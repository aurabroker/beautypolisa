# E: statyczne – JSON-LD, dane dymków, linki/kotwice, kontekst oznaczeń
import json, re, pathlib, html, collections
from bs4 import BeautifulSoup
V3 = pathlib.Path(__file__).resolve().parents[4] / 'docs/koncepcja/design/v3'  # repozytorium/docs/koncepcja/design/v3
SJ = json.loads((V3.parent.parent / 'snippets/slownik.json').read_text(encoding='utf-8'))
H = {h['id']: h for h in SJ['hasla']}
# strony z oznaczeniami (lista STRONY w gen_terminy.py; od 15.11.2026 także opieka-medyczna.html i strefa/szkolenia.html) + slownik.html na końcu
PAGES = ['makieta-v3.html','oc-beauty.html','tax-protect.html','utrata-dochodu.html','nnw-dzieci.html','grupowe-ergo.html','opieka-medyczna.html','strefa/logowanie.html','strefa/panel.html','strefa/dam-prace.html','strefa/szkolenia.html','slownik.html']
problemy = []
def P(*a): problemy.append(' '.join(str(x) for x in a)); print('PROBLEM:', *a)
soups = {}
for p in PAGES:
    soups[p] = BeautifulSoup((V3 / p).read_text(encoding='utf-8'), 'lxml')
# ---- JSON-LD na wszystkich stronach
for p, s in soups.items():
    for i, sc in enumerate(s.find_all('script', type='application/ld+json')):
        try: json.loads(sc.string)
        except Exception as e: P(p, 'JSON-LD nie parsuje się', i, e)
# ---- slownik.html: JSON-LD szczegółowo
s = soups['slownik.html']
ids = {t['id'] for t in s.find_all(id=True)}
lds = [json.loads(sc.string) for sc in s.find_all('script', type='application/ld+json')]
print('slownik.html: bloków JSON-LD', len(lds))
graf = [n for d in lds for n in d.get('@graph', [d])]
po_id = collections.Counter(n.get('@id') for n in graf)
print('węzły:', [(n.get('@type'), n.get('@id')) for n in graf if n.get('@type') != 'DefinedTerm'])
for k, c in po_id.items():
    if k and c > 1: P('duplikat @id w grafie', k)
def refs(o, acc):
    if isinstance(o, dict):
        if set(o) == {'@id'}: acc.append(o['@id'])
        for v in o.values(): refs(v, acc)
    elif isinstance(o, list):
        for v in o: refs(v, acc)
acc = []; refs(graf, acc)
known = set(po_id) | {n['@id'] for st in graf if st.get('@type') == 'DefinedTermSet' for n in st['hasDefinedTerm']}
for r in set(acc):
    if r not in known: P('odwołanie @id bez węzła', r)
zb = [n for n in graf if n.get('@type') == 'DefinedTermSet']
assert len(zb) == 1
terms = zb[0]['hasDefinedTerm']
print('DefinedTerm:', len(terms))
if len(terms) != len(SJ['hasla']): P('liczba DefinedTerm', len(terms), '≠', len(SJ['hasla']))
for t in terms:
    m = re.fullmatch(r'https://beautypolisa\.eu/slownik#(haslo-[a-z0-9-]+)', t['url'])
    if not m: P('url hasła', t['url']); continue
    if m.group(1) not in ids: P('url hasła bez kotwicy', t['url'])
    hid = m.group(1)[6:]
    if hid not in H: P('hasło spoza JSON', hid); continue
    if t['name'] != H[hid]['termin']: P('name ≠ termin', hid)
    if t['description'] != H[hid]['definicja']: P('description ≠ definicja', hid)
    if t['inDefinedTermSet'] != {'@id': zb[0]['@id']}: P('inDefinedTermSet', hid)
    if t.get('@id') != t['url']: P('@id ≠ url', hid)
wp = [n for n in graf if n.get('@type') == 'WebPage'][0]
canon = s.find('link', rel='canonical')
print('canonical', canon and canon.get('href'), '| WebPage.url', wp['url'], '| og:url', (s.find('meta', property='og:url') or {}).get('content'))
bc = [n for n in graf if n.get('@type') == 'BreadcrumbList'][0]
print('breadcrumb', [(i['position'], i['name'], i['item']) for i in bc['itemListElement']])
print('title', s.title.string, '| desc', len(s.find('meta', attrs={'name': 'description'})['content']))
# ---- slownik.html: zawartość haseł
arts = s.select('article.haslo')
print('hasła na stronie', len(arts))
if [a['id'][6:] for a in arts] != [h['id'] for h in SJ['hasla']]: P('kolejność/zbiór haseł ≠ JSON')
for a in arts:
    hid = a['id'][6:]
    d = a.select_one('.haslo-def').get_text(' ', strip=True)
    if re.sub(r'\s+', ' ', d) != re.sub(r'\s+', ' ', H[hid]['definicja']).replace(' ', ' '):
        if re.sub(r'\s+', ' ', d.replace(' ',' ')) != re.sub(r'\s+', ' ', H[hid]['definicja']): P('definicja na stronie ≠ JSON', hid)
