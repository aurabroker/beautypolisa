# ERGO Razem – Grupa Otwarta (ergo.beautypolisa.eu) – specyfikacja odtworzona z kodu klienckiego

Źródło: https://ergo.beautypolisa.eu/ (Next.js App Router, Turbopack). Analiza wyłącznie tekstowa pobranych plików (kod nie był uruchamiany). Kopie sformatowane prettierem: `specs/tmp/er/*.js`. Dane strukturalne: `ergo-razem-grupa-otwarta.json` (ten sam katalog).

**Najważniejsze w skrócie**

- W kodzie klienckim **są**: pełne tabele składek (3 grupy wiekowe × 3 produkty × warianty), ceny dodatków (MediPlan 9 zł, Medical Assistance 6 zł; Global Doctors bez ceny), wzór składki, reguła grup wiekowych, **pełne tabele świadczeń** (sumy, karencje) dla wszystkich wariantów, FAQ z odpowiedziami, szczegóły MediPlan/Medical Assistance (świadczenia, limity, wyłączenia, procedura, definicje), lista 57 zachorowań z kategoriami i zakresami.
- W pobranych plikach **nie ma** kodu kroków 2–6 (Ankieta, Weryfikacja, Oferta, Podsumowanie, Gotowe) ani strony `/wykluczenie/wiek`. Dlatego **nie da się odtworzyć**: pytań ankiety medycznej i reguł kwalifikacji, formularza kontaktowego (pola, walidacje), treści zgód i klauzul, wysyłki (server actions), Turnstile (sitekey, weryfikacja), ekranu sukcesu. Pobrane chunki to tylko: strona główna, FAQ, MediPlan/Medical Assistance, krok „Wiek” i wspólny runtime.
- W dostępnych plikach nie znaleziono kluczy (Supabase, Turnstile) ani adresów API.

### Sprawdzone pliki

| Plik | Zawartość (ustalona) |
|---|---|
| `src/er/31gj1ymm-1tvb.js` | **Krok 1 „Wiek”** (`/kalkulator/wiek`), store Zustand `useCalculatorStore` (moduł 3157), stałe `ADDONS`, `PREMIUMS`, `PRODUCT_LABELS`, `VARIANT_LABELS` (moduł 14887), funkcje `calcMonthlyPremium`, `getAgeGroup`, `getVariants`, `isGlobalDoctorsEligible` (moduł 84869), date-fns |
| `src/er/2x0a9fqp2d2bg.js` | Komponent `Stepper` (6 kroków i ich ścieżki), `clsx` |
| `src/er/0vqvpp9_0rpw6.js` | Strona główna `/`: `SiteHeader`, `SiteFooter`, tabele świadczeń + `getBenefits` (moduł 19489), kopia `PREMIUMS`/`ADDONS`, karty produktów, pole „Twój wiek” |
| `src/er/299pqtzg76wfe.js` | Strona `/faq` – pytania **i odpowiedzi** |
| `src/er/39ohoz70_awj_.js` | Strona `/ubezpieczenia-dodatkowe` – pełne dane MediPlan i Medical Assistance |
| `src/er/0cz1d0mv5g_q7.js`, `11oof8oxnxiv9.js`, `2nykiepra7i1k.js`, `27jktro2p5rq9.js`, `14mrh2-p_w84d.js`, `261y1hxfsqgcm.js`, `05-c3ty_6dwfk.js`, `turbopack-0ltocwye_fv3h.js` | Runtime: polyfille core-js, React/ReactDOM, router Next.js (tu `createServerReference`/`callServer` – ogólny mechanizm, bez ID akcji), strona błędu („This page couldn’t load”), dev-overlay; brak logiki biznesowej |
| `src/er/chunks.txt` | Lista 13 pobranych chunków |
| `ergo/go.md`, `go.html` | Tekst strony głównej |
| `ergo/go_kalkulator_wiek.md/.html` | Krok „Wiek” (SSR) + payload RSC (potwierdza chunki `2x0a9fqp2d2bg`, `31gj1ymm-1tvb`) |
| `ergo/go_faq.md/.html` | FAQ (same pytania; odpowiedzi tylko w chunku) |
| `ergo/go_katalog-zachorowan.md/.html` | Katalog 57 zachorowań (lista, kategorie, znaczniki MAX/MŁŻ/DZI); **definicje są w niepobranym chunku `03amb72-bgjst.js`** |
| `ergo/go_ubezpieczenia-dodatkowe.md/.html` | MediPlan/Medical Assistance (widoczna zakładka) |
| `ergo/go_global-doctors.md/.html` | Global Doctors (tekst) |
| `ergo/go_informacja-o-agencie.md/.html` | Informacja o agencie (art. 22 UDU); chunk strony `1rxncug86bump.js` niepobrany, ale tekst jest w SSR |
| `ergo/branzowe.html` | **Nie dotyczy tej aplikacji**: pusta powłoka aplikacji SvelteKit (inna technologia) + skrypt Cloudflare challenge-platform (JSD); brak treści |

Niepobrane, a potrzebne: chunki stron `/kalkulator/ankieta`, `/kalkulator/weryfikacja`, `/kalkulator/produkt`, `/kalkulator/podsumowanie`, `/kalkulator/sukces`, `/wykluczenie/wiek`, `/zglos-roszczenie`, `/rodo`, `/polityka-prywatnosci`, `/regulamin`, `/global-doctors` oraz `03amb72-bgjst.js` (katalog z definicjami).

---

## 1. Przegląd i kroki

Kalkulator orientacyjnej składki + zostawienie danych kontaktowych, po których agent ERGO Hestia oddzwania (z treści: „Zostawiasz dane kontaktowe — agent ERGO Hestia skontaktuje się w 1–2 dni.”). Wynik kalkulatora nie jest wiążącą ofertą (FAQ).

Kroki (`2x0a9fqp2d2bg.js`, komponent `Stepper`, tablica `r`):

| # | Etykieta | Ścieżka | Kod w pobranych plikach |
|---|---|---|---|
| 1 | Wiek | `/kalkulator/wiek` | tak (`31gj1ymm-1tvb.js`, moduł 4476) |
| 2 | Ankieta | `/kalkulator/ankieta` | **brak** |
| 3 | Weryfikacja | `/kalkulator/weryfikacja` | **brak** |
| 4 | Oferta | `/kalkulator/produkt` | **brak** (jest tylko logika cen w module 84869) |
| 5 | Podsumowanie | `/kalkulator/podsumowanie` | **brak** |
| 6 | Gotowe | `/kalkulator/sukces` | **brak** |

