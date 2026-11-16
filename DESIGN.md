---
name: "BeautyPolisa – system projektowy v3 „old money glass”"
version: "1.0"
date: "2026-11-15"
language: pl
status: "kierunek wizualny zatwierdzony przez zleceniodawcę"
preview: docs/koncepcja/design/v3/design-preview.html
rationale: docs/koncepcja/10-design-v3-old-money.md
# Tokeny 1:1 z :root makiet (docs/koncepcja/design/v3/makieta-v3.html:252–281, tak samo na 8 stronach publicznych).
# Klucze = nazwy właściwości CSS. Schematu front matter nie sprawdzono z oryginalną specyfikacją Stitch (host niedostępny z sesji) – zob. „Znane rozbieżności” #14.
colors:
  "--color-midnight": "#141C33"
  "--color-navy": "#2A3B68"
  "--color-navy-deep": "#1E2B4F"
  "--color-ink": "#1B2233"
  "--color-taupe": "#5F574D"
  "--color-ivory": "#F7F3EC"
  "--color-parchment": "#EDE5D8"
  "--color-gold": "#B8975A"
  "--color-gold-light": "#D9C089"
  "--bp-error": "#7A2E2E"
  "--bp-glass-ivory": "rgba(247,243,236,.7)"
  "--bp-glass-ivory-strong": "rgba(247,243,236,.9)"
  "--bp-glass-ivory-tint": "rgba(247,243,236,.84)"
  "--bp-glass-midnight": "rgba(20,28,51,.56)"
  "--bp-glass-midnight-tint": "rgba(20,28,51,.74)"
  "--bp-line-gold": "rgba(184,151,90,.5)"
  "--bp-line-gold-soft": "rgba(184,151,90,.35)"
  "--bp-line-gold-on-dark": "rgba(217,192,137,.32)"
  "--bp-line-gold-on-dark-soft": "rgba(217,192,137,.2)"
  "--bp-line-navy": "rgba(42,59,104,.22)"
  "--bp-line-field": "rgba(42,59,104,.7)"
typography:
  "--font-serif": "'Cormorant Garamond','Cormorant Fallback','Cormorant Fallback 2',Garamond,serif"
  "--font-sans": "'Poppins','Poppins Fallback','Poppins Fallback 2',system-ui,sans-serif"
  "--font-caps": "'Poppins','Poppins Caps Fallback','Poppins Fallback 2',system-ui,sans-serif"
  "--text-xs": ".75rem"
  "--text-sm": ".875rem"
  "--text-body": ".9375rem"
  "--text-base": "1rem"
  "--text-lead": "clamp(1.0625rem,1rem + .25vw,1.125rem)"
  "--text-serif-sm": "1.2rem"
  "--text-serif-md": "1.45rem"
  "--text-h3": "1.65rem"
  "--text-h2": "clamp(2.25rem,1.35rem + 3.4vw,4.25rem)"
  "--text-h1": "clamp(2.75rem,1.4rem + 4.6vw,5.25rem)"
  "--text-display-numeral": "3.4rem"
  "--text-price": "clamp(3rem,2.4rem + 2vw,4.2rem)"
  "--tracking-label": ".2em"
  "--tracking-nav": ".16em"
rounded:
  "--radius-card": "6px"
  "--radius-btn": "3px"
elevation:
  "--shadow-glass": "0 40px 80px -40px rgba(20,28,51,.45)"
  "--shadow-glass-dark": "0 40px 80px -40px rgba(0,0,0,.6)"
  "--blur-glass": "24px"
  "--blur-glass-dark": "22px"
  "--blur-glass-mobile": "16px"
layout:
  "--bp-container": "1240px"
  "--bp-gutter": "clamp(16px,4vw,40px)"
  "--bp-frame-inset": "9px"
  "--bp-z-sticky": "55"
  "--bp-z-header": "60"
  "--bp-z-skip": "100"
motion:
  "--ease-lux": "cubic-bezier(.2,.7,.1,1)"
  "--bp-dur-1": ".2s"
  "--bp-dur-2": ".3s"
  "--bp-dur-3": ".45s"
---

# BeautyPolisa – DESIGN.md (v3 „old money glass”)

**Wersja 1.0 · 15.11.2026.** Portal BeautyPolisa – program ubezpieczeń dla branży beauty prowadzony przez Aura Expert sp. z o.o., agenta ubezpieczeniowego. Kierunek wizualny „v3 old money glass” zatwierdził zleceniodawca.

**Relacja do dokumentu 10.** Ten plik to skrót dla agentów projektujących i kodujących ekrany: wartości, klasy, stany i zasady w jednym miejscu. Uzasadnienia, historia decyzji i wyniki testów są w `docs/koncepcja/10-design-v3-old-money.md` (rozdziały 1–18). Gdy liczba w dokumencie 10 różni się od CSS, obowiązuje CSS makiet – lista różnic jest w sekcji „Znane rozbieżności” na końcu.

**Źródła (ścieżki względem katalogu głównego repozytorium):**

| Co | Plik |
|---|---|
| Strona główna – pełny CSS systemu | `docs/koncepcja/design/v3/makieta-v3.html` (bloki `<style>` w liniach 234–1196, w tym `gen:wspolne-css` i `gen:slownik-css`) |
| Podstrony publiczne | `docs/koncepcja/design/v3/oc-beauty.html`, `tax-protect.html`, `utrata-dochodu.html`, `nnw-dzieci.html`, `grupowe-ergo.html`, `opieka-medyczna.html`, `slownik.html` |
| Strefa Klienta | `docs/koncepcja/design/v3/strefa/strefa.css` + `strefa/logowanie.html`, `panel.html`, `dam-prace.html`, `szkolenia.html` |
| Tokeny (kopia referencyjna, nie jest dołączana do stron) | `docs/koncepcja/design/v3/tokens-v3.css` |
| Ikony | `docs/koncepcja/design/v3/ikony-v3-sprite.svg`, `ikony/*.svg`, `ikony-v3-manifest.json` |
| Zdjęcia scen | `docs/koncepcja/design/v3/img/` |
| Wspólne komponenty (menu, szuflada, pasek akcji) | `narzedzia/makiety/gen_wspolne.py` – bloki `<!-- gen:wspolne-css -->` w stronach |
| Pojęcia ze słownika i dymek | `narzedzia/makiety/slownik/gen_terminy.py` – bloki `<!-- gen:slownik-css -->` |
| Decyzje i uzasadnienia | `docs/koncepcja/10-design-v3-old-money.md` |
| Katalog wizualny tego pliku | `docs/koncepcja/design/v3/design-preview.html` |

Bloków `gen:*` nie zmienia się ręcznie – tylko przez generator (`--check` sprawdza aktualność).

**Format.** Sekcje 1–9 według formatu DESIGN.md z Google Stitch w rozszerzonym układzie 9 sekcji. Oryginalnej specyfikacji (stitch.withgoogle.com) nie dało się pobrać z sesji – host jest poza dozwoloną siecią; układ sekcji pochodzi z opisu formatu w kolekcji awesome-design-md. Nagłówki sekcji są po angielsku (zgodność ze Stitch) z polskim dopiskiem, treść po polsku. Liczby w tabelach podają tokeny CSS; „px” w nawiasie to przeliczenie przy 16 px = 1rem.

---

## 1. Visual Theme & Atmosphere · Klimat wizualny

**Old money glass: cichy luksus, ponadczasowo, nigdy krzykliwie.** Granat nocy, kość słoniowa, pergamin i szampańskie złoto. Mrożone szkło leży na edytorskich zdjęciach (boazeria, granatowy jedwab, marmur z lnem, martwa natura z flakonem i piwoniami). Nagłówki w szeryfowym Cormorant Garamond z kursywą jako akcentem („Ochrona szyta *na miarę*…”), tekst w Poppins, etykiety wersalikami z szerokim rozstrzeleniem, cienkie złote ramy wewnątrz tafli, rzymskie numery rozdziałów, małe promienie 3–6 px.

| Cecha | Jak to wygląda w systemie |
|---|---|
| Nastrój | spokojny, „papeteria z grawerem”: cienka złota linia, ikony jak rytownictwo, dużo powietrza |
| Gęstość | przestronnie – sekcje `padding-block: clamp(72px,11vw,168px)`; jedna tafla szkła na sekcję, komórki w środku rozdzielone liniami włoskowymi zamiast osobnych kart |
| Opowieść | strona główna w rozdziałach I–VII (eyebrow z rzymską cyfrą, duża cyfra `.chapter-no` w tle nagłówka), „Jeden dzień w salonie” – sześć sytuacji odsłanianych jak wskazówki |
| Światło i tło | sceny fotograficzne: jasne (marmur z lnem, hero salonu, martwa natura) i ciemne (granatowy jedwab); na desktopie delikatne ziarno `--grain` (alfa ≤ .07) |
| Ruch | filmowy i powolny, tylko jako ulepszenie: kurtyna nagłówków, rysujące się złote linie, paralaksa zdjęcia; tafle stoją, rusza się zdjęcie pod nimi albo treść nad nimi |
| Schemat | tylko jasny (`color-scheme: only light`); ciemne sceny są rozdziałami, osobnego trybu ciemnego nie ma |
| Marka | logo bez zmian (serce i róż zostają tylko w logo); w interfejsie nie ma różu ani fioletu |
| Strefa Klienta | ta sama marka „dostrojona do aplikacji” (`strefa/strefa.css:3–15`): szkło tylko dla nawigacji i paneli bocznych, dane i formularze na kryjących powierzchniach `.surface`, statusy to tekst + znak, ruch ≤ 200 ms |

**Zdjęcia scen** (`docs/koncepcja/design/v3/img/`, każde w dwóch rozmiarach: 2048 px i `-1024` na telefon):

| Plik | Klasa sceny | Kolor podkładu | Rola |
|---|---|---|---|
| `hero-salon.webp` | `.scene--hero` (zdjęcie jako `<img fetchpriority="high">`) | `--color-parchment` | prolog; lewa strona zdjęcia spokojna pod panel |
| `tlo-jedwab.webp` | `.scene--silk` | `--color-midnight` | ciemne rozdziały, stopka |
| `tlo-marmur-len.webp` | `.scene--marble` | `--color-parchment` | jasne rozdziały (kalkulator, „Dla kogo”, FAQ), tło Strefy Klienta |
| `cta-martwa-natura.webp` | `.scene--still` | `--color-parchment` | epilog z formularzem kontaktu; prawa strona spokojna |

Fotografia: wnętrza i materiały (boazeria, aksamit, mosiądz, marmur, len, kryształ, piwonie), miękkie dzienne światło, bez twarzy, bez tekstu i bez produktów konkretnych marek.

---

## 2. Color Palette & Roles · Paleta i role kolorów

### Kolory marki

Kontrast według WCAG 2.x; wyniki z dokumentu 10 (rozdz. 3) i przeliczone z wartości hex (te same wzory).

| Nazwa | Token CSS | Wartość | Rola | Para kontrastowa – wynik |
|---|---|---|---|---|
| Midnight (nocny granat) | `--color-midnight` | `#141C33` | tła ciemnych scen, stopka, pasek akcji, podkład ciemnego szkła | ivory na midnight **15,27:1**, parchment **13,51:1**, gold light **9,53:1** |
| Navy (granat) | `--color-navy` | `#2A3B68` | nagłówki, przyciski, ikony na jasnym, obwódka fokusu, panel wyniku | na ivory **9,87:1**, na parchment **8,73:1**, na białym **10,92:1** |
| Navy deep | `--color-navy-deep` | `#1E2B4F` | najechanie na `.btn-navy` | ivory na navy deep **12,54:1** |
| Ink (atrament) | `--color-ink` | `#1B2233` | tekst akapitów | na ivory **14,35:1**, na parchment **12,70:1** |
| Taupe | `--color-taupe` | `#5F574D` | eyebrow i etykiety sekcji – tylko na tle kryjącym; podpisy drugorzędne także na szkle i jasnych polach w tafli (zob. „Reguły użycia koloru”) | na ivory **6,42:1**, na parchment **5,68:1**; na szkle zmierzone na wyrenderowanym tle 5,2–6,4:1 |
| Ivory (kość słoniowa) | `--color-ivory` | `#F7F3EC` | tło `body`, kryjące panele (menu, dymek, dialog), tekst na ciemnym | na navy **9,87:1**, na midnight **15,27:1** |
| Parchment (pergamin) | `--color-parchment` | `#EDE5D8` | tło scen bez zdjęcia, najechanie, bieżąca pozycja menu, akapity na ciemnym | na midnight **13,51:1**, na navy **8,73:1** |
| Gold (szampańskie złoto) | `--color-gold` | `#B8975A` | **tylko dekor**: linie, ramy, ozdobniki, podkreślenia na jasnym | na ivory **2,49:1** – nie dla tekstu; na midnight 6,12:1 |
| Gold light | `--color-gold-light` | `#D9C089` | tekst, ikony, etykiety, obwódka fokusu na ciemnym | na midnight **9,53:1**, na navy **6,16:1** |
| Błąd | `--bp-error` | `#7A2E2E` | komunikat błędu, obrys pola z `aria-invalid` | na ivory **8,41:1**, na białym **9,30:1** |

