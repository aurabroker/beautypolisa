# Dokumenty produktowe: OWU, karty produktu, informacja o dystrybutorze

Stan na 2026-11-13. Zebrano dokumenty przedumowne i pomocnicze dla produktów portalu. Źródła to płytkie klony publicznych repozytoriów zleceniodawcy (tylko odczyt, bez uruchamiania kodu) oraz publiczny serwis `utratadochodu.pl`. Pominięto wszystkie pliki z danymi klientów: polisy, wnioski, skany i pliki z nazwiskami.

- **Pliki:** `docs/koncepcja/design/v3/dokumenty/<produkt>/`, nazwy ASCII. Każda kopia jest bajt w bajt identyczna ze źródłem (sprawdzone sha256).
- **Manifest:** `docs/koncepcja/snippets/dokumenty-produktowe.json` zawiera dla każdego pliku produkt, typ, tytuł z dokumentu, kod lub wersję, ubezpieczyciela, datę „obowiązuje od”, ścieżkę, źródło, rozmiar, sha256, liczbę stron i uwagi. Ma też listę `brakujace` oraz `linki_zewnetrzne` (dokumenty, których nie kopiujemy, np. OWU NNW – tylko adres strony).
- **Razem:** 24 pliki, **11 009 607 B (≈ 10,5 MiB)**. Udział produktów: EZB 5 150 368 B (10 plików), UD 3 655 138 B (8), ER 929 675 B (1), Tax Protect 834 495 B (2), OC beauty 439 931 B (3). NNW dla dzieci i opieka medyczna nie mają żadnego pliku.
- Repozytoria i stan: `branzowe` na gałęzi `ezb-najnowsza` (8dc9a90, 24.09.2026), `gohestia` (e186f2a), `taxbp` (d693a7c), `ud` (793a158), `crmaura` (e01fbfb). Do tego `AnkietaBPEH.pdf` z katalogu głównego repozytorium portalu.

Kody braków (E*, R*, U*) i decyzje (W*) pochodzą z `00-braki-i-decyzje.md`.

---

## 1. Co mamy / czego brakuje – per produkt

| Produkt | Mamy | Brakuje | Braki z 00 | Blokuje produkcję? |
|---|---|---|---|---|
| **EZB** – ERGO Życie w Biznesie | 3 OWU (EZwB 01/25, MA 01/25, GD-GZ 01/25, każde z kartą produktu w środku i erratą) i 3 osobne karty produktu; informacja o dystrybutorze (lipiec 2026); nota RODO Aura Expert (lipiec 2026); szablon `lista-ubezpieczonych.xlsx`; ulotka branży beauty | — (dokumenty kompletne) | **E4 – zamknięty.** **E3 – zamknięty** (dokumenty tutaj; szablony e-maili: `branzowe/src/lib/serwer/resend.ts:53-92`, opis w `ergo-zycie-w-biznesie.md` §9.3). E5 – nota RODO jest, ale wymaga zatwierdzenia | nie (dokumenty są) |
| **ER** – ERGO Razem – Grupa Otwarta | komplet „Wszystko o ubezpieczeniu na życie” GO/WU002/2504: karta produktu, informacje dla konsumenta, **WU ER 01/25** z zał. 1–4, errata | **WU Global Doctors GD 02/24**; **pełnomocnictwo ERGO Hestii dla Aura Expert**, którego udostępnienie przed przystąpieniem potwierdza zgoda `oswiadczenie_3` (`gohestia/app/kalkulator/podsumowanie/page.tsx:379`); informacja o dystrybutorze w wersji dla ER (można użyć wersji z lipca 2026) | **R11 – w połowie:** ER 01/25 jest, GD 02/24 brak | **tak**: bez pełnomocnictwa zgoda `oswiadczenie_3` jest nieprawdziwa; bez GD 02/24, dopóki portal oferuje dodatek Global Doctors w ER |
| **UD** – utrata dochodu | 4 OWU i 4 karty produktu (Leadenhall LW044/…/PL/5; CEU Utrata dochodu v9.8; CEU dla zatrudniających v2.6; CEU LOI PREMIUM v1.2). Wszystkie z adresu, który podaje wersję aktywną | — dla dokumentów produktowych. Warianty medyczne MEDICA/MEDICARE pominięte celowo (zawody medyczne). **Informacja o dystrybutorze UD** – plik w panelu UD (`/dystrybutor`, `ud/apps/panel/src/routes/dystrybutor/+server.js:7-24`), nie pobrany; porównać z wersją z lipca 2026 | pkt 5 „Dokumenty przedumowne” w 00 – zamknięty dla UD. **U5 – bez zmian:** klauzula informacyjna, zgoda na dane o zdrowiu i regulamin to nie dokumenty produktowe | nie (dokumenty są) |
| **Tax Protect** | OWU (zatwierdzone 25.01.2023, stosowane od 26.01.2023, druk 157/0625) i karta produktu (IPID) | potwierdzenie od Colonnade, że OWU i karta to wersje dziś stosowane; karta opisuje dwa świadczenia, których w OWU nie ma (T8); potwierdzenie, że informacja o dystrybutorze z lipca 2026 może służyć dla Tax Protect | — (w 00 brak kodu; T8 w `tax-protect-wniosek.md` §7 i §11) | **tak** według T8 – karta produktu niezgodna z OWU |
| **OC beauty** (program WA50/003353/24/A) | Załącznik nr 1 i nr 2 – listy zabiegów w brzmieniu Aneksu nr 5; pusta ankieta oceny ryzyka grupy 4 (**brzmienie sprzed Aneksu nr 5**) | **OWU OC zawodowego ERGO Hestia**, **karta produktu (IPID)**, **program / wyciąg z programu z Aneksem nr 5**, lista zabiegów podologicznych (gr. 3), aktualna ankieta (Aneks 5), ulotka warunków, klauzula reklamacyjna, oświadczenie administratora danych, wzór pełnomocnictwa | (nowe, poza 00) | **tak** – bez OWU i IPID nie ma dokumentów przedumownych |
| **NNW dla dzieci** (Colonnade) | tylko publiczny adres strony produktu z sekcją „Dokumenty” i nazwa oraz daty OWU z ulotki | bezpośrednie adresy PDF (tylko do linkowania) | — | nie (zostaje przekierowanie do sklepu Colonnade, który sam podaje OWU) |
| **Opieka medyczna** (ENEL-MED / LUX MED) | nic | ogólne warunki lub regulaminy pakietów i ewentualne karty produktu | — | **tak**, jeśli portal ma je udostępniać przed zakupem |

