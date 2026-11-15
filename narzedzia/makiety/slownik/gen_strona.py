#!/usr/bin/env python3
"""Strona „Słownik pojęć ubezpieczeniowych” – design/v3/slownik.html (makieta /slownik).

Źródło treści: docs/koncepcja/snippets/slownik.json (hasła i kategorie z pliku) – bez ręcznych zmian w HTML.
Pole dawne_id hasła (np. „grupa-ryzyka” w haśle rodzaj-dzialalnosci, 00 D43) → pusta kotwica span.haslo-alias#haslo-<dawne_id>
na początku hasła (bez hidden – przeglądarka przewija do niej także bez JavaScriptu), żeby stare odnośniki działały.
Szkielet (nagłówek, stopka, sprite ikon, bazowy CSS i skrypt strony) kopiowany z tax-protect.html; bloki gen:* (menu „Ubezpieczenia”,
szuflada, pasek akcji, wspólne CSS/JS) wstawia narzedzia/makiety/gen_wspolne.py (funkcja przetworz – ten sam szablon co na stronach produktów).
Idempotentny: każde uruchomienie buduje stronę od nowa z tych samych źródeł (wynik zależy tylko od slownik.json, tax-protect.html i gen_wspolne.py).

Uruchomienie: python3 -I gen_strona.py [--check]   (--check: kod 1, gdy slownik.html jest nieaktualny; nic nie zapisuje)
"""
import html as htmlmod
import json
import pathlib
import re
import sys
import unicodedata

V3 = pathlib.Path(__file__).resolve().parents[3] / 'docs/koncepcja/design/v3'
SLOWNIK = V3.parent.parent / 'snippets' / 'slownik.json'
WZOR = V3 / 'tax-protect.html'
CEL = V3 / 'slownik.html'
NARZEDZIA = pathlib.Path(__file__).resolve().parents[1]  # narzedzia/makiety (gen_wspolne.py)
sys.path.insert(0, str(NARZEDZIA))
import gen_wspolne  # noqa: E402

URL = 'https://beautypolisa.eu/slownik'
TYTUL = 'Słownik pojęć ubezpieczeniowych | BeautyPolisa'
OPIS = ('Słownik pojęć ubezpieczeniowych BeautyPolisa: składka, suma gwarancyjna, OWU, karencja, prywatne L4 i inne – '
        'wyjaśnione prostym językiem. Wiążące są OWU i umowa.')
# krótsze etykiety kategorii w filtrze (pełna nazwa – w haśle, w liczniku i w data-nazwa)
KAT_KROTKO = {'strefa-klienta': 'Strefa Klienta i konto'}
ALFABET = list('ABCĆDEFGHIJKLŁMNOÓPRSŚTUWYZŹŻ')     # polski alfabet bez Ą, Ę, Ń (żaden wyraz od nich się nie zaczyna)

D = json.loads(SLOWNIK.read_text(encoding='utf-8'))
HASLA = D['hasla']
PO_ID = {h['id']: h for h in HASLA}
KAT = {k['id']: k['nazwa'] for k in D['kategorie']}
e = htmlmod.escape


def t(s):
    """Tekst do HTML: escape + polska typografia (twarde spacje po jednoliterowych spójnikach i przed „zł”)."""
    s = e(s, quote=False)
    s = re.sub(r'(?<![\w&;])([aiouwzAIOUWZ]) ', r'\1&nbsp;', s)
    s = re.sub(r'(\d) (zł|tys\.|mln|%|dni|lat|miesięcy|osób)', r'\1&nbsp;\2', s)
    s = re.sub(r'(§|art\.|nr|pkt|ust\.) (\d)', r'\1&nbsp;\2', s)
    return s


def szukaj_norm(s):
    s = s.lower().replace('’', "'").replace('ł', 'l')
    s = ''.join(c for c in unicodedata.normalize('NFD', s) if not unicodedata.combining(c))
    return re.sub(r'\s+', ' ', s).strip()


def litera(h):
    c = h['termin'][0].upper()
    assert c in ALFABET, (h['id'], c)
    return c


def slug_litery(c):
    return szukaj_norm(c).replace("'", '') + ('-pl' if szukaj_norm(c) != c.lower() else '')


def plural(n, f1, f2, f5):
    if n == 1:
        return f1
    if n % 10 in (2, 3, 4) and n % 100 not in (12, 13, 14):
        return f2
    return f5


# ---------------------------------------------------------------- źródła skrótowo (dla czytelnika strony, bez wewnętrznych ścieżek)
def zrodla(h):
    out = []
    for z in h['zrodlo']:
        o = z['opis']
        if z['typ'] == 'ergo-slowniczek':
            out.append('Słowniczek ERGO Życie w Biznesie')
        elif z['typ'] == 'przepis':
            o = o.replace('RODO – rozporządzenie (UE) 2016/679', 'RODO')
            o = re.sub(r'\s*\([^()]{7,}\)', '', o)
            o = o.split(' – ')[0].strip()
            out.append(o[0].upper() + o[1:])
        elif z['typ'] == 'koncepcja':
            out.append('ustalenia programu BeautyPolisa')
        else:
            for cz in re.split(r';\s*', o):
                cz = cz.strip()
                m = re.match(r'([a-z0-9-]+\.(?:pl|eu))\b', cz)
                if m:
                    out.append(m.group(1))
                elif cz.startswith('ulotka'):
                    out.append(cz.split(' – ')[0])
                else:
                    out.append('strony BeautyPolisa')
    wynik = []
    for x in out:
        if x not in wynik:
            wynik.append(x)
    # porządek: przepisy, ERGO, zewnętrzne, nasze
    ranga = lambda x: (3 if x == 'ustalenia programu BeautyPolisa' else 2 if x == 'strony BeautyPolisa' else 0 if x[0].isupper() else 1)
    return sorted(wynik, key=ranga)


# ---------------------------------------------------------------- hasła
def gdzie_href(strona):
    return strona          # slownik.html leży obok stron produktów; strefa/… i opieka-medyczna.html – ścieżki makiet


