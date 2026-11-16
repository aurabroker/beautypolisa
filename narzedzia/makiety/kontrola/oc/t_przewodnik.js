#!/usr/bin/env node
// Strona główna (makieta-v3.html) po uwagach zleceniodawcy z 16.11.2026: przewodnik po krokach kalkulatora OC, większy przełącznik
// produktów (sekcja III) i osobne kafle produktów (sekcja II).
//   * przewodnik: kroki 1 rodzaj działalności → 2 liczba osób → 3 suma gwarancyjna; bieżący = pierwszy brakujący (kolejność dowolna –
//     np. najpierw suma), aria-current="step" tylko na bieżącym polu, wykonane – „✓” i „Gotowe”, dalsze – „dalej”; wiersz stanu jest
//     opisem grupy (aria-describedby); ta sama wskazówka pod polem wyniku (#wynik-krok) i na pasku ceny na telefonie (390 px);
//     komunikat #calc-status: dokładnie jeden przy każdej zmianie kroku (z „Krok N z 3”), żadnego przy kliknięciu, które kroku
//     ani wyniku nie zmienia; bez przewijania i bez przenoszenia fokusu; wiersz stanu w jednej linii, kafelki bieżącego kroku nie
//     przesuwają się po kliknięciu; jednorazowy puls obwódki (animacja krok-puls) – brak przy prefers-reduced-motion: reduce;
//     bez JS – brak podświetlenia, numerów i wskazówek, wszystkie pola widoczne.
//   * sekcja III: przełącznik „OC dla branży beauty / Tax Protect” – role tab/tablist, aria-selected, wysokość ≥ 88 px (≥ 76 px
//     poniżej 480 px), na telefonie cała szerokość kontenera.
//   * sekcja II: 6 kafli z odstępem ≥ 16 px w poziomie i w pionie, promień 10 px, bez backdrop-filter.
//   * 320, 390, 768, 1280, 1440 px: brak przewijania w poziomie, axe-core (WCAG 2.2 AA: wcag2a, wcag2aa, wcag21a, wcag21aa,
//     wcag22aa) na całej stronie – w stanie startowym i z bieżącym krokiem 2 (kalkulator po zaznaczeniu rodzaju działalności).
// Uruchom: node narzedzia/makiety/kontrola/oc/t_przewodnik.js   (kod wyjścia 1 przy błędzie; wymaga npm install w narzedzia/makiety)
'use strict';
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../../..');
const PAGE = 'file://' + (process.env.MAKIETA ? path.resolve(process.env.MAKIETA) : path.join(REPO, 'docs/koncepcja/design/v3/makieta-v3.html'));
const AXE = require.resolve('axe-core/axe.min.js');
const NB = ' ';
const SZER = [320, 390, 768, 1280, 1440];
const KROKI = ['kalk-rodzaje', 'kalk-osoby', 'kalk-sumy'];
const bledy = [];
let asercje = 0;
const ok = (war, opis) => { asercje++; if (!war) bledy.push(opis); };

// stan przewodnika z DOM
const stan = (p) => p.evaluate((ids) => ids.map((id) => {
  const f = document.getElementById(id);
  return { id, cur: f.getAttribute('aria-current'), stan: f.dataset.krokStan || null, nr: (f.querySelector('.krok-nr') || {}).textContent || null,
    st: (f.querySelector('.krok-stan') || {}).textContent || null, opis: f.getAttribute('aria-describedby') };
}), KROKI);
// rejestr zmian #calc-status (każda zmiana treści = jedno ogłoszenie)
const nasluch = (p) => p.evaluate(() => {
  window.__ogl = [];
  const s = document.getElementById('calc-status');
  new MutationObserver(() => window.__ogl.push(s.textContent)).observe(s, { childList: true, characterData: true, subtree: true });
});
const ogl = (p) => p.evaluate(() => window.__ogl.slice());
// klik bez przewijania przez Playwright (element.click() w stronie) – sprawdza, że przewodnik sam nie przewija ani nie przenosi fokusu
const klik = async (p, id) => { await p.evaluate((i) => document.getElementById(i).click(), id); await p.waitForTimeout(650); };
const puls = (p) => p.evaluate(() => document.getAnimations().filter((a) => a.animationName === 'krok-puls').map((a) => a.effect.target.id || (a.effect.target.closest && a.effect.target.closest('fieldset') || {}).id));

