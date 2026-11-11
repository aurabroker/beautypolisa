# 10 · Design v3 – old money, całość w szkle

> Ta sekcja zastępuje warstwę wizualną sekcji `09-design-v2-bloom.md` (paleta, typografia, ikony, ilustracje, makieta). Z sekcji 07 nadal obowiązują: lista kontrolna WCAG 2.2 AA, zasady responsywności, inwentarz komponentów, mikrocopy i szablony stron. Z sekcji 09 nadal obowiązują: reguły kalkulatora OC i opis procesu pracy z Bloom.

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

1. **Nagłówek:** jasne szkło, logo z podpisem „created by Aura Consulting”, nawigacja (Ubezpieczenia, Kalkulator, Dla kogo, Jak to działa, Pytania) i przycisk „Umów rozmowę”.
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
- `design/v3/tokens-v3.css`: tokeny, szkło, ikony, przyciski i mapowanie do `@theme` Tailwind 4.
- `design/v3/img/`: cztery zdjęcia w dwóch rozmiarach.
- `design/v3/ikony/`, `ikony-v3-sprite.svg`, `ikony-arkusz-v3.svg`, `ikony-v3-manifest.json`: ikony.
- Wersja v2 (`design/makieta-v2.html`, `design/tokens-v2.css`, `design/bloom/`) zostaje w repozytorium jako historia i jest nieaktualna.

## 12. Decyzje

| # | Decyzja |
|---|---|
| D13 (zmieniona) | Paleta old money: midnight `#141C33`, navy `#2A3B68`, ivory `#F7F3EC`, parchment `#EDE5D8`, gold `#B8975A` (tylko dekor), gold light `#D9C089` (tekst na ciemnym). Nagłówki w Cormorant Garamond, tekst w Poppins. Róż tylko w logo. |
| D14 (zmieniona) | Całość w szkle na zdjęciach z Bloom (jasne, mocne i ciemne szkło ze złotą ramką). Ikony z Bloom cienką linią, jeden kolor. Wyjścia awaryjne szkła są obowiązkowe. |

## 13. Otwarte pytania

1. **Logo na ciemne tło:** w stopce logo stoi na jasnym polu. Potrzebna jest wersja jasna (kość słoniowa i złoto) oraz logo w SVG zamiast PNG.
2. **Zdjęcia:** czy zleceniodawca akceptuje zdjęcia generowane w Bloom na produkcji, czy planuje sesję w prawdziwym salonie w tym samym stylu?
3. **Tryb ciemny:** w v3 strona ma już ciemne sekcje. Osobny tryb ciemny dla całej strony nie jest potrzebny w fazie 1.
