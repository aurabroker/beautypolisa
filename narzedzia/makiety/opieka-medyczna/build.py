#!/usr/bin/env python3
"""Buduje docs/koncepcja/design/v3/opieka-medyczna.html i snippets/schema-produkt-opieka-medyczna.json
z data.py (przepisane z medical.html) + template.html. Uruchom: python3 -I build.py [--check]
--check: nic nie zapisuje, kończy się kodem 1, gdy strona albo snippet różnią się od wygenerowanych."""
import html, json, re, sys, unicodedata, os

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from data import PRICES, TEAMS, SCOPES, OPS, PACKAGES, SPEC_MAP, PROCEDURES  # noqa: E402

REPO = os.path.abspath(os.path.join(HERE, '..', '..', '..'))  # katalog główny repozytorium
V3 = REPO + '/docs/koncepcja/design/v3'
OUT_HTML = V3 + '/opieka-medyczna.html'
OUT_SCHEMA = REPO + '/docs/koncepcja/snippets/schema-produkt-opieka-medyczna.json'
URL = 'https://beautypolisa.eu/ubezpieczenia/opieka-medyczna'

esc = lambda s: html.escape(s, quote=True)
zl = lambda n: f'{n}&nbsp;zł'


def norm(s):
    s = s.lower().replace('ł', 'l')
    s = unicodedata.normalize('NFD', s)
    return ''.join(c for c in s if unicodedata.category(c) != 'Mn')


ALL = [p for team in PRICES.values() for op in team.values() for p in op]
LOW, HIGH = min(ALL), max(ALL)


def rng(op, i):
    vals = [PRICES[t][op][i] for t, _ in TEAMS]
    return min(vals), max(vals)


# ---------------------------------------------------------------- ceny
# jednostka stawki: źródło podpisuje cenę Singiel „Pracownik / mc”; dla Partner i Rodzina jednostki brak (łączna? – do potwierdzenia)
SCOPE_UNIT = {'singiel': 'za pracownika', 'partner': 'za pracownika z&nbsp;partnerem', 'rodzina': 'za pracownika z&nbsp;rodziną'}
# Decyzja zleceniodawcy 13.11.2026: cennika programu jeszcze nie ma – kwoty z medical.html to wyłącznie PRZYKŁAD.
# Każda kwota w elemencie data-przyklad="tak" ze znacznikiem „przykład” (kontrola automatyczna); bez kwot w meta, JSON-LD i FAQ.
PRZYKLAD = '<span class="mock-note">przykład</span>'


def price_card(op):
    o = OPS[op]
    d = PRICES['3-10'][op]
    rows = []
    for key, label in TEAMS:
        cells = ''.join(f'<td data-scope="{s}">{zl(PRICES[key][op][i])}</td>' for i, (s, _) in enumerate(SCOPES))
        rows.append(f'<tr data-team="{key}"><th scope="row">{label}</th>{cells}</tr>')
    rows.append('<tr class="row-ind" data-team="51+"><th scope="row">od&nbsp;51</th><td colspan="3">wycena indywidualna</td></tr>')
    heads = ''.join(f'<th scope="col" data-scope="{s}">{l}</th>' for s, l in SCOPES)
    return f'''<article class="op-card rv-rise" id="cena-{op}" data-op="{op}" data-przyklad="tak" aria-labelledby="op-{op}-t">
          <div class="op-head">
            <p class="op-legal">{o['legal']}</p>
            <h3 id="op-{op}-t">{o['pkg']}</h3>
          </div>
          <p class="op-fig" data-przyklad="tak">{PRZYKLAD}<span class="op-fig-num" data-fig>{zl(d[0])}</span><span class="op-fig-cap" data-fig-cap>{SCOPE_UNIT['singiel']} miesięcznie · Singiel · zespół 3–10&nbsp;osób</span></p>
          <div class="table-scroll" data-przyklad="tak">
            <table class="rate-table">
              <caption><span class="sr-only">{o['pkg']} – </span>Przykładowe stawki miesięczne w&nbsp;zł (cennik programu w&nbsp;przygotowaniu): Singiel za pracownika, Partner i&nbsp;Rodzina za pracownika z&nbsp;bliskimi – według liczby osób w&nbsp;zespole</caption>
              <thead><tr><th scope="col">Osób w&nbsp;zespole</th>{heads}</tr></thead>
              <tbody>
                {(chr(10) + '                ').join(rows)}
              </tbody>
            </table>
          </div>
          <a class="btn btn-navy" href="#zapytanie" data-to-form data-op="{op}"><svg class="lux-icon lux-icon--sm" aria-hidden="true"><use href="#lux-doradca"/></svg>Zapytaj o&nbsp;{o['brand']}<span class="sr-only"> Standard</span></a>
        </article>'''


