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
     z ankiety w fixture = ZABIEGI_ANKIETA (CRM bez komunikatu odrzuca inne).
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

# Wzorzec kodu CRM (commit e01fbfb, 11.11.2026), porównywany po złączeniu białych znaków.
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
    if not rodzaje:
        return None
    r = set(rodzaje)
    l2 = 'kosmetologiczny' in r or 'tatuaz' in r
    if 'podologiczny' in r or (l2 and 'fryzjerski' in r):
        return 'pelny'
    return 'kosmetologiczny' if l2 else 'kosmetyczny_fryzjerski'


def format_suma(s):
    return '{:,}'.format(s).replace(',', '.') + ' zł'


def format_zl(k):
    zl, gr = divmod(int(k * 100), 100)
    calosc = str(zl) if zl < 10000 else '{:,}'.format(zl).replace(',', ' ')  # pl-PL: grupowanie od 5 cyfr
    return '%s,%02d zł' % (calosc, gr)


def wycena_crm(C, rodzaje, osoby, suma, op, ankieta):
    """= wycenaNowej + skladkaProgramu na stałych z CRM; None – CRM nie wycenia (brak sumy)."""
    if not suma:
        return None
    if ankieta:
        return {'stan': 'indywidualna', 'powod': 'zabiegi wymagające ankiety podlegają ocenie ubezpieczyciela'}
    k = kategoria(rodzaje)
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
            bledy.append('%s: kod CRM ≠ wzorzec – przejrzyj oc-skladka.js i zaktualizuj WZORZEC' % nazwa)
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

    # 3. Fixture – niezależne przeliczenie
    porownane = portal = 0
    for p in F['przypadki']:
        for n in p['zabiegi_ankieta']:
            if n not in C['ankieta']:
                bledy.append('%s: „%s” spoza ZABIEGI_ANKIETA (CRM odrzuci bez komunikatu)' % (p['id'], n))
        w = wycena_crm(C, p['rodzaje'], p['osoby'], p['suma'], p['ochrona_prawna'], p['zabiegi_ankieta'])
        o = p['oczekiwane']
        if p['tylko_portal']:
            portal += 1
            if w is not None and w.get('powod') != 'brak danych do wyceny':
                bledy.append('%s: oznaczony tylko_portal, a CRM go wycenia (%s) – porównaj z CRM' % (p['id'], w))
            continue
        porownane += 1
        if w is None or w['stan'] != o['stan']:
            bledy.append('%s: stan %s ≠ CRM %s' % (p['id'], o['stan'], w and w['stan']))
            continue
        if o['stan'] == 'kwota':
            for pole in ('kategoria', 'nazwa', 'tekst_crm', 'opis_crm'):
                rowne('%s %s' % (p['id'], pole), o[pole], w[pole])
            rowne('%s kwota' % p['id'], Decimal(str(o['kwota'])), w['kwota'])
        else:
            rowne('%s powód' % p['id'], o['powod'], w['powod'])
    klucze = [r['klucz'] for r in C['rodzaje_gabinetu']]
    maski = set()
    for k in F['kombinacje_rodzajow']:
        rowne('kombinacja %s' % ('+'.join(k['rodzaje']) or '—'), k['kategoria'], kategoria(k['rodzaje']))
        maski.add(tuple(r in k['rodzaje'] for r in klucze))
    rowne('kombinacje: różne podzbiory 6 rodzajów', len(maski), 64)
    warianty = set()
    for k in F['kwoty_taryfy']:
        rod = {'kosmetyczny_fryzjerski': ['kosmetyczny'], 'kosmetologiczny': ['kosmetologiczny'], 'pelny': ['podologiczny']}[k['kategoria']]
        w = wycena_crm(C, rod, k['osoby'], k['suma'], k['ochrona_prawna'], [])
        rowne('kwota %s/%s/%s/%s' % (k['kategoria'], k['suma'], k['osoby'], k['ochrona_prawna']), Decimal(str(k['kwota'])), w['kwota'])
        warianty.add((k['kategoria'], k['suma'], k['osoby'], k['ochrona_prawna']))
    rowne('kwoty: różne warianty', len(warianty), 36)

    info.append('celowe różnice portalu: brak wyróżnionej sumy (CRM: SUMA_NAJCZESCIEJ_WYBIERANA = %d); kwota z groszami '
                'w typografii portalu (CRM: formatZl); sumy „200 tys. zł” (CRM: formatSuma „200.000 zł”); stany braków '
                'danych tylko w portalu (przypadków tylko_portal: %d)' % (C['najczesciej'], portal))
    print('\n'.join('BŁĄD: ' + b for b in bledy) or 'OK')
    print('przypadki porównane z CRM: %d (tylko portal: %d); kombinacje: %d; kwoty: %d; ankieta w CRM: %d pozycji'
          % (porownane, portal, len(F['kombinacje_rodzajow']), len(F['kwoty_taryfy']), len(C['ankieta'])))
    print('\n'.join('INFO: ' + i for i in info))
    return 1 if bledy else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
