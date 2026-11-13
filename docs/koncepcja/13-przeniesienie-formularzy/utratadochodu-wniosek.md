# UtrataDochodu.pl: wniosek o ubezpieczenie utraty dochodu (inżynieria wsteczna)

Źródło: kod kliencki `https://utratadochodu.pl/wniosek/` (Astro, strona statyczna, wyspa Svelte 5 `client:visible`). Wszystkie odwołania do linii dotyczą kopii po prettier w `specs/tmp/ud/`.

| Plik | Zawartość |
|---|---|
| `ext/src/ud/wniosek.html` (= `ext/ud_wniosek_`) | HTML strony. SSR obejmuje **tylko krok 1**, panel boczny, `window.UD_TAGI`, a w `astro-island` atrybut `props`: `zawody` (188 pozycji), `urlFunkcji`, `urlSzkicu`, `kluczTurnstile` |
| `ext/src/ud_bundle/Wniosek.DxdaBiVh.js` | **cała logika kreatora**: kroki, pola, walidacje, ankiety, szkic, wysyłka. **Nie było go w paczce** – pobrałem go osobno 2026-11-13 jako tekst (GET z `/_astro/`, 38 602 B). Kopia po prettier: `specs/tmp/ud/Wniosek.js`, 1841 linii |
| `ext/src/ud_bundle/Kalkulator.CddwfkKg.js` | **symulacja składki** (kalibracja z ofert). To osobna wyspa: strona główna, `/kalkulator/` i strony zawodów. Pobrana osobno; kopia `specs/tmp/ud/Kalkulator.js` |
| `ext/src/ud_bundle/podziekowanie.html`, `wycofaj-zgode.html` | strona po wysłaniu (konwersja Ads) i strona wycofania zgody na kontakt (akcja szkicu `wycofaj`). Obie pobrane osobno |
| `ext/src/ud_bundle/wniosek_zawod_*.html` | `/wniosek/?zawod=fryzjer` i `?zawod=stylistki%20paznokci`. HTML jest identyczny z wersją bez parametru (różni się tylko ray ID Cloudflare), więc **parametr niczego nie zmienia** (zob. §6) |
| `ext/src/ud/zgody.js` | baner cookies i Consent Mode v2, ładowanie GA4, Ads i Pixela, `UDCookies.konwersja` |
| `ext/src/ud/awaria.js` | modal awarii (`window.Awaria`) |
| `ext/src/ud/__vitals.js` | pomiar Web Vitals → `sendBeacon('/__vitals')` |
| `ext/ud/*.md`, `llms.txt` | teksty stron: kalkulator, zawody, wyłączenia i inne |

Dane strukturalne do makiety są w `specs/utratadochodu-wniosek.json`: kroki, wszystkie pola z opcjami i komunikatami, 7+20 pytań zdrowotnych, 15 aktywności, ryzyka, klauzule, zgody, 188 zawodów, protokół szkicu i wysyłki, kalibracja symulacji, strona podziękowania. Generator: `specs/tools/build_ud.py`.

**Uzupełnienie 13.11.2026 – kod serwera.** Drugim źródłem jest płytki klon publicznego repozytorium zleceniodawcy `aurabroker/ud` (commit `793a158`, 12.10.2026; czytany, nieuruchamiany). Zawiera portal Astro (`apps/portal`), panel agenta (`apps/panel`), monitor (`apps/monitor`), schemat wniosku (`packages/wniosek`), funkcje brzegowe Supabase (`supabase/functions`) i migracje (`supabase/migrations`). Wyniki są w **§9** (backend, e-maile, zgody, dokumenty, leady), a rozliczenie braków U1–U10 w **§10**. Odwołania w formacie `ud/<ścieżka>:<linia>` dotyczą tego repozytorium. Dwa zastrzeżenia:
- Repozytorium jest **starsze od produkcji**. Żywa strona z 13.11 ma box „Zakup online” i inny tekst „Co dostajesz”, a `ud/apps/portal/src/pages/wniosek/index.astro:84-90` jeszcze nie.
- Według projektu funkcja brzegowa w repozytorium „bywa starsza niż wdrożona” (`ud/CLAUDE.md:1100-1118`). Dla `form-submit` CLAUDE.md podaje, że produkcyjna v25 to treść z repozytorium (`ud/CLAUDE.md:1023-1028`).

**[przegląd repo 13.11]** Trzecim źródłem jest klon `aurabroker/udapp` (`36ae901`, 20.10.2026; czytany, nieuruchamiany). To **panel ofert, który klient widzi po wniosku, a nie formularz**. Opis i wpływ na U9 i U10: **§11**.

---

## 1. Przegląd i kroki

**Produkt:** ubezpieczenie utraty dochodu (prywatne L4). Ubezpieczycielem jest Lloyd's Insurance Company S.A., a coverholderami Leadenhall Insurance S.A. i CEU sp. z o.o. Agent: Aura Expert sp. z o.o., RPU 11229690/A (`llms.txt`, JSON-LD w `wniosek.html`). Wniosek nie zawiera umowy. Kończy się przekazaniem danych, po którym agent przygotowuje ofertę.

**Mechanika** (`Wniosek.js`, funkcja `Q`, l. 567–1839): jeden reaktywny obiekt stanu `W` (l. 576–600). Indeks kroku `H` startuje od 0, a lista kroków to `G` (l. 286–308). Nad formularzem jest stepper `<ol>` z 5 pozycjami „Krok N z 5” i tytułem. Ukończone kroki mają `border-akcent`, bieżący `border-akcent-ciemny` i `aria-current="step"`, kliknąć się ich nie da. Formularz ma `novalidate`. Walidacja to wyłącznie JS (`pe`).

- **„Dalej”** (`lt`, l. 623–636) waliduje tylko bieżący krok. Przy błędach przewija do pierwszego z nich (`[name=klucz]` lub `[data-pole=klucz]`, smooth, center) i ustawia na nim fokus. Gdy błędów nie ma: w kroku 1 woła `yt()` (szkic start/kontakt), w krokach 2–4 woła `bt(idKroku)` (szkic „krok”). Potem `H+1` i przewinięcie do `#wniosek-gora`.
- **„Wstecz”** (`ut`) czyści błędy, robi `H-1` i przewija. W kroku 1 zamiast przycisku jest pusty `<span>`.
- W kroku 5 zamiast „Dalej” jest `submit` z napisem „Wyślij wniosek” (podczas wysyłki „Wysyłam…”, `disabled`).
- Stanu **nie zapisuje się** w localStorage ani sessionStorage. Odświeżenie strony gubi dane, bo szkic na serwerze przechowuje tylko kontakt i postęp, nie treść.

| Krok | id | Tytuł | Co zawiera | Warunek „Dalej” |
|---|---|---|---|---|
| 1 | `kontakt` | Kontakt | imię i nazwisko, e-mail, telefon, opcjonalna zgoda na kontakt, niewidoczny Turnstile | 3 pola poprawne |
| 2 | `dane` | Dane podstawowe | PESEL, forma zatrudnienia, zawód (datalist 188), waga, wzrost, forma opodatkowania, ręczność, „zatrudniam pracowników” (+6 pól) | PESEL poprawny i wiek 18–65, zawód niepusty, waga i wzrost w zakresie, jeśli je podano |
| 3 | `zakres` | Zakres ochrony | 3 ryzyka z sumami (okresowa niezdolność zawsze zaznaczona), info o ankiecie rozszerzonej, 5 klauzul NNW (tylko przy NW > 300 000 zł) | każde zaznaczone ryzyko ma kwotę > 0 i ≤ max |
| 4 | `zdrowie` | Stan zdrowia | 7 pytań tak/nie (domyślnie „Nie”) + opis przy „Tak”, warunkowo ankieta rozszerzona (20 pytań, 3 grupy), 15 aktywności ryzykownych | opisy przy „Tak”, a w ankiecie rozszerzonej odpowiedź na każde pytanie |
| 5 | `zgody` | Zgody | 2 wymagane potwierdzenia, widoczny Turnstile, pole błędu wysyłki | oba checkboxy i token Turnstile |
| — | `/podziekowanie/` | Wniosek przyjęty | statyczna strona i konwersja Ads | — |

**Stała `G[].opis`** (l. 286–308) opisuje dane z każdego kroku. Kreator jej nie wyświetla. *Poprawka po analizie repozytorium:* to nie martwy kod. W źródle jest to `KROKI[].opis` (`ud/packages/wniosek/src/schemat.js:202-213`), a strona `/klauzula-informacyjna/` wypisuje z niego kategorie danych z art. 13 RODO (`ud/apps/portal/src/pages/klauzula-informacyjna/index.astro:104-108`). Rozbieżność trafia więc do klauzuli informacyjnej (§9.4). Uwaga na rozbieżności: opis kroku `dane` mówi o „wysokości dochodu”, a opis `zakres` o „okresie wypłaty świadczenia”. **Formularz nie ma ani pola dochodu, ani pola okresu wypłaty.**

**Obietnica symulacji jest niespełniona.** Lead i panel mówią: „Na końcu dostajesz symulację składki” oraz „Symulację składki od razu po wypełnieniu.”. W kodzie kreatora i strony `/podziekowanie/` **żadnej symulacji nie ma**, a po wysłaniu następuje przekierowanie na statyczną stronę. Symulacja istnieje tylko w osobnej wyspie Kalkulator (§4).

**Teksty strony (SSR, `wniosek.html`):**
- H1: „Wniosek o ubezpieczenie”
- Lead: „Pięć kroków, około pięciu minut. Na końcu dostajesz symulację składki, a ofertę z realną stawką — w 1–2 dni robocze, po ocenie ryzyka przez ubezpieczyciela.”
- `<title>`: „Wniosek o ubezpieczenie utraty dochodu | UtrataDochodu.pl”. Meta description: „Wypełnij wniosek online w pięć kroków. Bezpłatna symulacja składki, oferta w 1–2 dni robocze, bez wychodzenia z domu.”
- Panel boczny:
  - „Co dostajesz”: „Symulację składki od razu po wypełnieniu.” / „Ofertę z wariantami dwóch przedstawicieli Lloyd’s — Leadenhall i CEU.” / „Komplet dokumentów: OWU i kartę produktu.”
  - „Utknąłeś na którymś polu?”: „Zadzwoń — przejdziemy przez wniosek razem, telefonicznie.” i link 504 400 901.
  - Box „Zakup online”: „Wolisz kupić sam, przez internet?” i lista „✓ **Online:** tylko okresowa niezdolność do pracy (miesięczne świadczenie)” / „✗ **Tylko w ofercie po wniosku:** trwała niezdolność do pracy, śmierć / inwalidztwo w wyniku nieszczęśliwego wypadku”. Dalej: „Ten zakres sprzedaje online Leadenhall Insurance S.A., przedstawiciel (coverholder) Lloyd’s, na własnych warunkach. Mogą się różnić od wariantów z oferty, którą przygotujemy po wniosku, a porównania z CEU tam nie dostaniesz.” Przycisk „Kup online u Leadenhall →” prowadzi do `/kup-online?z=wniosek` (nowa karta), z dopiskiem „Strona Leadenhall otworzy się w nowej karcie. Ankietę zdrowotną wypełnisz u nich.”. Box jest usuwany, gdy w URL jest `?agent=`.
  - Stopka panelu: „Kwoty pokazywane w kreatorze to symulacja, nie oferta. Realną składkę wylicza system ubezpieczyciela po ocenie ryzyka.”

---

## 2. Pola i walidacje

Funkcja walidująca to `pe(krok, stan)` (`Wniosek.js` l. 349–419). Błędy wyświetlane są pod polem (`text-alarm`) z `aria-invalid` i `aria-describedby="e-<pole>"`.

| Krok | Pole (`name`) | Typ | Wymagane | Walidacja (dokładnie z kodu) | Komunikat błędu |
|---|---|---|---|---|---|
| 1 | `fullName` „Imię i nazwisko” | text, `autocomplete=name` | tak | `trim()` niepusty | „Podaj imię i nazwisko.” |
| 1 | `email` „Adres e-mail” | email | tak | `/^[^\s@]+@[^\s@]+\.[a-z]{2,}$/i` po trim | „Podaj adres e-mail, na który wyślemy ofertę.” |
| 1 | `phone` „Telefon” | tel | tak | po usunięciu `[\s()-]`: `/^(?:\+?48)?\d{9}$/` | „Podaj numer telefonu — dziewięć cyfr.” |
| 1 | `zgodaKontakt` | checkbox | nie | — (domyślnie odznaczony) | — |
| 2 | `pesel` „PESEL” | text, `inputmode=numeric`, `maxlength=11`, font-mono | tak | `/^\d{11}$/` i suma kontrolna: wagi `[9,7,3,1,9,7,3,1,9,7]`, Σ mod 10 == cyfra 11 (funkcja `K`, l. 313–323) | „PESEL ma 11 cyfr i musi się zgadzać z cyfrą kontrolną.” |
| 2 | `pesel` (wiek) | — | tak | data z PESEL (stulecie z miesiąca: +0→1900, +20→2000, +40→2100, +60→2200, +80→1800; UTC), wiek liczony na dziś (UTC), musi być **18–65** włącznie. Uwaga: `q()` buduje datę przez `Date.UTC` i sprawdza tylko `NaN`, więc nieistniejąca data z poprawną sumą kontrolną (np. dzień 31 w lutym) **przechodzi** z przesuniętą datą (w EZB taka data jest odrzucana) | „Ochrona obejmuje osoby od 18 do 65 lat, a z PESEL-u wychodzi {wiek}.” |
| 2 | `employmentType` „Forma zatrudnienia” | select | nie (domyślnie `b2b`) | — | — |
| 2 | `profession` „Zawód” | text + `datalist#lista-zawodow` (188 pozycji), placeholder „Wpisz lub wybierz z listy” | tak | `trim()` niepusty. Dowolny tekst, lista tylko podpowiada | „Wybierz zawód z listy albo wpisz własny.” |
| 2 | `weight` „Waga (kg)” | number, `inputmode=decimal`, min 30, max 200 | nie | tylko gdy niepuste: po usunięciu spacji i NBSP oraz zamianie `,`→`.` liczba w [30; 200] | „Wpisz wagę w kilogramach — od 30 do 200.” |
| 2 | `height` „Wzrost (cm)” | number, `inputmode=numeric`, min 100, max 250 | nie | jw., [100; 250] | „Wpisz wzrost w centymetrach — od 100 do 250.” |
| 2 | `taxForm` „Forma opodatkowania” | select, pierwsza opcja „— wybierz —” (`""`) | nie | — | — |
| 2 | `handedness` „Ręczność” (legend) | radio `prawy` / `lewy` | nie | — (domyślnie pusty) | — |
| 2 | `employsPeople` | checkbox | nie | — | — |
| 2 | `emp_startDate` „Data rozpoczęcia działalności” | date | nie (pojawia się przy `employsPeople`) | — | — |
| 2 | `emp_industry` „Branża” | text | nie | — | — |
| 2 | `emp_count_2024` „Pracownicy — rok ubiegły” | number min 0 | nie | — | — |
| 2 | `emp_count_current` „Pracownicy — obecnie” | number min 0 | nie | — | — |
| 2 | `emp_contribution_slider` „Mój wkład w przychód firmy: **{n}%**” | range 0–100, domyślnie 50 | nie | — | — |
| 2 | `emp_description` „Opis roli (opcjonalnie)” | textarea 2 wiersze, placeholder „Np. ja wykonuję zabiegi, pracownicy zajmują się recepcją.” | nie | — | — |
| 3 | `riskTempIncapacity` | checkbox, **disabled, zawsze true** | (podstawowe) | gdy brak → błąd `ryzyka` (w praktyce nieosiągalne) | „„Okresowa niezdolność do pracy" to ryzyko podstawowe — polisa zawsze je obejmuje. Pozostałe ryzyka możesz do niego dołożyć.” |
| 3 | `tempIncapacitySum` „Kwota miesięczna (zł)” | number min 0 step 1000 max 50 000 | tak (ryzyko zawsze aktywne) | liczba > 0 i ≤ 50 000 | „Wpisz kwotę.” / „Najwyżej 50 000 zł miesięcznie — wpisz niższą kwotę.” |
| 3 | `riskDeathInvalidity` | checkbox | nie | — | — |
| 3 | `nwDeathSum` „Suma ubezpieczenia (zł)” | number min 0 step 1000 max 10 000 000 | gdy ryzyko zaznaczone | > 0 i ≤ 10 000 000 | „Wpisz kwotę.” / „Najwyżej 10 000 000 zł — wpisz niższą sumę.” |
| 3 | `riskPermIncapacity` | checkbox | nie | — | — |
| 3 | `permIncapacitySum` „Suma ubezpieczenia (zł)” | number min 0 step 1000 max 10 000 000 | gdy ryzyko zaznaczone | > 0 i ≤ 10 000 000 | jw. |
| 3 | `nwFuneral`, `nwAdaptation`, `nwHospitalDaily`, `nwMedicalCosts`, `nwUnconsciousWeekly` | select (kwoty §4) | nie, domyślnie 0 | widoczne tylko przy `riskDeathInvalidity` i `nwDeathSum > 300 000` | — |
| 4 | 7 × `med_*` (ankieta podstawowa) | radio Tak/Nie (`yes`/`no`), **domyślnie `no`** | tak (zawsze ma wartość) | — | — |
| 4 | `med_*_notes` „Opisz krótko, czego dotyczy” | textarea 2 wiersze, widoczna przy „Tak” | gdy `yes` | trim niepusty | „Przy odpowiedzi „tak" opisz krótko, czego dotyczy.” |
| 4 | 20 pytań ankiety rozszerzonej (radio `name=hs_<key>`, stan w `W[key]`) | radio Tak/Nie, domyślnie puste (4 wspólne z podstawową mają `no`) | tak, gdy `permIncapacitySum > 1 000 000` | wartość `yes` albo `no` | „Odpowiedz „tak" albo „nie".” (ramka `border-alarm`) |
| 4 | `<key>_notes` (textarea `name=hsd_<key>`) | textarea | gdy `yes` | trim niepusty | „Przy odpowiedzi „tak" opisz krótko, czego dotyczy.” |
| 4 | 15 × `risk_*` | checkbox | nie | — | — |
| 5 | `exclusions_accepted` | checkbox | tak | true | „Potwierdź, że znasz główne wyłączenia odpowiedzialności.” |
| 5 | `informedAccepted` | checkbox | tak | true | „Potwierdź zapoznanie się z klauzulą informacyjną.” |
| 5 | Turnstile (widoczny) | widżet | tak | `turnstile.getResponse()` niepusty | „Potwierdź, że nie jesteś robotem.” (pokazywane w boksie błędu wysyłki) |