def haslo_html(h):
    hid = h['id']
    baza = re.sub(r'\s*\([^)]*\)\s*$', '', h['termin']).strip()
    szuk = '|'.join(dict.fromkeys(szukaj_norm(x) for x in [h['termin'], baza] + h.get('alias', [])))
    r = [f'          <article class="haslo" id="haslo-{hid}" data-kat="{h["kategoria"]}" data-szukaj="{e(szuk)}" aria-labelledby="haslo-{hid}-t">']
    for d in h.get('dawne_id', []):
        assert d not in PO_ID, f'dawne_id {d} hasła {hid} jest id istniejącego hasła'
        r.append(f'            <span class="haslo-alias" id="haslo-{e(d)}"></span>')
    r += ['            <header class="haslo-head">',
         f'              <h3 id="haslo-{hid}-t">{t(h["termin"])}</h3>',
         f'              <p class="haslo-kat">{t(KAT[h["kategoria"]])}</p>',
         '            </header>',
         f'            <p class="haslo-def">{t(h["definicja"])}</p>']
    if h.get('przyklad'):
        r.append(f'            <p class="haslo-przyklad"><span class="haslo-etyk">Na przykład</span> {t(h["przyklad"])}</p>')
    meta = []
    if h.get('zobacz_tez'):
        li = ''.join(f'<li><a href="#haslo-{z}">{t(PO_ID[z]["termin"])}</a></li>' for z in h['zobacz_tez'])
        meta.append(f'<div><dt>Zobacz też</dt><dd><ul class="haslo-linki">{li}</ul></dd></div>')
    if h.get('gdzie'):
        li = ''.join(f'<li><a href="{e(gdzie_href(g["strona"]))}">{t(g["etykieta"])}</a></li>' for g in h['gdzie'])
        meta.append(f'<div><dt>Gdzie w&nbsp;portalu</dt><dd><ul class="haslo-linki">{li}</ul></dd></div>')
    zr = zrodla(h)
    if zr:
        meta.append(f'<div class="haslo-zrodlo"><dt>Źródło</dt><dd>{"; ".join(t(x) for x in zr)}</dd></div>')
    if meta:
        r.append('            <dl class="haslo-meta">\n              ' + '\n              '.join(meta) + '\n            </dl>')
    if h.get('do_potwierdzenia'):
        r.append(f'            <p class="haslo-notka"><span class="mock-note">do potwierdzenia: {t(h["do_potwierdzenia"])}</span></p>')
    r.append('          </article>')
    return '\n'.join(r)


def lista_html():
    grupy = {}
    kolejnosc = []
    for h in HASLA:
        c = litera(h)
        if c not in grupy:
            assert not kolejnosc or ALFABET.index(c) > ALFABET.index(kolejnosc[-1]), f'hasła nie są posortowane: {h["id"]}'
            grupy[c] = []
            kolejnosc.append(c)
        grupy[c].append(h)
    sekcje = []
    for c in kolejnosc:
        sl = slug_litery(c)
        n = len(grupy[c])
        sekcje.append('\n'.join([
            f'        <section class="sl-litera" id="litera-{sl}" aria-labelledby="litera-{sl}-t">',
            f'          <h2 class="sl-litera-t" id="litera-{sl}-t"><span class="sr-only">Hasła na literę </span>{c}<span class="sl-litera-ile" aria-hidden="true">{n}</span></h2>',
            *[haslo_html(h) for h in grupy[c]],
            '          <p class="sl-wroc"><a class="link-quiet" href="#indeks">Wróć do indeksu A–Z</a></p>',
            '        </section>']))
    return grupy, '\n'.join(sekcje)


def indeks_html(grupy):
    li = []
    for c in ALFABET:
        if c in grupy:
            n = len(grupy[c])
            li.append(f'<li><a href="#litera-{slug_litery(c)}" data-litera="{slug_litery(c)}" aria-label="{c} – {n} {plural(n, "hasło", "hasła", "haseł")}">{c}</a></li>')
        else:
            li.append(f'<li aria-hidden="true"><span class="sl-az-off">{c}</span></li>')
    return ''.join(li)


def filtry_html():
    ile = {}
    for h in HASLA:
        ile[h['kategoria']] = ile.get(h['kategoria'], 0) + 1
    r = [f'<label class="sl-chip"><input type="radio" name="kategoria" value="" data-krotko="Wszystkie" checked><span><span class="sl-chip-n">Wszystkie</span> <span class="sl-ile">{len(HASLA)}</span></span></label>']
    for k in D['kategorie']:
        kr = KAT_KROTKO.get(k['id'], k['nazwa'])
        r.append(f'<label class="sl-chip"><input type="radio" name="kategoria" value="{k["id"]}" data-nazwa="{e(k["nazwa"])}" data-krotko="{e(kr)}"><span><span class="sl-chip-n">{t(kr)}</span> <span class="sl-ile">{ile.get(k["id"], 0)}</span></span></label>')
    return '\n                '.join(r)


# ---------------------------------------------------------------- JSON-LD
def jsonld(wzor_html):
    m = re.search(r'<script type="application/ld\+json">(.*?)</script>', wzor_html, flags=re.S)
    graf = json.loads(m.group(1))['@graph']
    org = [n for n in graf if n.get('@id') in ('https://beautypolisa.eu/#organization', 'https://beautypolisa.eu/#agency')]
    assert len(org) == 2
    zbior = URL + '#slownik'
    d = {'@context': 'https://schema.org', '@graph': [
        {'@type': 'WebPage', '@id': URL + '#webpage', 'url': URL, 'inLanguage': 'pl-PL', 'name': TYTUL, 'description': OPIS,
         'breadcrumb': {'@id': URL + '#breadcrumb'}, 'mainEntity': {'@id': zbior}, 'publisher': {'@id': 'https://beautypolisa.eu/#organization'}},
        {'@type': 'BreadcrumbList', '@id': URL + '#breadcrumb', 'itemListElement': [
            {'@type': 'ListItem', 'position': 1, 'name': 'Strona główna', 'item': 'https://beautypolisa.eu/'},
            {'@type': 'ListItem', 'position': 2, 'name': 'Słownik pojęć', 'item': URL}]},
        {'@type': 'DefinedTermSet', '@id': zbior, 'name': 'Słownik pojęć ubezpieczeniowych BeautyPolisa', 'url': URL, 'inLanguage': 'pl-PL',
         'description': 'Definicje wyjaśniają pojęcia prostym językiem. O zakresie ochrony decydują ogólne warunki ubezpieczenia (OWU) konkretnego produktu.',
         'publisher': {'@id': 'https://beautypolisa.eu/#organization'}, 'dateModified': D['wersja'],
         'hasDefinedTerm': [{'@type': 'DefinedTerm', '@id': f'{URL}#haslo-{h["id"]}', 'name': h['termin'], 'description': h['definicja'],
                             'url': f'{URL}#haslo-{h["id"]}', 'inDefinedTermSet': {'@id': zbior}} for h in HASLA]},
        *org]}
    return json.dumps(d, ensure_ascii=False, indent=1).replace('</', '<\\/')


