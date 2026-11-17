# Generatory i kontrole makiet BeautyPolisa

Skrypty, które tworzą i sprawdzają bloki generowane w makietach (`docs/koncepcja/design/v3/`) i plikach
pomocniczych (`docs/koncepcja/snippets/`). Do 14.11.2026 leżały tylko w katalogu roboczym sesji; przeniesione
do repozytorium w kroku 0 planu „OC beauty po Aneksie nr 5” **bez zmiany logiki**. Zmieniło się tylko to:

- ścieżki bezwzględne do repozytorium i do katalogu sesji są liczone względem położenia skryptu
  (`Path(__file__).resolve().parents[n]`, w Node `path.resolve(__dirname, …)`), więc skrypty można uruchamiać z dowolnego katalogu;
- `gen_oc_beauty.py`, `opieka-medyczna/build.py` i `gen_klauzula.py` dostały tryb `--check` (wcześniej go nie miały;
  dla `gen_oc_beauty.py` zastępuje dawny suchy przebieg `kontrola/oc/gen_dry.py`);
- komentarze, które generatory wstawiają do stron (np. `<!-- GEN:faq (wygenerowane – … ) -->`), wskazują nowe ścieżki;
- zrzuty ekranu z kontroli trafiają do `kontrola/wyniki/` (poza gitem), a `axe-core` jest zależnością z `package.json`.

## Wymagania

- Python 3 (generatory: tylko biblioteka standardowa; `kontrola/slownik/e_static.py`: także `bs4` i `lxml`).
  Zawsze `python3 -I …` – skrypty same dodają swój katalog do `sys.path` tam, gdzie trzeba.
- Do kontroli w przeglądarce: Node.js ≥ 20 i `npm install` w tym katalogu (`axe-core` 4.10.2, `playwright` 1.63.0;
  `node_modules/` jest w `.gitignore`). Przeglądarka: `npx playwright install chromium`, jeśli jeszcze jej nie ma.
  Skrypty używają `chromium.launch()` bez opcji.

## Generatory

Ścieżki względem katalogu głównego repozytorium. Każdy generator podmienia wyłącznie treść między swoimi znacznikami
(idempotentnie); `slownik/gen_strona.py` i `opieka-medyczna/build.py` budują całą stronę.

| Skrypt | Źródło → wynik |
|---|---|
| `gen_kalkulator_dane.py` | `snippets/zabiegi-oc-beauty.json` (v2), `taryfa-oc-beauty.json`, `oc-skladka.js`, `klauzula-ochrona-prawna.json` → `design/v3/makieta-v3.html`: `gen:zabiegi-data` (dane wyszukiwarki: pozycje list nr 1 i 2 `{id, slug, nazwa, listy}` i ankiety `{id, slug, nazwa, ankieta: litera}`), `gen:taryfa-data` (taryfa bez `$comment`, `teksty_crm` i opisów źródeł `zrodlo`/`limit_zrodlo` – ścieżki kodu CRM nie trafiają do publicznego źródła strony; weryfikacja, runda 2), `gen:oc-skladka` (treść `oc-skladka.js`, globalny `OcSkladka`), `gen:taryfa` (tabela „Pełna taryfa OC” + nota, `oc_taryfa.py`), `gen:klauzula` (dialog klauzuli); pola kalkulatora `gen:kalk-rodzaje`, `gen:kalk-osoby`, `gen:kalk-sumy`, `gen:kalk-ankieta`, `gen:kalk-ankieta-info` i dokumenty w FAQ strony głównej `gen:faq-ankieta-dokumenty` (znaczniki w makiecie od kroku 4; bez znacznika `gen:kalk-rodzaje` – „tryb przejściowy” z komunikatem `uwaga: kalkulator OC w starym układzie`) |
| `gen_oc_beauty.py` (+ `gen_oc_beauty.szablon.html` tylko dla `--init` – szablon sprzed Aneksu nr 5, dziś kończy się błędem „brak znacznika GEN:taryfa”) | `zabiegi-oc-beauty.json` (v2) i `zabiegi-oc-beauty-wycofane.json`, `taryfa-oc-beauty.json`, `faq-oc-beauty.json`, `klauzula-ochrona-prawna.json`, `schema-produkt-oc-beauty.json`, `schema-home.json` → `design/v3/oc-beauty.html`: bloki `GEN:jsonld`, `GEN:zabiegi-skok`, `GEN:zabiegi` (sekcje `#lista-1`, `#lista-2`, `#ankieta`, `#podologia`; `<li id="<slug>">` / `<slug>-lista-2`, numery z PDF, aliasy dawnych kotwic `span.z-alias` bez `hidden`), `GEN:zabiegi-reguly`, `GEN:taryfa`, `GEN:klauzula`, `GEN:faq`, liczby w `data-gen="liczba-lista-1"`, `"liczba-lista-2"`, `"liczba-ankieta"`; zapisuje też `snippets/schema-faq-oc-beauty.json` (FAQPage = widoczne pytania); sprawdza meta description = opis WebPage |
| `gen_strefa_zabiegi.py` | `zabiegi-oc-beauty.json` (v2), `zabiegi-oc-beauty-wycofane.json` → `design/v3/strefa/dam-prace.html`: `gen:zabiegi-data` (`{listy, zabiegi, wycofane}`), 4 bloki `gen:zabiegi-checkboxy:*` (sekcje lista nr 1, lista nr 2, ankieta; pozycja z obu list w obu sekcjach z tym samym `value`; `data-lista`), treść `div.zab-tags` (wycofane id – nazwa z dopiskiem „pozycja wycofana z listy”, na końcu) |
| `gen_zabiegi_sql.py` | `zabiegi-oc-beauty.json` (v2), `zabiegi-oc-beauty-wycofane.json` → `snippets/strefa-klienta.sql`: blok `gen:zabiegi-ids` (funkcja `zabiegi_ids()`: 100 aktywnych, 31 wycofanych; każde wycofane id musi mieć wpis w archiwum – inaczej błąd) |
| `gen_klauzula.py JSON PLIK [WCIĘCIE]` | `klauzula-ochrona-prawna.json` → blok `gen:klauzula` w podanym pliku; dziś `design/v3/strefa/panel.html` (wcięcie domyślne) |
| `gen_wspolne.py` | lista `PRODUKTY` w skrypcie → menu „Ubezpieczenia”, szuflada, pasek akcji na telefonie, wspólne CSS/JS (`gen:menu-produkty`, `gen:menu-mobilne`, `gen:pasek-akcji`, `gen:wspolne-css`, `gen:wspolne-js`) na 6 stronach publicznych, `opieka-medyczna.html` i `slownik.html` (od 15.11.2026 opieka medyczna ma w `PRODUKTY` plik `opieka-medyczna.html` i opis ceny „Cenę przygotuje doradca” – bez kwot; akcja paska na tej stronie → `#zapytanie`) |
| `opieka-medyczna/build.py` (+ `data.py`, `template.html`, `common.css`, `common.js`) | → cała `design/v3/opieka-medyczna.html` i `snippets/schema-produkt-opieka-medyczna.json`; bloki wspólne bierze z `gen_wspolne.py` (wstawia je po `nbsp()`, więc są identyczne jak u `gen_wspolne.py`), stopkę – z `nnw-dzieci.html` (bieżąca pozycja „Opieka medyczna”; dawny `footer.html` usunięty 15.11.2026 – rozjechał się z oryginałem), na końcu oznacza pojęcia funkcją `przetworz()` z `slownik/gen_terminy.py` – wynik jest od razu stroną końcową |
| `utrata-dochodu/gen_faq.py` | lista pytań w skrypcie (przeniesiona 17.11.2026 z dawnego skryptu budującego stronę z katalogu roboczego sesji) → `design/v3/utrata-dochodu.html`: blok `GEN:faq` (widoczne `<details>`, tekst przez `typografia.html()`) i węzeł `FAQPage` w bloku `GEN:jsonld` (bez twardych spacji i znaczników; pozostałe węzły JSON-LD bez zmian – asercja, że `json.dumps(indent=1)` odtwarza blok znak w znak); brzmienie bez pierwszej osoby i strony biernej (raport 16, 3.3); zakazane zwroty („podajemy”, „nie zostały zgłoszone”) – asercja |
| `slownik/gen_strona.py` | `snippets/slownik.json` (+ szkielet z `tax-protect.html`, bloki z `gen_wspolne.py`) → cała `design/v3/slownik.html`; pole `dawne_id` hasła → pusta kotwica `span.haslo-alias#haslo-<dawne_id>` bez `hidden` (np. `#haslo-grupa-ryzyka` → hasło „Rodzaj działalności (OC dla branży beauty)”, 00 D43) |
| `slownik/gen_terminy.py` | `snippets/slownik.json` → oznaczenia pojęć (`a.bp-termin`), bloki `gen:slownik-css` i `gen:slownik-js` na 11 stronach (lista `STRONY`; od 15.11.2026 także `opieka-medyczna.html` i `strefa/szkolenia.html`) i link „Słownik pojęć” w stopce / szufladzie; pomija bloki `gen:*`/`GEN:*`, nazwy zabiegów, klauzulę i przykłady `data-przyklad="tak"` (stawki opieki medycznej); klasy wykluczone z oznaczania obejmują listy zabiegów po Aneksie nr 5 (`zlista`, `z-nr`, `z-inna`, `z-alias`, `ankieta-lista`, `zab-groups`, `zab-tags` – uwaga K3); `INNE_ZNACZENIE` – hasła, których słowo stoi na danej stronie w innym znaczeniu (opieka: „świadczenia medyczne”; szkolenia: prowizja portalu, reklamacja u organizatora) |
| `check_zabiegi_1do1.py [--bez-pdf]` | kontrola (nic nie zapisuje): JSON v2 i archiwum (`zabiegi_model.py`), `#zabiegi-data` w `makieta-v3.html`, listy na `oc-beauty.html` (kolejność, numery/`value`, brzmienie, kotwice, odnośniki „także na liście nr …”, aliasy bez `hidden`, brak `a.bp-termin` w sekcjach list), dane i checkboxy w `dam-prace.html`, `zabiegi_ids()` w SQL; na końcu uruchamia `check_zabiegi_pdf.py` (JSON = PDF i CRM) |

