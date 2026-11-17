#!/usr/bin/env python3
"""Generuje w strefa/dam-prace.html bloki zabiegów z snippets/zabiegi-oc-beauty.json (wersja 2, Aneks nr 5)
i archiwum snippets/zabiegi-oc-beauty-wycofane.json (bez ręcznego przepisywania):
  <!-- gen:zabiegi-data -->              <script type="application/json" id="zabiegi-data"> –
                                         {"listy":[{klucz,nazwa,liczba}],"zabiegi":[{id,nazwa,listy}],"wycofane":[{id,nazwa}]}
                                         (zabiegi – kolejność pierwszego wystąpienia: lista nr 1, lista nr 2, ankieta a–h;
                                         wycofane – tylko do wyświetlania nazw w ogłoszeniach, które już je mają)
  <!-- gen:zabiegi-checkboxy:KLUCZ [checked="g1-01 g2-13"] -->
                                         statyczne checkboxy (name="zabieg", value=id) w <details> per lista – lista nr 1,
                                         lista nr 2, zabiegi wymagające ankiety; pozycja z obu list jest w obu sekcjach z tym
                                         samym value (skrypt strony synchronizuje zaznaczenie, serwer usuwa powtórzenia);
                                         działają bez JS jako zwykły formularz (GET ?zabieg=g2-12&zabieg=… albo POST);
                                         checked = wybór w makiecie (zaznacza każde wystąpienie); wycofanych nie ma w wyborze
  <div class="zab-tags" data-ids="g1-17 g1-25" [data-limit="3"] [data-more="text|details"]>…</div>
                                         treść chipów zabiegów na kartach ogłoszeń (nazwy z pliku; do N chipów + „i N innych”);
                                         kolejność jak na listach programu (stała, bez „trafności”), wycofane na końcu z dopiskiem
                                         „pozycja wycofana z listy” – generator porządkuje też data-ids
Polska typografia (raport 16, 3.1): nazwy pozycji i sekcji w HTML przez typografia.esc() (twarde spacje po „i/w/z”, po „nr”,
przed „–”; JSON bez zmian); blok gen:zabiegi-data niesie też funkcję bpTypografia() (typografia.JS) – skrypt strony stosuje ją
do nazw w chipach i podglądzie ogłoszenia.
Podmienia wyłącznie treść między znacznikami (idempotentnie). Lista 1:1 (walidacja zabiegi_model.py), bez synonimów,
nazwy pozycji jak na danej liście. Uruchom: python3 -I gen_strefa_zabiegi.py [--check]
--check: nic nie zapisuje, kończy się kodem 1, gdy blok w makiecie różni się od wygenerowanego.
"""
import html, json, pathlib, re, sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import zabiegi_model as zm  # noqa: E402
import typografia as ty  # noqa: E402
from oc_frazy import sprawdz, tekst_html, raport  # noqa: E402

ROOT = str(pathlib.Path(__file__).resolve().parents[2] / 'docs/koncepcja')  # repozytorium/docs/koncepcja
PAGE = ROOT + '/design/v3/strefa/dam-prace.html'
MAX_W_OGLOSZENIU = 30
DOPISEK_WYCOFANE = 'pozycja wycofana z listy'
LISTY_WYBORU = ('lista-1', 'lista-2', 'ankieta')  # podologia – bez pozycji (dokument programu)


def esc(s):
    return html.escape(s, quote=True)


def plural(n, one, few, many):
    if n == 1:
        return one
    d, t = n % 10, n % 100
    return few if (2 <= d <= 4 and not 12 <= t <= 14) else many


def nazwa_sekcji(lista):
    """„Lista nr 1 – gabinety kosmetyczne i fryzjerskie” (nagłówek PDF bez „Lista zabiegów”); ankieta – nazwa z JSON."""
    if lista.get('numer'):
        pref = 'Lista zabiegów – '
        assert lista['nazwa'].startswith(pref), lista['nazwa']
        return 'Lista nr %d – %s' % (lista['numer'], lista['nazwa'][len(pref):])
    return lista['nazwa']


def load():
    J = zm.wczytaj()
    W = zm.wczytaj_wycofane()
    bledy = zm.waliduj(J, W)
    assert not bledy, 'zabiegi-oc-beauty.json / archiwum wycofanych:\n' + '\n'.join(bledy)
    L = zm.listy(J)
    sekcje = []
    for k in LISTY_WYBORU:
        poz = zm.pozycje_listy(J, k)
        assert len(poz) == L[k]['liczba_pozycji'], (k, len(poz))
        sekcje.append({'klucz': k, 'nazwa': nazwa_sekcji(L[k]), 'pozycje': [(z['id'], n) for _, n, z in poz]})
    return J, W, sekcje


