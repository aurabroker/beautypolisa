# 15 · Przegląd makiet v3 według tasteskill 2.5.1 (design-taste-frontend)

| | |
|---|---|
| Wersja | 1.1 (uzupełnienie o audyty „ruch, interakcje i dostępność” i „treść i jeden system”) |
| Data | 15 listopada 2026, uzupełnienie 16 listopada 2026 |
| Zakres | `design/v3/`: `makieta-v3.html`, `oc-beauty.html`, `tax-protect.html`, `utrata-dochodu.html`, `nnw-dzieci.html`, `grupowe-ergo.html`, `opieka-medyczna.html`, `slownik.html`. Poza zakresem: `strefa/*.html` |
| Źródło reguł | Plik `SKILL.md` skilla „tasteskill 2.5.1 / design-taste-frontend” od zleceniodawcy. Mamy tylko ten plik, bez kitu (rozdz. 1) |
| Metoda | Cztery audyty wymiarów: układ i ekrany; obrazy, tła i efekty; ruch, interakcje i dostępność; treść i jeden system. Po nich weryfikacja w przeglądarce w dwóch rundach: 24 ustalenia, a potem 37 z audytów ruchu i treści (rozdz. 8). Narzędzia: Playwright i Chromium headless, `deviceScaleFactor` 1, strony przez `file://`. Szerokości okna 1440×900, 1024×768, 820×1180, 768×1024, 390×844 i 320×640 |
| Powiązane | `10` (§1–§8, §12 decyzje, §13 pytania, §14 przejście TURBO, §16–§18), `00` (D29, D30, D36, D37, D43), `07` (WCAG 2.2 AA) |
| Status | Przegląd tylko do odczytu. Wszystkie konflikty (K) czekają na decyzję zleceniodawcy. **Wdrożenie 17.11.2026** (generatory i wzorce wspólne, opis w `narzedzia/makiety/README.md`): Z4, Z5 (bez pojęć słownika w zdaniu – wyjątek „inline” WCAG 2.5.8), Z15, Z16 (karta końcowa; karta Strefy, `#na-otwarcie` i zasłona hero – strona główna), Z18, Z19, Z22, Z24 (jeden obraz udostępniania z kadru hero; obrazy podstron po K2), Z25, Z27, Z28, Z32 i Z34 (część opieki medycznej), Z40, Z41. **Strony publiczne (17.11.2026):** Z1, Z2, Z3, Z6, Z7 (wariant „panel z liczbami” – liczby hero w prawej kolumnie panelu; zdjęcia zależą od K2), Z8, Z9 (ERGO „Dla salonu” w 3 sekcjach, „Na otwarcie” jako osobna sekcja; listy OC – K6; poprawione w rundzie 2 weryfikacji – niżej), Z11, Z12, Z14, Z16 (strona główna), Z20, Z21, Z23 (częściowo: „Na otwarcie” to osobna `section`, ale wewnątrz sceny marmuru – `main > div.scene > section`, nie `main > section`; reszta niżej), Z29, Z30, Z31, Z32 (OC `#faq` „Pytania o OC dla branży beauty” – weryfikacja, runda 1), Z33, Z34 (OC), Z35, Z36 (bez nagłówków z §8 – K10), Z37. **Runda 2 weryfikacji (17.11.2026, „dokończ”):** Z8 – pytania jako osobna sekcja, „Inne ubezpieczenia” i karta końcowa jako sekcja zamykająca `#zamkniecie` (dawniej razem 2,23–2,55 ekranu, teraz 1 + 2 ekrany); Z9 – ERGO: „Dla salonu” w 5 sekcjach (wstęp, warianty, pakiety, MediOpieka, wniosek) i „Dla rodziny” w 2 (ERGO Razem, ubezpieczenia dodatkowe) – każda ≤ 2 ekrany, kalkulator od 1200 px ciaśniej (rodzaje w 3 kolumnach, zakres dodatkowy w 2; 2,56 → 2,0 ekranu przy 1440×900), UD `#zawody` i `#jak-kupic`, opieka `#dla-kogo` i `#ceny` – ≤ 2 ekrany po przycięciu `padding-block` (Z10; przy 1440×900 i 1280×900 – w rundzie 3 także 1366×768 i 1536×864); Z10 – rytm 1 albo 2 ekrany od 64em × 37.5em (`data-ekrany`, `min-height` 100 / 200svh, `padding-block` przycięty); Z37 – H1 podstron jednym tokenem `--text-h1-podstrona`, H3 kafla `--text-h3-kafel` (DESIGN.md); Z38 – jedna karta pełna i jedna notka; Z39 – jeden chip, jeden link-akcja, tokeny podkreślenia linków; Z33 – „Zapytaj doradcę” z tematem w sr-only i jedno „Wyślij zapytanie”; Z36 – zakres zamiast „kompleksowej ochrony” (ERGO Razem). **Runda 3 weryfikacji (17.11.2026):** Z9 – kalkulator od 1200 px z rodzajami w trzech kolumnach bez przelewania kafli, ciaśniejsze odstępy; „Inne ubezpieczenia” w trzech kolumnach; ciaśniejsze karty UD `#zawody` i `#jak-kupic`, ERGO warianty i MediOpieka, opieka `#dla-kogo`; Z10 – sekcja wyższa niż 2 ekrany z przyciętym paddingiem (`data-ekrany="n"`, bez powrotu do pełnego paddingu), `data-ciasno` 16 px, treść sekcji 2-ekranowej od góry (kotwice trafiają na H2), cyfra rozdziału w obrysie sekcji; Z38 – notka słownika `.sl-stopka-uwaga`; Z39 – odnośniki „także na liście nr …” granatowe. **Z8–Z10 są spełnione przy oknach 1280×900, 1366×768, 1440×900 i 1536×864** (każda sekcja poza hero i K6: 1 albo 2 ekrany). **Z10 – wdrożenie częściowe:** przy 1280×720 i 1024×768 część sekcji ma ponad 2 ekrany (przycięty padding, naturalna wysokość), a na tabletach (820 i 768 px, poniżej 64em) rytm nie działa – w jednej kolumnie dopasowanie wymagałoby dzielenia sekcji tylko dla tabletów. Pomiar: `kontrola/strony/t_axe_strony.js` (Z8–Z10 przy 1440×900, 1280×900, 1366×768, 1536×864, 1280×720 i 1024×768). Bez zmian: Z13 i Z17 (zdjęcia i tekstury – K2, rozdz. 7 pkt 7), Z26 (notki makiety – przed publikacją, rozdz. 7 pkt 9). **Odstępstwo od kolejności z rozdz. 7:** reszta Z23 (pkt 5 wymienia ją razem z Z8–Z10, które wdrożono) – sceny marmuru i jedwabiu mają jedną przyklejoną warstwę tekstury na całą scenę; po rozbiciu na `main > section` każda sekcja miałaby własną warstwę i na granicy sekcji powstałby szew, a bez szwu działa tylko `background-attachment: fixed` (ignorowane w iOS Safari) albo przesuwanie tła o położenie sekcji liczone skryptem przy każdej zmianie wysokości (Z10) – do zrobienia razem z teksturami Z17 po K2. Opis w `narzedzia/makiety/README.md` |

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
- Warstwa tekstu i „jeden system”: jeden pilny błąd kontrastu (końcowa karta słownika, 1,2:1), te same fakty i akcje w różnych brzmieniach (kroki zakupu, nazwy produktów, „Oblicz” i „Policz”), skala nagłówków (H2 w 5 rozmiarach, H3 w 13) oraz kilka stylów kart i przycisków. To też poprawki Z.
- Skill przewiduje dla usług zdjęcia ludzi i pracy na płaskich tłach, bez szkła, ziarna i odsłaniania przy przewijaniu. V3 świadomie poszło inną drogą, a dane prawne agenta muszą zostać na stronie. Do tego dochodzą brzmienia zatwierdzone w §4 i §8 oraz nazwa roli „doradca” lub „agent”. Tych 13 rozbieżności nie da się „naprawić”, trzeba o nich zdecydować (rozdz. 5).

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
| `scripts/copy-lint.mjs`, `references/copy*.md` | lint tekstu (slop, stock, run-on, fact-agree, assumed) | Warstwę tekstu sprawdził 4. audyt własną listą około 45 polskich wzorców i oceną ręczną. List, progów i karty głosu kitu nie znamy (N4) |
| `scripts/perf.mjs`, `photos.mjs`, `icons.mjs` | waga obrazów i CLS, zdjęcia zastępcze, prawdziwe ikony | Wagi znamy tylko z §7 i §14.5 dokumentu 10 |
| `assets/` (`system.css`, `starter.html`, hero, motion, moments), `deal.mjs`, `start.mjs`, `moments.mjs` | wspólny system, „rozdany” hero, paleta i momenty | Nie da się powiedzieć, jaki hero ani moment skill by przydzielił, ani sprawdzić siatki jego systemu |
| `references/*.md` (m.in. `layout-v4.md`, `sections.md`, `system.md`, `motion.md`) | definicje „1 ekranu”, „clear bleed”, kafla, wyjątków | Przyjęliśmy własne definicje (rozdz. 6, N1) |

**Wiarygodność przeglądu.**

- **Mocne strony.** Pomiary geometrii (wysokości, krawędzie, cele dotyku, liczba animacji, style obliczone, kontrast na wyrenderowanym tle) są powtarzalne i niezależne od kitu. Kierunek ustaleń jest pewny. Weryfikacja sprawdziła 61 ustaleń i potwierdziła 60. W 8 trzeba było poprawić przyczynę albo wartość, a 1 ustalenie niskiej wagi odrzuciliśmy (rozdz. 8).
- **Słabe strony.**
  - Dokładne liczby („16 z 54 sekcji”) zależą od przyjętych tolerancji.
  - Nie wiemy, które ustalenia kit uznałby za FAIL, a które za WARN.
  - Skill sprawdza strony przez http na 127.0.0.1. Audyty ruchu i treści tak robiły, a weryfikacja używała `file://`, bo logo jest linkowane cztery poziomy wyżej i przez `http.server` dawało 404. Na geometrię i tekst nie ma to wpływu.
  - Ocena warstwy tekstu (słowa-wytrychy, nagłówki bez rzeczownika) jest częściowo ręczna. Liczby w Z36 i K10 to przybliżenie copy-lint, a nie jego wynik.
  - Skill jest przede wszystkim narzędziem do budowania nowej strony z własnego systemu. Przyłożony do zatwierdzonego, autorskiego kierunku z natury daje wiele konfliktów K.

## 2. Rodzaj strony: usługa

