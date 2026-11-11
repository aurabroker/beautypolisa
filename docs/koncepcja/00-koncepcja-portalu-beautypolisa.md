# 00 · Koncepcja portalu BeautyPolisa (beautypolisa.eu) – dokument główny

| | |
|---|---|
| Wersja | 1.0 (do akceptacji zleceniodawcy) |
| Data | 11 listopada 2026 |
| Zakres | Portal informacyjno-leadowy BeautyPolisa: React/Next.js, Supabase, Cloudflare |
| Gałąź | `claude/dreamy-galileo-4l5y2v` |
| Status | Koncepcja – nic z tego dokumentu nie zostało jeszcze wdrożone w kodzie produkcyjnym |

## TL;DR

1. **Portal powstaje od nowa** jako jedna aplikacja Next.js (App Router, React Server Components, TypeScript, Tailwind CSS 4) na Cloudflare Workers, z oddzielnym, dedykowanym projektem Supabase. Obecne pliki HTML/JS traktujemy jako prototyp i źródło treści, nie jako kod do przeniesienia (sekcje 02 i 03).
2. **Bezpieczeństwo jest priorytetem nr 1 i wymusza trzy zmiany względem stanu obecnego:** przeglądarka nie dostaje żadnego klucza Supabase (leady zapisuje wyłącznie serwer), portal opuszcza współdzieloną bazę „aurabroker”, a skrypt „anti-inspect” i panel admina znikają z publicznego bundla.
3. **Cele mierzalne:** dostępność 99,9 %, LCP p75 mobile ≤ 2,0 s (próg akceptacji 2,5 s), INP ≤ 200 ms, CLS ≤ 0,1, budżet JS strony startowej ≤ 120 KB gzip, WCAG 2.2 AA, zero skryptów firm trzecich bez zgody.
4. **SEO/GEO zaczyna się w Cloudflare:** strefa beautypolisa.eu blokuje dziś wszystkie crawlery AI i nie ma rekordu DNS dla domeny głównej. Bez odblokowania kategorii *AI Search* i *Agent* żadna treść nie będzie cytowana w ChatGPT, Perplexity ani AI Overviews (sekcja 04).
5. **Treść jest przewagą konkurencyjną:** BeautyPolisa jest pierwotnym źródłem dla programu OC ERGO Hestia (Beauty Razem), czterech grup ryzyka zabiegów i listy zabiegów wysokiego ryzyka. Pierwsze 5 tygodni kalendarza to klaster OC i prawo salonowe (sekcja 05).
6. **Lejki:** cztery magnesy wg ramy MAGNET, z quizem grup ryzyka jako głównym wejściem (bez bramki e-mail), pełną serią pielęgnującą w Resend, osobnymi zgodami RODO/e-mail/telefon i warstwowym spełnieniem obowiązków IDD (sekcja 06).
7. **Design v3 – old money w szkle:** po odrzuceniu v2 („jak ilustracja komiksu”) marka w Bloom dostała kierunek old money: nocny granat `#141C33`, granat `#2A3B68`, kość słoniowa `#F7F3EC`, złoto `#B8975A` tylko jako ozdoba, Cormorant Garamond i Poppins. Cała strona stoi na mrożonym szkle nad czterema zdjęciami z Bloom (salon, jedwab, marmur, martwa natura). W Bloom powstało 21 nowych ikon cienką linią. Makieta `design/v3/makieta-v3.html` działa bez builda i przeszła test w Chrome przy 1280 i 390 px (sekcja 10; sekcje 07 i 09 są w części wizualnej zastąpione).
8. **Dwa produkty nie mają jeszcze oferty** (Utrata dochodu, NNW dzieci) – w v1 startują jako strony edukacyjne w trybie „zapytaj o ofertę”. Składki pozostałych produktów są sztywne (taryfa programu) i portal pokazuje je bez zastrzeżeń „orientacyjne” – potwierdzenie zleceniodawcy z 11.11.2026.
9. **Strefa Klienta (etap po fazie 1):** każdy klient, który kupi przez BeautyPolisa dowolną polisę, dostaje konto z polisami (wygasłe zostają w archiwum, konto nie jest odcinane), dostęp do tablicy ogłoszeń „Dam pracę” (tylko tablica – Aura nie poleca, nie wyszukuje i nie dobiera kandydatów, kandydat kontaktuje się z salonem bezpośrednio) oraz do „Szkoleń” dodawanych przez zweryfikowanych organizatorów – firmy szkoleniowe i salony – z moderacją przed publikacją (decyzje zleceniodawcy z 11.11.2026; sekcja 11).
10. **Plan:** tydzień 0 to szybkie wygrane na obecnej infrastrukturze (TLS 1.2, SSL strict, HSTS, odblokowanie botów AI, REVOKE zbędnych grantów, usunięcie anti-inspect), potem 4 fazy: MVP → baza wiedzy i GEO → lejki → skalowanie (sekcja 08).

