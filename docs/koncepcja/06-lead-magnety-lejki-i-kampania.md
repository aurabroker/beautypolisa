# 06 · Lead magnety, lejki i kampania kreatywna

> Sekcja koncepcji portalu **beautypolisa.eu**. Fakty o produktach, cenach, marce i infrastrukturze pochodzą wyłącznie z `01-audyt-stanu-obecnego.md`; przepływ leada, model danych, ochrona formularzy i polityka zgód – z `02-architektura-i-bezpieczenstwo.md`; lista treści narzędziowych, adresy URL narzędzi i kalendarz publikacji – z `05-strategia-tresci.md`; dane strukturalne i pomiar GEO – z `04-seo-geo-i-schema.md`. Wszystkie wskaźniki konwersji są hipotezami do zweryfikowania po starcie. Dokument nie generuje grafik, nie wysyła e-maili, nie zawiera sekretów ani identyfikatorów projektów.

## TL;DR

- Cztery magnesy wg ramy MAGNET, każdy zakotwiczony w produkcie, który dziś ma parametry w briefie: **quiz grup ryzyka** (OC dla branży beauty (ERGO Hestia), góra lejka, bez bramki, e-mail opcjonalny), **wzór zgody na zabieg + checklista dokumentacji** (OC, środek, bramka e-mail), **checklista kontroli sanepid / ZUS / US** (Tax Protect (Colonnade), środek, bramka e-mail), **kalkulator kosztu rotacji vs pakiet** (Grupowe ERGO dla beauty, dół lejka, na liczbach użytkownika).
- Kalkulator „ile tracisz na L4 jako JDG” odrzucony jako magnes nr 3: produkt „Utrata dochodu” nie ma w briefie żadnych parametrów (01, pkt 3.5), więc magnes nie miałby kotwicy; zostaje narzędziem edukacyjnym bez bramki (05, C1.4) i wraca jako magnes, gdy zespół produktowy dostarczy ofertę.
- Wynik zawsze natychmiast na ekranie. E-mail służy dostarczeniu kopii, a seria pielęgnująca (4 wiadomości z gałęziami na zachowanie) startuje dopiero po osobnej zgodzie i jej potwierdzeniu (double opt-in). Orkiestracja serii w Supabase + Cron Worker z sekcji 02, wysyłka i zdarzenia przez Resend (tagi, webhooki).
- Zgody jako trzy osobne elementy (informacja RODO, zgoda e-mail, zgoda na telefon – ta ostatnia tylko tam, gdzie zbieramy numer), bez domyślnych zaznaczeń, bez pilności i ciemnych wzorców. Obowiązki informacyjne dystrybutora (IDD) warstwowo: stopka, `/o-nas`, `/dokumenty`, strona sukcesu formularza leada i pierwszy kontakt brokera. Treści klauzul – do weryfikacji prawnej.
- Kampania startowa 30 dni: brief, kalendarz (17 pozycji Canva, 3 e-maile, 4 posty LinkedIn, 3 Reels), inwentarz slotów dwóch szablonów, tabela luk (w repo nie ma zdjęć poza logo i `AEX.png`) i budżet generowania do zatwierdzenia. **Generowanie projektów w Canva wymaga osobnej zgody właściciela i dostępu do kont – ten dokument dostarcza wyłącznie brief, kalendarz i copy.**
- KPI lejka jako przedziały [hipoteza], 3 testy A/B, macierz odpowiedzialności dev / marketing / broker / prawnik, lista narzędzi i jawna lista tego, czego dokument nie robi.

---

## 0. Zakres i rama MAGNET

Portal nie sprzedaje polis (01, pkt 8.1). Magnesy mają trzy zadania: **zakwalifikować** (grupa ryzyka, wielkość zespołu, zawód), **zbudować zaufanie** dokumentami, których klient faktycznie użyje w salonie, i **oddać kontakt brokerowi** w momencie, gdy osoba sama o to prosi. Każdy magnes przechodzi przez ramę MAGNET:

| Litera | Zasada | Jak egzekwujemy w BeautyPolisa |
|---|---|---|
| **M** – jedna grupa, jeden problem, jedna szybka wygrana | Magnes nie jest „dla całej branży” | Persony z 05 (właścicielka salonu 1–8 osób, kosmetolog JDG, fryzjer, linergistka, stylistka paznokci, tatuażysta, manager sieci); jeden magnes = jedna persona główna |
| **A** – zakotwiczenie w produkcie płatnym i etapie lejka | Góra: quiz / kalkulator; środek: szablon / checklista; dół: case / ROI | Produkt musi mieć parametry w 01 (cennik, sumy, zakres). Bez parametrów – brak magnesu, tylko treść edukacyjna |
| **G** – natychmiastowy, interaktywny wynik | Zamiast PDF-a „sprawdź skrzynkę” | Wynik renderowany na stronie; PDF i e-mail to kopia, nie warunek |
| **N** – nazwa od efektu | Nie „e-book o OC”, lecz „sprawdź, w której grupie…” | Nazwy w tabeli poniżej; H1 testowane A/B (pkt 4.2) |
| **E** – cały lejek | Landing (korzyść-first) → krótki formularz (e-mail + imię) → strona sukcesu → dostarczenie → 3–5 e-maili rozgałęzionych na zachowanie | Pełny przykład dla magnesu 1 w pkt 2; mechanika wspólna w pkt 1.5 |
| **T** – pielęgnacja bez wczesnego pitchu | Dostarczenie → szybka wygrana → dowód → miękki następny krok | Seria 4 e-maili: pierwszy pitch (kalkulator) dopiero w 3. wiadomości; rozmowa z brokerem – w 4. |

Przegląd czterech magnesów (adresy URL spójne z tabelą „Treści narzędziowe” w 05; adres magnesu 4 jest propozycją):

| # | Nazwa robocza (od efektu) | Persona główna | Problem | Produkt płatny (kotwica) | Etap lejka | Bramka | URL |
|---|---|---|---|---|---|---|---|
| 1 | „Sprawdź, czy Twoje zabiegi mieszczą się w programie OC dla beauty” (quiz) | kosmetolog JDG; wtórnie wszystkie zawody | „Nie wiem, czy moje zabiegi w ogóle da się ubezpieczyć i ile to kosztuje” | OC dla branży beauty (ERGO Hestia) | góra | brak; e-mail opcjonalny po wyniku | `/baza-wiedzy/quiz-grupy-ryzyka` |
| 2 | „Komplet przed zabiegiem: wzór zgody + checklista dokumentacji” | linergistka, kosmetolog, tatuażysta | „Mam zgodę na kolanie, nie wiem, co powinna zawierać i czego zażąda ubezpieczyciel” | OC dla branży beauty (ERGO Hestia) – ankieta wymaga formularzy zgody (01, pkt 3.1) | środek | e-mail + imię; dostęp natychmiast na stronie sukcesu + kopia e-mailem | `/baza-wiedzy/zgoda-na-zabieg-wzor` |
| 3 | „Gotowość na kontrolę: sanepid, ZUS, US – checklista” | właścicielka salonu 1–8 osób | „Boję się kontroli, nie wiem, co powinnam mieć przygotowane” | Tax Protect (Colonnade): sekcja 1 ochrona karno-skarbowa właściciela, sekcja 2 jeden pełny spór podatkowy w roku (01, pkt 3.2) | środek | e-mail + imię; lista online bez bramki, PDF i zapis postępu po e-mailu | `/baza-wiedzy/checklista-kontroli` |
| 4 | „Rotacja vs pakiet: policz różnicę na własnych liczbach” | manager sieci / właścicielka zatrudniająca | „Ludzie odchodzą, a ja nie wiem, czy benefit się opłaca” | Grupowe ERGO dla beauty – pakiety 58 / 68 / 76 zł za osobę miesięcznie (wg cennika programu) | dół | brak; e-mail opcjonalny („wyślij podsumowanie”) | `/baza-wiedzy/kalkulator-rotacji` [propozycja] |

---

## 1. Cztery magnesy

### 1.1 Magnes 1 – quiz „Sprawdź, czy Twoje zabiegi mieszczą się w programie OC dla beauty”

Uwaga do nazwy: tytuł z zadania („…są objęte OC”) obiecuje potwierdzenie ochrony, którego quiz dać nie może – zakres ochrony wynika z OWU i oceny wniosku, a quiz jedynie przypisuje zabiegi do jednej z czterech grup ryzyka programu (01, pkt 3.1). Proponujemy sformułowanie „mieszczą się w programie”, a wariant „W której grupie ryzyka są Twoje zabiegi?” testujemy A/B. Wynik nigdy nie używa słów „jesteś objęta / masz ochronę”.

| Litera | Zastosowanie |
|---|---|
| M | Kosmetolog JDG wykonujący zabiegi z gr. 2, czasem z gr. 4; szybka wygrana: w 60 s wie, w której grupie jest i czy czeka go ocena indywidualna |
| A | OC dla branży beauty (ERGO Hestia); góra lejka → wynik prowadzi do `/kalkulator/oc` z prewypełnioną grupą i liczbą osób (05, narzędzie 2) |
| G | Wynik na ekranie natychmiast po ostatnim kroku; brak pola e-mail przed wynikiem |
| N | „Sprawdź, czy Twoje zabiegi mieszczą się w programie OC dla beauty” (A) vs „W której grupie ryzyka są Twoje zabiegi?” (B) |
| E | Landing → quiz (3 kroki) → wynik → opcjonalny e-mail (e-mail + imię) → strona sukcesu → E0 dostarczający → po potwierdzeniu seria E1–E4 (pkt 2) |
| T | E1 szybka wygrana (co oznacza grupa), E2 dowód (jak wygląda roszczenie), E3 miękki krok (kalkulator), E4 zamknięcie (rozmowa albo cisza) |

**Obietnica:** „Zaznacz zabiegi, które wykonujesz. W 60 sekund zobaczysz, do której z 4 grup ryzyka programu trafiają, jaka jest składka roczna wg taryfy programu i czy potrzebna jest ocena indywidualna. Bez podawania e-maila.”

**Kroki quizu i pola:**

| Krok | Pole | Typ | Źródło wartości |
|---|---|---|---|
| 1 | Zabiegi, które wykonujesz | wielokrotny wybór, lista alfabetyczna bez etykiet grup (żeby nie sugerować wyniku) | lista zabiegów gr. 1–4 z `bp-app.js` (01, pkt 3.1) jako JSON w `packages/content` |
| 2 | Ile osób wykonuje zabiegi | 1 / 2–8 / 9 i więcej | próg „zespół powyżej 8 osób → wycena indywidualna” (01, pkt 3.1) |
| 3 | Twój zawód (opcjonalnie) | lista: kosmetolog, fryzjer, podolog, linergistka, stylistka paznokci, tatuażysta, inny | enum `Profession` z 02; prewypełnione, gdy wejście z `/dla-kogo/<zawod>` |
| wynik | – | – | – |
| po wyniku | E-mail, imię (oba opcjonalne) + checkbox zgody marketingowej | formularz | `POST /api/magnets` (pkt 1.5) |

**Wynik (reguła):** najwyższa grupa spośród zaznaczonych zabiegów. Gr. 1–3 → „Twoje zabiegi mieszczą się w grupie N programu. Składka roczna wg taryfy programu: od X zł przy sumie gwarancyjnej 100 000 zł; klauzula ochrony prawnej +92 zł”; X z aktywnej wersji cennika programu (02, pkt 2.3): gr. 1 – 400 zł, gr. 2 – 650 zł, gr. 3 – 850 zł. Gr. 4 lub 9+ osób → „Twoje zabiegi (lub wielkość zespołu) wymagają indywidualnej oceny” z listą powodów i CTA „Poproś o indywidualną ocenę”. Zawsze adnotacja: „Quiz nie potwierdza ochrony – zakres wynika z OWU i oceny wniosku”. Trzy przyciski: **Policz dokładną składkę** (→ `/kalkulator/oc?grupa=N&osoby=…`), **Lista zabiegów w mojej grupie** (→ artykuł A2.1 z 05), **Wyślij mi wynik na e-mail** (rozwija formularz).

