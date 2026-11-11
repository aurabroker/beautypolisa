# 11 · Strefa Klienta – konto salonu: polisy, „Dam pracę”, „Szkolenia”

| | |
|---|---|
| Wersja | 1.1 (po decyzjach zleceniodawcy z 11.11.2026 i przeglądzie bezpieczeństwa; do akceptacji zleceniodawcy) |
| Data | 11 listopada 2026 |
| Zakres | Konto klienta dla salonu, który kupił polisę przez BeautyPolisa: polisy i dokumenty, tablica ogłoszeń „Dam pracę”, „Szkolenia” z kontami organizatorów szkoleń |
| Wymaganie źródłowe | „Salon, który kupi u nas polisę, będzie miał swoje konto z polisami, dostęp do działu DAM PRACĘ, Szkolenia” (zleceniodawca, 11.11.2026) |
| Decyzje zleceniodawcy | D-A–D-D z 11.11.2026 (tabela niżej) – mają pierwszeństwo przed założeniami i pytaniami z wersji 1.0 |
| Pliki towarzyszące | `snippets/strefa-klienta.sql` (DDL, RLS, funkcje); makiety `design/v3/logowanie.html`, `panel.html`, `dam-prace.html`, `szkolenia.html` (w przygotowaniu) |
| Status | Koncepcja – nic z tego dokumentu nie jest wdrożone |

> Fakty biznesowe pochodzą wyłącznie z `01-audyt-stanu-obecnego.md`. Strukturę istniejących modułów projektu Supabase „BEAUTY” sprawdzono 11.11.2026 zapytaniami do katalogu systemowego (nazwy tabel i kolumn, polityki RLS, uprawnienia, liczby wierszy) – bez odczytu treści wierszy. Wszystko, czego nie da się wyprowadzić z audytu ani z decyzji zleceniodawcy, jest oznaczone jako **Założenie** (do decyzji zleceniodawcy) albo „[do weryfikacji]”.

**Decyzje zleceniodawcy z 11.11.2026**

| ID | Decyzja | Skutek w tym dokumencie |
|---|---|---|
| D-A | Konto w Strefie Klienta dostaje każdy klient, który kupi przez BeautyPolisa **dowolną** polisę: OC beauty, Tax Protect, grupowe ERGO, opiekę medyczną, utratę dochodu albo NNW dzieci – nie tylko OC | Aktywacja wymaga aktywnej polisy dowolnego produktu (4.1); dawne pytanie Q1 zamknięte |
| D-B | Po wygaśnięciu ostatniej polisy salon **zachowuje konto** oraz dostęp do „Dam pracę” i „Szkoleń”; wygasłe polisy są widoczne jako archiwalne; bez automatycznego odcięcia konta | Dawne założenie Z-13 i pytanie Q3 usunięte; zamiast odcięcia – kontrole cyklu życia konta (4.7, 11.2) |
| D-C | „Dam pracę” to **wyłącznie tablica ogłoszeń**. Słowa zleceniodawcy: „AURA, ani nikt inny nie rekomenduje, nie szuka pracowników. To ma być tylko tablica!” Salon publikuje ogłoszenie, kandydat je czyta i kontaktuje się z salonem bezpośrednio. Prowadzenie tablicy nie wymaga wpisu do KRAZ – decyzja zleceniodawcy | Usunięte: aplikacje przechowywane w platformie, dane i konta kandydatów, CV, statusy rekrutacji, wyszukiwanie, polecanie i dopasowywanie kandydatów (rozdział 11); pytanie o KRAZ nie blokuje etapów |
| D-D | Szkolenia dodają salony z kontem **albo firmy szkoleniowe**. Nowa rola: **organizator szkoleń** – nie potrzebuje polisy, dostaje konto z zaproszenia po weryfikacji przez Aura | Nowe tabele organizatorów, moderacja szkoleń, minimalne dane uczestników dla organizatora, role RODO do potwierdzenia przez prawnika (rozdział 12) |

## TL;DR

1. **Strefa Klienta to druga, prywatna część tej samej aplikacji Next.js** (`/strefa-klienta/*`) w tym samym, nowym projekcie Supabase co portal (D2). Nie korzystamy z bazy „BEAUTY” na żywo: jej moduły ogłoszeń o pracę i szkoleń mają tylko 1 ogłoszenie, 0 aplikacji, 6 szkoleń i 0 zapisów, a ich model (płatne ogłoszenia, aplikacje tylko z kontem, publiczny odczyt telefonu i e-maila ogłoszeniodawcy) nie pasuje do wymagań. **Rekomendacja: nowe tabele w projekcie portalu, jednorazowa migracja tych kilku wierszy, CRM w „BEAUTY” zostaje systemem źródłowym polis** z jednokierunkowym, zabezpieczonym przekazem do portalu w etapie Z3.
2. **Konto dostaje klient z każdą polisą kupioną przez BeautyPolisa (D-A) i zachowuje je po wygaśnięciu polis (D-B).** Konto zakłada Aura Consulting (Założenie): broker dodaje polisę i jej dokumenty PDF w `/panel`, publikuje je i aktywuje konto. Rejestracji otwartej nie ma.
3. **Logowanie bez hasła:** sześciocyfrowy kod jednorazowy z e-maila (Supabase Auth) z limitami po stronie aplikacji, sesja serwerowa w ciasteczkach `__Host-…; HttpOnly`. **Drugi składnik TOTP jest obowiązkowy dla właścicieli i organizatorów** (rekomendacja; egzekwuje go baza przez wymóg sesji `aal2`), dla pracowników – opcjonalny.
4. **Role:** właściciel salonu (polisy, zespół, ogłoszenia, szkolenia), pracownik (szkolenia, podgląd ogłoszeń salonu – bez polis), **organizator szkoleń** (firma szkoleniowa albo salon: własne szkolenia, terminy, liczba miejsc, lista uczestników tylko własnych szkoleń), personel Aura (`admin`/`agent`/`viewer` z `/panel`), gość i kandydat bez konta (czytają ogłoszenia i katalog szkoleń).
5. **Izolację egzekwuje Postgres (RLS), nie interfejs:** dwie rozłączne funkcje pomocnicze `client_account_ids()` (salony) i `organizer_ids()` (organizatorzy), uprawnienia kolumnowe, zapisy z niezmiennikami wyłącznie przez funkcje `service_role`. Model sprawdzono na lokalnym Postgresie 16 (9.6).
6. **„Dam pracę” to tylko tablica (D-C):** ogłoszenia publiczne i indeksowane (schema.org `JobPosting`), moderowane przed publikacją wyłącznie pod kątem treści, ważne 30 dni (Założenie), z obowiązkowymi widełkami wynagrodzenia. Kandydat kontaktuje się z salonem bezpośrednio – przez e-mail lub telefon rekrutacyjny wskazany przez salon albo przez prosty formularz, który przekazuje wiadomość e-mailem do salonu i nie zostaje w platformie. **Aura Consulting i platforma nie rekomendują, nie wyszukują, nie dobierają ani nie kontaktują się z kandydatami.**
7. **„Szkolenia” (D-D):** publiczny katalog szkoleń dodawanych przez zweryfikowanych organizatorów (firmy i salony), moderacja przed publikacją i po każdej zmianie, zapis z konta salonu, limit miejsc z listą rezerwową. Organizator dostaje tylko imię i nazwisko oraz e-mail uczestników swoich szkoleń, po wyraźnej informacji przy zapisie. Płatności online poza MVP: przy szkoleniu płatnym strona pokazuje cenę, a fakturę wystawia organizator (Założenie).
8. **Prywatność i wydajność:** strony strefy są dynamiczne, `no-store`, `noindex`, bez klienta Supabase w przeglądarce i bez nowych hostów zewnętrznych. Publiczne „Dam pracę” i „Szkolenia” mają dane w cache z rewalidacją po publikacji – tylko z zapytań bez sesji użytkownika.
9. **Plan:** Z0 (decyzje i dokumenty prawne) → Z1 konto i polisy (po fazie 1 portalu) → Z2 „Dam pracę”, „Szkolenia” i organizatorzy → Z3 przekaz z CRM, zaświadczenia, rozszerzenia.

---

## 1. Kontekst i zmiana zakresu

**Problem.** Salon, który kupił polisę przez BeautyPolisa, ma dziś dokumenty rozproszone w e-mailach, a o odnowieniu dowiaduje się od opiekuna. Portal w koncepcji v1 kończy relację na leadzie. Zleceniodawca chce, żeby polisa otwierała stałą relację: konto z polisami oraz dostęp do dwóch działów przydatnych w codziennym prowadzeniu salonu – tablicy ogłoszeń o pracę i szkoleń.

**Co się zmienia względem dokumentów 00 i 02:**

| Miejsce | Było | Jest (po akceptacji tej sekcji) |
|---|---|---|
| 00 §5 „Poza zakresem v1” | „konta klientów” | Konta klientów wchodzą jako osobny etap Z1–Z2 **po** fazie 1 portalu (nie opóźniają startu portalu) |
| D8 / 02 F6 | Supabase Auth tylko dla personelu `/panel` | Supabase Auth także dla salonów i organizatorów szkoleń (`/strefa-klienta`); personel, salony i organizatorzy rozdzieleni rolami i wyzwalaczami (9.3); podsumowanie zmian w 02 §4.13 |
| 02 §4.5 „brak klienta Supabase w przeglądarce” | – | Bez zmian: strefa też nie ma klienta Supabase w przeglądarce; sesja wyłącznie w ciasteczkach `HttpOnly` |
| 02 §4.3 reguła WAF `Origin` i reguła rate limit | tylko ścieżki `/api/*` | Od etapu Z1 dodatkowo ścieżki logowania, zaproszeń i formularzy strefy (8, 02 §4.13) |
| `snippets/robots.txt` | `Disallow: /panel/` | Dodatkowo `Disallow: /strefa-klienta/` (17) |
| 04 mapa URL | – | Nowe publiczne huby `/dam-prace` i `/szkolenia` |

## 2. Cele, nie-cele, mierniki

### 2.1 Cele

| # | Cel | Miernik | Próg [hipoteza – skalibrować po 90 dniach] |
|---|---|---|---|
| C1 | Właściciel ma polisy i dokumenty w jednym miejscu | % aktywowanych kont, w których właściciel zalogował się w ciągu 14 dni od zaproszenia | ≥ 60 % |
| C2 | Mniej próśb o duplikaty dokumentów | liczba próśb „proszę o polisę/OWU” do opiekuna (notowana w CRM) | spadek o połowę po 6 miesiącach |
| C3 | Odnowienia nie umykają | % polis odnowionych przed końcem ochrony wśród kont aktywnych | rośnie kwartał do kwartału |
| C4 | Tablica „Dam pracę” jest używana | liczba opublikowanych ogłoszeń / miesiąc; liczba odsłon kontaktu („Pokaż kontakt”) i wiadomości przekazanych formularzem na ogłoszenie – wyłącznie liczniki, bez danych kandydatów | ≥ 1 kontakt na ogłoszenie w medianie |
| C5 | „Szkolenia” budują relację | liczba zweryfikowanych organizatorów i opublikowanych szkoleń / miesiąc; zapisy / szkolenie; obecność (`attended` / `registered`) | obecność ≥ 70 % |

### 2.2 Nie-cele (MVP)

| Nie robimy | Dlaczego |
|---|---|
| Polecanie, wyszukiwanie, dobór, ranking i dopasowywanie kandydatów (także „polecani kandydaci” i podpowiedzi AI); kontakt Aura z kandydatami; usługi rekrutacyjne | Decyzja zleceniodawcy D-C: „Dam pracę” to tylko tablica |
| Konta i profile kandydatów, baza CV, przechowywanie aplikacji i statusów rekrutacji w platformie | D-C; minimalizacja danych osobowych (11.1) |
| Sprzedaż i płatności online (polisy, szkolenia, ogłoszenia) | Portal jest informacyjno-leadowy (00 §1); płatności wymagają regulaminu, operatora i nowego hosta w CSP; przy szkoleniach płatnych fakturę wystawia organizator (Założenie) |
| Integracja na żywo z ubezpieczycielem | Brak API w audycie; polisy wprowadza broker (Założenie) |
| Komunikator salon–kandydat i salon–organizator | Kontakt odbywa się poza portalem (e-mail, telefon) |
| Edycja danych polisy przez klienta | Dane polisy pochodzą od brokera; klient zgłasza zmianę opiekunowi |
| Aplikacja mobilna | Strefa jest responsywna od 360 px |

## 3. Użytkownicy i role

| Rola | Kto | Jak dostaje dostęp | Co widzi i robi |
|---|---|---|---|
| **Właściciel salonu** (`owner` w `client_members`) | osoba wskazana przy polisie (Założenie: osoba kontaktowa z polisy, z osobistym adresem e-mail – 4.1) | zaproszenie od Aura po aktywacji konta | polisy (aktualne i archiwalne) i dokumenty, zgłoszenie szkody, prośba o odnowienie, zespół (zaprasza i usuwa pracowników, raz w roku potwierdza skład), ogłoszenia „Dam pracę” i ich kontakt, szkolenia (zapis własny i podgląd zapisów zespołu), historia zdarzeń konta |
| **Pracownik** (`employee`) | osoba z zespołu salonu | zaproszenie od właściciela | szkolenia (zapis własny), podgląd ogłoszeń swojego salonu; **nie widzi** polis, dokumentów ani danych kontaktowych w ogłoszeniach |
| **Organizator szkoleń** (`owner`/`member` w `organizer_members`) | firma szkoleniowa albo salon prowadzący szkolenia; **bez polisy** | zaproszenie od Aura po weryfikacji organizatora (12.1); właściciel profilu organizatora może zaprosić członków zespołu | dodaje szkolenia (publikacja po moderacji), zmienia terminy i treść (ponowna moderacja), zmienia liczbę miejsc, odwołuje szkolenie, widzi listę uczestników **tylko swoich** szkoleń (imię i nazwisko, e-mail, status; nazwa salonu tylko przy szkoleniu płatnym), oznacza obecność; nie widzi polis, salonów, zespołów ani ogłoszeń w szkicu |
| **Doradca / admin Aura** (`admin_users`: `admin`, `agent`, `viewer`) | personel Aura Consulting | istniejący `/panel` (Cloudflare Access + Supabase Auth z MFA, 02 F6) | zakłada konta salonów, dodaje i publikuje polisy i dokumenty, aktywuje konta, weryfikuje organizatorów, moderuje ogłoszenia i szkolenia, obsługuje zgłoszenia nadużyć; **nie widzi** wiadomości kandydatów (nie są przechowywane) ani list uczestników organizatorów |
| **Kandydat** | osoba szukająca pracy | bez konta | czyta ogłoszenia, kontaktuje się z salonem bezpośrednio (e-mail, telefon albo formularz przekazujący wiadomość do salonu), może zgłosić nadużycie |
| **Gość** | każdy | – | publiczne `/dam-prace` i katalog `/szkolenia` (Założenie: katalog publiczny, zapis tylko z konta salonu) |

**Zasada tablicy (D-C):** Aura Consulting i platforma nie rekomendują, nie wyszukują, nie dobierają ani nie kontaktują się z kandydatami; moderacja dotyczy wyłącznie treści ogłoszenia.

Macierz uprawnień (✓ – tak, ○ – tylko własne, – – nie):

| Zasób | Właściciel | Pracownik | Organizator | Personel admin/agent | Personel viewer | Gość / kandydat |
|---|---|---|---|---|---|---|
| Dane salonu | ✓ odczyt | ✓ odczyt | – | ✓ | odczyt | – |
| Polisy (aktualne i archiwalne), dokumenty PDF | ✓ odczyt opublikowanych | – | – | ✓ | odczyt | – |
| Zgłoszenie szkody | ✓ | – | – | ✓ | odczyt | formularz publiczny `/szkoda` (02 F7) |
| Zespół salonu, zaproszenia | ✓ (zaprasza tylko pracowników) | ○ (własne członkostwo) | – | ✓ | odczyt | – |
| Ogłoszenia salonu | ✓ tworzy, edytuje, zamyka | odczyt | – | moderacja | odczyt | odczyt opublikowanych |
| Kontakt w ogłoszeniu | ✓ | – | – | odczyt (moderacja) | odczyt | po „Pokaż kontakt” (e-mail lub telefon) albo formularz; adres dla formularza nigdy nie jest pokazywany |
| Profil organizatora | – | – | ○ odczyt | ✓ zakłada, weryfikuje, zawiesza | odczyt | odczyt publiczny (zweryfikowani) |
| Szkolenia – katalog | ✓ | ✓ | ✓ | ✓ | odczyt | odczyt |
| Szkolenia – dodawanie, zmiany, liczba miejsc, odwołanie | – | – | ○ (moderacja przed publikacją) | moderacja, usunięcie | odczyt | – |
| Zapisy na szkolenia | ✓ własne + zespołu | ○ | – | ✓ odczyt | odczyt | – |
| Dane uczestników dla organizatora | – | – | ○ tylko własne szkolenia | – | – | – |
| Dziennik zdarzeń | ✓ swojego salonu | – | – | ✓ | odczyt | – |

