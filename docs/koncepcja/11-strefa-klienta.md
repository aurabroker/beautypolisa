# 11 · Strefa Klienta – konto salonu: polisy, „Dam pracę”, „Szkolenia”

| | |
|---|---|
| Wersja | 1.0 (do akceptacji zleceniodawcy) |
| Data | 11 listopada 2026 |
| Zakres | Konto klienta dla salonu, który kupił polisę przez BeautyPolisa: polisy i dokumenty, dział „Dam pracę”, dział „Szkolenia” |
| Wymaganie źródłowe | „Salon, który kupi u nas polisę, będzie miał swoje konto z polisami, dostęp do działu DAM PRACĘ, Szkolenia” (zleceniodawca, 11.11.2026) |
| Pliki towarzyszące | `snippets/strefa-klienta.sql` (DDL, RLS, funkcje); makiety `design/v3/logowanie.html`, `panel.html`, `dam-prace.html`, `szkolenia.html` (w przygotowaniu) |
| Status | Koncepcja – nic z tego dokumentu nie jest wdrożone |

> Fakty biznesowe pochodzą wyłącznie z `01-audyt-stanu-obecnego.md`. Strukturę istniejących modułów projektu Supabase „BEAUTY” sprawdzono 11.11.2026 zapytaniami do katalogu systemowego (nazwy tabel i kolumn, polityki RLS, uprawnienia, liczby wierszy) – bez odczytu treści wierszy. Wszystko, czego nie da się wyprowadzić z audytu, jest oznaczone jako **Założenie** (do decyzji zleceniodawcy) albo „[do weryfikacji]”.

## TL;DR

1. **Strefa Klienta to druga, prywatna część tej samej aplikacji Next.js** (`/strefa-klienta/*`) w tym samym, nowym projekcie Supabase co portal (D2). Nie korzystamy z bazy „BEAUTY” na żywo: jej moduły ogłoszeń o pracę i szkoleń mają tylko 1 ogłoszenie, 0 aplikacji, 6 szkoleń i 0 zapisów, a ich model (płatne ogłoszenia, aplikacje tylko z kontem, publiczny odczyt telefonu i e-maila ogłoszeniodawcy) nie pasuje do wymagań. **Rekomendacja: nowe tabele w projekcie portalu, jednorazowa migracja tych kilku wierszy, CRM w „BEAUTY” zostaje systemem źródłowym polis** z jednokierunkowym przekazem do portalu w fazie Z3.
2. **Konto zakłada wyłącznie Aura Consulting** (Założenie): broker dodaje polisę i jej dokumenty PDF w `/panel`, publikuje je i aktywuje konto. Właściciel salonu dostaje zaproszenie e-mailem. Rejestracji otwartej nie ma.
3. **Logowanie bez hasła:** sześciocyfrowy kod jednorazowy z e-maila (Supabase Auth), sesja serwerowa w ciasteczkach `HttpOnly`, opcjonalny drugi składnik TOTP dla właściciela. Gdy TOTP jest włączony, baza sama wymaga sesji `aal2`.
4. **Role:** właściciel salonu (polisy, dokumenty, zespół, oferty pracy, aplikacje kandydatów, szkolenia), pracownik (szkolenia, podgląd ofert salonu – bez polis i bez danych kandydatów), personel Aura (`admin`/`agent`/`viewer` z `/panel`), kandydat bez konta (przegląda oferty i aplikuje formularzem).
5. **Izolację salonów egzekwuje Postgres (RLS)**, nie interfejs: jedna funkcja pomocnicza `client_account_ids()`, kolumnowe uprawnienia, zapisy z niezmiennikami między salonami wyłącznie przez funkcje `service_role`. Model sprawdzono na lokalnym Postgresie 16: właściciel salonu B nie widzi niczego z salonu A, pracownik nie widzi polis ani plików, `anon` widzi tylko publiczne kolumny opublikowanych ofert.
6. **„Dam pracę”:** oferty publiczne i indeksowane (schema.org `JobPosting` dla Google for Jobs), moderowane przed publikacją, ważne 30 dni (Założenie), z obowiązkowymi widełkami wynagrodzenia. Kandydat aplikuje bez konta. W MVP **bez plików CV** – wgrywanie CV dopiero ze skanowaniem antywirusowym. Salon jest administratorem danych kandydatów, Aura – podmiotem przetwarzającym (do weryfikacji przez prawnika, tak samo jak kwestia, czy prowadzenie tablicy nie jest „pośrednictwem pracy” wymagającym wpisu do KRAZ).
7. **„Szkolenia”:** publiczny katalog, zapis z konta salonu, limit miejsc z listą rezerwową, przypomnienia e-mailem. Płatności online i certyfikaty – później.
8. **Prywatność i wydajność:** strony strefy są dynamiczne, `no-store`, `noindex`, bez klienta Supabase w przeglądarce i bez nowych hostów zewnętrznych. Publiczne „Dam pracę” i „Szkolenia” mają dane w cache z rewalidacją po publikacji.
9. **Plan:** Z0 (decyzje prawne) → Z1 konto + polisy (po fazie 1 portalu) → Z2 „Dam pracę” i „Szkolenia” → Z3 CV ze skanowaniem, synchronizacja z CRM, certyfikaty.

---

## 1. Kontekst i zmiana zakresu

**Problem.** Salon, który kupił polisę przez BeautyPolisa, ma dziś dokumenty rozproszone w e-mailach, a o odnowieniu dowiaduje się od opiekuna. Portal w koncepcji v1 kończy relację na leadzie. Zleceniodawca chce, żeby polisa otwierała stałą relację: konto z polisami oraz dostęp do dwóch działów przydatnych w codziennym prowadzeniu salonu – ogłoszeń o pracę i szkoleń.

**Co się zmienia względem dokumentów 00 i 02:**

| Miejsce | Było | Jest (po akceptacji tej sekcji) |
|---|---|---|
| 00 §5 „Poza zakresem v1” | „konta klientów” | Konta klientów wchodzą jako osobny etap Z1–Z2 **po** fazie 1 portalu (nie opóźniają startu portalu) |
| D8 / 02 F6 | Supabase Auth tylko dla personelu `/panel` | Supabase Auth także dla klientów `/strefa-klienta`; personel i klienci rozdzieleni rolami i triggerami (pkt 9) |
| 02 §4.5 „brak klienta Supabase w przeglądarce” | – | Bez zmian: strefa też nie ma klienta Supabase w przeglądarce; sesja wyłącznie w ciasteczkach `HttpOnly` |
| `snippets/robots.txt` | `Disallow: /panel/` | Dodatkowo `Disallow: /strefa-klienta/` (pkt 17) |
| 04 mapa URL | – | Nowe publiczne huby `/dam-prace` i `/szkolenia` |

## 2. Cele, nie-cele, mierniki

### 2.1 Cele

| # | Cel | Miernik | Próg [hipoteza – skalibrować po 90 dniach] |
|---|---|---|---|
| C1 | Właściciel ma polisy i dokumenty w jednym miejscu | % aktywowanych kont, w których właściciel zalogował się w ciągu 14 dni od zaproszenia | ≥ 60 % |
| C2 | Mniej próśb o duplikaty dokumentów | liczba próśb „proszę o polisę/OWU” do opiekuna (notowana w CRM) | spadek o połowę po 6 miesiącach |
| C3 | Odnowienia nie umykają | % polis odnowionych przed końcem ochrony wśród kont aktywnych | rośnie kwartał do kwartału |
| C4 | „Dam pracę” jest używane | liczba opublikowanych ofert / miesiąc, aplikacje na ofertę | ≥ 1 aplikacja na ofertę w medianie |
| C5 | „Szkolenia” budują relację | zapisy / szkolenie, obecność (`attended` / `registered`) | obecność ≥ 70 % |

### 2.2 Nie-cele (MVP)

| Nie robimy | Dlaczego |
|---|---|
| Sprzedaż i płatności online (polisy, szkolenia, ogłoszenia) | Portal jest informacyjno-leadowy (00 §1); płatności wymagają regulaminu, operatora i nowego hosta w CSP |
| Integracja na żywo z ubezpieczycielem | Brak API w audycie; polisy wprowadza broker (Założenie) |
| Konta kandydatów, baza CV, dopasowywanie kandydatów | Zwiększa zakres RODO i ryzyko uznania za pośrednictwo pracy (pkt 11.6) |
| Komunikator salon–kandydat | Kontakt po aplikacji odbywa się poza portalem (e-mail/telefon kandydata) |
| Edycja danych polisy przez klienta | Dane polisy pochodzą od brokera; klient zgłasza zmianę opiekunowi |
| Aplikacja mobilna | Strefa jest responsywna od 360 px |

## 3. Użytkownicy i role

| Rola | Kto | Jak dostaje dostęp | Co widzi i robi |
|---|---|---|---|
| **Właściciel salonu** (`owner`) | osoba wskazana przy polisie (Założenie: osoba kontaktowa z polisy) | zaproszenie od Aura po aktywacji konta | polisy i dokumenty, zgłoszenie szkody, prośba o odnowienie, zespół (zaprasza i usuwa pracowników), oferty pracy i aplikacje kandydatów, szkolenia (zapis własny i podgląd zapisów zespołu), historia zdarzeń konta |
| **Pracownik** (`employee`) | osoba z zespołu salonu | zaproszenie od właściciela | szkolenia (zapis własny), podgląd ofert pracy swojego salonu; **nie widzi** polis, dokumentów ani danych kandydatów |
| **Doradca / admin Aura** (`admin_users`: `admin`, `agent`, `viewer`) | personel Aura Consulting | istniejący `/panel` (Cloudflare Access + Supabase Auth z MFA, 02 F6) | zakłada konta, dodaje i publikuje polisy i dokumenty, aktywuje konta, moderuje oferty, prowadzi katalog szkoleń i obecność; **nie czyta** aplikacji kandydatów (pkt 11.5) |
| **Kandydat** | osoba szukająca pracy | bez konta | przegląda oferty, aplikuje formularzem, może wycofać aplikację linkiem z e-maila |
| **Gość** | każdy | – | publiczne `/dam-prace` i katalog `/szkolenia` (Założenie: katalog publiczny, zapis tylko z konta) |

Macierz uprawnień (✓ – tak, ○ – tylko własne, – – nie):

