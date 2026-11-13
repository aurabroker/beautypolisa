# ERGO Życie w Biznesie: wniosek grupowy dla branży beauty (inżynieria wsteczna)

Źródło: kod kliencki `https://ergo.auraexpert.pl/wniosek?branza=beauty` (SvelteKit, SPA, `ssr: false` w węźle trasy `/wniosek`). Analizowane pliki (robocze kopie po prettier z pierwszego przebiegu analizy; nie są częścią repozytorium beautypolisa – kod źródłowy tych samych stron jest w repozytorium `aurabroker/branzowe`, §9):

| Plik | Zawartość |
|---|---|
| `ext/src/ezb/index.html` | pusta powłoka SPA: Roboto z Google Fonts, 2 arkusze CSS (`0.DlgIBCu_.css`, `7.BsKANu8P.css`, **nie pobrane**), skrypt Cloudflare challenge (`/cdn-cgi/challenge-platform/...`), bez analityki |
| `js/_app__immutable__entry__app.DM-m-F-M.js` | mapa tras: `/`, `/dokumenty`, `/o-nas`, `/regulamin`, `/rodo`, `/wniosek`, `/wniosek/dziekujemy`, `/zakres-ochrony/[zakladka]` |
| `js/_app__immutable__nodes__7.75cyHC3C.js` | **cały kreator wniosku** (stan, 6 kroków, pasek dolny, walidacje, wysyłka) |
| `js/_app__immutable__chunks__s4z72ZNe.js` | **osadzony cennik** (stała `H`) i funkcje wyceny (`K` = wylicz, `O` = format zł, `D` = format świadczenia, `M` = ostrzeżenie W3>W1) |
| `js/_app__immutable__chunks__DN1jLyXa.js` | etykiety pozycji pakietów dodatkowych spoza katalogu, tabela pakietu (`h`) |
| `js/_app__immutable__nodes__8.CMtB0S-Q.js` | strona „Wniosek przyjęty” (`/wniosek/dziekujemy`) |
| `js/_app__immutable__nodes__0/2/3/4/5/6/9` | layout (nagłówek, stopka), strona główna, dokumenty, o nas, regulamin, RODO, zakres ochrony |
| `js/_app__immutable__chunks__SM48GHmE.js` | adresy zdjęć kafli branż (hosting `www.trybloom.ai/img/...`) |

**Uzupełnienie 13.11.2026:** backend (serwer `/api/wnioski` i `/api/gus`, e-maile, baza, dokumenty, katalogi OWU) opisują §9–§12 na podstawie repozytorium `aurabroker/branzowe`. Aplikacja to SvelteKit z adapterem Cloudflare Workers; produkcja odpowiada gałęzi PR #1 (`3c5086f`, §9.0).

Dane strukturalne do makiety: `ergo-zycie-w-biznesie.json` w tym samym katalogu (kroki, pola, opcje, pełny cennik wszystkich 8 branż, rozpisane karty wariantów i tabela świadczeń dla beauty, mediopieka, Global Doctors, 11 pakietów dodatkowych, zgody, słowniczek, opisy pakietów, dokumenty).

---

## 1. Przegląd i kroki

**Produkt:** grupowe ubezpieczenie na życie *ERGO Życie w Biznesie* (OWU EZwB 01/25), ubezpieczyciel Sopockie Towarzystwo Ubezpieczeń na Życie ERGO Hestia S.A., dystrybutor Aura Expert sp. z o.o. Oferta branżowa obowiązuje 1.07–31.12.2026 (nagłówek layoutu, `nodes/0`). Grupa: firmy, które zatrudniają **od 2 do 100 osób** w wieku **15–70 lat**.

**Mechanika:** jeden obiekt stanu `Vt` (`nodes/7`, l. 106–339), który zapisuje się do `sessionStorage` pod kluczem `ezb-wniosek-v1` przy każdej zmianie kroku i części pól. Stepper ma 6 pozycji: `Branża, Wariant, Rozszerzenia, Struktura, Firma, Zgody`. Można klikać tylko kroki już ukończone (`a(oa) < krok`). `idz(i)` blokuje wejście na krok ≥2 bez wybranej branży i po każdej zmianie przewija stronę do góry (`smooth`). Tytuł karty przeglądarki to „Kreator wniosku — ERGO Życie w Biznesie”.

**Parametr `?branza=beauty`** (`nodes/7`, funkcja `Is`): najpierw stan jest wczytywany z sessionStorage. Jeśli slug istnieje w cenniku i różni się od zapisanego, kod ustawia `branza`, zeruje `wariant=0` i `pakiety={}` (`medi` i `gd` zostają bez zmian), a gdy `krok===1`, przechodzi do kroku 2. **W BeautyPolisie krok 1 jest więc w praktyce pomijany.**

| Krok | Komponent | Co robi | Warunek „Dalej” |
|---|---|---|---|
| 1 Branża | `ee` | 8 kafli branż (zdjęcie, nazwa, opis, „od X / os. / mies.” = min z 3 składek). Kliknięcie ustawia branżę, zeruje wariant i pakiety, a po 140 ms przechodzi do kroku 2 | kliknięcie kafla |
| 2 Wariant | `ce` | 3 karty wariantów: cena, liczba świadczeń, „część na zgon”, kluczowe świadczenia. Do tego rozwijana pełna tabela świadczeń z karencjami | zawsze aktywny (wariant domyślnie 0) |
| 3 Rozszerzenia | `fe` | MediOpieka (5 pozycji, multi), Global Doctors (1), pakiety dodatkowe (11, każdy w 3 wariantach; domyślnie ukryte 3-podgrupowe). Suwak „adopcji” pojawia się, gdy wybrano cokolwiek | zawsze aktywny |
| 4 Struktura | `Ge` | Tryb 0: wklejenie listy (PESEL / data+płeć / rocznik+płeć), lokalne przeliczenie do agregatu rocznik×płeć i statystyki. Tryb 1: sama liczba osób | `2 ≤ liczbaOsob ≤ 100` |
| 5 Firma | `Qe` | NIP z sumą kontrolną → `GET /api/gus`. Przy 404 lub awarii jest tryb ręczny z nazwą firmy. Potem dane kontaktowe | GUS ok lub tryb ręczny + imię, e-mail, telefon (szczegóły w §2) |
| 6 Zgody | `ls` | podsumowanie, koszt, 7 zgód (5 wymaganych), wysyłka `POST /api/wnioski` | z1–z5 zaznaczone i brak trwającej wysyłki |
| — | `/wniosek/dziekujemy` | numer wniosku, e-mail, komunikat „kompletny” albo „arkusz XLS w mailu”, losowy baner promo **utratadochodu.pl** | — |

**Pasek dolny** (`ys`, widoczny na krokach 2–6 przy wybranej branży): „Pakiet główny / os. · gwarantowana” = `baza`, „Szacowany koszt firmy / mies.” = `szacunek · N os.` (bez liczby osób: „podaj strukturę”), „Widełki (0–100% adopcji)” = `min – max`, „bez rozszerzeń” albo „—”. Przycisk rozwija „rozbij składkę ▾” / „zwiń ▴”.

---

## 2. Pola i walidacje

| Krok | Pole (stan) | Typ | Wymagane | Walidacja (dokładnie z kodu) | Komunikat błędu / reakcja |
|---|---|---|---|---|---|
| 1 | `branza` | kafel `<button>` | tak | slug z `cennik.branze` | brak (bez branży nie da się wejść na krok ≥2) |
| 2 | `wariant` | karta `<button>` ×3 | tak | 0, 1 lub 2, domyślnie 0 | — |
| 3 | `medi[]` | przełączane karty | nie | slugi: `assistance-medyczny`, `assistance-chorobowy`, `assistance-onkologiczny`, `teleopieka-kardiologiczna`, `mediplan` | — |
| 3 | `gd` | przełączana karta | nie | bool | brak walidacji wieku 18–64 (wymóg jest tylko wyświetlany) |
| 3 | `pakiety{slug: wariant}` | `div role=checkbox` (Enter/klik) + 3 przyciski „WI · 12 zł” | nie | zaznaczenie wstawia wariant 0. Klik przycisku wariantu ustawia ten wariant i zaznacza pakiet (`stopPropagation`). Klik wewnątrz `<details class="swdet">` nie przełącza | ostrzeżenie dla 3-podgrupowych: „⚠ Niezgodny z pakietem głównym (5 podgrup operacji).” |
| 3 | `adopcja` | `range` min 0, max 100, krok 5 | nie | zapis `wartość/100`, domyślnie 0,5. Widoczny tylko gdy jest jakiekolwiek rozszerzenie | — |
| 4 | `tryb` | 2 przyciski | — | 0 = lista, 1 = liczba. Przełączenie na 1 zeruje strukturę i ustawia `liczbaOsob = clamp(0..999, 12)`. Przełączenie na 0 przelicza z `struktura` albo daje 0 | — |
| 4 | textarea `#paste` | textarea 12 wierszy | — | **nie trafia do stanu ani do sessionStorage** (zmienna lokalna). Parser `$e`: PESEL (11 cyfr po usunięciu spacji i NBSP) z sumą kontrolną wag `[1,3,7,9,1,3,7,9,1,3]` i datą (miesiąc +0/20/40/60/80 → 1900/2000/2100/2200/1800); `RRRR-MM-DD␣K/M`; `RRRR␣K/M` (separator `; , tab spacja`). Filtr wieku 15–70 włącznie. Wiek liczony na **dzisiejszą datę przeglądarki** (pełne lata dla PESEL i daty, różnica roczników dla `RRRR K/M`). Płeć z PESEL: 10. cyfra nieparzysta = M. Format `RRRR-MM-DD` **nie jest sprawdzany** pod kątem istnienia daty (np. 31 lutego przechodzi), PESEL – jest | per wiersz: „PESEL — błędna suma kontrolna”, „PESEL — nieprawidłowa data”, „nierozpoznany format” (pierwsze 4 wiersze, przycięte do 18 znaków, potem „…”) |
| 4 | `liczbaOsob` (tryb 1) `#cntM` | number min 2 max 100 | tak | w kodzie `Math.max(0, Math.min(999, v||0))`, przycisk Dalej aktywny dla 2–100 | `>100`: „{N} osób — program obejmuje maks. 100. Przy większych zespołach opiekun przygotuje ofertę indywidualną.” · `0<N<2`: „Minimum to 2 osoby.” (oba komunikaty tylko w trybie listy; w trybie liczby jest tylko zablokowany przycisk) |
| 4 | `struktura` | wynik parsera | nie | `[{rok, plec:'K'|'M', liczba}]` posortowane po roku, potem płci | poza wiekiem: „{n} os. poza zakresem wieku 15–70 lat — nie wchodzą do ubezpieczenia i nie liczymy ich do składki.” · nic nie rozpoznano: „Nie rozpoznaliśmy żadnej osoby. Wklej PESEL-e (11 cyfr), daty RRRR-MM-DD K/M albo roczniki RRRR K/M.” |
| 5 | NIP `#nip`, etykieta „NIP *” | text maxlength 13, placeholder „np. 5252248481”, autocomplete off; przycisk „Sprawdź w GUS” / w trakcie „Odpytuję REGON…” | tak | po usunięciu nie-cyfr długość 10, wagi `[6,5,7,2,3,4,5,6,7]`, `suma % 11 ≠ 10` i równa 10. cyfrze. Sprawdzane dopiero po kliknięciu „Sprawdź w GUS” | „Nieprawidłowy NIP — suma kontrolna się nie zgadza.” (klasa `bad` na polu) |
| 5 | wynik GUS | — | tak (albo tryb ręczny) | `/api/gus` 200, 404, inne | 404: „Nie znaleźliśmy firmy o NIP {nip} w rejestrze REGON. Sprawdź numer albo wpisz dane ręcznie.” · błąd/wyjątek: „Rejestr REGON chwilowo nie odpowiada. Nie blokujemy Cię — możesz wpisać dane ręcznie, zweryfikujemy je po naszej stronie.” · `data_zawieszenia`: „GUS podaje, że działalność jest zawieszona od {data}. Program jest dla firm aktywnych — opiekun zweryfikuje status przed wystawieniem polisy.” (**nie blokuje**) |
| 5 | nazwa ręczna `#nazwaR`, etykieta „Nazwa firmy *” | text, placeholder „Pełna nazwa firmy” | tak w trybie ręcznym | `trim().length > 2`. Zapis do `gus = {nip, nazwa, zrodlo:'recznie'}` na blur i przy „Dalej” | brak komunikatu, tylko zablokowane „Dalej” |
| 5 | `kontakt.imie` `#imie`, etykieta „Osoba do kontaktu *” | text, placeholder „Imię i nazwisko” | tak | `trim().length > 2` | brak komunikatu |
| 5 | `kontakt.stanowisko` `#stan`, etykieta „Stanowisko” | text, placeholder „np. właściciel, HR” | nie | — | — |
| 5 | `kontakt.email` `#mail`, etykieta „E-mail *” | email, placeholder „na ten adres wyślemy potwierdzenie” | tak | regex `/.+@.+\..+/` | brak komunikatu |
| 5 | `kontakt.telefon` `#tel`, etykieta „Telefon *” | text, placeholder „+48” | tak | liczba cyfr ≥ 9 | brak komunikatu |
| 5 | `kontakt.start` `#start`, etykieta „Planowany start ochrony” | date | nie | brak (bez min/max) | — |
| 6 | `zgody.z1…z7` | checkbox + „czytaj całość” (rozwija treść) | z1–z5 tak | `Ve = kody wymagane`, wszystkie muszą być `true` | przycisk zablokowany; błąd wysyłki: „Nie udało się wysłać wniosku. Spróbuj ponownie za chwilę. ({status}: {≤200 znaków odpowiedzi})” |

Formularz kontaktowy (krok 5) pokazuje się dopiero wtedy, gdy GUS zwrócił dane albo włączono tryb ręczny. **Uwagi do walidacji:**
- Pola kontaktowe nie mają komunikatów błędów, widać tylko zablokowany przycisk.
- W trybie ręcznym NIP nie jest walidowany ponownie: kod używa bieżącej wartości pola.
- Krok 6 nie sprawdza ponownie `liczbaOsob`, `gus` ani `kontakt`. Sesję można odtworzyć od razu na kroku 6, więc pełna walidacja musi być po stronie serwera.

---

## 3. Treści dosłowne

### 3.1 Zgody (`nodes/7`, stała `mt`, l. 1808–1867), wszystkie w wersji `2026-07-a`

| Kod | Wym. | Etykieta | Treść |
|---|---|---|---|
| z1 | tak | Zgoda na objęcie grupowym ubezpieczeniem na życie ERGO Życie w Biznesie | Wnioskuję o zawarcie umowy grupowego ubezpieczenia na życie ERGO Życie w Biznesie na warunkach określonych w OWU (kod: EZwB 01/25) oraz OWU ubezpieczeń dodatkowych, które wybrałem w tym wniosku. |
| z2 | tak | Oświadczenie o zapoznaniu się z OWU i kartami produktu | Oświadczam, że przed złożeniem wniosku otrzymałem i zapoznałem się z Ogólnymi warunkami ubezpieczenia (EZwB 01/25), OWU MediOpieka (MA 01/25) oraz OWU Global Doctors (GD-GZ 01/25), w tym z wyłączeniami i ograniczeniami odpowiedzialności. |
| z3 | tak | Zgoda na przetwarzanie danych osobowych (RODO) | Administratorem danych jest Sopockie Towarzystwo Ubezpieczeń na Życie ERGO Hestia S.A. Dane przetwarzamy w celu zawarcia i wykonania umowy ubezpieczenia (art. 6 ust. 1 lit. b RODO) oraz w celach wynikających z prawnie uzasadnionych interesów administratora. |
| z4 | tak | Oświadczenie o liczbie i wieku osób zgłaszanych do ubezpieczenia | Oświadczam, że osoby zgłaszane do ubezpieczenia są aktywne zawodowo, mają od 15 do 70 lat, a ich liczba mieści się w przedziale 2–100. |
| z5 | tak | Oświadczenie o statusie nowego klienta | Oświadczam, że firma nie posiada obecnie umowy grupowego ubezpieczenia na życie w ERGO Hestii — oferta branżowa dotyczy nowych klientów. |
| z6 | nie | Zgoda marketingowa — e-mail | Zgoda na otrzymywanie informacji handlowych drogą elektroniczną. Dobrowolna, można wycofać w każdej chwili. |
| z7 | nie | Zgoda marketingowa — telefon | Zgoda na kontakt telefoniczny w celach marketingowych. Dobrowolna, można wycofać w każdej chwili. |

