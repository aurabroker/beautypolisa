-- =====================================================================================================
-- Strefa Klienta BeautyPolisa: konta salonów, polisy i dokumenty, „Dam pracę”, „Szkolenia”
-- Migracja dla NOWEGO, dedykowanego projektu Supabase portalu (decyzja D2), uruchamiana PO schema.sql
-- i rls-policies.sql (korzysta z: lead_product, leads, pricing_versions, claims_reports, outbox_emails,
-- admin_users, app_is_staff()). Opis i uzasadnienia: 11-strefa-klienta.md.
--
-- Konwencje (jak w schema.sql / rls-policies.sql):
--  * domyślne granty odebrane w schema.sql (ALTER DEFAULT PRIVILEGES … FROM public, anon, authenticated);
--    mimo to każda tabela i funkcja ma tu jawne REVOKE + jawne GRANT;
--  * RLS włączone na każdej tabeli; tabele z danymi osobowymi dodatkowo FORCE ROW LEVEL SECURITY;
--  * funkcje zapisu z niezmiennikami między salonami (zaproszenia, zapisy z limitem miejsc, aplikacje
--    kandydatów bez konta, moderacja) wykonywalne WYŁĄCZNIE przez service_role (serwer), security invoker;
--  * SECURITY DEFINER tylko tam, gdzie RLS bez niego wpada w rekurencję (client_account_ids) albo gdzie
--    funkcja jest wyzwalaczem audytu – zawsze z set search_path = '' i pełnymi nazwami obiektów,
--    bez EXECUTE dla public/anon (błąd z audytu projektu „BEAUTY”: can_manage_salon, is_katalog_admin,
--    is_platform_admin, katalog_set_admin wykonywalne przez anon);
--  * polityki dla anon nigdy nie wywołują app_is_staff() (patrz komentarz w rls-policies.sql);
--  * żadnych widoków SECURITY DEFINER (w „BEAUTY” 3 takie widoki to poziom ERROR w Security Advisor).
-- Plik jest wzorcem: przed wdrożeniem dzielimy go na migracje w supabase/migrations i pokrywamy testami
-- uprawnień z sekcji 9.6 dokumentu 11.
-- =====================================================================================================


-- -----------------------------------------------------------------------------------------------------
-- 1. KONTA SALONÓW, CZŁONKOSTWA, ZAPROSZENIA
-- -----------------------------------------------------------------------------------------------------

create table client_accounts (
  id               uuid primary key default gen_random_uuid(),
  display_name     text not null check (char_length(display_name) between 2 and 120), -- nazwa salonu w Strefie i w ofertach pracy
  legal_name       text check (char_length(legal_name) <= 200),
  nip              text check (nip ~ '^[0-9]{10}$'),
  city             text check (char_length(city) <= 80),
  status           text not null default 'pending'
                     check (status in ('pending','active','suspended','closed')),
  crm_ref          text check (char_length(crm_ref) <= 64),      -- id firmy w CRM Aura (projekt „BEAUTY”, crm_companies.id); tylko referencja
  source_lead_id   uuid references leads(id) on delete set null,  -- lead, z którego powstała polisa (jeśli był)
  activated_at     timestamptz,
  activated_by     uuid references auth.users(id) on delete set null,
  suspended_at     timestamptz,
  closed_at        timestamptz,
  created_by       uuid references auth.users(id) on delete set null,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  check (status <> 'active' or activated_at is not null)
);
create unique index client_accounts_nip_uq on client_accounts (nip) where nip is not null and status <> 'closed';

create table client_members (
  account_id        uuid not null references client_accounts(id) on delete cascade,
  user_id           uuid not null references auth.users(id) on delete cascade,
  role              text not null check (role in ('owner','employee')),
  status            text not null default 'active' check (status in ('active','revoked')),
  display_name      text check (char_length(display_name) <= 120),
  terms_version     text,                     -- wersja regulaminu Strefy Klienta zaakceptowana przy pierwszym logowaniu
  terms_accepted_at timestamptz,
  invited_by        uuid references auth.users(id) on delete set null,
  revoked_by        uuid references auth.users(id) on delete set null,
  revoked_at        timestamptz,
  created_at        timestamptz not null default now(),
  primary key (account_id, user_id),
  check (status <> 'revoked' or revoked_at is not null)
);
create index client_members_user_idx on client_members (user_id) where status = 'active';

create table client_invitations (
  id                uuid primary key default gen_random_uuid(),
  account_id        uuid not null references client_accounts(id) on delete cascade,
  email             text,                     -- PII; czyszczone 30 dni po przyjęciu/wygaśnięciu (cron)
  email_normalized  text,
  role              text not null check (role in ('owner','employee')),
  token_hash        text not null unique check (token_hash ~ '^[0-9a-f]{64}$'), -- sha256(token); token wyłącznie w e-mailu
  expires_at        timestamptz not null,
  invited_by        uuid references auth.users(id) on delete set null,
  invited_by_kind   text not null check (invited_by_kind in ('staff','owner')),
  accepted_at       timestamptz,
  accepted_user_id  uuid references auth.users(id) on delete set null,
  revoked_at        timestamptz,
  created_at        timestamptz not null default now(),
  check (invited_by_kind = 'staff' or role = 'employee')  -- właściciel zaprasza tylko pracowników
);
create unique index client_invitations_pending_uq
  on client_invitations (account_id, email_normalized)
  where accepted_at is null and revoked_at is null;


-- -----------------------------------------------------------------------------------------------------
-- 2. POLISY I DOKUMENTY (dodaje broker w /panel; brak integracji z ubezpieczycielem w MVP)
-- -----------------------------------------------------------------------------------------------------

create table client_policies (
  id                  uuid primary key default gen_random_uuid(),
  account_id          uuid not null references client_accounts(id) on delete restrict,
  product             lead_product not null,
  insurer             text not null check (insurer in ('ergo-hestia','colonnade','enel-med','lux-med','inny')),
  product_label       text not null check (char_length(product_label) <= 160), -- np. „OC dla branży beauty – program ERGO Hestia”
  policy_number       text not null check (char_length(policy_number) <= 60),
  status              text not null default 'draft'
                        check (status in ('draft','active','expired','cancelled','renewed')),
  valid_from          date not null,
  valid_to            date not null,
  premium_amount      numeric(10,2) check (premium_amount >= 0),
  premium_period      text check (premium_period in ('year','month','month_per_person')),
  -- OC beauty: parametry taryfy programu (składki sztywne). Serwer przelicza składkę z aktywnej wersji
  -- cennika i odrzuca zapis, jeśli premium_amount się nie zgadza (ta sama czysta funkcja co kalkulator).
  oc_risk_groups      smallint[] check (oc_risk_groups <@ array[1,2,3,4]::smallint[]), -- zaznaczone grupy zabiegów
  oc_tariff_group     smallint check (oc_tariff_group between 1 and 3),           -- grupa taryfowa po regułach łączenia (gr. 3 z 1/2 → 3; 1+2 → 3)
  oc_sum_insured      integer check (oc_sum_insured in (100000, 200000, 300000)),
  oc_legal_protection boolean,
  oc_team_size_band   text check (oc_team_size_band in ('do-5','6-8','9+')),
  oc_individual_quote boolean not null default false, -- gr. 4 albo zespół 9+: składka z wyceny indywidualnej, nie z taryfy
  pricing_version_id  uuid references pricing_versions(id),
  published_at        timestamptz,            -- klient widzi polisę dopiero po publikacji przez brokera
  crm_ref             text check (char_length(crm_ref) <= 64), -- id polisy w CRM (crm_policies.id) – pod przyszłą synchronizację
  created_by          uuid references auth.users(id) on delete set null,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  check (valid_to >= valid_from),
  check (product <> 'oc-beauty' or status = 'draft' or oc_individual_quote
         or (oc_tariff_group is not null and oc_sum_insured is not null and oc_legal_protection is not null
             and oc_team_size_band in ('do-5','6-8') and pricing_version_id is not null)),
  check (not oc_individual_quote or product = 'oc-beauty')
);
create index client_policies_account_idx on client_policies (account_id, valid_to desc);
create index client_policies_renewal_idx on client_policies (valid_to) where status = 'active';

