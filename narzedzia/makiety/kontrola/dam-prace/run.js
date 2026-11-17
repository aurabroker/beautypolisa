// Kontrola filtra „Zabiegi” w strefa/dam-prace.html (tylko odczyt makiety; nic nie zapisuje w repo)
const REPO = require('path').resolve(__dirname, '../../../..');  // katalog główny repozytorium
const WYNIKI = require('path').join(__dirname, '../wyniki/dam-prace') + '/';  // zrzuty i wyniki (poza gitem)
const { chromium } = require('playwright');
const fs = require('fs');
const BASE = 'file://' + REPO + '/docs/koncepcja/design/v3/strefa/dam-prace.html';
const OUT = WYNIKI;
fs.mkdirSync(OUT, { recursive: true });
const EXP = JSON.parse(fs.readFileSync(__dirname + '/expect.json', 'utf8'));
// lista zabiegów w wersji 2 (Aneks nr 5): zabieg z obu list ma checkbox w sekcji lista-1 i lista-2 (to samo value) – wyniki liczymy bez powtórzeń
const ZJ = JSON.parse(fs.readFileSync(REPO + '/docs/koncepcja/snippets/zabiegi-oc-beauty.json', 'utf8'));
const LISTY = Object.fromEntries(ZJ.zabiegi.map(z => [z.id, z.pozycje.map(p => p.lista)]));
const N_POL = ZJ.zabiegi.reduce((n, z) => n + z.pozycje.length, 0);  // liczba checkboxów w oknie (pozycje list, z powtórzeniami)
const N_ZAB = ZJ.zabiegi.length;                                        // zabiegi bez powtórzeń (100)
const WYC = JSON.parse(fs.readFileSync(REPO + '/docs/koncepcja/snippets/zabiegi-oc-beauty-wycofane.json', 'utf8')).wycofane;
const DOPISEK = ' (pozycja wycofana z listy)';
const uniq = a => a.filter((v, i) => a.indexOf(v) === i);
const VPS = [[1440, 900, false], [768, 1024, false], [390, 844, true], [360, 740, true], [320, 640, true]];
const log = (...a) => console.log(...a);
const FAIL = [];
const check = (cond, msg) => { if (!cond) { FAIL.push(msg); log('  FAIL', msg); } return cond; };

const audit = () => {
  const de = document.documentElement;
  const vis = e => e.getClientRects().length > 0 && getComputedStyle(e).visibility !== 'hidden';
  const inVp = e => { const b = e.getBoundingClientRect(); return b.bottom > 0 && b.top < innerHeight && b.right > 0 && b.left < innerWidth; };
  const wide = [...document.querySelectorAll('body *')].filter(e => { if (!vis(e) || e.closest('.sr-only,.hp,dialog:not([open]),.table-wrap')) return false; const b = e.getBoundingClientRect(); return b.width > 0 && b.right > de.clientWidth + 1; }).slice(0, 6).map(e => e.tagName + '.' + String(e.className).slice(0, 30) + ':' + (e.textContent || '').trim().slice(0, 30) + '@' + Math.round(e.getBoundingClientRect().right));
  const small = [...document.querySelectorAll('body *')].filter(e => [...e.childNodes].some(n => n.nodeType === 3 && n.textContent.trim()) && vis(e) && parseFloat(getComputedStyle(e).fontSize) < 12 && !e.closest('.sr-only')).map(e => e.tagName + ':' + e.textContent.trim().slice(0, 30) + ':' + getComputedStyle(e).fontSize).slice(0, 8);
  const blurEls = [...document.querySelectorAll('body *')].filter(e => { const s = getComputedStyle(e); return vis(e) && s.backdropFilter && s.backdropFilter !== 'none'; });
  return { sw: de.scrollWidth, cw: de.clientWidth, bodySw: document.body.scrollWidth, wide, small, blurAll: blurEls.length, blurInVp: blurEls.filter(inVp).length, blurList: blurEls.filter(inVp).map(e => e.tagName + '.' + String(e.className).slice(0, 40)) };
};
// interaktywne elementy < 24 px (checkbox: liczy się etykieta – kliknięcie w nią zaznacza)
const smallTargets = (sel) => {
  const root = document.querySelector(sel); if (!root) return ['brak ' + sel];
  const els = [...root.querySelectorAll('a[href],button,input,select,textarea,summary')].filter(e => e.getClientRects().length && getComputedStyle(e).visibility !== 'hidden' && !e.closest('.sr-only'));
  return els.map(e => { let t = e; if (e.type === 'checkbox' || e.type === 'radio') t = e.closest('label') || e; const b = t.getBoundingClientRect(); return { n: (e.getAttribute('aria-label') || e.textContent || e.value || e.type || '').trim().slice(0, 30), w: Math.round(b.width * 10) / 10, h: Math.round(b.height * 10) / 10 }; }).filter(x => x.w < 24 || x.h < 24);
};
const offersState = () => {
  const offers = [...document.querySelectorAll('#lista-ofert > .offer')];
  return offers.map((o, i) => ({ i, vis: o.getClientRects().length > 0 && !document.getElementById('lista-ofert').hidden, ids: (o.querySelector('.zab-tags') ? o.querySelector('.zab-tags').getAttribute('data-ids') : '').split(' ').filter(Boolean), zawod: o.dataset.zawod, woj: o.dataset.woj, umowa: o.dataset.umowa, date: o.querySelector('time').getAttribute('datetime') }));
};
const dlgState = (base) => {
  const d = document.getElementById(base + '-dlg'); const q = document.getElementById(base + '-q');
  const boxes = [...d.querySelectorAll('input[name="zabieg"]')];
  const visible = boxes.filter(b => b.getClientRects().length > 0 && !b.closest('label').hidden && !b.closest('details').hidden && b.closest('details').open).map(b => b.value);
  const unhidden = boxes.filter(b => !b.closest('label').hidden).map(b => b.value);
  const grps = [...d.querySelectorAll('.zab-grp')].map(g => ({ g: g.dataset.lista, hidden: g.hidden, open: g.open, sel: g.querySelector('.zab-grp-sel').textContent }));
  const none = d.querySelector('.zab-none');
  return { open: d.open, q: q.value, visible, unhidden, grps, none: none.hidden ? '' : none.textContent, st: document.getElementById(base + '-q-st').textContent, count: d.querySelector('.zab-count').textContent, done: d.querySelector('.zab-done').textContent, clearDisabled: d.querySelector('.zab-clear').disabled, active: (document.activeElement.id || document.activeElement.className || document.activeElement.tagName) };
};
const activeDesc = () => { const a = document.activeElement; return a ? (a.tagName + '#' + a.id + '.' + String(a.className).slice(0, 30) + ' "' + (a.getAttribute('aria-label') || a.textContent || '').trim().slice(0, 40) + '"') : 'null'; };

