# BeautyKatalog

Katalog salonów beauty w Polsce — rejestracja salonów, wykaz zabiegów, mapa, panel właściciela.

## Stack
- Vanilla JS (zero frameworków)
- Supabase (auth + Postgres + Storage)
- Leaflet.js + OpenStreetMap (mapa)
- Google Fonts: Inter + Montserrat

## Pliki
| Plik | Opis |
|------|------|
| `index.html` + `index-app.js` | Katalog / wyszukiwarka salonów |
| `salon.html` + `salon-app.js` | Profil pojedynczego salonu |
| `panel.html` + `panel-app.js` | Panel właściciela (auth + zarządzanie) |
| `app.js` | Shared: Supabase, PROCS, nav, utils |

## Supabase tabele
- `katalog_profiles` — profile właścicieli
- `salons` — dane salonów
- `salon_services` — zabiegi z cenami i czasem
- `salon_photos` — zdjęcia (Supabase Storage bucket: `salon-photos`)
