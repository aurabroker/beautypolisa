# Przeniesienie trzech formularzy do BeautyPolisy: co mamy, czego brakuje

## Aktualizacja 13.11.2026 – kod z repozytoriów GitHub

Po pierwszej wersji tego pliku (kod kliencki pobrany z działających stron) przeczytano kod źródłowy z publicznych repozytoriów zleceniodawcy: płytkie klony, tylko odczyt, bez uruchamiania. Ta sekcja **zastępuje** werdykt, statusy braków i listę blokujących z dalszej części pliku. Decyzje W1–W9 (rozdz. 2) nadal obowiązują jako pytania; W1 ma teraz rekomendację (niżej). Szczegóły i odnośniki `repo/ścieżka:linia` są w plikach wskazanych w kolumnie „Gdzie”.

### A. Skąd co wzięto

| Repozytorium | Stan | Produkt / rola | Gdzie opisane |
|---|---|---|---|
| `gohestia` | `e186f2a`, 12.07.2026 | **ER** – ERGO Razem – Grupa Otwarta (`ergo.beautypolisa.eu`): Next.js na Cloudflare Workers, kroki 1–6, ankieta, wykluczenia, `/api/turnstile`, `/api/oferta` (Resend) | `ergo-razem-grupa-otwarta.md` § 9 i „Zamknięcie braków…”; `.json` |
| `ud` | `793a158`, 12.10.2026 | **UD** – utrata dochodu: portal Astro, funkcje `form-submit`, `wniosek-szkic`, `wniosek-przypomnienie`, `send-confirmation-email`, `contact-submit`, panel agentów | `utratadochodu-wniosek.md` §9–§10; `.json` |
| `taxbp` | `d693a7c`, 18.08.2026 | **Tax Protect** – wnioski online (`tax.beautypolisa.eu`): Next.js, funkcje `tax-wniosek`, `tax-potwierdz`, `tax-wycena` (3 kolejne – `tax-warianty`, `tax-gus`, `tax-admin` – poza repozytorium) | `tax-protect-wniosek.md`; `.json` |
| `branzowe`, gałąź `claude/cool-hypatia-ndksid` (lokalnie `ezb-najnowsza`) | `8dc9a90`, 24.09.2026 | **EZB** – ERGO Życie w Biznesie (`ergo.auraexpert.pl`): SvelteKit na Workers, `/api/wnioski`, `/api/gus`, Resend, tabele `ezb_*`. `main` ma tylko README. **Produkcja = gałąź PR #1 (`3c5086f`)**, nie najnowsza | `ergo-zycie-w-biznesie.md` §9–§12; `.json` |
| `crmaura` | `e01fbfb`, 11.11.2026 | **CRM** Aura Expert („aurabroker”, `portal.beautypolisa.eu`): punkty przyjęcia zgłoszeń, przekaz UD → CRM, ścieżka OC `/w/` → `/odnowienie` | `../14-integracja-wnioskow-z-crm.md` |
| wszystkie powyższe + `AnkietaBPEH.pdf` z repozytorium portalu + `utratadochodu.pl/owu/` | 13.11.2026 | **Dokumenty przedumowne** (OWU, karty produktu, informacja o dystrybutorze): 24 pliki, sha256 zgodne ze źródłem | `dokumenty-produktowe.md`; `../snippets/dokumenty-produktowe.json`; `../design/v3/dokumenty/` |

### B. Werdykt: czy mamy wszystko? (stan po repozytoriach)

**Wiedzy o kodzie – prawie tak. Do uruchomienia na produkcji – nie.** Wszystkie cztery formularze da się odtworzyć w makiecie w całości. Na produkcję brakuje decyzji (W1, W4, W5), zatwierdzonych tekstów prawnych i kilku dokumentów, a nie kodu.

| | Front (kroki, pola, walidacje, teksty) | Taryfy i wyliczenia | Wysyłka i backend | Teksty prawne | Dokumenty | Gotowość |
|---|---|---|---|---|---|---|
| **EZB** | kompletny (6 kroków) | kompletne: cennik `branze-2607` (01.07–31.12.2026), przeliczany też na serwerze; brak ceny wariantów MediPlanu i cennika 2027 | znany w całości: Zod, odrzucanie PESEL, `409` przy rozjeździe składki, numer `EZB-RRRR-NNNNNN`, zapis do `ezb_wnioski`, 2 e-maile + XLSX + 2 PDF. **Wnioski nie trafiają do CRM**; brak Turnstile, limitu i idempotencji | 7 zgód (wersja `2026-07-a`); administrator z kodu = Aura Expert, z3 do zastąpienia; `rodo.pdf` do korekty; akceptacja prawnika otwarta | komplet (3 OWU, 3 karty, informacja o dystrybutorze, nota RODO, szablon XLSX) | **makieta – tak; produkcja – po W1 (P1 w CRM) i tekstach prawnych** |
| **ER** | kompletny (6 kroków + 2 ekrany wykluczeń) | kompletne oprócz ceny Global Doctors; **błąd: podwójne liczenie dodatków w kroku „Oferta”** | znany: tylko 2 e-maile Resend (klient, agent), bez bazy i CRM; `/api/oferta` bez Turnstile i limitu; ankieta zostaje w przeglądarce | 14 zgód i oświadczeń dosłownie, nigdzie niezapisywanych i niewersjonowanych; `/rodo`, polityka, regulamin znane | WU ER 01/25 (komplet GO/WU002/2504) jest; **brak WU GD 02/24 i pełnomocnictwa ERGO Hestii dla Aura Expert** | **makieta – tak (całość); produkcja – nie** (R6, R8, R11, pełnomocnictwo, W1, W5) |
| **UD** | kompletny (5 kroków + 2 ankiety) | wniosek nie liczy składki; kalibracja symulacji znana (w repo 17.09, na żywo 14.10.2026) | znany: `form-submit` → `ud_clients` → wyzwalacze → klient, lead i zgłoszenie w CRM (bez danych medycznych); szkic, przypomnienia, e-maile, SMS; CORS `*`, brak deduplikacji i limitu | klauzula informacyjna jest; **zgody art. 9 i zgody marketingowej brak w formularzu, choć klauzula i polityka je zakładają**; potwierdzenia nieegzekwowane na serwerze | komplet (4 OWU + 4 karty, wersje aktywne) | **makieta – tak; produkcja – nie** (U5, P1-5 w CRM, W1) |
| **Tax** | kompletny (1 ekran, 3 sekcje + modal wyceny) | brak kwot w kodzie: składka to wiersz `tax_warianty` z bazy; taryfa znana z D26; **wzoru polisy (limity, podlimity, karencja) brak** | częściowy: 3 z 6 funkcji, schemat tabel odtworzony z zapytań; double opt-in linkiem GET; wniosek idzie e-mailem do Colonnade; Turnstile fail-open | wniosek: 3 wymagane (2 oświadczenia i zgoda `rodo`) i 2 dobrowolne, modal wyceny: 3 – dosłownie; **nota RODO pusta**, brak klauzuli art. 13 i wersji zgód | OWU (25.01.2023) i karta produktu są; **karta niezgodna z OWU** (T8) | **makieta kalkulatora i zapytania – tak; wniosek w portalu – nie przed etapem 2** (`/w/XXXXXXXXXX`, T3–T8) |

### C. Status braków

Legenda: **zamknięty** – brak wiedzy o kodzie usunięty (nie znaczy, że można uruchomić – decydują W1–W5); **częściowo** – wiedza jest, brakuje akceptacji, decyzji albo fragmentu; **otwarty** – nadal brak.

**EZB** (szczegóły: `ergo-zycie-w-biznesie.md` §10)

| # | Status | Krótko |
|---|---|---|
| E1 | zamknięty | kod `/api/wnioski` znany (§9.1); brak Turnstile, limitu i idempotencji – do portalu, nie do przeniesienia |
| E2 | zamknięty | `/api/gus` (BIR 1.1, cache 24 h) znany (§9.2); **zostaje klucz GUS** (od zleceniodawcy albo własny). [przegląd repo 13.11] Plan proxy w Workerze portalu: (1) BIR z PKD i datą zawieszenia według `branzowe/src/lib/serwer/gus.ts:59-121` (PKD informacyjne, jego błąd nie blokuje – `:121`); (2) bez klucza albo przy awarii – wykaz podatników VAT MF według `katalogbeauty/src/routes/api/regon/+server.ts:68-100` (nazwa, REGON, adres; bez PKD i daty zawieszenia); (3) tryb ręczny. Bez klucza nazwę, REGON i adres da się pobrać z wykazu VAT MF tylko dla podmiotów z wykazu podatników VAT – firma spoza wykazu (np. salon zwolniony podmiotowo bez zgłoszenia VAT) dostaje 404 i tryb ręczny (`katalogbeauty/src/routes/api/regon/+server.ts:68-78,90`); limity API MF dla zapytań z Workera – do potwierdzenia. Klucz GUS potrzebny do PKD, daty zawieszenia i firm spoza wykazu VAT. Przy przejęciu `gus.ts`: poprawić raport PKD dla jednostek `LP`/`LF` i zweryfikować na żywo `DataZawieszeniaDzialalnosci` w wyniku wyszukiwania (`ergo-zycie-w-biznesie.md` §9.2 i tabela E2 w §10) |
| E3 | zamknięty | szablony e-maili, XLSX i PDF są (§9.3, `dokumenty-produktowe.md` §3.2); kto wysyła – W4 |
| E4 | zamknięty | 3 OWU + 3 karty w `../design/v3/dokumenty/ergo-zycie-w-biznesie/` |
| E5 | częściowo | sprzeczność rozstrzygnięta na korzyść Aura Expert (z3 do zastąpienia); akceptacja prawnika i korekta `rodo.pdf` otwarte (§9.4) |
| E6 | częściowo | wersja `branze-2607` znana; brak taryfy wariantów MediPlanu i cennika 2027 (§9.8) |
| E7 | otwarty | listy PKD beauty nie ma w żadnym repozytorium (§9.8) |
| E8 | zamknięty | katalogi zakresu ochrony w repozytorium (§9.6) |
| E9 | otwarty | brak procesu deklaracji pracowników; arkusz odsyłany odpowiedzią na e-mail (§9.8) |
| E10 | częściowo | banery w repozytorium, zdjęcia branż z zewnętrznego hostingu; w portalu i tak własne (§9.7) |

**ER** (szczegóły: `ergo-razem-grupa-otwarta.md`, „Zamknięcie braków po analizie repozytorium gohestia”)

