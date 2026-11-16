// Kontrola „Zakładki w Strefie” – preferencja widoku salonu (prośba zleceniodawcy 16.11.2026), nie kontrola dostępu.
// Strony: strefa/panel.html (#ustawienia → „Zakładki w Strefie”, menu, pulpit właściciela i pracownika, „Historia konta”),
// strefa/dam-prace.html i strefa/szkolenia.html (menu, informacja przy wejściu pod adres ukrytego modułu, „Pokaż zakładkę”).
// Sprawdza: przełączanie klawiaturą (Spacja), stan tekstowy i aria (role=switch, checked), komunikat aria-live, historię,
// ukrycie pozycji menu (pasek boczny i szuflada) i kafli na trzech stronach, informację i „Pokaż zakładkę”, synchronizację
// między kartami, ?zakladki=…, wariant pracownika (tylko do odczytu), strony publiczne bez zmian, bez JS (wszystko widoczne),
// brak dostępu do localStorage, przewijanie w poziomie 320–1440 px, tekst ≥ 12 px, cele ≥ 24 px, fokus, axe (WCAG 2.2 AA).
// Tylko odczyt makiet (file://), nic nie zapisuje w repozytorium; zrzuty – kontrola/wyniki/strefa/.
// Uruchomienie: node narzedzia/makiety/kontrola/strefa/zakladki.js   (kod wyjścia 1 przy błędach)
const path = require('path');
const fs = require('fs');
const { chromium } = require('playwright');
const REPO = path.resolve(__dirname, '../../../..');                  // katalog główny repozytorium
const DIR = REPO + '/docs/koncepcja/design/v3/strefa/';
const S = 'file://' + DIR;
const OUT = path.join(__dirname, '../wyniki/strefa') + '/';          // zrzuty (poza gitem)
const AXE = fs.readFileSync(require.resolve('axe-core/axe.min.js'), 'utf8');
fs.mkdirSync(OUT, { recursive: true });

const FAIL = [];
let N = 0;
const ok = (c, m) => { N++; if (!c) { FAIL.push(m); console.log('  FAIL', m); } return !!c; };
const log = (...a) => console.log(...a);
const KLUCZ = 'bp-strefa-zakladki';
const NAZWA_PRACA = 'Praca – Dam pracę i Szukam pracy';
const MSG_UKRYTA = 'Zakładka Praca jest ukryta. Włączysz ją tutaj.';
const MSG_WIDOCZNA = 'Zakładka Praca jest widoczna w menu i na pulpicie.';
const nb = s => (s || '').replace(/[ ⁠]/g, ' ').replace(/\s+/g, ' ').trim();
const W = [320, 360, 390, 768, 1024, 1280, 1440];

