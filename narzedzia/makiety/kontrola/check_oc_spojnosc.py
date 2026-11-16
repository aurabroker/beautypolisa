#!/usr/bin/env python3
"""Spójność treści OC beauty po Aneksie nr 5 w snippets/ i w dokumentach koncepcji (plan „OC beauty po Aneksie nr 5”,
6.7–6.8, z poprawkami z krytyki K7, K10, K12, K14, K16, K17; decyzje D43 i D45 w 00).

Nic nie zapisuje. Kod wyjścia: 0 – brak trafień i niezgodności, 1 – są, 2 – błąd wejścia (brak pliku, zły JSON).

A. Teksty OC publikowane albo przekazywane dalej (snippets/): faq-oc-beauty.json, schema-faq-oc-beauty.json,
   schema-produkt-oc-beauty.json, taryfa-oc-beauty.json, zabiegi-oc-beauty.json, klauzula-ochrona-prawna.json, oc-skladka.js,
   lead-schema.ts, llms.txt, hasła OC w slownik.json (kategoria „oc” albo treść o OC) – wszystkie frazy z oc_frazy.FRAZY
   (plan 6.8 + K7). Pomijane: pola $comment i do_potwierdzenia (nie trafiają na stronę), dawne_nazwy i dawne_slugi,
   archiwum wycofanych (zabiegi-oc-beauty-wycofane.json) i archiwum propozycji wersji 1 (zabiegi-oc-beauty-propozycje.json).
B. Pozostałe pliki snippets/ (SQL, schema-home.json, dokumenty-produktowe.json, slownik.json – wszystkie hasła) i dokumenty
   koncepcji 00, 02, 04, 05, 06, 10, 11, 12, 13/README, 13/00-braki-i-decyzje, 13/dokumenty-produktowe, 14 (bez historycznych
   01, 03, 07, 09 i bez makiety v2): frazy OC (grupy ryzyka, grupy 1–4, 117 zabiegów, dawne brzmienia ankiety, „zespół od 9”…).
   Słowa ogólne („do potwierdzenia”, „rekomendacji”, „polecania”, „przykładowa”) bywają tu poprawne poza OC (K7) – sprawdzane są
   tylko połączenia ze składką/kwotą/wariantem („składka orientacyjna”, „szacunkowa kwota”, „najczęściej wybierany”,
   „polecany wariant”…; „przykładowe kwoty” w dokumentach to opis makiety – to słowo tylko w punkcie A), tylko we fragmentach
   o OC (KONTEKST_OC) i poza cudzysłowem („…”, "…", `…` – wzmianka o zakazanym słowie to nie jego użycie).
   Wyjątki – stan sprzed Aneksu nr 5 opisany jawnie jako dawny:
     (1) fragment (wiersz tekstu albo ciąg linii komentarza SQL/TS) z odwołaniem do D43 i słowem o dawnym stanie
         (zastąp…, sprzed, dawn…, wycofan…, historyczn…);
     (2) sekcja z linią <!-- oc-spojnosc: historyczne --> pod nagłówkiem – do następnego nagłówka tego samego albo wyższego
         poziomu (przed pierwszym nagłówkiem – cały plik).
   Trafienia w wyjątkach nie są błędami; -v wypisuje je wszystkie.
C. Dane i liczby (źródło: zabiegi-oc-beauty.json, taryfa-oc-beauty.json):
   llms.txt – nazwy list i liczby pozycji (49 / 63 / 8), liczba zabiegów na obu listach, stawki każdej taryfy, opis reguły
   kategorii (oc_taryfa.OPIS_KATEGORII), +92 zł, 25%, zdanie o podologii, „Dla kogo” według decyzji zleceniodawcy z 14.11.2026
   (DLA_KOGO; to samo w tabeli person w 05); schema-faq-oc-beauty.json = FAQ z faq-oc-beauty.json
   (gen_oc_beauty.schema_faq_text) i liczby pozycji;
   schema-produkt-oc-beauty.json – lowPrice / highPrice / offerCount z taryfy; slownik.json – hasła rodzaj-dzialalnosci
   (dawne_id grupa-ryzyka) i lista-zabiegow-programu (liczby), brak hasła grupa-ryzyka i kotwic #grupa-N; lead-schema.ts –
   enumy = klucze CRM z taryfy, sumy, powody wyceny indywidualnej, pola opcjonalne przy wycenie indywidualnej (K10);
   schema.sql i strefa-klienta.sql – klucze w CHECK i wartości domyślne = taryfa, opis migracji (K17); dokument 02 – bloki
   kodu z lead-schema.ts i schema.sql identyczne z plikami; 00 – decyzja D43 (z oznaczeniem zmiany przez D45), decyzja D45
   (reguła kategorii, odstępstwo od kategoriaZRodzajow w CRM) i pytania Q1–Q13 (Q3 rozstrzygnięte); teksty publikowane
   (llms.txt, schema-faq-oc-beauty.json, slownik.json, makieta-v3, oc-beauty, slownik.html, design-preview) – bez opisów
   reguły kategorii sprzed D45, a „gabinet kosmetyczny razem z gabinetem kosmetologicznym” zawsze z taryfą z oc_taryfa.kategoria().
D. Cytaty z CRM: zdanie o zabiegach z innej listy (K12) – tylko pierwsze zdanie CRM (oc_taryfa.zdanie_z_innej_listy()), bez
   końcówki o ekranie CRM; tekst publikowany (llms.txt – wiersze OC, FAQ OC, hasła OC słownika), który mówi, że zabieg nie zmienia
   składki, zawiera też to zdanie (weryfikacja, runda 2); wymagania dokumentów przy zabiegach z ankiety (K16) – bez skrótu „dyplom kosmetologa oraz
   certyfikaty szkoleń” i bez pola {termin}; opis ochrony prawnej (Q8) – „Koszty obrony prawnej, np. w sporze z klientem,
   do 100 000 zł.”.
E. Przykłady zabiegów (K14): w tekstach OC z punktu A (llms.txt – wiersze OC, opisy schema, odpowiedzi FAQPage, hasła OC
   słownika) każdy cytat „…” to dosłowna nazwa pozycji z listy, nazwa listy, taryfy albo rodzaju działalności, pytanie APK,
   zdanie CRM albo wpis z DOZWOLONE_CYTATY.

Uruchomienie: python3 -I narzedzia/makiety/kontrola/check_oc_spojnosc.py [--snippets | --dokumenty] [-v]
"""
import json
import pathlib
import re
import sys

