# Tax Protect: wnioski online BeautyPolisa (repozytorium `taxbp`, inżynieria wsteczna)

Źródło: płytki klon publicznego repozytorium zleceniodawcy `aurabroker/taxbp`. Gałąź `main` ma jeden commit `d693a7c` z 18.08.2026. Kod był czytany, nie uruchamiany. To aplikacja Next.js 14 „Beauty Polisa — Tax Protect (wnioski online)” na Cloudflare Pages: projekt `taxbp`, subdomena `tax.beautypolisa.eu` (`docs/koncepcja/01-audyt-stanu-obecnego.md:142`). Backend to funkcje brzegowe Supabase w projekcie „BEAUTY”. Odwołania w formacie `taxbp/<ścieżka>:<linia>`.

| Plik | Zawartość |
|---|---|
| `app/page.tsx` | strona główna (`/`): hero, „Dlaczego”, zakres (sekcje 1 i 2), wyłączenia, „Jak to działa”, warianty i formularz, FAQ, „Nasze serwisy”, stopka z informacją o agencie. Warianty pobiera SSR z funkcji `tax-warianty` |
| `components/WniosekForm.tsx` | **cała logika wniosku**: przedziały przychodu, sumy, wybór wariantu, pola, GUS, oświadczenia i zgody, Turnstile, wysyłka, ekran po wysłaniu |
| `components/WycenaModal.tsx` | modal „Wycena indywidualna” (przychód > 3 mln zł, więcej sporów, wyższa suma) |
| `supabase/functions/tax-wniosek/index.ts` | przyjęcie wniosku: Turnstile, walidacja, zapis do `tax_wnioski`, e-mail z linkiem potwierdzającym (double opt-in) |
| `supabase/functions/tax-potwierdz/index.ts` | potwierdzenie e-maila (GET z tokenem), 3 e-maile (klient z PDF, broker, Colonnade), strony HTML wyniku |
| `supabase/functions/tax-wycena/index.ts` | zapytanie o wycenę indywidualną: Turnstile, walidacja, 2 e-maile, **bez zapisu w bazie** |
| `app/admin/page.tsx` | panel `/admin`: logowanie Supabase Auth, lista wniosków, status, numer polisy (funkcja `tax-admin`) |
| `app/{rodo,regulamin,polityka-prywatnosci,o-nas}/page.tsx`, `components/InfoPage.tsx` | strony informacyjne – **puste** („Treść w przygotowaniu.”) |
| `apiregon.md` | przewodnik GUS BIR 1.1, w tym kod funkcji `tax-gus` (§3.2) – jedyny ślad tej funkcji |
| `public/OWU_Tax_Protect.pdf`, `public/Tax_Karta_Produktu.pdf` | OWU i karta produktu (IPID) – w aplikacji **nigdzie nie podlinkowane** (§7) |
| `beauty-polisa-tax-protect.zip` | starsza wersja z 11.06.2026: trasy API Next (`/api/wniosek`, `/api/gus`, `/api/admin/*`), `lib/emails.ts`, logowanie do panelu hasłem i podpisanym ciasteczkiem. Rozpakowana do katalogu tymczasowego tylko dla porównania |
| `README.md`, `.env.example` | opis wdrożenia i zmiennych. **Nieaktualne**: README nadal opisuje `POST /api/wniosek`, `GET /api/gus` i hasło admina (`README.md:13-14`, `.env.example:20-22`) |

Dane strukturalne do makiety są w `tax-protect-wniosek.json`: kroki, pola, walidacje, komunikaty, zgody, warianty, e-maile, endpointy, dokumenty, braki T1–T15 i porównanie z portalem.

Zastrzeżenia:
- **Repozytorium nie zawiera trzech funkcji, które kod wywołuje:** `tax-warianty` (`app/page.tsx:10`), `tax-gus` (`components/WniosekForm.tsx:111`) i `tax-admin` (`app/admin/page.tsx:8`). Nie ma też migracji tabel `tax_wnioski` i `tax_warianty`, choć README twierdzi, że zostały „utworzone migracją” (`README.md:15`). Schemat odtworzyłem z zapytań w kodzie (§5.2).
- Wartości z konfiguracji są poza dokumentem: adres projektu Supabase, klucz anon, site key Turnstile, sekrety i adresy odbiorców. Publiczne repozytorium zawiera jednak w kodzie: adres projektu (`WniosekForm.tsx:27`, `WycenaModal.tsx:5`, `app/page.tsx:6`, `app/admin/page.tsx:6`), klucz anon (`app/admin/page.tsx:7`) i site key Turnstile (`WniosekForm.tsx:78`, `WycenaModal.tsx:34`, także treść commita). W `.env.example:17-18` są ponadto **imienny adres e-mail pracownika partnera (odbiorca „Colonnade”) i adres zarządu Aura Expert** (§9).
- W cytatach adresy e-mail zastępuję opisami w nawiasach kwadratowych. Placeholdery pól („np. Anna Kowalska”) to przykłady z interfejsu, nie dane klientów.

---

## Werdykt

| | Front (kroki, pola, walidacje, teksty) | Taryfy i wyliczenia | Wysyłka i backend | Teksty prawne | Gotowość do przeniesienia |
|---|---|---|---|---|---|
| Tax Protect (`taxbp`) | kompletny: 1 ekran z 3 sekcjami, modal wyceny | **brak kwot w kodzie**: składka to wiersz `tax_warianty` z bazy; taryfa 8 wariantów jest znana z odczytu bazy 12.11.2026 i decyzji D26 | kod 3 z 6 funkcji; schemat tabel z zapytań; 6 szablonów e-maili dosłownie | 3 wymagane oświadczenia i 2 zgody dosłownie, **nota RODO pusta**, brak klauzuli art. 13 i wersji zgód | **makieta – tak; produkcja – nie** (T1, T3–T8) |

Najważniejsze ustalenia:
1. **Brak analizy potrzeb (IDD, art. 8 UDU).** Formularz od razu zbiera wniosek i wysyła go e-mailem do Colonnade (§8.2). Portal opisuje inną ścieżkę: najpierw analiza potrzeb, potem wniosek u doradcy (`design/v3/tax-protect.html#jak-kupic`, l. 940 w stanie `a82d8b1`). Docelowo ma to być osobisty link `/w/XXXXXXXXXX` w etapie 2 (D32).
2. **OWU i karty produktu klient nie widzi przed złożeniem wniosku.** Pliki są w `public/`, ale nic do nich nie linkuje. Klient dostaje je dopiero w załączniku e-maila, po potwierdzeniu adresu (§7).
3. **Parametry pokazywane klientowi (podlimit grzywien 75%, karencja 21 dni, „1 spór”, „pełne pokrycie retroaktywne”) nie wynikają z OWU.** OWU odsyła do pkt 4–7 polisy, a wzoru polisy w repozytorium nie ma (T3).
4. **Bezpieczeństwo:** endpointy bez uwierzytelniania i z `CORS *`. Turnstile przepuszcza wszystko przy braku sekretu. W e-mailach do brokera i Colonnade dane z formularza trafiają do HTML bez escapowania. `tax-wycena` może posłużyć jako przekaźnik e-maili. Szczegóły w §9.

---

## 1. Przegląd i kroki

**Produkt:** Tax Protect, ubezpieczenie ochrony skarbowej i podatkowej Colonnade Insurance S.A. Oddział w Polsce (omówienie; tytuł OWU: „Tax Protect – Ogólne warunki ubezpieczenia ochrony skarbowej i podatkowej”, stopka strony: „Ogólnych warunkach ubezpieczenia ochrony skarbowej i podatkowej Tax Protect”, `app/page.tsx:346`). OWU zatwierdzono 25.01.2023 i stosuje się je od 26.01.2023 (§7). Program „Beauty Polisa”, agent Aura Expert sp. z o.o., RPU 11229690/A (`app/page.tsx:341-350`).
- Sekcja 1 chroni osoby (właścicielkę, zarząd, zespół) w sprawach karnoskarbowych.
- Sekcja 2 chroni firmę w sporach z US, KAS, ZUS, PIP i PFRON oraz daje asystę podatkową.
- Oferta online obejmuje firmy z przychodem do 3 mln zł.

**Mechanika.** `/` to komponent serwerowy na edge (`export const runtime = "edge"`, `dynamic = "force-dynamic"`, `app/page.tsx:3-4`). Warianty pobiera przez `GET {SUPABASE_URL}/functions/v1/tax-warianty` z `revalidate: 60`, a przy błędzie dostaje `[]` (`app/page.tsx:8-18`). `WniosekForm` (`"use client"`) to **nie kreator ze stepperem**. To jedna sekcja z blokami pokazywanymi warunkowo:
- formularz ma `noValidate`;
- walidacja działa wyłącznie przy wysłaniu (`submit`, `WniosekForm.tsx:130-138`);
- pokazuje się tylko **pierwszy** błąd, w jednym boksie `role="alert"` nad przyciskiem (`WniosekForm.tsx:362-364`);
- wyjątkiem jest komunikat o niepoprawnym NIP, widoczny na bieżąco pod polem (l. 306).

Stan nie jest nigdzie zapisywany (brak localStorage i sessionStorage).

| Krok | Etykieta (dosłownie) | Co zawiera | Kiedy widoczny |
|---|---|---|---|
| 1 | „Krok 1 — Ile wynoszą Twoje roczne przychody?” | 5 przycisków przedziałów (`aria-pressed`), domyślnie „do 250 000 zł” (`WniosekForm.tsx:55`). Kliknięcie ustawia przedział i **resetuje sumę do 50 000 zł** (l. 209) | zawsze (l. 200–245) |
| 1a | „Wycena indywidualna” | box z tekstem, przycisk „Wypełnij formularz wyceny” (otwiera `WycenaModal`) i link `tel:+48504400901` | przedział „powyżej 3 000 000 zł” (`bracket === null`, l. 228–244) |
| 2 | „Krok 2 — Wybierz sumę ubezpieczenia” | 2 karty: 50 000 i 100 000 zł z podlimitem grzywien, składką, dopiskiem „Obejmuje 1 spór podatkowy rocznie” i znacznikiem „Wybrana ✓”/„Wybierz”. Domyślnie 50 000 zł (l. 56). Karta bez wariantu w bazie jest `disabled` (l. 261). Pod kartami link „Skontaktuj się z nami” do modalu | przedział ≤ 3 mln zł (l. 248) |
| 3 | „Dane do wniosku” | NIP z przyciskiem „Pobierz z GUS”, nazwa działalności, imię i nazwisko, e-mail, telefon; pasek podsumowania (suma, podlimit, przychody, składka); 5 oświadczeń i zgód; widżet Turnstile; przycisk; ostrzeżenie „to nie jest zawarcie umowy” | istnieje `activeWariant`, czyli wiersz `tax_warianty` z `przychod_max === bracket` i `suma_ubezpieczenia === selectedSuma` (l. 102–104, 285) |
| — | „Sprawdź swoją skrzynkę e-mail” | ekran zastępujący formularz po udanej wysyłce (l. 179–193) | odpowiedź HTTP 2xx |
| — | strony funkcji `tax-potwierdz` | strona HTML po kliknięciu linku z e-maila (§3.7) | GET z `?token=` |
| — | modal „Wycena indywidualna” | osobny formularz zapytania (§2.2, §3.8) | przycisk w 1a lub link w kroku 2 |

**Przebieg po wysłaniu** (`tax-wniosek` → e-mail → `tax-potwierdz`):
1. Wniosek jest zapisywany jako **niezweryfikowany** (`tax_wnioski`, `tax-wniosek/index.ts:126-149`).
2. Klient dostaje e-mail z przyciskiem „Potwierdzam adres e-mail” (l. 156–170).
3. Kliknięcie oznacza wniosek jako zweryfikowany (`tax-potwierdz/index.ts:133-136`) i wysyła trzy e-maile: klientowi (z OWU i kartą produktu w załączniku), brokerowi (`EMAIL_BROKER`) i do Colonnade (`EMAIL_COLONNADE`) (l. 147–189).
4. Dalej proces jest ręczny: w panelu `/admin` zmienia się status i wpisuje numer polisy (§6.2). Ofertę zapowiadaną w formularzu („Drugi e-mail będzie zawierał ofertę formalną…”) wysyła ktoś poza kodem (T6).

