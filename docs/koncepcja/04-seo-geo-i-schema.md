# 04 · SEO, GEO (widoczność w AI) i dane strukturalne

> Fakty o kliencie, produktach, cenach i infrastrukturze pochodzą wyłącznie z `01-audyt-stanu-obecnego.md`. Stos i architektura (Next.js App Router + RSC, Cloudflare Workers przez `@opennextjs/cloudflare`, treść jako MDX/JSON w `packages/content`, cenniki wersjonowane w Supabase) są ustalone w `02-architektura-i-bezpieczenstwo.md`; plan treści, klastry i standardy redakcyjne – w `05-strategia-tresci.md`; problemy obecnego kodu – w `03-code-review-obecnego-kodu.md`. Gotowe pliki do wklejenia leżą w `snippets/` (pkt 4.10). Wolumeny słów kluczowych są hipotezami – narzędzia keyword research były niedostępne (01, pkt 7).

## TL;DR

- Apex `beautypolisa.eu` nie ma dziś rekordu DNS, a strefa Cloudflare **blokuje wszystkie crawlery AI** (`ai_search`/`ai_user` wyłączone, `ai_training: disallow`, zarządzany robots.txt). Najtańsza i najważniejsza zmiana „GEO” to polityki Search i Agent na *Allow* oraz wyłączenie Bot Preference Sync – bez tego reszta tej sekcji nie działa.
- Architektura: huby `/ubezpieczenia`, `/dla-kogo`, `/baza-wiedzy`, 6 stron produktowych, kalkulator, `/szkoda`, `/dokumenty`. Jeden H1, self-canonical, JSON-LD komponowany na serwerze w `@graph` z trwałymi `@id`.
- Strony produktowe to `Service`, nie `Product` – składka OC wg taryfy programu zależy od grupy ryzyka i sumy, więc jedna cena dla produktu byłaby nieprawdziwa. `AggregateOffer` tylko dla OC i tylko z aktywnej wersji cennika, z której liczy kalkulator.
- `FAQPage` i `HowTo` nie dają już rich results w Google (ograniczenia z 2023 r.) – wdrażamy je dla czytelności maszynowej i cytowalności w asystentach AI.
- GEO w praktyce: treść w HTML z serwera, blok „W skrócie”, nagłówki-pytania, liczby z odesłaniem do OWU, imienny autor i data aktualizacji, spójna encja (NAP, jedno zdanie o marce), `llms.txt`, comiesięczny **ręczny** audyt 20 promptów. Nie raportujemy wymyślonych „wyników widoczności” i nie obiecujemy pozycji.
- Pomiar: GSC, Bing Webmaster, referrery AI we własnej analityce; wnioski po 30 dniach, ocena po 90.

## 0. Zakres i założenia

Portal jest informacyjno-leadowy (01, pkt 8). Priorytety zlecenia – bezpieczeństwo → szybkość → responsywność → SEO/GEO – oznaczają, że nic z tej sekcji nie może wprowadzać skryptów firm trzecich, renderowania po stronie klienta ani obejść bezpieczeństwa. SEO i GEO wynikają tu z dyscypliny: serwerowy HTML, stabilne URL-e, jedna encja, prawdziwe treści.

Dodatki do uzgodnionej mapy URL [założenie]: huby `/ubezpieczenia`, `/dla-kogo`, `/baza-wiedzy`, paginacja `/baza-wiedzy/strona/<n>`, podstrony dokumentów `/dokumenty/<slug>`, strona podziękowania `/dziekujemy` (noindex).

## 1. Architektura informacji i mapa URL

Model **hub-and-spoke**: produkt jest szprychą huba `/ubezpieczenia`, zawód – `/dla-kogo`, artykuł – `/baza-wiedzy`. Strony zawodów łączą produkty z artykułami (np. `/dla-kogo/podolog` → `/ubezpieczenia/oc-beauty` w kontekście grupy ryzyka 3). Każda strona jest osiągalna w ≤3 kliknięciach z home. Szczegółowy plan linkowania (anchory, frontmatter `related`, kontrola sierot w CI) jest w 05.

| URL | Typ strony | Intencja | Główne słowo kluczowe [hipoteza] | Typy schema | CTA |
|---|---|---|---|---|---|
| `/` | home | brandowa + informacyjna | „ubezpieczenia dla branży beauty” | Organization, InsuranceAgency, WebSite, WebPage | „Policz składkę OC”, „Zamów kontakt” |
| `/ubezpieczenia` | hub produktów | porównawcza | „ubezpieczenie salonu kosmetycznego” | CollectionPage, ItemList, BreadcrumbList | karty 6 produktów |
| `/ubezpieczenia/oc-beauty` | produkt | komercyjna | „OC kosmetyczki”, „OC salonu kosmetycznego” | WebPage, Service (+AggregateOffer), FAQPage, BreadcrumbList | „Policz składkę” → kalkulator |
| `/ubezpieczenia/tax-protect` | produkt | komercyjna | „ubezpieczenie karno-skarbowe” | Service, FAQPage, BreadcrumbList | „Zapytaj o wariant” |
| `/ubezpieczenia/utrata-dochodu` | produkt | informacyjno-komercyjna | „ubezpieczenie utraty dochodu” | Service, FAQPage, BreadcrumbList | „Zamów rozmowę” |
| `/ubezpieczenia/nnw-dzieci` | produkt | informacyjno-komercyjna | „NNW dzieci” | Service, FAQPage, BreadcrumbList | „Zamów ofertę” |
| `/ubezpieczenia/grupowe-ergo` | produkt B2B | komercyjna | „ubezpieczenie grupowe dla małej firmy” | Service, FAQPage, BreadcrumbList | „Wycena dla zespołu” |
| `/ubezpieczenia/opieka-medyczna` | produkt B2B | komercyjna | „pakiet medyczny dla pracowników” | Service, FAQPage, BreadcrumbList | „Zamów ofertę” |
| `/kalkulator/oc` | narzędzie leadowe | transakcyjna | „kalkulator OC salon kosmetyczny” | WebPage, BreadcrumbList | formularz (Turnstile) |
| `/dla-kogo` | hub segmentów | informacyjna | „ubezpieczenie dla kosmetyczki” | CollectionPage, BreadcrumbList | linki do zawodów |
| `/dla-kogo/<zawod>` (6) | landing segmentowy | informacyjno-komercyjna | „ubezpieczenie dla podologa” itd. | WebPage (`about`→Service), FAQPage, BreadcrumbList | „Policz składkę” |
| `/baza-wiedzy` (+`/strona/<n>`) | hub + paginacja | informacyjna | „ubezpieczenia beauty poradnik” | CollectionPage, BreadcrumbList | lead magnet (05) |
| `/baza-wiedzy/<slug>` | artykuł | informacyjna (long tail) | pytania użytkowników | Article, BreadcrumbList, opc. FAQPage | kontekstowe CTA |
| `/o-nas` | o firmie | E-E-A-T | „BeautyPolisa Aura Expert” | AboutPage, Organization, Person | kontakt |
| `/kontakt` | kontakt | nawigacyjna | „BeautyPolisa kontakt” | ContactPage | formularz |
| `/szkoda` | procedura | informacyjna (po sprzedaży) | „jak zgłosić szkodę z OC salonu” | HowTo, BreadcrumbList | formularz zgłoszenia |
| `/dokumenty` (+`/<slug>`) | repozytorium OWU | informacyjna | „OWU OC ERGO Hestia beauty” | CollectionPage, DigitalDocument | pobierz PDF |
| `/rodo` | prawna | – | – | WebPage | – |
| `/dziekujemy`, `/panel/*`, `/api/*` | techniczne | – | – | noindex / Disallow | – |