---

## 2. Spis plików

Kolumna „Od” podaje datę z treści dokumentu; „–” oznacza, że dokument jej nie podaje. Pełne sha256 są w manifeście.

| Plik (`dokumenty/…`) | Typ | Kod / wersja | Od | Str. | Bajty | sha256 | Źródło |
|---|---|---|---|---|---|---|---|
| `ergo-razem/owu-ergo-razem-er-01-25.pdf` | owu | ER 01/25 (komplet GO/WU002/2504; errata ER/EHZ01/2602) | 2025-06-02 | 148 | 929 675 | `875b9fb02172…` | `gohestia/public/dokumenty/OWU.pdf` = `https://ergo.beautypolisa.eu/dokumenty/OWU.pdf` |
| `ergo-zycie-w-biznesie/owu-ergo-zycie-w-biznesie-ezwb-01-25.pdf` | owu | EZwB 01/25 (druk OWU/EZB01/2512; errata) | 2025-12-22 | 357 | 2 526 378 | `7ac4ca684256…` | `branzowe/static/dokumenty/owu-ergo-zycie-w-biznesie.pdf` |
| `ergo-zycie-w-biznesie/owu-mediopieka-ma-01-25.pdf` | owu | MA 01/25 (druk MEDI/OWU002/2512; errata) | 2025-12-22 | 109 | 887 652 | `a7b1b3b9cfd9…` | `branzowe/static/dokumenty/owu-medi-opieka.pdf` |
| `ergo-zycie-w-biznesie/owu-global-doctors-gd-gz-01-25.pdf` | owu | GD-GZ 01/25 (druk GLD/OWU02/2512; errata) | 2025-12-22 | 68 | 926 473 | `361417bb2b97…` | `branzowe/static/dokumenty/owu-global-doctors.pdf` |
| `ergo-zycie-w-biznesie/karta-produktu-ergo-zycie-w-biznesie-ezwb-01-25.pdf` | karta-produktu | EZwB 01/25 | – | 8 | 81 779 | `71a5c4a8268f…` | `branzowe/static/dokumenty/karta-produktu-ergo-zycie-w-biznesie.pdf` |
| `ergo-zycie-w-biznesie/karta-produktu-mediopieka-ma-01-25.pdf` | karta-produktu | MA 01/25 | – | 4 | 63 895 | `8413606443a7…` | `branzowe/static/dokumenty/karta-produktu-medi-opieka.pdf` |
| `ergo-zycie-w-biznesie/karta-produktu-global-doctors-gd-gz-01-25.pdf` | karta-produktu | GD-GZ 01/25 | – | 5 | 83 842 | `46f811c931e3…` | `branzowe/static/dokumenty/karta-produktu-global-doctors.pdf` |
| `ergo-zycie-w-biznesie/informacja-o-dystrybutorze-aura-expert-2026-07.pdf` | informacja-o-dystrybutorze | lipiec 2026 | lipiec 2026 | 1 | 79 070 | `d9be0cd7fa68…` | `branzowe/static/dokumenty/informacja-o-dystrybutorze.pdf` |
| `ergo-zycie-w-biznesie/nota-informacyjna-rodo-aura-expert-2026-07.pdf` | inne | lipiec 2026 | lipiec 2026 | 1 | 131 697 | `3b29fb3be893…` | `branzowe/static/dokumenty/rodo.pdf` |
| `ergo-zycie-w-biznesie/lista-ubezpieczonych-szablon.xlsx` | inne | – | – | – | 20 394 | `658bddc33c39…` | `branzowe/static/dokumenty/lista-ubezpieczonych.xlsx` |
| `ergo-zycie-w-biznesie/ulotka-ezb-beauty-eh-ul-ezb-f-2607.pdf` | inne | EH-UL- EZB-F-2607 | 2026-07-01 | 4 | 349 188 | `cae1c6bc5a65…` | `branzowe/dane/Beauty1072026.pdf` |
| `tax-protect/owu-tax-protect-2023-01-25.pdf` | owu | OWU z 25.01.2023 (druk 157/0625) | 2023-01-26 | 23 | 683 346 | `640d23e399ce…` | `taxbp/public/OWU_Tax_Protect.pdf` |
| `tax-protect/karta-produktu-tax-protect.pdf` | karta-produktu | do OWU z 25.01.2023 | – | 2 | 151 149 | `b74d4617c177…` | `taxbp/public/Tax_Karta_Produktu.pdf` |
| `utrata-dochodu/owu-leadenhall-utrata-dochodu-lw044-pl-5.pdf` | owu | LW044/AD_D_TTD_PTD/PL/5 | – | 15 | 332 657 | `8dffe4c964d3…` | `https://utratadochodu.pl/owu/leadenhall-utrata-dochodu.pdf` |
| `utrata-dochodu/karta-produktu-leadenhall-utrata-dochodu-lw044-pl-5.pdf` | karta-produktu | LW044/AD_D_TTD_PTD/PL/5 | – | 2 | 238 564 | `fcc334b60c5a…` | `https://utratadochodu.pl/owu/karta-produktu-leadenhall-utrata-dochodu.pdf` |
| `utrata-dochodu/owu-ceu-utrata-dochodu-v9-8.pdf` | owu | OWU Utrata dochodu z dnia 01.04.2026, wersja 9.8 | 2026-04-01 | 28 | 829 972 | `54c692b80e02…` | `https://utratadochodu.pl/owu/ceu-utrata-dochodu.pdf` |
| `utrata-dochodu/karta-produktu-ceu-utrata-dochodu-v9-8.pdf` | karta-produktu | v 9.8 | – | 2 | 300 155 | `fe09a2411aa1…` | `https://utratadochodu.pl/owu/karta-produktu-ceu-utrata-dochodu.pdf` |
| `utrata-dochodu/owu-ceu-utrata-dochodu-dla-zatrudniajacych-v2-6.pdf` | owu | z dnia 01.04.2026, wersja 2.6 | 2026-04-01 | 26 | 696 350 | `8f047d9f2340…` | `https://utratadochodu.pl/owu/ceu-utrata-dochodu-dla-zatrudniajacych.pdf` |
| `utrata-dochodu/karta-produktu-ceu-utrata-dochodu-dla-zatrudniajacych-v2-6.pdf` | karta-produktu | v 2.6 | – | 2 | 302 999 | `7f1416dc5040…` | `https://utratadochodu.pl/owu/karta-produktu-ceu-utrata-dochodu-dla-zatrudniajacych.pdf` |
| `utrata-dochodu/owu-ceu-loi-premium-v1-2.pdf` | owu | OWU LOI PREMIUM z dnia 01.04.2026, wersja 1.2 | 2026-04-01 | 18 | 662 533 | `de255afa2f45…` | `https://utratadochodu.pl/owu/ceu-loi-premium.pdf` |
| `utrata-dochodu/karta-produktu-ceu-loi-premium-v1-2.pdf` | karta-produktu | v 1.2 | – | 2 | 291 908 | `b7cf30fa8538…` | `https://utratadochodu.pl/owu/karta-produktu-ceu-loi-premium.pdf` |
| `oc-beauty/lista-zabiegow-nr-1-kosmetyczne-fryzjerskie-aneks-5.pdf` | lista-zabiegow | WA50/003353/24/A, zał. nr 1, Aneks nr 5 | 2026-11-06 | 2 | 77 204 | `50342aba0025…` | `crmaura/static/dokumenty/beautypolisa/lista-zabiegow-nr-1-kosmetyczne-fryzjerskie-aneks-5.pdf` |
| `oc-beauty/lista-zabiegow-nr-2-kosmetyczne-kosmetologiczne-aneks-5.pdf` | lista-zabiegow | WA50/003353/24/A, zał. nr 2, Aneks nr 5 | 2026-11-06 | 2 | 116 966 | `a90ff7eef2b6…` | `crmaura/static/dokumenty/beautypolisa/lista-zabiegow-nr-2-kosmetyczne-kosmetologiczne-aneks-5.pdf` |
| `oc-beauty/ankieta-oceny-ryzyka-grupa-4-wa50-003353-24-a.pdf` | ankieta | WA50/003353/24/A, pkt 2, sprzed Aneksu nr 5 | – | 2 | 245 761 | `af9d747f5475…` | `beautypolisa:AnkietaBPEH.pdf` |