`dane/ankieta.txt` = `pdftotext -layout AnkietaBPEH.pdf` (pusty formularz ankiety z katalogu głównego repozytorium). Kopia PDF w portalu: `design/v3/dokumenty/oc-beauty/ankieta-oceny-ryzyka-wa50-003353-24-a-sprzed-aneksu-5.pdf` (nazwa od 15.11.2026, bez dawnej numeracji grup; treść i sha256 bez zmian).

Moduł wspólny wszystkich generatorów treści (od 17.11.2026, raport 16, rozdz. 3.1 i 5): `typografia.py` – polska typografia
(twarde spacje po jednoliterowych wyrazach – także kilku z rzędu, w grupach cyfr, przed „zł”, „r.”, „osób”, „pozycji”, „miesięcy”, po „nr”,
„poz.”, „art.”, „NIP”, „REGON”, w „sp. z o.o.”, w nazwach marek, przed półpauzą-myślnikiem; „ — ” → „ – ”, „...” → „…”, "…" → „…”);
`html()` dla HTML (`&nbsp;`, znaczniki i atrybuty bez zmian), `esc()`, `tekst()` (U+00A0 – dane wstawiane przez `textContent`),
`JS` (funkcja `bpTypografia` dla skryptów stron), `marki()` (`<span translate="no">` na nazwach marek), `porownaj()` (kontrole: twarda
spacja = spacja, pauza = półpauza). Używają go: `gen_wspolne.py` (`PRODUKTY`), `slownik/gen_terminy.py` (dymki), `slownik/gen_strona.py`
(`t()`), `gen_klauzula.py`, `gen_kalkulator_dane.py` (klauzula, ankieta a–h, legendy, dokumenty), `gen_oc_beauty.py` (skok, listy, reguły,
klauzula, FAQ – w JSON-LD bez twardych spacji), `oc_taryfa.py` (tabela taryfy, nota), `gen_strefa_zabiegi.py` (pola, sekcje, chipy; JS
w bloku `gen:zabiegi-data`) i `opieka-medyczna/build.py` (cała treść strony, także FAQ). Brzmienie list zabiegów, klauzuli i zdań CRM
się nie zmienia. `python3 -I typografia.py` – przykłady i idempotencja.

Moduły wspólne generatorów OC (krok 3 planu): `zabiegi_model.py` (odczyt i walidacja listy v2), `oc_taryfa.py` (formaty kwot – tabele bez groszy,
kwota z wyliczenia z groszami, sumy „200 tys. zł”; reguła kategorii D45 i jej opis słowami z kontrolą na 63 połączeniach rodzajów, fixture i grupach `regula_kategorii`; tabela
„Pełna taryfa OC” i nota – jedna dla obu stron; `python3 -I oc_taryfa.py` – kontrola i podgląd), `oc_frazy.py` (zakazane frazy z planu 6.8
z poprawkami K7: sprawdzane tylko w blokach generatorów OC, wyjątki – dawne brzmienia ankiety, nazwy z archiwum wycofanych, „podgrupa N”,
zwroty przeczące; `python3 -I oc_frazy.py PLIK…` – raport dla całych plików). FAQ strony OC: `snippets/faq-oc-beauty.json` (pola `{…}`
wypełnia `gen_oc_beauty.py` z danych; zdania CRM z `taryfa-oc-beauty.json` → `teksty_crm`).

### Dane OC po Aneksie nr 5 (kroki 1–2 planu, 14.11.2026)

Nowe źródła w `docs/koncepcja/snippets/`. Od kroku 3 (15.11.2026) wszystkie generatory OC, `check_zabiegi_1do1.py` i kontrole
`kontrola/dam-prace/*` czytają wersję 2; `dane/ankieta.txt` i `bp-app.js` nie są już źródłem żadnej kontroli.

| Plik | Co to jest |
|---|---|
| `snippets/taryfa-oc-beauty.json` | stałe programu 1:1 z CRM: sumy, 3 kategorie ze stawkami, dopłata 6–8 osób, ochrona prawna (92 zł, limit ze źródłem), 6 rodzajów działalności, 3 przedziały osób, pytania APK, powody wyceny indywidualnej, komunikaty braków, zdania CRM przytaczane dosłownie (`teksty_crm`); od 16.11.2026 `regula_kategorii` – grupy rodzajów działalności do reguły kategorii D45 (lista nr 1, lista nr 2, zawsze pełna; odstępstwo od CRM opisane w `$comment`) |
| `snippets/oc-skladka.js` | czysta funkcja wyceny (`kategoria(rodzaje, T)` – reguła D45 na grupach `T.regula_kategorii`, `skladkaOc`) i formaty portalu (`formatKwota` – zawsze z groszami, spacje twarde; `formatKwotaCalkowita`; `formatSuma` – „200 tys. zł”); w przeglądarce globalny `OcSkladka`, w Node moduł CommonJS; wynik `opisCrm` = opis wyceny w formacie CRM (w połączeniach D45 – taki, jaki CRM pokaże po zmianie reguły) |
| `snippets/zabiegi-oc-beauty.json` (wersja 2) | listy nr 1 (49) i nr 2 (63) z PDF Aneksu nr 5, ankieta a–h (8) z CRM, podologia bez pozycji; rekord = zabieg z `pozycje[]`; 100 aktywnych id, 18 aliasów `dawne_slugi` |
| `snippets/zabiegi-oc-beauty-wycofane.json` | archiwum 31 wycofanych pozycji (g3-01…g3-31): id, slug, nazwa – do starych ogłoszeń i aliasów kotwic `#podologia` |
| `snippets/zabiegi-oc-beauty-propozycje.json` | bez zmiany treści propozycji; oznaczenia względem wersji 2: `nazwa_v2`, `wycofane`, `odwolania_wycofane` i dopisek w `$comment` |

| Skrypt | Co robi |
|---|---|
| `zabiegi_model.py` | wspólny odczyt i walidacja wersji 2 (pola, id, slugi, numeracja list, kolejność, kotwice bez kolizji, archiwum); `python3 -I zabiegi_model.py` – walidacja i podsumowanie |
| `crm_tekst.py` | odczyt stałych z `crmaura/src/lib/renewals/program.ts` jako tekstu (bez uruchamiania kodu CRM); katalog CRM: `--crm`, `CRMAURA_DIR` albo `<katalog nadrzędny repozytorium>/aurabroker/crmaura` |
| `migruj_zabiegi_v2.py [--check]` | jednorazowa migracja v1 (z gita, commit `687654f`) + PDF + CRM → plik v2 i archiwum; `--check` odtwarza wynik i porównuje z plikami (wymaga CRM) |
| `check_zabiegi_pdf.py [--crm K] [--wymagaj-crm]` | JSON ↔ PDF list (nagłówki, brzmienie co do znaku, numery, tylko półpauza U+2013, sha256 = `dokumenty-produktowe.json`), PDF ankiety (dawne brzmienia), CRM (`ZABIEGI_LISTA_1/2`, `ZABIEGI_ANKIETA`, `_DAWNE`, `_PODSTAWA`, `ZABIEGI_LISTY`), liczby z planu; bez CRM część CRM pominięta |
| `check_zgodnosc_crm.py [--crm K]` | taryfa i reguła = CRM: stałe, treść `kategoriaZRodzajow`/`skladkaProgramu`/`wycenaNowej`/formatów = wzorzec w skrypcie, powody i komunikaty, `teksty_crm` dosłownie w komponentach CRM; fixture przeliczony niezależnie (Decimal) – 44 przypadki jak CRM + 5 `tylko_portal`, 64 kombinacje, 36 kwot; odstępstwo D45 (00): różnicę kategorii z CRM przyjmuje tylko w 9 połączeniach rodzajów D45 i tylko w przypadkach / kombinacjach z polem `odstepstwo_D45` (= wynik CRM), każdą wypisuje (`ODSTĘPSTWO D45: …`); kod 2 bez CRM |
| `kontrola/check_oc_spojnosc.py [--snippets \| --dokumenty] [-v]` | spójność treści OC po Aneksie nr 5 (plan 6.7–6.8, uwagi K7, K10, K12, K14, K16, K17; nic nie zapisuje): zakazane frazy w tekstach OC w `snippets/` (wszystkie z `oc_frazy.py`) oraz frazy OC w SQL i w dokumentach 00, 02, 04, 05, 06, 10, 11, 12, 13 (README, 00-braki, dokumenty-produktowe), 14 – słowa ogólne tylko w połączeniu ze składką/wariantem, poza cudzysłowem; wyjątki tylko dla opisów stanu sprzed D43 (fragment z „D43” i słowem o dawnym stanie albo sekcja z `<!-- oc-spojnosc: historyczne -->`); liczby 49 / 63 / 8 / 20, stawki i reguła kategorii w `llms.txt`, „Dla kogo” (decyzja 14.11.2026), FAQ = `faq-oc-beauty.json`, `AggregateOffer`, hasła słownika, enumy `lead-schema.ts` i CHECK-i SQL = taryfa, kopie `lead-schema.ts`/`schema.sql` w 02, D43 i Q1–Q13 w 00; cytaty CRM (K12 – pierwsze zdanie; tekst ze zdaniem „zabieg nie zmienia składki” – także zdanie CRM, runda 2; K16, opis ochrony prawnej) i przykłady zabiegów tylko dosłownie (K14) |

