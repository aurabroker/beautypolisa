-- LEADY: zero dostępu dla anon; personel czyta i aktualizuje wybrane kolumny przez RLS
alter table leads            enable row level security;
alter table leads            force row level security;   -- także dla właściciela tabeli (uwaga w runbooku: SQL Editor jako postgres
                                                         -- zwraca wtedy 0 wierszy – to NIE jest utrata danych; serwisowo: set role service_role)
alter table lead_events      enable row level security;
alter table consents         enable row level security;
alter table claims_reports   enable row level security;
alter table outbox_emails    enable row level security;  -- bez polityk: wyłącznie service_role (lista service_role_only w teście CI)
alter table newsletter_subscribers enable row level security; -- jw.
revoke all on leads, lead_events, consents, claims_reports, outbox_emails, newsletter_subscribers
  from public, anon, authenticated;
grant select, update (status, assigned_to, exported_at, updated_at) on leads to authenticated;
grant select, insert on lead_events to authenticated;
grant select on consents to authenticated;
grant select, update (status, forwarded_to, forwarded_at, closed_at) on claims_reports to authenticated;

create policy leads_staff_select on leads
  for select to authenticated using (app_is_staff());
create policy leads_staff_update on leads
  for update to authenticated
  using (app_is_staff('admin','agent')) with check (app_is_staff('admin','agent'));
create policy lead_events_staff_select on lead_events
  for select to authenticated using (app_is_staff());
create policy lead_events_staff_insert on lead_events
  for insert to authenticated
  with check (app_is_staff('admin','agent') and actor = 'user:' || auth.uid()::text);
create policy consents_staff_select on consents
  for select to authenticated using (app_is_staff());
create policy claims_staff_select on claims_reports
  for select to authenticated using (app_is_staff());
create policy claims_staff_update on claims_reports
  for update to authenticated
  using (app_is_staff('admin','agent')) with check (app_is_staff('admin','agent'));
-- brak polityk INSERT/DELETE na leads dla authenticated → zapis wyłącznie service_role (serwer)

-- CENNIKI: publiczny odczyt tylko aktywnej wersji; zapis wyłącznie admin.
-- Polityki ROZDZIELONE per rola: polityka dla anon nie może wywoływać app_is_staff() – Postgres sprawdza
-- uprawnienie EXECUTE przy inicjalizacji wyrażenia, niezależnie od skrótu `is_active OR …`, więc odczyt
-- jako anon kończyłby się błędem "permission denied for function app_is_staff".
alter table pricing_versions     enable row level security;
alter table pricing_oc_params    enable row level security;
alter table pricing_oc_tiers     enable row level security;
alter table pricing_tax_variants enable row level security;
revoke all on pricing_versions, pricing_oc_params, pricing_oc_tiers, pricing_tax_variants
  from public, anon, authenticated;
grant select on pricing_versions, pricing_oc_params, pricing_oc_tiers, pricing_tax_variants to anon, authenticated;
grant insert, update on pricing_versions, pricing_oc_params, pricing_oc_tiers, pricing_tax_variants to authenticated;

create policy pricing_versions_anon_read on pricing_versions
  for select to anon using (is_active);
create policy pricing_versions_staff_read on pricing_versions
  for select to authenticated using (is_active or app_is_staff());

create policy pricing_oc_params_anon_read on pricing_oc_params
  for select to anon
  using (exists (select 1 from pricing_versions v where v.id = version_id and v.is_active));
create policy pricing_oc_params_staff_read on pricing_oc_params
  for select to authenticated
  using (exists (select 1 from pricing_versions v where v.id = version_id and (v.is_active or app_is_staff())));

create policy pricing_oc_anon_read on pricing_oc_tiers
  for select to anon
  using (exists (select 1 from pricing_versions v where v.id = version_id and v.is_active));
create policy pricing_oc_staff_read on pricing_oc_tiers
  for select to authenticated
  using (exists (select 1 from pricing_versions v where v.id = version_id and (v.is_active or app_is_staff())));

create policy pricing_tax_anon_read on pricing_tax_variants           -- bez tej polityki RLS zwracałby 0 wierszy (jak tax_wnioski w audycie)
  for select to anon
  using (exists (select 1 from pricing_versions v where v.id = version_id and v.is_active));
create policy pricing_tax_staff_read on pricing_tax_variants
  for select to authenticated
  using (exists (select 1 from pricing_versions v where v.id = version_id and (v.is_active or app_is_staff())));

create policy pricing_versions_admin_write on pricing_versions
  for all to authenticated using (app_is_staff('admin')) with check (app_is_staff('admin'));
create policy pricing_oc_params_admin_write on pricing_oc_params
  for all to authenticated using (app_is_staff('admin')) with check (app_is_staff('admin'));
create policy pricing_oc_admin_write on pricing_oc_tiers
  for all to authenticated using (app_is_staff('admin')) with check (app_is_staff('admin'));
create policy pricing_tax_admin_write on pricing_tax_variants
  for all to authenticated using (app_is_staff('admin')) with check (app_is_staff('admin'));

-- ROLE PANELU: odczyt własnego wiersza; każda zmiana tylko z backendu (trigger guard)
alter table admin_users enable row level security;
revoke all on admin_users from public, anon, authenticated;
grant select on admin_users to authenticated;
create policy admin_users_self_read on admin_users
  for select to authenticated using (user_id = auth.uid());

create or replace function admin_users_guard() returns trigger
language plpgsql as $$                                      -- security INVOKER: current_user = rola wywołująca
begin
  if current_user not in ('service_role', 'postgres', 'supabase_admin') then
    raise exception 'admin_users: zmiana ról możliwa wyłącznie z backendu';
  end if;
  return coalesce(new, old);
end $$;
create trigger admin_users_guard
  before insert or update or delete on admin_users
  for each row execute function admin_users_guard();

-- Pomocnicza funkcja ról: SECURITY DEFINER z zamrożonym search_path, wykonywalna tylko przez authenticated.
-- Wymaga sesji po drugim składniku (aal2): wymóg MFA jest egzekwowany w RLS, nie tylko deklarowany –
-- sesja po samym haśle (przed TOTP) nie widzi leadów.
create or replace function app_is_staff(variadic roles text[] default array['admin','agent','viewer'])
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(auth.jwt()->>'aal', 'aal1') = 'aal2'
     and exists (
       select 1 from admin_users a
       where a.user_id = auth.uid() and a.is_active and a.role = any (roles)
     );
$$;
revoke execute on function app_is_staff(text[]) from public, anon;
grant  execute on function app_is_staff(text[]) to authenticated;

-- Funkcje zapisu – uprawnienia jawne
revoke execute on function app_create_lead(jsonb)     from public, anon, authenticated;
revoke execute on function anonymize_lead(uuid, text) from public, anon, authenticated;
grant  execute on function app_create_lead(jsonb), anonymize_lead(uuid, text) to service_role;