MAKIETY = pathlib.Path(__file__).resolve().parents[1]
REPO = pathlib.Path(__file__).resolve().parents[3]
K = REPO / 'docs/koncepcja'
SN = K / 'snippets'
sys.path.insert(0, str(MAKIETY))

from oc_frazy import FRAZY  # noqa: E402
import oc_taryfa as ot  # noqa: E402

NB = ' '
OGOLNE = {'orientacyjn', 'szacunkow', 'poglądow', 'do potwierdzenia', 'rekomendacj', 'rekomend', 'polecamy', 'polecan',
          'przykładow', 'najlepszy wybór', 'najczęściej wybier'}
FRAZY_OC = [(o, w) for o, w in FRAZY if o not in OGOLNE]
# słowa ogólne w dokumentach – tylko w połączeniu z kwotą, składką, sumą albo wariantem (poza cudzysłowem)
RZECZ = r'(?:składk|kwot|cen[aęy]\b|sum[aęy]\b|wariant|taryf)\w*'
FRAZY_OGOLNE_DOK = [
    ('składka/kwota orientacyjna, szacunkowa, poglądowa', re.compile(
        r'\b%s\s+(?:\w+\s+)?(?:orientacyjn|szacunkow|poglądow)\w*|\b(?:orientacyjn|szacunkow|poglądow)\w*\s+(?:\w+\s+)?%s' % (RZECZ, RZECZ), re.I)),
    ('najczęściej wybierany', re.compile(r'najczęściej wybier', re.I)),
    ('rekomendowany / polecany wariant', re.compile(
        r'(?<!bez )(?<!nie )(?<!żadnych )\b(?:rekomend|polec|najlepsz)\w*\s+(?:\w+\s+)?%s|\b%s\s+(?:\w+\s+)?(?:rekomend|polecan|najlepsz)\w*' % (RZECZ, RZECZ), re.I)),
]
# fragment dotyczy OC (słowa ogólne poza OC – np. NNW, Tax Protect, utrata dochodu – sprawdzają ich własne kontrole)
KONTEKST_OC = re.compile(r'\bOC\b|oc-beauty|ERGO Hesti|zabieg|kalkulator|taryf|składk', re.I)
WYJATEK_D43 = re.compile(r'zast[ąę]p|sprzed|dawn|wycofan|historyczn', re.I)
ZNACZNIK_SEKCJI = '<!-- oc-spojnosc: historyczne -->'
CYTAT = re.compile(r'„[^”\n]*”|"[^"\n]*"|`[^`\n]*`|“[^”\n]*”')

# Decyzja zleceniodawcy z 14.11.2026 (orkiestrator, kroki 5–6): profil „Dla kogo” → rodzaj działalności w kalkulatorze OC.
DLA_KOGO = {
    'kosmetolog': 'Gabinet kosmetologiczny',
    'linergistka': 'Gabinet kosmetologiczny',
    'stylistka-paznokci': 'Gabinet kosmetyczny',
    'fryzjer': 'Salon fryzjerski',
    'podolog': 'Gabinet podologiczny',
    'tatuazysta': 'Salon tatuażu',
}
DOKUMENTY = ['00-koncepcja-portalu-beautypolisa.md', '02-architektura-i-bezpieczenstwo.md', '04-seo-geo-i-schema.md',
             '05-strategia-tresci.md', '06-lead-magnety-lejki-i-kampania.md', '10-design-v3-old-money.md',
             '11-strefa-klienta.md', '12-integracja-apk-wniosek-polisa.md', '13-przeniesienie-formularzy/README.md',
             '13-przeniesienie-formularzy/00-braki-i-decyzje.md', '13-przeniesienie-formularzy/dokumenty-produktowe.md',
             '14-integracja-wnioskow-z-crm.md']
SNIPPETY_OC = ['faq-oc-beauty.json', 'schema-faq-oc-beauty.json', 'schema-produkt-oc-beauty.json', 'taryfa-oc-beauty.json',
               'zabiegi-oc-beauty.json', 'klauzula-ochrona-prawna.json', 'oc-skladka.js', 'lead-schema.ts', 'llms.txt']
SNIPPETY_INNE = ['schema.sql', 'strefa-klienta.sql', 'rls-policies.sql', 'schema-home.json', 'dokumenty-produktowe.json']
ARCHIWA = ['zabiegi-oc-beauty-wycofane.json', 'zabiegi-oc-beauty-propozycje.json']
POMIN_KLUCZE = {'$comment', 'do_potwierdzenia', 'dawne_nazwy', 'dawne_slugi'}
DOZWOLONE_CYTATY = {
    'Wykonuję zabiegi wymagające ankiety ERGO Hestii',
    'Poproś o polisę', 'Poproś o wycenę indywidualną', 'Treść klauzuli',
}

