#!/usr/bin/env python3
"""Pojęcia ze słownika w treści stron v3 (BeautyPolisa) – oznaczenia + dymek z definicją.

Źródło: docs/koncepcja/snippets/slownik.json (hasła, aliasy, reguły oznaczania w $comment).
Idempotentny: najpierw usuwa swoje poprzednie oznaczenia (a.bp-termin) i bloki, potem wstawia od nowa.

Na każdej stronie z listy STRONY:
  1. usuwa stare oznaczenia <a class="bp-termin" …>…</a> (zostaje sam tekst),
  2. oznacza pierwsze wystąpienie hasła na stronie (maks. MAX_NA_STRONE) – tylko tekst w <p> i <li> wewnątrz <main>,
     poza: nagłówkami, linkami, przyciskami, etykietami i polami formularzy, tabelami, okruszkami, nazwami zabiegów,
     treścią klauzuli ochrony prawnej, adnotacjami makiety, regionami aria-live, elementami ukrytymi i blokami gen:* / GEN:*;
     reguły z $comment: najdłuższe dopasowanie wygrywa, całe wyrazy, bez rozróżniania wielkości liter, ’ = ',
     wyrażenia wykluczone blokują dopasowanie, krótkie aliasy tylko w akapitach <p>, hasła „tylko Strefa” tylko w strefa/*,
     hasła „ma tylko aliasy” bez gołego terminu (wielowyrazowy termin – tak),
     poprawki po kontroli 13.11.2026: bez oznaczeń w otwarciu strony (hero), nie w cudzysłowie „…”, gęstość (1 na zdanie, 2 na akapit
     i na listę, 4 na sekcję, odstęp ODSTEP znaków), bez hasła-produktu bieżącej strony i bez „składka”/„polisa” na stronach produktów,
     dodatkowe wyrażenia wykluczone WYKLUCZONE_GEN (składki ZUS, „przed oficjalnym roszczeniem”, OC w życiu prywatnym),
  3. oznaczenie bez JS = link do slownik.html#haslo-<id> (w strefa/ – ../slownik.html#haslo-<id>),
  4. blok <!-- gen:slownik-css --> (koniec <head>) i <!-- gen:slownik-js --> (koniec <body>): dane dymków
     (<script type="application/json" id="slownik-dymki"> – tylko użyte hasła, definicja skrócona do 2 zdań: pierwsze + wybrane
     – o produkcie strony albo zastrzeżenie rozróżniające; flaga „o” = linia o OWU) i skrypt dymka (podkreślenie i fokus w currentColor,
     ciemne konteksty – gold light; dymek przy pojęciu z max-height, w oknie < 600 px szerokości lub wysokości – panel u dołu),
  5. link „Słownik pojęć” w stopce (kolumna informacyjna) i w szufladzie menu (sekcja po linii, przed przyciskiem) – jeśli go brak.

Uruchomienie: python3 -I gen_terminy.py [--check] [--debug]
  --check  kończy się kodem 1, gdy któraś strona jest nieaktualna (nic nie zapisuje)
  --debug  wypisuje oznaczenia z kontekstem
"""
import html as htmlmod
import json
import pathlib
import re
import sys

V3 = pathlib.Path(__file__).resolve().parents[3] / 'docs/koncepcja/design/v3'
SLOWNIK = V3.parent.parent / 'snippets' / 'slownik.json'
STRONY = ['makieta-v3.html', 'oc-beauty.html', 'tax-protect.html', 'utrata-dochodu.html', 'nnw-dzieci.html',
          'grupowe-ergo.html', 'strefa/logowanie.html', 'strefa/panel.html', 'strefa/dam-prace.html']
MAX_NA_STRONE = 12
# gęstość (kontrola 13.11.2026): w akapicie / punkcie listy najwyżej 2 oznaczenia, w zdaniu 1, między oznaczeniami co najmniej
# ODSTEP znaków; otwarcie strony (hero) bez oznaczeń – spokojny pierwszy ekran
MAX_NA_AKAPIT = 2
MAX_NA_LISTE = 2        # lista <ul>/<ol> (np. „Co zyskujesz”) – nie kolumna podkreśleń
MAX_NA_SEKCJE = 4       # najbliższa <section>/<article> – rozłożenie oznaczeń na całą stronę
ODSTEP = 40
# hasło będące produktem bieżącej strony nie jest oznaczane na tej stronie
WLASNE = {
    'oc-beauty.html': {'program-ubezpieczeniowy', 'odpowiedzialnosc-cywilna'},
    'utrata-dochodu.html': {'ubezpieczenie-utraty-dochodu'},
    'nnw-dzieci.html': {'nnw'},
    'grupowe-ergo.html': {'ubezpieczenie-grupowe'},
}
# hasła oczywiste na stronach produktów (na stronie głównej i w Strefie – tak)
OCZYWISTE = {'skladka', 'polisa'}
STRONY_PRODUKTOW = {'oc-beauty.html', 'tax-protect.html', 'utrata-dochodu.html', 'nnw-dzieci.html', 'grupowe-ergo.html'}
# wyrażenia wykluczone dodatkowo w generatorze (fałszywe trafienia z kontroli 13.11.2026) – do przeniesienia do $comment
# slownik.json przez właściciela słownika: składki ZUS to nie składka ubezpieczeniowa; „roszczenie” w Tax Protect to działanie organu
WYKLUCZONE_GEN = ['podstawy składek', 'podstawa składek', 'podstawie składek', 'podstawę składek', 'składki ZUS', 'składek ZUS',
                  'składka ZUS', 'składkę ZUS', 'składkach ZUS', 'płacisz składki', 'płacić składki', 'opłacasz składki',
                  'przed oficjalnym roszczeniem',
                  'odpowiedzialności cywilnej w życiu prywatnym']   # NNW: to OC prywatne (hasło oc-w-zyciu-prywatnym), nie OC zawodowe