**Mechanika (Next.js / Supabase, opis):** strona jest komponentem serwerowym, który – jak `/kalkulator/oc` w 02, pkt 2.3 – pobiera aktywną wersję cennika przez cache z rewalidacją 5 min oraz listę zabiegów z JSON w repozytorium i przekazuje je jako props do wyspy klienckiej. Quiz liczy w przeglądarce czystą funkcją z `packages/pricing` (ta sama, która zasila kalkulator), bez żądań sieciowych między krokami. Wynik jest zakodowany w adresie strony wyniku (`/baza-wiedzy/quiz-grupy-ryzyka/wynik?g=2&o=1&z=kosmetolog`) – bez danych osobowych, więc link z e-maila działa bezterminowo i nadaje się do udostępnienia. Podanie e-maila wywołuje `POST /api/magnets` (pkt 1.5); do bazy trafia subskrybent, zapis dostarczenia z ładunkiem `{group, teamBand, profession}` i wiersz outbox dla e-maila E0. Zdarzenia do kolektora przez Service Binding (02, pkt 7.1): `magnet_view`, `quiz_started`, `quiz_completed {group, individual}`, `quiz_to_calculator`, `magnet_email_submitted`.

**KPI [hipoteza]:** start quizu 40–60 % odwiedzin landingu; ukończenie 60–80 % startów; przejście do kalkulatora 25–40 % ukończeń; podanie e-maila 10–25 % ukończeń; zgoda marketingowa wśród podających e-mail 40–60 %.

### 1.2 Magnes 2 – „Komplet przed zabiegiem: wzór zgody + checklista dokumentacji”

| Litera | Zastosowanie |
|---|---|
| M | Linergistka / kosmetolog / tatuażysta; szybka wygrana: gotowy wzór i lista dokumentów, które powinny powstać przed i po zabiegu |
| A | OC dla branży beauty – ankieta ERGO Hestii pyta o formularze zgody na zabieg i kwalifikacje personelu (01, pkt 3.1); środek lejka, łączy się z artykułem A3.1 „Co przygotować do wniosku” (05) |
| G | Po wysłaniu formularza wzór i checklista otwierają się od razu na stronie sukcesu (podgląd HTML + pobranie PDF); e-mail to kopia |
| N | „Komplet przed zabiegiem: wzór zgody + checklista dokumentacji” |
| E | Landing (artykuł G1.1 z 05 jako nośnik) → formularz (e-mail, imię; zawód prewypełniony z kontekstu) → sukces z dokumentami → E0 kopia → seria „dokumentacja” (3 e-maile: jak wdrożyć wzór, karta zabiegu i zdjęcia, co z tego widzi ubezpieczyciel) |
| T | Pitch dopiero w ostatnim e-mailu: „co przygotować do wniosku OC” z linkiem do kalkulatora |

**Obietnica:** „Wzór zgody na zabieg w wersji do edycji i checklista dokumentacji, którą prowadzi się przed zabiegiem, w trakcie i po. Do użycia od razu. Zweryfikowane prawnie [do czasu weryfikacji – nie publikować].”

**Pola formularza:** e-mail (wymagane), imię (wymagane – personalizacja E0), zawód (opcjonalne, prewypełnione). Checkbox zgody marketingowej osobno, niezaznaczony. **Wynik:** strona sukcesu z zakładkami „Wzór zgody” (podgląd, pobranie PDF, pobranie DOCX [do decyzji – wersja edytowalna zwiększa użyteczność, ale wymaga utrzymania dwóch formatów]) i „Checklista” (interaktywne pola wyboru; stan zapamiętany w `localStorage` – wygoda per urządzenie, nie dane osobowe). Warianty wzoru wg zawodu to osobne pliki (np. makijaż permanentny, tatuaż, zabiegi z gr. 2) – treść do opracowania przez eksperta i zatwierdzenia przez prawnika (05, pytanie 9).

**Mechanika:** pliki PDF powstają w CI z MDX w `packages/content/dokumenty/` (stempel wersji i daty w stopce, zgodnie z zasadą „treść w repozytorium” z 02, pkt 2.5) i są publikowane jako assety statyczne. Dokument jest treścią bezpłatną – bramka ma funkcję wymiany wartości, nie zabezpieczenia, więc adres pobrania nie musi być tajny; parametr `?src=email` służy tylko atrybucji. Zapis jak w pkt 1.5.

**KPI [hipoteza]:** formularz rozpoczęty 8–15 % odwiedzin artykułu-nośnika; wysłany 60–80 % rozpoczętych; pobranie PDF 70–90 % wysłanych; potwierdzenie zgody (double opt-in) 50–70 % zaznaczonych zgód.

### 1.3 Magnes 3 – wybór: kalkulator L4 czy checklista kontroli

| Kryterium | „Kalkulator: ile tracisz na L4 jako JDG” (Utrata dochodu) | „Checklista kontroli: sanepid, ZUS, US” (Tax Protect) |
|---|---|---|
| Produkt z parametrami w briefie (A) | Nie – brak danych produktowych; oferta ma dostarczyć zespół produktowy (01, pkt 3.5) | Tak – sekcja 1 (karno-skarbowa właściciela, sumy 50 000 / 100 000 zł) i sekcja 2 (spór podatkowy, 250 000–3 000 000 zł); składki sztywne wg taryfy programu (tabela `tax_warianty`; rozstrzygnięte 11.11.2026), przy przychodach powyżej 3 mln zł – wycena indywidualna (01, pkt 3.2) |
| Natychmiastowy wynik (G) | Tak – kwota dziennego przestoju | Tak – „gotowość” per moduł, lista braków |
| Ryzyko merytoryczne | Wynik prowadzi do pytania „co dalej?”, na które bez OWU (definicja niezdolności, karencja, wyłączenia) nie ma odpowiedzi | Lista dotyczy obowiązków salonu, nie OWU; wymaga weryfikacji eksperta i prawnika, ale nie zależy od ubezpieczyciela |
| Sezonowość | I–II (zimowe L4) | I–II (podatki) oraz III–V (kontrole) – dwa okna (05, nakładka sezonowa) |
| Spójność z 05 | C1.4 – narzędzie bez bramki, CTA „zapytaj o ofertę” | G2.1 – lead magnet 2 z bramką PDF |
| Następny krok w lejku | „Zapytaj o ofertę” bez oferty | Strona `/ubezpieczenia/tax-protect` + „zapytaj o ofertę” z realnym zakresem i składkami wg taryfy programu |

**Decyzja: checklista kontroli.** Kalkulator L4 zostaje narzędziem edukacyjnym bez bramki pod `/baza-wiedzy/kalkulator-przestoju` (05) i staje się magnesem, gdy produkt „Utrata dochodu” dostanie parametry. Nazwa z zadania wymienia sanepid, ZUS i US; 05 (G2.1) wymienia sanepid / PIP / skarbową / UODO. Łączymy: jedna checklista z pięcioma modułami, trzy podstawowe (sanepid, ZUS, urząd skarbowy) i dwa rozszerzone (PIP, UODO) – do uzgodnienia z autorem 05.

| Litera | Zastosowanie |
|---|---|
| M | Właścicielka salonu 1–8 osób; szybka wygrana: w 10 minut wie, czego jej brakuje przed kontrolą |
| A | Tax Protect (Colonnade) – przejście „kontrola → spór” jest naturalnym pomostem do sekcji 2 (jeden pełny spór podatkowy w roku) i sekcji 1 (odpowiedzialność karno-skarbowa właściciela); środek lejka |
| G | Lista interaktywna online bez bramki; e-mail daje PDF, zapis postępu i przypomnienie |
| N | „Gotowość na kontrolę: sanepid, ZUS, US – checklista” |
| E | Artykuł G2.1 / B2.1 (05) → lista online → „Zapisz postęp i pobierz PDF” (e-mail, imię) → sukces → E0 kopia → seria „kontrola” (3 e-maile: co sprawdza sanepid, co ZUS, co US; czwarty: „gdy kontrola kończy się sporem” → Tax Protect) |
| T | Produkt pojawia się dopiero w ostatnim e-mailu; składki wg taryfy programu – na stronie produktu (link z e-maila), bez pitchu cenowego w serii |

**Pola:** e-mail, imię. **Wynik:** stan „X z Y pozycji” per moduł, lista braków na górze, przycisk „Drukuj / PDF”, link do `/ubezpieczenia/tax-protect`. **Mechanika:** treść listy jako JSON w `packages/content` (każda pozycja: tytuł, wyjaśnienie, podstawa / źródło [do uzupełnienia przez eksperta], moduł); stan w `localStorage`; po podaniu e-maila stan (bez PII poza adresem) zapisany w ładunku dostarczenia, żeby link z e-maila odtworzył postęp na innym urządzeniu. **KPI [hipoteza]:** rozpoczęcie listy 30–50 % odwiedzin; e-mail 10–20 % rozpoczętych; przejście na stronę Tax Protect 10–20 % subskrybentów serii.

### 1.4 Magnes 4 – „Rotacja vs pakiet: policz różnicę na własnych liczbach”

| Litera | Zastosowanie |
|---|---|
| M | Manager sieci / właścicielka zatrudniająca; szybka wygrana: jedna liczba – ile rocznie kosztuje ją rotacja – obok kosztu pakietu |
| A | Grupowe ERGO dla beauty (pakiety 58 / 68 / 76 zł za osobę miesięcznie wg cennika programu); dół lejka, CTA „Poproś o ofertę grupową” |
| G | Wynik liczony na żywo przy każdej zmianie pola |
| N | „Rotacja vs pakiet: policz różnicę na własnych liczbach” |
| E | Artykuł E1.1 (05) → kalkulator → „Wyślij podsumowanie dla wspólnika / księgowej” (e-mail, imię) → E0 z linkiem do podsumowania → 2 e-maile (moduły MediOpieki wg OWU; jak wygląda wdrożenie grupowego w małej firmie) → „Poproś o ofertę” |
| T | Oferta dopiero na prośbę; kalkulator nie twierdzi, że pakiet obniża rotację o X % – nie ma źródła |

**Pola (wszystkie liczby użytkownika, bez wartości domyślnych):** liczba pracowników; liczba odejść w ostatnich 12 miesiącach; średnia liczba dni wakatu; dzienny przychód jednego stanowiska; koszt rekrutacji na jedno stanowisko (ogłoszenia, czas); dni wdrożenia i orientacyjna produktywność w tym okresie (%). **Wynik:** roczny koszt rotacji = odejścia × (dni wakatu × dzienny przychód + koszt rekrutacji + dni wdrożenia × dzienny przychód × (1 − produktywność)); obok: roczny koszt pakietu = pracownicy × 12 × cena pakietu (wybór 58 / 68 / 76 zł, oznaczony „wg cennika programu”). Liczba „koszt rotacji ok. 15 000 zł” i argument „pakiet zamiast podwyżki 50 zł” z obecnej argumentacji sprzedażowej (01, pkt 3.3) **nie są** wbudowane jako domyślne – pojawią się jako przycisk „wczytaj przykład branżowy” wyłącznie po dostarczeniu cytowalnego źródła (05, pytanie 6).

**Mechanika:** czysta funkcja w `packages/pricing`; ceny pakietów z aktywnej wersji cennika programu (stawki sztywne; wersja z datą obowiązywania zostaje jako ślad zmian taryfy) – wymaga tabeli `pricing_group_packages` analogicznej do `pricing_oc_tiers` [propozycja uzupełnienia modelu z 02, pkt 3.1]. Podsumowanie e-mailowe to link do strony wyniku z parametrami w adresie (bez PII). **KPI [hipoteza]:** ukończenie 50–70 % rozpoczętych; e-mail 15–30 % ukończeń; prośba o ofertę 10–20 % ukończeń w sezonie XI–XII, 5–10 % poza sezonem.

### 1.5 Wspólna mechanika magnesów (Next.js / Supabase)

