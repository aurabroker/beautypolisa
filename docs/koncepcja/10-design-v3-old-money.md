# 10 · Design v3 – old money, całość w szkle

> Ta sekcja zastępuje warstwę wizualną sekcji `09-design-v2-bloom.md` (paleta, typografia, ikony, ilustracje, makieta). Z sekcji 07 nadal obowiązują: lista kontrolna WCAG 2.2 AA, zasady responsywności, inwentarz komponentów, mikrocopy i szablony stron. Z sekcji 09 nadal obowiązują: reguły kalkulatora OC i opis procesu pracy z Bloom.

> **Aktualizacja 12.11.2026 – przejście TURBO.** Makieta przeszła recenzję z czterech perspektyw, weryfikację i wdrożenie 41 poprawek. Doszła warstwa opowieści (rozdziały I–VII, „Jeden dzień w salonie”), ruch sterowany przewijaniem i rozdział „Strefa Klienta” z makietami ekranów. Szczegóły w rozdziale 14. Tokeny w `design/v3/tokens-v3.css` mają teraz nazwy zgodne z `@theme` Tailwind 4.

## TL;DR

- Zleceniodawca odrzucił v2 jako „ilustrację z komiksu” i poprosił o totalny redesign: całość w glassmorphizmie, glamour w stylu old money.
- W Bloom zmieniono kierunek wizualny marki na old money: nocny granat, kość słoniowa, pergamin, szampańskie złoto, Cormorant Garamond do nagłówków i Poppins do tekstu.
- Płaskie ilustracje zastąpiły cztery zdjęcia z Bloom: wnętrze salonu (hero), granatowy jedwab, marmur z lnem oraz martwa natura do CTA. Każda tafla szkła leży na zdjęciu, nigdy na płaskim kolorze.
- W Bloom powstał od zera nowy zestaw 21 ikon cienką linią, w stylu grawerowanej papeterii. Ikony mają jeden kolor (`currentColor`): granat na jasnym, złoto na ciemnym.
- Makieta `design/v3/makieta-v3.html` działa bez builda. Kalkulator liczy składkę ze stałej taryfy. Test w Chrome przy 1280 px i 390 px: brak poziomego przewijania, brak błędów JS, brak tekstu poniżej 12 px.
- Tablica Design (canvas) pokazuje v3: stronę główną z działającym kalkulatorem oraz tablicę systemu marki z paletą, kontrastami, typografią, ikonami i próbkami szkła.

## 1. Dlaczego v3

| Uwaga do v2 | Odpowiedź w v3 |
|---|---|
| „Jak ilustracja komiksu” – płaskie ilustracje, grube kontury, róż w grafice | Fotografia edytorska z Bloom zamiast ilustracji; ikony cienką linią 2,5 zamiast 6; róż został tylko w logo |
| Za mało szkła („całość glass morph”) | Szkło na całej stronie: nagłówek, panel hero, pasek partnerów, karty ubezpieczeń, kalkulator, kafle zawodów, FAQ, CTA, stopka |
| Brak glamour, ale bez przepychu („old money”) | Paleta granat–kość słoniowa–złoto, szeryfowe nagłówki z kursywą, wersaliki z rozstrzeleniem, cienkie złote ramki, liczby rzymskie, małe promienie 3–6 px |

## 2. Zmiana marki w Bloom

- Zmiana profilu marki (brand edit) zapisała nowy kierunek: quiet luxury, ponadczasowo, nigdy krzykliwie. Fotografia: boazeria w kolorze kremowym, granatowy aksamit, szczotkowany mosiądz, marmur, len, kryształowe flakony, blade piwonie, miękkie dzienne światło, bez twarzy i bez tekstu. Strona: całość na mrożonym szkle nad zdjęciami.
- Na tej podstawie Bloom przygotował brief strony głównej, a generacje (model gpt-image-2.6) korzystały z marki i briefu.
- Logo się nie zmieniło. Serce i róż zostają w logo; w interfejsie róż nie występuje.

## 3. Paleta i kontrast

| Token | Kolor | Użycie | Kontrast (WCAG) |
|---|---|---|---|
| `--midnight` | `#141C33` | tła ciemnych sekcji, stopka, ciemne szkło | ivory na nim 15,27:1 |
| `--navy` | `#2A3B68` | nagłówki, przyciski, ikony na jasnym | 9,87:1 na ivory, 8,73:1 na parchment |
| `--navy-deep` | `#1E2B4F` | hover przycisków | – |
| `--ink` | `#1B2233` | tekst akapitów | 14,35:1 na ivory |
| `--taupe` | `#5F574D` | podpisy, etykiety, eyebrow | 6,42:1 na ivory, 5,68:1 na parchment |
| `--ivory` | `#F7F3EC` | tło bazowe, jasne szkło, tekst na ciemnym | – |
| `--parchment` | `#EDE5D8` | tekst akapitów na ciemnym | 13,51:1 na midnight |
| `--gold` | `#B8975A` | linie, ramki, ozdobniki | 2,49:1 na ivory – **tylko dekor**; 6,12:1 na midnight |
| `--gold-light` | `#D9C089` | ikony, etykiety i tagi na ciemnym | 9,53:1 na midnight, 6,16:1 na navy |

Zasada: złoty tekst tylko na ciemnym tle. Na jasnym złoto rysuje linie i ramki, ale nie niesie treści.

## 4. Typografia

- **Nagłówki:** Cormorant Garamond 500/600, z kursywą 500 do akcentu w tytule („Ochrona szyta *na miarę* Twojego salonu”). H1 44–80 px, H2 34–54 px, H3 26 px.
- **Tekst:** Poppins 300/400/500 (font z logo), akapit 16 px przy interlinii 1,7.
- **Etykiety:** Poppins 500, 12 px, wersaliki, rozstrzelenie .2–.24em (eyebrow, przyciski, tagi, nawigacja). Nic poniżej 12 px.
- W produkcji oba fonty idą przez `next/font` (samohostowane, `display: swap`, podzbiór `latin-ext`). Nie ładujemy Google Fonts z zewnątrz, co upraszcza CSP.

## 5. Ikony

- 21 ikon z Bloom: sześć produktów, sześć zawodów i dziewięć ikon interfejsu. Styl: cienka linia jak grawer, jeden kolor, bez wypełnień.
- Detale old money: koń na biegunach (NNW dzieci), dłoń z monetą (utrata dochodu), dokument z pieczęcią lakową (dokumenty), telefon w stylu vintage (doradca), zegarek kieszonkowy (szybka wycena), antyczny klucz (bezpieczeństwo), wieniec laurowy z ptaszkiem (w zakresie).
- Pliki: `design/v3/ikony/*.svg` (pojedyncze), `design/v3/ikony-v3-sprite.svg` (`<symbol id="lux-…">`, kontur `currentColor`), `design/v3/ikony-arkusz-v3.svg` (arkusz z Bloom) i `design/v3/ikony-v3-manifest.json` (slug i nazwa).
- Rozmiary: 44 px z linią 2,5; 32 px z linią 3; 22 px z linią 4. Kafle zawodów: 54 px z linią 2,2. Kolor: granat na jasnym, gold light na ciemnym.

## 6. Szkło – zasady

| Wariant | Tło | Gdzie |
|---|---|---|
| Jasne `.glass` | `rgba(247,243,236,.7)`, blur 24 px, saturate 140%, biała krawędź 60% | panel hero, kalkulator, kafle zawodów, FAQ, CTA |
| Mocne `.glass--strong` | ivory 82% | nagłówek, menu mobilne |
| Ciemne `.glass--dark` | `rgba(20,28,51,.56)`, blur 22 px, złota krawędź 26% | karty ubezpieczeń, „Jak to działa”, stopka |
| Ramka `.frame` | złota linia 1 px wewnątrz tafli, 9 px od krawędzi | panel hero, kalkulator, karty, CTA |

- Szkło zawsze leży na zdjęciu. Na płaskim kolorze efekt znika, a zostaje tylko szary prostokąt.
- Wyjścia awaryjne: bez `backdrop-filter` tafla ma krycie 95% (jasna) lub 92% (ciemna). Przy `prefers-reduced-transparency` i `prefers-contrast: more` jest w pełni kryjąca, a przy wysokim kontraście dostaje granatową lub złotą krawędź.
- Wydajność: `backdrop-filter` obciąża GPU. W produkcji na ekranach poniżej 768 px blur zmniejszamy do 16 px, a w jednym widoku są najwyżej trzy duże tafle. Nie animujemy tafli.

