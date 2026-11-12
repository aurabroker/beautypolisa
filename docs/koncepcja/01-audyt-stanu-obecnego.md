# 01 · Audyt stanu obecnego (listopad 2026)

> Dokument wejściowy do koncepcji portalu **beautypolisa.eu**. Zawiera wyłącznie fakty ustalone
> podczas przeglądu repozytorium, projektów Supabase i konta Cloudflare oraz wyniki researchu rynkowego.
> Tam, gdzie czegoś nie udało się potwierdzić, jest to zaznaczone wprost.

## 1. Zlecenie

Opracować koncepcję portalu informacyjnego BeautyPolisa (React/Next.js) dla branży beauty, obejmującego:

| # | Produkt | Ubezpieczyciel / dostawca | Stan w obecnym repo |
|---|---------|---------------------------|---------------------|
| 1 | OC zawodowe dla branży beauty (program z ERGO Hestią, nr WA50/003353/24/A, we współpracy z Fundacją Beauty Razem) | Sopockie TU ERGO Hestia S.A. | kalkulator w `indeksowt.html` + `bp-app.js` |
| 2 | Ubezpieczenie karno-skarbowe Tax Protect | Colonnade Insurance S.A. Oddział w Polsce (OWU z 25.01.2023) | `tax-protect.html` |
| 3 | Utrata dochodu („prywatne L4”) | brak informacji o produkcie w repo; w `life.html` wzmianka o ofercie indywidualnej „Squarelife” z ochroną dochodu | tylko link `#` w nawigacji |
| 4 | NNW dzieci | brak informacji w repo | tylko link `#` w nawigacji |
| 5 | Ubezpieczenie grupowe ERGO dedykowane beauty (ERGO Życie w Biznesie EZwB 01/25 + MediOpieka MA 01/25) | STU na Życie ERGO Hestia S.A. | `life.html` / `life1.html` |
| 6 | (istniejące, nie wymienione w zleceniu) Opieka medyczna ENEL-MED / LUX MED | abonamenty, administrator danych: Aura Expert sp. z o.o. | `medical.html` |

Wymagania niefunkcjonalne wg zlecenia, w kolejności priorytetów: **bezpieczeństwo i stabilność → szybkość ładowania → responsywność → SEO/GEO**. Stos: React/Next.js, baza Supabase, wszystko przez Cloudflare. Dodatkowo wskazany efekt wizualny „glass widget” (glassmorphism) oraz zestaw skilli do zastosowania: schema markup, content strategy, SEO/AI visibility (GEO), code review, system design, Canva creator, design critique, lead magnets & funnels.

## 2. Marka i podmioty

- Marka: **BeautyPolisa** („BeautyPolisa created by Aura Consulting”). Obsługa brokerska: Aura Consulting sp. z o.o., ul. Bolkowska 2A/28, 01-466 Warszawa.
- Partner branżowy: **Beauty Razem** (od 2024 Fundacja Beauty Razem, założyciel Michał Łenczyński) – logo na ankiecie ERGO Hestii (`AnkietaBPEH.pdf`).
- Administrator danych dla abonamentów medycznych: Aura Expert sp. z o.o. (iod@auraexpert.pl).
- **Dane spółki podane przez zleceniodawcę 12.11.2026:** Aura Expert sp. z o.o., ul. Bolkowska 2A/28, 01-466 Warszawa, KRS 0000599840, NIP 5242793544, REGON 363673048. W makietach wpisana jako operator serwisu. Relacja z Aura Consulting sp. z o.o. (ten sam adres, w starych plikach „obsługa brokerska”) – do potwierdzenia.
- W kodzie występują równolegle oznaczenia „Obsługa Brokerska” i „Informacje o agencie ubezpieczeniowym” – status dystrybutora (broker vs agent) **do potwierdzenia**; ma to znaczenie dla obowiązków informacyjnych z ustawy o dystrybucji ubezpieczeń (IDD).
- Paleta obecna: granat `#2a3b69` (beauty-navy), róż `#e11d48` (beauty-pink), tło `#fafafa`, tekst `#1e293b`; font Montserrat (Playfair Display w najstarszej wersji, później usunięto szeryfy); tryb ciemny `#0f172a`.
- Domeny: w JSON-LD obecnie `https://www.beautypolisa.com/#agency`, docelowa domena wg zlecenia: **beautypolisa.eu**. Niespójność do usunięcia.

