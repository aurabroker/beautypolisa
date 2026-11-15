#!/usr/bin/env python3
"""Kontrola list zabiegów OC 1:1 po Aneksie nr 5 (plan, rozdz. 7) – nic nie zapisuje, kod wyjścia 1 przy błędzie.

Źródłem prawdy są PDF list (Załącznik nr 1 i 2 w brzmieniu Aneksu nr 5) i CRM – tę zgodność sprawdza check_zabiegi_pdf.py
(uruchamiany tu; bez repozytorium CRM jego część CRM jest pominięta z komunikatem). Ten skrypt sprawdza, że strony pokazują
dokładnie snippets/zabiegi-oc-beauty.json (wersja 2):
  1. walidacja schematu i archiwum wycofanych (zabiegi_model.waliduj), slug = transliteracja nazwy (1.1);
  2. makieta-v3.html, #zabiegi-data = rekordy list nr 1 i 2 ({id, slug, nazwa, listy}) i ankiety ({id, slug, nazwa, ankieta}),
     w kolejności pliku, bez podologii i bez pól spoza schematu;
  3. oc-beauty.html: sekcje #lista-1, #lista-2, #ankieta – <li> w kolejności, numeracji (value = nr z PDF, ankieta 1–8 = a–h)
     i brzmieniu pozycji (także „Masaż Kobido” na liście nr 2), kotwice <slug> / <slug>-lista-2, odnośniki „także na liście nr …”;
     #podologia – bez pozycji; aliasy dawnych kotwic (#grupa-1…4, dawne slugi, slugi wycofanych) bez hidden (K2);
     w sekcjach list nie ma oznaczeń pojęć a.bp-termin (K3);
  4. strefa/dam-prace.html, #zabiegi-data = listy (klucz, nazwa, liczba), zabiegi (id, nazwa, listy) i wycofane (id, nazwa);
     checkboxy każdego bloku: sekcje lista-1, lista-2, ankieta w kolejności pozycji, nazwy jak na liście, value = id;
  5. snippets/strefa-klienta.sql, zabiegi_ids(): aktywne = id z pliku, wycofane = archiwum.
Uruchom: python3 -I narzedzia/makiety/check_zabiegi_1do1.py [--bez-pdf]
"""
import html, json, pathlib, re, subprocess, sys

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import zabiegi_model as zm  # noqa: E402

V3 = zm.V3
err = []


def blad(s):
    err.append(s)


J = zm.wczytaj()
W = zm.wczytaj_wycofane()
for b in zm.waliduj(J, W):
    blad('JSON: ' + b)
L = zm.listy(J)

# 2. makieta-v3.html – dane wyszukiwarki w kalkulatorze
mk = (V3 / 'makieta-v3.html').read_text(encoding='utf-8')
m = re.search(r'<!-- gen:zabiegi-data -->\n<script type="application/json" id="zabiegi-data">\n(.*?)\n</script>', mk, re.S)
dane = json.loads(m.group(1)) if m else None
ocz = []
for z in J['zabiegi']:
    lst = [p['lista'] for p in z['pozycje']]
    r = {'id': z['id'], 'slug': z['slug'], 'nazwa': z['nazwa']}
    if lst == ['ankieta']:
        r['ankieta'] = z['pozycje'][0]['nr']
    else:
        r['listy'] = lst
    ocz.append(r)
if dane != ocz:
    blad('makieta-v3.html #zabiegi-data ≠ rekordy list nr 1 i 2 oraz ankiety z JSON')

# 3. oc-beauty.html – listy na stronie produktu
oc = (V3 / 'oc-beauty.html').read_text(encoding='utf-8')
kot = {(i, lst): k for i, lst, k in zm.kotwice_wystapien(J)}
poz = {z['id']: z['pozycje'] for z in J['zabiegi']}
for l in J['listy']:
    sek = re.search(r'<section class="zlista[^"]*"[^>]* id="%s"[^>]*>(.*?)</section>' % re.escape(l['kotwica']), oc, re.S)
    if not sek:
        blad('oc-beauty.html: brak sekcji #%s' % l['kotwica'])
        continue
    tresc = sek.group(1)
    li = re.findall(r'<li id="([^"]+)" value="(\d+)">(.*?)</li>', tresc, re.S)
    pozycje = zm.pozycje_listy(J, l['klucz'])
    if len(li) != len(pozycje):
        blad('oc-beauty.html #%s: %d pozycji, w JSON %d' % (l['kotwica'], len(li), len(pozycje)))
    for i, ((lid, val, body), (nr, nazwa, z)) in enumerate(zip(li, pozycje), 1):
        gdzie = 'oc-beauty.html #%s poz. %s' % (l['kotwica'], nr)
        if lid != kot[(z['id'], l['klucz'])]:
            blad('%s: kotwica %r ≠ %r' % (gdzie, lid, kot[(z['id'], l['klucz'])]))
        if val != str(i if isinstance(nr, str) else nr):
            blad('%s: value %s' % (gdzie, val))
        nm = re.search(r'<span class="z-nr">([^<]*)</span> <span class="z-name">([^<]*)</span>', body)
        if not nm or nm.group(1) != (nr + ')' if isinstance(nr, str) else '%d.' % nr) or html.unescape(nm.group(2)) != nazwa:
            blad('%s: numer/brzmienie ≠ JSON (%r)' % (gdzie, nazwa))
        inne = re.findall(r'<a class="z-inna" href="#([^"]+)">także na liście nr (\d), poz\.&nbsp;(\d+)</a>', body)
        ocz_inne = [(kot[(z['id'], p['lista'])], str(L[p['lista']]['numer']), str(p['nr'])) for p in poz[z['id']] if p['lista'] != l['klucz']]
        if inne != ocz_inne:
            blad('%s: odnośniki do drugiej listy %s ≠ %s' % (gdzie, inne, ocz_inne))
    if 'bp-termin' in tresc:
        blad('oc-beauty.html #%s: oznaczenie pojęcia (a.bp-termin) w sekcji listy (K3)' % l['kotwica'])
