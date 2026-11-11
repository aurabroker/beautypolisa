# 02 · Architektura systemu, bezpieczeństwo, stabilność i wydajność

> Sekcja koncepcji portalu **beautypolisa.eu**. Fakty o stanie obecnym (produkty, ceny, Supabase, Cloudflare) pochodzą wyłącznie z `01-audyt-stanu-obecnego.md`; szczegóły obecnego kodu – w `03-code-review-obecnego-kodu.md`. Wszystko, co nie wynika z audytu, oznaczono jako „[założenie]” lub „[hipoteza – do weryfikacji]”. Dokument nie zawiera sekretów ani identyfikatorów projektów/stref. Gotowe do wklejenia pliki (DDL, polityki RLS, nagłówki, CI, `wrangler.jsonc`, schemat Zod, pliki prawne JSON) leżą w `snippets/` – wykaz w pkt 3.0; ich treść jest identyczna z blokami kodu w tym dokumencie.

## TL;DR

- Jedna aplikacja **Next.js (aktualna stabilna wersja, App Router, RSC, TypeScript) + Tailwind CSS 4** uruchamiana na **Cloudflare Workers**: adapter `@opennextjs/cloudflare` jako wariant bazowy, `vinext` (wskazywany przez Cloudflare dla nowych projektów Next.js [do weryfikacji na starcie implementacji]) wybierany, jeśli przejdzie PoC z kryteriami z sekcji 8; HTML renderowany na Workerze (żeby każda odpowiedź miała własny nonce CSP), warstwa danych buforowana, assety statyczne z Workers Static Assets. **Workers Paid od pierwszego dnia** – limit 10 ms CPU na żądanie w planie Free wyklucza stabilny SSR.
- **Nowy, dedykowany projekt Supabase** (Postgres + RLS). Przeglądarka nie dostaje żadnego klucza Supabase: leady zapisuje wyłącznie serwer (klucz serwisowy w sekretach Workera) przez jedną transakcyjną funkcję SQL; cenniki są wersjonowane w bazie, aktywacja wersji wymaga zatwierdzenia, publiczny odczyt tylko aktywnych wierszy.
- Treść produktowa i baza wiedzy jako **MDX/JSON w repozytorium**, walidowane Zod i przeglądane w PR; brak CMS w pierwszej wersji. Informacje prawne (dane dystrybutora wg IDD, klauzula informacyjna, treści zgód per kanał, baner cookies) jako **wersjonowane pliki JSON/MDX** w tym samym repozytorium.
- Ochrona formularzy warstwowo, od najtańszej: **honeypot → idempotencja → rate limit (Cloudflare i binding w Workerze) → walidacja Zod → Turnstile → zapis z deduplikacją**; e-mail przez Resend z tabelą outbox i ponowieniami z Cron Triggers – **bez kolejek**.
- RODO: lead **bez checkboxa „zgody na przetwarzanie”** (podstawa: działania przed zawarciem umowy; rejestrujemy wersję wyświetlonej klauzuli informacyjnej), zgody wyłącznie marketingowe, osobno per kanał (RODO + PKE), wycofywane samodzielnie linkiem; **bez przechowywania adresu IP** (także w postaci hasha).
- Zmiany w Cloudflare względem audytu: SSL **Full (strict)**, **min TLS 1.2**, HSTS etapami, Early Hints, jedna reguła rate limit (plan Free) zawężona do endpointów formularzy, usunięcie trasy `aura-analytics-collector` z apexu na rzecz Service Binding; panel wewnętrzny za **Cloudflare Access + Supabase Auth (MFA egzekwowane w RLS) + RLS**.
- Zakres operacyjny dopasowany do zespołu 1–2 osób: podział na „musi w v1” i „później” (pkt 1.4); koszt stały infrastruktury ok. 30 USD/mies. [hipoteza – rozbicie w pkt 1.3].

---

## 1. Wymagania

### 1.1 Wymagania funkcjonalne

| ID | Wymaganie | Uwagi architektoniczne |
|----|-----------|------------------------|
| F1 | Strony produktowe dla 6 produktów (`/ubezpieczenia/*`) z nazwami: „OC dla branży beauty (ERGO Hestia)”, „Tax Protect (Colonnade)”, „Utrata dochodu”, „NNW dzieci”, „Grupowe ERGO dla beauty”, „Opieka medyczna (ENEL-MED / LUX MED)” | Treść z repo (MDX), renderowana po stronie serwera. Dla „Utrata dochodu” i „NNW dzieci” audyt nie zawiera danych produktowych – strony startują jako „zapytaj o ofertę” bez cennika. Frontmatter `productKind: 'insurance' \| 'medical_subscription'`: abonamenty ENEL-MED/LUX MED (wg audytu: abonamenty, administrator danych Aura Expert) dostają inną stopkę (inny administrator, brak odniesień do OWU/IDD) i w treści nie są nazywane ubezpieczeniem – ryzyko wprowadzenia w błąd co do charakteru usługi. Adres `/ubezpieczenia/opieka-medyczna` przyjęty w sekcji SEO – do rewizji na `/opieka-medyczna` po odpowiedzi na pytanie otwarte 13. |
| F2 | Kalkulator OC (`/kalkulator/oc`) z logiką grup ryzyka z briefu: gr. 1–3 z cennikiem (sumy 100/200/300 tys. zł; składki gr.1: 400/500/650, gr.2: 650/790/950, gr.3: 850/980/1250 zł; klauzula ochrony prawnej +92 zł), gr. 4 i zespół > 8 osób → wycena indywidualna | Jedyna większa „wyspa” interaktywna. Logika jako czysta funkcja w pakiecie współdzielonym, testowana jednostkowo; cennik z bazy, wersjonowany, **aktywny dopiero po zatwierdzeniu** (liczby pochodzą z kodu kalkulatora, nie z potwierdzonego dokumentu ubezpieczyciela – pytanie otwarte 12). |
| F3 | Formularze leadowe per produkt (wspólny endpoint, pole `product`), strony `/dla-kogo/<zawod>` z prewypełnionym kontekstem | Minimalny zakres PII na etapie leada (imię i nazwisko, e-mail, telefon, opcjonalnie nazwa firmy/NIP). Pod przyciskiem wysyłki klauzula informacyjna RODO i informacje o dystrybutorze (IDD) – bez checkboxa; zgody marketingowe jako osobne, niezaznaczone pola per kanał. Pełna ankieta ERGO Hestii (szkodowość 3 lata, kwalifikacje personelu itd.) **nie** jest zbierana przez portal w v1. |
| F4 | Baza wiedzy (`/baza-wiedzy/<slug>`) | MDX w repo, statyczne dane, schema.org w sekcji SEO/GEO koncepcji. |
| F5 | Dokumenty OWU (`/dokumenty`) | PDF jako assety statyczne z wersjonowanymi nazwami plików; lista z MDX/JSON. Publikacja OWU/warunków programu i logotypów partnerów wymaga potwierdzonej zgody (frontmatter `publicationApproved`, `brandUsageApproval` – pkt 2.5, pytanie otwarte 14). |
| F6 | Panel wewnętrzny do leadów (`/panel`) – lista, statusy, przypisanie, oznaczenie przekazania do CRM/ubezpieczyciela, aktywacja wersji cennika, anonimizacja, obsługa żądań z art. 15/17 RODO | Supabase Auth (tylko panel), tabela ról z triggerem guard, RLS, dodatkowo Cloudflare Access przed `/panel/*`. |
| F7 | Zgłoszenie szkody (`/szkoda`) | W v1 przede wszystkim **strona instruktażowa** (kroki, infolinia szkodowa ubezpieczyciela, lista dokumentów, kontakt do opiekuna w Aura) oraz krótki formularz **bez wolnego tekstu** (produkt, nr polisy, kontakt, data i rodzaj zdarzenia z listy); szczegóły zdarzenia opiekun zbiera telefonicznie – portal nie gromadzi opisów, które niemal zawsze dotyczą zdrowia osób trzecich (art. 9 RODO). Dane do `claims_reports`; powiadomienie zespołu. |
| F8 | Newsletter z double opt-in i samoobsługową rezygnacją | Tabela `newsletter_subscribers`, token potwierdzenia hashowany i jednorazowy; potwierdzenie przez `POST` z przycisku (nie skutek uboczny `GET`); link rezygnacji w każdej wiadomości + nagłówki `List-Unsubscribe`/`List-Unsubscribe-Post`. |
| F9 | Strony `/o-nas`, `/kontakt`, `/rodo`, przekierowania ze starych plików `.html`, linkowanie do subdomen Aura | Statyczne; redirecty w konfiguracji Next.js. |
| F10 | Informacje o dystrybutorze ubezpieczeń (IDD) i reklamacje: strona `/informacje-prawne` oraz komponent stopki/formularza | Jedno źródło: `packages/content/legal/distributor.json` (firma, adres, `registryType: 'agent' \| 'broker'`, numer w rejestrze KNF i adres do jego sprawdzenia, charakter wynagrodzenia, działanie na rzecz jednego/wielu zakładów, procedura reklamacji, podmioty pozasądowego rozwiązywania sporów – Rzecznik Finansowy). Do czasu potwierdzenia statusu dystrybutora (audyt §2: „do potwierdzenia”) plik ma wartości zastępcze, a **test w CI blokuje wdrożenie produkcyjne przy `registryNumber === null`**. Wersja treści (`idd-v1-2026-11`) zapisywana przy każdym leadzie. Zakres do potwierdzenia z prawnikiem [ustawa o dystrybucji ubezpieczeń, art. 22/32]. |

### 1.2 Wymagania niefunkcjonalne – cele mierzalne

| Obszar | Cel | Jak mierzymy |
|--------|-----|--------------|
| Dostępność | **99,9 %** miesięcznie (budżet błędu ≈ 43 min/mies.) dla stron publicznych; API leadów: ≥ 99,5 % odpowiedzi innych niż 5xx i innych niż timeout (4xx – 422/403/429 – to pożądane odrzucenia, raportowane osobno) | Zewnętrzny monitor uptime (1–5 min), metryki Workers |
| Szybkość | **LCP p75 mobile ≤ 2,0 s**, **INP ≤ 200 ms**, **CLS ≤ 0,1**, **TTFB ≤ 500 ms** (p75) | CrUX/Search Console po starcie, Lighthouse CI, RUM własny (Analytics Engine) |
| Budżet JS | **≤ 120 KB gzip JS na landing** (home, strony produktowe bez kalkulatora mniej), CSS ≤ 30 KB gzip, fonty ≤ 120 KB łącznie, obraz hero ≤ 150 KB | `size-limit` w CI, budżety Lighthouse CI (`budget.json`) |
| Responsywność | Mobile-first, brak przewijania poziomego od 320 px, zoom dozwolony (usunięcie `user-scalable=no` z audytu), cele dotykowe ≥ 44 px | Playwright (v1: 2 viewporty, docelowo 3), audyt WCAG w Lighthouse |
| RTO / RPO | **RTO ≤ 4 h**, **RPO ≤ 24 h** dla bazy; dla leadów efektywne RPO ≈ 0, bo każdy lead jest równolegle dostarczany e-mailem do zespołu (druga kopia poza bazą) | Test odtworzenia kopii: jeden przed startem, potem raz na kwartał (pkt 1.4) |
| RODO | Brak PII w logach, brak adresu IP w bazie, retencja leadów bez konwersji 12 mies. [założenie], mechanizm usunięcia/anonimizacji na żądanie ≤ 72 h [założenie], rejestr zgód z wersją treści per kanał, samoobsługowe wycofanie zgody | Przegląd kwartalny, test anonimizacji w CI (funkcja SQL) |
| Bezpieczeństwo | Brak klucza Supabase w przeglądarce, CSP z nonce, A+ w skanerach nagłówków, 0 krytycznych podatności zależności w `main`, 0 funkcji w `public` wykonywalnych przez `anon`/`PUBLIC` | Skaner nagłówków po każdym wdrożeniu, `pnpm audit` i test uprawnień SQL w CI |

### 1.3 Ograniczenia

- **Mały zespół** (1–2 osoby techniczne [założenie]) – architektura ma mieć mało ruchomych części: jeden Worker aplikacji, jeden mały Worker zadań cyklicznych, jedna baza, brak kolejek i brak CMS; zakres operacyjny podzielony na v1 i „później” (pkt 1.4).
- **Istniejąca infrastruktura Aura** (z audytu): strefa `beautypolisa.eu` na planie Free; subdomeny `app.`, `crm.`, `portal.`, `tax.`, `ergo.`, `konsultacja.`; trasa Workera `aura-analytics-collector` na `beautypolisa.eu/*`; Worker `security-headers` bez trasy; Resend z DKIM już skonfigurowany (`send.`/`links.`); poczta Microsoft 365; dwa projekty Supabase („aurabroker” – współdzielony, „BEAUTY” – z modułem Tax Protect).
- **Plan Cloudflare Free** – co działa, a co wymaga dopłaty:

| Potrzeba | Free | Wymaga | Koszt orientacyjny [hipoteza – do weryfikacji] |
|----------|------|--------|-----------------------------------------------|
| Workers: rendering, Static Assets, Cron Triggers, KV, Service Bindings | Technicznie tak, ale **10 ms CPU na żądanie** i ~100 tys. żądań/dzień – rendering drzewa RSC w Next.js z łatwością przekracza 10 ms, więc SSR na Free nie działa stabilnie | **Workers Paid od startu** (domyślnie 30 s CPU na żądanie), nie „przy większym ruchu”; Paid daje też Queues i dłuższą retencję logów | ~5 USD/mies. + zużycie |
| WAF managed rules | Tylko „Free Managed Ruleset” (podzbiór) | Pełny Cloudflare Managed Ruleset i OWASP – plan Pro | ~20 USD/mies. za strefę |
| Rate limiting | 1 reguła | 2 reguły (Pro), 5 (Business), zaawansowane – dodatek płatny | jw. |
| Turnstile | Tak | – | 0 |
| Cloudflare Access (Zero Trust) przed `/panel` | Tak, do ok. 50 użytkowników | – | 0 |
| Zaraz (ładowanie tagów firm trzecich po stronie serwera CF) | Tak, z limitem zdarzeń | Powyżej limitu | 0 → zużycie |
| Image Transformations | Włączenie na strefie; pula darmowych transformacji | Powyżej puli | niewielki |
| Supabase | Free pauzuje nieaktywne projekty (po ok. 7 dniach) – **niedopuszczalne na produkcji**; limit 2 aktywnych projektów Free na organizację (plany „aurabroker”/„BEAUTY” nieznane z audytu) | Pro (kopie dzienne, brak pauzowania) | ~25 USD/mies.; PITR dodatkowo ~100 USD/mies. za 7 dni – odłożony |
| Resend | Darmowy limit miesięczny | Przy większym wolumenie | 0 → ~20 USD/mies. |
| Sentry | Plan deweloperski | Przy większym wolumenie zdarzeń | 0 → ~26 USD/mies. |

Rekomendacja startowa: Workers Paid + Supabase Pro (ok. 30 USD/mies. [hipoteza]). Cloudflare Pro dopiero, jeśli pojawią się ataki, których nie zatrzyma Turnstile + jedna reguła rate limit. Wszystkie kwoty w dokumencie odsyłają do tej tabeli – przy aktualizacji cenników zmieniamy jedno miejsce.

### 1.4 Zakres operacyjny: v1 vs później

Każdy z mechanizmów opisanych dalej jest sensowny, ale razem tworzą obciążenie zespołu platformowego, którego firma brokerska z 1–2 osobami technicznymi nie ma. Podział [do akceptacji]:

| Obszar | v1 (musi być przed startem) | Później (gdy > 20 leadów/dzień [próg założony] lub druga osoba techniczna) |
|--------|-----------------------------|-----------------------------------------------------------------------------|
| Ochrona formularzy | Turnstile, honeypot, rate limit Cloudflare + binding, walidacja Zod | – |
| Baza | RLS/REVOKE, testy uprawnień w CI, Supabase Pro z kopiami dziennymi, **jeden** test odtworzenia przed startem | kwartalne testy odtworzenia, PITR |
| Nagłówki | CSP Report-Only → egzekwowana, HSTS etapami | – |
| Monitoring | Sentry (serwer), uptime zewnętrzny, alert outboxu | dashboard RUM, szczegółowe alerty kosztowe |
| CI | typecheck, lint, testy, build, `size-limit`, gitleaks, smoke Playwright (1 viewport mobile + 1 desktop) | Lighthouse CI w każdym PR (w v1: ręcznie przed wydaniem), Playwright na 3 viewportach, Renovate z automatycznym scalaniem |
| Wdrożenia | 100 % ruchu na nową wersję + natychmiastowy `wrangler rollback` | kanarki 10 % z version affinity |
| Przeglądy bezpieczeństwa | Security Advisor po każdej migracji i raz w miesiącu | co tydzień |
| Reakcja na alerty | w godzinach pracy (pn–pt 9–17) potwierdzenie w ≤ 2 h; poza nimi – następny dzień roboczy; strona błędu formularza zawsze pokazuje telefon/e-mail (fallback) [założenie do akceptacji] | dyżur rozszerzony |
| Akceptacja wdrożenia produkcyjnego | **właściciel biznesowy** jako recenzent środowiska `production` w GitHub – nie musi to być druga osoba techniczna | – |

---

## 2. Projekt wysokopoziomowy

### 2.1 Diagram komponentów

