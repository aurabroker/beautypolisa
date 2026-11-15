#!/usr/bin/env python3
"""Listy zabiegów OC (snippets/zabiegi-oc-beauty.json v2) ↔ PDF programu ↔ CRM. Nic nie zapisuje.

  1. walidacja schematu i archiwum wycofanych (zabiegi_model.waliduj);
  2. PDF list nr 1 i 2 z design/v3/dokumenty/oc-beauty (pdftotext -raw): nagłówki („Załącznik nr …”, „Lista zabiegów – …”)
     = listy[].zalacznik/nazwa, pozycje = pozycje listy w JSON co do znaku i numeru; jedyny znak nieliterowy spoza ASCII
     to półpauza U+2013; sha256 PDF = snippets/dokumenty-produktowe.json;
  3. PDF ankiety (brzmienie sprzed Aneksu nr 5): każda z 8 pozycji = pozycja a–h z JSON albo jej dawne brzmienie
     (bez wielkości liter) – raport, które pozycje PDF ma w dawnym brzmieniu;
  4. CRM (crmaura/src/lib/renewals/program.ts jako tekst): ZABIEGI_LISTA_1/2 = pozycje list, ZABIEGI_ANKIETA = a–h,
     ZABIEGI_ANKIETA_DAWNE = dawne_nazwy, ZABIEGI_ANKIETA_PODSTAWA = podstawa, ZABIEGI_LISTY (suma bez powtórzeń,
     bez wielkości liter) = rekordy list nr 1 i 2. Bez repozytorium CRM ta część jest pominięta (z komunikatem);
     --wymagaj-crm zamienia pominięcie w błąd;
  5. liczby z planu (OCZEKIWANE): 49 / 63 / 8, 20 wspólnych, 100 aktywnych id, 31 wycofanych, 18 aliasów, 5 przyciętych
     slugów (w tym g4-01), g2-14 z „Masaż Kobido” na liście nr 2. Przy nowym aneksie – zaktualizować razem z danymi.

Uruchom: python3 -I narzedzia/makiety/check_zabiegi_pdf.py [--crm KATALOG] [--wymagaj-crm]   (kod 1 przy błędzie)
"""
import hashlib, json, pathlib, re, sys, unicodedata
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))  # python3 -I nie dodaje katalogu skryptu
import crm_tekst
import zabiegi_model as zm

DOKUMENTY = zm.SN / 'dokumenty-produktowe.json'
PDF_ANKIETY = 'dokumenty/oc-beauty/ankieta-oceny-ryzyka-grupa-4-wa50-003353-24-a.pdf'
OCZEKIWANE = {
    'pozycje': {'lista-1': 49, 'lista-2': 63, 'ankieta': 8, 'podologia': 0},
    'wspolne_1_2': 20, 'tylko_lista_1': 29, 'tylko_lista_2': 43, 'aktywne_id': 100, 'wycofane_id': 31,
    'aliasy_slugow': 18, 'przyciete_slugi': ['g1-34', 'g1-39', 'g2-34', 'g2-36', 'g4-01'],
}
MYSLNIKI = {'‐', '‑', '‒', '—', '―', '−'}  # wszystko poza „-” i „–” to pomyłka

bledy, info = [], []


def porownaj(opis, jest, ma):
    if jest == ma:
        return
    if isinstance(jest, list) and isinstance(ma, list):
        for i in range(max(len(jest), len(ma))):
            a = jest[i] if i < len(jest) else None
            b = ma[i] if i < len(ma) else None
            if a != b:
                bledy.append('%s, poz. %d: JSON %r ≠ %r' % (opis, i + 1, a, b))
        return
    bledy.append('%s: JSON %r ≠ %r' % (opis, jest, ma))


def nieliterowe(nazwy):
    return sorted({'U+%04X' % ord(c) for n in nazwy for c in n if ord(c) > 127 and not c.isalpha()})


