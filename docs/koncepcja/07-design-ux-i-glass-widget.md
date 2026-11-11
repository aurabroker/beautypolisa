# 07 · Design, UX, responsywność i efekt glass widget

> **Uwaga – wersja zastąpiona.** Zleceniodawca odrzucił warstwę wizualną tej sekcji. Paleta, typografia, ikony, zdjęcia i makieta zostały zaprojektowane od nowa w Bloom. Aktualna jest wersja v3 w stylu old money, opisana w `10-design-v3-old-money.md` (tokeny: `design/v3/tokens-v3.css`, makieta: `design/v3/makieta-v3.html`, ikony: `design/v3/ikony/`). Wersja v2 (`09-design-v2-bloom.md`) też jest nieaktualna. Z tej sekcji nadal obowiązują: krytyka obecnego kodu, lista WCAG 2.2 AA, zasady responsywności, inwentarz komponentów, mikrocopy i szablony stron. Wartości kolorów i fontów podane niżej (Montserrat, Inter, `#e11d48`, `#be123c`, tryb ciemny) są nieaktualne.

> Sekcja koncepcji portalu **beautypolisa.eu**. Fakty o kliencie, produktach i cenach pochodzą wyłącznie z `01-audyt-stanu-obecnego.md`; obserwacje o obecnym designie – z plików `indeksowt.html`, `nowy.html`, `new.html`, `bp-nav.js`, `bp-app.js`, `tax-protect.html`, `life.html`, `life1.html`, `medical.html`, `style.css`. Pliki towarzyszące: `snippets/glass-widget.css` (tokeny i klasy) oraz `snippets/mockup-glass-widget.html` (v1, usunięta – zastąpiona przez `design/makieta-v2.html`) (samodzielna makieta bez zależności zewnętrznych, zweryfikowana skryptem Playwright w Chrome – wyniki w sekcji „Przekazanie do developmentu”).

## TL;DR

- Obecny front to pięć niezależnie stylowanych stron (trzy sposoby ładowania Tailwinda, dwie rodziny nagłówkowe, trzy systemy nazw kolorów, emoji jako ikony). Największe problemy UX: tekst 7–11 px, blokada zoomu, radio/checkboxy niedostępne z klawiatury, 2 z 6 zakładek prowadzące do `#`, brak CTA w zasięgu kciuka na mobile.
- Kierunek: **„spokojny premium”** – precyzja i powściągliwość ubezpieczyciela, lekkość gabinetu beauty. Jeden akcent (róż) zarezerwowany dla jednego działania na ekran.
- Róż `#e11d48` na białym daje 4,70:1 – wystarcza dla białego tekstu na różowym wypełnieniu CTA, ale jako tekst na tle `#fafafa` (4,50:1) i `#fff1f2` (4,28:1) nie przechodzi. Dla tekstu i linków: `#be123c` (6,29:1). Granat `#2a3b69` jest bezpieczny (10,89:1).
- Glass widget stosujemy w trzech miejscach: kalkulator w hero, sticky header, karta wyniku. Tekst pomocniczy wyłącznie na wewnętrznym panelu o kryciu 92 %; pełne fallbacki dla `@supports`, `prefers-reduced-transparency`, `prefers-contrast: more`.
- Design system to zestaw CSS custom properties (kolory z policzonymi kontrastami, typografia `clamp()`, odstępy 4 px, promienie, cienie, ruch), który trafia 1:1 do bloku `@theme` Tailwind 4.
- Mobile-first od 360 px, cele dotykowe ≥ 44 px, bez blokady zoomu, bezpieczne obszary `env()`, checklista WCAG 2.2 AA i kryteria akceptacji wizualnej dla developmentu.

## Krytyka obecnego designu

**Ogólne wrażenie.** Strony wyglądają jak kilka iteracji tego samego landinga wykonanych w różnych tygodniach: ten sam granat i róż, ale inne fonty nagłówków, inne promienie, inne rozmiary pisma i trzy różne nawigacje. Kalkulator OC ma dobrą logikę (zabiegi → parametry → wynik), lecz interfejs przytłacza drobiazgami i walczy z użytkownikiem mobilnym.

### Użyteczność

| Obserwacja (plik, fragment) | Waga | Rekomendacja |
|---|---|---|
| Pasek pomocniczy nad headerem ma `text-[10px]` (`indeksowt.html`, `life.html`), a `nowy.html` – `font-size: 10px`; zawiera linki do 3 produktów bez stron (`href="#"`) | 🔴 | Usunąć pasek; jedna nawigacja produktowa z sześcioma działającymi zakładkami (makieta: header → `nav.tabs`) |
| Trzy poziomy nawigacji: pasek pomocniczy, sticky header z CTA, pasek zakładek `bp-nav.js` (`new.html`/`life1.html`) – każdy z inną listą produktów | 🔴 | Jeden header: logo, zakładki produktów, przełącznik trybu, CTA; linki drugorzędne w stopce i w arkuszu „Więcej” na mobile |
| `maximum-scale=1.0, user-scalable=no` w `indeksowt.html`, `tax-protect.html`, `life.html`, `life1.html`, `medical.html`, `new.html` | 🔴 | `width=device-width, initial-scale=1, viewport-fit=cover` – bez ograniczania zoomu (WCAG 1.4.4) |
| Listy zabiegów: `.proc-item span{font-size:9px}` i `.proc-item input{width:.85rem;height:.85rem}` (`bp-app.js`); w `indeksowt.html` 0,75 rem tekstu i 1,1 rem checkbox w 3 kolumnach o stałej wysokości 300–320 px z własnym przewijaniem | 🔴 | Na mobile wybór **grupy ryzyka** (4 karty) zamiast 45 checkboxów; pełna lista zabiegów jako rozwijana ściąga „Które zabiegi należą do grupy 2?”; żadnych zagnieżdżonych obszarów przewijania |
| Radio „liczba osób” ukryte przez `display:none` (`.emp-card input[type=radio]`, `.radio-card input[type="radio"]`) – pole znika z kolejności tabulacji | 🔴 | Input widoczny dla technologii asystujących (`opacity:0; position:absolute; inset:0`), styl na `:checked + .card`, fokus na `:focus-visible + .card` (makieta: `.choice`) |
| Krok 2 „zablokowany” przez `opacity:.38; pointer-events:none` bez `aria-disabled`, bez komunikatu dlaczego | 🟡 | Stepper z `aria-current="step"`, przycisk „Dalej” z walidacją i komunikatem tekstowym („Najpierw wybierz grupę zabiegów”) |
| Etykiety formularzy `text-[9px]`/`text-[10px]` uppercase, komunikaty statusu 8–9 px (`#regon-status`, `#nip-status`), nota RODO i dystrybutora w modalu `font-size:9px` | 🔴 | Minimum 12 px dla przypisów, 14 px dla UI, 16 px dla treści; etykiety w zdaniu, nie uppercase |
| Placeholdery jako jedyna instrukcja formatu („500 000 000”, „9 lub 14 cyfr”) w domyślnym kolorze Tailwinda 4 (`currentColor` 50 % → ok. 3,0:1 na `#f8fafc`); pola 12 px (`text-xs`) i 12,5 px (`.minput` w `bp-app.js`) – iOS przybliża pola poniżej 16 px; brak `autocomplete`, `inputmode` tylko na REGON | 🟡 | Etykieta + stały tekst pomocniczy pod polem (placeholder wyłącznie jako przykład, ≥ 4,5:1), pola 16 px, `autocomplete="email/tel/organization"`, `inputmode="numeric"` dla NIP/REGON/telefonu |
| Modale: brak pułapki fokusu, brak powrotu fokusu po zamknięciu, `body.style.overflow` ręcznie, Esc obsługiwany tylko w `bp-app.js` | 🟡 | Natywny `<dialog>` z `showModal()` lub komponent z pułapką fokusu; dla formularza leadowego – osobny widok strony zamiast modala |
| Brak sticky CTA na mobile; CTA w headerze to `text-xs` 12 px, na mobile header składa się w kolumnę (`flex-col sm:flex-row`) | 🟡 | Sticky pasek dolny na < 768 px: „Oblicz składkę” + „Kontakt”, chowany, gdy kalkulator jest w widoku |
| Duplikaty: `index.html` („Hello World”), `indeksowt.html`, `new.html`, `nowy.html`; `life.html` vs `life1.html` | 🟡 | Jedna strona na URL (`04-seo-geo-i-schema.md` – przekierowania 301 ze starych plików) |
| Pasek „Zakres ochrony” (3 kolorowe boksy) i hero spychają kalkulator ok. 2 ekrany w dół na 360 px | 🟡 | Kalkulator jako glass widget **w hero** (makieta), zakres ochrony pod wynikiem |
| Efekt konfetti z CDN po wysłaniu wniosku; `scroll-behavior: smooth` bez `prefers-reduced-motion` | 🟢 | Usunąć zależność; potwierdzenie tekstowe + toast; globalna reguła reduced-motion |
| Przycisk zamknięcia modala „✕” bez minimalnego celu (`.mclose{font-size:1rem}`), przyciski „Wszystkie” 9 px | 🟡 | Wszystkie cele ≥ 44 × 44 px (minimum WCAG 2.2: 24 × 24) |

### Hierarchia wizualna

