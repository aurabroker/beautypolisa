# ERGO Razem – Grupa Otwarta (ergo.beautypolisa.eu) – specyfikacja odtworzona z kodu klienckiego

Źródło: https://ergo.beautypolisa.eu/ (Next.js App Router, Turbopack). Analiza wyłącznie tekstowa pobranych plików (kod nie był uruchamiany). Kopie sformatowane prettierem: `specs/tmp/er/*.js`. Dane strukturalne: `ergo-razem-grupa-otwarta.json` (ten sam katalog).

> **Aktualizacja 2026-11-13: analiza repozytorium `gohestia`** (kod źródłowy aplikacji, klon tylko do odczytu, commit `e186f2a` z 12.07.2026; kod nie był uruchamiany). Repozytorium zawiera **wszystkie kroki 1–6**, ankietę medyczną, oba ekrany wykluczeń, formularz kontaktowy z 14 zgodami i oświadczeniami, wysyłkę (route handlery `/api/turnstile` i `/api/oferta`, e-maile przez Resend) oraz strony treści. Nowe ustalenia są w **§ 9** i w sekcji **„Zamknięcie braków po analizie repozytorium gohestia”** na końcu pliku. Sekcje 1–8 opisują stan z kodu klienckiego; miejsca, które repozytorium skorygowało, oznaczono „**[korekta repo]**”. Odnośniki `gohestia/…:linia` wskazują pliki repozytorium.
>
> Najważniejsze nowe fakty:
> - Dane z formularza trafiają **wyłącznie do dwóch e-maili** (klient i agent, Resend). Aplikacja nie ma bazy, Supabase ani połączenia z CRM (`gohestia/app/api/oferta/route.ts:61-136`, `gohestia/package.json:13-27`).
> - Odpowiedzi ankiety **nie opuszczają przeglądarki** (`gohestia/components/questionnaire/index.tsx:48-69`). Każda odpowiedź „TAK” wyklucza z Grupy Otwartej.
> - Zgody i oświadczenia (14) są obowiązkowe lub dobrowolne tylko po stronie klienta. **Nie są nigdzie wysyłane ani zapisywane** (`gohestia/app/kalkulator/podsumowanie/page.tsx:136-151`).
> - `/api/oferta` nie wymaga tokenu Turnstile i nie ma limitu żądań. Krok „Weryfikacja” ustawia tylko flagę w przeglądarce.
> - Błąd: w kroku „Oferta” dodatki MediPlan i Medical Assistance są doliczane do składki dwukrotnie (`gohestia/components/premium-calculator.tsx:18-20`).
> - Cena Global Doctors nadal nie istnieje (R8 otwarty).

**Najważniejsze w skrócie** (stan sprzed repozytorium)

- W kodzie klienckim **są**: pełne tabele składek (3 grupy wiekowe × 3 produkty × warianty), ceny dodatków (MediPlan 9 zł, Medical Assistance 6 zł; Global Doctors bez ceny), wzór składki, reguła grup wiekowych, **pełne tabele świadczeń** (sumy, karencje) dla wszystkich wariantów, FAQ z odpowiedziami, szczegóły MediPlan/Medical Assistance (świadczenia, limity, wyłączenia, procedura, definicje), lista 57 zachorowań z kategoriami i zakresami.
- [korekta repo: wszystko poniższe jest już znane z repozytorium, § 9] W pobranych plikach **nie ma** kodu kroków 2–6 (Ankieta, Weryfikacja, Oferta, Podsumowanie, Gotowe) ani strony `/wykluczenie/wiek`. Dlatego **nie da się odtworzyć**: pytań ankiety medycznej i reguł kwalifikacji, formularza kontaktowego (pola, walidacje), treści zgód i klauzul, wysyłki (server actions), Turnstile (sitekey, weryfikacja), ekranu sukcesu. Pobrane chunki to tylko: strona główna, FAQ, MediPlan/Medical Assistance, krok „Wiek” i wspólny runtime.
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

| # | Etykieta | Ścieżka | Kod w pobranych plikach | Repozytorium `gohestia` [korekta repo] |
|---|---|---|---|---|
| 1 | Wiek | `/kalkulator/wiek` | tak (`31gj1ymm-1tvb.js`, moduł 4476) | `app/kalkulator/wiek/page.tsx` |
| 2 | Ankieta | `/kalkulator/ankieta` | **brak** | `app/kalkulator/ankieta/page.tsx`, `components/questionnaire/*`, `lib/data/questionnaire.ts` (§ 9.3) |
| 3 | Weryfikacja | `/kalkulator/weryfikacja` | **brak** | `app/kalkulator/weryfikacja/page.tsx`, `app/api/turnstile/route.ts` (§ 9.4) |
| 4 | Oferta | `/kalkulator/produkt` | **brak** (jest tylko logika cen w module 84869) | `app/kalkulator/produkt/page.tsx` (§ 9.5) |
| 5 | Podsumowanie | `/kalkulator/podsumowanie` | **brak** | `app/kalkulator/podsumowanie/page.tsx`, `app/api/oferta/route.ts` (§ 9.6, 9.9) |
| 6 | Gotowe | `/kalkulator/sukces` | **brak** | `app/kalkulator/sukces/page.tsx` (§ 9.7) |

Dodatkowo: `/wykluczenie/wiek` – przekierowanie z kroku 1, gdy wiek poza zakresem. [korekta repo: treść znana, § 9.8; jest też `/wykluczenie/zdrowie` po wykluczeniu w ankiecie]

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

Wnioski ze stanu (to jedyne ślady kroków 2–4): ankieta kończy się samą flagą logiczną `questionnaireComplete` (odpowiedzi nie są przechowywane w store); „Weryfikacja” ustawia flagę `turnstileVerified`, więc najpewniej jest to Cloudflare Turnstile; w kroku „Oferta” wybiera się produkt, wariant i dodatki. [korekta repo: wszystkie trzy wnioski potwierdzone; store w `gohestia/store/calculator-store.ts:5-52`, komentarz „NIE używamy persist — dane medyczne nie mogą trafić do localStorage” w l. 27]

## 2. Pola i walidacje

| Krok | Pole | Typ | Wymagane | Walidacja | Komunikat błędu |
|---|---|---|---|---|---|
| 1 Wiek | `birthdate` „Data urodzenia” | `input type="date"` | tak (sprawdzane w `onSubmit`) | `min` = 1 stycznia roku (dziś − 66 lat) (`format(subYears(now,66),"yyyy-01-01")`); `max` = dziś − 18 lat (`yyyy-MM-dd`). Po wysłaniu `getAgeGroup(new Date(value))`: wiek = `differenceInYears(new Date(), data)`; `<18` lub `>=66` → `null` → `router.push("/wykluczenie/wiek")`; inaczej zapis `ageGroup` i `birthDate` w store, potem `router.push("/kalkulator/ankieta")` | puste: „Podaj datę urodzenia.” (czyszczony przy `onChange`). Brak komunikatu dla wieku poza zakresem (jest przekierowanie) |
| Strona główna (podgląd) | „Twój wiek” | `input type="number"`, `min=18`, `max=65`, placeholder „np. 35” | nie | `parseInt`; 18–53 → A1, 54–59 → A2, 60–65 → B | „Ubezpieczenie dostępne dla osób w wieku 18–65 lat.” (gdy wartość jest wpisana, ale NaN lub poza 18–65); gdy puste: „Wpisz wiek, aby zobaczyć Twoje składki” |
| 2 Ankieta | 5 bloków oświadczeń [korekta repo] | 2 przyciski NIE/TAK na blok | tak, wszystkie 5 | dalej tylko gdy wszystkie = NIE; TAK → modal wykluczenia (§ 9.3) | brak komunikatu; modal „Niestety nie możesz przystąpić do Grupy Otwartej” |
| 3 Weryfikacja | Turnstile [korekta repo: potwierdzone] | widżet | tak | `POST /api/turnstile` → `siteverify` (§ 9.4) | „Weryfikacja nie powiodła się. Spróbuj ponownie.” |
| 4 Oferta | produkt / wariant / dodatki | wybór | produkt i wariant (przycisk dalej pojawia się po wyborze wariantu) | Global Doctors tylko przy wieku <64 (`isGlobalDoctorsEligible`) (§ 9.5) | brak; GD wyłączony z opisem „Niedostępne dla osób powyżej 63 r.ż.” |
| 5 Podsumowanie | imię, nazwisko, e-mail, telefon, region + 14 zgód/oświadczeń [korekta repo] | tekst / e-mail / tel / checkbox | wszystko oprócz regionu i 3 zgód dobrowolnych | Zod w przeglądarce (§ 9.6) | „Min. 2 znaki”, „Nieprawidłowy adres email”, „Nieprawidłowy numer telefonu”, „Wymagana zgoda” |

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

**Zgody i klauzule formularza: w dostępnym kodzie nie ma ani jednej.** FAQ potwierdza, że zgody istnieją: „Zgodę na przetwarzanie danych oraz udział w ubezpieczeniu możesz wycofać w dowolnym momencie…”. Ich treść jest w niepobranych krokach lub na stronach `/rodo`, `/polityka-prywatnosci`, `/regulamin`. [korekta repo: krok 5 ma 7 zgód obowiązkowych, 4 oświadczenia i 3 zgody dobrowolne, pełne treści w § 9.6; strony prawne w § 9.10]

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

Legenda: ★ = wiersz wyróżniony (`highlight`, tło `bg-yellow-50`); „—” = brak świadczenia lub wartość `null`. Formatowanie (`0vqvpp9_0rpw6.js`, moduł 19489): `toLocaleString("pl-PL")` + „ zł” / „ zł/dzień” / „ zł/1%” albo przedrostek „do …”. W pl-PL separator tysięcy pojawia się dopiero od 10 000 (np. „1600 zł”, „10 000 zł”). Wiersze „Leczenie szpitalne NW” mają w źródle wartości tekstowe typu „120/50 zł”, bez objaśnienia, co oznaczają obie liczby (do potwierdzenia). [korekta repo: interpretacja w § 9.10]

**Reguły tabeli świadczeń** (`getBenefits(grupa, produkt, wariant)`):
- Grupa B korzysta z tabeli B, a grupy A1 i A2 ze wspólnej tabeli A. Indeks kolumny pochodzi z map `a` (A) i `l` (B).
- Wiersze „Pakiet ubezpieczonego” pokazywane są zawsze. Wiersze „Pakiet małżonek / partner” tylko dla `dla_nas` i `dla_rodziny` i tylko z wartością różną od „—”. Wiersze „Pakiet dziecko” tylko dla `dla_rodziny` i również z wartością różną od „—”.
- W tabeli A wiersze NW mają nazwy „… ruch lądowy/wodny/powietrzny”, a w tabeli B „… ruch lądowy”. W A świadczenie to „Poważne zachorowanie (56 j.ch.)”, w B „Poważne zachorowanie (34 j.ch.)”.

**Tabela na stronie głównej** (komponent `j`): kolumny to warianty z list `z` (A) / `f` (B) przefiltrowane przez `PREMIUMS[grupa][produkt]`. W nagłówku każdej kolumny jest składka „{monthly} zł/mies.”, a na końcu kolumna „Karencja”. Bez wpisanego wieku stosowana jest grupa **A1**. Lista `z` nie zawiera wariantu `podstawowy` dla `dla_mnie` i `dla_nas`, więc dla A2 strona główna **nie pokazuje** wariantów Podstawowy 50 zł (Dla Mnie) i 70 zł (Dla Nas), choć są w `PREMIUMS`.