def data_block(J, W, sekcje):
    listy = [{'klucz': s['klucz'], 'nazwa': s['nazwa'], 'liczba': len(s['pozycje'])} for s in sekcje]
    rows = [json.dumps({'id': z['id'], 'nazwa': z['nazwa'], 'listy': [p['lista'] for p in z['pozycje']]},
                       ensure_ascii=False, separators=(',', ':')) for z in J['zabiegi']]
    wyc = [json.dumps({'id': w['id'], 'nazwa': w['nazwa']}, ensure_ascii=False, separators=(',', ':')) for w in W['wycofane']]
    body = ('{"listy":' + json.dumps(listy, ensure_ascii=False, separators=(',', ':'))
            + ',\n"zabiegi":[\n' + ',\n'.join(rows) + '\n],\n"wycofane":[\n' + ',\n'.join(wyc) + '\n]}')
    body = body.replace('<', '\\u003c')  # nic nie zamknie <script> przedwcześnie
    return ('<script type="application/json" id="zabiegi-data">\n' + body + '\n</script>\n'
            '<script>/* polska typografia nazw zabiegów w chipach (narzedzia/makiety/typografia.py, JS) */\n' + ty.JS + '\n</script>')


def checkbox_block(key, checked, sekcje, aktywne):
    bad = [c for c in checked if c not in aktywne]
    assert not bad, 'nieznane albo wycofane id w checked (%s): %s' % (key, bad)
    assert len(checked) == len(set(checked)) and len(checked) <= MAX_W_OGLOSZENIU, key
    out = ['<div class="zab-groups">']
    for s in sekcje:
        n = len(s['pozycje'])
        is_open = ' open' if any(i in checked for i, _ in s['pozycje']) else ''
        out.append('  <details class="zab-grp" data-lista="%s"%s>' % (s['klucz'], is_open))
        out.append('    <summary><span class="zab-grp-name">%s</span><span class="zab-grp-meta"><span class="zab-grp-n">%d&nbsp;%s</span><span class="zab-grp-sel"></span></span></summary>'
                   % (ty.esc(s['nazwa'], quote=True), n, plural(n, 'pozycja', 'pozycje', 'pozycji')))
        out.append('    <fieldset class="zab-list">')
        out.append('      <legend class="sr-only">%s</legend>' % ty.esc(s['nazwa'], quote=True))
        for i, nazwa in s['pozycje']:
            out.append('      <label class="check-row"><input type="checkbox" name="zabieg" value="%s"%s> <span>%s</span></label>'
                       % (i, ' checked' if i in checked else '', ty.esc(nazwa, quote=True)))
        out.append('    </fieldset>')
        out.append('  </details>')
    out.append('</div>')
    return '\n'.join(out)


def more_label(k):
    """„i N innych” w HTML – twarda spacja po „i” (typografia.esc; ta sama postać daje moreLabel() w skrypcie strony)."""
    return ty.esc('i %d %s' % (k, plural(k, 'inny', 'inne', 'innych')))


def tag_li(i, names, wycofane):
    if i in wycofane:
        return '<li class="zab-tag-wycofany">%s</li>' % ty.esc('%s (%s)' % (wycofane[i], DOPISEK_WYCOFANE), quote=True)
    return '<li>%s</li>' % ty.esc(names[i], quote=True)


def tags_inner(ids, limit, more, names, wycofane):
    shown = ids if not limit else ids[:limit]
    rest = [] if not limit else ids[limit:]
    li = ''.join(tag_li(i, names, wycofane) for i in shown)
    if rest and more == 'details':
        li += ('<li class="zab-tags-more"><details><summary>%s</summary><ul aria-label="Pozostałe zabiegi">%s</ul></details></li>'
               % (more_label(len(rest)), ''.join(tag_li(i, names, wycofane) for i in rest)))
    elif rest:
        li += '<li class="zab-tags-more">%s</li>' % more_label(len(rest))
    return '<ul aria-label="Zabiegi w ogłoszeniu">' + li + '</ul>'


def put(page, start, end, block):
    pat = re.compile('(' + re.escape(start) + r'\n).*?(' + re.escape(end) + ')', re.S)
    assert len(pat.findall(page)) == 1, 'znacznik %s musi wystąpić dokładnie raz' % start
    return pat.sub(lambda m: m.group(1) + block + '\n' + m.group(2), page)