| # | Status | Krótko |
|---|---|---|
| R1 | zamknięty | kroki 2–6 i oba ekrany wykluczeń (§ 9.2–9.8) |
| R2 | częściowo | pytania i reguły dosłownie (każde „TAK” wyklucza); brak akceptacji ERGO Hestii dla brzmienia w portalu i pytań o współubezpieczonych (§ 9.3) |
| R3 | zamknięty | krok „Weryfikacja” = sam Turnstile, wynik tylko w przeglądarce (§ 9.4) |
| R4 | zamknięty | układ kroku „Oferta”, brak wariantu domyślnego, GD > 63 r.ż. wyłączony; błąd podwójnego liczenia dodatków (§ 9.5) |
| R5 | zamknięty | pola, walidacje i komunikaty formularza (§ 9.6) |
| R6 | częściowo | 14 zgód i strony prawne znane; administrator, zakres zgód w „zapytaniu” (W5), wersjonowanie i akceptacja CPOP – otwarte (§ 9.6, 9.10) |
| R7 | zamknięty | tylko 2 e-maile Resend, bez bazy i CRM (§ 9.9) |
| R8 | otwarty | ceny Global Doctors nie ma ani w kodzie, ani w OWU; strona GD obiecuje kwotę |
| R9 | zamknięty | definicje i flagi 57 zachorowań; spoza KOMFORT tylko lp 1 |
| R10 | częściowo | część wyjaśniona z WU (errata, MAKSYMALNY/KOMFORT, wiek); „od 57 zł”, „56 chorób”, „120/50 zł” (interpretacja), „Zgon rodziców i teściów” – do ERGO Hestii |
| R11 | częściowo | WU ER 01/25 jest; brak WU GD 02/24, informacji o dystrybutorze dla ER (jest ogólna z lipca 2026) i potwierdzenia aktualności (`dokumenty-produktowe.md` §3.1) |

**UD** (szczegóły: `utratadochodu-wniosek.md` §10)

| # | Status | Krótko |
|---|---|---|
| U1 | zamknięty | `form-submit` znany (§9.1); zostaje pełne DDL `ud_clients` i stan GetResponse na produkcji |
| U2 | zamknięty | `wniosek-szkic`, schemat, HMAC `sig` i `ip_hash`, retencja (§9.2); sekret poza dokumentem |
| U3 | zamknięty | przypomnienia: cron, warunki, treść, nadawca (§9.2) |
| U4 | zamknięty | e-mail potwierdzający przez wyzwalacz na `ud_clients`, SMS do doradcy; definicja wyzwalacza tylko w panelu Supabase (§9.3) |
| U5 | częściowo | klauzula jest, ale **brak zgody art. 9 i zgody marketingowej w formularzu**; potwierdzenia nieegzekwowane na serwerze (§9.4) |
| U6 | otwarty | oryginalne pytania z okresami referencyjnymi albo akceptacja skróconych pytań przez underwritera |
| U7 | częściowo | proces kalibracji znany, odświeżanie poza repozytorium; decyzja o symulacji po wniosku otwarta |
| U8 | otwarty | decyzja o polach dochodu i okresu wypłaty |
| U9 | otwarty | `/kup-online` nie ma w repozytorium z 12.10.2026. [przegląd repo 13.11] Nie ma go też w `udapp` (20.10.2026): to panel ofert, w którym klient tylko wybiera wariant przygotowany przez agenta (`udapp/app/src/routes/offer/[token]/choice/+server.js:20-61`). Adres i parametry – nadal od zleceniodawcy |
| U10 | częściowo | mechanizm zgód i analityki znany; decyzja, czyje tagi w portalu. [przegląd repo 13.11] Webhook HUB `utm-attribution` (część G) przypisuje leady do UTM, `gclid` i `fbclid` po stronie serwera, bez tagów, ale tylko na potrzeby wewnętrznego raportu HUB (zapis do `utm_attributions`, `hub/src/routes/api/webhooks/utm-attribution/+server.ts:9,81-97`). Nie wysyła konwersji do Google Ads ani Meta; raport `/google-ads` w HUB czyta dane z konta Ads (skrypt Ads → `/api/webhooks/ads-report`, `hub/src/routes/google-ads/+page.server.ts:7-8`). Pomiar konwersji kampanii wymaga tagu albo importu konwersji offline – decyzja nadal otwarta. Rekomendacja v1: atrybucja tylko w kopercie zgłoszenia i w przekazie do CRM; webhook HUB dopiero po C11 i C14 (`../14-integracja-wnioskow-z-crm.md` 6.1 pkt 4) |

**Tax Protect** – braki T1–T15 są nowe (pełna tabela: `tax-protect-wniosek.md` §11)

| # | Status | Krótko |
|---|---|---|
| T1 | otwarty (warunkowo) | kod `tax-warianty`, `tax-gus`, `tax-admin` i migracje tabel; blokuje tylko, gdyby portal nadal zapisywał do `tax_wnioski` (poza W1 A–C) |
| T2 | częściowo | taryfa z D26 znana; brak dokumentu taryfy od Colonnade z wersją i wartości `podlimit_grzywny` |
| T3 | otwarty | wzór polisy programu (pkt 4–8: limity sporów, podlimity 30% i 75%, Data Ciągłości, karencja 21 dni) |
| T4 | otwarty | nota RODO (pusta), klauzula art. 13 z przekazaniem danych Colonnade, podstawa prawna, wersje zgód |
| T5 | otwarty | analiza potrzeb (art. 8 UDU) – etap 2 `/w/XXXXXXXXXX`, decyzja W5 |
| T6 | otwarty | proces od wniosku do polisy (oferta, akceptacja, płatność, numer polisy do CRM) |
| T7 | częściowo | 6 szablonów e-maili dosłownie; kto wysyła i do kogo – W4 |
| T8 | częściowo | OWU i karta są; brak potwierdzenia aktualności i poprawionej karty (2 świadczenia spoza OWU) |
| T9 | częściowo | wzór `tax-gus` w `apiregon.md`; brak wdrożonego kodu, klucza i pola `pkd`. [przegląd repo 13.11] Pobieranie PKD jest w `branzowe/src/lib/serwer/gus.ts:104-121`, tryb bez klucza w `katalogbeauty` – jeden proxy dla EZB i Tax jak w E2; zostaje klucz, a kod wdrożonego `tax-gus` nadal nieznany |
| T10 | otwarty | Turnstile dla domeny portalu, bez fail-open, z `hostname` i `action` (W2). [przegląd repo 13.11] Wzorzec kodu: `ac/functions/api/kontakt.js` (rozdz. 2, W2); do tego klucze dla domeny portalu i zmiany kodu z W2 |
| T11 | otwarty | zasady wyceny indywidualnej (przychód > 3 mln zł, liczba sporów, sumy > 100 000 zł) |
| T12 | otwarty | kod i autoryzacja `tax-admin` (ryzyko bezpieczeństwa, nie blokuje portalu) |
| T13 | otwarty | źródła twierdzeń marketingowych (rating, pokrycie retroaktywne, PIP) |
| T14 | otwarty | los `tax.beautypolisa.eu` i 1 wiersza `tax_wnioski` (W9) |
| T15 | otwarty | potwierdzenie e-maila w portalu; usunięcie imiennego adresu z publicznego repozytorium |

**Nowe braki dokumentów** (`dokumenty-produktowe.md` §5): pełnomocnictwo ERGO Hestii dla Aura Expert (wymagane przez oświadczenie 3 w ER), WU GD 02/24, informacja o dystrybutorze UD z panelu (do porównania), dokumenty opieki medycznej, a poza trzema formularzami – OWU, karta produktu (IPID) i program WA50/003353/24/A z Aneksem nr 5 dla OC beauty. [przegląd repo 13.11] `udapp` serwuje informację o dystrybutorze UD z magazynu (`udapp/app/src/routes/dystrybutor/+server.js:9-14`), ale pliku w repo nie ma; `medaura` i `medicalaura` nie mają ani dokumentów, ani cennika opieki medycznej.

### D. Braki blokujące (do wysłania zleceniodawcy) – stan po repozytoriach

Tylko to, czego nadal brakuje. Lista z rozdz. 3 jest nieaktualna.

1. **Akceptacja W1 i zmiany w CRM przed startem przekazu.** Zatwierdzenie rekomendacji z `../14-integracja-wnioskow-z-crm.md` (wariant C, niżej) i wykonanie P1-1–P1-9 przez zespół CRM. Do tego odpowiedzi na pytania C1–C11, w tym minimum bezpieczeństwa ścieżki OC (K1–K4, K6, K9). Bez tego formularze w portalu nie mają dokąd wysyłać wniosków. [W1; E1, R7, U1 – przekaz]
2. **Teksty prawne zatwierdzone przez prawnika:**
   - administrator danych w każdym formularzu (EZB: z3 → klauzula Aura Expert, korekta `rodo.pdf`; ER: Aura Expert, CPOP czy ERGO Hestia);
   - **zgoda art. 9 na dane o zdrowiu i zgoda marketingowa dla UD**;
   - które z 14 zgód ER należą do zapytania, a które do deklaracji przystąpienia; akceptacja CPOP dla zgód 9 i 10;
   - nota RODO i klauzula art. 13 dla Tax Protect (z przekazaniem danych Colonnade);
   - regulamin portalu i wersjonowanie zgód (W3, P1-7).

   [E5, R6, U5, T4, W3]
3. **Decyzja IDD (W5):** zapytanie czy wniosek i kto robi analizę potrzeb. Dla Tax Protect: do etapu 2 tylko kalkulator i zapytanie. [przegląd repo 13.11] Repo `APK` nie zastąpi treści od compliance Aura Expert (rozdz. 2, W5). [W5, T5]
4. **Dokumenty:**
   - pełnomocnictwo ERGO Hestii dla Aura Expert (bez niego oświadczenie 3 w ER jest nieprawdziwe);
   - WU Global Doctors GD 02/24 i cena GD według wieku albo decyzja „cena przy kontakcie”;
   - od Colonnade: potwierdzenie aktualności OWU i karty Tax Protect, poprawiona karta oraz wzór polisy programu (pkt 4–8) przed publikacją liczb 30%, 75%, 21 dni i „1 spór”.

   [R8, R11, T3, T8]