**Niespójności do wyjaśnienia ze zleceniodawcą** (wynikają wprost z kodu i treści):
1. „od 57 zł” (strona główna i FAQ) kontra A2 Dla Mnie Podstawowy = **50 zł** w `PREMIUMS`.
2. „56 chorób objętych” kontra katalog: 57 pozycji, „Zakres MAKSYMALNY 34”, „Zakres KOMFORT 56”. W tabelach A ma „56 j.ch.”, a B „34 j.ch.”, więc nazwy zakresów („maksymalny” = 34 < „komfort” = 56) wyglądają na odwrócone albo nieintuicyjne. [korekta repo: nazwy pochodzą z WU ER 01/25, tabela w § 40 ust. 9 (`gohestia/public/dokumenty/OWU.pdf` s. 42–44) – to nie błąd aplikacji. Otwarte zostaje, który wariant korzysta z którego zakresu i czy hasło „56 chorób” może dotyczyć grupy B]
3. Daty: „OWU (kod ER 01/25). Obowiązuje od 2.06.2025 r.” kontra katalog i dodatki „Obowiązuje od 13.02.2026”. [korekta repo: 13.02.2026 to data erraty ER/EHZ01/2602 dołączonej do OWU.pdf (s. 148)]
4. „wiek 18–65 lat w dniu objęcia ochroną” i FAQ „Wiek w dniu przystąpienia decyduje” kontra kod, który liczy wiek na dziś. [korekta repo: WU wiążą wiek z dniem podpisania certyfikatu uczestnictwa – „ukończyła 18 lat i nie ukończyła 66. roku życia” (OWU.pdf s. 3)]
5. Global Doctors: cena nieznana („podana przy wycenie”); w kalkulatorze dodaje 0 zł.
6. „Zgon rodzica/teścia” w tabeli B występuje tylko w Dla Rodziny Rozszerzony (1600 zł), a w karcie produktu „Dla Nas” jest cecha „Zgon rodziców i teściów”. W tabeli A ma go Dla Nas tylko w wariancie Komfort (1200 zł).

## 5. Wysyłka danych

> [korekta repo] Poniższe ustalenia z kodu klienckiego są nieaktualne. Aplikacja **nie używa server actions**. Używa dwóch route handlerów wywoływanych `fetch` z JSON: `POST /api/turnstile` (krok 3) i `POST /api/oferta` (krok 5). Dane trafiają tylko do e-maili Resend. Data urodzenia i ankieta nie są wysyłane. Turnstile działa tylko w kroku 3. Szczegóły: § 9.9.

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
- Przekierowania: `/wykluczenie/wiek` (wiek poza zakresem). Brak strażników kroków w dostępnym kodzie, więc nie wiadomo, czy wejście bezpośrednio na `/kalkulator/produkt` bez wieku jest blokowane (to sprawdzają niepobrane strony). [korekta repo: kroki 2–5 mają strażników w `useEffect` (`router.replace` do pierwszego niespełnionego kroku), np. `gohestia/app/kalkulator/podsumowanie/page.tsx:109-114`; tabela w § 9.2]
- [repo] Analityka: polityka prywatności deklaruje Cloudflare Web Analytics, ale w kodzie nie ma skryptu beacona, a CSP (`gohestia/next.config.ts:14-21`) by go zablokowała. Jeśli analityka działa, to włączona po stronie Cloudflare – do sprawdzenia u zleceniodawcy.
- Linki zewnętrzne w treści: `zgloszenieroszczenia.ergohestia.pl`, `mailto:[e-mail biura Aura Expert]`, `https://rpu.knf.gov.pl`, `www.rf.gov.pl`.
- Zasoby graficzne: `/ergo-hestia-logo.jpg`, `/girl.jpg`, `/para.jpg`, `/family.jpg` (do zastąpienia w portalu; logo ERGO Hestia wymaga zgody na użycie znaku). [repo] Także wideo `/hero-family.mp4` w panelu hero strony głównej (`<video autoPlay muted loop playsInline>`, tylko od `md`; `gohestia/app/page.tsx:125-133`) – do zastąpienia. Logo używają `gohestia/components/site-header.tsx:8` i `gohestia/app/kalkulator/layout.tsx:10`, zdjęcia – karty produktów (`gohestia/app/page.tsx:25,36,47`).
- Kolorystyka źródła: czerwień ERGO `#E4002B` / `#c00025` (hover). W portalu zastępuje ją styl „old money glass” (makiety v3).

## 7. Czego NIE da się odtworzyć z kodu klienckiego – do uzyskania od zleceniodawcy

> [korekta repo] Status po analizie repozytorium: pkt 1–6 i 9 – znane z kodu (§ 9). Zostaje akceptacja ankiety przez ERGO Hestię, zatwierdzenie tekstów prawnych i decyzja o miejscu zapisu. Pkt 7 (cena Global Doctors) – nadal brak. Pkt 8 – definicje i flaga KOMFORT znane (`gohestia/app/katalog-zachorowan/katalog.tsx:7-575`). Pkt 10 – częściowo wyjaśniony. Pkt 11 – OWU ER 01/25 jest w repozytorium, brak WU GD 02/24 i informacji o dystrybutorze. Pkt 12 – taryfy w kodzie potwierdzone maszynowo, aktualność do potwierdzenia. Pełne zestawienie: „Zamknięcie braków po analizie repozytorium gohestia”.

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

> [korekta repo] Uwagi poniżej pozostają aktualne jako zalecenia dla portalu. Kod potwierdził obawy: Turnstile nie chroni `/api/oferta`, składka z przeglądarki nie jest przeliczana na serwerze, zgody nie są zapisywane. Ustalenia z repozytorium: § 9.11.

- **Klucze**: w pobranych plikach nie znaleziono anon key Supabase, sitekey Turnstile ani tokenów. Nie ma czego rotować z tej analizy.
- **Dane o zdrowiu (art. 9 RODO)**: według treści ankieta jest przetwarzana wyłącznie lokalnie i nie jest wysyłana. Kod tego nie dowodzi, bo chunk ankiety nie był dostępny. W portalu warto zachować tę zasadę: ankieta w 100% po stronie klienta, a do serwera trafia co najwyżej wynik „kwalifikuje się / do agenta”. Jeśli kiedykolwiek wysyłane byłyby same odpowiedzi, potrzebna jest wyraźna zgoda z art. 9 ust. 2 lit. a i osobna podstawa w klauzuli.
- **Data urodzenia**: trzymana tylko w pamięci karty. W portalu nie wysyłać jej, wystarczy grupa wiekowa i ewentualnie flaga uprawnienia do Global Doctors (wiek < 64). Pozwala to dotrzymać zdania „Nie przechowujemy Twojej daty urodzenia…”.
- **Logika cen po stronie klienta**: składka liczona w przeglądarce. Przy wysyłce oferty serwer powinien ją przeliczyć ponownie z tej samej tabeli i nie ufać kwocie z klienta.
- **Turnstile**: weryfikację tokenu trzeba robić po stronie serwera (Workers) w tej samej akcji, która zapisuje lead. Sama flaga `turnstileVerified` w store klienta nie chroni przed botami.
- **Strażnicy kroków**: stan w pamięci sprawia, że bezpośrednie wejście na późniejszy krok ma pusty store. Portal powinien przekierować do kroku 1.
- **Obowiązki informacyjne**: Informacja o agencie (art. 22 UDU) jest kompletna w `go_informacja-o-agencie.md`. Brakuje klauzuli informacyjnej RODO dla formularza (administrator: agent czy ERGO Hestia, odbiorcy, okres przechowywania), do uzyskania (pkt 7.4).
- **Spójność komunikacji**: twierdzenia „bez badań lekarskich”, „od 57 zł”, „56 chorób” oraz wypłaty „nawet do 500 000 zł” (to suma tylko dla „Zgon NW przy pracy — ruch lądowy/wodny/powietrzny”, A, Dla Mnie Prestiż) wymagają zgodności z OWU i taryfą. Przy przenoszeniu do portalu warto doprecyzować ostatnie zdanie („za zgon w wyniku NW przy pracy…”).
- `branzowe.html` ładuje skrypt Cloudflare challenge-platform. To inna aplikacja (SvelteKit), bez związku z formularzem ERGO.

## 9. Uzupełnienie z repozytorium `gohestia` (2026-11-13)

### 9.1 Źródło, technologia, wdrożenie

- Repozytorium: kod aplikacji `ergo.beautypolisa.eu`, commit `e186f2a` z 12.07.2026. `CLAUDE.md` odsyła do `AGENTS.md`, czyli ostrzeżenia o zmianach API Next.js. `README.md` to szablon `create-next-app`.
- Stos (`gohestia/package.json:13-40`):
  - Next.js 16.2.9 (App Router), React 19.2.4;
  - Zustand 5 (bez `persist`), react-hook-form 7 + Zod 4;
  - Resend 6 + `@react-email/components`, `@marsidev/react-turnstile`, date-fns 4, lucide-react;
  - wdrożenie: `@opennextjs/cloudflare` i wrangler 4.
- **Brak** bazy danych, Supabase, KV i D1. `wrangler.jsonc` ma tylko Worker `gohestia`, `nodejs_compat` i binding `ASSETS` (`gohestia/wrangler.jsonc:1-11`).
- Wdrożenie: GitHub Actions przy pushu do `main` uruchamia `npm ci` i `opennextjs-cloudflare build && deploy` (`gohestia/.github/workflows/deploy.yml:5-60`). Workflow potrzebuje sekretów `CLOUDFLARE_API_TOKEN` i `CLOUDFLARE_ACCOUNT_ID` (wartości w konfiguracji, nie w dokumencie). Sekrety działającej aplikacji są ustawione po stronie Cloudflare: `RESEND_API_KEY`, `AGENT_EMAIL`, `TURNSTILE_SECRET_KEY`, `FROM_EMAIL` (`deploy.yml:55-58`). Opcjonalne zmienne to `SITE_URL` i `NEXT_PUBLIC_TURNSTILE_SITE_KEY` (`gohestia/app/api/oferta/route.ts:89-92`, `gohestia/lib/turnstile-config.ts:7-8`).
- Nagłówki dla wszystkich ścieżek (`gohestia/next.config.ts:4-25`):
  - `X-Frame-Options: DENY`, `nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`;
  - `Permissions-Policy` bez kamery, mikrofonu i geolokalizacji;
  - CSP `default-src 'self'` z `'unsafe-inline'` dla skryptów i stylów; `challenges.cloudflare.com` dopuszczone w `script-src`, `frame-src` i `connect-src`.

### 9.2 Kroki, przejścia i strażnicy

Stan kalkulatora jest tylko w pamięci karty (`gohestia/store/calculator-store.ts:27-52`). Strażnicy w `useEffect` cofają użytkownika do pierwszego niespełnionego kroku za pomocą `router.replace`. Do tego czasu strona renderuje `null`.

