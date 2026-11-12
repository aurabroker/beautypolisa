-- =====================================================================================================
-- Strefa Klienta BeautyPolisa: konta salonów, polisy i dokumenty, tablica „Dam pracę”, „Szkolenia”
-- (z kontami organizatorów szkoleń)
-- Migracja dla NOWEGO, dedykowanego projektu Supabase portalu (decyzja D2), uruchamiana PO schema.sql
-- i rls-policies.sql (korzysta z: lead_product, leads, pricing_versions, claims_reports, outbox_emails,
-- admin_users, app_is_staff()). Opis i uzasadnienia: 11-strefa-klienta.md, wersja 1.1 – po decyzjach
-- zleceniodawcy z 11.11.2026:
--   D-A konto przy KAŻDEJ polisie kupionej przez BeautyPolisa (nie tylko OC),
--   D-B po wygaśnięciu ostatniej polisy konto i dostęp do „Dam pracę” i „Szkoleń” zostają,
--   D-C „Dam pracę” to WYŁĄCZNIE tablica ogłoszeń: brak kont, profili i danych kandydatów, brak bazy CV,
--       wyszukiwania, polecania i dopasowywania kandydatów; kandydat czyta ogłoszenie i kontaktuje się
--       z salonem bezpośrednio,
--   D-D szkolenia dodają salony i firmy szkoleniowe (rola „organizator szkoleń”, bez polisy,
--       po weryfikacji przez Aura); publikacja po moderacji,
--   D-E „Szukam pracy” (ogłoszenia osób szukających pracy) przygotowane, ale NIEAKTYWNE – przełącznik
--       app_feature_flags('szukam_pracy') domyślnie wyłączony do decyzji zleceniodawcy po sprawdzeniu
--       prawnym (KRAZ, RODO, DSA); nadal tylko tablica – bez polecania i dopasowywania kandydatów.
--
-- Konwencje (jak w schema.sql / rls-policies.sql):
--  * domyślne granty odebrane w schema.sql (ALTER DEFAULT PRIVILEGES … FROM public, anon, authenticated);
--    mimo to każda tabela i funkcja ma tu jawne REVOKE + jawne GRANT;
--  * RLS włączone na każdej tabeli; tabele z danymi osobowymi dodatkowo FORCE ROW LEVEL SECURITY;
--  * funkcje zapisu z niezmiennikami między kontami (zaproszenia, zapisy z limitem miejsc, moderacja,
--    formularz kontaktowy „Dam pracę”) wykonywalne WYŁĄCZNIE przez service_role (serwer), security invoker;
--  * SECURITY DEFINER tylko tam, gdzie RLS bez niego wpada w rekurencję (client_account_ids,
--    organizer_ids), w wyzwalaczu audytu i w funkcji retencji dziennika – zawsze z set search_path = ''
--    i pełnymi nazwami obiektów, bez EXECUTE dla public/anon (błąd z audytu projektu „BEAUTY”:
--    can_manage_salon, is_katalog_admin, is_platform_admin, katalog_set_admin wykonywalne przez anon);
--  * dwie rozłączne rodziny uprawnień klientów: client_account_ids() (salony) i organizer_ids()
--    (organizatorzy szkoleń); żadna polityka nie łączy obu funkcji;
--  * polityki dla anon nigdy nie wywołują app_is_staff() (patrz komentarz w rls-policies.sql);
--  * żadnych widoków SECURITY DEFINER (w „BEAUTY” 3 takie widoki to poziom ERROR w Security Advisor);
--  * treści od salonów i organizatorów: tekst zwykły – CHECK w bazie odrzuca „<”, „>” i adresy URL
--    niezależnie od walidacji Zod na serwerze (obrona w głąb przed wstrzyknięciem do HTML i JSON-LD).
-- Plik jest wzorcem: przed wdrożeniem dzielimy go na migracje w supabase/migrations i pokrywamy testami
-- uprawnień z sekcji 9.6 dokumentu 11.
-- =====================================================================================================


-- -----------------------------------------------------------------------------------------------------
-- 1. KONTA SALONÓW, CZŁONKOSTWA, ZAPROSZENIA
-- -----------------------------------------------------------------------------------------------------

create table client_accounts (
  id                uuid primary key default gen_random_uuid(),
  display_name      text not null check (char_length(display_name) between 2 and 120), -- nazwa salonu w Strefie i w ogłoszeniach
  legal_name        text check (char_length(legal_name) <= 200),
  nip               text check (nip ~ '^[0-9]{10}$'),
  city              text check (char_length(city) <= 80),
  status            text not null default 'pending'
                      check (status in ('pending','active','suspended','closed')),
  crm_ref           text check (char_length(crm_ref) <= 64),      -- id firmy w CRM Aura (projekt „BEAUTY”); tylko personel
  source_lead_id    uuid references leads(id) on delete set null,  -- lead, z którego powstała polisa (jeśli był); tylko personel
  team_confirmed_at timestamptz,             -- coroczne potwierdzenie składu zespołu przez właściciela [Założenie, D-B]
  activated_at      timestamptz,
  activated_by      uuid references auth.users(id) on delete set null,
  suspended_at      timestamptz,
  closed_at         timestamptz,
  created_by        uuid references auth.users(id) on delete set null,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
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
  last_seen_at      timestamptz,              -- ustawia serwer przy logowaniu; podstawa wygaszania nieaktywnych (D-B)
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
--    D-A: konto przysługuje przy każdym produkcie z lead_product (OC beauty, Tax Protect, utrata dochodu,
--    NNW dzieci, grupowe ERGO, opieka medyczna). D-B: polisy po wygaśnięciu zostają widoczne jako
--    archiwalne (status expired/renewed/cancelled), konto nie jest automatycznie zawieszane.
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
  crm_ref             text check (char_length(crm_ref) <= 64), -- id polisy w CRM (crm_policies.id); tylko personel
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
-- (właścicieli salonów, organizatorów i personel) – kolumna „notes” w client_policies byłaby widoczna dla klienta.
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
-- Nowe szablony outbox (bez załączników; w treści tylko link do Strefy, bez kwot składek):
-- client_invite, client_policy_published, renewal_60, renewal_30, renewal_14, claim_received,
-- job_offer_submitted_team, job_offer_published, job_offer_rejected, job_offer_expiring,
-- job_relay (wiadomość z formularza kontaktowego ogłoszenia do salonu – treść usuwana po wysyłce, dok. 11 pkt 11.3),
-- organizer_invite, training_submitted_team, training_published, training_rejected, training_changed,
-- training_registered, training_waitlisted, training_promoted, training_reminder_24h, training_cancelled.
-- Token zaproszenia NIGDY nie trafia do payload: przy ponowieniu wysyłki serwer rotuje token
-- (app_rotate_invitation_token) i wysyła nowy link, a poprzedni przestaje działać.


-- -----------------------------------------------------------------------------------------------------
-- 3. „DAM PRACĘ” – TABLICA OGŁOSZEŃ (decyzja D-C)
--    Platforma przechowuje wyłącznie ogłoszenia salonów i sposób kontaktu wybrany przez salon.
--    NIE MA tu (i nie wolno dodawać): aplikacji, danych, kont ani profili kandydatów, plików CV,
--    statusów rekrutacji, wyszukiwarki kandydatów, rekomendacji ani dopasowywania. Moderacja Aura
--    dotyczy wyłącznie treści ogłoszenia.
-- -----------------------------------------------------------------------------------------------------

create table job_offers (
  id               uuid primary key default gen_random_uuid(),
  account_id       uuid not null references client_accounts(id) on delete cascade,
  slug             text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and char_length(slug) <= 120), -- nadaje guard
  status           text not null default 'draft'
                     check (status in ('draft','pending_review','published','rejected','closed','expired','removed')),
  content_version  integer not null default 1,  -- rośnie przy każdej zmianie treści i każdym wysłaniu do moderacji
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
  -- tekst zwykły: bez znaczników i adresów URL (kontakt wyłącznie w bloku job_offer_contacts)
  description      text not null check (char_length(description) between 200 and 5000),
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
  check (expires_at is null or published_at is null or expires_at <= published_at + interval '60 days'),
  check (concat_ws(' ', title, description, requirements, benefits) !~ '[<>]'),
  check (concat_ws(' ', title, description, requirements, benefits) !~* '(https?://|www\.)')
);
create index job_offers_public_idx  on job_offers (status, expires_at desc);
create index job_offers_account_idx on job_offers (account_id, status);
create index job_offers_filter_idx  on job_offers (profession, voivodeship) where status = 'published';

-- Sposób kontaktu wybrany przez salon. Osobna tabela BEZ grantu dla anon: dane kontaktowe nie trafiają
-- do listy, JSON-LD ani sitemap; serwer pokazuje je tylko na stronie pojedynczego ogłoszenia po kliknięciu
-- „Pokaż kontakt” (Turnstile + limit na IP). Domyślnie „formularz”: wiadomość kandydata trafia e-mailem
-- na adres salonu (email), którego strona nie pokazuje. Usuwane 30 dni po zamknięciu/wygaśnięciu oferty.
create table job_offer_contacts (
  offer_id     uuid primary key references job_offers(id) on delete cascade,
  account_id   uuid not null references client_accounts(id) on delete cascade, -- ustawia guard (= job_offers.account_id)
  method       text not null default 'formularz' check (method in ('formularz','email','telefon')),
  email        text check (char_length(email) <= 254 and email ~ '^[^@[:space:]<>]+@[^@[:space:]<>]+\.[a-z]{2,}$'),
  phone        text check (phone ~ '^\+?[0-9 ]{9,16}$'),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  check ((method in ('formularz','email') and email is not null) or (method = 'telefon' and phone is not null))
);

-- Ślad przekazania wiadomości z formularza „Dam pracę” – BEZ danych osobowych (bez nadawcy, treści i IP).
-- Służy do dziennego limitu na ogłoszenie i do linku „Zgłoś nadużycie” w e-mailu do salonu. Retencja 30 dni.
create table job_offer_relay_log (
  id          uuid primary key default gen_random_uuid(),
  offer_id    uuid not null references job_offers(id) on delete cascade,
  outbox_id   uuid references outbox_emails(id) on delete set null,
  created_at  timestamptz not null default now()
);
create index job_offer_relay_log_offer_idx on job_offer_relay_log (offer_id, created_at desc);


-- -----------------------------------------------------------------------------------------------------
-- 3a. „SZUKAM PRACY” – FUNKCJA NIEAKTYWNA (decyzja D-E z 11.11.2026)
--     Ogłoszenia osób szukających pracy na tablicy „Dam pracę”. Zaprojektowane i przygotowane, ale
--     WYŁĄCZONE przełącznikiem app_feature_flags('szukam_pracy') = false do czasu decyzji zleceniodawcy
--     po sprawdzeniu prawnym (KRAZ – nowa okoliczność względem tablicy samych ofert, RODO, DSA).
--     Nadal wyłącznie tablica (D-C): platforma i Aura nie rekomendują, nie wyszukują, nie dobierają,
--     nie oceniają, nie sortują i nie dopasowują kandydatów. NIE MA tu (i nie wolno dodawać): kont
--     i profili kandydatów, zdjęć, nazwisk, telefonów, CV, wyszukiwarki pełnotekstowej po osobach,
--     rekomendacji ani dopasowywania. Przy wyłączonym przełączniku: funkcje zapisu odmawiają,
--     polityki RLS nie zwracają wierszy; wyjątek – usunięcie ogłoszenia przez autora i retencja
--     (tylko zmniejszają ilość danych).
-- -----------------------------------------------------------------------------------------------------

-- Przełączniki funkcji. Domyślnie WYŁĄCZONE. Zmienia wyłącznie app_set_feature_flag() (admin Aura,
-- sesja aal2 sprawdzona przez serwer) z odwołaniem do decyzji zleceniodawcy; każda zmiana w dzienniku.
create table app_feature_flags (
  key           text primary key check (key in ('szukam_pracy')),
  enabled       boolean not null default false,
  decision_ref  text check (char_length(decision_ref) between 5 and 200), -- np. „decyzja zleceniodawcy z … po opinii prawnej …”
  changed_by    uuid references auth.users(id) on delete set null,
  changed_at    timestamptz not null default now(),
  check (not enabled or decision_ref is not null)
);
insert into app_feature_flags (key, enabled) values ('szukam_pracy', false);

-- Ogłoszenie osoby szukającej pracy. Bez konta: osoba podaje e-mail, potwierdza go linkiem i zarządza
-- ogłoszeniem (edycja, przedłużenie, usunięcie) linkiem z e-maila. W bazie tylko skróty SHA-256 tokenów.
-- Minimalny zakres danych: imię (jedno słowo – bez nazwiska), zawód, miasto i województwo, formy
-- współpracy, doświadczenie, dostępność od, krótki opis ≤ 500 znaków. Bez zdjęcia, nazwiska, telefonu;
-- e-mail nigdy nie jest pokazywany (brak grantu kolumnowego). Tylko osoby pełnoletnie (oświadczenie).
-- Widoczne wyłącznie dla zalogowanych członków aktywnych kont salonów i tylko przy włączonym przełączniku;
-- anon nie ma żadnego grantu (strony noindex, nigdy publiczne). Ważność 30 dni. Administrator danych: Aura.
create table candidate_ads (
  id                 uuid primary key default gen_random_uuid(),
  status             text not null default 'unconfirmed'
                       check (status in ('unconfirmed','pending_review','published','rejected','expired','removed')),
  content_version    integer not null default 1,     -- rośnie przy każdej edycji; moderator zatwierdza konkretną wersję
  email              text not null check (char_length(email) <= 254
                       and email ~ '^[^@[:space:]<>]+@[^@[:space:]<>]+\.[a-z]{2,}$'),   -- PII, nigdy nie wyświetlany
  email_normalized   text not null,
  confirm_token_hash text unique check (confirm_token_hash ~ '^[0-9a-f]{64}$'),
  confirm_expires_at timestamptz,
  manage_token_hash  text unique check (manage_token_hash ~ '^[0-9a-f]{64}$'),  -- rotowany przy każdej wysyłce linku
  first_name         text not null check (first_name ~ '^[^[:space:][:digit:][:punct:]]{2,30}(-[^[:space:][:digit:][:punct:]]{2,30})?$'),
  profession         text not null check (profession in ('kosmetolog','fryzjer','podolog','linergistka',
                       'stylistka-paznokci','tatuazysta','recepcja','inny')),
  city               text not null check (char_length(city) between 2 and 80 and city !~ '[[:digit:]<>@]'),
  voivodeship        text not null check (voivodeship in ('dolnoslaskie','kujawsko-pomorskie','lubelskie','lubuskie',
                       'lodzkie','malopolskie','mazowieckie','opolskie','podkarpackie','podlaskie','pomorskie',
                       'slaskie','swietokrzyskie','warminsko-mazurskie','wielkopolskie','zachodniopomorskie')),
  cooperation_forms  text[] not null check (cardinality(cooperation_forms) between 1 and 5
                       and cooperation_forms <@ array['umowa-o-prace','umowa-zlecenie','b2b','najem-stanowiska','inna']),
  experience         text not null check (experience in ('do-1-roku','1-3-lata','3-5-lat','powyzej-5-lat')),
  available_from     date not null,
  description        text check (char_length(description) <= 500),
  adult_confirmed    boolean not null check (adult_confirmed),           -- oświadczenie 18+
  notice_version     text not null check (char_length(notice_version) <= 40), -- wersja regulaminu i klauzuli informacyjnej
  confirmed_at       timestamptz,
  submitted_at       timestamptz,
  published_at       timestamptz,
  extended_at        timestamptz,
  expires_at         timestamptz,
  moderated_by       uuid references auth.users(id) on delete set null,
  moderation_note    text check (char_length(moderation_note) <= 1000),  -- wewnętrzna; bez grantu
  rejection_reason   text check (char_length(rejection_reason) <= 1000), -- uzasadnienie decyzji dla autora (DSA)
  removed_at         timestamptz,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  check (status <> 'unconfirmed' or (confirm_token_hash is not null and confirm_expires_at is not null)),
  check (status in ('unconfirmed') or confirmed_at is not null),          -- publikacja tylko po potwierdzeniu e-maila
  check (status <> 'published' or (published_at is not null and expires_at is not null)),
  check (expires_at is null or published_at is null
         or expires_at <= coalesce(extended_at, published_at) + interval '30 days'),
  check (status not in ('rejected','removed') or rejection_reason is not null),
  -- tekst zwykły: bez znaczników, adresów URL, adresów e-mail i numerów telefonów (kontakt tylko przez formularz)
  check (coalesce(description, '') !~ '[<>@]'),
  check (coalesce(description, '') !~* '(https?://|www\.)'),
  check (coalesce(description, '') !~ '[0-9][0-9 ()./-]{6,}[0-9]')
);
create index candidate_ads_public_idx on candidate_ads (status, expires_at desc);
create index candidate_ads_filter_idx on candidate_ads (profession, voivodeship) where status = 'published';
create index candidate_ads_email_idx  on candidate_ads (email_normalized);