Wzrok trafia najpierw na różową połowę H1 („dla Branży Beauty”), potem na trzy białe pigułki i dopiero po przewinięciu – na kalkulator; na mobile między hero a pierwszym krokiem jest sekcja zakresu ochrony z trzema pastelowymi kartami w kolorach spoza palety (`#f0f8ff`, `#e0f2fe`, `#fff1f2`), które konkurują z CTA. W samym kalkulatorze trzy kolumny po kilkanaście checkboxów w 9–12 px tworzą jednolitą „ścianę”, bez punktu wejścia. Wynik ma dobrą hierarchię (cena 4xl, wariant środkowy wyróżniony), ale wstążka „Rekomendacja Ekspertów” to 8–9 px wersalikami. Kolejność czytania na mobile: badge → H1 → akapit → pigułki → (zakres) → krok 1 → krok 2 (wyszarzony) → wynik → stopka z notą prawną 9 px. Akcenty: róż pojawia się jednocześnie w H1, badge’u, numerach kroków, ramce karty, wstążce i przycisku – przestaje oznaczać „działanie”.

### Spójność

| Element | Niespójność | Poprawka |
|---|---|---|
| Font nagłówków | Playfair Display (`indeksowt.html`, `nowy.html`) vs Montserrat 800 (`tax-protect.html`, `medical.html`, `life.html`, `bp-app.js`) | Montserrat (zmienny) dla nagłówków; Playfair usunięty |
| Sposób ładowania stylów | skompilowany `style.css` (Tailwind 4) vs `cdn.tailwindcss.com` (Play CDN, nieprodukcyjny) vs CSS wstrzykiwany z JS (`bp-app.js`, `bp-nav.js`) | Jeden build Tailwind 4 w Next.js, zero CSS w JS |
| Nazwy kolorów | `--navy`/`--pink` (`bp-app.js`), `--nav-navy` (`bp-nav.js`), `--beauty-navy` (`life.html`), klasy `.text-beauty-navy` (`indeksowt.html`), kolory inline `style="background-color:#f0f8ff"` | Tokeny z `snippets/glass-widget.css` → `@theme` |
| Lista produktów | pasek pomocniczy: 5 pozycji („Life”, „Opieka medyczna”); `bp-nav.js`: 6 zakładek („Prywatne L4”, „Opieka Med.”, „Życie”); zlecenie: 6 produktów z innymi nazwami | Nazwy kanoniczne: OC dla branży beauty (ERGO Hestia), Tax Protect (Colonnade), Utrata dochodu, NNW dzieci, Grupowe ERGO dla beauty, Opieka medyczna (ENEL-MED / LUX MED) |
| Aktywność zakładek | 6 w nawigacji, 2 z `href="#"` (`opacity:.5`, nadal fokusowalne) | Każda zakładka prowadzi do strony produktu; produkt bez cennika ma stronę informacyjną z formularzem |
| Ikonografia | emoji 🛡️ ⚖️ 🩺 ➕ 💙 ⭐ 🌙 ☀️ 🔍 ✨ ℹ️ (różne glify na iOS/Android/Windows) + znaki Unicode ✓ ✕ | Lucide, 20/24 px, stroke 1,75 |
| Tryb ciemny | `bp-nav.js`: nadpisania klas Tailwinda przez `!important`; `bp-app.js`: zmienne CSS; strony Play CDN: brak | `data-theme` + tokeny; brak `!important` |
| Promienie i rozmiary przycisków | `.55rem/.6rem/.65rem/1rem/1.1rem/1.2rem/9999px`; `.btn-xs` 10 px, `.btn-sm` 11 px, `.btn-md` 12 px | Skala 8/12/16/24 px + pełny; przyciski 44 px, tekst 14 px |
| Komunikat o dystrybutorze | „Obsługa Brokerska” (header), „Informacje o agencie ubezpieczeniowym” (modal), „Broker Ubezpieczeniowy” (stopka), „Agent działa na rzecz…” (`bp-app.js`) | Jedna formuła prawna po potwierdzeniu statusu (pytanie otwarte; obowiązki IDD – `02-architektura-i-bezpieczenstwo.md`) |
| Dane kontaktowe | dwa różne numery telefonu „obsługi technicznej” w stopkach (`indeksowt.html`/`tax-protect.html` vs `medical.html`) | Jedno źródło danych firmowych w konfiguracji |
| Domena | `https://www.beautypolisa.com/#agency` w JSON-LD | `https://beautypolisa.eu` (bez www) |

### Dostępność

Współczynniki policzone wg wzoru WCAG (luminancja względna, sRGB):

| Para | Współczynnik | Werdykt |
|---|---|---|
| granat `#2a3b69` na białym | 10,89:1 | AAA – tekst i tła przycisków |
| biały na granacie | 10,89:1 | AAA |
| róż `#e11d48` na białym | 4,70:1 | AA tylko dla tekstu normalnego – bez zapasu |
| róż `#e11d48` na `#fafafa` (obecne tło body) | 4,50:1 | na granicy |
| róż `#e11d48` na `#fff1f2` (hero, pigułki, `.price-top` wariantu) | 4,28:1 | **nie spełnia** |
| biały na różu `#e11d48` (CTA) | 4,70:1 | AA |
| `#be123c` (róż tekstowy) na białym | 6,29:1 | AA z zapasem; wybrany wariant dla tekstu |
| slate-400 `#94a3b8` na białym (etykiety 9 px, podpis logo 7 px) | 2,56:1 | **nie spełnia** |
| slate-500 `#64748b` na białym (opisy) | 4,76:1 | AA, ale używany w 9–11 px |
| zielony `#22c55e` („Taryfa bazowa”, 8 px) | 2,28:1 | **nie spełnia** |
| zielony `#16a34a` (status REGON, 8 px) | 3,30:1 | **nie spełnia** |
| bursztyn `#d97706` („Ankieta”, 8 px) | 3,19:1 | **nie spełnia** |
| tryb ciemny: `#fb7185` na `#0f172a` | 6,63:1 | AA |
| tryb ciemny: `#93c5fd` na `#0f172a` | 9,90:1 | AAA |

Poza kontrastem: cele dotykowe (checkbox 13,6 px w `bp-app.js`, przyciski „Wszystkie” 8 px z paddingiem 2 px – ok. 16 px wysokości, „✕” 16 px); pismo 7 px (`.bp-hdr-logo-sub`), 8 px (`.hdr-sub`, `.emp-sub`, `.tier-lbl`, `.feat-banner`, `.btn-all`) i 9 px (etykiety, noty prawne); placeholdery ok. 3,0:1; `alt` logo poprawny w `nowy.html`, ale w `bp-nav.js` marka to tekst 7 px; „anti-inspect” w `bp-app.js` blokuje menu kontekstowe i skróty, z których korzystają użytkownicy czytników ekranu (`03-code-review-obecnego-kodu.md`). Na plus: `lang="pl"` wszędzie, `aria-live="polite"` na wynikach, `role="dialog"` + `aria-labelledby` w `indeksowt.html` (brak w `bp-app.js`).

### Co działa dobrze

- Model mentalny kalkulatora: zabiegi → parametry → wynik, z automatycznym doborem taryfy i jasnym wyjątkiem dla grupy 4 i zespołów powyżej 8 osób.
- Rzeczowe listy zabiegów w czterech grupach – gotowy materiał na ściągę i strony `/dla-kogo/<zawod>`.
- Uczciwa karta „Czego polisa nie obejmuje” obok zakresu i rozszerzeń.
- Wyróżnienie wariantu środkowego (200 000 zł) jako rekomendacji, duża cena, jednostka „zł/rok”.
- Noty prawne (art. 66 KC, kod OWU) obecne, choć w 9 px.
- `lang="pl"`, `theme-color`, `aria-live`, `for`/`id` na większości pól w `indeksowt.html`, istniejący tryb ciemny i `backdrop-filter` w headerze – kierunek „glass” jest już w DNA projektu.

### Trzy priorytetowe rekomendacje

1. **Jeden system zamiast pięciu stron**: tokeny → Tailwind 4 `@theme`, jedna nawigacja z sześcioma działającymi zakładkami, Montserrat + Inter, Lucide zamiast emoji.
2. **Kalkulator do hero i na kciuk**: glass widget z trzema krokami (grupa ryzyka, zespół, suma), wynik na panelu kryjącym, sticky CTA na mobile, zero zagnieżdżonych przewijań, zero blokady zoomu.
3. **Czytelność i kontrast jako reguła, nie wyjątek**: minimum 12/14/16 px, `#be123c` dla różu tekstowego, `#94a3b8` wyłącznie na obramowania, cele dotykowe ≥ 44 px, widoczny fokus wszędzie.

## Kierunek projektowy

Zasady:

1. **Zaufanie jak u ubezpieczyciela.** Każda liczba ma jednostkę, kontekst i źródło (sumę gwarancyjną objaśniamy jednym zdaniem; przy składce stoi „składka wg taryfy programu” i nota, że informacja na stronie nie stanowi oferty w rozumieniu art. 66 KC, a zakres ochrony określają OWU). Nic nie miga, nie odlicza, nie straszy.
2. **Lekkość jak w gabinecie.** Dużo światła, miękkie promienie (16–24 px), jeden gradient róż → granat tylko w hero, cienie długie i rozmyte, a nie „karty na karcie”.
3. **Jeden akcent, jedno działanie.** Róż `#e11d48` to wyłącznie wypełnienie głównego CTA – maksymalnie jeden taki przycisk w widoku (plus sticky CTA na mobile). Wszystko inne jest granatowe lub neutralne.
4. **Szkło to narzędzie, nie motyw.** Glass widget zwraca uwagę na kalkulator i header, nie dekoruje artykułów ani tabel.
5. **Treść najpierw.** Strona ma sens bez CSS i JS (semantyczny HTML, `<details>` w FAQ, formularze działające bez skryptu); ozdoby to progressive enhancement.