### Szkło i linie (rgba)

| Token CSS | Wartość | Rola |
|---|---|---|
| `--bp-glass-ivory` | `rgba(247,243,236,.7)` | tło `.glass` |
| `--bp-glass-ivory-strong` | `rgba(247,243,236,.9)` | tło `.glass--strong` (belka nagłówka, księga produktów, Strefa Klienta) |
| `--bp-glass-ivory-tint` | `rgba(247,243,236,.84)` | tło `.glass.glass--tint` (bez rozmycia) |
| `--bp-glass-midnight` | `rgba(20,28,51,.56)` | tło `.glass--dark` |
| `--bp-glass-midnight-tint` | `rgba(20,28,51,.74)` | tło `.glass--dark.glass--tint` |
| `--bp-line-gold` | `rgba(184,151,90,.5)` | wewnętrzna rama `.frame`, linie na jasnym |
| `--bp-line-gold-soft` | `rgba(184,151,90,.35)` | linie włoskowe między komórkami i wierszami |
| `--bp-line-gold-on-dark` | `rgba(217,192,137,.32)` | rama i linie na ciemnym |
| `--bp-line-gold-on-dark-soft` | `rgba(217,192,137,.2)` | linie włoskowe na ciemnym |
| `--bp-line-navy` | `rgba(42,59,104,.22)`; Strefa `rgba(42,59,104,.18)` (`strefa/strefa.css:48`) | obrys kafelków wyboru `.opt` |
| `--bp-line-field` | `rgba(42,59,104,.7)` | obrys pól formularzy |

Pochodne alfa używane jako literały (bez osobnych tokenów): krawędź jasnego szkła `rgba(255,255,255,.6)` i błysk `inset 0 1px 0 rgba(255,255,255,.75)`; krawędź ciemnego szkła `rgba(217,192,137,.26)`; szwy między scenami `rgba(217,192,137,.45)`; obrys `.btn-ghost` `rgba(42,59,104,.45)`; obrys `.btn-ghost-dark` `rgba(217,192,137,.6)`; tła kafelków i pól `rgba(255,255,255,.45 / .75 / .82 / .85)`; tło `::backdrop` dialogu `rgba(20,28,51,.72)`. Poza dwoma wyjątkami każda wartość `rgba` w CSS makiet jest wariantem alfa barwy marki (w tym `--bp-error`) albo bieli. Wyjątki: czerń `rgba(0,0,0,.6)` w `--shadow-glass-dark` oraz `rgba(250,248,243,.97)` – kolor `#FAF8F3` spoza palety marki – w `--bp-surface` Strefy (`strefa/strefa.css:45`).

### Gradienty

| Gradient | Gdzie |
|---|---|
| `linear-gradient(150deg, var(--color-navy) 0%, var(--color-midnight) 100%)` (także `160deg`) | granatowe karty kryjące (`.member-card`, `.promo`, `.end-card`; Strefa `.banner`, `.invite`, `.promo-tag`) |
| `linear-gradient(90deg,transparent,var(--color-gold),transparent)` | linia ozdobna `.rule` |
| `linear-gradient(90deg,rgba(247,243,236,.35),rgba(247,243,236,0) 55%)` | woalka hero `.hero::after` |
| `linear-gradient(90deg,var(--color-gold-light),rgba(217,192,137,.25))` | linia „Jak to działa” `.how-line` |

### Strefa Klienta – kolory dodatkowe (`strefa/strefa.css`)

| Token / literał | Wartość | Rola | Kontrast |
|---|---|---|---|
| `--bp-surface` | `rgba(250,248,243,.97)` | kryjąca powierzchnia danych i formularzy `.surface` | – |
| `--bp-error-bg` | `#F6E9E6` | tło błędu (`.alert--error`, `.badge--error`, hover `.btn-danger`) | `--bp-error` na nim **7,85:1** |
| `#F3F5F9` | literał | `.alert--success` | navy na nim **10,00:1** |
| `#FBF6EA` | literał | `.alert--warn`, `.hold` | ink na nim **14,72:1** |
| `#fff` | literał | tło pól i chipów w Strefie i słowniku | ink **15,87:1** |

### Kolor przy ustawieniach dostępności

| Kontekst | Zmiana |
|---|---|
| `prefers-contrast: more` | `--color-taupe: #3F3A33` (na ivory 10,18:1), `--bp-line-field: var(--color-navy)`; tafle kryjące z obrysem navy (jasne) albo gold light (ciemne); `.chapter-no` ukryte. Strefa dodatkowo `--bp-line-gold-soft: rgba(42,59,104,.45)` |
| `prefers-reduced-transparency: reduce` | tafle kryjące: `--color-ivory` / `--color-midnight`, bez rozmycia |
| brak `backdrop-filter` | `.glass` → `rgba(247,243,236,.95)`, `.glass--dark` → `rgba(20,28,51,.92)` (Strefa `.94`) |
| `forced-colors: active` | fokus `2px dashed CanvasText`, `.glass{border:1px solid CanvasText}`, ramy ukryte, zaznaczenie `Highlight` |

### Reguły użycia koloru

- Złoty tekst tylko na ciemnym tle (`--color-gold-light`). Na jasnym złoto (`--color-gold`, `--bp-line-gold*`) rysuje linie i ramy, ale nie niesie treści.
- Eyebrow i etykiety sekcji (`.eyebrow`, `.partners p`, `.brand small` – lista w `makieta-v3.html:344–346`): na tle kryjącym – taupe; na szkle z rozmyciem lub na zdjęciu – navy; na ciemnym – gold light. Tafla bez rozmycia `.glass--tint` (krycie .84) działa jak tło kryjące: eyebrow list zabiegów na OC jest na niej taupe (`oc-beauty.html:1008`, 6,4:1).
- Podpisy drugorzędne mogą być taupe także na szkle: na `.glass--strong` (`.ledger--light .tag`, `.pp-pre`, `.pp-unit`), na `.glass` (`.calc legend small`, `.suma-nota`, `.zab-opis`, `.pro-text > span`) i na jasnych polach w tafli `rgba(255,255,255,.45–.88)` (`.opt label small`, `.opt-kwota`, `.co-opis`, `.zab-input::placeholder`, `.zab-chip small`) – zawsze przy kontraście ≥ 4,5:1 zmierzonym na wyrenderowanym tle. Pomiar 16.11.2026 (1440 i 390 px): księga na jedwabiu 5,2–5,4:1, kalkulator i kafle zawodów na marmurze 6,0–6,2:1. W Strefie etykiety wersalikami `.label-caps` (np. `.sidenav-title`) są taupe na `.glass--strong` (krycie .88; 6,3:1). Taupe bezpośrednio na zdjęciu (bez tafli) nie występuje w żadnej makiecie (strony publiczne i Strefa).
- Kontrast tekstu na szkle i zdjęciach mierzy się na wyrenderowanej stronie (nie z wartości tokenów) – wszystkie teksty muszą przejść AA.
- Kolor nigdy nie jest jedynym nośnikiem informacji: statusy mają znak i tekst, pojęcia ze słownika – kropkowane podkreślenie, zaznaczenie kafelka – obrys i cień wewnętrzny.

---

## 3. Typography Rules · Zasady typografii

### Rodziny

| Token | Stos | Ładowane wagi | Użycie |
|---|---|---|---|
| `--font-serif` | `'Cormorant Garamond','Cormorant Fallback','Cormorant Fallback 2',Garamond,serif` | 600 prosty, 500 kursywa | nagłówki, legendy, liczby, kwoty, nazwy w kafelkach, pytania FAQ |
| `--font-sans` | `'Poppins','Poppins Fallback','Poppins Fallback 2',system-ui,sans-serif` | 400, 500 | tekst, pola formularzy, tabele |
| `--font-caps` | `'Poppins','Poppins Caps Fallback','Poppins Fallback 2',system-ui,sans-serif` | 500 | wersaliki: eyebrow, przyciski, nawigacja, etykiety pól |

- Makiety ładują Google Fonts z `display=swap`: `family=Cormorant+Garamond:ital,wght@0,600;1,500&family=Poppins:wght@400;500`. Produkcja: `next/font`, samohostowane, `display: swap`, podzbiór `latin-ext`, bez zewnętrznego Google Fonts.
- Fonty zastępcze mają dopasowane metryki (`size-adjust`, `ascent-override`, `descent-override`, `line-gap-override` – `makieta-v3.html:243–249`), więc podmiana fontu nie przesuwa układu. Przykład: Poppins Fallback = Arial z `size-adjust: 112%`, Cormorant Fallback = Times New Roman Bold z `size-adjust: 91.7%`.
- Wagi 300 i 700 nie istnieją w systemie. Kursywa szeryfowa – zawsze 500. Strefa ma trzy wyjątki z niezaładowanymi wagami (przeglądarka je syntetyzuje) – „Znane rozbieżności” #4.

### Hierarchia (strony publiczne)

| Element | Token / wartość | Rozmiar | Krój i waga | Interlinia | Rozstrzelenie | Kolor |
|---|---|---|---|---|---|---|
| H1 | `--text-h1` = `clamp(2.75rem,1.4rem + 4.6vw,5.25rem)` | 44–84 px | serif 600, akcent `em` kursywa 500 | .98 | −.012em | navy |
| H1 panelu hero podstron | `clamp(2.5rem,1.4rem + 3.6vw,4.4rem)` | 40–70,4 px | serif 600 | 1 | −.012em | navy |
| H2 | `--text-h2` = `clamp(2.25rem,1.35rem + 3.4vw,4.25rem)` | 36–68 px | serif 600, `em` kursywa 500 | 1.02 | −.005em | navy; na ciemnym ivory |
| H2 FAQ | `clamp(2.25rem,1.5rem + 2.2vw,3.25rem)` | 36–52 px | serif 600 | 1.02 | −.005em | navy |
| H3 | `--text-h3` = `1.65rem` | 26,4 px | serif 600 | 1.15 | −.005em | navy; na ciemnym ivory |
| H3 kafelka produktu | `clamp(1.9rem,1.45rem + 1.4vw,2.3rem)` | 30,4–36,8 px | serif 600 | 1.1 | – | navy |
| Legenda, wynik „Taryfa”, nazwa zawodu | `--text-serif-md` = `1.45rem` | 23,2 px | serif 600 | 1.1–1.2 | – | navy / ivory |
| Podpis tabeli, partnerzy | `--text-serif-sm` = `1.2rem` | 19,2 px | serif 600 | 1.25 | – | navy |
| Pytanie FAQ (`summary`) | `1.4rem` | 22,4 px | serif 600 | 1.25 | – | navy |
| Duża cyfra rozdziału `.chapter-no` | `clamp(7rem,4.2rem + 9vw,14.5rem)`; < 768 px `clamp(5.5rem,3rem + 14vw,8rem)` | 112–232 px | serif 500 kursywa | 1 | −.02em | `rgba(184,151,90,.2)`; na ciemnym `rgba(217,192,137,.13)`; `aria-hidden` |
| Cyfra kroku `.numeral` | `--text-display-numeral` = `3.4rem` | 54,4 px | serif 500 kursywa | 1 | – | gold light (tylko na ciemnym) |
| Kwota składki w wyniku | `--text-price` = `clamp(3rem,2.4rem + 2vw,4.2rem)`; z groszami `min(var(--text-price),17cqi)` | 48–67,2 px | serif 600, cyfry tabelaryczne | .95 | – | ivory na navy |
| Kwota w kafelku produktu | `2.25rem` | 36 px | serif 600 | 1.05 | – | navy |
| Lead | `--text-lead` = `clamp(1.0625rem,1rem + .25vw,1.125rem)`, maks. `34rem` | 17–18 px | sans 400 | 1.75 | – | ink; na ciemnym parchment |
| Tekst bazowy, pola | `--text-base` = `1rem` | 16 px | sans 400 | 1.7 | – | ink |
| Tekst w kartach, FAQ, dymek | `--text-body` = `.9375rem` | 15 px | sans 400 | 1.6–1.7 | – | ink; na ciemnym parchment |
| Tekst pomocniczy, tabele, kafelki wyboru | `--text-sm` = `.875rem` | 14 px | sans 400 | 1.35–1.6 | – | ink / taupe |
| Linki stopki | `.9rem` | 14,4 px | sans 400 | 1.35 | – | parchment |
| Błąd pola `.field-error`, podpowiedź | `.8125rem` | 13 px | sans 400 | 1.5 | – | `--bp-error` |
| Eyebrow `.eyebrow` | `--text-xs` = `.75rem` | 12 px | caps 500, wersaliki, złota linia 36×1 px przed tekstem | 1.7 | `--tracking-label` .2em | taupe / navy / gold light (zob. reguły koloru) |
| Numer rozdziału w eyebrow `.eyebrow .no` | `1.25rem` | 20 px | serif 500 kursywa | 1 | .02em | navy; na ciemnym gold light |
| Przycisk `.btn` | `--text-xs` | 12 px | caps 500, wersaliki | 1.2 | `--tracking-label` .2em | zależnie od wariantu |
| Nawigacja `.main-nav a` | `--text-xs` | 12 px | caps 500, wersaliki | 1 | `--tracking-nav` .16em | ink; najechanie navy |
| Etykieta pola `.field label` | `--text-xs` | 12 px | caps 500, wersaliki | 1.4 | .14em | navy |
| Tytuł kolumny stopki | `--text-xs` | 12 px | caps 500, wersaliki | 1.4 | .22em | gold light |
| Minimum | `--text-xs` | **12 px** | – | – | – | nic mniejszego w całym systemie |