```text
                 ┌──────────────────────────────────────────────────────────────────────────────────┐
                 │                         CLOUDFLARE (strefa beautypolisa.eu)                      │
 użytkownik ───► │ DNS ─► TLS (Full strict, min 1.2, HSTS) ─► reguły WAF własne (sprawdzenie Origin)│
 (mobile first)  │     ─► Rate Limiting (1 reguła: POST na endpointy formularzy) ─► Managed Ruleset │
                 │     ─► Turnstile (widget w formularzach) ─► Zaraz (tagi wyłącznie po zgodzie)    │
                 │                                    │                                             │
                 │              ┌─────────────────────▼──────────────────────┐                      │
                 │              │  Worker: beautypolisa-web (OpenNext/vinext)│                      │
                 │              │  • Next.js App Router, RSC, route handlers │                      │
                 │              │    /api/*, server actions /panel           │                      │
                 │              │  • Static Assets: /_next/static, /dokumenty│                      │
                 │              │  • KV: cache inkrementalny Next.js         │                      │
                 │              │  • binding ratelimit: LEAD_RATE_LIMITER    │                      │
                 │              └───┬──────────┬───────────┬───────────┬─────┘                      │
                 │                  │          │           │           │ Service Binding            │
                 │                  │          │           │     ┌─────▼─────────────────────┐      │
                 │                  │          │           │     │ Worker: aura-analytics-   │      │
                 │                  │          │           │     │ collector (istniejący)    │      │
                 │                  │          │           │     │ KV VISITOR_SALT,          │      │
                 │                  │          │           │     │ Analytics Engine          │      │
                 │                  │          │           │     │ WEB_EVENTS                │      │
                 │                  │          │           │     └───────────────────────────┘      │
                 │   ┌──────────────▼───────┐  │           │                                        │
                 │   │ Worker: beautypolisa-│  │           │                                        │
                 │   │ jobs (Cron Triggers) │  │           │                                        │
                 │   │ • retry outbox e-mail├──┼───┐       │                                        │
                 │   │ • retencja/anonimiz. │  │   │       │                                        │
                 │   └──────────┬───────────┘  │   │       │                                        │
                 └──────────────┼──────────────┼───┼───────┼────────────────────────────────────────┘
                                │              │   │       │
                      ┌─────────▼──────────┐  ┌▼───▼────┐ ┌▼──────────────────┐
                      │ Supabase (nowy     │  │ Resend  │ │ Sentry (bez PII)  │
                      │ projekt, eu-west-1)│  │ (e-mail)│ │ Uptime zewnętrzny │
                      │ Postgres + RLS,    │  └─────────┘ └───────────────────┘
                      │ Auth tylko /panel  │
                      └────────────────────┘
                                ▲
    GitHub Actions ─────────────┘ (migracje `supabase db push`, `wrangler versions upload/deploy`)
```

### 2.2 Przepływ leada (krok po kroku)

1. **Formularz** (komponent kliencki) przy montażu generuje `idempotencyKey` (UUID v4, trzymany w stanie do odświeżenia strony) i renderuje widget Turnstile (`action: "lead"`, `cData` = produkt; klucz publiczny przekazany z serwera jako prop – pkt 4.5). Pole honeypot `extraInfo` leży w kontenerze ukrytym CSS-em (poza ekranem), ma `aria-hidden="true"`, `tabindex="-1"`, `autocomplete="off"` i etykietę „Pozostaw to pole puste” (dla technologii asystujących, które mimo wszystko do niego dotrą); nazwa celowo nie przypomina danych, które autouzupełnianie chętnie wpisuje (nie `website`/`url`). Pod przyciskiem wysyłki: klauzula informacyjna RODO i informacje o dystrybutorze (IDD) z wersjami; zgody marketingowe jako osobne, niezaznaczone pola wyboru per kanał.
2. Wysyłka `POST /api/leads` (JSON) – jeden endpoint dla wszystkich produktów.
3. **Cloudflare**, w kolejności faz przetwarzania: reguły WAF własne (`http_request_firewall_custom`: challenge dla `POST` bez nagłówka `Origin` równego domenie) → Rate Limiting (`http_ratelimit`, 10 żądań/10 s na IP dla endpointów formularzy, akcja „managed challenge”) → Free Managed Ruleset (`http_request_firewall_managed`) → Worker.
4. **Route handler** – warstwy od najtańszej do najdroższej:
   - (a) sprawdzenie `Origin`/`Sec-Fetch-Site`, limit rozmiaru ciała (16 KB), parsowanie JSON (`400 invalid_json`, `413`);
   - (b) **honeypot na surowym JSON, przed walidacją**: `extraInfo` niepuste → odpowiedź **nieodróżnialna od sukcesu** (`201`, losowy `reference`/`leadId`), bez zapisu i bez dalszych kroków (nie zdradzamy botowi, że go wykryto – gdyby honeypot był częścią schematu Zod, bot dostałby `422` z nazwą pola pułapki); w metrykach `honeypot_hit` oraz HMAC adresu e-mail w logu bez PII – monitorujemy odsetek, by wykryć fałszywe trafienia (autouzupełnianie, czytniki ekranu);
   - (c) **idempotencja**: `select id, reference from leads where idempotency_key = $1` (indeks unikalny, tanie); trafienie → `201` z istniejącym `reference`, bez Turnstile i bez zapisu – pierwsze żądanie przeszło już weryfikację, a token Turnstile jest jednorazowy, więc bez tego kroku ponowienie po utracie sieci kończyłoby się `403`;
   - (d) **rate limit aplikacyjny** (binding `LEAD_RATE_LIMITER`, klucz = hash IP + produkt, 5/min; licznik przybliżony, liczony osobno w każdej lokalizacji Cloudflare – ochronę globalną daje reguła strefy z kroku 3) → `429 rate_limited` z `Retry-After`;
   - (e) walidacja `LeadInput` (Zod) → `422 validation_failed` z listą pól; serwer odrzuca także wersje klauzul/zgód inne niż aktualne w repo.
5. **Turnstile** (jedyne wywołanie zewnętrzne przed zapisem): weryfikacja tokenu w API `siteverify` z sekretem Workera i `remoteip`; sprawdzane `success`, `hostname` (= domena środowiska) i `action` (= `lead`); niepowodzenie, w tym `timeout-or-duplicate` → `403 turnstile_failed`. Brak odpowiedzi Turnstile (awaria) → `503` z komunikatem i danymi kontaktowymi (telefon/e-mail) – bezpieczeństwo przed wygodą.
6. **Zapis**: wywołanie funkcji SQL `app_create_lead(jsonb)` kluczem serwisowym; funkcja w jednej transakcji: ponownie sprawdza idempotencję (pod blokadą), **deduplikuje** (ten sam `email_normalized` + produkt w ciągu 24 h → dopisuje zdarzenie `duplicate_submission` do istniejącego leada zamiast tworzyć nowy), **przelicza składkę po stronie serwera** z aktywnej (zatwierdzonej) wersji cennika, nadaje czytelny numer `reference` (np. `BP-2026-000123`), zapisuje `leads` (z wersjami klauzuli informacyjnej i informacji IDD), `consents` (tylko zaznaczone zgody, z `email_hmac`), `lead_events('created')` i wiersze `outbox_emails` (zespół; klient – jeśli w ciągu 24 h nie wysłano potwierdzenia na ten adres).
7. **E-mail**: w `ctx.waitUntil` pierwsza próba wysyłki przez Resend (z nagłówkiem idempotencji = id wiersza outbox); sukces → `outbox_emails.status='sent'`, porażka → `pending` z `next_attempt_at`; Worker `beautypolisa-jobs` ponawia co 5 min (backoff 5/15/60 min, maks. 6 prób), potem `failed` + alert.
8. **Zdarzenie analityczne** `lead_submitted {product, profession, individualQuote}` przez Service Binding do kolektora (bez PII).
9. Odpowiedź `201 {status:"created", reference, leadId, quote}` – **identyczna dla nowego leada i dla duplikatu** (duplikat zwraca `reference` istniejącego zgłoszenia; informacja o ponowieniu jest widoczna wyłącznie w panelu). Osobna odpowiedź `duplicate` pozwalałaby osobie trzeciej sprawdzić, czy dany adres pytał o konkretny produkt – byłaby sprzeczna z zasadą „brak enumeracji adresów” przyjętą dla newslettera. Klient pokazuje podsumowanie i numer zgłoszenia `reference`.
10. **Ponowienie po stronie klienta**: po błędzie sieci lub `503` klient wywołuje `turnstile.reset()`, pobiera nowy token i wysyła ponownie z **tym samym** `idempotencyKey` (krok 4c zwróci to samo zgłoszenie); po `429` czeka `Retry-After`.
11. Potwierdzenie dla klienta jest wysyłane **maks. raz na adres e-mail na 24 h** (ochrona przed użyciem portalu do zasypywania cudzej skrzynki). **Reguła redakcyjna szablonu `lead_client`**: wyłącznie potwierdzenie przyjęcia, numer zgłoszenia, dane dystrybutora (IDD), klauzula informacyjna i kontakt – zero treści promocyjnych i linków do innych produktów (komunikat transakcyjny, nie informacja handlowa w rozumieniu PKE). Treści marketingowe wyłącznie w szablonach wysyłanych do adresatów z aktywną zgodą `marketing_email`; test jednostkowy szablonów sprawdza obecność zakazanych fraz/linków.
12. Zespół pracuje w `/panel` (statusy `new → contacted → quoted → won/lost/spam`); każda zmiana, przekazanie do CRM/ubezpieczyciela i anonimizacja trafiają do `lead_events`.

### 2.3 Przepływ kalkulatora

Decyzja: **obliczenia w przeglądarce na podstawie migawki cennika osadzonej w HTML przez serwer, z ponownym przeliczeniem na serwerze przy wysyłce leada.**

- Strona `/kalkulator/oc` (RSC) pobiera aktywną wersję cennika (`pricing_versions.is_active` + `pricing_oc_params` + `pricing_oc_tiers`) przez warstwę cache Next.js z rewalidacją czasową 5 min i przekazuje ją jako props do wyspy klienckiej razem z `pricingVersionId`.
- Wyspa liczy natychmiast (INP ≤ 200 ms, brak żądań sieciowych przy każdej zmianie suwaka). Logika to czysta funkcja `quoteOc(input, tiers, params)` w pakiecie `packages/pricing`, ta sama na kliencie i serwerze.
- Gr. 4 lub zespół > 8 → wynik `individual: true` z listą powodów; formularz zmienia CTA na „poproś o wycenę indywidualną”.
- Przy wysyłce serwer przelicza składkę dla `pricingVersionId` z żądania; jeśli ta wersja nie jest już aktywna, liczy z aktualnej i oznacza `quote_recomputed` w `lead_events`. Wynik klienta nigdy nie jest zapisywany jako wiążący.
- **Bramka zatwierdzenia cennika**: wersję można aktywować tylko po zatwierdzeniu (ograniczenie w bazie: `is_active` wymaga `approved_by_label` i `approved_at`; `source_note` obowiązkowe). Liczby z briefu pochodzą z kodu kalkulatora `bp-app.js` (audyt §3.1), nie z potwierdzonego dokumentu ERGO Hestii, a program ma numer z 2024 r. – seed v1 dla OC ma `is_active=false` i `source_note = 'wg kodu kalkulatora bp-app.js (audyt §3.1) – DO POTWIERDZENIA z ERGO Hestia/Beauty Razem przed aktywacją'`. Do czasu aktywacji kalkulator pokazuje zakres grup ryzyka i sum bez kwot oraz CTA „poproś o wycenę” (pytanie otwarte 12).
- Wyświetlana kwota jest opatrzona adnotacją „składka orientacyjna wg cennika programu; nie stanowi oferty w rozumieniu art. 66 Kodeksu cywilnego; ostateczna oferta po ocenie wniosku” – treść do uzgodnienia z zespołem produktowym i prawnikiem.
- Tax Protect: w bazie `pricing_tax_variants` ma `annual_premium NULL` dopóki składki nie zostaną potwierdzone z Colonnade (audyt: „DO POTWIERDZENIA”) – strona pokazuje warianty sum bez kwot i formularz zapytania.

### 2.4 Kontrakty API

| Endpoint | Metoda | Wejście (Zod) | Wyjście | Kody błędów |
|----------|--------|---------------|---------|-------------|
| `/api/leads` | POST | `LeadInput` | `201 {status:"created", reference, leadId, quote}` – ta sama odpowiedź dla nowego leada, duplikatu (zwraca istniejące `reference`) i trafienia honeypota (losowe `reference`) | `400 invalid_json`, `413 payload_too_large`, `422 validation_failed`, `403 turnstile_failed`, `429 rate_limited`, `503 upstream_unavailable` |
| `/api/newsletter` | POST | `{email, legalVersions, consentTextVersion, turnstileToken, extraInfo?}` | `202 {status:"accepted"}` dla każdego poprawnego żądania, także gdy adres już istnieje lub jest wypisany (brak enumeracji adresów) | błędy walidacji/Turnstile/limitu jak w `/api/leads` (`400`, `413`, `422`, `403`, `429`) |
| `/api/newsletter/confirm` | POST | `{token}` – wysyłany przyciskiem „Potwierdzam” ze strony `/newsletter/potwierdz?token=`; samo wejście na stronę (`GET`) niczego nie zmienia, bo skanery linków w poczcie (np. Safe Links w Microsoft 365, z którego korzysta zespół i wielu odbiorców firmowych) pobierają adresy automatycznie i potwierdzałyby subskrypcję bez udziału użytkownika | `200` → widok „potwierdzono”; token jednorazowy (hash porównywany w bazie, unieważniany po użyciu) | `400 token_invalid`, `410 token_expired` |
| `/api/newsletter/unsubscribe` | POST | `{token}` = HMAC-SHA256(`subscriber.id`, `UNSUBSCRIBE_HMAC_KEY`) – liczony w locie, bez kolumny w bazie; wejście z przycisku na `/newsletter/wypisz?token=` oraz z nagłówka `List-Unsubscribe-Post: List-Unsubscribe=One-Click` (RFC 8058) | `200` → widok „wypisano”; ustawia `unsubscribed_at` | `400 token_invalid` |
| `/api/consents/withdraw` | POST | `{token}` = HMAC(`lead_id`, `purpose`) z linku w każdej wiadomości marketingowej (`/zgody/wycofaj?token=` z przyciskiem) | `200`; ustawia `consents.withdrawn_at`, zdarzenie `consent_withdrawn` z `actor='subject'` | `400 token_invalid` |
| `/api/privacy/request` | POST | `{email, kind: "access" \| "erasure", turnstileToken}` → e-mail z jednorazowym linkiem weryfikującym adres; po potwierdzeniu zdarzenie `privacy_request` i zadanie dla zespołu (realizacja ≤ 72 h [założenie]) | `202 {status:"accepted"}` zawsze (brak enumeracji) | `422`, `403`, `429` |
| `/api/claims` | POST | `ClaimInput` (produkt, nr polisy opcjonalnie, kontakt, data zdarzenia, `incidentType` z listy; **bez wolnego tekstu**) | `201 {reference}` | jak `/api/leads` |
| `/api/rum` | POST | `WebVitalInput` (`name`, `value`, `rating`, `path`, `deviceType`; bez identyfikatorów sesji/użytkownika i bez cech urządzenia), wysyłane `sendBeacon`, ≤ 2 KB | `204`; serwer dopisuje zdarzenie do Analytics Engine przez kolektor | `413`, `422`, `429` (łagodny limit w Workerze; poza regułą strefy) |
| `/api/health` | GET | – | `200 {ok:true, db:"ok"\|"degraded", version}` | `503` |
| `/api/csp-report` | POST | raport `application/reports+json` lub `application/csp-report`, ≤ 16 KB; próbkowanie: nagłówki `Reporting-Endpoints`/`report-uri` wysyłane w 10 % odpowiedzi HTML; własny łagodny limit w Workerze (poza regułą strefy i regułą `Origin`) | `204` | `413` |
| server actions w `/panel` | – | `updateLeadStatus`, `assignLead`, `addNote`, `markExported`, `updateClaimStatus`, `activatePricingVersion` – sesja Supabase użytkownika (RLS). `anonymizeLead` – **po stronie serwera kluczem serwisowym** po sprawdzeniu `app_is_staff('admin')` w sesji użytkownika i z `actor='user:<uuid>'` w `lead_events` (RLS celowo nie daje `authenticated` uprawnień do kolumn PII ani do `outbox_emails`, więc przez sesję użytkownika anonimizacja nie zadziałałaby) | – | `401`, `403` |

Format błędu jest jednolity:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "Popraw zaznaczone pola.",
    "issues": [{ "path": ["email"], "message": "Nieprawidłowy adres e-mail" }]
  },
  "requestId": "01J…"
}
```

Schemat Zod leada (wspólny dla klienta i serwera; serwer jest źródłem prawdy; plik `snippets/lead-schema.ts`):

```ts
// packages/schemas/lead.ts
import { z } from "zod";
import { isValidNip } from "./nip";

export const Product = z.enum([
  "oc-beauty", "tax-protect", "utrata-dochodu",
  "nnw-dzieci", "grupowe-ergo", "opieka-medyczna",
]);

// Slugi = adresy /dla-kogo/* z sekcji SEO. Rodzaj gramatyczny slugów (kosmetolog/linergistka)
// i ewentualne dodanie "stylistka-rzes" – do ujednolicenia wspólnie z sekcją SEO [do decyzji].
export const Profession = z.enum([
  "kosmetolog", "fryzjer", "podolog", "linergistka",
  "stylistka-paznokci", "tatuazysta", "inny",
]);

