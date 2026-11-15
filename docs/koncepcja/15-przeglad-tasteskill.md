# 15 · Przegląd makiet v3 według tasteskill 2.5.1 (design-taste-frontend)

| | |
|---|---|
| Wersja | 1.0 |
| Data | 15 listopada 2026 |
| Zakres | `design/v3/`: `makieta-v3.html`, `oc-beauty.html`, `tax-protect.html`, `utrata-dochodu.html`, `nnw-dzieci.html`, `grupowe-ergo.html`, `opieka-medyczna.html`, `slownik.html`. Poza zakresem: `strefa/*.html` |
| Źródło reguł | Plik `SKILL.md` skilla „tasteskill 2.5.1 / design-taste-frontend” od zleceniodawcy. Mamy tylko ten plik, bez kitu (rozdz. 1) |
| Metoda | Trzy audyty wymiarów: układ i ekrany, obrazy, tła i efekty, ruch, interakcje i dostępność. Po nich weryfikacja 24 ustaleń w przeglądarce (rozdz. 8). Narzędzia: Playwright i Chromium headless, `deviceScaleFactor` 1, strony przez `file://`. Szerokości okna 1440×900, 1024×768, 820×1180, 768×1024, 390×844 i 320×640 |
| Powiązane | `10` (§1–§8, §12 decyzje, §13 pytania, §14 przejście TURBO, §16–§18), `00` (D29, D30, D36, D37, D43), `07` (WCAG 2.2 AA) |
| Status | Przegląd tylko do odczytu. Makiety się nie zmieniły. Wszystkie konflikty (K) czekają na decyzję zleceniodawcy |

> **Konwencje.**
> - **Z**: zgodne z kierunkiem v3, do wdrożenia bez decyzji.
> - **K**: konflikt z zatwierdzoną decyzją projektu albo z prawem, do decyzji zleceniodawcy.
> - **N**: nie da się sprawdzić bez kitu skilla.
> - „Ekran” to wysokość okna. „Kafel” to pierwszy ekran sekcji ustawionej na górze okna.
> - ✔ oznacza ustalenie, które weryfikator zmierzył ponownie i potwierdził. „–” oznacza wartość z audytu, której nie sprawdzono drugi raz.
> - Identyfikatory w nawiasach, np. [section-height] i {hero-fold}, to nazwy kontroli z checklisty skilla. Mierzyliśmy własnymi odpowiednikami tych kontroli, a nie skryptami kitu.
> - Dokument nie zawiera numerów telefonów, adresów e-mail ani danych rejestrowych. Piszemy tylko, że takie dane są na stronach.

## TL;DR

- Makiety v3 są technicznie czyste: brak przewijania w poziomie (48 z 48 pomiarów), równe krawędzie kontenera, 0 błędów JS i dobra obsługa klawiatury. Przy ograniczonym ruchu strona stoi nieruchomo.
- Najwięcej pracy wymagają pierwszy ekran podstron, rytm sekcji (tylko 7 z 54 sekcji ma 1 albo 2 ekrany), krawędzie przy 320 px i cele dotyku w słowniku. Wszystko to są poprawki typu Z.
- Skill przewiduje dla usług zdjęcia ludzi i pracy na płaskich tłach, bez szkła, ziarna i odsłaniania przy przewijaniu. V3 świadomie poszło inną drogą, a dane prawne agenta muszą zostać na stronie. Tych 9 rozbieżności nie da się „naprawić”, trzeba o nich zdecydować (rozdz. 5).

## 1. Czym jest tasteskill i czego nie mamy

**Skill.** `design-taste-frontend` (tasteskill 2.5.1) to skill do budowania i przeglądu firmowych stron „na poziomie figma.com i x.ai”. Jego rdzeń to 9 reguł domu, które mają pierwszeństwo przed resztą:

1. bez podpisów pod obrazami;
2. każdy obraz się rysuje, nigdy puste tło;
3. jedna sekcja na ekran;
4. równe krawędzie;
5. mikroanimacje na hover, bez przechylania;
6. więcej prawdziwych zdjęć;
7. prawdziwe kolorowe ikony;
8. efekty i sceny tylko na stronach technicznych;
9. adresy i kontakty bez numerów.

Do tego dochodzą: tabela rodzajów biznesu, plan strony według rodzaju, „rozdanie” elementów skryptami (hero, paleta, momenty), checklista z identyfikatorami kontroli i bramka `gate.mjs`. Bramka uruchamia się hakiem przy zakończeniu pracy i daje wynik `GATE: PASS/OPEN/DONE`.

**Czego nie mamy.**

| Element kitu | Do czego służy | Skutek braku |
|---|---|---|
| `scripts/gate.mjs`, hak Stop | bramka końcowa: checker przy 1440 i 390, przejście przy 320 (overflow, collide, tap-size), copy-lint | Nie ma linii `GATE:`. W języku skilla najbliżej temu stan `GATE: OFF/ERROR`, przy którym skill każe tylko wpisać tę linię do raportu |
| `assets/layout/check.mjs`, `scripts/consistency.mjs` | kontrole z checklisty `[…]` i `{…}` z progami | Kontrole emulujemy własnymi pomiarami. Progi i tolerancje są nieznane |
| `scripts/copy-lint.mjs`, `references/copy*.md` | lint tekstu (slop, stock, run-on, fact-agree, assumed) | Warstwy tekstu nikt nie sprawdził automatycznie |
| `scripts/perf.mjs`, `photos.mjs`, `icons.mjs` | waga obrazów i CLS, zdjęcia zastępcze, prawdziwe ikony | Wagi znamy tylko z §7 i §14.5 dokumentu 10 |
| `assets/` (`system.css`, `starter.html`, hero, motion, moments), `deal.mjs`, `start.mjs`, `moments.mjs` | wspólny system, „rozdany” hero, paleta i momenty | Nie da się powiedzieć, jaki hero ani moment skill by przydzielił, ani sprawdzić siatki jego systemu |
| `references/*.md` (m.in. `layout-v4.md`, `sections.md`, `system.md`, `motion.md`) | definicje „1 ekranu”, „clear bleed”, kafla, wyjątków | Przyjęliśmy własne definicje (rozdz. 6, N1) |

**Wiarygodność przeglądu.**