// ---------- pomocnicze (wykonywane w stronie) ----------
// widoczne linki menu Strefy (pasek boczny): teksty
const navTexts = () => [...document.querySelectorAll('#sidenav a')].filter(a => a.checkVisibility()).map(a => a.textContent.replace(/\s+/g, ' ').trim());
const RE_PRACA = /^(Dam pracę|Moje ogłoszenia|Szukam pracy)$/;
const RE_SZK = /^(Szkolenia|Katalog szkoleń|Moje szkolenia)$/;
// tekst < 12 px i przewijanie w poziomie
const audit = () => {
  const de = document.documentElement;
  const vis = e => e.checkVisibility() && getComputedStyle(e).visibility !== 'hidden';
  const small = [...document.querySelectorAll('body *')].filter(e => [...e.childNodes].some(n => n.nodeType === 3 && n.textContent.trim()) && vis(e) && parseFloat(getComputedStyle(e).fontSize) < 12 && !e.closest('.sr-only')).map(e => e.tagName + ':' + e.textContent.trim().slice(0, 30) + ':' + getComputedStyle(e).fontSize).slice(0, 6);
  const wide = [...document.querySelectorAll('body *')].filter(e => { if (!vis(e) || e.closest('.sr-only,.table-wrap,dialog:not([open])')) return false; const b = e.getBoundingClientRect(); return b.width > 0 && b.right > de.clientWidth + 1; }).slice(0, 4).map(e => e.tagName + '.' + String(e.className).slice(0, 30) + '@' + Math.round(e.getBoundingClientRect().right));
  return { sw: de.scrollWidth, cw: de.clientWidth, small, wide };
};
const lsGet = k => { try { return JSON.parse(localStorage.getItem(k)); } catch (e) { return 'ERR'; } };
async function newCtx(b, opt = {}) {
  const c = await b.newContext({ viewport: { width: opt.w || 1280, height: opt.h || 900 }, javaScriptEnabled: opt.js !== false, reducedMotion: 'reduce' });
  if (opt.bezPamieci) {
    await c.addInitScript(() => { Object.defineProperty(window, 'localStorage', { configurable: true, get() { throw new Error('localStorage zablokowany (test)'); } }); });
  }
  return c;
}
async function open(c, url, errs) {
  const p = await c.newPage();
  p.on('pageerror', e => errs && errs.push(url + ': ' + e.message));
  // pomijane: zasoby z sieci (fonty) i odczyt arkusza CSS przez axe-core (XMLHttpRequest z file:// – blokada CORS przeglądarki)
  p.on('console', m => { if (errs && m.type() === 'error' && !/Failed to load resource|ERR_FILE_NOT_FOUND|net::|fonts\.g|XMLHttpRequest at 'file:/.test(m.text())) errs.push(url + ': ' + m.text()); });
  await p.goto(S + url, { waitUntil: 'load' });
  await p.waitForTimeout(120);
  return p;
}
async function axe(p, label, include) {
  await p.addScriptTag({ content: AXE });
  const r = await p.evaluate(async inc => {
    const res = await axe.run(inc ? { include: inc } : document, { runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'] }, resultTypes: ['violations'] });
    return res.violations.map(v => ({ id: v.id, n: v.nodes.length, t: v.nodes.slice(0, 3).map(n => n.target.join(' ') + ' :: ' + (n.failureSummary || '').replace(/\s+/g, ' ').slice(0, 160)) }));
  }, include || null);
  ok(!r.length, `axe ${label}: ${JSON.stringify(r)}`);
  return r;
}
const isVis = (p, sel) => p.evaluate(s => { const e = document.querySelector(s); return !!e && e.checkVisibility(); }, sel);
const txt = (p, sel) => p.evaluate(s => { const e = document.querySelector(s); return e ? e.textContent.replace(/\s+/g, ' ').trim() : null; }, sel);
const vtxt = (p, sel) => p.evaluate(s => { const e = document.querySelector(s); return e ? e.innerText.replace(/\s+/g, ' ').trim() : null; }, sel);   // tylko widoczny tekst
// cele < 24 px w elemencie (WCAG 2.5.8); wyjątek: link w zdaniu (display: inline w akapicie)
const maleCele = s => [...document.querySelectorAll(s)].flatMap(r => [...r.querySelectorAll('a[href],button,input,summary,label')]).filter(e => e.checkVisibility() && !(e.tagName === 'A' && getComputedStyle(e).display === 'inline' && e.closest('p'))).map(e => { const r = e.getBoundingClientRect(); return [(e.textContent || '').trim().slice(0, 24) || e.id, Math.round(r.width), Math.round(r.height)]; }).filter(([, w2, h2]) => w2 < 24 || h2 < 24);

(async () => {
  const b = await chromium.launch();
  const errs = [];

  // ---------- 0. statycznie: ten sam skrypt w <head> i zakladki.js na trzech stronach ----------
  {
    const glowa = {};
    for (const f of ['panel.html', 'dam-prace.html', 'szkolenia.html']) {
      const h = fs.readFileSync(DIR + f, 'utf8');
      const m = h.match(/<!-- Zakładki w Strefie salonu[\s\S]*?<\/script>/);
      ok(m, `${f}: brak skryptu zakładek w <head>`);
      glowa[f] = m ? m[0] : '';
      ok(m && h.indexOf(m[0]) < h.indexOf('</head>'), `${f}: skrypt zakładek poza <head>`);
      ok(/<script src="zakladki\.js"><\/script>/.test(h), `${f}: brak <script src="zakladki.js">`);
      ok((h.match(/data-zakladka="praca"/g) || []).length >= 1 && (h.match(/data-zakladka="szkolenia"/g) || []).length >= 1, `${f}: brak elementów data-zakladka`);
    }
    ok(glowa['panel.html'] === glowa['dam-prace.html'] && glowa['panel.html'] === glowa['szkolenia.html'], 'skrypt zakładek w <head> różni się między stronami');
  }

  // ---------- 1. Ustawienia (właściciel): klawiatura, stan tekstowy i aria, aria-live, historia, menu ----------
  log('\n== 1. Ustawienia – właściciel, klawiatura');
  {
    const c = await newCtx(b);
    const p = await open(c, 'panel.html#zakladki', errs);
    const sw = p.getByRole('switch', { name: NAZWA_PRACA, exact: true });
    const swS = p.getByRole('switch', { name: 'Szkolenia', exact: true });
    ok(await sw.count() === 1 && await swS.count() === 1, 'przełączniki: brak role=switch z nazwą z etykiety');
    ok(await sw.isChecked() && await swS.isChecked(), 'domyślnie oba włączone');
    ok(await sw.isEnabled(), 'właściciel: przełącznik aktywny');
    ok(await p.$eval('#zak-praca', e => e.tagName === 'INPUT' && e.type === 'checkbox' && e.getAttribute('role') === 'switch' && !e.hasAttribute('aria-checked')), 'przełącznik: input type=checkbox role=switch (bez aria-checked)');
    ok(await txt(p, '#zak-praca-stan') === 'Widoczna', 'stan tekstowy „Widoczna”');
    const desc = await p.$eval('#zak-praca', e => (e.getAttribute('aria-describedby') || '').split(' ').map(id => (document.getElementById(id) || {}).textContent || '').join(' ').replace(/\s+/g, ' '));
    ok(/Wyłącz, jeśli nie zatrudniasz/.test(desc) && /Zakładkę włączysz tu w każdej chwili/.test(nb(desc)), 'opis przełącznika (aria-describedby): ' + desc.slice(0, 120));
    ok(/zostają bez zmian/.test(nb(desc)) && /\/strefa-klienta\/dam-prace/.test(desc), 'informacja o aktywnych ogłoszeniach (aria-describedby)');
    ok(/zapis/.test(await p.$eval('#zak-szkolenia', e => (e.getAttribute('aria-describedby') || '').split(' ').map(id => (document.getElementById(id) || {}).textContent || '').join(' '))), 'informacja o nadchodzących zapisach przy „Szkolenia”');
    ok(await p.$eval('#zak-live', e => e.getAttribute('role') === 'status' || e.getAttribute('aria-live') === 'polite'), 'region aria-live');
    ok(await isVis(p, '.mock-note[data-zakladki-adnotacja]') && /nie kontrola dostępu/.test(nb(await txt(p, '[data-zakladki-adnotacja]'))), 'adnotacja makiety: preferencja widoku, nie kontrola dostępu');
    ok(!(await isVis(p, 'form[data-zakladki-form] .no-js-only')), 'z JS: bez przycisku „Zapisz”');
    let nav = await p.evaluate(navTexts);
    ok(nav.includes('Dam pracę') && nav.includes('Szkolenia'), 'menu przed zmianą: ' + nav.join('|'));

    // Tab do przełącznika (fokus z klawiatury), Spacja
    await p.focus('#zak-praca'); await p.keyboard.press('Shift+Tab'); await p.keyboard.press('Tab');
    ok(await p.evaluate(() => document.activeElement.id) === 'zak-praca', 'Tab: fokus na przełączniku Praca');
    const fv = await p.$eval('#zak-praca', e => { const s = getComputedStyle(e); return { fv: e.matches(':focus-visible'), st: s.outlineStyle, w: parseFloat(s.outlineWidth) }; });
    ok(fv.fv && fv.st !== 'none' && fv.w >= 2, 'widoczny fokus przełącznika ' + JSON.stringify(fv));
    await p.keyboard.press('Space'); await p.waitForTimeout(80);
    ok(!(await sw.isChecked()), 'Spacja: przełącznik wyłączony');
    ok(await p.getByRole('switch', { name: NAZWA_PRACA, exact: true, checked: false }).count() === 1, 'aria: switch checked=false');
    ok(await txt(p, '#zak-praca-stan') === 'Ukryta', 'stan tekstowy „Ukryta”');
    ok(nb(await txt(p, '#zak-live')) === MSG_UKRYTA, 'aria-live: ' + await txt(p, '#zak-live'));
    ok(await p.evaluate(() => document.activeElement.id) === 'zak-praca', 'fokus zostaje na przełączniku');
    ok(await p.evaluate(() => document.documentElement.getAttribute('data-ukryte')) === 'praca', 'html[data-ukryte]="praca"');
    ok(JSON.stringify((await p.evaluate(lsGet, KLUCZ) || {}).ukryte) === '["praca"]', 'localStorage: ukryte ["praca"]');
    nav = await p.evaluate(navTexts);
    ok(!nav.some(t => RE_PRACA.test(t)) && nav.includes('Szkolenia'), 'menu po ukryciu Pracy: ' + nav.join('|'));
    ok(/^Ukryto zakładkę Praca \(Dam pracę i Szukam pracy\) w Strefie salonu/.test(nb(await txt(p, '#historia tbody tr:first-child td:nth-child(2)'))), 'Historia konta: wpis „Ukryto zakładkę Praca…”');
    ok(nb(await txt(p, '#historia tbody tr:first-child td:nth-child(3)')) === 'Anna Przykładowa', 'Historia konta: osoba');
    await p.screenshot({ path: OUT + 'ustawienia-praca-ukryta-1280.png', fullPage: false });

    // pulpit: kafel „Dam pracę” znika, „Szkolenia” zostaje, podpowiedź o ukrytych zakładkach, „Ostatnie zdarzenia”
    await p.evaluate(() => { location.hash = 'pulpit'; }); await p.waitForTimeout(80);
    ok(!(await isVis(p, '#pulpit a.shortcut[href^="dam-prace.html"]')) && await isVis(p, '#pulpit a.shortcut[href^="szkolenia.html"]'), 'pulpit: kafel Dam pracę ukryty, Szkolenia widoczny');
    ok(await isVis(p, '#pulpit .zak-hint') && await p.$eval('#pulpit .zak-hint a', a => a.getAttribute('href')) === '#zakladki', 'pulpit: podpowiedź z linkiem do #zakladki');
    ok(/^Ukryto zakładkę Praca/.test(nb(await txt(p, '[data-historia-mini] > li:first-child strong'))), 'pulpit: „Ostatnie zdarzenia” z wpisem');
    ok(await p.$$eval('[data-historia-mini] > li', l => l.filter(x => x.checkVisibility()).length) === 3, 'pulpit: „Ostatnie zdarzenia” – 3 wpisy');
    await axe(p, 'panel #pulpit (Praca ukryta)', [['#pulpit'], ['#sidenav']]);

    // z powrotem: Spacja – widoczna; Szkolenia – klik w etykietę (mysz)
    await p.evaluate(() => { location.hash = 'zakladki'; }); await p.waitForTimeout(80);
    await p.focus('#zak-praca'); await p.keyboard.press('Space'); await p.waitForTimeout(80);
    ok(await sw.isChecked() && await txt(p, '#zak-praca-stan') === 'Widoczna', 'Spacja ponownie: widoczna');
    ok(nb(await txt(p, '#zak-live')) === MSG_WIDOCZNA, 'aria-live po pokazaniu: ' + await txt(p, '#zak-live'));
    ok(/^Pokazano zakładkę Praca/.test(nb(await txt(p, '#historia tbody tr:first-child td:nth-child(2)'))) && /^Ukryto zakładkę Praca/.test(nb(await txt(p, '#historia tbody tr:nth-child(2) td:nth-child(2)'))), 'Historia konta: dwa wpisy, najnowszy na górze');
    await p.click('label[for="zak-szkolenia"]'); await p.waitForTimeout(80);
    ok(!(await swS.isChecked()) && nb(await txt(p, '#zak-live')) === 'Zakładka Szkolenia jest ukryta. Włączysz ją tutaj.', 'klik w etykietę „Szkolenia”: ukryta + komunikat');
    nav = await p.evaluate(navTexts);
    ok(nav.includes('Dam pracę') && !nav.some(t => RE_SZK.test(t)), 'menu po ukryciu Szkoleń: ' + nav.join('|'));
    ok(await p.evaluate(() => document.documentElement.getAttribute('data-ukryte')) === 'szkolenia', 'html[data-ukryte]="szkolenia"');
    // cel dotyku przełącznika i etykiety
    const cel = await p.$$eval('input[data-zakladka-przelacznik], label[for^="zak-"]', l => l.map(e => { const r = e.getBoundingClientRect(); return [e.id || e.htmlFor, Math.round(r.width), Math.round(r.height)]; }));
    ok(cel.every(([, w, h]) => w >= 24 && h >= 24), 'cele ≥ 24 px: ' + JSON.stringify(cel));
    await axe(p, 'panel #ustawienia (właściciel)', [['#ustawienia']]);

    // ---------- 2. te same ustawienia na innych stronach Strefy (ta sama przeglądarka) ----------
    log('\n== 2. Pozostałe strony Strefy, wejście pod adres modułu');
    await p.focus('#zak-szkolenia'); await p.keyboard.press('Space');          // Szkolenia znowu widoczne
    await p.focus('#zak-praca'); await p.keyboard.press('Space');              // Praca ukryta
    ok(await p.evaluate(() => document.documentElement.getAttribute('data-ukryte')) === 'praca', 'stan przed przejściem: praca ukryta');
    const d = await open(c, 'dam-prace.html#moje-ogloszenia', errs);
    nav = await d.evaluate(navTexts);
    ok(!nav.some(t => RE_PRACA.test(t)) && nav.includes('Szkolenia'), 'dam-prace: menu bez Dam pracę: ' + nav.join('|'));
    ok(await isVis(d, '[data-zakladka-uwaga="praca"]'), 'dam-prace: informacja o ukrytej zakładce przy wejściu pod adres');
    ok(nb(await txt(d, '[data-zakladka-uwaga="praca"] .alert-title')) === 'Zakładka Praca jest ukryta w ustawieniach salonu', 'dam-prace: tytuł informacji');
    ok(await isVis(d, '#moje-ogloszenia h1') && await isVis(d, '#moje-ogloszenia table'), 'dam-prace: moduł działa normalnie (lista ogłoszeń)');
    ok(await d.evaluate(() => { const n = document.querySelector('[data-zakladka-uwaga="praca"]'), v = document.getElementById('moje-ogloszenia'); return !!(n.compareDocumentPosition(v) & Node.DOCUMENT_POSITION_FOLLOWING) && n.getBoundingClientRect().top < v.getBoundingClientRect().top; }), 'dam-prace: informacja u góry, nad widokiem');
    const btn = d.getByRole('button', { name: 'Pokaż zakładkę', exact: true });
    ok(await btn.count() === 1 && await btn.isVisible(), 'dam-prace: przycisk „Pokaż zakładkę” (właściciel)');
    const bb = await btn.boundingBox(); ok(bb && bb.width >= 24 && bb.height >= 24, 'dam-prace: cel „Pokaż zakładkę” ≥ 24 px ' + JSON.stringify(bb));
    ok(!(await isVis(d, '[data-zakladka-uwaga="praca"] p.employee-only')), 'dam-prace: tekst dla pracownika ukryty u właściciela');
    await axe(d, 'dam-prace #moje-ogloszenia z informacją', [['#tresc'], ['#sidenav']]);
    for (const h of ['nowe-ogloszenie', 'szukam-pracy']) {
      await d.evaluate(h => { location.hash = h; }, h); await d.waitForTimeout(60);
      ok(await isVis(d, '[data-zakladka-uwaga="praca"]') && await isVis(d, '#' + h + ' h1'), `dam-prace #${h}: informacja i moduł`);
    }
    for (const h of ['oferty', 'oferta']) {   // publiczna tablica /dam-prace – bez zmian
      await d.evaluate(h => { location.hash = h; }, h); await d.waitForTimeout(60);
      ok(!(await isVis(d, '[data-zakladka-uwaga="praca"]')), `dam-prace #${h} (publiczna): bez informacji`);
      ok(await d.evaluate(() => [...document.querySelectorAll('.pub-header a, .pub-header summary')].some(a => /Dam\s*pracę/.test(a.textContent))), `dam-prace #${h}: publiczny nagłówek z „Dam pracę”`);
    }
    const dp = await open(c, 'dam-prace.html?konto=pracodawca#moje-ogloszenia', errs);   // konto pracodawcy z rejestracji – bez tej preferencji
    ok(!(await isVis(dp, '[data-zakladka-uwaga="praca"]')) && (await dp.evaluate(navTexts)).includes('Moje ogłoszenia'), 'konto pracodawcy z rejestracji: bez informacji, menu bez zmian');
    await dp.close();

    const sz = await open(c, 'szkolenia.html#moje-szkolenia', errs);
    nav = await sz.evaluate(navTexts);
    ok(!nav.some(t => RE_PRACA.test(t)) && nav.includes('Szkolenia'), 'szkolenia: menu bez Dam pracę: ' + nav.join('|'));
    ok(!(await isVis(sz, '[data-zakladka-uwaga="szkolenia"]')), 'szkolenia: bez informacji (Szkolenia widoczne)');
    await sz.close();
    const pp = await open(c, 'panel.html#pulpit', errs);
    ok(!(await isVis(pp, '#pulpit a.shortcut[href^="dam-prace.html"]')), 'panel (nowa karta): kafel Dam pracę ukryty');
    ok(/^Ukryto zakładkę Praca/.test(nb(await txt(pp, '[data-historia-mini] > li:first-child strong'))), 'panel (nowa karta): historia z localStorage');

    // „Pokaż zakładkę” z klawiatury (Enter) na dam-prace
    await d.evaluate(() => { location.hash = 'moje-ogloszenia'; }); await d.waitForTimeout(60);
    await btn.focus(); await d.keyboard.press('Enter'); await d.waitForTimeout(100);
    ok(!(await isVis(d, '[data-zakladka-uwaga="praca"] form')), '„Pokaż zakładkę”: informacja znika');
    ok(await isVis(d, '[data-zakladka-uwaga="praca"] .tab-note-ok') && await d.evaluate(() => document.activeElement.classList.contains('tab-note-ok')), '„Pokaż zakładkę”: potwierdzenie widoczne i z fokusem');
    ok(/Zakładka Praca jest znowu widoczna/.test(nb(await txt(d, '[data-zakladka-uwaga="praca"] .tab-note-ok'))), '„Pokaż zakładkę”: treść potwierdzenia');
    nav = await d.evaluate(navTexts);
    ok(nav.includes('Dam pracę'), 'dam-prace: menu z Dam pracę po „Pokaż zakładkę”: ' + nav.join('|'));
    ok(JSON.stringify((await d.evaluate(lsGet, KLUCZ) || {}).ukryte) === '[]', 'localStorage po „Pokaż zakładkę”: []');
    // synchronizacja z inną kartą (zdarzenie storage)
    await pp.waitForTimeout(150);
    ok(await isVis(pp, '#pulpit a.shortcut[href^="dam-prace.html"]'), 'druga karta (panel): kafel wraca bez przeładowania');
    await pp.reload(); await pp.waitForTimeout(80);
    await pp.evaluate(() => { location.hash = 'historia'; }); await pp.waitForTimeout(60);
    ok(/^Pokazano zakładkę Praca/.test(nb(await txt(pp, '#historia tbody tr:first-child td:nth-child(2)'))), 'Historia konta: wpis po „Pokaż zakładkę” na innej stronie');
    // ukrycie w ustawieniach przy otwartej stronie modułu – informacja pojawia się znowu
    await p.bringToFront();
    await p.focus('#zak-praca'); await p.keyboard.press('Space'); await p.waitForTimeout(150);
    ok(await isVis(d, '[data-zakladka-uwaga="praca"] form') && !(await isVis(d, '.tab-note-ok')), 'dam-prace (druga karta): informacja wraca po ponownym ukryciu');
    await c.close();
  }

  // ---------- 3. Szkolenia ukryte: wejście pod adres, organizator, katalog; ?zakladki=… ----------
  log('\n== 3. ?zakladki=…, Szkolenia, oba ukryte');
  {
    const c = await newCtx(b);
    const sz = await open(c, 'szkolenia.html?zakladki=bez-szkolen#moje-szkolenia', errs);
    let nav = await sz.evaluate(navTexts);
    ok(nav.includes('Dam pracę') && !nav.some(t => RE_SZK.test(t)), 'szkolenia (bez-szkolen): menu: ' + nav.join('|'));
    ok(await isVis(sz, '[data-zakladka-uwaga="szkolenia"]') && nb(await txt(sz, '[data-zakladka-uwaga="szkolenia"] .alert-title')) === 'Zakładka Szkolenia jest ukryta w ustawieniach salonu', 'szkolenia: informacja');
    ok(await isVis(sz, '#moje-szkolenia h1') && await isVis(sz, '#p-nad'), 'szkolenia: moduł działa (zapisy widoczne)');
    ok(await sz.getByRole('button', { name: 'Pokaż zakładkę', exact: true }).isVisible(), 'szkolenia: „Pokaż zakładkę” (właściciel)');
    await axe(sz, 'szkolenia #moje-szkolenia z informacją', [['#tresc'], ['#sidenav']]);
    await sz.evaluate(() => { location.hash = 'katalog'; }); await sz.waitForTimeout(60);
    ok(await isVis(sz, '[data-zakladka-uwaga="szkolenia"]'), 'szkolenia #katalog w Strefie: informacja');
    await sz.evaluate(() => { location.hash = 'organizator'; }); await sz.waitForTimeout(60);
    ok(!(await isVis(sz, '[data-zakladka-uwaga="szkolenia"]')), 'szkolenia #organizator (osobne konto organizatora): bez informacji');
    nav = await sz.evaluate(navTexts);
    ok(nav.includes('Moje szkolenia') && nav.includes('Katalog szkoleń'), 'organizator: menu bez zmian: ' + nav.join('|'));
    const d = await open(c, 'dam-prace.html#moje-ogloszenia', errs);
    ok(!(await isVis(d, '[data-zakladka-uwaga="praca"]')) && !(await d.evaluate(navTexts)).some(t => RE_SZK.test(t)), 'dam-prace: bez informacji o Pracy, menu bez Szkoleń');
    // oba ukryte
    const p = await open(c, 'panel.html?zakladki=bez-pracy,bez-szkolen#pulpit', errs);
    nav = await p.evaluate(navTexts);
    ok(!nav.some(t => RE_PRACA.test(t) || RE_SZK.test(t)), 'panel (oba ukryte): menu: ' + nav.join('|'));
    ok(!(await isVis(p, '#pulpit a.shortcut[href^="dam-prace.html"]')) && !(await isVis(p, '#pulpit a.shortcut[href^="szkolenia.html"]')) && await isVis(p, '#pulpit a.shortcut[href="#szkoda"]'), 'pulpit (oba ukryte): zostaje tylko „Zgłoś szkodę”');
    ok(nb(await vtxt(p, '#pulpit .lead')) === 'Polisy i dokumenty salonu – w jednym miejscu.', 'pulpit (oba ukryte): lead bez modułów: ' + await vtxt(p, '#pulpit .lead'));
    await p.evaluate(() => { location.hash = 'pracownik'; }); await p.waitForTimeout(80);
    ok(await isVis(p, '#pracownik .zak-pusto') && !(await isVis(p, '#pracownik [data-zakladka="praca"]')) && !(await isVis(p, '#pracownik [data-zakladka="szkolenia"]')), 'pulpit pracownika (oba ukryte): pusty stan, bez kart');
    await axe(p, 'panel #pracownik (oba ukryte)', [['#pracownik']]);
    // szuflada menu na telefonie
    await p.setViewportSize({ width: 390, height: 844 });
    await p.evaluate(() => { location.hash = 'pulpit'; }); await p.waitForTimeout(60);
    await p.click('#nav-toggle'); await p.waitForTimeout(80);
    nav = await p.evaluate(navTexts);
    ok(nav.includes('Pulpit') && !nav.some(t => RE_PRACA.test(t) || RE_SZK.test(t)), 'szuflada 390 px (oba ukryte): ' + nav.join('|'));
    await p.screenshot({ path: OUT + 'szuflada-oba-ukryte-390.png' });
    await p.keyboard.press('Escape');
    // reset adresem
    const p2 = await open(c, 'panel.html?zakladki=wszystkie#pulpit', errs);
    ok(await isVis(p2, '#pulpit a.shortcut[href^="dam-prace.html"]') && await isVis(p2, '#pulpit a.shortcut[href^="szkolenia.html"]') && !(await isVis(p2, '#pulpit .zak-hint')), '?zakladki=wszystkie: wszystko widoczne');
    ok(JSON.stringify((await p2.evaluate(lsGet, KLUCZ) || {}).ukryte) === '[]', '?zakladki=wszystkie: zapisany stan []');
    await c.close();
  }

  // ---------- 4. wariant pracownika: tylko do odczytu, informacja bez przycisku ----------
  log('\n== 4. Pracownik');
  {
    const c = await newCtx(b);
    const p = await open(c, 'panel.html?rola=pracownik&zakladki=bez-pracy#ustawienia', errs);
    ok(await p.evaluate(() => document.body.getAttribute('data-role')) === 'employee', 'pracownik: data-role=employee');
    const sw = p.getByRole('switch', { name: NAZWA_PRACA, exact: true });
    ok(await sw.isDisabled() && await p.getByRole('switch', { name: 'Szkolenia', exact: true }).isDisabled(), 'pracownik: przełączniki tylko do odczytu (disabled)');
    ok(!(await sw.isChecked()) && await txt(p, '#zak-praca-stan') === 'Ukryta', 'pracownik: widzi stan (Praca ukryta)');
    ok(await isVis(p, '#zak-ro') && /właścicielka konta/.test(nb(await txt(p, '#zak-ro'))), 'pracownik: informacja, że zmienia właściciel');
    ok((await p.$eval('#zak-praca', e => e.getAttribute('aria-describedby'))).split(' ').includes('zak-ro'), 'pracownik: aria-describedby z informacją');
    ok(!(await isVis(p, '#historia')), 'pracownik: bez „Historii konta” (dziennik – tylko właściciel)');
    await p.click('label[for="zak-praca"]', { force: true }); await p.waitForTimeout(60);
    ok(!(await sw.isChecked()) && JSON.stringify((await p.evaluate(lsGet, KLUCZ) || {}).ukryte) === '["praca"]', 'pracownik: klik w etykietę nic nie zmienia');
    let nav = await p.evaluate(navTexts);
    ok(!nav.includes('Polisy') && !nav.some(t => RE_PRACA.test(t)) && nav.includes('Szkolenia'), 'pracownik: menu (bez Polis i Pracy): ' + nav.join('|'));
    ok(/rola=pracownik/.test(await p.$eval('#sidenav a[href^="szkolenia.html"]', a => a.getAttribute('href'))), 'pracownik: link Szkolenia niesie rolę');
    await axe(p, 'panel #ustawienia (pracownik)', [['#ustawienia']]);
    await p.evaluate(() => { location.hash = 'pracownik'; }); await p.waitForTimeout(80);
    ok(!(await isVis(p, '#pracownik [data-zakladka="praca"]')) && await isVis(p, '#pracownik [data-zakladka="szkolenia"]'), 'pulpit pracownika: bez „Ogłoszeń salonu”, „Moje szkolenia” zostaje');
    ok(!(await isVis(p, '#pracownik .zak-pusto')), 'pulpit pracownika: bez pustego stanu (Szkolenia widoczne)');
    // z „Pulpitu pracownika” (bez parametru) do Ustawień – rola zostaje
    const q = await open(c, 'panel.html#pracownik', errs);
    ok(await q.$eval('#sidenav a[data-view="ustawienia"]', a => a.getAttribute('href')) === '?rola=pracownik#ustawienia', 'pulpit pracownika: link Ustawienia z rolą');
    await q.click('#sidenav a[data-view="ustawienia"]'); await q.waitForLoadState('load'); await q.waitForTimeout(80);
    ok(await q.getByRole('switch', { name: NAZWA_PRACA, exact: true }).isDisabled(), 'pracownik po przejściu z pulpitu: przełączniki tylko do odczytu');
    await q.evaluate(() => { location.hash = 'pulpit'; }); await q.waitForTimeout(60);   // pulpit właściciela – rola właściciela
    ok(await q.evaluate(() => document.body.getAttribute('data-role')) === 'owner' && await q.$eval('#sidenav a[data-view="ustawienia"]', a => a.getAttribute('href')) === 'panel.html#ustawienia', 'pulpit właściciela na adresie ?rola=pracownik: Ustawienia bez parametru');
    const d = await open(c, 'dam-prace.html?rola=pracownik#moje-ogloszenia', errs);
    ok(await isVis(d, '[data-zakladka-uwaga="praca"]') && !(await d.getByRole('button', { name: 'Pokaż zakładkę' }).isVisible()), 'dam-prace (pracownik): informacja bez „Pokaż zakładkę”');
    ok(await isVis(d, '[data-zakladka-uwaga="praca"] p.employee-only') && /właściciel/.test(await txt(d, '[data-zakladka-uwaga="praca"] p.employee-only')), 'dam-prace (pracownik): kto pokaże zakładkę');
    ok(!(await d.evaluate(navTexts)).includes('Polisy') && !(await isVis(d, '#moje-ogloszenia .subnav')) && !(await isVis(d, '#moje-ogloszenia .cell-actions')), 'dam-prace (pracownik): bez Polis, „Szukam pracy” i akcji');
    await d.evaluate(() => { location.hash = 'nowe-ogloszenie'; }); await d.waitForTimeout(60);
    ok(await isVis(d, '#moje-ogloszenia h1') && !(await isVis(d, '#nowe-ogloszenie h1')), 'dam-prace (pracownik): „Nowe ogłoszenie” → lista ogłoszeń salonu');
    await axe(d, 'dam-prace (pracownik) z informacją', [['#tresc']]);
    const sz = await open(c, 'szkolenia.html?rola=pracownik&zakladki=bez-szkolen#moje-szkolenia', errs);
    ok(await isVis(sz, '[data-zakladka-uwaga="szkolenia"]') && !(await sz.getByRole('button', { name: 'Pokaż zakładkę' }).isVisible()) && await isVis(sz, '[data-zakladka-uwaga="szkolenia"] p.employee-only'), 'szkolenia (pracownik): informacja bez przycisku');
    ok(!(await isVis(sz, '#t-zespol')), 'szkolenia (pracownik): bez „Zapisów zespołu”');
    ok(/^panel\.html#pracownik$/.test(await sz.$eval('#sidenav a[data-href0="panel.html#pulpit"]', a => a.getAttribute('href'))), 'szkolenia (pracownik): Pulpit → pulpit pracownika');
    await axe(sz, 'szkolenia (pracownik) z informacją', [['#tresc']]);
    await c.close();
  }

  // ---------- 5. bez JS: wszystko widoczne ----------
  log('\n== 5. Bez JS');
  for (const w of [320, 1440]) {
    const c = await newCtx(b, { js: false, w });
    for (const f of ['panel.html', 'dam-prace.html', 'szkolenia.html']) {
      const p = await c.newPage(); await p.goto(S + f + '?zakladki=bez-pracy,bez-szkolen#ustawienia', { waitUntil: 'load' });
      const st = await p.evaluate(() => {
        const vis = e => !!e && e.checkVisibility();
        const zak = [...document.querySelectorAll('[data-zakladka]')];
        return { ukryte: document.documentElement.hasAttribute('data-ukryte'), zak: zak.length, zakVis: zak.filter(vis).length, nav: [...document.querySelectorAll('#sidenav a')].filter(vis).map(a => a.textContent.trim().replace(/\s+/g, ' ')), uwaga: [...document.querySelectorAll('[data-zakladka-uwaga]')].map(e => vis(e) && vis(e.querySelector('.mock-note'))), sw: [...document.querySelectorAll('input[data-zakladka-przelacznik]')].map(i => [i.checked, i.disabled, vis(i)]), zapisz: vis(document.querySelector('form[data-zakladki-form] .no-js-only button')), audit: null };
      });
      ok(!st.ukryte, `bez JS ${f}@${w}: brak html[data-ukryte]`);
      // [data-zakladka] poza ekranami niedostępnymi dla roli (owner-only/employee-only, kontekst organizatora) – widoczne
      const niewid = await p.evaluate(() => [...document.querySelectorAll('[data-zakladka]')].filter(e => !e.checkVisibility() && !e.closest('.employee-only,.org-only,.sidenav') ).map(e => e.outerHTML.slice(0, 80)));
      ok(!niewid.length, `bez JS ${f}@${w}: niewidoczne [data-zakladka]: ${JSON.stringify(niewid)}`);
      if (w === 1440) ok(st.nav.includes('Dam pracę') && st.nav.includes('Szkolenia'), `bez JS ${f}: menu z Dam pracę i Szkoleniami: ${st.nav.join('|')}`);
      if (f === 'panel.html') {
        ok(st.sw.length === 2 && st.sw.every(([c1, d1, v]) => c1 && !d1 && v), `bez JS panel: przełączniki włączone i aktywne ${JSON.stringify(st.sw)}`);
        ok(st.zapisz, 'bez JS panel: przycisk „Zapisz”');
        ok(await isVis(p, '#pracownik .zak-pusto .mock-note'), 'bez JS panel: wzór pustego pulpitu pracownika z adnotacją');
      } else {
        ok(st.uwaga.length === 1 && st.uwaga[0], `bez JS ${f}: informacja jako wzór z adnotacją ${JSON.stringify(st.uwaga)}`);
      }
      const a = await p.evaluate(audit);
      ok(a.sw <= a.cw, `bez JS ${f}@${w}: przewijanie w poziomie ${a.sw}/${a.cw} ${JSON.stringify(a.wide)}`);
      ok(!a.small.length, `bez JS ${f}@${w}: tekst < 12 px ${JSON.stringify(a.small)}`);
      await p.close();
    }
    await c.close();
  }

  // ---------- 6. localStorage niedostępny: strona działa, zmiana do przeładowania ----------
  log('\n== 6. Bez dostępu do localStorage');
  {
    const c = await newCtx(b, { bezPamieci: true });
    const e6 = [];
    const p = await open(c, 'panel.html?zakladki=bez-pracy#zakladki', e6);
    ok(!e6.length, 'bez pamięci: błędy JS ' + JSON.stringify(e6));
    ok(await p.evaluate(() => document.documentElement.getAttribute('data-ukryte')) === 'praca', 'bez pamięci: ?zakladki działa na tej stronie');
    await p.focus('#zak-szkolenia'); await p.keyboard.press('Space'); await p.waitForTimeout(60);
    ok(await p.evaluate(() => document.documentElement.getAttribute('data-ukryte')) === 'praca szkolenia' && nb(await txt(p, '#zak-live')) === 'Zakładka Szkolenia jest ukryta. Włączysz ją tutaj.', 'bez pamięci: przełącznik działa w tej karcie');
    ok(/^Ukryto zakładkę Szkolenia/.test(nb(await txt(p, '#historia tbody tr:first-child td:nth-child(2)'))), 'bez pamięci: wpis w historii');
    const d = await open(c, 'dam-prace.html#moje-ogloszenia', e6);
    ok(!e6.length && (await d.evaluate(navTexts)).includes('Dam pracę') && !(await isVis(d, '[data-zakladka-uwaga="praca"]')), 'bez pamięci: inna strona – stan domyślny, bez błędów');
    await c.close();
  }

  // ---------- 7. szerokości 320–1440: przewijanie w poziomie, tekst ≥ 12 px, cele ----------
  log('\n== 7. Szerokości');
  {
    // [adres, element nowego komponentu – do przewinięcia i kontroli celów]
    const ekrany = [
      ['panel.html?zakladki=bez-pracy#zakladki', '#zakladki'],
      ['panel.html?rola=pracownik&zakladki=bez-szkolen#zakladki', '#zakladki'],
      ['panel.html?zakladki=bez-pracy#pulpit', '#pulpit .zak-hint'],
      ['panel.html?zakladki=bez-pracy,bez-szkolen#pracownik', '#pracownik .zak-pusto'],
      ['dam-prace.html?zakladki=bez-pracy#moje-ogloszenia', '[data-zakladka-uwaga="praca"]'],
      ['dam-prace.html?rola=pracownik&zakladki=bez-pracy#moje-ogloszenia', '[data-zakladka-uwaga="praca"]'],
      ['szkolenia.html?zakladki=bez-szkolen#moje-szkolenia', '[data-zakladka-uwaga="szkolenia"]'],
    ];
    for (const w of W) {
      const c = await newCtx(b, { w, h: 860 });
      for (const [u, sel] of ekrany) {
        const p = await open(c, u, errs);
        await p.evaluate(s => document.querySelector(s).scrollIntoView({ block: 'start' }), sel); await p.waitForTimeout(40);
        const a = await p.evaluate(audit);
        ok(a.sw <= w && a.sw <= a.cw, `${u}@${w}: przewijanie w poziomie ${a.sw}/${a.cw} ${JSON.stringify(a.wide)}`);
        ok(!a.small.length, `${u}@${w}: tekst < 12 px ${JSON.stringify(a.small)}`);
        const male = await p.evaluate(maleCele, sel);
        ok(!male.length, `${u}@${w}: cele < 24 px ${JSON.stringify(male)}`);
        if (w === 320 || w === 1440) await p.screenshot({ path: OUT + u.replace(/[^a-z0-9]+/gi, '_') + '-' + w + '.png' });
        await p.close();
      }
      await c.close();
    }
  }

  ok(!errs.length, 'błędy JS: ' + JSON.stringify(errs.slice(0, 6)));
  await b.close();
  log(`\nasercji: ${N}`);
  if (FAIL.length) { log(`\n=== PODSUMOWANIE: BŁĘDY (${FAIL.length})\n` + FAIL.join('\n')); process.exitCode = 1; }
  else log('\n=== PODSUMOWANIE: wszystkie asercje OK');
})().catch(e => { console.error(e); process.exitCode = 1; });
