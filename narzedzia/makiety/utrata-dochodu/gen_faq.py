#!/usr/bin/env python3
"""FAQ strony „Utrata dochodu” (design/v3/utrata-dochodu.html) – jedna lista pytań dla widocznego bloku i FAQPage w JSON-LD.

Lista pytań pochodzi z dawnego skryptu budującego stronę (katalog roboczy sesji, 12.11.2026), który składał całą stronę z szablonu
i kopiował bloki z oc-beauty.html po numerach linii – dziś już nieużywalny. Ten generator podmienia TYLKO:
  * treść między <!-- GEN:faq … --> i <!-- /GEN:faq --> (widoczne <details>; tekst przez typografia.html() – twarde spacje),
  * węzeł FAQPage (mainEntity) w bloku GEN:jsonld (tekst bez twardych spacji i bez znaczników – jak w gen_oc_beauty.py);
pozostałe węzły JSON-LD zostają bez zmian (json.dumps z indent=1 odtwarza blok znak w znak – asercja niżej).

Brzmienie (raport 16, rozdz. 3.3, utrata-dochodu.html :1225–1226; weryfikacja 17.11.2026): bez pierwszej osoby („Kwot tu nie ma, bo…”),
strona czynna („jeśli ich nie zgłosisz albo ubezpieczyciel ich nie przyjmie”).

Użycie: python3 -I narzedzia/makiety/utrata-dochodu/gen_faq.py [--check]
  --check – nic nie zapisuje; kod 1, gdy plik różni się od wyniku („RÓŻNICA – uruchom bez --check”).
"""
import html
import json
import pathlib
import re
import sys

TU = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(TU.parent))
import typografia as ty  # noqa: E402

REPO = TU.parents[2]
STRONA = REPO / 'docs/koncepcja/design/v3/utrata-dochodu.html'
UTM = 'utm_source=beautypolisa&amp;utm_medium=referral&amp;utm_campaign=utrata-dochodu'

# (pytanie – czysty tekst, odpowiedź – fragment HTML bez twardych spacji)
FAQ = [
    ('Ile zasiłku chorobowego dostanę z ZUS, prowadząc działalność w branży beauty?',
     'Zasiłek chorobowy to 80% podstawy wymiaru składek po odliczeniu 13,71% – nie 80% Twojego dochodu. Przy dużym ZUS-ie z najniższej podstawy (5 652 zł) '
     'i dobrowolnym chorobowym opłacanym od co najmniej 90 dni wynosi 3 902 zł miesięcznie przed podatkiem, niezależnie od tego, ile zarabiasz. '
     'Na preferencyjnym ZUS-ie to około 995 zł, a bez dobrowolnego chorobowego – 0 zł. ZUS wypłaca zasiłek najdłużej przez 182 dni.'),
    ('Ile wypłaci polisa od utraty dochodu?',
     'Do 80% udokumentowanego dochodu przy działalności gospodarczej i kontrakcie B2B oraz do 65% przy umowie o pracę i umowie zlecenia, najwyżej 50 000 zł miesięcznie. '
     'W ubezpieczeniu CEU „Utrata dochodu” limit wynosi 65% także przy działalności i B2B. Świadczenie przychodzi co miesiąc po okresie wyczekiwania ustalonym w umowie, '
     'dopóki trwa niezdolność do pracy – najdłużej przez okres wybrany przy zawarciu umowy: 24, 36, 48 albo 60 miesięcy.'),
    ('Ile kosztuje ubezpieczenie utraty dochodu?',
     'Kwot tu nie ma, bo ten produkt nie ma stałej taryfy. Składkę wylicza ubezpieczyciel po ocenie ryzyka: zawodu, wieku, wysokości dochodu i ankiety medycznej; '
     'znaczenie mają też okres wyczekiwania i okres wypłaty – dłuższy okres wypłaty podnosi składkę. Symulację zobaczysz na końcu '
     '<a href="https://utratadochodu.pl/wniosek/?' + UTM + '">wniosku na utratadochodu.pl</a>, a ofertę z realną stawką dostaniesz w 1–2 dni robocze.'),
    ('Czy dostanę świadczenie, jeśli mogę pracować tylko w mniejszym wymiarze?',
     'Nie. Polisa wypłaca świadczenie za całkowitą niezdolność do wykonywania zawodu – praca w mniejszym wymiarze albo przejście na lżejsze obowiązki nie spełnia '
     'warunku wypłaty. Ochrona nie obejmuje też m.in. wypalenia zawodowego jako samodzielnej diagnozy, chorób psychicznych (w Leadenhall – gdy są jedyną przyczyną '
     'niezdolności, w CEU – bez tego zastrzeżenia) i schorzeń leczonych w ciągu 24 miesięcy przed zawarciem umowy, jeśli ich nie zgłosisz albo ubezpieczyciel ich nie przyjmie. '
     'Pełną listę znajdziesz w sekcji <a href="#zakres">Co obejmuje, a czego nie</a>.'),
    ('Czy przed zawarciem umowy potrzebne są badania lekarskie?',
     'Przy standardowych sumach wystarczy ankieta medyczna we wniosku. Gdy suma dla trwałej niezdolności do pracy przekracza 1 000 000 zł, uruchamia się rozszerzona '
     'ankieta zdrowotna, a ubezpieczyciel może poprosić o badania. Wcześniejsze leczenie zgłoś w ankiecie – zatajenie schorzenia jest najczęstszą przyczyną odmowy wypłaty.'),
    ('Kto jest ubezpieczycielem i do kogo zgłasza się roszczenie?',
     'Ubezpieczycielem jest Lloyd’s Insurance Company S.A. z siedzibą w Brukseli. Umowę zawiera się za pośrednictwem coverholderów Lloyd’s: Leadenhall Insurance S.A. '
     'albo CEU sp. z o.o. Roszczenia z wariantów Leadenhall zgłasza się przez Leadenhall Insurance S.A., a z wariantów CEU – przez WAGAS S.A., której ubezpieczyciel '
     'powierzył likwidację szkód. Aura Expert sp. z o.o. jest agentem ubezpieczeniowym (RPU 11229690/A): przyjmuje wniosek i prowadzi sprawę do wystawienia polisy.'),
]