- **Mocne strony.** Pomiary geometrii (wysokości, krawędzie, cele dotyku, liczba animacji, style obliczone) są powtarzalne i niezależne od kitu. Kierunek ustaleń jest pewny. Weryfikacja potwierdziła 24 z 24 sprawdzonych ustaleń, przy czym w 3 trzeba było poprawić przyczynę albo wartość (rozdz. 8).
- **Słabe strony.**
  - Dokładne liczby („16 z 54 sekcji”) zależą od przyjętych tolerancji.
  - Nie wiemy, które ustalenia kit uznałby za FAIL, a które za WARN.
  - Skill sprawdza strony przez http na 127.0.0.1. My użyliśmy `file://`, bo logo jest linkowane cztery poziomy wyżej i przez `http.server` dawało 404. Na geometrię nie ma to wpływu.
  - Skill jest przede wszystkim narzędziem do budowania nowej strony z własnego systemu. Przyłożony do zatwierdzonego, autorskiego kierunku z natury daje wiele konfliktów K.
  - Z 4 zapowiedzianych audytów do zestawienia trafiły 3. Wyniki trzeciego (ruch) dotarły w części, a czwarty (treść i jeden system) nie dotarł wcale. Jego surowe dane istnieją, a weryfikator wyciągnął z nich tylko sygnały oznaczone N5.

## 2. Rodzaj strony: usługa

Według tabeli z §1 skilla agent ubezpieczeniowy to rodzaj „people are hired… agency”, czyli **page type `service`, site-kind `other`, kind `service`**. Strony powinny to deklarować przez `<html data-type="service">`, `<meta name="page-type" content="service">` i `<meta name="site-kind" content="other">`. Dziś na 8 z 8 stron nie ma żadnej z tych deklaracji (✔, Z24).

| Obszar | Co skill przewiduje dla usługi (site-kind other) | Stan v3 |
|---|---|---|
| Obrazy | „Photographs lead: the product, the people, the rooms, the work”. Zdjęcia zastępcze z licencją, wykazane jako zastępcze | 2 zdjęcia z AI (Bloom), oba na stronie głównej. Podstrony: 0 zdjęć (K2, Z13, Z14) |
| Tła | „flat grounds and one brand band”. CSS grounds dla usług to „flat tokens”. Bez ziarna, gradientu, efektu i sceny | Jedwab i marmur jako sceny, szkło `backdrop-filter`, ziarno, 4 gradienty (K1, Z16) |
| Ikony | prawdziwe ikony tylko dla narzędzi, których firma naprawdę używa. Nigdy rysowane podróbki logotypów | 23 ikony rysowane w jednym kolorze (D14). Partnerzy zapisani tekstem (K3) |
| Diagramy, UI | 0–1 nieruchomy diagram. Fragmenty UI tylko z aplikacji, z której klient korzysta | 1 wykres na UD. Karta Strefy Klienta to dozwolony fragment „app the client runs” |
| Ruch | wejście hero raz, 1–2 „rozdane” momenty oparte na zdjęciu albo typografii (dla usług np. pinned-chapters, picture-develops), warstwa hover i press. Nic nie rusza się od przewijania poza momentem | Wejście hero ✔. Odsłanianie przy przewijaniu na 8 z 8 stron (K4), paralaksa (Z20), brak stanu press (Z19) |
| Układ | hero sam na pierwszym ekranie, sekcje po 1 albo 2 ekrany, równe krawędzie, 44 px celu dotyku | rozdz. 4: Z1–Z12 |
| Rozdanie dla usługi (§4) | nav `mega/split/centre`, stopka `visit/dark/columns`, zamknięcie `type/photo`, rytm `surface-pairs/dark-band/space`, przyciski `solid/tonal/block/arrow` | Nie losowaliśmy (brak `start.mjs`). V3 ma odpowiedniki: nav mega ≥ 1200 px, ciemna stopka, przyciski solid i ghost |
| Kontakty | reguła 9: ulica i dzielnica bez numeru, bez kodu, bez numerów rejestrowych, bez telefonu w prawdziwym formacie, kontakty w `.example` | Dane wymagane od agenta (D37, art. 22 ustawy o dystrybucji ubezpieczeń) (K5) |

Wniosek: w kierunku v3 najbliższą skillowi drogą jest „usługa z momentem typograficznym”. „Jeden dzień w salonie” (§14.1) i odsłonięcie martwej natury mogą pełnić rolę dwóch dozwolonych momentów strony głównej (K4, wariant B).

## 3. Werdykt

1. **Fundament jest zgodny ze skillem.** Brak przewijania w poziomie (48 z 48 pomiarów) i 0 elementów poza oknem przy 320 px. Kontener ma równe krawędzie na wszystkich stronach: 140/140, 40/40, 33/33, 31/31 i 16/16 px. Do tego klawiatura, skip link, fokus, nazwy kontrolek, nagłówki i spokój przy ograniczonym ruchu (16 z 16), wejście hero raz, 0 fioletu, brak WebGL i najwyżej 2 akcje w hero (rozdz. 9).
2. **Pierwszy ekran podstron nie spełnia reguły 3 przy żadnej szerokości.**
   - Na tabletach hero zajmuje 0,69–0,94 ekranu, a H2 następnej sekcji widać na 6 stronach przy 820 px.
   - Na desktopie panel wychodzi za krawędź okna: jego dół leży na 917–1041 px przy oknie 900 px.
   - Na telefonie 320 px główny przycisk jest pod ekranem na 8 z 8 stron.

   To najważniejsza poprawka Z.
3. **Rytm sekcji odbiega od reguły 3 w całym serwisie.** Przy 1440 px tylko 7 z 54 sekcji ma około 1 albo 2 ekranów. 16 sekcji jest niższych niż 0,9 ekranu, a 11 wyższych niż 2,1. Krótkie sekcje końcowe (szkoda, FAQ, „dalej”) wpuszczają do kafla H2 sąsiada. Większość tego da się poprawić bez zmiany treści (Z8–Z10). Wyjątkiem są strony-dokumenty (K6).
4. **Dostępność dotyku i krawędzie przy 320 px mają konkretne błędy do szybkiej naprawy:**
   - 430 linków „Zobacz też” w słowniku ma inny cel bliżej niż 8 px, co jest FAIL [tap-size];
   - panel hero wychodzi poza taflę o 5–6 px na OC i UD, a na stronie głównej treść dotyka jego prawej krawędzi;
   - sticky „Jednego dnia w salonie” jest zepsuty przez kaskadę CSS (Z11).
5. **Główna sprzeczność dotyczy kierunku, a nie wykonania.** Skill dla usług chce zdjęć ludzi i pracy na płaskich tłach. V3 to „całość w szkle” na teksturach i z 2 zdjęciami z AI (D14, §1, §6, §8). To decyzja zleceniodawcy (K1, K2). Tańsze poprawki w ramach v3 można wdrożyć od razu (Z15–Z17).
6. **Ruch przy przewijaniu łamie wprost listę „Never” skilla** na 8 z 8 stronach: od 4 do 50 bloków odsłanianych przy przewijaniu. Zatwierdził to jednak §14.2 (K4). Efekty spoza zatwierdzonej listy można zdjąć bez decyzji: paralaksę zdjęcia hero, dryf cyfr rozdziałów i 3,6-sekundowe wejście (Z20, Z21).
7. **Prawo ma pierwszeństwo przed regułami 9 i 1.** Dane agenta (KRS, NIP, REGON, numer RPU, adres do reklamacji, telefon) oraz zastrzeżenie „Symulacja, nie oferta” zostają. W raporcie bramki skilla zapisujemy je jako uchylenia z powodem prawnym (K5, K9).
8. **Luka w przeglądzie.** Nie mamy ocenionej warstwy tekstu ani „jednego systemu” (brak copy-lint i wyników 4. audytu). Przed uznaniem przeglądu za pełny trzeba uruchomić kit albo dokończyć ten audyt (N4, N5).

