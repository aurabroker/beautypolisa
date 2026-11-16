#!/usr/bin/env python3
"""Taryfa OC beauty (snippets/taryfa-oc-beauty.json) dla generatorów stron: formaty kwot, opis reguły kategorii słowami,
tabela „Pełna taryfa OC” i nota pod nią – jedna implementacja dla oc-beauty.html (GEN:taryfa) i makieta-v3.html (gen:taryfa).

Reguła kategorii portalu – decyzja zleceniodawcy D45 z 16.11.2026 (00): rodzaj z listy nr 1 (kosmetyczny, fryzjerski, masaż)
razem z rodzajem z listy nr 2 (kosmetologiczny, tatuaż) – pełna taryfa; podologia zawsze pełna; same rodzaje z listy nr 2 –
kosmetologiczna; same z listy nr 1 – kosmetyczna i fryzjerska. Grupy rodzajów są danymi (taryfa-oc-beauty.json → regula_kategorii),
sama reguła – kodem (snippets/oc-skladka.js: kategoria; tu – kategoria()). To ODSTĘPSTWO od CRM (kategoriaZRodzajow: z listą nr 2
pełną taryfę daje tylko salon fryzjerski) w 9 połączeniach rodzajów – check_zgodnosc_crm.py przyjmuje je tylko z oznaczeniem
odstepstwo_D45 w fixture. Tu jest też opis reguły słowami (OPIS_KATEGORII) i warunek (WARUNEK), który go wyraża; kontrola()
sprawdza na wszystkich 63 niepustych połączeniach rodzajów, że warunek = kategoria() = fixture kontrola/kalkulator-przypadki.json
(64 kombinacje) i że każdy rodzaj działalności jest w dokładnie jednej grupie regula_kategorii.

Formaty (decyzja Q9): tabele taryfy bez groszy („1 250 zł”), kwota z wyliczenia z groszami („987,50 zł”), sumy jak dotąd
(„200 tys. zł” w tabelach, „200 000 zł” w zdaniach FAQ); separator tysięcy i spacja przed „zł” – twarde (U+00A0).

Uruchom: python3 -I oc_taryfa.py – kontrola opisu reguły i podgląd tabeli.
"""
import html
import itertools
import json
import pathlib
import re
import sys
from decimal import Decimal, ROUND_HALF_UP

REPO = pathlib.Path(__file__).resolve().parents[2]
SN = REPO / 'docs/koncepcja/snippets'
TARYFA = SN / 'taryfa-oc-beauty.json'
FIXTURE = pathlib.Path(__file__).resolve().parent / 'kontrola/kalkulator-przypadki.json'
NB = ' '

T = json.loads(TARYFA.read_text(encoding='utf-8'))
KAT = {k['klucz']: k for k in T['kategorie']}
RODZAJE = [r['klucz'] for r in T['rodzaje_gabinetu']]
NAZWA_RODZAJU = {r['klucz']: r['nazwa'] for r in T['rodzaje_gabinetu']}
REGULA = T['regula_kategorii']
LISTA1, LISTA2, ZAWSZE_PELNA = set(REGULA['lista_1']), set(REGULA['lista_2']), set(REGULA['zawsze_pelna'])

# Opis słowami, które rodzaje działalności prowadzą do której taryfy (plan 2.3 i 3; reguła D45 – odstępstwo od CRM).
OPIS_KATEGORII = {
    'kosmetyczny_fryzjerski': 'tylko gabinet kosmetyczny, salon fryzjerski lub salon masażu (także razem)',
    'kosmetologiczny': 'tylko gabinet kosmetologiczny lub salon tatuażu (także razem)',
    'pelny': ('gabinet podologiczny (z innymi rodzajami lub bez) albo gabinet kosmetyczny, salon fryzjerski lub salon masażu '
              'razem z gabinetem kosmetologicznym lub salonem tatuażu'),
}
# Warunek, który opis wyraża (sprawdzany z kategoria() i z fixture) – zapisany nazwami rodzajów, bez grup z JSON.
_L1_SLOWAMI, _L2_SLOWAMI = {'kosmetyczny', 'fryzjerski', 'masaz'}, {'kosmetologiczny', 'tatuaz'}
WARUNEK = {
    'kosmetyczny_fryzjerski': lambda r: r <= _L1_SLOWAMI,
    'kosmetologiczny': lambda r: r <= _L2_SLOWAMI,
    'pelny': lambda r: 'podologiczny' in r or (bool(r & _L1_SLOWAMI) and bool(r & _L2_SLOWAMI)),
}


