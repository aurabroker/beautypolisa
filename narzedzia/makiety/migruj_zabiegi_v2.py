#!/usr/bin/env python3
"""Jednorazowa migracja listy zabiegów OC do wersji 2 (Aneks nr 5): buduje snippets/zabiegi-oc-beauty.json (v2)
i archiwum snippets/zabiegi-oc-beauty-wycofane.json z:
  * wersji 1 pliku (117 pozycji, grupy 1–4) – domyślnie z gita (commit V1_REF), bo wynik nadpisuje plik;
  * PDF list nr 1 i 2 w design/v3/dokumenty/oc-beauty (pdftotext -raw) – brzmienie, kolejność, numery, nagłówki;
  * CRM (crmaura/src/lib/renewals/program.ts, czytany jako tekst) – pozycje ankiety a–h (ZABIEGI_ANKIETA),
    ich dawne brzmienia (ZABIEGI_ANKIETA_DAWNE) i podstawa brzmienia (ZABIEGI_ANKIETA_PODSTAWA).

Reguły (plan „OC beauty po Aneksie nr 5”, 1.3; logika jak scratchpad oc-aneks5/mapa_id.py):
  1. id zostaje, gdy rekord v1 ma tę samą pozycję na liście z Aneksu nr 5 – dosłownie (bez wielkości liter) albo jako
     zmienione brzmienie tej samej pozycji (ZMIANY_BRZMIENIA, za docs/koncepcja/13-przeniesienie-formularzy/
     dokumenty-produktowe.md, tabela zmian brzmienia); ankieta – po brzmieniu z ankiety ERGO Hestii w v1
     (nazwa_w_ankiecie_ergo) = obecne albo dawne brzmienie z CRM;
  2. nowe pozycje – prefiks listy pierwszego wystąpienia i kolejny wolny numer (g1-41…, g2-39…), bez wypełniania luk;
  3. gr. 3 (podologia) – do archiwum wycofanych (decyzja Q1: lista podologiczna tylko w dokumentach programu);
  4. pozycje o podobnych, ale różnych nazwach na obu listach to osobne rekordy (lista 1:1).

Uruchom:  python3 -I narzedzia/makiety/migruj_zabiegi_v2.py [--check] [--v1 PLIK|git:REF] [--crm KATALOG]
--check: nic nie zapisuje; kod 1, gdy pliki w snippets/ różnią się od wyniku migracji.
"""
import collections, json, pathlib, subprocess, sys
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))  # python3 -I nie dodaje katalogu skryptu
import crm_tekst
import zabiegi_model as zm

V1_REF = '687654f'   # ostatni commit z wersją 1 listy (117 pozycji)
V1_PLIK = 'docs/koncepcja/snippets/zabiegi-oc-beauty.json'
DOK = 'dokumenty/oc-beauty/'
PDF = {'lista-1': DOK + 'lista-zabiegow-nr-1-kosmetyczne-fryzjerskie-aneks-5.pdf',
       'lista-2': DOK + 'lista-zabiegow-nr-2-kosmetyczne-kosmetologiczne-aneks-5.pdf'}

# Zmienione brzmienie tej samej pozycji (id v1 → brzmienie z PDF Aneksu nr 5; dokumenty-produktowe.md, tabela zmian).
ZMIANY_BRZMIENIA = {
    'g1-13': 'Kuracje nawilżające, regenerujące i odbudowujące włosy',
    'g1-21': 'Masaż manualny ciała, w tym masaż głowy i twarzy',
    'g1-26': 'Piercing – przekłuwanie innych części ciała',
    'g1-34': 'Strzyżenie nożyczkami, maszynką, brzytwą oraz metodą Split-ender i Hair-dusting; trymowanie',
    'g1-36': 'Wykonywanie zabiegów kosmetycznych z zastosowaniem składników aktywnych',
    'g1-39': 'Zabiegi wykorzystujące terapeutyczne działanie światła – światło LED i jego pochodnych',
    'g2-25': 'Pedicure kosmetyczny w zakresie zabiegów niezastrzeżonych dla podologów',
    'g2-33': 'Zabiegi z zastosowaniem fali radiowej',
    'g2-34': 'Zabiegi wykorzystujące światło IPL: fotoodmładzanie, likwidowanie przebarwień, terapia trądziku, '
             'zamykanie naczyń – teleangiektazje, usuwanie zbędnego owłosienia',
    'g2-35': 'Zabiegi z zastosowaniem lasera frakcyjnego nieablacyjnego, laser subablacyjny',
    'g2-36': 'Zabiegi z wykorzystaniem laserów nieablacyjnych, w tym laserowe zamykanie naczyń – teleangiektazje, '
             'usuwanie tatuażu i makijażu permanentnego, usuwanie zbędnego owłosienia',
}
# Kontrola krzyżowa z planem (tabela „Ankieta”, 1.3): litera a–h → id v1.
ANKIETA_PLAN = {'a': 'g4-05', 'b': 'g4-07', 'c': 'g4-03', 'd': 'g4-01', 'e': 'g4-04', 'f': 'g4-08', 'g': 'g4-06', 'h': 'g4-02'}
# Liczby z planu (rozdz. 1 i 11, krok 2) – migracja ma je odtworzyć.
OCZEKIWANE = {'lista-1': 49, 'lista-2': 63, 'ankieta': 8, 'wspolne': 20, 'bez_zmian': 66, 'nowe_brzmienie': 12,
              'nowe_id': 14, 'zmiany_slugow': 18, 'wycofane': 31, 'aktywne': 100}