-- Notatki wewnętrzne brokera: osobna tabela, bo uprawnienia kolumnowe obejmują całą rolę authenticated
-- (właścicieli salonów i personel) – kolumna „notes” w client_policies byłaby widoczna dla klienta.
create table client_policy_notes (
  id         bigint generated always as identity primary key,
  policy_id  uuid not null references client_policies(id) on delete cascade,
  body       text not null check (char_length(body) <= 4000),
  author     uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table client_policy_documents (
  id             uuid primary key default gen_random_uuid(),
  policy_id      uuid not null references client_policies(id) on delete cascade,
  account_id     uuid not null references client_accounts(id) on delete restrict, -- zdenormalizowane: RLS i ścieżka w Storage
  kind           text not null check (kind in ('polisa','owu','aneks','potwierdzenie','inne')),
  title          text not null check (char_length(title) <= 160),
  storage_path   text not null unique,      -- {account_id}/{policy_id}/{uuid}.pdf w prywatnym kubełku client-documents
  mime_type      text not null check (mime_type = 'application/pdf'),
  size_bytes     integer not null check (size_bytes between 1 and 15728640),      -- ≤ 15 MB
  sha256         text not null check (sha256 ~ '^[0-9a-f]{64}$'),
  published_at   timestamptz,
  uploaded_by    uuid references auth.users(id) on delete set null,
  created_at     timestamptz not null default now(),
  check (storage_path like account_id::text || '/' || policy_id::text || '/%.pdf')
);
create index client_policy_documents_policy_idx on client_policy_documents (policy_id);

-- Idempotencja przypomnień o odnowieniu (cron w beautypolisa-jobs): jeden wpis na polisę i próg
create table client_policy_reminders (
  policy_id  uuid not null references client_policies(id) on delete cascade,
  kind       text not null check (kind in ('renewal_60','renewal_30','renewal_14')),
  outbox_id  uuid references outbox_emails(id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (policy_id, kind)
);

-- Powiązania istniejących tabel portalu ze Strefą Klienta
alter table claims_reports
  add column account_id  uuid references client_accounts(id) on delete set null,
  add column policy_id   uuid references client_policies(id) on delete set null,
  add column reported_by uuid references auth.users(id) on delete set null;
alter table outbox_emails
  add column account_id  uuid references client_accounts(id) on delete cascade;
-- Nowe szablony outbox (bez danych kandydatów i bez załączników – w treści tylko link do Strefy):
-- client_invite, client_policy_published, renewal_60, renewal_30, renewal_14, claim_received,
-- job_offer_submitted_team, job_offer_published, job_offer_rejected, job_offer_expiring,
-- job_application_owner, job_application_candidate, training_registered, training_waitlisted,
-- training_promoted, training_reminder_24h, training_cancelled.
-- Token zaproszenia NIGDY nie trafia do payload: przy ponowieniu wysyłki serwer rotuje token
-- (app_rotate_invitation_token) i wysyła nowy link, a poprzedni przestaje działać.


-- -----------------------------------------------------------------------------------------------------
-- 3. „DAM PRACĘ” – OFERTY, APLIKACJE, ZGŁOSZENIA NADUŻYĆ
-- -----------------------------------------------------------------------------------------------------

create table job_offers (
  id               uuid primary key default gen_random_uuid(),
  account_id       uuid not null references client_accounts(id) on delete cascade,
  slug             text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and char_length(slug) <= 120),
  status           text not null default 'draft'
                     check (status in ('draft','pending_review','published','rejected','closed','expired','removed')),
  title            text not null check (char_length(title) between 5 and 120),
  profession       text not null check (profession in ('kosmetolog','fryzjer','podolog','linergistka',
                     'stylistka-paznokci','tatuazysta','recepcja','inny')),
  employment_type  text not null check (employment_type in ('umowa-o-prace','umowa-zlecenie','b2b','inna')),
  working_time     text not null check (working_time in ('pelny-etat','czesc-etatu','elastyczny')),
  city             text not null check (char_length(city) between 2 and 80),
  voivodeship      text not null check (voivodeship in ('dolnoslaskie','kujawsko-pomorskie','lubelskie','lubuskie',
                     'lodzkie','malopolskie','mazowieckie','opolskie','podkarpackie','podlaskie','pomorskie',
                     'slaskie','swietokrzyskie','warminsko-mazurskie','wielkopolskie','zachodniopomorskie')),
  postal_code      text check (postal_code ~ '^[0-9]{2}-[0-9]{3}$'),
  -- jawność wynagrodzeń: widełki obowiązkowe [Założenie – zgodność z nowelizacją Kodeksu pracy do weryfikacji przez prawnika]
  salary_min       numeric(10,2) not null check (salary_min > 0),
  salary_max       numeric(10,2) not null,
  salary_unit      text not null check (salary_unit in ('HOUR','MONTH')),
  salary_basis     text not null default 'brutto' check (salary_basis in ('brutto','netto')),
  description      text not null check (char_length(description) between 200 and 5000), -- tekst zwykły, bez HTML i linków
  requirements     text check (char_length(requirements) <= 2000),
  benefits         text check (char_length(benefits) <= 2000),
  employer_name    text not null,             -- migawka client_accounts.display_name (ustawia trigger)
  submitted_at     timestamptz,
  published_at     timestamptz,
  expires_at       timestamptz,
  moderated_by     uuid references auth.users(id) on delete set null,
  moderation_note  text check (char_length(moderation_note) <= 1000),   -- wewnętrzna; bez grantu kolumnowego dla klienta
  rejection_reason text check (char_length(rejection_reason) <= 500),   -- widoczna dla właściciela
  closed_at        timestamptz,
  created_by       uuid references auth.users(id) on delete set null,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  check (salary_max >= salary_min),
  check (status <> 'published' or (published_at is not null and expires_at is not null)),
  check (expires_at is null or published_at is null or expires_at <= published_at + interval '60 days')
);
create index job_offers_public_idx  on job_offers (status, expires_at desc);
create index job_offers_account_idx on job_offers (account_id, status);
create index job_offers_filter_idx  on job_offers (profession, voivodeship) where status = 'published';

create sequence job_applications_reference_seq;

create table job_applications (
  id                              uuid primary key default gen_random_uuid(),
  reference                       text not null unique,            -- np. AP-2026-000123
  idempotency_key                 uuid not null unique,
  offer_id                        uuid not null references job_offers(id) on delete cascade,
  account_id                      uuid not null references client_accounts(id) on delete cascade,
  status                          text not null default 'new'
                                    check (status in ('new','viewed','shortlisted','rejected','hired','withdrawn','anonymized')),
  -- PII kandydata – zakres zgodny z art. 22(1) KP [do weryfikacji przez prawnika]; czyszczone przez app_anonymize_job_applications()
  full_name                       text check (char_length(full_name) <= 120),
  email                           text check (char_length(email) <= 254),
  email_normalized                text,
  phone                           text check (char_length(phone) <= 20),
  experience_summary              text check (char_length(experience_summary) <= 2000),
  cv_storage_path                 text,     -- Faza Z3 (po wdrożeniu skanowania AV); w MVP zawsze NULL
  cv_scan_status                  text not null default 'none' check (cv_scan_status in ('none','pending','clean','infected','error')),
  privacy_notice_version          text not null,                   -- klauzula z art. 13 RODO wyświetlona przy formularzu
  future_recruitment_consent      boolean not null default false,  -- osobna, niezaznaczona zgoda na przyszłe rekrutacje
  future_recruitment_consent_version text,
  retention_until                 timestamptz not null,
  withdrawn_at                    timestamptz,
  anonymized_at                   timestamptz,
  created_at                      timestamptz not null default now(),
  updated_at                      timestamptz not null default now(),
  check (not future_recruitment_consent or future_recruitment_consent_version is not null),
  check (cv_storage_path is null or cv_storage_path like 'clean/' || account_id::text || '/%')
);
create index job_applications_offer_idx     on job_applications (offer_id, created_at desc);
create index job_applications_retention_idx on job_applications (retention_until) where anonymized_at is null;
create index job_applications_dedupe_idx    on job_applications (offer_id, email_normalized);

create table job_offer_reports (                     -- „Zgłoś ofertę” (bez danych zgłaszającego)
  id          bigint generated always as identity primary key,
  offer_id    uuid not null references job_offers(id) on delete cascade,
  reason      text not null check (reason in ('nieaktualna','dyskryminacja','oszustwo','spam','inne')),
  handled_at  timestamptz,
  handled_by  uuid references auth.users(id) on delete set null,
  created_at  timestamptz not null default now()
);


-- -----------------------------------------------------------------------------------------------------
-- 4. „SZKOLENIA” – KATALOG, SZCZEGÓŁY DLA ZAPISANYCH, ZAPISY
-- -----------------------------------------------------------------------------------------------------

create table trainings (
  id                     uuid primary key default gen_random_uuid(),
  slug                   text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and char_length(slug) <= 120),
  status                 text not null default 'draft' check (status in ('draft','published','cancelled','completed')),
  title                  text not null check (char_length(title) between 5 and 160),
  summary                text not null check (char_length(summary) <= 300),
  description            text not null check (char_length(description) <= 8000),
  format                 text not null check (format in ('stacjonarne','online','hybrydowe')),
  city                   text check (char_length(city) <= 80),
  venue_name             text check (char_length(venue_name) <= 120),
  starts_at              timestamptz not null,
  ends_at                timestamptz not null,
  registration_closes_at timestamptz,
  capacity               integer check (capacity is null or capacity > 0),  -- NULL = bez limitu (np. online)
  seats_registered       integer not null default 0 check (seats_registered >= 0), -- licznik prowadzony przez funkcje zapisu
  per_account_limit      smallint not null default 3 check (per_account_limit > 0),
  audience               text not null default 'all_members' check (audience in ('all_members','owners')),
  organizer_label        text not null check (char_length(organizer_label) <= 120), -- nazwa partnera tylko za jego zgodą
  price_kind             text not null default 'bezplatne' check (price_kind in ('bezplatne','partner')),
  published_at           timestamptz,
  created_by             uuid references auth.users(id) on delete set null,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  check (ends_at > starts_at),
  check (capacity is null or seats_registered <= capacity),
  check (format = 'online' or city is not null)
);
create index trainings_catalog_idx on trainings (status, starts_at);