Dodatkowo: `/wykluczenie/wiek` – przekierowanie z kroku 1, gdy wiek poza zakresem (treść nieznana).

Stepper: krok bieżący ustalany jest z `usePathname()`. Kroki ukończone mają „✓”, bieżący obwódkę w kolorze `#E4002B`, etykiety ukryte na mobile (`hidden sm:block`), `aria-label="Postęp"`.

**Stan kalkulatora** (`31gj1ymm-1tvb.js`, moduł 3157, Zustand **bez** `persist`, więc tylko w pamięci karty i po przeładowaniu stan znika):

```
ageGroup: null | "A1" | "A2" | "B"
birthDate: null | Date
questionnaireComplete: false
turnstileVerified: false
selectedProduct: null | "dla_mnie" | "dla_nas" | "dla_rodziny"
selectedVariant: null | "podstawowy" | "rozszerzony" | "komfort" | "premium" | "prestiz"
addons: { mediplan: false, medicalAssistance: false, globalDoctors: false }
akcje: setAgeGroup, setBirthDate, setQuestionnaireComplete, setTurnstileVerified,
       setProduct (zeruje selectedVariant), setVariant, toggleAddon(key), reset()
```

Wnioski ze stanu (to jedyne ślady kroków 2–4): ankieta kończy się samą flagą logiczną `questionnaireComplete` (odpowiedzi nie są przechowywane w store); „Weryfikacja” ustawia flagę `turnstileVerified`, więc najpewniej jest to Cloudflare Turnstile; w kroku „Oferta” wybiera się produkt, wariant i dodatki.

## 2. Pola i walidacje

| Krok | Pole | Typ | Wymagane | Walidacja | Komunikat błędu |
|---|---|---|---|---|---|
| 1 Wiek | `birthdate` „Data urodzenia” | `input type="date"` | tak (sprawdzane w `onSubmit`) | `min` = 1 stycznia roku (dziś − 66 lat) (`format(subYears(now,66),"yyyy-01-01")`); `max` = dziś − 18 lat (`yyyy-MM-dd`). Po wysłaniu `getAgeGroup(new Date(value))`: wiek = `differenceInYears(new Date(), data)`; `<18` lub `>=66` → `null` → `router.push("/wykluczenie/wiek")`; inaczej zapis `ageGroup` i `birthDate` w store, potem `router.push("/kalkulator/ankieta")` | puste: „Podaj datę urodzenia.” (czyszczony przy `onChange`). Brak komunikatu dla wieku poza zakresem (jest przekierowanie) |
| Strona główna (podgląd) | „Twój wiek” | `input type="number"`, `min=18`, `max=65`, placeholder „np. 35” | nie | `parseInt`; 18–53 → A1, 54–59 → A2, 60–65 → B | „Ubezpieczenie dostępne dla osób w wieku 18–65 lat.” (gdy wartość jest wpisana, ale NaN lub poza 18–65); gdy puste: „Wpisz wiek, aby zobaczyć Twoje składki” |
| 2 Ankieta | ? | ? | ? | **brak kodu** | ? |
| 3 Weryfikacja | Turnstile (domniemane) | widget | ? | **brak kodu** | ? |
| 4 Oferta | produkt / wariant / dodatki | wybór | ? | Global Doctors tylko przy wieku <64 (`isGlobalDoctorsEligible`) | ? |
| 5 Podsumowanie | dane kontaktowe (imię? telefon? e-mail?) + zgody | ? | ? | **brak kodu** | ? |

Szczegóły kroku 1 (`31gj1ymm-1tvb.js`, linie ~1393–1490 po sformatowaniu):
- SSR (`ergo/go_kalkulator_wiek.html`) potwierdza pole: `<input id="birthdate" type="date" min="1960-01-01" max="2008-11-12">`, etykieta „Data urodzenia” (wartości liczone w chwili renderu);
- nagłówek „Sprawdź, czy możesz przystąpić”, podtytuł „Grupowe ubezpieczenie na życie ERGO Razem — Grupa Otwarta”;
- przycisk „Dalej →”;
- pod kartą: „Nie przechowujemy Twojej daty urodzenia po zamknięciu strony.”;
- ramka: „**Warunki przystąpienia:** wiek 18–65 lat w dniu objęcia ochroną.”

Uwagi do walidacji kroku 1:
- Wiek liczony jest na **dziś** (`new Date()`), a nie na „dzień objęcia ochroną”, jak mówi treść.
- `min` w polu daty pozwala wybrać daty, przy których wiek wynosi 66 lat (1 stycznia roku sprzed 66 lat). Takie osoby trafiają na `/wykluczenie/wiek`.
- `new Date("yyyy-mm-dd")` tworzy datę o północy UTC, więc w dniu urodzin wynik może zależeć od strefy czasowej.

## 3. Treści dosłowne (zgody, klauzule, informacje)

**Zgody i klauzule formularza: w dostępnym kodzie nie ma ani jednej.** FAQ potwierdza, że zgody istnieją: „Zgodę na przetwarzanie danych oraz udział w ubezpieczeniu możesz wycofać w dowolnym momencie…”. Ich treść jest w niepobranych krokach lub na stronach `/rodo`, `/polityka-prywatnosci`, `/regulamin`.

Treści informacyjne obecne w kodzie i na stronach:

Nagłówek (`SiteHeader`, `0vqvpp9_0rpw6.js`): logo `/ergo-hestia-logo.jpg` (alt „ERGO Hestia”), „Aura Expert sp. z o.o.”, „ERGO Razem Kalkulator”, „Grupa Otwarta”, „ER 01/25”, przycisk „Złóż wniosek →” (→ `/kalkulator/wiek`).

Stopka (`SiteFooter`): „Zgłoś roszczenie →” (→ `/zglos-roszczenie`); „© 2025 Aura Expert sp. z o.o. — Agent ERGO Hestia”; „Szczegóły w OWU (kod ER 01/25). Obowiązuje od 2.06.2025 r.”; linki: FAQ (`/faq`) | Polityka prywatności (`/polityka-prywatnosci`) | RODO (`/rodo`) | Regulamin (`/regulamin`) | Informacja o agencie (`/informacja-o-agencie`) | Katalog zachorowań (`/katalog-zachorowan`) | MediPlan / Medical Assistance (`/ubezpieczenia-dodatkowe`) | Global Doctors (`/global-doctors`).

