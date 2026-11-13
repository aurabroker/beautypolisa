# Przeniesienie formularzy ERGO i utraty dochodu do portalu

Decyzja zleceniodawcy (13.11.2026): bez przekierowań na `ergo.auraexpert.pl`, `ergo.beautypolisa.eu` i `utratadochodu.pl/wniosek/` – logika i formularze w portalu BeautyPolisa, w jego stylistyce. NNW dla dzieci zostaje z przekierowaniem do sklepu Colonnade (zakup i płatność od razu u ubezpieczyciela). Osobisty link `portal.beautypolisa.eu/w/XXXXXXXXXX` (APK i wniosek) dotyczy tylko OC, później Tax Protect.

Zawartość (13.11.2026; bez kluczy i danych osobowych). Najpierw inżynieria wsteczna kodu klienckiego, potem kod źródłowy z repozytoriów GitHub zleceniodawcy: `gohestia` (ER), `ud` (UD), `taxbp` (Tax Protect), `branzowe` gałąź `claude/cool-hypatia-ndksid` (EZB), `crmaura` (CRM):
- `00-braki-i-decyzje.md` – co mamy, czego brakuje, od kogo, co blokuje; decyzje W1–W9. Na górze sekcja „Aktualizacja 13.11.2026 – kod z repozytoriów GitHub”: werdykt, statusy braków E*/R*/U*/T*, aktualna lista braków blokujących, rekomendacja W1 i lista tego, czego nie sprawdzono.
- `ergo-zycie-w-biznesie.md` / `.json` – wniosek ERGO Życie w Biznesie (6 kroków, cennik 8 branż, 7 zgód); backend `/api/wnioski`, `/api/gus`, e-maile, bezpieczeństwo (§9–§12).
- `ergo-razem-grupa-otwarta.md` / `.json` – kalkulator i zgłoszenie ERGO Razem – Grupa Otwarta: wszystkie 6 kroków, ankieta, ekrany wykluczeń, 14 zgód, wysyłka 2 e-mailami (§ 9).
- `utratadochodu-wniosek.md` / `.json` – wniosek o ubezpieczenie utraty dochodu (5 kroków, ankiety zdrowotne, szkic); `form-submit`, szkice, przypomnienia, e-maile, przekaz do CRM (§9–§10).
- `tax-protect-wniosek.md` / `.json` – wnioski online Tax Protect (repozytorium `taxbp`): formularz, modal wyceny, funkcje, e-maile, dokumenty, IDD, bezpieczeństwo, braki T1–T15, porównanie z makietą.
- `dokumenty-produktowe.md` – dokumenty przedumowne per produkt: co mamy, czego brakuje, spis plików, rozbieżności list zabiegów OC.

Powiązane poza tym katalogiem:
- `../14-integracja-wnioskow-z-crm.md` – jak wnioski trafiają dziś do CRM Aura Expert, bezpieczeństwo (K1–K12), odpowiedź na W1 z kontraktem punktu przyjęcia.
- `../snippets/dokumenty-produktowe.json` – manifest 24 plików dokumentów (wersja, sha256, źródło) i lista brakujących.
- `../design/v3/dokumenty/` – kopie dokumentów (ER, EZB, UD, Tax Protect, OC beauty), bajt w bajt ze źródłem; przed publikacją wyczyścić metadane.