Moodboard słowny: recepcja dobrego gabinetu – biel, jasne drewno, matowe szkło w lustrze, jeden kwiat; dokument polisy wydrukowany na porządnym papierze z wyraźnymi tabelami; aplikacja bankowa, w której nic nie wyskakuje. Kolor: granat jak granatowa marynarka doradcy, róż jak jedna pieczątka na dokumencie. Ton zdjęć (jeśli w ogóle): naturalne światło, ręce przy pracy, bez stocku z uśmiechem do kamery; w v1 bez zdjęć – gradient i typografia.

Odniesienia do briefu: priorytety bezpieczeństwo → szybkość → responsywność → SEO oznaczają, że design nie może dokładać zależności (żadnych bibliotek animacji, konfetti, wykresów na starcie), musi mieścić się w budżecie wydajności z `02-architektura-i-bezpieczenstwo.md` i renderować się po stronie serwera (nagłówki, treść produktowa, FAQ widoczne bez JS – `04-seo-geo-i-schema.md`). Portal nie sprzedaje polis – więc CTA mówi „Poproś o ofertę”, nie „Kup”.

## Design system

Pełna lista tokenów v1 była w usuniętym pliku `snippets/glass-widget.css`; aktualne tokeny są w `design/v3/tokens-v3.css` (patrz `10-design-v3-old-money.md`). Poniżej założenia v1, zachowane dla porównania.

### Paleta (z kontrastami)

```css
:root {
  --color-navy: #2a3b69;        /* tekst, wypełnienia; 10.89:1 na białym */
  --color-navy-deep: #1e2f5a;   /* hover; 13.05:1 */
  --color-navy-soft: #eef2ff;   /* tło zaznaczenia */
  --color-rose: #e11d48;        /* WYŁĄCZNIE wypełnienie CTA; biały tekst 4.70:1 */
  --color-rose-deep: #be123c;   /* hover CTA oraz róż jako TEKST: 6.29:1 na białym */
  --color-rose-text: var(--color-rose-deep);
  --color-rose-soft: #fff1f2;   /* tła akcentowe – nigdy pod różowym tekstem #e11d48 */
  --color-text: #1e293b;        /* 14.63:1 */
  --color-text-2: #475569;      /* 7.58:1 – etykiety, opisy */
  --color-text-3: #64748b;      /* 4.76:1 – tylko ≥ 14 px, placeholdery */
  --color-border: #e2e8f0;  --color-border-strong: #cbd5e1;  /* #94a3b8 wyłącznie na obramowania/ikony dekoracyjne */
  --color-success: #15803d; --color-warning: #b45309; --color-error: #b91c1c; --color-info: #1d4ed8; /* 5.02 / 5.02 / 6.47 / 6.70 */
}
```

Reguła różu: `#e11d48` pozostaje kolorem marki i wypełnień (przyciski, pasek postępu, wskaźnik aktywnej zakładki). Jako tekst – nagłówek, link, cena, etykieta – zawsze `#be123c` na jasnym tle, a w trybie ciemnym `#fda4af` (9,44:1 na `#0f172a`). Zielone i bursztynowe statusy w 8 px z obecnego kodu zastępują `#15803d` / `#b45309` w 14 px.

Tryb ciemny: tło `#0f172a`, powierzchnia `#162032`, obramowanie `#334155`, tekst `#e2e8f0` (14,48:1), tekst drugorzędny `#cbd5e1`, trzeciorzędny `#94a3b8` (6,96:1). Granat jako akcent zmienia się w `#93c5fd` (9,90:1), bo `#2a3b69` na ciemnym tle znika. Wypełnienie CTA zostaje `#e11d48` z białym tekstem (4,70:1) – marka wygląda tak samo w obu trybach. Sterowanie: `prefers-color-scheme` jako domyślne, `data-theme="light|dark"` jako jawny wybór zapamiętany w `localStorage` (wyłącznie preferencja; `try/catch` wokół odczytu).

### Typografia

| Rola | Decyzja | Uzasadnienie |
|---|---|---|
| Nagłówki, CTA, liczby w kalkulatorze | **Montserrat** – font zmienny, oś wagi 600–800, podzbiór `latin-ext`, self-hosting przez `next/font` | Ciągłość z obecną marką; jeden plik zamiast pięciu wag ładowanych dziś z Google Fonts; `latin-ext` dla „ą, ę, ł, ś” |
| Tekst | **Inter** – font zmienny 400–600, `latin-ext`, self-hosting | Wyższa czytelność w 14–16 px niż szeroki Montserrat; cyfry tabelaryczne (`font-variant-numeric: tabular-nums`) dla składek i sum; stabilne metryki na Windows/Android/iOS, czego stos systemowy nie daje (Segoe UI / Roboto / SF różnią się szerokością o kilkanaście procent, co zmienia łamanie H1 i kart) |
| Fallback | `system-ui, -apple-system, "Segoe UI", Roboto, sans-serif` z `size-adjust` generowanym przez `next/font` | Brak skoku układu (CLS) podczas ładowania |

Budżet: dwa pliki woff2 [założenie: łącznie poniżej ~200 KB; do potwierdzenia po subsetowaniu]. Jeśli LCP na 4G przekroczy cel z `02-architektura-i-bezpieczenstwo.md`, Inter zastępuje stos systemowy – decyzja odwracalna, bo tokeny `--font-body` są jedynym miejscem zmiany.

Skala płynna (`clamp()`), min. 12 px:

```css
--text-xs: .75rem;                                    /* 12 px – przypisy prawne, nic mniejszego */
--text-sm: .875rem;                                   /* 14 px – UI, etykiety, nawigacja */
--text-base: clamp(1rem, .95rem + .25vw, 1.0625rem);  /* 16–17 px – treść */
--text-lg: clamp(1.125rem, 1.05rem + .4vw, 1.25rem);  /* lead */
--text-2xl: clamp(1.5rem, 1.25rem + 1.2vw, 2rem);     /* H2 */
--text-3xl: clamp(1.75rem, 1.4rem + 1.6vw, 2.5rem);   /* cena w wyniku */
--text-4xl: clamp(2rem, 1.5rem + 2.5vw, 3.25rem);     /* H1 hero: 32 → 52 px */
```

Interlinia 1,6 dla treści, 1,15–1,3 dla nagłówków; szerokość wiersza artykułu 60–70 znaków (`--container-sm: 42rem`). Wersaliki tylko dla etykiet typu „eyebrow” w 12 px z `letter-spacing: .06–.08em`.

### Odstępy, promienie, cienie, ruch

- Odstępy: baza 4 px (`--space-1` … `--space-20` = 4–80 px). Sekcje: 48 px na mobile, 64 px od 1024 px. Rytm w komponentach: 8/12/16/20/24.
- Promienie: 8 (pola, chipy), 12 (karty wyboru), 16 (karty, panele), 24 (glass widget, hero-karty), pełny (przyciski, zakładki).
- Cienie: `--shadow-sm/md/lg` o niskiej alfie (0,06–0,18) i długim rozmyciu; `--shadow-glass` 60 px rozmycia w granacie. W trybie ciemnym cienie czarne o wyższej alfie.
- Ruch: 120 ms (hover), 200 ms (stan), 320 ms (wejście panelu); easing `cubic-bezier(.2,.8,.2,1)`; animujemy tylko `opacity`, `transform`, `background-color`, `border-color` – nigdy `filter`/`backdrop-filter`. Globalna reguła `prefers-reduced-motion: reduce` zeruje czasy i `scroll-behavior`.
- Ikonografia: Lucide (`lucide-react`), 20 px w tekście i zakładkach, 24 px w kartach produktów, stroke 1,75; ikony dekoracyjne `aria-hidden="true"`, ikony samodzielne z `aria-label`. Emoji znikają z nawigacji, przełącznika trybu i stopki.

### Siatka i breakpointy

| Nazwa | Szerokość | Zastosowanie |
|---|---|---|
| base | 360 px | wszystko w jednej kolumnie, zakładki przewijane poziomo, sticky CTA |
| sm | 480 px | CTA w headerze obok logo; pola formularza w 2 kolumnach tam, gdzie krótkie (kod pocztowy + miasto) |
| md | 768 px | karty produktów 2 kolumny, stopka 3 kolumny, sticky CTA znika, header w jednym wierszu |
| lg | 1024 px | hero 2 kolumny (tekst + glass widget), karty produktów 3 kolumny, kalkulator z panelem wyniku z boku |
| xl | 1280 px | maksymalna szerokość treści `--container-lg` (80 rem); marginesy rosną |
| 2xl | 1536 px | bez zmian układu – większy odstęp zewnętrzny, hero nie rośnie powyżej 80 rem |

Kontenery: `--container-sm` 42 rem (artykuł), `--container-md` 60 rem (kalkulator pełnoekranowy, formularze, kontakt), `--container-lg` 80 rem (home, listy). Gutter 16 → 24 (md) → 32 px (lg), z `max(var(--gutter), env(safe-area-inset-left))`.