## 4. Z – do wdrożenia bez zmiany kierunku

Priorytet: **P1** to pierwszy ekran albo dostępność, przed kolejną prezentacją. **P2** to najbliższe przejście poprawek. **P3** to wdrożenie produkcyjne. Wysiłek: **S** do 2 godzin, **M** do 1 dnia, **L** ponad 1 dzień. Wspólne komponenty zmienia się tylko generatorami: `gen_wspolne.py` (menu, pasek akcji), `slownik/gen_strona.py` (słownik) i `opieka-medyczna/build.py` (§17, §18).

| # | Co zmienić | Gdzie, szerokość | Pomiar | Reguła skilla | Prio | Wysiłek |
|---|---|---|---|---|---|---|
| Z1 | Hero podstron na dokładnie 1 ekran: `.page-hero{min-height:100svh}`, mniejszy `padding-top` (dziś `clamp(124px,13vw,172px)`), panel zakotwiczony tak, żeby dół panelu wypadał najwyżej 24 px nad dolną krawędzią okna | 7 podstron, `section.page-hero`; 820×1180, 768×1024, 1440×900, 1024×768 | ✔ Przy 820: hero 0,69–0,81 ekranu, następna sekcja wystaje 227–364 px, jej H2 na 1. ekranie na 6 stronach (np. OC `#zabiegi` H2 na 976 px przy oknie 1180). Przy 768: 0,78–0,94 ekranu. ✔ Przy 1440 dół panelu: OC 917, UD 956, NNW 1041, ERGO 978, opieka 1012, słownik 947 (Tax 885 mieści się). Zrzuty: `v1-oc-820x1180.png`, `v5-nnw-1440x900.png` | reguła 3; [hero-screen, hero-fill, fold-cut] {hero-fold} | P1 | M |
| Z2 | Telefon: główny przycisk w pierwszym ekranie. Krótszy lead (drugie zdanie i `.hero-note` pod przyciski), mniejszy H1, okruszki zwinięte do „‹ Ubezpieczenia”, przyciski przed `dl.figures` | 8 stron, `.hero-actions a.btn`; 320×640, NNW także 390×844 | ✔ Dół 1. przycisku przy oknie 640 px: home 754, OC 845, Tax 923, UD 893, NNW 1007, opieka 874, słownik 903. Hero 1,85–2,37 ekranu. ✔ NNW przy 390: przycisk na 826–876 px, ucięty przez krawędź 844. Zrzut: `v2-nnw-390x844.png` | [fold-action, fold-cut] | P1 | M |
| Z3 | Równe krawędzie panelu hero przy 320: `.hero-panel{grid-template-columns:minmax(0,1fr)}`, `.figures dd` zawija się poniżej 360 px. To samo dla `.member-card` | home, OC, UD (karta w `#strefa-klienta`); 320×640 | ✔ Panel 16..304 px. Treść: home 45..304 (lewy odstęp 29, prawy 0), OC 43..310 (prawy −6), UD 43..309 (prawy −5). Przy 390 odstępy symetryczne (29/29, 27/27). Kolumna siatki ma min-content 259–267 px. Zrzuty: `v3-*-320.png` | reguła 4; {edge-right, spill} | P1 | S |
| Z4 | Cele dotyku w słowniku: `.haslo-linki a{min-height:44px}`, odstęp między wierszami ≥ 8 px. Indeks A–Z: komórki ≥ 44 px, `gap` 8 px. Zmiana w `gen_strona.py` | `slownik.html`; 390×844, 320×640 | ✔ 485 linków po 32–42 px, `gap: 0 18px`, więc 430 celów ma inny cel bliżej niż 8 px. ✔ A–Z: 20 liter 32×40 px przy `gap` 4 px | [tap-size] (FAIL) | P1 | S |
| Z5 | Cele dotyku z WARN: 44 px przy `pointer:coarse` dla okruszków, `summary` „Informacje o agencie…”, `a.z-inna`, terminów `bp-termin` w wierszach. Projekt przyjął próg ≥ 24 px (§17.4). Skill jest surowszy, ale nie ma tu konfliktu | 7 podstron, stopka 8 stron, OC, UD, ERGO; 390, 320 | – Okruszki 102×32 px. `summary` 300×24 px. OC: 40 odsyłaczy po 24 px. ERGO: terminy 21 px | [tap-size] (WARN) | P3 | S |
| Z6 | Jedna akcja główna w hero ERGO, obok dwóch dróg (D36) | `grupowe-ergo`, hero `nav.choice`; wszystkie szerokości | ✔ 0 elementów `.btn` w hero przy 1440 i 390 | [fold-action] | P2 | S |
| Z7 | Prawa połowa hero podstron: miejsce na zdjęcie produktu w stylu v3 albo panel z liczbami. Źródło zdjęć zależy od K2. Słownik może zostać typograficzny | 7 podstron; 1440, 1024 | ✔ Pas 520 px (ERGO 440) przy 1440, czyli 36% pierwszego ekranu. W hero 0 obrazów. Przy 1024 pas ma 204 px | reguła 2, 6; [empty-area, no-visual] | P1 | M + zdjęcia |
| Z8 | Krótkie sekcje końcowe i obcy H2 w kaflu. Home: scalić `#szkoda` z `#faq` w jedną sekcję z jednym H2 (§8 pkt 7 opisuje je razem). Podstrony: FAQ, „Inne ubezpieczenia” i `#dalej` jako jedna sekcja zamykająca (najwyżej 2 ekrany) albo `min-height:100svh` | 8 stron; 1440, 1024, 820, 390 | ✔ Home `#szkoda` 0,32 ekranu, H2 FAQ 322 px pod jej górą. ✔ OC `#faq` 0,54, H2 „Inne ubezpieczenia…” 517 px niżej. ✔ Tax `#faq` 0,75, obcy H2 703 px niżej. ✔ `#dalej` 0,61–0,75, słownik `.sl-end` 0,58. ✔ 16 z 54 sekcji ma mniej niż 0,9 ekranu. – Przy 820×1180 obcy H2 w 22 kaflach | reguła 3; [one-heading, one-screen, section-height] {neighbour, screen-short} | P2 | M |
| Z9 | Sekcje wyższe niż 2 ekrany, które nie wynikają z decyzji, podzielić. ERGO `#dla-salonu`: warianty i składka, świadczenia, przystąpienie. `#na-otwarcie` wydzielić jako `main > section`. Kalkulator na desktopie w 2 kolumnach (pytania bez zmian, D43) | ERGO, home, UD, opieka; 1440×900 | ✔ ERGO `#dla-salonu` 6,91, `#dla-rodziny` 2,72. Home `#kalkulator` 2,38, `#strefa-klienta` 2,68. UD `#zawody` 2,18, `#jak-kupic` 2,15. Opieka `#dla-kogo` 2,13, `#ceny` 2,13. ✔ 11 z 54 sekcji ma ponad 2,1 ekranu, z czego 3 dotyczą K6 | reguła 3; [section-height] {screen-height} | P2 | L |
| Z10 | Każdej sekcji przypisać wysokość 1 albo 2 ekrany (`--h`, `min-height` 100/200svh), dociąć `padding-block` (dziś `clamp(72px,11vw,168px)`) w sekcjach mających 1,1–1,3 ekranu. Robić po Z8 i Z9 | 8 stron; 1440, 820, 768 | ✔ 20 z 54 sekcji ma 1,1–1,9 ekranu (np. home `#ubezpieczenia` 1,55, `#kontakt` 1,81; Tax `#zakres` 1,88). Tylko 7 z 54 ma około 1 albo 2 | reguła 3; [section-height] | P3 | M |
| Z11 | Naprawić sticky „Jednego dnia w salonie”. Reguła `.section-head, .sk-head{position:relative}` nadpisuje `.day-head{position:sticky}` z media query, a `top:120px` zostaje. Nagłówek jest więc trwale przesunięty o 120 px, a sticky nie działa. Rozwiązanie: wyższa specyficzność (`.section-head.day-head`) albo inna kolejność reguł | home `#dzien-w-salonie`; ≥ 1024×700 | ✔ H2 317 px, lista 158 px od góry sekcji, różnica 158 px. `align-items` ma już wartość `start`, więc przyczyna podana w audycie była błędna. Zrzut: `v9-dzien-1440.png` | „h2 first and top-aligned”; [top-stagger] | P2 | S |
| Z12 | Tafle przy lewej linii, kończące się przed prawą: wyciągnąć na pełną szerokość `.wrap` (tekst w środku może mieć `max-width`) albo dać im element do pary na siatce | OC `.zrules`, Tax/NNW/opieka `.mind`, UD `.scope-aside` i `.variants-box`, NNW `.plan-panel`, ERGO `.ext-note`; 1440 | ✔ Odstęp od lewej i prawej krawędzi okna przy linii wrap 140/140: 140/308 (zrules, mind, scope-aside), 140/244 (variants-box), 140/276 (plan-panel). ERGO `.ext-note`: 188/484, czyli poza liniami z obu stron (audyt podał 140/308) | reguła 4; {one-sided, edge-right} | P2 | S |
| Z13 | Zdjęcia pracy bez twarzy w „Dzień w salonie” i „Dla kogo”: dłonie stylistki, fryzjera, podologa, linergistki. Źródło zależy od K2 | home `#dzien-w-salonie`, `#dla-kogo`; wszystkie szerokości | – 0 zdjęć. 6 chwil dnia i 6 kafli zawodów z ikonami rysowanymi linią | §2 „the people… the work”; reguła 6 | P2 | M + zdjęcia |
| Z14 | Kadr hero przy 768–1023 px: `object-position` około 70% 50% albo układ mobilny (pas zdjęcia nad panelem) do 1023 px | home `.hero-media img`; 768×1024 | ✔ `object-position: 22% 50%`. Panel (31..671 × 333..851) zasłania fotel, widać tylko ścianę i wąski pas po prawej. Zrzut: `v-hero-768.png` | reguła 2; „the hero is the work, not a mood” | P2 | S |
| Z15 | `.faq.glass` na podstronach bez rozmycia: wariant `glass--tint`, jak `.zlista` | 6 podstron, `#faq`; 1440, 390 | ✔ `backdrop-filter: blur(24px) saturate(1.4)` na sekcji bez sceny. Tło jest przezroczyste nad płaskim ivory (na opiece parchment). To łamie też własną zasadę §6 („szkło zawsze leży na zdjęciu”) | §2 flat grounds; [grounds] | P2 | S |
| Z16 | Gradienty zamienić na płaskie tokeny (`--midnight` albo `--navy`). Zasłonę hero zastąpić kryciem samego panelu. Paleta D13 jest płaska, więc nie ma konfliktu | `.member-card` (150°), `#na-otwarcie` (160°), `.end-card` na 7 podstronach (160°), `.hero::after` (90°); wszystkie szerokości | ✔ Style obliczone: `linear-gradient(…navy → midnight)` w 3 komponentach i zasłona `hero::after` | §2 „No… gradient”; [grounds] | P2 | S |
| Z17 | Tekstury bez powiększania: warstwa sticky 100lvh (jak dziś poniżej 768 px) albo tło dzielone na sekcje. Martwa natura ze źródła 2880 px | home: sceny marmuru i jedwabiu, `#kontakt`; 1440, 1024, 768 | ✔ Przy 1440 (`cover` na 2048×1152): marmur 2,69× i 2,98×, jedwab 2,02×, martwa natura 1,41×. – Przy 768 marmur do 3,62× | [photo-upscale]; reguła 6 | P2 | M |
| Z18 | Stan „press” na kliknięcie dla przycisków i linków (`:active`, np. przesunięcie o 1 px i ciemniejsze tło). Zmiana w `tokens-v3.css` i `gen_wspolne.py` | 8 stron | ✔ 0 reguł `:active` w arkuszach (wystąpienia `:active` są tylko w `@media (forced-colors:active)`) | reguła 5 „buttons… press on click”; [hover, motion-layer] | P2 | S |
| Z19 | Usunąć paralaksę zdjęcia hero i dryf cyfr rozdziałów. Nie ma ich na liście efektów §14.2 | home `.hero-media` (`hero-par`, `scroll(root)`); `.chapter-no` (`drift`, `view()`) na 7 stronach | ✔ Oba efekty działają przy 1440. Przy ograniczonym ruchu są wyłączone | §6 Never „parallax on text”; [scroll-linked] | P2 | S |
| Z20 | Wejście hero zgodne z §14.2: najwyżej 1,15 s, tylko ozdoby. Skrócić `hero-zoom`, zdjąć `note-in` z liczb i z paska partnerów | home | ✔ `hero-zoom` na zdjęciu 3,6 s, `dl.figures` do 1,25 s, `.partners` do 1,65 s. H1 i lead nie są animowane. Skill tego nie zabrania („enters once”), ale jest to niespójne z dokumentem 10 | §14.2 dok. 10; [hero-enter] | P3 | S |
| Z21 | Karta Strefy Klienta: `rotate:0`, przy hover tylko uniesienie o 2 px. Usunąć `figcaption` „Dane przykładowe”, bo dane mają już dopisek „(przykład)” (§14.1) | home `figure.member-card`; wszystkie szerokości | ✔ `rotate: -1.5deg` także po wyłączeniu animacji. ✔ Podpis widoczny | reguła 5 „No tilt”; reguła 1; [tilt, visual-caption] | P3 | S |
| Z22 | Pasek akcji chowa się nad formularzami spoza listy: `form#calc`, `.zsearch`, `#spec-form` (ten sam IntersectionObserver). Zmiana w `gen_wspolne.py` | home, OC, opieka; 390, 320 | ✔ Przy 320×640 i przewinięciu 8704 px pasek leży nad `form#calc`. Zrzut: `v-bar-calc-320.png`. – OC i opieka według audytu | [collide] | P3 | S |
| Z23 | Struktura `main > section`. Tło sceny przenieść na sekcje, zachowując jeden marmur bez szwu (§8 pkt 5, §10). `#na-otwarcie` przenieść na poziom `main` | home | ✔ Dzieci `main`: 3 sekcje i 3 `div.scene`. 7 sekcji nie jest bezpośrednim dzieckiem `main` | §4 krok 5 | P3 | M |
| Z24 | Head: `og:image` (1200×630), `twitter:image`, `link rel=icon`. Do tego deklaracja rodzaju: `data-type="service"`, `meta page-type`, `meta site-kind` | 8 stron | ✔ Na 8 z 8 stron brak `og:image`, ikony i deklaracji rodzaju | §1; [share-meta, page-meta] | P3 | S |
| Z25 | Logo w SVG, a do tego czasu PNG 320×48 (§14.5, §13 Q1) | nagłówek i stopka 8 stron | ✔ Plik 3000×450 px wyświetlany w 160×24 px | [photo-weight] | P3 | S |
| Z26 | Notatki makiety `.mock-note` usunąć przy wdrożeniu, po rozstrzygnięciu każdego założenia | home 6, OC 0, Tax 4, UD 2, NNW 4, ERGO 25, opieka 52, słownik 22 | ✔ Liczby z weryfikacji (audyt podał 54 dla opieki) | [placeholder, sample-label] | P3 | S |
| Z27 | Podkreślenia linków w nawigacji, stopce i FAQ rysowane zamiast pojawiać się skokiem. Reakcja na kursor dla `link-quiet` i logo | 8 stron; 1440 | – Według audytu ruchu. Weryfikator nie potwierdził tego jednoznacznie | reguła 5 „underlines draw” | P3 | S |

