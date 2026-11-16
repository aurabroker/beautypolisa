-- app_is_staff() przed rls-policies.sql: w snippets/rls-policies.sql polityki odwołują się do funkcji
-- wcześniej, niż jest zdefiniowana (definicja w tym samym pliku, niżej). Uruchamiacz wczytuje tę kopię
-- między schema.sql a rls-policies.sql; rls-policies.sql nadpisuje ją swoją (create or replace).
create or replace function app_is_staff(variadic roles text[] default array['admin','agent','viewer'])
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(auth.jwt()->>'aal', 'aal1') = 'aal2'
     and exists (
       select 1 from admin_users a
       where a.user_id = auth.uid() and a.is_active and a.role = any (roles)
     );
$$;