Według tabeli z §1 skilla agent ubezpieczeniowy to rodzaj „people are hired… agency”, czyli **page type `service`, site-kind `other`, kind `service`**. Strony powinny to deklarować przez `<html data-type="service">`, `<meta name="page-type" content="service">` i `<meta name="site-kind" content="other">`. Dziś na 8 z 8 stron nie ma żadnej z tych deklaracji (✔, Z24).

| Obszar | Co skill przewiduje dla usługi (site-kind other) | Stan v3 |
|---|---|---|
| Obrazy | „Photographs lead: the product, the people, the rooms, the work”. Zdjęcia zastępcze z licencją, wykazane jako zastępcze | 2 zdjęcia z AI (Bloom), oba na stronie głównej. Podstrony: 0 zdjęć (K2, Z13, Z14) |
| Tła | „flat grounds and one brand band”. CSS grounds dla usług to „flat tokens”. Bez ziarna, gradientu, efektu i sceny | Jedwab i marmur jako sceny, szkło `backdrop-filter`, ziarno, 4 gradienty (K1, Z16) |
| Ikony | prawdziwe ikony tylko dla narzędzi, których firma naprawdę używa. Nigdy rysowane podróbki logotypów | 23 ikony rysowane w jednym kolorze (D14). Partnerzy zapisani tekstem (K3) |
| Diagramy, UI | 0–1 nieruchomy diagram. Fragmenty UI tylko z aplikacji, z której klient korzysta | 1 wykres na UD. Karta Strefy Klienta to dozwolony fragment „app the client runs” |
| Ruch | wejście hero raz, 1–2 „rozdane” momenty oparte na zdjęciu albo typografii (dla usług np. pinned-chapters, picture-develops), warstwa hover i press. Nic nie rusza się od przewijania poza momentem | Wejście hero ✔. Odsłanianie przy przewijaniu na 8 z 8 stron (K4), paralaksa i linia postępu (Z19), brak stanu press (Z18) |
| Układ | hero sam na pierwszym ekranie, sekcje po 1 albo 2 ekrany, równe krawędzie, 44 px celu dotyku | rozdz. 4: Z1–Z12 |
| Rozdanie dla usługi (§4) | nav `mega/split/centre`, stopka `visit/dark/columns`, zamknięcie `type/photo`, rytm `surface-pairs/dark-band/space`, przyciski `solid/tonal/block/arrow` | Nie losowaliśmy (brak `start.mjs`). V3 ma odpowiedniki: nav mega ≥ 1200 px, ciemna stopka, przyciski solid i ghost |
| Kontakty | reguła 9: ulica i dzielnica bez numeru, bez kodu, bez numerów rejestrowych, bez telefonu w prawdziwym formacie, kontakty w `.example` | Dane wymagane od agenta i spółki (D37, art. 22 ustawy o dystrybucji ubezpieczeń, art. 206 § 1 KSH) oraz kontakt do IOD (RODO) (K5) |

Wniosek: w kierunku v3 najbliższą skillowi drogą jest „usługa z momentem typograficznym”. „Jeden dzień w salonie” (§14.1) i odsłonięcie martwej natury mogą pełnić rolę dwóch dozwolonych momentów strony głównej (K4, wariant B).

## 3. Werdykt

1. **Fundament jest zgodny ze skillem.** Brak przewijania w poziomie (48 z 48 pomiarów) i 0 elementów poza oknem przy 320 px. Kontener ma równe krawędzie na wszystkich stronach: 140/140, 40/40, 33/33, 31/31 i 16/16 px. Do tego klawiatura, skip link, fokus, nazwy kontrolek, nagłówki i spokój przy ograniczonym ruchu (16 z 16), wejście hero raz, 0 fioletu, brak WebGL, najwyżej 2 przyciski w hero i kontrast AA w około 8 800 próbkach tekstu poza jedną kartą (rozdz. 9).
2. **Pierwszy ekran podstron nie spełnia reguły 3 przy żadnej szerokości.**
   - Na tabletach hero zajmuje 0,69–0,94 ekranu, a H2 następnej sekcji widać na 6 stronach przy 820 px.
   - Na desktopie panel wychodzi za krawędź okna: jego dół leży na 917–1041 px przy oknie 900 px.
   - Na telefonie 320 px główny przycisk jest pod ekranem na 8 z 8 stron.
   - Przy 390 px w pierwszym ekranie UD i Tax (a także strony głównej) nie ma żadnej kwoty, czyli twardego faktu (Z29).

   To najważniejsza poprawka Z.
3. **Rytm sekcji odbiega od reguły 3 w całym serwisie.** Przy 1440 px tylko 7 z 54 sekcji ma około 1 albo 2 ekranów. 16 sekcji jest niższych niż 0,9 ekranu, a 11 wyższych niż 2,1. Krótkie sekcje końcowe (szkoda, FAQ, „dalej”) wpuszczają do kafla H2 sąsiada. Większość tego da się poprawić bez zmiany treści (Z8–Z10). Wyjątkiem są strony-dokumenty (K6).
4. **Dostępność (dotyk, kontrast) i krawędzie przy 320 px mają konkretne błędy do szybkiej naprawy:**
   - 430 linków „Zobacz też” w słowniku ma inny cel bliżej niż 8 px, co jest FAIL [tap-size];
   - panel hero wychodzi poza taflę o 5–6 px na OC i UD, a na stronie głównej treść dotyka jego prawej krawędzi;
   - sticky „Jednego dnia w salonie” jest zepsuty przez kaskadę CSS (Z11);
   - końcowa karta słownika nie ma modyfikatora `dark`, więc granatowy H2 leży na granatowym tle przy kontraście 1,2:1 (Z28, P1).
5. **Tekst opisuje te same fakty i akcje różnymi słowami.**
   - Droga do polisy ma 3 kroki na stronie głównej i 4 kroki (o innych nazwach) na OC i Tax.
   - Hero UD zawęża odbiorców do samozatrudnionych wbrew §16.
   - ERGO w `title`, H1 i okruszkach nazywa się inaczej niż w menu.
   - Akcja kalkulatora ma 4 brzmienia, a akcja kontaktu 5.
   - Opieka pokazuje w jednym ekranie do 4 akcji prowadzących do tego samego formularza.

   Wszystko to są szybkie poprawki Z (Z30–Z35, Z40). Rozbieżności wynikające z zapisów §4, §8 i §16 oraz z prawa idą do decyzji (K10–K13).
6. **„Jeden system” rozjechał się w szczegółach, a nie w kierunku.** Szkło D14 i para przycisków `.btn` są spójne. Rozjechały się:
   - skala nagłówków: H2 ma 5 rozmiarów i token do 68 px wobec 34–54 px z §4, H3 ma 13 rozmiarów;
   - karty: 6 wyglądów poza szkłem;
   - elementy w roli przycisku: 4 dodatkowe style.

   Poprawki Z37–Z39 wracają do §4 i nie zmieniają kierunku.
7. **Główna sprzeczność dotyczy kierunku, a nie wykonania.** Skill dla usług chce zdjęć ludzi i pracy na płaskich tłach. V3 to „całość w szkle” na teksturach i z 2 zdjęciami z AI (D14, §1, §6, §8). To decyzja zleceniodawcy (K1, K2). Tańsze poprawki w ramach v3 można wdrożyć od razu (Z15–Z17).
8. **Ruch przy przewijaniu łamie wprost listę „Never” skilla** na 8 z 8 stronach: od 4 do 50 bloków odsłanianych przy przewijaniu. Zatwierdził to jednak §14.2 (K4). W Safari < 26 i Firefoksie rezerwa IntersectionObserver robi z tego klasyczny fade-in czasowy, czyli dokładnie to, czego skill zabrania (K4). Efekty spoza zatwierdzonej listy można zdjąć bez decyzji: paralaksę zdjęcia hero, dryf cyfr rozdziałów, linię postępu w nagłówku i 3,6-sekundowe wejście (Z19, Z20).
9. **Prawo ma pierwszeństwo przed regułami 9 i 1.** Zostają: dane agenta i spółki (KRS, NIP, REGON, kapitał, numer RPU, adres do reklamacji, telefon), kontakt do IOD oraz zastrzeżenie „Symulacja, nie oferta”. W raporcie bramki skilla zapisujemy je jako uchylenia z powodem prawnym (K5, K9). Nazwę roli („doradca” albo „agent”) trzeba ustalić z prawnikiem (K12).
10. **Przegląd obejmuje wszystkie 4 wymiary.** Wszystkie 59 ustaleń audytów ruchu i treści są w rozdz. 4–6 albo w rozdz. 8 (scalone lub odrzucone). Otwarte zostaje tylko to, czego bez kitu nie da się sprawdzić: progi, listy copy-lint, rozdanie i bramka (N1–N12).

## 4. Z – do wdrożenia bez zmiany kierunku

Priorytet: **P1** to pierwszy ekran albo dostępność, przed kolejną prezentacją. **P2** to najbliższe przejście poprawek. **P3** to wdrożenie produkcyjne. Wysiłek: **S** do 2 godzin, **M** do 1 dnia, **L** ponad 1 dzień. Wspólne komponenty zmienia się tylko generatorami: `gen_wspolne.py` (menu, szuflada, pasek akcji), `slownik/gen_strona.py` (słownik), `slownik/gen_terminy.py` (dymki), `opieka-medyczna/build.py` (cała strona opieki) i `gen_oc_beauty.py` (bloki `GEN:` strony OC i jej JSON-LD) (§17, §18). Po zmianie każdy generator uruchamia się z `--check`.