| Krok | Ścieżka | Warunek wejścia (strażnik) | Akcja „dalej” | Źródło |
|---|---|---|---|---|
| 1 Wiek | `/kalkulator/wiek` | brak | `getAgeGroup` → `null`: `/wykluczenie/wiek`; inaczej zapis `ageGroup`, `birthDate` → `/kalkulator/ankieta` | `gohestia/app/kalkulator/wiek/page.tsx:17-29` |
| 2 Ankieta | `/kalkulator/ankieta` | `ageGroup` | wszystkie 5 = NIE → `questionnaireComplete=true` → `/kalkulator/weryfikacja` | `gohestia/app/kalkulator/ankieta/page.tsx:11-15`; `gohestia/components/questionnaire/index.tsx:64-69` |
| 3 Weryfikacja | `/kalkulator/weryfikacja` | `ageGroup`, `questionnaireComplete` | token Turnstile → `POST /api/turnstile` 200 → `turnstileVerified=true` → `/kalkulator/produkt` | `gohestia/app/kalkulator/weryfikacja/page.tsx:14-43` |
| 4 Oferta | `/kalkulator/produkt` | jw. + `turnstileVerified` | przycisk po wyborze wariantu → `/kalkulator/podsumowanie` | `gohestia/app/kalkulator/produkt/page.tsx:29-35,152-157` |
| 5 Podsumowanie | `/kalkulator/podsumowanie` | jw. + `selectedProduct`, `selectedVariant` | `POST /api/oferta` 200 → `/kalkulator/sukces?email=…` | `gohestia/app/kalkulator/podsumowanie/page.tsx:109-120,133-168` |
| 6 Gotowe | `/kalkulator/sukces` | brak | `reset()` całego store przy wejściu | `gohestia/app/kalkulator/sukces/page.tsx:12-17` |
| — | `/wykluczenie/wiek` | brak (poza layoutem kalkulatora, bez Steppera) | linki | `gohestia/app/wykluczenie/wiek/page.tsx` |
| — | `/wykluczenie/zdrowie` | brak (poza layoutem kalkulatora) | linki | `gohestia/app/wykluczenie/zdrowie/page.tsx` |

Layout kalkulatora (`gohestia/app/kalkulator/layout.tsx:3-40`) ma logo ERGO Hestia, napisy „Aura Expert sp. z o.o.”, „ERGO Razem Kalkulator”, „Grupa Otwarta”, „ER 01/25” i Stepper. Nie ma stopki. Kroki Steppera i ich ścieżki zgadzają się z § 1 (`gohestia/components/stepper.tsx:5-12`).

Krok 1 (`gohestia/app/kalkulator/wiek/page.tsx`) jest zgodny z § 2: `max` = dziś − 18 lat, `min` = 1 stycznia roku sprzed 66 lat (l. 14-15), błąd „Podaj datę urodzenia.” (l. 19), teksty w l. 35-74.

### 9.3 Krok 2 – ankieta medyczna

Nagłówek: „Ankieta medyczna”. Podtytuł: „Odpowiedz na 5 pytań — są one wymagane do oceny możliwości przystąpienia do Grupy Otwartej.” (`gohestia/app/kalkulator/ankieta/page.tsx:19-22`).

Ramka nad pytaniami (`gohestia/components/privacy-notice.tsx:11-15`; prop `dismissible` nieużywany): „Odpowiedzi na pytania dotyczące stanu zdrowia są przetwarzane **wyłącznie lokalnie w Twojej przeglądarce** i nie są nigdzie wysyłane ani zapisywane.”

Każdy blok (`gohestia/components/questionnaire/question-block.tsx`) ma nadtytuł „Pytanie {n} z 5” (l. 27), tytuł, deklarację, listę warunków, opcjonalnie rozwijane „Wyjątki od tej reguły” (l. 51) i dwa przyciski: „NIE (spełniam warunek)” (wartość `false`, l. 78) oraz „TAK” (wartość `true`, l. 91). Kolory: NIE – zielona ramka, TAK – czerwona.

Pytania dosłownie (`gohestia/lib/data/questionnaire.ts:9-85`):

**Pytanie 1 – Choroby z ostatnich 5 lat.** „Oświadczam, że w okresie ostatnich 5 lat nie rozpoznano u mnie, nie byłem(am) leczony(a) ani nie przebywałem(am) pod stałą opieką lekarską z powodu następujących schorzeń:”
- choroby niedokrwiennej serca, zawału serca, wady serca, zaburzeń rytmu serca, kardiomiopatii, miażdżycy, tętniaka
- cukrzycy (z wyjątkiem podwyższonego poziomu glukozy we krwi w okresie ciąży)
- nowotworu złośliwego, choroby krwi (niedokrwistości aplastycznej, białaczki, chłoniaka, szpiczaka, zespołu mielodysplastycznego, niedokrwistości sierpowatokrwinkowej, talasemii, hemofilii lub trombofilii), nowotworu łagodnego mózgu lub rdzenia kręgowego
- udaru mózgu, krwotoku śródmózgowego, porażenia (paraliżu), przewlekłej niewydolności oddechowej, niewydolności nerek, marskości wątroby, choroby alkoholowej lub uzależnienia od narkotyków, stwardnienia rozsianego, choroby Parkinsona, choroby Alzheimera, AIDS, zakażenia wirusem HIV lub innej choroby, w zakresie której zalecenie lekarskie obejmowało lub obejmuje wykonanie przeszczepu narządu

**Pytanie 2 – Stan obecny.** „Oświadczam, że obecnie:”
- nie zamierzam zasięgać porady lekarskiej, nie oczekuję na wykonanie badań diagnostycznych, nie oczekuję na wyniki takich badań, ani nie zamierzam poddać się leczeniu, w tym leczeniu szpitalnemu z powodu chorób wymienionych w punkcie 1
- nie przebywam w szpitalu, hospicjum, domu pomocy społecznej, sanatorium ani na zwolnieniu lekarskim
- nie jestem uznany(a) za niezdolnego(ą) do pracy lub służby orzeczeniem właściwego organu, według przepisów o ubezpieczeniu społecznym lub zaopatrzeniu społecznym (nie dotyczy kategorii zdolności do odbywania lub pełnienia czynnej służby określanej podczas kwalifikacji wojskowej oraz orzeczenia WKL w procesie ubiegania się o powołanie do WOT)

**Pytanie 3 – Ostatnie 12 miesięcy.** „Oświadczam, że w ciągu ostatnich 12 miesięcy:”
- nie byłem(am) hospitalizowany(a) przez okres dłuższy niż 30 dni
- nie przebywałem(am) na zwolnieniu lekarskim przez okres dłuższy niż 30 dni

Wyjątki od tej reguły: złamań / zwichnięć / skręceń / stłuczenia kończyn; usunięcia wyrostka robaczkowego; usunięcia migdałków podniebiennych; usunięcia woreczka żółciowego (o ile powodem była kamica); ciąży (o ile w trakcie nie wystąpiły schorzenia leczone w dniu objęcia ochroną); porodu; opieki nad osobą trzecią (zasiłek opiekuńczy, zwolnienie np. na dziecko/małżonka); przeprowadzenia artroskopii; operacji: przepukliny brzusznej/pachwinowej, hemoroidów, zaćmy, przegrody nosa.

**Pytanie 4 – Wykluczony zawód.** „Oświadczam, że obecnie nie wykonuję żadnego z wymienionych zawodów:” górnika; kaskadera; konwojenta wartości pieniężnych; członka personelu statku powietrznego (nie dotyczy personelu licencjonowanych linii lotniczych); policjanta; ratownika górskiego; ratownika wodnego; robotnika rozbiórki budowli; sportowca zawodowego; strażaka zawodowego (nie dotyczy strażaka OSP); żołnierza zawodowego (nie dotyczy żołnierza WOT niebędącego żołnierzem zawodowym).

**Pytanie 5 – Czynności niebezpieczne.** „Oświadczam, że obecnie wykonywany zawód nie jest związany z podejmowaniem czynności uznawanych za niebezpieczne:” praca pod ziemią; praca pod wodą; praca na wysokości powyżej 10 metrów; praca z bronią palną; praca z materiałami wybuchowymi lub radioaktywnymi bądź ich wytwarzanie; praca na platformach wydobywczych lub przy ich obsłudze; praca w służbach specjalnych; wspinaczka wysokogórska; udział w wyścigach/rajdach samochodowych lub motocyklowych.

**Reguły kwalifikacji** (`gohestia/components/questionnaire/index.tsx`):
- Odpowiedź na blok jest jedna: `true` (TAK) albo `false` (NIE). Nie ma odpowiedzi na pojedyncze schorzenia (l. 48-50).
- TAK w dowolnym bloku natychmiast otwiera modal wykluczenia (l. 55-62).
- „Przejdź dalej →” jest aktywny tylko wtedy, gdy wszystkie 5 odpowiedzi to NIE (`answers.every(a => a === false)`, l. 64, 90-96).
- Po „Wróć do ankiety” można zmienić TAK na NIE. Kod nie blokuje takiej zmiany ani nie zapamiętuje wcześniejszej odpowiedzi TAK.
- Wyjątki w pytaniu 3 są tylko informacją. Kod nie ma dla nich logiki – ocenę robi użytkownik.
- Kod nie ma ścieżki „do agenta”. Każde TAK oznacza wykluczenie z Grupy Otwartej i odesłanie do polisy indywidualnej.
- Ankieta dotyczy tylko przystępującego. Nie ma pytań o małżonka, partnera ani dzieci, także w „Dla Nas” i „Dla Rodziny”.

**Modal wykluczenia** (`gohestia/components/questionnaire/index.tsx:13-45`): „⚠️” / „Niestety nie możesz przystąpić do Grupy Otwartej” / „Na podstawie udzielonej odpowiedzi nie spełniasz warunków przystąpienia do grupowego ubezpieczenia ERGO Razem w trybie Grupy Otwartej.” / „Możesz jednak ubiegać się o indywidualną polisę na życie — może ona wymagać wypełnienia szczegółowej ankiety medycznej lub poddania się badaniom na koszt ubezpieczyciela.” Przyciski: „Sprawdź polisę indywidualną →” (→ `/wykluczenie/zdrowie`) i „Wróć do ankiety” (zamyka modal).

**Czy odpowiedzi opuszczają przeglądarkę: nie.** Odpowiedzi są tylko w `useState` komponentu (`index.tsx:48-50`). Do store trafia wyłącznie `questionnaireComplete=true` (`index.tsx:66-69`). Ładunek `/api/oferta` nie zawiera ankiety (`gohestia/app/kalkulator/podsumowanie/page.tsx:139-151`). Ten sam stan deklarują `/rodo` § 4, `/polityka-prywatnosci` § 3 i regulamin § 3.

Uwagi dla portalu:
- Oświadczenia są przeczące („Oświadczam, że … nie …”), a „TAK” oznacza wykluczenie. Grozi to pomyłką. W portalu lepiej zadać pytania wprost („Czy w ciągu ostatnich 5 lat…?”), po akceptacji ERGO Hestii.
- WU ER 01/25 uzależniają przystąpienie od przekazania „informacji o stanie zdrowia i wykonywanym zawodzie” (OWU.pdf s. 3). ERGO Hestia musi potwierdzić, że te 5 bloków to aktualna i pełna wersja.

### 9.4 Krok 3 – Weryfikacja (Turnstile)

Treści (`gohestia/app/kalkulator/weryfikacja/page.tsx:47-66`): „Potwierdź, że nie jesteś robotem, aby przejść dalej.”, w trakcie: „Weryfikacja…”, po błędzie: „Weryfikacja nie powiodła się. Spróbuj ponownie.”

Mechanizm (bez kluczy):
1. Widżet `@marsidev/react-turnstile` z publicznym site key. Site key jest zapisany na stałe w `gohestia/lib/turnstile-config.ts:7-8` (wartość pominięta), z możliwością nadpisania przez `NEXT_PUBLIC_TURNSTILE_SITE_KEY`.
2. `onSuccess(token)` wysyła `POST /api/turnstile` z ciałem `{token}` (`weryfikacja/page.tsx:26-43`).
3. Serwer (`gohestia/app/api/turnstile/route.ts:1-32`) wywołuje `siteverify` z sekretem `TURNSTILE_SECRET_KEY` (wartość w konfiguracji, nie w dokumencie). Nie sprawdza `hostname`, `action` ani `remoteip`. Odpowiedzi:
   - 200 `{ok:true}`;
   - 400 `{error:"Nieprawidłowe dane"}` albo `{error:"Brak tokenu"}`;
   - 403 `{error:"Weryfikacja nieudana"}`;
   - 500 `{error:"Konfiguracja Turnstile"}`.