# ---------------------------------------------------------------- kopie z tax-protect.html
def wytnij(s, wzor, opis):
    m = re.search(wzor, s, flags=re.S)
    assert m, f'brak w tax-protect.html: {opis}'
    return m.group(0)


def bez_oznaczen(s):
    return re.sub(r'<a class="bp-termin" href="[^"]*" data-termin="[^"]*">(.*?)</a>', r'\1', s, flags=re.S)


def naglowek(wz):
    hdr = wytnij(wz, r'<header class="site-header".*?\n</header>', 'nagłówek')
    # pozycje nawigacji strony (po menu „Ubezpieczenia”)
    hdr, n = re.subn(r'(<!-- /gen:menu-produkty -->\n).*?(\n        </ul>)',
                     r'\1          <li><a href="#indeks">Indeks A–Z</a></li>\n          <li><a href="makieta-v3.html#kalkulator">Kalkulator</a></li>\n'
                     r'          <li><a href="makieta-v3.html#faq">Pytania</a></li>\2', hdr, count=1, flags=re.S)
    assert n == 1
    hdr, n = re.subn(r'href="makieta-v3\.html\?produkt=tax-protect#kontakt"', 'href="makieta-v3.html#kontakt"', hdr)
    assert n == 2, n
    # szuflada: pozycje strony do linii, potem sekcja informacyjna z bieżącym „Słownik pojęć”
    ikon = lambda i: f'<svg class="lux-icon lux-icon--sm" aria-hidden="true"><use href="#{i}"/></svg>'
    hdr, n = re.subn(r'(<!-- /gen:menu-mobilne -->\n).*?(\n          <hr class="rule">)',
                     r'\1' + '\n'.join([
                         f'          <a href="#indeks">{ikon("lux-dokumenty")}Indeks A–Z</a>',
                         f'          <a href="makieta-v3.html#kalkulator">{ikon("lux-kalkulator")}Kalkulator OC</a>',
                         f'          <a href="makieta-v3.html#faq">{ikon("lux-doradca")}Pytania</a>']) + r'\2', hdr, count=1, flags=re.S)
    assert n == 1
    hdr = re.sub(r'\n *<a href="slownik\.html"[^>]*>.*?Słownik pojęć</a>', '', hdr)
    hdr, n = re.subn(r'(\n( *)<a href="strefa/szkolenia\.html">.*?Szkolenia</a>)',
                     lambda m: m.group(1) + f'\n{m.group(2)}<a href="slownik.html" aria-current="page">{ikon("lux-dokumenty")}Słownik pojęć</a>', hdr, count=1)
    assert n == 1
    return hdr


def stopka(wz):
    ftr = wytnij(wz, r'<footer class="scene scene--silk scene--pos-rb site-footer dark">.*?</footer>', 'stopka')
    ftr = ftr.replace(' aria-current="page"', '')
    ftr = re.sub(r'<li><a href="slownik\.html"[^>]*>Słownik pojęć</a></li>', '', ftr)
    kotw = '<li><a href="/dokumenty">Dokumenty i&nbsp;OWU</a></li>'
    assert ftr.count(kotw) == 1
    return ftr.replace(kotw, kotw + '<li><a href="slownik.html" aria-current="page">Słownik pojęć</a></li>')


def bazowy_css(wz):
    css = wytnij(wz, r'<style>\n/\* =+\n   BeautyPolisa · makieta v3 · strona produktu „Tax Protect”.*?</style>', 'bazowy CSS')
    a = css.index('/* ---------- I · zakres')
    b = css.index('/* ---------- stopka')
    css = css[:a] + css[b:]
    css = css.replace('strona produktu „Tax Protect”', 'słownik pojęć (slownik.html)').replace(
        'Tafle z backdrop-filter: belka nagłówka, otwarcie, kroki zakupu, pytania, stopka – w jednym widoku najwyżej trzy.',
        'Tafle z backdrop-filter: belka nagłówka, otwarcie, stopka – w jednym widoku najwyżej trzy; panel narzędzi i hasła są kryjące (bez rozmycia).')
    return css


def skrypt_strony(wz):
    return wytnij(wz, r'<script>\n/\* Odnośniki do pytań.*?</script>', 'skrypt strony')