**Usterki widoczne w kodzie** (analiza statyczna, bez uruchamiania):
- **Brak wariantów = martwy formularz.** Gdy `tax-warianty` zwróci błąd albo pustą tablicę, obie karty kroku 2 są `disabled`, a „Dane do wniosku” w ogóle się nie pokazują. Użytkownik nie dostaje komunikatu (`WniosekForm.tsx:253-261, 285`).
- **Turnstile znika po przejściu przez „powyżej 3 000 000 zł”.** Kontener widżetu jest wewnątrz bloku `activeWariant && …`, więc przy `bracket === null` znika z DOM. Efekt renderujący (`[siteKey]`, flaga `tsRendered`) nie uruchamia się drugi raz (l. 81–99, 358). Po powrocie do przedziału ≤ 3 mln zł widżetu nie ma. Jeśli token nie został pobrany wcześniej, wysyłka kończy się komunikatem „Potwierdź, że nie jesteś robotem.”. Ten sam wzorzec ma `WycenaModal`: po zamknięciu i ponownym otwarciu modalu widżet się nie renderuje (`WycenaModal.tsx:52-72`).
- **Kotwica `#wniosek`** (nawigacja „Złóż wniosek”, `app/page.tsx:69`) istnieje tylko wtedy, gdy blok danych jest widoczny albo pokazany jest ekran po wysłaniu (l. 181, 286).
- **Dane z GUS poprzedniego NIP zostają po zmianie NIP.** Zmiana pola NIP czyści tylko `gusState` (`WniosekForm.tsx:297`). Ukryte `regon`, `adres` i `pkd` nie są czyszczone i idą w ładunku (l. 149–151), więc do `tax_wnioski` może trafić REGON, adres i PKD innej firmy niż ta z NIP-u. To samo dzieje się, gdy drugie wyszukanie w GUS nie znajdzie firmy: tryb ręczny (l. 122–127) nie czyści starych wartości. `pkd` nie jest nadpisywane nawet przy udanym wyszukaniu, jeśli GUS go nie zwrócił (`if (data.pkd) setPkd(…)`, l. 117).
- **Modal wyceny nie resetuje stanu po zamknięciu.** `WycenaModal` jest zawsze zamontowany (`WniosekForm.tsx:377`), a przy zamkniętym tylko zwraca `null` (`WycenaModal.tsx:72`). Stan (`done`, pola, zgody, token; l. 18–29) zostaje, a zamknięcie (`onClose` – Esc, tło, „✕”, „Zamknij”; l. 42, 139, 144, 160) niczego nie czyści. Ekran podziękowania zależy wyłącznie od `done` (l. 151), więc po udanym wysłaniu każde kolejne otwarcie pokazuje „Zapytanie wysłane — dziękujemy!” i drugiego zapytania nie da się wysłać bez przeładowania strony.

---

## 2. Pola i walidacje

### 2.1 Wniosek (`WniosekForm`)

Kolejność sprawdzeń przy wysyłce (`WniosekForm.tsx:133-138`). Każde sprawdzenie przerywa wysyłkę po pierwszym błędzie: wariant → NIP → nazwa → e-mail → 3 wymagane oświadczenia → token Turnstile. Serwer (`tax-wniosek/index.ts:88-109`) sprawdza: Turnstile → NIP → nazwa → e-mail → przychód → oświadczenia.

| Pole (stan → klucz ładunku) | Etykieta / atrybuty | Wymagane | Walidacja klienta (dokładnie z kodu) | Komunikat | Serwer |
|---|---|---|---|---|---|
| `bracket` → `przychod` | przyciski kroku 1; wartości `250000`, `500000`, `1000000`, `3000000`, `null` (= „powyżej 3 000 000 zł”) | tak | musi istnieć `activeWariant` | „Wybierz przychód i sumę ubezpieczenia.” | `roundToThousand(Number(przychod))`. `!przychod \|\| ≤ 0` → „Podaj wielkość przychodów.”; `> 3 000 000` → „Tax Protect jest dostępny dla firm o przychodach do 3 mln zł.” (l. 103–105). **Brak kontroli zgodności przychodu z wariantem** (§4.3) |
| `selectedSuma` (do ładunku idzie tylko `wariant_id`) | karty kroku 2; `50000` / `100000` | tak (domyślnie 50 000) | jw. | jw. | suma i składka pochodzą z bazy po `wariant_id` (§4.3) |
| `nip` → `nip` | „NIP”, `inputMode="numeric"`, `autoComplete="off"`, placeholder „np. 1234563218”; przycisk „Pobierz z GUS” / „Szukam…” | tak | `cleanNip` = usunięcie wszystkiego poza cyframi; długość 10; Σ(cyfra_i × [6,5,7,2,3,4,5,6,7]_i) mod 11 == cyfra 10 (l. 36–42) | na bieżąco (gdy pole niepuste): „Ten NIP wygląda na niepoprawny — sprawdź cyfry.”; przy wysyłce: „Podany NIP jest nieprawidłowy.” | to samo sprawdzenie i ten sam komunikat (l. 94–95) |
| `nazwa` → `nazwa_firmy` | „Nazwa działalności”, placeholder „np. Studio Urody Bella Anna Kowalska”; wypełniana z GUS | tak | `trim().length ≥ 3` | „Podaj nazwę działalności.” | to samo (l. 97–98) |
| `osoba` → `osoba_kontaktu` | „Imię i nazwisko”, `autoComplete="name"`, placeholder „np. Anna Kowalska” | **nie** (brak walidacji i brak dopisku „opcjonalnie”) | — | — | zapis `\|\| null` |
| `email` → `email` | „E-mail”, `type="email"`, `autoComplete="email"`, placeholder „anna@twojsalon.pl” | tak | `/^[^@\s]+@[^@\s]+\.[^@\s]+$/` na wartości **bez trim** (wysyłana jest po trim, więc spacja na początku blokuje wysyłkę) | „Podaj prawidłowy adres e-mail.” | `trim().toLowerCase()` + ten sam regex (l. 100–101) |
| `telefon` → `telefon` | „Telefon (opcjonalnie)”, `type="tel"`, `autoComplete="tel"`, placeholder „+48 600 000 000” | nie | — | — | zapis `\|\| null`, bez walidacji |
| `regon`, `adres`, `pkd` | pola ukryte, wypełniane tylko z GUS (l. 114–117) | nie | — | — | zapis `\|\| null`, bez walidacji (`regon`, `adres_siedziby`, `numer_pkd`) |
| `zgody.prawdziwosc` → `zgoda_prawdziwosc` | checkbox z gwiazdką | tak | `true` | „Zaznacz wymagane oświadczenia.” | to samo (l. 107–109); w bazie zawsze `true` |
| `zgody.postepowania` → `oswiadczenie_brak_postepowan` | checkbox z gwiazdką | tak | `true` | jw. | jw. |
| `zgody.rodo` → `zgoda_rodo` | checkbox z gwiazdką | tak | `true` | jw. | jw. |
| `zgody.kanaly` → `zgoda_kanaly` | checkbox | nie | — | — | `!!` → `zgoda_kanaly_kontaktu` |
| `zgody.marketing` → `zgoda_marketing` | checkbox | nie | — | — | `!!` → `zgoda_marketing` |
| `token` → `turnstileToken` | widżet Turnstile (§5.7) | tak (zawsze, bo site key ma wartość zapasową) | niepusty | „Potwierdź, że nie jesteś robotem.” | `siteverify`; porażka → HTTP 400 „Weryfikacja antyspamowa nie powiodła się. Odśwież stronę i spróbuj ponownie.” |

Pozostałe komunikaty wysyłki:
- serwer: 405 „Method not allowed”, 400 „Nieprawidłowy JSON”, 500 „Nie udało się zapisać wniosku. Spróbuj ponownie za chwilę.” (`tax-wniosek/index.ts:79, 85, 153`);
- klient przy odpowiedzi innej niż 2xx: `data.error ?? "Coś poszło nie tak. Spróbuj ponownie."`, potem `turnstile.reset()` i czyszczenie tokenu (`WniosekForm.tsx:165-168`);
- klient przy wyjątku: „Brak połączenia z serwerem. Spróbuj ponownie.” (l. 173). Dotyczy też odpowiedzi, która nie jest JSON-em (np. strona błędu 502), bo `res.json()` rzuca wyjątek;
- przycisk: „Wyślij wniosek o ubezpieczenie”, w trakcie „Wysyłam wniosek…” (`disabled`, l. 366–368).

### 2.2 Wycena indywidualna (`WycenaModal`)

Modal ma `role="dialog"`, `aria-modal="true"` i `aria-label="Wycena indywidualna"`. Zamyka się klawiszem Esc, kliknięciem w tło i przyciskiem „✕” (`aria-label="Zamknij"`). Blokuje przewijanie `body` (`WycenaModal.tsx:40-49, 134-149`).

| Pole → klucz | Etykieta / atrybuty | Wymagane | Walidacja klienta | Komunikat | Serwer (`tax-wycena`) |
|---|---|---|---|---|---|
| `nip` → `nip` | „NIP (opcjonalnie)”, placeholder „np. 1234563218”, przycisk „GUS” / „Szukam…” (GUS wypełnia **tylko nazwę**, l. 81) | nie | ostrzeżenie na bieżąco, gdy NIP niepusty i niepoprawny; **nie blokuje wysyłki** (l. 35, 94–98) | „Ten NIP wygląda na niepoprawny.” | tylko usunięcie znaków niebędących cyframi, bez sumy kontrolnej (l. 91) |
| `nazwa` → `nazwa_firmy` | „Nazwa działalności”, placeholder „np. Studio Urody Bella” | tak | `trim().length ≥ 3` | „Podaj nazwę działalności.” | to samo (l. 79–80) |
| `osoba` → `osoba_kontaktu` | „Imię i nazwisko”, placeholder „np. Anna Kowalska” | nie | — | — | — |
| `email` → `email` | „E-mail *”, placeholder „anna@twojsalon.pl” | tak | regex jak wyżej | „Podaj prawidłowy adres e-mail.” | to samo (l. 82–83) |
| `telefon` → `telefon` | „Telefon *”, placeholder „+48 600 000 000” | tak | co najmniej 9 cyfr po usunięciu pozostałych znaków | „Telefon jest obowiązkowy — podaj prawidłowy numer.” | co najmniej 9 cyfr → „Podaj prawidłowy numer telefonu.” (l. 85–86) |
| `wiadomosc` → `wiadomosc` | „Czego potrzebujesz? (opcjonalnie)”, textarea 3 wiersze, placeholder „np. wyższa suma ubezpieczenia, więcej sporów rocznie…” | nie | — (bez limitu długości) | — | trafia do e-maili (escapowana) |
| `zgody.rodo` → `zgoda_rodo` | checkbox z gwiazdką | tak | `true` | „Zaznacz wymaganą zgodę RODO.” | to samo (l. 88) |
| `zgody.kanaly`, `zgody.marketing` | checkboxy | nie | — | — | **nigdzie nie zapisywane** (funkcja ich nie czyta) |
| `token` → `turnstileToken` | widżet | tak | niepusty | „Potwierdź, że nie jesteś robotem.” | jak w §2.1 |

Przycisk: „Wyślij zapytanie o wycenę”, w trakcie „Wysyłam…”. Błędy obsługiwane są jak w §2.1 (l. 118–130).

---

## 3. Treści dosłowne (formularz, zgody, komunikaty, strony)

### 3.1 Metadane i strona główna (`app/layout.tsx`, `app/page.tsx`)
- `<title>`: „Beauty Polisa — Tax Protect | Ubezpieczenie karno-skarbowe dla salonów beauty”. Description: „Kontrola z urzędu skarbowego, ZUS lub PIP? Tax Protect chroni Ciebie i Twój salon: opłacamy doradcę podatkowego, prawnika i refundujemy grzywny karnoskarbowe. Wniosek online w 3 minuty.” (`app/layout.tsx:4-8`). Fonty Google ładowane z `fonts.googleapis.com` (l. 13–18).
- Nawigacja: „Co Cię chroni” / „Składki” / „Pytania / FAQ”, przycisk „Złóż wniosek” (l. 64–71).
- Hero: znacznik „Tax Protect dla branży beauty”. H1: „Kontrola skarbowa w salonie? Niech to będzie problem Twojego ubezpieczyciela.”. Lead: „Prowadzisz salon, a nie kancelarię podatkową. Gdy odezwie się urząd skarbowy, ZUS albo Inspekcja Pracy — ubezpieczyciel organizuje i opłaca doradcę podatkowego oraz prawnika, a grzywny karnoskarbowe refunduje. Ty zajmujesz się klientkami.”. Przyciski: „Wypełnij wniosek — 3 minuty”, „Zobacz składki” (l. 81–98). Obrazek hero `/hero-beauty.jpg`, alt: „Właścicielka salonu beauty maluje usta czerwoną pomadką” (l. 105–107).
- Liczby pod hero (l. 117–129):
  - „Colonnade” – „ubezpieczyciel z ratingiem A- (AM Best)”;
  - „Pełne pokrycie” – „retroaktywne — liczy się data zdarzenia, nie błędu”;
  - „21 dni” – „karencji, potem pełna ochrona”;
  - „0 zł” – „z Twojej kieszeni za doradcę przy sporze”.
