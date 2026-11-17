#!/usr/bin/env python3
"""Makieta /ubezpieczenia/oc-beauty: generuje bloki strony z JSON-ów (jedno źródło prawdy).

  python3 -I gen_oc_beauty.py          # podmienia bloki <!-- GEN:… --> … <!-- /GEN:… --> w oc-beauty.html i zapisuje
                                       # snippets/schema-faq-oc-beauty.json (FAQPage = widoczne pytania)
  python3 -I gen_oc_beauty.py --check  # nic nie zapisuje; kod 1 i różnice, gdy strona albo schema-faq są nieaktualne
  python3 -I gen_oc_beauty.py --init   # historyczne: składa stronę z gen_oc_beauty.szablon.html (szablon sprzed Aneksu nr 5,
                                       # bez znacznika GEN:taryfa – dziś kończy się błędem „brak znacznika”)

Bloki: jsonld, zabiegi-skok, zabiegi, zabiegi-reguly, taryfa, klauzula, faq; poza blokami – liczby pozycji list w elementach
data-gen="liczba-lista-1", "liczba-lista-2", "liczba-ankieta" oraz słowo „pozycja” uzgodnione z liczbą w data-gen="pozycje-<lista>".
Źródła (docs/koncepcja/snippets/): zabiegi-oc-beauty.json (wersja 2: listy nr 1 i 2 z PDF Aneksu nr 5, ankieta a–h, podologia –
dokument) i zabiegi-oc-beauty-wycofane.json (aliasy kotwic), taryfa-oc-beauty.json (stawki, dopłata, ochrona prawna, zdania CRM),
faq-oc-beauty.json (pytania), klauzula-ochrona-prawna.json, schema-produkt-oc-beauty.json, schema-home.json.

Kotwice (plan 1.5, uwaga K2): <li id="<slug>"> przy pierwszym wystąpieniu zabiegu, <li id="<slug>-lista-2"> przy drugim;
dawne slugi, #grupa-1…4 i slugi wycofanych pozycji podologicznych – puste elementy <span class="z-alias" id="…"></span>
BEZ atrybutu hidden (element z hidden nie przyjmuje przewinięcia do #fragmentu).
Zakazane frazy (plan 6.8, uwaga K7) – sprawdzane w blokach tego generatora (oc_frazy.py).
Polska typografia (raport 16, 3.1): widoczny tekst bloków przez typografia.py (twarde spacje po jednoliterowych wyrazach, „nr 1”,
„poz. 5”, „8 pozycji”, „5 osób”, półpauza zamiast pauzy); brzmienie list, klauzuli i zdań CRM bez zmian, FAQPage (JSON-LD) –
tekst bez twardych spacji.
"""
import html, json, re, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import zabiegi_model as zm  # noqa: E402
import oc_taryfa as ot  # noqa: E402
import typografia as ty  # noqa: E402
from oc_frazy import sprawdz, tekst_html, raport  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]  # katalog główny repozytorium
SNIP = ROOT / 'docs/koncepcja/snippets'
V3 = ROOT / 'docs/koncepcja/design/v3'
PAGE = V3 / 'oc-beauty.html'
SCHEMA_FAQ = SNIP / 'schema-faq-oc-beauty.json'
TEMPLATE = Path(__file__).with_name('gen_oc_beauty.szablon.html')
URL = 'https://beautypolisa.eu/ubezpieczenia/oc-beauty'
KONTAKT = 'makieta-v3.html?produkt=oc-beauty#kontakt'
OPIS_STRONY = ('OC zawodowe dla gabinetów kosmetycznych, fryzjerskich, kosmetologicznych i podologicznych. Program ERGO Hestia, '
               'sumy 100–300 tys. zł, stała taryfa. Oblicz składkę.')  # = meta description i og:description (plan, rozdz. 3; check())

NB = ' '
e = lambda s: html.escape(str(s), quote=True)


def eh(s):
    """Escapowanie z twardą spacją jako &nbsp; (czytelne źródło HTML)."""
    return e(s).replace(NB, '&nbsp;')


def load(name):
    with open(SNIP / name, encoding='utf-8') as f:
        return json.load(f)