// Telefon: normalizacja (spacje, myślniki, nawiasy) → E.164; 9 cyfr bez prefiksu = +48.
// UI podpowiada +48, ale numery zagraniczne (częste w branży) są akceptowane – nie tracimy leadów
// z powodu sztywnego formatu 123 456 789.
const phone = z.string().trim()
  .transform((s) => s.replace(/[\s()-]/g, ""))
  .transform((s) => (/^\d{9}$/.test(s) ? `+48${s}` : s))
  .pipe(z.string().regex(/^\+[1-9]\d{7,14}$/, "Podaj numer z kierunkowym, np. +48 123 456 789"));

// Identyfikatory wersji treści prawnych z packages/content/legal (np. rodo-v1-2026-11)
const version = (prefix: string) =>
  z.string().regex(new RegExp(`^${prefix}-v\\d+-\\d{4}-\\d{2}$`));

export const LegalVersions = z.object({
  privacyNotice: version("rodo"),       // klauzula informacyjna art. 13 RODO
  distributorNotice: version("idd"),    // informacje o dystrybutorze (F10)
});

export const OcCalcInput = z.object({
  riskGroup: z.union([z.literal(1), z.literal(2), z.literal(3), z.literal(4)]),
  sumInsured: z.union([z.literal(100_000), z.literal(200_000), z.literal(300_000)]),
  legalProtection: z.boolean().default(false),
  teamSize: z.number().int().min(1).max(50),
});

export const LeadInput = z.object({
  idempotencyKey: z.string().uuid(),
  product: Product,
  fullName: z.string().trim().min(2).max(120),
  email: z.string().trim().toLowerCase().email().max(254),
  phone: phone.optional(),
  companyName: z.string().trim().max(200).optional(),
  nip: z.string().regex(/^\d{10}$/).refine(isValidNip, "Nieprawidłowy NIP").optional(),
  profession: Profession.optional(),
  message: z.string().trim().max(2000).optional(),
  calc: OcCalcInput.optional(),                  // wymagane tylko dla oc-beauty
  // Obowiązek informacyjny – BEZ checkboxa (klauzula pod przyciskiem wysyłki); zapisujemy
  // wersje wyświetlonych treści. Serwer odrzuca wersje inne niż aktualne w repo (422).
  legalVersions: LegalVersions,
  // Wyłącznie prawdziwe zgody (art. 6 ust. 1 lit. a RODO + art. 398 PKE), osobno per kanał,
  // domyślnie NIEzaznaczone; każda z własną wersją treści.
  consents: z.object({
    marketingEmail: z.boolean().default(false),
    marketingPhone: z.boolean().default(false),
    textVersions: z.object({
      marketingEmail: version("marketing-email").optional(),
      marketingPhone: version("marketing-phone").optional(),
    }).default({}),
  }),
  utm: z.record(z.string().max(40), z.string().max(100)).optional(),
  landingPath: z.string().startsWith("/").max(300).optional(),
  turnstileToken: z.string().min(1).max(2048),
  // Honeypot: sprawdzany na SUROWYM JSON przed parse (2.2 krok 4b). Tu tylko po to,
  // by niepusta wartość nie generowała 422 z nazwą pola pułapki.
  extraInfo: z.string().max(200).optional(),
}).superRefine((v, ctx) => {
  if (v.product === "oc-beauty" && !v.calc) {
    ctx.addIssue({ code: "custom", path: ["calc"], message: "Brak danych kalkulatora" });
  }
  if (v.consents.marketingEmail && !v.consents.textVersions.marketingEmail) {
    ctx.addIssue({ code: "custom", path: ["consents", "textVersions", "marketingEmail"], message: "Brak wersji treści zgody" });
  }
  if (v.consents.marketingPhone && !v.consents.textVersions.marketingPhone) {
    ctx.addIssue({ code: "custom", path: ["consents", "textVersions", "marketingPhone"], message: "Brak wersji treści zgody" });
  }
});
export type LeadInput = z.infer<typeof LeadInput>;

export const QuoteResult = z.discriminatedUnion("individual", [
  z.object({ individual: z.literal(false), annualPremium: z.number(), legalProtection: z.number(), pricingVersionId: z.string().uuid() }),
  z.object({ individual: z.literal(true), reasons: z.array(z.enum(["risk_group_4", "team_over_8"])) }),
]);

export const ClaimInput = z.object({
  idempotencyKey: z.string().uuid(),
  product: Product,
  policyNumber: z.string().trim().max(40).optional(),
  fullName: z.string().trim().min(2).max(120),
  email: z.string().trim().toLowerCase().email().max(254),
  phone: phone,
  incidentDate: z.string().date(),
  incidentType: z.enum(["injury_client", "property_damage", "other"]), // bez wolnego tekstu (art. 9 RODO)
  legalVersions: LegalVersions,
  turnstileToken: z.string().min(1).max(2048),
  extraInfo: z.string().max(200).optional(),
});

