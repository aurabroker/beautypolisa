-- Zaślepki Supabase dla testów na czystym PostgreSQL 16 (narzedzia/sql-testy/uruchom.sh).
-- Odtwarzają tylko to, czego potrzebują snippets: role anon / authenticated / service_role, schematy
-- auth i storage, auth.uid() i auth.jwt() czytane z ustawień sesji (request.jwt.claim.sub,
-- request.jwt.claims – tak jak PostgREST), tabelę auth.mfa_factors i minimalne storage.buckets/objects.
-- Bez sekretów i bez prawdziwych danych. Nie zastępuje testu TEST-21 na lokalnym stosie Supabase CLI
-- (prawdziwe role, Data API, właściciele funkcji DEFINER) – patrz koniec snippets/strefa-klienta.sql.
do $$ begin
  if not exists (select 1 from pg_roles where rolname='anon') then create role anon nologin; end if;
  if not exists (select 1 from pg_roles where rolname='authenticated') then create role authenticated nologin; end if;
  if not exists (select 1 from pg_roles where rolname='service_role') then create role service_role nologin bypassrls; end if;
  if not exists (select 1 from pg_roles where rolname='supabase_admin') then create role supabase_admin nologin; end if;
end $$;
grant anon, authenticated, service_role to postgres;
create extension if not exists pgcrypto;
create schema auth; create schema storage;
grant usage on schema auth, storage, public to anon, authenticated, service_role;
create table auth.users (id uuid primary key, email text);
create table auth.mfa_factors (id uuid primary key default gen_random_uuid(), user_id uuid, status text);
grant select on auth.mfa_factors to authenticated;
create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub', true),'')::uuid $$;
create function auth.jwt() returns jsonb language sql stable as $$ select coalesce(nullif(current_setting('request.jwt.claims', true),''),'{}')::jsonb $$;
grant execute on function auth.uid(), auth.jwt() to anon, authenticated, service_role;
create table storage.buckets (id text primary key, name text, public boolean, file_size_limit bigint, allowed_mime_types text[]);
create table storage.objects (id uuid primary key default gen_random_uuid(), bucket_id text, name text);
alter table storage.objects enable row level security;
grant select on storage.objects to authenticated;
-- funkcje, do których odwołuje się rls-policies.sql, a które opisuje dokument 02 (poza snippets)
create function app_create_lead(jsonb) returns uuid language sql as $$ select null::uuid $$;
create function anonymize_lead(uuid, text) returns void language sql as $$ select $$;