BLEDY = []
WYJATKI = []      # (plik, linia, opis, kontekst)
SZCZEGOLY = '-v' in sys.argv


def blad(msg):
    BLEDY.append(msg)


def czytaj(p):
    try:
        return p.read_text(encoding='utf-8')
    except OSError as e:
        print('BŁĄD WEJŚCIA:', e)
        sys.exit(2)


def json_plik(p):
    try:
        return json.loads(czytaj(p))
    except ValueError as e:
        print('BŁĄD WEJŚCIA: %s: %s' % (p, e))
        sys.exit(2)


Z = json_plik(SN / 'zabiegi-oc-beauty.json')
T = json_plik(SN / 'taryfa-oc-beauty.json')
LISTY = {l['klucz']: l for l in Z['listy']}
LICZBA = {k: sum(1 for z in Z['zabiegi'] for p in z['pozycje'] if p['lista'] == k) for k in LISTY}
WSPOLNE = sum(1 for z in Z['zabiegi'] if {p['lista'] for p in z['pozycje']} >= {'lista-1', 'lista-2'})
DAWNE = [n for z in Z['zabiegi'] for n in z.get('dawne_nazwy', [])]
NAZWY_POZYCJI = {z['nazwa'] for z in Z['zabiegi']} | {p['nazwa'] for z in Z['zabiegi'] for p in z['pozycje'] if 'nazwa' in p}
DOZWOLONE = (NAZWY_POZYCJI | {l['nazwa'] for l in Z['listy']} | {k['nazwa'] for k in T['kategorie']}
             | {r['nazwa'] for r in T['rodzaje_gabinetu']} | {v for k, v in T['pytania'].items()} | DOZWOLONE_CYTATY
             | {ot.zdanie_z_innej_listy()} | set(ot.teksty_crm('dokumenty_przy_zabiegach_z_ankiety')))


KAT_NAZWA = {k['klucz']: k['nazwa'] for k in T['kategorie']}


def TEKSTY_PUBLIKOWANE():
    """[(nazwa, tekst)] – teksty publikowane z opisem taryfy OC (D45): snippets i strony v3 (bez strefa/*)."""
    out = [(n, czytaj(SN / n)) for n in ('llms.txt', 'schema-faq-oc-beauty.json', 'slownik.json')]
    v3 = K / 'design/v3'
    out += [('design/v3/' + n, czytaj(v3 / n)) for n in ('makieta-v3.html', 'oc-beauty.html', 'slownik.html', 'design-preview.html')]
    return out


def pozycji(n):
    return '%d %s' % (n, 'pozycja' if n == 1 else 'pozycje' if n % 10 in (2, 3, 4) and n % 100 not in (12, 13, 14) else 'pozycji')


def norm(s):
    return s.replace(NB, ' ').replace('&nbsp;', ' ')


# ------------------------------------------------------------------ fragmenty tekstu z wyjątkami (B)
def fragmenty(tekst, sciezka):
    """[(nr linii, tekst fragmentu, historyczny?)] – wiersz albo ciąg linii komentarza (--, //) jako jeden fragment;
    sekcje ze znacznikiem historycznym oznaczone całe."""
    linie = tekst.split('\n')
    hist = [False] * len(linie)
    md = sciezka.suffix == '.md'
    if md:
        poziom_pom = None
        ostatni = 0
        for i, l in enumerate(linie):
            m = re.match(r'(#{1,6}) ', l)
            if m:
                lv = len(m.group(1))
                if poziom_pom is not None and lv <= poziom_pom:
                    poziom_pom = None
                ostatni = lv
            if l.strip() == ZNACZNIK_SEKCJI:
                poziom_pom = ostatni
            if poziom_pom is not None:
                hist[i] = True
    out = []
    i = 0
    while i < len(linie):
        l = linie[i]
        if re.match(r'\s*(--|//)', l):
            j = i
            while j + 1 < len(linie) and re.match(r'\s*(--|//)', linie[j + 1]):
                j += 1
            blok = '\n'.join(linie[i:j + 1])
            out.append((i + 1, blok, any(hist[i:j + 1])))
            i = j + 1
            continue
        out.append((i + 1, l, hist[i]))
        i += 1
    return [(n, b, h or ('D43' in b and bool(WYJATEK_D43.search(b)))) for n, b, h in out]


def bez_cytatow(s):
    return CYTAT.sub(' ', s)


def sprawdz_dokument(sciezka, nazwa, frazy=FRAZY_OC, ogolne=True):
    tekst = norm(czytaj(sciezka))
    for nr, frag, hist in fragmenty(tekst, sciezka):
        traf = [(o, m) for o, w in frazy for m in w.finditer(frag)]
        if ogolne and KONTEKST_OC.search(frag):
            bc = bez_cytatow(frag)
            traf += [(o, m) for o, w in FRAZY_OGOLNE_DOK for m in w.finditer(bc)]
        for o, m in traf:
            src = m.string
            kont = re.sub(r'\s+', ' ', src[max(0, m.start() - 50):m.end() + 40]).strip()
            if hist:
                WYJATKI.append((nazwa, nr, o, kont))
            else:
                blad('%s:%d: zakazana fraza „%s” – …%s…' % (nazwa, nr, o, kont))
        sprawdz_cytaty_crm(frag, '%s:%d' % (nazwa, nr), hist)


