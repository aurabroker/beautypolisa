# Regresja SQL Strefy Klienta

Testy plików `docs/koncepcja/snippets/schema.sql`, `rls-policies.sql` i `strefa-klienta.sql` na czystym
PostgreSQL 16 z zaślepkami Supabase. Każdy zestaw dostaje własną, świeżą bazę z migracjami w kolejności wdrożenia:
`zaslepki-supabase.sql` → `schema.sql` → `app-is-staff-przed-rls.sql` → `rls-policies.sql` → `strefa-klienta.sql`.
Wynik zestawu porównywany jest ze wzorcem w `wzorce/<zestaw>.out`.

To nie zastępuje testu TEST-21 (dok. 11) na stosie Supabase CLI: zaślepki odtwarzają tylko role `anon`,
`authenticated`, `service_role`, schematy `auth` i `storage`, `auth.uid()` / `auth.jwt()` z ustawień sesji i
minimalne `storage.buckets` / `storage.objects`. Lokalnie właściciel funkcji SECURITY DEFINER jest superużytkownikiem,
a pgcrypto leży w `public` (w Supabase – w `extensions`), dlatego listy uprawnień funkcji pomijają funkcje rozszerzeń.

## Wymagania

- PostgreSQL 16 (`initdb`, `pg_ctl` w `PG_BIN`, domyślnie `/usr/lib/postgresql/16/bin`) i `psql` w `PATH`.
- Jako root klaster należy do użytkownika `postgres`, więc katalog z `SQL_TESTY_TMP` (i każdy katalog nad nim) musi
  być dla niego osiągalny – domyślne `/tmp` jest; przy katalogu prywatnym nadaj prawo przejścia (`chmod o+x`, np. 711).

## Uruchomienie

Wszystkie zestawy i test równoległy:

```bash
narzedzia/sql-testy/uruchom.sh
```

Wybrane zestawy:

```bash
narzedzia/sql-testy/uruchom.sh strefa-t2 zabiegi
```

Zmienne: `PG_BIN`, `SQL_TESTY_PORT` (domyślnie 55450), `SQL_TESTY_TMP` (katalog na klaster tymczasowy, domyślnie
`$TMPDIR` albo `/tmp`), `STREFA_SQL` (inna wersja `strefa-klienta.sql`, np. z `HEAD`). Kod wyjścia 0 – każdy zestaw
zgodny ze wzorcem; 1 – różnica, brak wzorca albo błąd wczytania migracji. Przy różnicy skrypt pokazuje pierwsze
40 linii `diff`; pełne wyniki zostają w katalogu podanym w ostatniej linii („Wyniki: …”).

## Zestawy

| Zestaw | Zakres | Asercje (16.11.2026) |
|---|---|---|
| `strefa-p1` | P1: rejestracja pracodawcy i GUS, SMS, aktywacja i RLS, ogłoszenia (21 dni, promocja), „Szukam pracy”, plany organizatorów, retencja, zawieszenia, przejęcie NIP; uprawnienia funkcji (scenariusz 1) | 281 |
| `strefa-t2` | scenariusze 2–10: konta salonów i zaproszenia, organizatorzy i szkolenia, „Dam pracę”, pracownik, `anon`, formularz kontaktowy, zapisy, dziennik audytu, uprawnienia | 145 |
| `zabiegi` | jak `strefa-p1` (sekcje 0–5) + Z0–Z4: lista zabiegów v2 (00, D41/D43), pole i filtr „Zabiegi”, wycofane pozycje | 222 |
| `platnosci` | płatności za szkolenia (00, D42): wypłaty, zamówienia, rezerwacje, webhooki, zwroty, RLS, prowizja, retencja | 149 |
| `platnosci-redteam` | przegląd red team płatności (RT1–RT9) i RT10 – uprawnienia funkcji po zmianach | 92 |
| `wyscigi` | test równoległy (osobne sesje `psql`): 5 sesji o 1 miejsce, ten sam klucz idempotencji, webhook 3 × naraz | 11 |