POWOD_WYCOFANIA = ('Lista zabiegów podologicznych nie jest częścią danych portalu – jest w dokumentach programu '
                   '(w CRM tylko odnośnik do dokumentu „Lista zabiegów – podologiczne”); pozycja dawnej listy podologicznej portalu (wersja 1).')

KOMENTARZ = (
    'Listy zabiegów programu OC nr WA50/003353/24/A dla branży beauty – 1:1 ze źródłami: Załącznik nr 1 (49 pozycji) '
    'i Załącznik nr 2 (63 pozycje) w brzmieniu Aneksu nr 5 – PDF w design/v3/dokumenty/oc-beauty, takie same jak '
    'ZABIEGI_LISTA_1 i ZABIEGI_LISTA_2 w CRM; zabiegi wymagające ankiety – 8 pozycji a–h w brzmieniu Aneksu nr 5 '
    'według CRM (ZABIEGI_ANKIETA; dawne brzmienia – ZABIEGI_ANKIETA_DAWNE). Lista zabiegów podologicznych nie jest '
    'częścią danych – jest w dokumentach programu; 31 dawnych pozycji podologicznych (g3-01…g3-31): zabiegi-oc-beauty-wycofane.json. '
    'Zabieg jest jednym rekordem, gdy ma na obu listach to samo brzmienie bez rozróżniania wielkości liter (jak '
    'ZABIEGI_LISTY w CRM); pozycje[].nazwa tylko przy innej wielkości liter na danej liście. Kolejność i numery pozycji '
    '– z PDF; ankieta – litery a–h (jedyna mapa litera ↔ id ↔ nazwa). Składka nie zależy od zabiegów – taryfa: '
    'taryfa-oc-beauty.json. Pola id, slug i dawne_slugi są techniczne: id stałe i nieużywane ponownie (prefiks g1–g4 '
    'jest historyczny, nie oznacza listy), dawne_slugi – kotwice sprzed wersji 2. Zbudowane przez '
    'narzedzia/makiety/migruj_zabiegi_v2.py z wersji 1, PDF i CRM; walidacja: zabiegi_model.py, zgodność z PDF i CRM: '
    'check_zabiegi_pdf.py. Zakres i wyłączenia określają warunki ubezpieczenia programu.')
KOMENTARZ_WYC = (
    'Archiwum pozycji usuniętych z listy zabiegów OC (zabiegi-oc-beauty.json). Pozycja wycofana zostaje dozwolona '
    'tylko w ogłoszeniach, które już ją mają (zabiegi_ids() – lista wycofanych; strefa klienta 11.10): strona pokazuje '
    'nazwę z dopiskiem o wycofaniu, nie można jej dodać do nowego ogłoszenia, filtr ze starym adresem działa. '
    'Id nie wraca do użycia; slug – alias kotwicy sekcji #podologia na stronie OC. wersja_listy – ostatnia wersja '
    'listy z tą pozycją; wycofano_w_wersji – wersja listy bez niej. Zbudowane przez narzedzia/makiety/migruj_zabiegi_v2.py.')


