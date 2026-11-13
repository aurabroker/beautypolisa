# ERGO Życie w Biznesie: wniosek grupowy dla branży beauty (inżynieria wsteczna)

Źródło: kod kliencki `https://ergo.auraexpert.pl/wniosek?branza=beauty` (SvelteKit, SPA, `ssr: false` w węźle trasy `/wniosek`). Analizowane pliki (kopie po prettier w `specs/tmp/ezb/`):

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

Dane strukturalne do makiety: `specs/ergo-zycie-w-biznesie.json` (kroki, pola, opcje, pełny cennik wszystkich 8 branż, rozpisane karty wariantów i tabela świadczeń dla beauty, mediopieka, Global Doctors, 11 pakietów dodatkowych, zgody, słowniczek, opisy pakietów, dokumenty).

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

**Krok 1:** „Jaka to branża?”. Podtytuł: „Składki i zakres różnią się między branżami — to nie jest jeden cennik z rabatem. Wybierz swoją, a zobaczysz dokładnie te trzy warianty, które ERGO Hestia oferuje firmom z Twoim PKD.” Ramka czerwona: „**Zanim wybierzesz branżę:** program działa wyłącznie dla firm zatrudniających **od 2 do 100 osób**, w wieku 15–70 lat. Poniżej i powyżej tego progu opiekun przygotuje ofertę indywidualną.” Notka: „**Nie ma Twojej branży?** Oferta branżowa obejmuje wybrane kody PKD. Dla pozostałych firm przygotujemy ofertę standardową — [zostaw kontakt](mailto:zgloszenie@auraexpert.pl).” Kafel: „od **{min}** / os. / mies.”

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
- Stopka: „Aura Expert sp. z o.o. ul. Bolkowska 2A lok. 28, Warszawa · KRS 0000599840 · REGON 363673048 / Rejestr Pośredników Ubezpieczeniowych: 11229690/A / Kontakt: zgloszenie@auraexpert.pl” oraz „Materiał informacyjny — nie jest ofertą w rozumieniu art. 66 k.c. Wiążące są wyłącznie OWU: EZwB 01/25, MA 01/25, GD-GZ 01/25. Ubezpieczyciel: Sopockie Towarzystwo Ubezpieczeń na Życie ERGO Hestia S.A.”
- Nagłówek: „Grupowe ubezpieczenie na życie · 2–100 osób / ERGO Życie w Biznesie · oferta branżowa 1.07–31.12.2026”.
- Strona RODO (`nodes/6`), dosłownie: „Administratorem danych zbieranych w tym serwisie jest Aura Expert sp. z o.o. (dystrybutor ubezpieczeń). Po przekazaniu wniosku administratorem danych w celu zawarcia i wykonania umowy ubezpieczenia staje się Sopockie Towarzystwo Ubezpieczeń na Życie ERGO Hestia S.A. […] 1. Dane firmy (NIP, nazwa, adres, PKD — pobierane z rejestru REGON) oraz dane osoby kontaktowej (imię i nazwisko, e-mail, telefon, stanowisko) — w celu przygotowania i obsługi wniosku o ubezpieczenie (art. 6 ust. 1 lit. b RODO). 2. Zbiorczą strukturę wiekową zespołu — wyłącznie liczbę osób danej płci w danym roczniku. Numery PESEL nie opuszczają Twojej przeglądarki: są przeliczane lokalnie na agregat, a nasz serwer aktywnie odrzuca każde zgłoszenie zawierające numer PESEL. 3. Zgody marketingowe (jeśli ich udzielono) — na podstawie art. 6 ust. 1 lit. a RODO; można je wycofać w każdej chwili. […] Dane przechowujemy w Unii Europejskiej: baza danych Supabase (region UE), wysyłka e-maili Resend, infrastruktura Cloudflare. Dane wniosku przekazujemy ubezpieczycielowi — ERGO Hestii. […] Dane wniosków przechowujemy przez okres wymagany przepisami o dystrybucji ubezpieczeń. Masz prawo dostępu do danych, ich sprostowania, usunięcia, ograniczenia przetwarzania, przenoszenia oraz wniesienia skargi do Prezesa UODO.” Strona ma dopisek: „**Dokument roboczy — wymaga zatwierdzenia przez prawnika przed startem kampanii.**”
- Regulamin (`nodes/5`) §1–§4 i O nas (`nodes/4`) są w kodzie. Pełne teksty są w kopiach plików; O nas wspomina dokument „Informacja o dystrybutorze”, dołączany do potwierdzenia (serwer).
- Dokumenty PDF (`nodes/3`): 3 OWU i 3 Karty Produktu pod `/dokumenty/*.pdf` (lista w JSON). **Same pliki PDF nie zostały pobrane.**

---

## 4. Logika cen i taryf

**Źródło cennika:** cennik jest **osadzony w JS** (`chunks/s4z72ZNe.js`, stała `H = {swiadczenia, grupy, branze, mediopieka, global_doctors, pakiety_dodatkowe}`). Lista `branze` jest wpisana jako `JSON.parse('<literał>')`. Klient niczego nie pobiera z API. **Nie ma pola `meta` ani numeru wersji** (w CRM `ezb_cenniki` ma wersję `branze-2607` i pole `meta`). Dane wyciągnięto parserem AST (acorn), bez wykonywania kodu.

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

**`GET /api/gus?nip={10 cyfr}`**, bez nagłówków i tokenu. Kod oczekuje JSON z polami `nazwa, regon, adres, pkd_kod, pkd_opis, data_zawieszenia` (innych nie używa, ale cały obiekt wraca w `firma`). Statusy: 404 → „nie znaleziono”, inny nie-OK lub wyjątek → „awaria”. Stan: `gus = {...odp, nip, zrodlo:'gus'}`.