## 1. Zlecenie i jego interpretacja

Zlecenie: koncepcja portalu BeautyPolisa (React/Next.js, beautypolisa.eu) z informacją o ubezpieczeniach dla branży beauty – OC (program z ERGO Hestią), ubezpieczenie karno-skarbowe (Colonnade), utrata dochodu, NNW dzieci, ubezpieczenie grupowe ERGO dedykowane beauty; baza Supabase, całość przez Cloudflare; priorytety: bezpieczeństwo i stabilność, potem szybkość ładowania, responsywność, SEO/GEO; efekt „glass widget”.

Przyjęta interpretacja (szczegóły i założenia w `01-audyt-stanu-obecnego.md`, rozdział 8):

- Portal **informuje i zbiera leady**; nie sprzedaje polis online, nie przyjmuje płatności, nie zawiera umów. Domknięcie sprzedaży należy do zespołu Aura Consulting.
- Produktów jest **sześć**, bo istniejąca strona opieki medycznej (ENEL-MED / LUX MED) jest częścią oferty i pozostaje w nawigacji.
- Jeden język (polski), jeden rynek, domena kanoniczna `https://beautypolisa.eu` bez `www`.
- „Glass widget” rozumiemy jako półprzezroczystą kartę kalkulatora/CTA w stylu glassmorphism, z pełnym fallbackiem dla przeglądarek i użytkowników, którzy przezroczystości nie chcą lub nie obsługują.
- Wskazane skille zastosowano następująco: *system design* → 02, *code review* → 03, *schema markup*, *SEO & AI visibility*, *AI search optimization (GEO)* → 04, *content strategy* → 05, *lead magnets & funnels* i *Canva creator* → 06, *design critique* → 07.

## 2. Mapa dokumentów

