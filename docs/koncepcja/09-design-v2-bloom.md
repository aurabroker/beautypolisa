# 09 · Design v2 – marka i ikony z Bloom

> **Uwaga – wersja zastąpiona.** Zleceniodawca odrzucił v2 jako „ilustrację z komiksu”. Aktualny jest design v3 w stylu old money, opisany w `10-design-v3-old-money.md` (makieta: `design/v3/makieta-v3.html`, tokeny: `design/v3/tokens-v3.css`). Z tej sekcji nadal obowiązują reguły kalkulatora OC i opis pracy z Bloom. Paleta z różem, ikony z różowym akcentem, ilustracja hero i makieta v2 są nieaktualne.

> Ta sekcja zastępuje część wizualną sekcji `07-design-ux-i-glass-widget.md`: paletę, typografię, ikony, ilustracje i makietę. Z sekcji 07 nadal obowiązują: lista kontrolna dostępności WCAG 2.2 AA, zasady responsywności, inwentarz komponentów, mikrocopy i szablony stron.

## TL;DR

- Projekt v1 został odrzucony przez zleceniodawcę. Główne przyczyny: kolory i font niezgodne z logo, generyczne ikony, brak warstwy ilustracyjnej i nadużyty efekt szkła.
- Marka BeautyPolisa została założona w Bloom wyłącznie na podstawie logo z repozytorium. Bloom odczytał paletę z logo (`#2A3B68`, `#ED145B`, `#D30C54`) i font Poppins oraz zapisał wytyczne dla ikon i strony.
- W Bloom powstał od zera zestaw 21 ikon (produkty, zawody, interfejs) w dwóch wersjach: arkusz wzorcowy PNG i wektor SVG. Ikony są rozcięte na pojedyncze pliki i sprite z `currentColor`.
- W Bloom powstała ilustracja hero w tym samym stylu linii. Po generacji przyciszono róż na fotelu i liściach, zgodnie z zasadą „granat prowadzi, róż jest akcentem”.
- Nowa makieta strony głównej `design/makieta-v2.html` działa bez builda, liczy składkę OC według reguł obecnego kalkulatora i została sprawdzona w Chrome przy 390 px i 1280 px.
- Bloom przeprowadził przegląd zgodności z marką. Ciemniejszy granat nagłówków został poprawiony. Uwagę o cenie rozstrzygnął zleceniodawca: składki są sztywne (taryfa programu), więc cena „od 400 zł” jest w hero i w kalkulatorze bez zastrzeżeń.

## 1. Dlaczego v1 nie działał

| Problem w v1 | Skutek | Rozwiązanie w v2 |
|---|---|---|
| Róż `#e11d48` i granat z Tailwinda zamiast kolorów z logo | Strona „obok” marki, róż w CTA inny niż w sercu logo | Paleta pobrana z pikseli logo i zatwierdzona w Bloom |
| Montserrat i Inter, a wcześniej Playfair Display | Logo w Poppins, tekst w innym kroju | Poppins w nagłówkach i tekście |
| Emoji, a potem ikony Lucide | Brak charakteru, wygląd szablonu | 21 ikon zaprojektowanych od zera w Bloom |
| Hero oparte na gradiencie i rozmytych plamach | Brak obrazu, który mówi „salon beauty” | Ilustracja Bloom: fotel, stolik z kosmetykami, tarcza z sercem |
| Szkło na wielu elementach | Efekt tracił sens, spadała czytelność | Szkło tylko tam, gdzie coś za nim jest: kalkulator na tle serca, plakietka w hero, nagłówek |
| 45 checkboxów zabiegów w kalkulatorze | Długi formularz na starcie | Cztery grupy ryzyka jako kafle; pełna lista zabiegów zostaje na `/kalkulator/oc` |

## 2. Proces w Bloom