# ------------------------------------------------------------------ teksty JSON (A)
def napisy(obj, pomin=POMIN_KLUCZE, sciezka=''):
    """[(ścieżka klucza, napis)] bez pól z `pomin`."""
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k in pomin:
                continue
            yield from napisy(v, pomin, '%s.%s' % (sciezka, k))
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            yield from napisy(v, pomin, '%s[%d]' % (sciezka, i))
    elif isinstance(obj, str):
        yield sciezka, obj


def sprawdz_napis(nazwa, gdzie, s, frazy=FRAZY, wyjatki=(), cytaty_crm=True):
    t = norm(s)
    for w in sorted({w for w in wyjatki if w}, key=len, reverse=True):
        t = t.replace(w, ' ⟨wyjątek⟩ ')
    for o, wz in frazy:
        for m in wz.finditer(t):
            blad('%s%s: zakazana fraza „%s” – …%s…' % (nazwa, gdzie, o, re.sub(r'\s+', ' ', t[max(0, m.start() - 50):m.end() + 40])))
    if cytaty_crm:
        sprawdz_cytaty_crm(t, nazwa + gdzie, False)


SLOWA_ZABIEGOW = re.compile(r'toksyn|botulin|hialuron|wypełniacz|nici\b|PDO\b|HIFU|PLASMA|mezoterapi|peeling|strzyżeni|koloryzac'
                            r'|manicure|pedicure|microblading|makijaż\w* permanent|laser|lipoliz|osocz|fibryn|IPL\b|rzęs', re.I)


def podobny_do_pozycji(c):
    import difflib
    cl = c.lower()
    for n in NAZWY_POZYCJI:
        nl = n.lower()
        if cl in nl or nl in cl or difflib.SequenceMatcher(None, cl, nl).ratio() >= 0.6:
            return n
    return None


def sprawdz_cytaty_przyklady(nazwa, s):
    """E (K14): przykłady zabiegów tylko dosłownie z list. Błąd: (a) cytat „…” podobny do nazwy pozycji, ale nie identyczny
    z nazwą pozycji, listy, taryfy, rodzaju działalności ani zdaniem z DOZWOLONE; (b) po „m.in.”/„np.” zabieg bez cudzysłowu
    (własny skrót zamiast brzmienia z listy)."""
    t = norm(s)
    dozw = {norm(x) for x in DOZWOLONE}
    for m in re.finditer(r'„([^”]+)”', t):
        c = m.group(1)
        if c not in dozw:
            n = podobny_do_pozycji(c)
            if n:
                blad('%s: cytat „%s” nie jest dosłowną nazwą pozycji (najbliższa: „%s”) – K14' % (nazwa, c, n))
    for m in re.finditer(r'(?:m\.in\.|np\.)\s+([^„.;:()]{0,80})', t):
        if SLOWA_ZABIEGOW.search(m.group(1)):
            blad('%s: przykład zabiegu bez dosłownej nazwy z listy – „%s…” (K14: cytować pozycję albo bez przykładu)'
                 % (nazwa, t[m.start():m.end()].strip()))


# ------------------------------------------------------------------ D. cytaty CRM
Z_INNEJ = ot.zdanie_z_innej_listy()


def sprawdz_cytaty_crm(t, gdzie, hist):
    t = norm(t)
    if hist:
        return
    for m in re.finditer(r'Dopisanie zabiegów z innej listy', t):
        dalej = t[m.start():]
        if not dalej.startswith(Z_INNEJ) or re.match(re.escape(Z_INNEJ[:-1]) + r'\s*[—–-]', dalej):
            blad('%s: zdanie CRM o zabiegach z innej listy nie jest dosłownym pierwszym zdaniem („%s”) – K12' % (gdzie, Z_INNEJ))
    if re.search(r'dyplom\w* kosmetologa (?:oraz|i) certyfikat\w* szkoleń', t, re.I):
        blad('%s: skrót wymagań dokumentów („dyplom kosmetologa oraz certyfikaty szkoleń”) – przytoczyć CRM albo odesłać do doradcy (K16)' % gdzie)
    if '{termin}' in t:
        blad('%s: pole {termin} z CRM – na stronach „co najmniej 12 miesięcy przed początkiem ochrony” (K16)' % gdzie)
    for m in re.finditer(r'Koszty obrony prawnej', t):
        if not re.match(r'Koszty obrony prawnej, np\. w sporze z klientem, do 100 000 zł\.', t[m.start():]):
            blad('%s: opis ochrony prawnej inny niż w CRM z limitem („Koszty obrony prawnej, np. w sporze z klientem, do 100 000 zł.”) – Q8' % gdzie)


# zdanie „zabieg nie zmienia składki” bez zdania CRM o zabiegach z innej listy to pół informacji (weryfikacja, runda 2, K12)
NIE_ZMIENIA = re.compile(r'nie zmienia\w*\s+składk|składk\w*\s+nie zmienia|nie zależy od pojedynczego zabiegu', re.I)


def sprawdz_pelne_k12(nazwa, s):
    """D (K12): tekst publikowany, który mówi, że zabieg nie zmienia składki, musi zawierać też dosłowne zdanie CRM
    o zabiegach z innej listy (zmieniają rodzaj działalności i składkę)."""
    t = norm(s)
    if NIE_ZMIENIA.search(t) and Z_INNEJ not in t:
        blad('%s: „zabieg nie zmienia składki” bez zdania CRM „%s” – K12 (weryfikacja, runda 2)' % (nazwa, Z_INNEJ))