# klucze do wyboru zdań definicji w dymku na stronach produktów (zdania o tym produkcie mają pierwszeństwo, o innym – są pomijane)
PRODUKT_KLUCZE = {
    'oc-beauty.html': r'\bOC\b|Program OC|branży beauty|ERGO Hesti',
    'tax-protect.html': r'Tax Protect|podatk|karnoskarb',
    'utrata-dochodu.html': r'utrat\w* dochodu|Leadenhall|CEU|prywatne L4',
    'nnw-dzieci.html': r'\bNNW\b|Colonnade|dzieci',
    'grupowe-ergo.html': r'Życie w Biznesie|ER 01/25|grupow',
}
# kategorie, przy których dymek dopisuje stałą linię o OWU (pojęcia ubezpieczeniowe – nie konto w Strefie ani dystrybucja)
KAT_OWU = {'podstawy', 'strony', 'ochrona', 'oc', 'tax-protect', 'zycie-zdrowie', 'utrata-dochodu', 'szkody'}
BEZ_OWU = {'zasilek-chorobowy', 'reklamacja', 'rzecznik-finansowy', 'ubezpieczyciel'}   # ZUS, prawo, podmioty – nie warunki produktu

# ---------------------------------------------------------------- reguły z $comment (jedno źródło)
D = json.loads(SLOWNIK.read_text(encoding='utf-8'))
KOM = D['$comment']
HASLA = {h['id']: h for h in D['hasla']}


def _cytaty(s):
    return re.findall(r'„([^”]+)”', s)


m = re.search(r'Wyrażenia wykluczone[^:]*:(.*?)\.\s+Hasło', KOM, flags=re.S)
WYKLUCZONE = _cytaty(m.group(1))
m = re.search(r'Krótkie aliasy \(([^)]*)\) oznaczać tylko w akapitach', KOM)
KROTKIE = [x.strip() for x in m.group(1).split(',')]
m = re.search(r'Hasła ([a-z0-9-]+(?:, [a-z0-9-]+)*(?: i [a-z0-9-]+)?) oznaczać tylko na stronach strefa/', KOM)
TYLKO_STREFA = set(re.split(r', | i ', m.group(1)))
TYLKO_ALIASY = set(re.findall(r'Hasło „([^”]+)” ma tylko aliasy', KOM))
assert len(WYKLUCZONE) == 10, WYKLUCZONE
assert len(KROTKIE) == 18, KROTKIE
assert TYLKO_STREFA == {'drugi-skladnik', 'role-w-strefie', 'osobisty-link'}, TYLKO_STREFA
assert TYLKO_ALIASY == {'Doradca Aura Expert', 'Limit (podlimit)'}, TYLKO_ALIASY
assert all(i in HASLA for i in TYLKO_STREFA)

# ---------------------------------------------------------------- normalizacja (tekst i formy porównujemy tak samo)
USUN = {'⁠', '­', '​'}            # word joiner, miękki dywiz, zero-width space
NA_SPACJE = {' ', ' ', ' ', ' ', '\n', '\t', '\r'}
ZAMIEN = {'’': "'", '‘': "'", '‑': '-'}


def norm_znak(c):
    if c in USUN:
        return ''
    if c in NA_SPACJE:
        return ' '
    c = ZAMIEN.get(c, c)
    lo = c.lower()
    return lo if len(lo) == 1 else c


def norm(s):
    return re.sub(r' +', ' ', ''.join(norm_znak(c) for c in s)).strip()


def baza_terminu(t):
    return re.sub(r'\s*\([^)]*\)\s*$', '', t).strip()


# forma (znormalizowana) -> id hasła; krótkie formy osobno
FORMY = {}
for h in D['hasla']:
    formy = list(h.get('alias', []))
    # „ma tylko aliasy” zakazuje gołej formy („doradca”, „limit”); wielowyrazowy termin („Doradca Aura Expert”) jest dopuszczony
    if h['termin'] not in TYLKO_ALIASY or ' ' in baza_terminu(h['termin']):
        formy.insert(0, baza_terminu(h['termin']))
    for f in formy:
        n = norm(f)
        if n in FORMY and FORMY[n] != h['id']:
            raise SystemExit(f'Forma „{f}” należy do dwóch haseł: {FORMY[n]} i {h["id"]}')
        FORMY[n] = h['id']
KROTKIE_N = {norm(k) for k in KROTKIE}
assert KROTKIE_N <= set(FORMY), KROTKIE_N - set(FORMY)

GRANICA_L = r"(?<![\w@'-])(?<!\w\.)"
GRANICA_P = r"(?![\w@'-])(?!\.\w)"


def wzorzec(formy):
    alts = sorted(formy, key=lambda f: (-len(f), f))
    return re.compile(GRANICA_L + '(?:' + '|'.join(re.escape(f).replace(r'\ ', ' +') for f in alts) + ')' + GRANICA_P)


RE_FORMY = wzorzec(FORMY)
RE_WYKL = wzorzec([norm(w) for w in WYKLUCZONE + WYKLUCZONE_GEN])