| Zasób | Właściciel | Pracownik | Personel admin/agent | Personel viewer | Kandydat / gość |
|---|---|---|---|---|---|
| Dane salonu | ✓ odczyt | ✓ odczyt | ✓ | odczyt | – |
| Polisy, dokumenty PDF | ✓ odczyt opublikowanych | – | ✓ | odczyt | – |
| Zgłoszenie szkody | ✓ | – | ✓ | odczyt | formularz publiczny `/szkoda` (02 F7) |
| Zespół, zaproszenia | ✓ (zaprasza tylko pracowników) | ○ (własne członkostwo) | ✓ | odczyt | – |
| Oferty pracy salonu | ✓ tworzy, edytuje, zamyka | odczyt | moderacja | odczyt | odczyt opublikowanych |
| Aplikacje kandydatów | ✓ | – | – | – | ○ (wycofanie własnej) |
| Szkolenia – katalog | ✓ | ✓ | ✓ prowadzi | odczyt | odczyt |
| Zapisy na szkolenia | ✓ własne + zespołu | ○ | ✓ obecność | odczyt | – |
| Dziennik zdarzeń | ✓ swojego salonu | – | ✓ | odczyt | – |

Jedna osoba może należeć do kilku salonów (np. sieć). Konto personelu Aura nie może być członkiem salonu (rozdział ról egzekwowany w `app_accept_invitation`).

## 4. Ścieżki użytkownika

### 4.1 Aktywacja po zakupie polisy

1. Polisa zostaje zawarta poza portalem (00 §1). Doradca w `/panel` → „Klienci” → „Nowe konto”: nazwa salonu, NIP, miasto, odwołanie do CRM (`crm_ref`), opcjonalnie lead źródłowy.
2. Doradca dodaje polisę: produkt, ubezpieczyciel, numer, okres, składka. Dla OC beauty wybiera grupy zabiegów, sumę, ochronę prawną i wielkość zespołu – **serwer przelicza składkę z aktywnej wersji taryfy** (ta sama czysta funkcja co kalkulator, 02 F2) i odrzuca zapis, jeśli kwota się nie zgadza. Grupa 4 i zespół od 9 osób nie mają kwoty z taryfy – doradca wpisuje składkę z wyceny indywidualnej i zaznacza `oc_individual_quote`; strefa pokazuje wtedy „Wycena indywidualna” obok kwoty z polisy.
3. Doradca wgrywa PDF-y (polisa, OWU, aneksy) – walidacja typu, rozmiaru i sygnatury pliku, hash SHA-256 – i publikuje polisę.
4. „Aktywuj Strefę Klienta” → `app_activate_client_account()` (wymaga co najmniej jednej aktywnej, opublikowanej polisy – Założenie) → zaproszenie dla właściciela ważne 7 dni. E-mail: „Strefa Klienta BeautyPolisa jest gotowa” z przyciskiem „Przyjmij zaproszenie”.

### 4.2 Pierwsze logowanie

1. Link z e-maila prowadzi na `/strefa-klienta/zaproszenie?t=…`. Strona **nie wykonuje niczego przy GET** (skanery poczty, np. ochrona linków w Microsoft 365, otwierają linki automatycznie); pokazuje nazwę salonu i przycisk „Przyjmij zaproszenie” (POST).
2. Serwer weryfikuje token (hash), tworzy użytkownika Auth, jeśli go nie ma (`auth.admin.createUser` z potwierdzonym adresem – kliknięcie w link z tego adresu jest dowodem kontroli skrzynki), zakłada sesję (`generateLink` + `verifyOtp` po stronie serwera [do weryfikacji w PoC]) i wywołuje `app_accept_invitation()`.
3. Ekran powitalny: regulamin Strefy Klienta (wersja zapisywana w `client_members.terms_version`), link do klauzuli informacyjnej, propozycja włączenia drugiego składnika (TOTP) – z opcją „Później”.
4. Pulpit.

### 4.3 Kolejne logowania

`/strefa-klienta/logowanie` → adres e-mail + Turnstile → komunikat neutralny „Jeśli adres jest przypisany do konta, wysłaliśmy kod” (brak enumeracji kont) → sześciocyfrowy kod (ważny 10 minut – Założenie) → jeśli konto ma TOTP: kod z aplikacji uwierzytelniającej → pulpit. E-mail z kodem zawiera też link „Zaloguj się jednym kliknięciem”, który prowadzi na stronę z przyciskiem POST (z tego samego powodu co w 4.2).

### 4.4 Polisy i dokumenty

Pulpit pokazuje karty polis (produkt, numer, okres ochrony, składka, status). Szczegóły polisy: parametry (dla OC: grupa taryfowa, suma gwarancyjna, ochrona prawna, wielkość zespołu), lista dokumentów, „Zgłoś szkodę”, „Odnów z doradcą”. Pobranie dokumentu: link do trasy serwerowej, która sprawdza uprawnienie sesją użytkownika (RLS), tworzy podpisany URL na 60 s z `download` i odpowiada przekierowaniem 303; zdarzenie `document_downloaded` trafia do dziennika.

### 4.5 Przypomnienia o odnowieniu

Codzienny Cron w `beautypolisa-jobs` wybiera aktywne polisy z `valid_to` za 60, 30 i 14 dni (Założenie) i wysyła e-mail do właścicieli: „Ochrona OC kończy się 31 grudnia 2026 r. Odnowienie przygotuje doradca”. Idempotencja: `client_policy_reminders (policy_id, kind)`. W strefie ta sama informacja jako baner na pulpicie. Przycisk „Odnów z doradcą” tworzy lead (`leads`, produkt polisy, kontekst konta) – bez nowej wyceny w strefie; składka po odnowieniu wynika z aktywnej taryfy programu.

### 4.6 Zgłoszenie szkody

Z karty polisy: „Zgłoś szkodę” → ten sam formularz co publiczny `/szkoda` (02 F7, **bez pola opisu** – szczegóły zdarzenia, zwykle o zdrowiu klientki salonu, zbiera opiekun telefonicznie), z prewypełnionym produktem, numerem polisy i kontaktem właściciela. Zapis do `claims_reports` z `account_id`, `policy_id`, `reported_by`. Właściciel widzi w strefie numer zgłoszenia i status (`new` → `forwarded` → `closed`). Obok instrukcja krok po kroku (treść jak `schema-howto-szkoda.json`).

### 4.7 Zapraszanie pracowników

„Zespół” → „Zaproś osobę” → adres e-mail (+ imię opcjonalnie) → `app_create_invitation()` (właściciel zaprasza tylko rolę `employee`; limit 15 aktywnych osób i 10 oczekujących zaproszeń – Założenie) → e-mail jak w 4.1. Właściciel widzi listę osób i zaproszeń, może cofnąć zaproszenie i odebrać dostęp (`app_revoke_member()`; salon zawsze ma co najmniej jednego właściciela). Odebranie dostępu anuluje przyszłe zapisy pracownika na szkolenia.

### 4.8 Publikacja oferty pracy

„Dam pracę” → „Nowa oferta”: stanowisko, zawód (lista jak w ikonach: kosmetolog, fryzjer, podolog, linergistka, stylistka paznokci, tatuażysta, recepcja, inny), rodzaj umowy, wymiar czasu, miasto i województwo, **widełki wynagrodzenia (obowiązkowe)**, opis, wymagania, oferujemy. Podgląd → „Wyślij do akceptacji” (`pending_review`) → moderacja w `/panel` (pkt 11.1) → publikacja na 30 dni (Założenie) → e-mail do właściciela. Właściciel może zamknąć ofertę w każdej chwili; zmiana treści opublikowanej oferty wraca do moderacji (guard w bazie). Na 3 dni przed wygaśnięciem – e-mail z opcją przedłużenia (= ponowna moderacja).

### 4.9 Kandydat aplikuje

`/dam-prace` → filtr (zawód, województwo, rodzaj umowy) → `/dam-prace/<slug>` → „Aplikuj”: imię i nazwisko, e-mail, telefon (opcjonalnie), krótko o doświadczeniu (do 2000 znaków), klauzula informacyjna (bez checkboxa), osobna niezaznaczona zgoda na udział w przyszłych rekrutacjach tego salonu, Turnstile → `app_create_job_application()` → strona „Dziękujemy, aplikacja AP-2026-000123 trafiła do salonu” + e-mail z potwierdzeniem i linkiem „Wycofaj aplikację”. Właściciel dostaje e-mail **bez danych kandydata** („Nowa aplikacja na ofertę Kosmetolog – zaloguj się, aby zobaczyć”). W strefie oznacza status: przejrzana, na krótkiej liście, odrzucona, zatrudniona.

### 4.10 Szkolenia

`/szkolenia` (publiczny katalog) albo `/strefa-klienta/szkolenia` → karta szkolenia (temat, termin, forma, miasto, organizator, wolne miejsca) → „Zapisz się” (dla zalogowanych; gość widzi „Zaloguj się, aby się zapisać”) → `app_training_register()` → „Zapisano” albo „Lista rezerwowa – pozycja 2” → e-mail z potwierdzeniem; link do spotkania online i adres sali widoczne dopiero po zapisie (`training_private_details`). Przypomnienie 24 h przed. Rezygnacja jednym przyciskiem zwalnia miejsce i awansuje pierwszą osobę z listy rezerwowej (e-mail „Zwolniło się miejsce”). Właściciel widzi, kto z zespołu jest zapisany.

## 5. Architektura informacji i lista ekranów

### 5.1 Mapa URL

| Ścieżka | Dostęp | Indeksowanie | Render |
|---|---|---|---|
| `/strefa-klienta` → przekierowanie na `/strefa-klienta/pulpit` albo `/logowanie` | – | noindex | dynamiczny |
| `/strefa-klienta/logowanie`, `/strefa-klienta/zaproszenie` | publiczny | noindex | dynamiczny (Turnstile, nonce) |
| `/strefa-klienta/pulpit` | członek | noindex | dynamiczny, `no-store` |
| `/strefa-klienta/polisy`, `/polisy/[id]`, `/polisy/[id]/szkoda` | właściciel | noindex | jw. |
| `/strefa-klienta/dokumenty/[id]` | właściciel | noindex | trasa serwerowa → 303 na podpisany URL |
| `/strefa-klienta/dam-prace`, `/dam-prace/nowa`, `/dam-prace/[id]`, `/dam-prace/[id]/aplikacje` | właściciel (pracownik: tylko lista ofert) | noindex | jw. |
| `/strefa-klienta/szkolenia` | członek | noindex | jw. |
| `/strefa-klienta/zespol` | właściciel | noindex | jw. |
| `/strefa-klienta/ustawienia` (TOTP, sesje, zgody, wylogowanie ze wszystkich urządzeń) | członek | noindex | jw. |
| `/dam-prace`, `/dam-prace/<slug>` | publiczny | **index** (oferta wygasła → 410) | dane z cache, rewalidacja po publikacji |
| `/dam-prace/aplikacja-wyslana`, `/dam-prace/wycofaj` | publiczny | noindex | dynamiczny |
| `/szkolenia`, `/szkolenia/<slug>` | publiczny | index (Założenie) | dane z cache |
| `/panel/klienci`, `/panel/oferty-pracy`, `/panel/szkolenia` | personel | Disallow | jak `/panel` (02 F6) |