create table training_private_details (               -- widoczne tylko dla zapisanych i personelu
  training_id     uuid primary key references trainings(id) on delete cascade,
  online_join_url text check (online_join_url ~ '^https://'),
  venue_address   text check (char_length(venue_address) <= 200),
  instructions    text check (char_length(instructions) <= 2000)
);

create table training_registrations (
  id            uuid primary key default gen_random_uuid(),
  training_id   uuid not null references trainings(id) on delete cascade,
  account_id    uuid not null references client_accounts(id) on delete cascade,
  user_id       uuid not null references auth.users(id) on delete cascade,
  status        text not null check (status in ('registered','waitlisted','cancelled','attended','no_show')),
  cancelled_at  timestamptz,
  marked_by     uuid references auth.users(id) on delete set null,   -- kto oznaczył obecność
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  unique (training_id, user_id)
);
create index training_registrations_training_idx on training_registrations (training_id, status, created_at);
create index training_registrations_account_idx  on training_registrations (account_id);


-- -----------------------------------------------------------------------------------------------------
-- 5. DZIENNIK AUDYTU STREFY (append-only, bez PII w payload)
-- -----------------------------------------------------------------------------------------------------

create table client_audit_log (
  id          bigint generated always as identity primary key,
  account_id  uuid references client_accounts(id) on delete set null,
  actor       text not null check (actor ~ '^(system|candidate|user:[0-9a-f-]{36}|staff:[0-9a-f-]{36})$'),
  action      text not null check (action in (
                'account_created','account_activated','account_suspended','account_closed',
                'invitation_created','invitation_rotated','invitation_accepted','invitation_revoked',
                'member_revoked','terms_accepted',
                'policy_created','policy_updated','policy_published','document_uploaded','document_published',
                'document_downloaded','claim_reported','renewal_requested',
                'job_offer_submitted','job_offer_published','job_offer_rejected','job_offer_closed',
                'job_offer_removed','job_offer_expired','job_application_received','job_application_status',
                'job_applications_anonymized',
                'training_registered','training_waitlisted','training_promoted','training_cancelled',
                'training_attendance')),
  entity      text not null check (entity in ('account','member','invitation','policy','document','claim',
                'job_offer','job_application','training','training_registration')),
  entity_id   uuid,
  payload     jsonb not null default '{}'::jsonb check (pg_column_size(payload) <= 2048), -- np. {"from":"draft","to":"pending_review"}
  request_id  text check (char_length(request_id) <= 64),
  created_at  timestamptz not null default now()
);
create index client_audit_log_account_idx on client_audit_log (account_id, created_at desc);


-- -----------------------------------------------------------------------------------------------------
-- 6. FUNKCJE POMOCNICZE RLS
-- -----------------------------------------------------------------------------------------------------

-- Konta, do których bieżący użytkownik należy (aktywne członkostwo w aktywnym koncie, wskazane role).
-- SECURITY DEFINER, bo polityka na client_members („właściciel widzi zespół”) odwołuje się do
-- client_members – funkcja invoker wpadłaby w nieskończoną rekurencję polityk.
-- Ograniczenia: zwraca wyłącznie dane o WYWOŁUJĄCYM (auth.uid()), bez parametru user_id; search_path = '';
-- EXECUTE tylko dla authenticated. Gdy użytkownik ma zweryfikowany czynnik MFA (TOTP), sesja musi mieć
-- aal2 – inaczej funkcja zwraca pusty zbiór (MFA egzekwowane w bazie, nie tylko w UI).
create or replace function public.client_account_ids(variadic roles text[] default array['owner','employee'])
returns setof uuid
language sql stable security definer set search_path = '' as $$
  select m.account_id
  from public.client_members m
  join public.client_accounts a on a.id = m.account_id
  where m.user_id = (select auth.uid())
    and m.status = 'active'
    and a.status = 'active'
    and m.role = any (roles)
    and (
      coalesce((select auth.jwt()) ->> 'aal', 'aal1') = 'aal2'
      or not exists (
        select 1 from auth.mfa_factors f
        where f.user_id = (select auth.uid()) and f.status = 'verified'
      )
    );
$$;
revoke all     on function public.client_account_ids(text[]) from public, anon;
grant  execute on function public.client_account_ids(text[]) to authenticated;

-- Guard: tabele, które zmienia wyłącznie backend (service_role) – członkostwa, zaproszenia,
-- przypomnienia. Wzorzec admin_users_guard (security invoker: current_user = rola wywołująca).
create or replace function public.backend_only_guard() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user not in ('service_role', 'postgres', 'supabase_admin') then
    raise exception '%: zmiana możliwa wyłącznie z backendu', tg_table_name;
  end if;
  return coalesce(new, old);
end $$;
revoke all on function public.backend_only_guard() from public, anon, authenticated;

create trigger client_members_guard
  before insert or update or delete on client_members
  for each row execute function public.backend_only_guard();
create trigger client_invitations_guard
  before insert or update or delete on client_invitations
  for each row execute function public.backend_only_guard();
create trigger client_policy_reminders_guard
  before insert or update or delete on client_policy_reminders
  for each row execute function public.backend_only_guard();

