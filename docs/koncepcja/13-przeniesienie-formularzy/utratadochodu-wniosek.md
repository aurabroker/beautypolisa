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

**Stała `G[].opis`** (l. 286–308) opisuje dane z każdego kroku. Komponent jej nie wyświetla (to martwy kod albo pozostałość po rejestrze RODO). Uwaga na rozbieżności: opis kroku `dane` mówi o „wysokości dochodu”, a opis `zakres` o „okresie wypłaty świadczenia”. **Formularz nie ma ani pola dochodu, ani pola okresu wypłaty.**

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

Na dole: „Masz pytania? Zadzwoń pod 504 400 901 albo napisz na biuro@utratadochodu.com .” i linki „Przeczytaj wyłączenia” oraz „Pobierz OWU”.

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

Adresy pochodzą z `props` wyspy (`wniosek.html`). Projekt Supabase ma ref zaczynający się od `kukvgsjr…` (pełny adres jest w props, tu go nie powtarzam). Funkcje:
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
| `wycofaj` | strona `/wycofaj-zgode/#id=<id>&sig=<podpis>` (link z e-maila; hash czyszczony przez `history.replaceState`) | `{akcja:"wycofaj", id, sig}` | `ok` → „Zgoda wycofana.”, inaczej błąd |

Wnioski:
- Szkic powstaje także **bez zgody**, jako anonimowy rekord lejka: `ostatni_krok`, `ukonczony_at`.
- Dane kontaktowe trafiają tam tylko przy zgodzie.
- Klient nie wysyła `zgoda_tresc`. Serwer musi mapować wersję `v1-2026-10` na treść (kolumna `zgoda_tresc`).
- `client_id`, `ip_hash`, `zgoda_at` i `przypomnienie_wyslane_at` ustala serwer.
- `sig` w linku wycofania podpisuje serwer (np. HMAC id).

**Przypomnienia:** w kodzie klienckim nie ma żadnej logiki przypomnień. Z kodu wynika tylko tyle, że istnieje e-mail z linkiem `/wycofaj-zgode/#id=…&sig=…` dotyczący „niedokończonego wniosku” (tekst strony wycofania). Harmonogram, treść i warunki wysyłki są po stronie serwera (§7).

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

  W żadnym z analizowanych plików **nie ma** anon key Supabase, bo funkcje są wywoływane bez JWT. Brak JWT oznacza, że jedyną ochroną endpointów jest Turnstile i walidacja serwerowa. Do weryfikacji, czy obie funkcje ją faktycznie robią.
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

## Weryfikacja krytyka kompletności (2026-11-13)

Sprawdzone w kodzie i **potwierdzone**: walidacje kroku 1 (`Y`: `/^[^\s@]+@[^\s@]+\.[a-z]{2,}$/i`, `fe`: `/^(?:\+?48)?\d{9}$/` po usunięciu `[\s()-]`); PESEL (`K`: wagi 9,7,3,1…, Σ mod 10) i komunikat wieku 18–65; limity 50 000 / 10 000 000 / 10 000 000 i progi `3e5`, `1e6`; kwoty 5 klauzul NW (`ue`); stan początkowy (`employmentType: b2b`, `emp_contribution_slider: 50`, ankieta podstawowa `no`); `ge()` z polem `nwPermanentDamage` i mapowaniem `hs_*`/`hsd_*`; `he()` i `affiliateCode`; wysyłka z `cf-turnstile-response`, `sessionStorage['ud:wniosek']`, `ukoncz` z `keepalive`, przekierowanie `/podziekowanie/`; szkic z timeoutem 3 s; wersja zgody `v1-2026-10`; teksty „Pięć kroków…” i „w ciągu 24 godzin roboczych”.

**Uzupełnione:** przepuszczanie nieistniejących dat w PESEL (§2) oraz skutek uboczny akcji `kontakt` bez tokenu (§5.2). Dodatkowo: bez `kluczTurnstile` w props widżet kroku 5 się nie renderuje, a submit zawsze kończy się komunikatem „Potwierdź, że nie jesteś robotem.” – w portalu sitekey jest warunkiem działania formularza.

Pominięć w polach, krokach, zgodach i taryfach nie znaleziono.
