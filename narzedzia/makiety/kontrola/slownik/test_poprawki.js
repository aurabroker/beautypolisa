// Testy poprawek po kontroli 13.11.2026 (słownik + dymki). Uruchomienie: node test_poprawki.js [kontrast|dymek|slownik|wszystko]
const REPO = require('path').resolve(__dirname, '../../../..');  // katalog główny repozytorium
const WYNIKI = require('path').join(__dirname, '../wyniki/slownik') + '/';  // zrzuty i wyniki (poza gitem)
// 1. kontrast: podkreślenie i obwódka fokusu każdego widocznego pojęcia ≥ 3:1 względem tła (także na ciemnych tłach bez .dark),
//    jasny tekst => jasne podkreślenie.
// 2. dymek: położenie przy pojęciu na 20/50/80% wysokości okna – dymek w całości w oknie (1440×900, 1280×720, 768×1024, 700×500, 844×390).
// 3. słownik: kategorie (strzałki – zaznaczony wiersz w całości widoczny), indeks A–Z w widoku przyklejonego panelu, liczby przy literach,
//    kolejność wyników („OC”, „NW”), wyniki tuż pod licznikiem na telefonie, odstępy z WCAG 1.4.12 przy 320 px.
const { chromium } = require('playwright');
const OUT = WYNIKI;
require('fs').mkdirSync(OUT, { recursive: true });
const V3 = 'file://' + REPO + '/docs/koncepcja/design/v3/';
const STRONY = ['makieta-v3.html', 'oc-beauty.html', 'tax-protect.html', 'utrata-dochodu.html', 'nnw-dzieci.html', 'grupowe-ergo.html',
  'strefa/logowanie.html', 'strefa/panel.html', 'strefa/dam-prace.html'];
const TRYB = process.argv[2] || 'wszystko';
const bledy = [], info = [];
const ok = (c, m) => { if (!c) bledy.push(m); };

const KONTRAST = () => {
  const parse = c => { const m = c.match(/rgba?\(([^)]+)\)/); if (!m) return null; const p = m[1].split(/[ ,/]+/).filter(Boolean).map(Number); return { r: p[0], g: p[1], b: p[2], a: p.length > 3 ? p[3] : 1 }; };
  const lum = c => { const f = v => { v /= 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); }; return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b); };
  const kr = (a, b) => { const x = lum(a), y = lum(b); return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05); };
  const nad = (top, bot) => ({ r: top.r * top.a + bot.r * (1 - top.a), g: top.g * top.a + bot.g * (1 - top.a), b: top.b * top.a + bot.b * (1 - top.a), a: 1 });
  // tła: warstwy od elementu w górę; gradient => zestaw kolorów (bierzemy najgorszy przypadek)
  const tla = el => {
    const warstwy = []; let baza = null;
    for (let e = el; e && e.nodeType === 1; e = e.parentElement) {
      const cs = getComputedStyle(e);
      const bi = cs.backgroundImage;
      if (bi && bi.includes('gradient')) { const cols = (bi.match(/rgba?\([^)]+\)/g) || []).map(parse).filter(c => c && c.a > 0.5); if (cols.length) { baza = cols; break; } }
      const bc = parse(cs.backgroundColor);
      if (bc && bc.a > 0) { if (bc.a >= 0.99) { baza = [bc]; break; } warstwy.push(bc); }
    }
    if (!baza) baza = [{ r: 255, g: 255, b: 255, a: 1 }];
    return baza.map(b => warstwy.reduceRight((acc, w) => nad(w, acc), b));
  };
  const odkryj = a => { for (let e = a.parentElement; e && e !== document.body; e = e.parentElement) { if (e.tagName === 'DETAILS' && !e.open) e.open = true; if (e.hidden) e.hidden = false; } };
  return [...document.querySelectorAll('a.bp-termin')].map(a => {
    odkryj(a); if (!a.getClientRects().length || getComputedStyle(a).visibility !== 'visible') return null;
    const cs = getComputedStyle(a);
    const tekst = parse(cs.color), pod = parse(cs.textDecorationColor);
    const bg = tla(a.parentElement);
    const kPod = Math.min(...bg.map(b => kr(nad(pod, b), b)));
    const kTekst = Math.min(...bg.map(b => kr(nad(tekst, b), b)));
    a.focus({ preventScroll: true });
    // obwódka fokusu – wywołana klawiaturą w teście; tu: kolor z reguły :focus-visible (currentColor albo gold light)
    return { id: a.dataset.termin, kPod: +kPod.toFixed(2), kTekst: +kTekst.toFixed(2), jasnyTekst: lum(tekst) > 0.4, jasnePod: lum(pod) > 0.4, kontekst: (a.closest('.dark,.banner,[class*="--dark"]') || {}).className || '' };
  }).filter(Boolean);
};