| # | Co zmienić | Gdzie, szerokość | Pomiar | Reguła skilla | Prio | Wysiłek |
|---|---|---|---|---|---|---|
| Z1 | Hero podstron na dokładnie 1 ekran: `.page-hero{min-height:100svh}`, mniejszy `padding-top` (dziś `clamp(124px,13vw,172px)`), panel zakotwiczony tak, żeby dół panelu wypadał najwyżej 24 px nad dolną krawędzią okna | 7 podstron, `section.page-hero`; 820×1180, 768×1024, 1440×900, 1024×768 | ✔ Przy 820: hero 0,69–0,81 ekranu, następna sekcja wystaje 227–364 px, jej H2 na 1. ekranie na 6 stronach (np. OC `#zabiegi` H2 na 976 px przy oknie 1180). Przy 768: 0,78–0,94 ekranu. ✔ Przy 1440 dół panelu: OC 917, UD 956, NNW 1041, ERGO 978, opieka 1012, słownik 947 (Tax 885 mieści się). Zrzuty: `v1-oc-820x1180.png`, `v5-nnw-1440x900.png` | reguła 3; [hero-screen, hero-fill, fold-cut] {hero-fold} | P1 | M |
| Z2 | Telefon: główny przycisk w pierwszym ekranie. Krótszy lead (drugie zdanie i `.hero-note` pod przyciski), mniejszy H1, okruszki zwinięte do „‹ Ubezpieczenia”, przyciski przed `dl.figures` | 8 stron, `.hero-actions a.btn`; 320×640, NNW także 390×844 | ✔ Dół 1. przycisku przy oknie 640 px: home 754, OC 845, Tax 923, UD 893, NNW 1007, opieka 874, słownik 903. Hero 1,85–2,37 ekranu. ✔ NNW przy 390: przycisk na 826–876 px, ucięty przez krawędź 844. Zrzut: `v2-nnw-390x844.png` | [fold-action, fold-cut] | P1 | M |
| Z3 | Równe krawędzie panelu hero przy 320: `.hero-panel{grid-template-columns:minmax(0,1fr)}`, `.figures dd` zawija się poniżej 360 px. To samo dla `.member-card` | home, OC, UD (karta w `#strefa-klienta`); 320×640 | ✔ Panel 16..304 px. Treść: home 45..304 (lewy odstęp 29, prawy 0), OC 43..310 (prawy −6), UD 43..309 (prawy −5). Przy 390 odstępy symetryczne (29/29, 27/27). Kolumna siatki ma min-content 259–267 px. Zrzuty: `v3-*-320.png` | reguła 4; {edge-right, spill} | P1 | S |
| Z4 | Cele dotyku w słowniku: `.haslo-linki a{min-height:44px}`, odstęp między wierszami ≥ 8 px. Indeks A–Z: komórki ≥ 44 px, `gap` 8 px. Zmiana w `gen_strona.py` | `slownik.html`; 390×844, 320×640 | ✔ 485 linków po 32–42 px, `gap: 0 18px`, więc 430 celów ma inny cel bliżej niż 8 px. ✔ A–Z: 20 liter 32×40 px przy `gap` 4 px | [tap-size] (FAIL) | P1 | S |
| Z5 | Cele dotyku z WARN: 44 px przy `pointer:coarse` dla okruszków, `summary` „Informacje o agencie…”, `a.z-inna`, terminów `bp-termin` w wierszach. Projekt przyjął próg ≥ 24 px (§17.4). Skill jest surowszy, ale nie ma tu konfliktu | 7 podstron, stopka 8 stron, OC, UD, ERGO; 390, 320 | – Okruszki 102×32 px. `summary` 300×24 px. OC: 40 odsyłaczy po 24 px. ERGO: terminy 21 px | [tap-size] (WARN) | P3 | S |
| Z6 | Hero ERGO: dwie drogi z D36 jako dwie akcje z czasownikiem w parze `.btn`, np. „Wybierz ubezpieczenie dla salonu” i „Wybierz ERGO Razem dla rodziny”. Link „Porównaj je w skrócie” przenieść pod hero | `grupowe-ergo`, hero `nav.choice`; wszystkie szerokości | ✔ 0 elementów `.btn` w hero przy 1440 i 390. ✔ W hero 3 akcje: 2 karty-linki bez czasownika („Dla salonu z zespołem…”, „Dla Ciebie i Twojej rodziny…”, promień 6 px, bez wersalików, inaczej niż `.btn`) i link „Porównaj je w skrócie” na 898 px przy oknie 900 px | [fold-action, action-count, copy-buttons] | P2 | S |
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
| Z19 | Usunąć paralaksę zdjęcia hero i dryf cyfr rozdziałów, razem z rezerwą rAF (`--hero-y`, `--drift-y`). Nie ma ich na liście efektów §14.2. Linię postępu czytania w nagłówku usunąć albo zapisać w §14.2 jako jedyny wyjątek nawigacyjny | home `.hero-media` (`hero-par`, `scroll(root)`); `.chapter-no` (`drift`, `view()`) na 7 stronach; `.header-bar::after` na 8 stronach | ✔ Oba efekty działają przy 1440. Przy ograniczonym ruchu są wyłączone. ✔ Linia postępu: animacja `draw` na `ScrollTimeline`, `scaleX` 0 → 0,035 → 0,106 → 0,31 przy przewinięciu 0, 450, 1350 i 4000 px (home; OC podobnie) | §6 Never „parallax on text”; [scroll-linked] | P2 | S |
| Z20 | Wejście hero zgodne z §14.2: najwyżej 1,15 s, tylko ozdoby. Skrócić `hero-zoom`, zdjąć `note-in` z liczb i z paska partnerów | home | ✔ `hero-zoom` na zdjęciu 3,6 s, `dl.figures` do 1,25 s, `.partners` do 1,65 s. H1 i lead nie są animowane. Skill tego nie zabrania („enters once”), ale jest to niespójne z dokumentem 10 | §14.2 dok. 10; [hero-enter] | P3 | S |
| Z21 | Karta Strefy Klienta: `rotate:0`, przy hover tylko uniesienie o 2 px. Promień 6 px jak reszta kart. Usunąć `figcaption` „Dane przykładowe”, bo dane mają już dopisek „(przykład)” (§14.1) | home `figure.member-card`; wszystkie szerokości | ✔ `rotate: -1.5deg` także po wyłączeniu animacji. ✔ Na hover karta prostuje się (`rotate: 0deg`) i unosi o 4 px. ✔ Promień 10 px, jedyny poza skalą 2/3/6 px. ✔ Podpis widoczny | reguła 5 „No tilt”; reguła 1; [tilt, hover-move, visual-caption, radius] | P3 | S |
| Z22 | Pasek akcji chowa się nad formularzami spoza listy: `form#calc`, `.zsearch`, `#spec-form` (ten sam IntersectionObserver). Zmiana w `gen_wspolne.py` | home, OC, opieka; 390, 320 | ✔ Przy 320×640 i przewinięciu 8704 px pasek leży nad `form#calc`. Zrzut: `v-bar-calc-320.png`. – OC i opieka według audytu | [collide] | P3 | S |
| Z23 | Struktura `main > section`. Tło sceny przenieść na sekcje, zachowując jeden marmur bez szwu (§8 pkt 5, §10). `#na-otwarcie` przenieść na poziom `main` | home | ✔ Dzieci `main`: 3 sekcje i 3 `div.scene`. 7 sekcji nie jest bezpośrednim dzieckiem `main` | §4 krok 5 | P3 | M |
| Z24 | Head: `og:image` (1200×630, kadr hero albo martwej natury, bez tekstu w obrazie) z `og:image:alt`, `twitter:card=summary_large_image`, `link rel=icon` i `apple-touch-icon` z logo. Do tego deklaracja rodzaju: `data-type="service"`, `meta page-type`, `meta site-kind`. W produkcji przez metadata Next.js | 8 stron | ✔ Na 8 z 8 stron brak `og:image`, `og:image:alt`, `twitter:card`, `link rel=icon`, `apple-touch-icon` i deklaracji rodzaju. `og:title` i `canonical` są | §1; [share-meta, page-meta] | P3 | S |
| Z25 | Logo w SVG, a do tego czasu PNG 320×48 (§14.5, §13 Q1) | nagłówek i stopka 8 stron | ✔ Plik 3000×450 px wyświetlany w 160×24 px | [photo-weight] | P3 | S |
| Z26 | Notatki makiety `.mock-note` usunąć przy wdrożeniu, po rozstrzygnięciu każdego założenia. Przed publikacją uzupełnić też widoczne miejsca „do uzupełnienia” i „do potwierdzenia”. W makiecie notki można zebrać w przełączanym trybie podglądu | home 6, OC 0, Tax 4, UD 2, NNW 4, ERGO 25, opieka 52, słownik 22; home `#kontakt`, hero opieki | ✔ Liczby z weryfikacji (audyt podał 54 dla opieki). ✔ Na home w `#kontakt` widoczny nawias „[Telefon i e-mail biura Aura Expert – do uzupełnienia przed publikacją.]”. ✔ W hero opieki przy 1440 widoczna notka „do potwierdzenia (przykładowe stawki od 3 osób)”. Zrzut: `u-opieka-medyczna-1440-ekran1.png` | [placeholder, sample-label]; copy-residue | P3 | S |
| Z27 | Podkreślenia linków w nawigacji, stopce, FAQ i nazwach kafli rysowane zamiast pojawiać się skokiem. Do tego posłuży istniejący idiom złotej linii (`background-size` albo `::after` ze `scaleX`, 0,3–0,5 s). `link-quiet` na hover z pogrubionym albo rysowanym podkreśleniem, logo ze zmianą krycia. Reguły hover nawigacji i stopki są dziś w CSS każdej strony, więc zmienić je w jednym miejscu (`tokens-v3.css` albo blok `gen:wspolne-css` w `gen_wspolne.py`) | 8 stron; 1440 | ✔ `a.link-quiet` i logo `a.brand`: 0 zmian stylu po 80 i 800 ms od najechania, `transition: all 0s` (home, OC, słownik). ✔ Podkreślenie skokiem, `none → underline` już po 80 ms: `.main-nav a`, `.footer-nav a`, `.faq summary`, `a.product-link` | reguła 5 „underlines draw”; Motion [hover]; [link-styles] | P3 | S |
| Z28 | Kontrast końcowej karty słownika: `div.end-card` dostaje modyfikator `dark`, jak na 6 podstronach. Zmiana w `slownik/gen_strona.py` (szablon karty), potem `--check` i ponowny pomiar przy 1440, 1024 i 390 | `slownik.html`, `section.sl-end`; 1440, 1024, 390 | ✔ H2 w kolorze navy na gradiencie navy → midnight: mediana 1,19:1 (1440), 1,20:1 (1024) i 1,16:1 (390), a wymagane jest 3:1. Eyebrow taupe 12 px: 1,67–1,80:1 wobec wymaganych 4,5:1. Ta sama karta na OC (`end-card dark`): H2 11,66:1. Zrzut: `u-slownik-end-1440.png` | [text-contrast]; WCAG 1.4.3 (dok. 07) | P1 | S |
| Z29 | Telefon: jeden twardy fakt w pierwszym ekranie. Kwotę wpleść w lead hero: home „OC od 400 zł rocznie”, Tax „od 1 532 zł rocznie”, UD np. „świadczenie do 50 000 zł miesięcznie” (próg 80% dotyczy tylko działalności i B2B, więc bez niego albo z oboma progami, Z31). Kwoty stałe z taryf, bez „orientacyjnie”. Robić razem z Z2, które skraca lead | home, UD, Tax; 390×844 | ✔ W pierwszym ekranie przy 390: na home tylko „w dwie minuty”, bo liczby panelu są pod zgięciem. UD i Tax bez żadnej kwoty. Przy 1440 kwota jest na wszystkich trzech. Zrzuty: `u-makieta-v3-390-ekran1.png`, `u-utrata-dochodu-390-ekran1.png`, `u-tax-protect-390-ekran1.png` | §4 krok 2; [copy-fact] | P1 | S |
| Z30 | Jedna droga do polisy: te same kroki na home, OC i Tax. Bez zmiany §8 (pkt 6: „trzy kroki”) wszędzie 3 kroki o nazwach ze strony głównej, z krokiem 1 w brzmieniu z Z33. E-mail z osobistym linkiem (D32) opisać w kroku 2. Druga możliwość to 4 kroki wszędzie, co wymaga dopisku w §8 | home `#jak-to-dziala`; OC i Tax `#jak-kupic`; wszystkie | ✔ Home: H2 „Od składki do polisy w trzech krokach”, kroki „Policz składkę”, „Zostaw kontakt”, „Podpisz i odbierz polisę”. OC: „…w czterech krokach”: „Kalkulator albo formularz”, „E-mail od doradcy”, „Analiza potrzeb, wniosek i podpis”, „Polisa”. Tax: 4 kroki o jeszcze innych nazwach („Kalkulator albo kontakt”, „Kontakt doradcy”, „Wniosek”, „Polisa”) | [fact-agree] | P2 | S |
| Z31 | UD bez zawężania odbiorców do samozatrudnionych (§16). Lead hero np. „Prywatne L4 dla pracujących w beauty – na działalności, B2B i na etacie”. To samo w danych strukturalnych: `alternateName` na UD i opis UD w JSON-LD strony głównej (źródła: `snippets/schema-home.json`, `snippets/llms.txt`) | UD hero `p.lead` i JSON-LD; home JSON-LD; wszystkie | ✔ Lead hero UD: „Prywatne L4 dla samozatrudnionych w beauty…”. Kafel na home: „…przy działalności, B2B i na etacie”. Fraza „dla samozatrudnionych” jest też w `alternateName` UD i w JSON-LD strony głównej | [fact-agree]; §16 dok. 10 | P2 | S |
| Z32 | Jedna nazwa produktu z listy `PRODUKTY` (§17). ERGO: `title`, H1 i okruszki z nazwą „Grupowe ERGO dla beauty”. Fraza „ubezpieczenie na życie” może zostać w drugiej części H1, np. „Grupowe ERGO dla beauty – ubezpieczenie na życie dla salonu i rodziny”. Do tego „NNW dzieci” → „NNW dla dzieci” (opieka przez `build.py`), „OC beauty” w H2 FAQ → „OC dla branży beauty” | ERGO head i hero; home `#faq`; OC `#faq`; opieka `#powiazane`; wszystkie | ✔ ERGO: `title`, H1 i okruszki zaczynają się od „Ubezpieczenie na życie ERGO”, a menu, kafle i stopki mówią „Grupowe ERGO dla beauty”. ✔ „NNW dzieci”: home 1×, opieka 1× (karta powiązana). ✔ „OC beauty”: home 1×, OC 1×, słownik 7× | [fact-agree]; §17 dok. 10 | P2 | S |
| Z33 | Jedno brzmienie każdej akcji. Kalkulator: „Oblicz składkę OC” i „Oblicz składkę Tax Protect” w hero, kaflach, krokach i zakończeniach, czyli tak, jak już mówią szuflada i pasek akcji z `gen_wspolne.py`. Kontakt: „Zapytaj doradcę”, temat w tekście dla czytników (sr-only), jak w kaflach. Jedno brzmienie przycisku wysyłki formularza. Szkoda: „Zgłoś szkodę”, jak w stopce. Etykiety bez czasownika z czasownikiem: „Pokaż treść klauzuli”, „Wypełnij formularz” | 8 stron; wszystkie | ✔ Kalkulator: „Oblicz składkę OC” (home), „Policz składkę” (OC), „Policz w kalkulatorze” (Tax), „Policz składkę Tax Protect” (UD), a na OC przy 390 pasek akcji mówi „Oblicz składkę”. ✔ Kontakt: „Zapytaj doradcę”, „Zamów rozmowę” (UD 2×), „Formularz”, „napisz do nas”, „Napisz przez formularz”, czyli 5 brzmień (audyt podał co najmniej 6). ✔ Wysyłka: „Wyślij zgłoszenie” (home), „Wyślij zapytanie” (opieka). ✔ „Jak zgłosić szkodę” (home 3×) wobec „Zgłoś szkodę” w stopce | [fact-agree, copy-buttons] | P2 | S |
| Z34 | Ta sama akcja najwyżej 2 razy na ekran. Opieka `#ceny`: jedna akcja pod obiema kartami („Zapytaj doradcę o cenę”), wybór sieci jako temat w formularzu, bez linku w akapicie. Hero opieki: zdanie z linkiem „Zapytaj doradcę o możliwość” przenieść do `#dla-kogo` albo FAQ. OC `#jak-kupic`: jeden link do formularza, w akapitach odesłanie bez linku. Opieka przez `opieka-medyczna/build.py` | opieka `#ceny` i hero; OC `#jak-kupic`; 1440, 390 | ✔ Opieka `#ceny` przy 1440: 4 akcje do `#zapytanie` w jednym ekranie (2 przyciski w kartach, „Zapytaj doradcę o cenę”, link w akapicie), przy 390: 3. ✔ Hero opieki: 3 akcje (2 przyciski i link 75 px niżej). Z przyciskiem w nagłówku to 3× „Zapytaj doradcę” na 1. ekranie. ✔ OC `#jak-kupic`: 3 linki do `#kontakt` w 3 brzmieniach w jednym ekranie. Zrzut: `u-opieka-medyczna-1440-ekran1.png` | [action-repeat, action-count] | P2 | S |
| Z35 | Karta opieki medycznej w „Inne ubezpieczenia” na 5 podstronach. Od 15.11.2026 opieka ma podstronę (§17.5), a menu i stopki już do niej prowadzą | OC, Tax, UD, NNW, ERGO `#powiazane`; wszystkie | ✔ Na 5 podstronach są 4 karty, bez opieki. Opieka ma 5 kart. Audyt zauważył brak tylko na ERGO | [fact-agree]; §17.5 dok. 10 | P2 | S |
| Z36 | Słowa i nagłówki. H2 „Sześć rozwiązań. Jeden doradca.” i lead „Każde rozwiązanie…” wrócić do brzmienia z §8 („Sześć ubezpieczeń…”). Usunąć „kompleksową ochronę” i zamiast niej wymienić zakres (zgon, poważne zachorowanie, pobyt w szpitalu). Zostawić jedno z trzech „w jednym miejscu”, usunąć „prostych”. Nagłówki bez rzeczownika nazwać, np. „Świadczenie a zasiłek z ZUS”, „Najczęstsze przyczyny niezdolności do pracy”, „Zakres i wyłączenia”, „Ważne warunki”, „Porównanie: salon czy rodzina”. Liczbę na początku nagłówka zostawić tam, gdzie jest faktem (warianty, kroki). H1 Tax i NNW z kupującym, np. „Tax Protect – ochrona salonu w sporach z fiskusem”. Dwa nagłówki z §8 są w K10 | home, UD, NNW, Tax, ERGO, opieka; wszystkie | ✔ „rozwiązanie/rozwiązań” 2× na home, a §8 ma „Sześć ubezpieczeń”. ✔ „Kompleksowa ochrona” 2× (ERGO), „w jednym miejscu” 3× (home). ✔ Poza dwoma nagłówkami z §8 jest 9 brzmień bez rzeczownika w 11 nagłówkach: UD 5, NNW 3, Tax, ERGO i opieka po 1; „O czym pamiętać” 3×. Audyt podał 10 brzmień w 13 nagłówkach razem z §8. ✔ 12 nagłówków zaczyna się od liczby (audyt: 11). ✔ H1 Tax i NNW bez kupującego | [copy-headings, copy-headline, copy-slop-word, copy-stock-phrase]; §8 dok. 10 | P2 | M |
| Z37 | Jedna skala nagłówków według §4. Tokeny: `--text-h1` do 80 px (dziś 84), `--text-h2` do 54 px (dziś 68), H3 26 px. Usunąć lokalne rozmiary H3 i H4 w CSS stron. H3 promocji `#na-otwarcie` (48 px) jako H2 sekcji albo w rozmiarze H3. Robić przed Z10, bo zmienia wysokości sekcji. Strony z generatorów (OC, opieka, słownik) przez generatory | `tokens-v3.css` i CSS 8 stron; 1440, 390 | ✔ Przy 1440: H1 ma 2 rozmiary (70,4 i 84 px), H2 5 (41,6 / 52 / 52,8 / 57,6 / 68 px), H3 13 (23,2–48 px), H4 3 (23,2–28,8 px). ✔ ERGO: H4 do 28,8 px przy H3 27,2 px. Home: H3 promocji 48 px przy H2 `#szkoda` 41,6 px. ✔ Tokeny `clamp(…, 5.25rem)` i `clamp(…, 4.25rem)` wobec „H1 44–80 px, H2 34–54 px” w §4. Przy 390: H2 4 rozmiary, H3 8 | One system [heading-scale]; §4 dok. 10 | P2 | M |
| Z38 | Jedna karta pełna i jedna notka: ivory, złota linia 1 px, jeden cień albo żaden, oraz notka z lewą złotą kreską. Cztery warianty szkła z D14 bez zmian | 8 stron, `main`; wszystkie | ✔ Poza szkłem 6 wyglądów kart: ivory + złota ramka 35% + cień (`li.job`, `.route`, `.sl-litera`); ivory + ramka 50% bez cienia (`.rel-card`, `.panel`, `.vcard`); ivory bez ramki z cieniem (`.scope-card`, `.clause`, `.ledger` na UD, `.apply`, `.op-card`); ivory + ramka 50% + cień (`.sl-narzedzia`); przezroczysta z ramką (`.mind`); notka z lewą kreską 2 px (`.scope-extra`, `.scope-aside`, `.haslo-przyklad`) | One system [card-family, card-layout] | P3 | M |
| Z39 | Jeden zestaw elementów w roli przycisku: para `.btn` dla akcji, jeden styl chipa dla nawigacji po liście i filtrów oraz jeden wygląd linku-akcji (bez etykiet z kreską „KALKULATOR ——”). Linki w tekście: jeden token podkreślenia na jasnym tle i jeden na ciemnym, a taupe i ink zastąpić granatem | 8 stron; wszystkie | ✔ Para `.btn` jest spójna (3 px, wersaliki): navy i ghost na jasnym, ivory i ghost-dark na ciemnym. Do tego 4 inne style: chipy z tłem białym 55% i złotą ramką bez wersalików (20×), chipy list na OC z ramką navy i wersalikami (4×), przyciski ivory ze złotą ramką (5×), karty wyboru ERGO z promieniem 6 px (2×). – Linki w tekście: według audytu 13 wyglądów, w tym co najmniej 8 na jasnym tle | One system [button-styles, button-shape, link-styles] | P3 | M |
| Z40 | Te same fakty cenowe tymi samymi słowami. NNW: wszędzie „za osobę” albo „za dziecko lub studenta”, także w liście `PRODUKTY` (`gen_wspolne.py`), w kaflu i w §16–§17. Sumy OC z jednym spójnikiem: „100, 200 albo 300 tys. zł”. Zakres „100–300 tys. zł” w liczbach hero zostaje (§8) | menu i kafel (8 stron), karty powiązane, NNW, home, OC, słownik | ✔ „od 40 zł rocznie za dziecko” w menu i kaflu, a „40, 94 albo 175 zł za osobę” w kartach powiązanych 5 podstron i „…lub 175 zł za osobę” na NNW. Polisa obejmuje też studentów (krok „Ubezpieczenie dziecka/studenta”). ✔ Sumy: „100, 200 lub 300” (home, OC) i „100, 200 albo 300” (słownik) | [fact-agree] | P3 | S |
| Z41 | Szuflada menu poniżej 768 px: widoczny stan otwarcia (ikona zamknięcia, etykieta „Zamknij”) i pełny ekran (`inset: 0`, tło ivory, bez `backdrop-filter`). Wzorzec `details/summary` z §17.2 zostaje. Zmiana w `gen_wspolne.py` | 8 stron, `details.menu`; 390 | ✔ Brak reguły dla `.menu[open]`. Ikona to ta sama ścieżka dwóch linii w obu stanach. Panel ma 356×740 px w oknie 390×844, czyli 80% powierzchni. Zrzut: `u-menu-makieta-v3-390.png` | Keyboard and head [menu-toggle]; checklista 390 „a full-screen menu” | P3 | S |