### Kolejność uruchamiania

Po zmianie danych w `snippets/`:

```bash
python3 -I narzedzia/makiety/gen_kalkulator_dane.py
python3 -I narzedzia/makiety/gen_oc_beauty.py
python3 -I narzedzia/makiety/gen_strefa_zabiegi.py
python3 -I narzedzia/makiety/gen_zabiegi_sql.py
python3 -I narzedzia/makiety/gen_klauzula.py docs/koncepcja/snippets/klauzula-ochrona-prawna.json docs/koncepcja/design/v3/strefa/panel.html
python3 -I narzedzia/makiety/gen_wspolne.py
python3 -I narzedzia/makiety/opieka-medyczna/build.py      # po każdej zmianie gen_wspolne.py
python3 -I narzedzia/makiety/slownik/gen_strona.py          # po każdej zmianie gen_wspolne.py albo slownik.json
python3 -I narzedzia/makiety/utrata-dochodu/gen_faq.py      # FAQ utraty dochodu (przed gen_terminy.py)
python3 -I narzedzia/makiety/slownik/gen_terminy.py         # na końcu: po każdej zmianie treści stron albo slownik.json
python3 -I narzedzia/makiety/check_zabiegi_1do1.py
```

Na końcu przebudowa paczki podglądu: `narzedzia/podglad-cloudflare/README.md`.

Poprawki z raportów 15 i 16 we wspólnych wzorcach i generatorach (17.11.2026): `gen_wspolne.py` – progi belka/szuflada w em
(`75em`, JS `matchMedia('(min-width:75em)')`), hover „Wszystkie ubezpieczenia” i przycisku z `data-biezacy`, `PRODUKTY` przez
`typografia.py` z `translate="no"`, NNW „za osobę” (Z40), pasek akcji chowany też nad `form#calc`, `.zsearch`, `#spec-form` (Z22),
szuflada < 768 px na cały ekran z etykietą „Zamknij” (Z41), a w bloku `gen:wspolne-css` wzorce bazowego CSS stron (rozdz. 3.2: safe-area,
`touch-action`, podświetlenie tapnięcia, `overscroll-behavior`, hover linków, `.btn-ghost-dark`, kreski na `transform`, rama hero bez
`clip-path`, długie listy bez animacji `block-size`, `.brand`, hero przy 200%; Z5, Z15, Z16, Z18, Z27) – blok stoi na końcu `<head>`, więc
nadpisuje ręczne kopie bazowego CSS. `slownik/gen_terminy.py` – pojęcie zostaje linkiem (`aria-haspopup="dialog"`, bez `role="button"`),
`overscroll-behavior:contain` w bazie dymku, położenie liczone po odczytach. `slownik/gen_strona.py` – karta końcowa `end-card dark` (Z28),
fraza i kategoria w adresie (`?q=&kategoria=`), `overflow-wrap:anywhere` w liczniku i stanie pustym, `content-visibility` liter, cele
dotyku 44 px (Z4), placeholder z „…”, teksty bez pierwszej osoby; `slownik.json` – „w 4 krokach”, „3 warianty”, „którym Aura Expert
przekazuje dane”. `gen_strefa_zabiegi.py` – `.zab-grp{content-visibility:auto}` w `dam-prace.html`. `opieka-medyczna/` – stan wysyłania
i błąd sieci (`?symulacja=blad-wysylki`), `beforeunload`, `#form-pick` stale w DOM, kwoty przez `Intl.NumberFormat`, stan w adresie
(`?zespol=&zakres=&porownaj=&q=`), `content:"✓" / ""`, łamanie długich zapytań, `spellcheck="false"`, fokus po podpowiedzi tylko przy
myszy, specjalności małą literą, „NNW dla dzieci” (Z32), jedna akcja pod cennikiem i bez linku w otwarciu (Z34), adnotacje makiety
w regionach live z `aria-hidden`. Strony pisane ręcznie (poza generatorami): `<head>` z `theme-color` #F7F3EC (Strefa #EDE5D8),
`og:image` (`img/og-beautypolisa.jpg`, 1200×630), `twitter:card`, ikoną (`img/ikona-32.png`, `img/apple-touch-icon.png`),
`data-type="service"`, `meta page-type` / `site-kind` (Z24); logo `img/logo-beautypolisa-320.png` (Z25); preload i `bg-on` tła hero;
`--bp-container: 77.5rem`; skrypt wejść – odczyty przed zapisami; bez dryfu cyfr i paralaksy hero (Z19); stopka z twardymi spacjami
i `translate="no"`; FAQ z twardymi spacjami (tax, NNW, ERGO; JSON-LD bez nich). `strefa/strefa.css` – wzorce 3.2 i uwagi 3.3 do arkusza
(fokus w menu konta, hover, `.switch` z gałką na `transform`, szuflada menu bez przewijania strony, długie dane, `.with-prefix`).
Uruchomione wszystkie generatory w kolejności z tej sekcji; wszystkie `--check` → `OK`; kontrole porównujące brzmienie
(`check_zabiegi_1do1.py`, `oc/cmp_klauzula.py`, `oc/t_func.js`, `oc/test_zab.js`, `dam-prace/cmp_data.py`) traktują twardą spację jak spację.

Strony publiczne po raportach 15 i 16 (17.11.2026, krok „strony publiczne”): `gen_wspolne.py` (blok `gen:wspolne-css`) – pierwszy ekran
podstron `.page-hero` (Z1, Z2, Z3, Z7, Z29: od 48em hero = 1 ekran, panel pośrodku ≥ 24 px nad dolną krawędzią okna; od 64em panel w dwóch
kolumnach `.hero-copy` / `.hero-aside` z liczbami; na telefonie ciaśniejszy panel i okruszki „‹ rodzic”), skala nagłówków (Z37: H2 =
`--text-h2`, H3 = `--text-h3` poza kafelkiem produktu, H4 = `--text-serif-md`; tokeny H1 36–80 px i H2 34–54 px w `tokens-v3.css` i kopiach
`:root`), tafle do obu linii kontenera (Z12), blok sekcji zamykającej `.zamkniecie-blok` (Z8). `opieka-medyczna/template.html` i
`slownik/gen_strona.py` – ta sama struktura hero; opieka: sekcja zamykająca, „Ważne warunki” (Z36). `gen_oc_beauty.py` – opis strony
„Oblicz składkę.” (Z33). `gen_kalkulator_dane.py` – asercja opisu ochrony prawnej z `np.&nbsp;w`. Strony pisane ręcznie: treść `<main>`
przez `typografia.html()` (bez bloków `gen:`/`GEN:`); strona główna – przeliczenie kalkulatorów i formularza na `pageshow`, odpowiedzi
kalkulatorów i zakładka w adresie, komunikat braku przy polu, stan wysyłania i błąd sieci formularza (`?symulacja=blad-wysylki`),
`beforeunload`, jeden formater kwot, pasek szkody i pytania w jednej sekcji, „Na otwarcie” jako osobna sekcja, Z11, Z14, Z16, Z20, Z21;
OC i Tax – droga do polisy w 3 krokach jak na stronie głównej (Z30); OC – fraza wyszukiwania w adresie (`?q=`); ERGO – nazwa jak w menu (Z32),
dwie akcje w hero (Z6), podział sekcji „Dla salonu” (Z9); karta opieki medycznej w „Inne ubezpieczenia” (Z35). Nowe kontrole:
`kontrola/strony/t_glowna_stan.js` (pageshow, adres, braki przy polu, wysyłka) i `kontrola/strony/t_axe_strony.js` (9 stron: axe 320/1280,
przewijanie w poziomie 320–1440, Z1, Z2, Z3, Z29, Z37). Poprawione kontrole: `oc/t_kalkulator.js` (nazwa taryfy z twardymi spacjami),
`oc/test_zab.js` i `oc/calc_search_check.js` (nowe brzmienia: „Zabiegu „…” nie ma…”, „Pokaż treść klauzuli”).