- **Jeden endpoint `POST /api/magnets`** obok `/api/leads` i `/api/newsletter` z 02, pkt 2.4, z tymi samymi pięcioma warstwami ochrony (Turnstile, rate limit Cloudflare, rate limit w Workerze, honeypot, walidacja Zod po stronie serwera – 02, pkt 4.4). Odpowiedź zawsze `202 {status:"accepted", resultUrl}` – brak enumeracji adresów. Ładunek wyniku ma schemat per magnes i nie zawiera PII.
- **Dane:** subskrybent w `newsletter_subscribers` (upsert po `email_normalized`, status `pending` dla nowego adresu), zgody w `consents` (nowy cel `magnet_delivery` obok istniejących – [propozycja zmiany w 02]), dostarczenia i zapisy do serii w dwóch nowych tabelach:

```sql
create table magnet_deliveries (
  id            uuid primary key default gen_random_uuid(),
  subscriber_id uuid not null references newsletter_subscribers(id) on delete cascade,
  magnet        text not null check (magnet in ('quiz-oc','zgoda-na-zabieg','checklista-kontroli','kalkulator-rotacji')),
  payload       jsonb not null,            -- wynik bez PII, np. {"group":2,"teamBand":"1","profession":"kosmetolog"}
  source_path   text, utm jsonb,
  created_at    timestamptz not null default now()
);

create table nurture_enrollments (
  id            uuid primary key default gen_random_uuid(),
  subscriber_id uuid not null references newsletter_subscribers(id) on delete cascade,
  sequence      text not null,             -- 'quiz-oc' | 'dokumentacja' | 'kontrola' | 'grupowe'
  step          smallint not null default 0,
  branch        text not null default 'default',   -- 'clicked_calc' | 'no_open' | 'replied' | 'asked_contact'
  status        text not null default 'active' check (status in ('active','paused_replied','converted','completed','unsubscribed')),
  next_send_at  timestamptz,
  created_at    timestamptz not null default now(),
  unique (subscriber_id, sequence)
);
-- anon/authenticated: brak grantów (ALTER DEFAULT PRIVILEGES z 02); zapis wyłącznie z serwera kluczem serwisowym
```

- **Dostarczenie:** funkcja SQL w jednej transakcji tworzy subskrybenta, dostarczenie, zgody i wiersz `outbox_emails` z szablonem `magnet_delivery_<slug>` (E0, wiadomość transakcyjna). Jeśli zaznaczono zgodę marketingową – E0 zawiera przycisk potwierdzenia (token hashowany, 48 h, mechanizm `/api/newsletter/confirm` z 02). Potwierdzenie ustawia `status='confirmed'`, tworzy `nurture_enrollments` i synchronizuje kontakt do Audience w Resend. Bez potwierdzenia nie wychodzi nic poza E0; niepotwierdzeni usuwani po 7 dniach (02, pkt 4.7).
- **Wysyłka serii:** Worker `beautypolisa-jobs` (Cron co 5 min, 02) pobiera zapisy z `next_send_at <= now()`, renderuje szablon z gałęzią, wysyła przez Resend z kluczem idempotencji `enrollment_id:step` i tagami, zapisuje wiersz outbox i przesuwa `step`/`next_send_at`.
- **Zatrzymanie serii:** formularz leada (`/api/leads`) z tym samym `email_normalized` → `status='converted'`; odpowiedź na e-mail → `paused_replied`; rezygnacja → `unsubscribed` i `consents.granted=false` z datą (dowód).
- **Pomiar:** zdarzenia first-party bez PII do kolektora Aura (02, decyzja 11): `magnet_view`, `magnet_start`, `magnet_complete`, `magnet_email_submitted`, `magnet_confirmed`, `nurture_sent`, `nurture_clicked`, `magnet_to_calculator`, `magnet_to_lead`; GA4 wyłącznie po zgodzie przez Zaraz.

---

## 2. Pełny lejek magnesu nr 1 (quiz grup ryzyka)

### 2.1 Landing `/baza-wiedzy/quiz-grupy-ryzyka`

Układ od góry: nagłówek i podtytuł → widżet quizu (karta „glass” z fallbackiem, 01, pkt 8.6) → 3 korzyści → dowód → FAQ (z `FAQPage`, 04) → stopka z informacją dystrybutora. Formularz e-mail pojawia się dopiero na ekranie wyniku.

| Element | Treść |
|---|---|
| H1 (wariant A) | Sprawdź, czy Twoje zabiegi mieszczą się w programie OC dla beauty |
| H1 (wariant B, test A/B) | W której grupie ryzyka są Twoje zabiegi? |
| Podtytuł | Zaznacz zabiegi, które wykonujesz. W 60 sekund zobaczysz, do której z 4 grup ryzyka programu ERGO Hestii trafiają, jaka jest składka roczna wg taryfy programu i czy potrzebna jest indywidualna ocena. Bez podawania e-maila. |
| Korzyść 1 | Wynik od razu na ekranie – bez PDF-a i czekania na skrzynkę. |
| Korzyść 2 | Lista zabiegów z programu, nie ogólniki: od manicure i rzęs po HIFU, nici PDO i laser ablacyjny. |
| Korzyść 3 | Składka roczna wg taryfy programu (od 400 zł/rok w grupie 1) i jasna informacja, kiedy potrzebna jest ocena indywidualna. |
| Dowód (fakty, bez opinii) | Program OC dla branży beauty realizowany z Sopockim TU ERGO Hestia S.A. (nr WA50/003353/24/A) we współpracy z Fundacją Beauty Razem; dystrybutor: Aura Expert sp. z o.o. [status – agent czy broker – do potwierdzenia]; 4 grupy ryzyka i 3 sumy gwarancyjne (100 000 / 200 000 / 300 000 zł). Opinie klientów pojawią się dopiero, gdy będą prawdziwe i za zgodą autorów – do tego czasu sekcja „dowód” zawiera wyłącznie fakty o programie. |
| CTA główne | Zacznij quiz |
| FAQ 1 | **Czy wynik quizu oznacza, że mam ochronę?** Nie. Quiz pokazuje, do której grupy ryzyka programu należą Twoje zabiegi i jaka jest składka roczna wg taryfy programu. Informacja nie stanowi oferty w rozumieniu art. 66 Kodeksu cywilnego; zakres ochrony określają OWU, a zawarcie umowy poprzedza ocena wniosku (ankieta pyta m.in. o NIP, REGON, datę rozpoczęcia działalności, liczbę zatrudnionych, szkodowość z 3 lat, zabiegi wysokiego ryzyka, formularze zgody i kwalifikacje personelu). |
| FAQ 2 | **Co z zabiegami z grupy 4?** HIFU, toksyna botulinowa, PRP, PLASMA, kwas hialuronowy, nici PDO, lipoliza iniekcyjna i laser ablacyjny wymagają indywidualnej oceny. Quiz nie poda składki – przekieruje Cię do formularza „poproś o indywidualną ocenę”. |
| FAQ 3 | **Czy muszę podać e-mail?** Nie. E-mail jest opcjonalny – wyślemy kopię wyniku, a jeśli zaznaczysz osobną zgodę i potwierdzisz ją w wiadomości, dostaniesz 4 krótkie e-maile o OC. Rezygnacja jednym kliknięciem w każdej wiadomości. |

### 2.2 Strona sukcesu (po podaniu e-maila)

Nagłówek: „Gotowe. Wynik masz poniżej, kopia leci na {e-mail}.” Pod nim powtórzona karta wyniku (grupa, składka roczna wg taryfy programu lub informacja o ocenie indywidualnej), CTA główne **Policz dokładną składkę** (kalkulator prewypełniony), CTA drugorzędne **Lista zabiegów w grupie {N}**. Jeśli zaznaczono zgodę marketingową: ramka „W e-mailu znajdziesz przycisk potwierdzenia – bez kliknięcia nie wyślemy nic więcej.” Jeśli nie zaznaczono: brak ponownej prośby o zgodę (bez „czy na pewno?”). Pod spodem: skrócona informacja dystrybutora i link do `/rodo`. Żadnego licznika, pop-upu ani komunikatu w stylu „nie, nie chcę chronić swojego salonu”.

### 2.3 E-mail dostarczający (E0)

Wiadomość transakcyjna: dostarcza zamówiony wynik, nie zawiera oferty. Wariant z potwierdzeniem – gdy zaznaczono zgodę; wariant bez – gdy nie.

| Pole | Treść |
|---|---|
| Nadawca | Imię i nazwisko brokera, BeautyPolisa (05, decyzja 6 – imienny nadawca) |
| Temat (≤ 50) | Twój wynik quizu: grupa ryzyka i następny krok |
| Preheader (≤ 90) | Grupa {N}, składka roczna od {X} zł wg taryfy programu. Pełna lista zabiegów w środku. |

Treść:

> Cześć {imię},
>
> dziękuję za wypełnienie quizu. Oto wynik dla zabiegów, które zaznaczyłaś/eś:
>
> **Grupa ryzyka {N} programu OC dla branży beauty (ERGO Hestia).** Składka roczna wg taryfy programu: od **{X} zł/rok** przy sumie gwarancyjnej 100 000 zł; klauzula ochrony prawnej +92 zł. Wyższe sumy: 200 000 i 300 000 zł. {Jeśli grupa 4 lub zespół 9+: Twoje zabiegi lub wielkość zespołu wymagają indywidualnej oceny – kalkulator nie poda składki, ale broker może to policzyć po krótkiej rozmowie.}
>
> Wynik nie jest potwierdzeniem ochrony – zakres wynika z OWU i oceny wniosku. Pełną listę zabiegów w Twojej grupie i wynik masz pod tym linkiem: {link do strony wyniku}.
>
> {Wariant ze zgodą:} Zaznaczyłaś/eś, że chcesz dostać 4 krótkie e-maile o OC w branży beauty (co oznacza grupa, jak wygląda roszczenie, jak policzyć składkę, co dalej). Żeby je wysłać, potrzebuję jednego kliknięcia:
>
> **[Tak, chcę serię 4 e-maili]**
>
> Bez kliknięcia nie wyślę nic więcej. {Wariant bez zgody: Na tym kończę – nie wyślę kolejnych wiadomości, chyba że sama/sam o to poprosisz.}
>
> {podpis brokera}
> Aura Expert sp. z o.o., ul. Bolkowska 2A/28, 01-466 Warszawa · {status dystrybutora – do potwierdzenia} · Informacje o dystrybutorze: beautypolisa.eu/o-nas · Polityka prywatności: beautypolisa.eu/rodo

(ok. 190 słów; jeden przycisk CTA zależny od wariantu).

### 2.4 Sekwencja pielęgnująca E1–E4

Harmonogram liczony od potwierdzenia zgody: E1 +2 dni, E2 +5, E3 +9, E4 +14. Jedna CTA w każdej wiadomości. Gałęzie:

| Gałąź | Sygnał | Działanie |
|---|---|---|
| Kliknął kalkulator | zdarzenie `nurture_clicked` z linku do `/kalkulator/oc` lub wejście na kalkulator z `?src=nurture` | E3 zastąpiony przez E3b („masz wycenę – co dalej?”), E4 bez zmian |
| Nie otworzył | brak `email.opened` i `email.clicked` dla E1 przez 72 h (otwarcia są niewiarygodne przy ochronie prywatności w klientach pocztowych – traktujemy jako wskazówkę, decydują kliknięcia) | E1b – ten sam tekst, nowy temat „Grupa ryzyka: 3 rzeczy, które warto wiedzieć” (+3 dni); brak reakcji na E1b i E2 → seria przechodzi od razu do E4 i kończy się |
| Odpowiedział | wiadomość przychodząca na adres nadawcy (skrzynka brokera, M365) | `status='paused_replied'`; broker odpowiada w ≤ 1 dzień roboczy; automat milczy |
| Poprosił o kontakt | formularz leada (`/api/leads`) z tym samym adresem lub kliknięcie „Umów rozmowę” | `status='converted'`; dalej przepływ leada z 02, pkt 2.2 (zgoda telefoniczna zbierana w formularzu) |

**E1 (+2 dni) – szybka wygrana**

| Temat (≤ 50) | Co właściwie obejmuje OC w Twojej grupie |
|---|---|
| Preheader (≤ 90) | Grupa to poziom składki, nie zakres ochrony. Trzy rzeczy, które warto sprawdzić. |

