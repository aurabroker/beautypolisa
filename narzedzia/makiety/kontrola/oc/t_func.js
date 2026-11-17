// oc-beauty.html po Aneksie nr 5 (plan rozdz. 7, krok 4; uwagi K2, K3) – kontrola z werdyktem:
//   * lista vs JSON: sekcje .zlista #lista-1, #lista-2, #ankieta (pozycje: kolejność, numer/value, brzmienie, id = slug przy pierwszym
//     wystąpieniu, <slug>-lista-2 przy drugim, odnośnik „także na liście nr …”), #podologia bez pozycji; bez oznaczeń pojęć w listach;
//     id na stronie bez powtórzeń;
//   * bez JS: cała lista widoczna (49 + 63 + 8), wyszukiwarka ukryta; każda dawna kotwica (#grupa-1…4, 18 dawnych slugów, 31 slugów
//     wycofanych pozycji podologicznych) przewija do widocznego elementu (odbiór pkt 4);
//   * z JS: filtr („klamra” – 0, „manicure” – 2 pozycje: lista nr 1 poz. 17 i lista nr 2 poz. 19, „kobido” – 2, MEZO = mezo, brak wyników),
//     licznik i „Wyczyść”; kotwice sekcji, aliasy i pozycje – widoczne pod nagłówkiem, także przy zamkniętych <details> i aktywnym filtrze;
//   * nagłówki (jeden H1, bez przeskoków), cele dotyku ≥ 24 × 24 px.
// Uruchom: node narzedzia/makiety/kontrola/oc/t_func.js   (kod wyjścia 1 przy błędzie)
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');
const REPO = path.resolve(__dirname, '../../../..');  // katalog główny repozytorium
const FILE = 'file://' + REPO + '/docs/koncepcja/design/v3/oc-beauty.html';
const SN = REPO + '/docs/koncepcja/snippets/';
const Z = JSON.parse(fs.readFileSync(SN + 'zabiegi-oc-beauty.json', 'utf8'));
const W = JSON.parse(fs.readFileSync(SN + 'zabiegi-oc-beauty-wycofane.json', 'utf8'));
const bledy = [];
const ma = (opis, war, info) => { if (!war) bledy.push(opis + (info !== undefined ? ': ' + JSON.stringify(info) : '')); };

// --- oczekiwane pozycje list z JSON (jak zabiegi_model.pozycje_listy / kotwice_wystapien) ---
function pozycje(klucz) {
  const out = [];
  for (const z of Z.zabiegi) z.pozycje.forEach((p, i) => {
    if (p.lista !== klucz) return;
    const inne = z.pozycje.filter((q) => q !== p && q.lista !== 'ankieta');
    out.push({ nr: p.nr, nazwa: p.nazwa || z.nazwa, id: i === 0 ? z.slug : z.slug + '-lista-2', inne: inne.length ? inne[0] : null, z });
  });
  return out.sort((a, b) => (typeof a.nr === 'number' ? a.nr - b.nr : a.nr.localeCompare(b.nr)));
}
const LISTY = Z.listy.filter((l) => l.liczba_pozycji);
const ALIASY_ZAB = Z.zabiegi.flatMap((z) => (z.dawne_slugi || []).map((s) => [s, z]));
const ALIASY_SEK = Z.listy.flatMap((l) => (l.dawne_kotwice || []).map((k) => [k, l.kotwica]));
const ALIASY_WYC = W.wycofane.map((w) => [w.slug, 'podologia']);