Strona główna (dosłownie z `go.md`, potwierdzone w `0vqvpp9_0rpw6.js`):
- „Sopockie TU na Życie ERGO Hestia S.A.” / „Grupowe ubezpieczenie na życie ERGO Razem” / „Kompleksowa ochrona Ciebie i Twoich bliskich. Wypłaty nawet do 500 000 zł — bez badań lekarskich, w kilka minut online.” / „Oblicz składkę →” „Zobacz świadczenia ↓”
- Liczniki: „500 000 zł / maks. wypłata za zgon NW”, „od 57 zł / składka miesięczna”, „56 / chorób objętych”
- „Dlaczego ERGO Razem?”: „Ochrona 24/7 – Ubezpieczenie działa przez całą dobę, w Polsce i za granicą.”; „56 chorób objętych – Poważne zachorowania — od zawału po nowotwory i udar mózgu.”; „Bez badań lekarskich – Tylko ankieta medyczna wypełniana elektronicznie — szybko i prosto.”; „Ochrona całej rodziny – Warianty obejmują partnera, dzieci oraz rodziców i teściów.”; „Kontakt z agentem – Dedykowany agent ERGO Hestia omówi szczegóły i pomoże wybrać wariant.”; „Transparentne OWU – Pełna dokumentacja dostępna — szczegóły w OWU kod ER 01/25.”
- „Wybierz zakres ochrony” / „Kliknij produkt, aby zobaczyć pełną tabelę świadczeń i składek.”. Po rozwinięciu karty: „Składki i świadczenia dla grupy wiekowej **{18–53 lat|54–59 lat|60–65 lat}**.”, tabela, przycisk „Oblicz swoją składkę →”.
- „Jak to działa?”: 1 „Podaj wiek – Wpisz datę urodzenia — dopasujemy dostępne warianty.”; 2 „Ankieta – Krótka ankieta medyczna — wypełniana tylko w przeglądarce, nic nie wysyłamy.”; 3 „Wybierz ofertę – Porównaj warianty i skonfiguruj dodatki (MediPlan, Medical Assistance, Global Doctors).”; 4 „Agent oddzwoni – Zostawiasz dane kontaktowe — agent ERGO Hestia skontaktuje się w 1–2 dni.”
- „Poznaj szczegóły ochrony” – trzy kafle (Katalog, MediPlan / Medical Assistance, Global Doctors) i FAQ (teksty w `go.md`).
- „Gotowy(-a) na ochronę?” / „Oblicz składkę w kilka minut. Bez zobowiązań, bez badań lekarskich.” / „Złóż wniosek →”

Karty produktów: tytuł, opis i cechy dosłownie w JSON (`produkty`).

Global Doctors (`go_global-doctors.md`): „Dostęp do konsultacji z lekarzami specjalistami na świecie, gdy diagnoza wymaga drugiej opinii. Dostępne dla Ubezpieczonych do 63. roku życia.”, „Dodatek dostępny jest dla Ubezpieczonych w wieku do 63 lat w dniu przystąpienia.”, „Wysokość składki ustalana jest indywidualnie w zależności od wieku — orientacyjną kwotę zobaczysz przy konfigurowaniu oferty w kalkulatorze.”. Organizator: „Centrum Pomocy Osobom Poszkodowanym sp. z o.o. w Gdańsku”. Zgłoszenia: „801 107 107 lub (58) 555 55 55”, „zgloszenieroszczenia.ergohestia.pl”. Kontakt: „[e-mail biura Aura Expert]”. Cały tekst jest w `go_global-doctors.md`.

Informacja o agencie (art. 22 UDU): pełny tekst jest w `ergo/go_informacja-o-agencie.md` (do przeniesienia 1:1; wspólny dla portalu).

FAQ (`299pqtzg76wfe.js`, moduł 32725, tablica `c`): **komplet 21 pytań z odpowiedziami dosłownie** jest w JSON (`faq`; linki zapisane jako Markdown). Nagłówek: „Pytania i odpowiedzi” / „Najczęściej zadawane pytania” / „Wszystko, co warto wiedzieć o przystąpieniu, wariantach, składkach, dodatkach i zgłaszaniu roszczeń w ERGO Razem.”. CTA na dole: „Nie znalazłeś odpowiedzi?” / „Skontaktuj się z nami — agent ERGO Hestia odpowie na wszystkie pytania.”. Odpowiedzi kluczowe dla wdrożenia:
- „Nie. Wystarczy wypełnić krótką ankietę medyczną online. Ankieta jest przetwarzana wyłącznie lokalnie w Twojej przeglądarce i nigdzie nie jest wysyłana ani zapisywana.”
- „Nie. Kalkulator służy wyłącznie do orientacyjnego wyliczenia składki. Wiążącą ofertę i szczegóły płatności przedstawia agent ubezpieczeniowy po kontakcie.”
- „Nie. Formularz służy wyłącznie do przedstawienia oferty — umowę zawierasz dopiero po kontakcie i weryfikacji z agentem.”

MediPlan / Medical Assistance (`39ohoz70_awj_.js`, moduł 66399, obiekty `p` i `u`): pełne dane są w JSON (`ubezpieczenia_dodatkowe_szczegoly`): `summary`, `trigger`, `definitions`, `limits`, `benefits` (grupy, pozycje, `detail`, `limit`), `exclusions`, `procedure`. Zakładki: „Świadczenia”, „Limity”, „Wyłączenia”, „Jak skorzystać”, „Definicje”; tytuły sekcji „Limity i sumy ubezpieczenia”, „Wyłączenia odpowiedzialności ERGO Hestii”, „Jak skorzystać ze świadczeń”, „Kluczowe definicje”. Ostrzeżenie: „⚠️ **Ważne:** Świadczenia MUSZĄ być zorganizowane przez Centrum Alarmowe. ERGO Hestia nie zwraca kosztów poniesionych samodzielnie bez wcześniejszego uzgodnienia.”. Tabela „⚡ Kluczowe różnice” jest w JSON. Uwaga: w MediPlan jest literówka w źródle („Każde zrealizowane świadczenie pomniejsza pula”), a w `procedure` MediPlan widnieje adres `pmu.szkody@mondial-assistance.pl`. Oba zapisy zostawiono dosłownie i trzeba je potwierdzić u zleceniodawcy.