## 5. K – konflikty z zatwierdzonym kierunkiem v3 lub z prawem

| # | Konflikt | Reguła skilla | Decyzja albo przepis | Pomiar | Warianty do decyzji | Rekomendacja |
|---|---|---|---|---|---|---|
| K1 | **Szkło, tekstury, ziarno i ciemne sceny wobec płaskich teł** | §1 („CSS grounds, dark pages… tech only”), §2 („flat grounds and one brand band”, „no… grain, gradient”), reguła 6; [grounds, effect-kind, photo-repeat] | D14 („całość w szkle”), §1 („całość glass morph”), §6, plan scen §8, ziarno w §14.2 | – Home: 5 scen z teksturą, 11 tafli z `backdrop-filter`. Podstrony: 2–3 sceny, 3–5 tafli. Dwa pliki tekstur w 24 miejscach. ✔ Ziarno przy 1440 na 8 z 8 stron, przy 768 nigdzie. ✔ Ciemne bloki to 39,3% wysokości strony głównej (podstrony około 14–16%). – [nesting]: złota ramka `.frame` tworzy trzecią warstwę w kalkulatorze (szkło → ramka → opcja albo panel wyniku), w formularzu opieki i w wyróżnionej kolumnie `.op-card`. Bez ramki zagnieżdżenie ma najwyżej 2 poziomy | **A.** V3 bez zmian, odstępstwa wpisane w raport jako uchylenia. **B.** Hybryda: szkło w nagłówku, panelu hero i stopce, tekstury tylko w hero i stopce, reszta na płaskim ivory i pergaminie z jednym granatowym pasem. Ziarno wyłączone, `.promo` na jasnym tle. **C.** Pełna zgodność: płaskie tokeny, jeden pas marki i ciemna stopka. Oznacza zmianę D14 i ponowną akceptację kierunku | **A** z poprawkami Z15–Z17. Zleceniodawca sam zażądał „całości w szkle” po odrzuceniu v2. B tylko wtedy, gdy celem ma być zgodność z tasteskill |
| K2 | **Zdjęcia z AI bez ludzi wobec zasady „photographs lead: people, rooms, work”** | §2, reguła 6, §6 Never (stock podany jako własny); [photo-set] | §2 dok. 10 (brief marki „bez twarzy”), §7 (Bloom), §13 Q2 (otwarte: AI czy sesja) | ✔ 2 zdjęcia treści w serwisie, oba na stronie głównej (hero jako `<img>`, CTA jako tło). Na 7 podstronach 0 zdjęć | **A.** Sesja w prawdziwym salonie w stylu v3, bez twarzy: dłonie przy pracy, stanowiska, narzędzia. **B.** Licencjonowane zdjęcia zastępcze, wykazane jako zastępcze. **C.** Zostają zdjęcia z AI z zapisaną akceptacją zleceniodawcy. Zdjęcia z twarzami wymagałyby zmiany briefu marki | **A**. Zamyka Q2 i daje materiał do Z7 i Z13 |
| K3 | **Rysowane ikony i brak logotypów wobec „real full-colour icons”** | reguła 7; §3 (dla usługi: „tools really used”); §6 (cudze logo w jego kolorach) | D14 (ikony z Bloom, jeden kolor); komentarz w kodzie: zgody na nazwy i logotypy partnerów do potwierdzenia | – 23 ikony konturowe w kolorze `currentColor`, 0 ikon kolorowych. Partnerzy w hero zapisani tekstem szeryfowym | **A.** Ikony produktów i zawodów zostają (to nie „narzędzia”). Po uzyskaniu zgód oryginalne logotypy ubezpieczycieli w pasku partnerów, na kartach i przy „Kup online u Colonnade”. **B.** Zostaje tekst | **A** po uzyskaniu zgód, do tego czasu B |
| K4 | **Odsłanianie bloków przy przewijaniu** | §6 Never: „A card, row or tile that fades in on scroll; a fade-in on every section”; checklista Motion [scroll-reveal, scroll-linked] (dozwolone tylko w rozdanym momencie) | §14.2: ruch sterowany przewijaniem (kurtyny nagłówków, złote linie, odsłonięcie martwej natury) | ✔ Bloki `.rv-*`: 50/19/18/33/18/22/26/4 (home, OC, Tax, UD, NNW, ERGO, opieka, słownik). ✔ Animacje na osi przewijania: 121/49/46/83/46/54/68/10. – Przy ograniczonym ruchu nic się nie rusza i nic nie zostaje ukryte (16 z 16). ✔ Rezerwa bez `animation-timeline` (Safari < 26, Firefox; emulacja w Chromium): na starcie ukrytych jest 50 z 60 bloków na home i 19 z 25 na OC. Po dojściu do bloku krycie rośnie 0 → 0,74 → 0,96 → 1 po 50, 300, 600 i 1000 ms, a przesunięcie maleje z 41 px do 0, niezależnie od tempa przewijania. To czasowy fade-in | **A.** Bez zmian, z uchyleniem. **B.** 1–2 momenty na stronę, zgodnie ze skillem. Na stronie głównej „Jeden dzień w salonie” (moment typograficzny, bliski pinned-chapters dla usług) i odsłonięcie martwej natury. Na podstronie jeden moment typograficzny. Bez odsłaniania kart, wierszy, kafli i kurtyn nagłówków. **C.** Brak ruchu przy przewijaniu. Przy każdym wariancie można zdjąć rezerwę IntersectionObserver: w przeglądarce bez `animation-timeline` treść jest wtedy od razu widoczna, tak jak §14.2 przewiduje bez JS | **B**, bez rezerwy IntersectionObserver. Zachowuje filmowe tempo z §14 w dwóch miejscach, zdejmuje „fade-in on every section” (także czasowy w Safari i Firefoksie) i odciąża przeglądarkę |
| K5 | **Reguła 9 wobec obowiązków informacyjnych agenta** | reguła 9 (bez numeru domu, kodu, numerów rejestrowych i telefonu w prawdziwym formacie, kontakty w `.example`); [street-number, postcode, company-number, phone-number] | art. 22–23 ustawy o dystrybucji ubezpieczeń; art. 206 § 1 KSH (dane spółki na stronie internetowej); art. 13 ust. 1 lit. b RODO (kontakt do IOD); D37 (informacje o agencie, adres do reklamacji, telefon); §17.3 (telefon w pasku akcji); §15 (KRS, NIP, REGON i numer RPU w stopce) | ✔ Na każdej stronie 3 linki `tel:` (na opiece 7), KRS 1 raz, numer RPU 5–9 razy. Kod pocztowy, NIP, REGON i kapitał w stopce. 0 adresów `.example`. ✔ Widoczne adresy e-mail (IOD i reklamacje): home 2, OC 1, Tax 1, UD 1, NNW 1, ERGO 1, opieka 2, słownik 3. – W JSON-LD: `postalCode`, `streetAddress` z numerem lokalu, `taxID` i identyfikatory rejestrowe | **A.** Dane zostają, w raporcie bramki zapisane jako uchylenie reguły 9 z powodem prawnym. JSON-LD zostaje (wyszukiwarki, zgodność z notą prawną) i też dostaje uchylenie. **B.** W stopce tylko skrót, pełna formuła na `/informacje-prawne` (to już przewiduje §15). Numer RPU i dane podmiotu zostają w obu miejscach | **A** (z B zgodnie z §15). Reguła 9 chroni przed zmyślonymi, „prawdziwie wyglądającymi” danymi na stronach demonstracyjnych. Tu dane są prawdziwe i wymagane |
| K6 | **Jedna sekcja na ekran wobec stron-dokumentów i długich tabel** | reguła 3 („every section exactly one or two screens”); [section-height] {screen-height} | D29 i D43 (listy zabiegów 1:1 z Aneksu nr 5, z kotwicami), D30 (klauzula dosłownie w `#ochrona-prawna`), §18 (95 haseł słownika) | ✔ Przy 1440: OC `#zabiegi` 5,93 ekranu, `#ochrona-prawna` 4,01. Słownik `#hasla` 58,07 ekranu, z 20 nagłówkami H2 liter w jednej sekcji. – Przy 320: `#zabiegi` 18,07, `#hasla` 151,9. Tabele świadczeń i taryf poza decyzjami (ERGO `#dla-salonu`, opieka `#ceny`) są w Z9 | **A.** Wyjątek od reguły 3 dla stron-dokumentów (listy OC, klauzula, słownik). **B.** Podział bez zmiany treści: lista 1, lista 2 i ankieta z podologią jako osobne `main > section`. Klauzula: wprowadzenie i fakty na 1 ekranie, pełna treść w `<details>` (zmienia sposób pokazania z D30). Słownik: każda litera jako sekcja. **C.** Pełne listy na osobnej stronie-dokumencie, na stronie OC tylko wyszukiwarka i nawigacja | **B dla list OC** (D29 i D43 się nie zmieniają). **A dla słownika i klauzuli**, chyba że zleceniodawca zgodzi się na `<details>` przy klauzuli |
| K7 | **Etykiety rozdziałów przed H2** | checklista: „its h2 first” [one-heading] | §14.1 (rozdziały I–VII w etykietach sekcji) | – `p.eyebrow` jest pierwszym elementem w 54 z 54 sekcji. Pierwszym nagłówkiem jest wszędzie H2 | **A.** Bez zmian. **B.** Etykieta jako `span` wewnątrz H2 (zmienia się nazwa dostępna). **C.** Etykieta pod H2 | **A**. Niska waga, a bez kitu nie wiadomo, czy [one-heading] liczy element niebędący nagłówkiem (N) |
| K8 | **Kafle produktów bez uniesienia na hover** | reguła 5 („a linked card lifts 2px”) | §16 (stany hover: tło, podkreślenie nazwy, przesunięcie szewronu); §14.3 (produkty jako jedna tafla z liniami włoskowymi) | ✔ Przy hover kafel przesuwa się o 0 px. Przejście dotyczy tylko `background-color 0.3s` | **A.** Bez zmian. **B.** Uniesienie o 2 px z cieniem. Rozbija „jedną taflę” z §14.3 | **A** |
| K9 | **Zastrzeżenie pod wykresem UD** | reguła 1 (bez podpisu pod obrazem); [visual-caption, caption] | rzetelna, jasna i niewprowadzająca w błąd informacja dystrybutora (art. 17 ustawy o dystrybucji ubezpieczeń); treść z utratadochodu.pl (D33) | ✔ `figcaption` „Symulacja, nie oferta…” pod wykresem 3 słupków, widoczny przy każdej szerokości | **A.** `figcaption` zostaje (uchylenie). **B.** To samo zdanie jako akapit obok wykresu, nie jako `figcaption`, równie widoczne | **B**. Spełnia oba wymagania, wysiłek S |
| K10 | **Brzmienia z §4 i §8 wobec reguł tekstu** | [copy-headline] (H1 nazywa kategorię i kupującego), [copy-slop-word], [copy-headings] (rzeczownik w każdym nagłówku), [run-on] (druga, wyróżniona połowa nagłówka to osobne zdanie) | §4 i §8 pkt 2, 5 i 7: H1 „Ochrona szyta *na miarę* Twojego salonu”, H2 „Znamy specyfikę *Twojej pracy*”, baner „Coś się wydarzyło w salonie?”, kursywa jako akcent w tytule | ✔ H1 nie nazywa kategorii (jest ona tylko w eyebrow „OC dla salonów beauty · program z ERGO Hestią”), a „szyta na miarę” jest na liście fraz szablonowych audytu. ✔ Oba nagłówki z §8 bez rzeczownika nazywającego temat. – Kursywa w 57 ze 114 H1 i H2, zwykle jako dalszy ciąg zdania („Sprawdź składkę *w dwie minuty*”) | **A.** Bez zmian, z uchyleniem. **B.** H1 z kategorią i kupującym, np. „Ubezpieczenie OC *dla salonu beauty*”. H2 nazywające rzecz, np. „Osiem profili w programie OC”, „Zgłoszenie szkody z OC”. Kursywa bez zmian. **C.** B, a do tego kursywa tylko na drugim pełnym zdaniu, jak w H2 słownika | **B**. Nazwa kategorii w H1 pomaga też w wyszukiwarce. Kursywa jest znakiem rozpoznawczym v3, więc C tylko przy pełnej zgodności ze skillem |
| K11 | **Druga akcja w kafelkach produktów** | [action-repeat] („one action twice a screen at most”) | §16: każdy kafelek ma nazwę-link i jedną akcję; dla UD, ERGO i opieki „Zapytaj doradcę” z tematem w nazwie dostępnej | ✔ Przy 1440 w jednym ekranie: 3× „Zapytaj doradcę” (UD, ERGO, opieka) i 2× „Oblicz składkę”. Gdy widać nagłówek, dochodzi czwarte „Zapytaj doradcę”. Audyt liczył je zawsze, ale nagłówek chowa się przy przewijaniu w dół (§14.2) | **A.** Bez zmian, z uchyleniem. **B.** Kafle bez akcji transakcyjnej (UD, ERGO, opieka) tylko z nazwą-linkiem. **C.** Jedno „Zapytaj doradcę” pod całą taflą, produkt wybierany w formularzu | **A**. Każda akcja ma inny temat, a §16 świadomie dał każdemu kafelkowi jedną akcję. B, jeśli celem ma być zgodność z tasteskill |
| K12 | **„Doradca” czy „agent”: jedna nazwa roli** | [fact-agree] (jedna nazwa tej samej rzeczy) | art. 22–23 ustawy o dystrybucji ubezpieczeń (status agenta). Słownik sam zapisuje, że to, „czy nazwa ‘doradca’ nie sugeruje niezależnego doradztwa”, jest do potwierdzenia z prawnikiem | ✔ ERGO: „agent” 5× („Od kalkulatora do rozmowy z agentem”, „Agent oddzwoni”) i „doradca” 1×. Home: „doradca” 10×, opieka 17×, UD: „agent” 1× | **A.** „Doradca” wszędzie, a status agenta w stopce i na `/informacje-prawne`. **B.** „Agent” wszędzie. **C.** „Doradca Aura Expert (agent ubezpieczeniowy)” przy pierwszym wystąpieniu na stronie, dalej „doradca” | Decyzja z prawnikiem. Potem jedno słowo na wszystkich stronach, także w przycisku nagłówka, w szufladzie i w pasku akcji (`gen_wspolne.py`) |
| K13 | **Przykładowe stawki opieki i fikcyjna karta Strefy Klienta** | [sample-label]; §6 Never („invented figures”); [copy-fact] | decyzja z 13.11.2026: stawki opieki tylko jako przykład, w menu i kaflu „Cenę przygotuje doradca” (§16–§17); §14.1: jawnie fikcyjna karta klienta | ✔ Opieka: 7 plakietek „przykład” i zdanie „Kwoty powyżej to przykład z makiety…”. W hero opieki zamiast ceny tylko liczby opcji (2 sieci, 3 zakresy, 4 pakiety). – Karta Strefy: „Salon Przykładowy”, numer polisy z dopiskiem „(przykład)”, podpis „Dane przykładowe” (Z21) | **A.** Bez zmian do czasu cennika programu. **B.** Przed publikacją bez przykładowych stawek, a w hero opieki fakt programu bez ceny (np. dwie sieci medyczne). **C.** Kartę Strefy pokazać jako zrzut interfejsu bez kwot | **A w makiecie, B przed publikacją.** Karta Strefy zostaje (§14.1) po poprawkach z Z21 |