async function openFilters(p) {
  const open = await p.$eval('#filtry-panel', d => d.open);
  if (!open) { await p.click('#filtry-panel > summary'); await p.waitForTimeout(50); }
}
async function openDlg(p, base) { await p.click('#' + base + ' .zab-open'); await p.waitForTimeout(260); }

async function jsOn(b, w, h, mobile, rm) {
  log(`\n=== JS on ${w}x${h} mobile=${mobile} reducedMotion=${rm}`);
  const ctx = await b.newContext({ viewport: { width: w, height: h }, isMobile: mobile, hasTouch: mobile, reducedMotion: rm, deviceScaleFactor: 1 });
  const p = await ctx.newPage();
  const errs = []; p.on('pageerror', e => errs.push('pageerror ' + e.message)); p.on('console', m => { if (m.type() === 'error' || m.type() === 'warning') errs.push(m.type() + ' ' + m.text()); });
  await p.goto(BASE + '#oferty', { waitUntil: 'load' }); await p.waitForTimeout(300);
  log('media pointer:fine', await p.evaluate(() => matchMedia('(pointer:fine)').matches), 'coarse', await p.evaluate(() => matchMedia('(pointer:coarse)').matches));
  const a0 = await p.evaluate(audit); log('audit start', JSON.stringify(a0));
  check(a0.sw <= a0.cw, `${w}: poziomy scroll na starcie ${a0.sw}>${a0.cw}`);
  check(a0.small.length === 0, `${w}: tekst <12px ${a0.small}`);
  check(a0.blurInVp <= 3, `${w}: backdrop-filter w widoku ${a0.blurInVp}`);
  log('filtry-panel open at load', await p.$eval('#filtry-panel', d => d.open));
  await openFilters(p);
  const a0b = await p.evaluate(audit); log('audit filtry otwarte', JSON.stringify({ sw: a0b.sw, cw: a0b.cw, wide: a0b.wide, small: a0b.small, blurInVp: a0b.blurInVp }));
  check(a0b.sw <= a0b.cw, `${w}: poziomy scroll z otwartymi filtrami`);
  // przycisk
  const btn = await p.$eval('#zab-oferty .zab-open', e => ({ text: e.textContent.trim(), exp: e.getAttribute('aria-expanded'), pop: e.getAttribute('aria-haspopup'), ctrl: e.getAttribute('aria-controls'), ctrlOk: !!document.getElementById(e.getAttribute('aria-controls')), desc: (document.getElementById(e.getAttribute('aria-describedby')) || {}).textContent, w: e.getBoundingClientRect().width, h: e.getBoundingClientRect().height, fs: getComputedStyle(e).fontSize }));
  log('open button', JSON.stringify(btn));
  check(btn.exp === 'false' && btn.pop === 'dialog' && btn.ctrlOk, `${w}: aria przycisku`);
  log('checkboxy widoczne przy zamkniętym oknie', await p.$$eval('#zab-oferty input[name=zabieg]', a => a.filter(x => x.getClientRects().length).length), 'w formularzu', await p.$$eval('#f-filtry input[name=zabieg]', a => a.length));
  const tFilters = await p.evaluate(smallTargets, '#f-filtry'); log('cele <24 w #f-filtry', JSON.stringify(tFilters));
  check(tFilters.length === 0, `${w}: cele <24px w filtrach ${JSON.stringify(tFilters)}`);
  await p.screenshot({ path: OUT + `filtry-${w}${rm === 'reduce' ? '-rm' : ''}.png`, fullPage: false });

  // otwarcie okna
  await openDlg(p, 'zab-oferty');
  const d1 = await p.evaluate(() => { const d = document.getElementById('zab-oferty-dlg'); const r = d.getBoundingClientRect(); const bd = d.querySelector('.zab-sheet-body'); return { open: d.open, modal: d.matches(':modal'), lab: document.getElementById(d.getAttribute('aria-labelledby')).textContent, r: [Math.round(r.left), Math.round(r.top), Math.round(r.width), Math.round(r.height)], vw: innerWidth, vh: innerHeight, dsw: d.scrollWidth, dcw: d.clientWidth, bsw: bd.scrollWidth, bcw: bd.clientWidth, anim: getComputedStyle(d).animationName, htmlOv: getComputedStyle(document.documentElement).overflow, exp: document.querySelector('#zab-oferty .zab-open').getAttribute('aria-expanded'), lead: d.querySelector('.zab-sheet-head p').textContent }; });
  log('dialog', JSON.stringify(d1), 'focus', await p.evaluate(activeDesc));
  check(d1.open && d1.modal, `${w}: okno nie jest modalne`);
  check(d1.exp === 'true', `${w}: aria-expanded po otwarciu`);
  check(d1.dsw <= d1.dcw && d1.bsw <= d1.bcw, `${w}: poziome przewijanie w oknie`);
  check(rm === 'reduce' ? d1.anim === 'none' : d1.anim === 'zab-in', `${w}: animacja przy reducedMotion=${rm}: ${d1.anim}`);
  check(d1.r[0] >= 0 && d1.r[1] >= 0 && d1.r[0] + d1.r[2] <= d1.vw && d1.r[1] + d1.r[3] <= d1.vh, `${w}: okno poza ekranem ${d1.r}`);
  const a1 = await p.evaluate(audit); log('audit z oknem', JSON.stringify({ sw: a1.sw, cw: a1.cw, small: a1.small, blurAll: a1.blurAll, blurInVp: a1.blurInVp, blurList: a1.blurList }));
  check(a1.small.length === 0 && a1.blurInVp <= 3, `${w}: okno – małe teksty/backdrop`);
  const tD = await p.evaluate(smallTargets, '#zab-oferty-dlg'); log('cele <24 w oknie (grupy zwinięte)', JSON.stringify(tD));
  check(tD.length === 0, `${w}: cele <24px w oknie`);
  log('ariaSnapshot okna (początek):\n' + (await p.locator('#zab-oferty-dlg').ariaSnapshot()).split('\n').slice(0, 30).join('\n'));
  await p.screenshot({ path: OUT + `okno-${w}${rm === 'reduce' ? '-rm' : ''}.png` });

  // wyszukiwanie
  const q = p.locator('#zab-oferty-q');
  let searchBad = [];
  for (const [term, exp] of Object.entries(EXP)) {
    await q.fill(term); await p.waitForTimeout(30);
    const s = await p.evaluate(dlgState, 'zab-oferty');
    const expSet = term.trim() ? exp : null;
    const okVis = JSON.stringify(uniq(s.visible)) === JSON.stringify(exp);
    const okUnh = JSON.stringify(uniq(s.unhidden)) === JSON.stringify(exp);
    const grpOk = s.grps.every(g => { const any = exp.some(id => LISTY[id].includes(g.g)); return g.hidden === !any && g.open === any; });
    const noneOk = exp.length ? s.none === '' : s.none.length > 0;
    if (!(okVis && okUnh && grpOk && noneOk)) searchBad.push({ term, exp: exp.length, vis: s.visible.length, unh: s.unhidden.length, grps: s.grps, none: s.none });
  }
  check(searchBad.length === 0, `${w}: wyszukiwanie ${JSON.stringify(searchBad).slice(0, 600)}`);
  log('wyszukiwanie: ' + Object.keys(EXP).length + ' zapytań, rozbieżności: ' + searchBad.length);
  await q.fill('rzes'); await p.waitForTimeout(600);
  let s = await p.evaluate(dlgState, 'zab-oferty'); log('rzes ->', JSON.stringify({ vis: s.visible, st: s.st, grps: s.grps }));
  await p.screenshot({ path: OUT + `szukaj-rzes-${w}.png` });
  await q.fill('xyzxyz'); await p.waitForTimeout(600);
  s = await p.evaluate(dlgState, 'zab-oferty'); log('xyzxyz ->', JSON.stringify({ none: s.none, st: s.st }));
  await q.fill(''); await p.waitForTimeout(600);
  s = await p.evaluate(dlgState, 'zab-oferty'); log('po wyczyszczeniu szukania ->', JSON.stringify({ unh: s.unhidden.length, grps: s.grps, st: s.st }));
  check(s.unhidden.length === N_POL && s.grps.every(g => !g.hidden && !g.open), `${w}: po wyczyszczeniu szukania listy nie wróciły`);
  // Esc w polu wyszukiwania z tekstem
  await q.fill('mezo'); await p.waitForTimeout(50); await q.focus(); await p.keyboard.press('Escape'); await p.waitForTimeout(150);
  const escSearch = await p.evaluate(() => ({ open: document.getElementById('zab-oferty-dlg').open, q: document.getElementById('zab-oferty-q').value }));
  log('Esc w polu szukania z tekstem ->', JSON.stringify(escSearch), 'focus', await p.evaluate(activeDesc));
  if (escSearch.open) { await p.keyboard.press('Escape'); await p.waitForTimeout(150); }
  const afterEsc = await p.evaluate(() => ({ open: document.getElementById('zab-oferty-dlg').open, exp: document.querySelector('#zab-oferty .zab-open').getAttribute('aria-expanded'), focusIsBtn: document.activeElement === document.querySelector('#zab-oferty .zab-open'), q: document.getElementById('zab-oferty-q').value, grpsHidden: [...document.querySelectorAll('#zab-oferty-dlg .zab-grp')].filter(g => g.hidden).length }));
  log('po Esc', JSON.stringify(afterEsc));
  check(!afterEsc.open && afterEsc.exp === 'false' && afterEsc.focusIsBtn && afterEsc.q === '' && afterEsc.grpsHidden === 0, `${w}: Esc – zamknięcie/powrót fokusu/reset szukania`);

  // wybór wielu: klik w etykietę (lista nr 1) + klawiatura (Spacja) po wyszukaniu
  await openDlg(p, 'zab-oferty');
  await p.click('#zab-oferty-dlg .zab-grp[data-lista="lista-1"] > summary'); await p.waitForTimeout(50);
  await p.click('#zab-oferty-dlg input[value="g1-17"]'); // Manicure
  await q.fill('tatu'); await p.waitForTimeout(50);
  await p.focus('#zab-oferty-dlg input[value="g2-32"]'); await p.keyboard.press('Space'); await p.waitForTimeout(50);
  s = await p.evaluate(dlgState, 'zab-oferty'); log('po wyborze 2 ->', JSON.stringify({ count: s.count, done: s.done, grps: s.grps.map(g => g.sel), clearDisabled: s.clearDisabled }));
  let os = await p.evaluate(offersState);
  const expN = os.filter(o => o.ids.some(id => ['g1-17', 'g2-32'].includes(id))).length;
  // licznik od poprawki 13.11 (verify.js) dopisuje liczbę ogłoszeń: „Wybrano: 2 zabiegi · 2 ogłoszenia” (spacje twarde albo zwykłe)
  const mN = /^Wybrano: 2[\s\u00a0]zabiegi[\s\u00a0]·[\s\u00a0](\d+)[\s\u00a0]ogłosze(?:ń|nia|nie)$/.exec(s.count);
  check(mN && +mN[1] === expN && s.done === `Pokaż ogłoszenia (${expN})`, `${w}: licznik/przycisk: "${s.count}" "${s.done}" exp N=${expN}`);
  // Tab w oknie (pułapka natywnego modala)
  const tabOut = [];
  for (let i = 0; i < 25; i++) { await p.keyboard.press('Tab'); tabOut.push(await p.evaluate(() => { const a = document.activeElement; return a && a.closest ? !!a.closest('#zab-oferty-dlg') : false; })); }
  log('Tab x25 – fokus w oknie:', tabOut.map(x => x ? 1 : 0).join(''));
  await p.click('#zab-oferty-dlg .zab-done'); await p.waitForTimeout(150);
  const afterDone = await p.evaluate(() => ({ open: document.getElementById('zab-oferty-dlg').open, focus: document.activeElement.id, chips: [...document.querySelectorAll('#zab-oferty .zab-chip')].map(c => c.getAttribute('aria-label') + '|' + Math.round(c.getBoundingClientRect().width) + 'x' + Math.round(c.getBoundingClientRect().height)), btn: document.querySelector('#zab-oferty .zab-open').textContent.trim(), liczba: document.getElementById('ofert-liczba').textContent, aktywne: document.getElementById('filtry-aktywne').textContent }));
  os = await p.evaluate(offersState);
  log('po „Pokaż ogłoszenia”', JSON.stringify(afterDone), 'widoczne oferty', os.filter(o => o.vis).map(o => o.i + ':' + o.date));
  check(!afterDone.open && afterDone.focus === 't-lista', `${w}: po „Pokaż” fokus nie na wynikach`);
  check(os.filter(o => o.vis).length === expN && os.every(o => o.vis === o.ids.some(id => ['g1-17', 'g2-32'].includes(id))), `${w}: filtr zawęża źle`);
  check(afterDone.chips.length === 2, `${w}: chipy`);
  await p.screenshot({ path: OUT + `chipy-${w}${rm === 'reduce' ? '-rm' : ''}.png` });
  const a2 = await p.evaluate(audit); check(a2.sw <= a2.cw && a2.small.length === 0, `${w}: audit po filtrze ${JSON.stringify(a2.wide)} ${a2.small}`);
  const tC = await p.evaluate(smallTargets, '#zab-oferty'); log('cele <24 w polu zabiegów (z chipami)', JSON.stringify(tC));
  // usuwanie chipów klawiaturą: Enter na pierwszym, Spacja na kolejnym
  await p.focus('#zab-oferty .zab-chip'); await p.keyboard.press('Enter'); await p.waitForTimeout(80);
  const k1 = await p.evaluate(() => ({ chips: document.querySelectorAll('#zab-oferty .zab-chip').length, focus: document.activeElement.getAttribute('aria-label') || document.activeElement.className, vis: [...document.querySelectorAll('#lista-ofert > .offer')].filter(o => o.getClientRects().length).length }));
  log('Enter na chipie ->', JSON.stringify(k1));
  await p.keyboard.press('Space'); await p.waitForTimeout(80);
  const k2 = await p.evaluate(() => ({ chips: document.querySelectorAll('#zab-oferty .zab-chip').length, focusIsBtn: document.activeElement === document.querySelector('#zab-oferty .zab-open'), vis: [...document.querySelectorAll('#lista-ofert > .offer')].filter(o => o.getClientRects().length).length, btn: document.querySelector('#zab-oferty .zab-open').textContent.trim(), aktywne: document.getElementById('filtry-aktywne').textContent }));
  log('Spacja na chipie ->', JSON.stringify(k2));
  check(k1.chips === 1 && /Usuń zabieg/.test(k1.focus) && k2.chips === 0 && k2.focusIsBtn && k2.vis === os.length, `${w}: usuwanie chipów klawiaturą`);

  // „Wyczyść” w oknie + zamknięcie X
  await openDlg(p, 'zab-oferty');
  await q.fill('mezo'); await p.waitForTimeout(40);
  for (const v of ['g2-15', 'g2-16', 'g2-17']) await p.click(`#zab-oferty-dlg input[value="${v}"]`);
  s = await p.evaluate(dlgState, 'zab-oferty'); log('3 wybrane ->', s.count, '|', s.done);
  await p.click('#zab-oferty-dlg .zab-clear'); await p.waitForTimeout(60);
  s = await p.evaluate(dlgState, 'zab-oferty'); log('po Wyczyść ->', JSON.stringify({ count: s.count, done: s.done, clearDisabled: s.clearDisabled, active: s.active, q: s.q }));
  check(/^Nie wybrano zabiegów[\s\u00a0]·[\s\u00a0]\d+[\s\u00a0]ogłosze(?:ń|nia|nie)$/.test(s.count) && s.clearDisabled && s.active === 'zab-oferty-q', `${w}: Wyczyść w oknie`);
  await p.click('#zab-oferty-dlg .drawer-close'); await p.waitForTimeout(100);
  const xr = await p.evaluate(() => ({ open: document.getElementById('zab-oferty-dlg').open, focusIsBtn: document.activeElement === document.querySelector('#zab-oferty .zab-open') }));
  log('Zamknij (X) ->', JSON.stringify(xr)); check(!xr.open && xr.focusIsBtn, `${w}: X – fokus`);
  // klik w tło (tylko gdy okno nie jest pełnoekranowe)
  if (w >= 640) {
    await openDlg(p, 'zab-oferty'); await p.mouse.click(5, h - 5); await p.waitForTimeout(100);
    const bg = await p.evaluate(() => ({ open: document.getElementById('zab-oferty-dlg').open, focusIsBtn: document.activeElement === document.querySelector('#zab-oferty .zab-open') }));
    log('klik w tło ->', JSON.stringify(bg));
  }
  // pusty wynik + zawód; reset formularza
  await openDlg(p, 'zab-oferty');
  await q.fill('lipoliz'); await p.waitForTimeout(40); await p.click('#zab-oferty-dlg input[value="g4-07"]');
  s = await p.evaluate(dlgState, 'zab-oferty'); log('g4-07 ->', s.done);
  check(s.done === 'Pokaż ogłoszenia (0)', `${w}: pusty wynik w przycisku`);
  await p.click('#zab-oferty-dlg .zab-done'); await p.waitForTimeout(100);
  const em = await p.evaluate(() => ({ listHidden: document.getElementById('lista-ofert').hidden, emptyVis: !document.getElementById('ofert-pusto').classList.contains('is-pending'), t: document.getElementById('ofert-pusto-t').textContent, p: document.getElementById('ofert-pusto-p').textContent, liczba: document.getElementById('ofert-liczba').textContent }));
  log('pusty stan ->', JSON.stringify(em));
  await p.screenshot({ path: OUT + `pusto-${w}.png` });
  await p.click('#wyczysc'); await p.waitForTimeout(100);
  const rs = await p.evaluate(() => ({ chips: document.querySelectorAll('#zab-oferty .zab-chip').length, checked: document.querySelectorAll('#zab-oferty input[name=zabieg]:checked').length, vis: [...document.querySelectorAll('#lista-ofert > .offer')].filter(o => o.getClientRects().length).length, btn: document.querySelector('#zab-oferty .zab-open').textContent.trim(), focus: document.activeElement.name }));
  log('„Wyczyść filtry” w pustym stanie ->', JSON.stringify(rs));
  check(rs.chips === 0 && rs.checked === 0 && rs.vis === os.length && rs.btn === 'Wybierz zabiegi', `${w}: reset formularza`);
  if (errs.length) { log('BŁĘDY KONSOLI', errs); FAIL.push(`${w} konsola: ${errs.join(' | ')}`); } else log('konsola: brak błędów/ostrzeżeń');
  await ctx.close();
}