# ---------------------------------------------------------------- definicja do dymku: 1–2 zdania
SKROTY = ('ang', 'np', 'm.in', 'tj', 'tzw', 'ok', 'ust', 'art', 'pkt', 'nr', 'sp', 'o.o', 'z o.o', 'S.A', 'godz', 'tys', 'mln', 'ul', 'al', 'r', 'zł', 'proc', 'poz', 'Dz.U', 'itp', 'itd', 'm.st', 'ww')


def zdania(t):
    out, start = [], 0
    for mm in re.finditer(r'[.!?](?=\s+[A-ZĄĆĘŁŃÓŚŹŻ„(])', t):
        przed = t[start:mm.start()]
        slowo = re.search(r'([\w.]+)$', przed)
        if mm.group() == '.' and slowo and slowo.group(1) in SKROTY:
            continue
        out.append(t[start:mm.end()].strip())
        start = mm.end()
    out.append(t[start:].strip())
    return [z for z in out if z]


RE_ZASTRZ = re.compile(r'nim nie jest|Nie myl|nie jest (?:brokerem|tym samym)|To nie to samo')
RE_OWU = re.compile(r'OWU|ogólne warunki|[Ww]iążąc')


def definicja_krotka(t, strona=None):
    """Dymek: pierwsze zdanie definicji + jedno zdanie wybrane z reszty (najwyżej 2 zdania).
    Pierwszeństwo: zdanie o produkcie bieżącej strony i zastrzeżenia rozróżniające („Aura Expert nim nie jest”, „Nie myl…”);
    zdanie o innym produkcie – na końcu; samo zastrzeżenie o OWU – niżej, bo dymek ma stałą linię o OWU."""
    zz = zdania(t)
    if len(zz) <= 2:
        return ' '.join(zz)
    wlasny = PRODUKT_KLUCZE.get(strona)
    inne = [k for s_, k in PRODUKT_KLUCZE.items() if s_ != strona] if strona in PRODUKT_KLUCZE else []

    def ocena(z):
        o = 0
        if wlasny and re.search(wlasny, z):
            o += 3
        elif any(re.search(k, z) for k in inne):
            o -= 3
        if RE_ZASTRZ.search(z):
            o += 4
        if RE_OWU.search(z):
            o -= 1
        return o
    reszta = zz[1:]
    best = max(range(len(reszta)), key=lambda i: (ocena(reszta[i]), -i))
    return zz[0] + ' ' + reszta[best]


# ---------------------------------------------------------------- tokenizacja HTML (z pozycjami)
TAG = re.compile(r'''<!--.*?-->|<(script|style)\b(?:[^>"']|"[^"]*"|'[^']*')*>.*?</\1\s*>|<![^>]*>|</?[a-zA-Z][\w:-]*(?:[^>"']|"[^"]*"|'[^']*')*>''', re.S | re.I)
ATR = re.compile(r'''([^\s=/>]+)(?:\s*=\s*("([^"]*)"|'([^']*)'|[^\s>]+))?''')
PUSTE = {'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link', 'meta', 'source', 'track', 'wbr'}
ZAKAZANE_TAGI = {'a', 'button', 'label', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'summary', 'table', 'nav', 'header', 'footer',
                 'form', 'fieldset', 'legend', 'select', 'option', 'textarea', 'dialog', 'code', 'pre', 'svg', 'abbr',
                 'kbd', 'output', 'caption', 'figcaption', 'dt', 'time', 'address', 'template', 'noscript'}
ZAKAZANE_KLASY = {
    'mock-note', 'mock-annot', 'mock-bar', 'sr-only', 'eyebrow', 'eyebrow-sm', 'label-caps', 'chapter-no', 'crumbs',
    'legal', 'legal-idd', 'figures',
    'product', 'offer',                       # karty z linkiem rozciągniętym na całą kartę – link w środku byłby niedostępny myszą
    'clause', 'clause-text', 'klauzula', 'klauzula-body',  # dosłowna treść klauzuli ochrony prawnej (00, D30)
    'zgroups', 'zgroup', 'zlist', 'z-name', 'zrates-box', 'zempty', 'zcount',   # nazwy zabiegów (zabiegi-oc-beauty.json)
    # listy zabiegów po Aneksie nr 5 (uwaga K3 planu): sekcje list nr 1 i 2, ankiety a–h i podologii na oc-beauty.html, numery,
    # odnośniki „także na liście nr …”, aliasy kotwic; pola zabiegów w kalkulatorze OC i w „Dam pracę” – brzmienie pozycji 1:1
    'zlisty', 'zlista', 'zlista-head', 'zlista-desc', 'z-nr', 'z-inna', 'z-alias', 'ankieta-lista', 'zab-groups', 'zab-list', 'zab-tags',
    'scope-label', 'step-where', 'card-sub', 'sidenav-title', 'mega', 'pasek-akcji',
    'partners', 'stepper', 'track',           # etykiety: pasek partnerów, nazwy kroków, oś statusu zgłoszenia
    'page-hero', 'hero',                      # otwarcie strony – bez oznaczeń (spokojny pierwszy ekran, kontrola 13.11.2026)
}
# Strefa Klienta – logowanie.html: dokumenty prawne (regulaminy, klauzula informacyjna RODO, punkty kontaktowe DSA) – dosłowna treść
ZAKAZANE_ID = {'regulamin-tresc', 'klauzula', 'regulamin-dp', 'regulamin-sp', 'punkty-kontaktowe',
               'pelna-tabela'}   # NNW: pełna tabela świadczeń z legendą (tabela taryf)


