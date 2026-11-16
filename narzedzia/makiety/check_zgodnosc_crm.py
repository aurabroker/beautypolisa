#!/usr/bin/env python3
"""Zgodność taryfy i wyceny OC portalu z CRM (crmaura) – kontrola uruchamiana tam, gdzie są oba repozytoria.
Kod CRM czyta jako TEKST (bez uruchamiania). Sprawdza:
  1. stałe: snippets/taryfa-oc-beauty.json = program.ts (SUMY, KATEGORIE, DOPLATA_6_8_OSOB, OCHRONA_PRAWNA_SKLADKA,
     OCHRONA_PRAWNA_LIMIT, RODZAJE_GABINETU, LICZBA_OSOB, APK_PYTANIA, PROGRAM_NR);
  2. regułę: treść kategoriaZRodzajow, skladkaProgramu, wycenaNowej, formatSuma i formatZl w CRM = wzorzec zapisany
     niżej (zmiana w CRM → czerwony wynik i przegląd oc-skladka.js); powody wyceny indywidualnej i komunikaty braków
     z JSON występują w CRM; zdania z teksty_crm występują dosłownie w komponentach CRM;
  3. fixture narzedzia/makiety/kontrola/kalkulator-przypadki.json – przeliczony NIEZALEŻNĄ implementacją (Decimal,
     stałe wczytane z CRM): 44 przypadki porównywalne z CRM (kategoria, kwota, tekst i opis jak w CRM, powód),
     przypadki tylko_portal muszą być niekompletne dla CRM, 64 kombinacje rodzajów, 36 kwot; nazwy zabiegów
     z ankiety w fixture = ZABIEGI_ANKIETA (CRM bez komunikatu odrzuca inne);
  4. ODSTĘPSTWO D45 (decyzja zleceniodawcy 16.11.2026, 00): portal liczy kategorię regułą D45 (kategoria_d45 niżej –
     druga niezależna implementacja), CRM – kategoriaZRodzajow. Różnicę z CRM przyjmujemy WYŁĄCZNIE w połączeniach rodzajów
     z ODSTEPSTWO_D45 (9 połączeń: gabinet kosmetyczny lub salon masażu, bez salonu fryzjerskiego i gabinetu podologicznego,
     razem z gabinetem kosmetologicznym lub salonem tatuażu) i tylko w przypadkach / kombinacjach fixture z polem
     odstepstwo_D45, którego treść = wynik CRM; oczekiwane = wynik reguły D45. Każdą różnicę wypisujemy (ODSTĘPSTWO D45: …).
     Inna różnica, brak oznaczenia przy różnicy albo oznaczenie bez różnicy = błąd. Gdy CRM wdroży D45
     (docs/koncepcja/do-crm/2026-11-16-D45-kategoria-taryfy-oc.md), wzorzec kategoriaZRodzajow przestanie pasować – wtedy
     usuń oznaczenia odstepstwo_D45 z fixture, ODSTEPSTWO_D45 i kategoria_d45 stąd i zaktualizuj WZORZEC.
Listy zabiegów (PDF ↔ JSON ↔ CRM) sprawdza osobno check_zabiegi_pdf.py.

Uruchom: python3 -I narzedzia/makiety/check_zgodnosc_crm.py [--crm KATALOG]
Kod wyjścia: 0 – zgodne, 1 – różnice, 2 – brak repozytorium CRM.
"""
import json, pathlib, re, sys
from decimal import Decimal, ROUND_HALF_UP
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))  # python3 -I nie dodaje katalogu skryptu
import crm_tekst

REPO = pathlib.Path(__file__).resolve().parents[2]
TARYFA = REPO / 'docs/koncepcja/snippets/taryfa-oc-beauty.json'
FIXTURE = pathlib.Path(__file__).resolve().parent / 'kontrola/kalkulator-przypadki.json'
KOMPONENTY = 'src/lib/components/renewal/'

