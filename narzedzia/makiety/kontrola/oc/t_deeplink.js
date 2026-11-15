const { chromium } = require('playwright');
const REPO = require('path').resolve(__dirname, '../../../..');  // katalog główny repozytorium
const FILE = 'file://' + REPO + '/docs/koncepcja/design/v3/oc-beauty.html';
(async () => {
  const b = await chromium.launch();
  for (const motion of ['no-preference', 'reduce']) for (const [w, h] of [[1440, 900], [390, 844]]) {
    const ctx = await b.newContext({ viewport: { width: w, height: h }, reducedMotion: motion });
    const p = await ctx.newPage();
    await p.goto(FILE, { waitUntil: 'networkidle' });
    await p.fill('#z-szukaj', 'henna'); await p.waitForTimeout(450);
    await p.evaluate(() => { location.hash = 'klamry-ortonyksyjne-aplikacja-i-aktywacje' });
    const res = [];
    for (const t of [300, 1500]) { await p.waitForTimeout(t); res.push(await p.evaluate(() => { const t = document.getElementById('klamry-ortonyksyjne-aplikacja-i-aktywacje'); const r = t.getBoundingClientRect(); return { y: Math.round(scrollY), top: Math.round(r.top), inView: r.top >= 0 && r.bottom <= innerHeight, q: document.getElementById('z-szukaj').value } })) }
    // ten sam scenariusz przez kliknięcie linku w treści (np. link do #grupa-4 przy filtrze ukrywającym grupę 4)
    await p.fill('#z-szukaj', 'henna'); await p.waitForTimeout(450);
    await p.evaluate(() => { location.hash = '' });
    await p.evaluate(() => { const a = document.createElement('a'); a.href = '#zabiegi-z-uzyciem-nici-pdo'; a.id = '__t'; a.textContent = 'x'; document.body.prepend(a) });
    await p.evaluate(() => document.getElementById('__t').click()); await p.waitForTimeout(1500);
    res.push(await p.evaluate(() => { const t = document.getElementById('zabiegi-z-uzyciem-nici-pdo'); const r = t.getBoundingClientRect(); return { click: true, top: Math.round(r.top), inView: r.top >= 0 && r.bottom <= innerHeight, hidden: !!t.closest('[hidden]'), q: document.getElementById('z-szukaj').value } }));
    console.log(motion, w, JSON.stringify(res));
    await ctx.close();
  }
  await b.close();
})();