**`POST /api/wnioski`**, `content-type: application/json`, ciało:
```json
{
  "branza": "beauty",
  "wariant": 0,
  "rozszerzenia": { "medi": ["assistance-medyczny"], "gd": false, "pakiety": { "zycie": 0 } },
  "zalozona_adopcja": 0.5,
  "liczba_osob": 10,
  "struktura": [{ "rok": 1985, "plec": "K", "liczba": 2 }],
  "firma": { "nazwa": "…", "regon": "…", "adres": "…", "pkd_kod": "…", "pkd_opis": "…", "data_zawieszenia": null, "nip": "…", "zrodlo": "gus" },
  "kontakt": { "imie": "", "stanowisko": "", "email": "", "telefon": "", "start": "" },
  "zgody": { "z1": { "wersja": "2026-07-a" }, "…": {} },
  "skladka_klienta": { "min": 580, "max": 730, "szacunek": 655 }
}
```
- `zgody` zawiera **tylko zaznaczone** kody, bez znacznika czasu (czas, IP i user-agent musi dodać serwer).
- Ładunek nie ma wersji cennika, nr wniosku ani `baza`; mapowanie na kolumny `ezb_wnioski` (`cennik_wersja`, `skladka`, `nr_wniosku`, `status`) robi serwer.
- Odpowiedź OK: JSON `{ nr_wniosku }`. Potem `sessionStorage.removeItem('ezb-wniosek-v1')` i przejście na `/wniosek/dziekujemy?nr=…&email=…&kompletny=0|1` (`kompletny=1` gdy `struktura` niepusta).
- Błąd: tekst „{status}: {treść[0..200]}” wyświetlony użytkownikowi.

**Turnstile:** **brak** w kodzie (żadnego widgetu, tokenu ani nagłówka). Jest tylko skrypt Cloudflare JS challenge wstrzyknięty przez CDN w `index.html`. **Honeypot:** brak. **Szkice i przypomnienia:** brak. Szkic istnieje tylko lokalnie w `sessionStorage` i ginie po zamknięciu karty. Nie ma zapisu częściowego wniosku na serwerze ani e-maila przypominającego.

---

## 6. Logika poboczna

- **GUS:** wyłącznie przez `/api/gus` (proxy po stronie serwera, kodu brak).
- **Analityka:** brak (GA, gtag, Plausible, PostHog, dataLayer, sendBeacon nie występują). **`ezb_zdarzenia`:** klient nie wysyła żadnych zdarzeń i nie ma endpointu zdarzeń. Tabela jest zasilana po stronie serwera (np. przez `/api/wnioski` lub `/api/gus`) albo nieużywana. Do ustalenia.
- **Storage:** `sessionStorage['ezb-wniosek-v1']` z polami `krok, branza, wariant, medi, gd, pakiety, adopcja, tryb, liczbaOsob, struktura, gus, kontakt, zgody`. Nie są zapisywane: surowa lista PESEL, `statystyki`, `pokaz3`, `wysylka`. Nie ma `localStorage`.
- **Przekierowania i linki zewnętrzne:** po sukcesie przejście na `/wniosek/dziekujemy`. Baner promo prowadzi do `https://utratadochodu.pl`; w BeautyPolisie trzeba go zastąpić wewnętrznym formularzem utraty dochodu. Kafle branż ze strony głównej linkują do `/wniosek?branza={slug}`. `mailto:zgloszenie@auraexpert.pl` pojawia się w kroku 1, w stopce i na stronach prawnych.
- **Obrazy:** kafle branż pochodzą z `https://www.trybloom.ai/img/...` (zewnętrzny hosting, `SM48GHmE.js`), grafiki promo są w assetach (`utrata-dochodu-03…15.png`), ale **nie zostały pobrane**.
- **Zakres ochrony** (`nodes/9`): zakładki `pakiety, katalogi, ograniczenia, slowniczek`. Opisy 10 pakietów i 25 haseł słowniczka są osadzone (w JSON). Katalogi OWU są pobierane z `/dane/owu/{powazne-zachorowania, operacje-indeks, operacje-1..N, rozdzialy-ezb, rozdzialy-mo, owu-meta, slowniczek}.json`; **tych plików nie mamy**.

---

## 7. Czego nie da się odtworzyć z kodu klienckiego (do uzyskania od zleceniodawcy)

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

---

## Weryfikacja krytyka kompletności (2026-11-13)

Sprawdzone w kodzie i **potwierdzone**: cennik beauty 58/68/76 zł i `skladka_zgon` 15,59/14,06/12,08 (`s4z72ZNe.js` l. 548); liczba świadczeń 32/44/57 (przeliczone z literału); wzór `K()` (min/max/szacunek) i błędy „Nieznana branża”, „Adopcja poza zakresem 0–1”; walidacje kroku 5 (`Ue`: wagi NIP, `imie.trim().length > 2`, `/.+@.+\..+/`, ≥ 9 cyfr telefonu); ładunek `POST /api/wnioski` i przejście na `/wniosek/dziekujemy?nr&email&kompletny` (`kompletny = !!struktura`); wersja zgód `2026-07-a`; klucz `ezb-wniosek-v1`; suwak `range 0–100 step 5`, domyślnie 0,5.

**Poprawione:** w JSON pole `adopcja` miało `krok: 5` (poprawnie: krok 3, Rozszerzenia). W §2 dopisano etykiety pól kroku 5 (wcześniej podane były placeholdery jako etykiety) oraz szczegóły parsera struktury (data odniesienia wieku, płeć z PESEL, brak sprawdzenia istnienia daty `RRRR-MM-DD`).

Pominięć w krokach, zgodach ani taryfach nie znaleziono.