-- Ślad wysyłki wiadomości salonu do autora ogłoszenia – BEZ treści wiadomości i bez adresu odbiorcy
-- (treść i adres istnieją tylko w outbox_emails do wysyłki, potem app_purge_relay_messages je czyści).
-- Służy do limitów i obsługi nadużyć. Retencja 30 dni [Założenie]. Tylko service_role.
create table candidate_ad_contact_log (
  id          uuid primary key default gen_random_uuid(),
  ad_id       uuid references candidate_ads(id) on delete set null,
  account_id  uuid not null references client_accounts(id) on delete cascade,
  sent_by     uuid references auth.users(id) on delete set null,
  outbox_id   uuid references outbox_emails(id) on delete set null,
  created_at  timestamptz not null default now()
);
create index candidate_ad_contact_log_ad_idx      on candidate_ad_contact_log (ad_id, created_at desc);
create index candidate_ad_contact_log_account_idx on candidate_ad_contact_log (account_id, created_at desc);


-- -----------------------------------------------------------------------------------------------------
-- 4. „SZKOLENIA” – ORGANIZATORZY (D-D), KATALOG, SZCZEGÓŁY DLA ZAPISANYCH, ZAPISY, KONTAKTY UCZESTNIKÓW
-- -----------------------------------------------------------------------------------------------------

-- Organizator szkoleń: firma szkoleniowa albo salon. Nie wymaga polisy. Profil zakłada i weryfikuje
-- personel Aura (NIP/KRS/CEIDG, adres e-mail w domenie firmy, telefon zwrotny, podpisana umowa
-- organizatora – Założenie); organizator tylko czyta swój profil (zmiany na wniosek, P1: samodzielna
-- edycja opisu z ponowną moderacją). Znaczek: „Organizator zweryfikowany przez Aura Consulting
-- (dane firmy)” – potwierdza tożsamość, nie jakość szkoleń.
create table training_organizers (
  id              uuid primary key default gen_random_uuid(),
  kind            text not null check (kind in ('firma','salon')),
  account_id      uuid references client_accounts(id) on delete set null, -- gdy organizatorem jest salon z kontem; tylko personel
  display_name    text not null check (char_length(display_name) between 2 and 120), -- nazwa pokazywana przy szkoleniach
  legal_name      text not null check (char_length(legal_name) between 2 and 200),
  nip             text not null check (nip ~ '^[0-9]{10}$'),
  city            text check (char_length(city) <= 80),
  website         text check (website ~ '^https://[^[:space:]<>"]+$' and char_length(website) <= 200),
  description     text check (char_length(description) <= 1500 and description !~ '[<>]'
                              and description !~* '(https?://|www\.)'),
  status          text not null default 'pending' check (status in ('pending','active','suspended')),
  verified_at     timestamptz,
  verified_by     uuid references auth.users(id) on delete set null,       -- tylko personel
  terms_version   text,                                                     -- wersja umowy organizatora
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  check (status <> 'active' or (verified_at is not null and verified_by is not null and terms_version is not null)),
  check (kind <> 'salon' or account_id is not null)
);
create unique index training_organizers_nip_uq on training_organizers (nip);

create table organizer_members (
  organizer_id   uuid not null references training_organizers(id) on delete cascade,
  user_id        uuid not null references auth.users(id) on delete cascade,
  role           text not null check (role in ('owner','member')),
  status         text not null default 'active' check (status in ('active','revoked')),
  display_name   text check (char_length(display_name) <= 120),
  invited_by     uuid references auth.users(id) on delete set null,
  revoked_by     uuid references auth.users(id) on delete set null,
  revoked_at     timestamptz,
  last_seen_at   timestamptz,
  created_at     timestamptz not null default now(),
  primary key (organizer_id, user_id),
  check (status <> 'revoked' or revoked_at is not null)
);
create index organizer_members_user_idx on organizer_members (user_id) where status = 'active';

-- Osobne zaproszenia organizatorów: token zaproszenia salonu nie zadziała jako zaproszenie organizatora i odwrotnie
create table organizer_invitations (
  id                uuid primary key default gen_random_uuid(),
  organizer_id      uuid not null references training_organizers(id) on delete cascade,
  email             text,                     -- PII; czyszczone 30 dni po przyjęciu/wygaśnięciu (cron)
  email_normalized  text,
  role              text not null check (role in ('owner','member')),
  token_hash        text not null unique check (token_hash ~ '^[0-9a-f]{64}$'),
  expires_at        timestamptz not null,
  invited_by        uuid references auth.users(id) on delete set null,
  invited_by_kind   text not null check (invited_by_kind in ('staff','owner')),
  accepted_at       timestamptz,
  accepted_user_id  uuid references auth.users(id) on delete set null,
  revoked_at        timestamptz,
  created_at        timestamptz not null default now(),
  check (invited_by_kind = 'staff' or role = 'member')
);
create unique index organizer_invitations_pending_uq
  on organizer_invitations (organizer_id, email_normalized)
  where accepted_at is null and revoked_at is null;

create table trainings (
  id                     uuid primary key default gen_random_uuid(),
  organizer_id           uuid not null references training_organizers(id) on delete restrict, -- niezmienne (guard)
  slug                   text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and char_length(slug) <= 120), -- nadaje guard
  status                 text not null default 'draft'
                           check (status in ('draft','pending_review','published','rejected','cancelled','completed','removed')),
  content_version        integer not null default 1,
  title                  text not null check (char_length(title) between 5 and 160),
  summary                text not null check (char_length(summary) <= 300),
  description            text not null check (char_length(description) <= 8000),
  format                 text not null check (format in ('stacjonarne','online','hybrydowe')),
  city                   text check (char_length(city) <= 80),
  venue_name             text check (char_length(venue_name) <= 120),
  starts_at              timestamptz not null,
  ends_at                timestamptz not null,
  registration_closes_at timestamptz,
  capacity               integer check (capacity is null or capacity > 0),  -- NULL = bez limitu; zmiana tylko app_training_set_capacity
  seats_registered       integer not null default 0 check (seats_registered >= 0), -- licznik prowadzony przez funkcje zapisu
  per_account_limit      smallint not null default 3 check (per_account_limit > 0),
  audience               text not null default 'all_members' check (audience in ('all_members','owners')),
  -- płatności online poza MVP: przy szkoleniu płatnym strona pokazuje cenę brutto,
  -- a fakturę wystawia organizator bezpośrednio uczestnikowi/salonowi [Założenie]
  price_kind             text not null default 'bezplatne' check (price_kind in ('bezplatne','platne')),
  price_gross_pln        numeric(10,2) check (price_gross_pln > 0),
  submitted_at           timestamptz,
  published_at           timestamptz,
  moderated_by           uuid references auth.users(id) on delete set null,
  moderation_note        text check (char_length(moderation_note) <= 1000),  -- bez grantu dla authenticated
  rejection_reason       text check (char_length(rejection_reason) <= 500),  -- widoczna dla organizatora
  cancelled_at           timestamptz,
  created_by             uuid references auth.users(id) on delete set null,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  check (ends_at > starts_at),
  check (capacity is null or seats_registered <= capacity),
  check (format = 'online' or city is not null),
  check ((price_kind = 'platne') = (price_gross_pln is not null)),
  check (status <> 'published' or published_at is not null),
  check (concat_ws(' ', title, summary, description, venue_name, city) !~ '[<>]'),
  check (concat_ws(' ', title, summary, description, venue_name, city) !~* '(https?://|www\.)')
);
create index trainings_catalog_idx   on trainings (status, starts_at);
create index trainings_organizer_idx on trainings (organizer_id, status);