5. **E-maile (W4):** kto wysyła (portal czy CRM), nadawca, `reply-to`, odbiorcy, czy Colonnade dostaje powiadomienie. Szablony EZB, ER, UD i Tax już znamy. Przy zapisie do `ud_clients` trzeba wyłączyć albo sparametryzować e-mail z marką UD. [E3, U4, T7]
6. **Turnstile dla domeny portalu** (site key i sekret na koncie Cloudflare zleceniodawcy). Według dok. 14 token weryfikuje Worker portalu, a CRM ufa mu po podpisie HMAC. [W2, T10]
7. **Klucz GUS (BIR 1.1)** od zleceniodawcy albo własny. Częściowo blokujące, bo tryb ręczny działa. [przegląd repo 13.11] Bez klucza nazwę, REGON i adres da się pobrać z wykazu podatników VAT MF (wzorzec `katalogbeauty`), ale tylko dla firm z tego wykazu (limity API MF – do potwierdzenia); klucz GUS potrzebny do PKD, daty zawieszenia i firm spoza wykazu VAT (część C, E2). [E2, T9]
8. **ER: akceptacja ankiety przez ERGO Hestię**, jeśli portal zmienia brzmienie pytań (przy przeniesieniu 1:1 – nie blokuje). [R2]
9. **Zgoda partnerów na markę i warunki w portalu:** ERGO Hestia, Lloyd’s/Leadenhall, CEU, Colonnade. [W8]
10. **Tax Protect – proces po wniosku** (oferta, akceptacja, płatność, polisa) – blokuje dopiero wniosek w etapie 2. [T6]

**Nieblokujące:**
- ER: niespójności treści (R10), błąd podwójnego liczenia dodatków (do poprawy u zleceniodawcy, portal liczy jedną funkcją na serwerze).
- EZB: lista PKD (E7), taryfa MediPlanu i cennik 2027 (E6; cennik 2027 blokuje sprzedaż od 1.01.2027), deklaracje pracowników (E9), grafiki (E10).
- UD: pytania z okresami (U6, ryzyko underwritingowe), symulacja (U7), dochód i okres (U8), `/kup-online` (U9), analityka (U10).
- Tax: T1 (przy W1 A–C), T2, T9, T11–T15.
- Dokumenty: informacja o dystrybutorze dla ER i UD (jest ogólna z lipca 2026), czyszczenie metadanych PDF/XLSX przed publikacją.

**Do zgłoszenia zleceniodawcy jako błędy działających aplikacji** (niezależnie od portalu):
- ER: podwójne liczenie dodatków; OWU najpewniej nie dochodzi w e-mailu (`owu.pdf` zamiast `OWU.pdf`); brak pliku informacji o dystrybutorze; „XIII Wydział” KRS; e-mail w adresie strony sukcesu; `/api/oferta` bez ochrony.
- EZB: produkcja z niescalonej gałęzi PR #1; e-mail z marką ERGO na dowolny adres bez Turnstile i limitu; brak escapowania HTML w szablonach.
- UD: zgoda art. 9 opisana w klauzuli, ale nieistniejąca w formularzu; GetResponse bez zgody marketingowej; PESEL jawnym tekstem; pełny rekord w logu przy braku e-maila.
- Tax: Turnstile fail-open; brak escapowania w e-mailach do brokera i Colonnade; `tax-wycena` jako przekaźnik e-maili; imienny adres pracownika partnera w publicznym repozytorium (usunąć z historii).
- CRM: patrz K1–K12 w `../14-integracja-wnioskow-z-crm.md` rozdz. 3.

**Bezpieczeństwo w repozytoriach zleceniodawcy – do zgłoszenia (nie blokuje portalu)** [przegląd repo 13.11]. Wartości kluczy pominięto. Definicje RLS są w repozytoriach tylko częściowo (migracje `crmaura` – m.in. `apk_*`; migracje `katalogbeauty` – `job_listings`), więc pozostałe skutki zależne od polityk są do potwierdzenia w projektach Supabase.
- **`beauty-crm` – wyłączony 13.11.2026 (decyzja zleceniodawcy: aplikacja niepotrzebna).** Projekt Cloudflare Pages usunięty razem ze wszystkimi wdrożeniami, wpis DNS `crm.beautypolisa.eu` usunięty; kod zostaje w repozytorium. Stan bazy BEAUTY sprawdzony 13.11 (tylko schemat i uprawnienia, bez danych): rola `anon` nie ma uprawnień do żadnej tabeli `crm_*` (także `crm_lead_intake`, więc `/formularz` i tak nie zapisywał), a `mienie_wnioski` i `mienie_lokalizacje` mają RLS bez polityk dla `anon` – odczyt, zapis i usuwanie bez logowania są zablokowane. Trzy punkty `beauty-crm` poniżej są więc nieaktualne jako ryzyko produkcyjne, z jednym wyjątkiem: **sekret `x-api-key` funkcji `lead-import` jest w publicznym repozytorium, a funkcja działa dalej** (arkusz zgłoszeń → Aura HUB) – rotacja razem z właściwością skryptu arkusza (inaczej przerwie się zasilanie HUB). Do zrobienia przez właściciela repozytorium: archiwizacja `beauty-crm` na GitHubie. Funkcja `mienie-form` w BEAUTY (bez JWT) – do sprawdzenia, czy coś jej jeszcze używa po wyłączeniu `beauty-crm`.
- **`beauty-crm` – pilne:** stały sekret nagłówka `x-api-key` funkcji `lead-import` (BEAUTY) jest w kodzie wysyłanym do przeglądarki, ta sama wartość w trzech miejscach (`src/components/LeadForm.tsx:44`, `src/store/useCRMStore.ts:278`, `src/components/Dashboard.tsx:117`). Każdy, kto otworzy `/formularz`, może wołać `lead-import` z dowolną treścią. Według komentarzy (`LeadForm.tsx:41`, `Dashboard.tsx:114`) i flagi `send_to_gr` funkcja zapisuje do CRM BEAUTY i do GetResponse – do potwierdzenia (kod `lead-import` niedostępny, C13 w dok. 14; arkusz nie używa już kolumny GetResponse, `crmaura/docs/integracje/arkusz-zgloszen.gs:10`). Do zrobienia: rotacja sekretu, przeniesienie wywołania na serwer i podmiana klucza w skrypcie arkusza (`crmaura/docs/integracje/arkusz-zgloszen.gs:15`).
- **`beauty-crm` – wniosek majątkowy:** komentarz w `public/mienie-formularz.html:10` mówi o RLS z INSERT, SELECT, UPDATE i DELETE dla `anon`. Strona czyta też `crm_companies` po `form_token` kluczem anon (`:776`), więc tabela CRM musi mieć politykę odczytu dla anon. Token (UUID z dopiskiem `-ID<id firmy>`, `src/store/useCRMStore.ts:378-387`) tych danych nie chroni: strona wysyła tylko nagłówki `apikey` i `Authorization` z kluczem anon (`:345`), a `form_token=eq.` to filtr zapytania PostgREST, którego polityka RLS nie widzi, więc nie może go wymagać. Jeśli anon ma SELECT na `crm_companies` i `mienie_wnioski` (wskazują na to `:10` i `:776`), klucz anon z tej strony wystarcza do odczytu wszystkich firm (razem z ich `form_token`) i wszystkich wniosków, a przy DELETE dla anon – do ich usunięcia. Zapis też idzie po `id`, nie po tokenie (PATCH `mienie_wnioski?id=eq.`, DELETE `mienie_lokalizacje?wniosek_id=eq.`, `:980-999`). Migracja `crmaura/supabase/migrations/20260618000000_security_hardening_anon_policies.sql:11-13` zdjęła anonimowy odczyt `mienie_wnioski`, ale w projekcie aurabroker; ta strona łączy się z BEAUTY. Stan polityk na produkcji do potwierdzenia (C13 w dok. 14); poprawka: RPC `SECURITY DEFINER` po tokenie zamiast bezpośredniego dostępu anon.
- **`beauty-crm` – cały CRM:** `crm_companies`, `crm_policies`, `crm_users`, `crm_settings` i reszta są obsługiwane z przeglądarki (klucz anon + sesja Supabase Auth, rola `authenticated`; `src/lib/supabase.ts:4`, `src/components/LoginPage.tsx:13`, `src/store/useCRMStore.ts:110-270`); bezpieczeństwo zależy wyłącznie od RLS.
- **`APK`:** klucz anon projektu aurabroker w kodzie klienta (`lib/supabase.js:4-10`). `README.md:70` opisuje RLS z INSERT i UPDATE dla anon w `apk_forms`, ale to stan nieaktualny: migracja `crmaura/supabase/migrations/20261006000000_security_apk_storage_bp.sql:18-26` zdjęła `apk_forms_select_auth`, `apk_forms_insert_anon`, `apk_forms_update_anon`, `apk_tokens_insert_auth` i `apk_tokens_update_anon`, a według `crmaura/SECURITY_HANDOFF.md:3-7` zastosowano ją na produkcji (handoff uznaje aplikację APK za nieistniejącą). Zapis z formularza (kod nie ustawia `tenant_id`) i panel doradcy bez logowania (`src/app.jx:64`) najpewniej więc nie działają. Do zgłoszenia zostaje klucz w kodzie i usunięcie albo archiwizacja repozytorium; stan produkcji – do potwierdzenia (K6, C4 w dok. 14). Token linku z `Math.random` (`lib/formState.js:17-22`), nigdzie nieweryfikowany. Zob. też K6 w dok. 14 (niezastosowana migracja dla `apk_form_by_token`).
- **`catalog`:** `.env` śledzony w git (adres projektu, klucz anon, site key Turnstile – wartości publiczne z założenia, ale plik w repo zachęca do dopisania sekretów). `contact_consent: true` zapisywane bez pobrania zgody (`src/routes/api/lead/+server.ts:39`) – zgoda nierozliczalna (art. 7 ust. 1 RODO).
- **Zgody marketingowe:** `beauty-crm` wysyła każdy lead z `/formularz` do `lead-import` z `send_to_gr: true` (`src/components/LeadForm.tsx:45`) przy zgodzie tylko na przedstawienie oferty; czy lead faktycznie trafia do GetResponse – do potwierdzenia (kod funkcji niedostępny, C13). `hub` liczy puste pole `rodo` jako zgodę i wyklucza tylko wyraźny sprzeciw – „nie wyrażam zgody” też przechodzi (`src/lib/categories.ts:69-80`, `README.md:484`). HUB uzasadnia to oświadczeniem, że zgody zebrano dla całej bazy, co potwierdził właściciel danych (`README.md:479-481`, `src/lib/categories.ts:72-75`). Do oceny prawnika razem z C11.
- **Mniejsze:** `udapp/app/src/lib/server/clientAuth.js:10` – przy braku `PIN_COOKIE_SECRET` podpis ciasteczka używa klucza `service_role` albo stałego napisu (ten sam wzorzec co K4 w CRM); `hub/src/lib/server/turnstile.ts:8-20` nie sprawdza `action` ani `hostname` (dziś nieużywany – nie kopiować); `udapp/app/DEPLOY.md` i komentarze migracji `katalogbeauty` ujawniają identyfikatory projektów Supabase, a migracje `katalogbeauty` wskazują dwa różne projekty (`20260622_katalog_admin_and_paid_jobs.sql:8` – aurabroker, `20260716_velora_applications_cv_saved.sql:4` – BEAUTY, którego używa kod).

