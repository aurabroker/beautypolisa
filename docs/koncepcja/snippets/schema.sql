-- Higiena uprawnień: nowe obiekty w public NIE dostają domyślnych grantów.
-- Uwaga 1: ALTER DEFAULT PRIVILEGES bez FOR ROLE działa tylko dla obiektów tworzonych przez rolę
--          wykonującą polecenie – stąd FOR ROLE dla każdej roli, która uruchamia migracje
--          (postgres; ewentualnie osobna rola CI).
-- Uwaga 2: EXECUTE na funkcjach Postgres nadaje domyślnie roli PUBLIC (której członkami są anon
--          i authenticated), więc samo odebranie anon/authenticated nie wystarcza – inaczej każda
--          nowa funkcja (app_create_lead, anonymize_lead) byłaby wywoływalna przez anon przez RPC.
alter default privileges for role postgres in schema public revoke all     on tables    from public, anon, authenticated;
alter default privileges for role postgres in schema public revoke all     on sequences from public, anon, authenticated;
alter default privileges for role postgres in schema public revoke execute on functions from public, anon, authenticated;
-- Test w CI (packages/db/tests/privileges.test.sql): zapytanie do pg_proc.proacl, które failuje,
-- gdy jakakolwiek funkcja w public ma EXECUTE dla anon lub PUBLIC (patrz 3.2).

create type lead_product as enum
  ('oc-beauty','tax-protect','utrata-dochodu','nnw-dzieci','grupowe-ergo','opieka-medyczna');
create type lead_status as enum
  ('new','contacted','quoted','won','lost','spam','marketing_only','anonymized');
-- marketing_only: lead po retencji sprzedażowej z aktywną zgodą marketingową (4.7)

-- Wersjonowanie cenników: dokładnie jedna aktywna wersja na produkt; aktywacja wymaga zatwierdzenia
create table pricing_versions (
  id                uuid primary key default gen_random_uuid(),
  product           lead_product not null,
  label             text not null,            -- np. "OC ERGO Hestia – cennik programu"
  valid_from        date not null,
  valid_to          date,
  is_active         boolean not null default false,
  source_note       text not null,            -- źródło wersji taryfy, np. "taryfa programu OC ERGO Hestia (audyt §3.1); składki sztywne – stan z 11.11.2026"
  approved_by       uuid references auth.users(id) on delete set null,
  approved_by_label text,                     -- trwały ślad audytowy (e-mail/nazwisko), niezależny od auth.users
  approved_at       timestamptz,
  created_at        timestamptz not null default now(),
  check (not is_active or (approved_by_label is not null and approved_at is not null))
);
create unique index pricing_versions_one_active on pricing_versions (product) where is_active;

-- Parametry wspólne dla całej wersji cennika OC – jedno miejsce zamiast powielania w 9 wierszach tierów
create table pricing_oc_params (
  version_id             uuid primary key references pricing_versions(id) on delete cascade,
  legal_protection_addon numeric(10,2) not null default 92.00,
  max_team_size          smallint not null default 8        -- powyżej → wycena indywidualna
);

create table pricing_oc_tiers (
  id             bigint generated always as identity primary key,
  version_id     uuid not null references pricing_versions(id) on delete cascade,
  risk_group     smallint not null check (risk_group between 1 and 3), -- gr. 4 = brak wiersza, wycena indywidualna
  sum_insured    integer  not null check (sum_insured in (100000, 200000, 300000)),
  annual_premium numeric(10,2) not null check (annual_premium > 0),
  unique (version_id, risk_group, sum_insured)
);

create table pricing_tax_variants (
  id             bigint generated always as identity primary key,
  version_id     uuid not null references pricing_versions(id) on delete cascade,
  -- 8 wierszy = 4 progi przychodu × 2 sumy; składka obejmuje obie sekcje (karnoskarbową i podatkową), 1 spór w roku
  revenue_limit  integer not null check (revenue_limit in (250000, 500000, 1000000, 3000000)), -- powyżej 3 mln → wycena indywidualna
  sum_insured    integer not null check (sum_insured in (50000, 100000)),
  annual_premium numeric(10,2) not null check (annual_premium > 0), -- składka roczna wg taryfy programu (źródło: tax_warianty)
  unique (version_id, revenue_limit, sum_insured)
);

create sequence leads_reference_seq;
create sequence claims_reference_seq;

create table leads (
  id                         uuid primary key default gen_random_uuid(),
  reference                  text not null unique,          -- czytelny numer zgłoszenia, np. BP-2026-000123 (nadawany w app_create_lead)
  idempotency_key            uuid not null unique,          -- z klienta; ponowna wysyłka = ten sam lead
  product                    lead_product not null,
  status                     lead_status  not null default 'new',
  -- PII – czyszczone przez anonymize_lead()
  full_name                  text,
  email                      text,
  email_normalized           text,                          -- lower(trim(email)); do deduplikacji
  phone                      text,                          -- E.164 po normalizacji
  company_name               text,
  nip                        text check (nip ~ '^[0-9]{10}$'),
  profession                 text,                          -- slug z /dla-kogo/<zawod>
  message                    text check (char_length(message) <= 2000),
  -- obowiązek informacyjny (art. 13 RODO) i informacje IDD: wersje wyświetlonych treści – bez checkboxa
  privacy_notice_version     text not null,                 -- np. rodo-v1-2026-11
  distributor_notice_version text not null,                 -- np. idd-v1-2026-11
  -- kontekst kalkulatora (bez PII)
  calc_input                 jsonb,                         -- {riskGroup,sumInsured,legalProtection,teamSize}
  calc_result                jsonb,                         -- wynik przeliczony NA SERWERZE
  pricing_version_id         uuid references pricing_versions(id),
  utm                        jsonb,
  landing_path               text,
  assigned_to                uuid references auth.users(id) on delete set null,
  exported_at                timestamptz,                   -- przekazanie do CRM/ubezpieczyciela; od tej daty liczy się retencja po konwersji
  anonymized_at              timestamptz,
  created_at                 timestamptz not null default now(),
  updated_at                 timestamptz not null default now()
);
create index leads_dedupe_idx on leads (email_normalized, product, created_at desc);
create index leads_status_idx on leads (status, created_at desc);