### 5.2 Nawigacja strefy

Górny pasek (desktop) / szuflada (mobile): **Pulpit · Polisy · Dam pracę · Szkolenia · Zespół** + menu konta (nazwa salonu, przełącznik salonu przy kilku członkostwach, Ustawienia, Wyloguj). Pracownik widzi: Pulpit · Dam pracę · Szkolenia. W nagłówku strony publicznej: link „Strefa Klienta” (ikona `lux-bezpieczenstwo` – antyczny klucz) obok „Umów rozmowę”.

### 5.3 Ekrany do pokazania w makietach

| Plik makiety | Ekrany |
|---|---|
| `logowanie.html` | (1) logowanie – krok 1: e-mail + Turnstile (miejsce na widget) + informacja „Konto zakłada Aura Consulting po zawarciu polisy. Rejestracja nie jest potrzebna”; (2) krok 2: kod 6 cyfr (jedno pole `inputmode="numeric"`, `autocomplete="one-time-code"`), „Wyślij kod ponownie” z odliczaniem; (3) krok 3 (opcjonalny): kod TOTP; (4) przyjęcie zaproszenia: nazwa salonu, przycisk „Przyjmij zaproszenie”; (5) pierwsze logowanie: regulamin + propozycja TOTP z „Później”; (6) stany: neutralny komunikat po wysłaniu kodu, błędny/wygasły kod, wygasłe zaproszenie z kontaktem do doradcy |
| `panel.html` | (1) pulpit właściciela „Salon Przykładowy”: karta polisy OC (numer „BP/2026/000123 (przykład)”, ERGO Hestia, okres 1.01–31.12.2026, grupa taryfowa 2, suma 200 000 zł, ochrona prawna, składka roczna 882 zł = 790 zł + 92 zł), baner odnowienia („Ochrona kończy się 31 grudnia 2026 r.” + „Odnów z doradcą”), skróty do „Dam pracę” i „Szkolenia”; (2) szczegóły polisy z listą dokumentów (Polisa, OWU, przycisk „Pobierz PDF”) i „Zgłoś szkodę”; (3) formularz zgłoszenia szkody bez pola opisu; (4) „Zespół”: lista osób z rolami, zaproszenie oczekujące, formularz „Zaproś osobę”; (5) widok pracownika: pulpit bez polis, z informacją „Polisy salonu widzi właściciel konta”; (6) „Ustawienia”: TOTP, aktywne sesje, wyloguj wszędzie |
| `dam-prace.html` | (1) publiczna lista ofert z filtrami (zawód, województwo, rodzaj umowy), karta oferty z widełkami; (2) strona oferty z formularzem aplikacji, klauzulą, zgodą na przyszłe rekrutacje i „Zgłoś ofertę”; (3) potwierdzenie aplikacji z numerem; (4) w strefie: „Moje oferty” ze statusami (szkic, w moderacji, opublikowana do…, odrzucona z powodem, wygasła); (5) formularz „Nowa oferta”; (6) lista aplikacji z informacją o terminie usunięcia danych |
| `szkolenia.html` | (1) katalog z filtrami (forma, miesiąc), karta szkolenia (termin, forma, miasto, organizator, „Wolne miejsca: 6 z 20”); (2) strona szkolenia z programem i przyciskiem „Zapisz się” / „Zaloguj się, aby się zapisać”; (3) stan po zapisie i stan listy rezerwowej; (4) „Moje szkolenia” w strefie: nadchodzące, lista rezerwowa, rezygnacja; (5) widok właściciela: zapisy zespołu |

Dane demonstracyjne muszą być jawnie fikcyjne: „Salon Przykładowy”, „BP/2026/000123 (przykład)”, „AP-2026-000123 (przykład)”, organizator szkolenia „Organizator przykładowy”, tematy szkoleń z dopiskiem „(przykład)”. Kwoty polis wyłącznie z taryfy (01 §3.1); Tax Protect bez kwoty (taryfa nie jest w audycie). Bez nazw realnych partnerów jako organizatorów szkoleń.

## 6. Wymagania funkcjonalne

Priorytety: **P0** – MVP danego etapu, **P1** – szybko po starcie, **P2** – później (architektura ma to umożliwić).

### 6.1 Konto, logowanie, zespół (etap Z1)

| ID | Wymaganie | P | Kryteria akceptacji |
|---|---|---|---|
| K1 | Konto zakłada i aktywuje wyłącznie personel Aura | P0 | Brak publicznej rejestracji (`enable_signup = false` w Auth, `shouldCreateUser: false` przy kodzie); aktywacja bez aktywnej opublikowanej polisy kończy się błędem |
| K2 | Zaproszenie e-mailem, ważne 7 dni, jednorazowe | P0 | Token tylko w e-mailu, w bazie hash SHA-256; ponowna wysyłka unieważnia poprzedni link; GET nie zmienia stanu |
| K3 | Logowanie kodem z e-maila | P0 | Neutralny komunikat dla nieistniejącego adresu; Turnstile; limit 5 kodów / adres / godzinę i 10 / IP / godzinę (Założenie); kod ważny 10 min |
| K4 | TOTP dla właściciela (opcjonalny) | P0 | Po włączeniu RLS zwraca puste wyniki dla sesji `aal1`; kody zapasowe pokazane raz [do weryfikacji – wsparcie w Supabase] |
| K5 | Regulamin i klauzula przy pierwszym logowaniu | P0 | Wersja regulaminu i data zapisane; bez akceptacji brak dostępu do modułów |
| K6 | Zespół: zaproszenia i odbieranie dostępu | P0 | Właściciel nie może zaprosić właściciela ani odebrać dostępu ostatniemu właścicielowi; zmiany tylko przez funkcje `service_role` |
| K7 | Przełącznik salonu przy kilku członkostwach | P1 | Wybrany salon w ciasteczku (bez danych wrażliwych), każde zapytanie i tak filtruje RLS |
| K8 | Aktywne sesje i „wyloguj wszędzie” | P1 | `signOut({ scope: 'global' })` |
| K9 | Klucze dostępu (passkeys) | P2 | Gdy Supabase Auth je obsłuży [do weryfikacji]; do tego czasu TOTP |
| K10 | Rola „manager” (oferty i aplikacje bez polis) | P2 | Rozszerzenie listy ról w `client_members` i `client_account_ids()` |

### 6.2 Polisy, dokumenty, odnowienia, szkody (etap Z1)

| ID | Wymaganie | P | Kryteria akceptacji |
|---|---|---|---|
| P1 | Broker dodaje polisę w `/panel` | P0 | Dla OC składka przeliczana na serwerze z aktywnej wersji taryfy; niezgodność = odrzucenie zapisu; polisa niewidoczna dla klienta przed publikacją |
| P2 | Dokumenty PDF w prywatnym kubełku | P0 | Tylko `application/pdf`, ≤ 15 MB, sygnatura `%PDF-`, SHA-256; pobranie przez podpisany URL 60 s z `Content-Disposition: attachment` |
| P3 | Właściciel widzi tylko opublikowane polisy swojego salonu | P0 | Test RLS na dwóch salonach; pracownik – 0 wierszy |
| P4 | Przypomnienia o odnowieniu 60/30/14 dni | P0 | Najwyżej jedno przypomnienie na próg; e-mail bez załączników |
| P5 | „Odnów z doradcą” | P0 | Tworzy lead z kontekstem konta i polisy; brak nowej kwoty w strefie |
| P6 | Zgłoszenie szkody z karty polisy | P0 | Formularz bez wolnego tekstu; numer zgłoszenia i status widoczne w strefie |
| P7 | Notatki wewnętrzne brokera | P1 | Osobna tabela bez dostępu klienta |
| P8 | Jednokierunkowy przekaz polis z CRM „BEAUTY” | P2 | pkt 7.4 |
| P9 | Raty i terminy płatności | P2 | CRM ma `terminy_platnosci` (jsonb) – przeniesienie po decyzji |

### 6.3 „Dam pracę” (etap Z2)

| ID | Wymaganie | P | Kryteria akceptacji |
|---|---|---|---|
| J1 | Właściciel tworzy, wysyła do moderacji i zamyka ofertę | P0 | Niedozwolone przejścia statusów blokuje baza; edycja opublikowanej oferty wraca do moderacji |
| J2 | Moderacja przed publikacją | P0 | Lista kontrolna (pkt 11.1); odrzucenie wymaga powodu widocznego dla salonu |
| J3 | Publiczna lista i strona oferty z `JobPosting` | P0 | Walidacja w Rich Results Test; wygasła oferta → 410 i zniknięcie z sitemap w ciągu doby |
| J4 | Aplikacja bez konta | P0 | Turnstile, honeypot, rate limit, Zod; idempotencja i deduplikacja (ten sam adres na tę samą ofertę = ta sama aplikacja) |
| J5 | Obowiązkowe widełki wynagrodzenia | P0 | Formularz nie przechodzi bez `salary_min`/`salary_max` |
| J6 | Retencja i wycofanie aplikacji | P0 | Anonimizacja 90 dni po wygaśnięciu oferty albo po 12 miesiącach przy zgodzie na przyszłe rekrutacje (Założenie); link „Wycofaj aplikację” |
| J7 | „Zgłoś ofertę” | P1 | Bez danych zgłaszającego; kolejka w `/panel` |
| J8 | CV w PDF | P2 (Z3) | Tylko ze skanowaniem AV (pkt 10.3) |
| J9 | Google Indexing API dla ofert | P2 | Po weryfikacji, że ruch z Google for Jobs to uzasadnia |

### 6.4 „Szkolenia” (etap Z2)