## 5. K – konflikty z zatwierdzonym kierunkiem v3 lub z prawem

| # | Konflikt | Reguła skilla | Decyzja albo przepis | Pomiar | Warianty do decyzji | Rekomendacja |
|---|---|---|---|---|---|---|
| K1 | **Szkło, tekstury, ziarno i ciemne sceny wobec płaskich teł** | §1 („CSS grounds, dark pages… tech only”), §2 („flat grounds and one brand band”, „no… grain, gradient”), reguła 6; [grounds, effect-kind, photo-repeat] | D14 („całość w szkle”), §1 („całość glass morph”), §6, plan scen §8, ziarno w §14.2 | – Home: 5 scen z teksturą, 11 tafli z `backdrop-filter`. Podstrony: 2–3 sceny, 3–5 tafli. Dwa pliki tekstur w 24 miejscach. ✔ Ziarno przy 1440 na 8 z 8 stron, przy 768 nigdzie. ✔ Ciemne bloki to 39,3% wysokości strony głównej (podstrony około 14–16%) | **A.** V3 bez zmian, odstępstwa wpisane w raport jako uchylenia. **B.** Hybryda: szkło w nagłówku, panelu hero i stopce, tekstury tylko w hero i stopce, reszta na płaskim ivory i pergaminie z jednym granatowym pasem. Ziarno wyłączone, `.promo` na jasnym tle. **C.** Pełna zgodność: płaskie tokeny, jeden pas marki i ciemna stopka. Oznacza zmianę D14 i ponowną akceptację kierunku | **A** z poprawkami Z15–Z17. Zleceniodawca sam zażądał „całości w szkle” po odrzuceniu v2. B tylko wtedy, gdy celem ma być zgodność z tasteskill |
| K2 | **Zdjęcia z AI bez ludzi wobec zasady „photographs lead: people, rooms, work”** | §2, reguła 6, §6 Never (stock podany jako własny); [photo-set] | §2 dok. 10 (brief marki „bez twarzy”), §7 (Bloom), §13 Q2 (otwarte: AI czy sesja) | ✔ 2 zdjęcia treści w serwisie, oba na stronie głównej (hero jako `<img>`, CTA jako tło). Na 7 podstronach 0 zdjęć | **A.** Sesja w prawdziwym salonie w stylu v3, bez twarzy: dłonie przy pracy, stanowiska, narzędzia. **B.** Licencjonowane zdjęcia zastępcze, wykazane jako zastępcze. **C.** Zostają zdjęcia z AI z zapisaną akceptacją zleceniodawcy. Zdjęcia z twarzami wymagałyby zmiany briefu marki | **A**. Zamyka Q2 i daje materiał do Z7 i Z13 |
| K3 | **Rysowane ikony i brak logotypów wobec „real full-colour icons”** | reguła 7; §3 (dla usługi: „tools really used”); §6 (cudze logo w jego kolorach) | D14 (ikony z Bloom, jeden kolor); komentarz w kodzie: zgody na nazwy i logotypy partnerów do potwierdzenia | – 23 ikony konturowe w kolorze `currentColor`, 0 ikon kolorowych. Partnerzy w hero zapisani tekstem szeryfowym | **A.** Ikony produktów i zawodów zostają (to nie „narzędzia”). Po uzyskaniu zgód oryginalne logotypy ubezpieczycieli w pasku partnerów, na kartach i przy „Kup online u Colonnade”. **B.** Zostaje tekst | **A** po uzyskaniu zgód, do tego czasu B |
| K4 | **Odsłanianie bloków przy przewijaniu** | §6 Never: „A card, row or tile that fades in on scroll; a fade-in on every section”; checklista Motion [scroll-reveal, scroll-linked] (dozwolone tylko w rozdanym momencie) | §14.2: ruch sterowany przewijaniem (kurtyny nagłówków, złote linie, odsłonięcie martwej natury) | ✔ Bloki `.rv-*`: 50/19/18/33/18/22/26/4 (home, OC, Tax, UD, NNW, ERGO, opieka, słownik). ✔ Animacje na osi przewijania: 121/49/46/83/46/54/68/10. – Przy ograniczonym ruchu nic się nie rusza i nic nie zostaje ukryte (16 z 16) | **A.** Bez zmian, z uchyleniem. **B.** 1–2 momenty na stronę, zgodnie ze skillem. Na stronie głównej „Jeden dzień w salonie” (moment typograficzny, bliski pinned-chapters dla usług) i odsłonięcie martwej natury. Na podstronie jeden moment typograficzny. Bez odsłaniania kart, wierszy, kafli i kurtyn nagłówków. **C.** Brak ruchu przy przewijaniu | **B**. Zachowuje filmowe tempo z §14 w dwóch miejscach, zdejmuje „fade-in on every section” i odciąża przeglądarkę |
| K5 | **Reguła 9 wobec obowiązków informacyjnych agenta** | reguła 9 (bez numeru domu, kodu, numerów rejestrowych i telefonu w prawdziwym formacie, kontakty w `.example`); [street-number, postcode, company-number, phone-number] | art. 22–23 ustawy o dystrybucji ubezpieczeń; D37 (informacje o agencie, adres do reklamacji, telefon); §17.3 (telefon w pasku akcji); §15 (KRS, NIP, REGON i numer RPU w stopce) | ✔ Na każdej stronie 3 linki `tel:` (na opiece 7), KRS 1 raz, numer RPU 5–9 razy. Kod pocztowy, NIP i REGON w stopce. 0 adresów `.example` | **A.** Dane zostają, w raporcie bramki zapisane jako uchylenie reguły 9 z powodem prawnym. **B.** W stopce tylko skrót, pełna formuła na `/informacje-prawne` (to już przewiduje §15). Numer RPU i dane podmiotu zostają w obu miejscach | **A** (z B zgodnie z §15). Reguła 9 chroni przed zmyślonymi, „prawdziwie wyglądającymi” danymi na stronach demonstracyjnych. Tu dane są prawdziwe i wymagane |
| K6 | **Jedna sekcja na ekran wobec stron-dokumentów i długich tabel** | reguła 3 („every section exactly one or two screens”); [section-height] {screen-height} | D29 i D43 (listy zabiegów 1:1 z Aneksu nr 5, z kotwicami), D30 (klauzula dosłownie w `#ochrona-prawna`), §18 (95 haseł słownika) | ✔ Przy 1440: OC `#zabiegi` 5,93 ekranu, `#ochrona-prawna` 4,01. Słownik `#hasla` 58,07 ekranu, z 20 nagłówkami H2 liter w jednej sekcji. – Przy 320: `#zabiegi` 18,07, `#hasla` 151,9. Tabele świadczeń i taryf poza decyzjami (ERGO `#dla-salonu`, opieka `#ceny`) są w Z9 | **A.** Wyjątek od reguły 3 dla stron-dokumentów (listy OC, klauzula, słownik). **B.** Podział bez zmiany treści: lista 1, lista 2 i ankieta z podologią jako osobne `main > section`. Klauzula: wprowadzenie i fakty na 1 ekranie, pełna treść w `<details>` (zmienia sposób pokazania z D30). Słownik: każda litera jako sekcja. **C.** Pełne listy na osobnej stronie-dokumencie, na stronie OC tylko wyszukiwarka i nawigacja | **B dla list OC** (D29 i D43 się nie zmieniają). **A dla słownika i klauzuli**, chyba że zleceniodawca zgodzi się na `<details>` przy klauzuli |
| K7 | **Etykiety rozdziałów przed H2** | checklista: „its h2 first” [one-heading] | §14.1 (rozdziały I–VII w etykietach sekcji) | – `p.eyebrow` jest pierwszym elementem w 54 z 54 sekcji. Pierwszym nagłówkiem jest wszędzie H2 | **A.** Bez zmian. **B.** Etykieta jako `span` wewnątrz H2 (zmienia się nazwa dostępna). **C.** Etykieta pod H2 | **A**. Niska waga, a bez kitu nie wiadomo, czy [one-heading] liczy element niebędący nagłówkiem (N) |
| K8 | **Kafle produktów bez uniesienia na hover** | reguła 5 („a linked card lifts 2px”) | §16 (stany hover: tło, podkreślenie nazwy, przesunięcie szewronu); §14.3 (produkty jako jedna tafla z liniami włoskowymi) | ✔ Przy hover kafel przesuwa się o 0 px. Przejście dotyczy tylko `background-color 0.3s` | **A.** Bez zmian. **B.** Uniesienie o 2 px z cieniem. Rozbija „jedną taflę” z §14.3 | **A** |
| K9 | **Zastrzeżenie pod wykresem UD** | reguła 1 (bez podpisu pod obrazem); [visual-caption, caption] | rzetelna, jasna i niewprowadzająca w błąd informacja dystrybutora (art. 17 ustawy o dystrybucji ubezpieczeń); treść z utratadochodu.pl (D33) | ✔ `figcaption` „Symulacja, nie oferta…” pod wykresem 3 słupków, widoczny przy każdej szerokości | **A.** `figcaption` zostaje (uchylenie). **B.** To samo zdanie jako akapit obok wykresu, nie jako `figcaption`, równie widoczne | **B**. Spełnia oba wymagania, wysiłek S |