4. Odpowiedź 200 ustawia w store `turnstileVerified=true` i przenosi do `/kalkulator/produkt`. Błąd, `onError` albo `onExpire` resetuje widżet (l. 21-24).

**Weryfikacja nie jest powiązana z wysyłką.** `/api/oferta` nie przyjmuje tokenu ani sesji. Flaga istnieje tylko w przeglądarce. `gohestia/lib/turnstile.ts` (`verifyTurnstileToken`) to martwy kod, nigdzie nieimportowany.

### 9.5 Krok 4 – Oferta (`/kalkulator/produkt`)

Źródło: `gohestia/app/kalkulator/produkt/page.tsx`. Sekcje pojawiają się po kolei:

1. „Wybierz zakres ochrony” / „Kogo chcesz objąć ubezpieczeniem?” – 3 kafle (l. 14-18, 47-67): „👤 Dla Mnie – Ubezpieczenie indywidualne (Ty)”, „👫 Dla Nas – Ty + małżonek / partner”, „👨‍👩‍👧‍👦 Dla Rodziny – Ty + partner + dzieci + rodzice”. Zmiana produktu zeruje wariant. Dodatki zostają (`gohestia/store/calculator-store.ts:41-45`).
2. Po wyborze produktu: „Wybierz wariant” / „Dla grupy wiekowej **{A1|A2|B}** dostępne warianty:” (l. 72-75). Karty pokazują wszystkie warianty z `PREMIUMS[grupa][produkt]` (`gohestia/lib/calculator.ts:13-15`), także A2 Podstawowy 50 i 70 zł, których nie ma na stronie głównej. Karta zawiera etykietę, „{monthly} zł/mies.”, znacznik „Wybrany” i ✓ przy 4 pierwszych nazwach z `COVERAGE` (`gohestia/components/product-card.tsx:22-57`). Wariantu domyślnego nie ma.
3. Po wyborze wariantu: przełącznik „Zobacz pełny zakres świadczeń” (l. 97) z tabelą „Świadczenie / Kwota / Karencja” (`gohestia/components/benefits-table.tsx:26-28`; nagłówki „Pakiet ubezpieczonego”, „Pakiet małżonek/partner”, „Pakiet dziecko”).
4. „Dodatki” / „Rozszerz ochronę o pakiety medyczne:” (l. 112-138):
   - „MediPlan” „+9 zł/mies.” – „Dostęp do lekarzy specjalistów, badań i rehabilitacji”;
   - „Medical Assistance” „+6 zł/mies.” – „Pomoc medyczna 24/7, transport medyczny, wizyty domowe”;
   - „Global Doctors” „wycena wg wieku” – „Dostęp do lekarzy na całym świecie (do 63 r.ż.)”, a przy wieku ≥ 64 wyłączony z opisem „Niedostępne dla osób powyżej 63 r.ż.”.
5. Ramka „Łączna składka miesięczna” / „{total} zł” / „/ miesiąc”, przy Global Doctors dopisek „+ Global Doctors: wycena indywidualna” (`gohestia/components/premium-calculator.tsx:17-33`). Przycisk „Przejdź do podsumowania →” (l. 152-157).

Wykryte problemy:
- **Podwójne liczenie dodatków.** `monthly = calcMonthlyPremium(...)` już zawiera 9 i 6 zł (`gohestia/lib/calculator.ts:24-27`). `PremiumCalculator` dodaje je drugi raz (`premium-calculator.tsx:18-20`). Przykład: A1 Dla Mnie Rozszerzony + MediPlan to 75 zł w kroku Oferta i 66 zł w Podsumowaniu oraz w e-mailu.
- **`COVERAGE` to dane zastępcze** niezgodne z tabelą świadczeń (`gohestia/lib/data/coverage.ts:8-53`, np. „20 chorób objętych ochroną”, „Renta miesięczna”, „Zwrot kosztów”). Na kartach widać 4 te same pozycje dla każdego wariantu: „Śmierć ubezpieczonego”, „Śmierć w wyniku NW”, „Trwała niezdolność do pracy”, „Poważne zachorowanie”. `WAITING_PERIODS` (l. 55-62) są nieużywane. **Nie przenosić do portalu.**
- **Przełączniki dodatków są niedostępne z klawiatury.** `<label>` nie ma pola `input`. Przełącza tylko kliknięcie w suwak (`div` z `onClick`), a kliknięcie w etykietę nic nie robi (`gohestia/components/addon-toggle.tsx:15-38`).

### 9.6 Krok 5 – Podsumowanie i formularz kontaktowy

**Podsumowanie oferty** (`gohestia/app/kalkulator/podsumowanie/page.tsx:173-205`): „Twoja oferta”, pola „Produkt”, „Wariant”, „Dodatki” (etykiety z `ADDONS`), „Składka miesięczna” „{monthly} zł/mies.” liczona raz z `calcMonthlyPremium`, „Pełny zakres świadczeń” (tabela) i stopka „Szczegóły w OWU (kod ER 01/25). Obowiązuje od 2.06.2025 r.”

**Formularz** (l. 209-261): „Dane kontaktowe” / „Dane kontaktowe i wybrana konfiguracja oferty zostaną przekazane agentowi ubezpieczeniowemu. **Nie przekazujemy danych medycznych.**”

| Pole | Etykieta | Typ | Walidacja w przeglądarce (Zod, l. 17-22) | Komunikat | Walidacja na serwerze (`gohestia/app/api/oferta/route.ts:40-44`) |
|---|---|---|---|---|---|
| `imie` | „Imię *” | text | 2–50 znaków | „Min. 2 znaki” (dla max brak własnego komunikatu) | `min(1)` |
| `nazwisko` | „Nazwisko *” | text | 2–50 znaków | „Min. 2 znaki” | `min(1)` |
| `email` | „Email *” | email | `email()` | „Nieprawidłowy adres email” | `email()` |
| `telefon` | „Telefon *”, placeholder „+48 500 600 700” | tel | `/^\+?[0-9\s\-]{9,15}$/` | „Nieprawidłowy numer telefonu” | dowolny string |
| `agent_region` | „Region (opcjonalnie)”, placeholder „np. Warszawa, Kraków...” | text | opcjonalne | — | **nie jest wysyłane** |

**Zgody i oświadczenia** – kolejność na ekranie i treść dosłownie (l. 263-422). Obowiązkowe mają `z.literal(true, {message: 'Wymagana zgoda'})`, dobrowolne `z.boolean().optional()` (l. 15, 23-38). Żadna nie jest zaznaczona domyślnie. Etykieta widnieje przy polu wyboru, a pełną treść rozwija „czytaj całość” / „zwiń” (l. 43-68). Obowiązkowe poprzedza gwiazdka „* ”.

Nagłówek sekcji: „Zgody obowiązkowe — wymagane do objęcia ochroną”

1. `zgoda_1` (wymagana) – „Zgoda na objęcie grupowym ubezpieczeniem na życie”:
   > Wyrażam zgodę na objęcie mnie grupowym ubezpieczeniem na życie, zawartym przez wskazanego w niniejszym dokumencie Ubezpieczającego z Sopockim Towarzystwem Ubezpieczeń na Życie ERGO Hestia SA, zgodnie z treścią tej umowy i Warunkami Ubezpieczenia, które będą mnie obowiązywały jako Ubezpieczonego. Od wyrażenia zgody na powyższe uzależnia się objęcie ochroną ubezpieczeniową.
2. `zgoda_2` (wymagana) – „Upoważnienie do uzyskania informacji od NFZ”:
   > Upoważniam ERGO Hestię do uzyskiwania, na podstawie art. 38 ust. 8 ustawy z dnia 11 września 2015 r. o działalności ubezpieczeniowej i reasekuracyjnej, od Narodowego Funduszu Zdrowia danych o nazwach i adresach świadczeniodawców, którzy udzielili mi świadczeń opieki zdrowotnej w związku z oceną ryzyka ubezpieczeniowego i weryfikacją podanych przeze mnie danych o moim stanie zdrowia, jak również w związku z wypadkiem lub zdarzeniem losowym, będącym podstawą ustalenia odpowiedzialności oraz wysokości odszkodowania lub świadczenia. Z uwagi na niezbędność niniejszego upoważnienia dla celów należytego wykonania umowy ubezpieczenia, tj. do ustalania odpowiedzialności ERGO Hestii i wypłaty świadczeń należnych z umowy ubezpieczenia powyższe upoważnienie jest nieodwołalne w okresie trwania ochrony ubezpieczeniowej oraz przez 3 lata od daty jej zakończenia i obowiązuje również po mojej śmierci. Od udzielenia niniejszego upoważnienia uzależnia się objęcie ochroną ubezpieczeniową.
3. `zgoda_3` (wymagana) – „Upoważnienie do uzyskania informacji od podmiotów wykonujących działalność leczniczą”:
   > Upoważniam ERGO Hestię na podstawie art. 38 ust. 6 ustawy z dnia 11 września 2015 r. o działalności ubezpieczeniowej i reasekuracyjnej, do uzyskiwania, również po mojej śmierci, od każdego z podmiotów wykonujących działalność leczniczą, które udzielały mi świadczeń zdrowotnych, informacji o okolicznościach związanych z oceną ryzyka ubezpieczeniowego i weryfikacją podanych przeze mnie danych o moim stanie zdrowia, a w przypadku objęcia ochroną ubezpieczeniową, również ustaleniem mojego prawa do świadczenia z zawartej umowy ubezpieczenia i wysokością tego świadczenia. Zakres informacji obejmuje, z wyłączeniem wyników badań genetycznych, informacje o: przyczynach hospitalizacji, wykonywanych w jej trakcie badaniach diagnostycznych i ich wynikach, innych udzielonych świadczeniach zdrowotnych, wynikach leczenia oraz o wynikach sekcji zwłok, jeżeli zostanie przeprowadzona; przyczynach leczenia ambulatoryjnego, wykonywanych w jego trakcie badaniach diagnostycznych i ich wynikach, innych udzielonych świadczeniach zdrowotnych oraz wynikach leczenia; wynikach przeprowadzonych konsultacji; przyczynie śmierci. Z uwagi na niezbędność niniejszego upoważnienia dla celów należytego wykonania umowy ubezpieczenia, tj. do ustalania odpowiedzialności ERGO Hestii i wypłaty świadczeń należnych z umowy ubezpieczenia, powyższe upoważnienie jest nieodwołalne w okresie trwania ochrony ubezpieczeniowej oraz w ciągu 3 lat od daty jej zakończenia i obowiązuje również po mojej śmierci. Od udzielenia niniejszego upoważnienia uzależnia się objęcie ochroną ubezpieczeniową.
4. `zgoda_4` (wymagana) – „Wniosek o komunikację za pomocą środków porozumiewania się na odległość”:
   > Wnioskuję o przesyłanie przez Sopockie Towarzystwo Ubezpieczeń na Życie ERGO Hestię SA korespondencji związanej z wykonywaniem czynności ubezpieczeniowych, w tym doręczenia certyfikatu uczestnictwa, za pomocą środków porozumiewania się na odległość w tym środków komunikacji elektronicznej (telefon, e-mail) na podane przeze mnie dane kontaktowe, a odpowiedzi na złożone reklamacje na wskazany w danych adres e-mail. Od wyrażenia zgody na powyższe uzależnia się objęcie ochroną ubezpieczeniową. Zobowiązuję się do aktualizacji danych.