| ID | Wymaganie | P | Kryteria akceptacji |
|---|---|---|---|
| S1 | Katalog prowadzony przez personel | P0 | Szkic → publikacja; odwołanie szkolenia powiadamia zapisanych |
| S2 | Zapis z konta z limitem miejsc i listą rezerwową | P0 | Brak nadsprzedaży przy równoczesnych zapisach (blokada wiersza szkolenia); limit na salon (domyślnie 3 – Założenie) |
| S3 | Szczegóły (link online, adres) tylko dla zapisanych | P0 | Osobna tabela z RLS |
| S4 | Przypomnienie 24 h przed | P0 | Jedno na zapis |
| S5 | Obecność oznaczana przez personel | P1 | `attended` / `no_show` |
| S6 | Zaświadczenia PDF | P2 | Generowane po `attended`; wymagają wzoru od zleceniodawcy |
| S7 | Płatne szkolenia | P2 | Poza MVP (regulamin, operator płatności, CSP) |
| S8 | Plik kalendarza `.ics` w e-mailu | P1 | Bez danych osobowych w pliku |

### 6.5 Panel personelu (`/panel`) – dodatki

„Klienci” (konta, polisy, dokumenty, aktywacja, zaproszenia, zawieszenie), „Oferty pracy” (kolejka moderacji, zgłoszenia), „Szkolenia” (katalog, zapisy, obecność). Te same zasady co w 02 F6: Cloudflare Access, MFA egzekwowane w RLS (`aal2`), akcje zapisu przez server actions.

## 7. Model danych

### 7.1 Tabele (nowy projekt portalu)

Pełny DDL z RLS: `snippets/strefa-klienta.sql`.

| Tabela | Klucz i najważniejsze kolumny | Relacje | PII |
|---|---|---|---|
| `client_accounts` | `id`, `display_name`, `nip`, `status` (pending/active/suspended/closed), `crm_ref`, `activated_at/by` | → `leads` (lead źródłowy) | dane firmy |
| `client_members` | PK (`account_id`, `user_id`), `role` (owner/employee), `status`, `terms_version` | → `client_accounts`, `auth.users` | pośrednio |
| `client_invitations` | `id`, `email_normalized`, `role`, `token_hash`, `expires_at`, `invited_by_kind` | → `client_accounts` | e-mail (czyszczony po 30 dniach) |
| `client_policies` | `id`, `product` (`lead_product`), `insurer`, `policy_number`, `valid_from/to`, `premium_amount`, `oc_*` (parametry taryfy, `oc_individual_quote` dla gr. 4 i zespołu 9+), `pricing_version_id`, `published_at`, `crm_ref` | → `client_accounts`, `pricing_versions` | nie |
| `client_policy_notes` | notatki brokera | → `client_policies` | możliwe – tylko personel |
| `client_policy_documents` | `storage_path`, `kind`, `size_bytes`, `sha256`, `published_at` | → `client_policies`, `client_accounts` | treść PDF |
| `client_policy_reminders` | PK (`policy_id`, `kind`) | → `client_policies`, `outbox_emails` | nie |
| `job_offers` | `slug`, `status`, treść, widełki, `employer_name` (migawka), `published_at`, `expires_at`, `moderation_note` | → `client_accounts` | nie (bez danych kontaktowych salonu) |
| `job_applications` | `reference`, `idempotency_key`, `status`, dane kandydata, `privacy_notice_version`, zgoda na przyszłe rekrutacje, `retention_until` | → `job_offers`, `client_accounts` | **tak** (FORCE RLS) |
| `job_offer_reports` | `reason`, `handled_at` | → `job_offers` | nie |
| `trainings` | `slug`, `status`, termin, `format`, `capacity`, `seats_registered`, `per_account_limit`, `audience` | – | nie |
| `training_private_details` | `online_join_url`, `venue_address` | → `trainings` | nie |
| `training_registrations` | `status` (registered/waitlisted/cancelled/attended/no_show) | → `trainings`, `client_accounts`, `auth.users` | pośrednio |
| `client_audit_log` | `actor`, `action`, `entity`, `payload` (bez PII, ≤ 2 KB) | → `client_accounts` | nie |
| zmiany istniejących | `claims_reports` + `account_id`, `policy_id`, `reported_by`; `outbox_emails` + `account_id` | | |

```text
auth.users ─┬─< client_members >── client_accounts ──< client_policies ──< client_policy_documents
            │                         │   │                   └──< client_policy_reminders
            │                         │   ├──< client_invitations
            │                         │   ├──< job_offers ──< job_applications
            │                         │   │        └──< job_offer_reports
            │                         │   └──< training_registrations >── trainings ── training_private_details
            └─< admin_users (personel; rozłączne z client_members)
client_accounts ──< client_audit_log      client_policies >── pricing_versions (taryfa OC)
```

### 7.2 Co jest w projekcie „BEAUTY” (stan z 11.11.2026, tylko struktura)

| Moduł | Tabele i liczba wierszy | Cechy istotne dla decyzji |
|---|---|---|
| Katalog salonów (multi-tenant) | `salons` (1), `salon_memberships` (1), `services`, `staff`, `appointments`, `plans`, `subscriptions`… | Inny produkt (katalog i rezerwacje na `app.`); `salon_memberships.role` + funkcja `can_manage_salon()` – SECURITY DEFINER **wykonywalna przez `anon`**; polityka SELECT na `salon_memberships` dla roli `public` |
| CRM | `crm_companies` (1468), `crm_policies` (37), `crm_history`, `crm_reminders`, `crm_audit_log` | System pracy brokera: `crm_policies` ma `company_id integer`, `rodzaj`, `nr_polisy`, `ubezpieczyciel`, `suma_ubezpieczenia text`, `skladka`, `data_od/do`, `przypomnienie`, `ochrona_prawna`, `terminy_platnosci jsonb`; dostęp przez `is_crm_user()`/`is_crm_admin()` (bez EXECUTE dla `anon`) |
| Ogłoszenia o pracę | `job_listings` (1), `job_applications` (0) | Ogłoszenie należy do użytkownika (`owner_id`), nie do salonu; pola płatności (`price_pln`, `payment_status`, `paid_at`); aplikacja wymaga konta (`applicant_user_id`, polityka INSERT tylko `authenticated`); **`anon` ma SELECT na kolumnach `phone`, `email`, `owner_id` aktywnych ogłoszeń** |
| Szkolenia | `trainings` (6), `training_enrollments` (0) | Model sprzedażowy (`price_pln`, `payment_method`, `payment_status`, `amount_pln`), licznik `seats_taken`; publiczny odczyt `status='active' and source='katalog'`; administracja przez `is_katalog_admin()` (SECURITY DEFINER wykonywalna przez `anon`) |
| Storage | kubełki `dokumenty` (**publiczny**, 10 MB, ograniczone typy), `salon-media` (publiczny), `seo-assets` (publiczny), `email-assets` | Żaden nie nadaje się na polisy klientów |

### 7.3 Warianty i rekomendacja

| Wariant | Opis | Za | Przeciw |
|---|---|---|---|
| A. Reuse – strefa na „BEAUTY” | Strefa korzysta wprost z `salons`, `job_listings`, `trainings`, `crm_policies` | Brak migracji | Sprzeczne z D2; publiczny portal na bazie z CRM (1468 firm) i danymi wielu modułów – ten sam problem, który audyt wskazał w „aurabroker”; dziedziczy błędy Security Advisor (widoki SECURITY DEFINER, funkcje DEFINER dla `anon`, `tax_wnioski` bez polityk); model ofert i szkoleń niezgodny z wymaganiami |
| **B. Nowe tabele w projekcie portalu + migracja danych modułów + integracja z CRM** | Moduły „Dam pracę” i „Szkolenia” powstają od nowa w projekcie portalu; 6 szkoleń i 1 ogłoszenie przenosimy jednorazowo (po przeglądzie treści przez zleceniodawcę); CRM zostaje systemem źródłowym polis, portal trzyma projekcję polis klientów | Zgodne z D2; izolacja skutków incydentu; model dopasowany do wymagań; koszt migracji pomijalny przy obecnych wolumenach | Dwa miejsca z danymi polis (CRM i portal) – wymaga jasnej reguły „źródłem jest CRM” i późniejszej synchronizacji |
| C. Strefa jako schemat w „BEAUTY” | Osobny schemat `strefa` w „BEAUTY” | Blisko CRM | Ten sam projekt, te same klucze, `auth.users` i ustawienia Auth wspólne z katalogiem salonów i CRM; odrzucone już w D2 |

**Rekomendacja: wariant B.** Uzasadnienie w kolejności priorytetów klienta: (1) bezpieczeństwo – strefa ma dane osobowe kandydatów i dokumenty polis, więc musi mieć mały, sprawdzalny zestaw uprawnień, a „BEAUTY” ma dziś 17 funkcji SECURITY DEFINER dostępnych dla `anon` (01 §5.2); (2) stabilność – zmiany w katalogu salonów lub CRM nie mogą psuć strefy; (3) koszty migracji są znikome (1 ogłoszenie, 0 aplikacji, 6 szkoleń, 0 zapisów).

### 7.4 Ścieżka migracji i integracji

| Krok | Etap | Co | Jak |
|---|---|---|---|
| M1 | Z1 | Konta i polisy wprowadzane ręcznie w `/panel` | `crm_ref` w `client_accounts` i `client_policies` przechowuje identyfikatory z CRM, żeby później połączyć rekordy |
| M2 | Z1 | Import „startowy” klientów z aktywnymi polisami | Jednorazowy eksport z CRM wykonany przez personel (CSV z polami: firma, NIP, numer polisy, okres, produkt, składka, e-mail kontaktowy), import skryptem z walidacją taryfy OC – **bez** dostępu portalu do bazy „BEAUTY” |
| M3 | Z2 | Szkolenia i ogłoszenie z „BEAUTY” | Zleceniodawca przegląda 6 szkoleń i 1 ogłoszenie; przenosimy tylko treść katalogową (bez danych płatności), ręcznie lub skryptem jednorazowym |
| M4 | Z2 | Wygaszenie starych modułów | Po decyzji zleceniodawcy (pytanie Q9): `job_listings`/`trainings` w „BEAUTY” tylko do odczytu albo usunięte; do tego czasu odebrać `anon` SELECT na `job_listings.phone/email/owner_id` i EXECUTE na funkcjach DEFINER (szybka wygrana niezależna od strefy) |
| M5 | Z3 | Jednokierunkowy przekaz CRM → portal | Webhook bazy w „BEAUTY” (trigger na `crm_policies` → `pg_net`/Database Webhook) na endpoint `POST /api/internal/crm/policies` w portalu, podpisany HMAC (sekret w obu projektach), z idempotencją po `crm_ref` + `updated_at`; portal **nie przechowuje kluczy do „BEAUTY”**, a „BEAUTY” nie dostaje kluczy portalu – tylko sekret HMAC; mapowanie pól i walidacja taryfy na serwerze portalu; konflikt = wpis do kolejki przeglądu w `/panel` |
| M6 | później | Powiązanie z katalogiem salonów (`app.`) | Opcjonalne pole `catalog_salon_ref`, link „Profil w katalogu” – bez wspólnej bazy |