- H2 „Księgowa księguje. Odpowiadasz Ty.” (l. 136–153):
  - lead: „Polskie prawo nie pozwala przenieść odpowiedzialności podatkowej i karnoskarbowej na biuro rachunkowe — nawet jeśli to ono popełniło błąd. Mandat, grzywna albo postępowanie zawsze trafiają do podatnika: właścicielki salonu. Tax Protect domyka tę lukę.” (l. 137–141);
  - trzy karty (l. 144–146):
    - „Niestabilne przepisy” – „Zmieniające się interpretacje i linie orzecznicze sprawiają, że nawet rzetelna firma może mieć spór z fiskusem.”;
    - „Kontrole US, ZUS, PIP, PFRON” – „Każda z tych instytucji może wszcząć kontrolę z urzędu — a jej obsługa bez wsparcia kosztuje czas i pieniądze.”;
    - „Osobiste grzywny” – „Kary z kodeksu karnego skarbowego płaci człowiek, nie firma. Polisa refunduje poniesioną stratę.”.
- Zakres (`#ochrona`), H2 „Jedna polisa, podwójna ochrona”, wstęp: „Tax Protect chroni równolegle Ciebie jako osobę i Twoją firmę jako podatnika.” (l. 160–198, wstęp l. 161):
  - **Sekcja 1 · Dla Ciebie** – „Ochrona karnoskarbowa właścicielki i zespołu”: „Koszty obrony w postępowaniach karnoskarbowych i karnych” / „Koszty postępowania przygotowawczego (przesłuchania, dochodzenia)” / „Refundacja grzywien i kar nałożonych w postępowaniu karnoskarbowym” / „Koszty porady prawnej — zanim sprawa się rozkręci” / „Postępowania porządkowe i kary porządkowe przy kontrolach” / „Koszty odzyskania dobrego imienia i wsparcie psychologiczne”.
  - **Sekcja 2 · Dla Twojej firmy** – „Bezgotówkowa obsługa sporów z urzędami”, z ostrzeżeniem „⚠ Zakres obejmuje 1 spór podatkowy rocznie. Więcej sporów lub wyższe potrzeby — wycena indywidualna.”. Pozycje: „Doradca podatkowy przy kontroli podatkowej i celno-skarbowej — organizuje i opłaca ubezpieczyciel” / „Reprezentacja w postępowaniach podatkowych przed urzędem i sądem” / „Obsługa kontroli i postępowań ZUS, PIP oraz PFRON” / „Asysta podatkowa: szybkie odpowiedzi na problemy podatkowe” / „Wsparcie przy czynnościach sprawdzających i wnioskach do KIS”.
- „Wyłączenia z ochrony (wyciąg z OWU § 8–9)” – 10 pozycji (pełna lista w JSON `strona.wylaczenia`) i dopisek: „Pełna treść wyłączeń: Załącznik 002BR do OWU Tax Protect zatwierdzonego przez Colonnade Insurance S.A. Oddział w Polsce, obowiązującego od 26.01.2023 r.” (l. 201–220). **Uwaga:** w OWU wyłączenia są w § 15, a § 8–9 to zakres sekcji 2. „Załącznika 002BR” nie ma w PDF-ie OWU (§7).
- „Jak to działa” (l. 229–233):
  1. „Wypełniasz wniosek – Podajesz NIP, nazwę działalności i przychody. Zajmie Ci to mniej czasu niż jeden manicure hybrydowy.”
  2. „Wystawiamy polisę – Sprawdzamy wniosek i potwierdzamy ochronę — zwykle w 1–2 dni robocze. Składkę opłacasz raz w roku.”
  3. „Urząd? Dzwonisz do nas – Zgłaszasz sprawę, a ubezpieczyciel organizuje doradcę podatkowego lub prawnika i pokrywa koszty.”
- Sekcja składek: H2 „Wybierz wariant i złóż wniosek”, lead „Składka roczna, bez ukrytych kosztów, bez udziałów własnych dla osób ubezpieczonych. Dla firm o przychodach do 3 mln zł.” (l. 247–250).
- FAQ (`#faq`), H2 „Pytania, które słyszymy najczęściej” (l. 258); 10 pytań (`app/page.tsx:26-37`, pełne odpowiedzi w JSON `strona.faq`):
  - „Dla kogo jest to ubezpieczenie?”
  - „Mam zewnętrzną księgową z polisą OC. Czy to nie wystarczy?”
  - „Prowadzę JDG — co dokładnie chroni polisa?”
  - „Czy ubezpieczyciel zapłaci za mnie podatek albo VAT?”
  - „Czy mandat po kontroli skarbowej jest refundowany?”
  - „Mam już trwające postępowanie karnoskarbowe — czy polisa mnie ochroni?”
  - „Czym jest karencja i ile trwa?”
  - „Co z błędami sprzed zawarcia polisy?”
  - „Czy polisa pokrywa koszty prawnika, ekspertyz i biegłych?”
  - „Jak szybko wypłacane są środki po zgłoszeniu?”

  Odpowiedź na ostatnie pytanie brzmi: „Kodeks cywilny przewiduje termin 30 dni od zgłoszenia. Szkody zgłaszane są do brokera ([e-mail zgłoszeń szkód brokera]) lub przez formularze na vero24.pl.”.
- „Nasze serwisy” (stała `SERWISY`, l. 41–51): znacznik „Nasze serwisy”, tytuł „Poznaj pozostałe serwisy Aura Expert”, wstęp „Wyspecjalizowane rozwiązania w ramach grupy Aura Expert — dla przedsiębiorców, zespołów i branż.” (l. 42–44). Karty (etykieta – opis – cel):
  - „utratadochodu.pl” – „Ochrona dochodu dla wolnych zawodów” – utratadochodu.pl;
  - „ERGO Grupa Otwarta” – „Ubezpieczenia grupowe ERGO” – ergo.beautypolisa.eu;
  - „Grupowe Pakiety Branżowe” – „Pakiety ubezpieczeń dla branż” – ergo.auraexpert.pl;
  - „Beauty Polisa” – „Ochrona salonów i gabinetów” – bez linku, z etykietą „Wkrótce” (`soon: true`; etykieta l. 294).

  Obrazki kart ładowane są z auraexpert.pl.

### 3.2 Kroki 1, 1a i 2 (`WniosekForm.tsx`)
- Etykiety przedziałów: „do 250 000 zł”, „do 500 000 zł”, „do 1 000 000 zł”, „do 3 000 000 zł”, „powyżej 3 000 000 zł” (l. 44–50).
- Box 1a: „Wycena indywidualna” / „Dla firm o przychodach powyżej 3 000 000 zł program standardowy nie obejmuje oferty online. Skontaktuj się z nami — przygotujemy ofertę dopasowaną do Twojej skali działalności.” / przyciski „Wypełnij formularz wyceny” i „Zadzwoń: +48 504 400 901” (l. 230–241).
- Karta sumy (l. 266–275), na przykładzie sumy 50 000 zł:
  - „Suma ubezpieczenia”;
  - „50 000 zł”;
  - „Podlimit grzywien: 37 500 zł”;
  - „{składka} / rok”;
  - „Obejmuje 1 spór podatkowy rocznie”;
  - „Wybrana ✓” albo „Wybierz”.
- Pod kartami: „Potrzebujesz obsługi więcej niż 1 sporu lub wyższej sumy? Skontaktuj się z nami — przygotujemy wycenę indywidualną.”. Fragment „Skontaktuj się z nami” to przycisk otwierający modal (l. 280).

### 3.3 „Dane do wniosku” (l. 287–340)
- Nagłówek: „Dane do wniosku”, podtytuł: „Trzy minuty — i fiskus przestaje spędzać Ci sen z powiek.”
- Komunikaty GUS (l. 118–120, 307–309):
  - „✓ Dane pobrane z rejestru REGON — sprawdź, czy się zgadzają.”;
  - „⚠️ Według GUS działalność jest zawieszona od {data_zawieszenia}. Ubezpieczenie można wystawić po wznowieniu.” (tylko ostrzeżenie, **nie blokuje wysyłki**);
  - „Nie udało się pobrać danych — wpisz nazwę firmy ręcznie.”
- Pasek podsumowania: „Suma: **{suma}** · Podlimit grzywien: **{podlimit_grzywny}** · Przychody: **{bracket}**” oraz „{skladka_roczna} / rok”. Przy przychodach widać sam górny próg przedziału, np. „250 000 zł” bez słowa „do” (l. 333–340).
- Gdy brak site key (dziś nieosiągalne przez wartość zapasową): „Weryfikacja Turnstile zostanie włączona po konfiguracji klucza.” (l. 359).

### 3.4 Oświadczenia i zgody we wniosku (dosłownie, `WniosekForm.tsx:344-350`)

Kolejność na ekranie jest zgodna z tabelą. Gwiazdka „* ” oznacza pole wymagane. Domyślnie wszystkie checkboxy są odznaczone (l. 65). Do bazy trafiają tylko wartości logiczne: bez wersji, treści, znacznika czasu zgody i IP (§9).

| Klucz | Wymagane | Treść | Kolumna `tax_wnioski` |
|---|---|---|---|
| `prawdziwosc` | tak | „Oświadczam, że podane dane są prawdziwe i kompletne. Wiem, że umowa ubezpieczenia zawierana jest w zaufaniu do złożonych oświadczeń.” | `zgoda_prawdziwosc` (zawsze `true`) |
| `postepowania` | tak | „Oświadczam, że wobec mnie ani mojej firmy nie toczy się obecnie postępowanie karnoskarbowe, kontrola podatkowa, celno-skarbowa ani spór z ZUS, PIP lub PFRON.” | `oswiadczenie_brak_postepowan` (zawsze `true`) |
| `rodo` | tak | „Zapoznałam/em się z notą informacyjną RODO Aura Expert sp. z o.o. i wyrażam zgodę na przetwarzanie moich danych w celu obsługi wniosku o ubezpieczenie.” | `zgoda_rodo` (zawsze `true`) |
| `kanaly` | nie | „Wyrażam zgodę na kontakt w sprawie oferty kanałami elektronicznymi i telefonicznymi: SMS, WhatsApp, komunikatory oraz połączenia telefoniczne (art. 172 Prawa telekomunikacyjnego oraz art. 10 ustawy o świadczeniu usług drogą elektroniczną).” | `zgoda_kanaly_kontaktu` |
| `marketing` | nie | „Chcę otrzymywać informacje o produktach Beauty Polisa (opcjonalnie).” | `zgoda_marketing` |

Uwagi:
- Oświadczenie `postepowania` działa jak pytanie eliminujące. Kto ma trwającą kontrolę, nie może wysłać wniosku, a formularz nie mówi, co ma wtedy zrobić.
- Zgoda `rodo` odsyła do noty, której nie ma: `/rodo` pokazuje „Treść w przygotowaniu.” (`app/rodo/page.tsx:7`, `components/InfoPage.tsx:25-29`), a formularz nie ma do niej linku.
- Zgoda `kanaly` powołuje art. 172 Prawa telekomunikacyjnego i art. 10 UŚUDE. Do weryfikacji przez prawnika: oba przepisy zastąpiła ustawa – Prawo komunikacji elektronicznej (od 10.11.2024).

### 3.5 Ostrzeżenie pod przyciskiem (dosłownie, z literówką, `WniosekForm.tsx:369-373`)
„Wysłanie wniosku nie jest jeszcze zawarciem umowy — otrzymasz jednego meila potwierdzającego wysłanie wniosku. Drugi e-mail będzie zawierał ofertę formalną, zgodną z Kodeksem Cywilnym. Dopiero jej zaakceptowanie, będzie dla Ciebie wiążące.”

Sprzeczność: pierwszy e-mail nie potwierdza wysłania, tylko prosi o kliknięcie linku. Klient dostaje więc **trzy** wiadomości: link, potwierdzenie z PDF i ofertę. Oferty nie wysyła żaden kod.

### 3.6 Ekran po wysłaniu (`WniosekForm.tsx:181-191`)
Ikona „📩”, H3 „Sprawdź swoją skrzynkę e-mail”, tekst: „Wysłaliśmy do Ciebie wiadomość z linkiem potwierdzającym. **Kliknij link w e-mailu**, aby dokończyć złożenie wniosku. Dopiero po potwierdzeniu przekażemy wniosek do obsługi i prześlemy Ci komplet dokumentów (OWU, Karta produktu).” oraz „Nie widzisz wiadomości? Sprawdź folder SPAM lub Oferty.”.