### E. W1 – rekomendacja (streszczenie `../14-integracja-wnioskow-z-crm.md` rozdz. 4)

- **Tak, do CRM, automatycznie** trafiają: OC (kalkulator i lead), Tax Protect, EZB, ER, UD, opieka medyczna, „Zapytaj doradcę” przy NNW i kontakt ogólny. **Nie** trafiają: szkolenia, „Dam pracę”/„Szukam pracy”, newsletter. Ankieta oceny ryzyka grupy 4 nie jest formularzem portalu – zostaje w osobistym linku do APK i wniosku w CRM.
- **Wariant C (hybryda) jako jeden punkt przyjęcia w CRM.** Worker portalu po walidacji i Turnstile wysyła ładunek do `POST /api/integracje/portal/v1/zgloszenia`, podpisany HMAC sekretem `CRM_LEAD_INTAKE_KEY` (czas, nonce, skrót treści), z idempotencją po `zgloszenie_id`. Odpowiedź `202` ma jeden kształt i nie zdradza, czy firma jest klientem. CORS nie jest potrzebny.
- **Portal trzyma tylko kopertę:** numer, produkt, zgody z wersją i skrótem treści, `crm_ref`, etap. **PESEL i dane o zdrowiu z UD przechodzą bez zapisu** do `ud_clients`, skąd istniejące wyzwalacze przenoszą wniosek do CRM.
- **Odrzucone:** wariant A (wołanie `/api/wnioski`, `form-submit` i arkusza – trzy kontrakty, jednorazowy token Turnstile z cudzej witryny, stałe klucze) i wariant B (PESEL i zdrowie w bazie portalu). Dwa jawne odstępstwa od `12` 3.2 pkt 4 wariant B: dopasowanie do istniejącego klienta z zadaniem dla doradcy (O-1) i `crm_ref` w odpowiedzi (O-2).
- **Warunek startu:** P1 z dok. 14 rozdz. 4.7, w tym minimum bezpieczeństwa ścieżki OC (K1–K4, K6, K9). Kolejność: najpierw OC, Tax, EZB i ER; UD (P1-5: funkcja do `ud_clients` ze zgodą art. 9) może dołączyć później, a do tego czasu UD zostaje na utratadochodu.pl (D33). Proponowany zapis W1 do rejestru decyzji: dok. 14 rozdz. 4.9 – wymaga akceptacji zleceniodawcy.

Dok. 14 wykazał też rozbieżności z dotychczasowymi ustaleniami (rozdz. 1.4). Po pierwsze, e-mail z CRM zawiera pełny link `/odnowienie/…`, a `/w/XXXXXXXXXX` to tylko krótki alias do SMS-a (D-1). Po drugie, `konsultacja-agent` pobiera z CRM pełny link do wniosku, co przeczy D32 lit. f (D-2). Po trzecie, punkt przyjęcia leadów w CRM już istnieje i jest zasilany z arkusza Google, który ma drugiego odbiorcę – Aura HUB (D-6, P1-9). [przegląd repo 13.11] Precyzyjniej: drugim odbiorcą jest Edge Function `lead-import` w projekcie BEAUTY („BEAUTY (Aura HUB)”, `crmaura/docs/integracje/arkusz-zgloszen.gs:2,5,15,31`; wywołuje ją też `beauty-crm`; kod poza repozytoriami – C13 w dok. 14), a Aura HUB wysyła maile z `crm_companies` tego projektu – część G.

### F. Czego nie sprawdzono (krytyk kompletności)

- **Pozostałe repozytoria** [przegląd repo 13.11]: `udapp`, `APK`, `hub`, `beauty-crm`, `grupowe`, `ac`, `expert`, `life`, `catalog`, `katalogbeauty`, `medaura` i `medicalaura` przejrzano w trybie tylko do odczytu, bez uruchamiania kodu. Wyniki i wpływ na braki – część G. Przegląd **nie** sprawdził:
  - zawartości baz `medaura`/`medicalaura`: czy `pakiet_skladki_historia` albo `pakiety` mają ceny ENEL-MED i LUX MED i z jaką `data_wejscia` (czytany był tylko kod);
  - definicji tabel `crm_lead_intake`, pełnego `crm_companies`, `apk_*`, `ud_clients` ani większości polityk RLS – są w projektach Supabase, nie w repozytoriach. Wyjątki: polityki `apk_*` (i anonimowy odczyt `mienie_wnioski` w aurabroker) są częściowo w migracjach `crmaura` (`20260618000000_security_hardening_anon_policies.sql`, `20261006000000_security_apk_storage_bp.sql`), polityki `job_listings` – w migracjach `katalogbeauty` (bez bazowego schematu tabeli);
  - kodu Edge Function `lead-import` (BEAUTY) – nie ma go w żadnym klonie; co robi z leadem (CRM, GetResponse, pole zgody) – do potwierdzenia;
  - kto ma być operatorem tablicy ogłoszeń w portalu (regulamin `katalogbeauty` ma szablon „Aura Consulting [pełna forma prawna]”) i czy „Zatrudnię” ma być płatne – decyzja zleceniodawcy;
  - treści analizy potrzeb dla EZB, ER i UD – repo `APK` jej nie zawiera, musi ją dostarczyć compliance Aura Expert;
  - aktualności danych KRS i RPU ze stopki `udapp` względem PDF „Informacja o dystrybutorze” z lipca 2026;
  - pobierania PKD przez BIR na żywo: kod jest w `branzowe` (`src/lib/serwer/gus.ts:104-121`), proxy `katalogbeauty` PKD nie zwraca, a bez klucza GUS nic nie testowano.
- **Produkcja a repozytorium:**
  - ER: produkcji nie porównano z `e186f2a` (sprawdzone tylko `OWU.pdf` i 404 na `owu.pdf`);
  - Tax: nie wiadomo, czy wdrożone funkcje = repozytorium (T1);
  - UD: produkcja jest nowsza od repozytorium (kalibracja z 14.10, `/kup-online`);
  - EZB: produkcja = PR #1 (ustalone z kodu klienckiego);
  - nieznany stan bazy (migracje `zrodlo_wizyty` EZB i `supabase/pending` CRM, DDL `ud_clients`, tabele `tax_*`, RLS).
- **Trasy nieprzejrzane w całości:**
  - CRM: starszy formularz APK `/form` i konta `/portal` – tylko w zakresie bezpieczeństwa;
  - Tax: `/admin` bez kodu `tax-admin`;
  - UD: polityka cookies, panel agentów poza przydziałem opiekuna;
  - EZB: landingi `/branza/[slug]` nie są na produkcji.
- **E-maile:** żadnego nie wysłano ani nie oglądano w skrzynce; treści pochodzą z kodu. Nie sprawdzono:
  - definicji wyzwalacza UD (tylko w panelu Supabase);
  - plików załączanych przez `tax-potwierdz` (magazyn albo adresy z sekretów);
  - czy ER faktycznie pomija załącznik;
  - czy w Resend włączone jest śledzenie kliknięć (C8);
  - wiadomości SMS (tylko kod).
- **Dokumenty:**
  - `pliki.auraexpert.pl`, `colonnade.pl` i `ergohestia.pl` były niedostępne (proxy 403);
  - informacji o dystrybutorze UD nie pobrano;
  - metadane PDF/XLSX wymagają czyszczenia przed publikacją.
- **Bez weryfikacji na żywo:** zachowania endpointów (CORS, odpowiedzi Turnstile, limity Cloudflare/WAF) wyprowadzono z kodu, bez wywołań. Żadnego tekstu prawnego nie ocenił prawnik.

### G. Przegląd pozostałych repozytoriów – co zmienia [przegląd repo 13.11]

Klony tylko do odczytu, bez uruchamiania kodu. Wartości sekretów, adresy projektów Supabase i adresy e-mail pominięto. Nazwy „BEAUTY” i „aurabroker” to dwa projekty Supabase rozpoznane po kodzie (BEAUTY: `crm_*`, `mienie_*`, katalog; aurabroker: `ud_*`, `apk_*`, `pakiety*`). Żadne z tych repozytoriów nie czyta ani nie zasila tabel `ezb_*`.

