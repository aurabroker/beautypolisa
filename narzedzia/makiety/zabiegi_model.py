#!/usr/bin/env python3
"""Wspólny odczyt i walidacja listy zabiegów OC w wersji 2 (snippets/zabiegi-oc-beauty.json) i archiwum wycofanych
pozycji (snippets/zabiegi-oc-beauty-wycofane.json). Importują go generatory i kontrole – zamiast osobnych asercji
„117 pozycji / 40-38-31-8” w każdym skrypcie.

Model (plan „OC beauty po Aneksie nr 5”, 1.1–1.4):
  * listy[]   – lista-1, lista-2 (numery 1..N z PDF), ankieta (litery a–h), podologia (bez pozycji, tylko dokument);
  * zabiegi[] – rekord = zabieg; pozycje[] = wystąpienia {lista, nr[, nazwa]}; zabieg z identycznym brzmieniem
                (bez wielkości liter) na listach nr 1 i 2 to jeden rekord z dwiema pozycjami; pozycje[].nazwa tylko,
                gdy brzmienie na tej liście różni się wielkością liter; nazwa = brzmienie pierwszego wystąpienia;
  * id        – ^g[1-4]-NN$, stałe, nieużywane ponownie (prefiks historyczny, nie oznacza listy);
  * slug      – transliteracja nazwy, najwyżej 80 znaków (przycięcie na granicy słowa); drugie wystąpienie na stronie
                ma kotwicę <slug>-<klucz listy>; dawne_slugi – kotwice-aliasy sprzed wersji 2;
  * dawne_nazwy – tylko w ankiecie: brzmienia sprzed Aneksu nr 5 (= klucze ZABIEGI_ANKIETA_DAWNE w CRM);
  * wycofane  – archiwum: id, slug i nazwa pozycji usuniętych z listy (wyświetlanie w starych ogłoszeniach, aliasy kotwic).

Uruchom: python3 -I narzedzia/makiety/zabiegi_model.py   – walidacja obu plików i podsumowanie (kod 1 przy błędzie).
"""
import json, pathlib, re, subprocess, sys

REPO = pathlib.Path(__file__).resolve().parents[2]
SN = REPO / 'docs/koncepcja/snippets'
V3 = REPO / 'docs/koncepcja/design/v3'
ZAB = SN / 'zabiegi-oc-beauty.json'
WYC = SN / 'zabiegi-oc-beauty-wycofane.json'

ID = re.compile(r'^g[1-4]-\d{2}$')
SLUG = re.compile(r'^[a-z0-9]+(?:-[a-z0-9]+)*$')
SLUG_MAX = 80
LITERY = 'abcdefghijklmnopqrstuvwxyz'
# Kotwice sekcji strony /ubezpieczenia/oc-beauty, które nie są generowane z listy (plan 1.5).
KOTWICE_STRONY = {'zabiegi', 'taryfa', 'ochrona-prawna', 'faq'}

POLA_LISTY = {'klucz', 'numer', 'zalacznik', 'nazwa', 'zrodlo', 'liczba_pozycji', 'kotwica', 'dawne_kotwice', 'dokument', 'numeracja'}
POLA_ZABIEGU = {'id', 'slug', 'nazwa', 'pozycje', 'dawne_slugi', 'dawne_nazwy'}
POLA_WYCOFANEGO = {'id', 'slug', 'nazwa', 'wersja_listy', 'wycofano_w_wersji', 'powod'}

_TR = str.maketrans('ąćęłńóśźżĄĆĘŁŃÓŚŹŻ', 'acelnoszzACELNOSZZ')


def slug(nazwa, maxlen=SLUG_MAX):
    """Transliteracja nazwy na kotwicę; dłuższa niż maxlen – przycięta na granicy słowa."""
    s = re.sub(r'[^a-z0-9]+', '-', nazwa.translate(_TR).lower()).strip('-')
    if len(s) <= maxlen:
        return s
    cut = s[:maxlen + 1]
    return cut[:cut.rfind('-')]


def wczytaj(sciezka=ZAB):
    return json.loads(pathlib.Path(sciezka).read_text(encoding='utf-8'))


