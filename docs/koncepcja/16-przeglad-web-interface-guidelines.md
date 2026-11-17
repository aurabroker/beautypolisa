# 16 · Przegląd makiet v3 według Vercel Web Interface Guidelines

| | |
|---|---|
| Wersja | 1.0 |
| Data | 16 listopada 2026 |
| Źródło reguł | Vercel Web Interface Guidelines: plik `command.md` z repozytorium `vercel-labs/web-interface-guidelines`, pobrany 15.11.2026. To jedyne źródło reguł przeglądu. Nazwy reguł i działów podaję w oryginale |
| Zakres | 12 stron w `docs/koncepcja/design/v3/`: `makieta-v3.html`, `oc-beauty.html`, `slownik.html`, `tax-protect.html`, `utrata-dochodu.html`, `nnw-dzieci.html`, `grupowe-ergo.html`, `opieka-medyczna.html`, `strefa/logowanie.html`, `strefa/panel.html`, `strefa/dam-prace.html`, `strefa/szkolenia.html`. Do tego `strefa/strefa.css` i generatory w `narzedzia/makiety/`: `gen_wspolne.py`, `slownik/gen_terminy.py`, `slownik/gen_strona.py`, `gen_kalkulator_dane.py`, `gen_oc_beauty.py`, `gen_klauzula.py`, `oc_taryfa.py`, `gen_strefa_zabiegi.py`, `opieka-medyczna/`. Poza zakresem: `design-preview.html` |
| Stan kodu | Commit `f071d1a` (16.11.2026). Od commitu `e07585f` trwają prace nad przełącznikami „Zakładki” w Ustawieniach salonu, więc w `strefa.css`, `panel.html`, `dam-prace.html` i `szkolenia.html` numery linii są przesunięte (np. `strefa.css` od l. 157 o +50). Linie z tego raportu odczytasz przez `git show f071d1a:<plik>`. Strony publiczne i generatory się nie zmieniły |
| Metoda | Pięć grup: wspólne bloki i generatory (oceniane raz, na `tax-protect.html`), strona główna, OC i słownik, 5 stron produktów, Strefa. Grupę najpierw przeglądał jeden agent, potem drugi niezależnie weryfikował każdą uwagę. Weryfikacja powtarzała pomiar, poprawiała linie, zakres i wagę albo uwagę odrzucała. Narzędzia: odczyt kodu, grep, skrypty typograficzne w Pythonie i Playwright z Chromium headless (`http.server` lub `file://`, `deviceScaleFactor` 1, okna 320–1920 px). W przeglądarce sprawdzono: Tab i Shift+Tab, `reducedMotion`, hover, zoom 200 i 400%, domyślną czcionkę 20 i 24 px (CDP `Page.setFontSizes`), drzewo dostępności (CDP), dławienie sieci, długie dane od użytkownika i powrót „wstecz” |
| Liczby | Przegląd zgłosił **142** uwagi. Weryfikacja odrzuciła w całości **9**, zmieniła **11** wag (9 obniżonych, 2 podwyższone) i dodała **6** nowych uwag oraz 3 uzupełnienia istniejących. Po weryfikacji zostało **139** uwag. Przy scalaniu: duplikaty między grupami ujęto raz (17 wzorców wspólnych w rozdz. 3.2), uwagi o treści kilku stron rozpisano na pliki, dodano **2** uwagi, które przepadły między grupami (klauzula, taryfa – sprawdzone skryptem), i ujednolicono **2** wagi w opiece: wyszukiwarka średnia → niska (jak w OC i słowniku), stan wysyłania niska → średnia (jak na stronie głównej). Zawężono 2 uwagi: przejścia kolorów `.seg-opt` nie są błędem animacji, a h2 w oc-beauty.html:1348 to proza (rozdz. 4). Rozdz. 3 ma **140** pozycji: 139 produkcyjnych i 1 o adnotacjach makiety |
| Powiązane | `15` (tasteskill: ta sama karta końcowa słownika), `07` (WCAG 2.2 AA), `10` (design v3), `11` (Strefa Klienta) |
| Status | Przegląd tylko do odczytu. **Wdrożenie 17.11.2026:** wszystkie uwagi z rozdz. 3.1 (generatory; wspólny moduł `narzedzia/makiety/typografia.py`), rozdz. 3.2 (wzorce wspólne – blok `gen:wspolne-css`, `<head>` stron, `strefa.css`) i uwagi do `strefa.css` z rozdz. 3.3, poza: fonty z `tnum` i preload krojów (produkcja – `next/font/local`), `translate="no"` w treści stron (zrobione w menu, stopce i logo). Opis: `narzedzia/makiety/README.md`. **Strony publiczne (17.11.2026):** wszystkie uwagi z rozdz. 3.3 dla `makieta-v3.html` (w tym wysoka: przeliczenie kalkulatorów i formularza na `pageshow`), `oc-beauty.html`, `tax-protect.html`, `utrata-dochodu.html`, `nnw-dzieci.html`, `grupowe-ergo.html`, poza `content-visibility` list zabiegów OC (szacowana wysokość psuła przewijanie do kotwic aliasów przy 360 px – `t_func.js`). FAQ utraty dochodu (weryfikacja, runda 1, 17.11.2026): lista pytań przeniesiona do repozytorium jako `narzedzia/makiety/utrata-dochodu/gen_faq.py` – widoczny blok `GEN:faq` z polską typografią (`typografia.html()`), `FAQPage` w `GEN:jsonld` bez twardych spacji, „Kwot tu nie ma, bo…” i „jeśli ich nie zgłosisz albo ubezpieczyciel ich nie przyjmie” (uwagi :1225–1226 wdrożone). **Strefa Klienta (17.11.2026):** wszystkie uwagi z rozdz. 3.3 dla `strefa/logowanie.html`, `panel.html`, `dam-prace.html` i `szkolenia.html` – wspólne wzorce w nowym `strefa/strefa.js` (błędy przy polach z ogłoszeniem, `aria-disabled`, potwierdzenia akcji nieodwracalnych, „Cofnij”, ostrzeżenie przed utratą danych, formaty `Intl`), kontrola `narzedzia/makiety/kontrola/strefa/potwierdzenia.js`. Rozdz. 3.4 (adnotacje makiety w regionach live opieki) – `aria-hidden`. Integracja 17.11.2026: generatory, `--check` i pełny zestaw kontroli bez błędów (`narzedzia/makiety/README.md`) |

## 1. Adaptacja reguł do projektu

- **Język polski.**
  - „Title Case” nie dotyczy, bo polska norma to wielka litera tylko na początku. Zgłaszam za to wielkie litery w środku fraz.
  - Zamiast “ ” obowiązują „ ”, wewnątrz ‚ ’. Wielokropek to „…”.
  - Twarde spacje stawiamy według polskiej typografii: po jednoliterowych spójnikach i przyimkach, między liczbą a jednostką („5 osób”, „100 zł”), w „nr 5”, w grupach cyfr i w datach.
  - „Second person” oznacza formę „Ty/Twój”, jak w reszcie portalu. Pierwsza osoba („pokażemy”, „nie znaleźliśmy”) to uwaga. Wyjątki to zgody, formuły RODO i oświadczenia użytkownika („Jestem pracodawcą”).
  - „Numerals for counts” dotyczy komunikatów UI, etykiet i miejsc obok liczników z cyframi. Słowne liczebniki do dziesięciu w nagłówkach i prozie to polska norma redakcyjna i nie są uwagą.
  - „Intl.NumberFormat” oznacza kwoty w polskim formacie. `pl-PL` domyślnie nie grupuje liczb czterocyfrowych, więc trzeba podać `useGrouping:'always'`.
- **Statyczny HTML/CSS/JS, bez Reacta.**
  - `focus-visible:ring-*` to `:focus-visible` z `outline`, `hover:` to `:hover`, a `min-w-0` to `min-width:0`.
  - Hydration Safety oceniam w odpowiedniku: czy UI liczony skryptem zgadza się ze stanem pól, który przywraca przeglądarka.
  - `useState` i nuqs oceniam jako „URL reflects state”, a `virtua` jako `content-visibility`.
- **Makiety.** Adnotacje `.mock-note` i `.mock-bar` nie są produkcyjne. Uwagi o nich są osobno (rozdz. 3.4).

## 2. Podsumowanie

**Liczby uwag według działu reguł i wagi** (139 uwag produkcyjnych; uwaga o adnotacji makiety jest poza tabelą):

| Dział reguł | wysoka | średnia | niska | razem |
|---|---:|---:|---:|---:|
| Accessibility | 1 | 3 | 5 | 9 |
| Focus States | 1 | 2 | 1 | 4 |
| Forms | 1 | 5 | 16 | 22 |
| Animation | – | – | 3 | 3 |
| Typography | – | – | 25 | 25 |
| Content Handling | – | 2 | 7 | 9 |
| Images | – | 1 | – | 1 |
| Performance | – | – | 6 | 6 |
| Navigation & State | 1 | 4 | 2 | 7 |
| Touch & Interaction | – | – | 6 | 6 |
| Safe Areas & Layout | – | 2 | – | 2 |
| Dark Mode & Theming | – | – | 1 | 1 |
| Locale & i18n | – | – | 5 | 5 |
| Hydration Safety | 1 | – | – | 1 |
| Hover & Interactive States | – | – | 9 | 9 |
| Content & Copy | – | 1 | 28 | 29 |
| **Razem** | **5** | **20** | **114** | **139** |

**Najważniejsze problemy:**

1. **Karta końcowa słownika jest nieczytelna i nie widać na niej fokusu** (wysoka). W `gen_strona.py:622` brakuje klasy `dark`. Obwódka fokusu i nagłówek mają wtedy kolor tła. Poprawka to jedno słowo. Tę samą kartę zgłasza dokument 15.
2. **Kalkulatory na stronie głównej po powrocie „wstecz” pokazują wynik niezgodny z zaznaczeniem** (wysoka). Tax pokazuje 1 532 zł zamiast 2 701 zł, a CTA wysłałoby nieaktualną kwotę. OC przy zaznaczonych polach każe „zaznaczyć rodzaj działalności”. Brakuje przeliczenia na `pageshow`.
3. **Strefa nie chroni przed nieodwracalnymi skutkami jednego kliknięcia** (wysoka). „Usuń konto”, „Usuń ogłoszenie”, „Zwróć 390,00 zł”, „Zrezygnuj” i „Odbierz dostęp” działają od razu, bez potwierdzenia i bez cofnięcia.
4. **Logowanie: licznik ponownej wysyłki kodu jest ogłaszany co sekundę** (wysoka). Region `aria-live` ogłasza go przez minutę, a koniec odliczania nie jest ogłoszony.
5. **Szkolenia: na iOS nie da się wpisać kodu pocztowego** (wysoka). Pole ma `inputmode="numeric"`, więc klawiatura nie ma „-”, a walidacja wymaga formatu 00-000. Zamówienie płatnego szkolenia jest zablokowane.
6. **Strefa: błędy i zmiany stanu nie dochodzą do czytnika ekranu** (średnia). `setErr` nie ogłasza błędu przy zatwierdzeniu Enterem. Część błędów nie stoi przy polu. „Pobieranie…” kasuje nazwy linków PDF. Wyłączony przycisk zrzuca fokus na `<body>`. Link ze słownika do `panel.html#p-szkody` otwiera złą zakładkę.
7. **Wszystkie strony mają `viewport-fit=cover` bez `env(safe-area-inset-*)`** (średnia). W poziomie na iPhonie treść, nagłówek i szuflady wchodzą pod wycięcie ekranu.
8. **Generatory nie mają wspólnej typografii** (niska, ale największy zasięg). Twardych spacji brakuje w dymkach słownika, klauzuli, taryfie, listach zabiegów, ankiecie, FAQ i menu. Jeden wspólny moduł usunie ok. 10 pozycji z generatorów naraz i ułatwi poprawki ręczne.

