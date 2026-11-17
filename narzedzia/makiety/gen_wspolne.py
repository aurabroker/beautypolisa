#!/usr/bin/env python3
"""Wspólne komponenty stron publicznych v3 (BeautyPolisa, design „old money glass”): strona główna, 6 stron produktów + slownik.html.

Jeden szablon -> bloki w każdej stronie (wstawiane/odświeżane między znacznikami):
  <!-- gen:menu-produkty -->  pozycja „Ubezpieczenia” w .main-nav: link (bez JS) -> przycisk disclosure + panel #menu-produkty
  <!-- gen:menu-mobilne -->   góra szuflady <details class="menu">: „Oblicz składkę OC” + lista 6 produktów z ceną (albo opisem ceny)
  <!-- gen:pasek-akcji -->    pasek akcji na telefonie (< 768 px): kontekstowa akcja + „Zadzwoń”
  <!-- gen:wspolne-css -->    style obu komponentów (koniec <head>)
  <!-- gen:wspolne-js -->     skrypt obu komponentów (koniec <body>)

Bieżący produkt (z nazwy pliku) dostaje aria-current="page". Linki względne: na stronie głównej „#…”,
na podstronach „makieta-v3.html#…” (produkcyjnie / i /#…). Fakty (ceny, linki) tylko z listy PRODUKTY.
Teksty z PRODUKTY przechodzą przez typografia.html() (raport 16, 3.1: twarde spacje w „100 osób”, „zł / mies.”, „ERGO Razem”),
a nazwy marek w menu dostają translate="no" (typografia.marki()). Blok gen:wspolne-css niesie też wzorce wspólne bazowego CSS stron
(raport 16, rozdz. 3.2: safe-area, dotyk, hover linków, ruch tylko transform/opacity; raport 15: Z5, Z15, Z16, Z18, Z22, Z27, Z40, Z41) –
stoi na końcu <head>, więc nadpisuje ręczne kopie bazowego CSS na 8 stronach.
Uruchomienie: python3 -I gen_wspolne.py [--check]   (--check: kończy się błędem, gdy bloki są nieaktualne)
"""
import pathlib, re, sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import typografia  # noqa: E402

V3 = pathlib.Path(__file__).resolve().parents[2] / 'docs/koncepcja/design/v3'
HOME = 'makieta-v3.html'
TEL_HREF, TEL_TXT = 'tel:+48504400901', '+48&nbsp;504&nbsp;400&nbsp;901'
NNW_URL = 'https://bit.ly/szkolneNNW2026'

# id = slug strony / wartość ?produkt= w formularzu kontaktu na stronie głównej
PRODUKTY = [
    dict(id='oc-beauty', plik='oc-beauty.html', ikona='lux-oc-beauty', nazwa='OC dla branży beauty',
         zdanie='OC za szkody wyrządzone klientom podczas zabiegów – składka ze stałej taryfy ERGO Hestia.',
         cena=['od 400&nbsp;zł rocznie'], krotko='od 400&nbsp;zł rocznie'),
    dict(id='tax-protect', plik='tax-protect.html', ikona='lux-tax-protect', nazwa='Tax Protect',
         zdanie='Ochrona karnoskarbowa dla właściciela i&nbsp;podatkowa dla salonu (Colonnade).',
         cena=['od 1&nbsp;532&nbsp;zł rocznie'], krotko='od 1&nbsp;532&nbsp;zł rocznie'),
    dict(id='utrata-dochodu', plik='utrata-dochodu.html', ikona='lux-utrata-dochodu', nazwa='Utrata dochodu',
         zdanie='Prywatne L4: miesięczne świadczenie, gdy choroba lub wypadek wyłączą Cię z&nbsp;pracy – Lloyd’s przez Leadenhall i&nbsp;CEU.',
         cena=['Składkę wylicza ubezpieczyciel po ocenie ryzyka'], krotko='składkę wylicza ubezpieczyciel po ocenie ryzyka'),
    dict(id='nnw-dzieci', plik='nnw-dzieci.html', ikona='lux-nnw-dzieci', nazwa='NNW dla dzieci',
         zdanie='Ochrona dziecka od następstw nieszczęśliwych wypadków – całą dobę (Colonnade).',
         # „za osobę” – jak w kartach powiązanych i na podstronie NNW (dziecko lub student; raport 15, Z40)
         cena=['od 40&nbsp;zł rocznie za osobę'], dopisek='Zakup online u&nbsp;Colonnade', krotko='od 40&nbsp;zł rocznie za osobę'),
    dict(id='grupowe-ergo', plik='grupowe-ergo.html', ikona='lux-grupowe-ergo', nazwa='Grupowe ERGO dla beauty',
         zdanie='Ubezpieczenie na życie dla zespołu (2–&#8288;100 osób) albo ERGO Razem dla Ciebie i&nbsp;rodziny.',
         # główna kwota: zespół (ERGO Życie w Biznesie) – jak kafelek i podstrona; 57 zł zawsze z nazwą ERGO Razem
         cena=['Zespół: od 58&nbsp;zł za osobę / mies.', 'ERGO Razem: od 57&nbsp;zł / mies.'], krotko='od 58&nbsp;zł za osobę / mies.'),
    # podstrona od 15.11.2026 (decyzja zleceniodawcy, 10 §17.5 wariant b): w makiecie opieka-medyczna.html (strona budowana przez
    # opieka-medyczna/build.py), produkcyjnie /ubezpieczenia/opieka-medyczna. Bez kwot: stawki na podstronie to wyłącznie przykłady
    # (decyzja 13.11.2026 – cennika programu jeszcze nie ma), więc zamiast ceny – kto ją przygotuje.
    dict(id='opieka-medyczna', plik='opieka-medyczna.html', ikona='lux-opieka-medyczna', nazwa='Opieka medyczna',
         zdanie='Abonamenty ENEL-&#8288;MED lub LUX&nbsp;MED dla pracowników, partnerów i&nbsp;rodzin.',
         cena=['Cenę przygotuje doradca'], krotko='cenę przygotuje doradca'),
]

# akcja główna paska na telefonie (kontekstowo)
def akcja(strona, H):
    if strona in ('makieta-v3.html', 'oc-beauty.html'):
        return f'<a class="pa-glowny" href="{H}#kalkulator">Oblicz składkę<span class="sr-only"> OC</span></a>'
    if strona == 'tax-protect.html':
        return f'<a class="pa-glowny" href="{H}#kalkulator-tax">Oblicz składkę<span class="sr-only"> Tax Protect</span></a>'
    if strona == 'nnw-dzieci.html':
        # widoczna etykieta mówi, dokąd prowadzi link (strona Colonnade); ↗ + aria-describedby: nowa karta
        return (f'<a class="pa-glowny" href="{NNW_URL}" target="_blank" rel="noopener" aria-describedby="opis-zewn">'
                '<span>Kup u&nbsp;Colonnade<span class="sr-only"> – NNW dla dzieci</span></span>'
                '<svg class="pa-zewn" viewBox="0 0 24 24" aria-hidden="true"><path d="M9 5h10v10M19 5 6 18"/></svg></a>')
    if strona == 'slownik.html':
        # słownik pojęć nie jest produktem – formularz kontaktu bez tematu
        return f'<a class="pa-glowny" href="{HOME}#kontakt">Zapytaj doradcę</a>'
    if strona == 'opieka-medyczna.html':
        # opieka medyczna ma własny formularz zapytania na podstronie (#zapytanie)
        return '<a class="pa-glowny" href="#zapytanie">Zapytaj doradcę<span class="sr-only"> o&nbsp;opiekę medyczną</span></a>'
    slug = strona[:-5]
    return f'<a class="pa-glowny" href="{HOME}?produkt={slug}#kontakt">Zapytaj doradcę</a>'