def atrybuty(tag):
    m = re.match(r'<\s*([a-zA-Z][\w:-]*)', tag)
    a = {}
    for mm in ATR.finditer(tag, m.end()):
        k = mm.group(1).lower()
        if k in ('/', '>'):
            continue
        v = mm.group(3) if mm.group(3) is not None else (mm.group(4) if mm.group(4) is not None else (mm.group(2) or ''))
        a[k] = v
    return a


def zakazany(nazwa, a):
    if nazwa in ZAKAZANE_TAGI:
        return True
    if a.get('aria-hidden') == 'true' or 'hidden' in a or 'aria-live' in a or a.get('role') in ('status', 'alert', 'log', 'dialog', 'search', 'navigation', 'listbox', 'option', 'combobox', 'menu', 'tablist', 'tab'):
        return True
    if a.get('id') in ZAKAZANE_ID:
        return True
    kl = set(a.get('class', '').split())
    return bool(kl & ZAKAZANE_KLASY)


def segmenty(s):
    """Zwraca listę (start, koniec, kontekst, ścieżka, element) tekstów kwalifikujących się do oznaczenia;
    kontekst = 'p' albo 'li', element = pozycja znacznika otwierającego najbliższego <p>/<li> (klucz akapitu)."""
    stos = []          # (nazwa, zakazany, opis, pozycja)
    gen = 0
    out = []
    pos = 0
    n_zak = 0

    def tekst(a, b):
        if a >= b or gen or n_zak:
            return
        if not any(e[0] == 'main' for e in stos):
            return
        kont = None
        for nz, _, _, ps in reversed(stos):
            if nz in ('p', 'li'):
                kont = nz
                break
        if kont:
            lista = next((e[3] for e in reversed(stos) if e[0] in ('ul', 'ol')), None)
            sekcja = next((e[3] for e in reversed(stos) if e[0] in ('section', 'article')), None)
            out.append((a, b, kont, ' > '.join(e[2] for e in stos[-4:]), ps, lista, sekcja))

    for m in TAG.finditer(s):
        tekst(pos, m.start())
        pos = m.end()
        t = m.group(0)
        if t.startswith('<!--'):
            c = t[4:-3].strip()
            if re.match(r'/gen:', c, flags=re.I):
                gen = max(0, gen - 1)
            elif re.match(r'gen:', c, flags=re.I):
                gen += 1
            continue
        if t.startswith('<!') or m.group(1):
            continue
        if t.startswith('</'):
            nazwa = t[2:].strip(' >\n').split()[0].lower()
            if any(e[0] == nazwa for e in stos):
                while stos:
                    nz, zk, _, _ = stos.pop()
                    n_zak -= zk
                    if nz == nazwa:
                        break
            continue
        nazwa = re.match(r'<([a-zA-Z][\w:-]*)', t).group(1).lower()
        if nazwa in PUSTE or t.endswith('/>'):
            continue
        a = atrybuty(t)
        if nazwa in ('p', 'li') and stos and stos[-1][0] == nazwa:      # niejawne zamknięcie
            nz, zk, _, _ = stos.pop()
            n_zak -= zk
        zk = 1 if zakazany(nazwa, a) else 0
        opis = nazwa + (('#' + a['id']) if a.get('id') else '') + ''.join('.' + k for k in a.get('class', '').split())
        stos.append((nazwa, zk, opis, m.start()))
        n_zak += zk
    tekst(pos, len(s))
    return out


ENCJA = re.compile(r'&(#\d+|#[xX][0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]*);')


def mapa(raw):
    """Znormalizowany tekst + ten sam tekst z zachowaną wielkością liter (do granic zdań) + mapa: indeks znaku -> (start, koniec) w HTML."""
    znaki, orig, poz = [], [], []
    i = 0
    while i < len(raw):
        m = ENCJA.match(raw, i)
        if m:
            c = htmlmod.unescape(m.group(0))
            j = m.end()
        else:
            c = raw[i]
            j = i + 1
        for cc in c:
            n = norm_znak(cc)
            if n:
                znaki.append(n)
                o = ' ' if cc in NA_SPACJE else ZAMIEN.get(cc, cc)
                orig.append(o if len(o) == 1 and o.lower() == n else n)
                poz.append((i, j))
        i = j
    return ''.join(znaki), ''.join(orig), poz


RE_KONIEC_ZDANIA = re.compile(r'[.!?…](?=\s+[A-ZĄĆĘŁŃÓŚŹŻ„(]|\s*$)')


def opisz_akapit(orig, stan):
    """Dla każdego znaku segmentu: numer zdania w akapicie i czy znak leży w cudzysłowie „…” (nazwy z interfejsu, cytaty).
    stan = słownik akapitu (zdanie, cyt) – przenoszony między segmentami tego samego <p>/<li>."""
    granice = set()
    for mm in RE_KONIEC_ZDANIA.finditer(orig):
        przed = re.search(r'([\w.]+)$', orig[:mm.start()])
        if mm.group() == '.' and przed and przed.group(1).lower() in {x.lower() for x in SKROTY}:
            continue
        granice.add(mm.start())
    zd, cyt = [], []
    for i, c in enumerate(orig):
        if c == '„':
            stan['cyt'] = True
        zd.append(stan['zdanie'])
        cyt.append(stan['cyt'])
        if c in '”“':
            stan['cyt'] = False
        if i in granice:
            stan['zdanie'] += 1
    return zd, cyt