Strony `/dla-kogo/*` muszą mieć **własną** substancję (zabiegi z przypisaniem do grup ryzyka, typowe roszczenia, rekomendowane produkty), nie szablon z podmienionym zawodem – inaczej są cienką treścią (pkt 8).

## 2. Title, meta description, canonical, Open Graph

Sufiks `| BeautyPolisa` (14 znaków) dokleja `title.template` w `app/layout.tsx`; we frontmatter trzymamy tytuł bez sufiksu. Limity: title ≤60 znaków z sufiksem, description ≤155.

| Typ strony | Szablon title | Szablon description |
|---|---|---|
| produkt | `<Nazwa produktu> \| BeautyPolisa` | dla kogo + 1 fakt z OWU + CTA |
| zawód | `Ubezpieczenie dla <zawód> – OC i więcej \| BeautyPolisa` | ryzyka zawodu + produkty + narzędzie |
| artykuł | `<Pytanie z H1> \| BeautyPolisa` | odpowiedź w 1 zdaniu + źródło (OWU/ustawa) |
| hub | `<Nazwa huba> dla branży beauty \| BeautyPolisa` | lista zawartości + jak wybrać |
| narzędzie | `Kalkulator <czego> \| BeautyPolisa` | co wybrać + co się dostanie + „bez zobowiązań” |

Przykłady (długości sprawdzone skryptem):

| Strona | Title (≤60) | Meta description (≤155) |
|---|---|---|
| `/` | Ubezpieczenia dla branży beauty \| BeautyPolisa | Ubezpieczenia dla salonów beauty: OC zawodowe ERGO Hestia, Tax Protect, utrata dochodu, NNW dzieci, grupowe, opieka medyczna. Zamów kontakt z doradcą. |
| `/ubezpieczenia/oc-beauty` | OC dla branży beauty (ERGO Hestia) \| BeautyPolisa | OC zawodowe dla salonów kosmetycznych, fryzjerów, podologów i linergistek. Program ERGO Hestia, sumy 100–300 tys. zł, 4 grupy ryzyka. Policz składkę. |
| `/ubezpieczenia/tax-protect` | Tax Protect (Colonnade) dla salonów beauty \| BeautyPolisa | Ubezpieczenie karno-skarbowe i podatkowe dla właścicieli salonów: ochrona właściciela i zarządu oraz koszty sporu podatkowego firmy. Zapytaj o wariant. |
| `/ubezpieczenia/utrata-dochodu` | Utrata dochodu – ubezpieczenie dla beauty \| BeautyPolisa | Ubezpieczenie utraty dochodu dla kosmetologów, fryzjerów i stylistek na B2B. Świadczenie przy niezdolności do pracy, karencja, wyłączenia – po ludzku. |
| `/ubezpieczenia/nnw-dzieci` | NNW dzieci – ubezpieczenie całoroczne \| BeautyPolisa | NNW dziecka: jak porównać sumy, zakres i wyłączenia oraz czym różni się polisa szkolna od indywidualnej. Zamów ofertę dla rodziny lub zespołu salonu. |
| `/ubezpieczenia/grupowe-ergo` | Grupowe ERGO dla beauty – ochrona zespołu \| BeautyPolisa | Ubezpieczenie grupowe ERGO Hestia dla salonów beauty: ochrona życia i zdrowia pracowników oraz moduły MediOpieki. Pakiet zamiast podwyżki – zapytaj. |
| `/ubezpieczenia/opieka-medyczna` | Opieka medyczna ENEL-MED / LUX MED \| BeautyPolisa | Abonamenty medyczne ENEL-MED i LUX MED dla zespołów salonów beauty. Pakiety wg cennika programu (3–50 osób), od 51 osób wycena indywidualna. Zamów ofertę. |
| `/kalkulator/oc` | Kalkulator składki OC dla salonu beauty \| BeautyPolisa | Wybierz grupę ryzyka zabiegów i sumę gwarancyjną (100, 200 lub 300 tys. zł), a kalkulator pokaże składkę roczną OC wg taryfy programu. Bez zobowiązań. |
| `/dla-kogo/kosmetolog` | Ubezpieczenie dla kosmetologa – OC i więcej \| BeautyPolisa | Jakie ubezpieczenie potrzebuje kosmetolog: OC zawodowe na zabiegi pielęgnacyjne i inwazyjne, ochrona dochodu, Tax Protect. Przewodnik i kalkulator składki. |
| `/baza-wiedzy/czy-kosmetyczka-musi-miec-oc` | Czy kosmetyczka musi mieć OC? Przepisy, umowy \| BeautyPolisa | Czy OC jest obowiązkowe w branży beauty, kiedy wymagają go kontrahenci i co grozi bez polisy po nieudanym zabiegu. Odpowiedź doradcy z odesłaniem do OWU. |

Zasady: żadnych kwot w title – składka wg taryfy programu zależy od grupy ryzyka lub wariantu i sumy (01, pkt 3.1–3.2), więc tabela i widełki są w treści strony, nie w title; żadnych „najtańsze/najlepsze” (YMYL), nazwa ubezpieczyciela w title produktu, bo jest wyszukiwana razem z marką.

Canonical i OG:

- Self-canonical na absolutny URL bez `www`, bez slasha końcowego (`trailingSlash: false`), bez parametrów; paginacja w ścieżce, nie w `?strona=`. `metadataBase` raz w layoucie.
- `og:type` = `website` / `article` (z `article:published_time`, `article:modified_time`), `og:locale` = `pl_PL`, `og:site_name`, Twitter `summary_large_image`. Tytuł OG może być dłuższy niż title.
- Obrazy OG 1200×630 z `opengraph-image.tsx` (`ImageResponse` z `next/og`): nazwa strony na granacie `#2a3b69`, Montserrat ładowany lokalnie. **Do potwierdzenia w PoC**, czy `next/og` (Satori + resvg/wasm) działa na Workers przez OpenNext; fallback – PNG generowane w CI do `public/og/`.

## 3. Techniczne SEO w Next.js App Router

### 3.1 Metadata API i `generateMetadata`

```tsx
// app/layout.tsx
import type { Metadata } from "next";

export const metadata: Metadata = {
  metadataBase: new URL("https://beautypolisa.eu"),
  title: { default: "Ubezpieczenia dla branży beauty | BeautyPolisa", template: "%s | BeautyPolisa" },
  description: "Ubezpieczenia dla salonów beauty: OC zawodowe ERGO Hestia, Tax Protect, utrata dochodu, NNW dzieci, grupowe, opieka medyczna. Zamów kontakt z doradcą.",
  alternates: { canonical: "/" },
  openGraph: { type: "website", locale: "pl_PL", siteName: "BeautyPolisa" },
  twitter: { card: "summary_large_image" },
  robots: { index: true, follow: true, "max-snippet": -1, "max-image-preview": "large" },
};
```

```tsx
// app/ubezpieczenia/[slug]/page.tsx – params jest Promise (Next ≥15)
import type { Metadata } from "next";
import { getProduct } from "@/lib/content/products"; // czyta MDX/JSON z packages/content

type Props = { params: Promise<{ slug: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const p = await getProduct(slug);
  if (!p) return {};
  return {
    title: p.frontmatter.title, // bez sufiksu – dokleja go template
    description: p.frontmatter.description,
    alternates: { canonical: `/ubezpieczenia/${slug}` },
    openGraph: { title: p.frontmatter.ogTitle ?? p.frontmatter.title, url: `/ubezpieczenia/${slug}`, type: "website" },
  };
}
```