Jedna osoba może należeć do kilku salonów (np. sieć) i jednocześnie do profilu organizatora (salon, który prowadzi szkolenia, ma osobny profil organizatora). Konto personelu Aura nie może być członkiem salonu ani organizatora – rozdział egzekwują funkcje przyjęcia zaproszeń i wyzwalacz na `admin_users` (9.3).

## 4. Ścieżki użytkownika

### 4.1 Aktywacja po zakupie polisy

1. Polisa zostaje zawarta poza portalem (00 §1). Doradca w `/panel` → „Klienci” → „Nowe konto”: nazwa salonu, NIP, miasto, odwołanie do CRM (`crm_ref`), opcjonalnie lead źródłowy.
2. Doradca dodaje polisę – **dowolny produkt** z oferty (D-A): produkt, ubezpieczyciel, numer, okres, składka. Dla OC beauty wybiera grupy zabiegów, sumę, ochronę prawną i wielkość zespołu – **serwer przelicza składkę z aktywnej wersji taryfy** (ta sama czysta funkcja co kalkulator, 02 F2) i odrzuca zapis, jeśli kwota się nie zgadza. Grupa 4 i zespół od 9 osób nie mają kwoty z taryfy – doradca wpisuje składkę z wyceny indywidualnej i zaznacza `oc_individual_quote`; strefa pokazuje wtedy „Wycena indywidualna” obok kwoty z polisy. Dla pozostałych produktów doradca wpisuje składkę z dokumentu polisy; walidacja z cennikiem tylko tam, gdzie w bazie jest wersjonowany cennik produktu.
3. Doradca wgrywa PDF-y (polisa, OWU, aneksy) – walidacja typu, rozmiaru i sygnatury pliku, hash SHA-256 – i publikuje polisę.
4. „Aktywuj Strefę Klienta” → `app_activate_client_account()` (wymaga co najmniej jednej aktywnej, opublikowanej polisy dowolnego produktu) → zaproszenie dla właściciela ważne 7 dni. Jeśli adres właściciela wygląda na wspólną skrzynkę (`recepcja@`, `kontakt@`, `biuro@`…), panel ostrzega i prosi o adres osobisty (Założenie) – logowanie dowodzi tylko dostępu do skrzynki. E-mail: „Strefa Klienta BeautyPolisa jest gotowa” z przyciskiem „Przyjmij zaproszenie”.

### 4.2 Pierwsze logowanie (przyjęcie zaproszenia)

1. Link z e-maila ma postać `/strefa-klienta/zaproszenie#t=…` – **token w części po `#`**, której przeglądarka nie wysyła do serwera, więc nie trafia do logów Workera, Sentry, kolektora analityki ani nagłówka `Referer`. Mały skrypt (z nonce CSP) przenosi token do treści żądania POST. Bez JavaScriptu strona prosi o wklejenie kodu zaproszenia z tego samego e-maila. Strona ma `Referrer-Policy: no-referrer`; `/strefa-klienta/*` jest wyłączone z kolektora analityki i z przechwytywania adresów w Sentry. Żądanie GET niczego nie zmienia (skanery poczty, np. ochrona linków w Microsoft 365, otwierają linki automatycznie).
2. Serwer sprawdza token (hash, ważność, jednorazowość) i pokazuje nazwę salonu z przyciskiem „Przyjmij zaproszenie”. **Zaproszenie nigdy samo nie tworzy sesji:**
   - adres ma już konto Auth → zwykłe logowanie kodem z e-maila (i TOTP, jeśli włączony), a dopiero w zalogowanej sesji `app_accept_invitation()`;
   - adres nie ma konta → serwer zakłada użytkownika (klucz `sb_secret_…`, rejestracja publiczna wyłączona) i wysyła kod jednorazowy na ten adres; sesja powstaje dopiero po wpisaniu kodu, co dowodzi dostępu do skrzynki w chwili użycia zaproszenia [mechanizm do potwierdzenia w PoC].
3. Ekran powitalny: regulamin Strefy Klienta (wersja zapisywana w `client_members.terms_version`), link do klauzuli informacyjnej, **konfiguracja TOTP – obowiązkowa dla właściciela** (rekomendacja, Q3), dla pracownika – propozycja z opcją „Później”. Każdy ekran potwierdzenia pokazuje adres e-mail zalogowanej osoby.
4. Pulpit.

Organizator szkoleń przechodzi tę samą ścieżkę z osobnym rodzajem zaproszenia (`organizer_invitations`) – token zaproszenia salonu nie zadziała jako zaproszenie organizatora i odwrotnie. TOTP jest dla organizatora obowiązkowy, bo przetwarza dane uczestników.

### 4.3 Kolejne logowania

`/strefa-klienta/logowanie` → adres e-mail + Turnstile → komunikat neutralny „Jeśli adres jest przypisany do konta, wysłaliśmy kod” (brak enumeracji kont) → sześciocyfrowy kod (ważny 10 minut – Założenie) + Turnstile → kod z aplikacji uwierzytelniającej (właściciel, organizator, pracownik z włączonym TOTP) → pulpit.

- **Limity po stronie aplikacji, zanim serwer wywoła Supabase** (Supabase widzi adresy IP Workera, nie użytkowników): binding Workers Rate Limiting albo Durable Object z kluczem HMAC znormalizowanego adresu – najwyżej 5 wysłanych kodów na adres na godzinę, najwyżej 5 błędnych prób na kod (potem kod jest unieważniany i trzeba poprosić o nowy), 10 żądań na godzinę na skrót IP przechowywany wyłącznie w limiterze (Założenie). Odpowiedzi zawsze neutralne.
- E-mail z kodem zawiera też link „Zaloguj się jednym kliknięciem” w przepływie **PKCE**: weryfikator jest w ciasteczku `__Host-` przeglądarki, która poprosiła o kod, więc link zadziała tylko w niej (ochrona przed podrzuceniem cudzej sesji, 8). W innej przeglądarce strona prosi o wpisanie kodu. Link prowadzi na stronę z przyciskiem POST (z tego samego powodu co w 4.2).
- Właściciel i organizator dostają e-mail o logowaniu z nowego urządzenia; „Ustawienia” pokazują ostatnie logowania i „Wyloguj wszędzie”.
- Konto bez logowania od 24 miesięcy (D-B) wymaga przed wydaniem sesji ponownej weryfikacji przez personel (Założenie).

### 4.4 Polisy i dokumenty

Pulpit pokazuje karty aktualnych polis (produkt, numer, okres ochrony, składka, status), a zakładka „Archiwum” – polisy wygasłe, odnowione i rozwiązane (D-B). Szczegóły polisy: parametry (dla OC: grupa taryfowa, suma gwarancyjna, ochrona prawna, wielkość zespołu), lista dokumentów, „Zgłoś szkodę”, „Odnów z doradcą”. Pobranie dokumentu: link do trasy serwerowej, która sprawdza uprawnienie sesją użytkownika (RLS), tworzy podpisany URL na 60 s z `download` i odpowiada przekierowaniem 303; zdarzenie `document_downloaded` trafia do dziennika.

### 4.5 Przypomnienia o odnowieniu

Codzienny Cron w `beautypolisa-jobs` wybiera aktywne polisy z `valid_to` za 60, 30 i 14 dni (Założenie) i wysyła e-mail do właścicieli: „Ochrona kończy się 31 grudnia 2026 r. Odnowienie przygotuje doradca”. Idempotencja: `client_policy_reminders (policy_id, kind)`. W strefie ta sama informacja jako baner na pulpicie. Przycisk „Odnów z doradcą” tworzy lead (`leads`, produkt polisy, kontekst konta) – bez nowej wyceny w strefie; składka OC po odnowieniu wynika z aktywnej taryfy programu.

### 4.6 Zgłoszenie szkody

Z karty polisy: „Zgłoś szkodę” → ten sam formularz co publiczny `/szkoda` (02 F7, **bez pola opisu** – szczegóły zdarzenia, zwykle o zdrowiu klientki salonu, zbiera opiekun telefonicznie), z prewypełnionym produktem, numerem polisy i kontaktem właściciela. Zapis do `claims_reports` z `account_id`, `policy_id`, `reported_by`. Właściciel widzi w strefie numer zgłoszenia i status (`new` → `forwarded` → `closed`). Obok instrukcja krok po kroku (treść jak `schema-howto-szkoda.json`).

### 4.7 Zespół salonu

„Zespół” → „Zaproś osobę” → adres e-mail (+ imię opcjonalnie) → `app_create_invitation()` (właściciel zaprasza tylko rolę `employee`; limit 15 aktywnych osób i 10 oczekujących zaproszeń – Założenie) → e-mail jak w 4.1. Właściciel widzi listę osób i zaproszeń, może ponowić zaproszenie (nowy link, stary przestaje działać), cofnąć je i odebrać dostęp (`app_revoke_member()`; salon zawsze ma co najmniej jednego właściciela). Odebranie dostępu anuluje przyszłe zapisy pracownika na szkolenia.

Konto nie wygasa wraz z polisą (D-B), więc dostęp porządkują kontrole cyklu życia (Założenie): raz w roku właściciel potwierdza skład zespołu („Zespół jest aktualny”, `app_confirm_team()`); pracownik bez logowania od 12 miesięcy traci dostęp automatycznie (`app_revoke_dormant_members()`), a właściciel dostaje o tym e-mail.

### 4.8 Publikacja ogłoszenia „Dam pracę”

„Dam pracę” → „Nowe ogłoszenie”: stanowisko, zawód (lista jak w ikonach: kosmetolog, fryzjer, podolog, linergistka, stylistka paznokci, tatuażysta, recepcja, inny), rodzaj umowy, wymiar czasu, miasto i województwo, **widełki wynagrodzenia (obowiązkowe)**, opis, wymagania, oferujemy – tekst zwykły, bez linków, numerów telefonów i adresów e-mail w treści.

**Jak kandydat ma się skontaktować** (blok kontaktu, wybór salonu):

| Sposób | Co widzi kandydat | Uwagi |
|---|---|---|
| **Formularz kontaktowy** (domyślny) | formularz na stronie ogłoszenia | wiadomość trafia e-mailem na adres rekrutacyjny salonu, którego strona nie pokazuje; platforma nie przechowuje wiadomości (11.3) |
| E-mail rekrutacyjny | adres po kliknięciu „Pokaż kontakt” | podpowiedź: „Użyj adresu rekrutacyjnego salonu, nie prywatnego” |
| Telefon rekrutacyjny | numer po kliknięciu „Pokaż kontakt” | jw.; przy jednoosobowej działalności numer bywa daną osobową właściciela |

Podgląd → „Wyślij do akceptacji” (`pending_review`) → moderacja w `/panel` (11.2) → publikacja na 30 dni (Założenie) → e-mail do właściciela. W trakcie moderacji ogłoszenia i kontaktu nie da się zmieniać – trzeba je najpierw wycofać do szkicu. Każda zmiana treści albo kontaktu w opublikowanym ogłoszeniu wysyła je ponownie do moderacji. Właściciel może zamknąć ogłoszenie w każdej chwili. Na 3 dni przed wygaśnięciem – e-mail z opcją przedłużenia (= ponowna moderacja). Adres strony (`slug`) nadaje baza: zawód + miasto + losowy sufiks.

### 4.9 Kandydat czyta ogłoszenie i kontaktuje się z salonem

`/dam-prace` → filtr (zawód, województwo, rodzaj umowy) → `/dam-prace/<slug>` → blok „Jak się skontaktować”:

- **E-mail lub telefon:** przycisk „Pokaż kontakt” (Turnstile + limit na IP) pokazuje adres (`mailto:`) albo numer (`tel:`) wskazany przez salon. Kontakt nie trafia do listy ogłoszeń, JSON-LD ani sitemap.
- **Formularz:** imię i nazwisko, e-mail do odpowiedzi, telefon (opcjonalnie), wiadomość do 1000 znaków (tekst zwykły, bez linków i załączników), informacja: „Wiadomość przekażemy e-mailem do salonu {nazwa}. Salon odpowie bezpośrednio na Twój adres. BeautyPolisa nie przechowuje wiadomości i nie bierze udziału w rekrutacji. Administratorem Twoich danych w rekrutacji jest salon” + link do klauzuli → Turnstile → `app_relay_job_message()` → **potwierdzenie wyłącznie na ekranie**: „Wiadomość została przekazana do salonu”. Do kandydata nie wysyłamy żadnego e-maila.
- Przy każdym ogłoszeniu: „Zgłoś nadużycie” (bez danych zgłaszającego).

Platforma nie prowadzi skrzynki odbiorczej, listy kandydatów ani statusów rekrutacji. Dalszy kontakt salon–kandydat odbywa się poza portalem.

### 4.10 Szkolenia – uczestnik z salonu

`/szkolenia` (publiczny katalog) albo `/strefa-klienta/szkolenia` → karta szkolenia (temat, termin, forma, miasto, organizator ze znaczkiem „Organizator zweryfikowany przez Aura Consulting (dane firmy)”, wolne miejsca, przy szkoleniu płatnym cena brutto z dopiskiem „fakturę wystawia organizator”) → „Zapisz się” (dla zalogowanych członków salonu; gość widzi „Zaloguj się, aby się zapisać”) → **krok informacyjny:** „Twoje imię i nazwisko oraz adres e-mail otrzyma organizator {nazwa}, który jest administratorem tych danych” (przy szkoleniu płatnym także nazwa salonu – do faktury) + link do informacji organizatora → „Potwierdzam zapis” → `app_training_register()` (z wersją wyświetlonej informacji) → „Zapisano” albo „Lista rezerwowa – pozycja 2” → e-mail z potwierdzeniem. Link do spotkania online (z widoczną nazwą hosta, np. „zoom.us”) i adres sali widoczne dopiero po zapisie (`training_private_details`). Przypomnienie 24 h przed. Rezygnacja jednym przyciskiem zwalnia miejsce i awansuje pierwszą osobę z listy rezerwowej (e-mail „Zwolniło się miejsce”). Właściciel widzi, kto z zespołu jest zapisany. Przy szkoleniu: „Zgłoś nadużycie”.

### 4.11 Organizator szkoleń (D-D)

1. **Zgłoszenie i weryfikacja (Założenie):** firma albo salon zgłasza chęć prowadzenia szkoleń (kontakt z Aura). Personel sprawdza firmę w rejestrze (NIP, KRS albo CEIDG), adres e-mail w domenie firmy, oddzwania na numer z rejestru lub strony firmy i zawiera umowę organizatora (cel przetwarzania danych uczestników ograniczony do przeprowadzenia szkolenia i wystawienia faktury; zakaz marketingu i rekrutacji z list uczestników). Dopiero wtedy w `/panel` → „Organizatorzy” powstaje profil (`training_organizers`: nazwa wyświetlana, dane firmy, miasto, strona, opis) ze statusem `active` i datą weryfikacji.
2. **Zaproszenie** osobnym tokenem (`organizer_invitations`) → logowanie jak w 4.2 → obowiązkowy TOTP. Salon, który jest organizatorem, dostaje osobny profil organizatora; ta sama osoba przełącza w menu konta „Salon” / „Organizator”.
3. **„Dodaj szkolenie”:** tytuł, krótki opis, program, forma (stacjonarne, online, hybrydowe), miasto i nazwa miejsca, termin rozpoczęcia i zakończenia, koniec zapisów, liczba miejsc, limit miejsc na salon, adresaci (wszyscy członkowie salonów albo tylko właściciele), cena (bezpłatne albo płatne z ceną brutto), szczegóły dla zapisanych (link do spotkania z hostów z listy dozwolonych – Założenie: Zoom, Microsoft Teams, Google Meet; adres sali; instrukcje). Tekst zwykły – bez linków, numerów kont, linków płatności i numerów telefonów w opisie. „Wyślij do moderacji”.
4. **„Moje szkolenia jako organizator”:** lista ze statusami: szkic, w moderacji, opublikowane, odrzucone (z powodem), odwołane, zakończone; przy każdym: liczba zapisanych i rezerwowych, „Edytuj”, „Zmień liczbę miejsc” (`app_training_set_capacity()` – nie mniej niż liczba zapisanych; zwiększenie awansuje osoby z listy rezerwowej), „Odwołaj szkolenie” (`app_training_cancel_event()` – zapisani dostają e-mail). Każda zmiana treści, terminu, miejsca albo linku w opublikowanym szkoleniu zdejmuje je z katalogu do ponownej akceptacji; zapisani zachowują miejsca i po akceptacji dostają e-mail `training_changed`.
5. **Lista uczestników** (tylko własne szkolenia): imię i nazwisko, e-mail, status (zapisany, obecny, nieobecny), nazwa salonu tylko przy szkoleniu płatnym; osoby z listy rezerwowej nie są widoczne. Informacja: „Dane uczestników usuniemy 30 dni po zakończeniu szkolenia”. Wyświetlenie i eksport CSV zapisują się w dzienniku. Od rozpoczęcia szkolenia organizator oznacza obecność (`app_training_mark_attendance()`).