Katalog zachorowań (`go_katalog-zachorowan.md`): „WU/ER 01/25 · Załącznik 1”, „Pełna lista poważnych zachorowań objętych ochroną ERGO Razem — z definicjami i zakresem dla każdego wariantu. Obowiązuje od 13.02.2026.”. Statystyki: 57 wszystkich, 34 „Zakres MAKSYMALNY”, 56 „Zakres KOMFORT”, 12 „Małżonek (rozszerzony)”, 18 „Dziecko”. Lista 57 pozycji z kategorią i znacznikami MAX/MŁŻ/DZI jest w JSON (`katalog_zachorowan.pozycje`). Policzone znaczniki zgadzają się ze statystykami: MAX = 34, MŁŻ = 12, DZI = 18. **Definicji brak** (niepobrany chunk). **Nie wiadomo**, której 1 z 57 pozycji nie ma w zakresie KOMFORT, bo znacznik KOMFORT nie jest wyświetlany.

## 4. Logika cen/taryf i dane

Źródło: `31gj1ymm-1tvb.js` (moduły 14887 i 84869); identyczna kopia stałych jest w `0vqvpp9_0rpw6.js`. Wszystkie ceny są zapisane na stałe w kodzie klienta, bez pobierania z API.

**Grupy wiekowe** (`getAgeGroup`): wiek = `differenceInYears(dziś, dataUrodzenia)`; `<18` lub `>=66` → brak; `<54` → **A1**; `<60` → **A2**; w pozostałych przypadkach → **B**. Wynik: A1 = 18–53, A2 = 54–59, B = 60–65.

**Wzór** (`calcMonthlyPremium(grupa, produkt, wariant, addons, dataUrodzenia)`):
```
skladka = PREMIUMS[grupa][produkt].find(v => v.variant === wariant)?.monthly ?? 0
        + (addons.mediplan ? 9 : 0)
        + (addons.medicalAssistance ? 6 : 0)
        + (addons.globalDoctors && wiek < 64 ? 0 : 0)   // Global Doctors: dosłownie „+= 0”
```
Global Doctors: `ADDONS.global_doctors = { monthly: null, maxAge: 63, note: "Składka zależna od wieku — podana przy wycenie" }`, `isGlobalDoctorsEligible(data) = wiek < 64`. **Cena GD nie istnieje w kodzie.** Klucze dodatków w store (`mediplan`, `medicalAssistance`, `globalDoctors`) różnią się od kluczy w `ADDONS` (`mediplan`, `medical_assistance`, `global_doctors`).

Etykiety: `PRODUCT_LABELS` = Dla Mnie / Dla Nas / Dla Rodziny; `VARIANT_LABELS` = Podstawowy / Rozszerzony / Komfort / Premium / Prestiż.

#### Składki miesięczne (PREMIUMS, zł)

| Grupa | Produkt | Podstawowy | Rozszerzony | Komfort | Premium | Prestiż |
|---|---|---|---|---|---|---|
| A1 | dla_mnie | — | 57 | 75 | 106 | 150 |
| A1 | dla_nas | — | 69 | 98 | — | — |
| A1 | dla_rodziny | 78 | 103 | 147 | 194 | — |
| A2 | dla_mnie | 50 | 89 | 115 | 139 | — |
| A2 | dla_nas | 70 | 116 | 152 | — | — |
| A2 | dla_rodziny | 105 | 151 | 210 | — | — |
| B | dla_mnie | 72 | 110 | 146 | — | — |
| B | dla_nas | 99 | 159 | — | — | — |
| B | dla_rodziny | 139 | 203 | — | — | — |

#### Tabela świadczeń A (grupy A1 i A2; 12 kolumn)