Title, description, FAQ i daty są polami frontmatter walidowanymi Zod w CI (02, pkt 2.5) – ten sam plik zasila HTML i JSON-LD, więc nie mogą się rozjechać.

### 3.2 `sitemap.ts` i `robots.ts`

```ts
// app/sitemap.ts – tylko opublikowane wpisy; lastModified wyłącznie z frontmatter.updatedAt
import type { MetadataRoute } from "next";
import { listProducts, listProfessions, listPublishedArticles } from "@/lib/content";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const base = "https://beautypolisa.eu";
  const fixed = ["", "/ubezpieczenia", "/kalkulator/oc", "/dla-kogo", "/baza-wiedzy", "/o-nas", "/kontakt", "/szkoda", "/dokumenty", "/rodo"];
  const [products, professions, articles] = await Promise.all([listProducts(), listProfessions(), listPublishedArticles()]);
  return [
    ...fixed.map((p) => ({ url: `${base}${p}` })),
    ...products.map((p) => ({ url: `${base}/ubezpieczenia/${p.slug}`, lastModified: p.updatedAt, priority: 0.9 })),
    ...professions.map((p) => ({ url: `${base}/dla-kogo/${p.slug}`, lastModified: p.updatedAt, priority: 0.8 })),
    ...articles.map((a) => ({ url: `${base}/baza-wiedzy/${a.slug}`, lastModified: a.updatedAt, priority: 0.6 })),
  ];
}
```

```ts
// app/robots.ts – źródło prawdy; treść docelowa w snippets/robots.txt
import type { MetadataRoute } from "next";

const BLOCKED = ["/api/", "/panel/", "/dziekujemy"];
const SEARCH_BOTS = ["Googlebot", "Bingbot", "OAI-SearchBot", "PerplexityBot", "Claude-SearchBot", "Applebot", "Amazonbot", "DuckAssistBot", "YouBot"];
const USER_BOTS = ["ChatGPT-User", "Perplexity-User", "Claude-User", "Meta-ExternalFetcher", "MistralAI-User"];
const TRAINING_BOTS = ["GPTBot", "ClaudeBot", "Google-Extended", "Meta-ExternalAgent", "Applebot-Extended", "CCBot"];
const ALLOW_TRAINING = true; // Decyzja 6 – do potwierdzenia przez zleceniodawcę

export default function robots(): MetadataRoute.Robots {
  const allow = (userAgent: string[]) => ({ userAgent, allow: "/", disallow: BLOCKED });
  return {
    rules: [
      { userAgent: "*", allow: "/", disallow: BLOCKED },
      allow(SEARCH_BOTS),
      allow(USER_BOTS),
      ALLOW_TRAINING ? allow(TRAINING_BOTS) : { userAgent: TRAINING_BOTS, disallow: "/" },
    ],
    sitemap: "https://beautypolisa.eu/sitemap.xml",
  };
}
```

`MetadataRoute.Robots` nie emituje niestandardowej dyrektywy `Content-Signal`; jeśli ma być w pliku (snippet zawiera ją jako opcję), zastępujemy `robots.ts` Route Handlerem `app/robots.txt/route.ts` zwracającym tekst. Nie wstawiamy `lastModified: new Date()` – uczy Google ignorować ten sygnał.

### 3.3 JSON-LD jako komponent serwerowy

```tsx
// components/seo/JsonLd.tsx – Server Component
import type { Graph, Thing, WithContext } from "schema-dts";

export function JsonLd({ data }: { data: WithContext<Thing> | Graph }) {
  const json = JSON.stringify(data).replace(/</g, "\\u003c"); // treść z MDX nie zamknie </script>
  return <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: json }} />;
}

// na stronie produktu – jeden @graph z węzłami o trwałych @id
// <JsonLd data={{ "@context": "https://schema.org", "@graph": [webPage(p), breadcrumb(p), service(p, pricing), faqPage(p.faq)] }} />
```

Węzły budują czyste funkcje w `lib/seo/schema/*.ts` typowane `schema-dts`. `@id` są stabilne (`https://beautypolisa.eu/#organization`, `…/oc-beauty#service`), więc artykuł wskazuje produkt przez `about`, a home – wszystkie usługi przez `makesOffer`. W CI test Playwright pobiera każdy URL z sitemapy, parsuje `application/ld+json` i sprawdza: poprawny JSON, wymagane typy dla typu strony, brak pustych wartości, zgodność pytań FAQ z HTML.

### 3.4 Core Web Vitals, obrazy, fonty

Budżet (p75, mobile): **LCP ≤ 2,5 s, INP ≤ 200 ms, CLS ≤ 0,1**, egzekwowany przez Lighthouse CI w bramkach z 02. Środki: RSC bez JS klienta poza wyspą kalkulatora i Turnstile ładowanym po pierwszym fokusie; zero skryptów firm trzecich (Chart.js, confetti i Google Fonts z obecnych stron nie są przenoszone – 03); Montserrat przez `next/font/local` (`display: swap`, dwa cięcia); `next/image` z loaderem wybranym w 02, jawne wymiary, `priority` tylko dla hero; glass widget ograniczony do karty CTA, bez animowanego rozmycia, z `prefers-reduced-transparency`; usunięty `user-scalable=no` (03). Po starcie – CrUX w GSC.

### 3.5 Paginacja bazy wiedzy

`/baza-wiedzy` to strona 1, dalej `/baza-wiedzy/strona/2`… Każda strona paginacji jest indeksowalna, ma self-canonical i title „– strona n”; bez canonical do strony 1 (ukrywa artykuły) i bez `noindex`. Strony kategorii powstają od ≥5 artykułów, wcześniej `noindex, follow`.

### 3.6 404, 410, przekierowania

`not-found.tsx` zwraca prawdziwy 404 z linkami do hubów; bez „miękkich 404”. 410 dla treści usuniętych bez następcy (route handler / `proxy.ts` zwracający `Response` 410). Przekierowania 301 ze starych `.html` są w 02, pkt 7.4 – dopisać `/index.html → /`. `tax.beautypolisa.eu` po migracji treści dostaje regułę na poziomie strefy (wykonuje się przed originem):

```txt
Cloudflare → Rules → Redirect Rules
Wyrażenie: (http.host eq "tax.beautypolisa.eu")
Akcja: Redirect, 301, cel: https://beautypolisa.eu/ubezpieczenia/tax-protect, zachowaj query string
```

Przed włączeniem sprawdzamy w GSC, które URL-e `tax.` mają ruch lub linki, i mapujemy je 1:1. Analogiczna reguła `www` → apex (wymaga proxowanego rekordu DNS dla `www`). `beautypolisa.com` z obecnego JSON-LD: 301 całej domeny, jeśli zleceniodawca ją kontroluje (pytanie 4). Zgodnie z 02 (pkt 7.1) trasa Workera `beautypolisa.eu/*` znika, więc `robots.txt`, `sitemap.xml`, `llms.txt` i kody 301/404/410 serwuje bezpośrednio aplikacja.

### 3.7 hreflang – świadomie brak

Jeden język, jeden rynek, jedna domena: samoodwołujący się `hreflang="pl"` nic nie wnosi, a błędny generuje ostrzeżenia w GSC. Zamiast tego `<html lang="pl">`, `inLanguage: "pl-PL"`, `og:locale: pl_PL`. Przy ewentualnej wersji EN hreflang wchodzi razem z `x-default`.

### 3.8 Nagłówki, linkowanie, breadcrumbs