| Krok | Co zrobiono | Wynik |
|---|---|---|
| Założenie marki | Źródła: logo `BeautyPolisa_logo_podstawowe_poziome.png` i baner `AEX.png` z publicznego repo; instrukcja z faktami z sekcji 01 | Marka „BeautyPolisa” z paletą, typografią, wytycznymi głosu, produktów, logo i ikon |
| Brief | Zadanie: zestaw ikon do strony, 24–48 px, trzy grupy | Wytyczne: prosta geometria, wspólna linia i narożniki, granat jako kolor główny, róż oszczędnie, serce nie w każdej ikonie |
| Arkusz wzorcowy | Model GPT Image 2.6 Sunburst z briefem, PNG 2240×960 | `design/bloom/ikony-arkusz-wzorcowy.webp` |
| Wektor | Ten sam model, wyjście SVG, ikony w grupach z identyfikatorami | `design/bloom/ikony-arkusz.svg` |
| Ilustracja hero | Wyjście SVG w stylu ikon | `design/bloom/hero-ilustracja-bloom.svg` (oryginał) i `hero-ilustracja.svg` (po przyciszeniu różu) |
| Przegląd | Recenzja zrzutu makiety względem marki: kolor, typografia, logo, copy | Dwie poprawki wprowadzone, szczegóły w rozdziale 7 |

Zużycie kredytów Bloom w tej pracy wyniosło około 8,6 kredytu. Najwięcej kosztowało założenie marki (5) i przegląd (2).

Marka w Bloom jest dostępna w obszarze roboczym zleceniodawcy pod nazwą „BeautyPolisa” i może służyć do kolejnych materiałów: grafik do kampanii z sekcji 06, banerów i kolejnych ilustracji.

## 3. Paleta i kontrast

| Token | Hex | Rola | Kontrast |
|---|---|---|---|
| `--bp-navy` | `#2A3B68` | Nagłówki, ikony, nawigacja, granatowe przyciski | 10,92:1 na bieli; 9,92:1 na blush |
| `--bp-pink` | `#ED145B` | Serce, akcenty ikon, ilustracje | Biały tekst 4,33:1, więc nie do małego tekstu |
| `--bp-pink-strong` | `#D30C54` | Przyciski CTA, różowy tekst w nagłówku | Biały tekst 5,32:1; na blush 4,83:1 |
| `--bp-pink-hover` | `#B80A49` | Hover CTA, tekst etykiet „Zapytaj o ofertę” | 6,61:1 |
| `--bp-body` | `#4A5468` | Tekst akapitów | 7,6:1 na bieli; 6,9:1 na blush |
| `--bp-muted` | `#5B6478` | Opisy i podpisy | 5,93:1 na bieli; 5,39:1 na blush |
| `--bp-blush` | `#FDF1F5` | Tła sekcji i odznak ikon | – |
| `--bp-navy-50` | `#EEF1F8` | Etykiety ubezpieczycieli, tła pomocnicze | – |

Pełne tokeny wraz z mapowaniem do Tailwind CSS 4 są w `design/tokens-v2.css`.

**Tryb ciemny** jest w v2 świadomie wyłączony. Logo ma granatowy napis, który na ciemnym tle znika, a marka nie ma wersji logo na ciemne tło. Tryb ciemny wróci, gdy powstanie taka wersja.

## 4. Typografia

- Poppins w wagach 400, 500, 600 i 700. Font jest na licencji SIL Open Font License, więc można go hostować samodzielnie przez `next/font`.
- Nagłówek H1 płynnie od około 34 px do 54 px, H2 od 27 px do 38 px, tekst 16 px z interlinią 1,65.
- Minimalny rozmiar tekstu to 12 px. Makieta ma zero elementów poniżej tej wartości.
- Kursywa nie jest używana. Wyróżnienie w nagłówku to kolor `#D30C54`.

## 5. Ikony

**Anatomia.** Siatka 96×96 w `viewBox`, odpowiednik siatki 24 px. Linia 6 jednostek, czyli 1,5 px przy 24 px i 3 px przy 48 px. Końce i narożniki zaokrąglone. Kontur granatowy, w każdej ikonie dokładnie jeden różowy akcent. Serce marki jest osobną ikoną i nie pojawia się w każdej ikonie.

**Zestaw.**

| Grupa | Ikony (nazwa pliku) |
|---|---|
| Produkty i narzędzia | `oc-beauty`, `tax-protect`, `utrata-dochodu`, `nnw-dzieci`, `grupowe-ergo`, `opieka-medyczna`, `kalkulator` |
| Zawody | `kosmetolog`, `fryzjer`, `podolog`, `linergistka`, `stylistka-paznokci`, `tatuazysta` |
| Interfejs | `dokumenty`, `doradca`, `szkoda`, `szybka-wycena`, `bezpieczenstwo`, `grupy-ryzyka`, `w-zakresie`, `serce` |