**Istotne dla przełączników zakładek w Ustawieniach salonu (Szkolenia, Praca – preferencja widoku, nie przełączniki modułów; 00, D44):**

- Stary `.switch` w `strefa.css:145–149` nie ma `:hover`, a jego gałka przeskakuje bez animacji (rozdz. 3.3, `strefa.css`). Nowy `input.toggle` z commitu `e07585f` był poza zakresem przeglądu. Animuje już `transform`, ale w chwili pisania też nie ma `:hover`. *Uzupełnienie 16.11.2026 (weryfikacja D44, runda 1): przełączniki zakładek używają `input.toggle` (natywny checkbox z `role="switch"`), nie `.switch`; `:hover` dodany w `(hover:hover) and (pointer:fine)`; wzorzec opisany w `DESIGN.md` (4.10).*
- Obwódka fokusu w jasnym menu konta (`strefa.css:72`) ma kontrast 1,6:1. To droga klawiaturą do „Ustawień”.
- Ukrycie zakładki da się cofnąć, więc nie wymaga potwierdzenia z reguły „Destructive actions” (inaczej niż usunięcie konta z punktu 3).

## 3. Uwagi

Format: `plik:linia - problem → poprawka`. Poprawka jest podana tylko wtedy, gdy nie jest oczywista. Na końcu pozycji stoi `[dział reguły · waga]`. Pierwsza ścieżka jest pełna (względem repozytorium). Dalsze ścieżki w tej samej pozycji są skrócone do nazwy pliku w `docs/koncepcja/design/v3/`. „→ plik:linia” oznacza miejsce w stronie wygenerowanej. Wzorców wspólnych z rozdz. 3.2 nie powtarzam przy stronach.

### 3.1 Generatory (`narzedzia/makiety/`)

#### narzedzia/makiety/gen_wspolne.py (menu, szuflada, pasek akcji – wszystkie strony publiczne)

- narzedzia/makiety/gen_wspolne.py:171, :237 - Przełączenie belka/szuflada działa na sztywnym progu 1200 px (`@media`, `matchMedia`), a etykiety menu są w rem z `nowrap`. Przy domyślnej czcionce 20–24 px „Zapytaj doradcę” wychodzi poza belkę albo okno: 1280@20 sięga 1279 px przy krawędzi belki 1220, 1920@24 sięga 1788 przy 1540. Nagłówek jest fixed, więc ucięta część jest nieosiągalna. Ten sam próg jest w CSS stron: tax-protect.html:188, :175, `--bp-container` w :66 oraz kopie makieta-v3.html:408, oc-beauty.html:195, utrata-dochodu.html:201, nnw-dzieci.html:191, grupowe-ergo.html:199, slownik.html:187, opieka-medyczna/common.css:164 → wszystko razem: `--bp-container:77.5rem`, progi `(max-width:74.99em)` i `matchMedia('(min-width:75em)')`. Alternatywa: container query na `.header-bar`, a w JS `getComputedStyle(.menu).display`. Po zmianie sprawdzić 1200–1920 px przy 20 i 24 px [Safe Areas & Layout · średnia]
- narzedzia/makiety/gen_wspolne.py:154, :146 (→ tax-protect.html:687, :679) - Dwa elementy nie zmieniają się po najechaniu. „Wszystkie ubezpieczenia”, bo `.main-nav .mega .mega-all` przebija specyficznością `.main-nav a:hover`. Przycisk „Ubezpieczenia” z `data-biezacy` na stronach produktów, bo ma już styl hover w spoczynku → `:hover{text-decoration-thickness:2px}` dla obu [Hover & Interactive States · niska]
- narzedzia/makiety/gen_wspolne.py:25, :37, :39, :44 (→ tax-protect.html:801–806) - W `PRODUKTY` są zwykłe spacje w „100 osób”, „zł / mies.”, „ERGO Razem” i „ERGO Hestia”, a „ENEL-MED” ma łamliwy dywiz → `&nbsp;`, `ENEL&#8209;MED` [Typography · niska]

#### narzedzia/makiety/slownik/gen_terminy.py (dymki słownika – strony publiczne i Strefa)

- narzedzia/makiety/slownik/gen_terminy.py:600 (→ tax-protect.html:1368) - Definicje w JSON `slownik-dymki` nie mają twardych spacji. Na tax-protect to 44 jednoliterowe słowa ze zwykłą spacją i 0 znaków U+00A0 → pola `t` i `d` przepuścić przez reguły z `gen_strona.py:46–48`, ale ze znakiem U+00A0, bo tekst trafia przez `textContent` [Typography · niska]
- narzedzia/makiety/slownik/gen_terminy.py:436 (→ tax-protect.html:1455) - Skrypt nadaje `<a href="slownik.html#haslo-…">` rolę `button`. Czytnik ogłasza przycisk, a element działa jak link i znika z listy linków → zostawić rolę linku z `aria-haspopup="dialog"` i `aria-expanded` albo podmieniać na `<button>` jak „Ubezpieczenia” (`gen_wspolne.py:215–218`). Link do hasła daje wtedy „Więcej w słowniku” [Accessibility · niska]
- narzedzia/makiety/slownik/gen_terminy.py:387, :404, :447–448 - Na szerokich oknach dymek się przewija (JS ustawia `overflow-y:auto` i `max-height`), a `overscroll-behavior:contain` ma tylko wariant wąski → `contain` w regule bazowej `.bp-dymek` [Touch & Interaction · niska]
- narzedzia/makiety/slownik/gen_terminy.py:438–451, :485 (→ tax-protect.html:1457–1470) - `pozycja()` przeplata zapisy stylu z odczytami (`getClientRects`, `offsetWidth/Height`). Po zapisie `maxHeight` drugi raz czyta `offsetHeight` → `y = r1.top - 10 - Math.min(h, maxH)`, wszystkie zapisy po odczytach [Performance · niska]

#### narzedzia/makiety/gen_klauzula.py (ten sam blok: gen_kalkulator_dane.py:196, gen_oc_beauty.py:254)

- narzedzia/makiety/gen_klauzula.py:13–24 - Klauzula ochrony prawnej nie ma twardych spacji. W każdej kopii jest 83 jednoliterowe słowa ze zwykłą spacją i 0 `&nbsp;` (makieta-v3.html:1604–1645, oc-beauty.html:1256–1301, strefa/panel.html:840–881) → `&nbsp;` dodawać przy wypisywaniu HTML, bez zmiany JSON i brzmienia; jedna funkcja dla trzech generatorów. Uwaga dodana przy scalaniu: grupy „główna”, „OC i słownik” oraz „Strefa” odesłały ją do „wspólnych” [Typography · niska]

#### narzedzia/makiety/oc_taryfa.py (tabela taryfy – makieta-v3.html i oc-beauty.html)