**Opcje list:**
- `employmentType` (`ie`, l. 142–146) przyjmuje wartości `b2b` „Samozatrudnienie (B2B / JDG)”, `uop` „Umowa o pracę” i `zlecenie` „Umowa zlecenie / o dzieło”. Podpowiedź pod polem: „Świadczenie obejmie do {80|65}% udokumentowanego dochodu.” (`re = {b2b:0.8, uop:0.65, zlecenie:0.65}`, l. 141).
- `taxForm` (`ae`, l. 147–152) przyjmuje wartości `zasady_ogolne` „Zasady ogólne (skala podatkowa)”, `liniowy` „Podatek liniowy (19%)”, `ryczalt` „Ryczałt od przychodów ewidencjonowanych” i `karta_podatkowa` „Karta podatkowa”.
- `handedness` przyjmuje wartości `prawy` „Praworęczny/a” i `lewy` „Leworęczny/a”.
- Zawody: 188 pozycji z `props.zawody` (pełna lista w JSON). Branża beauty obejmuje 9 z nich: Fryzjer, Kosmetolog, Kosmetyczka, Masażysta, Stylista, Stylistka Paznokci, Tatuażysta, Terapeuta, Wizażysta.

**Obserwacje i słabości walidacji (do poprawy w portalu):**
- Okresowa niezdolność ma tylko podpowiedź „Maksymalnie {limit}% średniorocznych przychodów netto, nie więcej niż 50 000 zł miesięcznie.”. Kod **nie sprawdza 80%/65% dochodu**, bo dochodu w ogóle nie zbiera. Podpowiedź do trwałej niezdolności („10× roczne przychody”) też nie jest sprawdzana.
- „Zaokrąglana do pełnych tysięcy” obowiązuje tylko jako atrybut `step=1000`, a przy `novalidate` niczego nie wymusza.
- Ankieta rozszerzona włącza się przy `permIncapacitySum > 1e6` **niezależnie od tego, czy `riskPermIncapacity` jest zaznaczone** (`me` → `ne(permIncapacitySum)`, l. 420–422). Wystarczy wpisać sumę i odznaczyć ryzyko, a ankieta i tak się pojawi.
- Cztery pytania ankiety rozszerzonej (`med_heart`, `med_neuro`, `med_stomach`, `med_diabetes`) **dzielą stan** z pytaniami ankiety podstawowej, choć mają inne etykiety (np. „Układ sercowo-naczyniowy” i „Problemy z sercem, nadciśnienie…”). W rozszerzonej nie pokazują pola opisu (`at.has(key)`), bo opis jest już w części podstawowej. `med_locomotor` ma `col: med_bones`, ale osobny stan. Z kolei `med_thyroid`, `med_urinary`, `med_respiratory`, `med_oncology`, `med_spine_degenerative`, `med_allergy` i `med_other` nie mają `col` (prawdopodobnie brak kolumny w bazie, zob. §7).
- Submit waliduje tylko krok 5 i nie sprawdza ponownie kroków 1–4 (do kroku 5 i tak nie da się dojść bez przejścia przez nie).

---

## 3. Treści dosłowne (zgody, klauzule, informacje)

### 3.1 Krok 1 – Kontakt
- Wstęp: „Zaczynamy od kontaktu — na ten adres e-mail i numer telefonu odezwiemy się z ofertą.”
- **Zgoda na kontakt** (stała `de`, l. 309–312, wersja **`v1-2026-10`**), checkbox `zgodaKontakt`:
  > Zgadzam się na kontakt e-mailowy i telefoniczny ze strony Aura Expert sp. z o.o. w sprawie mojego wniosku — także wtedy, gdy go nie dokończę. Zgodę mogę wycofać w każdej chwili.

  Dopisek: „Zgoda jest dobrowolna — wniosek możesz złożyć bez niej.”

### 3.2 Krok 2 – Dane podstawowe
- Checkbox `employsPeople`: **„Prowadzę działalność i zatrudniam pracowników”**, opis: „Ubezpieczyciel liczy wtedy Twój wkład w przychód firmy osobno — dojdzie kilka pól.”

### 3.3 Krok 3 – Zakres ochrony (`V`, l. 207–233)
| Klucz | Etykieta | Rodzaj (mono, wersaliki) | Max | Podpowiedź |
|---|---|---|---|---|
| `riskDeathInvalidity` / `nwDeathSum` | Śmierć / inwalidztwo w wyniku nieszczęśliwego wypadku | Jednorazowe świadczenie | 10 000 000 | „Najwyżej 10 000 000 zł. Zaokrąglana do pełnych tysięcy złotych.” |
| `riskTempIncapacity` / `tempIncapacitySum` | Okresowa niezdolność do pracy | Miesięczne świadczenie | 50 000 | „Maksymalnie {80\|65}% średniorocznych przychodów netto, nie więcej niż 50 000 zł miesięcznie.” |
| `riskPermIncapacity` / `permIncapacitySum` | Trwała niezdolność do pracy | Jednorazowe świadczenie | 10 000 000 | „Maksymalnie 10× roczne przychody, nie więcej niż 10 000 000 zł. Zaokrąglana do tysięcy.” |

Kolejność kart jest taka jak w tabeli: Śmierć/NW, Okresowa, Trwała. Pod okresową: „Ryzyko podstawowe — polisa zawsze je obejmuje. Pozostałe możesz dołożyć.”

- Info przy `permIncapacitySum > 1 000 000`: „Suma trwałej niezdolności przekracza 1 000 000 zł, więc w następnym kroku ubezpieczyciel wymaga rozszerzonej ankiety zdrowotnej. To dłuższa lista pytań, ale nadal tylko „tak" albo „nie" — opis potrzebny jest wyłącznie przy odpowiedzi twierdzącej.”
- Info przy zaznaczonym NW i sumie ≤ 300 000: „Klauzule dodatkowe — świadczenie pogrzebowe, dostosowanie do niepełnosprawności, świadczenie szpitalne — otwierają się przy sumie śmierci i inwalidztwa powyżej 300 000 zł. Poniżej tej kwoty ubezpieczyciel ich nie oferuje.”
- Nagłówek „Klauzule dodatkowe” i 5 selectów (kwoty w §4). Opcja 0 ma etykietę „Nie wybieram”.

Formatowanie kwot: `dt` = `Intl.NumberFormat('pl-PL')` + „ zł”, przy czym liczby czterocyfrowe nie dostają separatora („5000 zł”, ale „10 000 zł”). Do tego sufiks „ / dzień” lub „ / tydzień”.

### 3.4 Krok 4 – Stan zdrowia
Wstęp: „Odpowiadaj szczerze. Zatajenie choroby nie oszczędza składki — pozwala ubezpieczycielowi odmówić wypłaty w momencie, w którym będzie potrzebna najbardziej.”

**Ankieta podstawowa** (`L`, l. 153–176), numerowana „1.”–„7.”, radio „Tak”/„Nie”:
1. `med_heart`: Problemy z sercem, nadciśnienie, bóle w klatce piersiowej?
2. `med_diabetes`: Cukrzyca, problemy z nerkami, prostatą lub układem moczowym?
3. `med_bones`: Problemy z kręgosłupem, stawami, układem kostnym?
4. `med_stomach`: Choroby żołądka, jelit, wątroby lub trzustki?
5. `med_neuro`: Choroby neurologiczne, psychiczne lub zaburzenia lękowe?
6. `med_surgery`: Operacje chirurgiczne lub stałe leki?
7. `med_aids`: Testy w związku z AIDS / HIV?

Przy „Tak” pojawia się textarea „Opisz krótko, czego dotyczy”.

**Ankieta rozszerzona** (`F`, l. 40–123): nagłówek „Ankieta rozszerzona”, opis „Wymagana, bo suma trwałej niezdolności przekracza 1 000 000 zł.”
- *Informacje ogólne*:
  - `weight_change`: Zmiana wagi ciała ponad 5 kg w ciągu ostatniego roku (niezwiązana z ciążą/porodem)
  - `takes_meds`: Przyjmowanie na stałe leków przepisanych przez lekarza
  - `pending_diagnosis`: Aktualnie prowadzona jest diagnostyka, trwa oczekiwanie na wyniki badań, zabieg lub rozważane jest zasięgnięcie porady lekarskiej ze względu na aktualnie odczuwane objawy chorobowe
  - `disability_congenital`: Czy występują u Pana/Pani trwałe ograniczenie sprawności lub wady wrodzone?
  - `smoker`: Czy pali Pan/Pani papierosy lub inne wyroby tytoniowe?
- *Zdarzenia medyczne*:
  - `event_hospitalization`: Miała miejsce hospitalizacja
  - `event_sick_leave_30`: Otrzymano zwolnienie lekarskie dłuższe niż 30 dni
  - `event_further_diagnosis`: Odbyto konsultacje lub wykonano badania diagnostyczne, po przeprowadzeniu których lekarz zalecił dalszą diagnostykę lub leczenie
- *Choroby i układy*:
  - `med_heart`: Układ sercowo-naczyniowy
  - `med_neuro`: Układ nerwowy, wzrok, słuch
  - `med_thyroid`: Tarczyca
  - `med_urinary`: Układ moczowy
  - `med_stomach`: Układ pokarmowy
  - `med_locomotor`: Układ ruchu, dna moczanowa
  - `med_respiratory`: Układ oddechowy
  - `med_oncology`: Choroby onkologiczne, guzy, narośla
  - `med_spine_degenerative`: Choroba zwyrodnieniowa kręgosłupa lub stawów, zapalenie stawów lub jakikolwiek inny proces zwyrodnieniowy dotyczący kręgosłupa, stawów, kości, mięśni, ścięgien lub wiązadeł. Objawy/dolegliwości bólowe ze strony kręgosłupa lub stawów
  - `med_allergy`: Alergia (inna niż katar sienny)
  - `med_diabetes`: Cukrzyca
  - `med_other`: Inna, niewymieniona wcześniej choroba

W kodzie **nie ma okresu referencyjnego** dla pytań (np. „w ciągu ostatnich 5 lat”). Etykiety brzmią dokładnie tak, jak powyżej. Kontekst czasowy jest najpewniej w ankiecie ubezpieczyciela (§7).

**Aktywności podwyższonego ryzyka** (`R`, l. 177–202). Legenda „Aktywności podwyższonego ryzyka”, opis: „Zaznacz, co uprawiasz regularnie. Nie wyklucza to z ochrony — wpływa na ocenę ryzyka.” Checkboxy w siatce 2-kolumnowej:

| Klucz | Etykieta |
|---|---|
| `risk_climbing` | Wspinaczka wysokogórska |
| `risk_caving` | Eksploracja jaskiń |
| `risk_diving` | Nurkowanie głębokie lub jaskiniowe |
| `risk_skiing` | Narciarstwo poza trasami |
| `risk_gravity_bike` | Kolarstwo grawitacyjne (downhill, enduro) |
| `risk_extreme_bike_boat` | Rafting i kajakarstwo górskie |
| `risk_sailing` | Żeglarstwo morskie (załoga) |
| `risk_horse` | Jazda konna |
| `risk_horse_jumping` | Skoki przez przeszkody konne |
| `risk_quad` | Quady i sporty motorowe |
| `risk_skydiving` | Spadochroniarstwo |
| `risk_paragliding` | Paralotniarstwo i lotniarstwo |
| `risk_balloon` | Loty balonem |
| `risk_aviation` | Lotnictwo — pilot lub członek załogi |
| `risk_hunting` | Łowiectwo z użyciem broni |

### 3.5 Krok 5 – Zgody (`Ze`, l. 551–553)
- `exclusions_accepted` (wymagane): „Zapoznałem/am się z [głównymi wyłączeniami odpowiedzialności](/wylaczenia/).”
- `informedAccepted` (wymagane): „Zapoznałem/am się z [klauzulą informacyjną](/klauzula-informacyjna/), [regulaminem](/regulamin/) i [polityką prywatności](/polityka-prywatnosci/).”
- Brak innych zgód. **Nie ma wyraźnej zgody na przetwarzanie danych o zdrowiu (art. 9 RODO)**, choć `G[3].opis` mówi „przetwarzane wyłącznie za wyraźną zgodą”. Nie ma też zgód marketingowych ani zgody na przekazanie danych ubezpieczycielowi (zob. §8).
- Boks błędu wysyłki (`Xe`): tytuł **„Nie udało się wysłać wniosku”**, tekst „Zadzwońcie na 504 400 901 — przejdziemy przez wniosek telefonicznie, żeby nie robić tego drugi raz.”, a pod nim komunikat techniczny (mono).

### 3.6 Strona `/podziekowanie/` (`podziekowanie.html`)
„Wniosek przyjęty” / **„Dziękujemy”** / „Twój wniosek dotarł. Nasz ekspert przeanalizuje dane i skontaktuje się z Tobą w ciągu 24 godzin roboczych z przygotowaną ofertą.” Sekcja „Co dzieje się dalej”:
- 01 **Analiza wniosku**: „Sprawdzamy dane pod kątem ofert Leadenhall Insurance S.A. i CEU sp. z o.o. i dobieramy wariant do Twojego zawodu.”
- 02 **Kontakt w ciągu 24 godzin roboczych**: „Oddzwonimy albo wyślemy e-mail z dopasowaną ofertą i dalszymi krokami.”
- 03 **Polisa wystawiona zdalnie**: „Dokumenty podpiszesz elektronicznie, składkę opłacisz przelewem. Bez wychodzenia z domu.”

Na dole: „Masz pytania? Zadzwoń pod 504 400 901 albo napisz na [e-mail biura Aura Expert] .” i linki „Przeczytaj wyłączenia” oraz „Pobierz OWU”.

Niespójność: na wniosku obiecano ofertę w „1–2 dni robocze”, a na podziękowaniu kontakt „w ciągu 24 godzin roboczych”.

### 3.7 Strona `/wycofaj-zgode/` (`wycofaj-zgode.html`)
- „Zgoda na kontakt” / **„Wycofanie zgody”** / „Ta strona wycofuje zgodę na kontakt w sprawie niedokończonego wniosku o ubezpieczenie utraty dochodu. Otwarta z linku w wiadomości e-mail wycofuje ją od razu, bez dalszych kroków: usuwamy Twoje dane kontaktowe ze szkicu wniosku i nie kontaktujemy się z Tobą w tej sprawie.” Status w trakcie: „Wycofuję zgodę…”.
- Stopka strony: „Nie działa albo wolisz inaczej? Napisz na info@utratadochodu.pl albo zadzwoń pod 504 400 901 — wycofamy zgodę za Ciebie. Do automatycznego wycofania ta strona potrzebuje JavaScriptu.”
- Sukces: **„Zgoda wycofana.”** „Usunęliśmy Twoje dane kontaktowe ze szkicu wniosku i nie będziemy się z Tobą kontaktować w tej sprawie. Jeśli wniosek został już wysłany, nic w nim się nie zmienia.”
- Błąd: **„Nie udało się wycofać zgody.”** „Napisz na info@utratadochodu.pl albo zadzwoń pod 504 400 901 — wycofamy ją ręcznie.”
- Link niepełny: **„Ten link jest niepełny.”** „Otwórz go ponownie z wiadomości e-mail albo napisz na info@utratadochodu.pl — wycofamy zgodę za Ciebie.”

### 3.8 Baner cookies (`zgody.js`)
Tytuł „Pliki cookies”. Opis: „Niezbędne cookies są potrzebne, żeby strona działała. Analityczne i marketingowe uruchamiamy dopiero wtedy, gdy się zgodzisz — do tego momentu nie wysyłamy żadnych danych do Google ani Meta. Szczegóły w [polityce cookies](/polityka-cookies/).”

Kategorie:
- **Niezbędne**: „Sesja formularza, zapamiętanie tej decyzji, ochrona przed botami. Zawsze włączone.”
- **Analityczne**: „Zliczanie odwiedzin i sprawdzanie, które podstrony są przydatne (Google Analytics 4).”
- **Marketingowe**: „Pomiar skuteczności reklam i remarketing (Google Ads, Meta Pixel).”

Przyciski: „Akceptuję wszystkie”, „Odrzucam wszystkie”, „Ustawienia” (po rozwinięciu zmienia się w „Zapisz wybrane”).

### 3.9 Modal awarii (`awaria.js`)
Tytuł „Coś poszło nie tak”. Opis: „Strona napotkała problem techniczny i Twoje zgłoszenie mogło do nas nie dotrzeć. Zadzwoń — załatwimy sprawę od ręki. Będziemy też wdzięczni za zgłoszenie tego błędu.”

Przyciski: „📞 504 400 901”, „Zgłoś błąd e-mailem”, „Zamknij”. Rozwijane „Szczegóły techniczne” z przyciskami „Kopiuj szczegóły” / „Skopiowano ✓”.

Mail trafia na info@utratadochodu.pl. Temat: „Zgłoszenie błędu na stronie ({kod})”. Treść zaczyna się od „Opisz krótko, co robiłeś/aś, gdy pojawił się błąd:”, potem „--- dane techniczne, zostaw bez zmian ---” i raport (Kod, Strona, Czas, Przeglądarka, Szczegóły ≤300 znaków).

---

## 4. Logika cen/taryf i dane

### 4.1 Kreator wniosku
**Nie liczy żadnej składki.** Zawiera tylko stałe limitów:
- limit świadczenia wg formy zatrudnienia (`re`): b2b 0,8, uop 0,65, zlecenie 0,65 (wyłącznie do tekstu podpowiedzi);
- max sum ubezpieczenia: NW 10 000 000, okresowa 50 000/mies., trwała 10 000 000;
- progi: klauzule NW przy `nwDeathSum > 300 000` (`ce = 3e5`), ankieta rozszerzona przy `permIncapacitySum > 1 000 000` (`ee = 1e6`). Parsowanie (`te`) usuwa spacje i NBSP, „zł” i „PLN”, zamienia pierwszy przecinek na kropkę i bierze pierwszą liczbę;
- kwoty klauzul (`ue`, l. 257–285):

| Klucz | Etykieta | Kwoty [zł] |
|---|---|---|
| `nwFuneral` | Świadczenie pogrzebowe | 0, 5 000, 10 000, 15 000, 20 000, 25 000 |
| `nwAdaptation` | Dostosowanie do życia w niepełnosprawności | 0, 10 000, 20 000, 30 000, 40 000, 50 000, 100 000, 150 000, 200 000 |
| `nwHospitalDaily` | Dzienne świadczenie szpitalne | 0, 100, 200, 300, 400, 500 (/ dzień) |
| `nwMedicalCosts` | Świadczenie do kosztów medycznych | 0, 500, 1 000, 2 500, 5 000, 10 000 |
| `nwUnconsciousWeekly` | Tygodniowe świadczenie z tytułu nieprzytomności | 0, 100, 250, 500, 1 000 (/ tydzień) |

### 4.2 Symulacja składki (wyspa Kalkulator, `Kalkulator.js`)
Kalibracja jest wbudowana w bundle (stała `w`, l. 36–49) i walidowana przy buildzie przez `N`/`P` (komunikat: „kalibracja.json jest niepoprawny — build zatrzymany”). Plik źródłowy to `kalibracja.json` w repozytorium serwisu:

```
policzono: 2026-10-14
zrodlo: { metoda: "osoby-v1", ubezpieczyciel: "Leadenhall",
          okno: { od: 2025-10-14, do: 2026-10-12 }, osob: 10, ofert: 11, wariantow: 22, par: { "36": 5 } }
stawka: { dol: 0.0202, srodek: 0.022, gora: 0.0322 }   // składka / świadczenie miesięczne
okresy: { "24": 1, "36": 1.25 }                         // mnożnik za okres wypłaty (w UI nieużywany)
```

Reguły walidacji kalibracji: 0,01 ≤ dół ≤ środek ≤ góra ≤ 0,05. Klucze `okresy` tylko z 24/36/48/60, wartości w [1; 2], `okresy["24"] = 1`, mnożniki rosnące.