| Plik | Treść | Dla kogo |
|------|-------|----------|
| `00-koncepcja-portalu-beautypolisa.md` | Ten dokument: streszczenie, decyzje, mapa, następne kroki | Zarząd, właściciel produktu |
| `01-audyt-stanu-obecnego.md` | Fakty: produkty i ceny z obecnych stron, stan repo, Supabase (tabele, RLS, advisors), Cloudflare (DNS, ustawienia, bot management), research rynkowy, założenia | Wszyscy – jedyne źródło faktów dla pozostałych sekcji |
| `02-architektura-i-bezpieczenstwo.md` | Wymagania, diagram, przepływy, kontrakty API, model danych i RLS w SQL, CSP, Cloudflare, CI/CD, monitoring, wydajność, trade-offy | Developer, DevOps, osoba odpowiedzialna za bezpieczeństwo |
| `03-code-review-obecnego-kodu.md` | Przegląd `bp-app.js`, `bp-nav.js` i stron HTML z numerami linii, ocena konfiguracji, co przenieść, czego nie, poprawki „na już” | Developer |
| `04-seo-geo-i-schema.md` | Architektura informacji, title/meta, SEO techniczne w Next.js, JSON-LD, polityka crawlerów AI, llms.txt, audyt promptów, pomiar | SEO, content, developer |
| `05-strategia-tresci.md` | Persony, filary i klastry, luki, kolejka priorytetów, kalendarz 12 tygodni, linkowanie, standardy E-E-A-T, proces | Content, broker-recenzent |
| `06-lead-magnety-lejki-i-kampania.md` | Cztery magnesy (MAGNET), pełny lejek quizu, e-maile, zgody i IDD, brief kampanii 30 dni, kalendarz, copy, KPI | Marketing, prawnik, developer |
| `07-design-ux-i-glass-widget.md` | Krytyka obecnego designu, komponenty, responsywność, WCAG 2.2, mikrocopy, szablony (warstwa wizualna zastąpiona przez 10) | Projektant, front-end |
| `08-plan-wdrozenia.md` *(w przygotowaniu – plik jeszcze nie powstał)* | Szybkie wygrane, fazy, WBS, ryzyka, KPI/SLO, Definition of Done, rejestr decyzji, skonsolidowane pytania otwarte | Kierownik projektu, zleceniodawca |
| `09-design-v2-bloom.md` | Design v2 (nieaktualny, zastąpiony przez 10): proces w Bloom, reguły kalkulatora, historia przeglądu marki | Projektant, front-end |
| `10-design-v3-old-money.md` | Design v3: kierunek old money, paleta z kontrastami, typografia, ikony, zasady szkła, zdjęcia, sekcje strony, kalkulator, testy, decyzje | Projektant, front-end, zleceniodawca |
| `11-strefa-klienta.md` | Strefa Klienta: konto salonu z polisami, tablica „Dam pracę”, „Szkolenia” z kontami organizatorów; role, ścieżki, model danych i RLS (`snippets/strefa-klienta.sql`), uwierzytelnianie, RODO, zagrożenia, plan etapów Z0–Z3 | Właściciel produktu, developer, osoba odpowiedzialna za bezpieczeństwo, prawnik/IOD |
| `design/` | `v3/` (aktualna: `makieta-v3.html`, `tokens-v3.css`, `img/`, `ikony/`, sprite i arkusz ikon); `makieta-v2.html`, `tokens-v2.css`, `bloom/` jako historia v2 | Projektant, developer |
| `snippets/` | `robots.txt`, `llms.txt`, 6 plików JSON-LD, pliki SQL, CI i nagłówków bezpieczeństwa | Developer – gotowe do użycia |

## 3. Cele i kryteria sukcesu

| Obszar | Cel | Miernik | Źródło danych |
|--------|-----|---------|---------------|
| Biznes | Leady z sześciu produktów trafiają do zespołu w ciągu minut, z pełną zgodą i kontekstem | liczba leadów / produkt / miesiąc; udział leadów z kalkulatora [hipoteza: 40–60 %] | Supabase (panel), Resend |
| Bezpieczeństwo | Zero PII dostępnego z przeglądarki; zero sekretów w repo; wszystkie formularze za Turnstile i limitem częstotliwości | wynik checklisty DoD (sekcja 08), raport advisors Supabase bez pozycji ERROR | audyt przed startem |
| Stabilność | 99,9 % dostępności; rollback w minutach | uptime zewnętrzny, Workers Versions | monitoring |
| Szybkość | LCP p75 mobile ≤ 2,0 s (próg 2,5 s), INP ≤ 200 ms, CLS ≤ 0,1 | Lighthouse CI w PR, CrUX po starcie | CI, GSC |
| Responsywność i dostępność | Działa i jest czytelne od 360 px; WCAG 2.2 AA | testy Playwright 360/768/1280, audyt dostępności | CI |
| SEO | Indeksacja wszystkich stron produktowych w 30 dni; 20 śledzonych fraz | GSC, Bing Webmaster | miesięcznie |
| GEO | Crawlery AI kategorii Search/Agent dopuszczone; treść cytowalna | ręczny audyt 20 promptów (log, bez wymyślonego „wskaźnika”), referrery AI | miesięcznie |