## 5. Architektura informacji i lista ekranów

### 5.1 Mapa URL

| Ścieżka | Dostęp | Indeksowanie | Render |
|---|---|---|---|
| `/strefa-klienta` → przekierowanie na `/strefa-klienta/pulpit` albo `/logowanie` | – | noindex | dynamiczny |
| `/strefa-klienta/logowanie`, `/strefa-klienta/zaproszenie` | publiczny | noindex | dynamiczny (Turnstile, nonce), `Referrer-Policy: no-referrer` |
| `/strefa-klienta/pulpit` | członek salonu | noindex | dynamiczny, `no-store` |
| `/strefa-klienta/polisy` (aktualne i archiwum), `/polisy/[id]`, `/polisy/[id]/szkoda` | właściciel | noindex | jw. |
| `/strefa-klienta/dokumenty/[id]` | właściciel | noindex | trasa serwerowa → 303 na podpisany URL |
| `/strefa-klienta/dam-prace`, `/dam-prace/nowe`, `/dam-prace/[id]` | właściciel (pracownik: tylko lista ogłoszeń) | noindex | jw. |
| `/strefa-klienta/szkolenia` | członek salonu | noindex | jw. |
| `/strefa-klienta/zespol` | właściciel | noindex | jw. |
| `/strefa-klienta/organizator`, `/organizator/szkolenia`, `/organizator/szkolenia/nowe`, `/organizator/szkolenia/[id]`, `/organizator/szkolenia/[id]/uczestnicy`, `/organizator/profil` | członek organizatora | noindex | jw. |
| `/strefa-klienta/ustawienia` (TOTP, ostatnie logowania, zgody, wylogowanie ze wszystkich urządzeń) | zalogowany | noindex | jw. |
| `/dam-prace`, `/dam-prace/<slug>` | publiczny | **index** (ogłoszenie wygasłe → 410) | dane z cache bez sesji, rewalidacja po publikacji; kontakt i formularz – osobne wywołania dynamiczne |
| `/szkolenia`, `/szkolenia/<slug>` | publiczny | index (Założenie) | dane z cache bez sesji; stan zapisu użytkownika – osobny fragment dynamiczny |
| `POST /api/strefa/kontakt`, `/api/strefa/wiadomosc`, `/api/strefa/zgloszenie` | publiczny | – | route handlery („Pokaż kontakt”, formularz przekazujący, „Zgłoś nadużycie”) objęte regułą WAF i rate limit (02 §4.13) |
| `/panel/klienci`, `/panel/ogloszenia`, `/panel/organizatorzy`, `/panel/szkolenia`, `/panel/zgloszenia` | personel | Disallow | jak `/panel` (02 F6) |

### 5.2 Nawigacja strefy

Górny pasek (desktop) / szuflada (mobile): **Pulpit · Polisy · Dam pracę · Szkolenia · Zespół** + menu konta (nazwa salonu, przełącznik salonu lub profilu organizatora, Ustawienia, Wyloguj). Pracownik widzi: Pulpit · Dam pracę · Szkolenia. Organizator: **Pulpit organizatora · Moje szkolenia · Dodaj szkolenie · Profil**. W nagłówku strony publicznej: link „Strefa Klienta” (ikona `lux-bezpieczenstwo` – antyczny klucz) obok „Umów rozmowę”.

### 5.3 Ekrany do pokazania w makietach

| Plik makiety | Ekrany |
|---|---|
| `logowanie.html` | (1) logowanie – krok 1: e-mail + Turnstile (miejsce na widget) + informacja „Konto zakłada Aura Consulting po zawarciu polisy. Rejestracja nie jest potrzebna”; (2) krok 2: kod 6 cyfr (jedno pole `inputmode="numeric"`, `autocomplete="one-time-code"`), „Wyślij kod ponownie” z odliczaniem; (3) krok 3: kod TOTP; (4) przyjęcie zaproszenia: nazwa salonu (albo organizatora), adres e-mail, przycisk „Przyjmij zaproszenie”, pole „Kod zaproszenia” dla przeglądarek bez JavaScriptu; (5) pierwsze logowanie: regulamin + obowiązkowa konfiguracja TOTP dla właściciela i organizatora (kod QR, pole kodu); (6) stany: neutralny komunikat po wysłaniu kodu, błędny/wygasły kod, limit prób, wygasłe zaproszenie z kontaktem do doradcy |
| `panel.html` | (1) pulpit właściciela „Salon Przykładowy”: karta polisy OC (numer „BP/2026/000123 (przykład)”, ERGO Hestia, okres 1.01–31.12.2026, grupa taryfowa 2, suma 200 000 zł, ochrona prawna, składka roczna 882 zł = 790 zł + 92 zł), baner odnowienia („Ochrona kończy się 31 grudnia 2026 r.” + „Odnów z doradcą”), skróty do „Dam pracę” i „Szkolenia”; (2) „Archiwum”: przykładowa polisa wygasła (np. Tax Protect, „BP/2025/000045 (przykład)”, bez kwoty); (3) szczegóły polisy z listą dokumentów (Polisa, OWU, „Pobierz PDF”) i „Zgłoś szkodę”; (4) formularz zgłoszenia szkody bez pola opisu; (5) „Zespół”: lista osób z rolami, zaproszenie oczekujące, „Zaproś osobę”, coroczne „Potwierdź skład zespołu”; (6) widok pracownika: pulpit bez polis, z informacją „Polisy salonu widzi właściciel konta”; (7) „Ustawienia”: TOTP, ostatnie logowania, wyloguj wszędzie |
| `dam-prace.html` | (1) publiczna lista ogłoszeń z filtrami (zawód, województwo, rodzaj umowy), karta ogłoszenia z widełkami, krótka informacja „Dam pracę to tablica ogłoszeń salonów. Kontaktujesz się bezpośrednio z salonem”; (2) strona ogłoszenia z blokiem „Jak się skontaktować”: wariant „Pokaż kontakt” (e-mail lub telefon) i wariant formularza przekazującego wiadomość (imię i nazwisko, e-mail, telefon opcjonalnie, wiadomość, informacja o przekazaniu i braku przechowywania), „Zgłoś nadużycie”; (3) potwierdzenie na ekranie „Wiadomość została przekazana do salonu” (bez numeru, bez e-maila do kandydata); (4) w strefie: „Moje ogłoszenia” ze statusami (szkic, w moderacji, opublikowane do…, odrzucone z powodem, wygasłe, zamknięte); (5) formularz „Nowe ogłoszenie” z blokiem „Jak kandydat ma się skontaktować” (formularz – domyślnie, e-mail, telefon) i podpowiedzią o kontakcie rekrutacyjnym. **Bez** list kandydatów, aplikacji, statusów rekrutacji i „polecanych kandydatów” |
| `szkolenia.html` | (1) katalog z filtrami (forma, miesiąc), karta szkolenia (termin, forma, miasto, „Organizator przykładowy” ze znaczkiem weryfikacji, „Wolne miejsca: 6 z 20”, cena przy szkoleniu płatnym z dopiskiem „(przykład)”); (2) strona szkolenia z programem i przyciskiem „Zapisz się” / „Zaloguj się, aby się zapisać”; (3) krok informacyjny o przekazaniu danych organizatorowi; stan po zapisie i stan listy rezerwowej; (4) „Moje szkolenia” w strefie salonu: nadchodzące, lista rezerwowa, rezygnacja; (5) widok właściciela: zapisy zespołu; **(6) widok organizatora:** formularz „Dodaj szkolenie” (pola z 4.11 pkt 3, w tym cena i szczegóły dla zapisanych); (7) „Moje szkolenia jako organizator” ze statusami moderacji (szkic, w moderacji, opublikowane, odrzucone z powodem, odwołane) i akcjami; (8) lista uczestników szkolenia (imię i nazwisko, e-mail, status, oznaczanie obecności, „Pobierz CSV”, informacja o usunięciu danych 30 dni po szkoleniu) |

Dane demonstracyjne muszą być jawnie fikcyjne: „Salon Przykładowy”, „BP/2026/000123 (przykład)”, organizator „Organizator przykładowy”, tematy szkoleń i ceny z dopiskiem „(przykład)”, kandydatka „Kandydatka Przykładowa” tylko w polach formularza. Kwoty polis wyłącznie z taryfy (01 §3.1); Tax Protect bez kwoty (taryfa nie jest w audycie). Bez nazw realnych partnerów jako organizatorów szkoleń.

## 6. Wymagania funkcjonalne

Priorytety: **P0** – MVP danego etapu, **P1** – szybko po starcie, **P2** – później (architektura ma to umożliwić).

### 6.1 Konto, logowanie, zespół (etap Z1)

| ID | Wymaganie | P | Kryteria akceptacji |
|---|---|---|---|
| K1 | Konto salonu zakłada i aktywuje wyłącznie personel Aura, przy polisie dowolnego produktu (D-A) | P0 | Brak publicznej rejestracji (`enable_signup = false` w Auth, `shouldCreateUser: false` przy kodzie); aktywacja bez aktywnej opublikowanej polisy kończy się błędem |
| K2 | Zaproszenie e-mailem, ważne 7 dni, jednorazowe, bez tworzenia sesji | P0 | Token tylko w e-mailu, w części `#` adresu, w bazie hash SHA-256; ponowna wysyłka unieważnia poprzedni link; GET nie zmienia stanu; istniejący użytkownik musi się zalogować, nowy – wpisać kod z e-maila (4.2) |
| K3 | Logowanie kodem z e-maila z limitami aplikacji | P0 | Neutralny komunikat; Turnstile na wysłaniu i weryfikacji kodu; 5 kodów / adres / godzinę, 5 błędnych prób / kod, 10 / IP / godzinę (Założenie) – limiter z kluczem HMAC adresu, przed wywołaniem Supabase; kod ważny 10 min |
| K4 | TOTP obowiązkowy dla właściciela i organizatora, opcjonalny dla pracownika | P0 | `client_account_ids('owner')` i `organizer_ids()` zwracają pusty wynik dla sesji `aal1`; pracownik z włączonym TOTP – tak samo; kody zapasowe pokazane raz [do weryfikacji – wsparcie w Supabase] |
| K5 | Regulamin i klauzula przy pierwszym logowaniu | P0 | Wersja regulaminu i data zapisane; bez akceptacji brak dostępu do modułów |
| K6 | Zespół: zaproszenia, ponowienie, odbieranie dostępu | P0 | Właściciel nie może zaprosić właściciela, obniżyć roli właściciela ani odebrać dostępu ostatniemu właścicielowi; zmiany tylko przez funkcje `service_role` |
| K7 | Przełącznik salonu i profilu organizatora | P1 | Wybór w ciasteczku (bez danych wrażliwych), każde zapytanie i tak filtruje RLS |
| K8 | Ostatnie logowania, e-mail o nowym urządzeniu, „wyloguj wszędzie” | P1 | `signOut({ scope: 'global' })`; e-mail dla właściciela i organizatora |
| K9 | Klucze dostępu (passkeys) | P2 | Gdy Supabase Auth je obsłuży [do weryfikacji]; do tego czasu TOTP |
| K10 | Rola „manager” (ogłoszenia bez polis) | P2 | Rozszerzenie listy ról w `client_members` i `client_account_ids()` |
| K11 | Cykl życia konta bez odcięcia (D-B) | P0 | Coroczne potwierdzenie zespołu; automatyczne odebranie dostępu pracownikowi po 12 miesiącach bez logowania; po 24 miesiącach bez logowania ponowna weryfikacja przez personel (Założenie) |
| K12 | Zmiana adresu e-mail i hasło | P0 | Strefa nie oferuje zmiany adresu ani hasła; zmianę adresu robi personel w `/panel` z wpisem w dzienniku; logowanie hasłem odrzucane (8) |

### 6.2 Polisy, dokumenty, odnowienia, szkody (etap Z1)

| ID | Wymaganie | P | Kryteria akceptacji |
|---|---|---|---|
| P1 | Broker dodaje polisę dowolnego produktu w `/panel` | P0 | Dla OC składka przeliczana na serwerze z aktywnej wersji taryfy; niezgodność = odrzucenie zapisu; polisa niewidoczna dla klienta przed publikacją |
| P2 | Dokumenty PDF w prywatnym kubełku | P0 | Tylko `application/pdf`, ≤ 15 MB, sygnatura `%PDF-`, SHA-256; pobranie przez podpisany URL 60 s z `Content-Disposition: attachment` |
| P3 | Właściciel widzi tylko opublikowane polisy swojego salonu | P0 | Test RLS na dwóch salonach; pracownik – 0 wierszy |
| P4 | Przypomnienia o odnowieniu 60/30/14 dni | P0 | Najwyżej jedno przypomnienie na próg; e-mail bez załączników |
| P5 | „Odnów z doradcą” | P0 | Tworzy lead z kontekstem konta i polisy; brak nowej kwoty w strefie |
| P6 | Zgłoszenie szkody z karty polisy | P0 | Formularz bez wolnego tekstu; numer zgłoszenia i status widoczne w strefie |
| P7 | Notatki wewnętrzne brokera | P1 | Osobna tabela bez dostępu klienta |
| P8 | Jednokierunkowy przekaz polis z CRM „BEAUTY” | P2 | 7.4 M5 |
| P9 | Raty i terminy płatności | P2 | CRM ma `terminy_platnosci` (jsonb) – przeniesienie po decyzji |
| P10 | Archiwum polis (D-B) | P0 | Polisy wygasłe, odnowione i rozwiązane widoczne w zakładce „Archiwum”; konto pozostaje aktywne |

### 6.3 „Dam pracę” – tablica ogłoszeń (etap Z2)

| ID | Wymaganie | P | Kryteria akceptacji |
|---|---|---|---|
| J1 | Właściciel tworzy, wysyła do moderacji i zamyka ogłoszenie | P0 | Niedozwolone przejścia statusów blokuje baza; w trakcie moderacji treść i kontakt są zablokowane; edycja opublikowanego ogłoszenia wraca do moderacji; najwyżej 5 ogłoszeń w szkicu lub moderacji na salon (Założenie) |
| J2 | Moderacja przed publikacją, tylko treści | P0 | Lista kontrolna (11.2); moderator zatwierdza konkretną wersję treści (`content_version`); odrzucenie wymaga powodu widocznego dla salonu |
| J3 | Publiczna lista i strona ogłoszenia z `JobPosting` | P0 | Walidacja w Rich Results Test; wygasłe ogłoszenie → 410 i zniknięcie z sitemap w ciągu doby; kontakt poza JSON-LD |
| J4 | Blok kontaktu wybrany przez salon | P0 | Jeden z: formularz (domyślnie), e-mail, telefon; dane kontaktowe w osobnej tabeli bez dostępu `anon`; „Pokaż kontakt” za Turnstile i limitem na IP; usunięcie 30 dni po zakończeniu ogłoszenia |
| J5 | Obowiązkowe widełki wynagrodzenia | P0 | Formularz nie przechodzi bez `salary_min`/`salary_max` |
| J6 | Formularz przekazujący wiadomość do salonu | P0 | Turnstile, honeypot, limity (5 / IP / dobę, 50 / ogłoszenie / dobę – Założenie), Zod (≤ 1000 znaków, tekst zwykły, bez linków i załączników); stały szablon e-maila; treść usuwana z bazy po wysyłce; brak e-maila do kandydata (11.3) |
| J7 | „Zgłoś nadużycie” | P0 | Przy ogłoszeniu i w każdym e-mailu z formularza; bez danych zgłaszającego; kolejka w `/panel` |
| J8 | Brak funkcji rekrutacyjnych (D-C) | P0 | W bazie nie ma tabel aplikacji, kandydatów ani CV; test CI sprawdza ich brak (9.6) |
| J9 | Google Indexing API dla ogłoszeń | P2 | Po weryfikacji, że ruch z Google for Jobs to uzasadnia |