- narzedzia/makiety/oc_taryfa.py:158 (→ makieta-v3.html:1517–1519, oc-beauty.html:1317–1330) - Nazwy i opisy kategorii idą przez `e()` bez twardych spacji: „kosmetyczne i fryzjerskie”, „razem z gabinetem”, „(z innymi rodzajami” (5 miejsc). Reszta tabeli ma `&nbsp;` → ta sama obróbka co w `nota_taryfy()`. Uwaga dodana przy scalaniu (odesłana przez grupę „główna”) [Typography · niska]

#### narzedzia/makiety/gen_kalkulator_dane.py (bloki tylko na makieta-v3.html)

- narzedzia/makiety/gen_kalkulator_dane.py:164–170, :59, :173–175 (→ makieta-v3.html:1460–1467, :1477, :1817) - Pozycje ankiety a–h nie mają twardych spacji („z użyciem”, „i wypełniaczy”, „o dużym”), bo `ankieta_block` używa `eh()` bez `sierotki()`. W „12 miesięcy” spacja zostaje, bo `sierotki()` nie obejmuje liczby z rzeczownikiem → `sierotki(eh(...))` i reguła `(\d) (miesięcy|osób|lat|zł)` [Typography · niska]

#### narzedzia/makiety/gen_oc_beauty.py (bloki GEN tylko na oc-beauty.html)

- narzedzia/makiety/gen_oc_beauty.py:154–158, :179–228, :239, :275 (block_jump, block_listy, block_rules, block_faq → oc-beauty.html:991–993, :1008, :1014, :1017–1064, :1220, :1398–1402) - Teksty nie mają twardych spacji. Brakuje ich po jednoliterowych słowach (FAQ 61, zabiegi 42, reguły 4), w „nr N” (FAQ 5, zabiegi 44, skok 2) oraz w „8 pozycji” i „5 osób” → funkcja jak `t()` z `slownik/gen_strona.py:43–48`, rozszerzona o „pozycji/pozycje/osób” oraz „nr” i „poz.”. Poza listą reguł: w pytaniu 5 są dwie pauzy „—” zamiast półpauzy „–” [Typography · niska]

#### narzedzia/makiety/slownik/gen_strona.py (cała slownik.html; szkielet strony kopiowany z tax-protect.html)

- narzedzia/makiety/slownik/gen_strona.py:622 (→ slownik.html:3088) - Karta końcowa ma klasę `end-card` bez `dark` (oc-beauty.html:1446 ma `end-card dark`). Obwódka fokusu „Zapytaj doradcę” i „Zobacz ubezpieczenia” jest granatowa na granatowym gradiencie. h2 „Nie ma pojęcia…” ma kolor tła, a eyebrow jest taupe na granacie. Zgłasza to też dokument 15 → `class="end-card dark"` [Focus States · wysoka]
- narzedzia/makiety/slownik/gen_strona.py:269 (`skrypt_strony()` → slownik.html:3316, :3360) - Fraza i kategoria nie trafiają do adresu, a przy wejściu `?q=&kategoria=` są ignorowane → przy starcie wypełnić pola z `URLSearchParams` i wywołać `filtruj(false)`, po zmianie `history.replaceState` z zachowaniem `location.hash` [Navigation & State · średnia]
- narzedzia/makiety/slownik/gen_strona.py:324, :335, :363 (→ slownik.html:431, :442, :470, :1779) - Fraza bez spacji, od ok. 26 znaków (np. wklejony adres), w „Brak haseł dla „…”” i w `.sl-pusto` rozpycha stronę. `.sl-licznik` ma scrollWidth 1054 w panelu 246 px → `overflow-wrap:anywhere` [Content Handling · niska]
- narzedzia/makiety/slownik/gen_strona.py:583 (→ slownik.html:1744) - Placeholder „np. składka, L4, OWU” nie kończy się „…” [Forms · niska]
- narzedzia/makiety/slownik/gen_strona.py:43–48 (→ slownik.html:1803, :1807, :1816, :1829, :1855, :2162, :2175, :2391, :2603, :2707, :2747, :3044) - `t()` nie obsługuje kilku przypadków. Separator tysięcy to zwykła spacja (ok. 15 kwot, np. „1 000 000 zł” może się złamać w środku). Bez twardych spacji są też „2017 r.” (10 razy), „poz. 17” i „8 pozycji”, a „sp. z o.o.” łamie się po „sp.” → reguły `(\d) (?=\d{3}\b)`, `(\d{4}) r\.`, `poz\. (\d)`, `sp\. z` [Typography · niska]
- narzedzia/makiety/slownik/gen_strona.py:586, :609 (→ slownik.html:1747, :1780; w treści hasła :2096) - Teksty są w pierwszej osobie: „Szukamy w nazwach pojęć…” (2 razy) i „którym przekazujemy dane” → „Wyszukiwarka sprawdza nazwy pojęć i ich odmiany” [Content & Copy · niska]
- docs/koncepcja/snippets/slownik.json (→ slownik.html:1892, :2968) - Etykiety linków mają liczebniki słowne: „zakup online w czterech krokach”, „Grupowe ERGO – trzy warianty” → „w 4 krokach”, „3 warianty” [Content & Copy · niska]
- narzedzia/makiety/slownik/gen_strona.py:336 (→ slownik.html:1783–3078) - Wszystkie 96 haseł renderuje się naraz (ok. 85 tys. px wysokości przy 390 px), bez `content-visibility` → `.sl-litera{content-visibility:auto;contain-intrinsic-size:auto 1500px}`, potem sprawdzić przewijanie do `#haslo-…` i do aliasów [Performance · niska]

#### narzedzia/makiety/gen_strefa_zabiegi.py (bloki tylko na strefa/dam-prace.html)

- narzedzia/makiety/gen_strefa_zabiegi.py:46–52, :80–100, :106–109 (→ dam-prace.html:607–748, :1397–1538, :1747–1888, :2243–2384; chipy `renderTags` :2935–2938) - Nazwy zabiegów i sekcji nie mają twardych spacji po „i/w/z”, po „nr” ani przed „–” („Lista nr 1 – …”) → `&nbsp;` tylko przy wypisywaniu HTML (JSON bez zmian), ta sama funkcja w JS chipów [Typography · niska]
- narzedzia/makiety/gen_strefa_zabiegi.py:80–100 (→ dam-prace.html, 4 bloki po ok. 120 pól) - W DOM jest 480 pól wyboru bez `content-visibility`, a wyszukiwanie otwiera wszystkie grupy naraz → `.zab-grp{content-visibility:auto;contain-intrinsic-size:auto 48px}` albo jeden zestaw pól na stronę [Performance · niska]

#### narzedzia/makiety/opieka-medyczna/ (build.py, template.html, common.css, data.py → cała opieka-medyczna.html)

- narzedzia/makiety/opieka-medyczna/build.py:377 (→ opieka-medyczna.html:1156) - `nbsp()` zużywa poprzedzającą spację w grupie `(^|[\s(„])`, więc z dwóch jednoliterowych słów z rzędu poprawia tylko pierwsze (`i&nbsp;w jednym`) → lookbehind `(?<![^\s(„])([aiouwzAIOUWZ]) +(?=\S)` [Typography · niska]
- narzedzia/makiety/opieka-medyczna/template.html:156, :183, :147, :886 (→ :589, :616, :580, :2120, :2124) - Zapytanie powtórzone w `#spec-count` i `#spec-empty` się nie łamie, a `.spec-panel` nie ma `minmax(0,1fr)`. Przy 390 px strona przewija się w poziomie od ok. 45–60 znaków bez spacji (60 × „x” daje 482 px) → `overflow-wrap:anywhere`, `grid-template-columns:minmax(0,1fr)` [Content Handling · niska]
- narzedzia/makiety/opieka-medyczna/template.html:68 (→ :501) - Znak „✓” z `::before` wchodzi do nazwy pola: czytnik słyszy „✓ ENEL-MED Standard” → `content:"✓" / ""` [Accessibility · niska]
- narzedzia/makiety/opieka-medyczna/template.html:620, :819–820 (→ :1694, :2057–2058) - `#form-pick` (`role=status`) ma `hidden`. Tekst trafia do regionu przed zdjęciem `hidden`, więc pierwsza zmiana zwykle nie jest ogłaszana → region stale w DOM, ukrywany przez `.form-pick:empty{display:none}` [Accessibility · niska]
- narzedzia/makiety/opieka-medyczna/template.html:791 (→ :2029, :2033) - Kwota i „zespół N osób” są składane ręcznie. Po zmianie przełącznika znika `&nbsp;` ze statycznego `216&nbsp;zł`, a kwoty od 1000 nie miałyby separatora grup → `Intl.NumberFormat('pl-PL',{style:'currency',currency:'PLN',maximumFractionDigits:0})`, w podpisie U+00A0 [Locale & i18n · niska]
- narzedzia/makiety/opieka-medyczna/template.html:797, :854, :891 (→ :2035, :2092, :2129) - Do adresu nie trafiają: liczba osób i zakres stawek, pakiety do porównania ani zapytanie o specjalizację. Formularz już czyta `?operator=&zespol=&zakres=` → `replaceState` z `?zespol=&zakres=&porownaj=&q=` i odczyt przy starcie [Navigation & State · niska]
- narzedzia/makiety/opieka-medyczna/template.html:528 (→ :1365) - Placeholder „np. kardiolog, dermatolog, biopsja” nie kończy się „…” [Forms · niska]
- narzedzia/makiety/opieka-medyczna/template.html:626, :638 (→ :1700, :1712) - `#m-nip` i `#m-email` nie mają `spellcheck="false"` [Forms · niska]
- narzedzia/makiety/opieka-medyczna/template.html:685, :989–1002 (→ :1759, :2227–2240) - Makieta pomija stan wysyłania: po walidacji od razu pokazuje podziękowanie. Brakuje „Wysyłanie…”, `aria-busy`, blokady na czas żądania i stanu błędu sieci → na czas `fetch`: `disabled`, „Wysyłanie…”, `aria-busy`. Po błędzie dane zostają, przycisk znowu działa, a komunikat podaje następny krok [Forms · średnia]
- narzedzia/makiety/opieka-medyczna/template.html:995 (→ :1695, :2233) - Po wysłaniu z błędami fokus trafia na zbiorczą listę `#form-errors`, a nie na pierwsze błędne pole. To świadomy wzorzec GOV.UK → fokus na pierwszym polu albo zapisać odstępstwo w dokumentacji [Forms · niska]
- narzedzia/makiety/opieka-medyczna/template.html:616 (→ :1690) - Długi formularz (NIP, kontakt, 3 grupy wyboru, zgody) nie ostrzega przed opuszczeniem strony → `beforeunload` po pierwszej zmianie, zdjęty po wysłaniu [Forms · niska]
- narzedzia/makiety/opieka-medyczna/template.html:894 (→ :2132) - Kliknięcie „Często szukane” wywołuje `input.focus()`. Na telefonie klawiatura zasłania wtedy pokazane wyniki → fokus tylko przy `(pointer:fine)` [Touch & Interaction · niska]
- narzedzia/makiety/opieka-medyczna/template.html:627, :686 (→ :1701, :1760) - Teksty są w pierwszej osobie: „Sprawdzimy NIP… i uzupełnimy”, „Przetwarzamy je” → „System sprawdzi NIP w rejestrze REGON (GUS) i uzupełni nazwę firmy”. Formuła RODO może zostać [Content & Copy · niska]
- narzedzia/makiety/opieka-medyczna/data.py:20–36 (→ :1321, :1333) - Specjalności mają wielką literę w środku listy („Chirurg, Ginekolog, …, Lekarz Rodzinny”, „Chirurg Onkolog”) → małe litery (polska norma zamiast Title Case) [Content & Copy · niska]
- docs/koncepcja/design/v3/opieka-medyczna.html:1713 (źródło: template.html) - W podpowiedzi „Np. 600 000 000” grupy cyfr dzielą zwykłe spacje [Typography · niska]

### 3.2 Wzorce wspólne (bazowy CSS i `<head>` stron, `strefa.css`)

Bazowy CSS i `<head>` stron publicznych są kopiowane ręcznie. Wzorem jest `tax-protect.html`, z którego `gen_strona.py` składa słownik. Opieka ma je w `opieka-medyczna/common.css` i `template.html`. Każdy wzorzec podaję raz, z linią na `tax-protect.html` i listą kopii.

- docs/koncepcja/design/v3/tax-protect.html:5, :89, :157, :184 - `viewport-fit=cover` jest na wszystkich stronach, a `env(safe-area-inset-*)` mają tylko pasek akcji, wąski dymek i `.calc-peek`. Pod wycięcie ekranu wchodzą `.container`, `.site-header` i `.menu-panel`: gutter `clamp(16px,4vw,40px)` daje ok. 34 px przy 844 px, a wcięcie iPhone’a w poziomie ma 47–59 px. Kopie: makieta-v3.html:298 (i `.klauzula` :659), oc-beauty.html:85, :161, slownik.html:88, :156, utrata-dochodu.html:91, nnw-dzieci.html:92, grupowe-ergo.html:89, opieka-medyczna/common.css (→ :99). W Strefie: strefa.css:171 `.topbar`, :202 `.app`, :435 `.drawer-panel`, :444 `.drawer-foot`, :458 `.app-footer`, :465 `.auth-top`, :621 `.sidenav`, dam-prace.html:55 `.pub-header` → `padding-inline:max(var(--bp-gutter),env(safe-area-inset-left)) max(var(--bp-gutter),env(safe-area-inset-right))`, w szufladach `padding-left` i `padding-bottom` z `env()`. Alternatywa: zrezygnować z `viewport-fit=cover`. Wniosek z kodu, bo Chromium nie emuluje wcięć [Safe Areas & Layout · średnia]
- docs/koncepcja/design/v3/tax-protect.html:15 - `theme-color` to #141C33 (midnight), a góra strony jest jasna (ivory, marmur). Tak jest na wszystkich stronach publicznych, w szablonach generatorów (gen_oc_beauty.szablon.html, opieka-medyczna/template.html:15, slownik/gen_strona.py) i w Strefie (logowanie.html:10, panel.html:10, dam-prace.html:10, szkolenia.html:10) → na stronach publicznych `#F7F3EC`. W Strefie `#EDE5D8` na logowaniu i w publicznej części „Dam pracę” (jasny `.pub-bar`). W panelu ciemny jest tylko kafel `.topbar-inner` na tle parchment, więc to do decyzji: grupa „wspólne” uznała #141C33 za pasujące, grupa „Strefa” nie [Dark Mode & Theming · niska]
- docs/koncepcja/design/v3/tax-protect.html:75–93 - Nigdzie nie ma `touch-action:manipulation`: ani w bazie stron i jej kopiach, ani w strefa.css:57–78 (body :59, `.btn` :116), ani w CSS paska akcji (gen_wspolne.py:189). Podwójne tapnięcie kafla powiększa stronę → `a,button,summary,label,input,select,textarea,[role=button]{touch-action:manipulation}` [Touch & Interaction · niska]
- docs/koncepcja/design/v3/tax-protect.html:75–93 - `-webkit-tap-highlight-color` nie jest ustawiony, ani w stronach, ani w strefa.css, ani w gen_wspolne.py:189. Zostaje domyślna szara plama, także na ciemnym pasku akcji i na kaflach, które w całości przykrywa `input` (`.opt`, `.sl-chip`) → np. `rgba(42,59,104,.12)` albo `transparent`, jeśli stany `:active` są dopracowane [Touch & Interaction · niska]
- docs/koncepcja/design/v3/tax-protect.html:77 (makieta-v3.html:286, oc-beauty.html:73, slownik.html:76, strefa.css:58) - Brakuje `@media (pointer:fine){html{overscroll-behavior:none}}`. Na gładziku strona z przyklejonym nagłówkiem „odbija się” przy krańcach przewijania i pokazuje jasne tło pod ciemną stopką. Po zmianie przetestować urządzenia hybrydowe [Touch & Interaction · niska]
- docs/koncepcja/design/v3/tax-protect.html:153, :182, :185, :199, :247, :252, :285, :301 - Bez `:hover` (zmienia się tylko kursor) są:
  - `.link-quiet`, np. 20 linków „Wróć do indeksu A–Z” w słowniku i 18 w `.job-links` na stronie utraty dochodu;
  - `.crumbs a`;
  - `.menu summary` („Menu”);
  - linki szuflady `.menu-panel a:not(.btn)` – szuflada działa do 1199 px, więc także na laptopach z myszą;
  - linki w treści: `.mind`, `.scope-extra`, `.how-note`, `.note`, `.faq`, `.step`, `.zlista-desc`, `.zempty`, `.zrules`, `.clause-intro`, `.lead-notice`, `.zab-more`, a w opiece `.hero-note`, `.price-note`, `.cmp-table`, `a.tel`.

  Kopie: makieta-v3.html:370, :402, :405, :620, :783, :808; oc-beauty.html:157, :192, :207, :265, :286, :304, :353, :373; slownik.html:152, :184, :198; utrata-dochodu.html:163, :198, :213, :243, :362; nnw-dzieci.html:156, :188, :202, :245, :250, :283, :299, :520; grupowe-ergo.html:161, :196, :211, :271, :288, :480; opieka-medyczna/common.css:158, :161 (→ :163, :209, :252, :257, :290, :306) → jedna reguła, np. `a:not(.btn):not(.link-lux):hover{text-decoration-thickness:2px}` i `.menu summary:hover{border-color:var(--color-navy)}` [Hover & Interactive States · niska]
- docs/koncepcja/design/v3/tax-protect.html:148 (utrata-dochodu.html:158, nnw-dzieci.html:151, grupowe-ergo.html:156, opieka-medyczna.html:158, strefa.css:127) - `.btn-ghost-dark:hover` zmienia tekst z ivory na gold-light. Kontrast spada na navy z 9,87 do 6,16:1, a na midnight z 15,27 do 9,53:1, więc hover jest słabszy od spoczynku → tekst zostaje ivory, a mocniejsza staje się ramka albo tło, np. `rgba(217,192,137,.14)` [Hover & Interactive States · niska]
- docs/koncepcja/design/v3/tax-protect.html:150, :383, :400, :434 - Poza `transform` i `opacity` animowane są:
  - `width` kreski `.link-lux::after`, co przelicza układ;
  - `background-size` podkreślenia `.btn-navy`;
  - `clip-path` ramy hero (`frame-draw`);
  - `block-size` w `::details-content`: w FAQ, a w oc-beauty.html:512 także w listach zabiegów z 49 i 63 pozycjami, domyślnie otwartych.

  Kopie: makieta-v3.html:367–368, :918–919, :957, :968, :1040; oc-beauty.html:154, :512; utrata-dochodu.html:160, :429, :446, :487; nnw-dzieci.html:153, :381, :398, :432, :540; grupowe-ergo.html:158, :365, :382; opieka-medyczna.html:160; strefa.css:131–132, :138–139 → kreski przez `transform:scaleX()` z `transform-origin:left`, rama przez `opacity` i `scale`. `block-size` zostawić jako świadomy wyjątek albo zdjąć z długich list. Przejścia samych kolorów mogą zostać, bo wymagają tylko malowania [Animation · niska]
- docs/koncepcja/design/v3/tax-protect.html:789–790, :868, :1105, :1117, :1121 - W żadnej stronie ani w żadnym generatorze nie ma `translate="no"`. Tłumacz przeglądarki może więc przełożyć nazwy marek i produktów: BeautyPolisa, Aura Expert, (Fundacja) Beauty Razem, ERGO Razem, ERGO Hestia, ERGO Życie w Biznesie, ENEL-MED, LUX MED, Colonnade, Tax Protect, Leadenhall, CEU oraz warianty „Dla Mnie/Dla Nas/Dla Rodziny”. To samo grozi numerom programu, polis, zamówień i ogłoszeń oraz domenom. Miejsca: gen_wspolne.py:24–45 (`PRODUKTY`), nagłówek i stopka (wyżej), makieta-v3.html:1205–1207, :1293, :1347–1352, :1704, :1745, :1889; oc-beauty.html:946, :948, :1363, :1436; slownik.html:1719, :1803, :1939; utrata-dochodu.html:1125–1128; grupowe-ergo.html:1280, :1292, :1303; opieka-medyczna.html:1130; strefa: panel.html:89, :268, dam-prace.html:418, :1913, szkolenia.html:290, :1043 → `<span translate="no">`, w generatorach przez listę nazw [Locale & i18n · niska]
- docs/koncepcja/design/v3/tax-protect.html:22–24 - Ten sam `<head>` jest na makieta-v3.html:229–231, utrata-dochodu.html:23–25, nnw-dzieci.html:24–26, grupowe-ergo.html:21–23, opieka-medyczna.html:31–33 i w strefa/*.html. Fonty idą z CSS Google Fonts z `display=swap` i preconnect, ale bez preload krytycznych krojów (Cormorant 600 w H1, Poppins 400/500). Adresy plików w Google Fonts CSS2 się zmieniają, więc preload jest niemożliwy → w produkcji hostować woff2 samodzielnie (`@font-face`, `font-display:swap`) i dodać `<link rel="preload" as="font" type="font/woff2" crossorigin>` dla 1–2 krojów. Przy okazji adres IP nie trafia do Google. W Strefie komentarz w `<head>` zapowiada `next/font/local` [Performance · niska]
- docs/koncepcja/design/v3/tax-protect.html:130 - `tabular-nums` w komórkach kwot nie działa, bo Poppins z Google Fonts nie ma cechy `tnum`. Przy obliczonym `tabular-nums` „1111” ma 20,5 px, a „0000” 40,2 px. Dotyczy to taryfy Tax oraz nnw-dzieci.html:133, :483, grupowe-ergo.html:247, :491, opieki (common.css:106, template.html:93 → :526) i makieta-v3.html:636, :848. W Strefie samo dopisanie `tabular-nums` do `.price` oraz kolumn „Zapisy” i „Okres” (szkolenia.html:70, :1375; panel.html:385, :412) też nic nie da, jeśli krojem zostanie Poppins → liczby w tabelach składać w Cormorant (lining, tabular; w utracie `.ledger td` trzyma pion) albo hostować krój z `tnum` (patrz uwaga o fontach) [Typography · niska]
- docs/koncepcja/design/v3/tax-protect.html:1235 (makieta-v3.html:2597, oc-beauty.html:1672, slownik.html:3240, utrata-dochodu.html:1435, nnw-dzieci.html:1398, grupowe-ergo.html:1652, opieka-medyczna.html:1981) - Zapasowy skrypt wejść działa tylko w przeglądarkach bez `animation-timeline`. W jednej pętli czyta `getBoundingClientRect()` i dodaje klasę `is-in`, więc każdy kolejny odczyt wymusza przeliczenie stylu → najpierw zebrać `top` wszystkich elementów, potem wywołać `show()` [Performance · niska]
- docs/koncepcja/design/v3/tax-protect.html:1027–1031 (utrata-dochodu.html:1223–1228, nnw-dzieci.html:1203–1208, grupowe-ergo.html:1439–1445, opieka-medyczna/template.html:704 `<!--nb-off-->` → :1779–1784) - Odpowiedzi FAQ są celowo bez twardych spacji, bo to ten sam tekst co FAQPage w JSON-LD. Jednoliterowe „i, w, z, o” zostają na końcu wiersza, a „1 532 zł”, „250 000 zł” i numer telefonu mogą się złamać w środku → `&nbsp;` tylko w widocznym HTML, JSON-LD bez zmian [Typography · niska]
- docs/koncepcja/design/v3/tax-protect.html:193, :204 (utrata-dochodu.html:218, nnw-dzieci.html:207, opieka-medyczna/common.css:180 → :214, template.html:64 → :497, grupowe-ergo.html:530) - Przy tekście powiększonym do 200% (font-size korzenia) i oknie 390 px wszystkie strony produktów przewijają się w poziomie (scrollWidth 470–593), a czytanie hero wymaga przesuwania. Przyczyny: `.figures dd{white-space:nowrap}`, siatka `.hero-panel` bez `minmax(0,1fr)` i w opiece `.seg-opt span{nowrap}`. W ERGO `.kv dd` wystaje o 23 px także przy 1280 px → `grid-template-columns:minmax(0,1fr)`, `white-space:normal` poniżej 540 px, `overflow-wrap:break-word` na h1, h2 i `.lead` [Content Handling · średnia]
- docs/koncepcja/design/v3/tax-protect.html:166, :169 (makieta-v3.html:384, oc-beauty.html:171, utrata-dochodu.html:177, nnw-dzieci.html:169, grupowe-ergo.html:175, slownik.html:165, opieka-medyczna/common.css:142) - `.brand{flex:none}` razem z podpisem „created by Aura Expert” nie pozwala logo się kurczyć. Przy domyślnej czcionce 24 px przycisk „Menu” wystaje poza belkę i okno (przy 375 px zajmuje 336–384). Ikona zostaje widoczna i działa → `.brand{flex:0 1 auto;min-width:0}`, `.brand small{white-space:normal}`, `.menu{flex:none}` [Content Handling · niska]
- docs/koncepcja/design/v3/tax-protect.html:1121, :1130 (stopka kopiowana na strony publiczne; strefa/*.html:893, :907) - W danych rejestrowych i adresie stoją zwykłe spacje: przy numerze lokalu, po „NIP”, „REGON” i „numerem” oraz między kodem pocztowym a miastem → `&nbsp;` [Typography · niska]
- docs/koncepcja/design/v3/tax-protect.html:856, :1218–1225 (utrata-dochodu.html:918, :1418–1425; nnw-dzieci.html:937, :1381–1388; grupowe-ergo.html:1082, :1635–1642; opieka-medyczna.html:1119, :1964–1971) - Tło hero (`tlo-marmur-len*.webp`) jest elementem LCP, ale ładuje się dopiero z klasą `.bg-on`. Tę klasę nadaje IntersectionObserver na końcu `<body>`, więc żądanie obrazu wychodzi dopiero ok. DOMContentLoaded. Przy dławieniu sieci tax-protect przy 1440 px ma LCP 2412 ms, a tekst H1 692 ms → klasa `bg-on` wpisana w HTML sekcji hero i `<link rel="preload" as="image" fetchpriority="high">` dla wersji 1024 i desktopowej. Komentarz „poza heroem” w utracie i ERGO jest nieaktualny [Images · średnia]

### 3.3 Strony

#### docs/koncepcja/design/v3/makieta-v3.html

- docs/koncepcja/design/v3/makieta-v3.html:2425, :2478, :2275, :2475, :2732 - `licz(true)` działa tylko przy starcie, a przeliczanie tylko na zdarzeniu `change`. Po powrocie z podstrony bez bfcache przeglądarka przywraca zaznaczenia po `load`, bez `change`. Skutki:
  - OC przy zaznaczonych polach pokazuje „Zaznacz rodzaj działalności.”, CTA jest nieaktywne, a kwoty sum są puste;
  - Tax pokazuje 1 532 zł i wariant „do 250 tys. zł” zamiast 2 701 zł, a CTA wysłałoby nieaktualną kwotę;
  - pozycje a–h zostają ukryte;
  - tekst „co dalej” formularza nie zgadza się z tematem.

  → `window.addEventListener('pageshow',()=>licz(true))` w obu kalkulatorach i `syncCalc()` w formularzu [Hydration Safety · wysoka]
- docs/koncepcja/design/v3/makieta-v3.html:602, :622, :2334, :810, :2728 - Długi tekst bez spacji rozpycha układ. Wyszukiwarka: `.zab-search` to siatka z niejawną kolumną, a „Nie znaleźliśmy…” powtarza frazę. Przy 320 px fraza z 41 znaków poszerza pole i akapit do 366 px, więc strona przewija się w poziomie. Formularz: e-mail wpisany w pole imienia (27 znaków) poszerza panel podziękowania do 366 px → `.zab-search{grid-template-columns:minmax(0,1fr)}`, `.zab-empty,.lead-status{overflow-wrap:anywhere}` [Content Handling · średnia]
- docs/koncepcja/design/v3/makieta-v3.html:2721–2730, :1886 - Wysłanie formularza kontaktu od razu chowa formularz i pokazuje podziękowanie. Makieta nie ma stanu w trakcie żądania ani stanu błędu sieci (komentarz zapowiada `fetch POST /api/leads`) → po starcie żądania `disabled`, `aria-busy` i „Wysyłanie…”. Po błędzie dane zostają w formularzu, a `role=alert` podaje dalszy krok („Spróbuj ponownie albo zadzwoń…”) [Forms · średnia]
- docs/koncepcja/design/v3/makieta-v3.html:2278–2279, :2225–2231, :1383, :1422, :1432 - Po kliknięciu nieaktywnego CTA fokus trafia w pole z brakiem. Przy polu nie ma jednak komunikatu ani `aria-invalid` czy `aria-describedby`. Komunikat jest tylko w `#cena`, poza ekranem → akapit w fieldsecie wzorem `#ankieta-brak` (:1471), powiązany przez `aria-describedby` i chowany po uzupełnieniu [Forms · niska]
- docs/koncepcja/design/v3/makieta-v3.html:2500, :2514–2516 - `#kalkulator-tax` działa tylko przy wejściu na stronę: kliknięcie zakładki nie zmienia adresu. Wyborów kalkulatorów (:2275, :2475) nie da się podlinkować → `history.replaceState` w `select()`; opcjonalnie odpowiedzi w query [Navigation & State · niska]
- docs/koncepcja/design/v3/makieta-v3.html:347, :636, :848 - Selektor `.tariff td` nie trafia w żadną komórkę, bo tabele mają klasę `.tariff-table`. W `.opt-kwota` i `.calc-peek strong` późniejszy skrót `font:` zeruje `tabular-nums` → `.tariff-table td`, `font-variant-numeric` po skrótach `font` (zob. uwagę o Poppins w 3.2) [Typography · niska]
- docs/koncepcja/design/v3/makieta-v3.html:534, :541–542, :641 - Kafelki wyboru (`.opt label`, `.check-row`, `.zakres-opcja`) nie mają stanu hover. `input` przykrywa `label` → `.opt input:hover + label{border-color:var(--color-navy)}` w `@media (hover:hover)` [Hover & Interactive States · niska]
- docs/koncepcja/design/v3/makieta-v3.html:363 - `.btn-ivory:hover` zmienia tło z ivory na parchment. Kontrast navy spada z 9,87 do 8,73:1, a przycisk słabiej odcina się od granatowego panelu → na hover jaśniejsze tło albo złota linia jak w `.btn-navy` [Hover & Interactive States · niska]
- docs/koncepcja/design/v3/makieta-v3.html:959, :1013 - „Plate” animuje `clip-path` sprzężony z przewijaniem, więc odmalowuje się przy każdym przewinięciu → maska albo warstwa ze `scale` [Animation · niska]
- docs/koncepcja/design/v3/makieta-v3.html:1293, :1325, :1327, :1448, :1502, :1572, :1590, :1812, :1821, :1822, :2204, :2436, :2458, :2461, :2718 - Zwykłe spacje stoją tam, gdzie powinny być twarde: „od 2 do 100 osób”, „2–4 spory” (w HTML i w `SPORY_TXT`), „49 pozycji”, „np. w”, „m.in. NIP”, „LUX MED”. W JS: `r.nazwa` w `#taryfa` idzie bez `tw()`, CTA Tax „Poproś o wycenę…” i „Poproś o polisę…” (statyczne :1567 ma `o&nbsp;`), przykład numeru w komunikacie błędu → `&nbsp;`, w JS `NB` albo `tw()` [Typography · niska]
- docs/koncepcja/design/v3/makieta-v3.html:1407 - Placeholder „Wpisz zabieg, np. mezoterapia” nie kończy się „…” [Forms · niska]
- docs/koncepcja/design/v3/makieta-v3.html:1859 - `#l-email` nie ma `spellcheck="false"` (opcjonalnie też `autocapitalize="none"`) [Forms · niska]
- docs/koncepcja/design/v3/makieta-v3.html:1407 - `#zab-q` nie ma atrybutu `name`. Skutek jest znikomy, bo pole ma `autocomplete=off`, a formularz się nie wysyła → `name="zabieg"` [Forms · niska]
- docs/koncepcja/design/v3/makieta-v3.html:641, :1447–1453 - Karty „Klauzula ochrony prawnej” i „Wykonuję zabiegi…” wyglądają jak kafel. Kliknięcie w padding karty nie zaznacza jednak pola → padding przenieść z `.zakres-opcja` na `label.check-row` [Forms · niska]
- docs/koncepcja/design/v3/makieta-v3.html:1843, :2275, :2475 - Wypełniony, niewysłany formularz kontaktu i wybory kalkulatora przepadają po kliknięciu linku, bez ostrzeżenia → `beforeunload` tylko przy niewysłanych danych formularza; dla kalkulatora wystarczy stan w URL [Forms · niska]
- docs/koncepcja/design/v3/makieta-v3.html:2044–2053, :2438 - Kwoty formatują dwa niezależne, ręczne formatery: `grupuj()` w `gen:oc-skladka` (snippets/oc-skladka.js) i `zl()` z regexem → jeden `Intl.NumberFormat('pl-PL',{style:'currency',currency:'PLN',useGrouping:'always'})` [Locale & i18n · niska]
- docs/koncepcja/design/v3/makieta-v3.html:526, :742, :772 - Legendy kalkulatora, h4 w promocji i pytania FAQ (`.faq summary`) nie mają `text-wrap:balance` [Typography · niska]
- docs/koncepcja/design/v3/makieta-v3.html:1306, :1813, :2647 - Liczebniki słowne stoją obok liczników cyfrowych: „Odsłoń sześć sytuacji” przy „0 z 6”, „Osiem pozycji (a–h)” i „Wszystkie sześć chwil odsłonięte” po „5 z 6” → cyfry [Content & Copy · niska]
- docs/koncepcja/design/v3/makieta-v3.html:1823 - Zdanie „składka jest wyceniana indywidualnie” jest w stronie biernej [Content & Copy · niska]
- docs/koncepcja/design/v3/makieta-v3.html:1413, :1418, :1661, :1704, :1761, :2334 - Teksty są w pierwszej osobie: „Pokażemy…”, „dołączymy je do zgłoszenia”, „podajemy”, „sprawdzimy go”, „Nie znaleźliśmy…” → „Zobaczysz…”, „Doradca dołączy…”. Zgoda (:1862) i RODO (:1890) zostają w pierwszej osobie [Content & Copy · niska]

#### docs/koncepcja/design/v3/oc-beauty.html

- docs/koncepcja/design/v3/oc-beauty.html:512 - `overflow:clip` na `::details-content` (`.zdetails`, FAQ) przycina obwódkę fokusu przy krawędzi treści. Trzy linki „Wróć na początek listy” (:1066, :1145, :1169) tracą lewy i dolny bok obwódki, a linki FAQ na początku wiersza (:1398–1402) lewy bok → `overflow-clip-margin:6px` [Focus States · średnia]
- docs/koncepcja/design/v3/oc-beauty.html:1554, :1596 - Fraza wyszukiwania zabiegów nie trafia do adresu, a `?q=` przy wejściu jest ignorowane. Kotwice `#zabieg` nie przenoszą stanu filtra → przy starcie `URLSearchParams` i `apply(true)`, po zmianie `history.replaceState` z zachowaniem hasha [Navigation & State · średnia]
- docs/koncepcja/design/v3/oc-beauty.html:285, :1572 - Fraza bez spacji w `.zempty` rozpycha stronę od ok. 32 znaków przy 320 px (scrollWidth do 1153) → `overflow-wrap:anywhere` [Content Handling · niska]
- docs/koncepcja/design/v3/oc-beauty.html:982 - Placeholder „np. mezoterapia, henna, manicure” nie kończy się „…” [Forms · niska]
- docs/koncepcja/design/v3/oc-beauty.html:948, :1436 - Poza blokami GEN brakuje twardych spacji w „nr WA50/003353/24/A” i „100 osób” [Typography · niska]
- docs/koncepcja/design/v3/oc-beauty.html:1247, :1572 - Teksty są w pierwszej osobie: „publikujemy bez skrótów”, „Nie znaleźliśmy zabiegu…” → „Pełna treść klauzuli, z wyłączeniami – poniżej”, „Zabiegu „…” nie ma na listach programu” [Content & Copy · niska]
- docs/koncepcja/design/v3/oc-beauty.html:330, :364 - Podpis tabeli taryfy (`caption`) i pytania FAQ pełnią rolę nagłówków, ale mają `text-wrap:wrap` → `text-wrap:balance` [Typography · niska]
- docs/koncepcja/design/v3/oc-beauty.html:1004–1213 - Listy zabiegów (razem 120 pozycji, `details` domyślnie otwarte) nie mają `content-visibility` → `.zlista{content-visibility:auto;contain-intrinsic-size:auto 1500px}`, potem sprawdzić kotwice [Performance · niska]

#### docs/koncepcja/design/v3/slownik.html

✓ pass – strona jest w całości generowana. Uwagi są przy `slownik/gen_strona.py` (3.1) i we wzorcach wspólnych (3.2).

#### docs/koncepcja/design/v3/tax-protect.html

- docs/koncepcja/design/v3/tax-protect.html:988 - Linki „Kalkulator” i „Formularz” poza kontekstem, np. na liście linków czytnika, nie mówią, czego dotyczą. Ten sam układ jest w oc-beauty.html:1357, gdzie weryfikacja uznała kontekst h3 za wystarczający (WCAG 2.4.4) → opcjonalnie „Kalkulator Tax Protect” i „Formularz kontaktu” albo dopisek sr-only [Content & Copy · niska]
- docs/koncepcja/design/v3/tax-protect.html:1071 - W „od 2 do 100 osób” stoją zwykłe spacje [Typography · niska]

#### docs/koncepcja/design/v3/utrata-dochodu.html

- docs/koncepcja/design/v3/utrata-dochodu.html:957, :965, :1001–1058, :1166 - Brakuje twardych spacji w „po 90 dniach”, „przez 182 dni”, „farb i utleniaczy”, „5 kroków” i „ok. 5 minut” [Typography · niska]
- docs/koncepcja/design/v3/utrata-dochodu.html:1145, :1159, :1225 - Teksty są w pierwszej osobie: „nie podajemy tu kwot” (3 razy), „nie wskazujemy wariantu” → „Ta strona nie wskazuje wariantu…”, „Kwot tu nie ma, bo…” [Content & Copy · niska]
- docs/koncepcja/design/v3/utrata-dochodu.html:1283 - „około pięciu minut” stoi na tej samej stronie co „ok. 5 minut” (:1166) → „ok. 5 minut” [Content & Copy · niska]
- docs/koncepcja/design/v3/utrata-dochodu.html:1226 - Zdanie w FAQ jest w stronie biernej: „jeśli nie zostały zgłoszone i przyjęte przez ubezpieczyciela” → „jeśli ich nie zgłosisz albo ubezpieczyciel ich nie przyjmie” [Content & Copy · niska]
- docs/koncepcja/design/v3/utrata-dochodu.html:967–982 - W `<figure class="ledger">` po `<figcaption>` (:978) stoi jeszcze `div.ledger-actions` (:979). `figcaption` musi być pierwszym albo ostatnim dzieckiem `figure` → akcje przenieść za `</figure>` [Accessibility · niska]

#### docs/koncepcja/design/v3/nnw-dzieci.html

- docs/koncepcja/design/v3/nnw-dzieci.html:982, :988, :1033, :1124 - Liczby z jednostką mają zwykłe spacje, np. „24 godziny”, „19 jednostek” [Typography · niska]
- docs/koncepcja/design/v3/nnw-dzieci.html:1059–1061, :1069 - Nagłówki wierszy mają wielkie litery w środku fraz, i to niespójnie: „Śmierć Rodzica Osoby ubezpieczonej”, „Koszty pogrzebu Osoby Ubezpieczonej”, „z tytułu Uszczerbku” → zwykła pisownia albo konsekwentnie terminy z OWU z adnotacją [Content & Copy · niska]
- docs/koncepcja/design/v3/nnw-dzieci.html:1089, :1094 - „co najmniej dwa dni / trzy dni” stoi na tej samej stronie co „min. 2 dni / min. 3 dni” (:1030, :1032) → cyfry [Content & Copy · niska]
- docs/koncepcja/design/v3/nnw-dzieci.html:1001, :1205 - Zdanie „Umowa jest zawierana na 12 miesięcy” jest w stronie biernej → „Umowę zawierasz na 12 miesięcy” [Content & Copy · niska]

#### docs/koncepcja/design/v3/grupowe-ergo.html

- docs/koncepcja/design/v3/grupowe-ergo.html:1138–1177, :1192, :1201, :1216–1222 - Brakuje twardych spacji w nagłówkach wierszy („w wyniku…”), w „Limit 10 000 zł”, „2 000 000 €” i „500 / 250 / 500 / 400 zł” [Typography · niska]
- docs/koncepcja/design/v3/grupowe-ergo.html:1064, :1403, :1439 - „Która droga dla mnie” w H2, w pozycji menu i w linku w FAQ to pierwsza osoba → „Która droga dla Ciebie” [Content & Copy · niska]
- docs/koncepcja/design/v3/grupowe-ergo.html:1189 - Zdanie „Świadczenia MediOpieka są realizowane w Polsce” jest w stronie biernej → „MediOpieka realizuje świadczenia w Polsce” [Content & Copy · niska]
- docs/koncepcja/design/v3/grupowe-ergo.html:534 - `.inner-details > summary` (2 razy) nie zmienia się po najechaniu [Hover & Interactive States · niska]

#### docs/koncepcja/design/v3/opieka-medyczna.html

✓ pass – strona jest w całości generowana. Uwagi są przy `opieka-medyczna/` (3.1) i we wzorcach wspólnych (3.2).

#### docs/koncepcja/design/v3/strefa/strefa.css

- docs/koncepcja/design/v3/strefa/strefa.css:72 - `.topbar :focus-visible{outline-color:gold-light}` obejmuje też jasne menu konta `.account-panel` (panel.html:92–111, tak samo w dam-prace i szkoleniach). Obwódka #D9C089 na #F7F3EC ma kontrast 1,6:1 na linkach z nazwą salonu, „Ustawienia” i „Wyloguj” → `.topbar .account-panel :focus-visible{outline-color:var(--color-navy)}` albo zawężenie złotej reguły do `.topbar-inner > :focus-visible` [Focus States · średnia]
- docs/koncepcja/design/v3/strefa/strefa.css:134, :180, :236, :382, :461, :554 - Po najechaniu nic się nie zmienia w `.link-quiet` („Wyślij kod ponownie”, „Anuluj”, „Wyczyść filtry”), `.nav-toggle`, `.crumbs a`, karcie `.radio-card`, `.app-footer a` i `.legal-idd > summary` → `.link-quiet:hover,.crumbs a:hover,.app-footer a:hover{text-decoration-thickness:2px}`, `.nav-toggle:hover{border-color:var(--color-gold-light)}`, `.radio-card input:hover + label{border-color:var(--color-navy)}` (pole leży nad etykietą), `.legal-idd > summary:hover{text-decoration:underline}` [Hover & Interactive States · niska]
- docs/koncepcja/design/v3/strefa/strefa.css:145–149 - `.switch` nie ma `:hover`. Dziś jedyny `.switch` (panel.html:706) jest wyłączony. Przełączniki zakładek w Ustawieniach salonu (preferencja widoku, 00 D44) używają innego wzorca – `input.toggle` (uzupełnienie 16.11.2026), więc uwaga dotyczy tylko starego `.switch` → `.switch:not([disabled]):hover::before{box-shadow:0 0 0 3px rgba(42,59,104,.15)}` [Hover & Interactive States · niska]
- docs/koncepcja/design/v3/strefa/strefa.css:146–147 - `transition:background-position` w `.switch::before` nic nie animuje, bo zmiana stanu podmienia cały `background` (obraz `radial-gradient`). Gałka przeskakuje → gałka jako osobny `::after` z `transform:translateX(20px)` dla `[aria-checked=true]` i `transition:transform` [Animation · niska]
- docs/koncepcja/design/v3/strefa/strefa.css:621 - Menu boczne na telefonie (`.js .sidenav.is-open`, fixed, `overflow-y:auto`) nie ma `overscroll-behavior:contain`. Jego otwarcie nie blokuje przewijania strony (`closeNav` i `toggle` w panel.html:1068–1083 nie dodają `drawer-lock`), więc przewijanie przechodzi z końca listy na stronę → `contain` i `drawer-lock` przy otwarciu [Touch & Interaction · niska]
- docs/koncepcja/design/v3/strefa/strefa.css:334 - E-mail od użytkownika w `.alert` się nie łamie (logowanie.html:144, :453; panel.html:607). Adres z 47 znaków przy 320 px wystaje 41 px poza ramkę → `.alert strong,.who,.notice-box,.private{overflow-wrap:anywhere}` [Content Handling · niska]
- docs/koncepcja/design/v3/strefa/strefa.css:187–188 - Długa nazwa salonu w menu konta łamie się na kilka wierszy. Pasek rośnie wtedy ponad `scroll-padding-top` 92 px (:58), np. przy 768 px z 86 do 123 px → `min-width:0` oraz `white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:24ch` na `.account-name strong`. Pełna nazwa jest w `.acc-who` [Content Handling · niska]
- docs/koncepcja/design/v3/strefa/strefa.css:528–530 - Pole telefonu z prefiksem „+48” wygląda jak jedna kontrolka, ale obrys fokusu obejmuje tylko `input` (logowanie.html:567) → `.with-prefix:focus-within{outline:2px solid var(--color-navy);outline-offset:2px}` [Focus States · niska]
- docs/koncepcja/design/v3/strefa/strefa.css:255, :337, :349, :356, :399, :507 - `<strong>` pełniące rolę nagłówków (`.alert-title`, `.shortcut`, `.banner`, `.empty`, `.steps`, `.statement`; też dam-prace.html:82 `.howto`) nie mają `text-wrap:balance` [Typography · niska]

#### docs/koncepcja/design/v3/strefa/logowanie.html

- docs/koncepcja/design/v3/strefa/logowanie.html:160, :465, :594, :866–876 - Licznik „Możliwe za 0:59” jest w regionie `aria-live="polite"` i zmienia się co sekundę, więc czytnik ogłasza go przez 60 s w trakcie wpisywania kodu. Po 0:00 region jest ukrywany, więc nie słychać, że „Wyślij kod ponownie” już działa → `role="timer" aria-live="off"` (wzór: szkolenia.html:979) i osobny komunikat sr-only po dojściu do 0 [Accessibility · wysoka]
- docs/koncepcja/design/v3/strefa/logowanie.html:879, :998–1006 - `setErr` wpisuje błąd do `.field-error`, który nie jest regionem live. Przy formularzach jednopolowych zatwierdzanych Enterem fokus już jest w polu, więc „Kod jest nieprawidłowy. Pozostały 3 próby” nie zostaje odczytany. Ten sam `setErr` jest w panel.html:1127, dam-prace.html:2871 i szkolenia.html:2298 → wspólny region sr-only `role="alert"` w `setErr` [Accessibility · średnia]
- docs/koncepcja/design/v3/strefa/logowanie.html:750, :1005 - Komunikat o błędnym kodzie SMS podaje tylko problem i liczbę prób, a komunikat dla kodu z e-maila (:316) ma następny krok → „Sprawdź SMS i wpisz kod ponownie albo wyślij nowy kod.” [Content & Copy · niska]
- docs/koncepcja/design/v3/strefa/logowanie.html:115 - Placeholder „np. anna@salon-przykladowy.example” nie kończy się „…” [Forms · niska]
- docs/koncepcja/design/v3/strefa/logowanie.html:149, :184, :255, :293, :458, :587, :619 - Pola kodów, a także e-mail zgłoszenia szkody w panel.html:491, nie mają `spellcheck="false"`. Inne pola e-mail i NIP go mają, więc chodzi głównie o spójność [Forms · niska]
- docs/koncepcja/design/v3/strefa/logowanie.html:111, :144, :150, :453, :459, :563, :909, :916, :950, :1001 - „Sześć cyfr” i „sześciocyfrowy kod” są zapisane słownie, a reszta strony używa cyfr („10 minut”) → „6 cyfr”, „6-cyfrowy kod” [Content & Copy · niska]
- docs/koncepcja/design/v3/strefa/logowanie.html:189, :463 - Etykiety „Potwierdź” (TOTP, po nim następuje logowanie) i „Dalej” (kod z e-maila) nie mówią, co się stanie → „Zaloguj się”, „Potwierdź kod” [Content & Copy · niska]
- docs/koncepcja/design/v3/strefa/logowanie.html:323, :755, :1000 - Komunikat „Ten kod został unieważniony” jest w stronie biernej → „Ten kod już nie działa – wyślij nowy”. Nie zamieniać na „Unieważniliśmy…”, bo to łamie regułę o pierwszej osobie [Content & Copy · niska]
- docs/koncepcja/design/v3/strefa/logowanie.html:331, :437 - „Mam już konto” to pierwsza osoba → „Masz konto? Zaloguj się”. Wybór ścieżki („Jestem pracodawcą”, :364) może zostać [Content & Copy · niska]
- docs/koncepcja/design/v3/strefa/logowanie.html:909, :988, :1001, :1005 - Komunikaty JS mają zwykłe spacje po jednoliterowych słowach (np. „z e-maila”) → stała `NB` jak w szkolenia.html [Typography · niska]

#### docs/koncepcja/design/v3/strefa/panel.html

- docs/koncepcja/design/v3/strefa/panel.html:370, :973–994, :1009 - Adresy `#p-szkody` i `#p-archiwum` otwierają „Polisy” z zakładką „Aktualne”. Docelowy panel zostaje ukryty, a fokus spada na `<body>` (:990–992). Na taki adres prowadzi link ze słownika (slownik.html:3073). Kliknięcie zakładki nie zmienia adresu, tak samo w szkolenia.html:2203 → skopiować do `render()` obsługę `role=tabpanel` z szkolenia.html:2179–2182, a przy kliknięciu dodać `history.replaceState(null,'','#'+panel.id)` [Navigation & State · średnia]
- docs/koncepcja/design/v3/strefa/panel.html:1057 - Podmiana `textContent` na „Pobieranie…” usuwa `<span class="sr-only">` z kontekstem (linki :813–815). Po kliknięciu wszystkie linki nazywają się „Pobierz PDF”, a stan pobierania nie jest ogłaszany → zmieniać tylko widoczny `span`, stan podać w `role=status` [Accessibility · średnia]
- docs/koncepcja/design/v3/strefa/panel.html:1103, :1115 - Po akcji („Odnów z doradcą”, „Poproś doradcę o nowy link”) przycisk z fokusem dostaje `disabled`, więc fokus spada na `<body>`. Zmiana napisu nie jest ogłaszana. To samo w dam-prace.html:3200, :3212 (Wyślij zgłoszenie, Zapisz szkic) i szkolenia.html:2269 (zgłoszenie nadużycia) → `aria-disabled="true"` z blokadą w obsłudze albo przed wyłączeniem fokus na komunikat `role=status` z `tabindex=-1`, jak `done()` w szkolenia.html:2462 [Forms · średnia]
- docs/koncepcja/design/v3/strefa/panel.html:158, :263, :269, :299, :336, :366, :441, :529, :533, :545, :572, :578, :584, :604, :685, :732, :733, :799, :801, :815, :884, :1145, :1150 - Brakuje twardych spacji przed „–” (96 zwykłych spacji wobec 19 `&nbsp;`), w „nr WA50…” i „Aneks nr 1”, w datach („7 listopada”) i w „2 osoby”. To samo w komunikatach JS, także dam-prace.html:3307 → konwencja z szkolenia.html: `&nbsp;– `, `nr&nbsp;`, stała `NB` [Typography · niska]
- docs/koncepcja/design/v3/strefa/panel.html:337 - Etykieta „Zarządzaj” nie mówi, czym się zarządza → „Zarządzaj zespołem” [Content & Copy · niska]
- docs/koncepcja/design/v3/strefa/panel.html:510 - Komunikat „Zgłoszenie … zostało przyjęte” jest w stronie biernej → np. „Doradca dostał zgłoszenie SZ-…” [Content & Copy · niska]
- docs/koncepcja/design/v3/strefa/panel.html:553 - „Najpierw przejrzę listę” to pierwsza osoba → „Przejrzyj listę” [Content & Copy · niska]

#### docs/koncepcja/design/v3/strefa/dam-prace.html

- docs/koncepcja/design/v3/strefa/dam-prace.html:1183, :1200, :1258, :2522, :2559, :3205–3211 - Jedno kliknięcie od razu daje nieodwracalny skutek, bez potwierdzenia i bez cofnięcia: usunięcie konta, usunięcie i zamknięcie ogłoszenia, usunięcie szkicu. Tekst przy :2561 tak to opisuje: „Działa zawsze, jednym przyciskiem”. To samo dotyczy szkolenia.html:1769 („Zwróć 390,00 zł”), :686, :704, :1145, :1158, :1188 („Zrezygnuj”, miejsce przejmuje lista rezerwowa; obsługa :2248–2260) i panel.html:573 („Odbierz dostęp”). Dobry wzorzec jest w tej samej makiecie: „Odwołaj szkolenie” (szkolenia.html:1398–1418) → Usuń konto, Usuń ogłoszenie, Zwróć i Odbierz dostęp: `details` albo `<dialog>` z opisem skutku i drugim przyciskiem. Zamknij, Usuń szkic i Zrezygnuj: ok. 10 s na „Cofnij” w polu statusu [Navigation & State · wysoka]
- docs/koncepcja/design/v3/strefa/dam-prace.html:554, :1733, :2941, :3131–3132, :3160 - Z JS filtry działają bez zmiany adresu (`preventDefault`, bez `replaceState`). Przy wejściu strona czyta tylko `?zabieg`, więc adres z wersji bez JS (`?wojewodztwo=pomorskie&zawod=fryzjer`) pokazuje listę niefiltrowaną. Tak samo w szkolenia.html:369, :2240–2241 → w `applyFilters` `history.replaceState(null,'','?'+new URLSearchParams(new FormData(form))+'#oferty')`, a przy starcie wypełnić pola z `location.search` [Navigation & State · średnia]
- docs/koncepcja/design/v3/strefa/dam-prace.html:984, :1323, :1624, :2037, :2206, :2439 - Żaden formularz nie ostrzega przed utratą danych: opis ogłoszenia (200–5000 znaków) czy wiadomość przepadają po „Anuluj”, linku z menu albo zamknięciu karty. Tak samo w szkolenia.html:651, :857, :1808, :1946 i panel.html:446, :503 → flaga „dirty” na zdarzeniu `input`. Gdy jest ustawiona: `beforeunload` i potwierdzenie przy „Anuluj” albo zmianie widoku [Forms · średnia]
- docs/koncepcja/design/v3/strefa/dam-prace.html:116, :123, :200–201, :889 - Tytuły ogłoszeń od użytkowników się nie łamią: 85 znaków bez spacji przy 320 px daje szerokość 862 px, a h1 oferty rozpycha stronę także przy 1280 px (do 1806 px). To samo w szkolenia.html:62 i strefa.css:298 (`table.data`) → `overflow-wrap:anywhere` [Content Handling · niska]
- docs/koncepcja/design/v3/strefa/dam-prace.html:1690–1693 - Po h1 „Ogłoszenia „Szukam pracy”” od razu następuje h3 „Jak potwierdzamy firmę” → `strong.alert-title` `#t-sp-czeka` zamienić na h2 albo h3 na h2 [Accessibility · niska]
- docs/koncepcja/design/v3/strefa/dam-prace.html:91, :160, :236 - `summary` w `.filters`, `.disclose` i `.zab-grp` nie zmienia się po najechaniu [Hover & Interactive States · niska]
- docs/koncepcja/design/v3/strefa/dam-prace.html:1328, :1547, :1551 - Pola nie służące logowaniu (tytuł, płaca od–do) nie mają `autocomplete="off"`, choć część pól w tym formularzu go ma. Tak samo w szkolenia.html:1385, :1709, :1740, :1822, :1874, :1900, :1905, :1918, :1929 [Forms · niska]
- docs/koncepcja/design/v3/strefa/dam-prace.html:2415 - Placeholder „NIP obecnego pracodawcy” jest opisem, a nie wzorem → „np. 123-456-78-90…” [Forms · niska]
- docs/koncepcja/design/v3/strefa/dam-prace.html:3008 - Etykieta „Gotowe” w oknie zabiegów nie mówi, co się stanie → „Zapisz wybór zabiegów” [Content & Copy · niska]
- docs/koncepcja/design/v3/strefa/dam-prace.html:1042, :1200, :2522, :2559 - Komunikaty są w stronie biernej („Wiadomość została przekazana”, „Szkic … został usunięty”, „… zostało/zostały usunięte”) → strona czynna bez pierwszej osoby, np. „Pracodawca dostał wiadomość” [Content & Copy · niska]
- docs/koncepcja/design/v3/strefa/dam-prace.html:848, :2207, :2486 - „Mam konto” to pierwsza osoba. „Moje ogłoszenie” (:2486) i „Twoje ogłoszenie” (:2207) stoją obok siebie → „Masz konto?”, wszędzie „Twoje” [Content & Copy · niska]

#### docs/koncepcja/design/v3/strefa/szkolenia.html

- docs/koncepcja/design/v3/strefa/szkolenia.html:929, :2436 - Pole kodu pocztowego ma `inputmode="numeric"`, więc na iOS klawiatura nie ma „-”, a walidacja wymaga formatu 00-000. Zamówienia płatnego szkolenia nie da się złożyć bez wklejania. To samo pole jest w dam-prace.html:1390, tam bez walidacji → przed walidacją `replace(/\D/g,'')`, przyjąć 5 cyfr i wstawić myślnik automatycznie. Albo usunąć `inputmode` z pól kodu pocztowego [Forms · wysoka]
- docs/koncepcja/design/v3/strefa/szkolenia.html:589–605, :1382–1391, :2263–2284 - Błędy nie stoją przy polu. „Zgłoś nadużycie” przy pustym powodzie tylko oznacza pole i przenosi na nie fokus, bez tekstu, co poprawić. Błąd liczby miejsc jest pod przyciskiem, w `role=status`, bez powiązania z polem. W dam-prace.html:3252 pole „Do (zł)” ma `aria-invalid`, ale nie ma `aria-describedby` → `<p class="field-error">` przy polu i `setErr`, w dam-prace `aria-describedby="n-placa-err"` [Forms · średnia]
- docs/koncepcja/design/v3/strefa/szkolenia.html:2276–2283 - Przy wartości powyżej maksimum (np. 300) albo pustym polu (`cap-1` :1385, min 7, max 200) komunikat zawsze brzmi „Liczba miejsc nie może być mniejsza niż 7 (zapisani)”. Jest więc fałszywy → osobne komunikaty dla wartości poniżej minimum, powyżej maksimum i braku liczby, np. „Wpisz liczbę od 7 do 200” [Content & Copy · średnia]
- docs/koncepcja/design/v3/strefa/szkolenia.html:1838–1843 - Grupa radio „Adresaci” nie ma `fieldset` ani `legend`, więc czytnik czyta opcje bez nazwy grupy (WCAG 1.3.1). „Forma” i „Cena” w tym samym formularzu mają `fieldset` → `<fieldset class="field"><legend>Adresaci</legend>…</fieldset>` [Accessibility · średnia]
- docs/koncepcja/design/v3/strefa/szkolenia.html:2349, :2384 - Data i godzina są składane ręcznie. Data ma zera wiodące („03.12.2026”), a statyczny HTML pisze „3.12.2026” → `Intl.DateTimeFormat('pl-PL',…)` [Locale & i18n · niska]
- docs/koncepcja/design/v3/strefa/szkolenia.html:2483, :2487 - Kwoty są formatowane ręcznie (`toFixed(2).replace('.', ',')`), a w dam-prace.html:3244 regexem → `Intl.NumberFormat('pl-PL',{style:'currency',currency:'PLN',useGrouping:'always'})` [Locale & i18n · niska]

### 3.4 Adnotacje makiety (nie są elementami produkcyjnymi)

- narzedzia/makiety/opieka-medyczna/template.html (→ opieka-medyczna.html:2217, :2237) - Skrypt wstawia długie `.mock-note` do regionów live (`#m-nip-status` z `aria-live`, `#form-status` z `role=status`), więc czytnik czyta adnotację razem z komunikatem → w produkcji usunąć, w makiecie dać adnotację poza regionem live albo z `aria-hidden` [Accessibility · makieta]

### 3.5 Zgodne (✓ pass)

- **Wspólne bloki:**
  - przyciski z samą ikoną mają nazwy;
  - ikony dekoracyjne mają `aria-hidden`;
  - logo ma `alt` oraz `width` i `height`;
  - jest link pomijający;
  - `scroll-padding` obsługuje kotwice;
  - globalne `:focus-visible` z wariantem dla ciemnego tła;
  - nagłówek, pasek akcji i topbar Strefy nie zasłaniają fokusu (Tab i Shift+Tab przy 1280, 375 px i przy `reduce`);
  - menu „Ubezpieczenia” jest wzorcem disclosure;
  - szuflada i dymek obsługują Esc i wyjście fokusu;
  - pasek akcji ma `inert`, safe-area i obsługuje 200% tekstu;
  - `prefers-reduced-motion` jest respektowane;
  - nie ma `transition: all`, `outline:none` bez zastępstwa, `user-scalable=no` ani `maximum-scale`.
- **Strona główna:**
  - combobox wyszukiwarki, zakładki ARIA i dialog klauzuli obsługują klawiaturę;
  - formularz kontaktu ma `autocomplete`, typy pól, błędy przy polach i fokus na pierwszym błędzie;
  - `role=status` w kalkulatorach;
  - hero ma `fetchpriority=high` i preload;
  - przy 320–1280 px nie ma przewijania w poziomie (poza danymi od użytkownika).
- **OC i słownik:**
  - axe-core: 0 naruszeń przy 1280 i 375 px;
  - kotwice i aliasy (`#grupa-N`, dawne slugi, `#haslo-…`) działają pod nagłówkiem;
  - liczniki wyników w `aria-live`;
  - stany puste podają następny krok;
  - stan pól po powrocie jest odtwarzany przy starcie (`apply(true)`, `filtruj(false)`).
- **Produkty:**
  - fokus widoczny na wszystkich elementach `<main>`;
  - tabele mają `caption`, `scope` i przewijane regiony z nazwą;
  - formularz opieki ma `label`, `fieldset`, `autocomplete` i błędy z `aria-describedby`;
  - linki `target=_blank` mają `rel=noopener` i informację dla czytnika.
- **Strefa:**
  - szuflada polisy (`inert`, pętla Tab, Esc, powrót fokusu);
  - zakładki z roving tabindex;
  - licznik rezerwacji 15 min z `role="timer"` i komunikatami na 5 i 1 minutę (wzór dla logowania);
  - stany ładowania kończą się „…”;
  - natywne `<select>` mają jawne kolory;
  - nie ma przewijania w poziomie w 50 widokach przy 320 i 360 px;
  - „Odwołaj szkolenie” i odstąpienie od umowy mają dwa kroki.

## 4. Nie dotyczy

- **Hydration Safety** (`value`/`onChange`, daty server/client, `suppressHydrationWarning`): makiety to statyczny HTML bez SSR i hydracji. Odpowiednik w czystym JS to zgodność UI ze stanem pól, który przywraca przeglądarka. Jedyny błąd jest na stronie głównej (3.3). Słownik, OC i opieka odtwarzają stan przy starcie.
- **Deep-link all stateful UI (useState → nuqs):** oceniane jako „URL reflects state”.
- **Large lists: virtualize (`virtua`)**, **Large arrays `.map()`**: nie ma Reacta, więc oceniane jako `content-visibility`, tylko tam, gdzie pozycji jest ponad 50. Gdzie indziej jest ich najwyżej 34–57, w zwiniętych `details`.
- **Prefer uncontrolled inputs:** wszystkie pola są niekontrolowane, a obsługa `input` jest tania.
- **Media** (captions, kontrolki, autoplay powyżej 5 s, wyciszone pętle, wideo zamiast GIF, Safari H.264): na stronach nie ma mediów. Jedyny ruch bez przewijania to hero-zoom na stronie głównej. Trwa 3,6 s i wyłącza go `reduced-motion`.
- **SVG: transforms on `<g>`:** nie ma animacji wewnątrz SVG. Obracany jest cały `<svg>` szewronu, z poprawnym `transform-origin`.
- **Drag i gesty** (zaznaczanie tekstu, `inert`, alternatywy dla gestów): na stronach nie ma przeciągania ani gestów.
- **`color-scheme: dark`:** strony są tylko jasne (`color-scheme: only light`).
- **Native `<select>`:** na stronach publicznych nie ma selectów. W Strefie są spełnione (3.5).
- **Detect language via `Accept-Language`:** serwis jest jednojęzyczny (pl).
- **Title Case (Chicago):** obowiązuje polska norma. Naruszenia tej normy zgłoszono (opieka `data.py`, NNW).
- **`&` over „and”:** polskie „i” jest krótsze niż „&”.
- **Numerals for counts w nagłówkach i prozie:** polska norma pozwala pisać słownie liczebniki do dziesięciu. Odrzucone uwagi: nagłówki strony głównej („w dwie minuty”, „w trzech krokach”) oraz h2 oc-beauty.html:1348, odrzucony przy scalaniu dla spójności.
- **Below-fold images: `loading="lazy"`:** logo w stopce to ten sam plik co logo w nagłówku, już pobrany. Uwagę odrzucono w dwóch grupach.
- **Above-fold critical images w Strefie:** nad zgięciem jest tylko małe logo, a LCP to tekst. Strony produktów zgłoszono (3.2).
- **Dates/times `Intl.DateTimeFormat` na stronach publicznych:** skrypty nie formatują tam dat. Strefę zgłoszono (3.3).
- **Interactive elements need keyboard handlers:** strony używają wyłącznie natywnych elementów interaktywnych. Wyjątki, czyli dymek, zakładki i combobox, mają własną obsługę klawiszy.
- **`autoFocus`:** atrybutu nie ma nigdzie. Fokus programowy w dymku i w oknie zabiegów (tylko przy `pointer:fine`) jest uzasadniony. Wyjątek w opiece zgłoszono.
- **Destructive actions na stronach publicznych:** nie ma tam akcji niszczących. Wylogowanie wszędzie i cofnięcie zaproszenia w Strefie da się odwrócić, więc też ich nie dotyczy.
- **Flex/grid over JS measurement:** układ jest w CSS. JS mierzy tylko pozycję dymku, co jest uzasadnione.
- **Outline bez zastępstwa:** `.zab-sheet-head h2:focus{outline:none}` (dam-prace.html:264) dotyczy celu programowego fokusu z `tabindex=-1`, a nie elementu interaktywnego. Uwagę odrzucono.
- **Do decyzji redakcyjnej:** komunikaty systemowe Strefy są w pierwszej osobie liczby mnogiej („Wysłaliśmy kod”, „Wylogowaliśmy Cię”). To konwencja Strefy, sprzeczna z regułą „Second person”. Raport jej nie zgłasza pozycja po pozycji. Decyzję zapisać w `11`.

## 5. Proponowana kolejność poprawek

1. **Generatory – jedna poprawka naprawia wiele stron.**
   1. `slownik/gen_strona.py:622`: dodać klasę `dark` (wysoka, jedno słowo).
   2. Wspólny moduł typografii, np. `narzedzia/makiety/typografia.py`, z regułami `t()` z `gen_strona.py`, rozszerzonymi o grupy cyfr, „r.”, „poz.”, „nr”, „sp. z o.o.”, liczebnik z rzeczownikiem i półpauzę. Lookbehind zamiast grupy usuwa błąd z `build.py:377`. Moduł podpiąć w `gen_terminy.py` (dymki na wszystkich stronach, U+00A0), `gen_wspolne.py` (`PRODUKTY`), `gen_klauzula.py`, `gen_kalkulator_dane.py`, `gen_oc_beauty.py`, `oc_taryfa.py`, `gen_strefa_zabiegi.py` i `opieka-medyczna/build.py`, a w FAQ tylko w widocznym HTML. Usuwa to ok. 10 pozycji.
   3. `gen_wspolne.py`: progi w em i `--bp-container` w rem (średnia) oraz hover `.mega-all` i `data-biezacy`.
   4. `gen_terminy.py`: rola linku z `aria-haspopup`, `overscroll-behavior:contain`, odczyty przed zapisami.
   5. `opieka-medyczna/template.html` i `common.css`: pozycje z 3.1.
2. **Bazowy CSS i `<head>` (3.2).** Najpierw poprawić `tax-protect.html`, z którego słownik bierze szkielet przy regeneracji. Potem kopie na pozostałych stronach, `opieka-medyczna/common.css` i `strefa.css`. Kolejność:
   - safe-area i tekst 200% w hero (średnia);
   - preload tła hero (średnia);
   - hover linków i kontrast `.btn-ghost-dark`;
   - `touch-action`, `tap-highlight` i `overscroll-behavior`;
   - `theme-color`;
   - animacje kresek;
   - `.brand`;
   - skrypt wejść;
   - `translate="no"`;
   - fonty z `tnum` hostowane samodzielnie.

   Bazowy CSS jest dziś kopiowany ręcznie na 8 stron. Warto przenieść go do bloku generowanego przez `gen_wspolne.py`, żeby kolejne poprawki robić w jednym miejscu.
3. **Pozostałe wysokie w stronach.**
   - `makieta-v3.html`: przeliczenie na `pageshow`.
   - `strefa/logowanie.html`: licznik jako `role="timer"`.
   - `strefa/szkolenia.html`: normalizacja kodu pocztowego.
   - Strefa: potwierdzenie albo „Cofnij” dla akcji nieodwracalnych.
4. **Średnie.**
   - Strefa: `setErr` z regionem `role="alert"`, błędy przy polach i komunikat liczby miejsc, `fieldset` „Adresaci”, deep link zakładek panelu (link ze słownika), nazwy linków PDF, fokus po `disabled`, filtry w URL, ostrzeżenie przed utratą danych, fokus w menu konta.
   - Strona główna: przepełnienie przez dane od użytkownika, stan wysyłania formularza.
   - OC: `overflow-clip-margin` dla fokusu, fraza w URL.
   - Słownik: fraza i kategoria w URL.
   - Opieka: stan wysyłania formularza.
5. **Przełączniki zakładek w Ustawieniach salonu (preferencja widoku, 00 D44).** Przy dokończeniu `input.toggle` dodać `:hover` (zrobione 16.11.2026) i sprawdzić fokus w menu konta (rozdz. 2). Stary `.switch` poprawić albo usunąć.
6. **Niskie:** przy okazji edycji danego pliku. Treści (pierwsza osoba, strona bierna, liczebniki, placeholdery) najlepiej poprawić w jednej rundzie redakcyjnej dla wszystkich stron.