Strefa Klienta po raporcie 16 (17.11.2026, rozdz. 3.3 – `strefa/logowanie.html`, `panel.html`, `dam-prace.html`, `szkolenia.html`;
zmiany ręczne poza blokami `gen:`): nowy wspólny skrypt `strefa/strefa.js` (`window.bpStrefa`, ładowany przed skryptem strony na
czterech stronach) – błąd przy polu (`setErr`: `.field-error`, `aria-invalid`, `aria-describedby`; Enter w polu z fokusem – ogłoszenie
w `role="alert"`), jedno ogłoszenie w regionie sr-only, blokada po akcji przez `aria-disabled` zamiast `disabled` (fokus zostaje),
potwierdzenie akcji nieodwracalnych w `details.mini` (opis skutku, przycisk wykonania, „Anuluj”, Esc oddaje fokus; działa bez JS),
„Cofnij” przez 10 s dla akcji odwracalnych (czas stoi przy fokusie i kursorze), ostrzeżenie przed utratą danych
(`form[data-niezapisane]`, `beforeunload`, potwierdzenie przy „Anuluj” i zmianie ekranu), formaty `Intl` (kwoty, daty, godziny)
i stała `NB`. Na stronach: licznik ponownej wysyłki kodu `role="timer"` z `aria-live="off"` (ogłoszenie startu i końca), komunikaty
z następnym krokiem, „6 cyfr”, „Zaloguj się” / „Potwierdź kod”, strona czynna i druga osoba („Masz konto?”, „Twoje ogłoszenie”,
„Przejrzyj listę”), placeholdery z „…”, `spellcheck="false"` i `autocomplete="off"`; panel – kotwice `#p-szkody` / `#p-archiwum`
otwierają właściwą zakładkę, adres po kliknięciu zakładki, „Pobieranie…” bez kasowania kontekstu sr-only, „Zarządzaj zespołem”;
„Dam pracę” i szkolenia – filtry w adresie (zapis i odczyt, inne parametry zostają), błędy widełek płacy i liczby miejsc przy polach
(3 komunikaty), „Zgłoś nadużycie” z tekstem błędu, kod pocztowy z klawiatury numerycznej (5 cyfr bez myślnika → 00-000), `fieldset` „Adresaci”, h2 po h1,
„Zapisz wybór zabiegów”, łamanie długich tytułów od użytkownika. Kontrola: `kontrola/strefa/potwierdzenia.js`; `zakladki.js` bez zmian
(560 asercji `OK`). Podgląd: `narzedzia/podglad-cloudflare/build.py` kopiuje `strefa/strefa.js` (od integracji 17.11.2026).

Integracja 17.11.2026 („dokończ” – po równoległych zmianach generatorów, stron publicznych i Strefy): wszystkie generatory uruchomione
w kolejności z tej sekcji – żaden plik się nie zmienił; wszystkie `--check` → `OK`. Poprawione rozjazdy między krokami:
`gen_strefa_zabiegi.py` – „i&nbsp;N innych” na kartach ogłoszeń przez `typografia.esc()` (tak samo `moreLabel()` w skrypcie
`dam-prace.html` – stała `NBSP`); twarde spacje w szufladzie `grupowe-ergo.html` („Dla Ciebie i&nbsp;rodziny”) i w opisie linku
zewnętrznego `nnw-dzieci.html`; paczka podglądu – `strefa/strefa.js` w `build.py`, typ `image/jpeg` w `gen_assets.py` i reguła
`Data` dla `*.jpg` w `wrangler.jsonc` (obraz udostępniania z Z24; bez nich `gen_assets.py` kończył się błędem `KeyError: '.jpg'`).
Po zmianach: `gen_strefa_zabiegi.py` (zapis), wszystkie `--check` → `OK`, pełny zestaw kontroli z rozdz. „Kontrole” – bez błędów.

Weryfikacja, runda 1 (17.11.2026, „dokończ”): `typografia.py` – „nr” także przed symbolem z wielkiej litery („nr&nbsp;WA50/003353/24/A”;
też w wersji JS `bpTypografia`), „dniach” i „miesiącach” po liczbie; `oc_taryfa.py` – podpis tabeli taryfy przez `ty.html()`
(„ERGO&nbsp;Hestią&nbsp;–”); `gen_kalkulator_dane.py` – zdanie „Te zabiegi wymagają ankiety ERGO&nbsp;Hestii” przez `ty.html()`, przykłady
na kaflach „Dla kogo” rozdzielane średnikiem; `slownik/gen_strona.py` – cała treść `<main>` przez `typografia.html()`, litery indeksu A–Z
bez haseł w kolorze taupe (kontrast ≥ 4,5:1, dawniej 2,21:1) z przerywanym obrysem; nowy `utrata-dochodu/gen_faq.py` (FAQ utraty
dochodu z typografią i brzmieniem z raportu 16); `kontrola/check_oc_spojnosc.py` – kontrola reguły D45 uogólniona (`sprawdz_d45()`:
każda para rodzaju z listy nr 1 i z listy nr 2 w dowolnej kolejności, spójniki „z”, „razem z”, „i”, „oraz”, „+”; 4 zwroty sprzed D45;
także dokumenty 00–14, `13-przeniesienie-formularzy/*`, `do-crm/*` z pominięciem zdań o CRM i odstępstwie) – wykrywa mutacje M1–M10
z weryfikacji i dawny podpis z 06; `kontrola/oc/t_przewodnik.js` – ogłoszenie kroku przy szybkiej zmianie wyniku zaraz po zmianie
kroku, kafle przełącznika ≥ 104 px poniżej 480 px; `kontrola/strefa/potwierdzenia.js` – `.table-wrap` bez przewijania w poziomie
i axe we wszystkich zakładkach ekranów przy 320 i 1280 px, położenie „Cofnij” w oknie (szkolenia `#zapisano`, 4 rozmiary okna),
`aria-describedby` przycisku ponownej wysyłki kodu, „Zapisz szkic” po edycji. Strefa (ręcznie, poza blokami `gen:`): `strefa.css` – znaczki
statusu łamią się w tabelach `.stack`, poniżej 420 px etykieta nad wartością, obrys fokusu pól daty przy `:focus-within`; `.table-wrap`
wszystkich tabel jako region z fokusem (`tabindex="0"`, `role="region"`, `aria-label`), a `strefa.js` zdejmuje `tabindex`, gdy tabela się
mieści (ResizeObserver); „Cofnij” – fokus bez przewijania, położenie po wpisaniu statusu; `details.mini` – akapit skutku w `aria-describedby`
przycisku wykonania, „Anuluj” we wszystkich potwierdzeniach; `#sa-nip` bez `inputmode="numeric"` (NIP-y po wierszu, przecinku albo średniku);
licznik kodu bez `aria-describedby` po odliczaniu; twarde spacje w tekstach składanych w JS. Uruchomione wszystkie generatory w kolejności
z tej sekcji; wszystkie `--check` → `OK`; pełny zestaw kontroli z rozdz. „Kontrole” i testy SQL (`narzedzia/sql-testy/uruchom.sh`) – bez błędów.