## 3. Fakty produktowe zawarte w obecnych stronach (do ponownego użycia w treściach)

### 3.1 OC beauty (kalkulator `bp-app.js`)
- 4 grupy ryzyka zabiegów: gr. 1 (fryzjerstwo, kosmetyka pielęgnacyjna, manicure, rzęsy…), gr. 2 (makijaż permanentny, mezoterapia, lasery nieablacyjne, IPL, tatuaż, peelingi chemiczne…), gr. 3 (podologia), gr. 4 = wysokie ryzyko wymagające indywidualnej oceny (HIFU, toksyna botulinowa, PRP, PLASMA, kwas hialuronowy, nici PDO, lipoliza iniekcyjna, laser ablacyjny).
- Sumy gwarancyjne: 100 000 / 200 000 / 300 000 zł. Cennik programu zapisany w kodzie (taryfa, składka roczna; składki są sztywne – stan potwierdzony przez zleceniodawcę 11.11.2026): gr.1: 400/500/650 zł; gr.2: 650/790/950 zł; gr.3: 850/980/1250 zł; klauzula ochrony prawnej +92 zł; zespół 6–8 osób – składka ×1,25. Gr. 4 oraz zespół od 9 osób → wycena indywidualna (ankieta ERGO Hestii).
- Wniosek (ankieta ERGO Hestia) wymaga m.in.: NIP, REGON, data rozpoczęcia działalności, liczba zatrudnionych, szkodowość z 3 lat, lista zabiegów wysokiego ryzyka, formularze zgody na zabieg, kwalifikacje personelu.
- Lead trafia do tabeli `bp_quotes` w Supabase (status: new/sent/accepted/contact/rejected).

### 3.2 Tax Protect (Colonnade)
- Sekcja 1: ochrona karnoskarbowa dla właściciela/zarządu; sekcja 2: ochrona podatkowa dla firmy (jeden pełny spór podatkowy w roku).
- Warianty sum: 50 000 / 100 000 zł (sekcja 1), 250 000 / 500 000 / 1 000 000 / 3 000 000 zł; przychody powyżej 3 mln zł → wycena indywidualna.
- Tabela `tax_warianty` w projekcie Supabase „BEAUTY” ma komentarz: „Wartości składek DO POTWIERDZENIA z Colonnade”. Komentarz jest nieaktualny – rozstrzygnięte 11.11.2026: zleceniodawca potwierdził, że składki Tax Protect są sztywne (taryfa programu); strona może pokazywać kwoty z taryfy (wartości z `tax_warianty` lub przekazane przez zleceniodawcę).

### 3.3 Grupowe życie ERGO (life.html)
- Pakiety (warianty I / II / III): 58 / 68 / 76 zł za osobę miesięcznie wg cennika programu; sumy (przykłady z kodu): 100 000 / 210 000 zł, 80 000 / 170 000, 75 000 / 160 000; moduły MediOpieki: assistance domowy (limit 10 000 zł/rok), diagnostyka (20 konsultacji, rezonans, tomografia), onkologia, zdrowie psychiczne, tele-EKG, rehabilitacja; Global Doctors.
- Argumentacja sprzedażowa: „tarcza anty-rotacyjna”, koszt rotacji pracownika ok. 15 000 zł, pakiet zamiast podwyżki 50 zł.

### 3.4 Opieka medyczna
- ENEL-MED i LUX MED, abonamenty wg cennika programu zapisanego w kodzie (120–478 zł miesięcznie, zależnie od sieci, zakresu – pracownik / partner / rodzina – i liczby osób: 3–10 / 11–20 / 21–50), wycena korporacyjna 51+ osób.

### 3.5 Utrata dochodu i NNW dzieci
- Brak jakichkolwiek danych produktowych w repo. Z researchu rynkowego: produkt „utrata dochodu” kierowany do samozatrudnionych/B2B (min. ok. 80% przychodów z własnej działalności), istotne: definicja niezdolności do pracy, karencja, wyłączenia, kwestia kosztu podatkowego (interpretacje niejednoznaczne). NNW dzieci: rynek 2026/27 – składki indywidualne zwykle 40–150 zł/rok, sumy 5 000–220 000 zł, ubezpieczenie szkolne jest dobrowolne. **Konkretna oferta BeautyPolisa w tych dwóch liniach musi zostać dostarczona przez zespół produktowy.**