export const WebVitalInput = z.object({
  name: z.enum(["LCP", "INP", "CLS", "TTFB", "FCP"]),
  value: z.number().min(0).max(60_000),
  rating: z.enum(["good", "needs-improvement", "poor"]),
  path: z.string().startsWith("/").max(300),
  deviceType: z.enum(["mobile", "tablet", "desktop"]),
}); // celowo bez identyfikatora sesji/użytkownika
```

### 2.5 Magazyn treści: MDX/JSON w repozytorium zamiast CMS

Treść produktowa (6 produktów), strony `/dla-kogo/*` (6–10 zawodów) i baza wiedzy (kilka–kilkanaście artykułów na start, kilka miesięcznie [założenie]) trafiają do `packages/content` jako MDX z frontmatter oraz JSON dla danych strukturalnych (tabele sum, FAQ, listy zabiegów per grupa ryzyka). Każdy plik jest walidowany schematem Zod w CI (frontmatter: `title`, `description`, `product`, `productKind`, `insurer`, `updatedAt`, `reviewedBy`, `owuVersion`, `publicationApproved`, `brandUsageApproval: {partner, date, scope}`), a zmiana przechodzi przegląd w PR – dla treści ubezpieczeniowej (zgodność z OWU, IDD) ta ścieżka „cztery oczy” jest zaletą, nie kosztem. Build blokuje publikację pliku z `insurer != null` i `publicationApproved: false` – program OC jest zamknięty (nr WA50/003353/24/A, ankieta z logo Beauty Razem), a audyt nie znalazł publicznych źródeł o nim, więc portal będzie pierwszym publicznym opisem; użycie logotypów i warunków wymaga zgody partnerów (pytanie otwarte 14). Obrazy i PDF OWU leżą obok treści i są publikowane jako assety statyczne.

Treści prawne w `packages/content/legal/`, wersjonowane identyfikatorami zapisywanymi przy leadzie/zgodzie: `distributor.json` (dane dystrybutora – F10; `snippets/legal-distributor.json`), `consents.json` (treści zgód per kanał: `marketing-email-v1-2026-11`, `marketing-phone-v1-2026-11`, `newsletter-v1-2026-11`; `snippets/legal-consents.json`), `privacy-notice.mdx` (klauzula informacyjna `rodo-v1-2026-11`), `cookie-banner.json` (`cookie-banner-v1-2026-11`, pkt 4.12). Zmiana treści = nowa wersja, nigdy edycja w miejscu.

CMS (Payload – obecny w `aurabroker` jako `cms.*`, Sanity, Strapi) odrzucamy w v1: dodaje kolejny system do zabezpieczenia i utrzymania, kolejne konto i koszty, a tempo zmian treści nie uzasadnia edytora WYSIWYG. Granica rewizji – sekcja 9.

Dane dynamiczne (leady, zgody, zdarzenia, cenniki, subskrybenci, zgłoszenia szkód, outbox e-mail) są w Supabase.

---

## 3. Szczegóły techniczne

### 3.0 Pliki pomocnicze w `snippets/`

| Plik | Zawartość | Źródło w dokumencie |
|------|-----------|---------------------|
| `snippets/schema.sql` | DDL: typy, cenniki, leady, zgody, newsletter, role, szkody, outbox | 3.1 |
| `snippets/rls-policies.sql` | REVOKE/GRANT, polityki RLS, trigger guard, `app_is_staff` | 3.2 |
| `snippets/lead-schema.ts` | schematy Zod (`LeadInput`, `ClaimInput`, `WebVitalInput`) | 2.4 |
| `snippets/security-headers.http` | docelowy zestaw nagłówków z CSP | 4.2 |
| `snippets/ci-cd.yml` | pipeline GitHub Actions | 5.1 |
| `snippets/wrangler.jsonc` | konfiguracja Workera `beautypolisa-web` | 7.5 |
| `snippets/legal-distributor.json` | szkielet danych dystrybutora (IDD) z wartościami zastępczymi | F10, 2.5 |
| `snippets/legal-consents.json` | szkielet treści zgód per kanał z wersjami | 2.5, 4.7 |

Treść plików jest identyczna z blokami kodu poniżej; do czasu powstania repozytorium aplikacji zmiany wprowadzamy w obu miejscach.

### 3.1 Model danych (DDL, fragment kluczowy)

```sql
-- Higiena uprawnień: nowe obiekty w public NIE dostają domyślnych grantów.
-- Uwaga 1: ALTER DEFAULT PRIVILEGES bez FOR ROLE działa tylko dla obiektów tworzonych przez rolę
--          wykonującą polecenie – stąd FOR ROLE dla każdej roli, która uruchamia migracje
--          (postgres; ewentualnie osobna rola CI).
-- Uwaga 2: EXECUTE na funkcjach Postgres nadaje domyślnie roli PUBLIC (której członkami są anon
--          i authenticated), więc samo odebranie anon/authenticated nie wystarcza – inaczej każda
--          nowa funkcja (app_create_lead, anonymize_lead) byłaby wywoływalna przez anon przez RPC.
alter default privileges for role postgres in schema public revoke all     on tables    from public, anon, authenticated;
alter default privileges for role postgres in schema public revoke all     on sequences from public, anon, authenticated;
alter default privileges for role postgres in schema public revoke execute on functions from public, anon, authenticated;
-- Test w CI (packages/db/tests/privileges.test.sql): zapytanie do pg_proc.proacl, które failuje,
-- gdy jakakolwiek funkcja w public ma EXECUTE dla anon lub PUBLIC (patrz 3.2).

create type lead_product as enum
  ('oc-beauty','tax-protect','utrata-dochodu','nnw-dzieci','grupowe-ergo','opieka-medyczna');
create type lead_status as enum
  ('new','contacted','quoted','won','lost','spam','marketing_only','anonymized');
-- marketing_only: lead po retencji sprzedażowej z aktywną zgodą marketingową (4.7)

-- Wersjonowanie cenników: dokładnie jedna aktywna wersja na produkt; aktywacja wymaga zatwierdzenia
create table pricing_versions (
  id                uuid primary key default gen_random_uuid(),
  product           lead_product not null,
  label             text not null,            -- np. "OC ERGO Hestia – cennik programu"
  valid_from        date not null,
  valid_to          date,
  is_active         boolean not null default false,
  source_note       text not null,            -- skąd liczby, np. "wg kodu kalkulatora bp-app.js (audyt §3.1) – DO POTWIERDZENIA z ERGO Hestia"
  approved_by       uuid references auth.users(id) on delete set null,
  approved_by_label text,                     -- trwały ślad audytowy (e-mail/nazwisko), niezależny od auth.users
  approved_at       timestamptz,
  created_at        timestamptz not null default now(),
  check (not is_active or (approved_by_label is not null and approved_at is not null))
);
create unique index pricing_versions_one_active on pricing_versions (product) where is_active;

-- Parametry wspólne dla całej wersji cennika OC – jedno miejsce zamiast powielania w 9 wierszach tierów
create table pricing_oc_params (
  version_id             uuid primary key references pricing_versions(id) on delete cascade,
  legal_protection_addon numeric(10,2) not null default 92.00,
  max_team_size          smallint not null default 8        -- powyżej → wycena indywidualna
);

create table pricing_oc_tiers (
  id             bigint generated always as identity primary key,
  version_id     uuid not null references pricing_versions(id) on delete cascade,
  risk_group     smallint not null check (risk_group between 1 and 3), -- gr. 4 = brak wiersza, wycena indywidualna
  sum_insured    integer  not null check (sum_insured in (100000, 200000, 300000)),
  annual_premium numeric(10,2) not null check (annual_premium > 0),
  unique (version_id, risk_group, sum_insured)
);

create table pricing_tax_variants (
  id             bigint generated always as identity primary key,
  version_id     uuid not null references pricing_versions(id) on delete cascade,
  section        smallint not null check (section in (1, 2)), -- 1: karnoskarbowa, 2: podatkowa
  sum_insured    integer not null,
  annual_premium numeric(10,2),         -- NULL = składka niepotwierdzona (nie wyświetlamy kwoty)
  revenue_limit  integer,               -- np. 3 000 000; powyżej → wycena indywidualna
  unique (version_id, section, sum_insured)
);

create sequence leads_reference_seq;
create sequence claims_reference_seq;

create table leads (
  id                         uuid primary key default gen_random_uuid(),
  reference                  text not null unique,          -- czytelny numer zgłoszenia, np. BP-2026-000123 (nadawany w app_create_lead)
  idempotency_key            uuid not null unique,          -- z klienta; ponowna wysyłka = ten sam lead
  product                    lead_product not null,
  status                     lead_status  not null default 'new',
  -- PII – czyszczone przez anonymize_lead()
  full_name                  text,
  email                      text,
  email_normalized           text,                          -- lower(trim(email)); do deduplikacji
  phone                      text,                          -- E.164 po normalizacji
  company_name               text,
  nip                        text check (nip ~ '^[0-9]{10}$'),
  profession                 text,                          -- slug z /dla-kogo/<zawod>
  message                    text check (char_length(message) <= 2000),
  -- obowiązek informacyjny (art. 13 RODO) i informacje IDD: wersje wyświetlonych treści – bez checkboxa
  privacy_notice_version     text not null,                 -- np. rodo-v1-2026-11
  distributor_notice_version text not null,                 -- np. idd-v1-2026-11
  -- kontekst kalkulatora (bez PII)
  calc_input                 jsonb,                         -- {riskGroup,sumInsured,legalProtection,teamSize}
  calc_result                jsonb,                         -- wynik przeliczony NA SERWERZE
  pricing_version_id         uuid references pricing_versions(id),
  utm                        jsonb,
  landing_path               text,
  assigned_to                uuid references auth.users(id) on delete set null,
  exported_at                timestamptz,                   -- przekazanie do CRM/ubezpieczyciela; od tej daty liczy się retencja po konwersji
  anonymized_at              timestamptz,
  created_at                 timestamptz not null default now(),
  updated_at                 timestamptz not null default now()
);
create index leads_dedupe_idx on leads (email_normalized, product, created_at desc);
create index leads_status_idx on leads (status, created_at desc);

create table lead_events (
  id         bigint generated always as identity primary key,
  lead_id    uuid not null references leads(id) on delete cascade,
  type       text not null check (type in ('created','duplicate_submission','quote_recomputed',
               'email_team_sent','email_client_sent','email_failed','status_changed',
               'assigned','note_added','consent_withdrawn','exported_to_crm','forwarded_to_insurer',
               'privacy_request','anonymized')),
  payload    jsonb,                                 -- bez PII, np. {"from":"new","to":"contacted"}, {"recipient":"crm-aura","reference":"…"}
  actor      text not null default 'system',        -- 'system' | 'user:<uuid>' | 'subject' (osoba, której dane dotyczą – link samoobsługowy)
  created_at timestamptz not null default now()
);

create table newsletter_subscribers (
  id                       uuid primary key default gen_random_uuid(),
  email                    text not null,
  email_normalized         text not null unique,
  status                   text not null default 'pending' check (status in ('pending','confirmed','unsubscribed')),
  confirm_token_hash       text,                    -- sha256(token); token jednorazowy, wysyłany e-mailem
  confirm_token_expires_at timestamptz,             -- 48 h od wysłania; ponowna wysyłka nadpisuje oba pola
  confirmed_at             timestamptz,
  unsubscribed_at          timestamptz,
  source_path              text,
  created_at               timestamptz not null default now()
  -- link rezygnacji: HMAC(id, UNSUBSCRIBE_HMAC_KEY) liczony w locie – bez kolumny w bazie
);

create table consents (
  id                bigint generated always as identity primary key,
  lead_id           uuid references leads(id) on delete cascade,
  subscriber_id     uuid references newsletter_subscribers(id) on delete cascade,
  purpose           text not null check (purpose in ('marketing_email','marketing_phone','newsletter')), -- wyłącznie prawdziwe zgody
  granted           boolean not null,
  text_version      text not null,                  -- treść zgody per kanał z repo, np. marketing-email-v1-2026-11
  email_hmac        text not null,                  -- HMAC-SHA256(email_normalized, CONSENT_HMAC_KEY): „czyja” zgoda także po anonimizacji leada
  user_agent_family text check (char_length(user_agent_family) <= 64), -- np. "Chrome Mobile/Android"; bez pełnego UA
  request_id        text,                           -- korelacja z logiem serwera (bez PII)
  withdrawn_at      timestamptz,                    -- wycofanie linkiem samoobsługowym lub w panelu
  created_at        timestamptz not null default now(),
  check (lead_id is not null or subscriber_id is not null)
  -- celowo BEZ adresu IP ani jego hasha (4.1 wiersz R, 4.7)
);
create index consents_active_idx on consents (lead_id, purpose) where granted and withdrawn_at is null;

create table admin_users (
  user_id        uuid primary key references auth.users(id) on delete restrict, -- konta dezaktywujemy, nie kasujemy (ślad audytowy)
  role           text not null check (role in ('admin','agent','viewer')),
  is_active      boolean not null default true,
  deactivated_at timestamptz,
  created_by     uuid references auth.users(id) on delete set null,
  created_at     timestamptz not null default now()
);

create table claims_reports (
  id             uuid primary key default gen_random_uuid(),
  reference      text not null unique,                                   -- np. SZ-2026-000045
  idempotency_key uuid not null unique,
  product        lead_product not null,
  policy_number  text check (char_length(policy_number) <= 40),
  full_name      text, email text, phone text,
  incident_date  date,
  incident_type  text not null check (incident_type in ('injury_client','property_damage','other')),
  -- BRAK pola opisu: szczegóły zdarzenia (zwykle dane o zdrowiu klientki salonu – osoby trzeciej, art. 9 RODO)
  -- zbiera opiekun telefonicznie; instrukcja w formularzu nie jest środkiem technicznym
  privacy_notice_version text not null,
  status         text not null default 'new' check (status in ('new','forwarded','closed','anonymized')),
  forwarded_to   text,                                                   -- np. 'ergo-hestia' – odrębny administrator
  forwarded_at   timestamptz,
  closed_at      timestamptz,
  anonymized_at  timestamptz,
  created_at     timestamptz not null default now()
);

create table outbox_emails (
  id              uuid primary key default gen_random_uuid(),   -- = klucz idempotencji w Resend
  lead_id         uuid references leads(id) on delete cascade,
  template        text not null,                 -- 'lead_team' | 'lead_client' | 'newsletter_confirm' | ...
  recipient       text not null,                 -- PII; przy anonimizacji wartość zastępcza 'anonymized' (kolumna not null)
  payload         jsonb not null,                -- dane do szablonu; przy anonimizacji '{}'
  status          text not null default 'pending' check (status in ('pending','sent','failed')),
  attempts        smallint not null default 0,
  next_attempt_at timestamptz not null default now(),
  provider_id     text,
  last_error      text,
  created_at      timestamptz not null default now()
);
create index outbox_pending_idx on outbox_emails (next_attempt_at) where status = 'pending';
```

Funkcja zapisu leada `app_create_lead(jsonb)` jest `security invoker`, ma `set search_path = public`, a uprawnienia nadane jawnie (nie polegamy wyłącznie na default privileges): `revoke execute … from public, anon, authenticated; grant execute … to service_role` – może ją wywołać tylko serwer. Nadaje `reference` jako `'BP-' || to_char(now(), 'YYYY') || '-' || lpad(nextval('leads_reference_seq')::text, 6, '0')`.

`anonymize_lead(uuid, actor text)` ma te same uprawnienia i jest wywoływana z serwera: z server action po sprawdzeniu `app_is_staff('admin')` w sesji użytkownika (`actor = 'user:<uuid>'`) albo z Cron (`actor = 'system'`). Czyści PII w `leads` (`full_name`, `email`, `email_normalized`, `phone`, `company_name`, `nip`, `message` → NULL), w `consents` usuwa `user_agent_family` i `request_id`, **zachowując** `email_hmac`, `text_version`, `granted` i daty (dowód zgody, który da się powiązać z osobą po jej adresie, bez przechowywania adresu), a w `outbox_emails` wstawia wartości zastępcze (`recipient = 'anonymized'`, `payload = '{}'::jsonb` – kolumny są `not null`, więc zerowanie naruszyłoby ograniczenie), ustawia `status='anonymized'` i dopisuje zdarzenie. Funkcja **pomija** leady z aktywną zgodą marketingową (`exists (select 1 from consents where lead_id = $1 and granted and withdrawn_at is null and purpose like 'marketing_%')`) – takie rekordy przechodzą do statusu `marketing_only` (pkt 4.7).

### 3.2 Polityki RLS

Wzorzec: **`anon` nie ma żadnego dostępu do tabel z PII** (ani grantów, ani polityk); cenniki – publiczny odczyt tylko aktywnych; panel – role z `admin_users` chronione triggerem guard (odpowiednik `bp_profiles_guard` z audytu); odebrane zbędne granty, w tym `TRUNCATE`, którego RLS nie obejmuje. Uwaga: serwer czyta cenniki kluczem serwisowym (omija RLS), a przeglądarka nie ma klucza `anon` – polityki dla `anon` są zabezpieczeniem w głąb, nie ścieżką produkcyjną.

```sql
-- LEADY: zero dostępu dla anon; personel czyta i aktualizuje wybrane kolumny przez RLS
alter table leads            enable row level security;
alter table leads            force row level security;   -- także dla właściciela tabeli (uwaga w runbooku: SQL Editor jako postgres
                                                         -- zwraca wtedy 0 wierszy – to NIE jest utrata danych; serwisowo: set role service_role)
alter table lead_events      enable row level security;
alter table consents         enable row level security;
alter table claims_reports   enable row level security;
alter table outbox_emails    enable row level security;  -- bez polityk: wyłącznie service_role (lista service_role_only w teście CI)
alter table newsletter_subscribers enable row level security; -- jw.
revoke all on leads, lead_events, consents, claims_reports, outbox_emails, newsletter_subscribers
  from public, anon, authenticated;
grant select, update (status, assigned_to, exported_at, updated_at) on leads to authenticated;
grant select, insert on lead_events to authenticated;
grant select on consents to authenticated;
grant select, update (status, forwarded_to, forwarded_at, closed_at) on claims_reports to authenticated;

create policy leads_staff_select on leads
  for select to authenticated using (app_is_staff());
create policy leads_staff_update on leads
  for update to authenticated
  using (app_is_staff('admin','agent')) with check (app_is_staff('admin','agent'));
create policy lead_events_staff_select on lead_events
  for select to authenticated using (app_is_staff());
create policy lead_events_staff_insert on lead_events
  for insert to authenticated
  with check (app_is_staff('admin','agent') and actor = 'user:' || auth.uid()::text);
create policy consents_staff_select on consents
  for select to authenticated using (app_is_staff());
create policy claims_staff_select on claims_reports
  for select to authenticated using (app_is_staff());
create policy claims_staff_update on claims_reports
  for update to authenticated
  using (app_is_staff('admin','agent')) with check (app_is_staff('admin','agent'));
-- brak polityk INSERT/DELETE na leads dla authenticated → zapis wyłącznie service_role (serwer)

-- CENNIKI: publiczny odczyt tylko aktywnej wersji; zapis wyłącznie admin.
-- Polityki ROZDZIELONE per rola: polityka dla anon nie może wywoływać app_is_staff() – Postgres sprawdza
-- uprawnienie EXECUTE przy inicjalizacji wyrażenia, niezależnie od skrótu `is_active OR …`, więc odczyt
-- jako anon kończyłby się błędem "permission denied for function app_is_staff".
alter table pricing_versions     enable row level security;
alter table pricing_oc_params    enable row level security;
alter table pricing_oc_tiers     enable row level security;
alter table pricing_tax_variants enable row level security;
revoke all on pricing_versions, pricing_oc_params, pricing_oc_tiers, pricing_tax_variants
  from public, anon, authenticated;
grant select on pricing_versions, pricing_oc_params, pricing_oc_tiers, pricing_tax_variants to anon, authenticated;
grant insert, update on pricing_versions, pricing_oc_params, pricing_oc_tiers, pricing_tax_variants to authenticated;

create policy pricing_versions_anon_read on pricing_versions
  for select to anon using (is_active);
create policy pricing_versions_staff_read on pricing_versions
  for select to authenticated using (is_active or app_is_staff());

create policy pricing_oc_params_anon_read on pricing_oc_params
  for select to anon
  using (exists (select 1 from pricing_versions v where v.id = version_id and v.is_active));
create policy pricing_oc_params_staff_read on pricing_oc_params
  for select to authenticated
  using (exists (select 1 from pricing_versions v where v.id = version_id and (v.is_active or app_is_staff())));

create policy pricing_oc_anon_read on pricing_oc_tiers
  for select to anon
  using (exists (select 1 from pricing_versions v where v.id = version_id and v.is_active));
create policy pricing_oc_staff_read on pricing_oc_tiers
  for select to authenticated
  using (exists (select 1 from pricing_versions v where v.id = version_id and (v.is_active or app_is_staff())));

create policy pricing_tax_anon_read on pricing_tax_variants           -- bez tej polityki RLS zwracałby 0 wierszy (jak tax_wnioski w audycie)
  for select to anon
  using (exists (select 1 from pricing_versions v where v.id = version_id and v.is_active));
create policy pricing_tax_staff_read on pricing_tax_variants
  for select to authenticated
  using (exists (select 1 from pricing_versions v where v.id = version_id and (v.is_active or app_is_staff())));

create policy pricing_versions_admin_write on pricing_versions
  for all to authenticated using (app_is_staff('admin')) with check (app_is_staff('admin'));
create policy pricing_oc_params_admin_write on pricing_oc_params
  for all to authenticated using (app_is_staff('admin')) with check (app_is_staff('admin'));
create policy pricing_oc_admin_write on pricing_oc_tiers
  for all to authenticated using (app_is_staff('admin')) with check (app_is_staff('admin'));
create policy pricing_tax_admin_write on pricing_tax_variants
  for all to authenticated using (app_is_staff('admin')) with check (app_is_staff('admin'));

-- ROLE PANELU: odczyt własnego wiersza; każda zmiana tylko z backendu (trigger guard)
alter table admin_users enable row level security;
revoke all on admin_users from public, anon, authenticated;
grant select on admin_users to authenticated;
create policy admin_users_self_read on admin_users
  for select to authenticated using (user_id = auth.uid());

create or replace function admin_users_guard() returns trigger
language plpgsql as $$                                      -- security INVOKER: current_user = rola wywołująca
begin
  if current_user not in ('service_role', 'postgres', 'supabase_admin') then
    raise exception 'admin_users: zmiana ról możliwa wyłącznie z backendu';
  end if;
  return coalesce(new, old);
end $$;
create trigger admin_users_guard
  before insert or update or delete on admin_users
  for each row execute function admin_users_guard();

-- Pomocnicza funkcja ról: SECURITY DEFINER z zamrożonym search_path, wykonywalna tylko przez authenticated.
-- Wymaga sesji po drugim składniku (aal2): wymóg MFA jest egzekwowany w RLS, nie tylko deklarowany –
-- sesja po samym haśle (przed TOTP) nie widzi leadów.
create or replace function app_is_staff(variadic roles text[] default array['admin','agent','viewer'])
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(auth.jwt()->>'aal', 'aal1') = 'aal2'
     and exists (
       select 1 from admin_users a
       where a.user_id = auth.uid() and a.is_active and a.role = any (roles)
     );
$$;
revoke execute on function app_is_staff(text[]) from public, anon;
grant  execute on function app_is_staff(text[]) to authenticated;

-- Funkcje zapisu – uprawnienia jawne
revoke execute on function app_create_lead(jsonb)     from public, anon, authenticated;
revoke execute on function anonymize_lead(uuid, text) from public, anon, authenticated;
grant  execute on function app_create_lead(jsonb), anonymize_lead(uuid, text) to service_role;
```

Dodatkowo w nowym projekcie: brak funkcji `SECURITY DEFINER` wykonywalnych przez `anon` (w audycie: 21 w „aurabroker”, 17 w „BEAUTY”), rozszerzenia w schemacie `extensions`, włączona ochrona przed wyciekłymi hasłami, MFA (TOTP) wymagane dla wszystkich ról panelu i egzekwowane w `app_is_staff` (`aal2`), przegląd Security Advisor po każdej migracji i raz w miesiącu (pkt 1.4). Lista ról zaufanych w triggerze guard – do potwierdzenia z aktualnymi domyślnymi rolami Supabase. **Testy uprawnień w CI** (na lokalnej bazie z migracjami): (1) żadna funkcja w `public` nie ma `EXECUTE` dla `anon` ani `PUBLIC` (`pg_proc.proacl`); (2) każda tabela z włączonym RLS ma ≥ 1 politykę albo jest na jawnej liście `service_role_only` (`outbox_emails`, `newsletter_subscribers`); (3) `select` jako `anon` z `pricing_oc_tiers` zwraca wiersze aktywnej wersji i zero z nieaktywnej; (4) `anon` nie ma żadnego grantu na tabelach z PII.

### 3.3 Strategia cache

Worker na własnej domenie jest **originem** – żądania nie przechodzą przez cache strefy „przed” Workerem, więc Cache Rules dla ścieżek obsługiwanych przez aplikację nie mają efektu (działają tylko dla `fetch()` do zewnętrznych originów). Buforowaniem sterują nagłówki z aplikacji i automatyczne cache Workers Static Assets.

| Zasób | Nagłówki z aplikacji | Warstwa Cloudflare | Uwagi |
|-------|----------------------|--------------------|-------|
| `/_next/static/*`, fonty, obrazy w repo | `Cache-Control: public, max-age=31536000, immutable` (plik `_headers` dla Static Assets) | automatyczne cache Static Assets w sieci CF | nazwy z hashem treści |
| `/dokumenty/*.pdf` (OWU) | `public, max-age=86400`, `Content-Disposition: inline` | jw. | nazwa pliku z datą/wersją OWU |
| HTML stron publicznych | `private, no-cache` | **nie buforowane na brzegu** (nonce per odpowiedź) | dane pod spodem z cache Next.js (KV) – TTFB bez zapytań do bazy |
| Dane: cennik, lista artykułów | cache Next.js (`"use cache"` / `unstable_cache` zależnie od wersji) z rewalidacją 300 s | – | aktywacja nowej wersji cennika widoczna ≤ 5 min; brak infrastruktury tag cache |
| `/sitemap.xml`, `/robots.txt`, `/llms.txt` | `public, max-age=3600` | – (Worker) | treść w sekcji SEO/GEO |
| `/api/*`, `/panel/*`, odpowiedzi z `Set-Cookie`, Turnstile | `no-store` ustawiane w route handlerach | – (Worker; brak reguły „Bypass”, bo nie ma czego omijać) | **nigdy** w cache |
| Obrazy transformowane (`/cdn-cgi/image/*`) | – | zarządzane przez CF | warianty AVIF/WebP per szerokość |

Dlaczego HTML renderowany per żądanie, a nie statyczny: ścisła CSP z nonce wymaga unikalnego nonce w każdej odpowiedzi; statyczny eksport zmusiłby do `'unsafe-inline'` w `script-src` (Next.js osadza w HTML ładunek RSC/hydracji) albo do kruchych hashy. Na Workers Paid rendering pełnego drzewa RSC ze streamingiem kosztuje zwykle kilkanaście–kilkadziesiąt ms CPU [hipoteza – zmierzyć w PoC], a dane są w cache, więc TTFB ≤ 500 ms (p75) pozostaje realny bez cache HTML; na planie Free (10 ms CPU) nie byłby. Uwaga wdrożeniowa: adapter OpenNext na Workers wymaga middleware w runtime edge (middleware/proxy w runtime Node nie jest wspierane) – generowanie nonce musi być tam zaprojektowane; w `vinext` mechanizm do sprawdzenia w PoC [do weryfikacji na starcie implementacji].

### 3.4 Kolejki i zdarzenia – nie w v1

Cloudflare Queues wymagają planu Workers Paid i dokładają kolejny komponent do obsługi (DLQ, konsument, monitoring). Przy wolumenie leadów liczonym w sztukach–dziesiątkach dziennie [założenie] wystarcza **wzorzec outbox**: wiersze `outbox_emails` zapisywane w tej samej transakcji co lead, pierwsza próba wysyłki natychmiast (`ctx.waitUntil`), ponowienia z Cron Trigger w `beautypolisa-jobs`. Daje to te same gwarancje (co najmniej raz, z idempotencją po stronie Resend) bez kolejki. Jeśli outbox rośnie – alert (sekcja 5.4).

### 3.5 Obsługa błędów, retry, idempotencja, deduplikacja

- **Idempotencja leada**: `idempotency_key` unikalny; ponowna wysyłka (np. po utracie sieci) zwraca ten sam `reference`/`leadId`. Klucz żyje do odświeżenia strony. Ponieważ token Turnstile jest jednorazowy, serwer sprawdza istnienie klucza **przed** `siteverify` (2.2 krok 4c), a klient przy ponowieniu resetuje widget i wysyła nowy token z tym samym kluczem (krok 10).
- **Deduplikacja**: ten sam `email_normalized` + produkt w 24 h → zdarzenie zamiast nowego leada; odpowiedź dla klienta identyczna jak dla nowego zgłoszenia; panel pokazuje licznik ponowień.
- **E-mail**: identyfikator wiersza outbox jako klucz idempotencji w Resend [do weryfikacji wsparcia w API Resend]; backoff wykładniczy; po 6 próbach `failed` i alert; zespół ma zawsze leady w panelu, więc awaria poczty nie gubi danych.
- **Supabase niedostępny**: `/api/leads` zwraca `503` z komunikatem i kontaktem awaryjnym (telefon/e-mail Aura); brak buforowania w KV (unikamy drugiego miejsca przechowywania PII); alert natychmiast.
- **Turnstile niedostępny**: `503`, jak wyżej. Świadomy wybór bezpieczeństwa nad konwersją.
- Błędy aplikacji → Sentry bez PII; każda odpowiedź ma `requestId` zwracany klientowi i logowany.

---

## 4. Bezpieczeństwo (priorytet nr 1)

### 4.1 Model zagrożeń (STRIDE, lekki)

| Kategoria | Zagrożenie | Środki |
|-----------|-----------|--------|
| **S**poofing | Boty wysyłające leady; podszycie pod zespół (phishing w e-mailach z portalu); przejęcie konta panelu | Turnstile (z weryfikacją `hostname`/`action`), honeypot, rate limit; DKIM/SPF/DMARC dla domeny wysyłkowej (Resend już ma DKIM); Supabase Auth + MFA egzekwowane w RLS (`aal2`) + Cloudflare Access (SSO Microsoft 365 Aura lub kod jednorazowy) |
| **T**ampering | Manipulacja składką/grupą ryzyka w żądaniu; podmiana treści (supply chain npm); aktywacja niezatwierdzonego cennika | Przeliczenie na serwerze z wersjonowanego cennika; bramka zatwierdzenia w bazie; lockfile, pinowane akcje CI, SRI nie dotyczy (brak CDN), CSP |
| **R**epudiation | Spór o udzieloną zgodę marketingową | `consents` z wersją treści per kanał, znacznikiem czasu, `email_hmac` (powiązanie z osobą po adresie bez przechowywania go po anonimizacji), rodziną przeglądarki i `request_id`; dla newslettera double opt-in; `lead_events` jako ślad audytowy. **Świadomie bez adresu IP ani jego hasha**: hash z solą jest albo niemożliwy do zweryfikowania (sól usunięta – nie dowodzi niczego), albo odtwarzalny w sekundy (mała przestrzeń IPv4 – nadal dane osobowe); w obu wariantach nie pełni funkcji dowodu, a generuje obowiązki |
| **I**nformation disclosure | Wyciek leadów przez klucz anon (jak w „aurabroker”), przez logi, błędy, bundle panelu; enumeracja adresów newslettera; ujawnienie faktu zapytania o produkt przez odpowiedź „duplikat” | Brak klucza Supabase w przeglądarce; RLS + REVOKE; logi bez PII; strony błędów bez szczegółów; panel renderowany serwerowo pod ochroną Access; `202` zawsze dla newslettera; identyczna odpowiedź dla nowego leada i duplikatu |
| **D**enial of service | Spam leadów, zasypywanie cudzych skrzynek potwierdzeniami, koszty Workers/Resend; wywołania `siteverify` wymuszane przez atakującego | Rate limit CF + binding **przed** `siteverify`; limit potwierdzeń per e-mail/24 h; limity rozmiaru ciała; alert kosztowy Cloudflare |
| **E**levation of privilege | Nadanie sobie roli admina; funkcje `SECURITY DEFINER` dla `anon`; domyślne `EXECUTE` dla `PUBLIC`; mutowalny `search_path`; sesja bez MFA | Trigger guard na `admin_users`; brak funkcji dla `anon`/`PUBLIC` (default privileges + test w CI); `set search_path`; `force row level security`; `aal2` w `app_is_staff`; Security Advisor po każdej migracji |

### 4.2 Nagłówki bezpieczeństwa

Ustawiane w aplikacji (middleware), żeby były wersjonowane razem z kodem; HSTS dodatkowo na poziomie strefy Cloudflare. Plik `snippets/security-headers.http`.

```http
Content-Security-Policy:
  default-src 'self';
  script-src 'self' 'nonce-{NONCE}' 'strict-dynamic' https://challenges.cloudflare.com;
  style-src 'self' 'nonce-{NONCE}';
  img-src 'self' data: blob:;
  font-src 'self';
  connect-src 'self' https://challenges.cloudflare.com;
  frame-src https://challenges.cloudflare.com;
  frame-ancestors 'none';
  form-action 'self';
  base-uri 'self';
  object-src 'none';
  upgrade-insecure-requests;
  report-uri /api/csp-report;
  report-to csp-endpoint
Reporting-Endpoints: csp-endpoint="/api/csp-report"
# HSTS: wartość DOCELOWA po etapach z 4.3; start: max-age=86400 bez includeSubDomains i preload
Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=(), payment=(), usb=(), browsing-topics=()
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Resource-Policy: same-site
X-Frame-Options: DENY
```

Uwagi:

- **Turnstile a `'strict-dynamic'`**: przeglądarki zgodne z CSP3 przy `'strict-dynamic'` ignorują źródła hostowe i `'self'` w `script-src` – wpis `https://challenges.cloudflare.com` jest tylko fallbackiem dla starszych przeglądarek. Skrypt Turnstile musi być renderowany przez `next/script` **z nonce** (albo wstrzykiwany przez skrypt z nonce); `frame-src` i `connect-src` dla `challenges.cloudflare.com` pozostają wymagane.
- `report-uri` i `report-to` współistnieją celowo: Firefox nie wspiera Reporting API dla CSP, więc sama dyrektywa `report-to` nie zebrałaby danych z Firefoksa w fazie Report-Only; przeglądarki ignorują dyrektywy, których nie znają.
- `browsing-topics=()` zastępuje martwą dyrektywę `interest-cohort=()` (FLoC wycofany w 2022 r.; generowała tylko ostrzeżenia w konsoli).
- `Cross-Origin-Resource-Policy: same-site` (nie `same-origin`), żeby subdomeny Aura (`app.`, `crm.`) mogły osadzać logo/obrazy portalu; `same-origin` blokowałoby to bez uzasadnienia.
- Zaraz (tagi po zgodzie) ładuje się z tej samej domeny (`/cdn-cgi/zaraz/`) – jego skrypty inline muszą dostać nonce (ustawienie Zaraz) [do weryfikacji]. Jeśli jakaś biblioteka UI wymusi atrybuty `style` w HTML, dopuszczalnym kompromisem jest `style-src 'self' 'unsafe-inline'` (ryzyko istotnie mniejsze niż dla skryptów); dla `script-src` kompromisu nie ma.
- Sentry jest w v1 wyłącznie serwerowe; gdyby kiedyś włączono SDK przeglądarkowe, raporty kierować przez tunel (`/api/monitoring`) zamiast rozszerzać `connect-src`.
- Polityka startuje jako `Content-Security-Policy-Report-Only` na stagingu przez tydzień, potem egzekwowana.

### 4.3 Ustawienia Cloudflare do zmiany względem audytu

| Ustawienie | Stan z audytu | Docelowo | Plan |
|-----------|---------------|----------|------|
| SSL/TLS mode | Full | **Full (strict)** – wszystkie originy to Cloudflare (Workers/Pages), więc bez ryzyka | Free |
| Minimalna wersja TLS | **1.0** | **1.2** (1.3 pozostaje włączone) | Free |
| HSTS | wyłączony | etapami: `max-age=86400` → 6 mies. → 2 lata + `includeSubDomains` + `preload` dopiero po potwierdzeniu, że **każda** subdomena serwuje poprawny HTTPS: `app.`, `crm.`, `portal.`, `tax.`, `ergo.`, `konsultacja.`, `staging.`, `www`, `autodiscover` oraz rekordy do usług zewnętrznych `send.` i `links.` (Resend). `links.` to domena śledzenia kliknięć w e-mailach – jeśli Resend generuje linki `http://` lub host nie ma ważnego certyfikatu, wpis na listę preload (w praktyce nieodwracalny) zepsułby wszystkie linki w wiadomościach do klientów. Kontrola: `curl -I https://links.beautypolisa.eu` i podgląd linków w wiadomości testowej; w razie problemu – HSTS bez `includeSubDomains` na apexie i HSTS per subdomena | Free |
| Always HTTPS, HTTP/3, Brotli | włączone | bez zmian | Free |
| Early Hints | wyłączone | **włączone** (aplikacja wysyła `Link: rel=preload` dla CSS i fontów) | Free |
| 0-RTT | wyłączone | pozostaje wyłączone (ryzyko replay dla POST) | – |
| Security level | medium | medium; dodatkowo reguła WAF własna (faza `http_request_firewall_custom`, przed rate limitem i regułami zarządzanymi): managed challenge dla `http.request.method eq "POST" and http.request.uri.path in {"/api/leads" "/api/newsletter" "/api/newsletter/confirm" "/api/newsletter/unsubscribe" "/api/consents/withdraw" "/api/privacy/request" "/api/claims"} and http.request.headers["origin"][0] ne "https://beautypolisa.eu"`. `/api/csp-report` i `/api/rum` **poza regułą** – raporty wysyłane przez przeglądarkę (Reporting API, `sendBeacon`) nie niosą `Origin` strony w każdej przeglądarce i nie potrafią rozwiązać challenge; objęcie ich regułą po cichu wyłączyłoby fazę Report-Only | Free |
| WAF managed rules | Free Managed Ruleset | bez zmian; pełny zestaw dopiero na Pro (sekcja 1.3) | Free → Pro |
| Rate limiting | brak | **1 reguła** na te same ścieżki co wyżej (`POST`, lista endpointów formularzy; bez `/api/csp-report` i `/api/rum`): > 10 żądań/10 s z IP → managed challenge. Dla raportów CSP i RUM – łagodny limit w Workerze i próbkowanie (2.4); wspólny licznik z raportami CSP blokowałby realne formularze z tego samego NAT (salon, galeria handlowa) | Free |
| Cache TTL / reguły | 4 h, brak page rules | bez Cache Rules dla ścieżek obsługiwanych przez Worker (Worker jest originem – pkt 3.3); buforowaniem sterują nagłówki z aplikacji i cache Static Assets | Free |
| Turnstile | brak | widget „managed” na każdym formularzu; osobne klucze dla stagingu i produkcji, klucz publiczny przekazywany **w runtime** z `vars` Workera (nie przez `NEXT_PUBLIC_*` – pkt 4.5) | Free |
| Bot management / AI crawlers | `ai_bots_protection: block`, `ai_search` wyłączone | zgodnie z sekcją SEO/GEO: dopuścić kategorie *AI search* i *AI user/agent*, utrzymać blokadę *training* | Free |
| Trasa `beautypolisa.eu/*` → `aura-analytics-collector` | aktywna | **usunięta**; kolektor wywoływany przez Service Binding (sekcja 7) | – |
| Worker `security-headers` | bez trasy | pozostaje bez trasy w tej strefie – nagłówki ustawia aplikacja | – |
| Cloudflare Access | brak | aplikacja Access dla `beautypolisa.eu/panel*` i `staging.beautypolisa.eu/*`; Service Token dla testów CI (5.1) | Free |
| DNS apex / www | **brak rekordów** | apex → custom domain Workera; `www` → 301 na apex (Redirect Rule) | Free |

### 4.4 Ochrona formularzy

Pięć niezależnych warstw, każda tania, uruchamiane **od najtańszej do najdroższej** (2.2 krok 4–5): honeypot (odsiewa proste boty bez kosztu challenge; sprawdzany na surowym JSON), rate limit Cloudflare (ochrona Workera i kosztów), rate limit w Workerze (per IP + produkt, drobniejszy), walidacja Zod po stronie serwera (jedyna wiążąca; walidacja w kliencie służy tylko UX), Turnstile (dowód „nie-bot”; jedyne wywołanie zewnętrzne – dopiero po tanich warstwach, żeby atakujący nie wymuszał jednego `siteverify` na każde żądanie). Do tego limity rozmiaru ciała, `Origin`/`Sec-Fetch-Site` sprawdzane w route handlerze, a dla server actions w panelu – wbudowana ochrona CSRF Next.js plus sesja Supabase w ciasteczku `HttpOnly; Secure; SameSite=Lax`.

### 4.5 Zarządzanie sekretami i zmiennymi środowiskowymi

- Sekrety Workera (`SUPABASE_SECRET_KEY`, `TURNSTILE_SECRET_KEY`, `RESEND_API_KEY`, `SENTRY_DSN`, `CONSENT_HMAC_KEY`, `UNSUBSCRIBE_HMAC_KEY`) wyłącznie przez `wrangler secret put --env <env>` (osobno dla `staging` i `production`); lokalnie `.dev.vars` w `.gitignore`.
- **Klucze Supabase**: nowy projekt korzysta z nowego systemu kluczy API (`sb_publishable_…`/`sb_secret_…`), klucze legacy JWT `anon`/`service_role` są w projekcie wyłączone; sekret `SUPABASE_SECRET_KEY` = klucz `sb_secret_…`, rotowalny bez przerwy w działaniu (dwa klucze równolegle) – rotacja legacy `service_role` oznaczałaby rotację sekretu JWT całego projektu [do weryfikacji – stan systemu kluczy na dzień założenia projektu].
- **Zmienne publiczne per środowisko (`SITE_URL`, `TURNSTILE_SITE_KEY`) są czytane w runtime** z `env` Workera (`getCloudflareContext().env`) w RSC i przekazywane do komponentów jako props. Celowo **bez prefiksu `NEXT_PUBLIC_`**: takie zmienne są wklejane do bundla w czasie `next build`, a CI robi jeden build dla obu środowisk (5.1) – `NEXT_PUBLIC_TURNSTILE_SITE_KEY` w `vars` wranglera nie zmieniłby niczego w kodzie przeglądarki i oba środowiska dostałyby ten sam (lub pusty) klucz.
- **Brak sekretów w repozytorium** – `gitleaks` w CI, włączone GitHub secret scanning z push protection.
- Klucz serwisowy Supabase istnieje tylko w Workerach `beautypolisa-web` i `beautypolisa-jobs`. Do przeglądarki nie trafia żaden klucz Supabase (także publishable/anon) – aplikacja nie ma klienta Supabase po stronie przeglądarki; panel używa sesji serwerowej.
- Osobny klucz API Resend tylko do wysyłki z domeny portalu; osobne klucze Turnstile per środowisko.
- Rotacja: co 6 miesięcy i natychmiast po incydencie lub odejściu osoby z dostępem; procedura w runbooku.
- Wdrożenie do środowiska GitHub `production` wymaga akceptacji drugiej osoby – może to być **właściciel biznesowy** (recenzent środowiska), nie musi druga osoba techniczna (pkt 1.4).

### 4.6 Polityka zależności

- `pnpm install --frozen-lockfile` w CI.
- Minimalny wiek publikacji pakietu (np. 7 dni, `minimumReleaseAge`) przed instalacją nowej wersji – ochrona przed skompromitowanymi wydaniami.
- Renovate: tygodniowe, grupowane PR; automatyczne scalanie tylko dla patchy po zielonym CI (w v1 – ręczne scalanie, pkt 1.4).
- `pnpm audit --audit-level=high` blokuje PR.
- Akcje GitHub przypięte do SHA.
- Zero skryptów z CDN: Chart.js i confetti z obecnych stron znikają – wykresy w panelu z lekkiej biblioteki w bundle panelu, bez konfetti.

### 4.7 Minimalizacja i retencja PII (RODO)

| Dane | Podstawa prawna [do potwierdzenia z IOD] | Retencja [założenie] | Mechanizm / rozstrzygnięcie konfliktów |
|------|------------------------------------------|----------------------|----------------------------------------|
| Lead (kontakt + kontekst produktu) | art. 6 ust. 1 lit. b – działania przed zawarciem umowy na żądanie osoby. **Bez zgody** i bez checkboxa: obowiązek informacyjny z art. 13 realizuje klauzula wyświetlona w formularzu, jej wersja w `leads.privacy_notice_version` (wymuszona „zgoda na przetwarzanie” byłaby fikcyjna – niedobrowolna – i wprowadzałaby w błąd co do podstawy) | 12 mies. od ostatniego zdarzenia, jeśli brak konwersji; po oznaczeniu `won`/`lost` – 90 dni od `exported_at` (przekazanie do CRM Aura/ubezpieczyciela) albo od zmiany statusu, gdy przekazania nie ma [zależne od odpowiedzi na pytanie 5], potem anonimizacja w portalu | `anonymize_lead()` z Cron (codziennie). **Konflikt ze zgodą marketingową**: lead z aktywną zgodą nie jest anonimizowany – przechodzi do statusu `marketing_only`, zachowuje tylko `email`/`phone` (zależnie od kanału) i wiersze `consents`; anonimizacja po wycofaniu zgody lub po 24 mies. bez interakcji [założenie, do ustalenia z IOD] |
| Zgody marketingowe (osobno e-mail/SMS i telefon) | art. 6 ust. 1 lit. a RODO **oraz** art. 398 Prawa komunikacji elektronicznej (zgoda na kanał: informacja handlowa e-mail/SMS i marketing telefoniczny – osobne zgody, osobne treści) [stan prawny na 11.2026 – do potwierdzenia z prawnikiem, w tym status art. 10 u.ś.u.d.e.] | do wycofania + 3 lata jako dowód (wiersz z `withdrawn_at`, `text_version`, `email_hmac`) | wpis w `consents` per kanał; wycofanie równie łatwe jak udzielenie: link `/zgody/wycofaj` w każdej wiadomości, `List-Unsubscribe`; dowód bez PII w jawnej postaci po anonimizacji (HMAC adresu) |
| Newsletter | art. 6 ust. 1 lit. a, double opt-in | do wypisania; niepotwierdzone usuwane po 7 dniach | Cron; potwierdzenie przez `POST` z przycisku (nie `GET`), rezygnacja one-click |
| Zgłoszenie szkody | art. 6 ust. 1 lit. b/f – obsługa szkody na rzecz klienta; przekazanie do ubezpieczyciela jako **odrębnego administratora** (zdarzenie `forwarded_to_insurer`) [do potwierdzenia z IOD] | 12 mies. po `closed` [założenie; spory OC trwają latami, ale portal nie prowadzi likwidacji – dokumentacja sprawy jest u ubezpieczyciela i w CRM] | `anonymize`; formularz **bez wolnego tekstu** (art. 9 – dane o zdrowiu osób trzecich); informacja z art. 14 wobec osoby trzeciej leży po stronie ubezpieczyciela/CRM |
| Logi bezpieczeństwa (bez IP, bez PII) | art. 6 ust. 1 lit. f | 30 dni (Workers Logs) / 90 dni (Sentry) | brak adresu IP w bazie – Cloudflare ma własne logi WAF/rate limit na potrzeby ochrony |
| Web Vitals (`/api/rum`) | poza zakresem danych osobowych [hipoteza prawna – 5.4] | 90 dni w Analytics Engine | bez identyfikatorów; sampling |

Prawo dostępu i usunięcia: samoobsługowo przez `POST /api/privacy/request` (weryfikacja adresu jednorazowym linkiem, zdarzenie `privacy_request`) oraz w panelu – akcja `anonymizeLead` (zapis w `lead_events`), wyszukanie po adresie przez `email_normalized` lub `email_hmac`; realizacja ≤ 72 h [założenie]. Odbiorcy danych (CRM Aura, ubezpieczyciele) są wymienieni w `/rodo`, a każde przekazanie ma zdarzenie `exported_to_crm`/`forwarded_to_insurer` z `payload.recipient` – dzięki temu odpowiedź na wniosek z art. 15 o odbiorców jest możliwa. Administrator danych do wskazania (Aura Consulting vs Aura Expert – w audycie różne podmioty w różnych produktach); polityka prywatności w `/rodo`.

Podmioty przetwarzające i lokalizacja danych:

| Procesor | Rola | Lokalizacja danych | Wymagane |
|----------|------|--------------------|----------|
| Supabase | baza, Auth panelu | region `eu-west-1` (Irlandia) | DPA Supabase |
| Cloudflare | Workers, KV (cache bez PII), Analytics Engine, logi WAF | przetwarzanie globalne – regionalizacja (Data Localization Suite) dostępna tylko w planie Enterprise; świadomie akceptowany transfer metadanych żądań | DPA Cloudflare + standardowe klauzule umowne; wpis w rejestrze czynności i w `/rodo` jako odbiorca/transfer |
| Resend | e-mail transakcyjny (PII w `outbox_emails.payload` i w treści wiadomości) | domena wysyłkowa skonfigurowana w regionie EU (`eu-west-1`) [do weryfikacji w konfiguracji istniejącej domeny `send.`] | DPA Resend; bez regionu EU – transfer do USA (SCC/DPF) |
| Sentry | błędy bez PII | organizacja w regionie EU (`de.sentry.io`), `sendDefaultPii: false` | DPA Sentry |
| Monitor uptime (Better Stack/UptimeRobot [założenie]) | dostępność | brak PII | – |

### 4.8 Logowanie bez PII

Logi strukturalne JSON: `{requestId, route, status, durationMs, product, outcome, leadId}` – **nigdy** e-mail, telefon, treść wiadomości, ciało żądania ani adres IP (także skrócony). Sentry: `sendDefaultPii: false`, `beforeSend` usuwa ciało żądania, nagłówki `cookie`/`authorization` i pola formularzy; maskowanie w Session Replay (jeśli włączony – domyślnie wyłączony). Logi Workers (observability): `head_sampling_rate: 1` – próbkowanie w Workers Logs jest decydowane na początku żądania, zanim znany jest status, więc nie da się nim zapewnić „100 % błędów, 10 % sukcesów”; przy wolumenie portalu 100 % jest tanie, a wolumen ograniczamy, logując odsłony stron na poziomie `debug` (odfiltrowanym), a `/api/*` na `info`.

### 4.9 Kopie zapasowe i odtwarzanie

Supabase Pro: kopie dzienne (retencja wg planu [do weryfikacji]); PITR jako dodatek (koszt wg pkt 1.3) **nie** w v1 – leady mają drugą kopię w skrzynce zespołu, a cenniki i treść są w repo (odtwarzalne z migracji i seedów). Jeden test odtworzenia kopii do projektu tymczasowego przed startem (RTO ≤ 4 h), potem co kwartał (pkt 1.4). Migracje wyłącznie przez pliki w `supabase/migrations` – zmiany w dashboardzie są zabronione na produkcji.

### 4.10 Procedura reagowania na incydent (skrót)

1. **Wykrycie** (alert Sentry/uptime/koszty/Advisor) → potwierdzenie w ≤ 2 h w godzinach pracy (pn–pt 9–17), poza nimi następny dzień roboczy [założenie do akceptacji – pkt 1.4]; strona błędu formularza zawsze pokazuje kontakt awaryjny.
2. **Zatrzymanie**: w zależności od typu – `wrangler rollback` do poprzedniej wersji; reguła WAF „challenge all” na `/api/*`; rotacja klucza `sb_secret_…` i Resend; wyłączenie formularza flagą środowiskową (strona pokazuje kontakt awaryjny).
3. **Ocena wycieku PII**: zakres (tabele, okres), liczba osób – zapytania na kopii; decyzja IOD o zgłoszeniu do UODO w 72 h.
4. **Naprawa i weryfikacja** na stagingu, wdrożenie (w v1: 100 % z rollbackiem; docelowo kanarkowe).
5. **Post-mortem** w repo (`docs/incydenty/`) bez PII, z działaniami naprawczymi i terminami.

### 4.11 Słabości obecnej architektury (z audytu) i jak nowa je usuwa

| Słabość z `01-audyt-stanu-obecnego.md` | Nowa architektura |
|------------------------------------------|-------------------|
| Publiczny portal na kluczu anon współdzielonej bazy „aurabroker” (158 tabel, CRM) | Nowy projekt Supabase tylko dla portalu; klucz anon nieużywany w przeglądarce; zasięg skutków ewentualnego incydentu ograniczony do danych portalu |
| Skrypt anti-inspect czyszczący `document.body` | Usunięty; bezpieczeństwo zapewniają serwer, RLS i CSP, nie ukrywanie kodu |
| Panel admina w publicznym bundle, autoryzacja z `bp_profiles.is_admin` w kliencie | Panel pod `/panel` renderowany serwerowo, kod ładowany tylko dla tych tras, autoryzacja w RLS (z wymogiem MFA) + triggerze guard, przed tym Cloudflare Access |
| `bp_analytics`: INSERT z klienta bez limitów | Zdarzenia biznesowe emitowane z serwera przez Service Binding, bez PII; z przeglądarki wyłącznie Web Vitals przez `/api/rum` (bez identyfikatorów, z walidacją, limitem rozmiaru i częstości) |
| Formularze bez CAPTCHA/rate limitu, walidacja tylko w kliencie | Pięć warstw z sekcji 4.4 |
| Granty DELETE/UPDATE/TRUNCATE dla `anon`/`authenticated` | `REVOKE ALL` + `ALTER DEFAULT PRIVILEGES … FROM PUBLIC, anon, authenticated`; TRUNCATE niemożliwy |
| 21 funkcji `SECURITY DEFINER` dla `anon`, mutowalny `search_path` | Jedna funkcja pomocnicza, tylko dla `authenticated`, z zamrożonym `search_path`; test w CI na `EXECUTE` dla `anon`/`PUBLIC` |
| Skrypty z CDN, `user-scalable=no`, Google Fonts zewnętrzne | Brak CDN, zoom dozwolony, fonty self-hosted |
| Treść zaszyta w HTML/JS, duplikaty plików | MDX/JSON w repo z walidacją, jedno źródło prawdy |

### 4.12 Baner zgód (cookies) i tagi firm trzecich

Architektura zakłada zarządzanie zgodami w Zaraz i ładowanie GA4/pikseli wyłącznie po zgodzie (sekcja 6); baner musi spełniać wymagania wynikające z art. 399 PKE (dawny art. 173 Prawa telekomunikacyjnego), wytycznych EROD 03/2022 o ciemnych wzorcach i praktyki UOKiK [do potwierdzenia z prawnikiem]:

- dwa **równorzędne** przyciski na pierwszej warstwie: „Akceptuję” i „Odrzucam” (ten sam rozmiar, kontrast i pozycja); link „Ustawienia” jako trzecia, mniej eksponowana opcja;
- brak pre-zaznaczonych kategorii; kategorie „niezbędne” bez przełącznika;
- brak blokowania treści (cookie wall) i brak ponownego pytania po odrzuceniu przez co najmniej 6 miesięcy;
- decyzja zapisana w ciasteczku first-party **bez identyfikatora użytkownika** (tylko wersja banera i wybory per kategoria);
- stały link „Ustawienia cookies” w stopce – zmiana decyzji równie łatwa jak jej podjęcie;
- treść banera wersjonowana jak klauzule (`cookie-banner-v1-2026-11` w `packages/content/legal/cookie-banner.json`), wersja zapisana w ciasteczku;
- test Playwright w CI: przed zgodą strona nie wysyła **żadnego** żądania do domen trzecich i nie zapisuje ciasteczek innych niż niezbędne; po „Odrzucam” – to samo.

---

## 5. Stabilność

### 5.1 Bramki CI

| Bramka | Narzędzie | Kryterium |
|--------|-----------|-----------|
| Typy | `tsc --noEmit` (TS strict) | 0 błędów |
| Lint | ESLint + reguły bezpieczeństwa | 0 błędów; zakaz `dangerouslySetInnerHTML` poza whitelistą |
| Testy jednostkowe | Vitest | `packages/pricing`: pełna macierz grup ryzyka × sum × klauzula × wielkość zespołu z liczbami z briefu oraz przypadki brzegowe (gr. 4, zespół 9); schematy Zod; walidacja treści MDX/JSON i plików prawnych (`distributor.json` z `registryNumber !== null` dla produkcji, `publicationApproved` dla plików z `insurer`); szablony e-mail bez treści promocyjnych w `lead_client` |
| Uprawnienia SQL | lokalna baza z migracjami + zapytania do `pg_proc`/`pg_policies`/`information_schema` | testy (1)–(4) z pkt 3.2 |
| Sekrety | gitleaks | 0 trafień |
| Build | `opennextjs-cloudflare build` (lub `vinext build` po PoC) | sukces; **jeden artefakt** dla obu środowisk (zmienne per środowisko czytane w runtime) |
| Budżety | `size-limit` | trasy `/`, `/ubezpieczenia/oc-beauty`, `/kalkulator/oc` w limitach z sekcji 6 |
| Smoke | Playwright na podglądzie, przez Service Token Cloudflare Access (nagłówki `CF-Access-Client-Id`/`CF-Access-Client-Secret` z sekretów środowiska `staging` – bez nich testy dostałyby stronę logowania Access) | nawigacja, formularz z testowym kluczem Turnstile, 404, nagłówki bezpieczeństwa, baner zgód (4.12); v1: 1 viewport mobile + 1 desktop |
| Wydajność | Lighthouse CI (3 przebiegi mobile, te same nagłówki Access) | budżety LCP/INP/CLS/TTFB i wag zasobów; w v1 uruchamiane ręcznie przed wydaniem, docelowo w każdym PR (pkt 1.4) |

```yaml
# .github/workflows/ci-cd.yml (skrót; wersje akcji przypięte do SHA w realnym pliku)
name: ci-cd
on:
  pull_request:
  push: { branches: [main] }
permissions: { contents: read, pull-requests: write }

jobs:
  verify:
    runs-on: ubuntu-latest
    concurrency:                              # anulowanie TYLKO dla weryfikacji
      group: verify-${{ github.ref }}
      cancel-in-progress: true
    steps:
      - uses: actions/checkout@<sha>
      - uses: pnpm/action-setup@<sha>
      - uses: actions/setup-node@<sha>
        with: { node-version-file: .nvmrc, cache: pnpm }
      - run: pnpm install --frozen-lockfile
      - run: pnpm audit --audit-level=high
      - run: pnpm typecheck && pnpm lint
      - run: pnpm test --coverage            # pricing, schematy, treść, pliki prawne, uprawnienia SQL
      - run: pnpm build:cf                    # jeden build dla obu środowisk (bez NEXT_PUBLIC_* per env)
      - run: pnpm size-limit                  # budżety JS per trasa
      - uses: actions/upload-artifact@<sha>
        with: { name: open-next, path: .open-next }

  preview:
    needs: verify
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    environment: staging                      # sekrety stagingu, baza stagingowa, Service Token Access
    concurrency:
      group: preview-${{ github.ref }}
      cancel-in-progress: true
    steps:
      - uses: actions/checkout@<sha>          # + pnpm/setup-node/install jak w verify
      - uses: actions/download-artifact@<sha>
        with: { name: open-next, path: .open-next }
      - id: upload
        run: |
          pnpm wrangler versions upload --env staging --message "pr-${{ github.event.number }}" --json > version.json
          echo "url=$(jq -r .preview_url version.json)" >> "$GITHUB_OUTPUT"   # pola JSON do potwierdzenia z dokumentacją Wranglera
      - run: pnpm playwright test --config=playwright.smoke.ts
        env:
          BASE_URL: ${{ steps.upload.outputs.url }}
          CF_ACCESS_CLIENT_ID: ${{ secrets.CF_ACCESS_CLIENT_ID }}
          CF_ACCESS_CLIENT_SECRET: ${{ secrets.CF_ACCESS_CLIENT_SECRET }}
      - run: pnpm lhci autorun                 # lighthouserc.json: budżety + extraHeaders z tokenem Access; w v1 opcjonalnie

  deploy-production:
    needs: verify
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production                   # akceptacja drugiej osoby (może być właściciel biznesowy)
    concurrency:                              # NIGDY nie przerywać wdrożenia: anulowanie po `db push`, a przed
      group: deploy-production                # `versions deploy` zostawiłoby nowy schemat ze starym kodem
      cancel-in-progress: false               # albo ruch podzielony na dwie wersje na czas nieokreślony
    steps:
      - uses: actions/checkout@<sha>          # + pnpm/setup-node/install jak w verify
      - uses: actions/download-artifact@<sha>
        with: { name: open-next, path: .open-next }
      - run: supabase db push --linked        # migracje addytywne; token i hasło z sekretów środowiska
      - id: upload
        run: |
          pnpm wrangler versions upload --env production --json > version.json
          echo "id=$(jq -r .id version.json)" >> "$GITHUB_OUTPUT"
          echo "prev=$(pnpm wrangler deployments list --env production --json | jq -r '.[0].versions[0].version_id')" >> "$GITHUB_OUTPUT"
      # v1 (pkt 1.4): pominąć krok kanarka i wdrożyć od razu 100 %; rollback: `wrangler rollback`
      - run: pnpm wrangler versions deploy --env production -y "${{ steps.upload.outputs.id }}@10%" "${{ steps.upload.outputs.prev }}@90%"
      - run: pnpm playwright test --config=playwright.smoke.ts
        env: { BASE_URL: "https://beautypolisa.eu" }
      - run: pnpm wrangler versions deploy --env production -y "${{ steps.upload.outputs.id }}@100%"
```

Składnia podziału ruchu w `wrangler versions deploy` i pola wyjścia `--json` – do potwierdzenia z aktualną dokumentacją Wranglera na etapie implementacji.

### 5.2 Środowiska

| Środowisko | Worker / adres | Baza | Dostęp |
|-----------|----------------|------|--------|
| Podgląd per PR | wersja Workera `beautypolisa-web-staging` z adresem podglądu wersji | Supabase `beautypolisa-staging` | Cloudflare Access (ludzie) + Service Token (CI) |
| Staging | `beautypolisa-web-staging` → `staging.beautypolisa.eu` | jw. | Cloudflare Access, `X-Robots-Tag: noindex` |
| Produkcja | `beautypolisa-web` → `beautypolisa.eu` | Supabase `beautypolisa-prod` (Pro) | publiczny; `/panel` za Access |

Podglądy nie mogą współdzielić bindingów produkcyjnych – dlatego osobny Worker stagingowy z własnymi sekretami, a nie podgląd wersji Workera produkcyjnego.

Baza stagingowa na planie Free tylko, jeśli organizacja ma wolny slot (limit 2 aktywnych projektów Free; plany istniejących projektów „aurabroker”/„BEAUTY” nie są znane z audytu – pytanie otwarte 17). Projekt Free jest pauzowany po ok. 7 dniach bezczynności – pierwsze PR po przerwie w rozwoju failowałyby na smoke testach do ręcznego wznowienia; środek zaradczy: Cron w `beautypolisa-jobs` (staging) wykonuje `select 1` raz na dobę. Alternatywa: staging jako gałąź bazy w projekcie Pro (Supabase Branching) – koszt do uwzględnienia.

### 5.3 Wdrożenia stopniowe i rollback

Workers Versions: `versions upload` tworzy wersję bez ruchu; `versions deploy` dzieli ruch między maks. dwie wersje. Docelowo wdrożenie kanarkowe ~10 % na 5–10 min ze smoke testem, potem 100 %; w v1 (pkt 1.4) od razu 100 % z natychmiastowym rollbackiem. Znana pułapka: podczas podziału ruchu HTML z wersji B może odwoływać się do assetów, których nie ma w wersji A → 404 fragmentów JS; środek zaradczy: **version affinity** (przypięcie użytkownika do wersji ciasteczkiem/nagłówkiem) i krótki czas trwania podziału. Rollback: `wrangler rollback` do dowolnej z ostatnich wersji (limit podniesiony do 100) w sekundy; migracje bazy są wyłącznie addytywne (expand/contract), żeby rollback kodu nie wymagał rollbacku schematu.

### 5.4 Monitoring i alerty

- **Uptime zewnętrzny** (darmowy plan Better Stack/UptimeRobot [założenie]): `GET /` (oczekiwany fragment HTML) i `GET /api/health` co 1–5 min, z dwóch regionów; alert e-mail + kanał Teams (M365).
- **Cloudflare**: analityka ruchu i WAF, zdarzenia rate limit, metryki Workers (błędy, p99, CPU), powiadomienia o przekroczeniu budżetu żądań; dashboard Analytics Engine z własnym RUM: z przeglądarki wychodzą wyłącznie Web Vitals + ścieżka + typ urządzenia przez `POST /api/rum` (`sendBeacon`), **bez identyfikatora sesji/użytkownika i bez skryptu zbierającego cechy urządzenia**; serwer przekazuje zdarzenie do kolektora. Jeśli kolektor tworzy identyfikator odwiedzającego, powstaje on wyłącznie po stronie serwera z nagłówków żądania, z solą `VISITOR_SALT` rotowaną ≤ 24 h i nieprzechowywaną po rotacji [do weryfikacji w kodzie kolektora – 7.1]. Teza „bez zgody” jest obroniona tylko przy tych warunkach brzegowych [hipoteza prawna – do potwierdzenia z IOD; alternatywa: zgoda przez baner z 4.12].
- **Sentry** (serwer) z maskowaniem PII (4.8), alert przy > 5 błędach 5xx/5 min na `/api/leads`.
- **Outbox**: alert, gdy `pending` > 20 przez 15 min lub pojawi się `failed`.
- **Supabase**: alerty zużycia, przegląd Security/Performance Advisor po każdej migracji i co miesiąc (pkt 1.4), alert na nowe funkcje `SECURITY DEFINER`.
- **Turnstile**: wskaźnik odrzuceń (nagły wzrost = atak lub błąd integracji); odsetek trafień honeypota (nagły wzrost bez wzrostu odrzuceń Turnstile = fałszywe trafienia, np. autouzupełnianie).

### 5.5 SLO i runbook

| SLO | Cel | Okno | Reakcja po przekroczeniu |
|-----|-----|------|--------------------------|
| Dostępność stron publicznych | 99,9 % | 30 dni | zamrożenie wdrożeń poza poprawkami do końca okna |
| Odpowiedzi inne niż 5xx (i inne niż timeout) na `/api/leads` | ≥ 99,5 % | 30 dni | analiza przyczyn w post-mortem. Odsetek 403/429/422 raportowany **osobno** jako wskaźnik ataku/UX, bez wpływu na SLO – liczenie odrzuceń botów jako awarii zamrażałoby wdrożenia przy każdym ataku i zachęcało do poluzowania Turnstile |
| Dostarczenie e-maila zespołowi | ≤ 5 min dla 99 % leadów | 7 dni | przegląd outboxu, kontakt z Resend |
| LCP p75 mobile | ≤ 2,0 s | 28 dni (CrUX) | blokada PR pogarszających budżet |

Runbook (`docs/runbook.md`): procedury dla „5xx na API”, „Resend nie wysyła”, „Supabase niedostępny”, „podejrzenie spamu/ataku”, „rollback”, „rotacja sekretów”, „odtworzenie kopii”, „żądanie dostępu/usunięcia danych”, „wycofanie zgody zgłoszone poza linkiem”, „aktywacja nowej wersji cennika (zatwierdzenie)”, „SQL Editor zwraca 0 wierszy z `leads` (force RLS – to nie utrata danych)” – każda z krokami, poleceniami i właścicielem.

---

## 6. Wydajność i responsywność

**Techniki**

- RSC domyślnie; komponenty klienckie tylko tam, gdzie jest interakcja: kalkulator (jedyna większa wyspa), formularze (małe), menu mobilne, baner zgód (wymagania w 4.12). Zero bibliotek UI ładowanych globalnie.
- HTML renderowany na brzegu z cache danych (3.3); streaming RSC, żeby pierwszy bajt i LCP nie czekały na wolniejsze fragmenty.
- Obrazy: `next/image` z własnym loaderem do Cloudflare Image Transformations (`/cdn-cgi/image/width=…,format=auto/…`), `sizes` dopasowane do layoutu, `priority` tylko dla LCP; logo jako SVG. Fallback przy braku Image Transformations: warianty AVIF/WebP generowane w buildzie.
- Fonty: Montserrat self-hosted przez `next/font/local`, podzbiory `latin` + `latin-ext` (polskie znaki), 2–3 wagi, `font-display: swap`, preload tylko wagi używanej w nagłówku; brak Google Fonts.
- Brak skryptów firm trzecich przed zgodą; po zgodzie tagi (GA4, piksele) przez **Cloudflare Zaraz** (ładowanie po stronie Cloudflare, jedno lekkie żądanie, wbudowana obsługa zgód) – bez GTM w przeglądarce. Jeśli marketing wymaga GTM, to wyłącznie w wariancie server-side; w v1 nie.
- `Link: rel=preload` dla CSS i fontu nagłówkowego → Early Hints 103 z Cloudflare; `preconnect` tylko do `challenges.cloudflare.com` na stronach z formularzem.
- Efekt „glass widget” (z briefu) ograniczony do karty kalkulatora/CTA, warunkowany `@supports (backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px))` (ta sama forma co w `snippets/glass-widget.css`; `@supports` wymaga pary właściwość: wartość, a prefiks jest potrzebny dla starszych Safari/iOS), wyłączany przy `prefers-reduced-transparency` i `prefers-reduced-motion`; bez rozmycia na elementach animowanych przy przewijaniu (koszt GPU na słabszych Androidach).
- Tailwind 4: jeden arkusz, klasy nieużywane usuwane; CSS krytyczny i tak mały (≤ 30 KB gzip).

**Budżety i egzekwowanie**

| Metryka | Budżet | Narzędzie |
|---------|--------|-----------|
| JS (gzip) – landing / strona produktowa / kalkulator | ≤ 120 KB / ≤ 110 KB / ≤ 150 KB | `size-limit` w CI (fail PR) |
| CSS (gzip) | ≤ 30 KB | `size-limit` |
| Fonty łącznie | ≤ 120 KB | budżet LHCI `resource-summary` |
| Obraz LCP | ≤ 150 KB | LHCI |
| Żądania na landing | ≤ 30 | LHCI |
| LCP / INP / CLS / TTFB (mobile, Moto G class, 4G) | 2,0 s / 200 ms / 0,1 / 500 ms | LHCI asercje; po starcie CrUX |

Narzut frameworka (React + runtime Next.js) zajmuje istotną część budżetu JS [hipoteza: ~85–100 KB gzip], więc kod aplikacyjny na landing ma ok. 20–30 KB – stąd zakaz ciężkich zależności (daty, ikony całymi paczkami, biblioteki formularzy) poza panelem.

**Mobile-first**: projekt od 320 px w górę, siatka jednokolumnowa z progresywnym rozszerzaniem, nawigacja dolna/hamburger z dostępnym focusem, cele dotykowe ≥ 44 px, `viewport` bez blokady zoomu, testy Playwright na 360×800 i 1440×900 (v1), docelowo także 768×1024, kontrast WCAG AA dla palety (granat `#2a3b69`, róż `#e11d48` – róż na białym wymaga sprawdzenia kontrastu dla tekstu drobnego; szczegóły w sekcji projektowej koncepcji).

---

## 7. Integracja z istniejącą infrastrukturą

### 7.1 Trasa `beautypolisa.eu/*` → `aura-analytics-collector`

| Opcja | Zalety | Wady | Ocena |
|-------|--------|------|-------|
| A. Zostawić kolektor jako warstwę przed aplikacją (kolektor przekazuje żądania do aplikacji przez Service Binding) | brak zmian w kolektorze, spójne zbieranie dla całej Aury | każde żądanie przechodzi przez dwa Workery (opóźnienie, podwójne liczenie wywołań, trudniejsze debugowanie, zależność dostępności portalu od kodu kolektora); trasa `/*` przesłania custom domain aplikacji | odrzucona |
| **B. Usunąć trasę; aplikacja wywołuje kolektor przez Service Binding** (zdarzenia odsłon, leadów i Web Vitals emitowane z serwera, bez PII) | jeden skok sieciowy dla użytkownika, dane nadal w tym samym zbiorze `WEB_EVENTS` z tą samą solą, kolektor pozostaje wspólny dla Aury | kolektor musi wystawiać handler akceptujący zdarzenia przez binding (kod kolektora nie był widoczny w audycie) [do weryfikacji]; trzeba potwierdzić, co kolektor robi z solą `VISITOR_SALT` (identyfikator wyłącznie serwerowy, rotacja ≤ 24 h, sól nieprzechowywana po rotacji) i wskazać administratora zbioru `WEB_EVENTS` (Aura Consulting [założenie]) z wpisem w rejestrze czynności | **rekomendowana** |
| C. Przenieść logikę do aplikacji (bezpośredni binding do Analytics Engine `WEB_EVENTS` + KV `VISITOR_SALT`) | brak zależności od kolektora | duplikacja logiki haszowania, ryzyko rozjazdu z resztą Aury | wariant awaryjny, jeśli B niemożliwe |
| D. Wyłączyć | najprościej | utrata analityki first-party | odrzucona |

### 7.2 Worker `security-headers`

Nie podpinamy go do strefy: nagłówki (4.2) są częścią aplikacji i jej testów; podwójne przetwarzanie groziłoby konfliktami (np. dwa nagłówki CSP). Worker może dalej służyć innym strefom Aury.

### 7.3 Subdomeny

- `tax.` – treść Tax Protect przejmuje `/ubezpieczenia/tax-protect`; po uruchomieniu Redirect Rule `tax.beautypolisa.eu/*` → `https://beautypolisa.eu/ubezpieczenia/tax-protect` (301), a formularz z `tax.` zastępuje wspólny `/api/leads` (rozwiązuje też problem z audytu: `tax_wnioski` z RLS bez polityk). Dane historyczne z `tax_wnioski` – migracja jednorazowa do nowej bazy lub pozostawienie w „BEAUTY” do końca retencji [pytanie otwarte].
- `app.` (katalog salonów), `crm.`, `portal.`, `ergo.`, `konsultacja.` – pozostają; portal linkuje do nich w tej samej karcie (jeśli w nowej – `target="_blank" rel="noopener"`; dla zwykłych linków `rel="noopener"` nic nie wnosi, a nowoczesne przeglądarki stosują go domyślnie przy `target="_blank"`); CSP `form-action 'self'` i `frame-ancestors 'none'` oznaczają, że nic z subdomen nie osadza portalu ani odwrotnie. Włączenie HSTS `includeSubDomains` wymaga potwierdzenia HTTPS na każdej z nich, a także na `send.` i `links.` (Resend – domena śledzenia linków w e-mailach) i `staging.` (4.3).
- `www` → 301 na apex.

### 7.4 Przekierowania ze starych plików `.html`

Apex nie miał rekordu DNS, więc stare adresy nigdy nie były publicznie serwowane pod `beautypolisa.eu`; przekierowania to tania asekuracja (linki w materiałach, ewentualny indeks pod inną domeną [założenie]).

```ts
// next.config.ts (fragment)
export default {
  async redirects() {
    return [
      { source: "/indeksowt.html", destination: "/kalkulator/oc", permanent: true },
      { source: "/new.html",       destination: "/kalkulator/oc", permanent: true },
      { source: "/nowy.html",      destination: "/", permanent: true },
      { source: "/tax-protect.html", destination: "/ubezpieczenia/tax-protect", permanent: true },
      { source: "/life.html",      destination: "/ubezpieczenia/grupowe-ergo", permanent: true },
      { source: "/life1.html",     destination: "/ubezpieczenia/grupowe-ergo", permanent: true },
      { source: "/medical.html",   destination: "/ubezpieczenia/opieka-medyczna", permanent: true },
    ];
  },
};
```

### 7.5 Przykładowy `wrangler.jsonc` (bez sekretów)

Plik `snippets/wrangler.jsonc`.

```jsonc
{
  "$schema": "node_modules/wrangler/config-schema.json",
  "name": "beautypolisa-web",
  "main": ".open-next/worker.js",
  "compatibility_date": "2026-10-01",
  "compatibility_flags": ["nodejs_compat", "global_fetch_strictly_public"],
  "assets": { "directory": ".open-next/assets", "binding": "ASSETS" },
  "observability": { "enabled": true, "head_sampling_rate": 1 },
  // Zmienne czytane w RUNTIME (getCloudflareContext().env) – bez prefiksu NEXT_PUBLIC_, bo jeden build
  // obsługuje oba środowiska; wartości publiczne trafiają do komponentów jako props z RSC (4.5).
  "vars": {
    "SITE_URL": "https://beautypolisa.eu",
    "SUPABASE_URL": "https://<projekt-prod>.supabase.co",
    "TURNSTILE_SITE_KEY": "<klucz-publiczny-widgetu-prod>",
    "APP_ENV": "production"
  },
  // Sekrety WYŁĄCZNIE przez `wrangler secret put --env <env>`:
  // SUPABASE_SECRET_KEY, TURNSTILE_SECRET_KEY, RESEND_API_KEY, SENTRY_DSN, CONSENT_HMAC_KEY, UNSUBSCRIBE_HMAC_KEY
  "routes": [{ "pattern": "beautypolisa.eu", "custom_domain": true }],
  "kv_namespaces": [{ "binding": "NEXT_INC_CACHE_KV", "id": "<kv-prod>" }],
  "services": [{ "binding": "ANALYTICS", "service": "aura-analytics-collector" }],
  // Binding rate limit: klucz najwyższego poziomu `ratelimits` (Wrangler ≥ 4.36), nie `unsafe.bindings`;
  // `period` może wynosić tylko 10 lub 60 s; licznik liczony osobno w każdej lokalizacji Cloudflare.
  "ratelimits": [
    { "name": "LEAD_RATE_LIMITER", "namespace_id": "1001", "simple": { "limit": 5, "period": 60 } }
  ],
  "env": {
    "staging": {
      "name": "beautypolisa-web-staging",
      "routes": [{ "pattern": "staging.beautypolisa.eu", "custom_domain": true }],
      "vars": {
        "SITE_URL": "https://staging.beautypolisa.eu",
        "SUPABASE_URL": "https://<projekt-staging>.supabase.co",
        "TURNSTILE_SITE_KEY": "<klucz-publiczny-widgetu-staging>",
        "APP_ENV": "staging"
      },
      // Bindingi NIE są dziedziczone przez środowiska – każdy trzeba powtórzyć,
      // inaczej na stagingu env.LEAD_RATE_LIMITER byłby undefined i ta warstwa nie byłaby testowana.
      "kv_namespaces": [{ "binding": "NEXT_INC_CACHE_KV", "id": "<kv-staging>" }],
      "services": [{ "binding": "ANALYTICS", "service": "aura-analytics-collector" }],
      "ratelimits": [
        { "name": "LEAD_RATE_LIMITER", "namespace_id": "1002", "simple": { "limit": 5, "period": 60 } }
      ]
    }
  }
}
```

Worker `beautypolisa-jobs` ma osobny, krótki `wrangler.jsonc` z `"triggers": { "crons": ["*/5 * * * *", "15 3 * * *"] }` (retry outboxu, retencja; na stagingu dodatkowo `select 1` raz na dobę – 5.2) i tymi samymi sekretami Supabase/Resend. Układ repozytorium: `apps/web`, `apps/jobs`, `packages/pricing`, `packages/schemas`, `packages/content` (w tym `legal/`), `packages/db` (migracje, typy generowane z Supabase, testy uprawnień), `supabase/`.