# ---------------------------------------------------------------- bloki CSS i JS
CSS = r'''<style>
/* ===== Pojęcia ze słownika w treści + dymek z definicją (gen_terminy.py – nie edytuj ręcznie) ===== */
/* bez JS: zwykły link do słownika z dyskretnym kropkowanym podkreśleniem (rozróżnienie nie tylko kolorem – WCAG 1.4.1).
   Podkreślenie i obwódka fokusu idą za kolorem tekstu (currentColor) – kontrast z tłem jak tekst akapitu, także na ciemnych tłach
   bez klasy .dark (np. baner odnowienia w Strefie); w znanych ciemnych kontekstach – złoto jasne (gold light). */
a.bp-termin.bp-termin{display:inline;min-height:0;padding:0;margin:0;border:0;background:none;font:inherit;letter-spacing:inherit;text-transform:inherit;color:inherit;text-decoration-line:underline;text-decoration-style:dotted;text-decoration-thickness:1.5px;text-decoration-color:currentColor;text-underline-offset:.24em;text-decoration-skip-ink:auto;cursor:pointer;border-radius:2px}
a.bp-termin.bp-termin:hover{text-decoration-style:solid;text-decoration-color:var(--color-gold,#B8975A)}
a.bp-termin.bp-termin[aria-expanded="true"]{background:rgba(217,192,137,.3);text-decoration-style:solid}
a.bp-termin.bp-termin:focus-visible{outline:2px solid currentColor;outline-offset:2px}
:is(.dark,.banner,[class*="--dark"],[class*="--night"]) a.bp-termin.bp-termin{text-decoration-color:var(--color-gold-light,#D9C089)}
:is(.dark,.banner,[class*="--dark"],[class*="--night"]) a.bp-termin.bp-termin:hover{text-decoration-color:var(--color-gold-light,#D9C089)}
:is(.dark,.banner,[class*="--dark"],[class*="--night"]) a.bp-termin.bp-termin[aria-expanded="true"]{background:rgba(217,192,137,.18)}
:is(.dark,.banner,[class*="--dark"],[class*="--night"]) a.bp-termin.bp-termin:focus-visible{outline-color:var(--color-gold-light,#D9C089)}
/* dymek: kryjące ivory (bez backdrop-filter – nie liczy się do limitu 3 tafli), złota linia, cień */
.bp-dymek{position:absolute;top:0;left:0;z-index:85;box-sizing:border-box;width:min(380px,calc(100vw - 32px));padding:16px 20px 12px;background:var(--color-ivory,#F7F3EC);color:var(--color-ink,#1B2233);border:1px solid rgba(184,151,90,.75);border-radius:6px;box-shadow:0 0 0 1px rgba(42,59,104,.06),0 2px 4px rgba(20,28,51,.1),0 22px 44px -18px rgba(20,28,51,.6);font:400 var(--text-body,.9375rem)/1.6 var(--font-sans,system-ui,sans-serif);letter-spacing:normal;text-align:left;text-transform:none;white-space:normal}
.bp-dymek[hidden]{display:none}
.bp-dymek:focus{outline:none}
.bp-dymek:focus-visible{outline:2px solid var(--color-navy,#2A3B68);outline-offset:2px}
.bp-dymek-t{margin:0 44px 6px 0;padding-bottom:8px;border-bottom:1px solid rgba(184,151,90,.45);font:600 1.4rem/1.2 var(--font-serif,Georgia,serif);color:var(--color-navy,#2A3B68);text-wrap:balance}
.bp-dymek-d{margin:0;color:var(--color-ink,#1B2233);text-wrap:pretty}
.bp-dymek-o{margin:8px 0 0;font-size:var(--text-sm,.875rem);line-height:1.5;color:var(--color-taupe,#5F574D)}
.bp-dymek-o[hidden]{display:none}
.bp-dymek-akcje{display:flex;flex-wrap:wrap;align-items:center;gap:4px 16px;margin-top:6px}
.bp-dymek a.bp-dymek-wiecej{display:inline-flex;align-items:center;min-height:44px;padding:0;font:500 var(--text-sm,.875rem)/1.3 var(--font-sans,system-ui,sans-serif);letter-spacing:normal;text-transform:none;color:var(--color-navy,#2A3B68);text-decoration:underline;text-decoration-color:var(--color-gold,#B8975A);text-decoration-thickness:1px;text-underline-offset:5px}
.bp-dymek a.bp-dymek-wiecej:hover{text-decoration-thickness:2px}
.bp-dymek-x{position:absolute;top:6px;right:6px;display:inline-flex;align-items:center;justify-content:center;width:44px;height:44px;margin:0;padding:0;background:none;border:0;border-radius:3px;color:var(--color-navy,#2A3B68);cursor:pointer}
.bp-dymek-x:hover{background:var(--color-parchment,#EDE5D8)}
.bp-dymek-x svg{width:16px;height:16px;fill:none;stroke:currentColor;stroke-width:1.6;stroke-linecap:round}
.bp-dymek :focus-visible{outline:2px solid var(--color-navy,#2A3B68);outline-offset:2px}
/* wąskie i niskie okna (telefon, telefon poziomo, powiększenie 200%): panel u dołu okna (mieści się od 320 px), nad paskiem akcji */
@media (max-width:599px),(max-height:599px){
  .bp-dymek{position:fixed;top:auto!important;left:max(12px,env(safe-area-inset-left))!important;right:max(12px,env(safe-area-inset-right));bottom:calc(12px + env(safe-area-inset-bottom));width:auto;max-width:560px;margin-inline:auto;max-height:min(70vh,560px)!important;overflow-y:auto;overscroll-behavior:contain;padding:14px 16px 10px}
}
@media (prefers-contrast:more){.bp-dymek{border-color:var(--color-navy,#2A3B68)}a.bp-termin.bp-termin{text-decoration-color:currentColor}}
@media (forced-colors:active){.bp-dymek{border:2px solid CanvasText}a.bp-termin.bp-termin{text-decoration-color:LinkText}a.bp-termin.bp-termin[aria-expanded="true"]{background:none;outline:1px solid Highlight}}
@media print{.bp-dymek{display:none!important}a.bp-termin.bp-termin{text-decoration:none}}
</style>'''