Z = zm.wczytaj()
WYC = zm.wczytaj_wycofane()
_bledy = zm.waliduj(Z, WYC)
if _bledy:
    sys.exit('zabiegi-oc-beauty.json / archiwum wycofanych:\n' + '\n'.join(_bledy))
L = zm.listy(Z)
T = ot.T
K = load('klauzula-ochrona-prawna.json')
S = load('schema-produkt-oc-beauty.json')
H = load('schema-home.json')
F = load('faq-oc-beauty.json')
LISTY_NUM = [l for l in Z['listy'] if l.get('numer')]           # listy nr 1 i 2 (numery pozycji z PDF)
ANKIETA = zm.ankieta(Z)                                         # jedna mapa a–h: litera, id, nazwa, slug
LICZBY = {l['klucz']: len(zm.pozycje_listy(Z, l['klucz'])) for l in Z['listy']}


def plural(n, one, few, many):
    d, h = n % 10, n % 100
    return one if n == 1 else few if 2 <= d <= 4 and not 12 <= h <= 14 else many


def pozycji(n):
    return '%d %s' % (n, plural(n, 'pozycja', 'pozycje', 'pozycji'))


def strip_tags(s):
    return html.unescape(re.sub(r'<[^>]+>', '', s)).replace(NB, ' ')


# ---------- FAQ (snippets/faq-oc-beauty.json): wartości wstawiane z danych ----------
def pole(k):
    p = k.split('.')
    if k == 'program.numer':
        return Z['program']['numer_programu']
    if k == 'wspolne':
        return str(zm.podsumowanie(Z)['wspolne_1_2'])
    if k == 'doplata':
        return ot.doplata_proc()
    if k == 'op.skladka':
        return ot.zl(T['ochrona_prawna']['skladka'])
    if k == 'reguly_kategorii':
        return ot.reguly_kategorii()
    if p[0] in L and len(p) == 2:
        if p[1] == 'liczba':
            return str(LICZBY[p[0]])
        if p[1] == 'pozycji':
            return pozycji(LICZBY[p[0]])
        if p[1] == 'nazwa':
            return L[p[0]]['nazwa']
        if p[0] == 'ankieta':
            hit = [a for a in ANKIETA if a['litera'] == p[1]]
            if hit:
                return hit[0]['nazwa']
    if p[0] == 'kategoria' and len(p) == 2:
        return ot.KAT[p[1]]['nazwa']
    if p[0] == 'stawka' and len(p) == 3:
        return ot.zl(ot.stawka(p[1], int(p[2])))
    if p[0] == 'kwota_6_8' and len(p) == 3:
        return ot.zl_gr(ot.kwota(p[1], int(p[2]), '6-8'))
    if p[0] == 'suma' and len(p) == 2:
        assert int(p[1]) in T['sumy'], k
        return ot.suma_pelna(int(p[1]))
    raise KeyError('faq-oc-beauty.json: nieznane pole {%s}' % k)


def wypelnij(s):
    """Tekst HTML z polami {…} → HTML (wartości escapowane, twarda spacja jako &nbsp;)."""
    return re.sub(r'\{([a-z0-9_.-]+)\}', lambda m: eh(pole(m.group(1))), s)


def teksty_crm(klucz):
    """Zdania CRM przytaczane dosłownie – jedna implementacja dla obu stron (oc_taryfa.teksty_crm; K16)."""
    return ot.teksty_crm(klucz)


def bez_pauzy(t):
    """FAQPage = widoczne pytania: ta sama półpauza co w widocznym tekście (typografia.py: „ — ” → „ – ”), bez twardych spacji."""
    return t.replace(' — ', ' – ')


def faq():
    """[(pytanie, html odpowiedzi, tekst odpowiedzi do FAQPage)] – jedna lista dla widocznych pytań, GEN:jsonld i schema-faq."""
    out = []
    # „od … do …” w pytaniu o cenę: najniższa i najwyższa stawka taryfy (kontrola, że tekst nie rozjedzie się z taryfą)
    st = [v for k in T['kategorie'] for v in k['skladka'].values()]
    assert ot.stawka('kosmetyczny_fryzjerski', 100000) == min(st) and ot.stawka('pelny', 300000) == max(st)
    for q in F['pytania']:
        h, t = [], []
        for b in q['odpowiedz']:
            if isinstance(b, str):
                x = wypelnij(b)
                h.append('<p>%s</p>' % ty.html(x))
                t.append(bez_pauzy(strip_tags(x)))
            else:
                items = teksty_crm(b['crm'])
                h.append('<ul>' + ' '.join('<li>%s</li>' % ty.html(eh(i)) for i in items) + '</ul>')
                t.append(bez_pauzy(' '.join(items)))
        out.append((q['pytanie'], ' '.join(h), ' '.join(t)))  # spacja między blokami: tekst DOM = tekst FAQPage
    return out