Ubezpieczyciele: ER, EZB – Sopockie Towarzystwo Ubezpieczeń na Życie ERGO Hestia S.A.; OC beauty – Sopockie Towarzystwo Ubezpieczeń ERGO Hestia S.A.; Tax Protect – Colonnade Insurance S.A. Oddział w Polsce; UD – Lloyd’s Insurance Company S.A. przez coverholderów Leadenhall Insurance S.A. albo CEU sp. z o.o.

---

## 3. Uwagi do produktów

### 3.1 ER – czy OWU w `gohestia` to faktycznie ER 01/25?

**Tak, ale plik to komplet, a nie samo OWU.** `gohestia/public/dokumenty/OWU.pdf` (148 s.) to broszura „Wszystko o ubezpieczeniu na życie. Grupa Otwarta ERGO Razem”, druk **GO/WU002/2504** (s. 1). Zawiera:
- s. 2–4: „Dokument zawierający informacje o produkcie ubezpieczeniowym”, czyli kartę produktu (IPID). Osobna karta nie jest potrzebna, zgodnie z uwagą w `gohestia/public/dokumenty/README.md:19`;
- s. 5–7: „Informacje dla konsumenta przystępującego do umowy grupowego ubezpieczenia na życie ERGO Razem na odległość”;
- od s. 8: „Warunki Grupowego Ubezpieczenia na Życie dla ubezpieczonych w Grupie Otwartej ERGO Razem, KOD: ER 01/25” z załącznikami 1–4. § 72 mówi, że WU „obowiązują ubezpieczonych w Grupie Otwartej ERGO Razem obejmowanych ochroną od dnia 2 czerwca 2025 roku”;
- s. 148: ERRATA (druk ER/EHZ01/2602), zatwierdzona uchwałą Zarządu z 27.01.2026, obowiązująca „od dnia 13.02.2026 r.”. Dotyczy tylko trybu reklamacji. Wyjaśnia to datę „Obowiązuje od 13.02.2026” w katalogu zachorowań ER (`ergo-razem-grupa-otwarta.md`, R10).

**WU Global Doctors (kod: GD 02/24) są w pliku tylko przywołane** (s. 5, „Informacje dla konsumenta”, pkt 3 ppkt 2), bez treści. Plik `owu-global-doctors-gd-gz-01-25.pdf` z EZB to **inny produkt**: dodatkowe ubezpieczenie do umowy zakładowej, wchodzi w życie 22.12.2025. Nie wolno go podpinać pod ER. **R11 pozostaje otwarty w części GD 02/24.**