Ekran pokazuje się także wtedy, gdy e-mail **nie wyszedł**. Serwer zwraca wtedy `verificationEmailSent:false` z kodem 200, a klient tego pola nie czyta (`tax-wniosek/index.ts:172`; `WniosekForm.tsx:169-170`).

### 3.7 Strony funkcji `tax-potwierdz` (`tax-potwierdz/index.ts:97-108, 113-129, 193-197`)
Wspólny szablon:
- `<title>{tytuł} — Beauty Polisa</title>`, ikona „💗”, nagłówek, akapit;
- przycisk „Wróć na stronę” prowadzi do `https://beautypolisa.eu`. Według audytu domena główna nie ma rekordu DNS (`01-audyt-stanu-obecnego.md:142`), więc przycisk prowadzi donikąd.

| Stan | HTTP | Tytuł | Tekst |
|---|---|---|---|
| brak `token` | 400 | „Brak tokenu” | „Link potwierdzający jest niekompletny.” |
| token nieznany | 404 | „Nieprawidłowy link” | „Ten link potwierdzający jest nieprawidłowy lub wygasł.” (żadnego wygasania kod nie ma) |
| już potwierdzony | 200 | „Adres już potwierdzony” | „Twój wniosek został już potwierdzony i przekazany do obsługi. Dziękujemy!” |
| potwierdzenie | 200 | „Adres e-mail potwierdzony!” | „Dziękujemy — Twój wniosek został przyjęty i przekazany do obsługi. Komplet dokumentów (OWU, Karta produktu) wysłaliśmy na Twój adres e-mail.” (tekst jest ten sam także wtedy, gdy wysyłka e-maili lub pobranie PDF-ów się nie powiodły) |

### 3.8 Modal „Wycena indywidualna” (`WycenaModal.tsx`)
- Nagłówek: „Wycena indywidualna”. Opis: „Dla większej liczby sporów rocznie lub wyższej sumy ubezpieczenia. Wypełnij formularz — przygotujemy ofertę dopasowaną do Ciebie.” (l. 168–170).
- Zgody (l. 222–226):
  - `rodo`, wymagana: „Zapoznałam/em się z notą informacyjną RODO Aura Expert sp. z o.o. i wyrażam zgodę na przetwarzanie moich danych w celu przygotowania oferty.”;
  - `kanaly`, dobrowolna: „Wyrażam zgodę na kontakt kanałami elektronicznymi i telefonicznymi: SMS, WhatsApp, komunikatory oraz połączenia telefoniczne (art. 172 Prawa telekomunikacyjnego oraz art. 10 uśude).”;
  - `marketing`, dobrowolna: „Chcę otrzymywać informacje o produktach Beauty Polisa (opcjonalnie).”
- Komunikat GUS: „✓ Dane pobrane z rejestru REGON.” (l. 190).
- Po wysłaniu: ikona „💗”, „Zapytanie wysłane — dziękujemy!”, „Otrzymaliśmy Twoje zapytanie o wycenę indywidualną. Przygotujemy ofertę dopasowaną do Twoich potrzeb i odezwiemy się wkrótce.”, przycisk „Zamknij” (l. 153–163).

### 3.9 Stopka i strony informacyjne
Stopka strony głównej (`app/page.tsx:327-351`):
- logo Colonnade;
- „Ubezpieczyciel: Colonnade Insurance S.A. Oddział w Polsce · rating A- (AM Best)”;
- linki „O nas”, „Regulamin”, „RODO”, „Polityka Prywatności”;
- nota: „Beauty Polisa to program ubezpieczeniowy dystrybuowany przez Aura Expert sp. z o.o. z siedzibą w Warszawie, ul. Bolkowska 2A/28, 01-466 Warszawa, KRS 0000599840, NIP 5242793544 — agenta ubezpieczeniowego wpisanego do rejestru agentów KNF pod nr 11229690/A, działającego m.in. na rzecz Colonnade Insurance Société Anonyme Oddział w Polsce. Niniejsza strona ma charakter marketingowy. Pełne informacje o zakresie ochrony, ograniczeniach i wyłączeniach znajdują się w „Ogólnych warunkach ubezpieczenia ochrony skarbowej i podatkowej Tax Protect” z 25.01.2023 r. oraz w dokumencie zawierającym informacje o produkcie ubezpieczeniowym. Administratorem danych osobowych podanych we wniosku jest Aura Expert sp. z o.o. — szczegóły w nocie informacyjnej RODO (kontakt z IOD: [e-mail IOD Aura Expert]).”;
- „© {rok} Aura Expert sp. z o.o. · Reklamacje: [e-mail reklamacji Aura Expert] · tel. +48 504 400 901”.

Strony `/o-nas`, `/regulamin`, `/rodo` („RODO — nota informacyjna”) i `/polityka-prywatnosci` mają tylko nagłówek i „Treść w przygotowaniu.” (`components/InfoPage.tsx:25-29`).

---

## 4. Kalkulacja składki i warianty

### 4.1 Model danych wariantu
`type Wariant = { id, nazwa, suma_ubezpieczenia, podlimit_grzywny, skladka_roczna, opis, kolejnosc, przychod_min, przychod_max }` (`WniosekForm.tsx:6-16`). Serwer filtruje dodatkowo `aktywny = true` (`tax-wniosek/index.ts:121`). Klient nie używa pól `przychod_min`, `opis`, `kolejnosc` ani `nazwa`. `nazwa` pojawia się dopiero w e-mailach jako „Wariant”.

### 4.2 Wyznaczanie składki
W kodzie **nie ma wzoru ani kwot**. Składka to `skladka_roczna` wiersza, dla którego `przychod_max === bracket && suma_ubezpieczenia === selectedSuma` (`WniosekForm.tsx:102-104, 253`).

| Stała w kodzie | Wartości | Źródło |
|---|---|---|
| Przedziały przychodu (`BRACKETS`) | 250 000 / 500 000 / 1 000 000 / 3 000 000 zł; `null` = powyżej 3 mln zł → wycena indywidualna | `WniosekForm.tsx:44-50` |
| Sumy (`SUMY`) | 50 000 / 100 000 zł | `WniosekForm.tsx:52` |
| Domyślnie | przychód do 250 000 zł, suma 50 000 zł | `WniosekForm.tsx:55-56` |
| Podlimit grzywien na karcie kroku 2 | **suma × 0,75**, czyli 37 500 / 75 000 zł (liczone w kodzie) | `WniosekForm.tsx:268` |
| Podlimit grzywien w pasku podsumowania | `wariant.podlimit_grzywny ?? 0` (z bazy) – **drugie źródło tej samej wartości** | `WniosekForm.tsx:336` |
| Liczba sporów | tekst „Obejmuje 1 spór podatkowy rocznie” | `WniosekForm.tsx:272` |
| Limit programu | 3 000 000 zł (klient: przedział `null`; serwer: `> 3 000 000` → błąd) | `tax-wniosek/index.ts:105` |

**Taryfa** (wiersze `tax_warianty`; **poza repozytorium**). Źródłem jest odczyt bazy „BEAUTY” z 12.11.2026 i decyzja D26, potwierdzona przez zleceniodawcę (`01-audyt-stanu-obecnego.md:46-59`, `00-koncepcja-portalu-beautypolisa.md` D26). Składka roczna za 1 spór:

| Przychód firmy (`przychod_max`) | Suma 50 000 zł | Suma 100 000 zł |
|---|---|---|
| do 250 000 zł | 1 532 zł | 2 501 zł |
| do 500 000 zł | 1 612 zł | 2 581 zł |
| do 1 000 000 zł | 1 732 zł | 2 701 zł |
| do 3 000 000 zł | 1 932 zł | 2 901 zł |
| powyżej 3 000 000 zł | wycena indywidualna | wycena indywidualna |

Rozjazdy wokół taryfy:
- README nadal mówi o „3 warianty PLACEHOLDER (590/890/1290 zł)” (`README.md:41`). To pozostałość modelu z archiwum zip, gdzie były 3 karty wariantów z etykietą „Najczęściej wybierany”, bez przedziałów przychodu.
- Wartości `podlimit_grzywny` w bazie nie były odczytywane. Nie wiadomo, czy równają się 75% sumy (T3).
- Formatowanie kwot jest niespójne. Strona używa własnego formatera „1 532 zł” (separator tysięcy zawsze, `WniosekForm.tsx:31-34`). E-maile używają `Intl.NumberFormat("pl-PL", {style:"currency"})` (`tax-potwierdz/index.ts:4-5`), a polska lokalizacja nie grupuje liczb czterocyfrowych, więc w e-mailu będzie „1532 zł”.

### 4.3 Co sprawdza serwer
- Składka i suma są brane **z bazy** po `wariant_id`, a nie z ładunku (dobry wzorzec; komentarz w wersji zip: „nie ufamy cenie z frontu”).
- **Serwer nie sprawdza zgodności wariantu z przychodem.** Ładunek z `przychod: 3000000` i `wariant_id` wariantu „do 250 000 zł” przejdzie. W `tax_wnioski` zapiszą się przychód 3 mln zł i składka 1 532 zł (`tax-wniosek/index.ts:103-124, 138-141`).
- Nieznany lub nieaktywny `wariant_id` (albo brak tego pola) nie powoduje błędu. Wniosek zapisuje się z `wariant_id`, `suma_ubezpieczenia` i `skladka_roczna` równymi `null`, a e-maile pokazują „—”.

### 4.4 Wycena indywidualna
Kod kieruje do modalu w trzech sytuacjach:
- przychód powyżej 3 mln zł (`WniosekForm.tsx:228-244`);
- „więcej niż 1 sporu lub wyższej sumy” (l. 280);
- „więcej niż 1 spór rocznie lub wyższa suma ubezpieczenia” – opis dla brokera (`tax-wycena/index.ts:114`).

Kod nie podaje górnej granicy liczby sporów ani sum powyżej 100 000 zł.

---

## 5. Wysyłka danych

### 5.1 Endpointy

Wszystkie adresy mają postać `{SUPABASE_URL}/functions/v1/<nazwa>` (adres projektu jest w konfiguracji, nie w dokumencie). Klient nie wysyła `apikey` ani `Authorization` (`WniosekForm.tsx:142-144`, `WycenaModal.tsx:102-104`). Funkcje publiczne muszą więc być wdrożone bez weryfikacji JWT.

| Funkcja | Metoda | Wywołuje | Uwierzytelnianie | W repo |
|---|---|---|---|---|
| `tax-warianty` | GET | SSR strony `/` (`app/page.tsx:10`) | brak | **nie** |
| `tax-gus?nip=` | GET | przycisk „Pobierz z GUS” / „GUS” (`WniosekForm.tsx:111`, `WycenaModal.tsx:78`) | brak | **nie** (kod wzorcowy w `apiregon.md` §3.2) |
| `tax-wniosek` | POST JSON | wysłanie wniosku | brak; Turnstile | tak |
| `tax-potwierdz?token=` | GET | link w e-mailu | token w URL | tak |
| `tax-wycena` | POST JSON | wysłanie modalu | brak; Turnstile | tak |
| `tax-admin` | GET / PATCH | panel `/admin` (`app/admin/page.tsx:69-70, 93-95`) | `Authorization: Bearer <JWT Supabase Auth>` | **nie** |

CORS w funkcjach z repozytorium: `Access-Control-Allow-Origin: *`, metody `POST, OPTIONS`, nagłówki `Content-Type, Authorization, apikey, x-client-info` (`tax-wniosek/index.ts:4-8`, `tax-wycena/index.ts:3-7`). `tax-potwierdz` nie ustawia CORS, bo zwraca HTML.

### 5.2 `tax-wniosek` – przyjęcie wniosku
Ładunek (`WniosekForm.tsx:145-162`):

`{ wariant_id, nip (same cyfry), nazwa_firmy (trim), regon, adres, pkd (lub brak), przychod (= bracket), email (trim), telefon (trim), osoba_kontaktu (trim), zgoda_rodo, zgoda_prawdziwosc, oswiadczenie_brak_postepowan, zgoda_marketing, zgoda_kanaly, turnstileToken }`

Kolejność na serwerze (`tax-wniosek/index.ts:77-172`):
1. `OPTIONS` → `ok`; metoda inna niż `POST` → 405.
2. JSON.
3. Turnstile (§5.7).
4. Walidacje z §2.1.
5. Klient Supabase z kluczem `service_role`.
6. Wariant z `tax_warianty` (`id`, `aktywny = true`).
7. INSERT do `tax_wnioski`, zwracany `id, token_weryfikacyjny`.
8. E-mail weryfikacyjny (§5.5, szablon 1).
9. Odpowiedź `{ ok: true, pending: true, id, verificationEmailSent }`.