5. `zgoda_5` (wymagana) – „Zgoda na udostępnianie przez ERGO Hestię danych osobowych każdemu innemu zakładowi ubezpieczeń”:
   > Wyrażam zgodę na udostępnianie przez ERGO Hestię przetwarzanych przez ERGO Hestię moich danych osobowych każdemu innemu zakładowi ubezpieczeń, w zakresie potrzebnym do oceny ryzyka ubezpieczeniowego i weryfikacji podawanych przeze mnie danych, ustalenia mojego prawa do świadczenia z umowy ubezpieczenia i wysokości tego świadczenia, a także do udzielenia posiadanych przez ERGO Hestię informacji o przyczynie mojej śmierci lub informacji niezbędnych do ustalenia mojego prawa do świadczenia i jego wysokości. Od wyrażenia zgody na powyższe uzależnia się objęcie ochroną ubezpieczeniową.
6. `zgoda_6` (wymagana) – „Zgoda na udostępnianie danych osobowych ERGO Hestii przez każdy inny zakład ubezpieczeń”:
   > Wyrażam zgodę na udostępnianie ERGO Hestii moich danych osobowych przetwarzanych przez każdy inny zakład ubezpieczeń, w którym jestem, byłem(am) lub będę ubezpieczony(a) bądź występowałem(am), występuję lub będę występował/a o ubezpieczenie w zakresie potrzebnym do oceny ryzyka ubezpieczeniowego i weryfikacji podawanych przeze mnie danych, ustalenia mojego prawa do świadczenia z umowy ubezpieczenia i wysokości tego świadczenia, a także do udzielenia ERGO Hestii posiadanych przez każdy inny zakład ubezpieczeń informacji o przyczynie mojej śmierci lub informacji niezbędnych do ustalenia mojego prawa do świadczenia i jego wysokości. Od wyrażenia zgody na powyższe uzależnia się objęcie ochroną ubezpieczeniową.
7. `zgoda_9` (wymagana) – „Zgoda na finansowanie składki przez CPOP — Deklaracja przystąpienia do Grupy Otwartej ERGO Razem” (l. 323-353; podziały wierszy jak w źródle):
   ```
   DEKLARACJA FINANSOWANIA SKŁADKI UBEZPIECZENIOWEJ W GRUPIE OTWARTEJ ERGO RAZEM

   1. MISJA CENTRUM POMOCY OSOBOM POSZKODOWANYM SP. Z O.O.
   Celem społecznej misji Centrum Pomocy Osobom Poszkodowanym Sp. z o.o. z siedzibą w Gdańsku przy ul. Jelitkowskiej 49 (dalej: CPOP) jest kompleksowe wsparcie osób poszkodowanych w wypadkach w procesie rehabilitacji medycznej, społecznej i zawodowej. Spółka zdecydowała się zawrzeć z Sopockim Towarzystwem Ubezpieczeń na Życie ERGO Hestia S.A. umowę grupowego ubezpieczenia na życie ERGO Razem, aby ułatwić uzyskanie ochrony ubezpieczeniowej.

   2. CZYM JEST GRUPA OTWARTA ERGO RAZEM
   Grupa Otwarta ERGO Razem to Umowa grupowego ubezpieczenia na życie ERGO Razem zawarta w dniu 01.12.2023 r. przez CPOP jako Ubezpieczającym z ERGO Hestią.

   3. CO JEST KONIECZNE, ABY ZOSTAĆ OBJĘTYM OCHRONĄ
   Aby zostać Ubezpieczonym objętym ochroną w Grupie Otwartej ERGO Razem konieczne jest, oprócz zgody na objęcie ochroną przez ERGO Hestię, również wyrażenie CPOP zgody na finansowanie składki za udzielaną ochronę ubezpieczeniową.

   4. DEKLARACJA
   Zobowiązuję się wobec Centrum Pomocy Osobom Poszkodowanym Sp. z o.o. z siedzibą w Gdańsku do finansowania składki ubezpieczeniowej za udzielaną mi przez ERGO Hestię ochronę w Grupie Otwartej ERGO Razem, tj. do:
   (1) wpłaty pierwszej składki do daty wskazanej w Certyfikacie Uczestnictwa oraz
   (2) terminowego wpłacenia drugiej i następnych składek najpóźniej do 15 dnia miesiąca za kolejny miesiąc, na rachunek bankowy podany w Certyfikacie Uczestnictwa.

   5. CO SIĘ STANIE W PRZYPADKU NIEOPŁACENIA SKŁADKI
   W przypadku nieopłacenia składki w terminie zostanie Pan/Pani poinformowany o braku płatności i obowiązku zapłaty w dodatkowym terminie 7 dni pod rygorem uznania umowy za wypowiedzianą przez CPOP.

   6. CZY UBEZPIECZAJĄCY OTRZYMUJE WYNAGRODZENIE
   CPOP ani osoby działające na jej rzecz nie otrzymują wynagrodzenia ani innych korzyści w związku z oferowaniem możliwości skorzystania z ochrony.

   INFORMACJA O PRZETWARZANIU DANYCH PRZEZ CPOP
   Administratorem danych jest Centrum Pomocy Osobom Poszkodowanym Sp. z o.o., 80-342 Gdańsk, ul. Jelitkowska 49, email: ergorazem@cpop.pl. Inspektor Ochrony Danych: iod@cpop.pl. Dane przetwarzane są w celu objęcia ochroną ubezpieczeniową, dochodzenia roszczeń oraz (po wyrażeniu zgody) marketingu bezpośredniego. Masz prawo dostępu, sprostowania, usunięcia danych oraz wniesienia skargi do PUODO. Od wyrażenia zgody na finansowanie składki uzależnia się objęcie ochroną w Grupie Otwartej ERGO Razem.
   ```

Nagłówek: „Oświadczenia” (wszystkie wymagane, bez rozwijanej treści, l. 359-389)

8. `oswiadczenie_1`: „Oświadczam, że przed przystąpieniem do umowy ubezpieczenia otrzymałem/am Warunki Ubezpieczenia, zapoznałem/am się z ich treścią i w pełni je akceptuję.”
9. `oswiadczenie_2`: „Oświadczam, że przed przystąpieniem do umowy ubezpieczenia nastąpiło zbadanie i określenie moich wymagań oraz potrzeb ubezpieczeniowych.”
10. `oswiadczenie_3`: „Oświadczam, że przed przystąpieniem do umowy ubezpieczenia nastąpiło udostępnienie dokumentu pełnomocnictwa udzielonego dystrybutorowi przez ubezpieczyciela oraz przekazanie wymaganych ustawą o dystrybucji informacji o dystrybutorze.”
11. `oswiadczenie_4`: „Oświadczam, że przed przystąpieniem do umowy ubezpieczenia nastąpiło przekazanie mi w zrozumiałej formie wymaganych ustawowo obiektywnych informacji o proponowanym produkcie ubezpieczeniowym.”

Nagłówek: „Zgody dobrowolne” (l. 392-422)

12. `zgoda_7` (dobrowolna) – „Zgoda na otrzymywanie informacji handlowej drogą elektroniczną (niezbędna do wysłania elektronicznej oferty na e-mail)”:
    > Zgadzam się na otrzymywanie drogą elektroniczną informacji handlowej od Sopockiego Towarzystwa Ubezpieczeń na Życie ERGO Hestia SA w Sopocie, z wykorzystaniem środków porozumiewania się na odległość (telefon, e-mail) przy użyciu podanych przeze mnie danych kontaktowych. Zobowiązuję się do aktualizacji danych. Od wyrażenia zgody na powyższe nie uzależnia się objęcia ochroną ubezpieczeniową.
13. `zgoda_8` (dobrowolna) – „Zgoda na prowadzenie działań marketingowych przez STU ERGO Hestia S.A.”:
    > Wyrażam zgodę na przetwarzanie moich danych osobowych w celach marketingowych, w tym określenia preferencji i potrzeb ubezpieczeniowych, oraz na przesyłanie informacji handlowych przez Sopockie Towarzystwo Ubezpieczeń ERGO Hestia S.A. w Sopocie z wykorzystaniem:
    > • środków komunikacji elektronicznej (w szczególności na podany adres e-mail);
    > • telekomunikacyjnych urządzeń końcowych i automatycznych systemów wywołujących (w szczególności na podany numer telefonu).
    >
    > Twoją zgodę przekażemy do Sopockiego Towarzystwa Ubezpieczeń ERGO Hestia S.A. w Sopocie. Od wyrażenia zgody nie uzależnia się objęcia ochroną ubezpieczeniową.
14. `zgoda_10` (dobrowolna) – „Zgoda dla CPOP na przekazywanie informacji handlowej (dobrowolna)”:
    > Wyrażam zgodę na przekazywanie mi przez Centrum Pomocy Osobom Poszkodowanym sp. z o.o. z siedzibą w Gdańsku na podany przeze mnie adres email informacji handlowej o nowych wariantach ubezpieczenia w Grupie Otwartej ERGO Razem oferowanych przez ERGO Hestię, na podstawie której będę mógł/mogła dokonać zmiany warunków ochrony ubezpieczeniowej. Wyrażoną zgodę mogę cofnąć w każdym czasie i bez podawania przyczyny przesyłając oświadczenie na adres: iod@cpop.pl. Wycofanie zgody nie będzie mieć wpływu na zgodność z prawem przetwarzania przed jej cofnięciem. Zgoda jest dobrowolna — jej brak nie uzależnia objęcia ochroną.

Przypis: „* Pola i zgody obowiązkowe wymagane do objęcia ochroną ubezpieczeniową.” Przycisk: „Wyślij zapytanie do agenta →”, w trakcie wysyłki „Wysyłanie...” (l. 424-431). Błąd wysyłki pokazuje `window.alert`: „Nie udało się wysłać zapytania. Spróbuj ponownie za chwilę.” (l. 163). Szczegóły trafiają do `console.error`. Po sukcesie przekierowanie na `/kalkulator/sukces?email=<adres>` (l. 154).

**Wersjonowanie i zapis zgód: brak.** Nie ma kodu wersji, hasha treści ani znacznika czasu. Żadna zgoda ani oświadczenie nie trafia do `/api/oferta` (l. 139-151) ani do e-maili. Agent nie wie, które zgody dobrowolne klient zaznaczył.

Uwagi prawne do przekazania prawnikowi (nie rozstrzygamy ich tutaj):
- Zgody 1–6 i 9 oraz oświadczenia 1–4 to treść deklaracji przystąpienia i certyfikatu. Formularz jest tylko „zapytaniem do agenta”, a FAQ mówi: „Formularz służy wyłącznie do przedstawienia oferty”. Tu jest sprzeczność, powiązana z W5.
- `oswiadczenie_1` („otrzymałem/am Warunki Ubezpieczenia”): przed wysyłką żadna strona kalkulatora nie linkuje do WU. PDF miał trafić dopiero do e-maila, a najpewniej nie trafia (§ 9.9).
- `oswiadczenie_2` („nastąpiło zbadanie … potrzeb”): kalkulator nie ma kroku analizy potrzeb (W5).
- `zgoda_7` ma dopisek „niezbędna do wysłania elektronicznej oferty na e-mail”, ale jest dobrowolna, a e-mail wychodzi bez niej.
- `zgoda_8` wymienia spółkę majątkową („Sopockie Towarzystwo Ubezpieczeń ERGO Hestia S.A.”), a pozostałe zgody – spółkę życiową. Do potwierdzenia.
- W treściach są trzech administratorów: Aura Expert (`/rodo`, `/polityka-prywatnosci`), CPOP (`zgoda_9`) i ERGO Hestia (WU, OWU.pdf s. 13). Portal potrzebuje jednej klauzuli warstwowej (W3).
- Brak zgody z art. 9 RODO jest spójny z tym, że ankieta nie opuszcza przeglądarki.

### 9.7 Krok 6 – Gotowe (`/kalkulator/sukces`)