CSS_SLOWNIK = r'''<style>
/* =========================================================
   Słownik pojęć – układ: narzędzia (szukaj, kategorie, indeks A–Z) + lista haseł pogrupowana literami.
   Panel narzędzi i karty liter są kryjące (bez backdrop-filter) – nie liczą się do limitu 3 tafli.
   ========================================================= */
.menu-panel a[aria-current="page"]:not(.btn){margin-inline:-10px;padding-inline:10px;background:var(--color-parchment);box-shadow:inset 2px 0 0 var(--color-gold)}
.page-hero h1,.page-hero h1 em{overflow-wrap:anywhere;hyphens:auto}   /* długie „ubezpieczeniowych” przy 320 px i odstępach z WCAG 1.4.12 */
.hero-note{max-width:40rem;font-size:var(--text-sm);line-height:1.65;color:var(--color-ink);padding-left:14px;border-left:2px solid var(--color-gold)}
.slownik{background:var(--color-parchment);border-top:1px solid rgba(217,192,137,.45);padding-block:clamp(48px,7vw,104px)}
.sl-uklad{display:grid;grid-template-columns:minmax(0,1fr);gap:clamp(24px,4vw,48px);align-items:start}
@media (min-width:1024px){.sl-uklad{grid-template-columns:minmax(0,340px) minmax(0,1fr)}}
/* narzędzia: kryjące ivory, złota linia */
.sl-narzedzia{display:grid;grid-template-columns:minmax(0,1fr);min-width:0;gap:22px;padding:clamp(20px,2.4vw,28px);border:1px solid var(--bp-line-gold);border-radius:var(--radius-card);background:var(--color-ivory);box-shadow:0 24px 48px -36px rgba(20,28,51,.45)}
/* przyklejony panel tylko na szerokim i wysokim oknie (kolumna obok listy – nic nie zasłania); niższe okna – zwykły układ.
   W zwykłym stanie (kategorie zwinięte) panel ma ok. 520 px i mieści się bez przewijania; max-height i przewijanie wewnątrz – tylko
   zabezpieczenie, gdy ktoś rozwinie kategorie (indeks A–Z stoi nad nimi, więc zostaje w widoku) */
@media (min-width:1024px) and (min-height:700px){
  .sl-narzedzia{position:sticky;top:108px;max-height:calc(100vh - 128px);overflow-y:auto;overscroll-behavior:contain}
}
.sl-szukaj{display:grid;grid-template-columns:minmax(0,1fr);gap:18px;margin:0;min-width:0}
.sl-szukaj > *,.sl-narzedzia > *{min-width:0}
.sl-szukaj label[for="sl-q"],.sl-kat-etyk,.sl-az-t{font:500 var(--text-xs)/1.4 var(--font-caps);letter-spacing:var(--tracking-label);text-transform:uppercase;color:var(--color-taupe)}
.sl-pole-wrap{display:grid;grid-template-columns:minmax(0,1fr);gap:8px}
.sl-pole{display:flex;gap:8px}
.sl-pole input{flex:1 1 auto;width:100%;min-width:0;min-height:50px;padding:10px 14px;border:1px solid var(--bp-line-field);border-radius:var(--radius-btn);background:#fff;font:400 var(--text-base)/1.4 var(--font-sans);color:var(--color-ink)}
.sl-pole input:focus-visible{outline:2px solid var(--color-navy);outline-offset:1px;border-color:var(--color-navy)}
.sl-pole input::-webkit-search-cancel-button{display:none}
.sl-pole .btn{flex:none;min-height:50px;padding-inline:16px}
.sl-pomoc{font-size:var(--text-sm);line-height:1.5;color:var(--color-taupe)}
.sl-kategorie{margin:0;padding:0;border:0;min-width:0}
/* kategorie: rozwijany panel (summary = wybrana kategoria) i lista radio w wierszach, łamana – bez przewijania w poziomie */
.sl-kat{min-width:0}
.sl-kat > summary{display:flex;align-items:center;gap:6px 12px;flex-wrap:wrap;min-height:48px;padding:8px 14px;border:1px solid var(--bp-line-field);border-radius:var(--radius-btn);background:#fff;cursor:pointer;list-style:none}
.sl-kat > summary::-webkit-details-marker{display:none}
.sl-kat > summary:hover{border-color:var(--color-navy)}
.sl-kat > summary:focus-visible{outline:2px solid var(--color-navy);outline-offset:2px}
.sl-kat-wybor{flex:1 1 auto;min-width:0;font:500 var(--text-sm)/1.3 var(--font-sans);color:var(--color-navy)}
.sl-kat-ikona{flex:none;width:16px;height:16px;fill:none;stroke:var(--color-navy);stroke-width:1.6;stroke-linecap:round;stroke-linejoin:round;transition:transform .2s ease}
.sl-kat[open] .sl-kat-ikona{transform:rotate(180deg)}
.sl-chipy{display:grid;grid-template-columns:repeat(auto-fill,minmax(min(100%,180px),1fr));gap:2px 12px;padding-top:8px}
.sl-chip{position:relative;display:flex;min-width:0}
.sl-chip input{position:absolute;inset:0;width:100%;height:100%;margin:0;opacity:0;cursor:pointer}
.sl-chip span{font:inherit}
.sl-chip > span{display:flex;align-items:center;gap:10px;width:100%;min-height:44px;padding:6px 10px;border-radius:var(--radius-btn);font:400 var(--text-sm)/1.3 var(--font-sans);color:var(--color-ink);pointer-events:none}
.sl-chip > span::before{content:"";flex:none;width:16px;height:16px;box-sizing:border-box;border:1.5px solid var(--color-navy);border-radius:50%;background:#fff}
.sl-chip-n{flex:1 1 auto;min-width:0}
.sl-chip .sl-ile{flex:none;color:var(--color-taupe);font-variant-numeric:lining-nums tabular-nums}
.sl-chip input:hover + span{background:rgba(237,229,216,.7)}
.sl-chip input:checked + span{background:var(--color-parchment);color:var(--color-navy);font-weight:500}
.sl-chip input:checked + span::before{background:var(--color-navy);box-shadow:inset 0 0 0 3px #fff}
.sl-chip input:focus-visible + span{outline:2px solid var(--color-navy);outline-offset:0}
.sl-licznik{font-size:var(--text-sm);color:var(--color-ink);padding-top:12px;border-top:1px solid var(--bp-line-gold-soft)}
.sl-licznik strong{font-weight:500}
/* indeks A–Z */
.sl-az{display:grid;gap:10px}
.sl-az ul{display:grid;grid-template-columns:repeat(auto-fill,minmax(30px,1fr));gap:4px;margin:0;padding:0;list-style:none}
.sl-az a,.sl-az-off{display:flex;align-items:center;justify-content:center;min-height:40px;border-radius:var(--radius-btn);font:600 1.3rem/1 var(--font-serif);font-variant-numeric:lining-nums}
.sl-az a{color:var(--color-navy);text-decoration:none;border:1px solid var(--bp-line-gold-soft);background:rgba(255,255,255,.55)}
.sl-az a:hover{border-color:var(--color-navy);text-decoration:underline;text-decoration-color:var(--color-gold);text-underline-offset:4px;text-decoration-thickness:1px}
.sl-az a:not([href]){color:rgba(95,87,77,.5);border-color:transparent;background:none;cursor:default;text-decoration:none}
.sl-az-off{color:rgba(95,87,77,.5)}
/* lista: litera = jedna kryjąca karta, hasła oddzielone liniami włoskowymi */
.sl-lista{display:grid;gap:clamp(20px,3vw,32px);min-width:0}
.sl-litera{position:relative;min-width:0;padding:clamp(20px,3vw,36px);border:1px solid var(--bp-line-gold-soft);border-radius:var(--radius-card);background:var(--color-ivory);box-shadow:0 24px 48px -40px rgba(20,28,51,.45)}
.sl-litera-t{display:flex;align-items:baseline;gap:14px;padding-bottom:10px;margin-bottom:6px;border-bottom:1px solid var(--color-gold);font-size:clamp(2.6rem,2rem + 2vw,3.6rem);line-height:1}
.sl-litera-ile{font:500 var(--text-xs)/1 var(--font-caps);letter-spacing:var(--tracking-label);color:var(--color-taupe)}
.haslo{display:grid;gap:12px;min-width:0;padding-block:22px;border-bottom:1px solid var(--bp-line-gold-soft);overflow-wrap:anywhere}
.haslo:last-of-type{border-bottom:0}
.haslo:target{margin-inline:calc(-1 * clamp(10px,1.6vw,18px));padding-inline:clamp(10px,1.6vw,18px);box-shadow:inset 3px 0 0 var(--color-navy);background:rgba(237,229,216,.45)}
.haslo-head{display:flex;flex-wrap:wrap;align-items:baseline;justify-content:space-between;gap:4px 16px}
.haslo h3{font-size:clamp(1.5rem,1.3rem + .6vw,1.85rem);line-height:1.15}
.haslo-kat{font:500 var(--text-xs)/1.5 var(--font-caps);letter-spacing:.14em;text-transform:uppercase;color:var(--color-taupe)}
.haslo-def{font-size:var(--text-base);line-height:1.7;color:var(--color-ink);max-width:46rem}
.haslo-przyklad{max-width:46rem;padding:12px 16px;border-left:2px solid var(--color-gold);background:rgba(237,229,216,.55);font-size:var(--text-body);line-height:1.65;color:var(--color-ink)}
.haslo-etyk{display:block;margin-bottom:2px;font:500 var(--text-xs)/1.5 var(--font-caps);letter-spacing:var(--tracking-label);text-transform:uppercase;color:var(--color-navy)}
.haslo-meta{display:grid;gap:10px;margin:0;font-size:var(--text-sm);line-height:1.5}
.haslo-meta > div{display:grid;gap:2px}
@media (min-width:640px){.haslo-meta > div{grid-template-columns:9.5rem minmax(0,1fr);column-gap:16px}}
.haslo-meta dt{padding-top:6px;font:500 var(--text-xs)/1.5 var(--font-caps);letter-spacing:.14em;text-transform:uppercase;color:var(--color-taupe)}
.haslo-meta dd{margin:0;min-width:0;color:var(--color-ink)}
.haslo-zrodlo dd{padding-top:4px;color:var(--color-taupe)}
.haslo-linki{display:flex;flex-wrap:wrap;gap:0 18px;margin:0;padding:0;list-style:none}
.haslo-linki a{display:inline-flex;align-items:center;min-height:32px;color:var(--color-navy);text-decoration:underline;text-decoration-color:var(--color-gold);text-decoration-thickness:1px;text-underline-offset:4px}
.haslo-linki a:hover{text-decoration-thickness:2px}
.haslo-notka .mock-note{display:block;margin-left:0;padding:6px 10px;white-space:normal}
.haslo-akcje{display:flex}
.haslo-kopiuj{display:inline-flex;align-items:center;gap:8px;min-height:44px;padding:0 2px;background:none;border:0;font:500 var(--text-xs)/1.2 var(--font-caps);letter-spacing:var(--tracking-nav);text-transform:uppercase;color:var(--color-navy);cursor:pointer}
.haslo-kopiuj svg{width:16px;height:16px;fill:none;stroke:currentColor;stroke-width:1.6;stroke-linecap:round;stroke-linejoin:round}
.haslo-kopiuj:hover span:not(.sr-only){text-decoration:underline;text-decoration-color:var(--color-gold);text-underline-offset:5px}
.sl-wroc{padding-top:6px}
.sl-pusto{display:grid;gap:12px;padding:clamp(22px,3vw,36px);border:1px dashed var(--bp-line-gold);border-radius:var(--radius-card);background:var(--color-ivory)}
.sl-pusto-t{font:600 var(--text-serif-md)/1.25 var(--font-serif);color:var(--color-navy)}
.sl-pusto p{max-width:42rem}
.sl-pusto-akcje{display:flex;flex-wrap:wrap;align-items:center;gap:8px 24px}
.sl-stopka-uwaga{font-size:var(--text-sm);color:var(--color-ink);max-width:46rem;padding:16px 18px;border-left:2px solid var(--color-gold);background:var(--color-ivory)}
/* epilog */
.sl-end{padding-block:0 clamp(56px,8vw,104px);background:var(--color-parchment)}
.end-card{position:relative;display:grid;gap:22px;padding:clamp(28px,4.5vw,60px);border-radius:var(--radius-card);background:linear-gradient(160deg,var(--color-navy) 0%,var(--color-midnight) 100%);color:var(--color-parchment);box-shadow:0 30px 60px -34px rgba(20,28,51,.75)}
.end-card::before{content:"";position:absolute;inset:var(--bp-frame-inset);border:1px solid rgba(217,192,137,.45);border-radius:var(--radius-btn);pointer-events:none}
.end-card h2{font-size:clamp(2.1rem,1.5rem + 2vw,3.3rem);max-width:40rem}
.end-card p:not(.eyebrow){font-size:var(--text-body);color:var(--color-parchment);max-width:44rem}
.end-actions{display:flex;flex-wrap:wrap;align-items:center;gap:14px}
@media (max-width:479px){.end-actions .btn,.hero-actions .btn{width:100%}.sl-pole .btn{padding-inline:12px}}
/* telefon i tablet (panel nad listą): przy aktywnej frazie lub kategorii indeks A–Z się chowa – wyniki stoją tuż pod licznikiem */
@media (max-width:1023px){.slownik[data-filtr] .sl-az,.slownik[data-filtr] .sl-wroc{display:none}}
@media (prefers-reduced-motion:reduce){.sl-kat-ikona{transition:none}}
@media (forced-colors:active){.sl-narzedzia,.sl-litera,.end-card{border:1px solid CanvasText}.end-card::before{display:none}.sl-chip > span::before{forced-color-adjust:none;border-color:CanvasText;background:Canvas}.sl-chip input:checked + span::before{background:Highlight;box-shadow:inset 0 0 0 3px Canvas}.haslo:target{outline:2px solid Highlight}}
@media print{.sl-narzedzia,.sl-wroc,.haslo-akcje,.end-card{display:none!important}.sl-uklad{display:block}.haslo{break-inside:avoid}}
</style>'''