create table training_private_details (               -- widoczne tylko dla zapisanych, organizatora i personelu
  training_id     uuid primary key references trainings(id) on delete cascade,
  -- tylko hosty z listy dozwolonych [Założenie: Zoom, Microsoft Teams, Google Meet]; host pokazywany uczestnikowi
  online_join_url text check (char_length(online_join_url) <= 500 and online_join_url ~
                    '^https://([a-z0-9-]+\.)*(zoom\.us|teams\.microsoft\.com|meet\.google\.com)(/[^[:space:]<>"]*)?$'),
  venue_address   text check (char_length(venue_address) <= 200),
  instructions    text check (char_length(instructions) <= 2000),
  check (concat_ws(' ', venue_address, instructions) !~ '[<>]'),
  check (concat_ws(' ', venue_address, instructions) !~* '(https?://|www\.)')
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

-- Dane uczestnika dla organizatora – minimalna migawka, BEZ user_id i account_id (organizator nie może
-- łączyć uczestników z kontami ani śledzić ich między szkoleniami). Wypełnia app_training_register po
-- wyświetleniu informacji „Twoje imię, nazwisko i e-mail otrzyma organizator {nazwa}, który jest
-- administratorem tych danych” (wersja w notice_version). Organizator widzi tylko wiersze registered/
-- attended/no_show swoich szkoleń. Usuwane 30 dni po zakończeniu szkolenia [Założenie].
create table training_participant_contacts (
  registration_id   uuid primary key references training_registrations(id) on delete cascade,
  training_id       uuid not null references trainings(id) on delete cascade,
  organizer_id      uuid not null references training_organizers(id) on delete cascade,
  status            text not null check (status in ('registered','waitlisted','attended','no_show')),
  participant_name  text not null check (char_length(participant_name) between 2 and 120),
  participant_email text not null check (char_length(participant_email) <= 254),
  salon_name        text check (char_length(salon_name) <= 200),   -- tylko szkolenia płatne (dane do faktury)
  notice_version    text not null,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create index training_participant_contacts_idx on training_participant_contacts (organizer_id, training_id);


-- -----------------------------------------------------------------------------------------------------
-- 5. ZGŁOSZENIA NADUŻYĆ („Zgłoś nadużycie” przy ogłoszeniu, w e-mailu z formularza, przy szkoleniu,
--    przy ogłoszeniu „Szukam pracy” – D-E, nieaktywne). Bez danych zgłaszającego; zapis przez serwer
--    (Turnstile, limit), kolejka w /panel. details – uzasadnienie zgłoszenia treści nielegalnej (DSA).
-- -----------------------------------------------------------------------------------------------------

create table abuse_reports (
  id              bigint generated always as identity primary key,
  target          text not null check (target in ('job_offer','job_relay_message','training','organizer',
                    'candidate_ad','candidate_contact')),
  job_offer_id    uuid references job_offers(id) on delete cascade,
  relay_id        uuid references job_offer_relay_log(id) on delete set null,
  training_id     uuid references trainings(id) on delete cascade,
  organizer_id    uuid references training_organizers(id) on delete cascade,
  candidate_ad_id uuid references candidate_ads(id) on delete cascade,
  candidate_contact_id uuid references candidate_ad_contact_log(id) on delete set null, -- wiadomość salonu zgłoszona przez autora
  reported_account_id  uuid references client_accounts(id) on delete cascade,          -- salon, którego dotyczy zgłoszenie
  reason          text not null check (reason in ('nieaktualne','dyskryminacja','oszustwo','phishing','spam',
                    'nielegalne','niepelnoletnia','inne')),
  details         text check (char_length(details) <= 1000 and details !~ '[<>]'),
  handled_at      timestamptz,
  handled_by      uuid references auth.users(id) on delete set null,
  created_at      timestamptz not null default now(),
  check (num_nonnulls(job_offer_id, training_id, organizer_id, candidate_ad_id, reported_account_id) >= 1)
);


-- -----------------------------------------------------------------------------------------------------
-- 6. DZIENNIK AUDYTU (append-only, bez PII w payload)
-- -----------------------------------------------------------------------------------------------------

create table client_audit_log (
  id            bigint generated always as identity primary key,
  account_id    uuid references client_accounts(id) on delete set null,
  organizer_id  uuid references training_organizers(id) on delete set null,
  -- actor: system[:kontekst] (np. system:import:2026-11-20, system:crm-sync, system:cron), user:<uuid>, staff:<uuid>
  actor         text not null check (actor ~ '^(system(:[a-z0-9_.:-]{1,60})?|user:[0-9a-f-]{36}|staff:[0-9a-f-]{36})$'),
  action        text not null check (action in (
                  'account_created','account_activated','account_suspended','account_closed','team_confirmed',
                  'invitation_created','invitation_rotated','invitation_accepted','invitation_revoked',
                  'member_revoked','terms_accepted',
                  'policy_created','policy_updated','policy_published','document_uploaded','document_published',
                  'document_downloaded','claim_reported','renewal_requested',
                  'job_offer_submitted','job_offer_published','job_offer_rejected','job_offer_closed',
                  'job_offer_removed','job_offer_expired','job_contacts_purged',
                  'organizer_created','organizer_updated','organizer_verified','organizer_suspended',
                  'organizer_invitation_created','organizer_invitation_accepted','organizer_member_revoked',
                  'organizer_participants_viewed','organizer_participants_exported',
                  'training_published','training_rejected','training_removed','training_event_cancelled',
                  'training_capacity_changed',
                  'training_registered','training_waitlisted','training_promoted','training_cancelled',
                  'training_attendance','training_contacts_purged',
                  'feature_flag_changed','candidate_ad_published','candidate_ad_rejected','candidate_ad_removed',
                  'candidate_contact_sent')),
  entity        text not null check (entity in ('account','member','invitation','policy','document','claim',
                  'job_offer','training','training_registration','organizer','organizer_member',
                  'feature_flag','candidate_ad')),
  entity_id     uuid,
  payload       jsonb not null default '{}'::jsonb check (pg_column_size(payload) <= 2048), -- np. {"from":"draft","to":"pending_review"}
  request_id    text check (char_length(request_id) <= 64),
  created_at    timestamptz not null default now()
);
create index client_audit_log_account_idx   on client_audit_log (account_id, created_at desc);
create index client_audit_log_organizer_idx on client_audit_log (organizer_id, created_at desc);


-- -----------------------------------------------------------------------------------------------------
-- 7. FUNKCJE POMOCNICZE RLS I WYZWALACZE
-- -----------------------------------------------------------------------------------------------------

-- Salony, do których bieżący użytkownik należy (aktywne członkostwo w aktywnym koncie, wskazane role).
-- SECURITY DEFINER, bo polityka na client_members („właściciel widzi zespół”) odwołuje się do
-- client_members – funkcja invoker wpadłaby w nieskończoną rekurencję polityk.
-- Ograniczenia: zwraca wyłącznie dane o WYWOŁUJĄCYM (auth.uid()), bez parametru user_id; search_path = '';
-- EXECUTE tylko dla authenticated. MFA egzekwowane w bazie, nie tylko w UI:
--  * właściciel – zawsze sesja aal2 (TOTP obowiązkowy dla właścicieli: rekomendacja do potwierdzenia, Q4;
--    przy odmowie zleceniodawcy warunek dla roli owner zastępuje się warunkiem jak dla pracownika);
--  * pracownik – aal2 tylko wtedy, gdy sam włączył TOTP.
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
      or (m.role = 'employee'
          and not exists (select 1 from auth.mfa_factors f
                          where f.user_id = (select auth.uid()) and f.status = 'verified'))
    );
$$;
revoke all     on function public.client_account_ids(text[]) from public, anon;
grant  execute on function public.client_account_ids(text[]) to authenticated;

-- Organizatorzy, do których należy wywołujący (aktywne członkostwo, organizator aktywny i zweryfikowany).
-- Ten sam wzorzec co client_account_ids(): bez parametrów, search_path = '', EXECUTE tylko authenticated.
-- Organizator przetwarza dane uczestników, więc sesja aal2 (TOTP) jest wymagana zawsze.
create or replace function public.organizer_ids()
returns setof uuid
language sql stable security definer set search_path = '' as $$
  select om.organizer_id
  from public.organizer_members om
  join public.training_organizers o on o.id = om.organizer_id
  where om.user_id = (select auth.uid())
    and om.status = 'active'
    and o.status = 'active'
    and o.verified_at is not null
    and coalesce((select auth.jwt()) ->> 'aal', 'aal1') = 'aal2';
$$;
revoke all     on function public.organizer_ids() from public, anon;
grant  execute on function public.organizer_ids() to authenticated;

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
create trigger organizer_members_guard
  before insert or update or delete on organizer_members
  for each row execute function public.backend_only_guard();
create trigger organizer_invitations_guard
  before insert or update or delete on organizer_invitations
  for each row execute function public.backend_only_guard();
create trigger job_offer_relay_log_guard
  before insert or update or delete on job_offer_relay_log
  for each row execute function public.backend_only_guard();
create trigger training_participant_contacts_guard
  before insert or update or delete on training_participant_contacts
  for each row execute function public.backend_only_guard();
create trigger app_feature_flags_guard
  before insert or update or delete on app_feature_flags
  for each row execute function public.backend_only_guard();
create trigger candidate_ads_guard
  before insert or update or delete on candidate_ads
  for each row execute function public.backend_only_guard();
create trigger candidate_ad_contact_log_guard
  before insert or update or delete on candidate_ad_contact_log
  for each row execute function public.backend_only_guard();

-- Rozdział personelu i klientów działa w obie strony: konto z aktywnym członkostwem w salonie albo
-- u organizatora nie może dostać wpisu w admin_users (odwrotny kierunek sprawdzają app_accept_*).
create or replace function public.staff_client_disjoint_guard() returns trigger
language plpgsql set search_path = '' as $$
begin
  if exists (select 1 from public.client_members m where m.user_id = new.user_id and m.status = 'active')
     or exists (select 1 from public.organizer_members om where om.user_id = new.user_id and om.status = 'active') then
    raise exception 'admin_users: konto klienta lub organizatora nie może być kontem personelu';
  end if;
  return new;
end $$;
revoke all on function public.staff_client_disjoint_guard() from public, anon, authenticated;
create trigger admin_users_disjoint_guard
  before insert or update on admin_users
  for each row execute function public.staff_client_disjoint_guard();

-- Guard ogłoszeń dla właściciela salonu: slug nadawany w bazie, dozwolone przejścia statusów, migawka
-- nazwy salonu, brak zmian treści w trakcie moderacji, edycja opublikowanego ogłoszenia wraca do
-- moderacji, wersja treści dla moderatora, limit ogłoszeń w szkicu/moderacji. Kolumny moderacji
-- (published_at, expires_at, moderated_by, moderation_note, rejection_reason) i slug nie mają grantu
-- dla authenticated – ustawia je wyłącznie app_moderate_job_offer() (service_role) albo ten guard.
create or replace function public.job_offers_owner_guard() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_changed boolean;
  v_city    text;
begin
  if current_user in ('service_role', 'postgres', 'supabase_admin') then
    return new;
  end if;

  if tg_op = 'INSERT' then
    if new.status not in ('draft', 'pending_review') then
      raise exception 'job_offers: nowe ogłoszenie może być tylko szkicem albo trafić do moderacji';
    end if;
    if (select count(*) from public.job_offers o
         where o.account_id = new.account_id and o.status in ('draft', 'pending_review')) >= 5 then
      raise exception 'job_offers: limit 5 ogłoszeń w szkicu lub w moderacji na salon';   -- [Założenie]
    end if;
    select a.display_name into new.employer_name
      from public.client_accounts a where a.id = new.account_id;
    -- slug: zawód + miasto + losowy sufiks; nazwy zastrzeżone (marka, partnerzy) nie trafiają do adresu
    v_city := trim(both '-' from regexp_replace(translate(lower(new.city), 'ąćęłńóśźż', 'acelnoszz'),
                                               '[^a-z0-9]+', '-', 'g'));
    if v_city = '' or v_city ~ '(^|-)(aura|beautypolisa|beauty|polisa|ergo|hestia|colonnade|lux|luxmed|enel|enelmed|med)(-|$)' then
      v_city := null;
    end if;
    new.slug := concat_ws('-', new.profession, trim(both '-' from left(v_city, 60)),
                          substr(md5(gen_random_uuid()::text), 1, 8));
    new.content_version := 1;
    new.published_at := null;
    new.expires_at   := null;
    new.created_by   := (select auth.uid());
    new.submitted_at := case when new.status = 'pending_review' then now() end;
    return new;
  end if;

  -- UPDATE
  if new.account_id is distinct from old.account_id then
    raise exception 'job_offers: nie można przenieść ogłoszenia do innego salonu';
  end if;
  if old.status in ('expired', 'removed', 'closed') then
    raise exception 'job_offers: ogłoszenie jest zamknięte, wygasło lub zostało usunięte – utwórz nowe';
  end if;
  v_changed := (new.title, new.profession, new.employment_type, new.working_time, new.city, new.voivodeship,
                new.postal_code, new.salary_min, new.salary_max, new.salary_unit, new.salary_basis,
                new.description, new.requirements, new.benefits)
               is distinct from
               (old.title, old.profession, old.employment_type, old.working_time, old.city, old.voivodeship,
                old.postal_code, old.salary_min, old.salary_max, old.salary_unit, old.salary_basis,
                old.description, old.requirements, old.benefits);
  if v_changed and old.status = 'pending_review' then
    raise exception 'job_offers: ogłoszenie jest w moderacji – wycofaj je do szkicu, aby zmienić treść';
  end if;
  if v_changed and old.status = 'published' then
    new.status := 'pending_review';            -- zmiana treści = ponowna moderacja
  end if;
  if new.status is distinct from old.status and not (
       (old.status in ('draft', 'rejected') and new.status in ('draft', 'pending_review'))
    or (old.status = 'pending_review'       and new.status = 'draft')
    or (old.status = 'published'            and new.status in ('pending_review', 'closed'))
  ) then
    raise exception 'job_offers: niedozwolona zmiana statusu % → %', old.status, new.status;
  end if;
  if old.status = 'rejected' and new.status in ('draft', 'pending_review')
     and (select count(*) from public.job_offers o
           where o.account_id = new.account_id and o.id <> new.id
             and o.status in ('draft', 'pending_review')) >= 5 then
    raise exception 'job_offers: limit 5 ogłoszeń w szkicu lub w moderacji na salon';
  end if;
  if v_changed or (new.status = 'pending_review' and old.status <> 'pending_review') then
    new.content_version := old.content_version + 1;   -- moderator zatwierdza konkretną wersję (p_expected_version)
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

-- Blok kontaktu podlega tej samej regule co treść: brak zmian w trakcie moderacji, zmiana przy
-- opublikowanym ogłoszeniu wysyła je ponownie do moderacji (guard ogłoszeń podnosi content_version).
create or replace function public.job_offer_contacts_guard() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_status  text;
  v_account uuid;
begin
  if current_user in ('service_role', 'postgres', 'supabase_admin') then
    return coalesce(new, old);
  end if;
  if tg_op = 'DELETE' then
    raise exception 'job_offer_contacts: kontakt usuwa się razem z ogłoszeniem';
  end if;
  if tg_op = 'UPDATE' and new.offer_id is distinct from old.offer_id then
    raise exception 'job_offer_contacts: nie można przenieść kontaktu';
  end if;
  select o.status, o.account_id into v_status, v_account from public.job_offers o where o.id = new.offer_id;
  if not found then
    raise exception 'job_offer_contacts: brak ogłoszenia';
  end if;
  new.account_id := v_account;                 -- zawsze zgodne z ogłoszeniem; RLS with check sprawdza właściciela
  if v_status = 'pending_review' then
    raise exception 'job_offer_contacts: ogłoszenie jest w moderacji – wycofaj je do szkicu, aby zmienić kontakt';
  elsif v_status in ('closed', 'expired', 'removed') then
    raise exception 'job_offer_contacts: ogłoszenie jest zamknięte';
  elsif v_status = 'published' then
    update public.job_offers set status = 'pending_review' where id = new.offer_id;
  end if;
  new.updated_at := now();
  return new;
end $$;
revoke all on function public.job_offer_contacts_guard() from public, anon, authenticated;
create trigger job_offer_contacts_guard
  before insert or update or delete on job_offer_contacts
  for each row execute function public.job_offer_contacts_guard();

-- Guard szkoleń – dla organizatorów i personelu tak samo (personel też przechodzi przez moderację):
-- slug w bazie, organizer_id niezmienne, licznik miejsc i pojemność tylko funkcjami, brak zmian
-- w trakcie moderacji, zmiana opublikowanego szkolenia (treść, termin, miejsce) zdejmuje je z katalogu
-- do ponownej akceptacji, publikacja wyłącznie przez app_moderate_training().
create or replace function public.trainings_guard() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_changed boolean;
  v_base    text;
begin
  if current_user in ('service_role', 'postgres', 'supabase_admin') then
    return new;
  end if;

  if tg_op = 'INSERT' then
    if new.status not in ('draft', 'pending_review') then
      raise exception 'trainings: nowe szkolenie może być tylko szkicem albo trafić do moderacji';
    end if;
    if (select count(*) from public.trainings t
         where t.organizer_id = new.organizer_id and t.status in ('draft', 'pending_review')) >= 10 then
      raise exception 'trainings: limit 10 szkoleń w szkicu lub w moderacji na organizatora';  -- [Założenie]
    end if;
    v_base := trim(both '-' from regexp_replace(translate(lower(new.title), 'ąćęłńóśźż', 'acelnoszz'),
                                               '[^a-z0-9]+', '-', 'g'));
    if v_base = '' or v_base ~ '(^|-)(aura|beautypolisa|ergo|hestia|colonnade|luxmed|enelmed)(-|$)'
       or v_base ~ '(lux-med|enel-med|beauty-polisa)' then
      v_base := 'szkolenie';
    end if;
    new.slug := trim(both '-' from left(v_base, 80)) || '-' || substr(md5(gen_random_uuid()::text), 1, 8);
    new.content_version  := 1;
    new.seats_registered := 0;
    new.published_at     := null;
    new.created_by       := (select auth.uid());
    new.submitted_at     := case when new.status = 'pending_review' then now() end;
    return new;
  end if;

  -- UPDATE
  if new.organizer_id is distinct from old.organizer_id then
    raise exception 'trainings: nie można zmienić organizatora szkolenia';
  end if;
  if old.status in ('cancelled', 'completed', 'removed') then
    raise exception 'trainings: szkolenie jest zakończone, odwołane albo usunięte';
  end if;
  v_changed := (new.title, new.summary, new.description, new.format, new.city, new.venue_name, new.starts_at,
                new.ends_at, new.registration_closes_at, new.audience, new.per_account_limit, new.price_kind,
                new.price_gross_pln)
               is distinct from
               (old.title, old.summary, old.description, old.format, old.city, old.venue_name, old.starts_at,
                old.ends_at, old.registration_closes_at, old.audience, old.per_account_limit, old.price_kind,
                old.price_gross_pln);
  if v_changed and old.status = 'pending_review' then
    raise exception 'trainings: szkolenie jest w moderacji – wycofaj je do szkicu, aby zmienić treść';
  end if;
  if v_changed and old.status = 'published' then
    new.status := 'pending_review';
  end if;
  if new.status is distinct from old.status and not (
       (old.status in ('draft', 'rejected') and new.status in ('draft', 'pending_review'))
    or (old.status = 'pending_review'       and new.status = 'draft')
    or (old.status = 'published'            and new.status = 'pending_review')
  ) then
    raise exception 'trainings: niedozwolona zmiana statusu % → %', old.status, new.status;
  end if;
  if v_changed or (new.status = 'pending_review' and old.status <> 'pending_review') then
    new.content_version := old.content_version + 1;
  end if;
  if new.status = 'pending_review' and old.status <> 'pending_review' then
    new.submitted_at := now();
  end if;
  new.updated_at := now();
  return new;
end $$;
revoke all on function public.trainings_guard() from public, anon, authenticated;
create trigger trainings_guard
  before insert or update on trainings
  for each row execute function public.trainings_guard();

-- Szczegóły dla zapisanych (link do spotkania, adres): te same zasady co treść szkolenia
create or replace function public.training_private_details_guard() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_status text;
begin
  if current_user in ('service_role', 'postgres', 'supabase_admin') then
    return coalesce(new, old);
  end if;
  if tg_op = 'DELETE' then
    raise exception 'training_private_details: usuń treść pól zamiast wiersza';
  end if;
  if tg_op = 'UPDATE' and new.training_id is distinct from old.training_id then
    raise exception 'training_private_details: nie można przenieść szczegółów';
  end if;
  select t.status into v_status from public.trainings t where t.id = new.training_id;
  if not found then
    raise exception 'training_private_details: brak szkolenia';
  end if;
  if v_status = 'pending_review' then
    raise exception 'training_private_details: szkolenie jest w moderacji';
  elsif v_status in ('cancelled', 'completed', 'removed') then
    raise exception 'training_private_details: szkolenie zakończone';
  elsif v_status = 'published' then
    update public.trainings set status = 'pending_review' where id = new.training_id;
  end if;
  return new;
end $$;
revoke all on function public.training_private_details_guard() from public, anon, authenticated;
create trigger training_private_details_guard
  before insert or update or delete on training_private_details
  for each row execute function public.training_private_details_guard();

-- Audyt zmian wykonywanych przez personel przez RLS (panel) na kontach, polisach i profilach organizatorów.
-- SECURITY DEFINER, bo authenticated nie ma INSERT na client_audit_log; funkcji wyzwalacza nie da się
-- wywołać przez RPC, a EXECUTE i tak jest odebrane. Zmiany bez sesji (import M2, przekaz M5) podpisują
-- się kontekstem z ustawienia sesji: set local app.audit_actor = 'system:import:<partia>' / 'system:crm-sync'.
create or replace function public.client_audit_staff_change() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_action text;
  v_actor  text := coalesce('staff:' || (select auth.uid())::text,
                            nullif(current_setting('app.audit_actor', true), ''), 'system');
begin
  if tg_table_name = 'client_policies' then
    v_action := case
      when tg_op = 'INSERT' then 'policy_created'
      when new.published_at is not null and old.published_at is null then 'policy_published'
      else 'policy_updated' end;
    insert into public.client_audit_log (account_id, actor, action, entity, entity_id, payload)
    values (new.account_id, v_actor, v_action, 'policy', new.id, jsonb_build_object('status', new.status));
  elsif tg_table_name = 'client_accounts' then
    v_action := case
      when tg_op = 'INSERT' then 'account_created'
      when new.status = 'suspended' and old.status <> 'suspended' then 'account_suspended'
      when new.status = 'closed' and old.status <> 'closed' then 'account_closed'
      else null end;
    if v_action is not null then
      insert into public.client_audit_log (account_id, actor, action, entity, entity_id, payload)
      values (new.id, v_actor, v_action, 'account', new.id, jsonb_build_object('status', new.status));
    end if;
  elsif tg_table_name = 'training_organizers' then
    v_action := case
      when tg_op = 'INSERT' then 'organizer_created'
      when new.verified_at is not null and old.verified_at is null then 'organizer_verified'
      when new.status = 'suspended' and old.status <> 'suspended' then 'organizer_suspended'
      else 'organizer_updated' end;
    insert into public.client_audit_log (organizer_id, actor, action, entity, entity_id, payload)
    values (new.id, v_actor, v_action, 'organizer', new.id, jsonb_build_object('status', new.status));
  end if;
  return new;
end $$;
revoke all on function public.client_audit_staff_change() from public, anon, authenticated;
create trigger client_policies_audit after insert or update on client_policies
  for each row execute function public.client_audit_staff_change();
create trigger client_accounts_audit after insert or update on client_accounts
  for each row execute function public.client_audit_staff_change();
create trigger training_organizers_audit after insert or update on training_organizers
  for each row execute function public.client_audit_staff_change();

-- Dziennik audytu: append-only. UPDATE zawsze zabroniony, DELETE tylko wpisów starszych niż 24 miesiące
-- [Założenie: retencja] i tylko przez app_purge_audit_log() (właściciel: postgres); TRUNCATE zabroniony
-- wyzwalaczem instrukcji (wyzwalacze wierszy nie obejmują TRUNCATE). service_role ma tylko SELECT i INSERT.
create or replace function public.client_audit_log_guard() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op = 'TRUNCATE' then
    raise exception 'client_audit_log: TRUNCATE zabroniony';
  end if;
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
create trigger client_audit_log_no_truncate before truncate on client_audit_log
  for each statement execute function public.client_audit_log_guard();


-- -----------------------------------------------------------------------------------------------------
-- 8. RLS I GRANTY
-- -----------------------------------------------------------------------------------------------------

alter table client_accounts               enable row level security;
alter table client_members                enable row level security;
alter table client_invitations            enable row level security;
alter table client_policies               enable row level security;
alter table client_policy_notes           enable row level security;
alter table client_policy_documents       enable row level security;
alter table client_policy_reminders       enable row level security;  -- bez polityk: service_role_only
alter table job_offers                    enable row level security;
alter table job_offer_contacts            enable row level security;
alter table job_offer_relay_log           enable row level security;  -- bez polityk: service_role_only
alter table app_feature_flags             enable row level security;
alter table candidate_ads                 enable row level security;
alter table candidate_ad_contact_log      enable row level security;  -- bez polityk: service_role_only
alter table training_organizers           enable row level security;
alter table organizer_members             enable row level security;
alter table organizer_invitations         enable row level security;
alter table trainings                     enable row level security;
alter table training_private_details      enable row level security;
alter table training_registrations        enable row level security;
alter table training_participant_contacts enable row level security;
alter table abuse_reports                 enable row level security;
alter table client_audit_log              enable row level security;

alter table client_members                force row level security;
alter table client_invitations            force row level security;
alter table client_policies               force row level security;
alter table client_policy_documents       force row level security;
alter table job_offer_contacts            force row level security;
alter table candidate_ads                 force row level security;
alter table candidate_ad_contact_log      force row level security;
alter table organizer_members             force row level security;
alter table organizer_invitations         force row level security;
alter table training_registrations        force row level security;
alter table training_participant_contacts force row level security;

revoke all on client_accounts, client_members, client_invitations, client_policies, client_policy_notes,
              client_policy_documents, client_policy_reminders, job_offers, job_offer_contacts,
              job_offer_relay_log, training_organizers, organizer_members, organizer_invitations, trainings,
              training_private_details, training_registrations, training_participant_contacts, abuse_reports,
              client_audit_log, app_feature_flags, candidate_ads, candidate_ad_contact_log
  from public, anon, authenticated;

-- Uwaga: uprawnienia kolumnowe dotyczą CAŁEJ roli authenticated (salony, organizatorzy, personel).
-- Kolumny wewnętrzne (crm_ref, source_lead_id, *_by, moderation_note, account_id organizatora) personel
-- czyta w /panel serwerowo (service_role po sprawdzeniu app_is_staff w sesji aal2), nie przez grant.

-- 8.1 Konta salonów -------------------------------------------------------------------------------
grant select (id, display_name, legal_name, nip, city, status, team_confirmed_at, activated_at, suspended_at,
              closed_at, created_at, updated_at)
  on client_accounts to authenticated;
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

-- 8.2 Członkostwa i zaproszenia salonów (zapis tylko service_role; guard trigger) ------------------
grant select (account_id, user_id, role, status, display_name, terms_version, terms_accepted_at, last_seen_at,
              revoked_at, created_at)
  on client_members to authenticated;
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

-- 8.3 Polisy i dokumenty: właściciel czyta opublikowane (także archiwalne – D-B); pracownik nie widzi
--     polis; zapis – personel ------------------------------------------------------------------------
grant select (id, account_id, product, insurer, product_label, policy_number, status, valid_from, valid_to,
              premium_amount, premium_period, oc_risk_groups, oc_tariff_group, oc_sum_insured,
              oc_legal_protection, oc_team_size_band, oc_individual_quote, pricing_version_id, published_at,
              created_at, updated_at)
  on client_policies to authenticated;          -- bez crm_ref i created_by
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

grant select (id, policy_id, account_id, kind, title, storage_path, mime_type, size_bytes, sha256,
              published_at, created_at)
  on client_policy_documents to authenticated;  -- zapis: serwer (service_role) po walidacji pliku
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

-- 8.4 „Dam pracę” – ogłoszenia -------------------------------------------------------------------------
-- Publicznie (anon) tylko kolumny ogłoszenia, bez account_id/created_by/notatek moderacji i bez kontaktu.
-- (W „BEAUTY” anon czyta z job_listings także phone, email i owner_id ogłoszeniodawcy – tu celowo nie.)
grant select (id, slug, status, title, profession, employment_type, working_time, city, voivodeship,
              postal_code, salary_min, salary_max, salary_unit, salary_basis, description, requirements,
              benefits, employer_name, published_at, expires_at)
  on job_offers to anon;
create policy job_offers_public_read on job_offers
  for select to anon
  using (status = 'published' and expires_at > now());

grant select (id, account_id, slug, status, content_version, title, profession, employment_type, working_time,
              city, voivodeship, postal_code, salary_min, salary_max, salary_unit, salary_basis, description,
              requirements, benefits, employer_name, submitted_at, published_at, expires_at,
              rejection_reason, closed_at, created_at, updated_at)
  on job_offers to authenticated;               -- bez moderation_note, moderated_by i created_by
grant insert (account_id, status, title, profession, employment_type, working_time, city, voivodeship,
              postal_code, salary_min, salary_max, salary_unit, salary_basis, description, requirements, benefits),
      update (status, title, profession, employment_type, working_time, city, voivodeship, postal_code,
              salary_min, salary_max, salary_unit, salary_basis, description, requirements, benefits)
  on job_offers to authenticated;               -- slug i content_version ustawia guard

create policy job_offers_public_read_auth on job_offers   -- zalogowani widzą tablicę jak wszyscy
  for select to authenticated
  using (status = 'published' and expires_at > now());
create policy job_offers_member_read on job_offers        -- właściciel i pracownicy: ogłoszenia swojego salonu
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
-- brak DELETE: ogłoszenia się zamyka (closed) albo usuwa moderacyjnie (removed)

-- Kontakt: tylko właściciel salonu i personel (moderacja sprawdza, czy kontakt należy do salonu).
-- anon – brak grantu; strona ogłoszenia dostaje kontakt z serwera po „Pokaż kontakt”.
grant select (offer_id, account_id, method, email, phone, created_at, updated_at),
      insert (offer_id, method, email, phone),
      update (method, email, phone)
  on job_offer_contacts to authenticated;
create policy job_offer_contacts_owner_read on job_offer_contacts
  for select to authenticated using (account_id in (select public.client_account_ids('owner')));
create policy job_offer_contacts_owner_insert on job_offer_contacts
  for insert to authenticated with check (account_id in (select public.client_account_ids('owner')));
create policy job_offer_contacts_owner_update on job_offer_contacts
  for update to authenticated
  using (account_id in (select public.client_account_ids('owner')))
  with check (account_id in (select public.client_account_ids('owner')));
create policy job_offer_contacts_staff_read on job_offer_contacts
  for select to authenticated using (app_is_staff());

-- 8.4a „Szukam pracy” (D-E) – NIEAKTYWNE ------------------------------------------------------------------
-- Przełącznik: authenticated czyta tylko (key, enabled) – potrzebne w politykach niżej (podzapytanie
-- bez korelacji = initPlan, liczony raz na zapytanie). Brak funkcji pomocniczej dla authenticated
-- (lista funkcji wykonywalnych przez authenticated w teście CI 9.6 pkt 1 się nie zmienia). anon – nic.
grant select (key, enabled) on app_feature_flags to authenticated;
create policy app_feature_flags_read on app_feature_flags
  for select to authenticated using (true);

-- Ogłoszenia „Szukam pracy”: anon – BRAK grantu (nigdy publiczne, także przy włączonym przełączniku).
-- authenticated – tylko kolumny ogłoszenia; bez email, tokenów, moderated_by, moderation_note.
-- Odczyt: członek aktywnego konta salonu (client_account_ids(): właściciel w aal2, pracownik), tylko
-- opublikowane i nieprzeterminowane, tylko przy włączonym przełączniku. Organizator szkoleń bez konta
-- salonu nie widzi nic (organizer_ids() nie daje dostępu). Kolejność wyników ustala zapytanie
-- serwera (data publikacji) – bez rankingu i dopasowywania (D-C, D-E).
grant select (id, status, content_version, first_name, profession, city, voivodeship, cooperation_forms,
              experience, available_from, description, submitted_at, published_at, expires_at)
  on candidate_ads to authenticated;
create policy candidate_ads_salon_read on candidate_ads
  for select to authenticated
  using (status = 'published' and expires_at > now()
         and exists (select 1 from public.app_feature_flags f where f.key = 'szukam_pracy' and f.enabled)
         and exists (select 1 from public.client_account_ids()));
create policy candidate_ads_staff_read on candidate_ads     -- kolejka moderacji, tylko przy włączonym przełączniku
  for select to authenticated
  using (exists (select 1 from public.app_feature_flags f where f.key = 'szukam_pracy' and f.enabled)
         and app_is_staff());
-- brak INSERT/UPDATE/DELETE dla authenticated: zapis wyłącznie funkcjami app_candidate_* (service_role)
-- candidate_ad_contact_log: bez grantów i polityk (service_role_only)

-- 8.5 Organizatorzy szkoleń ---------------------------------------------------------------------------
-- Profil publiczny (znaczek „zweryfikowany”: nazwa, dane firmy z weryfikacji, miasto, strona, opis).
grant select (id, kind, display_name, legal_name, nip, city, website, description, verified_at)
  on training_organizers to anon;
grant select (id, kind, display_name, legal_name, nip, city, website, description, status, verified_at,
              created_at, updated_at)
  on training_organizers to authenticated;      -- bez account_id, verified_by, terms_version
grant insert (kind, account_id, display_name, legal_name, nip, city, website, description, status,
              verified_at, verified_by, terms_version),
      update (display_name, legal_name, nip, city, website, description, status, verified_at, verified_by,
              terms_version, updated_at)
  on training_organizers to authenticated;      -- zapis wyłącznie personel (polityki niżej)
create policy training_organizers_public_read on training_organizers
  for select to anon using (status = 'active' and verified_at is not null);
create policy training_organizers_public_read_auth on training_organizers
  for select to authenticated using (status = 'active' and verified_at is not null);
create policy training_organizers_member_read on training_organizers
  for select to authenticated using (id in (select public.organizer_ids()));
create policy training_organizers_staff_read on training_organizers
  for select to authenticated using (app_is_staff());
create policy training_organizers_staff_insert on training_organizers
  for insert to authenticated with check (app_is_staff('admin','agent'));
create policy training_organizers_staff_update on training_organizers
  for update to authenticated
  using (app_is_staff('admin','agent')) with check (app_is_staff('admin','agent'));

grant select (organizer_id, user_id, role, status, display_name, revoked_at, created_at)
  on organizer_members to authenticated;
create policy organizer_members_self_read on organizer_members
  for select to authenticated using (user_id = (select auth.uid()));
create policy organizer_members_org_read on organizer_members
  for select to authenticated using (organizer_id in (select public.organizer_ids()));
create policy organizer_members_staff_read on organizer_members
  for select to authenticated using (app_is_staff());

grant select (id, organizer_id, email, role, expires_at, invited_by_kind, accepted_at, revoked_at, created_at)
  on organizer_invitations to authenticated;    -- bez token_hash
create policy organizer_invitations_org_read on organizer_invitations
  for select to authenticated using (organizer_id in (select public.organizer_ids()));
create policy organizer_invitations_staff_read on organizer_invitations
  for select to authenticated using (app_is_staff());

-- 8.6 Szkolenia -----------------------------------------------------------------------------------------
grant select (id, organizer_id, slug, status, title, summary, description, format, city, venue_name, starts_at,
              ends_at, registration_closes_at, capacity, seats_registered, audience, price_kind, price_gross_pln,
              published_at, cancelled_at)
  on trainings to anon, authenticated;
grant select (per_account_limit, content_version, submitted_at, rejection_reason, created_at, updated_at)
  on trainings to authenticated;                -- bez moderation_note, moderated_by, created_by
-- status w grancie, ale guard dopuszcza tylko draft ↔ pending_review (i published → pending_review);
-- published_at, capacity (po utworzeniu), seats_registered, slug i kolumny moderacji – bez grantu
grant insert (organizer_id, status, title, summary, description, format, city, venue_name, starts_at, ends_at,
              registration_closes_at, capacity, per_account_limit, audience, price_kind, price_gross_pln),
      update (status, title, summary, description, format, city, venue_name, starts_at, ends_at,
              registration_closes_at, per_account_limit, audience, price_kind, price_gross_pln)
  on trainings to authenticated;

create policy trainings_public_read on trainings
  for select to anon using (status in ('published','cancelled') and published_at is not null);
create policy trainings_public_read_auth on trainings
  for select to authenticated using (status in ('published','cancelled') and published_at is not null);
create policy trainings_organizer_read on trainings
  for select to authenticated using (organizer_id in (select public.organizer_ids()));
create policy trainings_organizer_insert on trainings
  for insert to authenticated with check (organizer_id in (select public.organizer_ids()));
create policy trainings_organizer_update on trainings
  for update to authenticated
  using (organizer_id in (select public.organizer_ids()))
  with check (organizer_id in (select public.organizer_ids()));
create policy trainings_staff_read on trainings
  for select to authenticated using (app_is_staff());
create policy trainings_staff_insert on trainings
  for insert to authenticated with check (app_is_staff('admin','agent'));
create policy trainings_staff_update on trainings
  for update to authenticated
  using (app_is_staff('admin','agent')) with check (app_is_staff('admin','agent'));

grant select (training_id, online_join_url, venue_address, instructions),
      insert (training_id, online_join_url, venue_address, instructions),
      update (online_join_url, venue_address, instructions)
  on training_private_details to authenticated;
-- zapisany uczestnik: tylko przy aktywnym członkostwie w aktywnym salonie (client_account_ids)
create policy training_private_registered_read on training_private_details
  for select to authenticated
  using (exists (select 1 from training_registrations r
                 where r.training_id = training_private_details.training_id
                   and r.user_id = (select auth.uid())
                   and r.status = 'registered'
                   and r.account_id in (select public.client_account_ids())));
create policy training_private_organizer_read on training_private_details
  for select to authenticated
  using (training_id in (select t.id from trainings t where t.organizer_id in (select public.organizer_ids())));
create policy training_private_organizer_insert on training_private_details
  for insert to authenticated
  with check (training_id in (select t.id from trainings t where t.organizer_id in (select public.organizer_ids())));
create policy training_private_organizer_update on training_private_details
  for update to authenticated
  using (training_id in (select t.id from trainings t where t.organizer_id in (select public.organizer_ids())))
  with check (training_id in (select t.id from trainings t where t.organizer_id in (select public.organizer_ids())));
create policy training_private_staff_read on training_private_details
  for select to authenticated using (app_is_staff());
create policy training_private_staff_write on training_private_details
  for insert to authenticated with check (app_is_staff('admin','agent'));
create policy training_private_staff_update on training_private_details
  for update to authenticated
  using (app_is_staff('admin','agent')) with check (app_is_staff('admin','agent'));

-- Zapisy: uczestnik i właściciel jego salonu; personel. Organizator NIE ma polityki na tej tabeli
-- (user_id i account_id łączyłyby uczestników z salonami) – widzi tylko training_participant_contacts.
-- Zapis, rezygnacja i obecność wyłącznie funkcjami app_training_* (service_role).
grant select (id, training_id, account_id, user_id, status, cancelled_at, created_at, updated_at)
  on training_registrations to authenticated;
create policy training_registrations_self_read on training_registrations
  for select to authenticated using (user_id = (select auth.uid()));
create policy training_registrations_owner_read on training_registrations
  for select to authenticated using (account_id in (select public.client_account_ids('owner')));
create policy training_registrations_staff_read on training_registrations
  for select to authenticated using (app_is_staff());

grant select (registration_id, training_id, status, participant_name, participant_email, salon_name, created_at)
  on training_participant_contacts to authenticated;
create policy training_participant_contacts_organizer_read on training_participant_contacts
  for select to authenticated
  using (organizer_id in (select public.organizer_ids()) and status in ('registered','attended','no_show'));
-- personel: brak polityki (minimalizacja); obsługa nadużyć kluczem serwisowym z wpisem w dzienniku

-- 8.7 Zgłoszenia nadużyć: zapis przez serwer; personel czyta i oznacza obsłużone -------------------------
grant select, update (handled_at, handled_by) on abuse_reports to authenticated;
create policy abuse_reports_staff_read on abuse_reports
  for select to authenticated using (app_is_staff());
create policy abuse_reports_staff_update on abuse_reports
  for update to authenticated
  using (app_is_staff('admin','agent')) with check (app_is_staff('admin','agent'));

-- 8.8 Dziennik audytu ----------------------------------------------------------------------------------
grant select on client_audit_log to authenticated;
create policy client_audit_owner_read on client_audit_log
  for select to authenticated using (account_id in (select public.client_account_ids('owner')));
create policy client_audit_staff_read on client_audit_log
  for select to authenticated using (app_is_staff());
-- service_role: tylko odczyt i dopisywanie; bez UPDATE/DELETE/TRUNCATE (retencja: app_purge_audit_log)
revoke update, delete, truncate on client_audit_log from service_role;
grant select, insert on client_audit_log to service_role;


-- -----------------------------------------------------------------------------------------------------
-- 9. STORAGE: prywatny kubełek na dokumenty polis
--    (istniejący w „BEAUTY” kubełek „dokumenty” jest PUBLICZNY – nie wolno w nim trzymać polis).
--    „Dam pracę” nie ma kubełka: platforma nie przyjmuje CV ani załączników (D-C).
--    Organizatorzy: w MVP bez plików; później tylko obrazy rastrowe przekodowane na serwerze (bez SVG),
--    PDF-y wyłącznie po skanowaniu antywirusowym – inaczej link do strony organizatora.
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


-- -----------------------------------------------------------------------------------------------------
-- 10. FUNKCJE ZAPISU (security invoker, wyłącznie service_role)
--     Serwer wywołuje je po zweryfikowaniu sesji (getUser/getClaims – nigdy getSession) i przekazuje
--     p_actor = auth user id z ZWERYFIKOWANEGO tokenu; funkcje same sprawdzają uprawnienia aktora.
--     Wymóg aal2 dla personelu, właścicieli i organizatorów sprawdza serwer przed wywołaniem (funkcja
--     wywoływana kluczem serwisowym nie widzi JWT użytkownika).
-- -----------------------------------------------------------------------------------------------------

-- 10.1 Aktywacja konta: wymaga co najmniej jednej opublikowanej, aktywnej polisy dowolnego produktu (D-A)
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
     set status = 'active', activated_at = coalesce(activated_at, now()), activated_by = p_actor,
         team_confirmed_at = coalesce(team_confirmed_at, now()), updated_at = now()
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

-- 10.2 Zaproszenie pracownika przez właściciela (albo dowolnej roli przez personel)
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

-- 10.3 Rotacja tokenu (ponowna wysyłka zaproszenia – stary link przestaje działać). Te same uprawnienia
--      co przy tworzeniu: personel albo właściciel salonu (tylko zaproszenia pracowników).
create or replace function public.app_rotate_invitation_token(p_invitation uuid, p_actor uuid, p_new_token_hash text)
returns void
language plpgsql set search_path = '' as $$
declare
  v_inv  public.client_invitations%rowtype;
  v_kind text;
begin
  select * into v_inv from public.client_invitations
   where id = p_invitation and accepted_at is null and revoked_at is null
   for update;
  if not found then
    raise exception 'rotate: zaproszenie nieaktywne';
  end if;
  if exists (select 1 from public.admin_users u
             where u.user_id = p_actor and u.is_active and u.role in ('admin','agent')) then
    v_kind := 'staff:';
  elsif v_inv.role = 'employee' and exists (
          select 1 from public.client_members m
           where m.account_id = v_inv.account_id and m.user_id = p_actor
             and m.role = 'owner' and m.status = 'active') then
    v_kind := 'user:';
  else
    raise exception 'rotate: brak uprawnień';
  end if;
  update public.client_invitations
     set token_hash = p_new_token_hash, expires_at = now() + interval '7 days'
   where id = p_invitation;
  insert into public.client_audit_log (account_id, actor, action, entity, entity_id)
  values (v_inv.account_id, v_kind || p_actor::text, 'invitation_rotated', 'invitation', p_invitation);
end $$;

-- 10.4 Przyjęcie zaproszenia: adres konta Auth musi być identyczny z adresem zaproszenia.
--      p_user_email pochodzi z ZWERYFIKOWANEGO użytkownika (sesja po kodzie OTP z tej skrzynki, 4.2),
--      nie z formularza. Rola aktywnego członka nigdy nie jest obniżana.
create or replace function public.app_accept_invitation(p_token_hash text, p_user uuid, p_user_email text)
returns uuid
language plpgsql set search_path = '' as $$
declare
  v_inv     public.client_invitations%rowtype;
  v_current text;
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
  select m.role into v_current from public.client_members m
   where m.account_id = v_inv.account_id and m.user_id = p_user and m.status = 'active';
  if v_current = 'owner' and v_inv.role = 'employee' then
    raise exception 'accept: ta osoba jest już właścicielem salonu – zaproszenie obniżyłoby jej rolę';
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

-- 10.5 Akceptacja regulaminu przy pierwszym logowaniu
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

-- 10.6 Odebranie dostępu członkowi (właściciel → pracownik; personel → każdy, z wyjątkiem ostatniego właściciela)
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

-- 10.7 D-B: coroczne potwierdzenie zespołu przez właściciela i wygaszanie nieaktywnych pracowników
create or replace function public.app_confirm_team(p_account uuid, p_actor uuid)
returns void
language plpgsql set search_path = '' as $$
begin
  if not exists (select 1 from public.client_members m
                  where m.account_id = p_account and m.user_id = p_actor
                    and m.role = 'owner' and m.status = 'active') then
    raise exception 'team: brak uprawnień';
  end if;
  update public.client_accounts set team_confirmed_at = now(), updated_at = now() where id = p_account;
  insert into public.client_audit_log (account_id, actor, action, entity, entity_id)
  values (p_account, 'user:' || p_actor::text, 'team_confirmed', 'account', p_account);
end $$;

-- cron: pracownicy bez logowania od 12 miesięcy tracą dostęp [Założenie]; właściciel dostaje e-mail
-- (outbox dodaje serwer); właścicieli nie wygaszamy automatycznie – po 24 miesiącach bez logowania
-- serwer wymaga ponownej weryfikacji przez personel przed wydaniem sesji (pkt 6.1, K11)
create or replace function public.app_revoke_dormant_members()
returns integer
language plpgsql set search_path = '' as $$
declare
  v_count integer;
begin
  with done as (
    update public.client_members
       set status = 'revoked', revoked_at = now(), revoked_by = null
     where role = 'employee' and status = 'active'
       and coalesce(last_seen_at, created_at) < now() - interval '12 months'
    returning account_id, user_id
  ), log as (
    insert into public.client_audit_log (account_id, actor, action, entity, entity_id, payload)
    select account_id, 'system:dormant', 'member_revoked', 'member', user_id, '{"reason":"brak logowania 12 mies."}'::jsonb
      from done
    returning 1
  )
  select count(*) into v_count from log;
  return v_count;
end $$;

-- 10.8 Moderacja ogłoszenia (personel; serwer sprawdza też app_is_staff w sesji aal2).
--      p_expected_version = content_version z ekranu moderatora – inna wersja = ogłoszenie zmieniono
--      w trakcie przeglądu (wyjątek, moderator odświeża podgląd). Konto bez aktywnej polisy (D-B):
--      publikacja wymaga potwierdzenia, że NIP salonu jest nadal aktywny (CEIDG/KRS) – p_nip_confirmed.
create or replace function public.app_moderate_job_offer(
  p_offer uuid, p_actor uuid, p_decision text, p_expected_version integer,
  p_note text default null, p_reason text default null, p_nip_confirmed boolean default false)
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
    raise exception 'moderate: brak ogłoszenia';
  end if;
  if p_decision in ('publish', 'reject') and p_expected_version is distinct from v_offer.content_version then
    raise exception 'moderate: ogłoszenie zmieniono w trakcie moderacji (wersja %, oczekiwano %)',
      v_offer.content_version, p_expected_version;
  end if;

  if p_decision = 'publish' and v_offer.status = 'pending_review' then
    if not exists (select 1 from public.job_offer_contacts c where c.offer_id = p_offer) then
      raise exception 'moderate: ogłoszenie bez sposobu kontaktu';
    end if;
    if not p_nip_confirmed and not exists (
         select 1 from public.client_policies p
          where p.account_id = v_offer.account_id and p.status = 'active' and p.published_at is not null) then
      raise exception 'moderate: konto bez aktywnej polisy – potwierdź aktywność NIP salonu';
    end if;
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
          'job_offer', p_offer, jsonb_build_object('from', v_offer.status, 'version', v_offer.content_version));