async function urlGet(b) {
  log('\n=== GET ?zabieg=g1-17&zabieg=g2-32 (JS on, 1440 i 390)');
  for (const [w, h, m] of [[1440, 900, false], [390, 844, true]]) {
    const ctx = await b.newContext({ viewport: { width: w, height: h }, isMobile: m, hasTouch: m });
    const p = await ctx.newPage(); const errs = []; p.on('pageerror', e => errs.push(e.message));
    await p.goto(BASE + '?zawod=&wojewodztwo=&umowa=&zabieg=g1-17&zabieg=g2-32&zabieg=nieznane#oferty', { waitUntil: 'load' }); await p.waitForTimeout(200);
    const r = await p.evaluate(() => ({ checked: [...document.querySelectorAll('#zab-oferty input:checked')].map(x => x.value), chips: [...document.querySelectorAll('#zab-oferty .zab-chip')].map(c => c.textContent), vis: [...document.querySelectorAll('#lista-ofert > .offer')].filter(o => o.getClientRects().length).length, liczba: document.getElementById('ofert-liczba').textContent, spChecked: document.querySelectorAll('#zab-sp input:checked').length, filtryOpen: document.getElementById('filtry-panel').open, aktywne: document.getElementById('filtry-aktywne').textContent }));
    log(w, JSON.stringify(r), errs);
    // pozycja z obu list (g1-17 – Manicure) ma checkbox w obu sekcjach z tym samym value – oba zaznaczone, liczona raz
    check([...new Set(r.checked)].join() === 'g1-17,g2-32' && r.checked.filter((v) => v === 'g1-17').length === 2 && r.vis === 2, `GET ${w}: wybór z adresu`);
    await ctx.close();
  }
}