-- Guard ofert pracy dla właściciela salonu: dozwolone przejścia statusów, migawka nazwy salonu,
-- edycja treści opublikowanej oferty wraca do moderacji. Kolumny moderacji (published_at, expires_at,
-- moderated_by, moderation_note, rejection_reason) nie mają grantu UPDATE dla authenticated –
-- ustawia je wyłącznie app_moderate_job_offer() (service_role).
create or replace function public.job_offers_owner_guard() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user in ('service_role', 'postgres', 'supabase_admin') then
    return new;
  end if;

  if tg_op = 'INSERT' then
    if new.status not in ('draft', 'pending_review') then
      raise exception 'job_offers: nowa oferta może być tylko szkicem albo trafić do moderacji';
    end if;
    select a.display_name into new.employer_name
      from public.client_accounts a where a.id = new.account_id;
    new.published_at := null;
    new.expires_at   := null;
    new.created_by   := (select auth.uid());
    new.submitted_at := case when new.status = 'pending_review' then now() end;
    return new;
  end if;

  -- UPDATE
  if new.account_id is distinct from old.account_id then
    raise exception 'job_offers: nie można przenieść oferty do innego salonu';
  end if;
  if old.status in ('expired', 'removed') then
    raise exception 'job_offers: oferta wygasła lub została usunięta – utwórz nową';
  end if;
  if old.status = 'published' and new.status = 'published'
     and (new.title, new.profession, new.employment_type, new.working_time, new.city, new.voivodeship,
          new.postal_code, new.salary_min, new.salary_max, new.salary_unit, new.salary_basis,
          new.description, new.requirements, new.benefits)
         is distinct from
         (old.title, old.profession, old.employment_type, old.working_time, old.city, old.voivodeship,
          old.postal_code, old.salary_min, old.salary_max, old.salary_unit, old.salary_basis,
          old.description, old.requirements, old.benefits) then
    new.status := 'pending_review';            -- zmiana treści = ponowna moderacja
  end if;
  if new.status is distinct from old.status and not (
       (old.status in ('draft', 'rejected') and new.status in ('draft', 'pending_review'))
    or (old.status = 'pending_review'       and new.status = 'draft')
    or (old.status = 'published'            and new.status in ('pending_review', 'closed'))
  ) then
    raise exception 'job_offers: niedozwolona zmiana statusu % → %', old.status, new.status;
  end if;
  if new.status = 'pending_review' and old.status <> 'pending_review' then
    new.submitted_at := now();
  end if;
  if new.status = 'closed' and old.status <> 'closed' then
    new.closed_at := now();
  end if;
  new.updated_at := now();
  return new;
end $$;
revoke all on function public.job_offers_owner_guard() from public, anon, authenticated;
create trigger job_offers_owner_guard
  before insert or update on job_offers
  for each row execute function public.job_offers_owner_guard();

-- Audyt zmian polis i kont wykonywanych przez personel przez RLS (panel). SECURITY DEFINER, bo
-- authenticated nie ma INSERT na client_audit_log; funkcji wyzwalacza nie da się wywołać przez RPC,
-- a EXECUTE i tak jest odebrane.
create or replace function public.client_audit_staff_change() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_action text;
begin
  if tg_table_name = 'client_policies' then
    v_action := case
      when tg_op = 'INSERT' then 'policy_created'
      when new.published_at is not null and old.published_at is null then 'policy_published'
      else 'policy_updated' end;
    insert into public.client_audit_log (account_id, actor, action, entity, entity_id, payload)
    values (new.account_id,
            coalesce('staff:' || (select auth.uid())::text, 'system'),
            v_action, 'policy', new.id,
            jsonb_build_object('status', new.status));
  elsif tg_table_name = 'client_accounts' then
    v_action := case
      when tg_op = 'INSERT' then 'account_created'
      when new.status = 'suspended' and old.status <> 'suspended' then 'account_suspended'
      when new.status = 'closed' and old.status <> 'closed' then 'account_closed'
      else null end;
    if v_action is not null then
      insert into public.client_audit_log (account_id, actor, action, entity, entity_id, payload)
      values (new.id, coalesce('staff:' || (select auth.uid())::text, 'system'),
              v_action, 'account', new.id, jsonb_build_object('status', new.status));
    end if;
  end if;
  return new;
end $$;
revoke all on function public.client_audit_staff_change() from public, anon, authenticated;
create trigger client_policies_audit after insert or update on client_policies
  for each row execute function public.client_audit_staff_change();
create trigger client_accounts_audit after insert or update on client_accounts
  for each row execute function public.client_audit_staff_change();

-- Dziennik audytu: append-only; usuwanie tylko wpisów starszych niż 24 miesiące [Założenie: retencja]
create or replace function public.client_audit_log_guard() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op = 'UPDATE' then
    raise exception 'client_audit_log: wpisów nie można zmieniać';
  end if;
  if old.created_at > now() - interval '24 months' then
    raise exception 'client_audit_log: wpis objęty okresem retencji';
  end if;
  return old;
end $$;
revoke all on function public.client_audit_log_guard() from public, anon, authenticated;
create trigger client_audit_log_guard before update or delete on client_audit_log
  for each row execute function public.client_audit_log_guard();


-- -----------------------------------------------------------------------------------------------------
-- 7. RLS I GRANTY
-- -----------------------------------------------------------------------------------------------------

alter table client_accounts          enable row level security;
alter table client_members           enable row level security;
alter table client_invitations       enable row level security;
alter table client_policies          enable row level security;
alter table client_policy_notes      enable row level security;
alter table client_policy_documents  enable row level security;
alter table client_policy_reminders  enable row level security;  -- bez polityk: service_role_only (lista w teście CI)
alter table job_offers               enable row level security;
alter table job_applications         enable row level security;
alter table job_offer_reports        enable row level security;
alter table trainings                enable row level security;
alter table training_private_details enable row level security;
alter table training_registrations   enable row level security;
alter table client_audit_log         enable row level security;

alter table client_members          force row level security;
alter table client_invitations      force row level security;
alter table client_policies         force row level security;
alter table client_policy_documents force row level security;
alter table job_applications        force row level security;
alter table training_registrations  force row level security;

revoke all on client_accounts, client_members, client_invitations, client_policies, client_policy_notes,
              client_policy_documents, client_policy_reminders, job_offers, job_applications,
              job_offer_reports, trainings, training_private_details, training_registrations,
              client_audit_log
  from public, anon, authenticated;
revoke all on sequence job_applications_reference_seq from public, anon, authenticated;

-- 7.1 Konta salonów -------------------------------------------------------------------------------
grant select on client_accounts to authenticated;
grant insert (display_name, legal_name, nip, city, crm_ref, source_lead_id, created_by),
      update (display_name, legal_name, nip, city, crm_ref, status, suspended_at, closed_at, updated_at)
  on client_accounts to authenticated;          -- aktywację (status active) wykonuje app_activate_client_account()

create policy client_accounts_member_read on client_accounts
  for select to authenticated
  using (id in (select public.client_account_ids()));
create policy client_accounts_staff_read on client_accounts
  for select to authenticated using (app_is_staff());
create policy client_accounts_staff_insert on client_accounts
  for insert to authenticated
  with check (app_is_staff('admin','agent') and status = 'pending');
create policy client_accounts_staff_update on client_accounts
  for update to authenticated
  using (app_is_staff('admin','agent'))
  with check (app_is_staff('admin','agent') and status in ('pending','suspended','closed')); -- (ponowna) aktywacja tylko funkcją

-- 7.2 Członkostwa i zaproszenia (zapis tylko service_role; guard trigger) --------------------------
grant select on client_members to authenticated;
create policy client_members_self_read on client_members
  for select to authenticated using (user_id = (select auth.uid()));
create policy client_members_owner_read on client_members
  for select to authenticated using (account_id in (select public.client_account_ids('owner')));
create policy client_members_staff_read on client_members
  for select to authenticated using (app_is_staff());

grant select (id, account_id, email, role, expires_at, invited_by_kind, accepted_at, revoked_at, created_at)
  on client_invitations to authenticated;       -- bez token_hash
create policy client_invitations_owner_read on client_invitations
  for select to authenticated using (account_id in (select public.client_account_ids('owner')));
create policy client_invitations_staff_read on client_invitations
  for select to authenticated using (app_is_staff());

-- 7.3 Polisy i dokumenty: właściciel czyta opublikowane; pracownik nie widzi polis; zapis – personel --
grant select on client_policies to authenticated;
grant insert (account_id, product, insurer, product_label, policy_number, status, valid_from, valid_to,
              premium_amount, premium_period, oc_risk_groups, oc_tariff_group, oc_sum_insured,
              oc_legal_protection, oc_team_size_band, oc_individual_quote, pricing_version_id, published_at,
              crm_ref, created_by),
      update (product_label, policy_number, status, valid_from, valid_to, premium_amount, premium_period,
              oc_risk_groups, oc_tariff_group, oc_sum_insured, oc_legal_protection, oc_team_size_band,
              oc_individual_quote, pricing_version_id, published_at, crm_ref, updated_at)
  on client_policies to authenticated;

create policy client_policies_owner_read on client_policies
  for select to authenticated
  using (published_at is not null
         and status <> 'draft'
         and account_id in (select public.client_account_ids('owner')));
create policy client_policies_staff_read on client_policies
  for select to authenticated using (app_is_staff());
create policy client_policies_staff_insert on client_policies
  for insert to authenticated with check (app_is_staff('admin','agent'));