| Świadczenie | Mnie Podstawowy | Mnie Rozszerzony | Mnie Komfort | Mnie Premium | Mnie Prestiż | Nas Podstawowy | Nas Rozszerzony | Nas Komfort | Rodz. Podstawowy | Rodz. Rozszerzony | Rodz. Komfort | Rodz. Premium | Karencja |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Pakiet ubezpieczonego** | | | | | | | | | | | | | |
| Zgon NW przy pracy — ruch lądowy/wodny/powietrzny ★ | 100 000 zł | 140 000 zł | 220 000 zł | 300 000 zł | 500 000 zł | 120 000 zł | 180 000 zł | 260 000 zł | 160 000 zł | 220 000 zł | 350 000 zł | 430 000 zł | — |
| Zgon NW przy pracy | 60 000 zł | 90 000 zł | 150 000 zł | 210 000 zł | 360 000 zł | 75 000 zł | 120 000 zł | 180 000 zł | 100 000 zł | 150 000 zł | 240 000 zł | 300 000 zł | — |
| Zgon NW — ruch lądowy/wodny/powietrzny ★ | 60 000 zł | 90 000 zł | 150 000 zł | 210 000 zł | 360 000 zł | 75 000 zł | 120 000 zł | 180 000 zł | 100 000 zł | 150 000 zł | 240 000 zł | 300 000 zł | — |
| Zgon NW | 40 000 zł | 60 000 zł | 100 000 zł | 140 000 zł | 240 000 zł | 50 000 zł | 80 000 zł | 120 000 zł | 70 000 zł | 100 000 zł | 160 000 zł | 200 000 zł | — |
| Zgon — zawał/udar | 25 000 zł | 40 000 zł | 65 000 zł | 90 000 zł | 160 000 zł | 35 000 zł | 50 000 zł | 80 000 zł | 45 000 zł | 65 000 zł | 100 000 zł | 140 000 zł | — |
| Zgon ★ | 20 000 zł | 30 000 zł | 50 000 zł | 70 000 zł | 120 000 zł | 25 000 zł | 40 000 zł | 60 000 zł | 35 000 zł | 50 000 zł | 80 000 zł | 100 000 zł | — |
| Trwały uszczerbek NW — za 1% | 300 zł/1% | 400 zł/1% | 500 zł/1% | 650 zł/1% | 800 zł/1% | 350 zł/1% | 450 zł/1% | 500 zł/1% | 400 zł/1% | 500 zł/1% | 650 zł/1% | 750 zł/1% | — |
| Trwały uszczerbek zawał/krwotok — za 1% | 200 zł/1% | 300 zł/1% | 500 zł/1% | 600 zł/1% | 600 zł/1% | 250 zł/1% | 300 zł/1% | 500 zł/1% | 300 zł/1% | 400 zł/1% | 500 zł/1% | 600 zł/1% | — |
| Całkowita trwała niezdolność do pracy NW | 10 000 zł | 25 000 zł | 30 000 zł | 40 000 zł | 70 000 zł | 15 000 zł | 30 000 zł | 40 000 zł | 30 000 zł | 40 000 zł | 50 000 zł | 70 000 zł | — |
| Operacja chirurgiczna Gr.1 ★ | — | 1500 zł | 2000 zł | 3000 zł | 4000 zł | — | 2000 zł | 2500 zł | 1500 zł | 2000 zł | 3000 zł | 3500 zł | 6 mies. |
| Operacja chirurgiczna Gr.2 | — | 900 zł | 1200 zł | 1800 zł | 2400 zł | — | 1200 zł | 1500 zł | 900 zł | 1200 zł | 1800 zł | 2100 zł | 6 mies. |
| Operacja chirurgiczna Gr.3 | 300 zł | 400 zł | 600 zł | 800 zł | — | — | 400 zł | 500 zł | 300 zł | 400 zł | 600 zł | 700 zł | 6 mies. |
| Poważne zachorowanie (56 j.ch.) ★ | 3000 zł | 6000 zł | 12 000 zł | 15 000 zł | 20 000 zł | 4000 zł | 6000 zł | 10 000 zł | 7000 zł | 9000 zł | 12 000 zł | 17 000 zł | 3 mies. |
| Leczenie szpitalne NW | 120/50 zł | 160/60 zł | 180/70 zł | 200/90 zł | 250/100 zł | 120/50 zł | 140/60 zł | 160/70 zł | 170/60 zł | 180/70 zł | 200/80 zł | 220/100 zł | 2 mies. (od 15. dnia) |
| Leczenie szpitalne choroba ★ | 50 zł/dzień | 60 zł/dzień | 70 zł/dzień | 90 zł/dzień | 100 zł/dzień | 50 zł/dzień | 60 zł/dzień | 70 zł/dzień | 60 zł/dzień | 70 zł/dzień | 80 zł/dzień | 100 zł/dzień | 2 mies. |
| Leczenie szpitalne NW — ruch lądowy/wodny/powietrzny | 220 zł/dzień | 310 zł/dzień | 330 zł/dzień | 350 zł/dzień | 400 zł/dzień | 220 zł/dzień | 290 zł/dzień | 310 zł/dzień | 320 zł/dzień | 330 zł/dzień | 350 zł/dzień | 400 zł/dzień | — |
| Leczenie szpitalne zawał/krwotok | 80 zł/dzień | 120 zł/dzień | 130 zł/dzień | 150 zł/dzień | 250 zł/dzień | 80 zł/dzień | 120 zł/dzień | 130 zł/dzień | 120 zł/dzień | 140 zł/dzień | 160 zł/dzień | 200 zł/dzień | 2 mies. |
| Leczenie specjalistyczne ★ | do 1500 zł | do 2000 zł | do 4000 zł | do 5000 zł | do 7000 zł | do 1500 zł | do 2500 zł | do 2500 zł | do 2000 zł | do 2500 zł | do 3000 zł | do 5000 zł | 3 mies. |
| **Pakiet małżonek / partner** | | | | | | | | | | | | | |
| Zgon małżonka/partnera NW ★ | — | — | — | — | — | 14 000 zł | 25 000 zł | 24 000 zł | 20 000 zł | 24 000 zł | 30 000 zł | 40 000 zł | — |
| Zgon małżonka/partnera | — | — | — | — | — | 7000 zł | 12 000 zł | 12 000 zł | 10 000 zł | 12 000 zł | 15 000 zł | 20 000 zł | 6 mies. |
| Trwałe inwalidztwo małżonka/partnera NW | — | — | — | — | — | do 8000 zł | do 10 000 zł | do 12 000 zł | do 10 000 zł | do 10 000 zł | do 12 000 zł | do 12 000 zł | — |
| Poważne zachorowanie małżonka/partnera (12 j.ch.) | — | — | — | — | — | 2000 zł | 3000 zł | 3500 zł | 2000 zł | 3000 zł | 4000 zł | 5000 zł | 3 mies. |
| Zgon rodzica | — | — | — | — | — | — | — | 1200 zł | — | 1600 zł | 2000 zł | 2200 zł | 6 mies. |
| Zgon teścia | — | — | — | — | — | — | — | 1200 zł | — | 1600 zł | 2000 zł | 2200 zł | 6 mies. |
| **Pakiet dziecko** | | | | | | | | | | | | | |
| Osierocenie dziecka | — | — | — | — | — | — | — | — | 3000 zł | 4000 zł | 5000 zł | 6000 zł | — |
| Zgon dziecka NW ★ | — | — | — | — | — | — | — | — | 8000 zł | 10 000 zł | 12 000 zł | 14 000 zł | — |
| Zgon dziecka | — | — | — | — | — | — | — | — | 4000 zł | 5000 zł | 6000 zł | 7000 zł | 6 mies. |
| Urodzenie dziecka | — | — | — | — | — | — | — | — | 1300 zł | 1300 zł | 1500 zł | 1700 zł | 9 mies. |
| Urodzenie martwego noworodka | — | — | — | — | — | — | — | — | 3000 zł | 3500 zł | 4000 zł | 5000 zł | 9 mies. |
| Trwałe inwalidztwo dziecka NW | — | — | — | — | — | — | — | — | do 10 000 zł | do 10 000 zł | do 10 000 zł | do 10 000 zł | — |
| Wada wrodzona dziecka | — | — | — | — | — | — | — | — | 2000 zł | 2500 zł | 3000 zł | 3500 zł | 9 mies. |
| Poważne zachorowanie dziecka (18 j.ch.) | — | — | — | — | — | — | — | — | 4000 zł | 5000 zł | 6000 zł | 8000 zł | 3 mies. |
| Leczenie szpitalne dziecka | — | — | — | — | — | — | — | — | 400 zł/dzień | 500 zł/dzień | 700 zł/dzień | 700 zł/dzień | 2 mies. |

#### Tabela świadczeń B (grupa B; 7 kolumn)

