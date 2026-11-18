#!/usr/bin/env python3
"""Polska typografia dla generatorów makiet (jedno źródło reguł; raport 16, rozdz. 3.1 i 5 pkt 1.2).

Reguły (tylko tekst – znaczniki, komentarze, <script> i <style> zostają bez zmian):
  1. twarda spacja po jednoliterowych wyrazach (a, i, o, u, w, z – też wielką literą), także kilku z rzędu („i w jednym”):
     lookbehind zamiast grupy, więc spacja przed wyrazem nie jest „zużywana” (błąd dawnego nbsp() w opieka-medyczna/build.py);
     także przed znacznikiem elementu liniowego („w <a href=…>” → „w&nbsp;<a href=…>”);
  2. liczba + jednostka albo rzeczownik („400 zł”, „12 miesięcy”, „5 osób”, „8 pozycji”, „2017 r.”, „16 listopada”),
     „tys. zł”, „/ mies.”; grupy cyfr („1 000 000 zł”, „504 400 901”);
  3. skrót + liczba („nr 5”; „nr” także przed symbolem z wielkiej litery – „nr WA50/003353/24/A”; „poz. 17”, „art. 22”, „§ 3”, „pkt 4”, „ust. 1”, „NIP …”, „REGON …”, „numerem …”, „lokal 28”),
     kod pocztowy z miastem („01-466 Warszawa”), „sp. z o.o.”, „S.A.” po nazwie;
  4. półpauza jako myślnik nie zaczyna wiersza („lista nr 1 – gabinety”: twarda spacja przed „–”, także na granicy elementu liniowego:
     „</strong> – dalej”, „tekst <em>– dalej</em>”); pauza „ — ” → półpauza „ – ”;
  5. nazwy marek bez łamania: „ERGO Hestia” (odmiana), „ERGO Razem”, „ERGO Życie”, „LUX MED”, „Aura Expert”;
  6. „...” → „…”, proste cudzysłowy "…" → „…”.
Słowa, kolejność i znaki interpunkcyjne zostają – zmieniają się tylko odstępy (i kreska z reguły 4); brzmienie list zabiegów,
klauzuli i zdań CRM pozostaje 1:1 (porównania w kontrolach: U+00A0 = spacja, „—” = „–”).

  html(s)   – fragment HTML (tekst już escapowany) → HTML z &nbsp;
  esc(s)    – czysty tekst → html.escape + html()
  tekst(s)  – czysty tekst → tekst z U+00A0 (dane JSON wstawiane przez textContent, np. dymki słownika)
  JS        – ta sama reguła 1–3 w JavaScripcie (funkcja bpTypografia(s) → tekst z U+00A0; np. chipy zabiegów w „Dam pracę”)
  marki(s)  – nazwy marek we fragmencie HTML → <span translate="no">…</span>
  porownaj(s) – tekst do porównań brzmienia w kontrolach: U+00A0 → spacja, „—” → „–”, bez łącznika słowa U+2060

Uruchom: python3 -I typografia.py – przykłady i kontrola reguł.
"""
import html as _html
import re

NBSP = ' '

# poprzednik wyrazu jednoliterowego: początek tekstu, biały znak (też U+00A0), nawias, cudzysłów otwierający, encja twardej spacji
_PRZED = r'(?:^|(?<=[\s(\[„"\' ])|(?<=&nbsp;)|(?<=&#160;))'
_JEDNOLITEROWE = re.compile(_PRZED + r'([aiouwzAIOUWZ])[ \t]+(?=\S)')
_JEDNOSTKI = ('zł|gr|tys\\.|mln|mld|%|proc\\.|dniach|dni|dnia|dzień|lat|lata|rok|roku|miesiącach|miesięcy|miesiące|miesiąca|miesiąc|mies\\.|'
              'tygodni|tygodnie|tydzień|godz\\.|godzin|godziny|min|minut|osób|osoby|osoba|osobę|pozycji|pozycje|pozycja|'
              'haseł|hasła|hasło|zabiegów|zabiegi|zabieg|punktów|punkty|kategorii|kategorie|wariantów|warianty|kroków|kroki|'
              'r\\.|szt\\.|stycznia|lutego|marca|kwietnia|maja|czerwca|lipca|sierpnia|września|października|listopada|grudnia')