Schemat `tax_wnioski` odtworzony z zapytań (DDL poza repozytorium; typy i domyślne wartości nieznane):

| Kolumna | Źródło |
|---|---|
| `id` (prawdopodobnie uuid – do potwierdzenia migracją, T1; z kodu wynika tylko, że to tekst: „Nr wniosku” = `id.slice(0, 8).toUpperCase()`) | baza; `tax-potwierdz/index.ts:38` |
| `created_at` | baza; panel |
| `nip`, `nazwa_firmy`, `regon`, `adres_siedziby`, `numer_pkd` | ładunek |
| `email_kontaktowy` (małe litery), `telefon`, `osoba_kontaktu` | ładunek |
| `przychod_roczny` | `roundToThousand(przychod)` |
| `wariant_id`, `suma_ubezpieczenia`, `skladka_roczna` | wiersz `tax_warianty` |
| `zgoda_rodo`, `zgoda_prawdziwosc`, `oswiadczenie_brak_postepowan` | stałe `true` |
| `zgoda_marketing`, `zgoda_kanaly_kontaktu` | `!!` z ładunku |
| `token_weryfikacyjny` | **domyślna wartość w bazie** (generowanie nieznane; T1) |
| `zweryfikowany`, `data_weryfikacji` | `tax-potwierdz` |
| `emaile_wyslane` (prawdopodobnie jsonb – do potwierdzenia migracją, T1; z kodu wynika tylko, że to obiekt `{user, broker, colonnade}`, w panelu typ `Record<string, unknown>`) | `tax-potwierdz/index.ts:191`; `app/admin/page.tsx:25` |
| `status` (`nowy`, `w_obsludze`, `polisa_wystawiona`, `odrzucony`), `nr_polisy`, `data_wystawienia` | panel / `tax-admin` (`app/admin/page.tsx:12-36`) |

Stan bazy z audytu z 12.11.2026: 8 wierszy `tax_warianty` i 1 wiersz `tax_wnioski`. RLS `tax_wnioski` nie ma żadnej polityki, więc zapis jest możliwy tylko kluczem serwisowym. `tax_warianty` ma publiczny odczyt aktywnych wariantów (`01-audyt-stanu-obecnego.md:136-137`).

### 5.3 `tax-potwierdz` – double opt-in
1. `GET ?token=`.
2. `SELECT … WHERE token_weryfikacyjny = token` (`maybeSingle`).
3. Gdy rekord jest już potwierdzony, wyświetla stronę „Adres już potwierdzony”.
4. W przeciwnym razie `UPDATE zweryfikowany = true, data_weryfikacji = now`.
5. Pobiera nazwę wariantu.
6. Pobiera PDF-y (§5.6).
7. Wysyła 3 e-maile (szablony 2–4).
8. Zapisuje `emaile_wyslane`.
9. Wyświetla stronę „Adres e-mail potwierdzony!” (`tax-potwierdz/index.ts:110-197`).

Zachowanie:
- token **nie wygasa** i nie jest unieważniany po użyciu (jest tylko flaga);
- potwierdzenie to GET z efektem ubocznym, więc skanery linków w skrzynkach (np. Safe Links) mogą potwierdzić wniosek bez udziału klienta;
- dwa równoległe kliknięcia mogą oba przejść kontrolę `zweryfikowany` przed UPDATE i wysłać e-maile podwójnie;
- link prowadzi do domeny projektu Supabase, nie do domeny BeautyPolisy.

### 5.4 `tax-wycena` – zapytanie o wycenę
Ładunek: `{ nip, nazwa_firmy, osoba_kontaktu, email, telefon, wiadomosc, zgoda_rodo, zgoda_kanaly, zgoda_marketing, turnstileToken }` (`WycenaModal.tsx:105-116`).

Serwer (`tax-wycena/index.ts:64-131`):
1. Turnstile.
2. Walidacje z §2.2.
3. **Dwa e-maile** (szablony 5 i 6).
4. Odpowiedź `{ ok: true }`.

**Bez zapisu w bazie.** Zapytanie i zgody istnieją tylko w skrzynkach odbiorców. `zgoda_kanaly` i `zgoda_marketing` nie trafiają nawet do e-maila. Odpowiedź nie zależy od tego, czy e-maile wyszły.

### 5.5 E-maile (Resend, dosłownie)

**Wysyłka** (`sendEmail`, `tax-wniosek/index.ts:61-75`, `tax-potwierdz/index.ts:79-95`, `tax-wycena/index.ts:48-62`):
- `POST https://api.resend.com/emails` z `RESEND_API_KEY` (sekret, wartość w konfiguracji);
- nadawca to `RESEND_FROM` (konfiguracja); bez tej zmiennej używany jest testowy nadawca Resend (`Beauty Polisa <onboarding@…>`);
- brak `reply_to`, więc odpowiedź „po prostu odpowiedz na tego e-maila” trafia na adres nadawcy;
- bez klucza API funkcja zwraca `false` i nic nie wysyła;
- błędy są połykane.

**Szablon wspólny** (`emailShell`):
- tło `#FDF4F7`, karta biała;
- nagłówek „Beauty ❤ Polisa” (encja `&#10084;`);
- stopka: „Beauty Polisa — program ubezpieczeniowy dystrybuowany przez Aura Expert sp. z o.o., agenta ubezpieczeniowego wpisanego do rejestru KNF pod nr 11229690/A, działającego na rzecz Colonnade Insurance S.A. Oddział w Polsce.” (`tax-wniosek/index.ts:47-59`).

**Tabela podsumowania** (`summaryTable`, `tax-potwierdz/index.ts:28-40`): wiersze „Firma”, „NIP”, „Przychód roczny”, „Wariant”, „Suma ubezpieczenia”, „Składka roczna”, „Nr wniosku”. Brakujące wartości wyświetla jako „—”.

| # | Kiedy / do kogo | Temat (dosłownie) | Treść (dosłownie; `{…}` = wartość z rekordu) | Plik:linie |
|---|---|---|---|---|
| 1 | po wysłaniu wniosku → klient | „Potwierdź swój adres e-mail — Beauty Polisa Tax Protect” | H1 „Jeszcze jeden krok 💗”. „Dziękujemy za wypełnienie wniosku o ubezpieczenie **Tax Protect**. Aby dokończyć jego złożenie, potwierdź swój adres e-mail — kliknij przycisk poniżej.” Przycisk „Potwierdzam adres e-mail” (link do `tax-potwierdz?token=…`). „Dopiero po potwierdzeniu przekażemy wniosek do obsługi i prześlemy Ci komplet dokumentów (OWU, Karta produktu). Jeśli to nie Ty wypełniałaś/eś wniosek — po prostu zignoruj tę wiadomość.” „Gdyby przycisk nie działał, skopiuj ten link do przeglądarki:” + adres | `tax-wniosek/index.ts:157-170` |
| 2 | po potwierdzeniu → klient, z załącznikami | „Dziękujemy za wniosek — Beauty Polisa Tax Protect” | H1 „Dziękujemy{, osoba_kontaktu}! 💗”. „Twój adres e-mail został potwierdzony, a wniosek o ubezpieczenie **Tax Protect** przekazany do obsługi. Skontaktujemy się z Tobą, gdy tylko polisa będzie gotowa — zwykle zajmuje to 1–2 dni robocze.” + tabela. Gdy są załączniki: „W załączniku znajdziesz Ogólne Warunki Ubezpieczenia (OWU) oraz Kartę produktu Tax Protect.” Na końcu: „Masz pytania? Po prostu odpowiedz na tego e-maila.” | `tax-potwierdz/index.ts:150-161` |
| 3 | po potwierdzeniu → `EMAIL_BROKER` (Aura Expert; adres w konfiguracji) | „✅ Wniosek Tax Protect: {nazwa_firmy} — {składka}” | H1 „Klient potwierdził wniosek 🎉” + tabela + „Kontakt: {email}{, tel. {telefon}}” | `tax-potwierdz/index.ts:164-175` |
| 4 | po potwierdzeniu → `EMAIL_COLONNADE` (w `.env.example` adres imienny pracownika partnera; wartość w konfiguracji) | „Nowy wniosek Tax Protect — {nazwa_firmy} (NIP {nip})” | H1 „Nowy wniosek Tax Protect (Beauty Polisa)” + tabela + „Kontakt: {email}{, tel. {telefon}}” | `tax-potwierdz/index.ts:178-189` |
| 5 | wycena → `EMAIL_BROKER` | „📝 Zapytanie o wycenę indywidualną Tax Protect — {nazwa_firmy}” | H1 „Zapytanie o wycenę indywidualną”. „Klient prosi o wycenę wykraczającą poza standardowy cennik (więcej niż 1 spór rocznie lub wyższa suma ubezpieczenia).” + tabela („Firma”, „NIP”*, „Osoba”*, „E-mail”, „Telefon”; * gdy podane) + „**Wiadomość:** {wiadomosc}” (gdy podana) | `tax-wycena/index.ts:94-118` |
| 6 | wycena → klient (adres z formularza) | „Otrzymaliśmy Twoje zapytanie o wycenę — Beauty Polisa Tax Protect” | H1 „Dziękujemy{, osoba_kontaktu}! 💗”. „Otrzymaliśmy Twoje zapytanie o wycenę indywidualną ubezpieczenia **Tax Protect**. Nasz zespół przygotuje ofertę dopasowaną do Twoich potrzeb i skontaktuje się z Tobą.” + ta sama tabela z wiadomością | `tax-wycena/index.ts:120-129` |

Szablony 2–4 wstawiają `nazwa_firmy`, `osoba_kontaktu`, `email` i `telefon` do HTML i tematu **bez escapowania**. `tax-wycena` escapuje `< > &` funkcją `esc` (l. 30–32). Wersja z archiwum zip miała w e-mailu do klienta dodatkowy akapit o karencji („Pamiętaj: ochrona obejmuje zdarzenia, które wystąpią po raz pierwszy w okresie ubezpieczenia. Obowiązuje karencja 21 dni od zawarcia umowy.”). Obecna wersja go nie ma.

### 5.6 PDF-y w e-mailu
`documentAttachments()` (`tax-potwierdz/index.ts:61-77`) próbuje kolejno pobrać:
- OWU: `DOC_OWU_URL` (zmienna) → `{SUPABASE_URL}/storage/v1/object/public/dokumenty/OWU.pdf` → `…/owu.pdf`; załącznik „OWU-Tax-Protect.pdf”;
- kartę: `DOC_KARTA_URL` → `…/dokumenty/karta-produktu.pdf` → `…/Karta-produktu.pdf`; załącznik „Karta-produktu-Tax-Protect.pdf”.

Pobiera pierwszy plik, który się uda, i koduje go w base64 (`fetchDoc`, l. 44–59). Kubełek `dokumenty` jest publiczny. **Pliki z `public/` repozytorium nie są używane.** Nie wiadomo, czy w kubełku leżą te same wersje (T8). Gdy pobranie się nie uda, e-mail wychodzi bez załączników i bez zdania o załącznikach, a strona i tak mówi, że dokumenty zostały wysłane (§3.7).

### 5.7 Turnstile
- **Klient:** skrypt `https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit` jest dołączany dynamicznie do `<head>`. `turnstile.render(el, {sitekey, callback, "expired-callback"})` ustawia token albo czyści go po wygaśnięciu (`WniosekForm.tsx:81-99`, `WycenaModal.tsx:52-70`). Po błędzie serwera wykonuje `turnstile.reset()` i czyści token. Site key to `NEXT_PUBLIC_SITE_KEY` (zmienna z czasu budowania), a gdy jej brak – **wartość zapasowa wpisana w kod** (l. 78; tu jej nie powtarzam). Widżety są dwa: w formularzu i w modalu. Język i wygląd są domyślne (bez `language`, `appearance`, `action`).
- **Serwer** (`verifyTurnstile`, `tax-wniosek/index.ts:33-45`, `tax-wycena/index.ts:16-28`):
  - sekret pochodzi z `TSK` albo `TURNSTILE_SECRET_KEY` (sekret funkcji);
  - **przy braku sekretu funkcja zwraca `true`**, czyli fail-open. Wersja z zip przepuszczała tylko poza produkcją;
  - wywołuje `POST /turnstile/v0/siteverify` z `secret`, `response` i `remoteip` (pierwszy adres z `x-forwarded-for`);
  - sprawdza wyłącznie `success === true`, bez `hostname` i `action`;
  - błąd sieci przy `siteverify` rzuca wyjątek, a ten nie jest obsłużony (odpowiedź 500 platformy).