> Cześć {imię},
>
> w quizie wyszła grupa {N}. Wyjaśnię, co to oznacza, bo często jest mylone.
>
> **Grupa to poziom składki.** Program dzieli zabiegi na cztery grupy wg ryzyka – od fryzjerstwa, kosmetyki pielęgnacyjnej, manicure i rzęs (gr. 1), przez makijaż permanentny, mezoterapię, lasery nieablacyjne, IPL, tatuaż i peelingi chemiczne (gr. 2), po podologię (gr. 3). Gr. 4 to zabiegi oceniane indywidualnie.
>
> **Zakres ochrony to OWU, nie grupa.** OC zawodowe odpowiada za szkody wyrządzone klientce w związku z zabiegiem – granice, wyłączenia i obowiązki są w ogólnych warunkach, które znajdziesz na beautypolisa.eu/dokumenty.
>
> **Trzy parametry do wyboru:** suma gwarancyjna (100 000 / 200 000 / 300 000 zł), klauzula ochrony prawnej (+92 zł/rok) i liczba osób w zespole (powyżej 8 – wycena indywidualna).
>
> Jeśli któryś zabieg z Twojej listy budzi wątpliwość, do której grupy należy – odpisz, sprawdzę.
>
> **[Zobacz pełną listę zabiegów w grupie {N}]**
>
> {podpis, stopka dystrybutora, link rezygnacji}

(ok. 150 słów)

**E2 (+5 dni) – dowód**

| Temat (≤ 50) | Jak wygląda roszczenie po zabiegu – krok po kroku |
|---|---|
| Preheader (≤ 90) | Bez straszenia: co dzieje się po zgłoszeniu i jaką rolę gra dokumentacja. |

> Cześć {imię},
>
> nie będę opowiadać historii o zrujnowanych salonach – nie mamy takich, które moglibyśmy uczciwie zacytować. Zamiast tego proces, krok po kroku, tak jak wygląda po stronie ubezpieczonego.
>
> 1. **Zgłoszenie.** Klientka zgłasza powikłanie lub niezadowolenie z efektu. Ty zgłaszasz zdarzenie do ubezpieczyciela – przez brokera, formularz na beautypolisa.eu/szkoda lub bezpośrednio.
> 2. **Dokumentacja.** Ubezpieczyciel prosi o kartę zabiegu, zgodę klientki na zabieg, zdjęcia, opis produktów. To moment, w którym zgoda „na kolanie” zaczyna kosztować.
> 3. **Ocena.** Likwidator ustala, czy zdarzenie mieści się w zakresie OWU i czy zachowano obowiązki (kwalifikacje, procedury).
> 4. **Decyzja i wypłata** albo odmowa z uzasadnieniem, od której można się odwołać.
>
> Na stronie /szkoda opisaliśmy, co przygotować przed zgłoszeniem, żeby nie szukać dokumentów po fakcie. Wzór zgody na zabieg i checklistę dokumentacji dostaniesz tam bezpłatnie.
>
> **[Zobacz, jak wygląda zgłoszenie szkody]**
>
> {podpis, stopka dystrybutora, link rezygnacji}

(ok. 170 słów; opis procesu do weryfikacji przez brokera z OWU)

**E3 (+9 dni) – miękki następny krok**

| Temat (≤ 50) | Policz składkę w 2 minuty (bez zobowiązań) |
|---|---|
| Preheader (≤ 90) | Kalkulator ma już Twoją grupę. Zobaczysz składkę wg taryfy i listę rzeczy do wniosku. |

> Cześć {imię},
>
> masz grupę ryzyka z quizu, więc kalkulator na beautypolisa.eu/kalkulator/oc wypełni się sam. Wybierasz sumę gwarancyjną, decydujesz o klauzuli ochrony prawnej, podajesz liczbę osób – i widzisz składkę roczną wg taryfy programu.
>
> Co dalej, jeśli kwota ma sens? Wniosek do ERGO Hestii wymaga kilku danych: NIP, REGON, data rozpoczęcia działalności, liczba zatrudnionych, szkodowość z ostatnich 3 lat, lista zabiegów wysokiego ryzyka, formularze zgody na zabieg i kwalifikacje personelu. Większość masz pod ręką, resztę pomogę skompletować.
>
> Nie ma tu zakupu online – wynik kalkulatora możesz po prostu zapisać. Jeśli zostawisz kontakt, odezwę się w ciągu jednego dnia roboczego, nie wcześniej niż chcesz.
>
> **[Policz składkę dla grupy {N}]**
>
> {podpis, stopka dystrybutora, link rezygnacji}

(ok. 150 słów)

**E3b (+9 dni, gałąź „kliknął kalkulator”)**

| Temat (≤ 50) | Twoja wycena czeka – masz pytania? |
|---|---|
| Preheader (≤ 90) | Kalkulator policzył składkę. Trzy pytania, które najczęściej padają po tym kroku. |

> Cześć {imię},
>
> kalkulator pokazał Ci kwotę. Po tym kroku najczęściej słyszę trzy pytania: czy pracownice są objęte tą samą polisą (w programie liczy się liczba osób wykonujących zabiegi), czy warto brać wyższą sumę niż 100 000 zł (zależy od zabiegów i liczby klientek – to rozmowa, nie reguła) oraz co, jeśli robię też zabieg z grupy 4 (wtedy ocena indywidualna całego wniosku).
>
> Jeśli któreś z nich jest Twoje – odpisz albo zostaw numer, oddzwonię w dogodnej porze.
>
> **[Zadaj pytanie brokerowi]**
>
> {podpis, stopka dystrybutora, link rezygnacji}

(ok. 110 słów; odpowiedzi na pytania do weryfikacji z OWU przez brokera)

**E4 (+14 dni) – zamknięcie serii**

| Temat (≤ 50) | Ostatni e-mail z tej serii – co dalej? |
|---|---|
| Preheader (≤ 90) | Trzy możliwości i żadnej presji. Nie wyślę kolejnych wiadomości bez Twojej decyzji. |

> Cześć {imię},
>
> to ostatnia wiadomość z serii o OC. Masz trzy możliwości i każda jest w porządku:
>
> **Rozmowa z brokerem.** Jeśli chcesz przejść od składki z kalkulatora do oferty i wniosku, zostaw kontakt – zadzwonię lub odpiszę w ciągu jednego dnia roboczego, w porze, którą wskażesz.
>
> **Zostajesz na liście.** Zgoda, którą potwierdziłaś/eś, obejmuje też okazjonalne aktualizacje (zmiany w programie, nowe wzory dokumentów, terminy kontroli sezonowych). Jeśli to wystarczy – nie musisz nic robić.
>
> **Nic.** Rezygnacja jest jednym kliknięciem na dole i działa od razu.
>
> Dziękuję za czas poświęcony quizowi i tym wiadomościom.
>
> **[Umów rozmowę z brokerem]**
>
> {podpis, stopka dystrybutora, link rezygnacji}

(ok. 120 słów)

### 2.5 Mechanika w Resend

Resend jest już skonfigurowany w strefie (`send.`/`links.`, DKIM – 01, pkt 6); portal używa własnego klucza API ograniczonego do wysyłki (02, pkt 4.5). Logika serii żyje w Supabase (pkt 1.5); Resend odpowiada za dostarczenie, zdarzenia i listę rezygnacji.

| Element Resend | Użycie |
|---|---|
| Audience „BeautyPolisa – portal” | Lustro potwierdzonych subskrybentów (e-mail, imię, właściwości: `profession`, `risk_group`, `magnet_last`, `consent_version`, `stage`); flaga `unsubscribed` jest listą blokującą dla wszystkich wysyłek |
| Tematy / segmenty (jeśli dostępne w planie – [do weryfikacji]) | „Seria OC”, „Dokumentacja”, „Kontrola”, „Grupowe”, „Aktualizacje” – odbiorca wybiera zakres na stronie preferencji zamiast rezygnować ze wszystkiego |
| Tagi na każdej wiadomości | `sequence`, `step`, `branch`, `magnet`, `variant` (A/B) – wracają w webhookach i pozwalają liczyć lejek bez PII |
| Webhook `POST /api/webhooks/resend` | Weryfikacja podpisu (nagłówki Svix: id, timestamp, signature), zapis zdarzenia, decyzja o gałęzi |
| Nagłówki `List-Unsubscribe` i `List-Unsubscribe-Post` | Rezygnacja jednym kliknięciem z poziomu klienta pocztowego; link w stopce prowadzi do `/rezygnacja?t=` |
| Klucz idempotencji | `enrollment_id:step` – ponowienie z Cron nie zdubluje wiadomości |

Przykładowe wywołanie wysyłki (bez sekretów):

```json
{
  "from": "Imię Nazwisko · BeautyPolisa <imie.nazwisko@send.beautypolisa.eu>",
  "to": ["subskrybent@example.com"],
  "reply_to": "imie.nazwisko@auraexpert.example",
  "subject": "Co właściwie obejmuje OC w Twojej grupie",
  "html": "<!-- szablon E1 z gałęzi default -->",
  "text": "…",
  "headers": {
    "List-Unsubscribe": "<https://beautypolisa.eu/rezygnacja?t=TOKEN>, <mailto:rezygnacja@send.beautypolisa.eu>",
    "List-Unsubscribe-Post": "List-Unsubscribe=One-Click",
    "Idempotency-Key": "ENROLLMENT_UUID:1"
  },
  "tags": [
    { "name": "sequence", "value": "quiz-oc" },
    { "name": "step", "value": "1" },
    { "name": "branch", "value": "default" },
    { "name": "variant", "value": "A" }
  ]
}
```

Obsługa zdarzeń z webhooka:

| Zdarzenie | Zapis | Wpływ na serię |
|---|---|---|
| `email.delivered` | `outbox_emails.status='sent'`, zdarzenie `nurture_sent` | – |
| `email.opened` | zdarzenie (wskazówka) | zdejmuje gałąź „nie otworzył” |
| `email.clicked` | zdarzenie z adresem docelowym (bez PII w metrykach) | link do kalkulatora → gałąź `clicked_calc`; link „Umów rozmowę” → oczekiwanie na lead |
| `email.bounced` (twardy) | `status='unsubscribed'`, kontakt oznaczony | koniec serii, adres wykluczony |
| `email.complained` | jak wyżej + `consents.granted=false` | koniec; adres na liście blokującej |
| `contact.updated` z `unsubscribed=true` | synchronizacja do `consents` | koniec serii |

Odrzucone: prowadzenie serii w Broadcasts / Automations Resend jako silniku (rozgałęzianie na zdarzenia z kalkulatora i formularza leada wymaga danych, które są w Supabase; zgody i ich wersje też); zewnętrzny ESP (kolejny procesor PII i kopia bazy). Do rewizji, jeśli Automations Resend obejmą warunki na zdarzeniach zewnętrznych.

### 2.6 Zgody i prawo

**Trzy osobne elementy przy formularzu** (kolejność: informacja → zgoda e-mail → zgoda telefon). Treści przykładowe – **do weryfikacji przez prawnika**; administratorem danych jest Aura Expert sp. z o.o. (decyzja zleceniodawcy z 12.11.2026), kontakt do IOD – do potwierdzenia (02, pytanie 1). Identyfikator wersji tekstu (np. `rodo-v1-2026-11`) trafia do `consents.text_version` (02). Jeżeli zgody marketingowe zebrane dotąd (stara strona, CRM Aura) wskazują spółkę pod nazwą wycofaną decyzją z 12.11.2026 (pełna nazwa – w historii repozytorium, wersja sprzed 12.11.2026; 01, pkt 2), prawnik musi potwierdzić, czy pozostają ważne dla Aura Expert sp. z o.o., czy trzeba je zebrać ponownie.

1. **Informacja RODO** (tekst stale widoczny pod formularzem; checkbox „zapoznałam/em się” tylko jeśli prawnik tego wymaga – nie jest zgodą):