end $$;

-- 10.9 Formularz kontaktowy ogłoszenia: przekazanie wiadomości kandydata e-mailem do salonu.
--      Serwer przed wywołaniem: Turnstile, honeypot, limit Workers (np. 5 / IP / dobę – klucz to skrót IP
--      wyłącznie w pamięci limitera, nie w bazie), Zod (treść ≤ 1000 znaków, tekst zwykły, adresy URL
--      odrzucone), brak załączników. W bazie wiadomość istnieje tylko w outbox_emails.payload do wysyłki;
--      po odpowiedzi 2xx z Resend serwer wywołuje app_purge_relay_messages(outbox_id).
--      Do kandydata nie wysyłamy żadnego e-maila (potwierdzenie tylko na ekranie).
create or replace function public.app_relay_job_message(p_offer_slug text, p_payload jsonb)
returns uuid
language plpgsql set search_path = '' as $$
declare
  v_offer   public.job_offers%rowtype;
  v_contact public.job_offer_contacts%rowtype;
  v_outbox  uuid;
  v_relay   uuid;
begin
  select * into v_offer from public.job_offers
   where slug = p_offer_slug and status = 'published' and expires_at > now();
  if not found then
    raise exception 'relay: ogłoszenie niedostępne';
  end if;
  select * into v_contact from public.job_offer_contacts where offer_id = v_offer.id and method = 'formularz';
  if not found then
    raise exception 'relay: salon nie przyjmuje wiadomości przez formularz';
  end if;
  if char_length(coalesce(p_payload->>'message', '')) not between 1 and 1000
     or char_length(coalesce(p_payload->>'sender_name', '')) not between 2 and 120
     or char_length(coalesce(p_payload->>'reply_to', '')) not between 6 and 254
     or char_length(coalesce(p_payload->>'phone', '')) > 20 then
    raise exception 'relay: nieprawidłowa wiadomość';
  end if;
  -- limit na ogłoszenie [Założenie: 50 wiadomości na dobę]
  if (select count(*) from public.job_offer_relay_log l
       where l.offer_id = v_offer.id and l.created_at > now() - interval '1 day') >= 50 then
    raise exception 'relay: dzienny limit wiadomości dla ogłoszenia';
  end if;

  v_relay := gen_random_uuid();
  insert into public.outbox_emails (template, recipient, payload, account_id)
  values ('job_relay', v_contact.email,
          jsonb_build_object('offer_title', v_offer.title, 'offer_slug', v_offer.slug, 'relay_id', v_relay,
                             'sender_name', p_payload->>'sender_name', 'reply_to', p_payload->>'reply_to',
                             'phone', nullif(p_payload->>'phone', ''), 'message', p_payload->>'message'),
          v_offer.account_id)
  returning id into v_outbox;
  insert into public.job_offer_relay_log (id, offer_id, outbox_id) values (v_relay, v_offer.id, v_outbox);
  return v_relay;