# ------------------------------------------------------------------ A + E: snippety OC
def snippety_oc():
    wyj_zab = DAWNE
    for f in SNIPPETY_OC:
        p = SN / f
        if f.endswith('.json'):
            d = json_plik(p)
            for gdzie, s in napisy(d):
                # taryfa → teksty_crm: zdania CRM w całości (dane źródłowe; zgodność z CRM – check_zgodnosc_crm.py)
                sprawdz_napis(f, gdzie, s, wyjatki=wyj_zab if f == 'zabiegi-oc-beauty.json' else (),
                              cytaty_crm=not gdzie.startswith('.teksty_crm'))
        else:
            tekst = czytaj(p)
            for i, l in enumerate(tekst.split('\n'), 1):
                sprawdz_napis(f, ':%d' % i, l)
    # E: przykłady w tekstach publikowanych
    sp = json_plik(SN / 'schema-produkt-oc-beauty.json')
    for k in ('description', 'alternateName'):
        sprawdz_cytaty_przyklady('schema-produkt-oc-beauty.json:%s' % k, sp[k])
    sprawdz_cytaty_przyklady('schema-produkt-oc-beauty.json:offers.description', sp['offers']['description'])
    for q in json_plik(SN / 'faq-oc-beauty.json')['pytania']:
        sprawdz_cytaty_przyklady('faq-oc-beauty.json: „%s”' % q['pytanie'], ' '.join(b for b in q['odpowiedz'] if isinstance(b, str)))
    for q in json_plik(SN / 'schema-faq-oc-beauty.json')['mainEntity']:
        sprawdz_cytaty_przyklady('schema-faq-oc-beauty.json: „%s”' % q['name'], q['acceptedAnswer']['text'])
    for i, l in enumerate(czytaj(SN / 'llms.txt').split('\n'), 1):
        if re.search(r'oc-beauty|/kalkulator/oc|/dla-kogo/', l):
            sprawdz_cytaty_przyklady('llms.txt:%d' % i, l)
            sprawdz_pelne_k12('llms.txt:%d' % i, l)
    for q in json_plik(SN / 'faq-oc-beauty.json')['pytania']:
        sprawdz_pelne_k12('faq-oc-beauty.json: „%s”' % q['pytanie'], ' '.join(b for b in q['odpowiedz'] if isinstance(b, str)))
    for q in json_plik(SN / 'schema-faq-oc-beauty.json')['mainEntity']:
        sprawdz_pelne_k12('schema-faq-oc-beauty.json: „%s”' % q['name'], q['acceptedAnswer']['text'])
    # słownik: hasła OC – wszystkie frazy; pozostałe hasła – frazy OC
    sl = json_plik(SN / 'slownik.json')
    for h in sl['hasla']:
        tresc = ' '.join(s for _, s in napisy({k: v for k, v in h.items() if k in ('termin', 'alias', 'definicja', 'przyklad', 'gdzie')}))
        oc = h['kategoria'] == 'oc' or re.search(r'\bOC\b', tresc)
        for gdzie, s in napisy(h):
            sprawdz_napis('slownik.json', '[%s]%s' % (h['id'], gdzie), s, frazy=FRAZY if oc and not gdzie.startswith('.zrodlo') else FRAZY_OC)
        if oc:
            for k in ('definicja', 'przyklad'):
                if h.get(k):
                    sprawdz_cytaty_przyklady('slownik.json[%s].%s' % (h['id'], k), h[k])
                    sprawdz_pelne_k12('slownik.json[%s].%s' % (h['id'], k), h[k])