### 6.4 „Szkolenia” (etap Z2)

| ID | Wymaganie | P | Kryteria akceptacji |
|---|---|---|---|
| S1 | Szkolenia dodają zweryfikowani organizatorzy (firmy i salony) | P0 | Publikacja tylko przez moderację (`app_moderate_training()`); organizator nie może ustawić statusu `published` ani daty publikacji; zmiana treści, terminu, miejsca lub linku → ponowna moderacja |
| S2 | Zapis z konta salonu z limitem miejsc i listą rezerwową | P0 | Brak nadsprzedaży przy równoczesnych zapisach (blokada wiersza szkolenia); limit na salon (domyślnie 3 – Założenie) |
| S3 | Szczegóły (link online, adres) tylko dla zapisanych z aktywnym członkostwem i dla organizatora | P0 | Osobna tabela z RLS; link tylko z hostów z listy dozwolonych |
| S4 | Przypomnienie 24 h przed | P0 | Jedno na zapis |
| S5 | Obecność oznacza organizator (albo personel) | P1 | `attended` / `no_show`, dopiero od rozpoczęcia szkolenia |
| S6 | Zaświadczenia PDF | P2 | Generowane po `attended`; wymagają wzoru i decyzji, kto je wystawia |
| S7 | Szkolenia płatne bez płatności online | P0 | Cena brutto w ustrukturyzowanym polu, dopisek „fakturę wystawia organizator”; płatności online – P2 (regulamin, operator płatności, CSP) |
| S8 | Plik kalendarza `.ics` w e-mailu | P1 | Bez danych osobowych w pliku |
| S9 | Minimalne dane uczestników dla organizatora | P0 | Tylko imię i nazwisko, e-mail, status (+ nazwa salonu przy szkoleniu płatnym); bez `user_id`, `account_id` i telefonu; tylko po kroku informacyjnym; usunięcie 30 dni po szkoleniu; wgląd i eksport w dzienniku |
| S10 | Zmiana liczby miejsc i odwołanie szkolenia funkcjami | P0 | Liczba miejsc nie mniejsza niż liczba zapisanych; zwiększenie awansuje z listy rezerwowej; odwołanie powiadamia zapisanych |
| S11 | „Zgłoś nadużycie” przy szkoleniu i w e-mailach | P0 | Kolejka w `/panel`; personel może zawiesić organizatora |

### 6.5 Organizator szkoleń (etap Z2)

| ID | Wymaganie | P | Kryteria akceptacji |
|---|---|---|---|
| O1 | Profil organizatora zakłada personel po weryfikacji | P0 | Status `active` tylko z datą i autorem weryfikacji oraz wersją umowy organizatora (CHECK w bazie); profil zmienia personel (P1: samodzielna edycja opisu z ponowną moderacją) |
| O2 | Zaproszenia organizatora osobnym tokenem | P0 | `organizer_invitations` rozłączne z `client_invitations`; personel Aura nie może zostać członkiem organizatora |
| O3 | Znaczek weryfikacji | P0 | Treść: „Organizator zweryfikowany przez Aura Consulting (dane firmy)” – potwierdza tożsamość firmy, nie jakość szkoleń |
| O4 | Zawieszenie organizatora | P0 | Status `suspended` → `organizer_ids()` zwraca pusty wynik, nowe publikacje zablokowane |

### 6.6 Panel personelu (`/panel`) – dodatki

„Klienci” (konta, polisy, dokumenty, aktywacja, zaproszenia, zawieszenie, zmiana adresu e-mail), „Ogłoszenia” (kolejka moderacji z wersją treści, sprawdzenie NIP dla kont bez aktywnej polisy), „Organizatorzy” (weryfikacja, profile, zaproszenia, zawieszenie), „Szkolenia” (kolejka moderacji, odwołania), „Zgłoszenia” (nadużycia ogłoszeń, wiadomości z formularza, szkoleń i organizatorów). Te same zasady co w 02 F6: Cloudflare Access, MFA egzekwowane w RLS (`aal2`), akcje zapisu przez server actions.

## 7. Model danych

### 7.1 Tabele (nowy projekt portalu)

Pełny DDL z RLS: `snippets/strefa-klienta.sql`.

| Tabela | Klucz i najważniejsze kolumny | Relacje | PII |
|---|---|---|---|
| `client_accounts` | `id`, `display_name`, `nip`, `status` (pending/active/suspended/closed), `team_confirmed_at`, `crm_ref` (tylko personel), `activated_at/by` | → `leads` (lead źródłowy) | dane firmy |
| `client_members` | PK (`account_id`, `user_id`), `role` (owner/employee), `status`, `terms_version`, `last_seen_at` | → `client_accounts`, `auth.users` | pośrednio |
| `client_invitations` | `id`, `email_normalized`, `role`, `token_hash`, `expires_at`, `invited_by_kind` | → `client_accounts` | e-mail (czyszczony po 30 dniach) |
| `client_policies` | `id`, `product` (`lead_product` – wszystkie produkty, D-A), `insurer`, `policy_number`, `valid_from/to`, `premium_amount`, `oc_*` (parametry taryfy, `oc_individual_quote` dla gr. 4 i zespołu 9+), `pricing_version_id`, `published_at`, `crm_ref` (tylko personel) | → `client_accounts`, `pricing_versions` | nie |
| `client_policy_notes` | notatki brokera | → `client_policies` | możliwe – tylko personel |
| `client_policy_documents` | `storage_path`, `kind`, `size_bytes`, `sha256`, `published_at` | → `client_policies`, `client_accounts` | treść PDF |
| `client_policy_reminders` | PK (`policy_id`, `kind`) | → `client_policies`, `outbox_emails` | nie |
| `job_offers` | `slug` (nadaje baza), `status`, `content_version`, treść, widełki, `employer_name` (migawka), `published_at`, `expires_at`, `moderation_note` | → `client_accounts` | nie (bez danych kontaktowych) |
| `job_offer_contacts` | PK `offer_id`, `method` (formularz/email/telefon), `email`, `phone` | → `job_offers`, `client_accounts` | możliwe (kontakt salonu; FORCE RLS, bez `anon`, usuwany 30 dni po ogłoszeniu) |
| `job_offer_relay_log` | `id`, `offer_id`, `outbox_id`, `created_at` | → `job_offers`, `outbox_emails` | **nie** (bez nadawcy, treści i IP; 30 dni) |
| `training_organizers` | `id`, `kind` (firma/salon), `display_name`, `legal_name`, `nip`, `status`, `verified_at/by`, `terms_version` | → `client_accounts` (salon-organizator) | dane firmy |
| `organizer_members` | PK (`organizer_id`, `user_id`), `role` (owner/member), `status` | → `training_organizers`, `auth.users` | pośrednio |
| `organizer_invitations` | jak `client_invitations` | → `training_organizers` | e-mail |
| `trainings` | `organizer_id` (niezmienne), `slug`, `status` (draft/pending_review/published/rejected/cancelled/completed/removed), `content_version`, termin, `format`, `capacity`, `seats_registered`, `per_account_limit`, `audience`, `price_kind`, `price_gross_pln` | → `training_organizers` | nie |
| `training_private_details` | `online_join_url` (hosty z listy dozwolonych), `venue_address`, `instructions` | → `trainings` | nie |
| `training_registrations` | `status` (registered/waitlisted/cancelled/attended/no_show) | → `trainings`, `client_accounts`, `auth.users` | pośrednio |
| `training_participant_contacts` | PK `registration_id`, `organizer_id`, `status`, `participant_name`, `participant_email`, `salon_name` (tylko płatne), `notice_version` | → `training_registrations`, `trainings`, `training_organizers` | **tak** (FORCE RLS; 30 dni po szkoleniu) |
| `abuse_reports` | `target`, `reason`, odwołanie do ogłoszenia/wiadomości/szkolenia/organizatora, `handled_at` | → jw. | nie |
| `client_audit_log` | `account_id`, `organizer_id`, `actor`, `action`, `entity`, `payload` (bez PII, ≤ 2 KB) | → `client_accounts`, `training_organizers` | nie |
| zmiany istniejących | `claims_reports` + `account_id`, `policy_id`, `reported_by`; `outbox_emails` + `account_id`; wyzwalacz rozłączności na `admin_users` | | |

```text
auth.users ─┬─< client_members >── client_accounts ──< client_policies ──< client_policy_documents
            │                         │   │                   └──< client_policy_reminders
            │                         │   ├──< client_invitations
            │                         │   ├──< job_offers ──┬── job_offer_contacts
            │                         │   │                 └──< job_offer_relay_log
            │                         │   └──< training_registrations >── trainings ── training_private_details
            │                         │              └── training_participant_contacts      │
            ├─< organizer_members >── training_organizers ──< trainings ───────────────────┘
            │                          └──< organizer_invitations
            └─< admin_users (personel; rozłączne z client_members i organizer_members)
abuse_reports → job_offers | job_offer_relay_log | trainings | training_organizers
client_audit_log → client_accounts | training_organizers      client_policies >── pricing_versions (taryfa OC)
```

### 7.2 Co jest w projekcie „BEAUTY” (stan z 11.11.2026, tylko struktura)

| Moduł | Tabele i liczba wierszy | Cechy istotne dla decyzji |
|---|---|---|
| Katalog salonów (multi-tenant) | `salons` (1), `salon_memberships` (1), `services`, `staff`, `appointments`, `plans`, `subscriptions`… | Inny produkt (katalog i rezerwacje na `app.`); `salon_memberships.role` + funkcja `can_manage_salon()` – SECURITY DEFINER **wykonywalna przez `anon`**; polityka SELECT na `salon_memberships` dla roli `public` |
| CRM | `crm_companies` (1468), `crm_policies` (37), `crm_history`, `crm_reminders`, `crm_audit_log` | System pracy brokera: `crm_policies` ma `company_id integer`, `rodzaj`, `nr_polisy`, `ubezpieczyciel`, `suma_ubezpieczenia text`, `skladka`, `data_od/do`, `przypomnienie`, `ochrona_prawna`, `terminy_platnosci jsonb`; dostęp przez `is_crm_user()`/`is_crm_admin()` (bez EXECUTE dla `anon`) |
| Ogłoszenia o pracę | `job_listings` (1), `job_applications` (0) | Ogłoszenie należy do użytkownika (`owner_id`), nie do salonu; pola płatności (`price_pln`, `payment_status`, `paid_at`); aplikacja wymaga konta (`applicant_user_id`, polityka INSERT tylko `authenticated`); **`anon` ma SELECT na kolumnach `phone`, `email`, `owner_id` aktywnych ogłoszeń** |
| Szkolenia | `trainings` (6), `training_enrollments` (0) | Model sprzedażowy (`price_pln`, `payment_method`, `payment_status`, `amount_pln`), licznik `seats_taken`; publiczny odczyt `status='active' and source='katalog'`; administracja przez `is_katalog_admin()` (SECURITY DEFINER wykonywalna przez `anon`) |
| Storage | kubełki `dokumenty` (**publiczny**, 10 MB, ograniczone typy), `salon-media` (publiczny), `seo-assets` (publiczny), `email-assets` | Żaden nie nadaje się na polisy klientów |

### 7.3 Warianty i rekomendacja

| Wariant | Opis | Za | Przeciw |
|---|---|---|---|
| A. Reuse – strefa na „BEAUTY” | Strefa korzysta wprost z `salons`, `job_listings`, `trainings`, `crm_policies` | Brak migracji | Sprzeczne z D2; publiczny portal na bazie z CRM (1468 firm) i danymi wielu modułów – ten sam problem, który audyt wskazał w „aurabroker”; dziedziczy błędy Security Advisor (widoki SECURITY DEFINER, funkcje DEFINER dla `anon`, `tax_wnioski` bez polityk); model ogłoszeń (aplikacje z kontem kandydata) sprzeczny z D-C, model szkoleń bez organizatorów |
| **B. Nowe tabele w projekcie portalu + migracja danych modułów + integracja z CRM** | Moduły „Dam pracę” i „Szkolenia” powstają od nowa w projekcie portalu; 6 szkoleń i 1 ogłoszenie przenosimy jednorazowo (po przeglądzie treści przez zleceniodawcę); CRM zostaje systemem źródłowym polis, portal trzyma projekcję polis klientów | Zgodne z D2 i D-C; izolacja skutków incydentu; model dopasowany do wymagań; koszt migracji pomijalny przy obecnych wolumenach | Dwa miejsca z danymi polis (CRM i portal) – wymaga jasnej reguły „źródłem jest CRM” i późniejszej synchronizacji |
| C. Strefa jako schemat w „BEAUTY” | Osobny schemat `strefa` w „BEAUTY” | Blisko CRM | Ten sam projekt, te same klucze, `auth.users` i ustawienia Auth wspólne z katalogiem salonów i CRM; odrzucone już w D2 |

**Rekomendacja: wariant B.** Uzasadnienie w kolejności priorytetów klienta: (1) bezpieczeństwo – strefa ma dokumenty polis i dane uczestników szkoleń, więc musi mieć mały, sprawdzalny zestaw uprawnień, a „BEAUTY” ma dziś 17 funkcji SECURITY DEFINER dostępnych dla `anon` (01 §5.2); (2) stabilność – zmiany w katalogu salonów lub CRM nie mogą psuć strefy; (3) koszty migracji są znikome (1 ogłoszenie, 0 aplikacji, 6 szkoleń, 0 zapisów).

### 7.4 Ścieżka migracji i integracji

| Krok | Etap | Co | Jak |
|---|---|---|---|
| M1 | Z1 | Konta i polisy wprowadzane ręcznie w `/panel` | `crm_ref` w `client_accounts` i `client_policies` przechowuje identyfikatory z CRM, żeby później połączyć rekordy |
| M2 | Z1 | Import „startowy” klientów z aktywnymi polisami (wszystkie produkty, D-A) | Jednorazowy eksport z CRM wykonany przez personel (CSV z polami: firma, NIP, numer polisy, okres, produkt, składka, e-mail kontaktowy), import skryptem z walidacją taryfy OC i podpisem w dzienniku `system:import:<partia>` – **bez** dostępu portalu do bazy „BEAUTY”; pliki CSV usuwane po imporcie |
| M3 | Z2 | Szkolenia i ogłoszenie z „BEAUTY” | Zleceniodawca przegląda 6 szkoleń i 1 ogłoszenie. Szkolenia przenosimy tylko jako treść katalogową (bez danych płatności) i tylko pod profil organizatora, który przeszedł weryfikację (12.1). Ogłoszenie – tylko jeśli jego salon ma konto, jako szkic do przejrzenia przez właściciela i moderacji |
| M4 | Z2 | Wygaszenie starych modułów | Po decyzji zleceniodawcy (Q6): `job_listings`/`trainings` w „BEAUTY” tylko do odczytu albo usunięte; do tego czasu odebrać `anon` SELECT na `job_listings.phone/email/owner_id` i EXECUTE na funkcjach DEFINER (szybka wygrana niezależna od strefy) |
| M5 | Z3 | Jednokierunkowy przekaz CRM → portal | Webhook bazy w „BEAUTY” (trigger na `crm_policies` → `pg_net`/Database Webhook) na `POST /api/internal/crm/policies`. Podpis HMAC z `timestamp + nonce + body`, odrzucanie żądań spoza ±5 min, nonce pamiętane 10 min, limit częstotliwości endpointu; sekret w Supabase Vault w „BEAUTY” (nie w kodzie wyzwalacza). Przekaz może tylko tworzyć lub zmieniać **nieopublikowane** polisy przy istniejącym dopasowaniu `crm_ref` – nigdy kont ani publikacji (publikuje personel w `/panel`); wpisy w dzienniku jako `system:crm-sync`; konflikt = kolejka przeglądu w `/panel`. Portal nie przechowuje kluczy do „BEAUTY”, a „BEAUTY” nie dostaje kluczy portalu |
| M6 | później | Powiązanie z katalogiem salonów (`app.`) | Opcjonalne pole `catalog_salon_ref`, link „Profil w katalogu” – bez wspólnej bazy |