def wczytaj_wycofane(sciezka=WYC):
    return json.loads(pathlib.Path(sciezka).read_text(encoding='utf-8'))


def zapisz_json(sciezka, dane):
    """Format plików w snippets/: wcięcie 1, UTF-8 bez ucieczek, bez końcowego znaku nowej linii."""
    pathlib.Path(sciezka).write_text(json.dumps(dane, ensure_ascii=False, indent=1), encoding='utf-8')


def tekst_json(dane):
    return json.dumps(dane, ensure_ascii=False, indent=1)


def listy(J):
    return {l['klucz']: l for l in J['listy']}


def _klucz_nr(nr):
    return (0, nr, '') if isinstance(nr, int) else (1, 0, nr)


def nazwa_pozycji(z, p):
    return p.get('nazwa', z['nazwa'])


def pozycje_listy(J, klucz):
    """Wystąpienia na liście w kolejności numerów: [(nr, nazwa na liście, rekord zabiegu)]."""
    out = [(p['nr'], nazwa_pozycji(z, p), z) for z in J['zabiegi'] for p in z['pozycje'] if p['lista'] == klucz]
    return sorted(out, key=lambda x: _klucz_nr(x[0]))


def ankieta(J):
    """Jedna mapa a–h: [{litera, id, nazwa, slug, dawne_nazwy}] w kolejności liter."""
    return [{'litera': nr, 'id': z['id'], 'nazwa': n, 'slug': z['slug'], 'dawne_nazwy': z.get('dawne_nazwy', [])}
            for nr, n, z in pozycje_listy(J, 'ankieta')]


def aktywne_ids(J):
    return [z['id'] for z in J['zabiegi']]


def kotwice_wystapien(J):
    """Kotwice <li> na stronie OC: pierwsze wystąpienie – slug, kolejne – <slug>-<klucz listy>."""
    kolej = [l['klucz'] for l in J['listy']]
    out = []
    for z in J['zabiegi']:
        poz = sorted(z['pozycje'], key=lambda p: (kolej.index(p['lista']), _klucz_nr(p['nr'])))
        for i, p in enumerate(poz):
            out.append((z['id'], p['lista'], z['slug'] if i == 0 else '%s-%s' % (z['slug'], p['lista'])))
    return out


def pdf_tekst(sciezka):
    return subprocess.run(['pdftotext', '-raw', str(sciezka), '-'], check=True, capture_output=True, text=True).stdout


def pdf_lista(sciezka):
    """PDF listy zabiegów (pdftotext -raw) → (wiersz „Załącznik nr …”, wiersz „Lista zabiegów – …”, [(nr, nazwa)]).
    Zawinięte wiersze pozycji sklejone spacją; powtórzony na kolejnych stronach nagłówek „Załącznik nr …” pominięty."""
    zal = naz = None
    poz = []
    for ln in pdf_tekst(sciezka).split('\n'):
        s = ln.replace('\f', '').strip()
        if not s:
            continue
        if s.startswith('Załącznik nr'):
            if zal is None:
                zal = s
            elif s != zal:
                raise ValueError('%s: inny nagłówek na kolejnej stronie: %r' % (sciezka, s))
            continue
        if s.startswith('Lista zabiegów'):
            if naz is None:
                naz = s
            continue
        m = re.match(r'^(\d+)\.\s+(.*)$', s)
        if m:
            poz.append([int(m.group(1)), m.group(2)])
        elif poz:
            poz[-1][1] += ' ' + s
        else:
            raise ValueError('%s: tekst przed pierwszą pozycją: %r' % (sciezka, s))
    return zal, naz, [tuple(p) for p in poz]