Weryfikacja, runda 2 (17.11.2026, „dokończ”): `typografia.py` – twarda spacja po wyrazie jednoliterowym także wtedy, gdy zaraz po nim zaczyna
się znacznik elementu liniowego („w&nbsp;<a href=…>”, „razem z&nbsp;<a class="bp-termin">”; przykłady w autoteście), treść `<main>` stron
Tax i NNW przepuszczona ponownie; `gen_wspolne.py` (blok `gen:wspolne-css` / `gen:wspolne-js`) – **Z10** rytm sekcji 1 albo 2 ekrany od
64em × 37.5em (skrypt mierzy treść przy przyciętym `padding-block`, ustawia `data-ekrany`; poza hero i sekcjami K6), **Z8** sekcja zamykająca
`#zamkniecie` osobno od pytań (podstrony; opieka przez `template.html`), **Z37** H1 podstron tokenem `--text-h1-podstrona` (bez lokalnych
rozmiarów w CSS stron i w `opieka-medyczna/common.css`), **Z38** jedna karta pełna i jedna notka (tokeny `--bp-karta-*`, `--bp-notka-*`),
**Z39** jeden chip (`.zjump a`, `.sl-az a`, `.spec-quick button`), jeden link-akcja (`.link-lux` bez wersalików i kreski) i tokeny
podkreślenia linków `--bp-link-podkreslenie` / `-ciemne` (także w `tokens-v3.css` i DESIGN.md); `opieka-medyczna/template.html` – akcje
kontaktu „Zapytaj doradcę” z tematem w sr-only (Z33), twarde spacje w tekstach składanych w JS (wyszukiwarka specjalizacji, błędy pól,
komunikaty wysyłki), bez `--drift` (`common.css`); `slownik.json` – „6-⁠cyfrowy kod”, nazwy haseł „(OC dla branży beauty)”, forma neutralna
(„samodzielnie”, „z własnych środków”); `kontrola/check_oc_spojnosc.py` – formy eliptyczne reguły D45 („gabinet kosmetyczny
z kosmetologicznym”, „salon masażu i tatuażu”), zdanie z rozstrzygnięciem („rozstrzygnięte”, „(a) nie”) nie jest opisem CRM bez „D45” albo
„dziś”, test mutacyjny `MUTACJE_D45` (m.in. dawne zdanie z 03, pkt 3). Strony ręczne: ERGO w 7 sekcjach produktowych (Z9), kalkulator OC od
1200 px ciaśniej (Z9), komunikat profilu „Dla kogo” z numerem kroku, kwota w przełączniku OC / Tax < 480 px `1.05rem`, „Wyślij zapytanie”,
twarde spacje w wyszukiwarce zabiegów (strona główna) i filtrze list (OC), bez `--drift`. Strefa (ręcznie): `strefa.js` – po akcji
odwracalnej w oknie jest komunikat statusu i cały pasek „Cofnij” (`dolPaska()`), potwierdzenie w komórce akcji tabeli jako panel pod
wierszem (`tr.mini-pod`, tabela nie rośnie w poziomie); `strefa.css` – „Osoby i zaproszenia” w układzie `.stack` według szerokości
obszaru (`.table-wrap.cq`, `@container tabela`); `panel.html` – przy wejściu z `#p-szkody` / `#p-archiwum` rząd zakładek pod paskiem;
`logowanie.html` – fokus zostaje na „Wyślij kod ponownie” (SMS), jedno ogłoszenie; `szkolenia.html` – „Anuluj” i `aria-describedby`
w potwierdzeniach zwrotu, nazwa „Cofnij: rezygnacja z zapisu na „…””; `dam-prace.html` – stany puste filtrów przez `bpTypografia`.
Kontrole: `strony/t_axe_strony.js` (Z8–Z10 przy 1440×900 i 1280×900, H1 podstron), `strefa/potwierdzenia.js` (status i „Cofnij” w oknie –
dam-prace i szkolenia przy 320/390/768/1280 px, świeże wejście `#p-szkody` / `#p-archiwum` przy 5 szerokościach, SMS – jedno
ogłoszenie, „Anuluj” i opis skutku we wszystkich potwierdzeniach akcji nieodwracalnych). Odłożone zgodnie z rozdz. 7 raportu 15: Z13 i Z17
(zdjęcia, tekstury – po K2), Z23 poza „Na otwarciem” (pełne `main > section` w scenie marmuru wymaga tła dzielonego na sekcje bez szwu – Z17,
po K2), Z26 (notki makiety – przed publikacją).

### `--check`

Każdy generator przyjmuje `--check`: buduje wynik w pamięci, porównuje z plikiem i **niczego nie zapisuje**. Kod wyjścia 0 –
pliki aktualne (komunikat `OK`, „Bez zmian”, „slownik.html aktualny”), 1 – różnica („RÓŻNICA – uruchom bez --check”;
`gen_oc_beauty.py` wypisuje też do 40 linii różnicy). Asercje generatora (np. liczba pozycji listy, klauzula słowo w słowo,
zakazane frazy) działają także w trybie `--check`. Wszystkie naraz:

```bash
for g in gen_kalkulator_dane gen_oc_beauty gen_strefa_zabiegi gen_zabiegi_sql gen_wspolne opieka-medyczna/build slownik/gen_strona utrata-dochodu/gen_faq slownik/gen_terminy; do
  python3 -I narzedzia/makiety/$g.py --check || echo "!! $g"
done
python3 -I narzedzia/makiety/gen_klauzula.py docs/koncepcja/snippets/klauzula-ochrona-prawna.json docs/koncepcja/design/v3/strefa/panel.html --check
python3 -I narzedzia/makiety/check_zabiegi_1do1.py
```

Stan po kroku 3 (15.11.2026): wszystkie `OK`. `gen_kalkulator_dane.py` wypisuje dodatkowo „uwaga: kalkulator OC w starym układzie” –
bloki pól kalkulatora powstaną po wstawieniu znaczników w kroku 4. Uruchomienie `gen_oc_beauty.py` przeniosło do `oc-beauty.html` opis
`Organization` z `snippets/schema-home.json` („NNW dzieci”; pozostałe strony mają w swoim JSON-LD „NNW dla dzieci”) – zmiana spoza OC,
przewidziana w planie (6.2).

Stan po krokach 4–6 (15.11.2026, po zmianach makiet, `snippets/` i dokumentów): wszystkie generatory uruchomione w kolejności z tej
sekcji – żaden plik się nie zmienił; wszystkie `--check` → `OK`; `gen_kalkulator_dane.py` buduje bloki pól kalkulatora (komunikatu
o starym układzie już nie ma); `check_zabiegi_1do1.py`, `check_zabiegi_pdf.py --wymagaj-crm`, `check_zgodnosc_crm.py`,
`kontrola/check_oc_spojnosc.py` i `kontrola/oc/oc-skladka.test.js` – `OK`.

Stan po weryfikacji, runda 1 (15.11.2026): zmiany w generatorach – `gen_kalkulator_dane.py` sprawdza też przykłady zabiegów na kaflach
„Dla kogo” (tylko dosłowne nazwy pozycji z list nr 1 i 2, przy podologu zdanie Q1) i odnośnik kafla do `#kalk-rodzaje`;
`gen_oc_beauty.py` uzgadnia słowo „pozycja” z liczbą w `data-gen="pozycje-<lista>"` (hero: „49 + 63 pozycje” dla czytnika ekranu);
`oc_frazy.py` – fraza „grupa {N}” (pole szablonu z numerem dawnej grupy). Po zmianach `faq-oc-beauty.json` i `schema-home.json`
uruchomiony `gen_oc_beauty.py`; pozostałe generatory bez zmian w plikach; wszystkie `--check` → `OK`.

Stan po weryfikacji, runda 2 (15.11.2026): `gen_kalkulator_dane.py` – blok `gen:taryfa-data` bez `teksty_crm` i pól `*zrodlo`
(asercja: w bloku nie ma `crmaura`, `.svelte`, `program.ts`, `{termin}`, końcówki zdania CRM); `gen_oc_beauty.py` – spacje twarde
w „Pobierz listę nr 1 (PDF, Aneks nr 5)” i „Brzmienie Aneksu nr 5”; `snippets/oc-skladka.js` – opis portalu „+25% (6–⁠8 osób)”
z łącznikiem słowa U+2060 po półpauzie (fixture: pole `opis` przy 6–8 osobach) i komentarz o kolejności sprawdzeń (CRM `wycenaNowej`
najpierw sprawdza sumę – uwaga K9); fixture D4: `oczekiwane.przycisk_portalu` („Wykonuję…” bez pozycji a–h – przycisk nieaktywny,
fokus na pozycji a); `check_oc_spojnosc.py` – tekst publikowany ze zdaniem „zabieg nie zmienia składki” musi mieć zdanie CRM (K12).
Zdanie o marce w JSON-LD: „wskazuje go: NNW dla dzieci” w `schema-home.json`, `llms.txt`, na 5 stronach pisanych ręcznie
(`makieta-v3`, `tax-protect`, `utrata-dochodu`, `nnw-dzieci`, `grupowe-ergo`) i w 00 (D40), 02, 04; `oc-beauty.html`, `opieka-medyczna.html`
i `slownik.html` – przez generatory. Po zmianach uruchomione wszystkie generatory w kolejności z tej sekcji; wszystkie `--check` → `OK`.

Integracja 15.11.2026 (opieka medyczna i słownik na nowych stronach): opieka medyczna w `PRODUKTY` z plikiem `opieka-medyczna.html`
i na liście `STRONY` `gen_wspolne.py`; `opieka-medyczna.html` i `strefa/szkolenia.html` na liście `STRONY` `slownik/gen_terminy.py`
(oznaczenia; na opiece bez elementów `data-przyklad="tak"`); `opieka-medyczna/build.py` – bloki wspólne po `nbsp()`, stopka z
`nnw-dzieci.html`, oznaczenia z `gen_terminy.py`; kafelek opieki w `makieta-v3.html` → `opieka-medyczna.html` („Cenę przygotuje doradca”);
odnośnik „Opieka medyczna” w stopkach wszystkich stron → `opieka-medyczna.html` (w `strefa/` – `../opieka-medyczna.html`). Po zmianach
uruchomione wszystkie generatory w kolejności z tej sekcji; wszystkie `--check` → `OK`; `check_zabiegi_1do1.py`, `kontrola/check_oc_spojnosc.py`,
`kontrola/slownik/e_static.py`, `slownik/test_slownik.js` (oba tryby), `slownik/test_poprawki.js wszystko`, `oc/t_kalkulator.js` – bez błędów.

