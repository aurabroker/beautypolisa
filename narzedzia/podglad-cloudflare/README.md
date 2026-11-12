# Podgląd roboczy makiet na Cloudflare Workers

Zamknięty podgląd makiet z `docs/koncepcja/design/v3` (strona główna, strony produktów, Strefa Klienta)
pod adresem `beautypolisa-podglad.<subdomena>.workers.dev`. To nie jest produkcja.

- Dostęp tylko z hasłem (HTTP Basic, użytkownik `beautypolisa`). Hasło jest wyłącznie sekretem Workera
  `PODGLAD_HASLO` – nigdy w repozytorium. Bez sekretu Worker zwraca 503 dla wszystkiego.
- `noindex` (nagłówek `X-Robots-Tag` i `robots.txt`), `Cache-Control: private, no-store`, `Referrer-Policy: no-referrer`.
- Pliki są wbudowane w skrypt (`src/assets.js` generowany z `public/`), bez Workers Assets.

## Aktualizacja

```bash
python3 build.py          # makiety → public/ (linki przepięte na pliki podglądu)
python3 gen_assets.py     # public/ → src/assets.js
npx -y wrangler@4.155.0 deploy
```

Zmiana hasła: `npx -y wrangler@4.155.0 secret put PODGLAD_HASLO`.
Usunięcie podglądu: `npx -y wrangler@4.155.0 delete beautypolisa-podglad`.