FAQ = faq()


# ---------- bloki ----------
def block_jump():
    out = ['<nav class="zjump" aria-labelledby="z-skok-tytul">', '  <p id="z-skok-tytul">Przejdź do listy</p>', '  <ul>']
    for l in Z['listy']:
        n = LICZBY[l['klucz']]
        etyk = 'Lista nr %d' % l['numer'] if l.get('numer') else ('Ankieta' if l['klucz'] == 'ankieta' else 'Podologia')
        if n:
            out.append(f'    <li><a href="#{e(l["kotwica"])}">{ty.html(etyk)} <span>{n}</span>'
                       f'<span class="sr-only"> {plural(n, "pozycja", "pozycje", "pozycji")}</span></a></li>')
        else:
            out.append(f'    <li><a href="#{e(l["kotwica"])}">{ty.html(etyk)}</a></li>')
    out += ['  </ul>', '</nav>']
    return out


def _wystapienia():
    """{(id, lista): kotwica} i {id: [(lista, nr)]} – dla odnośników „także na liście nr …”."""
    kot = {(i, lst): k for i, lst, k in zm.kotwice_wystapien(Z)}
    poz = {z['id']: [(p['lista'], p['nr']) for p in z['pozycje']] for z in Z['zabiegi']}
    return kot, poz


def _alias(i, ind):
    return f'{ind}<span class="z-alias" id="{e(i)}"></span>'


def block_listy():
    kot, poz = _wystapienia()
    pierwsze = {z['id']: z['slug'] for z in Z['zabiegi']}
    out = []
    for l in Z['listy']:
        k, a = l['klucz'], l['kotwica']
        items = zm.pozycje_listy(Z, k)
        n = len(items)
        assert n == (l['liczba_pozycji'] or 0), (k, n)
        etyk = ' data-z-lista="lista nr %d"' % l['numer'] if l.get('numer') else ''
        dok = ' zlista--dokument' if not n else ''
        out.append(f'<section class="zlista{dok} glass glass--tint" id="{e(a)}" aria-labelledby="{e(a)}-tytul"{etyk}>')
        out += [_alias(d, '  ') for d in l.get('dawne_kotwice', [])]
        if k == 'podologia':  # aliasy slugów wycofanych pozycji podologicznych (archiwum) – prowadzą do tej sekcji
            out += [_alias(w['slug'], '  ') for w in WYC['wycofane']]
        out.append('  <div class="zlista-head">')
        out.append('    <div class="zlista-title">')
        if l.get('numer'):
            m = re.match(r'(Załącznik nr \d+)\b', l['zalacznik'])
            assert m, l['zalacznik']
            out.append(f'      <p class="eyebrow">{ty.esc(m.group(1) + " · " + pozycji(n))}</p>')
        elif n:
            out.append(f'      <p class="eyebrow">Brzmienie Aneksu nr&nbsp;5 · {ty.esc(pozycji(n))}</p>')
        else:
            out.append('      <p class="eyebrow">Dokumenty programu</p>')
        out.append(f'      <h3 id="{e(a)}-tytul">{ty.esc(l["nazwa"])}</h3>')
        if k == 'ankieta':
            out.append('      <p class="zlista-desc">%s</p>' % ty.esc('Przy tych zabiegach całą składkę wycenia indywidualnie ubezpieczyciel na podstawie ankiety.'))
        elif not n:  # podologia (decyzja Q1): bez listy pozycji – informacja i kontakt
            out.append('      <p class="zlista-desc">Lista zabiegów podologicznych jest w&nbsp;dokumentach programu. '
                       f'<a href="{KONTAKT}">Zapytaj doradcę o&nbsp;listę zabiegów podologicznych</a>.</p>')
        out.append('    </div>')
        if l.get('dokument'):
            nr = ('&nbsp;nr&nbsp;%d' % l['numer']) if l.get('numer') else ''  # spacje twarde: „nr 2” i „nr 5” bez łamania (390 px)
            out.append(f'    <p class="zlista-doc"><a class="link-lux" href="{e(l["dokument"])}">Pobierz listę{nr} (PDF, Aneks&nbsp;nr&nbsp;5)</a></p>')
        out.append('  </div>')
        if n:
            litery = l.get('numeracja') == 'litery'
            co = ('listy nr %d' % l['numer']) if l.get('numer') else ('%s–%s' % (items[0][0], items[-1][0]))
            out.append('  <details class="zdetails" open>')
            out.append(f'    <summary><span>{ty.esc("Pozycje " + co)} (<span data-z-ile>{n}</span>)</span></summary>')
            out.append('    <ol class="zlist"%s>' % (' type="a"' if litery else ''))
            for idx, (nr, nazwa, z) in enumerate(items, 1):
                kotw = kot[(z['id'], k)]
                aliasy = ''.join(f'<span class="z-alias" id="{e(s)}"></span>' for s in z.get('dawne_slugi', []) if kotw == pierwsze[z['id']])
                znak = f'{nr})' if litery else f'{nr}.'
                inne = ''
                for lst, nr2 in poz[z['id']]:
                    if lst != k:
                        inne += (f' <a class="z-inna" href="#{e(kot[(z["id"], lst)])}">także na liście nr&nbsp;{L[lst]["numer"]}, '
                                 f'poz.&nbsp;{nr2}</a>')
                out.append(f'      <li id="{e(kotw)}" value="{idx if litery else nr}">{aliasy}<span class="z-nr">{znak}</span> '
                           f'<span class="z-name">{ty.esc(nazwa)}</span>{inne}</li>')
            out.append('    </ol>')
            out.append('    <p class="zback"><a class="link-quiet" href="#zabiegi">Wróć na początek listy</a></p>')
            out.append('  </details>')
        out.append('</section>')
    return out