| Świadczenie | Mnie Podstawowy | Mnie Rozszerzony | Mnie Komfort | Nas Podstawowy | Nas Rozszerzony | Rodz. Podstawowy | Rodz. Rozszerzony | Karencja |
|---|---|---|---|---|---|---|---|---|
| **Pakiet ubezpieczonego** | | | | | | | | |
| Zgon NW przy pracy — ruch lądowy ★ | 100 000 zł | 140 000 zł | 220 000 zł | 120 000 zł | 180 000 zł | 160 000 zł | 220 000 zł | — |
| Zgon NW przy pracy | 60 000 zł | 90 000 zł | 150 000 zł | 75 000 zł | 120 000 zł | 100 000 zł | 150 000 zł | — |
| Zgon NW — ruch lądowy ★ | 60 000 zł | 90 000 zł | 150 000 zł | 75 000 zł | 120 000 zł | 100 000 zł | 150 000 zł | — |
| Zgon NW | 40 000 zł | 60 000 zł | 100 000 zł | 50 000 zł | 80 000 zł | 70 000 zł | 100 000 zł | — |
| Zgon — zawał/udar | 25 000 zł | 40 000 zł | 65 000 zł | 35 000 zł | 50 000 zł | 45 000 zł | 65 000 zł | — |
| Zgon ★ | 20 000 zł | 30 000 zł | 50 000 zł | 25 000 zł | 40 000 zł | 35 000 zł | 50 000 zł | — |
| Trwały uszczerbek NW — za 1% | 300 zł/1% | 400 zł/1% | 500 zł/1% | 350 zł/1% | 450 zł/1% | 400 zł/1% | 500 zł/1% | — |
| Trwały uszczerbek zawał/krwotok — za 1% | 200 zł/1% | 300 zł/1% | 500 zł/1% | 250 zł/1% | 300 zł/1% | 300 zł/1% | 400 zł/1% | — |
| Całkowita trwała niezdolność do pracy NW | 10 000 zł | 25 000 zł | 30 000 zł | 15 000 zł | 30 000 zł | 30 000 zł | 40 000 zł | — |
| Operacja chirurgiczna Gr.1 ★ | — | 1500 zł | 2000 zł | — | 2000 zł | 1500 zł | 2000 zł | 6 mies. |
| Operacja chirurgiczna Gr.2 | — | 900 zł | 1200 zł | — | 1200 zł | 900 zł | 1200 zł | 6 mies. |
| Operacja chirurgiczna Gr.3 | 300 zł | 400 zł | 400 zł | 300 zł | 400 zł | 300 zł | 400 zł | 6 mies. |
| Poważne zachorowanie (34 j.ch.) ★ | 3000 zł | 6000 zł | 12 000 zł | 4000 zł | 6000 zł | 7000 zł | 9000 zł | 3 mies. |
| Leczenie szpitalne NW | 120/50 zł | 160/60 zł | 180/70 zł | 120/50 zł | 140/60 zł | 170/60 zł | 180/70 zł | 2 mies. (od 15. dnia) |
| Leczenie szpitalne choroba ★ | 50 zł/dzień | 60 zł/dzień | 70 zł/dzień | 50 zł/dzień | 60 zł/dzień | 60 zł/dzień | 70 zł/dzień | 2 mies. |
| Leczenie szpitalne NW — ruch lądowy | 220 zł/dzień | 310 zł/dzień | 330 zł/dzień | 220 zł/dzień | 290 zł/dzień | 320 zł/dzień | 330 zł/dzień | — |
| Leczenie szpitalne zawał/krwotok | 80 zł/dzień | 120 zł/dzień | 130 zł/dzień | 80 zł/dzień | 120 zł/dzień | 120 zł/dzień | 140 zł/dzień | 2 mies. |
| Leczenie specjalistyczne ★ | do 1500 zł | do 2000 zł | do 4000 zł | do 1500 zł | do 2500 zł | do 2000 zł | do 2500 zł | 3 mies. |
| **Pakiet małżonek / partner** | | | | | | | | |
| Zgon małżonka/partnera NW ★ | — | — | — | 14 000 zł | 25 000 zł | 20 000 zł | 24 000 zł | — |
| Zgon małżonka/partnera | — | — | — | 7000 zł | 12 000 zł | 10 000 zł | 12 000 zł | 6 mies. |
| Trwałe inwalidztwo małżonka/partnera NW | — | — | — | do 8000 zł | do 10 000 zł | do 10 000 zł | do 10 000 zł | — |
| Poważne zachorowanie małżonka/partnera (12 j.ch.) | — | — | — | 2000 zł | 3000 zł | 2000 zł | 3000 zł | 3 mies. |
| Zgon rodzica | — | — | — | — | — | — | 1600 zł | 6 mies. |
| Zgon teścia | — | — | — | — | — | — | 1600 zł | 6 mies. |
| **Pakiet dziecko** | | | | | | | | |
| Osierocenie dziecka | — | — | — | — | — | 3000 zł | 4000 zł | — |
| Zgon dziecka NW ★ | — | — | — | — | — | 8000 zł | 10 000 zł | — |
| Zgon dziecka | — | — | — | — | — | 4000 zł | 5000 zł | 6 mies. |
| Urodzenie dziecka | — | — | — | — | — | 1300 zł | 1300 zł | 9 mies. |
| Urodzenie martwego noworodka | — | — | — | — | — | 3000 zł | 3500 zł | 9 mies. |
| Trwałe inwalidztwo dziecka NW | — | — | — | — | — | do 10 000 zł | do 10 000 zł | — |
| Wada wrodzona dziecka | — | — | — | — | — | 2000 zł | 2500 zł | 9 mies. |
| Poważne zachorowanie dziecka (18 j.ch.) | — | — | — | — | — | 4000 zł | 5000 zł | 3 mies. |
| Leczenie szpitalne dziecka | — | — | — | — | — | 400 zł/dzień | 500 zł/dzień | 2 mies. |

Legenda: ★ = wiersz wyróżniony (`highlight`, tło `bg-yellow-50`); „—” = brak świadczenia lub wartość `null`. Formatowanie (`0vqvpp9_0rpw6.js`, moduł 19489): `toLocaleString("pl-PL")` + „ zł” / „ zł/dzień” / „ zł/1%” albo przedrostek „do …”. W pl-PL separator tysięcy pojawia się dopiero od 10 000 (np. „1600 zł”, „10 000 zł”). Wiersze „Leczenie szpitalne NW” mają w źródle wartości tekstowe typu „120/50 zł”, bez objaśnienia, co oznaczają obie liczby (do potwierdzenia).

**Reguły tabeli świadczeń** (`getBenefits(grupa, produkt, wariant)`):
- Grupa B korzysta z tabeli B, a grupy A1 i A2 ze wspólnej tabeli A. Indeks kolumny pochodzi z map `a` (A) i `l` (B).
- Wiersze „Pakiet ubezpieczonego” pokazywane są zawsze. Wiersze „Pakiet małżonek / partner” tylko dla `dla_nas` i `dla_rodziny` i tylko z wartością różną od „—”. Wiersze „Pakiet dziecko” tylko dla `dla_rodziny` i również z wartością różną od „—”.
- W tabeli A wiersze NW mają nazwy „… ruch lądowy/wodny/powietrzny”, a w tabeli B „… ruch lądowy”. W A świadczenie to „Poważne zachorowanie (56 j.ch.)”, w B „Poważne zachorowanie (34 j.ch.)”.