- `tax-potwierdz` nie używa Turnstile.

---

## 6. Logika poboczna

### 6.1 GUS / REGON
- Przycisk jest aktywny tylko przy poprawnym NIP. Wywołuje `GET tax-gus?nip=`. Gdy `found`, wypełnia `nazwa`, `regon`, `adres` i (jeśli jest) `pkd`, a przy `data_zawieszenia` pokazuje ostrzeżenie. W każdym innym przypadku, także przy błędzie, przechodzi w tryb ręczny (`WniosekForm.tsx:106-128`).
- **Usterka: zmiana NIP nie czyści danych z GUS.** `onChange` pola NIP ustawia tylko `gusState` na `idle` (`WniosekForm.tsx:297`). Ukryte `regon`, `adres` i `pkd` z poprzedniego wyszukania zostają i idą w ładunku (l. 149–151). Tryb ręczny po nieudanym wyszukaniu też ich nie czyści (l. 122–127). Do `tax_wnioski` może więc trafić REGON, adres i PKD innej firmy niż ta z NIP-u, a klient tego nie widzi, bo pola są ukryte.
- W modalu GUS wypełnia tylko nazwę (`WycenaModal.tsx:81`). Modal nie resetuje stanu po zamknięciu (§1, usterki): po wysłaniu każde kolejne otwarcie pokazuje ekran podziękowania.
- Kod funkcji `tax-gus` istnieje tylko jako wzór w `apiregon.md:126-237`:
  - SOAP BIR 1.1: `Zaloguj` → `DaneSzukajPodmioty`;
  - klucz w sekrecie `GUS_API_KEY`;
  - odpowiedź `{found, nazwa, regon, adres, data_zawieszenia}`, a bez klucza `{available:false, reason:"no_key"}`.
- **W dokumentowanej odpowiedzi nie ma pola `pkd`, które klient czyta.** Jeśli wdrożona funkcja jest zgodna z wzorem, `numer_pkd` zawsze ma wartość `null` (T9).
- Nie ma cache, nie ma limitu, zapytanie nie wymaga Turnstile. Endpoint jest publicznym proxy do GUS na kluczu zleceniodawcy.

### 6.2 Panel `/admin`
- Logowanie: `supabase.auth.signInWithPassword({email, password})` kluczem anon wpisanym w kod (`app/admin/page.tsx:7, 77-82`). Sesja jest przechowywana przez supabase-js w localStorage.
- Lista: `GET tax-admin` z `Bearer access_token`, odpowiedź `{wnioski:[…]}` (l. 67–75).
- Zmiany: `PATCH tax-admin {id, status}` albo `{id, nr_polisy, status:"polisa_wystawiona"}` po wpisaniu numeru i Enter (l. 90–99, 220–231).
- Statystyki: „Wszystkie wnioski”, „Nowe (do obsługi)”, „Polisy wystawione”, „Składki z wystawionych”. Filtry według statusu.
- Etykiety statusów: „Nowy”, „W obsłudze”, „Polisa wystawiona”, „Odrzucony”.
- **Reguła autoryzacji `tax-admin` jest nieznana** (funkcji nie ma w repozytorium). Projekt „BEAUTY” ma też innych użytkowników Auth (katalog salonów multi-tenant – `01-audyt-stanu-obecnego.md:137`). Jeśli funkcja sprawdza tylko, czy JWT jest ważny, każdy zalogowany użytkownik projektu odczyta wszystkie wnioski (T12).
- Panel nie pokazuje, czy wniosek jest potwierdzony (`zweryfikowany`). Nie wiadomo, czy `tax-admin` filtruje wnioski niepotwierdzone.
- Pliki `app/admin/admin` (1 bajt) i `app/admin/readme.txt` („Admin”) to śmieci.

### 6.3 Inne
- Brak analityki, banera cookies i Consent Mode. Jedynym zasobem zewnętrznym ładowanym przy wejściu są fonty Google, co oznacza przekazanie IP do Google bez zgody (`app/layout.tsx:13-18`). Obrazki „Nasze serwisy” pochodzą z auraexpert.pl.
- Brak `?agent=` i jakiegokolwiek przypisania leada do agenta lub opiekuna.
- `next.config.mjs` jest pusty: brak nagłówków bezpieczeństwa i CSP po stronie aplikacji (mogą być w Cloudflare – nieznane).

---

## 7. Dokumenty (OWU i karta produktu)

Dane z `pdfinfo` i `pdftotext` (pliki w `taxbp/public/`; czytane lokalnie, bez publikacji):

| | `OWU_Tax_Protect.pdf` | `Tax_Karta_Produktu.pdf` |
|---|---|---|
| Tytuł w treści | „Tax Protect – Ogólne warunki ubezpieczenia ochrony skarbowej i podatkowej” | „Ubezpieczenie ochrony skarbowej i podatkowej – Dokument zawierający informacje o produkcie ubezpieczeniowym”, „Produkt: TAX PROTECT” |
| Ubezpieczyciel | Colonnade Insurance Société Anonyme Oddział w Polsce | Colonnade Insurance S.A. zarejestrowana w Luksemburgu działająca przez Oddział w Polsce |
| Data / wersja | „zatwierdzone przez dyrektora … w dniu 25.01.2023 r. …, mają zastosowanie do umów ubezpieczenia zawieranych od 26.01.2023 r.”; **kod druku „157/0625”** na ostatniej stronie | odsyła do OWU „z dnia 25 stycznia 2023 r.”; **brak kodu i daty dokumentu** |
| Metadane PDF | Colonnade, InDesign; utworzony 09.06.2025, zmieniony 09.07.2025; 23 strony A4; zaszyfrowany (druk i kopiowanie dozwolone, edycja nie); AcroForm | Word; utworzony i zmieniony 27.01.2023; 2 strony **Letter**, nie A4 |
| Rozmiar / SHA-256 | 683 346 B / `640d23e3…be7b` | 151 149 B / `b74d4617…924e` |
| Użycie w `taxbp` | **nigdzie nie podlinkowany**; e-mail bierze plik z kubełka Storage (§5.6) | jw. |

Ustalenia z treści OWU ważne dla formularza i strony:
- **Liczby pokazywane klientowi nie są w OWU.** Odsyłają one do polisy:
  - liczba sporów i problemów podatkowych to pkt 4 polisy (§ 9, § 10);
  - podlimity grzywien, trybu awaryjnego i kaucji to pkt 5 (§ 5 ust. 5, § 6 ust. 1, § 7 ust. 1, 2, 4);
  - Data Ciągłości („retroaktywność”) to pkt 6 (§ 14 ust. 4, § 15 ust. 1 pkt 1 lit. a);
  - Karencja to pkt 7 (§ 14 ust. 6);
  - fakultatywny Okres Dodatkowy to pkt 8 (§ 2).

  Procenty 30% i 75% oraz „21 dni” wymagają wzoru polisy programu (T3).
- **Sekcja 2 rozróżnia kategorie z odrębnymi limitami liczby:** Spory Podatkowe, Spory z ZUS/PIP/PFRON, Postępowania Podatkowe przeciw osobom fizycznym (§ 9 ust. 1–3) oraz Problemy Podatkowe (asysta: prosty problem, Czynność Sprawdzająca, Wniosek do KIS – § 10, § 14 ust. 37–38).
- **Składka:** „Wysokość pełnej składki za czas trwania ochrony ubezpieczeniowej ustala Ubezpieczyciel po dokonaniu indywidualnej oceny ryzyka z uwzględnieniem okresu Karencji.” (§ 17 ust. 2). Umowę zawiera się przez przyjęcie oferty ubezpieczyciela (§ 16 ust. 1), co jest zgodne z ostrzeżeniem w formularzu (§3.5). Składka jest ryczałtowa, niezależna od liczby ubezpieczonych (§ 40 ust. 2).
- **Wyłączenia** są w § 15, a nie w „§ 8–9”, jak podaje strona (`app/page.tsx:202`). Zwrotu „Załącznik 002BR” nie ma w pliku.
- **„Grzywna lub Kara”** to kara „nałożona w Postępowaniu Karnoskarbowym” (§ 14 ust. 5). FAQ `taxbp` obiecuje refundację mandatów z kontroli PIP „analogicznie” (`app/page.tsx:31`). Do potwierdzenia, czy mieści się to w § 7 ust. 5 (Postępowania Porządkowe) – T13.
- Wypłata w 30 dni (§ 38), reklamacje do Colonnade (§ 39). Klauzula danych osobowych wskazuje **Colonnade jako administratora** (s. 22 OWU).

**Karta produktu nie pasuje do OWU w dwóch miejscach** (T8):
1. W „Co jest przedmiotem ubezpieczenia?” wymienia „Koszty powiadomienia osób, których dane wyciekły (i/lub powiadomienia o tym zdarzeniu regulatora)” oraz „koszty obrony i odszkodowań w przypadku, gdy firma, podmiot zależny lub podwykonawca … spowoduje naruszenie bezpieczeństwa danych osobowych lub informacji handlowych”. Takich świadczeń w OWU nie ma. OWU ma tylko „Niewłaściwe postępowanie z informacją” przy Czynnościach Księgowych (§ 7 ust. 3).
2. W ograniczeniach karta wymienia „postępowaniami prowadzonymi na podstawie … prawa karnego lub przepisów prawa karnego skarbowego”, bez zastrzeżenia, że w OWU (§ 15 ust. 1 pkt 6 lit. b) dotyczy to tylko Usługi Pomocy Prawnopodatkowej. Czytelnik karty może uznać, że postępowania karnoskarbowe są wyłączone w całości, a to rdzeń sekcji 1.

---

## 8. Informacja o agencie i analiza potrzeb (IDD)

### 8.1 Informacja o agencie
Informacja o agencie jest w trzech miejscach:
- stopka strony: firma, adres, KRS, NIP, numer RPU 11229690/A, „działającego m.in. na rzecz Colonnade…”, administrator danych, kontakt z IOD i do reklamacji (§3.9);
- stopka e-maili (§5.5);
- modal: brak.

Brakuje elementów z art. 22–23 UDU, które portal ma w `snippets/legal-distributor.json` i stopce makiet v3:
- lista zakładów, na rzecz których działa agent;
- informacja o wynagrodzeniu;
- informacja o powiązaniach kapitałowych;
- tryb reklamacji i Rzecznik Finansowy;
- sposób sprawdzenia wpisu w RPU.

Brakuje też sądu rejestrowego i kapitału zakładowego.

### 8.2 Analiza potrzeb (art. 8 UDU) – **brak**
- W kodzie nie ma kroku, pytań ani zapisu analizy potrzeb. Przedział przychodu i suma służą tylko do wyboru wariantu. Dwa oświadczenia (`prawdziwosc`, `postepowania`) są oceną ryzyka, nie badaniem potrzeb.
- **Dokument IPID (karta produktu) i OWU klient dostaje dopiero po złożeniu i potwierdzeniu wniosku**, i to tylko wtedy, gdy uda się pobrać pliki z kubełka. Przed wnioskiem strona tylko wspomina o dokumentach w stopce, bez linku.
- Wniosek idzie e-mailem prosto do ubezpieczyciela (szablon 4). Doradca jest powiadamiany równolegle (szablon 3).
- Odniesienie do portalu:
  - portal w sekcji „Jak kupić” (`design/v3/tax-protect.html#jak-kupic`, l. 934–978 w stanie `a82d8b1`) ma cztery kroki z nagłówkami „Kalkulator albo kontakt”, „Kontakt doradcy” (podpis „Analiza potrzeb”), „Wniosek” (podpis „Z doradcą Aura Expert”) i „Polisa” (podpis „Colonnade · Strefa Klienta”). Wstęp sekcji: „Najpierw analiza potrzeb, potem wniosek – tak wymagają przepisy o dystrybucji ubezpieczeń (IDD). Doradca Aura Expert prowadzi Cię przez każdy krok.” (l. 940). To samo w skrócie podaje odpowiedź FAQ „Jak kupić Tax Protect?” (`#pytanie-5`, l. 991);
  - D32 i dokument 12 przewidują dla Tax Protect w etapie 2 osobisty link `portal.beautypolisa.eu/w/XXXXXXXXXX` (APK, wniosek, podpisy w CRM Aura Expert).

  Formularz `taxbp` w obecnym kształcie **nie pasuje do żadnej z tych ścieżek**. W portalu jego część „dane i oświadczenia” powinna trafić do APK i wniosku pod linkiem `/w/` (etap 2). Do tego czasu portal ma tylko kalkulator i formularz kontaktowy (W5 wariant a; T5).