def main(argv):
    J = zm.wczytaj()
    W = zm.wczytaj_wycofane()
    bledy.extend(zm.waliduj(J, W))
    L = zm.listy(J)
    nazwy_json = {k: [n for _, n, _ in zm.pozycje_listy(J, k)] for k in L}

    # 2. PDF list
    dok = {d['sciezka']: d for d in json.loads(DOKUMENTY.read_text(encoding='utf-8'))['dokumenty']}
    for k in ('lista-1', 'lista-2'):
        l = L[k]
        przed = len(bledy)
        sciezka = zm.V3 / l['dokument']
        zal, naz, poz = zm.pdf_lista(sciezka)
        porownaj('%s: nagłówek „Załącznik”' % k, l['zalacznik'], zal)
        porownaj('%s: nazwa listy' % k, l['nazwa'], naz)
        porownaj('%s: numeracja PDF' % k, [n for n, _ in poz], list(range(1, len(poz) + 1)))
        porownaj('%s ↔ PDF' % k, nazwy_json[k], [n for _, n in poz])
        nr_json = [nr for nr, _, _ in zm.pozycje_listy(J, k)]
        porownaj('%s: numery pozycji ↔ PDF' % k, nr_json, [n for n, _ in poz])
        znaki = nieliterowe(n for _, n in poz)
        if znaki != ['U+2013']:
            bledy.append('%s: znaki nieliterowe spoza ASCII w PDF: %s (oczekiwana tylko półpauza U+2013)' % (k, znaki))
        zle = sorted({'U+%04X %s' % (ord(c), unicodedata.name(c)) for n in nazwy_json[k] for c in n if c in MYSLNIKI})
        if zle:
            bledy.append('%s: niedozwolone myślniki w JSON: %s' % (k, zle))
        rel = 'docs/koncepcja/design/v3/' + l['dokument']
        sha = hashlib.sha256(sciezka.read_bytes()).hexdigest()
        if rel not in dok:
            bledy.append('%s: PDF nie ma wpisu w dokumenty-produktowe.json' % k)
        elif dok[rel]['sha256'] != sha:
            bledy.append('%s: sha256 PDF ≠ dokumenty-produktowe.json' % k)
        info.append('%s: PDF %d pozycji – %s' % (k, len(poz), 'nagłówki, brzmienie, numery i sha256 zgodne' if len(bledy) == przed
                                               else 'różnice: %d (BŁĄD wyżej)' % (len(bledy) - przed)))

    # 3. PDF ankiety (sprzed Aneksu nr 5)
    t = zm.pdf_tekst(zm.V3 / PDF_ANKIETY)
    m = re.search(r'zaznaczenie zabiegów.*?:\n(.*?)\nInny', t, re.S)
    pdf_ank = [s.strip() for s in m.group(1).split('\n') if s.strip()] if m else []
    if len(pdf_ank) != 8:
        bledy.append('PDF ankiety: %d pozycji zamiast 8' % len(pdf_ank))
    dawne_w_pdf = []
    mapa = {}
    for a in zm.ankieta(J):
        mapa[a['nazwa'].lower()] = (a['litera'], False)
        for d in a['dawne_nazwy']:
            mapa[d.lower()] = (a['litera'], True)
    trafione = set()
    for s in pdf_ank:
        if s.lower() not in mapa:
            bledy.append('PDF ankiety: pozycja „%s” bez odpowiednika a–h w JSON' % s)
            continue
        lit, dawna = mapa[s.lower()]
        trafione.add(lit)
        if dawna:
            dawne_w_pdf.append(lit)
    if trafione != set('abcdefgh'):
        bledy.append('PDF ankiety: brak odpowiedników pozycji %s' % sorted(set('abcdefgh') - trafione))
    info.append('PDF ankiety (sprzed Aneksu nr 5): 8 pozycji, w dawnym brzmieniu: %s' % ', '.join(sorted(dawne_w_pdf)))

    # 4. CRM
    crm = crm_tekst.katalog_crm(argv)
    if (crm / crm_tekst.PROGRAM).is_file():
        src = crm_tekst.czytaj(crm)
        porownaj('lista-1 ↔ CRM ZABIEGI_LISTA_1', nazwy_json['lista-1'], crm_tekst.ts_lista(src, 'ZABIEGI_LISTA_1'))
        porownaj('lista-2 ↔ CRM ZABIEGI_LISTA_2', nazwy_json['lista-2'], crm_tekst.ts_lista(src, 'ZABIEGI_LISTA_2'))
        porownaj('ankieta ↔ CRM ZABIEGI_ANKIETA', nazwy_json['ankieta'], crm_tekst.ts_lista(src, 'ZABIEGI_ANKIETA'))
        dawne = {d: a['nazwa'] for a in zm.ankieta(J) for d in a['dawne_nazwy']}
        porownaj('dawne_nazwy ↔ CRM ZABIEGI_ANKIETA_DAWNE', dawne, crm_tekst.ts_slownik_napisow(src, 'ZABIEGI_ANKIETA_DAWNE'))
        porownaj('podstawa ↔ CRM ZABIEGI_ANKIETA_PODSTAWA', J['podstawa'], crm_tekst.ts_stala(src, 'ZABIEGI_ANKIETA_PODSTAWA'))
        unia = {n.lower() for k in ('ZABIEGI_LISTA_1', 'ZABIEGI_LISTA_2') for n in crm_tekst.ts_lista(src, k)}
        rek = sum(1 for z in J['zabiegi'] if {p['lista'] for p in z['pozycje']} & {'lista-1', 'lista-2'})
        porownaj('rekordy list nr 1 i 2 ↔ CRM ZABIEGI_LISTY (bez powtórzeń)', rek, len(unia))
        info.append('CRM: listy nr 1 i 2, ankieta a–h, dawne brzmienia i podstawa zgodne (%s)' % crm_tekst.PROGRAM)
    elif '--wymagaj-crm' in argv:
        bledy.append('brak repozytorium CRM: %s' % crm)
    else:
        info.append('CRM: pominięto – brak %s (podaj --crm KATALOG albo CRMAURA_DIR)' % (crm / crm_tekst.PROGRAM))

    # 5. Liczby z planu
    pod = zm.podsumowanie(J, W)
    for k, v in OCZEKIWANE.items():
        if pod[k] != v:
            bledy.append('%s: %r ≠ oczekiwane %r' % (k, pod[k], v))
    g214 = next((z for z in J['zabiegi'] if z['id'] == 'g2-14'), None)
    if not g214 or g214['nazwa'] != 'Masaż kobido' or g214['pozycje'][1:] != [{'lista': 'lista-2', 'nr': 25, 'nazwa': 'Masaż Kobido'}]:
        bledy.append('g2-14: oczekiwane „Masaż kobido” (L1/45) i „Masaż Kobido” (L2/25)')

    print('\n'.join('BŁĄD: ' + b for b in bledy) or 'OK')
    print(json.dumps(pod, ensure_ascii=False))
    print('\n'.join('INFO: ' + i for i in info))
    return 1 if bledy else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