## 6. N – nie do sprawdzenia bez kitu

| # | Kontrole skilla | Czego brakuje | Co zrobiliśmy zamiast |
|---|---|---|---|
| N1 | [section-height], {screen-height}, {screen-short}, [fold-cut], [fold-card], {hero-fold} | tolerancje i definicje z `layout-v4.md` §2 („≈ 1 ekran”, kafel, „clear bleed”) | Przyjęliśmy: ≈ 1 ekran to 0,9–1,1, ≈ 2 ekrany to 1,9–2,1, kafel to [góra sekcji, góra + okno − 10 px], przycisk „w hero” ma dół ≤ wysokości okna. Przy innych progach liczby się przesuną, kierunek nie |
| N2 | [row-lines], [col-edge], [stagger], [off-grid], [split-pair], {lines}, [section-air], [section-gaps], [empty-area], {sparse}, {neighbour-ground} | siatka i kolumny `system.css` | Sprawdziliśmy tylko linie `.container` (równe) oraz bloki wystające albo jednostronne (Z3, Z12). Skan kolizji nie wykazał realnych nakładań poza 3–5 px w `dt/dd` karty klienta przy 390 i 320 |
| N3 | rozdanie: `deal.mjs`, `start.mjs`, `moments.mjs`; [hero-enter] (`data-enter`), [moment-none] | skrypty rozdania i wzorce `hero-<id>.html` | Nie wiadomo, jaki hero, paletę, parę fontów i momenty przydzieliłby skill. Strony nie mają `data-enter`. Wejście hero zmierzyliśmy jako animację przy ładowaniu (jest) |
| N4 | `copy-lint` i warstwa tekstu: [copy-headline], [copy-fact], [copy-headings], [copy-buttons], [run-on], [fact-agree], [assumed], [action-repeat], copy-slop-word… | `copy-lint.mjs`, `copy.md`, `copy-voice.md`; wyniki 4. audytu nie dotarły do zestawienia | Sprawdziliśmy tylko liczbę akcji w hero: 2 na 7 stronach, 0 na ERGO [action-count] (✔) |
| N5 | jeden system: [button-styles], [card-family], [heading-scale], [link-styles], [nesting] | definicje „jednej pary przycisków” i „jednej skali” | Sygnały z surowych danych 4. audytu. H2 sekcji mają przy 1440 cztery rozmiary: 68 px, oraz 52 / 52,8 / 41,6 px w `#faq`, `#dalej`, `#powiazane` i `#szkoda`. W `main` jest 5–9 wariantów wyglądu przycisków (navy i ghost na jasnym i ciemnym tle, przyciski formularzy). Nie wiadomo, czy to FAIL |
| N6 | `perf.mjs` (waga obrazów, CLS, konteksty) | skrypt i progi | Wagi tylko za §7 i §14.5 dokumentu 10. Według §14.3 CLS 0,006 |
| N7 | [visual-empty], [empty-visual], [hidden-content] | sposób robienia zrzutu przez kit (przewijanie czy cała strona naraz) | Po przewinięciu 0 pustych ram na 765 ekranach. Na zrzucie całej strony bez przewijania 50 z 50 bloków `.rv-*` przy 1440 jest niewidocznych (puste tafle). Jeśli kit robi zrzut naraz, będzie to FAIL, który zależy od K4 |
| N8 | [img-alt] | czy kit akceptuje jawnie pusty `alt` | Zdjęcie hero ma `alt=""` w `aria-hidden`. Jeśli kit tego nie przyjmie: krótki opis wnętrza |
| N9 | przeglądarki i ekrany | Safari i Firefox (zastępczy IntersectionObserver), DPR > 1 | Nie zrzucaliśmy. Powiększenie zdjęć przy DPR 2–3 na telefonie tylko wyliczone: hero 1,25–1,87×, tekstury do 4,4× |