end $$;

-- Czyszczenie wiadomości: natychmiast po wysyłce (p_outbox) oraz cron – wiadomości niewysłane w 24 h
-- (oznaczane jako failed) i ślad przekazania starszy niż 30 dni. Obejmuje też e-maile „Szukam pracy”
-- (szablony candidate_*: wiadomość salonu do autora ogłoszenia i e-maile do autora – D-E, nieaktywne).
create or replace function public.app_purge_relay_messages(p_outbox uuid default null)
returns integer
language plpgsql set search_path = '' as $$
declare
  v_count integer;
begin
  update public.outbox_emails
     set payload = '{}'::jsonb, recipient = 'anonymized',
         status = case when status = 'pending' then 'failed' else status end
   where (template = 'job_relay' or template like 'candidate\_%') and recipient <> 'anonymized'
     and ((p_outbox is not null and id = p_outbox and status = 'sent')
          or (p_outbox is null and (status = 'sent' or created_at < now() - interval '24 hours')));
  get diagnostics v_count = row_count;
  if p_outbox is null then
    delete from public.job_offer_relay_log where created_at < now() - interval '30 days';
  end if;
  return v_count;
end $$;

-- 10.10 Wygaszanie ogłoszeń (cron, codziennie) i usuwanie kontaktów 30 dni po zakończeniu ogłoszenia
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
    select account_id, 'system:cron', 'job_offer_expired', 'job_offer', id from done
    returning 1
  )
  select count(*) into v_count from log;

  with gone as (
    delete from public.job_offer_contacts c
     using public.job_offers o
     where o.id = c.offer_id
       and o.status in ('closed','expired','removed')
       and coalesce(o.closed_at, o.expires_at, o.updated_at) < now() - interval '30 days'
    returning c.account_id, c.offer_id
  )
  insert into public.client_audit_log (account_id, actor, action, entity, entity_id)
  select account_id, 'system:cron', 'job_contacts_purged', 'job_offer', offer_id from gone;
  return v_count;
end $$;

-- 10.11 Organizatorzy: zaproszenie (personel albo właściciel organizatora – tylko rola member),
--       przyjęcie (osobne tokeny; personel Aura nie może być organizatorem), odebranie dostępu
create or replace function public.app_create_organizer_invitation(
  p_organizer uuid, p_actor uuid, p_email text, p_role text, p_token_hash text)
