# 02 · Architektura systemu, bezpieczeństwo, stabilność i wydajność

> Sekcja koncepcji portalu **beautypolisa.eu**. Fakty o stanie obecnym (produkty, ceny, Supabase, Cloudflare) pochodzą wyłącznie z `01-audyt-stanu-obecnego.md`; szczegóły obecnego kodu – w `03-code-review-obecnego-kodu.md`. Wszystko, co nie wynika z audytu, oznaczono jako „[założenie]” lub „[hipoteza – do weryfikacji]”. Dokument nie zawiera sekretów ani identyfikatorów projektów/stref.

## TL;DR

- Jedna aplikacja **Next.js (aktualna stabilna wersja, App Router, RSC, TypeScript) + Tailwind CSS 4** uruchamiana na **Cloudflare Workers przez `@opennextjs/cloudflare`**; HTML renderowany na Workerze (żeby każda odpowiedź miała własny nonce CSP), warstwa danych cache'owana, assety statyczne z Workers Static Assets.
- **Nowy, dedykowany projekt Supabase** (Postgres + RLS). Przeglądarka nie dostaje żadnego klucza Supabase: leady zapisuje wyłącznie serwer (klucz serwisowy w sekretach Workera) przez jedną transakcyjną funkcję SQL; cenniki są wersjonowane w bazie, z publicznym odczytem tylko aktywnych wierszy.
- Treść produktowa i baza wiedzy jako **MDX/JSON w repozytorium**, walidowane Zod i przeglądane w PR; brak CMS w pierwszej wersji.
- Ochrona formularzy warstwowo: **Turnstile + rate limit (Cloudflare i binding w Workerze) + honeypot + walidacja Zod + idempotencja i deduplikacja**; e-mail przez Resend z tabelą outbox i ponowieniami z Cron Triggers – **bez kolejek**.
- Zmiany w Cloudflare względem audytu: SSL **Full (strict)**, **min TLS 1.2**, HSTS etapami, Early Hints, jedna reguła rate limit (plan Free), usunięcie trasy `aura-analytics-collector` z apexu na rzecz Service Binding; panel wewnętrzny za **Cloudflare Access + Supabase Auth + RLS**.
- Koszt stały infrastruktury [hipoteza – do weryfikacji]: Supabase Pro ~25 USD/mies. + Workers Paid ~5 USD/mies.; Cloudflare Pro (~20 USD/mies.) opcjonalnie; PITR Supabase (~100 USD/mies.) odłożony.

---

## 1. Wymagania

### 1.1 Wymagania funkcjonalne

| ID | Wymaganie | Uwagi architektoniczne |
|----|-----------|------------------------|
| F1 | Strony produktowe dla 6 produktów (`/ubezpieczenia/*`) z nazwami: „OC dla branży beauty (ERGO Hestia)”, „Tax Protect (Colonnade)”, „Utrata dochodu”, „NNW dzieci”, „Grupowe ERGO dla beauty”, „Opieka medyczna (ENEL-MED / LUX MED)” | Treść z repo (MDX), renderowana po stronie serwera. Dla „Utrata dochodu” i „NNW dzieci” audyt nie zawiera danych produktowych – strony startują jako „zapytaj o ofertę” bez cennika. |
| F2 | Kalkulator OC (`/kalkulator/oc`) z logiką grup ryzyka z briefu: gr. 1–3 z cennikiem (sumy 100/200/300 tys. zł; składki gr.1: 400/500/650, gr.2: 650/790/950, gr.3: 850/980/1250 zł; klauzula ochrony prawnej +92 zł), gr. 4 i zespół > 8 osób → wycena indywidualna | Jedyna większa „wyspa” interaktywna. Logika jako czysta funkcja w pakiecie współdzielonym, testowana jednostkowo; cennik z bazy, wersjonowany. |
| F3 | Formularze leadowe per produkt (wspólny endpoint, pole `product`), strony `/dla-kogo/<zawod>` z prewypełnionym kontekstem | Minimalny zakres PII na etapie leada (imię i nazwisko, e-mail, telefon, opcjonalnie nazwa firmy/NIP). Pełna ankieta ERGO Hestii (szkodowość 3 lata, kwalifikacje personelu itd.) **nie** jest zbierana przez portal w v1. |
| F4 | Baza wiedzy (`/baza-wiedzy/<slug>`) | MDX w repo, statyczne dane, schema.org w sekcji SEO/GEO koncepcji. |
| F5 | Dokumenty OWU (`/dokumenty`) | PDF jako assety statyczne z wersjonowanymi nazwami plików; lista z MDX/JSON. |
| F6 | Panel wewnętrzny do leadów (`/panel`) – lista, statusy, przypisanie, aktywacja wersji cennika, anonimizacja | Supabase Auth (tylko panel), tabela ról z triggerem guard, RLS, dodatkowo Cloudflare Access przed `/panel/*`. |
| F7 | Zgłoszenie szkody (`/szkoda`) | Formularz bez załączników w v1; dane do `claims_reports`; powiadomienie zespołu. |
| F8 | Newsletter z double opt-in | Tabela `newsletter_subscribers`, token potwierdzenia hashowany. |
| F9 | Strony `/o-nas`, `/kontakt`, `/rodo`, przekierowania ze starych plików `.html`, linkowanie do subdomen Aura | Statyczne; redirecty w konfiguracji Next.js. |

### 1.2 Wymagania niefunkcjonalne – cele mierzalne

| Obszar | Cel | Jak mierzymy |
|--------|-----|--------------|
| Dostępność | **99,9 %** miesięcznie (budżet błędu ≈ 43 min/mies.) dla stron publicznych; API leadów: ≥ 99,5 % odpowiedzi innych niż 5xx | Zewnętrzny monitor uptime (1–5 min), metryki Workers |
| Szybkość | **LCP p75 mobile ≤ 2,0 s**, **INP ≤ 200 ms**, **CLS ≤ 0,1**, **TTFB ≤ 500 ms** (p75) | CrUX/Search Console po starcie, Lighthouse CI w PR, RUM własny (Analytics Engine) |
| Budżet JS | **≤ 120 KB gzip JS na landing** (home, strony produktowe bez kalkulatora mniej), CSS ≤ 30 KB gzip, fonty ≤ 120 KB łącznie, obraz hero ≤ 150 KB | `size-limit` w CI, budżety Lighthouse CI (`budget.json`) |
| Responsywność | Mobile-first, brak przewijania poziomego od 320 px, zoom dozwolony (usunięcie `user-scalable=no` z audytu), cele dotykowe ≥ 44 px | Playwright na 3 viewportach, audyt WCAG w Lighthouse |
| RTO / RPO | **RTO ≤ 4 h**, **RPO ≤ 24 h** dla bazy; dla leadów efektywne RPO ≈ 0, bo każdy lead jest równolegle dostarczany e-mailem do zespołu (druga kopia poza bazą) | Test odtworzenia kopii raz na kwartał |
| RODO | Brak PII w logach, retencja leadów bez konwersji 12 mies. [założenie], mechanizm usunięcia/anonimizacji na żądanie ≤ 72 h [założenie], rejestr zgód z wersją treści klauzuli | Przegląd kwartalny, test anonimizacji w CI (funkcja SQL) |
| Bezpieczeństwo | Brak klucza Supabase w przeglądarce, CSP z nonce, A+ w skanerach nagłówków, 0 krytycznych podatności zależności w `main` | Skaner nagłówków po każdym wdrożeniu, `pnpm audit` w CI |

### 1.3 Ograniczenia

- **Mały zespół** (1–2 osoby techniczne [założenie]) – architektura ma mieć mało ruchomych części: jeden Worker aplikacji, jeden mały Worker zadań cyklicznych, jedna baza, brak kolejek i brak CMS.
- **Istniejąca infrastruktura Aura** (z audytu): strefa `beautypolisa.eu` na planie Free; subdomeny `app.`, `crm.`, `portal.`, `tax.`, `ergo.`, `konsultacja.`; trasa Workera `aura-analytics-collector` na `beautypolisa.eu/*`; Worker `security-headers` bez trasy; Resend z DKIM już skonfigurowany (`send.`/`links.`); poczta Microsoft 365; dwa projekty Supabase („aurabroker” – współdzielony, „BEAUTY” – z modułem Tax Protect).
- **Plan Cloudflare Free** – co działa, a co wymaga dopłaty:

| Potrzeba | Free | Wymaga | Koszt orientacyjny [hipoteza – do weryfikacji] |
|----------|------|--------|-----------------------------------------------|
| Workers: rendering, Static Assets, Cron Triggers, KV, Service Bindings | Tak, limit ~100 tys. żądań/dzień | Workers Paid przy większym ruchu, Queues, dłuższej retencji logów | ~5 USD/mies. + zużycie |
| WAF managed rules | Tylko „Free Managed Ruleset” (podzbiór) | Pełny Cloudflare Managed Ruleset i OWASP – plan Pro | ~20 USD/mies. za strefę |
| Rate limiting | 1 reguła | 2 reguły (Pro), 5 (Business), zaawansowane – dodatek płatny | jw. |
| Turnstile | Tak | – | 0 |
| Cloudflare Access (Zero Trust) przed `/panel` | Tak, do ok. 50 użytkowników | – | 0 |
| Zaraz (ładowanie tagów firm trzecich po stronie serwera CF) | Tak, z limitem zdarzeń | Powyżej limitu | 0 → zużycie |
| Image Transformations | Włączenie na strefie; pula darmowych transformacji | Powyżej puli | niewielki |
| Supabase | Free pauzuje nieaktywne projekty – **niedopuszczalne na produkcji** | Pro (kopie dzienne, brak pauzowania) | ~25 USD/mies.; PITR dodatkowo ~100 USD/mies. za 7 dni – odłożony |
| Resend | Darmowy limit miesięczny | Przy większym wolumenie | 0 → ~20 USD/mies. |
| Sentry | Plan deweloperski | Przy większym wolumenie zdarzeń | 0 → ~26 USD/mies. |

