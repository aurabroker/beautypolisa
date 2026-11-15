import pathlib
REPO = str(pathlib.Path(__file__).resolve().parents[4])  # katalog główny repozytorium
import json, re, os, sys
from html.parser import HTMLParser
base = REPO + '/docs/koncepcja/design/v3'
d = json.load(open(REPO + '/docs/koncepcja/snippets/slownik.json'))
class IdP(HTMLParser):
    def __init__(s): super().__init__(); s.ids=set()
    def handle_starttag(s, t, a):
        for k,v in a:
            if k in ('id','name') and v: s.ids.add(v)
cache={}
def ids(f):
    if f not in cache:
        p=os.path.join(base,f)
        if not os.path.exists(p): cache[f]=None
        else:
            P=IdP(); P.feed(open(p,encoding='utf-8').read()); cache[f]=P.ids
    return cache[f]
bad=[]; nohash=[]
for h in d['hasla']:
    for g in h['gdzie']:
        s=g['strona']; f,_,a=s.partition('#')
        I=ids(f)
        if I is None: bad.append((h['id'],s,'brak pliku'))
        elif a and a not in I: bad.append((h['id'],s,'brak kotwicy'))
        elif not a: nohash.append((h['id'],s,g['etykieta']))
print('BRAKI:'); [print(' ',x) for x in bad]
print('BEZ KOTWICY:'); [print(' ',x) for x in nohash]
# also anchors in zrodlo opis strings like 'oc-beauty.html#pytanie-5 i #grupa-4'
print('ZRODLO refs:')
for h in d['hasla']:
    for z in h['zrodlo']:
        o=z.get('opis','')
        cur=None
        for m in re.finditer(r'((?:strefa/)?[a-z0-9-]+\.html)?#([a-z0-9-]+)', o):
            if m.group(1): cur=m.group(1)
            if not cur: continue
            I=ids(cur)
            if I is None: print('  brak pliku',h['id'],cur)
            elif m.group(2) not in I: print('  brak kotwicy',h['id'],cur+'#'+m.group(2))
# zobacz_tez / kategoria
idset={h['id'] for h in d['hasla']}; kat={k['id'] for k in d['kategorie']}
for h in d['hasla']:
    for z in h['zobacz_tez']:
        if z not in idset: print('zobacz_tez bad',h['id'],z)
    if h['kategoria'] not in kat: print('kat bad',h['id'])
    if h['id'] in h['zobacz_tez']: print('self-ref',h['id'])
# reciprocity of zobacz_tez
print('Niewzajemne zobacz_tez (A->B bez B->A):')
zt={h['id']:set(h['zobacz_tez']) for h in d['hasla']}
cnt=0
for a,bs in zt.items():
    for b in bs:
        if a not in zt.get(b,()): cnt+=1
print(' ',cnt)
from collections import Counter
print(Counter(h['kategoria'] for h in d['hasla']))