| Repozytorium (stan) | Co zawiera | Wpływ na braki i decyzje |
|---|---|---|
| `udapp` (`36ae901`, 20.10.2026; aurabroker) | Panel ofert UD (SvelteKit). Agent porównuje oferty Leadenhall i CEU. Klient dostaje e-mail z linkiem `/offer/[token]` i osobno 4-cyfrowe hasło SMS (`app/src/lib/server/templates.js:15-58`, `app/DEPLOY.md:43`), potem wybiera albo odrzuca wariant, a agent dostaje e-mail (`app/src/routes/offer/[token]/choice/+server.js:20-61`). OWU dopasowywane po symbolu (`app/src/lib/server/owuMatch.js:1-4`). `/dystrybutor` serwuje PDF z magazynu według `ud_settings.distributor_pdf_path` (`app/src/routes/dystrybutor/+server.js:5-24`). Stopka spółki z KRS, wydziałem i numerem RPU (`app/src/lib/server/offerConditions.js:83`, `app/src/lib/server/pdf/conditionsDoc.js:76-79`) | **U9 bez zmian:** `/kup-online` nie ma i tutaj; po wniosku jest oferta agenta i wybór wariantu, bez zakupu i płatności. **Informacja o dystrybutorze UD:** mechanizm znany, pliku w repo nie ma (leży w magazynie), więc brak dokumentu bez zmian. **XII Wydział (D38):** stopka też ma „XII” – to źródło wewnętrzne; rozstrzyga odpis KRS (do potwierdzenia). **W4:** wzorzec e-maila – neutralne „Dzień dobry,” (`templates.js:16-18`), HTML i wersja tekstowa, escapowanie (`templates.js:6-8`), hasło osobnym kanałem. Błąd do zgłoszenia: stary `index.html:466` podpisuje Aura Expert numerami KRS i KNF Aura Consulting |
| `APK` (`1c519f4`, 19.04.2026; aurabroker) | Formularz analizy potrzeb brokera Aura Consulting, 6 kroków (`components/steps/*`): dane, osoba fizyczna, firma (progi 6,2 i 12,8 mln EUR, `Step3Firma.jsx:42,48`), 12 koszyków ryzyk Lloyd's, historia ubezpieczeń, podsumowanie z akceptacją (`Step6Podsumowanie.jsx:117-120`). `form_data` w JSONB i status draft/submitted (`lib/formState.js:48-94`), autozapis co 5 s (`hooks/useAutosave.js:7`), tabele `apk_forms`, `apk_tokens`, `apk_audit` (`README.md:66-70`) | **W5, T5:** nie przenosić – werdykt i wzorzec koperty w rozdz. 2, W5. Bezpieczeństwo – część D. Szerokie polityki anon na `apk_forms` i `apk_tokens`, na których opiera się ta aplikacja, zdjęła migracja `crmaura/supabase/migrations/20261006000000_security_apk_storage_bp.sql:18-26` (według `crmaura/SECURITY_HANDOFF.md:3-7` zastosowana na produkcji), więc repo najpewniej nie działa (dok. 14, 6.4) |
| `hub` (`e2f6824`, 26.10.2026; BEAUTY) | Aura HUB: mailingi do kontaktów `crm_companies`, po wysyłce wpis w `crm_history` (`README.md:17-21`, `src/lib/server/sender.ts:587`). Słownik zainteresowań `email_normalize_interest`: oc, konsultacja, tax, utrata_dochodu, zdrowie, grupowe (`supabase/migrations/20260708120000_aura_hub_email_module.sql:9-31`). Webhook `POST /api/webhooks/utm-attribution`: nagłówek `x-utm-secret`, świadomie bez CORS, dopina lead po `company_id` albo e-mailu (`src/routes/api/webhooks/utm-attribution/+server.ts:11-15,43-47,69-83`). Bramka RODO: puste pole `rodo` liczy się jako zgoda, wykluczany jest tylko wyraźny sprzeciw (`src/lib/categories.ts:69-80`, `README.md:479-484`); HUB uzasadnia to tym, że zgody zebrano dla całej bazy, co potwierdził właściciel danych (`README.md:479-481`) – do oceny prawnika razem z C11. `src/lib/server/turnstile.ts` – nieużywany | **P1-9, C11:** HUB nie ma kodu przyjmowania leadów (`lead-import` w repo nie występuje). Nowy kontakt w `crm_companies` może dostać kampanię i automatyczne powitanie sekcji (`README.md:61`), jeśli w polu `rodo` nie ma wyraźnego sprzeciwu. To wzmacnia P1-9: do HUB tylko leady ze zgodą marketingową e-mail. **U10:** gotowy kanał atrybucji po stronie serwera (UTM, `gclid`, `fbclid`) bez tagów w przeglądarce – tylko do raportu HUB; konwersji do Google Ads ani Meta nie wysyła (część C, U10). Czy dopnie leady z CRM „aurabroker” (wariant C) – do potwierdzenia, bo szuka w `crm_companies` BEAUTY. Etykiety produktów w przekazie do HUB zgodne ze słownikiem. **W2:** nie kopiować `turnstile.ts`. Błąd: `docs/email-footer.html:21,28` podpisuje stopkę „Aura Consulting” przy linkach do auraexpert.pl |
| `beauty-crm` (`40ebfaa`, 18.06.2026; BEAUTY) | CRM w przeglądarce (React): klucz anon i logowanie Supabase Auth, CRUD `crm_*` (`src/store/useCRMStore.ts:110-270`). Publiczny `/formularz` (`src/App.tsx:32,48`) zapisuje `crm_lead_intake` i woła `lead-import` z `send_to_gr: true` (`src/components/LeadForm.tsx:35-46`), choć zgoda dotyczy tylko „przedstawienia oferty” (`LeadForm.tsx:139-142`). Osobisty link `mienie-formularz.html?token=` (UUID z dopiskiem `-ID<id firmy>`, `useCRMStore.ts:378-387`) otwiera wniosek majątkowy (`public/mienie-formularz.html:771-811`) | **D-6, P1-9:** „drugi odbiorca” arkusza to Edge Function `lead-import` w projekcie BEAUTY (`crmaura/docs/integracje/arkusz-zgloszen.gs:2,15,31`), którą wywołuje też `beauty-crm`; jej kodu nie ma w żadnym klonie (C13). Aura HUB wysyła maile z `crm_companies` tego projektu. Według komentarza (`LeadForm.tsx:41`) i flagi `send_to_gr` lead z `/formularz` ma iść też do GetResponse bez zgody marketingowej – do potwierdzenia (`arkusz-zgloszen.gs:10`: GetResponse w arkuszu już nieużywany). Pewne: sekret w kodzie przeglądarki i zgoda tylko na ofertę. **W1:** nie wzorować się (anon z przeglądarki, stały sekret w kodzie – część D). Link z tokenem to precedens dla `/w/XXXXXXXXXX`, ale w portalu token bez id firmy i dostęp przez Worker, nie przez RLS dla anon |
| `katalogbeauty` (`cab57b5`, 16.07.2026; BEAUTY) | Katalog salonów VELORA (SvelteKit). Tablica `job_listings`: typ `hiring`/`looking`, miasto, województwo, widełki, forma zatrudnienia, status, `payment_status`, `expires_at` (`src/lib/database.types.ts:12-15`, `src/lib/utils.ts:52-57`). RLS: publicznie tylko aktywne i nieprzeterminowane albo bez `expires_at` (`supabase/migrations/20260622_katalog_admin_and_paid_jobs.sql:65-67`); polityki właściciela dopuszczają `status='active'` tylko przy `payment_status='paid'` (`:51-58`), ale samej kolumny `payment_status` nic nie chroni (w migracjach brak triggera i `REVOKE`), więc właściciel jednym UPDATE ustawi sobie `paid` i `active` – paywall da się obejść. Bazowego schematu `job_listings` nie ma w repo, a migracja wskazuje projekt aurabroker (`:8`) – stan w BEAUTY do potwierdzenia. Regulamin §6 (`src/routes/regulamin/+page.svelte:82-93`), CV i aplikacje (`supabase/migrations/20260716_velora_applications_cv_saved.sql:8-45`), JSON-LD `JobPosting` (`src/routes/jobs/[id]/+page.svelte:108-124`). Proxy `GET /api/regon`: BIR 1.1 z kluczem, awaryjnie wykaz podatników VAT MF bez klucza, walidacja NIP (`src/routes/api/regon/+server.ts:27-32,58-100`) | **„Dam pracę”:** przejąć model danych, zasady widoczności i szkic regulaminu (bez CV i aplikacji), **nie** polityki płatności: płatność i aktywacja tylko po stronie serwera, kolumny `payment_status`, `paid_at` i `expires_at` chronione triggerem albo `REVOKE UPDATE`; według części E ogłoszenia nie idą do CRM. Do decyzji: operator (regulamin ma szablon „Aura Consulting [pełna forma prawna]”, `regulamin/+page.svelte:30`), płatność za „Zatrudnię” oraz telefon i e-mail – dziś obowiązkowe i publiczne (`regulamin/+page.svelte:90,128`) – czy formularz pośredniczący. **E2, T9:** proxy nie zwraca PKD ani daty zawieszenia, ale daje tryb bez klucza (część C) |
| `catalog` (`8a01c03`, 15.06.2026; BEAUTY) | Wcześniejszy katalog salonów; lead do salonu `POST /api/lead` → `contact_leads` (`src/routes/api/lead/+server.ts:30-41`); bez modułu pracy | **W3:** antywzorzec – `contact_consent: true` zapisywane bez pola zgody (`:39`). W portalu zgoda tylko z pola formularza, z wersją i hashem treści |
| `ac` (`b5f59c0`, 13.11.2026) | Serwis Aura Consulting (Astro, Pages Functions). `functions/api/kontakt.js`: Turnstile z `action`, `hostname` i `idempotency_key`, pole-pułapka, minimalny czas, Origin, limit na IP, działanie bez JS. Zgoda kontaktowa (`src/components/ContactForm.astro:74`), strona `src/content/pages/informacje-o-brokerze.mdx` | **W2, T10:** wzorzec referencyjny – szczegóły i potrzebne zmiany w rozdz. 2, W2. **Informacja o agencie (art. 22 UDU):** można wziąć układ strony, ale nie treść (broker, nie agent) |
| `grupowe` (`f1e9f2e`, 12.11.2026) | grupowe.pro (Astro + Worker): formularz → Resend, tylko pole-pułapka (`worker/index.ts:68-78`), odbiorca w sekrecie `MAIL_TO` (`:9`) | Nic do przejęcia; bez Turnstile i limitu |
| `medaura` (`48899a7`, 08.03.2026; projekt konfigurowany w przeglądarce – adres i klucz z `localStorage`, `medaura/index.html:612-613`, do potwierdzenia), `medicalaura` (`6cd0593`, 15.03.2026; aurabroker) | Narzędzia B2B Aura Consulting do porównania pakietów medycznych (`medaura/index.html:227,604`). Składki tylko w bazie: `pakiet_skladki_historia` z `data_wejscia`, `cena_ind_mies`, `cena_grup_mies`, `cena_rodzina` (`medaura/index.html:1055-1063,1088-1089`). `medicalaura/index2.html:725-773` czyta `dostawcy`, `pakiety`, `placowki_medyczne`, `pakiety_pelne` | **Opieka medyczna:** cennika ENEL-MED / LUX MED w kodzie nie ma, ostatnie zmiany sprzed 8 miesięcy – potwierdza „cena w ofercie”. Gdy cennik powstanie: wersjonowany JSON według modelu `pakiet_skladki_historia`. Brak dokumentów opieki medycznej bez zmian |
| `life` (`c2e1f59`, 14.04.2026), `expert` (`1bce0eb`, 22.04.2026) | `life`: porównywarki B2B (LIFEAURA, AuraBenefits) i strona Warta Szkoła z dopiskiem „Agent: Aura Expert sp. z o.o.” (`life/warta.html:94`); `expert`: statyczna strona Aura Expert bez formularza | Bez wpływu |

---

> **Poniżej: stan sprzed analizy repozytoriów** (kod kliencki z działających stron, 13.11.2026 rano). Werdykt, statusy w rozdz. 1 i lista w rozdz. 3 są nieaktualne – obowiązuje sekcja „Aktualizacja 13.11.2026” powyżej. Rozdział 2 (W1–W9) pozostaje rejestrem pytań; W1 ma rekomendację w części E.