## 7. Zdjęcia

| Plik | Rola | Desktop (2048×1152) | Mobile (1024) |
|---|---|---|---|
| `img/hero-salon.webp` | hero: salon z boazerią, granatowy fotel, piwonie; lewa strona spokojna pod panel | 137 KB | 36 KB |
| `img/tlo-jedwab.webp` | ciemne sekcje: granatowy jedwab ze złotym połyskiem | 143 KB | 16 KB |
| `img/tlo-marmur-len.webp` | jasne sekcje: marmur Calacatta i len w świetle dziennym | 180 KB | 22 KB |
| `img/cta-martwa-natura.webp` | CTA: flakon, notesy, pióro, piwonie; prawa strona spokojna | 130 KB | 30 KB |

- Na telefonie strona pobiera łącznie około 104 KB zdjęć, a na desktopie około 590 KB.
- W produkcji hero to `<Image fill priority>` z `sizes` i AVIF (Cloudflare Images lub loader `next/image`), a nie tło w CSS. Tylko tak przeglądarka dostanie preload i `srcset` dla LCP. Pozostałe tła mogą zostać w CSS z `image-set()` (AVIF i WebP) i ładować się leniwie.
- Zdjęcia są wygenerowane w Bloom (AI) i nie pokazują twarzy ani produktów konkretnych marek. Przed publikacją zleceniodawca potwierdza, że akceptuje zdjęcia generowane albo dostarcza własne sesje w tym samym stylu.

## 8. Strona główna – sekcje

1. **Nagłówek:** jasne szkło, logo z podpisem „created by Aura Expert”, nawigacja (Ubezpieczenia, Kalkulator, Dla kogo, Jak to działa, Pytania) i przycisk „Umów rozmowę”.
2. **Hero na zdjęciu salonu:** panel szkła ze złotą ramką, eyebrow „Program ubezpieczeń dla branży beauty” i H1 „Ochrona szyta *na miarę* Twojego salonu”. Przyciski „Oblicz składkę OC” i „Poznaj ubezpieczenia”. Liczby: „od 400 zł” (składka OC rocznie), „300 tys. zł” (najwyższa suma) i „4” (grupy ryzyka). Pod panelem szklany pasek partnerów: ERGO Hestia, Colonnade, ENEL-MED, LUX MED, Fundacja Beauty Razem.
3. **Ubezpieczenia na jedwabiu:** H2 „Sześć ubezpieczeń. Jeden doradca.” i sześć ciemnych kart szkła ze złotymi ikonami i tagami ubezpieczyciela.
4. **Kalkulator na marmurze:** H2 „Sprawdź składkę *w dwie minuty*”. Formularz w jasnym szkle i granatowy panel wyniku z polami Taryfa i Składka roczna oraz przyciskiem „Poproś o polisę”.
5. **Dla kogo:** na tym samym marmurze co kalkulator, bez szwu między sekcjami. H2 „Znamy specyfikę *Twojej pracy*” i sześć kafli zawodów.
6. **Jak to działa na jedwabiu:** trzy kroki z liczbami rzymskimi I–III i pasek czterech korzyści.
7. **Szkoda i FAQ na marmurze:** baner „Coś się wydarzyło w salonie?” i pytania w szklanych `<details>`.
8. **CTA na martwej naturze:** szklany panel po prawej, H2 „Porozmawiajmy o ochronie Twojego salonu”.
9. **Stopka na jedwabiu:** ciemne szkło, logo na jasnym polu (do czasu logo na ciemne tło), mapa linków i nota prawna z art. 66 KC.

## 9. Kalkulator OC

Reguły są te same co w v2 i w obecnym `bp-app.js`. Składki są stałe (taryfa programu), więc nie ma przy nich słów „orientacyjnie”, „szacunkowo” ani „do potwierdzenia”.

| Grupa | 100 tys. zł | 200 tys. zł | 300 tys. zł |
|---|---|---|---|
| 1 – pielęgnacja i fryzjerstwo | 400 zł | 500 zł | 650 zł |
| 2 – kosmetologia i tatuaż | 650 zł | 790 zł | 950 zł |
| 3 – podologia | 850 zł | 980 zł | 1250 zł |

- Grupa 3 z grupą 1 lub 2 → taryfa 3; grupy 1 i 2 razem → taryfa 3.
- Ochrona prawna: +92 zł. Zespół 6–8 osób: ×1,25.
- Grupa 4 albo zespół od 9 osób: „Wycena indywidualna”, a przycisk zmienia się na „Wypełnij ankietę ERGO Hestii” lub „Poproś o wycenę”.

## 10. Testy makiety

| Test | Wynik |
|---|---|
| Szerokość 1280 px, poziome przewijanie | brak (scrollWidth 1280) |
| Szerokość 390 px, poziome przewijanie | brak (scrollWidth 390) |
| Błędy JS w konsoli | 0 |
| Kalkulator: grupy 1 i 2, 200 tys. zł | 980 zł |
| Kalkulator: grupa 4 | „Wycena indywidualna” |
| Tekst poniżej 12 px | brak elementów |
| Szew tła między kalkulatorem a „Dla kogo” | usunięty (jedna scena marmuru) |

Narzędzie: Playwright i Chromium, zrzuty całej strony przy 1280 i 390 px.

## 11. Pliki

- `design/v3/makieta-v3.html`: makieta strony głównej (sprite ikon wbudowany).
- `design/v3/oc-beauty.html`: makieta strony `/ubezpieczenia/oc-beauty` – lista 117 zabiegów (`#zabiegi`), treść klauzuli ochrony prawnej (`#ochrona-prawna`), taryfa i FAQ (rozdział 15). „Jak kupić”: ścieżka OC z osobistym linkiem do APK i wniosku w serwisie portal.beautypolisa.eu opisana słowami, bez adresu z kodem (00, D32).
- `design/v3/tax-protect.html`: makieta strony `/ubezpieczenia/tax-protect` – stała taryfa (00, D26), „Jak kupić”: kalkulator albo formularz → doradca Aura Expert prowadzi wniosek, bez osobistego linku (00, D32 etap 1, D34).
- `design/v3/utrata-dochodu.html`: makieta strony `/ubezpieczenia/utrata-dochodu` – treść z utratadochodu.pl, bez kwot składek, wniosek i zakup online na utratadochodu.pl (00, D33, D34).
- `design/v3/nnw-dzieci.html`, `design/v3/grupowe-ergo.html`: makiety stron NNW dzieci i grupowego ERGO. NNW dzieci (00, D35) – tabela wariantów I–III (40 / 94 / 175 zł jednorazowo za rok za osobę), przycisk „Kup online u Colonnade” (`https://bit.ly/szkolneNNW2026` → market.colonnade.pl, zakup na platformie ubezpieczyciela) albo formularz → doradca Aura Expert. Grupowe ERGO (00, D36) – ERGO Życie w Biznesie dla salonu (58 / 68 / 76 zł miesięcznie za osobę, wniosek na ergo.auraexpert.pl) i ERGO Razem dla siebie i rodziny (od 57 zł miesięcznie, kalkulator na ergo.beautypolisa.eu) albo formularz → doradca. Na obu stronach bez osobistego linku `/w/` (00, D32, D35, D36).
- `design/v3/tokens-v3.css`: tokeny, szkło, ikony, przyciski i mapowanie do `@theme` Tailwind 4.
- `design/v3/img/`: cztery zdjęcia w dwóch rozmiarach.
- `design/v3/ikony/`, `ikony-v3-sprite.svg`, `ikony-arkusz-v3.svg`, `ikony-v3-manifest.json`: ikony.
- Wersja v2 (`design/makieta-v2.html`, `design/tokens-v2.css`, `design/bloom/`) zostaje w repozytorium jako historia i jest nieaktualna.

## 12. Decyzje