### Skala Strefy Klienta (`strefa/strefa.css:35–37`, `62–67`)

| Element | Wartość | Rozmiar |
|---|---|---|
| H1 | `clamp(2.1rem,1.6rem + 1.8vw,3rem)`, interlinia 1.05 | 33,6–48 px |
| H1 karty logowania | `clamp(2rem,1.6rem + 1.4vw,2.6rem)` | 32–41,6 px |
| H2 | `clamp(1.6rem,1.35rem + .9vw,2rem)`, interlinia 1.1 | 25,6–32 px |
| H3 | `1.5rem`, interlinia 1.2 | 24 px |
| H4 | `--text-serif-sm`, interlinia 1.25 | 19,2 px |
| Lead | `1.0625rem`, interlinia 1.7, maks. `44rem` | 17 px |
| Nawigacja | `--tracking-nav: .14em` | – |
| Kod jednorazowy `.code-input` | Poppins 500 `1.6rem`, `letter-spacing: .45em` | 25,6 px |

### Liczby i kwoty

- Cyfry nautyczne zawsze wyłączone: `font-variant-numeric: lining-nums tabular-nums` (kwoty, tabele, godziny, karty).
- Wynik kalkulatora zawsze z groszami: „1&nbsp;279,50&nbsp;zł”, „987,50&nbsp;zł rocznie”. Sumy jak w treści stron: „200&nbsp;tys.&nbsp;zł”. Tabela taryfy bez groszy: „1&nbsp;250&nbsp;zł”.
- Kafelek produktu: „od” i jednostka Poppins 400 `--text-sm` taupe, kwota Cormorant 600 2.25rem navy, nad linią ceny złota linia `--bp-line-gold-soft`.

### Polska typografia (obowiązkowo w każdej treści)

- Cudzysłowy „ ”, nigdy "proste".
- Spacja twarda (`&nbsp;`) przed „zł” i w grupach cyfr („1&nbsp;532&nbsp;zł”, „100&nbsp;000&nbsp;zł”), w skrótach („sp.&nbsp;z&nbsp;o.o.”, „ul.&nbsp;Bolkowskiej”).
- Spacja twarda po jednoliterowych spójnikach i przyimkach: „i&nbsp;”, „w&nbsp;”, „z&nbsp;”, „o&nbsp;”, „a&nbsp;”, „u&nbsp;”.
- Półpauza w zakresach, a po niej łącznik słowa U+2060 (`&#8288;`), żeby zakres się nie łamał: „6–&#8288;8&nbsp;osób”, „2–&#8288;100&nbsp;osób”. Ten sam łącznik po dywizie w „e-&#8288;mail”.
- Półpauza ze spacjami jako myślnik („Składka ze stałej taryfy – według rodzaju działalności”).
- Nagłówki i akapity: `text-wrap: balance` (h1–h3) i `text-wrap: pretty` (p).

---

## 4. Component Stylings · Komponenty

Klasy i wartości z `makieta-v3.html`, chyba że podano inny plik. Każdy komponent działa bez JS (treść widoczna, linki zamiast przełączników), a ruch zamyka `prefers-reduced-motion: no-preference`.

### 4.1 Przyciski

Baza `.btn`: `inline-flex`, `gap: 12px`, **`min-height: 50px`**, `padding: 14px 28px`, `border-radius: var(--radius-btn)`, `border: 1px solid transparent`, `font: 500 var(--text-xs)/1.2 var(--font-caps)`, `letter-spacing: var(--tracking-label)`, wersaliki, `transition: background-color .25s, color .25s, border-color .25s`.

| Wariant | Tło / tekst / obrys | Najechanie | Fokus | Gdzie |
|---|---|---|---|---|
| `.btn-navy` | navy / ivory / navy | `--color-navy-deep`; przy `(hover:hover) and (pointer:fine)` złota linia `--color-gold-light` 1 px rośnie od środka 10 px nad dolną krawędzią do `calc(100% - 56px)` w `.5s var(--ease-lux)` | obwódka 2 px navy, odstęp 3 px (+ ta sama złota linia) | główna akcja na jasnym |
| `.btn-ghost` | `rgba(247,243,236,.4)` / navy / `rgba(42,59,104,.45)` | tło `rgba(247,243,236,.8)`, obrys navy | jak wyżej | druga akcja na szkle lub zdjęciu |
| `.btn-ivory` | ivory / navy / ivory | parchment | obwódka gold light | główna akcja na ciemnym (panel wyniku, pasek akcji) |
| `.btn-ghost-dark` | przezroczyste / ivory / `rgba(217,192,137,.6)` | obrys i tekst gold light | obwódka gold light | druga akcja na ciemnym |
| nieaktywny (`.result .btn[aria-disabled="true"]`) | przezroczyste / parchment / `rgba(217,192,137,.5)`, `cursor: not-allowed` | – | jak aktywny (pozostaje w kolejności Tab) | wysyłka kalkulatora przy brakach |

- Nieaktywny przycisk ma `aria-disabled="true"`, nie `disabled` – po kliknięciu fokus trafia na brakujące pole. Etykieta zawsze mówi, czego brakuje (teksty `CTA_BRAK`, `makieta-v3.html:2142`: „Najpierw zaznacz rodzaj działalności”, „Najpierw podaj liczbę osób”, „Najpierw wybierz sumę gwarancyjną”, „Najpierw zaznacz zabiegi wymagające ankiety”); „Poproś o polisę” wraca dopiero przy komplecie danych.
- Poniżej 480 px przyciski w grupach akcji (`.hero-actions`, `.lead-form`, `.cta-row`, `.tariff-actions` i podobne) mają pełną szerokość; w panelu wyniku zawsze.
- Przycisk z ikoną: `.lux-icon--sm` (22 px) w `currentColor`.
- **Strefa Klienta** (`strefa/strefa.css:116–140`): `.btn` `min-height: 48px`, `padding: 12px 24px`, `gap: 10px`, przejście `var(--bp-dur)` (.2s); `.btn-sm` 44 px (`10px 16px`, `.14em`); `.btn-ghost` na `rgba(255,255,255,.55)` → `#fff`; `.btn-quiet` przezroczysty ze złotym podkreśleniem; `.btn-danger` tekst `--bp-error`, obrys `rgba(122,46,46,.5)`, najechanie `--bp-error-bg`; nieaktywny `.btn[disabled], .btn[aria-disabled="true"]` – taupe, obrys `rgba(95,87,77,.45)`; `.btn-block` 100%.

### 4.2 Linki

| Klasa | Wygląd | Stany |
|---|---|---|
| `.link-lux` | wersaliki `--text-xs`, `--tracking-label`, navy, `min-height: 44px`, po tekście linia 28×1 px | najechanie: linia 44 px (`width var(--bp-dur-2)`); na ciemnym gold light |
| `.link-quiet` | `--text-sm` navy, podkreślenie `--color-gold` 1 px, `text-underline-offset: 5px`, `min-height: 44px` | na ciemnym parchment, podkreślenie `rgba(217,192,137,.6)` |
| link w tekście | navy, `text-decoration-color: var(--color-gold)`, offset 3–4 px | na ciemnym gold light, najechanie ivory |
| `.main-nav a` | caps `--text-xs`, `--tracking-nav`, ink, `min-height: 44px` | najechanie navy + złote podkreślenie, offset 6 px |
| `.footer-nav a` | parchment `.9rem`, `min-height: 34px` (44 px przy `pointer: coarse`) | najechanie ivory + złote podkreślenie; `[aria-current="page"]` ivory + podkreślenie |
| `.skip` („Przejdź do treści”) | navy, tekst ivory, `top: -60px` → `12px` przy fokusie, `z-index: var(--bp-z-skip)` | – |

### 4.3 Fokus

- Globalnie `:focus-visible { outline: 2px solid var(--color-navy); outline-offset: 3px }`; w `.dark`, `.result`, `.member-card`, pasku akcji – `--color-gold-light`.
- Pola: obwódka 2 px navy, odstęp 2 px i obramowanie navy. Kafelek wyboru: obwódka 2 px na `label` (`input:focus-visible + label`), odstęp 2 px.
- Komórki w tafli z `overflow: clip` mają obwódkę do środka: `-4px` (`.pro`, `.clue summary`), `-3px` (`.calc-tab`), `-2px` (`.table-scroll`, `.zab-chip-x`); kafelek produktu – `:has(.product-link:focus-visible)` obwódka 2 px navy z odstępem `-6px` i tłem `rgba(255,255,255,.55)`.
- Fokus nigdy nie jest zasłonięty: nagłówek nie chowa się przy fokusie w środku (`.site-header:focus-within{transform:none}`), `scroll-padding-top` i `scroll-padding-bottom` rezerwują miejsce pod belką i paskami (WCAG 2.4.11).

### 4.4 Tafle szkła

| Klasa | Definicja | Gdzie |
|---|---|---|
| `.glass` | `border-radius: var(--radius-card)`; tło `--bp-glass-ivory`; `backdrop-filter: blur(var(--blur-glass)) saturate(140%)`; `border: 1px solid rgba(255,255,255,.6)`; `box-shadow: var(--shadow-glass), inset 0 1px 0 rgba(255,255,255,.75)` | panel hero, kalkulator, kafle zawodów, FAQ, panel kontaktu |
| `.glass--strong` | tło `--bp-glass-ivory-strong` | belka nagłówka, księga produktów, rozdział Strefy Klienta |
| `.glass--dark` | tło `--bp-glass-midnight`; obrys `rgba(217,192,137,.26)`; `blur(var(--blur-glass-dark)) saturate(120%)`; `var(--shadow-glass-dark), inset 0 1px 0 rgba(255,255,255,.08)`; tekst parchment | „Jeden dzień”, „Jak to działa”, stopka |
| `.glass--tint` | **bez** `backdrop-filter` (nie liczy się do limitu tafli); jasna `--bp-glass-ivory-tint`, ciemna `--bp-glass-midnight-tint` | pasek partnerów, przełącznik kalkulatorów, tabele taryf, baner szkody |
| `.frame::before` | wewnętrzna rama: `inset: var(--bp-frame-inset)` (9 px), `1px solid var(--bp-line-gold)` (na ciemnym `--bp-line-gold-on-dark`), `border-radius: calc(var(--radius-card) - 3px)` | strony publiczne: panel hero, kalkulator (OC i Tax), panel kontaktu, `.form-panel.glass--tint` (opieka medyczna); Strefa: `.auth-card.glass--strong`, `.page-head.glass--strong`, `.card.surface` (tam `inset: 7px`) |
| `.surface` (Strefa) | kryjąca: `--bp-surface`, obrys `--bp-line-gold-soft`, `--shadow-surface` = `0 18px 40px -28px rgba(20,28,51,.45)`, `--radius-card` | dane i formularze w Strefie Klienta |

### 4.5 Karty kryjące (bez rozmycia)

Tło ivory albo gradient granatowy (`150deg`/`160deg`, navy → midnight), wewnętrzna rama przez `::before` z `inset: var(--bp-frame-inset)`, cień `0 30px 60px -40px rgba(20,28,51,α)` w trzech wariantach alfy: `.4` – `.clause` (OC), `.scope-card` (Tax, NNW, opieka), `.apply` (grupowe), `.op-card` (opieka); `.45` – `.ledger` (utrata dochodu); `.5` – `.route--main` (utrata dochodu). Przykłady: `.clause` (OC), `.scope-card` (Tax), `.apply` (grupowe), `.op-card` (opieka), `.route--main` i `.ledger` (utrata dochodu), `.result`, `.promo`, `.end-card`, `.member-card` (promień 10 px, `rotate: -1.5deg`, przy najechaniu 0° i −4 px w górę w `.6s`), w Strefie `.banner`, `.invite`, `.promo-tag`. Karty z samym obrysem: `.rel-card`, `.panel`, `.vcard`, `.cmp-attr`, `.sl-litera`.

