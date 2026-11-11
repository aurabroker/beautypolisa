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