**Tabela na stronie głównej** (komponent `j`): kolumny to warianty z list `z` (A) / `f` (B) przefiltrowane przez `PREMIUMS[grupa][produkt]`. W nagłówku każdej kolumny jest składka „{monthly} zł/mies.”, a na końcu kolumna „Karencja”. Bez wpisanego wieku stosowana jest grupa **A1**. Lista `z` nie zawiera wariantu `podstawowy` dla `dla_mnie` i `dla_nas`, więc dla A2 strona główna **nie pokazuje** wariantów Podstawowy 50 zł (Dla Mnie) i 70 zł (Dla Nas), choć są w `PREMIUMS`.

**Niespójności do wyjaśnienia ze zleceniodawcą** (wynikają wprost z kodu i treści):
1. „od 57 zł” (strona główna i FAQ) kontra A2 Dla Mnie Podstawowy = **50 zł** w `PREMIUMS`.
2. „56 chorób objętych” kontra katalog: 57 pozycji, „Zakres MAKSYMALNY 34”, „Zakres KOMFORT 56”. W tabelach A ma „56 j.ch.”, a B „34 j.ch.”, więc nazwy zakresów („maksymalny” = 34 < „komfort” = 56) wyglądają na odwrócone albo nieintuicyjne.
3. Daty: „OWU (kod ER 01/25). Obowiązuje od 2.06.2025 r.” kontra katalog i dodatki „Obowiązuje od 13.02.2026”.
4. „wiek 18–65 lat w dniu objęcia ochroną” i FAQ „Wiek w dniu przystąpienia decyduje” kontra kod, który liczy wiek na dziś.
5. Global Doctors: cena nieznana („podana przy wycenie”); w kalkulatorze dodaje 0 zł.
6. „Zgon rodzica/teścia” w tabeli B występuje tylko w Dla Rodziny Rozszerzony (1600 zł), a w karcie produktu „Dla Nas” jest cecha „Zgon rodziców i teściów”. W tabeli A ma go Dla Nas tylko w wariancie Komfort (1200 zł).

## 5. Wysyłka danych

- **Server actions: w pobranych plikach brak identyfikatorów akcji** (40–42 znaki hex) i brak wywołań `createServerReference` w kodzie aplikacji. Wystąpienia `createServerReference` i `callServer` w `11oof8oxnxiv9.js` i `2nykiepra7i1k.js` to wyłącznie runtime React/Next.js. Wywołania `fetch(` w `11oof8oxnxiv9.js`, `27jktro2p5rq9.js` i `turbopack-…js` to router i ładowanie chunków.
- Metoda, endpoint, kształt ładunku i odpowiedzi: **nieznane**. Next.js wysyła server action jako `POST` na bieżącą ścieżkę z nagłówkiem `Next-Action: <id>` i ciałem w formacie RSC lub FormData, ale konkretne ID i pola są w niepobranym chunku kroku „Podsumowanie”.
- Co prawdopodobnie trafia do wysyłki (wnioskowanie ze store, **niepotwierdzone**): `ageGroup`, `selectedProduct`, `selectedVariant`, `addons`, wyliczona składka i dane kontaktowe. Według treści **nie** są wysyłane odpowiedzi ankiety ani data urodzenia. Kod tego nie potwierdza.
- **Turnstile**: jedyny ślad to flaga `turnstileVerified` i akcja `setTurnstileVerified`. Sitekey, sposób renderowania widgetu i weryfikacja tokenu po stronie serwera (`siteverify`) są nieznane. W HTML pobranych stron brak skryptu `challenges.cloudflare.com`.
- Szkice / przypomnienia: **brak** (store bez `persist`, brak `localStorage`/`sessionStorage` w kodzie aplikacji).
- Supabase: w pobranych plikach **brak** klienta, URL i anon key.

## 6. Logika poboczna

- GUS / NIP: **brak**, to formularz dla osób fizycznych.
- Analityka: w HTML i chunkach **brak** GA/GTM, Plausible, Meta Pixel, Clarity itp.
- Zdarzenia: wyłącznie nawigacja `router.push` (krok 1 → `/kalkulator/ankieta` lub `/wykluczenie/wiek`). Na stronie głównej zwijanie i rozwijanie kart produktów oraz FAQ (`useState`).
- localStorage / sessionStorage: **brak** w kodzie aplikacji. Stan (w tym `birthDate` jako `Date`) jest tylko w pamięci (Zustand), co zgadza się z „Nie przechowujemy Twojej daty urodzenia po zamknięciu strony.”.
- Przekierowania: `/wykluczenie/wiek` (wiek poza zakresem). Brak strażników kroków w dostępnym kodzie, więc nie wiadomo, czy wejście bezpośrednio na `/kalkulator/produkt` bez wieku jest blokowane (to sprawdzają niepobrane strony).
- Linki zewnętrzne w treści: `zgloszenieroszczenia.ergohestia.pl`, `mailto:[e-mail biura Aura Expert]`, `https://rpu.knf.gov.pl`, `www.rf.gov.pl`.
- Zasoby graficzne: `/ergo-hestia-logo.jpg`, `/girl.jpg`, `/para.jpg`, `/family.jpg` (do zastąpienia w portalu; logo ERGO Hestia wymaga zgody na użycie znaku).
- Kolorystyka źródła: czerwień ERGO `#E4002B` / `#c00025` (hover). W portalu zastępuje ją styl „old money glass” (makiety v3).

## 7. Czego NIE da się odtworzyć z kodu klienckiego – do uzyskania od zleceniodawcy