---

## 8. Tabela trade-offów

| Decyzja | Opcja A | Opcja B | Opcja C | Rekomendacja |
|---------|---------|---------|---------|--------------|
| Hosting | **Workers + adapter Next.js**: pełny Next.js (RSC, route handlers, middleware) w tej samej sieci co reszta Aury, Service Bindings, Static Assets, wersje/rollback. Dwa adaptery: `@opennextjs/cloudflare` (dojrzały, ale wg dokumentacji Cloudflare przeznaczony do utrzymania istniejących aplikacji; ograniczenia: middleware edge, brak wbudowanej optymalizacji obrazów) oraz `vinext` (reimplementacja Next.js na Vite, wskazywana przez Cloudflare dla **nowych** projektów; status 1.0 i zakres wsparcia [do weryfikacji na starcie implementacji]) | Cloudflare Pages ze statycznym eksportem: najprostsze, ale brak renderingu serwerowego → CSP z `'unsafe-inline'` lub hashe, osobny Worker na API, a Cloudflare kieruje nowe projekty na Workers | Vercel: najlepsze doświadczenie deweloperskie (DX) i zero adaptera, ale dodatkowy dostawca i rachunek, dane poza Cloudflare, brak Service Binding do kolektora, podwójne CDN | **A, wybór warunkowy**: PoC (≤ 3 dni) z kryteriami akceptacji – CSP nonce w middleware, `after()`/`waitUntil`, Service Bindings, loader `next/image`, rewalidacja czasowa cache, streaming RSC, `getCloudflareContext().env` w RSC. Jeśli `vinext` przechodzi PoC – `vinext` (zgodnie z rekomendacją dostawcy: wsparcie, poprawki bezpieczeństwa, roadmapa); w przeciwnym razie OpenNext z zapisanym planem migracji na `vinext` |
| Baza | **Nowy projekt Supabase**: izolacja PII, czyste advisory, osobne klucze i kopie; koszt wg pkt 1.3 | Schemat w „BEAUTY”: zero nowego kosztu, bliżej `tax_warianty`; ale klucz anon i funkcje `SECURITY DEFINER` dla `anon` są wspólne dla całego projektu, 3 błędy krytyczne w Advisorze | Pozostanie w „aurabroker”: największe ryzyko wg audytu | **A** |
| Treść | **MDX/JSON w repo**: przegląd w PR, zero dodatkowych systemów, wersjonowanie z kodem (także treści prawnych) | Payload (już w `aurabroker`): edytor, ale współdzielona baza i kolejna powierzchnia ataku | Sanity/Strapi: edytor i podglądy, koszt i konto | **A**; rewizja przy >2 autorach lub >10 publikacji/mies. |
| Anty-bot | **Turnstile**: darmowy, bez ciasteczek śledzących, natywny dla Cloudflare, lepsza prywatność | reCAPTCHA v3: dojrzały, ale transfer danych do Google i obowiązki informacyjne | hCaptcha: podobny do Turnstile, kolejny dostawca | **A** |
| Analityka | **Analytics Engine (istniejący kolektor)**: first-party, bez ciasteczek, bez zgody przy warunkach z 5.4 [hipoteza prawna], spójne z Aurą; słabsze raporty marketingowe | GA4: raporty i integracja z Ads, ale wymaga zgody i obniża wydajność; dopuszczalne po zgodzie przez Zaraz (baner wg 4.12) | Plausible: prywatny i prosty, ale koszt i kolejny dostawca | **A** jako podstawa + GA4 przez Zaraz po zgodzie, gdy marketing tego potrzebuje |
| Kolejki | **Outbox + Cron**: zero nowych usług | Cloudflare Queues: gwarancje i DLQ, ale więcej komponentów | Wysyłka synchroniczna bez retry | **A** |
| Zgłoszenie szkody | **Strona instruktażowa + krótki formularz bez wolnego tekstu**: brak danych o zdrowiu osób trzecich, mniejszy zakres PII | Pełny formularz z opisem i załącznikami: wygodniejszy dla klienta, ale dane szczególnej kategorii (art. 9) w bazie portalu i obowiązki wobec osób trzecich | Brak formularza (tylko telefon/e-mail) | **A** |