// Stary adres filtra z identyfikatorem wycofanym z listy (11 §11.10, scenariusz 9.6 pkt 26): filtr nadal działa, okno wyboru nie ma
// checkboxa tej pozycji, chip z dopiskiem, ukryte pole zabieg (ponowne wysłanie GET), usunięcie chipa i „Wyczyść” je usuwają.
// Karta ogłoszenia z wycofanym id: nazwa z dopiskiem (00, Q1), klasa zab-tag-wycofany.
async function urlWycofane(b) {
  log('\n=== GET ze starym (wycofanym) identyfikatorem: ?zabieg=g3-18 i ?zabieg=g3-18&zabieg=g1-17 (JS on, 1440 i 390)');
  const nazwa = (id) => WYC.find((x) => x.id === id).nazwa + DOPISEK;  // w stan() i kartach twarda spacja (typografia.py, od 17.11.2026) = spacja
  const stan = () => ({
    vis: [...document.querySelectorAll('#lista-ofert > .offer')].map((o) => o.getClientRects().length > 0 && !document.getElementById('lista-ofert').hidden),
    chips: [...document.querySelectorAll('#zab-oferty .zab-chip')].map((c) => c.textContent.replace(/\u00a0/g, ' ').trim()),
    ukryte: [...document.querySelectorAll('#zab-oferty input[type=hidden][name=zabieg]')].map((i) => i.value),
    btn: document.querySelector('#zab-oferty .zab-open').textContent.trim(),
  });
  for (const [w, h, m] of [[1440, 900, false], [390, 844, true]]) {
    for (const ids of [['g3-18'], ['g3-18', 'g1-17']]) {
      const ctx = await b.newContext({ viewport: { width: w, height: h }, isMobile: m, hasTouch: m });
      const p = await ctx.newPage(); const errs = []; p.on('pageerror', (e) => errs.push(e.message));
      await p.goto(BASE + '?' + ids.map((i) => 'zabieg=' + i).join('&') + '#oferty', { waitUntil: 'load' }); await p.waitForTimeout(200);
      const os = await p.evaluate(offersState);
      const exp = os.map((o) => o.ids.some((id) => ids.includes(id)));
      let r = await p.evaluate(stan);
      log(w, ids.join('+'), JSON.stringify(r), errs);
      check(exp.some(Boolean) && JSON.stringify(r.vis) === JSON.stringify(exp), `GET wycofane ${w} ${ids}: filtr (widoczne ${r.vis} ≠ ${exp})`);
      check(r.chips.includes(nazwa('g3-18')) && r.chips.length === ids.length && r.btn === 'Zabiegi: wybrano ' + ids.length, `GET wycofane ${w} ${ids}: chipy/przycisk ${r.chips} ${r.btn}`);
      check(JSON.stringify(r.ukryte) === '["g3-18"]', `GET wycofane ${w} ${ids}: ukryte pole zabieg ${r.ukryte}`);
      check(await p.locator('#zab-oferty-dlg input[value="g3-18"]').count() === 0, `GET wycofane ${w} ${ids}: okno wyboru bez checkboxa wycofanej pozycji`);
      if (ids.length === 2) {
        // usunięcie chipa wycofanej pozycji: zostaje filtr g1-17
        await openFilters(p); await p.click('#zab-oferty .zab-chip[data-id="g3-18"]'); await p.waitForTimeout(80);
        r = await p.evaluate(stan);
        const exp2 = os.map((o) => o.ids.includes('g1-17'));
        check(JSON.stringify(r.vis) === JSON.stringify(exp2) && r.ukryte.length === 0 && r.chips.length === 1, `GET wycofane ${w}: usunięcie chipa wycofanej pozycji ${JSON.stringify(r)}`);
      } else {
        // „Wyczyść” w oknie usuwa także wycofaną pozycję
        await openFilters(p); await openDlg(p, 'zab-oferty'); await p.click('#zab-oferty-dlg .zab-clear'); await p.waitForTimeout(60);
        await p.click('#zab-oferty-dlg .drawer-close'); await p.waitForTimeout(100);
        r = await p.evaluate(stan);
        check(r.vis.every(Boolean) && r.ukryte.length === 0 && r.chips.length === 0 && r.btn === 'Wybierz zabiegi', `GET wycofane ${w}: „Wyczyść” ${JSON.stringify(r)}`);
      }
      check(errs.length === 0, `GET wycofane ${w} ${ids}: błędy JS ${errs}`);
      await ctx.close();
    }
  }
  // karta ogłoszenia z wycofanymi id – z JS i bez JS
  for (const js of [true, false]) {
    const ctx = await b.newContext({ viewport: { width: 1440, height: 900 }, javaScriptEnabled: js });
    const p = await ctx.newPage();
    await p.goto(BASE + '#oferty', { waitUntil: 'load' });
    const k = await p.evaluate(() => [...document.querySelectorAll('#lista-ofert .zab-tags')].map((t) => ({
      ids: t.getAttribute('data-ids').split(' '), wyc: [...t.querySelectorAll('li.zab-tag-wycofany')].map((l) => l.textContent.replace(/\u00a0/g, ' ')),
      kolor: (t.querySelector('li.zab-tag-wycofany') ? getComputedStyle(t.querySelector('li.zab-tag-wycofany')).color : null),
      zwykly: getComputedStyle(t.querySelector('li')).color })).filter((x) => x.ids.some((id) => /^g3-/.test(id))));
    log('karty z wycofanymi id (' + (js ? 'z JS' : 'bez JS') + '):', JSON.stringify(k));
    check(k.length >= 1 && k.every((x) => JSON.stringify(x.wyc) === JSON.stringify(x.ids.filter((id) => /^g3-/.test(id)).map(nazwa)) && x.kolor && x.kolor !== x.zwykly),
      `karta z wycofanymi id (${js ? 'z JS' : 'bez JS'}): nazwy z dopiskiem i osobny wygląd`);
    await ctx.close();
  }
}