Reguła kategorii D45 (16.11.2026, decyzja zleceniodawcy; 00, D45): rodzaj z listy nr 1 (kosmetyczny, fryzjerski, masaż) razem
z rodzajem z listy nr 2 (kosmetologiczny, tatuaż) – pełna taryfa; podologia zawsze pełna. Grupy rodzajów – `taryfa-oc-beauty.json`
(`regula_kategorii`), reguła – `oc-skladka.js` (`kategoria(rodzaje, T)`) i `oc_taryfa.py` (opis słowami w tabeli „Pełna taryfa OC”,
regułach pod listami i FAQ). Odstępstwo od CRM (`kategoriaZRodzajow`) w 9 połączeniach: fixture – przypadki A7, A11, B17 i 9 kombinacji
z polem `odstepstwo_D45` (kwota portalu, kwota i opis CRM); `check_zgodnosc_crm.py` przyjmuje różnicę tylko tam; `oc-skladka.test.js`
– 64 kombinacje według reguły zapisanej w teście; `t_kalkulator.js` – kwota portalu zamiast CRM w A7, A11, B17 i profile „Kosmetolog”
+ „Stylistka paznokci” → pełna taryfa; `check_oc_spojnosc.py` – D45 w 00, brak opisów reguły sprzed D45 w tekstach publikowanych.
Zmiana dla CRM: `docs/koncepcja/do-crm/2026-11-16-D45-kategoria-taryfy-oc.md` (14 §4.7, P1-11) – po wdrożeniu w CRM usuń
`odstepstwo_D45` z fixture i wyjątek D45 z `check_zgodnosc_crm.py`. Uruchomione: `gen_kalkulator_dane.py`, `gen_oc_beauty.py`,
`slownik/gen_strona.py` (zmienione pliki: `makieta-v3.html`, `oc-beauty.html`, `schema-faq-oc-beauty.json`, `slownik.html`); pozostałe
generatory bez zmian w plikach; wszystkie `--check` → `OK`.

Uwagi zleceniodawcy do strony głównej (16.11.2026; 00, D46): sekcje II i III i przewodnik po kalkulatorze OC – zmiany ręczne w
`makieta-v3.html` poza blokami generatorów (kontrola `kontrola/oc/t_przewodnik.js`); sekcja IV „Dla kogo” (D46 e) – profile „Trycholog”
(rodzaj „Gabinet kosmetyczny”) i „Masażysta” („Salon masażu”), ikony `lux-trycholog` i `lux-masazysta` (sprite strony, `ikony-v3-sprite.svg`,
`ikony/`, manifest, arkusz, katalog w `design-preview.html`). `gen_kalkulator_dane.py` – mapa `DLA_KOGO` z nowymi profilami; przykłady
zabiegów na kaflu dzielone według nazw pozycji z list (funkcja `rozbij_przyklady`), nie według przecinka – nazwa „Masaż manualny ciała,
w tym masaż głowy i twarzy” sama ma przecinek (od weryfikacji 17.11.2026 przykłady na kaflach rozdziela średnik, a `rozbij_przyklady` dzieli po „; ”). Stopka „Dla kogo” z dwoma nowymi odnośnikami na 6 stronach pisanych ręcznie; `opieka-medyczna/build.py`
i `slownik/gen_strona.py` przeniosły ją do `opieka-medyczna.html` i `slownik.html`; pozostałe generatory bez zmian w plikach; wszystkie
`--check` → `OK`. `check_oc_spojnosc.py` – `DLA_KOGO` z trychologiem i masażystą (`llms.txt`, tabela person w 05).

## Kontrole (`kontrola/`)

Uruchamiane z dowolnego katalogu: `node narzedzia/makiety/kontrola/<grupa>/<plik>.js`, `python3 -I narzedzia/makiety/kontrola/<grupa>/<plik>.py`.
Czytają makiety z repozytorium (`file://`), niczego w nich nie zapisują. Zrzuty – `kontrola/wyniki/<grupa>/`.
W kolumnie „Stan” – wynik na `687654f` (14.11.2026), przy kontrolach list zabiegów – po kroku 3 (15.11.2026), a przy kontrolach OC
przepisanych albo dodanych w kroku 4 – po krokach 4–6 (15.11.2026); „raport” = skrypt wypisuje pomiary bez werdyktu, ocenia człowiek.