## 4. Repozytorium `aurabroker/beautypolisa` – stan

Pliki: `index.html` („Hello World”, 13 B), `indeksowt.html` (85 KB, pełny kalkulator OC, Tailwind skompilowany do `style.css`), `new.html` + `bp-app.js` (74 KB, wersja SPA budująca DOM z JS, Supabase w kliencie, panel admina), `bp-nav.js` (wspólny header z 6 zakładkami produktów), `nowy.html` (hero „React-ready”), `tax-protect.html`, `life.html`, `life1.html`, `medical.html`, logo PNG, `AEX.png`, `AnkietaBPEH.pdf`, `README.md` (opisuje Web3Forms, które w kodzie zastąpiono Supabase).

Ustalenia z przeglądu kodu (szczegóły w `03-code-review-obecnego-kodu.md`):
1. `bp-app.js` zawiera skrypt „anti-inspect” (blokada F12, prawego przycisku, Ctrl+U/S/P, pętla `debugger` co 4 s, która **czyści całe `document.body`** przy wykryciu DevTools). Szkodzi dostępności, wydajności, SEO i zaufaniu, nie daje żadnej realnej ochrony.
2. Klucz `anon` Supabase i URL projektu są złożone z fragmentów w kodzie (obfuskacja pozorna). Klucz anon jest z założenia publiczny, ale bezpieczeństwo zależy wyłącznie od polityk RLS, które nie są widoczne w repo.
3. Panel administracyjny (lista leadów `bp_quotes`, zmiana statusów, analityka) jest renderowany w tym samym publicznym bundle, a autoryzacja opiera się na `bp_profiles.is_admin` odczytywanym po stronie klienta.
4. Analityka własna (`bp_analytics`) – każdy wizytator wykonuje `INSERT` z klienta (session id, referrer, UTM, device). Brak limitów i walidacji po stronie serwera.
5. Formularze: brak CAPTCHA/Turnstile, brak rate limitingu, walidacja tylko w kliencie; notatki wniosku sklejane jako tekst.
6. Strony HTML zawierają skrypt Chart.js/confetti z CDN, Google Fonts bez `font-display` kontrolowanego lokalnie, `maximum-scale=1, user-scalable=no` (blokada zoomu – problem WCAG).
7. SEO: JSON-LD tylko `InsuranceAgency` (z domeną .com), brak `FAQPage` mimo sekcji FAQ, brak `BreadcrumbList`, brak `sitemap.xml`/`robots.txt`/`llms.txt` w repo, meta `keywords` (bez znaczenia), tytuły OK, brak `canonical`, brak hreflang (jednojęzyczny – OK).
8. Treść produktowa jest zaszyta w HTML/JS (brak CMS), duplikaty (`life.html` vs `life1.html`, `index` vs `indeksowt` vs `new`).

## 5. Supabase – stan projektów (jedna organizacja, region eu-west-1, Postgres 17)

### 5.1 Projekt „aurabroker” – używany przez `bp-app.js`
- Współdzielona baza wielu niezależnych modułów Aura (158 tabel w `public`: CRM 52 tabele, `ud_*` 26, `izba_*` 10, `bond_*`, `ads_*`, `life_*`, `apk_*`, `ezb_*`, `cms.*` Payload itd.).
- Tabele BeautyPolisa: `bp_profiles` (3 wiersze; `is_admin boolean`), `bp_quotes` (0), `bp_policies` (0), `bp_analytics` (66). RLS włączone na wszystkich; polityki zweryfikowane w `pg_policies`:
  - `bp_quotes`: INSERT dla każdego (`user_id` NULL lub własny, status tylko `new`/`contact`, limity długości pól, zakresy sum i składek), SELECT dla właściciela lub admina, UPDATE tylko admin; brak polityki DELETE.
  - `bp_analytics`: INSERT dla każdego z limitami długości, SELECT tylko admin.
  - `bp_profiles`: właściciel ma CRUD na własnym wierszu; trigger `bp_profiles_guard` blokuje nadanie/zmianę `is_admin` przez role inne niż `service_role` (eskalacja uprawnień przez własny profil **nie jest** możliwa – sprawdzone).
  - `bp_policies`: SELECT tylko właściciel; brak polityk zapisu.
  - Słabości pozostałe: role `anon`/`authenticated` mają nadane na poziomie tabel uprawnienia DELETE/UPDATE/TRUNCATE (domyślne granty Supabase; RLS je neutralizuje dla DELETE/UPDATE, ale TRUNCATE nie podlega RLS – wymagane `REVOKE`), brak ograniczeń częstotliwości wstawiania (spam leadów/analityki), brak weryfikacji e-mail/telefonu, brak CAPTCHA.