Dwa błędy w aplikacji ER, które wyszły przy sprawdzaniu:
- `gohestia/lib/data/documents.ts:21` każe dołączyć do e-maila z ofertą `dokumenty/owu.pdf`, a plik nazywa się `OWU.pdf`. Produkcja odpowiada 404 na `https://ergo.beautypolisa.eu/dokumenty/owu.pdf` i 200 na `…/OWU.pdf` (sprawdzone 13.11.2026). Kod pobiera załącznik przez `fetch` i przy błędzie go pomija (`gohestia/app/api/oferta/route.ts:22-26`). **Klient ER najpewniej nie dostaje OWU w e-mailu.**
- `gohestia/lib/data/documents.ts:24-26` oczekuje `dokumenty/informacja-o-dystrybutorze.pdf`. Pliku nie ma w repozytorium, produkcja odpowiada 404. Tymczasem zgoda `oswiadczenie_3` ER brzmi: „Oświadczam, że przed przystąpieniem do umowy ubezpieczenia nastąpiło udostępnienie dokumentu pełnomocnictwa udzielonego dystrybutorowi przez ubezpieczyciela oraz przekazanie wymaganych ustawą o dystrybucji informacji o dystrybutorze.” (`gohestia/app/kalkulator/podsumowanie/page.tsx:379`).
- **Pełnomocnictwa ERGO Hestii dla Aura Expert nie ma nigdzie.** Ta sama zgoda wymaga udostępnienia go przed przystąpieniem, a w `gohestia` nie ma ani pliku, ani odnośnika (brak trafień „pełnomocnictw” poza `page.tsx:379`). EZB takiej zgody nie ma (brak trafień w `branzowe@ezb-najnowsza`). Dokument od zleceniodawcy; bez niego zgoda `oswiadczenie_3` jest nieprawdziwa (§5, poz. 9).

### 3.2 EZB – E3 i E4 zamknięte

- Pliki z gałęzi `ezb-najnowsza` są identyczne (sha256) z plikami publikowanymi na `https://ergo.auraexpert.pl/dokumenty/…` (sprawdzone 13.11.2026).
- Lista na stronie `/dokumenty` zgadza się z plikami: 3 OWU i 3 karty z kodami EZwB 01/25, MA 01/25 i GD-GZ 01/25 (`branzowe/src/routes/dokumenty/+page.svelte:4-30`).
- Każde OWU to komplet: karta produktu na początku i ogólne warunki dalej. EZwB: karta s. 3–10, OWU od s. 11. MA: karta s. 3–6, OWU od s. 7. GD-GZ: karta s. 3–7, OWU od s. 8. Na końcu każdego kompletu jest ta sama errata reklamacyjna, obowiązująca od 13.02.2026.
- Daty wejścia w życie: EZwB 01/25 – „wchodzą w życie 22 grudnia 2025 roku i są stosowane do umów, które zawieramy od tego dnia” (pkt 1663). MA 01/25 – „z dniem 22.12.2025 r.” (pkt 242). GD-GZ 01/25 – 22.12.2025 (pkt 142). Oznaczenie „01/25” nie oznacza więc daty stosowania.
- Zgoda z2 we wniosku wymaga, żeby te pliki były dostępne przed złożeniem wniosku: „Oświadczam, że przed złożeniem wniosku otrzymałem i zapoznałem się z Ogólnymi warunkami ubezpieczenia (EZwB 01/25), OWU MediOpieka (MA 01/25) oraz OWU Global Doctors (GD-GZ 01/25), w tym z wyłączeniami i ograniczeniami odpowiedzialności.” Portal powinien linkować wszystkie trzy przy tej zgodzie.
- **E3 – zamknięty.** Serwer EZB dołącza do e-maila `rodo.pdf`, `informacja-o-dystrybutorze.pdf` oraz, gdy klient wybrał „arkusz mailem”, `lista-ubezpieczonych.xlsx` (`branzowe/src/routes/api/wnioski/+server.ts:125-129`). E-mail linkuje 3 karty produktu (`branzowe/src/lib/serwer/resend.ts:46-48`). Arkusz to pusty szablon, bez PESEL i bez danych osób. Arkusze: `Struktura`, `ObliczeniaPESEL`, `ObliczeniaDataUrodzenia`, `ObliczeniaRocznik`; tabela wiek × płeć jest liczona formułami. Szablony e-maili też są: `mailDoKlienta` (`branzowe/src/lib/serwer/resend.ts:53`) i `mailDoOpiekuna` (`:77`), nadawca z sekretu `MAIL_OD` (`:109`, wartość w konfiguracji, nie w dokumencie). Opisuje je `ergo-zycie-w-biznesie.md` §9.3, ten dokument ich nie powtarza.
- Ulotka `Beauty1072026.pdf` (druk EH-UL- EZB-F-2607) jest materiałem marketingowym („Nie jest to oferta w rozumieniu art 66 k.c.”) ze składkami dla umów zawartych od 1.07.2026 do 31.12.2026. Nie jest dokumentem przedumownym, ale przyda się jako źródło liczb do porównania z cennikiem w `ergo-zycie-w-biznesie.json`.

### 3.3 UD – czy wersja jest „obowiązująca”?