Stan na 2026-11-13, po przeglądzie krytyka kompletności. Dotyczy trzech aplikacji, które portal ma przestać linkować i odtworzyć u siebie w stylistyce „old money glass” (makiety `docs/koncepcja/design/v3`):

| Skrót | Aplikacja | Specyfikacja | Dane do makiety |
|---|---|---|---|
| **EZB** | ERGO Życie w Biznesie, wniosek dla salonu (`ergo.auraexpert.pl/wniosek?branza=beauty`) | `ergo-zycie-w-biznesie.md` | `ergo-zycie-w-biznesie.json` |
| **ER** | ERGO Razem – Grupa Otwarta, kalkulator i zgłoszenie (`ergo.beautypolisa.eu`) | `ergo-razem-grupa-otwarta.md` | `ergo-razem-grupa-otwarta.json` |
| **UD** | Utrata dochodu, wniosek 5 kroków (`utratadochodu.pl/wniosek/`) | `utratadochodu-wniosek.md` | `utratadochodu-wniosek.json` |

## Werdykt: czy mamy wszystko? (stan z kodu klienckiego – nieaktualny, zob. „Aktualizacja”, część B)

**Nie.** Kod kliencki pozwala odtworzyć wygląd i zachowanie formularzy EZB i UD w całości. W ER mamy tylko krok 1 z 6.

| | Front (kroki, pola, walidacje, teksty) | Taryfy i wyliczenia | Wysyłka i backend | Teksty prawne | Gotowość do przeniesienia |
|---|---|---|---|---|---|
| EZB | kompletny (6 kroków) | kompletne (cennik 8 branż w kodzie) | znany tylko kontrakt `POST /api/wnioski` i `GET /api/gus`; brak kodu serwera | 7 zgód dosłownie; RODO oznaczone jako „dokument roboczy” | **makieta – tak; produkcja – nie** |
| UD | kompletny (5 kroków + 2 ankiety) | wniosek nie liczy składki; symulacja w osobnej wyspie (kalibracja w kodzie) | znane kontrakty `form-submit` i `wniosek-szkic`; brak kodu serwera | zgoda na kontakt i 2 potwierdzenia dosłownie; **brak zgody na dane o zdrowiu**; dokumenty pod linkami niepobrane | **makieta – tak; produkcja – nie** |
| ER | **tylko krok 1 „Wiek”** | składki i świadczenia kompletne (oprócz ceny Global Doctors) | nieznana (server action w niepobranym kodzie) | **żadnej zgody ani klauzuli w kodzie** | **makieta – tylko kalkulator; formularz – nie** |

Weryfikacja specyfikacji: w każdej sprawdzono 8–12 twierdzeń w kodzie źródłowym i wszystkie się potwierdziły. Poprawki naniesione na miejscu (szczegóły w sekcjach „Weryfikacja krytyka kompletności” na końcu każdego pliku `.md`):
- EZB: w JSON pole `adopcja` było przypisane do kroku 5, a jest w kroku 3. Dodano etykiety pól kroku 5 (wcześniej jako etykiety stały placeholdery) i szczegóły parsera struktury wiekowej.
- ER: dodano atrybuty `min`/`max` daty z SSR.
- UD: dodano dwie rzeczy. (1) PESEL z nieistniejącą datą, ale poprawną sumą kontrolną, przechodzi walidację. (2) Przy zaznaczonej zgodzie, ale bez tokenu Turnstile, akcja `kontakt` wysyła `zgoda:false`, czyli kasuje kontakt ze szkicu.

---

## 1. Tabela braków: co mamy / czego brakuje / od kogo / czy blokuje

> Statusy w tej tabeli są sprzed repozytoriów. Aktualne – „Aktualizacja”, część C; braki Tax Protect T1–T15 – `tax-protect-wniosek.md` §11.

Legenda kolumny „Blokuje”: **TAK** – bez tego nie da się uruchomić formularza na produkcji; **makieta** – blokuje już makietę; **nie** – można uruchomić, a uzupełnić później.

### 1.1 EZB – ERGO Życie w Biznesie

| # | Co mamy | Czego brakuje | Od kogo | Blokuje |
|---|---|---|---|---|
| E1 | Kontrakt `POST /api/wnioski`: ładunek, odpowiedź `{nr_wniosku}`, obsługa błędu | Kod serwera: walidacje (w tym odrzucanie PESEL, o którym mówi strona RODO), przeliczenie składki, format `nr_wniosku`, statusy, zapis do `ezb_wnioski`, `cennik_wersja`, zasilanie `ezb_zdarzenia`, rate limit | Zleceniodawca (repozytorium `ergo.auraexpert.pl` / zespół CRM) | **TAK** (o ile portal pisze do CRM, decyzja W1) |
| E2 | Kontrakt `GET /api/gus?nip=` i pola odpowiedzi (`nazwa, regon, adres, pkd_kod, pkd_opis, data_zawieszenia`) | Dostęp do API REGON (BIR1): klucz, mapowanie adresu i PKD, cache; albo zgoda na wołanie ich `/api/gus` z portalu (CORS) | Zleceniodawca (klucz GUS) | **TAK**, częściowo: tryb ręczny działa bez GUS |
| E3 | Treść strony „Wniosek przyjęty”, która zapowiada e-mail z kopią oferty i arkuszem `lista-ubezpieczonych.xlsx` | Szablony e-maili (klient, opiekun), nadawca, **szablon arkusza XLSX**, PDF „Informacja o dystrybutorze” | Zleceniodawca | **TAK** (strona obiecuje załącznik) |
| E4 | Lista 3 OWU i 3 kart produktu z nazwami plików | Pliki PDF (OWU EZwB 01/25, MA 01/25, GD-GZ 01/25 i karty) | Zleceniodawca / ERGO Hestia | **TAK** (zgoda z2 „otrzymałem i zapoznałem się z OWU” wymaga dostępnych dokumentów) |
| E5 | 7 zgód dosłownie, wersja `2026-07-a`; tekst strony RODO | Zatwierdzona klauzula art. 13 (strona oznaczona „Dokument roboczy – wymaga zatwierdzenia przez prawnika”). Do rozstrzygnięcia sprzeczność: z3 jako administratora wskazuje ERGO Hestię, strona RODO – Aura Expert | Zleceniodawca + prawnik | **TAK** |
| E6 | Cennik 8 branż osadzony w kodzie (beauty 58/68/76 zł) | Wersja i data cennika (`ezb_cenniki.meta`, `branze-2607`), potwierdzenie składki MediPlan (2,80 zł, „do potwierdzenia w taryfie” wg kodu), procedura aktualizacji po 31.12.2026 | Zleceniodawca | nie (można wystartować na cenniku z kodu; trzeba go oznaczyć wersją) |
| E7 | Obietnica „Sprawdzimy też, czy Twoje PKD mieści się w wybranej branży” | Lista kodów PKD dla beauty i reguła weryfikacji (w kliencie jej nie ma) | Zleceniodawca / ERGO Hestia | nie (można usunąć zdanie albo dodać regułę później) |
| E8 | Struktura stron zakresu ochrony, 10 opisów pakietów, 25 haseł słowniczka | Katalogi `/dane/owu/*.json` (operacje, poważne zachorowania, rozdziały OWU) | Zleceniodawca | nie |
| E9 | Opis procesu (opiekun w 1 dzień roboczy, deklaracje pracowników) | Proces deklaracji pracowników (osobny formularz?), sposób odsyłania arkusza, SLA | Zleceniodawca | nie |
| E10 | Grafiki promo UD (`utrata-dochodu-*.png`) i zdjęcia branż (hosting `trybloom.ai`) | Pliki graficzne; w portalu i tak do zastąpienia własnymi | Portal (nasze) | nie |

### 1.2 ER – ERGO Razem – Grupa Otwarta

| # | Co mamy | Czego brakuje | Od kogo | Blokuje |
|---|---|---|---|---|
| R1 | Krok 1 „Wiek”: pole, walidacja, grupy wiekowe A1/A2/B, przekierowania | **Kod kroków 2–6**: Ankieta, Weryfikacja, Oferta, Podsumowanie, Gotowe oraz `/wykluczenie/wiek` | Zleceniodawca (repozytorium aplikacji / Worker `gohestia`). Alternatywnie: my, przechodząc kroki w przeglądarce i pobierając chunki – daje tylko kod kliencki | **makieta** i **TAK** |
| R2 | Flaga `questionnaireComplete` i deklaracja „ankieta tylko w przeglądarce” | **Pytania ankiety medycznej dosłownie, typy odpowiedzi, reguły kwalifikacji** (co wyklucza, co kieruje do agenta), teksty ekranów wykluczenia | Zleceniodawca / ERGO Hestia (underwriting) | **TAK** |
| R3 | Flaga `turnstileVerified` | Co sprawdza krok „Weryfikacja” (sam Turnstile?) | Zleceniodawca | nie (portal ma własny Turnstile, W2) |
| R4 | Store: produkt, wariant, dodatki; funkcja `calcMonthlyPremium` | Układ kroku „Oferta”, wariant domyślny, komunikat dla Global Doctors przy wieku > 63 | Zleceniodawca | nie (można zaprojektować na podstawie taryf) |
| R5 | Zapowiedź „Zostawiasz dane kontaktowe — agent … skontaktuje się w 1–2 dni” | **Pola formularza kontaktowego, walidacje, komunikaty** | Zleceniodawca | **TAK** (lub decyzja: używamy wspólnego formularza leada portalu) |
| R6 | FAQ potwierdza, że zgody istnieją | **Treść wszystkich zgód i klauzul** (art. 13, marketing per kanał, ewentualnie art. 9), strony `/rodo`, `/polityka-prywatnosci`, `/regulamin` | Zleceniodawca + prawnik | **TAK** |
| R7 | — | Wysyłka: dokąd idzie zgłoszenie (Supabase / e-mail / CRM), struktura rekordu, e-maile do agenta i klienta | Zleceniodawca | **TAK** (jeśli zapis do CRM, W1) |
| R8 | `ADDONS.global_doctors.monthly = null`, „Składka zależna od wieku – podana przy wycenie” | Tabela składek Global Doctors wg wieku albo decyzja „cena przy kontakcie” | Zleceniodawca / ERGO Hestia | nie |
| R9 | Katalog 57 zachorowań (lista, kategorie, znaczniki) | Definicje zachorowań (chunk `03amb72-bgjst.js` albo WU/ER 01/25 zał. 1); która 1 z 57 nie jest w zakresie KOMFORT | Zleceniodawca | nie |
| R10 | Treści marketingowe i taryfy | Wyjaśnienie niespójności: „od 57 zł” a 50 zł (A2); „56 chorób” a 57/34; daty 2.06.2025 i 13.02.2026; wiek „na dziś” a „w dniu objęcia ochroną”; znaczenie „120/50 zł” | Zleceniodawca | nie (ale do poprawy przed publikacją) |
| R11 | Linki do dokumentów | PDF OWU/WU ER 01/25 i GD 02/24 | Zleceniodawca / ERGO Hestia | **TAK** |