## 6. N – nie do sprawdzenia bez kitu

| # | Kontrole skilla | Czego brakuje | Co zrobiliśmy zamiast |
|---|---|---|---|
| N1 | [section-height], {screen-height}, {screen-short}, [fold-cut], [fold-card], {hero-fold} | tolerancje i definicje z `layout-v4.md` §2 („≈ 1 ekran”, kafel, „clear bleed”) | Przyjęliśmy: ≈ 1 ekran to 0,9–1,1, ≈ 2 ekrany to 1,9–2,1, kafel to [góra sekcji, góra + okno − 10 px], przycisk „w hero” ma dół ≤ wysokości okna. Przy innych progach liczby się przesuną, kierunek nie |
| N2 | [row-lines], [col-edge], [stagger], [off-grid], [split-pair], {lines}, [section-air], [section-gaps], [empty-area], {sparse}, {neighbour-ground} | siatka i kolumny `system.css` | Sprawdziliśmy tylko linie `.container` (równe) oraz bloki wystające albo jednostronne (Z3, Z12). Skan kolizji nie wykazał realnych nakładań poza 3–5 px w `dt/dd` karty klienta przy 390 i 320 |
| N3 | rozdanie: `deal.mjs`, `start.mjs`, `moments.mjs`; [hero-enter] (`data-enter`), [moment-none] | skrypty rozdania i wzorce `hero-<id>.html` | Nie wiadomo, jaki hero, paletę, parę fontów i momenty przydzieliłby skill. Strony nie mają `data-enter`. Wejście hero zmierzyliśmy jako animację przy ładowaniu (jest). – Kandydaci na momenty strony głównej to odsłonięcie martwej natury w CTA („plate”, od 1024 px) i wypełnianie zegara oraz szyny w „Jednym dniu w salonie”. Podstrony nie mają kandydata (tylko odsłanianie, dryf cyfr i linie eyebrow). Po udostępnieniu kitu: `moments.mjs pick --page service` (K4, wariant B) |
| N4 | `copy-lint` i warstwa tekstu: [copy-headline], [copy-fact], [copy-headings], [copy-buttons], [run-on], [fact-agree], [assumed], [action-repeat], copy-slop-word… | `copy-lint.mjs`, `copy.md`, `copy-voice.md`, `copy-registers.md`: listy słów, progi, karta głosu | 4. audyt emulował te kontrole własną listą około 45 polskich wzorców, regexami faktów i oceną ręczną. Wyniki są w Z29–Z36, Z40 i K10–K13. `data-assumed`: 0 na 8 stronach, więc [assumed] nie ma czego sprawdzać. [action-count]: najwyżej 2 przyciski w hero; z linkami w treści 3 akcje na opiece i ERGO (✔, Z6, Z34). Nie wiadomo, które trafienia kit uzna za FAIL, a zgodności z kartą głosu nie da się sprawdzić |
| N5 | jeden system: [button-styles], [card-family], [heading-scale], [link-styles], [nesting], [radius] | progi „jednej pary przycisków”, „jednej skali” i definicja karty w `consistency.mjs` | Pomiary są już ustaleniami: Z37 (skala nagłówków), Z38 (karty), Z39 (przyciski, chipy i linki), Z21 (promień 10 px) i K1 ([nesting] przez ramkę `.frame`). Otwarte zostaje tylko to, czy kit uzna te rozbieżności za FAIL, czy za WARN |
| N6 | `perf.mjs` (waga obrazów, CLS, konteksty) | skrypt i progi | Wagi tylko za §7 i §14.5 dokumentu 10. Według §14.3 CLS 0,006 |
| N7 | [visual-empty], [empty-visual], [hidden-content] | sposób robienia zrzutu przez kit (przewijanie czy cała strona naraz) | Po przewinięciu 0 pustych ram na 765 ekranach. Na zrzucie całej strony bez przewijania 50 z 50 bloków `.rv-*` przy 1440 jest niewidocznych (puste tafle). Jeśli kit robi zrzut naraz, będzie to FAIL, który zależy od K4 |
| N8 | [img-alt] | czy kit akceptuje jawnie pusty `alt` | Zdjęcie hero ma `alt=""` w `aria-hidden`. Jeśli kit tego nie przyjmie: krótki opis wnętrza |
| N9 | przeglądarki i ekrany | Safari i Firefox (zastępczy IntersectionObserver), DPR > 1, VoiceOver i NVDA | Nie zrzucaliśmy. Ścieżkę rezerwową odtworzyliśmy tylko emulacją w Chromium (K4). Powiększenie zdjęć przy DPR 2–3 na telefonie tylko wyliczone: hero 1,25–1,87×, tekstury do 4,4× |
| N10 | [menu-toggle] w wersji kitu | sposób sprawdzania (czy kontrola szuka atrybutu `aria-expanded` na `button`) | ✔ Przełącznik szuflady to natywny `summary` bez atrybutu `aria-expanded`. Stan „rozwinięte” wystawia przeglądarka w drzewie dostępności (Enter otwiera, Esc zamyka i oddaje fokus). Przy fałszywym FAIL: uchylenie (wzorzec natywny, §17.2) zamiast zmiany wzorca. Wygląd stanu otwarcia to Z41 |
| N11 | [links], [forms, form-send, form-fields] | kontrole linków i wysyłki formularzy kitu, dostęp do sieci | – Wszystkie kotwice `#id` między 8 stronami trafiają. 8–9 linków na stronę prowadzi do ścieżek produkcyjnych (`/dla-kogo/*`, `/o-nas`, `/rodo`, `/dokumenty`), których w makiecie nie ma. Linków zewnętrznych i wysyłki formularzy nie sprawdzaliśmy |
| N12 | reguła 5: zdjęcie przybliża się o 1,02–1,03 w ramce na hover | obiekty do sprawdzenia | – Dziś nie dotyczy: `<img>` to tylko logo i zdjęcie hero bez linku, a sceny to tła CSS. Gdy dojdą zdjęcia w kartach albo linkach (K2, Z7, Z13), dodać przybliżenie w ramce z `overflow: clip`, wyłączane przy ograniczonym ruchu |