returns uuid
language plpgsql set search_path = '' as $$
declare
  v_kind text;
  v_id   uuid;
begin
  if exists (select 1 from public.admin_users u
             where u.user_id = p_actor and u.is_active and u.role in ('admin','agent')) then
    v_kind := 'staff';
  elsif exists (select 1 from public.organizer_members om
                join public.training_organizers o on o.id = om.organizer_id and o.status = 'active'
                where om.organizer_id = p_organizer and om.user_id = p_actor
                  and om.role = 'owner' and om.status = 'active') then
    v_kind := 'owner';
    if p_role <> 'member' then
      raise exception 'organizer invite: właściciel zaprasza tylko członków zespołu';
    end if;
  else
    raise exception 'organizer invite: brak uprawnień';
  end if;
  if not exists (select 1 from public.training_organizers o
                  where o.id = p_organizer and o.status = 'active' and o.verified_at is not null) then
    raise exception 'organizer invite: organizator niezweryfikowany albo zawieszony';
  end if;
  if (select count(*) from public.organizer_members om where om.organizer_id = p_organizer and om.status = 'active') >= 10 then
    raise exception 'organizer invite: osiągnięto limit zespołu organizatora';   -- [Założenie]
  end if;

  update public.organizer_invitations
     set revoked_at = now()
   where organizer_id = p_organizer and email_normalized = lower(trim(p_email))
     and accepted_at is null and revoked_at is null;
  insert into public.organizer_invitations
    (organizer_id, email, email_normalized, role, token_hash, expires_at, invited_by, invited_by_kind)
  values (p_organizer, p_email, lower(trim(p_email)), p_role, p_token_hash, now() + interval '7 days', p_actor, v_kind)
  returning id into v_id;

  insert into public.client_audit_log (organizer_id, actor, action, entity, entity_id, payload)
  values (p_organizer, (case v_kind when 'staff' then 'staff:' else 'user:' end) || p_actor::text,
          'organizer_invitation_created', 'invitation', v_id, jsonb_build_object('role', p_role));
  return v_id;
end $$;

create or replace function public.app_accept_organizer_invitation(p_token_hash text, p_user uuid, p_user_email text)
returns uuid
language plpgsql set search_path = '' as $$
declare
  v_inv     public.organizer_invitations%rowtype;
  v_current text;
begin
  select * into v_inv from public.organizer_invitations
   where token_hash = p_token_hash and accepted_at is null and revoked_at is null and expires_at > now()
   for update;
  if not found then
    raise exception 'organizer accept: zaproszenie wygasło albo zostało użyte';
  end if;
  if lower(trim(p_user_email)) is distinct from v_inv.email_normalized then
    raise exception 'organizer accept: zaproszenie dotyczy innego adresu e-mail';
  end if;
  if exists (select 1 from public.admin_users a where a.user_id = p_user) then
    raise exception 'organizer accept: konto personelu nie może należeć do organizatora';
  end if;
  select om.role into v_current from public.organizer_members om
   where om.organizer_id = v_inv.organizer_id and om.user_id = p_user and om.status = 'active';
  if v_current = 'owner' and v_inv.role = 'member' then
    raise exception 'organizer accept: zaproszenie obniżyłoby rolę właściciela';
  end if;

  insert into public.organizer_members (organizer_id, user_id, role, status, invited_by)
  values (v_inv.organizer_id, p_user, v_inv.role, 'active', v_inv.invited_by)
  on conflict (organizer_id, user_id) do update
    set role = excluded.role, status = 'active', revoked_at = null, revoked_by = null;
  update public.organizer_invitations set accepted_at = now(), accepted_user_id = p_user where id = v_inv.id;

  insert into public.client_audit_log (organizer_id, actor, action, entity, entity_id, payload)
  values (v_inv.organizer_id, 'user:' || p_user::text, 'organizer_invitation_accepted', 'invitation', v_inv.id,
          jsonb_build_object('role', v_inv.role));
  return v_inv.organizer_id;
end $$;

create or replace function public.app_revoke_organizer_member(p_organizer uuid, p_user uuid, p_actor uuid)
returns void
language plpgsql set search_path = '' as $$
declare
  v_is_staff boolean;
  v_target   public.organizer_members%rowtype;
begin
  v_is_staff := exists (select 1 from public.admin_users u
                        where u.user_id = p_actor and u.is_active and u.role in ('admin','agent'));
  select * into v_target from public.organizer_members
   where organizer_id = p_organizer and user_id = p_user and status = 'active' for update;
  if not found then
    raise exception 'organizer revoke: brak aktywnego członkostwa';
  end if;
  if not v_is_staff and not (
       v_target.role = 'member'
       and exists (select 1 from public.organizer_members om
                    where om.organizer_id = p_organizer and om.user_id = p_actor
                      and om.role = 'owner' and om.status = 'active')) then
    raise exception 'organizer revoke: brak uprawnień';
  end if;
  update public.organizer_members
     set status = 'revoked', revoked_at = now(), revoked_by = p_actor
   where organizer_id = p_organizer and user_id = p_user;
  insert into public.client_audit_log (organizer_id, actor, action, entity, entity_id)
  values (p_organizer, (case when v_is_staff then 'staff:' else 'user:' end) || p_actor::text,
          'organizer_member_revoked', 'organizer_member', p_user);
end $$;

-- 10.12 Moderacja szkolenia (personel). Publikacja tylko szkoleń aktywnego, zweryfikowanego organizatora;
--       wersja treści jak przy ogłoszeniach (szkolenie albo szczegóły zmienione w trakcie przeglądu → wyjątek).
create or replace function public.app_moderate_training(
  p_training uuid, p_actor uuid, p_decision text, p_expected_version integer,
  p_note text default null, p_reason text default null)
returns void
language plpgsql set search_path = '' as $$
declare
  v_t public.trainings%rowtype;
begin
  if not exists (select 1 from public.admin_users u
                 where u.user_id = p_actor and u.is_active and u.role in ('admin','agent')) then
    raise exception 'moderate training: brak uprawnień';
  end if;
  select * into v_t from public.trainings where id = p_training for update;
  if not found then
    raise exception 'moderate training: brak szkolenia';
  end if;
  if p_decision in ('publish', 'reject') and p_expected_version is distinct from v_t.content_version then
    raise exception 'moderate training: szkolenie zmieniono w trakcie moderacji (wersja %, oczekiwano %)',
      v_t.content_version, p_expected_version;
  end if;

  if p_decision = 'publish' and v_t.status = 'pending_review' then
    if not exists (select 1 from public.training_organizers o
                    where o.id = v_t.organizer_id and o.status = 'active' and o.verified_at is not null) then
      raise exception 'moderate training: organizator niezweryfikowany albo zawieszony';
    end if;
    if v_t.starts_at <= now() then
      raise exception 'moderate training: termin szkolenia minął';
    end if;
    update public.trainings
       set status = 'published', published_at = coalesce(published_at, now()), moderated_by = p_actor,
           moderation_note = p_note, rejection_reason = null, updated_at = now()
     where id = p_training;
  elsif p_decision = 'reject' and v_t.status = 'pending_review' then
    if p_reason is null then
      raise exception 'moderate training: odrzucenie wymaga powodu dla organizatora';
    end if;
    update public.trainings
       set status = 'rejected', moderated_by = p_actor, moderation_note = p_note, rejection_reason = p_reason,
           updated_at = now()
     where id = p_training;
  elsif p_decision = 'remove' and v_t.status in ('published','pending_review','rejected','draft') then
    update public.trainings
       set status = 'removed', moderated_by = p_actor, moderation_note = p_note, rejection_reason = p_reason,
           cancelled_at = now(), updated_at = now()
     where id = p_training;            -- zapisanym serwer wysyła training_cancelled
  else
    raise exception 'moderate training: niedozwolona decyzja % dla statusu %', p_decision, v_t.status;
  end if;

  insert into public.client_audit_log (organizer_id, actor, action, entity, entity_id, payload)
  values (v_t.organizer_id, 'staff:' || p_actor::text,
          case p_decision when 'publish' then 'training_published'
                          when 'reject'  then 'training_rejected'
                          else 'training_removed' end,
          'training', p_training, jsonb_build_object('from', v_t.status, 'version', v_t.content_version));
end $$;

-- Pomocnicza (EXECUTE tylko service_role, wołana wewnątrz funkcji app_*): czy aktor może zarządzać
-- szkoleniem – członek aktywnego organizatora szkolenia albo personel admin/agent. Zwraca 'staff:'/'user:'.
create or replace function public.training_actor_kind(p_training uuid, p_actor uuid)
returns text
language sql stable set search_path = '' as $$
  select case
    when exists (select 1 from public.admin_users u
                  where u.user_id = p_actor and u.is_active and u.role in ('admin','agent')) then 'staff:'
    when exists (select 1 from public.trainings t
                   join public.organizer_members om on om.organizer_id = t.organizer_id
                   join public.training_organizers o on o.id = t.organizer_id
                  where t.id = p_training and om.user_id = p_actor and om.status = 'active'
                    and o.status = 'active' and o.verified_at is not null) then 'user:'
  end;
$$;

-- 10.13 Pojemność: nigdy poniżej liczby zapisanych; zwiększenie awansuje osoby z listy rezerwowej
create or replace function public.app_training_set_capacity(p_training uuid, p_actor uuid, p_capacity integer)
returns integer
language plpgsql set search_path = '' as $$
declare
  v_t       public.trainings%rowtype;
  v_kind    text := public.training_actor_kind(p_training, p_actor);
  v_next    uuid;
  v_moved   integer := 0;
begin
  if v_kind is null then
    raise exception 'capacity: brak uprawnień';
  end if;
  select * into v_t from public.trainings where id = p_training for update;
  if v_t.status not in ('draft','pending_review','published','rejected') then
    raise exception 'capacity: szkolenie zakończone albo odwołane';
  end if;
  if p_capacity is not null and (p_capacity < 1 or p_capacity < v_t.seats_registered) then
    raise exception 'capacity: limit nie może być mniejszy niż liczba zapisanych (%)', v_t.seats_registered;
  end if;
  update public.trainings set capacity = p_capacity, updated_at = now() where id = p_training;

  loop
    exit when p_capacity is not null
          and (select seats_registered from public.trainings where id = p_training) >= p_capacity;
    select r.id into v_next from public.training_registrations r
     where r.training_id = p_training and r.status = 'waitlisted'
     order by r.created_at limit 1 for update;
    exit when v_next is null;
    update public.training_registrations set status = 'registered', updated_at = now() where id = v_next;
    update public.training_participant_contacts set status = 'registered', updated_at = now() where registration_id = v_next;
    update public.trainings set seats_registered = seats_registered + 1 where id = p_training;
    insert into public.client_audit_log (account_id, actor, action, entity, entity_id)
    select r.account_id, 'system:capacity', 'training_promoted', 'training_registration', r.id
      from public.training_registrations r where r.id = v_next;
    v_moved := v_moved + 1;
    v_next := null;
  end loop;

  insert into public.client_audit_log (organizer_id, actor, action, entity, entity_id, payload)
  values (v_t.organizer_id, v_kind || p_actor::text, 'training_capacity_changed', 'training', p_training,
          jsonb_build_object('from', v_t.capacity, 'to', p_capacity, 'promoted', v_moved));
  return v_moved;                       -- serwer wysyła training_promoted awansowanym
end $$;

-- 10.14 Odwołanie szkolenia przez organizatora albo personel (zapisani dostają training_cancelled)
create or replace function public.app_training_cancel_event(p_training uuid, p_actor uuid, p_reason text)
returns void
language plpgsql set search_path = '' as $$
declare
  v_t    public.trainings%rowtype;
  v_kind text := public.training_actor_kind(p_training, p_actor);
begin
  if v_kind is null then
    raise exception 'cancel event: brak uprawnień';
  end if;
  select * into v_t from public.trainings where id = p_training for update;
  if v_t.status not in ('published','pending_review') then
    raise exception 'cancel event: szkolenia w statusie % nie można odwołać', v_t.status;
  end if;
  update public.trainings set status = 'cancelled', cancelled_at = now(), updated_at = now() where id = p_training;
  insert into public.client_audit_log (organizer_id, actor, action, entity, entity_id, payload)
  values (v_t.organizer_id, v_kind || p_actor::text, 'training_event_cancelled', 'training', p_training,
          jsonb_build_object('reason', left(coalesce(p_reason, ''), 200)));
end $$;

-- 10.15 Zapis na szkolenie: blokada wiersza szkolenia, limit miejsc, limit na salon, lista rezerwowa,
--       migawka danych dla organizatora (imię i nazwisko, e-mail; nazwa salonu tylko przy szkoleniu płatnym).
--       p_participant_name/p_participant_email pochodzą z profilu zweryfikowanego użytkownika, nie z formularza;
--       p_notice_version – wersja informacji o przekazaniu danych organizatorowi pokazanej przed zapisem.
create or replace function public.app_training_register(
  p_training uuid, p_user uuid, p_account uuid,
  p_participant_name text, p_participant_email text, p_notice_version text)
returns text
language plpgsql set search_path = '' as $$
declare
  v_t      public.trainings%rowtype;
  v_role   text;
  v_status text;
  v_prev   text;
  v_reg    uuid;
begin
  if p_notice_version is null then
    raise exception 'register: brak informacji o przekazaniu danych organizatorowi';
  end if;
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
        cancelled_at = null, updated_at = now(), created_at = now()  -- nowa pozycja na liście rezerwowej
  returning id into v_reg;

  insert into public.training_participant_contacts
    (registration_id, training_id, organizer_id, status, participant_name, participant_email, salon_name, notice_version)
  values (v_reg, p_training, v_t.organizer_id, v_status, p_participant_name, lower(trim(p_participant_email)),
          case when v_t.price_kind = 'platne'
               then (select coalesce(a.legal_name, a.display_name) from public.client_accounts a where a.id = p_account) end,
          p_notice_version)
  on conflict (registration_id) do update
    set status = excluded.status, participant_name = excluded.participant_name,
        participant_email = excluded.participant_email, salon_name = excluded.salon_name,
        notice_version = excluded.notice_version, updated_at = now();

  if v_status = 'registered' then
    update public.trainings set seats_registered = seats_registered + 1 where id = p_training;
  end if;

  insert into public.client_audit_log (account_id, actor, action, entity, entity_id, payload)
  values (p_account, 'user:' || p_user::text,
          case v_status when 'registered' then 'training_registered' else 'training_waitlisted' end,
          'training', p_training, '{}'::jsonb);
  return v_status;
end $$;

-- 10.16 Rezygnacja (uczestnik, właściciel salonu, personel albo serwer przy odebraniu dostępu)
--       + awans z listy rezerwowej; dane uczestnika dla organizatora są usuwane od razu
create or replace function public.app_training_cancel(p_training uuid, p_user uuid, p_actor uuid)
returns void
language plpgsql set search_path = '' as $$
declare
  v_reg      public.training_registrations%rowtype;
  v_next     uuid;
  v_prefix   text;