## 8. Uwierzytelnianie

| Element | Rozwiązanie |
|---|---|
| Dostawca | Supabase Auth w nowym projekcie portalu (ten sam co dla `/panel`) |
| Rejestracja | **wyłączona** (`enable_signup = false`); użytkownicy powstają tylko przy przyjęciu zaproszenia, na serwerze, kluczem `sb_secret_…` |
| Metoda | kod jednorazowy z e-maila (`signInWithOtp`, `shouldCreateUser: false`) + link w tym samym e-mailu prowadzący na stronę z przyciskiem POST (odporność na automatyczne otwieranie linków przez skanery poczty) |
| Drugi składnik | TOTP opcjonalny dla właściciela (MVP), rekomendowany w ustawieniach; egzekwowany w bazie: użytkownik ze zweryfikowanym czynnikiem i sesją `aal1` dostaje pusty `client_account_ids()`; dla personelu `aal2` obowiązkowe jak w 02. Klucze dostępu (passkeys) – gdy Supabase Auth je obsłuży [do weryfikacji] |
| Sesja | `@supabase/ssr` wyłącznie po stronie serwera; ciasteczka `HttpOnly; Secure; SameSite=Lax; Path=/` (opcja `cookieOptions` klienta serwerowego – domyślnie biblioteka nie ustawia `HttpOnly`, bo zakłada klienta w przeglądarce, którego tu nie ma) |
| Czas życia | token dostępu 1 h, rotacja refresh tokenów z wykrywaniem ponownego użycia, limit sesji 30 dni i wylogowanie po 7 dniach bezczynności (ustawienia Auth w planie Pro) [Założenie; do weryfikacji dostępności opcji] |
| Weryfikacja na serwerze | decyzje autoryzacyjne tylko po `auth.getUser()` albo `auth.getClaims()` (weryfikacja podpisu JWT asymetrycznymi kluczami – bez zapytania sieciowego przy każdym żądaniu [do weryfikacji w PoC]); **nigdy** `getSession()` (nie weryfikuje tokenu); **nigdy** `user_metadata` jako źródło uprawnień (użytkownik może je zmienić) |
| E-maile Auth | własny SMTP przez Resend z domeny `send.` (wbudowany SMTP Supabase ma niskie limity); szablony po polsku, w stylu marki, bez obrazów zewnętrznych |
| Ochrona formularzy logowania | Turnstile (Supabase Auth obsługuje CAPTCHA natywnie [do weryfikacji wariantu Turnstile]), rate limit Cloudflare na `/strefa-klienta/logowanie`, limity Auth (`rate_limit_email_sent`, `rate_limit_otp`), neutralne komunikaty |
| Wylogowanie | `POST /strefa-klienta/wyloguj` (nie GET), opcja „wyloguj wszędzie” |
| Konta personelu | rozłączne z kontami klientów (pkt 9.3); `/panel` dodatkowo za Cloudflare Access |

## 9. Autoryzacja

### 9.1 Członkostwo i RLS per salon

- Źródłem uprawnień jest `client_members` (rola, status) oraz status konta `client_accounts.status = 'active'`.
- Jedna funkcja pomocnicza `client_account_ids(variadic roles)` zwraca identyfikatory salonów wywołującego dla wskazanych ról. Polityki mają postać `account_id in (select public.client_account_ids('owner'))` – podzapytanie jest wyliczane raz na zapytanie (initPlan), więc nie ma kosztu per wiersz.
- Kolumny, których klient nie powinien widzieć, są wyłączone **uprawnieniami kolumnowymi** (np. `job_offers.moderation_note`, `client_invitations.token_hash`), a nie widokami. Notatki brokera są w osobnej tabeli, bo uprawnienia kolumnowe dotyczą całej roli `authenticated`, czyli i klientów, i personelu.
- Serwer używa w strefie **klienta Supabase z sesją użytkownika** (klucz publishable tylko po stronie serwera + token użytkownika), więc każdy odczyt przechodzi przez RLS. Klucz `sb_secret_…` jest używany wyłącznie do: funkcji `app_*`, wgrywania plików, wysyłki outboxu i zadań Cron.

### 9.2 Zapisy

| Rodzaj zapisu | Droga | Dlaczego |
|---|---|---|
| Oferty pracy właściciela (szkic, edycja, wysłanie do moderacji, zamknięcie) | RLS + guard `job_offers_owner_guard` (dozwolone przejścia statusów, migawka nazwy salonu, ponowna moderacja po edycji) | Prosty zapis w obrębie własnego salonu |
| Status aplikacji kandydata | RLS (`update (status)` + `with check` na dozwolone wartości) | jw. |
| Polisy, konta, szkolenia, obecność (personel) | RLS z `app_is_staff('admin','agent')` + trigger audytu | Zgodnie z wzorcem panelu (02 §3.2) |
| Zaproszenia, aktywacja, przyjęcie zaproszenia, odebranie dostępu, regulamin | funkcje `app_*` tylko dla `service_role`; tabele członkostw z triggerem `backend_only_guard` | Niezmienniki (ostatni właściciel, limity zespołu, rozdział personel/klient, zgodność adresu e-mail) |
| Aplikacja kandydata | `app_create_job_application()` (`service_role`) | Kandydat nie ma sesji; idempotencja, deduplikacja i limit dzienny w jednej transakcji |
| Zapis i rezygnacja ze szkolenia | `app_training_register()` / `app_training_cancel()` (`service_role`) | Limit miejsc liczony ponad granicą salonów (RLS ukrywa cudze zapisy) – blokada wiersza szkolenia `FOR UPDATE` |
| Moderacja ofert | `app_moderate_job_offer()` (`service_role`), serwer sprawdza też `app_is_staff` w sesji `aal2` | Kolumny moderacji bez grantu dla `authenticated` |

Funkcje `app_*` przyjmują `p_actor` – identyfikator z **zweryfikowanego** tokenu – i same sprawdzają uprawnienia aktora (obrona w głąb, choć wywołuje je tylko serwer).

### 9.3 Personel Aura

Polityki personelu używają istniejącego `app_is_staff()` (MFA `aal2`). Personel czyta konta, polisy, dokumenty, oferty i szkolenia; **nie ma polityki na `job_applications`** – dane kandydatów widzi tylko salon (minimalizacja; obsługa nadużyć kluczem serwisowym z wpisem w dzienniku). Konto z wpisem w `admin_users` nie może przyjąć zaproszenia do salonu, więc nikt nie łączy ról personelu i klienta. Podgląd „oczami klienta” (impersonacja) – świadomie poza zakresem.

### 9.4 Pułapki SECURITY DEFINER z audytu i jak ich unikamy

| Pułapka (stan w „BEAUTY”/„aurabroker”) | W strefie |
|---|---|
| Funkcje DEFINER wykonywalne przez `anon` (`can_manage_salon`, `is_katalog_admin`, `is_platform_admin`, `katalog_set_admin`, `katalog_admin_users`) | Jedyna funkcja DEFINER wywoływalna przez API to `client_account_ids()` – tylko `authenticated`, bez parametru użytkownika (odpowiada wyłącznie o wywołującym), zwraca tylko identyfikatory; drugi DEFINER to funkcja wyzwalacza audytu (nie da się jej wywołać przez RPC) |
| Mutowalny `search_path` (15 funkcji w „aurabroker”) | Każda funkcja ma `set search_path = ''` i pełne nazwy obiektów |
| Widoki SECURITY DEFINER (3 × ERROR) | Brak widoków; uprawnienia kolumnowe |
| Polityki dla roli `public` (np. `salon_memberships`) | Polityki zawsze z jawną rolą (`to anon` / `to authenticated`), polityki `anon` nie wywołują funkcji personelu |
| Domyślny `EXECUTE` dla `PUBLIC` | Jawne `REVOKE … FROM public, anon, authenticated` dla każdej funkcji. **Uwaga do `schema.sql`:** `ALTER DEFAULT PRIVILEGES … IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM public` nie odbiera globalnego domyślnego prawa `PUBLIC` (domyślne uprawnienia per schemat mogą tylko dodawać); w teście lokalnym `admin_users_guard` z `rls-policies.sql` pozostał wykonywalny przez `anon`. Poprawka: dodatkowe `alter default privileges for role postgres revoke execute on functions from public;` **bez** `IN SCHEMA` (do naniesienia w 02/`schema.sql`) |
| Uprawnienia oparte o metadane użytkownika | Wyłącznie tabele `client_members`/`admin_users` |

### 9.5 Kolejność w `rls-policies.sql`

W obecnym `rls-policies.sql` polityki leadów używają `app_is_staff()` przed jej definicją, więc plik uruchomiony od góry kończy się błędem. `strefa-klienta.sql` zakłada, że funkcja już istnieje; w migracjach `app_is_staff` musi trafić przed polityki (do naniesienia w 02).

### 9.6 Testy uprawnień w CI

Rozszerzenie `packages/db/tests/privileges.test.sql` (fixture: dwa salony, właściciel A, pracownik A, właściciel B, personel, anon):

1. Żadna funkcja w `public` nie ma `EXECUTE` dla `anon` ani `PUBLIC`; dla `authenticated` – tylko `app_is_staff` i `client_account_ids`.
2. Każda tabela z RLS ma politykę albo jest na liście `service_role_only` (`client_policy_reminders`).
3. Właściciel B nie widzi żadnego wiersza salonu A w żadnej tabeli ani obiektu w kubełku `client-documents`.
4. Pracownik widzi 0 polis, 0 dokumentów, 0 aplikacji, 0 obiektów Storage; widzi oferty swojego salonu.
5. `anon`: tylko opublikowane, nieprzeterminowane oferty i tylko kolumny publiczne (`select account_id` → `permission denied`); brak dostępu do polis.
6. Właściciel ze zweryfikowanym TOTP i sesją `aal1` – 0 wierszy; z `aal2` – komplet.
7. Właściciel: `update published_at` → `permission denied`; przejście `pending_review → published` → wyjątek; wstawienie oferty do cudzego salonu → naruszenie RLS.
8. Funkcje: ponowne użycie zaproszenia, zaproszenie właściciela przez właściciela, przyjęcie zaproszenia z innego adresu – wyjątki; zapis na szkolenie z 1 miejscem przez dwie osoby → `registered` + `waitlisted`; rezygnacja awansuje osobę z listy rezerwowej.
9. `client_audit_log`: UPDATE → wyjątek.