JS = r'''<script>
/* Dymek z definicją pojęcia (gen_terminy.py – nie edytuj ręcznie).
   Bez JS oznaczenie jest linkiem do słownika. Z JS: link dostaje rolę przycisku (aria-haspopup="dialog", aria-expanded, aria-controls),
   klik / Enter / Spacja otwiera niemodalny dialog (role="dialog" + aria-labelledby/aria-describedby – w środku link i przycisk, więc nie tooltip).
   Fokus przechodzi do dialogu; Esc i „Zamknij” zamykają i oddają fokus pojęciu; Tab za ostatnim elementem i Shift+Tab przed pierwszym też wracają do pojęcia;
   klik poza dymkiem zamyka. Najechanie myszą niczego nie otwiera ani nie zamyka (WCAG 1.4.13: dymek nie znika, gdy kursor jest nad nim).
   Klik z Ctrl/Cmd/Shift lub środkowym przyciskiem – zwykły link do słownika. Okno od 600 × 600 px: dymek pod ostatnią linią pojęcia albo nad
   pierwszą (gdzie się mieści); gdy nie mieści się z żadnej strony – po stronie z większym miejscem, z max-height i przewijaniem wewnątrz
   (dymek ma tabindex=-1, więc przewija się też z klawiatury). Okno węższe lub niższe niż 600 px: panel u dołu okna. */
(function(){
  var dane=document.getElementById('slownik-dymki'); if(!dane) return;
  var D; try{D=JSON.parse(dane.textContent)}catch(e){return}
  var pojecia=[].slice.call(document.querySelectorAll('a.bp-termin[data-termin]')); if(!pojecia.length) return;
  var box=document.createElement('div');
  box.className='bp-dymek';box.id='bp-dymek';box.hidden=true;box.tabIndex=-1;
  box.setAttribute('role','dialog');box.setAttribute('aria-labelledby','bp-dymek-t');box.setAttribute('aria-describedby','bp-dymek-d');
  box.innerHTML='<p class="bp-dymek-t" id="bp-dymek-t"></p><p class="bp-dymek-d" id="bp-dymek-d"></p>'+
    '<p class="bp-dymek-o" hidden>Objaśnienie ogólne – wiążą OWU produktu i&nbsp;umowa.</p>'+
    '<div class="bp-dymek-akcje"><a class="bp-dymek-wiecej" href="#">Więcej w&nbsp;słowniku</a></div>'+
    '<button type="button" class="bp-dymek-x" aria-label="Zamknij objaśnienie"><svg viewBox="0 0 16 16" aria-hidden="true"><path d="M3 3l10 10M13 3 3 13"/></svg></button>';
  document.body.appendChild(box);
  var tytul=box.querySelector('.bp-dymek-t'), opis=box.querySelector('.bp-dymek-d'), owu=box.querySelector('.bp-dymek-o'), wiecej=box.querySelector('.bp-dymek-wiecej'), zamknij=box.querySelector('.bp-dymek-x');
  var mqWaski=window.matchMedia('(max-width:599px),(max-height:599px)'), biezace=null, GORA=88, M=12;
  pojecia.forEach(function(a){
    if(!D[a.getAttribute('data-termin')])return;
    a.setAttribute('role','button');a.setAttribute('aria-haspopup','dialog');a.setAttribute('aria-expanded','false');a.setAttribute('aria-controls','bp-dymek');
  });
  function pozycja(){
    if(!biezace||box.hidden)return;
    box.style.maxHeight='';box.style.overflowY='';
    if(mqWaski.matches){box.style.top='';box.style.left='';return}
    var rs=biezace.getClientRects(), r1=rs[0]||biezace.getBoundingClientRect(), r2=rs[rs.length-1]||r1;
    var vw=document.documentElement.clientWidth, vh=window.innerHeight, w=box.offsetWidth, h=box.offsetHeight;
    var pod=vh-M-(r2.bottom+10), nad=r1.top-10-GORA, r=r2, y;
    if(h<=pod){y=r2.bottom+10}
    else if(h<=nad){r=r1;y=r1.top-10-h}
    else if(pod>=nad){y=r2.bottom+10;box.style.maxHeight=Math.max(160,pod)+'px';box.style.overflowY='auto'}
    else{r=r1;box.style.maxHeight=Math.max(160,nad)+'px';box.style.overflowY='auto';y=r1.top-10-box.offsetHeight}
    var x=Math.min(Math.max(16,r.left),vw-w-16);
    box.style.left=Math.round(x+window.scrollX)+'px';box.style.top=Math.round(y+window.scrollY)+'px';
  }
  function otworz(a){
    var d=D[a.getAttribute('data-termin')]; if(!d)return;
    if(biezace&&biezace!==a)biezace.setAttribute('aria-expanded','false');
    biezace=a;tytul.textContent=d.t;opis.textContent=d.d;owu.hidden=!d.o;wiecej.href=d.u;box.scrollTop=0;
    box.hidden=false;a.setAttribute('aria-expanded','true');pozycja();
    try{box.focus({preventScroll:true})}catch(e){box.focus()}
  }
  function zamknijDymek(oddaj){
    if(!biezace)return;var a=biezace;biezace=null;box.hidden=true;a.setAttribute('aria-expanded','false');
    if(oddaj){try{a.focus({preventScroll:mqWaski.matches})}catch(e){a.focus()}}
  }
  document.addEventListener('click',function(e){
    var a=e.target.closest&&e.target.closest('a.bp-termin[data-termin]');
    if(a&&D[a.getAttribute('data-termin')]){
      if(e.button!==0||e.ctrlKey||e.metaKey||e.shiftKey||e.altKey)return;
      e.preventDefault();
      if(biezace===a)zamknijDymek(true);else otworz(a);
      return;
    }
    if(biezace&&!box.contains(e.target))zamknijDymek(false);
  });
  document.addEventListener('keydown',function(e){
    var a=e.target.closest&&e.target.closest('a.bp-termin[data-termin]');
    if(a&&(e.key===' '||e.key==='Spacebar')&&D[a.getAttribute('data-termin')]){e.preventDefault();if(biezace===a)zamknijDymek(true);else otworz(a);return}
    if(!biezace)return;
    if(e.key==='Escape'||e.key==='Esc'){e.preventDefault();zamknijDymek(true);return}
    if(e.key==='Tab'&&box.contains(document.activeElement)){
      var ost=document.activeElement===zamknij, pierw=document.activeElement===box||document.activeElement===wiecej;
      if((!e.shiftKey&&ost)||(e.shiftKey&&pierw)){e.preventDefault();zamknijDymek(true)}
    }
  });
  zamknij.addEventListener('click',function(){zamknijDymek(true)});
  box.addEventListener('focusout',function(e){if(biezace&&e.relatedTarget&&!box.contains(e.relatedTarget)&&e.relatedTarget!==biezace)zamknijDymek(false)});
  window.addEventListener('resize',pozycja);
  if(mqWaski.addEventListener)mqWaski.addEventListener('change',pozycja);
})();
</script>'''