# Wzorzec kodu CRM (commit e01fbfb, 11.11.2026), porównywany po złączeniu białych znaków. kategoriaZRodzajow – reguła CRM
# SPRZED decyzji D45 (portal liczy już według D45 – punkt 4 opisu wyżej).
WZORZEC = {
    'kategoriaZRodzajow': """export function kategoriaZRodzajow(rodzaje: RodzajGabinetu[]): Kategoria | null {
	if (!rodzaje.length) return null;
	const r = new Set(rodzaje);
	const lista2 = r.has('kosmetologiczny') || r.has('tatuaz');
	if (r.has('podologiczny') || (lista2 && r.has('fryzjerski'))) return 'pelny';
	if (lista2) return 'kosmetologiczny';
	return 'kosmetyczny_fryzjerski';
}""",
    'skladkaProgramu': """export function skladkaProgramu(o: { kategoria: Kategoria; suma: Suma; osoby: LiczbaOsob; ochronaPrawna: boolean }): Wycena {
	if (o.osoby === '9+') return { rodzaj: 'indywidualna', powod: 'gabinet zatrudnia więcej niż 8 osób' };
	const baza = KATEGORIE[o.kategoria].skladka[o.suma];
	const zDoplata = o.osoby === '6-8' ? baza * (1 + DOPLATA_6_8_OSOB) : baza;
	const kwota = Math.round((zDoplata + (o.ochronaPrawna ? OCHRONA_PRAWNA_SKLADKA : 0)) * 100) / 100;
	const czesci = [`${KATEGORIE[o.kategoria].nazwa}, suma ${formatSuma(o.suma)}: ${baza} zł`];
	if (o.osoby === '6-8') czesci.push('+25% (6–8 osób)');
	if (o.ochronaPrawna) czesci.push(`+${OCHRONA_PRAWNA_SKLADKA} zł ochrona prawna`);
	return { rodzaj: 'kwota', kwota, opis: czesci.join(', ') };
}""",
    'wycenaNowej': """export function wycenaNowej(w: Wniosek, apk: Apk | null): Wycena | null {
	const z = w.zmiany;
	const suma = z?.wyzsza_suma;
	if (w.decyzja !== 'nowa' || !z || !suma) return null;
	if (z.zabiegi_ankieta.length) return { rodzaj: 'indywidualna', powod: 'zabiegi wymagające ankiety podlegają ocenie ubezpieczyciela' };
	const rodzaje = apk?.rodzaje.length ? apk.rodzaje : z.rodzaje;
	const osoby = apk?.osoby || z.osoby;
	const kategoria = kategoriaZRodzajow(rodzaje);
	if (!kategoria || !osoby) return { rodzaj: 'indywidualna', powod: 'brak danych do wyceny' };
	return skladkaProgramu({ kategoria, suma, osoby, ochronaPrawna: z.ochrona_prawna });
}""",
    'formaty': """export const formatSuma = (s: number) => `${Math.round(s).toString().replace(/\\B(?=(\\d{3})+(?!\\d))/g, '.')} zł`;
export const formatZl = (n: number) =>
	`${n.toLocaleString('pl-PL', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} zł`;""",
}

bledy, info = [], []


def rowne(opis, jest, ma):
    if jest != ma:
        bledy.append('%s: portal (JSON/fixture) %r ≠ CRM %r' % (opis, jest, ma))


def blok(src, poczatek, koniec):
    i = src.index(poczatek)
    return src[i:src.index(koniec, i)]


def stale_crm(src):
    kat = []
    for k, n, s in re.findall(r"(\w+): \{ nazwa: '([^']*)', skladka: \{ ([^}]*) \} \}", blok(src, 'export const KATEGORIE', '\n};')):
        kat.append({'klucz': k, 'nazwa': n, 'skladka': {a: int(b) for a, b in re.findall(r'(\d+): (\d+)', s)}})
    para = r"\{ key: '([^']+)', nazwa: '([^']*)' \}"
    pyt = blok(src, 'export const APK_PYTANIA', '} as const;')
    return {
        'program': crm_tekst.ts_stala(src, 'PROGRAM_NR'),
        'sumy': [int(x) for x in re.findall(r'\d+', re.search(r'export const SUMY: Suma\[\] = \[([^\]]*)\]', src).group(1))],
        'kategorie': kat,
        'doplata_6_8_osob': crm_tekst.ts_stala(src, 'DOPLATA_6_8_OSOB'),
        'op_skladka': crm_tekst.ts_stala(src, 'OCHRONA_PRAWNA_SKLADKA'),
        'op_limit': crm_tekst.ts_stala(src, 'OCHRONA_PRAWNA_LIMIT'),
        'rodzaje_gabinetu': [{'klucz': k, 'nazwa': n} for k, n in re.findall(para, blok(src, 'export const RODZAJE_GABINETU', '];'))],
        'liczba_osob': [{'klucz': k, 'nazwa': n} for k, n in re.findall(para, blok(src, 'export const LICZBA_OSOB', '];'))],
        'pytania': {k: re.search(k + r": '([^']*)'", pyt).group(1) for k in ('rodzaje', 'osoby')},
        'ankieta': crm_tekst.ts_lista(src, 'ZABIEGI_ANKIETA'),
        'ankieta_dawne': crm_tekst.ts_slownik_napisow(src, 'ZABIEGI_ANKIETA_DAWNE'),
        'najczesciej': crm_tekst.ts_stala(src, 'SUMA_NAJCZESCIEJ_WYBIERANA'),
    }