Wszystkie wartości liczbowe spoza audytu są hipotezami do skalibrowania po pierwszych 90 dniach.

## 4. Dla kogo i z jaką obietnicą

Główne persony (pełny opis w sekcji 05): właścicielka salonu 1–8 osób, kosmetolog na JDG, fryzjer/barber, podolog, linergistka, stylistka paznokci, tatuażysta, trycholog, manager sieci. Łączy ich to, że ingerują w ciało klienta, pracują na własny rachunek lub prowadzą mały zespół i są kontrolowani przez sanepid, ZUS i urząd skarbowy.

Obietnica marki (jedno zdanie używane wszędzie, także w danych strukturalnych i llms.txt): *BeautyPolisa to program ubezpieczeń dla branży beauty prowadzony przez Aura Consulting – OC dla salonów i gabinetów w programie z ERGO Hestią, ochrona karno-skarbowa, ochrona dochodu, ubezpieczenia grupowe i opieka medyczna, z kalkulatorem składki i doradcą, który zna specyfikę zabiegów.*

## 5. Zakres funkcjonalny v1

W zakresie:

- Strona główna z glass widgetem kalkulatora OC (3 kroki: grupa ryzyka → zespół → suma gwarancyjna) i paskiem zaufania.
- Sześć stron produktowych (`/ubezpieczenia/...`) z FAQ, dokumentami OWU, formularzem „poproś o ofertę”; Utrata dochodu i NNW dzieci w trybie edukacyjnym „zapytaj o ofertę” do czasu dostarczenia parametrów.
- Pełny kalkulator OC (`/kalkulator/oc`) z listą zabiegów w czterech grupach i regułami z obecnego kodu (grupa 4 i zespół powyżej 8 osób → wycena indywidualna).
- Sześć stron `/dla-kogo/<zawód>`, baza wiedzy (MDX), `/dokumenty`, `/o-nas`, `/kontakt`, `/szkoda`, `/rodo`.
- Formularze leadowe z Turnstile, limitem częstotliwości, walidacją serwerową, zapisem przez funkcję SQL, e-mailem do zespołu (Resend) i zdarzeniem analitycznym first-party.
- Panel wewnętrzny `/panel` (lista leadów, statusy) za Cloudflare Access i Supabase Auth z MFA.
- SEO techniczne (Metadata API, sitemap, robots, JSON-LD, OG), llms.txt, analityka bez cookies.

Poza zakresem v1: sprzedaż i płatności online, konta klientów (Strefa Klienta – osobne etapy Z1–Z2 po fazie 1, sekcja 11), wielojęzyczność, CMS z interfejsem graficznym, załączniki w zgłoszeniu szkody, pełna ankieta ERGO Hestii online.

## 6. Architektura w jednym rzucie

```
Użytkownik ──► Cloudflare (DNS, WAF, cache, Turnstile, Access dla /panel)
                 │
                 ▼
         Next.js na Workers (@opennextjs/cloudflare)
         • RSC + strony statyczne/ISR   • route handlers: /api/leads, /api/magnets
         • CSP z nonce                  • Service Binding → aura-analytics-collector
                 │                 │                  │
                 ▼                 ▼                  ▼
        Supabase (nowy projekt)  Resend (e-mail,    GitHub Actions
        Postgres + RLS, Auth     outbox + retry)    (CI/CD, preview, Lighthouse CI)
        dla /panel (od Z1 także
        Strefa Klienta, sekcja 11)
```

Kluczowe decyzje (pełne uzasadnienia i odrzucone alternatywy w sekcjach; rejestr w 08):