Jeden `<h1>` = główne zapytanie (na artykułach pytanie); `<h2>` to pytania lub sekcje, `<h3>` podpunkty; nagłówki nie stylują kafelków (obecne strony używają `<h3>` do kart – 03). Linkowanie wg planu z 05: artykuł → ≥1 produkt i ≥1 zawód z opisowym anchorem, produkt → 3–5 artykułów i hub; stopka tylko do hubów i stron obowiązkowych. Breadcrumbs widoczne nad H1 i jako `BreadcrumbList`, ostatni element bez linku. Słownik pojęć `/baza-wiedzy/slownik` z kotwicami – cel linków i definicje do cytowania.

## 4. Dane strukturalne

### 4.1 Które typy i dlaczego

| Typ | Gdzie | Efekt w Google | Efekt GEO |
|---|---|---|---|
| Organization + InsuranceAgency + WebSite (`@graph`) | home, `@id` wszędzie | panel wiedzy (możliwy), logo | jednoznaczna encja marki i podmiotu |
| Service (+AggregateOffer tylko OC) | 6 produktów | brak rich result | fakty o produkcie i ubezpieczycielu do cytowania |
| FAQPage | produkty, zawody, artykuły z FAQ | rich result tylko witryny rządowe/medyczne (od 08.2023) | najłatwiej cytowany format |
| BreadcrumbList | wszystko poza home | okruszki zamiast URL | struktura serwisu |
| Article | `/baza-wiedzy/*` | karuzele zależne od jakości | świeżość i autorstwo |
| HowTo | `/szkoda` | rich result wycofany (09.2023) | uporządkowana procedura |
| DigitalDocument | `/dokumenty/*` | brak | odesłanie do źródła wiążącego |
| Person | `/o-nas`, autorzy | brak | E-E-A-T |
| VideoObject | artykuły z wideo (opcjonalnie) | wideo w wynikach | transkrypcja = cytowalny tekst |

### 4.2 Home

`schema-home.json`: `Organization` to podmiot prawny (Aura Expert sp. z o.o., adres z audytu; KRS, NIP i REGON podane przez zleceniodawcę 12.11.2026 – w `identifier` i `taxID`), `InsuranceAgency` to marka BeautyPolisa (`parentOrganization` w jedną stronę, `brand` w drugą). `contactPoint` wskazuje `/kontakt` i język `pl`; telefon i e-mail po otrzymaniu. `makesOffer` wylicza 6 usług przez `@id` – asystent czytający home dostaje pełną listę produktów z linkami. `sameAs` pominięto (adresy profili nieznane). `WebSite` bez `SearchAction`, bo na starcie nie ma wyszukiwarki w serwisie.

### 4.3 Produkty: `Service`, nie `Product`

`Product` z `Offer.price` wymaga jednej ceny i jest czytany przez Google jako oferta handlowa (merchant listing: `priceValidUntil`, `availability`). Składka OC wg taryfy programu zależy od grupy ryzyka, sumy gwarancyjnej, klauzuli ochrony prawnej i liczebności zespołu (6–8 osób ×1,25; grupa 4 i zespoły od 9 osób – wycena indywidualna na podstawie ankiety ERGO Hestii); Tax Protect ma własną taryfę wariantów (`tax_warianty`), a przy przychodach powyżej 3 mln zł – wycenę indywidualną; utrata dochodu i NNW dzieci nie mają oferty. Jedna cena byłaby fałszywa – w YMYL to ryzyko reputacyjne i regulacyjne.

`Service` (`schema-produkt-oc-beauty.json`) opisuje to, co jest prawdą niezależnie od wyceny: `provider` = ERGO Hestia, `broker` = BeautyPolisa (w schema.org `broker` to dowolny pośrednik; nie przesądza statusu z ustawy o dystrybucji – pytanie 1), `areaServed`, `audience`, `termsOfService` → strona OWU, `availableChannel` → kalkulator.

`AggregateOffer` (`lowPrice`/`highPrice`) **tylko dla OC**, bo tylko tam istnieje publiczny kalkulator z jawną tabelą składek (400–1250 zł rocznie dla grup 1–3, +92 zł klauzula ochrony prawnej – 01, pkt 3.1), a `description` mówi wprost, że to składka roczna wg taryfy programu dla grup 1–3 (grupa 4 i zespoły od 9 osób – wycena indywidualna). Warunki: wartości generowane z aktywnej wersji cennika (`pricing_versions`/`pricing_oc_tiers`, 02 pkt 2.3) – nigdy ręcznie; wersjonowanie zostaje, bo taryfa może się zmienić w czasie – nowa wersja z datą obowiązywania (`valid_from`) zmienia jednocześnie kalkulator, tabelę na stronie i `offers`. `priceRange` na `InsuranceAgency` opisywałby całą agencję, nie produkt – nie używamy.

### 4.4 `FAQPage` – uczciwie

Od sierpnia 2023 Google pokazuje FAQ w wynikach tylko dla autorytatywnych witryn rządowych i zdrowotnych – portal ubezpieczeniowy ich nie dostanie. Wdrażamy `FAQPage`, bo asystenci AI czytają JSON-LD i format pytanie–odpowiedź cytuje się najłatwiej, a schemat wymusza dyscyplinę: każde pytanie widoczne na stronie w identycznym brzmieniu, odpowiedź zgodna z OWU.

Obecne strony nie mają FAQ (kalkulator ma tylko modal „Masz pytania?”; `tax-protect.html`, `life.html`, `medical.html` to opisy), więc `schema-faq-oc-beauty.json` zawiera 7 **zaproponowanych** pytań z odpowiedziami zbudowanymi z faktów audytu. Status: **do weryfikacji merytorycznej** – zwłaszcza pytanie 1 (obowiązek OC – przegląd prawny) i 2 (zakres – zgodność z OWU programu WA50/003353/24/A); w pytaniu 6 kwoty są sztywne (taryfa programu) i generowane z aktywnej wersji cennika, nie przepisywane. FAQ pozostałych produktów powstaje w ramach 05 po dostarczeniu materiałów.

### 4.5 `BreadcrumbList`, `Article`, `HowTo`, pozostałe

`schema-breadcrumb.json` – trzy poziomy, generowane z tej samej struktury tras co widoczne okruszki.

`Article`: docelowo `author` = `Person` z `name`, `jobTitle` (uprawnienia, wpis KNF – [do potwierdzenia]), `url` do bio na `/o-nas`, `sameAs` (LinkedIn), opcjonalnie `reviewedBy`. Audyt nie wskazuje osób, więc **`schema-artykul.json` przyjmuje wariant minimalny z autorem-organizacją** – do podmiany po wskazaniu autorów (pytanie 3). Szablon węzła:

```json
{
  "@type": "Person",
  "@id": "https://beautypolisa.eu/o-nas#<slug-osoby>",
  "name": "<imię i nazwisko – do uzupełnienia>",
  "jobTitle": "<stanowisko / uprawnienia – do uzupełnienia>",
  "worksFor": { "@id": "https://beautypolisa.eu/#organization" },
  "sameAs": ["<profil LinkedIn – do uzupełnienia>"]
}
```

Daty z frontmatter (`updatedAt` zmienia się tylko przy zmianie merytorycznej – zasada z 05), widoczne na stronie; `image` = obraz OG; `headline` ≤110 znaków.

`HowTo` (`schema-howto-szkoda.json`): 6 kroków z kotwicami `#krok-n` zgodnymi z nagłówkami `/szkoda`; kroki ogólne i ostrożne (dokumentacja, nieuznawanie roszczenia bez zgody ubezpieczyciela, zgłoszenie, dokumenty, współpraca z likwidatorem, archiwizacja pod kątem 3-letniej szkodowości we wniosku). **Terminy zgłoszenia i kanał bezpośredni do ERGO Hestii do uzupełnienia z OWU** – nie wpisujemy niezweryfikowanej liczby dni. Rich result HowTo Google wycofał w 2023 r.