def kategoria(rodzaje):
    """Reguła D45 = OcSkladka.kategoria (snippets/oc-skladka.js); grupy z taryfa-oc-beauty.json (regula_kategorii)."""
    r = set(rodzaje)
    if not r:
        return None
    if r & ZAWSZE_PELNA or (r & LISTA1 and r & LISTA2):
        return 'pelny'
    return 'kosmetologiczny' if r & LISTA2 else 'kosmetyczny_fryzjerski'


def grupuj(n):
    s = str(n)
    out = ''
    while len(s) > 3:
        out = NB + s[-3:] + out
        s = s[:-3]
    return s + out


def zl(n):
    """Kwota całkowita: „400 zł”, „1 250 zł” (tabele taryfy, stawki)."""
    assert int(n) == n, n
    return grupuj(int(n)) + NB + 'zł'


def zl_gr(kwota):
    """Kwota z groszami: „987,50 zł”, „1 279,50 zł”, „1 250,00 zł”."""
    d = Decimal(str(kwota)).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
    calk, gr = divmod(int(d * 100), 100)
    return '%s,%02d%szł' % (grupuj(calk), gr, NB)


def suma_tys(s):
    """Suma gwarancyjna w tabelach i kafelkach: „200 tys. zł”."""
    assert s % 1000 == 0, s
    return '%d%stys.%szł' % (s // 1000, NB, NB)


def suma_pelna(s):
    """Suma gwarancyjna w zdaniach: „200 000 zł”."""
    return zl(s)


def stawka(k, suma):
    return KAT[k]['skladka'][str(suma)]


def kwota(k, suma, osoby='1-5', ochrona_prawna=False):
    """= skladkaProgramu (CRM): stawka × (1 + dopłata) przy 6–8 osobach, + ochrona prawna, zaokrąglenie do grosza."""
    b = Decimal(stawka(k, suma))
    if osoby == '6-8':
        b = b * (1 + Decimal(str(T['doplata_6_8_osob'])))
    elif osoby != '1-5':
        raise ValueError(osoby)
    if ochrona_prawna:
        b += Decimal(T['ochrona_prawna']['skladka'])
    return b.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)


def doplata_proc():
    return '%d%%' % round(T['doplata_6_8_osob'] * 100)


def reguly_kategorii():
    """Zdanie z regułą kategorii (strona OC: reguły pod listami, FAQ)."""
    czesci = ['%s – „%s”' % (OPIS_KATEGORII[k['klucz']], k['nazwa']) for k in T['kategorie']]
    return 'Taryfę wyznacza rodzaj działalności: ' + '; '.join(czesci) + '.'


def nota_taryfy():
    """Nota pod tabelą taryfy (tekst z encjami HTML)."""
    return ('6–8&nbsp;osób wykonujących zabiegi – składka z&nbsp;taryfy wyższa o&nbsp;%s (klauzula ochrony prawnej +%d&nbsp;zł bez tej dopłaty). '
            'Więcej niż 8&nbsp;osób albo zabiegi wymagające ankiety ERGO Hestii – wycena indywidualna.'
            % (doplata_proc(), T['ochrona_prawna']['skladka']))


def teksty_crm(klucz):
    """Zdania CRM przytaczane dosłownie (teksty_crm → pozycje). W wymaganiu dokumentów CRM wstawia datę „najpóźniej {termin}”
    (dzień początku ochrony minus 12 miesięcy) – na stronach bez daty zostaje warunek z nawiasu CRM: „co najmniej 12 miesięcy
    przed początkiem ochrony” (rozstrzygnięcie K16)."""
    out = []
    for t in T['teksty_crm'][klucz]['pozycje']:
        t2 = re.sub(r'najpóźniej \{termin\} \((co najmniej 12 miesięcy przed początkiem ochrony)\)', r'\1', t)
        assert '{' not in t2, 'teksty_crm.%s: nieobsłużone pole w %r' % (klucz, t)
        out.append(t2)
    return out


