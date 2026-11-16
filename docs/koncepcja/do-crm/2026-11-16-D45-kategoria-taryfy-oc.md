# Zmiana dla CRM: kategoria taryfy OC dla rodzajów działalności z obu list (decyzja D45)

| | |
|---|---|
| Dla | zespołu CRM Aura Expert (repozytorium `crmaura`) |
| Data | 16.11.2026 |
| Źródło decyzji | zleceniodawca, 16.11.2026; rejestr decyzji portalu: `docs/koncepcja/00-koncepcja-portalu-beautypolisa.md`, D45 |
| Stan kodu CRM, do którego odnosi się ten opis | `crmaura` @ `e01fbfb` (11.11.2026) |
| Stan portalu | kalkulator OC portalu liczy już według D45; do czasu zmiany w CRM obie aplikacje dają różne kwoty dla 9 kombinacji z tabeli w p. 3 |

Plik możesz w całości wkleić jako zadanie do sesji pracującej na repozytorium `crmaura`.

## 1. Co zmienić

Zleceniodawca zdecydował (16.11.2026): **gabinet kosmetyczny razem z gabinetem kosmetologicznym płaci według pełnej taryfy**, czyli 850 / 980 / 1250 zł przy sumie 100 / 200 / 300 tys. zł. Dziś CRM liczy dla tej kombinacji taryfę „Gabinety kosmetologiczne”: 650 / 790 / 950 zł.

Portal stosuje decyzję jako zasadę ogólną, tak jak dawny portal („grupy 1 i 2 razem → stawki grupy 3”). Zasada w języku rodzajów działalności z CRM (`RODZAJE_GABINETU`):

- **Załącznik nr 1** (gabinety kosmetyczne i fryzjerskie): `kosmetyczny`, `fryzjerski`, `masaz`;
- **Załącznik nr 2** (gabinety kosmetyczne i kosmetologiczne): `kosmetologiczny`, `tatuaz`;
- **pełna** (`pelny`): `podologiczny` z czymkolwiek albo co najmniej jeden rodzaj z Załącznika nr 1 razem z co najmniej jednym rodzajem z Załącznika nr 2;
- **kosmetologiczna** (`kosmetologiczny`): tylko rodzaje z Załącznika nr 2;
- **podstawowa** (`kosmetyczny_fryzjerski`): tylko rodzaje z Załącznika nr 1.

Różnica wobec obecnej reguły: dziś pełną taryfę daje z Załącznikiem nr 2 tylko `fryzjerski`. Po zmianie dają ją też `kosmetyczny` i `masaz`.

> Do potwierdzenia przed wdrożeniem w CRM: czy ta sama zasada obejmuje salon masażu i salon tatuażu (decyzja zleceniodawcy dosłownie mówi o „salonie kosmetycznym i kosmetologicznym razem”; portal przyjął zasadę ogólną). Jeśli zleceniodawca zawęzi ją do pary `kosmetyczny` + `kosmetologiczny`, w tabeli z p. 3 zostają tylko wiersze z tymi dwoma rodzajami, a portal zostanie poprawiony tak samo.

## 2. Gdzie w kodzie

Jedno miejsce reguły, wiele miejsc użycia. Wystarczy zmienić funkcję, ale sprawdź każde użycie.

| Plik | Co | Zmiana |
|---|---|---|
| `src/lib/renewals/program.ts:53-65` | komentarz i `kategoriaZRodzajow()` | nowa reguła (niżej) i nowy komentarz |
| `src/lib/renewals/program.test.ts:115-125` | testy kategorii i kwot | zmienić oczekiwania (np. `['masaz','kosmetologiczny']` → `'pelny'`, `['tatuaz','kosmetyczny','masaz']` → `'pelny'`), dopisać `['kosmetyczny','kosmetologiczny']` → `'pelny'` i kwotę 980 zł przy 200 000 zł |
| `src/lib/renewals/program.ts:560-570` | `wycenaNowej()` – pierwsza polisa | bez zmian w kodzie; zmienia się wynik |
| `src/lib/renewals/program.ts:678-700` | `wycenaWniosku()` – odnowienie ze zmianą działalności lub sumy | bez zmian w kodzie; zmienia się wynik |
| `src/lib/components/renewal/stan.svelte.ts:210-230` | `skladkiSum` – kwoty przy kafelkach sum we wniosku | bez zmian w kodzie; zmienia się wynik |
| `src/lib/server/renewalDocs.ts:255-270` | `wariantySum()` – warianty sum w e-mailu i PDF | bez zmian w kodzie; zmienia się wynik |
| `src/lib/policyImport/wniosek.ts:94-101` | porównanie zakresu na certyfikacie z kategorią z wniosku | bez zmian w kodzie; **skutek dla istniejących polis** – p. 4 |

Proponowana funkcja (ten sam kontrakt i typy):