## Komponenty

| Komponent | Warianty | Stany | Uwagi |
|---|---|---|---|
| **Header z zakładkami produktów** | jasny/ciemny; z CTA (≥ 480 px) / bez | zakładka: default, hover, `aria-current="page"`, focus-visible; header: sticky z glass, fallback kryjący | 6 zakładek z realnymi URL (`/ubezpieczenia/…`), bez pozycji `#`; na mobile przewijane poziomo z gradientowym „fade” po prawej jako sygnałem, że jest więcej; linki drugorzędne (Baza wiedzy, O nas, Kontakt, Szkoda) w stopce i w arkuszu „Więcej” |
| **Glass widget kalkulatora** | hero (3 kroki), pełna strona `/kalkulator/oc` (kroki obok panelu wyniku od 1024 px) | krok aktywny/zrobiony/przyszły; wynik: pusty, wyliczony, wycena indywidualna (grupa 4 lub 9+ osób), błąd walidacji | specyfikacja w sekcji „Glass widget”; makieta: `#kalkulator` |
| **Karta wyboru (choice card)** | radio (grupa, zespół, suma), checkbox (ochrona prawna), ostrzegawcza (grupa 4) | default, hover, checked, focus-visible, disabled | input widoczny dla AT (`opacity:0` nad kartą), nigdy `display:none` |
| **Karta produktu** | standard; z ceną „od”; informacyjna (produkt bez cennika) | hover (cień, strzałka), focus-within | ikona Lucide, nazwa kanoniczna, ubezpieczyciel, 1–2 zdania faktów, link rozciągnięty na kartę przez `::after` |
| **Pasek zaufania ubezpieczycieli** | tekstowy (v1); z logotypami po uzyskaniu zgód | – | nazwy: ERGO Hestia, Colonnade, ENEL-MED, LUX MED, Fundacja Beauty Razem; `aria-label` sekcji |
| **Tabela porównawcza** | warianty sum (OC), sekcje Tax Protect, pakiety grupowe, abonamenty | sticky nagłówek kolumn; na < 768 px karty z `<dl>` zamiast tabeli lub przewijanie z `tabindex="0"` i `aria-label` | `<caption>` obowiązkowy; bez glass |
| **FAQ accordion** | natywny `<details>/<summary>`; wariant z jednym otwartym (opcjonalnie JS) | closed/open, hover, focus-visible | treść widoczna dla crawlera; `FAQPage` tylko dla faktycznie wyświetlanych pytań (`04-seo-geo-i-schema.md`) |
| **Formularz leadowy** | krótki (imię, e-mail, telefon, zgoda), wniosek OC (plus NIP/REGON, liczba osób, grupa), kontakt, szkoda | pole: default, focus, invalid (po `blur`), valid, disabled; formularz: wysyłanie, sukces, błąd serwera, limit (Turnstile) | walidacja inline po opuszczeniu pola, komunikaty PL pod polem z `aria-describedby` i `aria-invalid`; `inputmode`/`autocomplete`; `font-size ≥ 16px` na iOS; przycisk wysyłki 44 px, pełna szerokość na mobile |
| **Sticky CTA mobile** | 2 akcje (Oblicz składkę / Kontakt); 1 akcja na stronach produktów (Poproś o ofertę) | widoczny, ukryty (gdy jakikolwiek fragment kalkulatora lub formularza jest w widoku – `IntersectionObserver`, `threshold: 0`) | `position: fixed`, `padding-bottom: env(safe-area-inset-bottom)`, glass z fallbackiem (`.glass-bar` w snippets); `body` dostaje dolny padding; próg 0 gwarantuje najwyżej 2 tafle naraz (header + widget) |
| **Banner zgód** | minimalny (tylko niezbędne – bez bannera), pełny (gdy analityka marketingowa) | zwinięty/rozwinięty | równorzędne przyciski „Odrzuć” i „Zaakceptuj” tej samej wagi, brak ciemnych wzorców (bez „X” = zgoda, bez pre-zaznaczonych kategorii), link do `/rodo`; dolny pasek, nie modal |
| **Toast** | success, error, info | wchodzi/znika po 6 s, pauza na hover/fokus | `role="status"` (info/success) lub `role="alert"` (error); nie jedyna forma komunikatu – formularz pokazuje też wynik inline |
| **Skeleton** | wiersz tekstu, karta, cena w wyniku | – | tylko dla treści ładowanej po stronie klienta (wynik API wyceny); bez animacji shimmer przy reduced-motion |
| **Lista dokumentów OWU** | lista; grupowana per produkt | hover, focus | wiersz: nazwa dokumentu, ubezpieczyciel, kod OWU, data obowiązywania, rozmiar i format („PDF · 1,2 MB”), link `download` |
| **Przycisk** | cta (róż), primary (granat), ghost, link | hover, active, focus-visible, disabled, loading | tekst 14 px, wysokość 44 px, pełny promień |
| **Powiadomienie (notice)** | info, warning, error, success | – | tło semantyczne + ikona + tekst `--color-text`; nie polegamy na samym kolorze |
| **Okruszki (breadcrumbs)** | – | – | `nav aria-label="Okruszki"`, `BreadcrumbList` wg `04-seo-geo-i-schema.md` |

## Glass widget – specyfikacja

**Anatomia:** tafla (`.glass`) z obramowaniem 1 px, wewnętrznym podświetleniem górnej krawędzi i długim cieniem; nagłówek (`.glass__header`: tytuł, badge „Cennik programu”, stepper); ciało (`.glass__body`: aktywny krok z kartami wyboru); panel wyniku (`.glass__panel`: tło kryjące 92 %, cena, metadane, porównanie sum, CTA, nota prawna).

```css
.glass {
  background: var(--glass-bg);                 /* rgba(255,255,255,.55) / ciemny: rgba(15,23,42,.55) */
  border: 1px solid var(--glass-border);       /* rgba(255,255,255,.35) */
  border-radius: var(--radius-xl);             /* 24 px */
  box-shadow: inset 0 1px 0 var(--glass-highlight), var(--shadow-glass);
  -webkit-backdrop-filter: blur(16px) saturate(160%);   /* Safari */
  backdrop-filter: blur(16px) saturate(160%);           /* zakres 14–18 px */
  contain: paint;
  isolation: isolate;
}
.glass__panel { background: var(--glass-panel); }        /* rgba(255,255,255,.92) */

@supports not ((backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px))) {
  .glass { background: var(--color-surface); border-color: var(--color-border); }
}
@media (prefers-reduced-transparency: reduce), (prefers-contrast: more) {
  .glass { background: var(--color-surface); backdrop-filter: none; -webkit-backdrop-filter: none; }
}
```

**Reguła kontrastu.** Szkło nie ma stałego tła, więc kontrast liczymy dla najgorszego przypadku – najciemniejszego fragmentu gradientu pod taflą. Dla tafli 55 % bieli nad granatem `#2a3b69` tło efektywne to `#9fa7bc`: tekst `#1e293b` daje 6,08:1 (OK), granat `#2a3b69` 4,53:1 (na granicy), slate-500 `#64748b` nad różowym `#fecdd3` tylko 4,08:1 (nie). Stąd zasada: na tafli dozwolone są wyłącznie `--color-text` i `--color-navy` w ≥ 14 px; wszystko drugorzędne (`--color-text-2/3`, ceny do porównania, nota prawna) wyłącznie na `.glass__panel`, gdzie przy kryciu 92 % nad granatem `#475569` daje 6,59:1, a `#be123c` 5,47:1. W trybie ciemnym tafla 55 % `#0f172a` nad najjaśniejszym `#3b4f8a` daje dla `#cbd5e1` 8,70:1 – bezpiecznie.

**Wydajność.** `backdrop-filter` wymusza osobną warstwę kompozycji i próbkowanie tła przy każdym przewinięciu. Zasady: (1) maksymalnie dwa elementy ze szkłem w widoku naraz – sticky header i widget hero; sticky CTA na mobile pojawia się, gdy widget zniknie z ekranu; (2) szkło tylko above the fold – nigdy w stopce, tabelach, artykułach; (3) nie animujemy `blur` ani `backdrop-filter` – wejście panelu to `opacity`/`transform`; (4) bez `will-change` na dużych obszarach; (5) wewnątrz tafli nie ma własnego przewijania (listy zabiegów idą do ściągi poniżej); (6) `contain: paint` i `isolation: isolate`, żeby repaint nie wychodził poza widget; (7) na małych ekranach z dotykiem blur 12 px; (8) test akceptacyjny na Androidzie średniej klasy [założenie: urządzenie klasy 2022–2023, Chrome, 4× throttling CPU w DevTools] – przewijanie hero bez spadków poniżej 50 fps, INP poniżej 200 ms przy zmianie kroku; (9) tło hero to `radial-gradient`, nie `filter: blur()` na dużych pseudoelementach – element z filtrem to osobna warstwa kompozycji, czyli ten sam rodzaj kosztu co kolejna tafla (makieta używa gradientów).

**Gdzie stosować:** kalkulator w hero (home i `/ubezpieczenia/oc-beauty`), sticky header, karta wyniku na `/kalkulator/oc`, sticky CTA mobile. **Gdzie nie:** długie formularze (wniosek, kontakt, szkoda – pełne tło), tabele porównawcze, artykuły bazy wiedzy, listy dokumentów, modale/arkusze (tło przyciemnione, panel kryjący).