Przy etykiecie wymaganej zgody jest gwiazdka `*`, przy dobrowolnej dopisek „(dobrowolna)”. Pod listą: „* zgody wymagane do złożenia wniosku”.

### 3.2 Teksty kroków

**Krok 1:** „Jaka to branża?”. Podtytuł: „Składki i zakres różnią się między branżami — to nie jest jeden cennik z rabatem. Wybierz swoją, a zobaczysz dokładnie te trzy warianty, które ERGO Hestia oferuje firmom z Twoim PKD.” Ramka czerwona: „**Zanim wybierzesz branżę:** program działa wyłącznie dla firm zatrudniających **od 2 do 100 osób**, w wieku 15–70 lat. Poniżej i powyżej tego progu opiekun przygotuje ofertę indywidualną.” Notka: „**Nie ma Twojej branży?** Oferta branżowa obejmuje wybrane kody PKD. Dla pozostałych firm przygotujemy ofertę standardową — zostaw kontakt.” (link „zostaw kontakt” to `mailto:` na [e-mail kontaktowy Aura Expert – skrzynka zgłoszeń, ta sama co MAIL_OPIEKUN]) Kafel: „od **{min}** / os. / mies.”

**Krok 2:** eyebrow „Krok 2 · Beauty”, tytuł „Wybierz wariant”. Podtytuł: „Trzy warianty programu dla branży beauty. Różnią się nie tylko ceną — mają inny rozkład sum ubezpieczenia, a część z nich w ogóle nie zawiera świadczeń dla rodziny.” Karta: „Wariant I/II/III”, „{cena} / os. / mies.”, „{N} świadczeń · część na zgon: {kwota}”. Rozwijana tabela: „Pełna tabela świadczeń — wszystkie pozycje dla tej branży” (kolumny: Świadczenie, Wariant I, Wariant II, Wariant III, Karencja; dni jako „(dni 1–180)”). Notka: „Kwoty w osobnych wierszach **nie kumulują się** — wartość w wierszu to już skumulowana kwota świadczeń (np. w zgonie w wyniku wypadku zawarta jest kwota za zgon). Szczegóły, wyłączenia i ograniczenia: OWU **EZwB 01/25**.” Ostrzeżenie warunkowe, które **dla beauty się nie pokazuje** (W3 zgon 75 000 < W1 100 000): „Uwaga: w tej branży Wariant III ma wyższą sumę na zgon niż Wariant I ({W3} vs {W1}). Warianty nie są uszeregowane „od najsłabszego do najmocniejszego” — porównuj zakres, nie numer.” Przyciski: „← Wstecz”, „Dalej: rozszerzenia →”.

**Krok 3:** „Co udostępniasz pracownikom”. Podtytuł: „Składkę za wszystko płacisz Ty — ale to pracownik decyduje w swojej deklaracji, które rozszerzenia weźmie. Zaznacz więc, **co ma zobaczyć w menu**.” Ramka: „**Twój koszt to widełki, nie liczba.** Dopiero po zebraniu deklaracji od zespołu wiadomo, ile osób wzięło co. Poniżej możesz założyć, jaka część zespołu skorzysta — żeby zaplanować budżet.” Suwak: „Zakładam, że rozszerzenia wybierze **{X}%** zespołu”, krańce „nikt (koszt minimalny)” / „wszyscy (koszt maksymalny)”. Sekcje:
- „MediOpieka · assistance i świadczenia medyczne, realizowane w Polsce”
- „Global Doctors · leczenie za granicą, suma 2 mln €”. Opis: „Organizacja i pokrycie kosztów leczenia w klinikach za granicą — nowotwory, zastawki serca, by-passy, neurochirurgia, przeszczepy. Suma **2 000 000 € na całe życie ubezpieczonego**. Dodatkowo zgon ubezpieczonego 10 000 zł. / **Wiek 18–64 lat** · wymagane 183 dni pobytu w PL w ostatnich 12 mies.”
- „Pakiety dodatkowe · każdy w 3 wariantach”: „Pakiet główny rozlicza operacje w **5 podgrupach**, więc domyślnie pokazujemy zgodne z nim pakiety 5-podgrupowe.” Link: „pokaż też warianty 3-podgrupowe” / „ukryj warianty 3-podgrupowe”. W karcie pakietu jest `<details>` „świadczenia i sumy w wariantach”.

Ceny jako „{X} /os./mies.”. Przyciski: „← Wstecz”, „Dalej: struktura zespołu →”.

**Krok 4:** „Ile osób ubezpieczasz? — musi być od 2 do 100”. Podtytuł: „**Składka jest już ostateczna** i nie zależy od wieku zespołu — struktura wiekowa jest nam potrzebna do wystawienia polisy, nie do wyceny. Możesz podać ją teraz albo dostać arkusz mailem.” Przełącznik: „Mam listę — wkleję teraz” / „Podam samą liczbę, resztę uzupełnię później”. Notka (zielona): „**PESEL-e nie opuszczają tej przeglądarki.** Przeliczamy je lokalnie na wiek i płeć, a do nas trafia wyłącznie tabela zbiorcza — ile kobiet i mężczyzn w każdym roczniku. Odśwież stronę i znikają.” Etykieta textarea: „Wklej dane (jedna osoba w wierszu) — PESEL, data urodzenia + płeć albo sam rocznik + płeć”. Przyciski: „Przelicz strukturę”, „Wklej dane demo”. Pusty panel: „Tu pojawi się rozkład wieku / i liczba osób do ubezpieczenia”. Statystyki: „Osób”, „Kobiety / Mężczyźni”, „Średni wiek” (1 miejsce po przecinku), słupki 15–24, 25–34, 35–44, 45–54, 55–70, stopka: „Do ERGO Hestii wysyłamy tylko te liczby — {k} pozycji siatki rocznik × płeć.” W trybie liczby: etykieta „Liczba osób do ubezpieczenia *”, pomoc: „Arkusz struktury wiekowej wyślemy mailem razem z potwierdzeniem. Polisę wystawimy, gdy go odeślesz — składka się nie zmieni.” Przyciski: „← Wstecz”, „Dalej: dane firmy →”.

**Krok 5:** „Dane firmy”. Podtytuł: „Podaj NIP — resztę pobierzemy z rejestru REGON (GUS). Sprawdzimy też, czy Twoje PKD mieści się w wybranej branży.” (**W kodzie klienckim nie ma żadnego sprawdzenia PKD względem branży, PKD jest tylko wyświetlane.**) Karta GUS: „Dane z rejestru REGON (GUS)” + „Znaleziono”, pola „Nazwa”, „NIP / REGON”, „Adres”, „PKD przeważające” (kod, opis). Tryb ręczny: „Tryb ręczny — dane zweryfikuje opiekun przed wystawieniem polisy.” Przycisk „Wpisz dane ręcznie”. Nawigacja: „← Wstecz”, „Dalej: podsumowanie →”.

**Krok 6:** „Podsumowanie i zgody”, karta „Twój wniosek”: Firma, NIP, Program („Beauty · Wariant I”), Osób do ubezpieczenia, Struktura rocznik × płeć („{n} pozycji (bez danych osobowych)” albo „arkusz mailem”), Pakiet główny („{baza} / os. / mies.”), **Koszt pewny** („{min} / mies.”). Sekcja „Rozszerzenia udostępnione zespołowi”: lista „{nazwa} — {cena} / os.”, „Przy {X}% adopcji ≈ {szacunek} / mies.”, „Widełki kosztu {min} – {max}”, „Ostateczna składka wyjdzie **po zebraniu deklaracji** od pracowników — każdy sam wskaże, które rozszerzenia bierze. Opiekun potwierdzi kwotę przed wystawieniem polisy.” Bez rozszerzeń: „Nie udostępniasz rozszerzeń — składka jest z góry znana i nie zmieni się po zebraniu deklaracji.” Przycisk: „Złóż wniosek” / „Wysyłam…”.

**Pasek dolny:**
- „Pakiet główny — obowiązuje całą grupę, koszt pewny” → „Beauty · Wariant I × N os.” = „{min} / mies.”
- „Rozszerzenia — wybiera pracownik, płacisz Ty”: wiersze „{nazwa}” = „{cena} / os. · {cena×N} gdyby wzięli wszyscy”
- „Przy założeniu {X}% adopcji” = „{szacunek} / mies. · {szacunek×12} / rok”
- „Widełki: od zera do pełnej adopcji” = „{min} – {max} / mies.”
- Bez rozszerzeń: „Nie udostępniasz rozszerzeń — koszt jest pewny: {min×12} / rok.”

**Dziękujemy** (`nodes/8`), tytuł „Wniosek przyjęty — ERGO Życie w Biznesie”: „Wniosek przyjęty” / „Numer **{nr}**. Kopia oferty poszła na **{email}**. Opiekun odezwie się w ciągu jednego dnia roboczego.”
- Gdy `kompletny=1`: „**Wniosek jest kompletny.** Strukturę wiekową już mamy — nie musisz nic odsyłać. Opiekun potwierdzi warunki i przygotuje polisę.”
- W przeciwnym razie: plik „**lista-ubezpieczonych.xlsx** — Arkusz struktury wiekowej jest w załączniku maila z potwierdzeniem. Wypełnij dane osób przystępujących i odeślij odpowiedzią na tę wiadomość — każdy pracownik składa własną deklarację z wyborem rozszerzeń, dopiero wtedy znamy ostateczną składkę.”
- Dalej: „[Przejdź do zakładki Dokumenty](/dokumenty) jeśli chcesz pobrać OWU.”, losowy baner (12 grafik `utrata-dochodu-*.png`) z linkiem `https://utratadochodu.pl` (`target=_blank`), przycisk „Zacznij od nowa”. Bez e-maila w URL wyświetla się „twój adres e-mail”.