## 8. Uwierzytelnianie

| Element | Rozwiązanie |
|---|---|
| Dostawca | Supabase Auth w nowym projekcie portalu (ten sam co dla `/panel`) |
| Rejestracja | **wyłączona** (`enable_signup = false`); użytkownicy powstają tylko przy przyjęciu zaproszenia, na serwerze, kluczem `sb_secret_…` |
| Metoda | kod jednorazowy z e-maila (`signInWithOtp`, `shouldCreateUser: false`) + link PKCE w tym samym e-mailu prowadzący na stronę z przyciskiem POST |
| Hasła i zmiana adresu | logowanie hasłem odrzucane hookiem *Password Verification Attempt* albo wyłączonym dostawcą haseł, jeśli Supabase pozwala na tryb tylko OTP [do weryfikacji]; włączona bezpieczna zmiana adresu e-mail (potwierdzenie i powiadomienie starego adresu); strefa nie udostępnia zmiany adresu ani hasła – zmianę adresu robi personel w `/panel` z wpisem w dzienniku. Klucz publishable **nie jest granicą bezpieczeństwa** (każda sesja może wywołać API Auth własnym tokenem) – dlatego te ustawienia sprawdza test konfiguracji w CI lub runbook (`enable_signup = false`, hasła odrzucane, bezpieczna zmiana adresu włączona) |
| Drugi składnik | TOTP obowiązkowy dla właścicieli i organizatorów (rekomendacja, Q3), opcjonalny dla pracowników; egzekwowany w bazie (`client_account_ids()`, `organizer_ids()` wymagają `aal2`); dla personelu `aal2` obowiązkowe jak w 02. Klucze dostępu – gdy Supabase Auth je obsłuży [do weryfikacji] |
| Sesja | `@supabase/ssr` wyłącznie po stronie serwera; ciasteczka z prefiksem **`__Host-`** (`cookieOptions.name`; prefiks wymusza `Secure`, `Path=/` i brak `Domain`, więc subdomeny `app.`, `crm.`, `portal.` itd. nie mogą podrzucić sesji), `HttpOnly; Secure; SameSite=Lax` (domyślnie biblioteka nie ustawia `HttpOnly`, bo zakłada klienta w przeglądarce, którego tu nie ma); weryfikator PKCE w osobnym ciasteczku `__Host-`. Kontrola `Origin` server actions w Next.js ścisła – `serverActions.allowedOrigins` nigdy nie obejmuje subdomen |
| Czas życia | token dostępu 1 h, rotacja refresh tokenów z wykrywaniem ponownego użycia, limit sesji 30 dni i wylogowanie po 7 dniach bezczynności (ustawienia Auth w planie Pro) [Założenie; do weryfikacji dostępności opcji] |
| Weryfikacja na serwerze | decyzje autoryzacyjne tylko po `auth.getUser()` albo `auth.getClaims()` (weryfikacja podpisu JWT asymetrycznymi kluczami – bez zapytania sieciowego przy każdym żądaniu [do weryfikacji w PoC]); **nigdy** `getSession()` (nie weryfikuje tokenu); **nigdy** `user_metadata` jako źródło uprawnień (użytkownik może je zmienić) |
| E-maile Auth | własny SMTP przez Resend z domeny `send.`, **osobny strumień** dla kodów logowania (oddzielony od leadów i e-maili transakcyjnych); szablony po polsku, w stylu marki, bez obrazów zewnętrznych; limit wysyłek Auth podniesiony w planie Pro, alert przy 50 % limitu godzinowego |
| Ochrona formularzy logowania | limity aplikacji z 4.3 (przed wywołaniem Supabase, bo Supabase widzi adresy IP Workera); Turnstile na wysłaniu i weryfikacji kodu (Supabase Auth obsługuje CAPTCHA natywnie [do weryfikacji wariantu Turnstile]); reguła WAF `Origin` i reguła rate limit Cloudflare rozszerzone na `/strefa-klienta/logowanie*`, `/strefa-klienta/zaproszenie*` i `/api/strefa/*` (02 §4.13); limity Auth (`rate_limit_email_sent`, `rate_limit_otp`) jako ostatnia linia; neutralne komunikaty. Jak przekazać Supabase prawdziwy adres IP klienta przy wywołaniu z serwera – [do weryfikacji] |
| Wylogowanie | `POST /strefa-klienta/wyloguj` (nie GET), opcja „wyloguj wszędzie” |
| Konta personelu | rozłączne z kontami salonów i organizatorów (9.3); `/panel` dodatkowo za Cloudflare Access |

## 9. Autoryzacja

### 9.1 Członkostwo i RLS

- Źródłem uprawnień są tabele `client_members` (salony) i `organizer_members` (organizatorzy) – rola i status – oraz status konta albo profilu organizatora (`active`, a u organizatora także `verified_at`).
- Dwie funkcje pomocnicze: `client_account_ids(variadic roles)` zwraca salony wywołującego dla wskazanych ról, `organizer_ids()` – profile organizatora wywołującego. Polityki mają postać `account_id in (select public.client_account_ids('owner'))` – podzapytanie jest wyliczane raz na zapytanie (initPlan), więc nie ma kosztu per wiersz. **Żadna polityka nie łączy obu funkcji**: salon będący organizatorem działa w dwóch rozłącznych rolach.
- Kolumny, których klient nie powinien widzieć, są wyłączone **uprawnieniami kolumnowymi** (np. `client_accounts.crm_ref`, `source_lead_id`, `*_by`; `client_policies.crm_ref`; `job_offers.moderation_note`; `client_invitations.token_hash`; `training_organizers.account_id`, `verified_by`), a nie widokami. Uprawnienia kolumnowe dotyczą całej roli `authenticated` – salonów, organizatorów i personelu – więc personel czyta kolumny wewnętrzne w `/panel` serwerowo (klucz serwisowy po sprawdzeniu `app_is_staff` w sesji `aal2`), a notatki brokera są w osobnej tabeli.
- Serwer używa w strefie **klienta Supabase z sesją użytkownika** (klucz publishable tylko po stronie serwera + token użytkownika), więc każdy odczyt przechodzi przez RLS. Klucz `sb_secret_…` jest używany wyłącznie do: funkcji `app_*`, wgrywania plików, wysyłki outboxu, odczytu kontaktu po „Pokaż kontakt” i zadań Cron.

### 9.2 Zapisy

| Rodzaj zapisu | Droga | Dlaczego |
|---|---|---|
| Ogłoszenia właściciela (szkic, edycja, wysłanie do moderacji, zamknięcie) i blok kontaktu | RLS + guardy `job_offers_owner_guard` i `job_offer_contacts_guard`: slug nadawany w bazie, dozwolone przejścia statusów, blokada zmian w trakcie moderacji, ponowna moderacja po edycji, `content_version`, limit 5 ogłoszeń w szkicu lub moderacji, migawka nazwy salonu | Prosty zapis w obrębie własnego salonu |
| Szkolenia organizatora (szkic, edycja, wysłanie do moderacji) i szczegóły dla zapisanych | RLS z `organizer_ids()` + guardy `trainings_guard` i `training_private_details_guard`: `organizer_id` niezmienne, slug w bazie, brak grantu na `published_at`, `capacity` (po utworzeniu), `seats_registered` i kolumny moderacji, ponowna moderacja po każdej zmianie, limit 10 szkoleń w szkicu lub moderacji (Założenie) | Organizator zmienia tylko własne szkolenia i nie może ominąć moderacji |
| Polisy, konta, profile organizatorów (personel) | RLS z `app_is_staff('admin','agent')` + wyzwalacz audytu | Zgodnie z wzorcem panelu (02 §3.2) |
| Zaproszenia, aktywacja, przyjęcie zaproszenia, odebranie dostępu, regulamin, potwierdzenie zespołu (salony i organizatorzy) | funkcje `app_*` tylko dla `service_role`; tabele członkostw i zaproszeń z wyzwalaczem `backend_only_guard` | Niezmienniki (ostatni właściciel, brak obniżenia roli, limity zespołu, rozdział personel/klient, zgodność adresu e-mail) |
| Formularz przekazujący wiadomość do salonu | `app_relay_job_message()` (`service_role`) | Kandydat nie ma sesji; limit na ogłoszenie w tej samej transakcji co wpis do outboxu |
| Zapis i rezygnacja ze szkolenia, liczba miejsc, odwołanie, obecność | `app_training_register()` / `app_training_cancel()` / `app_training_set_capacity()` / `app_training_cancel_event()` / `app_training_mark_attendance()` (`service_role`) | Limit miejsc liczony ponad granicą salonów (RLS ukrywa cudze zapisy) – blokada wiersza szkolenia `FOR UPDATE`; migawka danych dla organizatora |
| Moderacja ogłoszeń i szkoleń | `app_moderate_job_offer()` / `app_moderate_training()` (`service_role`) z oczekiwaną wersją treści; serwer sprawdza też `app_is_staff` w sesji `aal2` | Kolumny moderacji bez grantu dla `authenticated`; brak podmiany treści w trakcie przeglądu |

Funkcje `app_*` przyjmują `p_actor` – identyfikator z **zweryfikowanego** tokenu – i same sprawdzają uprawnienia aktora (obrona w głąb, choć wywołuje je tylko serwer); dotyczy to także rotacji tokenu zaproszenia. Wymóg `aal2` dla personelu, właścicieli i organizatorów sprawdza serwer przed wywołaniem, bo funkcja wywołana kluczem serwisowym nie widzi JWT użytkownika.

### 9.3 Personel Aura i rozdział ról

Polityki personelu używają istniejącego `app_is_staff()` (MFA `aal2`). Personel czyta konta, polisy, dokumenty, ogłoszenia z kontaktem (moderacja), profile organizatorów, szkolenia i zapisy; **nie ma polityki na `training_participant_contacts`** (dane uczestników widzi tylko organizator danego szkolenia – minimalizacja; obsługa nadużyć kluczem serwisowym z wpisem w dzienniku). Wiadomości z formularza „Dam pracę” nie są przechowywane, więc nikt ich w platformie nie czyta. Rozdział ról działa w obie strony: konto z wpisem w `admin_users` nie przyjmie zaproszenia do salonu ani organizatora, a wyzwalacz `admin_users_disjoint_guard` nie pozwoli dodać do personelu osoby z aktywnym członkostwem w salonie lub u organizatora. Podgląd „oczami klienta” (impersonacja) – świadomie poza zakresem.

### 9.4 Pułapki SECURITY DEFINER z audytu i jak ich unikamy

| Pułapka (stan w „BEAUTY”/„aurabroker”) | W strefie |
|---|---|
| Funkcje DEFINER wykonywalne przez `anon` (`can_manage_salon`, `is_katalog_admin`, `is_platform_admin`, `katalog_set_admin`, `katalog_admin_users`) | Funkcje DEFINER wywoływalne przez API to tylko `client_account_ids()` i `organizer_ids()` – wyłącznie `authenticated`, bez parametru użytkownika (odpowiadają tylko o wywołującym), zwracają tylko identyfikatory. Pozostałe DEFINER: wyzwalacz audytu (nie da się go wywołać przez RPC) i `app_purge_audit_log()` (tylko `service_role`, jedyna droga usuwania wpisów dziennika) |
| Mutowalny `search_path` (15 funkcji w „aurabroker”) | Każda funkcja w `strefa-klienta.sql` ma `set search_path = ''` i pełne nazwy obiektów. **Uwaga do `rls-policies.sql`:** `app_is_staff()` ma tam `set search_path = public` i niekwalifikowane `admin_users` – do wyrównania w 02 (`search_path = ''`, `public.admin_users`) |
| Widoki SECURITY DEFINER (3 × ERROR) | Brak widoków; uprawnienia kolumnowe |
| Polityki dla roli `public` (np. `salon_memberships`) | Polityki zawsze z jawną rolą (`to anon` / `to authenticated`), polityki `anon` nie wywołują funkcji personelu |
| Domyślny `EXECUTE` dla `PUBLIC` | Jawne `REVOKE … FROM public, anon, authenticated` dla każdej funkcji. **Uwaga do `schema.sql`:** `ALTER DEFAULT PRIVILEGES … IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM public` nie odbiera globalnego domyślnego prawa `PUBLIC` (domyślne uprawnienia per schemat mogą tylko dodawać); w teście lokalnym `admin_users_guard` z `rls-policies.sql` pozostał wykonywalny przez `anon`. Poprawka: dodatkowe `alter default privileges for role postgres revoke execute on functions from public;` **bez** `IN SCHEMA` (do naniesienia w 02/`schema.sql`) |
| Uprawnienia oparte o metadane użytkownika | Wyłącznie tabele `client_members`, `organizer_members`, `admin_users` |

### 9.5 Kolejność w `rls-policies.sql`

W obecnym `rls-policies.sql` polityki leadów używają `app_is_staff()` przed jej definicją, więc plik uruchomiony od góry kończy się błędem. `strefa-klienta.sql` zakłada, że funkcja już istnieje; w migracjach `app_is_staff` musi trafić przed polityki (do naniesienia w 02).

### 9.6 Testy uprawnień w CI

Rozszerzenie `packages/db/tests/privileges.test.sql` (fixture: dwa salony, właściciel A, pracownik A, właściciel B z wygasłą polisą, dwóch organizatorów, salon A jako organizator, personel, anon):

1. Żadna funkcja w `public` nie ma `EXECUTE` dla `anon` ani `PUBLIC`; dla `authenticated` – tylko `app_is_staff`, `client_account_ids` i `organizer_ids`.
2. Każda tabela z RLS ma politykę albo jest na liście `service_role_only` (`client_policy_reminders`, `job_offer_relay_log`).
3. Właściciel B nie widzi żadnego wiersza salonu A ani kontaktu w jego ogłoszeniach i nie zapisze kontaktu do cudzego ogłoszenia; organizator A nie widzi żadnego wiersza organizatora B, 0 wierszy `client_*`, 0 szkiców `job_offers`, 0 wierszy `training_registrations`.
4. Pracownik widzi 0 polis, 0 dokumentów, 0 kontaktów, 0 obiektów Storage; widzi ogłoszenia swojego salonu.
5. `anon`: tylko opublikowane, nieprzeterminowane ogłoszenia i tylko kolumny publiczne (`select account_id` → `permission denied`); `job_offer_contacts` → `permission denied`; tylko aktywni, zweryfikowani organizatorzy i ich kolumny publiczne.
6. Właściciel z sesją `aal1` – 0 wierszy; z `aal2` – komplet. Organizator z `aal1` – 0 szkiców.
7. Właściciel: `update published_at` → `permission denied`; własny slug → `permission denied`; zmiana treści albo kontaktu w trakcie moderacji → wyjątek; moderacja z nieaktualną wersją → wyjątek; szóste ogłoszenie w szkicu → wyjątek. Organizator: `insert … status 'published'` → wyjątek; `update capacity` i `published_at` → `permission denied`; zmiana opublikowanego szkolenia lub linku → `pending_review`; link spoza listy hostów i adres URL w opisie → naruszenie CHECK.
8. Funkcje: ponowne użycie zaproszenia, token salonu użyty jako zaproszenie organizatora, zaproszenie właściciela przez właściciela, obniżenie roli właściciela, rotacja cudzego zaproszenia, przyjęcie zaproszenia z innego adresu, personel jako organizator, właściciel salonu dopisany do `admin_users` – wyjątki; zapis na szkolenie z 1 miejscem przez dwie osoby → `registered` + `waitlisted`, organizator widzi tylko osobę zapisaną; zwiększenie limitu awansuje osobę z listy rezerwowej; zmniejszenie poniżej liczby zapisanych → wyjątek; publikacja ogłoszenia konta bez aktywnej polisy bez potwierdzenia NIP → wyjątek.
9. `client_audit_log`: UPDATE → wyjątek; TRUNCATE → wyjątek; DELETE i TRUNCATE jako `service_role` → `permission denied`.
10. Formularz „Dam pracę”: po wysyłce `outbox_emails.payload = '{}'`; `job_offer_relay_log` nie ma kolumn z danymi osobowymi; tabel `job_applications` i podobnych nie ma (D-C).
11. Cache (test HTTP, nie SQL): strona publiczna pobrana jako zalogowany użytkownik A, a potem anonimowo – druga odpowiedź bez znaczników per użytkownik i bez `Set-Cookie` (16).