def wczytaj_v1(argv):
    zrodlo = argv[argv.index('--v1') + 1] if '--v1' in argv else 'git:' + V1_REF
    if zrodlo.startswith('git:'):
        txt = subprocess.run(['git', '-C', str(zm.REPO), 'show', '%s:%s' % (zrodlo[4:], V1_PLIK)],
                             check=True, capture_output=True, text=True).stdout
    else:
        txt = open(zrodlo, encoding='utf-8').read()
    J = json.loads(txt)
    assert 'grupy' in J and len(J['zabiegi']) == 117, 'to nie jest wersja 1 listy (117 pozycji)'
    return J


def migruj(V1, crm):
    src = crm_tekst.czytaj(crm)
    ANK = crm_tekst.ts_lista(src, 'ZABIEGI_ANKIETA')
    DAWNE = crm_tekst.ts_slownik_napisow(src, 'ZABIEGI_ANKIETA_DAWNE')
    PODSTAWA = crm_tekst.ts_stala(src, 'ZABIEGI_ANKIETA_PODSTAWA')

    naglowki, pozycje = {}, {}
    for k, p in PDF.items():
        zal, naz, poz = zm.pdf_lista(zm.V3 / p)
        assert [n for n, _ in poz] == list(range(1, len(poz) + 1)), (k, 'numeracja PDF')
        naglowki[k], pozycje[k] = (zal, naz), [n for _, n in poz]

    # Rekordy list nr 1 i 2: klucz = brzmienie małymi literami (wspólne tylko przy identycznym brzmieniu).
    rek, kolej = {}, []
    for k in ('lista-1', 'lista-2'):
        for nr, n in enumerate(pozycje[k], 1):
            kl = n.lower()
            if kl not in rek:
                rek[kl] = {'pozycje': [], 'id': None, 'v1': None}
                kolej.append(kl)
            rek[kl]['pozycje'].append((k, nr, n))

    v1 = {z['id']: z for z in V1['zabiegi']}
    for z in V1['zabiegi']:
        if z['grupa'] not in (1, 2):
            continue
        kl = z['nazwa'].lower() if z['nazwa'].lower() in rek else ZMIANY_BRZMIENIA.get(z['id'], '\0').lower()
        assert kl in rek, ('rekord v1 bez pozycji w Aneksie nr 5', z['id'], z['nazwa'])
        assert rek[kl]['id'] is None, ('dwa rekordy v1 na jedną pozycję', z['id'], rek[kl]['id'])
        rek[kl]['id'], rek[kl]['v1'] = z['id'], z
    nast = {p: max(int(i[3:]) for i in v1 if i.startswith(p)) + 1 for p in ('g1-', 'g2-')}
    for kl in kolej:
        r = rek[kl]
        if r['id'] is None:
            p = 'g1-' if r['pozycje'][0][0] == 'lista-1' else 'g2-'
            r['id'] = '%s%02d' % (p, nast[p])
            nast[p] += 1

    zabiegi, stat = [], collections.Counter()
    for kl in kolej:
        r = rek[kl]
        nazwa = r['pozycje'][0][2]
        z = {'id': r['id'], 'slug': zm.slug(nazwa), 'nazwa': nazwa,
             'pozycje': [dict({'lista': k, 'nr': nr}, **({'nazwa': n} if n != nazwa else {})) for k, nr, n in r['pozycje']]}
        stary = r['v1']
        if stary and stary['slug'] != z['slug']:
            z['dawne_slugi'] = [stary['slug']]
        stat['bez_zmian' if stary and stary['nazwa'] == nazwa and stary['slug'] == z['slug']
             else 'nowe_brzmienie' if stary else 'nowe_id'] += 1
        zabiegi.append(z)

    # Ankieta a–h: rekord v1 grupy 4 po brzmieniu z ankiety ERGO Hestii (obecne albo dawne brzmienie w CRM).
    dawne_do = collections.defaultdict(list)
    for d, n in DAWNE.items():
        dawne_do[n].append(d)
    g4 = [z for z in V1['zabiegi'] if z['grupa'] == 4]
    for i, nazwa in enumerate(ANK):
        lit = zm.LITERY[i]
        trafione = [z for z in g4 if z['nazwa_w_ankiecie_ergo'].lower() in {nazwa.lower()} | {d.lower() for d in dawne_do[nazwa]}]
        assert len(trafione) == 1, ('ankieta', lit, nazwa, [z['id'] for z in trafione])
        stary = trafione[0]
        assert stary['id'] == ANKIETA_PLAN[lit], ('ankieta: mapa ≠ plan', lit, stary['id'])
        z = {'id': stary['id'], 'slug': zm.slug(nazwa), 'nazwa': nazwa, 'pozycje': [{'lista': 'ankieta', 'nr': lit}]}
        if stary['slug'] != z['slug']:
            z['dawne_slugi'] = [stary['slug']]
        if dawne_do[nazwa]:
            z['dawne_nazwy'] = dawne_do[nazwa]
        zabiegi.append(z)
    assert len(ANK) == len(g4) and len({z['id'] for z in zabiegi}) == len(zabiegi)

    listy = [
        {'klucz': k, 'numer': i, 'zalacznik': naglowki[k][0], 'nazwa': naglowki[k][1], 'liczba_pozycji': len(pozycje[k]),
         'kotwica': k, 'dawne_kotwice': ['grupa-%d' % i], 'dokument': PDF[k]}
        for i, k in ((1, 'lista-1'), (2, 'lista-2'))
    ] + [
        {'klucz': 'ankieta', 'nazwa': 'Zabiegi wymagające ankiety ERGO Hestii',
         'zrodlo': 'brzmienie Aneksu nr 5 według CRM (ZABIEGI_ANKIETA)', 'liczba_pozycji': len(ANK),
         'kotwica': 'ankieta', 'dawne_kotwice': ['grupa-4'], 'numeracja': 'litery'},
        {'klucz': 'podologia', 'nazwa': 'Lista zabiegów – podologiczne',
         'zrodlo': 'dokumenty programu (w CRM tylko odnośnik do dokumentu, bez listy pozycji)', 'liczba_pozycji': None,
         'kotwica': 'podologia', 'dawne_kotwice': ['grupa-3'], 'dokument': None},
    ]
    J2 = {'$comment': KOMENTARZ, 'wersja': 2, 'program': V1['program'], 'podstawa': PODSTAWA,
          'listy': listy, 'zabiegi': zabiegi}
    W = {'$comment': KOMENTARZ_WYC,
         'wycofane': [{'id': z['id'], 'slug': z['slug'], 'nazwa': z['nazwa'], 'wersja_listy': 1, 'wycofano_w_wersji': 2,
                       'powod': POWOD_WYCOFANIA} for z in V1['zabiegi'] if z['grupa'] == 3]}

    stat['zmiany_slugow'] = sum(len(z.get('dawne_slugi', [])) for z in zabiegi)
    stat['wycofane'] = len(W['wycofane'])
    stat['aktywne'] = len(zabiegi)
    stat['wspolne'] = sum(1 for z in zabiegi if len(z['pozycje']) == 2)
    for k in ('lista-1', 'lista-2', 'ankieta'):
        stat[k] = sum(1 for z in zabiegi for p in z['pozycje'] if p['lista'] == k)
    return J2, W, stat