**Tailwind 4.** Tokeny trafiają do `@theme`, a szkło to jedna utility, więc w JSX piszemy `className="glass p-5 lg:p-6"`:

```css
@import "tailwindcss";
@theme {
  --color-navy: #2a3b69; --color-rose: #e11d48; --color-rose-deep: #be123c;
  --radius-xl: 24px; --blur-glass: 16px;
  --shadow-glass: 0 24px 60px -24px rgb(42 59 105 / 0.35);
  --breakpoint-sm: 30rem; --breakpoint-md: 48rem; --breakpoint-lg: 64rem; --breakpoint-xl: 80rem; --breakpoint-2xl: 96rem;
}
@custom-variant dark (&:where([data-theme="dark"], [data-theme="dark"] *));
@utility glass {
  background: var(--glass-bg); border: 1px solid var(--glass-border); border-radius: var(--radius-xl);
  box-shadow: inset 0 1px 0 var(--glass-highlight), var(--shadow-glass);
  -webkit-backdrop-filter: blur(var(--blur-glass)) saturate(160%);
  backdrop-filter: blur(var(--blur-glass)) saturate(160%);
  contain: paint;
  @supports not (backdrop-filter: blur(1px)) { background: var(--color-surface); }
  @media (prefers-reduced-transparency: reduce), (prefers-contrast: more) { background: var(--color-surface); backdrop-filter: none; }
}
```

## Responsywność

Mobile-first: style bazowe dla 360 px, media queries tylko `min-width`. Żaden widok nie może generować poziomego przewijania (test automatyczny: `scrollWidth === innerWidth` przy 360/480/768/1024/1280/1536 – makieta przechodzi).

### Zasady per breakpoint

| Szablon | 360 px | 768 px | 1280 px |
|---|---|---|---|
| Home | header 2 wiersze (logo + przełącznik, zakładki przewijane); hero: tekst, potem glass widget; produkty 1 kolumna; sticky CTA | header 1 wiersz; hero nadal w jednej kolumnie (widget pod tekstem, max 36 rem); produkty 2 kolumny; stopka 3 kolumny | hero 2 kolumny (tekst 1,05 fr / widget 0,95 fr); produkty 3 kolumny; kontener 80 rem |
| Produkt | hero z ceną „od” i CTA; zakres jako akordeon; tabela sum jako karty | tabela sum jako tabela; zakres w 2 kolumnach (zakres / wyłączenia) | sidebar z glass-kartą „Poproś o ofertę” sticky po prawej, treść 2/3 |
| Kalkulator `/kalkulator/oc` | jeden krok na ekran, stepper na górze, wynik pod krokami (pełny panel), sticky CTA | kroki w kontenerze 60 rem, wynik pod spodem | kroki po lewej (3/5), panel wyniku sticky po prawej (2/5) |
| Artykuł | 42 rem, 16–17 px, obrazy pełnej szerokości, spis treści jako `<details>` | spis treści nad treścią | spis treści sticky po lewej, treść 42 rem, box „Policz składkę” po prawej |

### Wireframe home

```text
360 px                      768 px                              1280 px
┌──────────────────────┐    ┌──────────────────────────────┐    ┌──────────────────────────────────────────────┐
│ BeautyPolisa   (☾)   │    │ BeautyPolisa  (☾) [Oblicz]   │    │ BeautyPolisa          (☾) [Oblicz składkę]    │
│ [OC][Tax][Utrata]… → │    │ [OC][Tax][Utrata][NNW][Gr][Op]│    │ [OC][Tax][Utrata][NNW][Grupowe][Opieka]       │
├──────────────────────┤    ├──────────────────────────────┤    ├───────────────────────┬──────────────────────┤
│ eyebrow              │    │ eyebrow                      │    │ eyebrow               │ ┌──────────────────┐ │
│ H1 Ochrona gabinetu… │    │ H1 Ochrona gabinetu…         │    │ H1 Ochrona gabinetu   │ │ GLASS: Kalkulator│ │
│ lead                 │    │ lead                         │    │ i zespołu…            │ │ ▮▮▮ ░░░ ░░░      │ │
│ ✓ fakt ✓ fakt ✓ fakt │    │ ✓ fakt ✓ fakt ✓ fakt         │    │ lead                  │ │ 1. Zabiegi       │ │
│ [Oblicz] [Zakres]    │    │ [Oblicz składkę] [Zakres]    │    │ ✓ ✓ ✓                 │ │ ○ Grupa 1        │ │
│ ┌──────────────────┐ │    │ ┌──────────────────────────┐ │    │ [Oblicz] [Zakres]     │ │ ○ Grupa 2 …      │ │
│ │ GLASS: Kalkulator│ │    │ │ GLASS: Kalkulator (36rem)│ │    │                       │ │ [Dalej]          │ │
│ │ ▮▮▮ ░░░ ░░░      │ │    │ │ …                        │ │    │                       │ │ ┌──panel wyniku┐ │ │
│ │ 1. Zabiegi …     │ │    │ └──────────────────────────┘ │    │                       │ │ │ 742 zł / rok │ │ │
│ │ [Dalej]          │ │    ├──────────────────────────────┤    │                       │ │ │[Poproś o of.]│ │ │
│ │ ┌─panel wyniku─┐ │ │    │ ZAUFANIE  ERGO Hestia · …    │    │                       │ └─┴──────────────┴─┘ │
│ └─┴──────────────┴─┘ │    ├──────────────────────────────┤    ├───────────────────────┴──────────────────────┤
├──────────────────────┤    │ ┌───────────┐ ┌───────────┐  │    │ ZAUFANIE  ERGO Hestia · Colonnade · ENEL-MED… │
│ ZAUFANIE ERGO Hestia…│    │ │ Produkt 1 │ │ Produkt 2 │  │    ├──────────────────────────────────────────────┤
├──────────────────────┤    │ └───────────┘ └───────────┘  │    │ ┌─────────┐ ┌─────────┐ ┌─────────┐          │
│ ┌──────────────────┐ │    │ ┌───────────┐ ┌───────────┐  │    │ │Produkt 1│ │Produkt 2│ │Produkt 3│          │
│ │ Produkt 1        │ │    │ │ Produkt 3 │ │ Produkt 4 │  │    │ └─────────┘ └─────────┘ └─────────┘          │
│ └──────────────────┘ │    │ └───────────┘ └───────────┘  │    │ ┌─────────┐ ┌─────────┐ ┌─────────┐          │
│ … ×6                 │    │ … ×6                         │    │ │Produkt 4│ │Produkt 5│ │Produkt 6│          │
├──────────────────────┤    ├──────────────────────────────┤    │ └─────────┘ └─────────┘ └─────────┘          │
│ FAQ ▸ ▸ ▸ ▸ ▸        │    │ FAQ ▸ ▸ ▸ ▸ ▸                │    ├──────────────────────────────────────────────┤
├──────────────────────┤    ├──────────────────────────────┤    │ FAQ ▸ ▸ ▸ ▸ ▸                                 │
│ stopka (1 kol.)      │    │ stopka (3 kol.)              │    ├──────────────────────────────────────────────┤
├──────────────────────┤    └──────────────────────────────┘    │ stopka (3 kol.) · noty prawne 12 px           │
│ [Oblicz] [Kontakt] ⌂ │  ← sticky CTA + safe-area               └──────────────────────────────────────────────┘
└──────────────────────┘
```

### Wireframe kalkulatora `/kalkulator/oc`

```text
360 px                      768 px                              1280 px
┌──────────────────────┐    ┌──────────────────────────────┐    ┌───────────────────────────┬──────────────────┐
│ header               │    │ header                       │    │ header                                       │
├──────────────────────┤    ├──────────────────────────────┤    ├───────────────────────────┬──────────────────┤
│ Okruszki › Kalkulator│    │ Okruszki › Kalkulator OC     │    │ Okruszki › Kalkulator OC  │                  │
│ H1 Kalkulator OC     │    │ H1 Kalkulator OC beauty      │    │ H1 Kalkulator OC beauty   │ ┌─GLASS wynik──┐ │
│ ▮▮▮ ░░░ ░░░  Krok 1/3│    │ ▮▮▮ ░░░ ░░░  Krok 1/3        │    │ ▮▮▮ ░░░ ░░░  Krok 1/3     │ │ (sticky)     │ │
│ 1. Jakie zabiegi?    │    │ 1. Jakie zabiegi?            │    │ 1. Jakie zabiegi?         │ │ Składka rocz.│ │
│ ○ Grupa 1 ……………      │    │ ○ Grupa 1 ……   ○ Grupa 2 …… │    │ ○ Grupa 1 ……  ○ Grupa 2 …│ │ 742 zł / rok │ │
│ ○ Grupa 2 ……………      │    │ ○ Grupa 3 ……   ○ Grupa 4 !! │    │ ○ Grupa 3 ……  ○ Grupa 4 !│ │ 100k 200k 300k│ │
│ ○ Grupa 3 ……………      │    │ ▸ Które zabiegi należą…?     │    │ ▸ Które zabiegi należą…?  │ │ [Poproś o of.]│ │
│ ○ Grupa 4 !! indyw.  │    │            [Dalej: zespół]   │    │            [Dalej: zespół]│ │ nota prawna  │ │
│ ▸ Które zabiegi…?    │    ├──────────────────────────────┤    │                           │ └──────────────┘ │
│        [Dalej]       │    │ ┌──panel wyniku (pełny)────┐ │    │ Zakres ochrony (3 kolumny)│                  │
├──────────────────────┤    │ │ 742 zł / rok  [Poproś]   │ │    │ FAQ kalkulatora           │                  │
│ ┌─panel wyniku─────┐ │    │ └──────────────────────────┘ │    ├───────────────────────────┴──────────────────┤
│ │ 742 zł / rok     │ │    │ Zakres ochrony · FAQ         │    │ stopka                                       │
│ │ [Poproś o ofertę]│ │    └──────────────────────────────┘    └──────────────────────────────────────────────┘
│ └──────────────────┘ │
│ Zakres ochrony · FAQ │
├──────────────────────┤
│ [Poproś o ofertę]  ⌂ │  ← sticky CTA, ukryty gdy panel wyniku w widoku
└──────────────────────┘
```

