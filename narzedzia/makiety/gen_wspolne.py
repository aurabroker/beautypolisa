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
Uruchomienie: python3 -I gen_wspolne.py [--check]   (--check: kończy się błędem, gdy bloki są nieaktualne)
"""
import pathlib, re, sys

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
         cena=['od 40&nbsp;zł rocznie za dziecko'], dopisek='Zakup online u&nbsp;Colonnade', krotko='od 40&nbsp;zł rocznie za dziecko'),
    dict(id='grupowe-ergo', plik='grupowe-ergo.html', ikona='lux-grupowe-ergo', nazwa='Grupowe ERGO dla beauty',
         zdanie='Ubezpieczenie na życie dla zespołu (2–&#8288;100 osób) albo ERGO Razem dla Ciebie i&nbsp;rodziny.',
         # główna kwota: zespół (ERGO Życie w Biznesie) – jak kafelek i podstrona; 57 zł zawsze z nazwą ERGO Razem
         cena=['Zespół: od 58&nbsp;zł za osobę / mies.', 'ERGO Razem: od 57&nbsp;zł / mies.'], krotko='od 58&nbsp;zł za osobę / mies.'),
    # podstrona od 15.11.2026 (decyzja zleceniodawcy, 10 §17.5 wariant b): w makiecie opieka-medyczna.html (strona budowana przez
    # opieka-medyczna/build.py), produkcyjnie /ubezpieczenia/opieka-medyczna. Bez kwot: stawki na podstronie to wyłącznie przykłady
    # (decyzja 13.11.2026 – cennika programu jeszcze nie ma), więc zamiast ceny – kto ją przygotuje.
    dict(id='opieka-medyczna', plik='opieka-medyczna.html', ikona='lux-opieka-medyczna', nazwa='Opieka medyczna',
         zdanie='Abonamenty ENEL-MED lub LUX&nbsp;MED dla pracowników, partnerów i&nbsp;rodzin.',
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
        ceny = ''.join(f'<span class="mega-cena">{c}</span>' for c in p['cena'])
        if p.get('dopisek'):
            ceny += f'<span class="mega-dop">{p["dopisek"]}</span>'
        items.append(
            f'                <li><a class="mega-item" href="{href_produktu(p, strona, H)}"{attrs(p, strona)} aria-labelledby="{i}-n" aria-describedby="{i}-d {i}-c">'
            f'<svg class="lux-icon lux-icon--md" aria-hidden="true"><use href="#{p["ikona"]}"/></svg>'
            f'<span class="mega-text"><span class="mega-name" id="{i}-n">{p["nazwa"]}{tu}</span>'
            f'<span class="mega-desc" id="{i}-d">{p["zdanie"]}</span><span class="mega-price" id="{i}-c">{ceny}</span></span></a></li>')
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
            f'<span class="mm-text"><span class="mm-name">{p["nazwa"]}</span><span class="mm-price">{p["krotko"]}</span></span></a></li>')
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
        '     chowa się przy polu formularza / klawiaturze, przy widocznym pasku ceny kalkulatora (.calc-peek), formularzu kontaktu,',
        '     karcie końcowej i stopce. Bez JS zostaje ukryty (te same akcje są w treści). -->',
        '<aside class="pasek-akcji" id="pasek-akcji" aria-label="Szybkie akcje" hidden>',
        '  ' + akcja(strona, H),
        f'  <a class="pa-tel" href="{TEL_HREF}"><svg class="pa-ikona" viewBox="0 0 24 24" aria-hidden="true"><path d="M6.6 3.5 9 3l1.7 4.3-2.2 1.5a11.5 11.5 0 0 0 6.7 6.7l1.5-2.2L21 15l-.5 2.4A2.5 2.5 0 0 1 18 19.5 15.5 15.5 0 0 1 4.5 6 2.5 2.5 0 0 1 6.6 3.5Z"/></svg>'
        f'<span class="pa-tel-txt">Zadzwoń<span class="pa-nr"><span class="sr-only">: </span>{TEL_TXT}</span></span></a>',
        '</aside>',
    ])

CSS = r'''<style>
/* ===== Wspólne komponenty stron publicznych (gen_wspolne.py – nie edytuj ręcznie) ===== */
/* --- menu „Ubezpieczenia” (≥ 1200 px): wzorzec disclosure, panel ivory bez backdrop-filter (nie liczy się do limitu tafli) --- */
.main-nav .nav-produkty-btn{display:inline-flex;align-items:center;gap:8px;min-height:44px;margin:0;padding:0 10px;background:none;border:0;border-radius:var(--radius-btn);font:500 var(--text-xs)/1 var(--font-caps);letter-spacing:var(--tracking-nav);text-transform:uppercase;text-decoration:none;color:var(--color-ink);white-space:nowrap;cursor:pointer}
.main-nav .nav-produkty-btn:hover,.main-nav .nav-produkty-btn[aria-expanded="true"],.nav-produkty[data-biezacy] > .nav-produkty-btn{color:var(--color-navy);text-decoration:underline;text-underline-offset:6px;text-decoration-color:var(--color-gold)}
.nav-produkty-btn svg{width:10px;height:10px;fill:none;stroke:currentColor;stroke-width:1.6;transition:transform var(--bp-dur-2) var(--ease-lux)}
.nav-produkty-btn[aria-expanded="true"] svg{transform:rotate(180deg)}
.mega{position:absolute;left:0;right:0;top:calc(100% + 10px);z-index:2;max-height:calc(100vh - 116px);overflow-y:auto;overscroll-behavior:contain;padding:22px 28px 22px;background:var(--color-ivory);border:1px solid rgba(184,151,90,.55);border-radius:var(--radius-card);box-shadow:0 0 0 1px rgba(42,59,104,.07),0 2px 4px rgba(20,28,51,.1),0 18px 40px -20px rgba(20,28,51,.6),inset 0 1px 0 rgba(255,255,255,.75)}
.mega[hidden]{display:none}
.mega-head{display:flex;align-items:baseline;justify-content:space-between;gap:24px;padding-bottom:12px;border-bottom:1px solid var(--color-gold)}
.mega-title{margin:0;font:500 var(--text-xs)/1.3 var(--font-caps);letter-spacing:var(--tracking-label);text-transform:uppercase;color:var(--color-taupe)}
.main-nav .mega a{display:revert;min-height:0;padding:0;font:inherit;letter-spacing:normal;text-transform:none;white-space:normal;color:inherit;text-decoration:none}
.main-nav .mega .mega-all{display:inline-flex;align-items:center;min-height:24px;font:500 var(--text-sm)/1.3 var(--font-sans);color:var(--color-navy);text-decoration:underline;text-decoration-color:var(--color-gold);text-underline-offset:5px}
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
@media (max-width:1199px){.mega{display:none!important}}
/* --- szuflada (< 1200 px): „Oblicz składkę OC” na górze + 6 produktów z ceną --- */
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
  var mqWide=window.matchMedia('(min-width:1200px)');
  function onWide(){if(!mqWide.matches)close(false)}
  if(mqWide.addEventListener)mqWide.addEventListener('change',onWide);else if(mqWide.addListener)mqWide.addListener(onWide);
})();

/* Pasek akcji na telefonie (< 768 px): po przewinięciu poza pierwszy ekran; chowa się przy polu formularza/klawiaturze,
   otwartej szufladzie menu, widocznym pasku ceny kalkulatora (.calc-peek), formularzu kontaktu, karcie końcowej, akcjach otwarcia i stopce */
(function(){
  var bar=document.getElementById('pasek-akcji'); if(!bar||!('IntersectionObserver' in window)) return;
  /* niskie okno (telefon w poziomie, ≤ 500 px – jak nagłówek): bez paska */
  var root=document.documentElement, mq=window.matchMedia('(max-width:767px) and (min-height:501px)'), menu=document.querySelector('details.menu');
  var FIELD='input:not([type=checkbox]):not([type=radio]):not([type=button]):not([type=submit]):not([type=reset]):not([type=range]):not([type=file]):not([type=image]),textarea,select,[contenteditable="true"]';
  var targets=[].slice.call(document.querySelectorAll('.calc-peek,.lead-form,.end-card,.hero-actions,.tariff-actions,.site-footer'));
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
