// 9 stron publicznych (makieta-v3, 6 stron produktów, słownik, design-preview) – kontrola po wdrożeniu raportów 15 i 16 (17.11.2026):
//   axe-core (WCAG 2.2 AA) przy 320 i 1280 px, brak przewijania w poziomie (320, 390, 768, 1024, 1280, 1440 px), błędy JS,
//   jeden H1; pierwszy ekran (raport 15): Z1 – hero podstron = 1 ekran, dół panelu ≥ 24 px nad dolną krawędzią okna (1440×900, 1024×768,
//   820×1180); Z2 – główny przycisk hero w 1. ekranie (320×640, 390×844); Z29 – kwota w 1. ekranie na telefonie (strona główna, Tax, UD);
//   Z3 – treść panelu hero w jego obrysie przy 320 px; Z37 – jedna skala nagłówków (H2 jeden rozmiar, H3 najwyżej dwa, H1 podstron
//   jeden rozmiar); rundy 2 i 3 weryfikacji: Z8–Z10 – sekcje 1 albo 2 ekrany przy 1440×900, 1280×900, 1366×768 i 1536×864 (poza hero
//   i K6), przy 1280×720 i 1024×768 1 / 2 ekrany albo "n" z przyciętym paddingiem; H2 sekcji 2-ekranowej u góry, cyfra rozdziału w sekcji.
// Uruchom: node narzedzia/makiety/kontrola/strony/t_axe_strony.js (kod 1 przy błędzie). Bez zrzutów.
const { chromium } = require('playwright');
const path = require('path');
const V3 = path.resolve(__dirname, '../../../../docs/koncepcja/design/v3') + '/';
const AXE = require.resolve('axe-core/axe.min.js');
const STRONY = ['makieta-v3', 'oc-beauty', 'tax-protect', 'utrata-dochodu', 'nnw-dzieci', 'grupowe-ergo', 'opieka-medyczna', 'slownik', 'design-preview'];
const PODSTRONY = ['oc-beauty', 'tax-protect', 'utrata-dochodu', 'nnw-dzieci', 'grupowe-ergo', 'opieka-medyczna', 'slownik'];
const bledy = []; let asercje = 0;
const ok = (w, opis) => { asercje++; if (!w) bledy.push(opis); };