create policy client_policies_staff_update on client_policies
  for update to authenticated
  using (app_is_staff('admin','agent')) with check (app_is_staff('admin','agent'));

grant select, insert (policy_id, body, author) on client_policy_notes to authenticated;
create policy client_policy_notes_staff_read on client_policy_notes
  for select to authenticated using (app_is_staff());
create policy client_policy_notes_staff_insert on client_policy_notes
  for insert to authenticated
  with check (app_is_staff('admin','agent') and author = (select auth.uid()));

grant select on client_policy_documents to authenticated;  -- zapis: serwer (service_role) po walidacji pliku
create policy client_policy_documents_owner_read on client_policy_documents
  for select to authenticated
  using (published_at is not null
         and account_id in (select public.client_account_ids('owner'))
         and exists (select 1 from client_policies p
                     where p.id = policy_id and p.published_at is not null and p.status <> 'draft'));
create policy client_policy_documents_staff_read on client_policy_documents
  for select to authenticated using (app_is_staff());

-- Zgłoszenia szkody: właściciel widzi zgłoszenia swojego salonu (status), zapis – serwer
create policy claims_owner_select on claims_reports
  for select to authenticated
  using (account_id in (select public.client_account_ids('owner')));

-- 7.4 Oferty pracy ----------------------------------------------------------------------------------
-- Publicznie (anon) tylko kolumny ogłoszenia, bez account_id/created_by/notatek moderacji.
-- (W „BEAUTY” anon czyta z job_listings także phone, email i owner_id ogłoszeniodawcy – tu celowo nie.)
grant select (id, slug, status, title, profession, employment_type, working_time, city, voivodeship,
              postal_code, salary_min, salary_max, salary_unit, salary_basis, description, requirements,
              benefits, employer_name, published_at, expires_at)
  on job_offers to anon;
create policy job_offers_public_read on job_offers
  for select to anon
  using (status = 'published' and expires_at > now());

grant select (id, account_id, slug, status, title, profession, employment_type, working_time, city,
              voivodeship, postal_code, salary_min, salary_max, salary_unit, salary_basis, description,
              requirements, benefits, employer_name, submitted_at, published_at, expires_at,
              rejection_reason, closed_at, created_at, updated_at)
  on job_offers to authenticated;               -- bez moderation_note i moderated_by (personel czyta je serwerowo)
grant insert (account_id, slug, status, title, profession, employment_type, working_time, city, voivodeship,
              postal_code, salary_min, salary_max, salary_unit, salary_basis, description, requirements, benefits),
      update (status, title, profession, employment_type, working_time, city, voivodeship, postal_code,
              salary_min, salary_max, salary_unit, salary_basis, description, requirements, benefits)
  on job_offers to authenticated;

create policy job_offers_public_read_auth on job_offers   -- zalogowani widzą katalog jak wszyscy
  for select to authenticated
  using (status = 'published' and expires_at > now());
create policy job_offers_member_read on job_offers        -- właściciel i pracownicy: oferty swojego salonu
  for select to authenticated
  using (account_id in (select public.client_account_ids()));
create policy job_offers_owner_insert on job_offers
  for insert to authenticated
  with check (account_id in (select public.client_account_ids('owner')));
create policy job_offers_owner_update on job_offers
  for update to authenticated
  using (account_id in (select public.client_account_ids('owner')))
  with check (account_id in (select public.client_account_ids('owner')));
create policy job_offers_staff_read on job_offers
  for select to authenticated using (app_is_staff());
-- brak DELETE: oferty się zamyka (closed) albo usuwa moderacyjnie (removed); anonimizacja aplikacji – cron

-- 7.5 Aplikacje kandydatów: czyta i zmienia status WYŁĄCZNIE właściciel salonu; personel Aura nie ma
--     polityki (minimalizacja – salon jest administratorem danych rekrutacyjnych [do weryfikacji]).
grant select (id, reference, offer_id, account_id, status, full_name, email, phone, experience_summary,
              cv_scan_status, future_recruitment_consent, retention_until, withdrawn_at, created_at, updated_at),
      update (status, updated_at)
  on job_applications to authenticated;
create policy job_applications_owner_read on job_applications
  for select to authenticated
  using (anonymized_at is null and account_id in (select public.client_account_ids('owner')));
create policy job_applications_owner_update on job_applications
  for update to authenticated
  using (anonymized_at is null and account_id in (select public.client_account_ids('owner')))
  with check (status in ('viewed','shortlisted','rejected','hired')
              and account_id in (select public.client_account_ids('owner')));

grant select, update (handled_at, handled_by) on job_offer_reports to authenticated;
create policy job_offer_reports_staff_read on job_offer_reports
  for select to authenticated using (app_is_staff());
create policy job_offer_reports_staff_update on job_offer_reports
  for update to authenticated
  using (app_is_staff('admin','agent')) with check (app_is_staff('admin','agent'));

-- 7.6 Szkolenia ---------------------------------------------------------------------------------------
grant select (id, slug, status, title, summary, description, format, city, venue_name, starts_at, ends_at,
              registration_closes_at, capacity, seats_registered, audience, organizer_label, price_kind,
              published_at)
  on trainings to anon, authenticated;
grant insert (slug, status, title, summary, description, format, city, venue_name, starts_at, ends_at,
              registration_closes_at, capacity, per_account_limit, audience, organizer_label, price_kind,
              published_at, created_by),
      update (status, title, summary, description, format, city, venue_name, starts_at, ends_at,
              registration_closes_at, capacity, per_account_limit, audience, organizer_label, price_kind,
              published_at, updated_at)
  on trainings to authenticated;
grant select (per_account_limit, created_by, created_at, updated_at) on trainings to authenticated;

create policy trainings_public_read on trainings
  for select to anon using (status in ('published','cancelled') and published_at is not null);
create policy trainings_public_read_auth on trainings
  for select to authenticated using (status in ('published','cancelled') and published_at is not null);
create policy trainings_staff_read on trainings
  for select to authenticated using (app_is_staff());
create policy trainings_staff_insert on trainings
  for insert to authenticated with check (app_is_staff('admin','agent'));
create policy trainings_staff_update on trainings
  for update to authenticated
  using (app_is_staff('admin','agent')) with check (app_is_staff('admin','agent'));

grant select, insert, update on training_private_details to authenticated;
create policy training_private_registered_read on training_private_details
  for select to authenticated
  using (exists (select 1 from training_registrations r
                 where r.training_id = training_private_details.training_id
                   and r.user_id = (select auth.uid())
                   and r.status = 'registered'));
create policy training_private_staff_all on training_private_details
  for all to authenticated
  using (app_is_staff('admin','agent')) with check (app_is_staff('admin','agent'));

grant select on training_registrations to authenticated;
grant update (status, marked_by, updated_at) on training_registrations to authenticated; -- obecność: personel
create policy training_registrations_self_read on training_registrations
  for select to authenticated using (user_id = (select auth.uid()));
create policy training_registrations_owner_read on training_registrations
  for select to authenticated using (account_id in (select public.client_account_ids('owner')));
create policy training_registrations_staff_read on training_registrations
  for select to authenticated using (app_is_staff());
create policy training_registrations_staff_attendance on training_registrations
  for update to authenticated
  using (app_is_staff('admin','agent'))
  with check (app_is_staff('admin','agent') and status in ('attended','no_show','registered'));

-- 7.7 Dziennik audytu ----------------------------------------------------------------------------------
grant select on client_audit_log to authenticated;
create policy client_audit_owner_read on client_audit_log
  for select to authenticated using (account_id in (select public.client_account_ids('owner')));
create policy client_audit_staff_read on client_audit_log
  for select to authenticated using (app_is_staff());


-- -----------------------------------------------------------------------------------------------------
-- 8. STORAGE: prywatny kubełek na dokumenty polis
--    (istniejący w „BEAUTY” kubełek „dokumenty” jest PUBLICZNY – nie wolno w nim trzymać polis)
-- -----------------------------------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('client-documents', 'client-documents', false, 15728640, array['application/pdf'])
on conflict (id) do update
  set public = false, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