## 7. Proponowana kolejność prac

1. **Decyzje (jedno spotkanie, bez kodu): K1–K9.** Kolejność ważności: K2 (zdjęcia, bo od niej zależą Z7 i Z13), K6 (strony-dokumenty), K4 (ruch), K1, K5 i K9 (prawo, wpis uchyleń), a potem K3, K7 i K8.
2. **Szybkie poprawki Z (około 1–2 dni):** Z3, Z4, Z11, Z6, Z15, Z16, Z18, Z19, Z21, Z22, Z24 i Z25. Żadna nie czeka na decyzje. Z4 i Z22 przez generatory.
3. **Pierwszy ekran (około 2 dni):** Z1 i Z2 razem, bo oba dotyczą tego samego `.page-hero` i `.hero-panel`, a potem Z14. Test przy 6 szerokościach.
4. **Rytm sekcji (około 3–4 dni, po K6):** Z8, potem Z9 i Z12, a na końcu Z10 i Z23. Przy każdej zmianie: brak przewijania w poziomie od 320 px, test kalkulatora (`shot_v3`), `check_zabiegi_1do1` i `--check` generatorów (§17.4, §18.4).
5. **Zdjęcia (po K2 i sesji):** Z7, Z13, Z17, potem `og:image` z Z24 dla podstron.
6. **Ruch (po K4):** wariant B z K4, Z20 i Z27.
7. **Przed publikacją:** Z5 i Z26. Dokument 10 trzeba uzupełnić o decyzje K1–K9.
8. **Gdy będzie kit:** `copy-lint.mjs`, `consistency.mjs --widths 1440,1024,820,768,390`, `check.mjs --sizes 1440x900,1024x768,820x1180,768x1024,390x844`, `perf.mjs` i `gate.mjs` (przy 320). Uchylenia K wpisać do `.taste-skill/waivers.json` z powodami. Wyniki porównać z tym raportem i zamknąć N1–N9.