**Pliki.**

- `design/bloom/ikony/*.svg` – 21 samodzielnych plików z kolorami marki i polskim `<title>`, do użycia jako `<img>` albo w CMS.
- `design/bloom/ikony-sprite.svg` – sprite z symbolami `bp-<nazwa>`. Kontur bierze `currentColor`, akcent zmienną `--bp-icon-accent`.
- `design/bloom/ikony-manifest.json` – mapowanie nazw z Bloom na nazwy plików i tytuły.

**Użycie w Next.js.** Sprite trafia do jednego komponentu serwerowego renderowanego raz w layoucie. Ikona to `<svg class="bp-icon"><use href="#bp-oc-beauty"/></svg>`. Ikony dekoracyjne mają `aria-hidden="true"`, a ikony bez etykiety tekstowej dostają `aria-label`.

**Rozszerzanie zestawu.** Nowe ikony generujemy w Bloom z tym samym briefem i promptem stylu. Gotowy wektor przechodzi przez ten sam skrypt podziału, a nowa ikona trafia do przeglądu wizualnego na arkuszu obok istniejących.

## 6. Strona główna v2

Kolejność sekcji i ich cel:

1. **Nagłówek** – logo z podpisem „created by Aura Expert”, pięć pozycji menu, przycisk „Oblicz składkę OC”. Na telefonie menu w `<details>` działa bez JavaScriptu.
2. **Hero** – nagłówek „Ubezpieczenie, które rozumie Twoje zabiegi”, dwa przyciski, trzy fakty z ikoną `w-zakresie`, ilustracja Bloom i szklana plakietka „Wycena OC w 2 minuty”. Pod spodem tekstowa lista partnerów.
3. **Ubezpieczenia** – sześć kart z ikoną, nazwą ubezpieczyciela w etykiecie i jednym linkiem. Utrata dochodu i NNW dzieci mają etykietę „Zapytaj o ofertę”.
4. **Szybka wycena OC (glass widget)** – kalkulator jako szklana karta na tle dużego, dwukolorowego serca marki. Serce prześwituje przez szkło, a jego górne łuki wychodzą ponad kartę.
5. **Dla kogo** – sześć kafli zawodów z ikonami i przykładami zabiegów z obecnej listy.
6. **Jak to działa** – trzy kroki i cztery cechy programu.
7. **Zgłoszenie szkody** – baner z linkiem do instrukcji.
8. **FAQ** – cztery pytania oparte na faktach z obecnego kalkulatora i ankiety ERGO Hestii.
9. **CTA** – granatowy blok „Porozmawiajmy o ochronie Twojego salonu”, zdanie zaproponowane w wytycznych głosu w Bloom.
10. **Stopka** – dane Aura Expert sp. z o.o. i miejsce na jej dane jako dystrybutora: status (agent albo broker) i numer w rejestrze KNF.

**Kalkulator.** Reguły są przeniesione 1:1 z obecnego `bp-app.js`:

| Wybór | Taryfa | Składka 100 / 200 / 300 tys. zł |
|---|---|---|
| Tylko grupa 1 | Gabinety kosmetyczne i fryzjerskie | 400 / 500 / 650 zł |
| Tylko grupa 2 | Gabinety kosmetologiczne | 650 / 790 / 950 zł |
| Grupa 3 albo grupy 1 i 2 razem | Taryfa 3 (podologia, wieloprofilowy, pakiet łączony) | 850 / 980 / 1250 zł |
| Grupa 4 w wyborze | Wycena indywidualna, ankieta ERGO Hestii | – |
| Zespół 6–8 osób | Mnożnik 1,25 | – |
| Zespół 9 i więcej osób | Wycena indywidualna | – |
| Ochrona prawna | +92 zł | – |

Składki są sztywne – to stała taryfa programu, nie wycena szacunkowa (potwierdzenie zleceniodawcy z 11.11.2026). Kalkulator pokazuje je bez dopisków „poglądowy” czy „orientacyjny”. Pod wynikiem zostaje jedno zdanie o taryfie i o wycenie indywidualnej dla grupy 4 i zespołów od 9 osób.