begin
  perform 1 from public.trainings where id = p_training for update;
  select * into v_reg from public.training_registrations
   where training_id = p_training and user_id = p_user and status in ('registered','waitlisted')
   for update;
  if not found then
    return;
  end if;
  if p_actor = p_user
     or exists (select 1 from public.client_members m
                 where m.account_id = v_reg.account_id and m.user_id = p_actor
                   and m.role = 'owner' and m.status = 'active') then
    v_prefix := 'user:';
  elsif exists (select 1 from public.admin_users u
                 where u.user_id = p_actor and u.is_active and u.role in ('admin','agent')) then
    v_prefix := 'staff:';
  else
    raise exception 'cancel: brak uprawnień';
  end if;

  update public.training_registrations
     set status = 'cancelled', cancelled_at = now(), updated_at = now()
   where id = v_reg.id;
  delete from public.training_participant_contacts where registration_id = v_reg.id;

  if v_reg.status = 'registered' then
    select r.id into v_next from public.training_registrations r
     where r.training_id = p_training and r.status = 'waitlisted'
     order by r.created_at
     limit 1 for update skip locked;
    if v_next is not null then
      update public.training_registrations set status = 'registered', updated_at = now() where id = v_next;
      update public.training_participant_contacts set status = 'registered', updated_at = now()
       where registration_id = v_next;
      insert into public.client_audit_log (account_id, actor, action, entity, entity_id)
      select r.account_id, 'system:waitlist', 'training_promoted', 'training_registration', r.id
        from public.training_registrations r where r.id = v_next;
    else
      update public.trainings set seats_registered = greatest(seats_registered - 1, 0) where id = p_training;
    end if;
  end if;

  insert into public.client_audit_log (account_id, actor, action, entity, entity_id)
  values (v_reg.account_id, v_prefix || p_actor::text, 'training_cancelled', 'training_registration', v_reg.id);
end $$;

-- 10.17 Obecność: organizator szkolenia albo personel, dopiero od rozpoczęcia szkolenia
create or replace function public.app_training_mark_attendance(p_registration uuid, p_actor uuid, p_status text)
returns void
language plpgsql set search_path = '' as $$
declare
  v_reg  public.training_registrations%rowtype;
  v_kind text;
begin
  if p_status not in ('attended','no_show','registered') then
    raise exception 'attendance: niedozwolony status';
  end if;
  select * into v_reg from public.training_registrations where id = p_registration for update;
  if not found or v_reg.status not in ('registered','attended','no_show') then
    raise exception 'attendance: brak zapisu';
  end if;
  v_kind := public.training_actor_kind(v_reg.training_id, p_actor);
  if v_kind is null then
    raise exception 'attendance: brak uprawnień';
  end if;
  if (select t.starts_at from public.trainings t where t.id = v_reg.training_id) > now() then
    raise exception 'attendance: szkolenie jeszcze się nie rozpoczęło';
  end if;
  update public.training_registrations
     set status = p_status, marked_by = p_actor, updated_at = now() where id = p_registration;
  update public.training_participant_contacts set status = p_status, updated_at = now()
   where registration_id = p_registration;
  insert into public.client_audit_log (account_id, actor, action, entity, entity_id, payload)
  values (v_reg.account_id, v_kind || p_actor::text, 'training_attendance', 'training_registration', p_registration,
          jsonb_build_object('status', p_status));
end $$;

-- 10.18 Wgląd organizatora w listę uczestników i eksport – wpis w dzienniku (wywołuje serwer przy
--       wyświetleniu listy i przy pobraniu CSV); retencja danych uczestników 30 dni po szkoleniu
create or replace function public.app_log_organizer_access(p_training uuid, p_actor uuid, p_action text)
returns void
language plpgsql set search_path = '' as $$
declare
  v_org uuid;
begin
  if p_action not in ('organizer_participants_viewed','organizer_participants_exported') then
    raise exception 'organizer log: niedozwolona akcja';
  end if;
  if public.training_actor_kind(p_training, p_actor) is distinct from 'user:' then
    raise exception 'organizer log: brak uprawnień';
  end if;
  select t.organizer_id into v_org from public.trainings t where t.id = p_training;
  insert into public.client_audit_log (organizer_id, actor, action, entity, entity_id)
  values (v_org, 'user:' || p_actor::text, p_action, 'training', p_training);
end $$;

create or replace function public.app_purge_training_contacts()
returns integer
language plpgsql set search_path = '' as $$
declare
  v_count integer;
begin
  with gone as (
    delete from public.training_participant_contacts c
     using public.trainings t
     where t.id = c.training_id and t.ends_at < now() - interval '30 days'   -- [Założenie] 30 dni
    returning c.organizer_id, c.training_id
  ), per_training as (
    select organizer_id, training_id, count(*) as n from gone group by organizer_id, training_id
  ), log as (
    insert into public.client_audit_log (organizer_id, actor, action, entity, entity_id, payload)
    select organizer_id, 'system:cron', 'training_contacts_purged', 'training', training_id,
           jsonb_build_object('count', n) from per_training
    returning 1
  )
  select coalesce(sum(n), 0) into v_count from per_training;
  update public.trainings set status = 'completed', updated_at = now()
   where status = 'published' and ends_at < now();
  return v_count;
end $$;

-- 10.19 Retencja dziennika audytu – jedyna droga usuwania wpisów (SECURITY DEFINER, właściciel postgres)
create or replace function public.app_purge_audit_log()
returns integer
language plpgsql security definer set search_path = '' as $$
declare
  v_count integer;
begin
  delete from public.client_audit_log where created_at <= now() - interval '24 months';
  get diagnostics v_count = row_count;
  return v_count;
end $$;

-- 10.20 „Szukam pracy” (D-E) – NIEAKTYWNE. Każda funkcja zapisu zaczyna od app_require_feature():
--       przy wyłączonym przełączniku kończy się wyjątkiem SQLSTATE BP404 (serwer odpowiada 404, a trasy
--       i zakładka i tak nie istnieją dla użytkowników). Wyjątki od blokady: app_candidate_ad_delete()
--       (prawo do usunięcia danych) i app_purge_candidate_ads() (retencja) – tylko zmniejszają ilość danych.
--       Tokeny (potwierdzenie e-maila, link do zarządzania) generuje serwer; do bazy trafia skrót SHA-256,
--       a e-mail z linkiem wysyła serwer – token nigdy w outbox_emails.payload ani w logach (jak w 4.2).
create or replace function public.app_require_feature(p_key text)
returns void
language plpgsql stable set search_path = '' as $$
begin
  if not exists (select 1 from public.app_feature_flags f where f.key = p_key and f.enabled) then
    raise exception 'funkcja % jest wyłączona', p_key using errcode = 'BP404';
  end if;
end $$;

-- Włączenie/wyłączenie: tylko admin Aura, włączenie wymaga odwołania do decyzji zleceniodawcy
-- (po opinii prawnej – 11 §11.9). Wyłączenie nie usuwa wierszy: RLS natychmiast je ukrywa, a retencja
-- usuwa dane w zwykłym trybie.
create or replace function public.app_set_feature_flag(
  p_key text, p_enabled boolean, p_actor uuid, p_decision_ref text default null)
returns void
language plpgsql set search_path = '' as $$
declare
  v_old boolean;
begin
  if not exists (select 1 from public.admin_users u
                 where u.user_id = p_actor and u.is_active and u.role = 'admin') then
    raise exception 'feature flag: brak uprawnień';
  end if;
  select f.enabled into v_old from public.app_feature_flags f where f.key = p_key for update;
  if not found then
    raise exception 'feature flag: nieznany przełącznik %', p_key;
  end if;
  if p_enabled and coalesce(char_length(trim(p_decision_ref)), 0) < 5 then
    raise exception 'feature flag: włączenie wymaga odwołania do decyzji zleceniodawcy po sprawdzeniu prawnym';
  end if;
  update public.app_feature_flags
     set enabled = p_enabled, decision_ref = coalesce(nullif(trim(p_decision_ref), ''), decision_ref),
         changed_by = p_actor, changed_at = now()
   where key = p_key;
  insert into public.client_audit_log (actor, action, entity, payload)
  values ('staff:' || p_actor::text, 'feature_flag_changed', 'feature_flag',
          jsonb_build_object('key', p_key, 'from', v_old, 'to', p_enabled));
end $$;

-- Wspólna walidacja treści (poza CHECK w tabeli): dostępność najwyżej rok naprzód, formy współpracy z listy.
create or replace function public.candidate_ad_check_payload(p_payload jsonb)
returns void
language plpgsql stable set search_path = '' as $$
begin
  if jsonb_typeof(p_payload -> 'cooperation_forms') is distinct from 'array' then
    raise exception 'szukam-pracy: brak form współpracy';
  end if;
  if (p_payload ->> 'available_from')::date > current_date + 365 then
    raise exception 'szukam-pracy: dostępność najwyżej rok naprzód';
  end if;
  if char_length(coalesce(p_payload ->> 'description', '')) > 500 then
    raise exception 'szukam-pracy: opis najwyżej 500 znaków';
  end if;
end $$;

-- Dodanie ogłoszenia (bez konta): status unconfirmed; link potwierdzający ważny 24 h [Założenie].
-- [Założenie] jedno ogłoszenie na adres e-mail: jeśli adres ma już ogłoszenie, funkcja zwraca NULL,
-- a serwer odpowiada TAK SAMO jak przy sukcesie („Sprawdź skrzynkę”) i wysyła na ten adres link
-- do zarządzania (app_candidate_ad_send_manage_link) – brak wycieku informacji, czy adres ma ogłoszenie.
-- Turnstile, honeypot i limit Workers na IP sprawdza serwer przed wywołaniem.
create or replace function public.app_candidate_ad_submit(
  p_email text, p_payload jsonb, p_confirm_token_hash text, p_notice_version text)
returns uuid
language plpgsql set search_path = '' as $$
declare
  v_email text := lower(trim(p_email));
  v_id    uuid;
begin
  perform public.app_require_feature('szukam_pracy');
  if coalesce((p_payload ->> 'adult_confirmed')::boolean, false) is not true then
    raise exception 'szukam-pracy: ogłoszenie może dodać wyłącznie osoba pełnoletnia';
  end if;
  perform public.candidate_ad_check_payload(p_payload);
  if exists (select 1 from public.candidate_ads a
              where a.email_normalized = v_email
                and a.status in ('unconfirmed','pending_review','published')) then
    return null;
  end if;
  insert into public.candidate_ads
    (email, email_normalized, confirm_token_hash, confirm_expires_at, first_name, profession, city,
     voivodeship, cooperation_forms, experience, available_from, description, adult_confirmed, notice_version)
  values (trim(p_email), v_email, p_confirm_token_hash, now() + interval '24 hours',
          trim(p_payload ->> 'first_name'), p_payload ->> 'profession', trim(p_payload ->> 'city'),
          p_payload ->> 'voivodeship',
          array(select jsonb_array_elements_text(p_payload -> 'cooperation_forms')),
          p_payload ->> 'experience', (p_payload ->> 'available_from')::date,
          nullif(trim(p_payload ->> 'description'), ''), true, p_notice_version)
  returning id into v_id;
  return v_id;
end $$;

-- Potwierdzenie adresu (POST ze strony potwierdzenia – GET niczego nie zmienia, skanery poczty
-- otwierają linki): ogłoszenie trafia do moderacji; od teraz działa link do zarządzania.
create or replace function public.app_candidate_ad_confirm(p_confirm_token_hash text, p_manage_token_hash text)
returns uuid
language plpgsql set search_path = '' as $$
declare
  v_id uuid;
begin
  perform public.app_require_feature('szukam_pracy');
  update public.candidate_ads
     set status = 'pending_review', confirmed_at = now(), submitted_at = now(),
         confirm_token_hash = null, confirm_expires_at = null,
         manage_token_hash = p_manage_token_hash, updated_at = now()
   where confirm_token_hash = p_confirm_token_hash and status = 'unconfirmed' and confirm_expires_at > now()
  returning id into v_id;
  if v_id is null then
    raise exception 'szukam-pracy: link potwierdzający wygasł albo został użyty';
  end if;
  return v_id;
end $$;

-- „Wyślij mi link do zarządzania”: nowy token, poprzedni przestaje działać. Zwraca NULL, gdy adres nie
-- ma ogłoszenia – serwer odpowiada neutralnie w obu przypadkach.
create or replace function public.app_candidate_ad_send_manage_link(p_email text, p_new_manage_token_hash text)
returns uuid
language plpgsql set search_path = '' as $$
declare
  v_id uuid;
begin
  perform public.app_require_feature('szukam_pracy');
  update public.candidate_ads
     set manage_token_hash = p_new_manage_token_hash, updated_at = now()
   where email_normalized = lower(trim(p_email))
     and status in ('pending_review','published','rejected','expired')
  returning id into v_id;
  return v_id;
end $$;

-- Edycja przez link: każda zmiana wraca do moderacji (ogłoszenie znika z tablicy do akceptacji),
-- content_version rośnie – decyzja moderatora dla starszej wersji kończy się wyjątkiem.
create or replace function public.app_candidate_ad_update(p_manage_token_hash text, p_payload jsonb)
returns uuid
language plpgsql set search_path = '' as $$
declare
  v_id uuid;
begin
  perform public.app_require_feature('szukam_pracy');
  perform public.candidate_ad_check_payload(p_payload);
  update public.candidate_ads
     set first_name = trim(p_payload ->> 'first_name'), profession = p_payload ->> 'profession',
         city = trim(p_payload ->> 'city'), voivodeship = p_payload ->> 'voivodeship',
         cooperation_forms = array(select jsonb_array_elements_text(p_payload -> 'cooperation_forms')),
         experience = p_payload ->> 'experience', available_from = (p_payload ->> 'available_from')::date,
         description = nullif(trim(p_payload ->> 'description'), ''),
         content_version = content_version + 1, status = 'pending_review', submitted_at = now(),
         published_at = null, extended_at = null, expires_at = null, rejection_reason = null,
         updated_at = now()
   where manage_token_hash = p_manage_token_hash and p_manage_token_hash is not null
     and status in ('pending_review','published','rejected','expired')
  returning id into v_id;
  if v_id is null then
    raise exception 'szukam-pracy: link do zarządzania jest nieważny';
  end if;
  return v_id;
end $$;

-- Przedłużenie o 30 dni [Założenie]: tylko opublikowane ogłoszenie w ostatnich 7 dniach ważności,
-- bez zmiany treści (zatwierdzona wersja zostaje). Wygasłe ogłoszenie – ponownie przez edycję (moderacja).
create or replace function public.app_candidate_ad_extend(p_manage_token_hash text)
returns timestamptz
language plpgsql set search_path = '' as $$
declare
  v_expires timestamptz;
begin
  perform public.app_require_feature('szukam_pracy');
  update public.candidate_ads
     set extended_at = now(), expires_at = now() + interval '30 days', updated_at = now()
   where manage_token_hash = p_manage_token_hash and p_manage_token_hash is not null
     and status = 'published' and expires_at > now() and expires_at <= now() + interval '7 days'
  returning expires_at into v_expires;
  if v_expires is null then
    raise exception 'szukam-pracy: przedłużenie możliwe w ostatnich 7 dniach ważności opublikowanego ogłoszenia';
  end if;
  return v_expires;
end $$;

-- Usunięcie przez autora – działa ZAWSZE, także przy wyłączonym przełączniku (prawo do usunięcia danych).
-- Usuwa wiersz od razu (bez kopii), czyści niewysłane wiadomości salonów do tego adresu; ślad wysyłek
-- traci odwołanie do ogłoszenia (ad_id → NULL), zgłoszenia nadużyć dotyczące ogłoszenia znikają (cascade).
create or replace function public.app_candidate_ad_delete(p_manage_token_hash text)
returns boolean
language plpgsql set search_path = '' as $$
declare
  v_id uuid;
begin
  select id into v_id from public.candidate_ads
   where manage_token_hash = p_manage_token_hash and p_manage_token_hash is not null
   for update;
  if v_id is null then
    return false;
  end if;
  update public.outbox_emails o
     set payload = '{}'::jsonb, recipient = 'anonymized',
         status = case when o.status = 'pending' then 'failed' else o.status end
   where o.template like 'candidate\_%' and o.recipient <> 'anonymized'
     and o.id in (select l.outbox_id from public.candidate_ad_contact_log l where l.ad_id = v_id);
  delete from public.candidate_ads where id = v_id;
  return true;
end $$;

-- Moderacja (personel admin/agent; serwer sprawdza też app_is_staff w sesji aal2). Odrzucenie
-- i usunięcie wymagają uzasadnienia dla autora (statement of reasons – art. 17 DSA [do weryfikacji
-- przez prawnika]); serwer wysyła je e-mailem candidate_ad_rejected / candidate_ad_removed.
create or replace function public.app_moderate_candidate_ad(
  p_ad uuid, p_actor uuid, p_decision text, p_expected_version integer,
  p_note text default null, p_reason text default null)
