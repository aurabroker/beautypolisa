// Testy słownika (slownik.html) i dymków pojęć na 9 stronach. Uruchomienie: node test_slownik.js
const REPO = require('path').resolve(__dirname, '../../../..');  // katalog główny repozytorium
const WYNIKI = require('path').join(__dirname, '../wyniki/slownik') + '/';  // zrzuty i wyniki (poza gitem)
const { chromium } = require('playwright');
const fs = require('fs');
const V3 = 'file://' + REPO + '/docs/koncepcja/design/v3/';
const OUT = WYNIKI;
const AXE = fs.readFileSync(require.resolve('axe-core/axe.min.js'), 'utf8');
fs.mkdirSync(OUT, { recursive: true });
const STRONY = ['makieta-v3.html', 'oc-beauty.html', 'tax-protect.html', 'utrata-dochodu.html', 'nnw-dzieci.html', 'grupowe-ergo.html',
  'strefa/logowanie.html', 'strefa/panel.html', 'strefa/dam-prace.html', 'slownik.html'];
const W = [320, 360, 390, 768, 1024, 1280, 1440];
const wyniki = [], bledy = [];
const ok = (c, m) => { if (!c) bledy.push(m); };

const small = () => [...document.querySelectorAll('body *')].filter(e => e.childNodes.length && [...e.childNodes].some(n => n.nodeType === 3 && n.textContent.trim()) && parseFloat(getComputedStyle(e).fontSize) < 12 && e.offsetParent && !e.closest('.sr-only')).map(e => e.tagName + ':' + e.textContent.trim().slice(0, 30));
const tafle = () => [...document.querySelectorAll('body *')].filter(e => { const cs = getComputedStyle(e); const bf = cs.backdropFilter || cs.webkitBackdropFilter; if (!bf || bf === 'none') return false; const r = e.getBoundingClientRect(); return r.width > 0 && r.height > 0 && r.bottom > 0 && r.top < innerHeight && cs.visibility !== 'hidden'; }).length;