## 8. Weryfikacja ustaleń audytów

**Wejście.** Audyt „układ i ekrany” przyniósł 23 ustalenia. Audyt „obrazy, tła i efekty” przyniósł 22. Z audytu „ruch, interakcje i dostępność” dotarło streszczenie i 1 pełne ustalenie (reszta została ucięta). Czwarty audyt (treść i jeden system) nie dotarł.

**Scalenie.** Po usunięciu duplikatów zostało 27 Z, 9 K i 9 N. Scalone duplikaty:
- przechylona karta (3 audyty);
- pusty pas w hero podstron (2);
- reguła 9 (3);
- brak `og:image` (2);
- tekstury i [photo-repeat] (włączone do K1, bo to tła, a nie zdjęcia).

**Zmiany klasy.**
- Paralaksa zdjęcia hero i dryf cyfr rozdziałów: z K na Z. Nie ma ich na liście efektów §14.2, a skill zabrania paralaksy tekstu.
- Uniesienie kafli produktów: K, bo §16 opisuje hover, a §14.3 każe traktować produkty jako jedną taflę.
- Podpis „Dane przykładowe”: Z, bo dane i tak są oznaczone.

**Sprawdzone ponownie w przeglądarce** (24 ustalenia o wadze wysokiej lub średniej, wszystkie wymiary):