| ID | Decyzja | Sekcja |
|----|---------|--------|
| D1 | Jedna aplikacja Next.js na Cloudflare Workers; odrzucone: statyczny eksport na Pages, Vercel | 02 |
| D2 | Nowy, dedykowany projekt Supabase; odrzucone: schemat w „BEAUTY”, pozostanie w „aurabroker” | 02 |
| D3 | Zero kluczy Supabase w przeglądarce; zapis leadów wyłącznie z serwera przez funkcję SQL; REVOKE zbędnych grantów (w tym TRUNCATE) | 02 |
| D4 | Kalkulator liczy w przeglądarce z migawki wersjonowanego cennika; serwer przelicza przy wysyłce | 02 |
| D5 | Treść produktowa i baza wiedzy jako MDX/JSON w repo z walidacją; bez CMS w v1 | 02, 05 |
| D6 | Ochrona formularzy: Turnstile + rate limit Cloudflare + rate limit w Workerze + honeypot + walidacja Zod | 02 |
| D7 | E-mail przez Resend z tabelą outbox i retry; bez kolejek | 02 |
| D8 | Panel w tej samej aplikacji, za Cloudflare Access + Supabase Auth (MFA) + RLS | 02 |
| D9 | Cloudflare: SSL Full (strict), min TLS 1.2, HSTS etapami, AI Search i Agent dopuszczone, robots.txt z repozytorium | 02, 04 |
| D10 | Strony produktowe jako schema `Service`, nie `Product`; `AggregateOffer` dla OC z taryfy programu (składki sztywne) | 04 |
| D11 | Huby = strony produktowe i kalkulator; start od klastra OC i prawa salonowego; rytm 2 publikacje + 1 aktualizacja tygodniowo | 05 |
| D12 | Quiz grup ryzyka bez bramki e-mail; double opt-in dla serii pielęgnującej; trzy osobne zgody | 06 |
| D13 | Paleta old money: midnight `#141C33`, navy `#2A3B68`, ivory `#F7F3EC`, parchment `#EDE5D8`, gold `#B8975A` tylko jako dekor, gold light `#D9C089` do tekstu na ciemnym; Cormorant Garamond i Poppins; róż tylko w logo | 10 |
| D14 | Całość w szkle na zdjęciach z Bloom (jasne, mocne i ciemne szkło ze złotą ramką) z obowiązkowymi wyjściami awaryjnymi; ikony z Bloom cienką linią, jeden kolor | 10 |
| D15 | Utrata dochodu i NNW dzieci w v1 jako strony edukacyjne „zapytaj o ofertę” | 05, 08 |
| D16 | Strefa Klienta w tej samej aplikacji i w nowym projekcie Supabase; moduły ogłoszeń i szkoleń z „BEAUTY” migrowane jednorazowo, CRM pozostaje źródłem polis | 11 |
| D17 | Konta Strefy wyłącznie z zaproszenia (bez rejestracji, zaproszenie nie tworzy sesji); logowanie kodem z e-maila z limitami; TOTP obowiązkowy dla właścicieli salonów i organizatorów, egzekwowany w RLS | 11 |
| D18 | Izolacja salonów i organizatorów w RLS przez dwie rozłączne funkcje; zapisy z niezmiennikami tylko funkcjami serwera; personel rozłączny z klientami | 11 |
| D19 | Dokumenty polis w prywatnym kubełku, pobierane przez podpisany URL na 60 s | 11 |
| D20 | **Decyzja zleceniodawcy 11.11.2026:** „Dam pracę” wyłącznie jako tablica ogłoszeń – bez danych, kont i CV kandydatów, bez polecania i dobierania kandydatów; kontakt z salonem bezpośrednio albo formularzem bez przechowywania wiadomości; bez wpisu do KRAZ | 11 |
| D21 | **Decyzja zleceniodawcy 11.11.2026:** szkolenia dodają zweryfikowani organizatorzy (firmy szkoleniowe i salony) z publikacją po moderacji; organizator widzi minimalne dane uczestników tylko swoich szkoleń; bez płatności online w MVP | 11 |
| D22 | **Decyzje zleceniodawcy 11.11.2026:** konto przy każdej polisie kupionej przez BeautyPolisa; po wygaśnięciu polis konto i dostęp do „Dam pracę” i „Szkoleń” zostają | 11 |

## 7. Bezpieczeństwo i stabilność – zasady nienegocjowalne