Rekomendacja startowa: Workers Paid + Supabase Pro (ok. 30 USD/mies. [hipoteza]). Cloudflare Pro dopiero, jeśli pojawią się ataki, których nie zatrzyma Turnstile + jedna reguła rate limit.

---

## 2. Projekt wysokopoziomowy

### 2.1 Diagram komponentów

```text
                 ┌──────────────────────────────────────────────────────────────────────┐
                 │                       CLOUDFLARE (strefa beautypolisa.eu)            │
 użytkownik ───► │ DNS ─► TLS (Full strict, min 1.2, HSTS) ─► WAF (Free Managed Ruleset) │
 (mobile first)  │     ─► Rate Limiting (1 reguła: POST /api/*) ─► Cache Rules            │
                 │     ─► Turnstile (challenge w formularzach)  ─► Zaraz (tagi po zgodzie) │
                 │                                   │                                   │
                 │              ┌────────────────────▼─────────────────────┐             │
                 │              │  Worker: beautypolisa-web (OpenNext)     │             │
                 │              │  • Next.js App Router, RSC, route        │             │
                 │              │    handlers /api/*, server actions /panel│             │
                 │              │  • Static Assets: /_next/static, /dokumenty│           │
                 │              │  • KV: cache inkrementalny Next.js       │             │
                 │              │  • binding ratelimit: LEAD_RATE_LIMITER  │             │
                 │              └───┬──────────┬───────────┬──────────┬────┘             │
                 │                  │          │           │          │ Service Binding   │
                 │                  │          │           │   ┌──────▼─────────────────┐ │
                 │                  │          │           │   │ Worker: aura-analytics- │ │
                 │                  │          │           │   │ collector (istniejący)  │ │
                 │                  │          │           │   │ KV VISITOR_SALT, AE      │ │
                 │                  │          │           │   │ WEB_EVENTS               │ │
                 │                  │          │           │   └────────────────────────┘ │
                 │   ┌──────────────▼───────┐  │           │                               │
                 │   │ Worker: beautypolisa-│  │           │                               │
                 │   │ jobs (Cron Triggers) │  │           │                               │
                 │   │ • retry outbox e-mail│  │           │                               │
                 │   │ • retencja/anonimiz. │  │           │                               │
                 │   └──────────┬───────────┘  │           │                               │
                 └──────────────┼──────────────┼───────────┼───────────────────────────────┘
                                │              │           │
                      ┌─────────▼──────────┐ ┌─▼────────┐ ┌▼──────────────────┐
                      │ Supabase (nowy     │ │ Resend   │ │ Sentry (bez PII)  │
                      │ projekt, eu-west-1)│ │ (e-mail) │ │ Uptime zewnętrzny │
                      │ Postgres + RLS,    │ └──────────┘ └───────────────────┘
                      │ Auth tylko /panel  │
                      └────────────────────┘
                                ▲
            GitHub Actions ─────┘ (migracje `supabase db push`, `wrangler versions upload/deploy`)
```

### 2.2 Przepływ leada (krok po kroku)

1. Formularz (komponent kliencki) przy montażu generuje `idempotencyKey` (UUID v4) i renderuje widget Turnstile; pole honeypot `website` jest ukryte CSS-em i ma `tabindex="-1"`, `autocomplete="off"`.
2. Wysyłka `POST /api/leads` (JSON) – jeden endpoint dla wszystkich produktów.
3. **Cloudflare**: WAF managed rules → reguła rate limit (np. 10 żądań/10 s na IP dla `POST /api/*`, akcja „managed challenge”) → Worker.
4. **Route handler**: limit rozmiaru ciała (16 KB), parsowanie JSON, walidacja `LeadInput` (Zod). Błędy → `422 validation_failed` z listą pól. Honeypot wypełniony → `200` z neutralnym komunikatem, bez zapisu (nie zdradzamy botowi, że go wykryto), zdarzenie `honeypot_hit` w metrykach.
5. **Turnstile**: weryfikacja tokenu w API `siteverify` z sekretem Workera, z przekazaniem IP klienta; niepowodzenie → `403 turnstile_failed`. Brak odpowiedzi Turnstile (awaria) → `503` z komunikatem i danymi kontaktowymi (telefon/e-mail) – bezpieczeństwo przed wygodą.
6. **Rate limit aplikacyjny** (binding `LEAD_RATE_LIMITER`, klucz = hash IP + produkt, np. 5/min) → `429 rate_limited` z `Retry-After`.
7. **Zapis**: wywołanie funkcji SQL `app_create_lead(jsonb)` kluczem serwisowym; funkcja w jednej transakcji: sprawdza idempotencję (`idempotency_key`), **deduplikuje** (ten sam `email_normalized` + produkt w ciągu 24 h → dopisuje zdarzenie `duplicate_submission` do istniejącego leada zamiast tworzyć nowy), **przelicza składkę po stronie serwera** z aktywnej wersji cennika, zapisuje `leads`, `consents`, `lead_events('created')` i dwa wiersze `outbox_emails` (zespół, klient).
8. **E-mail**: w `ctx.waitUntil` pierwsza próba wysyłki obu wiadomości przez Resend (z nagłówkiem idempotencji = id wiersza outbox); sukces → `outbox_emails.status='sent'`, porażka → `pending` z `next_attempt_at`; Worker `beautypolisa-jobs` ponawia co 5 min (backoff 5/15/60 min, maks. 6 prób), potem `failed` + alert.
9. **Zdarzenie analityczne** `lead_submitted {product, profession, individualQuote}` przez Service Binding do kolektora (bez PII).
10. Odpowiedź `201 {status:"created", leadId, quote}` lub `200 {status:"duplicate", leadId}`; klient pokazuje podsumowanie i numer zgłoszenia.
11. Potwierdzenie dla klienta jest wysyłane **maks. raz na adres e-mail na 24 h** (ochrona przed użyciem portalu do zasypywania cudzej skrzynki).
12. Zespół pracuje w `/panel` (statusy `new → contacted → quoted → won/lost/spam`); każda zmiana trafia do `lead_events`.

### 2.3 Przepływ kalkulatora

Decyzja: **obliczenia w przeglądarce na podstawie migawki cennika osadzonej w HTML przez serwer, z ponownym przeliczeniem na serwerze przy wysyłce leada.**

- Strona `/kalkulator/oc` (RSC) pobiera aktywną wersję cennika (`pricing_versions.is_active` + `pricing_oc_tiers`) przez warstwę cache Next.js z rewalidacją czasową 5 min i przekazuje ją jako props do wyspy klienckiej razem z `pricingVersionId`.
- Wyspa liczy natychmiast (INP ≤ 200 ms, brak żądań sieciowych przy każdej zmianie suwaka). Logika to czysta funkcja `quoteOc(input, tiers)` w pakiecie `packages/pricing`, ta sama na kliencie i serwerze.
- Gr. 4 lub zespół > 8 → wynik `individual: true` z listą powodów; formularz zmienia CTA na „poproś o wycenę indywidualną”.
- Przy wysyłce serwer przelicza składkę dla `pricingVersionId` z żądania; jeśli ta wersja nie jest już aktywna, liczy z aktualnej i oznacza `quote_recomputed` w `lead_events`. Wynik klienta nigdy nie jest zapisywany jako wiążący.
- Wyświetlana kwota jest opatrzona adnotacją „składka orientacyjna wg cennika programu; ostateczna oferta po ocenie wniosku” – treść do uzgodnienia z zespołem produktowym.
- Tax Protect: w bazie `pricing_tax_variants` ma `annual_premium NULL` dopóki składki nie zostaną potwierdzone z Colonnade (audyt: „DO POTWIERDZENIA”) – strona pokazuje warianty sum bez kwot i formularz zapytania.

### 2.4 Kontrakty API

| Endpoint | Metoda | Wejście (Zod) | Wyjście | Kody błędów |
|----------|--------|---------------|---------|-------------|
| `/api/leads` | POST | `LeadInput` | `201 {status:"created", leadId, quote}` / `200 {status:"duplicate", leadId}` | `400 invalid_json`, `413 payload_too_large`, `422 validation_failed`, `403 turnstile_failed`, `429 rate_limited`, `503 upstream_unavailable` |
| `/api/newsletter` | POST | `{email, textVersion, turnstileToken, website?}` | zawsze `202 {status:"accepted"}` (brak enumeracji adresów) | `422`, `403`, `429` |
| `/api/newsletter/confirm` | GET | `?token=` (hash porównywany w bazie) | `302` → `/newsletter/potwierdzono` lub `/newsletter/blad` | – |
| `/api/claims` | POST | `ClaimInput` (produkt, nr polisy opcjonalnie, kontakt, data zdarzenia, opis ≤ 2000 znaków) | `201 {claimId}` | jak `/api/leads` |
| `/api/health` | GET | – | `200 {ok:true, db:"ok"\|"degraded", version}` | `503` |
| `/api/csp-report` | POST | raport `application/reports+json` | `204` | – |
| server actions w `/panel` | – | `updateLeadStatus`, `assignLead`, `addNote`, `activatePricingVersion`, `anonymizeLead` – sesja Supabase użytkownika (RLS) | – | `401`, `403` |

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

Schemat Zod leada (wspólny dla klienta i serwera; serwer jest źródłem prawdy):