async function exhaustive(b) {
  log(`\n=== Filtr – wszystkie ${N_POL} pozycji (${N_ZAB} zabiegów) pojedynczo + 300 losowych kombinacji z innymi filtrami (1440, JS on)`);
  const ctx = await b.newContext({ viewport: { width: 1440, height: 900 } });
  const p = await ctx.newPage();
  await p.goto(BASE + '#oferty', { waitUntil: 'load' }); await p.waitForTimeout(200);
  const res = await p.evaluate(() => {
    const ff = document.getElementById('f-filtry');
    const boxes = [...ff.querySelectorAll('input[name=zabieg]')];
    const offers = [...document.querySelectorAll('#lista-ofert > .offer')];
    const data = offers.map(o => ({ ids: o.querySelector('.zab-tags').getAttribute('data-ids').split(' '), z: o.dataset.zawod, w: o.dataset.woj, u: o.dataset.umowa }));
    const set = (sel, z, w, u) => {
      boxes.forEach(b => { b.checked = sel.includes(b.value); });
      (ff.querySelector(`input[name=zawod][value="${z}"]`)).checked = true;
      ff.elements.wojewodztwo.value = w; ff.elements.umowa.value = u;
      boxes[0].dispatchEvent(new Event('change', { bubbles: true }));
    };
    const vis = () => offers.map(o => o.getClientRects().length > 0 && !document.getElementById('lista-ofert').hidden);
    const bad = []; let n = 0, nonEmpty = 0;
    const zs = ['', 'kosmetolog', 'fryzjer', 'tatuazysta'], ws = ['', 'malopolskie', 'pomorskie'], us = ['', 'umowa-o-prace', 'b2b'];
    const runOne = (sel, z, w, u) => {
      set(sel, z, w, u); n++;
      const exp = data.map(d => (!sel.length || sel.some(id => d.ids.includes(id))) && (!z || d.z === z) && (!w || d.w === w) && (!u || d.u === u));
      const got = vis();
      const cnt = exp.filter(Boolean).length;
      const doneTxt = document.querySelector('#zab-oferty-dlg .zab-done').textContent;
      const lic = document.getElementById('ofert-liczba').textContent;
      if (cnt) nonEmpty++;
      if (JSON.stringify(exp) !== JSON.stringify(got) || doneTxt !== 'Pokaż ogłoszenia (' + cnt + ')' || (cnt ? !lic.startsWith(cnt + ' ') : lic !== 'Brak ogłoszeń')) bad.push({ sel, z, w, u, exp, got, doneTxt, lic });
    };
    boxes.forEach(b => runOne([b.value], '', '', ''));
    let seed = 7; const rnd = k => { seed = (seed * 1103515245 + 12345) % 2147483648; return seed % k; };
    const all = boxes.map(b => b.value), used = [...new Set(data.flatMap(d => d.ids))];
    for (let i = 0; i < 300; i++) {
      const k = 1 + rnd(5), sel = [];
      for (let j = 0; j < k; j++) sel.push(rnd(2) ? used[rnd(used.length)] : all[rnd(all.length)]);
      runOne([...new Set(sel)], zs[rnd(zs.length)], ws[rnd(ws.length)], us[rnd(us.length)]);
    }
    // kolejność widocznych = DOM = od najnowszych
    const dates = offers.map(o => o.querySelector('time').getAttribute('datetime'));
    const sortedDesc = dates.every((d, i) => i === 0 || dates[i - 1] >= d);
    return { n, nonEmpty, bad: bad.slice(0, 5), badN: bad.length, sortedDesc, dates };
  });
  log(JSON.stringify(res));
  check(res.badN === 0, 'filtr wyczerpujący: rozbieżności ' + res.badN);
  // Szukam pracy – ten sam mechanizm
  await p.goto(BASE + '#szukam-pracy', { waitUntil: 'load' }); await p.waitForTimeout(200);
  const sp = await p.evaluate(() => {
    const sf = document.getElementById('f-sp-filtry');
    const boxes = [...sf.querySelectorAll('input[name=zabieg]')];
    const cands = [...document.querySelectorAll('#sp-lista > .cand')];
    const data = cands.map(c => { const t = c.querySelector('.zab-tags'); return t ? t.getAttribute('data-ids').split(' ') : []; });
    const bad = [];
    boxes.forEach(b => {
      boxes.forEach(x => { x.checked = x === b; }); b.dispatchEvent(new Event('change', { bubbles: true }));
      const exp = data.map(ids => ids.includes(b.value)), got = cands.map(c => c.getClientRects().length > 0 && !document.getElementById('sp-lista').hidden);
      if (JSON.stringify(exp) !== JSON.stringify(got)) bad.push(b.value);
    });
    return { n: boxes.length, cands: data, bad };
  });
  log(`Szukam pracy – ${N_POL} pozycji (${N_ZAB} zabiegów) pojedynczo:`, JSON.stringify(sp));
  check(sp.bad.length === 0, 'SP filtr rozbieżności');
  await ctx.close();
}

