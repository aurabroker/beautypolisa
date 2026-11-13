# Przeniesienie trzech formularzy do BeautyPolisy: co mamy, czego brakuje

Stan na 2026-11-13, po przeglądzie krytyka kompletności. Dotyczy trzech aplikacji, które portal ma przestać linkować i odtworzyć u siebie w stylistyce „old money glass” (makiety `docs/koncepcja/design/v3`):

| Skrót | Aplikacja | Specyfikacja | Dane do makiety |
|---|---|---|---|
| **EZB** | ERGO Życie w Biznesie, wniosek dla salonu (`ergo.auraexpert.pl/wniosek?branza=beauty`) | `ergo-zycie-w-biznesie.md` | `ergo-zycie-w-biznesie.json` |
| **ER** | ERGO Razem – Grupa Otwarta, kalkulator i zgłoszenie (`ergo.beautypolisa.eu`) | `ergo-razem-grupa-otwarta.md` | `ergo-razem-grupa-otwarta.json` |
| **UD** | Utrata dochodu, wniosek 5 kroków (`utratadochodu.pl/wniosek/`) | `utratadochodu-wniosek.md` | `utratadochodu-wniosek.json` |

## Werdykt: czy mamy wszystko?

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

### W2. Turnstile i ochrona formularzy
- Wszystkie trzy formularze przechodzą na **jeden standard portalu** (02 §2.2): honeypot → idempotencja → rate limit → Zod → Turnstile (`siteverify` w Workerze, sprawdzenie `hostname` i `action`).
- EZB dziś nie ma Turnstile ani honeypota. UD ma dwa widżety (niewidoczny w kroku 1 dla szkicu, widoczny w kroku 5). ER ma tylko flagę w store.
- Do ustalenia: nowy sitekey i secret dla domeny portalu (konto Cloudflare zleceniodawcy). Przy wariancie A trzeba też ustalić, czy funkcje CRM nadal wymagają `cf-turnstile-response`. Wtedy weryfikacja musiałaby iść tam, a nie w Workerze, bo token jest jednorazowy. Alternatywa: CRM ufa Workerowi po sekrecie.
- Poprawić znaną usterkę UD: zgoda bez tokenu nie może wysyłać `zgoda:false`.

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
- Niezależnie od wariantu: przy każdym formularzu informacje o agencie (art. 22 UDU) z `legal-distributor.json` z wersją. Uwaga: `ergo.beautypolisa.eu/informacja-o-agencie` podaje „XIII Wydział”, a portal używa „XII” (D38).

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

## 3. Braki blokujące (lista do wysłania zleceniodawcy)

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
- Makieta ER: krok „Wiek”, kalkulator składki (taryfy A1/A2/B, dodatki) i tabela świadczeń. Kroki 2–6 jako szkielety z oznaczeniem „brak treści od zleceniodawcy”.
- Schematy Zod i kontrakty API portalu dla trzech formularzy (niezależne od W1).
- Rejestr zgód z obecnymi treściami i wersjami, gotowy do podmiany na zatwierdzone.