# ---------------------------------------------------------------- porównanie
ROWS = [  # kolejność: cena, lekarze, badania, ciąża, zabiegi; liczba specjalności (niespójna w źródle) na końcu
    ('price', 'Przykładowe stawki (cennik w&nbsp;przygotowaniu)'),
    ('list', 'Lekarze wymienieni w&nbsp;zestawieniu'),
    ('labs', 'Diagnostyka laboratoryjna'),
    ('diag', 'Diagnostyka obrazowa i&nbsp;RTG'),
    ('preg', 'Prowadzenie ciąży'),
    ('proc', 'Zabiegi ambulatoryjne'),
    ('specs', 'Liczba specjalności (wg zestawienia)'),
    ('diff', 'Różnice: lekarze z&nbsp;innych wybranych pakietów, których nie ma na liście'),
]


def diff_for(pid, selected):
    me = next(p for p in PACKAGES if p['id'] == pid)
    out = []
    for other in PACKAGES:
        if other['id'] == pid or other['id'] not in selected:
            continue
        for s in other['specs_list']:
            if s not in me['specs_list'] and s not in out:
                out.append(s)
    return out


def cell(p, key):
    if key == 'specs':
        n = len(p['specs_list'])
        return f'{esc(p["specs"])} <span class="mock-note">na liście w&nbsp;źródle: {n} nazw – do potwierdzenia</span>'
    if key == 'list':
        return esc(', '.join(p['specs_list']))
    if key == 'price':
        if not p['priced']:
            return 'brak przykładu – cenę przygotuje doradca <span class="mock-note">cennik programu w&nbsp;przygotowaniu</span>'
        op = p['op']
        parts = []
        for i, (_, l) in enumerate(SCOPES):
            a, b = rng(op, i)
            parts.append(f'{l}: {a}&#8288;–&#8288;{b}&nbsp;zł')  # bez łamania wiersza w zakresie kwot
        return (f'<span class="cmp-price" data-przyklad="tak">{PRZYKLAD} ' + '; '.join(parts)
                + ' miesięcznie (Singiel za pracownika; zespół 3&#8288;–&#8288;50&nbsp;osób)</span> – <a href="#ceny">zobacz przykładowe stawki</a>')
    if key == 'diff':
        d = diff_for(p['id'], [x['id'] for x in PACKAGES])
        return f'<span data-diff="{p["id"]}">{esc(", ".join(d)) if d else "–"}</span>'
    return esc(p[key])


def compare_table():
    head = ''.join(f'<th scope="col" data-pkg="{p["id"]}">{p["name"]}</th>' for p in PACKAGES)
    body = []
    for key, label in ROWS:
        cls = ' class="row-diff"' if key == 'diff' else ''
        tds = ''.join(f'<td data-pkg="{p["id"]}">{cell(p, key)}</td>' for p in PACKAGES)
        body.append(f'<tr{cls}><th scope="row">{label}</th>{tds}</tr>')
    return f'''<div class="cmp-table-wrap">
          <table class="cmp-table">
            <caption>Zakres pakietów według zestawienia z&nbsp;dotychczasowej strony programu</caption>
            <thead><tr><th scope="col" class="cmp-corner"><span class="sr-only">Zakres</span></th>{head}</tr></thead>
            <tbody>
              {(chr(10) + '              ').join(body)}
            </tbody>
          </table>
        </div>'''


def compare_attrs():
    """Poniżej 1024 px: układ „najpierw atrybut” – blok atrybutu, pod nim jedna linia na każdy (wybrany) pakiet."""
    blocks = []
    for key, label in ROWS:
        cls = ' row-diff' if key == 'diff' else ''
        lines = ''.join(f'<div data-pkg="{p["id"]}"><dt>{p["name"]}</dt><dd>{cell(p, key)}</dd></div>' for p in PACKAGES)
        blocks.append(f'<section class="cmp-attr{cls}" aria-labelledby="ca-{key}"><h3 id="ca-{key}">{label}</h3><dl>{lines}</dl></section>')
    return '<div class="cmp-attrs">\n          ' + '\n          '.join(blocks) + '\n        </div>'