def block_rules():
    zdania = [
        eh(ot.reguly_kategorii()),
        '6–8&nbsp;osób wykonujących zabiegi – składka z&nbsp;taryfy wyższa o&nbsp;%s (ochrona prawna +%d&nbsp;zł bez tej dopłaty).'
        % (ot.doplata_proc(), T['ochrona_prawna']['skladka']),
        'Więcej niż 8&nbsp;osób wykonujących zabiegi – wycena indywidualna.',
        'Zabiegi wymagające ankiety ERGO Hestii – cała składka do indywidualnej wyceny.',
    ]
    return ['<ul>'] + [f'  <li>{ty.html(s)}</li>' for s in zdania] + ['</ul>']


def block_taryfa():
    return ot.tabela_taryfy('Taryfa OC dla branży beauty')


def block_clause():
    out = ['<header class="clause-head">',
           '  <p class="clause-label">Pełna treść klauzuli</p>',
           f'  <h3 id="klauzula-tytul">{ty.esc(K["tytul"])}</h3>']
    out.append('</header>')
    out.append('<ol class="clause-text">')
    for p in K['punkty']:
        if p.get('wyliczenie'):
            out.append(f'  <li>{ty.esc(p["tekst"])}')
            out.append('    <ul>')
            out += [f'      <li>{ty.esc(w)}</li>' for w in p['wyliczenie']]
            out.append('    </ul>')
            out.append('  </li>')
        else:
            out.append(f'  <li>{ty.esc(p["tekst"])}</li>')
    out.append('</ol>')
    out.append('<p class="clause-foot">%s</p>' % ty.esc('Klauzula do programu ubezpieczenia OC dla branży beauty nr %s (ERGO Hestia). '
                                                     'Pozostałe postanowienia umowy określają Warunki Ubezpieczenia programu.' % Z['program']['numer_programu']))
    return out


def block_faq():
    return [f'<details id="pytanie-{i}"><summary>{ty.esc(q)}</summary>{a}</details>' for i, (q, a, _) in enumerate(FAQ, 1)]


def home_node(suffix, keys):
    g = H.get('@graph', [])
    n = next(x for x in g if x.get('@id') == 'https://beautypolisa.eu/#' + suffix)
    return {k: n[k] for k in keys if k in n}


