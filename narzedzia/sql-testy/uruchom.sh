#!/usr/bin/env bash
# Regresja SQL Strefy Klienta: snippets/schema.sql + rls-policies.sql + strefa-klienta.sql na tymczasowym
# PostgreSQL 16 z zaślepkami Supabase. Każdy zestaw dostaje własną, świeżą bazę. Opis: README.md obok.
#
#   narzedzia/sql-testy/uruchom.sh                 – wszystkie zestawy i test równoległy (wyscigi)
#   narzedzia/sql-testy/uruchom.sh zakladki zabiegi – wybrane zestawy
#   narzedzia/sql-testy/uruchom.sh --aktualizuj-wzorce [zestawy] – zapisuje bieżące wyniki jako wzorce
#                                                    (tylko po świadomej zmianie snippetu albo testu)
# Zmienne: PG_BIN (domyślnie /usr/lib/postgresql/16/bin), SQL_TESTY_PORT (55450), SQL_TESTY_TMP (katalog
# na klaster tymczasowy, domyślnie $TMPDIR albo /tmp), STREFA_SQL (inna wersja strefa-klienta.sql, np. z HEAD).
# Kod wyjścia: 0 – każdy zestaw zgodny ze wzorcem; 1 – różnica albo błąd wczytania.
set -uo pipefail

TU=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO=$(cd "$TU/../.." && pwd)
SNIP=$REPO/docs/koncepcja/snippets
STREFA_SQL=${STREFA_SQL:-$SNIP/strefa-klienta.sql}
PG_BIN=${PG_BIN:-/usr/lib/postgresql/16/bin}
PORT=${SQL_TESTY_PORT:-55450}
WSZYSTKIE=(strefa-p1 strefa-t2 zabiegi platnosci platnosci-redteam zakladki wyscigi)

