\set ON_ERROR_STOP 0
\pset tuples_only on
\set VERBOSITY terse
create schema t; grant usage on schema t to anon, authenticated, service_role;
create function t.expect(p_label text, p_sql text, p_code text) returns text language plpgsql as $$
begin
  execute p_sql;
  return 'FAIL ' || p_label || ' (no error, expected ' || p_code || ')';
exception when others then
  if sqlstate = p_code then return 'ok   ' || p_label || ' [' || sqlstate || ']';
  else return 'FAIL ' || p_label || ' [' || sqlstate || ': ' || sqlerrm || ']'; end if;
end $$;
grant execute on function t.expect(text, text, text) to anon, authenticated, service_role;
create function t.eq(p_label text, p_got anyelement, p_want anyelement) returns text language sql as $$
  select case when p_got is not distinct from p_want then 'ok   ' else 'FAIL ' end || p_label || ' = ' || coalesce(p_got::text, 'NULL')
$$;
grant execute on function t.eq(text, anyelement, anyelement) to anon, authenticated, service_role;
create function t.as_user(p_sub text, p_aal text) returns void language sql as $$
  select set_config('request.jwt.claim.sub', p_sub, false), set_config('request.jwt.claims', '{"aal":"' || p_aal || '"}', false);
$$;
grant execute on function t.as_user(text, text) to anon, authenticated, service_role;
create function t.h(p text) returns text language sql immutable as $$ select encode(digest(p, 'sha256'), 'hex') $$;
grant execute on function t.h(text) to anon, authenticated, service_role;

-- Supabase default: service_role has table privileges in public (stub lacks them); keep snippet's audit-log restriction
grant select, insert, update, delete on all tables in schema public to service_role;
grant usage on all sequences in schema public to service_role;
revoke update, delete, truncate on client_audit_log from service_role;

-- ===================== fixtures =====================

-- ===================== fixtures (płatności za szkolenia, 00, D42) =====================
-- a = właściciel salonu A, e1 = pracownik A, b = właściciel salonu B, f1 = admin, f2 = agent,
-- c1 = właściciel organizatora 1, c3 = członek organizatora 1, c2 = właściciel organizatora 2, u1..u9 = pracownicy A
insert into auth.users values
 ('00000000-0000-0000-0000-00000000000a','ownera@example.com'), ('00000000-0000-0000-0000-00000000000b','ownerb@example.com'),
 ('00000000-0000-0000-0000-0000000000e1','empa@example.com'),   ('00000000-0000-0000-0000-0000000000f1','admin@example.com'),
 ('00000000-0000-0000-0000-0000000000f2','agent@example.com'),  ('00000000-0000-0000-0000-0000000000c1','org1@example.com'),
 ('00000000-0000-0000-0000-0000000000c2','org2@example.com'),   ('00000000-0000-0000-0000-0000000000c3','org1m@example.com');
insert into auth.users select ('00000000-0000-0000-0000-0000000001' || lpad(g::text, 2, '0'))::uuid, 'u' || g || '@example.com' from generate_series(1,9) g;
insert into admin_users(user_id, role) values ('00000000-0000-0000-0000-0000000000f1','admin'),('00000000-0000-0000-0000-0000000000f2','agent');
insert into client_accounts(id, display_name, nip, city) values ('aaaaaaaa-0000-0000-0000-000000000001','Salon Przykładowy A','9876543210','Kraków'),
                                                           ('bbbbbbbb-0000-0000-0000-000000000001','Salon Przykładowy B','1112223332','Gdańsk');
insert into client_policies(account_id, product, insurer, product_label, policy_number, status, valid_from, valid_to, published_at)
 values ('aaaaaaaa-0000-0000-0000-000000000001','tax-protect','colonnade','Tax Protect','BP/2026/000123 (przykład)','active','2026-01-01','2026-12-31',now()),
        ('bbbbbbbb-0000-0000-0000-000000000001','tax-protect','colonnade','Tax Protect','BP/2026/000124 (przykład)','active','2026-01-01','2026-12-31',now());