Scenariusze 1 i 3–9 przeszły 11.11.2026 na lokalnym Postgresie 16 z zaślepkami schematów `auth` i `storage` (`schema.sql` → `rls-policies.sql` → `strefa-klienta.sql`).

## 10. Pliki (Supabase Storage)

### 10.1 Dokumenty polis

- Kubełek **`client-documents`**: prywatny, limit 15 MB, tylko `application/pdf`; ścieżka `{account_id}/{policy_id}/{uuid}.pdf` (nazwa pliku z serwera, nigdy od użytkownika); zgodność ścieżki z salonem wymusza `check` w `client_policy_documents`.
- Wgrywa wyłącznie serwer (`service_role`) po: sprawdzeniu sesji personelu (`aal2`), rozmiaru, sygnatury `%PDF-`, typu, policzeniu SHA-256. Brak polityk INSERT/UPDATE/DELETE dla `authenticated`.
- Odczyt: polityka na `storage.objects` dopuszcza właściciela tylko dla opublikowanych dokumentów jego salonu – dlatego podpisany URL generujemy **sesją użytkownika** (RLS działa także przy podpisywaniu), bez klucza serwisowego.
- Podpisany URL ważny 60 s, parametr `download` (wymusza `Content-Disposition: attachment`), `Referrer-Policy` bez zmian (02 §4.2).
- Istniejący publiczny kubełek `dokumenty` w „BEAUTY” – wyłącznie do publicznych OWU, nigdy do polis klientów.
- Usuwanie: dokumenty polis są częścią dokumentacji dystrybucji; okres przechowywania do ustalenia z IOD (pytanie Q6).

### 10.2 Skanowanie antywirusowe

Dokumenty polis pochodzą od personelu (zaufane źródło: ubezpieczyciel, broker) – w MVP wystarcza walidacja typu i sygnatury oraz hash. Pliki od osób z zewnątrz (CV) – tylko ze skanowaniem.

### 10.3 CV kandydatów (etap Z3)

Kubełek `job-cv`: prywatny, ≤ 5 MB, tylko PDF; upload do `quarantine/{account_id}/…`, skan, przeniesienie do `clean/{account_id}/…`; właściciel podpisuje URL tylko dla `clean/` i `cv_scan_status = 'clean'`; anonimizacja usuwa obiekt. Skaner: ani Workers, ani Supabase Storage nie mają wbudowanego antywirusa – opcje: kontener z ClamAV w Cloudflare Containers [do weryfikacji dostępności] albo zewnętrzna usługa skanowania w UE (nowy podmiot przetwarzający, DPA, nowy host tylko po stronie serwera). Decyzja przed Z3 (pytanie Q12). Do tego czasu formularz ma tylko pole „Krótko o doświadczeniu”.

## 11. „Dam pracę” – specyfika

### 11.1 Moderacja

- Każda oferta przechodzi moderację przed publikacją (wolumen niski; płacący klienci) – Założenie. Po 3 zaakceptowanych ofertach salon może dostać publikację natychmiastową z kontrolą następczą (P2).
- Lista kontrolna moderatora (w `/panel`): tytuł neutralny płciowo albo z oboma formami („Kosmetolog / kosmetolożka”); brak wymagań dyskryminujących (wiek, płeć, wygląd, stan cywilny – art. 18³ᵃ KP); widełki realne; opis dotyczy pracy w salonie; brak danych osobowych osób trzecich; brak linków i numerów telefonów w treści (aplikacja wyłącznie formularzem); zgodność stanowiska z deklarowanym zawodem.
- Odrzucenie zawsze z powodem dla salonu; usunięcie (`removed`) po zgłoszeniu nadużycia.

### 11.2 Spam i nadużycia

| Wektor | Kontrola |
|---|---|
| Zalew aplikacji botami | Turnstile, honeypot, rate limit Cloudflare + binding w Workerze, idempotencja, deduplikacja po adresie, limit 200 aplikacji / oferta / dobę (Założenie) |
| Fałszywe oferty (wyłudzenia) | Publikować mogą tylko salony z aktywną polisą; moderacja; „Zgłoś ofertę”; brak danych kontaktowych w treści |
| Wstrzykiwanie treści | Tekst zwykły (bez HTML/Markdown), escape przy renderowaniu, limity długości, CSP |
| Enumeracja ofert w szkicu | Slug losowy dla szkiców; publiczny odczyt tylko `published` |
| Scraping danych kandydatów | Dane kandydatów nigdy na stronach publicznych ani w e-mailach |

### 11.3 Google for Jobs (`JobPosting`)

- JSON-LD `JobPosting` **tylko na stronie pojedynczej oferty**, nie na liście. Pola: `title`, `description` (HTML z akapitów treści), `datePosted` = `published_at`, `validThrough` = `expires_at`, `employmentType` (mapowanie: umowa o pracę → `FULL_TIME`/`PART_TIME` wg wymiaru, zlecenie i B2B → `CONTRACTOR`, inna → `OTHER`), `hiringOrganization` (`name` = `employer_name`; bez `sameAs`/`logo`, jeśli salon ich nie podał), `jobLocation` (`addressLocality`, `addressRegion`, `postalCode`, `addressCountry: PL`), `baseSalary` (`MonetaryAmount`, `currency: PLN`, `QuantitativeValue` z `minValue`, `maxValue`, `unitText: MONTH|HOUR`), `directApply: true` (aplikacja na stronie), `identifier` (`reference` oferty).
- Wygasła lub zamknięta oferta: odpowiedź **410**, usunięcie z `sitemap-oferty.xml` (z `lastmod`) przy najbliższej rewalidacji. Google Indexing API – P2.
- Lista `/dam-prace` ma treść wstępną (jak publikować, jak aplikować) i `ItemList`/`BreadcrumbList` bez `JobPosting`. Kombinacje filtrów (`?zawod=`, `?wojewodztwo=`) – `noindex, follow` i canonical do `/dam-prace` (Założenie: bez osobnych stron miast w MVP).

### 11.4 Wygasanie

Ważność 30 dni od publikacji (Założenie; twardy limit w bazie: 60 dni). Cron dzienny: `app_expire_job_offers()`, przypomnienie 3 dni przed (`job_offer_expiring`), rewalidacja cache.

### 11.5 RODO dla danych kandydatów

| Kwestia | Proponowane rozstrzygnięcie [do weryfikacji przez prawnika i IOD] |
|---|---|
| Role | **Salon = administrator** danych w swojej rekrutacji (decyduje o celu i sposobie); **Aura = podmiot przetwarzający** (hosting formularza i aplikacji) na podstawie umowy powierzenia (art. 28 RODO) zawartej w regulaminie „Dam pracę” akceptowanym przez właściciela; Aura jest odrębnym administratorem tylko w zakresie bezpieczeństwa serwisu (logi bez PII, zgłoszenia nadużyć) |
| Podstawa | art. 6 ust. 1 lit. b RODO / art. 22¹ KP (działania przed zawarciem umowy) dla danych z formularza; zgoda (art. 6 ust. 1 lit. a) na przyszłe rekrutacje – osobne, niezaznaczone pole z wersją treści |
| Zakres | imię i nazwisko, e-mail, telefon (opcjonalnie), opis doświadczenia; bez daty urodzenia, zdjęcia, PESEL, oczekiwań finansowych i pytań o dotychczasowe wynagrodzenie |
| Obowiązek informacyjny | klauzula przy formularzu wskazuje salon jako administratora (nazwa z oferty), Aura jako podmiot przetwarzający, okres przechowywania i prawa; wersja klauzuli w `privacy_notice_version` |
| Retencja | anonimizacja 90 dni po wygaśnięciu/zamknięciu oferty albo 12 miesięcy od aplikacji przy zgodzie na przyszłe rekrutacje (Założenie); salon może odrzucić i zostawić dane do końca retencji, ale nie może jej wydłużyć |
| Usunięcie i wycofanie | link „Wycofaj aplikację” (HMAC z identyfikatora, bez kolumny w bazie) – natychmiastowa anonimizacja przy najbliższym przebiegu Cron; wnioski z art. 15–17 obsługuje salon, Aura pomaga jako procesor |
| E-maile | do salonu bez danych kandydata; do kandydata tylko potwierdzenie z numerem |
| Personel Aura | brak dostępu do aplikacji w RLS |

### 11.6 Pytanie prawne: czy to „pośrednictwo pracy” (KRAZ)?

Prowadzenie agencji zatrudnienia, w tym pośrednictwa pracy, wymaga wpisu do rejestru podmiotów prowadzących agencje zatrudnienia (KRAZ) [podstawa prawna według stanu na 2026 r. – do weryfikacji przez prawnika: ustawa o rynku pracy i służbach zatrudnienia, która zastąpiła ustawę z 2004 r.]. Ryzyko kwalifikacji rośnie, gdy operator serwisu dobiera kandydatów do ofert, rekomenduje ich, prowadzi bazę kandydatów albo pobiera opłaty od kandydatów. Projekt świadomie ogranicza „Dam pracę” do roli tablicy ogłoszeń: salon sam publikuje i sam wybiera kandydatów, Aura nie przegląda aplikacji, nie ma bazy CV ani kont kandydatów, kandydat nic nie płaci, a moderacja dotyczy wyłącznie treści ogłoszenia. **Prawnik musi potwierdzić przed startem Z2**, czy taki model nie wymaga wpisu do KRAZ i czy bezpłatność dla salonów (benefit do polisy) cokolwiek zmienia. Do rozstrzygnięcia także: obowiązki z nowelizacji Kodeksu pracy o jawności wynagrodzeń (informacja o wynagrodzeniu lub jego przedziale dla kandydata, neutralne nazwy stanowisk, zakaz pytania o dotychczasowe wynagrodzenie) [do weryfikacji daty wejścia w życie i zakresu] – projekt już teraz wymaga widełek i nie pyta o wynagrodzenie.

## 12. „Szkolenia” – specyfika