_LICZBA_JEDNOSTKA = re.compile(r'(\d)[ \t]+(' + _JEDNOSTKI + r')(?![\w])')
_GRUPY_CYFR = re.compile(r'(?<=\d)[ \t](?=\d{3}(?!\d))')
_SKROT_LICZBA = re.compile(r'(?<![\w.])(§|art\.|Art\.|pkt|ust\.|poz\.|str\.|ul\.|lit\.|par\.|NIP|REGON|KRS|numerem|lokal)[ \t]+(?=\d)')
# „nr” także przed symbolem zaczynającym się wielką literą („nr WA50/003353/24/A”, „nr KRS …”)
_NR = re.compile(r'(?<![\w.])(nr|Nr)[ \t]+(?=[\dA-ZĄĆĘŁŃÓŚŹŻ])')
_KOD_MIASTO = re.compile(r'(?<!\d)(\d{2}-\d{3})[ \t]+(?=[A-ZĆŁŚŹŻ])')
_TYS_ZL = re.compile(r'(tys\.|mln|mld)[ \t]+(zł)(?![\w])')
_NA = re.compile(r'(?<=\S)[ \t]+/[ \t]+(?=mies\.|mc\b|rok\b)')
_SP_ZOO = re.compile(r'(?<![\w])sp\.[ \t]+z[ \t]+o\.o\.')
_SA = re.compile(r'(?<=\w)[ \t]+(S\.A\.)')
_MYSLNIK = re.compile(r'(?<=[^\s>])[ \t]+([–—])(?=[ \t])')
_PAUZA = re.compile(r'(?<=\S)([ \t ]|&nbsp;)—(?=[ \t])')
_MARKI = re.compile(r'\b(ERGO|LUX|Aura)[ \t]+(Hesti[aię]|Hestią|Razem|Życie|MED|Expert)\b')
_WIELOKROPEK = re.compile(r'\.\.\.')
_CUDZYSLOW = re.compile(r'"([^"<>\n]+)"')


def _popraw(s, nb):
    """Reguły na samym tekście (bez znaczników); nb = '&nbsp;' albo U+00A0."""
    s = _WIELOKROPEK.sub('…', s)
    s = _CUDZYSLOW.sub(r'„\1”', s)
    s = _PAUZA.sub(lambda m: m.group(1) + '–', s)
    s = _SP_ZOO.sub('sp.' + nb + 'z' + nb + 'o.o.', s)
    s = _SA.sub(nb + r'\1', s)
    s = _MARKI.sub(r'\1' + nb + r'\2', s)
    s = _TYS_ZL.sub(r'\1' + nb + r'\2', s)
    s = _NA.sub(nb + '/' + nb, s)
    s = _LICZBA_JEDNOSTKA.sub(r'\1' + nb + r'\2', s)
    s = _GRUPY_CYFR.sub(nb, s)
    s = _SKROT_LICZBA.sub(r'\1' + nb, s)
    s = _NR.sub(r'\1' + nb, s)
    s = _KOD_MIASTO.sub(r'\1' + nb, s)
    s = _MYSLNIK.sub(nb + r'\1', s)
    s = _JEDNOLITEROWE.sub(r'\1' + nb, s)
    return s