AKTUALIZUJ=0
if [ "${1:-}" = "--aktualizuj-wzorce" ]; then AKTUALIZUJ=1; shift; fi
ZESTAWY=("$@"); [ ${#ZESTAWY[@]} -eq 0 ] && ZESTAWY=("${WSZYSTKIE[@]}")

for b in initdb pg_ctl; do
  [ -x "$PG_BIN/$b" ] || { echo "Brak $PG_BIN/$b – ustaw PG_BIN na katalog z PostgreSQL 16"; exit 1; }
done
command -v psql >/dev/null || { echo "Brak psql w PATH"; exit 1; }

TMP=$(mktemp -d "${SQL_TESTY_TMP:-${TMPDIR:-/tmp}}/sql-testy.XXXXXX")
WYNIKI=$TMP/wyniki; mkdir -p "$WYNIKI"
# Postgres nie startuje jako root – wtedy klaster należy do użytkownika postgres (katalog musi być dla niego
# osiągalny: domyślne /tmp jest; przy SQL_TESTY_TMP w katalogu prywatnym nadaj mu prawo przejścia, np. 711).
jako_pg() { if [ "$(id -u)" = 0 ]; then runuser -u postgres -- "$@"; else "$@"; fi; }
[ "$(id -u)" = 0 ] && chown postgres "$TMP"
jako_pg "$PG_BIN/initdb" -D "$TMP/data" -U postgres -A trust --no-sync -E UTF8 --locale=C.UTF-8 >"$TMP/initdb.log" 2>&1 \
  || { echo "initdb nie powiódł się:"; tail -5 "$TMP/initdb.log"; exit 1; }
jako_pg "$PG_BIN/pg_ctl" -D "$TMP/data" -o "-p $PORT -k '' -h 127.0.0.1 -c fsync=off -c timezone=Etc/UTC" -l "$TMP/data/serwer.log" -w start >/dev/null \
  || { echo "Serwer nie wystartował (port $PORT zajęty?)"; tail -5 "$TMP/data/serwer.log"; exit 1; }
sprzataj() { jako_pg "$PG_BIN/pg_ctl" -D "$TMP/data" -m fast stop >/dev/null 2>&1; rm -rf "$TMP/data"; }
trap sprzataj EXIT

PSQL=(psql -X -h 127.0.0.1 -p "$PORT" -U postgres)

# świeża baza z migracjami w kolejności wdrożenia (zaślepki → schema → app_is_staff → RLS → strefa)
wczytaj() {
  local db=$1
  "${PSQL[@]}" -q -c "drop database if exists $db" -c "create database $db" >/dev/null || return 1
  "${PSQL[@]}" -q -v ON_ERROR_STOP=1 -d "$db" -f "$TU/zaslepki-supabase.sql" >/dev/null 2>&1 || return 1
  "${PSQL[@]}" -q -v ON_ERROR_STOP=1 -d "$db" -f "$SNIP/schema.sql" >/dev/null || return 1
  "${PSQL[@]}" -q -v ON_ERROR_STOP=1 -d "$db" -f "$TU/app-is-staff-przed-rls.sql" >/dev/null || return 1
  "${PSQL[@]}" -q -v ON_ERROR_STOP=1 -d "$db" -f "$SNIP/rls-policies.sql" >/dev/null || return 1
  "${PSQL[@]}" -q -v ON_ERROR_STOP=1 -d "$db" -f "$STREFA_SQL" >"$WYNIKI/wczytanie-$db.log" 2>&1 || return 1
}

# test równoległy (SEC-18, 12a.15 pkt 20): 5 sesji o 1 miejsce, ten sam klucz idempotencji, webhook 3 × naraz
wyscigi() {
  local db=wyscigi Q=("${PSQL[@]}" -d wyscigi -tAq) W=$TMP/wyscigi T2 ST O B
  mkdir -p "$W"
  "${PSQL[@]}" -q -d $db -f "$TU/testy/wyscigi-fixture.sql" >/dev/null 2>&1
  T2=$("${Q[@]}" -c "select id from trainings where title like 'Laminacja%'")
  ST=$("${Q[@]}" -c "select id from organizer_sales_terms where status='active'")
  B='{"buyer_kind":"osoba","buyer_name":"U Przykładowy","invoice_email":"u@example.com"}'
  sprawdz() { if [ "$2" = "$3" ]; then echo " ok   $1 = $2"; else echo " FAIL $1 = $2 (oczekiwano $3)"; fi; }
  sprawdz "fixture: szkolenie opublikowane, 1 miejsce" "$("${Q[@]}" -c "select status||'/'||capacity from trainings where id='$T2'")" "published/1"
  local g U pids=()
  for g in 1 2 3 4 5; do
    U=00000000-0000-0000-0000-00000000010$g
    "${Q[@]}" -c "set role service_role" -c "begin" -c "select order_id from public.app_training_order_create('$T2','$U','aaaaaaaa-0000-0000-0000-000000000001',gen_random_uuid(),'$ST','U$g Przykładowy','u$g@example.com','$B','sprz-v1')" -c "select pg_sleep(1)" -c "commit" >"$W/r1_$g.out" 2>&1 & pids+=($!)
  done
  wait "${pids[@]}"; pids=()
  sprawdz "R1 5 sesji o 1 miejsce: rezerwacje" "$("${Q[@]}" -c "select count(*) from training_orders where training_id='$T2' and status='reserved'")" 1
  sprawdz "R1 seats_held/capacity" "$("${Q[@]}" -c "select seats_held||'/'||capacity from trainings where id='$T2'")" "1/1"
  sprawdz "R1 odmowy BP409 brak wolnych miejsc" "$(grep -l 'brak wolnych miejsc' "$W"/r1_*.out | wc -l)" 4
  "${Q[@]}" -c "update trainings set capacity = 5 where id='$T2'" >/dev/null
  for g in 1 2 3; do
    "${Q[@]}" -c "set role service_role" -c "select order_id from public.app_training_order_create('$T2','00000000-0000-0000-0000-000000000106','aaaaaaaa-0000-0000-0000-000000000001','22222222-2222-2222-2222-222222222222','$ST','U6 Przykładowy','u6@example.com','$B','sprz-v1')" >"$W/r2_$g.out" 2>&1 & pids+=($!)
  done
  wait "${pids[@]}"; pids=()
  sprawdz "R2 ten sam klucz idempotencji 3 × naraz: zamówienia" "$("${Q[@]}" -c "select count(*) from training_orders where user_id='00000000-0000-0000-0000-000000000106'")" 1
  sprawdz "R2 zwrócone identyfikatory (różne)" "$(cat "$W"/r2_*.out | grep -v '^SET' | sort -u | grep -c .)" 1
  sprawdz "R2 seats_held" "$("${Q[@]}" -c "select seats_held from trainings where id='$T2'")" 2
  O=$("${Q[@]}" -c "select id from training_orders where user_id='00000000-0000-0000-0000-000000000106'")
  "${Q[@]}" -c "set role service_role" -c "select public.app_training_payment_attach('$O','00000000-0000-0000-0000-000000000106','stripe','pi_RACE',now())" >/dev/null
  for g in 1 2 3; do
    "${Q[@]}" -c "set role service_role" -c "select public.app_payment_webhook('stripe','evt_race','payment.succeeded','pi_RACE',null,'$O',30000,'PLN',repeat('a',64))" >"$W/r3_$g.out" 2>&1 & pids+=($!)
  done
  "${Q[@]}" -c "set role service_role" -c "select public.app_payment_webhook('stripe','evt_race_b','payment.succeeded','pi_RACE',null,'$O',30000,'PLN',repeat('b',64))" >"$W/r3_4.out" 2>&1 & pids+=($!)
  wait "${pids[@]}"; pids=()
  sprawdz "R3 webhook 3 × naraz + inne zdarzenie" "$(cat "$W"/r3_*.out | grep -v '^SET' | sort | uniq -c | awk '{print $1"x"$2}' | tr '\n' ' ')" "2xduplicate 1xignored_stale 1xpaid "
  sprawdz "R3 zapisy u6" "$("${Q[@]}" -c "select count(*) from training_registrations where user_id='00000000-0000-0000-0000-000000000106' and status='registered'")" 1
  sprawdz "R3 liczniki held/registered" "$("${Q[@]}" -c "select seats_held||'/'||seats_registered from trainings where id='$T2'")" "1/1"
  sprawdz "R3 wiersze webhooków pi_RACE" "$("${Q[@]}" -c "select count(*) from payment_webhook_events where provider_ref='pi_RACE'")" 2
}

KOD=0
for z in "${ZESTAWY[@]}"; do
  db=${z//-/_}
  if [ "$z" != wyscigi ] && [ ! -f "$TU/testy/$z.sql" ]; then echo "$z: brak pliku testy/$z.sql"; KOD=1; continue; fi
  if ! wczytaj "$db"; then
    echo "$z: BŁĄD WCZYTANIA migracji"; tail -5 "$WYNIKI/wczytanie-$db.log" 2>/dev/null; KOD=1; continue
  fi
  if [ "$z" = wyscigi ]; then
    wyscigi >"$WYNIKI/$z.out" 2>&1
  else
    # ścieżka względna: komunikaty psql zawierają nazwę pliku, a nie katalog maszyny (wzorce są przenośne)
    (cd "$TU/testy" && "${PSQL[@]}" -d "$db" -f "$z.sql" >"$WYNIKI/$z.out" 2>&1)
  fi
  ok=$(grep -c '^ ok ' "$WYNIKI/$z.out"); fail=$(grep -c 'FAIL' "$WYNIKI/$z.out"); err=$(grep -c 'ERROR' "$WYNIKI/$z.out")
  wzor=$TU/wzorce/$z.out
  if [ $AKTUALIZUJ = 1 ]; then
    mkdir -p "$TU/wzorce"; cp "$WYNIKI/$z.out" "$wzor"; stan="wzorzec zapisany"
  elif [ ! -f "$wzor" ]; then
    stan="BRAK WZORCA"; KOD=1
  elif diff -q "$wzor" "$WYNIKI/$z.out" >/dev/null; then
    stan="zgodny ze wzorcem"
  else
    stan="RÓŻNICA ze wzorcem (diff poniżej)"; KOD=1
  fi
  printf '%-18s ok=%-4s FAIL=%-3s ERROR=%-3s %s\n' "$z" "$ok" "$fail" "$err" "$stan"
  if [ "$stan" = "RÓŻNICA ze wzorcem (diff poniżej)" ]; then diff "$wzor" "$WYNIKI/$z.out" | head -40; fi
done
echo "Wyniki: $WYNIKI"
exit $KOD