---

## 9. Bezpieczeństwo i RODO

**Uwierzytelnianie i ochrona endpointów**
- `tax-wniosek`, `tax-wycena`, `tax-potwierdz`, `tax-warianty` i `tax-gus` działają bez JWT i z `CORS *`. Jedyną ochroną przed spamem jest Turnstile, a ten:
  - przy braku sekretu przepuszcza wszystko (`tax-wniosek/index.ts:35`, `tax-wycena/index.ts:18`);
  - nie sprawdza `hostname` ani `action`.
- Brak limitu żądań, honeypota, deduplikacji i limitów długości pól (np. `wiadomosc`, `nazwa_firmy`).
- **`tax-wycena` jako przekaźnik poczty.** Każdy, kto przejdzie Turnstile (człowiek albo farma rozwiązań), może wysłać z domeny nadawcy BeautyPolisy wiadomość na dowolny adres wpisany w pole e-mail, z własną treścią w „nazwie działalności” i „wiadomości”. To ryzyko phishingu i utraty reputacji domeny. Wniosek główny nie ma tego problemu: e-mail weryfikacyjny nie zawiera treści od użytkownika.
- **Brak escapowania HTML** w szablonach 2–4. `nazwa_firmy` i `osoba_kontaktu` trafiają do e-maili brokera i Colonnade, a `nazwa_firmy` także do tematu. Można w ten sposób wstrzyknąć link lub fałszywą treść do wiadomości wewnętrznych (`tax-potwierdz/index.ts:28-40, 154, 168-172`).
- **Double opt-in na GET** z tokenem bez wygasania, na domenie Supabase (§5.3).
- **Panel:** autoryzacja `tax-admin` nieznana (§6.2). Logowanie tylko hasłem, brak MFA w kodzie panelu. Zip miał inny model: jedno wspólne hasło i ciasteczko HMAC na 12 h.

**Przechowywanie danych**
- Dane trafiają do tabeli `tax_wnioski` w projekcie Supabase „BEAUTY”, wspólnym z katalogiem salonów, CRM i e-mailami (`01-audyt-stanu-obecnego.md:137`). Zapis odbywa się kluczem `service_role`.
- Zakres danych: NIP, nazwa firmy, REGON, adres, PKD, e-mail, telefon, imię i nazwisko, przychód, wariant, zgody. Nie ma danych szczególnych kategorii ani PESEL.
- **Wniosek zapisuje się przed potwierdzeniem e-maila.** Wnioski niepotwierdzone (także wpisane na cudzy adres) zostają bez retencji i bez sprzątania.
- Zapytania o wycenę nie są nigdzie przechowywane poza skrzynkami pocztowymi. Ich zgody też nie, więc nie ma rozliczalności (art. 7 ust. 1 RODO).
- Zgody zapisane są jako same wartości logiczne: bez wersji, treści, hasha, znacznika czasu zgody, IP i user agenta (wzorzec docelowy – W3).
- Dane klienta (NIP, nazwa, e-mail, telefon, składka) **idą e-mailem do Colonnade** (adres imienny). Zgoda `rodo` mówi tylko o Aura Expert i „obsłudze wniosku”, a nota informacyjna jest pusta. Klient nie dostaje informacji o przekazaniu danych ubezpieczycielowi przed wysłaniem, choć OWU wskazuje Colonnade jako odrębnego administratora.
- Zgoda `rodo` jako podstawa przetwarzania do „obsługi wniosku” to prawdopodobnie zła podstawa (właściwa byłaby art. 6 ust. 1 lit. b RODO). Do oceny prawnika (T4).
- Logi: `console.error("DB insert error", error)` (`tax-wniosek/index.ts:152`), bez treści wniosku.

**Publiczne repozytorium** zawiera:
- adres projektu Supabase i klucz anon w kodzie;
- site key Turnstile w kodzie i w treści commita;
- imienny adres e-mail pracownika partnera i adres zarządu w `.env.example:17-18`;
- archiwum zip ze starszym kodem.

Klucz anon i site key są z założenia publiczne, ale razem z funkcjami bez JWT i `tax_warianty` z publicznym odczytem ułatwiają nadużycia. Adres imienny to dana osobowa w publicznym repozytorium: do usunięcia z historii.

---

## 10. Co z tego wynika dla portalu

1. **Przenieść:**
   - przedziały i sumy (§4.2) do `pricing_tax_variants` z wersją taryfy (W6, 02 §2.3);
   - przeliczenie składki po stronie serwera z kontrolą zgodności przedziału i wariantu (usterka z §4.3);
   - walidację NIP;
   - tryb ręczny i GUS (W1/E2 – wspólne z EZB), z poprawką usterki z §6.1: każda zmiana NIP i każde nieudane wyszukanie czyści dane pobrane z GUS (REGON, adres, PKD, nazwa, jeśli pochodziła z GUS), a dane z GUS są widoczne dla klienta przed wysłaniem;
   - dwa oświadczenia underwritingowe do wniosku pod linkiem `/w/` (etap 2);
   - w formularzu kontaktowym lub zapytaniu w okienku: po zamknięciu i po udanej wysyłce resetować pola, zgody, token Turnstile i stan „wysłano” (usterka modalu z §1), a widżet Turnstile renderować przy każdym zamontowaniu kontenera.
2. **Nie przenosić:**
   - wysyłki wniosku e-mailem do Colonnade przed analizą potrzeb;
   - zgody `rodo` jako „zgody na przetwarzanie” bez noty;
   - double opt-in przez GET na domenie Supabase;
   - modalu wyceny bez zapisu, który zastępuje formularz kontaktowy portalu z tematem „Tax Protect” (`POST /api/leads`, `12-integracja-apk-wniosek-polisa.md:165`).
3. **Do decyzji:**
   - W1 (`00-braki-i-decyzje.md`, rozdz. 2): wariant A – CRM „aurabroker” przez dedykowane funkcje; B – własna baza portalu; C – hybryda (koperta w portalu, treść do CRM). Dokument 14 odpowiada na W1 wariantem C i dla Tax Protect (kalkulator, lead) przewiduje kopertę w portalu i lead w CRM z kodem `tax` (`14-integracja-wnioskow-z-crm.md`, ustalenie 4 i tabela w rozdz. 4); etap 2 (link `/w/`) wymaga zmiany CRM, bo dziś obsługuje tylko `oc_beauty`. Stan obecny – zapis do `tax_wnioski` w projekcie „BEAUTY” – **nie jest żadnym z wariantów A–C** i nie powinien być kontynuowany przez portal (T1, T14);
   - W4: kto wysyła e-maile i czy Colonnade dostaje powiadomienie;
   - W9: los `tax.beautypolisa.eu` (przekierowanie 301 na `/ubezpieczenia/tax-protect`) i 1 wiersza `tax_wnioski`.

---

## 11. Braki T1–T15: co mamy / czego brakuje / od kogo / czy blokuje

Legenda kolumny „Blokuje” jak w `00-braki-i-decyzje.md`: **TAK** – bez tego nie da się uruchomić na produkcji; **makieta** – blokuje już makietę; **nie** – można uruchomić, a uzupełnić później.

| # | Co mamy | Czego brakuje | Od kogo | Blokuje |
|---|---|---|---|---|
| T1 | Kod `tax-wniosek`, `tax-potwierdz`, `tax-wycena`; wywołania `tax-warianty`, `tax-gus`, `tax-admin`; schemat `tax_wnioski` odtworzony z zapytań | Kod trzech funkcji spoza repozytorium; migracja tabel `tax_wnioski` i `tax_warianty` (typy, `token_weryfikacyjny` – generowanie, domyślny `status`, RLS, indeksy); potwierdzenie, że wdrożone wersje funkcji = repozytorium | Zleceniodawca (projekt Supabase „BEAUTY”) | **TAK** tylko, jeśli portal miałby nadal zapisywać do `tax_wnioski` w projekcie „BEAUTY” (poza wariantami W1 A–C); przy W1 A/B/C – nie (do C: tylko migracja 1 wiersza – T14) |
| T2 | Taryfa 8 wariantów (odczyt bazy 12.11.2026, D26); przedziały i sumy w kodzie | Dokument źródłowy taryfy od Colonnade z wersją i datą obowiązywania, procedura zmian; wyjaśnienie „składka stała” wobec OWU § 17 ust. 2 (indywidualna ocena ryzyka); wartości `podlimit_grzywny` w bazie | Zleceniodawca / Colonnade | nie (start na D26), ale wersja taryfy jest potrzebna do zapisu (W6) |
| T3 | Podlimit grzywien 75% (kod), karencja 21 dni, „1 spór”, „pełne pokrycie retroaktywne” (treści) | Wzór polisy programu: pkt 4 (limity liczby Sporów Podatkowych, Sporów z ZUS/PIP/PFRON, postępowań osób fizycznych, Problemów Podatkowych), pkt 5 (podlimity: grzywny, tryb awaryjny – portal pisze 30%, kaucje, schematy podatkowe, limit dodatkowy), pkt 6 (Data Ciągłości), pkt 7 (Karencja), pkt 8 (okres dodatkowy) | Colonnade | **TAK** dla publikacji tych liczb w kalkulatorze i na stronie |
| T4 | 3 oświadczenia i 2 zgody dosłownie; administrator Aura Expert w stopce | Nota informacyjna RODO (`/rodo` pusta), klauzula art. 13 z informacją o przekazaniu danych Colonnade (odrębny administrator), właściwa podstawa prawna (umowa zamiast „zgody” na obsługę wniosku), zgoda na kanały po zmianie przepisów (PKE), wersje i treści zgód do rejestru (W3); regulamin, polityka prywatności | Zleceniodawca + prawnik | **TAK** |
| T5 | — (brak w kodzie) | Analiza potrzeb dla Tax Protect: pytania, zapis wyniku, kto ją prowadzi (etap 2 `/w/`, D32); decyzja W5, że do etapu 2 portal ma tylko kalkulator i zapytanie | Zleceniodawca (compliance) | **TAK** dla wniosku w portalu |
| T6 | Zapowiedź „Drugi e-mail będzie zawierał ofertę formalną…”; statusy w panelu | Proces po wniosku: kto przygotowuje i wysyła ofertę (Colonnade, Aura Expert, pośrednik po stronie Colonnade?), wzór oferty, sposób akceptacji, płatność (jednorazowo albo w ratach – karta produktu), wystawienie polisy, numer polisy do CRM i Strefy Klienta; rola odbiorcy `EMAIL_COLONNADE` | Zleceniodawca / Colonnade | **TAK** |
| T7 | 6 szablonów e-maili dosłownie (§5.5) | Decyzja W4 (kto wysyła), nadawca i `reply_to`, odbiorcy (sekrety), czy portal ma powiadamiać Colonnade; szablony bez emoji i bez treści promocyjnych | Zleceniodawca | **TAK** (W4) |
| T8 | OWU (kod 157/0625, OWU z 25.01.2023) i karta produktu (27.01.2023) w `public/` | Potwierdzenie aktualnych wersji i zgodności z plikami w kubełku `dokumenty`; poprawiona karta produktu (pozycje o wycieku danych spoza OWU, niejasne wyłączenie KKS, format A4); „Załącznik 002BR” cytowany na stronie; dostęp do OWU i karty **przed** wnioskiem | Colonnade | **TAK** (dokumenty przedumowne, W5) |
| T9 | Kontrakt i wzór `tax-gus` (`apiregon.md`) | Kod wdrożonej funkcji, klucz BIR (sekret), pole `pkd` (klient je czyta, wzór go nie zwraca), reguła dla działalności zawieszonej (dziś tylko ostrzeżenie) | Zleceniodawca | nie (tryb ręczny) |
| T10 | Mechanizm Turnstile w 3 funkcjach | Site key i sekret dla domeny portalu; usunięcie fail-open; sprawdzanie `hostname` i `action` (W2) | Zleceniodawca (konto Cloudflare) + portal | **TAK** (W2) |
| T11 | Modal wyceny (tylko e-mail, bez zapisu) | Zasady wyceny indywidualnej: przychód > 3 mln zł, 2–4 spory (portal) albo „więcej niż 1” (`taxbp`), sumy > 100 000 zł; kto wycenia i w jakim czasie | Zleceniodawca / Colonnade | nie (formularz kontaktowy portalu z tematem „Tax Protect”) |
| T12 | Panel `/admin` (statusy, numer polisy) | Kod i reguła autoryzacji `tax-admin`; kto z niego korzysta; zastąpienie sprawami w CRM (`crm_renewals`, etap 2) | Zleceniodawca / zespół CRM | nie dla portalu (ale ryzyko bezpieczeństwa – §9) |
| T13 | Treści strony `taxbp` | Źródła i potwierdzenie: rating „A- (AM Best)”, „pełne pokrycie retroaktywne”, refundacja mandatów z kontroli PIP, „Wyłączenia z ochrony (wyciąg z OWU § 8–9)” (`app/page.tsx:202`), zakres „Koszty obrony” | Colonnade | nie (ale przed publikacją w portalu) |
| T14 | 1 wiersz `tax_wnioski`, subdomena `tax.beautypolisa.eu` | Decyzja W9 (przekierowanie 301 albo wyłączenie), migracja lub usunięcie danych historycznych (02, pytanie 6), retencja wniosków niepotwierdzonych | Zleceniodawca | nie |
| T15 | Double opt-in (`tax-potwierdz`) | Decyzja, czy portal potwierdza e-mail przed przekazaniem leada, i jak (kod jednorazowy lub link na domenie portalu, z ważnością i ochroną przed skanerami); usunięcie imiennego adresu z publicznego repozytorium | Portal + zleceniodawca | nie |