_ZNACZNIK = re.compile(r'(<!--.*?-->|<(?:script|style)\b.*?</(?:script|style)\s*>|<[^>]*>)', re.S | re.I)
# wyraz jednoliterowy na końcu kawałka tekstu, gdy zaraz po spacji zaczyna się znacznik w treści („znajdziesz w <a href=…>”,
# „razem z <a class="bp-termin">”; runda 2 weryfikacji 17.11.2026) – spacja przed znacznikiem otwierającym element liniowy
_JEDNOLITEROWE_KONIEC = re.compile(_PRZED + r'([aiouwzAIOUWZ])[ \t]+$')
_ZNACZNIK_LINIOWY = re.compile(r'<(?:a|abbr|b|bdi|bdo|cite|code|data|dfn|em|i|kbd|mark|q|s|samp|small|span|strong|sub|sup|time|u|var)\b',
                               re.I)


# reguła 4 na granicy znacznika elementu liniowego (runda 3 weryfikacji): „</strong> – wsparcie” i „Trzy warianty <em>– składka</em>” –
# spacja przed półpauzą-myślnikiem stała między tekstem a znacznikiem, więc „–” mogło zacząć wiersz
_ZAMYKAJACY_LINIOWY = re.compile(r'</(?:a|abbr|b|bdi|bdo|cite|code|data|dfn|em|i|kbd|mark|q|s|samp|small|span|strong|sub|sup|time|u|var)\s*>',
                                 re.I)
_MYSLNIK_POCZATEK = re.compile(r'^[ \t]+(?=[–—][ \t])')
_MYSLNIK_W_ZNACZNIKU = re.compile(r'^[–—][ \t]')
_SPACJA_KONIEC = re.compile(r'(?<=[^\s>])[ \t]+$')


def html(s):
    """Fragment HTML → ten sam fragment z polską typografią w tekście (znaczniki i atrybuty bez zmian)."""
    czesci = _ZNACZNIK.split(s)
    out = []
    for i, cz in enumerate(czesci):
        if i % 2:
            out.append(cz)
            continue
        t = _popraw(cz, '&nbsp;')
        if i + 1 < len(czesci) and _ZNACZNIK_LINIOWY.match(czesci[i + 1]):
            t = _JEDNOLITEROWE_KONIEC.sub(r'\1&nbsp;', t)
            # „tekst <em>– dalej</em>”: półpauza na początku elementu liniowego
            if i + 2 < len(czesci) and _MYSLNIK_W_ZNACZNIKU.match(czesci[i + 2]):
                t = _SPACJA_KONIEC.sub('&nbsp;', t)
        # „</strong> – dalej”: półpauza po elemencie liniowym
        if i > 0 and _ZAMYKAJACY_LINIOWY.match(czesci[i - 1]):
            t = _MYSLNIK_POCZATEK.sub('&nbsp;', t)
        out.append(t)
    return ''.join(out)


def esc(s, quote=False):
    """Czysty tekst → HTML (escape) z polską typografią."""
    return html(_html.escape(str(s), quote=quote))


def tekst(s):
    """Czysty tekst → tekst z twardymi spacjami U+00A0 (dla danych wstawianych przez textContent)."""
    return _popraw(str(s), NBSP)


_SP = r'(?: |&nbsp;|\u00a0)'
MARKI = ['ERGO' + _SP + 'Życie' + _SP + 'w' + _SP + 'Biznesie', 'Aura' + _SP + 'Expert', 'BeautyPolisa', 'Beauty' + _SP + 'Razem',
         'ERGO' + _SP + 'Razem', 'ERGO' + _SP + 'Hesti(?:a|i|ą|ę)', 'ENEL-(?:&#8288;|\u2060)?MED', 'LUX' + _SP + 'MED', 'Colonnade',
         'Tax' + _SP + 'Protect', 'Leadenhall', 'CEU', 'Lloyd’s']
_MARKI_RE = re.compile(r'(?<![\w-])(' + '|'.join(MARKI) + r')(?![\w-])')


