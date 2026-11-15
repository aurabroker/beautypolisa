const { chromium } = require('playwright');
const REPO = require('path').resolve(__dirname, '../../../..');  // katalog główny repozytorium
const FILE = 'file://' + REPO + '/docs/koncepcja/design/v3/oc-beauty.html';
(async () => {
  const b = await chromium.launch(); const bad = [];
  for (const js of [true, false]) {
    const ctx = await b.newContext({ viewport: { width: 360, height: 800 }, javaScriptEnabled: js });
    const p = await ctx.newPage(); await p.goto(FILE, { waitUntil: 'networkidle' });
    for (let w = 360; w <= 1440; w += 20) {
      await p.setViewportSize({ width: w, height: 800 }); await p.waitForTimeout(40);
      const r = await p.evaluate(() => ({ sw: document.documentElement.scrollWidth, cw: document.documentElement.clientWidth, small: (() => { let m = 99; const tw = document.createTreeWalker(document.body, 4); let n; while ((n = tw.nextNode())) { if (!n.textContent.trim()) continue; const e = n.parentElement; if (!e || e.closest('script,style,svg,noscript') || !e.checkVisibility()) continue; const rg = document.createRange(); rg.selectNodeContents(n); const rc = rg.getBoundingClientRect(); if (rc.width <= 1 || rc.height <= 1) continue; m = Math.min(m, parseFloat(getComputedStyle(e).fontSize)) } return m })() }));
      if (r.sw > r.cw || r.small < 12) bad.push({ js, w, ...r });
    }
    await ctx.close();
  }
  console.log('szerokości 360–1440 co 20 px, z JS i bez JS; problemy:', JSON.stringify(bad));
  await b.close();
})();