- Security advisor: 44 tabele z RLS bez polityk (głównie inne moduły), 21 funkcji `SECURITY DEFINER` wykonywalnych przez `anon` (np. `is_admin()`, `submit_apk`, `ud_offer_by_token`), 15 funkcji z mutowalnym `search_path`, rozszerzenie `unaccent` w `public`, wyłączona ochrona przed wyciekłymi hasłami (HaveIBeenPwned).
- Wniosek: trzymanie publicznego portalu na kluczu anon współdzielonej bazy z CRM i danymi wielu modułów to największe pojedyncze ryzyko bezpieczeństwa obecnej architektury.

### 5.2 Projekt „BEAUTY”
- Polityki RLS sprawdzone wyrywkowo: `tax_warianty` – publiczny odczyt aktywnych wariantów; `tax_wnioski` – **RLS bez żadnej polityki** (formularz z `tax.beautypolisa.eu` musi więc zapisywać przez backend z kluczem serwisowym albo nie działa); `crm_lead_intake` – INSERT dla `anon` tylko z `rodo = true`, `processed = false`, `status = 'nowy'` (dobry wzorzec do powielenia); `utm_*` – wyłącznie `is_platform_admin()`.
- Zawiera: katalog salonów (multi-tenant: `salons`, `salon_memberships`, `services`, `domains`, `reviews`, `plans`, `subscriptions`, `seo_pages`, rezerwacje `appointments`/`staff`), CRM (`crm_companies` 1463 wierszy, `crm_policies`, `crm_lead_intake`, `crm_audit_log`), moduł Tax Protect (`tax_warianty` 8, `tax_wnioski` 1), e-mail (`email_messages` 3875), szkolenia, ogłoszenia o pracę, moduł UTM (`utm_links`, `utm_clicks`, `utm_attributions`), raporty Google Ads, `konsultacja_*` (agent AI).
- Security advisor: 3 widoki `SECURITY DEFINER` (**ERROR**: `public_catalog_services`, `public_salon_reviews`, `public_catalog_salons`), `tax_wnioski` i `mienie_*` z RLS bez polityk, 17 funkcji SECURITY DEFINER dostępnych dla `anon` (w tym `katalog_set_admin`, `katalog_admin_users`, `rls_auto_enable`), widok zmaterializowany `salon_search_index` dostępny z API, rozszerzenia `citext`/`unaccent`/`pg_trgm` w `public`, wyłączona ochrona haseł.

## 6. Cloudflare – strefa `beautypolisa.eu` (plan Free, status active)