| Plik | Dawniej (katalog sesji) | Co sprawdza | Stan |
|---|---|---|---|
| `oc/oc-skladka.test.js` (+ `kalkulator-przypadki.json`) | `oc-aneks5/kalkulator-przypadki.json` (fixture; nowy test 14.11) | `snippets/oc-skladka.js` na fixture: 49 przypadków (stan, kategoria, kwota, tekst i opis portalu, `opisCrm`, powód, komunikat, kafelki sum), 64 kombinacje rodzajów, 36 kwot, formaty, spójność fixture z `zabiegi-oc-beauty.json` (a–h, listy E1–E4), `przycisk_portalu` tylko przy „Wykonuję…” bez pozycji a–h (D4) | `OK` (459 asercji; weryfikacja, runda 2) |
| `slownik/test_slownik.js [szer]` | `slownik/test_slownik.js` | słownik i dymki pojęć na 11 stronach (link z `aria-haspopup="dialog"` – od 17.11.2026 bez `role="button"`, Enter/Esc, położenie, bez JS, axe); `szer` – 12 stron × 7 szerokości: przewijanie w poziomie, błędy JS, tekst < 12 px, tafle | `BŁĘDY (0)` (po integracji 15.11.2026: obie wersje) |
| `slownik/test_poprawki.js [kontrast\|dymek\|slownik\|wszystko]` | `slownik/test_poprawki.js` | poprawki po kontroli 13.11: kontrast podkreślenia i fokusu, położenie dymka, kategorie, indeks A–Z, WCAG 1.4.12 (strony = `STRONY` z `gen_terminy.py`) | `BŁĘDY (0)` (po integracji 15.11.2026) |
| `slownik/anchors.py` | `slownik-review/anchors.py` | odnośniki `gdzie`/`zrodlo` w `slownik.json` → istniejące pliki i kotwice; `zobacz_tez`, kategorie | `BRAKI:` puste |
| `oc/t_kalkulator.js` | – (nowy, krok 4) | kalkulator OC na `makieta-v3.html` przez interfejs: 49 przypadków `kalkulator-przypadki.json` (44 jak CRM + 5 `tylko_portal`) – `#taryfa`, `#cena`, `#cena-dop`, `#cena-opis`, kafelki sum, przycisk (`aria-disabled`), pola `#lead` i `#kontakt-wynik`; zdanie pod sumami (przy więcej niż 8 osobach – powód z CRM); „Dla kogo” (8 profili – od 16.11.2026 z trychologiem i masażystą, 00 D46 e; 2 razem; trycholog i masażysta osobno i razem → podstawowa taryfa); zmiany po kliknięciu przycisku (pola `#lead` i `#kontakt-wynik` idą za kalkulatorem: ankieta, suma, ochrona prawna, chip; stan „brak” je czyści, a powrót do kwoty – np. zmiana jedynego rodzaju działalności – wypełnia je znowu (`data-powiazany`); „Wykonuję…” bez pozycji a–h – przycisk nieaktywny, fokus na pozycji a), lead bez wyniku; przycisk Tax Protect przejmuje formularz; inny temat formularza; bez przycisku – pola OC wyłączone, także przy `?produkt=oc-beauty`); stan startowy bez zaznaczeń, z JS i bez | `OK` (773 asercje; weryfikacja, runda 2) |
| `oc/t_przewodnik.js` | – (nowy, 16.11.2026) | strona główna po uwagach zleceniodawcy z 16.11.2026 (00, D46): przewodnik po krokach kalkulatora OC (bieżący = pierwszy brakujący, kolejność dowolna, `aria-current="step"`, „✓ Gotowe”, opis grupy, jedno ogłoszenie na zmianę kroku, bez przewijania i przenoszenia fokusu, puls tylko bez ograniczonego ruchu, bez JS bez podświetlenia), wskazówka pod wynikiem i na pasku ceny, przełącznik „OC / Tax Protect” (role, wysokość, szerokość), kafle sekcji II (odstęp, promień, bez rozmycia), sekcja IV (8 kart z trychologiem i masażystą, pełne wiersze 4 / 2 / 1, nowe ikony), przewijanie w poziomie i axe (WCAG 2.2 AA) przy 320, 390, 768, 1280 i 1440 px | `OK` |
| `oc/calc_search_check.js [ścieżka makieta-v3.html]` | `tools/calc_search_check.js` | kalkulator OC: „mezo” → plakietka „Lista nr 2”, po wyborze żaden rodzaj nie jest zaznaczony, `#cena` bez zmian, chip; „nici” → pozycja g) ankiety i „Składka do indywidualnej wyceny”; dialog klauzuli (12 punktów), fokus po Esc | `OK` (przepisany w kroku 4) |
| `oc/test_zab.js` | `zab/test_zab.js` | kalkulator OC: wyszukiwarka (combobox: klawiatura, mysz, Esc, brak wyników – z odesłaniem do sekcji Podologia, Q1), chipy „Wybrane zabiegi” (bez wpływu na rodzaj i składkę), pozycja a–h z wyszukiwarki, przekazanie do formularza, dialog klauzuli słowo w słowo, odnośnik z FAQ, bez JS; runda 2: odnośniki poza listą podpowiedzi, Tab zamyka listę bez aktywnej opcji, „zapytaj doradcę” ustawia temat OC, „laminowanie wlosow” → „Laminowanie włosów”; 1440 i 390 px | `OK` (weryfikacja, runda 2) |
| `oc/t_fix.js` | `zab/t_fix.js` | `oc-beauty.html`: filtr listy („klamra”, „manicure”, „kobido”…), skok do `#lista-2`, tabela taryfy, < 12 px, przewijanie w poziomie | raport (krok 3: „klamra” 0 – podologia bez pozycji, „manicure” i „kobido” po 2 pozycje, `overflow 0`, `errors []`) |
| `oc/t_func.js` | `kontrola/oc/t_func.js` | `oc-beauty.html`: sekcje `.zlista` vs JSON (kolejność, numery, brzmienie, kotwice, „także na liście nr …”, bez `a.bp-termin`), bez JS cała lista i 53 dawne kotwice (`#grupa-1…4`, 18 slugów, 31 slugów wycofanych), filtr („klamra” 0 z odesłaniem do `#podologia`, „manicure” 2, „kobido” 2), aliasy z JS, nagłówki, cele dotyku | `OK – listy = JSON (120 pozycji), 53 dawne kotwice bez JS…` (przepisany w kroku 4) |
| `oc/t_deeplink.js` | `kontrola/oc/t_deeplink.js` | `oc-beauty.html`: odnośnik `#slug` przy aktywnym filtrze – przewinięcie, czyszczenie filtra; od kroku 3 oba przypadki to aliasy (slug wycofanej pozycji → `#podologia`, `zabiegi-z-uzyciem-nici-pdo` → g4-06) | raport, element w widoku (po płynnym przewinięciu) |
| `oc/t_main.js` | `kontrola/oc/t_main.js` | `oc-beauty.html` × szerokości × ruch: przewijanie w poziomie, konsola, zasoby, < 12 px, tafle, nagłówki, cele | `errs`, `fails`, `bad` puste |
| `oc/t_sweep.js` | `kontrola/oc/t_sweep.js` | `oc-beauty.html` 360–1440 px co 20 px, z JS i bez: przewijanie w poziomie, tekst < 12 px | `problemy: []` |
| `oc/cmp_klauzula.py` | `kontrola/cmp_klauzula.py` | klauzula na `oc-beauty.html` = `klauzula-ochrona-prawna.json` (tytuł, 12 punktów, wyliczenia; od 17.11.2026 z twardymi spacjami z `typografia.py`, inne encje – błąd) | `ROZNIC: 0` |
| `oc/links_faq.py` | `kontrola/links_faq.py` | linki między 4 stronami, FAQPage `oc-beauty.html` vs `snippets/schema-faq-oc-beauty.json` | FAQ zgodne od kroku 3 (snippet generuje `gen_oc_beauty.py`); „złe linki” to fałszywe trafienia (`?produkt=…`, szablon JS) |
| `dam-prace/run.js` (+ `expect.json`) | `kontrola-zab-1311/run.js` | filtr i pole „Zabiegi” w „Dam pracę”: wyniki wyszukiwania vs `expect.json` (bez powtórzeń – zabieg z obu list ma dwa checkboxy), sekcje list, chipy, licznik, okno, bez JS, 5 szerokości; stary adres z wycofanym id (`?zabieg=g3-18`, `?zabieg=g3-18&zabieg=g1-17`: filtr działa, chip z dopiskiem, ukryte pole, usunięcie chipa i „Wyczyść”), karta z wycofanymi id (nazwa z dopiskiem, klasa `zab-tag-wycofany`, z JS i bez) | `wszystkie asercje OK` (weryfikacja, runda 1: przypadki wycofanych id, liczba ogłoszeń z DOM zamiast stałej 6, etykiety „120 pozycji (100 zabiegów)”; krok 4: licznik z dopiskiem „· N ogłoszeń” po poprawce z 13.11, zabieg z obu list zaznaczony w obu sekcjach; krok 3: selektory `data-lista`, fraza „lipoliz”) |
| `dam-prace/expect.py` | `kontrola-zab-1311/expect.py` | tworzy `expect.json` z `zabiegi-oc-beauty.json` (zapis obok skryptu) | `expect.json` odtworzony z wersji 2 (krok 3) |
| `dam-prace/cmp_data.py` | `kontrola-zab-1311/cmp_data.py` | dane i checkboxy w `dam-prace.html` = JSON v2 i archiwum (listy, zabiegi, wycofane; sekcje lista-1, lista-2, ankieta; `checked` w każdym wystąpieniu; chipy z wycofanymi na końcu) | `OK: dane 1:1` |
| `dam-prace/axe.js`, `contrast.js`, `keyboard.js`, `misc.js` | `kontrola-zab-1311/…` | axe (WCAG 2.2 AA), kontrast, ścieżka klawiatury, duplikaty `id` i limit 30 zabiegów | raport (`keyboard.js` od weryfikacji, runda 1: Tab do ostatniej sekcji list zamiast stałych 4× Tab – po kroku 3 sekcje są 3; przechodzi do końca, kod 0, 1440 i 390 px) |
| `dam-prace/verify.js`, `foot.js` | `kontrola-zab-1311b/…` | komunikaty filtra, stopka okna przy niskim oknie (fokus niezasłonięty) | raport, `errors: []` |
| `strefa/zakladki.js` | – (nowy, 16.11.2026) | „Zakładki w Strefie” – preferencja widoku salonu, nie kontrola dostępu (prośba zleceniodawcy 16.11.2026) w `strefa/panel.html`, `dam-prace.html` i `szkolenia.html`: ten sam skrypt w `<head>` i `<script src="zakladki.js">` na trzech stronach; przełączniki w „Ustawieniach” (`#zakladki`: `input type=checkbox role=switch` z etykietą, Tab + Spacja, klik w etykietę, stan tekstowy „Widoczna” / „Ukryta”, `aria-describedby` z opisem i informacją o aktywnych ogłoszeniach / nadchodzących zapisach, komunikat `aria-live`, widoczny fokus, wpis w „Historii konta” i w „Ostatnich zdarzeniach”); ukrycie pozycji menu (menu boczne, szuflada 390 px) i kafli na pulpicie właściciela i pracownika (kafle „Na skróty” bez pustych kolumn; u pracownika podpowiedź przy jednej ukrytej i pusty stan przy obu) na trzech stronach; informacja „Zakładka … jest ukryta w ustawieniach salonu” na początku aktywnego ekranu przy wejściu pod adres modułu (jedno zdanie „Moduł działa normalnie…”; **położenie w oknie pod paskiem przy wejściu z kotwicą ekranu – 9 adresów × 390 i 1280 px – i po zmianie ekranu na przewiniętej stronie; kotwice stanów w głębi ekranu (`data-trasa`: „Zamówienia i faktury”, kroki zamówienia i zapisu, stany po wysłaniu formularza – 11 adresów × 390 i 1280 px i zmiana ekranu) – informacja tuż przed kartą z celem, cel pod nią; zwykłe fragmenty (`#f-nowe`, `#sp-lista`) – informacja na początku ekranu, jak w produkcji**; potwierdzenie „… jest znowu widoczna” znika po zmianie ekranu) i „Pokaż zakładkę” (Enter, fokus na potwierdzeniu); zdania przy przełącznikach (ogłoszenie w moderacji osobno, zapisy salonu = „Zapisy zespołu”) z adnotacją „tylko wtedy, gdy…”; kontrakt formularzy bez JS (`formularz=zakladki` + zbiór `widoczne`; „Pokaż zakładkę” – `zakladka` + `widoczna`); globalny przełącznik „Szukam pracy” wyłączony (`?szukam=wylaczone`: „Praca – Dam pracę”, menu i historia bez „Szukam pracy”); synchronizacja z drugą kartą (zdarzenie `storage`); publiczna tablica, konto pracodawcy z rejestracji i profil organizatora bez zmian; stopka menu `dam-prace.html` w Strefie salonu z ukrytą „Pracą” – „Opiekun” zamiast skrótu do tablicy (konto pracodawcy – bez zmian); `?zakladki=bez-pracy`, `bez-szkolen`, `wszystkie` – parametr działa raz (stan zapisany, parametr usunięty z adresu z zachowaniem `?rola`, `?szukam` i kotwicy; po „Pokaż zakładkę” i F5 stan zostaje); wariant pracownika (`?rola=pracownik` i „Pulpit pracownika”: przełączniki tylko do odczytu, informacja bez przycisku, linki z rolą); bez JS (wszystko widoczne, informacje jako wzory); zablokowany `localStorage`; 7 szerokości 320–1440 px (przewijanie w poziomie, tekst ≥ 12 px, cele ≥ 24 px poza linkami w zdaniu); axe (WCAG 2.2 AA) na widokach z nowymi elementami (właściciel i pracownik) | `OK` (560 asercji; weryfikacja, runda 2) |
| `strefa/potwierdzenia.js` | – (nowy, 17.11.2026) | uwagi raportu 16 (rozdz. 3.3) w Strefie: akcje nieodwracalne w dwóch krokach (`details.mini`: Usuń konto, Usuń ogłoszenie, Zwróć 390,00 zł, Odbierz dostęp) i „Cofnij” przez 10 s (Zamknij, Usuń szkic, Zrezygnuj: fokus, przywrócenie stanu, czas stoi przy fokusie); licznik kodu `role="timer"` bez ogłoszeń co sekundę; błędy przy polach (`.field-error`, `aria-invalid`, `aria-describedby`, `role="alert"` przy Enter; widełki, liczba miejsc – 3 komunikaty, „Zgłoś nadużycie”, kod pocztowy 5 cyfr → 00-000); „Pobieranie…” bez kasowania sr-only; `aria-disabled` zamiast `disabled`; kotwice `#p-szkody` / `#p-archiwum` i adres po kliknięciu zakładki; filtry w adresie; ostrzeżenie przed utratą danych; teksty (druga osoba, strona czynna, cyfry, placeholdery z „…”, `spellcheck`, `autocomplete="off"`, `fieldset` „Adresaci”, h2); formaty `Intl` (1 234,50 zł, 3.12.2026); axe (WCAG 2.2 AA) na 4 stronach przy 320 i 1280 px; brak przewijania w poziomie 320–1440 px, także przy tytule z 85 znaków bez spacji | `OK` (289 asercji; integracja 17.11.2026) |
| `strony/t_glowna_stan.js` | – (nowy, 17.11.2026) | strona główna: powrót „wstecz” bez bfcache (pageshow – OC, Tax, „co dalej”), odpowiedzi kalkulatorów w adresie (zapis, odtworzenie, nieznane wartości pomijane), zakładka w kotwicy, komunikat braku przy polu (`aria-describedby`), wysyłka formularza (stan wysyłania, błąd sieci, podziękowanie), długie dane przy 320 px | `OK` |
| `strony/t_axe_strony.js` | – (nowy, 17.11.2026) | 9 stron publicznych: axe (WCAG 2.2 AA) przy 320 i 1280 px, przewijanie w poziomie przy 320–1440 px, błędy JS, jeden H1, Z1 (hero podstron = 1 ekran, panel ≥ 24 px nad dołem okna), Z2 (przycisk w 1. ekranie 320×640 i 390×844), Z3, Z29, Z37 (także H1 podstron jednym rozmiarem), Z8–Z10 (sekcje 1 albo 2 ekrany przy 1440×900 i 1280×900, poza hero i K6; runda 2) | `OK` |
| `strony/k4_seo_links.js` | `kontrola/tech/k4_seo_links.js` | 4 strony: JSON-LD, FAQPage = widoczne FAQ, linki i kotwice, odwołania `id`, brak adresów `/w/` | raport; 1 uwaga na stronę: pusty `#` „Więcej w słowniku” (szablon dymka) |