Scenariusze 2–10 przeszły 11.11.2026 na lokalnym Postgresie 16 z zaślepkami schematów `auth` i `storage` (`schema.sql` → `rls-policies.sql` → `strefa-klienta.sql` w wersji 1.1). Scenariusz 1 przeszedł dla wszystkich funkcji z `strefa-klienta.sql`; poza nim zostaje znany wyjątek `admin_users_guard` z `rls-policies.sql` (9.4).

## 10. Pliki (Supabase Storage)

### 10.1 Dokumenty polis

- Kubełek **`client-documents`**: prywatny, limit 15 MB, tylko `application/pdf`; ścieżka `{account_id}/{policy_id}/{uuid}.pdf` (nazwa pliku z serwera, nigdy od użytkownika); zgodność ścieżki z salonem wymusza `check` w `client_policy_documents`.
- Wgrywa wyłącznie serwer (`service_role`) po: sprawdzeniu sesji personelu (`aal2`), rozmiaru, sygnatury `%PDF-`, typu, policzeniu SHA-256. Brak polityk INSERT/UPDATE/DELETE dla `authenticated`.
- Odczyt: polityka na `storage.objects` dopuszcza właściciela tylko dla opublikowanych dokumentów jego salonu – dlatego podpisany URL generujemy **sesją użytkownika** (RLS działa także przy podpisywaniu), bez klucza serwisowego.
- Podpisany URL ważny 60 s, parametr `download` (wymusza `Content-Disposition: attachment`), `Referrer-Policy` bez zmian (02 §4.2).
- Istniejący publiczny kubełek `dokumenty` w „BEAUTY” – wyłącznie do publicznych OWU, nigdy do polis klientów.
- Usuwanie: dokumenty polis są częścią dokumentacji dystrybucji; okres przechowywania do ustalenia z IOD (Q5).

### 10.2 Pliki od osób z zewnątrz

„Dam pracę” **nie przyjmuje plików** – ani CV, ani załączników do wiadomości (D-C). Organizatorzy w MVP nie wgrywają plików; później tylko obrazy rastrowe przekodowane na serwerze (bez SVG), a materiały PDF wyłącznie po skanowaniu antywirusowym – do tego czasu link do strony organizatora. Dokumenty polis pochodzą od personelu (zaufane źródło: ubezpieczyciel, broker) – w MVP wystarcza walidacja typu i sygnatury oraz hash.

## 11. „Dam pracę” – tablica ogłoszeń (D-C)

### 11.1 Charakter tablicy

„Dam pracę” jest tablicą ogłoszeń salonów. Salon sam publikuje ogłoszenie i sam wybiera osobę do pracy; kandydat sam czyta ogłoszenia i sam kontaktuje się z salonem.

| Platforma robi | Platforma nie robi (i nie wolno tego dodać bez nowej decyzji zleceniodawcy) |
|---|---|
| hostuje ogłoszenia i blok kontaktu wybrany przez salon | nie prowadzi kont, profili ani bazy kandydatów i CV |
| moderuje treść ogłoszenia (legalność, jakość, zgodność z regulaminem) | nie przyjmuje i nie przechowuje aplikacji, nie prowadzi statusów rekrutacji |
| przekazuje wiadomość z formularza e-mailem do salonu i usuwa ją po wysyłce | nie wyszukuje, nie poleca, nie ocenia, nie sortuje i nie dopasowuje kandydatów (także automatycznie lub z użyciem AI) |
| przyjmuje zgłoszenia nadużyć | nie kontaktuje się z kandydatami i nie świadczy usług rekrutacyjnych |

Tekst na stronie `/dam-prace` i w regulaminie „Dam pracę”: „Dam pracę to tablica ogłoszeń salonów. Aura Consulting i BeautyPolisa nie rekomendują, nie wyszukują, nie dobierają ani nie kontaktują się z kandydatami; moderujemy wyłącznie treść ogłoszeń”.

### 11.2 Moderacja

- Każde ogłoszenie przechodzi moderację przed publikacją i po każdej zmianie treści lub kontaktu – Założenie. Moderator widzi wersję treści (`content_version`) i zatwierdza dokładnie ją; zmiana w trakcie przeglądu jest niemożliwa (blokada w bazie), a nieaktualna wersja w decyzji kończy się błędem. Po 3 zaakceptowanych ogłoszeniach salon może dostać publikację natychmiastową z kontrolą następczą (P2).
- Lista kontrolna moderatora (w `/panel`): tytuł neutralny płciowo albo z oboma formami („Kosmetolog / kosmetolożka”); brak wymagań dyskryminujących (wiek, płeć, wygląd, stan cywilny – art. 18³ᵃ KP); widełki realne; opis dotyczy pracy w salonie; brak danych osobowych osób trzecich; brak linków, numerów telefonów, adresów e-mail, numerów kont i próśb o wpłaty w treści (kontakt wyłącznie w bloku kontaktu); kontakt należy do salonu (domena, nazwa); zgodność stanowiska z deklarowanym zawodem.
- **Konto bez aktywnej polisy (D-B):** konto pozostaje, ale każde ogłoszenie przechodzi ostrzejszą moderację – personel sprawdza, czy NIP salonu jest nadal aktywny (CEIDG/KRS), i potwierdza to w decyzji (`p_nip_confirmed`); bez potwierdzenia baza nie opublikuje ogłoszenia.
- Odrzucenie zawsze z powodem dla salonu; usunięcie (`removed`) po zgłoszeniu nadużycia.

### 11.3 Kontakt z salonem i formularz przekazujący

- Dane kontaktowe są w `job_offer_contacts` bez grantu dla `anon`. Serwer pokazuje adres lub numer tylko na stronie pojedynczego ogłoszenia, po „Pokaż kontakt” (Turnstile, limit na IP), nigdy w liście, JSON-LD, sitemap ani `llms.txt`. Kontakt jest usuwany 30 dni po zamknięciu lub wygaśnięciu ogłoszenia.
- **Formularz przekazujący (domyślny):** Turnstile, honeypot, binding Workers Rate Limiting (5 wiadomości / IP / dobę – skrót IP tylko w limiterze, nie w bazie, zgodnie z 02 D16), 50 wiadomości / ogłoszenie / dobę w bazie (Założenie), Zod: wiadomość ≤ 1000 znaków, tekst zwykły, adresy URL odrzucane, bez załączników.
- E-mail do salonu: stały szablon z domeny platformy, wysyłany wyłącznie przez JSON API Resend (nigdy surowe nagłówki), `Reply-To` = adres kandydata, pierwsza linia: „Wiadomość przekazana przez tablicę Dam pracę – BeautyPolisa nie weryfikuje nadawcy ani nie przechowuje wiadomości”, link „Zgłoś nadużycie”.
- **Retencja:** treść i adres odbiorcy istnieją tylko w `outbox_emails` do wysyłki – po odpowiedzi 2xx z Resend serwer od razu je czyści (`app_purge_relay_messages`), a niewysłane czyści Cron po 24 h. Zostaje ślad bez danych osobowych (`job_offer_relay_log`: ogłoszenie, czas, odwołanie do statusu outboxu) przez 30 dni – do limitów i zgłoszeń nadużyć. Retencja treści po stronie Resend [do weryfikacji]; Resend wpisujemy do rejestru podprzetwarzających.
- Do kandydata nie wysyłamy żadnego e-maila (potwierdzenie tylko na ekranie) – formularz nie może posłużyć do zasypywania cudzych skrzynek wiadomościami z domeny BeautyPolisa.

### 11.4 Spam i nadużycia

| Wektor | Kontrola |
|---|---|
| Podmiana treści w trakcie moderacji („przynęta i zamiana”) | blokada zmian treści i kontaktu w `pending_review`; moderacja konkretnej `content_version`; slug nadawany przez bazę (zawód, miasto, losowy sufiks; nazwy zastrzeżone – Aura, BeautyPolisa, ERGO, Hestia, Colonnade, LUX MED, ENEL-MED – nie trafiają do adresu) |
| Zalew moderacji | limit 5 ogłoszeń w szkicu lub moderacji na salon (Założenie) |
| Fałszywe ogłoszenia (wyłudzenia, „praca za granicą, wpłać zaliczkę”) | moderacja; zakaz kontaktu i próśb o wpłaty w treści; „Zgłoś nadużycie”; dla kont bez aktywnej polisy – sprawdzenie aktywności NIP; uśpione konta – ponowna weryfikacja (4.3) |
| Phishing przez formularz | stały szablon, linki odrzucane, nagłówek ostrzegawczy, „Zgłoś nadużycie”, limity na IP i ogłoszenie |
| Zasypywanie cudzych skrzynek | brak e-maila do kandydata; limity |
| Wstrzykiwanie treści | tekst zwykły (bez HTML/Markdown); CHECK w bazie odrzuca `<`, `>` i adresy URL; escape przy renderowaniu; JSON-LD serializowany z escapowaniem (11.5); CSP |
| Enumeracja ogłoszeń w szkicu | slug z losowym sufiksem; publiczny odczyt tylko `published` |
| Zbieranie kontaktów salonów (scraping) | kontakt poza listą, JSON-LD i sitemap; „Pokaż kontakt” za Turnstile i limitem; domyślnie formularz; usunięcie 30 dni po ogłoszeniu |

### 11.5 Google for Jobs (`JobPosting`)

- JSON-LD `JobPosting` **tylko na stronie pojedynczego ogłoszenia**, nie na liście. Pola: `title`, `description` (HTML zbudowany wyłącznie z escapowanych akapitów treści), `datePosted` = `published_at`, `validThrough` = `expires_at`, `employmentType` (mapowanie: umowa o pracę → `FULL_TIME`/`PART_TIME` wg wymiaru, zlecenie i B2B → `CONTRACTOR`, inna → `OTHER`), `hiringOrganization` (`name` = `employer_name`; bez `sameAs`/`logo`, jeśli salon ich nie podał), `jobLocation` (`addressLocality`, `addressRegion`, `postalCode`, `addressCountry: PL`), `baseSalary` (`MonetaryAmount`, `currency: PLN`, `QuantitativeValue` z `minValue`, `maxValue`, `unitText: MONTH|HOUR`), `directApply: false` (platforma nie przyjmuje aplikacji), `identifier`. **Bez danych kontaktowych.**
- Serializacja JSON-LD zawsze z escapowaniem `<`, `>`, `&`, U+2028 i U+2029 (`<` itd.) – treść od salonów i organizatorów nie może zamknąć bloku `<script>`.
- Wygasłe lub zamknięte ogłoszenie: odpowiedź **410**, usunięcie z `sitemap-oferty.xml` (z `lastmod`) przy najbliższej rewalidacji. Google Indexing API – P2.
- Lista `/dam-prace` ma treść wstępną (czym jest tablica, jak opublikować ogłoszenie, jak skontaktować się z salonem) i `ItemList`/`BreadcrumbList` bez `JobPosting`. Kombinacje filtrów (`?zawod=`, `?wojewodztwo=`) – `noindex, follow` i canonical do `/dam-prace` (Założenie: bez osobnych stron miast w MVP).

### 11.6 Wygasanie

Ważność 30 dni od publikacji (Założenie; twardy limit w bazie: 60 dni). Cron dzienny: `app_expire_job_offers()` (także usunięcie kontaktów 30 dni po zakończeniu ogłoszenia), przypomnienie 3 dni przed (`job_offer_expiring`), rewalidacja cache.

### 11.7 RODO w „Dam pracę”

| Kwestia | Proponowane rozstrzygnięcie [do weryfikacji przez prawnika i IOD] |
|---|---|
| Dane kandydatów w platformie | Brak: platforma nie zbiera aplikacji. Jedynym miejscem, w którym dane kandydata przechodzą przez platformę, jest formularz przekazujący – treść istnieje w bazie tylko do wysyłki e-maila |
| Role przy formularzu | **Założenie:** salon – administrator danych w swojej rekrutacji; Aura – podmiot przetwarzający w zakresie samego przekazania wiadomości (umowa powierzenia w regulaminie „Dam pracę” akceptowanym przez właściciela); Aura – odrębny administrator tylko w zakresie bezpieczeństwa serwisu (limity, zgłoszenia nadużyć, logi bez PII) |
| Informacja przy formularzu | kto jest administratorem (salon z ogłoszenia), że Aura tylko przekazuje wiadomość i jej nie przechowuje, podprzetwarzający (Resend), prawa osoby |
| Dane kontaktowe salonu | publikowane na polecenie salonu (regulamin „Dam pracę”); przy jednoosobowej działalności to dane osobowe właściciela – podpowiedź „użyj kontaktu rekrutacyjnego”, wyświetlanie tylko po „Pokaż kontakt”, usunięcie 30 dni po ogłoszeniu |
| Wnioski z art. 15–17 | dotyczą salonu (to on ma wiadomości w swojej skrzynce); platforma nie ma czego wydać ani usunąć poza śladem bez PII |

### 11.8 KRAZ i jawność wynagrodzeń

**Decyzja zleceniodawcy z 11.11.2026:** prowadzenie tablicy „Dam pracę” nie wymaga wpisu do rejestru podmiotów prowadzących agencje zatrudnienia (KRAZ). Projekt utrzymuje cechy tablicy opisane w 11.1 – każde rozszerzenie o funkcje z prawej kolumny tej tabeli wymaga nowej decyzji zleceniodawcy.

Niezależnie od tego regulamin „Dam pracę” sprawdzi prawnik pod kątem obowiązków z nowelizacji Kodeksu pracy o jawności wynagrodzeń (informacja o wynagrodzeniu lub jego przedziale dla kandydata, neutralne nazwy stanowisk, zakaz pytania o dotychczasowe wynagrodzenie) [do weryfikacji daty wejścia w życie i zakresu] – projekt już teraz wymaga widełek i neutralnych nazw stanowisk. To nie blokuje etapów.

## 12. „Szkolenia” – specyfika (D-D)

### 12.1 Organizatorzy

- **Kto:** firmy szkoleniowe i salony. Organizator nie potrzebuje polisy; salon z kontem dostaje osobny profil organizatora powiązany z kontem salonu.
- **Weryfikacja (Założenie):** sprawdzenie w rejestrze (NIP, KRS albo CEIDG), adres e-mail w domenie firmy, telefon zwrotny Aura na numer z rejestru lub strony firmy, podpisana umowa organizatora. `verified_at`, `verified_by` i wersję umowy ustawia wyłącznie personel; bez nich profil nie może mieć statusu `active` (CHECK w bazie).
- **Znaczek:** „Organizator zweryfikowany przez Aura Consulting (dane firmy)” – potwierdza tożsamość firmy, nie jakość szkoleń. Nazwa organizatora przy szkoleniu pochodzi wyłącznie ze zweryfikowanego profilu (organizator nie wpisuje jej sam, więc nie podszyje się pod ubezpieczyciela ani Aura).
- **Umowa organizatora:** dane uczestników tylko do przeprowadzenia szkolenia i wystawienia faktury; zakaz marketingu, rekrutacji i przekazywania dalej; usunięcie po rozliczeniu; zgłaszanie naruszeń. Zawieszenie profilu przez personel natychmiast odcina dostęp (`organizer_ids()`).

### 12.2 Katalog, moderacja i zmiany

- **Publikacja wyłącznie po moderacji** (`app_moderate_training()`, personel w sesji `aal2`, z oczekiwaną wersją treści). Organizator może tylko: szkic ↔ do moderacji. Zmiana treści, terminu, miejsca, ceny albo szczegółów dla zapisanych w opublikowanym szkoleniu zdejmuje je z katalogu do ponownej akceptacji; zapisani zachowują miejsca, a po akceptacji dostają `training_changed`.
- **Lista kontrolna moderatora:** temat związany z branżą beauty; brak obietnic uprawnień zawodowych, których organizator nie może nadać; brak linków, numerów kont, linków płatności i numerów telefonów w opisie (walidator + CHECK w bazie dla adresów URL i znaczników); cena w ustrukturyzowanym polu; link do spotkania z hosta z listy dozwolonych (Założenie: Zoom, Microsoft Teams, Google Meet), host pokazywany uczestnikowi.
- **Publiczna strona** pokazuje termin, formę, miasto, organizatora ze znaczkiem, wolne miejsca (`capacity − seats_registered`), cenę albo „bezpłatne”.
- **Zapis:** tylko członkowie aktywnych kont salonów; `audience = 'owners'` dla szkoleń wyłącznie dla właścicieli; limit na salon (domyślnie 3); lista rezerwowa w kolejności zgłoszeń; zapis i rezygnacja są idempotentne.
- **Pojemność:** licznik `seats_registered` i `capacity` zmieniają wyłącznie funkcje z blokadą `FOR UPDATE` wiersza szkolenia – brak nadsprzedaży; `check (seats_registered <= capacity)` jako ostatnia linia obrony.
- **Odwołanie:** `app_training_cancel_event()` (organizator albo personel), e-mail `training_cancelled` do zapisanych i rezerwowych; usunięcie przez moderację (`removed`) – tak samo.
- **Przypomnienia:** potwierdzenie zapisu, awans z listy rezerwowej, zmiana szkolenia, przypomnienie 24 h przed, odwołanie. Plik `.ics` (P1).
- **Zamknięcie zapisów:** `registration_closes_at` albo start szkolenia; po zakończeniu status `completed` (Cron).
- **Obecność i zaświadczenia:** obecność oznacza organizator (albo personel) od rozpoczęcia szkolenia; zaświadczenia PDF po `attended` (P2) – wymagają wzoru i decyzji, kto je wystawia.
- **Płatności:** poza MVP. Szkolenie płatne pokazuje cenę brutto z dopiskiem „fakturę wystawia organizator” (Założenie); rozliczenie odbywa się między organizatorem a uczestnikiem lub salonem, poza platformą.