(async () => {
  const b = await chromium.launch();
  const TRYB = process.argv[2] || 'reszta';
  // ---------- 1. wszystkie strony: szerokości, błędy JS, < 12 px, tafle
  for (const s of (TRYB === 'szer' ? STRONY : [])) {
    for (const w of W) {
      const p = await b.newPage({ viewport: { width: w, height: 860 } });
      const err = [];
      p.on('pageerror', e => err.push(e.message));
      p.on('console', m => { if (m.type() === 'error' && !/Failed to load resource|ERR_FILE_NOT_FOUND|net::/.test(m.text())) err.push(m.text()); });
      await p.goto(V3 + s, { waitUntil: 'load' });
      await p.waitForTimeout(250);
      const sw0 = await p.evaluate(() => document.documentElement.scrollWidth);
      let maxT = await p.evaluate(tafle);
      const H = await p.evaluate(() => document.documentElement.scrollHeight);
      for (let y = 0; y < H; y += Math.max(600, Math.floor(H / 14))) { await p.evaluate(y => window.scrollTo(0, y), y); await p.waitForTimeout(60); maxT = Math.max(maxT, await p.evaluate(tafle)); }
      await p.evaluate(() => window.scrollTo(0, document.documentElement.scrollHeight)); await p.waitForTimeout(150);
      const sw1 = await p.evaluate(() => document.documentElement.scrollWidth);
      const sm = await p.evaluate(small);
      const n = await p.evaluate(() => document.querySelectorAll('a.bp-termin').length);
      ok(sw0 <= w && sw1 <= w, `${s}@${w}: przewijanie w poziomie ${sw0}/${sw1}`);
      ok(!err.length, `${s}@${w}: błędy JS ${JSON.stringify(err)}`);
      ok(!sm.length, `${s}@${w}: tekst < 12px ${JSON.stringify(sm.slice(0, 5))}`);
      ok(maxT <= 3, `${s}@${w}: tafle backdrop-filter w widoku ${maxT}`);
      if (w === 320 || w === 1440) wyniki.push(`${s}@${w}: sw ${sw0}/${sw1}, tafle max ${maxT}, oznaczeń ${n}`);
      await p.close();
    }
  }

  if (TRYB === 'szer') { await b.close(); console.log(wyniki.join('\n')); console.log('\nBŁĘDY (' + bledy.length + '):\n' + bledy.join('\n')); return; }
  // ---------- 2. dymki na stronach z oznaczeniami
  for (const s of STRONY.filter(x => x !== 'slownik.html')) {
    for (const w of [320, 1280]) {
      const p = await b.newPage({ viewport: { width: w, height: 800 } });
      await p.goto(V3 + s, { waitUntil: 'load' }); await p.waitForTimeout(200);
      // strefa: ekrany makiety mogą być ukryte – bierzemy pierwszy widoczny termin
      const idx = await p.evaluate(() => [...document.querySelectorAll('a.bp-termin')].findIndex(a => a.checkVisibility() && a.offsetParent));
      if (idx < 0) { wyniki.push(`${s}@${w}: brak widocznego oznaczenia`); await p.close(); continue; }
      const a = p.locator('a.bp-termin').nth(idx);
      const id = await a.getAttribute('data-termin');
      ok(await a.getAttribute('role') === 'button' && await a.getAttribute('aria-haspopup') === 'dialog', `${s}: rola przycisku`);
      ok((await a.getAttribute('href')).endsWith('slownik.html#haslo-' + id), `${s}: href ${await a.getAttribute('href')}`);
      await a.scrollIntoViewIfNeeded(); await p.waitForTimeout(400);
      // Enter z klawiatury
      await a.focus(); await p.keyboard.press('Enter'); await p.waitForTimeout(100);
      let st = await p.evaluate(() => { const d = document.getElementById('bp-dymek'); const r = d.getBoundingClientRect(); return { open: !d.hidden, focusIn: d.contains(document.activeElement), l: r.left, r: r.right, t: r.top, b: r.bottom, vw: document.documentElement.clientWidth, vh: innerHeight, title: d.querySelector('.bp-dymek-t').textContent, def: d.querySelector('.bp-dymek-d').textContent, more: d.querySelector('.bp-dymek-wiecej').getAttribute('href'), role: d.getAttribute('role'), lab: d.getAttribute('aria-labelledby') }; });
      ok(st.open && st.focusIn, `${s}@${w}: Enter nie otwiera / fokus poza dymkiem ${JSON.stringify(st)}`);
      ok(st.l >= 0 && st.r <= st.vw && st.t >= 0 && st.b <= st.vh, `${s}@${w}: dymek poza oknem ${JSON.stringify(st)}`);
      ok(await a.getAttribute('aria-expanded') === 'true', `${s}: aria-expanded`);
      ok(st.role === 'dialog' && st.lab === 'bp-dymek-t', `${s}: role/label`);
      ok(st.more.endsWith('slownik.html#haslo-' + id), `${s}: link więcej ${st.more}`);
      const sm = await p.evaluate(small);
      ok(!sm.length, `${s}@${w}: dymek < 12px ${JSON.stringify(sm)}`);
      if (w === 320) await p.screenshot({ path: OUT + `dymek-${s.replace('/', '-')}-${w}.png` });
      if (w === 1280 && s === 'tax-protect.html') await p.screenshot({ path: OUT + `dymek-tax-1280.png` });
      // najechanie na dymek nie zamyka
      await p.mouse.move((st.l + st.r) / 2, (st.t + st.b) / 2); await p.waitForTimeout(300);
      ok(await p.evaluate(() => !document.getElementById('bp-dymek').hidden), `${s}: znika przy najechaniu`);
      // Esc zamyka i oddaje fokus
      await p.keyboard.press('Escape'); await p.waitForTimeout(80);
      st = await p.evaluate(() => ({ open: !document.getElementById('bp-dymek').hidden, back: document.activeElement && document.activeElement.classList.contains('bp-termin') }));
      ok(!st.open && st.back, `${s}@${w}: Esc ${JSON.stringify(st)}`);
      ok(await a.getAttribute('aria-expanded') === 'false', `${s}: aria-expanded po Esc`);
      // Spacja otwiera, Tab przechodzi przez link i przycisk, Tab za ostatnim wraca do pojęcia
      await p.keyboard.press(' '); await p.waitForTimeout(80);
      ok(await p.evaluate(() => !document.getElementById('bp-dymek').hidden), `${s}: Spacja`);
      await p.keyboard.press('Tab'); const f1 = await p.evaluate(() => document.activeElement.className);
      await p.keyboard.press('Tab'); const f2 = await p.evaluate(() => document.activeElement.className);
      await p.keyboard.press('Tab'); const f3 = await p.evaluate(() => ({ c: document.activeElement.className, open: !document.getElementById('bp-dymek').hidden }));
      ok(f1 === 'bp-dymek-wiecej' && f2 === 'bp-dymek-x' && /bp-termin/.test(f3.c) && !f3.open, `${s}: kolejność Tab ${f1} ${f2} ${JSON.stringify(f3)}`);
      // klik otwiera, klik poza zamyka
      await a.click(); await p.waitForTimeout(80);
      ok(await p.evaluate(() => !document.getElementById('bp-dymek').hidden), `${s}: klik`);
      await p.mouse.click(5, Math.floor((await p.evaluate(() => innerHeight)) / 2)); await p.waitForTimeout(80);
      ok(await p.evaluate(() => document.getElementById('bp-dymek').hidden), `${s}: klik poza`);
      // zamknij przyciskiem
      await a.click(); await p.waitForTimeout(80); await p.locator('.bp-dymek-x').click(); await p.waitForTimeout(80);
      ok(await p.evaluate(() => document.getElementById('bp-dymek').hidden && document.activeElement.classList.contains('bp-termin')), `${s}: Zamknij`);
      if (w === 1280) wyniki.push(`${s}: dymek „${st.title || ''}” OK`);
      await p.close();
    }
  }

  // ---------- 3. słownik: wyszukiwarka, filtry, indeks, stan pusty, kopiuj link
  {
    const ctx = await b.newContext({ viewport: { width: 1440, height: 900 } });
    const p = await ctx.newPage();
    await p.goto(V3 + 'slownik.html', { waitUntil: 'load' }); await p.waitForTimeout(200);
    const vis = () => p.evaluate(() => [...document.querySelectorAll('.haslo')].filter(h => !h.hidden && !h.closest('.sl-litera').hidden).map(h => h.id));
    ok((await vis()).length === 95, 'wszystkie 95 widoczne');
    await p.fill('#sl-q', 'skladka'); await p.waitForTimeout(450);
    let v = await vis(); let live = await p.textContent('#sl-licznik');
    ok(v.includes('haslo-skladka'), 'skladka -> Składka ' + v);
    wyniki.push(`szukaj „skladka”: ${v.join(', ')} | licznik: ${live}`);
    await p.fill('#sl-q', 'L4'); await p.waitForTimeout(450); v = await vis();
    wyniki.push(`szukaj „L4”: ${v.join(', ')} | ${await p.textContent('#sl-licznik')}`);
    await p.fill('#sl-q', 'zzqx'); await p.waitForTimeout(450);
    ok(await p.isVisible('#sl-pusto'), 'stan pusty');
    wyniki.push(`stan pusty: ${(await p.textContent('#sl-pusto .sl-pusto-t')).trim()} | ${await p.textContent('#sl-licznik')}`);
    const off = await p.evaluate(() => [...document.querySelectorAll('.sl-az a[data-litera]')].filter(a => !a.hasAttribute('href')).length);
    ok(off >= 20, 'litery nieaktywne przy braku wyników ' + off);
    await p.screenshot({ path: OUT + 'slownik-pusto-1440.png' });
    await p.click('#sl-pusto-reset'); await p.waitForTimeout(100);
    ok((await vis()).length === 95, 'reset');
    await p.click('#sl-kat > summary'); await p.waitForTimeout(100);   // kategorie w rozwijanym panelu (po kontroli 13.11)
    await p.locator('.sl-chip', { hasText: 'Tax Protect' }).click(); await p.waitForTimeout(450);
    v = await vis(); wyniki.push(`kategoria Tax Protect: ${v.join(', ')} | ${await p.textContent('#sl-licznik')}`);
    const azOff = await p.evaluate(() => [...document.querySelectorAll('.sl-az a[data-litera]')].filter(a => !a.hasAttribute('href')).map(a => a.textContent).join(''));
    wyniki.push(`  litery nieaktywne: ${azOff}`);
    // link „Zobacz też” do hasła spoza filtra czyści filtr
    await p.evaluate(() => { location.hash = ''; });
    await p.locator('#haslo-ochrona-karnoskarbowa .haslo-linki a').first().click(); await p.waitForTimeout(300);
    const h = await p.evaluate(() => location.hash);
    const tv = await p.evaluate(id => { const e = document.querySelector(id); const r = e.getBoundingClientRect(); return { hidden: e.hidden, top: r.top }; }, h);
    ok(!tv.hidden && tv.top >= 0 && tv.top < 400, 'zobacz też ' + h + JSON.stringify(tv));
    wyniki.push(`zobacz też -> ${h} ${JSON.stringify(tv)}; widocznych ${(await vis()).length}`);
    // sticky panel: po przewinięciu w górę nagłówek nie zachodzi na panel
    await p.evaluate(() => { const r = document.querySelector('input[name="kategoria"][value=""]'); r.checked = true; r.dispatchEvent(new Event('change', { bubbles: true })); document.getElementById('sl-kat').open = false; }); await p.waitForTimeout(100);
    await p.evaluate(() => window.scrollTo(0, 6000)); await p.waitForTimeout(300);
    await p.evaluate(() => window.scrollTo(0, 5600)); await p.waitForTimeout(600);
    const st = await p.evaluate(() => { const a = document.querySelector('.sl-narzedzia').getBoundingClientRect(); const hb = document.querySelector('.header-bar').getBoundingClientRect(); return { aside: [a.top, a.bottom], header: [hb.top, hb.bottom], pos: getComputedStyle(document.querySelector('.sl-narzedzia')).position }; });
    ok(st.aside[0] >= st.header[1], 'panel pod nagłówkiem ' + JSON.stringify(st));
    wyniki.push('sticky 1440x900: ' + JSON.stringify(st));
    await p.screenshot({ path: OUT + 'slownik-sticky-1440.png' });
    // kopiuj link
    await ctx.grantPermissions(['clipboard-read', 'clipboard-write']).catch(() => {});
    await p.evaluate(() => { const r = document.querySelector('input[name="kategoria"][value=""]'); r.checked = true; r.dispatchEvent(new Event('change', { bubbles: true })); document.getElementById('sl-kat').open = false; }); await p.waitForTimeout(100);
    await p.locator('#haslo-karencja .haslo-kopiuj').click(); await p.waitForTimeout(200);
    wyniki.push(`kopiuj: przycisk „${(await p.textContent('#haslo-karencja .haslo-kopiuj-t'))}”, status „${await p.textContent('#sl-kopia-status')}”`);
    // Tab po radio + Esc w polu
    await p.close(); await ctx.close();
  }
  // wejście z kotwicą
  for (const w of [390, 1440]) {
    const p = await b.newPage({ viewport: { width: w, height: 844 } });
    await p.goto(V3 + 'slownik.html#haslo-karencja', { waitUntil: 'load' }); await p.waitForTimeout(500);
    const r = await p.evaluate(() => { const e = document.getElementById('haslo-karencja'); const r = e.getBoundingClientRect(); const hb = document.querySelector('.header-bar').getBoundingClientRect(); return { top: r.top, headerBottom: hb.bottom, target: e.matches(':target') }; });
    ok(r.target && r.top >= r.headerBottom - 2, `kotwica @${w} ${JSON.stringify(r)}`);
    wyniki.push(`#haslo-karencja @${w}: ${JSON.stringify(r)}`);
    await p.screenshot({ path: OUT + `slownik-kotwica-${w}.png` });
    await p.close();
  }
  // bez JS
  {
    const ctx = await b.newContext({ javaScriptEnabled: false, viewport: { width: 390, height: 844 } });
    const p = await ctx.newPage();
    await p.goto(V3 + 'slownik.html', { waitUntil: 'load' });
    const r = await p.evaluate(() => ({ hasla: [...document.querySelectorAll('.haslo')].filter(h => h.offsetParent).length, form: !!document.querySelector('#sl-szukaj').offsetParent, az: document.querySelectorAll('.sl-az a[href]').length, sw: document.documentElement.scrollWidth }));
    ok(r.hasla === 95 && !r.form && r.az > 15 && r.sw <= 390, 'bez JS ' + JSON.stringify(r));
    wyniki.push('bez JS: ' + JSON.stringify(r));
    await p.click('.sl-az a[href="#litera-k"]');
    wyniki.push('bez JS klik K -> ' + await p.evaluate(() => location.hash));
    await p.screenshot({ path: OUT + 'slownik-nojs-390.png' });
    const q = await ctx.newPage();
    await q.goto(V3 + 'tax-protect.html', { waitUntil: 'load' });
    wyniki.push('bez JS tax: pierwsze oznaczenie ' + await q.evaluate(() => { const a = document.querySelector('a.bp-termin'); return a.outerHTML + ' role=' + a.getAttribute('role'); }));
    await ctx.close();
  }
  // zrzuty słownika
  for (const [w, h] of [[320, 740], [390, 844], [768, 1024], [1440, 900]]) {
    const p = await b.newPage({ viewport: { width: w, height: h } });
    await p.goto(V3 + 'slownik.html', { waitUntil: 'load' }); await p.waitForTimeout(400);
    await p.screenshot({ path: OUT + `slownik-${w}-top.png` });
    await p.evaluate(() => document.getElementById('hasla').scrollIntoView()); await p.waitForTimeout(400);
    await p.screenshot({ path: OUT + `slownik-${w}-lista.png` });
    await p.close();
  }
  // axe
  for (const s of ['slownik.html', 'tax-protect.html', 'strefa/panel.html']) {
    const p = await b.newPage({ viewport: { width: 1280, height: 900 } });
    await p.goto(V3 + s, { waitUntil: 'load' }); await p.waitForTimeout(300);
    if (s !== 'slownik.html') { await p.evaluate(() => { const a = [...document.querySelectorAll('a.bp-termin')].find(a => a.offsetParent); a.click(); }); await p.waitForTimeout(100); }
    await p.addScriptTag({ content: AXE });
    const r = await p.evaluate(async () => { const r = await axe.run(document, { runOnly: ['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa', 'best-practice'] }); return r.violations.map(v => v.id + ' (' + v.nodes.length + '): ' + v.nodes.slice(0, 2).map(n => n.target.join(' ')).join(' | ')); });
    wyniki.push(`axe ${s}: ${r.length ? r.join(' ;; ') : 'brak naruszeń'}`);
    await p.close();
  }
  await b.close();
  console.log(wyniki.join('\n'));
  console.log('\nBŁĘDY (' + bledy.length + '):\n' + bledy.join('\n'));
})();