1. Żaden klucz Supabase ani inny sekret nie trafia do przeglądarki ani do repozytorium (sekrety w Wrangler, klucz serwisowy tylko w kodzie serwerowym).
2. Tabele z danymi osobowymi nie mają żadnych polityk RLS dla `anon`/`authenticated`; zapis wyłącznie przez funkcję SQL wywoływaną z serwera; granty domyślne odebrane.
3. Każdy formularz publiczny: Turnstile, limit częstotliwości, honeypot, walidacja schematem po stronie serwera, idempotencja i deduplikacja.
4. Ścisła CSP z nonce, HSTS, nagłówki bezpieczeństwa; brak `unsafe-inline`.
5. Panel wewnętrzny za dwoma warstwami (Cloudflare Access + Supabase Auth z MFA) i RLS z tabelą ról chronioną triggerem (wzorzec `bp_profiles_guard` z obecnej bazy).
6. Minimalizacja PII w leadzie, retencja z anonimizacją, logi bez danych osobowych.
7. Bramki CI przed każdym wdrożeniem (typecheck, lint, testy logiki cennika, smoke, Lighthouse CI); wdrożenia kanarkowe z rollbackiem.
8. Zależności z lockfile, automatyczne aktualizacje i audyt; żadnych skryptów z CDN bez SRI.
9. Kopie zapasowe testowane kwartalnie; runbook incydentu.
10. Skrypt „anti-inspect” i podobne mechanizmy nigdy nie wracają.

## 8. Wydajność i responsywność

Budżety egzekwowane w CI: LCP ≤ 2,0 s (cel) / 2,5 s (próg), INP ≤ 200 ms, CLS ≤ 0,1, TTFB ≤ 500 ms, JS strony startowej ≤ 120 KB gzip. Techniki: RSC i strony statyczne, kalkulator jako jedyna większa wyspa interaktywna, fonty self-hosted, obrazy przez pipeline Cloudflare, Early Hints, brak skryptów firm trzecich bez zgody. Responsywność mobile-first od 360 px, breakpointy 360/480/768/1024/1280/1536, cele dotykowe 44 px, brak blokady powiększania (obecnie zablokowane). Szczegóły: sekcje 02 i 07.

## 9. SEO i GEO – siedem ruchów

1. Rekord DNS dla domeny głównej i przekierowania 301 ze starych plików `.html`, z `tax.beautypolisa.eu` i (po potwierdzeniu) z `beautypolisa.com`.
2. Odblokowanie w Cloudflare kategorii *AI Search* i *Agent*, wyłączenie zarządzanego robots.txt na rzecz `robots.ts` z repozytorium; decyzja zleceniodawcy w sprawie crawlerów treningowych.
3. Treść renderowana po stronie serwera, jeden H1, self-canonical, sitemap, OG generowane w Next.js.
4. JSON-LD jako `@graph`: `Organization`/`InsuranceAgency`, `Service` dla produktów, `FAQPage`, `BreadcrumbList`, `Article` z imiennym autorem, `HowTo` dla zgłoszenia szkody – gotowe pliki w `snippets/`.
5. `llms.txt` po polsku i wzorce treści „do cytowania” (blok „W skrócie”, nagłówki-pytania, tabele, liczby ze źródłem, data aktualizacji).
6. Spójność encji: jedno zdanie o marce, NAP, `sameAs`, profil Google Business, stopka z danymi rejestrowymi.
7. Pomiar bez wymyślonych wskaźników: GSC, Bing, referrery AI, comiesięczny ręczny audyt 20 promptów; horyzont 30–90 dni.

## 10. Treść, lejki i kampania