def blok(nazwa, tresc):
    return f'<!-- gen:{nazwa} -->\n{tresc}\n<!-- /gen:{nazwa} -->'


def usun_blok(s, nazwa):
    return re.sub(r'\n?<!-- gen:' + re.escape(nazwa) + r' -->.*?<!-- /gen:' + re.escape(nazwa) + r' -->', '', s, flags=re.S)


OZN = re.compile(r'<a class="bp-termin" href="[^"]*" data-termin="[^"]*">(.*?)</a>', re.S)


# ---------------------------------------------------------------- linki „Słownik pojęć” (stopka, szuflada)
def linki(strona, s):
    if strona.startswith('strefa/'):
        nav = re.search(r'<nav aria-label="Stopka">.*?</nav>', s, flags=re.S)
        assert nav, strona
        if 'href="../slownik.html"' not in nav.group(0):
            kotwica = '<a href="../makieta-v3.html#kontakt">Kontakt z&nbsp;doradcą</a>'
            assert nav.group(0).count(kotwica) == 1, strona
            nowy = nav.group(0).replace(kotwica, kotwica + '<a href="../slownik.html">Słownik pojęć</a>')
            s = s[:nav.start()] + nowy + s[nav.end():]
        return s
    # stopka: kolumna informacyjna „BeautyPolisa”, po „Dokumenty i OWU”
    kol = re.search(r'<h2 class="footer-title">BeautyPolisa</h2><ul>.*?</ul>', s)
    assert kol, strona
    if 'href="slownik.html"' not in kol.group(0):
        kotwica = '<li><a href="/dokumenty">Dokumenty i&nbsp;OWU</a></li>'
        assert kol.group(0).count(kotwica) == 1, strona
        nowy = kol.group(0).replace(kotwica, kotwica + '<li><a href="slownik.html">Słownik pojęć</a></li>')
        s = s[:kol.start()] + nowy + s[kol.end():]
    # szuflada: sekcja po linii (Strefa Klienta, Dam pracę, Szukam pracy, Szkolenia) – po „Szkolenia”, przed przyciskiem
    menu = re.search(r'<nav class="menu-panel" aria-label="Menu główne">.*?</nav>', s, flags=re.S)
    assert menu, strona
    if 'href="slownik.html"' not in menu.group(0):
        mm = re.search(r'\n( *)<a href="strefa/szkolenia.html">.*?Szkolenia</a>', menu.group(0))
        assert mm, strona
        wst = (f'\n{mm.group(1)}<a href="slownik.html"><svg class="lux-icon lux-icon--sm" aria-hidden="true">'
               '<use href="#lux-dokumenty"/></svg>Słownik pojęć</a>')
        nowy = menu.group(0)[:mm.end()] + wst + menu.group(0)[mm.end():]
        s = s[:menu.start()] + nowy + s[menu.end():]
    return s