JS_SLOWNIK = r'''<script>
/* Słownik: wyszukiwarka (termin i aliasy, bez względu na wielkość liter i polskie znaki), filtr kategorii (radio w rozwijanym panelu),
   licznik w aria-live, stan pusty, indeks A–Z (litery bez widocznych haseł nieaktywne, liczby przy literach liczone po filtrze),
   „Kopiuj link”. Bez JS: pełna lista + indeks (kotwice).
   Kolejność wyników przy wpisanej frazie: najpierw dokładne trafienie terminu lub odmiany, potem początek terminu, potem początek
   wyrazu, na końcu fragment w środku wyrazu (ten tylko dla fraz dłuższych niż 3 znaki – „OC” nie znajduje „ochrona”, a „NW” – „inwalidztwo”).
   Litery i hasła są wtedy przestawiane w DOM (kolejność czytania = kolejność na ekranie); po wyczyszczeniu frazy wraca kolejność alfabetyczna. */
(function(){
  var form=document.getElementById('sl-szukaj'), q=document.getElementById('sl-q'), wyczysc=document.getElementById('sl-wyczysc');
  var licznik=document.getElementById('sl-licznik'), pusto=document.getElementById('sl-pusto'), pustoQ=document.getElementById('sl-pusto-q');
  var kat=document.getElementById('sl-kat'), katWybor=document.getElementById('sl-kat-wybor'), sekcja=document.getElementById('hasla');
  var lista=document.querySelector('.sl-lista'), uwaga=document.querySelector('.sl-stopka-uwaga'), indeks=document.getElementById('indeks');
  var hasla=[].slice.call(document.querySelectorAll('.haslo')), litery=[].slice.call(document.querySelectorAll('.sl-litera'));
  if(!form||!q||!hasla.length||!kat) return;
  form.hidden=false;kat.hidden=false;
  function norm(s){return (s||'').toLowerCase().replace(/[’‘]/g,"'").replace(/ł/g,'l').normalize('NFD').replace(/[̀-ͯ]/g,'').replace(/\s+/g,' ').trim()}
  function esc(s){return s.replace(/[.*+?^${}()|[\]\\]/g,'\\$&')}
  function plural(n,a,b,c){if(n===1)return a;var d=n%10,s=n%100;return (d>=2&&d<=4&&(s<12||s>14))?b:c}
  var dane=hasla.map(function(h,i){return {el:h,i:i,kat:h.getAttribute('data-kat'),txt:h.getAttribute('data-szukaj').split('|')}});
  litery.forEach(function(l,i){l._i=i;l._ile=l.querySelector('.sl-litera-ile');l._wroc=l.querySelector('.sl-wroc')});
  var tLive=0, porzadek=false;
  function radio(){return document.querySelector('input[name="kategoria"]:checked')}
  /* ranga trafienia: 0 dokładne, 1 początek terminu/odmiany, 2 początek wyrazu, 3 fragment; Infinity – brak */
  function ranga(d,fraza,reWyraz){
    var best=Infinity;
    d.txt.forEach(function(x){
      var r=x===fraza?0:x.indexOf(fraza)===0?1:reWyraz.test(x)?2:(fraza.length>3&&x.indexOf(fraza)!==-1)?3:Infinity;
      if(r<best)best=r;
    });
    return best;
  }
  function ustawKolejnosc(wg){
    /* wg: true – według rangi; false – alfabetycznie (kolejność z pliku) */
    if(!wg&&!porzadek)return;
    litery.forEach(function(l){
      var hs=dane.filter(function(d){return d.el.parentNode===l});
      hs.sort(function(a,b){return wg?(a.r-b.r)||(a.i-b.i):a.i-b.i});
      hs.forEach(function(d){l.insertBefore(d.el,l._wroc)});
      l._r=hs.reduce(function(m,d){return Math.min(m,d.el.hidden?Infinity:d.r)},Infinity);
    });
    litery.slice().sort(function(a,b){return wg?((a._r-b._r)||(a._i-b._i)):a._i-b._i}).forEach(function(l){lista.insertBefore(l,uwaga)});
    porzadek=wg;
  }
  function filtruj(ogloszenie){
    var fraza=norm(q.value), kr=radio(), kv=kr&&kr.value, widoczne=0;
    var reWyraz=new RegExp('(^|[^a-z0-9])'+esc(fraza));
    dane.forEach(function(d){
      d.r=fraza?ranga(d,fraza,reWyraz):0;
      var ok=(!kv||d.kat===kv)&&d.r<Infinity;
      d.el.hidden=!ok;if(ok)widoczne++;
    });
    ustawKolejnosc(!!fraza);
    litery.forEach(function(l){
      var n=l.querySelectorAll('.haslo:not([hidden])').length;l.hidden=!n;
      if(l._ile)l._ile.textContent=n;
      var a=document.querySelector('.sl-az a[data-litera="'+l.id.replace('litera-','')+'"]');
      if(a){
        var c=a.textContent;
        a.setAttribute('aria-label',n?c+' – '+n+' '+plural(n,'hasło','hasła','haseł'):c+' – brak haseł w wynikach');
        if(n){a.setAttribute('href','#'+l.id);a.removeAttribute('aria-disabled')}else{a.removeAttribute('href');a.setAttribute('aria-disabled','true')}
      }
    });
    if(fraza||kv)sekcja.setAttribute('data-filtr','');else sekcja.removeAttribute('data-filtr');
    if(katWybor&&kr)katWybor.textContent=kr.getAttribute('data-krotko')||'Wszystkie';
    wyczysc.hidden=!q.value;
    pusto.hidden=widoczne>0;
    if(!widoczne)pustoQ.textContent=q.value.trim();
    var wKat=kv?' w kategorii „'+kr.getAttribute('data-nazwa')+'”':'';
    var txt=(!fraza&&!kv)?'Wszystkie hasła: '+widoczne:(widoczne?'Znaleziono '+widoczne+' '+plural(widoczne,'hasło','hasła','haseł')+wKat:'Brak haseł'+(fraza?' dla „'+q.value.trim()+'”':'')+wKat);
    clearTimeout(tLive);
    if(ogloszenie===false){licznik.textContent=txt;return}
    tLive=setTimeout(function(){licznik.textContent=txt},350);
  }
  function reset(){q.value='';var w=document.querySelector('input[name="kategoria"][value=""]');if(w)w.checked=true;filtruj()}
  q.addEventListener('input',function(){filtruj()});
  kat.addEventListener('change',function(e){if(e.target.name==='kategoria')filtruj()});
  form.addEventListener('submit',function(e){e.preventDefault();filtruj()});
  form.addEventListener('reset',function(){setTimeout(function(){filtruj();q.focus()},0)});
  q.addEventListener('keydown',function(e){if(e.key==='Escape'&&q.value){e.preventDefault();q.value='';filtruj()}});
  document.getElementById('sl-pusto-reset').addEventListener('click',function(){reset();q.focus()});
  /* odnośnik do ukrytego hasła (kotwica, „Zobacz też”, adres z #haslo-…) albo do schowanego indeksu: czyści filtry przed przewinięciem */
  function pokaz(id){var el=id&&document.getElementById(id);if(el&&el.classList.contains('haslo-alias'))el=el.closest('.haslo');if(el&&(el.hidden||(el.closest('.sl-litera')||{}).hidden||(el===indeks&&!el.getClientRects().length)))reset()}
  document.addEventListener('click',function(e){var a=e.target.closest&&e.target.closest('a[href^="#haslo-"],a[href^="#litera-"],a[href="#indeks"]');if(a)pokaz(a.getAttribute('href').slice(1))},true);
  /* wejście z #haslo-…: przewinięcie po zbudowaniu strony (przyciski kopiowania zmieniają wysokość) – bez animacji */
  function zHash(e){try{var id=decodeURIComponent(location.hash.slice(1)), el;if(!id)return;el=document.getElementById(id);if(el&&el.classList.contains('haslo-alias'))el=el.closest('.haslo');var ukryte=el&&(el.hidden||(el.closest('.sl-litera')||{}).hidden);pokaz(id);
    if(el&&(!e||ukryte))requestAnimationFrame(function(){el.scrollIntoView({block:'start',behavior:'instant'})})}catch(err){}}
  window.addEventListener('hashchange',zHash);
  filtruj(false);
  /* „Kopiuj link” – adres strony z kotwicą hasła; potwierdzenie w przycisku i w regionie statusu */
  var status=document.getElementById('sl-kopia-status');
  function kopiuj(tekst){
    if(navigator.clipboard&&window.isSecureContext)return navigator.clipboard.writeText(tekst);
    return new Promise(function(ok,blad){var ta=document.createElement('textarea');ta.value=tekst;ta.setAttribute('readonly','');ta.className='sr-only';document.body.appendChild(ta);ta.select();
      try{document.execCommand('copy')?ok():blad()}catch(err){blad(err)}document.body.removeChild(ta)});
  }
  hasla.forEach(function(h){
    var nazwa=h.querySelector('h3').textContent, box=document.createElement('div');
    box.className='haslo-akcje';
    box.innerHTML='<button type="button" class="haslo-kopiuj"><svg viewBox="0 0 16 16" aria-hidden="true"><path d="M6.5 9.5l3-3M7 4.5l1.3-1.3a2.6 2.6 0 0 1 3.7 3.7L10.7 8.2M9 11.5l-1.3 1.3a2.6 2.6 0 0 1-3.7-3.7L5.3 7.8"/></svg><span class="haslo-kopiuj-t">Kopiuj link</span><span class="sr-only"> do hasła '+nazwa.replace(/[<&]/g,'')+'</span></button>';
    h.appendChild(box);
    var b=box.querySelector('button'), bt=box.querySelector('.haslo-kopiuj-t'), tm=0;
    b.addEventListener('click',function(){
      var url=location.href.split('#')[0]+'#'+h.id;
      kopiuj(url).then(function(){bt.textContent='Skopiowano';status.textContent='Skopiowano link do hasła '+nazwa+'.'},function(){bt.textContent='Nie udało się skopiować';status.textContent='Nie udało się skopiować linku. Adres hasła: '+url})
        .then(function(){clearTimeout(tm);tm=setTimeout(function(){bt.textContent='Kopiuj link'},2500)});
    });
  });
  zHash();
  window.addEventListener('load',function(){if(/^#haslo-/.test(location.hash))zHash()});
})();
</script>'''