-- Odczyt (= możliwość wygenerowania podpisanego URL sesją użytkownika): tylko opublikowane dokumenty
-- własnego salonu albo personel. Brak polityk INSERT/UPDATE/DELETE dla authenticated: wgrywa serwer
-- (service_role) po walidacji typu, rozmiaru i sygnatury pliku.
create policy client_documents_owner_read on storage.objects
  for select to authenticated
  using (bucket_id = 'client-documents'
         and exists (select 1 from public.client_policy_documents d
                     where d.storage_path = storage.objects.name
                       and d.published_at is not null
                       and d.account_id in (select public.client_account_ids('owner'))));
create policy client_documents_staff_read on storage.objects
  for select to authenticated
  using (bucket_id = 'client-documents' and public.app_is_staff());

-- Faza Z3 (CV kandydatów, dopiero ze skanowaniem AV): kubełek 'job-cv', prywatny, ≤ 5 MB, application/pdf;
-- ścieżki quarantine/{account_id}/… → clean/{account_id}/…; polityka odczytu dla właściciela tylko
-- na prefiksie clean/ i tylko dla aplikacji z cv_scan_status = 'clean'.


-- -----------------------------------------------------------------------------------------------------
-- 9. FUNKCJE ZAPISU (security invoker, wyłącznie service_role)
--    Serwer wywołuje je po zweryfikowaniu sesji (getUser/getClaims – nigdy getSession) i przekazuje
--    p_actor = auth user id z ZWERYFIKOWANEGO tokenu; funkcje same sprawdzają uprawnienia aktora.
-- -----------------------------------------------------------------------------------------------------

-- 9.1 Aktywacja konta: wymaga co najmniej jednej opublikowanej, aktywnej polisy [Założenie]
create or replace function public.app_activate_client_account(
  p_account uuid, p_actor uuid, p_owner_email text, p_token_hash text)
returns uuid
language plpgsql set search_path = '' as $$
declare
  v_invitation uuid;
begin
  if not exists (select 1 from public.admin_users u
                 where u.user_id = p_actor and u.is_active and u.role in ('admin','agent')) then
    raise exception 'activate: brak uprawnień';
  end if;
  if not exists (select 1 from public.client_policies p
                 where p.account_id = p_account and p.status = 'active' and p.published_at is not null) then
    raise exception 'activate: konto bez aktywnej, opublikowanej polisy';
  end if;
  update public.client_accounts
     set status = 'active', activated_at = coalesce(activated_at, now()), activated_by = p_actor, updated_at = now()
   where id = p_account and status in ('pending','suspended');
  if not found then
    raise exception 'activate: konto nie istnieje albo jest zamknięte/aktywne';
  end if;

  insert into public.client_invitations
    (account_id, email, email_normalized, role, token_hash, expires_at, invited_by, invited_by_kind)
  values (p_account, p_owner_email, lower(trim(p_owner_email)), 'owner', p_token_hash,
          now() + interval '7 days', p_actor, 'staff')
  returning id into v_invitation;

  insert into public.client_audit_log (account_id, actor, action, entity, entity_id)
  values (p_account, 'staff:' || p_actor::text, 'account_activated', 'account', p_account),
         (p_account, 'staff:' || p_actor::text, 'invitation_created', 'invitation', v_invitation);
  return v_invitation;
end $$;

-- 9.2 Zaproszenie pracownika przez właściciela (albo dowolnej roli przez personel)
create or replace function public.app_create_invitation(
  p_account uuid, p_actor uuid, p_email text, p_role text, p_token_hash text)
returns uuid
language plpgsql set search_path = '' as $$
declare
  v_kind text;
  v_id   uuid;
begin
  if exists (select 1 from public.admin_users u
             where u.user_id = p_actor and u.is_active and u.role in ('admin','agent')) then
    v_kind := 'staff';
  elsif exists (select 1 from public.client_members m
                join public.client_accounts a on a.id = m.account_id and a.status = 'active'
                where m.account_id = p_account and m.user_id = p_actor
                  and m.role = 'owner' and m.status = 'active') then
    v_kind := 'owner';
    if p_role <> 'employee' then
      raise exception 'invite: właściciel zaprasza tylko pracowników';
    end if;
  else
    raise exception 'invite: brak uprawnień';
  end if;

  -- limity [Założenie]: 15 aktywnych członków i 10 oczekujących zaproszeń na salon
  if (select count(*) from public.client_members m where m.account_id = p_account and m.status = 'active') >= 15
     or (select count(*) from public.client_invitations i
         where i.account_id = p_account and i.accepted_at is null and i.revoked_at is null and i.expires_at > now()) >= 10 then
    raise exception 'invite: osiągnięto limit zespołu';
  end if;
  -- konta personelu Aura nie mogą być członkami salonów – sprawdza app_accept_invitation (rozdział ról)

  update public.client_invitations
     set revoked_at = now()
   where account_id = p_account and email_normalized = lower(trim(p_email))
     and accepted_at is null and revoked_at is null;

  insert into public.client_invitations
    (account_id, email, email_normalized, role, token_hash, expires_at, invited_by, invited_by_kind)
  values (p_account, p_email, lower(trim(p_email)), p_role, p_token_hash, now() + interval '7 days', p_actor, v_kind)
  returning id into v_id;

  insert into public.client_audit_log (account_id, actor, action, entity, entity_id, payload)
  values (p_account, (case v_kind when 'staff' then 'staff:' else 'user:' end) || p_actor::text,
          'invitation_created', 'invitation', v_id, jsonb_build_object('role', p_role));
  return v_id;
end $$;

-- 9.3 Rotacja tokenu (ponowna wysyłka zaproszenia – stary link przestaje działać)
create or replace function public.app_rotate_invitation_token(p_invitation uuid, p_new_token_hash text)
returns void
language plpgsql set search_path = '' as $$
declare
  v_account uuid;
begin
  update public.client_invitations
     set token_hash = p_new_token_hash, expires_at = now() + interval '7 days'
   where id = p_invitation and accepted_at is null and revoked_at is null
  returning account_id into v_account;
  if not found then
    raise exception 'rotate: zaproszenie nieaktywne';
  end if;
  insert into public.client_audit_log (account_id, actor, action, entity, entity_id)
  values (v_account, 'system', 'invitation_rotated', 'invitation', p_invitation);
end $$;

-- 9.4 Przyjęcie zaproszenia: adres konta Auth musi być identyczny z adresem zaproszenia.
--     p_user_email pochodzi z ZWERYFIKOWANEGO użytkownika (auth.getUser() po stronie serwera), nie z formularza.
create or replace function public.app_accept_invitation(p_token_hash text, p_user uuid, p_user_email text)
returns uuid
language plpgsql set search_path = '' as $$
declare
  v_inv public.client_invitations%rowtype;
begin
  select * into v_inv from public.client_invitations
   where token_hash = p_token_hash and accepted_at is null and revoked_at is null and expires_at > now()
   for update;
  if not found then
    raise exception 'accept: zaproszenie wygasło albo zostało użyte';
  end if;
  if lower(trim(p_user_email)) is distinct from v_inv.email_normalized then
    raise exception 'accept: zaproszenie dotyczy innego adresu e-mail';
  end if;
  if exists (select 1 from public.admin_users a where a.user_id = p_user) then
    raise exception 'accept: konto personelu nie może należeć do salonu';
  end if;

  insert into public.client_members (account_id, user_id, role, status, invited_by)
  values (v_inv.account_id, p_user, v_inv.role, 'active', v_inv.invited_by)
  on conflict (account_id, user_id) do update
    set role = excluded.role, status = 'active', revoked_at = null, revoked_by = null;

  update public.client_invitations
     set accepted_at = now(), accepted_user_id = p_user
   where id = v_inv.id;

  insert into public.client_audit_log (account_id, actor, action, entity, entity_id, payload)
  values (v_inv.account_id, 'user:' || p_user::text, 'invitation_accepted', 'invitation', v_inv.id,
          jsonb_build_object('role', v_inv.role));
  return v_inv.account_id;
end $$;

-- 9.5 Akceptacja regulaminu przy pierwszym logowaniu
create or replace function public.app_accept_terms(p_account uuid, p_user uuid, p_terms_version text)
returns void
language plpgsql set search_path = '' as $$
begin
  update public.client_members
     set terms_version = p_terms_version, terms_accepted_at = now()
   where account_id = p_account and user_id = p_user and status = 'active';
  if not found then
    raise exception 'terms: brak aktywnego członkostwa';
  end if;
  insert into public.client_audit_log (account_id, actor, action, entity, entity_id, payload)
  values (p_account, 'user:' || p_user::text, 'terms_accepted', 'member', p_user,
          jsonb_build_object('version', p_terms_version));