returns void
language plpgsql set search_path = '' as $$
declare
  v_ad public.candidate_ads%rowtype;
begin
  perform public.app_require_feature('szukam_pracy');
  if not exists (select 1 from public.admin_users u
                 where u.user_id = p_actor and u.is_active and u.role in ('admin','agent')) then
    raise exception 'moderate: brak uprawnień';
  end if;
  select * into v_ad from public.candidate_ads where id = p_ad for update;
  if not found then
    raise exception 'moderate: brak ogłoszenia';
  end if;
  if p_decision in ('publish','reject') and p_expected_version is distinct from v_ad.content_version then
    raise exception 'moderate: ogłoszenie zmieniono w trakcie moderacji (wersja %, oczekiwano %)',
      v_ad.content_version, p_expected_version;
  end if;
  if p_decision in ('reject','remove') and coalesce(char_length(trim(p_reason)), 0) < 10 then
    raise exception 'moderate: decyzja wymaga uzasadnienia dla autora ogłoszenia';
  end if;

  if p_decision = 'publish' and v_ad.status = 'pending_review' then
    update public.candidate_ads
       set status = 'published', published_at = now(), extended_at = null,
           expires_at = now() + interval '30 days',                              -- [Założenie] 30 dni
           moderated_by = p_actor, moderation_note = p_note, rejection_reason = null, updated_at = now()
     where id = p_ad;
  elsif p_decision = 'reject' and v_ad.status = 'pending_review' then
    update public.candidate_ads
       set status = 'rejected', moderated_by = p_actor, moderation_note = p_note,
           rejection_reason = p_reason, updated_at = now()
     where id = p_ad;
  elsif p_decision = 'remove' and v_ad.status in ('published','pending_review') then
    update public.candidate_ads
       set status = 'removed', moderated_by = p_actor, moderation_note = p_note,
           rejection_reason = p_reason, removed_at = now(), updated_at = now()
     where id = p_ad;
  else
    raise exception 'moderate: niedozwolona decyzja % dla statusu %', p_decision, v_ad.status;
  end if;

  insert into public.client_audit_log (actor, action, entity, entity_id, payload)
  values ('staff:' || p_actor::text,
          case p_decision when 'publish' then 'candidate_ad_published'
                          when 'reject'  then 'candidate_ad_rejected'
                          else 'candidate_ad_removed' end,
          'candidate_ad', p_ad, jsonb_build_object('from', v_ad.status, 'version', v_ad.content_version));
end $$;

-- Wiadomość salonu do autora ogłoszenia (formularz przekazujący). Tylko właściciel aktywnego konta
-- salonu [Założenie] (serwer sprawdza sesję aal2, Turnstile i limit Workers). Wiadomość trafia e-mailem
-- na adres autora, którego salon nie widzi; Reply-To = adres kontaktowy salonu. W bazie treść i adres
-- odbiorcy istnieją tylko w outbox_emails do wysyłki (potem app_purge_relay_messages); zostaje ślad bez
-- treści (candidate_ad_contact_log). Limity [Założenie]: 1 wiadomość od salonu do ogłoszenia (w okresie
-- retencji śladu), 20 wiadomości salonu na dobę, 10 wiadomości do ogłoszenia na dobę.
create or replace function public.app_candidate_contact(p_ad uuid, p_account uuid, p_actor uuid, p_payload jsonb)
returns uuid
language plpgsql set search_path = '' as $$
declare
  v_ad     public.candidate_ads%rowtype;
  v_salon  public.client_accounts%rowtype;
  v_outbox uuid;
  v_log    uuid;
begin
  perform public.app_require_feature('szukam_pracy');
  select a.* into v_salon from public.client_accounts a
    join public.client_members m on m.account_id = a.id
   where a.id = p_account and a.status = 'active'
     and m.user_id = p_actor and m.role = 'owner' and m.status = 'active';
  if not found then
    raise exception 'candidate contact: brak uprawnień';
  end if;
  select * into v_ad from public.candidate_ads
   where id = p_ad and status = 'published' and expires_at > now()
   for update;                                   -- serializuje limity dla jednego ogłoszenia
  if not found then
    raise exception 'candidate contact: ogłoszenie niedostępne';
  end if;
  if char_length(coalesce(p_payload ->> 'message', '')) not between 20 and 1000
     or (p_payload ->> 'message') ~ '[<>]' or (p_payload ->> 'message') ~* '(https?://|www\.)'
     or coalesce(p_payload ->> 'reply_to', '') !~ '^[^@[:space:]<>]+@[^@[:space:]<>]+\.[a-z]{2,}$'
     or char_length(p_payload ->> 'reply_to') > 254 then
    raise exception 'candidate contact: nieprawidłowa wiadomość';
  end if;
  if exists (select 1 from public.candidate_ad_contact_log l where l.ad_id = p_ad and l.account_id = p_account) then
    raise exception 'candidate contact: salon już wysłał wiadomość do tego ogłoszenia';
  end if;
  if (select count(*) from public.candidate_ad_contact_log l
       where l.account_id = p_account and l.created_at > now() - interval '1 day') >= 20
     or (select count(*) from public.candidate_ad_contact_log l
          where l.ad_id = p_ad and l.created_at > now() - interval '1 day') >= 10 then
    raise exception 'candidate contact: dzienny limit wiadomości';
  end if;

  v_log := gen_random_uuid();                   -- contact_id trafia do linku „Zgłoś wiadomość” w e-mailu
  insert into public.outbox_emails (template, recipient, payload, account_id)
  values ('candidate_contact', v_ad.email,
          jsonb_build_object('salon_name', v_salon.display_name, 'salon_city', v_salon.city,
                             'reply_to', p_payload ->> 'reply_to', 'message', p_payload ->> 'message',
                             'contact_id', v_log),
          p_account)
  returning id into v_outbox;
  insert into public.candidate_ad_contact_log (id, ad_id, account_id, sent_by, outbox_id)
  values (v_log, p_ad, p_account, p_actor, v_outbox);
  -- dziennik konta: tylko fakt wysyłki (bez odwołania do ogłoszenia i bez treści)
  insert into public.client_audit_log (account_id, actor, action, entity)
  values (p_account, 'user:' || p_actor::text, 'candidate_contact_sent', 'candidate_ad');
  return v_log;
end $$;

-- „Zgłoś” przy ogłoszeniu (zgłoszenie DSA: powód + opcjonalne uzasadnienie, bez danych zgłaszającego).
create or replace function public.app_report_candidate_ad(p_ad uuid, p_reason text, p_details text default null)
returns bigint
language plpgsql set search_path = '' as $$
declare
  v_id bigint;
begin
  perform public.app_require_feature('szukam_pracy');
  if not exists (select 1 from public.candidate_ads a where a.id = p_ad and a.status = 'published') then
    raise exception 'report: ogłoszenie niedostępne';
  end if;
  insert into public.abuse_reports (target, candidate_ad_id, reason, details)
  values ('candidate_ad', p_ad, p_reason, nullif(trim(p_details), ''))
  returning id into v_id;
  return v_id;
end $$;

-- „Zgłoś wiadomość” z e-maila do autora ogłoszenia (link z contact_id; bez danych zgłaszającego).
-- Zgłoszenie wskazuje salon (reported_account_id) i przetrwa usunięcie śladu wysyłki po 30 dniach.
create or replace function public.app_report_candidate_contact(p_contact uuid, p_reason text, p_details text default null)
returns bigint
language plpgsql set search_path = '' as $$
declare
  v_account uuid;
  v_id      bigint;
begin
  perform public.app_require_feature('szukam_pracy');
  select l.account_id into v_account from public.candidate_ad_contact_log l where l.id = p_contact;
  if v_account is null then
    raise exception 'report: wiadomość nie istnieje albo minął okres przechowywania śladu';
  end if;
  insert into public.abuse_reports (target, candidate_contact_id, reported_account_id, reason, details)
  values ('candidate_contact', p_contact, v_account, p_reason, nullif(trim(p_details), ''))
  returning id into v_id;
  return v_id;
end $$;

-- Retencja (cron, codziennie) – działa także przy wyłączonym przełączniku. [Założenie] niepotwierdzone
-- po 24 h – usunięte; wygasłe, odrzucone, usunięte moderacyjnie i niezmoderowane od 30 dni – usunięte
-- 30 dni po ostatniej zmianie (czas na odwołanie od decyzji); ślad wysyłek – 30 dni.
create or replace function public.app_purge_candidate_ads()
returns integer
language plpgsql set search_path = '' as $$
declare
  v_count integer;
begin
  update public.candidate_ads set status = 'expired', updated_at = now()
   where status = 'published' and expires_at <= now();
  delete from public.candidate_ads
   where (status = 'unconfirmed' and confirm_expires_at <= now())
      or (status in ('expired','rejected','removed','pending_review') and updated_at < now() - interval '30 days');
  get diagnostics v_count = row_count;
  delete from public.candidate_ad_contact_log where created_at < now() - interval '30 days';
  return v_count;
end $$;

-- Uprawnienia funkcji zapisu: wyłącznie service_role
revoke execute on function
  public.app_activate_client_account(uuid, uuid, text, text),
  public.app_create_invitation(uuid, uuid, text, text, text),
  public.app_rotate_invitation_token(uuid, uuid, text),
  public.app_accept_invitation(text, uuid, text),
  public.app_accept_terms(uuid, uuid, text),
  public.app_revoke_member(uuid, uuid, uuid),
  public.app_confirm_team(uuid, uuid),
  public.app_revoke_dormant_members(),
  public.app_moderate_job_offer(uuid, uuid, text, integer, text, text, boolean),
  public.app_relay_job_message(text, jsonb),
  public.app_purge_relay_messages(uuid),
  public.app_expire_job_offers(),
  public.app_create_organizer_invitation(uuid, uuid, text, text, text),
  public.app_accept_organizer_invitation(text, uuid, text),
  public.app_revoke_organizer_member(uuid, uuid, uuid),
  public.app_moderate_training(uuid, uuid, text, integer, text, text),
  public.training_actor_kind(uuid, uuid),
  public.app_training_set_capacity(uuid, uuid, integer),
  public.app_training_cancel_event(uuid, uuid, text),
  public.app_training_register(uuid, uuid, uuid, text, text, text),
  public.app_training_cancel(uuid, uuid, uuid),
  public.app_training_mark_attendance(uuid, uuid, text),
  public.app_log_organizer_access(uuid, uuid, text),
  public.app_purge_training_contacts(),
  public.app_purge_audit_log(),
  public.app_require_feature(text),
  public.app_set_feature_flag(text, boolean, uuid, text),
  public.candidate_ad_check_payload(jsonb),
  public.app_candidate_ad_submit(text, jsonb, text, text),
  public.app_candidate_ad_confirm(text, text),
  public.app_candidate_ad_send_manage_link(text, text),
  public.app_candidate_ad_update(text, jsonb),
  public.app_candidate_ad_extend(text),
  public.app_candidate_ad_delete(text),
  public.app_moderate_candidate_ad(uuid, uuid, text, integer, text, text),
  public.app_candidate_contact(uuid, uuid, uuid, jsonb),
  public.app_report_candidate_ad(uuid, text, text),
  public.app_report_candidate_contact(uuid, text, text),
  public.app_purge_candidate_ads()
  from public, anon, authenticated;
grant execute on function
  public.app_activate_client_account(uuid, uuid, text, text),
  public.app_create_invitation(uuid, uuid, text, text, text),
  public.app_rotate_invitation_token(uuid, uuid, text),
  public.app_accept_invitation(text, uuid, text),
  public.app_accept_terms(uuid, uuid, text),
  public.app_revoke_member(uuid, uuid, uuid),
  public.app_confirm_team(uuid, uuid),
  public.app_revoke_dormant_members(),
  public.app_moderate_job_offer(uuid, uuid, text, integer, text, text, boolean),
  public.app_relay_job_message(text, jsonb),
  public.app_purge_relay_messages(uuid),
  public.app_expire_job_offers(),
  public.app_create_organizer_invitation(uuid, uuid, text, text, text),
  public.app_accept_organizer_invitation(text, uuid, text),
  public.app_revoke_organizer_member(uuid, uuid, uuid),
  public.app_moderate_training(uuid, uuid, text, integer, text, text),
  public.app_training_set_capacity(uuid, uuid, integer),
  public.app_training_cancel_event(uuid, uuid, text),
  public.app_training_register(uuid, uuid, uuid, text, text, text),
  public.app_training_cancel(uuid, uuid, uuid),
  public.app_training_mark_attendance(uuid, uuid, text),
  public.app_log_organizer_access(uuid, uuid, text),
  public.app_purge_training_contacts(),
  public.app_purge_audit_log(),
  public.training_actor_kind(uuid, uuid),         -- wołana wewnątrz funkcji app_* (security invoker)
  -- „Szukam pracy” (D-E): funkcje istnieją, ale przy wyłączonym przełączniku odmawiają (BP404)
  public.app_require_feature(text),
  public.app_set_feature_flag(text, boolean, uuid, text),
  public.candidate_ad_check_payload(jsonb),
  public.app_candidate_ad_submit(text, jsonb, text, text),
  public.app_candidate_ad_confirm(text, text),
  public.app_candidate_ad_send_manage_link(text, text),
  public.app_candidate_ad_update(text, jsonb),
  public.app_candidate_ad_extend(text),
  public.app_candidate_ad_delete(text),
  public.app_moderate_candidate_ad(uuid, uuid, text, integer, text, text),
  public.app_candidate_contact(uuid, uuid, uuid, jsonb),
  public.app_report_candidate_ad(uuid, text, text),
  public.app_report_candidate_contact(uuid, text, text),
  public.app_purge_candidate_ads()
  to service_role;

-- Test w CI (rozszerzenie packages/db/tests/privileges.test.sql) – pełna lista w pkt 9.6 dokumentu 11:
--  (1) żadna funkcja w public nie ma EXECUTE dla anon ani PUBLIC; dla authenticated tylko app_is_staff,
--      client_account_ids i organizer_ids;
--  (2) client_policy_reminders i job_offer_relay_log na liście service_role_only;
--  (3) właściciel salonu A nie widzi żadnego wiersza salonu B; organizator A – żadnego wiersza
--      organizatora B, 0 wierszy client_* i 0 szkiców job_offers;
--  (4) pracownik nie widzi client_policies, client_policy_documents, job_offer_contacts ani obiektów
--      w kubełku client-documents;
--  (5) anon: tylko opublikowane, nieprzeterminowane ogłoszenia i tylko kolumny publiczne
--      (select account_id → permission denied); job_offer_contacts → permission denied;
--  (6) właściciel z sesją aal1 → pusty client_account_ids('owner'); organizator z aal1 → pusty organizer_ids();
--  (7) właściciel: UPDATE published_at → permission denied; zmiana treści w pending_review → wyjątek;
--      moderacja z nieaktualną wersją → wyjątek; organizator: INSERT status 'published' → wyjątek,
--      UPDATE capacity → permission denied, zmiana organizer_id → wyjątek;
--  (8) organizator: training_registrations → 0 wierszy; training_participant_contacts tylko własnych szkoleń;
--  (9) client_audit_log: UPDATE → wyjątek; TRUNCATE i DELETE jako service_role → permission denied;
--  (10) „Szukam pracy” (D-E): przy wyłączonym przełączniku każda funkcja app_candidate_* (poza delete)
--       i app_moderate_candidate_ad → BP404, candidate_ads → 0 wierszy dla salonu i personelu;
--       anon: select z candidate_ads → permission denied także przy włączonym; salon nie czyta email;
--       organizator bez konta salonu → 0 wierszy; po wysyłce outbox candidate_contact = '{}'.
