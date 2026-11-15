#!/usr/bin/env python3
"""Zakazane frazy w treściach OC beauty po Aneksie nr 5 (plan „OC beauty po Aneksie nr 5”, 6.8, z poprawkami z uwagi K7).

Frazy sprawdzamy TYLKO w strefach OC: w blokach, które piszą generatory OC (gen_oc_beauty.py, gen_kalkulator_dane.py,
gen_strefa_zabiegi.py), a w kolejnych krokach planu – w strefie kalkulatora OC, na stronie oc-beauty.html i w plikach OC
w snippets/. Poza OC te same słowa bywają poprawne (np. „podgrupa 1” w ubezpieczeniu grupowym, „bez rekomendacji” jako
zasada IDD, „do potwierdzenia” w innych produktach) – dlatego tego modułu nie stosujemy do całych stron spoza OC.

Wyjątki (K7 i 6.8):
  * aliasy kotwic (dawne slugi, #grupa-N) – atrybuty id, nie tekst; funkcja tekst_html() usuwa znaczniki z atrybutami;
  * dawne brzmienia pozycji ankiety (pole dawne_nazwy) i nazwy pozycji z archiwum wycofanych (np. g3-25 „Profilaktyka
    i zabiegi u osób z grup ryzyka”) – przekazywane jako `wyjatki` (dokładne napisy, wycinane przed sprawdzeniem);
  * zwroty przeczące: „bez rekomendacji”, „nie rekomendujemy”, „nie polecamy”;
  * „podgrupa N” (EZB) – wzorzec grup wymaga początku wyrazu.

Użycie: from oc_frazy import sprawdz, tekst_html;  sprawdz(tekst, wyjatki=[…]) → lista trafień [(fraza, kontekst)].
Uruchomienie: python3 -I oc_frazy.py PLIK… – wypisuje trafienia w całych plikach (pomocniczo; bez wyjątków z danych).
"""
import html
import re
import sys

# (opis, wzorzec) – wzorce bez rozróżniania wielkości liter, z wyjątkiem skrótów pisanych wielkimi literami (PRP).
FRAZY = [
    ('grupa ryzyka / grupa zabiegów', re.compile(r'\bgrup(?:a|ą|ę|i|y|ie|om|ach|ami)? (?:ryzyka|zabiegów)', re.I)),
    ('grupa 1–4', re.compile(r'\bgrup(?:a|ę|y|ie|ą)? [1-4]\b', re.I)),
    ('gr. 1–4', re.compile(r'\bgr\. ?[1-4]\b', re.I)),
    ('grupa {N} (pole szablonu z numerem dawnej grupy)', re.compile(r'\bgrup(?:a|ę|y|ie|ą)? \{', re.I)),
    ('stawki grupy', re.compile(r'stawk\w* grupy', re.I)),
    ('Pakiet łączony', re.compile(r'pakiet łączony', re.I)),
    ('wieloprofilowy', re.compile(r'wieloprofilow', re.I)),
    ('117 zabiegów', re.compile(r'\b117\b(?=.{0,40}zabieg)|zabieg.{0,40}\b117\b', re.I | re.S)),
    ('40/38/31/8', re.compile(r'40\s*/\s*38\s*/\s*31\s*/\s*8')),
    ('PRP', re.compile(r'\bPRP\b')),
    ('osoczem bogatopłytkowym', re.compile(r'osoczem bogatopłytkowym', re.I)),
    ('osocza bogatopłytkowego (poza pełną nazwą poz. c)', re.compile(r'osocza bogatopłytkowego(?! i wypełniaczy)', re.I)),
    ('laserem ablacyjnym', re.compile(r'laserem ablacyjnym', re.I)),
    ('Zabiegi z użyciem nici PDO (dawne brzmienie)', re.compile(r'zabiegi z użyciem nici PDO(?!, PLLA)', re.I)),
    ('Zabiegi technologią', re.compile(r'zabiegi technologią', re.I)),
    ('zespół od 9', re.compile(r'\bzesp(?:ół|oły|ołów|ołu|ole|ołach|ołom) od 9', re.I)),
    ('orientacyjn', re.compile(r'orientacyjn', re.I)),
    ('szacunkow', re.compile(r'szacunkow', re.I)),
    ('poglądow', re.compile(r'poglądow', re.I)),
    ('do potwierdzenia', re.compile(r'do potwierdzenia', re.I)),
    ('rekomendacj', re.compile(r'(?<!bez )rekomendacj', re.I)),
    ('rekomend', re.compile(r'(?<!nie )rekomendujemy', re.I)),
    ('polecamy', re.compile(r'(?<!nie )polecamy', re.I)),
    ('polecan', re.compile(r'polecan', re.I)),
    ('przykładow', re.compile(r'przykładow', re.I)),
    ('najlepszy wybór', re.compile(r'najlepsz\w* wyb', re.I)),
    ('najczęściej wybier', re.compile(r'najczęściej wybier', re.I)),
]


def tekst_html(s):
    """Tekst widoczny z fragmentu HTML (bez znaczników i ich atrybutów, z rozwiniętymi encjami; NBSP → spacja).
    Treść <script type="application/json|ld+json"> zostaje (to dane, które trafiają na stronę i do wyszukiwarek)."""
    s = re.sub(r'<!--.*?-->', ' ', s, flags=re.S)
    s = re.sub(r'<[^>]+>', ' ', s)
    return html.unescape(s).replace(' ', ' ')


def sprawdz(tekst, wyjatki=()):
    """Trafienia zakazanych fraz: [(opis, kontekst)]. `wyjatki` – dokładne napisy wycinane przed sprawdzeniem."""
    t = tekst.replace(' ', ' ')
    for w in sorted({w for w in wyjatki if w}, key=len, reverse=True):
        t = t.replace(w.replace(' ', ' '), ' ⟨wyjątek⟩ ')
    out = []
    for opis, wz in FRAZY:
        for m in wz.finditer(t):
            a, b = max(0, m.start() - 40), min(len(t), m.end() + 40)
            out.append((opis, re.sub(r'\s+', ' ', t[a:b]).strip()))
    return out


def raport(nazwa, trafienia):
    return '\n'.join('%s: zakazana fraza „%s” – …%s…' % (nazwa, o, k) for o, k in trafienia)


if __name__ == '__main__':
    bylo = False
    for p in sys.argv[1:]:
        t = open(p, encoding='utf-8').read()
        r = sprawdz(tekst_html(t) if p.endswith('.html') else t)
        if r:
            bylo = True
            print(raport(p, r))
    sys.exit(1 if bylo else 0)