### 4.6 Kafelek produktu (księga produktów)

- Kontener `.ledger.ledger--light.glass.glass--strong` – jedna tafla, siatka 3 → 2 (< 1024 px) → 1 (< 640 px) kolumny.
- `.product`: `display: grid`, `gap: 16px`, `padding: 36px 34px 30px`, `grid-template-rows: auto auto 1fr auto auto` (linia ceny i akcja stoją na jednej wysokości w rzędzie); linie włoskowe cieniem `1px 0 0, 0 1px 0` w `--bp-line-gold-soft`.
- Kolejność: `.product-top` (ikona 48 px + `.tag` ubezpieczyciela: `--text-xs`, `.2em`, wersaliki, taupe z rombem 4×4 px w gold) → H3 z `a.product-link` i szewronem `.product-go` → opis `--text-body` ink → `.product-price` → `.product-actions` (jedna akcja, `.link-lux`, cel 44 px).
- Cały kafelek klikalny: `.product-link::after { position:absolute; inset:0; z-index:1 }`; akcja leży nad nim (`z-index: 2`). Bez zagnieżdżania elementów interaktywnych.
- Stany: najechanie tylko przy `(hover:hover) and (pointer:fine)` – tło `rgba(255,255,255,.55)`, złote podkreślenie nazwy (offset 6 px), szewron przesuwa się o .15em; `:target` – `inset 0 0 0 1px var(--color-gold)`; fokus – zob. 4.3.
- Żaden kafelek nie jest wyróżniony (bez plakietek, bez innego tła, bez kolejności „najlepszy”).

### 4.7 Kafelki wyboru (radio / checkbox) – `.opt`

- `fieldset` bez ramki, `legend` serif `--text-serif-md` navy z `small` Poppins `--text-xs` taupe (np. „możesz zaznaczyć kilka”, „opcjonalnie”).
- Siatki `.opt-grid--2` / `.opt-grid--3` (gap 10 px); `--2` → 1 kolumna < 480 px; liczby osób i sumy → 1 kolumna < 360 px.
- `.opt input` niewidoczny na całym kafelku (`opacity: 0`, `z-index: 1`); `label`: `min-height: 56px`, `padding: 12px 16px`, `--radius-btn`, tło `rgba(255,255,255,.45)`, obrys `--bp-line-navy`, `--text-sm`, przejście `var(--bp-dur-1)`.
- **Zaznaczony:** obrys navy, tło `rgba(255,255,255,.85)`, `box-shadow: inset 0 0 0 1px var(--color-navy)`. **Fokus:** obwódka 2 px navy, odstęp 2 px. **Kolory wymuszone:** `border: 3px solid Highlight`.
- Odmiany: `.opt--center` (serif 1.15rem navy, wyśrodkowany; < 480 px 1rem); `.opt--check` (kwadratowy znacznik 18×18 px, promień 2 px; zaznaczony – navy z `inset 0 0 0 3px var(--color-ivory)` – odróżnia wielokrotny wybór); `.opt--suma` (druga linia `.opt-kwota` `--text-xs` taupe → navy po zaznaczeniu).
- `.check-row`: natywny checkbox 20×20 px, `accent-color: var(--color-navy)`, `min-height: 44px` (40 px w listach: `.ankieta-lista .check-row` – `makieta-v3.html:651`, `.zab-list .check-row` w `dialog.zab-sheet` – `strefa/dam-prace.html:245`); `.zakres-opcja` – opcja z opisem w obrysie `--bp-line-navy`, po zaznaczeniu obrys navy i tło `.8`.
- **Bez wartości domyślnych:** żadna opcja nie jest zaznaczona przy wejściu na stronę.

### 4.8 Wynik kalkulatora i pasek ceny

- `.result`: kryjący navy (nie szkło), `padding: clamp(26px,3vw,40px)`, `--radius-card`, rama `::before` `rgba(217,192,137,.4)`; `.label` wersaliki gold light; `.tariff` serif `--text-serif-md` ivory; `.rule` złota; od 1024 px `position: sticky; top: 112px`.
- Stany `data-state`: `price` (kwota `--text-price`, bez łamania), `individual` (2rem, „Składka do indywidualnej wyceny”), `empty` (1.5rem, komunikat braku, przycisk z `aria-disabled` i etykietą brakującego pola – zob. 4.1).
- Opis wyliczenia jak w CRM, np. „Gabinety kosmetologiczne, suma 200&nbsp;tys.&nbsp;zł: 790&nbsp;zł, +25% (6–&#8288;8&nbsp;osób)”.
- Ogłaszanie: jeden `role="status"` (sr-only) na kalkulator, z opóźnieniem 450 ms.
- `.calc-peek` (< 1024 px): przyklejony do dołu, `z-index: var(--bp-z-sticky)`, `min-height: 56px`, navy, obrys `rgba(217,192,137,.55)`, cień `0 14px 30px -14px rgba(20,28,51,.7)`; zawsze jedna linia; w stanie `empty` `visibility: hidden`; `aria-hidden` (czytnik dostaje wynik z panelu).

### 4.9 Wyszukiwarka zabiegów, chipy i plakietki

- Combobox ARIA 1.2 (`role="combobox"`, lista `role="listbox"`, bez automatycznego wyboru). `.zab-input`: `min-height: 52px`, lupa 20 px (kreska 1.6) po lewej, tło `rgba(255,255,255,.82)`, obrys `--bp-line-field`; po rozwinięciu dolne narożniki proste.
- `.zab-pop`: kryjące ivory, obrys navy, cień `0 22px 44px -22px rgba(20,28,51,.5)`, `z-index: 5` – **nie jest taflą**. `.zab-list` `max-height: min(440px,58vh)`; `.zab-opt` `min-height: 48px`, najechanie parchment, `.is-active` navy z tekstem ivory.
- `.zab-badge`: pigułka 999 px, obrys navy, `--text-xs` 500 („Lista nr 2”, „Listy nr 1 i 2”, „Ankieta, poz. h)”); w aktywnej pozycji gold light. Plakietka podaje tylko numer listy albo pozycję ankiety – nie ocenia zakresu ochrony.
- `.zab-chip` (wybrane zabiegi): pigułka 999 px, obrys navy, tło `rgba(255,255,255,.88)`, `--text-sm` navy, `small` taupe; przycisk usuwania `.zab-chip-x` 34×34 px, okrągły, najechanie parchment, `aria-label="Usuń z wybranych: …"`.
- Strefa (`dam-prace.html`): `.chip` jako kafelek filtra `min-height: 44px` z ikoną 28 px, zaznaczony navy z ikoną gold light; `.zab-chip` `min-height: 36px` (44 px przy `pointer: coarse`).

### 4.10 Pola formularzy

| Element | Styl |
|---|---|
| `.field` | `display: grid; gap: 6px` |
| `label` | caps 500 `--text-xs`, `.14em`, navy; dopisek `span` („(opcjonalnie)”) Poppins 400 bez wersalików |
| `input`, `select` | `min-height: 48px`, `padding: 10px 14px`, obrys `--bp-line-field`, `--radius-btn`, tło `rgba(255,255,255,.75)` (Strefa `#fff`), Poppins 400 `--text-base` |
| `select` | `appearance: none`, strzałka SVG (kreska `#2A3B68`, 1.4) 16 px od prawej, `padding-right: 42px` |
| `:focus-visible` | obwódka 2 px navy, odstęp 2 px, obramowanie navy |
| `[aria-invalid="true"]` | obramowanie `--bp-error` + `inset 0 0 0 1px var(--bp-error)` |
| `.field-error` | `.8125rem`/1.5 `--bp-error`, powiązany przez `aria-describedby`; w Strefie z kółkiem „!” 18 px |
| `textarea` (Strefa) | `min-height: 120px`, `resize: vertical` |
| `[readonly]` / `:disabled` (Strefa) | parchment, obrys przerywany; nieaktywny także taupe i `cursor: not-allowed` |
| `.fields-2` | 2 kolumny od 640 px; `.fields-3` 3 kolumny od 720 px (Strefa) |
| zgody `.check-row.consent` | checkbox wyrównany do góry, tekst `--text-sm` ink |
| `.radio-card` (Strefa) | `min-height: 52px`, `#fff`, kółko 18 px; zaznaczony navy z `inset 4px #fff` |
| `.switch` (Strefa) | 44×24 px, promień 12 px; `[aria-checked="true"]` tło navy |
| `.ts-slot` (Turnstile) | `min-height: 65px`, `max-width: 300px`, obrys przerywany |

Komunikaty błędów są konkretne, z przykładem: „Sprawdź adres e-mail, np. anna@salon.pl.”, „Zaznacz rodzaj działalności.”, „Podaj liczbę osób wykonujących zabiegi.”.

### 4.11 Komunikaty i stany

| Klasa | Styl |
|---|---|
| `.lead-status:not(:empty)` (sukces formularza) | obrys `--bp-line-gold`, tło `rgba(255,255,255,.6)`, serif 600 1.3rem navy; `role="status"`, `tabindex="-1"` |
| `.form-status` / `.form-errors` (opieka) | lewa linia 2 px navy / `--bp-error`; lista błędów z linkami do pól |
| wzorzec notatki (`.lead-calc`, `.zempty`, `.haslo-przyklad`) | lewa złota linia 2 px + jasne tło |
| `.alert` (Strefa) | siatka z ikoną 22 px, lewa krawędź 3 px, tytuł serif 600 1.25rem; `--info` navy na `--bp-surface`, `--success` navy na `#F3F5F9`, `--warn` gold na `#FBF6EA`, `--error` `--bp-error` na `--bp-error-bg` |
| `.empty` / `.sl-pusto` | pusty stan: obrys przerywany `--bp-line-gold`, wyśrodkowany, tytuł serif |
| `.badge` (Strefa) | `min-height: 28px`, promień 2 px, obrys `currentColor`, tło `rgba(255,255,255,.7)`, `--text-xs` 500, **znak + tekst** (`--ok`, `--warn`, `--off` przerywany, `--info` kropkowany, `--error` z „!”) |
| `.statement` (Strefa – „zasada tablicy”) | lewa linia 3 px gold, tło `rgba(255,255,255,.82)`: „nikt nie poleca ani nie dobiera” |

### 4.12 Tabele taryf i danych

- `.tariff-table` w tafli `glass--tint`; `caption` serif `--text-serif-sm` navy; komórki `padding: 10px 8px` (podstrony `12px 8px`), linia `--bp-line-gold-soft`, kwoty do prawej i bez łamania; `thead th` `--text-xs` 500 navy; `th[scope="row"]` z `small` (opis taryfy) ink.
- Zawsze w `.table-scroll` (`overflow-x: auto`, `role="region"`, `tabindex="0"`, `aria-label`) – zabezpieczenie WCAG 1.4.10. Poniżej 480 px nagłówki kolumn się łamią, `padding-inline: 4px` (3 px < 360 px).
- Wiersz wyceny indywidualnej `.row-ind`: linia `--bp-line-gold`, tekst wyśrodkowany navy. Wybrany wiersz w porównaniu (`.rate-table .is-sel`) – parchment `.85`; to stan wyboru użytkownika, nie wyróżnienie.
- Strefa `table.data`: `thead` wersaliki `.12em` taupe z linią `--bp-line-gold`; `.stack` < 720 px – wiersze jako karty z `data-label`.

### 4.13 FAQ i `details`