```ts
// packages/schemas/lead.ts
import { z } from "zod";
import { isValidNip } from "./nip";

export const Product = z.enum([
  "oc-beauty", "tax-protect", "utrata-dochodu",
  "nnw-dzieci", "grupowe-ergo", "opieka-medyczna",
]);

export const Profession = z.enum([
  "kosmetolog", "fryzjer", "podolog", "linergistka",
  "stylistka-paznokci", "tatuazysta", "inny",
]);

const plPhone = z.string().trim()
  .regex(/^(\+48)?[ -]?\d{3}[ -]?\d{3}[ -]?\d{3}$/, "Podaj numer w formacie 123 456 789");

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
  phone: plPhone.optional(),
  companyName: z.string().trim().max(200).optional(),
  nip: z.string().regex(/^\d{10}$/).refine(isValidNip, "Nieprawidłowy NIP").optional(),
  profession: Profession.optional(),
  message: z.string().trim().max(2000).optional(),
  calc: OcCalcInput.optional(),                  // wymagane tylko dla oc-beauty
  consents: z.object({
    processingQuote: z.literal(true),            // bez tej zgody/informacji – 422
    marketingEmail: z.boolean().default(false),
    marketingPhone: z.boolean().default(false),
    textVersion: z.string().regex(/^rodo-v\d+-\d{4}-\d{2}$/), // wersja klauzuli z repo
  }),
  utm: z.record(z.string().max(40), z.string().max(100)).optional(),
  landingPath: z.string().startsWith("/").max(300).optional(),
  turnstileToken: z.string().min(1).max(2048),
  website: z.literal("").optional(),             // honeypot – każda inna wartość = bot
}).superRefine((v, ctx) => {
  if (v.product === "oc-beauty" && !v.calc) {
    ctx.addIssue({ code: "custom", path: ["calc"], message: "Brak danych kalkulatora" });
  }
});
export type LeadInput = z.infer<typeof LeadInput>;

export const QuoteResult = z.discriminatedUnion("individual", [
  z.object({ individual: z.literal(false), annualPremium: z.number(), legalProtection: z.number(), pricingVersionId: z.string().uuid() }),
  z.object({ individual: z.literal(true), reasons: z.array(z.enum(["risk_group_4", "team_over_8"])) }),
]);
```

### 2.5 Magazyn treści: MDX/JSON w repozytorium zamiast CMS

Treść produktowa (6 produktów), strony `/dla-kogo/*` (6–10 zawodów) i baza wiedzy (kilka–kilkanaście artykułów na start, kilka miesięcznie [założenie]) trafiają do `packages/content` jako MDX z frontmatter oraz JSON dla danych strukturalnych (tabele sum, FAQ, listy zabiegów per grupa ryzyka). Każdy plik jest walidowany schematem Zod w CI (frontmatter: `title`, `description`, `product`, `updatedAt`, `reviewedBy`, `owuVersion`), a zmiana przechodzi przegląd w PR – dla treści ubezpieczeniowej (zgodność z OWU, IDD) ta ścieżka „cztery oczy” jest zaletą, nie kosztem. Obrazy i PDF OWU leżą obok treści i są publikowane jako assety statyczne.

CMS (Payload – obecny w `aurabroker` jako `cms.*`, Sanity, Strapi) odrzucamy w v1: dodaje kolejny system do zabezpieczenia i utrzymania, kolejne konto i koszty, a tempo zmian treści nie uzasadnia edytora WYSIWYG. Granica rewizji – sekcja 9.

Dane dynamiczne (leady, zgody, zdarzenia, cenniki, subskrybenci, zgłoszenia szkód, outbox e-mail) są w Supabase.

---

## 3. Deep dive

### 3.1 Model danych (DDL, fragment kluczowy)

```sql
-- Higiena uprawnień: nowe obiekty w public NIE dostają domyślnych grantów dla anon/authenticated
alter default privileges in schema public revoke all on tables    from anon, authenticated;
alter default privileges in schema public revoke all on sequences from anon, authenticated;
alter default privileges in schema public revoke all on functions from anon, authenticated;

create type lead_product as enum
  ('oc-beauty','tax-protect','utrata-dochodu','nnw-dzieci','grupowe-ergo','opieka-medyczna');
create type lead_status as enum
  ('new','contacted','quoted','won','lost','spam','anonymized');

-- Wersjonowanie cenników: dokładnie jedna aktywna wersja na produkt
create table pricing_versions (
  id           uuid primary key default gen_random_uuid(),
  product      lead_product not null,
  label        text not null,            -- np. "OC ERGO Hestia – cennik programu wg briefu"
  valid_from   date not null,
  valid_to     date,
  is_active    boolean not null default false,
  source_note  text,                     -- np. "składki DO POTWIERDZENIA z Colonnade"
  approved_by  uuid references auth.users(id),
  created_at   timestamptz not null default now()
);
create unique index pricing_versions_one_active on pricing_versions (product) where is_active;

create table pricing_oc_tiers (
  id                     bigint generated always as identity primary key,
  version_id             uuid not null references pricing_versions(id) on delete cascade,
  risk_group             smallint not null check (risk_group between 1 and 3), -- gr. 4 = brak wiersza, wycena indywidualna
  sum_insured            integer  not null check (sum_insured in (100000, 200000, 300000)),
  annual_premium         numeric(10,2) not null check (annual_premium > 0),
  legal_protection_addon numeric(10,2) not null default 92.00,
  max_team_size          smallint not null default 8,      -- powyżej → wycena indywidualna
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

create table leads (
  id                 uuid primary key default gen_random_uuid(),
  idempotency_key    uuid not null unique,          -- z klienta; ponowna wysyłka = ten sam lead
  product            lead_product not null,
  status             lead_status  not null default 'new',
  -- PII – czyszczone przez anonymize_lead()
  full_name          text,
  email              text,
  email_normalized   text,                          -- lower(trim(email)); do deduplikacji
  phone              text,
  company_name       text,
  nip                text check (nip ~ '^[0-9]{10}$'),
  profession         text,                          -- slug z /dla-kogo/<zawod>
  message            text check (char_length(message) <= 2000),
  -- kontekst kalkulatora (bez PII)
  calc_input         jsonb,                         -- {riskGroup,sumInsured,legalProtection,teamSize}
  calc_result        jsonb,                         -- wynik przeliczony NA SERWERZE
  pricing_version_id uuid references pricing_versions(id),
  utm                jsonb,
  landing_path       text,
  assigned_to        uuid references auth.users(id),
  anonymized_at      timestamptz,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);
create index leads_dedupe_idx on leads (email_normalized, product, created_at desc);
create index leads_status_idx on leads (status, created_at desc);

create table lead_events (
  id         bigint generated always as identity primary key,
  lead_id    uuid not null references leads(id) on delete cascade,
  type       text not null check (type in ('created','duplicate_submission','quote_recomputed',
               'email_team_sent','email_client_sent','email_failed','status_changed',
               'assigned','note_added','anonymized')),
  payload    jsonb,                                 -- bez PII (np. {"from":"new","to":"contacted"})
  actor      text not null default 'system',        -- 'system' | 'user:<uuid>'
  created_at timestamptz not null default now()
);

create table newsletter_subscribers (
  id                 uuid primary key default gen_random_uuid(),
  email              text not null,
  email_normalized   text not null unique,
  status             text not null default 'pending' check (status in ('pending','confirmed','unsubscribed')),
  confirm_token_hash text,                          -- sha256(token); token wysyłany e-mailem, ważny 48 h
  confirmed_at       timestamptz,
  unsubscribed_at    timestamptz,
  source_path        text,
  created_at         timestamptz not null default now()
);

create table consents (
  id            bigint generated always as identity primary key,
  lead_id       uuid references leads(id) on delete cascade,
  subscriber_id uuid references newsletter_subscribers(id) on delete cascade,
  purpose       text not null check (purpose in ('processing_quote','marketing_email','marketing_phone','newsletter')),
  granted       boolean not null,
  text_version  text not null,                      -- identyfikator treści klauzuli z repo, np. rodo-v3-2026-11
  ip_hash       text,                               -- sha256(ip || sól dnia) – dowód bez przechowywania IP
  user_agent    text check (char_length(user_agent) <= 256),
  created_at    timestamptz not null default now(),
  check (lead_id is not null or subscriber_id is not null)
);

create table admin_users (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  role       text not null check (role in ('admin','agent','viewer')),
  is_active  boolean not null default true,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table claims_reports (
  id             uuid primary key default gen_random_uuid(),
  product        lead_product not null,
  policy_number  text check (char_length(policy_number) <= 40),
  full_name      text, email text, phone text,
  incident_date  date,
  description    text check (char_length(description) <= 2000),  -- formularz prosi o NIEpodawanie danych zdrowotnych osób trzecich
  status         text not null default 'new' check (status in ('new','forwarded','closed','anonymized')),
  anonymized_at  timestamptz,
  created_at     timestamptz not null default now()
);

create table outbox_emails (
  id              uuid primary key default gen_random_uuid(),   -- = klucz idempotencji w Resend
  lead_id         uuid references leads(id) on delete cascade,
  template        text not null,                 -- 'lead_team' | 'lead_client' | 'newsletter_confirm' | ...
  recipient       text not null,                 -- PII; czyszczone razem z leadem
  payload         jsonb not null,                -- dane do szablonu
  status          text not null default 'pending' check (status in ('pending','sent','failed')),
  attempts        smallint not null default 0,
  next_attempt_at timestamptz not null default now(),
  provider_id     text,
  last_error      text,
  created_at      timestamptz not null default now()
);
create index outbox_pending_idx on outbox_emails (next_attempt_at) where status = 'pending';
```