## 7. Proponowana kolejność prac

1. **Od razu, przed kolejną prezentacją: Z28** (kontrast końcowej karty słownika, jedna klasa w `slownik/gen_strona.py`).
2. **Decyzje (jedno spotkanie, bez kodu): K1–K13.** Kolejność ważności:
   1. K2 (zdjęcia, bo od niej zależą Z7 i Z13);
   2. K6 (strony-dokumenty);
   3. K4 (ruch, razem z rezerwą IntersectionObserver);
   4. K1;
   5. K5, K9 i K12 (prawo, wpis uchyleń; K12 razem z prawnikiem);
   6. K10 i K13 (brzmienia z §4 i §8, przykładowe stawki);
   7. na końcu K3, K7, K8 i K11.
3. **Szybkie poprawki Z (około 2–3 dni):** Z3, Z4, Z11, Z6, Z15, Z16, Z18, Z19, Z21, Z22, Z24 i Z25, a z warstwy tekstu Z30–Z35 i Z40. Żadna nie czeka na decyzje. Z4 idzie przez generator słownika, a Z22 i Z40 przez `gen_wspolne.py`. Zmiany na stronie opieki (Z32, Z34) idą przez `opieka-medyczna/build.py`.
4. **Pierwszy ekran (około 2 dni):** Z1, Z2 i Z29 razem, bo dotyczą tego samego `.page-hero`, `.hero-panel` i leadu. Potem Z14. Test przy 6 szerokościach.
5. **Rytm sekcji (około 3–4 dni, po K6):** najpierw Z37 (skala nagłówków zmienia wysokości sekcji), potem Z8, Z9 i Z12, a na końcu Z10 i Z23. Przy każdej zmianie: brak przewijania w poziomie od 320 px, test kalkulatora (`shot_v3`), `check_zabiegi_1do1` i `--check` generatorów (§17.4, §18.4).
6. **Tekst i jeden system (około 2 dni, po K10):** Z36, Z38 i Z39.
7. **Zdjęcia (po K2 i sesji):** Z7, Z13, Z17, potem `og:image` z Z24 dla podstron.
8. **Ruch (po K4):** wariant B z K4, Z20, Z27 i Z41.
9. **Przed publikacją:** Z5 i Z26 (z miejscami „do uzupełnienia” i „do potwierdzenia”). Dokument 10 trzeba uzupełnić o decyzje K1–K13 oraz o zmiany zapisów z Z19 (linia postępu), Z40 (jednostka NNW w §16–§17) i Z30, jeśli wybrany zostanie wariant z 4 krokami.
10. **Gdy będzie kit:** `copy-lint.mjs`, `consistency.mjs --widths 1440,1024,820,768,390`, `check.mjs --sizes 1440x900,1024x768,820x1180,768x1024,390x844`, `perf.mjs`, `moments.mjs` i `gate.mjs` (przy 320). Uchylenia K wpisać do `.taste-skill/waivers.json` z powodami. Wyniki porównać z tym raportem i zamknąć N1–N12.