def marki(s):
    """Nazwy marek i produktów w tekście fragmentu HTML → <span translate="no">…</span> (raport 16, 3.2: tłumacz przeglądarki
    nie przekłada nazw). Tekst w elemencie z translate="no" zostaje bez zmian (idempotentne)."""
    out, wewn = [], 0
    for i, cz in enumerate(_ZNACZNIK.split(s)):
        if i % 2:
            if re.match(r'<[a-zA-Z][^>]*\btranslate="no"', cz):
                wewn += 1
            elif wewn and re.match(r'</', cz):
                wewn -= 1
            elif wewn and re.match(r'<[a-zA-Z]', cz) and not cz.endswith('/>'):
                wewn += 1
            out.append(cz)
        else:
            out.append(cz if wewn else _MARKI_RE.sub(r'<span translate="no">\1</span>', cz))
    return ''.join(out)


def porownaj(s):
    """Tekst do porównań brzmienia w kontrolach: twarda spacja = spacja, pauza = półpauza, łącznik słowa usunięty."""
    return re.sub(r'[ \t]+', ' ', str(s).replace(NBSP, ' ').replace('—', '–').replace('⁠', ''))


# Ta sama typografia w przeglądarce (reguły 1–3 i marki; dane z JSON wstawiane przez textContent) – kopiowana do skryptów stron
# przez generatory albo ręcznie z tego miejsca.
JS = r'''function bpTypografia(s){
  var nb=' ';
  return String(s)
    .replace(/(^|[^\w.])(sp\.) z o\.o\./g,'$1$2'+nb+'z'+nb+'o.o.')
    .replace(/\b(ERGO|LUX|Aura) (Hesti[aię]|Hestią|Razem|Życie|MED|Expert)\b/g,'$1'+nb+'$2')
    .replace(/(\d) (?=\d{3}(?!\d))/g,'$1'+nb)
    .replace(/(\d) (zł|tys\.|mln|osób|osoby|pozycji|pozycje|miesiącach|miesięcy|lat|dniach|dni|r\.)(?![0-9A-Za-zĄĆĘŁŃÓŚŹŻąćęłńóśźż])/g,'$1'+nb+'$2')
    .replace(/(^|[^\w.])(poz\.|art\.|pkt|ust\.|§) (?=\d)/g,'$1$2'+nb)
    .replace(/(^|[^\w.])(nr|Nr) (?=[0-9A-ZĄĆĘŁŃÓŚŹŻ])/g,'$1$2'+nb)
    .replace(/(\S) ([–—])(?= )/g,'$1'+nb+'$2')
    .replace(/(^|[\s(„ ])([aiouwzAIOUWZ]) (?=\S)/g,'$1$2'+nb)
    .replace(/(^|[\s(„ ])([aiouwzAIOUWZ]) (?=\S)/g,'$1$2'+nb);
}'''