> Administratorem Twoich danych jest Aura Expert sp. z o.o., ul. Bolkowska 2A/28, 01-466 Warszawa. Adres e-mail, imię i wynik quizu przetwarzamy, aby dostarczyć Ci zamówiony wynik i – jeśli wyrazisz zgodę – wysyłać informacje o ubezpieczeniach dla branży beauty. Podstawa: podjęcie działań na Twoje żądanie (art. 6 ust. 1 lit. b RODO) [alternatywnie lit. f – do rozstrzygnięcia] oraz Twoja zgoda (art. 6 ust. 1 lit. a RODO). Dane przechowujemy do wycofania zgody, a niepotwierdzone adresy usuwamy po 7 dniach. Masz prawo dostępu, sprostowania, usunięcia, ograniczenia, przenoszenia, sprzeciwu i skargi do Prezesa UODO. Pełna informacja: beautypolisa.eu/rodo.

2. **Zgoda na e-mail** (checkbox, domyślnie odznaczony, niewymagany do otrzymania wyniku):

> ☐ Chcę otrzymywać od Aura Expert sp. z o.o. na podany adres e-mail informacje o ubezpieczeniach dla branży beauty: serię 4 wiadomości o OC oraz okazjonalne aktualizacje. Zgodę mogę wycofać w każdej chwili linkiem w wiadomości.

Podstawa wskazana w zadaniu: art. 10 ustawy o świadczeniu usług drogą elektroniczną. **Uwaga [hipoteza – do weryfikacji przez prawnika]:** od 10.11.2024 r. obowiązuje Prawo komunikacji elektronicznej, które zastąpiło art. 172 Prawa telekomunikacyjnego i uchyliło art. 10 u.ś.u.d.e. – zgoda na komunikację marketingową opiera się obecnie na art. 398 PKE. Treść klauzuli i odwołanie do przepisu ma ustalić prawnik; mechanika (osobny checkbox, dowód w `consents`, double opt-in) nie zależy od tego, który przepis zostanie wskazany.

3. **Zgoda na kontakt telefoniczny** (checkbox wyłącznie tam, gdzie zbieramy numer: formularz leada, „Umów rozmowę”; w quizie numeru nie ma, więc checkbox nie występuje):

> ☐ Wyrażam zgodę na kontakt telefoniczny ze strony Aura Expert sp. z o.o. pod podanym numerem w celu przedstawienia informacji o ubezpieczeniach dla branży beauty. Zgodę mogę wycofać w każdej chwili.

Podstawa wskazana w zadaniu: art. 172 Prawa telekomunikacyjnego – ta sama uwaga o PKE jak wyżej.

**Reguły projektowe (anty-ciemne wzorce):** żadne pole zgody nie jest zaznaczone domyślnie; zgody nie są łączone w jeden checkbox ani z regulaminem; wynik i dokumenty są dostępne bez zgody marketingowej; przyciski „Zacznij quiz” i „Pomiń e-mail” mają tę samą wagę wizualną; brak liczników, komunikatów „tylko dziś”, „zostało 3 miejsc”, „inni już sprawdzili”; brak fałszywych powiadomień o aktywności; rezygnacja jednym kliknięciem i strona `/rezygnacja` bez logowania; potwierdzenie rezygnacji bez próby zatrzymania; strona preferencji zamiast „wszystko albo nic”; w e-mailach stopka z pełną nazwą administratora i adresem.

**Obowiązki informacyjne dystrybutora (ustawa o dystrybucji ubezpieczeń) – gdzie w lejku** [zakres do weryfikacji przez prawnika; treść zależy od statusu broker vs agent – 01, pkt 2]:

| Obowiązek | Etap lejka | Miejsce |
|---|---|---|
| Firma, adres, status dystrybutora (broker / agent), wpis do rejestru KNF i sposób jego weryfikacji | każdy kontakt z treścią | stopka wszystkich stron i e-maili (skrót) + `/o-nas#dystrybutor` (pełna treść) |
| Charakter wynagrodzenia (prowizja / honorarium); dla brokera – czy udziela porady na podstawie rzetelnej analizy; dla agenta – zakłady, na rzecz których działa | przed propozycją umowy | `/o-nas#dystrybutor`; strona sukcesu formularza leada; pierwsza wiadomość brokera do leada |
| Procedura reklamacji i pozasądowe rozwiązywanie sporów (Rzecznik Finansowy) | j.w. | `/o-nas#dystrybutor`, `/kontakt`, stopka e-maili serii (link) |
| OWU i dokument informacyjny o produkcie (IPID) przed zawarciem umowy | strona produktowa / kontakt z brokerem | `/dokumenty` z wersjami OWU (05), link ze stron produktowych i z E1/E3 |
| Analiza potrzeb klienta przed zaproponowaniem umowy | rozmowa brokera | poza portalem (proces Aura); formularz leada zbiera tylko dane kontekstowe, nie zastępuje analizy (02, decyzja 10) |
| Zastrzeżenie: treści portalu i kalkulator to informacja, nie oferta w rozumieniu art. 66 Kodeksu cywilnego; zakres ochrony określają OWU | kalkulator, quiz, e-maile | adnotacja pod każdym wynikiem i w stopce E0–E4 |

Landing magnesu sam w sobie nie jest czynnością dystrybucyjną, ale pochodzi od dystrybutora – stąd skrócona informacja w stopce każdej strony. Pełne obowiązki „przed zawarciem umowy” realizuje broker w pierwszym kontakcie; portal ma zapewnić, że klient wcześniej widział, kim jest dystrybutor i gdzie są OWU.

---

## 3. Kampania startowa portalu (30 dni)

Rama „Canva creator” ma sześć etapów: brief → kalendarz → inwentarz zasobów → projekty Canva → copy → kolejkowanie. **Ten dokument dostarcza etapy 1–3 i 5 (brief, kalendarz, inwentarz, copy). Etapy 4 i 6 – generowanie projektów w Canva oraz kolejkowanie publikacji – wymagają osobnej, wyraźnej zgody właściciela oraz dostępu do kont Canva, Meta Business Suite, LinkedIn i Resend; nie są częścią tej koncepcji i nie zostały wykonane.**

### 3.1 Brief kampanii

| Pole | Treść |
|---|---|
| Cel | (1) Uruchomić portal jako pierwotne źródło informacji o programie OC dla branży beauty (01, pkt 7 – brak publicznych źródeł); (2) zbudować bazę e-mail z potwierdzoną zgodą; (3) pierwsze leady OC przez kalkulator. Mierniki w pkt 4.1 |
| Grupa | Persony z 05: właścicielka salonu 1–8 osób, kosmetolog JDG, fryzjer, linergistka, stylistka paznokci, tatuażysta; wtórnie manager sieci (LinkedIn) |
| Przekaz główny | „Wiesz, w której grupie ryzyka są Twoje zabiegi? Sprawdź w 60 sekund.” |
| Przekazy wspierające | Program OC z ERGO Hestią we współpracy z Fundacją Beauty Razem; dokumenty, których używa się w salonie (zgoda, checklisty); bez sprzedaży online – rozmowa z brokerem wtedy, gdy klient chce |
| Ton | Ekspercki, ciepły, konkretny. Mówimy „Ty”, unikamy form rodzajowych tam, gdzie się da („Twoje zabiegi”, „wykonujesz”). Zakaz straszenia („jedno roszczenie zrujnuje Twój salon”), pilności, wykrzykników, emoji w nadmiarze |
| Elementy marki (01, pkt 2) | Granat `#2a3b69` – tła i typografia; róż `#e11d48` – akcent CTA, maks. ok. 10 % powierzchni; tło `#fafafa`; tekst `#1e293b`; tryb ciemny `#0f172a` (Stories); Montserrat Bold (nagłówki) / Regular i Medium (treść); logo poziome PNG z repo (`BeautyPolisa_logo_podstawowe_poziome.png`) – brak wersji białej i monochromatycznej [luka] |
| Ubezpieczyciele i partnerzy jako dowód | ERGO Hestia (program nr WA50/003353/24/A), Colonnade, ENEL-MED, LUX MED, Fundacja Beauty Razem – **wyłącznie jako nazwy tekstowe** do czasu potwierdzenia umownego zasad użycia logotypów i treści (05, pytanie 2) |
| Kanały | Instagram (feed, Reels, Stories), Facebook (strona), LinkedIn (strona Aura Expert + profil brokera [założenie]), e-mail (tylko adresy z udokumentowaną zgodą) |
| Zakazy | Ceny inne niż z cennika programu (kwoty zawsze jako „składka wg taryfy programu”, z zastrzeżeniem art. 66 KC i odwołaniem do OWU w nocie dystrybutora lub stopce); składki Tax Protect spoza taryfy wariantów (`tax_warianty`) i kwoty przy przychodach powyżej 3 mln zł (tam wyłącznie „wycena indywidualna”); obietnice ochrony; wymyślone opinie i „historie klientek”; liczby bez źródła (koszt rotacji 15 000 zł); logotypy partnerów; grafiki z generowanymi osobami przedstawianymi jako klientki lub zespół |
| Zgody | Posty organiczne – bez dodatkowych; e-maile kampanii C1–C3 – wyłącznie do subskrybentów portalu z potwierdzoną zgodą oraz do kontaktów z CRM Aura **tylko po audycie zgód** (01, pkt 5.2: `crm_companies`, `email_messages` – status zgód nieznany) |
| Budżet mediowy | Brak płatnych kampanii w pierwszych 30 dniach [założenie]; decyzja o Meta Ads po danych z lejka i wdrożeniu zgód na piksele przez Zaraz (02) |

### 3.2 Kalendarz 30 dni

Dzień 1 = dzień uruchomienia portalu (data nieznana – 05 zakłada styczeń). Ścieżka „Canva (social)” = projekt graficzny z szablonu (pkt 3.3); „Tylko tekst” = post bez grafiki lub nagranie własne. Kolumna „Uwagi” oznacza konflikty (K) i sezonowość (S).