Treść (`gohestia/app/kalkulator/sukces/page.tsx:23-47`):
- „✅”, „Zapytanie wysłane!”;
- „Twoje dane kontaktowe i wybrana oferta zostały wysłane do agenta ERGO Hestia, który skontaktuje się z Tobą w ciągu **1–2 dni roboczych**.”;
- gdy URL zawiera `email`: „Kopię podsumowania oferty wysłaliśmy na adres **{email}**.”;
- przyciski: „Wróć na stronę główną” (`/`) i „Oblicz nową ofertę” (`/kalkulator/wiek`).

Strona resetuje cały store przy wejściu (l. 12-17). Komentarz w kodzie opisuje wcześniejszy wyścig ze strażnikiem w Podsumowaniu. Adres e-mail pochodzi z parametru URL, więc trafia do historii przeglądarki i logów, a strona wyświetli dowolny tekst. W portalu nie przekazywać go w URL (W4).

### 9.8 Ekrany wykluczeń

`/wykluczenie/wiek` (`gohestia/app/wykluczenie/wiek/page.tsx:8-33`):
- „⚠️”, „Niestety, Twój wiek nie spełnia warunków”;
- „Grupowe ubezpieczenie ERGO Razem w trybie Grupy Otwartej jest dostępne dla osób w wieku od **18 do 65 lat**.”;
- „Jeśli masz inne pytania lub szukasz innego rodzaju ochrony, skontaktuj się z agentem ERGO Hestia.”;
- przyciski: „Skontaktuj się z agentem →” (`https://www.ergohestia.pl/kontakt/`) i „Sprawdź ponownie” (`/kalkulator/wiek`).

`/wykluczenie/zdrowie` (`gohestia/app/wykluczenie/zdrowie/page.tsx:8-60`):
- „⚠️”, „Niestety nie możesz przystąpić do Grupy Otwartej”;
- „Na podstawie udzielonych odpowiedzi nie spełniasz warunków przystąpienia do ubezpieczenia ERGO Razem w trybie Grupy Otwartej.”;
- ramka „Polisa indywidualna ERGO Hestia”: „Możesz ubiegać się o indywidualną polisę na życie. Polisa indywidualna może:” • „wymagać wypełnienia szczegółowej ankiety medycznej,” • „lub poddania się badaniom lekarskim na koszt ubezpieczyciela.” / „Zakres ochrony i składka ustalane są indywidualnie.”;
- przyciski: „Wycen polisę indywidualną →” (`https://www.ergohestia.pl/ubezpieczenie-na-zycie/`, nowa karta), „Skontaktuj się z agentem →” (`https://www.ergohestia.pl/kontakt/`), „← Wróć do ankiety” (`/kalkulator/ankieta`; odpowiedzi trzeba podać od nowa).

Uwaga dla portalu: oba ekrany kierują do ogólnego kontaktu ERGO Hestii, a nie do Aura Expert. W portalu skierować do kontaktu z agentem portalu, np. do formularza leada na życie.

### 9.9 Wysyłka: route handler `/api/oferta`, Resend, załączniki

**Dokąd trafiają dane: wyłącznie do e-maili.** Jeden do klienta, drugi do agenta na adres z sekretu `AGENT_EMAIL` (wartość w konfiguracji, nie w dokumencie). Kod nie zawiera bazy, Supabase, CRM „aurabroker” ani webhooka (`gohestia/app/api/oferta/route.ts:61-136`; brak zależności w `gohestia/package.json`).

Ładunek z przeglądarki (`gohestia/app/kalkulator/podsumowanie/page.tsx:136-151`):

```json
{
  "imie": "…", "nazwisko": "…", "email": "…", "telefon": "…",
  "oferta": {
    "ageGroup": "A1",
    "product": "dla_mnie",
    "variant": "komfort",
    "addons": ["MediPlan", "Medical Assistance", "Global Doctors"],
    "monthlyPremium": 90
  }
}
```

`addons` to etykiety z `ADDONS`, a nie klucze. `monthlyPremium` jest liczony w przeglądarce. Nie są wysyłane: data urodzenia, region, ankieta, zgody, token Turnstile.

Przetwarzanie na serwerze (`route.ts`):
1. `req.json()`. Błąd parsowania daje 400 `{error:"Nieprawidłowe dane"}` (l. 62-67).
2. Zod `bodySchema` (l. 40-52): `imie` i `nazwisko` `min(1)`, `email` `email()`, `telefon` dowolny string. `oferta.ageGroup` i `oferta.product` to enumy, `variant` dowolny string, `addons` tablica stringów, `monthlyPremium` liczba. Błąd daje 400 `{error:"Bad Request"}` (l. 69-72). Brak limitów długości.
3. Brak `RESEND_API_KEY` lub `AGENT_EMAIL` daje 500 `{error:"Email configuration missing", detail:{hasApiKey, hasAgentEmail}}` (l. 74-85).
4. Nadawca: `ERGO Razem Kalkulator <FROM_EMAIL>`. Domyślny adres w domenie beautypolisa.eu jest wpisany w kodzie (l. 89, 107, 114).
5. Szablony renderowane do HTML przez `render` z `@react-email/components`. Załączniki pobierane są z `public/` przez `fetch(${SITE_URL lub origin żądania}/${file})` i kodowane w base64 (l. 20-38, 92-103).
6. Dwa równoległe `resend.emails.send` (l. 105-119). Błąd którejkolwiek wysyłki daje 500 `{error:"Email error", detail:<błąd Resend lub message>, from:<adres nadawcy>}` (l. 121-133). Jedna wiadomość mogła już wyjść. Nie ma ponowień ani outboxu.
7. Sukces: 200 `{ok:true}`.

**Rate limit: brak** (ani w kodzie, ani w `wrangler.jsonc`). Nie ma też honeypota, idempotencji ani wymogu tokenu Turnstile.

**E-mail do klienta** (`gohestia/components/email/oferta-template.tsx:12-62`). Temat: „Twoja oferta ERGO Razem — podsumowanie”. Załączniki: `OFFER_DOCUMENTS`. Treść:
- nagłówek na czerwonym tle: „ERGO Razem — Twoja oferta”;
- „Szanowny(a) Panie/Pani **{imie} {nazwisko}**,”;
- „Dziękujemy za skorzystanie z kalkulatora grupowego ubezpieczenia na życie ERGO Razem.”;
- ramka „Podsumowanie wybranej oferty”: „Produkt” {etykieta}, „Wariant” {etykieta albo surowa wartość}, „Dodatki” {lista, gdy niepusta}, „Składka miesięczna” „{monthlyPremium} zł / mies.”;
- „Agent ERGO Hestia skontaktuje się z Tobą w ciągu 1–2 dni roboczych, aby omówić szczegóły oferty.”;
- stopka: „Szczegóły w OWU (kod ER 01/25). Obowiązuje od 2.06.2025 r.”

**E-mail do agenta** (`gohestia/components/email/agent-template.tsx:14-72`), bez załączników. Temat: „Nowe zapytanie: {imie} {nazwisko} — {product} {variant}”, z surowymi kluczami, np. „dla_mnie komfort”. Treść:
- nagłówek: „Nowe zapytanie — ERGO Razem Kalkulator”;
- „Dane kontaktowe klienta”: „Imię i nazwisko”, „Email” (link `mailto`), „Telefon”;
- „Wybrana konfiguracja”: „Grupa wiekowa” {A1|A2|B}, „Produkt”, „Wariant”, „Dodatki”, „Składka” „{monthlyPremium} zł / mies.”

W e-mailu do agenta brakuje regionu, zgód, znacznika czasu i numeru zgłoszenia. Dane osobowe są w temacie wiadomości.

**Załączniki** (`gohestia/lib/data/documents.ts:19-34`, `gohestia/public/dokumenty/README.md`):

| Plik w konfiguracji | Nazwa w e-mailu | Stan w repozytorium |
|---|---|---|
| `dokumenty/owu.pdf` | `OWU_ERGO_Razem_ER_01-25.pdf` | plik nazywa się `OWU.pdf` (wielkie litery). Serwowanie zasobów rozróżnia wielkość liter, więc pobranie najpewniej zwraca 404 i załącznik jest pomijany z ostrzeżeniem (`route.ts:24-28`) |
| `dokumenty/informacja-o-dystrybutorze.pdf` | `Informacja_o_dystrybutorze_Aura_Expert.pdf` | **brak pliku** |
| `dokumenty/ipid.pdf` (zakomentowane) | `IPID_ERGO_Razem.pdf` | brak; IPID jest w OWU.pdf (s. 2–4) |

Wniosek: e-mail do klienta najpewniej wychodzi **bez załączników**, choć oświadczenia 1 i 3 potwierdzają otrzymanie WU i informacji o dystrybutorze. Do potwierdzenia w logach Workera u zleceniodawcy.

`OWU.pdf` (148 stron, oznaczenie GO/WU002/2504) zawiera:
- s. 2–4: kartę produktu (art. 8 UDU);
- s. 5–7: informacje dla konsumenta przy umowie na odległość;
- s. 8–147: WU ER 01/25, w tym klauzulę informacyjną ERGO Hestii jako administratora (s. 13) i tabelę poważnych zachorowań (§ 40 ust. 9, s. 42–44);
- s. 148: erratę ER/EHZ01/2602 z 13.02.2026.

Nie ma w nim WU Global Doctors GD 02/24, choć Informacje dla konsumenta (OWU.pdf s. 5, pkt 3.2) wymieniają WU GD 02/24 jako element określający świadczenie (obok WU ER 01/25 w pkt 3.1).

### 9.10 Taryfy, świadczenia, strony treści – porównanie z JSON

