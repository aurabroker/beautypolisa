-- =====================================================================================================
-- Strefa Klienta BeautyPolisa: konta salonów, polisy i dokumenty, tablica „Dam pracę”, „Szkolenia”
-- (z kontami organizatorów szkoleń)
-- Migracja dla NOWEGO, dedykowanego projektu Supabase portalu (decyzja D2), uruchamiana PO schema.sql
-- i rls-policies.sql (korzysta z: lead_product, leads, pricing_versions, claims_reports, outbox_emails,
-- admin_users, app_is_staff()). Opis i uzasadnienia: 11-strefa-klienta.md, wersja 1.3 – po decyzjach
-- zleceniodawcy z 11.11.2026 i 12.11.2026:
--   D-A konto przy KAŻDEJ polisie kupionej przez BeautyPolisa (nie tylko OC),
--   D-B po wygaśnięciu ostatniej polisy konto i dostęp do „Dam pracę” i „Szkoleń” zostają,
--   D-C „Dam pracę” to WYŁĄCZNIE tablica ogłoszeń: brak profili kandydatów, bazy CV, aplikacji, statusów
--       rekrutacji, wyszukiwania, polecania, oceniania, sortowania wg dopasowania i dopasowywania;
--       ogłoszeniodawca i czytelnik kontaktują się bezpośrednio,
--   D-D szkolenia dodają salony i firmy szkoleniowe (rola „organizator szkoleń”, bez polisy,
--       po weryfikacji przez Aura); publikacja po moderacji,
--   D-E „Szukam pracy” – zaprojektowane za przełącznikiem app_feature_flags('szukam_pracy');
--   P1 (12.11.2026, promocja na otwarcie portalu – ZASTĘPUJE „nieaktywne” z D-E):
--       (a) „Szukam pracy” AKTYWNE od startu: ogłoszenie dodaje osoba z kontem (e-mail + telefon
--           potwierdzony SMS, oświadczenie 18+); przełącznik zostaje, żeby można było funkcję wyłączyć,
--       (b) „Dam pracę” dla KAŻDEGO pracodawcy: konto + NIP sprawdzony w GUS (API BIR/REGON) + telefon
--           potwierdzony SMS (konta client_accounts.kind = 'employer'),
--       (c) w promocji ogłoszenia są bezpłatne i wiszą 21 dni (CHECK w tabelach + zadanie wygaszania),
--       (d) organizatorzy szkoleń płacą: 10 000 zł netto za 12 miesięcy albo 1 000 zł netto za miesiąc
--           (faktura Aura Expert poza portalem – Założenie); szkolenia widoczne tylko przy aktywnym planie,
--       nadal WYŁĄCZNIE tablica – nikt (ani Aura Expert, ani platforma) nie rekomenduje, nie wyszukuje,
--       nie dobiera, nie ocenia, nie sortuje wg dopasowania i nie dopasowuje kandydatów ani pracodawców;
--   L1 (12.11.2026) Aura Expert sp. z o.o. jest AGENTEM ubezpieczeniowym (nie brokerem), administratorem
--       danych kont i ogłoszeń; kontakt do IOD: iod@auraexpert.pl.
--   Wersja 1.4 (przegląd red team 12.11.2026, dok. 11 §26): odczyt „Szukam pracy” wyłącznie funkcją
--       app_candidate_ads_page() z kwotą dzienną (bez SELECT przez Data API), dwa poziomy zaufania
--       pracodawcy (GUS → employer_trusted_at), NIP rezerwowany dopiero przez aktywne konto, liczniki SMS
--       niezależne od usuwania kont, potwierdzone adresy kontaktowe pracodawców, zawieszenie zdejmujące
--       treści, retencja kont i zgłoszeń, walidacja w funkcjach bez wartości w komunikatach błędów.
--   00, D41 (decyzja zleceniodawcy 13.11.2026): pole „Zabiegi” w ofertach i ogłoszeniach „Szukam pracy”
--       (0–30 identyfikatorów z snippets/zabiegi-oc-beauty.json, funkcja zabiegi_ids() generowana z pliku)
--       i filtr LUB na tablicy (zabiegi && …, indeks GIN); kolejność bez zmian – od najnowszej publikacji,
--       bez dopasowywania (dok. 11 §11.10).
--   00, D42 (decyzja zleceniodawcy 13.11.2026): płatność za szkolenie z poziomu Strefy Klienta; SPRZEDAWCĄ
--       jest ORGANIZATOR; portal BEZ PROWIZJI w okresie promocji (prowizja = parametr platform_fee_settings).
--       Model: marketplace z płatnościami dzielonymi u licencjonowanego operatora (operator do wyboru) –
--       środki płyną od kupującego na subkonto / konto połączone organizatora; Aura Expert nie przyjmuje
--       ani nie przekazuje cudzych środków [kwalifikację potwierdza prawnik]. W bazie: zamówienia z kwotą
--       wyłącznie z bazy, rezerwacja miejsca na 15 minut bez nadsprzedaży (seats_held + blokada wiersza),
--       idempotentna obsługa podpisanych webhooków (podpis sprawdza Worker – sekret nie trafia do bazy),
--       zwroty inicjowane przez organizatora, audyt zmian statusów, retencja (dok. 11 §12a).
--
-- Konwencje (jak w schema.sql / rls-policies.sql):
--  * domyślne granty odebrane w schema.sql (ALTER DEFAULT PRIVILEGES … FROM public, anon, authenticated);
--    mimo to każda tabela i funkcja ma tu jawne REVOKE + jawne GRANT;
--  * RLS włączone na każdej tabeli; tabele z danymi osobowymi dodatkowo FORCE ROW LEVEL SECURITY;
--  * funkcje zapisu z niezmiennikami między kontami (zaproszenia, zapisy z limitem miejsc, moderacja,
--    formularz kontaktowy „Dam pracę”, rejestracja pracodawców i osób szukających pracy, kody SMS,
--    wyniki GUS, plany organizatorów) wykonywalne WYŁĄCZNIE przez service_role (serwer), security invoker;
--  * SECURITY DEFINER tylko tam, gdzie RLS bez niego wpada w rekurencję (client_account_ids,
--    organizer_ids, employer_account_ids), w wyzwalaczu audytu i w funkcji retencji dziennika – zawsze z set search_path = ''
--    i pełnymi nazwami obiektów, bez EXECUTE dla public/anon (błąd z audytu projektu „BEAUTY”:
--    can_manage_salon, is_katalog_admin, is_platform_admin, katalog_set_admin wykonywalne przez anon);
--  * rozłączne rodziny uprawnień klientów: client_account_ids() (salony i pracodawcy),
--    employer_account_ids() (pracodawcy z NIP w GUS + telefonem SMS + TOTP – tylko tworzenie ofert), organizer_ids()
--    (organizatorzy szkoleń) i własny wiersz osoby szukającej pracy (seeker_id = auth.uid());
--    żadna polityka nie łączy funkcji salonów/pracodawców z funkcją organizatorów;
--  * sekrety (klucz API BIR/REGON, klucz bramki SMS, klucz HMAC numerów i kodów) wyłącznie w sekretach
--    Workera – baza nie przechowuje numerów telefonów ani kodów SMS, tylko ich HMAC;
--  * polityki dla anon nigdy nie wywołują app_is_staff() (patrz komentarz w rls-policies.sql);
--  * żadnych widoków SECURITY DEFINER (w „BEAUTY” 3 takie widoki to poziom ERROR w Security Advisor);
--  * treści od salonów i organizatorów: tekst zwykły – CHECK w bazie odrzuca „<”, „>” i adresy URL
--    niezależnie od walidacji Zod na serwerze (obrona w głąb przed wstrzyknięciem do HTML i JSON-LD).
-- Plik jest wzorcem: przed wdrożeniem dzielimy go na migracje w supabase/migrations i pokrywamy testami
-- uprawnień z sekcji 9.6 dokumentu 11.
-- =====================================================================================================


-- -----------------------------------------------------------------------------------------------------
-- 1. KONTA SALONÓW I PRACODAWCÓW, CZŁONKOSTWA, ZAPROSZENIA
--    kind = 'client'   – salon, klient Aura Expert z polisą (konto zakłada personel, D-A);
--    kind = 'employer' – dowolny pracodawca z samodzielnej rejestracji (P1b): NIP sprawdzony w GUS,
--                        telefon właściciela potwierdzony SMS; dostęp tylko do „Dam pracę” i „Szukam pracy”.
--    Publikacja ofert wymaga w obu rodzajach kont tego samego (poziom 1): employer_verified_at (aktywny
--    NIP w GUS, nie starszy niż 120 dni) + telefon właściciela + TOTP. Odczyt „Szukam pracy” i wiadomości
--    do autorów – dodatkowo poziom 2 (SEC-02): salon z polisą z urzędu, pracodawca z rejestracji po
--    potwierdzeniu reprezentacji firmy przez personel (employer_trusted_at).
-- -----------------------------------------------------------------------------------------------------

create table client_accounts (
  id                uuid primary key default gen_random_uuid(),
  kind              text not null default 'client' check (kind in ('client','employer')),
  display_name      text not null check (char_length(display_name) between 2 and 120), -- nazwa w Strefie i w ogłoszeniach
  legal_name        text check (char_length(legal_name) <= 300),  -- u pracodawcy: nazwa z GUS (nie zmienia jej użytkownik)
  nip               text check (nip ~ '^[0-9]{10}$'),
  city              text check (char_length(city) <= 80),
  status            text not null default 'pending'
                      check (status in ('pending','active','suspended','closed')),
  employer_verified_at timestamptz,          -- ostatnie potwierdzenie aktywnego NIP w GUS (app_employer_record_gus)
  -- Poziom 2 zaufania (SEC-02): personel potwierdził, że rejestrujący REPREZENTUJE firmę (GUS potwierdza
  -- tylko istnienie firmy, SMS – tylko posiadanie karty SIM). Ustawia wyłącznie app_employer_trust().
  -- Bez tego konto pracodawcy z rejestracji tworzy szkice i wysyła oferty do moderacji, ale nie czyta
  -- „Szukam pracy” i nie pisze do autorów. Salon z polisą (kind = 'client') – z urzędu: zna go Aura Expert.
  employer_trusted_at   timestamptz,
  employer_trust_method text check (employer_trust_method in ('domena-email','telefon-zwrotny',
                          'list-na-adres-siedziby','przelew-weryfikacyjny')),
  employer_trusted_by   uuid references auth.users(id) on delete set null,
  display_name_approved_at timestamptz,      -- nazwa wyświetlana sprawdzona przez personel przed użyciem w e-mailu
  inactivity_warned_at  timestamptz,         -- retencja: ostrzeżenie przed zamknięciem nieużywanego konta pracodawcy
  -- Odwołanie do CRM Aura Expert (baza „aurabroker”, 12 §5.2): para (crm_tenant, crm_ref) = (crm_renewals.tenant_id,
  -- crm_renewals.klient_id) – klient_id może być unikalny tylko w obrębie tenant_id. Tylko personel.
  crm_tenant       text check (char_length(crm_tenant) <= 64),
  crm_ref          text check (char_length(crm_ref) <= 64),      -- klient_id w CRM Aura Expert („aurabroker”)
  source_lead_id    uuid references leads(id) on delete set null,  -- lead, z którego powstała polisa (jeśli był); tylko personel
  team_confirmed_at timestamptz,             -- coroczne potwierdzenie składu zespołu przez właściciela [Założenie, D-B]
  activated_at      timestamptz,
  activated_by      uuid references auth.users(id) on delete set null,
  suspended_at      timestamptz,
  closed_at         timestamptz,
  created_by        uuid references auth.users(id) on delete set null,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  check (status <> 'active' or activated_at is not null),
  check (kind <> 'employer' or nip is not null),
  check (kind <> 'employer' or status in ('pending','closed','suspended') or employer_verified_at is not null),
  check (employer_trusted_at is null or employer_trust_method is not null),
  check ((crm_tenant is null) = (crm_ref is null)),   -- odwołanie do CRM tylko jako para
  -- nazwy zastrzeżone nie mogą być nazwą wyświetlaną pracodawcy z rejestracji (podszywanie się – SEC-02)
  check (kind <> 'employer' or display_name !~* '(\m(aura|beautypolisa|ergo|hestia|colonnade)\M|beauty[ -]?polisa|lux[ -]?med|enel[ -]?med)')
);
-- Jedno AKTYWNE (albo zawieszone) konto na NIP (SEC-03): rejestracja w toku nie rezerwuje NIP, więc nikt
-- nie zablokuje firmie rejestracji ani nie sprawdzi odpowiedzią HTTP, czy NIP ma konto. Konflikt
-- rozstrzyga app_employer_activate() (konto z potwierdzoną reprezentacją wygrywa).
create unique index client_accounts_nip_uq on client_accounts (nip)
  where nip is not null and status in ('active','suspended');
-- Jedno aktywne (albo zawieszone) konto na klienta CRM (12 §5.2): pomyłka albo duplikat przy zakładaniu
-- konta kończy się błędem, a nie pokazaniem spraw i linku „Dokończ” firmy X na koncie Y. Przekaz z CRM
-- dodatkowo porównuje HMAC NIP-u z client_accounts.nip; niezgodność → kolejka konfliktów, nie zapis.
create unique index client_accounts_crm_uq on client_accounts (crm_tenant, crm_ref)
  where crm_ref is not null and status in ('active','suspended');

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
-- 1a. P1: TELEFONY (SMS), WERYFIKACJA NIP W GUS, OSOBY SZUKAJĄCE PRACY, USTAWIENIA, PROMOCJA
--     Rejestracja publiczna w Supabase Auth pozostaje wyłączona: użytkownika zakłada serwer (klucz
--     sb_secret_…) po Turnstile i limitach, a sesja powstaje dopiero po kodzie z e-maila (dok. 11, 4.12).
-- -----------------------------------------------------------------------------------------------------

-- Zweryfikowany telefon osoby (pracodawca – właściciel konta, osoba szukająca pracy). Numer NIE jest
-- przechowywany: phone_hmac = HMAC-SHA256(sekret Workera, '+48XXXXXXXXX') – do limitu kont na numer;
-- phone_last3 – do wyświetlenia „••• ••• 123”. Tylko numery komórkowe +48 (walidacja na serwerze).
create table user_phones (
  user_id      uuid primary key references auth.users(id) on delete cascade,
  phone_hmac   text not null check (phone_hmac ~ '^[0-9a-f]{64}$'),
  phone_last3  text not null check (phone_last3 ~ '^[0-9]{3}$'),
  verified_at  timestamptz not null,
  created_at   timestamptz not null default now()
);
create index user_phones_hmac_idx on user_phones (phone_hmac);

-- Kod SMS do sprawdzenia. Kod istnieje tylko w SMS; w bazie code_hmac = HMAC-SHA256(sekret kodów,
-- user_id || ':' || kod). Ważność 10 minut, najwyżej 5 prób [Założenie]. Retencja 30 dni. Tylko service_role.
-- Wiersze znikają kaskadowo z użytkownikiem Auth – dlatego NIE są podstawą limitów (SEC-04, sms_send_log).
create table phone_verifications (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  phone_hmac   text not null check (phone_hmac ~ '^[0-9a-f]{64}$'),
  phone_last3  text not null check (phone_last3 ~ '^[0-9]{3}$'),
  code_hmac    text not null check (code_hmac ~ '^[0-9a-f]{64}$'),
  attempts     smallint not null default 0 check (attempts between 0 and 5),
  expires_at   timestamptz not null,
  verified_at  timestamptz,
  created_at   timestamptz not null default now(),
  check (expires_at <= created_at + interval '10 minutes')
);
create index phone_verifications_user_idx  on phone_verifications (user_id, created_at desc);
create index phone_verifications_phone_idx on phone_verifications (phone_hmac, created_at desc);
create index phone_verifications_day_idx   on phone_verifications (created_at);

-- Licznik wysyłek SMS – tylko do dopisywania, BEZ klucza obcego do auth.users (SEC-04): usunięcie konta
-- („Usuń konto”, sprzątanie nieukończonych rejestracji) nie kasuje historii wysyłek, więc pętla
-- „rejestracja → SMS → usunięcie konta” nie odnawia limitów. Podstawa WSZYSTKICH limitów SMS: globalny
-- dzienny i godzinowy, na konto (user_ref), na numer (phone_hmac), na prefiks numeru (prefix_hmac – HMAC
-- pierwszych 5 cyfr po +48, SEC-11) i bezpiecznika konwersji (verified_at). Bez numeru i kodu w postaci
-- jawnej. Retencja 30 dni po created_at (app_purge_verification_data). Tylko service_role.
create table sms_send_log (
  id               bigint generated always as identity primary key,
  created_at       timestamptz not null default now(),
  user_ref         uuid,                     -- identyfikator konta Auth w chwili wysyłki; celowo bez FK
  verification_id  uuid,                     -- phone_verifications.id; celowo bez FK
  phone_hmac       text not null check (phone_hmac ~ '^[0-9a-f]{64}$'),
  prefix_hmac      text check (prefix_hmac ~ '^[0-9a-f]{64}$'),
  verified_at      timestamptz               -- kod potwierdzony (bezpiecznik konwersji)
);
create index sms_send_log_day_idx    on sms_send_log (created_at);
create index sms_send_log_user_idx   on sms_send_log (user_ref, created_at desc);
create index sms_send_log_phone_idx  on sms_send_log (phone_hmac, created_at desc);
create index sms_send_log_prefix_idx on sms_send_log (prefix_hmac, created_at desc) where prefix_hmac is not null;

-- Wynik sprawdzenia NIP w rejestrze REGON (API BIR GUS) – minimalny zapis, bez surowej odpowiedzi.
-- Zapisuje serwer po zapytaniu z kluczem API trzymanym wyłącznie w sekrecie Workera (app_employer_record_gus).
-- source = 'personel' – ręczne sprawdzenie przez personel, gdy usługa GUS nie odpowiada.
-- Nazwa i miejscowość jednoosobowej działalności to dane osobowe – zapisujemy tylko to, co potrzebne
-- do prewypełnienia i weryfikacji (bez ulicy, PESEL i danych wspólników).
create table employer_verifications (
  id           uuid primary key default gen_random_uuid(),
  account_id   uuid not null references client_accounts(id) on delete cascade,
  nip          text not null check (nip ~ '^[0-9]{10}$'),
  source       text not null default 'gus-bir' check (source in ('gus-bir','personel')),
  result       text not null check (result in ('aktywny','nieaktywny','nie-znaleziono','blad-uslugi')),
  regon        text check (regon ~ '^([0-9]{9}|[0-9]{14})$'),
  entity_type  text check (entity_type in ('P','F','LP','LF')),   -- typ podmiotu w BIR [do weryfikacji w dokumentacji API]
  legal_name   text check (char_length(legal_name) <= 300),
  city         text check (char_length(city) <= 80),
  postal_code  text check (postal_code ~ '^[0-9]{2}-[0-9]{3}$'),
  checked_by   text not null check (checked_by ~ '^(system:gus|staff:[0-9a-f-]{36})$'),
  checked_at   timestamptz not null default now(),
  check (result <> 'aktywny' or (regon is not null and legal_name is not null)),
  check (source = 'gus-bir' or checked_by like 'staff:%')
);
create index employer_verifications_account_idx on employer_verifications (account_id, checked_at desc);

-- Konto osoby szukającej pracy (P1a): e-mail (Supabase Auth) + telefon potwierdzony SMS + oświadczenie 18+.
-- Bez profilu, CV, zdjęcia, nazwiska i daty urodzenia. Jedno ogłoszenie na osobę (candidate_ads.seeker_id unique).
create table job_seekers (
  user_id          uuid primary key references auth.users(id) on delete cascade,
  status           text not null default 'active' check (status in ('active','suspended')),
  adult_confirmed  boolean not null check (adult_confirmed),        -- oświadczenie „Mam ukończone 18 lat”
  terms_version    text not null check (char_length(terms_version) <= 40),
  notice_version   text not null check (char_length(notice_version) <= 40),  -- klauzula informacyjna Aura Expert
  suspended_at     timestamptz,
  last_seen_at     timestamptz,              -- ustawia serwer przy logowaniu; podstawa retencji kont nieaktywnych
  inactivity_warned_at timestamptz,          -- e-mail ostrzegawczy przed zamknięciem nieużywanego konta (PRIV-14)
  created_at       timestamptz not null default now(),
  check (status <> 'suspended' or suspended_at is not null)
);

-- Ustawienia operacyjne (jeden wiersz). Limity SMS chronią przed SMS pumping / toll fraud: nawet przy
-- obejściu limitów Workers baza nie wyśle więcej niż sms_daily_cap kodów na dobę. [Założenie: wartości]
create table app_settings (
  id                   boolean primary key default true check (id),
  sms_daily_cap        integer  not null default 300 check (sms_daily_cap between 1 and 5000),
  sms_per_user_day     smallint not null default 5   check (sms_per_user_day between 1 and 20),
  sms_per_number_day   smallint not null default 3   check (sms_per_number_day between 1 and 20),
  accounts_per_number  smallint not null default 2   check (accounts_per_number between 1 and 5),
  -- SEC-11: limit godzinowy (ok. 1/8 dobowego), limit na prefiks numeru i bezpiecznik konwersji – wyczerpanie
  -- globalnego limitu przez jednego atakującego nie zatrzymuje rejestracji na całą dobę
  sms_hourly_cap       smallint not null default 40  check (sms_hourly_cap between 1 and 1000),
  sms_per_prefix_hour  smallint not null default 10  check (sms_per_prefix_hour between 1 and 100),
  sms_breaker_min_sends smallint not null default 20 check (sms_breaker_min_sends between 5 and 1000),
  sms_breaker_min_ratio numeric(3,2) not null default 0.30 check (sms_breaker_min_ratio between 0 and 1),
  -- SEC-01: kwota odsłon kart „Szukam pracy” na konto pracodawcy na dobę i próg alertu dla zespołu
  candidate_cards_per_day   smallint not null default 200 check (candidate_cards_per_day between 20 and 2000),
  candidate_cards_alert     smallint not null default 150 check (candidate_cards_alert between 20 and 2000),
  -- SEC-06: wiadomości pracodawcy do autorów na dobę: nowe konto (14 dni albo do pierwszej opublikowanej
  -- oferty) i pozostałe
  contact_new_account_per_day smallint not null default 3  check (contact_new_account_per_day between 1 and 50),
  contact_per_account_day     smallint not null default 20 check (contact_per_account_day between 1 and 100),
  -- 00, D42: płatności za szkolenia – czas rezerwacji miejsca i limity przeciw blokowaniu miejsc
  order_reservation_minutes   smallint not null default 15 check (order_reservation_minutes between 10 and 30),
  orders_per_user_hour        smallint not null default 10 check (orders_per_user_hour between 1 and 50),
  active_reservations_per_user smallint not null default 3 check (active_reservations_per_user between 1 and 10),
  -- Przegląd red team płatności (13.11.2026): minimalny czas sesji płatności u operatora (Stripe Checkout:
  -- 30 min – 24 h; pozostali – do weryfikacji) – rezerwacja = max(order_reservation_minutes, minimum operatora)
  checkout_min_minutes        jsonb not null default '{"stripe": 30}'::jsonb
                                check (jsonb_typeof(checkout_min_minutes) = 'object'),
  -- karencja nowego albo zmienionego konta wypłat (przejęcie konta organizatora) i blokada „Wypłat” i zwrotów
  -- po resecie drugiego składnika właściciela przez doradcę
  payout_change_cooldown_hours smallint not null default 72 check (payout_change_cooldown_hours between 24 and 336),
  -- limity sprzedaży dla nowych organizatorów (fałszywy organizator: sprzedaż, wypłata, zniknięcie)
  new_organizer_days          smallint not null default 60 check (new_organizer_days between 0 and 365),
  new_organizer_paid_orders   smallint not null default 30 check (new_organizer_paid_orders between 1 and 1000),
  new_organizer_max_grosze    integer  not null default 2000000 check (new_organizer_max_grosze between 10000 and 100000000),
  changed_by          uuid references auth.users(id) on delete set null,
  changed_at           timestamptz not null default now()
);
insert into app_settings default values;

-- Promocja na otwarcie portalu (P1). Gdy promocja jest aktywna: ogłoszenia „Dam pracę” i „Szukam pracy”
-- są bezpłatne i wiszą ad_days dni (21); ceny planów organizatorów: 10 000 zł netto / 12 mies. albo
-- 1 000 zł netto / mies. Zasady po promocji – do ustalenia: bez aktywnej promocji funkcje publikacji
-- i planów odmawiają (BP409) do czasu nowej decyzji zleceniodawcy [Założenie].
create table app_promotions (
  key                   text primary key check (key in ('otwarcie-portalu')),
  enabled               boolean not null default false,
  starts_at             timestamptz not null default now(),
  ends_at               timestamptz,                             -- NULL = do odwołania
  free_ads              boolean not null default true,
  ad_days               smallint not null default 21 check (ad_days between 1 and 21),
  organizer_12m_net_pln numeric(10,2) not null default 10000 check (organizer_12m_net_pln > 0),
  organizer_1m_net_pln  numeric(10,2) not null default 1000  check (organizer_1m_net_pln > 0),
  decision_ref          text check (char_length(decision_ref) between 5 and 200),
  changed_by            uuid references auth.users(id) on delete set null,
  changed_at            timestamptz not null default now(),
  check (not enabled or decision_ref is not null),
  check (ends_at is null or ends_at > starts_at)
);
insert into app_promotions (key, enabled, decision_ref)
values ('otwarcie-portalu', true, 'decyzja zleceniodawcy P1 z 12.11.2026 – promocja na otwarcie portalu');


-- -----------------------------------------------------------------------------------------------------
-- 2. POLISY I DOKUMENTY (dodaje personel Aura Expert – agenta ubezpieczeniowego – w /panel;
--    brak integracji z ubezpieczycielem w MVP)
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
  published_at        timestamptz,            -- klient widzi polisę dopiero po publikacji przez personel
  crm_ref             text check (char_length(crm_ref) <= 64), -- id polisy w CRM Aura Expert (crm_renewals.polisa_id, w obrębie crm_tenant konta – 12 §5.2, Q7); tylko personel
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

-- Notatki wewnętrzne personelu: osobna tabela, bo uprawnienia kolumnowe obejmują całą rolę authenticated
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
-- training_registered, training_waitlisted, training_promoted, training_reminder_24h, training_cancelled;
-- P1: employer_registered, employer_suspended_gus, candidate_ad_published, candidate_ad_rejected,
-- candidate_ad_removed, candidate_ad_expiring, candidate_contact (adres odbiorcy rozwiązuje serwer),
-- organizer_plan_expiring, sms_spend_alert (do zespołu Aura). Kody SMS nie idą przez outbox.
-- Token zaproszenia NIGDY nie trafia do payload: przy ponowieniu wysyłki serwer rotuje token
-- (app_rotate_invitation_token) i wysyła nowy link, a poprzedni przestaje działać.


-- -----------------------------------------------------------------------------------------------------
-- 3. „DAM PRACĘ” – TABLICA OGŁOSZEŃ (decyzje D-C i P1)
--    Platforma przechowuje wyłącznie ogłoszenia pracodawców (salonów z polisą i pracodawców z samodzielnej
--    rejestracji) i sposób kontaktu wybrany przez pracodawcę. NIE MA tu (i nie wolno dodawać): aplikacji,
--    profili kandydatów, plików CV, statusów rekrutacji, wyszukiwarki kandydatów, rekomendacji ani
--    dopasowywania. Moderacja Aura dotyczy wyłącznie treści ogłoszenia (w tym reguł antyoszustwowych).
--    P1c: ogłoszenie wisi najwyżej 21 dni od publikacji (CHECK) – długość z app_promotions.ad_days.
-- -----------------------------------------------------------------------------------------------------

-- Zabiegi w ogłoszeniach (00, D41 – decyzja zleceniodawcy 13.11.2026): pole „Zabiegi” w ofertach
-- (job_offers) i w ogłoszeniach „Szukam pracy” (candidate_ads) oraz filtr na tablicy. Lista = kanoniczna
-- lista 117 zabiegów z snippets/zabiegi-oc-beauty.json (D29) – dane w repozytorium, import przy budowaniu:
-- baza NIE ma tabeli słownikowej (nazwy i grupy renderuje aplikacja z tego samego pliku), a dozwolone
-- identyfikatory zwraca funkcja IMMUTABLE wygenerowana z pliku (blok gen:zabiegi-ids). Dlaczego tak:
-- (a) CHECK nie czyta tabeli (deterministyczny, bez zależności kolejności przy pg_dump/restore), (b) brak
-- tabeli = brak dodatkowych polityk RLS i grantów, (c) jedno źródło prawdy jak w kalkulatorze i na stronie OC.
-- Wersjonowanie: identyfikatory są stabilne i lista tylko rośnie – pozycja usunięta z pliku przechodzi do
-- „wycofanych”: zostaje dozwolona w ogłoszeniach, które już ją mają (CHECK z p_tylko_aktywne = false), ale
-- nowo dodawane zabiegi muszą być aktywne (guard ofert, app_candidate_ad_save). Zmiana listy = nowa migracja
-- z tego samego skryptu (CI: --check). Nazwa ani grupa zabiegu nie trafiają do bazy.
-- EXECUTE: authenticated (CHECK w job_offers sprawdza się przy zapisie właściciela przez Data API) i service_role;
-- anon – nie (tylko czyta). Funkcja zwraca wyłącznie publiczne identyfikatory z listy na stronie OC.
-- gen:zabiegi-ids
-- Wygenerowane skryptem gen_zabiegi_sql.py z snippets/zabiegi-oc-beauty.json – NIE EDYTOWAĆ RĘCZNIE.
-- Wersja listy: 117 pozycji (grupa 1: 40, 2: 38, 3: 31, 4: 8), sha256 pliku a527564cf868fd23546c1c21a69ce7f52a0adb153c67043c7663990370f249c1.
-- Wycofane (usunięte z pliku w kolejnych wersjach – dozwolone tylko w ogłoszeniach, które już je mają): brak.
create or replace function public.zabiegi_ids(p_tylko_aktywne boolean default false)
returns text[]
language plpgsql immutable parallel safe set search_path = '' as $$
declare
  v_aktywne  text[] := array['g1-01','g1-02','g1-03','g1-04','g1-05','g1-06','g1-07','g1-08','g1-09','g1-10','g1-11','g1-12',
                      'g1-13','g1-14','g1-15','g1-16','g1-17','g1-18','g1-19','g1-20','g1-21','g1-22','g1-23','g1-24',
                      'g1-25','g1-26','g1-27','g1-28','g1-29','g1-30','g1-31','g1-32','g1-33','g1-34','g1-35','g1-36',
                      'g1-37','g1-38','g1-39','g1-40','g2-01','g2-02','g2-03','g2-04','g2-05','g2-06','g2-07','g2-08',
                      'g2-09','g2-10','g2-11','g2-12','g2-13','g2-14','g2-15','g2-16','g2-17','g2-18','g2-19','g2-20',
                      'g2-21','g2-22','g2-23','g2-24','g2-25','g2-26','g2-27','g2-28','g2-29','g2-30','g2-31','g2-32',
                      'g2-33','g2-34','g2-35','g2-36','g2-37','g2-38','g3-01','g3-02','g3-03','g3-04','g3-05','g3-06',
                      'g3-07','g3-08','g3-09','g3-10','g3-11','g3-12','g3-13','g3-14','g3-15','g3-16','g3-17','g3-18',
                      'g3-19','g3-20','g3-21','g3-22','g3-23','g3-24','g3-25','g3-26','g3-27','g3-28','g3-29','g3-30',
                      'g3-31','g4-01','g4-02','g4-03','g4-04','g4-05','g4-06','g4-07','g4-08']::text[];
  v_wycofane text[] := array[]::text[];
begin
  return case when p_tylko_aktywne then v_aktywne else v_aktywne || v_wycofane end;
end $$;
-- /gen:zabiegi-ids
revoke all on function public.zabiegi_ids(boolean) from public, anon;
grant execute on function public.zabiegi_ids(boolean) to authenticated, service_role;

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
  -- zabiegi wybrane przez pracodawcę (00, D41): opcjonalnie 0–30 identyfikatorów z listy (zabiegi_ids());
  -- guard dla właściciela usuwa powtórzenia, sortuje i odrzuca nowo dodane pozycje wycofane (BP422)
  zabiegi          text[] not null default '{}'
                     check (cardinality(zabiegi) <= 30 and zabiegi <@ public.zabiegi_ids()),
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
  check (expires_at is null or published_at is null or expires_at <= published_at + interval '21 days'), -- P1c
  check (concat_ws(' ', title, description, requirements, benefits) !~ '[<>]'),
  check (concat_ws(' ', title, description, requirements, benefits) !~* '(https?://|www\.)'),
  -- SEC-19: kontakt wyłącznie w bloku kontaktu – bez adresów e-mail i numerów telefonów w treści
  -- (wzorzec numeru: 9 cyfr w grupach 3-3-3 albo 2-3-2-2, opcjonalnie z +48; nie łapie widełek ani dat)
  check (concat_ws(' ', title, description, requirements, benefits) !~ '@'),
  check (concat_ws(' ', title, description, requirements, benefits)
         !~ '(^|[^0-9])(\+?48[ .-]?)?([0-9]{3}[ .-]?[0-9]{3}[ .-]?[0-9]{3}|[0-9]{2}[ .-]?[0-9]{3}[ .-]?[0-9]{2}[ .-]?[0-9]{2})([^0-9]|$)')
);
create index job_offers_public_idx  on job_offers (status, expires_at desc);
create index job_offers_account_idx on job_offers (account_id, status);
create index job_offers_filter_idx  on job_offers (profession, voivodeship) where status = 'published';
-- filtr „Zabiegi” (00, D41): zabiegi && $1 (ogłoszenie zawiera którykolwiek z wybranych) – GIN tylko dla opublikowanych
create index job_offers_zabiegi_idx on job_offers using gin (zabiegi) where status = 'published';

-- Sposób kontaktu wybrany przez salon. Osobna tabela BEZ grantu dla anon: dane kontaktowe nie trafiają
-- do listy, JSON-LD ani sitemap; serwer pokazuje je tylko na stronie pojedynczego ogłoszenia po kliknięciu
-- „Pokaż kontakt” (Turnstile + limit na IP). Domyślnie „formularz”: wiadomość kandydata trafia e-mailem
-- na adres salonu (email), którego strona nie pokazuje. Usuwane 30 dni po zamknięciu/wygaśnięciu oferty.
-- SEC-05: adres (formularz i e-mail) musi być POTWIERDZONYM adresem konta (employer_reply_addresses) –
-- inaczej moderacja nie opublikuje ogłoszenia, a app_relay_job_message() nie wyśle wiadomości.
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

-- Potwierdzone adresy e-mail konta pracodawcy (SEC-05): adres rekrutacyjny w ofercie (formularz, e-mail)
-- i adres do odpowiedzi w wiadomości do autora „Szukam pracy” muszą być na tej liście z verified_at.
-- Adres logowania właściciela dopisuje serwer jako potwierdzony (sesja dowodzi dostępu do skrzynki –
-- app_reply_address_from_login); każdy inny adres – link z jednorazowym tokenem wysłany na ten adres
-- (app_reply_address_request → app_reply_address_confirm; w bazie tylko sha256 tokenu, ważny 24 h).
-- Niepotwierdzone wiersze usuwane po 7 dniach. Zapis tylko service_role.
create table employer_reply_addresses (
  account_id       uuid not null references client_accounts(id) on delete cascade,
  email_normalized text not null check (char_length(email_normalized) <= 254
                     and email_normalized ~ '^[^@[:space:]<>A-Z]+@[^@[:space:]<>A-Z]+\.[a-z]{2,}$'),
  token_hash       text unique check (token_hash ~ '^[0-9a-f]{64}$'),
  token_expires_at timestamptz,
  requested_by     uuid references auth.users(id) on delete set null,
  verified_at      timestamptz,
  created_at       timestamptz not null default now(),
  primary key (account_id, email_normalized),
  check (verified_at is not null or (token_hash is not null and token_expires_at is not null))
);


-- -----------------------------------------------------------------------------------------------------
-- 3a. „SZUKAM PRACY” – AKTYWNE OD STARTU (decyzja P1a z 12.11.2026, zastępuje „nieaktywne” z D-E)
--     Ogłoszenia osób szukających pracy na tablicy „Dam pracę”. Ogłoszenie dodaje osoba z kontem
--     (job_seekers: e-mail + telefon potwierdzony SMS + oświadczenie 18+). Przełącznik
--     app_feature_flags('szukam_pracy') jest WŁĄCZONY od startu i zostaje, żeby admin mógł funkcję
--     wyłączyć jednym ruchem. Nadal wyłącznie tablica (D-C): platforma i Aura nie rekomendują, nie
--     wyszukują, nie dobierają, nie oceniają, nie sortują wg dopasowania i nie dopasowują kandydatów.
--     NIE MA tu (i nie wolno dodawać): profili kandydatów, zdjęć, nazwisk, telefonów, CV, wyszukiwarki
--     pełnotekstowej po osobach, rekomendacji ani dopasowywania. Przy wyłączonym przełączniku: funkcje
--     zapisu odmawiają (BP404), pracodawcy i personel nie widzą ogłoszeń; autor nadal widzi i usuwa
--     swoje ogłoszenie, a retencja działa (tylko zmniejszają ilość danych).
-- -----------------------------------------------------------------------------------------------------

-- Przełączniki funkcji. Zmienia wyłącznie app_set_feature_flag() (admin Aura, sesja aal2 sprawdzona
-- przez serwer); włączenie wymaga odwołania do decyzji zleceniodawcy; każda zmiana w dzienniku.
create table app_feature_flags (
  key           text primary key check (key in ('szukam_pracy')),
  enabled       boolean not null default false,
  decision_ref  text check (char_length(decision_ref) between 5 and 200), -- np. „decyzja zleceniodawcy P1 z 12.11.2026”
  changed_by    uuid references auth.users(id) on delete set null,
  changed_at    timestamptz not null default now(),
  check (not enabled or decision_ref is not null)
);
insert into app_feature_flags (key, enabled, decision_ref)
values ('szukam_pracy', true, 'decyzja zleceniodawcy P1 z 12.11.2026 – „Szukam pracy” aktywne od startu');

-- Ogłoszenie osoby szukającej pracy – jedno na konto (seeker_id unique). Minimalny zakres danych: imię
-- (jedno słowo – bez nazwiska), zawód, miasto i województwo, formy współpracy, doświadczenie,
-- dostępność od, krótki opis ≤ 500 znaków. Bez zdjęcia, nazwiska, telefonu i e-maila w treści.
-- Pracodawcy NIE czytają tej tabeli przez Data API (SEC-01): brak polityki odczytu dla pracodawców;
-- karty zwraca wyłącznie app_candidate_ads_page() (service_role) – najwyżej 20 na stronę, od najnowszej
-- publikacji, z dzienną kwotą odsłon na konto, z pominięciem firm ukrytych przez autora (PRIV-07)
-- i zablokowanych pracodawców (SEC-06), tylko dla pracodawcy z potwierdzoną reprezentacją firmy
-- (SEC-02) i tylko przy włączonym przełączniku. anon nie ma żadnego grantu (strony noindex, nigdy
-- publiczne); kolumna seeker_id bez grantu. Pracodawca widzi tylko ad_ref – identyfikator nadawany
-- od nowa przy każdej publikacji (PRIV-07: nie da się śledzić osoby między kolejnymi publikacjami).
-- Miasto opcjonalne – wystarczy województwo (PRIV-07). Ważność 21 dni (P1c). Administrator danych:
-- Aura Expert sp. z o.o. (L1, P1).
create table candidate_ads (
  id                 uuid primary key default gen_random_uuid(),
  ad_ref             uuid not null unique default gen_random_uuid(),   -- identyfikator dla pracodawców; nowy przy każdej publikacji
  seeker_id          uuid not null unique references job_seekers(user_id) on delete cascade,
  status             text not null default 'pending_review'
                       check (status in ('pending_review','published','rejected','expired','removed')),
  content_version    integer not null default 1,     -- rośnie przy każdej edycji; moderator zatwierdza konkretną wersję
  first_name         text not null check (first_name ~ '^[^[:space:][:digit:][:punct:]]{2,30}(-[^[:space:][:digit:][:punct:]]{2,30})?$'),
  profession         text not null check (profession in ('kosmetolog','fryzjer','podolog','linergistka',
                       'stylistka-paznokci','tatuazysta','recepcja','inny')),
  city               text check (char_length(city) between 2 and 80 and city !~ '[[:digit:]<>@]'),  -- opcjonalne (PRIV-07)
  voivodeship        text not null check (voivodeship in ('dolnoslaskie','kujawsko-pomorskie','lubelskie','lubuskie',
                       'lodzkie','malopolskie','mazowieckie','opolskie','podkarpackie','podlaskie','pomorskie',
                       'slaskie','swietokrzyskie','warminsko-mazurskie','wielkopolskie','zachodniopomorskie')),
  cooperation_forms  text[] not null check (cardinality(cooperation_forms) between 1 and 5
                       and cooperation_forms <@ array['umowa-o-prace','umowa-zlecenie','b2b','najem-stanowiska','inna']),
  experience         text not null check (experience in ('do-1-roku','1-3-lata','3-5-lat','powyzej-5-lat')),
  available_from     date not null,
  description        text check (char_length(description) <= 500),
  -- zabiegi wybrane przez autora (00, D41): opcjonalnie 0–30 identyfikatorów z listy; zapis tylko przez
  -- app_candidate_ad_save() (walidacja BP422 bez wartości, bez powtórzeń, nowo dodane – tylko aktywne)
  zabiegi            text[] not null default '{}'
                       check (cardinality(zabiegi) <= 30 and zabiegi <@ public.zabiegi_ids()),
  notice_version     text not null check (char_length(notice_version) <= 40), -- wersja regulaminu i klauzuli informacyjnej
  submitted_at       timestamptz,
  published_at       timestamptz,
  expires_at         timestamptz,
  moderated_by       uuid references auth.users(id) on delete set null,
  moderation_note    text check (char_length(moderation_note) <= 1000),  -- wewnętrzna; bez grantu
  rejection_reason   text check (char_length(rejection_reason) <= 1000), -- uzasadnienie decyzji dla autora (DSA)
  removed_at         timestamptz,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  check (status <> 'published' or (published_at is not null and expires_at is not null)),
  check (expires_at is null or published_at is null or expires_at <= published_at + interval '21 days'), -- P1c
  check (status not in ('rejected','removed') or rejection_reason is not null),
  -- tekst zwykły: bez znaczników, adresów URL, adresów e-mail i numerów telefonów (kontakt tylko przez formularz)
  check (coalesce(description, '') !~ '[<>@]'),
  check (coalesce(description, '') !~* '(https?://|www\.)'),
  check (coalesce(description, '') !~ '[0-9][0-9 ()./-]{6,}[0-9]')
);
create index candidate_ads_public_idx on candidate_ads (status, published_at desc, ad_ref desc);
create index candidate_ads_filter_idx on candidate_ads (profession, voivodeship) where status = 'published';
create index candidate_ads_zabiegi_idx on candidate_ads using gin (zabiegi) where status = 'published';  -- 00, D41

-- „Ukryj moje ogłoszenie przed firmami o NIP …” (PRIV-07): obecny albo poprzedni pracodawca autora nie
-- zobaczy jego karty ani nie napisze do niego (sprawdza app_candidate_ads_page i app_candidate_contact).
-- Najwyżej 10 NIP na osobę [Założenie]. Autor czyta własną listę; zapis – app_candidate_hidden_nips_set().
create table candidate_ad_hidden_nips (
  seeker_id   uuid not null references job_seekers(user_id) on delete cascade,
  nip         text not null check (nip ~ '^[0-9]{10}$'),
  created_at  timestamptz not null default now(),
  primary key (seeker_id, nip)
);

-- „Zablokuj tego pracodawcę” z e-maila z wiadomością (SEC-06): zablokowane konto nie widzi karty autora
-- i nie może do niego napisać. Tylko service_role (autor blokuje linkiem z contact_id).
create table candidate_blocks (
  seeker_id   uuid not null references job_seekers(user_id) on delete cascade,
  account_id  uuid not null references client_accounts(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (seeker_id, account_id)
);

-- Dzienne liczniki odsłon kart „Szukam pracy” na konto pracodawcy (SEC-01) – bez odwołań do ogłoszeń
-- i osób. Kwota i próg alertu w app_settings; retencja 30 dni. Tylko service_role.
create table candidate_ad_views_daily (
  account_id  uuid not null references client_accounts(id) on delete cascade,
  day         date not null,
  n           integer not null default 0 check (n >= 0),
  alerted_at  timestamptz,
  primary key (account_id, day)
);

-- Ślad wysyłki wiadomości pracodawcy do autora ogłoszenia – BEZ treści wiadomości i bez adresu odbiorcy
-- (treść istnieje tylko w outbox_emails do wysyłki, potem app_purge_relay_messages ją czyści; adres
-- autora rozwiązuje serwer przy wysyłce z Supabase Auth – w outbox jest tylko znacznik 'user:<uuid>').
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
-- edycja opisu z ponowną moderacją). Znaczek: „Organizator zweryfikowany przez Aura Expert
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
  -- reset drugiego składnika przez doradcę (00, D28): przez payout_change_cooldown_hours (72 h) właściciel
  -- nie zleca zwrotów i nie zmienia „Wypłat” (przegląd red team płatności 13.11.2026)
  mfa_reset_at   timestamptz,
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
  -- przy szkoleniu płatnym strona pokazuje cenę brutto, a fakturę wystawia organizator (sprzedawca).
  -- 00, D42: payment_mode = 'online' – zapłata w Strefie Klienta u operatora płatności na konto organizatora
  -- (zamówienie training_orders, rezerwacja miejsca); 'poza_portalem' – rozliczenie bez portalu (jak dotąd)
  price_kind             text not null default 'bezplatne' check (price_kind in ('bezplatne','platne')),
  price_gross_pln        numeric(10,2) check (price_gross_pln > 0),
  payment_mode           text not null default 'poza_portalem' check (payment_mode in ('poza_portalem','online')),
  seats_held             integer not null default 0 check (seats_held >= 0), -- miejsca w rezerwacjach (zamówienia 'reserved')
  submitted_at           timestamptz,
  published_at           timestamptz,
  moderated_by           uuid references auth.users(id) on delete set null,
  moderation_note        text check (char_length(moderation_note) <= 1000),  -- bez grantu dla authenticated
  rejection_reason       text check (char_length(rejection_reason) <= 500),  -- widoczna dla organizatora
  cancelled_at           timestamptz,
  -- P1d: koniec ciągłej ważności planów organizatora; ustawiają wyłącznie app_moderate_training()
  -- i app_set_organizer_plan()/app_cancel_organizer_plan() (bez grantu); RLS katalogu wymaga > now()
  plan_valid_until       timestamptz,
  created_by             uuid references auth.users(id) on delete set null,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  check (ends_at > starts_at),
  -- ostatnia linia obrony przed nadsprzedażą: zapisani + miejsca w rezerwacjach (00, D42) ≤ limit
  check (capacity is null or seats_registered + seats_held <= capacity),
  check (format = 'online' or city is not null),
  check ((price_kind = 'platne') = (price_gross_pln is not null)),
  check (payment_mode = 'poza_portalem' or price_kind = 'platne'),
  check (status <> 'published' or published_at is not null),
  check (concat_ws(' ', title, summary, description, venue_name, city) !~ '[<>]'),
  check (concat_ws(' ', title, summary, description, venue_name, city) !~* '(https?://|www\.)')
);
create index trainings_catalog_idx   on trainings (status, starts_at);

-- Plany organizatorów (P1d): promocja 10 000 zł netto za 12 miesięcy albo 1 000 zł netto za miesiąc;
-- pozostałe zasady cennika szkoleń – do ustalenia. Rozliczenie fakturą Aura Expert poza portalem
-- [Założenie]; plan, jego status i ważność ustawia wyłącznie personel (app_set_organizer_plan).
-- Szkolenia organizatora są widoczne w katalogu i przyjmują zapisy tylko do końca ciągłej ważności
-- planów (trainings.plan_valid_until – migawka ustawiana przez funkcje, sprawdzana w RLS).
create table organizer_plans (
  id             uuid primary key default gen_random_uuid(),
  organizer_id   uuid not null references training_organizers(id) on delete cascade,
  plan_code      text not null check (plan_code in ('promo-12m','promo-1m')),
  price_net_pln  numeric(10,2) not null check (price_net_pln > 0),   -- migawka ceny z app_promotions
  valid_from     timestamptz not null,
  valid_until    timestamptz not null,
  status         text not null default 'active' check (status in ('active','cancelled')),
  invoice_ref    text check (char_length(invoice_ref) between 3 and 60 and invoice_ref !~ '[<>]'), -- numer faktury (poza portalem)
  set_by         uuid references auth.users(id) on delete set null,
  cancelled_at   timestamptz,
  cancelled_by   uuid references auth.users(id) on delete set null,
  created_at     timestamptz not null default now(),
  check (plan_code <> 'promo-12m' or valid_until = valid_from + interval '12 months'),
  check (plan_code <> 'promo-1m'  or valid_until = valid_from + interval '1 month'),
  check (status <> 'cancelled' or cancelled_at is not null)
);
create index organizer_plans_org_idx on organizer_plans (organizer_id, valid_from);
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
-- 4a. PŁATNOŚCI ZA SZKOLENIA (00, D42 – decyzja zleceniodawcy 13.11.2026; dok. 11 §12a)
-- -----------------------------------------------------------------------------------------------------
-- Sprzedawcą jest ORGANIZATOR. Płatność obsługuje licencjonowany operator (marketplace z płatnościami
-- dzielonymi – operator do wyboru, adapter PaymentProvider w Workerze): kupujący płaci na stronie operatora
-- (BLIK, karta, przelew), środki trafiają na subkonto / konto połączone organizatora, Aura Expert ich nie
-- przyjmuje ani nie przekazuje [kwalifikację prawną potwierdza prawnik]. Baza portalu: zamówienie z kwotą
-- wyłącznie z bazy (migawka ceny szkolenia), rezerwacja miejsca z wygaśnięciem, stany płatności z podpisanych
-- webhooków (podpis i – gdzie operator tego wymaga – potwierdzenie transakcji w API sprawdza Worker; sekrety
-- operatora tylko w sekretach Workera), zwroty, audyt i retencja. Bez danych kart i numerów rachunków.
-- Kwoty w groszach (integer). Wszystkie zapisy – wyłącznie funkcjami service_role (backend_only_guard).

-- Prowizja platformy (application fee) jako parametr z historią. Decyzja 00, D42: w okresie promocji 0 %.
-- Zmienia wyłącznie admin z odwołaniem do decyzji zleceniodawcy (app_set_platform_fee); zamówienie
-- przechowuje migawkę stawki i kwoty – zmiana stawki nie działa wstecz.
create table platform_fee_settings (
  id               uuid primary key default gen_random_uuid(),
  valid_from       timestamptz not null unique,
  fee_bps          smallint not null check (fee_bps between 0 and 3000),          -- punkty bazowe: 100 = 1 %
  fee_fixed_grosze integer  not null default 0 check (fee_fixed_grosze between 0 and 10000),
  decision_ref     text not null check (char_length(decision_ref) between 5 and 200),
  set_by           uuid references auth.users(id) on delete set null,
  created_at       timestamptz not null default now()
);
insert into platform_fee_settings (valid_from, fee_bps, fee_fixed_grosze, decision_ref)
values ('2026-11-13 00:00:00+01', 0, 0, 'decyzja zleceniodawcy 00, D42 z 13.11.2026 – bez prowizji w okresie promocji');

-- Konto organizatora u operatora („Wypłaty”): subkonto / konto połączone zakłada i weryfikuje (KYC/KYB)
-- OPERATOR na swojej stronie (link z createOnboardingLink). Portal przechowuje tylko identyfikator konta
-- u operatora i stan zdolności do przyjmowania płatności i wypłat – bez numeru rachunku, dokumentów
-- i danych osób reprezentujących. Stan ustawia wyłącznie operator (webhook albo odpytanie getPayoutStatus);
-- personel nie może „włączyć” płatności ręcznie.
create table organizer_payout_accounts (
  id                   uuid primary key default gen_random_uuid(),
  organizer_id         uuid not null references training_organizers(id) on delete restrict,
  provider             text not null check (provider in ('p24','payu','tpay','stripe')),
  provider_account_ref text not null check (provider_account_ref ~ '^[A-Za-z0-9_.:-]{3,100}$'), -- bez grantu
  status               text not null default 'onboarding'
                         check (status in ('onboarding','active','restricted','disabled')),
  charges_enabled      boolean not null default false,
  payouts_enabled      boolean not null default false,
  requirements_due     boolean not null default true,
  status_checked_at    timestamptz,
  activated_at         timestamptz,
  -- karencja (przegląd red team 13.11.2026): zamówienia i publikacja dopiero od usable_from = aktywacja albo
  -- zmiana rachunku wypłat u operatora + app_settings.payout_change_cooldown_hours (72 h)
  usable_from          timestamptz,
  payout_destination_changed_at timestamptz,          -- ostatnia zmiana rachunku wypłat zgłoszona przez operatora
  kyb_tax_id_match     boolean,                       -- NIP z KYB operatora = NIP profilu; NULL – operator nie podaje
  created_by           uuid references auth.users(id) on delete set null,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  unique (provider, provider_account_ref),
  check (status <> 'active' or (charges_enabled and not requirements_due and activated_at is not null
                                and usable_from is not null and kyb_tax_id_match is distinct from false))
);
create unique index organizer_payout_accounts_one_uq on organizer_payout_accounts (organizer_id)
  where status <> 'disabled';

-- Warunki sprzedaży organizatora (regulamin organizatora + informacje przedkontraktowe sprzedawcy):
-- dane sprzedawcy (DSA art. 30 – identyfikowalność przedsiębiorców; NIP zgodny ze zweryfikowanym profilem),
-- zasady rezygnacji i zwrotów, informacja o prawie odstąpienia, reklamacje, pełna treść. Organizator
-- składa nową wersję, personel sprawdza ją z profilem organizatora; jedna aktywna wersja. Kupujący
-- akceptuje konkretną wersję (training_orders.sales_terms_id). Tekst zwykły jak treści szkoleń.
create table organizer_sales_terms (
  id                 uuid primary key default gen_random_uuid(),
  organizer_id       uuid not null references training_organizers(id) on delete restrict,
  version            integer not null check (version > 0),
  status             text not null default 'pending_review'
                       check (status in ('pending_review','active','rejected','retired')),
  seller_legal_name  text not null check (char_length(seller_legal_name) between 2 and 200),
  seller_address     text not null check (char_length(seller_address) between 5 and 200),
  seller_nip         text not null check (seller_nip ~ '^[0-9]{10}$'),
  seller_register    text check (char_length(seller_register) <= 120),          -- KRS albo CEIDG
  seller_email       text not null check (char_length(seller_email) <= 254 and seller_email ~ '^[^@[:space:]<>]+@[^@[:space:]<>]+\.[a-z]{2,}$'),
  seller_phone       text check (seller_phone ~ '^\+?[0-9 ]{9,16}$'),
  cancellation_rules text not null check (char_length(cancellation_rules) between 50 and 4000),
  withdrawal_info    text not null check (char_length(withdrawal_info) between 50 and 4000),
  complaint_info     text not null check (char_length(complaint_info) between 30 and 2000),
  terms_body         text not null check (char_length(terms_body) between 200 and 20000),
  submitted_by       uuid references auth.users(id) on delete set null,
  submitted_at       timestamptz not null default now(),
  reviewed_by        uuid references auth.users(id) on delete set null,
  reviewed_at        timestamptz,
  rejection_reason   text check (char_length(rejection_reason) <= 500),
  unique (organizer_id, version),
  check (concat_ws(' ', seller_legal_name, seller_address, seller_register, cancellation_rules, withdrawal_info,
                   complaint_info, terms_body) !~ '[<>]'),
  check (concat_ws(' ', cancellation_rules, withdrawal_info, complaint_info, terms_body) !~* '(https?://|www\.)'),
  check (status not in ('active','retired','rejected') or (reviewed_by is not null and reviewed_at is not null))
);
create unique index organizer_sales_terms_active_uq on organizer_sales_terms (organizer_id) where status = 'active';
create unique index organizer_sales_terms_pending_uq on organizer_sales_terms (organizer_id) where status = 'pending_review';

-- Zamówienie miejsca na płatnym szkoleniu (jedno zamówienie = jedno miejsce dla zalogowanego uczestnika).
-- Kwota = migawka ceny szkolenia z bazy (nigdy z przeglądarki), prowizja = migawka z platform_fee_settings.
-- Stany (dok. 11 §12a.4): reserved → paid | expired | cancelled; paid → refund_pending → partially_refunded |
-- refunded; expired/cancelled → paid (spóźniona płatność przy wolnym miejscu) albo refund_pending (bez
-- miejsca – zwrot automatyczny). Zmiany statusów zapisuje wyzwalacz audytu (training_orders_status_audit).
-- Bez danych osobowych poza identyfikatorami – dane kupującego i do faktury w training_order_buyer_data.
create table training_orders (
  id                  uuid primary key default gen_random_uuid(),
  order_ref           text not null unique check (order_ref ~ '^SZ-[0-9]{4}-[0-9A-F]{8}$'), -- numer dla ludzi
  idempotency_key     uuid not null,                     -- z formularza (nadany przez serwer przy renderze)
  training_id         uuid not null references trainings(id) on delete restrict,
  organizer_id        uuid not null references training_organizers(id) on delete restrict,
  account_id          uuid references client_accounts(id) on delete set null,
  user_id             uuid references auth.users(id) on delete set null,
  registration_id     uuid references training_registrations(id) on delete set null,
  sales_terms_id      uuid not null references organizer_sales_terms(id) on delete restrict,
  payout_account_id   uuid not null references organizer_payout_accounts(id) on delete restrict,
  provider            text not null check (provider in ('p24','payu','tpay','stripe')),
  buyer_kind          text not null check (buyer_kind in ('osoba','firma')),
  status              text not null default 'reserved'
                        check (status in ('reserved','expired','cancelled','paid','refund_pending',
                                          'partially_refunded','refunded')),
  amount_grosze       integer not null check (amount_grosze between 100 and 10000000),
  currency            text not null default 'PLN' check (currency = 'PLN'),
  platform_fee_bps    smallint not null check (platform_fee_bps between 0 and 3000),
  platform_fee_grosze integer not null check (platform_fee_grosze >= 0),
  refunded_grosze     integer not null default 0 check (refunded_grosze >= 0),
  reserved_until      timestamptz not null,
  paid_at             timestamptz,
  expired_at          timestamptz,
  cancelled_at        timestamptz,
  cancel_requested_at timestamptz,                       -- kupujący prosi o rezygnację; decyzja i zwrot – organizator
  -- prawa konsumenta (dok. 11 §12a.8) [do weryfikacji prawnej]: odstąpienie to jednostronne oświadczenie
  -- kupującego (nie prośba); żądanie rozpoczęcia usługi przed upływem 14 dni – z wersją treści
  withdrawal_declared_at     timestamptz,
  withdrawal_notice_version  text check (char_length(withdrawal_notice_version) between 1 and 40),
  early_start_requested_at   timestamptz,
  early_start_notice_version text check (char_length(early_start_notice_version) between 1 and 40),
  -- faktura na NIP konta salonu (NIP = client_accounts.nip); tylko wtedy zamówienie widzi właściciel salonu
  bill_to_account     boolean not null default false,
  disputed_at         timestamptz,                       -- otwarty spór / obciążenie zwrotne u operatora
  refund_reason       text check (refund_reason in ('rezygnacja','odwolanie','spozniona-platnosc','podwojna-platnosc',
                                                    'inne','odstapienie','chargeback','organizator-zawieszony')),
  invoice_number      text check (char_length(invoice_number) between 1 and 60 and invoice_number !~ '[<>]'),
  invoice_storage_path text check (invoice_storage_path ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}\.pdf$'),
  invoice_sha256      text check (invoice_sha256 ~ '^[0-9a-f]{64}$'),
  invoice_added_at    timestamptz,
  notice_version      text not null check (char_length(notice_version) between 1 and 40), -- informacja o sprzedawcy i danych
  anonymized_at       timestamptz,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  unique (user_id, idempotency_key),
  check (platform_fee_grosze < amount_grosze),
  check (refunded_grosze <= amount_grosze),
  check (status not in ('paid','partially_refunded','refunded') or paid_at is not null),
  check (status <> 'refunded' or refunded_grosze = amount_grosze),
  check (status <> 'partially_refunded' or refunded_grosze between 1 and amount_grosze - 1),
  check ((invoice_storage_path is null) = (invoice_sha256 is null)),
  check (not bill_to_account or buyer_kind = 'firma'),
  check ((withdrawal_declared_at is null) = (withdrawal_notice_version is null)),
  check ((early_start_requested_at is null) = (early_start_notice_version is null))
);
-- jedna aktywna rezerwacja i jedno opłacone miejsce na osobę i szkolenie
create unique index training_orders_reserved_uq on training_orders (training_id, user_id) where status = 'reserved';
create unique index training_orders_paid_uq on training_orders (training_id, user_id)
  where status in ('paid','partially_refunded');
create index training_orders_expiry_idx   on training_orders (reserved_until) where status = 'reserved';
create index training_orders_training_idx on training_orders (training_id, status);
create index training_orders_user_idx     on training_orders (user_id, created_at desc);

-- Dane kupującego: uczestnik (z profilu zweryfikowanego użytkownika) i dane do faktury, którą wystawia
-- ORGANIZATOR (portal faktur nie wystawia). Organizator czyta je wyłącznie funkcją z wpisem w dzienniku
-- (app_organizer_invoice_data); personel – brak polityki (minimalizacja). Usuwane 90 dni po zakończeniu
-- szkolenia [Założenie] – organizator przenosi je do swojej księgowości.
create table training_order_buyer_data (
  order_id          uuid primary key references training_orders(id) on delete cascade,
  user_id           uuid not null references auth.users(id) on delete cascade, -- warunek RLS (bez grantu)
  buyer_kind        text not null check (buyer_kind in ('osoba','firma')),
  buyer_name        text not null check (char_length(buyer_name) between 2 and 200),
  nip               text check (nip ~ '^[0-9]{10}$'),
  street            text check (char_length(street) between 3 and 200),
  postal_code       text check (postal_code ~ '^[0-9]{2}-[0-9]{3}$'),
  city              text check (char_length(city) between 2 and 80),
  invoice_email     text not null check (char_length(invoice_email) <= 254),
  participant_name  text not null check (char_length(participant_name) between 2 and 120),
  participant_email text not null check (char_length(participant_email) <= 254),
  created_at        timestamptz not null default now(),
  check ((buyer_kind = 'firma') = (nip is not null)),
  check (buyer_kind = 'osoba' or (street is not null and postal_code is not null and city is not null)),
  check (concat_ws(' ', buyer_name, street, city, participant_name) !~ '[<>@]')
);

-- Płatności (sesje płatności u operatora). Jedno zamówienie może mieć kilka prób (np. odrzucony BLIK);
-- stan zmienia wyłącznie app_payment_webhook() według tabeli dozwolonych przejść (zdarzenia spóźnione
-- albo w złej kolejności są zapisywane i pomijane).
create table training_payments (
  id                   uuid primary key default gen_random_uuid(),
  order_id             uuid not null references training_orders(id) on delete restrict,
  provider             text not null check (provider in ('p24','payu','tpay','stripe')),
  -- NULL do czasu odpowiedzi createCheckout: wiersz (nasz UUID = id) powstaje PRZED wywołaniem operatora,
  -- a UUID trafia do operatora w metadanych – awaria Workera między createCheckout a zapisem referencji
  -- nie gubi płatności (przegląd red team 13.11.2026)
  provider_payment_ref text check (provider_payment_ref ~ '^[A-Za-z0-9_.:-]{3,200}$'),
  -- druga referencja operatora nadawana przy płatności (Stripe: PaymentIntent albo charge przy sesji Checkout;
  -- P24: orderId przy naszym sessionId) – zwroty i spory przychodzą z nią
  provider_charge_ref  text check (provider_charge_ref ~ '^[A-Za-z0-9_.:-]{3,200}$'),
  attempt              smallint not null check (attempt between 1 and 5),
  status               text not null default 'pending'
                         check (status in ('pending','succeeded','failed','cancelled','expired',
                                           'partially_refunded','refunded','disputed')),
  amount_grosze        integer not null check (amount_grosze > 0),
  currency             text not null default 'PLN' check (currency = 'PLN'),
  method               text check (method in ('blik','karta','przelew','inna')),
  checkout_expires_at  timestamptz,
  checkout_cancel_requested_at timestamptz,          -- Worker wołał cancelCheckout (wygasła albo anulowana rezerwacja)
  succeeded_at         timestamptz,
  last_event_at        timestamptz,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  unique (provider, provider_payment_ref),
  unique (provider, provider_charge_ref),
  unique (order_id, attempt),
  check (status = 'pending' or provider_payment_ref is not null)
);

-- Zwroty: inicjuje organizator (rezygnacja wg jego regulaminu, kwota ≤ pozostałej) albo system
-- (odwołanie szkolenia, spóźniona płatność bez miejsca, podwójna płatność); wykonuje operator.
-- id zwrotu = klucz idempotencji w API operatora. Zwrot wykonany poza portalem (w panelu operatora)
-- zapisuje webhook jako requested_by = 'system:operator'.
create table training_refunds (
  id                  uuid primary key default gen_random_uuid(),
  order_id            uuid not null references training_orders(id) on delete restrict,
  payment_id          uuid not null references training_payments(id) on delete restrict,
  amount_grosze       integer not null check (amount_grosze > 0),
  reason              text not null check (reason in ('rezygnacja','odwolanie','spozniona-platnosc','podwojna-platnosc',
                                                       'inne','odstapienie','organizator-zawieszony')),
  status              text not null default 'requested' check (status in ('requested','submitted','succeeded','failed')),
  provider_refund_ref text unique check (provider_refund_ref ~ '^[A-Za-z0-9_.:-]{3,200}$'),
  requested_by        text not null check (requested_by ~ '^(system(:[a-z0-9_.:-]{1,60})?|user:[0-9a-f-]{36})$'),
  failure_code        text check (char_length(failure_code) <= 60 and failure_code ~ '^[A-Za-z0-9_.:-]*$'),
  created_at          timestamptz not null default now(),
  submitted_at        timestamptz,
  succeeded_at        timestamptz,
  failed_at           timestamptz,
  updated_at          timestamptz not null default now()
);
create index training_payments_order_idx on training_payments (order_id, attempt);
create index training_payments_cancel_idx on training_payments (created_at) where status = 'pending';
create index training_refunds_order_idx on training_refunds (order_id);
create index training_refunds_active_idx on training_refunds (status, created_at) where status in ('requested','submitted');

-- Dziennik zdarzeń od operatora (deduplikacja i ślad). Zapisujemy wyłącznie zdarzenia z poprawnym podpisem
-- (sprawdza Worker przed wywołaniem bazy) i tylko pola znormalizowane + skrót treści – bez surowego JSON
-- (może zawierać e-mail, końcówkę karty). Unikalność (provider, event_id) daje idempotencję także przy
-- równoległych doręczeniach tego samego zdarzenia.
create table payment_webhook_events (
  id             bigint generated always as identity primary key,
  provider       text not null check (provider in ('p24','payu','tpay','stripe')),
  event_id       text not null check (event_id ~ '^[A-Za-z0-9_.:-]{1,200}$'),
  event_type     text not null check (event_type in ('payment.succeeded','payment.failed','payment.cancelled',
                   'payment.expired','refund.succeeded','refund.failed','dispute.opened','dispute.closed')),
  provider_ref   text check (provider_ref ~ '^[A-Za-z0-9_.:-]{1,200}$'),
  order_id       uuid,                                   -- z metadanych zdarzenia – do kontroli krzyżowej
  amount_grosze  integer,
  currency       text check (currency ~ '^[A-Z]{3}$'),
  payload_sha256 text not null check (payload_sha256 ~ '^[0-9a-f]{64}$'),
  source         text not null default 'webhook' check (source in ('webhook','reconciliation')),
  occurred_at    timestamptz,
  received_at    timestamptz not null default now(),
  status         text not null default 'received'
                   -- deferred_out_of_order: zwrot / spór przed potwierdzeniem płatności – Worker odpowiada 409,
                   -- operator ponawia; unknown_ref – tak samo (przegląd red team 13.11.2026)
                   check (status in ('received','processed','ignored_stale','rejected_mismatch','unknown_ref',
                                     'deferred_out_of_order')),
  result         text check (char_length(result) <= 60),
  processed_at   timestamptz,
  unique (provider, event_id)
);
create index payment_webhook_events_received_idx on payment_webhook_events (received_at);

-- Rozbieżności do wyjaśnienia (uzgadnianie z raportami operatora, kontrole spójności, zdarzenia odrzucone).
-- details bez danych osobowych (≤ 2 KB). Jedna otwarta pozycja danego rodzaju na zamówienie albo referencję.
create table payment_discrepancies (
  id           bigint generated always as identity primary key,
  kind         text not null check (kind in ('amount_mismatch','currency_mismatch','order_mismatch',
                 'unknown_payment','paid_not_confirmed','confirmed_not_paid','double_payment',
                 'late_payment_no_seat','refund_failed','refund_stuck','external_refund','seat_counter',
                 'reservation_stuck','cancel_request_stale','dispute','kyb_mismatch','withdrawal_overdue',
                 'payout_destination_changed')),
  provider     text check (provider in ('p24','payu','tpay','stripe')),
  provider_ref text check (provider_ref ~ '^[A-Za-z0-9_.:-]{1,200}$'),
  order_id     uuid references training_orders(id) on delete set null,
  details      jsonb not null default '{}'::jsonb check (pg_column_size(details) <= 2048),
  detected_at  timestamptz not null default now(),
  resolved_at  timestamptz,
  resolved_by  uuid references auth.users(id) on delete set null,
  resolution   text check (char_length(resolution) <= 500 and resolution !~ '[<>]'),
  check ((resolved_at is null) = (resolution is null))
);
create unique index payment_discrepancies_open_uq
  on payment_discrepancies (kind, coalesce(order_id::text, provider_ref, '')) where resolved_at is null;


-- -----------------------------------------------------------------------------------------------------
-- 5. ZGŁOSZENIA NADUŻYĆ – mechanizm zgłaszania i działania (art. 16 DSA [do weryfikacji zakresu]):
--    „Zgłoś nadużycie” przy ogłoszeniu, w e-mailu z formularza, przy szkoleniu, przy ogłoszeniu
--    „Szukam pracy”, w e-mailu z wiadomością pracodawcy i przy profilu pracodawcy (podszywanie się).
--    Zapis przez serwer (Turnstile, limit), kolejka w /panel. details – uzasadnienie zgłoszenia;
--    reporter_email – opcjonalny, tylko do potwierdzenia przyjęcia i decyzji; czyszczony 30 dni po
--    obsłużeniu (app_purge_verification_data).
-- -----------------------------------------------------------------------------------------------------

create table abuse_reports (
  id              bigint generated always as identity primary key,
  target          text not null check (target in ('job_offer','job_relay_message','training','organizer',
                    'candidate_ad','candidate_contact','employer')),
  job_offer_id    uuid references job_offers(id) on delete cascade,
  relay_id        uuid references job_offer_relay_log(id) on delete set null,
  training_id     uuid references trainings(id) on delete cascade,
  organizer_id    uuid references training_organizers(id) on delete cascade,
  candidate_ad_id uuid references candidate_ads(id) on delete cascade,
  candidate_contact_id uuid references candidate_ad_contact_log(id) on delete set null, -- wiadomość salonu zgłoszona przez autora
  reported_account_id  uuid references client_accounts(id) on delete cascade,          -- salon, którego dotyczy zgłoszenie
  reason          text not null check (reason in ('nieaktualne','dyskryminacja','oszustwo','oplata-za-prace',
                    'podszywanie','phishing','spam','nielegalne','niepelnoletnia','inne')),
  -- DSA-13 (art. 16 ust. 2 DSA [do weryfikacji przez prawnika]): uzasadnienie wymagane (≥ 20 znaków)
  -- i oświadczenie zgłaszającego o dobrej wierze; imię i nazwisko oraz e-mail – opcjonalne
  details         text check (char_length(details) between 20 and 1000 and details !~ '[<>]'),
  good_faith      boolean not null check (good_faith),
  reporter_name   text check (char_length(reporter_name) between 2 and 120 and reporter_name !~ '[<>@]'),
  reporter_email  text check (char_length(reporter_email) <= 254
                    and reporter_email ~ '^[^@[:space:]<>]+@[^@[:space:]<>]+\.[a-z]{2,}$'),
  handled_at      timestamptz,
  handled_by      uuid references auth.users(id) on delete set null,
  outcome         text check (outcome in ('uzasadnione','nieuzasadnione')),  -- SEC-06: podstawa wstrzymania wysyłek
  anonymized_at   timestamptz,               -- PRIV-14: details i dane zgłaszającego usunięte 12 miesięcy po obsłużeniu
  created_at      timestamptz not null default now(),
  check (num_nonnulls(job_offer_id, training_id, organizer_id, candidate_ad_id, reported_account_id) >= 1),
  check (details is not null or anonymized_at is not null),
  check (outcome is null or handled_at is not null)
);
create index abuse_reports_account_idx on abuse_reports (reported_account_id, outcome) where reported_account_id is not null;


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
                  'candidate_contact_sent',
                  -- P1
                  'employer_registered','employer_gus_checked','phone_verified','job_seeker_registered',
                  'job_seeker_closed','candidate_ad_submitted','candidate_ad_deleted','promotion_changed',
                  'organizer_plan_set','organizer_plan_cancelled',
                  -- 1.4 (przegląd red team)
                  'account_identity_changed','employer_trusted','employer_trust_revoked','employer_nip_conflict',
                  'job_seeker_suspended','reply_address_verified','organizer_plan_invoice_set',
                  -- 00, D42 (płatności za szkolenia)
                  'training_order_created','training_order_status_changed','training_order_cancel_requested',
                  'training_refund_requested','training_refund_status_changed','payment_event_rejected',
                  'payout_account_created','payout_account_status_changed','sales_terms_submitted',
                  'sales_terms_approved','sales_terms_rejected','platform_fee_changed','organizer_orders_viewed',
                  'organizer_invoice_data_viewed','training_invoice_attached','payment_discrepancy_resolved',
                  'training_orders_purged',
                  -- przegląd red team płatności (13.11.2026)
                  'payout_account_link_created','payout_destination_changed','payout_account_kyb_mismatch',
                  'organizer_owner_mfa_reset','training_order_withdrawal_declared','training_dispute_closed',
                  'organizer_suspended_orders_closed')),
  entity        text not null check (entity in ('account','member','invitation','policy','document','claim',
                  'job_offer','training','training_registration','organizer','organizer_member',
                  'feature_flag','candidate_ad','job_seeker','phone','promotion','organizer_plan',
                  'reply_address',
                  -- 00, D42
                  'training_order','training_refund','payment','payout_account','sales_terms','platform_fee')),
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
--  * właściciel (salonu i konta pracodawcy) – zawsze sesja aal2 (TOTP obowiązkowy dla właścicieli –
--    decyzja zleceniodawcy; dla właścicieli kont pracodawców – Założenie Z-27);
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

-- Zweryfikowani pracodawcy wywołującego (P1b): konto aktywne (salon z polisą albo pracodawca z rejestracji),
-- aktywny NIP potwierdzony w GUS nie dawniej niż 120 dni temu [Założenie: ponowne sprawdzenie co 90 dni
-- – cron], wywołujący jest właścicielem w sesji aal2 (TOTP – jak dla właścicieli salonów) i ma telefon
-- potwierdzony SMS. Poziom 1 zaufania (SEC-02): daje wyłącznie tworzenie ofert „Dam pracę” (szkice
-- i wysłanie do moderacji). Odczyt „Szukam pracy” i wiadomości do autorów wymagają dodatkowo poziomu 2
-- (kind = 'client' albo employer_trusted_at) i idą wyłącznie przez funkcje service_role (SEC-01).
-- Ten sam wzorzec: bez parametrów, search_path = '', zwraca tylko identyfikatory, EXECUTE tylko authenticated.
create or replace function public.employer_account_ids()
returns setof uuid
language sql stable security definer set search_path = '' as $$
  select m.account_id
  from public.client_members m
  join public.client_accounts a on a.id = m.account_id
  where m.user_id = (select auth.uid())
    and m.status = 'active'
    and m.role = 'owner'
    and a.status = 'active'
    and a.employer_verified_at > now() - interval '120 days'
    and coalesce((select auth.jwt()) ->> 'aal', 'aal1') = 'aal2'
    and exists (select 1 from public.user_phones p where p.user_id = (select auth.uid()));
$$;
revoke all     on function public.employer_account_ids() from public, anon;
grant  execute on function public.employer_account_ids() to authenticated;

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
create trigger user_phones_guard
  before insert or update or delete on user_phones
  for each row execute function public.backend_only_guard();
create trigger phone_verifications_guard
  before insert or update or delete on phone_verifications
  for each row execute function public.backend_only_guard();
create trigger employer_verifications_guard
  before insert or update or delete on employer_verifications
  for each row execute function public.backend_only_guard();
create trigger job_seekers_guard
  before insert or update or delete on job_seekers
  for each row execute function public.backend_only_guard();
create trigger app_settings_guard
  before insert or update or delete on app_settings
  for each row execute function public.backend_only_guard();
create trigger app_promotions_guard
  before insert or update or delete on app_promotions
  for each row execute function public.backend_only_guard();
create trigger organizer_plans_guard
  before insert or update or delete on organizer_plans
  for each row execute function public.backend_only_guard();
create trigger sms_send_log_guard
  before insert or update or delete on sms_send_log
  for each row execute function public.backend_only_guard();
create trigger employer_reply_addresses_guard
  before insert or update or delete on employer_reply_addresses
  for each row execute function public.backend_only_guard();
create trigger candidate_ad_hidden_nips_guard
  before insert or update or delete on candidate_ad_hidden_nips
  for each row execute function public.backend_only_guard();
create trigger candidate_blocks_guard
  before insert or update or delete on candidate_blocks
  for each row execute function public.backend_only_guard();
create trigger candidate_ad_views_daily_guard
  before insert or update or delete on candidate_ad_views_daily
  for each row execute function public.backend_only_guard();
-- 00, D42: tabele płatności – zapis wyłącznie funkcjami service_role
create trigger platform_fee_settings_guard
  before insert or update or delete on platform_fee_settings
  for each row execute function public.backend_only_guard();
create trigger organizer_payout_accounts_guard
  before insert or update or delete on organizer_payout_accounts
  for each row execute function public.backend_only_guard();
create trigger organizer_sales_terms_guard
  before insert or update or delete on organizer_sales_terms
  for each row execute function public.backend_only_guard();
create trigger training_orders_guard
  before insert or update or delete on training_orders
  for each row execute function public.backend_only_guard();
create trigger training_order_buyer_data_guard
  before insert or update or delete on training_order_buyer_data
  for each row execute function public.backend_only_guard();
create trigger training_payments_guard
  before insert or update or delete on training_payments
  for each row execute function public.backend_only_guard();
create trigger training_refunds_guard
  before insert or update or delete on training_refunds
  for each row execute function public.backend_only_guard();
create trigger payment_webhook_events_guard
  before insert or update or delete on payment_webhook_events
  for each row execute function public.backend_only_guard();
create trigger payment_discrepancies_guard
  before insert or update or delete on payment_discrepancies
  for each row execute function public.backend_only_guard();

-- 00, D42: każda zmiana statusu zamówienia trafia do dziennika (kto: app.audit_actor ustawiany przez funkcje
-- – user:/staff:/system:webhook:<operator>/system:cron), bez danych osobowych w payload.
create or replace function public.training_orders_status_audit() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.status is distinct from old.status then
    insert into public.client_audit_log (account_id, organizer_id, actor, action, entity, entity_id, payload)
    values (new.account_id, new.organizer_id,
            coalesce(nullif(current_setting('app.audit_actor', true), ''), 'system:payments'),
            'training_order_status_changed', 'training_order', new.id,
            jsonb_build_object('from', old.status, 'to', new.status, 'reason', new.refund_reason));
  end if;
  return null;
end $$;
revoke all on function public.training_orders_status_audit() from public, anon, authenticated;
create trigger training_orders_status_audit
  after update of status on training_orders
  for each row execute function public.training_orders_status_audit();

-- SEC-16: tożsamość konta. Zmiana NIP (także przez personel w /panel) zeruje weryfikację GUS i poziom 2
-- zaufania – weryfikacja nie „przechodzi” na inny NIP; serwer wymusza nowe sprawdzenie w GUS. U pracodawcy
-- z rejestracji nazwę prawną ustawia wyłącznie app_employer_record_gus() (z GUS). Zmiana nazwy
-- wyświetlanej cofa jej akceptację (ponowna moderacja przed użyciem w e-mailu – SEC-02), chyba że zmienia
-- ją funkcja serwera. Wpis account_identity_changed dodaje wyzwalacz audytu (bez wartości pól).
create or replace function public.client_accounts_identity_guard() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.nip is distinct from old.nip then
    new.employer_verified_at  := null;
    new.employer_trusted_at   := null;
    new.employer_trust_method := null;
    new.employer_trusted_by   := null;
  end if;
  if current_user not in ('service_role', 'postgres', 'supabase_admin') then
    if new.kind = 'employer' and new.legal_name is distinct from old.legal_name then
      raise exception 'client_accounts: nazwę prawną pracodawcy ustawia wyłącznie sprawdzenie w GUS';
    end if;
    if new.display_name is distinct from old.display_name then
      new.display_name_approved_at := null;
    end if;
    -- kolumny zaufania (employer_trusted_*, display_name_approved_at) nie mają grantu UPDATE dla
    -- authenticated – ustawia je wyłącznie app_employer_trust() i moderacja
  end if;
  return new;
end $$;
revoke all on function public.client_accounts_identity_guard() from public, anon, authenticated;
create trigger client_accounts_identity_guard
  before update on client_accounts
  for each row execute function public.client_accounts_identity_guard();

-- Rozdział personelu i klientów działa w obie strony: konto z aktywnym członkostwem w salonie, u pracodawcy
-- albo u organizatora lub konto osoby szukającej pracy nie może dostać wpisu w admin_users (odwrotny
-- kierunek sprawdzają app_accept_*, app_employer_register i app_job_seeker_register).
create or replace function public.staff_client_disjoint_guard() returns trigger
language plpgsql set search_path = '' as $$
begin
  if exists (select 1 from public.client_members m where m.user_id = new.user_id and m.status = 'active')
     or exists (select 1 from public.organizer_members om where om.user_id = new.user_id and om.status = 'active')
     or exists (select 1 from public.job_seekers s where s.user_id = new.user_id) then
    raise exception 'admin_users: konto klienta, pracodawcy, organizatora lub osoby szukającej pracy nie może być kontem personelu';
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
  v_old_zab text[] := case when tg_op = 'UPDATE' then old.zabiegi else '{}'::text[] end;
begin
  if current_user in ('service_role', 'postgres', 'supabase_admin') then
    return new;
  end if;

  -- Zabiegi (00, D41): tylko identyfikatory z listy, bez pustych i powtórzeń, najwyżej 30; nowo dodane – tylko
  -- aktywne (wycofana pozycja zostaje w ogłoszeniu, które już ją ma). Błąd BP422 z nazwą pola, bez wartości
  -- (zanim CHECK zwróci w DETAIL cały wiersz). Zapis znormalizowany: posortowane identyfikatory.
  if new.zabiegi is distinct from v_old_zab then
    if new.zabiegi is null or array_position(new.zabiegi, null) is not null
       or not (new.zabiegi <@ public.zabiegi_ids())
       or exists (select 1 from unnest(new.zabiegi) z
                   where z <> all (v_old_zab) and z <> all (public.zabiegi_ids(true)))
       or (select count(distinct z) from unnest(new.zabiegi) z) > 30 then
      raise exception 'job_offers: nieprawidłowe pole zabiegi' using errcode = 'BP422';
    end if;
    new.zabiegi := array(select distinct z from unnest(new.zabiegi) z order by z);
  end if;

  -- SEC-18: limit szkiców liczony pod blokadą konta – równoległe żądania nie przekroczą limitu
  perform pg_advisory_xact_lock(hashtext('jo:' || new.account_id::text));
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
                new.description, new.requirements, new.benefits, new.zabiegi)
               is distinct from
               (old.title, old.profession, old.employment_type, old.working_time, old.city, old.voivodeship,
                old.postal_code, old.salary_min, old.salary_max, old.salary_unit, old.salary_basis,
                old.description, old.requirements, old.benefits, old.zabiegi);   -- zabiegi = treść (00, D41)
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
    new.seats_held       := 0;
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
                new.price_gross_pln, new.payment_mode)
               is distinct from
               (old.title, old.summary, old.description, old.format, old.city, old.venue_name, old.starts_at,
                old.ends_at, old.registration_closes_at, old.audience, old.per_account_limit, old.price_kind,
                old.price_gross_pln, old.payment_mode);
  -- 00, D42: ceny i sposobu płatności nie zmienia się przy otwartych rezerwacjach (seats_held), a sposobu
  -- płatności szkolenia „online” – także przy zapisanych (opłacone zamówienia; zmiana trybu odcięłaby zwroty).
  -- Liczniki z wiersza szkolenia, nie z training_orders: guard działa z uprawnieniami organizatora,
  -- a organizator nie ma polityki odczytu zamówień (RLS zwróciłby 0 wierszy).
  if (new.price_kind, new.price_gross_pln, new.payment_mode) is distinct from
     (old.price_kind, old.price_gross_pln, old.payment_mode)
     and (old.seats_held > 0
          or (old.payment_mode = 'online' and new.payment_mode is distinct from old.payment_mode
              and old.seats_registered > 0)) then
    raise exception 'trainings: szkolenie ma rezerwacje albo opłacone zamówienia – zmiana ceny lub sposobu płatności niemożliwa';
  end if;
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
      when (new.nip, new.legal_name, new.display_name) is distinct from (old.nip, old.legal_name, old.display_name)
        then 'account_identity_changed'                  -- SEC-16: które pola, bez wartości
      else null end;
    if v_action is not null then
      insert into public.client_audit_log (account_id, actor, action, entity, entity_id, payload)
      values (new.id, v_actor, v_action, 'account', new.id,
              case when v_action = 'account_identity_changed' and tg_op = 'UPDATE'
                   then jsonb_build_object('nip', new.nip is distinct from old.nip,
                                           'legal_name', new.legal_name is distinct from old.legal_name,
                                           'display_name', new.display_name is distinct from old.display_name)
                   else jsonb_build_object('status', new.status) end);
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
alter table user_phones                   enable row level security;
alter table phone_verifications           enable row level security;  -- bez polityk: service_role_only
alter table employer_verifications        enable row level security;
alter table job_seekers                   enable row level security;
alter table app_settings                  enable row level security;
alter table app_promotions                enable row level security;
alter table organizer_plans               enable row level security;
alter table sms_send_log                  enable row level security;  -- bez polityk: service_role_only
alter table employer_reply_addresses      enable row level security;
alter table candidate_ad_hidden_nips      enable row level security;
alter table candidate_blocks              enable row level security;  -- bez polityk: service_role_only
alter table candidate_ad_views_daily      enable row level security;  -- bez polityk: service_role_only
-- 00, D42: płatności za szkolenia
alter table platform_fee_settings         enable row level security;
alter table organizer_payout_accounts     enable row level security;
alter table organizer_sales_terms         enable row level security;
alter table training_orders               enable row level security;
alter table training_order_buyer_data     enable row level security;
alter table training_payments             enable row level security;
alter table training_refunds              enable row level security;
alter table payment_webhook_events        enable row level security;
alter table payment_discrepancies         enable row level security;

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
alter table user_phones                   force row level security;
alter table phone_verifications           force row level security;
alter table employer_verifications        force row level security;
alter table job_seekers                   force row level security;
alter table sms_send_log                  force row level security;
alter table employer_reply_addresses      force row level security;
alter table candidate_ad_hidden_nips      force row level security;
alter table candidate_blocks              force row level security;
alter table organizer_payout_accounts     force row level security;
alter table training_orders               force row level security;
alter table training_order_buyer_data     force row level security;
alter table training_payments             force row level security;
alter table training_refunds              force row level security;
alter table payment_webhook_events        force row level security;

revoke all on client_accounts, client_members, client_invitations, client_policies, client_policy_notes,
              client_policy_documents, client_policy_reminders, job_offers, job_offer_contacts,
              job_offer_relay_log, training_organizers, organizer_members, organizer_invitations, trainings,
              training_private_details, training_registrations, training_participant_contacts, abuse_reports,
              client_audit_log, app_feature_flags, candidate_ads, candidate_ad_contact_log,
              user_phones, phone_verifications, employer_verifications, job_seekers, app_settings,
              app_promotions, organizer_plans, sms_send_log, employer_reply_addresses,
              candidate_ad_hidden_nips, candidate_blocks, candidate_ad_views_daily,
              platform_fee_settings, organizer_payout_accounts, organizer_sales_terms, training_orders,
              training_order_buyer_data, training_payments, training_refunds, payment_webhook_events,
              payment_discrepancies
  from public, anon, authenticated;

-- SEC-01 (Data API): klucz publishable nie jest sekretem, a token z ciasteczka sesji użytkownik może
-- skopiować i wołać PostgREST bez aplikacji. Dlatego (1) tabele czytane hurtem, w których stronicowanie,
-- kwota albo dziennik są warunkiem bezpieczeństwa („Szukam pracy”, dane uczestników szkoleń), nie mają
-- polityki odczytu dla klientów – czytają je wyłącznie funkcje service_role; (2) w ustawieniach Data API
-- projektu: max_rows = 100 [Założenie] i wystawione tylko schematy potrzebne aplikacji (Z3: tabele strefy
-- w osobnym, niewystawionym schemacie) [do weryfikacji w PoC].

-- Uwaga: uprawnienia kolumnowe dotyczą CAŁEJ roli authenticated (salony, organizatorzy, personel).
-- Kolumny wewnętrzne (crm_tenant, crm_ref, source_lead_id, *_by, moderation_note, account_id organizatora) personel
-- czyta w /panel serwerowo (service_role po sprawdzeniu app_is_staff w sesji aal2), nie przez grant.

-- 8.1 Konta salonów -------------------------------------------------------------------------------
grant select (id, kind, display_name, legal_name, nip, city, status, employer_verified_at, employer_trusted_at,
              display_name_approved_at, team_confirmed_at, activated_at, suspended_at, closed_at, created_at, updated_at)
  on client_accounts to authenticated;
grant insert (display_name, legal_name, nip, city, crm_tenant, crm_ref, source_lead_id, created_by),
      update (display_name, legal_name, nip, city, crm_tenant, crm_ref, status, suspended_at, closed_at, updated_at)
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
              benefits, zabiegi, employer_name, published_at, expires_at)
  on job_offers to anon;
create policy job_offers_public_read on job_offers
  for select to anon
  using (status = 'published' and expires_at > now());

grant select (id, account_id, slug, status, content_version, title, profession, employment_type, working_time,
              city, voivodeship, postal_code, salary_min, salary_max, salary_unit, salary_basis, description,
              requirements, benefits, zabiegi, employer_name, submitted_at, published_at, expires_at,
              rejection_reason, closed_at, created_at, updated_at)
  on job_offers to authenticated;               -- bez moderation_note, moderated_by i created_by
grant insert (account_id, status, title, profession, employment_type, working_time, city, voivodeship,
              postal_code, salary_min, salary_max, salary_unit, salary_basis, description, requirements, benefits,
              zabiegi),
      update (status, title, profession, employment_type, working_time, city, voivodeship, postal_code,
              salary_min, salary_max, salary_unit, salary_basis, description, requirements, benefits, zabiegi)
  on job_offers to authenticated;               -- slug i content_version ustawia guard

create policy job_offers_public_read_auth on job_offers   -- zalogowani widzą tablicę jak wszyscy
  for select to authenticated
  using (status = 'published' and expires_at > now());
create policy job_offers_member_read on job_offers        -- właściciel i pracownicy: ogłoszenia swojego salonu
  for select to authenticated
  using (account_id in (select public.client_account_ids()));
-- Nowe ogłoszenie: tylko pracodawca z poziomem 1 (P1b – NIP w GUS, telefon SMS, TOTP) – także salon
-- z polisą. Edycja, wycofanie i zamknięcie: każdy właściciel (moderacja i tak wymaga ważnej weryfikacji).
create policy job_offers_owner_insert on job_offers
  for insert to authenticated
  with check (account_id in (select public.employer_account_ids()));
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

-- 8.4a „Szukam pracy” (P1a – aktywne od startu, za przełącznikiem) ----------------------------------------
-- Przełącznik: authenticated czyta tylko (key, enabled) – potrzebne w politykach niżej (podzapytanie
-- bez korelacji = initPlan, liczony raz na zapytanie). anon – nic.
grant select (key, enabled) on app_feature_flags to authenticated;
create policy app_feature_flags_read on app_feature_flags
  for select to authenticated using (true);

-- Ogłoszenia „Szukam pracy”: anon – BRAK grantu (nigdy publiczne). authenticated – tylko kolumny
-- ogłoszenia; bez seeker_id (identyfikator konta osoby), moderated_by i moderation_note.
-- Odczyt przez Data API:
--  * autor – własne ogłoszenie w każdym statusie, także przy wyłączonym przełączniku (podgląd, usunięcie);
--  * personel – kolejka moderacji przy włączonym przełączniku.
-- Pracodawcy – BRAK polityki (SEC-01): karty zwraca tylko app_candidate_ads_page() (service_role) –
-- 20 na stronę, od najnowszej publikacji, z dzienną kwotą i alertem, bez rankingu i dopasowywania (D-C).
grant select (id, status, content_version, first_name, profession, city, voivodeship, cooperation_forms,
              experience, available_from, description, zabiegi, submitted_at, published_at, expires_at,
              rejection_reason)
  on candidate_ads to authenticated;
create policy candidate_ads_author_read on candidate_ads
  for select to authenticated
  using (seeker_id = (select auth.uid()));
create policy candidate_ads_staff_read on candidate_ads     -- kolejka moderacji, tylko przy włączonym przełączniku
  for select to authenticated
  using (exists (select 1 from public.app_feature_flags f where f.key = 'szukam_pracy' and f.enabled)
         and app_is_staff());
-- brak INSERT/UPDATE/DELETE dla authenticated: zapis wyłącznie funkcjami app_candidate_* (service_role)
-- candidate_ad_contact_log, candidate_blocks, candidate_ad_views_daily: bez grantów i polityk (service_role_only)

-- lista firm ukrytych przez autora (PRIV-07): autor czyta własną listę; zapis – funkcja
grant select (nip, created_at) on candidate_ad_hidden_nips to authenticated;
create policy candidate_ad_hidden_nips_self_read on candidate_ad_hidden_nips
  for select to authenticated using (seeker_id = (select auth.uid()));

-- potwierdzone adresy pracodawcy (SEC-05): właściciel konta widzi listę i stan potwierdzenia; personel
grant select (account_id, email_normalized, verified_at, created_at) on employer_reply_addresses to authenticated;
create policy employer_reply_addresses_owner_read on employer_reply_addresses
  for select to authenticated using (account_id in (select public.client_account_ids('owner')));
create policy employer_reply_addresses_staff_read on employer_reply_addresses
  for select to authenticated using (app_is_staff());

-- 8.4b Konta P1: osoby szukające pracy, telefony, weryfikacje GUS, ustawienia, promocja -----------------
grant select (user_id, status, adult_confirmed, terms_version, notice_version, created_at)
  on job_seekers to authenticated;
create policy job_seekers_self_read on job_seekers
  for select to authenticated using (user_id = (select auth.uid()));
create policy job_seekers_staff_read on job_seekers
  for select to authenticated using (app_is_staff());

-- telefon: osoba widzi tylko końcówkę własnego numeru i datę weryfikacji; HMAC numeru – bez grantu
grant select (user_id, phone_last3, verified_at) on user_phones to authenticated;
create policy user_phones_self_read on user_phones
  for select to authenticated using (user_id = (select auth.uid()));
-- phone_verifications, sms_send_log: bez grantów i polityk (service_role_only; kody i numery tylko jako HMAC)

-- weryfikacje NIP: właściciel konta (wynik i dane z rejestru do prewypełnienia), personel
grant select (id, account_id, nip, source, result, regon, entity_type, legal_name, city, postal_code, checked_at)
  on employer_verifications to authenticated;
create policy employer_verifications_owner_read on employer_verifications
  for select to authenticated using (account_id in (select public.client_account_ids('owner')));
create policy employer_verifications_staff_read on employer_verifications
  for select to authenticated using (app_is_staff());

grant select on app_settings to authenticated;
create policy app_settings_staff_read on app_settings
  for select to authenticated using (app_is_staff());
grant select (key, enabled, starts_at, ends_at, free_ads, ad_days, organizer_12m_net_pln, organizer_1m_net_pln,
              decision_ref, changed_at)
  on app_promotions to authenticated;
create policy app_promotions_staff_read on app_promotions
  for select to authenticated using (app_is_staff());
-- strony publiczne pokazują warunki promocji z odczytu serwerowego (service_role) w cache – anon bez grantu

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

-- Plany organizatora (P1d): organizator widzi własne (ważność, cena netto, numer faktury), personel – wszystkie;
-- zapis wyłącznie app_set_organizer_plan()/app_cancel_organizer_plan() (service_role)
grant select (id, organizer_id, plan_code, price_net_pln, valid_from, valid_until, status, invoice_ref,
              cancelled_at, created_at)
  on organizer_plans to authenticated;
create policy organizer_plans_org_read on organizer_plans
  for select to authenticated using (organizer_id in (select public.organizer_ids()));
create policy organizer_plans_staff_read on organizer_plans
  for select to authenticated using (app_is_staff());

-- 8.6 Szkolenia -----------------------------------------------------------------------------------------
grant select (id, organizer_id, slug, status, title, summary, description, format, city, venue_name, starts_at,
              ends_at, registration_closes_at, capacity, seats_registered, seats_held, audience, price_kind,
              price_gross_pln, payment_mode, published_at, cancelled_at)
  on trainings to anon, authenticated;          -- wolne miejsca = capacity − seats_registered − seats_held
grant select (per_account_limit, content_version, submitted_at, rejection_reason, created_at, updated_at)
  on trainings to authenticated;                -- bez moderation_note, moderated_by, created_by
-- status w grancie, ale guard dopuszcza tylko draft ↔ pending_review (i published → pending_review);
-- published_at, capacity (po utworzeniu), seats_registered, seats_held, slug i kolumny moderacji – bez grantu
grant insert (organizer_id, status, title, summary, description, format, city, venue_name, starts_at, ends_at,
              registration_closes_at, capacity, per_account_limit, audience, price_kind, price_gross_pln,
              payment_mode),
      update (status, title, summary, description, format, city, venue_name, starts_at, ends_at,
              registration_closes_at, per_account_limit, audience, price_kind, price_gross_pln, payment_mode)
  on trainings to authenticated;

-- Katalog: tylko opublikowane (i odwołane – informacja dla zapisanych) szkolenia organizatorów z aktywnym
-- planem (P1d). plan_valid_until nie ma grantu – warunek polityki na własnej tabeli go nie wymaga.
create policy trainings_public_read on trainings
  for select to anon
  using (status in ('published','cancelled') and published_at is not null and plan_valid_until > now());
create policy trainings_public_read_auth on trainings
  for select to authenticated
  using (status in ('published','cancelled') and published_at is not null and plan_valid_until > now());
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

-- training_participant_contacts: bez grantów i polityk dla authenticated (SEC-01 – przegląd tabel czytanych
-- hurtem). Organizator dostaje listę wyłącznie funkcją app_training_participants() (service_role), która
-- zawsze zapisuje wgląd albo eksport w dzienniku – bezpośredni odczyt przez Data API omijałby dziennik.
-- Personel: brak dostępu (minimalizacja); obsługa nadużyć kluczem serwisowym z wpisem w dzienniku.

-- 8.6a Płatności za szkolenia (00, D42) -----------------------------------------------------------------
-- Zapis wyłącznie funkcjami service_role (backend_only_guard). Odczyt:
--  * uczestnik – własne zamówienia i własne dane do faktury; właściciel salonu – zamówienia „na firmę”
--    swojego salonu (statusy i kwoty, bez danych kupującego);
--  * organizator – BEZ polityk na zamówieniach i danych kupujących (SEC-01): lista zamówień swoich szkoleń
--    i dane do faktury tylko funkcjami app_organizer_training_orders() / app_organizer_invoice_data()
--    z wpisem w dzienniku; swój stan „Wypłat” i swoje warunki sprzedaży – przez RLS;
--  * personel – audyt: zamówienia (bez danych kupującego), płatności, zwroty, zdarzenia operatora,
--    rozbieżności, konta wypłat (bez identyfikatora konta u operatora), stawki prowizji.
grant select (id, valid_from, fee_bps, fee_fixed_grosze, decision_ref, created_at) on platform_fee_settings to authenticated;
create policy platform_fee_settings_org_read on platform_fee_settings      -- organizator widzi stawkę prowizji
  for select to authenticated using (exists (select 1 from public.organizer_ids()));
create policy platform_fee_settings_staff_read on platform_fee_settings
  for select to authenticated using (app_is_staff());

grant select (id, organizer_id, provider, status, charges_enabled, payouts_enabled, requirements_due,
              status_checked_at, activated_at, usable_from, payout_destination_changed_at, kyb_tax_id_match,
              created_at, updated_at)
  on organizer_payout_accounts to authenticated;  -- bez provider_account_ref
create policy organizer_payout_accounts_org_read on organizer_payout_accounts
  for select to authenticated using (organizer_id in (select public.organizer_ids()));
create policy organizer_payout_accounts_staff_read on organizer_payout_accounts
  for select to authenticated using (app_is_staff());

-- Warunki sprzedaży: aktywna wersja jest publiczna (informacje przedkontraktowe i dane sprzedawcy –
-- DSA art. 30 ust. 7: nazwa, adres, telefon, e-mail, rejestr); organizator widzi wszystkie swoje wersje.
grant select (id, organizer_id, version, status, seller_legal_name, seller_address, seller_nip, seller_register,
              seller_email, seller_phone, cancellation_rules, withdrawal_info, complaint_info, terms_body, reviewed_at)
  on organizer_sales_terms to anon, authenticated;
grant select (submitted_at, rejection_reason) on organizer_sales_terms to authenticated;
create policy organizer_sales_terms_public_read on organizer_sales_terms
  for select to anon using (status = 'active');
create policy organizer_sales_terms_public_read_auth on organizer_sales_terms
  for select to authenticated using (status = 'active');
create policy organizer_sales_terms_org_read on organizer_sales_terms
  for select to authenticated using (organizer_id in (select public.organizer_ids()));
create policy organizer_sales_terms_staff_read on organizer_sales_terms
  for select to authenticated using (app_is_staff());

grant select (id, order_ref, training_id, organizer_id, account_id, buyer_kind, status, amount_grosze, currency,
              refunded_grosze, reserved_until, paid_at, expired_at, cancelled_at, cancel_requested_at, refund_reason,
              withdrawal_declared_at, early_start_requested_at, bill_to_account, disputed_at,
              invoice_number, invoice_added_at, created_at, updated_at)
  on training_orders to authenticated;            -- bez user_id, idempotency_key, kont operatora i ścieżki pliku
create policy training_orders_self_read on training_orders
  for select to authenticated using (user_id = (select auth.uid()));
-- Właściciel salonu widzi tylko zamówienia z fakturą na NIP SALONU (bill_to_account; NIP = client_accounts.nip,
-- ustawia app_training_order_create). Zakup pracownika na własną działalność (inny NIP) jest prywatny
-- (przegląd red team 13.11.2026).
create policy training_orders_owner_read on training_orders
  for select to authenticated
  using (bill_to_account and account_id in (select public.client_account_ids('owner')));
create policy training_orders_staff_read on training_orders
  for select to authenticated using (app_is_staff());

grant select (order_id, buyer_kind, buyer_name, nip, street, postal_code, city, invoice_email, participant_name,
              participant_email)
  on training_order_buyer_data to authenticated;
create policy training_order_buyer_data_self_read on training_order_buyer_data
  for select to authenticated using (user_id = (select auth.uid()));

grant select (id, order_id, provider, provider_payment_ref, provider_charge_ref, attempt, status, amount_grosze,
              currency, method, checkout_expires_at, checkout_cancel_requested_at, succeeded_at, last_event_at,
              created_at, updated_at)
  on training_payments to authenticated;
create policy training_payments_staff_read on training_payments
  for select to authenticated using (app_is_staff());
grant select (id, order_id, payment_id, amount_grosze, reason, status, provider_refund_ref, requested_by,
              failure_code, created_at, submitted_at, succeeded_at, failed_at)
  on training_refunds to authenticated;
create policy training_refunds_staff_read on training_refunds
  for select to authenticated using (app_is_staff());
grant select (id, provider, event_id, event_type, provider_ref, order_id, amount_grosze, currency, source,
              occurred_at, received_at, status, result, processed_at)
  on payment_webhook_events to authenticated;
create policy payment_webhook_events_staff_read on payment_webhook_events
  for select to authenticated using (app_is_staff('admin','agent'));
grant select on payment_discrepancies to authenticated;
create policy payment_discrepancies_staff_read on payment_discrepancies
  for select to authenticated using (app_is_staff());

-- 8.7 Zgłoszenia nadużyć: zapis przez serwer; personel czyta i oznacza obsłużone -------------------------
grant select (id, target, job_offer_id, relay_id, training_id, organizer_id, candidate_ad_id, candidate_contact_id,
              reported_account_id, reason, details, good_faith, reporter_name, reporter_email, handled_at,
              handled_by, outcome, anonymized_at, created_at),
      update (handled_at, handled_by, outcome)
  on abuse_reports to authenticated;
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

-- 00, D42: faktury od organizatorów (opcjonalnie – portal faktur nie wystawia). Prywatny kubełek, tylko PDF,
-- ścieżka {organizer_id}/{order_id}/{uuid}.pdf nadawana przez serwer. Bez polityk dla authenticated:
-- wgrywa serwer po sprawdzeniu organizatora (app_training_order_invoice_attach), podpisany URL (60 s)
-- serwer tworzy po app_training_invoice_path(). Plik usuwa serwer przy anonimizacji zamówienia (retencja).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('training-invoices', 'training-invoices', false, 5242880, array['application/pdf'])
on conflict (id) do update
  set public = false, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;


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
   where id = p_account and kind = 'client' and status in ('pending','suspended');
  if not found then
    raise exception 'activate: konto nie istnieje, jest kontem pracodawcy albo jest zamknięte/aktywne';
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
                                             and a.kind = 'client'  -- [Założenie P1] konto pracodawcy w MVP bez zespołu
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
--      w trakcie przeglądu (wyjątek, moderator odświeża podgląd). Każde konto (salon z polisą albo
--      pracodawca z rejestracji – P1b): publikacja wymaga aktywnego NIP potwierdzonego w GUS nie dawniej
--      niż 120 dni temu (inaczej serwer najpierw ponawia sprawdzenie – app_employer_record_gus).
--      Długość publikacji z aktywnej promocji (P1c: 21 dni); bez aktywnej promocji – BP409.
create or replace function public.app_moderate_job_offer(
  p_offer uuid, p_actor uuid, p_decision text, p_expected_version integer,
  p_note text default null, p_reason text default null)
returns void
language plpgsql set search_path = '' as $$
declare
  v_offer public.job_offers%rowtype;
  v_days  smallint;
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
    -- SEC-05: adres rekrutacyjny (formularz albo e-mail) musi być potwierdzonym adresem konta
    if exists (select 1 from public.job_offer_contacts c
                where c.offer_id = p_offer and c.method in ('formularz','email')
                  and not exists (select 1 from public.employer_reply_addresses r
                                   where r.account_id = v_offer.account_id
                                     and r.email_normalized = lower(c.email) and r.verified_at is not null)) then
      raise exception 'moderate: adres kontaktowy ogłoszenia nie jest potwierdzony';
    end if;
    if not exists (select 1 from public.client_accounts a
                    where a.id = v_offer.account_id and a.status = 'active'
                      and a.employer_verified_at > now() - interval '120 days') then
      raise exception 'moderate: NIP pracodawcy wymaga ponownego sprawdzenia w GUS albo konto jest nieaktywne';
    end if;
    v_days := public.promo_ad_days();                 -- P1c: 21 dni w promocji; bez promocji – BP409
    update public.job_offers
       set status = 'published',
           published_at = coalesce(published_at, now()),   -- ponowna moderacja nie przedłuża ważności
           expires_at = coalesce(least(expires_at, coalesce(published_at, now()) + make_interval(days => v_days)),
                                 coalesce(published_at, now()) + make_interval(days => v_days)),
           employer_name = (select a.display_name from public.client_accounts a where a.id = v_offer.account_id),
           moderated_by = p_actor, moderation_note = p_note, rejection_reason = null, updated_at = now()
     where id = p_offer;
    -- nazwa wyświetlana sprawdzona z listą kontrolną 11.2 (zgodność z rejestrem) – może trafiać do e-maili
    update public.client_accounts set display_name_approved_at = coalesce(display_name_approved_at, now())
     where id = v_offer.account_id;
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
  select o.* into v_offer from public.job_offers o
    join public.client_accounts a on a.id = o.account_id and a.status = 'active'   -- SEC-08: konto aktywne
   where o.slug = p_offer_slug and o.status = 'published' and o.expires_at > now();
  if not found then
    raise exception 'relay: ogłoszenie niedostępne';
  end if;
  select * into v_contact from public.job_offer_contacts where offer_id = v_offer.id and method = 'formularz';
  if not found then
    raise exception 'relay: salon nie przyjmuje wiadomości przez formularz';
  end if;
  -- SEC-05: wysyłka tylko na potwierdzony adres konta (nie na cudzą skrzynkę wpisaną w ofercie)
  if not exists (select 1 from public.employer_reply_addresses r
                  where r.account_id = v_offer.account_id and r.email_normalized = lower(v_contact.email)
                    and r.verified_at is not null) then
    raise exception 'relay: ogłoszenie niedostępne';
  end if;
  -- walidacja bez wartości w komunikacie (PRIV-12); SEC-19: bez adresów URL i znaczników także w bazie
  if char_length(coalesce(p_payload->>'message', '')) not between 1 and 1000
     or char_length(coalesce(p_payload->>'sender_name', '')) not between 2 and 120
     or char_length(coalesce(p_payload->>'reply_to', '')) not between 6 and 254
     or coalesce(p_payload->>'reply_to', '') !~ '^[^@[:space:]<>]+@[^@[:space:]<>]+\.[A-Za-z]{2,}$'
     or char_length(coalesce(p_payload->>'phone', '')) > 20
     or concat_ws(' ', p_payload->>'message', p_payload->>'sender_name', p_payload->>'phone') ~ '[<>]'
     or concat_ws(' ', p_payload->>'message', p_payload->>'sender_name') ~* '(https?://|www\.)' then
    raise exception 'relay: nieprawidłowa wiadomość' using errcode = 'BP422';
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
-- (szablony candidate_*: wiadomość pracodawcy do autora ogłoszenia i e-maile do autora – P1a).
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
          or (p_outbox is null and (status = 'sent'
               -- zwykłe niewysłane po 24 h; wstrzymane do decyzji moderatora (SEC-06) – po 72 h
               or (created_at < now() - interval '24 hours' and next_attempt_at <> 'infinity')
               or created_at < now() - interval '72 hours')));
  get diagnostics v_count = row_count;
  if p_outbox is null then
    delete from public.job_offer_relay_log where created_at < now() - interval '30 days';
  end if;
  return v_count;
end $$;

-- 10.9a Filtr „Zabiegi” (00, D41) – wspólna walidacja parametru {"zabiegi":[…]} list ofert i „Szukam pracy”.
-- NULL = brak filtra (klucz pominięty albo pusta tablica). Tylko identyfikatory z listy (także wycofane – stare
-- adresy z filtrem nadal działają), bez powtórzeń; inaczej BP422 bez wartości. Serwer najpierw normalizuje
-- adres (?zabieg=…: pomija nieznane i powtórzone identyfikatory i mówi o tym na stronie), więc BP422 oznacza
-- wywołanie z pominięciem aplikacji. Górna granica = długość listy (117) – zapytanie pozostaje ograniczone.
create or replace function public.zabiegi_filter(p_filters jsonb)
returns text[]
language plpgsql immutable set search_path = '' as $$
declare
  v_zab text[];
begin
  if p_filters is null or not (p_filters ? 'zabiegi') or p_filters -> 'zabiegi' = '[]'::jsonb then
    return null;
  end if;
  if jsonb_typeof(p_filters -> 'zabiegi') <> 'array'
     or exists (select 1 from jsonb_array_elements(p_filters -> 'zabiegi') e where jsonb_typeof(e) <> 'string') then
    raise exception 'filtr: nieprawidłowe pole zabiegi' using errcode = 'BP422';
  end if;
  v_zab := array(select distinct e from jsonb_array_elements_text(p_filters -> 'zabiegi') e order by e);
  if not (v_zab <@ public.zabiegi_ids()) then
    raise exception 'filtr: nieprawidłowe pole zabiegi' using errcode = 'BP422';
  end if;
  return v_zab;
end $$;

-- 10.9b Publiczna lista ofert „Dam pracę” (00, D41) dla danych w cache bez sesji (16): serwer woła ją kluczem
-- serwisowym (brak EXECUTE dla anon/authenticated – 9.6 pkt 1). Zwraca to samo co polityka anon
-- job_offers_public_read (opublikowane, nieprzeterminowane, tylko kolumny z grantu anon) – nie poszerza
-- dostępu. Zasada tablicy (D-C): kolejność WYŁĄCZNIE od najnowszej publikacji (published_at, id), bez rankingu,
-- bez „najlepiej dopasowanych” i bez liczby wspólnych zabiegów; filtry tylko po polach wybranych przez
-- pracodawcę: zawód, województwo, rodzaj umowy, zabiegi (LUB – oferta z co najmniej jednym z wybranych).
-- 20 ofert na stronę, kursor {"published_at","id"} zamiast numerów stron. Bez limitu dziennego – oferty są
-- publiczne (limity na IP w WAF, 02 §4.13). To samo zapytanie przez Data API jako anon (RLS):
--   GET /rest/v1/job_offers?select=…&zabiegi=ov.{g1-03,g2-12}&order=published_at.desc,id.desc&limit=20
-- (pod RLS operator && nie jest leakproof, więc indeks GIN użyje dopiero funkcja service_role – 16).
create or replace function public.app_job_offers_page(p_filters jsonb default '{}'::jsonb, p_cursor jsonb default null)
returns table (id uuid, slug text, title text, profession text, employment_type text, working_time text,
               city text, voivodeship text, salary_min numeric, salary_max numeric, salary_unit text,
               salary_basis text, zabiegi text[], employer_name text, published_at timestamptz,
               expires_at timestamptz)
language plpgsql stable set search_path = '' as $$
declare
  v_zab text[] := public.zabiegi_filter(p_filters);
begin
  return query
  select o.id, o.slug, o.title, o.profession, o.employment_type, o.working_time, o.city, o.voivodeship,
         o.salary_min, o.salary_max, o.salary_unit, o.salary_basis, o.zabiegi, o.employer_name,
         o.published_at, o.expires_at
    from public.job_offers o
   where o.status = 'published' and o.expires_at > now()
     and (p_filters ->> 'profession' is null or o.profession = p_filters ->> 'profession')
     and (p_filters ->> 'voivodeship' is null or o.voivodeship = p_filters ->> 'voivodeship')
     and (p_filters ->> 'employment_type' is null or o.employment_type = p_filters ->> 'employment_type')
     and (v_zab is null or o.zabiegi && v_zab)                    -- LUB: co najmniej jeden z wybranych
     and (p_cursor is null
          or (o.published_at, o.id) < ((p_cursor ->> 'published_at')::timestamptz, (p_cursor ->> 'id')::uuid))
   order by o.published_at desc, o.id desc
   limit 20;
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

  -- PRIV-14 [Założenie: okresy]: kontakty szkiców i odrzuconych ofert – 30 dni od ostatniej zmiany
  delete from public.job_offer_contacts c
   using public.job_offers o
   where o.id = c.offer_id and o.status in ('draft','rejected') and o.updated_at < now() - interval '30 days';
  -- wiersze ofert – 12 miesięcy po zakończeniu (zamknięte, wygasłe, usunięte) albo po ostatniej zmianie
  -- szkicu lub odrzuconej; nie usuwamy oferty z nieobsłużonym zgłoszeniem nadużycia
  delete from public.job_offers o
   where ((o.status in ('closed','expired','removed')
           and coalesce(o.closed_at, o.expires_at, o.updated_at) < now() - interval '12 months')
       or (o.status in ('draft','rejected') and o.updated_at < now() - interval '12 months'))
     and not exists (select 1 from public.abuse_reports r where r.job_offer_id = o.id and r.handled_at is null);
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
  v_t     public.trainings%rowtype;
  v_until timestamptz;
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
    v_until := public.organizer_plan_until(v_t.organizer_id);
    if v_until is null or v_until <= now() then
      raise exception 'moderate training: organizator bez aktywnego planu (P1d)';
    end if;
    -- BIZ-15: plan obejmuje szkolenia odbywające się w okresie planu (nie „cały rok za jeden miesiąc”)
    if v_t.starts_at > v_until then
      raise exception 'moderate training: szkolenie zaczyna się po końcu planu organizatora';
    end if;
    -- 00, D42: płatność online tylko u organizatora z aktywnymi „Wypłatami” po karencji (usable_from) i
    -- zatwierdzonymi warunkami sprzedaży
    if v_t.payment_mode = 'online' and (
         not exists (select 1 from public.organizer_payout_accounts pa
                      where pa.organizer_id = v_t.organizer_id and pa.status = 'active' and pa.usable_from <= now())
      or not exists (select 1 from public.organizer_sales_terms st
                      where st.organizer_id = v_t.organizer_id and st.status = 'active')) then
      raise exception 'moderate training: płatność online wymaga aktywnych wypłat i warunków sprzedaży organizatora';
    end if;
    update public.trainings
       set status = 'published', published_at = coalesce(published_at, now()), moderated_by = p_actor,
           moderation_note = p_note, rejection_reason = null, plan_valid_until = v_until, updated_at = now()
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
    -- przegląd red team 13.11.2026: usunięcie szkolenia z opłaconymi zamówieniami (= zwroty wszystkim) – tryb
    -- dwóch osób: agent zgłasza w /panel, zatwierdza i wykonuje admin z uzasadnieniem (≥ 20 znaków);
    -- e-mail do wszystkich właścicieli organizatora
    if exists (select 1 from public.training_orders o
                where o.training_id = p_training and o.status in ('paid','partially_refunded','refund_pending')) then
      if not exists (select 1 from public.admin_users u where u.user_id = p_actor and u.is_active and u.role = 'admin') then
        raise exception 'moderate training: usunięcie szkolenia z opłaconymi zamówieniami zatwierdza admin';
      end if;
      if coalesce(char_length(trim(p_reason)), 0) not between 20 and 500 then
        raise exception 'moderate training: usunięcie szkolenia z opłaconymi zamówieniami wymaga uzasadnienia';
      end if;
      insert into public.outbox_emails (template, recipient, payload)
      select 'training_cancelled_by_staff', 'user:' || om.user_id::text, jsonb_build_object('training_id', p_training)
        from public.organizer_members om
       where om.organizer_id = v_t.organizer_id and om.role = 'owner' and om.status = 'active';
    end if;
    update public.trainings
       set status = 'removed', moderated_by = p_actor, moderation_note = p_note, rejection_reason = p_reason,
           cancelled_at = now(), updated_at = now()
     where id = p_training;            -- zapisanym serwer wysyła training_cancelled
    -- 00, D42: usunięte szkolenie = zwroty wszystkim opłaconym i zamknięte rezerwacje
    perform public.training_orders_refund_all(p_training, 'staff:' || p_actor::text);
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
  -- 00, D42: miejsca w rezerwacjach (seats_held) liczą się jak zajęte
  if p_capacity is not null and (p_capacity < 1 or p_capacity < v_t.seats_registered + v_t.seats_held) then
    raise exception 'capacity: limit nie może być mniejszy niż liczba zapisanych i zarezerwowanych (%)',
      v_t.seats_registered + v_t.seats_held;
  end if;
  update public.trainings set capacity = p_capacity, updated_at = now() where id = p_training;

  loop
    exit when p_capacity is not null
          and (select seats_registered + seats_held from public.trainings where id = p_training) >= p_capacity;
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

-- 10.14 Odwołanie szkolenia przez organizatora albo personel (zapisani dostają training_cancelled).
-- 00, D42 + przegląd red team 13.11.2026: odwołanie szkolenia z opłaconymi zamówieniami = zwroty wszystkim,
-- więc tylko właściciel organizatora poza karencją po resecie TOTP (organizer_money_ok) albo admin
-- z uzasadnieniem (≥ 20 znaków) i e-mailem do wszystkich właścicieli organizatora; członek zespołu
-- organizatora i agent – tylko szkolenia bez opłaconych zamówień.
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
  if exists (select 1 from public.training_orders o
              where o.training_id = p_training and o.status in ('paid','partially_refunded','refund_pending')) then
    if v_kind = 'user:' and not public.organizer_money_ok(v_t.organizer_id, p_actor) then
      raise exception 'cancel event: szkolenie z opłaconymi zamówieniami odwołuje właściciel organizatora';
    end if;
    if v_kind = 'staff:' then
      if not exists (select 1 from public.admin_users u where u.user_id = p_actor and u.is_active and u.role = 'admin') then
        raise exception 'cancel event: szkolenie z opłaconymi zamówieniami – tylko admin';
      end if;
      if coalesce(char_length(trim(p_reason)), 0) not between 20 and 500 or p_reason ~ '[<>]' then
        raise exception 'cancel event: nieprawidłowe pole reason' using errcode = 'BP422';
      end if;
      insert into public.outbox_emails (template, recipient, payload)
      select 'training_cancelled_by_staff', 'user:' || om.user_id::text,
             jsonb_build_object('training_id', p_training)
        from public.organizer_members om
       where om.organizer_id = v_t.organizer_id and om.role = 'owner' and om.status = 'active';
    end if;
  end if;
  update public.trainings set status = 'cancelled', cancelled_at = now(), updated_at = now() where id = p_training;
  insert into public.client_audit_log (organizer_id, actor, action, entity, entity_id, payload)
  values (v_t.organizer_id, v_kind || p_actor::text, 'training_event_cancelled', 'training', p_training,
          jsonb_build_object('reason', left(coalesce(p_reason, ''), 200)));
  -- 00, D42: odwołanie = pełne zwroty wszystkim opłaconym zamówieniom (wykonuje operator) i zamknięte rezerwacje
  perform public.training_orders_refund_all(p_training, v_kind || p_actor::text);
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
                                 and a.kind = 'client'   -- zapis z konta salonu (D-D); konta pracodawców – Q17
   where m.account_id = p_account and m.user_id = p_user and m.status = 'active';
  if not found then
    raise exception 'register: brak aktywnego członkostwa';
  end if;

  select * into v_t from public.trainings where id = p_training for update;
  if not found or v_t.status <> 'published' or v_t.published_at is null
     or v_t.plan_valid_until is null or v_t.plan_valid_until <= now()      -- P1d: tylko przy aktywnym planie
     or v_t.starts_at > v_t.plan_valid_until then                          -- BIZ-15: termin w okresie planu
    raise exception 'register: szkolenie niedostępne';
  end if;
  if v_t.payment_mode = 'online' then                                      -- 00, D42: tylko przez zamówienie
    raise exception 'register: szkolenie płatne online – zapis przez zamówienie' using errcode = 'BP409';
  end if;
  -- PRIV-12: walidacja przed zapisem, bez wartości w komunikacie (CHECK zwróciłby cały wiersz w DETAIL)
  if coalesce(char_length(trim(p_participant_name)), 0) not between 2 and 120
     or coalesce(char_length(trim(p_participant_email)), 0) not between 6 and 254 then
    raise exception 'register: nieprawidłowe dane uczestnika' using errcode = 'BP422';
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
  -- 00, D42: opłacone miejsce zwalnia wyłącznie zwrot (decyzja organizatora albo odwołanie szkolenia) –
  -- uczestnik prosi o rezygnację przez app_training_order_cancel_request()
  if exists (select 1 from public.training_orders o
              where o.registration_id = v_reg.id and o.status in ('paid','partially_refunded','refund_pending')) then
    raise exception 'cancel: szkolenie opłacone – rezygnacja przez zamówienie' using errcode = 'BP409';
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

-- Lista uczestników dla organizatora (SEC-01 – jedyna droga odczytu training_participant_contacts):
-- tylko członek aktywnego, zweryfikowanego organizatora szkolenia (aal2 sprawdza serwer), tylko osoby
-- zapisane/obecne/nieobecne (lista rezerwowa niewidoczna), każde wywołanie z wpisem w dzienniku
-- (wgląd albo eksport CSV). Personel nie ma tej drogi (minimalizacja).
create or replace function public.app_training_participants(
  p_training uuid, p_actor uuid, p_action text default 'organizer_participants_viewed')
returns table (registration_id uuid, status text, participant_name text, participant_email text, salon_name text)
language plpgsql set search_path = '' as $$
begin
  perform public.app_log_organizer_access(p_training, p_actor, p_action);   -- uprawnienia + dziennik
  return query
    select c.registration_id, c.status, c.participant_name, c.participant_email, c.salon_name
      from public.training_participant_contacts c
     where c.training_id = p_training and c.status in ('registered','attended','no_show')
     order by c.created_at;
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

-- 10.20 Przełącznik funkcji i promocja (P1). Każda funkcja zapisu „Szukam pracy” zaczyna od
--       app_require_feature(): przy wyłączonym przełączniku kończy się wyjątkiem SQLSTATE BP404 (serwer
--       odpowiada 404, zakładka znika). Wyjątki od blokady: app_candidate_ad_delete(), app_job_seeker_close()
--       (prawo do usunięcia danych) i app_purge_candidate_ads() (retencja) – tylko zmniejszają ilość danych.
create or replace function public.app_require_feature(p_key text)
returns void
language plpgsql stable set search_path = '' as $$
begin
  if not exists (select 1 from public.app_feature_flags f where f.key = p_key and f.enabled) then
    raise exception 'funkcja % jest wyłączona', p_key using errcode = 'BP404';
  end if;
end $$;

-- Włączenie/wyłączenie: tylko admin Aura; włączenie wymaga odwołania do decyzji zleceniodawcy (P1).
-- Wyłączenie nie usuwa wierszy: RLS natychmiast ukrywa ogłoszenia przed pracodawcami i personelem,
-- a retencja usuwa dane w zwykłym trybie.
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
    raise exception 'feature flag: włączenie wymaga odwołania do decyzji zleceniodawcy';
  end if;
  update public.app_feature_flags
     set enabled = p_enabled, decision_ref = coalesce(nullif(trim(p_decision_ref), ''), decision_ref),
         changed_by = p_actor, changed_at = now()
   where key = p_key;
  insert into public.client_audit_log (actor, action, entity, payload)
  values ('staff:' || p_actor::text, 'feature_flag_changed', 'feature_flag',
          jsonb_build_object('key', p_key, 'from', v_old, 'to', p_enabled));
end $$;

-- Długość publikacji ogłoszeń z aktywnej promocji (P1c: 21 dni). Bez aktywnej promocji – BP409:
-- zasady po promocji są do ustalenia, więc baza nie publikuje ogłoszeń na nieokreślonych warunkach [Założenie].
create or replace function public.promo_ad_days()
returns smallint
language plpgsql stable set search_path = '' as $$
declare
  v_days smallint;
begin
  select p.ad_days into v_days from public.app_promotions p
   where p.enabled and p.free_ads and p.starts_at <= now() and (p.ends_at is null or p.ends_at > now())
   order by p.starts_at desc limit 1;
  if v_days is null then
    raise exception 'promocja nieaktywna – zasady publikacji po promocji do ustalenia' using errcode = 'BP409';
  end if;
  return v_days;
end $$;

-- Zmiana promocji: tylko admin Aura, włączenie z odwołaniem do decyzji zleceniodawcy, wpis w dzienniku.
create or replace function public.app_set_promotion(
  p_key text, p_enabled boolean, p_actor uuid, p_decision_ref text default null, p_ends_at timestamptz default null)
returns void
language plpgsql set search_path = '' as $$
declare
  v_old boolean;
begin
  if not exists (select 1 from public.admin_users u
                 where u.user_id = p_actor and u.is_active and u.role = 'admin') then
    raise exception 'promotion: brak uprawnień';
  end if;
  select p.enabled into v_old from public.app_promotions p where p.key = p_key for update;
  if not found then
    raise exception 'promotion: nieznana promocja %', p_key;
  end if;
  if p_enabled and coalesce(char_length(trim(p_decision_ref)), 0) < 5 then
    raise exception 'promotion: włączenie wymaga odwołania do decyzji zleceniodawcy';
  end if;
  update public.app_promotions
     set enabled = p_enabled, ends_at = p_ends_at,
         decision_ref = coalesce(nullif(trim(p_decision_ref), ''), decision_ref),
         changed_by = p_actor, changed_at = now()
   where key = p_key;
  insert into public.client_audit_log (actor, action, entity, payload)
  values ('staff:' || p_actor::text, 'promotion_changed', 'promotion',
          jsonb_build_object('key', p_key, 'from', v_old, 'to', p_enabled, 'ends_at', p_ends_at));
end $$;


-- 10.21 Pracodawcy (P1b): rejestracja, wynik GUS, aktywacja.
--       Kolejność na serwerze: konto Auth (kod z e-maila) → NIP (suma kontrolna, Turnstile) →
--       app_employer_register → zapytanie do API BIR GUS (klucz tylko w sekrecie Workera, wynik z cache
--       najwyżej 24 h) → app_employer_record_gus → kod SMS (app_phone_send_code / app_phone_verify_code)
--       → konfiguracja TOTP → app_employer_activate.
create or replace function public.nip_checksum_ok(p_nip text)
returns boolean
language sql immutable set search_path = '' as $$
  select case when p_nip ~ '^[0-9]{10}$' then
    (  6 * substr(p_nip, 1, 1)::int + 5 * substr(p_nip, 2, 1)::int + 7 * substr(p_nip, 3, 1)::int
     + 2 * substr(p_nip, 4, 1)::int + 3 * substr(p_nip, 5, 1)::int + 4 * substr(p_nip, 6, 1)::int
     + 5 * substr(p_nip, 7, 1)::int + 6 * substr(p_nip, 8, 1)::int + 7 * substr(p_nip, 9, 1)::int) % 11
    = substr(p_nip, 10, 1)::int
  else false end;
$$;

-- Rejestracja: konto 'employer' w statusie pending i właściciel = rejestrujący. SEC-03: rejestracja
-- w toku NIE rezerwuje NIP i NIE ujawnia, czy dla NIP istnieje konto – funkcja zakłada konto pending także
-- wtedy, gdy NIP ma już aktywne konto (salon z polisą albo inny pracodawca); serwer zawsze odpowiada
-- tak samo („Sprawdzimy dane i odezwiemy się e-mailem”). Kolizję rozstrzyga app_employer_activate().
-- [Założenie] jedna rejestracja w toku na osobę, najwyżej 3 konta pracodawcy na osobę, najwyżej 3
-- rejestracje w toku na jeden NIP (próby ponad limit – BP429, serwer odpowiada tym samym tekstem;
-- limiter Workera liczy dodatkowo próby na HMAC NIP).
create or replace function public.app_employer_register(
  p_user uuid, p_nip text, p_display_name text, p_terms_version text)
returns uuid
language plpgsql set search_path = '' as $$
declare
  v_id uuid;
begin
  if exists (select 1 from public.admin_users u where u.user_id = p_user) then
    raise exception 'employer: konto personelu nie może być kontem pracodawcy';
  end if;
  if not public.nip_checksum_ok(p_nip) then
    raise exception 'employer: nieprawidłowy NIP' using errcode = 'BP422';
  end if;
  if coalesce(char_length(trim(p_terms_version)), 0) = 0 then
    raise exception 'employer: brak akceptacji regulaminu';
  end if;
  if coalesce(char_length(trim(p_display_name)), 0) not between 2 and 120
     or trim(p_display_name) ~ '[<>@]' or trim(p_display_name) ~* '(https?://|www\.)'
     or trim(p_display_name) ~* '(\m(aura|beautypolisa|ergo|hestia|colonnade)\M|beauty[ -]?polisa|lux[ -]?med|enel[ -]?med)' then
    raise exception 'employer: nazwa wyświetlana niedozwolona (znaczniki, adresy, linki albo nazwa zastrzeżona)'
      using errcode = 'BP422';
  end if;
  perform pg_advisory_xact_lock(hashtext('nip:' || p_nip));
  if (select count(*) from public.client_accounts a
       where a.nip = p_nip and a.kind = 'employer' and a.status = 'pending') >= 3 then
    raise exception 'employer: limit rejestracji dla NIP' using errcode = 'BP429';
  end if;
  if exists (select 1 from public.client_members m join public.client_accounts a on a.id = m.account_id
              where m.user_id = p_user and a.kind = 'employer' and a.status = 'pending') then
    raise exception 'employer: dokończ rozpoczętą rejestrację';
  end if;
  if (select count(*) from public.client_members m join public.client_accounts a on a.id = m.account_id
       where m.user_id = p_user and m.status = 'active' and a.kind = 'employer' and a.status <> 'closed') >= 3 then
    raise exception 'employer: limit kont pracodawcy';
  end if;
  insert into public.client_accounts (kind, display_name, nip, status, created_by)
  values ('employer', trim(p_display_name), p_nip, 'pending', p_user)
  returning id into v_id;
  insert into public.client_members (account_id, user_id, role, status, terms_version, terms_accepted_at)
  values (v_id, p_user, 'owner', 'active', p_terms_version, now());
  insert into public.client_audit_log (account_id, actor, action, entity, entity_id)
  values (v_id, 'user:' || p_user::text, 'employer_registered', 'account', v_id);
  return v_id;
end $$;

-- Wynik sprawdzenia NIP (serwer po zapytaniu do API BIR albo personel przy awarii usługi). p_result:
-- {"nip","result":"aktywny|nieaktywny|nie-znaleziono|blad-uslugi","regon","entity_type","legal_name","city",
-- "postal_code"}. „aktywny” = podmiot jest w rejestrze i nie ma daty zakończenia ani zawieszenia
-- działalności [pola odpowiedzi BIR do weryfikacji w dokumentacji API]. Skutki: aktywny → employer_verified_at
-- = now(), u pracodawcy nazwa prawna z GUS; nieaktywny / nie-znaleziono → weryfikacja cofnięta, aktywne konto
-- pracodawcy zawieszone (salon z polisą zachowuje konto – D-B – ale traci publikację i „Szukam pracy”);
-- blad-uslugi → bez zmian (serwer ponowi zapytanie).
create or replace function public.app_employer_record_gus(p_account uuid, p_checked_by text, p_result jsonb)
returns boolean
language plpgsql set search_path = '' as $$
declare
  v_acc public.client_accounts%rowtype;
  v_res text := p_result ->> 'result';
begin
  if p_checked_by is null or p_checked_by !~ '^(system:gus|staff:[0-9a-f-]{36})$' then
    raise exception 'gus: nieprawidłowy aktor';
  end if;
  if p_checked_by like 'staff:%' and not exists (
       select 1 from public.admin_users u
        where u.user_id = substr(p_checked_by, 7)::uuid and u.is_active and u.role in ('admin','agent')) then
    raise exception 'gus: brak uprawnień';
  end if;
  select * into v_acc from public.client_accounts where id = p_account for update;
  if not found or v_acc.status = 'closed' then
    raise exception 'gus: brak konta';
  end if;
  if v_acc.nip is null or (p_result ->> 'nip') is distinct from v_acc.nip then
    raise exception 'gus: wynik dotyczy innego NIP';
  end if;

  insert into public.employer_verifications
    (account_id, nip, source, result, regon, entity_type, legal_name, city, postal_code, checked_by)
  values (p_account, v_acc.nip, case when p_checked_by like 'staff:%' then 'personel' else 'gus-bir' end,
          v_res, p_result ->> 'regon', p_result ->> 'entity_type', left(p_result ->> 'legal_name', 300),
          left(p_result ->> 'city', 80), p_result ->> 'postal_code', p_checked_by);

  if v_res = 'aktywny' then
    update public.client_accounts
       set employer_verified_at = now(),
           legal_name = case when kind = 'employer' or legal_name is null
                             then left(p_result ->> 'legal_name', 300) else legal_name end,
           city = coalesce(city, left(p_result ->> 'city', 80)),
           updated_at = now()
     where id = p_account;
  elsif v_res in ('nieaktywny', 'nie-znaleziono') then
    perform set_config('app.audit_actor', p_checked_by, true);
    update public.client_accounts
       set employer_verified_at = null,
           suspended_at = case when kind = 'employer' and status = 'active' then now() else suspended_at end,
           status = case when kind = 'employer' and status = 'active' then 'suspended' else status end,
           updated_at = now()
     where id = p_account;
    -- SEC-08: zawieszenie i utrata funkcji pracodawcy zdejmują treści – oferty przestają być publiczne,
    -- oczekujące wiadomości nie wychodzą; uzasadnienie e-mailem z informacją o środku automatycznym (DSA-13)
    perform public.account_content_takedown(p_account, p_checked_by,
      'Nie potwierdziliśmy aktywnej działalności firmy w rejestrze REGON (GUS).', p_checked_by = 'system:gus');
  end if;

  insert into public.client_audit_log (account_id, actor, action, entity, entity_id, payload)
  values (p_account, p_checked_by, 'employer_gus_checked', 'account', p_account,
          jsonb_build_object('result', v_res));
  return v_res = 'aktywny';
end $$;

-- Aktywacja konta pracodawcy: świeży wynik GUS (≤ 24 h), właściciel z potwierdzonym telefonem.
-- TOTP właściciela serwer konfiguruje przed wywołaniem; employer_account_ids() i tak wymaga aal2.
-- SEC-03 – konflikt NIP rozstrzyga ta funkcja (pod blokadą NIP):
--  * NIP bez aktywnego/zawieszonego konta → aktywacja; pozostałe rejestracje w toku dla NIP są zamykane;
--  * NIP ma aktywne konto pracodawcy BEZ potwierdzonej reprezentacji, a aktywowane konto ją ma (personel
--    potwierdził ją przed aktywacją – app_employer_trust) → dotychczasowe konto jest zamykane i traci treści
--    („przejęcie NIP”), aktywowane – aktywne;
--  * w pozostałych przypadkach → 'conflict': brak aktywacji, e-mail do właściciela istniejącego konta
--    („Ktoś próbował założyć konto dla NIP …”), zgłoszenie dla personelu w /panel, wpis w dzienniku.
--    Funkcja NIE rzuca wyjątku (wycofałby powiadomienia); serwer odpowiada neutralnie.
-- Zwraca 'active' albo 'conflict'.
create or replace function public.app_employer_activate(p_account uuid, p_actor uuid)
returns text
language plpgsql set search_path = '' as $$
declare
  v_acc   public.client_accounts%rowtype;
  v_other public.client_accounts%rowtype;
begin
  select a.* into v_acc from public.client_accounts a
   where a.id = p_account and a.kind = 'employer' and a.status = 'pending'
     and a.employer_verified_at > now() - interval '24 hours'
     and exists (select 1 from public.client_members m
                  where m.account_id = a.id and m.user_id = p_actor and m.role = 'owner' and m.status = 'active')
     and exists (select 1 from public.user_phones p where p.user_id = p_actor)
   for update;
  if not found then
    raise exception 'employer activate: wymagany aktywny NIP w GUS i potwierdzony telefon właściciela';
  end if;
  perform pg_advisory_xact_lock(hashtext('nip:' || v_acc.nip));
  select a.* into v_other from public.client_accounts a
   where a.nip = v_acc.nip and a.id <> v_acc.id and a.status in ('active','suspended')
   for update;
  if found then
    if v_other.kind = 'employer' and v_other.employer_trusted_at is null and v_acc.employer_trusted_at is not null then
      perform set_config('app.audit_actor', 'system:nip-conflict', true);
      perform public.account_content_takedown(v_other.id, 'system:nip-conflict',
        'Firma o tym NIP potwierdziła reprezentację w Aura Expert; konto bez potwierdzenia zostało zamknięte.', false);
      update public.client_accounts set status = 'closed', closed_at = now(), updated_at = now() where id = v_other.id;
      update public.client_members set status = 'revoked', revoked_at = now()
       where account_id = v_other.id and status = 'active';
    else
      insert into public.outbox_emails (template, recipient, payload, account_id)
      select 'employer_nip_attempt', 'user:' || m.user_id::text, jsonb_build_object('nip', v_acc.nip), v_other.id
        from public.client_members m
       where m.account_id = v_other.id and m.role = 'owner' and m.status = 'active';
      insert into public.outbox_emails (template, recipient, payload, account_id)
      values ('employer_nip_conflict_team', 'team:pracodawcy',
              jsonb_build_object('pending_account', v_acc.id, 'existing_account', v_other.id), v_acc.id);
      insert into public.client_audit_log (account_id, actor, action, entity, entity_id)
      values (v_other.id, 'user:' || p_actor::text, 'employer_nip_conflict', 'account', v_acc.id);
      return 'conflict';
    end if;
  end if;

  update public.client_accounts
     set status = 'active', activated_at = now(), activated_by = p_actor, updated_at = now()
   where id = p_account;
  -- pozostałe rejestracje w toku dla tego NIP – zamknięte (NIP zajęty przez aktywne konto)
  update public.client_members m set status = 'revoked', revoked_at = now()
    from public.client_accounts a
   where m.account_id = a.id and a.nip = v_acc.nip and a.id <> p_account and a.status = 'pending'
     and m.status = 'active';
  update public.client_accounts
     set status = 'closed', closed_at = now(), legal_name = null, city = null, employer_verified_at = null,
         updated_at = now()
   where nip = v_acc.nip and id <> p_account and status = 'pending' and kind = 'employer';
  insert into public.client_audit_log (account_id, actor, action, entity, entity_id)
  values (p_account, 'user:' || p_actor::text, 'account_activated', 'account', p_account);
  return 'active';
end $$;

-- SEC-02: poziom 2 zaufania – personel potwierdził, że rejestrujący reprezentuje firmę. Wystarczy
-- JEDNA proporcjonalna droga (Założenie; szczegóły w dok. 11, 4.12 pkt 4a):
--   'domena-email'           – adres konta w domenie firmy zgodnej ze stroną albo e-mailem z rejestru
--                              [pola raportu BIR/CEIDG do weryfikacji];
--   'telefon-zwrotny'        – personel dzwoni na numer z publicznego rejestru albo ze strony firmy
--                              (ten sam standard co u organizatorów, 12.1);
--   'list-na-adres-siedziby' – kod wysłany listem na adres siedziby z rejestru;
--   'przelew-weryfikacyjny'  – przelew 1 zł z rachunku firmy z białej listy VAT (API MF) [do weryfikacji].
-- Potwierdzenie zatwierdza też nazwę wyświetlaną. p_method = NULL cofa potwierdzenie. Tylko admin/agent.
create or replace function public.app_employer_trust(p_account uuid, p_actor uuid, p_method text)
returns void
language plpgsql set search_path = '' as $$
begin
  if not exists (select 1 from public.admin_users u
                 where u.user_id = p_actor and u.is_active and u.role in ('admin','agent')) then
    raise exception 'trust: brak uprawnień';
  end if;
  update public.client_accounts
     set employer_trusted_at = case when p_method is null then null else now() end,
         employer_trust_method = p_method,
         employer_trusted_by = case when p_method is null then null else p_actor end,
         display_name_approved_at = case when p_method is null then display_name_approved_at
                                         else coalesce(display_name_approved_at, now()) end,
         updated_at = now()
   where id = p_account and kind = 'employer' and status in ('pending','active');
  if not found then
    raise exception 'trust: brak konta pracodawcy w toku albo aktywnego';
  end if;
  insert into public.client_audit_log (account_id, actor, action, entity, entity_id, payload)
  values (p_account, 'staff:' || p_actor::text,
          case when p_method is null then 'employer_trust_revoked' else 'employer_trusted' end,
          'account', p_account, jsonb_build_object('method', p_method));
end $$;

-- Czy aktor może czytać „Szukam pracy” i pisać do autorów w imieniu konta (SEC-01, SEC-02): właściciel
-- aktywnego konta, NIP w GUS ≤ 120 dni, telefon SMS i poziom 2 zaufania (salon z polisą – z urzędu).
-- Sesję aal2 sprawdza serwer przed wywołaniem. Funkcja wewnętrzna (EXECUTE tylko service_role).
create or replace function public.employer_trusted_actor(p_account uuid, p_actor uuid)
returns boolean
language sql stable set search_path = '' as $$
  select exists (
    select 1 from public.client_accounts a
      join public.client_members m on m.account_id = a.id
     where a.id = p_account and a.status = 'active'
       and a.employer_verified_at > now() - interval '120 days'
       and (a.kind = 'client' or a.employer_trusted_at is not null)
       and m.user_id = p_actor and m.role = 'owner' and m.status = 'active')
  and exists (select 1 from public.user_phones p where p.user_id = p_actor);
$$;

-- SEC-08: zdjęcie treści konta (wołają: zawieszenie przez personel, wynik GUS „nieaktywny”, przejęcie NIP).
-- Oferty opublikowane, w moderacji i szkice → 'removed' z uzasadnieniem (DSA), oczekujące wiadomości
-- kandydatów do pracodawcy (job_relay) i pracodawcy do autorów (candidate_contact) – wyczyszczone,
-- e-mail z uzasadnieniem do właścicieli (informacja, czy decyzję podjęto środkiem automatycznym, i jak się
-- odwołać – DSA-13). Funkcja wewnętrzna (EXECUTE tylko service_role).
create or replace function public.account_content_takedown(
  p_account uuid, p_actor text, p_reason text, p_automated boolean)
returns integer
language plpgsql set search_path = '' as $$
declare
  v_n integer;
begin
  update public.job_offers
     set status = 'removed', rejection_reason = left(p_reason, 500), closed_at = coalesce(closed_at, now()),
         updated_at = now()
   where account_id = p_account and status in ('draft','pending_review','published');
  get diagnostics v_n = row_count;
  update public.outbox_emails
     set payload = '{}'::jsonb, recipient = 'anonymized', status = 'failed'
   where account_id = p_account and status = 'pending' and recipient <> 'anonymized'
     and (template = 'job_relay' or template = 'candidate_contact');
  insert into public.outbox_emails (template, recipient, payload, account_id)
  select 'account_content_removed', 'user:' || m.user_id::text,
         jsonb_build_object('reason', left(p_reason, 500), 'automated', p_automated, 'offers_removed', v_n,
                            'appeal_days', 30),
         p_account
    from public.client_members m
   where m.account_id = p_account and m.role = 'owner' and m.status = 'active';
  if v_n > 0 then
    insert into public.client_audit_log (account_id, actor, action, entity, entity_id, payload)
    values (p_account, p_actor, 'job_offer_removed', 'account', p_account,
            jsonb_build_object('count', v_n, 'automated', p_automated));
  end if;
  return v_n;
end $$;

-- SEC-08: zawieszenie konta salonu albo pracodawcy przez personel (oszustwo, uzasadnione zgłoszenia).
-- Konto traci dostęp (client_account_ids/employer_account_ids wymagają statusu active), treści są zdejmowane.
create or replace function public.app_suspend_account(p_account uuid, p_actor uuid, p_reason text)
returns void
language plpgsql set search_path = '' as $$
begin
  if not exists (select 1 from public.admin_users u
                 where u.user_id = p_actor and u.is_active and u.role in ('admin','agent')) then
    raise exception 'suspend: brak uprawnień';
  end if;
  if coalesce(char_length(trim(p_reason)), 0) < 10 then
    raise exception 'suspend: zawieszenie wymaga uzasadnienia' using errcode = 'BP422';
  end if;
  perform set_config('app.audit_actor', 'staff:' || p_actor::text, true);
  update public.client_accounts set status = 'suspended', suspended_at = now(), updated_at = now()
   where id = p_account and status = 'active';
  if not found then
    raise exception 'suspend: konto nie jest aktywne';
  end if;
  perform public.account_content_takedown(p_account, 'staff:' || p_actor::text, p_reason, false);
end $$;

-- SEC-08: zawieszenie osoby szukającej pracy (np. osoba niepełnoletnia, nadużycia): ogłoszenie zdjęte
-- z uzasadnieniem, oczekujące wiadomości do niej wyczyszczone, e-mail z uzasadnieniem i drogą odwołania.
create or replace function public.app_suspend_job_seeker(p_user uuid, p_actor uuid, p_reason text)
returns void
language plpgsql set search_path = '' as $$
begin
  if not exists (select 1 from public.admin_users u
                 where u.user_id = p_actor and u.is_active and u.role in ('admin','agent')) then
    raise exception 'suspend: brak uprawnień';
  end if;
  if coalesce(char_length(trim(p_reason)), 0) < 10 then
    raise exception 'suspend: zawieszenie wymaga uzasadnienia' using errcode = 'BP422';
  end if;
  update public.job_seekers set status = 'suspended', suspended_at = now()
   where user_id = p_user and status = 'active';
  if not found then
    raise exception 'suspend: konto osoby szukającej pracy nie jest aktywne';
  end if;
  update public.candidate_ads
     set status = 'removed', rejection_reason = left(p_reason, 1000), removed_at = now(), moderated_by = p_actor,
         updated_at = now()
   where seeker_id = p_user and status in ('pending_review','published');
  update public.outbox_emails
     set payload = '{}'::jsonb, recipient = 'anonymized', status = 'failed'
   where recipient = 'user:' || p_user::text and template = 'candidate_contact' and status = 'pending';
  insert into public.outbox_emails (template, recipient, payload)
  values ('job_seeker_suspended', 'user:' || p_user::text,
          jsonb_build_object('reason', left(p_reason, 1000), 'automated', false, 'appeal_days', 30));
  insert into public.client_audit_log (actor, action, entity, entity_id)
  values ('staff:' || p_actor::text, 'job_seeker_suspended', 'job_seeker', p_user);
end $$;

-- SEC-05: potwierdzone adresy pracodawcy. Adres logowania właściciela – od razu potwierdzony (serwer
-- przekazuje adres z ZWERYFIKOWANEGO tokenu sesji, która powstała z kodu wysłanego na ten adres).
create or replace function public.app_reply_address_from_login(p_account uuid, p_actor uuid, p_login_email text)
returns void
language plpgsql set search_path = '' as $$
begin
  if not exists (select 1 from public.client_members m
                  where m.account_id = p_account and m.user_id = p_actor and m.role = 'owner' and m.status = 'active') then
    raise exception 'reply address: brak uprawnień';
  end if;
  insert into public.employer_reply_addresses (account_id, email_normalized, requested_by, verified_at)
  values (p_account, lower(trim(p_login_email)), p_actor, now())
  on conflict (account_id, email_normalized) do update
    set verified_at = coalesce(public.employer_reply_addresses.verified_at, now()), token_hash = null,
        token_expires_at = null;
end $$;

-- Inny adres (np. rekrutacja@firma.pl): serwer generuje token, zapisuje jego sha256 i wysyła link
-- WYŁĄCZNIE na ten adres (poza outboxem, jak kody logowania). Najwyżej 5 niepotwierdzonych adresów na konto.
create or replace function public.app_reply_address_request(
  p_account uuid, p_actor uuid, p_email text, p_token_hash text)
returns void
language plpgsql set search_path = '' as $$
declare
  v_email text := lower(trim(p_email));
begin
  if not exists (select 1 from public.client_members m join public.client_accounts a on a.id = m.account_id
                  where m.account_id = p_account and m.user_id = p_actor and m.role = 'owner'
                    and m.status = 'active' and a.status in ('pending','active')) then
    raise exception 'reply address: brak uprawnień';
  end if;
  if v_email !~ '^[^@[:space:]<>]+@[^@[:space:]<>]+\.[a-z]{2,}$' or char_length(v_email) > 254 then
    raise exception 'reply address: nieprawidłowy adres' using errcode = 'BP422';
  end if;
  perform pg_advisory_xact_lock(hashtext('ra:' || p_account::text));
  if (select count(*) from public.employer_reply_addresses r
       where r.account_id = p_account and r.verified_at is null) >= 5 then
    raise exception 'reply address: limit adresów oczekujących na potwierdzenie' using errcode = 'BP429';
  end if;
  insert into public.employer_reply_addresses (account_id, email_normalized, token_hash, token_expires_at, requested_by)
  values (p_account, v_email, p_token_hash, now() + interval '24 hours', p_actor)
  on conflict (account_id, email_normalized) do update
    set token_hash = excluded.token_hash, token_expires_at = excluded.token_expires_at,
        requested_by = excluded.requested_by
    where public.employer_reply_addresses.verified_at is null;
end $$;

-- Kliknięcie linku (strona z przyciskiem POST – skanery poczty otwierają linki): token jednorazowy.
create or replace function public.app_reply_address_confirm(p_token_hash text)
returns boolean
language plpgsql set search_path = '' as $$
declare
  v_account uuid;
begin
  update public.employer_reply_addresses
     set verified_at = now(), token_hash = null, token_expires_at = null
   where token_hash = p_token_hash and verified_at is null and token_expires_at > now()
  returning account_id into v_account;
  if v_account is null then
    return false;
  end if;
  insert into public.client_audit_log (account_id, actor, action, entity)
  values (v_account, 'system:reply-address', 'reply_address_verified', 'reply_address');
  return true;
end $$;


-- 10.22 Telefon (P1, SMS). Serwer przed wywołaniem: sesja z kodu e-mail (konto Auth istnieje), Turnstile,
--       numer tylko komórkowy +48 (walidacja numeracji), u pracodawcy dopiero po wyniku GUS „aktywny”
--       (SEC-11), limity na IP i prefiks sieci w Durable Object (SEC-10); generuje 6-cyfrowy kod, liczy HMAC
--       numeru, prefiksu (5 pierwszych cyfr po +48) i kodu – osobnymi kluczami (SEC-17) – i dopiero po
--       sukcesie funkcji wysyła SMS przez bramkę. Baza egzekwuje niezależnie (wszystko z sms_send_log, który
--       nie znika z kontem – SEC-04): globalny limit dobowy i godzinowy, bezpiecznik konwersji, limity na konto,
--       numer i prefiks, 60 s między wysyłkami, limit kont na numer, ważność 10 min i 5 prób.
--       Każda odmowa ma ten sam kod BP429 i neutralny tekst (SEC-11: bez ujawniania, że numer ma już konta);
--       powód zna tylko dziennik techniczny (bez numeru). Alert przy wyczerpaniu limitu wysyła Cron
--       (sms_spend_alert) – wyjątek wycofałby wpis alertu.
create or replace function public.app_phone_send_code(
  p_user uuid, p_phone_hmac text, p_phone_last3 text, p_code_hmac text, p_prefix_hmac text default null)
returns uuid
language plpgsql set search_path = '' as $$
declare
  s        public.app_settings%rowtype;
  v_id     uuid;
  v_hour   integer;
  v_hour_ok integer;
begin
  perform pg_advisory_xact_lock(hashtext('app_phone_send_code'));   -- limity globalne bez wyścigu
  select * into s from public.app_settings;
  -- bezpiecznik konwersji: kody z okna 70–10 min temu są już rozstrzygnięte (ważność 10 min); dużo wysyłek
  -- i mało potwierdzeń = SMS pumping → pauza wysyłek do czasu, aż okno się poprawi, i alert z Cron
  select count(*), count(l.verified_at) into v_hour, v_hour_ok
    from public.sms_send_log l
   where l.created_at > now() - interval '70 minutes' and l.created_at <= now() - interval '10 minutes';
  if (select count(*) from public.sms_send_log l where l.created_at > now() - interval '1 day') >= s.sms_daily_cap
     or (select count(*) from public.sms_send_log l where l.created_at > now() - interval '1 hour') >= s.sms_hourly_cap
     or (v_hour >= s.sms_breaker_min_sends and v_hour_ok < v_hour * s.sms_breaker_min_ratio) then
    raise exception 'sms: limit wysyłek kodów – spróbuj później' using errcode = 'BP429';
  end if;
  if exists (select 1 from public.sms_send_log l
              where l.user_ref = p_user and l.created_at > now() - interval '60 seconds')
     or (select count(*) from public.sms_send_log l
          where l.user_ref = p_user and l.created_at > now() - interval '1 day') >= s.sms_per_user_day
     or (select count(*) from public.sms_send_log l
          where l.phone_hmac = p_phone_hmac and l.created_at > now() - interval '1 day') >= s.sms_per_number_day
     or (p_prefix_hmac is not null and (select count(*) from public.sms_send_log l
          where l.prefix_hmac = p_prefix_hmac and l.created_at > now() - interval '1 hour') >= s.sms_per_prefix_hour)
     or (select count(*) from public.user_phones p
          where p.phone_hmac = p_phone_hmac and p.user_id <> p_user) >= s.accounts_per_number then
    raise exception 'sms: limit wysyłek kodów – spróbuj później' using errcode = 'BP429';
  end if;
  update public.phone_verifications
     set expires_at = now()
   where user_id = p_user and verified_at is null and expires_at > now();   -- poprzedni kod przestaje działać
  insert into public.phone_verifications (user_id, phone_hmac, phone_last3, code_hmac, expires_at)
  values (p_user, p_phone_hmac, p_phone_last3, p_code_hmac, now() + interval '10 minutes')
  returning id into v_id;
  insert into public.sms_send_log (user_ref, verification_id, phone_hmac, prefix_hmac)
  values (p_user, v_id, p_phone_hmac, p_prefix_hmac);
  return v_id;
end $$;

-- Sprawdzenie kodu. Błędny kod zwraca false BEZ wyjątku – licznik prób musi zostać zapisany (wyjątek
-- wycofałby transakcję); po 5 błędach kod wygasa. SEC-18: limit kont na numer liczony pod blokadą numeru
-- (dwie równoczesne weryfikacje tego samego numeru nie przekroczą limitu).
create or replace function public.app_phone_verify_code(p_user uuid, p_verification uuid, p_code_hmac text)
returns boolean
language plpgsql set search_path = '' as $$
declare
  v public.phone_verifications%rowtype;
  s public.app_settings%rowtype;
begin
  select * into v from public.phone_verifications
   where id = p_verification and user_id = p_user
   for update;
  if not found or v.verified_at is not null or v.expires_at <= now() or v.attempts >= 5 then
    raise exception 'sms: kod wygasł albo został już użyty – poproś o nowy';
  end if;
  if v.code_hmac is distinct from p_code_hmac then
    update public.phone_verifications
       set attempts = attempts + 1,
           expires_at = case when attempts + 1 >= 5 then now() else expires_at end
     where id = v.id;
    return false;
  end if;
  perform pg_advisory_xact_lock(hashtext('ph:' || v.phone_hmac));
  select * into s from public.app_settings;
  if (select count(*) from public.user_phones p
       where p.phone_hmac = v.phone_hmac and p.user_id <> p_user) >= s.accounts_per_number then
    raise exception 'sms: limit wysyłek kodów – spróbuj później' using errcode = 'BP429';
  end if;
  update public.phone_verifications set verified_at = now() where id = v.id;
  update public.sms_send_log set verified_at = now() where verification_id = v.id;
  insert into public.user_phones (user_id, phone_hmac, phone_last3, verified_at)
  values (p_user, v.phone_hmac, v.phone_last3, now())
  on conflict (user_id) do update
    set phone_hmac = excluded.phone_hmac, phone_last3 = excluded.phone_last3, verified_at = excluded.verified_at;
  insert into public.client_audit_log (actor, action, entity, entity_id)
  values ('user:' || p_user::text, 'phone_verified', 'phone', p_user);
  return true;
end $$;


-- 10.23 „Szukam pracy” (P1a – aktywne od startu). Konto osoby: e-mail (Auth) + telefon (SMS) + 18+.
create or replace function public.app_job_seeker_register(
  p_user uuid, p_adult_confirmed boolean, p_terms_version text, p_notice_version text)
returns void
language plpgsql set search_path = '' as $$
declare
  v_rows integer;
begin
  perform public.app_require_feature('szukam_pracy');
  if exists (select 1 from public.admin_users u where u.user_id = p_user) then
    raise exception 'szukam-pracy: konto personelu nie może być kontem osoby szukającej pracy';
  end if;
  if p_adult_confirmed is not true then
    raise exception 'szukam-pracy: konto może założyć wyłącznie osoba pełnoletnia';
  end if;
  if not exists (select 1 from public.user_phones p where p.user_id = p_user) then
    raise exception 'szukam-pracy: najpierw potwierdź numer telefonu';
  end if;
  insert into public.job_seekers (user_id, adult_confirmed, terms_version, notice_version)
  values (p_user, true, p_terms_version, p_notice_version)
  on conflict (user_id) do nothing;
  get diagnostics v_rows = row_count;
  if v_rows > 0 then
    insert into public.client_audit_log (actor, action, entity, entity_id)
    values ('user:' || p_user::text, 'job_seeker_registered', 'job_seeker', p_user);
  end if;
end $$;

-- Walidacja treści PRZED zapisem (PRIV-12): te same reguły co CHECK w tabeli plus dostępność najwyżej rok
-- naprzód. Naruszenie CHECK zwróciłoby w DETAIL cały wiersz („Failing row contains …” – imię, opis), który
-- trafiłby do logów Postgresa, Workera i Sentry; tu komunikat zawiera tylko nazwę pola, kod BP422.
create or replace function public.candidate_ad_check_payload(p_payload jsonb)
returns void
language plpgsql stable set search_path = '' as $$
declare
  v_field text;
  v_desc  text := coalesce(p_payload ->> 'description', '');
  v_city  text := nullif(trim(p_payload ->> 'city'), '');
begin
  v_field := case
    when coalesce(trim(p_payload ->> 'first_name'), '')
         !~ '^[^[:space:][:digit:][:punct:]]{2,30}(-[^[:space:][:digit:][:punct:]]{2,30})?$' then 'first_name'
    when coalesce(p_payload ->> 'profession', '') not in ('kosmetolog','fryzjer','podolog','linergistka',
         'stylistka-paznokci','tatuazysta','recepcja','inny') then 'profession'
    when v_city is not null and (char_length(v_city) not between 2 and 80 or v_city ~ '[[:digit:]<>@]') then 'city'
    when coalesce(p_payload ->> 'voivodeship', '') not in ('dolnoslaskie','kujawsko-pomorskie','lubelskie',
         'lubuskie','lodzkie','malopolskie','mazowieckie','opolskie','podkarpackie','podlaskie','pomorskie',
         'slaskie','swietokrzyskie','warminsko-mazurskie','wielkopolskie','zachodniopomorskie') then 'voivodeship'
    when jsonb_typeof(p_payload -> 'cooperation_forms') is distinct from 'array'
         or jsonb_array_length(p_payload -> 'cooperation_forms') not between 1 and 5
         or not (array(select jsonb_array_elements_text(p_payload -> 'cooperation_forms'))
                 <@ array['umowa-o-prace','umowa-zlecenie','b2b','najem-stanowiska','inna']) then 'cooperation_forms'
    when coalesce(p_payload ->> 'experience', '') not in ('do-1-roku','1-3-lata','3-5-lat','powyzej-5-lat') then 'experience'
    when coalesce(p_payload ->> 'available_from', '') !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' then 'available_from'
    when char_length(v_desc) > 500 or v_desc ~ '[<>@]' or v_desc ~* '(https?://|www\.)'
         or v_desc ~ '[0-9][0-9 ()./-]{6,}[0-9]' then 'description'
    -- zabiegi (00, D41): opcjonalne; tablica identyfikatorów z listy (aktywne albo wycofane – to, czy nowo
    -- dodane są aktywne, sprawdza app_candidate_ad_save() względem zapisanego ogłoszenia), najwyżej 30 różnych
    when p_payload ? 'zabiegi' and (
         jsonb_typeof(p_payload -> 'zabiegi') is distinct from 'array'
         or exists (select 1 from jsonb_array_elements(p_payload -> 'zabiegi') e where jsonb_typeof(e) <> 'string')
         or not (array(select jsonb_array_elements_text(p_payload -> 'zabiegi')) <@ public.zabiegi_ids())
         or (select count(distinct e) from jsonb_array_elements_text(p_payload -> 'zabiegi') e) > 30) then 'zabiegi'
  end;
  if v_field is null and (p_payload ->> 'available_from')::date > current_date + 365 then
    v_field := 'available_from';
  end if;
  if v_field is not null then
    raise exception 'szukam-pracy: nieprawidłowe pole %', v_field using errcode = 'BP422';
  end if;
end $$;

-- Dodanie albo zmiana własnego ogłoszenia (jedno na konto). Każdy zapis trafia do moderacji
-- (ogłoszenie znika z tablicy do akceptacji), content_version rośnie – decyzja moderatora dla starszej
-- wersji kończy się wyjątkiem. Wygasłe ogłoszenie „odnawia się” tym samym zapisem (ponowna moderacja).
-- Ogłoszenie usunięte przez moderację można przywrócić tylko po odwołaniu (personel).
create or replace function public.app_candidate_ad_save(p_actor uuid, p_payload jsonb, p_notice_version text)
returns uuid
language plpgsql set search_path = '' as $$
declare
  v_ad  public.candidate_ads%rowtype;
  v_id  uuid;
  v_zab text[];
begin
  perform public.app_require_feature('szukam_pracy');
  if not exists (select 1 from public.job_seekers s where s.user_id = p_actor and s.status = 'active')
     or not exists (select 1 from public.user_phones p where p.user_id = p_actor) then
    raise exception 'szukam-pracy: brak aktywnego konta osoby szukającej pracy';
  end if;
  perform public.candidate_ad_check_payload(p_payload);
  select * into v_ad from public.candidate_ads where seeker_id = p_actor for update;
  -- zabiegi (00, D41): bez powtórzeń, posortowane; nowo dodane – tylko aktywne (wycofana pozycja zostaje
  -- wyłącznie w ogłoszeniu, które już ją ma)
  v_zab := array(select distinct e from jsonb_array_elements_text(coalesce(p_payload -> 'zabiegi', '[]'::jsonb)) e
                  order by e);
  if exists (select 1 from unnest(v_zab) z
              where z <> all (coalesce(v_ad.zabiegi, '{}'::text[])) and z <> all (public.zabiegi_ids(true))) then
    raise exception 'szukam-pracy: nieprawidłowe pole zabiegi' using errcode = 'BP422';
  end if;
  if v_ad.id is null then
    insert into public.candidate_ads
      (seeker_id, first_name, profession, city, voivodeship, cooperation_forms, experience, available_from,
       description, zabiegi, notice_version, submitted_at)
    values (p_actor, trim(p_payload ->> 'first_name'), p_payload ->> 'profession', nullif(trim(p_payload ->> 'city'), ''),
            p_payload ->> 'voivodeship',
            array(select jsonb_array_elements_text(p_payload -> 'cooperation_forms')),
            p_payload ->> 'experience', (p_payload ->> 'available_from')::date,
            nullif(trim(p_payload ->> 'description'), ''), v_zab, p_notice_version, now())
    returning id into v_id;
  else
    if v_ad.status = 'removed' then
      raise exception 'szukam-pracy: ogłoszenie usunięte przez moderację – odpowiedz na e-mail z uzasadnieniem, aby się odwołać';
    end if;
    update public.candidate_ads
       set first_name = trim(p_payload ->> 'first_name'), profession = p_payload ->> 'profession',
           city = nullif(trim(p_payload ->> 'city'), ''), voivodeship = p_payload ->> 'voivodeship',
           cooperation_forms = array(select jsonb_array_elements_text(p_payload -> 'cooperation_forms')),
           experience = p_payload ->> 'experience', available_from = (p_payload ->> 'available_from')::date,
           description = nullif(trim(p_payload ->> 'description'), ''), zabiegi = v_zab,
           notice_version = p_notice_version,
           content_version = content_version + 1, status = 'pending_review', submitted_at = now(),
           published_at = null, expires_at = null, rejection_reason = null, updated_at = now()
     where id = v_ad.id
    returning id into v_id;
  end if;
  insert into public.client_audit_log (actor, action, entity, entity_id)
  values ('user:' || p_actor::text, 'candidate_ad_submitted', 'candidate_ad', v_id);
  return v_id;
end $$;

-- Usunięcie ogłoszenia przez autora – działa ZAWSZE, także przy wyłączonym przełączniku (prawo do
-- usunięcia danych). Usuwa wiersz od razu, czyści niewysłane wiadomości pracodawców do autora; ślad
-- wysyłek traci odwołanie do ogłoszenia (ad_id → NULL), zgłoszenia dotyczące ogłoszenia znikają (cascade).
create or replace function public.app_candidate_ad_delete(p_actor uuid)
returns boolean
language plpgsql set search_path = '' as $$
declare
  v_id uuid;
begin
  select id into v_id from public.candidate_ads where seeker_id = p_actor for update;
  if v_id is null then
    return false;
  end if;
  update public.outbox_emails o
     set payload = '{}'::jsonb, recipient = 'anonymized',
         status = case when o.status = 'pending' then 'failed' else o.status end
   where o.template like 'candidate\_%' and o.recipient <> 'anonymized'
     and o.id in (select l.outbox_id from public.candidate_ad_contact_log l where l.ad_id = v_id);
  delete from public.candidate_ads where id = v_id;
  insert into public.client_audit_log (actor, action, entity, entity_id)
  values ('user:' || p_actor::text, 'candidate_ad_deleted', 'candidate_ad', v_id);
  return true;
end $$;

-- Zamknięcie konta osoby szukającej pracy (zawsze dostępne): ogłoszenie i konto „Szukam pracy” usunięte;
-- serwer usuwa potem użytkownika Auth (Admin API), jeśli nie ma on innych ról (pracodawca, salon).
create or replace function public.app_job_seeker_close(p_actor uuid)
returns void
language plpgsql set search_path = '' as $$
begin
  perform public.app_candidate_ad_delete(p_actor);
  delete from public.job_seekers where user_id = p_actor;
  if found then
    insert into public.client_audit_log (actor, action, entity, entity_id)
    values ('user:' || p_actor::text, 'job_seeker_closed', 'job_seeker', p_actor);
  end if;
end $$;

-- Moderacja (personel admin/agent; serwer sprawdza też app_is_staff w sesji aal2). Odrzucenie
-- i usunięcie wymagają uzasadnienia dla autora (art. 17 DSA [do weryfikacji przez prawnika]);
-- serwer wysyła je e-mailem candidate_ad_rejected / candidate_ad_removed. Publikacja na 21 dni (P1c).
create or replace function public.app_moderate_candidate_ad(
  p_ad uuid, p_actor uuid, p_decision text, p_expected_version integer,
  p_note text default null, p_reason text default null)
returns void
language plpgsql set search_path = '' as $$
declare
  v_ad   public.candidate_ads%rowtype;
  v_days smallint;
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
    if not exists (select 1 from public.job_seekers s where s.user_id = v_ad.seeker_id and s.status = 'active') then
      raise exception 'moderate: konto autora jest zawieszone';
    end if;
    v_days := public.promo_ad_days();
    update public.candidate_ads
       set status = 'published', published_at = now(), expires_at = now() + make_interval(days => v_days),
           ad_ref = gen_random_uuid(),                -- PRIV-07: nowy identyfikator przy każdej publikacji
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

-- Lista kart „Szukam pracy” dla pracodawcy (SEC-01) – JEDYNA droga odczytu ogłoszeń przez pracodawców.
-- Warunki: włączony przełącznik; employer_trusted_actor() (właściciel aktywnego konta, GUS ≤ 120 dni,
-- telefon, poziom 2 zaufania – SEC-02; aal2 sprawdza serwer). Zwraca najwyżej 20 kart od najnowszej
-- publikacji (stronicowanie kursorem {"published_at","ad_ref"}), filtry wyłącznie z pól autora: zawód,
-- województwo, forma współpracy i zabiegi (00, D41: {"zabiegi":[…]} – karta, której autor wybrał CO NAJMNIEJ
-- JEDEN z podanych zabiegów; bez liczenia zgodności i bez zmiany kolejności; nieznany identyfikator → BP422
-- przed naliczeniem kwoty) (D-C: bez wyszukiwania, rankingu i dopasowywania). Pomija ogłoszenia
-- autorów, którzy ukryli NIP tej firmy (PRIV-07) albo zablokowali to konto (SEC-06). Każda zwrócona karta
-- zwiększa dzienny licznik konta (candidate_ad_views_daily); po przekroczeniu progu – jednorazowy alert do
-- zespołu, po wyczerpaniu kwoty – BP429 do końca doby (Założenie: 150 / 200 kart). Zwraca ad_ref, nigdy id.
create or replace function public.app_candidate_ads_page(
  p_actor uuid, p_account uuid, p_cursor jsonb default null, p_filters jsonb default '{}'::jsonb)
returns table (ad_ref uuid, first_name text, profession text, city text, voivodeship text,
               cooperation_forms text[], experience text, available_from date, description text,
               published_at timestamptz, zabiegi text[])
language plpgsql set search_path = '' as $$
declare
  s        public.app_settings%rowtype;
  v_nip    text;
  v_used   integer;
  v_limit  integer;
  v_rows   integer;
  v_zab    text[];
begin
  perform public.app_require_feature('szukam_pracy');
  if not public.employer_trusted_actor(p_account, p_actor) then
    raise exception 'szukam-pracy: brak uprawnień';
  end if;
  v_zab := public.zabiegi_filter(p_filters);
  select * into s from public.app_settings;
  select a.nip into v_nip from public.client_accounts a where a.id = p_account;
  perform pg_advisory_xact_lock(hashtext('cv:' || p_account::text));
  select coalesce(max(d.n), 0) into v_used from public.candidate_ad_views_daily d
   where d.account_id = p_account and d.day = current_date;
  v_limit := least(20, s.candidate_cards_per_day - v_used);
  if v_limit <= 0 then
    raise exception 'szukam-pracy: dzienny limit odsłon' using errcode = 'BP429';
  end if;

  return query
  select c.ad_ref, c.first_name, c.profession, c.city, c.voivodeship, c.cooperation_forms, c.experience,
         c.available_from, c.description, c.published_at, c.zabiegi
    from public.candidate_ads c
    join public.job_seekers j on j.user_id = c.seeker_id and j.status = 'active'
   where c.status = 'published' and c.expires_at > now()
     and (p_filters ->> 'profession' is null or c.profession = p_filters ->> 'profession')
     and (p_filters ->> 'voivodeship' is null or c.voivodeship = p_filters ->> 'voivodeship')
     and (p_filters ->> 'cooperation_form' is null or (p_filters ->> 'cooperation_form') = any (c.cooperation_forms))
     and (v_zab is null or c.zabiegi && v_zab)                    -- LUB: co najmniej jeden z wybranych (00, D41)
     and (p_cursor is null
          or (c.published_at, c.ad_ref) < ((p_cursor ->> 'published_at')::timestamptz, (p_cursor ->> 'ad_ref')::uuid))
     and not exists (select 1 from public.candidate_ad_hidden_nips h where h.seeker_id = c.seeker_id and h.nip = v_nip)
     and not exists (select 1 from public.candidate_blocks b where b.seeker_id = c.seeker_id and b.account_id = p_account)
   order by c.published_at desc, c.ad_ref desc
   limit v_limit;
  get diagnostics v_rows = row_count;

  insert into public.candidate_ad_views_daily as d (account_id, day, n)
  values (p_account, current_date, v_rows)
  on conflict (account_id, day) do update set n = d.n + excluded.n;
  if v_used + v_rows >= s.candidate_cards_alert
     and exists (select 1 from public.candidate_ad_views_daily d
                  where d.account_id = p_account and d.day = current_date and d.alerted_at is null) then
    update public.candidate_ad_views_daily set alerted_at = now()
     where account_id = p_account and day = current_date;
    insert into public.outbox_emails (template, recipient, payload, account_id)
    values ('candidate_views_alert', 'team:bezpieczenstwo',
            jsonb_build_object('cards_today', v_used + v_rows, 'quota', s.candidate_cards_per_day), p_account);
  end if;
end $$;

-- Wiadomość pracodawcy do autora ogłoszenia (formularz przekazujący). Tylko employer_trusted_actor()
-- (SEC-02; serwer sprawdza też aal2, Turnstile i limit Workers). Pracodawca nie widzi e-maila ani telefonu
-- autora: w outbox jest tylko znacznik odbiorcy 'user:<uuid>', adres rozwiązuje serwer przy wysyłce (Auth
-- Admin API). Reply-To – wyłącznie potwierdzony adres konta (SEC-05), a jego domena jest pokazana w e-mailu.
-- W e-mailu do autora: „Firma: {nazwa} – dane z rejestru REGON. BeautyPolisa sprawdziła, że firma istnieje,
-- nie tożsamość nadawcy” (SEC-02; bez słowa „zweryfikowany”), NIP i miejscowość, zasady bezpieczeństwa,
-- „Zgłoś wiadomość”, „Zablokuj tego pracodawcę”. Nazwa wyświetlana trafia do e-maila dopiero po akceptacji
-- personelu (inaczej nazwa z rejestru). Treść istnieje tylko w outbox do wysyłki (potem
-- app_purge_relay_messages); zostaje ślad bez treści (candidate_ad_contact_log).
-- SEC-06 – treść: bez adresów URL, znaczników, adresów e-mail, numerów telefonów i nazw komunikatorów
-- (kontakt wyłącznie przez Reply-To) – odmowa BP422; frazy ryzyka (opłata, kaucja, PESEL, skan dowodu,
-- paczki, przelew…) → wiadomość WSTRZYMANA do decyzji moderatora (next_attempt_at = 'infinity', najwyżej
-- 72 h, app_release_candidate_contact). Konto z ≥ 2 uzasadnionymi zgłoszeniami w 90 dni – wysyłki wstrzymane.
-- Limity [Założenie]: 1 wiadomość od pracodawcy do ogłoszenia (w okresie retencji śladu), 10 wiadomości do
-- ogłoszenia na dobę, na konto: 3 na dobę przez 14 dni od aktywacji albo do pierwszej opublikowanej oferty,
-- potem 20 na dobę; liczone pod blokadą konta (SEC-18).
create or replace function public.app_candidate_contact(p_ad uuid, p_account uuid, p_actor uuid, p_payload jsonb)
returns uuid
language plpgsql set search_path = '' as $$
declare
  s        public.app_settings%rowtype;
  v_ad     public.candidate_ads%rowtype;
  v_emp    public.client_accounts%rowtype;
  v_msg    text := coalesce(p_payload ->> 'message', '');
  v_reply  text := lower(trim(coalesce(p_payload ->> 'reply_to', '')));
  v_held   boolean;
  v_quota  integer;
  v_outbox uuid;
  v_log    uuid;
begin
  perform public.app_require_feature('szukam_pracy');
  if not public.employer_trusted_actor(p_account, p_actor) then
    raise exception 'candidate contact: brak uprawnień';
  end if;
  select * into v_emp from public.client_accounts a where a.id = p_account;
  perform pg_advisory_xact_lock(hashtext('cc:' || p_account::text));   -- SEC-18: limity konta bez wyścigu
  if (select count(*) from public.abuse_reports r
       where r.reported_account_id = p_account and r.outcome = 'uzasadnione'
         and r.handled_at > now() - interval '90 days') >= 2 then
    raise exception 'candidate contact: wysyłka wiadomości z konta jest wstrzymana';
  end if;
  -- p_ad = ad_ref z karty (identyfikator publikacji, nie wiersza)
  select c.* into v_ad from public.candidate_ads c
    join public.job_seekers j on j.user_id = c.seeker_id and j.status = 'active'
   where c.ad_ref = p_ad and c.status = 'published' and c.expires_at > now()
     and not exists (select 1 from public.candidate_ad_hidden_nips h where h.seeker_id = c.seeker_id and h.nip = v_emp.nip)
     and not exists (select 1 from public.candidate_blocks b where b.seeker_id = c.seeker_id and b.account_id = p_account)
   for update of c;
  if not found then
    raise exception 'candidate contact: ogłoszenie niedostępne';
  end if;
  if char_length(v_msg) not between 20 and 1000
     or v_msg ~ '[<>@]' or v_msg ~* '(https?://|www\.|\.(pl|com|eu|net|org)\M)'
     or v_msg ~ '(^|[^0-9])(\+?48[ .-]?)?([0-9]{3}[ .-]?[0-9]{3}[ .-]?[0-9]{3}|[0-9]{2}[ .-]?[0-9]{3}[ .-]?[0-9]{2}[ .-]?[0-9]{2})([^0-9]|$)'
     or v_msg ~* '(whats ?app|telegram|signal|viber|messenger|wechat|snapchat|instagram|insta\M|tik ?tok|facebook|t\.me|wa\.me)' then
    raise exception 'candidate contact: nieprawidłowa wiadomość' using errcode = 'BP422';
  end if;
  if not exists (select 1 from public.employer_reply_addresses r
                  where r.account_id = p_account and r.email_normalized = v_reply and r.verified_at is not null) then
    raise exception 'candidate contact: adres do odpowiedzi nie jest potwierdzonym adresem konta' using errcode = 'BP422';
  end if;
  if exists (select 1 from public.candidate_ad_contact_log l where l.ad_id = v_ad.id and l.account_id = p_account) then
    raise exception 'candidate contact: pracodawca już wysłał wiadomość do tego ogłoszenia';
  end if;
  select * into s from public.app_settings;
  v_quota := case when v_emp.activated_at > now() - interval '14 days'
                       and not exists (select 1 from public.job_offers o
                                        where o.account_id = p_account and o.published_at is not null)
                  then s.contact_new_account_per_day else s.contact_per_account_day end;
  if (select count(*) from public.candidate_ad_contact_log l
       where l.account_id = p_account and l.created_at > now() - interval '1 day') >= v_quota
     or (select count(*) from public.candidate_ad_contact_log l
          where l.ad_id = v_ad.id and l.created_at > now() - interval '1 day') >= 10 then
    raise exception 'candidate contact: dzienny limit wiadomości' using errcode = 'BP429';
  end if;
  v_held := v_msg ~* '(opłat|oplat|kaucj|wpłać|wplac|wpłat|wplat|przelew|pesel|skan|zdjęci[ae] dowodu|dowod[uy] osobist|paszport|karty płatnicz|blik|paczk|przesyłk|przesylk|kryptowalut|bitcoin)';

  v_log := gen_random_uuid();                   -- contact_id trafia do linków „Zgłoś wiadomość” i „Zablokuj”
  insert into public.outbox_emails (template, recipient, payload, account_id, next_attempt_at)
  values ('candidate_contact', 'user:' || v_ad.seeker_id::text,
          jsonb_build_object('employer_name', case when v_emp.display_name_approved_at is not null or v_emp.kind = 'client'
                                                   then v_emp.display_name else v_emp.legal_name end,
                             'employer_legal_name', v_emp.legal_name,
                             'employer_nip', v_emp.nip, 'employer_city', v_emp.city,
                             'reply_to', v_reply, 'reply_to_domain', split_part(v_reply, '@', 2),
                             'message', v_msg, 'contact_id', v_log, 'held', v_held),
          p_account, case when v_held then 'infinity'::timestamptz else now() end)
  returning id into v_outbox;
  insert into public.candidate_ad_contact_log (id, ad_id, account_id, sent_by, outbox_id)
  values (v_log, v_ad.id, p_account, p_actor, v_outbox);
  -- dziennik konta: tylko fakt wysyłki (bez odwołania do ogłoszenia i bez treści)
  insert into public.client_audit_log (account_id, actor, action, entity, payload)
  values (p_account, 'user:' || p_actor::text, 'candidate_contact_sent', 'candidate_ad',
          jsonb_build_object('held', v_held));
  return v_log;
end $$;

-- Decyzja moderatora o wiadomości wstrzymanej (SEC-06): 'send' – wysyłka; 'reject' – treść usunięta,
-- wiadomość nie wychodzi (pracodawca widzi tylko, że nie została przekazana). Tylko admin/agent.
create or replace function public.app_release_candidate_contact(p_contact uuid, p_actor uuid, p_decision text)
returns void
language plpgsql set search_path = '' as $$
declare
  v_outbox uuid;
begin
  if not exists (select 1 from public.admin_users u
                 where u.user_id = p_actor and u.is_active and u.role in ('admin','agent')) then
    raise exception 'release: brak uprawnień';
  end if;
  select l.outbox_id into v_outbox from public.candidate_ad_contact_log l
    join public.outbox_emails o on o.id = l.outbox_id
   where l.id = p_contact and o.status = 'pending' and o.next_attempt_at = 'infinity';
  if v_outbox is null then
    raise exception 'release: brak wstrzymanej wiadomości';
  end if;
  if p_decision = 'send' then
    update public.outbox_emails set next_attempt_at = now() where id = v_outbox;
  elsif p_decision = 'reject' then
    update public.outbox_emails set payload = '{}'::jsonb, recipient = 'anonymized', status = 'failed'
     where id = v_outbox;
  else
    raise exception 'release: nieznana decyzja';
  end if;
end $$;

-- „Zablokuj tego pracodawcę” (SEC-06) – link z contact_id w e-mailu do autora (w zalogowanej sesji autora).
create or replace function public.app_candidate_block_employer(p_actor uuid, p_contact uuid)
returns boolean
language plpgsql set search_path = '' as $$
declare
  v_account uuid;
begin
  perform public.app_require_feature('szukam_pracy');
  select l.account_id into v_account from public.candidate_ad_contact_log l
    join public.candidate_ads c on c.id = l.ad_id
   where l.id = p_contact and c.seeker_id = p_actor;
  if v_account is null then
    return false;
  end if;
  insert into public.candidate_blocks (seeker_id, account_id) values (p_actor, v_account)
  on conflict do nothing;
  -- niewysłane wiadomości tego pracodawcy do autora nie wychodzą
  update public.outbox_emails o
     set payload = '{}'::jsonb, recipient = 'anonymized', status = 'failed'
   where o.account_id = v_account and o.template = 'candidate_contact' and o.status = 'pending'
     and o.recipient = 'user:' || p_actor::text;
  return true;
end $$;

-- „Ukryj moje ogłoszenie przed firmami o NIP …” (PRIV-07) – autor zastępuje całą listę (najwyżej 10 NIP).
create or replace function public.app_candidate_hidden_nips_set(p_actor uuid, p_nips text[])
returns integer
language plpgsql set search_path = '' as $$
declare
  v_nips text[] := array(select distinct regexp_replace(n, '[^0-9]', '', 'g')
                           from unnest(coalesce(p_nips, '{}'::text[])) n);
begin
  perform public.app_require_feature('szukam_pracy');
  if not exists (select 1 from public.job_seekers s where s.user_id = p_actor) then
    raise exception 'szukam-pracy: brak konta osoby szukającej pracy';
  end if;
  if cardinality(v_nips) > 10
     or exists (select 1 from unnest(v_nips) n where not public.nip_checksum_ok(n)) then
    raise exception 'szukam-pracy: nieprawidłowa lista NIP' using errcode = 'BP422';
  end if;
  delete from public.candidate_ad_hidden_nips where seeker_id = p_actor;
  insert into public.candidate_ad_hidden_nips (seeker_id, nip) select p_actor, n from unnest(v_nips) n;
  return cardinality(v_nips);
end $$;

-- „Zgłoś” przy ogłoszeniu (pracodawca; p_ad = ad_ref z karty). DSA-13: powód, uzasadnienie ≥ 20 znaków,
-- oświadczenie o dobrej wierze; imię i nazwisko oraz e-mail zgłaszającego – opcjonalne.
create or replace function public.app_report_candidate_ad(
  p_ad uuid, p_reason text, p_details text default null, p_reporter_email text default null,
  p_good_faith boolean default false, p_reporter_name text default null)
returns bigint
language plpgsql set search_path = '' as $$
declare
  v_ad uuid;
  v_id bigint;
begin
  perform public.app_require_feature('szukam_pracy');
  select a.id into v_ad from public.candidate_ads a where a.ad_ref = p_ad and a.status = 'published';
  if v_ad is null then
    raise exception 'report: ogłoszenie niedostępne';
  end if;
  perform public.abuse_report_check(p_reason, p_details, p_reporter_email, p_good_faith, p_reporter_name);
  insert into public.abuse_reports (target, candidate_ad_id, reason, details, good_faith, reporter_name, reporter_email)
  values ('candidate_ad', v_ad, p_reason, trim(p_details), true, nullif(trim(p_reporter_name), ''),
          nullif(lower(trim(p_reporter_email)), ''))
  returning id into v_id;
  return v_id;
end $$;

-- „Zgłoś wiadomość” z e-maila do autora ogłoszenia (link z contact_id). Zgłoszenie wskazuje pracodawcę
-- (reported_account_id) i przetrwa usunięcie śladu wysyłki po 30 dniach.
create or replace function public.app_report_candidate_contact(
  p_contact uuid, p_reason text, p_details text default null, p_reporter_email text default null,
  p_good_faith boolean default false, p_reporter_name text default null)
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
  perform public.abuse_report_check(p_reason, p_details, p_reporter_email, p_good_faith, p_reporter_name);
  insert into public.abuse_reports (target, candidate_contact_id, reported_account_id, reason, details, good_faith,
                                    reporter_name, reporter_email)
  values ('candidate_contact', p_contact, v_account, p_reason, trim(p_details), true,
          nullif(trim(p_reporter_name), ''), nullif(lower(trim(p_reporter_email)), ''))
  returning id into v_id;
  return v_id;
end $$;

-- Walidacja zgłoszenia przed zapisem (PRIV-12, DSA-13) – komunikat bez wartości, kod BP422. Serwer używa
-- tej samej funkcji przed zapisem zgłoszeń ofert, szkoleń, organizatorów i pracodawców (service_role).
create or replace function public.abuse_report_check(
  p_reason text, p_details text, p_reporter_email text, p_good_faith boolean, p_reporter_name text)
returns void
language plpgsql immutable set search_path = '' as $$
begin
  if p_reason is null or p_reason not in ('nieaktualne','dyskryminacja','oszustwo','oplata-za-prace',
       'podszywanie','phishing','spam','nielegalne','niepelnoletnia','inne') then
    raise exception 'report: nieprawidłowy powód' using errcode = 'BP422';
  end if;
  if coalesce(char_length(trim(p_details)), 0) not between 20 and 1000 or trim(p_details) ~ '[<>]' then
    raise exception 'report: uzasadnienie zgłoszenia musi mieć od 20 do 1000 znaków' using errcode = 'BP422';
  end if;
  if p_good_faith is not true then
    raise exception 'report: wymagane oświadczenie o dobrej wierze' using errcode = 'BP422';
  end if;
  if nullif(trim(p_reporter_email), '') is not null
     and (lower(trim(p_reporter_email)) !~ '^[^@[:space:]<>]+@[^@[:space:]<>]+\.[a-z]{2,}$'
          or char_length(trim(p_reporter_email)) > 254) then
    raise exception 'report: nieprawidłowy adres e-mail' using errcode = 'BP422';
  end if;
  if nullif(trim(p_reporter_name), '') is not null
     and (char_length(trim(p_reporter_name)) not between 2 and 120 or trim(p_reporter_name) ~ '[<>@]') then
    raise exception 'report: nieprawidłowe imię i nazwisko' using errcode = 'BP422';
  end if;
end $$;

-- Retencja (cron, codziennie) – działa także przy wyłączonym przełączniku. Wygaszanie po 21 dniach
-- (P1c); [Założenie] wygasłe, odrzucone i usunięte moderacyjnie – usunięte 30 dni po ostatniej zmianie
-- (czas na odwołanie od decyzji); ślad wysyłek – 30 dni.
create or replace function public.app_purge_candidate_ads()
returns integer
language plpgsql set search_path = '' as $$
declare
  v_count integer;
begin
  update public.candidate_ads set status = 'expired', updated_at = now()
   where status = 'published' and expires_at <= now();
  delete from public.candidate_ads
   where status in ('expired','rejected','removed') and updated_at < now() - interval '30 days';
  get diagnostics v_count = row_count;
  -- PRIV-14 [Założenie]: ogłoszenie bez decyzji moderacji przez 30 dni (np. przy wyłączonym przełączniku
  -- moderacja odpowiada BP404) – usunięte, autor dostaje e-mail
  with gone as (
    delete from public.candidate_ads
     where status = 'pending_review' and coalesce(submitted_at, updated_at) < now() - interval '30 days'
    returning seeker_id
  )
  insert into public.outbox_emails (template, recipient, payload)
  select 'candidate_ad_purged', 'user:' || seeker_id::text, '{}'::jsonb from gone;
  delete from public.candidate_ad_contact_log where created_at < now() - interval '30 days';
  delete from public.candidate_ad_views_daily where day < current_date - 30;
  return v_count;
end $$;


-- 10.24 Plany organizatorów (P1d). Ceny z aktywnej promocji (10 000 zł netto / 12 mies., 1 000 zł netto
--       / mies.); bez aktywnej promocji – BP409 (cennik po promocji do ustalenia). Faktura poza portalem
--       [Założenie]; personel wpisuje numer faktury, gdy jest znany.
-- Koniec ciągłej ważności aktywnych planów (plany stykające się lub nakładające łączą się w jeden okres).
create or replace function public.organizer_plan_until(p_organizer uuid)
returns timestamptz
language plpgsql stable set search_path = '' as $$
declare
  v_until timestamptz;
  r       record;
begin
  for r in select p.valid_from, p.valid_until from public.organizer_plans p
            where p.organizer_id = p_organizer and p.status = 'active' and p.valid_until > now()
            order by p.valid_from
  loop
    exit when r.valid_from > coalesce(v_until, now());       -- przerwa w ciągłości planów
    v_until := greatest(coalesce(v_until, r.valid_until), r.valid_until);
  end loop;
  return v_until;
end $$;

-- Migawka ważności planu w szkoleniach organizatora (RLS katalogu i zapisy jej używają)
create or replace function public.organizer_plan_sync(p_organizer uuid)
returns timestamptz
language plpgsql set search_path = '' as $$
declare
  v_until timestamptz := public.organizer_plan_until(p_organizer);
begin
  update public.trainings set plan_valid_until = v_until
   where organizer_id = p_organizer and status in ('published','cancelled')
     and plan_valid_until is distinct from v_until;
  return v_until;
end $$;

create or replace function public.app_set_organizer_plan(
  p_organizer uuid, p_actor uuid, p_plan_code text, p_valid_from timestamptz, p_invoice_ref text default null)
returns uuid
language plpgsql set search_path = '' as $$
declare
  v_promo public.app_promotions%rowtype;
  v_price numeric(10,2);
  v_id    uuid;
begin
  if not exists (select 1 from public.admin_users u
                 where u.user_id = p_actor and u.is_active and u.role in ('admin','agent')) then
    raise exception 'plan: brak uprawnień';
  end if;
  if not exists (select 1 from public.training_organizers o
                  where o.id = p_organizer and o.status = 'active' and o.verified_at is not null) then
    raise exception 'plan: organizator niezweryfikowany albo zawieszony';
  end if;
  if p_valid_from is null or p_valid_from < now() - interval '1 day' then
    raise exception 'plan: data początku nie może być w przeszłości';
  end if;
  select * into v_promo from public.app_promotions p
   where p.enabled and p.starts_at <= now() and (p.ends_at is null or p.ends_at > now())
   order by p.starts_at desc limit 1;
  if not found then
    raise exception 'plan: cennik planów po promocji – do ustalenia' using errcode = 'BP409';
  end if;
  v_price := case p_plan_code when 'promo-12m' then v_promo.organizer_12m_net_pln
                              when 'promo-1m'  then v_promo.organizer_1m_net_pln end;
  if v_price is null then
    raise exception 'plan: nieznany plan %', p_plan_code;
  end if;
  insert into public.organizer_plans (organizer_id, plan_code, price_net_pln, valid_from, valid_until, invoice_ref, set_by)
  values (p_organizer, p_plan_code, v_price, p_valid_from,
          p_valid_from + case p_plan_code when 'promo-12m' then interval '12 months' else interval '1 month' end,
          nullif(trim(p_invoice_ref), ''), p_actor)
  returning id into v_id;
  perform public.organizer_plan_sync(p_organizer);
  insert into public.client_audit_log (organizer_id, actor, action, entity, entity_id, payload)
  values (p_organizer, 'staff:' || p_actor::text, 'organizer_plan_set', 'organizer_plan', v_id,
          jsonb_build_object('plan', p_plan_code, 'price_net_pln', v_price));
  return v_id;
end $$;

create or replace function public.app_cancel_organizer_plan(p_plan uuid, p_actor uuid, p_reason text)
returns void
language plpgsql set search_path = '' as $$
declare
  v_org uuid;
begin
  if not exists (select 1 from public.admin_users u
                 where u.user_id = p_actor and u.is_active and u.role in ('admin','agent')) then
    raise exception 'plan: brak uprawnień';
  end if;
  update public.organizer_plans
     set status = 'cancelled', cancelled_at = now(), cancelled_by = p_actor
   where id = p_plan and status = 'active'
  returning organizer_id into v_org;
  if v_org is null then
    raise exception 'plan: brak aktywnego planu';
  end if;
  perform public.organizer_plan_sync(v_org);
  insert into public.client_audit_log (organizer_id, actor, action, entity, entity_id, payload)
  values (v_org, 'staff:' || p_actor::text, 'organizer_plan_cancelled', 'organizer_plan', p_plan,
          jsonb_build_object('reason', left(coalesce(p_reason, ''), 200)));
end $$;

-- Numer faktury wpisany po wystawieniu (BIZ-15): bez niego plan wygasa po 14 dniach (app_sync_organizer_plans).
create or replace function public.app_set_organizer_plan_invoice(p_plan uuid, p_actor uuid, p_invoice_ref text)
returns void
language plpgsql set search_path = '' as $$
declare
  v_org uuid;
begin
  if not exists (select 1 from public.admin_users u
                 where u.user_id = p_actor and u.is_active and u.role in ('admin','agent')) then
    raise exception 'plan: brak uprawnień';
  end if;
  if coalesce(char_length(trim(p_invoice_ref)), 0) not between 3 and 60 or p_invoice_ref ~ '[<>]' then
    raise exception 'plan: nieprawidłowy numer faktury' using errcode = 'BP422';
  end if;
  update public.organizer_plans set invoice_ref = trim(p_invoice_ref)
   where id = p_plan and status = 'active'
  returning organizer_id into v_org;
  if v_org is null then
    raise exception 'plan: brak aktywnego planu';
  end if;
  insert into public.client_audit_log (organizer_id, actor, action, entity, entity_id)
  values (v_org, 'staff:' || p_actor::text, 'organizer_plan_invoice_set', 'organizer_plan', p_plan);
end $$;

-- Cron (co godzinę – BIZ-15, żeby katalog i cache znikały w chwili końca planu, a nie raz na dobę):
-- plany bez numeru faktury po 14 dniach od ustawienia wygasają [Założenie – decyzja zleceniodawcy Q16];
-- plany zaczynające się po przerwie w ciągłości stają się widoczne bez ręcznej akcji. Serwer po wywołaniu
-- unieważnia tagi cache katalogu (revalidateTag('trainings')) dla organizatorów, których ważność się zmieniła.
create or replace function public.app_sync_organizer_plans()
returns integer
language plpgsql set search_path = '' as $$
declare
  v_count integer := 0;
  r       record;
begin
  with gone as (
    update public.organizer_plans
       set status = 'cancelled', cancelled_at = now()
     where status = 'active' and invoice_ref is null and created_at < now() - interval '14 days'
    returning id, organizer_id
  )
  insert into public.client_audit_log (organizer_id, actor, action, entity, entity_id, payload)
  select organizer_id, 'system:cron', 'organizer_plan_cancelled', 'organizer_plan', id,
         jsonb_build_object('reason', 'brak numeru faktury po 14 dniach')
    from gone;
  for r in select distinct p.organizer_id from public.organizer_plans p loop
    perform public.organizer_plan_sync(r.organizer_id);
    v_count := v_count + 1;
  end loop;
  return v_count;
end $$;


-- 10.25 Retencja danych weryfikacji (cron, codziennie) [Założenie: okresy]:
--       kody SMS i licznik wysyłek – 30 dni; nieukończone rejestracje pracodawców (SEC-03) – zamknięte 24 h
--       po ostatnim wyniku GUS albo po założeniu, gdy wyniku nie ma (7 dni, gdy ostatni wynik to błąd usługi
--       i czeka ręczna weryfikacja); wiersz konta zostaje ze względu na dziennik audytu, ale bez nazwy z GUS;
--       wyniki GUS – ostatni na konto + 12 miesięcy, a dla kont zamkniętych – wszystkie 12 miesięcy po
--       zamknięciu (PRIV-14); niepotwierdzone adresy pracodawców – 7 dni; e-mail zgłaszającego nadużycie –
--       30 dni po obsłużeniu; uzasadnienie zgłoszenia i imię zgłaszającego – 12 miesięcy po obsłużeniu (PRIV-14).
create or replace function public.app_purge_verification_data()
returns integer
language plpgsql set search_path = '' as $$
declare
  v_total integer := 0;
  v_n     integer;
begin
  delete from public.phone_verifications where created_at < now() - interval '30 days';
  get diagnostics v_n = row_count; v_total := v_total + v_n;
  delete from public.sms_send_log where created_at < now() - interval '30 days';
  get diagnostics v_n = row_count; v_total := v_total + v_n;

  with last_check as (
    select a.id,
           (select v.checked_at from public.employer_verifications v
             where v.account_id = a.id order by v.checked_at desc limit 1) as checked_at,
           (select v.result from public.employer_verifications v
             where v.account_id = a.id order by v.checked_at desc limit 1) as result
      from public.client_accounts a
     where a.kind = 'employer' and a.status = 'pending'
  ), stale as (
    update public.client_accounts a
       set status = 'closed', closed_at = now(), legal_name = null, city = null,
           employer_verified_at = null, updated_at = now()
      from last_check l
     where a.id = l.id
       and greatest(a.created_at, l.checked_at)
           < now() - case when l.result = 'blad-uslugi' then interval '7 days' else interval '24 hours' end
    returning a.id
  ), members as (
    update public.client_members m set status = 'revoked', revoked_at = now()
      from stale where m.account_id = stale.id and m.status = 'active'
    returning 1
  )
  delete from public.employer_verifications v using stale where v.account_id = stale.id;
  get diagnostics v_n = row_count; v_total := v_total + v_n;

  delete from public.employer_verifications v
   where v.checked_at < now() - interval '12 months'
     and v.id <> (select v2.id from public.employer_verifications v2
                   where v2.account_id = v.account_id order by v2.checked_at desc limit 1);
  get diagnostics v_n = row_count; v_total := v_total + v_n;
  delete from public.employer_verifications v
   using public.client_accounts a
   where a.id = v.account_id and a.status = 'closed' and a.closed_at < now() - interval '12 months';
  get diagnostics v_n = row_count; v_total := v_total + v_n;

  delete from public.employer_reply_addresses
   where verified_at is null and created_at < now() - interval '7 days';
  get diagnostics v_n = row_count; v_total := v_total + v_n;

  update public.abuse_reports set reporter_email = null
   where reporter_email is not null and handled_at < now() - interval '30 days';
  get diagnostics v_n = row_count; v_total := v_total + v_n;
  update public.abuse_reports set details = null, reporter_name = null, anonymized_at = now()
   where anonymized_at is null and handled_at < now() - interval '12 months';
  get diagnostics v_n = row_count; v_total := v_total + v_n;
  return v_total;
end $$;

-- 10.26 Konta nieużywane (cron, codziennie; PRIV-14) [Założenie: okresy]. Osoba szukająca pracy bez
--       logowania 12 miesięcy, konto pracodawcy z rejestracji bez logowania właściciela 24 miesiące:
--       najpierw e-mail z ostrzeżeniem (account_inactive_warning), po 30 dniach bez logowania – zamknięcie
--       (ogłoszenie i konto „Szukam pracy” usunięte; konto pracodawcy zamknięte, oferty zdjęte, członkostwa
--       odebrane). Serwer usuwa potem użytkowników Auth bez żadnej roli (Admin API). last_seen_at ustawia
--       serwer przy logowaniu; konta salonów z polisą – D-B (bez zamykania; dokumenty – Q5).
create or replace function public.app_purge_inactive_accounts()
returns integer
language plpgsql set search_path = '' as $$
declare
  v_total integer := 0;
  r       record;
begin
  -- ostrzeżenia
  with warn as (
    update public.job_seekers s set inactivity_warned_at = now()
     where s.inactivity_warned_at is null
       and coalesce(s.last_seen_at, s.created_at) < now() - interval '12 months'
    returning s.user_id
  )
  insert into public.outbox_emails (template, recipient, payload)
  select 'account_inactive_warning', 'user:' || user_id::text, jsonb_build_object('days', 30) from warn;
  with warn as (
    update public.client_accounts a set inactivity_warned_at = now()
     where a.kind = 'employer' and a.status in ('active','suspended') and a.inactivity_warned_at is null
       and coalesce((select max(m.last_seen_at) from public.client_members m
                      where m.account_id = a.id and m.role = 'owner'), a.activated_at, a.created_at)
           < now() - interval '24 months'
    returning a.id
  )
  insert into public.outbox_emails (template, recipient, payload, account_id)
  select 'account_inactive_warning', 'user:' || m.user_id::text, jsonb_build_object('days', 30), w.id
    from warn w join public.client_members m on m.account_id = w.id and m.role = 'owner' and m.status = 'active';

  -- zamknięcia po 30 dniach od ostrzeżenia bez logowania (logowanie zeruje inactivity_warned_at – serwer)
  for r in select s.user_id from public.job_seekers s
            where s.inactivity_warned_at < now() - interval '30 days'
              and coalesce(s.last_seen_at, s.created_at) < s.inactivity_warned_at loop
    perform public.app_candidate_ad_delete(r.user_id);
    delete from public.job_seekers where user_id = r.user_id;
    insert into public.client_audit_log (actor, action, entity, entity_id, payload)
    values ('system:cron', 'job_seeker_closed', 'job_seeker', r.user_id, jsonb_build_object('reason', 'nieaktywne'));
    v_total := v_total + 1;
  end loop;
  for r in select a.id from public.client_accounts a
            where a.kind = 'employer' and a.status in ('active','suspended')
              and a.inactivity_warned_at < now() - interval '30 days'
              and coalesce((select max(m.last_seen_at) from public.client_members m
                             where m.account_id = a.id and m.role = 'owner'), a.created_at) < a.inactivity_warned_at loop
    perform set_config('app.audit_actor', 'system:cron', true);
    perform public.account_content_takedown(r.id, 'system:cron', 'Konto nieużywane przez 24 miesiące.', true);
    update public.client_accounts set status = 'closed', closed_at = now(), updated_at = now() where id = r.id;
    update public.client_members set status = 'revoked', revoked_at = now() where account_id = r.id and status = 'active';
    v_total := v_total + 1;
  end loop;
  return v_total;
end $$;

-- 10.27 Płatności za szkolenia (00, D42; dok. 11 §12a). Sprzedawcą jest organizator; operator płatności
--       (adapter PaymentProvider w Workerze) przyjmuje środki na konto organizatora. Kolejność blokad we
--       wszystkich funkcjach: blokada doradcza użytkownika → wiersz szkolenia → zamówienie → płatność/zwrot
--       (bez zakleszczeń). Kody błędów: BP422 – dane (tylko nazwa pola), BP409 – stan nie pozwala,
--       BP429 – limit; brak uprawnień – zwykły wyjątek. Wszystkie funkcje: EXECUTE tylko service_role.

-- Stawka prowizji obowiązująca w chwili p_at (migawka do zamówienia)
create or replace function public.platform_fee_current(p_at timestamptz default now())
returns public.platform_fee_settings
language sql stable set search_path = '' as $$
  select f.* from public.platform_fee_settings f where f.valid_from <= p_at order by f.valid_from desc limit 1;
$$;

-- Zmiana prowizji: tylko admin, z odwołaniem do decyzji zleceniodawcy, bez działania wstecz. Decyzja 00, D42:
-- w okresie promocji „otwarcie-portalu” prowizja wynosi 0 % (BP409 dla stawki > 0 przed końcem promocji).
create or replace function public.app_set_platform_fee(
  p_actor uuid, p_fee_bps integer, p_fee_fixed_grosze integer, p_valid_from timestamptz, p_decision_ref text)
returns uuid
language plpgsql set search_path = '' as $$
declare
  v_id uuid;
begin
  if not exists (select 1 from public.admin_users u where u.user_id = p_actor and u.is_active and u.role = 'admin') then
    raise exception 'fee: brak uprawnień';
  end if;
  if p_fee_bps is null or p_fee_bps not between 0 and 3000 then
    raise exception 'fee: nieprawidłowe pole fee_bps' using errcode = 'BP422';
  elsif p_fee_fixed_grosze is null or p_fee_fixed_grosze not between 0 and 10000 then
    raise exception 'fee: nieprawidłowe pole fee_fixed_grosze' using errcode = 'BP422';
  elsif p_valid_from is null or p_valid_from < now() - interval '1 minute' then
    raise exception 'fee: nieprawidłowe pole valid_from' using errcode = 'BP422';      -- bez działania wstecz
  elsif coalesce(char_length(trim(p_decision_ref)), 0) not between 5 and 200 then
    raise exception 'fee: nieprawidłowe pole decision_ref' using errcode = 'BP422';
  end if;
  if (p_fee_bps > 0 or p_fee_fixed_grosze > 0) and exists (
       select 1 from public.app_promotions p
        where p.key = 'otwarcie-portalu' and p.enabled and (p.ends_at is null or p.ends_at > p_valid_from)) then
    raise exception 'fee: w okresie promocji prowizja wynosi 0 %% (00, D42)' using errcode = 'BP409';
  end if;
  insert into public.platform_fee_settings (valid_from, fee_bps, fee_fixed_grosze, decision_ref, set_by)
  values (p_valid_from, p_fee_bps, p_fee_fixed_grosze, trim(p_decision_ref), p_actor)
  returning id into v_id;
  insert into public.client_audit_log (actor, action, entity, entity_id, payload)
  values ('staff:' || p_actor::text, 'platform_fee_changed', 'platform_fee', v_id,
          jsonb_build_object('fee_bps', p_fee_bps, 'fee_fixed_grosze', p_fee_fixed_grosze, 'valid_from', p_valid_from));
  return v_id;
end $$;

-- Właściciel aktywnego, zweryfikowanego organizatora (decyzje o pieniądzach: „Wypłaty”, warunki sprzedaży, zwroty)
create or replace function public.organizer_owner_ok(p_organizer uuid, p_actor uuid)
returns boolean
language sql stable set search_path = '' as $$
  select exists (select 1 from public.organizer_members om
                   join public.training_organizers o on o.id = om.organizer_id
                  where om.organizer_id = p_organizer and om.user_id = p_actor and om.role = 'owner'
                    and om.status = 'active' and o.status = 'active' and o.verified_at is not null);
$$;

-- Decyzje o pieniądzach organizatora (zwroty, „Wypłaty”, odwołanie szkolenia z opłaconymi zamówieniami):
-- właściciel jak wyżej, ale NIE w karencji po resecie drugiego składnika przez doradcę (00, D28) –
-- przejęcie konta przez fałszywe zgłoszenie utraty telefonu nie daje od razu dostępu do pieniędzy
-- (przegląd red team płatności 13.11.2026).
create or replace function public.organizer_money_ok(p_organizer uuid, p_actor uuid)
returns boolean
language sql stable set search_path = '' as $$
  select public.organizer_owner_ok(p_organizer, p_actor)
     and not exists (select 1 from public.organizer_members om cross join public.app_settings s
                      where om.organizer_id = p_organizer and om.user_id = p_actor
                        and om.mfa_reset_at > now() - make_interval(hours => s.payout_change_cooldown_hours));
$$;

-- Alert o zmianie „Wypłat” (nowe konto, link do formularza operatora dla konta aktywnego, zmiana rachunku
-- u operatora, reset drugiego składnika właściciela, niezgodny NIP z KYB): e-mail do WSZYSTKICH właścicieli
-- organizatora, na adres z weryfikacji organizatora (12.1 – serwer rozwiązuje 'organizer-verified:<id>'
-- z rekordu weryfikacji, nie z profilu, którym może sterować napastnik) i do zespołu płatności, który
-- przed końcem karencji dzwoni na numer z rejestru (telefon zwrotny jak przy weryfikacji – 12.1).
create or replace function public.payout_alert(p_organizer uuid, p_kind text, p_payload jsonb default '{}'::jsonb)
returns void
language plpgsql set search_path = '' as $$
declare
  v_payload jsonb := jsonb_build_object('kind', p_kind, 'organizer_id', p_organizer) || coalesce(p_payload, '{}'::jsonb);
begin
  insert into public.outbox_emails (template, recipient, payload)
  select 'payout_change_alert', 'user:' || om.user_id::text, v_payload
    from public.organizer_members om
   where om.organizer_id = p_organizer and om.role = 'owner' and om.status = 'active';
  insert into public.outbox_emails (template, recipient, payload)
  values ('payout_change_alert', 'organizer-verified:' || p_organizer::text, v_payload),
         ('payout_change_alert_team', 'team:platnosci', v_payload);
end $$;

-- Reset drugiego składnika właściciela organizatora przez doradcę (00, D28; procedura – Q25). Serwer usuwa
-- czynnik TOTP w Supabase Auth (Admin API) i w tej samej operacji woła tę funkcję: znacznik mfa_reset_at
-- (72 h bez zwrotów i zmian „Wypłat” – organizer_money_ok), wpis w dzienniku i alert do wszystkich
-- właścicieli, na adres z weryfikacji i do zespołu płatności. Zwraca liczbę profili organizatora.
create or replace function public.app_organizer_owner_mfa_reset(p_user uuid, p_actor uuid)
returns integer
language plpgsql set search_path = '' as $$
declare
  v_n integer := 0;
  r   record;
begin
  if not exists (select 1 from public.admin_users u
                 where u.user_id = p_actor and u.is_active and u.role in ('admin','agent')) then
    raise exception 'mfa reset: brak uprawnień';
  end if;
  for r in update public.organizer_members om set mfa_reset_at = now()
            where om.user_id = p_user and om.role = 'owner' and om.status = 'active'
           returning om.organizer_id loop
    insert into public.client_audit_log (organizer_id, actor, action, entity, entity_id)
    values (r.organizer_id, 'staff:' || p_actor::text, 'organizer_owner_mfa_reset', 'organizer_member', p_user);
    perform public.payout_alert(r.organizer_id, 'owner_mfa_reset');
    v_n := v_n + 1;
  end loop;
  return v_n;
end $$;

-- „Wypłaty” – krok 0, przed KAŻDYM createOnboardingLink (nowe konto, dokończenie KYC/KYB, zmiana danych
-- w formularzu operatora): właściciel poza karencją po resecie TOTP, świeża weryfikacja TOTP (≤ 5 min –
-- serwer przekazuje czas ostatniego wyzwania MFA z sesji, baza sprawdza go jeszcze raz), ślad w dzienniku
-- i alert, gdy link dotyczy konta, które już było aktywne (formularz operatora pozwala zmienić rachunek).
create or replace function public.app_payout_link_issued(p_organizer uuid, p_actor uuid, p_mfa_verified_at timestamptz)
returns void
language plpgsql set search_path = '' as $$
declare
  v_a public.organizer_payout_accounts%rowtype;
begin
  if not public.organizer_money_ok(p_organizer, p_actor) then
    raise exception 'payout link: brak uprawnień';
  end if;
  if p_mfa_verified_at is null or p_mfa_verified_at < now() - interval '5 minutes'
     or p_mfa_verified_at > now() + interval '1 minute' then
    raise exception 'payout link: wymagane ponowne podanie kodu z aplikacji' using errcode = 'BP409';
  end if;
  select * into v_a from public.organizer_payout_accounts a
   where a.organizer_id = p_organizer and a.status <> 'disabled';
  insert into public.client_audit_log (organizer_id, actor, action, entity, entity_id, payload)
  values (p_organizer, 'user:' || p_actor::text, 'payout_account_link_created', 'payout_account', v_a.id,
          jsonb_build_object('account_status', coalesce(v_a.status, 'none')));
  if v_a.activated_at is not null then
    perform public.payout_alert(p_organizer, 'payout_link_for_active_account');
  end if;
end $$;

-- „Wypłaty” – krok 1: serwer zakłada konto u operatora (adapter createOnboardingLink) i zapisuje tu jego
-- identyfikator. Idempotentnie dla tej samej pary (operator, konto). Stan ustawia tylko operator.
-- Nowe konto = alert (payout_alert) i – po aktywacji – karencja przed pierwszym zamówieniem (usable_from).
create or replace function public.app_payout_account_register(
  p_organizer uuid, p_actor uuid, p_provider text, p_account_ref text)
returns uuid
language plpgsql set search_path = '' as $$
declare
  v_id  uuid;
  v_org uuid;
begin
  if not public.organizer_money_ok(p_organizer, p_actor) then
    raise exception 'payout: brak uprawnień';
  end if;
  if p_provider is null or p_provider not in ('p24','payu','tpay','stripe') then
    raise exception 'payout: nieprawidłowe pole provider' using errcode = 'BP422';
  elsif coalesce(p_account_ref, '') !~ '^[A-Za-z0-9_.:-]{3,100}$' then
    raise exception 'payout: nieprawidłowe pole provider_account_ref' using errcode = 'BP422';
  end if;
  select a.id, a.organizer_id into v_id, v_org from public.organizer_payout_accounts a
   where a.provider = p_provider and a.provider_account_ref = p_account_ref;
  if found then
    if v_org <> p_organizer then
      raise exception 'payout: konto operatora należy do innego organizatora';
    end if;
    return v_id;
  end if;
  if exists (select 1 from public.organizer_payout_accounts a
              where a.organizer_id = p_organizer and a.status <> 'disabled') then
    raise exception 'payout: organizator ma już konto u operatora' using errcode = 'BP409';
  end if;
  insert into public.organizer_payout_accounts (organizer_id, provider, provider_account_ref, created_by)
  values (p_organizer, p_provider, p_account_ref, p_actor)
  returning id into v_id;
  insert into public.client_audit_log (organizer_id, actor, action, entity, entity_id, payload)
  values (p_organizer, 'user:' || p_actor::text, 'payout_account_created', 'payout_account', v_id,
          jsonb_build_object('provider', p_provider));
  perform public.payout_alert(p_organizer, 'payout_account_created', jsonb_build_object('provider', p_provider));
  return v_id;
end $$;

-- „Wypłaty” – stan od operatora (webhook o koncie albo odpytanie getPayoutStatus). Jedyna droga do 'active'.
-- Karencja (przegląd red team 13.11.2026): pierwsza aktywacja i każda zmiana rachunku wypłat zgłoszona przez
-- operatora (p_destination_changed – zdarzenie operatora zmapowane na account.updated z flagą
-- payoutDestinationChanged) ustawia usable_from = now() + payout_change_cooldown_hours; do tego czasu
-- konto nie przyjmuje zamówień ani publikacji, a zespół dostaje alert do telefonu zwrotnego.
-- p_entity_tax_id – NIP podmiotu z KYB operatora (jeśli operator go podaje; do weryfikacji): inny niż NIP
-- zweryfikowanego profilu → stan 'restricted' i rozbieżność kyb_mismatch (konto „słupa” albo innej firmy).
create or replace function public.app_payout_account_set_status(
  p_provider text, p_account_ref text, p_charges_enabled boolean, p_payouts_enabled boolean,
  p_requirements_due boolean, p_disabled boolean default false, p_destination_changed boolean default false,
  p_entity_tax_id text default null)
returns text
language plpgsql set search_path = '' as $$
declare
  v_a      public.organizer_payout_accounts%rowtype;
  v_new    text;
  v_nip    text;
  v_match  boolean;
  v_cool   interval;
  v_usable timestamptz;
begin
  if p_entity_tax_id is not null and p_entity_tax_id !~ '^[0-9]{10}$' then
    raise exception 'payout: nieprawidłowe pole entity_tax_id' using errcode = 'BP422';
  end if;
  select * into v_a from public.organizer_payout_accounts a
   where a.provider = p_provider and a.provider_account_ref = p_account_ref for update;
  if not found then
    raise exception 'payout: nieznane konto operatora';
  end if;
  select o.nip into v_nip from public.training_organizers o where o.id = v_a.organizer_id;
  select make_interval(hours => s.payout_change_cooldown_hours) into v_cool from public.app_settings s;
  v_match := case when p_entity_tax_id is null then v_a.kyb_tax_id_match else p_entity_tax_id = v_nip end;
  v_new := case when coalesce(p_disabled, false) then 'disabled'
                when v_match is false then 'restricted'
                when coalesce(p_charges_enabled, false) and not coalesce(p_requirements_due, true) then 'active'
                when v_a.activated_at is not null then 'restricted'
                else 'onboarding' end;
  v_usable := v_a.usable_from;
  if v_new = 'active' and v_usable is null then
    v_usable := now() + v_cool;                                -- pierwsza aktywacja
  end if;
  if coalesce(p_destination_changed, false) then
    v_usable := now() + v_cool;                                -- nowy rachunek wypłat – karencja od nowa
  end if;
  update public.organizer_payout_accounts
     set status = v_new, charges_enabled = coalesce(p_charges_enabled, false),
         payouts_enabled = coalesce(p_payouts_enabled, false), requirements_due = coalesce(p_requirements_due, true),
         status_checked_at = now(), kyb_tax_id_match = v_match, usable_from = v_usable,
         payout_destination_changed_at = case when coalesce(p_destination_changed, false) then now()
                                              else payout_destination_changed_at end,
         activated_at = coalesce(v_a.activated_at, case when v_new = 'active' then now() end),
         updated_at = now()
   where id = v_a.id;
  if v_new is distinct from v_a.status then
    insert into public.client_audit_log (organizer_id, actor, action, entity, entity_id, payload)
    values (v_a.organizer_id, 'system:payments:' || p_provider, 'payout_account_status_changed', 'payout_account',
            v_a.id, jsonb_build_object('from', v_a.status, 'to', v_new));
    insert into public.outbox_emails (template, recipient, payload)
    values ('payout_account_status', 'organizer:' || v_a.organizer_id::text, jsonb_build_object('status', v_new));
  end if;
  if coalesce(p_destination_changed, false) then
    insert into public.client_audit_log (organizer_id, actor, action, entity, entity_id, payload)
    values (v_a.organizer_id, 'system:payments:' || p_provider, 'payout_destination_changed', 'payout_account',
            v_a.id, jsonb_build_object('usable_from', v_usable));
    perform public.payout_alert(v_a.organizer_id, 'payout_destination_changed');
    perform public.payment_discrepancy_open('payout_destination_changed', p_provider, p_account_ref, null,
                                            jsonb_build_object('organizer_id', v_a.organizer_id));
  end if;
  if v_match is false and v_a.kyb_tax_id_match is distinct from false then
    insert into public.client_audit_log (organizer_id, actor, action, entity, entity_id)
    values (v_a.organizer_id, 'system:payments:' || p_provider, 'payout_account_kyb_mismatch', 'payout_account', v_a.id);
    perform public.payout_alert(v_a.organizer_id, 'payout_account_kyb_mismatch');
    perform public.payment_discrepancy_open('kyb_mismatch', p_provider, p_account_ref, null,
                                            jsonb_build_object('organizer_id', v_a.organizer_id));
  end if;
  return v_new;
end $$;

-- Warunki sprzedaży organizatora (regulamin + dane sprzedawcy): nową wersję składa właściciel organizatora,
-- zatwierdza personel. NIP sprzedawcy = NIP zweryfikowanego profilu (DSA art. 30 – identyfikowalność).
create or replace function public.app_sales_terms_submit(p_organizer uuid, p_actor uuid, p_payload jsonb)
returns uuid
language plpgsql set search_path = '' as $$
declare
  v_field   text;
  v_id      uuid;
  v_version integer;
  v_url     text := '(https?://|www\.)';
begin
  if not public.organizer_owner_ok(p_organizer, p_actor) then
    raise exception 'sales terms: brak uprawnień';
  end if;
  v_field := case
    when coalesce(p_payload ->> 'seller_nip', '') is distinct from
         (select o.nip from public.training_organizers o where o.id = p_organizer) then 'seller_nip'
    when coalesce(char_length(trim(p_payload ->> 'seller_legal_name')), 0) not between 2 and 200
         or p_payload ->> 'seller_legal_name' ~ '[<>]' then 'seller_legal_name'
    when coalesce(char_length(trim(p_payload ->> 'seller_address')), 0) not between 5 and 200
         or p_payload ->> 'seller_address' ~ '[<>]' then 'seller_address'
    when char_length(p_payload ->> 'seller_register') > 120 or p_payload ->> 'seller_register' ~ '[<>]' then 'seller_register'
    when coalesce(p_payload ->> 'seller_email', '') !~ '^[^@[:space:]<>]+@[^@[:space:]<>]+\.[a-z]{2,}$'
         or char_length(p_payload ->> 'seller_email') > 254 then 'seller_email'
    when nullif(p_payload ->> 'seller_phone', '') is not null
         and p_payload ->> 'seller_phone' !~ '^\+?[0-9 ]{9,16}$' then 'seller_phone'
    when coalesce(char_length(p_payload ->> 'cancellation_rules'), 0) not between 50 and 4000
         or p_payload ->> 'cancellation_rules' ~ '[<>]' or p_payload ->> 'cancellation_rules' ~* v_url then 'cancellation_rules'
    when coalesce(char_length(p_payload ->> 'withdrawal_info'), 0) not between 50 and 4000
         or p_payload ->> 'withdrawal_info' ~ '[<>]' or p_payload ->> 'withdrawal_info' ~* v_url then 'withdrawal_info'
    when coalesce(char_length(p_payload ->> 'complaint_info'), 0) not between 30 and 2000
         or p_payload ->> 'complaint_info' ~ '[<>]' or p_payload ->> 'complaint_info' ~* v_url then 'complaint_info'
    when coalesce(char_length(p_payload ->> 'terms_body'), 0) not between 200 and 20000
         or p_payload ->> 'terms_body' ~ '[<>]' or p_payload ->> 'terms_body' ~* v_url then 'terms_body'
  end;
  if v_field is not null then
    raise exception 'sales terms: nieprawidłowe pole %', v_field using errcode = 'BP422';
  end if;
  if exists (select 1 from public.organizer_sales_terms st
              where st.organizer_id = p_organizer and st.status = 'pending_review') then
    raise exception 'sales terms: poprzednia wersja czeka na sprawdzenie' using errcode = 'BP409';
  end if;
  select coalesce(max(st.version), 0) + 1 into v_version from public.organizer_sales_terms st
   where st.organizer_id = p_organizer;
  insert into public.organizer_sales_terms
    (organizer_id, version, seller_legal_name, seller_address, seller_nip, seller_register, seller_email,
     seller_phone, cancellation_rules, withdrawal_info, complaint_info, terms_body, submitted_by)
  values (p_organizer, v_version, trim(p_payload ->> 'seller_legal_name'), trim(p_payload ->> 'seller_address'),
          p_payload ->> 'seller_nip', nullif(trim(p_payload ->> 'seller_register'), ''),
          lower(trim(p_payload ->> 'seller_email')), nullif(trim(p_payload ->> 'seller_phone'), ''),
          p_payload ->> 'cancellation_rules', p_payload ->> 'withdrawal_info', p_payload ->> 'complaint_info',
          p_payload ->> 'terms_body', p_actor)
  returning id into v_id;
  insert into public.client_audit_log (organizer_id, actor, action, entity, entity_id, payload)
  values (p_organizer, 'user:' || p_actor::text, 'sales_terms_submitted', 'sales_terms', v_id,
          jsonb_build_object('version', v_version));
  insert into public.outbox_emails (template, recipient, payload)
  values ('sales_terms_submitted_team', 'team:moderacja', jsonb_build_object('organizer_id', p_organizer, 'version', v_version));
  return v_id;
end $$;

create or replace function public.app_sales_terms_moderate(
  p_terms uuid, p_actor uuid, p_decision text, p_reason text default null)
returns void
language plpgsql set search_path = '' as $$
declare
  v_st public.organizer_sales_terms%rowtype;
begin
  if not exists (select 1 from public.admin_users u
                 where u.user_id = p_actor and u.is_active and u.role in ('admin','agent')) then
    raise exception 'sales terms: brak uprawnień';
  end if;
  select * into v_st from public.organizer_sales_terms st where st.id = p_terms for update;
  if not found or v_st.status <> 'pending_review' then
    raise exception 'sales terms: brak wersji do sprawdzenia' using errcode = 'BP409';
  end if;
  if p_decision = 'approve' then
    update public.organizer_sales_terms set status = 'retired'
     where organizer_id = v_st.organizer_id and status = 'active';
    update public.organizer_sales_terms set status = 'active', reviewed_by = p_actor, reviewed_at = now()
     where id = p_terms;
  elsif p_decision = 'reject' and coalesce(char_length(trim(p_reason)), 0) between 5 and 500 then
    update public.organizer_sales_terms
       set status = 'rejected', reviewed_by = p_actor, reviewed_at = now(), rejection_reason = trim(p_reason)
     where id = p_terms;
  else
    raise exception 'sales terms: niedozwolona decyzja albo brak uzasadnienia';
  end if;
  insert into public.client_audit_log (organizer_id, actor, action, entity, entity_id, payload)
  values (v_st.organizer_id, 'staff:' || p_actor::text,
          case p_decision when 'approve' then 'sales_terms_approved' else 'sales_terms_rejected' end,
          'sales_terms', p_terms, jsonb_build_object('version', v_st.version));
end $$;

-- Wygaszenie przeterminowanych rezerwacji jednego szkolenia. Wywołujący TRZYMA blokadę wiersza szkolenia.
create or replace function public.training_orders_expire_for(p_training uuid)
returns integer
language plpgsql set search_path = '' as $$
declare
  v_n     integer;
  v_actor text := current_setting('app.audit_actor', true);
begin
  perform set_config('app.audit_actor', 'system:reservation-expiry', true);
  with exp as (
    update public.training_orders o
       set status = 'expired', expired_at = now(), updated_at = now()
     where o.training_id = p_training and o.status = 'reserved' and o.reserved_until <= now()
    returning 1)
  select count(*) into v_n from exp;
  if v_n > 0 then
    update public.trainings t set seats_held = t.seats_held - v_n where t.id = p_training;
  end if;
  perform set_config('app.audit_actor', coalesce(v_actor, ''), true);
  return v_n;
end $$;

-- Zamknięcie otwartych rezerwacji szkolenia (zawieszony organizator). Wywołujący TRZYMA blokadę wiersza szkolenia.
create or replace function public.training_orders_close_reserved(p_training uuid, p_actor text)
returns integer
language plpgsql set search_path = '' as $$
declare
  v_n     integer;
  v_actor text := current_setting('app.audit_actor', true);
begin
  perform set_config('app.audit_actor', p_actor, true);
  with c as (
    update public.training_orders o set status = 'cancelled', cancelled_at = now(), updated_at = now()
     where o.training_id = p_training and o.status = 'reserved'
    returning 1)
  select count(*) into v_n from c;
  if v_n > 0 then
    update public.trainings t set seats_held = t.seats_held - v_n where t.id = p_training;
  end if;
  perform set_config('app.audit_actor', coalesce(v_actor, ''), true);
  return v_n;
end $$;

-- Cron co 5 minut (istniejący wyzwalacz */5 Workera beautypolisa-jobs): zwalnia miejsca z wygasłych rezerwacji
-- (czas rezerwacji – app_settings, z minimum operatora) i zamyka rezerwacje organizatorów, którzy nie są już
-- aktywni (zawieszenie także bezpośrednią zmianą statusu w /panel). Rezerwacja i tak wygasa „leniwie” przy
-- każdym nowym zamówieniu na to samo szkolenie. Po funkcji Worker woła app_checkouts_to_cancel() i dla każdej
-- zwróconej sesji adapter.cancelCheckout() – strona operatora przestaje przyjmować płatność.
create or replace function public.app_expire_training_orders()
returns integer
language plpgsql set search_path = '' as $$
declare
  v_total integer := 0;
  r       record;
begin
  for r in select distinct o.training_id from public.training_orders o
            where o.status = 'reserved' and o.reserved_until <= now() order by 1 loop
    perform 1 from public.trainings t where t.id = r.training_id for update;
    v_total := v_total + public.training_orders_expire_for(r.training_id);
  end loop;
  for r in select distinct o.training_id from public.training_orders o
             join public.training_organizers g on g.id = o.organizer_id
            where o.status = 'reserved' and g.status <> 'active' order by 1 loop
    perform 1 from public.trainings t where t.id = r.training_id for update;
    v_total := v_total + public.training_orders_close_reserved(r.training_id, 'system:organizer-suspended');
  end loop;
  return v_total;
end $$;

-- Zawieszenie organizatora przez personel (admin/agent, z uzasadnieniem): status 'suspended' (organizer_ids()
-- od razu odcina dostęp), zamknięcie otwartych rezerwacji wszystkich jego szkoleń; serwer po wywołaniu woła
-- app_checkouts_to_cancel() i cancelCheckout. Płatność, która mimo to przyjdzie, idzie do zwrotu automatycznego
-- (app_payment_webhook – powód 'organizator-zawieszony'). Przegląd red team płatności 13.11.2026.
create or replace function public.app_suspend_organizer(p_organizer uuid, p_actor uuid, p_reason text)
returns integer
language plpgsql set search_path = '' as $$
declare
  v_n integer := 0;
  r   record;
begin
  if not exists (select 1 from public.admin_users u
                 where u.user_id = p_actor and u.is_active and u.role in ('admin','agent')) then
    raise exception 'suspend organizer: brak uprawnień';
  end if;
  if coalesce(char_length(trim(p_reason)), 0) not between 5 and 500 or p_reason ~ '[<>]' then
    raise exception 'suspend organizer: nieprawidłowe pole reason' using errcode = 'BP422';
  end if;
  update public.training_organizers set status = 'suspended', updated_at = now()
   where id = p_organizer and status = 'active';
  if not found then
    raise exception 'suspend organizer: organizator nie jest aktywny' using errcode = 'BP409';
  end if;
  for r in select distinct o.training_id from public.training_orders o
            where o.organizer_id = p_organizer and o.status = 'reserved' order by 1 loop
    perform 1 from public.trainings t where t.id = r.training_id for update;
    v_n := v_n + public.training_orders_close_reserved(r.training_id, 'staff:' || p_actor::text);
  end loop;
  insert into public.client_audit_log (organizer_id, actor, action, entity, entity_id, payload)
  values (p_organizer, 'staff:' || p_actor::text, 'organizer_suspended_orders_closed', 'organizer', p_organizer,
          jsonb_build_object('reservations_closed', v_n));
  return v_n;
end $$;

-- Sesje płatności do unieważnienia u operatora (adapter.cancelCheckout, idempotentne): płatność 'pending'
-- z referencją operatora, gdy zamówienie nie jest już rezerwacją (wygasło, anulowane, opłacone inną sesją,
-- zamknięte przy zawieszeniu organizatora). Funkcja „rezerwuje” wiersze (checkout_cancel_requested_at),
-- ponowienie po 15 minutach, jeśli sesja dalej jest 'pending'. Cron co 5 minut i od razu po
-- app_training_order_abandon() / app_suspend_organizer().
create or replace function public.app_checkouts_to_cancel(p_limit integer default 100)
returns table (payment_id uuid, provider text, provider_payment_ref text)
language plpgsql set search_path = '' as $$
#variable_conflict use_column
begin
  return query
    with c as (
      select p.id from public.training_payments p
        join public.training_orders o on o.id = p.order_id
       where p.status = 'pending' and p.provider_payment_ref is not null
         and (o.status <> 'reserved'
              or exists (select 1 from public.training_payments q where q.order_id = p.order_id and q.attempt > p.attempt))
         and p.created_at > now() - interval '48 hours'
         and (p.checkout_cancel_requested_at is null or p.checkout_cancel_requested_at < now() - interval '15 minutes')
       order by p.created_at
       limit least(greatest(coalesce(p_limit, 100), 1), 500)
       for update of p skip locked)
    update public.training_payments x set checkout_cancel_requested_at = now(), updated_at = now()
      from c where x.id = c.id
    returning x.id, x.provider, x.provider_payment_ref;
end $$;

-- Płatności do sprawdzenia w API operatora (cron co 15 minut; adapter.getPayment): wciąż 'pending' po czasie
-- sesji, także bez referencji operatora (Worker padł między createCheckout a zapisem referencji – szuka po
-- naszym UUID w metadanych; możliwość wyszukiwania po metadanych – do weryfikacji u operatora). Wynik Worker
-- przekazuje do app_payment_webhook() ze źródłem 'reconciliation' (event_id 'recon:<id>:<stan>').
create or replace function public.app_payments_to_reconcile(p_limit integer default 100)
returns table (payment_id uuid, order_id uuid, provider text, provider_payment_ref text, created_at timestamptz)
language sql stable set search_path = '' as $$
  select p.id, p.order_id, p.provider, p.provider_payment_ref, p.created_at
    from public.training_payments p
   where p.status = 'pending' and p.created_at between now() - interval '48 hours' and now() - interval '15 minutes'
     and coalesce(p.checkout_expires_at, p.created_at) < now()
   order by p.created_at
   limit least(greatest(coalesce(p_limit, 100), 1), 500);
$$;

-- Zamówienie z rezerwacją miejsca (15 minut albo minimalny czas sesji operatora – Stripe: 30). Kwota i prowizja
-- WYŁĄCZNIE z bazy (brak parametru kwoty).
-- p_participant_name / p_participant_email – z profilu zweryfikowanego użytkownika (jak app_training_register);
-- p_buyer – dane do faktury z formularza (osoba albo firma z NIP); p_sales_terms – wersja warunków sprzedaży,
-- które kupujący widział i zaakceptował; p_notice_version – wersja informacji „sprzedawcą jest organizator,
-- portal nie jest stroną umowy” i o przekazaniu danych organizatorowi; p_idempotency_key – nadany przez
-- serwer przy renderze formularza (ponowne wysłanie = to samo zamówienie); p_early_start_notice – wersja treści
-- żądania rozpoczęcia usługi przed upływem 14 dni na odstąpienie (checkbox; wymagane, gdy szkolenie zaczyna się
-- wcześniej niż za 14 dni – dok. 11 §12a.8 [do weryfikacji prawnej]).
-- Przegląd red team 13.11.2026: konto wypłat po karencji (usable_from), limity nowego organizatora,
-- bill_to_account tylko dla NIP konta salonu (zakup na NIP salonu – wyłącznie właściciel).
create or replace function public.app_training_order_create(
  p_training uuid, p_user uuid, p_account uuid, p_idempotency_key uuid, p_sales_terms uuid,
  p_participant_name text, p_participant_email text, p_buyer jsonb, p_notice_version text,
  p_early_start_notice text default null)
returns table (order_id uuid, order_ref text, status text, amount_grosze integer, platform_fee_grosze integer,
               reserved_until timestamptz, provider text, provider_account_ref text, created boolean)
language plpgsql set search_path = '' as $$
#variable_conflict use_column
declare
  v_o      public.training_orders%rowtype;
  v_t      public.trainings%rowtype;
  v_set    public.app_settings%rowtype;
  v_pa     public.organizer_payout_accounts%rowtype;
  v_fee    public.platform_fee_settings%rowtype;
  v_role   text;
  v_terms  uuid;
  v_field  text;
  v_kind   text := p_buyer ->> 'buyer_kind';
  v_nip    text := nullif(p_buyer ->> 'nip', '');
  v_amount integer;
  v_bps    integer;
  v_fee_gr integer;
  v_email  text := '^[^@[:space:]<>]+@[^@[:space:]<>]+\.[A-Za-z]{2,}$';
  v_bill   boolean := false;
  v_verif  timestamptz;
  v_mins   integer;
begin
  -- 0. jedna operacja zamówienia naraz na użytkownika (SEC-18): idempotencja i limity bez wyścigów
  perform pg_advisory_xact_lock(hashtextextended('training_order:user:' || coalesce(p_user::text, ''), 0));
  -- 1. idempotencja: ten sam klucz tej samej osoby = to samo zamówienie, bez nowej rezerwacji
  select * into v_o from public.training_orders o where o.user_id = p_user and o.idempotency_key = p_idempotency_key;
  if found then
    if v_o.training_id <> p_training then
      raise exception 'order: klucz idempotencji użyty dla innego szkolenia' using errcode = 'BP409';
    end if;
    return query select v_o.id, v_o.order_ref, v_o.status, v_o.amount_grosze, v_o.platform_fee_grosze,
                        v_o.reserved_until, v_o.provider, pa.provider_account_ref, false
                   from public.organizer_payout_accounts pa where pa.id = v_o.payout_account_id;
    return;
  end if;
  -- 2. członkostwo: aktywny członek aktywnego konta salonu (konta pracodawców – Q17; osoby szukające pracy – nie)
  select m.role into v_role from public.client_members m
    join public.client_accounts a on a.id = m.account_id and a.status = 'active' and a.kind = 'client'
   where m.account_id = p_account and m.user_id = p_user and m.status = 'active';
  if not found then
    raise exception 'order: brak aktywnego członkostwa';
  end if;
  -- 3. walidacja (PRIV-12: tylko nazwa pola, bez wartości)
  v_field := case
    when coalesce(char_length(p_notice_version), 0) not between 1 and 40 then 'notice_version'
    when p_idempotency_key is null then 'idempotency_key'
    when coalesce(char_length(trim(p_participant_name)), 0) not between 2 and 120
         or p_participant_name ~ '[<>@]' then 'participant_name'
    when coalesce(p_participant_email, '') !~ v_email or char_length(p_participant_email) > 254 then 'participant_email'
    when v_kind is null or v_kind not in ('osoba','firma') then 'buyer_kind'
    when coalesce(char_length(trim(p_buyer ->> 'buyer_name')), 0) not between 2 and 200
         or p_buyer ->> 'buyer_name' ~ '[<>@]' then 'buyer_name'
    when v_kind = 'firma' and (v_nip is null or v_nip !~ '^[0-9]{10}$' or not public.nip_checksum_ok(v_nip)) then 'nip'
    when v_kind = 'osoba' and v_nip is not null then 'nip'
    when (v_kind = 'firma' or nullif(p_buyer ->> 'street', '') is not null)
         and (coalesce(char_length(trim(p_buyer ->> 'street')), 0) not between 3 and 200
              or p_buyer ->> 'street' ~ '[<>@]') then 'street'
    when (v_kind = 'firma' or nullif(p_buyer ->> 'postal_code', '') is not null)
         and coalesce(p_buyer ->> 'postal_code', '') !~ '^[0-9]{2}-[0-9]{3}$' then 'postal_code'
    when (v_kind = 'firma' or nullif(p_buyer ->> 'city', '') is not null)
         and (coalesce(char_length(trim(p_buyer ->> 'city')), 0) not between 2 and 80
              or p_buyer ->> 'city' ~ '[<>@[:digit:]]') then 'city'
    when coalesce(p_buyer ->> 'invoice_email', '') !~ v_email or char_length(p_buyer ->> 'invoice_email') > 254 then 'invoice_email'
    when p_early_start_notice is not null and char_length(p_early_start_notice) not between 1 and 40 then 'early_start'
  end;
  if v_field is not null then
    raise exception 'order: nieprawidłowe pole %', v_field using errcode = 'BP422';
  end if;
  -- 4. druga karta przeglądarki: aktywna rezerwacja tej osoby na to szkolenie = to samo zamówienie
  select * into v_o from public.training_orders o
   where o.training_id = p_training and o.user_id = p_user and o.status = 'reserved' and o.reserved_until > now();
  if found then
    return query select v_o.id, v_o.order_ref, v_o.status, v_o.amount_grosze, v_o.platform_fee_grosze,
                        v_o.reserved_until, v_o.provider, pa.provider_account_ref, false
                   from public.organizer_payout_accounts pa where pa.id = v_o.payout_account_id;
    return;
  end if;
  -- 5. limity przeciw blokowaniu miejsc (rezerwacje bez zamiaru zapłaty)
  select * into v_set from public.app_settings;
  if (select count(*) from public.training_orders o
       where o.user_id = p_user and o.created_at > now() - interval '1 hour') >= v_set.orders_per_user_hour
     or (select count(*) from public.training_orders o
          where o.user_id = p_user and o.status = 'reserved' and o.reserved_until > now())
        >= v_set.active_reservations_per_user then
    raise exception 'order: limit zamówień' using errcode = 'BP429';
  end if;
  -- 6. blokada wiersza szkolenia: wszystkie operacje na miejscach tego szkolenia po kolei
  select * into v_t from public.trainings t where t.id = p_training for update;
  if not found or v_t.status <> 'published' or v_t.published_at is null
     or v_t.plan_valid_until is null or v_t.plan_valid_until <= now() or v_t.starts_at > v_t.plan_valid_until then
    raise exception 'order: szkolenie niedostępne' using errcode = 'BP409';
  end if;
  if v_t.payment_mode <> 'online' or v_t.price_kind <> 'platne' then
    raise exception 'order: szkolenie bez płatności online' using errcode = 'BP409';
  end if;
  if now() >= coalesce(v_t.registration_closes_at, v_t.starts_at) then
    raise exception 'order: zapisy zamknięte' using errcode = 'BP409';
  end if;
  if v_t.audience = 'owners' and v_role <> 'owner' then
    raise exception 'order: szkolenie dla właścicieli salonów' using errcode = 'BP409';
  end if;
  select o.verified_at into v_verif from public.training_organizers o
   where o.id = v_t.organizer_id and o.status = 'active' and o.verified_at is not null;
  if not found then
    raise exception 'order: organizator niedostępny' using errcode = 'BP409';
  end if;
  select * into v_pa from public.organizer_payout_accounts pa
   where pa.organizer_id = v_t.organizer_id and pa.status = 'active';
  if not found then
    raise exception 'order: organizator nie przyjmuje teraz płatności online' using errcode = 'BP409';
  end if;
  if v_pa.usable_from is null or v_pa.usable_from > now() then
    raise exception 'order: konto wypłat organizatora w karencji' using errcode = 'BP409';
  end if;
  -- prawa konsumenta: szkolenie przed upływem 14 dni na odstąpienie – tylko z wyraźnym żądaniem kupującego
  if v_t.starts_at < now() + interval '14 days' and p_early_start_notice is null then
    raise exception 'order: nieprawidłowe pole early_start' using errcode = 'BP422';
  end if;
  -- faktura na NIP konta salonu: tylko właściciel (pracownik – przez właściciela); inny NIP = zakup prywatny
  if v_kind = 'firma' and v_nip = (select a.nip from public.client_accounts a where a.id = p_account) then
    if v_role <> 'owner' then
      raise exception 'order: faktura na NIP salonu – zamawia właściciel salonu' using errcode = 'BP409';
    end if;
    v_bill := true;
  end if;
  select st.id into v_terms from public.organizer_sales_terms st
   where st.organizer_id = v_t.organizer_id and st.status = 'active';
  if v_terms is null or v_terms is distinct from p_sales_terms then
    raise exception 'order: warunki sprzedaży organizatora zmieniły się – odśwież stronę' using errcode = 'BP409';
  end if;
  if exists (select 1 from public.training_registrations r
              where r.training_id = p_training and r.user_id = p_user
                and r.status in ('registered','attended','no_show')) then
    raise exception 'order: już zapisano na to szkolenie' using errcode = 'BP409';
  end if;
  -- opłacone (także częściowo zwrócone albo w zwrocie) zamówienie tej osoby na to szkolenie – bez drugiego
  -- (unikalny indeks training_orders_paid_uq i tak odrzuciłby drugie potwierdzenie)
  if exists (select 1 from public.training_orders x
              where x.training_id = p_training and x.user_id = p_user
                and x.status in ('paid','partially_refunded','refund_pending')) then
    raise exception 'order: szkolenie jest już opłacone' using errcode = 'BP409';
  end if;
  -- 7. wygaszenie przeterminowanych rezerwacji tego szkolenia (pod tą samą blokadą)
  if public.training_orders_expire_for(p_training) > 0 then
    select * into v_t from public.trainings t where t.id = p_training;
  end if;
  -- 8. limit miejsc na salon: zapisy + aktywne rezerwacje konta
  if (select count(*) from public.training_registrations r
       where r.training_id = p_training and r.account_id = p_account and r.status in ('registered','waitlisted'))
     + (select count(*) from public.training_orders o
         where o.training_id = p_training and o.account_id = p_account and o.status = 'reserved')
     >= v_t.per_account_limit then
    raise exception 'order: limit miejsc dla salonu' using errcode = 'BP409';
  end if;
  -- 9. brak nadsprzedaży: zapisani + zarezerwowani < limit (płatne online – bez listy rezerwowej w MVP)
  if v_t.capacity is not null and v_t.seats_registered + v_t.seats_held >= v_t.capacity then
    raise exception 'order: brak wolnych miejsc' using errcode = 'BP409';
  end if;
  -- 10. kwota wyłącznie z bazy (migawka ceny brutto) i prowizja z ustawień; w promocji zawsze 0 (00, D42)
  v_amount := (v_t.price_gross_pln * 100)::integer;
  v_fee := public.platform_fee_current();
  v_bps := coalesce(v_fee.fee_bps, 0);
  v_fee_gr := floor(v_amount::numeric * v_bps / 10000)::integer + coalesce(v_fee.fee_fixed_grosze, 0);
  if exists (select 1 from public.app_promotions p
              where p.key = 'otwarcie-portalu' and p.enabled and (p.ends_at is null or p.ends_at > now())) then
    v_bps := 0;
    v_fee_gr := 0;
  end if;
  if v_fee_gr >= v_amount then
    raise exception 'order: prowizja nie może przekroczyć ceny' using errcode = 'BP409';
  end if;
  -- 11. nowy organizator (pierwsze new_organizer_days dni od weryfikacji): limit liczby i sumy zamówień
  --     opłaconych i w rezerwacji – szkoda przy fałszywym organizatorze ograniczona do limitu
  if v_verif > now() - make_interval(days => v_set.new_organizer_days) then
    perform pg_advisory_xact_lock(hashtextextended('training_order:organizer:' || v_t.organizer_id::text, 0));
    if (select count(*) from public.training_orders x
         where x.organizer_id = v_t.organizer_id
           and (x.status in ('paid','partially_refunded','refund_pending','refunded')
                or (x.status = 'reserved' and x.reserved_until > now()))) >= v_set.new_organizer_paid_orders
       or (select coalesce(sum(x.amount_grosze), 0) from public.training_orders x
            where x.organizer_id = v_t.organizer_id
              and (x.status in ('paid','partially_refunded','refund_pending','refunded')
                   or (x.status = 'reserved' and x.reserved_until > now()))) + v_amount > v_set.new_organizer_max_grosze then
      raise exception 'order: limit sprzedaży nowego organizatora' using errcode = 'BP409';
    end if;
  end if;
  -- 12. czas rezerwacji = max(ustawienie, minimalny czas sesji operatora) – sesja u operatora nie może być
  --     krótsza niż minimum operatora (Stripe Checkout: 30 min), a rezerwacja nie krótsza niż sesja
  v_mins := greatest(v_set.order_reservation_minutes, coalesce((v_set.checkout_min_minutes ->> v_pa.provider)::integer, 0));
  insert into public.training_orders
    (order_ref, idempotency_key, training_id, organizer_id, account_id, user_id, sales_terms_id, payout_account_id,
     provider, buyer_kind, bill_to_account, amount_grosze, platform_fee_bps, platform_fee_grosze, reserved_until,
     notice_version, early_start_requested_at, early_start_notice_version)
  values ('SZ-' || to_char(now(), 'YYMM') || '-' || upper(substr(md5(gen_random_uuid()::text), 1, 8)),
          p_idempotency_key, p_training, v_t.organizer_id, p_account, p_user, v_terms, v_pa.id, v_pa.provider,
          v_kind, v_bill, v_amount, v_bps, v_fee_gr, now() + make_interval(mins => v_mins),
          p_notice_version, case when p_early_start_notice is not null then now() end, p_early_start_notice)
  returning * into v_o;
  insert into public.training_order_buyer_data
    (order_id, user_id, buyer_kind, buyer_name, nip, street, postal_code, city, invoice_email, participant_name,
     participant_email)
  values (v_o.id, p_user, v_kind, trim(p_buyer ->> 'buyer_name'), v_nip, nullif(trim(p_buyer ->> 'street'), ''),
          nullif(trim(p_buyer ->> 'postal_code'), ''), nullif(trim(p_buyer ->> 'city'), ''),
          lower(trim(p_buyer ->> 'invoice_email')), trim(p_participant_name), lower(trim(p_participant_email)));
  update public.trainings t set seats_held = t.seats_held + 1 where t.id = p_training;
  insert into public.client_audit_log (account_id, organizer_id, actor, action, entity, entity_id, payload)
  values (p_account, v_t.organizer_id, 'user:' || p_user::text, 'training_order_created', 'training_order', v_o.id,
          jsonb_build_object('training', p_training, 'amount_grosze', v_amount, 'fee_bps', v_bps));
  return query select v_o.id, v_o.order_ref, v_o.status, v_o.amount_grosze, v_o.platform_fee_grosze,
                      v_o.reserved_until, v_o.provider, v_pa.provider_account_ref, true;
end $$;

-- Kupujący rezygnuje przed zapłatą („Anuluj zamówienie”) – miejsce wraca od razu. Idempotentnie. Serwer po
-- wywołaniu unieważnia otwarte sesje operatora (app_checkouts_to_cancel → cancelCheckout).
create or replace function public.app_training_order_abandon(p_order uuid, p_user uuid)
returns void
language plpgsql set search_path = '' as $$
declare
  v_training uuid;
  v_status   text;
begin
  select o.training_id into v_training from public.training_orders o where o.id = p_order and o.user_id = p_user;
  if not found then
    raise exception 'order: brak zamówienia';
  end if;
  perform 1 from public.trainings t where t.id = v_training for update;
  select o.status into v_status from public.training_orders o where o.id = p_order for update;
  if v_status <> 'reserved' then
    return;
  end if;
  perform set_config('app.audit_actor', 'user:' || p_user::text, true);
  update public.training_orders set status = 'cancelled', cancelled_at = now(), updated_at = now() where id = p_order;
  update public.trainings t set seats_held = t.seats_held - 1 where t.id = v_training;
end $$;

-- Czy zamówienie można teraz opłacić (nowa sesja u operatora). NULL = tak, inaczej krótki powód (BP409).
-- Przegląd red team 13.11.2026: zawieszony organizator, konto wypłat nieaktywne albo w karencji, szkolenie
-- zdjęte, odwołane albo rozpoczęte – bez nowych sesji płatności także dla istniejącej rezerwacji.
create or replace function public.training_order_payable_error(p_order uuid)
returns text
language sql stable set search_path = '' as $$
  select case
    when o.status <> 'reserved' or o.reserved_until <= now() then 'rezerwacja wygasła'
    when g.status <> 'active' or g.verified_at is null then 'organizator niedostępny'
    when pa.status <> 'active' or pa.usable_from is null or pa.usable_from > now() then 'konto wypłat organizatora nieaktywne'
    when t.status <> 'published' or now() >= t.starts_at then 'szkolenie niedostępne'
  end
    from public.training_orders o
    join public.training_organizers g on g.id = o.organizer_id
    join public.organizer_payout_accounts pa on pa.id = o.payout_account_id
    join public.trainings t on t.id = o.training_id
   where o.id = p_order;
$$;

-- Sesja płatności – krok 1, PRZED createCheckout: wiersz płatności z naszym UUID (status 'pending', bez
-- referencji operatora). UUID trafia do operatora w metadanych sesji (ourPaymentId) – webhook i uzgadnianie
-- znajdą płatność nawet wtedy, gdy Worker padnie między createCheckout a app_training_payment_attach.
-- Tylko właściciel zamówienia, tylko przy ważnej rezerwacji i opłacalnym zamówieniu; najwyżej 5 prób.
create or replace function public.app_training_payment_begin(p_order uuid, p_user uuid, p_provider text)
returns uuid
language plpgsql set search_path = '' as $$
declare
  v_o       public.training_orders%rowtype;
  v_id      uuid;
  v_attempt integer;
  v_err     text;
begin
  select * into v_o from public.training_orders o where o.id = p_order and o.user_id = p_user for update;
  if not found then
    raise exception 'payment: brak zamówienia';
  end if;
  if p_provider is distinct from v_o.provider then
    raise exception 'payment: inny operator niż w zamówieniu';
  end if;
  v_err := public.training_order_payable_error(p_order);
  if v_err is not null then
    raise exception 'payment: %', v_err using errcode = 'BP409';
  end if;
  select coalesce(max(p.attempt), 0) + 1 into v_attempt from public.training_payments p where p.order_id = p_order;
  if v_attempt > 5 then
    raise exception 'payment: limit prób płatności' using errcode = 'BP429';
  end if;
  insert into public.training_payments (order_id, provider, attempt, amount_grosze)
  values (p_order, p_provider, v_attempt, v_o.amount_grosze)
  returning id into v_id;
  return v_id;
end $$;

-- Sesja płatności – krok 2, po createCheckout: referencja operatora do wiersza z kroku 1 (p_payment).
-- Zapis referencji NIE zależy już od ważności rezerwacji: sesja istnieje u operatora, więc musi dać się ją
-- unieważnić (cancelCheckout) i rozliczyć spóźnioną płatność. Idempotentnie dla tej samej referencji.
-- Bez p_payment (zgodność wstecz) – jak dawniej: kontrola opłacalności i nowa próba w jednym kroku.
create or replace function public.app_training_payment_attach(
  p_order uuid, p_user uuid, p_provider text, p_provider_payment_ref text, p_checkout_expires_at timestamptz,
  p_payment uuid default null)
returns uuid
language plpgsql set search_path = '' as $$
declare
  v_o       public.training_orders%rowtype;
  v_p       public.training_payments%rowtype;
  v_id      uuid;
  v_oid     uuid;
  v_attempt integer;
  v_err     text;
begin
  if coalesce(p_provider_payment_ref, '') !~ '^[A-Za-z0-9_.:-]{3,200}$' then
    raise exception 'payment: nieprawidłowe pole provider_payment_ref' using errcode = 'BP422';
  end if;
  select * into v_o from public.training_orders o where o.id = p_order and o.user_id = p_user for update;
  if not found then
    raise exception 'payment: brak zamówienia';
  end if;
  select p.id, p.order_id into v_id, v_oid from public.training_payments p
   where p.provider = p_provider and p.provider_payment_ref = p_provider_payment_ref;
  if found then                                  -- powtórzenie tego samego wywołania (idempotentnie)
    if v_oid <> p_order then
      raise exception 'payment: referencja operatora należy do innego zamówienia';
    end if;
    return v_id;
  end if;
  if p_provider is distinct from v_o.provider then
    raise exception 'payment: inny operator niż w zamówieniu';
  end if;
  if p_payment is not null then
    select * into v_p from public.training_payments p where p.id = p_payment and p.order_id = p_order for update;
    if not found or v_p.provider_payment_ref is not null then
      raise exception 'payment: brak sesji do uzupełnienia';
    end if;
    update public.training_payments
       set provider_payment_ref = p_provider_payment_ref, checkout_expires_at = p_checkout_expires_at, updated_at = now()
     where id = p_payment;
    return p_payment;
  end if;
  v_err := public.training_order_payable_error(p_order);
  if v_err is not null then
    raise exception 'payment: %', v_err using errcode = 'BP409';
  end if;
  select coalesce(max(p.attempt), 0) + 1 into v_attempt from public.training_payments p where p.order_id = p_order;
  if v_attempt > 5 then
    raise exception 'payment: limit prób płatności' using errcode = 'BP429';
  end if;
  insert into public.training_payments (order_id, provider, provider_payment_ref, attempt, amount_grosze, checkout_expires_at)
  values (p_order, p_provider, p_provider_payment_ref, v_attempt, v_o.amount_grosze, p_checkout_expires_at)
  returning id into v_id;
  return v_id;
end $$;

-- Dozwolone przejścia stanu płatności. Zdarzenia spóźnione i w złej kolejności (np. „failed” po
-- „succeeded”) są zapisywane w payment_webhook_events jako 'ignored_stale' i nie zmieniają stanu.
create or replace function public.payment_status_next_ok(p_from text, p_to text)
returns boolean
language sql immutable set search_path = '' as $$
  select (p_from, p_to) in (
    ('pending','succeeded'), ('pending','failed'), ('pending','cancelled'), ('pending','expired'),
    ('failed','succeeded'), ('failed','cancelled'), ('failed','expired'),
    ('cancelled','succeeded'), ('expired','succeeded'),          -- płatność potwierdzona po czasie (np. przelew)
    ('succeeded','partially_refunded'), ('succeeded','refunded'), ('succeeded','disputed'),
    ('partially_refunded','partially_refunded'), ('partially_refunded','refunded'), ('partially_refunded','disputed'),
    ('disputed','succeeded'),                                     -- spór wygrany albo zamknięte ostrzeżenie
    ('disputed','partially_refunded'), ('disputed','refunded'));  -- spór przegrany (chargeback)
$$;

-- Rozbieżność do wyjaśnienia (jedna otwarta danego rodzaju na zamówienie albo referencję) + alert dla zespołu
create or replace function public.payment_discrepancy_open(
  p_kind text, p_provider text, p_ref text, p_order uuid, p_details jsonb default '{}'::jsonb)
returns boolean
language plpgsql set search_path = '' as $$
declare
  v_id bigint;
begin
  insert into public.payment_discrepancies (kind, provider, provider_ref, order_id, details)
  values (p_kind, p_provider, nullif(p_ref, ''), p_order, coalesce(p_details, '{}'::jsonb))
  on conflict do nothing
  returning id into v_id;
  if v_id is not null then
    insert into public.outbox_emails (template, recipient, payload)
    values ('payment_discrepancy_team', 'team:platnosci', jsonb_build_object('kind', p_kind, 'id', v_id));
  end if;
  return v_id is not null;
end $$;

-- Pierwsza udana płatność zamówienia (płatność „główna” – od niej liczone są zwroty)
create or replace function public.training_order_main_payment(p_order uuid)
returns uuid
language sql stable set search_path = '' as $$
  select p.id from public.training_payments p
   where p.order_id = p_order and p.status in ('succeeded','partially_refunded','disputed','refunded')
   order by p.succeeded_at nulls last, p.attempt
   limit 1;
$$;

create or replace function public.training_refund_create(
  p_order uuid, p_payment uuid, p_amount integer, p_reason text, p_actor text)
returns uuid
language plpgsql set search_path = '' as $$
declare
  v_id uuid;
begin
  insert into public.training_refunds (order_id, payment_id, amount_grosze, reason, requested_by)
  values (p_order, p_payment, p_amount, p_reason, p_actor)
  returning id into v_id;
  insert into public.client_audit_log (account_id, organizer_id, actor, action, entity, entity_id, payload)
  select o.account_id, o.organizer_id, p_actor, 'training_refund_requested', 'training_refund', v_id,
         jsonb_build_object('order', p_order, 'amount_grosze', p_amount, 'reason', p_reason)
    from public.training_orders o where o.id = p_order;
  return v_id;                         -- serwer wykonuje zwrot u operatora (adapter refund, klucz = id zwrotu)
end $$;

-- Potwierdzenie zapisu po udanej płatności. Wywołujący trzyma blokady szkolenia i zamówienia i już
-- przeniósł miejsce do seats_registered. Dane dla organizatora – minimalna migawka jak w app_training_register.
create or replace function public.training_order_confirm(p_order uuid, p_paid_at timestamptz)
returns uuid
language plpgsql set search_path = '' as $$
declare
  v_o   public.training_orders%rowtype;
  v_b   public.training_order_buyer_data%rowtype;
  v_reg uuid;
begin
  select * into v_o from public.training_orders o where o.id = p_order;
  select * into v_b from public.training_order_buyer_data b where b.order_id = p_order;
  insert into public.training_registrations (training_id, account_id, user_id, status)
  values (v_o.training_id, v_o.account_id, v_o.user_id, 'registered')
  on conflict (training_id, user_id) do update
    set status = 'registered', account_id = excluded.account_id, cancelled_at = null, updated_at = now(),
        created_at = now()
  returning id into v_reg;
  insert into public.training_participant_contacts
    (registration_id, training_id, organizer_id, status, participant_name, participant_email, salon_name, notice_version)
  values (v_reg, v_o.training_id, v_o.organizer_id, 'registered', v_b.participant_name, v_b.participant_email,
          case when v_b.buyer_kind = 'firma' then v_b.buyer_name end, v_o.notice_version)
  on conflict (registration_id) do update
    set status = 'registered', participant_name = excluded.participant_name,
        participant_email = excluded.participant_email, salon_name = excluded.salon_name,
        notice_version = excluded.notice_version, updated_at = now();
  update public.training_orders
     set status = 'paid', paid_at = coalesce(p_paid_at, now()), registration_id = v_reg, updated_at = now()
   where id = p_order;
  insert into public.outbox_emails (template, recipient, payload, account_id)
  values ('training_order_paid', 'user:' || v_o.user_id::text,
          jsonb_build_object('order_ref', v_o.order_ref, 'training_id', v_o.training_id), v_o.account_id);
  insert into public.client_audit_log (account_id, organizer_id, actor, action, entity, entity_id, payload)
  values (v_o.account_id, v_o.organizer_id,
          coalesce(nullif(current_setting('app.audit_actor', true), ''), 'system:payments'),
          'training_registered', 'training', v_o.training_id, jsonb_build_object('order', p_order));
  return v_reg;
end $$;

-- Zwolnienie opłaconego miejsca (pełny zwrot, rezygnacja przyjęta przez organizatora, odwołanie).
-- Po rozpoczęciu szkolenia (obecny / nieobecny) zapis zostaje – zwrot nie zmienia historii obecności.
create or replace function public.training_order_release_seat(p_order uuid)
returns boolean
language plpgsql set search_path = '' as $$
declare
  v_reg uuid;
  v_tid uuid;
begin
  select o.registration_id into v_reg from public.training_orders o where o.id = p_order;
  if v_reg is null then
    return false;
  end if;
  update public.training_registrations r
     set status = 'cancelled', cancelled_at = now(), updated_at = now()
   where r.id = v_reg and r.status = 'registered'
  returning r.training_id into v_tid;
  if v_tid is null then
    return false;
  end if;
  delete from public.training_participant_contacts c where c.registration_id = v_reg;
  update public.trainings t set seats_registered = t.seats_registered - 1 where t.id = v_tid;
  return true;
end $$;

-- Odrzucenie zdarzenia, które nie zgadza się z zamówieniem (kwota, waluta, zamówienie) – bez zmiany stanu,
-- z rozbieżnością i alertem. Worker i tak odpowiada operatorowi 2xx (zdarzenie zapisane; ponawianie nic nie zmieni).
create or replace function public.payment_event_reject(
  p_event bigint, p_kind text, p_provider text, p_ref text, p_order uuid)
returns text
language plpgsql set search_path = '' as $$
begin
  update public.payment_webhook_events
     set status = 'rejected_mismatch', result = p_kind, order_id = coalesce(order_id, p_order), processed_at = now()
   where id = p_event;
  perform public.payment_discrepancy_open(p_kind, p_provider, p_ref, p_order, jsonb_build_object('event', p_event));
  insert into public.client_audit_log (organizer_id, actor, action, entity, entity_id, payload)
  select o.organizer_id, coalesce(nullif(current_setting('app.audit_actor', true), ''), 'system:payments'),
         'payment_event_rejected', 'payment', p_order, jsonb_build_object('kind', p_kind)
    from public.training_orders o where o.id = p_order;
  return 'rejected_mismatch';
end $$;

-- Zdarzenie od operatora (webhook) albo z uzgadniania (reconciliation). Worker PRZED wywołaniem:
-- (1) sprawdza podpis na surowej treści i znacznik czasu (sekret tylko w sekretach Workera), (2) u operatorów,
-- którzy tego wymagają, potwierdza transakcję w API (np. weryfikacja / pobranie stanu płatności) – stan
-- bierzemy z API operatora, nie z treści żądania, (3) normalizuje kwotę do groszy. Funkcja: deduplikacja
-- po (provider, event_id), kontrola zamówienia, kwoty i waluty z bazą, przejścia stanów niezależne od
-- kolejności zdarzeń, potwierdzenie zapisu albo automatyczny zwrot (spóźniona lub podwójna płatność,
-- zawieszony organizator, odwołane szkolenie). Zwraca wynik do logów Workera (bez danych osobowych).
-- Wyniki 'unknown_ref' i 'deferred_out_of_order' → Worker odpowiada 409 (operator ponawia doręczenie);
-- pozostałe → 2xx po zapisie (przegląd red team 13.11.2026).
-- p_our_payment_id – nasz UUID płatności z metadanych sesji (app_training_payment_begin); p_charge_ref – druga
-- referencja operatora (Stripe: PaymentIntent albo charge; P24: orderId), z którą przychodzą zwroty i spory;
-- p_dispute_outcome – wynik sporu przy 'dispute.closed' ('won' | 'lost' | 'warning_closed').
create or replace function public.app_payment_webhook(
  p_provider text, p_event_id text, p_event_type text, p_provider_ref text, p_payment_ref text,
  p_order_id uuid, p_amount_grosze integer, p_currency text, p_payload_sha256 text,
  p_occurred_at timestamptz default null, p_method text default null, p_source text default 'webhook',
  p_dispute_outcome text default null, p_charge_ref text default null, p_our_payment_id uuid default null)
returns text
language plpgsql set search_path = '' as $$
declare
  v_ev      bigint;
  v_prev    text;
  v_pay_ref text;
  v_pid     uuid;
  v_oid     uuid;
  v_tid     uuid;
  v_t       public.trainings%rowtype;
  v_o       public.training_orders%rowtype;
  v_p       public.training_payments%rowtype;
  v_r       public.training_refunds%rowtype;
  v_target  text;
  v_result  text;
  v_actor   text;
  v_full    boolean;
  v_org_ok  boolean;
  v_reason  text;
  v_amt     integer;
begin
  if p_provider is null or p_provider not in ('p24','payu','tpay','stripe')
     or coalesce(p_event_id, '') !~ '^[A-Za-z0-9_.:-]{1,200}$'
     or p_event_type is null or p_event_type not in ('payment.succeeded','payment.failed','payment.cancelled',
          'payment.expired','refund.succeeded','refund.failed','dispute.opened','dispute.closed')
     or coalesce(p_provider_ref, '') !~ '^[A-Za-z0-9_.:-]{1,200}$'
     or (p_payment_ref is not null and p_payment_ref !~ '^[A-Za-z0-9_.:-]{1,200}$')
     or (p_charge_ref is not null and p_charge_ref !~ '^[A-Za-z0-9_.:-]{3,200}$')
     or coalesce(p_payload_sha256, '') !~ '^[0-9a-f]{64}$'
     or p_source is null or p_source not in ('webhook','reconciliation')
     or (p_currency is not null and p_currency !~ '^[A-Z]{3}$')
     or (p_method is not null and p_method not in ('blik','karta','przelew','inna'))
     or (p_event_type = 'dispute.closed') <> (p_dispute_outcome is not null)
     or (p_dispute_outcome is not null and p_dispute_outcome not in ('won','lost','warning_closed')) then
    raise exception 'webhook: nieprawidłowe zdarzenie' using errcode = 'BP422';
  end if;
  v_actor := 'system:' || p_source || ':' || p_provider;
  perform set_config('app.audit_actor', v_actor, true);

  -- 1. deduplikacja: równoległe doręczenie tego samego zdarzenia czeka na pierwsze i dostaje 'duplicate'
  insert into public.payment_webhook_events
    (provider, event_id, event_type, provider_ref, order_id, amount_grosze, currency, payload_sha256, source, occurred_at)
  values (p_provider, p_event_id, p_event_type, p_provider_ref, p_order_id, p_amount_grosze, p_currency,
          p_payload_sha256, p_source, p_occurred_at)
  on conflict (provider, event_id) do nothing
  returning id into v_ev;
  if v_ev is null then
    select e.id, e.status into v_ev, v_prev from public.payment_webhook_events e
     where e.provider = p_provider and e.event_id = p_event_id for update;
    if v_prev not in ('unknown_ref','deferred_out_of_order') then
      return 'duplicate';
    end if;                  -- przetwarzamy ponownie (płatność mogła się pojawić albo zostać potwierdzona)
  end if;

  -- 2. płatność, której dotyczy zdarzenie: po referencji płatności albo drugiej referencji operatora
  --    (charge / PaymentIntent – zwroty i spory), po referencji zwrotu, a na końcu po naszym UUID z metadanych
  v_pay_ref := case when p_event_type like 'payment.%' then p_provider_ref else coalesce(p_payment_ref, p_charge_ref) end;
  select p.id, p.order_id into v_pid, v_oid from public.training_payments p
   where p.provider = p_provider and (p.provider_payment_ref = v_pay_ref or p.provider_charge_ref = v_pay_ref
                                      or (p_charge_ref is not null and p.provider_charge_ref = p_charge_ref))
   order by p.attempt limit 1;
  if v_pid is null and p_event_type like 'refund.%' then
    select r.payment_id, r.order_id into v_pid, v_oid from public.training_refunds r
     where r.provider_refund_ref = p_provider_ref;
  end if;
  if v_pid is null and p_our_payment_id is not null then
    select p.id, p.order_id into v_pid, v_oid from public.training_payments p
     where p.id = p_our_payment_id and p.provider = p_provider;
    if v_pid is not null and exists (select 1 from public.training_payments p where p.id = v_pid
                                        and p.provider_payment_ref is not null and p.provider_payment_ref <> v_pay_ref
                                        and p.provider_charge_ref is distinct from v_pay_ref) then
      return public.payment_event_reject(v_ev, 'order_mismatch', p_provider, v_pay_ref, v_oid);
    end if;
  end if;
  if v_pid is null then
    update public.payment_webhook_events set status = 'unknown_ref', result = 'unknown_payment', processed_at = now()
     where id = v_ev;
    perform public.payment_discrepancy_open('unknown_payment', p_provider, coalesce(v_pay_ref, p_provider_ref), null,
                                            jsonb_build_object('event_type', p_event_type));
    return 'unknown_ref';                                   -- Worker: 409, operator ponawia
  end if;
  if p_order_id is not null and p_order_id <> v_oid then
    return public.payment_event_reject(v_ev, 'order_mismatch', p_provider, v_pay_ref, v_oid);
  end if;

  -- 3. blokady w stałej kolejności: szkolenie → zamówienie → płatność
  select o.training_id into v_tid from public.training_orders o where o.id = v_oid;
  select * into v_t from public.trainings t where t.id = v_tid for update;
  select * into v_o from public.training_orders o where o.id = v_oid for update;
  select * into v_p from public.training_payments p where p.id = v_pid for update;
  update public.payment_webhook_events set order_id = v_oid where id = v_ev;

  -- 4. zła kolejność: zwrot albo spór, zanim płatność jest potwierdzona u nas → odłożenie (409, operator
  --    ponawia); bez zapisu zwrotu „spoza portalu” i bez blokady miejsca (przegląd red team, RT1)
  if p_event_type not like 'payment.%'
     and v_p.status not in ('succeeded','partially_refunded','refunded','disputed') then
    update public.payment_webhook_events set status = 'deferred_out_of_order', result = v_p.status, processed_at = now()
     where id = v_ev;
    return 'deferred_out_of_order';
  end if;

  if p_event_type = 'payment.succeeded' then
    -- kwota i waluta muszą zgadzać się z zamówieniem w bazie (nigdy odwrotnie)
    if p_amount_grosze is distinct from v_o.amount_grosze or v_p.amount_grosze <> v_o.amount_grosze then
      return public.payment_event_reject(v_ev, 'amount_mismatch', p_provider, v_pay_ref, v_oid);
    end if;
    if p_currency is distinct from v_o.currency then
      return public.payment_event_reject(v_ev, 'currency_mismatch', p_provider, v_pay_ref, v_oid);
    end if;
    if p_charge_ref is not null and exists (select 1 from public.training_payments p
                                             where p.provider = p_provider and p.provider_charge_ref = p_charge_ref
                                               and p.id <> v_pid) then
      return public.payment_event_reject(v_ev, 'order_mismatch', p_provider, p_charge_ref, v_oid);
    end if;
    if not public.payment_status_next_ok(v_p.status, 'succeeded') then
      update public.payment_webhook_events set status = 'ignored_stale', result = v_p.status, processed_at = now()
       where id = v_ev;
      return 'ignored_stale';
    end if;
    update public.training_payments
       set status = 'succeeded', succeeded_at = coalesce(p_occurred_at, now()), method = coalesce(p_method, method),
           provider_payment_ref = coalesce(provider_payment_ref, p_provider_ref),
           provider_charge_ref = coalesce(provider_charge_ref, p_charge_ref),
           last_event_at = now(), updated_at = now()
     where id = v_pid;
    v_org_ok := exists (select 1 from public.training_organizers g
                         where g.id = v_o.organizer_id and g.status = 'active' and g.verified_at is not null);
    if v_o.status in ('reserved','expired','cancelled') then
      if v_o.status = 'reserved' then                     -- rezerwacja kończy się płatnością
        update public.trainings t set seats_held = t.seats_held - 1 where t.id = v_tid;
        v_t.seats_held := v_t.seats_held - 1;
      end if;
      if v_o.user_id is not null and v_org_ok
         and v_t.status = 'published' and now() < v_t.starts_at
         and (v_o.status = 'reserved'
              or v_t.capacity is null or v_t.seats_registered + v_t.seats_held < v_t.capacity)
         and not exists (select 1 from public.training_orders x
                          where x.training_id = v_o.training_id and x.user_id = v_o.user_id and x.id <> v_o.id
                            and x.status in ('paid','partially_refunded'))
         and not exists (select 1 from public.training_registrations r
                          where r.training_id = v_o.training_id and r.user_id = v_o.user_id
                            and r.status in ('registered','attended','no_show')) then
        update public.trainings t set seats_registered = t.seats_registered + 1 where t.id = v_tid;
        perform public.training_order_confirm(v_oid, coalesce(p_occurred_at, now()));
        v_result := case when v_o.status = 'reserved' then 'paid' else 'paid_late' end;
      else
        -- pieniądze nie powinny były wpłynąć → pełny zwrot automatyczny: zawieszony organizator, szkolenie
        -- odwołane / usunięte / rozpoczęte albo spóźniona płatność bez wolnego miejsca
        v_reason := case when not v_org_ok then 'organizator-zawieszony'
                         when v_t.status in ('cancelled','removed') then 'odwolanie'
                         else 'spozniona-platnosc' end;
        update public.training_orders
           set status = 'refund_pending', refund_reason = v_reason,
               paid_at = coalesce(p_occurred_at, now()), updated_at = now()
         where id = v_oid;
        perform public.training_refund_create(v_oid, v_pid, v_o.amount_grosze, v_reason, v_actor);
        perform public.payment_discrepancy_open('late_payment_no_seat', p_provider, v_pay_ref, v_oid,
                                                jsonb_build_object('reason', v_reason));
        if v_o.user_id is not null then
          insert into public.outbox_emails (template, recipient, payload, account_id)
          values ('training_order_late_refund', 'user:' || v_o.user_id::text,
                  jsonb_build_object('order_ref', v_o.order_ref, 'reason', v_reason), v_o.account_id);
        end if;
        v_result := 'refund_required';
      end if;
    elsif exists (select 1 from public.training_refunds r where r.payment_id = v_pid and r.status <> 'failed') then
      -- ta płatność ma już zwrot (np. z uzgadniania) – bez drugiego zwrotu „podwójna płatność”
      perform public.payment_discrepancy_open('double_payment', p_provider, v_pay_ref, v_oid,
                                              jsonb_build_object('already_refunded', true));
      v_result := 'already_refunded';
    else
      -- zamówienie już opłacone albo w zwrotach: druga udana płatność za to samo zamówienie → zwrot tej płatności
      perform public.training_refund_create(v_oid, v_pid, v_p.amount_grosze, 'podwojna-platnosc', v_actor);
      perform public.payment_discrepancy_open('double_payment', p_provider, v_pay_ref, v_oid);
      v_result := 'refund_required';
    end if;

  elsif p_event_type in ('payment.failed','payment.cancelled','payment.expired') then
    v_target := split_part(p_event_type, '.', 2);
    if not public.payment_status_next_ok(v_p.status, v_target) then
      update public.payment_webhook_events set status = 'ignored_stale', result = v_p.status, processed_at = now()
       where id = v_ev;
      return 'ignored_stale';
    end if;
    update public.training_payments
       set status = v_target, provider_payment_ref = coalesce(provider_payment_ref, p_provider_ref),
           last_event_at = now(), updated_at = now()
     where id = v_pid;
    v_result := v_target;              -- rezerwacja trwa do wygaśnięcia: kupujący może spróbować ponownie

  elsif p_event_type = 'refund.succeeded' then
    select * into v_r from public.training_refunds r where r.provider_refund_ref = p_provider_ref for update;
    if not found then
      -- webhook szybszy niż zapis referencji zwrotu: przypisz do oczekującego zwrotu tej płatności o tej kwocie
      select * into v_r from public.training_refunds r
       where r.payment_id = v_pid and r.status in ('requested','submitted') and r.provider_refund_ref is null
         and r.amount_grosze = p_amount_grosze
       order by r.created_at limit 1 for update;
      if found then
        update public.training_refunds set provider_refund_ref = p_provider_ref, updated_at = now() where id = v_r.id;
      else
        -- zwrot wykonany poza portalem (np. w panelu operatora) – zapisujemy, żeby stany i kwoty się zgadzały
        if p_amount_grosze is null or p_amount_grosze < 1
           or p_amount_grosze > v_o.amount_grosze - v_o.refunded_grosze then
          return public.payment_event_reject(v_ev, 'amount_mismatch', p_provider, p_provider_ref, v_oid);
        end if;
        insert into public.training_refunds
          (order_id, payment_id, amount_grosze, reason, status, provider_refund_ref, requested_by, submitted_at)
        values (v_oid, v_pid, p_amount_grosze, 'inne', 'submitted', p_provider_ref, 'system:operator', now())
        returning * into v_r;
        perform public.payment_discrepancy_open('external_refund', p_provider, p_provider_ref, v_oid);
      end if;
    end if;
    if v_r.status = 'succeeded' then
      update public.payment_webhook_events set status = 'ignored_stale', result = 'succeeded', processed_at = now()
       where id = v_ev;
      return 'ignored_stale';
    end if;
    if p_amount_grosze is distinct from v_r.amount_grosze
       or (v_r.reason <> 'podwojna-platnosc' and v_r.amount_grosze > v_o.amount_grosze - v_o.refunded_grosze) then
      return public.payment_event_reject(v_ev, 'amount_mismatch', p_provider, p_provider_ref, v_oid);
    end if;
    update public.training_refunds set status = 'succeeded', succeeded_at = now(), updated_at = now() where id = v_r.id;
    if v_r.reason = 'podwojna-platnosc' then
      update public.training_payments set status = 'refunded', updated_at = now() where id = v_r.payment_id;
      v_result := 'refunded_duplicate';
    else
      v_full := v_o.refunded_grosze + v_r.amount_grosze = v_o.amount_grosze;
      update public.training_orders
         set refunded_grosze = refunded_grosze + v_r.amount_grosze,
             status = case when v_full then 'refunded' else 'partially_refunded' end,
             paid_at = coalesce(paid_at, now()), updated_at = now()
       where id = v_oid;
      update public.training_payments
         set status = case when v_full then 'refunded' else 'partially_refunded' end, updated_at = now()
       where id = v_r.payment_id
         and public.payment_status_next_ok(status, case when v_full then 'refunded' else 'partially_refunded' end);
      if v_full then
        perform public.training_order_release_seat(v_oid);
      end if;
      if v_o.user_id is not null then
        insert into public.outbox_emails (template, recipient, payload, account_id)
        values ('training_order_refunded', 'user:' || v_o.user_id::text,
                jsonb_build_object('order_ref', v_o.order_ref, 'amount_grosze', v_r.amount_grosze), v_o.account_id);
      end if;
      v_result := case when v_full then 'refunded' else 'partially_refunded' end;
    end if;
    insert into public.client_audit_log (account_id, organizer_id, actor, action, entity, entity_id, payload)
    values (v_o.account_id, v_o.organizer_id, v_actor, 'training_refund_status_changed', 'training_refund', v_r.id,
            jsonb_build_object('from', v_r.status, 'to', 'succeeded'));

  elsif p_event_type = 'refund.failed' then
    select * into v_r from public.training_refunds r where r.provider_refund_ref = p_provider_ref for update;
    if not found then
      update public.payment_webhook_events set status = 'unknown_ref', result = 'unknown_refund', processed_at = now()
       where id = v_ev;
      return 'unknown_ref';
    end if;
    if v_r.status not in ('requested','submitted') then
      update public.payment_webhook_events set status = 'ignored_stale', result = v_r.status, processed_at = now()
       where id = v_ev;
      return 'ignored_stale';
    end if;
    update public.training_refunds set status = 'failed', failed_at = now(), updated_at = now() where id = v_r.id;
    -- zamówienie zostaje w 'refund_pending' – zwrot ponawia organizator albo system; alert dla zespołu
    perform public.payment_discrepancy_open('refund_failed', p_provider, p_provider_ref, v_oid);
    insert into public.client_audit_log (account_id, organizer_id, actor, action, entity, entity_id, payload)
    values (v_o.account_id, v_o.organizer_id, v_actor, 'training_refund_status_changed', 'training_refund', v_r.id,
            jsonb_build_object('from', v_r.status, 'to', 'failed'));
    v_result := 'refund_failed';

  elsif p_event_type = 'dispute.opened' then
    if not public.payment_status_next_ok(v_p.status, 'disputed') then
      update public.payment_webhook_events set status = 'ignored_stale', result = v_p.status, processed_at = now()
       where id = v_ev;
      return 'ignored_stale';
    end if;
    update public.training_payments
       set status = 'disputed', provider_charge_ref = coalesce(provider_charge_ref, p_charge_ref),
           last_event_at = now(), updated_at = now()
     where id = v_pid;
    update public.training_orders set disputed_at = coalesce(disputed_at, now()), updated_at = now() where id = v_oid;
    perform public.payment_discrepancy_open('dispute', p_provider, v_pay_ref, v_oid);
    insert into public.outbox_emails (template, recipient, payload)
    values ('training_order_disputed', 'organizer:' || v_o.organizer_id::text, jsonb_build_object('order_ref', v_o.order_ref));
    v_result := 'dispute_opened';

  else -- 'dispute.closed' z wynikiem od operatora (NormalizedEvent.disputeOutcome)
    if v_p.status <> 'disputed' then
      update public.payment_webhook_events set status = 'ignored_stale', result = v_p.status, processed_at = now()
       where id = v_ev;
      return 'ignored_stale';
    end if;
    if p_dispute_outcome in ('won','warning_closed') then
      -- środki zostają u organizatora: płatność wraca do 'succeeded', zwroty przez portal znów możliwe
      update public.training_payments set status = 'succeeded', last_event_at = now(), updated_at = now() where id = v_pid;
      update public.training_orders set disputed_at = null, updated_at = now() where id = v_oid;
      v_result := 'dispute_' || p_dispute_outcome;
    else
      -- spór przegrany: środki wróciły do kupującego przez operatora (chargeback) – zamówienie jak po zwrocie,
      -- miejsce zwolnione (bez dostępu do linku i adresu), bez zwrotu przez portal (brak podwójnego zwrotu)
      v_amt := coalesce(p_amount_grosze, v_o.amount_grosze - v_o.refunded_grosze);
      if v_amt < 1 or v_amt > v_o.amount_grosze - v_o.refunded_grosze then
        return public.payment_event_reject(v_ev, 'amount_mismatch', p_provider, v_pay_ref, v_oid);
      end if;
      v_full := v_o.refunded_grosze + v_amt = v_o.amount_grosze;
      update public.training_orders
         set refunded_grosze = refunded_grosze + v_amt, disputed_at = null,
             status = case when v_full then 'refunded' else 'partially_refunded' end,
             refund_reason = 'chargeback', paid_at = coalesce(paid_at, now()), updated_at = now()
       where id = v_oid;
      update public.training_payments
         set status = case when v_full then 'refunded' else 'partially_refunded' end, last_event_at = now(),
             updated_at = now()
       where id = v_pid;
      if v_full then
        perform public.training_order_release_seat(v_oid);
      end if;
      if v_o.user_id is not null then
        insert into public.outbox_emails (template, recipient, payload, account_id)
        values ('training_order_chargeback', 'user:' || v_o.user_id::text,
                jsonb_build_object('order_ref', v_o.order_ref, 'amount_grosze', v_amt), v_o.account_id);
      end if;
      v_result := 'dispute_lost';
    end if;
    insert into public.outbox_emails (template, recipient, payload)
    values ('training_order_dispute_closed', 'organizer:' || v_o.organizer_id::text,
            jsonb_build_object('order_ref', v_o.order_ref, 'outcome', p_dispute_outcome));
    insert into public.client_audit_log (account_id, organizer_id, actor, action, entity, entity_id, payload)
    values (v_o.account_id, v_o.organizer_id, v_actor, 'training_dispute_closed', 'training_order', v_oid,
            jsonb_build_object('outcome', p_dispute_outcome, 'amount_grosze', p_amount_grosze));
  end if;

  update public.payment_webhook_events set status = 'processed', result = v_result, processed_at = now() where id = v_ev;
  return v_result;
end $$;

-- Zwrot inicjowany przez ORGANIZATORA (rezygnacja wg jego regulaminu, odstąpienie konsumenta albo inna decyzja
-- sprzedawcy): tylko właściciel aktywnego organizatora szkolenia, poza karencją po resecie TOTP
-- (organizer_money_ok; pieniądze organizatora – personel Aura nie zleca zwrotów),
-- kwota ≤ pozostałej do zwrotu, jeden zwrot organizatora naraz. p_cancel_registration – zwolnienie miejsca
-- od razu (rezygnacja); bez niego – zwrot częściowy z zachowaniem zapisu. Wykonuje operator (klucz = id zwrotu).
create or replace function public.app_training_refund_request(
  p_order uuid, p_actor uuid, p_amount_grosze integer, p_reason text, p_cancel_registration boolean default true)
returns uuid
language plpgsql set search_path = '' as $$
declare
  v_tid uuid;
  v_org uuid;
  v_o   public.training_orders%rowtype;
  v_pay uuid;
  v_id  uuid;
begin
  select o.training_id, o.organizer_id into v_tid, v_org from public.training_orders o where o.id = p_order;
  if not found or not public.organizer_money_ok(v_org, p_actor) then
    raise exception 'refund: brak uprawnień';
  end if;
  if p_reason is null or p_reason not in ('rezygnacja','odstapienie','inne') then
    raise exception 'refund: nieprawidłowe pole reason' using errcode = 'BP422';
  end if;
  perform 1 from public.trainings t where t.id = v_tid for update;
  select * into v_o from public.training_orders o where o.id = p_order for update;
  if v_o.status not in ('paid','partially_refunded','refund_pending') then
    raise exception 'refund: zamówienie nieopłacone albo zwrócone' using errcode = 'BP409';
  end if;
  if exists (select 1 from public.training_refunds r
              where r.order_id = p_order and r.status in ('requested','submitted')) then
    raise exception 'refund: zwrot w toku' using errcode = 'BP409';
  end if;
  if v_o.disputed_at is not null then
    raise exception 'refund: płatność w sporze – rozstrzyga operator' using errcode = 'BP409';
  end if;
  if p_amount_grosze is null or p_amount_grosze < 1 or p_amount_grosze > v_o.amount_grosze - v_o.refunded_grosze then
    raise exception 'refund: nieprawidłowe pole amount_grosze' using errcode = 'BP422';
  end if;
  v_pay := public.training_order_main_payment(p_order);
  perform set_config('app.audit_actor', 'user:' || p_actor::text, true);
  update public.training_orders set status = 'refund_pending', refund_reason = p_reason, updated_at = now()
   where id = p_order;
  v_id := public.training_refund_create(p_order, v_pay, p_amount_grosze, p_reason, 'user:' || p_actor::text);
  if coalesce(p_cancel_registration, true) then
    perform public.training_order_release_seat(p_order);
  end if;
  return v_id;
end $$;

-- Wynik wywołania API zwrotu (adapter refund): referencja operatora albo kod błędu. Idempotentnie.
create or replace function public.app_training_refund_attach(
  p_refund uuid, p_provider_refund_ref text, p_failure_code text default null)
returns text
language plpgsql set search_path = '' as $$
declare
  v_r public.training_refunds%rowtype;
begin
  select * into v_r from public.training_refunds r where r.id = p_refund for update;
  if not found then
    raise exception 'refund: brak zwrotu';
  end if;
  if p_failure_code is not null then
    if coalesce(p_failure_code, '') !~ '^[A-Za-z0-9_.:-]{1,60}$' then
      raise exception 'refund: nieprawidłowe pole failure_code' using errcode = 'BP422';
    end if;
    if v_r.status in ('requested','submitted') then
      update public.training_refunds set status = 'failed', failure_code = p_failure_code, failed_at = now(),
             updated_at = now() where id = p_refund;
      perform public.payment_discrepancy_open('refund_failed', null, null, v_r.order_id,
                                              jsonb_build_object('refund', p_refund, 'code', p_failure_code));
      return 'failed';
    end if;
    return v_r.status;
  end if;
  if coalesce(p_provider_refund_ref, '') !~ '^[A-Za-z0-9_.:-]{3,200}$' then
    raise exception 'refund: nieprawidłowe pole provider_refund_ref' using errcode = 'BP422';
  end if;
  if v_r.provider_refund_ref = p_provider_refund_ref then
    return v_r.status;                         -- powtórzenie albo webhook był szybszy
  end if;
  if v_r.provider_refund_ref is not null then
    raise exception 'refund: zwrot ma już inną referencję operatora';
  end if;
  update public.training_refunds
     set provider_refund_ref = p_provider_refund_ref,
         status = case when status = 'requested' then 'submitted' else status end,
         submitted_at = coalesce(submitted_at, now()), updated_at = now()
   where id = p_refund;
  return 'submitted';
end $$;

-- Odwołanie albo usunięcie szkolenia: pełne zwroty pozostałych kwot wszystkim opłaconym zamówieniom,
-- zwolnienie miejsc, zamknięcie rezerwacji. Zamówienia w otwartym sporze (disputed_at) – BEZ zwrotu przez
-- portal (kupujący dostałby pieniądze dwa razy: z chargebacku i ze zwrotu); rozbieżność 'dispute' dla
-- zespołu i e-mail do kupującego. Wywołujący TRZYMA blokadę wiersza szkolenia.
create or replace function public.training_orders_refund_all(p_training uuid, p_actor text)
returns integer
language plpgsql set search_path = '' as $$
declare
  v_count integer := 0;
  v_left  integer;
  v_rel   boolean;
  r       record;
begin
  perform public.training_orders_close_reserved(p_training, p_actor);
  perform set_config('app.audit_actor', p_actor, true);
  for r in select o.id, o.user_id, o.account_id, o.order_ref, o.disputed_at, o.provider,
                  o.amount_grosze - o.refunded_grosze as left_grosze
             from public.training_orders o
            where o.training_id = p_training and o.status in ('paid','partially_refunded','refund_pending')
            order by o.id for update loop
    v_rel := public.training_order_release_seat(r.id);
    if r.disputed_at is not null then
      perform public.payment_discrepancy_open('dispute', r.provider, null, r.id,
                                              jsonb_build_object('training_cancelled', true));
      insert into public.outbox_emails (template, recipient, payload)
      values ('payment_dispute_training_cancelled', 'team:platnosci', jsonb_build_object('order_ref', r.order_ref));
      if r.user_id is not null then
        insert into public.outbox_emails (template, recipient, payload, account_id)
        values ('training_cancelled_dispute', 'user:' || r.user_id::text, jsonb_build_object('order_ref', r.order_ref),
                r.account_id);
      end if;
      v_count := v_count + 1;
      continue;
    end if;
    v_left := r.left_grosze - coalesce((select sum(x.amount_grosze) from public.training_refunds x
                                         where x.order_id = r.id and x.status in ('requested','submitted')
                                           and x.reason <> 'podwojna-platnosc'), 0);
    if v_left > 0 then
      update public.training_orders set status = 'refund_pending', refund_reason = 'odwolanie', updated_at = now()
       where id = r.id;
      perform public.training_refund_create(r.id, public.training_order_main_payment(r.id), v_left, 'odwolanie', p_actor);
    end if;
    -- e-mail tylko do osób z miejscem albo z nowym zwrotem (spóźniona płatność bez miejsca ma już swój zwrot)
    if r.user_id is not null and (v_left > 0 or v_rel) then
      insert into public.outbox_emails (template, recipient, payload, account_id)
      values ('training_cancelled_refund', 'user:' || r.user_id::text, jsonb_build_object('order_ref', r.order_ref),
              r.account_id);
    end if;
    v_count := v_count + 1;
  end loop;
  return v_count;
end $$;

-- Odstąpienie od umowy przez konsumenta (14 dni – dok. 11 §12a.8 [do weryfikacji prawnej]): jednostronne
-- OŚWIADCZENIE kupującego, nie prośba – portal je przyjmuje, potwierdza na trwałym nośniku (e-mail), zwalnia
-- miejsce i przekazuje organizatorowi, który zwraca płatność (app_training_refund_request, powód
-- 'odstapienie') w ustawowym terminie 14 dni; alert dla zespołu po 3 dniach bez zwrotu (app_payment_health).
-- Odmowa tylko po terminie (14 dni od zawarcia umowy = opłacenia) albo po pełnym wykonaniu usługi, której
-- rozpoczęcia przed terminem kupujący zażądał (early_start_requested_at). Idempotentnie.
create or replace function public.app_training_order_withdraw(p_order uuid, p_user uuid, p_notice_version text)
returns void
language plpgsql set search_path = '' as $$
declare
  v_tid uuid;
  v_o   public.training_orders%rowtype;
  v_t   public.trainings%rowtype;
begin
  if coalesce(char_length(p_notice_version), 0) not between 1 and 40 then
    raise exception 'withdraw: nieprawidłowe pole notice_version' using errcode = 'BP422';
  end if;
  select o.training_id into v_tid from public.training_orders o where o.id = p_order and o.user_id = p_user;
  if not found then
    raise exception 'withdraw: brak zamówienia';
  end if;
  select * into v_t from public.trainings t where t.id = v_tid for update;
  select * into v_o from public.training_orders o where o.id = p_order for update;
  if v_o.withdrawal_declared_at is not null then
    return;
  end if;
  if v_o.status not in ('paid','partially_refunded','refund_pending') then
    raise exception 'withdraw: zamówienie nieopłacone albo zwrócone' using errcode = 'BP409';
  end if;
  if now() > v_o.paid_at + interval '14 days' then
    raise exception 'withdraw: minął termin odstąpienia' using errcode = 'BP409';
  end if;
  if v_o.early_start_requested_at is not null and v_t.ends_at < now() then
    raise exception 'withdraw: usługa wykonana na żądanie kupującego' using errcode = 'BP409';
  end if;
  perform set_config('app.audit_actor', 'user:' || p_user::text, true);
  update public.training_orders
     set withdrawal_declared_at = now(), withdrawal_notice_version = p_notice_version, updated_at = now()
   where id = p_order;
  perform public.training_order_release_seat(p_order);
  insert into public.client_audit_log (account_id, organizer_id, actor, action, entity, entity_id)
  values (v_o.account_id, v_o.organizer_id, 'user:' || p_user::text, 'training_order_withdrawal_declared',
          'training_order', p_order);
  insert into public.outbox_emails (template, recipient, payload, account_id)
  values ('training_order_withdrawal_received', 'user:' || p_user::text,
          jsonb_build_object('order_ref', v_o.order_ref), v_o.account_id);
  insert into public.outbox_emails (template, recipient, payload)
  values ('training_order_withdrawal', 'organizer:' || v_o.organizer_id::text,
          jsonb_build_object('order_ref', v_o.order_ref, 'training_id', v_o.training_id,
                             'refund_due', (now() + interval '14 days')::date));
end $$;

-- Prośba uczestnika o rezygnację z opłaconego miejsca POZA ustawowym odstąpieniem (np. po 14 dniach): decyzję
-- i kwotę zwrotu wg regulaminu organizatora podejmuje organizator w panelu. Odstąpienie konsumenta w terminie
-- to osobna ścieżka – app_training_order_withdraw() (dok. 11 §12a.8). Idempotentnie.
create or replace function public.app_training_order_cancel_request(p_order uuid, p_user uuid)
returns void
language plpgsql set search_path = '' as $$
declare
  v_o public.training_orders%rowtype;
begin
  select * into v_o from public.training_orders o where o.id = p_order and o.user_id = p_user for update;
  if not found then
    raise exception 'cancel request: brak zamówienia';
  end if;
  if v_o.status not in ('paid','partially_refunded') then
    raise exception 'cancel request: zamówienie nieopłacone albo w zwrocie' using errcode = 'BP409';
  end if;
  if v_o.cancel_requested_at is not null then
    return;
  end if;
  update public.training_orders set cancel_requested_at = now(), updated_at = now() where id = p_order;
  insert into public.client_audit_log (account_id, organizer_id, actor, action, entity, entity_id)
  values (v_o.account_id, v_o.organizer_id, 'user:' || p_user::text, 'training_order_cancel_requested',
          'training_order', p_order);
  insert into public.outbox_emails (template, recipient, payload)
  values ('training_order_cancel_requested', 'organizer:' || v_o.organizer_id::text,
          jsonb_build_object('order_ref', v_o.order_ref, 'training_id', v_o.training_id));
end $$;

-- Organizator: zamówienia swojego szkolenia (SEC-01 – jedyna droga odczytu, zawsze z wpisem w dzienniku).
-- Bez adresów, NIP i e-maili – te tylko w app_organizer_invoice_data() dla jednego zamówienia.
create or replace function public.app_organizer_training_orders(p_training uuid, p_actor uuid)
returns table (order_id uuid, order_ref text, status text, amount_grosze integer, platform_fee_grosze integer,
               refunded_grosze integer, paid_at timestamptz, cancel_requested_at timestamptz,
               withdrawal_declared_at timestamptz, disputed boolean,
               participant_name text, buyer_kind text, invoice_added boolean)
language plpgsql set search_path = '' as $$
#variable_conflict use_column
begin
  if public.training_actor_kind(p_training, p_actor) is distinct from 'user:' then
    raise exception 'organizer orders: brak uprawnień';
  end if;
  insert into public.client_audit_log (organizer_id, actor, action, entity, entity_id)
  select t.organizer_id, 'user:' || p_actor::text, 'organizer_orders_viewed', 'training', p_training
    from public.trainings t where t.id = p_training;
  return query
    select o.id, o.order_ref, o.status, o.amount_grosze, o.platform_fee_grosze, o.refunded_grosze, o.paid_at,
           o.cancel_requested_at, o.withdrawal_declared_at, o.disputed_at is not null, b.participant_name, o.buyer_kind,
           (o.invoice_storage_path is not null or o.invoice_number is not null)
      from public.training_orders o
      left join public.training_order_buyer_data b on b.order_id = o.id
     where o.training_id = p_training and o.status in ('paid','refund_pending','partially_refunded','refunded')
     order by o.paid_at;
end $$;

create or replace function public.app_organizer_invoice_data(p_order uuid, p_actor uuid)
returns table (order_ref text, buyer_kind text, buyer_name text, nip text, street text, postal_code text,
               city text, invoice_email text, amount_grosze integer, paid_at timestamptz)
language plpgsql set search_path = '' as $$
#variable_conflict use_column
declare
  v_o public.training_orders%rowtype;
begin
  select * into v_o from public.training_orders o where o.id = p_order;
  if not found or public.training_actor_kind(v_o.training_id, p_actor) is distinct from 'user:'
     or v_o.status not in ('paid','refund_pending','partially_refunded','refunded') then
    raise exception 'invoice data: brak uprawnień';
  end if;
  insert into public.client_audit_log (organizer_id, actor, action, entity, entity_id)
  values (v_o.organizer_id, 'user:' || p_actor::text, 'organizer_invoice_data_viewed', 'training_order', p_order);
  return query
    select v_o.order_ref, b.buyer_kind, b.buyer_name, b.nip, b.street, b.postal_code, b.city, b.invoice_email,
           v_o.amount_grosze, v_o.paid_at
      from public.training_order_buyer_data b where b.order_id = p_order;
end $$;

-- Faktura od organizatora (opcjonalnie): numer i/lub plik PDF w prywatnym kubełku training-invoices
-- ({organizer_id}/{order_id}/{uuid}.pdf, nazwa z serwera, skrót SHA-256). Portal faktur nie wystawia.
create or replace function public.app_training_order_invoice_attach(
  p_order uuid, p_actor uuid, p_invoice_number text, p_storage_path text default null, p_sha256 text default null)
returns void
language plpgsql set search_path = '' as $$
declare
  v_o public.training_orders%rowtype;
begin
  select * into v_o from public.training_orders o where o.id = p_order for update;
  if not found or public.training_actor_kind(v_o.training_id, p_actor) is distinct from 'user:' then
    raise exception 'invoice: brak uprawnień';
  end if;
  if v_o.status not in ('paid','refund_pending','partially_refunded','refunded') then
    raise exception 'invoice: zamówienie nieopłacone' using errcode = 'BP409';
  end if;
  if coalesce(char_length(trim(p_invoice_number)), 0) not between 1 and 60 or p_invoice_number ~ '[<>]' then
    raise exception 'invoice: nieprawidłowe pole invoice_number' using errcode = 'BP422';
  end if;
  if (p_storage_path is null) <> (p_sha256 is null)
     or (p_storage_path is not null and (p_storage_path not like v_o.organizer_id::text || '/' || p_order::text || '/%'
                                         or p_sha256 !~ '^[0-9a-f]{64}$')) then
    raise exception 'invoice: nieprawidłowe pole storage_path' using errcode = 'BP422';
  end if;
  update public.training_orders
     set invoice_number = trim(p_invoice_number), invoice_storage_path = p_storage_path, invoice_sha256 = p_sha256,
         invoice_added_at = now(), updated_at = now()
   where id = p_order;
  insert into public.client_audit_log (account_id, organizer_id, actor, action, entity, entity_id)
  values (v_o.account_id, v_o.organizer_id, 'user:' || p_actor::text, 'training_invoice_attached', 'training_order', p_order);
  if v_o.user_id is not null then
    insert into public.outbox_emails (template, recipient, payload, account_id)
    values ('training_invoice_available', 'user:' || v_o.user_id::text, jsonb_build_object('order_ref', v_o.order_ref),
            v_o.account_id);
  end if;
end $$;

-- Pobranie pliku faktury: kupujący (własne zamówienie), właściciel salonu (tylko faktura na NIP salonu –
-- bill_to_account)
-- albo organizator szkolenia. Serwer podpisuje URL kluczem serwisowym dopiero po tej kontroli (60 s,
-- download – jak dokumenty polis, 10.1); kubełek training-invoices nie ma polityk dla authenticated.
create or replace function public.app_training_invoice_path(p_order uuid, p_actor uuid)
returns text
language plpgsql stable set search_path = '' as $$
declare
  v_path text;
begin
  select o.invoice_storage_path into v_path from public.training_orders o
   where o.id = p_order and o.invoice_storage_path is not null
     and (o.user_id = p_actor
          or (o.bill_to_account and exists (
                select 1 from public.client_members m
                  join public.client_accounts a on a.id = m.account_id and a.status = 'active'
                 where m.account_id = o.account_id and m.user_id = p_actor
                   and m.role = 'owner' and m.status = 'active'))
          or public.training_actor_kind(o.training_id, p_actor) = 'user:');
  if v_path is null then
    raise exception 'invoice: brak pliku albo uprawnień';
  end if;
  return v_path;
end $$;

-- Uzgadnianie z raportami operatora (zadanie dzienne w Workerze): płatność potwierdzona u operatora, a nie
-- w bazie → serwer woła app_payment_webhook() ze zdarzeniem syntetycznym (source = 'reconciliation',
-- event_id 'recon:<referencja>:<stan>') – ta sama, idempotentna ścieżka; pozostałe rozbieżności – tutaj.
create or replace function public.app_payment_discrepancy_report(
  p_kind text, p_provider text, p_ref text, p_order uuid, p_details jsonb default '{}'::jsonb)
returns boolean
language plpgsql set search_path = '' as $$
begin
  if p_kind is null or p_kind not in ('confirmed_not_paid','paid_not_confirmed','amount_mismatch','seat_counter',
                                      'reservation_stuck','refund_stuck','cancel_request_stale','unknown_payment',
                                      'withdrawal_overdue','kyb_mismatch') then
    raise exception 'discrepancy: nieprawidłowe pole kind' using errcode = 'BP422';
  end if;
  return public.payment_discrepancy_open(p_kind, p_provider, p_ref, p_order, p_details);
end $$;

create or replace function public.app_payment_discrepancy_resolve(p_id bigint, p_actor uuid, p_resolution text)
returns void
language plpgsql set search_path = '' as $$
begin
  if not exists (select 1 from public.admin_users u
                 where u.user_id = p_actor and u.is_active and u.role in ('admin','agent')) then
    raise exception 'discrepancy: brak uprawnień';
  end if;
  if coalesce(char_length(trim(p_resolution)), 0) not between 5 and 500 or p_resolution ~ '[<>]' then
    raise exception 'discrepancy: nieprawidłowe pole resolution' using errcode = 'BP422';
  end if;
  update public.payment_discrepancies
     set resolved_at = now(), resolved_by = p_actor, resolution = trim(p_resolution)
   where id = p_id and resolved_at is null;
  if not found then
    raise exception 'discrepancy: brak otwartej pozycji';
  end if;
  insert into public.client_audit_log (actor, action, entity, payload)
  values ('staff:' || p_actor::text, 'payment_discrepancy_resolved', 'payment', jsonb_build_object('id', p_id));
end $$;

-- Kontrole spójności (Cron co 5 minut, razem z wygaszaniem rezerwacji; wynik > 0 → alert dla zespołu; dok. 11 §12a.13)
create or replace function public.app_payment_health()
returns table (check_name text, n bigint)
language sql stable set search_path = '' as $$
  select 'reservation_stuck', count(*) from public.training_orders o
   where o.status = 'reserved' and o.reserved_until < now() - interval '5 minutes'
  union all
  select 'refund_stuck', count(*) from public.training_refunds r
   where r.status in ('requested','submitted') and r.created_at < now() - interval '24 hours'
  union all
  select 'cancel_request_stale', count(*) from public.training_orders o
   where o.status in ('paid','partially_refunded') and o.cancel_requested_at < now() - interval '7 days'
  union all
  -- odstąpienie konsumenta bez zleconego zwrotu po 3 dniach (ustawowy termin zwrotu – 14 dni) [do weryfikacji prawnej]
  select 'withdrawal_overdue', count(*) from public.training_orders o
   where o.withdrawal_declared_at < now() - interval '3 days' and o.status in ('paid','partially_refunded')
     and not exists (select 1 from public.training_refunds r where r.order_id = o.id and r.status <> 'failed'
                        and r.created_at >= o.withdrawal_declared_at)
  union all
  -- sesja płatności bez wyniku po 48 h (uzgadnianie co 15 minut nie znalazło jej u operatora)
  select 'payment_pending_stale', count(*) from public.training_payments p
   where p.status = 'pending' and p.created_at < now() - interval '48 hours'
  union all
  select 'paid_without_registration', count(*) from public.training_orders o
   where o.status = 'paid' and not exists (select 1 from public.training_registrations r
                                            where r.id = o.registration_id and r.status in ('registered','attended','no_show'))
  union all
  select 'seat_counter', count(*) from public.trainings t
   where t.seats_held <> (select count(*) from public.training_orders o where o.training_id = t.id and o.status = 'reserved')
      or t.seats_registered <> (select count(*) from public.training_registrations r
                                 where r.training_id = t.id and r.status in ('registered','attended','no_show'))
  union all
  select 'open_discrepancies', count(*) from public.payment_discrepancies d where d.resolved_at is null;
$$;

-- Retencja (Cron dziennie) [Założenie: okresy; obowiązki księgowe i DAC7 – do potwierdzenia, dok. 11 §12a.12]:
--  * dane kupującego i do faktury – 90 dni po zakończeniu szkolenia (organizator ma je w swojej księgowości),
--    nie przy otwartym zwrocie ani sporze; zamówienia nieopłacone – 7 dni od utworzenia;
--  * zamówienie – 12 miesięcy po szkoleniu bez powiązania z osobą i kontem (plik faktury serwer usuwa
--    z kubełka wcześniej, wg ścieżek z tego samego warunku);
--  * zdarzenia operatora – 13 miesięcy; rekord finansowy bez danych osobowych (zamówienie, płatności, zwroty)
--    – do końca 5. roku po roku szkolenia; rozbieżności zamknięte – 24 miesiące.
create or replace function public.app_purge_training_orders()
returns integer
language plpgsql set search_path = '' as $$
declare
  v_buyers integer;
  v_anon   integer;
  v_old    integer;
begin
  delete from public.training_order_buyer_data b
   using public.training_orders o, public.trainings t
   where o.id = b.order_id and t.id = o.training_id
     and ((o.status in ('expired','cancelled') and o.created_at < now() - interval '7 days')
       or (o.status in ('paid','partially_refunded','refunded') and t.ends_at < now() - interval '90 days'
           and o.disputed_at is null
           and not exists (select 1 from public.training_refunds r
                            where r.order_id = o.id and r.status in ('requested','submitted'))));
  get diagnostics v_buyers = row_count;
  update public.training_orders o
     set user_id = null, account_id = null, invoice_storage_path = null, invoice_sha256 = null,
         anonymized_at = now(), updated_at = now()
    from public.trainings t
   where t.id = o.training_id and o.anonymized_at is null
     and o.status not in ('reserved','refund_pending')
     and t.ends_at < now() - interval '12 months';
  get diagnostics v_anon = row_count;
  delete from public.payment_webhook_events e where e.received_at < now() - interval '13 months';
  delete from public.payment_discrepancies d where d.resolved_at < now() - interval '24 months';
  with old as (
    select o.id from public.training_orders o join public.trainings t on t.id = o.training_id
     where o.anonymized_at is not null
       and t.ends_at < date_trunc('year', now()) - interval '5 years'),
  r as (delete from public.training_refunds x using old where x.order_id = old.id returning 1),
  p as (delete from public.training_payments x using old where x.order_id = old.id
         and not exists (select 1 from public.training_refunds y where y.payment_id = x.id and y.order_id <> old.id)
        returning 1)
  select count(*) into v_old from old;
  delete from public.training_orders o
   where o.anonymized_at is not null
     and not exists (select 1 from public.training_payments p where p.order_id = o.id)
     and exists (select 1 from public.trainings t where t.id = o.training_id
                  and t.ends_at < date_trunc('year', now()) - interval '5 years');
  insert into public.client_audit_log (actor, action, entity, payload)
  values ('system:cron', 'training_orders_purged', 'training_order',
          jsonb_build_object('buyer_data', v_buyers, 'anonymized', v_anon, 'old', v_old));
  return v_buyers + v_anon;
end $$;

-- Uprawnienia funkcji zapisu i funkcji wewnętrznych: wyłącznie service_role
revoke execute on function
  public.app_activate_client_account(uuid, uuid, text, text),
  public.app_create_invitation(uuid, uuid, text, text, text),
  public.app_rotate_invitation_token(uuid, uuid, text),
  public.app_accept_invitation(text, uuid, text),
  public.app_accept_terms(uuid, uuid, text),
  public.app_revoke_member(uuid, uuid, uuid),
  public.app_confirm_team(uuid, uuid),
  public.app_revoke_dormant_members(),
  public.app_moderate_job_offer(uuid, uuid, text, integer, text, text),
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
  public.promo_ad_days(),
  public.app_set_promotion(text, boolean, uuid, text, timestamptz),
  public.nip_checksum_ok(text),
  public.app_employer_register(uuid, text, text, text),
  public.app_employer_record_gus(uuid, text, jsonb),
  public.app_employer_activate(uuid, uuid),
  public.app_phone_send_code(uuid, text, text, text, text),
  public.app_phone_verify_code(uuid, uuid, text),
  public.app_job_seeker_register(uuid, boolean, text, text),
  public.candidate_ad_check_payload(jsonb),
  public.app_candidate_ad_save(uuid, jsonb, text),
  public.app_candidate_ad_delete(uuid),
  public.app_job_seeker_close(uuid),
  public.app_moderate_candidate_ad(uuid, uuid, text, integer, text, text),
  public.app_candidate_contact(uuid, uuid, uuid, jsonb),
  public.app_report_candidate_ad(uuid, text, text, text, boolean, text),
  public.app_report_candidate_contact(uuid, text, text, text, boolean, text),
  public.app_purge_candidate_ads(),
  public.organizer_plan_until(uuid),
  public.organizer_plan_sync(uuid),
  public.app_set_organizer_plan(uuid, uuid, text, timestamptz, text),
  public.app_cancel_organizer_plan(uuid, uuid, text),
  public.app_sync_organizer_plans(),
  -- 1.4 (przegląd red team)
  public.app_training_participants(uuid, uuid, text),
  public.app_employer_trust(uuid, uuid, text),
  public.employer_trusted_actor(uuid, uuid),
  public.account_content_takedown(uuid, text, text, boolean),
  public.app_suspend_account(uuid, uuid, text),
  public.app_suspend_job_seeker(uuid, uuid, text),
  public.app_reply_address_from_login(uuid, uuid, text),
  public.app_reply_address_request(uuid, uuid, text, text),
  public.app_reply_address_confirm(text),
  public.app_candidate_ads_page(uuid, uuid, jsonb, jsonb),
  public.app_release_candidate_contact(uuid, uuid, text),
  public.app_candidate_block_employer(uuid, uuid),
  public.app_candidate_hidden_nips_set(uuid, text[]),
  public.abuse_report_check(text, text, text, boolean, text),
  public.app_set_organizer_plan_invoice(uuid, uuid, text),
  public.app_purge_inactive_accounts(),
  public.app_purge_verification_data(),
  -- 00, D41 (zabiegi); public.zabiegi_ids(boolean) – granty przy definicji (authenticated i service_role)
  public.zabiegi_filter(jsonb),
  public.app_job_offers_page(jsonb, jsonb),
  -- 00, D42 (płatności za szkolenia)
  public.platform_fee_current(timestamptz),
  public.app_set_platform_fee(uuid, integer, integer, timestamptz, text),
  public.organizer_owner_ok(uuid, uuid),
  -- przegląd red team płatności (13.11.2026)
  public.organizer_money_ok(uuid, uuid),
  public.payout_alert(uuid, text, jsonb),
  public.app_organizer_owner_mfa_reset(uuid, uuid),
  public.app_payout_link_issued(uuid, uuid, timestamptz),
  public.training_orders_close_reserved(uuid, text),
  public.app_suspend_organizer(uuid, uuid, text),
  public.app_checkouts_to_cancel(integer),
  public.app_payments_to_reconcile(integer),
  public.training_order_payable_error(uuid),
  public.app_training_payment_begin(uuid, uuid, text),
  public.app_training_order_withdraw(uuid, uuid, text),
  public.app_payout_account_register(uuid, uuid, text, text),
  public.app_payout_account_set_status(text, text, boolean, boolean, boolean, boolean, boolean, text),
  public.app_sales_terms_submit(uuid, uuid, jsonb),
  public.app_sales_terms_moderate(uuid, uuid, text, text),
  public.training_orders_expire_for(uuid),
  public.app_expire_training_orders(),
  public.app_training_order_create(uuid, uuid, uuid, uuid, uuid, text, text, jsonb, text, text),
  public.app_training_order_abandon(uuid, uuid),
  public.app_training_payment_attach(uuid, uuid, text, text, timestamptz, uuid),
  public.payment_status_next_ok(text, text),
  public.payment_discrepancy_open(text, text, text, uuid, jsonb),
  public.training_order_main_payment(uuid),
  public.training_refund_create(uuid, uuid, integer, text, text),
  public.training_order_confirm(uuid, timestamptz),
  public.training_order_release_seat(uuid),
  public.payment_event_reject(bigint, text, text, text, uuid),
  public.app_payment_webhook(text, text, text, text, text, uuid, integer, text, text, timestamptz, text, text, text, text, uuid),
  public.app_training_refund_request(uuid, uuid, integer, text, boolean),
  public.app_training_refund_attach(uuid, text, text),
  public.training_orders_refund_all(uuid, text),
  public.app_training_order_cancel_request(uuid, uuid),
  public.app_organizer_training_orders(uuid, uuid),
  public.app_organizer_invoice_data(uuid, uuid),
  public.app_training_order_invoice_attach(uuid, uuid, text, text, text),
  public.app_training_invoice_path(uuid, uuid),
  public.app_payment_discrepancy_report(text, text, text, uuid, jsonb),
  public.app_payment_discrepancy_resolve(bigint, uuid, text),
  public.app_payment_health(),
  public.app_purge_training_orders()
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
  public.app_moderate_job_offer(uuid, uuid, text, integer, text, text),
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
  -- P1: przełącznik, promocja, pracodawcy, telefon, „Szukam pracy”, plany organizatorów, retencja
  public.app_require_feature(text),
  public.app_set_feature_flag(text, boolean, uuid, text),
  public.promo_ad_days(),
  public.app_set_promotion(text, boolean, uuid, text, timestamptz),
  public.nip_checksum_ok(text),
  public.app_employer_register(uuid, text, text, text),
  public.app_employer_record_gus(uuid, text, jsonb),
  public.app_employer_activate(uuid, uuid),
  public.app_phone_send_code(uuid, text, text, text, text),
  public.app_phone_verify_code(uuid, uuid, text),
  public.app_job_seeker_register(uuid, boolean, text, text),
  public.candidate_ad_check_payload(jsonb),
  public.app_candidate_ad_save(uuid, jsonb, text),
  public.app_candidate_ad_delete(uuid),
  public.app_job_seeker_close(uuid),
  public.app_moderate_candidate_ad(uuid, uuid, text, integer, text, text),
  public.app_candidate_contact(uuid, uuid, uuid, jsonb),
  public.app_report_candidate_ad(uuid, text, text, text, boolean, text),
  public.app_report_candidate_contact(uuid, text, text, text, boolean, text),
  public.app_purge_candidate_ads(),
  public.organizer_plan_until(uuid),
  public.organizer_plan_sync(uuid),
  public.app_set_organizer_plan(uuid, uuid, text, timestamptz, text),
  public.app_cancel_organizer_plan(uuid, uuid, text),
  public.app_sync_organizer_plans(),
  -- 1.4 (przegląd red team)
  public.app_training_participants(uuid, uuid, text),
  public.app_employer_trust(uuid, uuid, text),
  public.employer_trusted_actor(uuid, uuid),
  public.account_content_takedown(uuid, text, text, boolean),
  public.app_suspend_account(uuid, uuid, text),
  public.app_suspend_job_seeker(uuid, uuid, text),
  public.app_reply_address_from_login(uuid, uuid, text),
  public.app_reply_address_request(uuid, uuid, text, text),
  public.app_reply_address_confirm(text),
  public.app_candidate_ads_page(uuid, uuid, jsonb, jsonb),
  public.app_release_candidate_contact(uuid, uuid, text),
  public.app_candidate_block_employer(uuid, uuid),
  public.app_candidate_hidden_nips_set(uuid, text[]),
  public.abuse_report_check(text, text, text, boolean, text),
  public.app_set_organizer_plan_invoice(uuid, uuid, text),
  public.app_purge_inactive_accounts(),
  public.app_purge_verification_data(),
  -- 00, D41 (zabiegi)
  public.zabiegi_filter(jsonb),
  public.app_job_offers_page(jsonb, jsonb),
  -- 00, D42 (płatności za szkolenia)
  public.platform_fee_current(timestamptz),
  public.app_set_platform_fee(uuid, integer, integer, timestamptz, text),
  public.organizer_owner_ok(uuid, uuid),
  -- przegląd red team płatności (13.11.2026)
  public.organizer_money_ok(uuid, uuid),
  public.payout_alert(uuid, text, jsonb),
  public.app_organizer_owner_mfa_reset(uuid, uuid),
  public.app_payout_link_issued(uuid, uuid, timestamptz),
  public.training_orders_close_reserved(uuid, text),
  public.app_suspend_organizer(uuid, uuid, text),
  public.app_checkouts_to_cancel(integer),
  public.app_payments_to_reconcile(integer),
  public.training_order_payable_error(uuid),
  public.app_training_payment_begin(uuid, uuid, text),
  public.app_training_order_withdraw(uuid, uuid, text),
  public.app_payout_account_register(uuid, uuid, text, text),
  public.app_payout_account_set_status(text, text, boolean, boolean, boolean, boolean, boolean, text),
  public.app_sales_terms_submit(uuid, uuid, jsonb),
  public.app_sales_terms_moderate(uuid, uuid, text, text),
  public.training_orders_expire_for(uuid),
  public.app_expire_training_orders(),
  public.app_training_order_create(uuid, uuid, uuid, uuid, uuid, text, text, jsonb, text, text),
  public.app_training_order_abandon(uuid, uuid),
  public.app_training_payment_attach(uuid, uuid, text, text, timestamptz, uuid),
  public.payment_status_next_ok(text, text),
  public.payment_discrepancy_open(text, text, text, uuid, jsonb),
  public.training_order_main_payment(uuid),
  public.training_refund_create(uuid, uuid, integer, text, text),
  public.training_order_confirm(uuid, timestamptz),
  public.training_order_release_seat(uuid),
  public.payment_event_reject(bigint, text, text, text, uuid),
  public.app_payment_webhook(text, text, text, text, text, uuid, integer, text, text, timestamptz, text, text, text, text, uuid),
  public.app_training_refund_request(uuid, uuid, integer, text, boolean),
  public.app_training_refund_attach(uuid, text, text),
  public.training_orders_refund_all(uuid, text),
  public.app_training_order_cancel_request(uuid, uuid),
  public.app_organizer_training_orders(uuid, uuid),
  public.app_organizer_invoice_data(uuid, uuid),
  public.app_training_order_invoice_attach(uuid, uuid, text, text, text),
  public.app_training_invoice_path(uuid, uuid),
  public.app_payment_discrepancy_report(text, text, text, uuid, jsonb),
  public.app_payment_discrepancy_resolve(bigint, uuid, text),
  public.app_payment_health(),
  public.app_purge_training_orders()
  to service_role;

-- Test w CI (rozszerzenie packages/db/tests/privileges.test.sql) – pełna lista w pkt 9.6 dokumentu 11.
-- TEST-21: uruchamiany na lokalnym stosie Supabase CLI albo na gałęzi projektu (prawdziwe role anon,
-- authenticated, service_role, postgres i ustawienia Data API), nie tylko na czystym Postgresie; asercja,
-- że właściciel funkcji DEFINER (client_account_ids, employer_account_ids, organizer_ids) ma oczekiwane
-- atrybuty (BYPASSRLS albo polityki, które go obejmują) – od tego zależy działanie na tabelach z FORCE RLS
-- [do weryfikacji w Supabase].
--  (1) żadna funkcja w public nie ma EXECUTE dla anon ani PUBLIC; dla authenticated tylko app_is_staff,
--      client_account_ids, organizer_ids, employer_account_ids i zabiegi_ids (CHECK w job_offers – 00, D41);
--  (2) client_policy_reminders, job_offer_relay_log, candidate_ad_contact_log, phone_verifications,
--      sms_send_log, candidate_blocks, candidate_ad_views_daily i training_participant_contacts na liście
--      service_role_only;
--  (3) właściciel salonu A nie widzi żadnego wiersza salonu B; organizator A – żadnego wiersza
--      organizatora B, 0 wierszy client_* i 0 szkiców job_offers;
--  (4) pracownik nie widzi client_policies, client_policy_documents, job_offer_contacts ani obiektów
--      w kubełku client-documents;
--  (5) anon: tylko opublikowane, nieprzeterminowane ogłoszenia i tylko kolumny publiczne
--      (select account_id → permission denied); job_offer_contacts → permission denied;
--      szkolenia tylko organizatorów z aktywnym planem;
--  (6) właściciel z sesją aal1 → pusty client_account_ids('owner') i employer_account_ids();
--      organizator z aal1 → pusty organizer_ids();
--  (7) właściciel: UPDATE published_at → permission denied; zmiana treści w pending_review → wyjątek;
--      moderacja z nieaktualną wersją → wyjątek; ogłoszenie bez weryfikacji GUS/telefonu → naruszenie RLS;
--      telefon albo e-mail w treści oferty → naruszenie CHECK; organizator: INSERT status 'published' →
--      wyjątek, UPDATE capacity → permission denied;
--  (8) organizator: training_registrations → 0 wierszy; training_participant_contacts przez Data API →
--      permission denied; app_training_participants() – tylko własne szkolenia, każde wywołanie w dzienniku;
--  (9) client_audit_log: UPDATE → wyjątek; TRUNCATE i DELETE jako service_role → permission denied;
--  (10) „Szukam pracy”: token pracodawcy + Data API → 0 wierszy candidate_ads; app_candidate_ads_page()
--       tylko dla employer_trusted_actor(), 20 kart, kwota dzienna (BP429) i jednorazowy alert; ukryte NIP
--       i blokady respektowane; nowy ad_ref po ponownej publikacji; przy wyłączonym przełączniku → BP404;
--  (11) SMS: limity z sms_send_log (globalny dobowy i godzinowy, bezpiecznik konwersji, konto, numer,
--       prefiks, 60 s, limit kont na numer – zawsze neutralne BP429); wysyłka → usunięcie użytkownika →
--       limity bez zmian; 5 prób, wygaśnięcie;
--  (12) 21 dni: expires_at > published_at + 21 dni → naruszenie CHECK w job_offers i candidate_ads;
--  (13) pracodawca: rejestracja z NIP istniejącego konta – neutralnie (konto pending, bez BP409);
--       aktywacja przy aktywnym koncie NIP → 'conflict' + e-mail do właściciela; konto z potwierdzoną
--       reprezentacją przejmuje NIP od konta bez potwierdzenia; zmiana NIP przez personel zeruje GUS i zaufanie;
--  (14) adresy pracodawcy: publikacja i formularz tylko z potwierdzonym adresem; reply_to spoza listy → BP422;
--  (15) zawieszenie konta: anon widzi 0 ofert konta, outbox job_relay/candidate_contact pusty, e-mail
--       z uzasadnieniem; zawieszenie osoby szukającej pracy zdejmuje ogłoszenie z uzasadnieniem;
--  (16) błędne dane w funkcjach → kod BP422 bez wartości w komunikacie (PRIV-12);
--  (17) równoległe żądania (dwie sesje): limit szkiców, wiadomości pracodawcy i kont na numer nie są
--       przekraczane (SEC-18);
--  (18) retencja: zgłoszenia anonimizowane po 12 miesiącach, ogłoszenia w moderacji 30 dni, oferty
--       12 miesięcy po zakończeniu, wyniki GUS zamkniętych kont, konta nieużywane (ostrzeżenie → zamknięcie);
--  (19) zabiegi (00, D41): identyfikator spoza listy, null w tablicy, 31 różnych zabiegów → BP422 w guardzie
--       i w app_candidate_ad_save(), a z pominięciem guardu – naruszenie CHECK; powtórzenia usunięte, zapis
--       posortowany; zmiana zabiegów w opublikowanej ofercie → ponowna moderacja; wycofana pozycja zostaje
--       w ogłoszeniu, które ją ma, ale nie da się jej dodać; filtr LUB (zabiegi && …) w app_job_offers_page()
--       i app_candidate_ads_page() bez zmiany kolejności (od najnowszej); nieznany identyfikator w filtrze
--       → BP422 bez naliczenia kwoty; anon: kolumna zabiegi czytelna, RLS i kwoty bez zmian;
--       gen_zabiegi_sql.py --check zgodny z snippets/zabiegi-oc-beauty.json.
--  (20) płatności za szkolenia (00, D42; dok. 11 §12a.15): authenticated nie wykonuje app_training_order_create()
--       ani app_payment_webhook(); kwota zamówienia = cena szkolenia z bazy (pola kwoty w danych z formularza
--       ignorowane), prowizja 0 w promocji; ten sam klucz idempotencji i druga karta → to samo zamówienie;
--       brak nadsprzedaży (5 równoległych sesji o 1 miejsce → 1 rezerwacja, 4 × BP409); wygaśnięcie rezerwacji
--       (cron i „leniwie” przy nowym zamówieniu) zwalnia miejsce; webhook: zła kwota, waluta albo zamówienie →
--       rejected_mismatch + rozbieżność, to samo zdarzenie → duplicate (także 3 doręczenia naraz), „failed” po
--       „succeeded” → ignored_stale, spóźniona płatność bez miejsca → zwrot automatyczny, z wolnym miejscem →
--       zapis, podwójna płatność → zwrot drugiej; zwrot tylko przez właściciela organizatora (nie członek, nie
--       personel), kwota ≤ pozostałej, webhook zwrotu szybszy niż zapis referencji; odwołanie szkolenia → zwroty
--       wszystkim i zamknięte rezerwacje; RLS: kupujący – własne zamówienia i dane do faktury (bez user_id,
--       idempotency_key), organizator – 0 wierszy (tylko funkcje z dziennikiem), personel aal2 – zamówienia bez
--       danych kupujących, anon – permission denied; retencja: dane kupującego 90 dni po szkoleniu (nieopłacone –
--       7 dni), zamówienie anonimizowane po 12 miesiącach z zachowaniem kwot.
--  (21) przegląd red team płatności (13.11.2026; dok. 11 §12a.15): zwrot / spór przed płatnością →
--       deferred_out_of_order bez zapisu, po płatności i ponowieniu jeden zwrot; dispute.closed: lost → refunded,
--       chargeback, zapis anulowany, bez zwrotu przez portal; won → disputed_at = null, zwroty znów możliwe; bez
--       wyniku → BP422; odwołanie szkolenia z opłaconymi zamówieniami: członek, agent → odmowa, admin bez
--       uzasadnienia → BP422, zamówienie w sporze bez zwrotu; bill_to_account: zakup pracownika na własny NIP
--       niewidoczny dla właściciela (RLS i plik), pracownik na NIP salonu → BP409; karencja 72 h konta wypłat
--       (publikacja i zamówienie → BP409), link bez świeżego TOTP → BP409, alerty, zmiana rachunku → ponowna
--       karencja, NIP z KYB innej firmy → restricted + kyb_mismatch, 72 h bez zwrotów po resecie TOTP;
--       zawieszenie zamyka rezerwacje (funkcją i cronem), nowa sesja → BP409, płatność po zawieszeniu → zwrot
--       'organizator-zawieszony', sesje do cancelCheckout; płatność po naszym UUID bez referencji, zwrot po
--       drugiej referencji, unknown_ref także przy ponowieniu; rezerwacja Stripe = 30 min; szkolenie < 14 dni
--       bez żądania wcześniejszego rozpoczęcia → BP422; odstąpienie: zapis, miejsce, e-maile, alert po 3 dniach,
--       po 14 dniach → BP409; limit sprzedaży nowego organizatora → BP409.
