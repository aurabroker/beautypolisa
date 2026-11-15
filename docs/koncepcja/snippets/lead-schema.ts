// packages/schemas/lead.ts
import { z } from "zod";
import { isValidNip } from "./nip";
// Generowane przy budowaniu z snippets/zabiegi-oc-beauty.json (wersja 2) – krotki `as const`:
// ANKIETA_IDS – 8 pozycji a–h (g4-xx), LISTY_IDS – rekordy list nr 1 i 2 (zabieg z obu list = jeden id).
// Identyfikatorów wycofanych (zabiegi-oc-beauty-wycofane.json) tu nie ma – nowe zgłoszenie ich nie przyjmie.
import { ANKIETA_IDS, LISTY_IDS } from "../content/oc/zabiegi-ids";

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

// OC beauty (00, D43): klucze i wartości = CRM (crmaura program.ts: RODZAJE_GABINETU, LICZBA_OSOB, SUMY), żeby doradca
// przeniósł odpowiedzi do APK i wniosku w CRM bez tłumaczenia (CRM bez komunikatu pomija wartości spoza swoich list).
// Stałe: snippets/taryfa-oc-beauty.json. Taryfę (kategorię) wyznaczają rodzaje działalności – serwer liczy ją i kwotę sam,
// funkcją quoteOc = snippets/oc-skladka.js (skladkaOc); zabiegi z list nr 1 i 2 są tylko informacją i nie zmieniają składki.
export const RodzajGabinetu = z.enum(["kosmetyczny", "fryzjerski", "kosmetologiczny", "podologiczny", "masaz", "tatuaz"]);
export const LiczbaOsob = z.enum(["1-5", "6-8", "9+"]);   // osoby wykonujące zabiegi (łącznie z klientem) – pytanie APK CRM
export const KategoriaOc = z.enum(["kosmetyczny_fryzjerski", "kosmetologiczny", "pelny"]); // taryfa = zakres na certyfikacie

const bezPowtorzen = (a: readonly unknown[]) => new Set(a).size === a.length;

// Front buduje calc z ukrytych pól formularza (makieta: #lead; mapowanie – 02 §2.3): rodzaje → businessTypes, osoby → teamSize,
// suma → sumInsured (Number), prawna → legalProtection (=== '1'), ankieta → surveyProcedureIds, zabiegi → procedureIds;
// listy po przecinku (puste → []), puste osoby i suma (wycena indywidualna – K10) pomija zamiast wysyłać ''.
export const OcCalcInput = z.object({
  businessTypes: z.array(RodzajGabinetu).max(6).refine(bezPowtorzen, "Rodzaj wybrany dwa razy").default([]),
  teamSize: LiczbaOsob.optional(),
  sumInsured: z.union([z.literal(100_000), z.literal(200_000), z.literal(300_000)]).optional(),
  legalProtection: z.boolean().default(false),
  // Zabiegi wymagające ankiety ERGO Hestii (Aneks nr 5, poz. a–h): każda pozycja → cała składka do wyceny indywidualnej.
  // Do CRM idą jako dosłowne nazwy z ZABIEGI_ANKIETA (mapa id ↔ litera ↔ nazwa: zabiegi-oc-beauty.json → pozycje[].nr).
  surveyProcedureIds: z.array(z.enum(ANKIETA_IDS)).max(ANKIETA_IDS.length)
    .refine(bezPowtorzen, "Zabieg wybrany dwa razy").default([]),
  // Zabiegi z list nr 1 i 2 wybrane w wyszukiwarce kalkulatora – informacja dla doradcy, bez wpływu na składkę.
  procedureIds: z.array(z.enum(LISTY_IDS)).max(LISTY_IDS.length)
    .refine(bezPowtorzen, "Zabieg wybrany dwa razy").default([]),
}).superRefine((v, ctx) => {
  // Pola wymagane tylko tam, gdzie wynik ma być kwotą z taryfy (plan, uwaga K10; kolejność sprawdzeń jak skladkaOc w portalu –
  // dla kompletu odpowiedzi wynik = wycenaNowej w CRM, która bez sumy nie wycenia; braki to stany interfejsu portalu, F1–F5):
  // zabieg z ankiety → wycena indywidualna bez dalszych pól; bez rodzaju – brak wyniku; więcej niż 8 osób → wycena
  // indywidualna, suma opcjonalna; 1–5 i 6–8 osób → suma wymagana. Komunikaty = taryfa-oc-beauty.json → komunikaty_brakow.
  // CRM przy pierwszej polisie wymaga rodzaju, liczby osób i sumy zawsze – braki uzupełnia doradca w APK i we wniosku.
  if (v.surveyProcedureIds.length > 0) return;
  if (v.businessTypes.length === 0) {
    ctx.addIssue({ code: "custom", path: ["businessTypes"], message: "Zaznacz rodzaj działalności." });
  }
  if (!v.teamSize) {
    ctx.addIssue({ code: "custom", path: ["teamSize"], message: "Podaj liczbę osób wykonujących zabiegi." });
  } else if (v.teamSize !== "9+" && v.sumInsured === undefined) {
    ctx.addIssue({ code: "custom", path: ["sumInsured"], message: "Wybierz sumę gwarancyjną, żeby zobaczyć składkę." });
  }
});