`VideoObject` tylko gdy powstaną filmy (pkt 5.7): `transcript` na stronie jest dla GEO ważniejszy niż sam obiekt.

### 4.6 Walidacja

Przed wdrożeniem: Schema Markup Validator (poprawność słownika) i Rich Results Test (kwalifikowalność – dla `Service`/`FAQPage` pokaże „brak elementów”, co jest oczekiwane). W CI – test z pkt 3.3; `schema-dts` łapie literówki w nazwach właściwości. Po starcie – raporty „Ulepszenia” w GSC. Zasada nadrzędna: **schemat opisuje tylko to, co widać na stronie** – ukryte FAQ, inny autor niż na stronie czy cena w schemie bez ceny w treści to naruszenie wytycznych Google.

### 4.7 Pliki w `snippets/` i „Do uzupełnienia”

| Plik | Zawartość | Status |
|---|---|---|
| `robots.txt` | wzorzec dla `robots.ts`/Route Handlera, bloki search/user/training | gotowy; blok training wg Decyzji 6 |
| `llms.txt` | marka, produkty, zawody, dokumenty, kontakt, zasady cytowania (PL) | gotowy; linkowane strony muszą istnieć na starcie |
| `schema-home.json` | Organization, InsuranceAgency, WebSite, WebPage | gotowy; brak sameAs/telefonu |
| `schema-produkt-oc-beauty.json` | Service + AggregateOffer | gotowy; `offers` wg taryfy programu, generowane z aktywnej wersji cennika |
| `schema-faq-oc-beauty.json` | FAQPage, 7 pytań | odpowiedzi do weryfikacji merytorycznej |
| `schema-artykul.json` | Article (autor-organizacja) | autor do podmiany na Person |
| `schema-breadcrumb.json` | BreadcrumbList, 3 poziomy | gotowy |
| `schema-howto-szkoda.json` | HowTo, 6 kroków | terminy z OWU do uzupełnienia |

Pola celowo pominięte (fakt nieznany – bez wartości zastępczych): `telephone`/`email`; `sameAs` (LinkedIn, Facebook, Instagram, YouTube, wizytówka Google, rejestr KNF); `foundingDate`, `founder`, `openingHoursSpecification`, `geo`; `author` jako `Person` i `reviewedBy`; `url`/`sameAs` ubezpieczycieli w `provider`; adresy plików OWU dla `termsOfService`/`DigitalDocument` (program WA50/003353/24/A, OWU Colonnade 25.01.2023) i zgoda na publikację; plik logo pod `/images/logo-beautypolisa.png` (w repo `BeautyPolisa_logo_podstawowe_poziome.png`); terminy zgłoszenia szkody w HowTo; prawdziwe daty i obrazy artykułów.

## 5. GEO – widoczność w asystentach AI

### 5.1 Dostęp crawlerów: zmiany w Cloudflare

Stan (01, pkt 6): `ai_bots_protection: block`, `ai_training: disallow`, `ai_search: disabled`, `ai_user: disabled`, `is_robots_txt_managed: true`; od 15.09.2026 Cloudflare domyślnie blokuje Training i Agent dla stref Free (01, pkt 7). Docelowo (nazwy wg dokumentacji Cloudflare: **Security → Settings → Bot traffic → AI Crawler and Agent access policies**: Search / Agent / Training; **AI Crawl Control**):

| Ustawienie | Obecnie | Docelowo | Dlaczego |
|---|---|---|---|
| Polityka **Search** | zablokowana | **Allow** | OAI-SearchBot, PerplexityBot, Claude-SearchBot, Applebot indeksują i cytują z linkiem – to cel GEO |
| Polityka **Agent** | zablokowana | **Allow** | ChatGPT-User, Perplexity-User, Claude-User pobierają stronę, gdy użytkownik pyta; blokada = odpowiedź z cudzych źródeł |
| Polityka **Training** | Disallow | **decyzja zleceniodawcy** (rekomendacja Allow – Decyzja 6) | treść marketingowo-edukacyjna ma być szeroko znana; brak przychodów z ekskluzywności |
| „Block AI bots” | block | off | duplikuje polityki i blokuje wszystkich |
| **Bot Preference Sync** (zarządzany robots.txt) | on | **off** | `robots.ts` w repo jest źródłem prawdy; Cloudflare dopisuje dyrektywy tylko gdy któraś polityka blokuje, ale wyłączamy dla przewidywalności |
| AI Crawl Control – akcje per crawler | – | Allow dla listy 5.2, monitoring naruszeń robots.txt | darmowy wgląd, kto i co pobiera |
| Bot Fight Mode / Security level | wg audytu | test | wyzwania dla IP centrów danych mogą blokować fetchery agentów; test `curl -A "<UA>"` → 200 + pełny HTML |
| SSL/TLS/HSTS | `full`, TLS 1.0, HSTS off | wg 02, pkt 4.3 | bezpieczeństwo (priorytet 1) |
| Markdown for Agents | brak (Free) | opcjonalnie przy Pro | Cloudflare konwertuje HTML→Markdown dla `Accept: text/markdown` i zachowuje JSON-LD; wygodne, niekonieczne |

Zmiany są odwracalne i bezkosztowe. Po 7 dniach sprawdzamy w AI Crawl Control, czy OAI-SearchBot/PerplexityBot/Googlebot pobrały `sitemap.xml` i strony produktowe.

### 5.2 User-agenty

| User-agent | Operator | Funkcja | Kategoria | robots.txt | Pewność nazwy |
|---|---|---|---|---|---|
| Googlebot | Google | indeks Google; zasila AI Overviews / AI Mode | wyszukiwarka | Allow | pewna |
| Google-Extended | Google | token sterujący użyciem w Gemini/Vertex i treningu; wg Google bez wpływu na ranking i AI Overviews | trening/grounding | decyzja (rek. Allow) | pewna |
| Bingbot | Microsoft | indeks Bing → Copilot | wyszukiwarka | Allow | pewna |
| OAI-SearchBot | OpenAI | indeks ChatGPT Search (cytowania) | wyszukiwarka AI | Allow | pewna |
| ChatGPT-User | OpenAI | pobranie na żądanie użytkownika | agent użytkownika | Allow | pewna |
| GPTBot | OpenAI | trening | trening | decyzja | pewna |
| PerplexityBot | Perplexity | indeks Perplexity | wyszukiwarka AI | Allow | pewna |
| Perplexity-User | Perplexity | pobranie na żądanie; operator deklaruje, że może nie respektować robots.txt | agent użytkownika | Allow | pewna; zachowanie do potwierdzenia u dostawcy |
| ClaudeBot | Anthropic | trening | trening | decyzja | pewna |
| Claude-SearchBot | Anthropic | indeks wyszukiwania Claude | wyszukiwarka AI | Allow | pewna |
| Claude-User | Anthropic | pobranie na żądanie | agent użytkownika | Allow | pewna |
| Applebot / Applebot-Extended | Apple | Siri/Spotlight; Extended steruje treningiem | wyszukiwarka / trening | Allow / decyzja | pewna |
| Amazonbot | Amazon | odpowiedzi Alexy | asystent | Allow | pewna |
| DuckAssistBot | DuckDuckGo | odpowiedzi DuckAssist | asystent | Allow | do potwierdzenia u dostawcy |
| Meta-ExternalAgent | Meta | trening | trening | decyzja | pewna |
| Meta-ExternalFetcher | Meta | pobranie na żądanie (Meta AI) | agent użytkownika | Allow | do potwierdzenia u dostawcy |
| MistralAI-User | Mistral | pobranie na żądanie (Le Chat) | agent użytkownika | Allow | do potwierdzenia u dostawcy |
| YouBot | You.com | indeks wyszukiwarki AI | wyszukiwarka AI | Allow | do potwierdzenia u dostawcy |
| CCBot | Common Crawl | publiczny zbiór do treningu wielu modeli | trening | decyzja | pewna |
| Bytespider | ByteDance | trening; słabo respektuje robots.txt | trening | ewentualna blokada przez AI Crawl Control, nie robots | pewna |