# ---------------------------------------------------------------- specjalizacje
def parse_tokens(s):
    out = []
    for part in s.split(' / '):
        m = re.match(r'^(\S+)(?:\s*\((.+)\))?$', part.strip())
        out.append((m.group(1), m.group(2)))
    return out


LIST_NAMES = {}
for p in PACKAGES:
    for s in p['specs_list']:
        LIST_NAMES.setdefault(s.lower(), s)

DISPLAY = {'szycie rany': 'Szycie rany', 'lekarz rodzinny': 'Lekarz rodzinny', 'lekarz dyżurny': 'Lekarz dyżurny',
           'chirurg onkolog': 'Chirurg onkolog'}
def gen(name):  # dopełniacz do zdań o rozbieżnościach (lekarz → lekarza, pediatra → pediatry)
    return name[:-1] + 'y' if name.endswith('a') else name + 'a'
OUTSIDE = {'enel': {'Basic', 'Standard'}, 'lux': {'Podstawowa', 'Standardowa'}}
STATUS = {'tak': ('jest', '✓'), 'nie': ('nie wskazano', '–'), 'rozb': ('do potwierdzenia', '?'), 'nw': ('nie wymieniono', '·')}
BASIC_SCOPE = 'zakres ambulatoryjny Basic'  # comparisonData['enel-std'].proc: „Pełen zakres ambulatoryjny Basic + …”


def spec_entries():
    """Status w czterech pakietach strony (jedna reguła dla wszystkich haseł):
    lekarz z mapy: mapa i lista lekarzy pakietu zgodne → „jest” / „nie wskazano”; sprzeczne → „do potwierdzenia” z opisem;
    lekarz tylko z list: na liście → „jest”, poza listą → „nie wymieniono”;
    zabieg (listy lekarzy go nie dotyczą): mapa → „jest” / „nie wskazano”, chyba że zestawienie (wiersz „Zabiegi”) podaje dla pakietu
    pełen zakres ambulatoryjny pakietu wskazanego w mapie (ENEL-MED Standard ⊃ Basic) – wtedy „do potwierdzenia”."""
    entries = []
    mp = {k: (e, l) for k, e, l in SPEC_MAP}
    names = list(mp.keys()) + [n for n in LIST_NAMES if n not in mp]
    for name in names:
        m = mp.get(name)
        proc = name in PROCEDURES
        in_lists = name in LIST_NAMES
        pk = []
        conflicts = []
        for p in PACKAGES:
            q = None
            lstat = None if proc else name in [s.lower() for s in p['specs_list']]
            if not m:
                st = 'tak' if lstat else 'nw'
            else:
                toks = parse_tokens(m[0] if p['op'] == 'enel' else m[1])
                hit = [t for t in toks if t[0] == p['token']]
                mstat = bool(hit)
                q = hit[0][1] if hit else None
                if proc:
                    st = 'tak' if mstat else 'nie'
                    basic = [t for t in toks if t[0] == 'Basic']
                    if not mstat and basic and BASIC_SCOPE in p['proc']:
                        st = 'rozb'
                        conflicts.append(f'zestawienie pakietów podaje dla {p["name"]} „pełen zakres ambulatoryjny Basic”, '
                                         'a&nbsp;mapa specjalizacji wskazuje dla ENEL-MED tylko pakiet Basic')
                elif mstat == lstat:
                    st = 'tak' if mstat else 'nie'
                else:
                    st = 'rozb'
                    near = [x for x in p['specs_list'] if name in x.lower().split() and x.lower() != name]
                    if mstat and near:
                        conflicts.append(f'mapa specjalizacji wskazuje {p["name"]}, a&nbsp;lista lekarzy tego pakietu wymienia tylko: '
                                         + ', '.join(n.lower() for n in near))
                    elif mstat:
                        conflicts.append(f'mapa specjalizacji wskazuje {p["name"]}, ale lista lekarzy tego pakietu nie wymienia {gen(name)}')
                    else:
                        conflicts.append(f'lista lekarzy {p["name"]} wymienia {gen(name)}, a&nbsp;mapa specjalizacji nie wskazuje tego pakietu')
            pk.append({'id': p['id'], 'name': p['name'], 'st': st, 'q': q})
        outside = []
        if m:
            for op, s in (('enel', m[0]), ('lux', m[1])):
                o = [t for t, _ in parse_tokens(s) if t not in OUTSIDE[op]]
                if o:
                    outside.append(f'{OPS[op]["brand"]} {", ".join(o)}')
        disp = DISPLAY.get(name, name[:1].upper() + name[1:])
        entries.append({'key': name, 'name': disp, 'kind': 'zabieg' if proc else 'lekarz',
                        'map': m, 'inLists': in_lists, 'pk': pk, 'conflicts': conflicts, 'outside': outside})
    entries.sort(key=lambda e: norm(e['name']))
    return entries