### Nawigacja mobilna

Decyzja: **zakładki przewijane poziomo** dla sześciu produktów (to główne wejścia i cele SEO), a nie hamburger. Powody: zakładki pokazują ofertę bez kliknięcia, są dostępne jako zwykłe linki i mierzalne per produkt; hamburger ukrywa 100 % nawigacji za jednym gestem. Mechanika: `overflow-x: auto`, `scroll-snap-type: x proximity`, brak widocznego scrollbara, gradientowy „fade” po prawej jako afordancja, aktywna zakładka przewinięta do widoku po załadowaniu (`scrollIntoView({ inline: "nearest" })`). Linki drugorzędne: przycisk „Więcej” otwierający arkusz dolny (`<dialog>`) z Bazą wiedzy, Dla kogo, O nas, Kontakt, Szkoda, Dokumenty – oraz zawsze w stopce.

### Reszta zasad

- Cele dotykowe: ≥ 44 × 44 px dla wszystkich kontrolek (WCAG 2.2 wymaga 24 × 24, przyjmujemy 44 jako standard; odstęp ≥ 8 px między sąsiednimi). W makiecie: zakładki, przyciski, karty wyboru, `summary` FAQ – wszystkie ≥ 44 px (sprawdzone skryptem).
- Zoom: nigdy `maximum-scale`/`user-scalable=no`; pola formularzy ≥ 16 px, żeby iOS nie przybliżał.
- Formularze na mobile: jedna kolumna, etykieta nad polem, `inputmode="numeric"` (NIP, REGON, kod), `inputmode="tel"`, `autocomplete` (`name`, `email`, `tel`, `organization`, `postal-code`), `enterkeyhint="next|send"`, przycisk wysyłki pełnej szerokości i sticky nad klawiaturą, bez modali – formularz leadowy to strona lub arkusz pełnoekranowy.
- Obrazy: v1 bez zdjęć w hero (gradient CSS, zero LCP-obrazów). Tam, gdzie obrazy są potrzebne (artykuły, „O nas”): `next/image` z `sizes`, AVIF/WebP, `aspect-ratio` w CSS przeciw CLS, `loading="lazy"` poza pierwszym ekranem, `alt` opisowy lub pusty dla dekoracji.
- Bezpieczne obszary: `viewport-fit=cover` + `env(safe-area-inset-*)` w headerze (góra), sticky CTA (dół) i gutterach (boki); `body` z dolnym paddingiem równym wysokości sticky CTA.
- Orientacja i wysokość: hero nie używa `100vh` (`svh`/naturalna wysokość treści); testy przy 360 × 640 w poziomie.

## Dostępność (WCAG 2.2 AA)

1. `<html lang="pl">`; fragmenty w innym języku (np. „Global Doctors”) bez zmiany `lang`, nazwy własne nie wymagają oznaczania.
2. Skip link „Przejdź do treści” jako pierwszy element, widoczny po fokusie; `main` z `id="tresc"` i `tabindex="-1"`.
3. Jedna definicja fokusu dla wszystkiego (`:focus-visible` → podwójny pierścień: tło + granat, 3 + 3 px), nigdy `outline: none` bez zamiennika; kontrast pierścienia ≥ 3:1 na każdym tle.
4. Kontrast tekstu ≥ 4,5:1 (normalny) i ≥ 3:1 (duży ≥ 24 px lub 18,7 px pogrubiony); UI i ikony informacyjne ≥ 3:1 – lista par w sekcji „Design system”.
5. Minimalny rozmiar pisma 12 px (przypisy), 14 px (UI), 16 px (treść); tekst skalowalny do 200 % bez utraty treści, reflow przy 320 px CSS.
6. Cele dotykowe ≥ 44 × 44 px (2.5.8 wymaga 24 × 24); fokus nie może być zasłonięty przez sticky header/CTA (2.4.11) – `scroll-margin-top` na celach kotwic i fokusu.
7. Nagłówki w porządku (jeden H1, H2 sekcje, H3 karty); `aria-labelledby` na sekcjach.
8. Formularze: etykieta widoczna i powiązana (`for`/`id`), pomoc przez `aria-describedby`, błąd tekstowy + `aria-invalid="true"`, lista błędów nad formularzem z `role="alert"` po nieudanej wysyłce, fokus na pierwsze błędne pole; bez walidacji wyłącznie kolorem.
9. Kroki kalkulatora: `<fieldset>`/`<legend>` dla każdej grupy opcji; stepper jako `<ol>` z `aria-current="step"` i tekstem „Krok 1 z 3” dla czytników; zmiana kroku przenosi fokus na `legend`.
10. Wynik kalkulatora w regionie `aria-live="polite" aria-atomic="true"` – ogłaszany po zmianie, bez przerywania; komunikat o wycenie indywidualnej jest tekstem, nie tylko kolorem.
11. Akordeon FAQ: natywny `<details>`; jeśli komponent własny – `button[aria-expanded][aria-controls]`, panel `role="region"` z `aria-labelledby`.
12. Modale/arkusze: `<dialog>` + `showModal()` (pułapka fokusu, Esc, `inert` dla tła), fokus na pierwszy element, powrót fokusu do wyzwalacza; tytuł przez `aria-labelledby`.
13. Zakładki produktów to linki (`nav aria-label="Produkty"`), nie `role="tablist"` – prowadzą do stron, nie przełączają paneli.
14. Ikony dekoracyjne `aria-hidden="true"`; przycisk z samą ikoną ma `aria-label` (przełącznik trybu: „Włącz/Wyłącz tryb ciemny” + `aria-pressed`).
15. Ruch: `prefers-reduced-motion` respektowany globalnie; brak autoodtwarzania wideo/animacji dłuższych niż 5 s; bez parallaxu.
16. Przezroczystość: `prefers-reduced-transparency` i `prefers-contrast: more` → tła kryjące; `forced-colors: active` → obramowania systemowe (`border: 1px solid CanvasText` dla kart wyboru).
17. Tabele: `<caption>`, `<th scope>`; na mobile alternatywa kartowa lub przewijanie z klawiatury.
18. Dokumenty PDF (OWU): nazwa, format i rozmiar w tekście linku lub obok; PDF-y od ubezpieczycieli nie podlegają naszej kontroli – w `/dokumenty` nota, że na życzenie przekażemy treść w formie dostępnej [założenie: ścieżka kontaktu przez formularz].
19. Test z czytnikiem przed wdrożeniem: NVDA + Firefox (Windows), VoiceOver + Safari (iOS) – scenariusze: przejście kalkulatora klawiaturą, wysłanie formularza z błędem, nawigacja zakładkami, otwarcie i zamknięcie arkusza „Więcej”. Automatycznie: axe-core w Playwright na każdy szablon, Lighthouse a11y ≥ 95.
20. Treść: język prosty, skróty rozwijane przy pierwszym użyciu („OWU – ogólne warunki ubezpieczenia”), liczby z jednostkami i odstępem tysięcy (nierozdzielająca spacja).

## Mikrocopy i ton

Zasady: po polsku, bezpośrednio, w drugiej osobie („wybierasz”, „policz”), ekspercko, ale ciepło; bez straszenia („zanim będzie za późno”) i bez wykrzykników; liczby zawsze z kontekstem („od 400 zł rocznie przy sumie 100 000 zł”), bez „już od”; żadnych obietnic prawnych („pełna ochrona”, „bez wyłączeń”) – zamiast tego link do OWU; nazwy produktów w brzmieniu kanonicznym; forma żeńska i męska tam, gdzie to naturalne („właścicielka lub właściciel”), bez podkreśleń i nawiasów w CTA. Skład: po jednoliterowych spójnikach i przyimkach („i”, „w”, „z”, „o”) twarda spacja (`&nbsp;`), żeby nie zostawały na końcu wiersza – w nagłówkach ręcznie, w treści z CMS filtrem przy renderowaniu; kwoty formatowane przez `Intl.NumberFormat("pl-PL")` („1280 zł”, „12 800 zł”, odstęp tysięcy od 5 cyfr).