# slownik.html (słownik pojęć) – strona tworzona przez slownik/gen_strona.py, bloki jak na stronach produktów (bez bieżącego produktu);
# opieka-medyczna.html – strona tworzona przez opieka-medyczna/build.py z tymi samymi funkcjami (tu: kontrola i odświeżenie bloków)
STRONY = ['makieta-v3.html', 'oc-beauty.html', 'tax-protect.html', 'utrata-dochodu.html', 'nnw-dzieci.html', 'grupowe-ergo.html',
          'opieka-medyczna.html', 'slownik.html']

def tx(h):
    """Tekst z PRODUKTY (HTML) → polska typografia + translate="no" na nazwach marek."""
    return typografia.marki(typografia.html(h))


def href_produktu(p, strona, H):
    if p['plik']:
        return p['plik']
    return '#kontakt' if strona == HOME else f'{HOME}?produkt={p["id"]}#kontakt'

def attrs(p, strona):
    a = ' aria-current="page"' if p['plik'] == strona else ''
    if not p['plik'] and strona == HOME:
        a += f' data-produkt="{p["id"]}"'
    return a

def menu_produkty(strona, H):
    biez = ' data-biezacy' if strona not in (HOME, 'slownik.html') else ''   # słownik nie należy do sekcji „Ubezpieczenia”
    items = []
    for p in PRODUKTY:
        tu = '<span class="mega-tu" aria-hidden="true">Jesteś tutaj</span>' if p['plik'] == strona else ''
        i = 'mp-' + p['id']
        ceny = ''.join(f'<span class="mega-cena">{tx(c)}</span>' for c in p['cena'])
        if p.get('dopisek'):
            ceny += f'<span class="mega-dop">{tx(p["dopisek"])}</span>'
        items.append(
            f'                <li><a class="mega-item" href="{href_produktu(p, strona, H)}"{attrs(p, strona)} aria-labelledby="{i}-n" aria-describedby="{i}-d {i}-c">'
            f'<svg class="lux-icon lux-icon--md" aria-hidden="true"><use href="#{p["ikona"]}"/></svg>'
            f'<span class="mega-text"><span class="mega-name" id="{i}-n">{tx(p["nazwa"])}{tu}</span>'
            f'<span class="mega-desc" id="{i}-d">{tx(p["zdanie"])}</span><span class="mega-price" id="{i}-c">{ceny}</span></span></a></li>')
    return '\n'.join([
        f'          <li class="nav-produkty"{biez}>',
        '            <!-- bez JS: link do sekcji produktów; skrypt (gen:wspolne-js) zamienia go na przycisk aria-expanded + aria-controls -->',
        f'            <a class="nav-produkty-btn" href="{H}#ubezpieczenia">Ubezpieczenia</a>',
        '            <div class="mega" id="menu-produkty" hidden>',
        '              <div class="mega-head"><p class="mega-title">Ubezpieczenia dla branży beauty</p>'
        f'<a class="mega-all" href="{H}#ubezpieczenia">Wszystkie ubezpieczenia</a></div>',
        '              <ul class="mega-grid">',
        *items,
        '              </ul>',
        '              <div class="mega-foot">'
        f'<a class="btn btn-navy" href="{H}#kalkulator">Oblicz składkę OC</a>'
        f'<a class="btn btn-ghost" href="{H}#kalkulator-tax">Oblicz składkę Tax Protect</a></div>',
        '            </div>',
        '          </li>',
    ])

def menu_mobilne(strona, H):
    rows = []
    for p in PRODUKTY:
        rows.append(
            f'            <li><a href="{href_produktu(p, strona, H)}"{attrs(p, strona)}>'
            f'<svg class="lux-icon lux-icon--sm" aria-hidden="true"><use href="#{p["ikona"]}"/></svg>'
            f'<span class="mm-text"><span class="mm-name">{tx(p["nazwa"])}</span><span class="mm-price">{tx(p["krotko"])}</span></span></a></li>')
    return '\n'.join([
        f'          <a class="btn btn-navy mm-oblicz" href="{H}#kalkulator">Oblicz składkę OC</a>',
        '          <p class="mm-tytul" id="mm-produkty-t">Ubezpieczenia</p>',
        '          <ul class="mm-produkty" aria-labelledby="mm-produkty-t">',
        *rows,
        '          </ul>',
    ])

def pasek(strona, H):
    return '\n'.join([
        '<!-- Pasek akcji na telefonie (< 768 px, wysokość okna > 500 px): pokazuje go skrypt gen:wspolne-js po przewinięciu poza pierwszy ekran;',
        '     chowa się przy polu formularza / klawiaturze, przy widocznym pasku ceny kalkulatora (.calc-peek), kalkulatorze OC, wyszukiwarkach, formularzu kontaktu,',
        '     karcie końcowej i stopce. Bez JS zostaje ukryty (te same akcje są w treści). -->',
        '<aside class="pasek-akcji" id="pasek-akcji" aria-label="Szybkie akcje" hidden>',
        '  ' + akcja(strona, H),
        f'  <a class="pa-tel" href="{TEL_HREF}"><svg class="pa-ikona" viewBox="0 0 24 24" aria-hidden="true"><path d="M6.6 3.5 9 3l1.7 4.3-2.2 1.5a11.5 11.5 0 0 0 6.7 6.7l1.5-2.2L21 15l-.5 2.4A2.5 2.5 0 0 1 18 19.5 15.5 15.5 0 0 1 4.5 6 2.5 2.5 0 0 1 6.6 3.5Z"/></svg>'
        f'<span class="pa-tel-txt">Zadzwoń<span class="pa-nr"><span class="sr-only">: </span>{TEL_TXT}</span></span></a>',
        '</aside>',
    ])