- **Składki i świadczenia: zgodne.** Ponowne porównanie maszynowe objęło 27 pozycji `PREMIUMS` (`gohestia/lib/data/premiums.ts:3-55`) i 66 wierszy tabel A/B (`gohestia/lib/data/benefits.ts:59-143`): nazwy, wartości, karencje i wyróżnienia. Tabele z § 4 i JSON (`skladki_miesieczne_zl`, `swiadczenia`) nie wymagają poprawek. `ADDONS` (`premiums.ts:57-62`) i `calcMonthlyPremium` (`gohestia/lib/calculator.ts:17-33`) są zgodne z § 4. Uwaga: składka w kroku Oferta jest wyświetlana błędnie (§ 9.5).
- **„120/50 zł”** (wiersz „Leczenie szpitalne NW”) to najpewniej świadczenie za dzień w pierwszych 14 dniach i za każdy dzień po 14. dniu (§ 48 ust. 1–2 WU, OWU.pdf s. 50). Druga liczba w każdej kolumnie tabel A i B równa się wartości „Leczenie szpitalne choroba”, czego wymaga § 48 ust. 2 zd. 2. Karencja „2 mies. (od 15. dnia)” dotyczy drugiej części. W portalu pokazać dwie wartości z opisem („dzień 1–14 / od 15. dnia”). Interpretację musi potwierdzić ERGO Hestia.
- **Global Doctors (R8): ceny nadal brak.** `ADDONS.global_doctors.monthly = null`, notka „Składka zależna od wieku — podana przy wycenie” (`premiums.ts:60-61`). Kalkulator dodaje `0` (`calculator.ts:28-31`), krok Oferta pokazuje „wycena wg wieku”, a e-mail – samą etykietę „Global Doctors”. Strona `/global-doctors` obiecuje: „orientacyjną kwotę zobaczysz przy konfigurowaniu oferty w kalkulatorze” (`gohestia/app/global-doctors/page.tsx:38-43`). To nieprawda. Pełną treść strony zawiera JSON (`strony_tresci.global_doctors`). Kontakt na stronie: [e-mail biura Aura Expert] (l. 81).
- **Strona główna** (`gohestia/app/page.tsx`) jest zgodna z § 3: liczniki „500 000 zł”, „od 57 zł”, „56” (l. 137-145), kroki „Jak to działa?” (l. 279-281), pole „Twój wiek” (l. 87, 189, 201). Tabela porównawcza używa `VariantsComparisonTable` z listami wariantów bez A2 Podstawowy (`gohestia/components/variants-comparison-table.tsx:6-40`), a bez wpisanego wieku – grupy A1 (`page.tsx:255`).
- **Metadane główne** (`gohestia/app/layout.tsx:8-9`), dosłownie: title „ERGO Razem — Kalkulator Grupy Otwartej”, description „Oblicz składkę grupowego ubezpieczenia na życie ERGO Razem. Sopockie TU na Życie ERGO Hestia S.A.”. Do tego `lang="pl"` i font Inter (l. 5, 14). W portalu tytuł i opis według konwencji portalu (JSON: `meta.metadane_strony`). Zasoby graficzne i wideo `/hero-family.mp4` do zastąpienia – § 6 i JSON `strony_tresci.strona_glowna.zasoby_do_zastapienia`.
- **FAQ** (`gohestia/app/faq/faq.tsx`): 21 pytań i odpowiedzi zgodnych z JSON (`faq`).
- **MediPlan / Medical Assistance** (`gohestia/app/ubezpieczenia-dodatkowe/ubezpieczenia.tsx`): zgodne z JSON, łącznie z literówką „pomniejsza pula”.
- **Katalog zachorowań** (`gohestia/app/katalog-zachorowan/katalog.tsx:7-575`): 57 pozycji z definicjami (skróty redakcyjne z podpisem „Źródło: WU ER 01/25, Załącznik 1 – Definicje poważnych zachorowań, poz. {lp}”, l. 826) i flagą `ubezpieczony_komfort`. Jedyna pozycja spoza KOMFORT: lp 1 „Bakteryjne zapalenie opon mózgowych” (tylko dziecko) – l. 9-12. Pełne dane są w JSON (`katalog_zachorowan.pozycje`).
- **`/zglos-roszczenie`** (`gohestia/app/zglos-roszczenie/page.tsx:15-58`), dosłownie:
  - „Klient może zgłosić roszczenie w Grupie Otwartej:” • „za pomocą Platformy Zgłaszania Roszczeń,” (bez linku) • „podczas wizyty u agenta,” • „przesyłając dokumenty listem na adres: Sopockie Towarzystwo Ubezpieczeń na Życie ERGO Hestia S.A., ul. Hestii 1, 81-731 Sopot,” • „przesyłając dokumenty listem elektronicznym na adres do doręczeń elektronicznych **AE:PL-71115-41590-RJWRG-16**.”;
  - „Zgłoszenie roszczenia z dodatków”: „**Global Doctors** – pod numerem telefonu 801 107 107 lub (58) 555 55 55 lub przez formularz na stronie https://zgloszenieroszczenia.ergohestia.pl,” • „**MediPlan i Medical Assistance** – przez infolinię Centrum Alarmowego pod numerem 22 522 29 94.”;
  - OWU.pdf s. 4 podaje dla ERGO Razem formularz `www.ergohestia.pl/zglos-zdarzenie/` i telefon 801 107 107 / 58 555 55 55. Do ujednolicenia w portalu.
- **`/rodo`** (`gohestia/app/rodo/page.tsx:7-95`). Tytuł meta: „Klauzula RODO — Aura Expert sp. z o.o.”; nagłówek: „Klauzula Informacyjna RODO” / „Zgodnie z art. 13 Rozporządzenia Parlamentu Europejskiego i Rady (UE) 2016/679 (RODO).” Treść dosłownie:
  1. **Administrator danych** – „Administratorem Twoich danych osobowych jest: **Aura Expert sp. z o.o.** Agent ubezpieczeniowy działający w imieniu Sopockie TU na Życie ERGO Hestia S.A., ul. Hestii 1, 81-731 Sopot Kontakt: **[e-mail biura Aura Expert]**”
  2. **Cel przetwarzania** – „Twoje dane osobowe (imię, nazwisko, e-mail, telefon, opcjonalnie region) są przetwarzane w celu:” • „przedstawienia indywidualnej oferty grupowego ubezpieczenia na życie ERGO Razem,” • „nawiązania kontaktu przez agenta ubezpieczeniowego w celu omówienia oferty,” • „przesyłania informacji marketingowych — wyłącznie po wyrażeniu odrębnej zgody.”
  3. **Podstawa prawna** – „Art. 6 ust. 1 lit. **a** RODO — Twoja zgoda wyrażona w formularzu.”
  4. **Co NIE jest przetwarzane** – „**Dane wrażliwe z ankiety medycznej nie są przesyłane na żaden serwer.** Odpowiedzi na pytania ankiety przetwarzane są wyłącznie lokalnie w Twojej przeglądarce i nie opuszczają Twojego urządzenia. Administratorowi przekazywana jest jedynie konfiguracja wybranej oferty (produkt, wariant, składka) — bez żadnych informacji o stanie zdrowia.”
  5. **Odbiorcy danych** – „Dane mogą być przekazywane:” • „agentowi ubezpieczeniowemu **Aura Expert sp. z o.o.**,” • „dostawcy poczty e-mail **Resend Inc.** (transfer na podstawie SCC),” • „**Cloudflare Inc.** — infrastruktura hostingowa i CDN (transfer na podstawie SCC).”
  6. **Okres przechowywania** – „Dane przechowywane są przez czas niezbędny do realizacji celu, tj. do zakończenia procesu przedstawienia oferty i nawiązania kontaktu — nie dłużej niż **3 lata** od daty wysłania formularza lub do cofnięcia zgody.”
  7. **Twoje prawa** – „Masz prawo do:” dostępu (art. 15), sprostowania (art. 16), usunięcia (art. 17), ograniczenia przetwarzania (art. 18), przenoszenia danych (art. 20), sprzeciwu (art. 21), „cofnięcia zgody w dowolnym momencie bez wpływu na zgodność z prawem przetwarzania przed cofnięciem,” „wniesienia skargi do Prezesa Urzędu Ochrony Danych Osobowych (ul. Stawki 2, 00-193 Warszawa, www.uodo.gov.pl).” (pełne brzmienie punktów w JSON)
  8. **Dobrowolność podania danych** – „Podanie danych jest dobrowolne, jednak niezbędne do przedstawienia oferty ubezpieczeniowej i kontaktu przez agenta. Brak podania danych uniemożliwia realizację ww. celów.”
  9. **Zautomatyzowane podejmowanie decyzji** – „Dane nie są wykorzystywane do zautomatyzowanego podejmowania decyzji ani profilowania w rozumieniu art. 22 RODO.”

  Uwagi:
  - Klauzula nie ma daty ani wersji.
  - Jedyną podstawą jest zgoda. Dla kontaktu na żądanie klienta właściwszy jest art. 6 ust. 1 lit. b – do oceny prawnika.
  - „Region” jest wymieniony, ale nie jest wysyłany.
  - Brak informacji o CPOP i ERGO Hestii jako odrębnych administratorach.
- **`/polityka-prywatnosci`** (`gohestia/app/polityka-prywatnosci/page.tsx:24-118`, „Ostatnia aktualizacja: 1 czerwca 2025 r.”) i **`/regulamin`** (`gohestia/app/regulamin/page.tsx:24-133`, ta sama data): pełne teksty w JSON (`strony_tresci.polityka_prywatnosci.tresc_pelna`, `strony_tresci.regulamin.tresc_pelna`). Adres e-mail biura zastąpiono tam opisem. Niezgodności z kodem:
  - polityka § 3 mówi, że na serwer trafia „token weryfikacji Cloudflare Turnstile” – nie trafia razem z danymi;
  - polityka § 2 wymienia „preferowany region” – nie jest wysyłany;
  - polityka § 7 deklaruje Cloudflare Web Analytics – brak w kodzie;
  - regulamin § 1 ust. 2 opisuje produkt jako „dystrybuowanego przez Sopockie TU na Życie ERGO Hestia S.A.” (`gohestia/app/regulamin/page.tsx:35-36`), czyli ubezpieczyciela nazywa dystrybutorem;
  - regulamin § 7 ust. 3 („sąd właściwy miejscowo dla siedziby Operatora”) to wobec konsumentów klauzula niedozwolona – nie przenosić;
  - regulamin § 2 ust. 3 odsyła do OWU, które są „dostępne na stronie ERGO Hestia” (`gohestia/app/regulamin/page.tsx:60-61`).
- **`/informacja-o-agencie`** (`gohestia/app/informacja-o-agencie/page.tsx:37-153`): treść zgodna z `ergo/go_informacja-o-agencie.md`: 10 zakładów, wynagrodzenie w formie prowizji, reklamacje, Rzecznik Finansowy. **Błąd: „Sąd Rejonowy dla m.st. Warszawy w Warszawie, XIII Wydział Gospodarczy Krajowego Rejestru Sądowego”** (l. 59-62). Portal używa XII (D38, `legal-distributor.json`). Nie kopiować XIII. Zgłosić zleceniodawcy do poprawy w aplikacji. Podstawa „Dz.U. z 2017 r., poz. 2486 ze zm.” to stare oznaczenie, do aktualizacji. Danych kontaktowych agenta (telefon, e-maile zarządu i reklamacji) tu nie powielamy – źródłem dla portalu jest `legal-distributor.json`.

### 9.11 Bezpieczeństwo i zgodność (ustalenia z kodu)

| Waga | Problem | Źródło |
|---|---|---|
| wysoka | `/api/oferta` nie ma Turnstile, rate limitu, honeypota ani powiązania z krokiem 3. Każdy może wysłać POST i wywołać e-mail „ERGO Razem Kalkulator” z załącznikami na dowolny adres. Imię, nazwisko i `variant` są dowolne i trafiają też do tematu wiadomości do agenta. | `gohestia/app/api/oferta/route.ts:40-52,61-119` |
| wysoka | Zgody i oświadczenia nie są nigdzie zapisywane ani przekazywane. Brak rozliczalności (art. 7 ust. 1 RODO). Agent nie zna zgód marketingowych. | `gohestia/app/kalkulator/podsumowanie/page.tsx:136-151` |
| średnia | Składka i dodatki pochodzą z przeglądarki. Serwer ich nie przelicza, więc e-mail może pokazać dowolną kwotę. Krok Oferta podwójnie liczy dodatki. | `route.ts:45-51`; `gohestia/components/premium-calculator.tsx:18-20` |
| średnia | Odpowiedzi 500 ujawniają szczegóły błędu Resend, adres nadawcy i obecność sekretów. | `route.ts:81-84,124,128-132` |
| średnia | Adres e-mail w URL strony sukcesu (historia, logi, nagłówek Referer). | `podsumowanie/page.tsx:154` |
| średnia | Załączniki najpewniej nie wychodzą (`owu.pdf` zamiast `OWU.pdf`, brak informacji o dystrybutorze), mimo oświadczeń 1 i 3. | `gohestia/lib/data/documents.ts:19-27` |
| niska | Walidacja w przeglądarce i na serwerze się różni (imię min 2 / min 1, telefon bez reguły na serwerze, brak limitów długości). | `route.ts:40-44` |
| niska | `siteverify` bez sprawdzenia `hostname` i `action`; martwy `lib/turnstile.ts`. | `gohestia/app/api/turnstile/route.ts:18-31` |
| niska | Adres do pobrania PDF opiera się na originie żądania, gdy brak `SITE_URL`. | `route.ts:92` |
| niska | Przełączniki dodatków są niedostępne z klawiatury. | `gohestia/components/addon-toggle.tsx:15-38` |
| informacyjna | Nagłówki bezpieczeństwa i CSP ustawione dla wszystkich ścieżek. | `gohestia/next.config.ts:4-25` |