**Tak, według stanu serwisu na 13.11.2026.**
- Adres `https://utratadochodu.pl/owu/<slug>.pdf` z założenia podaje wersję aktywną. Slug pochodzi z tytułu, a nie z symbolu wersji (`ud/apps/portal/src/lib/owu.ts:14-21`). Funkcja sprawdza `active=is.true` w bazie przy każdym żądaniu (`ud/apps/portal/functions/owu/[plik].js:72`), bufor trwa do 10 minut (l. 30). Opis: `ud/CLAUDE.md:699-740`.
- Wszystkie 8 plików pobrano 13.11.2026 (HTTP 200, `application/pdf`). Ich rozmiary są równe polom `bajty` w `ud/apps/portal/src/dane/dokumenty.json` (`"pobrano": "2026-09-24"`, `"zrodlo": "ud_owu_library (active = true)"`). Od 24.09.2026 żadna wersja się więc nie zmieniła.
- OWU CEU mają w stopce „z dnia 01.04.2026” i numer wersji (9.8, 2.6, 1.2), ale nie podają osobnej daty stosowania. Warunki Leadenhall LW044/AD_D_TTD_PTD/PL/5 nie mają żadnej daty. PDF powstał 10.09.2026.
- Zastrzeżenie samego serwisu: „Wersję obowiązującą dla Twojej polisy wskazuje jej numer — jest w dokumencie polisowym.” (`ext/ud/dokumenty.md`). Portal, który kopiuje pliki, traci automatyczne podmienianie wersji. Dlatego potrzebna jest decyzja: kopie z kontrolą sha256 albo linki do `utratadochodu.pl/owu/…`. To ten sam wybór co w W1, którym systemem portal się posługuje.
- Który dokument dotyczy beauty (z `ext/ud/dokumenty.md`): „**Utrata Dochodu (LW044)** — pozostałe zawody w Leadenhall”; „**CEU Utrata Dochodu** i **CEU LOI Premium** — warianty CEU dla osób, które nie zatrudniają nikogo, kto przejmuje ich obowiązki”; „**CEU Utrata Dochodu dla zatrudniających** — dla osób, które zatrudniają pracowników”. Celowo pominięto MEDICA (LW046), MEDICARE (LW047) i warunki szczególne HIV/WZW (LW048, LW049), bo to warianty dla zawodów medycznych.
- Panel UD rozpoznaje oferty CEU jako „LOI Premium” (`ud/apps/panel/src/lib/format.js:21`, `ud/apps/panel/src/lib/pdf/parseCEU.js:2`). Do potwierdzenia, czy klient beauty dostaje ofertę CEU w wariancie „Utrata dochodu” czy „LOI PREMIUM”, bo od tego zależy, który komplet linkować przy ofercie.

### 3.4 Tax Protect

- OWU: „zatwierdzone przez dyrektora Colonnade Insurance Société Anonyme Oddział w Polsce w dniu 25.01.2023 r. […] mają zastosowanie do umów ubezpieczenia zawieranych od 26.01.2023 r.” (s. 4). Kod druku na ostatniej stronie (s. 23): 157/0625. Plik złożono ponownie w czerwcu i lipcu 2025 (metadane PDF), ale data w treści się nie zmieniła.
- Karta odsyła do OWU z 25.01.2023 („Ogólnych warunków ubezpieczenia ochrony skarbowej i podatkowej TAX PROTECT Colonnade Insurance S.A. Oddział w Polsce z dnia 25 stycznia 2023 r.”), ale w dwóch miejscach opisuje świadczenia, których w OWU nie ma (T8 w `tax-protect-wniosek.md` §7): „Koszty powiadomienia osób, których dane wyciekły (i/lub powiadomienia o tym zdarzeniu regulatora)” oraz „koszty obrony i odszkodowań w przypadku, gdy firma, podmiot zależny lub podwykonawca, któremu powierzono wykonywanie pewnych czynności spowoduje naruszenie bezpieczeństwa danych osobowych lub informacji handlowych” (pdftotext karty, l. 41–46; w OWU 0 trafień „wyciek”/„powiadomi”).
- Aplikacja nie linkuje tych plików (`tax-protect-wniosek.md` §7). E-mail z potwierdzeniem bierze OWU i kartę z magazynu plików albo z adresów w sekretach `DOC_OWU_URL` i `DOC_KARTA_URL` (wartości w konfiguracji, nie w dokumencie): `taxbp/supabase/functions/tax-potwierdz/index.ts:61-67`. Nie da się sprawdzić, czy klient dostaje te same pliki. Colonnade powinno potwierdzić, że OWU z 2023 r. i karta produktu nadal obowiązują, i usunąć niezgodność T8 (§5, poz. 10).

### 3.5 OC beauty

- Listy zabiegów (zał. nr 1 i nr 2) pochodzą z CRM, który publikuje je pod `https://pliki.auraexpert.pl/media/beautypolisa/lista-zabiegow-kosmetyczne-fryzjerskie.pdf` i `…/lista-zabiegow-kosmetologiczne-tatuaze.pdf` (`crmaura/src/lib/server/plikiPubliczne.ts:51-53`). Datę Aneksu nr 5 (06.11.2026) podaje tylko CRM (`crmaura/src/lib/renewals/program.ts:114-115`, `:136-137`). W samych PDF-ach daty nie ma, a Aneksu nr 5 jako dokumentu nie mamy.
- Ankieta: `AnkietaBPEH.pdf` to pusty formularz bez pól i bez wpisanych danych. **Jest nieaktualna od 06.11.2026:** trzy pozycje pkt 2 mają węższe brzmienie sprzed aneksu. Aktualne brzmienia są w `crmaura/src/lib/renewals/program.ts:92-111`, a lista zmian w §4.3. CRM generuje aktualny pusty formularz sam (`crmaura/src/lib/server/renewalDocs.ts:858-861`, `plikiPubliczne.ts:28-37`, `:55`). Gotowego pliku w repozytorium nie ma. Portal powinien dostać eksport z CRM albo linkować adres CRM.
- **OWU OC i karta produktu.** CRM ma na OWU tylko pusty slot „OWU OC z tytułu wykonywania czynności zawodowych (ERGO Hestia)”, który wgrywa administrator (`plikiPubliczne.ts:61`, `zrodlo: null`). Karta produktu nie pojawia się w żadnym repozytorium. To samo dotyczy wyciągu z programu (l. 60), ulotki warunków (l. 62), klauzuli reklamacyjnej (l. 63), oświadczenia administratora danych (l. 64) i wzoru pełnomocnictwa (l. 59). Listy podologicznej (gr. 3) też nie ma w repozytorium (l. 54).
- Adresy `pliki.auraexpert.pl` są z tego środowiska zablokowane (proxy, 403), więc niczego z nich nie pobrano.

### 3.6 NNW dla dzieci