| # | Decyzja |
|---|---|
| D13 (zmieniona) | Paleta old money: midnight `#141C33`, navy `#2A3B68`, ivory `#F7F3EC`, parchment `#EDE5D8`, gold `#B8975A` (tylko dekor), gold light `#D9C089` (tekst na ciemnym). Nagłówki w Cormorant Garamond, tekst w Poppins. Róż tylko w logo. |
| D14 (zmieniona) | Całość w szkle na zdjęciach z Bloom (jasne, mocne i ciemne szkło ze złotą ramką). Ikony z Bloom cienką linią, jeden kolor. Wyjścia awaryjne szkła są obowiązkowe. |
| D29 (00) | Pełna lista 117 zabiegów z jednego pliku danych: wyszukiwarka (combobox) w kalkulatorze i długa lista z kotwicami na stronie OC (rozdział 15) |
| D30 (00) | Treść klauzuli ochrony prawnej dosłownie: natywny dialog w kalkulatorze, sekcja `#ochrona-prawna` na stronie OC, karta polisy w Strefie Klienta (rozdział 15) |

## 13. Otwarte pytania

1. **Logo na ciemne tło:** w stopce logo stoi na jasnym polu. Potrzebna jest wersja jasna (kość słoniowa i złoto) oraz logo w SVG zamiast PNG.
2. **Zdjęcia:** czy zleceniodawca akceptuje zdjęcia generowane w Bloom na produkcji, czy planuje sesję w prawdziwym salonie w tym samym stylu?
3. **Tryb ciemny:** w v3 strona ma już ciemne sekcje. Osobny tryb ciemny dla całej strony nie jest potrzebny w fazie 1.

## 14. Przejście TURBO (12.11.2026)

**Jak powstało.** Cztery niezależne recenzje makiety, każda z innym skillem: luksus wizualny i opowieść (design-critique, brand-review), dostępność i telefony (accessibility-review), teksty i konwersja (ux-copy, lead-magnets-and-funnels, insurance-customer-experience), wydajność, semantyka i system (technical-seo, design-system). Wyniki przed zmianami: 6, 6, 5 i 6 na 10. Ze 49 propozycji 43 przyjęto, każdą sprawdził weryfikator, który próbował ją obalić. Wdrożenie odbyło się w dwóch przejściach. Potem nastąpiła kontrola jakości przed i po oraz runda poprawek. Kontrola jakości po zmianach: strona główna 7,5/10, Strefa Klienta 8/10.

**Inspiracje zleceniodawcy.** Gucci „La Famiglia: Mystery Unfolds” (opowieść, odkrywanie zamiast menu) i Agrumea Farm (powolna, filmowa podróż w przewijaniu). Strony nie były osiągalne z sesji, więc przejęto zasady z opisów: rozdziały, odkrywanie, filmowe tempo. Nie przejęto ani elementów, ani układów. Bez WebGL, bez bibliotek i bez przejmowania przewijania, bo szybkość i dostępność mają pierwszeństwo.