CSS = r'''<style>
/* ===== Wspólne komponenty stron publicznych (gen_wspolne.py – nie edytuj ręcznie) ===== */
/* --- menu „Ubezpieczenia” (≥ 75em – 1200 px przy domyślnej czcionce 16 px; przy 20–24 px próg rośnie razem z etykietami): wzorzec disclosure, panel ivory bez backdrop-filter (nie liczy się do limitu tafli) --- */
.main-nav .nav-produkty-btn{display:inline-flex;align-items:center;gap:8px;min-height:44px;margin:0;padding:0 10px;background:none;border:0;border-radius:var(--radius-btn);font:500 var(--text-xs)/1 var(--font-caps);letter-spacing:var(--tracking-nav);text-transform:uppercase;text-decoration:none;color:var(--color-ink);white-space:nowrap;cursor:pointer}
.main-nav .nav-produkty-btn:hover,.main-nav .nav-produkty-btn[aria-expanded="true"],.nav-produkty[data-biezacy] > .nav-produkty-btn{color:var(--color-navy);text-decoration:underline;text-underline-offset:6px;text-decoration-color:var(--color-gold)}
.nav-produkty-btn svg{width:10px;height:10px;fill:none;stroke:currentColor;stroke-width:1.6;transition:transform var(--bp-dur-2) var(--ease-lux)}
.nav-produkty-btn[aria-expanded="true"] svg{transform:rotate(180deg)}
.mega{position:absolute;left:0;right:0;top:calc(100% + 10px);z-index:2;max-height:calc(100vh - 116px);overflow-y:auto;overscroll-behavior:contain;padding:22px 28px 22px;background:var(--color-ivory);border:1px solid rgba(184,151,90,.55);border-radius:var(--radius-card);box-shadow:0 0 0 1px rgba(42,59,104,.07),0 2px 4px rgba(20,28,51,.1),0 18px 40px -20px rgba(20,28,51,.6),inset 0 1px 0 rgba(255,255,255,.75)}
.mega[hidden]{display:none}
.mega-head{display:flex;align-items:baseline;justify-content:space-between;gap:24px;padding-bottom:12px;border-bottom:1px solid var(--color-gold)}
.mega-title{margin:0;font:500 var(--text-xs)/1.3 var(--font-caps);letter-spacing:var(--tracking-label);text-transform:uppercase;color:var(--color-taupe)}
.main-nav .mega a{display:revert;min-height:0;padding:0;font:inherit;letter-spacing:normal;text-transform:none;white-space:normal;color:inherit;text-decoration:none}
.main-nav .mega .mega-all{display:inline-flex;align-items:center;min-height:24px;font:500 var(--text-sm)/1.3 var(--font-sans);color:var(--color-navy);text-decoration:underline;text-decoration-color:var(--color-gold);text-underline-offset:5px;transition:text-decoration-thickness var(--bp-dur-1)}
/* hover: „Wszystkie ubezpieczenia” i przycisk z data-biezacy (podkreślony już w spoczynku) – grubsza linia (raport 16, 3.1) */
.main-nav .mega .mega-all:hover,.nav-produkty[data-biezacy] > .nav-produkty-btn:hover{text-decoration-thickness:2px}
.main-nav .mega-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:4px 20px;margin:14px 0 0;padding:0;list-style:none}
.main-nav .mega .mega-item{display:grid;grid-template-columns:32px minmax(0,1fr);column-gap:16px;align-items:start;height:100%;padding:14px 14px 16px;border-radius:var(--radius-card);color:var(--color-ink);transition:background-color var(--bp-dur-1)}
.main-nav .mega .mega-item:hover{background:var(--color-parchment)}
.main-nav .mega .mega-item:hover .mega-name{text-decoration:underline;text-decoration-color:var(--color-gold);text-underline-offset:5px;text-decoration-thickness:1px}
.main-nav .mega .mega-item[aria-current="page"]{background:var(--color-parchment);box-shadow:inset 2px 0 0 var(--color-gold)}
.mega-item .lux-icon{margin-top:2px;color:var(--color-navy)}
.mega-text{display:grid;gap:4px}
.mega-name{display:flex;flex-wrap:wrap;align-items:baseline;gap:4px 10px;font:500 1.3rem/1.15 var(--font-serif);color:var(--color-navy)}
.mega-tu{font:500 var(--text-xs)/1.2 var(--font-caps);letter-spacing:var(--tracking-label);text-transform:uppercase;color:var(--color-taupe)}
.mega-desc{font:400 var(--text-sm)/1.45 var(--font-sans);color:var(--color-taupe)}
.mega-price{display:grid;gap:2px;margin-top:2px;font:500 var(--text-sm)/1.4 var(--font-sans);color:var(--color-ink);font-variant-numeric:lining-nums tabular-nums}
.mega-dop{font-weight:400;color:var(--color-taupe)}
.mega-foot{display:flex;flex-wrap:wrap;justify-content:flex-end;gap:12px;margin-top:14px;padding-top:16px;border-top:1px solid var(--bp-line-gold-soft)}
.main-nav .mega .btn{display:inline-flex;align-items:center;justify-content:center;min-height:48px;padding:12px 24px;font:500 var(--text-xs)/1.2 var(--font-caps);letter-spacing:var(--tracking-label);text-transform:uppercase;text-decoration:none;white-space:nowrap}
.main-nav .mega .btn-navy,.main-nav .mega .btn-navy:hover{color:var(--color-ivory)}
.main-nav .mega .btn-ghost,.main-nav .mega .btn-ghost:hover{color:var(--color-navy)}
@media (max-width:74.99em){.mega{display:none!important}}
/* --- szuflada (< 75em): „Oblicz składkę OC” na górze + 6 produktów z ceną --- */
.menu-panel .btn.mm-oblicz{width:100%;margin:4px 0 14px}
.mm-tytul{margin:0;padding:4px 0 2px;font:500 var(--text-xs)/1.3 var(--font-caps);letter-spacing:var(--tracking-label);text-transform:uppercase;color:var(--color-taupe)}
.mm-produkty{margin:0 0 6px;padding:0;list-style:none}
.menu-panel .mm-produkty a{display:grid;grid-template-columns:22px minmax(0,1fr);align-items:center;column-gap:14px;min-height:52px;padding:8px 0;border-bottom:1px solid var(--bp-line-gold-soft);font:500 var(--text-body)/1.3 var(--font-sans);letter-spacing:0;text-transform:none;text-decoration:none;color:var(--color-ink)}
.menu-panel .mm-produkty a:hover .mm-name{text-decoration:underline;text-decoration-color:var(--color-gold);text-underline-offset:5px}
.menu-panel .mm-produkty a[aria-current="page"]{margin-inline:-10px;padding-inline:10px;background:var(--color-parchment);box-shadow:inset 2px 0 0 var(--color-gold)}
.mm-text{display:grid;gap:1px;min-width:0}
@media (min-width:600px){.mm-text{display:flex;align-items:baseline;justify-content:space-between;gap:16px}}
.mm-price{font:400 var(--text-sm)/1.35 var(--font-sans);color:var(--color-taupe);font-variant-numeric:lining-nums tabular-nums}
@media (min-width:600px){.mm-price{flex:none;max-width:55%;text-align:right}}
/* --- pasek akcji na telefonie: jedno nieprzezroczyste tło midnight (bez backdrop-filter), safe-area --- */
.pasek-akcji{display:none}
@media (max-width:767px){
  html.has-pasek{scroll-padding-bottom:calc(92px + env(safe-area-inset-bottom))}
  html.has-pasek .pasek-akcji{position:fixed;left:max(12px,env(safe-area-inset-left));right:max(12px,env(safe-area-inset-right));bottom:calc(10px + env(safe-area-inset-bottom));z-index:var(--bp-z-sticky);display:flex;flex-wrap:wrap;gap:6px;padding:6px;background:var(--color-midnight);border:1px solid rgba(217,192,137,.5);border-radius:var(--radius-card);box-shadow:0 14px 30px -12px rgba(20,28,51,.75);transform:translateY(calc(100% + 24px + env(safe-area-inset-bottom)));visibility:hidden;transition:transform var(--bp-dur-3) var(--ease-lux),visibility 0s linear var(--bp-dur-3)}
  html.has-pasek .pasek-akcji[data-on="1"]{transform:none;visibility:visible;transition:transform var(--bp-dur-3) var(--ease-lux),visibility 0s}
  .pasek-akcji a{display:flex;align-items:center;justify-content:center;gap:8px;min-height:48px;padding:6px 12px;border-radius:var(--radius-btn);border:1px solid transparent;font:500 var(--text-xs)/1.2 var(--font-caps);letter-spacing:var(--tracking-nav);text-transform:uppercase;text-align:center;text-decoration:none}
  /* przy powiększonym tekście (WCAG 1.4.4) przyciski przechodzą do dwóch wierszy zamiast obcinać etykietę */
  .pasek-akcji .pa-glowny{flex:1 1 8rem;min-width:0;background:var(--color-ivory);color:var(--color-navy);border-color:var(--color-ivory)}
  .pasek-akcji .pa-glowny:hover{background:var(--color-parchment)}
  .pasek-akcji .pa-tel{flex:1 0 auto;max-width:100%;color:var(--color-ivory);border-color:rgba(217,192,137,.6);padding-inline:10px}
  .pasek-akcji .pa-tel:hover{border-color:var(--color-gold-light)}
  .pasek-akcji :focus-visible{outline:2px solid var(--color-gold-light);outline-offset:2px}
  .pa-ikona{width:18px;height:18px;flex:none;fill:none;stroke:var(--color-gold-light);stroke-width:1.5;stroke-linejoin:round}
  .pa-zewn{width:12px;height:12px;flex:none;fill:none;stroke:currentColor;stroke-width:2;stroke-linecap:round}
  .pa-tel-txt{display:grid;justify-items:start;gap:2px;text-align:left}
  .pa-nr{font:500 var(--text-xs)/1.1 var(--font-sans);letter-spacing:.02em;text-transform:none;color:var(--color-gold-light);white-space:nowrap;font-variant-numeric:lining-nums tabular-nums}
}
@media (max-width:359px){.pasek-akcji a{padding-inline:8px;letter-spacing:.1em}.pa-ikona{display:none}}
@media (prefers-reduced-motion:reduce){.pasek-akcji,.pasek-akcji[data-on="1"],.nav-produkty-btn svg{transition:none!important}}
@media (forced-colors:active){.mega,.pasek-akcji{border-color:CanvasText}.main-nav .mega .mega-item[aria-current="page"]{outline:2px solid Highlight}}
@media print{.pasek-akcji,.mega{display:none!important}}
/* ===== Wzorce wspólne bazowego CSS stron (raport 16, rozdz. 3.2; raport 15: Z5, Z15, Z16, Z18, Z27, Z41) =====
   Blok stoi na końcu <head>, więc nadpisuje ręczne kopie bazowego CSS (tax-protect.html i kopie, opieka-medyczna/common.css).
   Ruch tylko na transform i opacity (zmiany samych kolorów – tylko malowanie); prefers-reduced-motion wyłącza przejścia jak dotąd. */
/* safe-area przy viewport-fit=cover: w poziomie na iPhonie treść, belka i szuflada nie wchodzą pod wycięcie ekranu */
.container{padding-left:max(var(--bp-gutter),env(safe-area-inset-left));padding-right:max(var(--bp-gutter),env(safe-area-inset-right))}
.menu-panel{padding-bottom:calc(22px + env(safe-area-inset-bottom))}
.site-footer{padding-bottom:calc(40px + env(safe-area-inset-bottom))}
.klauzula{width:min(calc(100% - 32px - env(safe-area-inset-left) - env(safe-area-inset-right)),780px)}
/* dotyk: bez powiększania podwójnym tapnięciem, stonowane podświetlenie tapnięcia, bez „odbijania” strony na gładziku */
a,button,summary,label,input,select,textarea,[role="button"]{touch-action:manipulation}
html{-webkit-tap-highlight-color:rgba(42,59,104,.12)}
:is(.dark,.pasek-akcji,.end-card){-webkit-tap-highlight-color:rgba(217,192,137,.2)}
@media (pointer:fine){html{overscroll-behavior-y:none}}
/* długie słowa i tekst powiększony do 200%: hero bez przewijania w poziomie (minmax(0,1fr), kwoty łamią się poniżej 540 px) */
.hero-panel{grid-template-columns:minmax(0,1fr)}
h1,h2,h3,.lead{overflow-wrap:break-word}
@media (max-width:539px){.figures dd{white-space:normal}.figures > div,.figures > div:first-child{flex-wrap:wrap}.figures dt{min-width:0}}
.mock-note{white-space:normal}   /* adnotacje makiety łamią się przy powiększonym tekście */
/* logo kurczy się przy dużej czcionce domyślnej (24 px), przycisk „Menu” zostaje w belce */
.brand{flex:0 1 auto;min-width:0}
.brand small{white-space:normal}
.menu{flex:none}
/* hover: linki w treści, okruszki, „Wróć…” (.link-quiet) – grubsza linia; szuflada i „Menu” – kolor i ramka */
.link-quiet,.crumbs a{transition:text-decoration-thickness var(--bp-dur-1),color var(--bp-dur-1)}
@media (hover:hover){
  a:not(.btn):not(.link-lux):hover{text-decoration-thickness:2px}
  .menu-panel > a:not(.btn):hover{color:var(--color-navy);text-decoration:underline;text-decoration-color:var(--color-gold);text-underline-offset:5px}
  .menu summary:hover{border-color:var(--color-navy)}
}
/* .btn-ghost-dark: hover mocniejszy od spoczynku – tekst zostaje ivory, wzmacnia się ramka i tło */
.btn-ghost-dark:hover{color:var(--color-ivory);border-color:var(--color-gold-light);background-color:rgba(217,192,137,.14)}
/* Z18: stan „wciśnięty” przycisków */
.btn:active,.pasek-akcji a:active{transform:translateY(1px)}
.btn-navy:active{background-color:var(--color-midnight);border-color:var(--color-midnight)}
.btn-ghost:active{background-color:var(--color-parchment);border-color:var(--color-navy)}
.btn-ivory:active{background-color:#E2D7C5}
.btn-ghost-dark:active{background-color:rgba(217,192,137,.24)}
/* Z27: podkreślenia nawigacji, stopki i pytań pojawiają się płynnie (kolor linii), w nawigacji linia się rysuje (scaleX); logo – krycie */
.footer-nav a,.faq summary,.product-link{text-decoration-line:underline;text-decoration-color:transparent;text-decoration-thickness:1px;transition:color var(--bp-dur-2),text-decoration-color var(--bp-dur-2) var(--ease-lux)}
.footer-nav a{text-underline-offset:5px}
.faq summary,.product-link{text-underline-offset:6px}
.main-nav > ul > li > a,.client-link{position:relative}
.main-nav > ul > li > a::after,.client-link::after{content:"";position:absolute;left:10px;right:10px;bottom:10px;height:1px;background:var(--color-gold);transform:scaleX(0);transform-origin:left;transition:transform .4s var(--ease-lux);pointer-events:none}
.client-link::after{left:18px;right:6px}
@media (hover:hover){
  .main-nav > ul > li > a:hover,.client-link:hover{text-decoration:none}
  .main-nav > ul > li > a:hover::after,.client-link:hover::after{transform:scaleX(1)}
}
.brand img{transition:opacity var(--bp-dur-2)}
.brand:hover img{opacity:.78}
/* kreska .link-lux i podkreślenie .btn-navy: transform zamiast width i background-size (bez przeliczania układu) */
.link-lux::after{transform-origin:left;transition:transform var(--bp-dur-2) var(--ease-lux)}
.link-lux:hover::after{width:28px;transform:scaleX(1.5715)}
@media (hover:hover) and (pointer:fine){
  .btn-navy{position:relative;background-image:none}
  .btn-navy::after{content:"";position:absolute;left:28px;right:28px;bottom:10px;height:1px;background:var(--color-gold-light);transform:scaleX(0);transition:transform .5s var(--ease-lux);pointer-events:none}
  .header-cta .btn-navy::after{left:20px;right:20px}
  .btn-navy:hover::after,.btn-navy:focus-visible::after{transform:scaleX(1)}
}
/* rama panelu hero: opacity i scale zamiast clip-path */
@keyframes bp-frame-in{from{opacity:0;transform:scale(.985)}to{opacity:1;transform:none}}
@media screen and (prefers-reduced-motion:no-preference){.hero-panel.frame::before{animation-name:bp-frame-in}}
/* długie listy rozwijane (zabiegi OC, pełne tabele) bez animacji block-size; FAQ – świadomy wyjątek (krótkie odpowiedzi) */
@supports selector(::details-content){.zdetails::details-content,.full::details-content,.full-list::details-content{transition:none}}
/* Z15: pytania na płaskim tle (poza sceną ze zdjęciem) bez rozmycia – szkło zawsze leży na zdjęciu (§6) */
.faq.glass:not(.scene .faq){-webkit-backdrop-filter:none;backdrop-filter:none;background:var(--bp-glass-ivory-tint)}
/* Z16: karta końcowa – płaski token zamiast gradientu */
.end-card{background:var(--color-navy)}
/* Z5: cele dotyku 44 px na ekranach dotykowych (okruszki, „Informacje o agencie…”, odsyłacze „także na liście nr …”) */
@media (pointer:coarse){
  .crumbs a{min-height:44px}
  .legal-idd > summary{min-height:44px;padding-block:10px}
  a.z-inna{display:inline-flex;align-items:center;min-height:44px}
}
/* Z1, Z2, Z3, Z7, Z29: pierwszy ekran podstron (.page-hero). Hero zajmuje ekran (min-height 100svh), panel stoi pośrodku
   i kończy się co najmniej 24 px nad dolną krawędzią okna. Od 64em panel na całą szerokość kontenera: z lewej tekst i akcje
   (.hero-copy), z prawej liczby (.hero-aside) – bez pustego pasa. Na telefonie lead to jedno zdanie z twardym faktem (dalsze zdania
   – .hero-note pod przyciskami), mniejszy H1, ciaśniejszy panel i okruszki zwinięte do „‹ rodzic”: główny przycisk w 1. ekranie od 320×640 */
.page-hero{padding-top:clamp(92px,7vw,104px);padding-bottom:24px}
/* siatka tylko od 48em: poniżej scena ma przyklejoną warstwę tła (::before, position:sticky) – w siatce byłaby elementem siatki */
@media (min-width:48em){.page-hero{min-height:100svh;display:grid;align-items:center}}
.page-hero .hero-copy{display:grid;gap:inherit;min-width:0;align-content:start}
.page-hero .hero-aside{display:grid;gap:12px;min-width:0;align-content:center}
/* H1 panelu hero podstron – token --text-h1-podstrona (tokens-v3.css, DESIGN.md; Z37, runda 2: bez lokalnych rozmiarów); definicja
   także tu, bo strony mają własne kopie :root */
:root{--text-h1-podstrona:clamp(2.25rem,.6rem + 4.4vw,4.4rem);--text-h3-kafel:clamp(1.9rem,1.45rem + 1.4vw,2.3rem)}
.page-hero .hero-panel h1{font-size:var(--text-h1-podstrona)}
.page-hero .hero-note{font-size:var(--text-sm);line-height:1.6;color:var(--color-ink);max-width:42rem}
@media (min-width:64em){
  .page-hero .hero-panel{max-width:none;grid-template-columns:minmax(0,1fr) minmax(14rem,18rem);column-gap:clamp(36px,4.5vw,72px);row-gap:20px;padding-block:clamp(28px,3vw,48px)}
  .page-hero .hero-aside{padding-left:clamp(28px,3vw,44px);border-left:1px solid rgba(184,151,90,.55)}
  .page-hero .hero-aside .figures{flex-direction:column;padding-top:0;border-top:0}
  .page-hero .hero-aside .figures > div,.page-hero .hero-aside .figures > div:first-child{padding:16px 0;border-left:0}
  .page-hero .hero-aside .figures > div + div{border-top:1px solid var(--bp-line-gold-soft)}
  .page-hero .hero-aside .figures dd{font-size:clamp(1.9rem,1.2rem + 1.1vw,2.4rem);white-space:normal}
}
@media (max-width:47.99em){
  .page-hero{padding-top:94px}
  .page-hero .hero-panel{gap:16px;padding:22px 20px 24px}
  .page-hero .crumbs li:not(:nth-last-child(2)){display:none}
  .page-hero .crumbs li:nth-last-child(2)::before{content:none}
  .page-hero .crumbs li:nth-last-child(2) a::before{content:"‹\00a0";content:"‹\00a0" / ""}
}
/* Z37: jedna skala nagłówków (dok. 10 §4, DESIGN.md): H2 = --text-h2 (34–54 px), H3 = --text-h3 (26,4 px; wyjątek – nazwa kafelka
   produktu na stronie głównej: --text-h3-kafel), H4 = --text-serif-md; bez lokalnych rozmiarów w CSS stron. Nagłówek okna klauzuli zostaje mniejszy. */
main h2:not(.klauzula h2){font-size:var(--text-h2)}
main h3:not(.product h3){font-size:var(--text-h3)}
main h4:not(.bp-bez-skali){font-size:var(--text-serif-md)}
/* Z12: tafle od lewej do prawej linii kontenera (bez jednostronnego pasa przy 1440 px); miara tekstu w środku ograniczona */
.zrules,.mind,.scope-aside,.variants-box,.plan-panel,.cta-row + .ext-note{max-width:none}
:is(.zrules,.mind,.scope-aside) > :is(p,ul,h3,.cta-row){max-width:62rem}
/* Z8: sekcja zamykająca podstron (section#zamkniecie, section--flush-top) – „Inne ubezpieczenia” (H2) i karta końcowa jako bloki
   jednej sekcji; pytania – osobna sekcja przed nią (runda 2 weryfikacji: razem miały 2,23–2,55 ekranu) */
.zamkniecie-blok{margin-top:clamp(56px,7vw,104px)}
/* Z10: rytm sekcji – od 64em szerokości i 37.5em wysokości okna każda sekcja główna (poza hero i sekcjami-dokumentami z K6:
   listy zabiegów, klauzula, hasła słownika) ma dokładnie 1 albo 2 ekrany. Skrypt (gen:wspolne-js) mierzy wysokość treści przy
   przyciętym padding-block (dawniej clamp(72px,11vw,168px), czyli 158 px przy 1440 px) i ustawia data-ekrany="1" albo "2";
   sekcja, która mieści się w ekranie dopiero przy 24 px odstępu (data-ciasno), dostaje 1 ekran zamiast 2 (tolerancja ≈ 1 ekran:
   do 1,1 – raport 15, N1); treść stoi pośrodku sekcji. Bez JS, na telefonie i w niskim oknie – naturalna wysokość jak dotąd */
@media (min-width:64em) and (min-height:37.5em){
  main section[data-ekrany]{display:flex;flex-direction:column;justify-content:center;padding-block:clamp(48px,7svh,96px)}
  main section[data-ekrany][data-ciasno]{padding-block:24px}
  main section[data-ekrany] > *{flex:none}
  main section[data-ekrany="1"]{min-height:100svh}
  main section[data-ekrany="2"]{min-height:200svh}
}
.end-card h3{max-width:40rem}
/* Z38 (raport 15): jedna karta pełna i jedna notka poza szkłem – cztery warianty szkła z D14 bez zmian. Karta: ivory, złota linia 1 px,
   promień 6 px, jeden cień (dawniej 6 wyglądów: z cieniem albo bez, linia 35 / 50% albo żadna, przezroczysta .mind). Notka: pergamin 55%,
   lewa złota kreska 2 px, bez cienia i promienia. Tokeny także w tokens-v3.css i DESIGN.md (4.5) */
:root{--bp-karta-tlo:var(--color-ivory);--bp-karta-linia:rgba(184,151,90,.5);--bp-karta-cien:0 24px 48px -38px rgba(20,28,51,.45);
  --bp-notka-tlo:rgba(237,229,216,.55);--bp-notka-kreska:var(--color-gold);
  --bp-link-podkreslenie:var(--color-gold);--bp-link-podkreslenie-ciemne:rgba(217,192,137,.7)}
main :is(.clause,.op-card,.rel-card,.route,.scope-card,.apply,figure.ledger,.mind,.panel,.sl-narzedzia,li.job,.vcard,.cmp-attr,.sl-litera){
  background-color:var(--bp-karta-tlo);border:1px solid var(--bp-karta-linia);border-radius:var(--radius-card);box-shadow:var(--bp-karta-cien)}
main :is(.scope-extra,.scope-aside,.haslo-przyklad){background:var(--bp-notka-tlo);border:0;border-left:2px solid var(--bp-notka-kreska);border-radius:0;box-shadow:none}
/* Z39 (raport 15): jeden zestaw elementów w roli przycisku – para .btn (bez zmian); jeden chip do nawigacji po liście i filtrów (skok do
   list OC, indeks A–Z słownika, podpowiedzi specjalizacji – dawniej 3 wyglądy); jeden link-akcja: zwykły tekst z podkreśleniem, bez etykiety
   w wersalikach z kreską („KALKULATOR ——”); jeden token podkreślenia linków na jasnym tle i jeden na ciemnym; linki w tekście granatowe */
main :is(.zjump a,.sl-az a[href],.spec-quick button){display:inline-flex;align-items:center;justify-content:center;gap:8px;min-height:44px;
  border:1px solid var(--bp-karta-linia);border-radius:var(--radius-btn);background:rgba(255,255,255,.55);color:var(--color-navy);
  font:500 var(--text-sm)/1.2 var(--font-sans);letter-spacing:normal;text-transform:none;text-decoration:none;cursor:pointer}
main :is(.zjump a,.spec-quick button){padding:8px 14px}
main .zjump a span{font:inherit;font-weight:400;color:inherit}
main :is(.sl-az a:not([href]),.sl-az-off){font:400 var(--text-sm)/1.2 var(--font-sans)}
@media (hover:hover) and (pointer:fine){main :is(.zjump a,.sl-az a[href],.spec-quick button):hover{border-color:var(--color-navy);background:rgba(255,255,255,.85);text-decoration:none}}
main .link-lux{gap:8px;font:500 var(--text-sm)/1.4 var(--font-sans);letter-spacing:normal;text-transform:none;
  text-decoration:underline;text-decoration-color:var(--bp-link-podkreslenie);text-decoration-thickness:1px;text-underline-offset:5px}
main .link-lux::after{content:none}
main :is(p,dd) a:not([class]){color:var(--color-navy);text-decoration:underline;text-decoration-color:var(--bp-link-podkreslenie);text-decoration-thickness:1px;text-underline-offset:4px}
/* na ciemnym tle (sceny .dark, wynik kalkulatora, karta promocji i karta Strefy): tekst parchment, podkreślenie złote 70%; jasne
   powierzchnie wewnątrz ciemnej sceny (kafle produktów .ledger--light, jasne szkło) – jak na jasnym tle */
main :is(.dark,.result,.promo,.member-card) :is(.link-lux,.link-quiet,p a:not([class]),dd a:not([class])){color:var(--color-parchment);text-decoration-color:var(--bp-link-podkreslenie-ciemne)}
main .dark :is(.ledger--light,.glass:not(.glass--dark)) :is(.link-lux,.link-quiet,p a:not([class]),dd a:not([class])){color:var(--color-navy);text-decoration-color:var(--bp-link-podkreslenie)}
@media (hover:hover) and (pointer:fine){main :is(.link-lux,.link-quiet,p a:not([class]),dd a:not([class])):hover{text-decoration-thickness:2px}}
/* Z41: szuflada poniżej 768 px – pełny ekran (ivory, bez backdrop-filter), stan otwarcia widoczny w przycisku („Zamknij”, ikona X – skrypt) */
@media (max-width:767px){
  html:has(details.menu[open]){overflow:hidden}
  .site-header:has(details.menu[open]) .header-bar{-webkit-backdrop-filter:none;backdrop-filter:none;background:var(--color-ivory)}
  .site-header:has(details.menu[open]) .brand,details.menu[open] > summary{position:relative;z-index:2}
  details.menu[open] .menu-panel{position:fixed;inset:0;z-index:1;max-height:none;height:100dvh;border:0;border-radius:0;box-shadow:none;background:var(--color-ivory);
    padding:calc(110px + env(safe-area-inset-top)) max(var(--bp-gutter),env(safe-area-inset-right)) calc(28px + env(safe-area-inset-bottom)) max(var(--bp-gutter),env(safe-area-inset-left))}
}
details.menu[open] > summary{border-color:var(--color-navy)}
@media (prefers-reduced-motion:reduce){.btn:active,.pasek-akcji a:active{transform:none}}
@media (forced-colors:active){.main-nav > ul > li > a::after,.client-link::after,.btn-navy::after{background:CanvasText}}
</style>'''