Funkcja zapisu leada (`app_create_lead(jsonb)`) jest `security invoker`, ma `set search_path = public`, a `execute` jest odebrane rolom `public`, `anon` i `authenticated` – może ją wywołać tylko `service_role` z serwera. Analogicznie `anonymize_lead(uuid)` zeruje pola PII w `leads`, `consents.ip_hash/user_agent`, `outbox_emails.recipient/payload`, ustawia `status='anonymized'` i dopisuje zdarzenie.

### 3.2 Polityki RLS

Wzorzec: **`anon` nie ma żadnego dostępu do tabel z PII** (ani grantów, ani polityk); cenniki – publiczny odczyt tylko aktywnych; panel – role z `admin_users` chronione triggerem guard (odpowiednik `bp_profiles_guard` z audytu); odebrane zbędne granty, w tym `TRUNCATE`, którego RLS nie obejmuje.

```sql
-- LEADY: zero dostępu dla anon; personel czyta i aktualizuje wybrane kolumny przez RLS
alter table leads enable row level security;
alter table leads force row level security;                 -- także dla właściciela tabeli
revoke all on leads, lead_events, consents, claims_reports, outbox_emails from anon, authenticated;
grant select, update (status, assigned_to, updated_at) on leads to authenticated;
grant select, insert on lead_events to authenticated;
grant select on consents to authenticated;

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
-- brak polityk INSERT/DELETE na leads dla authenticated → zapis wyłącznie service_role (serwer)

-- CENNIKI: publiczny odczyt tylko aktywnej wersji; zapis wyłącznie admin
alter table pricing_versions   enable row level security;
alter table pricing_oc_tiers   enable row level security;
alter table pricing_tax_variants enable row level security;
revoke all on pricing_versions, pricing_oc_tiers, pricing_tax_variants from anon, authenticated;
grant select on pricing_versions, pricing_oc_tiers, pricing_tax_variants to anon, authenticated;
grant insert, update on pricing_versions, pricing_oc_tiers, pricing_tax_variants to authenticated;

create policy pricing_versions_public_read on pricing_versions
  for select to anon, authenticated using (is_active or app_is_staff());
create policy pricing_oc_public_read on pricing_oc_tiers
  for select to anon, authenticated
  using (exists (select 1 from pricing_versions v where v.id = version_id and (v.is_active or app_is_staff())));
create policy pricing_versions_admin_write on pricing_versions
  for all to authenticated using (app_is_staff('admin')) with check (app_is_staff('admin'));
create policy pricing_oc_admin_write on pricing_oc_tiers
  for all to authenticated using (app_is_staff('admin')) with check (app_is_staff('admin'));

-- ROLE PANELU: odczyt własnego wiersza; każda zmiana tylko z backendu (trigger guard)
alter table admin_users enable row level security;
revoke all on admin_users from anon, authenticated;
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

-- Pomocnicza funkcja ról: SECURITY DEFINER z zamrożonym search_path, niedostępna dla anon
create or replace function app_is_staff(variadic roles text[] default array['admin','agent','viewer'])
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from admin_users a
    where a.user_id = auth.uid() and a.is_active and a.role = any (roles)
  );
$$;
revoke execute on function app_is_staff(text[]) from public, anon;
grant  execute on function app_is_staff(text[]) to authenticated;
```

Dodatkowo w nowym projekcie: brak funkcji `SECURITY DEFINER` wykonywalnych przez `anon` (w audycie: 21 w „aurabroker”, 17 w „BEAUTY”), rozszerzenia w schemacie `extensions`, włączona ochrona przed wyciekłymi hasłami, MFA (TOTP) wymagane dla ról `admin`/`agent`, cotygodniowy przegląd Security Advisor jako punkt runbooka. Lista ról zaufanych w triggerze guard – do potwierdzenia z aktualnymi domyślnymi rolami Supabase.

### 3.3 Strategia cache

| Zasób | Nagłówki z aplikacji | Cloudflare | Uwagi |
|-------|----------------------|-----------|-------|
| `/_next/static/*`, fonty, obrazy w repo | `Cache-Control: public, max-age=31536000, immutable` | Static Assets z sieci CF; Cache Rule „Cache everything, Edge TTL 1 rok” | nazwy z hashem treści |
| `/dokumenty/*.pdf` (OWU) | `public, max-age=86400`, `Content-Disposition: inline` | cache 1 dzień | nazwa pliku z datą/wersją OWU |
| HTML stron publicznych | `private, no-cache` | **nie cache'owane na brzegu** (nonce per odpowiedź) | dane pod spodem z cache Next.js (KV) – TTFB bez zapytań do bazy |
| Dane: cennik, lista artykułów | cache Next.js (`"use cache"` / `unstable_cache` zależnie od wersji) z rewalidacją 300 s | – | aktywacja nowej wersji cennika widoczna ≤ 5 min; brak infrastruktury tag cache |
| `/sitemap.xml`, `/robots.txt`, `/llms.txt` | `public, max-age=3600` | cache 1 h | treść w sekcji SEO/GEO |
| `/api/*`, `/panel/*`, odpowiedzi z `Set-Cookie`, Turnstile | `no-store` | Cache Rule „Bypass” | **nigdy** w cache |
| Obrazy transformowane (`/cdn-cgi/image/*`) | – | zarządzane przez CF | warianty AVIF/WebP per szerokość |