def waliduj(J, W=None, pliki=True):
    """Lista błędów schematu v2 (pusta = poprawny). W – archiwum wycofanych (opcjonalnie)."""
    e = []
    if J.get('wersja') != 2:
        e.append('wersja ≠ 2')
    L = J.get('listy', [])
    kl = [l.get('klucz') for l in L]
    if len(set(kl)) != len(kl):
        e.append('listy: powtórzony klucz')
    for l in L:
        if set(l) - POLA_LISTY:
            e.append('lista %s: pola spoza schematu %s' % (l.get('klucz'), sorted(set(l) - POLA_LISTY)))
        for pole in ('klucz', 'nazwa', 'kotwica', 'dawne_kotwice'):
            if pole not in l:
                e.append('lista %s: brak pola %s' % (l.get('klucz'), pole))
        if pliki and l.get('dokument') and not (V3 / l['dokument']).is_file():
            e.append('lista %s: brak pliku %s' % (l['klucz'], l['dokument']))
    litery = {l['klucz'] for l in L if l.get('numeracja') == 'litery'}

    ids, slugi = [], []
    for z in J.get('zabiegi', []):
        zid = z.get('id', '?')
        if set(z) - POLA_ZABIEGU:
            e.append('%s: pola spoza schematu %s' % (zid, sorted(set(z) - POLA_ZABIEGU)))
        if not ID.match(zid):
            e.append('%s: id poza wzorcem ^g[1-4]-NN$' % zid)
        ids.append(zid)
        n = z.get('nazwa', '')
        if not n or n != n.strip() or '  ' in n:
            e.append('%s: pusta nazwa albo zbędne spacje' % zid)
        if z.get('slug') != slug(n):
            e.append('%s: slug %r ≠ %r (transliteracja nazwy)' % (zid, z.get('slug'), slug(n)))
        slugi.append(z.get('slug'))
        P = z.get('pozycje') or []
        if not P:
            e.append('%s: brak pozycji' % zid)
        listy_z = [p.get('lista') for p in P]
        if len(set(listy_z)) != len(listy_z):
            e.append('%s: dwie pozycje na tej samej liście' % zid)
        if 'ankieta' in listy_z and len(P) > 1:
            e.append('%s: pozycja ankiety razem z pozycją listy' % zid)
        for p in P:
            if p.get('lista') not in kl:
                e.append('%s: nieznana lista %r' % (zid, p.get('lista')))
            elif p['lista'] in litery:
                if not (isinstance(p.get('nr'), str) and len(p['nr']) == 1 and p['nr'] in LITERY):
                    e.append('%s: numer na liście %s nie jest literą' % (zid, p['lista']))
            elif not (isinstance(p.get('nr'), int) and p['nr'] >= 1):
                e.append('%s: numer na liście %s nie jest liczbą ≥ 1' % (zid, p['lista']))
            if set(p) - {'lista', 'nr', 'nazwa'}:
                e.append('%s: pola pozycji spoza schematu' % zid)
            if 'nazwa' in p and not (p['nazwa'] != n and p['nazwa'].lower() == n.lower()):
                e.append('%s: pozycje[].nazwa dozwolona tylko przy innej wielkości liter' % zid)
        if P and P[0].get('lista') in kl:
            kolej = sorted(P, key=lambda p: (kl.index(p['lista']) if p['lista'] in kl else 99, _klucz_nr(p.get('nr', 0))))
            if P != kolej:
                e.append('%s: pozycje nie w kolejności list' % zid)
            if 'nazwa' in kolej[0]:
                e.append('%s: nazwa rekordu ≠ brzmienie pierwszego wystąpienia' % zid)
        if 'dawne_nazwy' in z and listy_z != ['ankieta']:
            e.append('%s: dawne_nazwy tylko w ankiecie' % zid)
        for pole in ('dawne_slugi', 'dawne_nazwy'):
            if pole in z and (not z[pole] or not all(isinstance(x, str) and x for x in z[pole])):
                e.append('%s: %s – pusta lista albo zły typ' % (zid, pole))
        for s in z.get('dawne_slugi', []):
            if not SLUG.match(s):
                e.append('%s: dawny slug %r poza wzorcem' % (zid, s))

    if len(set(ids)) != len(ids):
        e.append('powtórzone id: %s' % sorted({i for i in ids if ids.count(i) > 1}))
    for s in slugi:
        if not (isinstance(s, str) and SLUG.match(s) and len(s) <= SLUG_MAX):
            e.append('slug %r poza wzorcem albo dłuższy niż %d' % (s, SLUG_MAX))

    # Numeracja każdej listy: 1..N (albo a..) bez luk i powtórzeń; liczba = liczba_pozycji.
    for l in L:
        nr = [p[0] for p in pozycje_listy(J, l['klucz'])]
        ocz = list(LITERY[:len(nr)]) if l['klucz'] in litery else list(range(1, len(nr) + 1))
        if nr != ocz:
            e.append('lista %s: numeracja z lukami albo powtórzeniami' % l['klucz'])
        if l.get('liczba_pozycji') != (len(nr) if nr else None):
            e.append('lista %s: liczba_pozycji %r ≠ %d pozycji' % (l['klucz'], l.get('liczba_pozycji'), len(nr)))

    # Kolejność rekordów: według pierwszego wystąpienia (kolejność list, potem numer).
    def pierwsze(z):
        p = z['pozycje'][0]
        return (kl.index(p['lista']) if p['lista'] in kl else 99, _klucz_nr(p['nr']))
    try:
        if J['zabiegi'] != sorted(J['zabiegi'], key=pierwsze):
            e.append('zabiegi nie w kolejności pierwszego wystąpienia')
    except (KeyError, IndexError, TypeError):
        pass

    # Wszystkie kotwice na stronie unikalne: wystąpienia, aliasy, kotwice sekcji, archiwum.
    kotwice = []
    try:
        kotwice += [k for _, _, k in kotwice_wystapien(J)]
    except (KeyError, ValueError):
        pass
    kotwice += [s for z in J.get('zabiegi', []) for s in z.get('dawne_slugi', [])]
    kotwice += [l.get('kotwica') for l in L] + [k for l in L for k in l.get('dawne_kotwice', [])]
    kotwice += sorted(KOTWICE_STRONY)
    if W is not None:
        if set(W) - {'$comment', 'wycofane'}:
            e.append('archiwum: pola spoza schematu')
        wid = []
        for w in W.get('wycofane', []):
            if set(w) - POLA_WYCOFANEGO or not POLA_WYCOFANEGO <= set(w):
                e.append('wycofane %s: pola ≠ %s' % (w.get('id'), sorted(POLA_WYCOFANEGO)))
            if not ID.match(w.get('id', '')):
                e.append('wycofane %s: id poza wzorcem' % w.get('id'))
            if w.get('id') in ids:
                e.append('wycofane %s: id jest też aktywne' % w.get('id'))
            if not SLUG.match(w.get('slug', '')):
                e.append('wycofane %s: slug poza wzorcem' % w.get('id'))
            wid.append(w.get('id'))
            kotwice.append(w.get('slug'))
        if len(set(wid)) != len(wid):
            e.append('archiwum: powtórzone id')
    pow_ = sorted({k for k in kotwice if kotwice.count(k) > 1})
    if pow_:
        e.append('kolizje kotwic: %s' % pow_)
    return e