ids = re.findall(r'\sid="([^"]+)"', oc)
if len(ids) != len(set(ids)):
    blad('oc-beauty.html: powtórzone id %s' % sorted({i for i in ids if ids.count(i) > 1}))
aliasy = [s for z in J['zabiegi'] for s in z.get('dawne_slugi', [])] + [d for l in J['listy'] for d in l.get('dawne_kotwice', [])]
aliasy += [w['slug'] for w in W['wycofane']]
for a in aliasy:
    mm = re.search(r'<span class="z-alias" id="%s"([^>]*)></span>' % re.escape(a), oc)
    if not mm:
        blad('oc-beauty.html: brak aliasu kotwicy #%s' % a)
    elif 'hidden' in mm.group(1):
        blad('oc-beauty.html: alias #%s z atrybutem hidden (K2)' % a)
for w in W['wycofane']:  # aliasy wycofanych prowadzą do sekcji #podologia
    if not re.search(r'id="podologia"[^>]*>(?:(?!</section>).)*id="%s"' % re.escape(w['slug']), oc, re.S):
        blad('oc-beauty.html: alias wycofanej pozycji #%s poza sekcją #podologia' % w['slug'])

# 4. strefa/dam-prace.html
dp = (V3 / 'strefa/dam-prace.html').read_text(encoding='utf-8')
m = re.search(r'<!-- gen:zabiegi-data -->\n<script type="application/json" id="zabiegi-data">\n(.*?)\n</script>', dp, re.S)
D = json.loads(m.group(1)) if m else {}
sekcje = [('lista-1', 'Lista nr 1 – gabinety kosmetyczne i fryzjerskie'), ('lista-2', 'Lista nr 2 – gabinety kosmetyczne i kosmetologiczne'),
          ('ankieta', L['ankieta']['nazwa'])]
if D.get('listy') != [{'klucz': k, 'nazwa': n, 'liczba': len(zm.pozycje_listy(J, k))} for k, n in sekcje]:
    blad('dam-prace.html #zabiegi-data: listy ≠ JSON')
if D.get('zabiegi') != [{'id': z['id'], 'nazwa': z['nazwa'], 'listy': [p['lista'] for p in z['pozycje']]} for z in J['zabiegi']]:
    blad('dam-prace.html #zabiegi-data: zabiegi ≠ JSON')
if D.get('wycofane') != [{'id': w['id'], 'nazwa': w['nazwa']} for w in W['wycofane']]:
    blad('dam-prace.html #zabiegi-data: wycofane ≠ archiwum')
bloki = re.findall(r'<!-- gen:zabiegi-checkboxy:([a-z0-9-]+)[^>]*-->\n(.*?)<!-- /gen:zabiegi-checkboxy', dp, re.S)
if not bloki:
    blad('dam-prace.html: brak bloków gen:zabiegi-checkboxy')
for key, body in bloki:
    det = re.findall(r'<details class="zab-grp" data-lista="([^"]+)"[^>]*>(.*?)</details>', body, re.S)
    if [k for k, _ in det] != [k for k, _ in sekcje]:
        blad('dam-prace.html blok %s: sekcje %s' % (key, [k for k, _ in det]))
    for k, b in det:
        got = [(v, html.unescape(n)) for v, n in re.findall(r'<input type="checkbox" name="zabieg" value="([^"]+)"[^>]*> <span>([^<]*)</span>', b)]
        if got != [(z['id'], n) for _, n, z in zm.pozycje_listy(J, k)]:
            blad('dam-prace.html blok %s, %s: checkboxy ≠ pozycje listy' % (key, k))

# 5. SQL
sql = (zm.SN / 'strefa-klienta.sql').read_text(encoding='utf-8')
blk = re.search(r'-- gen:zabiegi-ids\n(.*?)-- /gen:zabiegi-ids', sql, re.S)
grab = lambda n: re.findall(r"'([^']+)'", re.search(r'%s\s+text\[\]\s*:=\s*array\[(.*?)\]::text\[\]' % n, blk.group(1), re.S).group(1)) if blk else []
if grab('v_aktywne') != zm.aktywne_ids(J):
    blad('strefa-klienta.sql zabiegi_ids(): aktywne ≠ id z JSON')
if sorted(grab('v_wycofane')) != sorted(w['id'] for w in W['wycofane']):
    blad('strefa-klienta.sql zabiegi_ids(): wycofane ≠ archiwum')

# PDF i CRM (źródła)
if '--bez-pdf' not in sys.argv:
    r = subprocess.run([sys.executable, '-I', str(HERE / 'check_zabiegi_pdf.py')], capture_output=True, text=True)
    if r.returncode:
        blad('check_zabiegi_pdf.py: ' + (r.stdout + r.stderr).strip().splitlines()[-1])

print('\n'.join('BŁĄD: ' + e for e in err) if err else
      'OK – listy nr 1 (%d) i 2 (%d), ankieta (%d), podologia bez pozycji; makieta, strona OC, „Dam pracę” i SQL = JSON%s'
      % (len(zm.pozycje_listy(J, 'lista-1')), len(zm.pozycje_listy(J, 'lista-2')), len(zm.pozycje_listy(J, 'ankieta')),
         '' if '--bez-pdf' in sys.argv else '; JSON = PDF (check_zabiegi_pdf.py)'))
sys.exit(1 if err else 0)