def bloki_gen(s):
    """Treść bloków gen:zabiegi-* i chipów (do kontroli zakazanych fraz)."""
    out = re.findall(r'<!-- gen:zabiegi-[a-z:-]+(?: [a-z]+="[^"]*")* -->\n(.*?)<!-- /gen:zabiegi-', s, flags=re.S)
    out += re.findall(r'<div class="zab-tags"[^>]*>.*?</div>', s, flags=re.S)
    return out


def main():
    check = '--check' in sys.argv
    page = open(PAGE, encoding='utf-8').read()
    J, W, sekcje = load()
    names = {z['id']: z['nazwa'] for z in J['zabiegi']}
    wycofane = {w['id']: w['nazwa'] for w in W['wycofane']}
    order = {i: n for n, i in enumerate([z['id'] for z in J['zabiegi']] + [w['id'] for w in W['wycofane']])}
    new = put(page, '<!-- gen:zabiegi-data -->', '<!-- /gen:zabiegi-data -->', data_block(J, W, sekcje))

    keys = re.findall(r'<!-- gen:zabiegi-checkboxy:([a-z0-9-]+)((?: [a-z]+="[^"]*")*) -->', new)
    assert keys, 'brak bloków gen:zabiegi-checkboxy:*'
    assert len({k for k, _ in keys}) == len(keys), 'powtórzony klucz gen:zabiegi-checkboxy'
    for key, attrs in keys:
        m = re.search(r'checked="([^"]*)"', attrs)
        checked = m.group(1).split() if m else []
        start = '<!-- gen:zabiegi-checkboxy:%s%s -->' % (key, attrs)
        new = put(new, start, '<!-- /gen:zabiegi-checkboxy:%s -->' % key, checkbox_block(key, checked, sekcje, names))

    ntags = 0

    def tag_sub(m):
        nonlocal ntags
        attrs = m.group(1)
        ids = re.search(r'data-ids="([^"]*)"', attrs).group(1).split()
        bad = [i for i in ids if i not in order]
        assert not bad, 'nieznane id w zab-tags (ani na liście, ani w archiwum wycofanych): %s' % bad
        ids = sorted(ids, key=order.get)
        attrs = re.sub(r'data-ids="[^"]*"', 'data-ids="%s"' % ' '.join(ids), attrs)
        assert len(ids) == len(set(ids)) and len(ids) <= MAX_W_OGLOSZENIU, ids
        lm = re.search(r'data-limit="(\d+)"', attrs)
        mm = re.search(r'data-more="(text|details)"', attrs)
        ntags += 1
        return ('<div class="zab-tags"' + attrs + '>'
                + tags_inner(ids, int(lm.group(1)) if lm else 3, mm.group(1) if mm else 'text', names, wycofane) + '</div>')

    new = re.sub(r'<div class="zab-tags"([^>]*)>.*?</div>', tag_sub, new, flags=re.S)
    # spójność tekstów pisanych ręcznie z danymi
    assert 'maks.&nbsp;%d' % MAX_W_OGLOSZENIU in new, 'limit zabiegów w etykiecie pól formularzy'
    # zakazane frazy (plan 6.8, K7) – tylko w blokach tego generatora; wyjątki: nazwy z archiwum wycofanych, dawne brzmienia ankiety
    wyjatki = list(wycofane.values()) + [n for z in J['zabiegi'] for n in z.get('dawne_nazwy', [])]
    traf = [t for b in bloki_gen(new) for t in sprawdz(tekst_html(b), wyjatki)]
    assert not traf, raport('dam-prace.html (bloki gen)', traf)
    if check:
        print('OK' if new == page else 'RÓŻNICA – uruchom bez --check')
        sys.exit(0 if new == page else 1)
    if new != page:
        if open(PAGE, encoding='utf-8').read() != page:
            sys.exit('makieta zmieniła się w trakcie – uruchom ponownie')
        open(PAGE, 'w', encoding='utf-8').write(new)
    print('zabiegi: %d aktywnych (%s), wycofane w archiwum: %d, bloki checkboxów: %s, karty z zabiegami: %d – %s'
          % (len(names), ' / '.join('%s %d' % (s['klucz'], len(s['pozycje'])) for s in sekcje), len(wycofane),
             ', '.join(k for k, _ in keys), ntags, 'zapisano' if new != page else 'bez zmian'))


main()
