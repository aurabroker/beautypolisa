#!/usr/bin/env python3
"""Generuje w makieta-v3.html bloki kalkulatora OC z plików źródłowych (bez ręcznego przepisywania):
  <!-- gen:zabiegi-data -->   <script type="application/json" id="zabiegi-data"> z snippets/zabiegi-oc-beauty.json (wersja 2):
                             tablica w kolejności pliku – pozycje list nr 1 i 2: {id, slug, nazwa, listy:["lista-1","lista-2"]},
                             pozycje ankiety: {id, slug, nazwa, ankieta:"a"…"h"}; podologii nie ma (lista w dokumentach programu)
  <!-- gen:taryfa-data -->    <script type="application/json" id="taryfa-data"> = snippets/taryfa-oc-beauty.json bez pól $comment
                             (stawki, dopłata, ochrona prawna, rodzaje, osoby, pytania, powody, komunikaty, zdania CRM)
  <!-- gen:oc-skladka -->     <script> z treścią snippets/oc-skladka.js (globalny OcSkladka – ta sama funkcja co w testach)
  <!-- gen:taryfa -->         tabela „Pełna taryfa OC” i nota pod nią (oc_taryfa.py – ta sama co GEN:taryfa na oc-beauty.html)
  <!-- gen:klauzula -->       tytuł + <ol> 12 punktów (wyliczenia jako <ul>) z snippets/klauzula-ochrona-prawna.json
Pola kalkulatora (krok 4 planu „OC beauty po Aneksie nr 5”, rozdz. 2) – generowane, gdy w makiecie są ich znaczniki:
  <!-- gen:kalk-rodzaje -->   6 pól checkbox name="rodzaj" (klucze i etykiety z taryfy = CRM), bez zaznaczenia domyślnego
  <!-- gen:kalk-osoby -->     3 pola radio name="osoby" (1-5, 6-8, 9+), bez zaznaczenia domyślnego
  <!-- gen:kalk-ankieta -->   8 pól checkbox name="ankieta" (value = id g4-xx, litery a)–h), brzmienie Aneksu nr 5 z JSON)
Tryb przejściowy: dopóki w makiecie nie ma znacznika gen:kalk-rodzaje (stary układ kalkulatora z kafelkami grup – przebudowa
w kroku 4), bloki pól są pomijane, a teksty ręczne sprawdzane są według starego układu; potem obowiązują wszystkie znaczniki
i nowe teksty (link „Listy zabiegów programu”, „Klauzula ochrony prawnej (+92 zł/rok)”, limit w stopce dialogu klauzuli)
oraz zakazane frazy w całej strefie kalkulatora OC.
Podmienia wyłącznie treść między znacznikami (idempotentnie). Uruchom: python3 -I gen_kalkulator_dane.py [--check]
--check: nic nie zapisuje, kończy się kodem 1, gdy blok w makiecie różni się od wygenerowanego.
"""
import html, json, pathlib, re, sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import zabiegi_model as zm  # noqa: E402
import oc_taryfa as ot  # noqa: E402
from oc_frazy import sprawdz, tekst_html, raport  # noqa: E402

ROOT = str(pathlib.Path(__file__).resolve().parents[2] / 'docs/koncepcja')  # repozytorium/docs/koncepcja
PAGE = ROOT + '/design/v3/makieta-v3.html'
KLA = ROOT + '/snippets/klauzula-ochrona-prawna.json'
SKLADKA_JS = ROOT + '/snippets/oc-skladka.js'
NB = ' '
# ikony rodzajów działalności (plan 2.1); „Gabinet kosmetyczny” i „Salon masażu” – do dorysowania w kroku 4
IKONY = {'kosmetyczny': 'lux-gabinet-kosmetyczny', 'fryzjerski': 'lux-fryzjer', 'kosmetologiczny': 'lux-kosmetolog',
         'podologiczny': 'lux-podolog', 'masaz': 'lux-salon-masazu', 'tatuaz': 'lux-tatuazysta'}
BLOKI_POL = ('kalk-rodzaje', 'kalk-osoby', 'kalk-ankieta')


def esc(s):
    return html.escape(s, quote=False)


def eh(s):
    return html.escape(s, quote=True).replace(NB, '&nbsp;')


def dane_json(obj, el_id):
    body = json.dumps(obj, ensure_ascii=False, separators=(',', ':')).replace('<', '\\u003c')  # nic nie zamknie <script>
    return '<script type="application/json" id="%s">\n%s\n</script>' % (el_id, body)