end $$;

-- 9.6 Odebranie dostępu członkowi (właściciel → pracownik; personel → każdy, z wyjątkiem ostatniego właściciela)
create or replace function public.app_revoke_member(p_account uuid, p_user uuid, p_actor uuid)
returns void
language plpgsql set search_path = '' as $$
declare
  v_is_staff boolean;
  v_target   public.client_members%rowtype;
begin
  v_is_staff := exists (select 1 from public.admin_users u
                        where u.user_id = p_actor and u.is_active and u.role in ('admin','agent'));
  select * into v_target from public.client_members
   where account_id = p_account and user_id = p_user and status = 'active' for update;
  if not found then
    raise exception 'revoke: brak aktywnego członkostwa';
  end if;
  if not v_is_staff and not (
       v_target.role = 'employee'
       and exists (select 1 from public.client_members m
                   where m.account_id = p_account and m.user_id = p_actor
                     and m.role = 'owner' and m.status = 'active')) then
    raise exception 'revoke: brak uprawnień';
  end if;
  if v_target.role = 'owner' and (select count(*) from public.client_members m
                                  where m.account_id = p_account and m.role = 'owner' and m.status = 'active') <= 1 then
    raise exception 'revoke: salon musi mieć co najmniej jednego właściciela';
  end if;

  update public.client_members
     set status = 'revoked', revoked_at = now(), revoked_by = p_actor
   where account_id = p_account and user_id = p_user;
  -- zapisy pracownika na przyszłe szkolenia anuluje serwer przez app_training_cancel (zwalnia miejsca)
  insert into public.client_audit_log (account_id, actor, action, entity, entity_id)
  values (p_account, (case when v_is_staff then 'staff:' else 'user:' end) || p_actor::text,
          'member_revoked', 'member', p_user);
end $$;

-- 9.7 Moderacja oferty pracy (personel; serwer sprawdza też app_is_staff w sesji z aal2)
create or replace function public.app_moderate_job_offer(
  p_offer uuid, p_actor uuid, p_decision text, p_note text default null, p_reason text default null)
returns void
language plpgsql set search_path = '' as $$
declare
  v_offer public.job_offers%rowtype;
begin
  if not exists (select 1 from public.admin_users u
                 where u.user_id = p_actor and u.is_active and u.role in ('admin','agent')) then
    raise exception 'moderate: brak uprawnień';
  end if;
  select * into v_offer from public.job_offers where id = p_offer for update;
  if not found then
    raise exception 'moderate: brak oferty';
  end if;

  if p_decision = 'publish' and v_offer.status = 'pending_review' then
    update public.job_offers
       set status = 'published',
           published_at = coalesce(published_at, now()),
           expires_at = coalesce(least(expires_at, coalesce(published_at, now()) + interval '30 days'),
                                 coalesce(published_at, now()) + interval '30 days'),   -- [Założenie] 30 dni
           employer_name = (select a.display_name from public.client_accounts a where a.id = v_offer.account_id),
           moderated_by = p_actor, moderation_note = p_note, rejection_reason = null, updated_at = now()
     where id = p_offer;
    -- wygasła ważność przy ponownej moderacji: zamknij zamiast publikować
    if (select expires_at from public.job_offers where id = p_offer) <= now() then
      update public.job_offers set status = 'expired' where id = p_offer;
    end if;
  elsif p_decision = 'reject' and v_offer.status = 'pending_review' then
    if p_reason is null then
      raise exception 'moderate: odrzucenie wymaga powodu dla salonu';
    end if;
    update public.job_offers
       set status = 'rejected', moderated_by = p_actor, moderation_note = p_note,
           rejection_reason = p_reason, updated_at = now()
     where id = p_offer;
  elsif p_decision = 'remove' and v_offer.status in ('published','pending_review','closed') then
    update public.job_offers
       set status = 'removed', moderated_by = p_actor, moderation_note = p_note,
           rejection_reason = p_reason, closed_at = coalesce(closed_at, now()), updated_at = now()
     where id = p_offer;
  else
    raise exception 'moderate: niedozwolona decyzja % dla statusu %', p_decision, v_offer.status;
  end if;

  insert into public.client_audit_log (account_id, actor, action, entity, entity_id, payload)
  values (v_offer.account_id, 'staff:' || p_actor::text,
          case p_decision when 'publish' then 'job_offer_published'
                          when 'reject'  then 'job_offer_rejected'
                          else 'job_offer_removed' end,
          'job_offer', p_offer, jsonb_build_object('from', v_offer.status));
end $$;

-- 9.8 Aplikacja kandydata bez konta (formularz publiczny: Turnstile, rate limit, honeypot, Zod – w serwerze)
create or replace function public.app_create_job_application(p jsonb)
returns text
language plpgsql set search_path = '' as $$
declare
  v_offer     public.job_offers%rowtype;
  v_existing  text;
  v_reference text;
  v_email     text := lower(trim(p->>'email'));
  v_consent   boolean := coalesce((p->>'future_recruitment_consent')::boolean, false);
begin
  -- idempotencja: ponowna wysyłka = ta sama aplikacja
  select reference into v_existing from public.job_applications
   where idempotency_key = (p->>'idempotency_key')::uuid;
  if found then
    return v_existing;
  end if;

  select * into v_offer from public.job_offers
   where slug = p->>'offer_slug' and status = 'published' and expires_at > now();
  if not found then
    raise exception 'apply: oferta niedostępna';
  end if;

  -- deduplikacja: ten sam adres na tę samą ofertę → odpowiedź jak dla nowej aplikacji, bez drugiego wiersza
  select reference into v_existing from public.job_applications
   where offer_id = v_offer.id and email_normalized = v_email and anonymized_at is null;
  if found then
    return v_existing;
  end if;

  -- limit dzienny na ofertę [Założenie: 200] – ochrona salonu przed zalewem
  if (select count(*) from public.job_applications
      where offer_id = v_offer.id and created_at > now() - interval '1 day') >= 200 then
    raise exception 'apply: limit aplikacji';
  end if;

  v_reference := 'AP-' || to_char(now(), 'YYYY') || '-'
                 || lpad(nextval('public.job_applications_reference_seq')::text, 6, '0');

  insert into public.job_applications
    (reference, idempotency_key, offer_id, account_id, full_name, email, email_normalized, phone,
     experience_summary, privacy_notice_version, future_recruitment_consent,
     future_recruitment_consent_version, retention_until)
  values
    (v_reference, (p->>'idempotency_key')::uuid, v_offer.id, v_offer.account_id,
     p->>'full_name', p->>'email', v_email, nullif(p->>'phone', ''),
     p->>'experience_summary', p->>'privacy_notice_version', v_consent,
     case when v_consent then p->>'future_recruitment_consent_version' end,
     -- [Założenie] 90 dni po wygaśnięciu oferty; ze zgodą na przyszłe rekrutacje – 12 miesięcy od aplikacji
     case when v_consent then greatest(now() + interval '12 months', v_offer.expires_at + interval '90 days')
          else v_offer.expires_at + interval '90 days' end);

  insert into public.client_audit_log (account_id, actor, action, entity, entity_id, payload)
  values (v_offer.account_id, 'candidate', 'job_application_received', 'job_application', null,
          jsonb_build_object('offer', v_offer.id, 'reference', v_reference));
  -- powiadomienia (outbox) dodaje serwer w tej samej transakcji: do właściciela bez danych kandydata,
  -- do kandydata potwierdzenie z linkiem wycofania (HMAC id, bez kolumny w bazie)
  return v_reference;
end $$;

-- 9.9 Wycofanie aplikacji przez kandydata (link z HMAC z e-maila potwierdzającego) i anonimizacja
create or replace function public.app_withdraw_job_application(p_reference text)
returns void
language plpgsql set search_path = '' as $$
begin
  update public.job_applications
     set status = 'withdrawn', withdrawn_at = now(), retention_until = now(), updated_at = now()
   where reference = p_reference and anonymized_at is null;
end $$;

create or replace function public.app_anonymize_job_applications()
returns integer
language plpgsql set search_path = '' as $$
declare
  v_count integer;