## 7. Weryfikacja

**Test w przeglądarce (Playwright, Chrome).**

| Sprawdzenie | 390 px | 1280 px |
|---|---|---|
| Przewijanie poziome | brak | brak |
| Błędy konsoli i strony | 0 | 0 |
| Tekst poniżej 12 px | 0 | 0 |
| Grupy 1 i 2, suma 200 tys. zł | 980 zł | 980 zł |
| Grupa 4 | Wycena indywidualna | Wycena indywidualna |

**Przegląd zgodności z marką w Bloom.**

| Kontrola | Werdykt Bloom | Co zrobiono |
|---|---|---|
| Kolor | Nagłówki w `#1C2748` zamiast `#2A3B68`; przyciski i serce zgodne | Nagłówki przestawione na `#2A3B68` |
| Copy | Ton zgodny z marką; cena 400 zł i sumy wymagają zatwierdzonych danych produktu | Zleceniodawca potwierdził, że składki są sztywne (taryfa programu). Cena „od 400 zł rocznie” wróciła do plakietki hero, a kalkulator ma etykietę „Stała taryfa programu” |
| Logo | Niepewny – zrzut za mały, by potwierdzić detale | Używany jest oryginalny plik PNG bez zmian; w produkcji zalecany SVG logo |
| Typografia | Niepewny – większość liter zgodna z Poppins | Bez zmian; to ograniczenie rozdzielczości zrzutu |

## 8. Gdzie zobaczyć

- **Makieta w repozytorium:** `docs/koncepcja/design/makieta-v2.html` – otworzyć lokalnie w przeglądarce; kalkulator działa.
- **Płótno Design w claude.ai:** dwa artboardy – interaktywna strona główna oraz system marki z paletą, typografią i 21 ikonami. Link podany jest w podsumowaniu prac; płótno jest prywatne, dopóki właściciel go nie udostępni.

## Decyzje

1. **Paleta i font wyłącznie z logo.** Odrzucono dalsze strojenie palety v1, bo była niezgodna ze znakiem marki.
2. **Ikony własne z Bloom zamiast bibliotek (Lucide, Heroicons).** Biblioteki są poprawne technicznie, ale nie budują rozpoznawalności, a branża beauty wymaga ikon zawodów, których biblioteki nie mają.
3. **Jeden różowy akcent na ikonę.** Odrzucono ikony w pełni różowe i jednobarwne granatowe: pierwsze łamią zasadę akcentu, drugie są bez charakteru.
4. **CTA w `#D30C54`, nie `#ED145B`.** Biały tekst na `#ED145B` ma 4,33:1, czyli poniżej 4,5:1 wymaganego dla tekstu przycisków.
5. **Szkło tylko z czymś za nim.** Kalkulator na tle serca marki uzasadnia efekt; puste szkło na białym tle odrzucono.
6. **Tryb ciemny wyłączony do czasu logo na ciemne tło.** Odrzucono odwrócenie kolorów logo, bo wytyczne marki zabraniają zmian w znaku.
7. **Ilustracja zamiast zdjęć w v1 portalu.** Zdjęcia wymagają sesji i praw; ilustracja jest lekka (6,5 KB) i spójna z ikonami.

## Pytania otwarte do zleceniodawcy

1. Czy istnieje logo w wersji SVG oraz w wersji na ciemne tło? Bez nich nie wrócimy do trybu ciemnego.
2. ~~Czy cennik OC jest aktualny i potwierdzony?~~ Rozstrzygnięte 11.11.2026: składki są sztywne (taryfa programu: 400–1250 zł, ochrona prawna 92 zł, zespół 6–8 osób ×1,25).
3. Czy można publicznie wymienić Fundację Beauty Razem i ubezpieczycieli z nazwy w pasku partnerów? Logotypy wymagają zgody, nazwy tekstowe zwykle nie, ale to decyzja prawna.
4. Czy chcesz kolejne ilustracje z Bloom: dla każdej strony produktu i dla stron zawodów?
5. Czy płótno Design ma zostać udostępnione zespołowi lub agencji, która będzie budować portal?
