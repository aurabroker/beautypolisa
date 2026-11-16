#!/usr/bin/env python3
"""Paczka podglądu na Cloudflare Workers (statyczne pliki + hasło w Workerze).
Wyjście: public/ obok skryptu – pełne dokumenty HTML (z własnym <head>), linki przepięte na makiety.

Strony: makieta-v3.html (jako index.html), strony z listy STRONY (produkty, opieka medyczna, słownik pojęć) i wszystkie
strefa/*.html (logowanie, panel, Dam pracę, szkolenia). PDF-y z design/v3/dokumenty/ – tylko te, do których prowadzą linki
ze stron (15.11.2026: 2 listy zabiegów z oc-beauty.html, ok. 190 KB); całego katalogu (24 pliki, ok. 10,5 MB) nie – limit
rozmiaru Workera, patrz README, „Rozmiar paczki”. --bez-pdf: paczka bez PDF-ów.
Na końcu raport: złe ścieżki (repozytorium, makieta-v3.html) i linki względne do plików, których nie ma w paczce."""
import re, shutil, sys, pathlib
REPO = pathlib.Path(__file__).resolve().parents[2]
V3 = REPO / 'docs/koncepcja/design/v3'
OUT = pathlib.Path(__file__).resolve().parent / 'public'
Z_PDF = '--bez-pdf' not in sys.argv
if OUT.exists(): shutil.rmtree(OUT)
(OUT / 'img').mkdir(parents=True); (OUT / 'strefa').mkdir()
for p in (V3 / 'img').glob('*.webp'): shutil.copy(p, OUT / 'img' / p.name)
shutil.copy(REPO / 'BeautyPolisa_logo_podstawowe_poziome.png', OUT / 'logo.png')
shutil.copy(V3 / 'strefa/strefa.css', OUT / 'strefa/strefa.css')
shutil.copy(V3 / 'strefa/zakladki.js', OUT / 'strefa/zakladki.js')   # „Zakładki w Strefie” – wspólny skrypt panel/dam-prace/szkolenia
# strony obok index.html; produkty mają produkcyjnie adres /ubezpieczenia/<nazwa> (mapowany na plik podglądu)
PRODUKTY = ['oc-beauty', 'tax-protect', 'utrata-dochodu', 'nnw-dzieci', 'grupowe-ergo', 'opieka-medyczna']
STRONY = PRODUKTY + ['slownik']

def map_products(html, prefix):
    for name in PRODUKTY:
        if (V3 / f'{name}.html').exists():
            html = re.sub(r'href="/ubezpieczenia/%s(#[^"]*)?"' % name, lambda m: f'href="{prefix}{name}.html{m.group(1) or ""}"', html)
    return html

def finish(html, prefix):
    html = html.replace('makieta-v3.html', prefix + 'index.html')
    html = re.sub(r'href="/"', f'href="{prefix}index.html"', html)
    html = map_products(html, prefix)
    # podstrony docelowego serwisu, których jeszcze nie ma – nie wyprowadzają z podglądu
    html = re.sub(r'href="/(?!/)[^"]*"', 'href="#" data-podglad="podstrona w przygotowaniu"', html)
    if '<meta name="robots"' not in html:
        html = html.replace('<title>', '<meta name="robots" content="noindex, nofollow">\n<title>', 1)
    return html

s = (V3 / 'makieta-v3.html').read_text(encoding='utf-8').replace('../../../../BeautyPolisa_logo_podstawowe_poziome.png', 'logo.png')
(OUT / 'index.html').write_text(finish(s, ''), encoding='utf-8')
for name in STRONY:
    f = V3 / f'{name}.html'
    assert f.exists(), f
    s = f.read_text(encoding='utf-8').replace('../../../../BeautyPolisa_logo_podstawowe_poziome.png', 'logo.png')
    (OUT / f'{name}.html').write_text(finish(s, ''), encoding='utf-8')
for f in sorted((V3 / 'strefa').glob('*.html')):
    s = f.read_text(encoding='utf-8').replace('../../../../../BeautyPolisa_logo_podstawowe_poziome.png', '../logo.png')
    s = s.replace('../makieta-v3.html', '../index.html')
    (OUT / 'strefa' / f.name).write_text(finish(s.replace('../index.html', '__IDX__'), '../').replace('__IDX__', '../index.html'), encoding='utf-8')

# linki względne (href/src) z pominięciem kotwic, adresów zewnętrznych i ścieżek bezwzględnych
def wzgledne(p):
    for m in re.finditer(r'(?:src|href)="([^"]+)"', p.read_text(encoding='utf-8')):
        u = m.group(1).split('#')[0].split('?')[0]
        if u and not re.match(r'(?:[a-z]+:|/)', u):
            yield (p.parent / u).resolve()

if Z_PDF:   # tylko PDF-y, do których prowadzą strony
    for p in sorted(OUT.rglob('*.html')):
        for t in wzgledne(p):
            if t.suffix == '.pdf' and not t.exists():
                rel = t.relative_to(OUT.resolve())
                (OUT / rel).parent.mkdir(parents=True, exist_ok=True)
                shutil.copy(V3 / rel, OUT / rel)
(OUT / 'robots.txt').write_text('User-agent: *\nDisallow: /\n')
bad = [(p.name, m) for p in OUT.rglob('*.html') for m in re.findall(r'(?:src|href)="([^"]*(?:\.\./\.\./|makieta-v3)[^"]*)"', p.read_text(encoding='utf-8'))]
print('złe ścieżki:', bad[:5])
brak = sorted({(str(p.relative_to(OUT)), str(t.relative_to(OUT.resolve()))) for p in OUT.rglob('*.html') for t in wzgledne(p) if not t.exists()})
print('linki do plików spoza paczki (w podglądzie: 404 „Nie ma takiej strony”):', brak)
pliki = sorted(p for p in OUT.rglob('*') if p.is_file())
print(len(pliki), 'plików,', sum(p.stat().st_size for p in pliki), 'B:', [str(p.relative_to(OUT)) for p in pliki])