def zdanie_z_innej_listy():
    """K12 (rozstrzygnięcie): z komunikatu CRM przy „Zabiegi z innej listy programu” tylko pierwsze zdanie, bez końcówki
    o ekranie CRM („— nową składkę widzisz niżej”): „Dopisanie zabiegów z innej listy zmienia rodzaj działalności i składkę
    według taryfy programu.”"""
    t = T['teksty_crm']['zabiegi_z_innej_listy']['tekst']
    z = t.split(' — ')[0].rstrip('.') + '.'
    assert z.startswith('Dopisanie zabiegów z innej listy') and '{' not in z, z
    return z


def tabela_taryfy(aria_label):
    """Linie HTML: przewijana tabela taryfy (bez groszy) + nota. Sumy jak dotąd („100 tys. zł”)."""
    e = lambda s: html.escape(s, quote=True)
    nb = lambda s: e(s).replace(NB, '&nbsp;')
    out = ['<div class="table-scroll" role="region" tabindex="0" aria-label="%s">' % e(aria_label),
           '<table>',
           '  <caption>Składka roczna według taryfy programu OC z&nbsp;ERGO Hestią – do 5&nbsp;osób wykonujących zabiegi</caption>',
           '  <thead><tr><th scope="col">Taryfa (zakres na certyfikacie)</th>'
           + ''.join('<th scope="col">%s</th>' % nb(suma_tys(s)) for s in T['sumy']) + '</tr></thead>',
           '  <tbody>']
    for k in T['kategorie']:
        out.append('    <tr><th scope="row">%s<small>%s</small></th>%s</tr>'
                   % (e(k['nazwa']), e(OPIS_KATEGORII[k['klucz']]),
                      ''.join('<td>%s</td>' % nb(zl(k['skladka'][str(s)])) for s in T['sumy'])))
    out += ['  </tbody>', '</table>', '</div>', '<p class="tariff-note">%s</p>' % nota_taryfy()]
    return out


def kontrola():
    """Błędy: opis reguły (WARUNEK) ≠ kategoria() albo ≠ fixture; stawki niecałkowite."""
    e = []
    for n in range(1, len(RODZAJE) + 1):
        for comb in itertools.combinations(RODZAJE, n):
            r = set(comb)
            k = kategoria(r)
            pasuje = [kk for kk, w in WARUNEK.items() if w(r)]
            if pasuje != [k]:
                e.append('rodzaje %s: kategoria %s, opis słowami pasuje do %s' % (sorted(r), k, pasuje))
    if FIXTURE.is_file():
        F = json.loads(FIXTURE.read_text(encoding='utf-8'))
        for x in F['kombinacje_rodzajow']:
            if kategoria(x['rodzaje']) != x['kategoria']:
                e.append('fixture %s: %s ≠ %s' % (x['rodzaje'], kategoria(x['rodzaje']), x['kategoria']))
        for x in F['kwoty_taryfy']:
            if kwota(x['kategoria'], x['suma'], x['osoby'], x['ochrona_prawna']) != Decimal(str(x['kwota'])).quantize(Decimal('0.01')):
                e.append('fixture kwota %s' % x)
    for k in T['kategorie']:
        if set(k['skladka']) != {str(s) for s in T['sumy']} or any(int(v) != v for v in k['skladka'].values()):
            e.append('kategoria %s: stawki ≠ sumy albo niecałkowite' % k['klucz'])
    if set(OPIS_KATEGORII) != set(KAT):
        e.append('OPIS_KATEGORII ≠ kategorie taryfy')
    grupy = REGULA['lista_1'] + REGULA['lista_2'] + REGULA['zawsze_pelna']
    if sorted(grupy) != sorted(RODZAJE):
        e.append('regula_kategorii: rodzaj działalności poza grupami albo w kilku grupach (%s)' % sorted(grupy))
    return e


if __name__ == '__main__':
    b = kontrola()
    print('\n'.join('BŁĄD: ' + x for x in b) or 'OK – opis reguły = kategoria() (D45) = fixture (63 połączenia rodzajów)')
    print(reguly_kategorii())
    print('\n'.join(tabela_taryfy('Taryfa OC')))
    sys.exit(1 if b else 0)