def faq_page():
    return {'@type': 'FAQPage', '@id': URL + '#faq', 'url': URL, 'inLanguage': 'pl-PL', 'mainEntity': [
        {'@type': 'Question', 'name': q, 'acceptedAnswer': {'@type': 'Answer', 'text': t}} for q, _, t in FAQ]}


def schema_faq_text():
    """snippets/schema-faq-oc-beauty.json – ten sam FAQPage co w GEN:jsonld (samodzielny dokument z @context)."""
    return json.dumps({'@context': 'https://schema.org', **faq_page()}, ensure_ascii=False, indent=2) + '\n'


def block_jsonld():
    service = {k: v for k, v in S.items() if k != '@context'}
    org = home_node('organization', ('@type', '@id', 'name', 'legalName', 'alternateName', 'description', 'url', 'identifier', 'address'))
    agency = home_node('agency', ('@type', '@id', 'name', 'alternateName', 'description', 'url', 'address', 'parentOrganization'))
    assert '11229690/A' in json.dumps(org) and 'broker' not in json.dumps([org, agency])
    assert service['@id'] == URL + '#service' and 'broker' not in json.dumps(service)
    graph = [
        {'@type': 'WebPage', '@id': URL + '#webpage', 'url': URL, 'inLanguage': 'pl-PL',
         'name': 'OC dla branży beauty (ERGO Hestia) | BeautyPolisa',
         'description': OPIS_STRONY,
         'breadcrumb': {'@id': URL + '#breadcrumb'}, 'mainEntity': {'@id': URL + '#service'},
         'publisher': {'@id': 'https://beautypolisa.eu/#organization'}},
        {'@type': 'BreadcrumbList', '@id': URL + '#breadcrumb', 'itemListElement': [
            {'@type': 'ListItem', 'position': 1, 'name': 'Strona główna', 'item': 'https://beautypolisa.eu/'},
            {'@type': 'ListItem', 'position': 2, 'name': 'Ubezpieczenia', 'item': 'https://beautypolisa.eu/ubezpieczenia'},
            {'@type': 'ListItem', 'position': 3, 'name': 'OC dla branży beauty', 'item': URL}]},
        service,
        org,
        agency,
        faq_page(),
    ]
    doc = json.dumps({'@context': 'https://schema.org', '@graph': graph}, ensure_ascii=False, indent=1).replace('</', '<\\/')
    return ['<!-- JSON-LD: WebPage, BreadcrumbList, Service (= snippets/schema-produkt-oc-beauty.json, bez „broker”), Organization i InsuranceAgency '
            '(minimalne węzły z snippets/schema-home.json – cel odwołań publisher/offeredBy), FAQPage (= widoczne pytania '
            '= snippets/schema-faq-oc-beauty.json, oba z snippets/faq-oc-beauty.json) -->',
            '<script type="application/ld+json">'] + doc.split('\n') + ['</script>']


BLOCKS = {'jsonld': block_jsonld, 'zabiegi-skok': block_jump, 'zabiegi': block_listy,
          'zabiegi-reguly': block_rules, 'taryfa': block_taryfa, 'klauzula': block_clause, 'faq': block_faq}
# data-gen="…" → liczba pozycji listy; minimalna liczba znaczników na stronie
LICZNIKI = {'liczba-lista-1': ('lista-1', 2), 'liczba-lista-2': ('lista-2', 2), 'liczba-ankieta': ('ankieta', 1)}


