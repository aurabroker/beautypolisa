// Kontrola oc-beauty.html: przewijanie w poziomie, konsola/zasoby, tekst < 12 px, tafle backdrop-filter w widoku, nagłówki, cele dotyku
const REPO = require('path').resolve(__dirname, '../../../..');  // katalog główny repozytorium
const { chromium } = require('playwright');
const FILE = 'file://' + REPO + '/docs/koncepcja/design/v3/oc-beauty.html';
const VPS = [[1440, 900], [768, 1024], [390, 844], [360, 740]];
(async () => {
  const b = await chromium.launch();
  const out = {};
  for (const [w, h] of VPS) {
    for (const motion of ['no-preference', 'reduce']) {
      const ctx = await b.newContext({ viewport: { width: w, height: h }, reducedMotion: motion, hasTouch: w < 768, isMobile: false });
      const p = await ctx.newPage();
      const errs = [], fails = [], bad = [];
      p.on('pageerror', e => errs.push('pageerror: ' + e.message));
      p.on('console', m => { if (m.type() === 'error' || m.type() === 'warning') errs.push(m.type() + ': ' + m.text()) });
      p.on('requestfailed', r => fails.push(r.url() + ' ' + (r.failure() || {}).errorText));
      p.on('response', r => { if (r.status() >= 400) bad.push(r.status() + ' ' + r.url()) });
      await p.goto(FILE, { waitUntil: 'networkidle' });
      await p.evaluate(() => document.fonts.ready);
      const total = await p.evaluate(() => document.documentElement.scrollHeight);
      const steps = [];
      let maxGlass = 0, maxGlassAt = null, hscroll = false, overflowEls = new Set();
      for (let y = 0; y < total + h; y += Math.round(h / 2)) {
        await p.evaluate(y => window.scrollTo({ top: y, behavior: 'instant' }), y);
        await p.waitForTimeout(motion === 'reduce' ? 60 : 160);
        const r = await p.evaluate(() => {
          const W = document.documentElement.clientWidth, H = innerHeight;
          const glass = [];
          for (const el of document.querySelectorAll('body *')) {
            const cs = getComputedStyle(el);
            const bf = cs.backdropFilter && cs.backdropFilter !== 'none' ? cs.backdropFilter : (cs.webkitBackdropFilter && cs.webkitBackdropFilter !== 'none' ? cs.webkitBackdropFilter : null);
            if (!bf) continue;
            if (!el.checkVisibility({ checkOpacity: false, checkVisibilityCSS: true })) continue;
            const rc = el.getBoundingClientRect();
            if (rc.bottom > 0 && rc.top < H && rc.right > 0 && rc.left < W && rc.width > 0 && rc.height > 0) glass.push((el.id ? '#' + el.id : '') + '.' + [...el.classList].join('.'));
          }
          const sw = document.documentElement.scrollWidth, bw = document.body.scrollWidth;
          const over = [...document.querySelectorAll('body *')].filter(e => { const r = e.getBoundingClientRect(); return r.width > 0 && r.right > W + 0.5 && e.checkVisibility() }).slice(0, 5).map(e => e.tagName + '.' + e.className + ' r=' + Math.round(e.getBoundingClientRect().right));
          return { y: scrollY, glass, sw, bw, W, over };
        });
        if (r.glass.length > maxGlass) { maxGlass = r.glass.length; maxGlassAt = { y: r.y, glass: r.glass } }
        if (r.sw > r.W || r.bw > r.W) hscroll = true;
        r.over.forEach(o => overflowEls.add(o));
        steps.push(r.glass.length);
      }
      // tekst < 12 px (wszystkie widoczne węzły tekstowe + pseudo-elementy z treścią)
      const small = await p.evaluate(() => {
        const res = [];
        const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
        let n;
        while ((n = walker.nextNode())) {
          if (!n.textContent.trim()) continue;
          const el = n.parentElement;
          if (!el || el.closest('script,style,svg,noscript,template')) continue;
          if (!el.checkVisibility({ checkOpacity: false, checkVisibilityCSS: true })) continue;
          const rg = document.createRange(); rg.selectNodeContents(n);
          const rc = rg.getBoundingClientRect();
          if (rc.width <= 1 || rc.height <= 1) continue; // sr-only
          const cs = getComputedStyle(el);
          if (cs.clip && cs.clip !== 'auto' && /rect\(0/.test(cs.clip)) continue;
          const fs = parseFloat(cs.fontSize);
          if (fs < 12) res.push(fs + 'px ' + el.tagName + '.' + el.className + ' "' + n.textContent.trim().slice(0, 40) + '"');
        }
        for (const el of document.querySelectorAll('body *')) {
          for (const ps of ['::before', '::after', '::marker']) {
            const cs = getComputedStyle(el, ps);
            const c = cs.content;
            if (!c || c === 'none' || c === 'normal' || c === '""' || c === "''" || !/^["']/.test(c) || !el.checkVisibility()) continue;
            if (parseFloat(cs.fontSize) < 12 && cs.display !== 'none') res.push(cs.fontSize + ' ' + ps + ' ' + el.tagName + '.' + el.className + ' ' + c.slice(0, 20));
          }
        }
        const inp = document.getElementById('z-szukaj');
        if (inp && inp.checkVisibility()) { const f = parseFloat(getComputedStyle(inp, '::placeholder').fontSize); if (f < 12) res.push('placeholder ' + f) }
        return res;
      });
      // minimalny rozmiar tekstu ogółem
      const minFs = await p.evaluate(() => {
        let m = 99, at = '';
        const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT); let n;
        while ((n = walker.nextNode())) {
          if (!n.textContent.trim()) continue; const el = n.parentElement; if (!el || el.closest('script,style,svg,noscript')) continue;
          if (!el.checkVisibility()) continue; const rg = document.createRange(); rg.selectNodeContents(n); const rc = rg.getBoundingClientRect(); if (rc.width <= 1 || rc.height <= 1) continue;
          const f = parseFloat(getComputedStyle(el).fontSize); if (f < m) { m = f; at = el.tagName + '.' + el.className + ' "' + n.textContent.trim().slice(0, 30) + '"' }
        }
        return m + 'px @ ' + at;
      });
      // animacje (ruch jako ulepszenie / reduced motion)
      await p.evaluate(() => window.scrollTo({ top: 0, behavior: 'instant' })); await p.waitForTimeout(100);
      const anim = await p.evaluate(() => {
        const a = document.getAnimations();
        let trans = 0; for (const el of document.querySelectorAll('*')) { const d = getComputedStyle(el).transitionDuration.split(',').some(x => parseFloat(x) > 0); if (d) trans++ }
        const hiddenRv = [...document.querySelectorAll('.rv-curtain,.rv-rise')].filter(e => parseFloat(getComputedStyle(e).opacity) < 1).length;
        return { animations: a.length, elsWithTransition: trans, scrollBehavior: getComputedStyle(document.documentElement).scrollBehavior, rvBelowOpacity1AtTop: hiddenRv, ioReveal: document.documentElement.classList.contains('io-reveal') };
      });
      out[w + '/' + motion] = { hscroll, overflowEls: [...overflowEls], maxGlass, maxGlassAt, glassPerStep: steps.join(','), small, minFs, anim, errs, fails, bad };
      await ctx.close();
    }
  }
  console.log(JSON.stringify(out, null, 1));
  await b.close();
})();