select public.app_activate_client_account('aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000f1','ownera@example.com', t.h('tokA')) is not null;
select public.app_activate_client_account('bbbbbbbb-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000f1','ownerb@example.com', t.h('tokB')) is not null;
select public.app_accept_invitation(t.h('tokA'),'00000000-0000-0000-0000-00000000000a','ownera@example.com') is not null;
select public.app_accept_invitation(t.h('tokB'),'00000000-0000-0000-0000-00000000000b','ownerb@example.com') is not null;
select public.app_create_invitation('aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000a','empa@example.com','employee', t.h('tokE')) is not null;
select public.app_accept_invitation(t.h('tokE'),'00000000-0000-0000-0000-0000000000e1','empa@example.com') is not null;
insert into client_members(account_id, user_id, role, status)
 select 'aaaaaaaa-0000-0000-0000-000000000001', ('00000000-0000-0000-0000-0000000001' || lpad(g::text, 2, '0'))::uuid, 'employee', 'active'
   from generate_series(1,9) g;
insert into training_organizers(id, kind, display_name, legal_name, nip, city, status, verified_at, verified_by, terms_version) values
 ('eeeeeeee-0000-0000-0000-000000000001','firma','Organizator przykładowy','Organizator Przykładowy sp. z o.o.','5556667776','Kraków','active',now(),'00000000-0000-0000-0000-0000000000f1','org-v1'),
 ('eeeeeeee-0000-0000-0000-000000000002','firma','Inny organizator (przykład)','Inny Organizator s.c.','7778889998','Gdańsk','active',now(),'00000000-0000-0000-0000-0000000000f1','org-v1');
select public.app_create_organizer_invitation('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000f1','org1@example.com','owner',t.h('tokO1')) is not null;
select public.app_accept_organizer_invitation(t.h('tokO1'),'00000000-0000-0000-0000-0000000000c1','org1@example.com') is not null;
select public.app_create_organizer_invitation('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000c1','org1m@example.com','member',t.h('tokO3')) is not null;
select public.app_accept_organizer_invitation(t.h('tokO3'),'00000000-0000-0000-0000-0000000000c3','org1m@example.com') is not null;
select public.app_create_organizer_invitation('eeeeeeee-0000-0000-0000-000000000002','00000000-0000-0000-0000-0000000000f1','org2@example.com','owner',t.h('tokO2')) is not null;
select public.app_accept_organizer_invitation(t.h('tokO2'),'00000000-0000-0000-0000-0000000000c2','org2@example.com') is not null;
select public.app_set_organizer_plan('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000f2','promo-12m',now(),'FV/2026/11/001 (przykład)') is not null;
select public.app_set_organizer_plan('eeeeeeee-0000-0000-0000-000000000002','00000000-0000-0000-0000-0000000000f2','promo-12m',now(),'FV/2026/11/002 (przykład)') is not null;

\set terms '{"seller_legal_name":"Organizator Przykładowy sp. z o.o.","seller_address":"ul. Przykładowa 1, 30-001 Kraków","seller_nip":"5556667776","seller_register":"KRS 0000000000 (przykład)","seller_email":"szkolenia@example.com","seller_phone":"+48 000 000 000","cancellation_rules":"Rezygnacja do 14 dni przed szkoleniem – zwrot całości; później – zwrot 50 procent ceny (przykład).","withdrawal_info":"Konsument może odstąpić od umowy w terminie 14 dni, z wyjątkami dla usług z określonym terminem (przykład).","complaint_info":"Reklamacje rozpatrujemy w terminie 14 dni od otrzymania (przykład).","terms_body":"Regulamin szkoleń organizatora przykładowego. Sprzedawcą jest organizator. Portal BeautyPolisa nie jest stroną umowy. Płatność obsługuje operator płatności. Faktury wystawia organizator. Szczegóły organizacyjne przekazujemy po zapisie (przykład)."}'
\set osoba '{"buyer_kind":"osoba","buyer_name":"Anna Przykładowa","invoice_email":"anna@example.com"}'
\set firma '{"buyer_kind":"firma","buyer_name":"Salon Przykładowy A sp. z o.o.","nip":"9876543210","street":"ul. Przykładowa 2","postal_code":"30-001","city":"Kraków","invoice_email":"faktury@example.com"}'