Strony dostawców nie były osiągalne z tej sesji – przed startem lista jest porównywana z ich dokumentacją i katalogiem botów Cloudflare Radar.

### 5.3 Renderowalność

Fetchery AI zwykle nie wykonują JavaScriptu. Obecny `bp-app.js` buduje DOM w kliencie, a skrypt „anti-inspect” czyści `document.body` (03) – dla asystenta strona jest pusta. W nowym portalu cała treść (opisy, FAQ, tabele, zakres składek tekstem „od–do”) jest w HTML z serwera, kalkulator ma statyczny fallback z tabelą, JSON-LD jest w odpowiedzi od pierwszego bajtu. Test akceptacyjny: `curl -A "OAI-SearchBot" https://beautypolisa.eu/ubezpieczenia/oc-beauty | grep -c "Grupa 1"` > 0; strona czytelna w Chrome bez JS; baner zgody mały i niezasłaniający treści.

### 5.4 `llms.txt`

`snippets/llms.txt` – po polsku, format llmstxt.org: H1, blockquote z jednym zdaniem o marce, sekcje „Kim jesteśmy”, „Produkty”, „Dla kogo”, „Dokumenty”, „Kontakt”, „Zasady cytowania”, `## Optional`. Uczciwie: **żaden duży dostawca nie potwierdził, że jego crawler czyta llms.txt**; to tania konwencja porządkująca opis serwisu, używana przez narzędzia agentowe. Generujemy go Route Handlerem z tego samego źródła co sitemap; `llms-full.txt` odkładamy.

### 5.5 Wzorce treści „do cytowania”

Standard każdej strony produktowej i artykułu (szczegóły redakcyjne w 05):

1. **„W skrócie”** pod H1: 3–5 zdań odpowiadających wprost na pytanie strony – fragment najczęściej trafiający do odpowiedzi AI.
2. **Nagłówki-pytania** z odpowiedzią w pierwszym zdaniu akapitu.
3. **Tabele porównawcze** (grupy ryzyka × sumy × składka roczna wg taryfy programu; sekcja 1 vs 2 Tax Protect; polisa szkolna vs indywidualna NNW).
4. **Definicje** „X to …” z linkiem do słownika.
5. **Liczby ze źródłem**: „suma gwarancyjna 100/200/300 tys. zł (warunki programu WA50/003353/24/A)”, „składka roczna wg taryfy programu, cennik obowiązujący od <data>”. Bez liczb, których nie da się przypisać do OWU, ustawy lub własnego cennika.
6. **Autor z kwalifikacjami i data aktualizacji** w widocznym bloku i w JSON-LD; recenzent przy treściach o zakresie ochrony.
7. **Jeden temat na stronę** – „OC dla podologa” to własna strona, nie akapit.

### 5.6 Spójność encji

- **NAP**: „Aura Expert sp. z o.o.” + marka „BeautyPolisa”, „ul. Bolkowska 2A/28, 01-466 Warszawa”, jeden telefon i e-mail – identyczne w stopce, `/kontakt`, `/o-nas`, JSON-LD, wizytówce Google, LinkedIn, stopkach e-maili z Resend, rejestrze KNF.
- **Jedno zdanie o marce** wszędzie (stopka, `/o-nas`, `description` w schemie, llms.txt, profile): *„BeautyPolisa to portal informacyjny Aura Expert sp. z o.o. o ubezpieczeniach dla branży beauty – OC zawodowe (ERGO Hestia), Tax Protect (Colonnade), utrata dochodu, NNW dzieci, ubezpieczenia grupowe i opieka medyczna – który edukuje i umawia kontakt z doradcą; nie sprzedaje polis online.”* Słowo „broker/agent” po rozstrzygnięciu statusu.
- **`sameAs`** w obie strony: profile linkują do domeny, schema do profili.
- **Google Business Profile** dla Aura Expert (kategoria „agencja ubezpieczeniowa”, adres jak wyżej) – jedno z niewielu źródeł o lokalnych firmach, które asystenci traktują jako pewne.
- **KRS/NIP/REGON w stopce** (KRS 0000599840, NIP 5242793544, REGON 363673048 – dane od zleceniodawcy z 12.11.2026) razem z informacją o dystrybutorze (sekcja prawna koncepcji); status (agent albo broker) i numer w rejestrze KNF – po rozstrzygnięciu.
- **Wikidata**: nie na starcie – marka nie ma niezależnych źródeł, wpis zostałby usunięty; wracamy po pierwszych publikacjach branżowych.

### 5.7 Źródła poza witryną, które cytuje AI

Audyt (01, pkt 7): w SERP dla fraz beauty-ubezpieczenia dominują CUK, Rankomat, Warta, blog Booksy i Prawo.pl, a program ERGO Hestia × Beauty Razem nie ma publicznych opisów – portal będzie źródłem pierwotnym. Plan bez astroturfingu (żadnych fałszywych opinii, kont-przebierańców, kupowania linków):

| Źródło | Co AI z niego bierze | Jak uczciwie pozyskać | Czego nie robić |
|---|---|---|---|
| Fundacja Beauty Razem | opis programu, link | wspólny komunikat, strona programu u partnera z linkiem do `/ubezpieczenia/oc-beauty`, współtworzone FAQ | wymuszać linków bez zgody |
| Wiadomości Kosmetyczne | artykuł ekspercki | pitch tematów z prawdziwymi, zanonimizowanymi danymi własnymi; autor imienny | nieoznaczone artykuły sponsorowane |
| Blog Booksy | poradnik dla salonów | propozycja aktualizacji/gościnnego tekstu „formularz zgody a OC” (Booksy już pisze o zgodach) | kopiować własne treści 1:1 |
| Grupy FB kosmetologów/fryzjerów | pytania „jakie OC” | odpowiadać imiennie, z ujawnioną afiliacją, linkiem do konkretnej odpowiedzi | udawać klientki, spamować |
| YouTube | transkrypcje | 5–10-min odpowiedzi na prompty z 5.8, z transkrypcją, osadzone z `VideoObject` | kupować wyświetlenia |
| LinkedIn | profile osób | strona firmowa, profile doradców w `sameAs`, posty-odpowiedzi | automatyzować komentarze |
| Rankomat / CUK | rankingi | występować jako cytowane źródło o specyfice beauty (komentarz ekspercki) | kupować miejsca w rankingach |
| Szkoły i szkolenia beauty | materiały dla absolwentów | bezpłatny materiał „pierwsza polisa po kursie” | uzależniać od poleceń |
| Rejestr KNF | fakt rejestracji | link w stopce do wpisu | – |

Każda wzmianka kieruje do **konkretnej** strony, nie do home.

### 5.8 Audyt promptów