| Miejsce | Źle | Dobrze |
|---|---|---|
| CTA główne | „Rozpocznij Kalkulację” (wersaliki, rzeczownik) | „Oblicz składkę OC” |
| CTA wyniku | „Wybieram wariant” (co dalej?) | „Poproś o ofertę na 200 000 zł” |
| CTA indywidualne | „Odbierz Ankietę na e-mail” | „Umów rozmowę z doradcą” |
| Nagłówek hero | „Ekskluzywny Program Ochrony dla Branży Beauty” | „Ochrona gabinetu i zespołu, bez niespodzianek w OWU” |
| Etykieta pola | „NIP Firmy (Weryfikacja API)” | „NIP firmy” + pomoc „10 cyfr, bez myślników” |
| Odznaka | „Rekomendacja Ekspertów” | „Najczęściej wybierana” |
| Grupa 4 | „Wymagana Indywidualna Ocena Ryzyka” (wersaliki) | „Zabiegi z grupy 4 wymagają indywidualnej oceny ryzyka przez ERGO Hestię. Przygotujemy ankietę i ofertę szytą na miarę.” |

Komunikaty błędów (pod polem, 14 px, `--color-error`): „Podaj adres e-mail w formacie nazwa@domena.pl”; „Numer telefonu powinien mieć 9 cyfr”; „NIP ma 10 cyfr – sprawdź, czy nie brakuje jednej”; „Zaznacz zgodę na kontakt, żebyśmy mogli odpowiedzieć”; błąd serwera: „Nie udało się wysłać formularza. Spróbuj ponownie za chwilę lub napisz na adres z sekcji Kontakt.”; limit: „Zbyt wiele prób. Odczekaj minutę i spróbuj ponownie.” Sukces: „Dziękujemy. Doradca odezwie się w następnym dniu roboczym.” [założenie: SLA do potwierdzenia].

Stany puste: wynik przed wyborem – „Wybierz grupę zabiegów w kroku 1, aby zobaczyć składkę”; baza wiedzy bez wyników – „Nie mamy jeszcze artykułu na ten temat. Zobacz pytania w FAQ lub napisz do nas”; lista dokumentów produktu bez OWU – „Dokumenty dla tego produktu są w przygotowaniu – poproś o nie w formularzu”.

## Szablony stron

| Szablon | Kolejność sekcji | Cel każdej sekcji |
|---|---|---|
| **Home** `/` | header → hero (H1, lead, 3 fakty, CTA) + glass widget → pasek zaufania → 6 produktów → „Jak to działa” (3 kroki: policz, poproś o ofertę, doradca domyka) → baza wiedzy (3 najnowsze) → FAQ → stopka | hero: jedno działanie; zaufanie: nazwy ubezpieczycieli; produkty: wejścia SEO; FAQ: pytania z SERP (`05-strategia-tresci.md`) |
| **Produkt** `/ubezpieczenia/<slug>` | okruszki → hero (nazwa, ubezpieczyciel, cena „od” z kontekstem, CTA) → dla kogo (chipy zawodów → `/dla-kogo/…`) → zakres / rozszerzenia / wyłączenia (3 kolumny, bez szkła) → warianty (tabela sum) → jak kupić (kroki) → dokumenty OWU → FAQ produktu → formularz „Poproś o ofertę” → produkty powiązane | strona musi odpowiadać na „co, dla kogo, ile, czego nie obejmuje, jak kupić” bez przewijania w nieskończoność; `Service` + `FAQPage` wg `04-seo-geo-i-schema.md` |
| **Kalkulator** `/kalkulator/oc` | okruszki → H1 + stepper → krok 1–3 → panel wyniku (sticky od 1024 px) → ściąga zabiegów per grupa → zakres ochrony → FAQ kalkulatora | jedno pytanie na ekran; wynik zawsze w zasięgu; ściąga odpowiada „do której grupy należy mój zabieg” |
| **Artykuł** `/baza-wiedzy/<slug>` | okruszki → H1, autor/recenzent, data aktualizacji, czas czytania → TL;DR (3 punkty) → spis treści → treść 42 rem z H2/H3, tabelami, cytatami z OWU → box „Policz składkę” po pierwszej trzeciej → źródła → FAQ artykułu → powiązane → CTA | E-E-A-T z `05-strategia-tresci.md`; bez glass; obrazy tylko merytoryczne |
| **Landing lead magnetu** `/baza-wiedzy/<slug>` z formularzem lub `/dla-kogo/<zawod>` | hero (co dostajesz, dla kogo, 3 punkty) → podgląd materiału (spis treści, 1 strona) → formularz (e-mail + zgoda, Turnstile) → kto za tym stoi (Aura Consulting, Beauty Razem) → FAQ → stopka | jeden formularz, jedna obietnica; po wysyłce strona potwierdzenia z linkiem do kalkulatora |
| **Kontakt / Szkoda** `/kontakt`, `/szkoda` | H1 → wybór tematu (oferta / polisa / szkoda / inne) → formularz dostosowany do tematu → dane firmy i godziny [do uzupełnienia] → „co dalej” (kroki po zgłoszeniu) → RODO (skrót + link) | szkoda: lista potrzebnych informacji przed formularzem (numer polisy, data zdarzenia, opis, dokumenty), bez presji czasowej; `HowTo` wg `04-seo-geo-i-schema.md` |

## Przekazanie do developmentu

**Tokeny.** `design/v3/tokens-v3.css` (zastępuje `design/tokens-v2.css` i `snippets/glass-widget.css` z v1) przepisujemy do `app/globals.css` jako `@theme` (kolory, fonty, promienie, cienie, breakpointy, blur) oraz zwykłe `:root` dla wartości, których Tailwind nie mapuje na utility (`--glass-*`, `--focus-ring`, `--tap-min`). Tryb ciemny: `@custom-variant dark` oparty na `[data-theme="dark"]`, a preferencja systemowa obsłużona skryptem inline w `<head>` (`layout.tsx`), który ustawia `data-theme` przed hydracją – bez błysku i bez `!important`. Fonty przez `next/font/google` z `subsets: ["latin", "latin-ext"]`, `display: "swap"`, zmienne `--font-heading`/`--font-body`. Snippet zawiera też klasy bazowe `.glass-header`, `.glass-bar` (sticky CTA), `.stepper`, pierścień fokusu, `[id] { scroll-margin-top }` i blok `forced-colors` – w Next.js stają się komponentami `Header`, `StickyCta`, `Stepper`.

**Nazewnictwo.** Komponenty w `components/`: `Header`, `ProductTabs`, `ThemeToggle`, `Hero`, `GlassWidget`, `CalculatorOC` (`Stepper`, `ChoiceCard`, `ResultPanel`), `TrustBar`, `ProductCard`, `ComparisonTable`, `FaqAccordion`, `LeadForm` (`Field`, `FieldError`), `StickyCta`, `ConsentBanner`, `Toast`, `Skeleton`, `DocumentList`, `Breadcrumbs`, `Button`, `Notice`. Pliki `PascalCase.tsx`, warianty przez props (`variant="cta" | "primary" | "ghost"`), stany przez atrybuty danych (`data-state="open"`), nie przez klasy modyfikatorów. Logika wyceny OC w `lib/pricing/oc.ts` – czysta funkcja `quoteOC({ group, team, sumIndex, legal })` z testami jednostkowymi na przypadki z cennika (400/500/650, 650/790/950, 850/980/1250, +92, ×1,25 dla zespołu 6–8 osób, grupa 4 i 9+ → indywidualna); stawki i mnożnik zespołu to sztywna taryfa programu, trzymana w wersjonowanej konfiguracji cennika z datą obowiązywania, żeby zmiana taryfy w czasie zostawiała ślad.

**Storybook (opcjonalnie).** Dla zespołu 1–2 osób wystarczy trasa `/dev/styleguide` dostępna tylko w środowisku deweloperskim, renderująca każdy komponent w stanach i w obu trybach. Storybook ma sens, jeśli projekt będzie rozwijany dłużej niż pół roku lub przez więcej osób – wtedy stories jako źródło testów wizualnych.

**Kryteria akceptacji wizualnej** (bramka w CI, `02-architektura-i-bezpieczenstwo.md`):

1. Brak poziomego przewijania przy 360/480/768/1024/1280/1536 px (Playwright: `scrollWidth === innerWidth`).
2. Zrzuty porównawcze (Playwright) dla home, produktu, kalkulatora, artykułu w obu trybach i trzech szerokościach; różnice > 0,1 % wymagają akceptacji.
3. axe-core: 0 błędów „serious/critical”; Lighthouse: Accessibility ≥ 95, Best Practices ≥ 95; CLS < 0,1; INP < 200 ms na profilu „mid-tier mobile”.
4. Żaden tekst poniżej 12 px (audyt computed styles – skrypt z makiety); UI ≥ 14 px; treść ≥ 16 px.
5. Kontrast: automatyczny test par z tabeli tokenów; każda nowa para kolorów dopisana do testu.
6. Wszystkie interaktywne elementy ≥ 44 × 44 px i widoczny `:focus-visible`.
7. Glass: maksymalnie 2 elementy z `backdrop-filter` w widoku; `prefers-reduced-transparency`, `prefers-contrast: more`, brak `backdrop-filter` → tła kryjące (testy z `emulateMedia`).
8. Brak emoji w nawigacji, przyciskach i ikonach; ikony wyłącznie Lucide.
9. Brak `maximum-scale`, `user-scalable=no`, `outline: none` bez zamiennika, `display: none` na inputach radio/checkbox (lint: reguły ESLint/Stylelint).
10. Strona renderuje treść (H1, opisy, FAQ, ceny „od”) bez JavaScript (test `javaScriptEnabled: false`).