# zwroty, które nie mogą wrócić (raport 16: pierwsza osoba, strona bierna)
ZAKAZANE = ['podajemy', 'wskazujemy', 'nie zostały zgłoszone']

WCIECIE = '        '
ZN_FAQ = re.compile(r'(<!-- GEN:faq[^\n]*-->\n)(.*?)([ \t]*<!-- /GEN:faq -->)', re.S)
ZN_LD = re.compile(r'(<!-- GEN:jsonld[^\n]*-->\n.*?<script type="application/ld\+json">\n)(.*?)(\n</script>\n<!-- /GEN:jsonld -->)', re.S)
KOMENTARZ_FAQ = '<!-- GEN:faq (wygenerowane – narzedzia/makiety/utrata-dochodu/gen_faq.py; nie edytować ręcznie) -->\n'
KOMENTARZ_LD = '<!-- GEN:jsonld (FAQPage – narzedzia/makiety/utrata-dochodu/gen_faq.py z jednej listy pytań; pozostałe węzły – nie edytować ręcznie) -->'


def tekst(fragment):
    """Fragment HTML → czysty tekst do JSON-LD (bez znaczników i encji)."""
    return html.unescape(re.sub(r'<[^>]+>', '', fragment))


def blok_faq():
    linie = []
    for i, (p, o) in enumerate(FAQ, 1):
        linie.append('%s<details id="pytanie-%d"><summary>%s</summary><p>%s</p></details>' % (WCIECIE, i, ty.esc(p), ty.html(o)))
    return '\n'.join(linie) + '\n'


def kontrola_tresci():
    bledy = []
    for p, o in FAQ:
        for z in ZAKAZANE:
            if z in p or z in o:
                bledy.append('zakazany zwrot %r: %s' % (z, p))
        if ' ' in p + o or '&nbsp;' in p + o:
            bledy.append('twarda spacja w źródle (dodaje ją typografia.py): %s' % p)
        # typografia zmienia tylko odstępy – brzmienie widocznego bloku = JSON-LD
        if ty.porownaj(tekst(ty.html(o))) != ty.porownaj(tekst(o)) or ty.porownaj(html.unescape(ty.esc(p))) != ty.porownaj(p):
            bledy.append('typografia zmieniła brzmienie: %s' % p)
    return bledy


def zbuduj(s):
    m = ZN_FAQ.search(s)
    assert m and len(ZN_FAQ.findall(s)) == 1, 'utrata-dochodu.html: oczekiwano jednej pary znaczników GEN:faq'
    s = s[:m.start()] + re.sub(r'<!-- GEN:faq[^\n]*-->\n', KOMENTARZ_FAQ, m.group(1)) + blok_faq() + m.group(3) + s[m.end():]
    m = ZN_LD.search(s)
    assert m, 'utrata-dochodu.html: brak bloku GEN:jsonld ze skryptem application/ld+json'
    stary = m.group(2)
    d = json.loads(stary)
    assert json.dumps(d, ensure_ascii=False, indent=1).replace('</', '<\\/') == stary, \
        'GEN:jsonld nie jest w formacie json.dumps(indent=1) – generator zmieniłby inne węzły'
    faq = [n for n in d['@graph'] if n.get('@type') == 'FAQPage']
    assert len(faq) == 1, 'GEN:jsonld: oczekiwano jednego węzła FAQPage'
    faq[0]['mainEntity'] = [{'@type': 'Question', 'name': p, 'acceptedAnswer': {'@type': 'Answer', 'text': tekst(o)}} for p, o in FAQ]
    nowy = json.dumps(d, ensure_ascii=False, indent=1).replace('</', '<\\/')
    assert ' ' not in nowy and '&nbsp;' not in nowy
    poczatek = re.sub(r'<!-- GEN:jsonld[^\n]*-->', KOMENTARZ_LD, m.group(1), count=1)
    return s[:m.start()] + poczatek + nowy + m.group(3) + s[m.end():]


def main():
    check = '--check' in sys.argv[1:]
    bledy = kontrola_tresci()
    if bledy:
        print('\n'.join('BŁĄD: ' + b for b in bledy))
        sys.exit(2)
    s = STRONA.read_text(encoding='utf-8')
    nowy = zbuduj(s)
    assert zbuduj(nowy) == nowy, 'generator nie jest idempotentny'
    if check:
        print('OK' if nowy == s else 'RÓŻNICA – uruchom bez --check')
        sys.exit(0 if nowy == s else 1)
    if nowy != s:
        STRONA.write_text(nowy, encoding='utf-8')
        print('Zapisano', STRONA.relative_to(REPO), '(%d pytań)' % len(FAQ))
    else:
        print('Bez zmian (%d pytań)' % len(FAQ))


if __name__ == '__main__':
    main()