# ---------------------------------------------------------------- przetwarzanie strony
def przetworz(strona, s, debug=False):
    strefa = strona.startswith('strefa/')
    pref = '../' if strefa else ''
    s = OZN.sub(r'\1', s)
    s = usun_blok(s, 'slownik-css')
    s = usun_blok(s, 'slownik-js')
    s = linki(strona, s)

    uzyte = []          # kolejność pierwszego użycia
    zmiany = []         # (start, koniec, html)
    akapity = {}        # element <p>/<li> -> stan: zdanie, cyt, off (znaki przed segmentem), n, zdania, koniec ostatniego oznaczenia
    pomin = (WLASNE.get(strona, set()) | (OCZYWISTE if strona in STRONY_PRODUKTOW else set()))
    n_lista, n_sekcja = {}, {}
    for a, b, kont, sciezka, el, lista, sekcja in segmenty(s):
        if len(uzyte) >= MAX_NA_STRONE:
            break
        raw = s[a:b]
        txt, orig, poz = mapa(raw)
        st_ak = akapity.setdefault(el, {'zdanie': 0, 'cyt': False, 'off': 0, 'n': 0, 'zdania': set(), 'ost': None})
        zd, cyt = opisz_akapit(orig, st_ak)
        off = st_ak['off']
        st_ak['off'] += len(txt) + 1
        if not txt.strip():
            continue
        wykl = [(m.start(), m.end()) for m in RE_WYKL.finditer(txt)]
        for m in RE_FORMY.finditer(txt):
            if (len(uzyte) >= MAX_NA_STRONE or st_ak['n'] >= MAX_NA_AKAPIT or n_lista.get(lista, 0) >= MAX_NA_LISTE
                    or n_sekcja.get(sekcja, 0) >= MAX_NA_SEKCJE):
                break
            forma = re.sub(r' +', ' ', m.group(0))
            hid = FORMY[forma]
            if hid in uzyte or hid in pomin:
                continue
            if hid in TYLKO_STREFA and not strefa:
                continue
            if forma in KROTKIE_N and kont != 'p':
                continue
            if any(x < m.end() and m.start() < y for x, y in wykl):
                continue
            if cyt[m.start()]:                                   # nazwa z interfejsu / cytat w „…”
                continue
            if zd[m.start()] in st_ak['zdania']:                  # najwyżej 1 oznaczenie w zdaniu
                continue
            if st_ak['ost'] is not None and off + m.start() - st_ak['ost'] < ODSTEP:   # nie tuż obok poprzedniego
                continue
            rs, re_ = poz[m.start()][0], poz[m.end() - 1][1]
            uzyte.append(hid)
            zmiany.append((a + rs, a + re_, hid))
            st_ak['n'] += 1
            if lista is not None:
                n_lista[lista] = n_lista.get(lista, 0) + 1
            if sekcja is not None:
                n_sekcja[sekcja] = n_sekcja.get(sekcja, 0) + 1
            st_ak['zdania'].add(zd[m.start()])
            st_ak['ost'] = off + m.end()
            if debug:
                kon = re.sub(r'\s+', ' ', txt[max(0, m.start() - 50):m.end() + 30])
                print(f'  [{kont}] {hid:28s} „{m.group(0)}” … {kon}\n         {sciezka}')
    for st, kn, hid in sorted(zmiany, reverse=True):
        s = s[:st] + f'<a class="bp-termin" href="{pref}slownik.html#haslo-{hid}" data-termin="{hid}">' + s[st:kn] + '</a>' + s[kn:]

    if uzyte:
        dane = {}
        for hid in uzyte:
            h = HASLA[hid]
            dane[hid] = {'t': h['termin'], 'd': definicja_krotka(h['definicja'], strona), 'u': f'{pref}slownik.html#haslo-{hid}'}
            if h['kategoria'] in KAT_OWU and hid not in BEZ_OWU:
                dane[hid]['o'] = 1
        js = json.dumps(dane, ensure_ascii=False, indent=1).replace('</', '<\\/')
        s = s.replace('</head>', blok('slownik-css', CSS) + '\n</head>', 1)
        tresc = f'<script type="application/json" id="slownik-dymki">\n{js}\n</script>\n{JS}'
        s = s.replace('</body>', blok('slownik-js', tresc) + '\n</body>', 1)
        assert s.count('<!-- gen:slownik-css -->') == 1 and s.count('<!-- gen:slownik-js -->') == 1, strona
    return s, uzyte


def main():
    check = '--check' in sys.argv
    debug = '--debug' in sys.argv
    zle = []
    for strona in STRONY:
        p = V3 / strona
        s = p.read_text(encoding='utf-8')
        if debug:
            print(f'== {strona}')
        nowy, uzyte = przetworz(strona, s, debug)
        # idempotencja: drugie przejście na wyniku nic nie zmienia
        assert przetworz(strona, nowy)[0] == nowy, f'{strona}: drugie przejście zmienia wynik'
        print(f'{strona}: {len(uzyte)} oznaczeń – {", ".join(uzyte)}')
        if nowy != s:
            zle.append(strona)
            if not check:
                p.write_text(nowy, encoding='utf-8')
    if check and zle:
        print('NIEAKTUALNE:', ', '.join(zle))
        sys.exit(1)
    print(('Zaktualizowano: ' + ', '.join(zle)) if zle else 'Bez zmian (oznaczenia aktualne)')


if __name__ == '__main__':
    main()