### 9.12 Wnioski dla przeniesienia do portalu

1. **Przenieść 1:1** (z oznaczeniem „do akceptacji ERGO Hestii”):
   - regułę wieku i grup taryfowych;
   - taryfy i tabele świadczeń (JSON);
   - 5 bloków ankiety z regułą „każde TAK = wykluczenie”, z ankietą wyłącznie w przeglądarce;
   - teksty ekranów wykluczeń z kontaktem do agenta portalu zamiast ogólnego kontaktu ERGO Hestii.
2. **Nie przenosić:**
   - `COVERAGE` i `WAITING_PERIODS`;
   - komponentu `PremiumCalculator` z podwójnym liczeniem;
   - e-maila w URL;
   - XIII Wydziału KRS;
   - klauzuli o sądzie z regulaminu;
   - obietnicy kwoty Global Doctors.
3. **Do decyzji (W1, W3, W4, W5):**
   - czy zgłoszenie ER w portalu jest „zapytaniem do agenta” z minimalnym zestawem zgód (klauzula informacyjna portalu i opcjonalny marketing per kanał), czy pełną deklaracją przystąpienia ze zgodami 1–6, 9 i oświadczeniami 1–4. Pełna deklaracja wymaga APK przed propozycją i doręczenia WU przed wysłaniem;
   - czy zgłoszenie ma trafiać do CRM.
4. **Standard ochrony portalu (W2):** honeypot, idempotencja, rate limit, Zod, a na końcu Turnstile weryfikowany **w tym samym żądaniu**, które zapisuje lub wysyła zgłoszenie. Do tego sprawdzenie `hostname` i `action`, przeliczenie składki na serwerze z wersjonowanego cennika oraz zapis zgód z wersją i hashem treści.


---

## Weryfikacja krytyka kompletności (2026-11-13)

Sprawdzone w kodzie i **potwierdzone**: `PREMIUMS` i `ADDONS` (`31gj1ymm-1tvb.js` l. 75–160: MediPlan 9, Medical Assistance 6, Global Doctors `monthly: null`, `maxAge: 63`); `getAgeGroup` (`<18 || >=66 → null`, `<54 A1`, `<60 A2`, inaczej B); `calcMonthlyPremium` z dosłownym `o += 0` dla Global Doctors; komunikat „Podaj datę urodzenia.” i przekierowania `/kalkulator/ankieta` / `/wykluczenie/wiek`; store bez `persist`; listy wariantów strony głównej (`0vqvpp9_0rpw6.js` l. 1631–1661, brak „Podstawowy” dla Dla Mnie / Dla Nas w A); wiersze tabeli A (np. „Poważne zachorowanie (56 j.ch.)” 3000…17 000, „Leczenie szpitalne NW” jako tekst „120/50 zł”); brak skryptu Turnstile w pobranym HTML.

**Uzupełnione:** atrybuty `min`/`max` pola daty z SSR. Chunk `1rxncug86bump.js` jest ładowany także przez `/global-doctors` (nie tylko „Informacja o agencie”), więc jest raczej wspólnym komponentem stron treści niż kodem jednej strony.

**Bez zmian (potwierdzone braki):** kroki 2–6 (ankieta, weryfikacja, oferta, podsumowanie, sukces), `/wykluczenie/wiek`, zgody, wysyłka i Turnstile nie występują w żadnym pobranym pliku. To największa luka wśród trzech aplikacji. [korekta repo: luka zamknięta, § 9 i Zamknięcie braków]

---

## Zamknięcie braków po analizie repozytorium gohestia

Stan na 2026-11-13. Kody braków jak w `00-braki-i-decyzje.md` § 1.2. Odnośniki do plików repozytorium `gohestia`.

| # | Brak (skrót) | Status | Dowód | Czego dalej brakuje i od kogo |
|---|---|---|---|---|
| R1 | Kod kroków 2–6 i `/wykluczenie/wiek` | **zamknięty** | Wszystkie kroki i oba ekrany wykluczeń: `gohestia/app/kalkulator/{ankieta,weryfikacja,produkt,podsumowanie,sukces}/page.tsx`, `gohestia/app/wykluczenie/{wiek,zdrowie}/page.tsx`; opis w § 9.2–9.8 | — |
| R2 | Pytania ankiety, typy odpowiedzi, reguły, ekrany wykluczenia | **zamknięty** (treść i reguły); **częściowo** (akceptacja) | `gohestia/lib/data/questionnaire.ts:9-85` (5 bloków dosłownie), `gohestia/components/questionnaire/index.tsx:13-96` (TAK = wykluczenie, dalej tylko przy 5 × NIE, modal), `gohestia/app/wykluczenie/zdrowie/page.tsx`; odpowiedzi nie opuszczają przeglądarki (§ 9.3) | ERGO Hestia (underwriting): potwierdzenie, że pytania są aktualne i pełne; zgoda na przeformułowanie pytań wprost; czy potrzebne są pytania o współubezpieczonych (Dla Nas, Dla Rodziny). Od: zleceniodawca / ERGO Hestia |
| R3 | Co sprawdza krok „Weryfikacja” | **zamknięty** | Tylko Cloudflare Turnstile: `gohestia/app/kalkulator/weryfikacja/page.tsx:26-57`, `gohestia/app/api/turnstile/route.ts:1-32`; wynik zostaje w przeglądarce, `/api/oferta` go nie sprawdza (§ 9.4) | — (portal ma własny Turnstile, W2) |
| R4 | Układ kroku „Oferta”, wariant domyślny, komunikat GD > 63 | **zamknięty** | `gohestia/app/kalkulator/produkt/page.tsx:47-157`: brak wariantu domyślnego, GD wyłączony z opisem „Niedostępne dla osób powyżej 63 r.ż.”; wykryto błąd podwójnego liczenia dodatków (`gohestia/components/premium-calculator.tsx:18-20`) (§ 9.5) | — |
| R5 | Pola formularza kontaktowego, walidacje, komunikaty | **zamknięty** | `gohestia/app/kalkulator/podsumowanie/page.tsx:15-39,209-261,424-431`: imię, nazwisko, e-mail, telefon, region (niewysyłany), komunikaty dosłownie (§ 9.6) | Decyzja W1/W4: czy portal przejmuje te pola, czy używa wspólnego formularza leada |
| R6 | Treść zgód i klauzul, `/rodo`, `/polityka-prywatnosci`, `/regulamin` | **częściowo** | 14 zgód i oświadczeń dosłownie (`podsumowanie/page.tsx:263-422`); `/rodo` dosłownie (`gohestia/app/rodo/page.tsx`); polityka i regulamin – pełny tekst w JSON (§ 9.6, 9.10). Treści znane, ale bez wersjonowania i nigdzie niezapisywane | Prawnik i zleceniodawca: (1) administrator – Aura Expert, CPOP czy ERGO Hestia, jedna klauzula warstwowa; (2) czy zgody certyfikatowe (1–6, 9) i oświadczenia 1–4 należą do „zapytania” (W5); (3) podstawa prawna kontaktu (lit. a czy b); (4) korekta `zgoda_7`, polityki (Turnstile, region, Web Analytics) i regulaminu (§ 1, § 7 ust. 3); (5) wersje zgód. CPOP: akceptacja `zgoda_9` i `zgoda_10` w portalu |
| R7 | Dokąd idzie zgłoszenie, struktura, e-maile | **zamknięty** | `gohestia/app/api/oferta/route.ts:40-136`: tylko 2 e-maile Resend (klient z załącznikami, agent na sekret `AGENT_EMAIL`); brak bazy i CRM; ładunek, tematy i treści szablonów dosłownie (`gohestia/components/email/*.tsx`) (§ 9.9) | Decyzja W1: czy w portalu zgłoszenia ER trafiają do CRM „aurabroker” (dziś nie trafiają). Decyzja W4: szablony portalu |
| R8 | Składka Global Doctors | **nadal otwarty** | Brak ceny w kodzie (`gohestia/lib/data/premiums.ts:60-61`, `gohestia/lib/calculator.ts:28-31` dodaje 0 zł) i w `OWU.pdf` (brak WU GD 02/24); strona `/global-doctors` obiecuje kwotę, której kalkulator nie pokazuje | Tabela składek GD według wieku albo decyzja „cena przy kontakcie z agentem” (wtedy usunąć obietnicę ze strony GD); WU GD 02/24 (PDF). Od: zleceniodawca / ERGO Hestia |
| R9 | Definicje 57 zachorowań, pozycja spoza KOMFORT | **zamknięty** | `gohestia/app/katalog-zachorowan/katalog.tsx:7-575`: definicje i flagi; spoza KOMFORT tylko lp 1 „Bakteryjne zapalenie opon mózgowych” (l. 9-12); flagi zgodne z § 40 ust. 9 WU (OWU.pdf s. 42–44) | Opcjonalnie: pełne definicje z Załącznika 1 WU zamiast skrótów redakcyjnych aplikacji |
| R10 | Niespójności treści | **częściowo** | Wyjaśnione: 13.02.2026 = errata ER/EHZ01/2602 (OWU.pdf s. 148); MAKSYMALNY (34) jest węższy niż KOMFORT (56) zgodnie z WU (s. 42–44); wiek liczony w dniu podpisania certyfikatu (s. 3); „120/50 zł” = dzień 1–14 / od 15. dnia (§ 48 WU, s. 50) – interpretacja | Zleceniodawca / ERGO Hestia: „od 57 zł” vs 50 zł (A2 Dla Mnie Podstawowy, `premiums.ts:24`); „56 chorób” w treściach marketingowych (grupa B ma 34); potwierdzenie „120/50 zł”; który wariant korzysta z zakresu MAKSYMALNY/KOMFORT; „Zgon rodziców i teściów” w karcie „Dla Nas”; stopka „Obowiązuje od 2.06.2025” przy erracie |
| R11 | PDF OWU/WU ER 01/25 i GD 02/24 | **częściowo** | `gohestia/public/dokumenty/OWU.pdf`: pakiet GO/WU002/2504 (karta produktu, informacje dla konsumenta na odległość, WU ER 01/25, errata 13.02.2026). Konfiguracja załączników wskazuje złą nazwę pliku (`gohestia/lib/data/documents.ts:21`) | WU GD 02/24, PDF „Informacja o dystrybutorze” (Aura Expert), ewentualnie osobny IPID; potwierdzenie aktualności pakietu 2504 i zgoda na publikację w portalu. Od: zleceniodawca / ERGO Hestia |

**Nadal otwarte lub częściowe:** R2 (akceptacja ankiety), R6 (teksty prawne), R8 (cena GD), R10 (część niespójności), R11 (WU GD, informacja o dystrybutorze). Poza listą R1–R11 doszły ustalenia, które trzeba zgłosić zleceniodawcy jako błędy działającej aplikacji `ergo.beautypolisa.eu`:
- podwójne liczenie dodatków w kroku Oferta;
- `/api/oferta` bez ochrony przed nadużyciem;
- załączniki PDF najpewniej nie wychodzą;
- zgody nie są zapisywane;
- XIII zamiast XII Wydziału KRS;
- e-mail w URL strony sukcesu.

Propozycja zmian w `00-braki-i-decyzje.md` § 1.2 (ten plik go nie edytuje):
- tabela „Werdykt”: wiersz ER zmienić na „kompletny (6 kroków)” / „wysyłka znana: 2 e-maile Resend, bez bazy” / „14 zgód dosłownie, bez wersjonowania”;
- R1, R3, R4, R5, R7, R9 oznaczyć jako zamknięte.