def inject(src):
    for name, fn in BLOCKS.items():
        pat = re.compile(r'([ \t]*)<!-- GEN:' + re.escape(name) + r'(?: [^>]*)? -->.*?<!-- /GEN:' + re.escape(name) + r' -->', re.S)
        m = pat.search(src)
        if not m:
            sys.exit(f'brak znacznika GEN:{name}')
        ind = m.group(1)
        body = '\n'.join(ind + line for line in fn())
        new = f'{ind}<!-- GEN:{name} (wygenerowane – narzedzia/makiety/gen_oc_beauty.py; nie edytować ręcznie) -->\n{body}\n{ind}<!-- /GEN:{name} -->'
        src = src[:m.start()] + new + src[m.end():]
    if 'data-gen="liczba-zabiegow"' in src:
        sys.exit('na stronie został znacznik data-gen="liczba-zabiegow" (wersja 1 listy) – zastąp go liczbą pozycji listy: '
                 + ', '.join('data-gen="%s"' % k for k in LICZNIKI))
    for dg, (lst, minimum) in LICZNIKI.items():
        src, k = re.subn(r'(<[a-z]+ data-gen="%s">)[^<]*(</[a-z]+>)' % dg, lambda m: f'{m.group(1)}{LICZBY[lst]}{m.group(2)}', src)
        if k < minimum:
            sys.exit(f'za mało znaczników data-gen="{dg}" ({k}, minimum {minimum})')
    # data-gen="pozycje-<lista>" – słowo „pozycja” w formie uzgodnionej z liczbą pozycji tej listy (np. tekst dla czytnika ekranu
    # po „49 + 63” w hero: rzeczownik uzgadnia się z ostatnią liczbą – „63 pozycje”)
    for lst, n in LICZBY.items():
        src = re.sub(r'(<[a-z]+ data-gen="pozycje-%s"[^>]*>)[^<]*(</[a-z]+>)' % re.escape(lst),
                     lambda m, n=n: f'{m.group(1)} {plural(n, "pozycja", "pozycje", "pozycji")}{m.group(2)}', src)
    return src


def init():
    mk = (V3 / 'makieta-v3.html').read_text(encoding='utf-8')
    a = mk.index('/* ---------- fonty zastępcze')
    b = mk.index('/* ---------- prolog: hero')
    base = mk[a:b].rstrip() + '\n'
    used = sorted(set(re.findall(r'href="#(lux-[a-z-]+)"', TEMPLATE.read_text(encoding='utf-8'))))
    syms = [re.search(r'^\s*<symbol id="' + u + r'".*?</symbol>$', mk, re.M | re.S).group(0) for u in used]
    sprite = ('<svg class="sprite" xmlns="http://www.w3.org/2000/svg" width="0" height="0" aria-hidden="true" focusable="false">\n'
              '  <!-- BeautyPolisa v3 – ikony old money (kopie symboli z makieta-v3.html, tylko używane tutaj). -->\n'
              + '\n'.join(syms) + '\n</svg>')
    t = TEMPLATE.read_text(encoding='utf-8').replace('/*@@BASE_CSS@@*/', base).replace('<!--@@SPRITE@@-->', sprite)
    return t


def bloki(src):
    """{nazwa: treść} bloków GEN:* na stronie."""
    return dict(re.findall(r'<!-- GEN:([a-z-]+)(?: [^>]*)? -->\n(.*?)<!-- /GEN:\1 -->', src, flags=re.S))