def kontrola():
    przyklady = [
        ('i w jednym', 'i&nbsp;w&nbsp;jednym'),
        ('Abonamenty ENEL-MED lub LUX MED dla pracowników, partnerów i rodzin.',
         'Abonamenty ENEL-MED lub LUX&nbsp;MED dla pracowników, partnerów i&nbsp;rodzin.'),
        ('od 1 532 zł rocznie', 'od 1&nbsp;532&nbsp;zł rocznie'),
        ('Zespół: od 58 zł za osobę / mies.', 'Zespół: od 58&nbsp;zł za osobę&nbsp;/&nbsp;mies.'),
        ('ERGO Razem: od 57 zł / mies.', 'ERGO&nbsp;Razem: od 57&nbsp;zł&nbsp;/&nbsp;mies.'),
        ('Lista nr 1 – gabinety kosmetyczne i fryzjerskie', 'Lista nr&nbsp;1&nbsp;– gabinety kosmetyczne i&nbsp;fryzjerskie'),
        ('także na liście nr 2, poz. 17', 'także na liście nr&nbsp;2, poz.&nbsp;17'),
        ('program nr WA50/003353/24/A', 'program nr&nbsp;WA50/003353/24/A'),
        ('nr telefonu', 'nr telefonu'),
        ('Aura Expert sp. z o.o. – agent', 'Aura&nbsp;Expert sp.&nbsp;z&nbsp;o.o.&nbsp;– agent'),
        ('1 000 000 zł w 2017 r.', '1&nbsp;000&nbsp;000&nbsp;zł w&nbsp;2017&nbsp;r.'),
        ('do 12 miesięcy, 8 pozycji, 5 osób', 'do 12&nbsp;miesięcy, 8&nbsp;pozycji, 5&nbsp;osób'),
        ('dla każdej osoby — tylko dyplom', 'dla każdej osoby&nbsp;– tylko dyplom'),
        ('200 tys. zł', '200&nbsp;tys.&nbsp;zł'),
        ('<a href="#a i b">a i b</a> z <strong>w</strong>', '<a href="#a i b">a&nbsp;i&nbsp;b</a> z&nbsp;<strong>w</strong>'),
        ('znajdziesz w <a href="#x">słowniku</a>', 'znajdziesz w&nbsp;<a href="#x">słowniku</a>'),
        ('razem z <a class="bp-termin" href="#k">kartą</a> i <br>', 'razem z&nbsp;<a class="bp-termin" href="#k">kartą</a> i <br>'),
        ('Oblicz składkę w <a href="#k">kalkulatorze</a>', 'Oblicz składkę w&nbsp;<a href="#k">kalkulatorze</a>'),
        ('już&nbsp;w domu', 'już&nbsp;w&nbsp;domu'),
        ('6–&#8288;8 osób', '6–&#8288;8&nbsp;osób'),
        ('+48 504 400 901', '+48&nbsp;504&nbsp;400&nbsp;901'),
        ('2026-11-16 i 00-950 Warszawa', '2026-11-16 i&nbsp;00-950&nbsp;Warszawa'),
        ('NIP 5252645060, REGON 363541990, pod numerem 0000599840, lokal 28', 'NIP&nbsp;5252645060, REGON&nbsp;363541990, pod numerem&nbsp;0000599840, lokal&nbsp;28'),
        ('np. składka, L4, OWU...', 'np. składka, L4, OWU…'),
        ('<strong>A</strong> – b', '<strong>A</strong>&nbsp;– b'),
        ('Trzy warianty <em>– składka</em>', 'Trzy warianty&nbsp;<em>– składka</em>'),
        ('ERGO Razem <em>– grupa otwarta</em>', 'ERGO&nbsp;Razem&nbsp;<em>– grupa otwarta</em>'),
        ('<a href="#x">6</a>–8 osób i <br> – x', '<a href="#x">6</a>–8&nbsp;osób i <br> – x'),
    ]
    bledy = []
    for wej, ocz in przyklady:
        wyn = html(wej)
        if wyn != ocz:
            bledy.append('%r → %r (oczekiwano %r)' % (wej, wyn, ocz))
        if html(wyn) != wyn:
            bledy.append('nie idempotentne: %r' % wej)
        if porownaj(_html.unescape(re.sub(r'<[^>]+>', '', wyn))) != porownaj(_html.unescape(re.sub(r'<[^>]+>', '', wej))).replace('...', '…'):
            bledy.append('zmienione brzmienie: %r' % wej)
    m = marki('Tax Protect (Colonnade) i ERGO&nbsp;Razem, <span translate="no">LUX MED</span>')
    if m != ('<span translate="no">Tax Protect</span> (<span translate="no">Colonnade</span>) i <span translate="no">ERGO&nbsp;Razem</span>, '
             '<span translate="no">LUX MED</span>') or marki(m) != m:
        bledy.append('marki(): %r' % m)
    if tekst('i w domu') != 'i w domu':
        bledy.append('tekst(): U+00A0')
    return bledy


if __name__ == '__main__':
    import sys
    b = kontrola()
    print('\n'.join('BŁĄD: ' + x for x in b) or 'OK – reguły typografii (przykłady i idempotencja)')
    sys.exit(1 if b else 0)
