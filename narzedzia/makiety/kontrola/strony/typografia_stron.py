#!/usr/bin/env python3
"""Strony v3 są punktem stałym typografia.html() (runda 3 weryfikacji, 17.11.2026).

Dla 9 stron publicznych (z design-preview.html) i 4 stron Strefy: treść <body> poza komentarzami, <script>, <style>, <svg>
(tytuły symboli ikon), <textarea> i <pre> przepuszczona przez typografia.html() nie może się zmienić – wszystkie twarde spacje,
półpauzy i cudzysłowy są już na miejscu, także w blokach generowanych (generatory używają tego samego modułu) i na granicy
znaczników elementów liniowych („</strong>&nbsp;– …”, „tekst&nbsp;<em>– …</em>”). Wypisuje pierwsze różnice każdej strony.
Nic nie zapisuje. Uruchom: python3 -I narzedzia/makiety/kontrola/strony/typografia_stron.py   (kod wyjścia 1 przy różnicach)
"""
import difflib
import pathlib
import re
import sys

MAKIETY = pathlib.Path(__file__).resolve().parents[2]
V3 = MAKIETY.parents[1] / 'docs/koncepcja/design/v3'
sys.path.insert(0, str(MAKIETY))
import typografia as ty  # noqa: E402

STRONY = ['makieta-v3.html', 'oc-beauty.html', 'tax-protect.html', 'utrata-dochodu.html', 'nnw-dzieci.html', 'grupowe-ergo.html',
          'opieka-medyczna.html', 'slownik.html', 'design-preview.html',
          'strefa/logowanie.html', 'strefa/panel.html', 'strefa/dam-prace.html', 'strefa/szkolenia.html']
POMIN = re.compile(r'(<!--.*?-->|<script\b.*?</script\s*>|<style\b.*?</style\s*>|<svg\b.*?</svg>|<textarea\b.*?</textarea>|<pre\b.*?</pre>)',
                   re.S | re.I)


def roznice(body):
    """[(przed, po)] – fragmenty tekstu (między pominiętymi blokami), które typografia.html() zmienia."""
    out, poz = [], 0
    for m in list(POMIN.finditer(body)) + [None]:
        kaw = body[poz:m.start() if m else len(body)]
        nowy = ty.html(kaw)
        if nowy != kaw:
            sm = difflib.SequenceMatcher(None, kaw, nowy, autojunk=False)
            out += [(kaw[max(0, i1 - 40):i2 + 15], nowy[j1:j2]) for op, i1, i2, j1, j2 in sm.get_opcodes() if op != 'equal']
        poz = m.end() if m else poz
    return out


def main():
    bledy = 0
    for n in STRONY:
        s = (V3 / n).read_text(encoding='utf-8')
        body = s[s.index('<body'):s.rindex('</body>')]
        r = roznice(body)
        if r:
            bledy += len(r)
            print('%s: %d zmian typografii, np.:' % (n, len(r)))
            for a, b in r[:5]:
                print('   %r → %r' % (a, b))
    print('typografia stron: ' + ('OK (%d stron)' % len(STRONY) if not bledy else 'RÓŻNICE (%d)' % bledy))
    return 1 if bledy else 0


if __name__ == '__main__':
    sys.exit(main())