def tekst_komponentu(crm, plik):
    """Tekst komponentu Svelte bez znaczników HTML, z białymi znakami złączonymi."""
    s = crm_tekst.czytaj(crm, KOMPONENTY + plik)
    return crm_tekst.bez_bialych(re.sub(r'<[^>]+>', ' ', s)).replace(' .', '.').replace('( ', '(').replace(' )', ')')


# --- niezależna implementacja reguł CRM (Decimal) ---
def kategoria(rodzaje):
    """= kategoriaZRodzajow w CRM (stan sprzed D45)."""
    if not rodzaje:
        return None
    r = set(rodzaje)
    l2 = 'kosmetologiczny' in r or 'tatuaz' in r
    if 'podologiczny' in r or (l2 and 'fryzjerski' in r):
        return 'pelny'
    return 'kosmetologiczny' if l2 else 'kosmetyczny_fryzjerski'


# --- reguła kategorii portalu (decyzja zleceniodawcy D45, 16.11.2026) – niezależnie od oc-skladka.js i oc_taryfa.py ---
def kategoria_d45(rodzaje):
    """Rodzaj z listy nr 1 (kosmetyczny, fryzjerski, masaż) razem z rodzajem z listy nr 2 (kosmetologiczny, tatuaż) – pełna;
    podologia zawsze pełna; same rodzaje z listy nr 2 – kosmetologiczna; same z listy nr 1 – kosmetyczna i fryzjerska."""
    if not rodzaje:
        return None
    r = set(rodzaje)
    l1 = bool(r & {'kosmetyczny', 'fryzjerski', 'masaz'})
    l2 = bool(r & {'kosmetologiczny', 'tatuaz'})
    if 'podologiczny' in r or (l1 and l2):
        return 'pelny'
    return 'kosmetologiczny' if l2 else 'kosmetyczny_fryzjerski'


def ODSTEPSTWO_D45(rodzaje):
    """Połączenia rodzajów, w których portal (D45) i CRM (kategoriaZRodzajow) celowo dają różne kategorie – zapisane słowami
    decyzji, nie jako różnica dwóch funkcji (main() sprawdza, że to dokładnie te same połączenia)."""
    r = set(rodzaje)
    return ('fryzjerski' not in r and 'podologiczny' not in r and bool(r & {'kosmetyczny', 'masaz'})
            and bool(r & {'kosmetologiczny', 'tatuaz'}))


def format_suma(s):
    return '{:,}'.format(s).replace(',', '.') + ' zł'


def format_zl(k):
    zl, gr = divmod(int(k * 100), 100)
    calosc = str(zl) if zl < 10000 else '{:,}'.format(zl).replace(',', ' ')  # pl-PL: grupowanie od 5 cyfr
    return '%s,%02d zł' % (calosc, gr)


def wycena_crm(C, rodzaje, osoby, suma, op, ankieta, regula=kategoria):
    """= wycenaNowej + skladkaProgramu na stałych z CRM; None – CRM nie wycenia (brak sumy). regula=kategoria_d45 – ta sama
    wycena z kategorią portalu (D45)."""
    if not suma:
        return None
    if ankieta:
        return {'stan': 'indywidualna', 'powod': 'zabiegi wymagające ankiety podlegają ocenie ubezpieczyciela'}
    k = regula(rodzaje)
    if not k or not osoby:
        return {'stan': 'indywidualna', 'powod': 'brak danych do wyceny'}
    if osoby == '9+':
        return {'stan': 'indywidualna', 'powod': 'gabinet zatrudnia więcej niż 8 osób'}
    kat = next(x for x in C['kategorie'] if x['klucz'] == k)
    baza = Decimal(kat['skladka'][str(suma)])
    z = baza * (1 + Decimal(str(C['doplata_6_8_osob']))) if osoby == '6-8' else baza
    kwota = (z + (Decimal(C['op_skladka']) if op else 0)).quantize(Decimal('0.01'), ROUND_HALF_UP)
    czesci = ['%s, suma %s: %s zł' % (kat['nazwa'], format_suma(suma), baza)]
    if osoby == '6-8':
        czesci.append('+25% (6–8 osób)')
    if op:
        czesci.append('+%d zł ochrona prawna' % C['op_skladka'])
    return {'stan': 'kwota', 'kategoria': k, 'nazwa': kat['nazwa'], 'kwota': kwota, 'tekst_crm': format_zl(kwota),
            'opis_crm': ', '.join(czesci)}