def strona():
    wz = bez_oznaczen(WZOR.read_text(encoding='utf-8'))
    grupy, lista = lista_html()
    n = len(HASLA)
    data = '.'.join(reversed(D['wersja'].split('-')))
    sprite = wytnij(wz, r'<svg class="sprite" xmlns="http://www.w3.org/2000/svg"[^>]*>\n  <!-- [^\n]*\n.*?\n</svg>', 'sprite')
    pasek = wytnij(wz, r'<!-- gen:pasek-akcji -->.*?<!-- /gen:pasek-akcji -->', 'pasek akcji')
    css_w = wytnij(wz, r'<!-- gen:wspolne-css -->.*?<!-- /gen:wspolne-css -->', 'wspolne-css')
    js_w = wytnij(wz, r'<!-- gen:wspolne-js -->.*?<!-- /gen:wspolne-js -->', 'wspolne-js')
    noscript = wytnij(wz, r'<noscript><style>.*?</style></noscript>', 'noscript')
    fonty = wytnij(wz, r'<link rel="preconnect" href="https://fonts.googleapis.com">.*?rel="stylesheet">', 'fonty')
    kat_n = len(D['kategorie'])
    s = f'''<!doctype html>
<html lang="pl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>{TYTUL}</title>
<meta name="description" content="{e(OPIS)}">
<link rel="canonical" href="{URL}">
<meta property="og:type" content="website">
<meta property="og:locale" content="pl_PL">
<meta property="og:site_name" content="BeautyPolisa">
<meta property="og:url" content="{URL}">
<meta property="og:title" content="{TYTUL}">
<meta property="og:description" content="{e(OPIS)}">
<meta name="theme-color" content="#141C33">
<meta name="color-scheme" content="only light">
<!-- Makieta strony /slownik – WYGENEROWANA (narzedzia/makiety/slownik/gen_strona.py z snippets/slownik.json; nie edytować ręcznie).
     Nagłówek, stopka, bazowy CSS i skrypt – kopia z tax-protect.html; bloki gen:* – narzedzia/makiety/gen_wspolne.py.
     Pole do_potwierdzenia pokazane jako adnotacja makiety (.mock-note) – w produkcji nie publikujemy go (snippets/slownik.json, $comment).
     Oznaczenia pojęć na innych stronach (dymki) – narzedzia/makiety/slownik/gen_terminy.py. -->
{fonty}
{bazowy_css(wz)}
{CSS_SLOWNIK}
{noscript}
<!-- JSON-LD: WebPage, BreadcrumbList, DefinedTermSet z {n} DefinedTerm (name, description = pełna definicja, url = /slownik#haslo-<id>, inDefinedTermSet),
     Organization i InsuranceAgency (kopie węzłów z tax-protect.html – cel odwołań publisher). -->
<script type="application/ld+json">
{jsonld(wz)}
</script>
{css_w}
</head>
<body>
<a class="skip" href="#tresc">Przejdź do treści</a>

<!-- Nagłówek 1:1 z podstron produktów (tax-protect.html); bieżąca pozycja: „Słownik pojęć” w szufladzie i w stopce (aria-current). -->
{naglowek(wz)}

<main id="tresc">

  <!-- PROLOG: wstęp – objaśnienia, wiążące są OWU i umowa ($comment slownik.json) -->
  <section class="scene scene--marble scene--pos-ct page-hero" aria-labelledby="hero-title">
    <div class="container">
      <div class="hero-panel glass frame">
        <nav class="crumbs" aria-label="Okruszki">
          <!-- produkcyjnie: / › /slownik (BreadcrumbList w JSON-LD) -->
          <ol>
            <li><a href="makieta-v3.html">Strona główna</a></li>
            <li><span aria-current="page">Słownik pojęć</span></li>
          </ol>
        </nav>
        <p class="eyebrow">Słownik BeautyPolisa</p>
        <h1 id="hero-title">Słownik <em>pojęć ubezpieczeniowych</em></h1>
        <p class="lead">Pojęcia, które spotkasz na stronach BeautyPolisa, w&nbsp;dokumentach ubezpieczenia i&nbsp;w&nbsp;Strefie Klienta – wyjaśnione prostym językiem, przy części haseł z&nbsp;przykładem.</p>
        <p class="hero-note">Definicje wyjaśniają pojęcia prostym językiem. O&nbsp;zakresie ochrony decydują ogólne warunki ubezpieczenia (OWU) konkretnego produktu i&nbsp;umowa (polisa) – to objaśnienia, a&nbsp;nie warunki ubezpieczenia.</p>
        <div class="hero-actions">
          <a class="btn btn-navy" href="#indeks">Przejdź do indeksu A–Z</a>
          <a class="btn btn-ghost" href="makieta-v3.html#kontakt">Zapytaj doradcę</a>
        </div>
        <dl class="figures">
          <div><dt>Haseł w&nbsp;słowniku</dt><dd>{n}</dd></div>
          <div><dt>Kategorii</dt><dd>{kat_n}</dd></div>
          <div><dt>Stan na</dt><dd>{data}</dd></div>
        </dl>
      </div>
    </div>
  </section>

  <!-- HASŁA: narzędzia (szukaj + kategorie – tylko z JS; indeks A–Z – zawsze) i lista {n} haseł w kolejności z pliku (polska kolejność liter) -->
  <section class="slownik" id="hasla" aria-label="Hasła słownika">
    <div class="container sl-uklad">
      <div class="sl-narzedzia">
        <form class="sl-szukaj" id="sl-szukaj" role="search" aria-label="Szukaj w słowniku" hidden>
          <div class="sl-pole-wrap">
            <label for="sl-q">Szukaj pojęcia</label>
            <div class="sl-pole">
              <input type="search" id="sl-q" name="q" autocomplete="off" spellcheck="false" enterkeyhint="search" placeholder="np. składka, L4, OWU" aria-describedby="sl-q-pomoc sl-licznik">
              <button class="btn btn-ghost" type="reset" id="sl-wyczysc" hidden>Wyczyść</button>
            </div>
            <p class="sl-pomoc" id="sl-q-pomoc">Szukamy w&nbsp;nazwach pojęć i&nbsp;ich odmianach – możesz pisać bez polskich znaków.</p>
          </div>
          <p class="sl-licznik" id="sl-licznik" aria-live="polite" aria-atomic="true">Wszystkie hasła: {n}</p>
        </form>
        <nav class="sl-az" id="indeks" aria-labelledby="indeks-t">
          <p class="sl-az-t" id="indeks-t">Indeks A–Z</p>
          <ul>{indeks_html(grupy)}</ul>
        </nav>
        <!-- kategorie: grupa radio (jeden wybór) w rozwijanym panelu – pod indeksem, żeby indeks był zawsze w pierwszym widoku panelu;
             wiersze łamią się (bez przewijania w poziomie) -->
        <details class="sl-kat" id="sl-kat" hidden>
          <summary><span class="sl-kat-etyk">Kategoria</span><span class="sl-kat-wybor" id="sl-kat-wybor">Wszystkie</span><svg class="sl-kat-ikona" viewBox="0 0 16 16" aria-hidden="true"><path d="M4 6l4 4 4-4"/></svg></summary>
          <fieldset class="sl-kategorie">
            <legend class="sr-only">Kategoria</legend>
            <div class="sl-chipy">
                {filtry_html()}
            </div>
          </fieldset>
        </details>
      </div>
      <div class="sl-lista">
        <div class="sl-pusto" id="sl-pusto" hidden>
          <p class="sl-pusto-t">Brak haseł dla „<span id="sl-pusto-q"></span>”</p>
          <p>Sprawdź pisownię albo wpisz krótszy fragment słowa – np. „skład” zamiast „składkami”. Szukamy w&nbsp;nazwach pojęć i&nbsp;ich odmianach; jeśli wybrana jest kategoria, wybierz „Wszystkie”.</p>
          <div class="sl-pusto-akcje"><button class="btn btn-ghost" type="button" id="sl-pusto-reset">Pokaż wszystkie hasła</button><a class="link-quiet" href="makieta-v3.html#kontakt">Nie ma pojęcia? Zapytaj doradcę</a></div>
        </div>
{lista}
        <p class="sl-stopka-uwaga">Definicje wyjaśniają pojęcia prostym językiem. O&nbsp;zakresie ochrony decydują ogólne warunki ubezpieczenia (OWU) konkretnego produktu.</p>
      </div>
    </div>
    <p class="sr-only" id="sl-kopia-status" role="status"></p>
  </section>

  <!-- EPILOG -->
  <section class="sl-end" aria-labelledby="end-title">
    <div class="container">
      <div class="end-card">
        <p class="eyebrow">Masz pytanie o&nbsp;swoją polisę?</p>
        <h2 id="end-title">Nie ma pojęcia, którego szukasz? <em>Zapytaj doradcę</em></h2>
        <p>Doradca Aura Expert wyjaśni zapisy OWU i&nbsp;polisy dla Twojego salonu. Słownik objaśnia pojęcia ogólnie – o&nbsp;zakresie ochrony decydują warunki konkretnego produktu.</p>
        <div class="end-actions">
          <a class="btn btn-ivory" href="makieta-v3.html#kontakt">Zapytaj doradcę</a>
          <a class="btn btn-ghost-dark" href="makieta-v3.html#ubezpieczenia">Zobacz ubezpieczenia</a>
        </div>
      </div>
    </div>
  </section>

</main>

<!-- Stopka 1:1 z tax-protect.html; „Słownik pojęć” w kolumnie informacyjnej „BeautyPolisa” (aria-current). -->
{stopka(wz)}

{sprite}

{pasek}
{skrypt_strony(wz)}
{JS_SLOWNIK}
{js_w}
</body>
</html>
'''
    s = gen_wspolne.przetworz('slownik.html', s)
    assert s.count('<article class="haslo" id="haslo-') == n
    assert 'Tax Protect – ochrona' not in s.split('</head>')[1].split('<footer')[0], 'resztki treści tax-protect w nagłówku/treści'
    return s


def main():
    check = '--check' in sys.argv
    nowy = strona()
    stary = CEL.read_text(encoding='utf-8') if CEL.exists() else ''
    if check:
        if nowy != stary:
            print('NIEAKTUALNE: slownik.html')
            sys.exit(1)
        print('slownik.html aktualny')
        return
    if nowy != stary:
        CEL.write_text(nowy, encoding='utf-8')
        print(f'Zapisano {CEL} ({len(nowy)} B, {len(HASLA)} haseł)')
    else:
        print('Bez zmian (slownik.html aktualny)')


if __name__ == '__main__':
    main()