Co miesiąc, tego samego dnia, jedna osoba przechodzi 20 promptów w ChatGPT (z wyszukiwaniem), Perplexity, Gemini oraz Google AI Overviews/AI Mode (jeśli dostępne w Polsce dla danego zapytania – [do potwierdzenia]). Zasady: okno prywatne, lokalizacja Polska, prompt wklejony dosłownie, zrzut całej odpowiedzi w `audyt-promptow/<RRRR-MM>/`. Wynik to **surowy log**, nie wskaźnik: jedna próbka na silnik nie jest statystyką, odpowiedzi są niedeterministyczne. Nie obiecujemy pozycji ani „udziału w odpowiedziach”.

| Nr | Prompt | Nr | Prompt |
|---|---|---|---|
| 1 | jakie ubezpieczenie OC dla kosmetologa | 11 | program OC ERGO Hestia dla branży beauty – gdzie kupić |
| 2 | ile kosztuje OC salonu kosmetycznego | 12 | ubezpieczenie karno-skarbowe dla właściciela salonu |
| 3 | czy kosmetyczka musi mieć OC | 13 | Tax Protect Colonnade – co obejmuje |
| 4 | ubezpieczenie dla podologa | 14 | jaka suma gwarancyjna OC dla gabinetu kosmetycznego |
| 5 | ubezpieczenie od utraty dochodu dla fryzjerki | 15 | czy OC kosmetyczki obejmuje zabiegi z kwasem hialuronowym |
| 6 | NNW dla dziecka – co wybrać | 16 | klientka żąda odszkodowania po nieudanym zabiegu – co zrobić |
| 7 | grupowe ubezpieczenie dla małego salonu | 17 | jak zgłosić szkodę z OC salonu kosmetycznego |
| 8 | ubezpieczenie OC dla linergistki (makijaż permanentny) | 18 | prywatne L4 dla samozatrudnionych – ile kosztuje i czy warto |
| 9 | ubezpieczenie dla stylistki paznokci | 19 | pakiet medyczny dla pracowników salonu fryzjerskiego |
| 10 | OC dla studia tatuażu | 20 | BeautyPolisa – co to jest i czy warto |

Tabela wyników (jeden wiersz = prompt × silnik × miesiąc):

| Data | Silnik | Nr | Wzmianka o BeautyPolisa | Cytowany URL beautypolisa.eu | Inne cytowane domeny | Zgodność z OWU/faktami | Zrzut | Uwagi |
|---|---|---|---|---|---|---|---|---|
| 2026-12-01 | Perplexity | 2 | nie | – | cuk.pl, rankomat.pl | częściowo | `2026-12/p02-pplx.png` | brak źródła o grupach ryzyka – temat na artykuł |

Kolumna „zgodność” jest ważniejsza niż „wzmianka”: błędna odpowiedź asystenta to sygnał braku jasnego, cytowalnego źródła – i gotowy temat.

## 6. Pomiar

- **Google Search Console**: właściwość domenowa `beautypolisa.eu` (TXT w Cloudflare; obejmie subdomeny), sitemap, raporty indeksowania, skuteczności (weryfikacja hipotez słów kluczowych), Core Web Vitals, ulepszeń.
- **Bing Webmaster Tools**: import z GSC, IndexNow (ping po publikacji z Route Handlera lub CI) – Bing zasila Copilot, koszt zerowy.
- **Własna analityka** (Analytics Engine, 02): osobny kanał dla referrerów `chatgpt.com`, `chat.openai.com`, `perplexity.ai`, `copilot.microsoft.com`, `gemini.google.com`, `claude.ai`, `you.com` oraz `utm_source=chatgpt.com`, które ChatGPT dokleja do linków. Ruch z AI Overviews jest nierozróżnialny od organicznego Google – mówimy to wprost.
- **Cloudflare AI Crawl Control**: żądania per crawler i strona – czy w ogóle jesteśmy pobierani.
- **Leady**: `landing_url`, `referrer`, `utm_*` w tabeli leadów (02) → zapytania z kanału AI bez cookies firm trzecich.
- **Raport miesięczny (1 strona)**: GSC per hub, top 10 zapytań, zaindeksowane URL vs sitemap, CWV p75, sesje i leady z AI, strony pobrane per crawler, log audytu promptów z wnioskami redakcyjnymi, błędy schematu. Bez „wskaźnika widoczności AI”.
- **Horyzont**: 0–30 dni – indeksacja i poprawność techniczna, pierwsze pobrania przez crawlery AI; 30–60 – pierwsze zapytania brandowe i długi ogon; 60–90 – które strony są cytowane i gdzie brakuje treści. Decyzje kierunkowe po 90 dniach.

## 7. Checklisty

**Przed startem**
- [ ] Cloudflare: Search/Agent = Allow, Training wg Decyzji 6, Bot Preference Sync i „Block AI bots” off; `curl -A` dla UA z 5.2 → 200 + pełny HTML.
- [ ] DNS apex i `www`; `www` → 301; reguła dla `tax.` przygotowana; decyzja o `.com`.
- [ ] `robots.txt`, `sitemap.xml`, `llms.txt` dostępne; każda strona: 1× H1, title ≤60, description ≤155, self-canonical, OG image, `lang="pl"`.
- [ ] JSON-LD: test CI zielony; Rich Results Test i Schema Markup Validator bez błędów dla home, produktu, artykułu, `/szkoda`; FAQ na stronie = FAQ w schemie; `offers` i kwoty w FAQ z aktywnej wersji cennika programu, zgodne z kalkulatorem.
- [ ] Autorzy i recenzent wskazani, bio na `/o-nas`; `/baza-wiedzy` startuje z ≥6 artykułami albo wcale.
- [ ] Lighthouse CI w budżecie na mobile; 404 zwraca 404; stare `.html` → 301; brak zoom-lock.
- [ ] GSC i Bing zweryfikowane, sitemap wysłana, IndexNow działa; wizytówka Google i profile z tym samym NAP i zdaniem o marce; `sameAs` uzupełnione.

**Po starcie (30 dni)**
- [ ] Tydz. 1: pokrycie indeksu vs sitemap, błędy indeksowania, AI Crawl Control – kto pobrał sitemap.
- [ ] Tydz. 2: CWV z danych polowych lub RUM; poprawki.
- [ ] Tydz. 4: pierwszy audyt promptów (baza), raport miesięczny, lista brakujących treści.
- [ ] Przekierowanie `tax.` po zaindeksowaniu `/ubezpieczenia/tax-protect`.

**Kwartalnie**
- [ ] Przegląd stron produktowych z aktualnymi OWU → `updatedAt`.
- [ ] Aktualizacja listy user-agentów i polityk Cloudflare wg dokumentacji dostawców.
- [ ] Hipotezy słów kluczowych vs GSC; title/description tam, gdzie CTR niski.
- [ ] Linkowanie wewnętrzne (sieroty, głębokość >3), okruszki, ponowna walidacja schematów.
- [ ] Earned mentions: co opublikowano, co cytują asystenci, gdzie luki.

## 8. Ryzyka

**Duplikacja z `tax.beautypolisa.eu` i `beautypolisa.com`.** Ta sama treść na dwóch hostach rozprasza sygnały; Google może wybrać subdomenę jako kanoniczną. Rozwiązanie: migracja, 301 z `tax.` (pkt 3.6), canonical na apex w okresie przejściowym; `.com` – 301 albo usunięcie odwołań (pytanie 4). `app.beautypolisa.eu` (katalog z `seo_pages`, 01 pkt 5.2) nie może publikować treści o ubezpieczeniach powielających portal.

**Cienka treść.** Sześć stron `/dla-kogo/*` i produkty bez oferty (utrata dochodu, NNW dzieci – 01 pkt 3.5) to kandydaci na puste szablony. Strona bez unikalnej substancji nie startuje (albo `noindex` z „wkrótce”); artykuły poniżej ~600 słów łączymy lub dopisujemy do FAQ.