JS = r'''<script>
/* Wspólne komponenty (gen_wspolne.py – nie edytuj ręcznie) */
/* Menu „Ubezpieczenia”: link -> przycisk disclosure (aria-expanded + aria-controls, bez role=menu).
   Zamykanie: Esc (fokus wraca na przycisk), klik poza, Tab poza panel, schowanie nagłówka, przewinięcie o > 120 px. Najechanie otwiera z opóźnieniem tylko jako dodatek. */
(function(){
  var li=document.querySelector('.nav-produkty'), panel=document.getElementById('menu-produkty');
  if(!li||!panel) return;
  var link=li.querySelector('.nav-produkty-btn'), hdr=document.querySelector('.site-header');
  var btn=document.createElement('button');
  btn.type='button';btn.className='nav-produkty-btn';btn.setAttribute('aria-expanded','false');btn.setAttribute('aria-controls','menu-produkty');
  btn.innerHTML='Ubezpieczenia<svg viewBox="0 0 10 10" aria-hidden="true"><path d="M1.5 3.5 5 7l3.5-3.5"/></svg>';
  link.parentNode.replaceChild(btn,link);
  var via=null, tOpen=0, tClose=0, y0=0, mqHover=window.matchMedia('(hover:hover) and (pointer:fine)');
  function isOpen(){return !panel.hidden}
  function open(how){clearTimeout(tClose);if(isOpen()){if(how==='click')via='click';return}panel.hidden=false;btn.setAttribute('aria-expanded','true');via=how;y0=window.scrollY}
  function close(focus){clearTimeout(tOpen);clearTimeout(tClose);if(!isOpen())return;panel.hidden=true;btn.setAttribute('aria-expanded','false');via=null;if(focus)btn.focus()}
  btn.addEventListener('click',function(){if(isOpen()&&via!=='hover')close(false);else open('click')});
  document.addEventListener('keydown',function(e){if(e.key==='Escape'&&isOpen()){var inside=li.contains(document.activeElement);close(inside)}});
  document.addEventListener('click',function(e){if(isOpen()&&!li.contains(e.target))close(false)});
  li.addEventListener('focusout',function(e){if(isOpen()&&e.relatedTarget&&!li.contains(e.relatedTarget))close(false)});
  panel.addEventListener('click',function(e){if(e.target.closest('a[href]'))close(false)});
  li.addEventListener('pointerenter',function(e){if(e.pointerType!=='mouse'||!mqHover.matches)return;clearTimeout(tClose);if(!isOpen())tOpen=setTimeout(function(){open('hover')},180)});
  li.addEventListener('pointerleave',function(e){if(e.pointerType!=='mouse')return;clearTimeout(tOpen);if(isOpen()&&via==='hover'&&!li.contains(document.activeElement))tClose=setTimeout(function(){close(false)},320)});
  /* przewinięcie: zamyka przy schowanym nagłówku, a panel otwarty klikiem/klawiaturą także po 120 px od otwarcia
     (fokus na przycisku blokuje chowanie nagłówka); fokus w samym panelu – panel zostaje, fokus nie jest przenoszony */
  window.addEventListener('scroll',function(){
    if(!isOpen())return;
    if(hdr&&hdr.dataset.hidden==='1'){close(false);return}
    if(via!=='hover'&&!panel.contains(document.activeElement)&&Math.abs(window.scrollY-y0)>120)close(false);
  },{passive:true});
  var mqWide=window.matchMedia('(min-width:75em)');
  function onWide(){if(!mqWide.matches)close(false)}
  if(mqWide.addEventListener)mqWide.addEventListener('change',onWide);else if(mqWide.addListener)mqWide.addListener(onWide);
})();

/* Szuflada menu (details.menu): widoczny stan otwarcia – etykieta „Zamknij” i ikona X; bez JS – „Menu” w obu stanach (raport 15, Z41) */
(function(){
  var menu=document.querySelector('details.menu'); if(!menu) return;
  var lab=menu.querySelector('.menu-label'), path=menu.querySelector('summary svg path'); if(!lab||!path) return;
  var d0=path.getAttribute('d'), d1='M6 6l12 12M18 6 6 18', t0=lab.textContent;
  function sync(){var o=menu.open;lab.textContent=o?'Zamknij':t0;path.setAttribute('d',o?d1:d0)}
  menu.addEventListener('toggle',sync);sync();
})();

/* Z10 (raport 15): rytm sekcji 1 albo 2 ekrany – od 64em × 37.5em. Pomiar: wszystkie sekcje główne naraz w stanie pomiaru
   (data-ekrany="0": przycięty padding, bez min-height), odczyt wysokości, potem zapis 1 (do 1,1 ekranu) / 2 (do 2,02 ekranu; powyżej –
   bez atrybutu,
   np. listy zabiegów i hasła słownika – K6). Ponownie po wczytaniu fontów, przy zmianie rozmiaru okna; nie przy rozwijaniu
   treści (pytania, pełne listy), żeby sekcja nie skakała o ekran */
(function(){
  var mq=window.matchMedia('(min-width:64em) and (min-height:37.5em)'), raf=0;
  var sekcje=[].slice.call(document.querySelectorAll('main section')).filter(function(s){
    return !(s.parentElement&&s.parentElement.closest('main section'))&&!s.matches('.scene--hero,.page-hero,[data-ekrany-auto]');
  });
  if(!sekcje.length) return;
  function licz(){
    raf=0;
    if(!mq.matches){sekcje.forEach(function(s){s.removeAttribute('data-ekrany')});return}
    sekcje.forEach(function(s){s.setAttribute('data-ekrany','0');s.removeAttribute('data-ciasno')});
    var H=window.innerHeight, T1=1.1*H, T2=2.02*H, m=sekcje.map(function(s){var cs=getComputedStyle(s);
      return {h:s.getBoundingClientRect().height,p:parseFloat(cs.paddingTop)+parseFloat(cs.paddingBottom)}});
    sekcje.forEach(function(s,i){
      var h=m[i].h, t=h-m[i].p+48, n='', c=false;
      if(h<=T1)n='1';else if(t<=T1){n='1';c=true}else if(h<=T2)n='2';else if(t<=T2){n='2';c=true}
      if(n){s.setAttribute('data-ekrany',n);if(c)s.setAttribute('data-ciasno','')}else s.removeAttribute('data-ekrany');
    });
  }
  function req(){if(!raf)raf=requestAnimationFrame(licz)}
  licz();
  window.addEventListener('resize',req);
  window.addEventListener('load',req);
  if(document.fonts&&document.fonts.ready)document.fonts.ready.then(req);
})();

/* Pasek akcji na telefonie (< 768 px): po przewinięciu poza pierwszy ekran; chowa się przy polu formularza/klawiaturze,
   otwartej szufladzie menu, widocznym pasku ceny kalkulatora (.calc-peek), formularzu kontaktu, karcie końcowej, akcjach otwarcia i stopce,
   a także nad formularzami kalkulatora OC (form#calc), wyszukiwarką zabiegów (.zsearch) i wyszukiwarką specjalizacji (#spec-form) – raport 15, Z22 */
(function(){
  var bar=document.getElementById('pasek-akcji'); if(!bar||!('IntersectionObserver' in window)) return;
  /* niskie okno (telefon w poziomie, ≤ 500 px – jak nagłówek): bez paska */
  var root=document.documentElement, mq=window.matchMedia('(max-width:767px) and (min-height:501px)'), menu=document.querySelector('details.menu');
  var FIELD='input:not([type=checkbox]):not([type=radio]):not([type=button]):not([type=submit]):not([type=reset]):not([type=range]):not([type=file]):not([type=image]),textarea,select,[contenteditable="true"]';
  var targets=[].slice.call(document.querySelectorAll('.calc-peek,.lead-form,.end-card,.hero-actions,.tariff-actions,.site-footer,form#calc,.zsearch,#spec-form'));
  var seen=new Set(), io=null, ticking=false;
  function typing(){var a=document.activeElement;return !!(a&&a.matches&&a.matches(FIELD))}
  function keyboard(){var v=window.visualViewport;return !!(v&&v.height<window.innerHeight*0.72)}
  /* widoczność wymusza tylko fokus z klawiatury (po tapnięciu fokus jest zdejmowany – tel:, nowa karta, bfcache) */
  function kbdFocus(){try{return !!bar.querySelector(':focus-visible')}catch(e){return false}}
  /* fokus z klawiatury w pasku, a pasek ma zniknąć: fokus na początek bieżącej sekcji, dopiero potem inert */
  function focusSekcja(){
    var el=document.elementFromPoint(window.innerWidth/2,Math.round(window.innerHeight*0.4));
    var s=(el&&!bar.contains(el)&&el.closest('section,footer,article'))||document.querySelector('main')||document.body;
    var t=s.querySelector('h1,h2,h3')||s;
    if(!t.hasAttribute('tabindex')){t.setAttribute('tabindex','-1');t.addEventListener('blur',function(){t.removeAttribute('tabindex')},{once:true})}
    t.focus({preventScroll:true});
  }
  function update(){
    ticking=false;if(!io)return;
    var past=window.scrollY>window.innerHeight*0.9;
    var hide=!past||seen.size>0||!!(menu&&menu.open);
    var on=!hide&&!typing()&&!keyboard();
    if(!on&&kbdFocus()){if(hide)focusSekcja();else on=true}
    bar.dataset.on=on?'1':'0';bar.inert=!on;
  }
  function req(){if(!ticking){ticking=true;requestAnimationFrame(update)}}
  function start(){
    root.classList.add('has-pasek');bar.hidden=false;
    io=new IntersectionObserver(function(entries){
      entries.forEach(function(en){if(en.isIntersecting&&en.target.getClientRects().length)seen.add(en.target);else seen.delete(en.target)});
      req();
    },{threshold:0});
    targets.forEach(function(t){io.observe(t)});req();
  }
  function stop(){if(io){io.disconnect();io=null}seen.clear();bar.hidden=true;bar.dataset.on='0';root.classList.remove('has-pasek')}
  function sync(){if(mq.matches){if(!io)start()}else stop()}
  bar.addEventListener('click',function(e){var a=e.target.closest&&e.target.closest('a');if(a&&e.detail)setTimeout(function(){a.blur();req()},0)});
  window.addEventListener('pageshow',function(){var a=document.activeElement;if(a&&bar.contains(a)&&!kbdFocus())a.blur();req()});
  window.addEventListener('scroll',req,{passive:true});
  window.addEventListener('resize',req);
  if(window.visualViewport)window.visualViewport.addEventListener('resize',req);
  document.addEventListener('focusin',req);
  document.addEventListener('focusout',function(){setTimeout(req,0)});
  if(menu)menu.addEventListener('toggle',req);
  if(mq.addEventListener)mq.addEventListener('change',sync);else if(mq.addListener)mq.addListener(sync);
  sync();
})();
</script>'''