Zostaje przekierowanie do sklepu Colonnade, więc pliku nie kopiujemy. Ulotka podaje: „Ogólne warunki ubezpieczenia następstw nieszczęśliwych wypadków dzieci, młodzieży oraz pracowników w placówkach oświatowych oraz odpowiedzialności cywilnej w życiu prywatnym, a także w związku z nauką lub odbywaniem praktyk uczniowskich zatwierdzonych przez Dyrektora Colonnade Insurance Société Anonyme Oddział w Polsce w dniu 28 lutego 2025 r., mających zastosowanie do umów ubezpieczenia zawieranych od 3 marca 2025 r. dostępnych na stronie: https://www.colonnade.pl/dla-firm/ubezpieczenia-osobowe/ubezpieczenie-nastepstw-nieszczesliwych-wypadkow-dla-dzieci w części „Dokumenty”” (`ext/nnw/ulotka.md`, l. 211–212). Według ulotki OWU, kartę produktu i regulamin usług elektronicznych można pobrać na każdym kroku zakupu (l. 41). Portal linkuje tylko stronę produktu. Bezpośrednich adresów PDF nie ustalono, bo `colonnade.pl` jest z tego środowiska niedostępny.

### 3.7 Opieka medyczna

W żadnym repozytorium (`medaura`, `medicalaura` i pozostałe) ani w pobranych stronach nie ma dokumentów ENEL-MED ani LUX MED. Makieta `opieka-medyczna.html` sama oznacza OWU lub regulamin jako „do potwierdzenia”.

### 3.8 Wspólne

- **Informacja o dystrybutorze (lipiec 2026)** jest dokumentem ogólnym Aura Expert. Wymienia 9 zakładów, w tym obie spółki ERGO Hestia, Lloyd’s Insurance Company i Colonnade. Treściowo może więc służyć wszystkim produktom (pole `dotyczy_produktow` w manifeście), ale nie jest jedynym egzemplarzem. UD ma własną, globalną informację o dystrybutorze: panel podaje ją pod `/dystrybutor` z kubełka plików według ustawienia `distributor_pdf_path` (`ud/apps/panel/src/routes/dystrybutor/+server.js:7-24`) i linkuje w ofercie (`ud/apps/panel/src/routes/offer/[token]/+page.server.js:55`). Kopii nie pobrano; trzeba ją porównać z wersją z lipca 2026 (§5, poz. 12). Leży fizycznie w `ergo-zycie-w-biznesie/`, bo stamtąd pochodzi. CRM OC ma osobny egzemplarz „Z001” z zewnętrznego narzędzia mailingowego (`plikiPubliczne.ts:56`). Nie da się sprawdzić, czy jest identyczny.
- **Nota RODO (lipiec 2026)** jest ogólną klauzulą art. 13–14 Aura Expert. Wymaga zatwierdzenia razem z E5, R6 i W3.
- **Metadane:** listy zabiegów, ankieta, karta Tax Protect, 3 karty produktu CEU (v9.8, v2.6, v1.2) i XLSX mają w metadanych (autor, ostatnia modyfikacja) nazwiska pracowników ubezpieczycieli lub coverholdera. Przed publikacją na portalu warto je wyczyścić. Zmieni to sha256, więc trzeba też zaktualizować manifest.
- **Dane w dokumentach:** informacja o dystrybutorze i nota RODO zawierają dane kontaktowe spółki (adres, telefon, e-mail zarządu), nie osób prywatnych. Tych danych nie przepisano do manifestu ani do tego opisu.

---

## 4. Rozbieżności list zabiegów: PDF (Aneks nr 5) a `snippets/zabiegi-oc-beauty.json`

`zabiegi-oc-beauty.json` **nie był zmieniany.** Według swojego `$comment` odwzorowuje 1:1 listę `PROCS` z `bp-app.js` (117 pozycji: gr. 1 – 40, gr. 2 – 38, gr. 3 – 31, gr. 4 – 8). Ta lista jest starsza niż Aneks nr 5. Porównanie wykonano maszynowo: pdftotext, a potem porównanie nazw po normalizacji białych znaków i wielkości liter.

### 4.1 Liczby

| Lista | PDF Aneks nr 5 | JSON (`grupa`) | Wspólne dosłownie | Zmieniona nazwa | Tylko w PDF |
|---|---|---|---|---|---|
| Zał. nr 1 – kosmetyczne i fryzjerskie | **49** | 40 (gr. 1) | 34 | 6 | 9 |
| Zał. nr 2 – kosmetyczne i kosmetologiczne | **63** | 38 (gr. 2) | 33 | 5 | 25 |
| Podologia (gr. 3) | brak pliku | 31 | — | — | nie do sprawdzenia |
| Ankieta (gr. 4) | 8 (CRM, Aneks 5) | 8 | 1 | 7 (3 z poszerzonym zakresem) | 0 |

Każda pozycja JSON z gr. 1 i gr. 2 ma swój odpowiednik w PDF, więc JSON niczego „nadmiarowego” nie zawiera. W gr. 1 kolejność JSON zgadza się z PDF. W gr. 2 zamienione są tylko g2-33 i g2-34 (PDF poz. 53 i 51), reszta idzie w kolejności PDF.

Gr. 4 porównano po polu `nazwa`: dosłownie zgodna z Aneksem nr 5 jest tylko g4-02. Pole `nazwa_w_ankiecie_ergo` (brzmienie z ankiety) różni się od Aneksu nr 5 tylko w 3 pozycjach: g4-03, g4-06 i g4-08 (poza wielkością pierwszej litery).

### 4.2 Różnice nazw (JSON → PDF)

