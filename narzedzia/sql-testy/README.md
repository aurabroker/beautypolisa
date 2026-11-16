# Testy SQL Strefy Klienta (`narzedzia/sql-testy`)

Regresja wzorców bazy z `docs/koncepcja/snippets/` – `schema.sql`, `rls-policies.sql` i `strefa-klienta.sql` – na
tymczasowym PostgreSQL 16 z zaślepkami Supabase. Każdy zestaw dostaje własną, świeżą bazę, a wynik porównujemy
z zapisanym wzorcem (`wzorce/*.out`). Dzięki temu „0 nowych błędów” sprawdza skrypt, a nie człowiek.

Zestawy przeniesiono 16.11.2026 z katalogu roboczego sesji (ostatnie uruchomienie 13.11.2026 przy płatnościach za
szkolenia, 00 D42). Bez sekretów; wszystkie adresy e-mail i domeny są przykładowe (`example.com`, `*.example`) –
poza hostami wideokonferencji (`zoom.us`, `meet.google.com`), które CHECK adresu spotkania dopuszcza z listy.

## Uruchomienie

```bash
narzedzia/sql-testy/uruchom.sh                      # wszystkie zestawy i test równoległy
narzedzia/sql-testy/uruchom.sh zakladki wyscigi      # wybrane zestawy
STREFA_SQL=/ścieżka/strefa-klienta.sql narzedzia/sql-testy/uruchom.sh   # inna wersja snippetu (np. z HEAD)
narzedzia/sql-testy/uruchom.sh --aktualizuj-wzorce zakladki             # zapis nowego wzorca – patrz niżej
```

Wynik: jeden wiersz na zestaw (`ok=`, `FAIL=`, `ERROR=` i stan porównania ze wzorcem). Przy różnicy skrypt pokazuje
`diff` (do 40 wierszy) i kończy się kodem 1. Pełne wyniki zostają w katalogu podanym w ostatnim wierszu.

Wymagania: `bash`, PostgreSQL 16 (`initdb`, `pg_ctl` w `PG_BIN`, domyślnie `/usr/lib/postgresql/16/bin`) i `psql`
w `PATH`. Serwer słucha tylko na `127.0.0.1` (bez gniazda unix), z `trust` – wyłącznie do testów; po zakończeniu
katalog danych jest usuwany.

| Zmienna | Domyślnie | Znaczenie |
|---|---|---|
| `PG_BIN` | `/usr/lib/postgresql/16/bin` | katalog z `initdb` i `pg_ctl` |
| `SQL_TESTY_PORT` | `55450` | port tymczasowego serwera |
| `SQL_TESTY_TMP` | `$TMPDIR` albo `/tmp` | gdzie powstaje klaster i wyniki |
| `STREFA_SQL` | `docs/koncepcja/snippets/strefa-klienta.sql` | testowana wersja snippetu |

Uruchomienie jako `root`: Postgres nie startuje jako root, więc skrypt tworzy klaster jako użytkownik `postgres`
(`runuser`). Katalog z `SQL_TESTY_TMP` musi być dla niego osiągalny – domyślne `/tmp` jest; przy katalogu
prywatnym nadaj prawo przejścia (np. `chmod 711`) każdemu katalogowi nadrzędnemu.

## Jak to działa

1. `initdb` w katalogu tymczasowym (UTF-8, `C.UTF-8`, strefa `Etc/UTC`), start serwera.
2. Dla każdego zestawu: nowa baza i migracje w kolejności wdrożenia – `zaslepki-supabase.sql` (role `anon`,
   `authenticated`, `service_role`, schematy `auth` i `storage`, `auth.uid()` i `auth.jwt()` z ustawień sesji jak
   w PostgREST) → `schema.sql` → `app-is-staff-przed-rls.sql` (w `rls-policies.sql` polityki używają funkcji przed jej
   definicją) → `rls-policies.sql` → `strefa-klienta.sql`. Błąd wczytania = błąd zestawu.
3. Plik zestawu z `testy/` przez `psql`. Asercje: `t.expect(etykieta, sql, sqlstate)` – oczekiwany błąd,
   `t.eq(etykieta, wynik, oczekiwane)` – wartość; wiersz zaczyna się od `ok` albo `FAIL`. Wyjątki z funkcji mają
   wspólny kod `P0001`, więc tam `t.eq(…, t.errmsg(sql), 'P0001 <komunikat>')` sprawdza też treść (w `strefa-t2`).
   Sesję użytkownika udaje `set role authenticated` + `t.as_user(uuid, 'aal1'|'aal2')`; serwer – `set role service_role`.
   Testy nie wczytują plików spoza repozytorium.
4. Wartości losowe (UUID z `gen_random_uuid()`, końcówki slugów, numery zamówień) zamieniane na znaczniki
   (`<uuid>`, `<hex8>`, `SZ-<nr>`), potem porównanie z `wzorce/<zestaw>.out`.

## Zestawy