# wewnętrzne linki na slownik.html
def resolve(p, href):
    if href.startswith(('http:', 'https:', 'tel:', 'mailto:', 'javascript:')): return None
    base = (V3 / p).parent
    path, _, frag = href.partition('#')
    path = path.split('?')[0]
    if path.startswith('/'): return ('abs', href)
    tgt = (base / path).resolve() if path else (V3 / p).resolve()
    if not tgt.exists(): return ('brak pliku', href)
    if frag and tgt.suffix == '.html':
        rel = str(tgt.relative_to(V3.resolve()))
        sp = soups.get(rel) or BeautifulSoup(tgt.read_text(encoding='utf-8'), 'lxml')
        soups[rel] = sp
        if not sp.find(id=frag) and not sp.find(attrs={'name': frag}): return ('brak kotwicy', href)
    return 'ok'
for p in PAGES:
    zle = collections.Counter(); abs_ = set()
    for a in soups[p].find_all('a', href=True):
        r = resolve(p, a['href'])
        if r and r != 'ok':
            if r[0] == 'abs': abs_.add(r[1])
            else: zle[r] += 1
    if zle: print(p, 'linki nierozwiązane:', dict(zle))
    if p == 'slownik.html': print(p, 'linki absolutne (produkcyjne):', sorted(abs_))
# ---- oznaczenia na 11 stronach
ZAK_ANC = {'a','button','label','h1','h2','h3','h4','h5','h6','summary','table','nav','header','footer','form','fieldset','legend','select','textarea','dialog','figcaption','dt','caption'}
for p in PAGES[:-1]:
    s = soups[p]
    ms = s.select('a.bp-termin')
    hids = [m['data-termin'] for m in ms]
    dup = [k for k, c in collections.Counter(hids).items() if c > 1]
    if dup: P(p, 'hasło oznaczone >1 raz', dup)
    if len(ms) > 12: P(p, '>12 oznaczeń')
    for m in ms:
        anc = [x.name for x in m.parents]
        if 'main' not in anc: P(p, m['data-termin'], 'poza main')
        bad = ZAK_ANC & set(anc[:-2]) - set()
        if bad: P(p, m['data-termin'], 'w zakazanym przodku', bad)
        if not ({'p', 'li'} & set(anc)): P(p, m['data-termin'], 'nie w p/li')
        pref = '../' if p.startswith('strefa/') else ''
        if m['href'] != f"{pref}slownik.html#haslo-{m['data-termin']}": P(p, 'href', m['href'])
        if m['data-termin'] not in H: P(p, 'nieznane hasło', m['data-termin'])
        for x in m.parents:
            if x.get('hidden') is not None or x.get('aria-hidden') == 'true' or x.get('aria-live'): P(p, m['data-termin'], 'w ukrytym/aria-live', x.name, x.get('class'))
            if x.get('data-przyklad') == 'tak': P(p, m['data-termin'], 'w przykładzie (data-przyklad="tak")', x.name, x.get('class'))
    dj = s.find('script', id='slownik-dymki')
    if ms:
        D = json.loads(dj.string)
        if set(D) != set(hids): P(p, 'dane dymków ≠ oznaczenia', set(D) ^ set(hids))
        for k, v in D.items():
            if v['u'] != f"{'../' if p.startswith('strefa/') else ''}slownik.html#haslo-{k}": P(p, 'u', k)
            if not v['d'] or len(v['d']) > 600: P(p, 'definicja dymka długość', k, len(v['d']))
        print(f"{p}: {len(ms)} oznaczeń; najdłuższa definicja dymka {max(len(v['d']) for v in D.values())} zn.")
    # link w stopce
    if p.startswith('strefa/'):
        nav = s.find('nav', attrs={'aria-label': 'Stopka'})
        if not nav or not nav.find('a', href='../slownik.html'): P(p, 'brak linku w nav Stopka')
    else:
        if not s.select_one('footer a[href="slownik.html"]'): P(p, 'brak linku w stopce')
        if not s.select_one('nav.menu-panel a[href="slownik.html"]'): P(p, 'brak linku w szufladzie')
s = soups['slownik.html']
print('slownik.html aria-current:', [(a.find_parent(['nav','footer']).name if a.find_parent(['nav','footer']) else None, a.get_text(strip=True)) for a in s.select('[aria-current="page"]')])
print('\nPROBLEMÓW:', len(problemy))