def spec_item(e):
    chips = []
    for c in e['pk']:
        label, mark = STATUS[c['st']]
        q = f' <span class="pk-q">({esc(c["q"])})</span>' if c['q'] else ''
        chips.append(f'<li class="pk pk--{c["st"]}"><span class="pk-mark" aria-hidden="true">{mark}</span><span class="pk-name">{c["name"]}</span>{q}<span class="pk-st">: {label}</span></li>')
    src = []
    if e['map']:
        src.append(f'Mapa specjalizacji: ENEL – {esc(e["map"][0])}; LuxMed – {esc(e["map"][1])}.')
    if e['inLists'] and not e['map']:
        src.append('Tylko na listach lekarzy w&nbsp;porównaniu pakietów.')
    if e['outside']:
        src.append('Według mapy także w&nbsp;pakietach spoza tej strony: ' + '; '.join(e['outside']) + '.')
    note = ''
    if e['conflicts']:
        note = '<p class="spec-conflict"><span class="mock-note">rozbieżność w&nbsp;danych źródła – do potwierdzenia</span> ' + \
               (lambda x: x[:1].upper() + x[1:])('; '.join(e['conflicts'])) + '.</p>'
    kind = 'Zabieg' if e['kind'] == 'zabieg' else 'Lekarz'
    sid = 'spec-' + re.sub(r'[^a-z0-9]+', '-', norm(e['key'])).strip('-')
    return f'''<li class="spec-item" id="{sid}" data-q="{esc(norm(e['name']))}">
              <p class="spec-kind">{kind}</p>
              <h3>{esc(e['name'])}</h3>
              <ul class="pk-list" aria-label="Pakiety na tej stronie">{''.join(chips)}</ul>
              <p class="spec-src">{' '.join(src)}</p>
              {note}
            </li>'''


# ---------------------------------------------------------------- FAQ (tekst widoczny = JSON-LD)
FAQ = [
    ('Dla kogo jest opieka medyczna w BeautyPolisa?',
     'Dla salonów i firm z branży beauty, które chcą zapewnić zespołowi abonament medyczny ENEL-MED albo LUX MED. '
     'W zakresie Partner albo Rodzina abonament obejmuje także bliskich pracownika. '
     'Ofertę dla Twojego zespołu przygotuje doradca po zapytaniu.'),
    ('Ile kosztuje abonament medyczny?',
     'Cenę przygotuje doradca po zapytaniu; cennik programu jest w przygotowaniu.'),
    ('Czym różnią się pakiety ENEL-MED i LUX MED?',
     'Pakiety różnią się listą lekarzy specjalistów, zakresem badań laboratoryjnych i diagnostyki obrazowej, prowadzeniem ciąży '
     'oraz zabiegami ambulatoryjnymi. Zestawienie czterech pakietów – ENEL-MED Basic i Standard oraz LUX MED Podstawowa i Standard – '
     'znajdziesz w <a href="#porownanie">porównaniu pakietów</a>.'),
    ('Jak sprawdzić, czy pakiet obejmuje danego specjalistę?',
     'Wpisz nazwę specjalizacji lub zabiegu w <a href="#specjalizacje">wyszukiwarce specjalizacji</a>, np. kardiolog, dermatolog albo biopsja. '
     'Wynik pokaże, w których pakietach ENEL-MED i LUX MED ją znajdziesz. Ostateczny zakres określa oferta i dokumenty operatora.'),
    ('Jak zamówić opiekę medyczną dla zespołu?',
     'Wypełnij <a href="#zapytanie">formularz zapytania</a>: podaj NIP firmy, dane kontaktowe, wybraną sieć, liczbę osób i zakres. '
     'Doradca Aura Expert skontaktuje się z Tobą i przygotuje ofertę. Możesz też zadzwonić pod numer '
     '<a href="tel:+48504400901">+48 504 400 901</a>. Abonamentu nie kupuje się w koszyku na stronie.'),
    ('Kto zapewnia świadczenia medyczne?',
     'Pakiety dostarczają ENEL-MED S.A. oraz LUX MED sp. z o.o. Pełne warunki określają dokumenty operatora '
     '(OWU lub regulamin – do potwierdzenia). Aura Expert sp. z o.o. – agent ubezpieczeniowy – obsługuje zapytania '
     'i przygotowuje ofertę.'),
]
strip = lambda s: re.sub(r'<[^>]+>', '', s)