| # | Ustalenie (wymiar) | Pomiar weryfikacji | Wynik |
|---|---|---|---|
| 1 | Hero podstron za niskie przy 820 i 768 (układ) | 0,69–0,81 i 0,78–0,94 ekranu. H2 następnej sekcji widoczny przy 820 na 6 stronach | potwierdzone |
| 2 | Przycisk hero pod 1. ekranem przy 320, NNW ucięty przy 390 (układ) | dół przycisku 754–1007 px przy oknie 640 px; NNW 826–876 px przy 844 px | potwierdzone |
| 3 | Asymetria panelu hero przy 320 (układ) | 29/0, 27/−6 i 27/−5 px; przy 390 symetrycznie | potwierdzone |
| 4 | Cele dotyku w słowniku (układ) | 485 linków po 32–42 px, 430 ma sąsiada bliżej niż 8 px; A–Z 32×40 px przy `gap` 4 px | potwierdzone |
| 5 | Panel hero za dolną krawędzią przy 1440 (układ) | 917/885/956/1041/978/1012/947 px | potwierdzone |
| 6 | ERGO bez przycisku w hero (układ) | 0 `.btn` przy 1440 i 390 | potwierdzone |
| 7 | Obcy H2 w kaflu krótkich sekcji (układ) | home `#szkoda` 0,32 i H2 na 322 px; OC `#faq` 0,54 i H2 na 517 px; Tax `#faq` 0,75 i H2 na 703 px | potwierdzone |
| 8 | Tafle jednostronne (układ) | 140/308, 140/244, 140/276 px | potwierdzone; ERGO `.ext-note` **skorygowane** (188/484 zamiast 140/308) |
| 9 | Przesunięcie „Dzień w salonie” (układ) | różnica 158 px | pomiar potwierdzony, **przyczyna i poprawka odrzucone**: `align-items` ma już `start`. Prawdziwa przyczyna: sticky nadpisany przez `position:relative` przy zachowanym `top:120px` (Z11) |
| 10 | Statystyka wysokości sekcji (układ) | 54 sekcje: 11 ponad 2,1 ekranu, 16 poniżej 0,9, 7 około 1 albo 2 | potwierdzone co do sztuki |
| 11 | Pusty pas w hero podstron (obrazy, układ) | 520 px (ERGO 440), 0 obrazów w hero | potwierdzone |
| 12 | 2 zdjęcia, oba tylko na stronie głównej (obrazy) | `<img>` treści: home 1 (hero), podstrony 0 | potwierdzone |
| 13 | `.faq.glass` na płaskim tle (obrazy) | `blur(24px) saturate(1.4)`, sekcja bez sceny na 6 podstronach | potwierdzone |
| 14 | Gradienty (obrazy) | 3 komponenty i `hero::after` | potwierdzone |
| 15 | Powiększenie tekstur (obrazy) | 2,69×, 2,98×, 2,02×, 1,41× (audyt: 2,72×, 2,99×, 2,05×, 1,43×) | potwierdzone (różnice ±0,03) |
| 16 | Udział ciemnych bloków na stronie głównej (obrazy) | 39,3% | potwierdzone |
| 17 | Ziarno tylko ≥ 1024 px (obrazy) | jest przy 1440 na 8 z 8 stron, brak przy 768 | potwierdzone |
| 18 | Kadr hero przy 768 zasłania fotel (obrazy) | `object-position: 22% 50%`, zrzut | potwierdzone |
| 19 | Odsłanianie przy przewijaniu (ruch) | `.rv-*` 50/19/18/33/18/22/26/4; animacje 121/…/10 | potwierdzone co do sztuki |
| 20 | Brak stanu press (ruch) | 0 selektorów `:active` | potwierdzone |
| 21 | Przechylona karta (ruch, obrazy, układ) | `rotate: -1.5deg` bez animacji | potwierdzone |
| 22 | Paralaksa hero i dryf cyfr (ruch, obrazy) | `hero-par` na `scroll(root)`, `drift` na `view()` | potwierdzone |
| 23 | Wejście hero 3,6 s „obejmuje tekst” (ruch) | `hero-zoom` 3,6 s na zdjęciu; liczby do 1,25 s, partnerzy do 1,65 s; H1 i lead bez animacji | **skorygowane**: animowane są liczby i pasek partnerów, a nie H1 |
| 24 | Reguła 9 i `og:image` (układ, ruch, obrazy) | `tel:` 3–7, KRS 1, numer RPU 5–9; `og:image`, ikona i deklaracja rodzaju: 0 z 8 | potwierdzone |

Dodatkowo potwierdzone ustalenia niskiej wagi:
- pasek akcji nad `form#calc` przy 320;
- kafle produktów bez uniesienia;
- logo 3000×450 px;
- liczba `.mock-note` (opieka: 52, a nie 54).

**Odrzucone w całości:** żadne z 24 sprawdzonych ustaleń.

**Niesprawdzone ponownie** (pozostają z oznaczeniem „–”): cele dotyku z WARN, 22 kafle z obcym H2 przy 820, nakładanie paska akcji na OC i opiece, podkreślenia „skokiem”, przesunięcie sticky FAQ (weryfikator potwierdził tylko, że `.faq-head` jest sticky).

**Dowody** (pliki robocze sesji, nietrwałe): `/tmp/claude-0/-home-user-beautypolisa/02bc7ecd-7d14-594f-829e-bcbe3ff0c238/scratchpad/taste/`:
- `uklad/` (`results-*.json`, `hero.json`, `shots/`);
- `obrazy/` (`results-*.json`, `hero.txt`, zrzuty 1440/1024/768/390);
- `ruch/` (`mo/`, `kb/`, `hv/`);
- `tresc/` (surowe dane 4. audytu);
- `weryfikacja/` (`verify.json`, `verify2.json`, zrzuty `v1-…`, `v2-…`, `v3-…`, `v5-…`, `v7-…`, `v9-…`, `v-hero-768.png`, `v-bar-calc-320.png`).

## 9. Zgodne ze skillem (PASS, z audytów)

- Brak przewijania w poziomie (48 z 48) i 0 elementów poza oknem przy 320 px [off-viewport]. Równe krawędzie `.container` na wszystkich stronach i szerokościach [container-edges]. Nagłówek i stopka na tych samych liniach.
- 0 błędów JS. Wszystkie obrazy się ładują, 0 nieudanych żądań, wszystkie symbole ikon działają. Brak WebGL, `<canvas>` i wideo. 0 fioletu i lawendy w CSS, SVG i obrazach (§6 Never).
- Najwyżej 2–3 tafle `backdrop-filter` w widoku. Wyjścia awaryjne szkła działają.
- Wejście hero raz przy ładowaniu (8 z 8). Brak pętli, karuzel, zakładek zmienianych zegarem i przejmowania przewijania. Przy ograniczonym ruchu 0 animacji i nic ukrytego (16 z 16) [reduced-motion, hidden-content].
- Pierwszym przystankiem Tab jest skip link (16 z 16), a jego obwódka pojawia się od razu nad nagłówkiem. 1906 przystanków Tab i Shift+Tab z widoczną obwódką, nic pod nagłówkiem ani pod paskiem. Menu ma `aria-expanded`, a Esc oddaje fokus. 0 kontrolek bez nazwy, `alt` na obrazach, widoczne etykiety, jeden H1 na stronę, kolejność nagłówków bez przeskoków, `tabindex` ≤ 0, `lang`, `title` i `description` [a11y-name … page-meta].
- Najwyżej 2 akcje w hero [action-count]. Szuflada menu przy 390 px prawie pełnoekranowa, przyciski hero na pełną szerokość. Pasek akcji ukryty na 1. ekranie i przy stopce, nie zasłania `.calc-peek`, `.lead-form` ani `.end-card`.