(async () => {
  const b = await chromium.launch();
  // ---------- lista vs JSON ----------
  {
    const p = await b.newPage({ viewport: { width: 1440, height: 900 } });
    await p.goto(FILE, { waitUntil: 'networkidle' });
    // brzmienie 1:1; twarde spacje (polska typografia, typografia.py – raport 16, 3.1) porównywane jako spacje
    const dom = await p.evaluate(() => { const sp = (t) => t.replace(/\u00a0/g, ' '); return [...document.querySelectorAll('.zlista')].map((g) => ({
      id: g.id, h3: sp(g.querySelector('h3').textContent), termin: g.querySelectorAll('a.bp-termin').length,
      items: [...g.querySelectorAll('.zlist > li')].map((l) => ({ id: l.id, value: l.getAttribute('value'), nr: l.querySelector('.z-nr').textContent,
        nazwa: sp(l.querySelector('.z-name').textContent), inna: l.querySelector('.z-inna') ? l.querySelector('.z-inna').getAttribute('href') : null })),
    })); });
    ma('sekcje list', JSON.stringify(dom.map((d) => d.id)) === JSON.stringify(Z.listy.map((l) => l.kotwica)), dom.map((d) => d.id));
    let n = 0;
    for (const l of LISTY) {
      const d = dom.find((x) => x.id === l.kotwica);
      if (!d) { bledy.push('brak sekcji ' + l.kotwica); continue; }
      const h3 = l.klucz === 'ankieta' ? 'Zabiegi wymagające ankiety ERGO Hestii' : l.nazwa;
      ma(`${l.klucz}: nagłówek`, d.h3 === h3, d.h3);
      ma(`${l.klucz}: bez oznaczeń pojęć w nazwach pozycji (K3)`, d.termin === 0, d.termin);
      const exp = pozycje(l.klucz);
      ma(`${l.klucz}: liczba pozycji = ${l.liczba_pozycji}`, d.items.length === l.liczba_pozycji && exp.length === l.liczba_pozycji, d.items.length);
      exp.forEach((e, i) => {
        const x = d.items[i]; n++;
        const nrTxt = typeof e.nr === 'number' ? e.nr + '.' : e.nr + ')';
        const value = typeof e.nr === 'number' ? String(e.nr) : String(i + 1);
        const inna = e.inne ? '#' + (e.inne === e.z.pozycje[0] ? e.z.slug : e.z.slug + '-lista-2') : null;
        ma(`${l.klucz} poz. ${nrTxt} (${e.z.id})`, x && x.id === e.id && x.value === value && x.nr === nrTxt && x.nazwa === e.nazwa && x.inna === inna, x);
      });
    }
    ma('porównane pozycje: 49 + 63 + 8', n === 120, n);
    const pod = dom.find((x) => x.id === 'podologia');
    ma('podologia bez pozycji, z informacją o dokumentach programu', pod && pod.items.length === 0 &&
      (await p.textContent('#podologia')).replace(/\u00a0/g, ' ').includes('Lista zabiegów podologicznych jest w dokumentach programu'));
    const dup = await p.evaluate(() => { const a = [...document.querySelectorAll('[id]')].map((e) => e.id); return a.filter((x, i) => a.indexOf(x) !== i); });
    ma('id bez powtórzeń', dup.length === 0, dup);
    const naglowki = await p.evaluate(() => [...document.querySelectorAll('h1,h2,h3,h4,h5,h6')].filter((h) => h.checkVisibility()).map((h) => +h.tagName[1]));
    ma('jeden H1', naglowki.filter((x) => x === 1).length === 1);
    ma('nagłówki bez przeskoków', naglowki.every((l, i) => !i || l <= naglowki[i - 1] + 1));
    await p.close();
  }
  // ---------- bez JS: lista i dawne kotwice ----------
  for (const [w, h] of [[1440, 900], [360, 740]]) {
    // reducedMotion: bez płynnego przewijania (scroll-behavior: smooth) – pozycja po przejściu do #fragmentu od razu końcowa
    const ctx = await b.newContext({ viewport: { width: w, height: h }, javaScriptEnabled: false, reducedMotion: 'reduce' });
    const p = await ctx.newPage();
    await p.goto(FILE, { waitUntil: 'networkidle' });
    const r = await p.evaluate(() => {
      const lis = [...document.querySelectorAll('.zlist > li')];
      return { li: lis.length, vis: lis.filter((l) => l.checkVisibility()).length, form: document.getElementById('z-szukaj-form').checkVisibility(),
        hscroll: document.documentElement.scrollWidth > document.documentElement.clientWidth };
    });
    ma(`bez JS ${w}: cała lista widoczna`, r.li === 120 && r.vis === 120, r);
    ma(`bez JS ${w}: wyszukiwarka ukryta`, !r.form);
    ma(`bez JS ${w}: bez przewijania w poziomie`, !r.hscroll);
    const zle = [];
    for (const [alias] of [...ALIASY_SEK, ...ALIASY_ZAB, ...ALIASY_WYC]) {
      await p.goto(FILE + '#' + alias, { waitUntil: 'load' });  // przewinięcie przeglądarki do #fragmentu (bez skryptu strony)
      await p.waitForTimeout(50);
      const ok = await p.evaluate((a) => {
        const t = document.getElementById(a); if (!t) return 'brak';
        const cel = t.classList.contains('z-alias') ? (t.closest('li') || t.closest('section')) : t;
        const r = cel.getBoundingClientRect();
        return t.hidden ? 'hidden' : cel.checkVisibility() && r.top >= 0 && r.top < innerHeight && scrollY > 0 ? 'ok' : 'poza widokiem ' + Math.round(r.top);
      }, alias);
      if (ok !== 'ok') zle.push(alias + ': ' + ok);
    }
    ma(`bez JS ${w}: ${ALIASY_SEK.length + ALIASY_ZAB.length + ALIASY_WYC.length} dawnych kotwic prowadzi do widocznego elementu`, zle.length === 0, zle);
    ma('dawne kotwice: 4 sekcje, 18 slugów, 31 wycofanych', ALIASY_SEK.length === 4 && ALIASY_ZAB.length === 18 && ALIASY_WYC.length === 31,
      [ALIASY_SEK.length, ALIASY_ZAB.length, ALIASY_WYC.length]);
    await ctx.close();
  }
  // ---------- filtr ----------
  for (const [w, h] of [[1440, 900], [390, 844]]) {
    const p = await b.newPage({ viewport: { width: w, height: h } });
    const errs = []; p.on('pageerror', (e) => errs.push(e.message));
    await p.goto(FILE, { waitUntil: 'networkidle' });
    const start = await p.textContent('#z-licznik');
    ma(`filtr ${w}: licznik startowy`, start.replace(/\s+/g, ' ').trim() === 'Lista nr 1: 49 · lista nr 2: 63 · ankieta: 8', start);
    const wynik = async (q) => {
      await p.fill('#z-szukaj', q); await p.waitForTimeout(450);
      return p.evaluate(() => {
        const vis = [...document.querySelectorAll('.zlist > li')].filter((l) => !l.hidden && !l.closest('[hidden]'));
        return { n: vis.length, poz: vis.map((l) => l.closest('.zlista').id + '/' + l.querySelector('.z-nr').textContent), licznik: document.getElementById('z-licznik').textContent.replace(/\s+/g, ' ').trim(),
          brak: document.getElementById('z-brak').hidden ? '' : document.getElementById('z-brak').textContent, wyczysc: !document.getElementById('z-wyczysc').hidden };
      });
    };
    const kl = await wynik('klamra');
    ma(`filtr ${w}: „klamra” – 0 (podologia tylko jako dokument)`, kl.n === 0 && kl.brak !== '', kl);
    // Q1: komunikat braku wyników odsyła do sekcji Podologia (lista zabiegów podologicznych w dokumentach programu)
    ma(`filtr ${w}: brak wyników – zdanie o liście podologicznej i odnośnik #podologia`,
      kl.brak.replace(/\u00a0/g, ' ').includes('Lista zabiegów podologicznych jest w dokumentach programu') && (await p.locator('#z-brak a[href="#podologia"]').count()) === 1, kl);
    const man = await wynik('manicure');
    ma(`filtr ${w}: „manicure” – lista nr 1 poz. 17 i lista nr 2 poz. 19`, JSON.stringify(man.poz) === JSON.stringify(['lista-1/17.', 'lista-2/19.']) && /Znaleziono 2/.test(man.licznik), man);
    const kob = await wynik('kobido');
    ma(`filtr ${w}: „kobido” – 2 pozycje`, kob.n === 2, kob);
    const m1 = await wynik('mezo'), m2 = await wynik('MEZO');
    ma(`filtr ${w}: wielkość liter`, m1.n > 0 && m1.n === m2.n, [m1.n, m2.n]);
    const nici = await wynik('nici pdo');
    ma(`filtr ${w}: „nici pdo” – poz. g)`, nici.poz.includes('ankieta/g)'), nici.poz);
    const x = await wynik('xyzzy');
    ma(`filtr ${w}: brak wyników`, x.n === 0 && x.brak.length > 0 && x.wyczysc, x);
    await p.click('#z-wyczysc'); await p.waitForTimeout(150);
    const po = await p.evaluate(() => ({ licznik: document.getElementById('z-licznik').textContent.replace(/\s+/g, ' ').trim(), vis: [...document.querySelectorAll('.zlist > li')].filter((l) => !l.hidden && !l.closest('[hidden]')).length }));
    ma(`filtr ${w}: „Wyczyść”`, po.vis === 120 && po.licznik === start.replace(/\s+/g, ' ').trim(), po);
    // głęboki link (alias) przy aktywnym filtrze: filtr czyszczony, pozycja widoczna
    await p.fill('#z-szukaj', 'henna'); await p.waitForTimeout(450);
    await p.evaluate(() => { location.hash = 'zabiegi-z-uzyciem-nici-pdo'; }); await p.waitForTimeout(1200);
    const dl = await p.evaluate(() => { const t = document.getElementById('zabiegi-z-uzyciem-nici-pdo').closest('li'); const r = t.getBoundingClientRect(); return { q: document.getElementById('z-szukaj').value, hidden: !!t.closest('[hidden]') || t.hidden, inView: r.top >= 0 && r.bottom <= innerHeight }; });
    ma(`filtr ${w}: alias przy aktywnym filtrze`, dl.q === '' && !dl.hidden && dl.inView, dl);
    ma(`filtr ${w}: bez błędów JS`, errs.length === 0, errs);
    await p.close();
  }
  // ---------- kotwice z JS (zamknięte <details>, nagłówek) ----------
  for (const [w, h] of [[1440, 900], [360, 740]]) {
    const ctx = await b.newContext({ viewport: { width: w, height: h }, reducedMotion: 'reduce' });
    const p = await ctx.newPage();
    const zle = [];
    const cele = ['lista-1', 'lista-2', 'ankieta', 'podologia', 'grupa-1', 'grupa-2', 'grupa-3', 'grupa-4', 'zabiegi-z-uzyciem-wypelniaczy-na-bazie-kwasu-hialuronowego',
      'wypelniacze-kwas-hialuronowy', 'barbering', 'manicure', 'manicure-lista-2', 'tatuaz', 'taryfa', 'ochrona-prawna', 'faq', 'pytanie-5', ...ALIASY_ZAB.map((a) => a[0])];
    for (const hash of cele) {
      await p.goto(FILE + '#' + hash, { waitUntil: 'networkidle' }); await p.waitForTimeout(200);
      const r = await p.evaluate((hash) => {
        const t = document.getElementById(hash); const cel = t.classList.contains('z-alias') ? (t.closest('li') || t.closest('section')) : t;
        const rc = cel.getBoundingClientRect(); const hb = document.querySelector('.header-bar').getBoundingClientRect();
        const d = t.closest('details');
        return { below: rc.top >= hb.bottom - 2, inView: rc.top < innerHeight && rc.bottom > 0, open: d ? d.open : true, vis: cel.checkVisibility() };
      }, hash);
      if (!(r.inView && r.open && r.vis && r.below)) zle.push(hash + ' ' + JSON.stringify(r));
    }
    ma(`kotwice z JS ${w}: sekcje, aliasy i pozycje widoczne pod nagłówkiem`, zle.length === 0, zle);
    // zamknięte <details> + alias dawnego slugu → rozwija listę i pokazuje właściwy <li>
    await p.goto(FILE, { waitUntil: 'networkidle' });
    const zleAliasy = [];
    for (const [alias, z] of ALIASY_ZAB) {
      await p.evaluate(() => { document.querySelectorAll('.zdetails').forEach((d) => { d.open = false; }); location.hash = ''; });
      await p.evaluate((a) => { location.hash = a; }, alias); await p.waitForTimeout(150);
      const r = await p.evaluate((a) => { const li = document.getElementById(a).closest('li'); const rc = li.getBoundingClientRect(); return { id: li.id, open: li.closest('details').open, inView: rc.top >= 0 && rc.bottom <= innerHeight }; }, alias);
      if (!(r.id === z.slug && r.open && r.inView)) zleAliasy.push(alias + ' ' + JSON.stringify(r));
    }
    ma(`aliasy ${w}: 18 dawnych slugów rozwija listę i przewija do pozycji`, zleAliasy.length === 0, zleAliasy);
    await ctx.close();
  }
  // ---------- cele dotyku (WCAG 2.2 2.5.8: 24 × 24, bez linków w tekście) ----------
  for (const [w, h] of [[390, 844], [1440, 900]]) {
    const p = await b.newPage({ viewport: { width: w, height: h } });
    await p.goto(FILE, { waitUntil: 'networkidle' });
    const male = await p.evaluate(() => {
      const res = [];
      for (const el of document.querySelectorAll('a[href],button,summary,input,[tabindex="0"]')) {
        if (!el.checkVisibility()) continue;
        const r = el.getBoundingClientRect(); if (r.width === 0) continue;
        const blok = el.closest('p,li,dd');
        if (getComputedStyle(el).display === 'inline' && blok && blok.textContent.trim() !== el.textContent.trim()) continue;
        if (r.width < 24 || r.height < 24) res.push(el.tagName + '.' + el.className + ' "' + el.textContent.trim().slice(0, 30) + '" ' + Math.round(r.width) + 'x' + Math.round(r.height));
      }
      return res;
    });
    ma(`cele dotyku ${w}: ≥ 24 × 24`, male.length === 0, male.slice(0, 10));
    await p.close();
  }
  await b.close();
  console.log(bledy.length ? 'BŁĘDY (' + bledy.length + '):\n' + bledy.join('\n') : 'OK – listy = JSON (120 pozycji), 53 dawne kotwice bez JS, filtr, kotwice i aliasy z JS, nagłówki, cele dotyku');
  process.exit(bledy.length ? 1 : 0);
})();