def blok(nazwa, tresc):
    return f'<!-- gen:{nazwa} -->\n{tresc}\n<!-- /gen:{nazwa} -->'

def wstaw(s, nazwa, tresc, kotwica_re, indent=''):
    """Odświeża blok między znacznikami; przy pierwszym uruchomieniu zastępuje kotwicę (regex, 1 trafienie)."""
    pocz, kon = f'<!-- gen:{nazwa} -->', f'<!-- /gen:{nazwa} -->'
    nowy = f'{indent}{pocz}\n{tresc}\n{indent}{kon}'
    if pocz in s:
        i = s.index(pocz); i = s.rfind('\n', 0, i) + 1
        j = s.index(kon) + len(kon)
        return s[:i] + nowy + s[j:]
    m = list(re.finditer(kotwica_re, s, flags=re.M))
    assert len(m) >= 1, (nazwa, kotwica_re)
    m = m[0]
    return s[:m.start()] + nowy + s[m.end():]

SPRITE_OPIEKA = None

def przetworz(strona, s):
    """Odświeża bloki gen:* jednej strony (tekst -> tekst). Używa go też slownik/gen_strona.py."""
    global SPRITE_OPIEKA
    if SPRITE_OPIEKA is None:
        home = (V3 / HOME).read_text(encoding='utf-8')
        SPRITE_OPIEKA = re.search(r'  <symbol id="lux-opieka-medyczna".*?</symbol>', home, flags=re.S).group(0)
    H = '' if strona == HOME else HOME
    hk = re.escape(H)
    # 1. menu desktop: pierwsza pozycja „Ubezpieczenia” w .main-nav
    s = wstaw(s, 'menu-produkty', menu_produkty(strona, H),
              r'^          <li><a href="' + hk + r'#ubezpieczenia">Ubezpieczenia</a></li>$', '          ')
    # 2. szuflada: pozycja „Ubezpieczenia” zastąpiona przyciskiem OC i listą produktów
    s = wstaw(s, 'menu-mobilne', menu_mobilne(strona, H),
              r'^          <a href="' + hk + r'#ubezpieczenia"><svg class="lux-icon lux-icon--sm" aria-hidden="true"><use href="#lux-oc-beauty"/></svg>Ubezpieczenia</a>$', '          ')
    # 3. pasek akcji (+ brakujące symbole sprite) – po sprite strony
    bez_bloku = re.sub(r'<!-- gen:pasek-akcji -->.*?<!-- /gen:pasek-akcji -->', '', s, flags=re.S)
    tresc = pasek(strona, H)
    if 'id="lux-opieka-medyczna"' not in bez_bloku:
        tresc += ('\n<svg class="sprite" xmlns="http://www.w3.org/2000/svg" width="0" height="0" aria-hidden="true" focusable="false">\n'
                  '  <!-- symbole potrzebne menu „Ubezpieczenia” (kopie z makieta-v3.html) -->\n' + SPRITE_OPIEKA + '\n</svg>')
    s = wstaw(s, 'pasek-akcji', tresc, r'(?<=\n</svg>\n)(?=<script>)')
    s = s.replace('<!-- /gen:pasek-akcji --><script>', '<!-- /gen:pasek-akcji -->\n<script>')
    # 4./5. style i skrypt
    s = wstaw(s, 'wspolne-css', CSS, r'^(?=</head>)')
    s = wstaw(s, 'wspolne-js', JS, r'^(?=</body>)')
    # wstawki przed </head> i </body> muszą kończyć się nową linią
    s = s.replace('<!-- /gen:wspolne-css --></head>', '<!-- /gen:wspolne-css -->\n</head>').replace('<!-- /gen:wspolne-js --></body>', '<!-- /gen:wspolne-js -->\n</body>')
    for n in ('menu-produkty', 'menu-mobilne', 'pasek-akcji', 'wspolne-css', 'wspolne-js'):
        assert s.count(f'<!-- gen:{n} -->') == 1 and s.count(f'<!-- /gen:{n} -->') == 1, (strona, n)
    assert s.count('id="menu-produkty"') == 1 and s.count('id="pasek-akcji"') == 1
    if strona == 'nnw-dzieci.html':
        assert 'id="opis-zewn"' in s
    return s

def main():
    check = '--check' in sys.argv
    zle = []
    for strona in STRONY:
        p = V3 / strona; s = p.read_text(encoding='utf-8'); o = s
        s = przetworz(strona, s)
        if s != o:
            zle.append(strona)
            if not check:
                p.write_text(s, encoding='utf-8')
    if check and zle:
        print('NIEAKTUALNE:', ', '.join(zle)); sys.exit(1)
    print(('Zaktualizowano: ' + ', '.join(zle)) if zle else 'Bez zmian (bloki aktualne)')

if __name__ == '__main__':
    main()
