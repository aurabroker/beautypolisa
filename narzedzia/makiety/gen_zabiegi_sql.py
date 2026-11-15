#!/usr/bin/env python3
"""Generuje w snippets/strefa-klienta.sql funkcję public.zabiegi_ids() z snippets/zabiegi-oc-beauty.json (wersja 2)
(00, D41 – pole i filtr „Zabiegi” w „Dam pracę” i „Szukam pracy”; dane w repozytorium, import przy budowaniu – D29).
Podmienia wyłącznie treść między znacznikami  -- gen:zabiegi-ids  i  -- /gen:zabiegi-ids  (idempotentnie).

Wersjonowanie (lista identyfikatorów tylko rośnie, id nie wraca do użycia):
  * aktywne  = identyfikatory rekordów z bieżącego pliku JSON (listy nr 1 i 2 oraz ankieta), w kolejności pliku;
  * wycofane = identyfikatory, które były w poprzedniej wersji bloku (aktywne albo wycofane) albo są w archiwum
               snippets/zabiegi-oc-beauty-wycofane.json, a nie ma ich w pliku – zostają dozwolone w starych
               ogłoszeniach (CHECK), ale nie można ich dodać do nowych. Każdy wycofany identyfikator musi mieć wpis
               w archiwum (nazwa do wyświetlania w starych ogłoszeniach) – brak wpisu przerywa generowanie;
    identyfikator aktywny nie może być w archiwum (walidacja zabiegi_model.py).
W projekcie ten sam skrypt tworzy nową migrację z poprzedniej (blok czytany z ostatniej migracji); migracja
listy z Aneksu nr 5 razem ze zmianą kolumn client_policies (plan, rozdz. 5) – to nie jest blok generowany.

Uruchom: python3 -I gen_zabiegi_sql.py [--check]
--check: nic nie zapisuje, kod 1, gdy blok w SQL różni się od wygenerowanego.
"""
import hashlib, json, pathlib, re, sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import zabiegi_model as zm  # noqa: E402

ROOT = str(pathlib.Path(__file__).resolve().parents[2] / 'docs/koncepcja')  # repozytorium/docs/koncepcja
SQL = ROOT + '/snippets/strefa-klienta.sql'
ZAB = ROOT + '/snippets/zabiegi-oc-beauty.json'
WYC = ROOT + '/snippets/zabiegi-oc-beauty-wycofane.json'
BLOCK = re.compile(r'(-- gen:zabiegi-ids\n)(.*?)(-- /gen:zabiegi-ids)', re.S)
ID = re.compile(r'^g[1-4]-[0-9]{2}$')  # = zabiegi_model.ID; prefiks historyczny, nie oznacza listy


def arr(ids, indent):
    if not ids:
        return 'array[]::text[]'
    lines, cur = [], []
    for i in ids:
        cur.append("'%s'" % i)
        if len(cur) == 12:
            lines.append(','.join(cur)); cur = []
    if cur:
        lines.append(','.join(cur))
    return 'array[' + (',\n' + ' ' * indent).join(lines) + ']::text[]'


def parse_prev(body):
    def grab(name):
        m = re.search(r'%s\s+text\[\]\s*:=\s*array\[(.*?)\]::text\[\]' % name, body, re.S)
        if not m:
            return []
        return re.findall(r"'([^']+)'", m.group(1))
    return grab('v_aktywne'), grab('v_wycofane')


def main():
    check = '--check' in sys.argv
    raw = open(ZAB, 'rb').read()
    d = json.loads(raw.decode('utf-8'))
    W = zm.wczytaj_wycofane(WYC)
    bledy = zm.waliduj(d, W)
    assert not bledy, 'zabiegi-oc-beauty.json / archiwum wycofanych:\n' + '\n'.join(bledy)
    ids = zm.aktywne_ids(d)
    assert len(set(ids)) == len(ids) and all(ID.match(i) for i in ids), 'identyfikatory unikalne, wzorzec g<N>-NN'
    pod = zm.podsumowanie(d, W)
    sha = hashlib.sha256(raw).hexdigest()
    archiwum = [w['id'] for w in W['wycofane']]

    sql = open(SQL, encoding='utf-8').read()
    found = BLOCK.findall(sql)
    assert len(found) == 1, 'znacznik gen:zabiegi-ids musi wystąpić dokładnie raz'
    prev_akt, prev_wyc = parse_prev(found[0][1])
    wycofane = [i for i in prev_wyc + prev_akt + archiwum if i not in ids]
    wycofane = list(dict.fromkeys(wycofane))  # bez powtórzeń, kolejność pierwszego wystąpienia
    brak = [i for i in wycofane if i not in archiwum]
    assert not brak, ('identyfikatory usunięte z pliku bez wpisu w archiwum %s: %s – dopisz je (id, slug, nazwa) '
                      'do zabiegi-oc-beauty-wycofane.json' % (pathlib.Path(WYC).name, brak))

    p = pod['pozycje']
    block = (
        "-- Wygenerowane skryptem narzedzia/makiety/gen_zabiegi_sql.py z snippets/zabiegi-oc-beauty.json – NIE EDYTOWAĆ RĘCZNIE.\n"
        "-- Wersja listy %d (%s): lista nr 1 – %d, lista nr 2 – %d (wspólne %d), ankieta – %d; aktywne identyfikatory: %d,\n"
        "-- sha256 pliku %s.\n"
        "-- Wycofane (usunięte z pliku – dozwolone tylko w ogłoszeniach, które już je mają; nazwy: zabiegi-oc-beauty-wycofane.json): %s.\n"
        "create or replace function public.zabiegi_ids(p_tylko_aktywne boolean default false)\n"
        "returns text[]\n"
        "language plpgsql immutable parallel safe set search_path = '' as $$\n"
        "declare\n"
        "  v_aktywne  text[] := %s;\n"
        "  v_wycofane text[] := %s;\n"
        "begin\n"
        "  return case when p_tylko_aktywne then v_aktywne else v_aktywne || v_wycofane end;\n"
        "end $$;\n"
    ) % (d['wersja'], d['podstawa'], p['lista-1'], p['lista-2'], pod['wspolne_1_2'], p['ankieta'], len(ids), sha,
         (str(len(wycofane)) + ' – ' + ', '.join(wycofane)) if wycofane else 'brak',
         arr(ids, 22), arr(wycofane, 22))

    new = BLOCK.sub(lambda m: m.group(1) + block + m.group(3), sql)
    if check:
        print('OK' if new == sql else 'RÓŻNICA – uruchom bez --check')
        sys.exit(0 if new == sql else 1)
    if new != sql:
        if open(SQL, encoding='utf-8').read() != sql:
            sys.exit('plik SQL zmienił się w trakcie – uruchom ponownie')
        open(SQL, 'w', encoding='utf-8').write(new)
    print('zabiegi_ids(): aktywne %d, wycofane %d – %s' % (len(ids), len(wycofane), 'zapisano' if new != sql else 'bez zmian'))


main()