Dlaczego HTML renderowany per żądanie, a nie statyczny: ścisła CSP z nonce wymaga unikalnego nonce w każdej odpowiedzi; statyczny eksport zmusiłby do `'unsafe-inline'` w `script-src` (Next.js osadza inline'owy payload RSC/hydracji) albo do kruchych hashy. Na Workers rendering kosztuje pojedyncze milisekundy, a dane są w cache, więc TTFB ≤ 500 ms jest osiągalny bez cache HTML. Uwaga wdrożeniowa: adapter OpenNext na Workers wymaga middleware w runtime edge (middleware/proxy w runtime Node nie jest wspierane) – generowanie nonce musi być tam zaprojektowane [do weryfikacji na starcie implementacji].

### 3.4 Kolejki i zdarzenia – nie w v1

Cloudflare Queues wymagają planu Workers Paid i dokładają kolejny komponent do obsługi (DLQ, konsument, monitoring). Przy wolumenie leadów liczonym w sztukach–dziesiątkach dziennie [założenie] wystarcza **wzorzec outbox**: wiersze `outbox_emails` zapisywane w tej samej transakcji co lead, pierwsza próba wysyłki natychmiast (`ctx.waitUntil`), ponowienia z Cron Trigger w `beautypolisa-jobs`. Daje to te same gwarancje (co najmniej raz, z idempotencją po stronie Resend) bez kolejki. Jeśli outbox rośnie – alert (sekcja 5.4).

### 3.5 Obsługa błędów, retry, idempotencja, deduplikacja

- **Idempotencja leada**: `idempotency_key` unikalny; ponowna wysyłka (np. po utracie sieci) zwraca ten sam `leadId`. Klucz żyje do odświeżenia strony.
- **Deduplikacja**: ten sam `email_normalized` + produkt w 24 h → zdarzenie zamiast nowego leada; panel pokazuje licznik ponowień.
- **E-mail**: identyfikator wiersza outbox jako klucz idempotencji w Resend [do weryfikacji wsparcia w API Resend]; backoff wykładniczy; po 6 próbach `failed` i alert; zespół ma zawsze leady w panelu, więc awaria poczty nie gubi danych.
- **Supabase niedostępny**: `/api/leads` zwraca `503` z komunikatem i kontaktem awaryjnym (telefon/e-mail Aura); brak buforowania w KV (unikamy drugiego miejsca przechowywania PII); alert natychmiast.
- **Turnstile niedostępny**: `503`, jak wyżej. Świadomy wybór bezpieczeństwa nad konwersją.
- Błędy aplikacji → Sentry bez PII; każda odpowiedź ma `requestId` zwracany klientowi i logowany.

---

## 4. Bezpieczeństwo (priorytet nr 1)

### 4.1 Model zagrożeń (STRIDE, lekki)

| Kategoria | Zagrożenie | Środki |
|-----------|-----------|--------|
| **S**poofing | Boty wysyłające leady; podszycie pod zespół (phishing w e-mailach z portalu); przejęcie konta panelu | Turnstile, honeypot, rate limit; DKIM/SPF/DMARC dla domeny wysyłkowej (Resend już ma DKIM); Supabase Auth + MFA + Cloudflare Access (SSO Microsoft 365 Aura lub kod jednorazowy) |
| **T**ampering | Manipulacja składką/grupą ryzyka w żądaniu; podmiana treści (supply chain npm) | Przeliczenie na serwerze z wersjonowanego cennika; lockfile, pinowane akcje CI, SRI nie dotyczy (brak CDN), CSP |
| **R**epudiation | Spór o udzieloną zgodę marketingową | `consents` z wersją klauzuli, znacznikiem czasu, `ip_hash`, user agent; `lead_events` jako ślad audytowy zmian statusów |
| **I**nformation disclosure | Wyciek leadów przez klucz anon (jak w „aurabroker”), przez logi, błędy, bundle panelu; enumeracja adresów newslettera | Brak klucza Supabase w przeglądarce; RLS + REVOKE; logi bez PII; strony błędów bez szczegółów; panel renderowany serwerowo pod ochroną Access; `202` zawsze dla newslettera |
| **D**enial of service | Spam leadów, zasypywanie cudzych skrzynek potwierdzeniami, koszty Workers/Resend | Rate limit CF + binding; limit potwierdzeń per e-mail/24 h; limity rozmiaru ciała; alert kosztowy Cloudflare |
| **E**levation of privilege | Nadanie sobie roli admina; funkcje `SECURITY DEFINER` dla `anon`; mutowalny `search_path` | Trigger guard na `admin_users`; brak funkcji dla `anon`; `set search_path`; `force row level security`; cotygodniowy Security Advisor |

### 4.2 Nagłówki bezpieczeństwa

Ustawiane w aplikacji (middleware), żeby były wersjonowane razem z kodem; HSTS dodatkowo na poziomie strefy Cloudflare.

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
  report-to csp-endpoint
Reporting-Endpoints: csp-endpoint="/api/csp-report"
Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=(), payment=(), usb=(), interest-cohort=()
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Resource-Policy: same-origin
X-Frame-Options: DENY
```

Uwagi: Turnstile wymaga `challenges.cloudflare.com` w `script-src`/`frame-src`/`connect-src`. Zaraz (tagi po zgodzie) ładuje się z tej samej domeny (`/cdn-cgi/zaraz/`) – jego skrypty inline muszą dostać nonce (ustawienie Zaraz) [do weryfikacji]. Jeśli jakaś biblioteka UI wymusi inline'owe atrybuty `style`, dopuszczalnym kompromisem jest `style-src 'self' 'unsafe-inline'` (ryzyko istotnie mniejsze niż dla skryptów); dla `script-src` kompromisu nie ma. Polityka startuje jako `Content-Security-Policy-Report-Only` na stagingu przez tydzień, potem egzekwowana.

### 4.3 Ustawienia Cloudflare do zmiany względem audytu

| Ustawienie | Stan z audytu | Docelowo | Plan |
|-----------|---------------|----------|------|
| SSL/TLS mode | Full | **Full (strict)** – wszystkie originy to Cloudflare (Workers/Pages), więc bez ryzyka | Free |
| Minimalna wersja TLS | **1.0** | **1.2** (1.3 pozostaje włączone) | Free |
| HSTS | wyłączony | etapami: `max-age=86400` → 6 mies. → 2 lata + `includeSubDomains` + `preload` po potwierdzeniu, że każda subdomena (`app.`, `crm.`, `portal.`, `tax.`, `ergo.`, `konsultacja.`, `autodiscover`) serwuje HTTPS | Free |
| Always HTTPS, HTTP/3, Brotli | włączone | bez zmian | Free |
| Early Hints | wyłączone | **włączone** (aplikacja wysyła `Link: rel=preload` dla CSS i fontów) | Free |
| 0-RTT | wyłączone | pozostaje wyłączone (ryzyko replay dla POST) | – |
| Security level | medium | medium; dodatkowo reguła WAF: challenge dla `POST /api/*` bez nagłówka `Origin` równego domenie | Free |
| WAF managed rules | Free Managed Ruleset | bez zmian; pełny zestaw dopiero na Pro (sekcja 1.3) | Free → Pro |
| Rate limiting | brak | **1 reguła**: `POST /api/*` > 10 żądań/10 s z IP → managed challenge | Free |
| Cache TTL / reguły | 4 h, brak page rules | Cache Rules z sekcji 3.3 | Free |
| Turnstile | brak | widget „managed” na każdym formularzu, osobne klucze dla stagingu i produkcji | Free |
| Bot management / AI crawlers | `ai_bots_protection: block`, `ai_search` wyłączone | zgodnie z sekcją SEO/GEO: dopuścić kategorie *AI search* i *AI user/agent*, utrzymać blokadę *training* | Free |
| Trasa `beautypolisa.eu/*` → `aura-analytics-collector` | aktywna | **usunięta**; kolektor wywoływany przez Service Binding (sekcja 7) | – |
| Worker `security-headers` | bez trasy | pozostaje bez trasy w tej strefie – nagłówki ustawia aplikacja | – |
| Cloudflare Access | brak | aplikacja Access dla `beautypolisa.eu/panel*` i `staging.beautypolisa.eu/*` | Free |
| DNS apex / www | **brak rekordów** | apex → custom domain Workera; `www` → 301 na apex (Redirect Rule) | Free |

### 4.4 Ochrona formularzy

Pięć niezależnych warstw, każda tania: Turnstile (dowód „nie-bot”), rate limit Cloudflare (ochrona Workera i kosztów), rate limit w Workerze (per IP + produkt, drobniejszy), honeypot (odsiewa proste boty bez kosztu challenge), walidacja Zod po stronie serwera (jedyna wiążąca; walidacja w kliencie służy tylko UX). Do tego limity rozmiaru ciała, `Origin`/`Sec-Fetch-Site` sprawdzane w route handlerze, a dla server actions w panelu – wbudowana ochrona CSRF Next.js plus sesja Supabase w ciasteczku `HttpOnly; Secure; SameSite=Lax`.

### 4.5 Zarządzanie sekretami

- Sekrety Workera (`SUPABASE_SERVICE_ROLE_KEY`, `TURNSTILE_SECRET_KEY`, `RESEND_API_KEY`, `SENTRY_DSN`) wyłącznie przez `wrangler secret put` (osobno dla `staging` i `production`); lokalnie `.dev.vars` w `.gitignore`.
- **Brak sekretów w repozytorium** – `gitleaks` w CI, włączone GitHub secret scanning z push protection.
- Klucz serwisowy Supabase istnieje tylko w Workerach `beautypolisa-web` i `beautypolisa-jobs`. Do przeglądarki nie trafia żaden klucz Supabase (także anon) – aplikacja nie ma klienta Supabase po stronie przeglądarki; panel używa sesji serwerowej.
- Osobny klucz API Resend tylko do wysyłki z domeny portalu; osobne klucze Turnstile per środowisko.
- Rotacja: co 6 miesięcy i natychmiast po incydencie lub odejściu osoby z dostępem; procedura w runbooku.
- Dostęp do GitHub Environments `production` wymaga akceptacji drugiej osoby.

### 4.6 Polityka zależności

`pnpm` z `--frozen-lockfile` w CI; ustawienie minimalnego wieku publikacji pakietu (np. 7 dni) przed instalacją nowej wersji – ochrona przed skompromitowanymi wydaniami; Renovate w trybie tygodniowych, grupowanych PR z automatycznym scaleniem tylko dla patchy po zielonym CI; `pnpm audit --audit-level=high` blokuje PR; akcje GitHub przypięte do SHA; zero skryptów z CDN (Chart.js i confetti z obecnych stron znikają – wykresy w panelu z lekkiej biblioteki w bundle panelu, bez konfetti).

### 4.7 Minimalizacja i retencja PII (RODO)

| Dane | Podstawa prawna [do potwierdzenia z IOD] | Retencja [założenie] | Mechanizm |
|------|------------------------------------------|----------------------|-----------|
| Lead (kontakt + kontekst produktu) | art. 6 ust. 1 lit. b – działania przed zawarciem umowy na żądanie osoby | 12 mies. od ostatniego zdarzenia, jeśli brak konwersji; po konwersji 90 dni od przekazania do CRM Aura, potem anonimizacja w portalu | `anonymize_lead()` z Cron (codziennie) |
| Zgody marketingowe | art. 6 ust. 1 lit. a | do wycofania + 3 lata jako dowód (pole `granted=false` z datą) | wpis w `consents`, link rezygnacji w każdej wiadomości |
| Newsletter | art. 6 ust. 1 lit. a, double opt-in | do wypisania; niepotwierdzone usuwane po 7 dniach | Cron |
| Zgłoszenie szkody | art. 6 ust. 1 lit. b/f | 90 dni po `closed` | `anonymize`; formularz instruuje, by nie wpisywać danych zdrowotnych osób trzecich (art. 9) |
| Hash IP w zgodach, logi bezpieczeństwa | art. 6 ust. 1 lit. f | 12 mies. | sól dnia uniemożliwia odtworzenie IP po czasie |

Prawo do usunięcia: w panelu akcja `anonymizeLead` (zapis w `lead_events`), a dla zgłoszeń e-mailowych – wyszukanie po adresie przez `email_normalized` przed anonimizacją. Administrator danych do wskazania (Aura Consulting vs Aura Expert – w audycie różne podmioty w różnych produktach), umowy powierzenia: Supabase (region eu-west-1), Cloudflare, Resend, Sentry; polityka prywatności w `/rodo`.

### 4.8 Logowanie bez PII

Logi strukturalne JSON: `{requestId, route, status, durationMs, product, outcome, leadId}` – **nigdy** e-mail, telefon, treść wiadomości, ciało żądania ani pełne IP. Sentry: `sendDefaultPii: false`, `beforeSend` usuwa ciało żądania, nagłówki `cookie`/`authorization` i pola formularzy; maskowanie w Session Replay (jeśli włączony – domyślnie wyłączony). Logi Workers (observability) z próbkowaniem 100 % dla błędów i 10 % dla sukcesów.

### 4.9 Kopie zapasowe i odtwarzanie

Supabase Pro: kopie dzienne (retencja wg planu [do weryfikacji]); PITR jako dodatek (~100 USD/mies. [hipoteza]) **nie** w v1 – leady mają drugą kopię w skrzynce zespołu, a cenniki i treść są w repo (odtwarzalne z migracji i seedów). Co kwartał test odtworzenia kopii do projektu tymczasowego (RTO ≤ 4 h). Migracje wyłącznie przez pliki w `supabase/migrations` – zmiany w dashboardzie są zabronione na produkcji.

### 4.10 Playbook incydentu (skrót)

1. **Wykrycie** (alert Sentry/uptime/koszty/Advisor) → osoba dyżurna potwierdza w ≤ 30 min.
2. **Zatrzymanie**: w zależności od typu – `wrangler rollback` do poprzedniej wersji; reguła WAF „challenge all” na `/api/*`; rotacja klucza serwisowego i Resend; wyłączenie formularza flagą środowiskową (strona pokazuje kontakt awaryjny).
3. **Ocena wycieku PII**: zakres (tabele, okres), liczba osób – zapytania na kopii; decyzja IOD o zgłoszeniu do UODO w 72 h.
4. **Naprawa i weryfikacja** na stagingu, wdrożenie kanarkowe.
5. **Post-mortem** w repo (`docs/incydenty/`) bez PII, z działaniami naprawczymi i terminami.

### 4.11 Słabości obecnej architektury (z audytu) i jak nowa je usuwa

| Słabość z `01-audyt-stanu-obecnego.md` | Nowa architektura |
|------------------------------------------|-------------------|
| Publiczny portal na kluczu anon współdzielonej bazy „aurabroker” (158 tabel, CRM) | Nowy projekt Supabase tylko dla portalu; klucz anon nieużywany w przeglądarce; blast radius ograniczony do danych portalu |
| Skrypt anti-inspect czyszczący `document.body` | Usunięty; bezpieczeństwo zapewniają serwer, RLS i CSP, nie ukrywanie kodu |
| Panel admina w publicznym bundle, autoryzacja z `bp_profiles.is_admin` w kliencie | Panel pod `/panel` renderowany serwerowo, kod ładowany tylko dla tych tras, autoryzacja w RLS + triggerze guard, przed tym Cloudflare Access |
| `bp_analytics`: INSERT z klienta bez limitów | Zdarzenia emitowane z serwera przez Service Binding, bez PII, bez zapisu z przeglądarki |
| Formularze bez CAPTCHA/rate limitu, walidacja tylko w kliencie | Pięć warstw z sekcji 4.4 |
| Granty DELETE/UPDATE/TRUNCATE dla `anon`/`authenticated` | `REVOKE ALL` + `ALTER DEFAULT PRIVILEGES`; TRUNCATE niemożliwy |
| 21 funkcji `SECURITY DEFINER` dla `anon`, mutowalny `search_path` | Jedna funkcja pomocnicza, tylko dla `authenticated`, z zamrożonym `search_path` |
| Skrypty z CDN, `user-scalable=no`, Google Fonts zewnętrzne | Brak CDN, zoom dozwolony, fonty self-hosted |
| Treść zaszyta w HTML/JS, duplikaty plików | MDX/JSON w repo z walidacją, jedno źródło prawdy |

---

## 5. Stabilność

### 5.1 Bramki CI

Każdy PR musi przejść: `typecheck` (TS strict), `lint` (ESLint + reguły bezpieczeństwa, np. zakaz `dangerouslySetInnerHTML` poza whitelistą), testy jednostkowe (Vitest) dla `packages/pricing` – pełna macierz grup ryzyka × sum × klauzula × wielkość zespołu z liczbami z briefu oraz przypadki brzegowe (gr. 4, zespół 9), testy schematów Zod i walidacji treści, build OpenNext, `size-limit` na trasach `/`, `/ubezpieczenia/oc-beauty`, `/kalkulator/oc`, smoke Playwright na podglądzie (nawigacja, formularz z testowym kluczem Turnstile, 404, nagłówki bezpieczeństwa), Lighthouse CI (3 przebiegi mobile, budżety LCP/INP/CLS/TTFB i wagi zasobów).

```yaml
# .github/workflows/ci-cd.yml (skrót; wersje akcji przypięte do SHA w realnym pliku)
name: ci-cd
on:
  pull_request:
  push: { branches: [main] }
concurrency: { group: ${{ github.workflow }}-${{ github.ref }}, cancel-in-progress: true }
permissions: { contents: read, pull-requests: write }

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<sha>
      - uses: pnpm/action-setup@<sha>
      - uses: actions/setup-node@<sha>
        with: { node-version-file: .nvmrc, cache: pnpm }
      - run: pnpm install --frozen-lockfile
      - run: pnpm audit --audit-level=high
      - run: pnpm typecheck && pnpm lint
      - run: pnpm test --coverage            # pricing, schematy, walidacja treści MDX/JSON
      - run: pnpm build:cf                    # opennextjs-cloudflare build
      - run: pnpm size-limit                  # budżety JS per trasa

  preview:
    needs: verify
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    environment: staging                      # sekrety stagingu, baza stagingowa
    steps:
      - run: pnpm wrangler versions upload --env staging --message "pr-${{ github.event.number }}"
        # wynik: adres podglądu wersji; komentarz w PR
      - run: pnpm playwright test --config=playwright.smoke.ts   # BASE_URL = adres podglądu
      - run: pnpm lhci autorun                                   # lighthouserc.json z budżetami

  deploy-production:
    needs: verify
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production                   # wymagana akceptacja drugiej osoby
    steps:
      - run: supabase db push --linked        # migracje; token i hasło z sekretów środowiska
      - run: pnpm wrangler versions upload --env production
      - run: pnpm wrangler versions deploy --env production -y   # kanarek: ~10 % ruchu na nową wersję
      - run: pnpm playwright test --config=playwright.smoke.ts   # BASE_URL=https://beautypolisa.eu
      - run: pnpm wrangler versions deploy --env production -y   # 100 % po zielonym smoke
```

Składnia podziału ruchu w `wrangler versions deploy` – do potwierdzenia z aktualną dokumentacją Wranglera na etapie implementacji.

### 5.2 Środowiska

| Środowisko | Worker / adres | Baza | Dostęp |
|-----------|----------------|------|--------|
| Podgląd per PR | wersja Workera `beautypolisa-web-staging` z adresem podglądu wersji | Supabase `beautypolisa-staging` (plan Free wystarczy) | Cloudflare Access |
| Staging | `beautypolisa-web-staging` → `staging.beautypolisa.eu` | jw. | Cloudflare Access, `X-Robots-Tag: noindex` |
| Produkcja | `beautypolisa-web` → `beautypolisa.eu` | Supabase `beautypolisa-prod` (Pro) | publiczny; `/panel` za Access |

Podglądy nie mogą współdzielić bindingów produkcyjnych – dlatego osobny Worker stagingowy z własnymi sekretami, a nie podgląd wersji Workera produkcyjnego.

### 5.3 Wdrożenia stopniowe i rollback

Workers Versions: `versions upload` tworzy wersję bez ruchu; `versions deploy` dzieli ruch między maks. dwie wersje. Wdrożenie kanarkowe ~10 % na 5–10 min ze smoke testem, potem 100 %. Znana pułapka: podczas podziału ruchu HTML z wersji B może odwoływać się do assetów, których nie ma w wersji A → 404 fragmentów JS; środek zaradczy: **version affinity** (przypięcie użytkownika do wersji ciasteczkiem/nagłówkiem) i krótki czas trwania podziału. Rollback: `wrangler rollback` do dowolnej z ostatnich wersji (limit podniesiony do 100) w sekundy; migracje bazy są wyłącznie addytywne (expand/contract), żeby rollback kodu nie wymagał rollbacku schematu.

### 5.4 Monitoring i alerty

- **Uptime zewnętrzny** (darmowy plan Better Stack/UptimeRobot [założenie]): `GET /` (oczekiwany fragment HTML) i `GET /api/health` co 1–5 min, z dwóch regionów; alert e-mail + kanał Teams (M365).
- **Cloudflare**: analityka ruchu i WAF, zdarzenia rate limit, metryki Workers (błędy, p99, CPU), powiadomienia o przekroczeniu budżetu żądań; dashboard Analytics Engine z własnym RUM (Web Vitals wysyłane `sendBeacon` – bez PII, bez zgody, bo bez identyfikatorów trwałych [hipoteza prawna – do weryfikacji]).
- **Sentry** z maskowaniem PII (4.8), alert przy > 5 błędach 5xx/5 min na `/api/leads`.
- **Outbox**: alert, gdy `pending` > 20 przez 15 min lub pojawi się `failed`.
- **Supabase**: alerty zużycia, cotygodniowy przegląd Security/Performance Advisor, alert na nowe funkcje `SECURITY DEFINER`.
- **Turnstile**: wskaźnik odrzuceń (nagły wzrost = atak lub błąd integracji).

### 5.5 SLO i runbook

| SLO | Cel | Okno | Reakcja po przekroczeniu |
|-----|-----|------|--------------------------|
| Dostępność stron publicznych | 99,9 % | 30 dni | zamrożenie wdrożeń poza poprawkami do końca okna |
| Sukces `/api/leads` (bez 4xx) | ≥ 99,5 % | 30 dni | analiza przyczyn w post-mortem |
| Dostarczenie e-maila zespołowi | ≤ 5 min dla 99 % leadów | 7 dni | przegląd outboxu, kontakt z Resend |
| LCP p75 mobile | ≤ 2,0 s | 28 dni (CrUX) | blokada PR pogarszających budżet |

Runbook (`docs/runbook.md`): procedury dla „5xx na API”, „Resend nie wysyła”, „Supabase niedostępny”, „podejrzenie spamu/ataku”, „rollback”, „rotacja sekretów”, „odtworzenie kopii”, „żądanie usunięcia danych”, „aktywacja nowej wersji cennika” – każda z krokami, poleceniami i właścicielem.

---

## 6. Wydajność i responsywność

**Techniki**

- RSC domyślnie; komponenty klienckie tylko tam, gdzie jest interakcja: kalkulator (jedyna większa wyspa), formularze (małe), menu mobilne, baner zgód. Zero bibliotek UI ładowanych globalnie.
- HTML renderowany na brzegu z cache danych (3.3); streaming RSC, żeby pierwszy bajt i LCP nie czekały na wolniejsze fragmenty.
- Obrazy: `next/image` z własnym loaderem do Cloudflare Image Transformations (`/cdn-cgi/image/width=…,format=auto/…`), `sizes` dopasowane do layoutu, `priority` tylko dla LCP; logo jako SVG. Fallback przy braku Image Transformations: warianty AVIF/WebP generowane w buildzie.
- Fonty: Montserrat self-hosted przez `next/font/local`, podzbiory `latin` + `latin-ext` (polskie znaki), 2–3 wagi, `font-display: swap`, preload tylko wagi używanej w nagłówku; brak Google Fonts.
- Brak skryptów firm trzecich przed zgodą; po zgodzie tagi (GA4, piksele) przez **Cloudflare Zaraz** (ładowanie po stronie Cloudflare, jedno lekkie żądanie, wbudowana obsługa zgód) – bez GTM w przeglądarce. Jeśli marketing wymaga GTM, to wyłącznie w wariancie server-side; w v1 nie.
- `Link: rel=preload` dla CSS i fontu nagłówkowego → Early Hints 103 z Cloudflare; `preconnect` tylko do `challenges.cloudflare.com` na stronach z formularzem.
- Efekt „glass widget” (z briefu) ograniczony do karty kalkulatora/CTA, `@supports (backdrop-filter)`, wyłączany przy `prefers-reduced-transparency` i `prefers-reduced-motion`; bez rozmycia na elementach animowanych przy przewijaniu (koszt GPU na słabszych Androidach).
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

Baseline frameworka (React + runtime Next.js) zajmuje istotną część budżetu JS [hipoteza: ~85–100 KB gzip], więc kod aplikacyjny na landing ma ok. 20–30 KB – stąd zakaz ciężkich zależności (daty, ikony całymi paczkami, biblioteki formularzy) poza panelem.

**Mobile-first**: projekt od 320 px w górę, siatka jednokolumnowa z progresywnym rozszerzaniem, nawigacja dolna/hamburger z dostępnym focusem, cele dotykowe ≥ 44 px, `viewport` bez blokady zoomu, testy Playwright na 360×800, 768×1024, 1440×900, kontrast WCAG AA dla palety (granat `#2a3b69`, róż `#e11d48` – róż na białym wymaga sprawdzenia kontrastu dla tekstu drobnego; szczegóły w sekcji projektowej koncepcji).

---

## 7. Integracja z istniejącą infrastrukturą

### 7.1 Trasa `beautypolisa.eu/*` → `aura-analytics-collector`

| Opcja | Zalety | Wady | Ocena |
|-------|--------|------|-------|
| A. Zostawić kolektor jako warstwę przed aplikacją (kolektor przekazuje żądania do aplikacji przez Service Binding) | brak zmian w kolektorze, spójne zbieranie dla całej Aury | każde żądanie przechodzi przez dwa Workery (opóźnienie, podwójne liczenie wywołań, trudniejsze debugowanie, zależność dostępności portalu od kodu kolektora); trasa `/*` przesłania custom domain aplikacji | odrzucona |
| **B. Usunąć trasę; aplikacja wywołuje kolektor przez Service Binding** (zdarzenia odsłon i leadów emitowane z serwera, bez PII) | jeden skok sieciowy dla użytkownika, dane nadal w tym samym zbiorze `WEB_EVENTS` z tą samą solą, kolektor pozostaje wspólny dla Aury | kolektor musi wystawiać handler akceptujący zdarzenia przez binding (kod kolektora nie był widoczny w audycie) [do weryfikacji] | **rekomendowana** |
| C. Przenieść logikę do aplikacji (bezpośredni binding do Analytics Engine `WEB_EVENTS` + KV `VISITOR_SALT`) | brak zależności od kolektora | duplikacja logiki haszowania, ryzyko rozjazdu z resztą Aury | wariant awaryjny, jeśli B niemożliwe |
| D. Wyłączyć | najprościej | utrata analityki first-party | odrzucona |

### 7.2 Worker `security-headers`

Nie podpinamy go do strefy: nagłówki (4.2) są częścią aplikacji i jej testów; podwójne przetwarzanie groziłoby konfliktami (np. dwa nagłówki CSP). Worker może dalej służyć innym strefom Aury.

### 7.3 Subdomeny

- `tax.` – treść Tax Protect przejmuje `/ubezpieczenia/tax-protect`; po uruchomieniu Redirect Rule `tax.beautypolisa.eu/*` → `https://beautypolisa.eu/ubezpieczenia/tax-protect` (301), a formularz z `tax.` zastępuje wspólny `/api/leads` (rozwiązuje też problem z audytu: `tax_wnioski` z RLS bez polityk). Dane historyczne z `tax_wnioski` – migracja jednorazowa do nowej bazy lub pozostawienie w „BEAUTY” do końca retencji [pytanie otwarte].
- `app.` (katalog salonów), `crm.`, `portal.`, `ergo.`, `konsultacja.` – pozostają; portal linkuje do nich z `rel="noopener"`; CSP `form-action 'self'` i `frame-ancestors 'none'` oznaczają, że nic z subdomen nie osadza portalu ani odwrotnie. Włączenie HSTS `includeSubDomains` wymaga potwierdzenia HTTPS na każdej z nich (4.3).
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

```jsonc
{
  "$schema": "node_modules/wrangler/config-schema.json",
  "name": "beautypolisa-web",
  "main": ".open-next/worker.js",
  "compatibility_date": "2026-10-01",
  "compatibility_flags": ["nodejs_compat", "global_fetch_strictly_public"],
  "assets": { "directory": ".open-next/assets", "binding": "ASSETS" },
  "observability": { "enabled": true, "head_sampling_rate": 0.1 },
  "vars": {
    "NEXT_PUBLIC_SITE_URL": "https://beautypolisa.eu",
    "SUPABASE_URL": "https://<projekt-prod>.supabase.co",
    "NEXT_PUBLIC_TURNSTILE_SITE_KEY": "<klucz-publiczny-widgetu>",
    "APP_ENV": "production"
  },
  // Sekrety WYŁĄCZNIE przez `wrangler secret put`:
  // SUPABASE_SERVICE_ROLE_KEY, TURNSTILE_SECRET_KEY, RESEND_API_KEY, SENTRY_DSN
  "routes": [{ "pattern": "beautypolisa.eu", "custom_domain": true }],
  "kv_namespaces": [{ "binding": "NEXT_INC_CACHE_KV", "id": "<kv-prod>" }],
  "services": [{ "binding": "ANALYTICS", "service": "aura-analytics-collector" }],
  "unsafe": {
    "bindings": [{
      "name": "LEAD_RATE_LIMITER", "type": "ratelimit", "namespace_id": "1001",
      "simple": { "limit": 5, "period": 60 }
    }]
  },
  "env": {
    "staging": {
      "name": "beautypolisa-web-staging",
      "routes": [{ "pattern": "staging.beautypolisa.eu", "custom_domain": true }],
      "vars": { "NEXT_PUBLIC_SITE_URL": "https://staging.beautypolisa.eu",
                "SUPABASE_URL": "https://<projekt-staging>.supabase.co", "APP_ENV": "staging" },
      "kv_namespaces": [{ "binding": "NEXT_INC_CACHE_KV", "id": "<kv-staging>" }],
      "services": [{ "binding": "ANALYTICS", "service": "aura-analytics-collector" }]
    }
  }
}
```

Worker `beautypolisa-jobs` ma osobny, krótki `wrangler.jsonc` z `"triggers": { "crons": ["*/5 * * * *", "15 3 * * *"] }` (retry outboxu, retencja) i tymi samymi sekretami Supabase/Resend. Układ repozytorium: `apps/web`, `apps/jobs`, `packages/pricing`, `packages/schemas`, `packages/content`, `packages/db` (migracje, typy generowane z Supabase), `supabase/`.

---

## 8. Tabela trade-offów

| Decyzja | Opcja A | Opcja B | Opcja C | Rekomendacja |
|---------|---------|---------|---------|--------------|
| Hosting | **Workers + OpenNext**: pełny Next.js (RSC, route handlers, middleware) w tej samej sieci co reszta Aury, Service Bindings, Static Assets, wersje/rollback; minus: adapter zewnętrzny, ograniczenia (middleware edge, brak wbudowanej optymalizacji obrazów) | Cloudflare Pages ze statycznym eksportem: najprostsze, ale brak renderingu serwerowego → CSP z `'unsafe-inline'` lub hashe, osobny Worker na API, a Cloudflare kieruje nowe projekty na Workers | Vercel: najlepsze DX i zero adaptera, ale dodatkowy dostawca i rachunek, dane poza Cloudflare, brak Service Binding do kolektora, podwójne CDN | **A**; na starcie implementacji sprawdzić stan `vinext` (narzędzie wskazywane przez Cloudflare dla nowych projektów Next.js) – jeśli dojrzałe, rozważyć |
| Baza | **Nowy projekt Supabase**: izolacja PII, czyste advisory, osobne klucze i kopie; koszt ~25 USD/mies. [hipoteza] | Schemat w „BEAUTY”: zero nowego kosztu, bliżej `tax_warianty`; ale klucz anon i funkcje `SECURITY DEFINER` dla `anon` są wspólne dla całego projektu, 3 błędy krytyczne w Advisorze | Pozostanie w „aurabroker”: największe ryzyko wg audytu | **A** |
| Treść | **MDX/JSON w repo**: przegląd w PR, zero dodatkowych systemów, wersjonowanie z kodem | Payload (już w `aurabroker`): edytor, ale współdzielona baza i kolejna powierzchnia ataku | Sanity/Strapi: edytor i podglądy, koszt i konto | **A**; rewizja przy >2 autorach lub >10 publikacji/mies. |
| Anty-bot | **Turnstile**: darmowy, bez ciasteczek śledzących, natywny dla Cloudflare, lepsza prywatność | reCAPTCHA v3: dojrzały, ale transfer danych do Google i obowiązki informacyjne | hCaptcha: podobny do Turnstile, kolejny dostawca | **A** |
| Analityka | **Analytics Engine (istniejący kolektor)**: first-party, bez ciasteczek, bez zgody [hipoteza prawna], spójne z Aurą; słabsze raporty marketingowe | GA4: raporty i integracja z Ads, ale wymaga zgody i obniża wydajność; dopuszczalne po zgodzie przez Zaraz | Plausible: prywatny i prosty, ale koszt i kolejny dostawca | **A** jako podstawa + GA4 przez Zaraz po zgodzie, gdy marketing tego potrzebuje |
| Kolejki | **Outbox + Cron**: zero nowych usług | Cloudflare Queues: gwarancje i DLQ, ale plan Paid i więcej komponentów | Wysyłka synchroniczna bez retry | **A** |

---

## 9. Co zrewidować przy wzroście

- **Ruch > ~50 tys. odsłon/dzień** [próg założony]: włączyć cache tagowe Next.js (D1/KV) zamiast rewalidacji czasowej, podnieść compute Supabase, rozważyć Cloudflare Pro (pełny WAF, 2 reguły rate limit) i PITR.
- **Więcej produktów/ubezpieczycieli**: model `pricing_versions` jest per produkt – nowe tabele taryf dochodzą bez zmian w leadach; schemat treści MDX ma pole `product`, więc kolejne linie to nowe pliki, nie nowy kod.
- **Wielojęzyczność**: struktura `packages/content/<locale>/…`, routing `/[locale]` i `hreflang` – nie wdrażać wcześniej, ale nie blokować (żadne slugi nie są zaszyte w kodzie komponentów).
- **Sprzedaż online**: wymaga tożsamości klienta (Supabase Auth dla klientów, nie tylko panelu), płatności przez hostowane strony operatora (brak danych kart w naszej infrastrukturze), podpisu dokumentów, obowiązków IDD przy zawieraniu umowy na odległość i prawdopodobnie PITR. To osobny projekt z własnym modelem zagrożeń – obecna architektura go nie wyklucza (oddzielny projekt Supabase, serwerowe API), ale nie jest pod niego zaprojektowana.
- **Wolumen e-maili > kilkaset/dzień**: Queues zamiast outboxu + Cron; Resend plan płatny.
- **Zespół treści**: CMS (headless) z publikacją przez webhook do rewalidacji – gdy przegląd w PR stanie się wąskim gardłem.

---

## Decyzje

1. **Next.js na Cloudflare Workers przez `@opennextjs/cloudflare`, z renderingiem HTML na brzegu i cache danych.** Uzasadnienie: pełne możliwości frameworka w infrastrukturze, którą Aura już utrzymuje; Service Binding do kolektora; wersje i rollback. Odrzucone: statyczny eksport na Pages (brak serwera → słabsza CSP, osobne API), Vercel (drugi dostawca, dane poza Cloudflare). Do sprawdzenia na starcie implementacji: dojrzałość `vinext`.
2. **Nowy, dedykowany projekt Supabase (Pro) dla portalu.** Uzasadnienie: izolacja PII od CRM i innych modułów, czyste advisory, osobne kopie; plan Free pauzuje projekty. Odrzucone: schemat w „BEAUTY” (wspólny klucz anon i funkcje dla `anon`, błędy krytyczne w Advisorze), „aurabroker” (największe ryzyko wg audytu).
3. **Brak klucza Supabase w przeglądarce; zapis leadów wyłącznie z serwera przez jedną transakcyjną funkcję SQL; `REVOKE ALL` dla `anon`/`authenticated` na tabelach z PII, `ALTER DEFAULT PRIVILEGES`.** Odrzucone: wzorzec INSERT dla `anon` z RLS (jak `bp_quotes`/`crm_lead_intake`) – działa, ale pozostawia publiczną powierzchnię zapisu bez Turnstile i rate limitu na poziomie bazy.
4. **Kalkulator liczy w przeglądarce z migawki cennika dostarczonej przez serwer; serwer przelicza przy wysyłce; cennik wersjonowany w bazie z jedną aktywną wersją na produkt.** Odrzucone: obliczenia tylko na serwerze (gorszy INP, więcej żądań), cennik zaszyty w kodzie (brak audytu zmian, wdrożenie przy każdej zmianie składki).
5. **Ścisła CSP z nonce i `strict-dynamic`, kosztem braku cache HTML na brzegu.** Odrzucone: `'unsafe-inline'` ze statycznym HTML (osłabia główną ochronę przed XSS), hashe (kruche przy zmianach frameworka).
6. **Treść jako MDX/JSON w repozytorium, walidowana Zod, przeglądana w PR; bez CMS w v1.** Odrzucone: Payload/Sanity (dodatkowa powierzchnia ataku i koszt przy niskim tempie zmian).
7. **Ochrona formularzy pięcioma warstwami: Turnstile, rate limit Cloudflare (jedna reguła Free), rate limit w Workerze, honeypot, walidacja serwerowa.** Odrzucone: reCAPTCHA (transfer danych do Google), sama walidacja (stan obecny).
8. **E-mail przez Resend z outboxem i ponowieniami z Cron Triggers; bez Cloudflare Queues.** Odrzucone: Queues (plan Paid, więcej komponentów przy małym wolumenie), wysyłka synchroniczna bez retry.
9. **Panel wewnętrzny w tej samej aplikacji pod `/panel`, renderowany serwerowo, za Cloudflare Access + Supabase Auth z MFA + RLS z tabelą ról chronioną triggerem guard.** Odrzucone: osobna aplikacja (więcej utrzymania przy 1–2 osobach – do rewizji), autoryzacja w kliencie (stan obecny).
10. **Minimalny zakres PII w leadzie; pełna ankieta ERGO Hestii poza portalem w v1; zgłoszenie szkody bez załączników.** Odrzucone: pełny wniosek online (dane wrażliwe biznesowo i zdrowotne, obowiązki, których portal informacyjny nie musi brać na siebie).
11. **Analityka first-party przez istniejący kolektor Aura wywoływany Service Bindingiem (trasa z apexu usunięta); tagi firm trzecich wyłącznie po zgodzie przez Zaraz.** Odrzucone: kolektor jako proxy przed aplikacją (dwa Workery na żądanie), GTM w przeglądarce (wydajność, zgody).
12. **Kopie dzienne Supabase Pro bez PITR w v1; RPO leadów ≈ 0 dzięki e-mailowi do zespołu.** Odrzucone: PITR od startu (~100 USD/mies. [hipoteza] nieproporcjonalny do wolumenu).
13. **Wdrożenia kanarkowe przez Workers Versions z version affinity, rollback do poprzedniej wersji; migracje bazy tylko addytywne.** Odrzucone: wdrożenia bezpośrednie 100 % (brak okna na wykrycie regresji).
14. **Nagłówki bezpieczeństwa w aplikacji, nie w Workerze `security-headers`; HSTS etapami z `preload` na końcu.** Odrzucone: natychmiastowy `preload` (nieodwracalny przy problemach z subdomenami).

## Pytania otwarte do zleceniodawcy

1. Kto jest administratorem danych osobowych portalu – Aura Consulting sp. z o.o. czy Aura Expert sp. z o.o. (audyt: różne podmioty w różnych produktach)? Kto pełni funkcję IOD i zatwierdza podstawy prawne oraz okresy retencji z sekcji 4.7?
2. Czy akceptowalny jest koszt stały ok. 30 USD/mies. (Supabase Pro + Workers Paid) [hipoteza], a Cloudflare Pro i PITR odkładamy do czasu realnej potrzeby?
3. Czy kolektor `aura-analytics-collector` może przyjmować zdarzenia przez Service Binding (opcja B w 7.1)? Potrzebny wgląd w jego kod lub kontakt z autorem.
4. Czy zespół Aura chce logować się do `/panel` przez Microsoft 365 (SSO w Cloudflare Access), czy wystarczą kody jednorazowe na e-mail + hasło i TOTP w Supabase Auth?
5. Jaki adres skrzynki zespołowej ma otrzymywać leady i zgłoszenia szkód, oraz czy leady mają być dodatkowo przekazywane do istniejącego CRM Aura (`crm.`) – jeśli tak, jakim interfejsem?
6. Co z danymi historycznymi `tax_wnioski` (1 wiersz) i `tax_warianty` (8 wierszy) w projekcie „BEAUTY” po przejęciu treści `tax.` przez portal – migracja czy pozostawienie?
7. Czy składki Tax Protect zostaną potwierdzone z Colonnade przed startem (bez tego strona pokazuje warianty sum bez kwot)?
8. Czy w v1 wysyłamy klientowi e-mail potwierdzający zgłoszenie (wymaga treści zgodnej z IDD), czy tylko powiadomienie do zespołu?
9. Czy status dystrybutora (broker vs agent) jest już ustalony – wpływa na treści informacyjne w formularzach i stopkach, a przez to na wersjonowane klauzule w `consents.text_version`?
10. Czy można wyłączyć blokadę crawlerów AI kategorii *search*/*user* w ustawieniach strefy (wymóg GEO – szczegóły w sekcji SEO/GEO), utrzymując blokadę *training*?
11. Czy przewidywana jest sprzedaż online lub wielojęzyczność w horyzoncie 12–18 miesięcy? Zmienia to priorytety z sekcji 9 (PITR, Auth dla klientów, routing językowy).