Asercje: `t.expect(etykieta, sql, sqlstate)` i `t.eq(etykieta, wynik, oczekiwane)` drukują `ok` albo `FAIL`;
przy wyjątkach z funkcji (wspólny kod P0001) `t.eq(…, t.errmsg(sql), 'P0001 <komunikat>')` sprawdza też treść.
Podsumowanie skryptu liczy wiersze `ok`, `FAIL` i `ERROR`; zdrowy zestaw ma `FAIL=0 ERROR=0`.

## Wzorce

Wzorce zmienia się tylko po świadomej zmianie snippetu albo testu i po przejrzeniu każdej różnicy:

```bash
narzedzia/sql-testy/uruchom.sh --aktualizuj-wzorce strefa-t2
```

Przed zapisem skrypt zastępuje wartości losowe stałymi znacznikami (`<uuid>` dla `gen_random_uuid`, `-<hex8>`
w slugach, `SZ-<nr>` w numerach zamówień), więc porównanie pokazuje tylko zmiany wyników. Ścieżki plików w
komunikatach `psql` są względne, a testy nie wczytują plików spoza repozytorium – wzorce są przenośne.

## Znane błędy we wzorcach

Stan na 16.11.2026: **brak**. Każdy zestaw kończy się `FAIL=0 ERROR=0`, a wzorce zapisano po przejrzeniu różnic.

Usunięte 16.11.2026 (wszystkie powstały przed tą datą i nie wynikały z błędów `strefa-klienta.sql`):

1. `strefa-p1`: `FAIL fn exec anon (none) = admin_users_guard` – funkcja wyzwalacza z `rls-policies.sql` (kopia dok. 02)
   nie miała jawnego `REVOKE`, a `alter default privileges … in schema public` nie odbiera `EXECUTE` roli `PUBLIC`.
   Dopisano `revoke all on function admin_users_guard() from public, anon, authenticated` w `rls-policies.sql` i
   w dok. 02 (w `schema.sql` nie można – wczytuje się przed definicją funkcji). Funkcja zniknęła też z listy
   `authenticated`. Globalna poprawka (`alter default privileges for role postgres revoke execute on functions from public`
   bez `IN SCHEMA`) nadal czeka w dok. 02 na etap Z1.
2. `zabiegi` (Z0, Z4): oczekiwania listy v1 (117 pozycji, nic wycofanego). Po 00, D43 lista ma wersję 2 – 100 aktywnych
   i 31 wycofanych (`g3-01`…`g3-31`; `narzedzia/makiety/gen_zabiegi_sql.py --check` = OK). Z0 sprawdza liczby i grupy
   obu zbiorów; Z4 zamiast przepisywać `zabiegi_ids()` używa naprawdę wycofanego `g3-05`, więc odmowa BP422 przy
   dodaniu wycofanej pozycji wynika z reguły „nowe tylko aktywne”, a nie z nieznanego identyfikatora (jak wcześniej).
3. `strefa-t2`: fikstura sprzed pary `crm_tenant` + `crm_ref` (CHECK `client_accounts_check4`) i sprzed kolumn OC z 00, D43
   (`oc_risk_groups` / `oc_tariff_group` / `'do-5'` → `oc_rodzaje` / `oc_kategoria` / `'1-5'`; składka 882 zł bez zmian
   według `oc-skladka.js`) – pierwszy insert się nie udawał i 70 kroków dziedziczyło błąd. Zestaw przepisano na asercje.
   Przy okazji dwa kroki sprawdzają teraz to, co mówi etykieta: odmowa obrotu tokenu przez właściciela B na aktywnym
   zaproszeniu salonu A (`rotate: brak uprawnień`; dawniej padała na już przyjętym zaproszeniu) i odczyt kontaktów
   uczestników przez organizatora przez Data API (`42501`, obok braku kolumny `user_id`).

Tego samego dnia: `platnosci-redteam` wczytywał na końcu `\i` z katalogu roboczego innej sesji (plik nie istniał) –
zastąpiony sekcją RT10 w samym teście; zestaw `zakladki` (00, D44) zdjęty z listy domyślnej do czasu dodania
`testy/zakladki.sql` i wzorca.