def zabiegi_block(J):
    rows = []
    for z in J['zabiegi']:
        lst = [p['lista'] for p in z['pozycje']]
        item = {'id': z['id'], 'slug': z['slug'], 'nazwa': z['nazwa']}
        if lst == ['ankieta']:
            item['ankieta'] = z['pozycje'][0]['nr']
        else:
            assert set(lst) <= {'lista-1', 'lista-2'}, (z['id'], lst)
            item['listy'] = lst
        rows.append(json.dumps(item, ensure_ascii=False, separators=(',', ':')))
    body = '[\n' + ',\n'.join(rows) + '\n]'
    body = body.replace('<', '\\u003c')  # nic nie zamknie <script> przedwcześnie
    return '<script type="application/json" id="zabiegi-data">\n' + body + '\n</script>'


def bez_komentarzy(o):
    if isinstance(o, dict):
        return {k: bez_komentarzy(v) for k, v in o.items() if k != '$comment'}
    if isinstance(o, list):
        return [bez_komentarzy(v) for v in o]
    return o


def taryfa_data_block():
    return dane_json(bez_komentarzy(ot.T), 'taryfa-data')


def oc_skladka_block():
    src = open(SKLADKA_JS, encoding='utf-8').read().rstrip('\n')
    assert '</script' not in src.lower()
    return ('<!-- = snippets/oc-skladka.js (wycena jak w CRM: kategoriaZRodzajow, skladkaProgramu, wycenaNowej) – globalny OcSkladka -->\n'
            '<script>\n' + src + '\n</script>')


def taryfa_block():
    return '\n'.join('        ' + l for l in ot.tabela_taryfy('Pełna taryfa OC'))


def rodzaje_block(page):
    out = ['<div class="opt-grid opt-grid--2">']
    for r in ot.T['rodzaje_gabinetu']:
        k = r['klucz']
        ik = IKONY.get(k)
        svg = ('<svg class="lux-icon lux-icon--md" aria-hidden="true"><use href="#%s"/></svg>' % ik
               if ik and ('<symbol id="%s"' % ik) in page else '')
        out.append('  <div class="opt opt--check"><input type="checkbox" id="r-%s" name="rodzaj" value="%s"><label for="r-%s">%s<span>%s</span></label></div>'
                   % (k, k, k, svg, eh(r['nazwa'])))
    out.append('</div>')
    return '\n'.join(out)


def osoby_block():
    ids = {'1-5': 'o-1-5', '6-8': 'o-6-8', '9+': 'o-9-plus'}
    out = ['<div class="opt-grid opt-grid--3">']
    for o in ot.T['liczba_osob']:
        etyk = re.sub(r' (osób)$', NB + r'\1', o['nazwa'])
        out.append('  <div class="opt opt--center"><input type="radio" id="%s" name="osoby" value="%s"><label for="%s">%s</label></div>'
                   % (ids[o['klucz']], o['klucz'], ids[o['klucz']], eh(etyk)))
    out.append('</div>')
    return '\n'.join(out)


def ankieta_block(J):
    out = ['<ul class="ankieta-lista">']  # litery a)–h) w etykiecie (jak w Aneksie nr 5); lista bez własnej numeracji
    for a in zm.ankieta(J):
        out.append('  <li><label class="check-row"><input type="checkbox" id="%s" name="ankieta" value="%s"> <span><span class="ankieta-lit">%s)</span> %s</span></label></li>'
                   % (a['id'], a['id'], a['litera'], eh(a['nazwa'])))
    out.append('</ul>')
    return '\n'.join(out)


def klauzula_block():
    d = json.load(open(KLA, encoding='utf-8'))
    pk = d['punkty']
    assert len(pk) == 12, len(pk)
    out = ['          <p class="klauzula-tytul">' + esc(d['tytul']) + '</p>', '          <ol>']
    for p in pk:
        li = '            <li>' + esc(p['tekst'])
        if p.get('wyliczenie'):
            li += '\n              <ul>\n' + '\n'.join('                <li>' + esc(w) + '</li>' for w in p['wyliczenie']) + '\n              </ul>\n            '
        out.append(li + '</li>')
    out.append('          </ol>')
    return '\n'.join(out), d['skladka_dodatkowa_zl_rocznie']


def put(page, name, block):
    pat = re.compile(r'(<!-- gen:%s -->\n).*?(<!-- /gen:%s -->)' % (name, name), re.S)
    assert len(pat.findall(page)) == 1, 'znacznik gen:%s musi wystąpić dokładnie raz' % name
    return pat.sub(lambda m: m.group(1) + block + '\n' + m.group(2), page)


def blok(page, name):
    m = re.search(r'<!-- gen:%s -->\n(.*?)<!-- /gen:%s -->' % (name, name), page, re.S)
    return m.group(1) if m else ''