Kontrole przepisane w kroku 4 (rozdz. 7): `oc/t_func.js` (sekcje `.zlista` vs `listy`, 18 aliasów, `#grupa-1…4` także bez JS),
`oc/calc_search_check.js` i `oc/test_zab.js` (nowy kalkulator), nowy `oc/t_kalkulator.js` (49 przypadków); `slownik/test_slownik.js`
liczy hasła z `slownik.json` (wcześniej na sztywno 95). W kroku 3 dostosowane do list
w wersji 2: `dam-prace/*` (selektory `data-lista`, `expect.json`, `cmp_data.py`, `run.js`), `oc/t_fix.js`.

`slownik/e_static.py` (dawniej `kontrola-slownik-tech2/e_static.py`) – statyczna kontrola słownika i oznaczeń na 11 stronach:
JSON-LD wszystkich stron się parsuje, `DefinedTerm` = `slownik.json`, dane dymków = oznaczenia, oznaczenia tylko w `<p>`/`<li>` w `<main>`,
poza zakazanymi przodkami, elementami ukrytymi i przykładami (`data-przyklad="tak"`); link „Słownik pojęć” w stopce i szufladzie; linki
i kotwice. Stan: `PROBLEMÓW: 0` (po integracji 15.11.2026). Wymaga `bs4` i `lxml` (pakiety systemowe Pythona).

### Nieprzeniesione (wycofane 14.11.2026)

Kryterium: przenoszone są kontrole, które działają na dzisiejszych stronach i są potrzebne w kolejnych krokach planu
(rozdz. 7 i uwaga K18) albo dają werdykt (lista błędów) dla stron, których plan dotyczy. Pozostałe zostały w katalogu sesji:

- `tools/check_zabiegi.py` – starszy schemat danych, 356 błędów na obecnym JSON, plan (rozdz. 7) przewiduje usunięcie;
  `tools/build_cf.py` – to samo co `narzedzia/podglad-cloudflare/build.py` (różnią się tylko ścieżki `REPO`/`OUT`);
  `tools/build_preview.py` i `tools/check_preview.js` – dawny podgląd jako Artifact (3 produkty), zastąpiony podglądem na Cloudflare;
  `tools/header_shot.js`, `ledger_shot.js`, `logo_check.js` – zrzuty.
- `slownik/test_szer_slownik.js` – starsza kopia `test_slownik.js` (przegląd szerokości to dziś `test_slownik.js szer`).
- Kalkulator OC na `makieta-v3.html` (przegląd 12.11, przed `a82d8b1`): `kontrola/a_combobox.js` (czerwony: po Tab fokus przechodzi
  do „Wszystkie zabiegi”, lista zostaje otwarta), `kontrola/b_dialog.js` (czerwony: Tab z ostatniego elementu natywnego `<dialog>` wychodzi
  do przeglądarki – zachowanie Chromium), `kontrola/tech/t_fix_search.js`, `kontrola/tech/t_all.js` i pozostałe sondy z `kontrola/`
  i `kontrola/tech/` (zrzuty, piksele, pomiary, wersje `k4_all`/`k4_nojs` – część nojs się przerywa). Kalkulator przebudowuje krok 4;
  dialog klauzuli i wyszukiwarkę sprawdzają `oc/test_zab.js` i `oc/calc_search_check.js`, szerokości i błędy JS – `slownik/test_slownik.js szer`.
- `oc-beauty.html`: `kontrola/oc/gen_dry.py` (zastąpiony przez `gen_oc_beauty.py --check`), `t_shots.js`, `fonts_probe.js`, `t_perf.js`,
  `t_contrast.js` + `contrast.py`, `t_menu.js` (raporty, zrzuty), `t_obscured.js`/`t_obscured2.js` (fałszywe trafienia przy płynnym przewijaniu),
  `kontrola/klauzula_obie.py` (zawsze „różne” przez podpisy wokół klauzuli; klauzulę pilnują asercje generatorów i `oc/cmp_klauzula.py`),
  `kontrola/cmp_ld.py`, `html2txt.py` (pomocnicze), `zab/t_head.js`, `measure.js`, `opt.js`, `overflow.js`, `turbo/*.js`
  (`test_oc.js` powiela `oc/t_func.js` i `oc/t_deeplink.js`; reszta to pomiary i zrzuty; `script-backup.js` to skrypt przepływu, nie test).
- `kontrola-zab-1311/short*.js`, `shot2.js`, `wide.js` – zrzuty i próby poprawek CSS.
- `slownik-review/*.py` poza `anchors.py` – raporty z przeglądu treści słownika (część na zrzucie tekstów `texts.json`).
- `kontrola-slownik-tech/`, `kontrola-slownik-tech2/` (poza `e_static.py`) – przegląd dostępności słownika 13.11; wnioski są w
  `slownik/test_poprawki.js`, część skryptów działa na kopiach stron (`sb/`, `sb_base/`, `sb_nojs/`).
- `kontrola-om/` (opieka medyczna), `kontrola-szkpay2/` (płatności za szkolenia), `kontrola123/`, `kontrola123fix/` (ulepszenia 1+2+3) –
  przeglądy z raportami do oceny ręcznej, część wymaga serwera HTTP na stałym porcie; `kontrola-om/k1.js` przerywa się na dzisiejszej stronie.