(async () => {
  const b = await chromium.launch();
  const strona = async (s, w, h) => {
    const p = await b.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: 1 });
    p._errs = []; p.on('pageerror', (e) => p._errs.push(e.message));
    await p.goto('file://' + V3 + s + '.html', { waitUntil: 'load' }); await p.waitForTimeout(250);
    return p;
  };
  for (const s of STRONY) {
    for (const [w, h] of [[320, 640], [390, 844], [768, 1024], [1024, 768], [1280, 900], [1440, 900]]) {
      const p = await strona(s, w, h);
      const sw = await p.evaluate(() => document.documentElement.scrollWidth - innerWidth);
      ok(sw <= 0, `${s}@${w}: przewijanie w poziomie (${sw} px)`);
      if (w === 320 || w === 1280) {
        await p.addScriptTag({ path: AXE });
        const v = await p.evaluate(async () => (await axe.run(document, { runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'] } })).violations
          .map((x) => x.id + ' (' + x.nodes.length + '): ' + x.nodes.slice(0, 3).map((n) => n.target.join(' ')).join(' | ')));
        ok(v.length === 0, `${s}@${w}: axe WCAG 2.2 AA – ${v.join('; ')}`);
        ok((await p.evaluate(() => document.querySelectorAll('h1').length)) === 1, `${s}@${w}: jeden H1`);
      }
      ok(p._errs.length === 0, `${s}@${w}: błędy JS: ${p._errs.join('; ')}`);
      await p.close();
    }
  }
  // Z1: hero podstron = 1 ekran, panel ≥ 24 px nad dolną krawędzią okna
  for (const s of PODSTRONY) for (const [w, h] of [[1440, 900], [1024, 768], [820, 1180]]) {
    const p = await strona(s, w, h);
    const r = await p.evaluate(() => { const hero = document.querySelector('.page-hero'), pan = hero.querySelector('.hero-panel');
      return { hero: hero.getBoundingClientRect().height, dol: pan.getBoundingClientRect().bottom, vh: innerHeight }; });
    ok(Math.abs(r.hero - r.vh) <= 2 && r.dol <= r.vh - 24, `Z1 ${s}@${w}×${h}: hero ${Math.round(r.hero)} px, dół panelu ${Math.round(r.dol)} (okno ${r.vh})`);
    await p.close();
  }
  // Z2, Z3, Z29: telefon
  for (const s of ['makieta-v3', ...PODSTRONY]) for (const [w, h] of [[320, 640], [390, 844]]) {
    const p = await strona(s, w, h);
    const r = await p.evaluate(() => {
      const btn = document.querySelector('.hero-actions .btn'), pan = document.querySelector('.hero-panel'), pr = pan.getBoundingClientRect();
      const cs = getComputedStyle(pan), lewa = pr.left + parseFloat(cs.paddingLeft), prawa = pr.right - parseFloat(cs.paddingRight);
      const poza = [...pan.querySelectorAll('h1,p,dl,.hero-actions,nav')].filter((e) => { const r = e.getBoundingClientRect(); return r.width && (r.left < lewa - 1 || r.right > prawa + 1); }).map((e) => e.tagName + '.' + e.className);
      const lead = pan.querySelector('.lead'), lr = lead.getBoundingClientRect();
      return { btn: btn.getBoundingClientRect().bottom, poza, kwota: /\d\s?(zł|tys)/.test(lead.textContent) && lr.bottom <= innerHeight, vh: innerHeight };
    });
    ok(r.btn <= r.vh, `Z2 ${s}@${w}×${h}: dół głównego przycisku ${Math.round(r.btn)} (okno ${r.vh})`);
    if (w === 320) ok(r.poza.length === 0, `Z3 ${s}@320: poza obrysem panelu: ${r.poza.join(', ')}`);
    if (['makieta-v3', 'tax-protect', 'utrata-dochodu'].includes(s)) ok(r.kwota, `Z29 ${s}@${w}: kwota w leadzie w 1. ekranie`);
    await p.close();
  }
  // Z37: skala nagłówków (1440 i 390 px)
  for (const w of [1440, 390]) {
    const r = { H2: new Set(), H3: new Set() };
    for (const s of STRONY.slice(0, 8)) {
      const p = await strona(s, w, 900);
      const x = await p.evaluate(() => [...document.querySelectorAll('main h2:not(.klauzula h2),main h3')].filter((h) => h.getClientRects().length).map((h) => [h.tagName, getComputedStyle(h).fontSize]));
      x.forEach(([t, f]) => r[t].add(f)); await p.close();
    }
    ok(r.H2.size === 1, `Z37 @${w}: H2 w ${r.H2.size} rozmiarach: ${[...r.H2]}`);
    ok(r.H3.size <= 2, `Z37 @${w}: H3 w ${r.H3.size} rozmiarach: ${[...r.H3]}`);
  }
  // Z37 (runda 2 weryfikacji): H1 – na stronie głównej --text-h1, na podstronach jeden rozmiar --text-h1-podstrona (bez lokalnych rozmiarów)
  for (const w of [1440, 390]) {
    const h1 = new Set();
    for (const s of PODSTRONY) { const p = await strona(s, w, 900); h1.add(await p.evaluate(() => getComputedStyle(document.querySelector('main h1')).fontSize)); await p.close(); }
    ok(h1.size === 1, `Z37 @${w}: H1 podstron w ${h1.size} rozmiarach: ${[...h1]}`);
  }
  // Z8, Z9, Z10 (rundy 2 i 3 weryfikacji): przy 1440×900, 1280×900, 1366×768 i 1536×864 każda sekcja główna poza hero i sekcjami-
  // dokumentami z K6 (OC #zabiegi, #ochrona-prawna, słownik #hasla) ma ≈ 1 albo ≈ 2 ekrany (0,98–1,1 albo 1,98–2,02). Przy 1280×720
  // i 1024×768 (wdrożenie częściowe – README makiet) sekcja ma 1 albo 2 ekrany albo data-ekrany="n" (wyższa niż 2,02 ekranu) – zawsze
  // z przyciętym paddingiem (≤ 96 px), bez powrotu do pełnego clamp(72px,11vw,168px); K6 – "n" z przyciętym paddingiem przy wszystkich
  // oknach. Runda 3: treść sekcji 2-ekranowej od góry (H2 w pierwszej połowie ekranu – kotwica z menu trafia na nagłówek), duża cyfra
  // rozdziału (.chapter-no) nie wychodzi ponad górną krawędź sekcji (szew między scenami)
  const K6 = ['zabiegi', 'ochrona-prawna', 'hasla'];
  for (const [w, h, pelne] of [[1440, 900, 1], [1280, 900, 1], [1366, 768, 1], [1536, 864, 1], [1280, 720, 0], [1024, 768, 0]]) for (const s of STRONY.slice(0, 8)) {
    const p = await strona(s, w, h); await p.waitForTimeout(250);
    const r = await p.evaluate(() => [...document.querySelectorAll('main section')].filter((x) => !x.parentElement.closest('main section') && !x.matches('.scene--hero,.page-hero'))
      .map((x) => { const r = x.getBoundingClientRect(), h2 = x.querySelector('h2'), cn = [...x.querySelectorAll('.chapter-no')].filter((c) => c.getClientRects().length);
        return { id: x.id || x.className, e: +(r.height / innerHeight).toFixed(2), n: x.getAttribute('data-ekrany'), pad: parseFloat(getComputedStyle(x).paddingTop),
          h2: h2 ? (h2.getBoundingClientRect().top - r.top) / innerHeight : 0, cn: cn.filter((c) => c.getBoundingClientRect().top < r.top - 0.5).length }; }));
    const k6 = r.filter((x) => K6.includes(x.id)), reszta = r.filter((x) => !K6.includes(x.id));
    const rytm = (x) => (x.e >= 0.98 && x.e <= 1.1 && x.n === '1') || (x.e >= 1.98 && x.e <= 2.02 && x.n === '2');
    const zle = reszta.filter((x) => !(rytm(x) || (!pelne && x.n === 'n' && x.e > 2.02)));
    ok(zle.length === 0, `Z8–Z10 ${s}@${w}×${h}: sekcje poza 1 / 2 ekranami: ${zle.map((x) => x.id + ' ' + x.e + ' ' + x.n).join(', ')}`);
    const pad = r.filter((x) => x.pad > 96.5);
    ok(pad.length === 0, `Z10 ${s}@${w}×${h}: sekcje z pełnym paddingiem (> 96 px): ${pad.map((x) => x.id + ' ' + x.pad).join(', ')}`);
    ok(k6.every((x) => x.n === 'n'), `Z10 ${s}@${w}×${h}: sekcje K6 bez data-ekrany="n": ${k6.map((x) => x.id + ' ' + x.n).join(', ')}`);
    const nisko = r.filter((x) => x.n === '2' && x.h2 > 0.5);
    ok(nisko.length === 0, `Z10 ${s}@${w}×${h}: H2 sekcji 2-ekranowej poniżej połowy pierwszego ekranu: ${nisko.map((x) => x.id + ' ' + x.h2.toFixed(2)).join(', ')}`);
    const cyfry = r.filter((x) => x.cn);
    ok(cyfry.length === 0, `Z10 ${s}@${w}×${h}: cyfra rozdziału ponad górną krawędzią sekcji: ${cyfry.map((x) => x.id).join(', ')}`);
    await p.close();
  }
  await b.close();
  console.log(`asercje: ${asercje}`);
  console.log(bledy.length ? 'BŁĘDY (' + bledy.length + '):\n' + bledy.join('\n') : 'OK');
  process.exit(bledy.length ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(1); });