def check(src):
    ids = re.findall(r'\sid="([^"]+)"', src)
    dup = sorted({i for i in ids if ids.count(i) > 1})
    assert not dup, f'powtórzone id: {dup}'
    idset = set(ids)
    # kotwice: wystąpienia, dawne slugi, sekcje i ich dawne kotwice, slugi wycofanych
    wymagane = [k for _, _, k in zm.kotwice_wystapien(Z)] + [s for z in Z['zabiegi'] for s in z.get('dawne_slugi', [])]
    wymagane += [l['kotwica'] for l in Z['listy']] + [d for l in Z['listy'] for d in l.get('dawne_kotwice', [])]
    wymagane += [w['slug'] for w in WYC['wycofane']]
    brak = [k for k in wymagane if k not in idset]
    assert not brak, f'brak kotwic na stronie: {brak}'
    # K2: aliasy bez hidden (inaczej przeglądarka nie przewinie do #fragmentu)
    assert not re.search(r'<span class="z-alias"[^>]*\shidden', src), 'alias kotwicy z atrybutem hidden'
    B = bloki(src)
    # listy 1:1: kolejność, numery i brzmienie pozycji = JSON (= PDF, check_zabiegi_pdf.py)
    for l in Z['listy']:
        sek = re.search(r'<section class="zlista[^"]*"[^>]* id="%s"[^>]*>(.*?)</section>' % re.escape(l['kotwica']), B['zabiegi'], re.S)
        assert sek, l['kotwica']
        li = re.findall(r'<li id="[^"]+" value="(\d+)">(?:<span class="z-alias"[^>]*></span>)*<span class="z-nr">([^<]+)</span> '
                        r'<span class="z-name">([^<]*)</span>', sek.group(1))
        ocz = [(str(i if isinstance(nr, str) else nr), (f'{nr})' if isinstance(nr, str) else f'{nr}.'), ty.esc(n))
               for i, (nr, n, _) in enumerate(zm.pozycje_listy(Z, l['klucz']), 1)]
        assert li == ocz, f'lista {l["klucz"]}: pozycje na stronie ≠ JSON'
        assert 'bp-termin' not in sek.group(1), f'lista {l["klucz"]}: oznaczenie pojęcia w nazwie pozycji (K3)'
    assert 'data-syn' not in src and 'z-via' not in src, 'lista 1:1: bez synonimów'
    # klauzula słowo w słowo (z polską typografią – twarde spacje nie zmieniają brzmienia)
    for p in K['punkty']:
        assert ty.esc(p['tekst']) in src
        for w in p.get('wyliczenie', []):
            assert ty.esc(w) in src
    # zakazane frazy (6.8, K7) w blokach generatora; wyjątki: dawne brzmienia ankiety, nazwy z archiwum wycofanych
    wyjatki = [n for z in Z['zabiegi'] for n in z.get('dawne_nazwy', [])] + [w['nazwa'] for w in WYC['wycofane']]
    traf = [(n, t) for n, b in B.items() for t in sprawdz(tekst_html(b), wyjatki)]
    assert not traf, '\n'.join(raport('oc-beauty.html GEN:' + n, [t]) for n, t in traf)
    # cała strona – słowa, których nie było już przed Aneksem nr 5 (dawny zestaw)
    for bad in ('orientacyjn', 'szacunkow', 'poglądow', 'przykładowa składka', 'polecamy', 'najlepszy wybór', 'rekomendacj',
                'najczęściej wybier'):
        assert bad not in src.lower(), bad
    # opis strony: meta description i og:description = WebPage.description w GEN:jsonld
    for wz in (r'<meta name="description" content="([^"]*)">', r'<meta property="og:description" content="([^"]*)">'):
        mm = re.search(wz, src)
        assert mm and html.unescape(mm.group(1)) == OPIS_STRONY, 'opis strony (%s) ≠ OPIS_STRONY w generatorze' % wz[:30]
    # K12 (rozstrzygnięcie): pierwsze zdanie komunikatu CRM o zabiegach z innej listy – dosłownie w sekcji list zabiegów
    tekst = html.unescape(re.sub(r'<[^>]+>', '', src)).replace('\u00a0', ' ')
    assert ot.zdanie_z_innej_listy() in tekst, 'K12: brak zdania CRM o zabiegach z innej listy'
    # FAQ: widoczne pytania = FAQPage
    assert len(re.findall(r'<details id="pytanie-\d+">', B['faq'])) == len(F['pytania'])


def main():
    if '--check' in sys.argv:  # suchy przebieg (dawniej kontrola/oc/gen_dry.py): te same inject() i check(), bez zapisu
        old = PAGE.read_text(encoding='utf-8')
        new = inject(old)
        check(new)
        if new != old:
            import difflib
            for line in list(difflib.unified_diff(old.splitlines(), new.splitlines(), 'oc-beauty.html', 'wygenerowane', lineterm='', n=0))[:40]:
                print(line)
        sf_old = SCHEMA_FAQ.read_text(encoding='utf-8') if SCHEMA_FAQ.is_file() else ''
        if sf_old != schema_faq_text():
            print('RÓŻNICA: snippets/schema-faq-oc-beauty.json ≠ FAQ z faq-oc-beauty.json')
        ok = new == old and sf_old == schema_faq_text()
        print('OK' if ok else 'RÓŻNICA – uruchom bez --check')
        sys.exit(0 if ok else 1)
    src = init() if '--init' in sys.argv else PAGE.read_text(encoding='utf-8')
    src = inject(src)
    check(src)
    PAGE.write_text(src, encoding='utf-8')
    SCHEMA_FAQ.write_text(schema_faq_text(), encoding='utf-8')
    print('OK', PAGE, len(src), 'B;', SCHEMA_FAQ.name, '– FAQPage', len(FAQ), 'pytań')


if __name__ == '__main__':
    main()