# ------------------------------------------------------------------ C: dane i liczby
def dane():
    l1, l2, an = LISTY['lista-1'], LISTY['lista-2'], LISTY['ankieta']
    for k in ('lista-1', 'lista-2', 'ankieta'):
        if LICZBA[k] != LISTY[k]['liczba_pozycji']:
            blad('zabiegi-oc-beauty.json: lista %s ma %d pozycji, liczba_pozycji = %s' % (k, LICZBA[k], LISTY[k]['liczba_pozycji']))
    # llms.txt
    llms = norm(czytaj(SN / 'llms.txt'))
    oczek = ['lista nr 1 „%s”: %s' % (l1['nazwa'], pozycji(LICZBA['lista-1'])),
             'lista nr 2 „%s”: %s' % (l2['nazwa'], pozycji(LICZBA['lista-2'])),
             '%d zabiegów jest na obu listach' % WSPOLNE,
             '%s: %s' % (an['nazwa'], pozycji(LICZBA['ankieta'])),
             'Lista zabiegów podologicznych jest w dokumentach programu',
             '+%d zł' % T['ochrona_prawna']['skladka'], '%d%%' % round(T['doplata_6_8_osob'] * 100),
             'więcej niż 8 osób i zabiegi wymagające ankiety ERGO Hestii – wycena indywidualna']
    for k in T['kategorie']:
        st = ' / '.join(norm(ot.grupuj(k['skladka'][str(s)])) for s in T['sumy'])
        oczek.append('%s – „%s”: %s zł' % (ot.OPIS_KATEGORII[k['klucz']], k['nazwa'], st))
    oczek.append(' / '.join(norm(ot.grupuj(s)) for s in T['sumy']) + ' zł')
    for o in oczek:
        if o not in llms:
            blad('llms.txt: brak „%s” (dane z zabiegi-oc-beauty.json / taryfa-oc-beauty.json)' % o)
    for n in re.findall(r'(\d+) (?:pozycj|zabieg)', ' '.join(l for l in llms.split('\n') if 'oc-beauty' in l)):
        if int(n) not in set(LICZBA.values()) | {WSPOLNE}:
            blad('llms.txt: liczba %s przy pozycjach/zabiegach OC nie wynika z zabiegi-oc-beauty.json' % n)
    rodzaje = {r['nazwa'] for r in T['rodzaje_gabinetu']}
    for slug, rodzaj in DLA_KOGO.items():
        wiersz = [l for l in llms.split('\n') if '/dla-kogo/%s)' % slug in l]
        if len(wiersz) != 1:
            blad('llms.txt: „Dla kogo” – brak wiersza /dla-kogo/%s' % slug)
            continue
        cyt = set(re.findall(r'„([^”]+)”', wiersz[0])) & rodzaje
        if cyt != {rodzaj}:
            blad('llms.txt: /dla-kogo/%s – rodzaj działalności %s, decyzja z 14.11.2026: „%s”' % (slug, sorted(cyt) or 'brak', rodzaj))
    # 05 – tabela person: kolumna OC z rodzajem działalności według tej samej decyzji
    d05 = norm(czytaj(K / '05-strategia-tresci.md')).split('\n')
    for prefiks, slug in (('| Kosmetolog JDG |', 'kosmetolog'), ('| Fryzjer / barber |', 'fryzjer'), ('| Podolog |', 'podolog'),
                          ('| Linergistka', 'linergistka'), ('| Stylistka paznokci |', 'stylistka-paznokci'), ('| Tatuażysta |', 'tatuazysta')):
        w = [l for l in d05 if l.startswith(prefiks)]
        if len(w) != 1 or '„%s”' % DLA_KOGO[slug] not in w[0]:
            blad('05: persona %s – w kolumnie OC brak rodzaju działalności „%s” (decyzja z 14.11.2026)' % (prefiks.strip('| '), DLA_KOGO[slug]))
    # FAQ
    try:
        import gen_oc_beauty as g
        if czytaj(SN / 'schema-faq-oc-beauty.json') != g.schema_faq_text():
            blad('schema-faq-oc-beauty.json ≠ FAQ z faq-oc-beauty.json (uruchom gen_oc_beauty.py)')
    except Exception as e:  # generator w trakcie zmian – sam plik i tak sprawdzamy niżej
        blad('gen_oc_beauty.py: nie da się zbudować FAQ do porównania (%s: %s)' % (type(e).__name__, e))
    faq = norm(' '.join(q['acceptedAnswer']['text'] for q in json_plik(SN / 'schema-faq-oc-beauty.json')['mainEntity']))
    for o in ('„%s” (%s)' % (l1['nazwa'], pozycji(LICZBA['lista-1'])), '„%s” (%s)' % (l2['nazwa'], pozycji(LICZBA['lista-2'])),
              '(%s)' % pozycji(LICZBA['ankieta']), '(%d)' % WSPOLNE):
        if o not in faq:
            blad('schema-faq-oc-beauty.json: brak „%s”' % o)
    # schema-produkt
    sp = json_plik(SN / 'schema-produkt-oc-beauty.json')['offers']
    st = [v for k in T['kategorie'] for v in k['skladka'].values()]
    for pole, oczekiwane in (('lowPrice', min(st)), ('highPrice', max(st)), ('offerCount', len(T['kategorie']) * len(T['sumy']))):
        if sp.get(pole) != oczekiwane:
            blad('schema-produkt-oc-beauty.json: offers.%s = %s, z taryfy %s' % (pole, sp.get(pole), oczekiwane))
    for o in ('25%', '92 zł'):
        if o not in norm(sp['description']):
            blad('schema-produkt-oc-beauty.json: offers.description bez „%s”' % o)
    # słownik
    sl = {h['id']: h for h in json_plik(SN / 'slownik.json')['hasla']}
    if 'grupa-ryzyka' in sl:
        blad('slownik.json: hasło grupa-ryzyka nadal istnieje (D43)')
    if sl.get('rodzaj-dzialalnosci', {}).get('dawne_id') != ['grupa-ryzyka']:
        blad('slownik.json: hasło rodzaj-dzialalnosci bez dawne_id ["grupa-ryzyka"] (stare odnośniki #haslo-grupa-ryzyka)')
    d = norm(sl.get('lista-zabiegow-programu', {}).get('definicja', ''))
    for o in ('„%s” (%s)' % (l1['nazwa'], pozycji(LICZBA['lista-1'])), '„%s” (%s)' % (l2['nazwa'], pozycji(LICZBA['lista-2'])),
              '(%s)' % pozycji(LICZBA['ankieta'])):
        if o not in d:
            blad('slownik.json: hasło lista-zabiegow-programu – brak „%s”' % o)
    for h in sl.values():
        for z in h.get('zobacz_tez', []):
            if z not in sl:
                blad('slownik.json[%s]: zobacz_tez → nieistniejące hasło %s' % (h['id'], z))
        for g_ in h.get('gdzie', []):
            if re.search(r'#grupa-\d', g_['strona']):
                blad('slownik.json[%s]: odnośnik do dawnej kotwicy %s' % (h['id'], g_['strona']))
    # lead-schema.ts (rozdz. 5, K10)
    ts = czytaj(SN / 'lead-schema.ts')

    def enum(nazwa):
        m = re.search(r'export const %s = z\.enum\(\[([^\]]*)\]\)' % nazwa, ts)
        return re.findall(r'"([^"]+)"', m.group(1)) if m else None
    for nazwa, oczek in (('RodzajGabinetu', [r['klucz'] for r in T['rodzaje_gabinetu']]),
                         ('LiczbaOsob', [x['klucz'] for x in T['liczba_osob']]),
                         ('KategoriaOc', [k['klucz'] for k in T['kategorie']])):
        if enum(nazwa) != oczek:
            blad('lead-schema.ts: %s = %s, taryfa (= CRM): %s' % (nazwa, enum(nazwa), oczek))
    oc = ts[ts.index('export const OcCalcInput'):ts.index('export const TaxCalcInput')] if 'export const OcCalcInput' in ts else ''
    sumy = [int(x.replace('_', '')) for x in re.findall(r'z\.literal\((\d[\d_]*)\)', oc)]
    if sumy != T['sumy']:
        blad('lead-schema.ts: sumy w OcCalcInput %s ≠ taryfa %s' % (sumy, T['sumy']))
    for o in ('teamSize: LiczbaOsob.optional()', 'sumInsured: z.union', 'surveyProcedureIds', 'z.enum(ANKIETA_IDS)',
              'z.enum(LISTY_IDS)', 'if (v.surveyProcedureIds.length > 0) return;', 'v.teamSize !== "9+"'):
        if o not in oc:
            blad('lead-schema.ts: OcCalcInput bez „%s” (rozdz. 5, K10: pola opcjonalne przy wycenie indywidualnej)' % o)
    for k, v in T['komunikaty_brakow'].items():
        if k in ('rodzaje', 'osoby', 'suma') and '"%s"' % v not in oc:
            blad('lead-schema.ts: komunikat braku „%s” inny niż w taryfa-oc-beauty.json' % v)
    for o in ('"survey_procedures"', '"team_over_8"'):
        if o not in ts:
            blad('lead-schema.ts: QuoteResult bez powodu %s' % o)
    for o in ('riskGroup', 'risk_group_4', '.max(117)'):
        if o in ts:
            blad('lead-schema.ts: dawny element „%s”' % o)
    # schema.sql
    sql = czytaj(SN / 'schema.sql')
    kod = '\n'.join(l for l in sql.split('\n') if not l.lstrip().startswith('--'))
    m = re.search(r"category\s+text not null check \(category in \(([^)]*)\)\)", kod)
    if not m or re.findall(r"'([^']+)'", m.group(1)) != [k['klucz'] for k in T['kategorie']]:
        blad('schema.sql: pricing_oc_tiers.category – CHECK inny niż klucze kategorii z taryfy')
    for kol, oczek in (('legal_protection_addon', '%.2f' % T['ochrona_prawna']['skladka']),
                       ('legal_protection_limit', str(T['ochrona_prawna']['limit'])),
                       ('team_6_8_surcharge', '%.2f' % T['doplata_6_8_osob'])):
        m = re.search(r'%s\s+\w+(?:\(\d+,\d+\))?\s+not null default ([\d.]+)' % kol, kod)
        if not m or m.group(1) != oczek:
            blad('schema.sql: pricing_oc_params.%s – domyślnie %s, taryfa %s' % (kol, m.group(1) if m else 'brak', oczek))
    if re.search(r'\brisk_group\b', kod) or 'riskGroup' in kod:
        blad('schema.sql: dawna kolumna risk_group / riskGroup poza opisem migracji')
    if 'Migracja z wcześniejszej wersji' not in sql:
        blad('schema.sql: brak opisu migracji tabel cennika OC (D43)')
    # strefa-klienta.sql
    sk = czytaj(SN / 'strefa-klienta.sql')
    kod = '\n'.join(l for l in sk.split('\n') if not l.lstrip().startswith('--'))
    m = re.search(r"oc_rodzaje\s+text\[\] check \(oc_rodzaje <@ array\[([^\]]*)\]", kod)
    if not m or re.findall(r"'([^']+)'", m.group(1)) != [r['klucz'] for r in T['rodzaje_gabinetu']]:
        blad('strefa-klienta.sql: oc_rodzaje – CHECK inny niż rodzaje działalności z taryfy')
    m = re.search(r"oc_kategoria\s+text check \(oc_kategoria in \(([^)]*)\)\)", kod)
    if not m or re.findall(r"'([^']+)'", m.group(1)) != [k['klucz'] for k in T['kategorie']]:
        blad('strefa-klienta.sql: oc_kategoria – CHECK inny niż klucze kategorii z taryfy')
    m = re.search(r"oc_team_size_band\s+text check \(oc_team_size_band in \(([^)]*)\)\)", kod)
    if not m or re.findall(r"'([^']+)'", m.group(1)) != [x['klucz'] for x in T['liczba_osob']]:
        blad('strefa-klienta.sql: oc_team_size_band – wartości inne niż liczba_osob z taryfy')
    # CHECK taryfy: cardinality(NULL) to NULL, a CHECK z wynikiem NULL przepuszcza wiersz – stąd coalesce (sprawdzone na PostgreSQL 16)
    if 'coalesce(cardinality(oc_rodzaje), 0) > 0' not in kod:
        blad('strefa-klienta.sql: CHECK client_policies_oc_taryfa bez coalesce(cardinality(oc_rodzaje), 0) – polisa bez rodzajów przeszłaby')
    for o in ('oc_risk_groups', 'oc_tariff_group', "'do-5'"):
        if o in kod:
            blad('strefa-klienta.sql: dawny element %s poza opisem migracji' % o)
    if kod.count('oc_rodzaje, oc_kategoria') != 3 or kod.count('oc_zabiegi_ankieta') < 4:
        blad('strefa-klienta.sql: granty kolumnowe client_policies bez nowych kolumn OC (sekcja 8.3)')
    if not re.search(r'Migracja kolumn OC.*?NIE są przenoszone automatycznie', sk, re.S):
        blad('strefa-klienta.sql: brak opisu migracji kolumn OC bez automatycznego mapowania grup (K17)')
    # dokument 02 – kopie snippetów
    d02 = czytaj(K / '02-architektura-i-bezpieczenstwo.md')
    for plik, poczatek, jezyk in (('lead-schema.ts', '// packages/schemas/lead.ts', 'ts'), ('schema.sql', '-- Higiena uprawnień', 'sql')):
        m = re.search(r'```%s\n(%s.*?)\n```' % (jezyk, re.escape(poczatek)), d02, re.S)
        if not m:
            blad('02: brak bloku ```%s z kopią snippets/%s' % (jezyk, plik))
        elif m.group(1).rstrip('\n') != czytaj(SN / plik).rstrip('\n'):
            blad('02: blok ```%s ≠ snippets/%s (kopia w dokumencie nieaktualna)' % (jezyk, plik))
    # reguła kategorii D45 (decyzja zleceniodawcy 16.11.2026): bez opisów reguły sprzed D45 w tekstach publikowanych, a przykład
    # „gabinet kosmetyczny razem z gabinetem kosmetologicznym” zawsze z taryfą, którą daje reguła (oc_taryfa.kategoria)
    stare_opisy = ('także razem z gabinetem kosmetycznym lub salonem masażu',
                   'albo salon fryzjerski razem z gabinetem kosmetologicznym')
    taryfa_pary = KAT_NAZWA[ot.kategoria(['kosmetyczny', 'kosmetologiczny'])]
    para = re.compile(r'gabinet\w* kosmetyczn\w*,? (?:razem z|i|oraz) gabinet\w* kosmetologiczn\w*[^.„]*„([^”]+)”', re.I)
    for nazwa, tekst in TEKSTY_PUBLIKOWANE():
        t = re.sub(r'\s+', ' ', norm(re.sub(r'<[^>]+>', '', tekst)))
        for s in stare_opisy:
            if s in t:
                blad('%s: opis reguły kategorii sprzed D45 („%s”) – reguła: oc_taryfa.OPIS_KATEGORII' % (nazwa, s))
        for m in para.finditer(t):
            if m.group(1) in KAT_NAZWA.values() and m.group(1) != taryfa_pary:
                blad('%s: gabinet kosmetyczny z kosmetologicznym – „%s”, według reguły D45 „%s”' % (nazwa, m.group(1), taryfa_pary))
    # 00 – D43, D45 i rejestr Q1–Q13
    d00 = czytaj(K / '00-koncepcja-portalu-beautypolisa.md')
    if not re.search(r'^\| D43 \|', d00, re.M):
        blad('00: brak decyzji D43 w tabeli decyzji')
    m45 = re.search(r'^\| D45 \|.*$', d00, re.M)
    if not m45 or 'kategoriaZRodzajow' not in m45.group(0) or 'odstępstw' not in m45.group(0).lower():
        blad('00: brak decyzji D45 (reguła kategorii, odstępstwo od kategoriaZRodzajow w CRM) w tabeli decyzji')
    m43 = re.search(r'^\| D43 \|.*$', d00, re.M)
    if m43 and 'D45' not in m43.group(0):
        blad('00: D43 lit. d (reguła kategorii) bez oznaczenia, że zmieniła ją D45')
    for q in range(1, 14):
        if not re.search(r'^\| Q%d \|' % q, d00, re.M):
            blad('00: brak pytania Q%d (OC po Aneksie nr 5) w rejestrze otwartych spraw (wiersz „| Q%d |”)' % (q, q))
    m = re.search(r'^\| Q3 \|.*$', d00, re.M)
    if m and 'rozstrzygnięte' not in m.group(0).lower():
        blad('00: Q3 nie jest oznaczone jako rozstrzygnięte (decyzja zleceniodawcy z 14.11.2026)')