1. **Ankieta medyczna**: pełne pytania (dosłownie), typy odpowiedzi, reguły kwalifikacji (które odpowiedzi blokują przystąpienie, które kierują do agenta, czy są wyjątki dla partnera i dzieci), treść ekranów wykluczenia.
2. **Krok „Weryfikacja”**: co dokładnie weryfikuje (tylko Turnstile czy coś więcej), sitekey (nowy dla domeny portalu) i weryfikacja serwerowa.
3. **Krok „Oferta”**: układ, domyślny wariant, czy pokazuje tabelę świadczeń, komunikaty przy niedostępnym Global Doctors (wiek > 63).
4. **Krok „Podsumowanie”**: pola formularza kontaktowego (imię, nazwisko, telefon, e-mail, preferowana pora kontaktu?), walidacje, komunikaty błędów, **treści wszystkich zgód i klauzul** (RODO art. 13, zgoda marketingowa i kanały komunikacji, ewentualna zgoda art. 9).
5. **Wysyłka**: kod server action (co zapisuje, dokąd: Supabase / e-mail / CRM), struktura rekordu, e-maile do agenta i do klienta (szablony, nadawca), limity anty-spam, walidacje serwerowe.
6. **Ekran „Gotowe”** i **strona `/wykluczenie/wiek`**: treści.
7. **Cena Global Doctors** w zależności od wieku (tabela) i sposób jej pokazania.
8. **Definicje 57 zachorowań** (chunk `03amb72-bgjst.js` albo dokument WU/ER 01/25 Zał. 1) oraz informacja, której pozycji brak w zakresie KOMFORT.
9. Strony `/zglos-roszczenie`, `/rodo`, `/polityka-prywatnosci`, `/regulamin` (treści).
10. Wyjaśnienie niespójności z sekcji 4: 57 vs 50 zł, 56/34 j.ch., daty obowiązywania, wiek „na dziś” vs „w dniu objęcia ochroną”, znaczenie „120/50 zł”.
11. Pliki OWU/WU ER 01/25 i GD 02/24 (PDF) do podlinkowania oraz zgoda ERGO Hestii na użycie logo i nazwy w portalu.
12. Potwierdzenie, czy taryfy (`PREMIUMS`) i sumy świadczeń są aktualne i czy portal ma je trzymać w kodzie czy w bazie (Supabase) do edycji.

Najprostsza droga do punktów 1–6, 8 i 9: poprosić zleceniodawcę o repozytorium źródłowe aplikacji ergo.beautypolisa.eu. Alternatywnie można pobrać brakujące chunki z działającej strony, przechodząc kolejne kroki w przeglądarce. Kodu serwerowego (pkt 5) i tak nie da się w ten sposób uzyskać.

## 8. Uwagi bezpieczeństwa i RODO

- **Klucze**: w pobranych plikach nie znaleziono anon key Supabase, sitekey Turnstile ani tokenów. Nie ma czego rotować z tej analizy.
- **Dane o zdrowiu (art. 9 RODO)**: według treści ankieta jest przetwarzana wyłącznie lokalnie i nie jest wysyłana. Kod tego nie dowodzi, bo chunk ankiety nie był dostępny. W portalu warto zachować tę zasadę: ankieta w 100% po stronie klienta, a do serwera trafia co najwyżej wynik „kwalifikuje się / do agenta”. Jeśli kiedykolwiek wysyłane byłyby same odpowiedzi, potrzebna jest wyraźna zgoda z art. 9 ust. 2 lit. a i osobna podstawa w klauzuli.
- **Data urodzenia**: trzymana tylko w pamięci karty. W portalu nie wysyłać jej, wystarczy grupa wiekowa i ewentualnie flaga uprawnienia do Global Doctors (wiek < 64). Pozwala to dotrzymać zdania „Nie przechowujemy Twojej daty urodzenia…”.
- **Logika cen po stronie klienta**: składka liczona w przeglądarce. Przy wysyłce oferty serwer powinien ją przeliczyć ponownie z tej samej tabeli i nie ufać kwocie z klienta.
- **Turnstile**: weryfikację tokenu trzeba robić po stronie serwera (Workers) w tej samej akcji, która zapisuje lead. Sama flaga `turnstileVerified` w store klienta nie chroni przed botami.
- **Strażnicy kroków**: stan w pamięci sprawia, że bezpośrednie wejście na późniejszy krok ma pusty store. Portal powinien przekierować do kroku 1.
- **Obowiązki informacyjne**: Informacja o agencie (art. 22 UDU) jest kompletna w `go_informacja-o-agencie.md`. Brakuje klauzuli informacyjnej RODO dla formularza (administrator: agent czy ERGO Hestia, odbiorcy, okres przechowywania), do uzyskania (pkt 7.4).
- **Spójność komunikacji**: twierdzenia „bez badań lekarskich”, „od 57 zł”, „56 chorób” oraz wypłaty „nawet do 500 000 zł” (to suma tylko dla „Zgon NW przy pracy — ruch lądowy/wodny/powietrzny”, A, Dla Mnie Prestiż) wymagają zgodności z OWU i taryfą. Przy przenoszeniu do portalu warto doprecyzować ostatnie zdanie („za zgon w wyniku NW przy pracy…”).
- `branzowe.html` ładuje skrypt Cloudflare challenge-platform. To inna aplikacja (SvelteKit), bez związku z formularzem ERGO.

---

## Weryfikacja krytyka kompletności (2026-11-13)

Sprawdzone w kodzie i **potwierdzone**: `PREMIUMS` i `ADDONS` (`31gj1ymm-1tvb.js` l. 75–160: MediPlan 9, Medical Assistance 6, Global Doctors `monthly: null`, `maxAge: 63`); `getAgeGroup` (`<18 || >=66 → null`, `<54 A1`, `<60 A2`, inaczej B); `calcMonthlyPremium` z dosłownym `o += 0` dla Global Doctors; komunikat „Podaj datę urodzenia.” i przekierowania `/kalkulator/ankieta` / `/wykluczenie/wiek`; store bez `persist`; listy wariantów strony głównej (`0vqvpp9_0rpw6.js` l. 1631–1661, brak „Podstawowy” dla Dla Mnie / Dla Nas w A); wiersze tabeli A (np. „Poważne zachorowanie (56 j.ch.)” 3000…17 000, „Leczenie szpitalne NW” jako tekst „120/50 zł”); brak skryptu Turnstile w pobranym HTML.

**Uzupełnione:** atrybuty `min`/`max` pola daty z SSR. Chunk `1rxncug86bump.js` jest ładowany także przez `/global-doctors` (nie tylko „Informacja o agencie”), więc jest raczej wspólnym komponentem stron treści niż kodem jednej strony.

**Bez zmian (potwierdzone braki):** kroki 2–6 (ankieta, weryfikacja, oferta, podsumowanie, sukces), `/wykluczenie/wiek`, zgody, wysyłka i Turnstile nie występują w żadnym pobranym pliku. To największa luka wśród trzech aplikacji.