### 1.3 UD – Utrata dochodu

| # | Co mamy | Czego brakuje | Od kogo | Blokuje |
|---|---|---|---|---|
| U1 | Kontrakt `form-submit`: ładunek z `ge()`, Turnstile, odpowiedź `status/message` | Kod funkcji: weryfikacja Turnstile, walidacje serwerowe, mapowanie na kolumny (w tym pytania bez `col`, `hs_*`/`hsd_*`, stałe `nwPermanentDamage`), deduplikacja, `affiliateCode` | Zleceniodawca (projekt Supabase CRM) | **TAK** (jeśli zapis do CRM, W1) |
| U2 | Kontrakt `wniosek-szkic` (start/kontakt/krok/ukoncz/wycofaj), strona `/wycofaj-zgode/` | Kod funkcji, schemat `ud_wnioski_szkice`, sól `ip_hash`, **algorytm i klucz podpisu `sig`** linku wycofania, retencja szkiców | Zleceniodawca | **TAK** dla szkiców i przypomnień; formularz działa bez nich |
| U3 | Tylko ślad: link wycofania „z wiadomości e-mail” | Przypomnienia o niedokończonym wniosku: harmonogram, warunki, **szablon e-maila**, nadawca | Zleceniodawca | nie (funkcję można włączyć później) |
| U4 | — | E-maile po złożeniu wniosku (potwierdzenie dla klienta, powiadomienie agenta) | Zleceniodawca | **TAK** (lub własne szablony portalu, W4) |
| U5 | Dwa wymagane potwierdzenia z linkami do `/wylaczenia/`, `/klauzula-informacyjna/`, `/regulamin/`, `/polityka-prywatnosci/` | **Klauzula informacyjna dla portalu**, **zgoda na przetwarzanie danych o zdrowiu (art. 9 ust. 2 lit. a RODO)**, informacja o przekazaniu danych Leadenhall/CEU. Teksty dokumentów pod linkami nie zostały pobrane (tylko `wylaczenia.md`) | Zleceniodawca + prawnik | **TAK** |
| U6 | Pytania ankiety podstawowej (7) i rozszerzonej (20) dosłownie, bez okresów referencyjnych | Akceptacja ubezpieczyciela lub coverholdera, że skrócone pytania wystarczają (albo oryginalne pytania z okresami) | Zleceniodawca / Leadenhall, CEU | nie (stan obecny działa), ale ryzyko underwritingowe |
| U7 | Kalibracja symulacji (11 ofert, stawki 0,0202/0,022/0,0322) | Decyzja, czy portal pokazuje symulację po wniosku (strona ją obiecuje, a kreator jej nie ma); proces odświeżania `kalibracja.json` | Zleceniodawca | nie |
| U8 | Opisy kroków (stała `G[].opis`) mówią o „wysokości dochodu” i „okresie wypłaty” | Decyzja, czy dodać do wniosku dochód i okres wypłaty (24/36/48/60) | Zleceniodawca | nie |
| U9 | Link „Kup online u Leadenhall” → `/kup-online?z=wniosek` | Docelowy adres i parametry (link afiliacyjny), zgoda na zachowanie w portalu | Zleceniodawca | nie |
| U10 | Analityka i Consent Mode z identyfikatorami GA4/Ads/Pixel | Decyzja: tagi portalu czy UD; nowe etykiety konwersji | Portal + zleceniodawca | nie |

---

## 2. Wspólne decyzje do podjęcia

Prośba zleceniodawcy („nie rób przekierowań, przenieś logikę do portalu”) **zmienia obowiązujące decyzje** w `docs/koncepcja/00-koncepcja-portalu-beautypolisa.md`. Dziś D33/D34 kierują wniosek UD na utratadochodu.pl, a D36 – grupowe ERGO na `ergo.auraexpert.pl` i `ergo.beautypolisa.eu`. Do tego `02-architektura-i-bezpieczenstwo.md` (F3, rozdział o zakresie v1) zakłada, że portal zbiera minimalny lead, bez ankiet i bez danych o zdrowiu. Trzeba to zapisać jako nową decyzję i rozstrzygnąć punkty poniżej.

### W1. Gdzie portal zapisuje wnioski

| Wariant | Opis | Za | Przeciw |
|---|---|---|---|
| **A. CRM „aurabroker” przez dedykowane funkcje** | Worker portalu wywołuje po stronie serwera istniejące `/api/wnioski` (EZB) oraz `form-submit` i `wniosek-szkic` (UD) albo nowe funkcje Edge z kontraktem uzgodnionym z zespołem CRM. Przeglądarka nie zna adresów CRM | Jeden obieg w CRM (opiekun, statusy, e-maile, XLSX już istnieją), brak migracji, zgodne z D32 („sprawy w CRM”) | Zależność od kodu, którego nie widzieliśmy (E1, U1, U2). Audyt wskazał słabości „aurabroker” (klucz anon, funkcje `SECURITY DEFINER` dostępne dla `anon`). Funkcje UD działają bez JWT. Wymaga CORS lub wywołań serwer–serwer i sekretu między systemami |
| **B. Własna baza portalu** | Tabele `ezb_applications`, `ud_applications`, `er_leads` w projekcie Supabase portalu, eksport lub webhook do CRM | Pełna kontrola walidacji, RLS i retencji; spójne z architekturą (osobny projekt, brak klucza w przeglądarce) | Dublowanie logiki CRM (numeracja, XLSX, e-maile, panel opiekuna). UD wnosi do portalu PESEL i dane o zdrowiu (art. 9), co oznacza nową DPIA, szyfrowanie kolumn, krótką retencję i zmianę zakresu v1 |
| **C. Hybryda (rekomendacja do dyskusji)** | Portal waliduje (Zod), weryfikuje Turnstile, zapisuje **kopertę** zgłoszenia (numer, produkt, zgody z wersją i treścią, znacznik czasu, hash IP) i przekazuje treść do CRM przez dedykowaną funkcję z sekretem serwer–serwer. Dane o zdrowiu i PESEL **nie są przechowywane w bazie portalu**, tylko przekazywane dalej | Rozliczalność zgód po stronie portalu; dane szczególnej kategorii zostają w jednym systemie (CRM) | Nadal wymaga kontraktu i utwardzenia funkcji CRM (E1, U1) |

Bez tej decyzji nie da się zamknąć pozycji E1, E3, R7, U1, U2 i U4.

> **Rekomendacja (13.11.2026):** wariant C jako jeden punkt przyjęcia w CRM – streszczenie w „Aktualizacji”, część E; pełny kontrakt w `../14-integracja-wnioskow-z-crm.md` rozdz. 4. Wiedza o kodzie dla E1, R7, U1, U2 i U4 jest już zamknięta.

### W2. Turnstile i ochrona formularzy
- Wszystkie trzy formularze przechodzą na **jeden standard portalu** (02 §2.2): honeypot → idempotencja → rate limit → Zod → Turnstile (`siteverify` w Workerze, sprawdzenie `hostname` i `action`).
- EZB dziś nie ma Turnstile ani honeypota. UD ma dwa widżety (niewidoczny w kroku 1 dla szkicu, widoczny w kroku 5). ER ma tylko flagę w store.
- Do ustalenia: nowy sitekey i secret dla domeny portalu (konto Cloudflare zleceniodawcy). Przy wariancie A trzeba też ustalić, czy funkcje CRM nadal wymagają `cf-turnstile-response`. Wtedy weryfikacja musiałaby iść tam, a nie w Workerze, bo token jest jednorazowy. Alternatywa: CRM ufa Workerowi po sekrecie.
- Poprawić znaną usterkę UD: zgoda bez tokenu nie może wysyłać `zgoda:false`.
- [przegląd repo 13.11] **Wzorzec kodu:** `ac/functions/api/kontakt.js` – `siteverify` z `idempotency_key` i sprawdzeniem `action` i `hostname` (`:63-79`), pole-pułapka `website` i minimalny czas 3 s (`:123-126`), Origin/Referer (`:102-106`), limit 1 wysyłki na 20 s z IP (`:158-163`, `:221`), bez JS odpowiedź 303 z kotwicą (`:98`), awaria Turnstile → 503, zły token → 403 (`:148-156`). Przy przenoszeniu do Workera portalu trzy zmiany: brak sekretu ma blokować wysyłkę (w `ac` warunek `if (env.TURNSTILE_SECRET_KEY)` pomija wtedy weryfikację, `:148`); lista hostów w produkcji ma zawierać tylko domenę portalu (w `ac` także `*.pages.dev`, `localhost` i `127.0.0.1`, `:16` – ta sama lista sprawdza `hostname` z Turnstile, `:75`); brak pola `t` traktować jak zbyt szybkie wysłanie (w `ac` minimalny czas działa tylko, gdy klient przyśle `t` – warunek `started &&`, `:124-125`). Limit w Cache API działa w obrębie jednego centrum danych, więc w portalu lepiej Rate Limiting albo KV. Nie kopiować `hub/src/lib/server/turnstile.ts` (bez `action` i `hostname`, `:8-20`).

### W3. Zgody i ich wersjonowanie
- Jeden rejestr treści zgód w repozytorium (`packages/content/legal/*.json`, wzór `snippets/legal-consents.json`): kod, wersja, pełna treść, wymagana/dobrowolna, produkt.
- Przy zapisie: kod, wersja, **hash treści**, znacznik czasu serwera, hash IP, user agent (art. 7 ust. 1 RODO). Dziś EZB wysyła tylko kod i wersję, UD – tylko wersję zgody na kontakt.
- Do rozstrzygnięcia przez prawnika:
  - administrator danych w każdym formularzu (Aura Expert jako agent czy zakład ubezpieczeń; sprzeczność w EZB z3);
  - wyraźna, niezaznaczona domyślnie zgoda na dane o zdrowiu w UD (i w ER, jeśli odpowiedzi ankiety miałyby opuszczać przeglądarkę);
  - zgody marketingowe per kanał (EZB z6/z7 są, UD i ER – brak);
  - zgoda na kontakt przy niedokończonym wniosku (wzorzec UD, z jednoklikowym wycofaniem).