- 8 filarów (6 produktów + prawo i kontrole w salonie + pracownicy i benefity), 20 klastrów, 45 artykułów z frazami oznaczonymi jako hipotezy (narzędzia do badania fraz były w tej sesji niedostępne – lista 52 fraz czeka na jednorazową weryfikację).
- Kalendarz 12 tygodni: 2 publikacje + 1 aktualizacja strony produktowej tygodniowo; zadanie zerowe – migracja obecnych treści do MDX.
- Standardy YMYL: imienny autor, recenzent z uprawnieniami, wersja OWU, data przeglądu, zakaz obietnic; AI jako asystent, nie autor.
- Magnesy: quiz grup ryzyka (OC, bez bramki), wzór zgody na zabieg + checklista dokumentacji (OC, bramka e-mail), checklista kontroli sanepid/ZUS/US (Tax Protect), kalkulator rotacji vs pakiet (Grupowe ERGO, tylko na liczbach użytkownika).
- Kampania startowa 30 dni: brief, kalendarz z podziałem na ścieżki Canva/tekst, inwentarz slotów, budżet generowania do zatwierdzenia, komplet copy. Generowanie grafik i wysyłki wymagają osobnej zgody i dostępów.

## 11. Design

Aktualny jest design v3 (szczegóły: `10-design-v3-old-money.md`). Powstał po odrzuceniu v1 i v2; v2 zleceniodawca ocenił jako „ilustrację z komiksu” i poprosił o glamour w stylu old money oraz szkło na całej stronie. W Bloom zmieniono kierunek marki: nocny granat, kość słoniowa, pergamin i szampańskie złoto, nagłówki w Cormorant Garamond, tekst w Poppins. Płaskie ilustracje zastąpiły cztery zdjęcia z Bloom (salon, jedwab, marmur, martwa natura), a każda tafla szkła leży na zdjęciu. Szkło ma trzy warianty (jasne, mocne, ciemne) ze złotą ramką i wyjściami awaryjnymi `@supports`, `prefers-reduced-transparency` i `prefers-contrast: more`. W Bloom powstało 21 nowych ikon cienką linią, w jednym kolorze. Złoto `#B8975A` ma 2,49:1 na kości słoniowej, więc służy tylko jako ozdoba. Makieta: `design/v3/makieta-v3.html`, tokeny: `design/v3/tokens-v3.css`, ikony i zdjęcia: `design/v3/`.

## 12. Plan w skrócie

| Etap | Zakres | Orientacyjny czas [założenie] |
|------|--------|-------------------------------|
| Tydzień 0 | Szybkie wygrane na obecnej infrastrukturze: TLS 1.2, SSL strict, HSTS, odblokowanie botów AI, REVOKE grantów, usunięcie anti-inspect i blokady zoomu, decyzja o DNS apexu | 1 tydzień |
| Faza 1 | MVP: szkielet Next.js na Workers, home z glass widgetem, 6 stron produktowych, kalkulator OC, formularze, dokumenty, RODO, analityka, SEO techniczne, JSON-LD, panel | 6–9 tygodni |
| Faza 2 | Baza wiedzy i GEO: MDX, 12 tygodni treści, llms.txt, audyt promptów, strony /dla-kogo | równolegle od tygodnia 4, 12 tygodni |
| Faza 3 | Lejki: quiz, magnesy, seria Resend, kampania startowa | 3–5 tygodni |
| Faza 4 | Skalowanie: integracja z CRM Aura, przejęcie `tax.`, ewentualna sprzedaż online | wg decyzji |
| Strefa Klienta | Z0 decyzje prawne → Z1 konto i polisy (po fazie 1) → Z2 „Dam pracę”, „Szkolenia”, organizatorzy → Z3 rozszerzenia (sekcja 11 §19) | Z1 4–6 tygodni, Z2 5–7 tygodni [założenie] |

Pełny plan z WBS, rejestrem ryzyk, KPI/SLO i checklistami Definition of Done trafi do `08-plan-wdrozenia.md` (w przygotowaniu).

## 13. Decyzje zleceniodawcy blokujące start fazy 1