---

## 12. Porównanie z `design/v3/tax-protect.html` (rozbieżności – do decyzji, strony nie poprawiałem)

Numery linii makiety podaję według stanu z commita `a82d8b1` (ta sama wersja pliku jest w HEAD). Kopia robocza jest równolegle zmieniana przez workflow słownika: blok `gen:slownik-css` i link „Słownik pojęć” w nawigacji dodały 35 linii, więc linie od ok. 740 są dziś przesunięte o +35 (np. taryfa 948–951, hero „od 1 532 zł” 870, wstęp „Jak kupić” 975). Trwałym odnośnikiem są identyfikatory sekcji (`#zakres`, `#sekcja-1`, `#sekcja-2`, `#taryfa`, `#jak-kupic`, `#pytanie-N`, `#dalej`). Linie 642 i 650 to dane strukturalne JSON-LD (FAQPage) w `<head>`, przed wstawionym blokiem, więc się nie przesunęły.

| # | Temat | Portal (`design/v3/tax-protect.html`) | `taxbp` | OWU / karta | Ocena |
|---|---|---|---|---|---|
| P1 | Kwoty taryfy | 8 kwot 1 532–2 901 zł (`#taryfa`, l. 913–916), „od 1 532 zł” (hero, lista `.figures`, l. 835) | brak kwot w kodzie, wiersze z `tax_warianty`; README: „590/890/1290 zł” (`README.md:41`) | składkę ustala ubezpieczyciel (§ 17 ust. 2) | portal zgodny z odczytem bazy z 12.11 (D26); README nieaktualny; potrzebny dokument taryfy (T2) |
| P2 | Sumy i przedziały | 50 / 100 tys. zł; do 250 tys. / 500 tys. / 1 mln / 3 mln zł; w taryfie wiersz „powyżej 3 000 000 zł” z komórką „wycena indywidualna” (`#taryfa`, l. 913–917) | identyczne (`WniosekForm.tsx:44-52`) | „ustalane indywidualnie w każdej umowie” (karta) | zgodne |
| P3 | Okres przychodu | „ostatni zamknięty rok obrotowy” (`#taryfa`, l. 905; JSON-LD, pytanie „Ile kosztuje Tax Protect?”, l. 642) | FAQ: „ostatni zamknięty rok podatkowy” (`app/page.tsx:27`); formularz: „roczne przychody” bez okresu | — | rozbieżność słów (obrotowy / podatkowy); do ujednolicenia |
| P4 | Podlimit grzywien | „Refundacja mandatów karnoskarbowych do 75% sumy ubezpieczenia” z dopiskiem „próg 75% i zakres – do potwierdzenia” (`#sekcja-1`, l. 867) | 75% liczone w kodzie (`WniosekForm.tsx:268`) + `podlimit_grzywny` z bazy (l. 336); bez dopisku | pkt 5 polisy (§ 7 ust. 1) | spójne z kodem; źródłem jest polisa (T3) |
| P5 | Tryb awaryjny | „refundacja do 30% sumy ubezpieczenia”, „np. aresztowanie” (`#sekcja-1`, l. 865) | brak | „do wysokości wskazanej w pkt 5 Polisy” (§ 6 ust. 1); w OWU brak przykładu aresztowania | liczba 30% bez źródła w `taxbp` i OWU (T3) |
| P6 | Karencja | „21 dni od zawarcia polisy” z dopiskiem „karencja 21 dni – do potwierdzenia” (`#zakres`, blok „O czym pamiętać”, l. 890) | „21 dni” bez zastrzeżeń (`app/page.tsx:33, 121, 209`) | pkt 7 polisy (§ 14 ust. 6) | spójne; źródło – polisa (T3) |
| P7 | Liczba sporów | „Taryfa obejmuje jeden pełny spór podatkowy w roku – na przykład z urzędem skarbowym lub KAS, z ZUS, z Państwową Inspekcją Pracy albo z PFRON.” (JSON-LD, l. 650; widoczne jako `#pytanie-3`) i „Taryfa obejmuje jeden pełny spór podatkowy w roku.” (`#sekcja-2`, l. 875); „Chcesz ubezpieczyć 2–4 spory w roku? To wycena indywidualna – zapytaj doradcę.” (`#sekcja-2`, `p.scope-extra`, l. 883) i „Ochrona 2–4 sporów w roku – wycena indywidualna.” (`#taryfa`, `p.tariff-note`, l. 921) | „1 spór podatkowy rocznie” (`app/page.tsx:184, 214`; `WniosekForm.tsx:272`); „więcej niż 1 sporu” bez górnej granicy (l. 280; `tax-wycena/index.ts:114`) | odrębne limity dla Sporów Podatkowych i Sporów z ZUS/PIP/PFRON oraz Problemów Podatkowych (§ 9–10, pkt 4 polisy) | portal łączy ZUS/PIP/PFRON z „1 sporem podatkowym” – do potwierdzenia; „2–4” nie ma w `taxbp` |
| P8 | Wyzwalacze wyceny indywidualnej | omówienie: przychód > 3 mln zł albo 2–4 spory (JSON-LD, l. 642; `#dalej`, l. 1046) | przychód > 3 mln zł, więcej sporów **lub wyższa suma** (`WniosekForm.tsx:280`, `WycenaModal.tsx:170`) | — | portal pomija „wyższą sumę” (> 100 000 zł) |
| P9 | Charakter składki | „Składki są stałe – wynikają z taryfy, a nie z indywidualnej wyceny.” (`#taryfa`, l. 905) | „Drugi e-mail będzie zawierał ofertę formalną…” (`WniosekForm.tsx:369-373`) | „ustala Ubezpieczyciel po dokonaniu indywidualnej oceny ryzyka” (§ 17 ust. 2); umowa przez akceptację oferty (§ 16) | sformułowanie portalu przeczy OWU; do uzgodnienia z Colonnade (T2) |
| P10 | Koszty obrony | „Pokrycie wydatków na adwokata w postępowaniach cywilnych, administracyjnych i arbitrażowych.” (`#sekcja-1`, l. 862) | „Koszty obrony w postępowaniach karnoskarbowych i karnych” (`app/page.tsx:168`) | definicja obejmuje m.in. postępowania karnoskarbowe, cywilne, administracyjne, sądowo-administracyjne, egzekucyjne, wykonawcze i arbitraż (§ 14, „Koszty Obrony”) | portal pomija postępowanie karnoskarbowe – rdzeń sekcji 1 |
| P11 | Retroaktywność | brak (usunięte – K18) | „Pełne pokrycie – retroaktywne” (`app/page.tsx:120`), FAQ „Polisa ma pełne pokrycie retroaktywne” (l. 34) | Data Ciągłości w pkt 6 polisy; wyłączenie sporów sprzed Daty Ciągłości (§ 15 ust. 1 pkt 1 lit. a) | `taxbp` obiecuje to, czego portal świadomie nie mówi (T3, T13) |
| P12 | Rating | brak | „rating A- (AM Best)” (`app/page.tsx:119, 332`) | brak | źródło nieznane (T13) |
| P13 | Postępowania porządkowe i PIP | „Zwrot kar nałożonych przy kontrolach kadrowych i podatkowych” z dopiskiem „zwrot kar, w tym PIP – do potwierdzenia” (`#sekcja-1`, l. 866) | FAQ: mandaty z kontroli PIP refundowane „analogicznie” (`app/page.tsx:31`) | „Grzywna lub Kara” tylko z postępowania karnoskarbowego (§ 14 ust. 5); kary porządkowe – § 7 ust. 5 | `taxbp` mocniej niż OWU; portal słusznie oznacza do potwierdzenia |
| P14 | Odwołania do OWU | „zatwierdzone przez Colonnade 25.01.2023 r., stosowane do umów zawartych od 26.01.2023 r.”, link `/dokumenty/owu-tax-protect-colonnade` (`#zakres`, blok „O czym pamiętać”, l. 892) | te same daty (`app/page.tsx:219, 347`), ale „wyciąg z OWU § 8–9” i „Załącznik 002BR”; PDF niepodlinkowany | wyłączenia w § 15; brak „002BR”; kod druku 157/0625 | daty zgodne; numeracja i załącznik w `taxbp` błędne |
| P15 | Ścieżka zakupu | omówienie: kalkulator lub formularz → doradca → analiza potrzeb → wniosek z doradcą → polisa i Strefa Klienta (`#jak-kupic`, l. 934–978; `#pytanie-5`, l. 991) | wniosek online bez analizy potrzeb → e-mail do Colonnade i brokera → oferta e-mailem → panel `/admin` | umowa przez akceptację oferty (§ 16) | sprzeczne procesy; portal zgodny z D32/D34 (T5, T6) |
| P16 | Czas | brak terminu | „zwykle w 1–2 dni robocze” (`app/page.tsx:231`, `tax-potwierdz/index.ts:155`) | wypłata 30 dni (§ 38) | SLA do potwierdzenia przed użyciem w portalu |
| P17 | Asysta i KIS | „Asysta podatkowa … czynnościach sprawdzających”, „Wniosek do KIS … wiążącą interpretację indywidualną” (`#sekcja-2`, l. 880–881) | „Asysta podatkowa: szybkie odpowiedzi…”, „Wsparcie przy czynnościach sprawdzających i wnioskach do KIS” (`app/page.tsx:190-191`) | Problem Podatkowy = prosty problem, Czynność Sprawdzająca, Wniosek do KIS (§ 14 ust. 37); liczba – pkt 4 polisy | zgodne co do zakresu; liczba nieznana |

---

## Weryfikacja (2026-11-13)

Sprawdzone w kodzie i **potwierdzone**:
- przedziały i sumy oraz wartości domyślne (`WniosekForm.tsx:44-56`);
- podlimit `× 0.75` (l. 268);
- algorytm NIP (wagi 6,5,7,2,3,4,5,6,7, mod 11) w obu komponentach klienta (`WniosekForm.tsx:36-42`, `WycenaModal.tsx:7-15`) i w `tax-wniosek/index.ts:21-27`; `tax-wycena` nie sprawdza sumy kontrolnej (`tax-wycena/index.ts:91`);
- usterki dopisane przy weryfikacji: dane z GUS nie są czyszczone po zmianie NIP (`WniosekForm.tsx:297`, l. 149–151) i modal wyceny nie resetuje stanu po zamknięciu (`WycenaModal.tsx:18-29, 72, 151`; `WniosekForm.tsx:377`);
- kolejność walidacji i komunikaty (l. 133–138; `tax-wniosek/index.ts:88-109`; `WycenaModal.tsx:94-98`; `tax-wycena/index.ts:79-88`);
- treść 5 oświadczeń i zgód oraz ostrzeżenia z literówką „meila”;
- ładunki obu formularzy i mapowanie na kolumny;
- fail-open Turnstile przy braku sekretu;
- brak escapowania w `tax-potwierdz` i escapowanie w `tax-wycena`;
- źródła PDF w e-mailu (Storage, nie `public/`);
- brak linków do PDF w aplikacji (grep `\.pdf` w `app/` i `components/`);
- puste strony informacyjne;
- metadane i treść PDF (`pdfinfo`, `pdftotext`; kod 157/0625, daty 25.01.2023 i 26.01.2023, § 6, § 15–17, § 38–40).

Nie dało się sprawdzić z kodu: wartości w bazie (`podlimit_grzywny`, kwoty – przyjęte z audytu 12.11.2026), wdrożonych wersji funkcji i reguły autoryzacji `tax-admin` (T1, T12).