## 8. Weryfikacja ustaleń audytów

**Wejście.**
- Wydanie 1.0 opierało się na pełnych wynikach dwóch audytów: „układ i ekrany” (23 ustalenia) i „obrazy, tła i efekty” (22). Z audytu ruchu miało streszczenie i 1 ustalenie, a z audytu treści tylko sygnały z surowych danych.
- Wydanie 1.1 (16.11.2026) uwzględnia pełne wyniki obu brakujących audytów. Audyt ruchu ma 20 ustaleń, w tym 11 o wadze wysokiej lub średniej. Audyt treści ma 39 ustaleń, w tym 23 o wadze wysokiej lub średniej.

**Scalenie.** Po usunięciu duplikatów zostało 41 Z, 13 K i 12 N. W pierwszym wydaniu było 27 Z, 9 K i 9 N, a uzupełnienie dodało Z28–Z41, K10–K13 i N10–N12. Scalone duplikaty z pierwszego wydania:
- przechylona karta (3 audyty);
- pusty pas w hero podstron (2);
- reguła 9 (3);
- brak `og:image` (2);
- tekstury i [photo-repeat] (włączone do K1, bo to tła, a nie zdjęcia).

Scalone w uzupełnieniu (ustalenia audytu ruchu oznaczone R, treści T, z numerem z audytu):
- z istniejącymi pozycjami:
  - K4 ← R1, R3;
  - Z18 ← R2;
  - N7 ← R4;
  - K8 ← R5;
  - Z21 ← R6, T31;
  - Z19 ← R7, R8, R12;
  - Z24 ← R9, R18, T37;
  - Z27 ← R10, R11;
  - Z20 ← R13;
  - K5 ← R16, T2, T3, T4, T5;
  - N3 ← R17;
  - Z6 ← T17;
  - Z26 ← T25;
  - K1 ← T32;
  - N4 ← T39;
- nowe pozycje złożone z kilku ustaleń:
  - Z33 ← T10, T11, T34;
  - Z34 ← T13, T14, T16;
  - Z36 ← T20, T21, T22, T23 (bez dwóch nagłówków z §8), T24, T35;
  - Z39 ← T29, T30;
  - K10 ← T6, T33 i dwa nagłówki z §8 z T23;
  - K13 ← T19, T26;
- nowe pozycje z jednego ustalenia: Z28 ← T1, Z29 ← T18, Z30 ← T7, Z31 ← T8, Z32 ← T9, Z35 ← uwaga poboczna T, Z37 ← T27, Z38 ← T28, Z40 ← T36, Z41 ← R14, K11 ← T15, K12 ← T12, N10 ← R19, N11 ← T38, N12 ← R20;
- odrzucone: R15 (niżej).

**Zmiany klasy.**
- Paralaksa zdjęcia hero i dryf cyfr rozdziałów: z K na Z. Nie ma ich na liście efektów §14.2, a skill zabrania paralaksy tekstu.
- Uniesienie kafli produktów: K, bo §16 opisuje hover, a §14.3 każe traktować produkty jako jedną taflę.
- Podpis „Dane przykładowe”: Z, bo dane i tak są oznaczone.
- T23 (nagłówki bez rzeczownika): Z, ale „Znamy specyfikę Twojej pracy” i „Coś się wydarzyło w salonie?” przeszły do K10, bo zapisuje je §8.
- Uwaga poboczna T o braku karty opieki w „Inne ubezpieczenia” na ERGO: nowe Z35, bo brak dotyczy 5 podstron.

**Sprawdzone ponownie w przeglądarce, runda 1** (24 ustalenia o wadze wysokiej lub średniej z trzech audytów):

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

**Sprawdzone ponownie w przeglądarce, runda 2** (uzupełnienie, 16.11.2026). Runda objęła 25 ustaleń o wadze wysokiej lub średniej z audytów ruchu (R) i treści (T). Pozostałe ustalenia tej wagi to duplikaty sprawdzone w rundzie 1 (R1, R2, R5, R7, R8, T2, T3), R4, który zależy od sposobu robienia zrzutu przez kit (N7), i R17 (N3). Pomiar: Playwright z Chromium, `file://`, `deviceScaleFactor` 1, okna 1440×900, 1024×768 i 390×844. Kontrast liczony na zrzucie z ukrytym tekstem, jako mediana próbek tła pod prostokątem nagłówka.