begin
  with done as (
    update public.job_applications
       set full_name = null, email = null, email_normalized = null, phone = null,
           experience_summary = null, cv_storage_path = null,
           status = 'anonymized', anonymized_at = now(), updated_at = now()
     where anonymized_at is null and retention_until <= now()
    returning account_id
  )
  select count(*) into v_count from done;
  -- obiekty CV w Storage (Faza Z3) usuwa worker przed wywołaniem funkcji
  if v_count > 0 then
    insert into public.client_audit_log (actor, action, entity, payload)
    values ('system', 'job_applications_anonymized', 'job_application', jsonb_build_object('count', v_count));
  end if;
  return v_count;
end $$;

-- 9.10 Wygaszanie ofert (cron, codziennie)
create or replace function public.app_expire_job_offers()
returns integer
language plpgsql set search_path = '' as $$
declare
  v_count integer;
begin
  with done as (
    update public.job_offers set status = 'expired', updated_at = now()
     where status = 'published' and expires_at <= now()
    returning id, account_id
  ), log as (
    insert into public.client_audit_log (account_id, actor, action, entity, entity_id)
    select account_id, 'system', 'job_offer_expired', 'job_offer', id from done
    returning 1
  )
  select count(*) into v_count from log;
  return v_count;
end $$;

-- 9.11 Zapis na szkolenie: blokada wiersza szkolenia, limit miejsc, limit na salon, lista rezerwowa
create or replace function public.app_training_register(p_training uuid, p_user uuid, p_account uuid)
returns text
language plpgsql set search_path = '' as $$
declare
  v_t      public.trainings%rowtype;
  v_role   text;
  v_status text;
  v_prev   text;
begin
  select m.role into v_role from public.client_members m
    join public.client_accounts a on a.id = m.account_id and a.status = 'active'
   where m.account_id = p_account and m.user_id = p_user and m.status = 'active';
  if not found then
    raise exception 'register: brak aktywnego członkostwa';
  end if;

  select * into v_t from public.trainings where id = p_training for update;
  if not found or v_t.status <> 'published' or v_t.published_at is null then
    raise exception 'register: szkolenie niedostępne';
  end if;
  if now() >= coalesce(v_t.registration_closes_at, v_t.starts_at) then
    raise exception 'register: zapisy zamknięte';
  end if;
  if v_t.audience = 'owners' and v_role <> 'owner' then
    raise exception 'register: szkolenie dla właścicieli salonów';
  end if;

  select r.status into v_prev from public.training_registrations r
   where r.training_id = p_training and r.user_id = p_user;
  if v_prev in ('registered','waitlisted') then
    return v_prev;                                         -- idempotentnie
  end if;

  if (select count(*) from public.training_registrations r
      where r.training_id = p_training and r.account_id = p_account
        and r.status in ('registered','waitlisted')) >= v_t.per_account_limit then
    raise exception 'register: limit miejsc dla salonu';
  end if;

  v_status := case when v_t.capacity is null or v_t.seats_registered < v_t.capacity
                   then 'registered' else 'waitlisted' end;

  insert into public.training_registrations (training_id, account_id, user_id, status)
  values (p_training, p_account, p_user, v_status)
  on conflict (training_id, user_id) do update
    set status = excluded.status, account_id = excluded.account_id,
        cancelled_at = null, updated_at = now(), created_at = now();  -- nowa pozycja na liście rezerwowej

  if v_status = 'registered' then
    update public.trainings set seats_registered = seats_registered + 1 where id = p_training;
  end if;

  insert into public.client_audit_log (account_id, actor, action, entity, entity_id, payload)
  values (p_account, 'user:' || p_user::text,
          case v_status when 'registered' then 'training_registered' else 'training_waitlisted' end,
          'training', p_training, '{}'::jsonb);
  return v_status;
end $$;

-- 9.12 Rezygnacja (uczestnik, właściciel salonu albo serwer przy odebraniu dostępu) + awans z listy rezerwowej
create or replace function public.app_training_cancel(p_training uuid, p_user uuid, p_actor uuid)
returns void
language plpgsql set search_path = '' as $$
declare
  v_reg      public.training_registrations%rowtype;
  v_next     uuid;
begin
  perform 1 from public.trainings where id = p_training for update;
  select * into v_reg from public.training_registrations
   where training_id = p_training and user_id = p_user and status in ('registered','waitlisted')
   for update;
  if not found then
    return;
  end if;
  if p_actor <> p_user
     and not exists (select 1 from public.client_members m
                     where m.account_id = v_reg.account_id and m.user_id = p_actor
                       and m.role = 'owner' and m.status = 'active')
     and not exists (select 1 from public.admin_users u
                     where u.user_id = p_actor and u.is_active and u.role in ('admin','agent')) then
    raise exception 'cancel: brak uprawnień';
  end if;

  update public.training_registrations
     set status = 'cancelled', cancelled_at = now(), updated_at = now()
   where id = v_reg.id;

  if v_reg.status = 'registered' then
    select r.id into v_next from public.training_registrations r
     where r.training_id = p_training and r.status = 'waitlisted'
     order by r.created_at
     limit 1 for update skip locked;
    if v_next is not null then
      update public.training_registrations set status = 'registered', updated_at = now() where id = v_next;
      insert into public.client_audit_log (account_id, actor, action, entity, entity_id)
      select r.account_id, 'system', 'training_promoted', 'training_registration', r.id
        from public.training_registrations r where r.id = v_next;
    else
      update public.trainings set seats_registered = greatest(seats_registered - 1, 0) where id = p_training;
    end if;
  end if;

  insert into public.client_audit_log (account_id, actor, action, entity, entity_id)
  values (v_reg.account_id, 'user:' || p_actor::text, 'training_cancelled', 'training_registration', v_reg.id);
end $$;

-- Uprawnienia funkcji zapisu: wyłącznie service_role
revoke execute on function
  public.app_activate_client_account(uuid, uuid, text, text),
  public.app_create_invitation(uuid, uuid, text, text, text),
  public.app_rotate_invitation_token(uuid, text),
  public.app_accept_invitation(text, uuid, text),
  public.app_accept_terms(uuid, uuid, text),
  public.app_revoke_member(uuid, uuid, uuid),
  public.app_moderate_job_offer(uuid, uuid, text, text, text),
  public.app_create_job_application(jsonb),
  public.app_withdraw_job_application(text),
  public.app_anonymize_job_applications(),
  public.app_expire_job_offers(),
  public.app_training_register(uuid, uuid, uuid),
  public.app_training_cancel(uuid, uuid, uuid)
  from public, anon, authenticated;
grant execute on function
  public.app_activate_client_account(uuid, uuid, text, text),
  public.app_create_invitation(uuid, uuid, text, text, text),
  public.app_rotate_invitation_token(uuid, text),
  public.app_accept_invitation(text, uuid, text),
  public.app_accept_terms(uuid, uuid, text),
  public.app_revoke_member(uuid, uuid, uuid),
  public.app_moderate_job_offer(uuid, uuid, text, text, text),
  public.app_create_job_application(jsonb),
  public.app_withdraw_job_application(text),
  public.app_anonymize_job_applications(),
  public.app_expire_job_offers(),
  public.app_training_register(uuid, uuid, uuid),
  public.app_training_cancel(uuid, uuid, uuid)
  to service_role;
grant usage on sequence job_applications_reference_seq to service_role;

-- Test w CI (rozszerzenie packages/db/tests/privileges.test.sql):
--  (1) żadna funkcja w public nie ma EXECUTE dla anon ani PUBLIC; client_account_ids i app_is_staff –
--      jedyne z EXECUTE dla authenticated;
--  (2) client_policy_reminders na liście service_role_only;
--  (3) właściciel salonu A nie widzi żadnego wiersza salonu B w żadnej tabeli (fixture dwóch salonów);
--  (4) pracownik nie widzi client_policies, client_policy_documents, job_applications ani obiektów
--      w kubełku client-documents;
--  (5) anon widzi w job_offers tylko opublikowane, nieprzeterminowane oferty i tylko kolumny publiczne
--      (select account_id jako anon → permission denied);
--  (6) użytkownik z zweryfikowanym TOTP i sesją aal1 dostaje pusty client_account_ids();
--  (7) próba UPDATE published_at przez właściciela → permission denied; niedozwolone przejście statusu → wyjątek.