### W4. E-maile potwierdzające
- Kto wysyła: portal (Resend + outbox, 02 §2.2) czy CRM, który dziś wysyła EZB z XLSX i prawdopodobnie UD.
- Potrzebne szablony: EZB (klient z XLSX i PDF „Informacja o dystrybutorze”, opiekun), UD (klient, agent, przypomnienie z linkiem wycofania), ER (klient, agent).
- Reguła portalu: e-mail transakcyjny bez treści promocyjnych (02, krok 11). Usuwa to m.in. baner UD ze strony podziękowania EZB w wersji e-mail.
- Nie przekazywać e-maila w URL strony podziękowania (dziś robi tak EZB: `?email=`).

### W5. Analiza potrzeb przed propozycją (IDD, art. 8 ustawy o dystrybucji ubezpieczeń)
- **EZB** zgoda z1 brzmi „Wnioskuję o zawarcie umowy…”, a kod nie ma żadnego kroku analizy potrzeb. **UD** zbiera wniosek pod ofertę. **ER** prowadzi do kontaktu agenta.
- Do decyzji:
  - (a) formularze w portalu to **zapytanie lub wniosek o ofertę**, a APK robi CRM pod osobistym linkiem `portal.beautypolisa.eu/w/` przed zawarciem umowy. Wymaga to rozszerzenia D32 poza OC, a zleceniodawca 12.11.2026 ograniczył tę ścieżkę do OC i Tax Protect;
  - (b) portal dokłada w formularzu krótką analizę potrzeb (pytania i zapis wyniku), której treść musi dostarczyć zleceniodawca (compliance);
  - (c) zleceniodawca potwierdza na piśmie, że APK odbywa się w kontakcie opiekuna lub agenta przed wystawieniem polisy.
- Niezależnie od wariantu: przy każdym formularzu informacje o agencie (art. 22 UDU) z `legal-distributor.json` z wersją. Uwaga: `ergo.beautypolisa.eu/informacja-o-agencie` podaje „XIII Wydział”, a portal używa „XII” (D38). [przegląd repo 13.11] „XII” ma też stopka `udapp` (`app/src/lib/server/offerConditions.js:83`, `app/src/lib/server/pdf/conditionsDoc.js:76-79`) – to źródło wewnętrzne, nie rozstrzygnięcie; rozstrzyga odpis KRS (D38, do potwierdzenia).
- [przegląd repo 13.11] **Werdykt o repo `APK`: nie przenosić.**
  - Podmiot: to APK brokera Aura Consulting – akceptacja „wyrażam zgodę na ich przetwarzanie przez Aura Consulting Sp. z o.o.” (`APK/components/steps/Step6Podsumowanie.jsx:117-120`), nagłówek i PDF (`APK/src/app.jx:30`, `APK/lib/pdf.js:126`). Portal działa jako agent Aura Expert, a UDU nie pozwala łączyć czynności brokerskich i agencyjnych (tak też `ac/src/content/pages/informacje-o-brokerze.mdx:25`).
  - Treść: pytania ogólne i korporacyjne (progi 6,2 i 12,8 mln EUR, 12 koszyków ryzyk Lloyd's), bez potrzeb właściwych dla EZB, ER i UD.
  - Kod niedokończony: link `?apk_token=` jest generowany (`APK/components/steps/Step1Dane.jsx:91`), ale nigdzie nieodczytywany; `APK/src/main.jsx:4` importuje `./App.jsx`, a plik to `src/app.jx`; w repo nie ma migracji; panel doradcy bez logowania (`APK/src/app.jx:64`).
  - **Przejąć wzorzec koperty APK:** numer referencyjny (`APK-<base36>`, `APK/lib/formState.js:8`), status draft/submitted ze znacznikami czasu (`APK/lib/formState.js:80-92`), log zdarzeń `created`, `autosaved`, `submitted`, `pdf_exported`, `viewed` (`APK/README.md:68`, `APK/lib/supabase.js:42-49`), krok podsumowania z akceptacją i PDF do archiwum, blok historii ubezpieczeń (krok 5). Wersji formularza APK nie ma – `form_version` jest dopiero w planach (`APK/README.md:119`); w portalu wersja i hash treści od pierwszego dnia.
  - Rekomendacja bez zmian: wariant (b) albo (c). Pytania i tekst akceptacji (podmiot: Aura Expert) musi dostarczyć compliance; do tego czasu (c).

### W6. Taryfy i dane produktowe
- Cenniki EZB i ER oraz kalibracja UD są dziś na stałe w kodzie klienta. W portalu: JSON w repozytorium z wersją i datą obowiązywania (02, rozdział o treści). Serwer zawsze przelicza składkę i zapisuje wersję cennika.
- Oferta EZB obowiązuje do 31.12.2026. Potrzebny termin dostarczenia cennika na 2027.

### W7. Dane szczególne i minimalizacja
- Zachować dobre wzorce:
  - EZB: PESEL-e przeliczane lokalnie, a do serwera trafia tylko agregat rocznik × płeć;
  - ER: data urodzenia i ankieta tylko w przeglądarce;
  - UD: brak Pixela na stronach z danymi o zdrowiu, analityka dopiero po zgodzie.
- UD wysyła PESEL i odpowiedzi zdrowotne. Potrzebne są DPIA, rejestr czynności i retencja, a także brak tych danych w logach Workera i Sentry.

### W8. Marka i treści
- Zgoda ERGO Hestii, Lloyd’s/Leadenhall i CEU na użycie nazw, logotypów i warunków w portalu (`brandUsageApproval`, 02). Do tego wyjaśnienie niespójności w ER (R10) i usunięcie obietnic, których kod nie spełnia: „Sprawdzimy też PKD” (EZB) i „symulacja składki od razu po wypełnieniu” (UD).

### W9. Los starych adresów
- Co robią `ergo.auraexpert.pl`, `ergo.beautypolisa.eu` i `utratadochodu.pl/wniosek/` po uruchomieniu w portalu: przekierowanie 301 na portal, równoległe działanie czy wyłączenie. Od tego zależą też CORS, analityka i `affiliateCode` (`?agent=`).

---

## 3. Braki blokujące (lista do wysłania zleceniodawcy) – nieaktualna, zob. „Aktualizacja”, część D

1. **ER: kod lub specyfikacja kroków 2–6** (ankieta medyczna z regułami kwalifikacji, krok Oferta, formularz kontaktowy, ekran Gotowe, `/wykluczenie/wiek`) oraz sposób wysyłki. Najprościej: dostęp do repozytorium aplikacji `ergo.beautypolisa.eu` (Worker `gohestia`). [R1, R2, R5, R7]
2. **Decyzja W1** (gdzie zapisujemy wnioski). Przy zapisie do CRM: kod lub kontrakt i utwardzenie `/api/wnioski` (EZB), `form-submit` i `wniosek-szkic` (UD), sekret serwer–serwer i CORS. [E1, U1, U2]
3. **Teksty prawne zatwierdzone przez prawnika** dla trzech formularzy:
   - klauzule art. 13 z właściwym administratorem;
   - **zgoda art. 9 na dane o zdrowiu (UD; ER, jeśli dotyczy)**;
   - zgody ER (dziś nieznane);
   - finalna strona RODO EZB (dziś „dokument roboczy”);
   - wersje zgód.

   [E5, R6, U5, W3]
4. **Decyzja IDD (W5):** czy formularze są wnioskiem o zawarcie umowy, czy zapytaniem, oraz kto i gdzie przeprowadza analizę potrzeb przed propozycją. Jeśli w portalu – treść APK. [W5]
5. **Dokumenty przedumowne (PDF):** OWU i karty produktu EZB (EZwB 01/25, MA 01/25, GD-GZ 01/25), OWU ER 01/25 i GD 02/24, OWU i karta produktu UD (Leadenhall/CEU). [E4, R11]
6. **E-maile:** decyzja, kto wysyła (W4), szablony potwierdzeń i powiadomień oraz **szablon `lista-ubezpieczonych.xlsx`** i PDF „Informacja o dystrybutorze” dla EZB. [E3, U4]
7. **Dostęp do REGON (GUS)** dla EZB albo zgoda na korzystanie z ich `/api/gus`. Częściowo blokujące, bo tryb ręczny działa. [E2]
8. **Turnstile dla domeny portalu** (sitekey i secret na koncie Cloudflare zleceniodawcy) i ustalenie, czy funkcje CRM nadal weryfikują token. [W2]
9. **Zgoda partnerów (ERGO Hestia, Lloyd’s/Leadenhall, CEU) na użycie marki i warunków w portalu.** [W8]

**Nieblokujące** (do uzupełnienia po starcie): cena Global Doctors (R8), definicje 57 zachorowań (R9), niespójności treści ER (R10), lista PKD beauty (E7), katalogi `/dane/owu/*.json` (E8), MediPlan 3 warianty (E6), proces deklaracji pracowników (E9), przypomnienia UD (U3), oryginalne pytania ankiety UD (U6), symulacja po wniosku (U7), pola dochodu i okresu wypłaty (U8), adres „Kup online” (U9), analityka (U10), grafiki (E10).

## 4. Co można zrobić od razu, bez odpowiedzi zleceniodawcy

- Makiety EZB i UD w stylistyce v3 z danych JSON (wszystkie kroki, pola, komunikaty, taryfy, zgody w obecnym brzmieniu oznaczone „do zatwierdzenia”).
- Makieta ER: krok „Wiek”, kalkulator składki (taryfy A1/A2/B, dodatki) i tabela świadczeń. Kroki 2–6 jako szkielety z oznaczeniem „brak treści od zleceniodawcy”. [Aktualizacja 13.11.2026: kroki 2–6, ankieta i wykluczenia są znane z `gohestia` – makieta ER może być pełna, bez podwójnego liczenia dodatków.]
- [Aktualizacja 13.11.2026] Makieta Tax Protect: kalkulator i zapytanie (bez wniosku do etapu 2), dane z `tax-protect-wniosek.json`; dokumenty do linkowania z `../design/v3/dokumenty/` według `../snippets/dokumenty-produktowe.json`.
- Schematy Zod i kontrakty API portalu dla trzech formularzy (niezależne od W1).
- Rejestr zgód z obecnymi treściami i wersjami, gotowy do podmiany na zatwierdzone.