**YMYL i E-E-A-T.** Ubezpieczenia to w wytycznych oceny jakości Google kategoria „Your Money or Your Life” – treści są oceniane surowiej pod kątem autora i źródeł, a błędy obniżają ocenę całej witryny. Dla zespołu: imienny autor i recenzent z kwalifikacjami na `/o-nas`; każda liczba ze źródłem; brak superlatyw; treści tworzone z pomocą AI przechodzą ten sam przegląd – odpowiada podpisana osoba; informacja o dystrybutorze i o tym, że portal nie zawiera umów, na każdej stronie produktowej (standardy w 05, wymogi IDD w sekcji prawnej). GEO wzmacnia ryzyko: asystent zacytuje błędną składkę równie chętnie jak poprawną i nie da się tego „sprostować” w modelu – dlatego cennik w schemie i FAQ jest generowany, nie przepisywany.

**Zależność od polityk dostawców AI** (nazwy botów, status llms.txt zmieniają się co kilka miesięcy) – kwartalny przegląd, brak obietnic. **Blokada na poziomie Cloudflare mimo poprawnego robots.txt** – test `curl -A` i monitoring kodów odpowiedzi per crawler są obowiązkowe.

## Decyzje

1. **Domena kanoniczna `https://beautypolisa.eu` bez `www`; `tax.` i (jeśli możliwe) `.com` → 301.** Jedna domena = jedna encja i skumulowane sygnały; audyt wskazuje niespójność `.com`. Odrzucone: `tax.` jako osobny serwis (duplikacja), `www` jako kanoniczne (niezgodne z konwencją).
2. **Brak hreflang.** Jeden język i rynek; błędny hreflang szkodzi, poprawny nic nie daje. Odrzucone: `hreflang="pl-PL"` + `x-default` „na zapas”.
3. **`Service` zamiast `Product`; `AggregateOffer` tylko dla OC i tylko z aktywnej wersji cennika.** Składka wg taryfy programu zależy od grupy ryzyka i sumy – jedna cena dla produktu byłaby fałszywa (YMYL). Odrzucone: `Product` + `Offer.price` (jedna cena zamiast tabeli taryfy, wymogi merchant listing); brak informacji o cenie (składki są sztywne i jawne w cenniku programu – rozstrzygnięte 11.11.2026).
4. **JSON-LD komponowany per strona w komponencie serwerowym, `@graph` z trwałymi `@id`, `schema-dts`, walidacja w CI.** Odrzucone: jeden globalny blok w layoucie (nie opisuje strony), Microdata (trudne w komponentach), schemat dopisywany w kliencie (niewidoczny dla fetcherów).
5. **`FAQPage` i `HowTo` mimo braku rich results.** Koszt bliski zeru przy generowaniu z frontmatter, realna wartość dla cytowań. Odrzucone: pominięcie; FAQ ukryte w schemie bez treści na stronie (naruszenie wytycznych).
6. **Crawlery: Search i Agent = Allow; Training = Allow (rekomendacja), decyzja zleceniodawcy; Bot Preference Sync off; `robots.ts` w repo jako źródło prawdy.** Cel portalu to bycie znanym i cytowanym; treść nie ma wartości ekskluzywnej; blokada treningu nie zwiększa cytowań. Odrzucone: zarządzany robots.txt Cloudflare (poza kontrolą wersji), blokada treningu jako domyślna (udokumentowany wariant w snippecie), `Disallow` dla botów ignorujących robots (egzekwowanie należy do AI Crawl Control/WAF).
7. **`llms.txt` po polsku, generowany z tego samego źródła co sitemap; bez `llms-full.txt`.** Niski koszt, porządkuje opis; brak potwierdzonego wsparcia komunikowany uczciwie. Odrzucone: pominięcie, plik utrzymywany ręcznie (rozjazd).
8. **Autor to imienna osoba z kwalifikacjami; do czasu wskazania – autor-organizacja i brak startu bazy wiedzy.** YMYL wymaga odpowiedzialności osobowej. Odrzucone: „Zespół BeautyPolisa” jako `Person`, autorzy fikcyjni.
9. **Pomiar bez „wskaźnika widoczności AI”: ręczny audyt 20 promptów z logiem, referrery AI, GSC/Bing.** Odpowiedzi AI są niedeterministyczne; metryka z jednej próbki byłaby fikcją. Odrzucone: płatne narzędzia AI-visibility na starcie (do rozważenia po 90 dniach), „pozycje w AI”.
10. **Obrazy OG z `opengraph-image.tsx` po weryfikacji w PoC na Workers; fallback PNG z CI.** Odrzucone: jeden statyczny obraz (niższy CTR z social), zewnętrzny generator (zależność).
11. **Paginacja `/baza-wiedzy/strona/<n>` indeksowalna z self-canonical; kategorie od ≥5 artykułów.** Odrzucone: canonical do strony 1, `noindex` paginacji, `?strona=`.
12. **Budżet wydajności jako warunek merge (LCP ≤2,5 s, INP ≤200 ms, CLS ≤0,1 mobile); zero skryptów firm trzecich poza Turnstile; glass widget tylko na karcie CTA.** Odrzucone: pomiar „po fakcie”, przeniesienie Chart.js/confetti.

## Pytania otwarte do zleceniodawcy

1. Status dystrybutora Aura Expert sp. z o.o. – broker czy agent – i numer wpisu w rejestrze KNF? Wpływa na `broker` w `Service`, stopkę, bio autorów i słownictwo. (Podmiot i numery KRS/NIP/REGON – rozstrzygnięte decyzją zleceniodawcy z 12.11.2026.)
2. Telefon i e-mail do `ContactPoint`; adresy profili (LinkedIn, Facebook, Instagram, YouTube), stan wizytówki Google, link do wpisu w rejestrze KNF – do `sameAs`.
3. Kto jest imiennym autorem i recenzentem treści (imię, stanowisko, uprawnienia, zgoda na bio i zdjęcie)?
4. Czy zleceniodawca kontroluje DNS `beautypolisa.com`? Czy domena serwowała strony (indeksacja, linki)? Zgoda na 301 na `.eu`.
5. `tax.beautypolisa.eu`: czy jest w GSC, ma ruch/linki, kiedy przełączyć na przekierowanie?
6. Decyzja o crawlerach treningowych (GPTBot, ClaudeBot, Google-Extended, Meta-ExternalAgent, CCBot, Applebot-Extended): Allow czy Disallow?
7. Które OWU/warunki programów można opublikować na `/dokumenty` (program WA50/003353/24/A, OWU Colonnade 25.01.2023, EZwB 01/25, MA 01/25) i czy ubezpieczyciele wymagają zgody?
8. Cennik OC (400–1250 zł, klauzula 92 zł) i składki Tax Protect – rozstrzygnięte 11.11.2026: składki są sztywne (taryfa programu; Tax Protect – tabela `tax_warianty`). `AggregateOffer` i FAQ o cenie opierają się na aktywnej wersji cennika bez zastrzeżenia „do potwierdzenia” (zostaje standardowa nota: informacja nie stanowi oferty w rozumieniu art. 66 KC, zakres ochrony określają OWU).
9. Utrata dochodu i NNW dzieci: kiedy będzie oferta; strony „wkrótce” z `noindex` czy czekają?
10. Czy planowane jest wideo z doradcami (YouTube) – `VideoObject`, earned mentions?
11. Zgoda Fundacji Beauty Razem na wzajemne linkowanie i wspólny komunikat.
12. Budżet na Cloudflare Pro (Markdown for Agents, lepsza analityka botów) – opcjonalne.