def strefa_kalkulatora(page):
    """Strefa OC w makiecie: panel kalkulatora OC (z tabelą taryfy) i skrypt kalkulatora OC."""
    a = page.index('<div class="calc-panel" id="kalkulator-oc">')
    b = page.index('<!-- Tax Protect', a)
    s = page[a:b]
    m = re.search(r'<script>\n/\* Kalkulator OC.*?</script>', page, re.S)
    return s + (m.group(0) if m else '')


def main():
    check = '--check' in sys.argv
    page = open(PAGE, encoding='utf-8').read()
    J = zm.wczytaj()
    W = zm.wczytaj_wycofane()
    bledy = zm.waliduj(J, W) + ot.kontrola()
    assert not bledy, 'dane OC:\n' + '\n'.join(bledy)
    nowy = '<!-- gen:kalk-rodzaje -->' in page
    kb, doplata = klauzula_block()
    op = ot.T['ochrona_prawna']
    assert doplata == op['skladka'], 'dopłata za klauzulę: klauzula-ochrona-prawna.json ≠ taryfa-oc-beauty.json'
    new = page
    for name, block in (('zabiegi-data', zabiegi_block(J)), ('taryfa-data', taryfa_data_block()),
                        ('oc-skladka', oc_skladka_block()), ('taryfa', taryfa_block()), ('klauzula', kb)):
        new = put(new, name, block)
    if nowy:
        for name, block in (('kalk-rodzaje', rodzaje_block(new)), ('kalk-osoby', osoby_block()), ('kalk-ankieta', ankieta_block(J))):
            new = put(new, name, block)
        brak_ikon = [IKONY[r] for r in IKONY if ('<symbol id="%s"' % IKONY[r]) not in new]
        if brak_ikon:
            print('uwaga: brak ikon w makiecie (pola bez ikony): %s' % ', '.join(brak_ikon))
    else:
        obecne = [n for n in BLOKI_POL if '<!-- gen:%s -->' % n in page]
        assert not obecne, 'część znaczników pól kalkulatora jest, części brak: %s' % obecne
        print('uwaga: kalkulator OC w starym układzie (bez gen:kalk-rodzaje) – bloki pól pominięte do przebudowy (krok 4 planu)')

    # spójność tekstów pisanych ręcznie z danymi
    assert 'Dopłata za klauzulę: %d&nbsp;zł rocznie' % doplata in new, 'dopłata w stopce dialogu'
    if nowy:
        assert 'Listy zabiegów programu' in new, 'link pod rodzajami działalności'
        assert 'Klauzula ochrony prawnej (+%d&nbsp;zł/rok)' % doplata in new, 'dopłata przy checkboxie'
        assert 'Limit: %s' % eh(ot.zl(op['limit'])) in new, 'limit ochrony prawnej w stopce dialogu klauzuli (źródło: program w CRM)'
    else:
        assert 'Dodaj ochronę prawną: +%d&nbsp;zł rocznie' % doplata in new, 'dopłata przy checkboxie'

    # zakazane frazy (plan 6.8, K7): w blokach generatora zawsze, w całej strefie kalkulatora OC – po przebudowie (krok 4)
    wyjatki = [n for z in J['zabiegi'] for n in z.get('dawne_nazwy', [])]
    nazwy = ['zabiegi-data', 'taryfa-data', 'oc-skladka', 'taryfa', 'klauzula'] + (list(BLOKI_POL) if nowy else [])
    traf = [(n, t) for n in nazwy for t in sprawdz(tekst_html(blok(new, n)), wyjatki)]
    if nowy:
        traf += [('strefa kalkulatora OC', t) for t in sprawdz(tekst_html(strefa_kalkulatora(new)), wyjatki)]
    assert not traf, '\n'.join(raport('makieta-v3.html ' + n, [t]) for n, t in traf)

    if check:
        print('OK' if new == page else 'RÓŻNICA – uruchom bez --check')
        sys.exit(0 if new == page else 1)
    if new != page:
        # zapis tylko, gdy plik nie zmienił się w trakcie (równoległe edycje)
        if open(PAGE, encoding='utf-8').read() != page:
            sys.exit('makieta zmieniła się w trakcie – uruchom ponownie')
        open(PAGE, 'w', encoding='utf-8').write(new)
    pod = zm.podsumowanie(J)['pozycje']
    print('zabiegi: lista nr 1 – %d, lista nr 2 – %d, ankieta – %d; taryfa: %d kategorie × %d sumy; klauzula: 12 punktów, dopłata %d zł; '
          'pola kalkulatora: %s – %s' % (pod['lista-1'], pod['lista-2'], pod['ankieta'], len(ot.T['kategorie']), len(ot.T['sumy']),
                                          doplata, 'tak' if nowy else 'krok 4', 'zapisano' if new != page else 'bez zmian'))


main()