- **Katalog:** personel tworzy szkolenia w `/panel` (szkic → publikacja). Publiczna strona pokazuje termin, formę, miasto, organizatora, wolne miejsca (`capacity − seats_registered`). Nazwa partnera jako organizatora – tylko za jego zgodą (`organizer_label`); nie zakładamy żadnego konkretnego partnera.
- **Zapis:** tylko członkowie aktywnych kont; `audience = 'owners'` dla szkoleń wyłącznie dla właścicieli; limit na salon (domyślnie 3); lista rezerwowa w kolejności zgłoszeń; zapis i rezygnacja są idempotentne.
- **Pojemność:** licznik `seats_registered` aktualizowany wyłącznie przez funkcje z blokadą `FOR UPDATE` wiersza szkolenia – brak nadsprzedaży przy równoczesnych zapisach; `check (seats_registered <= capacity)` jako ostatnia linia obrony.
- **Przypomnienia:** potwierdzenie zapisu, awans z listy rezerwowej, przypomnienie 24 h przed, odwołanie szkolenia (wszyscy zapisani). Plik `.ics` (P1).
- **Zamknięcie zapisów:** `registration_closes_at` albo start szkolenia.
- **Obecność i zaświadczenia:** obecność oznacza personel (P1); zaświadczenia PDF po `attended` (P2) – wymagają wzoru i decyzji, kto je wystawia.
- **Płatności:** poza MVP (`price_kind`: `bezplatne` / `partner`). Płatne szkolenia wymagają regulaminu, operatora płatności i nowego hosta w CSP.
- **Dane uczestników dla organizatora zewnętrznego:** przekazanie listy uczestników partnerowi to udostępnienie danych – wymaga podstawy i informacji w klauzuli (pytanie Q11).

## 13. Powiadomienia (Resend, outbox)

Wszystkie e-maile przez istniejący wzorzec `outbox_emails` (02 §3.4): wiersz w tej samej transakcji co zdarzenie, pierwsza próba natychmiast, ponowienia z Cron. Nowa kolumna `account_id`. Zasady: **bez załączników**, bez danych kandydatów w e-mailach do salonu, bez kwot składek w treści (tylko link do strefy), token zaproszenia nigdy w `payload` (rotacja przy ponowieniu), nagłówki `List-Unsubscribe` tylko dla wiadomości nietransakcyjnych.

| Szablon | Odbiorca | Wyzwalacz |
|---|---|---|
| `client_invite` | zapraszany | aktywacja konta, zaproszenie do zespołu |
| `client_policy_published` | właściciele | publikacja nowej polisy/dokumentu |
| `renewal_60`, `renewal_30`, `renewal_14` | właściciele | Cron dzienny |
| `claim_received` | właściciel + zespół Aura | zgłoszenie szkody |
| `job_offer_submitted_team` | zespół Aura | oferta w moderacji |
| `job_offer_published`, `job_offer_rejected`, `job_offer_expiring` | właściciele | moderacja, Cron |
| `job_application_owner` | właściciele | nowa aplikacja (bez danych kandydata) |
| `job_application_candidate` | kandydat | potwierdzenie z linkiem wycofania |
| `training_registered`, `training_waitlisted`, `training_promoted`, `training_reminder_24h`, `training_cancelled` | uczestnik | zapis, lista rezerwowa, Cron, odwołanie |

E-maile Supabase Auth (kod logowania) idą przez SMTP Resend, poza outboxem.

## 14. Dziennik audytu

`client_audit_log`: append-only (trigger blokuje UPDATE, DELETE tylko po 24 miesiącach – Założenie), `actor` w formacie `system` / `candidate` / `user:<uuid>` / `staff:<uuid>`, `payload` bez PII (≤ 2 KB), `request_id` do korelacji z logami Workera. Zapisują: funkcje `app_*`, trigger audytu zmian personelu, trasa pobierania dokumentów (`document_downloaded`). Odczyt: właściciel – zdarzenia swojego salonu (ekran „Historia konta”, P1), personel – wszystko. Logi Workera bez PII jak w 02 §4.8.

## 15. Zagrożenia (STRIDE) i kontrole

| Kategoria | Zagrożenie w strefie | Kontrole |
|---|---|---|
| **S** – podszycie | Przejęcie skrzynki e-mail właściciela; phishing podszywający się pod zaproszenie; zużycie linku przez skaner poczty; zgadywanie kodu | Kod 6 cyfr z krótką ważnością i limitami; opcjonalny TOTP egzekwowany w RLS; linki działają dopiero po kliknięciu przycisku (POST); DMARC/DKIM/SPF dla `send.`; e-maile bez próśb o dane, z nazwą salonu; zaproszenie powiązane z adresem e-mail |
| **T** – manipulacja | Podmiana `account_id` w formularzu; zmiana statusu oferty z pominięciem moderacji; zawyżenie/zaniżenie składki przez personel; podmiana pliku PDF | RLS `with check`; uprawnienia kolumnowe; guard przejść statusów; przeliczenie składki OC z taryfy na serwerze; hash SHA-256 dokumentów, brak UPDATE na plikach |
| **R** – wypieranie się | „Nie publikowałem tej oferty”, „Nie dostałem dokumentu”, spór o zgodę kandydata | `client_audit_log` (kto, co, kiedy), `document_downloaded`, wersje regulaminu i klauzul, wersja treści zgody na przyszłe rekrutacje |
| **I** – ujawnienie | IDOR na dokumentach/aplikacjach; wyciek między salonami; buforowanie prywatnych stron; indeksowanie strefy; wyciek podpisanego URL; enumeracja kont; dane kandydatów w e-mailach; publiczne kolumny kontaktowe (jak w „BEAUTY”) | RLS na każdej tabeli i na `storage.objects`; `Cache-Control: private, no-store` + `X-Robots-Tag: noindex, nofollow`; robots `Disallow`; URL 60 s z `download`; neutralne odpowiedzi logowania; e-maile bez PII; publiczne kolumny ofert wymienione jawnie |
| **D** – odmowa usługi | Zalew aplikacji; wyczerpanie miejsc na szkoleniu przez jeden salon; bombardowanie kodami | Turnstile, rate limit, limity dzienne; limit miejsc na salon; limity Auth na adres i IP |
| **E** – eskalacja | Pracownik → właściciel; klient → personel; funkcje DEFINER dla `anon`; `user_metadata` jako źródło ról; sesja `aal1` po włączonym TOTP | Członkostwa tylko przez funkcje `service_role` + guard; rozdział `admin_users`/`client_members`; zero DEFINER dla `anon` (test CI); role tylko z tabel; warunek `aal2` w `client_account_ids()` |

## 16. Wydajność i cache

| Zasób | Strategia |
|---|---|
| Strony `/strefa-klienta/*` | renderowane per żądanie, `Cache-Control: private, no-store`, bez cache danych Next.js (dane per użytkownik); zapytania po indeksach `account_id`; budżet JS jak dla landingu (≤ 120 KB gzip), formularze jako server actions działające bez JS |
| `/dam-prace`, `/szkolenia` (lista i szczegóły) | HTML per żądanie (nonce CSP, 02 §3.3), dane w cache Next.js z rewalidacją 300 s i rewalidacją na żądanie (`revalidateTag('job-offers')`, `revalidateTag('trainings')`) po publikacji, wygaśnięciu, zapisie |
| `sitemap-oferty.xml` | `public, max-age=3600` |
| Pliki PDF | podpisane URL Supabase Storage, bez cache po stronie portalu |
| Obrazy | strefa używa jednego zdjęcia tła (`tlo-marmur-len`, wariant `-1024` na mobile), bez nowych ciężkich assetów |
| Szkło | najwyżej 3 tafle z `backdrop-filter` w widoku; listy (polisy, oferty, aplikacje) jako jedna tafla z liniami podziału, nie karta-szkło na element |
| Nowe hosty | brak (Turnstile już jest w CSP; Supabase i Resend tylko po stronie serwera) |

Skala obciążenia [hipoteza]: dziesiątki kont i pojedyncze tysiące odsłon strefy miesięcznie – mieści się w Workers Paid i Supabase Pro z 02 §1.3 bez dodatkowych kosztów.

## 17. SEO i GEO

- `/strefa-klienta/*`: `noindex, nofollow` (meta + nagłówek), `Disallow: /strefa-klienta/` w `robots.ts`, brak w sitemap.
- `/dam-prace` i oferty: indeksowane, `JobPosting` (pkt 11.3), `BreadcrumbList`, osobna sitemap z `lastmod`; wygasłe → 410.
- `/szkolenia` i strony szkoleń: indeksowane (Założenie), schema.org `EducationEvent` z `startDate`, `endDate`, `eventAttendanceMode` (online/offline/mixed), `location` (`Place` albo `VirtualLocation`), `organizer`, `offers` z `price: 0` i `availability` (`InStock`/`SoldOut`) tylko dla szkoleń bezpłatnych; odwołane – `eventStatus: EventCancelled`.
- `llms.txt`: dopisać sekcję „Strefa Klienta” (jedno zdanie: konto dla salonów z polisą BeautyPolisa – polisy, oferty pracy, szkolenia) i linki do `/dam-prace` i `/szkolenia`.
- Strona główna: teaser strefy (pkt 18.2) – treść statyczna, bez wpływu na LCP.

## 18. UX i design

### 18.1 Zasady dla strefy (spójne z 10)

- Ta sama paleta, typografia i ikony co v3; róż tylko w logo; złoto na jasnym tylko jako linie i ramki.
- Tło strefy: jedno zdjęcie (marmur z lnem) pod jasnym szkłem `glass--strong`; ciemne szkło na midnight tylko dla paska nawigacji. Fallbacki szkła (`@supports`, `prefers-reduced-transparency`, `prefers-contrast: more`) bez zmian.
- Typy ekranów: tabele/listy w jednej tafli z cienkimi liniami (czytelność > efekt), statusy jako tekst + ikona (nie sam kolor), daty w formacie „31 grudnia 2026 r.”, kwoty „882 zł” ze spacją nierozdzielającą.
- Formularze: etykiety nad polami, komunikaty błędów pod polem z `aria-describedby`, `autocomplete` (`email`, `one-time-code`, `name`, `tel`), cele dotykowe 44 px, widoczny fokus, brak tekstu poniżej 12 px.
- Animacje w strefie minimalne (przejścia stanów ≤ 200 ms, wyłączone przy `prefers-reduced-motion`) – strefa to narzędzie, nie opowieść.
- Ton: spokojny, rzeczowy, bez wykrzykników („Polisa jest aktywna do 31 grudnia 2026 r.”, „Oferta czeka na akceptację doradcy”).

### 18.2 Teaser na stronie głównej