def main():
    tylko_snip = '--snippets' in sys.argv
    tylko_dok = '--dokumenty' in sys.argv
    if not tylko_dok:
        snippety_oc()
        for f in SNIPPETY_INNE:
            sprawdz_dokument(SN / f, f, ogolne=False)
        sl = SN / 'slownik.json'
        if not sl.is_file():
            blad('brak snippets/slownik.json')
        for f in ARCHIWA:
            if not (SN / f).is_file():
                blad('brak archiwum snippets/%s' % f)
        dane()
    if not tylko_snip:
        for f in DOKUMENTY:
            sprawdz_dokument(K / f, f)
    if SZCZEGOLY:
        for w in WYJATKI:
            print('wyjątek (stan sprzed D43, oznaczony): %s:%d „%s” – …%s…' % w)
    ile = {}
    for w in WYJATKI:
        ile[w[0]] = ile.get(w[0], 0) + 1
    if ile:
        print('Wyjątki (opisy stanu sprzed D43, oznaczone): ' + ', '.join('%s %d' % kv for kv in sorted(ile.items())))
    for b in BLEDY:
        print(b)
    print('OC spójność: %s (%d)' % ('OK' if not BLEDY else 'BŁĘDY', len(BLEDY)))
    sys.exit(1 if BLEDY else 0)


if __name__ == '__main__':
    main()
