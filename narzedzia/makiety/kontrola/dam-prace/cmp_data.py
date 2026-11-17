"""Dane i checkboxy zabiegów w strefa/dam-prace.html = snippets/zabiegi-oc-beauty.json (wersja 2) i archiwum wycofanych:
#zabiegi-data (listy, zabiegi, wycofane), bloki gen:zabiegi-checkboxy:* (sekcje lista-1, lista-2, ankieta w kolejności
pozycji, nazwy jak na danej liście, value = id, checked = wybór z atrybutu znacznika – każde wystąpienie), chipy div.zab-tags
(kolejność pierwszego wystąpienia, wycofane na końcu z dopiskiem). Nic nie zapisuje."""
import pathlib
import sys
REPO = pathlib.Path(__file__).resolve().parents[4]  # katalog główny repozytorium
sys.path.insert(0, str(REPO / 'narzedzia/makiety'))
import json, re, html  # noqa: E402
import zabiegi_model as zm  # noqa: E402
from typografia import porownaj  # noqa: E402  – twarda spacja (polska typografia) = spacja

J = zm.wczytaj()
W = zm.wczytaj_wycofane()
page = (zm.V3 / 'strefa/dam-prace.html').read_text(encoding='utf-8')
err = []
m = re.search(r'<!-- gen:zabiegi-data -->\n<script type="application/json" id="zabiegi-data">\n(.*?)\n</script>', page, re.S)
emb = json.loads(m.group(1))
S = J['zabiegi']
E = emb['zabiegi']
print('źródło', len(S), 'w stronie', len(E), 'wycofane', len(emb.get('wycofane', [])))
if [(z['id'], z['nazwa'], [p['lista'] for p in z['pozycje']]) for z in S] != [(z['id'], z['nazwa'], z['listy']) for z in E]:
    err.append('zabiegi: id/nazwa/listy/kolejność ≠ JSON')
if [(w['id'], w['nazwa']) for w in W['wycofane']] != [(w['id'], w['nazwa']) for w in emb.get('wycofane', [])]:
    err.append('wycofane ≠ archiwum')
print('pola', sorted({k for z in E for k in z}))
LK = ('lista-1', 'lista-2', 'ankieta')
liczby = [(l['klucz'], l['liczba']) for l in emb['listy']]
if liczby != [(k, len(zm.pozycje_listy(J, k))) for k in LK]:
    err.append('listy: klucze/liczby %s' % liczby)
print('listy', [(l['klucz'], l['nazwa'], l['liczba']) for l in emb['listy']])
if 'synonim' in m.group(1).lower():
    err.append('synonimy w danych')
blocks = re.findall(r'<!-- gen:zabiegi-checkboxy:([a-z0-9-]+)((?: [a-z]+="[^"]*")*) -->(.*?)<!-- /gen:zabiegi-checkboxy:\1 -->', page, re.S)
print('bloki checkboxów', [b[0] for b in blocks])
for key, attrs, b in blocks:
    wybor = (re.search(r'checked="([^"]*)"', attrs) or re.match('()', '')).group(1).split()
    sek = re.findall(r'<details class="zab-grp" data-lista="([^"]+)"[^>]*>.*?<span class="zab-grp-name">(.*?)</span>.*?<span class="zab-grp-n">(\d+)&nbsp;\w+</span>(.*?)</details>', b, re.S)
    if [s[0] for s in sek] != list(LK):
        err.append(key + ': sekcje %s' % [s[0] for s in sek])
    for k, nazwa, n, body in sek:
        rows = re.findall(r'<input type="checkbox" name="zabieg" value="([^"]+)"( checked)?> <span>(.*?)</span>', body)
        if [(v, porownaj(html.unescape(t))) for v, _, t in rows] != [(z['id'], t) for _, t, z in zm.pozycje_listy(J, k)]:
            err.append('%s/%s: checkboxy ≠ pozycje listy' % (key, k))
        if int(n) != len(rows):
            err.append('%s/%s: liczba w nagłówku %s ≠ %d' % (key, k, n, len(rows)))
        if sorted(v for v, c, _ in rows if c) != sorted(v for v, _, _ in rows if v in wybor):
            err.append('%s/%s: checked ≠ wybór %s' % (key, k, wybor))
    print(key, 'wybór', wybor, 'sekcje', [(k, porownaj(html.unescape(nz)), int(n)) for k, nz, n, _ in sek])
names = {z['id']: z['nazwa'] for z in S}
names.update({w['id']: w['nazwa'] + ' (pozycja wycofana z listy)' for w in W['wycofane']})
order = {i: n for n, i in enumerate([z['id'] for z in S] + [w['id'] for w in W['wycofane']])}
ntag = 0
for m2 in re.finditer(r'<div class="zab-tags"([^>]*)>(.*?)</div>', page, re.S):
    ntag += 1
    ids = re.search(r'data-ids="([^"]*)"', m2.group(1)).group(1).split()
    lis = [porownaj(html.unescape(x)) for x in re.findall(r'<li(?: class="zab-tag-wycofany")?>([^<]*)</li>', m2.group(2))]
    bad = [i for i in ids if i not in names]
    if bad:
        err.append('nieznane id ' + str(bad))
        continue
    if ids != sorted(ids, key=order.get):
        err.append('kolejność data-ids ' + str(ids))
    if lis != [names[i] for i in ids][:len(lis)]:
        err.append('nazwy w chipach ' + str(ids) + str(lis))
print('karty z zabiegami', ntag)
print('\n'.join('BŁĄD ' + e for e in err) or 'OK: dane 1:1')
sys.exit(1 if err else 0)