---

## 9. Co zrewidować przy wzroście

- **Ruch > ~50 tys. odsłon/dzień** [próg założony]: włączyć cache tagowe Next.js (D1/KV) zamiast rewalidacji czasowej, podnieść compute Supabase, rozważyć Cloudflare Pro (pełny WAF, 2 reguły rate limit) i PITR.
- **Druga osoba techniczna lub > 20 leadów/dzień**: elementy z kolumny „później” w pkt 1.4 (kanarki, LHCI w PR, Renovate z automatycznym scalaniem, kwartalne testy odtworzenia, tygodniowy Advisor).
- **Więcej produktów/ubezpieczycieli**: model `pricing_versions` jest per produkt – nowe tabele taryf dochodzą bez zmian w leadach; schemat treści MDX ma pole `product`, więc kolejne linie to nowe pliki, nie nowy kod.
- **Wielojęzyczność**: struktura `packages/content/<locale>/…`, routing `/[locale]` i `hreflang` – nie wdrażać wcześniej, ale nie blokować (żadne slugi nie są zaszyte w kodzie komponentów).
- **Sprzedaż online**: wymaga tożsamości klienta (Supabase Auth dla klientów, nie tylko panelu), płatności przez hostowane strony operatora (brak danych kart w naszej infrastrukturze), podpisu dokumentów, obowiązków IDD przy zawieraniu umowy na odległość i prawdopodobnie PITR. To osobny projekt z własnym modelem zagrożeń – obecna architektura go nie wyklucza (oddzielny projekt Supabase, serwerowe API), ale nie jest pod niego zaprojektowana.
- **Wolumen e-maili > kilkaset/dzień**: Queues zamiast outboxu + Cron; Resend plan płatny.
- **Zespół treści**: CMS (headless) z publikacją przez webhook do rewalidacji – gdy przegląd w PR stanie się wąskim gardłem.