- **Brak rekordu DNS dla apex `beautypolisa.eu` i dla `www`** – główna domena nie serwuje obecnie żadnej strony. Istnieją subdomeny: `app.` → Pages `catalog-amh` (katalog salonów), `crm.` → Pages `beauty-crm`, `portal.` → Pages `crmaura`, `tax.` → Pages `taxbp` (Tax Protect), `ergo.` → Worker `gohestia`, `konsultacja.` → Worker `konsultacja-agent`. Poczta: Microsoft 365 (MX, SPF, autodiscover), wysyłka transakcyjna: Resend (`send.`/`links.`, DKIM).
- Trasa Workera `beautypolisa.eu/*` → `aura-analytics-collector` (bindingi: KV `VISITOR_SALT`, Analytics Engine `WEB_EVENTS`). Każde żądanie do apexu przechodzi przez ten Worker – należy to uwzględnić (albo wpiąć kolektor jako bibliotekę w nowej aplikacji, albo zostawić Worker jako warstwę przed aplikacją).
- Istnieje Worker `security-headers` (KV `SECURITY_POLICIES`) bez trasy w tej strefie.
- Ustawienia: SSL `full` (nie `strict`), **min TLS 1.0**, HSTS wyłączony, Always HTTPS on, TLS 1.3 on, HTTP/3 on, Brotli on, Early Hints off, 0-RTT off, security level medium, cache TTL 4 h, brak page rules, tylko managed rulesets (Free).
- **Bot management: `ai_bots_protection: block`, `ai_training: disallow`, `ai_search: disabled`, `ai_user: disabled`, wszyscy agenci AI (OpenAI, Anthropic, Google) `disabled`, `is_robots_txt_managed: true`** – Cloudflare blokuje crawlery AI i zarządza robots.txt. To bezpośrednio uniemożliwia cele GEO (cytowanie w ChatGPT/Perplexity/AI Overviews). Decyzja: dopuścić kategorię *AI search* i *AI user/agent* (OAI-SearchBot, ChatGPT-User, PerplexityBot, Claude-SearchBot, Google-Extended wg polityki), ewentualnie nadal blokować *training*.
- Konto zawiera 21 Workerów innych serwisów Aura (m.in. `grupowe`, `medicalaura`, `gwarancje`, `kancelaria-worker`).

## 7. Research rynkowy i narzędzia

- Narzędzia keyword research niedostępne w tej sesji: Semrush (brak jednostek API), Ahrefs (plan bez Keywords Explorer), OpenSEO (brak kredytów). **Wolumeny słów kluczowych w koncepcji są hipotezami do zweryfikowania** (zalecenie: GSC po starcie + jednorazowy eksport z Senuto/Semrush).
- Strona beautypolisa.eu oraz beautypolisa.com nie były osiągalne z sesji (polityka sieciowa); audyt „live” nie został wykonany.
- Konkurencja w SERP dla fraz „ubezpieczenie salonu kosmetycznego / OC kosmetyczki”: poradniki CUK (cuk.pl/porady), Rankomat, Warta (pakiet Studio urody / Ekstrabiznes Plus), blog Booksy (formularz zgody + ubezpieczenie), Prawo.pl (odszkodowania za nieudany zabieg). Dla „utrata dochodu”: Poradnik Przedsiębiorcy, CUK, Firmove, podatki.biz (koszt podatkowy). Dla NNW dzieci: Rankomat, Mubi, Portal Oświatowy, PZU Edukacja, InterRisk.
- Nie znaleziono publicznych źródeł opisujących program OC ERGO Hestia dla Beauty Razem – treści na portalu będą pierwotnym źródłem (szansa na cytowalność, obowiązek precyzji i zgodności z OWU).
- Cloudflare od 15.09.2026 blokuje domyślnie crawlery AI z kategorii Training i Agent dla nowych/Free stref; kategoria Search pozostaje dozwolona – ale w tej strefie `ai_search` jest wyłączony.

## 8. Założenia przyjęte w koncepcji (do potwierdzenia przez zleceniodawcę)

1. Portal jest **informacyjno-leadowy**, nie sprzedaje polis online (brak płatności, brak zawierania umów na stronie); sprzedaż domyka zespół Aura Consulting.
2. Jeden język (PL), jeden rynek (PL); domena kanoniczna `https://beautypolisa.eu` (bez `www`).
3. Istniejące subdomeny (`tax.`, `app.`, `crm.`, `portal.`, `ergo.`, `konsultacja.`) pozostają; portal na apexie linkuje do nich i docelowo przejmuje treści `tax.`.
4. Dane portalu trafiają do **oddzielnego projektu Supabase** (lub dedykowanego schematu w projekcie „BEAUTY”), nigdy do współdzielonego „aurabroker”.
5. Hosting: Cloudflare Workers (OpenNext) + statyczne assety; CI/CD z GitHub.
6. Efekt „glass widget”: kalkulator/CTA w formie półprzezroczystej karty (backdrop-filter) z pełnym fallbackiem i poszanowaniem `prefers-reduced-transparency`.