def faq_html():
    return '\n        '.join(f'<details id="pytanie-{i}"><summary>{q}</summary><p>{a}</p></details>'
                             for i, (q, a) in enumerate(FAQ, 1))


# ---------------------------------------------------------------- JSON-LD
def jsonld():
    nnw = open(V3 + '/nnw-dzieci.html', encoding='utf-8').read()
    m = re.search(r'<script type="application/ld\+json">\s*(\{.*?\})\s*</script>', nnw, re.S)
    graph = json.loads(m.group(1))['@graph']
    org = next(n for n in graph if n['@type'] == 'Organization' and n['@id'].endswith('#organization'))
    agency = next(n for n in graph if n['@type'] == 'InsuranceAgency')
    service = schema_service()
    title = 'Opieka medyczna ENEL-MED i LUX MED dla salonu | BeautyPolisa'
    data = {'@context': 'https://schema.org', '@graph': [
        {'@type': 'WebPage', '@id': URL + '#webpage', 'url': URL, 'inLanguage': 'pl-PL', 'name': title,
         'description': DESCRIPTION, 'breadcrumb': {'@id': URL + '#breadcrumb'}, 'mainEntity': {'@id': URL + '#service'},
         'publisher': {'@id': 'https://beautypolisa.eu/#organization'}},
        {'@type': 'BreadcrumbList', '@id': URL + '#breadcrumb', 'itemListElement': [
            {'@type': 'ListItem', 'position': 1, 'name': 'Strona główna', 'item': 'https://beautypolisa.eu/'},
            {'@type': 'ListItem', 'position': 2, 'name': 'Ubezpieczenia', 'item': 'https://beautypolisa.eu/ubezpieczenia'},
            {'@type': 'ListItem', 'position': 3, 'name': 'Opieka medyczna', 'item': URL}]},
        service, org, agency,
        {'@type': 'FAQPage', '@id': URL + '#faq', 'url': URL, 'inLanguage': 'pl-PL', 'mainEntity': [
            {'@type': 'Question', 'name': q, 'acceptedAnswer': {'@type': 'Answer', 'text': strip(a)}} for q, a in FAQ]},
    ]}
    return json.dumps(data, ensure_ascii=False, indent=1)


DESCRIPTION = ('Abonamenty medyczne ENEL-MED i LUX MED dla zespołu salonu beauty: Singiel, Partner, Rodzina. '
               'Porównaj pakiety, sprawdź specjalizacje i zapytaj doradcę o ofertę.')


def schema_service():
    return {
        '@type': 'Service', '@id': URL + '#service',
        'name': 'Opieka medyczna ENEL-MED i LUX MED dla branży beauty',
        'alternateName': 'Program abonamentów medycznych dla salonów beauty',
        'serviceType': 'Abonament medyczny (prywatna opieka medyczna) dla pracowników i ich bliskich',
        'category': 'Benefity dla firm – opieka medyczna',
        'description': ('Abonamenty medyczne ENEL-MED Standard i LUX MED Standard dla zespołów salonów beauty w zakresie Singiel, '
                        'Partner albo Rodzina. Cenę dla zespołu przygotuje doradca Aura Expert po zapytaniu; cennik programu jest w przygotowaniu.'),
        'url': URL,
        'provider': [
            {'@type': 'Organization', '@id': 'https://beautypolisa.eu/#enel-med', 'name': 'ENEL-MED S.A.'},
            {'@type': 'Organization', '@id': 'https://beautypolisa.eu/#lux-med', 'name': 'LUX MED sp. z o.o.'},
        ],
        'areaServed': {'@type': 'Country', 'name': 'Polska'},
        'audience': {'@type': 'BusinessAudience',
                     'audienceType': 'salony i firmy z branży beauty, ich pracownicy oraz partnerzy i rodziny pracowników',
                     'numberOfEmployees': {'@type': 'QuantitativeValue', 'minValue': 3}},
        'availableChannel': {'@type': 'ServiceChannel', 'name': 'Zapytanie do doradcy Aura Expert (formularz lub telefon)',
                             'serviceUrl': URL + '#zapytanie', 'availableLanguage': 'pl',
                             'servicePhone': {'@type': 'ContactPoint', 'telephone': '+48 504 400 901', 'contactType': 'doradca'}},
        'offers': {  # bez ceny: cennika programu jeszcze nie ma (decyzja 13.11.2026)
            '@type': 'Offer', 'url': URL + '#zapytanie', 'eligibleRegion': 'PL',
            'description': 'Cenę przygotuje doradca po zapytaniu; cennik programu jest w przygotowaniu.',
            'offeredBy': {'@id': 'https://beautypolisa.eu/#agency'},
        },
    }