| id | JSON | PDF (dosłownie) |
|---|---|---|
| g1-13 | Kuracje nawilżające i odbudowujące włosy | Kuracje nawilżające, regenerujące i odbudowujące włosy |
| g1-21 | Masaż manualny ciała i twarzy | Masaż manualny ciała, w tym masaż głowy i twarzy |
| g1-26 | Piercing – przekłuwanie | Piercing – przekłuwanie innych części ciała |
| g1-34 | Strzyżenie (nożyczki, maszynka, brzytwa, Split-ender) | Strzyżenie nożyczkami, maszynką, brzytwą oraz metodą Split-ender i Hair-dusting; trymowanie |
| g1-36 | Zabiegi z zastosowaniem składników aktywnych | Wykonywanie zabiegów kosmetycznych z zastosowaniem składników aktywnych |
| g1-39 | Zabiegi LED – terapeutyczne | Zabiegi wykorzystujące terapeutyczne działanie światła – światło LED i jego pochodnych (zał. 1, poz. 42); w zał. 2, poz. 52: „… – światło LED” |
| g2-14 | Masaż Kobido | Masaż Kobido (zał. 2); „Masaż kobido” (zał. 1, poz. 45) |
| g2-25 | Pedicure kosmetyczny (niezastrzeżony dla podologów) | Pedicure kosmetyczny w zakresie zabiegów niezastrzeżonych dla podologów |
| g2-33 | Zabiegi falą radiową | Zabiegi z zastosowaniem fali radiowej (poz. 53) |
| g2-34 | Zabiegi IPL (fotoodmładzanie, przebarwienia, teleangiektazje, depilacja) | Zabiegi wykorzystujące światło IPL: fotoodmładzanie, likwidowanie przebarwień, terapia trądziku, zamykanie naczyń – teleangiektazje, usuwanie zbędnego owłosienia |
| g2-35 | Zabiegi laserem frakcyjnym nieablacyjnym | Zabiegi z zastosowaniem lasera frakcyjnego nieablacyjnego, laser subablacyjny |
| g2-36 | Zabiegi laserem nieablacyjnym (naczynia, tatuaż, depilacja) | Zabiegi z wykorzystaniem laserów nieablacyjnych, w tym laserowe zamykanie naczyń – teleangiektazje, usuwanie tatuażu i makijażu permanentnego, usuwanie zbędnego owłosienia |

W kilku pozycjach skrót w JSON zawęża zakres. Przykłady: „terapia trądziku” wypadła z IPL, „laser subablacyjny” z lasera frakcyjnego, a „Hair-dusting; trymowanie” ze strzyżenia.

### 4.3 Pozycje z PDF, których brak w JSON

**Zał. nr 1 (poz. 37–39 i 44–49), nowe w stosunku do gr. 1** (poz. 40–43 są w JSON):
- nieobecne w JSON w ogóle: „Zabieg pielęgnacyjny włosów z użyciem fal ultradźwiękowych”, „Zabieg rekonstrukcji włosów”, „Zabieg regeneracyjny włosów z użyciem podczerwieni”, „Warkocze syntetyczne”, „Masaż mięśniowo-powięziowy”, „Masaż transbukalny”, „Suche igłowanie”;
- obecne w JSON tylko w gr. 2, a w Aneksie nr 5 także na liście 1: „Masaż kobido” (g2-14) i „Opalanie natryskowe” (g2-23).

**Zał. nr 2, 25 pozycji spoza gr. 2:**
- 16 z nich JSON ma tylko w gr. 1: Depilacja pastą cukrową, Depilacja woskiem, Elektrostymulacja, Henna, Laminowanie brwi i rzęs, Manicure, Masaż bańką chińską, Manualne oczyszczanie twarzy, Przedłużanie i zagęszczanie rzęs, Presoterapia, Przekłuwanie uszu, Kosmetyczny zabieg trychologiczny, Kosmetyczna diagnostyka trychologiczna oraz, pod zmienionymi nazwami, Piercing (g1-26), składniki aktywne (g1-36) i LED (g1-39). **Model JSON przypisuje zabieg do jednej grupy, a program dopuszcza ten sam zabieg na obu listach.** Ma to znaczenie dla reguły taryfy „Grupy 1 i 2 razem…”: salon kosmetologiczny wykonujący manicure nie miesza grup.
- 9 nieobecnych w JSON w tym brzmieniu: „Masaż endodermiczny” (JSON ma g1-20 „Masaż endodermiczny i drenaż limfatyczny”), „Masaż podciśnieniowy” (JSON ma g1-07 „Endermologia – masaż podciśnieniowy”), „Masaż manualny ciała” (por. g1-21), „Metaterapia”, „Wykonywanie zabiegów na twarz i ciało z zastosowaniem fali radiowej” (osobno od poz. 53), „Masaż transbukalny”, „Masaż mięśniowo-powięziowy”, „Suche igłowanie”, „Needle shaping”.
- „Metaterapia” (zał. 2, poz. 29) stoi w PDF między „Mezoterapia mikroigłowa” a „Microblading”. Wygląda na literówkę („mezoterapia”?), ale CRM przepisał ją tak samo (`crmaura/src/lib/renewals/program.ts:145`). Do wyjaśnienia z ERGO Hestią.

**Gr. 4 (ankieta) – JSON w brzmieniu sprzed Aneksu nr 5.** Aktualne brzmienia według `crmaura/src/lib/renewals/program.ts:92-101`:

| id | JSON | Aneks nr 5 |
|---|---|---|
| g4-01 | Zabiegi technologią HIFU | Zabiegi urządzeniami opartymi na technologii HIFU (skupiona wiązka fal ultradźwiękowych o dużym natężeniu) |
| g4-02 | Zabiegi z użyciem toksyny botulinowej | bez zmian |
| g4-03 | Zabiegi osoczem bogatopłytkowym (PRP) | **Zabiegi z użyciem fibryny, osocza bogatopłytkowego i wypełniaczy autologicznych** (zakres poszerzony) |
| g4-04 | Zabiegi technologią PLASMA | Zabiegi z użyciem urządzeń wykorzystujących technologię PLASMA |
| g4-05 | Wypełniacze – kwas hialuronowy | Zabiegi z użyciem wypełniaczy na bazie kwasu hialuronowego |
| g4-06 | Zabiegi z użyciem nici PDO | **Zabiegi z użyciem nici PDO, PLLA i PLA/CL** (zakres poszerzony) |
| g4-07 | Lipoliza iniekcyjna | Zabiegi lipolizy iniekcyjnej |
| g4-08 | Zabiegi laserem ablacyjnym | **Zabiegi laserami ablacyjnymi i frakcyjno-ablacyjnymi** (zakres poszerzony) |