**Weryfikacja makiety (wykonana 8.11.2026, Playwright 1.63 + Chrome).** Przy 360/480/768/1024/1280/1536 px w trybie jasnym i ciemnym: `scrollWidth === innerWidth` (brak poziomego przewijania), 0 błędów konsoli, żaden tekst poniżej 12 px, wszystkie cele dotykowe ≥ 44 × 44 px (linki w stopce rozciągnięte na szerokość kolumny), H1 skaluje się 33 → 52 px. Kalkulator zwraca wartości z cennika: grupa 1 / 1–5 os. / 100 000 zł = 400 zł; grupa 2 / 1–5 / 200 000 zł = 790 zł; grupa 2 / 6–8 / 300 000 zł + ochrona prawna = 1280 zł (950 × 1,25 + 92); grupa 3 / 1–5 / 300 000 zł + ochrona = 1342 zł; grupa 4 oraz 9+ osób → „Wycena indywidualna” i CTA „Umów rozmowę z doradcą”; „Dalej” bez wybranej grupy zatrzymuje się z komunikatem i fokusem na pierwszej opcji. Przełącznik trybu zapisuje `bp-theme`, ustawia `aria-pressed` i `theme-color`. `prefers-contrast: more` → `backdrop-filter: none` i tło kryjące na tafli i headerze; `forced-colors: active` → obramowania 1 px na kartach; `prefers-reduced-motion` → przejścia 0,01 ms; bez JavaScriptu widoczne są wszystkie trzy kroki, nawigacja kroków ukryta, `<noscript>` kieruje do formularza. Kotwica `#kalkulator` zatrzymuje się 15 px pod sticky headerem; sticky CTA znika, gdy widget jest w widoku. Klawiatura: kolejność fokusu skip link → logo → przełącznik → CTA → 6 zakładek → CTA hero, każdy element z pierścieniem; strzałki zmieniają grupę i przeliczają wynik, Enter na „Dalej” przenosi fokus na `legend` kolejnego kroku, Enter na `summary` otwiera FAQ. Nie sprawdzono: czytnik ekranu (NVDA/VoiceOver wymagają sesji ręcznej), `prefers-reduced-transparency` (skrypt nie emulował tej preferencji – pokrywa ją ta sama reguła co `prefers-contrast`), Safari/WebKit oraz realne urządzenie z Androidem.

## Decyzje

1. **Róż `#e11d48` zostaje kolorem wypełnień, tekst w różu to `#be123c` (jasny) / `#fda4af` (ciemny).** Uzasadnienie: 4,70:1 na białym nie zostawia zapasu, a na tłach różowych (`#fff1f2`) spada do 4,28:1. Odrzucone: zmiana koloru marki na ciemniejszy wszędzie (traci lekkość CTA), pozostawienie `#e11d48` jako tekstu (niezgodność z AA na tłach akcentowych).
2. **Montserrat (nagłówki) + Inter (tekst), self-hosting przez `next/font`.** Uzasadnienie: ciągłość marki, czytelność w małych rozmiarach, cyfry tabelaryczne, brak CLS. Odrzucone: Playfair Display (dwie rodziny serif/sans mnożyły koszty i wyglądały „bankowo-weselnie”), stos systemowy (różne metryki między platformami psują łamanie H1 i kart; pozostaje jako fallback i plan B wydajnościowy).
3. **Kalkulator w hero jako glass widget z wyborem grupy ryzyka zamiast 45 checkboxów.** Uzasadnienie: jedno pytanie na krok, brak zagnieżdżonego przewijania, wynik widoczny od pierwszego ekranu. Odrzucone: lista zabiegów w hero (ściana checkboxów na 360 px), kalkulator wyłącznie na osobnej stronie (traci konwersję z home). Pełna lista zabiegów pozostaje jako ściąga i na `/kalkulator/oc`.
4. **Jedna nawigacja: zakładki produktów przewijane poziomo + arkusz „Więcej”.** Odrzucone: pasek pomocniczy 10 px, hamburger (ukrywa ofertę), mega-menu (6 produktów nie wymaga).
5. **Szkło w trzech miejscach (hero-widget, sticky header, karta wyniku/sticky CTA), nigdzie w treści.** Uzasadnienie: koszt kompozycji i czytelności rośnie z każdą taflą; brief wymaga efektu, nie motywu. Odrzucone: glass na kartach produktów i w stopce.
6. **Tekst drugorzędny tylko na panelu o kryciu 92 %.** Uzasadnienie: policzony kontrast na tafli 55 % nad granatem nie gwarantuje 4,5:1 dla `--color-text-2/3`. Odrzucone: zwiększenie krycia tafli do 85 % (efekt szkła znika), ciemniejszy tekst drugorzędny (traci hierarchię).
7. **`data-theme` + `prefers-color-scheme`, bez `html.dark` i `!important`.** Uzasadnienie: zgodne z Tailwind 4 `@custom-variant`, odwracalne, bez nadpisywania utility. Odrzucone: klasa `.dark` z nadpisaniami Tailwinda (obecne `bp-nav.js`).
8. **Natywne elementy przed komponentami: `<details>` dla FAQ, `<dialog>` dla modali, radio/checkbox z `opacity:0` zamiast `display:none`.** Uzasadnienie: dostępność i brak JS w ścieżce krytycznej. Odrzucone: akordeon i modal w React bez semantyki natywnej.
9. **Formularz leadowy jako strona/arkusz pełnoekranowy, nie modal.** Uzasadnienie: na mobile modale z formularzem walczą z klawiaturą i pułapką fokusu; strona ma własny URL do pomiaru. Odrzucone: modal (obecne rozwiązanie).
10. **Banner zgód tylko wtedy, gdy pojawi się analityka wymagająca zgody; z równorzędnymi przyciskami.** Uzasadnienie: kolektor `aura-analytics-collector` i analityka własna bez cookies śledzących [założenie – do potwierdzenia w `02-architektura-i-bezpieczenstwo.md`] nie wymagają bannera. Odrzucone: banner „na wszelki wypadek” z „X” jako zgodą.
11. **Brak zdjęć w hero w v1; gradient i typografia.** Uzasadnienie: szybkość (brak obrazu LCP), brak praw do materiałów, spójność między trybami. Odrzucone: wideo z `nowy.html` (placeholder bez treści, koszt transferu, autoodtwarzanie vs reduced-motion).
12. **Cele dotykowe 44 px jako standard, mimo że WCAG 2.2 wymaga 24 px.** Uzasadnienie: użytkowniczki pracują telefonem między zabiegami, często w rękawiczkach lub z mokrymi dłońmi [założenie]. Odrzucone: 24 px minimum (zgodne, ale uciążliwe).

## Pytania otwarte do zleceniodawcy

1. Czy BeautyPolisa/Aura Consulting występuje jako broker czy agent? Od tego zależy jedna formuła w headerze, stopce i na `/o-nas` (dziś w kodzie cztery różne).
2. Czy mamy prawo użyć logotypów ERGO Hestia, Colonnade, ENEL-MED, LUX MED i Fundacji Beauty Razem w pasku zaufania, czy pozostajemy przy nazwach tekstowych?
3. Czy mnożnik składki dla zespołów 6–8 osób (×1,25 w obecnym kodzie) jest potwierdzony z ERGO Hestią, czy kalkulator ma pokazywać dla tego przedziału „wycena indywidualna”? **Rozstrzygnięte 11.11.2026:** składki są sztywne (taryfa programu); ×1,25 dla zespołów 6–8 osób jest częścią taryfy, więc kalkulator pokazuje dla tego przedziału składkę wg taryfy, a wycena indywidualna dotyczy grupy 4 i zespołów od 9 osób.
4. Czy istnieją wytyczne brandowe (księga znaku, wersje logo na ciemne tło, minimalna wielkość)? Makieta używa logotypu tekstowego; plik PNG z repo wymaga wersji SVG.
5. Czy portal ma pokazywać ceny „od” dla Tax Protect, grupowych i abonamentów medycznych (wartości w kodzie są oznaczone jako „do potwierdzenia”), czy wyłącznie dla OC? **Rozstrzygnięte 11.11.2026:** składki są sztywne (taryfa programu), a oznaczenie „do potwierdzenia” w kodzie jest nieaktualne – strony Tax Protect (kwoty z tabeli `tax_warianty`), Grupowego ERGO dla beauty (58/68/76 zł za osobę miesięcznie) i abonamentów medycznych mogą pokazywać ceny „od” z cennika programu; Tax Protect przy przychodach powyżej 3 mln zł – wycena indywidualna.
6. Jaki jest deklarowany czas odpowiedzi doradcy po wysłaniu formularza (komunikat sukcesu) i godziny kontaktu na `/kontakt`?
7. Czy w v1 będzie jakakolwiek analityka wymagająca zgody (piksele reklamowe), co uruchamia banner zgód, czy wyłącznie pomiar bez cookies?
8. Czy Utrata dochodu i NNW dzieci mają w v1 strony informacyjne z formularzem (bez cennika), czy pozostają w nawigacji jako „w przygotowaniu” – i do kiedy zespół produktowy dostarczy zakres?
9. Czy klient akceptuje brak zdjęć i wideo w hero w v1, czy planuje sesję zdjęciową (wtedy potrzebne wytyczne do stylu zdjęć i budżet wydajnościowy na obraz LCP)?