def main(argv):
    sprawdz = '--check' in argv
    crm = crm_tekst.katalog_crm(argv)
    if not (crm / crm_tekst.PROGRAM).is_file():
        print('BRAK CRM: %s – podaj --crm KATALOG albo CRMAURA_DIR' % (crm / crm_tekst.PROGRAM))
        return 2
    J2, W, stat = migruj(wczytaj_v1(argv), crm)
    e = zm.waliduj(J2, W)
    roznice = {k: (stat.get(k), v) for k, v in OCZEKIWANE.items() if stat.get(k) != v}
    if roznice:
        e.append('liczby ≠ plan: %s' % roznice)
    if e:
        print('\n'.join('BŁĄD: ' + x for x in e))
        return 1
    print('migracja:', dict(sorted(stat.items())))
    wynik = 0
    for sciezka, dane in ((zm.ZAB, J2), (zm.WYC, W)):
        nowy = zm.tekst_json(dane)
        stary = sciezka.read_text(encoding='utf-8') if sciezka.is_file() else None
        if sprawdz:
            print('%s: %s' % (sciezka.name, 'OK' if stary == nowy else 'RÓŻNICA – uruchom bez --check'))
            wynik |= stary != nowy
        elif stary != nowy:
            sciezka.write_text(nowy, encoding='utf-8')
            print('zapisano', sciezka.relative_to(zm.REPO))
        else:
            print('%s: bez zmian' % sciezka.name)
    return 1 if wynik else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