**Wzór** (`fe`, l. 121–133):
```
limit       = 0.8                               // I.b2b; zawsze B2B, bez wyboru formy
swiadczenie = round(dochod * 0.8)
mnoznikHIV  = hivWzw ? 1.07 : 1                 // checkbox „Klauzula HIV / WZW”
skladkaOd   = round(swiadczenie * 0.0202 * mnoznikHIV)
skladka     = round(swiadczenie * 0.0220 * mnoznikHIV)   // nie pokazywana
skladkaDo   = round(swiadczenie * 0.0322 * mnoznikHIV)
wyświetlane: "{skladkaOd}–{skladkaDo} zł" (lub jedna kwota, gdy równe)
```
Suwak dochodu: min 3 000, max 60 000, krok 500, domyślnie 18 000. Okresy wypłaty `[24, 36, 48, 60]`. Składka dotyczy wariantu 24 mies. (mnożnika `okresy` UI nie stosuje). Inne limity (`I`): `{b2b:0.8, etat:0.65, ceu:0.65}`, ale używany jest tylko b2b.

**Zasiłek ZUS** (l. 145–166): `round(podstawa × 0.8629 × 0.8)`. Dla dużego ZUS-u (podstawa 5 652) wychodzi **3 902 zł**, dla preferencyjnego (1 441,80) **995 zł**, bez chorobowego 0 zł.

**Wartości kontrolne** (zgodne z tabelą na `/kalkulator/` i stronach zawodów):

| Dochód | Świadczenie | Składka (dół–góra) | z HIV/WZW |
|---|---|---|---|
| 10 000 | 8 000 | 162–258 zł | 173–276 zł |
| 11 000 | 8 800 | 178–283 zł | 190–303 zł |
| 18 000 | 14 400 | 291–464 zł | 311–496 zł |
| 30 000 | 24 000 | 485–773 zł | 519–827 zł |
| 50 000 | 40 000 | 808–1 288 zł | 865–1 378 zł |

**Moduł „Gdyby odkładać samodzielnie”** (`Se`, tylko na `/kalkulator/`): kwota odkładania ma suwak 50–2 000 zł, krok 10, a domyślnie jest równa górnej granicy składki zaokrąglonej do 10. Liczy się przy oprocentowaniu 3% rocznie (kapitalizacja miesięczna, wpłata na koniec miesiąca, bez inflacji).
- Liczba miesięcy do uzbierania 1× i 2× świadczenia: `ceil(log(1 + S·r/k)/log(1+r))`, gdzie `r = 0.03/12`.
- Stan po roku: `k·((1+r)^12 − 1)/r`, przeliczony na „dni świadczenia” przy miesiącu = 30 dni.

**Teksty kalkulatora (dosłownie):**
- Nagłówek: „Symulacja składki” albo „Symulacja składki dla {zawod}”.
- „Przesuń suwak, żeby zobaczyć, jak zmienia się świadczenie i szacowana składka.”
- Etykieta suwaka: „Miesięczny dochód netto z działalności lub B2B”.
- „Polisa obejmuje do 80% udokumentowanego dochodu z działalności lub kontraktu B2B.”
- „Na umowie o pracę ZUS wypłaca co najmniej 80% pensji przez 182 dni. Polisa chroni dochód przy dłuższej niezdolności.”
- Wiersz „Świadczenie z polisy”: „wypłacane co miesiąc, najdłużej przez 60 miesięcy”.
- Wiersz „Zasiłek chorobowy z ZUS”: „duży ZUS z chorobowym (na preferencyjnym ZUS-ie około 995 zł, bez chorobowego 0 zł)”.
- Wiersz „Szacowana składka miesięczna”: „wariant z wypłatą do 24 miesięcy, razem z opłatą dystrybucyjną; przedział z ostatnio wystawionych ofert”.
- CTA „Przejdź do wniosku” prowadzi do `/wniosek/` lub `/wniosek/?zawod={zawod}`.
- Trzy akapity zastrzeżeń:
  - „To jest symulacja, nie oferta. Realną składkę wylicza system ubezpieczyciela po ocenie ryzyka — może różnić się od tej kwoty. Zasiłek ZUS to 80% podstawy wymiaru składek po odliczeniu 13,71%, przy dużym ZUS-ie z najniższej podstawy (5 652 zł) i dobrowolnym chorobowym opłacanym od co najmniej 90 dni. Zasiłek to kwota przed podatkiem dochodowym.”
  - „Przedział składki policzyliśmy z ofert wystawionych w ostatnich 12 miesiącach, w wariancie porównywalnym z kalkulatorem: samo świadczenie miesięczne, wypłata najdłużej przez 24 miesiące, okres wyczekiwania do 21 dni, składka w ratach — od najtańszej do najdroższej stawki, jaka w nich wystąpiła, razem z opłatą dystrybucyjną, którą płaci się w racie. Na Twoją składkę wpłyną wiek, klasa ryzyka Twojego zawodu, długość okresu wyczekiwania, o które ten kalkulator nie pyta.”
  - „Świadczenie wypłacane jest najdłużej przez 24, 36, 48 albo 60 miesięcy — okres wybierasz przy zawarciu umowy. Powyższa składka dotyczy wariantu najkrótszego, 24-miesięcznego; dłuższy okres wypłaty podnosi składkę.”

Pełne teksty modułu odkładania są w `ext/ud/kalkulator.md` i JSON.

**Wniosek dla BeautyPolisy:** to jedyna „symulacja” w ekosystemie UD. Opiera się na 11 ofertach Leadenhall z 12 miesięcy i jednej stawce dla wszystkich zawodów, bez wieku i klasy zawodu. Jeśli portal ma pokazywać symulację po wniosku (zgodnie z obietnicą), trzeba ją wywołać z `tempIncapacitySum` (świadczenie wpisane w kroku 3) według wzoru `świadczenie × [0,0202; 0,0322]` i oznaczyć jako wariant 24-miesięczny. To decyzja projektowa, nie odtworzenie istniejącej logiki.

---

## 5. Wysyłka danych

Adresy pochodzą z `props` wyspy (`wniosek.html`). Adres projektu Supabase to wartość w konfiguracji, nie w dokumencie (*poprawka 13.11: usunięto stąd fragment identyfikatora projektu*). W kodzie składa go `funkcja(nazwa)` w `ud/apps/portal/src/lib/uslugi.ts`. Funkcje:
- `urlFunkcji` → `/functions/v1/form-submit`
- `urlSzkicu` → `/functions/v1/wniosek-szkic`

Klient **nie wysyła** nagłówków `apikey` ani `Authorization`, tylko `Content-Type: application/json`, więc funkcje muszą być wdrożone z `--no-verify-jwt`.

### 5.1 Finalna wysyłka (`xt`, l. 762–806)
- `POST {urlFunkcji}`, ciało JSON = `{ ...ge(W), ...he(location.search), "cf-turnstile-response": token }`.
- **`ge(W)`** (l. 440–460), kształt ładunku:
  - wszystkie pola stanu `W` (nazwy z §2) **bez** `zgodaKontakt` (zgoda na kontakt nie trafia do wniosku, żyje tylko w szkicu);
  - zamiana na `"Yes"`/`"No"` (true, `yes`, `Yes` i `on` dają `"Yes"`, reszta `"No"`) dla: 7 kluczy ankiety podstawowej (`med_heart`, `med_diabetes`, `med_bones`, `med_stomach`, `med_neuro`, `med_surgery`, `med_aids`), 15 `risk_*`, `riskDeathInvalidity`, `riskTempIncapacity`, `riskPermIncapacity`, `exclusions_accepted`, `employsPeople`, `informedAccepted` oraz **`nwPermanentDamage`**. Tego ostatniego pola nie ma w formularzu, więc zawsze idzie `"No"`, co wskazuje na schemat po stronie serwera;
  - gdy NIE (`riskDeathInvalidity` i `nwDeathSum > 300000`), pięć kluczy `nw*` klauzul dostaje 0;
  - przy `employsPeople`: `emp_contribution = "{slider}%"`, a `emp_contribution_slider` zostaje jako liczba;
  - przy ankiecie rozszerzonej, dla 20 pytań: `hs_<key> = "tak"|"nie"` i `hsd_<key> = opis` (string). Surowe `<key>` (`yes`/`no`/`""`) i `<key>_notes` też są w ładunku;
  - pozostałe pola idą bez zmian: stringi z inputów, liczby z `type=number` (Svelte `bind:value`), `""` dla nieruszonych. Sumy ryzyk niezaznaczonych też idą, jako `""` lub wpisana wartość. Pola `emp_*` poza sliderem są obecne tylko po edycji (inaczej `undefined`, więc pomijane w JSON).
- **`he()`**: `?agent=XYZ` daje `affiliateCode` (regex `^[A-Za-z0-9_-]{1,20}$`). Inna wartość jest pomijana.
- **Odpowiedź:** sukces, gdy `res.ok && body.status !== "error"` (body nieparsowalne = `{}` = sukces). Wtedy kolejno:
  1. `sessionStorage['ud:wniosek'] = crypto.randomUUID()` (znacznik konwersji);
  2. szkic `{akcja:"ukoncz", id}` z `keepalive:true`;
  3. `location.href = "/podziekowanie/"`.
- **Błąd:** `Error(body.message || "HTTP {status}")`. Komunikat trafia do boksu błędu, `turnstile.reset`, a potem wywoływane jest `window.Awaria.pokaz({kod:"WNIOSEK_WYSYLKA", szczegoly})`.

### 5.2 Szkic i lejek (`vt`, `yt`, `bt`, l. 697–761)
`POST {urlSzkicu}` z JSON, timeout 3 s (AbortController). Gdy brak `urlSzkicu`, nic nie jest wysyłane. Każdy błąd jest połykany (zwraca `null`).

| Akcja | Kiedy | Ładunek | Odpowiedź |
|---|---|---|---|
| `start` | pierwsze udane „Dalej” w kroku 1 **i** jest token niewidocznego Turnstile (bez tokenu nic nie wysyła) | `{akcja:"start", "cf-turnstile-response", zgoda:bool, zgoda_wersja:"v1-2026-10"}`, a **tylko przy zgodzie** dodatkowo `imie, email, phone` (trim) | `{id}` jako id szkicu. Brak id = reset, przy następnym „Dalej” w kroku 1 nastąpi ponowna próba |
| `kontakt` | ponowne „Dalej” w kroku 1 (po „Wstecz”), gdy zmieniła się zgoda lub dane (porównanie `JSON.stringify([zgoda, zgoda?dane:null])`) | przy zgodzie i tokenie: `{akcja:"kontakt", id, "cf-turnstile-response", zgoda:true, zgoda_wersja, imie, email, phone}`. W przeciwnym razie `{akcja:"kontakt", id, zgoda:false}` (przy zgodzie bez tokenu kod czyści stan porównania, żeby spróbować ponownie). **Skutek uboczny:** przy zaznaczonej zgodzie, ale bez tokenu niewidocznego Turnstile, klient wysyła `zgoda:false` – czyli na serwerze kontakt ze szkicu jest kasowany, mimo że użytkownik zgody nie cofnął | ignorowana |
| `krok` | udane „Dalej” w krokach 2, 3, 4 | `{akcja:"krok", id, krok:"dane"\|"zakres"\|"zdrowie"}` (id kroku **opuszczanego**) | ignorowana |
| `ukoncz` | po udanej wysyłce finalnej | `{akcja:"ukoncz", id}`, keepalive | — |
| `wycofaj` | strona `/wycofaj-zgode/#id=<id>&sig=<podpis>` (link z e-maila; hash czyszczony przez `history.replaceState`) | `{akcja:"wycofaj", id, sig}` | HTTP 2xx (`res.ok`; serwer zwraca `{status:"success"}`) → „Zgoda wycofana.”, inaczej błąd |

Wnioski:
- Szkic powstaje także **bez zgody**, jako anonimowy rekord lejka: `ostatni_krok`, `ukonczony_at`.
- Dane kontaktowe trafiają tam tylko przy zgodzie.
- Klient nie wysyła `zgoda_tresc`. Serwer musi mapować wersję `v1-2026-10` na treść (kolumna `zgoda_tresc`).
- `client_id`, `ip_hash`, `zgoda_at` i `przypomnienie_wyslane_at` ustala serwer.
- `sig` w linku wycofania podpisuje serwer. *Potwierdzone w repozytorium:* to HMAC-SHA256 z `wycofaj:<id>`, szczegóły w §9.2.

**Przypomnienia:** w kodzie klienckim nie ma żadnej logiki przypomnień. Z kodu wynika tylko tyle, że istnieje e-mail z linkiem `/wycofaj-zgode/#id=…&sig=…` dotyczący „niedokończonego wniosku” (tekst strony wycofania). Harmonogram, treść i warunki wysyłki są po stronie serwera. *Uzupełnione z repozytorium w §9.2.*

### 5.3 Turnstile
Skrypt `https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit&onload=onloadTurnstileCallback` ładowany jest async w `main`. Sitekey pochodzi z `props.kluczTurnstile` (jest w HTML, tu go nie powtarzam).
- **Krok 1:** widżet `appearance:"interaction-only"` (niewidoczny, chyba że Cloudflare zażąda interakcji), renderowany tylko gdy jest `urlSzkicu`. Jego token służy wyłącznie szkicowi.
- **Krok 5:** widżet widoczny, `language:"pl"`. Jego token idzie do `form-submit`.
- Jeśli API Turnstile jeszcze się nie wczytało, render następuje w `window.onloadTurnstileCallback`. Widżety są usuwane (`turnstile.remove`) przy zmianie kroku, a po błędzie wysyłki resetowane.

---

## 6. Logika poboczna

- **Parametr `?zawod=`**: komponent ma prop `zawodPoczatkowy` (inicjalizuje `profession`, l. 573, 580), ale **strona `/wniosek/` go nie przekazuje**. `props` zawiera tylko `zawody`, `urlFunkcji`, `urlSzkicu` i `kluczTurnstile`, a HTML dla `?zawod=fryzjer` i `?zawod=stylistki%20paznokci` jest identyczny. Żaden skrypt nie czyta `location.search` pod kątem `zawod`. **Parametr jest więc ignorowany.** Linki go jednak używają, i to niespójnie: strony zawodów linkują raz mianownikiem (`?zawod=fryzjer`, `?zawod=stylistka-paznokci`), raz dopełniaczem z kalkulatora (`?zawod=fryzjera`, `?zawod=stylistki%20paznokci`, `?zawod=masa%C5%BCysty`). W portalu warto prefillować zawód z parametru, normalizując go do nazwy z listy.
- **Parametr `?agent=`**: usuwa box „Kup online” (inline script w `aside`) i dodaje `affiliateCode` do wniosku.
- **Kalkulator**: `?dochod=`, `?swiadczenie=` (dochód = świadczenie / 0,8) i `?odkladam=` działają tylko w wariancie `zOdkladaniem` (strona `/kalkulator/`). Link „Wolisz odkładać samodzielnie? Policz, ile to potrwa” prowadzi do `/kalkulator/?dochod={d}#odkladanie`.
- **Analityka (`zgody.js`)**: Consent Mode v2 domyślnie ustawia `ad_storage`, `ad_user_data`, `ad_personalization` i `analytics_storage` na denied, a `functionality` i `security` na granted, z `wait_for_update:500`. Tryb **„basic”**: bez zgody nie ładuje gtag ani Pixela. Decyzja trafia do `localStorage['ud_zgody'] = {wersja:2, analityka, marketing, data}`; zmiana wersji oznacza ponowne pytanie. GA4 dostaje `anonymize_ip`, Ads ładuje się przy zgodzie marketingowej. **Meta Pixel nie startuje na `/wniosek/`, `/podziekowanie/` i `/wycofaj-zgode/`** (dane zdrowotne). Zdarzenie `ud:zgody` (CustomEvent) jest emitowane po decyzji. API: `window.UDCookies.{otworz, stan, konwersja(etykieta, dane)}`. Identyfikatory GA4, Ads i Pixela oraz etykieta konwersji są w `window.UD_TAGI` w `<head>` (tu ich nie powtarzam).
- **Konwersja** (`/podziekowanie/`): `UDCookies.konwersja(etykietaWniosek, {transaction_id: sessionStorage['ud:wniosek']})` odpala tylko przy zgodzie marketingowej i obecnym znaczniku. Wywołanie powtarza się po `ud:zgody` (gdy zgoda została udzielona dopiero na tej stronie). Znacznika się nie kasuje, a deduplikację zapewnia `transaction_id`.
- **Awaria (`awaria.js`)**: modal `window.Awaria.pokaz({kod, szczegoly, tytul?, opis?})`. Własny CSS, `role=dialog aria-modal`, Esc lub tło zamyka, fokus wraca do poprzedniego elementu, blokuje przewijanie `body`. Automatycznie (raz na wczytanie strony) pokazuje się przy `error` i `unhandledrejection` **z własnego originu**. Ignoruje: błędy ładowania zasobów, skrypty obce („Script error.”) oraz kod wstrzykiwany przez przeglądarki w aplikacjach (regex `WSTRZYKNIETE`: `_AutofillCallbackHandler`, `__gCrWeb`, `WeixinJSBridge` itd., albo plik = adres strony i linia ≤ 1). Zdarzenia GA: `awaria_modal`, `awaria_telefon`, `awaria_zgloszenie` z parametrem `kod_bledu`. Kody: `SKRYPT`, `PROMISE`, `WNIOSEK_WYSYLKA`.
- **Web Vitals (`__vitals.js`)**: TTFB, FCP, LCP, CLS (okno sesji 1 s / 5 s) i INP (przybliżony najdłuższą interakcją, próg 40 ms). Przy `visibilitychange:hidden` lub `pagehide` wysyła jeden `sendBeacon('/__vitals', text/plain {p: pathname, m: [[nazwa, wartość]]})`. Endpoint `/__vitals` jest po stronie serwera UD i nie ma CORS.
- **Cloudflare**: na końcu `body` jest wstrzykiwany skrypt challenge platform (`/cdn-cgi/challenge-platform/...`), część infrastruktury Cloudflare, a nie aplikacji.
- **GUS / NIP**: brak. Wniosek nie pyta o NIP ani firmę.
- **localStorage / sessionStorage**: `ud_zgody` (cookies) i `ud:wniosek` (znacznik konwersji). Stan formularza nie jest przechowywany.
- **Przekierowania**: po sukcesie `/podziekowanie/`. Link „Kup online” prowadzi do `/kup-online?z=wniosek` (dalej do Leadenhall; logiki przekierowania nie ma w kodzie klienckim).

---

## 7. Czego NIE da się odtworzyć z kodu klienckiego (do pozyskania od zleceniodawcy)

> **Stan po analizie repozytorium `ud` (13.11.2026):**
> - zamknięte: punkty 1, 2, 3 i 4 (kod funkcji, szkic, przypomnienia, e-maile);
> - częściowo: punkty 5, 6, 7 i 11 (5 – proces w panelu, §9.6; 6 – klauzula, polityka prywatności i regulamin, §9.4; 7 – proces kalibracji opisany, decyzja o symulacji otwarta, §10 U7; 11 – CORS i Turnstile opisane w §9.1, decyzja integracyjna otwarta);
> - otwarte: punkty 8–10.
>
> Szczegóły w §9 i §10. Lista poniżej zostaje w pierwotnym brzmieniu.