// Kalkulator Tax Protect (02 §2.3; taryfa stała – 00, D26): 4 progi przychodu × 2 sumy gwarancyjne,
// składka za 1 spór w roku. Przychód powyżej 3 mln zł albo 2–4 spory → wycena indywidualna (bez kwoty).
// Wartości jak w makiecie design/v3/makieta-v3.html#kalkulator-tax; serwer przelicza składkę sam.
export const TaxCalcInput = z.object({
  revenueBand: z.enum(["250000", "500000", "1000000", "3000000", "powyzej-3000000"]),
  sumInsured: z.union([z.literal(50_000), z.literal(100_000)]),
  disputes: z.enum(["1", "2-4"]),
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
  // Tylko oc-beauty; opcjonalne – brak = zgłoszenie OC bez wyniku kalkulatora (temat wybrany w formularzu albo z adresu
  // ?produkt=oc-beauty). Front wysyła calc tylko po przycisku kalkulatora (#kontakt-wynik z data-produkt="oc-beauty").
  calc: OcCalcInput.optional(),
  taxCalc: TaxCalcInput.optional(),              // tylko tax-protect; opcjonalne (formularz bez kalkulatora)
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
  if (v.calc && v.product !== "oc-beauty") {
    ctx.addIssue({ code: "custom", path: ["calc"], message: "Dane kalkulatora OC tylko dla oc-beauty" });
  }
  if (v.taxCalc && v.product !== "tax-protect") {
    ctx.addIssue({ code: "custom", path: ["taxCalc"], message: "Dane kalkulatora Tax Protect tylko dla tax-protect" });
  }
  if (v.consents.marketingEmail && !v.consents.textVersions.marketingEmail) {
    ctx.addIssue({ code: "custom", path: ["consents", "textVersions", "marketingEmail"], message: "Brak wersji treści zgody" });
  }
  if (v.consents.marketingPhone && !v.consents.textVersions.marketingPhone) {
    ctx.addIssue({ code: "custom", path: ["consents", "textVersions", "marketingPhone"], message: "Brak wersji treści zgody" });
  }
});
export type LeadInput = z.infer<typeof LeadInput>;

// annualPremium – kwota do grosza (OC: round2(stawka × (6–8 osób ? 1,25 : 1) + ochrona prawna), jak skladkaProgramu w CRM).
export const QuoteResult = z.discriminatedUnion("individual", [
  z.object({ individual: z.literal(false), annualPremium: z.number(),
    category: KategoriaOc.optional(), legalProtection: z.number().optional(),   // tylko OC
    pricingVersionId: z.string().uuid() }),
  z.object({ individual: z.literal(true), category: KategoriaOc.optional(),   // OC: przy więcej niż 8 osobach
    reasons: z.array(z.enum([
    "survey_procedures", "team_over_8",          // OC: zabiegi wymagające ankiety (cała składka), więcej niż 8 osób
    "revenue_over_3m", "disputes_2_4",           // Tax Protect
  ])) }),
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