-- szkolenie płatne online (450 zł, 2 miejsca) i drugie do testu równoległego (1 miejsce)
set role authenticated; select t.as_user('00000000-0000-0000-0000-0000000000c1','aal2');
insert into trainings(organizer_id, status, title, summary, description, format, starts_at, ends_at, capacity, per_account_limit,
                      price_kind, price_gross_pln, payment_mode)
 values ('eeeeeeee-0000-0000-0000-000000000001','pending_review','Stylizacja brwi (przykład)','Krótko','Opis szkolenia przykładowego.','online',
         now()+interval '20 days', now()+interval '20 days 4 hours', 2, 10, 'platne', 450.00, 'online'),
        ('eeeeeeee-0000-0000-0000-000000000001','pending_review','Laminacja rzęs (przykład)','Krótko','Opis szkolenia przykładowego.','online',
         now()+interval '21 days', now()+interval '21 days 4 hours', 1, 10, 'platne', 300.00, 'online');
reset role;
select id as t1 from trainings where title like 'Stylizacja%' \gset
select id as t2 from trainings where title like 'Laminacja%' \gset

-- ===================== 1. Wypłaty, warunki sprzedaży, publikacja =====================
select '--- 1. payouts, sales terms, publish ---';
set role service_role;
select t.expect('publish online training without payouts and terms', format($q$select public.app_moderate_training(%L,'00000000-0000-0000-0000-0000000000f2','publish',1)$q$, :'t1'), 'P0001');
select t.expect('payout register by organiser member (not owner)', $q$select public.app_payout_account_register('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000c3','stripe','acct_TEST1')$q$, 'P0001');
select t.expect('payout register bad provider', $q$select public.app_payout_account_register('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000c1','paypal','acct_TEST1')$q$, 'BP422');
select public.app_payout_account_register('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000c1','stripe','acct_TEST1') as pa1 \gset
select t.eq('payout register idempotent', public.app_payout_account_register('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000c1','stripe','acct_TEST1'), :'pa1'::uuid);
select t.expect('payout account of org 1 claimed by org 2', $q$select public.app_payout_account_register('eeeeeeee-0000-0000-0000-000000000002','00000000-0000-0000-0000-0000000000c2','stripe','acct_TEST1')$q$, 'P0001');
select t.eq('payout status from operator: requirements due -> onboarding', public.app_payout_account_set_status('stripe','acct_TEST1', true, false, true), 'onboarding');
select t.expect('sales terms by member', format($q$select public.app_sales_terms_submit('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000c3',%L)$q$, :'terms'), 'P0001');
select t.expect('sales terms NIP other than verified profile (DSA art. 30)', format($q$select public.app_sales_terms_submit('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000c1',%L)$q$, jsonb_set(:'terms'::jsonb, '{seller_nip}', '"1112223332"')), 'BP422');
select t.expect('sales terms with URL', format($q$select public.app_sales_terms_submit('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000c1',%L)$q$, jsonb_set(:'terms'::jsonb, '{complaint_info}', '"Reklamacje: https://example.com/reklamacje (przykład)"')), 'BP422');
select public.app_sales_terms_submit('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000c1', :'terms') as st1 \gset
select t.expect('second terms version while first pending', format($q$select public.app_sales_terms_submit('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-0000000000c1',%L)$q$, :'terms'), 'BP409');
select t.expect('terms approved by organiser', format($q$select public.app_sales_terms_moderate(%L,'00000000-0000-0000-0000-0000000000c1','approve')$q$, :'st1'), 'P0001');
select public.app_sales_terms_moderate(:'st1','00000000-0000-0000-0000-0000000000f2','approve');
select t.expect('publish with payouts still onboarding', format($q$select public.app_moderate_training(%L,'00000000-0000-0000-0000-0000000000f2','publish',1)$q$, :'t1'), 'P0001');
select t.eq('payout status from operator: active', public.app_payout_account_set_status('stripe','acct_TEST1', true, true, false), 'active');
reset role;
update organizer_payout_accounts set usable_from = now() - interval '1 minute' where provider_account_ref = 'acct_TEST1';  -- karencja minęła
set role service_role;
select public.app_moderate_training(:'t1','00000000-0000-0000-0000-0000000000f2','publish',1);
select public.app_moderate_training(:'t2','00000000-0000-0000-0000-0000000000f2','publish',1);
reset role;
select t.eq('training published', (select status from trainings where id = :'t1'), 'published');
select t.eq('audit: payout_account_status_changed x2', (select count(*) from client_audit_log where action = 'payout_account_status_changed'), 1::bigint);

-- ===================== 2. zamówienie: kwota z bazy, idempotencja, brak nadsprzedaży =====================
