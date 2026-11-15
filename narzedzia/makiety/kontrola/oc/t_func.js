const { chromium } = require('playwright');
const REPO = require('path').resolve(__dirname, '../../../..');  // katalog główny repozytorium
const fs = require('fs');
const FILE = 'file://' + REPO + '/docs/koncepcja/design/v3/oc-beauty.html';
const Z = JSON.parse(fs.readFileSync(REPO + '/docs/koncepcja/snippets/zabiegi-oc-beauty.json', 'utf8'));
(async () => {
  const b = await chromium.launch();
  const R = {};
  // ---------- bez JS ----------
  for (const [w, h] of [[1440, 900], [360, 740]]) {
    const ctx = await b.newContext({ viewport: { width: w, height: h }, javaScriptEnabled: false });
    const p = await ctx.newPage();
    await p.goto(FILE, { waitUntil: 'networkidle' });
    R['nojs-' + w] = await p.evaluate(() => {
      const lis = [...document.querySelectorAll('.zlist > li')];
      const vis = lis.filter(l => l.checkVisibility({ checkOpacity: true, checkVisibilityCSS: true }));
      const det = [...document.querySelectorAll('.zdetails')].map(d => d.open);
      return { li: lis.length, visible: vis.length, detailsOpen: det, formVisible: document.getElementById('z-szukaj-form').checkVisibility(), jumpVisible: document.querySelector('.zjump').checkVisibility(), sticky: document.querySelector('.sticky-cta').checkVisibility(), hscroll: document.documentElement.scrollWidth > document.documentElement.clientWidth, bgScenes: getComputedStyle(document.querySelector('.scene--marble')).backgroundImage.slice(0, 60) };
    });
    // po przewinięciu na dół (animacje CSS bez JS) – czy treść widoczna
    await p.evaluate(() => window.scrollTo(0, document.documentElement.scrollHeight)); await p.waitForTimeout(300);
    R['nojs-' + w].rvOpacityAfterScroll = await p.evaluate(() => [...document.querySelectorAll('.site-footer .rv-rise')].map(e => getComputedStyle(e).opacity).join(','));
    await ctx.close();
  }
  // ---------- lista vs JSON ----------
  {
    const p = await b.newPage({ viewport: { width: 1440, height: 900 } });
    await p.goto(FILE, { waitUntil: 'networkidle' });
    const dom = await p.evaluate(() => [...document.querySelectorAll('.zgroup')].map(g => ({ id: g.id, h3: g.querySelector('h3').textContent, items: [...g.querySelectorAll('.zlist > li')].map(l => [l.id, l.querySelector('.z-name').textContent, l.attributes.length]) })));
    const errs = [];
    let n = 0;
    for (const g of Z.grupy) {
      const dg = dom.find(d => d.id === g.kotwica);
      if (!dg) { errs.push('brak sekcji ' + g.kotwica); continue }
      if (dg.h3 !== g.nazwa) errs.push('nazwa grupy ' + g.grupa + ': ' + dg.h3);
      const exp = Z.zabiegi.filter(z => z.grupa === g.grupa);
      if (exp.length !== dg.items.length) errs.push('liczba ' + g.grupa);
      exp.forEach((z, i) => { const d = dg.items[i]; n++; if (!d || d[0] !== z.slug || d[1] !== z.nazwa) errs.push('poz ' + z.id + ' ' + JSON.stringify(d)); if (d && d[2] !== 1) errs.push('dodatkowe atrybuty li ' + z.slug) });
    }
    const ids = await p.evaluate(() => { const a = [...document.querySelectorAll('[id]')].map(e => e.id); return a.length - new Set(a).size });
    R.lista = { compared: n, errs, dupIds: ids, groupsInDom: dom.map(d => d.id + ':' + d.items.length) };
    // nagłówki
    R.headings = await p.evaluate(() => [...document.querySelectorAll('h1,h2,h3,h4,h5,h6')].map(h => h.tagName + ' ' + h.textContent.trim().replace(/\s+/g, ' ').slice(0, 50)));
    const lv = R.headings.map(s => +s[1]); const skips = []; lv.forEach((l, i) => { if (i && l > lv[i - 1] + 1) skips.push(R.headings[i]) }); R.headingSkips = skips; R.h1count = lv.filter(l => l === 1).length;
    await p.close();
  }
  // ---------- filtr ----------
  for (const [w, h] of [[1440, 900], [390, 844]]) {
    const p = await b.newPage({ viewport: { width: w, height: h } });
    await p.goto(FILE, { waitUntil: 'networkidle' });
    const live = await p.evaluate(() => { const c = document.getElementById('z-licznik'); return { ariaLive: c.getAttribute('aria-live'), atomic: c.getAttribute('aria-atomic'), formHidden: document.getElementById('z-szukaj-form').hidden, describedby: document.getElementById('z-szukaj').getAttribute('aria-describedby'), label: document.querySelector('label[for=z-szukaj]').textContent, placeholder: document.getElementById('z-szukaj').placeholder } });
    const res = { live };
    for (const q of ['zel', 'żel', 'mezo', 'MEZO', 'mezoterapia', 'henna', 'klamra', 'klamr', 'glowy', 'pedicure', 'laser', 'xyzzy']) {
      await p.fill('#z-szukaj', q);
      await p.waitForTimeout(450);
      res[q] = await p.evaluate(() => {
        const vis = [...document.querySelectorAll('.zlist > li')].filter(l => !l.hidden && !l.closest('[hidden]'));
        return { n: vis.length, names: vis.slice(0, 6).map(l => l.closest('.zgroup').id.slice(-1) + ':' + l.querySelector('.z-name').textContent), count: document.getElementById('z-licznik').textContent, empty: document.getElementById('z-brak').hidden ? '' : document.getElementById('z-brak').textContent, via: document.querySelectorAll('.z-via').length, groupsHidden: [...document.querySelectorAll('.zgroup')].filter(g => g.hidden).map(g => g.id), jumps: [...document.querySelectorAll('.zjump li')].map(li => (li.hidden ? '-' : '+') + li.textContent.trim()), clearVisible: !document.getElementById('z-wyczysc').hidden };
      });
    }
    // reset
    await p.click('#z-wyczysc'); await p.waitForTimeout(100);
    res.afterReset = await p.evaluate(() => ({ count: document.getElementById('z-licznik').textContent, visible: [...document.querySelectorAll('.zlist > li')].filter(l => !l.hidden && !l.closest('[hidden]')).length, focus: document.activeElement.id, open: [...document.querySelectorAll('.zdetails')].map(d => d.open) }));
    // licznik: aktualizacja z opóźnieniem (debounce) – stan po 100 ms i po 450 ms
    await p.fill('#z-szukaj', 'mezo'); await p.waitForTimeout(80);
    const early = await p.textContent('#z-licznik'); await p.waitForTimeout(400); const late = await p.textContent('#z-licznik');
    res.debounce = { early, late };
    // Enter nie przeładowuje strony
    await p.focus('#z-szukaj'); await p.keyboard.press('Enter'); await p.waitForTimeout(150); res.enterKeepsValue = await p.inputValue('#z-szukaj');
    // głęboki link do zabiegu ukrytego filtrem
    await p.fill('#z-szukaj', 'henna'); await p.waitForTimeout(450);
    await p.evaluate(() => { location.hash = 'klamry-ortonyksyjne-aplikacja-i-aktywacje' }); await p.waitForTimeout(400);
    res.deepLinkWhileFiltered = await p.evaluate(() => { const t = document.getElementById('klamry-ortonyksyjne-aplikacja-i-aktywacje'); const r = t.getBoundingClientRect(); return { inputValue: document.getElementById('z-szukaj').value, hidden: !!(t.hidden || t.closest('[hidden]')), top: Math.round(r.top), inView: r.top >= 0 && r.bottom <= innerHeight, targetMatch: t.matches(':target') } });
    R['filtr-' + w] = res;
    await p.close();
  }
  // ---------- kotwice grup i zabiegów, details zamknięte ----------
  for (const [w, h] of [[1440, 900], [360, 740]]) {
    const ctx = await b.newContext({ viewport: { width: w, height: h }, reducedMotion: 'reduce' });
    const p = await ctx.newPage();
    const r = {};
    for (const hash of ['grupa-1', 'grupa-2', 'grupa-3', 'grupa-4', 'zabiegi', 'ochrona-prawna', 'faq', 'taryfa', 'wypelniacze-kwas-hialuronowy', 'barbering', 'pytanie-5']) {
      await p.goto(FILE + '#' + hash, { waitUntil: 'networkidle' }); await p.waitForTimeout(250);
      r[hash] = await p.evaluate(hash => { const t = document.getElementById(hash); const rc = t.getBoundingClientRect(); const hb = document.querySelector('.header-bar').getBoundingClientRect(); return { top: Math.round(rc.top), hdrBottom: Math.round(hb.bottom), belowHeader: rc.top >= hb.bottom - 1, inView: rc.top < innerHeight, open: t.tagName === 'DETAILS' ? t.open : (t.closest('details') ? t.closest('details').open : null) } }, hash);
    }
    // zamknięta grupa 2 + klik w link skoku + głęboki link do zabiegu w zamkniętej grupie
    await p.goto(FILE, { waitUntil: 'networkidle' });
    await p.evaluate(() => { document.querySelectorAll('.zdetails').forEach(d => d.open = false) });
    await p.click('.zjump a[href="#grupa-2"]'); await p.waitForTimeout(300);
    r.jumpClick = await p.evaluate(() => ({ hash: location.hash, open2: document.querySelector('#grupa-2 .zdetails').open, top: Math.round(document.getElementById('grupa-2').getBoundingClientRect().top) }));
    await p.evaluate(() => { location.hash = 'tatuaz' }); await p.waitForTimeout(300);
    r.deepClosed = await p.evaluate(() => { const t = document.getElementById('tatuaz'); return { open: t.closest('details').open, visible: t.checkVisibility(), top: Math.round(t.getBoundingClientRect().top) } });
    // fokus klawiaturą: skip link
    await p.goto(FILE, { waitUntil: 'networkidle' });
    await p.keyboard.press('Tab');
    r.firstTab = await p.evaluate(() => { const a = document.activeElement; const cs = getComputedStyle(a); const rc = a.getBoundingClientRect(); return { text: a.textContent.trim(), visible: rc.top >= 0 && rc.height > 0 && cs.opacity !== '0', outline: cs.outlineStyle + ' ' + cs.outlineWidth } });
    // fokus widoczny na kolejnych elementach
    const fv = [];
    for (let i = 0; i < 14; i++) { await p.keyboard.press('Tab'); fv.push(await p.evaluate(() => { const a = document.activeElement; const cs = getComputedStyle(a); return (a.id || a.className || a.tagName).toString().slice(0, 24) + ':' + (cs.outlineStyle !== 'none' && parseFloat(cs.outlineWidth) > 0 ? 'outline' : (cs.boxShadow !== 'none' ? 'shadow' : 'BRAK')) })) }
    r.focusRing = fv;
    R['kotwice-' + w] = r;
    await ctx.close();
  }
  // ---------- cele dotyku (WCAG 2.2 2.5.8: 24x24, bez linków w tekście) ----------
  for (const [w, h] of [[390, 844], [1440, 900]]) {
    const p = await b.newPage({ viewport: { width: w, height: h } });
    await p.goto(FILE, { waitUntil: 'networkidle' });
    R['target-' + w] = await p.evaluate(() => {
      const res = [];
      for (const el of document.querySelectorAll('a[href],button,summary,input,[tabindex="0"]')) {
        if (!el.checkVisibility()) continue;
        const r = el.getBoundingClientRect(); if (r.width === 0) continue;
        const inline = getComputedStyle(el).display === 'inline' && el.closest('p,li,dd') && el.closest('p,li,dd').textContent.trim() !== el.textContent.trim();
        if (inline) continue;
        if (r.width < 24 || r.height < 24) res.push(el.tagName + '.' + el.className + ' "' + el.textContent.trim().slice(0, 30) + '" ' + Math.round(r.width) + 'x' + Math.round(r.height));
      }
      return res.slice(0, 20);
    });
    await p.close();
  }
  console.log(JSON.stringify(R, null, 1));
  await b.close();
})();