| Dzień | Kanał | Ścieżka | Temat | Typ zasobu | Kąt copy | Uwagi |
|---|---|---|---|---|---|---|
| 1 | Instagram feed | Canva (social) | Startujemy: portal BeautyPolisa | post 1080×1080 (szablon A) | dlaczego powstał – pierwotne źródło o programie OC | caption 1 |
| 1 | Facebook | Canva (social) | j.w. (ten sam projekt) | post 1080×1080 | j.w. | reuse projektu |
| 1 | LinkedIn | Tylko tekst | Start portalu z perspektywy brokera | post tekstowy | branża bez publicznego źródła o programie | post LI 1 |
| 2 | Instagram Stories | Canva (social) | Quiz: 4 grupy ryzyka | 3 klatki 1080×1920 + link | „zaznacz zabiegi, zobacz grupę” | tryb ciemny `#0f172a` |
| 3 | E-mail | Tylko tekst | C1 „Startujemy…” | e-mail | quiz + co znajdziesz na portalu | **K:** tylko adresy ze zgodą; CRM po audycie |
| 4 | Instagram feed | Canva (social) | Cztery grupy ryzyka zabiegów | karuzela 5 slajdów (szablon B) | edukacja, lista zabiegów per grupa | caption 2; **S:** ever-green |
| 5 | Facebook | Tylko tekst | „Czy stylistka paznokci musi mieć OC?” | post-pytanie | dyskusja, odpowiedź w komentarzu z linkiem do A1.1 | bez twierdzeń prawnych o obowiązku |
| 6 | Instagram Reels | Tylko tekst (scenariusz) | Hook 1: mezoterapia vs fryzjerka | Reels 15 s, nagranie własne | grupa ryzyka to nie to samo OC | okładka z szablonu A |
| 8 | Instagram feed | Canva (social) | Co przygotować do wniosku OC | post 1080×1080 | lista z ankiety (NIP, REGON, szkodowość 3 lat, zgody, kwalifikacje) | link do A3.1 |
| 9 | LinkedIn | Tylko tekst | Odpowiedzialność karno-skarbowa właściciela | post tekstowy | Tax Protect sekcja 1 i 2 – składki wg taryfy na stronie produktu | post LI 2; **S:** I–II podatki |
| 10 | Instagram Stories | Canva (social) | Pytanie dnia: uczulenie na farbę | 2 klatki z naklejką pytania | zbieramy pytania do FAQ | odpowiedzi tylko ogólne, bez oceny przypadków |
| 11 | Facebook | Canva (social) | Co przygotować do wniosku OC | post 1080×1080 (reuse z dnia 8) | j.w. | reuse |
| 12 | E-mail | Tylko tekst | C2 „Zgoda na zabieg…” | e-mail | magnes 2 | **K:** publikacja dopiero po zatwierdzeniu wzoru przez prawnika |
| 13 | Instagram feed | Canva (social) | Zgoda na zabieg: 7 elementów | karuzela 5 slajdów | co powinna zawierać zgoda, dlaczego pyta o nią ankieta OC | caption 3; **K:** j.w. |
| 14 | Instagram Reels | Tylko tekst (scenariusz) | Hook 2: trzy rzeczy, o które zapyta ubezpieczyciel | Reels 15 s | szkodowość, zabiegi wysokiego ryzyka, zgody | – |
| 15 | – | – | Przegląd KPI połowy kampanii | – | korekta dni 16–30 wg danych | wewnętrzne |
| 16 | Instagram feed | Canva (social) | Jak zgłosić szkodę – 4 kroki | post 1080×1080 | proces, nie strach | caption 4; treść do weryfikacji z OWU |
| 17 | Facebook | Canva (social) | j.w. (reuse) | post 1080×1080 | j.w. | reuse |
| 18 | Instagram Stories | Canva (social) | Kto odpowiada na Wasze pytania | 3 klatki | broker imiennie (E-E-A-T, 05) | **K:** wymaga zdjęcia zespołu – luka |
| 19 | LinkedIn | Tylko tekst | Czego nauczyliśmy się po 2 tygodniach portalu | post tekstowy | tylko realne dane z lejka; bez liczb – bez posta | zależny od dnia 15 |
| 20 | Instagram feed | Canva (social) | Kontrola w salonie: sanepid, ZUS, US | karuzela 5 slajdów | magnes 3; Tax Protect jako „co, jeśli spór” | caption 5; **K:** po weryfikacji prawnej listy; **S:** I–II, III–V |
| 22 | Instagram Reels | Tylko tekst (scenariusz) | Hook 3: zespół do 8 osób – jedna polisa | Reels 15 s | próg 8 osób, wycena indywidualna | – |
| 23 | Facebook | Canva (social) | Zespół do 8 osób – jedna polisa OC | post 1080×1080 | właścicielki zatrudniające | – |
| 24 | E-mail | Tylko tekst | C3 „Kontrola w salonie…” | e-mail | magnes 3 | **K:** jak dzień 20 |
| 25 | Instagram feed | Canva (social) | Grupowe ERGO dla beauty – od 58 zł/os./mies. | post 1080×1080 | benefity w małym salonie, moduły MediOpieki | caption 6; cena „wg cennika programu”; **S:** priorytet XI–XII; przy starcie we IX zamienić na edukację NNW dzieci |
| 26 | Instagram Stories | Canva (social) | Q&A: Wasze pytania o OC | 3 klatki z odpowiedziami | odpowiedzi z dnia 10 | ogólne, bez oceny przypadków |
| 27 | LinkedIn | Tylko tekst | Benefity a rotacja – jak policzyć na własnych liczbach | post tekstowy | kalkulator rotacji (magnes 4) | bez liczby 15 000 zł |
| 28 | Instagram feed | Canva (social) | Najczęstsze pytanie miesiąca | post 1080×1080 | odpowiedź z FAQ portalu | – |
| 29 | Facebook | Tylko tekst | Zaproszenie do rozmowy z brokerem | post | bez pilności, z informacją o dystrybutorze | – |
| 30 | Instagram feed | Canva (social) | 30 dni BeautyPolisa – co dalej | post 1080×1080 | podziękowanie, zapowiedź kalendarza treści z 05 | – |

Razem: 17 pozycji Canva, 3 e-maile, 4 posty LinkedIn, 3 Reels, 3 posty tekstowe FB. Reguły konfliktów: maks. jeden e-mail tygodniowo do całej bazy (seria nurture liczy się osobno, bo trafia do osób, które o nią poprosiły); Reels i post w feedzie nie tego samego dnia; żadna publikacja o magnesach 2 i 3 przed zatwierdzeniem prawnym dokumentów; przy innym terminie startu przesuwamy pozycje oznaczone S zgodnie z nakładką sezonową z 05.

### 3.3 Inwentarz slotów szablonów i tabela luk

**Szablon A – post kwadratowy 1080×1080**

| Slot | Typ | Specyfikacja | Treść przykładowa (dzień 1) |
|---|---|---|---|
| `Hero_Image` | obraz | 1080×1080, bezpieczny obszar tekstu 880×880; nakładka granat `#2a3b69` 55–65 % krycia | zdjęcie stanowiska pracy w salonie (dłonie, narzędzia) – brak w repo |
| `Headline` | tekst | ≤ 40 znaków, Montserrat Bold 64–72 px, biały | „W której grupie są Twoje zabiegi?” |
| `Subline` | tekst | ≤ 90 znaków, Montserrat Regular 30–34 px, biały 90 % | „Quiz: 60 sekund, bez e-maila. beautypolisa.eu” |
| `Logo` | obraz | wersja biała na granacie, wys. 72 px, prawy dolny róg | wymaga wersji białej – luka |

**Szablon B – karuzela 5 slajdów 1080×1350**

| Slajd | Sloty | Specyfikacja |
|---|---|---|
| 1 (okładka) | `Cover_Title` (≤ 50 zn.), `Cover_Sub` (≤ 80 zn.), `Logo`, `Swipe_Hint` | tło granat, akcent różowy pasek, typografia jak w A |
| 2–4 (treść) | `Slide_Number`, `Slide_Title` (≤ 40 zn.), `Slide_Body` (≤ 60 słów), `Slide_Icon` | tło `#fafafa`, tekst `#1e293b`, ikona liniowa granatowa 160 px |
| 5 (CTA) | `CTA_Title` (≤ 40 zn.), `CTA_Text` (≤ 90 zn.), `URL`, `Logo`, `Distributor_Note` (≤ 120 zn.) | tło granat; nota dystrybutora: „Aura Expert sp. z o.o. – [status do potwierdzenia]. Informacja, nie oferta.” |

**Tabela luk (w repozytorium są wyłącznie: logo poziome PNG, `AEX.png`, `AnkietaBPEH.pdf`):**

| Potrzebny zasób | Ilość | Użycie | Źródło do decyzji |
|---|---|---|---|
| Zdjęcia stanowisk pracy wg zawodu (kosmetolog, fryzjer, podolog, linergistka, stylistka paznokci, tatuażysta) | 6–8 | `Hero_Image`, okładki karuzel, OG strony `/dla-kogo/*` | sesja własna lub stock z licencją komercyjną; bez generowania osób |
| Portret brokera / zespołu | 2 | Stories dzień 18, nadawca e-maili, `/o-nas` | sesja własna |
| Zestaw ikon liniowych (4 grupy ryzyka, dokument, tarcza, kontrola, zespół, kalkulator) | 10–12 | `Slide_Icon`, strony produktowe | biblioteka Canva lub własny zestaw SVG w repo |
| Logo w wersji białej i monochromatycznej, plik wektorowy | 1 komplet | wszystkie szablony | od właściciela marki |
| Logotypy partnerów (ERGO Hestia, Colonnade, ENEL-MED, LUX MED, Fundacja Beauty Razem) | 5 | dopiero po zgodzie umownej | partnerzy |
| Ilustracja procesu „zgłoszenie szkody – 4 kroki” | 1 | dzień 16, `/szkoda` | własna, z ikon |

### 3.4 Budżet generowania (do zatwierdzenia)

| Pozycja | Liczba | Komentarz |
|---|---|---|
| Projekty Canva wg kalendarza | 17 | 9 postów A, 3 karuzele B, 5 zestawów Stories |
| Kandydaci na projekt | 2 dla 8 pozycji kluczowych (dni 1, 2, 4, 13, 16, 20, 25, 30), 1 dla pozostałych | 25 generowanych wersji |
| Wywołania API (orientacyjnie) | ok. 70–90 | tworzenie / autofill 25, eksport 20, przesłanie zasobów 15, zmiana formatu IG → FB → Stories 10, odczyt i komentarze 10–20 |
| Generowanie obrazów AI | 0 w wariancie bazowym | wyłącznie tła abstrakcyjne i ikony, jeśli brak zdjęć; żadnych osób |
| Czas pracy marketingu | 10–14 h | copy, akceptacja kandydatów, kolejkowanie |
| Czas brokera | 3–4 h | akceptacja merytoryczna 17 projektów i 3 e-maili |

Budżet jest szacunkiem [hipoteza]; limity i koszty zależą od planu Canva i zakresu udzielonego dostępu. Uruchomienie generowania wymaga pisemnej akceptacji tej tabeli przez właściciela.

### 3.5 Copy

Wszystkie ceny wyłącznie z cennika programu, opisane jako „składka wg taryfy programu” (składki są sztywne – bez dopisków „orientacyjna” czy „do potwierdzenia”); zastrzeżenie art. 66 KC i odwołanie do OWU – w nocie dystrybutora. Treści o dokumentach (zgoda, checklista) publikowane dopiero po zatwierdzeniu prawnym.

**Sześć podpisów Instagram / Facebook** (hook → korzyść → CTA → hashtagi)

1. (dzień 1) Manicure, mezoterapia i HIFU to nie ta sama grupa ryzyka. → W programie OC dla branży beauty (ERGO Hestia) zabiegi dzielą się na 4 grupy. Od grupy zależy składka i to, czy potrzebna jest indywidualna ocena. Quiz na portalu pokaże Ci wynik w 60 sekund – bez podawania e-maila. → Link w bio: quiz grup ryzyka. → #beautypolisa #ockosmetyczki #salonkosmetyczny #kosmetolog #beautybiznes
2. (dzień 4) Grupa 1, 2, 3 czy 4? Przesuń, żeby sprawdzić, gdzie są Twoje zabiegi. → Gr. 1: fryzjerstwo, kosmetyka pielęgnacyjna, manicure, rzęsy. Gr. 2: makijaż permanentny, mezoterapia, lasery nieablacyjne, IPL, tatuaż, peelingi chemiczne. Gr. 3: podologia. Gr. 4: HIFU, toksyna botulinowa, PRP, kwas hialuronowy, nici PDO, lipoliza iniekcyjna, laser ablacyjny – indywidualna ocena. Składki od 400 zł/rok w gr. 1 – wg taryfy programu. → Zapisz post i policz składkę: beautypolisa.eu/kalkulator/oc → #ockosmetologa #makijazpermanentny #podolog #fryzjer #beautypolisa
3. (dzień 13) Zgoda na zabieg to nie podpis na kolanie pięć minut przed laserem. → Przygotowaliśmy wzór zgody i checklistę dokumentacji – to dokumenty, o które pyta też ankieta do ubezpieczenia OC. Otwierasz od razu online, kopię dostajesz na e-mail. → Pobierz: beautypolisa.eu/baza-wiedzy/zgoda-na-zabieg-wzor → #zgodanazabieg #dokumentacjasalonu #linergistka #kosmetolog #beautypolisa
4. (dzień 16) Klientka zgłasza powikłanie. Co robisz w pierwszych 24 godzinach? → Kolejność zamiast paniki: zabezpieczasz dokumentację (zgoda, karta zabiegu, zdjęcia), nie podejmujesz zobowiązań wobec klientki bez konsultacji z brokerem, zgłaszasz zdarzenie ubezpieczycielowi. Na portalu opisaliśmy cztery kroki zgłoszenia szkody z OC. → Zapisz na później: beautypolisa.eu/szkoda → #reklamacjazabiegu #ocbeauty #salonkosmetyczny #beautypolisa
5. (dzień 20) Sanepid, ZUS, urząd skarbowy – trzy kontrole, jedna checklista. → Zaznaczasz, co masz, widzisz, czego brakuje. Online bez logowania, PDF na e-mail. A jeśli kontrola skończy się sporem podatkowym – Tax Protect (Colonnade) to ochrona karno-skarbowa właściciela i jeden pełny spór podatkowy w roku dla firmy. Zakres i składki wg taryfy programu – na stronie produktu. → Link w bio: checklista kontroli → #kontrolasanepidu #taxprotect #wlascicielkasalonu #beautybiznes #beautypolisa
6. (dzień 25) Benefity nie są tylko dla korporacji. → Grupowe ERGO dla beauty: pakiety od 58 zł za osobę miesięcznie (wg cennika programu) z modułami MediOpieki – m.in. diagnostyka, rehabilitacja, zdrowie psychiczne, tele-EKG, assistance domowy. Dla salonów, które chcą zatrzymać ludzi, a nie tylko ich rekrutować. → Policz na własnych liczbach: beautypolisa.eu/baza-wiedzy/kalkulator-rotacji → #benefitypracownicze #grupoweergo #salonfryzjerski #managerkasalonu #beautypolisa

