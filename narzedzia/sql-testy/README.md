# Testy SQL Strefy Klienta (`narzedzia/sql-testy`)

Regresja wzorców bazy z `docs/koncepcja/snippets/` – `schema.sql`, `rls-policies.sql` i `strefa-klienta.sql` – na
tymczasowym PostgreSQL 16 z zaślepkami Supabase. Każdy zestaw dostaje własną, świeżą bazę, a wynik porównujemy
z zapisanym wzorcem (`wzorce/*.out`). Dzięki temu „0 nowych błędów” sprawdza skrypt, a nie człowiek.

Zestawy przeniesiono 16.11.2026 z katalogu roboczego sesji (ostatnie uruchomienie 13.11.2026 przy płatnościach za
szkolenia, 00 D42). Bez sekretów; wszystkie adresy e-mail i domeny są przykładowe (`example.com`, `*.example`).

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
   `t.eq(etykieta, wynik, oczekiwane)` – wartość; wiersz zaczyna się od `ok` albo `FAIL`. Sesję użytkownika udaje
   `set role authenticated` + `t.as_user(uuid, 'aal1'|'aal2')`; serwer – `set role service_role`.
4. Wartości losowe (UUID z `gen_random_uuid()`, końcówki slugów, numery zamówień) zamieniane na znaczniki
   (`<uuid>`, `<hex8>`, `SZ-<nr>`), potem porównanie z `wzorce/<zestaw>.out`.

## Zestawy

| Zestaw | Zakres | Wzorzec (16.11.2026) |
|---|---|---|
| `strefa-p1` | decyzje P1: przełącznik „Szukam pracy”, promocja, pracodawcy (GUS, poziomy zaufania), telefon i limity SMS, oferty i moderacja, „Szukam pracy”, plany organizatorów, retencja, uprawnienia funkcji | ok 280, FAIL 1 (znany) |
| `strefa-t2` | scenariusze konta, zaproszeń, organizatorów i szkoleń (wersja 1.2) | ERROR 70 (znane – fikstura nieaktualna) |
| `zabiegi` | pole i filtr „Zabiegi” (00, D41) w ofertach i „Szukam pracy” | ok 211, FAIL 6, ERROR 4 (znane) |
| `platnosci` | płatności za szkolenia (00, D42; dok. 11 §12a.15 pkt 20) | ok 149 |
| `platnosci-redteam` | przegląd red team płatności (pkt 21) | ok 86 |
| `zakladki` | zakładki w Strefie salonu (00, D44; snippet 10.7a; TEST-21 pkt 22) | ok 86 |
| `wyscigi` | równoległe sesje: 5 osób o 1 miejsce, ten sam klucz idempotencji, webhook 3 × naraz, dwie zakładki naraz (R4), zawieszenie salonu (R5) i odebranie roli właściciela (R6) w trakcie zmiany zakładki, `app_revoke_member()` (R7) i `app_accept_terms()` (R8) w trakcie zmiany zakładki – bez zakleszczenia | ok 23 |

`zakladki` sprawdza: domyślne `{}`; właściciel ukrywa i pokazuje „Pracę” i „Szkolenia” (powtórzenie – ten sam stan,
bez drugiego wpisu w dzienniku); pracownik, właściciel innego salonu, personel, organizator, pracodawca z rejestracji,
właściciel zawieszonego salonu – odmowa; nieznana zakładka i `NULL` – `BP422` bez wartości w komunikacie; brak
`EXECUTE` dla `anon` i `authenticated`; `CHECK` przy zapisie z pominięciem funkcji (nazwa ograniczenia z D44 stała, nazwy
automatyczne sprzed D44 bez przesunięcia – SEC-02 nadal `client_accounts_check5`); odczyt przez członków salonu
istniejącymi politykami i brak `UPDATE` przez Data API; przy ukrytych zakładkach moduły działają tak samo (zapis
pracownika na szkolenie bezpłatne, zamówienie i płatność szkolenia płatnego, publikacja oferty, publiczna tablica,
`app_job_offers_page()`, wiadomość kandydata, „Szukam pracy” zależne tylko od globalnego przełącznika); żadna funkcja
modułu ani polityka RLS nie czyta `ukryte_zakladki`. R4 w `wyscigi` wykrywa zgubioną zmianę bez blokady wiersza, a R5 i R6 –
zmianę przepuszczoną po zawieszeniu salonu albo po odebraniu roli właściciela, gdy funkcja sprawdza stan konta i rolę
przed założeniem blokad (wiersz konta FOR NO KEY UPDATE, wiersz właściciela FOR SHARE). R7 i R8 wykrywają zakleszczenie
(`40P01`) z prawdziwymi `app_revoke_member()` i `app_accept_terms()`: blokują one wiersz członka, a potem dopisują wpis
do `client_audit_log`, którego klucz obcy zakłada `FOR KEY SHARE` na wierszu konta – przy blokadzie konta `FOR UPDATE`
powstaje cykl. Oczekiwane: R7 – odebranie roli wykonane, zmiana zakładki odrzucona (P0001), stan i dziennik zakładek bez
zmian; R8 – oba zapisy przechodzą. Pauzę między blokadą członka a wpisem do dziennika daje wyzwalacz `testy_pauza`
tworzony tylko w bazie testowej (działa w sesji z ustawieniem `testy.pauza_s`).

### Znane błędy we wzorcach (sprzed zmiany 16.11.2026, do odświeżenia osobno)

- `strefa-p1`: `FAIL fn exec anon (none) = admin_users_guard` – funkcja wyzwalacza w `schema.sql` bez `revoke … from anon`.
- `zabiegi`: Z0 i Z4 oczekują listy zabiegów w wersji 1 (117 pozycji, bez wycofanych); po D43 lista ma wersję 2
  (100 aktywnych, 31 wycofanych) – trzeba przepisać oczekiwania, nie snippet.
- `strefa-t2`: fikstura sprzed pary `crm_tenant` + `crm_ref` (12 §5.2) i sprzed nowych kolumn OC (D43) – pierwszy
  `insert` się nie udaje, a dalsze kroki dziedziczą błąd; wzorzec pilnuje, żeby nie doszły nowe różnice.

## Kiedy aktualizować wzorce

Tylko po świadomej zmianie snippetu albo testu: uruchom bez `--aktualizuj-wzorce`, przejrzyj `diff` (każda różnica
musi wynikać ze zmiany), dopiero potem `--aktualizuj-wzorce <zestaw>` dla zestawów, których dotyczy zmiana. Nowy
zestaw: plik `testy/<nazwa>.sql` (nagłówek z helperami `t.*` jak w istniejących), dopisanie nazwy do `WSZYSTKIE`
w `uruchom.sh` i pierwszy wzorzec.

## Ograniczenia

Czysty PostgreSQL z zaślepkami nie zastępuje TEST-21 z końca `strefa-klienta.sql` (lokalny stos Supabase CLI albo
gałąź projektu: prawdziwe role, Data API, właściciele funkcji SECURITY DEFINER, `max_rows`). Testy nie sprawdzają
interfejsu – to robią testy makiet w `narzedzia/makiety/kontrola/`.