### 12.3 Dane uczestników dla organizatora (RODO)

| Kwestia | Proponowane rozstrzygnięcie [do weryfikacji przez prawnika i IOD, Q1] |
|---|---|
| Role | **Organizator – administrator danych uczestników swojego szkolenia.** Dla Aura dwa warianty do decyzji prawnika: (a) wariant rekomendowany przez zespół – Aura jest administratorem danych kont Strefy i samego udostępnienia danych organizatorowi, organizator jest odrębnym administratorem; (b) wariant wskazany wstępnie przez zleceniodawcę – Aura jako platforma przetwarza dane zapisu w imieniu organizatora (umowa powierzenia w umowie organizatora). Od wyboru zależą treść informacji przy zapisie, regulamin i umowa organizatora |
| Zakres | imię i nazwisko, e-mail, status (zapisany, obecny, nieobecny); nazwa salonu tylko przy szkoleniu płatnym (do faktury). **Bez** telefonu, `user_id`, `account_id` i informacji o innych szkoleniach uczestnika |
| Informacja | krok przed zapisem: „Twoje imię i nazwisko oraz adres e-mail otrzyma organizator {nazwa}, który jest administratorem tych danych” + link do informacji organizatora; wersja treści zapisywana przy zapisie (`notice_version`) |
| Techniczna separacja | organizator nie ma polityki na `training_registrations`; czyta tylko `training_participant_contacts` swoich szkoleń i tylko wiersze zapisanych/obecnych; osoby z listy rezerwowej niewidoczne do awansu; obowiązkowy TOTP |
| Retencja | usunięcie danych z platformy 30 dni po zakończeniu szkolenia (Założenie); rezygnacja usuwa wiersz od razu; organizator usuwa swoje kopie zgodnie z umową |
| Rozliczalność | wyświetlenie listy i eksport CSV zapisywane w `client_audit_log` (`organizer_participants_viewed`/`exported`) |
| Nadużycia | zbieranie kontaktów pod pozorem darmowego webinaru, marketing, podbieranie pracowników – zakazane umową; „Zgłoś nadużycie”, zawieszenie organizatora |

## 13. Powiadomienia (Resend, outbox)

Wszystkie e-maile przez istniejący wzorzec `outbox_emails` (02 §3.4): wiersz w tej samej transakcji co zdarzenie, pierwsza próba natychmiast, ponowienia z Cron. Nowa kolumna `account_id`. Zasady: **bez załączników**, bez danych osobowych osób trzecich, bez kwot składek w treści (tylko link do strefy), token zaproszenia nigdy w `payload` (rotacja przy ponowieniu), **stałe szablony** – treść od organizatorów i salonów trafia do e-maili tylko jako moderowany tytuł, każdy e-mail o ogłoszeniu lub szkoleniu ma link „Zgłoś nadużycie”, nagłówki `List-Unsubscribe` tylko dla wiadomości nietransakcyjnych. Osobne strumienie Resend dla kodów logowania, e-maili transakcyjnych strefy i leadów.

| Szablon | Odbiorca | Wyzwalacz |
|---|---|---|
| `client_invite`, `organizer_invite` | zapraszany | aktywacja konta, zaproszenie do zespołu, zaproszenie organizatora |
| `client_policy_published` | właściciele | publikacja nowej polisy/dokumentu |
| `renewal_60`, `renewal_30`, `renewal_14` | właściciele | Cron dzienny |
| `claim_received` | właściciel + zespół Aura | zgłoszenie szkody |
| `job_offer_submitted_team` | zespół Aura | ogłoszenie w moderacji |
| `job_offer_published`, `job_offer_rejected`, `job_offer_expiring` | właściciele | moderacja, Cron |
| `job_relay` | adres rekrutacyjny salonu | formularz przekazujący (11.3); treść czyszczona po wysyłce |
| `training_submitted_team` | zespół Aura | szkolenie w moderacji |
| `training_published`, `training_rejected` | organizator | moderacja |
| `training_registered`, `training_waitlisted`, `training_promoted`, `training_changed`, `training_reminder_24h`, `training_cancelled` | uczestnik | zapis, lista rezerwowa, zmiana po ponownej akceptacji, Cron, odwołanie |
| `member_dormant_revoked`, `new_device_login` | właściciel / właściciel i organizator | Cron, logowanie z nowego urządzenia |

E-maile Supabase Auth (kod logowania) idą przez SMTP Resend, poza outboxem.

## 14. Dziennik audytu

`client_audit_log`: append-only – wyzwalacz blokuje UPDATE, DELETE tylko wpisów starszych niż 24 miesiące (Założenie) i tylko przez `app_purge_audit_log()` (SECURITY DEFINER, właściciel `postgres`), wyzwalacz instrukcji blokuje TRUNCATE; `service_role` (sekret Workera) ma tylko SELECT i INSERT. `actor` w formacie `system[:kontekst]` (np. `system:import:<partia>`, `system:crm-sync`, `system:cron`) / `user:<uuid>` / `staff:<uuid>` – funkcje rozróżniają działania personelu i klientów (także przy rezygnacji ze szkolenia i rotacji zaproszeń). `payload` bez PII (≤ 2 KB), `request_id` do korelacji z logami Workera. Zapisują: funkcje `app_*`, wyzwalacz audytu zmian personelu (konta, polisy, profile organizatorów), trasa pobierania dokumentów (`document_downloaded`), wgląd organizatora w listę uczestników. Odczyt: właściciel – zdarzenia swojego salonu (ekran „Historia konta”, P1), personel – wszystko. Logi Workera bez PII jak w 02 §4.8. Kopia poza bazą: codzienny eksport do R2 z blokadą obiektów (Logpush lub podpisany eksport) – P1; łańcuch skrótów (`prev_hash`) – P2, jeśli dziennik ma służyć jako dowód w sporach.

## 15. Zagrożenia (STRIDE) i kontrole

| Kategoria | Zagrożenie w strefie | Kontrole |
|---|---|---|
| **S** – podszycie | Przejęcie skrzynki właściciela (także wspólnej `recepcja@`); zgadywanie kodu OTP z wielu adresów IP; przejęcie sesji przez link zaproszenia z logów, przekazanego e-maila albo wspólnej skrzynki; podrzucenie sesji ciasteczkiem z subdomeny lub cudzym linkiem logowania; organizator podszywający się pod ubezpieczyciela lub Aura; phishing z domeny BeautyPolisa przez formularz | limity per adres (HMAC) i na kod, Turnstile; obowiązkowy TOTP dla właścicieli i organizatorów egzekwowany w RLS; zaproszenie bez sesji, token w `#`; ciasteczka `__Host-`, PKCE; nazwa organizatora tylko ze zweryfikowanego profilu; stały szablon `job_relay`, linki odrzucane; DMARC/DKIM/SPF dla `send.`; ostrzeżenie o wspólnych skrzynkach przy aktywacji |
| **T** – manipulacja | Podmiana `account_id`/`organizer_id`; publikacja z pominięciem moderacji; podmiana treści, kontaktu lub linku do spotkania w trakcie albo po moderacji; zmiana pojemności poniżej liczby zapisanych; zawyżenie/zaniżenie składki przez personel; podmiana pliku PDF; fałszywy przekaz z CRM | RLS `with check`; uprawnienia kolumnowe; guardy przejść statusów, `content_version`, ponowna moderacja po zmianie; funkcje pojemności z blokadą; przeliczenie składki OC z taryfy na serwerze; hash SHA-256 dokumentów; M5: podpis z czasem i nonce, tylko nieopublikowane polisy |
| **R** – wypieranie się | „Nie publikowałem tego ogłoszenia”, „Nie dostałem dokumentu”, „Organizator nie pobierał listy” | `client_audit_log` (kto, co, kiedy; personel jako `staff:`), `document_downloaded`, `organizer_participants_*`, wersje regulaminów i informacji; brak UPDATE/DELETE/TRUNCATE dla `service_role`; kopia poza bazą (P1) |
| **I** – ujawnienie | Wyciek między salonami lub między organizatorami; zbieranie danych uczestników przez fałszywego organizatora; zbieranie kontaktów salonów; buforowanie stanu jednego użytkownika i podawanie go innym; wyciek tokenu zaproszenia w logach; wyciek podpisanego URL; enumeracja kont; dane osobowe w e-mailach i outboxie | RLS na każdej tabeli i na `storage.objects`; minimalna migawka dla organizatora, weryfikacja i umowa, retencja 30 dni; kontakt tylko po „Pokaż kontakt”; reguły cache z 16; token w `#`, wyłączenie strefy z analityki i Sentry; `Cache-Control: private, no-store` + `X-Robots-Tag: noindex, nofollow`; URL 60 s z `download`; neutralne odpowiedzi logowania; czyszczenie `job_relay` po wysyłce |
| **D** – odmowa usługi | Wyczerpanie godzinowego limitu e-maili Auth przez żądania kodów (blokada logowania wszystkich, także `/panel`); zalew moderacji; zalew formularza; wyczerpanie miejsc na szkoleniu przez jeden salon | limity aplikacji przed Supabase, osobny strumień e-maili, alert przy 50 % limitu; limity szkiców; limity formularza; limit miejsc na salon |
| **E** – eskalacja | Pracownik → właściciel; obniżenie roli właściciela zaproszeniem; klient lub organizator → personel; funkcje DEFINER dla `anon`; `user_metadata` jako źródło ról; sesja `aal1`; trwały dostęp po jednorazowym przejęciu przez ustawienie hasła lub zmianę adresu e-mail | członkostwa tylko przez funkcje `service_role` + guard; brak obniżania roli; rozdział `admin_users`/`client_members`/`organizer_members` w obie strony; zero DEFINER dla `anon` (test CI); role tylko z tabel; warunek `aal2` w funkcjach pomocniczych; hasła odrzucane, zmiana adresu tylko przez personel |

## 16. Wydajność i cache

| Zasób | Strategia |
|---|---|
| Strony `/strefa-klienta/*` | renderowane per żądanie, `Cache-Control: private, no-store`, bez cache danych Next.js (dane per użytkownik); zapytania po indeksach `account_id`/`organizer_id`; budżet JS jak dla landingu (≤ 120 KB gzip), formularze jako server actions działające bez JS (wyjątek: przeniesienie tokenu z `#` w 4.2, z wariantem bez JS) |
| `/dam-prace`, `/szkolenia` (lista i szczegóły) | HTML per żądanie (nonce CSP, 02 §3.3); **dane publiczne w cache Next.js tylko z funkcji bez sesji** – klient serwerowy bez ciasteczek albo odczyt kolumn publicznych kluczem serwisowym, bez `cookies()`, `headers()` i wywołań Auth wewnątrz funkcji buforowanych (reguła lint lub test); rewalidacja 300 s i na żądanie (`revalidateTag('job-offers')`, `revalidateTag('trainings')`) po publikacji, wygaśnięciu, zapisie. Stan użytkownika („Zapisano”, pozycja na liście rezerwowej, nagłówek zalogowanego) w osobnym komponencie dynamicznym (Suspense, `no-store`); `training_private_details` i kontakt ogłoszenia nigdy przez funkcję buforowaną |
| Middleware sesji | dopasowanie tylko do `/strefa-klienta/:path*` i `/panel/:path*` – strony publiczne nie odświeżają tokenu ani nie ustawiają `Set-Cookie`; każda odpowiedź z `Set-Cookie` ma `Cache-Control: private, no-store` |
| `sitemap-oferty.xml` | `public, max-age=3600` |
| Pliki PDF | podpisane URL Supabase Storage, bez cache po stronie portalu |
| Obrazy | strefa używa jednego zdjęcia tła (`tlo-marmur-len`, wariant `-1024` na mobile), bez nowych ciężkich assetów |
| Szkło | najwyżej 3 tafle z `backdrop-filter` w widoku; listy (polisy, ogłoszenia, szkolenia, uczestnicy) jako jedna tafla z liniami podziału, nie karta-szkło na element |
| Nowe hosty | brak (Turnstile już jest w CSP; Supabase i Resend tylko po stronie serwera; linki do spotkań online otwierane przez uczestnika, nie ładowane przez stronę) |

Skala obciążenia [hipoteza]: dziesiątki kont i pojedyncze tysiące odsłon strefy miesięcznie – mieści się w Workers Paid i Supabase Pro z 02 §1.3 bez dodatkowych kosztów.

## 17. SEO i GEO

- `/strefa-klienta/*`: `noindex, nofollow` (meta + nagłówek), `Disallow: /strefa-klienta/` w `robots.ts`, brak w sitemap.
- `/dam-prace` i ogłoszenia: indeksowane, `JobPosting` (11.5, `directApply: false`, bez kontaktu), `BreadcrumbList`, osobna sitemap z `lastmod`; wygasłe → 410.
- `/szkolenia` i strony szkoleń: indeksowane (Założenie), schema.org `EducationEvent` z `startDate`, `endDate`, `eventAttendanceMode` (online/offline/mixed), `location` (`Place` albo `VirtualLocation` – bez linku do spotkania), `organizer` (nazwa ze zweryfikowanego profilu), `offers` z `price` (0 dla bezpłatnych, cena brutto dla płatnych), `priceCurrency: PLN` i `availability` (`InStock`/`SoldOut`); odwołane – `eventStatus: EventCancelled`. JSON-LD z escapowaniem jak w 11.5.
- `llms.txt`: dopisać sekcję „Strefa Klienta” (jedno zdanie: konto dla salonów z polisą kupioną przez BeautyPolisa – polisy, tablica ogłoszeń o pracę, szkolenia) i linki do `/dam-prace` i `/szkolenia`.
- Strona główna: teaser strefy (18.2) – treść statyczna, bez wpływu na LCP.

## 18. UX i design

### 18.1 Zasady dla strefy (spójne z 10)

- Ta sama paleta, typografia i ikony co v3; róż tylko w logo; złoto na jasnym tylko jako linie i ramki.
- Tło strefy: jedno zdjęcie (marmur z lnem) pod jasnym szkłem `glass--strong`; ciemne szkło na midnight tylko dla paska nawigacji. Fallbacki szkła (`@supports`, `prefers-reduced-transparency`, `prefers-contrast: more`) bez zmian.
- Typy ekranów: tabele/listy w jednej tafli z cienkimi liniami (czytelność > efekt), statusy jako tekst + ikona (nie sam kolor), daty w formacie „31 grudnia 2026 r.”, kwoty „882 zł” ze spacją nierozdzielającą.
- Formularze: etykiety nad polami, komunikaty błędów pod polem z `aria-describedby`, `autocomplete` (`email`, `one-time-code`, `name`, `tel`), cele dotykowe 44 px, widoczny fokus, brak tekstu poniżej 12 px.
- Animacje w strefie minimalne (przejścia stanów ≤ 200 ms, wyłączone przy `prefers-reduced-motion`) – strefa to narzędzie, nie opowieść.
- Ton: spokojny, rzeczowy, bez wykrzykników („Polisa jest aktywna do 31 grudnia 2026 r.”, „Ogłoszenie czeka na akceptację”, „Szkolenie czeka na akceptację Aura Consulting”).

### 18.2 Teaser na stronie głównej