def podsumowanie(J, W=None):
    na = {z['id']: {p['lista'] for p in z['pozycje']} for z in J['zabiegi']}
    return {
        'pozycje': {l['klucz']: len(pozycje_listy(J, l['klucz'])) for l in J['listy']},
        'wspolne_1_2': sum(1 for s in na.values() if {'lista-1', 'lista-2'} <= s),
        'tylko_lista_1': sum(1 for s in na.values() if s == {'lista-1'}),
        'tylko_lista_2': sum(1 for s in na.values() if s == {'lista-2'}),
        'aktywne_id': len(J['zabiegi']),
        'wycofane_id': len(W['wycofane']) if W else None,
        'aliasy_slugow': sum(len(z.get('dawne_slugi', [])) for z in J['zabiegi']),
        'przyciete_slugi': [z['id'] for z in J['zabiegi'] if len(slug(z['nazwa'], 10 ** 6)) > SLUG_MAX],
        'najdluzszy_slug': max(len(z['slug']) for z in J['zabiegi']),
    }


def main():
    J = wczytaj()
    W = wczytaj_wycofane() if WYC.is_file() else None
    e = waliduj(J, W)
    print('\n'.join('BŁĄD: ' + x for x in e) or 'OK')
    if not e:
        print(json.dumps(podsumowanie(J, W), ensure_ascii=False))
    return 1 if e else 0


if __name__ == '__main__':
    sys.exit(main())
