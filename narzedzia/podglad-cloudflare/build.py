#!/usr/bin/env python3
"""Paczka podglądu na Cloudflare Workers (statyczne pliki + hasło w Workerze).
Wyjście: scratchpad/cf-podglad/public/ – pełne dokumenty HTML (z własnym <head>), linki przepięte na makiety."""
import re, shutil, pathlib
REPO = pathlib.Path(__file__).resolve().parents[2]
V3 = REPO / 'docs/koncepcja/design/v3'
OUT = pathlib.Path(__file__).resolve().parent / 'public'
if OUT.exists(): shutil.rmtree(OUT)
(OUT / 'img').mkdir(parents=True); (OUT / 'strefa').mkdir()
for p in (V3 / 'img').glob('*.webp'): shutil.copy(p, OUT / 'img' / p.name)
shutil.copy(REPO / 'BeautyPolisa_logo_podstawowe_poziome.png', OUT / 'logo.png')
shutil.copy(V3 / 'strefa/strefa.css', OUT / 'strefa/strefa.css')
PRODUKTY = ['oc-beauty', 'tax-protect', 'utrata-dochodu']

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
for name in PRODUKTY:
    f = V3 / f'{name}.html'
    if f.exists():
        s = f.read_text(encoding='utf-8').replace('../../../../BeautyPolisa_logo_podstawowe_poziome.png', 'logo.png')
        (OUT / f'{name}.html').write_text(finish(s, ''), encoding='utf-8')
for f in (V3 / 'strefa').glob('*.html'):
    s = f.read_text(encoding='utf-8').replace('../../../../../BeautyPolisa_logo_podstawowe_poziome.png', '../logo.png')
    s = s.replace('../makieta-v3.html', '../index.html')
    for name in PRODUKTY:
        s = s.replace(f'../{name}.html', f'../{name}.html')
    (OUT / 'strefa' / f.name).write_text(finish(s.replace('../index.html', '__IDX__'), '../').replace('__IDX__', '../index.html'), encoding='utf-8')
(OUT / 'robots.txt').write_text('User-agent: *\nDisallow: /\n')
bad = [(p.name, m) for p in OUT.rglob('*.html') for m in re.findall(r'(?:src|href)="([^"]*(?:\.\./\.\./|makieta-v3)[^"]*)"', p.read_text(encoding='utf-8'))]
print('złe ścieżki:', bad[:5])
print(sorted(str(p.relative_to(OUT)) for p in OUT.rglob('*') if p.is_file()))