- `.faq` – jedna tafla `.glass`; `details` z `padding: 0 28px`, linie `--bp-line-gold-soft`; `summary` `min-height: 64px`, serif 600 1.4rem navy (< 480 px 1.25rem – tylko podstrony, np. `oc-beauty.html:454`; strona główna zostaje przy 1.4rem – rozbieżność #12); krzyżyk z dwóch linii 16×16 px obraca się o 45° (`var(--bp-dur-2) var(--ease-lux)`), w kolorach wymuszonych znak „+”.
- Płynne rozwijanie przez `::details-content` + `interpolate-size: allow-keywords`, `block-size .45s var(--ease-lux)` – tylko przy `prefers-reduced-motion: no-preference`.
- Siatka nagłówek/pytania `4fr / 7fr` od 1024 px, nagłówek przyklejony przy oknie ≥ 1024×700 px.

### 4.14 Nawigacja

- **Nagłówek** `.site-header`: `fixed`, `top: 14px` (8 px < 768 px), `z-index: var(--bp-z-header)`. `.header-bar` – `glass--strong`, `min-height: 68px`, `padding: 10px 14px 10px 22px`, obrys `rgba(184,151,90,.55)`. Logo 24 px wysokości (proporcja 3000×450) z podpisem „created by Aura Expert”.
- Tryb kompaktowy `[data-compact="1"]` po przewinięciu > 40 px: tło `rgba(247,243,236,.95)`, podpis logo znika, przycisk w nagłówku przechodzi w pełne navy. `[data-hidden="1"]`: `translateY(calc(-100% - 20px))`, `var(--bp-dur-3) var(--ease-lux)` – chowa się przy przewijaniu w dół od 320 px, ale nigdy przy ograniczonym ruchu, oknie ≤ 500 px wysokości, otwartym menu ani fokusie w środku.
- **Menu „Ubezpieczenia” (≥ 1200 px)** – wzorzec disclosure (przycisk z `aria-expanded`, bez `role="menu"`): `.mega` kryjące ivory, obrys `rgba(184,151,90,.55)`, `--radius-card`, siatka 3×2 (ikona 32 px + nazwa serif 1.3rem + opis `--text-sm` taupe + cena); bieżąca pozycja parchment + `inset 2px 0 0 var(--color-gold)` + „Jesteś tutaj”; najechanie otwiera po 180 ms, zamyka po 320 ms (tylko jako dodatek do kliknięcia).
- **Szuflada (< 1200 px)** – `details.menu`: `summary` 48×48 px z obrysem `rgba(42,59,104,.3)`; `.menu-panel` kryjące ivory, `max-height: calc(100dvh - 104px)`; na górze „Oblicz składkę OC” (`btn-navy`, pełna szerokość), potem 6 produktów (ikona 22 px, nazwa, cena; wiersz ≥ 52 px); bieżący produkt parchment + złoty pasek 2 px + `aria-current`.
- **Okruszki** `.crumbs`: separator „›” taupe, linki navy ze złotym podkreśleniem, `min-height: 32px` (Strefa: „/” gold, 24 px).
- **Strefa Klienta:** `.topbar` – ciemne szkło `rgba(20,28,51,.78)`, przyklejony, `--bp-topbar-h: 68px`; `.sidenav` – `glass--strong`, pozycje `min-height: 46px`, bieżąca – tło `.85` + złoty pasek 2 px; < 1024 px szuflada `min(320px,86vw)` na ivory (`z-index: 80`, zasłona `rgba(20,28,51,.5)`); `.tabs` – zakładki ARIA 46 px, zaznaczona linia 2 px navy; `.pager` 44×44 px.

### 4.15 Pasek akcji na telefonie (`gen_wspolne.py`)

- Tylko < 768 px i przy wysokości okna > 500 px, po przewinięciu poza 90% wysokości okna. Landmark `aside`.
- `position: fixed`, `left/right: max(12px, env(safe-area-inset-*))`, `bottom: calc(10px + env(safe-area-inset-bottom))`, `z-index: var(--bp-z-sticky)`; jedna kryjąca płyta midnight (bez rozmycia), obrys `rgba(217,192,137,.5)`, `--radius-card`, cień `0 14px 30px -12px rgba(20,28,51,.75)`, `padding` i `gap` 6 px.
- Dwa przyciski `min-height: 48px`: `.pa-glowny` (ivory, tekst navy, `flex: 1 1 8rem`) i `.pa-tel` (obrys gold `.6`, tekst ivory, ikona słuchawki 18 px gold light, numer `--text-xs` gold light z cyframi tabelarycznymi).
- Wjazd `translateY(calc(100% + 24px + safe-area))` → `none` w `var(--bp-dur-3) var(--ease-lux)`; ukryty ma `visibility: hidden` + `inert`.
- Chowa się, gdy widać pasek ceny, formularz kontaktu, kartę końcową, przyciski hero lub taryfy albo stopkę; przy fokusie w polu, otwartej klawiaturze i otwartej szufladzie. Miejsce rezerwuje `html.has-pasek{scroll-padding-bottom: calc(92px + env(safe-area-inset-bottom))}`, nie `padding` na `body`.

### 4.16 Pojęcie ze słownika i dymek (`gen_terminy.py`)

- `a.bp-termin`: kolor tekstu bez zmian, kropkowane podkreślenie 1,5 px `currentColor`, offset .24em; najechanie – ciągłe, gold; `[aria-expanded="true"]` tło `rgba(217,192,137,.3)`; na ciemnym podkreślenie gold light, tło `.18`; fokus 2 px `currentColor`. Bez JS – zwykły link do `slownik.html#haslo-…`.
- Oznaczać tylko w `<p>`/`<li>` w `<main>` – nigdy w hero, nagłówkach, przyciskach, formularzach, tabelach ani stopce prawnej.
- `.bp-dymek`: niemodalny `role="dialog"`, `z-index: 85` (nad paskiem akcji), `width: min(380px, calc(100vw - 32px))`, `padding: 16px 20px 12px`, kryjące ivory, obrys `rgba(184,151,90,.75)`, promień 6 px, cień `0 0 0 1px rgba(42,59,104,.06), 0 2px 4px rgba(20,28,51,.1), 0 22px 44px -18px rgba(20,28,51,.6)`, tekst `--text-body`/1.6; tytuł serif 600 1.4rem navy z linią `rgba(184,151,90,.45)`; „Objaśnienie ogólne – wiążą OWU produktu i umowa.” `--text-sm` taupe; „Więcej w słowniku” `min-height: 44px`; zamknięcie 44×44 px. Bez `backdrop-filter`.
- Otwiera i zamyka kliknięcie, Enter albo Spacja; Esc i „Zamknij” oddają fokus pojęciu; najechanie niczego nie otwiera ani nie zamyka (WCAG 1.4.13).
- Okno < 600 px szerokości **lub** wysokości: panel u dołu (`position: fixed`, `bottom: calc(12px + safe-area)`, `max-width: 560px`, `max-height: min(70vh,560px)`, przewijanie wewnątrz).

### 4.17 Dialogi i szuflady

| Klasa | Styl |
|---|---|
| `dialog.klauzula` | natywny `showModal`; `width: min(calc(100% - 32px),780px)`, `max-height: min(calc(100dvh - 32px),920px)`, kryjące ivory, obrys `--bp-line-gold`, `--radius-card`, cień `0 40px 80px -30px rgba(20,28,51,.65)`; `::backdrop` `rgba(20,28,51,.72)`; treść przewija się w `region` z `tabindex="0"`; wejście `.4s var(--ease-lux)`, 14 px (Strefa `.2s`, 10 px) |
| `dialog.zab-sheet` (Strefa) | `width: min(680px, calc(100% - 32px))`, `height: min(780px, calc(100dvh - 48px))`; < 640 px pełny ekran; `::backdrop` `rgba(20,28,51,.55)` |
| `.drawer` (Strefa) | panel `min(560px,100%)` z prawej, cień `-30px 0 60px -30px rgba(20,28,51,.6)`, zasłona `rgba(20,28,51,.5)`, `z-index: 80`, wejście `.2s` (24 px) |

### 4.18 Stopka i informacje o agencie

- `.site-footer` na scenie jedwabiu: `padding-block: clamp(56px,8vw,96px) 40px` (`makieta-v3.html:815`); `.footer-panel` w `glass--dark`, `padding: clamp(28px,4vw,48px)`.
- `.logo-chip` – logo 22 px na jasnym polu `rgba(247,243,236,.96)` z ramą `rgba(184,151,90,.55)` (do czasu logo na ciemne tło).
- `.footer-nav` – 2 kolumny, 4 od 1024 px, 1 < 480 px; `.footer-title` wersaliki `.22em` gold light.
- `.legal` – `--text-xs`/1.7 parchment, linia `rgba(217,192,137,.3)`, linki gold light. **Obowiązkowa treść:** pełna formuła spółki z numerem KRS i sądem rejestrowym („Sąd Rejonowy dla m.st. Warszawy, XII Wydział Gospodarczy Krajowego Rejestru Sądowego”), NIP, REGON, kapitał; status **agenta ubezpieczeniowego** (nie brokera); numer wpisu w Rejestrze Pośredników Ubezpieczeniowych z odnośnikiem do `rpu.knf.gov.pl`; `details.legal-idd` „Informacje o agencie ubezpieczeniowym (IDD)” (zakłady, wynagrodzenie, powiązania, reklamacje, Rzecznik Finansowy); zdanie o braku oferty w rozumieniu art. 66 KC. Treść wzorcowa: `makieta-v3.html:1919–1937`; skrót w stopce, pełna formuła na `/informacje-prawne`.
- Stopkę Strefy (`.app-footer`, tło `rgba(247,243,236,.86)`) zamyka ten sam blok `.legal-idd`.

### 4.19 Ikony

- Sprite `ikony-v3-sprite.svg`: 23 symbole `<symbol id="lux-…" viewBox="0 0 96 96">` – produkty (`oc-beauty`, `tax-protect`, `utrata-dochodu`, `nnw-dzieci`, `grupowe-ergo`, `opieka-medyczna`), zawody (`kosmetolog`, `fryzjer`, `podolog`, `linergistka`, `stylistka-paznokci`, `tatuazysta`), rodzaje działalności (`gabinet-kosmetyczny`, `salon-masazu`), interfejs (`kalkulator`, `dokumenty`, `doradca`, `szkoda`, `szybka-wycena`, `bezpieczenstwo`, `wskaznik`, `w-zakresie`, `serce`).
- `.lux-icon{width:44px;height:44px;fill:none;stroke:currentColor;stroke-width:2.5;stroke-linecap:round;stroke-linejoin:round;color:var(--color-navy)}`; na ciemnym gold light; w przycisku `currentColor`. Ikona zawsze `aria-hidden="true"`.

| Rozmiar | Kreska | Klasa / miejsce |
|---|---|---|
| 54 px | 2.2 | kafle zawodów `.pro` |
| 48 px | 2.5 | kafelek produktu `.product` |
| 48 px | 2.2 | zawód `.pro` < 480 px (w `@media` zmienia się tylko rozmiar) |
| 44 px | 2.5 | `.lux-icon` (bazowa) |
| 32 px | 3 | `.lux-icon--md` (menu, kafelki wyboru, korzyści) |
| 22 px | 4 | `.lux-icon--sm` (szuflada, przyciski) |
| 28 px | 3.4 | `.chip` – filtr w Strefie (`strefa/dam-prace.html:105`) |
| 28–48 px | 2.5–3 | pozostałe w Strefie: `.offer` 40 px / 2.8 (32 px < 640 px), `.choice-grid .shortcut` 36 px / 2.8, `.policy-top` 36 px / 2.8 (< 768 px), `.doc-row` i `.statement` 32 px / 3, `.case-note` 28 px / 3, `.offer-title` 48 px / 2.5 |
| 16–20 px | 1.5–1.6 | glify interfejsu: lupa 20 px, słuchawka 18 px, zamknięcie dymka 16 px |

---

## 5. Layout Principles · Układ

### Kontener i rytm

- `.container{width:100%;max-width:var(--bp-container);margin-inline:auto;padding-inline:var(--bp-gutter)}` – 1240 px, margines `clamp(16px,4vw,40px)`. Strefa: 1280 px, `clamp(16px,3vw,32px)`, `.app` = menu boczne `--bp-side-w` (252 px) + treść, `gap: 24px`.
- Sekcje: `.section{padding-block:clamp(72px,11vw,168px)}`; `.section--flush-top` łączy sekcje na tej samej scenie bez szwu; hero podstron `clamp(124px,13vw,172px) 0 clamp(56px,8vw,104px)`; stopka `padding-block: clamp(56px,8vw,96px) 40px`.
- `.section-head`: `display: grid; gap: 18px; max-width: 44rem; margin-bottom: clamp(40px,6vw,88px)` (podstrony `clamp(36px,5vw,72px)` / `46rem`); wyśrodkowany tylko przy kalkulatorze (`--center`).
- Padding tafli zawsze płynny: hero i panel kontaktu `clamp(28px,4vw,56px)`, kalkulator `clamp(22px,3.5vw,48px)`, wynik i baner `clamp(26px,3vw,40px)`, stopka `clamp(28px,4vw,48px)`. Komórki tafli: produkt `36px 34px 30px`, zawód `32px 22px 28px`, krok `40px 34px 34px`.
- Najczęstsze odstępy (gap/padding/margin w px): 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 40, 44 – to nie jest zamknięta skala. CSS ma też pojedyncze literały spoza listy: 1, 3, 5, 7, 9, 13, 42, 46, 48, 50, 52, 56, 58 px (np. `.menu summary` `padding: 0 13px`, `.zab-input` `padding-left: 46px`, `.zab-chip` `padding: 3px 3px 3px 14px`) i odsunięcia hero (112, 140 px). Rytm sekcji to literały `clamp()` – bez osobnych tokenów.

### Siatki

| Siatka | Kolumny |
|---|---|
| Księga produktów `.ledger` | 3 → 2 (< 1024) → 1 (< 640) |
| Zawody `.pros` | 3 → 2 (< 1024) → 1 (< 480; wiersz z ikoną 48 px) |
| Kroki `.steps` | strona główna 3 → 1 (< 1024); podstrony 1 → 2 (≥ 768) → 4 (≥ 1200) |
| Kalkulator `.calc` | `1.55fr / 1fr`, `gap: clamp(22px,3vw,40px)` → 1 (< 1024) |
| FAQ, klauzula | `4fr / 7fr` od 1024 |
| „Jeden dzień” `.day-grid` | `5fr / 7fr` od 1024 |
| Strefa Klienta – zapowiedź `.sk` | `7fr / 5fr` od 1024 |
| Korzyści `.feats` | `repeat(auto-fit,minmax(min(100%,230px),1fr))`, `gap: 22px` |
| Stopka `.footer-nav` | 2 → 4 (≥ 1024) → 1 (< 480) |
| Słownik `.sl-uklad` | 340 px + 1fr od 1024; panel przyklejony `top: 108px` przy ≥ 1024×700 |

Zasada: każda kolumna to `minmax(0,…)` – długi tekst nie poszerza siatki i nie wywołuje poziomego przewijania.

### Kompozycja

- Jedna tafla szkła na sekcję; elementy w środku rozdzielone liniami włoskowymi (cienie `1px 0 0` i `0 1px 0`), nie osobnymi kartami.
- Nagłówki sekcji do lewej; duża rzymska cyfra rozdziału za nagłówkiem (`z-index: -1` w kontekście `isolation`).
- Szwy między scenami: `border-top: 1px solid rgba(217,192,137,.45)`.
- `html{scroll-padding-top:104px}` (92 px < 768); `scroll-margin-top` 104–120 px dla celów kotwic.

### Warstwy `z-index`

| Wartość | Element |
|---|---|
| −2 / −1 | zdjęcie hero; woalki, cyfry rozdziałów, warstwy tekstur |
| 1 / 2 | link rozciągnięty w kafelku / akcja nad nim, panel `.mega` |
| 5 | lista podpowiedzi `.zab-pop` |
| 50 | Strefa `--bp-z-topbar` |
| 55 | `--bp-z-sticky` – `.calc-peek`, `.pasek-akcji` |
| 60 | `--bp-z-header` |
| 79 / 80 | Strefa: tło szuflady / `--bp-z-drawer` |
| 85 | `.bp-dymek` |
| 100 | `--bp-z-skip` |

Dialogi `<dialog>` leżą w top layer, poza skalą.

---

## 6. Depth & Elevation · Głębia i warstwy

### Kolejność warstw sceny (od dołu)

1. Kolor podkładu sceny (`--color-parchment` / `--color-midnight`).
2. Zdjęcie (ładowane leniwie przez klasę `.bg-on`; hero jako `<img>`) i ziarno `--grain` (desktop ≥ 1024 px).
3. Woalki (`.hero::after`, na podstronach `rgba(20,28,51,.74)` pod nagłówkiem sekcji na jedwabiu).
4. Duża cyfra rozdziału.
5. Tafla szkła (`backdrop-filter`).
6. Wewnętrzna złota rama `::before`.
7. Treść.

### Cienie

| Rola | Wartość |
|---|---|
| Jasna tafla | `var(--shadow-glass), inset 0 1px 0 rgba(255,255,255,.75)` – `--shadow-glass` = `0 40px 80px -40px rgba(20,28,51,.45)` |
| Ciemna tafla | `var(--shadow-glass-dark), inset 0 1px 0 rgba(255,255,255,.08)` – `--shadow-glass-dark` = `0 40px 80px -40px rgba(0,0,0,.6)` |
| Belka nagłówka | `0 1px 2px rgba(20,28,51,.08), 0 16px 36px -22px rgba(20,28,51,.55), inset 0 1px 0 rgba(255,255,255,.75)` |
| Belka kompaktowa, `.mega` | `0 0 0 1px rgba(42,59,104,.07), 0 2px 4px rgba(20,28,51,.1), 0 18px 40px -20px rgba(20,28,51,.6), inset 0 1px 0 rgba(255,255,255,.75)` |
| Dymek | `0 0 0 1px rgba(42,59,104,.06), 0 2px 4px rgba(20,28,51,.1), 0 22px 44px -18px rgba(20,28,51,.6)` |
| Panele kryjące (menu, konto) | `var(--shadow-glass)` |
| Karty jasne kryjące | `0 30px 60px -40px rgba(20,28,51,.4)` (`.clause`, `.scope-card`, `.apply`, `.op-card`), `.45` (`.ledger` – utrata dochodu), `.5` (`.route--main`); `.job`, `.route` `0 24px 48px -38px rgba(20,28,51,.5)` |
| Karty granatowe | `0 30px 60px -34px rgba(20,28,51,.75)` (promo, karta końcowa); `0 30px 60px -30px rgba(20,28,51,.7)` (karta członkowska) |
| Elementy przyklejone | pasek akcji `0 14px 30px -12px rgba(20,28,51,.75)`; `.calc-peek` `0 14px 30px -14px rgba(20,28,51,.7)` |
| Dialog | `0 40px 80px -30px rgba(20,28,51,.65)` |
| Szuflada (Strefa) | `-30px 0 60px -30px rgba(20,28,51,.6)` |
| Lista podpowiedzi | `0 22px 44px -22px rgba(20,28,51,.5)` |
| Strefa `.surface` | `--shadow-surface` = `0 18px 40px -28px rgba(20,28,51,.45)` |

Wskaźniki stanu jako cienie wewnętrzne: `inset 2px 0 0 var(--color-gold)` – bieżąca pozycja menu; `inset 3px 0 0 var(--color-navy)` – `:target` w listach; `inset 0 0 0 1px var(--color-navy)` – zaznaczony kafelek; `inset 0 0 0 1px var(--bp-error)` – pole z błędem.

### Rozmycie (`backdrop-filter`)

Tylko cztery wartości: `blur(var(--blur-glass)) saturate(140%)` (24 px), `blur(var(--blur-glass-dark)) saturate(120%)` (22 px) i te same z `--blur-glass-mobile` (16 px) poniżej 768 px. Bez rozmycia: `.glass--tint`, belka nagłówka na telefonie (tło `rgba(247,243,236,.94)`), panele i elementy kryjące – `.mega`, `.menu-panel`, `.zab-pop`, `.klauzula`, `.bp-dymek`, `.pasek-akcji`, `.calc-peek`, `.result`.

**Limit: najwyżej 3 tafle z `backdrop-filter` w jednym widoku (2 na telefonie). Tafli się nie animuje.** Szkło zawsze leży na zdjęciu – na płaskim kolorze zostaje szary prostokąt.

### Obramowania i promienie

| Wartość | Gdzie |
|---|---|
| `--radius-card` 6 px | tafle, karty, dialogi, dymek |
| `--radius-btn` 3 px | przyciski, pola, kafelki wyboru, pasek ceny |
| `calc(var(--radius-card) - 3px)` = 3 px | ramy wewnętrzne |
| 2 px | znaczniki, `.badge`, znacznik `.opt--check` |
| 10 px | karta członkowska; licznik `.sidenav .count` (Strefa, `strefa/strefa.css:210`) |
| 12 px | `.switch` (Strefa) |
| 999 px | pigułki (chipy, plakietki) |
| 50% | koła (`.zab-chip-x`, kółka radia) |

Rama wewnętrzna: 1 px `--bp-line-gold` / `--bp-line-gold-on-dark`, odsunięta o `--bp-frame-inset` (9 px; karty Strefy 7 px, `.invite` 6 px, `.logo-chip` 4 px).

### Ruch

| Token / wartość | Użycie |
|---|---|
| `--ease-lux` `cubic-bezier(.2,.7,.1,1)` | jedyna krzywa marki |
| `--bp-dur-1` .2s | stany pól i kafelków wyboru |
| `--bp-dur-2` .3s | linki, krzyżyk FAQ, kafelki |
| `--bp-dur-3` .45s | nagłówek, pasek akcji |
| `.25s` | kolory przycisków |
| `.5s` / `.6s` | złota linia przycisku / zakładka kalkulatora, karta członkowska |
| `.4s` | wejście dialogu |
| `.45s` | rozwijanie `details` |
| 3.6s `cubic-bezier(.22,.61,.2,1)` | `hero-zoom` (scale 1.14 → 1) |
| 420 ms / 600 ms | „tyknięcie” ceny / linia wyniku (Web Animations) |
| 180 ms / 320 ms | otwarcie / zamknięcie menu po najechaniu |
| Strefa: `--bp-dur` .2s | wszystko (≤ 200 ms) |

- Animuje się wyłącznie `transform` (`translate`, `scale`) i `opacity`. Tekst nigdy nie zostaje półprzezroczysty (krycie pełne po 11vh przewinięcia).
- Ruch sterowany przewijaniem (`animation-timeline: scroll()/view()`) zamknięty w `@supports` i `@media (prefers-reduced-motion: no-preference)`; rezerwa – `IntersectionObserver` (`html.io-reveal`) i rAF (`html.sl-js`). Bez WebGL, bez bibliotek, bez przejmowania przewijania.
- `prefers-reduced-motion: reduce`: `transition: none !important; animation: none !important; scroll-behavior: auto`; nagłówek się nie chowa, cena nie „tyka”. W druku stany końcowe.

---

## 7. Do's and Don'ts · Rób / Nie rób

### Rób

- **Treść i oferta**
  - Podawaj składki ze stałej taryfy programu jako pewne kwoty: „od 400&nbsp;zł rocznie”, wynik z groszami („987,50&nbsp;zł”). Gdy kwoty nie ma – mów wprost: „Składkę wylicza ubezpieczyciel po ocenie ryzyka”, „Cenę przygotuje doradca”, „Składka do indywidualnej wyceny”.
  - Pokazuj warianty równorzędnie: ten sam kształt i kolor, kolejność rosnąca jak w taryfie (100 / 200 / 300 tys. zł).
  - Umieszczaj w stopce każdej strony (publicznej i Strefy) informacje o agencie: formułę spółki z KRS i „XII Wydział Gospodarczy KRS”, status agenta ubezpieczeniowego, numer RPU z odnośnikiem do `rpu.knf.gov.pl` i `details.legal-idd`.
  - Stosuj polską typografię: cudzysłowy „ ”, spacje twarde przed „zł”, w liczbach i po jednoliterowych spójnikach, półpauzę w zakresach (z U+2060 po niej).
- **Kolor i szkło**
  - Kładź szkło na zdjęciu; w jednym widoku najwyżej 3 tafle z rozmyciem (2 na telefonie). Panele pomocnicze (menu, podpowiedzi, dymek, dialog, paski) rób kryjące.
  - Dawaj każdej tafli wyjście awaryjne: kryjące tło bez `backdrop-filter`, przy `prefers-reduced-transparency` i `prefers-contrast: more`, obrys w `forced-colors`.
  - Złotem na jasnym rysuj tylko linie i ramy; tekst na ciemnym – gold light, ivory albo parchment.
  - Mierz kontrast na wyrenderowanym tle (szkło i zdjęcie) – każdy tekst WCAG 2.2 AA (4,5:1, duży 3:1), elementy interfejsu i obwódki fokusu ≥ 3:1.
- **Dostępność i interakcja**
  - Tekst ≥ 12 px (`--text-xs`), akapity 15–16 px.
  - Cele dotyku ≥ 24 px wszędzie; główne akcje ≥ 44 px (przyciski 48–50 px, opcje listy ≥ 48 px, wiersze szuflady ≥ 52 px). Link w zdaniu jest wyjątkiem (WCAG 2.5.8).
  - Pokazuj fokus zawsze (obwódka 2 px navy / gold light) i pilnuj, żeby nic go nie zasłaniało: `scroll-padding`, nagłówek nie chowa się przy fokusie w środku, paski znikają przy polach.
  - Uszanuj `prefers-reduced-motion`: każda animacja w `@media (prefers-reduced-motion: no-preference)`, treść widoczna bez JS i bez animacji.
  - Ogłaszaj wynik jednym `role="status"`; błędy pól wiąż przez `aria-describedby`, przycisk przy brakach – `aria-disabled`, etykieta z brakującym polem („Najpierw zaznacz rodzaj działalności”) i fokus na tym polu.
  - Budowanie: wspólne komponenty raz w generatorze (`gen_wspolne.py`, `gen_terminy.py`); kolumny siatek `minmax(0,…)`; brak poziomego przewijania od 320 px.

### Nie rób

- **Oferta**
  - Nie rekomenduj wariantu i nie wyróżniaj żadnego: bez plakietek „najczęściej wybierany” i „polecany”, bez innego tła albo ramki dla jednej opcji, bez zaznaczenia domyślnego.
  - Nie pisz „orientacyjnie”, „szacunkowo”, „do potwierdzenia”, „przykładowa składka” przy kwotach z taryfy.
  - Nie usuwaj ani nie skracaj do nieczytelności informacji o agencie w stopce; nie nazywaj Aura Expert brokerem.
- **Kolor i szkło**
  - Nie używaj fioletu ani różu w interfejsie (róż tylko w logo); nie dodawaj kolorów spoza tokenów.
  - Nie pisz tekstu złotem `--color-gold` (2,49:1 na ivory). Nie dawaj taupe eyebrow ani etykietom sekcji na szkle z rozmyciem lub zdjęciu (tam navy), a taupe w ogóle – bezpośrednio na zdjęciu. Podpis drugorzędny w taupe na szkle – tylko przy zmierzonym kontraście ≥ 4,5:1 (sekcja 2).
  - Nie kładź szkła na płaskim kolorze, nie układaj tafli w tafli i nie animuj tafli (ani `backdrop-filter`).
  - Nie dawaj czwartej tafli z rozmyciem do widoku – zamiast tego `glass--tint` albo kryjąca karta.
- **Typografia i kształt**
  - Nie schodź poniżej 12 px; nie używaj wag 300 i 700 ani prostego Cormorant 500.
  - Nie zaokrąglaj mocniej niż 6 px (wyjątki z CSS: pigułki 999 px, karta członkowska i licznik `.sidenav .count` w Strefie 10 px, przełącznik `.switch` 12 px, koła 50%).
  - Nie używaj prostych cudzysłowów, dywizu w zakresach ani łamania „zł” od kwoty.
- **Interakcja**
  - Nie uzależniaj działania od najechania (menu i dymek otwiera kliknięcie; efekty hover tylko przy `(hover:hover) and (pointer:fine)`).
  - Nie używaj `role="menu"` dla nawigacji, `style=""` w HTML (CSP z nonce) ani bibliotek animacji, WebGL i przejmowania przewijania.
  - Nie zasłaniaj fokusu przyklejonymi elementami i nie dodawaj `padding-bottom` do `body` pod pasek akcji.
  - Nie oznaczaj pojęć słownika w nagłówkach, przyciskach, formularzach, tabelach ani w stopce prawnej.
  - Nie kopiuj stylu cudzych marek – inspiracje tylko jako zasady (rozdziały, odkrywanie, tempo), nigdy elementy ani układy.

---

## 8. Responsive Behavior · Responsywność

### Progi (wartości z `@media`)

Komentarz w tokenach mówi o 480 / 768 / 1024 / 1200 px; w CSS progi są zapisane jako `max-width: 479/767/1023/1199px` i `min-width: 1024/1200px`, plus progi pomocnicze. Tabela obejmuje wszystkie progi z `@media` w makietach (stan 16.11.2026).

| Próg | Co się zmienia |
|---|---|
| `max-width: 359px` | 320 px: liczby osób i sumy w 1 kolumnie, ciaśniejsza belka, pasek akcji bez ikony, `letter-spacing .1em` |
| `max-width: 379px` | strona główna: wiersz ceny `.promo-price` się łamie; Tax Protect i słownik: liczby hero `.figures` w kolumnie |
| `max-width: 399px` | etykieta „Menu” tylko dla czytnika |
| `max-height: 600px` (Strefa, `dam-prace.html`) | okno `.zab-sheet` przewija się w całości, stopka okna przyklejona; z `max-width: 419px` – większy `scroll-padding-bottom` (156 px) |
| `max-width: 479px` | telefon: przyciski w grupach na pełną szerokość, `.opt-grid--2`, zawody i stopka w 1 kolumnie, FAQ `summary` 1.25rem (tylko podstrony), tabele z mniejszym paddingiem |
| `max-width: 539px` | liczby hero w wierszach |
| `min-width: 560px` (opieka medyczna) | karty porównania `.cmp-attr`: etykieta i wartość w dwóch kolumnach |
| `min-width: 600px` | cena produktu w szufladzie po prawej |
| `max-width: 639px` / `min-width: 640px` | księga produktów 1 kolumna / `.fields-2` w 2 kolumnach |
| `max-width: 719px` / `min-width: 720px` (Strefa) | tabele `.stack` jako karty / `.fields-3` w 3 kolumnach, akcje w tabeli `table.data` w kolumnie |
| **`max-width: 767px`** | telefon: rozmycie 16 px, belka bez rozmycia, tekstury w przyklejonej warstwie `::before` (`height: 100lvh`) zamiast rozciągania, hero jako pas 92vw z panelem zachodzącym o 96 px, martwa natura jako pas nad panelem, pasek akcji, `scroll-padding-top: 92px` |
| `min-width: 768px` | podstrony: kroki w 2 kolumnach, `.related` w 2 |
| `min-width: 900px` (podstrony) | siatki 2–3 kolumn: `.roles` (utrata dochodu), `.why-list` (NNW), `.panel-grid`, `.vcards` (grupowe), `.price-controls`, `.prices`, `.spec-list` (opieka) |
| **`max-width: 1023px` / `min-width: 1024px`** | kalkulator w 1 kolumnie + `.calc-peek` / kalkulator 2 kolumny, wynik przyklejony, ziarno, siatki 4/7, przyklejone nagłówki (gdy wysokość ≥ 700 px), Strefa: menu boczne zamiast szuflady |
| `max-width: 1099px` (Strefa, `dam-prace.html`) | nagłówek publiczny bez nawigacji, linku do Strefy i przycisku (`.pub-nav`, `.pub-client`, `.pub-cta`) |
| `max-width: 1180px` (Strefa, `szkolenia.html`) | filtry `.filters` w 2 kolumnach |
| **`max-width: 1199px` / `min-width: 1200px`** | szuflada `details.menu` / pełna nawigacja z menu „Ubezpieczenia”; podstrony: kroki w 4 kolumnach |
| `max-height: 500px` | nagłówek `position: absolute` (nie przykleja się), brak paska akcji |
| `max-width: 599px`, `max-height: 599px` | dymek jako panel u dołu |
| `min-height: 700px` (z `min-width: 1024px`) | przyklejone nagłówki sekcji i panele (FAQ, „Jeden dzień”, słownik); klauzula od `min-height: 880px` |
| `(hover:hover) and (pointer:fine)` | efekty najechania (złota linia przycisku, kafelki) |
| `(pointer: coarse)` | linki stopki 44 px, chipy 44 px |

### Cele dotyku

| Element | Wysokość / rozmiar |
|---|---|
| `.btn` (publiczne) | 50 px; `.mega .btn`, Strefa `.btn`, pasek akcji 48 px; Strefa `.btn-sm` 44 px |
| `.link-lux`, `.link-quiet`, `.main-nav a`, `.check-row`, „Więcej w słowniku”, zamknięcie dymka | 44 px; wiersze list `.ankieta-lista .check-row` i `.zab-list .check-row` (Strefa) 40 px |
| `.opt label` | 56 px; `.zab-opt`, pola 48 px; `.zab-input` 52 px; wiersz szuflady 52 px; `summary` FAQ 64 px; zakładki kalkulatora 64 px |
| `.footer-nav a` | 34 px (44 px przy `pointer: coarse`) |
| `.zab-chip-x` | 34×34 px |
| okruszki | 32 px (Strefa 24 px) |
| `.legal-idd > summary` | 24 px (minimum WCAG 2.5.8) |

### Zachowanie komponentów

- **Menu:** ≥ 1200 px – nawigacja w belce i panel `.mega` (disclosure); < 1200 px – szuflada `details.menu` z przyciskiem „Oblicz składkę OC” i listą produktów z cenami. Zamknięcie panelu po przewinięciu o > 120 px.
- **Nagłówek:** kompaktowy po 40 px przewinięcia; chowa się przy przewijaniu w dół od 320 px (nigdy przy ograniczonym ruchu, oknie ≤ 500 px, otwartym menu ani fokusie w środku).
- **Pasek akcji:** tylko < 768 px i przy oknie > 500 px wysokości; znika przy elementach, które dublują jego akcję, przy stopce, polu z fokusem i klawiaturze (`visualViewport` < 72%).
- **Pasek ceny `.calc-peek`:** tylko < 1024 px, jedna linia, wysokość ≤ 72 px mniejsza niż `scroll-padding-bottom` 84 px – nie zasłania pól przy przechodzeniu klawiszem Tab.
- **Tabele:** przewijanie wewnątrz `.table-scroll`; porównanie `.cmp-table` od 1024 px, poniżej karty `.cmp-attr`; Strefa `.stack` < 720 px.
- **Dialogi:** `width: min(calc(100% - 32px), …)`; `.zab-sheet` pełny ekran < 640 px; dymek jako panel < 600 px szerokości lub wysokości.
- **Zawsze:** brak poziomego przewijania od 320 do 1440 px (także przy odstępach tekstu z WCAG 1.4.12 i powiększeniu 200%); `env(safe-area-inset-*)` w paskach i dymku (`viewport-fit=cover`).

---

## 9. Agent Prompt Guide · Ściąga dla agentów

### Szybka ściąga kolorów

```
Tło bazowe ........ --color-ivory      #F7F3EC   (body, panele kryjące)
Tło sceny jasnej .. --color-parchment  #EDE5D8   (+ zdjęcie marmuru z lnem)
Tło sceny ciemnej . --color-midnight   #141C33   (+ zdjęcie granatowego jedwabiu)
Nagłówki, akcje ... --color-navy       #2A3B68   (hover --color-navy-deep #1E2B4F)
Tekst ............. --color-ink        #1B2233
Podpisy .......... --color-taupe      #5F574D   (eyebrow tylko na kryjącym; podpis na szkle przy ≥ 4,5:1)
Złoto – tylko linie --color-gold       #B8975A   (--bp-line-gold, --bp-line-gold-soft)
Złoto – tekst/ciemne --color-gold-light #D9C089
Błąd .............. --bp-error         #7A2E2E
Szkło ............. .glass (ivory .7, blur 24) · .glass--strong (.9) · .glass--dark (midnight .56, blur 22) · .glass--tint (bez blur)
```

**Szybka ściąga typografii:** nagłówki `--font-serif` 600 navy (H1 `--text-h1`, H2 `--text-h2`, H3 `--text-h3`), akcent `<em>` kursywa 500; tekst `--font-sans` 400 `--text-base`/1.7 ink; eyebrow i przyciski `--font-caps` 500 `--text-xs` wersaliki `--tracking-label`; minimum 12 px. Promienie: karty 6 px, przyciski i pola 3 px.

### Lista kontrolna przed oddaniem ekranu

1. Kolory tylko z tokenów; brak fioletu i różu; złoto jako tekst tylko gold light na ciemnym.
2. W każdym widoku ≤ 3 tafle z `backdrop-filter` (≤ 2 na telefonie), każda na zdjęciu, z wyjściami awaryjnymi.
3. Tekst ≥ 12 px; kontrast AA zmierzony na wyrenderowanym tle; cele ≥ 24 px, główne akcje ≥ 44 px.
4. Fokus widoczny i niezasłonięty; ruch tylko przy `prefers-reduced-motion: no-preference`; treść działa bez JS.
5. Brak rekomendacji wariantów, plakietek i słów „orientacyjnie/szacunkowo”; brak wartości domyślnych w wyborze.
6. Stopka z informacjami o agencie (KRS z „XII Wydział”, agent ubezpieczeniowy, RPU).
7. Polska typografia: „ ”, `&nbsp;` przed „zł” i po jednoliterowych spójnikach, „6–&#8288;8”.
8. Brak poziomego przewijania od 320 px; axe (WCAG 2.2 AA) bez naruszeń.

### Gotowe polecenia

**1. Formularz wniosku w stylu BeautyPolisa**

> Zbuduj ekran wniosku według `DESIGN.md` BeautyPolisa. Tło: scena marmuru (`.scene.scene--marble`, kolor podkładu `--color-parchment`). Na niej jedna tafla `.glass.frame` z paddingiem `clamp(28px,4vw,56px)` i maks. szerokością 600 px (wzorzec `.cta-panel`). Nad formularzem eyebrow (`.eyebrow`, navy na szkle) i H2 serif 600 navy z akcentem `<em>` w kursywie 500. Pola `.field`: etykieta wersalikami `--text-xs` z rozstrzeleniem .14em navy, pole `min-height: 48px`, `padding: 10px 14px`, obrys `--bp-line-field`, promień `--radius-btn`, tło `rgba(255,255,255,.75)`, tekst `--text-base`. Pola opcjonalne z dopiskiem „(opcjonalnie)”. Wybory jako kafelki `.opt` w `fieldset` z `legend` serif `--text-serif-md` – bez zaznaczenia domyślnego. Błąd: `aria-invalid="true"`, obrys `--bp-error` + `inset 0 0 0 1px var(--bp-error)`, komunikat `.field-error` (13 px, `--bp-error`) z przykładem poprawnej wartości, powiązany `aria-describedby`; po próbie wysłania fokus na pierwszym błędnym polu. Zgody `.check-row.consent`. Wysyłka `.btn.btn-navy` (50 px; < 480 px pełna szerokość), stan po wysłaniu `.lead-status` z `role="status"`. Polska typografia, `&nbsp;` po „i/w/z/o/a”. Żadnej drugiej tafli z rozmyciem obok.

**2. Strona produktu ubezpieczenia (podstrona)**

> Zbuduj podstronę produktu w stylu BeautyPolisa: hero na zdjęciu z panelem `.glass.frame` (H1 `clamp(2.5rem,1.4rem + 3.6vw,4.4rem)`, lead `--text-lead`, akcje `.btn-navy` + `.btn-ghost`), okruszki `.crumbs`. Dalej rozdziały na przemian: scena marmuru (jasna) i jedwabiu (ciemna, klasa `.dark`: H2 ivory, akapity parchment, eyebrow i ikony gold light). Zakres jako jedna tafla z komórkami rozdzielonymi liniami `--bp-line-gold-soft`, taryfa w `details.tariff-table.glass--tint` z `.table-scroll` (kwoty bez groszy, `&nbsp;` przed „zł”), FAQ w jednej tafli `.faq` (`summary` serif 1.4rem, krzyżyk 16 px). Na końcu panel kontaktu i stopka na jedwabiu z `glass--dark` i pełnymi informacjami o agencie. Maks. 3 tafle z rozmyciem w widoku; kwoty jako stałe („od … zł rocznie”), bez „orientacyjnie” i bez wyróżniania wariantów.

**3. Ekran Strefy Klienta (lista polis i dokumentów)**

> Zbuduj ekran Strefy Klienta według `DESIGN.md` (skala aplikacji z `strefa/strefa.css`): tło marmuru z woalką `rgba(247,243,236,.42)`→`.62`, ciemny pasek górny `.topbar` (68 px, przyklejony), menu boczne `.sidenav` w `glass--strong` (pozycje 46 px, bieżąca – tło `.85` + złoty pasek 2 px). Dane wyłącznie na kryjących powierzchniach `.surface` (`--bp-surface`, obrys `--bp-line-gold-soft`, `--shadow-surface`). H1 `clamp(2.1rem,1.6rem + 1.8vw,3rem)`, H2 `clamp(1.6rem,1.35rem + .9vw,2rem)`. Statusy `.badge` zawsze ze znakiem i tekstem (nie samym kolorem); komunikaty `.alert` z lewą krawędzią 3 px; tabela `table.data`, poniżej 720 px wiersze jako karty `.stack`. Przyciski 48 px (`.btn-sm` 44 px), ruch ≤ 200 ms (`--bp-dur`). Stopka `.app-footer` z blokiem `.legal-idd`.

**4. Porównanie wariantów lub tabela składek bez rekomendacji**

> Zbuduj porównanie wariantów w stylu BeautyPolisa: tabela w `.table-scroll` (`role="region"`, `tabindex="0"`, `aria-label`) na tafli `glass--tint`, `caption` serif `--text-serif-sm` navy, nagłówki kolumn `--text-xs` 500 navy, komórki `10px 8px` z linią `--bp-line-gold-soft`, kwoty do prawej z cyframi tabelarycznymi i `&nbsp;` przed „zł”. Wszystkie warianty wyglądają tak samo – bez plakietek „najczęściej wybierany”/„polecany”, bez wyróżnionej kolumny, bez zaznaczenia domyślnego; podświetlenie tylko po wyborze użytkownika. Kwoty stałe, bez „orientacyjnie/szacunkowo”; wycena indywidualna jako wiersz `.row-ind` z tekstem. Poniżej 480 px nagłówki kolumn się łamią, strona nie przewija się w poziomie od 320 px.

**5. Komunikaty stanu i dialog z treścią dokumentu**

> Dodaj stany według `DESIGN.md` BeautyPolisa: sukces formularza jako `.lead-status` (obrys `--bp-line-gold`, tło `rgba(255,255,255,.6)`, serif 600 1.3rem navy, `role="status"`, `tabindex="-1"` i fokus po wysłaniu); błędy jako lista linków do pól (lewa linia 2 px `--bp-error`); pusty stan z przerywanym obrysem `--bp-line-gold` i tytułem serif. Treść dokumentu w natywnym `<dialog>` (`showModal`): `width: min(calc(100% - 32px),780px)`, kryjące ivory (bez rozmycia), obrys `--bp-line-gold`, promień 6 px, cień `0 40px 80px -30px rgba(20,28,51,.65)`, `::backdrop` `rgba(20,28,51,.72)`, treść przewijana w regionie z `tabindex="0"`, zamknięcie obrysem navy 44 px; wejście `.4s var(--ease-lux)` tylko przy `prefers-reduced-motion: no-preference`.

---

## Znane rozbieżności · Known Discrepancies

Różnice zastane w źródłach. DESIGN.md je opisuje i wskazuje, co przyjąć w nowych ekranach; **makiet nie ujednolicamy w ramach tego pliku** – zmiany w makietach i generatorach to osobne zadania.

| # | Rozbieżność | Źródła | Co przyjąć w nowych ekranach |
|---|---|---|---|
| 1 | Nazwy tokenów: dok. 10 (rozdz. 3, D13) używa `--midnight`, `--navy`…, CSS – `--color-midnight`, `--color-navy`… (nazwy `@theme` Tailwind 4) | dok. 10:30–42; `tokens-v3.css:4`; `makieta-v3.html:254–256` | nazwy z CSS |
| 2 | `.glass--strong`: dok. 10 – „ivory 82%”; strony publiczne `rgba(247,243,236,.9)`; Strefa `.88` | dok. 10:65; `makieta-v3.html:269`; `strefa/strefa.css:43` | `.9` (publiczne), `.88` (Strefa) – według kontekstu |
| 3 | Rozmiary nagłówków: dok. 10 – H1 44–80 px, H2 34–54 px, H3 26 px; CSS – H1 44–84 px, H2 36–68 px, H3 26,4 px | dok. 10:48; `makieta-v3.html:261–262` | wartości z CSS (tabela w sekcji 3) |
| 4 | Wagi: dok. 10 rozdz. 4 wymienia Poppins 300/400/500 i Cormorant 500/600; ładowane są tylko Cormorant 600 i 500 kursywa oraz Poppins 400/500 (także w Strefie). Niezaładowane wagi: `.mega-name` – prosty Cormorant 500; Strefa: `.monogram` – `font: italic 600 1.05rem` (Cormorant kursywa 600, syntetyzowana), `.badge--error::before` i `.field-error::before` – Poppins 600 | dok. 10:48–49, 183; `gen_wspolne.py:162`; `makieta-v3.html:1114`; `strefa/strefa.css:186`, `328`, `376` | tylko ładowane wagi; `.mega-name` do poprawy w generatorze, trzy selektory Strefy w `strefa.css` |
| 5 | Fonty zastępcze: Strefa nie ma `Cormorant Fallback 2` ani `Poppins Fallback 2` | `strefa/strefa.css:20–23`, `31–33` | pełne stosy z sekcji 3 |
| 6 | Progi: komentarz „480 / 768 / 1024 / 1200” nie oddaje wszystkich progów w `@media` | `tokens-v3.css:53`; `makieta-v3.html:280` | tabela progów z sekcji 8 |
| 7 | `tokens-v3.css` nie zawiera przycisków, choć dok. 10 rozdz. 11 tak podaje; blok `@theme` nie ma tokenów `--bp-*`; mobilne rozmycie obejmuje tam tylko `.glass`, a w makietach także `.glass--dark` | dok. 10:139; `tokens-v3.css:62`; `makieta-v3.html:865–866` | CSS makiet |
| 8 | Strefa ma własną skalę: `--bp-line-navy` `.18` vs `.22`, `--bp-glass-midnight` `.78` vs `.56`, `.btn` 48/12/24 vs 50/14/28 px, `.eyebrow::before` 32 vs 36 px, `.link-lux` 24→40 vs 28→44 px, inne `.lead`, `.logo-chip`, `.crumbs`, `.skip` (−80 vs −60 px), czas .2s i dialog .2s/10 px vs .4s/14 px – celowe „dostrojenie do aplikacji” | `strefa/strefa.css:3–5`, `44`, `48`, `116–140` | skala Strefy w aplikacji, publiczna na stronach publicznych |
| 9 | Kolizje nazw klas: `.ledger` (siatka produktów vs karta rachunku na utracie dochodu), `.steps` (3 znaczenia), `.kv`, `.chip` (dwie wersje w Strefie), `.zab-chip`, `.zab-list` | `.ledger`: `makieta-v3.html:474`, `utrata-dochodu.html:250`; `.steps`: `makieta-v3.html:705`, `utrata-dochodu.html:334`, `strefa/strefa.css:395`; `.kv`: `grupowe-ergo.html:527`, `strefa/strefa.css:273`; `.chip`: `strefa/dam-prace.html:101`, `strefa/szkolenia.html:40`; `.zab-chip`: `makieta-v3.html:627`, `strefa/dam-prace.html:251`; `.zab-list`: `makieta-v3.html:611`, `strefa/dam-prace.html:244` | w kodzie produkcyjnym nazwy z przedrostkiem komponentu |
| 10 | Czas wejścia hero: dok. 10 – najwyżej 1,15 s; `.figures` kończy się po 1,25 s, `.partners` po 1,65 s | dok. 10:175; `makieta-v3.html:970–971` | ≤ 1,15 s, tylko ozdoby |
| 11 | Literały zamiast tokenów: `#fff`, `#F3F5F9`, `#FBF6EA`, pochodne `rgba`, `z-index` 2/5/85, rytm sekcji bez tokenów | `strefa/strefa.css:340–341`; `makieta-v3.html:610`, `1174` | wartości jak w CSS; przy przenoszeniu do Tailwind – nowe tokeny o tych samych wartościach |
| 12 | Drobne różnice podstron: `.dark .chapter-no` `.13` vs `.14`; `overflow: clip` vs tylko `hidden`; padding taryf `10px 8px` vs `12px 8px`; `.hero-panel` 640 vs 780 px (`grupowe-ergo` 860 px); `.section-head` `44rem` vs `46rem`; tło pola `.75` vs `.85` (opieka) vs `#fff` (Strefa); FAQ `summary` < 480 px – 1.25rem na podstronach, 1.4rem na stronie głównej (brak reguły) | `makieta-v3.html:417`, `441`, `687`, `797`, `890–910`; `oc-beauty.html:201`, `225`, `341`, `454`; `opieka-medyczna.html:639`; `grupowe-ergo.html:456` | wartości strony głównej, chyba że ekran jest podstroną tego samego typu |
| 13 | Fiolet: nie występuje w żadnym pliku CSS | wszystkie arkusze v3 | zgodne z zasadą „brak fioletu” |
| 14 | Specyfikacja Stitch: oryginał (stitch.withgoogle.com) niedostępny z sesji (ponowna próba 16.11.2026 – host nie rozwiązuje się w sieci sesji); format według opisu 9 sekcji, front matter YAML niezweryfikowany walidatorem `@google/design.md`. Ryzyka schematu: klucze w postaci nazw właściwości CSS (`--color-*`), typografia jako płaskie stringi zamiast obiektów, niestandardowe grupy `elevation`, `layout`, `motion` | – | po dopuszczeniu hosta `stitch.withgoogle.com` w ustawieniach sieci sprawdzić front matter ze specyfikacją; w razie potrzeby zmapować klucze na nazwy semantyczne, a tokeny CSS zostawić w treści |
| 15 | Dok. 10 a CSS: rozstrzelenie etykiet „.2–.24em” – w CSS największe rozstrzelenie etykiet to `.22em` (tytuły stopki); `.24em` występuje tylko jako `text-underline-offset` pojęcia `.bp-termin`, nie jako `letter-spacing` (poza etykietami jest jeszcze `.45em` w polu kodu `.code-input` Strefy); tabela szkła przypisuje `.glass--strong` do „menu mobilnego”, `.glass--dark` do „kart ubezpieczeń”, a `.frame` do „kart” – w makietach menu mobilne `.menu-panel` jest kryjące ivory, karty ubezpieczeń leżą w `.ledger--light.glass--strong`, a `.frame` mają panel hero, kalkulator, panel kontaktu (i karty Strefy, zob. 4.4) | dok. 10:50, 65–67; `makieta-v3.html:404`, `1346` | wartości i role z CSS (sekcje 3, 4.4) |
| 16 | Komentarz CSS „taupe tylko na kryjącym tle” (`makieta-v3.html:344`, `oc-beauty.html:131`) a makiety: taupe mają też podpisy na szkle (sekcja 2), eyebrow list zabiegów na `.glass--tint` i – w Strefie – etykiety `.label-caps` na `.glass--strong` | `makieta-v3.html:491`, `509`, `527`, `535`; `oc-beauty.html:1008`; `strefa/panel.html` (`.sidenav-title`) | reguła z sekcji 2: eyebrow i etykiety sekcji na szkle z rozmyciem – navy; podpisy taupe na szkle przy zmierzonym ≥ 4,5:1 |