(async () => {
  const b = await chromium.launch();
  // ---------- 1. kontrast podkreślenia i fokusu
  if (TRYB === 'kontrast' || TRYB === 'wszystko') {
    for (const w of [1440, 390]) {
      for (const s of STRONY) {
        const p = await b.newPage({ viewport: { width: w, height: 900 } });
        await p.goto(V3 + s, { waitUntil: 'load' }); await p.waitForTimeout(250);
        const r = await p.evaluate(KONTRAST);
        for (const x of r) {
          ok(x.kPod >= 3, `${s}@${w} ${x.id}: podkreślenie ${x.kPod}:1 (${x.kontekst})`);
          ok(!x.jasnyTekst || x.jasnePod, `${s}@${w} ${x.id}: jasny tekst, ciemne podkreślenie (${x.kontekst})`);
        }
        // obwódka fokusu z klawiatury: Tab do każdego pojęcia i odczyt outline-color
        const n = await p.evaluate(() => document.querySelectorAll('a.bp-termin').length);
        for (let i = 0; i < n; i++) {
          const f = await p.evaluate(i => { const a = document.querySelectorAll('a.bp-termin')[i]; for (let e = a.parentElement; e && e !== document.body; e = e.parentElement) { if (e.tagName === 'DETAILS' && !e.open) e.open = true; if (e.hidden) e.hidden = false; } if (!a.getClientRects().length) return null; a.scrollIntoView({ block: 'center' }); return a.dataset.termin; }, i);
          if (!f) continue;
          await p.waitForTimeout(450);   // rozwijanie details z animacją (content-visibility) – fokus dopiero po niej
          await p.evaluate(i => { const a = document.querySelectorAll('a.bp-termin')[i]; const prev = a.previousElementSibling; document.activeElement && document.activeElement.blur(); a.setAttribute('data-cel', '1'); }, i);
          await p.keyboard.press('Tab'); // nada fokusu klawiaturze (focus-visible), potem przenosimy fokus na pojęcie przez focus() – Chrome zachowuje tryb klawiatury
          const o = await p.evaluate(() => { const a = document.querySelector('a.bp-termin[data-cel]'); a.removeAttribute('data-cel'); a.focus(); const cs = getComputedStyle(a); return { fv: a.matches(':focus-visible'), oc: cs.outlineColor, ow: cs.outlineWidth, os: cs.outlineStyle }; });
          const kO = await p.evaluate(([oc, i]) => {
            const parse = c => { const m = c.match(/rgba?\(([^)]+)\)/); const p = m[1].split(/[ ,/]+/).filter(Boolean).map(Number); return { r: p[0], g: p[1], b: p[2], a: p.length > 3 ? p[3] : 1 }; };
            const lum = c => { const f = v => { v /= 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); }; return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b); };
            const a = document.querySelectorAll('a.bp-termin')[i]; let bg = null;
            for (let e = a.parentElement; e; e = e.parentElement) { const cs = getComputedStyle(e); const bi = cs.backgroundImage; if (bi.includes('gradient')) { bg = (bi.match(/rgba?\([^)]+\)/g) || []).map(parse).filter(c => c.a > .5); if (bg.length) break; bg = null; } const bc = parse(cs.backgroundColor); if (bc.a >= .99) { bg = [bc]; break; } }
            bg = bg || [{ r: 255, g: 255, b: 255, a: 1 }];
            const c = parse(oc); return Math.min(...bg.map(x => { const l1 = lum(c), l2 = lum(x); return (Math.max(l1, l2) + .05) / (Math.min(l1, l2) + .05); }));
          }, [o.oc, i]);
          ok(o.fv && o.os !== 'none' && parseFloat(o.ow) >= 2, `${s}@${w} ${f}: brak obwódki fokusu ${JSON.stringify(o)}`);
          ok(kO >= 3, `${s}@${w} ${f}: obwódka fokusu ${kO.toFixed(2)}:1 ${o.oc}`);
        }
        info.push(`kontrast ${s}@${w}: pojęć ${r.length}, min podkreślenie ${Math.min(...r.map(x => x.kPod)).toFixed(2)}:1`);
        if (s === 'strefa/panel.html') {
          await p.evaluate(() => { const a = document.querySelector('.banner a.bp-termin'); if (a) { a.scrollIntoView({ block: 'center' }); } });
          await p.keyboard.press('Tab'); await p.evaluate(() => { const a = document.querySelector('.banner a.bp-termin'); if (a) a.focus(); });
          await p.screenshot({ path: OUT + `panel-banner-fokus-${w}.png` });
        }
        await p.close();
      }
    }
  }
  // ---------- 2. położenie dymka
  if (TRYB === 'dymek' || TRYB === 'wszystko') {
    for (const [W, H] of [[1440, 900], [1280, 720], [768, 1024], [700, 500], [844, 390], [1280, 800]]) {
      let tot = 0, zle = 0, wew = 0; const przyk = [];
      for (const s of STRONY) {
        const c = await b.newContext({ viewport: { width: W, height: H }, reducedMotion: 'reduce' }); const p = await c.newPage();
        await p.goto(V3 + s, { waitUntil: 'load' }); await p.waitForTimeout(250);
        await p.evaluate(() => document.querySelectorAll('a.bp-termin').forEach(a => { let d = a.closest('details'); while (d) { d.open = true; d = d.parentElement && d.parentElement.closest('details'); } }));
        const n = await p.evaluate(() => document.querySelectorAll('a.bp-termin').length);
        for (let i = 0; i < n; i++) {
          if (!(await p.evaluate(i => { const a = document.querySelectorAll('a.bp-termin')[i]; for (let e = a.parentElement; e && e !== document.body; e = e.parentElement) { if (e.tagName === 'DETAILS' && !e.open) e.open = true; } return a.getClientRects().length > 0; }, i))) continue;
          for (const frac of [0.2, 0.5, 0.8]) {
            const r = await p.evaluate(([i, frac]) => {
              const a = document.querySelectorAll('a.bp-termin')[i]; const q0 = a.getBoundingClientRect(); window.scrollBy(0, q0.top - innerHeight * frac);
              const rs = a.getClientRects(); a.click(); const d = document.getElementById('bp-dymek'); const r = d.getBoundingClientRect();
              // nie przykrywa pojęcia (żadnej linii) – dotyczy trybu „przy pojęciu”
              const fixed = getComputedStyle(d).position === 'fixed';
              const nachodzi = !fixed && [...rs].some(q => q.bottom > r.top + 1 && q.top < r.bottom - 1 && q.right > r.left && q.left < r.right);
              const wiecej = d.querySelector('.bp-dymek-wiecej');
              const out = { id: a.dataset.termin, top: Math.round(rs[0].top), dt: Math.round(r.top), db: Math.round(r.bottom), h: Math.round(r.height), fits: r.top >= 0 && r.bottom <= innerHeight + 0.5 && r.left >= 0 && r.right <= document.documentElement.clientWidth, open: !d.hidden, nachodzi, przew: d.scrollHeight > d.clientHeight + 1, fixed, wiecejOsiagalny: !!wiecej };
              a.click(); return out;
            }, [i, frac]);
            if (!r.open) continue;
            tot++; if (r.przew) wew++;
            if (!r.fits || r.nachodzi) { zle++; if (przyk.length < 8) przyk.push(`${s} ${r.id} y=${r.top} dymek ${r.dt}–${r.db} h=${r.h}${r.nachodzi ? ' NACHODZI' : ''}`); }
          }
        }
        await c.close();
      }
      ok(zle === 0, `dymek ${W}x${H}: ${zle}/${tot} poza oknem lub na pojęciu: ${przyk.join(' | ')}`);
      info.push(`dymek ${W}x${H}: otwarć ${tot}, poza oknem/na pojęciu ${zle}, z przewijaniem wewnątrz ${wew}`);
    }
  }
  // ---------- 3. słownik
  if (TRYB === 'slownik' || TRYB === 'wszystko') {
    const SPACING = '*{line-height:1.5!important;letter-spacing:.12em!important;word-spacing:.16em!important}p{margin-bottom:2em!important}';
    for (const w of [320, 360, 390, 768, 1024, 1440]) {
      const p = await b.newPage({ viewport: { width: w, height: 800 } });
      await p.goto(V3 + 'slownik.html', { waitUntil: 'load' }); await p.waitForTimeout(250);
      // kategorie: rozwiń, Tab do zaznaczonego radia, strzałki w prawo przez wszystkie – zaznaczony wiersz w całości widoczny
      await p.evaluate(() => { document.getElementById('sl-kat').open = true; document.querySelector('input[name="kategoria"]:checked').focus(); });
      let zleChip = [];
      for (let k = 0; k < 11; k++) {
        await p.keyboard.press('ArrowDown'); await p.waitForTimeout(30);
        const r = await p.evaluate(() => { const i = document.activeElement; const s = i.closest('.sl-chip').getBoundingClientRect(); const box = document.querySelector('.sl-chipy').getBoundingClientRect(); return { n: i.dataset.krotko, ok: s.left >= box.left - 1 && s.right <= box.right + 1 && s.left >= 0 && s.right <= document.documentElement.clientWidth, sw: document.documentElement.scrollWidth, cw: document.querySelector('.sl-chipy').scrollWidth <= document.querySelector('.sl-chipy').clientWidth + 1 }; });
        if (!r.ok || !r.cw || r.sw > w) zleChip.push(JSON.stringify(r));
      }
      ok(!zleChip.length, `słownik@${w}: kategoria poza wierszem ${zleChip.join(' ')}`);
      await p.evaluate(() => { const w = document.querySelector('input[name="kategoria"][value=""]'); w.checked = true; w.dispatchEvent(new Event('change', { bubbles: true })); document.getElementById('sl-kat').open = false; });
      // odstępy tekstu (1.4.12) – bez przewijania w poziomie
      await p.addStyleTag({ content: SPACING }); await p.waitForTimeout(200);
      const sw = await p.evaluate(() => document.documentElement.scrollWidth);
      ok(sw <= w, `słownik@${w}: przy odstępach 1.4.12 scrollWidth ${sw}`);
      info.push(`słownik@${w}: kategorie strzałkami OK=${!zleChip.length}, odstępy 1.4.12 scrollWidth ${sw}`);
      await p.close();
    }
    // indeks A–Z w widoku przyklejonego panelu
    for (const [W, H] of [[1440, 900], [1280, 800], [1024, 768]]) {
      const p = await b.newPage({ viewport: { width: W, height: H } });
      await p.goto(V3 + 'slownik.html', { waitUntil: 'load' }); await p.waitForTimeout(250);
      await p.evaluate(() => window.scrollTo(0, document.getElementById('litera-o').offsetTop)); await p.waitForTimeout(300);
      const r = await p.evaluate(() => { const n = document.querySelector('.sl-narzedzia'); const a = document.getElementById('indeks').getBoundingClientRect(); const q = n.getBoundingClientRect(); return { pos: getComputedStyle(n).position, panel: [Math.round(q.top), Math.round(q.bottom)], az: [Math.round(a.top), Math.round(a.bottom)], przew: n.scrollHeight > n.clientHeight + 1, vh: innerHeight }; });
      ok(r.pos === 'sticky' && r.az[0] >= r.panel[0] && r.az[1] <= Math.min(r.panel[1], r.vh) && !r.przew, `indeks A–Z ${W}x${H}: ${JSON.stringify(r)}`);
      info.push(`indeks ${W}x${H}: ${JSON.stringify(r)}`);
      await p.screenshot({ path: OUT + `sl-${W}-lista.png` });
      await p.close();
    }
    // liczby przy literach, kolejność wyników, wyniki pod licznikiem (telefon)
    {
      const p = await b.newPage({ viewport: { width: 1440, height: 900 } });
      await p.goto(V3 + 'slownik.html', { waitUntil: 'load' }); await p.waitForTimeout(250);
      const vis = () => p.evaluate(() => [...document.querySelectorAll('.haslo')].filter(h => h.checkVisibility()).map(h => h.id.replace('haslo-', '')));
      await p.fill('#sl-q', 'skladka'); await p.waitForTimeout(100);
      const s9 = await p.evaluate(() => document.querySelector('#litera-s .sl-litera-ile').textContent);
      ok(s9 === '1', 'litera S przy „skladka”: ' + s9);
      await p.fill('#sl-q', 'OC'); await p.waitForTimeout(100); let v = await vis();
      ok(v[0] === 'odpowiedzialnosc-cywilna', '„OC” – pierwsze: ' + v.slice(0, 4));
      info.push(`„OC”: ${v.length} haseł, kolejność: ${v.slice(0, 6).join(', ')}`);
      await p.fill('#sl-q', 'NW'); await p.waitForTimeout(100); v = await vis();
      ok(v[0] === 'nieszczesliwy-wypadek' && !v.includes('inwalidztwo'), '„NW”: ' + v);
      info.push(`„NW”: ${v.join(', ')}`);
      await p.fill('#sl-q', 'L4'); await p.waitForTimeout(100); v = await vis(); info.push(`„L4”: ${v.join(', ')}`);
      await p.fill('#sl-q', 'karen'); await p.waitForTimeout(100); v = await vis(); info.push(`„karen”: ${v.join(', ')}`);
      await p.fill('#sl-q', ''); await p.waitForTimeout(100);
      const kol = await p.evaluate(() => [...document.querySelectorAll('.sl-litera')].map(l => l.id.replace('litera-', '')).join(''));
      ok(kol.startsWith('abc'), 'kolejność po wyczyszczeniu: ' + kol);
      await p.evaluate(() => { const r = document.querySelector('input[name="kategoria"][value="tax-protect"]'); r.checked = true; r.dispatchEvent(new Event('change', { bubbles: true })); }); await p.waitForTimeout(100);
      const o = await p.evaluate(() => [...document.querySelectorAll('.sl-litera')].filter(l => !l.hidden).map(l => l.id + ':' + l.querySelector('.sl-litera-ile').textContent).join(' '));
      info.push('Tax Protect – litery: ' + o + ' | wybór: ' + await p.textContent('#sl-kat-wybor'));
      await p.close();
    }
    for (const [W, H] of [[390, 844], [320, 640]]) {
      const p = await b.newPage({ viewport: { width: W, height: H } });
      await p.goto(V3 + 'slownik.html', { waitUntil: 'load' }); await p.waitForTimeout(250);
      await p.fill('#sl-q', 'skladka'); await p.waitForTimeout(450);
      const r = await p.evaluate(() => { const q = document.getElementById('sl-q').getBoundingClientRect(); const h = [...document.querySelectorAll('.haslo')].find(h => h.checkVisibility()).getBoundingClientRect(); return { pole: Math.round(q.bottom + scrollY), wynik: Math.round(h.top + scrollY), indeks: document.getElementById('indeks').checkVisibility() }; });
      ok(!r.indeks && r.wynik - r.pole < 340, `telefon ${W}: wynik daleko od pola ${JSON.stringify(r)}`);
      info.push(`telefon ${W}: pole ${r.pole} → pierwszy wynik ${r.wynik}, indeks widoczny: ${r.indeks}`);
      await p.evaluate(() => document.getElementById('sl-q').scrollIntoView({ block: 'start' })); await p.waitForTimeout(100);
      await p.screenshot({ path: OUT + `sl-${W}-szukaj.png` });
      await p.fill('#sl-q', 'zzqx'); await p.waitForTimeout(450);
      await p.screenshot({ path: OUT + `sl-${W}-pusto.png` });
      // klik „Indeks A–Z” w szufladzie przy schowanym indeksie – filtry czyszczone, indeks widoczny
      await p.evaluate(() => document.querySelector('.menu-panel a[href="#indeks"]').click()); await p.waitForTimeout(200);
      const ix = await p.evaluate(() => ({ widoczny: document.getElementById('indeks').checkVisibility(), q: document.getElementById('sl-q').value }));
      ok(ix.widoczny && ix.q === '', `telefon ${W}: link do indeksu przy filtrze ${JSON.stringify(ix)}`);
      await p.close();
    }
    for (const [W, H] of [[1440, 900], [390, 844], [320, 740]]) {
      const p = await b.newPage({ viewport: { width: W, height: H } });
      await p.goto(V3 + 'slownik.html', { waitUntil: 'load' }); await p.waitForTimeout(300);
      await p.screenshot({ path: OUT + `sl-${W}-top.png` });
      await p.evaluate(() => document.getElementById('hasla').scrollIntoView()); await p.waitForTimeout(200);
      await p.screenshot({ path: OUT + `sl-${W}-narzedzia.png` });
      await p.evaluate(() => { document.getElementById('sl-kat').open = true; }); await p.waitForTimeout(100);
      await p.screenshot({ path: OUT + `sl-${W}-kategorie.png` });
      await p.close();
    }
  }
  await b.close();
  console.log(info.join('\n'));
  console.log('\nBŁĘDY (' + bledy.length + '):\n' + bledy.slice(0, 60).join('\n'));
})();