def main(argv):
    crm = crm_tekst.katalog_crm(argv)
    if not (crm / crm_tekst.PROGRAM).is_file():
        print('BRAK CRM: %s – podaj --crm KATALOG albo CRMAURA_DIR' % (crm / crm_tekst.PROGRAM))
        return 2
    src = crm_tekst.czytaj(crm)
    C = stale_crm(src)
    T = json.loads(TARYFA.read_text(encoding='utf-8'))
    F = json.loads(FIXTURE.read_text(encoding='utf-8'))

    # 1. Stałe
    rowne('program', T['program'], C['program'])
    rowne('sumy', T['sumy'], C['sumy'])
    rowne('kategorie', T['kategorie'], C['kategorie'])
    rowne('doplata_6_8_osob', T['doplata_6_8_osob'], C['doplata_6_8_osob'])
    rowne('ochrona_prawna.skladka', T['ochrona_prawna']['skladka'], C['op_skladka'])
    rowne('ochrona_prawna.limit', T['ochrona_prawna']['limit'], C['op_limit'])
    rowne('rodzaje_gabinetu', T['rodzaje_gabinetu'], C['rodzaje_gabinetu'])
    rowne('liczba_osob', T['liczba_osob'], C['liczba_osob'])
    rowne('pytania.rodzaje', T['pytania']['rodzaje'], C['pytania']['rodzaje'])
    rowne('pytania.osoby', T['pytania']['osoby'], C['pytania']['osoby'])
    apk = tekst_komponentu(crm, 'KrokApk.svelte')
    if '(%s)' % T['pytania']['rodzaje_podpowiedz'] not in apk:
        bledy.append('pytania.rodzaje_podpowiedz: brak „(%s)” w KrokApk.svelte' % T['pytania']['rodzaje_podpowiedz'])

    # 2. Reguła i teksty
    for nazwa, wzor in WZORZEC.items():
        if nazwa == 'formaty':
            m = re.search(r'export const formatSuma = .*?;\nexport const formatZl = .*?;', src, re.S)
            kod = m.group(0) if m else ''
        else:
            kod = crm_tekst.ts_funkcja(src, nazwa)
        if crm_tekst.bez_bialych(kod) != crm_tekst.bez_bialych(wzor):
            bledy.append('%s: kod CRM ≠ wzorzec – przejrzyj oc-skladka.js i zaktualizuj WZORZEC%s' % (nazwa, (
                ' (jeśli CRM wdrożył regułę D45 – usuń oznaczenia odstepstwo_D45 z fixture i wyjątek D45 z tego skryptu)'
                if nazwa == 'kategoriaZRodzajow' else '')))
    for klucz, fn in (('ankieta', 'wycenaNowej'), ('osoby', 'skladkaProgramu')):
        if "powod: '%s'" % T['powody_wyceny_indywidualnej'][klucz] not in crm_tekst.ts_funkcja(src, fn):
            bledy.append('powody_wyceny_indywidualnej.%s: nie ma go w %s' % (klucz, fn))
    kb = T['komunikaty_brakow']
    for klucz in ('rodzaje', 'osoby'):
        if "bledy.push('%s')" % kb[klucz] not in crm_tekst.ts_funkcja(src, 'waliduj_apk'):
            bledy.append('komunikaty_brakow.%s: nie ma go w waliduj_apk' % klucz)
    if "'%s'" % kb['ankieta_bez_pozycji'] not in crm_tekst.czytaj(crm, KOMPONENTY + 'stan.svelte.ts'):
        bledy.append('komunikaty_brakow.ankieta_bez_pozycji: nie ma go w stan.svelte.ts')
    nowy = tekst_komponentu(crm, 'KrokWniosekNowy.svelte')
    if kb['suma'].replace('zobaczyć składkę', 'zobaczyć orientacyjną składkę') not in nowy:
        bledy.append('komunikaty_brakow.suma: w KrokWniosekNowy.svelte nie ma odpowiednika (CRM ze słowem o niepewności kwoty)')
    tc = T['teksty_crm']
    if tc['zabiegi_z_innej_listy']['tekst'] not in tekst_komponentu(crm, 'KrokWniosek.svelte'):
        bledy.append('teksty_crm.zabiegi_z_innej_listy: zdania nie ma dosłownie w KrokWniosek.svelte')
    kw = tekst_komponentu(crm, 'KrokKwalifikacje.svelte')
    for i, t in enumerate(tc['dokumenty_przy_zabiegach_z_ankiety']['pozycje'], 1):
        if t not in kw:
            bledy.append('teksty_crm.dokumenty_przy_zabiegach_z_ankiety[%d]: nie ma dosłownie w KrokKwalifikacje.svelte' % i)

    # 3. Fixture – niezależne przeliczenie; 4. odstępstwo D45 (różnica z CRM tylko w połączeniach D45 i z oznaczeniem)
    klucze = [r['klucz'] for r in C['rodzaje_gabinetu']]
    wszystkie = [[r for i, r in enumerate(klucze) if m >> i & 1] for m in range(1, 1 << len(klucze))]
    rozne = [r for r in wszystkie if kategoria(r) != kategoria_d45(r)]
    if sorted(map(sorted, rozne)) != sorted(sorted(r) for r in wszystkie if ODSTEPSTWO_D45(r)) or len(rozne) != 9:
        bledy.append('D45: połączenia z różną kategorią CRM/portal (%d) ≠ ODSTEPSTWO_D45 (9)' % len(rozne))
    odstepstwa = []
    porownane = portal = 0
    for p in F['przypadki']:
        for n in p['zabiegi_ankieta']:
            if n not in C['ankieta']:
                bledy.append('%s: „%s” spoza ZABIEGI_ANKIETA (CRM odrzuci bez komunikatu)' % (p['id'], n))
        w = wycena_crm(C, p['rodzaje'], p['osoby'], p['suma'], p['ochrona_prawna'], p['zabiegi_ankieta'])
        o, od = p['oczekiwane'], p.get('odstepstwo_D45')
        if p['tylko_portal']:
            portal += 1
            if w is not None and w.get('powod') != 'brak danych do wyceny':
                bledy.append('%s: oznaczony tylko_portal, a CRM go wycenia (%s) – porównaj z CRM' % (p['id'], w))
            if od:
                bledy.append('%s: odstepstwo_D45 przy przypadku tylko_portal' % p['id'])
            continue
        porownane += 1
        # wynik portalu: ta sama wycena z kategorią D45 – różni się od CRM tylko w połączeniach D45
        wp = wycena_crm(C, p['rodzaje'], p['osoby'], p['suma'], p['ochrona_prawna'], p['zabiegi_ankieta'], kategoria_d45)
        rozni = w is not None and wp is not None and w != wp
        if rozni and not ODSTEPSTWO_D45(p['rodzaje']):
            bledy.append('%s: portal ≠ CRM poza połączeniami D45 (%s)' % (p['id'], '+'.join(p['rodzaje'])))
        if bool(od) != rozni:
            bledy.append('%s: %s' % (p['id'], 'odstepstwo_D45 bez różnicy z CRM' if od else
                                     'różnica z CRM (D45) bez oznaczenia odstepstwo_D45'))
        if wp is None or wp['stan'] != o['stan']:
            bledy.append('%s: stan %s ≠ CRM %s' % (p['id'], o['stan'], wp and wp['stan']))
            continue
        if o['stan'] == 'kwota':
            for pole in ('kategoria', 'nazwa', 'tekst_crm', 'opis_crm'):
                rowne('%s %s' % (p['id'], pole), o[pole], wp[pole])
            rowne('%s kwota' % p['id'], Decimal(str(o['kwota'])), wp['kwota'])
        else:
            rowne('%s powód' % p['id'], o['powod'], wp['powod'])
        if od and rozni:
            # treść oznaczenia = wynik CRM dosłownie; kwota portalu = oczekiwane
            for pole, crm_pole in (('kategoria_crm', 'kategoria'), ('nazwa_crm', 'nazwa'), ('tekst_crm', 'tekst_crm'),
                                   ('opis_crm', 'opis_crm')):
                rowne('%s odstepstwo_D45.%s' % (p['id'], pole), od.get(pole), w[crm_pole])
            rowne('%s odstepstwo_D45.kwota_crm' % p['id'], Decimal(str(od.get('kwota_crm'))), w['kwota'])
            rowne('%s odstepstwo_D45.kwota_portalu' % p['id'], Decimal(str(od.get('kwota_portalu'))), wp['kwota'])
            odstepstwa.append('%s %s, %s, suma %s%s: portal %s („%s”), CRM %s („%s”)' % (
                p['id'], ' + '.join(p['rodzaje']), p['osoby'], format_suma(p['suma']), ', ochrona prawna' if p['ochrona_prawna'] else '',
                wp['tekst_crm'], wp['nazwa'], w['tekst_crm'], w['nazwa']))
    maski = set()
    komb_d45 = []
    for k in F['kombinacje_rodzajow']:
        opis = '+'.join(k['rodzaje']) or '—'
        kc, kp, od = kategoria(k['rodzaje']), kategoria_d45(k['rodzaje']), k.get('odstepstwo_D45')
        rowne('kombinacja %s (D45)' % opis, k['kategoria'], kp)
        if kc != kp:
            if not (od and ODSTEPSTWO_D45(k['rodzaje'])):
                bledy.append('kombinacja %s: portal %s ≠ CRM %s bez oznaczenia odstepstwo_D45' % (opis, kp, kc))
            else:
                rowne('kombinacja %s odstepstwo_D45.kategoria_crm' % opis, od.get('kategoria_crm'), kc)
                komb_d45.append('%s (CRM %s → portal %s)' % (' + '.join(k['rodzaje']), kc, kp))
        elif od:
            bledy.append('kombinacja %s: odstepstwo_D45 bez różnicy z CRM' % opis)
        maski.add(tuple(r in k['rodzaje'] for r in klucze))
    rowne('kombinacje: różne podzbiory 6 rodzajów', len(maski), 64)
    rowne('kombinacje z odstepstwo_D45', len(komb_d45), 9)
    warianty = set()
    for k in F['kwoty_taryfy']:
        rod = {'kosmetyczny_fryzjerski': ['kosmetyczny'], 'kosmetologiczny': ['kosmetologiczny'], 'pelny': ['podologiczny']}[k['kategoria']]
        w = wycena_crm(C, rod, k['osoby'], k['suma'], k['ochrona_prawna'], [])
        rowne('kwota %s/%s/%s/%s' % (k['kategoria'], k['suma'], k['osoby'], k['ochrona_prawna']), Decimal(str(k['kwota'])), w['kwota'])
        warianty.add((k['kategoria'], k['suma'], k['osoby'], k['ochrona_prawna']))
    rowne('kwoty: różne warianty', len(warianty), 36)

    info.append('celowe różnice portalu: brak wyróżnionej sumy (CRM: SUMA_NAJCZESCIEJ_WYBIERANA = %d); kwota z groszami '
                'w typografii portalu (CRM: formatZl); sumy „200 tys. zł” (CRM: formatSuma „200.000 zł”); stany braków '
                'danych tylko w portalu (przypadków tylko_portal: %d); kategoria taryfy według decyzji D45 – %d połączeń '
                'rodzajów, CRM do zmiany (docs/koncepcja/do-crm/2026-11-16-D45-kategoria-taryfy-oc.md)'
                % (C['najczesciej'], portal, len(komb_d45)))
    print('\n'.join('BŁĄD: ' + b for b in bledy) or 'OK')
    print('przypadki porównane z CRM: %d (w tym z odstępstwem D45: %d; tylko portal: %d); kombinacje: %d (odstępstwo D45: %d); '
          'kwoty: %d; ankieta w CRM: %d pozycji' % (porownane, len(odstepstwa), portal, len(F['kombinacje_rodzajow']),
                                                     len(komb_d45), len(F['kwoty_taryfy']), len(C['ankieta'])))
    print('\n'.join('ODSTĘPSTWO D45 (przypadek): ' + x for x in odstepstwa))
    print('\n'.join('ODSTĘPSTWO D45 (kombinacja): ' + x for x in komb_d45))
    print('\n'.join('INFO: ' + i for i in info))
    return 1 if bledy else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