async function spDialog(b) {
  log('\n=== „Szukam pracy” – okno zabiegów (390, JS on)');
  const ctx = await b.newContext({ viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true });
  const p = await ctx.newPage(); const errs = []; p.on('pageerror', e => errs.push(e.message)); p.on('console', m => { if (m.type() === 'error') errs.push(m.text()); });
  await p.goto(BASE + '#szukam-pracy', { waitUntil: 'load' }); await p.waitForTimeout(200);
  await openDlg(p, 'zab-sp');
  let s = await p.evaluate(dlgState, 'zab-sp'); log('otwarte', JSON.stringify({ open: s.open, count: s.count, done: s.done, active: s.active }));
  await p.fill('#zab-sp-q', 'MASAZ'); await p.waitForTimeout(40);
  s = await p.evaluate(dlgState, 'zab-sp'); log('MASAZ ->', s.visible);
  await p.click('#zab-sp-dlg input[value="g1-21"]'); s = await p.evaluate(dlgState, 'zab-sp'); log('g1-21 ->', s.count, '|', s.done);
  await p.click('#zab-sp-dlg .zab-done'); await p.waitForTimeout(150);
  const r = await p.evaluate(() => ({ focus: document.activeElement.id, vis: [...document.querySelectorAll('#sp-lista > .cand')].filter(c => c.getClientRects().length).length, liczba: document.getElementById('sp-liczba').textContent, chips: [...document.querySelectorAll('#zab-sp .zab-chip')].map(c => c.getAttribute('aria-label')) }));
  log('po Pokaż ->', JSON.stringify(r));
  const a = await p.evaluate(audit); log('audit', JSON.stringify({ sw: a.sw, cw: a.cw, small: a.small, blurInVp: a.blurInVp }));
  await p.screenshot({ path: OUT + 'sp-390.png' });
  log('błędy', errs);
  await ctx.close();
}