1. **Status dystrybutora** (broker czy agent) – wpływa na stopkę, klauzule, dane strukturalne i treść.
2. **Administrator danych i IOD** (Aura Consulting czy Aura Expert) oraz akceptacja podstaw prawnych i retencji.
3. **Zgoda na nowy projekt Supabase** i koszt stały ok. 30 USD miesięcznie [hipoteza] (Supabase Pro + Workers Paid).
4. ~~Potwierdzenie cenników~~ – **rozstrzygnięte 11.11.2026:** składki są sztywne (taryfa programu). Do dostarczenia zostają tylko aktualne tabele składek Tax Protect, Grupowego ERGO i abonamentów, jeśli różnią się od wartości w obecnym kodzie.
5. **Decyzja o crawlerach AI** (Search/Agent – rekomendujemy dopuścić; Training – do decyzji).
6. **Dokumenty OWU do publikacji** i zasady użycia nazw oraz logotypów ubezpieczycieli i Fundacji Beauty Razem.
7. **Imienny autor i recenzent** treści z uprawnieniami.
8. **Dane kontaktowe i profile** (telefon, e-mail, LinkedIn/Facebook/Instagram, Google Business Profile, KRS/NIP) do stopki, `ContactPoint` i `sameAs`.

**Strefa Klienta** (nie blokuje fazy 1): rozstrzygnięte 11.11.2026 – konto przy każdej polisie, brak odcięcia konta po wygaśnięciu polis, „Dam pracę” jako sama tablica bez wpisu do KRAZ, organizatorzy szkoleń. Otwarte (pełna lista w 11 §21): role RODO przy danych uczestników szkoleń – organizator jako odrębny administrator czy Aura jako podmiot przetwarzający (prawnik i IOD, blokuje Z2); właściciel konta, gdy ubezpieczającym jest spółka; akceptacja obowiązkowego TOTP dla właścicieli salonów; okres przechowywania dokumentów polis przy koncie bez daty wygaśnięcia; zasady weryfikacji i ewentualne opłaty dla organizatorów; formularz kontaktowy w ogłoszeniach czy wyłącznie bezpośredni e-mail lub telefon salonu.

Pełna, skonsolidowana lista pytań otwartych trafi do `08-plan-wdrozenia.md` (w przygotowaniu).

## 14. Jak powstał ten pakiet i jakie ma ograniczenia

- Podstawą jest audyt faktów (sekcja 01): przegląd repozytorium, odczyt tabel, polityk RLS i raportów bezpieczeństwa z dwóch projektów Supabase, odczyt DNS, ustawień i bot management strefy Cloudflare, research rynkowy.
- Sekcje 02–08 zostały napisane równolegle przez wyspecjalizowane agenty, a następnie poddane recenzji trzech niezależnych perspektyw (rzetelność techniczna i bezpieczeństwo, zgodność prawna i biznesowa w Polsce, jakość redakcyjna), poprawione i sprawdzone przez krytyka spójności międzysekcyjnej.
- Ograniczenia: narzędzia do badania fraz (Semrush, Ahrefs, OpenSEO) były niedostępne, więc wolumeny są hipotezami; strona beautypolisa.eu nie była osiągalna z sesji, więc nie wykonano audytu „na żywo”; kod Workera `aura-analytics-collector` nie był widoczny; stan prawny zgód marketingowych (PKE) i obowiązków IDD wymaga weryfikacji przez prawnika przed wdrożeniem klauzul.
- Nic w tym pakiecie nie obiecuje pozycji w wyszukiwarkach ani cytowań w asystentach AI; wszystkie liczby spoza audytu są oznaczone jako hipotezy lub założenia.

## 15. Następne kroki

1. Przegląd i akceptacja koncepcji przez zleceniodawcę, w szczególności decyzji D1–D22 i odpowiedzi na pytania z rozdziału 13.
2. Wykonanie szybkich wygranych tygodnia 0 (sekcja 08, rozdział 1) – są niezależne od budowy portalu i usuwają realne ryzyka już dziś.
3. Po akceptacji: szczegółowy plan implementacji fazy 1 (zadania, kolejność, testy) i start od szkieletu aplikacji z bramkami CI, zanim powstanie jakakolwiek strona.