### 14.1 Opowieść
- Rozdziały I–VII w etykietach sekcji (rzymskie cyfry, kursywa szeryfowa).
- **I · „Jeden dzień w salonie. Sześć chwil.”** – sześć sytuacji od 9:40 do 20:00 (reakcja klientki po zabiegu, zawiadomienie o kontroli podatkowej, uraz właścicielki, wypadek dziecka w szkole, pytanie o benefity, ból pleców po dniu przy fotelu). Każdą odsłania się jak wskazówkę (`<details>`, działa bez JS) i każda prowadzi do właściwej ochrony. Do tego licznik „Odsłonięte: x z 6”, linia „rano → wieczór” i przycisk „Odsłoń wszystkie”. Opisy ochrony są ogólne, z zastrzeżeniem „zgodnie z OWU”.
- **VI · Strefa Klienta** – rozdział na marmurze z przykładową kartą klienta (dane jawnie fikcyjne, kwota z taryfy: 790 zł + 92 zł = 882 zł) i linkami do makiet strefy. W nagłówku jest link „Strefa Klienta”, w stopce „Dam pracę” i „Szkolenia”.
- **Epilog (#kontakt)** – formularz rozmowy z doradcą w panelu CTA: wybór produktu, minimum pól, zgody z `snippets/legal-consents.json`.

### 14.2 Ruch
- Ruch sterowany przewijaniem (`animation-timeline: view()`) jest zamknięty w `@supports` i `prefers-reduced-motion: no-preference`. Gdy przeglądarka go nie obsługuje, zastępuje go `IntersectionObserver`.
- Efekty: nagłówki odsłaniane „kurtyną” (z zapasem na polskie znaki diakrytyczne), złote linie rysujące się przy wejściu, odsłonięcie zdjęcia martwej natury, delikatne ziarno na tłach.
- Wejście strony trwa najwyżej 1,15 s i obejmuje tylko ozdoby (ramka panelu, linia). H1 i zdjęcie hero nie czekają na animację, LCP to H1 po około 220 ms.
- Nagłówek kurczy się przy przewijaniu i chowa przy przewijaniu w dół. Nigdy nie chowa się przy otwartym menu, przy fokusie w środku ani przy ograniczonym ruchu.
- Cena w kalkulatorze „tyka” przy zmianie (Web Animations, wyłączone przy ograniczonym ruchu). Na telefonie przy dolnej krawędzi ekranu jest pasek z aktualną składką.
- Bez JavaScriptu cała treść jest widoczna. Przy ograniczonym ruchu nie ma żadnych animacji.

### 14.3 Wydajność i dostępność
- Najwyżej 3 tafle `backdrop-filter` w widoku (2 na telefonie). Produkty, zawody, kroki i FAQ są jedną taflą z liniami włoskowymi zamiast wielu kart.
- Zdjęcie hero jest `<img fetchpriority="high">` w `<picture>` (1024 px na telefonie), a nie tłem w CSS. Tła pozostałych scen ładują się przy zbliżeniu.
- Fonty: Cormorant 600 i 600 kursywa (500), Poppins 400 i 500. Do tego fonty zastępcze o zgodnych metrykach, więc nie ma skoku układu (CLS 0,006).
- Brak atrybutów `style` (zgodność z CSP z nonce). Jest blok `forced-colors`. Wynik kalkulatora jest ogłaszany przez jeden `role="status"`.
- Twarde spacje i polska typografia w całym tekście. Kontrast zmierzono na wyrenderowanym szkle i zdjęciach: wszystkie teksty przechodzą AA.

### 14.4 Makiety Strefy Klienta
`design/v3/strefa/`: `strefa.css` (wspólna warstwa aplikacji na tokenach v3), `logowanie.html`, `panel.html`, `dam-prace.html`, `szkolenia.html`. Opis funkcji jest w `11-strefa-klienta.md`. Ekrany przełącza się paskiem makiety na górze strony. Bez JS wszystkie ekrany są widoczne jeden pod drugim. „Szukam pracy” jest tylko podglądem z oznaczeniem „funkcja nieaktywna” (D-E).

### 14.5 Do dostarczenia
- Logo w SVG oraz jasna wersja na ciemne tła. Do tego czasu: zmniejszona wersja PNG (obecny plik ma 3000 px i 41 KB).
- Wersje AVIF czterech zdjęć, które dadzą około 60% mniej danych, oraz kadr hero 4:3 na telefon. Wszystko można zrobić z istniejących plików.
- Dane do stopki i schema.org: telefon i e-mail biura – w makiecie oznaczone jako miejsce do uzupełnienia.

## 15. Strona OC i nowe komponenty (00, D29, D30)

Lista zabiegów (`snippets/zabiegi-oc-beauty.json`) i treść klauzuli ochrony prawnej (`snippets/klauzula-ochrona-prawna.json`) wchodzą do interfejsu w trzech nowych komponentach. Makiety: wyszukiwarka i dialog w kalkulatorze `makieta-v3.html`, długa lista i pełna klauzula w `oc-beauty.html`. Treść list i klauzuli w makietach jest generowana z tych plików, bez ręcznych zmian.

**Wyszukiwarka zabiegów w kalkulatorze (combobox).**
- Wzorzec ARIA 1.2: pole `role="combobox"` z `aria-autocomplete="list"` i lista `role="listbox"`; bez automatycznego wyboru – zabieg wybiera się Enterem albo kliknięciem. Strzałki, Home/End, Esc (zamyka listę, drugi raz czyści pole) i `aria-activedescendant` jak we wzorcu; fokus zostaje w polu.
- Widoczna etykieta „Sprawdź, w której grupie jest Twój zabieg” i stały opis pod polem (`aria-describedby`): „Pokażemy grupę ryzyka, do której zabieg przypisano w programie. Zakres i wyłączenia określają warunki ubezpieczenia programu.” Wyszukiwarka nie rozstrzyga o objęciu ochroną.
- Szukanie po nazwie z listy programu (bez względu na wielkość liter i polskie znaki). Lista jest 1:1 jak na listach źródłowych (00, D29), więc wyszukiwarka nie szuka po innych nazwach; synonimy mogą wrócić dopiero po ułożeniu listy (`snippets/zabiegi-oc-beauty-propozycje.json`). Najwyżej 8 podpowiedzi, każda z plakietką „Grupa N”. Pod listą link „Pokaż wszystkie wyniki na liście zabiegów” do `oc-beauty.html#zabiegi`.
- Wybór zaznacza kafelek grupy i dodaje zabieg do „Wybranych zabiegów” (trafiają do zgłoszenia jako identyfikatory – 02, pkt 2.3). Usunięcie zabiegu nie odznacza grupy – grupę odznacza się kafelkiem. Przy grupie 4 komunikat dodaje: „Zabiegi z grupy 4 wymagają ankiety ERGO Hestii i oceny ryzyka przez ubezpieczyciela.”
- Brak wyniku: „Nie znaleźliśmy „…” na liście zabiegów programu. Nie ma Twojego zabiegu? Zapytaj doradcę”. Bez podpowiedzi „podobnych” zabiegów z innej grupy.
- Komunikaty dla czytników ekranu idą przez jeden `role="status"` kalkulatora, z opóźnieniem (bez czytania każdego znaku).
- Opcje mają co najmniej 48 px wysokości; lista przewija się wewnątrz (`max-height: min(440px, 58vh)`), strona się nie przesuwa w poziomie.
- Lista podpowiedzi nie jest taflą szkła (pełne tło ivory) – limit 3 tafli `backdrop-filter` w widoku zostaje.
- Bez JavaScriptu wyszukiwarka jest ukryta, a pod kafelkami grup zostaje link „Pełna lista zabiegów (117)”.

**Dialog z treścią klauzuli.**
- Natywny `<dialog>` otwierany `showModal()` z przycisku „Treść klauzuli” przy polu ochrony prawnej (+92 zł) i z odnośnika w FAQ. Esc i „Zamknij” zamykają, fokus wraca do przycisku, który otworzył dialog.
- Nagłówek „Klauzula ochrony prawnej”, pod nim pełna treść: tytuł klauzuli i 12 punktów z wyliczeniami w pkt 3, 5 i 6 – dosłownie, bez skrótów i parafrazy. Treść przewija się wewnątrz obszaru `role="region"` z `tabindex="0"` (przewijanie klawiaturą).
- Tło ivory bez `backdrop-filter` (to nie jest tafla szkła), tło za dialogiem midnight 72 %.
- Bez JavaScriptu przycisk jest zwykłym odnośnikiem do `/ubezpieczenia/oc-beauty#ochrona-prawna`.

**Długa lista zabiegów (strona OC, `#zabiegi`).**
- Cała lista jest w HTML z serwera: cztery sekcje grup z nagłówkami H3, nazwą grupy z pliku (opis tylko przy grupie 4), liczbą zabiegów i stawkami z taryfy (grupa 4: „wycena indywidualna – ankieta ERGO Hestii”), a zabiegi w `<details open>` – bez JS wszystko jest widoczne.
- Nawigacja „Przejdź do grupy” z liczbą zabiegów w grupie (`#grupa-1`…`#grupa-4`).
- Filtr `role="search"` (ulepszenie, ukryty bez JS): zawęża listę w miejscu po nazwie z listy programu (bez względu na wielkość liter i polskie znaki) i aktualizuje liczniki „n z 40”; wynik ogłasza licznik `aria-live="polite"` z opóźnieniem 350 ms. Brak wyniku: komunikat z linkiem „zapytaj doradcę”.
- Każdy zabieg ma kotwicę równą `slug` z pliku. Odnośnik z zewnątrz (np. z artykułu bazy wiedzy; z `/dla-kogo/<zawod>` dopiero po ułożeniu listy – w v1 te strony linkują do `#grupa-N`) czyści filtr, rozwija grupę i przewija do zabiegu; zabieg wskazany kotwicą wyróżnia granatowa linia z lewej (`:target`), w trybie wymuszonych kolorów – obrys.
- Grupy i narzędzia listy to jasne tafle `glass--tint` bez `backdrop-filter`, więc długa lista nie podnosi liczby tafli w widoku.
- Pod listą stałe zdanie: lista przypisuje zabiegi do grup ryzyka programu; zakres ochrony i wyłączenia określają warunki ubezpieczenia programu; zabiegi z grupy 4 wymagają ankiety ERGO Hestii i oceny ryzyka przez ubezpieczyciela. Obok reguły łączenia grup z taryfy i przyciski „Policz składkę” i „Nie ma Twojego zabiegu? Zapytaj doradcę”.
- Kwoty są stałe (taryfa programu) – bez słów „orientacyjna”, „szacunkowa”, „przykładowa”. Żaden wariant ani grupa nie ma oznaczenia „polecany”.

**Klauzula na stronie OC (`#ochrona-prawna`).** Ta sama treść co w dialogu, jako lista numerowana z cyframi w Cormorant Garamond; obok krótkie wprowadzenie prostym językiem (nie zastępuje treści) i fakty: składka 92 zł rocznie, także przy zespole 6–8 osób. W Strefie Klienta ta sama treść jest na karcie polisy OC z ochroną prawną (11, pkt 4.4).

Wspólne wymagania dla trzech komponentów: brak tekstu poniżej 12 px, kontrast AA na wyrenderowanym tle, brak poziomego przewijania od 360 do 1440 px, ruch tylko jako ulepszenie (`prefers-reduced-motion` wyłącza animacje). Przed publikacją sekcji `#zabiegi` i `#ochrona-prawna` – odpowiedzi na pytania z 00, rozdział 13, pkt 10. KRS, NIP i REGON Aura Expert sp. z o.o. są już wpisane w stopce makiety. Status i numer wpisu są znane od 12.11.2026: Aura Expert jest agentem ubezpieczeniowym (nie brokerem), wpis w Rejestrze Pośredników Ubezpieczeniowych nr 11229690/A, IOD: iod@auraexpert.pl – nawias „do uzupełnienia” w stopce makiety trzeba zastąpić tym zapisem (skrót w stopce, pełna formuła na `/informacje-prawne`; `snippets/legal-distributor.json`).

## 16. Kafelki ubezpieczeń: linia ceny i kafelek klikalny w całości (13.11.2026, ulepszenie 1)

Dotyczy sekcji `#ubezpieczenia` na stronie głównej (`makieta-v3.html`, sześć jasnych kafelków `.product` w `.ledger--light`).

- **Układ kafelka:** ikona i tag ubezpieczyciela → nazwa produktu (H3) → krótki opis → linia ceny → jedna akcja. Wiersz opisu rośnie (`grid-template-rows: auto auto 1fr auto auto`), więc linia ceny i akcja stoją na tej samej wysokości we wszystkich kafelkach rzędu.
- **Opisy:** po 2–3 linijki (sprawdzone przy 1440, 768 i 390 px; przy 320 px 4–5 linijek), bez kwot i bez zdań, które mogłyby się rozjechać z podstronami. Kwoty są tylko w linii ceny. Opis utraty dochodu nie zawęża odbiorców do samozatrudnionych („Prywatne L4: miesięczne świadczenie… – przy działalności, B2B i na etacie”; podstrona: do 80% dochodu przy działalności i B2B, do 65% przy umowie o pracę i zleceniu).
- **Linia ceny (`.product-price`):** cienka złota linia nad nią (ozdoba na jasnym), „od” i jednostka w Poppins (`--text-sm`, taupe), liczba w Cormorant Garamond 600, granat, cyfry nautyczne wyłączone (`lining-nums tabular-nums`). Treść – składki stałe z taryf, bez słów „orientacyjna/szacunkowa”:
  - OC dla branży beauty: od 400 zł rocznie; Tax Protect: od 1 532 zł rocznie; NNW dla dzieci: od 40 zł rocznie za dziecko; Grupowe ERGO dla beauty: od 58 zł za osobę / mies. (główna kwota – zespół, ERGO Życie w Biznesie), pod nią drugi wiersz `.pp-dop` „ERGO Razem: od 57 zł / mies.” – kwota 57 zł zawsze z nazwą produktu, nigdy sama (ten sam zapis co w panelu menu)
  - Utrata dochodu: „Składkę wylicza ubezpieczyciel – po ocenie ryzyka”; opieka medyczna: „Według cennika programu – zależnie od liczby osób” (wariant tekstowy `.product-price--text`: Cormorant 1,5 rem, dopisek w Poppins pod spodem).
- **Cały kafelek klikalny („stretched link”):** jedynym linkiem do strony produktu jest nazwa w H3 (`a.product-link`); jej `::after` (`position:absolute; inset:0; z-index:1`) kryje kafelek (`.product{position:relative}`). Bez zagnieżdżania elementów interaktywnych. Opieka medyczna nie ma podstrony w nawigacji: w makiecie nazwa prowadzi do formularza kontaktu (`#kontakt` + `data-produkt="opieka-medyczna"`, tak samo jak menu i szuflada – wcześniej ścieżka produkcyjna dawała 404 w makiecie), produkcyjnie `/ubezpieczenia/opieka-medyczna`. Stopki zostają przy ścieżce produkcyjnej (dozwolonej w faktach) – świadoma różnica do czasu decyzji o podstronie. Za nazwą stoi granatowy szewron (`aria-hidden`) – sygnał „przejdź dalej” także na dotyku, bez tekstu, który rozjechałby się z nazwą dostępną linku (głosowe sterowanie: nazwa linku = nazwa produktu).
- **Druga akcja nad warstwą linku** (`.product-actions`, `position:relative; z-index:2`, cel 44 px): OC i Tax Protect – „Oblicz składkę” (`data-calc="oc"` / `"tax"`, otwiera właściwą zakładkę kalkulatora), NNW – „Kup online u Colonnade” z ikoną ↗ (`aria-hidden`, ten sam znak „strona zewnętrzna” co w pasku akcji; `https://bit.ly/szkolneNNW2026`, `target="_blank" rel="noopener"`, w nazwie dostępnej informacja o przejściu na stronę ubezpieczyciela w nowej karcie), Utrata dochodu, Grupowe ERGO i opieka medyczna – „Zapytaj doradcę” (`#kontakt`, `data-produkt` ustawia temat). Dotychczasowy „Poznaj ubezpieczenie” zniknął – jego rolę przejął cały kafelek.
- **Stany:** hover (tylko `hover:hover` i `pointer:fine`) – jaśniejsze tło kafelka, złote podkreślenie nazwy, szewron przesuwa się o 0,15 em; gdy kursor jest nad akcją, podkreślenie nazwy znika (widać, co zostanie kliknięte). Fokus na nazwie – obrys całego kafelka (`.product:has(.product-link:focus-visible)`, granat 2 px, `outline-offset:-6px`) i podkreślenie nazwy; bez `:has` zostaje zwykły obrys linku. Akcja ma własny obrys. `prefers-reduced-motion` wyłącza przejścia (reguła globalna).
- **Kolejność klawiatury:** nazwa produktu → akcja, kafelek po kafelku (12 przystanków), dalej zakładki kalkulatora.
- **Kompromis wzorca:** tekstu opisu nie da się zaznaczyć myszą (leży pod warstwą linku) – przyjęte, bo opis jest krótki i powtarza go podstrona.
- **Testy (13.11.2026):** brak przewijania w poziomie przy 1440/768/390/320 px z JS i bez JS; klik w opis prowadzi na stronę produktu, klik w akcję – do akcji (formularz dostaje temat); w widoku 2 tafle `backdrop-filter`; brak tekstu < 12 px; `shot_v3` (980 zł / Wycena indywidualna / errors []) i `check_zabiegi_1do1` – OK.

## 17. Wspólne komponenty: menu „Ubezpieczenia” i pasek akcji na telefonie (13.11.2026, ulepszenia 2+3)

Dotyczy sześciu stron publicznych: `makieta-v3.html`, `oc-beauty.html`, `tax-protect.html`, `utrata-dochodu.html`, `nnw-dzieci.html`, `grupowe-ergo.html`. Komponenty są zbudowane **raz** jako szablon w generatorze `gen_wspolne.py` (scratchpad `tools/`) i wstawione do stron w blokach `<!-- gen:menu-produkty -->`, `<!-- gen:menu-mobilne -->`, `<!-- gen:pasek-akcji -->`, `<!-- gen:wspolne-css -->` (koniec `<head>`) i `<!-- gen:wspolne-js -->` (koniec `<body>`). Bloki zmienia się wyłącznie generatorem (`--check` sprawdza, czy są aktualne). Generator oznacza bieżący produkt `aria-current="page"` na podstawie nazwy pliku i ustawia linki względne: na stronie głównej `#…`, na podstronach `makieta-v3.html#…` (produkcyjnie `/` i `/#…`). W Next.js to jeden komponent nagłówka i jeden komponent paska z tą samą listą produktów.

**Treść (jedno źródło – lista `PRODUKTY` w generatorze, tylko fakty programu, składki stałe):** OC dla branży beauty – od 400 zł rocznie; Tax Protect – od 1 532 zł rocznie; Utrata dochodu – „Składkę wylicza ubezpieczyciel po ocenie ryzyka”; NNW dla dzieci – od 40 zł rocznie za dziecko, zakup online u Colonnade; Grupowe ERGO dla beauty – zespół od 58 zł za osobę / mies., ERGO Razem od 57 zł / mies.; opieka medyczna – według cennika programu.

**Nazwy produktów (13.11.2026, po kontroli):** wszędzie te same co w menu i na podstronach – „NNW dla dzieci” i „Grupowe ERGO dla beauty” (kafelek, scena „clue”, temat formularza kontaktu, karty „Inne ubezpieczenia” na podstronach, stopki 6 stron, opis organizacji w JSON-LD). Kafelki i stopki są pisane ręcznie, więc przy zmianie nazwy w `PRODUKTY` trzeba je poprawić punktowo (słowa kluczowe SEO i kategorie JSON-LD bez zmian). Opieka medyczna nie ma podstrony: w makiecie prowadzi do formularza kontaktu z tematem (`?produkt=opieka-medyczna#kontakt`, na stronie głównej `#kontakt` + `data-produkt`), produkcyjnie `/ubezpieczenia/opieka-medyczna`. Bez nowych odnośników do formularzy ERGO (zostaną przeniesione do portalu).

### 17.1 Menu „Ubezpieczenia” (desktop ≥ 1200 px)

- **Wzorzec disclosure, nie menu ARIA:** `button[aria-expanded][aria-controls="menu-produkty"]` + panel `div#menu-produkty[hidden]` bezpośrednio po przycisku (kolejność Tab: przycisk → panel → reszta nagłówka). Bez `role=menu`/`menuitem` – w panelu są zwykłe linki, nawigacja Tab/Shift+Tab.
- **Bez JS:** w HTML stoi link „Ubezpieczenia” do `makieta-v3.html#ubezpieczenia` (na stronie głównej `#ubezpieczenia`); skrypt zamienia go na przycisk ze szewronem. Panel bez JS pozostaje ukryty.
- **Panel:** nieprzezroczyste ivory (bez `backdrop-filter` – nie liczy się do limitu 3 tafli; w teście z otwartym panelem ≤ 3 tafle w widoku), złota cienka linia pod nagłówkiem panelu (ozdoba na jasnym), cień jak belka w trybie kompaktowym, promień kart. Siatka 3 × 2: ikona `lux-*` (32 px), nazwa (Cormorant), jedno zdanie (Poppins `--text-sm`, taupe), cena (Poppins 500, cyfry `lining-nums tabular-nums`). Cena to osobne wiersze (`.mega-cena`), żeby kwota nie łamała się w środku frazy i nie mieszała z dopiskiem: Grupowe ERGO – „Zespół: od 58 zł za osobę / mies.” i „ERGO Razem: od 57 zł / mies.”; NNW – „od 40 zł rocznie za dziecko” + dopisek „Zakup online u Colonnade” (`.mega-dop`, 400, taupe). **Nazwa dostępna pozycji = nazwa produktu** (`aria-labelledby` na `.mega-name`), opis i cena przez `aria-describedby` – przy Tab czytnik nie czyta całego akapitu; „Jesteś tutaj” ma `aria-hidden` (informację niesie `aria-current="page"`). Bieżący produkt: tło parchment, złoty pasek 2 px z lewej, dopisek „Jesteś tutaj” i `aria-current="page"`; na podstronie produktu przycisk „Ubezpieczenia” ma złote podkreślenie. Na dole „Oblicz składkę OC” (btn-navy, `#kalkulator`) i „Oblicz składkę Tax Protect” (btn-ghost, `#kalkulator-tax` – otwiera zakładkę Tax; ta sama nazwa akcji co w kafelku i pasku, bez „porównaj”), u góry link „Wszystkie ubezpieczenia” (`#ubezpieczenia`). Panel mieści się w 900 px wysokości; przy niższych oknach przewija się wewnątrz (`max-height: 100vh − 116px`).
- **Zamykanie:** Esc (fokus wraca na przycisk, gdy był w panelu lub na przycisku), klik poza, Tab/Shift+Tab poza pozycję menu, wybór linku, schowanie nagłówka przy przewijaniu, przewinięcie strony o ponad 120 px od otwarcia (panel otwarty klikiem lub klawiaturą, fokus poza panelem – fokus na przycisku blokuje chowanie nagłówka, więc samo „schowanie nagłówka” nie wystarczało; fokus nie jest przenoszony), zejście poniżej 1200 px.
- **Najechanie tylko jako dodatek:** wyłącznie mysz (`pointerType=mouse`, `hover:hover` i `pointer:fine`), otwarcie po 180 ms, zamknięcie 320 ms po opuszczeniu (przejście kursorem przez szczelinę do panelu nie zamyka – bez migotania). Klik zawsze działa: klik w przycisk przy panelu otwartym najechaniem „przypina” panel (nie zamyka go), kolejny klik zamyka.

### 17.2 Szuflada (< 1200 px)

Na górze `<details class="menu">`: „Oblicz składkę OC” (btn-navy, pełna szerokość), etykieta „Ubezpieczenia” i lista 6 produktów (ikona 22 px, nazwa, cena – na telefonie pod nazwą, od 600 px po prawej, wiersz ≥ 52 px; bieżący produkt – parchment + złoty pasek + `aria-current`). **Krótkie ceny nie zmieniają sensu kwoty:** „od 58 zł za osobę / mies.” (Grupowe ERGO – ta sama kwota i jednostka co kafelek i podstrona; 57 zł z ERGO Razem jest tylko tam, gdzie stoi nazwa ERGO Razem), „od 40 zł rocznie za dziecko”, „składkę wylicza ubezpieczyciel po ocenie ryzyka”, „według cennika programu”. Cena może zawijać się w 2–3 linijki (przy 320 px utrata dochodu – 3 linijki), kwoty spięte `&nbsp;`; brak przewijania w poziomie od 320 px. Dawna pozycja „Ubezpieczenia” w szufladzie zastąpiona listą; pozostałe pozycje strony bez zmian. Istniejący skrypt szuflady zamyka ją po wyborze produktu.

### 17.3 Pasek akcji na telefonie (< 768 px)

- **Jeden wzorzec zamiast lokalnych pasków:** usunięto `.sticky-cta` (element, style, skrypt i reguły `has-sticky`) ze wszystkich 6 stron (jednorazowa migracja `migracja_pasek.py`).
- **Landmark:** `<aside class="pasek-akcji" aria-label="Szybkie akcje">` – czytnik może do niego przeskoczyć (axe „region” – czysto).
- **Wygląd:** przyklejony do dołu (`left/right: max(12 px, env(safe-area-inset-left/right))`, `bottom: 10 px + env(safe-area-inset-bottom)`), jedna nieprzezroczysta płyta midnight (bez `backdrop-filter`), złota cienka ramka, cień. Dwa przyciski ≥ 48 px: akcja kontekstowa (ivory, tekst navy) i „Zadzwoń” (obrys gold-light, ikona słuchawki, numer +48 504 400 901 widoczny pod słowem w gold-light – złoty tekst tylko na ciemnym; nazwa dostępna „Zadzwoń: +48 504 400 901”, `tel:+48504400901`). Przy 320–390 px akcja kontekstowa może łamać się w 2 linijki; poniżej 360 px bez ikony słuchawki. Układ `flex-wrap` (akcja `flex: 1 1 8rem`, telefon `flex: 1 0 auto`): przy powiększonym samym tekście (160% przy 320 px, 175% przy 360 px, 200% przy 390 px) przyciski przechodzą do dwóch wierszy na pełną szerokość zamiast obcinać etykietę (WCAG 1.4.4).
- **Akcja kontekstowa:** strona główna i OC – „Oblicz składkę” → `#kalkulator` / `makieta-v3.html#kalkulator`; Tax Protect – „Oblicz składkę” → `makieta-v3.html#kalkulator-tax`; NNW – widoczne „Kup u Colonnade” + ↗ → `https://bit.ly/szkolneNNW2026` (`target="_blank" rel="noopener"`, `aria-describedby="opis-zewn"`: strona ubezpieczyciela Colonnade w nowej karcie; nazwa dostępna „Kup u Colonnade – NNW dla dzieci” zaczyna się od widocznej etykiety); Utrata dochodu i Grupowe ERGO – „Zapytaj doradcę” → `makieta-v3.html?produkt=…#kontakt` (wcześniej UD prowadził do zewnętrznego wniosku; „Zapytaj doradcę” to **decyzja projektowa – do potwierdzenia u zleceniodawcy**: fakty jej nie przesądzają, a główne akcje strony UD to wniosek na utratadochodu.pl i zakup u Leadenhall).
- **Kiedy widoczny:** tylko przy oknie wyższym niż 500 px (telefon w poziomie – bez paska, ta sama granica co logika nagłówka `max-height: 500px`; wcześniej pasek zabierał tam 19–22% wysokości), po przewinięciu poza pierwszy ekran (90% wysokości okna). Chowa się, gdy fokus jest w polu formularza (tekst, select, textarea) lub `visualViewport` wskazuje otwartą klawiaturę, gdy otwarta jest szuflada menu, gdy widoczne są: pasek ceny kalkulatora `.calc-peek` (nie dublujemy dwóch przyklejonych pasków), formularz kontaktu `.lead-form`, karta końcowa `.end-card`, przyciski otwarcia `.hero-actions` / pod taryfą `.tariff-actions` (na stronie głównej, OC, Tax i NNW to ta sama akcja; na UD i Grupowym ERGO akcja w hero jest inna, ale pasek też się chowa – nie dublujemy wezwań na jednym ekranie) i stopka. Ukryty pasek ma `visibility:hidden` + `inert` (poza kolejnością Tab i drzewem dostępności).
- **Fokus w pasku (poprawka 13.11.2026):** widoczność wymusza tylko fokus z klawiatury (`:focus-visible` w pasku) – wcześniej każdy fokus (`activeElement`) wygrywał z warunkami ukrycia, więc po tapnięciu „Zadzwoń” (tel:), „Kup u Colonnade” (nowa karta) albo po powrocie z bfcache pasek zostawał na stałe i zasłaniał `.calc-peek`, formularz, kartę końcową i stopkę. Teraz: po kliknięciu/tapnięciu (`click` z `detail > 0`) fokus jest zdejmowany z linku; `pageshow` przelicza stan (bfcache); gdy zachodzi warunek ukrycia, a fokus z klawiatury jest w pasku, fokus przechodzi na nagłówek bieżącej sekcji (`tabindex=-1`, `preventScroll`), dopiero potem `inert`. Bez JS (lub bez IntersectionObserver) pasek się nie pokazuje – te same akcje są w treści.
- **Nic nie zasłania:** pasek znika przy stopce, więc koniec strony nigdy nie leży pod nim – dlatego zamiast stałego `padding-bottom` na `body` (zostawiał pusty pas pod ciemną stopką) jest `scroll-padding-bottom: 92 px + safe-area`, żeby elementy z fokusem i cele kotwic nie lądowały pod paskiem (WCAG 2.4.11).
- **Ruch:** wjazd od dołu (`transform`, `--bp-dur-3`, `--ease-lux`); przy `prefers-reduced-motion: reduce` bez animacji. W druku ukryty.

### 17.4 Testy (13.11.2026)

Po kontroli (13.11.2026, poprawki): pasek po tapnięciu „Zadzwoń”/„Kup u Colonnade” widoczny tylko w części pozycji przewinięcia i bez nakładania na `.calc-peek`, formularz, kartę końcową i stopkę (wcześniej 70/70 i 42/42); fokus z klawiatury w pasku przy zjeździe do stopki trafia na nagłówek sekcji, pasek znika; tekst 160–200% – bez obcięcia etykiet; 667×375, 740×360, 568×320 – brak paska; axe `region` – czysto na 6 stronach; panel otwarty klikiem zamyka się po przewinięciu kółkiem; panel 1200×720 mieści się bez przewijania.

Playwright na 6 stronach × 1440/1024/768/390/360/320 px: brak błędów JS, brak przewijania w poziomie (góra i dół strony), brak tekstu < 12 px; desktop – przycisk z `aria-expanded`/`aria-controls`, brak `role=menu`, klik otwiera, Tab wchodzi do panelu, Shift+Tab wraca na przycisk (panel otwarty), Esc zamyka i oddaje fokus, Tab i Shift+Tab poza pozycję zamykają, klik poza zamyka, najechanie otwiera dopiero po opóźnieniu i nie gaśnie przy przejściu do panelu, `aria-current` tylko na bieżącym produkcie (na stronie głównej brak), ≤ 3 tafle w widoku, cele ≥ 24 px (akcje ≥ 44 px); telefon – szuflada z przyciskiem OC ≥ 44 px i 6 wierszami ≥ 44 px, pasek ukryty na pierwszym ekranie, przy przewijaniu co 0,45 ekranu nigdy nie nachodzi na `.calc-peek`, formularz kontaktu, kartę końcową ani stopkę, chowa się przy fokusie w polu; bez JS – link do `#ubezpieczenia`, panel i pasek ukryte. `shot_v3` (980 zł / Wycena indywidualna / brak < 12 px / errors []) i `check_zabiegi_1do1` – OK.

### 17.5 Otwarte po kontroli (13.11.2026)

- **Opieka medyczna – podstrona:** w repo jest makieta `opieka-medyczna.html` (inna praca, commit 01c196d) z ręczną kopią bloków menu, bez wpisu w `PRODUKTY` generatora; żadna z 6 stron do niej nie linkuje. Decyzja zleceniodawcy: (a) zostaje „brak podstrony” (stan obecny: kafelek, menu i szuflada → formularz kontaktu z tematem, stopki → `/ubezpieczenia/opieka-medyczna`) albo (b) podstrona wchodzi – wtedy w `PRODUKTY` `plik='opieka-medyczna.html'`, strona na listę `STRONY` generatora, kafelek i stopki na plik, aktualizacja §16–17.
- **Pasek na utracie dochodu:** „Zapytaj doradcę” czy ta sama akcja co w hero (wniosek / zakup u Leadenhall) – do potwierdzenia (§17.3).
- **Formularze ERGO:** strona główna (Jak to działa, krok 2; `#lead-next`; podpowiedź po wysłaniu formularza dla grupowego ERGO) i `grupowe-ergo.html` (5 linków) nadal wskazują ergo.auraexpert.pl / ergo.beautypolisa.eu – stan sprzed ulepszeń 1+2+3, bez nowych linków. Zadanie następcze: po przeniesieniu formularzy do portalu podmienić teksty i linki na ścieżkę w portalu.

## 18. Słownik pojęć i dymki z definicjami (13.11.2026)

Źródło treści: `snippets/slownik.json` (95 haseł, 10 kategorii; reguły oznaczania w `$comment`). Strona i oznaczenia są generowane – nie edytuje się ich ręcznie: `slownik/gen_strona.py` tworzy `design/v3/slownik.html` (makieta `/slownik`), `slownik/gen_terminy.py` oznacza pojęcia w treści 9 stron (6 publicznych i `strefa/logowanie`, `panel`, `dam-prace`) i wstawia bloki `<!-- gen:slownik-css -->` (koniec `<head>`) oraz `<!-- gen:slownik-js -->` (koniec `<body>`). Oba skrypty (scratchpad `slownik/`) są idempotentne i mają `--check`; `slownik.html` jest też na liście `STRONY` w `gen_wspolne.py` (menu „Ubezpieczenia”, szuflada i pasek akcji – bez bieżącego produktu, akcja paska „Zapytaj doradcę” → formularz bez tematu). W Next.js: trasa `/slownik` z danych JSON + komponent `<Termin id>` i jeden komponent dymka.

### 18.1 Strona `/slownik`

- **Szkielet jak podstrony produktów** (nagłówek, stopka, sprite i skrypt strony kopiowane z `tax-protect.html`). Okruszki Strona główna › Słownik pojęć, H1 „Słownik pojęć ubezpieczeniowych”, wstęp z zastrzeżeniem z `$comment`: definicje wyjaśniają pojęcia prostym językiem, o zakresie ochrony decydują OWU konkretnego produktu i umowa. To samo zdanie stoi pod listą.
- **Układ:** od 1024 px panel narzędzi (lewa kolumna, 340 px) i lista; poniżej – panel nad listą. Panel jest przyklejony (`sticky`, `top: 108px`, przewija się wewnątrz) tylko przy oknie ≥ 1024 × 760 px – leży w osobnej kolumnie, więc niczego nie zasłania; nagłówek strony (dół belki ~82 px) nie nachodzi na panel. Na telefonie i w niskich oknach nic nie jest przyklejone.
- **Wyszukiwarka** (`form role="search"`, `input type="search"` z widoczną etykietą „Szukaj pojęcia” i opisem): filtruje w miejscu po terminie i aliasach, bez względu na wielkość liter i polskie znaki („skladka” → „Składka”, „L4” → zasiłek chorobowy i prywatne L4). Licznik `aria-live="polite"` (z opóźnieniem 350 ms): „Wszystkie hasła: 95”, „Znaleziono 3 hasła w kategorii „…””. Stan pusty: „Brak haseł dla „…””, podpowiedź (krótszy fragment, kategoria „Wszystkie”), przycisk „Pokaż wszystkie hasła” i link „Nie ma pojęcia? Zapytaj doradcę”. Esc w polu czyści frazę.
- **Kategorie:** grupa radio w `fieldset` z `legend` (jeden wybór naraz – dlatego radio, nie przyciski `aria-pressed`), chipy z liczbą haseł, cel ≥ 40 px.
- **Indeks A–Z:** polski alfabet bez Ą, Ę, Ń (29 liter); litery bez haseł są nieaktywne i ukryte przed czytnikiem, a przy filtrowaniu litera bez widocznych haseł traci `href` (`aria-disabled`), nazwa dostępna mówi o liczbie haseł („K – 7 haseł”). Pod każdą literą „Wróć do indeksu A–Z”.
- **Hasło** (`article#haslo-<id>`, H2 – litera, H3 – termin): kategoria, definicja, „Na przykład” (blok ze złotą linią), „Zobacz też” (`#haslo-…`), „Gdzie w portalu” (linki do makiet), „Źródło” skrótowo (przepis z artykułem, słowniczek ERGO, serwis zewnętrzny albo „strony / ustalenia programu BeautyPolisa” – bez wewnętrznych ścieżek), `do_potwierdzenia` jako adnotacja makiety `.mock-note` (w produkcji nie publikujemy). Z JS – przycisk „Kopiuj link” (nazwa dostępna z nazwą hasła, potwierdzenie w przycisku i w `role="status"`). `:target` – granatowa linia z lewej. Odnośnik do hasła ukrytego filtrem (kotwica w adresie, „Zobacz też”) najpierw czyści filtry.
- **Bez JS:** pełna lista 95 haseł i działający indeks (kotwice); wyszukiwarka i kategorie są ukryte (`hidden`), przycisków kopiowania nie ma.
- **Szkło:** tafle `backdrop-filter` tylko w belce nagłówka, panelu otwarcia i stopce; panel narzędzi i karty liter są kryjące (ivory, złota linia) – w widoku ≤ 3 tafle.
- **SEO:** `title`, `meta description`, `canonical` `https://beautypolisa.eu/slownik`, Open Graph; JSON-LD: `WebPage`, `BreadcrumbList`, `DefinedTermSet` z 95 `DefinedTerm` (`name`, `description` = pełna definicja, `url` = `/slownik#haslo-<id>`, `inDefinedTermSet`) i węzły organizacji jak na podstronach.
- **Linki do słownika:** „Słownik pojęć” w stopce wszystkich stron – w kolumnie informacyjnej „BeautyPolisa” (po „Dokumenty i OWU”), w Strefie Klienta w nawigacji „Stopka” (po „Kontakt z doradcą”) – oraz w szufladzie menu stron publicznych w sekcji pod linią (po „Szkolenia”). Panel produktów i menu desktopowe – bez zmian (nie ma w nich sekcji informacyjnej). Na `slownik.html` pozycja ma `aria-current="page"`.

### 18.2 Oznaczanie pojęć w treści

- **Gdzie:** tylko tekst w `<p>` i `<li>` wewnątrz `<main>`. Nigdy w: nagłówkach i `summary`, linkach, przyciskach, etykietach i polach formularzy (cały `form`/`fieldset`), tabelach (taryfy), okruszkach, etykietach typu eyebrow, nazwach zabiegów (lista `#zabiegi`), dosłownej treści klauzuli ochrony prawnej (`.clause`, dialog `.klauzula`), dokumentach prawnych Strefy (regulaminy, klauzula informacyjna, punkty kontaktowe), adnotacjach makiety, regionach `aria-live`/`role="status"`, elementach ukrytych, kartach z linkiem rozciągniętym na całą kartę (`.product`, `.offer` – link w środku byłby niedostępny myszą), stopce prawnej i blokach `gen:*`/`GEN:*` (np. FAQ generowane z danych – ich generatory nadpisałyby oznaczenia).
- **Reguły z `$comment`:** bez rozróżniania wielkości liter, `’` = `'`, tylko całe wyrazy, najdłuższe dopasowanie wygrywa, tylko pierwsze wystąpienie hasła na stronie, najwyżej 12 oznaczeń na stronę (w kolejności dokumentu); wyrażenia wykluczone („doradca podatkowy”, „czasowa niezdolność do pracy”, „kod z e-maila” …) blokują dopasowanie; krótkie aliasy (OC, L4, OWU, agent, wariant, taryfa …) tylko w akapitach `<p>`; hasła drugi-skladnik, role-w-strefie, osobisty-link tylko w `strefa/*`; hasła „Doradca Aura Expert” i „Limit” – tylko aliasy (bez gołego „doradca” i „limit”). Reguły są czytane z `$comment` – zmiana listy wykluczeń w JSON zmienia oznaczenia po ponownym uruchomieniu.
- **Bez JS:** `<a class="bp-termin" href="slownik.html#haslo-<id>">` (w `strefa/` – `../slownik.html#…`), tekst w kolorze akapitu, kropkowane podkreślenie 1,5 px (granat; na ciemnym – gold light), na hover – ciągłe. Rozróżnienie nie tylko kolorem (WCAG 1.4.1); link w zdaniu jest wyjątkiem od rozmiaru celu (2.5.8).

### 18.3 Dymek

- **Wzorzec:** treść z linkiem i przyciskiem, więc nie tooltip ani disclosure z samym tekstem, tylko **niemodalny dialog**: `div role="dialog" aria-labelledby` (termin) `aria-describedby` (definicja). Skrypt nadaje oznaczeniu rolę przycisku: `role="button"`, `aria-haspopup="dialog"`, `aria-expanded`, `aria-controls`; `href` zostaje (Ctrl/Cmd/Shift/środkowy przycisk otwierają słownik jak zwykły link).
- **Treść:** pełna nazwa hasła, definicja skrócona do 2 zdań, link „Więcej w słowniku” (`#haslo-<id>`) i przycisk „Zamknij objaśnienie” (44 × 44 px). Dane – `<script type="application/json" id="slownik-dymki">` tylko z użytymi na stronie hasłami.
- **Obsługa:** klik, Enter i Spacja otwierają (drugie użycie zamyka); fokus przechodzi do dialogu; Tab: „Więcej w słowniku” → „Zamknij”, Tab za ostatnim i Shift+Tab przed pierwszym zamykają i oddają fokus pojęciu; Esc i „Zamknij” – to samo; klik poza dymkiem zamyka (fokus zostaje tam, gdzie kliknięto). Najechanie myszą niczego nie otwiera ani nie zamyka – dymek nie znika, gdy kursor jest nad nim, i trwa do zamknięcia (WCAG 1.4.13).
- **Wygląd i miejsce:** kryjące ivory, złota linia, cień, bez `backdrop-filter` (nie liczy się do limitu tafli), tytuł w Cormorant, tekst 15 px. Od 600 px – pod pojęciem (albo nad nim, gdy brak miejsca), w granicach okna z marginesem 16 px, szerokość do 380 px; poniżej 600 px – panel u dołu okna (od krawędzi do krawędzi z marginesem 12 px i `safe-area`, `max-height: 70vh`, przewijanie wewnątrz), nad paskiem akcji (`z-index` 85). Tryb wymuszonych kolorów – ramka `CanvasText`, w druku dymek ukryty, a pojęcie bez podkreślenia.

### 18.4 Testy (13.11.2026)

Playwright (`slownik/test_slownik.js`): 10 stron (9 z oznaczeniami + słownik) × 320/360/390/768/1024/1280/1440 px – brak przewijania w poziomie (góra i dół strony), brak błędów JS, brak tekstu < 12 px (także w otwartym dymku), ≤ 3 tafle `backdrop-filter` w widoku. Dymki na 9 stronach przy 320 i 1280 px: Enter/Spacja/klik otwierają, fokus w dialogu, dymek w granicach okna (przy 320 px – panel u dołu), najechanie go nie zamyka, Esc i „Zamknij” oddają fokus pojęciu, Tab: link → przycisk → powrót do pojęcia, klik poza zamyka, `aria-expanded` się przełącza. Słownik: „skladka” → Składka, „L4” → 2 hasła, stan pusty z licznikiem „Brak haseł dla „…””, kategoria Tax Protect → 2 hasła i nieaktywne litery, „Zobacz też” do hasła spoza filtra czyści filtr, wejście z `#haslo-karencja` (390 i 1440 px) – hasło pod nagłówkiem, panel przyklejony przy 1024–1440 px nie wchodzi pod belkę (108 px vs 86 px), „Kopiuj link” – potwierdzenie; bez JS – 95 haseł, indeks działa, oznaczenia są zwykłymi linkami. axe (WCAG 2.2 AA + best practice): `slownik.html` i `tax-protect.html` z otwartym dymkiem – czysto; `strefa/panel.html` – tylko istniejące wcześniej `region` na pasku makiety. Generatory: `gen_terminy.py --check`, `gen_strona.py --check`, `gen_wspolne.py --check` – aktualne; `shot_v3` (980 zł / Wycena indywidualna / brak < 12 px / errors []) i `check_zabiegi_1do1` – OK.

### 18.5 Otwarte

- Opieka medyczna i Szkolenia (`opieka-medyczna.html`, `strefa/szkolenia.html`) – bez oznaczeń i linku w stopce (inne prace w toku); dołączyć do `STRONY` w `gen_terminy.py` po ich zakończeniu.
- FAQ na `oc-beauty.html` i `utrata-dochodu.html` jest w blokach `GEN:faq` innych generatorów – pojęcia w odpowiedziach nie są oznaczane. Jeśli mają być, oznaczanie trzeba dodać do tamtych generatorów (albo uruchamiać `gen_terminy.py` po nich i wyłączyć wyjątek dla tych bloków).
- Limit 12 oznaczeń na stronę wyczerpuje się w otwarciu i pierwszych sekcjach (strona główna: hero i „Jeden dzień w salonie”) – do decyzji, czy wolimy priorytet haseł (np. pomijać „składka”, „polisa” na stronach, gdzie są oczywiste).
- Produkcyjnie link „Kopiuj link” powinien kopiować adres kanoniczny `https://beautypolisa.eu/slownik#haslo-<id>` (w makiecie – adres pliku).