1. **Funkcja `form-submit`** (Supabase Edge, projekt CRM „aurabroker”):
   - weryfikacja Turnstile (secret);
   - walidacje serwerowe (czy powtarza PESEL i 18–65?);
   - mapowanie pól na tabelę, z pytaniami: które kolumny istnieją, bo pola `col` sugerują kolumny `weight_change, takes_meds, pending_diagnosis, disability_congenital, smoker, event_hospitalization, event_sick_leave_30, event_further_diagnosis, med_heart, med_neuro, med_stomach, med_bones, med_diabetes`; co z `hs_*`/`hsd_*` i 7 pytaniami bez `col`; skąd `nwPermanentDamage`;
   - kształt odpowiedzi (`status`, `message`);
   - deduplikacja, limity, obsługa `affiliateCode`;
   - powiązanie wniosku ze szkicem (klient nie wysyła `id` szkicu w `form-submit`, więc łączenie musi iść przez e-mail lub telefon albo wcale).
2. **Funkcja `wniosek-szkic`**: obsługa akcji `start/kontakt/krok/ukoncz/wycofaj`, schemat `ud_wnioski_szkice`, generowanie `client_id` i `ip_hash` (sól), zapis `zgoda_tresc` dla wersji, algorytm `sig` (HMAC, klucz) dla linku wycofania, retencja i usuwanie szkiców.
3. **Przypomnienia o niedokończonym wniosku**: harmonogram (cron), warunki (zgoda, brak `ukonczony_at`, brak `obsluzony_at`, `przypomnienie_wyslane_at`), liczba i odstępy, **szablon e-maila** (temat, treść, link do wycofania), nadawca, dostawca (Resend, SES itp.), ewentualne SMS-y lub telefony.
4. **E-maile po złożeniu wniosku**: potwierdzenie do klienta i powiadomienie do agenta (adresaci, szablony, załączniki OWU/KID?).
5. **Proces po stronie CRM**: kto i jak przygotowuje ofertę Leadenhall/CEU, statusy, SLA („24 godziny robocze” lub „1–2 dni robocze”).
6. **Treść dokumentów** z linków zgód: `/klauzula-informacyjna/`, `/regulamin/`, `/polityka-prywatnosci/`, `/polityka-cookies/`. Nie zostały pobrane. Dla BeautyPolisy i tak trzeba własnych dokumentów z prawidłowym administratorem i celami. `/wylaczenia/` jest w `ext/ud/wylaczenia.md`.
7. **Źródło `kalibracja.json`** i proces jej odświeżania (metoda „osoby-v1”, skąd 11 ofert). Pytanie, czy BeautyPolisa ma używać tej samej kalibracji, czy osobnej dla zawodów beauty.
8. **Ankieta ubezpieczyciela**: oryginalna treść pytań Leadenhall/CEU z okresami referencyjnymi. Pytania w kodzie są skrócone, np. „Operacje chirurgiczne lub stałe leki?” bez ram czasowych. Potrzebna jest akceptacja, że ten skrót wystarcza do underwritingu.
9. **`/kup-online`**: dokąd dokładnie przekierowuje (link afiliacyjny Leadenhall?) i czy BeautyPolisa ma go zachować.
10. **Brakujące pola**: czy dochód i okres wypłaty (24/36/48/60) mają się pojawić we wniosku, skoro opisy RODO kroków je wymieniają.
11. **Konfiguracja CORS** funkcji Supabase dla nowej domeny portalu i nowy sitekey/secret Turnstile dla domeny BeautyPolisy.

---

## 8. Uwagi bezpieczeństwa i RODO

- **W kodzie publicznym są** (to normalne dla frontendu, ale przy migracji trzeba je wymienić lub skonfigurować):
  - adres projektu Supabase (`props.urlFunkcji`/`urlSzkicu` i `data-url` na `/wycofaj-zgode/`);
  - sitekey Turnstile (`props.kluczTurnstile`);
  - identyfikatory GA4, Google Ads, Meta Pixel i etykieta konwersji (`window.UD_TAGI`).

  W żadnym z analizowanych plików **nie ma** anon key Supabase, bo funkcje są wywoływane bez JWT. Brak JWT oznacza, że jedyną ochroną endpointów jest Turnstile i walidacja serwerowa. Do weryfikacji, czy obie funkcje ją faktycznie robią. *Zweryfikowane 13.11 (§9.1, §9.2):* obie weryfikują Turnstile przez `siteverify` (bez sprawdzania `hostname`/`action`). `form-submit` ma walidację serwerową tylko częściową i nie ma limitu żądań.
- **Dane szczególnej kategorii (art. 9 RODO):** wniosek zbiera dane o zdrowiu (7–27 pytań, opisy chorób, HIV/AIDS, palenie, waga i wzrost). Brakuje wyraźnej zgody na przetwarzanie danych o zdrowiu. Jest tylko potwierdzenie zapoznania się z klauzulą, choć `G[3].opis` deklaruje „wyłącznie za wyraźną zgodą”. W portalu BeautyPolisy trzeba dodać osobny, niezaznaczony domyślnie checkbox zgody na dane zdrowotne (cel: ocena ryzyka i przygotowanie oferty, odbiorcy: ubezpieczyciel lub coverholder). Treść musi dostarczyć zleceniodawca lub prawnik.
- **Brak zgody na przekazanie danych ubezpieczycielowi/coverholderom** oraz brak klauzuli informacyjnej w samym formularzu. Jest tylko link.
- **PESEL** idzie w ładunku jawnie (HTTPS). Klient sprawdza tylko sumę kontrolną i wiek. W portalu warto ograniczyć logowanie PESEL-u i opisów zdrowia w Workerach i Sentry.
- **Szkic**: przy braku zgody kontakt nie jest wysyłany (zgodne z minimalizacją). Przy zgodzie kontakt jest zapisywany przed złożeniem wniosku na podstawie zgody wersjonowanej (`zgoda_wersja`). Wycofanie zgody odbywa się jednym kliknięciem z podpisanego linku. Ten wzorzec warto przenieść 1:1.
- **Analityka**: tryb „basic” (bez pingów przed zgodą), odrzucenie równie łatwe jak akceptacja i Pixel wyłączony na stronach z danymi zdrowotnymi. Też warto przenieść. GA4 i Ads przy zgodzie działają jednak również na `/wniosek/`. Zdarzeń z treścią pól nie ma, ale URL i ścieżka lejka trafiają do Google.
- **Turnstile**: token kroku 1 służy tylko szkicowi. Wysyłka finalna wymaga osobnego tokenu z kroku 5, a serwer musi weryfikować oba.
- **Modal awarii**: raport e-mail zawiera URL, user agent i komunikat błędu (≤300 znaków), bez danych z formularza. Przy `WNIOSEK_WYSYLKA` `szczegoly` to obiekt Error, a do raportu trafia sam `message`.
- **Brak trwałego zapisu stanu po stronie klienta**: plus dla prywatności, minus dla UX (odświeżenie gubi ankietę).
- **Pola o stałej wartości**: `nwPermanentDamage` zawsze `"No"`, a `riskTempIncapacity` zawsze `"Yes"`. Serwer nie powinien polegać na tych polach jako na wyborze klienta.

---

## 9. Backend i portal – analiza repozytorium `ud` (13.11.2026)

Źródło: `aurabroker/ud`, commit `793a158` (12.10.2026). Kod tylko czytany, bez uruchamiania. Wartości sekretów, identyfikatory projektu Supabase, klucze Turnstile, ID tagów i adresy odbiorców są w konfiguracji, nie w dokumencie. Projekt szkiców i przypomnień (uzasadnienie prawne, decyzje właściciela z 01.10.2026, kryteria odbioru) opisuje `ud/PLAN-NIEDOKONCZONE-WNIOSKI.md`; kod jest z nim zgodny w punktach sprawdzonych w §9.2.

### 9.1 `form-submit` – przyjęcie wniosku

**Kolejność obsługi** (`ud/supabase/functions/form-submit/index.ts`):
1. `OPTIONS` → `200 "ok"` z nagłówkami CORS (l. 158). Innych metod funkcja nie filtruje: `GET` bez ciała wywraca `req.json()` i kończy się 500 z wpisem w `ud_errors` (l. 161, 389–397).
2. Parsowanie JSON (l. 161), potem bramka sekretu Turnstile i weryfikacja tokenu (l. 163–178).
3. PESEL (l. 181–187), mapowanie na kolumny (l. 190–277).
4. Bramka ryzyka podstawowego (l. 285–293) i zerowanie kwot przy niewybranych ryzykach (l. 298–300).
5. Granice liczb (l. 303–312), zbiórka ankiety rozszerzonej (l. 316–324) i bramka ankiety (l. 328–342). Ankieta ma pierwszeństwo nad odpowiedziami podstawowymi (l. 346–349).
6. `form_data` (l. 353–356), usunięcie pustych pól (l. 359–361), `INSERT` do `ud_clients` kluczem `service_role` (l. 364–368).
7. Synchronizacja z GetResponse (l. 380–383), odpowiedź (l. 385–388).

**Turnstile – mechanizm.**
- `POST https://challenges.cloudflare.com/turnstile/v0/siteverify` z polami `secret` (sekret `TURNSTILE_SECRET_KEY`), `response` (token z `cf-turnstile-response`) i `remoteip` (nagłówek `CF-Connecting-IP`, jeśli jest) (l. 135–155).
- Przechodzi wyłącznie `success === true`. **Nie są sprawdzane `hostname` ani `action`.**
- Bez sekretu funkcja odpowiada 503 i zapisuje wpis w `ud_errors` (l. 166–172). Wcześniej (do 24.09.2026) brak sekretu oznaczał przepustkę (l. 137–141).
- Sekret musi pochodzić z tego samego widżetu, którego klucz stoi na stronie. Sekret innego widżetu odrzuci także prawdziwych klientów (`ud/CLAUDE.md:414-428`).
- **Wniosek dla portalu:** token z widżetu BeautyPolisy przejdzie w `form-submit` tylko wtedy, gdy będzie to ten sam widżet (z domeną portalu dodaną do jego hostnames) albo gdy funkcja dostanie drugi sekret. Funkcja nie sprawdza `hostname`, więc pierwszy wariant technicznie zadziała.

**Walidacje serwerowe – co jest, a czego nie ma:**

| Sprawdzane | Kod | Odpowiedź |
|---|---|---|
| PESEL: wyłącznie `/^\d{11}$/` | l. 181–187 | 400 „Nieprawidłowy PESEL.” |
| Okresowa niezdolność zaznaczona (`risk_temp_incapacity === true`) i `temp_incapacity_sum > 0` | l. 285–293 | 400 „Polisy nie da się zawrzeć bez „Okresowej niezdolności do pracy" — to ryzyko podstawowe. Zaznacz je i wpisz kwotę miesięczną.” |
| Waga 30–200 i wzrost 100–250 (puste dozwolone) | `GRANICE_CIALA`, l. 88–91 | 400 „Waga musi mieścić się między 30 a 200 kg.” / „Wzrost musi mieścić się między 100 a 250 cm.” |
| Sumy: okresowa ≤ 50 000, trwała ≤ 10 000 000, NW ≤ 10 000 000 (tylko przy zaznaczonym ryzyku; ścisły odczyt liczby `liczbaScisla`) | `GRANICE_SUM`, l. 80–87, 99–128 | 400 „Świadczenie miesięczne z okresowej niezdolności może wynosić najwyżej 50 000 zł.” / „Suma trwałej niezdolności do pracy może wynosić najwyżej 10 000 000 zł.” / „Suma na wypadek śmierci / inwalidztwa (NW) może wynosić najwyżej 10 000 000 zł.”, dodatkowo wpis w `ud_errors` „Wniosek poza granicami: <pole>” |
| Ankieta rozszerzona: gdy `risk_perm_incapacity` i suma trwałej > 1 000 000, musi przyjść **co najmniej jedno** pole `hs_*` z wartością `tak`/`nie` | l. 328–342 | 400 „Przy sumie trwałej niezdolności powyżej 1 000 000 zł wymagana jest pełna ankieta medyczna. Odśwież formularz i wypełnij wszystkie pytania.” |

**Nie są sprawdzane po stronie serwera:**
- imię i nazwisko, format e-maila i telefonu;
- suma kontrolna PESEL-u i wiek 18–65 (sprawdza je tylko kreator, `ud/packages/wniosek/src/schemat.js:323-332`);
- zawód;
- kwoty klauzul NW, pola B2B i długość pól tekstowych (świadomie, `ud/CLAUDE.md:1030-1032`);
- komplet 20 odpowiedzi ankiety;
- **oba potwierdzenia z kroku 5 (`exclusions_accepted`, `informedAccepted`).** Funkcja tylko je mapuje. Wniosek z `"No"` albo bez nich zostanie zapisany.

**Mapowanie pól na kolumny `ud_clients`** (l. 190–277). Część pól ma dwie nazwy (`body.a ?? body.b`), zwykle camelCase przed snake_case (np. `body.fullName ?? body.full_name`, l. 192). Pola `med_*` odwrotnie: najpierw snake_case (`body.med_heart ?? body.medHeart`, l. 221–227). Pozostałe pola mają tylko jedną nazwę: `email`, `phone`, `profession`, `source`, `weight`, `height`, `handedness`, `emp_*`, `smoker` i 15 sportowych `risk_*` (l. 193–218, 234, 242–256):

| Ładunek | Kolumna | Uwagi |
|---|---|---|
| `fullName`, `email`, `phone`, `pesel` | `full_name`, `email`, `phone`, `pesel` | PESEL zapisywany **jawnym tekstem**. `.env.example` deklaruje `PESEL_ENCRYPTION_KEY` (`form-submit/.env.example:7-9`), ale kod funkcji go nie używa. Panel opiera się na jawnym PESEL-u: kod oferty to `right(pesel, 4)` (`ud/CLAUDE.md:1290-1306`) |
| `employmentType`, `profession`, `taxForm`, `handedness`, `weight`, `height` | `employment_type`, `profession`, `tax_form`, `handedness`, `weight`, `height` | waga i wzrost po normalizacji do liczby (l. 116–128) |
| `source` | `source` | domyślnie `'form'`. Wartości nie ogranicza żadna lista (l. 198) |
| `affiliateCode` | `affiliate_code_used` | bez walidacji po stronie serwera (regex jest tylko w kreatorze, `schemat.js:452-459`) |
| `employsPeople` | `employs_people` (bool) | — |
| `emp_startDate`, `emp_industry`, `emp_character`, `emp_area`, `emp_count_2024`, `emp_count_current`, `emp_contribution`, `emp_description` | `b2b_start_date`, `b2b_industry`, `b2b_character`, `b2b_area`, `b2b_employees_2024`, `b2b_employees_2025`, `b2b_own_contribution`, `b2b_description` | `emp_character` i `emp_area` czeka kolumna, ale kreator ich nie wysyła. `emp_count_current` trafia do kolumny `…_2025` |
| `med_heart`, `med_diabetes`, `med_bones`, `med_stomach`, `med_neuro`, `med_surgery`, `med_aids` | te same (bool) | `yesNo()` przyjmuje `Yes/yes/true` i `No/no/false`, reszta daje `null` (l. 36–40) |
| `weight_change`, `takes_meds`, `pending_diagnosis`, `disability_congenital`, `smoker`, `event_hospitalization`, `event_sick_leave_30`, `event_further_diagnosis` | te same (bool) | wypełniane z ankiety `hs_*` (l. 56–70, 346–349) |
| `hs_med_locomotor` | `med_bones` | wyjątek mapy `HEALTH_SURVEY_COLUMNS` (l. 68) |
| 15 × `risk_*` | te same (bool) | — |
| `riskDeathInvalidity`, `riskTempIncapacity`, `riskPermIncapacity` | `risk_death_invalidity`, `risk_temp_incapacity`, `risk_perm_incapacity` | — |
| `tempIncapacitySum`, `permIncapacitySum`, `nwDeathSum` | `temp_incapacity_sum`, `perm_incapacity_sum`, `nw_death_sum` | `null`, gdy ryzyko niewybrane (l. 298–300) |
| `nwFuneral`, `nwAdaptation`, `nwHospitalDaily`, `nwMedicalCosts`, `nwUnconsciousWeekly` | `nw_funeral`, `nw_adaptation`, `nw_hospital_daily`, `nw_medical_costs`, `nw_unconscious_weekly` | bez walidacji |
| `nwPermanentDamage` | `nw_permanent_damage` (bool) | kreator zawsze wysyła `"No"`; to pozostałość starego formularza |
| `exclusions_accepted`, `informedAccepted` | `exclusions_accepted`, `informed_accepted` (bool) | bez wersji i treści |
| całe ciało bez `cf-turnstile-response` + `health_survey` | `form_data` (jsonb) | `health_survey = {<key>: {answer:"tak"\|"nie", details}}` dla 20 pytań. **Tu, a nie w kolumnach, siedzi 7 pozycji bez `col`** (`med_thyroid`, `med_urinary`, `med_respiratory`, `med_oncology`, `med_spine_degenerative`, `med_allergy`, `med_other`). To świadoma decyzja (`ud/CLAUDE.md:1087-1098`) |

Pola z wartością `null`, `undefined` albo `''` są wycinane przed zapisem, więc działają wartości domyślne kolumn (l. 359–361). Pełna definicja `ud_clients` **nie jest w repozytorium**: starsze migracje istnieją tylko w panelu Supabase (`ud/CLAUDE.md:374-375`), a `ud/supabase/tests/stub.sql:39-58` to skrócona atrapa testowa.

**Deduplikacja: brak.** Każde udane wywołanie tworzy nowy wiersz `ud_clients`. Funkcja nie sprawdza PESEL-u, e-maila ani klucza idempotencji. Wiązanie z szkicem robi SQL po e-mailu, dla klienta utworzonego po szkicu (`ud/supabase/migrations/20261001101112_wnioski_szkice.sql:131-149`). Duplikat PESEL-u wykrywa tylko panelowe „Dodaj polisę” (`klient_istnieje`, `ud/CLAUDE.md:1707-1712`).

**`affiliateCode` i agent.** Kod zapisuje się w `affiliate_code_used`. Opiekuna leada ustala `ud_leady_synchronizuj()`: pierwsza niepusta wartość z `referred_by`, profilu z `ud_user_profiles.affiliate_code` równym kodowi (po `btrim`) i autora oferty, a dopiero potem filtr „konto aktywne” (`ud/supabase/migrations/20261004200000_leady_kanban_5_prowizja_polisy.sql:494-505`). Skutki: nieznany kod przechodzi dalej, do autora oferty (jeśli jest); kod **nieaktywnego** agenta daje lead bez opiekuna, który czeka na przydział administratora (bez przejścia do autora oferty). *Poprawka 13.11: wcześniej napisano, że nieznany kod też daje lead bez opiekuna.* Link agenta ma postać `https://utratadochodu.pl/wniosek/?agent=<kod>`, a kod nadaje `ud_agent_kod()` (`ud/CLAUDE.md:1670-1680`). **Rozjazd dokumentacji z kodem:** `ud/CLAUDE.md:1678-1679` zakłada, że nieznany kod też daje lead bez opiekuna („nieaktywny albo nieznany kod — lead bez opiekuna, czeka na przydział”); kod robi inaczej (komentarz i zapytanie w `…_kanban_5_…sql:494-505`). Do potwierdzenia u zleceniodawcy, które zachowanie jest zamierzone. Ma to znaczenie, jeśli portal przekazuje `affiliateCode`: literówka w kodzie albo kod spoza panelu UD przypisze lead autorowi oferty, a nie zostawi go administratorowi.