Miejsce: nowa sekcja między „Jak to działa” (ciemny jedwab) a „Szkoda + FAQ” (marmur), na zdjęciu marmuru, **jedna** tafla `glass--strong` z trzema kolumnami rozdzielonymi złotą linią (limit tafli). Dodatkowo link „Strefa Klienta” w nagłówku (desktop: tekstowy link przed „Umów rozmowę”; mobile: pozycja w menu) i w stopce, obok „Dam pracę” i „Szkolenia”.

Treść (HTML, z twardymi spacjami):

```html
<p class="eyebrow">Strefa Klienta</p>
<h2>Po podpisaniu polisy <em>otwieramy Strefę Klienta</em></h2>
<p>Salon, który kupił polisę przez BeautyPolisa, dostaje własne konto. Polisy i&nbsp;dokumenty są w&nbsp;jednym miejscu, a&nbsp;zespół ma dostęp do tablicy ogłoszeń o&nbsp;pracę i&nbsp;do szkoleń.</p>
<!-- kolumna 1: ikona lux-dokumenty -->
<h3>Polisy i&nbsp;dokumenty</h3>
<p>Aktualne polisy, OWU i&nbsp;aneksy do pobrania o&nbsp;każdej porze, a&nbsp;wygasłe – w&nbsp;archiwum. Przypomnimy o&nbsp;odnowieniu przed końcem ochrony.</p>
<!-- kolumna 2: ikona lux-kosmetolog -->
<h3>Dam pracę</h3>
<p>Opublikuj ogłoszenie dla kosmetologa, fryzjera czy stylistki paznokci. Kandydaci kontaktują się bezpośrednio z&nbsp;salonem.</p>
<!-- kolumna 3: ikona lux-w-zakresie -->
<h3>Szkolenia</h3>
<p>Katalog szkoleń od zweryfikowanych organizatorów – firm szkoleniowych i&nbsp;salonów. Zapis z&nbsp;konta salonu, przypomnienie przed terminem.</p>
<p class="note">Konto aktywuje Aura Consulting po zawarciu polisy – zaproszenie przychodzi e-mailem. Rejestracja nie jest potrzebna.</p>
<a class="btn btn-navy" href="strefa-klienta/logowanie">Zaloguj się do Strefy Klienta</a>
<a class="link-lux" href="dam-prace">Przeglądaj ogłoszenia o&nbsp;pracę</a>
```

W makiecie (statycznej) linki wskazują `logowanie.html` i `dam-prace.html`. Zdanie o aktywacji odpowiada założeniu Z-1 – zmienić, jeśli zleceniodawca zdecyduje inaczej.

## 19. Plan wdrożenia

| Etap | Zakres | Zależności | Czas [Założenie] |
|---|---|---|---|
| **Z0** – decyzje | Odpowiedzi na pytania z 21; regulamin Strefy Klienta, regulamin „Dam pracę” (z umową powierzenia dla formularza i jawnością wynagrodzeń), umowa organizatora szkoleń; opinia o rolach RODO przy danych uczestników (Q1); klauzule; decyzja o administratorze (00 §13 pkt 2) | – | 2–3 tygodnie, równolegle z fazą 1 portalu |
| **Z1** – konto i polisy | Migracja tabel kont, członkostw, zaproszeń, polis, dokumentów, audytu; Auth (SMTP Resend, OTP z limitami, obowiązkowy TOTP właścicieli, PKCE, `__Host-`, hasła odrzucane); reguły WAF i rate limit dla strefy; `/panel/klienci`; pulpit, polisy z archiwum, dokumenty, odnowienia, zgłoszenie szkody, zespół z cyklem życia; testy uprawnień; import startowy (M2) | faza 1 portalu (szkielet, `/panel`, outbox, CI) | 4–6 tygodni |
| **Z2** – „Dam pracę”, „Szkolenia”, organizatorzy | Tabele i funkcje ogłoszeń, kontaktu, formularza przekazującego, organizatorów, szkoleń i zapisów; moderacja ogłoszeń i szkoleń, weryfikacja organizatorów i zgłoszenia nadużyć w `/panel`; publiczne `/dam-prace` i `/szkolenia` z JSON-LD i sitemap; widok organizatora; przypomnienia; migracja M3; teaser na stronie głównej | Z1; regulamin „Dam pracę”, umowa organizatora, Q1 | 5–7 tygodni |
| **Z3** – rozszerzenia | Przekaz z CRM (M5); zaświadczenia; samodzielna edycja profilu organizatora; klucze dostępu; rola „manager”; Indexing API; kopia dziennika poza bazą | decyzja Q8 | wg decyzji |

Definition of Done każdego etapu: testy uprawnień z 9.6 zielone, Security Advisor bez pozycji ERROR/WARN dla nowych obiektów, audyt WCAG 2.2 AA ekranów etapu, budżety wydajności z 02 spełnione, wpis w rejestrze czynności przetwarzania.

## 20. Założenia (do decyzji zleceniodawcy)

Rozstrzygnięte decyzjami z 11.11.2026 (tabela na początku dokumentu): konto przy każdej polisie (D-A), brak odcięcia konta po wygaśnięciu polis (D-B), „Dam pracę” jako tablica bez wpisu do KRAZ (D-C), organizatorzy szkoleń (D-D). Pozostałe założenia:

| ID | Założenie |
|---|---|
| Z-1 | **Założenie:** konto aktywuje Aura Consulting, gdy salon ma aktywną polisę (dowolnego produktu, D-A); bez otwartej rejestracji |
| Z-2 | **Założenie:** polisy i PDF-y wprowadza broker (admin) w `/panel`; bez integracji z ubezpieczycielem w MVP |
| Z-3 | **Założenie:** właściciel zaprasza pracowników; pracownicy widzą „Szkolenia” i „Dam pracę”, nie widzą polis ani kontaktu w ogłoszeniach |
| Z-4 | **Założenie:** ogłoszenia są publiczne; domyślny sposób kontaktu to formularz przekazujący wiadomość do salonu, e-mail lub telefon salon wybiera sam (D-C) |
| Z-5 | **Założenie:** szkolenia mogą być bezpłatne albo płatne; przy płatnych strona pokazuje cenę brutto, a fakturę wystawia organizator; płatności online poza MVP |
| Z-6 | **Założenie:** katalog szkoleń jest publiczny, zapis tylko z konta salonu |
| Z-7 | **Założenie:** właścicielem konta jest osoba kontaktowa z polisy, z osobistym adresem e-mail; kolejnych właścicieli dodaje Aura |
| Z-8 | **Założenie:** ogłoszenie ważne 30 dni, moderacja każdego ogłoszenia, najwyżej 5 ogłoszeń w szkicu lub moderacji na salon |
| Z-9 | **Założenie:** formularz przekazujący – 5 wiadomości na IP na dobę, 50 na ogłoszenie na dobę; treść usuwana po wysyłce, niewysłana po 24 h; ślad bez PII 30 dni; kontakt salonu usuwany 30 dni po zakończeniu ogłoszenia |
| Z-10 | **Założenie:** przypomnienia o odnowieniu 60, 30 i 14 dni przed końcem ochrony |
| Z-11 | **Założenie:** limity: 15 osób w zespole salonu, 10 oczekujących zaproszeń, 10 osób w zespole organizatora, 3 miejsca na szkoleniu na salon, 10 szkoleń w szkicu lub moderacji na organizatora, kod logowania ważny 10 minut, zaproszenie 7 dni; logowanie: 5 kodów na adres na godzinę, 5 błędnych prób na kod, 10 żądań na IP na godzinę |
| Z-12 | **Założenie:** sesja maks. 30 dni, wylogowanie po 7 dniach bezczynności; TOTP obowiązkowy dla właścicieli i organizatorów, opcjonalny dla pracowników |
| Z-13 | **Założenie (cykl życia konta po D-B):** coroczne potwierdzenie zespołu przez właściciela; odebranie dostępu pracownikowi po 12 miesiącach bez logowania; ponowna weryfikacja przez personel po 24 miesiącach bez logowania; konto bez aktywnej polisy – ostrzejsza moderacja ogłoszeń ze sprawdzeniem NIP |
| Z-14 | **Założenie:** dziennik audytu przechowywany 24 miesiące |
| Z-15 | **Założenie:** „Dam pracę” i „Szkolenia” są bezpłatne dla salonów z kontem |
| Z-16 | **Założenie:** weryfikacja organizatora: rejestr (NIP, KRS albo CEIDG), adres e-mail w domenie firmy, telefon zwrotny Aura, podpisana umowa organizatora |
| Z-17 | **Założenie:** dane uczestników dla organizatora usuwane z platformy 30 dni po zakończeniu szkolenia |
| Z-18 | **Założenie:** linki do spotkań online tylko z hostów Zoom, Microsoft Teams i Google Meet |

## 21. Pytania otwarte do zleceniodawcy

| ID | Pytanie | Kto odpowiada | Blokuje |
|---|---|---|---|
| Q1 | Role RODO przy danych uczestników szkoleń: organizator jako odrębny administrator, a Aura jako administrator kont i udostępnienia (rekomendacja zespołu) czy Aura jako podmiot przetwarzający dla organizatora (12.3)? | prawnik + IOD | Z2 |
| Q2 | Kto jest właścicielem konta, gdy ubezpieczającym jest spółka, a kontaktem menedżer? | zleceniodawca | Z1 |
| Q3 | Czy akceptujecie obowiązkowy TOTP dla właścicieli salonów (rekomendacja: tak – chroni polisy przed osobami z dostępem do wspólnej skrzynki salonu)? | zleceniodawca + bezpieczeństwo | nie (domyślnie: tak) |
| Q4 | Administrator danych strefy: Aura Consulting czy Aura Expert (00 §13 pkt 2)? | zleceniodawca + IOD | Z1 |
| Q5 | Jak długo przechowujemy dokumenty polis i dane kont po zakończeniu współpracy (obowiązki dystrybutora), skoro konto nie wygasa (D-B)? | IOD + prawnik | Z1 |
| Q6 | Czy moduły `job_listings`/`trainings` w „BEAUTY” (katalog `app.`) są używane i czy można je wygasić po migracji? | zleceniodawca | Z2 (M4) |
| Q7 | Czy pracownicy mają widzieć ogłoszenia salonu i czy potrzebna jest rola „manager” (ogłoszenia bez polis)? | zleceniodawca | nie |
| Q8 | Czy z CRM ma płynąć automatyczna synchronizacja polis (M5) i kto ją utrzyma po stronie „BEAUTY”? | zleceniodawca + zespół CRM | Z3 |
| Q9 | Czy salony mogą pokazywać w ogłoszeniu logo i adres, czy wyłącznie nazwę i miasto? | zleceniodawca | nie |
| Q10 | Czy katalog szkoleń ma być publiczny (Z-6), czy widoczny tylko dla klientów? | zleceniodawca | Z2 |
| Q11 | Czy organizatorzy szkoleń płacą za publikację albo za weryfikację, czy jest ona bezpłatna? Kto po stronie Aura weryfikuje organizatorów? | zleceniodawca | Z2 |
| Q12 | Czy domyślnym sposobem kontaktu w ogłoszeniu ma być formularz przekazujący (rekomendacja), czy tylko e-mail lub telefon salonu – bez żadnej wiadomości przechodzącej przez platformę? | zleceniodawca + IOD | Z2 |
| Q13 | Jaką retencję treści wiadomości stosuje Resend i czy można ją skrócić [do weryfikacji]? | zespół techniczny | Z2 |

## 22. Decyzje (do rejestru w 08)

| ID | Decyzja | Odrzucone |
|---|---|---|
| D16 | Strefa Klienta w tej samej aplikacji i w nowym projekcie Supabase portalu; dane modułów „BEAUTY” migrowane, CRM pozostaje źródłem polis | strefa na „BEAUTY” (A), osobny schemat w „BEAUTY” (C), osobna aplikacja |
| D17 | Konta wyłącznie z zaproszenia, które nie tworzy sesji; logowanie kodem z e-maila z limitami aplikacji; TOTP obowiązkowy dla właścicieli i organizatorów, egzekwowany w RLS; ciasteczka `__Host-`, PKCE, hasła odrzucane | hasła, otwarta rejestracja, logowanie przez media społecznościowe, sesja z samego linku zaproszenia |
| D18 | Izolacja w RLS przez dwie rozłączne funkcje `client_account_ids()` i `organizer_ids()`; zapisy z niezmiennikami tylko funkcjami `service_role`; personel rozłączny z klientami w obie strony | autoryzacja w kodzie aplikacji, widoki SECURITY DEFINER, jedna wspólna rola klienta |
| D19 | Dokumenty w prywatnym kubełku, podpisywane sesją użytkownika na 60 s | publiczny kubełek, proxy plików przez Worker, załączniki e-mail |
| D20 | **Decyzja zleceniodawcy 11.11.2026 (D-C):** „Dam pracę” wyłącznie jako tablica ogłoszeń – moderacja treści przed publikacją i po każdej zmianie, widełki obowiązkowe, kontakt z salonem bezpośrednio albo przez formularz bez przechowywania wiadomości; bez wpisu do KRAZ | konta i profile kandydatów, baza CV, aplikacje i statusy rekrutacji w platformie, wyszukiwanie, polecanie i dopasowywanie kandydatów, kontakt Aura z kandydatami |
| D21 | **Decyzja zleceniodawcy 11.11.2026 (D-D):** szkolenia dodają zweryfikowani organizatorzy (firmy i salony) z publikacją po moderacji; organizator dostaje minimalne dane uczestników tylko swoich szkoleń; zapis z konta salonu, limit miejsc z blokadą wiersza; bez płatności online w MVP | katalog prowadzony wyłącznie przez personel, płatności online, zapisy bez konta, pełny dostęp organizatora do zapisów |
| D22 | **Decyzje zleceniodawcy 11.11.2026 (D-A, D-B):** konto przy każdej polisie kupionej przez BeautyPolisa; konto i dostęp do „Dam pracę” i „Szkoleń” zostają po wygaśnięciu polis, polisy wygasłe w archiwum; zamiast odcięcia – kontrole cyklu życia (Z-13) | konto tylko dla OC, zawieszenie konta 12 miesięcy po wygaśnięciu ostatniej polisy |

## 23. Zmiany w wersji 1.1

| Zmiana | Źródło |
|---|---|
| Konto przy każdej polisie; archiwum polis; usunięte odcięcie konta, dodane kontrole cyklu życia | D-A, D-B; przegląd bezpieczeństwa (cykl życia konta) |
| „Dam pracę” jako tablica: usunięte aplikacje, dane kandydatów, CV, statusy rekrutacji, e-maile do kandydatów, pytanie o KRAZ; dodany blok kontaktu i formularz przekazujący bez przechowywania | D-C; przegląd bezpieczeństwa (zgodność z D-C, formularz, scraping kontaktów) |
| Organizatorzy szkoleń: profile, weryfikacja, osobne zaproszenia, moderacja, minimalne dane uczestników, role RODO do decyzji prawnika | D-D; przegląd bezpieczeństwa (model uprawnień szkoleń, dane uczestników, fałszywi organizatorzy) |
| Blokada zmian w trakcie moderacji, `content_version`, slug nadawany przez bazę, limity szkiców | przegląd bezpieczeństwa (podmiana treści w trakcie moderacji) |
| Limity OTP po stronie aplikacji, zaproszenie bez sesji i token w `#`, ciasteczka `__Host-` i PKCE, hasła odrzucane, zmiana adresu tylko przez personel, obowiązkowy TOTP właścicieli i organizatorów | przegląd bezpieczeństwa (logowanie, zaproszenia, sesje, Auth) |
| Reguły cache dla stron publicznych i middleware sesji | przegląd bezpieczeństwa (cache) |
| Dziennik: brak UPDATE/DELETE/TRUNCATE dla `service_role`, funkcja retencji, aktor `staff:` i `system:<kontekst>`, uprawnienia przy rotacji zaproszenia | przegląd bezpieczeństwa (integralność dziennika) |
| CHECK w bazie przeciw znacznikom i adresom URL, escapowanie JSON-LD | przegląd bezpieczeństwa (wstrzykiwanie treści) |
| Brak obniżania roli przy przyjęciu zaproszenia, rozdział personelu i klientów w obie strony | przegląd bezpieczeństwa (członkostwa) |
| Uprawnienia kolumnowe zamiast całych tabel dla kont i polis | przegląd bezpieczeństwa (nadmiarowe kolumny) |
| Zabezpieczenie przekazu z CRM (czas, nonce, Vault, tylko nieopublikowane polisy) | przegląd bezpieczeństwa (M5) |
| Poprawka twierdzenia o `search_path` w `app_is_staff()` | przegląd spójności |