(async () => {
  const b = await chromium.launch();

  // ---------- 1. przewodnik (1280 px, ruch dozwolony)
  {
    const ctx = await b.newContext({ viewport: { width: 1280, height: 900 }, reducedMotion: 'no-preference' });
    const p = await ctx.newPage();
    const errs = []; p.on('pageerror', (e) => errs.push(e.message));
    await p.goto(PAGE);
    await p.waitForTimeout(400);
    let s = await stan(p);
    ok(s.map((x) => x.cur).join() === 'step,,', 'start: aria-current="step" tylko na rodzaju działalności: ' + JSON.stringify(s.map((x) => x.cur)));
    ok(s.map((x) => x.stan).join() === 'teraz,dalej,dalej', 'start: stany kroków teraz/dalej/dalej: ' + s.map((x) => x.stan));
    ok(s.map((x) => x.nr).join() === '1,2,3', 'start: numery w kółkach 1, 2, 3');
    ok(s[0].st === `Krok 1 z${NB}3 · Teraz: zaznacz rodzaj działalności`, 'start: wiersz stanu kroku 1: ' + s[0].st);
    ok(s[1].st === `Krok 2 z${NB}3` && s[2].st === `Krok 3 z${NB}3`, 'start: wiersze stanu kroków 2 i 3');
    ok(s[0].opis === 'krok-stan-1' && s[1].opis === 'krok-stan-2' && s[2].opis === 'krok-stan-3 suma-nota', 'aria-describedby kroków: ' + s.map((x) => x.opis));
    ok(await p.evaluate(() => [...document.querySelectorAll('.krok-nr')].every((e) => e.getAttribute('aria-hidden') === 'true')), 'numer w kółku aria-hidden');
    // nazwa grupy bez numeru i stanu (legenda bez zmian dla czytnika)
    const nazwa = await p.evaluate(() => { const l = document.querySelector('#kalk-osoby > legend').cloneNode(true); l.querySelectorAll('[aria-hidden="true"]').forEach((x) => x.remove()); return l.textContent.replace(/\s+/g, ' ').trim(); });
    ok(nazwa === 'Ile osób wykonuje zabiegi w gabinecie (łącznie z Tobą)?', 'nazwa grupy osób bez numeru: ' + nazwa);
    ok(await p.evaluate(() => { const w = document.getElementById('wynik-krok'); return !w.hidden && w.textContent === 'Krok 1 z 3: rodzaj działalności'; }), 'start: wskazówka pod polem wyniku');
    ok((await p.textContent('#calc-status')) === '', 'start: bez ogłoszenia przy wczytaniu');
    ok((await puls(p)).length === 0, 'start: bez pulsu');
    // ramka bieżącego kroku (złota obwódka) i przygaszone dalsze kroki (legenda taupe, nie przezroczystość)
    const css = await p.evaluate(() => { const g = (id) => getComputedStyle(document.getElementById(id)); const l = (id) => getComputedStyle(document.querySelector('#' + id + ' > legend'));
      return { b1: g('kalk-rodzaje').borderTopColor, b2: g('kalk-osoby').borderTopColor, o2: g('kalk-osoby').opacity, l2: l('kalk-osoby').color, l1: l('kalk-rodzaje').color }; });
    ok(css.b1 === 'rgb(184, 151, 90)' && css.b2 === 'rgba(0, 0, 0, 0)', 'obwódka tylko na bieżącym kroku: ' + JSON.stringify(css));
    ok(css.o2 === '1' && css.l2 === 'rgb(95, 87, 77)' && css.l1 === 'rgb(42, 59, 104)', 'dalszy krok: legenda taupe, pełne krycie: ' + JSON.stringify(css));

    await nasluch(p);
    // krok 1 → 2: fokus i przewinięcie bez zmian
    await p.locator('#r-kosmetyczny').scrollIntoViewIfNeeded();
    await p.focus('#r-kosmetyczny');
    const y0 = await p.evaluate(() => scrollY);
    await klik(p, 'r-kosmetyczny');
    s = await stan(p);
    ok(s.map((x) => x.cur).join() === ',step,', 'po rodzaju: bieżący krok 2');
    ok(s[0].nr === '✓' && s[0].st === `Krok 1 z${NB}3 · Gotowe` && s[0].stan === 'gotowe', 'po rodzaju: krok 1 „✓” i „Gotowe”');
    ok(s[1].st === `Krok 2 z${NB}3 · Teraz: zaznacz liczbę osób`, 'po rodzaju: wiersz stanu kroku 2: ' + s[1].st);
    let o = await ogl(p);
    ok(o.length === 1 && o[0] === `Krok 2 z${NB}3. Podaj liczbę osób wykonujących zabiegi.`, 'zmiana 1→2: jedno ogłoszenie z numerem kroku: ' + JSON.stringify(o));
    ok((await p.evaluate(() => scrollY)) === y0, 'zmiana kroku nie przewija strony');
    ok((await p.evaluate(() => document.activeElement.id)) === 'r-kosmetyczny', 'zmiana kroku nie przenosi fokusu');
    ok(JSON.stringify(await puls(p)) === '["kalk-osoby"]', 'zmiana kroku: jeden puls obwódki na kroku 2: ' + JSON.stringify(await puls(p)));
    ok(await p.evaluate(() => document.getElementById('wynik-krok').textContent === 'Krok 2 z 3: liczba osób'), 'wskazówka pod wynikiem: krok 2');
    // drugi rodzaj (krok bez zmian, brak liczby osób) – nic do ogłoszenia; kafelki kroku 1 nie przesuwają się
    const yKaf = await p.evaluate(() => document.querySelector('label[for="r-kosmetologiczny"]').getBoundingClientRect().top);
    await p.waitForTimeout(1500);
    await klik(p, 'r-kosmetologiczny');
    o = await ogl(p);
    ok(o.length === 1, 'drugi rodzaj (krok bez zmian): bez nowego ogłoszenia: ' + JSON.stringify(o));
    ok((await puls(p)).length === 0, 'drugi rodzaj: bez pulsu');
    ok(Math.abs((await p.evaluate(() => document.querySelector('label[for="r-kosmetologiczny"]').getBoundingClientRect().top)) - yKaf) < 0.5, 'kafelki kroku 1 bez przesunięcia');
    // kolejność dowolna: suma przed liczbą osób – krok 3 „Gotowe”, bieżący nadal 2, bez ogłoszenia
    await klik(p, 's-200000');
    s = await stan(p);
    ok(s.map((x) => x.stan).join() === 'gotowe,teraz,gotowe' && s[1].cur === 'step', 'suma przed liczbą osób: bieżący nadal krok 2, krok 3 gotowe');
    o = await ogl(p);
    ok(o.length === 1, 'suma przed liczbą osób: bez nowego ogłoszenia: ' + JSON.stringify(o));
    // komplet: brak bieżącego kroku, wskazówka pod wynikiem znika, ogłoszenie kwoty bez „Krok”
    await klik(p, 'o-1-5');
    s = await stan(p);
    ok(s.every((x) => x.cur === null && x.stan === 'gotowe' && x.nr === '✓'), 'komplet: wszystkie kroki „✓”, bez aria-current');
    ok(await p.evaluate(() => document.getElementById('wynik-krok').hidden), 'komplet: wskazówka pod wynikiem ukryta');
    o = await ogl(p);
    ok(o.length === 2 && /^Taryfa: .*Składka roczna: 980,00 zł\.$/.test(o[1]) && !/Krok/.test(o[1]), 'komplet: jedno ogłoszenie kwoty bez numeru kroku: ' + JSON.stringify(o.slice(1)));
    // zmiana sumy przy komplecie – zmiana wyniku (kwota), bez numeru kroku
    await klik(p, 's-300000');
    o = await ogl(p);
    ok(o.length === 3 && /1 250,00 zł\.$/.test(o[2]) && !/Krok/.test(o[2]), 'zmiana sumy: ogłoszenie nowej kwoty bez kroku: ' + JSON.stringify(o.slice(2)));
    // cofnięcie: odznaczenie obu rodzajów → krok 1, jedno ogłoszenie (D45: kosmetyczny + kosmetologiczny – pełna; sam kosmetologiczny – 950 zł)
    await klik(p, 'r-kosmetyczny');
    o = await ogl(p);
    ok(o.length === 4 && /950,00\u00a0zł\.$/.test(o[3]) && !/Krok/.test(o[3]), 'odznaczenie jednego z dwóch rodzajów: jedno ogłoszenie (inna kwota): ' + JSON.stringify(o.slice(3)));
    await klik(p, 'r-kosmetologiczny');
    s = await stan(p);
    o = await ogl(p);
    ok(s[0].cur === 'step' && s[0].stan === 'teraz', 'bez rodzaju: bieżący znowu krok 1');
    ok(o.length === 5 && o[4] === `Krok 1 z${NB}3. Zaznacz rodzaj działalności.`, 'powrót do kroku 1: jedno ogłoszenie: ' + JSON.stringify(o.slice(4)));
    const zKrokiem = o.filter((t) => /Krok \d z/.test(t)).length;
    ok(zKrokiem === 2, 'ogłoszenia z numerem kroku = liczba zmian kroku z brakami (2): ' + zKrokiem);
    ok(errs.length === 0, 'błędy JS: ' + errs);
    await ctx.close();
  }

  // ---------- 2. wycena indywidualna przed krokami (ankieta) – wynik bez numeru kroku, krok dopisany dopiero przy zmianie
  {
    const ctx = await b.newContext({ viewport: { width: 1280, height: 900 } });
    const p = await ctx.newPage();
    await p.goto(PAGE);
    await p.waitForTimeout(300);
    await nasluch(p);
    await klik(p, 'ankieta');
    await klik(p, 'g4-02');
    let o = await ogl(p);
    ok(o.length === 2 && /^Składka do indywidualnej wyceny/.test(o[1]) && !/Krok/.test(o[1]), 'ankieta przed krokami: wycena indywidualna bez numeru kroku: ' + JSON.stringify(o));
    ok((await stan(p))[0].cur === 'step', 'ankieta: bieżący nadal krok 1 (CRM wymaga rodzaju, liczby osób i sumy)');
    ok(await p.evaluate(() => document.getElementById('wynik-krok').textContent === 'Krok 1 z 3: rodzaj działalności'), 'ankieta: wskazówka pod wynikiem przy wycenie indywidualnej');
    await klik(p, 'r-kosmetologiczny');
    o = await ogl(p);
    ok(o.length === 3 && /^Składka do indywidualnej wyceny.* Krok 2 z 3: zaznacz liczbę osób\.$/.test(o[2]), 'ankieta + rodzaj: wynik i nowy krok w jednym ogłoszeniu: ' + JSON.stringify(o.slice(2)));
    await ctx.close();
  }

  // ---------- 3. ograniczony ruch: bez pulsu
  {
    const ctx = await b.newContext({ viewport: { width: 1280, height: 900 }, reducedMotion: 'reduce' });
    const p = await ctx.newPage();
    await p.goto(PAGE);
    await p.waitForTimeout(300);
    await klik(p, 'r-masaz');
    ok((await stan(p))[1].cur === 'step', 'reduced motion: przewodnik działa (krok 2)');
    ok((await puls(p)).length === 0 && !(await p.evaluate(() => document.querySelector('.krok-puls'))), 'reduced motion: bez pulsu obwódki');
    await ctx.close();
  }

  // ---------- 4. bez JS: brak podświetlenia i wskazówek, wszystkie pola widoczne
  {
    const ctx = await b.newContext({ viewport: { width: 1280, height: 900 }, javaScriptEnabled: false });
    const p = await ctx.newPage();
    await p.goto(PAGE);
    const r = await p.evaluate((ids) => ({
      krok: document.querySelectorAll('.krok,.krok-nr,.krok-stan,[aria-current="step"],.kroki-on').length,
      wk: document.getElementById('wynik-krok').hidden,
      ramki: ids.map((id) => getComputedStyle(document.getElementById(id)).borderTopWidth + '/' + getComputedStyle(document.getElementById(id)).paddingTop),
      pola: [...document.querySelectorAll('#calc input[name=rodzaj],#calc input[name=osoby],#calc input[name=suma]')].filter((i) => { const l = i.nextElementSibling.getBoundingClientRect(); return l.width > 0 && l.height > 0; }).length,
      zaznaczone: document.querySelectorAll('#calc input:checked').length,
    }), KROKI);
    ok(r.krok === 0 && r.wk, 'bez JS: bez klas, numerów, wskazówek i aria-current: ' + JSON.stringify(r));
    ok(r.ramki.every((x) => x === '0px/0px'), 'bez JS: pola bez ramki i odstępów przewodnika: ' + r.ramki);
    ok(r.pola === 12 && r.zaznaczone === 0, 'bez JS: 12 pól kroków widocznych, nic nie zaznaczone: ' + JSON.stringify(r));
    await ctx.close();
  }

  // ---------- 5. szerokości: pasek ceny, przełącznik, kafle produktów, wiersz stanu w jednej linii, przewijanie w poziomie, axe
  for (const w of SZER) {
    const ctx = await b.newContext({ viewport: { width: w, height: 860 } });
    const p = await ctx.newPage();
    const errs = []; p.on('pageerror', (e) => errs.push(e.message));
    await p.goto(PAGE);
    await p.waitForTimeout(400);
    // przełącznik produktów
    const t = await p.evaluate(() => {
      const sw = document.getElementById('calc-switch'), tabs = [...sw.querySelectorAll('.calc-tab')], c = sw.closest('.container');
      const cs = getComputedStyle(c), inner = c.clientWidth - parseFloat(cs.paddingLeft) - parseFloat(cs.paddingRight);
      return { role: sw.getAttribute('role'), roles: tabs.map((x) => x.getAttribute('role') + ':' + x.getAttribute('aria-selected')), h: tabs.map((x) => x.getBoundingClientRect().height),
        wSw: sw.getBoundingClientRect().width, inner, hidden: sw.hidden, nazwy: tabs.map((x) => x.querySelector('small').getAttribute('aria-hidden')) };
    });
    ok(t.role === 'tablist' && t.roles.join() === 'tab:true,tab:false' && !t.hidden && t.nazwy.join() === 'true,true', `${w}: przełącznik – role i aria-selected bez zmian: ` + JSON.stringify(t));
    ok(t.h.every((h) => h >= (w < 480 ? 76 : 88)), `${w}: wysokość kafli przełącznika ≥ ${w < 480 ? 76 : 88} px: ` + t.h);
    if (w < 768) ok(Math.abs(t.wSw - t.inner) < 1, `${w}: przełącznik na całą szerokość kontenera: ${t.wSw} / ${t.inner}`);
    // kafle produktów
    const k = await p.evaluate(() => {
      // offset* zamiast getBoundingClientRect: wejście kafli (rv-rise, scale .96) nie zawyża odstępów
      const a = [...document.querySelectorAll('#ubezpieczenia .product')].map((e) => ({ left: e.offsetLeft, top: e.offsetTop, right: e.offsetLeft + e.offsetWidth, bottom: e.offsetTop + e.offsetHeight }));
      const st = getComputedStyle(document.querySelector('#ubezpieczenia .product')), led = getComputedStyle(document.querySelector('#ubezpieczenia .ledger'));
      let minX = 1e9, minY = 1e9;
      for (const r of a) for (const q of a) {
        if (q === r) continue;
        const nakladaY = r.top < q.bottom && q.top < r.bottom, nakladaX = r.left < q.right && q.left < r.right;
        if (nakladaY && q.left >= r.right - 0.5) minX = Math.min(minX, q.left - r.right);
        if (nakladaX && q.top >= r.bottom - 0.5) minY = Math.min(minY, q.top - r.bottom);
      }
      const bf = [...document.querySelectorAll('#ubezpieczenia .ledger, #ubezpieczenia .product')].map((e) => getComputedStyle(e).backdropFilter).filter((x) => x && x !== 'none');
      return { n: a.length, minX, minY, rad: st.borderTopLeftRadius, bf: bf.length, ledBf: led.backdropFilter };
    });
    ok(k.n === 6 && k.rad === '10px' && k.bf === 0, `${w}: 6 kafli, promień 10 px, bez backdrop-filter: ` + JSON.stringify(k));
    if (w >= 640) ok(k.minX >= 15, `${w}: odstęp kafli w poziomie ≥ 16 px (offset* – liczby całkowite, tolerancja 1 px): ${k.minX}`);
    ok(k.minY >= 15, `${w}: odstęp kafli w pionie ≥ 16 px (offset* – tolerancja 1 px): ${k.minY}`);
    // wiersz stanu w jednej linii we wszystkich stanach; pasek ceny z tą samą wskazówką
    const linie = async () => p.evaluate(() => [...document.querySelectorAll('.krok-stan')].map((e) => Math.round(e.getBoundingClientRect().height / parseFloat(getComputedStyle(e).lineHeight))));
    const l0 = await linie();
    const peek0 = await p.evaluate(() => { const a = document.querySelector('#calc .calc-peek'); return { k: a.dataset.krok, vis: getComputedStyle(a).visibility, lab: a.querySelector('span').textContent, txt: a.querySelector('strong').textContent, href: a.getAttribute('href'), cut: a.querySelector('strong').scrollWidth > a.querySelector('strong').clientWidth + 1 }; });
    await klik(p, 'r-kosmetyczny');
    const l1 = await linie();
    await klik(p, 'o-6-8');
    const l2 = await linie();
    const peek1 = await p.evaluate(() => { const a = document.querySelector('#calc .calc-peek'); return { k: a.dataset.krok, lab: a.querySelector('span').textContent, txt: a.querySelector('strong').textContent, href: a.getAttribute('href'), cut: a.querySelector('strong').scrollWidth > a.querySelector('strong').clientWidth + 1 }; });
    ok([...l0, ...l1, ...l2].every((n) => n === 1), `${w}: wiersz stanu kroku w jednej linii: ${l0} | ${l1} | ${l2}`);
    if (w < 1024) {
      ok(peek0.k === '1' && peek0.vis === 'visible' && peek0.lab === `Krok 1 z${NB}3 · Teraz` && peek0.txt === 'Zaznacz rodzaj działalności' && peek0.href === '#kalk-rodzaje' && !peek0.cut,
        `${w}: pasek ceny – wskazówka kroku 1: ` + JSON.stringify(peek0));
      ok(peek1.k === '3' && peek1.txt === 'Wybierz sumę gwarancyjną' && peek1.href === '#kalk-sumy' && !peek1.cut, `${w}: pasek ceny – wskazówka kroku 3: ` + JSON.stringify(peek1));
      await klik(p, 's-100000');
      const peek2 = await p.evaluate(() => { const a = document.querySelector('#calc .calc-peek'); return { k: a.dataset.krok, lab: a.querySelector('span').textContent, txt: a.querySelector('strong').textContent, href: a.getAttribute('href') }; });
      ok(peek2.k === undefined && peek2.lab === 'Składka roczna' && peek2.txt === `500,00${NB}zł` && peek2.href === '#wynik', `${w}: pasek ceny po komplecie – kwota: ` + JSON.stringify(peek2));
    }
    // przewijanie w poziomie (stan startowy i po zmianach)
    const sw = await p.evaluate(() => document.documentElement.scrollWidth - innerWidth);
    ok(sw <= 0, `${w}: przewijanie w poziomie (${sw} px)`);
    // axe WCAG 2.2 AA – cała strona: po zmianach (krok 3 albo komplet) i w stanie startowym
    const axe = async (opis) => {
      await p.addScriptTag({ path: AXE });
      const v = await p.evaluate(async () => (await axe.run(document, { runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'] } })).violations
        .map((x) => x.id + ' (' + x.nodes.length + '): ' + x.nodes.slice(0, 3).map((n) => n.target.join(' ')).join(' | ')));
      ok(v.length === 0, `${w} ${opis}: axe WCAG 2.2 AA – ${v.join('; ')}`);
    };
    await axe('po zmianach');
    await p.reload();
    await p.waitForTimeout(400);
    await klik(p, 'r-tatuaz');
    await axe('krok 2 bieżący');
    ok((await p.evaluate(() => document.documentElement.scrollWidth - innerWidth)) <= 0, `${w}: przewijanie w poziomie (krok 2)`);
    ok(errs.length === 0, `${w}: błędy JS: ${errs}`);
    await ctx.close();
  }

  await b.close();
  console.log(`asercje: ${asercje}`);
  console.log(bledy.length ? 'BŁĘDY (' + bledy.length + '):\n' + bledy.join('\n') : 'OK');
  process.exit(bledy.length ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(1); });