---

## Decyzje

1. **Next.js na Cloudflare Workers z renderingiem HTML na brzegu i cache danych; adapter wybierany warunkowo: `vinext`, jeśli przejdzie PoC z kryteriami z sekcji 8 (Cloudflare wskazuje go dla nowych projektów Next.js [do weryfikacji]), w przeciwnym razie `@opennextjs/cloudflare` z zapisanym planem migracji.** Uzasadnienie: pełne możliwości frameworka w infrastrukturze, którą Aura już utrzymuje; Service Binding do kolektora; wersje i rollback; wybór adaptera zgodny z kierunkiem wsparcia dostawcy. Odrzucone: statyczny eksport na Pages (brak serwera → słabsza CSP, osobne API), Vercel (drugi dostawca, dane poza Cloudflare). Workers Paid od pierwszego dnia (limit 10 ms CPU na Free).
2. **Nowy, dedykowany projekt Supabase (Pro) dla portalu.** Uzasadnienie: izolacja PII od CRM i innych modułów, czyste advisory, osobne kopie; plan Free pauzuje projekty. Odrzucone: schemat w „BEAUTY” (wspólny klucz anon i funkcje dla `anon`, błędy krytyczne w Advisorze), „aurabroker” (największe ryzyko wg audytu). Koszt wg pkt 1.3.
3. **Brak klucza Supabase w przeglądarce; zapis leadów wyłącznie z serwera przez jedną transakcyjną funkcję SQL; `REVOKE ALL` dla `anon`/`authenticated` na tabelach z PII; `ALTER DEFAULT PRIVILEGES FOR ROLE … REVOKE … FROM PUBLIC, anon, authenticated` plus test uprawnień w CI.** Odrzucone: wzorzec INSERT dla `anon` z RLS (jak `bp_quotes`/`crm_lead_intake`) – działa, ale pozostawia publiczną powierzchnię zapisu bez Turnstile i rate limitu na poziomie bazy; poleganie na samej dyscyplinie przy `REVOKE` per funkcja.
4. **Kalkulator liczy w przeglądarce z migawki cennika dostarczonej przez serwer; serwer przelicza przy wysyłce; cennik wersjonowany w bazie z jedną aktywną wersją na produkt, aktywowaną wyłącznie po zatwierdzeniu (bramka w bazie).** Odrzucone: obliczenia tylko na serwerze (gorszy INP, więcej żądań), cennik zaszyty w kodzie (brak audytu zmian, wdrożenie przy każdej zmianie składki), aktywacja bez zatwierdzenia (liczby z kodu kalkulatora nie są potwierdzone przez ubezpieczyciela).
5. **Ścisła CSP z nonce i `strict-dynamic` (skrypt Turnstile z nonce), kosztem braku cache HTML na brzegu; raportowanie przez `report-uri` i `report-to` równolegle.** Odrzucone: `'unsafe-inline'` ze statycznym HTML (osłabia główną ochronę przed XSS), hashe (kruche przy zmianach frameworka).
6. **Treść i treści prawne jako MDX/JSON w repozytorium, walidowane Zod, przeglądane w PR; bez CMS w v1; publikacja materiałów ubezpieczycieli i logotypów tylko z odnotowaną zgodą.** Odrzucone: Payload/Sanity (dodatkowa powierzchnia ataku i koszt przy niskim tempie zmian).
7. **Ochrona formularzy pięcioma warstwami w kolejności od najtańszej: honeypot (na surowym JSON), rate limit Cloudflare (jedna reguła Free, zawężona do endpointów formularzy), rate limit w Workerze, walidacja serwerowa, Turnstile; idempotencja sprawdzana przed Turnstile.** Odrzucone: reCAPTCHA (transfer danych do Google), sama walidacja (stan obecny), honeypot jako część schematu Zod (ujawnia pole pułapki), `siteverify` przed tanimi warstwami.
8. **E-mail przez Resend z outboxem i ponowieniami z Cron Triggers; bez Cloudflare Queues; szablon potwierdzenia dla klienta wyłącznie transakcyjny.** Odrzucone: Queues (więcej komponentów przy małym wolumenie), wysyłka synchroniczna bez retry, treści promocyjne w e-mailu potwierdzającym (wymagałyby zgody z PKE).
9. **Panel wewnętrzny w tej samej aplikacji pod `/panel`, renderowany serwerowo, za Cloudflare Access + Supabase Auth z MFA egzekwowanym w RLS (`aal2` w `app_is_staff`) + tabela ról chroniona triggerem guard; akcje wymagające dostępu do PII poza grantami `authenticated` (anonimizacja) wykonywane po stronie serwera kluczem serwisowym po sprawdzeniu roli.** Odrzucone: osobna aplikacja (więcej utrzymania przy 1–2 osobach – do rewizji), autoryzacja w kliencie (stan obecny), MFA tylko deklaratywne.
10. **Minimalny zakres PII w leadzie; pełna ankieta ERGO Hestii poza portalem w v1; zgłoszenie szkody jako strona instruktażowa z krótkim formularzem bez wolnego tekstu i bez załączników.** Odrzucone: pełny wniosek online (dane wrażliwe biznesowo i zdrowotne, obowiązki, których portal informacyjny nie musi brać na siebie), opis szkody w formularzu (dane o zdrowiu osób trzecich).
11. **Analityka first-party przez istniejący kolektor Aura wywoływany Service Bindingiem (trasa z apexu usunięta); z przeglądarki wyłącznie Web Vitals bez identyfikatorów przez `/api/rum`; tagi firm trzecich wyłącznie po zgodzie przez Zaraz z banerem spełniającym 4.12.** Odrzucone: kolektor jako proxy przed aplikacją (dwa Workery na żądanie), GTM w przeglądarce (wydajność, zgody), skrypt zbierający cechy urządzenia (fingerprinting – wymagałby zgody).
12. **Kopie dzienne Supabase Pro bez PITR w v1; RPO leadów ≈ 0 dzięki e-mailowi do zespołu.** Odrzucone: PITR od startu (koszt wg pkt 1.3 nieproporcjonalny do wolumenu).
13. **Wdrożenia przez Workers Versions z rollbackiem do poprzedniej wersji; w v1 100 % ruchu na nową wersję, docelowo kanarki z version affinity; migracje bazy tylko addytywne; joby wdrożeniowe nigdy nie są anulowane przez współbieżność.** Odrzucone: kanarki od startu przy jednoosobowym zespole (obsługa podziału ruchu bez korzyści przy małym ruchu), wspólna grupa współbieżności z `cancel-in-progress` dla wdrożeń (niespójny stan po przerwaniu).
14. **Nagłówki bezpieczeństwa w aplikacji, nie w Workerze `security-headers`; HSTS etapami z `preload` na końcu, po sprawdzeniu wszystkich subdomen, w tym `send.`/`links.` Resend.** Odrzucone: natychmiastowy `preload` (nieodwracalny przy problemach z subdomenami).
15. **Lead bez checkboxa „zgody na przetwarzanie”: podstawa art. 6 ust. 1 lit. b, obowiązek informacyjny przez klauzulę z zapisaną wersją; zgody wyłącznie marketingowe, osobno per kanał (RODO + PKE), z własnymi wersjami treści i samoobsługowym wycofaniem (link w każdej wiadomości, `List-Unsubscribe`).** Odrzucone: wymuszona „zgoda” (fikcyjna, wprowadza w błąd co do podstawy), jedna wspólna wersja treści dla wszystkich zgód, wycofanie tylko przez panel pracownika.
16. **Brak adresu IP w bazie – także jako hash; dowodem zgody są wersja treści, znacznik czasu, HMAC adresu, rodzina przeglądarki, `request_id` i (dla newslettera) double opt-in.** Odrzucone: `sha256(ip || sól dnia)` (albo nieweryfikowalny, albo odtwarzalny – nie jest dowodem, a jest daną osobową).
17. **Informacje o dystrybutorze (IDD) i ścieżka reklamacyjna z jednego pliku JSON, renderowane w stopce, formularzach, e-mailach i na `/informacje-prawne`; CI blokuje produkcję bez numeru rejestru.** Odrzucone: treści IDD wpisane ręcznie w komponentach (rozjazd między stronami, brak wersjonowania).
18. **Zakres operacyjny v1 ograniczony do tego, co zespół 1–2 osób utrzyma (pkt 1.4); reakcja na alerty w godzinach pracy; akceptacja wdrożeń przez właściciela biznesowego.** Odrzucone: pełny zestaw praktyk zespołu platformowego od pierwszego dnia (nierealny do utrzymania, więc pomijany w praktyce).