**Odpowiedzi** (wszystkie `application/json` z CORS):

| HTTP | Ciało | Kiedy |
|---|---|---|
| 200 | `{status:"success", supabase:"ok", getresponse:<bool>}` | zapis udany |
| 400 | `{status:"error", message:"Weryfikacja bezpieczeństwa nie powiodła się. Odśwież stronę i spróbuj ponownie."}` | brak lub zły token |
| 400 | `{status:"error", message:<komunikat walidacji z tabeli wyżej>}` | PESEL, ryzyko podstawowe, granice, ankieta |
| 503 | `{status:"error", message:"Formularz jest chwilowo niedostępny. Zadzwoń: 504 400 901 albo napisz na info@utratadochodu.pl."}` | brak sekretu Turnstile |
| 500 | `{status:"error", message:"Błąd zapisu. Spróbuj ponownie."}` | błąd `INSERT`, wpis w `ud_errors` z kodem błędu |
| 500 | `{status:"error", message:"Nieoczekiwany błąd serwera."}` | każdy inny wyjątek, w tym niepoprawny JSON |

Kreator pokazuje `message` w boksie błędu (`ud/apps/portal/src/components/Wniosek.svelte:290-340`).

**CORS:** `Access-Control-Allow-Origin: *`, `Access-Control-Allow-Headers: authorization, x-client-info, apikey, content-type` (l. 5–8). Nie ma `Allow-Methods` ani ograniczenia originu.

**Uwierzytelnianie:** brak. Funkcja działa z `verify_jwt = false` (`ud/CLAUDE.md:381-397`), a jedyną bramką jest Turnstile. Do bazy pisze kluczem `service_role` z sekretów funkcji.

**Limit żądań:** brak w `form-submit`. Jest tylko w `wniosek-szkic` (10 szkiców na godzinę na skrót IP, §9.2).

**Skutki uboczne do decyzji:**
- **GetResponse:** przy ustawionych `GETRESPONSE_API_KEY` i `GETRESPONSE_LIST_ID` każdy wnioskodawca (imię, nazwisko, e-mail) trafia na listę GetResponse, **bez żadnej zgody marketingowej** (l. 11–34, 380–383). Repozytorium nie mówi, czy sekrety są ustawione na produkcji. Klauzula informacyjna mówi o kontakcie marketingowym tylko „gdy zaznaczysz odpowiednie pole”, a takiego pola nie ma (§9.4). Wymaga sprawdzenia i rozstrzygnięcia przed jakimkolwiek przekazywaniem wniosków z portalu.
- `ud_errors` zapisuje surowy adres IP (`_shared/logger.ts:14-20`). Repozytorium nie określa retencji.
- Monitor (`ud/apps/monitor/README.md:14-25`) wysyła do `form-submit` sondy kontraktowe (błędne dane, oczekiwany kształt odpowiedzi 400) i liczy zgłoszenia („sonda ciszy”). Wnioski z portalu zapisane w `ud_clients` liczyłyby się w niej razem z UD.

### 9.2 `wniosek-szkic` i `wniosek-przypomnienie`

#### `wniosek-szkic` (`ud/supabase/functions/wniosek-szkic/index.ts`)

**Wejście:** tylko `POST`. Inna metoda daje 405 „Niedozwolona metoda.” (l. 115–119), więc skaner linków nie wycofa zgody za klienta. Ciało JSON albo `application/x-www-form-urlencoded` (RFC 8058, one-click z nagłówka `List-Unsubscribe-Post`), scalone z parametrami adresu (`parsujWejscie`, l. 97–113). Niepoprawne ciało daje 400 „Nieprawidłowy format danych.”. Funkcja czyta **wyłącznie** pola `akcja`, `id`, `zgoda`, `zgoda_wersja`, `imie`, `email`, `phone`, `krok`, `sig` i `cf-turnstile-response`. PESEL i ankieta nie mają dokąd trafić (komentarz l. 15–19). CORS jak w `form-submit` (l. 35–38). `verify_jwt = false`.

**Walidacja kontaktu** `sprawdzKontakt` (l. 86–95): imię po trim, niepuste, do 100 znaków; e-mail do 150 znaków, zamieniony na małe litery, `/^[^@\s]+@[^@\s]+\.[^@\s]{2,}$/`; telefon do 30 znaków i co najmniej 9 cyfr.

| Akcja | Bramki | Działanie | Odpowiedź |
|---|---|---|---|
| (wspólne) | `akcja` z listy; `id` jako UUID dla wszystkich poza `start` (l. 156–161) | — | 400 „Nieznana akcja.” / „Nieprawidłowy identyfikator.”; wyjątek: 500 „Nieoczekiwany błąd.” (w `ud_errors` tylko nazwa akcji i komunikat, bez ciała) |
| `start` | Turnstile (503 bez sekretu, 400 „Weryfikacja bezpieczeństwa nie powiodła się.”), sekret HMAC (503); przy zgodzie: znana wersja i poprawny kontakt, inaczej 400 „Nieprawidłowe dane kontaktowe.”; limit **10 szkiców na godzinę na `ip_hash`**, inaczej 429 „Zbyt wiele prób. Spróbuj później.” | `INSERT` z `ostatni_krok='kontakt'`, `ip_hash`, `zgoda_kontakt`. Przy zgodzie dodatkowo `zgoda_wersja`, **`zgoda_tresc` z mapy serwera `ZGODY`** (l. 51–55), `zgoda_at` i kontakt (l. 169–222) | 200 `{status:"success", id}` |
| `kontakt` | przy `zgoda:true` jak `start` (bez limitu); przy `false` – nic | zgoda: kontakt + wersja + treść + `zgoda_at`; brak zgody: `zgoda_kontakt=false` i wyczyszczenie imienia, e-maila i telefonu; tylko gdy `ukonczony_at is null` (l. 225–259) | 200 `{status:"success"}` |
| `krok` | `krok` ∈ {`dane`,`zakres`,`zdrowie`}, inaczej 400 „Nieznany krok.” | przesunięcie `ostatni_krok` **tylko do przodu** (l. 262–277) | 200 |
| `ukoncz` | — | RPC `ud_wnioski_szkic_ukoncz(p_id)`: `ukonczony_at`, `ostatni_krok='zgody'`, `client_id` po e-mailu, wyczyszczenie kontaktu (l. 280–284; migracja l. 131–149) | 200 |
| `wycofaj` | sekret (503); podpis `sig`, inaczej 403 „Nieprawidłowy lub wygasły link.” | `zgoda_kontakt=false`, `zgoda_wycofana_at`, wyczyszczenie kontaktu (l. 286–303) | 200 `{status:"success"}`, także gdy szkicu już nie ma |

**Schemat `ud_wnioski_szkice`** (`ud/supabase/migrations/20261001101112_wnioski_szkice.sql:22-62`):

| Kolumna | Typ / ograniczenie |
|---|---|
| `id` | uuid PK, `gen_random_uuid()` |
| `created_at`, `updated_at` | timestamptz not null default now(); `updated_at` ustawia funkcja jawnie (bez wyzwalacza) |
| `ostatni_krok` | text not null default `'kontakt'`, check ∈ (`kontakt`,`dane`,`zakres`,`zdrowie`,`zgody`) |
| `ukonczony_at` | timestamptz |
| `client_id` | uuid → `ud_clients(id)` on delete set null |
| `zgoda_kontakt` | boolean not null default false |
| `zgoda_wersja`, `zgoda_tresc`, `zgoda_at`, `zgoda_wycofana_at` | text, text, timestamptz, timestamptz |
| `imie`, `email`, `phone` | text, odpowiednio ≤ 100 / 150 / 30 znaków |
| `przypomnienie_wyslane_at`, `obsluzony_at` | timestamptz |
| `ip_hash` | text |
| Ograniczenia | `szkic_kontakt_tylko_za_zgoda`: bez zgody imię, e-mail i telefon muszą być `null`; `szkic_zgoda_udokumentowana`: zgoda wymaga wersji, treści i czasu; `szkic_ukonczony_to_ostatni_krok` |

- Indeksy: `(ip_hash, created_at)`, częściowy pod przypomnienia, `lower(email)`, `updated_at` (l. 67–75).
- RLS włączone **bez polityk**; `revoke all` od `anon` i `authenticated` (l. 77–80).
- Obok: `ud_lejek_wniosku_archiwum` (tydzień × krok × liczba) i widok `ud_lejek_wniosku` (`security_invoker`) (l. 84–124).

**`ip_hash` – mechanizm** (`ud/supabase/functions/_shared/szkic-podpis.ts:36-40`): HMAC-SHA256 z kluczem `SZKIC_HMAC_SECRET` nad napisem `ip:<adres>`. Adres pochodzi z `CF-Connecting-IP`. Wynik w hex, obcięty do pierwszych 32 znaków (128 bitów). Osobnej soli nie ma: klucz jest wspólny z podpisem linku, a rozdzielają je przedrostki `ip:` i `wycofaj:` (l. 1–8). Bez nagłówka IP limit nie działa (`wniosek-szkic/index.ts:182-196`). Retencja zeruje `ip_hash` dobę po `created_at`.

**Podpis `sig` linku wycofania – algorytm** (`szkic-podpis.ts:24-34`):
- `sig = hex(HMAC-SHA256(klucz = SZKIC_HMAC_SECRET, wiadomość = "wycofaj:" + id))`, czyli 64 znaki hex.
- Weryfikacja: dekodowanie hex z wymogiem 32 bajtów, potem `crypto.subtle.verify` (stały czas).
- **Podpis nie wygasa.** Komunikat mówi o „wygasłym” linku, ale algorytm nie zawiera daty. Link działa, dopóki nie zmieni się sekret.
- Wartość klucza jest w sekretach funkcji, nie w dokumencie.

**Retencja** (`ud_wnioski_szkice_retencja()`, migracja l. 156–183; pg_cron `wnioski-szkice-retencja`, `20 2 * * *` UTC, l. 185–194):
- `ip_hash` jest zerowany po 1 dniu;
- szkice z `updated_at` starszym niż 30 dni są usuwane, a ich liczby trafiają do archiwum lejka;
- dane kontaktowe znikają od razu przy `ukoncz` i przy bezpieczniku w funkcji przypomnień.

#### `wniosek-przypomnienie` (`ud/supabase/functions/wniosek-przypomnienie/index.ts`)

**Harmonogram:** pg_cron `wnioski-przypomnienia`, `10 * * * *` (co godzinę o :10 UTC). Woła `ud_wnioski_przypomnienia()`, a ta wysyła `net.http_post` z nagłówkiem `x-cron-token` z Vaulta (migracja l. 256–291). Zadanie powstaje wyłączone. Według projektu jest **włączone od 01.10.2026**, po akceptacji treści zgody przez prawnika (`ud/CLAUDE.md:1234-1250`).

**Bramka:** tylko `POST` (405). Bez nagłówka 401 „brak nagłówka x-cron-token”. Nagłówek sprawdza `edge_cron_token_matches` **przed** odczytem danych (l. 173–187). Bez klucza Resend albo `SZKIC_HMAC_SECRET` funkcja odpowiada 503 z wpisem w `ud_errors` (l. 192–198).

**Kandydaci** (`ud_wnioski_do_przypomnienia(opoznienie => '3 hours', maks => 50)`, migracja l. 215–254):
- Najpierw bezpiecznik: szkice z e-mailem, który pojawił się już w `ud_clients` po dacie szkicu, są zamykane jako ukończone, a kontakt czyszczony.
- Potem wybór: `zgoda_kontakt`, nieukończony, nie `obsluzony`, bez wysłanego przypomnienia, z e-mailem, ostatnia aktywność ponad 3 h temu, szkic utworzony w ciągu ostatnich 7 dni.
- Na adres nie mogło wyjść inne przypomnienie w ciągu 30 dni. Jeden adres to jeden kandydat (`distinct on lower(email)`), najwyżej 50 na uruchomienie.

**Wysyłka:**
- Szkic jest zajmowany warunkowym `UPDATE przypomnienie_wyslane_at` przed wysłaniem (l. 207–221).
- Wysyłka przez Resend (`RESEND_API_KEY`, zapasowo `RESEND2_API_KEY`).
- Przy porażce szkic wraca do puli, wpis „Resend odmówił wysyłki (HTTP n)” trafia do `ud_errors` (adresy zamaskowane), a uruchomienie kończy się 502 (l. 223–237).
- Odpowiedź udana: `200 {"ok":true,"kandydatow":n,"wyslano":n}`.

**Nadawca:** `UtrataDochodu <info@utratadochodu.pl>`, reply-to: ten sam adres serwisu (l. 31–32). Domena `utratadochodu.pl` musi być zweryfikowana w Resend (`ud/CLAUDE.md:1225-1230`).

**Nagłówki:**
- `List-Unsubscribe: <{SUPABASE_URL}/functions/v1/wniosek-szkic?akcja=wycofaj&id=…&sig=…>, <mailto:{reply-to}?subject=Wycofanie%20zgody>`;
- `List-Unsubscribe-Post: List-Unsubscribe=One-Click` (l. 147–166).

**Link wycofania:** `https://utratadochodu.pl/wycofaj-zgode/#id=<id>&sig=<sig>` (fragment, l. 144–146).

**Treść e-maila** (dosłownie, wersja tekstowa; HTML ma te same zdania, przycisk „Wróć do wniosku” i link „Wycofaj zgodę jednym kliknięciem.”, l. 72–140):

> **Temat:** Pomożemy dokończyć wniosek o ubezpieczenie utraty dochodu
>
> Dzień dobry,
>
> wniosek o ubezpieczenie utraty dochodu na UtrataDochodu.pl nie został dokończony. Jeśli coś się po drodze zacięło — wątpliwość, pytanie o zakres ochrony, brakująca informacja — chętnie pomożemy.
>
> Zadzwoń: 504 400 901 — przejdziemy przez wniosek razem. Możesz też odpowiedzieć na tę wiadomość.
>
> Jeśli wolisz wrócić do wniosku sam(a): https://utratadochodu.pl/wniosek/?utm_source=przypomnienie&utm_medium=email&utm_campaign=niedokonczony-wniosek
> Wniosek wypełnia się od nowa — zajmuje około pięciu minut.
>
> —
> Dostajesz tę wiadomość, ponieważ na UtrataDochodu.pl udzielono zgody na kontakt w sprawie wniosku z tego adresu e-mail. Piszemy jednorazowo i nie częściej niż raz na 30 dni.
> Wycofaj zgodę jednym kliknięciem: {link wycofania}
>
> Aura Expert spółka z ograniczoną odpowiedzialnością z siedzibą w Warszawie przy ul. Bolkowskiej 2A lokal 28, wpisana do Krajowego Rejestru Sądowego pod numerem 0000599840 przez Sąd Rejonowy dla m.st. Warszawy, XII Wydział Gospodarczy Krajowego Rejestru Sądowego, kapitał zakładowy 5.000 zł. Spółka wpisana jest do Rejestru Pośredników Ubezpieczeniowych pod numerem 11229690/A. ul. Bolkowska 2A/28, 01-466 Warszawa | REGON 363673048 | NIP 5242793544

Celowo **bez imienia** z formularza i **bez informacji, na którym kroku** klient przerwał, bo krok „zdrowie” to już informacja o zdrowiu (l. 18–23; `ud/CLAUDE.md:1211-1221`).

**SMS:** do szkiców **nie ma** przypomnień SMS. Kontakty ze zgodą trafiają na listę panelu „Niedokończone”, a agent dzwoni do nich ręcznie i oznacza je jako „Obsłużony”:
- `ud/apps/panel/src/lib/server/niedokonczone.js:9-22`;
- flaga `ZGODA_ZATWIERDZONA = true` w `ud/apps/panel/src/routes/panel/niedokonczone/+page.server.js:29`.

SMS-y istnieją tylko w obsłudze **oferty** (panel, SMSAPI, bez linku i bez polskich znaków; `ud/apps/panel/src/lib/server/smsOferta.js:23-24, 55-56`):
- po wysłaniu oferty: „UtrataDochodu: Wlasnie wyslalismy do Ciebie oferte. Sprawdz maila (takze folder Spam). Pytania: 504 400 901”;
- przypomnienie 3–30 dni po wysyłce bez odpowiedzi, dni robocze 9:00–18:59, cron `oferty-przypomnienia-sms` `25 * * * *`: „UtrataDochodu: Kilka dni temu wyslalismy Ci oferte ubezpieczenia na e-mail. Masz pytania? Chetnie pomozemy: 504 400 901” (`ud/CLAUDE.md:1351-1456`).

### 9.3 E-maile i powiadomienia po złożeniu wniosku

`form-submit` **niczego nie wysyła**. Powiadomienia wychodzą trzema drogami:

1. **Wyzwalacz bazy `send-confirmation-email-full`** (Database Webhook na `INSERT` w `ud_clients`) woła funkcję `send-confirmation-email`.
   - Wyzwalacz jest zdefiniowany tylko w panelu Supabase, nie w migracjach.
   - W definicji ma jawny JWT `service_role`; projekt planuje przenieść go na wzorzec z Vaultem (`ud/CLAUDE.md:409-412, 1539, 1719-1724`).
   - Funkcja wysyła przez Resend (`RESEND2_API_KEY`) jako `UtrataDochodu.pl <noreply@utratadochodu.com>`, reply-to `[e-mail biura Aura Expert]` (`ud/supabase/functions/send-confirmation-email/index.ts:3-5, 268-281`).
2. **SMS do doradcy** przez SMSAPI, na numer ze zmiennej `ADVISOR_PHONE` (domyślnie infolinia serwisu), tekst spłaszczony do ASCII (l. 13–30, 292–297):
   > UtrataDochodu: nowy wniosek. {full_name}, tel {phone}, {email}, zawod: {profession}
3. **Raport co 2 godziny** `send-digest-email` (pg_cron `digest-email-2h` przez `ud_send_digest_email()` z `x-cron-token`; `ud/supabase/migrations/20260924191031_edge_cron_token.sql:51-101`).
   - Trafia na skrzynkę biura serwisu (adres w kodzie, nie w dokumencie).
   - Temat: `[{N} zgłoszeń] Raport UtrataDochodu.pl — {data i godzina}`.
   - Treść: tabela imię / telefon / e-mail / zawód / godzina oraz przycisk „Otwórz bazę danych →”.
   - Pola są escapowane (`ud/supabase/functions/send-digest-email/index.ts`).

**Opiekun (agent) nie dostaje e-maila.** Lead pojawia się na tablicy w panelu przy najbliższej synchronizacji (§9.6). Potwierdzenie nie ma załączników (OWU i karta produktu idą dopiero z ofertą z panelu). `apps/portal/public/email/` zawiera tylko obrazki newslettera i logo, nie szablony transakcyjne (`ud/CLAUDE.md:2047-2062`).