| Zestaw | Zakres | Wzorzec (16.11.2026) |
|---|---|---|
| `strefa-p1` | decyzje P1: przełącznik „Szukam pracy”, promocja, pracodawcy (GUS, poziomy zaufania), telefon i limity SMS, oferty i moderacja, „Szukam pracy”, plany organizatorów, retencja, uprawnienia funkcji | ok 281 |
| `strefa-t2` | scenariusze 2–10: konta salonów i zaproszenia, organizatorzy i szkolenia, „Dam pracę”, pracownik, `anon`, formularz kontaktowy, zapisy, dziennik audytu, uprawnienia | ok 145 |
| `zabiegi` | pole i filtr „Zabiegi” (00, D41) w ofertach i „Szukam pracy”; lista w wersji 2 (00, D43), wycofane pozycje | ok 222 |
| `platnosci` | płatności za szkolenia (00, D42; dok. 11 §12a.15 pkt 20) | ok 149 |
| `platnosci-redteam` | przegląd red team płatności (pkt 21); RT10 – uprawnienia funkcji po zmianach | ok 92 |
| `zakladki` | zakładki w Strefie salonu (00, D44; snippet 10.7a; TEST-21 pkt 22) | ok 84 |
| `wyscigi` | równoległe sesje: 5 osób o 1 miejsce, ten sam klucz idempotencji, webhook 3 × naraz, dwie zakładki naraz (R4) | ok 13 |

`zakladki` sprawdza: domyślne `{}`; właściciel ukrywa i pokazuje „Pracę” i „Szkolenia” (powtórzenie – ten sam stan,
bez drugiego wpisu w dzienniku); pracownik, właściciel innego salonu, personel, organizator, pracodawca z rejestracji,
właściciel zawieszonego salonu – odmowa; nieznana zakładka i `NULL` – `BP422` bez wartości w komunikacie; brak
`EXECUTE` dla `anon` i `authenticated`; `CHECK` przy zapisie z pominięciem funkcji; odczyt przez członków salonu
istniejącymi politykami i brak `UPDATE` przez Data API; przy ukrytych zakładkach moduły działają tak samo (zapis
pracownika na szkolenie bezpłatne, zamówienie i płatność szkolenia płatnego, publikacja oferty, publiczna tablica,
`app_job_offers_page()`, wiadomość kandydata, „Szukam pracy” zależne tylko od globalnego przełącznika); żadna funkcja
modułu ani polityka RLS nie czyta `ukryte_zakladki`. R4 w `wyscigi` wykrywa zgubioną zmianę bez blokady wiersza.

### Znane błędy we wzorcach

Stan na 16.11.2026: **brak** – każdy zestaw kończy się `FAIL=0 ERROR=0`. Usunięte tego dnia (powstały wcześniej
i nie wynikały z błędów `strefa-klienta.sql`):

- `strefa-p1`: `FAIL fn exec anon (none) = admin_users_guard` – funkcja wyzwalacza z `rls-policies.sql` (kopia dok. 02,
  nie `schema.sql`) nie miała jawnego `REVOKE`, a `alter default privileges … in schema public` nie odbiera `EXECUTE`
  roli `PUBLIC`. Dopisano `revoke all on function admin_users_guard() from public, anon, authenticated` w snippecie i
  w dok. 02; funkcja zniknęła też z listy `authenticated`. Globalna poprawka uprawnień domyślnych (bez `IN SCHEMA`)
  nadal czeka w dok. 02 na etap Z1.
- `zabiegi`: Z0 sprawdza listę v2 (131 znanych, 100 aktywnych: g1 47, g2 45, g4 8; wycofane dokładnie `g3-01`…`g3-31`).
  Z4 używa naprawdę wycofanego `g3-05` zamiast przepisywać `zabiegi_ids()`, więc odmowa `BP422` wynika z reguły
  „nowe tylko aktywne”, a nie z nieznanego identyfikatora.
- `strefa-t2`: fikstura z parą `crm_tenant` + `crm_ref` i kolumnami OC z D43 (`oc_rodzaje`, `oc_kategoria`, `'1-5'`;
  składka 882 zł bez zmian według `oc-skladka.js`); zestaw przepisany na asercje z zachowaniem intencji wierszy
  „ERR expected” – dwa kroki sprawdzają teraz to, co mówi etykieta (obrót tokenu przez obcego właściciela na
  aktywnym zaproszeniu; odczyt kontaktów uczestników przez Data API).
- `platnosci-redteam`: koniec testu wczytywał `\i` z katalogu roboczego innej sesji – zastąpiony sekcją RT10.

## Kiedy aktualizować wzorce

Tylko po świadomej zmianie snippetu albo testu: uruchom bez `--aktualizuj-wzorce`, przejrzyj `diff` (każda różnica
musi wynikać ze zmiany), dopiero potem `--aktualizuj-wzorce <zestaw>` dla zestawów, których dotyczy zmiana. Nowy
zestaw: plik `testy/<nazwa>.sql` (nagłówek z helperami `t.*` jak w istniejących), dopisanie nazwy do `WSZYSTKIE`
w `uruchom.sh` i pierwszy wzorzec.

## Ograniczenia

Czysty PostgreSQL z zaślepkami nie zastępuje TEST-21 z końca `strefa-klienta.sql` (lokalny stos Supabase CLI albo
gałąź projektu: prawdziwe role, Data API, właściciele funkcji SECURITY DEFINER, `max_rows`). Lokalnie pgcrypto leży
w `public` (w Supabase – w `extensions`), dlatego listy uprawnień funkcji pomijają funkcje rozszerzeń. Testy nie
sprawdzają interfejsu – to robią testy makiet w `narzedzia/makiety/kontrola/`.