## Pytania otwarte do zleceniodawcy

1. Kto jest administratorem danych osobowych portalu – Aura Consulting sp. z o.o. czy Aura Expert sp. z o.o. (audyt: różne podmioty w różnych produktach)? Kto pełni funkcję IOD i zatwierdza podstawy prawne oraz okresy retencji z sekcji 4.7 (w tym rozstrzygnięcie konfliktu retencji leada i zgody marketingowej)?
2. Czy akceptowalny jest koszt stały wg pkt 1.3 (Supabase Pro + Workers Paid, ok. 30 USD/mies. [hipoteza]), a Cloudflare Pro i PITR odkładamy do czasu realnej potrzeby?
3. Czy kolektor `aura-analytics-collector` może przyjmować zdarzenia przez Service Binding (opcja B w 7.1) i jak traktuje sól `VISITOR_SALT` (rotacja, przechowywanie)? Potrzebny wgląd w jego kod lub kontakt z autorem.
4. Czy zespół Aura chce logować się do `/panel` przez Microsoft 365 (SSO w Cloudflare Access), czy wystarczą kody jednorazowe na e-mail + hasło i TOTP w Supabase Auth?
5. Jaki adres skrzynki zespołowej ma otrzymywać leady i zgłoszenia szkód, oraz czy leady mają być dodatkowo przekazywane do istniejącego CRM Aura (`crm.`) – jeśli tak, jakim interfejsem? (Od odpowiedzi zależy, od czego liczy się retencja po konwersji w 4.7.)
6. Co z danymi historycznymi `tax_wnioski` (1 wiersz) i `tax_warianty` (8 wierszy) w projekcie „BEAUTY” po przejęciu treści `tax.` przez portal – migracja czy pozostawienie?
7. Czy składki Tax Protect zostaną potwierdzone z Colonnade przed startem (bez tego strona pokazuje warianty sum bez kwot)?
8. Czy w v1 wysyłamy klientowi e-mail potwierdzający zgłoszenie (treść wyłącznie transakcyjna z informacjami IDD – reguła w 2.2 krok 11), czy tylko powiadomienie do zespołu?
9. Czy status dystrybutora (broker vs agent) jest już ustalony – wpływa na treści informacyjne w formularzach i stopkach (`distributor.json`, F10), a przez to na wersjonowane klauzule zapisywane przy leadzie?
10. Czy można wyłączyć blokadę crawlerów AI kategorii *search*/*user* w ustawieniach strefy (wymóg GEO – szczegóły w sekcji SEO/GEO), utrzymując blokadę *training*?
11. Czy przewidywana jest sprzedaż online lub wielojęzyczność w horyzoncie 12–18 miesięcy? Zmienia to priorytety z sekcji 9 (PITR, Auth dla klientów, routing językowy).
12. Czy cennik OC z kalkulatora (`bp-app.js`: gr. 1: 400/500/650 zł itd., program nr WA50/003353/24/A z 2024 r.) jest aktualny i zatwierdzony przez ERGO Hestię (data, wersja programu)? Kto po stronie Aura zatwierdza aktywację wersji cennika w panelu?
13. Czy oferta LUX MED/ENEL-MED to abonament medyczny, czy ubezpieczenie zdrowotne (np. z towarzystwem ubezpieczeń)? Decyduje o nazewnictwie, adresie strony (`/ubezpieczenia/opieka-medyczna` vs `/opieka-medyczna`), administratorze danych i obowiązkach informacyjnych.
14. Czy ERGO Hestia, Colonnade, Fundacja Beauty Razem, ENEL-MED i LUX MED wyraziły zgodę na użycie logotypów i publikację OWU/warunków programu na beautypolisa.eu? Kto po stronie ubezpieczyciela akceptuje treści produktowe?
15. Dane do `distributor.json` (F10): numer w rejestrze pośredników KNF, charakter wynagrodzenia (prowizja/honorarium), działanie na rzecz jednego czy wielu zakładów, procedura reklamacji i podmioty pozasądowego rozwiązywania sporów.
16. Potwierdzenie z prawnikiem stanu prawnego dla zgód marketingowych i banera cookies (art. 398/399 PKE, status art. 10 u.ś.u.d.e.) oraz minimalnych formuł zgód per kanał (`consents.json`).
17. Czy organizacja Supabase ma wolny slot na projekt Free dla stagingu (limit 2 projekty Free; plany „aurabroker”/„BEAUTY” nieznane), czy staging ma być gałęzią w projekcie Pro?