async function jsOff(b, w, h, mobile) {
  log(`\n=== JS off ${w}x${h}`);
  const ctx = await b.newContext({ viewport: { width: w, height: h }, isMobile: mobile, hasTouch: mobile, javaScriptEnabled: false });
  const p = await ctx.newPage(); const errs = []; p.on('console', m => { if (m.type() === 'error') errs.push(m.text()); });
  await p.goto(BASE, { waitUntil: 'load' }); await p.waitForTimeout(200);
  const a = await p.evaluate(audit); log('audit', JSON.stringify(a));
  check(a.sw <= a.cw, `noJS ${w}: poziomy scroll ${a.sw}>${a.cw} ${a.wide}`);
  check(a.small.length === 0, `noJS ${w}: tekst <12 ${a.small}`);
  check(a.blurInVp <= 3, `noJS ${w}: backdrop ${a.blurInVp}`);
  const st = await p.evaluate(() => {
    const fs = document.getElementById('zab-oferty');
    const grps = [...fs.querySelectorAll('details.zab-grp')];
    return { form: fs.form ? fs.form.id + ' ' + fs.form.method + ' ' + fs.form.getAttribute('action') : null, grps: grps.map(g => ({ open: g.open, sum: g.querySelector('summary').textContent, n: g.querySelectorAll('input[name=zabieg]').length, legend: g.querySelector('legend').textContent })), hint: document.getElementById('zab-oferty-opis').textContent, openBtn: !!fs.querySelector('.zab-open'), filtryOpen: document.getElementById('filtry-panel').open };
  });
  log('struktura bez JS', JSON.stringify(st));
  await p.click('#zab-oferty .zab-grp[data-lista="lista-1"] > summary');
  await p.click('#zab-oferty .zab-grp[data-lista="lista-2"] > summary');
  const tg = await p.evaluate(smallTargets, '#f-filtry'); log('cele <24 w filtrach bez JS (grupy 1–2 otwarte)', JSON.stringify(tg.slice(0, 8)), tg.length);
  const rows = await p.$$eval('#zab-oferty .zab-grp[data-lista="lista-1"] label.check-row', l => l.slice(0, 3).map(x => Math.round(x.getBoundingClientRect().height)));
  log('wysokość wierszy checkboxów', rows);
  const a2 = await p.evaluate(audit); log('audit z otwartymi grupami', JSON.stringify({ sw: a2.sw, cw: a2.cw, wide: a2.wide, small: a2.small }));
  check(a2.sw <= a2.cw, `noJS ${w}: poziomy scroll z otwartymi grupami`);
  await p.screenshot({ path: OUT + `nojs-filtry-${w}.png`, clip: await p.$eval('#f-filtry', e => { const r = e.getBoundingClientRect(); return { x: Math.max(0, r.x), y: r.y + scrollY, width: Math.min(r.width, innerWidth), height: Math.min(r.height, 2400) }; }) , fullPage: true});
  await p.click('#zab-oferty input[value="g1-17"]');
  await p.click('#zab-oferty input[value="g2-32"]');
  await Promise.all([p.waitForNavigation({ waitUntil: 'load' }).catch(() => {}), p.click('#f-filtry button[type=submit]')]);
  const url = p.url(); log('URL po wysłaniu formularza:', url.slice(url.indexOf('?')));
  check(/zabieg=g1-17&zabieg=g2-32/.test(url), `noJS ${w}: GET bez zabiegów w adresie`);
  log('błędy', errs);
  await ctx.close();
}

(async () => {
  const b = await chromium.launch();
  for (const [w, h, m] of VPS) await jsOn(b, w, h, m, 'no-preference');
  for (const [w, h, m] of [[1440, 900, false], [390, 844, true], [320, 640, true]]) await jsOn(b, w, h, m, 'reduce');
  await urlGet(b);
  await urlWycofane(b);
  await exhaustive(b);
  await spDialog(b);
  for (const [w, h, m] of VPS) await jsOff(b, w, h, m);
  await b.close();
  log('\n=== PODSUMOWANIE: ' + (FAIL.length ? FAIL.length + ' niepowodzeń\n' + FAIL.join('\n') : 'wszystkie asercje OK'));
})().catch(e => { console.error('SKRYPT', e); process.exit(2); });