| # | Ustalenie (audyt, waga) | Pomiar weryfikacji | Wynik |
|---|---|---|---|
| 25 | T1 Kontrast końcowej karty słownika (treść, wysoka) | H2 1,16–1,20:1 przy 390, 1024 i 1440; eyebrow 1,67–1,80:1. Na słowniku `class="end-card"`, na 6 podstronach `end-card dark` (OC: 11,66:1) | potwierdzone (Z28) |
| 26 | T6 H1 strony głównej bez kategorii, „szyta na miarę” (treść, wysoka) | H1 „Ochrona szyta na miarę Twojego salonu”, kategoria tylko w eyebrow | potwierdzone (K10) |
| 27 | T4 Adresy e-mail IOD i reklamacji (treść, średnia) | 2/1/1/1/1/1/2/3 widoczne na stronach | potwierdzone (K5) |
| 28 | T7 Trzy kroki na home, cztery na OC (treść, średnia) | 3 i 4 `li.step`; Tax też 4 kroki, o innych nazwach | potwierdzone (Z30) |
| 29 | T8 UD „dla samozatrudnionych” wbrew §16 (treść, średnia) | lead hero UD wobec kafla na home | potwierdzone i rozszerzone o JSON-LD (Z31) |
| 30 | T9 Różne nazwy produktów (treść, średnia) | ERGO: `title`, H1, okruszki; „NNW dzieci” 1 + 1; „OC beauty” 1/1/7 | potwierdzone (Z32) |
| 31 | T10 Akcja kalkulatora w 4 brzmieniach (treść, średnia) | „Oblicz składkę OC”, „Policz składkę”, „Policz w kalkulatorze”, „Policz składkę Tax Protect”; pasek akcji „Oblicz składkę” (słowo „OC” tylko dla czytników) | potwierdzone (Z33) |
| 32 | T11 Akcja kontaktu w co najmniej 6 brzmieniach (treść, średnia) | 5 brzmień i 2 brzmienia przycisku wysyłki. „Zapytaj o ofertę” nie jest akcją, to fragment leadu opieki | **skorygowane**: 5, a nie 6 (Z33) |
| 33 | T12 „agent” i „doradca” (treść, średnia) | ERGO 5 i 1; „doradca” home 10, opieka 17 | potwierdzone (K12) |
| 34 | T13 4 akcje do formularza w `#ceny` opieki (treść, średnia) | 4 przy 1440, 3 przy 390 | potwierdzone (Z34) |
| 35 | T14 3 akcje w hero opieki (treść, średnia) | 2 przyciski i link 75 px niżej; z nagłówkiem 3× „Zapytaj doradcę” | potwierdzone (Z34) |
| 36 | T15 4× „Zapytaj doradcę” przy kaflach produktów (treść, średnia) | 3 w kaflach w jednym ekranie; czwarte w nagłówku tylko wtedy, gdy nagłówek jest widoczny | **skorygowane** (K11) |
| 37 | T17 Hero ERGO: 3 akcje bez czasownika (treść, średnia) | 2 karty-linki i link na 898 px przy oknie 900 px | potwierdzone (Z6) |
| 38 | T18 Brak twardego faktu w 1. ekranie przy 390 (treść, średnia) | home, UD i Tax bez kwoty; przy 1440 kwota jest | potwierdzone (Z29) |
| 39 | T20 „Sześć rozwiązań” zamiast „ubezpieczeń” z §8 (treść, średnia) | „rozwiązanie/rozwiązań” 2× | potwierdzone (Z36) |
| 40 | T23 10 nagłówków bez rzeczownika w 13 miejscach (treść, średnia) | 11 brzmień w 13 nagłówkach, z tego 2 z §8 | **skorygowane** (Z36, K10) |
| 41 | T25 Notki robocze i miejsca do uzupełnienia (treść, średnia) | nawias w `#kontakt` i notka w hero opieki widoczne. Widoczne „do potwierdzenia”, liczone jako najmniejsze elementy z tym tekstem: opieka 19, słownik 22, ERGO 9 (audyt: 37, 41, 9) | potwierdzone, liczby **skorygowane** (inna metoda liczenia; Z26) |
| 42 | T26 Przykładowe stawki opieki i fikcyjna karta (treść, średnia) | 7 plakietek „przykład” i zdanie o przykładzie z makiety | potwierdzone (K13) |
| 43 | T27 Skala nagłówków (treść, średnia) | H1 2, H2 5, H3 13, H4 3 rozmiary; tokeny do 84 i 68 px | potwierdzone (Z37) |
| 44 | T28 Rodzina kart (treść, średnia) | 6 wyglądów poza szkłem | potwierdzone (Z38) |
| 45 | T29 Style przycisków (treść, średnia) | para `.btn` spójna, do tego 4 inne style | potwierdzone (Z39) |
| 46 | R3 Rezerwa IntersectionObserver jako fade-in czasowy (ruch, średnia) | 50 z 60 i 19 z 25 bloków ukrytych na starcie; krycie 0 → 1 w 1000 ms | potwierdzone (K4) |
| 47 | R6 Karta Strefy na hover (ruch, średnia) | `rotate` 0 i uniesienie o 4 px | potwierdzone (Z21) |
| 48 | R9 Head bez `og:image`, `twitter:card` i ikon (ruch, średnia) | 0 z 8 | potwierdzone (Z24) |
| 49 | R10 `link-quiet` i logo bez reakcji na kursor (ruch, średnia) | 0 zmian stylu po 80 i 800 ms | potwierdzone (Z27) |

Ustalenia niskiej wagi sprawdzone w rundzie 2 (12):
- potwierdzone:
  - R11 (podkreślenia skokiem w nawigacji, stopce, FAQ i nazwach kafli, Z27);
  - R12 (linia postępu, Z19);
  - R14 (szuflada 80%, brak stanu otwarcia, Z41);
  - R19 (`summary` bez `aria-expanded`, N10);
  - T21, T22 i T35 (Z36);
  - T31 (promień 10 px, Z21);
  - T36 (Z40);
- **skorygowane:** T24 (12 nagłówków od liczby, a nie 11);
- **rozszerzone:** uwaga poboczna o braku karty opieki dotyczy 5 podstron, a nie tylko ERGO (Z35);
- **odrzucone:** R15 (niżej).

**Odrzucone w całości:** 1 z 61 sprawdzonych ustaleń, i to o niskiej wadze. Wszystkie ustalenia o wadze wysokiej i średniej się potwierdziły, części z korektą wartości.
- R15 (ruch, niska): „fokus po 1,2 s nadal poza oknem” (OC przy 1440, przystanek 44).
  - Pomiar: 4 przebiegi po 80 przystanków Tab (OC i home przy 1440).
  - Po 1,2 s: 0 przypadków poza oknem albo pod nagłówkiem.
  - Po 200 ms: 1–2 przypadki na przebieg. To chwilowy skutek płynnego przewijania, który znika po jego zakończeniu.
  - Sam audyt też nie odtworzył tego przypadku. Do raportu nie wpisane.
- Odrzucony fragment ustalenia: „Zapytaj o ofertę” jako akcja (T11).

**Niesprawdzone ponownie** (pozostają z oznaczeniem „–”):
- z rundy 1: cele dotyku z WARN, 22 kafle z obcym H2 przy 820, nakładanie paska akcji na OC i opiece, przesunięcie sticky FAQ (weryfikator potwierdził tylko, że `.faq-head` jest sticky);
- z rundy 2:
  - wyglądy linków w tekście (Z39);
  - kursywa w 57 ze 114 nagłówków (K10);
  - [nesting] przez ramkę (K1);
  - dane w JSON-LD (K5);
  - kandydaci na momenty (N3);
  - linki do ścieżek produkcyjnych (N11).

**Dowody** (pliki robocze sesji, nietrwałe): `/tmp/claude-0/-home-user-beautypolisa/02bc7ecd-7d14-594f-829e-bcbe3ff0c238/scratchpad/taste/`:
- `uklad/` (`results-*.json`, `hero.json`, `shots/`);
- `obrazy/` (`results-*.json`, `hero.txt`, zrzuty 1440/1024/768/390);
- `ruch/` (`mo/`, `kb/`, `hv/`);
- `tresc/` (surowe dane 4. audytu: `audit.json`, `contrast-*.json`, zrzuty 1440 i 390);
- `audyty-pelne.json` (pełne wyniki 4 audytów);
- `weryfikacja/` (`verify.json`, `verify2.json`, zrzuty `v1-…`, `v2-…`, `v3-…`, `v5-…`, `v7-…`, `v9-…`, `v-hero-768.png`, `v-bar-calc-320.png`);
- `uzupelnienie/` (runda 2: `tresc.js` i `tresc.json`, `ruch.js`, `ruch.json` i `ruch-fallback.json`, `dodatkowe.js` i `dodatkowe.json`, `fokus.js` i `fokus.json`, zrzuty `u-slownik-end-*.png`, `u-*-ekran1.png`, `u-menu-*-390.png`).

## 9. Zgodne ze skillem (PASS, z audytów)

- Brak przewijania w poziomie (48 z 48) i 0 elementów poza oknem przy 320 px [off-viewport]. Równe krawędzie `.container` na wszystkich stronach i szerokościach [container-edges]. Nagłówek i stopka na tych samych liniach.
- 0 błędów JS. Wszystkie obrazy się ładują, 0 nieudanych żądań, wszystkie symbole ikon działają. Brak WebGL, `<canvas>` i wideo. 0 fioletu i lawendy w CSS, SVG i obrazach (§6 Never).
- Najwyżej 2–3 tafle `backdrop-filter` w widoku. Wyjścia awaryjne szkła działają.
- Wejście hero raz przy ładowaniu (8 z 8). Brak pętli, karuzel, zakładek zmienianych zegarem i przejmowania przewijania. Przy ograniczonym ruchu 0 animacji i nic ukrytego (16 z 16) [reduced-motion, hidden-content].
- Pierwszym przystankiem Tab jest skip link (16 z 16), a jego obwódka pojawia się od razu nad nagłówkiem. 1906 przystanków Tab i Shift+Tab z widoczną obwódką, nic pod nagłówkiem ani pod paskiem. Przycisk „Ubezpieczenia” ma `aria-expanded`, a Esc oddaje fokus. Szuflada na telefonie wystawia stan przez natywny `summary` (N10). 0 kontrolek bez nazwy, `alt` na obrazach, widoczne etykiety, jeden H1 na stronę, kolejność nagłówków bez przeskoków, `tabindex` ≤ 0, `lang`, `title` i `description` [a11y-name … page-meta].
- Najwyżej 2 przyciski w hero [action-count]. Z linkami w treści hero opieki i ERGO mają po 3 akcje (Z6, Z34). Przyciski hero przy 390 px na pełną szerokość. Szuflada menu zajmuje 80% ekranu (Z41). Pasek akcji ukryty na 1. ekranie i przy stopce, nie zasłania `.calc-peek`, `.lead-form` ani `.end-card`.
- Treść i jeden system (audyt treści):
  - Około 8 800 próbek tekstu przechodzi AA na wyrenderowanym tle. Wyjątkiem jest końcowa karta słownika (Z28).
  - Cormorant Garamond i Poppins się ładują [font-load].
  - Para przycisków `.btn` jest jedna na dwóch tłach.
  - Promienie trzymają skalę 2/3/6 px. Wyjątkiem jest karta Strefy (Z21).
  - Bez ramki `.frame` zagnieżdżenie ma najwyżej 2 poziomy.
  - Wszystkie kotwice `#id` między 8 stronami trafiają.
  - Copy jest w większości czyste: zakazane słowa i frazy szablonowe to pojedyncze przypadki (Z36, K10).