create table lead_events (
  id         bigint generated always as identity primary key,
  lead_id    uuid not null references leads(id) on delete cascade,
  type       text not null check (type in ('created','duplicate_submission','quote_recomputed',
               'email_team_sent','email_client_sent','email_failed','status_changed',
               'assigned','note_added','consent_withdrawn','exported_to_crm','forwarded_to_insurer',
               'privacy_request','anonymized')),
  payload    jsonb,                                 -- bez PII, np. {"from":"new","to":"contacted"}, {"recipient":"crm-aura","reference":"…"}
  actor      text not null default 'system',        -- 'system' | 'user:<uuid>' | 'subject' (osoba, której dane dotyczą – link samoobsługowy)
  created_at timestamptz not null default now()
);

create table newsletter_subscribers (
  id                       uuid primary key default gen_random_uuid(),
  email                    text not null,
  email_normalized         text not null unique,
  status                   text not null default 'pending' check (status in ('pending','confirmed','unsubscribed')),
  confirm_token_hash       text,                    -- sha256(token); token jednorazowy, wysyłany e-mailem
  confirm_token_expires_at timestamptz,             -- 48 h od wysłania; ponowna wysyłka nadpisuje oba pola
  confirmed_at             timestamptz,
  unsubscribed_at          timestamptz,
  source_path              text,
  created_at               timestamptz not null default now()
  -- link rezygnacji: HMAC(id, UNSUBSCRIBE_HMAC_KEY) liczony w locie – bez kolumny w bazie
);

create table consents (
  id                bigint generated always as identity primary key,
  lead_id           uuid references leads(id) on delete cascade,
  subscriber_id     uuid references newsletter_subscribers(id) on delete cascade,
  purpose           text not null check (purpose in ('marketing_email','marketing_phone','newsletter')), -- wyłącznie prawdziwe zgody
  granted           boolean not null,
  text_version      text not null,                  -- treść zgody per kanał z repo, np. marketing-email-v1-2026-11
  email_hmac        text not null,                  -- HMAC-SHA256(email_normalized, CONSENT_HMAC_KEY): „czyja” zgoda także po anonimizacji leada
  user_agent_family text check (char_length(user_agent_family) <= 64), -- np. "Chrome Mobile/Android"; bez pełnego UA
  request_id        text,                           -- korelacja z logiem serwera (bez PII)
  withdrawn_at      timestamptz,                    -- wycofanie linkiem samoobsługowym lub w panelu
  created_at        timestamptz not null default now(),
  check (lead_id is not null or subscriber_id is not null)
  -- celowo BEZ adresu IP ani jego hasha (4.1 wiersz R, 4.7)
);
create index consents_active_idx on consents (lead_id, purpose) where granted and withdrawn_at is null;

create table admin_users (
  user_id        uuid primary key references auth.users(id) on delete restrict, -- konta dezaktywujemy, nie kasujemy (ślad audytowy)
  role           text not null check (role in ('admin','agent','viewer')),
  is_active      boolean not null default true,
  deactivated_at timestamptz,
  created_by     uuid references auth.users(id) on delete set null,
  created_at     timestamptz not null default now()
);

create table claims_reports (
  id             uuid primary key default gen_random_uuid(),
  reference      text not null unique,                                   -- np. SZ-2026-000045
  idempotency_key uuid not null unique,
  product        lead_product not null,
  policy_number  text check (char_length(policy_number) <= 40),
  full_name      text, email text, phone text,
  incident_date  date,
  incident_type  text not null check (incident_type in ('injury_client','property_damage','other')),
  -- BRAK pola opisu: szczegóły zdarzenia (zwykle dane o zdrowiu klientki salonu – osoby trzeciej, art. 9 RODO)
  -- zbiera opiekun telefonicznie; instrukcja w formularzu nie jest środkiem technicznym
  privacy_notice_version text not null,
  status         text not null default 'new' check (status in ('new','forwarded','closed','anonymized')),
  forwarded_to   text,                                                   -- np. 'ergo-hestia' – odrębny administrator
  forwarded_at   timestamptz,
  closed_at      timestamptz,
  anonymized_at  timestamptz,
  created_at     timestamptz not null default now()
);

create table outbox_emails (
  id              uuid primary key default gen_random_uuid(),   -- = klucz idempotencji w Resend
  lead_id         uuid references leads(id) on delete cascade,
  template        text not null,                 -- 'lead_team' | 'lead_client' | 'newsletter_confirm' | ...
  recipient       text not null,                 -- PII; przy anonimizacji wartość zastępcza 'anonymized' (kolumna not null)
  payload         jsonb not null,                -- dane do szablonu; przy anonimizacji '{}'
  status          text not null default 'pending' check (status in ('pending','sent','failed')),
  attempts        smallint not null default 0,
  next_attempt_at timestamptz not null default now(),
  provider_id     text,
  last_error      text,
  created_at      timestamptz not null default now()
);
create index outbox_pending_idx on outbox_emails (next_attempt_at) where status = 'pending';