CRM utrzymuje mapę dawnych nazw na nowe (`program.ts:105-111`). Portal powinien zrobić to samo, jeśli przechowuje wybory klientów.

**Wniosek:** decyzja „1:1 jak w źródłach” jest dziś nieaktualna, bo źródłem obowiązującym od 06.11.2026 są załączniki w brzmieniu Aneksu nr 5. Do decyzji zleceniodawcy:
1. czy JSON przejść na 49 + 63 pozycje z PDF, z dopuszczeniem tego samego zabiegu w dwóch grupach;
2. lista podologiczna w aktualnym brzmieniu;
3. tekst Aneksu nr 5, czyli źródło gr. 4 i daty 06.11.2026.

---

## 5. Brakujące dokumenty

Ta sama lista, w tej samej kolejności, jest w polu `brakujace` manifestu.

| # | Produkt | Dokument | Gdzie szukano | Od kogo | Blokuje |
|---|---|---|---|---|---|
| 1 | OC beauty | OWU OC z tytułu wykonywania czynności zawodowych (ERGO Hestia) dla programu WA50/003353/24/A | wszystkie repo; CRM ma pusty slot (`plikiPubliczne.ts:61`) | Zleceniodawca / ERGO Hestia | **TAK** |
| 2 | OC beauty | Karta produktu (IPID) OC | brak wzmianki w repo | Zleceniodawca / ERGO Hestia | **TAK** |
| 3 | OC beauty | Program WA50/003353/24/A z Aneksem nr 5 albo „Wyciąg z programu Beauty Razem” | `plikiPubliczne.ts:60` | Zleceniodawca | **TAK** |
| 4 | OC beauty | Lista zabiegów – podologiczne (gr. 3), aktualna | `plikiPubliczne.ts:54` (tylko zewnętrzny adres) | Zleceniodawca | nie |
| 5 | OC beauty | Ankieta oceny ryzyka gr. 4 w brzmieniu Aneksu nr 5 (PDF) | generowana w CRM (`renewalDocs.ts:858-861`) | Zleceniodawca (eksport z CRM) | nie |
| 6 | OC beauty | Ulotka warunków, klauzula reklamacyjna, oświadczenie administratora danych, wzór pełnomocnictwa | `plikiPubliczne.ts:59, 62-64` | Zleceniodawca | nie |
| 7 | ER | WU Global Doctors GD 02/24 (R11) | gohestia (OWU.pdf tylko je przywołuje, s. 5), branzowe, ext | Zleceniodawca / ERGO Hestia | **TAK** (dla dodatku GD) |
| 8 | ER | Informacja o dystrybutorze w wersji dla ER (jest wersja ogólna z lipca 2026) | `gohestia/lib/data/documents.ts:24-26` | Zleceniodawca | nie |
| 9 | ER | Pełnomocnictwo ERGO Hestii dla Aura Expert do udostępnienia przed przystąpieniem (zgoda `oswiadczenie_3`). EZB takiej zgody nie ma | `gohestia/app/kalkulator/podsumowanie/page.tsx:379`; gohestia, branzowe – brak pliku | Zleceniodawca | **TAK** (dla zgody `oswiadczenie_3`) |
| 10 | Tax Protect | Potwierdzenie od Colonnade, że OWU z 25.01.2023 (druk 157/0625) i karta produktu są aktualne; poprawiona karta albo wyjaśnienie dwóch świadczeń spoza OWU (T8) | `taxbp/public/`; kubełek `dokumenty` niesprawdzalny (`tax-potwierdz/index.ts:61-67`) | Colonnade / zleceniodawca | **TAK** (T8) |
| 11 | Tax Protect | Potwierdzenie, że informacja o dystrybutorze z lipca 2026 (Colonnade jest na liście zakładów w pkt 8, poz. 9) może służyć dla Tax Protect | — | Zleceniodawca | nie |
| 12 | UD | Informacja o dystrybutorze UD z panelu (`/dystrybutor`) – kopia do porównania z wersją z lipca 2026 | `ud/apps/panel/src/routes/dystrybutor/+server.js:7-24` (plik w kubełku, w repo brak) | Zleceniodawca | nie |
| 13 | Opieka medyczna | Ogólne warunki lub regulaminy pakietów ENEL-MED i LUX MED, ewentualnie karty produktu | wszystkie repo, ext | Zleceniodawca / operatorzy | **TAK** (jeśli portal je udostępnia) |
| 14 | NNW dla dzieci | Bezpośrednie adresy PDF OWU i karty produktu (tylko do linkowania) | ulotka, makieta | Colonnade (strona publiczna) | nie |

Nie są dokumentami produktowymi i zostają w 00: U5 (klauzula informacyjna portalu, zgoda art. 9 RODO, regulamin), E5, R6 i W3 (zatwierdzone teksty prawne).

---

## 6. Wnioski dla portalu

- Strona `/dokumenty` i przy każdym produkcie sekcja dokumentów: OWU, karta produktu (dla ER i EZB wskazać strony w komplecie albo podać osobną kartę), informacja o dystrybutorze i kod lub wersja z datą. Przy zgodach typu z2 (EZB) i `oswiadczenie_1` (ER) dać linki do konkretnych plików przed przyciskiem wysyłki.
- Nie linkować bezpośrednio do `ergo.auraexpert.pl` ani `ergo.beautypolisa.eu`, bo portal ma je zastąpić. Publikować kopie z tego katalogu, a manifest JSON (sha256 i wersja) traktować jako rejestr wersji. Nową wersję wgrywać jako nowy plik, a w e-mailach z potwierdzeniem zapisywać sha256 dokumentu pokazanego klientowi.
- Dla UD rozważyć stały link do `utratadochodu.pl/owu/<slug>.pdf` zamiast kopii, bo tam działa automatyczne wycofywanie wersji. Decyzja razem z W1.
