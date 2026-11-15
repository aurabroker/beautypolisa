// JSON-LD (parsowanie, FAQPage = widoczne FAQ), linki wewnętrzne (#kotwice, pliki, #fragmenty w plikach), odwołania id (use/aria/for), duplikaty id.
const REPO = require('path').resolve(__dirname, '../../../..');  // katalog główny repozytorium
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const DIR = REPO + '/docs/koncepcja/design/v3/';
const PAGES = ['makieta-v3.html', 'oc-beauty.html', 'tax-protect.html', 'utrata-dochodu.html'];
const norm = s => (s || '').replace(/ /g, ' ').replace(/\s+/g, ' ').trim();
const idCache = {};
function idsOf(file) {
  if (idCache[file]) return idCache[file];
  const s = fs.readFileSync(file, 'utf8').replace(/<!--[\s\S]*?-->/g, '');
  return (idCache[file] = new Set([...s.matchAll(/\sid="([^"]+)"/g)].map(m => m[1])));
}
(async () => {
  const b = await chromium.launch();
  for (const pg of PAGES) {
    const ctx = await b.newContext({ viewport: { width: 1440, height: 900 } });
    const p = await ctx.newPage();
    await p.goto('file://' + DIR + pg, { waitUntil: 'load' });
    console.log('\n=====', pg);
    // JSON-LD
    const ld = await p.evaluate(() => [...document.querySelectorAll('script[type="application/ld+json"]')].map(s => s.textContent));
    console.log('JSON-LD bloków:', ld.length);
    let faqLD = null;
    for (const t of ld) {
      let j; try { j = JSON.parse(t); } catch (e) { console.log('  BŁĄD PARSOWANIA:', e.message); continue; }
      const nodes = j['@graph'] || [j];
      console.log('  @context', j['@context'], 'typy:', nodes.map(n => [].concat(n['@type']).join('+') + (n['@id'] ? '(' + n['@id'] + ')' : '')).join(', '));
      // @id referencje
      const ids = new Set(nodes.map(n => n['@id']).filter(Boolean));
      const refs = [];
      (function walk(o) { if (Array.isArray(o)) o.forEach(walk); else if (o && typeof o === 'object') { if (Object.keys(o).length === 1 && o['@id']) refs.push(o['@id']); else Object.values(o).forEach(walk); } })(nodes);
      const dangling = [...new Set(refs)].filter(r => !ids.has(r));
      if (dangling.length) console.log('  @id bez węzła w grafie:', dangling.join(' | '));
      for (const n of nodes) {
        if ([].concat(n['@type']).includes('FAQPage')) faqLD = n;
        for (const k of ['url', '@id']) if (n[k] && typeof n[k] === 'string' && !/^https:\/\/beautypolisa\.eu/.test(n[k]) && /^http/.test(n[k])) console.log('  obca domena w', k, n[k]);
        if ([].concat(n['@type']).includes('BreadcrumbList')) console.log('  Breadcrumb:', n.itemListElement.map(i => i.name + '→' + (i.item && (i.item['@id'] || i.item))).join(' | '));
        if (n.offers) console.log('  offers:', JSON.stringify(n.offers).slice(0, 300));
        if (n.dateModified || n.datePublished) console.log('  daty:', n.datePublished, n.dateModified);
      }
      const txt = t;
      for (const bad of ['orientacyjn', 'szacunkow', 'konsultacja.beautypolisa', '/w/', 'kod zapasow', 'kodów zapasow']) if (txt.includes(bad)) console.log('  ZAKAZANE w JSON-LD:', bad);
    }
    // widoczne FAQ
    const vis = await p.evaluate(() => [...document.querySelectorAll('#faq details')].map(d => ({ id: d.id, q: d.querySelector('summary').textContent, a: [...d.children].filter(c => c.tagName !== 'SUMMARY').map(c => c.textContent).join(' ') })));
    if (faqLD) {
      const ents = faqLD.mainEntity || [];
      console.log('  FAQPage pytań:', ents.length, '| widoczne:', vis.length);
      const n = Math.max(ents.length, vis.length);
      for (let i = 0; i < n; i++) {
        const e = ents[i], v = vis[i];
        const qOK = e && v && norm(e.name) === norm(v.q);
        const aL = e ? norm(e.acceptedAnswer && e.acceptedAnswer.text).replace(/<[^>]+>/g, '') : '';
        const aV = v ? norm(v.a) : '';
        const aOK = aL === aV;
        if (!qOK || !aOK) {
          console.log(`  [${i + 1}] Q ${qOK ? 'OK' : 'RÓŻNE'} A ${aOK ? 'OK' : 'RÓŻNE'}`);
          if (!qOK) console.log('     LD :', e && e.name, '\n     DOM:', v && v.q);
          if (!aOK) { let k = 0; while (k < aL.length && aL[k] === aV[k]) k++; console.log('     od znaku', k, '\n     LD :', aL.slice(Math.max(0, k - 30), k + 90), '\n     DOM:', aV.slice(Math.max(0, k - 30), k + 90)); }
        } else console.log(`  [${i + 1}] OK`);
        if (e && e['@id'] && v && !e['@id'].endsWith('#' + v.id) && !(e.url || '').endsWith('#' + v.id)) {/* opcjonalnie */}
      }
    } else console.log('  brak FAQPage; widocznych pytań FAQ:', vis.length);
    // linki
    const links = await p.evaluate(() => [...document.querySelectorAll('a[href], area[href]')].map(a => ({ h: a.getAttribute('href'), t: a.textContent.trim().replace(/\s+/g, ' ').slice(0, 40), hid: !a.checkVisibility() })));
    const own = idsOf(DIR + pg);
    const domIds = new Set(await p.evaluate(() => [...document.querySelectorAll('[id]')].map(e => e.id)));
    const probs = [], prod = new Set(), ext = new Set();
    for (const { h, t } of links) {
      if (/^(https?:|mailto:|tel:)/.test(h)) { ext.add(h); continue; }
      if (h.startsWith('#')) { const id = decodeURIComponent(h.slice(1)); if (!id) probs.push('pusty # "' + t + '"'); else if (!domIds.has(id)) probs.push(`${h} "${t}" – brak id`); continue; }
      if (h.startsWith('/')) { prod.add(h); continue; }
      const [fp, frag] = h.split('#'); const file = path.resolve(DIR, fp.split('?')[0]);
      if (!fs.existsSync(file)) { probs.push(`${h} "${t}" – brak pliku`); continue; }
      if (frag && !idsOf(file).has(frag)) probs.push(`${h} "${t}" – brak #${frag} w ${path.basename(file)}`);
    }
    // use href, aria-*, for, list
    const refs = await p.evaluate(() => {
      const out = [];
      document.querySelectorAll('use').forEach(u => { const h = u.getAttribute('href') || u.getAttribute('xlink:href'); if (h && h.startsWith('#') && !document.getElementById(h.slice(1))) out.push('use ' + h); });
      document.querySelectorAll('[aria-controls],[aria-labelledby],[aria-describedby],[for],[list],[aria-owns],[aria-activedescendant]').forEach(e => {
        for (const a of ['aria-controls', 'aria-labelledby', 'aria-describedby', 'for', 'list', 'aria-owns', 'aria-activedescendant']) { const v = e.getAttribute(a); if (!v) continue; v.split(/\s+/).forEach(id => { if (!document.getElementById(id)) out.push(`${a}=${id} na ${e.tagName}${e.id ? '#' + e.id : ''}`); }); }
      });
      const c = {}; document.querySelectorAll('[id]').forEach(e => c[e.id] = (c[e.id] || 0) + 1);
      Object.entries(c).filter(([, n]) => n > 1).forEach(([id, n]) => out.push('duplikat id ' + id + ' ×' + n));
      // obrazy/srcset
      document.querySelectorAll('img').forEach(i => { if (i.complete && i.naturalWidth === 0 && i.loading !== 'lazy') out.push('img nie wczytany ' + i.getAttribute('src')); });
      // h1
      out.push('H1×' + document.querySelectorAll('h1').length);
      return out;
    });
    console.log('  linki: ' + links.length + ', problemy: ' + probs.length); probs.forEach(x => console.log('   -', x));
    console.log('  produkcyjne ścieżki /…:', [...prod].join(' '));
    console.log('  zewnętrzne:', [...ext].join(' '));
    console.log('  odwołania id:', refs.join(' | '));
    // treść: zakazane frazy w widocznym tekście i HTML
    const body = await p.evaluate(() => document.body.innerText);
    const html = fs.readFileSync(DIR + pg, 'utf8');
    for (const bad of ['orientacyjn', 'szacunkow', 'konsultacja.beautypolisa', 'kod zapasow', 'kodów zapasow', 'kody zapasow']) {
      if (body.toLowerCase().includes(bad)) console.log('  ZAKAZANE w tekście:', bad);
      else if (html.toLowerCase().includes(bad)) console.log('  (tylko w źródle/komentarzu):', bad);
    }
    const wLinks = [...html.matchAll(/portal\.beautypolisa\.eu\/w\/[^\s"<]*/g)].map(m => m[0]);
    console.log('  portal…/w/ w źródle:', [...new Set(wLinks)].join(' | ') || 'brak');
    const wVis = (body.match(/portal\.beautypolisa\.eu\/w\/\S*/g) || []);
    console.log('  portal…/w/ w widocznym tekście:', wVis.join(' | ') || 'brak');
    await ctx.close();
  }
  await b.close();
})();