### 3.3 Klauzule informacyjne (layout i strony prawne)
- Stopka: „Aura Expert sp. z o.o. ul. Bolkowska 2A lok. 28, Warszawa · KRS 0000599840 · REGON 363673048 / Rejestr Pośredników Ubezpieczeniowych: 11229690/A / Kontakt: [e-mail kontaktowy Aura Expert – skrzynka zgłoszeń, ta sama co MAIL_OPIEKUN]” oraz „Materiał informacyjny — nie jest ofertą w rozumieniu art. 66 k.c. Wiążące są wyłącznie OWU: EZwB 01/25, MA 01/25, GD-GZ 01/25. Ubezpieczyciel: Sopockie Towarzystwo Ubezpieczeń na Życie ERGO Hestia S.A.”
- Nagłówek: „Grupowe ubezpieczenie na życie · 2–100 osób / ERGO Życie w Biznesie · oferta branżowa 1.07–31.12.2026”.
- Strona RODO (`nodes/6`), dosłownie: „Administratorem danych zbieranych w tym serwisie jest Aura Expert sp. z o.o. (dystrybutor ubezpieczeń). Po przekazaniu wniosku administratorem danych w celu zawarcia i wykonania umowy ubezpieczenia staje się Sopockie Towarzystwo Ubezpieczeń na Życie ERGO Hestia S.A. […] 1. Dane firmy (NIP, nazwa, adres, PKD — pobierane z rejestru REGON) oraz dane osoby kontaktowej (imię i nazwisko, e-mail, telefon, stanowisko) — w celu przygotowania i obsługi wniosku o ubezpieczenie (art. 6 ust. 1 lit. b RODO). 2. Zbiorczą strukturę wiekową zespołu — wyłącznie liczbę osób danej płci w danym roczniku. Numery PESEL nie opuszczają Twojej przeglądarki: są przeliczane lokalnie na agregat, a nasz serwer aktywnie odrzuca każde zgłoszenie zawierające numer PESEL. 3. Zgody marketingowe (jeśli ich udzielono) — na podstawie art. 6 ust. 1 lit. a RODO; można je wycofać w każdej chwili. […] Dane przechowujemy w Unii Europejskiej: baza danych Supabase (region UE), wysyłka e-maili Resend, infrastruktura Cloudflare. Dane wniosku przekazujemy ubezpieczycielowi — ERGO Hestii. […] Dane wniosków przechowujemy przez okres wymagany przepisami o dystrybucji ubezpieczeń. Masz prawo dostępu do danych, ich sprostowania, usunięcia, ograniczenia przetwarzania, przenoszenia oraz wniesienia skargi do Prezesa UODO.” Strona ma dopisek: „**Dokument roboczy — wymaga zatwierdzenia przez prawnika przed startem kampanii.**”
- Regulamin (`nodes/5`) i O nas (`nodes/4`). Źródło w repozytorium: `branzowe/src/routes/regulamin/+page.svelte:5-42` i `branzowe/src/routes/o-nas/+page.svelte:5-34` (treść identyczna w `3c5086f` i `8dc9a90`). Pełne teksty, dosłownie:
  - **O nas** (`/o-nas`, tytuł strony „O nas — Aura Expert sp. z o.o.”): eyebrow „O nas”, nagłówek „Aura Expert sp. z o.o.”. „Jesteśmy dystrybutorem ubezpieczeń. Prowadzimy program branżowy grupowego ubezpieczenia na życie **ERGO Życie w Biznesie** dla firm zatrudniających od 2 do 100 osób — od doboru wariantu, przez złożenie wniosku online, po opiekę nad polisą.” „Ubezpieczycielem jest Sopockie Towarzystwo Ubezpieczeń na Życie ERGO Hestia S.A. Szczegółowe informacje o naszej roli jako dystrybutora, w tym o charakterze wynagrodzenia, znajdziesz w dokumencie "Informacja o dystrybutorze", który dołączamy do każdego potwierdzenia wniosku.” Sekcja „Dane rejestrowe”: „Aura Expert spółka z ograniczoną odpowiedzialnością z siedzibą w Warszawie przy ul. Bolkowskiej 2A lokal 28, wpisana do Krajowego Rejestru Sądowego pod numerem **0000599840** przez Sąd Rejonowy dla m.st. Warszawy, XII Wydział Gospodarczy Krajowego Rejestru Sądowego, REGON **363673048**, kapitał zakładowy 5.000 zł.” „Spółka wpisana jest do Rejestru Pośredników Ubezpieczeniowych pod numerem **11229690/A**. Wpis można zweryfikować w rejestrze prowadzonym przez Komisję Nadzoru Finansowego: [rpu.knf.gov.pl](https://rpu.knf.gov.pl).” Sekcja „Kontakt”: „E-mail: [e-mail kontaktowy Aura Expert – skrzynka zgłoszeń, ta sama co MAIL_OPIEKUN]” (link `mailto:`). Dokument „Informacja o dystrybutorze” jest tylko załącznikiem maila (§9.5).
  - **Regulamin** (`/regulamin`, tytuł strony „Regulamin serwisu — ERGO Życie w Biznesie”): eyebrow „Regulamin”, nagłówek „Regulamin serwisu ergo.auraexpert.pl”.
    - „§1. Postanowienia ogólne”: „1. Serwis prowadzi Aura Expert sp. z o.o. (dalej: "Operator"), pełniąca rolę dystrybutora ubezpieczeń. 2. Serwis służy do prezentacji warunków grupowego ubezpieczenia na życie ERGO Życie w Biznesie oraz do składania wniosków o objęcie ochroną. 3. Ubezpieczycielem jest Sopockie Towarzystwo Ubezpieczeń na Życie ERGO Hestia S.A.”
    - „§2. Charakter informacji”: „1. Treści w serwisie mają charakter informacyjny i nie stanowią oferty w rozumieniu art. 66 Kodeksu cywilnego. 2. Wiążące warunki ubezpieczenia określają wyłącznie Ogólne Warunki Ubezpieczenia: EZwB 01/25, MA 01/25 oraz GD-GZ 01/25. 3. Złożenie wniosku w serwisie nie jest równoznaczne z zawarciem umowy ubezpieczenia — umowa dochodzi do skutku po potwierdzeniu warunków przez opiekuna i ubezpieczyciela.”
    - „§3. Warunki techniczne i zasady korzystania”: „1. Do korzystania z serwisu wystarczy przeglądarka internetowa z włączoną obsługą JavaScript. 2. Użytkownik zobowiązany jest do podawania danych zgodnych z prawdą. 3. Numery PESEL wklejane w kroku "struktura zespołu" są przetwarzane wyłącznie lokalnie w przeglądarce użytkownika i nie są przesyłane do Operatora.”
    - „§4. Reklamacje”: „Reklamacje dotyczące działania serwisu można składać na adres [e-mail kontaktowy Aura Expert – skrzynka zgłoszeń, ta sama co MAIL_OPIEKUN]. Odpowiadamy w terminie 14 dni.”
  - W kodzie cudzysłowy wewnątrz tekstów to proste `"` (tu oddane bez zmian). Numeracja punktów jest w treści, rozdzielona `<br />`.
- Dokumenty PDF (`nodes/3`): 3 OWU i 3 Karty Produktu pod `/dokumenty/*.pdf` (lista w JSON). **Same pliki PDF nie zostały pobrane.** *(Stan po analizie repozytorium: pliki są w `static/dokumenty/`, rozmiary i kody w §9.5.)*

---

## 4. Logika cen i taryf

**Źródło cennika:** cennik jest **osadzony w JS** (`chunks/s4z72ZNe.js`, stała `H = {swiadczenia, grupy, branze, mediopieka, global_doctors, pakiety_dodatkowe}`). Lista `branze` jest wpisana jako `JSON.parse('<literał>')`. Klient niczego nie pobiera z API. **Nie ma pola `meta` ani numeru wersji.** W bazie wersja to `branze-2607`: tabela `ezb_cenniki` aplikacji EZB w projekcie Supabase „aurabroker”, wspólnym z CRM; `meta` jest częścią kolumny `dane`. *(Poprawione 13.11.2026, wcześniej „w CRM”. Serwer liczy z cennika w bundlu, §9.1.)* Dane wyciągnięto parserem AST (acorn), bez wykonywania kodu.

**Beauty** (`slug: beauty`, „Salony fryzjerskie, kosmetyczne, SPA, studia paznokci”, kod ulotki `EH-UL-EZB-F-2607`):

| | Wariant I | Wariant II | Wariant III |
|---|---|---|---|
| Składka / os. / mies. | **58 zł** | **68 zł** | **76 zł** |
| w tym część na zgon (`skladka_zgon`) | 15,59 zł | 14,06 zł | 12,08 zł |
| Liczba świadczeń (niepuste) | 32 | 44 | 57 |
| Zgon ubezpieczonego | 100 000 | 80 000 | 75 000 |
| Poważne zachorowanie (max) | do 11 000 | do 8000 | do 7500 |
| Operacja chirurgiczna (5 podgrup) | 4500 | 3500 | 3500 |
| Szpital — choroba (dni 1–180) | 90 / dzień | 80 / dzień | 80 / dzień |
| TU w wyniku NW | 650 / 1% | 600 / 1% | 550 / 1% |
| Całkowita trwała niezdolność (choroba lub NW) | 25 000 | 25 000 | 25 000 |
| Zgon małżonka/partnera | — | 15 000 | 15 000 |
| Zgon dziecka | — | — | 5000 |

Pełna tabela 57 pozycji w 8 grupach, z karencjami, jest w JSON (`cennik.beauty.tabela_swiadczen`). Na kartach wariantów pokazywane są te pozycje: `zgon, pz_max, operacja, szpital_choroba, tu_nw, niezdolnosc_nw, niezdolnosc_choroba_nw, zgon_malzonka, zgon_dziecka`, o ile występują w branży (beauty nie ma `niezdolnosc_nw`).

**MediOpieka (zł/os./mies.):** Assistance medyczny **3** (limit 10 000 zł/rok, 16 usług z limitami w JSON) · Assistance chorobowy ubezpieczonego **2,5** · Assistance onkologiczny ubezpieczonego **2** · Teleopieka kardiologiczna ubezpieczonego **0,8** · MediPlan **2,8**. Przy MediPlan w kodzie jest uwaga: „Cennik branżowy podaje jedną składkę 2,80 zł, bez rozbicia na 3 warianty MediPlanu — do potwierdzenia w taryfie.” UI nie pozwala wybrać wariantu MediPlanu.

**Global Doctors:** **135 zł/os./mies.**, suma 2 000 000 € na całe życie, zgon 10 000 zł, wiek 18–64, karencja NW „90 dni”, 5 modułów, limity, okres świadczeniowy 36 miesięcy.

**Pakiety dodatkowe** (zł/os./mies. W I / W II / W III):

| nr | Pakiet | Podgrupy | Składki | Domyślnie widoczny |
|---|---|---|---|---|
| 1 | Pakiet Życie | — | 12 / 15 / 20 | tak |
| 2 | Pakiet Zdrowie (3 podgrupy operacji) | 3 | 18 / 28 / 40 | nie |
| 3 | Pakiet Zdrowie (5 podgrup operacji) | 5 | 17 / 27 / 39 | tak |
| 4 | Pakiet Wypadek (3 podgrupy operacji) | 3 | 12 / 16 / 20 | nie |
| 5 | Pakiet Wypadek (5 podgrup operacji) | 5 | 11 / 15 / 19 | tak |
| 6 | Pakiet Onkologiczny | — | 12 / 16 / 22 | tak |
| 7 | Pakiet Kardiologiczny | — | 10 / 14 / 18 | tak |
| 8 | Pakiet Dziecko NW (3 podgrupy operacji) | 3 | 6 / 8 / 12 | nie |
| 9 | Pakiet Dziecko NW (5 podgrup operacji) | 5 | 5 / 7 / 11 | tak |
| 10 | Pakiet Małżonek NW (3 podgrupy operacji) | 3 | 6 / 8 / 12 | nie |
| 11 | Pakiet Małżonek NW (5 podgrup operacji) | 5 | 5 / 7 / 11 | tak |

Sumy świadczeń pakietów są w JSON. Pakiety Dziecko NW mają uwagę: „Jedna składka obejmuje wszystkie dzieci ubezpieczonego do 25. roku życia.”

**Wzór** (`s4z72ZNe.js`, funkcje `U` i `K`):
```
baza       = branza.skladka[wariant]
opcje      = [mediopieka zaznaczone: skladka] + [GD: 135 jeśli gd] + [pakiet: skladka[wariantPakietu]]
sumaOpcji  = Σ opcje
min        = baza × liczbaOsob                       // „Koszt pewny”
max        = (baza + sumaOpcji) × liczbaOsob
szacunek   = min + sumaOpcji × liczbaOsob × adopcja  // adopcja 0..1, domyślnie 0,5
rocznie    = szacunek × 12   (bez rozszerzeń: min × 12)
```
Wiek nie wpływa na składkę, a struktura nie wchodzi do wyceny. Błędy: `Nieznana branża: {slug}`, `Adopcja poza zakresem 0–1`. Przykład: beauty W I, 10 os., Assistance medyczny + Pakiet Życie W I, adopcja 50% → min 580, max 730, szacunek 655 zł/mies.

**Formatowanie** (`O`): `toLocaleString('pl-PL')`, 2 miejsca po przecinku tylko dla ułamków, separator tysięcy NBSP od 5 cyfr („4500 zł”, „100 000 zł”), sufiks „ zł”. Świadczenie (`D`): „do ” dla `max`, „ / 1%” dla `pln_1pct`, „ / dzień” dla `pln_dzien`, „—” dla null. W pakietach wartość bool daje „✓ w pakiecie”.

---

## 5. Wysyłka danych

**`GET /api/gus?nip={10 cyfr}`**, bez nagłówków i tokenu. Kod oczekuje JSON z polami `nazwa, regon, adres, pkd_kod, pkd_opis, data_zawieszenia` (innych nie używa, ale cały obiekt wraca w `firma`). Statusy: 404 → „nie znaleziono”, inny nie-OK lub wyjątek → „awaria”. Stan: `gus = {...odp, nip, zrodlo:'gus'}`. Kod serwera: §9.2.

**`POST /api/wnioski`**, `content-type: application/json`, ciało:
```json
{
  "branza": "beauty",
  "wariant": 0,
  "rozszerzenia": { "medi": ["assistance-medyczny"], "gd": false, "pakiety": { "zycie": 0 } },
  "zalozona_adopcja": 0.5,
  "liczba_osob": 10,
  "struktura": [{ "rok": 1985, "plec": "K", "liczba": 2 }],
  "firma": { "nazwa": "…", "regon": "…", "adres": "…", "pkd_kod": "…", "pkd_opis": "…", "nip": "…", "zrodlo": "gus" },
  "kontakt": { "imie": "", "stanowisko": "", "email": "", "telefon": "", "start": "" },
  "zgody": { "z1": { "wersja": "2026-07-a" }, "…": {} },
  "skladka_klienta": { "min": 580, "max": 730, "szacunek": 655 }
}
```
- `zgody` zawiera **tylko zaznaczone** kody, bez znacznika czasu (czas, IP i user-agent musi dodać serwer).
- `firma.data_zawieszenia` pojawia się tylko wtedy, gdy GUS ją zwróci. Wartość `null` serwer odrzuca (pole `optional`, nie `nullable`). *(Poprawione 13.11.2026: przykład zawierał `"data_zawieszenia": null`; §9.1.)*
- Ładunek nie ma wersji cennika, nr wniosku ani `baza`; mapowanie na kolumny `ezb_wnioski` (`cennik_wersja`, `skladka`, `nr_wniosku`, `status`) robi serwer (szczegóły: §9.1).
- Odpowiedź OK: JSON `{ nr_wniosku }`. Potem `sessionStorage.removeItem('ezb-wniosek-v1')` i przejście na `/wniosek/dziekujemy?nr=…&email=…&kompletny=0|1` (`kompletny=1` gdy `struktura` niepusta).
- Błąd: tekst „{status}: {treść[0..200]}” wyświetlony użytkownikowi.

**Turnstile:** **brak** w kodzie (żadnego widgetu, tokenu ani nagłówka). Jest tylko skrypt Cloudflare JS challenge wstrzyknięty przez CDN w `index.html`. **Honeypot:** brak. Serwer też niczego takiego nie wymaga (§9.1). **Szkice i przypomnienia:** brak. Szkic istnieje tylko lokalnie w `sessionStorage` i ginie po zamknięciu karty. Nie ma zapisu częściowego wniosku na serwerze ani e-maila przypominającego.

---

## 6. Logika poboczna

- **GUS:** wyłącznie przez `/api/gus` (proxy po stronie serwera; kod: §9.2).
- **Analityka:** brak (GA, gtag, Plausible, PostHog, dataLayer, sendBeacon nie występują). **`ezb_zdarzenia`:** klient nie wysyła żadnych zdarzeń i nie ma endpointu zdarzeń. Tabela jest zasilana po stronie serwera (np. przez `/api/wnioski` lub `/api/gus`) albo nieużywana. Do ustalenia. **Ustalone 13.11.2026:** zasila ją tylko `/api/wnioski` (typy `wyslano`, `atrybucja_pominieta` – tylko `990b947`+, nie na produkcji – oraz `mail_blad`), §9.1.
- **Storage:** `sessionStorage['ezb-wniosek-v1']` z polami `krok, branza, wariant, medi, gd, pakiety, adopcja, tryb, liczbaOsob, struktura, gus, kontakt, zgody`. Nie są zapisywane: surowa lista PESEL, `statystyki`, `pokaz3`, `wysylka`. Nie ma `localStorage`.
- **Przekierowania i linki zewnętrzne:** po sukcesie przejście na `/wniosek/dziekujemy`. Baner promo prowadzi do `https://utratadochodu.pl`; w BeautyPolisie trzeba go zastąpić wewnętrznym formularzem utraty dochodu. Kafle branż ze strony głównej linkują do `/wniosek?branza={slug}`. Link `mailto:` na [e-mail kontaktowy Aura Expert – skrzynka zgłoszeń, ta sama co MAIL_OPIEKUN] pojawia się w kroku 1, w stopce i na stronach prawnych (`/o-nas`, `/regulamin` §4).
- **Obrazy:** kafle branż pochodzą z `https://www.trybloom.ai/img/...` (zewnętrzny hosting, `SM48GHmE.js`), grafiki promo są w assetach (`utrata-dochodu-03…15.png`), ale **nie zostały pobrane**.
- **Zakres ochrony** (`nodes/9`): zakładki `pakiety, katalogi, ograniczenia, slowniczek`. Opisy 10 pakietów i 25 haseł słowniczka są osadzone (w JSON). Katalogi OWU są pobierane z `/dane/owu/{powazne-zachorowania, operacje-indeks, operacje-1..N, rozdzialy-ezb, rozdzialy-mo, owu-meta, slowniczek}.json`; **tych plików nie mamy**. *(Stan po analizie repozytorium: generuje je `scripts/tnij-owu.mjs`, struktura i liczności w §9.6.)*

---

## 7. Czego nie da się odtworzyć z kodu klienckiego (do uzyskania od zleceniodawcy)

*Stan po analizie repozytorium `branzowe` (13.11.2026): punkty 1–3 i 6 są zamknięte (§9.1–§9.6), punkt 4 częściowo (§9.1, §9.8), punkty 5 i 7 otwarte (§9.8), punkt 8 częściowo – sprzeczność rozstrzygnięta, akceptacja prawnika otwarta (§9.4), punkt 9: serwer nie wymaga żadnej ochrony (§9.1). Zestawienie: §10.*

1. **Kod `/api/wnioski`:** walidacja serwerowa, w tym zapowiadane „aktywne odrzucanie zgłoszeń z PESEL” (RODO), przeliczenie składki po stronie serwera, nadawanie `nr_wniosku` (format), `status` (wartości), zapis do `ezb_wnioski`, ewentualny zapis `ezb_zdarzenia`, limity i rate limiting, CORS.
2. **Kod `/api/gus`:** dostawca (BIR1/REGON API), klucz, mapowanie pól (`adres`, `pkd_*`, `data_zawieszenia`), cache, obsługa spółek cywilnych i jednostek lokalnych.
3. **E-maile (Resend):** szablon potwierdzenia dla klienta („Kopia oferty”), powiadomienie dla opiekuna, nadawca, **arkusz `lista-ubezpieczonych.xlsx`** (szablon), dokument „Informacja o dystrybutorze” (PDF), ewentualne PDF oferty.
4. **Cennik źródłowy i wersjonowanie:** `ezb_cenniki.dane.meta` i sposób wiązania `cennik_wersja` z wnioskiem; potwierdzenie składki MediPlan (3 warianty?) i czy `skladka_zgon` ma znaczenie w ofercie.
5. **Weryfikacja PKD vs branża:** obiecana w UI („Sprawdzimy też…”), w kliencie jej nie ma. Potrzebna lista kodów PKD dla beauty.
6. **Pliki statyczne:** 6 PDF z `/dokumenty/`, JSON-y `/dane/owu/*.json`, CSS, grafiki promo i zdjęcia branż.
7. **Proces po wniosku:** SLA „1 dzień roboczy”, deklaracje pracowników (osobny formularz?), sposób odsyłania arkusza, panel opiekuna w CRM aurabroker.
8. **Zatwierdzone teksty prawne:** RODO jest oznaczone jako „Dokument roboczy”; z3 wskazuje jako administratora ERGO Hestię, a strona RODO Aura Expert. Treść klauzul (w tym informacyjnej art. 13 i IDD) potwierdza zleceniodawca lub jego prawnik.
9. **Ochrona antyspamowa:** w obecnym kliencie nie ma Turnstile; czy serwer czegoś wymaga.

---

## 8. Uwagi bezpieczeństwa i RODO

- **Plus:** PESEL-e są przetwarzane lokalnie, wysyłany jest tylko agregat `{rok, płeć, liczba}`, surowa lista nie trafia do sessionStorage. Ten wzorzec warto zachować w BeautyPolisie.
- **E-mail w URL** strony podziękowania (`?email=`) trafia do historii przeglądarki, logów CDN i ewentualnie do `Referer`. W portalu przekazywać go przez stan lub sesję, nie przez query string.
- **Błąd serwera pokazywany użytkownikowi** (do 200 znaków treści) może ujawniać szczegóły implementacji. Lepiej pokazywać komunikat ogólny, a szczegóły logować.
- **Brak Turnstile i honeypota** przy publicznym `POST` z danymi osobowymi, który wysyła e-maile, to ryzyko spamu i nadużyć Resend. W portalu dodać Turnstile (serwerowa weryfikacja) i rate limit.
- **Brak ponownej walidacji przed wysyłką** (krok 6 można odtworzyć z sessionStorage), więc serwer musi walidować wszystko: NIP, e-mail, telefon, zakres liczby osób 2–100, wymagane zgody, strukturę (wiek 15–70, brak PESEL), zgodność składki z cennikiem.
- **Zgody** są zapisywane bez znacznika czasu i bez treści, tylko kod i wersja. Dla rozliczalności (art. 7 ust. 1 RODO) serwer powinien zapisać timestamp, IP i hash lub treść danej wersji.
- **sessionStorage** zawiera dane kontaktowe i firmowe do zamknięcia karty (ryzyko na współdzielonych komputerach). Po wysyłce jest czyszczony, czego nie robi przy porzuceniu wniosku.
- **Zawieszona działalność** (GUS) nie blokuje wniosku, tylko ostrzega.
- **Zewnętrzne zasoby:** obrazy z `trybloom.ai` i Google Fonts (transfer IP do podmiotu trzeciego). W portalu hostować lokalnie.
- **Dane demo:** kod zawiera 10 przykładowych wierszy z numerami w formacie PESEL (przycisk „Wklej dane demo”). Nie zostały skopiowane do raportu; w makiecie używać własnych, jawnie fikcyjnych danych.
- **Klucze i tokeny:** w kodzie klienckim EZB **nie ma** kluczy (brak anon key Supabase, klucza Turnstile, tokenów API). Supabase jest używany wyłącznie po stronie serwera.
- **Stan po analizie repozytorium (13.11.2026):** powyższe ryzyka potwierdzają się w kodzie serwera. Doszły nowe: mail z marką na dowolny adres, brak escapowania HTML w szablonach, klucz `service_role` do projektu współdzielonego z CRM, otwarte proxy GUS, arkusz XLSX z PESEL-ami odsyłany mailem. Pełna lista z dowodami: §12.

---

## 9. Backend i portal – analiza repozytorium `branzowe` (13.11.2026)

Źródło: `aurabroker/branzowe`, gałąź `claude/cool-hypatia-ndksid` @ `8dc9a90` (24.09.2026; lokalnie `ezb-najnowsza`). Pozostałe gałęzie czytane przez `git show`/`git diff`. Kod tylko czytany, bez uruchamiania. Wartości sekretów, identyfikatory projektu Supabase i konta Cloudflare, klucz GUS (także publiczny klucz testowy z testów) i adresy odbiorców są w konfiguracji, nie w dokumencie. Ścieżki bez prefiksu repozytorium dotyczą `branzowe`.

### 9.0 Gałęzie i która z nich jest na produkcji

| Gałąź | Ostatni commit | Zawartość | Relacja |
|---|---|---|---|
| `main` | `d94205b` 12.07.2026 | tylko `README.md` (Initial commit) | – |
| `claude/sveltekit-cloudflare-supabase-resend-pgz9w8` (PR #1) | `3c5086f` 20.07.2026 | aplikacja M1–M3: kreator, zakres ochrony, `/api/wnioski`, `/api/gus`, Resend, migracja `ezb_*`, dokumenty PDF, losowy baner | podstawa dwóch kolejnych (liniowo) |
| `claude/czytaj-repo-czekaj-m1talo` | `990b947` 04.09.2026 | + landingi `/branza/[slug]`, atrybucja kampanii (`zrodlo_wizyty`, migracja `20260904120000`), `sitemap.xml`, `robots.txt`, `hooks.server.ts` (`X-Robots-Tag` dla `/wniosek`), `rodo.ts` wydzielony z endpointu | `3c5086f` + 2 commity |
| `claude/cool-hypatia-ndksid` (= `ezb-najnowsza`) | `8dc9a90` 24.09.2026 | + banery w `static/banery/` pod stałymi adresami, link banera z UTM | `990b947` + 3 commity |
| `claude/great-noether-3vadc2` | `8df6f8d` 23.09.2026 | wyłącznie `gus-regon-verification.json` (przenośny klient BIR 1.1, §9.2) | odgałęzienie od `main`, bez kodu aplikacji |

**Produkcja (`ergo.auraexpert.pl`) odpowiada stanowi PR #1 (`3c5086f`), a nie najnowszej gałęzi.** Dowody z kodu klienckiego pobranego z produkcji (§1–§8):
- strona „Wniosek przyjęty” (`nodes/8`) ma 12 grafik `utrata-dochodu-03…15-*.png` i link `https://utratadochodu.pl` bez UTM, czyli dokładnie `src/lib/promo/*.png` i `dziekujemy/+page.svelte:57` z `3c5086f`. W `8dc9a90` są `/banery/*.png` i link z UTM (`dziekujemy/+page.svelte:59`);
- mapa tras produkcji nie ma `/branza/[slug]`, `/sitemap.xml` ani `/robots.txt`;
- kafle strony głównej linkują do `/wniosek?branza=…` (w `990b947`+ do `/branza/{slug}`, `git diff 3c5086f 8dc9a90 -- src/routes/+page.svelte`);
- ładunek `POST /api/wnioski` nie ma `zrodlo_wizyty` (dodane w `Krok6Zgody.svelte:33` w `990b947`).

Moduły kluczowe dla przeniesienia są identyczne w `3c5086f` i `8dc9a90`: `resend.ts`, `gus.ts`, `zgody.ts`, migracja `20260713120000_init.sql`, `static/dokumenty/*`. Endpoint `/api/wnioski` różni się tylko obsługą `zrodlo_wizyty` i wydzieleniem `zawieraPesel` do `rodo.ts` (logika ta sama, nowa wersja dodatkowo wyłącza `zrodlo_wizyty` z testu). Nie wiadomo, czy migracja `20260904120000_zrodlo_wizyty.sql` została wykonana w bazie. `origin/main` nie zawiera kodu, PR #1 nie jest scalony, a wdrożenie odbywa się ręcznie (`wrangler deploy`, `README.md:26-32`; krok deploy w `.github/workflows/ci.yml:23-36` jest zakomentowany). Kod produkcyjny nie leży więc na gałęzi głównej.

Dokument projektowy `docs/ARCHITEKTURA.md` (wersja 1.0, 13.07.2026) opisuje stan sprzed wdrożenia. Różni się od kodu: tabele bez prefiksu `ezb_` (l. 100–135), domena Resend `utratadochodu.com` (l. 59) i opiekun pod [e-mail biura Aura Expert] (l. 180), „link do rekordu” w mailu do opiekuna (l. 180), 49 haseł MO + hasła EZwB w słowniczku (l. 199), „GUS >100 zatrudnionych ⇒ stop” (l. 166–167). Żadnej z tych rzeczy nie ma w kodzie. Źródłem prawdy jest kod, nie ten dokument.

### 9.1 `POST /api/wnioski` – przyjęcie wniosku

**Kolejność obsługi** (`src/routes/api/wnioski/+server.ts`):
1. Brak `SUPABASE_URL` w środowisku → 503 „Backend nieskonfigurowany” (l. 136).
2. `request.json()`; błąd → 400 „Nieprawidłowy JSON” (l. 138–143).
3. Walidacja Zod (`schemat`, l. 19–79); pierwszy błąd → 422 „Walidacja: {komunikat}” (l. 144–145).
4. Negatywna walidacja PESEL (l. 148), suma struktury (l. 150–153), wymagane zgody (l. 155–157).
5. Przeliczenie składki po stronie serwera i porównanie z ładunkiem (l. 159–180).
6. `INSERT` do `ezb_wnioski` kluczem `service_role` (l. 182–222).
7. Załączniki i dwa e-maile Resend (l. 224–241); błędy maili nie przerywają.
8. `INSERT` zdarzeń do `ezb_zdarzenia` (l. 243–253), odpowiedź 201 `{ nr_wniosku }` (l. 255).

**Walidacje serwera (Zod, l. 19–79):**

| Pole | Reguła | Uwaga |
|---|---|---|
| `branza` | slug z `produkty.json` (`'nieznana branża'`) | – |
| `wariant` | int 0–2 | w bazie zapisywany jako 1–3 (`wariant + 1`, l. 186); warianty pakietów w `rozszerzenia.pakiety` zostają 0–2 |
| `rozszerzenia.medi` | tablica ≤ 10 slugów z `mediopieka` | – |
| `rozszerzenia.gd` | bool | **wiek 18–64 nie jest sprawdzany** (nie da się: serwer nie zna wieku osób) |
| `rozszerzenia.pakiety` | rekord `slug pakietu → int 0–2` | – |
| `zalozona_adopcja` | 0–1 | kolumna `numeric(3,2)` |
| `liczba_osob` | int 2–100 | – |
| `struktura` | `null` albo ≤ 200 pozycji `{rok: int 1940…(bieżący rok − 10), plec: 'K'|'M', liczba: 1–100}` | zakres roczników to wiek ok. 10–86 lat, **nie 15–70**. Suma `liczba` musi równać się `liczba_osob` → 422 „Suma struktury nie zgadza się z liczbą osób” |
| `firma` | `nip` z sumą kontrolną (`'błędny NIP'`), `nazwa` 3–300, `regon` ≤ 20, `adres` ≤ 300, `pkd_kod` ≤ 10, `pkd_opis` ≤ 300, `data_zawieszenia` ≤ 10 (wszystkie opcjonalne), `zrodlo: 'gus'|'recznie'` | danych z GUS serwer **nie weryfikuje ponownie**. `data_zawieszenia: null` zostałoby odrzucone (pole `optional`, nie `nullable`); GUS pomija to pole zamiast wysyłać `null` (`gus.ts:101`) |
| `kontakt` | `imie` 3–120, `stanowisko` ≤ 120, `email` (`z.string().email()`) ≤ 200, `telefon` **9–20 znaków** (bez sprawdzania cyfr), `start` ≤ 10 znaków (bez sprawdzania daty) | klient sprawdza ≥ 9 cyfr (`Krok5Firma.svelte:13-17`), serwer tylko długość |
| `zgody` | dowolny rekord `kod → {wersja ≤ 20 znaków}` | wymagane: obecność kluczy `z1–z5` (`KODY_WYMAGANE`, `zgody.ts:73`) → 422 „Brak wymaganej zgody {kod}”. **Wersja i nieznane kody nie są sprawdzane** |
| `skladka_klienta` | `{min, max, szacunek}` liczby | porównanie w kroku 5 |
| `zrodlo_wizyty` (tylko `990b947`+) | obiekt z 10 polami ≤ 200 znaków (`utm_source`, `utm_medium`, `utm_campaign`, `utm_content`, `utm_term`, `gclid`, `fbclid`, `msclkid`, `wejscie`, `skad`) + `ts` ≤ 40, wszystkie opcjonalne; `.strict().nullish()` – `null` albo brak pola (`+server.ts:63-78`) | §9.7 |

**PESEL.** `zawieraPesel` (`src/lib/domena/rodo.ts:26-31`; na produkcji ta sama funkcja wewnątrz endpointu) robi `JSON.stringify` całego ładunku i odrzuca go, gdy znajdzie ciąg `\d{11}`. Z testu wyłączone są `kontakt.telefon` (numer z +48) i `zrodlo_wizyty`. Odpowiedź: 422 „Payload zawiera ciąg wyglądający jak PESEL — odrzucono”. To potwierdza zdanie ze strony RODO („serwer aktywnie odrzuca…”). Ograniczenia: (a) fałszywe trafienie dla 14-cyfrowego REGON-u jednostki lokalnej, gdyby GUS go zwrócił, albo dla adresu e-mail czy nazwy z 11 cyframi pod rząd; (b) PESEL rozdzielony spacją lub myślnikiem przechodzi. Testy: `rodo.test.ts:15-53`.

**Składka po stronie serwera** (l. 159–180): `wyliczSkladke` (`src/lib/domena/skladka.ts:71-89`), ta sama funkcja co w kliencie, na cenniku z **pliku w bundlu** `src/lib/dane/produkty.json` (identyczny z `dane/produkty.json`). Porównywane są tylko `min` i `max` (tolerancja 0,01 zł). Przy rozjeździe serwer zwraca **409** z JSON `{ "blad": "Cennik się zmienił — odśwież stronę", "skladka": { "min", "max" } }`. Klient nie obsługuje 409 osobno: pokaże „Nie udało się wysłać wniosku… (409: {"blad":…})” (`Krok6Zgody.svelte:36-39, 119-122`). Zapisywane jest wyliczenie serwera: `skladka = {os: baza, min, max, szacunek}` (l. 196).

**Cennik i wersja.**
- Stała `CENNIK_WERSJA = 'branze-2607'` (l. 14) trafia do kolumny `cennik_wersja` (klucz obcy do `ezb_cenniki.wersja`, migracja l. 20). Ceny serwer bierze z bundla, **nie z `ezb_cenniki`**. Wiersz w bazie jest tylko migawką i spełnia warunek klucza obcego.
- `scripts/seed-cennika.mjs` wgrywa cały `dane/produkty.json` jako `dane` z `wersja: 'branze-2607'`, `obowiazuje_od/do` z `meta.skladki_obowiazuja` (2026-07-01 – 2026-12-31). Robi to przez REST PostgREST z `on_conflict=wersja` i `resolution=merge-duplicates`, czyli powtórny seed nadpisuje ten sam wiersz (l. 20–36). Według commita `438d70a` seed wykonano w projekcie Supabase „aurabroker”.
- Zmiana cennika wymaga trzech ręcznych kroków: nowego `produkty.json`, nowej wersji w seedzie **i** zmiany stałej w endpoincie, a potem redeployu. Kod nie wymusza ich zgodności.

**Numer wniosku** (migracja `20260713120000_init.sql:14,18-19`): `'EZB-' || to_char(now(),'YYYY') || '-' || lpad(nextval('ezb_wnioski_nr'), 6, '0')`, np. `EZB-2026-000123`. Sekwencja jest globalna (nie zeruje się co rok), a rok bierze z czasu serwera bazy (UTC). Testowy insert z rollbackiem zużył numer 000001 (commit `438d70a`).

**Zapis – tabele i kolumny** (`20260713120000_init.sql`; wszystkie z prefiksem `ezb_`, bo projekt „aurabroker” dzieli schemat `public` z `crm_*`, `ud_*`, `izba_*`, commit `438d70a`):

| Tabela | Kolumny | Uwagi |
|---|---|---|
| `ezb_cenniki` (l. 5–12) | `id`, `wersja` unique, `obowiazuje_od`, `obowiazuje_do`, `dane jsonb`, `utworzono` | 1 wiersz `branze-2607` |
| `ezb_wnioski` (l. 16–36) | `id uuid`, `nr_wniosku` unique, `cennik_wersja` FK, `branza`, `wariant` 1–3, `rozszerzenia jsonb`, `zalozona_adopcja numeric(3,2)` 0–1, `liczba_osob` 2–100, `struktura jsonb` (agregat lub NULL), `firma jsonb`, `kontakt jsonb`, `zgody jsonb`, `skladka jsonb`, `status`, `utworzono`; od `20260904120000`: `zrodlo_wizyty jsonb` | indeks `(status, utworzono desc)`; indeksy po `zrodlo_wizyty->>'utm_campaign'` i `->>'wejscie'` |
| `ezb_zdarzenia` (l. 40–46) | `id`, `sesja uuid`, `typ`, `dane jsonb`, `utworzono` | indeks `(typ, utworzono desc)` |

**Statusy:** `nowy` (domyślny) → `przekazany` → `oferta` → `polisa` / `odrzucony` (check, l. 33–34). **Żaden kod w repozytorium nie zmienia statusu.** Nie ma panelu opiekuna, endpointu ani funkcji. Każdy wniosek ma więc na zawsze status `nowy`, chyba że ktoś zmieni go ręcznie w bazie.

**`ezb_zdarzenia`** zasila wyłącznie `/api/wnioski` (l. 243–253). Klient nie wysyła zdarzeń lejka, a planowany w `ARCHITEKTURA.md` (l. 128–135) log kroków nie powstał. Typy:
- `wyslano`, `dane: {wniosek: id, branza, zrodlo}` (`zrodlo` od `990b947`; na produkcji `{wniosek, branza}`, `3c5086f:src/routes/api/wnioski/+server.ts:214`);
- `atrybucja_pominieta` (**tylko `990b947`+, nie na produkcji**; `+server.ts:248-250`), gdy brak kolumny `zrodlo_wizyty` i zapis ponowiono bez niej (l. 205–217; kod PostgREST `PGRST204` lub Postgres `42703`). Na produkcji zapisywane są tylko `wyslano` i `mail_blad` (`3c5086f:src/routes/api/wnioski/+server.ts:213-217`);
- `mail_blad`, jeden wpis na nieudany e-mail, `dane: {wniosek, adresat, blad}`.

Kolumna `sesja` przechowuje **id wniosku**, a nie identyfikator sesji (l. 253). Wynik tego `INSERT` nie jest sprawdzany.

**Idempotencja:** brak. Nie ma klucza idempotencji ani ograniczenia unikalności na treść (np. NIP + dzień). Ochroną przed duplikatem jest tylko blokada przycisku w trakcie wysyłki (`Krok6Zgody.svelte:14`). Ponowienie po zerwanym połączeniu, gdy serwer już zapisał, tworzy drugi wniosek i drugą parę maili.

**Rate limit, Turnstile, honeypot:** w kodzie brak. Nie ma ich w endpoincie, w `hooks.server.ts` (tylko `X-Robots-Tag`, `990b947`+) ani w `wrangler.jsonc`. Jedyną ochroną jest skrypt Cloudflare JS challenge wstrzykiwany na poziomie strefy (widoczny w `index.html` produkcji, §1). Nie ma go w repozytorium i nie chroni wywołań API spoza przeglądarki. CORS nie jest ustawiony, więc przeglądarka z innej domeny nie przejdzie preflightu dla `application/json`, ale skrypt serwerowy może wołać endpoint bez ograniczeń.

**Odpowiedzi i błędy:**

| Kod | Kiedy | Treść |
|---|---|---|
| 201 | zapisano | `{ "nr_wniosku": "EZB-RRRR-NNNNNN" }` |
| 400 | ciało nie jest JSON | „Nieprawidłowy JSON” |
| 409 | składka klienta ≠ serwera | `{ blad, skladka: {min, max} }` |
| 422 | Zod / PESEL / suma struktury / brak zgody | „Walidacja: …” (komunikaty Zod są domyślne, częściowo po angielsku, np. dla e-maila), „Payload zawiera ciąg wyglądający jak PESEL — odrzucono”, „Suma struktury nie zgadza się z liczbą osób”, „Brak wymaganej zgody z3” |
| 500 | błąd `INSERT` | „Nie udało się zapisać wniosku” (szczegóły w `console.error`, l. 220) |
| 503 | brak konfiguracji | „Backend nieskonfigurowany” |

Błędy rzucane przez `error()` SvelteKit wracają w standardowym formacie błędu SvelteKit, a klient pokazuje do 200 znaków surowej odpowiedzi (§2). Błąd e-maila nie zmienia odpowiedzi: wniosek jest zapisany, a klient i tak zobaczy „Kopia oferty poszła na…”.

**Dostęp do Supabase:** `supabaseAdmin()` tworzy klienta z kluczem `service_role` z sekretów Workera (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`; `src/lib/serwer/supabase.ts:8-12`, `app.d.ts:4-11`). RLS jest włączone na trzech tabelach bez żadnych polityk (migracja l. 50–53), więc `anon` i `authenticated` nie mają dostępu, a Worker ma pełny dostęp z pominięciem RLS. Ten sam klucz otwiera cały projekt „aurabroker”, łącznie z tabelami CRM (§12).

### 9.2 `GET /api/gus` – REGON (BIR 1.1)

**Endpoint** (`src/routes/api/gus/+server.ts`):
1. `nip` z query, oczyszczony z nie-cyfr. Zła suma kontrolna → 400 „Nieprawidłowy NIP” (l. 9–10).
2. Brak sekretu `GUS_API_KEY` → 503 „Brak konfiguracji API REGON” (l. 11–12).
3. Cache: `caches.default` z kluczem `https://cache.internal/gus/{nip}` (l. 14–19). Trafienie zwraca zapisaną odpowiedź.
4. `szukajPoNip` → 200 JSON z nagłówkiem `cache-control: public, max-age=86400` i zapis do cache (l. 21–27). Cache'owane są tylko odpowiedzi 200, przez 24 h, w cache danego centrum danych Cloudflare. Ten sam nagłówek pozwala też przeglądarce trzymać wynik dobę. 404 i błędy nie są cache'owane.
5. `GusBrakFirmy` → 404 „Nie znaleziono firmy w rejestrze REGON”, `GusAwaria` → 502 „Rejestr REGON nie odpowiada” (l. 29–30). Inne wyjątki są rzucane dalej (l. 31) i kończą się 500. Dotyczy to też **przekroczenia czasu** (`AbortSignal.timeout` rzuca `TimeoutError`, nie `GusAwaria`). Dla klienta każde „nie-OK” poza 404 oznacza „awarię” i tryb ręczny, więc wynik dla użytkownika jest ten sam.

**Klient BIR** (`src/lib/serwer/gus.ts`), SOAP 1.2 + WS-Addressing, endpoint produkcyjny `wyszukiwarkaregon.stat.gov.pl/wsBIR/UslugaBIRzewnPubl.svc` (l. 7–8):
- **Sesja:** przy każdym zapytaniu spoza cache wykonywane jest nowe `Zaloguj` kluczem. Pusty `ZalogujResult` → `GusAwaria` (l. 60–66). `sid` idzie w nagłówku HTTP `sid` (l. 35). **Nie ma `Wyloguj`** ani ponownego użycia sesji. Każde wywołanie zostawia otwartą sesję (wygasa po ok. 60 min bezczynności, `docs/REGONAPILOGIN.md:23`). Timeout 5 s na każde z maks. 3 wywołań SOAP (l. 38).
- **Wyszukanie:** `DaneSzukajPodmioty` z `<dat:Nip>` (l. 69–73). Pusty wynik albo `ErrorCode 4` albo brak `Nazwa` lub `Regon` → `GusBrakFirmy`. Inny `ErrorCode` (np. 2, wygasła sesja) → `GusAwaria` (l. 74–87). Wynik jest odkodowywany z encji i parsowany wyrażeniami regularnymi (l. 45–57).
- **Mapowanie adresu** (l. 90–100): `"{Ulica} {NrNieruchomosci}/{NrLokalu}, {KodPocztowy} {Miejscowosc}"`. Gdy brak lokalu, bez `/…`. Gdy brak ulicy: „{NrNieruchomosci}[/{NrLokalu}], {KodPocztowy} {Miejscowosc}” (`gus.ts:90-95`; lokal dołączany tylko wtedy, gdy jest ulica lub numer). Przy braku wszystkich części pole `adres` jest pomijane (`gus.ts:100`, `|| undefined`). Pola `Ulica` z BIR nie są normalizowane (prefiks „ul.” zostaje taki, jak go podaje GUS).
- **Data zawieszenia:** czytana z wyniku wyszukiwania jako `DataZawieszeniaDzialalnosci` (l. 101), zgodnie z `docs/REGONAPILOGIN.md:174`. Implementacja z `great-noether` czyta datę zawieszenia z **raportu pełnego** (`dataZawieszeniaDzialalnosci` z prefiksem `praw_`/`fiz_`). Jeśli wynik wyszukiwania BIR 1.1 tego pola nie zawiera, ostrzeżenie „działalność jest zawieszona” (`Krok5Firma.svelte:114-118`) nigdy się nie pokaże. **Do sprawdzenia na żywym API.** Data zakończenia działalności (`DataZakonczeniaDzialalnosci`) nie jest czytana wcale.
- **PKD** (l. 104–122): `DanePobierzPelnyRaport` z raportem `BIR11OsFizycznaPkd` dla `Typ = F`, w pozostałych przypadkach `BIR11OsPrawnaPkd`. Jednostki lokalne (`LP`, `LF`) dostają więc niewłaściwy raport. Wybierany jest wiersz z `…_pkd_Przewazajace = 1`, a gdy go nie ma – pierwszy wiersz. Kod i nazwa trafiają do `pkd_kod`/`pkd_opis` (format GUS, np. 4 cyfry + litera bez kropki). Błąd tego kroku jest połykany („PKD jest informacyjne”).
- **Odpowiedź 200:** `{ nazwa, regon, adres?, pkd_kod?, pkd_opis?, data_zawieszenia? }`. Pola puste są pomijane.

**Tryb ręczny:** wyłącznie po stronie klienta (`Krok5Firma.svelte:51-59`). Zapisuje `{nip, nazwa, zrodlo:'recznie'}`, a serwer przyjmuje go bez dalszej weryfikacji (`+server.ts:43-52`). Komunikat „zweryfikujemy je po naszej stronie” nie ma pokrycia w kodzie. Weryfikacja odbywa się ręcznie u opiekuna.

**Wariant z gałęzi `great-noether`** (`gus-regon-verification.json`, 223 linie, pakiet „bez zależności”, ESM, działa na Workers):
- **Walidacja offline:** REGON-9 (wagi 8,9,2,3,4,5,6,7), REGON-14 (wagi 2,4,8,5,0,9,7,3,6,1,2,4,8 i poprawny 9-cyfrowy prefiks), NIP i format KRS. Wykrywanie typu identyfikatora (l. 106–158 i `files["gus/regon.js"]`, l. 160).
- **`GusClient`:** środowisko prod/test, timeout 15 s, `login`/`ensureSession`/`logout` (`Wyloguj`), wyszukiwanie po `Regon/Nip/Krs/Regony9zn/Regony14zn/Nipy/Krsy` z escapowaniem XML, `ErrorCode 4` → pusta lista. `ErrorCode 2` → ponowne logowanie i powtórzenie zapytania. Uwaga: rekurencja bez licznika, więc trwale wygasająca sesja zapętliłaby wywołanie. Mapa raportów pełnych według `Typ`/`SilosID` (`P`, `LP`, `LF`, `F/1` CEIDG, `F/2` rolnicza, `F/3` pozostała, `F/4` skreślona do 08.11.2014, `F/6`). Kody błędów 0,1,2,4,5,7 (l. 73–104 i `files["gus/gusClient.js"]`, l. 162).
- **`verifyRegon`** zwraca `{valid, found, active, identifierType, entity, error, raw}`. `entity` ma: `regon`, `nip`, `nipStatus`, `krs`, `name`, `shortName`, formę prawną, `pkdMain`, daty `startDate`, `suspendedFrom`, `resumedFrom`, `endDate`, `deletionDate`, adres w polach (ulica bez „ul.”, kod `NN-NNN`, gmina, powiat, województwo, kraj), `type`, `silosId`. `active = false` przy dacie zakończenia lub skreślenia albo przy zawieszeniu bez wznowienia. Zawsze wylogowuje się w `finally` (l. 163, 177–212; `files["gus/verifyRegon.js"]`).
- **Ograniczenia:** nie pobiera raportów `*Pkd`, a `pkdMain` czyta klucze, których raporty pełne BIR 1.1 zwykle nie mają, więc PKD przeważające praktycznie nie będzie dostępne. Wywołania na żywo „nie zostały zweryfikowane” (l. 214–222, `notes[6]`). Testy offline: 19 asercji.

**Wniosek dla portalu:** połączyć oba warianty:
- z `great-noether`: walidację offline, dobór raportu według `Typ`/`SilosID`, `Wyloguj`, ponowne logowanie z limitem prób i ocenę aktywności (zakończenie, zawieszenie);
- z `branzowe`: pobieranie PKD przeważającego (z właściwymi raportami także dla `LP`/`LF`), cache 24 h i stabilny kontrakt `{nazwa, regon, adres, pkd_kod, pkd_opis, data_zawieszenia}`;
- nowe: rate limit na IP lub sesję i Turnstile przed odpytaniem.

Klucz GUS jest sekretem zleceniodawcy (sekret `GUS_API_KEY`, wartość w konfiguracji, nie w dokumencie).

### 9.3 E-maile (Resend)

`src/lib/serwer/resend.ts` (identyczny w `3c5086f` i `8dc9a90`). Dwa maile wysyłane równolegle (`Promise.allSettled`, l. 107–116):

| | Do klienta | Do opiekuna |
|---|---|---|
| Nadawca | sekret `MAIL_OD`: nazwa wyświetlana „ERGO Życie w Biznesie” + skrzynka funkcyjna w domenie `auraexpert.pl` (`.env.example`; domena zweryfikowana w Resend, `README.md:34`) | to samo |
| Odbiorca | `kontakt.email` z formularza | sekret `MAIL_OPIEKUN` (skrzynka zgłoszeń w domenie `auraexpert.pl`; wartość w konfiguracji, nie w dokumencie) |
| Reply-To | `MAIL_OPIEKUN` (odpowiedź z arkuszem trafia do opiekuna) | e-mail klienta |
| Temat | „Wniosek {nr} przyjęty — ERGO Życie w Biznesie” (l. 55) | „Nowy wniosek {nr}: {nazwa firmy} ({branża}, {N} os.)” (l. 79) |
| Załączniki | `RODO.pdf` i `Informacja-o-dystrybutorze.pdf` zawsze, `lista-ubezpieczonych.xlsx` gdy `struktura` = null | brak |

**Treść maila do klienta, dosłownie** (l. 56–73; HTML: nagłówek z tekstowym logo „ERGO HESTIA” na czerwonej linii; `{…}` to wartości):

> **Dziękujemy — wniosek {nr} jest u nas**
>
> Dzień dobry {imię i nazwisko z formularza},  *(bez imienia: „Dzień dobry,”)*
>
> przyjęliśmy wniosek o grupowe ubezpieczenie na życie **ERGO Życie w Biznesie** dla firmy **{nazwa firmy}** (NIP {nip}). Opiekun odezwie się w ciągu jednego dnia roboczego.
>
> | Wiersz tabeli | Kwota |
> |---|---|
> | Pakiet główny ({branża} · Wariant {I/II/III}) × {N} os. | **{min} / mies.** |
> | {nazwa rozszerzenia, np. „Pakiet Życie · WI”} | {składka} / os. |
> | Szacunek przy {X}% adopcji rozszerzeń | **≈ {szacunek} / mies.** |
> | Widełki (0–100% adopcji) | {min} – {max} |
>
> *(dwa ostatnie wiersze tylko przy rozszerzeniach)*
>
> Wariant „kompletny” (zielone tło): **Wniosek jest kompletny.** Strukturę wiekową już mamy — nie musisz nic odsyłać.
>
> Wariant bez struktury (żółte tło): **Do wystawienia polisy potrzebujemy jeszcze struktury wiekowej zespołu.** W załączniku jest arkusz **lista-ubezpieczonych.xlsx** — wypełnij go i odeślij odpowiedzią na tę wiadomość. Składka się nie zmieni.
>
> Ostateczna składka za rozszerzenia wyjdzie po zebraniu deklaracji od pracowników — każdy sam wskaże, które rozszerzenia bierze.
>
> **Dokumenty produktowe**
> Karty Produktu (PDF): ERGO Życie w Biznesie · Medi Opieka · Global Doctors.
> Pełne Ogólne Warunki Ubezpieczenia (OWU) znajdziesz w zakładce Dokumenty.
>
> W załącznikach przekazujemy informację o przetwarzaniu danych osobowych (RODO) oraz informację o dystrybutorze ubezpieczeń.
>
> Materiał informacyjny — nie jest ofertą w rozumieniu art. 66 k.c. Wiążące są wyłącznie OWU: EZwB 01/25, MA 01/25, GD-GZ 01/25. Ubezpieczyciel: Sopockie Towarzystwo Ubezpieczeń na Życie ERGO Hestia S.A.

Linki „Dokumenty produktowe” prowadzą do `{origin}/dokumenty/karta-produktu-{ergo-zycie-w-biznesie|medi-opieka|global-doctors}.pdf` i `{origin}/dokumenty` (l. 42–51), gdzie `origin` to adres, pod którym przyszło żądanie (`+server.ts:239`).

**Treść maila do opiekuna, dosłownie** (l. 80–90): nagłówek „Nowy wniosek {nr}”, tabela:
- „Firma” – „{nazwa} · NIP {nip}”;
- „Program” – „{branża} · Wariant {I}”;
- „Osób” – „{N}”;
- „Struktura wiekowa” – „podana w kreatorze (wniosek kompletny)” albo „BRAK — klient odeśle arkusz”;
- „Koszt pewny” – „{min} / mies.”;
- „Widełki” – „{min} – {max} / mies.”;
- „Kontakt” – „{imię} · {e-mail jako mailto} · {telefon}”.

Mail **nie zawiera** listy rozszerzeń, stanowiska, planowanego startu, adresu, REGON-u, PKD, zgód marketingowych, struktury ani linku do rekordu. Opiekun, który chce je zobaczyć, musi zajrzeć do bazy.

**Rozbieżności z ekranem „Wniosek przyjęty”** (§3.2): strona mówi „Kopia oferty poszła na…”, ale mail jest potwierdzeniem z podsumowaniem, nie ofertą. Strona każe „wypełnić dane osób przystępujących” (każdy pracownik składa deklarację), a mail i arkusz dotyczą tylko struktury wiekowej.

**Arkusz `lista-ubezpieczonych.xlsx`** (20 394 B, statyczny plik `static/dokumenty/`; analiza XML arkusza, bez otwierania w Excelu). Arkusz to kalkulator struktury wiekowej, a **nie lista imienna ani deklaracja**. Ma 4 zakładki:

| Zakładka | Kolumny | Działanie |
|---|---|---|
| `Struktura` (A1:C53) | `wiek` (18–69, 52 wiersze), `kobieta`, `mezczyzna` | `COUNTIF` po kluczu płeć+wiek z trzech zakładek obliczeniowych |
| `ObliczeniaPESEL` (tabela `ObliczeniaPESEL`, A1:I2) | `PESEL`, `Plec kod`, `Plec`, `Rok`, `Miesiąc`, `Dzień`, `Data Urodzenia`, `Wiek`, `Sklejenie` | wiersz zachęty „Tutaj wklej PESEL klientów”; płeć z 10. cyfry; rok = `LEFT(PESEL,2)` **bez stulecia** (dla PESEL-i z miesiącem +20, czyli urodzonych od 2000 r., data wychodzi błędna) |
| `ObliczeniaDataUrodzenia` (`Tabela3`, A1:D2) | `Data urodzenia [RRRR-MM-DD]`, `Płeć [K lub M]`, `Wiek` = `INT((NOW()-data)/365)`, `Sklejenie` | zachęty „Tu wklej listę z datami urodzenia”, „Tutaj wklej listę z płcią (M lub K)” |
| `ObliczeniaRocznik` (`Tabela4`, A1:D68) | `Rocznik [RRRR]`, `Płeć [K lub M]`, `Wiek` = `YEAR(NOW())-rocznik`, `Sklejenie` | 67 pustych wierszy z formułami (kolumna `Rocznik` A2:A68 pusta); przy pustym roczniku `Wiek` = `YEAR(NOW())-0` daje 2026, a `Sklejenie` „2026” (wartości zapisane w pliku, przeliczane przy otwarciu) |

Uwagi:
- (a) zakres wieku w arkuszu to 18–69, a w programie 15–70;
- (b) wiek liczy się w dniu otwarcia pliku (`NOW()`);
- (c) arkusz zachęca do wklejenia PESEL-i i odesłania mailem, co jest sprzeczne z obietnicą „PESEL-e nie opuszczają tej przeglądarki” i z regulaminem §3 ust. 3. PESEL-e trafiają wtedy na skrzynkę opiekuna, poza bazą;
- (d) metadane pliku (`docProps/core.xml`) zawierają imiona i nazwiska autorów i trzeba je wyczyścić przed użyciem w portalu (nie przepisano ich tutaj).

**Błędy wysyłki:**
- `pobierzZalacznik` (`+server.ts:94-113`) pobiera plik z `ASSETS` Workera. Brak pliku lub błąd → mail idzie bez załącznika (`console.error`).
- Odrzucenie lub `error` z Resend → wpis `mail_blad` z adresem odbiorcy i treścią błędu (`resend.ts:117-121`, `+server.ts:251`). Wyjątek całej funkcji → jeden wpis z `adresat: '-'` (l. 241).
- Nie ma ponawiania ani kolejki (outbox). Ponowienie jest możliwe tylko ręcznie na podstawie `ezb_zdarzenia`.
- Pola w szablonach są wstawiane **bez escapowania HTML** (`imie`, nazwa firmy, e-mail, telefon), §12.

### 9.4 Zgody i RODO – treści, wersje, zapis, administrator (rozstrzygnięcie E5)

**Treści zgód** są identyczne z §3.1 (`src/lib/domena/zgody.ts:14-71`, potwierdzone dosłownie). W pliku jest komentarz: „TODO: treści robocze z prototypu — do zatwierdzenia przez prawnika.” (l. 4). Wersja `2026-07-a` jest wspólna dla 7 zgód. Zmiana treści „wymaga podbicia wersji” (l. 2–3), ale nic tego nie wymusza: wersja to ręcznie wpisany tekst.

**Zapis:** `ezb_wnioski.zgody = { "z1": { "wersja": "2026-07-a", "ts": "<ISO, czas serwera>" }, … }`, tylko zaznaczone zgody (`+server.ts:193-195`). Brak treści, hasha treści, IP i user-agenta. Serwer nie sprawdza, czy wersja jest aktualna, i przyjmuje dowolne dodatkowe kody. Nie ma mechanizmu wycofania zgód marketingowych z6/z7 (ani strony, ani endpointu). W mailu do opiekuna zgód marketingowych nie widać.

**Administrator danych – co mówi kod i dokumenty:**

| Źródło | Kto jest administratorem |
|---|---|
| z3 (`zgody.ts:37`, ekran kroku 6) | „Sopockie Towarzystwo Ubezpieczeń na Życie ERGO Hestia S.A.” |
| `/rodo` (`src/routes/rodo/+page.svelte`, prerender) | „Aura Expert sp. z o.o. (dystrybutor ubezpieczeń). Po przekazaniu wniosku administratorem danych w celu zawarcia i wykonania umowy ubezpieczenia staje się Sopockie Towarzystwo Ubezpieczeń na Życie ERGO Hestia S.A.” (dopisek „Dokument roboczy — wymaga zatwierdzenia przez prawnika przed startem kampanii.”) |
| `rodo.pdf` – załącznik do **każdego** maila klienta („Nota informacyjna RODO zgodnie z art. 13-14 …”, „Warszawa, lipiec 2026”) | „Administratorem danych osobowych jest Aura Expert spółka z ograniczoną odpowiedzialnością (Aura Expert) z siedzibą w Warszawie…”, kontakt do Inspektora Ochrony Danych Aura Expert (e-mail, telefon, adres; wartości w pliku) |
| `/regulamin` §1 | serwis prowadzi Aura Expert jako „Operator”, „dystrybutor ubezpieczeń” |
| przepływ danych w kodzie | wniosek trafia do bazy Supabase projektu „aurabroker” (Aura Expert) i na skrzynkę Aura Expert. **Żaden kod nie przekazuje danych do ERGO Hestii** (brak API ubezpieczyciela; przekazanie robi opiekun poza systemem) |

**Rozstrzygnięcie E5 na podstawie kodu:**
- Na etapie wniosku dane zbiera, zapisuje i obsługuje **Aura Expert**. Trzy źródła (strona `/rodo`, `rodo.pdf` dołączany do potwierdzenia, regulamin) i faktyczny przepływ danych wskazują Aura Expert.
- z3 to pozostałość roboczej treści z prototypu (TODO w `zgody.ts:4`). Jest niespójna z resztą i dodatkowo źle skonstruowana: „zgoda” z podstawą art. 6 ust. 1 lit. b, która zgody nie wymaga.
- **Do portalu:** w miejscu z3 klauzula informacyjna art. 13 z administratorem Aura Expert i informacją, że po przekazaniu wniosku ERGO Hestia staje się odrębnym administratorem w celu zawarcia i wykonania umowy. Klauzula informacyjna to potwierdzenie zapoznania się, a nie zgoda.
- **Otwarte dla prawnika:** czy agent przetwarza dane wniosku jako administrator, czy jako podmiot przetwarzający w imieniu ERGO Hestii (umowa agencyjna).

Dodatkowe błędy w `rodo.pdf`:
- tekst mówi o „wykonywaniu czynności brokerskich” i „prawnie uzasadnionym interesie brokera”, a Aura Expert jest agentem (`informacja-o-dystrybutorze.pdf` pkt 1);
- KRS wskazuje „XII Wydział Gospodarczy”, a `informacja-o-dystrybutorze.pdf` – „XIII Wydział” (por. D38);
- strona `/rodo` deklaruje przechowywanie „w Unii Europejskiej” (Supabase, Resend, Cloudflare). Resend i Cloudflare to podmioty spoza UE, więc wymaga to weryfikacji umów powierzenia i transferu.

**`/regulamin`** (prerender, §1–§4): Operator Aura Expert; charakter informacyjny (nie oferta, art. 66 k.c.); „Złożenie wniosku w serwisie nie jest równoznaczne z zawarciem umowy ubezpieczenia — umowa dochodzi do skutku po potwierdzeniu warunków przez opiekuna i ubezpieczyciela.”; §3 ust. 3 „Numery PESEL wklejane w kroku „struktura zespołu” są przetwarzane wyłącznie lokalnie w przeglądarce użytkownika i nie są przesyłane do Operatora.”; reklamacje na adres kontaktowy z odpowiedzią „w terminie 14 dni”. Regulamin nie odnosi się do arkusza XLSX odsyłanego mailem (§9.3).

### 9.5 Dokumenty `static/dokumenty`

Stan identyczny w `3c5086f` (produkcja) i `8dc9a90`. Dane z `pdfinfo`/`pdftotext`; pliki nie zostały skopiowane (robi to zadanie „docs”).

| Plik | Rozmiar | Strony | Kod / wersja w treści | Gdzie linkowany |
|---|---|---|---|---|
| `owu-ergo-zycie-w-biznesie.pdf` | 2 526 378 B (2,4 MB) | 357 | „Kod: EZwB 01/25”, „Data wejścia w życie: 22.12.2025 r.”; na końcu errata `ER/EHZ01/2602` (Uchwała Zarządu nr WS 03/2026 z 27.01.2026, stosowana od 13.02.2026) | zakładka `/dokumenty`; zgody z1, z2 (tylko kod, bez linku); mail – link do zakładki |
| `owu-medi-opieka.pdf` | 887 652 B | 109 | „Kod: MA 01/25”, w życie 22.12.2025 („stosowane do umów, które zawieramy na ich podstawie od tego dnia”); ta sama errata | `/dokumenty` |
| `owu-global-doctors.pdf` | 926 473 B | 68 | „Kod: GD-GZ 01/25”, w życie 22.12.2025; ta sama errata | `/dokumenty` |
| `karta-produktu-ergo-zycie-w-biznesie.pdf` | 81 779 B | 8 | „Dokument zawierający informacje o produkcie ubezpieczeniowym”, odwołanie do EZwB 01/25 (bez własnego kodu i daty) | `/dokumenty`; link w mailu klienta |
| `karta-produktu-medi-opieka.pdf` | 63 895 B | 4 | jw., MA 01/25 | `/dokumenty`; mail |
| `karta-produktu-global-doctors.pdf` | 83 842 B | 5 | jw., GD-GZ 01/25 | `/dokumenty`; mail |
| `informacja-o-dystrybutorze.pdf` | 79 070 B | 1 | „Aura Expert … – Informacje dotyczące agenta ubezpieczeniowego”, „Warszawa, lipiec 2026”, art. 22 UDU; 9 zakładów, w tym obie spółki ERGO Hestia; KRS „XIII Wydział” | **tylko załącznik maila klienta**; wspomniany na `/o-nas` |
| `rodo.pdf` | 131 697 B | 1 | „Nota informacyjna RODO …”, „Warszawa, lipiec 2026” | **tylko załącznik maila klienta** (nie ma go na `/rodo` ani `/dokumenty`) |
| `lista-ubezpieczonych.xlsx` | 20 394 B | – | brak wersji; utworzony 2018, zmieniony 08.07.2026 (metadane) | załącznik maila klienta, gdy brak struktury (§9.3) |

Poza `static/` leży jeszcze ulotka `dane/Beauty1072026.pdf` (349 188 B, 4 s., stopka `EH-UL- EZB-F-2607`, InDesign 17.06.2026). Nie jest serwowana. Potwierdza składki beauty 58/68/76 zł i MediOpiekę (3 / 2,50 / 2 / 0,80 / 2,80 zł) oraz zdanie „dla przedsiębiorców z wybranym PKD w branży beauty” (§9.8).

Strona `/dokumenty` (`src/routes/dokumenty/+page.svelte`) pokazuje 3 OWU i 3 karty z kodami jak w §3.3 / JSON `dokumenty`. `svelte.config.js:9-17` toleruje 404 dla brakujących `/dokumenty/owu-*.pdf` przy prerenderze, bo pliki były dogrywane ręcznie.

### 9.6 Katalogi zakresu ochrony (zamknięcie E8)

`scripts/tnij-owu.mjs` (uruchamiany w `npm run build`, `package.json`) tnie `dane/owu.json` i `dane/mo.json` na pliki w `static/dane/owu/` (katalog generowany, nie jest w repozytorium):

| Plik wyjściowy | Zawartość | Liczność |
|---|---|---|
| `rozdzialy-ezb.json` | rozdziały EZwB z polami `nr, nazwa, strona, kod, karencja[], wylaczenia[], dokumenty[]`, tylko rozdziały z co najmniej jednym punktem; tekst czyszczony ze stopki „Spis treści Strona NNN” (l. 32–58) | 92 z 103 rozdziałów; 150 punktów karencji, 306 wyłączeń, 415 punktów „dokumenty” |
| `rozdzialy-mo.json` | jw. dla MediOpieki | 13 z 23 rozdziałów; 35 wyłączeń, 0 karencji, 0 dokumentów |
| `powazne-zachorowania.json` | `{_liczba, _lp_ciagle, pozycje[{lp, nazwa, definicja, strona_pdf}]}` | 104 (lp ciągłe) |
| `operacje-1.json` … `operacje-5.json` | `[{lp, nazwa, sekcja, grupa_5podgrup, grupa_3podgrupy, kod_icd9}]`, po 150 (ostatni 2) | 602 operacje w 18 sekcjach; `kod_icd9` pusty we wszystkich |
| `operacje-indeks.json` | `zrodlo`, `liczba` 602, `stawki` (5 podgrup: 100/75/50/25/10 %; 3 podgrupy: 100/60/20 %), `stron` 5, `na_strone` 150 | – |
| `slowniczek.json` | słowniczek **MediOpieki** (`mo.slowniczek`) | 49 haseł (definicji z OWU EZwB nie ma) |
| `owu-meta.json` | `wylaczenia_wspolne_top` (prefiks, liczba wystąpień, pełne brzmienia z listą rozdziałów, l. 80–97), `statystyki`, `mediopieka_statystyki` | 10 najczęstszych wyłączeń |

Źródła:
- `dane/owu.json` (806 122 B): `_zrodlo` „EZB_OWU.pdf (EZwB 01/25)”, „pdfplumber, deterministycznie”; 103 rozdziały (141 punktów „zdarzenia”); `wylaczenia_wspolne_top` (10); `statystyki`; `powazne_zachorowania` (104); `katalog_operacji` (602, „Lp 1–602 ciągłe w obu katalogach, bez luk”); `mediopieka` (kopia `mo.json`).
- `dane/mo.json` (148 917 B): 23 rozdziały (306 punktów „zdarzenia”), słowniczek 49, statystyki.
- `dane/zakres-marketing.json` (21 613 B; kopia w `src/lib/dane/`, osadzana w bundlu):
  - `_meta`: ostrzeżenie „Materiały marketingowe NIE są ofertą…” i liczby deklarowane w ulotkach: 124 świadczenia, 102 jednostki PZ, 87 PZ w Pakiecie Zdrowie, 20 metod leczenia, 5 podgrup, 13 produktów assistance;
  - `warunki_programu` (6 punktów), `pakiety` (10 opisów: slug, jedno zdanie, dla kogo, korzyści, składki wariantów, uwaga o kumulacji);
  - `ograniczenia` (STATUS „KOMPLETNE”, 306/150), `katalog_powaznych_zachorowan` (104), `katalog_operacji` (602);
  - `leczenie_specjalistyczne` (STATUS „CZĘŚCIOWE”, potwierdzone 9 z 20 metod);
  - `slowniczek` (25 haseł, STATUS „WYJAŚNIENIA POTOCZNE — nie są definicjami prawnymi…”).

Zakładki pobierają porcje w przeglądarce (`ZakladkaKatalogi.svelte:33-40`, `ZakladkaOgraniczenia.svelte:39-41`, `ZakladkaSlowniczek.svelte:18`). Znaczników `LUKA`/`BRAK_DANYCH` w danych nie ma. Niespójność do wyjaśnienia: ulotki deklarują 102 jednostki PZ, katalog OWU ma 104 pozycje.

### 9.7 Landingi branżowe, atrybucja kampanii, banery (tylko gałęzie `990b947`+, nie na produkcji)

**Landingi `/branza/[slug]`:**
- 8 stron prerenderowanych (`+page.ts:8, 55`): `beauty`, `budownictwo`, `gastronomia-hotelarstwo`, `ksiegowosc`, `nieruchomosci`, `piekarnictwo`, `stomatologia`, `transport-ladowy`.
- Treści w `src/lib/dane/branze-landing.json`: `naglowek`, `lead`, `kogo` (5 pozycji), 3 `scenariusze` (kod świadczenia + tytuł + opis), `seo_tytul` z `{od}`, `seo_opis`. Kwot w pliku nie ma: strona bierze sumę Wariantu I z cennika i pomija scenariusz, gdy branża nie ma danego świadczenia (`+page.ts:62-71`).
- Strona pokazuje tabelę 13 „kluczowych” świadczeń (`+page.ts:13-27`), składki 3 wariantów, ostrzeżenie o niemonotonicznych wariantach (stomatologia), warunki wejścia i okres oferty z `produkty.json`. Ma `canonical`, `og:*` i dwa CTA do `/wniosek?branza={slug}`. Test spójności: `landing.test.ts`.
- Beauty, dosłownie: nagłówek „Ubezpieczenie grupowe dla salonów beauty”, lead „Fryzjerstwo, kosmetyka, SPA i stylizacja paznokci to praca rękami, w kontakcie z chemią i narzędziem. Program branżowy wycenia to ryzyko osobno, zamiast wrzucać salon do wspólnego cennika usług.”, `kogo`: salony fryzjerskie, gabinety kosmetyczne, SPA i wellness, studia stylizacji paznokci, barber shopy. Scenariusze:
  - „Uraz dłoni przy pracy” (`tu_w_pracy`): „Skaleczenie nożyczkami, brzytwą albo frezarką kończy się szyciem i przerwą w pracy. Świadczenie liczone jest za każdy procent trwałego uszczerbku powstałego w pracy.”
  - „Poważne zachorowanie” (`pz_max`): „Katalog obejmuje ponad sto jednostek chorobowych. Wypłata jest jednorazowa i niezależna od zwolnienia lekarskiego czy zasiłku z ZUS.”
  - „Operacja chirurgiczna” (`operacja`): „Zabieg rozliczany jest w pięciu podgrupach zależnie od jego rozległości. Kwota poniżej dotyczy podgrupy najwyższej.”

  Tytuł SEO: „Ubezpieczenie grupowe dla salonu beauty — składka od {od}”. Opis SEO (`seo_opis`): „Grupowe ubezpieczenie na życie dla salonów fryzjerskich, kosmetycznych i SPA zatrudniających od 2 do 100 osób. Trzy warianty, cennik branżowy, wniosek online.” (Źródło: `src/lib/dane/branze-landing.json`, klucz `beauty`.)
- Strona główna kieruje kafle na landingi zamiast do kreatora. Doszły też `sitemap.xml` (strona główna, 8 landingów, 4 zakładki, dokumenty, o nas, regulamin, RODO; bez `/wniosek`) i `robots.txt` (`Allow: /`, celowo bez `Disallow` dla `/wniosek`, które ma `noindex` w `<head>` i nagłówek `X-Robots-Tag: noindex, follow`, `hooks.server.ts:11-19`).

**Atrybucja** (`src/lib/zrodlo.ts`, migracja `20260904120000_zrodlo_wizyty.sql`):
- Zasada first touch w `sessionStorage['ezb-zrodlo-v1']`, zapis z layoutu przy każdej nawigacji (`+layout.svelte:8-12`).
- Zapisywane pola: biała lista `utm_source/medium/campaign/content/term`, `gclid`, `fbclid`, `msclkid` oraz `wejscie` (ścieżka), `skad` (host odsyłającego, pusty dla własnej domeny) i `ts`. Wartości przycinane do 200 znaków, znaki sterujące usuwane (l. 16–73).
- Wejście bez kampanii i bez odsyłającego nie tworzy rekordu.
- Wysyłka: `zrodlo_wizyty` w ładunku wniosku (`Krok6Zgody.svelte:33`), kolumna `jsonb` z indeksami po `utm_campaign` i `wejscie`. Gdy kolumny brak, wniosek zapisuje się bez niej (§9.1).
- Uwaga RODO: `gclid`/`fbclid`/`msclkid` to identyfikatory internetowe. Deklaracja „bez danych osobowych” (komentarz migracji, `README.md:58-62`) jest dyskusyjna.

**Banery na `/wniosek/dziekujemy`:**
- produkcja: losowo 1 z 12 grafik `utrata-dochodu-{03…10,12…15}-{programista, balerina, aktor, architekt, dentysta, przedsiebiorca, nurkowanie, jacht, narty, rodzina, podroze, dom}.png` z `src/lib/promo/` (wykrywanie `import.meta.glob`); link `https://utratadochodu.pl`, `target=_blank`, `rel=noopener`, `alt=""`;
- `8dc9a90`: te same 12 motywów jako `static/banery/{nazwa}.png`, 1200×628 px, 0,3–1,1 MB każdy. Stałe adresy, bo „z tych samych adresów pobierają je inne serwisy” (`promo.ts:4-6`). Link `https://utratadochodu.pl/?utm_source=partner&utm_medium=display&utm_campaign=permanentlink&utm_content=ergobranzowe&utm_term=wniosek` (`dziekujemy/+page.svelte:59`; commit `5800047` zastąpił wcześniejszy wariant z nazwą grafiki w `utm_content`);
- losowanie w `onMount` (l. 10–14). Test zgodności listy z plikami: `promo.test.ts:6`.

W portalu baner zastępuje wewnętrzny link do formularza UD (W4: bez promocji w e-mailach transakcyjnych; na ekranie podziękowania promocja jest dopuszczalna).

### 9.8 PKD (E7), MediPlan / MediOpieka (E6), deklaracje pracowników (E9) – co mówi kod

- **PKD:**
  - kod tylko **wyświetla** PKD przeważające z GUS (`Krok5Firma.svelte:103-108`) i zapisuje `pkd_kod`/`pkd_opis` w `firma`;
  - nie ma listy kodów PKD dla żadnej branży (brak w `produkty.json`, `branze-landing.json`, `owu.json`) ani reguły porównania. Grep po `pkd` w `src/`, `dane/` (bez treści OWU), `scripts/`, `prototypy/` daje tylko wyświetlanie i teksty;
  - zdania „Sprawdzimy też, czy Twoje PKD mieści się w wybranej branży” (`Krok5Firma.svelte:67-68`) i „trzy warianty, które ERGO Hestia oferuje firmom z Twoim PKD” (`Krok1Branza.svelte:18`) nie mają pokrycia;
  - ulotka beauty mówi tylko „dla przedsiębiorców z wybranym PKD w branży beauty”;
  - **E7 otwarty:** lista kodów musi przyjść od ERGO Hestii.
- **MediOpieka / MediPlan:**
  - składki 3 / 2,5 / 2 / 0,8 / 2,8 zł są w `produkty.json` i potwierdza je ulotka beauty („MediPlan Składka miesięczna od osoby: 2,80 zł”);
  - `mediplan` ma 3 warianty opisowe (podstawowy 10 świadczeń; rozszerzony 15, rehabilitacja 20 zabiegów, USG; maksymalny 20, rehabilitacja 40 zabiegów, TK, MR, USG) i flagę `UWAGA`: „Cennik branżowy podaje jedną składkę 2,80 zł, bez rozbicia na 3 warianty MediPlanu — do potwierdzenia w taryfie.”;
  - UI nie pozwala wybrać wariantu MediPlanu, a serwer liczy 2,80 zł niezależnie od wariantu (`skladka.ts:53-55`);
  - `ARCHITEKTURA.md` §9 pkt 1 traktuje to jako kwestię otwartą;
  - Global Doctors 135 zł, wiek 18–64 tylko informacyjnie (`Krok3Rozszerzenia.svelte:83`).
- **Wersja i okres cennika (E6):**
  - `branze-2607` (seed, stała endpointu); obowiązuje 2026-07-01 – 2026-12-31 (`produkty.json` → `meta.skladki_obowiazuja`, także `pakiety_dodatkowe_do: 2026-12-31`);
  - procedury na 2027 w kodzie nie ma. Strona i landingi po 31.12.2026 nadal pokażą ceny 2026, bo nie sprawdzają daty.
- **Deklaracje pracowników:**
  - poza tekstami (krok 3, krok 6, mail, strona podziękowania, `ARCHITEKTURA.md:161`) w kodzie nie ma niczego: formularza deklaracji, wzoru PDF, zapisu ani tabeli;
  - prototyp zapowiadał odsyłanie „na wnioski@…” (`prototypy/kreator-wniosku.html`), a produkcja każe odpowiedzieć na mail (Reply-To = opiekun);
  - **E9 otwarty:** proces deklaracji odbywa się poza systemem (u opiekuna, na dokumentach ERGO Hestii).

---

## 10. Zamknięcie braków po analizie repozytorium `branzowe`

Stan na 13.11.2026, źródło `aurabroker/branzowe` @ `8dc9a90` (produkcja = `3c5086f`). „Zamknięty” znaczy, że brak wiedzy o kodzie został usunięty. Nie znaczy, że formularz można uruchomić w portalu: o tym nadal decydują W1–W5.

| # | Brak (z `00-braki-i-decyzje.md`) | Status | Dowód / co zostaje |
|---|---|---|---|
| E1 | Kod `/api/wnioski`: walidacje (PESEL), przeliczenie składki, `nr_wniosku`, statusy, `ezb_wnioski`, `cennik_wersja`, `ezb_zdarzenia`, rate limit | **zamknięty** | §9.1: kolejność i walidacje (`+server.ts:19-157`), PESEL (`rodo.ts:26-31`), składka i 409 (l. 159–180), `cennik_wersja` = stała `branze-2607` (l. 14), numer `EZB-RRRR-NNNNNN` (`init.sql:18-19`), statusy bez obsługi w kodzie (l. 33–34), zdarzenia `wyslano`/`atrybucja_pominieta` (tylko `990b947`+, nie na produkcji)/`mail_blad` (l. 243–253). **Rate limitu, Turnstile, honeypota i idempotencji nie ma** |
| E2 | `/api/gus`: dostęp BIR1, mapowanie adresu i PKD, cache | **zamknięty** (klucz celowo poza dokumentem) | §9.2: BIR 1.1 SOAP, nowa sesja na każde zapytanie bez `Wyloguj` (`gus.ts:59-73`), adres (l. 90–100), PKD z raportów `*Pkd` (l. 104–122), cache 24 h (`api/gus/+server.ts:6-27`), kody 400/404/502/503/500. **Zostaje:** klucz GUS od zleceniodawcy albo własny; weryfikacja na żywym API, czy `DataZawieszeniaDzialalnosci` jest w wyniku wyszukiwania; wariant `great-noether` jako baza implementacji portalu |
| E3 | Szablony e-maili, nadawca, szablon XLSX, PDF „Informacja o dystrybutorze” | **zamknięty** | §9.3: tematy i treści dosłownie (`resend.ts:53-92`), nadawca i odbiorcy z sekretów, 3 załączniki, kolumny arkusza; pliki w `static/dokumenty/`. **Zostaje (W4):** kto wysyła z portalu i czy treść ma zostać (rozbieżności: „kopia oferty”, „dane osób przystępujących”, arkusz 18–69 lat, PESEL w arkuszu) |
| E4 | PDF OWU i karty produktu | **zamknięty** | §9.5: 6 plików + `rodo.pdf` + `informacja-o-dystrybutorze.pdf` w repozytorium, kody EZwB 01/25, MA 01/25, GD-GZ 01/25, wejście w życie 22.12.2025, errata ER/EHZ01/2602 od 13.02.2026. Kopiowanie robi zadanie „docs” |
| E5 | Zatwierdzona klauzula art. 13; sprzeczność z3 a `/rodo` | **częściowo** (sprzeczność rozstrzygnięta na podstawie kodu; akceptacja prawnika – otwarta) | §9.4: `/rodo`, `rodo.pdf` (załącznik każdego potwierdzenia), regulamin i przepływ danych wskazują **Aura Expert**; z3 to robocza treść z prototypu (`zgody.ts:4`). Do prawnika: rola agenta (administrator czy podmiot przetwarzający), błędy w `rodo.pdf` („czynności brokerskie”, XII/XIII Wydział), transfer poza UE (Resend, Cloudflare) |
| E6 | Wersja i data cennika, MediPlan, procedura po 31.12.2026 | **częściowo** | §9.1, §9.8: wersja `branze-2607`, 01.07–31.12.2026, ceny z bundla, `ezb_cenniki` tylko migawka; MediPlan 2,80 zł potwierdzony ulotką, ale wariant MediPlanu bez ceny. **Zostaje:** taryfa MediPlanu (3 warianty?) i cennik 2027 |
| E7 | Lista PKD beauty i reguła weryfikacji | **otwarty** | §9.8: kod tylko wyświetla PKD; listy nie ma nigdzie w repozytorium |
| E8 | Katalogi `/dane/owu/*.json` | **zamknięty** | §9.6: struktura 7 typów plików i liczności (92/13 rozdziałów, 104 PZ, 602 operacje w 5 porcjach, 49 haseł MO, 10 wyłączeń wspólnych); źródła `dane/owu.json`, `mo.json`, `zakres-marketing.json` w repozytorium |
| E9 | Proces deklaracji pracowników, odsyłanie arkusza, SLA | **otwarty** (kod potwierdza brak) | §9.8: brak formularza i zapisu deklaracji; arkusz odsyłany odpowiedzią na mail (Reply-To = opiekun, `resend.ts:111`); SLA „jeden dzień roboczy” tylko w tekstach, statusy wniosku nie są prowadzone |
| E10 | Grafiki promo i zdjęcia branż | **częściowo** | §9.7: 12 banerów w repozytorium (`static/banery/`, 1200×628); zdjęcia branż nadal z `trybloom.ai` (`src/lib/obrazy.ts`, TODO M4). W portalu i tak własne grafiki |

**Nowe ustalenia, które warto dopisać do `00-braki-i-decyzje.md`** (ten plik edytują inne workflow, więc tu tylko lista):
- (a) produkcja EZB działa z niescalonej gałęzi PR #1; najnowsze zmiany (landingi, atrybucja, banery z UTM) nie są wdrożone;
- (b) wnioski EZB leżą w projekcie Supabase „aurabroker”, ale **nie trafiają do CRM** (§11);
- (c) brak Turnstile, rate limitu i idempotencji, a do tego mail z marką na dowolny adres z treścią sterowaną przez wysyłającego (§12);
- (d) arkusz XLSX zachęca do odsyłania PESEL-i mailem, wbrew obietnicy z kroku 4 i regulaminu;
- (e) statusy `ezb_wnioski` nigdy się nie zmieniają;
- (f) ostrzeżenie o zawieszonej działalności prawdopodobnie martwe (do weryfikacji);
- (g) z3 do zastąpienia klauzulą Aura Expert;
- (h) `rodo.pdf` zawiera słownictwo brokerskie i rozbieżny wydział KRS.

## 11. Integracja z CRM (`aurabroker/crmaura`)

**Stan faktyczny: wnioski EZB nie trafiają do CRM.**
- Tabele `ezb_cenniki`, `ezb_wnioski`, `ezb_zdarzenia` utworzono ręcznie w projekcie Supabase „aurabroker”. To ta sama baza i ten sam schemat `public`, z którego korzysta CRM (`crm_*`), aplikacja UD (`ud_*`) i inne (commit `438d70a`).
- Repozytorium `crmaura` nie zawiera ani jednej referencji do `ezb_`: zero trafień w `supabase/migrations/*` (63 pliki) i w `src/` (w tym `src/lib/types/database.ts`, ręcznie pisane typy dla `crm_*`, `apk_*`, `bond_*`).
- Nie ma też migracji `ezb_*` w CRM. Żaden inny klon w `/home/user/aurabroker/*` nie czyta `ezb_wnioski`.
- Opiekun dowiaduje się o wniosku **wyłącznie z maila** na skrzynkę zgłoszeń (§9.3). Wniosek nie tworzy klienta (`crm_clients`), leada (`crm_prospects`), zgłoszenia (`crm_zgloszenia`) ani zadania (`crm_tasks`).

**Wzorzec, który już działa w CRM dla UD** (`crmaura/supabase/migrations/20261019000002_ud_leady_do_crm.sql`, zastosowana 19.10.2026):
- triggery na `ud_clients` i `ud_leady` oraz cron co godzinę zakładają lub dopasowują klienta (e-mail, potem telefon), lead w Sprzedaży (`crm_prospects`, zainteresowanie i źródło `utrata_dochodu`) i zgłoszenie `crm_zgloszenia` (ref `ud:<id>`);
- mapują etapy (nowy → Nowy, kontakt → W kontakcie, oferta/decyzja → Oferta wysłana, wygrany/sprzedaż → Wygrany, przegrany → Przegrany);
- firma docelowa jest wybierana flagą `crm_tenants.features.ud_leady`;
- powiązanie trzyma tabela `crm_ud_leady` z RLS po `get_my_tenant_id()`;
- dane medyczne zostają w aplikacji.

Kody zainteresowań CRM obejmują już `grupowe` (`crmaura/src/lib/sprzedaz.ts:4`; `20261012000001_sprzedaz_leady_zgloszenia.sql`, nagłówek). Etapy leada: `nowy`, `w_kontakcie`, `oferta_wyslana`, `wygrany`, `przegrany` (tamże, l. 93–95, 353).

**Statusy – proponowane mapowanie** (`ezb_wnioski.status` → `crm_prospects.status`):

| EZB | CRM |
|---|---|
| `nowy` | `nowy` |
| `przekazany` | `w_kontakcie` |
| `oferta` | `oferta_wyslana` |
| `polisa` | `wygrany` |
| `odrzucony` | `przegrany` |

Dziś po stronie EZB nikt statusów nie zmienia, więc w praktyce synchronizacja będzie jednokierunkowa: CRM → `ezb_wnioski.status`, albo `ezb_wnioski` przestaje być miejscem prowadzenia statusu.

**Wnioski dla decyzji W1 (EZB):**
1. **Nie wołać `https://ergo.auraexpert.pl/api/wnioski` z portalu.** Endpoint nie ma uwierzytelnienia ani sekretu serwer–serwer. Wysłałby klientowi mail z marką „ERGO HESTIA”, linkami do `ergo.auraexpert.pl` i arkuszem. Na strefie działa Cloudflare challenge, a wywołanie Worker → Worker nie przejdzie wyzwania JS (do sprawdzenia). Formularz EZB nie ma też żadnych danych szczególnych ani PESEL-i (tylko agregat), więc jest najprostszym kandydatem do wariantu A/C.
2. **Rekomendacja (wariant C):**
   - portal przyjmuje wniosek u siebie (Zod według §9.1, przeliczenie `wyliczSkladke`, `zawieraPesel`, Turnstile, honeypot, rate limit, klucz idempotencji) i zapisuje kopertę zgód z hashem treści;
   - zapis do `ezb_wnioski` idzie przez **dedykowaną funkcję** w projekcie „aurabroker” (np. RPC `ezb_przyjmij_wniosek(p_hash, p_wniosek)` z kluczem integracji jak `crm_klucze_integracji`, które trzymają tylko skrót SHA-256), a nie przez klucz `service_role` w Workerze portalu;
   - kanał oznaczyć w `zrodlo_wizyty` (np. `utm_source: "beautypolisa"`, `wejscie: "/grupowe-ergo"`) albo w nowej kolumnie `kanal`. To wymaga potwierdzenia, że migracja `20260904120000` jest wykonana.
3. **Dołożyć synchronizację EZB → CRM** na wzór UD:
   - trigger na `ezb_wnioski`: klient-firma dopasowany po NIP; lead z `zainteresowania = {grupowe}` i źródłem np. `ergo_ezb`; zgłoszenie z ref `ezb:<nr_wniosku>`; notatka ze składką, wariantem, rozszerzeniami i informacją, czy jest struktura;
   - dla firmy, którą CRM już zna, zgłoszenie „ponowne” z zadaniem na dziś;
   - wtedy opiekun ma wniosek w CRM niezależnie od maila, a statusy mają jedno miejsce prowadzenia. Uwaga: `wariant` w bazie jest 1–3, a warianty pakietów 0–2 (§9.1).
4. **E-maile (W4):** jeśli zapis idzie przez RPC, maile wysyła portal (Resend, outbox, szablony w stylistyce portalu, bez banerów). Treść, arkusz i PDF-y z §9.3 do ponownego użycia po poprawkach (escapowanie, arkusz bez PESEL lub z obsługą wieku 15–70, `rodo.pdf` po korekcie).

## 12. Bezpieczeństwo – ustalenia z dowodami

| # | Ustalenie | Dowód | Waga | Co w portalu |
|---|---|---|---|---|
| B1 | Publiczny `POST /api/wnioski` bez Turnstile, honeypota, rate limitu i idempotencji; każde wywołanie to `INSERT` z kluczem `service_role` i dwa maile | `+server.ts:134-255`; `hooks.server.ts` (tylko robots); brak w `wrangler.jsonc` | wysoka | standard 02 §2.2: honeypot → idempotencja → rate limit → Zod → Turnstile (`siteverify` z `hostname`/`action`) |
| B2 | Mail z marką ERGO HESTIA i domeną `auraexpert.pl` (DKIM) wysyłany **na dowolny adres** podany w formularzu, z załącznikami PDF i treścią częściowo sterowaną przez wysyłającego (imię, nazwa firmy w trybie ręcznym). Gotowy kanał phishingu i spamu z zaufanej domeny | `resend.ts:53-75, 107-114`; `+server.ts:226-241`; brak B1 | wysoka | wysyłka dopiero po Turnstile; limit maili na adres i IP; ewentualnie potwierdzenie adresu przed wysyłką załączników |
| B3 | Brak escapowania HTML w szablonach (`imie`, `firmaNazwa`, `email`, `telefon`, nazwy z GUS) – wstrzyknięcie linków lub HTML w mail do klienta i opiekuna | `resend.ts:30, 58-61, 79-89` | wysoka | escapowanie wszystkich pól, szablony z silnikiem escapującym |
| B4 | Worker trzyma klucz `service_role` projektu współdzielonego z CRM (`crm_*`), UD (`ud_*`) i innymi. Kompromitacja Workera EZB lub jego sekretów daje pełny dostęp do CRM | `supabase.ts:8-12`; commit `438d70a`; `README.md:29-30` | wysoka | portal bez `service_role` do „aurabroker”; dedykowana funkcja z kluczem integracji i minimalnymi uprawnieniami (§11) |
| B5 | `/api/gus` bez limitu – otwarte proxy do BIR na kluczu Aura Expert (zużycie limitu GUS, enumeracja NIP). Każde zapytanie spoza cache otwiera sesję BIR bez `Wyloguj`; timeout kończy się 500 | `api/gus/+server.ts:8-33`; `gus.ts:38, 59-66` | średnia | rate limit, Turnstile lub token sesji formularza, `Wyloguj` lub współdzielona sesja, mapowanie timeoutu na 502 |
| B6 | Dane osobowe w logu zdarzeń: `mail_blad` zapisuje adres e-mail odbiorcy i treść błędu; `console.error` przy błędzie zapisu | `+server.ts:220, 251`; `resend.ts:117-121` | średnia | log bez PII (hash adresu), retencja |
| B7 | Zgody bez rozliczalności: tylko kod, wersja i czas serwera; brak treści lub hasha, IP, UA; wersja i nieznane kody nieweryfikowane; brak wycofania z6/z7 | `+server.ts:60, 155-157, 193-195`; `zgody.ts:2-4` | średnia (RODO art. 7 ust. 1) | rejestr zgód z hashem treści (W3) |
| B8 | Negatywna walidacja PESEL to heurystyka: PESEL z separatorami przechodzi, a 14-cyfrowy REGON lub e-mail z 11 cyframi daje fałszywe odrzucenie. Równolegle arkusz XLSX prosi o PESEL-e mailem | `rodo.ts:18-30`; `lista-ubezpieczonych.xlsx` (`ObliczeniaPESEL`) | średnia | normalizacja cyfr przed testem i wyłączenie pól o znanym formacie (`nip`, `regon`); arkusz bez PESEL |
| B9 | E-mail w adresie strony podziękowania (`?email=`) – historia, logi CDN, `Referer` (baner prowadzi na zewnętrzną domenę) | `Krok6Zgody.svelte:44-46`; `dziekujemy/+page.svelte:7, 59` | niska–średnia | numer i adres przez stan lub sesję, nie query |
| B10 | Szczegóły błędów pokazywane użytkownikowi (do 200 znaków odpowiedzi, komunikaty Zod) | `Krok6Zgody.svelte:36-39, 119-122`; `+server.ts:145` | niska | komunikat ogólny + identyfikator zdarzenia |
| B11 | Serwer ufa danym firmy z klienta (`zrodlo:'gus'` z dowolną nazwą/REGON/PKD), brak ponownej weryfikacji GUS i statusu działalności | `+server.ts:43-52` | niska–średnia | ponowne odpytanie GUS po stronie serwera przy zapisie (z cache) |
| B12 | Cennik w bundlu i stała wersja w kodzie – ryzyko rozjazdu z `ezb_cenniki`; brak blokady wniosków po 31.12.2026 | `+server.ts:13-14`; `seed-cennika.mjs:20-24`; `produkty.json` `meta.skladki_obowiazuja` | niska (biznesowo średnia) | cennik z wersją i datami obowiązywania, odrzucanie po dacie (W6) |
| B13 | Brak nagłówków bezpieczeństwa (CSP, `Referrer-Policy`, `Permissions-Policy`) w kodzie; zasoby zewnętrzne: Google Fonts (`app.html:7-11`) i zdjęcia `trybloom.ai` (`obrazy.ts`) – transfer IP do podmiotów trzecich | `src/app.html`, `src/hooks.server.ts`, `src/lib/obrazy.ts` | niska | CSP portalu, lokalne fonty i obrazy |
| B14 | Proces wdrożenia: produkcja z niescalonej gałęzi PR #1, ręczny `wrangler deploy`, `main` bez kodu, CI bez deployu | §9.0; `.github/workflows/ci.yml:23-36` | niska (ryzyko operacyjne) | – (dotyczy zleceniodawcy) |
| B15 | `gclid`/`fbclid`/`msclkid` w `zrodlo_wizyty` opisane jako „bez danych osobowych”, a to identyfikatory internetowe; zbierane bez zgody cookies | `zrodlo.ts:8-10, 16-25`; migracja `20260904120000` | niska | w portalu atrybucja zgodna z Consent Mode portalu |

Pozytywne (zachować w portalu):
- PESEL-e liczone lokalnie, do serwera idzie tylko agregat (`pesel.ts`, `Krok4Struktura.svelte`), a serwer to egzekwuje;
- klucze tylko w sekretach Workera, brak klucza Supabase w przeglądarce, RLS bez polityk dla `anon` (`init.sql:50-53`);
- przeliczenie składki po stronie serwera (`+server.ts:159-180`);
- zapis wniosku nie przepada przy awarii maila lub przy braku kolumny atrybucji;
- `noindex` + `X-Robots-Tag` na krokach lejka;
- w repozytorium i historii `.env.example` nie ma wartości sekretów (sprawdzone), a `docs/REGONAPILOGIN.md` zawiera tylko przykładowy identyfikator sesji.

### Poprawki naniesione w tym pliku 13.11.2026

- Nagłówek i `_zrodlo` (JSON): aplikacja to SvelteKit z `@sveltejs/adapter-cloudflare` (Workers), a nie `adapter-static`. Kreator działa bez SSR (`src/routes/wniosek/+page.ts:4`). Dopisano, że produkcja = gałąź PR #1 (`3c5086f`).
- §4 i JSON `produkt.uwaga_wersja`: `ezb_cenniki` nie jest tabelą CRM, tylko tabelą aplikacji EZB w projekcie Supabase „aurabroker” (wspólnym z CRM). Serwer i tak liczy z cennika w bundlu.
- §5: w przykładowym ładunku `firma.data_zawieszenia` nie jest wysyłane jako `null`. GUS pomija pole (`gus.ts:101`), a serwer odrzuciłby `null` (`optional`, nie `nullable`). Dopisano odwołania do §9.1–§9.2.
- §6: „kodu brak” przy GUS zastąpione odwołaniem do §9.2; `ezb_zdarzenia` zasila tylko `/api/wnioski` (3 typy zdarzeń, §9.1); katalogi `/dane/owu/*.json` opisane w §9.6.
- §3.3: pliki PDF są w repozytorium (§9.5).
- §7 i §8: dopisano stan po analizie repozytorium. Większość punktów §7 jest zamknięta (§10). Ryzyka z §8 potwierdzone i rozszerzone w §12.

---

## Weryfikacja krytyka kompletności (2026-11-13)

Sprawdzone w kodzie i **potwierdzone**: cennik beauty 58/68/76 zł i `skladka_zgon` 15,59/14,06/12,08 (`s4z72ZNe.js` l. 548); liczba świadczeń 32/44/57 (przeliczone z literału); wzór `K()` (min/max/szacunek) i błędy „Nieznana branża”, „Adopcja poza zakresem 0–1”; walidacje kroku 5 (`Ue`: wagi NIP, `imie.trim().length > 2`, `/.+@.+\..+/`, ≥ 9 cyfr telefonu); ładunek `POST /api/wnioski` i przejście na `/wniosek/dziekujemy?nr&email&kompletny` (`kompletny = !!struktura`); wersja zgód `2026-07-a`; klucz `ezb-wniosek-v1`; suwak `range 0–100 step 5`, domyślnie 0,5.

**Poprawione:** w JSON pole `adopcja` miało `krok: 5` (poprawnie: krok 3, Rozszerzenia). W §2 dopisano etykiety pól kroku 5 (wcześniej podane były placeholdery jako etykiety) oraz szczegóły parsera struktury (data odniesienia wieku, płeć z PESEL, brak sprawdzenia istnienia daty `RRRR-MM-DD`).

Pominięć w krokach, zgodach ani taryfach nie znaleziono.