# ---------------------------------------------------------------- dane dla skryptu
def page_data():
    return json.dumps({
        'prices': PRICES,
        'teams': {k: l for k, l in TEAMS} | {'51+': 'od 51', '1-2': 'mniej niż 3'},
        'scopeUnits': {k: v.replace('&nbsp;', '\u00a0') for k, v in SCOPE_UNIT.items()},
        'scopes': [s for s, _ in SCOPES], 'scopeLabels': {s: l for s, l in SCOPES},
        'ops': {k: {'brand': v['brand'], 'pkg': v['pkg']} for k, v in OPS.items()},
        'pkgs': {p['id']: p['specs_list'] for p in PACKAGES},
        'pkgNames': {p['id']: p['name'] for p in PACKAGES},
    }, ensure_ascii=False, separators=(',', ':'))


# ---------------------------------------------------------------- nbsp po jednoliterowych słowach (tylko tekst, poza script/style/FAQ)
def nbsp(doc):
    out, skip = [], False
    for part in re.split(r'(<[^>]+>)', doc):
        if part.startswith('<'):
            low = part.lower()
            if low.startswith(('<script', '<style', '<!--nb-off')):
                skip = True
            elif low.startswith(('</script', '</style', '<!--nb-on')):
                skip = False
            out.append(part)
        elif skip:
            out.append(part)
        else:
            out.append(re.sub(r'(^|[\s(„])([aiouwzAIOUWZ]) +(?=\S)', r'\1\2&nbsp;', part))
    return ''.join(out)


def sprite():
    src = open(V3 + '/ikony-v3-sprite.svg', encoding='utf-8').read()
    nnw = open(V3 + '/nnw-dzieci.html', encoding='utf-8').read()
    ids = ['bezpieczenstwo', 'dokumenty', 'doradca', 'kalkulator', 'serce', 'opieka-medyczna', 'grupowe-ergo',
           'oc-beauty', 'tax-protect', 'utrata-dochodu', 'nnw-dzieci', 'w-zakresie', 'szybka-wycena', 'kosmetolog']
    out = []
    for i in ids:
        m = re.search(r'<symbol id="lux-%s".*?</symbol>' % re.escape(i), nnw, re.S) or \
            re.search(r'<symbol id="lux-%s".*?</symbol>' % re.escape(i), src, re.S)
        sym = re.sub(r'\s+', ' ', m.group(0))
        out.append('  ' + sym)
    return '\n'.join(out)


def footer():
    f = open(HERE + '/footer.html', encoding='utf-8').read().rstrip()
    a = '<a href="nnw-dzieci.html" aria-current="page">NNW dzieci</a>'
    b = '<a href="/ubezpieczenia/opieka-medyczna">Opieka medyczna</a>'
    assert a in f and b in f
    f = f.replace(a, '<a href="nnw-dzieci.html">NNW dzieci</a>').replace(b, '<a href="opieka-medyczna.html" aria-current="page">Opieka medyczna</a>')
    note = ('<!-- Stopka 1:1 z nnw-dzieci.html / oc-beauty.html (pełna formuła prawna Aura Expert, L1 12.11.2026; blok „Informacje o agencie ubezpieczeniowym (IDD)” identyczny\n'
            '     jak na stronach publicznych). Jedyna różnica: aria-current na „Opieka medyczna” (w makiecie opieka-medyczna.html, produkcyjnie /ubezpieczenia/opieka-medyczna). -->\n')
    return note + f