**Szablon e-maila do klienta – pełny wniosek** (dosłownie, treść bez stylów; `send-confirmation-email/index.ts:163-239`):

> **Temat:** UtrataDochodu.pl - Twoje prywatne L4
>
> [nagłówek] utratadochodu.pl / Aura Expert Sp. z o.o. (wersalikami tylko przez CSS `text-transform:uppercase`, l. 178–179)
>
> Cześć {pierwszy wyraz full_name},
>
> Twój kompletny wniosek ubezpieczeniowy dotarł. Przekazaliśmy go do weryfikacji przez naszych partnerów — **CEU sp. z o.o.** i **Leadenhall Insurance SA**.
>
> 1 Weryfikacja wniosku: **1–2 dni robocze**
> 2 Oferta na Twój email z porównaniem obu produktów
> 3 Jeśli będziemy potrzebować uzupełnienia — skontaktujemy się telefonicznie
>
> Masz pytania?
> Napisz: [e-mail biura Aura Expert] | Zadzwoń: +48 504 400 901
>
> Aura Expert Sp. z o.o. · agent ubezpieczeniowy wpisany do rejestru KNF
> Ubezpieczyciele: CEU sp. z o.o. oraz Leadenhall Insurance SA
> utratadochodu.pl

Tytuł dokumentu HTML: „Wniosek przyjęty”. Ta sama funkcja ma drugi szablon (szybki kontakt, tabela `udochodu_contacts`) z tym samym tematem, l. 104–160. Do wniosku z portalu nie ma zastosowania.

**Uwagi do przeniesienia:**
- Szablon wstawia imię, a w szybkim kontakcie także telefon i zawód, **bez escapowania HTML** (l. 96–102, 123–125, 182). Raport (`send-digest-email`) i przypomnienie escapują. W portalu (W4) trzeba escapować wszystko.
- Rozjazd terminów: e-mail mówi „Weryfikacja wniosku: 1–2 dni robocze”, a `/podziekowanie/` mówi „w ciągu 24 godzin roboczych” (§3.6).
- Domeny nadawców są różne: potwierdzenie wychodzi z `utratadochodu.com`, przypomnienie z `utratadochodu.pl`.
- Logi funkcji: każde wysłanie zapisuje w logu adres odbiorcy (`console.log`, l. 290), a rekord bez e-maila trafia do logu **w całości** (`console.error(… JSON.stringify(record))`, l. 262), czyli z PESEL-em i odpowiedziami zdrowotnymi z `form_data`. W portalu do logów nie wolno pisać treści wniosku (W7).
- **Wiersz zapisany w `ud_clients` automatycznie uruchamia e-mail z marką UtrataDochodu.pl i SMS do doradcy.** Jeżeli portal BeautyPolisa ma zapisywać wnioski przez `form-submit` (W1 wariant A), klient dostanie list UD, chyba że zleceniodawca zmieni wyzwalacz (np. warunek na `source`).

### 9.4 Zgody, klauzula informacyjna, wycofanie

| Zgoda / potwierdzenie | Treść (dosłownie) | Wersja | Gdzie zapisywana | Wymagana |
|---|---|---|---|---|
| Kontakt w sprawie wniosku (krok 1) | „Zgadzam się na kontakt e-mailowy i telefoniczny ze strony Aura Expert sp. z o.o. w sprawie mojego wniosku — także wtedy, gdy go nie dokończę. Zgodę mogę wycofać w każdej chwili.” + dopisek „Zgoda jest dobrowolna — wniosek możesz złożyć bez niej.” | `v1-2026-10`; treść zaakceptowana przez prawnika bez zmian 01.10.2026 (`ud/packages/wniosek/src/schemat.js:228-249`) | **tylko w szkicu**: `zgoda_wersja`, `zgoda_tresc` (z mapy serwera `ZGODY`, `wniosek-szkic/index.ts:51-55`), `zgoda_at`. Do `form-submit` nie idzie (`doWysylki` usuwa `zgodaKontakt`, `schemat.js:461-466`) | nie |
| Wyłączenia (krok 5) | „Zapoznałem/am się z głównymi wyłączeniami odpowiedzialności.” (link `/wylaczenia/`) | brak | kolumna bool `exclusions_accepted` (bez treści, wersji i czasu poza `created_at`) | tak, ale tylko w kreatorze (`schemat.js:391-398`); serwer nie egzekwuje (§9.1) |
| Klauzula, regulamin, polityka (krok 5) | „Zapoznałem/am się z klauzulą informacyjną, regulaminem i polityką prywatności.” | brak | kolumna bool `informed_accepted` | j.w. |
| **Dane o zdrowiu (art. 9 ust. 2 lit. a RODO)** | **brak checkboxa w kreatorze** (`ud/apps/portal/src/components/Wniosek.svelte:740-764`) | — | — | — |
| Marketing | brak pola | — | — | — |

**Sprzeczność do rozstrzygnięcia przez prawnika (wzmacnia U5).** Opublikowana klauzula informacyjna (`ud/apps/portal/src/pages/klauzula-informacyjna/index.astro`, „zaktualizowano 2026-10-01”, według projektu zaakceptowana przez prawnika razem z polityką prywatności, `ud/CLAUDE.md:1245-1248`) twierdzi dosłownie:
- l. 63–68 – „**Dane o stanie zdrowia z ankiety medycznej** — Art. 9 ust. 2 lit. a RODO — Twoja wyraźna zgoda, zaznaczana w ostatnim kroku wniosku. Zgodę możesz cofnąć w każdej chwili; cofnięcie nie wpływa na zgodność z prawem przetwarzania, które nastąpiło wcześniej.” **W ostatnim kroku takiej zgody nie ma.** Są tylko dwa potwierdzenia „zapoznałem/am się”, więc nie ma też czego wycofać.
- l. 76–81 – „**Kontakt marketingowy** — Art. 6 ust. 1 lit. f RODO albo Twoja zgoda — wyłącznie wtedy, gdy zaznaczysz odpowiednie pole. […]” Takiego pola nie ma, a `form-submit` może synchronizować adres z GetResponse bez zgody (§9.1).
- l. 104–108 – lista kategorii danych z `KROKI[].opis` obejmuje „wysokość dochodu” oraz „okres wypłaty świadczenia”, których formularz nie zbiera (§1). Krok „zdrowie” jest tam opisany jako „przetwarzane wyłącznie za wyraźną zgodą”.
- Tę samą zgodę zakładają jeszcze trzy miejsca w repozytorium, więc to nie jest pojedynczy błąd w tekście klauzuli, tylko niewdrożony element projektu:
  - polityka prywatności, `ud/apps/portal/src/pages/polityka-prywatnosci/index.astro:56` – „Dane dotyczące zdrowia — art. 9 ust. 2 lit. a RODO (wyraźna zgoda udzielona przed złożeniem wniosku).”;
  - komentarz funkcji szkicu, `ud/supabase/functions/wniosek-szkic/index.ts:15-19` – „zgoda z art. 9 RODO pada dopiero w ostatnim kroku”;
  - plan projektu, `ud/PLAN-NIEDOKONCZONE-WNIOSKI.md:199-200` – „Ankieta medyczna to dane szczególnej kategorii; zgoda na ich przetwarzanie pada na końcu — dlatego szkic nigdy ich nie zawiera.”
- Polityka prywatności opiera „Marketing własny” na art. 6 ust. 1 lit. f RODO „albo zgodzie” (`polityka-prywatnosci/index.astro:52`). To jedyna podstawa, na którą dałoby się powołać przy synchronizacji z GetResponse. E-mail marketingowy wymaga jednak uprzedniej zgody (art. 398 Prawa komunikacji elektronicznej), co sam projekt przyjmuje dla przypomnień (`ud/PLAN-NIEDOKONCZONE-WNIOSKI.md:188-191`). Do oceny prawnika.
- Niespójność wewnątrz polityki prywatności: cel „Statystyka kroków wniosku, bez danych osobowych (numer kroku i data)” (`polityka-prywatnosci/index.astro:54`) wobec kategorii „Dane techniczne”, która sama podaje: „Przy zakładaniu szkicu wniosku przechowujemy przez dobę wyłącznie skrót adresu IP, żeby ograniczyć nadużycia.” (l. 45). Skrót IP może być daną osobową, więc sformułowanie z l. 54 trzeba uściślić. Cel „Statystyka porzuconych wniosków” w klauzuli (l. 93–101) opisuje skrót IP przez dobę i jest z kodem spójny.
- Pozostałe cele (nazwy dosłownie, l. 51–101), wszystkie zgodne z kodem:
  - „Przygotowanie oferty i obsługa wniosku” (art. 6 ust. 1 lit. b);
  - „Przekazanie wniosku ubezpieczycielowi” (art. 6 ust. 1 lit. b);
  - „Obowiązki agenta ubezpieczeniowego” (art. 6 ust. 1 lit. c);
  - „Kontakt w sprawie niedokończonego wniosku” (art. 6 ust. 1 lit. a);
  - „Statystyka porzuconych wniosków” (art. 6 ust. 1 lit. f, „Przez dobę przechowujemy skrót adresu IP…”).
- Administrator to Aura Expert sp. z o.o. (dane z `ud/apps/portal/src/lib/firma.ts:5-29`).
- Odbiorcy (l. 121–127) – „Ubezpieczycielom, w imieniu których działamy: Leadenhall Insurance S.A. oraz CEU sp. z o.o.”, „Dostawcom usług informatycznych utrzymującym bazę danych i pocztę.”, „Podmiotom świadczącym nam obsługę prawną i księgową.”, „Organom uprawnionym na podstawie przepisów prawa.”. **Informacja o przekazaniu danych Leadenhall i CEU jest więc w klauzuli**, ale nie w samym formularzu.
- Retencja (l. 133–143) obejmuje m.in. szkic: kontakt „najdłużej 30 dni od ostatniej aktywności”.

**Regulamin** (`ud/apps/portal/src/pages/regulamin/index.astro`, „Regulamin świadczenia usług drogą elektroniczną”, „zaktualizowano 2026-08-27”, l. 15). Potwierdzenie `informedAccepted` z kroku 5 deklaruje zapoznanie się z nim. O wniosku mówi tylko tyle:
- § 1 ust. 2 (l. 27–30): „Strona umożliwia zapoznanie się z ofertą ubezpieczeń utraty dochodu oraz przesłanie wniosku o przygotowanie indywidualnej oferty.”;
- § 2 (l. 39–55): „Kalkulator składki dostępny na stronie ma charakter wyłącznie poglądowy i edukacyjny. Wyniki symulacji nie stanowią oferty w rozumieniu przepisów Kodeksu cywilnego.”, „Ostateczna wysokość składki ubezpieczeniowej zależy od indywidualnej oceny ryzyka (underwritingu) dokonywanej przez towarzystwo ubezpieczeniowe na podstawie pełnego wniosku.”, „Złożenie wniosku przez formularz nie jest równoznaczne z zawarciem umowy ubezpieczenia ani ze złożeniem oferty jej zawarcia przez ubezpieczyciela.”;
- reszta to wymagania techniczne, wyłączenie odpowiedzialności, reklamacje (14 dni, adres reklamacyjny Aura Expert w l. 72–82, poza dokumentem) i zmiany regulaminu. Regulamin nie zawiera zgód, danych osobowych ani terminów obsługi wniosku.

Polityka cookies (`…/polityka-cookies/index.astro`, „zaktualizowano 2026-08-27”, l. 34) powtarza zasady banera z §3.8 i odsyła do polityki prywatności. Szczegółowo jej nie analizowano: portal ma własny baner i własną politykę. **Wniosek dla portalu:** treść regulaminu UD przenosi się tylko jako wzór trzech zdań z § 2. Portal potrzebuje własnego regulaminu (usługa drogą elektroniczną dla wszystkich formularzy portalu), a potwierdzenie w kroku 5 ma linkować do niego, nie do `/regulamin/` UD.

**Szybki kontakt (`contact-submit`, tabela `udochodu_contacts`) – drugi kanał leadów UD obok wniosku.**
- Funkcja `ud/supabase/functions/contact-submit/index.ts`: Turnstile serwerowo (bez sekretu – 503 i wpis w `ud_errors`, l. 74–81), pola `name`, `email`, `phone` przycięte i sprawdzone (l. 83–96), zapis `{name, email, phone, rodo_consent}` (l. 103–107). `rodo_consent` zapisuje się jako `body.rodo_consent === true`, ale serwer go nie wymaga. CORS `*` (l. 16–19). Brak deduplikacji i limitu, jak w `form-submit`.
- Ten sam webhook INSERT uruchamia `send-confirmation-email` z drugim szablonem (`isQuick`, `send-confirmation-email/index.ts:104-162, 257-258`) i SMS „UtrataDochodu: nowy kontakt. …” do doradcy (l. 294–297). Kontakty trafiają też do raportu co 2 h (`send-digest-email/index.ts:136-140`).
- Kto z niej korzysta: szybki formularz starego serwisu statycznego (`ud/app.js:171-197`, `ud/index.html:486`; tabela formularzy w `ud/CLAUDE.md:283-287`). W portalu Astro komponent `SzybkiKontakt.svelte` (pole wymagane w przeglądarce: „Zgadzam się na kontakt telefoniczny i e-mailowy w sprawie oferty ubezpieczenia. Zapoznałem się z klauzulą informacyjną RODO.”, link do `/klauzula-informacyjna/`, l. 122–127) jest użyty tylko na `/pracuj-z-nami/` i wysyła do funkcji Pages `/wspolpraca` (e-mail na skrzynkę serwisu, bez zapisu do tabeli; `pracuj-z-nami/index.astro:21, 135`; `apps/portal/functions/wspolpraca.js:1-9`). Strona `/kontakt/` portalu UD ma tylko telefon i e-mail, bez formularza.
- `udochodu_contacts` nie zasila tablicy leadów (§9.6: lead to wiersz `ud_clients`).
- **Propozycja:** szybkiego kontaktu UD nie przenosimy jako osobnego formularza. Portal ma jeden własny formularz „oddzwonimy” dla wszystkich produktów, a to, czy kontakt w sprawie UD trafia do `udochodu_contacts` (z e-mailem marki UD) czy do CRM portalu, rozstrzyga się razem z W1 (dokąd idą leady) i W4 (e-maile po zgłoszeniu).

**Wycofanie zgody:**
- *kontakt w sprawie wniosku* – link z e-maila (`/wycofaj-zgode/`, §3.7, §9.2), one-click w kliencie poczty albo e-mail lub telefon (klauzula l. 89–90). Treść strony `/wycofaj-zgode/` w repozytorium jest zgodna z §3.7 (`ud/apps/portal/src/pages/wycofaj-zgode/index.astro`).
- *dane o zdrowiu* – brak mechanizmu, bo zgoda nie jest zbierana.
- *cookies* – przycisk w `UDCookies.otworz`.

**Cookies (`ud/apps/portal/public/zgody.js`):**
- `TRYB = 'basic'`, `KLUCZ = 'ud_zgody'`, `WERSJA = 2` (l. 24–26);
- teksty banera dosłownie jak w §3.8 (l. 190–215);
- ścieżki bez Pixela: `/wniosek/`, `/podziekowanie/`, `/wycofaj-zgode/` (`ud/apps/portal/src/lib/analityka.ts:28`);
- konwersja tylko przy zgodzie, ze znacznikiem `ud:wniosek` i `transaction_id` (`ud/CLAUDE.md:576-625`).

Wszystko potwierdza §6.

### 9.5 Dokumenty: OWU i karty produktu

**Źródło listy:** `ud/apps/portal/src/dane/dokumenty.json` (`"pobrano": "2026-09-24"`, `"zrodlo": "ud_owu_library (active = true)"`), 14 pozycji.
- Pliki leżą w **prywatnym** kubełku Supabase Storage `ud-owu`.
- Publicznie wychodzą pod stałym adresem na domenie serwisu, `https://utratadochodu.pl/owu/<slug>.pdf`. Funkcja Pages `ud/apps/portal/functions/owu/[plik].js` strumieniuje je kluczem serwisowym (bez przekierowania).
- Lista dla klienta jest na stronie `https://utratadochodu.pl/dokumenty/`. Przycisk „Pobierz OWU” na `/podziekowanie/` prowadzi właśnie tam (`ud/apps/portal/src/pages/podziekowanie/index.astro:72-73`).

| Ubezpieczyciel | Rodzaj | Tytuł | Symbol (wersja) | Plik w kubełku | Adres publiczny |
|---|---|---|---|---|---|
| Leadenhall | OWU | Leadenhall Utrata Dochodu | `LW044/AD_D_TTD_PTD/PL/5` | `LW_044_AD_D_TTD_PTD_PL_5.pdf` | `/owu/leadenhall-utrata-dochodu.pdf` |
| Leadenhall | karta produktu (IPID) | Karta produktu — Leadenhall Utrata Dochodu | `LW044/AD_D_TTD_PTD/PL/5` | `Karta_Produktu_LW_044_AD_D_TTD_PTD_PL_5.pdf` | `/owu/karta-produktu-leadenhall-utrata-dochodu.pdf` |
| Leadenhall | OWU | Leadenhall MEDICA | `LW046/MEDICA/PL/4` | `LW_046_MEDICA_PL_4.pdf` | `/owu/leadenhall-medica.pdf` |
| Leadenhall | IPID | Karta produktu — Leadenhall MEDICA | `LW046/MEDICA/PL/4` | `Karta_produktu_LH_Medica_LW_046_v4.pdf` | `/owu/karta-produktu-leadenhall-medica.pdf` |
| Leadenhall | OWU | Leadenhall MEDICARE | `LW047/MEDICARE/PL/4` | `LW_047_MEDICARE_PL_4.pdf` | `/owu/leadenhall-medicare.pdf` |
| Leadenhall | IPID | Karta produktu — Leadenhall MEDICARE | `LW047/MEDICARE/PL/4` | `Karta_produktu_LH_Medicare_LW_047_v4.pdf` | `/owu/karta-produktu-leadenhall-medicare.pdf` |
| Leadenhall | warunki szczególne | Leadenhall MEDICA — warunki szczególne HIV/WZW | `LW048/NS_MEDICA/PL/2` | `LW_048_NS_MEDICA_PL_2.pdf` | `/owu/leadenhall-medica-warunki-szczegolne-hiv-wzw.pdf` |
| Leadenhall | warunki szczególne | Leadenhall MEDICARE — warunki szczególne HIV/WZW | `LW049/NS_MEDICARE/PL/2` | `LW_049_NS_MEDICARE_PL_2.pdf` | `/owu/leadenhall-medicare-warunki-szczegolne-hiv-wzw.pdf` |
| CEU | OWU | CEU Utrata Dochodu | `OWU Utrata Dochodu 2026 _v_9_8` | `OWU Utrata Dochodu 2026 _v_9_8.pdf` | `/owu/ceu-utrata-dochodu.pdf` |
| CEU | IPID | Karta produktu — CEU Utrata Dochodu | `Karta Produktu - Utrata Dochodu 2026 _v_9_8 CEU` | `Karta Produktu Utrata dochodu 2026.pdf` | `/owu/karta-produktu-ceu-utrata-dochodu.pdf` |
| CEU | OWU | CEU Utrata Dochodu dla zatrudniających | `OWU Utrata Dochodu dla zatrudniających 2026 _v_2_6` | `OWU Utrata dochodu dla zatrudniających 2026_v_2_6.pdf` | `/owu/ceu-utrata-dochodu-dla-zatrudniajacych.pdf` |
| CEU | IPID | Karta produktu — CEU Utrata Dochodu dla zatrudniających | `Karta Produktu - Utrata Dochodu dla zatrudniających 2026 _v_2_6` | `Karta Produktu Utrata dochodu dla zatrudniajacych 2026.pdf` | `/owu/karta-produktu-ceu-utrata-dochodu-dla-zatrudniajacych.pdf` |
| CEU | OWU | CEU LOI Premium | `OWU LOI PREMIUM 2026 _v_1_2` | `OWU LOI PREMIUM 2026_v_1_2.pdf` | `/owu/ceu-loi-premium.pdf` |
| CEU | IPID | Karta produktu — CEU LOI Premium | `Karta Produktu - OWU LOI PREMIUM 2026 _v_1_2 CEU` | `Karta Produktu LOI PREMIUM 2026.pdf` | `/owu/karta-produktu-ceu-loi-premium.pdf` |