**Dwa posty LinkedIn**

Post 1 (dzień 1, profil brokera / strona Aura Expert):

> Od dziś działa beautypolisa.eu – portal o ubezpieczeniach dla branży beauty, który prowadzimy w Aura Expert.
>
> Powód jest prosty. Program OC dla branży beauty realizowany z ERGO Hestią we współpracy z Fundacją Beauty Razem nie ma dotąd żadnego publicznego opisu: ani listy zabiegów w czterech grupach ryzyka, ani zasad, kiedy potrzebna jest indywidualna ocena. Kosmetolożki pytają o to na grupach, a odpowiedzi są przypadkowe.
>
> Na portalu znajdziesz: quiz, który przypisuje zabiegi do grupy ryzyka (bez podawania e-maila), kalkulator składki wg cennika programu, opis zgłoszenia szkody krok po kroku oraz dokumenty do użycia w salonie – wzór zgody na zabieg i checklistę kontroli (po weryfikacji prawnej).
>
> Nie sprzedajemy polis online. Portal informuje, a rozmowa z brokerem jest wtedy, gdy ktoś o nią poprosi.
>
> Jeśli prowadzisz salon albo szkolisz branżę – chętnie usłyszę, czego brakuje. Link w komentarzu.

Post 2 (dzień 9, sezon podatkowy):

> Właściciel salonu odpowiada za rozliczenia osobiście – to nie jest odpowiedzialność „firmy”, tylko konkretnej osoby. Mało kto o tym myśli, dopóki nie przyjdzie wezwanie.
>
> Tax Protect (Colonnade) ma dwie sekcje: pierwsza to ochrona karno-skarbowa właściciela lub zarządu (sumy 50 000 lub 100 000 zł), druga – ochrona podatkowa firmy obejmująca jeden pełny spór podatkowy w roku (sumy od 250 000 do 3 000 000 zł; przychody powyżej 3 mln zł – wycena indywidualna).
>
> Składki są stałe, wg taryfy programu – warianty sum ze składką roczną znajdziesz na portalu. Jest tam też opis obu sekcji i checklista przygotowania do kontroli sanepidu, ZUS i urzędu skarbowego.
>
> Nie zachęcam do kupowania „na wszelki wypadek”. Zachęcam do sprawdzenia, czy w Twojej sytuacji to ryzyko jest realne. beautypolisa.eu/ubezpieczenia/tax-protect

(Twierdzenie o odpowiedzialności osobistej – do weryfikacji przez prawnika przed publikacją.)

**Trzy hooki do Reels (15 s)**

1. „Robisz mezoterapię i myślisz, że masz to samo OC co fryzjerka obok? To są dwie różne grupy ryzyka – i dwie różne składki. Sprawdź swoją w quizie, link w bio.” (tekst na ekranie: „Gr. 1 ≠ Gr. 2”)
2. „Trzy rzeczy, o które zapyta Cię ubezpieczyciel, zanim wyceni OC salonu: szkodowość z trzech lat, lista zabiegów wysokiego ryzyka, formularze zgody na zabieg. Masz wszystkie? Lista na portalu.” (tekst: „1 · 2 · 3”)
3. „Zespół do ośmiu osób – jedna polisa OC w programie. Dziewięć i więcej – wycena indywidualna. Pokazuję, co to zmienia w kalkulatorze.” (nagranie ekranu kalkulatora)

**Trzy e-maile kampanii** (do subskrybentów z potwierdzoną zgodą)

C1 (dzień 3)

| Temat (≤ 50) | Startujemy. Sprawdź grupę ryzyka swoich zabiegów |
|---|---|
| Preheader (≤ 90) | Nowy portal o ubezpieczeniach dla beauty: quiz bez e-maila, kalkulator, dokumenty. |

> Cześć {imię},
>
> piszę, bo od dziś działa beautypolisa.eu – portal, na którym zbieramy w jednym miejscu to, o co pytacie najczęściej.
>
> **Quiz grup ryzyka.** Zaznaczasz zabiegi, które wykonujesz, i w 60 sekund widzisz, do której z czterech grup programu OC (ERGO Hestia) trafiają oraz czy potrzebna jest indywidualna ocena. Bez podawania e-maila.
>
> **Kalkulator składki.** Suma gwarancyjna 100 000 / 200 000 / 300 000 zł, klauzula ochrony prawnej, liczba osób w zespole – i składka roczna wg taryfy programu (grupa 4 i zespoły od 9 osób – wycena indywidualna).
>
> **Zgłoszenie szkody krok po kroku** oraz – w kolejnych tygodniach – wzór zgody na zabieg i checklista kontroli, po weryfikacji prawnej.
>
> Portal nie sprzedaje polis. Jeśli po sprawdzeniu grupy i składki chcesz porozmawiać – zostawiasz kontakt, odzywam się w ciągu jednego dnia roboczego.
>
> **[Zacznij od quizu]**
>
> {podpis, stopka dystrybutora, link rezygnacji}

(ok. 160 słów)

C2 (dzień 12)

| Temat (≤ 50) | Zgoda na zabieg: wzór i checklista dokumentów |
|---|---|
| Preheader (≤ 90) | Dokumenty, o które pyta ankieta OC – gotowe do użycia w salonie, otwierane od razu. |

> Cześć {imię},
>
> ankieta do ubezpieczenia OC w programie pyta między innymi o formularze zgody na zabieg i kwalifikacje personelu. To nie przypadek – w razie roszczenia to właśnie te dokumenty są oglądane jako pierwsze.
>
> Na portalu udostępniliśmy dwa narzędzia, zweryfikowane prawnie: **wzór zgody na zabieg** (wersja ogólna oraz warianty dla makijażu permanentnego, tatuażu i zabiegów z grupy 2) i **checklistę dokumentacji** – co powinno powstać przed zabiegiem, w trakcie i po nim.
>
> Wypełniasz krótki formularz (e-mail i imię), dokumenty otwierają się od razu na stronie, kopia trafia na skrzynkę. Checklistę możesz odhaczać online – stan zostaje na Twoim urządzeniu.
>
> Jeśli masz własny wzór zgody i chcesz wiedzieć, czego mu brakuje – odpisz na tę wiadomość, porównam z listą.
>
> **[Otwórz wzór zgody i checklistę]**
>
> {podpis, stopka dystrybutora, link rezygnacji}

(ok. 150 słów)

C3 (dzień 24)

| Temat (≤ 50) | Kontrola w salonie: checklista na 3 urzędy |
|---|---|
| Preheader (≤ 90) | Sanepid, ZUS, urząd skarbowy – zaznacz, co masz, zobacz, czego brakuje. Bez logowania. |

> Cześć {imię},
>
> kontrola rzadko przychodzi w dobrym momencie, ale prawie zawsze pyta o to samo. Zebraliśmy te pytania w jedną interaktywną checklistę: moduł sanepidu, ZUS i urzędu skarbowego (plus PIP i UODO dla tych, którzy chcą pójść dalej).
>
> Otwierasz listę bez logowania, zaznaczasz, co masz – braki widzisz na górze. Po podaniu e-maila dostajesz PDF i zapis postępu, żeby wrócić do listy z innego urządzenia.
>
> Jedna rzecz, o której warto wiedzieć wcześniej: kontrola skarbowa może skończyć się sporem, a spór kosztuje – czas, pełnomocnika, nerwy. Tax Protect (Colonnade) obejmuje ochronę karno-skarbową właściciela i jeden pełny spór podatkowy w roku dla firmy. Warianty sum ze składką roczną wg taryfy programu i opis zakresu są na portalu.
>
> **[Otwórz checklistę kontroli]**
>
> {podpis, stopka dystrybutora, link rezygnacji}

(ok. 150 słów)

---

## 4. Pomiar, testy, odpowiedzialność, narzędzia

### 4.1 KPI lejka magnesu 1

Dwie ścieżki: bezpośrednia (quiz → kalkulator → lead) i e-mailowa (quiz → e-mail → seria → lead). Baseline zero (01, pkt 6 – apex nie serwuje strony). Wartości to przedziały celów do rewizji po pierwszym kwartale, nie prognozy.

| Etap | Metryka | Cel [hipoteza] | Źródło pomiaru |
|---|---|---|---|
| Odwiedziny landing → start quizu | % sesji z `quiz_started` | 40–60 % | Analytics Engine (kolektor Aura) |
| Start → ukończenie | % `quiz_completed` / `quiz_started` | 60–80 % | j.w. |
| Ukończenie → kalkulator (ścieżka bezpośrednia) | % `quiz_to_calculator` | 25–40 % | j.w. |
| Kalkulator → lead | % `lead_submitted` / wejść z quizu | 5–12 % | j.w. + tabela `leads` (landing_path, utm) |
| Ukończenie → e-mail (ścieżka e-mailowa) | % `magnet_email_submitted` | 10–25 % | j.w. |
| E-mail → potwierdzenie zgody | % `magnet_confirmed` wśród zaznaczonych zgód | 50–70 % | Supabase |
| Potwierdzony → MQL (klik kalkulatora lub prośba o kontakt w 14 dni) | % zapisów z gałęzią `clicked_calc` lub `asked_contact` | 20–35 % | Supabase + webhooki Resend |
| MQL → kontakt (formularz leada / odpowiedź) | % `converted` + `paused_replied` | 25–45 % | Supabase |
| Kontakt → polisa | % leadów ze statusem `won` w 60 dni | 20–40 % | panel `/panel` (statusy z 02) |
| Higiena | odsetek rezygnacji na wiadomość; skargi | ≤ 0,5 %; ≤ 0,1 % | Resend |

Przykład skali [hipoteza]: 1000 odwiedzin landingu → ok. 500 startów → ok. 350 ukończeń → ok. 100 wejść do kalkulatora → ok. 8 leadów ścieżką bezpośrednią; równolegle ok. 60 e-maili → ok. 35 potwierdzonych → ok. 10 MQL → ok. 3–4 kontakty. Wniosek projektowy: ścieżka bezpośrednia jest głównym źródłem leadów, e-mail – źródłem powracających kontaktów i danych o zachowaniu; nie warto osłabiać pierwszej, żeby wzmocnić drugą.

### 4.2 Plan testów A/B (3 testy)

Przydział wariantu po stronie serwera (hash losowego identyfikatora w ciasteczku funkcjonalnym pierwszej strony, bez identyfikacji osoby [hipoteza prawna – do weryfikacji]), wariant jako wymiar zdarzeń w Analytics Engine i tag w Resend. Jeden test naraz na daną stronę.

| # | Test | Warianty | Metryka główna | Metryka ochronna | Próba [szacunek] |
|---|---|---|---|---|---|
| 1 | H1 landingu quizu | A „Sprawdź, czy Twoje zabiegi mieszczą się w programie OC dla beauty” vs B „W której grupie ryzyka są Twoje zabiegi?” | start quizu | ukończenie quizu | ok. 400 odwiedzin na wariant (różnica 10 p.p. przy bazie 50 %) |
| 2 | Hierarchia CTA na ekranie wyniku | A „Policz dokładną składkę” jako główne, e-mail drugorzędne vs B „Wyślij mi wynik na e-mail” jako główne | przejścia do kalkulatora i podania e-maila (łącznie, ważone leadami) | leady z kalkulatora | ok. 350 ukończeń na wariant |
| 3 | Bramka magnesu 2 | A dostęp do dokumentów od razu na stronie sukcesu + kopia e-mailem vs B dostęp tylko z linku w e-mailu | pobrania PDF na 100 odwiedzin artykułu-nośnika | potwierdzone zgody, twarde odbicia | ok. 200 wysłanych formularzy na wariant |