def gen_blocks():
    """Bloki gen:* z narzedzia/makiety/gen_wspolne.py (bez zmian w tym pliku): strona opieka-medyczna.html jako „plik” produktu,
    akcja paska na telefonie – „Zapytaj doradcę” do formularza na tej stronie (#zapytanie)."""
    import importlib.util
    spec = importlib.util.spec_from_file_location('gen_wspolne', os.path.join(HERE, '..', 'gen_wspolne.py'))
    g = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(g)
    g.PRODUKTY = [dict(p, plik=PAGE) if p['id'] == 'opieka-medyczna' else p for p in g.PRODUKTY]
    H = g.HOME
    pasek = g.pasek(PAGE, H)
    a = f'<a class="pa-glowny" href="{H}?produkt=opieka-medyczna#kontakt">Zapytaj doradcę</a>'
    assert a in pasek
    pasek = pasek.replace(a, '<a class="pa-glowny" href="#zapytanie">Zapytaj doradcę<span class="sr-only"> o&nbsp;opiekę medyczną</span></a>')
    return {
        '%%GEN_MENU_PRODUKTY%%': g.menu_produkty(PAGE, H),
        '%%GEN_MENU_MOBILNE%%': g.menu_mobilne(PAGE, H),
        '%%GEN_PASEK%%': g.blok('pasek-akcji', pasek),
        '%%GEN_CSS%%': g.blok('wspolne-css', g.CSS),
        '%%GEN_JS%%': g.blok('wspolne-js', g.JS),
    }


PAGE = 'opieka-medyczna.html'


def main():
    t = open(HERE + '/template.html', encoding='utf-8').read()
    css = open(HERE + '/common.css', encoding='utf-8').read()
    css = css.split('\n', 7)[7]  # bez 7-wierszowego nagłówka komentarza NNW (razem z linią zamykającą „*/”)
    assert css.lstrip().startswith('/* ----------') and '@font-face' in css.split('\n', 3)[2], css[:200]
    rep = {
        '%%COMMON_CSS%%': css.rstrip(),
        '%%COMMON_JS%%': open(HERE + '/common.js', encoding='utf-8').read().rstrip(),
        '%%JSONLD%%': jsonld(),
        '%%DESCRIPTION%%': DESCRIPTION,
        '%%PRICE_ENEL%%': price_card('enel'),
        '%%PRICE_LUX%%': price_card('lux'),
        '%%CMP_TABLE%%': compare_table(),
        '%%CMP_ATTRS%%': compare_attrs(),
        '%%SPEC_ITEMS%%': '\n            '.join(spec_item(e) for e in spec_entries()),
        '%%SPEC_COUNT%%': str(len(spec_entries())),
        '%%FAQ%%': faq_html(),
        '%%DATA%%': page_data(),
        '%%SPRITE%%': sprite(),
        '%%FOOTER%%': footer(),
    }
    rep.update(gen_blocks())
    for k, v in rep.items():
        t = t.replace(k, v)
    left = re.findall(r'%%[A-Z_]+%%', t)
    assert not left, left
    head, body = t.split('<body>', 1)
    t = head + '<body>' + nbsp(body)
    snippet = {'@context': 'https://schema.org'}
    snippet.update(schema_service())
    sj = json.dumps(snippet, ensure_ascii=False, indent=2) + '\n'
    if '--check' in sys.argv:
        same = [open(p, encoding='utf-8').read() == s for p, s in ((OUT_HTML, t), (OUT_SCHEMA, sj))]
        print('OK' if all(same) else 'RÓŻNICA – uruchom bez --check (opieka-medyczna.html: %s, schema-produkt-opieka-medyczna.json: %s)'
              % tuple('aktualny' if x else 'nieaktualny' for x in same))
        sys.exit(0 if all(same) else 1)
    open(OUT_HTML, 'w', encoding='utf-8').write(t)
    open(OUT_SCHEMA, 'w', encoding='utf-8').write(sj)
    print('ok', len(t), 'spec entries', len(spec_entries()), 'przykład low/high', LOW, HIGH)
    for e in spec_entries():
        if e['conflicts']:
            print(' conflict:', e['key'], e['conflicts'])


if __name__ == '__main__':
    main()