Adresy policzono algorytmem `slugDokumentu` z `ud/apps/portal/src/lib/owu.ts:30-45`: małe litery, polskie znaki na łacińskie, każdy ciąg znaków spoza `[a-z0-9]` zamieniony na `-`. Same pliki PDF **nie są w repozytorium**. Trzeba je pobrać spod tych adresów albo dostać od zleceniodawcy.

**Logika „zawsze obowiązujące”:**
- **Slug pochodzi z tytułu, nie z symbolu.** Symbol niesie numer wersji (`…/PL/5`), więc adres przeżywa podmianę wersji i zawsze podaje warunki obowiązujące (`owu.ts:14-22`; `ud/CLAUDE.md:699-723`).
- **Dwie aktywne wersje tego samego tytułu wywalają build** (`ud/apps/portal/src/pages/owu-adresy.json.ts:18-29`, wyjątek w l. 21–28). To celowa kontrola przed wdrożeniem.
- **Aktywność sprawdzana na żywo.** Funkcja `/owu/[plik].js` czyta mapę slug → id z builda (`/owu-adresy.json`), a potem odpytuje `ud_owu_library` z filtrem `active=is.true`. Wycofany dokument daje 404 od razu, bez czekania na nowy build (l. 57–77). Bufor `public, max-age=300, s-maxage=600` (l. 30), nagłówek `Content-Disposition: inline` (l. 87–93).
- **Stary adres** `/pobierz/<id>` odpowiada **301** na `/owu/<slug>.pdf` (`ud/apps/portal/functions/pobierz/[id].js:21-40`).
- **Oferty w panelu trzymają wskaźnik na konkretny plik.**
  - W chwili wystawienia oferty `storage_path` trafia do `ud_offer_files`, więc oferta historyczna zachowuje swoją wersję OWU.
  - Wersje wycofuje się przełącznikiem `active`, nigdy usuwaniem (`ud/CLAUDE.md:1484-1525`).
  - Dopasowanie po bazie symbolu (`LW044`) z filtrem `bezInnychWersji` chroni przed doklejeniem klientowi nowszej wersji. Pilnuje tego `ud/apps/panel/scripts/test-owu.mjs:28-82`: wersja 4 → bez wersji 5; karta produktu o tym samym symbolu wolno dołożyć; rider `LW048` dochodzi do `LW046`.
  - OWU i karta produktu tej samej wersji mają w bibliotece **identyczny symbol** (np. oba `LW044/AD_D_TTD_PTD/PL/5`).

**Wniosek dla portalu:** linkować dokumenty po stałych adresach `/owu/<slug>.pdf` (albo hostować kopie z wersją w nazwie). Przy wniosku zapisywać, która wersja obowiązywała (symbol), bo adres zawsze wskazuje wersję bieżącą.

### 9.6 Od wniosku do leada w panelu (kontekst integracji z CRM)

**Skąd biorą się leady:**
- **Lead to klient z `ud_clients`** (złożony wniosek albo klient dodany w panelu). Szkice nie są leadami: ograniczenie `lead_tylko_klient` (`szkic_id is null`) blokuje to w bazie (`ud/supabase/migrations/20261002120000_leady_kanban_3_sprzedaz.sql:38-39`; `ud/CLAUDE.md:1163-1172, 1593-1600`).
- Na `ud_clients` nie ma wyzwalacza od tablicy (`ud/CLAUDE.md:1893-1900`). Leady powstają w `ud_leady_synchronizuj()` przy otwarciu tablicy (`ud/supabase/migrations/20261004200000_leady_kanban_5_prowizja_polisy.sql:431`).
- Etap startowy wynika z najlepszej oferty klienta: `bought` → Wygrany, `chosen` → Decyzja klienta, `sent`/`viewed` → Oferta, `rejected` → Przegrany, oferta robocza albo jej brak → Nowy.

**Etapy i statusy:**
- Pipeline „Sprzedaż”: **Nowy → Oferta → Decyzja klienta → Wygrany / Przegrany**. Etapy zakłada `ud/supabase/migrations/20261001151739_leady_kanban_1_tabele.sql:62-74`. Etap „Kontakt” jest wyłączony od 02.10.2026 (`aktywny = false`, `ud/supabase/migrations/20261002120000_leady_kanban_3_sprzedaz.sql:56`).
- Wygrany wymaga składki rocznej, Przegrany – powodu utraty.
- Statusy oferty: `draft → sent → viewed → chosen → bought / rejected` (`ud/CLAUDE.md:1458-1482`).

**Zmiany stanu i widoczność:**
- Jedna ścieżka zmiany stanu: `ud_lead_zmien()` (wersjonowanie, klucz idempotencji, historia w `ud_leady_historia`).
- Agent widzi tylko leady, których jest opiekunem. Opiekuna przydziela administrator albo kod z linku agenta (§9.1).
- `ud_leady` nie ma kolumn z danymi osobowymi; RLS bez polityk, dostęp tylko `service_role` (`ud/CLAUDE.md:1876-1891`).

**Prowizja:**
- Prowizja to składka roczna × stawka sprzedawcy (`ud_user_profiles.prowizja_procent`, % składki rocznej). Konto „Centrala” ma 20%.
- Stawka zapisuje się migawką w `ud_leady.prowizja_procent` przy sprzedaży.
- Opłata dystrybucyjna ubezpieczyciela **nie jest** prowizją i nie wchodzi do składki (`ud/CLAUDE.md:1685-1716`; migracja `…_kanban_5_…sql:31-49`).

**Pozostałe zakładki panelu:** „Polisy” (numer, okres ochrony), „Statystyki”, „Niedokończone” (szkice ze zgodą).

**Czego `ud` nie robi:** nie zapisuje wniosków do tabel CRM `crm_clients`. Te zasila tylko synchronizacja firm z projektu BEAUTY (`ud/supabase/functions/sync-beauty-companies/index.ts`), działająca w tym samym projekcie Supabase. „CRM” dla wniosków UD to panel `apps/panel` (Kanban leadów) na tabelach `ud_*`.

### 9.7 Co z tego wynika dla decyzji W1 (czy wnioski UD z portalu mają trafiać do CRM)

Fakty z kodu, bez rozstrzygania decyzji. Jeżeli portal wyśle wniosek UD do istniejącego `form-submit` (wariant A):
- **Plusy:**
  - lead od razu trafia do panelu agentów UD (tablica, oferty z PDF ubezpieczyciela, SMS-y, statystyki, prowizje);
  - przypisanie do agenta działa przez `affiliateCode`;
  - pole `source` można ustawić na wartość portalu, bo funkcja nie ogranicza wartości;
  - ankieta i 7 pozycji bez kolumn zapisują się w `form_data.health_survey`.
- **Do zmiany po stronie zleceniodawcy:**
  - Turnstile: wspólny widżet z domeną portalu albo drugi sekret (§9.1);
  - wyzwalacz e-maila z marką UD (§9.3) i ewentualnie synchronizacja GetResponse (§9.1);
  - serwerowe egzekwowanie potwierdzeń i zgody art. 9 (§9.4);
  - limit żądań i deduplikacja;
  - CORS ograniczony do domen albo wywołanie serwer–serwer z sekretem.
- **Szkic i przypomnienia** (`wniosek-szkic`) są związane z domeną `utratadochodu.pl`: link do wniosku i link wycofania w e-mailu oraz nadawca. Dla portalu wymagają parametryzacji albo własnej implementacji (W3, W4).

---

## 10. Zamknięcie braków po analizie repozytorium `ud`

Stan na 13.11.2026, źródło `aurabroker/ud` @ `793a158`. „Zamknięty” znaczy, że brak wiedzy o kodzie został usunięty. Nie znaczy, że formularz można uruchomić w portalu: o tym nadal decydują W1–W4.

| # | Brak (z `00-braki-i-decyzje.md`) | Status | Dowód / co zostaje |
|---|---|---|---|
| U1 | Kod `form-submit`: Turnstile, walidacje, mapowanie, deduplikacja, `affiliateCode` | **zamknięty** | §9.1: mechanizm `siteverify` bez `hostname`/`action` (`form-submit/index.ts:135-178`), walidacje (l. 181–342), pełne mapowanie na `ud_clients` (l. 190–277), `form_data.health_survey`, brak deduplikacji i limitu, `affiliate_code_used` → opiekun (`…_kanban_5_…sql:494-505`), kody odpowiedzi, CORS `*`, brak JWT. **Zostaje:** pełne DDL `ud_clients` nie jest w repozytorium (tylko atrapa `supabase/tests/stub.sql:39-58`); trzeba potwierdzić, czy GetResponse jest aktywny na produkcji; dla integracji nowe ustalenia: widżet Turnstile, `source`, wyzwalacz e-maila |
| U2 | `wniosek-szkic`: kod, schemat, sól `ip_hash`, algorytm i klucz `sig`, retencja | **zamknięty** (klucz celowo poza dokumentem) | §9.2: akcje i odpowiedzi (`wniosek-szkic/index.ts:115-310`), schemat `ud_wnioski_szkice` (migracja `20261001101112`, l. 22–62), `ip_hash` = HMAC-SHA256(`SZKIC_HMAC_SECRET`, `ip:<IP>`) obcięty do 32 hex, bez osobnej soli (`szkic-podpis.ts:36-40`), `sig` = HMAC-SHA256(`SZKIC_HMAC_SECRET`, `wycofaj:<id>`), 64 hex, bez wygasania (l. 24–34), retencja 1 dzień dla IP i 30 dni dla szkiców (l. 156–194). Portal musi mieć własny sekret albo wspólny, uzgodniony ze zleceniodawcą |
| U3 | Przypomnienia: harmonogram, warunki, szablon, nadawca | **zamknięty** | §9.2: cron `10 * * * *`, włączony od 01.10.2026, 3 h po aktywności, szkice do 7 dni, 1 mail na adres na 30 dni, do 50 na uruchomienie (`migracja:215-291`; `wniosek-przypomnienie/index.ts:36-38`), treść dosłownie (l. 72–140), nadawca `UtrataDochodu <info@utratadochodu.pl>`, nagłówki RFC 8058. **SMS do szkiców nie ma**, jest ręczna lista „Niedokończone” w panelu |
| U4 | E-maile po złożeniu wniosku (klient, agent) | **zamknięty** (treść i mechanizm); definicja wyzwalacza poza repozytorium | §9.3: wyzwalacz `send-confirmation-email-full` (INSERT `ud_clients`) → `send-confirmation-email` (szablon dosłownie, `index.ts:163-239`), SMS do doradcy (l. 292–297), raport co 2 h na skrzynkę biura (`send-digest-email`). Opiekun nie dostaje e-maila. Wyzwalacz istnieje tylko w panelu Supabase (`ud/CLAUDE.md:409-412, 1719-1724`). Zapis do `ud_clients` z portalu wyśle list z marką UD (W4) |
| U5 | Klauzula informacyjna, zgoda art. 9, informacja o przekazaniu danych Leadenhall/CEU | **częściowo – i pilniejszy niż sądziliśmy** | Klauzula informacyjna jest w repozytorium (`apps/portal/src/pages/klauzula-informacyjna/index.astro`, zaktualizowana 01.10.2026, według projektu zaakceptowana przez prawnika). Odbiorców (Leadenhall, CEU) wymienia (l. 121–127). **Zgody art. 9 nadal nie ma w formularzu, a klauzula twierdzi, że jest „zaznaczana w ostatnim kroku wniosku” (l. 63–68)**; podobnie „Kontakt marketingowy … gdy zaznaczysz odpowiednie pole” (l. 76–81). Potwierdzenia z kroku 5 nie są egzekwowane na serwerze. Tę samą nieistniejącą zgodę zakłada polityka prywatności (`apps/portal/src/pages/polityka-prywatnosci/index.astro:56`: „wyraźna zgoda udzielona przed złożeniem wniosku”), komentarz `wniosek-szkic/index.ts:15-19` i `PLAN-NIEDOKONCZONE-WNIOSKI.md:199-200`, więc to niewdrożony element projektu, a nie pomyłka w jednym tekście. Regulamin (`apps/portal/src/pages/regulamin/index.astro`) o wniosku mówi tylko, że strona umożliwia jego przesłanie, kalkulator jest poglądowy, a złożenie wniosku nie jest zawarciem umowy (§ 1 ust. 2, § 2; §9.4); zgód i danych osobowych nie dotyczy. Polityki cookies nie analizowano szczegółowo (portal ma własną). Wewnątrz polityki prywatności jest niespójność: statystyka „bez danych osobowych” (l. 54) wobec skrótu IP przez dobę (l. 45). Szybki kontakt (`contact-submit` → `udochodu_contacts`) opisany w §9.4; propozycja: nie przenosić jako osobnego formularza, kierunek leadów w W1/W4. Dla portalu nadal potrzebne własne teksty z prawidłowym administratorem i wyraźną zgodą art. 9 |
| U6 | Oryginalne pytania ankiety z okresami referencyjnymi / akceptacja underwritera | **otwarty** | Repozytorium ma te same skrócone pytania (`packages/wniosek/src/schemat.js:43-51`, `ankieta.js:14-48`). Okres pojawia się tylko w jednym pytaniu („w ciągu ostatniego roku”, `ankieta.js:18`). Komentarz w `form-submit/index.ts:236` („medical events last 2 years”) sugeruje dwuletni okres zdarzeń medycznych, ale treść pytań go nie podaje |
| U7 | Symulacja po wniosku; odświeżanie `kalibracja.json` | **częściowo** | Proces: liczby w `apps/portal/src/lib/kalibracja.json` liczone maszynowo z wystawionych ofert (dół/góra = najtańsza/najdroższa obserwowana stawka, środek = mediana), metoda w `apps/portal/MODEL-SKLADKI.md`, planowany worker `ud-kalibrator`; mnożnik HIV/WZW 1,07 w `symulacja.ts` (`ud/CLAUDE.md:872-922`). W repozytorium kalibracja z 17.09.2026 (góra 0,0244), na żywej stronie z 14.10.2026 (góra 0,0322), czyli odświeżanie działa poza repozytorium. **Decyzja o symulacji po wniosku – otwarta** |
| U8 | Pola dochodu i okresu wypłaty | **otwarty** (decyzja) | Repozytorium potwierdza rozjazd. `KROKI[].opis` wymienia „wysokość dochodu” i „okres wypłaty świadczenia” (`schemat.js:202-213`), a ten tekst trafia do klauzuli informacyjnej (§9.4). `form-submit` nie ma kolumn na te pola |
| U9 | `/kup-online` – adres docelowy, link afiliacyjny | **otwarty** | Repozytorium (12.10.2026) nie ma `/kup-online` ani boxu „Zakup online” (brak w `apps/portal/src`, `functions`, `public/_redirects`). Funkcja doszła na produkcji później. Potrzebny nowszy kod albo informacja od zleceniodawcy. [przegląd repo 13.11] `udapp` (20.10.2026) też nie ma `/kup-online`. To panel ofert po wniosku, a zakup i płatność są poza nim (§11.4). Wybór wariantu nie jest zakupem i nie zapisuje akceptacji wyłączeń (§11.5) |
| U10 | Analityka: tagi portalu czy UD, etykiety konwersji | **częściowo** | Mechanizm potwierdzony: `zgody.js` (basic, WERSJA 2), `analityka.ts:28` (ścieżki bez Pixela), konwersja `SUBMIT_LEAD_FORM` ze znacznikiem i `transaction_id` (`ud/CLAUDE.md:576-625`); identyfikatory w `analityka.ts` (poza dokumentem). Decyzja, czyje tagi w portalu – otwarta. [przegląd repo 13.11] `udapp` nie ma tagów. Otwarcie oferty i wybór wariantu zapisuje tylko jako statusy w `ud_offers` (§11.4). Powiązanie oferty z `ud_clients` jest opcjonalne (§11.5) |

**Nowe ustalenia, które warto dopisać do `00-braki-i-decyzje.md`** (ten plik edytują inne workflow, więc tu tylko lista):
- (a) sprzeczność klauzuli z formularzem w sprawie zgody art. 9 i zgody marketingowej;
- (b) synchronizacja GetResponse bez zgody w `form-submit`;
- (c) potwierdzenia z kroku 5 nieegzekwowane na serwerze;
- (d) automatyczny e-mail z marką UD dla każdego wiersza `ud_clients`;
- (e) PESEL jawnym tekstem w `ud_clients` mimo zadeklarowanego `PESEL_ENCRYPTION_KEY`;
- (f) Turnstile bez sprawdzania `hostname`, sekret związany z widżetem UD;
- (g) brak deduplikacji i limitu w `form-submit`;
- (h) imię bez escapowania w szablonie potwierdzenia;
- (i) pełny rekord wniosku (PESEL, ankieta) w logu `send-confirmation-email`, gdy brak e-maila;
- (j) przydział opiekuna: kod nieaktywnego agenta zostawia lead bez opiekuna, a nieznany kod przechodzi do autora oferty (ważne, jeśli portal przekazuje `affiliateCode`). `ud/CLAUDE.md:1678-1679` zakłada, że nieznany kod też daje lead bez opiekuna; kod robi inaczej (`…_kanban_5_…sql:494-505`) – do potwierdzenia u zleceniodawcy, które zachowanie jest zamierzone;
- (k) szybki kontakt UD (`contact-submit`, `udochodu_contacts`, drugi szablon e-maila i SMS do doradcy) – osobny kanał leadów poza tablicą; decyzja, czy i dokąd portal go przenosi, w W1/W4 (§9.4).

### Poprawki naniesione w tym pliku 13.11.2026