```ts
// Kategoria taryfy z rodzajów działalności (decyzja zleceniodawcy z 16.11.2026, D45):
// podologia → pełna; rodzaj z Załącznika nr 1 (kosmetyczny, fryzjerski, masaż) razem z rodzajem
// z Załącznika nr 2 (kosmetologiczny, tatuaż) → pełna; tylko Załącznik nr 2 → kosmetologiczna;
// tylko Załącznik nr 1 → podstawowa.
const RODZAJE_LISTY_1: RodzajGabinetu[] = ['kosmetyczny', 'fryzjerski', 'masaz'];
const RODZAJE_LISTY_2: RodzajGabinetu[] = ['kosmetologiczny', 'tatuaz'];
export function kategoriaZRodzajow(rodzaje: RodzajGabinetu[]): Kategoria | null {
	if (!rodzaje.length) return null;
	const r = new Set(rodzaje);
	const lista1 = RODZAJE_LISTY_1.some((x) => r.has(x));
	const lista2 = RODZAJE_LISTY_2.some((x) => r.has(x));
	if (r.has('podologiczny') || (lista1 && lista2)) return 'pelny';
	if (lista2) return 'kosmetologiczny';
	return 'kosmetyczny_fryzjerski';
}
```

## 3. Kombinacje, które zmieniają kategorię

Z 63 niepustych kombinacji sześciu rodzajów zmienia się 9. Pozostałe 54 dają tę samą kategorię co dziś.

| Rodzaje działalności | Dziś w CRM | Po zmianie (portal już tak liczy) | Składka do 5 osób, 100 / 200 / 300 tys. zł |
|---|---|---|---|
| kosmetyczny + kosmetologiczny | kosmetologiczna | pełna | 650 / 790 / 950 → 850 / 980 / 1250 zł |
| kosmetyczny + tatuaż | kosmetologiczna | pełna | jw. |
| masaż + kosmetologiczny | kosmetologiczna | pełna | jw. |
| masaż + tatuaż | kosmetologiczna | pełna | jw. |
| kosmetyczny + kosmetologiczny + masaż | kosmetologiczna | pełna | jw. |
| kosmetyczny + kosmetologiczny + tatuaż | kosmetologiczna | pełna | jw. |
| kosmetyczny + masaż + tatuaż | kosmetologiczna | pełna | jw. |
| kosmetologiczny + masaż + tatuaż | kosmetologiczna | pełna | jw. |
| kosmetyczny + kosmetologiczny + masaż + tatuaż | kosmetologiczna | pełna | jw. |

Dopłata 6–8 osób (+25 %), ochrona prawna (+92 zł, bez dopłaty), zabiegi z ankiety i więcej niż 8 osób – bez zmian.

## 4. Skutki dla istniejących klientów – do decyzji przed wdrożeniem

- **Odnowienia.** Salon z kombinacją z p. 3, ubezpieczony dziś w taryfie „Gabinety kosmetologiczne”, przy odnowieniu ze zmianą sumy albo działalności dostanie wyższą składkę z pełnej taryfy (np. 790 → 980 zł przy 200 000 zł). Trzeba ustalić, od kiedy nowa reguła obowiązuje: od wniosków złożonych po dacie wdrożenia, od nowego okresu ochrony, czy także dla trwających odnowień (szkice wniosków, otwarte linki).
- **Import polis** (`policyImport/wniosek.ts:94-101`). Certyfikaty wystawione wcześniej dla tych kombinacji mają zakres „Gabinety kosmetologiczne”. Po zmianie porównanie z wnioskiem pokaże różnicę „zakres na polisie … z wniosku wynika Gabinety kosmetyczne, kosmetologiczne, fryzjerskie i podologiczne”. Proponuję porównywać kategorię według reguły z dnia złożenia wniosku albo oznaczać takie różnice jako „sprzed D45”.
- **Zgodność z programem.** Przed wdrożeniem warto potwierdzić u ERGO Hestii, że zakres „Gabinety kosmetyczne, kosmetologiczne, fryzjerskie i podologiczne” jest właściwy dla tych kombinacji (Program WA50/003353/24/A z Aneksem nr 5), bo nazwa kategorii trafia na certyfikat.

## 5. Kryteria odbioru

1. `kategoriaZRodzajow()` daje dla wszystkich 63 kombinacji wynik z zasady w p. 1. Test może wygenerować kombinacje i porównać je z regułą zapisaną w teście albo z tabelą z p. 3 i kategoriami pozostałych 54 bez zmian.
2. `wycenaNowej()` i `wycenaWniosku()` dla `['kosmetyczny','kosmetologiczny']`, do 5 osób, 200 000 zł, bez ochrony prawnej → 980 zł; z 6–8 osobami → 1225 zł; z ochroną prawną → 1072 zł.
3. Kafelki sum we wniosku i warianty w e-mailu/PDF pokazują 850 / 980 / 1250 zł dla tej kombinacji.
4. Decyzja z p. 4 (od kiedy, import polis) zapisana w kodzie i w dokumentacji CRM.
5. Po wdrożeniu daj znać portalowi: wtedy usuwamy oznaczenia `odstepstwo_D45` z `narzedzia/makiety/kontrola/kalkulator-przypadki.json` i wyjątek z `narzedzia/makiety/check_zgodnosc_crm.py` – kontrola zgodności portalu z CRM wraca do pełnej (bez wyjątków).
