# Podgląd roboczy makiet na Cloudflare Workers

Zamknięty podgląd makiet z `docs/koncepcja/design/v3` (strona główna, strony produktów z opieką medyczną, słownik pojęć,
Strefa Klienta ze szkoleniami)
pod adresem https://podglad.beautypolisa.eu (Workers Custom Domain; workers.dev wyłączone). To nie jest produkcja.

- Dostęp tylko z hasłem (HTTP Basic, użytkownik `beautypolisa`). Hasło jest wyłącznie sekretem Workera
  `PODGLAD_HASLO` – nigdy w repozytorium. Bez sekretu Worker zwraca 503 dla wszystkiego.
- `noindex` (nagłówek `X-Robots-Tag` i `robots.txt`), `Cache-Control: private, no-store`, `Referrer-Policy: no-referrer`.
- Pliki są wbudowane w skrypt (`src/assets.js` generowany z `public/`), bez Workers Assets.

## Aktualizacja

```bash
python3 -I build.py       # makiety → public/ (linki przepięte na pliki podglądu; --bez-pdf: bez PDF-ów)
python3 -I gen_assets.py  # public/ → src/assets.js
npx -y wrangler@4.155.0 deploy --dry-run --outdir <katalog roboczy>   # rozmiar paczki bez wdrażania („Total Upload … / gzip …”)
npx -y wrangler@4.155.0 deploy
```

Zmiana hasła: `npx -y wrangler@4.155.0 secret put PODGLAD_HASLO`.
Usunięcie podglądu: `npx -y wrangler@4.155.0 delete beautypolisa-podglad`.

## Zawartość i rozmiar paczki

- Strony: `index.html` (= `makieta-v3.html`), `oc-beauty`, `tax-protect`, `utrata-dochodu`, `nnw-dzieci`, `grupowe-ergo`,
  `opieka-medyczna`, `slownik` (od 15.11.2026 także dwie ostatnie) i wszystkie `strefa/*.html` (logowanie, panel, Dam pracę, szkolenia)
  z `strefa/strefa.css`, `strefa/zakladki.js` (od 16.11.2026; „Zakładki w Strefie”, wspólny skrypt panelu, „Dam pracę” i szkoleń)
  i `strefa/strefa.js` (od 17.11.2026; wspólne wzorce Strefy po raporcie 16: potwierdzenia, „Cofnij”, błędy przy polach; 4 strony).
  Z `img/` – zdjęcia scen (`.webp`) oraz od 17.11.2026 logo 320 px, ikony strony (`.png`) i obraz udostępniania `og-beautypolisa.jpg`
  (raport 15, Z24 i Z25; typ `image/jpeg` w `gen_assets.py`, reguła `Data` dla `*.jpg` w `wrangler.jsonc`).
  Ścieżki produkcyjne `/ubezpieczenia/<produkt>` są przepinane na pliki podglądu, pozostałe ścieżki bezwzględne (np. `/o-nas`,
  `/dokumenty`) – na `#` z `data-podglad="podstrona w przygotowaniu"`. `build.py` wypisuje linki względne do plików spoza paczki
  (stan 17.11.2026: brak; przed dodaniem `strefa.js` do `build.py` – 4 strony Strefy bez tego skryptu).
- PDF-y: tylko te, do których prowadzą linki ze stron – dziś 2 listy zabiegów z `oc-beauty.html` (ok. 190 KB). Całego katalogu
  `design/v3/dokumenty/` (24 pliki, 10,5 MiB, po gzip ok. 7,8 MiB) nie dodajemy: pliki są wbudowane w skrypt Workera, a limit rozmiaru
  skryptu po kompresji to 3 MB w planie Workers Free i 10 MB w Workers Paid – z całym katalogiem paczka miałaby ok. 9,1 MiB po gzip
  (trzykrotnie ponad limit Free, tuż pod limitem Paid; planu konta nie udało się odczytać – brak uprawnień do subskrypcji w API). Gdyby podgląd miał pokazywać wszystkie dokumenty, trzeba przejść na Workers Assets
  (pliki poza skryptem) albo R2.
- Rozmiar 15.11.2026 (25 plików): `Total Upload: 3380.86 KiB / gzip: 1436.13 KiB` (`wrangler deploy --dry-run`).
  17.11.2026 (31 plików): `Total Upload: 3721.49 KiB / gzip: 1610.18 KiB`.