Miejsce: nowa sekcja między „Jak to działa” (ciemny jedwab) a „Szkoda + FAQ” (marmur), na zdjęciu marmuru, **jedna** tafla `glass--strong` z trzema kolumnami rozdzielonymi złotą linią (limit tafli). Dodatkowo link „Strefa Klienta” w nagłówku (desktop: tekstowy link przed „Umów rozmowę”; mobile: pozycja w menu) i w stopce, obok „Dam pracę” i „Szkolenia”.

Treść (HTML, z twardymi spacjami):

```html
<p class="eyebrow">Strefa Klienta</p>
<h2>Po podpisaniu polisy <em>otwieramy Strefę Klienta</em></h2>
<p>Salon ubezpieczony w&nbsp;programie BeautyPolisa dostaje własne konto. Polisy i&nbsp;dokumenty są w&nbsp;jednym miejscu, a&nbsp;zespół zyskuje dostęp do ofert pracy i&nbsp;szkoleń.</p>
<!-- kolumna 1: ikona lux-dokumenty -->
<h3>Polisy i&nbsp;dokumenty</h3>
<p>Aktualne polisy, OWU i&nbsp;aneksy do pobrania o&nbsp;każdej porze. Przypomnimy o&nbsp;odnowieniu przed końcem ochrony.</p>
<!-- kolumna 2: ikona lux-kosmetolog -->
<h3>Dam pracę</h3>
<p>Opublikuj ofertę dla kosmetologa, fryzjera czy stylistki paznokci. Kandydaci aplikują przez formularz, bez zakładania konta.</p>
<!-- kolumna 3: ikona lux-w-zakresie -->
<h3>Szkolenia</h3>
<p>Katalog szkoleń dla właścicieli i&nbsp;zespołu. Zapis z&nbsp;konta salonu, przypomnienie przed terminem.</p>
<p class="note">Konto aktywuje Aura Consulting po zawarciu polisy – zaproszenie przychodzi e-mailem. Rejestracja nie jest potrzebna.</p>
<a class="btn btn-navy" href="strefa-klienta/logowanie">Zaloguj się do Strefy Klienta</a>
<a class="link-lux" href="dam-prace">Przeglądaj oferty pracy</a>
```

W makiecie (statycznej) linki wskazują `logowanie.html` i `dam-prace.html`. Zdanie o aktywacji odpowiada założeniu Z-1 – zmienić, jeśli zleceniodawca zdecyduje inaczej.

## 19. Plan wdrożenia

| Etap | Zakres | Zależności | Czas [Założenie] |
|---|---|---|---|
| **Z0** – decyzje | Odpowiedzi na pytania Q1–Q12; regulamin Strefy Klienta i regulamin „Dam pracę” z umową powierzenia; opinia prawna KRAZ i jawność wynagrodzeń; klauzule; decyzja o administratorze (00 §13 pkt 2) | – | 2–3 tygodnie, równolegle z fazą 1 portalu |
| **Z1** – konto i polisy | Migracja tabel kont, członkostw, zaproszeń, polis, dokumentów, audytu; Auth (SMTP Resend, OTP, TOTP, sesje); `/panel/klienci`; pulpit, polisy, dokumenty, odnowienia, zgłoszenie szkody, zespół; testy uprawnień; import startowy (M2) | faza 1 portalu (szkielet, `/panel`, outbox, CI) | 4–6 tygodni |
| **Z2** – „Dam pracę” i „Szkolenia” | Tabele i funkcje ofert, aplikacji, szkoleń; moderacja i katalog w `/panel`; publiczne `/dam-prace` i `/szkolenia` z JSON-LD i sitemap; przypomnienia; migracja M3; teaser na stronie głównej | Z1; opinia KRAZ | 4–6 tygodni |
| **Z3** – rozszerzenia | CV ze skanowaniem AV; synchronizacja z CRM (M5); zaświadczenia; obowiązkowy TOTP lub klucze dostępu; rola „manager”; Indexing API | decyzje Q8, Q12 | wg decyzji |

Definition of Done każdego etapu: testy uprawnień z pkt 9.6 zielone, Security Advisor bez pozycji ERROR/WARN dla nowych obiektów, audyt WCAG 2.2 AA ekranów etapu, budżety wydajności z 02 spełnione, wpis w rejestrze czynności przetwarzania.

## 20. Założenia (do decyzji zleceniodawcy)

| ID | Założenie |
|---|---|
| Z-1 | **Założenie:** konto aktywuje Aura Consulting, gdy salon ma aktywną polisę; bez otwartej rejestracji |
| Z-2 | **Założenie:** polisy i PDF-y wprowadza broker (admin) w `/panel`; bez integracji z ubezpieczycielem w MVP |
| Z-3 | **Założenie:** właściciel zaprasza pracowników; pracownicy widzą „Szkolenia” i „Dam pracę”, nie widzą polis |
| Z-4 | **Założenie:** oferty pracy są publiczne; kandydaci przeglądają bez konta i aplikują formularzem |
| Z-5 | **Założenie:** „Szkolenia” to katalog z zapisami (szkolenia bezpłatne lub partnerskie); płatności online poza MVP |
| Z-6 | **Założenie:** katalog szkoleń jest publiczny, zapis tylko z konta |
| Z-7 | **Założenie:** właścicielem konta jest osoba kontaktowa z polisy; kolejnych właścicieli dodaje Aura |
| Z-8 | **Założenie:** oferta ważna 30 dni, moderacja każdej oferty, limit 200 aplikacji na ofertę na dobę |
| Z-9 | **Założenie:** retencja aplikacji 90 dni po wygaśnięciu oferty; 12 miesięcy przy zgodzie na przyszłe rekrutacje |
| Z-10 | **Założenie:** przypomnienia o odnowieniu 60, 30 i 14 dni przed końcem ochrony |
| Z-11 | **Założenie:** limity: 15 osób w zespole, 10 oczekujących zaproszeń, 3 miejsca na szkoleniu na salon, kod logowania ważny 10 minut, zaproszenie 7 dni |
| Z-12 | **Założenie:** sesja maks. 30 dni, wylogowanie po 7 dniach bezczynności; TOTP opcjonalny dla właściciela |
| Z-13 | **Założenie:** po wygaśnięciu ostatniej polisy konto pozostaje aktywne 12 miesięcy (dostęp do dokumentów), potem zawieszenie |
| Z-14 | **Założenie:** dziennik audytu przechowywany 24 miesiące |
| Z-15 | **Założenie:** „Dam pracę” i „Szkolenia” są bezpłatne dla salonów z polisą |

## 21. Pytania otwarte do zleceniodawcy

| ID | Pytanie | Kto odpowiada | Blokuje |
|---|---|---|---|
| Q1 | Czy konto przysługuje przy każdej polisie (także Tax Protect, Grupowe ERGO, abonament medyczny), czy tylko przy OC beauty? | zleceniodawca | Z1 |
| Q2 | Kto jest właścicielem konta, gdy ubezpieczającym jest spółka, a kontaktem menedżer? | zleceniodawca | Z1 |
| Q3 | Czy po wygaśnięciu polisy salon zachowuje dostęp do „Dam pracę” i „Szkoleń” (Z-13)? | zleceniodawca | Z1 |
| Q4 | Czy TOTP ma być obowiązkowy dla właścicieli od startu? | zleceniodawca + bezpieczeństwo | nie |
| Q5 | Administrator danych strefy: Aura Consulting czy Aura Expert (00 §13 pkt 2)? | zleceniodawca + IOD | Z1 |
| Q6 | Jak długo przechowujemy dokumenty polis i dane kont po zakończeniu współpracy (obowiązki dystrybutora)? | IOD + prawnik | Z1 |
| Q7 | Czy prowadzenie „Dam pracę” wymaga wpisu do KRAZ i jak spełnić wymogi jawności wynagrodzeń (pkt 11.6)? | prawnik | Z2 |
| Q8 | Czy CV w PDF są potrzebne, a jeśli tak – zgoda na nowy podmiot przetwarzający do skanowania (pkt 10.3)? | zleceniodawca + IOD | Z3 |
| Q9 | Czy moduły `job_listings`/`trainings` w „BEAUTY” (katalog `app.`) są używane i czy można je wygasić po migracji? | zleceniodawca | Z2 (M4) |
| Q10 | Czy pracownicy mają widzieć oferty pracy salonu i czy potrzebna jest rola „manager” (oferty bez polis)? | zleceniodawca | nie |
| Q11 | Kto organizuje szkolenia (Aura, partnerzy – którzy, za jaką zgodą na użycie nazwy) i czy listy uczestników trafiają do partnerów? | zleceniodawca + IOD | Z2 |
| Q12 | Czy szkolenia mają być dostępne dla wszystkich (katalog publiczny), czy tylko dla klientów (Z-6)? | zleceniodawca | Z2 |
| Q13 | Czy z CRM ma płynąć automatyczna synchronizacja polis (M5) i kto ją utrzyma po stronie „BEAUTY”? | zleceniodawca + zespół CRM | Z3 |
| Q14 | Czy salony mogą pokazywać w ofercie logo i adres, czy wyłącznie nazwę i miasto? | zleceniodawca | nie |

## 22. Decyzje (do rejestru w 08)

| ID | Decyzja | Odrzucone |
|---|---|---|
| D16 | Strefa Klienta w tej samej aplikacji i w nowym projekcie Supabase portalu; dane modułów „BEAUTY” migrowane, CRM pozostaje źródłem polis | strefa na „BEAUTY” (A), osobny schemat w „BEAUTY” (C), osobna aplikacja |
| D17 | Konta wyłącznie z zaproszenia; logowanie kodem z e-maila; opcjonalny TOTP egzekwowany w RLS | hasła, otwarta rejestracja, logowanie przez media społecznościowe |
| D18 | Izolacja salonów w RLS przez `client_account_ids()`; zapisy międzysalonowe tylko funkcjami `service_role` | autoryzacja w kodzie aplikacji, widoki SECURITY DEFINER |
| D19 | Dokumenty w prywatnym kubełku, podpisywane sesją użytkownika na 60 s | publiczny kubełek, proxy plików przez Worker, załączniki e-mail |
| D20 | „Dam pracę”: moderacja przed publikacją, widełki obowiązkowe, aplikacja bez konta, bez CV do czasu skanowania AV, salon administratorem danych kandydatów | konta kandydatów, baza CV, aplikacje widoczne dla Aura |
| D21 | „Szkolenia”: publiczny katalog, zapis z konta, limit miejsc z blokadą wiersza, bez płatności w MVP | płatności online, zapisy bez konta |