### 4.3 Macierz odpowiedzialności

R – wykonuje, A – zatwierdza, C – konsultuje, I – informowany.

| Zadanie | Dev | Marketing | Broker | Prawnik |
|---|---|---|---|---|
| Logika quizu i kalkulatorów (`packages/pricing`, JSON zabiegów i checklist) | R/A | I | C (zgodność z programem) | – |
| Landing, formularze, `/api/magnets`, webhook Resend, tabele | R/A | C | I | I |
| Treść wzoru zgody i checklisty kontroli | I | C (redakcja) | R (ekspert) | A |
| Klauzule zgód, `/rodo`, informacja dystrybutora (IDD) | I (wdraża wersje) | I | C | R/A |
| Copy e-maili E0–E4, C1–C3 i postów | I | R | A (merytoryka) | C |
| Szablony i projekty Canva (po zgodzie właściciela) | I | R/A | C | – |
| Konfiguracja Resend (nadawca, Audience, webhooki, rezygnacja) | R/A | C | I | I |
| Odpowiedzi na e-maile i leady, SLA 1 dzień roboczy | – | I | R/A | – |
| Dashboard KPI (Analytics Engine, Resend, panel) | R | A | I | – |
| Testy A/B | R | A | I | C (test 3 – zgody) |
| Zgody partnerów na nazwy i logotypy | – | I | R/A | C |

### 4.4 Narzędzia

| Narzędzie | Rola w lejku | Uwagi |
|---|---|---|
| Resend | Wysyłka E0–E4 i C1–C3, Audience jako lista blokująca, webhooki zdarzeń, nagłówki rezygnacji | już skonfigurowany w strefie (01, pkt 6); osobny klucz API (02) |
| Supabase (nowy projekt) | Subskrybenci, zgody z wersjami, dostarczenia, zapisy do serii, outbox, leady | zero dostępu `anon` do tabel z PII (02, decyzja 3) |
| Cloudflare | Workers (aplikacja + Cron `beautypolisa-jobs`), Turnstile, rate limit, Zaraz (tagi po zgodzie), Analytics Engine (lejek first-party) | kolektor Aura przez Service Binding (02, pkt 7.1) |
| Canva | Brand Kit (kolory, Montserrat, logo), 2 szablony z pkt 3.3, autofill, eksport, zmiana formatu | tylko po zgodzie właściciela i nadaniu dostępu |
| GA4 (przez Zaraz) lub Analytics Engine | GA4 wyłącznie po zgodzie – uzupełnienie dla marketingu; Analytics Engine jako podstawa lejka | zgodnie z 02, decyzja 11 |
| GitHub Actions | Budowa PDF-ów magnesów z MDX, walidacja JSON zabiegów i checklist, wdrożenia | 02, pkt 5.1 |
| Meta Business Suite, LinkedIn | Kolejkowanie publikacji z kalendarza | poza zakresem dokumentu |

### 4.5 Czego ten dokument NIE robi

- Nie generuje grafik ani projektów w Canva, nie tworzy szablonów ani Brand Kitu.
- Nie wysyła e-maili, nie tworzy kontaktów, Audience, webhooków ani kluczy w Resend.
- Nie publikuje ani nie kolejkuje postów w żadnym kanale.
- Nie zakłada wyników – każdy wskaźnik jest przedziałem hipotetycznym do zweryfikowania po starcie.
- Nie zastępuje opinii prawnej: klauzule zgód, treść wzoru zgody, checklisty i zakres informacji IDD wymagają zatwierdzenia przez prawnika.
- Nie ustala cen ani zakresów – wszystkie kwoty pochodzą z cennika programu (składki sztywne, taryfowe – rozstrzygnięte 11.11.2026), a zakres ochrony określają OWU.
- Nie modyfikuje istniejącego kodu w repozytorium ani nie tworzy plików poza tą sekcją.

---

## Decyzje

1. **Quiz bez bramki; e-mail opcjonalny dopiero po wyniku.** Uzasadnienie: wynik ma być natychmiastowy (G), a główna wartość quizu to kwalifikacja i skierowanie do kalkulatora (ścieżka bezpośrednia daje więcej leadów niż e-mailowa – pkt 4.1); spójne z 05, decyzja 5. Odrzucone: bramka przed wynikiem (spadek ukończeń, osłabienie linkowalności), dostarczenie wyniku tylko jako PDF.
2. **Magnes 3 = checklista kontroli (Tax Protect), nie kalkulator L4.** Uzasadnienie: produkt „Utrata dochodu” nie ma parametrów (01, pkt 3.5), więc magnes nie miałby kotwicy (A); Tax Protect ma zdefiniowane sekcje i sumy, a checklista ma dwa okna sezonowe. Odrzucone: kalkulator L4 jako magnes (brak oferty do pokazania), oba naraz (rozproszenie zespołu 1 autor + 1 recenzent z 05).
3. **Kalkulator rotacji liczy wyłącznie na liczbach użytkownika; ceny pakietów z aktywnej wersji cennika programu (58 / 68 / 76 zł – stawki sztywne, rozstrzygnięte 11.11.2026; wersja z datą obowiązywania zostaje jako ślad zmian taryfy).** Uzasadnienie: liczby z obecnej argumentacji sprzedażowej (15 000 zł, 50 zł podwyżki) nie mają źródła (05, pytanie 6). Odrzucone: wartości domyślne „średnie branżowe” (niecytowalne, podważają E-E-A-T).
4. **Double opt-in dla serii pielęgnującej; E0 transakcyjny i bez oferty.** Uzasadnienie: dowód zgody, jakość bazy, zgodność z newsletterem z 02 (F8); e-mail dostarczający nie powinien być informacją handlową. Odrzucone: single opt-in (więcej zapisów, słabszy dowód i dostarczalność), łączenie dostarczenia z pitchem.
5. **Orkiestracja serii w Supabase + Cron Worker; Resend jako dostarczenie, zdarzenia i lista blokująca.** Uzasadnienie: gałęzie zależą od zdarzeń z kalkulatora i formularza leada, które są w naszej bazie; zgody i wersje też. Odrzucone: Broadcasts / Automations Resend jako silnik, zewnętrzny ESP (kolejny procesor PII).
6. **Jeden endpoint `/api/magnets` z pięcioma warstwami ochrony z 02; wyniki jako strony bez PII z parametrami w adresie.** Uzasadnienie: jedna powierzchnia do zabezpieczenia, linki z e-maili działają bezterminowo i są udostępnialne. Odrzucone: osobne endpointy per magnes, strony wyniku z tokenami powiązanymi z osobą.
7. **PDF-y magnesów 2 i 3 budowane w CI z MDX jako assety statyczne; wynik quizu wyłącznie jako HTML.** Uzasadnienie: brak renderowania PDF w runtime Workers, wersjonowanie w repozytorium (02, pkt 2.5). Odrzucone: generowanie PDF na serwerze, zewnętrzne API do PDF.
8. **Trzy osobne elementy zgód, zgoda telefoniczna tylko tam, gdzie zbieramy numer; teksty wersjonowane w `consents.text_version`; zero ciemnych wzorców.** Uzasadnienie: dowód i czytelność, zgodność z 02, pkt 4.7. Odrzucone: jeden zbiorczy checkbox, domyślne zaznaczenia, zgoda jako warunek pobrania.
9. **Informacja dystrybutora warstwowo (stopka → `/o-nas` → `/dokumenty` → sukces leada → pierwszy kontakt).** Uzasadnienie: landing magnesu nie jest czynnością dystrybucyjną, ale klient ma zawsze wiedzieć, kto stoi za treścią; pełne obowiązki realizuje broker przed zawarciem umowy. Odrzucone: pełny tekst IDD na każdym landingu (szum), brak informacji do czasu kontaktu (ryzyko).
10. **Kampania organiczna przez 30 dni, partnerzy tylko jako nazwy, e-maile wyłącznie do bazy ze zgodą.** Uzasadnienie: brak danych do optymalizacji płatnych kampanii, brak zgód na piksele przed wdrożeniem Zaraz, nieznane zasady użycia logotypów i status zgód w CRM Aura. Odrzucone: Meta Ads od dnia 1, wysyłka do `crm_companies` bez audytu zgód.
11. **Analytics Engine jako podstawa pomiaru lejka, GA4 tylko po zgodzie przez Zaraz, Resend dla metryk e-mail** – zgodnie z 02, decyzja 11. Odrzucone: GA4 jako jedyne źródło (zależność od zgody dziurawi lejek).
12. **Generowanie w Canva dopiero po zatwierdzeniu budżetu z pkt 3.4 i nadaniu dostępu.** Uzasadnienie: koszty, dostęp do kont i akceptacja merytoryczna brokera. Odrzucone: generowanie kandydatów „na próbę” bez zgody.

## Pytania otwarte do zleceniodawcy

1. Jaki jest potwierdzony status dystrybutora (broker vs agent)? Decyduje o treści stopki, klauzul i informacji IDD (01, pkt 2; 02, pytanie 9).
2. Kto pełni funkcję IOD i jaki adres kontaktowy IOD podajemy w klauzulach z pkt 2.6 (02, pytanie 1)? Administrator danych portalu jest rozstrzygnięty: Aura Expert sp. z o.o. (decyzja zleceniodawcy z 12.11.2026).
3. Kto zatwierdza prawnie wzór zgody na zabieg i checklistę kontroli oraz czy mogą być wydawane pod marką BeautyPolisa / Aura Expert (05, pytanie 9)?
4. Czy prawnik potwierdzi aktualną podstawę prawną zgód (art. 398 PKE vs art. 10 u.ś.u.d.e. i art. 172 Pt) oraz oceni, czy e-mail E0 z linkiem do strony wyniku jest informacją handlową?
5. Czy można używać nazwy „ERGO Hestia” i numeru programu w postach i e-mailach, i na jakich zasadach umownych wolno użyć logotypów ERGO Hestia, Colonnade, ENEL-MED, LUX MED i Fundacji Beauty Razem?
6. Czy istnieje baza kontaktów z udokumentowaną zgodą marketingową (CRM Aura, `email_messages`) do e-maili C1–C3 i kto przeprowadzi audyt zgód przed wysyłką – w tym ocenę, czy zgody zebrane dotąd pod poprzednią nazwą spółki są ważne dla Aura Expert sp. z o.o. (pkt 2.6)?
7. Czy liczby „koszt rotacji ok. 15 000 zł” i „pakiet zamiast podwyżki 50 zł” mają cytowalne źródło (05, pytanie 6)? Bez niego kalkulator rotacji pracuje tylko na liczbach użytkownika.
8. Czy seria pielęgnująca wchodzi do v1 (02 i 05, pytanie 11) i kto jest imiennym nadawcą e-maili (05, decyzja 6)? Czy broker może odpowiadać w SLA 1 dnia roboczego?
9. Kto nadaje dostęp do Canva (Brand Kit, szablony), Meta Business Suite, LinkedIn i Resend, i czy właściciel akceptuje budżet generowania z pkt 3.4?
10. Jaka jest data startu portalu? Określa nakładkę sezonową kalendarza (I–II podatki, IX NNW dzieci, XI–XII grupowe).
11. Czy Aura lub Fundacja Beauty Razem dysponują zdjęciami z prawami do użycia (salony, zespół), czy planujemy sesję albo zakup stocku?
12. Czy uzupełnienie modelu danych z 02 o `magnet_deliveries`, `nurture_enrollments`, cel zgody `magnet_delivery` i tabelę `pricing_group_packages` jest akceptowane przez autora sekcji 02?