- §1: `G[].opis` to nie martwy kod. Zasila listę kategorii danych w klauzuli informacyjnej.
- §5: usunięto fragment identyfikatora projektu Supabase (zasada: identyfikatory infrastruktury poza dokumentem).
- §5.2: odpowiedź akcji `wycofaj` to HTTP 2xx z `{status:"success"}`, a nie `ok`; algorytm `sig` potwierdzony.
- §7, §8: dopisano stan po analizie repozytorium.
- §9.1: poprawiono opis przydziału opiekuna. Nieznany kod przechodzi do autora oferty, a bez opiekuna zostaje tylko kod (albo `referred_by`) konta nieaktywnego.
- §9.2: poprawiono numery linii `wniosek-szkic/index.ts` (były przesunięte o 40 względem klonu `793a158`): 405 → l. 115–119, `sprawdzKontakt` → l. 86–95, `ZGODY` → l. 51–55, akcje → l. 169–303.
- §9.3: nagłówek e-maila potwierdzającego przepisany dosłownie („Aura Expert Sp. z o.o.”; wersaliki to tylko CSS). Dopisano uwagę o logach funkcji (pełny rekord w `console.error`).
- §9.4: odwołanie do akceptacji prawnika poprawione na `ud/CLAUDE.md:1245-1248`. Dopisano trzy dalsze miejsca, które zakładają istnienie zgody art. 9 (polityka prywatności, komentarz `wniosek-szkic`, plan), oraz rozjazdy polityki prywatności z klauzulą.
- §9.6: źródło wyłączenia etapu „Kontakt” to `…_kanban_3_sprzedaz.sql:56`, nie migracja 1.
- Druga runda (13.11.2026):
  - §9.5: odwołanie do kontroli kolizji slugów poprawione na `owu-adresy.json.ts:18-29` (plik ma 36 linii).
  - §9.1: doprecyzowano kolejność nazw pól w `form-submit` (`med_*` najpierw snake_case; część pól ma jedną nazwę). Dopisano rozjazd `ud/CLAUDE.md:1678-1679` z kodem przydziału opiekuna.
  - §9.4: niespójność statystyki opisana jako wewnętrzna w polityce prywatności (l. 45 wobec l. 54); klauzula (l. 93–101) jest spójna. Dopisano regulamin i szybki kontakt (`contact-submit`).
  - §7: stan punktów 5–11 zgodny z §10 (7 i 11 częściowo).

---

## 11. Panel ofert po wniosku – repozytorium `udapp` [przegląd repo 13.11]

Źródło: płytki klon `aurabroker/udapp` (jeden commit `36ae901`, 20.10.2026), czytany, nieuruchamiany. SvelteKit na Cloudflare Pages. Baza i pliki są w projekcie Supabase „aurabroker” (tabele `ud_*`), SMS-y idą przez SMSAPI, e-maile przez Resend (`udapp/app/README.md:1-11`, `udapp/app/DEPLOY.md:1-43`). Adres projektu i klucze z `DEPLOY.md` celowo pominięte. Ścieżki w tabelach są względne do `udapp/app/`.

**To nie jest formularz.** `udapp` zaczyna się tam, gdzie wniosek się kończy. Agent wgrywa PDF-y ofert Leadenhall i CEU, aplikacja czyta z nich warianty, a klient dostaje link do porównania. Formularz, który ma trafić do portalu, opisują §1–§10. Ta sama aplikacja, w innej wersji, jest w monorepo jako `ud/apps/panel` (§11.2).

### 11.1 Przepływ oferty

| Etap | Co się dzieje | Dowód |
|---|---|---|
| Utworzenie | `ud_offers` z `share_token` (24 znaki z `crypto.getRandomValues`) i `access_code`; warianty w `ud_offer_documents`, pliki w `ud_offer_files` | `src/lib/server/offers.js:79-101`; `src/lib/server/crypto.js:8-15` |
| Kod dostępu | hasło PDF ubezpieczyciela, jeśli ma co najmniej 4 cyfry, inaczej losowy 4-cyfrowy PIN. Przy wysyłce hash PBKDF2-SHA256 (100 000 iteracji) trafia do `ud_offer_pins` z `expires_at` = teraz + `PIN_TTL_HOURS` (domyślnie 48 h) | `offers.js:83-85, 527-542`; `crypto.js:17-40`; `DEPLOY.md:43` |
| Wysyłka | e-mail z linkiem `/offer/[token]` (temat „Twoja oferta ubezpieczenia utraty dochodu — nr …”) i SMS z hasłem **oraz linkiem**. Każda próba trafia do `ud_send_log`. Status `sent` tylko wtedy, gdy cokolwiek wyszło | `offers.js:544-599` |
| Bramka | bez weryfikacji strona dostaje tylko token, imię i nazwisko klienta oraz nazwę oferty. `POST …/unlock` przyjmuje 4 cyfry, sprawdza wygaśnięcie i licznik `attempts`/`max_attempts`, potem ustawia ciasteczko httpOnly podpisane HMAC na ścieżce oferty | `src/routes/offer/[token]/+page.server.js:7-27`; `…/unlock/+server.js:6-66`; `src/lib/server/clientAuth.js:17-34` |
| Podgląd | po weryfikacji status `sent` → `viewed` (`viewed_at`); warianty, pliki, warunki oferty, link do „Informacji o dystrybutorze” | `+page.server.js:29-58` |
| Decyzja | `POST …/choice`: wybór wariantu (`chosen`) albo rezygnacja (`rejected`), obie z potwierdzeniem; zapis `client_choice` i `decided_at`, e-mail do agenta. Klient widzi: „Dziękujemy! Twój wybór został zapisany. Agent skontaktuje się z Tobą.” | `…/choice/+server.js:20-62`; `src/lib/components/OfferView.svelte:158, 169, 193-204` |
| Pytania | „Masz pytanie?”: 3–2000 znaków → `ud_offer_questions` i e-mail do agenta z `Reply-To` klienta (pola escapowane) | `…/question/+server.js:7-47`; `src/lib/server/templates.js:65-88` |
| OWU | aktywne pozycje `ud_owu_library` danego ubezpieczyciela, dopasowanie po symbolu: baza LW044/LW046/LW047, warunki HIV/WZW (LW048/LW049) tylko przy LW046/LW047; CEU – jedno dopasowanie | `offers.js:163-190`; `src/lib/server/owuMatch.js:47-80`; `DEPLOY.md:64-67` |
| Dystrybutor | `GET /dystrybutor` strumieniuje PDF z kubełka `ud-public` według `ud_settings.distributor_pdf_path` (`inline`, `no-store`); bez ustawienia 404 | `src/routes/dystrybutor/+server.js:5-24`; `src/lib/server/settings.js:6-17` |
| Stopka | „Aura Expert spółka z ograniczoną odpowiedzialnością … XII Wydział Gospodarczy Krajowego Rejestru Sądowego … pod numerem 11229690/A” w warunkach oferty, w PDF i w e-mailu | `src/lib/server/offerConditions.js:83`; `src/lib/server/pdf/conditionsDoc.js:75-79`; `templates.js:4, 19` |

Zakupu ani płatności w `udapp` nie ma: w `app/src` nie występuje status `bought` ani obsługa płatności. Status `bought` i etap „Wygrany” prowadzi `ud` (§9.6). E-mail do klienta zaczyna się neutralnym „Dzień dobry,” i ma wersję tekstową (`templates.js:16-18, 45-56`).

### 11.2 `udapp` a `ud/apps/panel` – dwie wersje panelu

Bramka `unlock`, ciasteczko i `/dystrybutor` są w obu repozytoriach identyczne (porównanie plików). Różnią się kodem dostępu i SMS-em. **Która wersja działa na produkcji – do potwierdzenia u zleceniodawcy.** `udapp` ma nowszy commit, a `ud` nowszy model kodu dostępu.

| | `udapp` (`36ae901`, 20.10.2026) | `ud/apps/panel` (`793a158`, 12.10.2026) |
|---|---|---|
| Kod dostępu | hasło PDF albo losowy PIN (`offers.js:83-85`) | 4 ostatnie cyfry PESEL z `ud_clients` (według komentarza to też hasło PDF); bez PESEL-u wysyłka jest blokowana (`ud/apps/panel/src/lib/server/offers.js:570-592`) |
| SMS | hasło i link (`offers.js:567`) | samo zawiadomienie, bez linku i kodu – decyzja z 12.10.2026 (`ud/apps/panel/src/lib/server/smsOferta.js:1-24`) |
| Zapowiedź w e-mailu | „4-cyfrowym hasłem, które wysłaliśmy osobno SMS-em” (`templates.js:39`) | „Hasłem dostępu są 4 ostatnie cyfry Pani/Pana numeru PESEL” (`ud/apps/panel/src/lib/server/templates.js:39`) |
| Wersja oferty | brak | numer wersji przy każdej kolejnej wysyłce (`ud/apps/panel/src/lib/server/offers.js:597`) |
| Wersje OWU | dopasowanie przez zawieranie się symbolu, bez strażnika wersji (`owuMatch.js:33-40`) | strażnik `bezInnychWersji` (`ud/apps/panel/src/lib/server/owuMatch.js:84`; §9.5) |

### 11.3 Uwagi bezpieczeństwa (dla wzorca w portalu)

- **TTL nie zamyka dostępu.** Gdy PIN wygaśnie, a oferta ma 4-cyfrowy `access_code`, `unlock` zakłada nowy PIN na 30 dni z nowym licznikiem prób (`…/unlock/+server.js:28-41`). E-mail obiecuje ważność `PIN_TTL_HOURS`. Domyślne `max_attempts` jest w schemacie tabeli, którego nie ma w repozytorium – do potwierdzenia.
- **Kod jawnym tekstem.** `access_code` leży w `ud_offers` obok hasha w `ud_offer_pins` (`offers.js:101, 536-542`), więc hash niczego nie chroni.
- **„Osobny kanał” tylko w treści e-maila.** W `udapp` SMS niesie hasło i link (`offers.js:567`), więc sam SMS otwiera ofertę.
- **Dane przed weryfikacją.** Bramka zwraca pełne `client_name`, choć pokazuje tylko imię (`+page.server.js:20-26`; `src/routes/offer/[token]/+page.svelte:41`).
- **Sekret ciasteczka** ma wartości zapasowe: klucz `service_role` albo stały napis deweloperski (`clientAuth.js:9-11`). Podpis nie zawiera czasu ważności, pilnuje go tylko `maxAge` (`clientAuth.js:18-26`).
- **Kod z PESEL (`ud`)** to fragment danej osobowej, którą znają też osoby bliskie, i najwyżej 10 000 kombinacji. Jedyną ochroną jest limit prób.

### 11.4 Wpływ na braki i portal

- **U9 – bez zmian (otwarty).** `udapp` nie zawiera `/kup-online` ani linku afiliacyjnego. Przeszukałem wszystkie klony w `aurabroker/` – zero trafień. `udapp` opisuje drugą ścieżkę: wniosek → oferta agenta → porównanie → wybór → kontakt agenta. Niewiadomą pozostaje tylko box „Zakup online”. Strona portalu po wysłaniu wniosku UD może już zapowiedzieć e-mail z linkiem do porównania. Sposób odblokowania zależy od wersji panelu (§11.2).
  - [przegląd repo 13.11] **Wybór wariantu to nie zakup.** `choice` zapisuje tylko `client_choice`, bez śladu akceptacji wyłączeń, a decyzję można nadpisać (§11.5). Komunikat po wyborze zapowiada tylko kontakt agenta (`OfferView.svelte:158`). Umowa, polisa i płatność są poza `udapp` (status `bought` prowadzi `ud`, §9.6); kto i jak je realizuje – do potwierdzenia. Portal może więc opisać ścieżkę po wniosku do etapu „wybór → kontakt agenta”, ale nie powinien obiecywać zakupu online po ofercie. Dla U9 zostają dwie odrębne ścieżki: zakup online u Leadenhall (`/kup-online`, cel nieznany) i oferta po wniosku w panelu UD.
- **U10 – częściowo, decyzja bez zmian.** W `udapp/app/src` nie ma tagów: wyszukanie `gtag`, `googletagmanager` i `fbq` nie daje trafień poza osadzonymi danymi fontów. Otwarcie oferty, wybór i rezygnacja istnieją tylko jako status i znaczniki czasu w `ud_offers` (`viewed_at`, `decided_at`, `client_choice`). Jeśli portal ma mierzyć coś więcej niż wysłanie wniosku, to tylko po stronie serwera, np. webhookiem HUB `utm-attribution` (`00-braki-i-decyzje.md`, część G).
  - [przegląd repo 13.11] Konwersję „wybór oferty” da się powiązać z wnioskiem z portalu tylko wtedy, gdy agent połączy ofertę z klientem w `ud_clients`. Pole `client_id` jest opcjonalne. Decyzja może się zmieniać, więc liczy się ostatni `decided_at` (§11.5).
- **W4.** Klient, którego wniosek z portalu trafi do `ud_clients` (wariant A), dostanie ofertę z marką UtrataDochodu (`templates.js:22-24`; `+page.svelte:28-31`). Nadawcą będzie domyślny adres z domeny UD, jeśli nie ustawiono `RESEND_FROM` (`src/lib/server/email.js:8, 20`). Strona podziękowania w portalu musi to zapowiadać.
- **D38 (XII Wydział):** stopka `udapp` potwierdza „XII”.
- **Wzorce do przejęcia** (oferty i linki `/w/`):
  - token z CSPRNG o wysokiej entropii;
  - kod jako drugi czynnik: z limitem prób i twardym TTL (bez cichego odnawiania), przechowywany tylko jako hash, niebędący fragmentem PESEL;
  - SMS bez linku (jak w `ud`);
  - log wysyłek z numerem wersji oferty (jak w `ud`);
  - „Informacja o dystrybutorze” serwowana z własnej domeny (`/dystrybutor`);
  - OWU dopasowywane po symbolu ze strażnikiem wersji (jak w `ud`);
  - neutralne „Dzień dobry,” i wersja tekstowa e-maila;
  - [przegląd repo 13.11] jeden format kodu w generatorze, SMS-ie i bramce;
  - [przegląd repo 13.11] akceptacja warunków i wyłączeń zapisywana na serwerze (treść z wersją, czas, wariant), a decyzja jednorazowa albo z historią zmian;
  - [przegląd repo 13.11] „Informacja o dystrybutorze” z wersją w adresie albo w nazwie pliku i z hashem w kopercie wniosku.
- **Ochrona formularza (W2):** wzorzec `ac/functions/api/kontakt.js` opisują `ergo-zycie-w-biznesie.md` §13.2 i `tax-protect-wniosek.md` §13.2.

### 11.5 Weryfikacja w klonie i uzupełnienia [przegląd repo 13.11]

Odnośniki z §11.1–§11.4 sprawdziłem w klonach `udapp` @ `36ae901` i `ud` @ `793a158`. Są zgodne z kodem. Przy sprawdzaniu doszły szczegóły ważne dla U9 i dla wzorca w portalu. Ścieżki są względne do `udapp/app/`.

| Ustalenie | Skutek | Dowód |
|---|---|---|
| **Kod dłuższy niż 4 cyfry.** Hasło PDF z co najmniej 4 cyframi zostaje kodem dostępu (`^\d{4,}$`) i idzie SMS-em. Bramka, odnowienie PIN-u i pole przyjmują jednak dokładnie 4 cyfry | klient z hasłem PDF dłuższym niż 4 cyfry nie otworzy oferty. Czy hasła PDF Leadenhall mają zawsze 4 cyfry – do potwierdzenia | `src/lib/server/offers.js:85, 527-542, 567`; `src/routes/offer/[token]/unlock/+server.js:8, 31`; `src/routes/offer/[token]/+page.svelte:47-48` |
| **Akceptacja wyłączeń tylko w przeglądarce.** Pole „Zapoznałem/am się z wyłączeniami i akceptuję warunki.” tylko odblokowuje przycisk. Do serwera idzie wyłącznie `{action, documentId}`, a `client_choice` nie zapisuje akceptacji | nie ma dowodu, że klient poznał wyłączenia przed wyborem | `src/lib/components/OfferView.svelte:68, 80, 197, 203`; `src/routes/offer/[token]/choice/+server.js:7-9, 33-39` |
| **Decyzję można zmieniać.** Każdy `POST …/choice` nadpisuje `client_choice`, `status` i `decided_at` i wysyła agentowi kolejny e-mail. Treść e-maila nie jest escapowana, ale pochodzi z panelu i PDF, nie od klienta | w statystyce liczy się ostatnia decyzja | `choice/+server.js:45-61` |
| **Powiązanie oferty z wnioskiem jest opcjonalne.** `client_id` ustawia agent przy tworzeniu oferty | bez niego wyboru nie da się połączyć z `ud_clients` ani z kampanią (U10) | `src/lib/server/offers.js:72, 95`; `src/routes/panel/new/+page.server.js:32, 42-46` |
| **Stopka e-maila** pochodzi z `ud_settings.pdf_footer`. Gdy pole jest puste, używana jest stała stopka spółki z „XII Wydział Gospodarczy” | treść stopki zależy od bazy, nie tylko od kodu | `src/lib/server/templates.js:4, 19`; `src/lib/server/settings.js:6-17`; `src/lib/server/pdf/conditionsDoc.js:75-79` |
| **`/dystrybutor` bez wersji.** Adres nie zawiera wersji ani daty. Nazwa pliku pochodzi z `ud_settings.distributor_pdf_name`, odpowiedź ma `no-store` | nie da się ustalić, którą wersję klient pobrał | `src/routes/dystrybutor/+server.js:10-23` |
| **Ręczne dodanie klienta** w panelu zapisuje `ud_clients` z `source: 'manual'` i `referred_by`. Serwer pilnuje, że okresowa niezdolność jest ryzykiem podstawowym, i wymaga ankiety rozszerzonej (`hs_*`, `hsd_*`) przy sumie trwałej niezdolności powyżej 1 000 000 zł | te same reguły co w kreatorze (§2, §4.1); potwierdza `ud_clients` jako tabelę docelową U1 | `src/routes/panel/klienci/nowy/+page.server.js:45, 52-72`; `src/lib/healthSurvey.js:8` |

Statusy U9 (otwarty) i U10 (częściowo) się nie zmieniają.

---

## Weryfikacja krytyka kompletności (2026-11-13)

Sprawdzone w kodzie i **potwierdzone**: walidacje kroku 1 (`Y`: `/^[^\s@]+@[^\s@]+\.[a-z]{2,}$/i`, `fe`: `/^(?:\+?48)?\d{9}$/` po usunięciu `[\s()-]`); PESEL (`K`: wagi 9,7,3,1…, Σ mod 10) i komunikat wieku 18–65; limity 50 000 / 10 000 000 / 10 000 000 i progi `3e5`, `1e6`; kwoty 5 klauzul NW (`ue`); stan początkowy (`employmentType: b2b`, `emp_contribution_slider: 50`, ankieta podstawowa `no`); `ge()` z polem `nwPermanentDamage` i mapowaniem `hs_*`/`hsd_*`; `he()` i `affiliateCode`; wysyłka z `cf-turnstile-response`, `sessionStorage['ud:wniosek']`, `ukoncz` z `keepalive`, przekierowanie `/podziekowanie/`; szkic z timeoutem 3 s; wersja zgody `v1-2026-10`; teksty „Pięć kroków…” i „w ciągu 24 godzin roboczych”.

**Uzupełnione:** przepuszczanie nieistniejących dat w PESEL (§2) oraz skutek uboczny akcji `kontakt` bez tokenu (§5.2). Dodatkowo: bez `kluczTurnstile` w props widżet kroku 5 się nie renderuje, a submit zawsze kończy się komunikatem „Potwierdź, że nie jesteś robotem.” – w portalu sitekey jest warunkiem działania formularza.

Pominięć w polach, krokach, zgodach i taryfach nie znaleziono.
