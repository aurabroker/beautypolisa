// Kalkulator OC na makieta-v3.html po Aneksie nr 5 (krok 4): wyszukiwarka zabiegów (combobox ARIA 1.2: klawiatura, mysz, Esc,
// brak wyników), chipy „Wybrane zabiegi” (wybór z list nr 1 i 2 nie zaznacza rodzaju i nie zmienia składki), pozycja a–h
// z wyszukiwarki, przekazanie do formularza kontaktu, dialog klauzuli słowo w słowo, odnośnik z FAQ, bez JS.
// Szerokości 1440 i 390. Zrzuty: kontrola/wyniki/oc/. Uruchom: node narzedzia/makiety/kontrola/oc/test_zab.js (kod 1 przy błędzie)
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const REPO = path.resolve(__dirname, '../../../..');  // katalog główny repozytorium
const OUT = path.join(__dirname, '../wyniki/oc') + '/';  // zrzuty (poza gitem)
fs.mkdirSync(OUT, { recursive: true });
const file = 'file://' + REPO + '/docs/koncepcja/design/v3/makieta-v3.html';
const K = JSON.parse(fs.readFileSync(REPO + '/docs/koncepcja/snippets/klauzula-ochrona-prawna.json', 'utf8'));
const bledy = [];
(async () => {
  const b = await chromium.launch();
  for (const [w, h] of [[1440, 900], [390, 844]]) {
    const p = await b.newPage({ viewport: { width: w, height: h } });
    const errs = []; p.on('pageerror', (e) => errs.push(e.message)); p.on('console', (m) => { if (m.type() === 'error') errs.push(m.text()); });
    await p.goto(file, { waitUntil: 'networkidle' });
    const log = (...a) => console.log(w + ':', ...a);
    const ma = (opis, war) => { if (!war) bledy.push(w + ': ' + opis); };
    ma('wyszukiwarka widoczna', await p.locator('#zab-search').isVisible());
    await p.locator('#r-kosmetyczny').check(); await p.locator('#o-1-5').check(); await p.locator('#s-100000').check();
    const cena0 = await p.locator('#cena').textContent();
    ma('stała kwota przed wyszukiwaniem', cena0 === '400,00 zł');
    await p.locator('#zab-q').focus();
    await p.keyboard.type('mezo');
    const opts = await p.locator('#zab-lista [role=option]').allTextContents();
    log('expanded', await p.locator('#zab-q').getAttribute('aria-expanded'), 'options', opts);
    ma('combobox rozwinięty', (await p.locator('#zab-q').getAttribute('aria-expanded')) === 'true' && opts.length >= 3);
    await p.keyboard.press('ArrowDown');
    const ad = await p.locator('#zab-q').getAttribute('aria-activedescendant');
    ma('aria-activedescendant + aria-selected', ad && (await p.locator('#' + ad).getAttribute('aria-selected')) === 'true');
    await p.locator('#kalkulator-oc').screenshot({ path: OUT + `calc-open-${w}.png` });
    await p.keyboard.press('End'); const adEnd = await p.locator('#zab-q').getAttribute('aria-activedescendant');
    await p.keyboard.press('Home'); const adHome = await p.locator('#zab-q').getAttribute('aria-activedescendant');
    ma('End/Home', adEnd !== adHome && adHome === ad);
    await p.keyboard.press('Enter');
    await p.waitForTimeout(600);
    const chips1 = await p.locator('.zab-chip').count();
    log('rodzaje', await p.locator('input[name=rodzaj]:checked').count(), 'chips', await p.locator('.zab-chip').allTextContents(), 'status', await p.locator('#calc-status').textContent(), 'price', await p.locator('#cena').textContent());
    ma('wybór z listy nie zmienia rodzajów', (await p.locator('input[name=rodzaj]:checked').count()) === 1);
    ma('wybór z listy nie zmienia składki', (await p.locator('#cena').textContent()) === cena0);
    ma('chip po wyborze', chips1 === 1);
    ma('fokus wraca do pola, lista zamknięta', (await p.evaluate(() => document.activeElement.id)) === 'zab-q' && (await p.locator('#zab-q').getAttribute('aria-expanded')) === 'false');
    // polskie znaki i wielkość liter
    await p.keyboard.type('MANICURE');
    const man = (await p.locator('#zab-lista [role=option]').allTextContents()).map((x) => x.replace(/\u00a0/g, ' '));  // twarda spacja = spacja (runda 2)
    ma('„MANICURE” → Manicure z plakietką „Listy nr 1 i 2”', man.some((o) => o.startsWith('Manicure') && o.endsWith('Listy nr 1 i 2')));
    await p.keyboard.press('Escape'); ma('Esc zamyka listę', (await p.locator('#zab-q').getAttribute('aria-expanded')) === 'false' && (await p.locator('#zab-q').inputValue()) === 'MANICURE');
    await p.keyboard.press('Escape'); ma('drugi Esc czyści pole', (await p.locator('#zab-q').inputValue()) === '');
    await p.keyboard.type('zabiegi z uzyciem nici');
    ma('bez polskich znaków → poz. g)', (await p.locator('#zab-lista [role=option]').allTextContents()).some((o) => o.includes('nici PDO, PLLA i PLA/CL')));
    // „ł” bez polskiego znaku: „wlosow” → pozycje z „włosów” (norm: ł → l, znaki łączące \u0300–\u036f usunięte)
    await p.locator('#zab-q').fill(''); await p.keyboard.type('laminowanie wlosow');
    ma('„laminowanie wlosow” → Laminowanie włosów', (await p.locator('#zab-lista [role=option]').allTextContents()).some((o) => o.startsWith('Laminowanie włosów')));
    // weryfikacja, runda 2: odnośniki poza listą podpowiedzi; Tab zamyka listę (wzorzec APG combobox) i nie zostawia aktywnej opcji
    ma('odnośniki poza listą podpowiedzi', (await p.locator('#zab-pop a').count()) === 0 && (await p.locator('#zab-wszystkie').count()) === 0);
    ma('odnośnik do sekcji Podologia pod polem', (await p.locator('#zab-search > .zab-more #zab-podologia').getAttribute('href')) === 'oc-beauty.html#podologia');
    await p.keyboard.press('ArrowDown');
    await p.keyboard.press('Tab');
    const poTab = await p.evaluate(() => { const q = document.getElementById('zab-q'), pop = document.getElementById('zab-pop'), a = document.activeElement;
      return { exp: q.getAttribute('aria-expanded'), ad: q.getAttribute('aria-activedescendant'), aktywne: document.querySelectorAll('#zab-lista .is-active,#zab-lista [aria-selected="true"]').length,
        ukryta: pop.hidden, wPopup: pop.contains(a), id: a.id }; });
    log('po Tab', JSON.stringify(poTab));
    ma('Tab zamyka listę bez aktywnej opcji', poTab.exp === 'false' && poTab.ad === null && poTab.aktywne === 0 && poTab.ukryta && !poTab.wPopup);
    await p.locator('#zab-q').focus();
    // mysz: pozycja a–h zaznacza „Wykonuję…” i tę pozycję; składka do wyceny
    await p.locator('#zab-q').fill(''); await p.keyboard.type('hifu');
    await p.locator('#zab-lista [role=option]').first().click();
    await p.waitForTimeout(600);
    log('ankieta', await p.locator('#ankieta').isChecked(), await p.locator('#g4-01').isChecked(), 'price', await p.locator('#cena').textContent(), 'status', await p.locator('#calc-status').textContent());
    ma('HIFU → „Wykonuję…” i poz. d)', (await p.locator('#ankieta').isChecked()) && (await p.locator('#g4-01').isChecked()));
    ma('HIFU → wycena indywidualna', (await p.locator('#cena').textContent()) === 'Składka do indywidualnej wyceny');
    ma('HIFU → bez chipa', (await p.locator('.zab-chip').count()) === chips1);
    ma('HIFU → dokumenty z CRM widoczne', await p.locator('#ankieta-info').isVisible());
    // brak wyników
    await p.locator('#zab-q').fill(''); await p.keyboard.type('xyzzy');
    await p.waitForTimeout(600);
    const brak = await p.locator('#zab-brak').textContent();
    log('brak', brak);
    ma('brak wyników: komunikat i odnośniki', (await p.locator('#zab-brak').isVisible()) && brak.startsWith('Zabiegu „xyzzy” nie ma na listach zabiegów programu.') && (await p.locator('#zab-brak a').count()) === 3);
    // Q1: zabiegów podologicznych nie ma w wyszukiwarce – stałe zdanie i odnośnik do sekcji Podologia (bez oceny zakresu)
    ma('brak wyników: zdanie o liście podologicznej i odnośnik', brak.replace(/\u00a0/g, ' ').includes('Lista zabiegów podologicznych jest w dokumentach programu') && (await p.locator('#zab-brak a[href="oc-beauty.html#podologia"]').count()) === 1);
    // „zapytaj doradcę” ustawia temat formularza (a[data-produkt] – jak inne odnośniki kalkulatora do #kontakt)
    ma('brak wyników: „zapytaj doradcę” z tematem OC', (await p.locator('#zab-brak a[href="#kontakt"]').getAttribute('data-produkt')) === 'oc-beauty');
    await p.locator('#zab-brak a[href="#kontakt"]').click(); await p.waitForTimeout(300);
    ma('brak wyników: po „zapytaj doradcę” temat formularza = OC', (await p.locator('#l-produkt').inputValue()) === 'oc-beauty');
    await p.locator('#zab-q').fill('');
    await p.locator('#kalkulator-oc').screenshot({ path: OUT + `calc-chips-${w}.png` });
    // przekazanie do formularza (wycena indywidualna: zabiegi z ankiety)
    await p.locator('#cta-oferta').click(); await p.waitForTimeout(300);
    const lead = await p.evaluate(() => { const f = document.querySelector('#lead').elements; return [f.rodzaje.value, f.osoby.value, f.suma.value, f.prawna.value, f.ankieta.value, f.zabiegi.value, f.product.value]; });
    log('lead', await p.locator('#kontakt-wynik').textContent(), '|', lead.join(' | '));
    ma('pola #lead', lead[0] === 'kosmetyczny' && lead[1] === '1-5' && lead[2] === '100000' && lead[3] === '0' && lead[4] === 'g4-01' && /^g\d-\d\d$/.test(lead[5]) && lead[6] === 'oc-beauty');
    // usunięcie chipa: fokus na polu, rodzaj zostaje
    await p.locator('.zab-chip-x').first().click(); await p.waitForTimeout(600);
    ma('usunięcie chipa', (await p.locator('.zab-chip').count()) === chips1 - 1 && (await p.locator('input[name=rodzaj]:checked').count()) === 1);
    // dialog klauzuli
    await p.locator('#klauzula-open').scrollIntoViewIfNeeded();
    ma('„Pokaż treść klauzuli” jako przycisk', (await p.evaluate(() => document.getElementById('klauzula-open').tagName)) === 'BUTTON');
    await p.locator('#klauzula-open').focus(); await p.keyboard.press('Enter');
    await p.waitForTimeout(500);
    const dl = await p.evaluate(() => { const d = document.getElementById('klauzula-dialog'); const r = d.getBoundingClientRect(); const bd = d.querySelector('.klauzula-body'); return { open: d.open, w: r.width, h: r.height, scrollH: bd.scrollHeight, clientH: bd.clientHeight, tytul: d.querySelector('.klauzula-tytul').textContent, items: [...d.querySelectorAll('.klauzula-body > ol > li')].map((li) => ({ t: li.firstChild.textContent.trim(), u: [...li.querySelectorAll('ul li')].map((x) => x.textContent) })) }; });
    // brzmienie słowo w słowo; twarde spacje (polska typografia, typografia.py – raport 16, 3.1) = spacje
    const sp = (t) => t.replace(/\u00a0/g, ' ');
    const same = sp(dl.tytul) === K.tytul && dl.items.length === 12 && dl.items.every((it, i) => sp(it.t) === K.punkty[i].tekst && JSON.stringify(it.u.map(sp)) === JSON.stringify(K.punkty[i].wyliczenie || []));
    log('dialog size', dl.w, dl.h, 'scroll', dl.scrollH, dl.clientH, 'verbatim', same);
    ma('dialog klauzuli otwarty, treść słowo w słowo', dl.open && same);
    await p.screenshot({ path: OUT + `dialog-${w}.png` });
    await p.keyboard.press('Escape'); await p.waitForTimeout(300);
    ma('Esc zamyka dialog, fokus wraca', !(await p.evaluate(() => document.getElementById('klauzula-dialog').open)) && (await p.evaluate(() => document.activeElement.id)) === 'klauzula-open');
    // odnośnik z FAQ przy aktywnej zakładce Tax Protect
    await p.locator('#tab-tax').click();
    await p.locator('#faq-ochrona-prawna summary').click();
    await p.locator('#faq-ochrona-prawna a[data-klauzula]').click(); await p.waitForTimeout(400);
    ma('FAQ otwiera dialog', await p.locator('#klauzula-dialog').isVisible());
    await p.locator('.klauzula-close').click(); await p.waitForTimeout(300);
    const sw = await p.evaluate(() => document.documentElement.scrollWidth);
    log('scrollWidth', sw, 'errors', JSON.stringify(errs));
    ma('bez przewijania w poziomie', sw <= w);
    ma('bez błędów JS', errs.length === 0);
    await p.close();
  }
  // bez JS: wyszukiwarka ukryta, link do list, klauzula jako odnośnik, pozycje a–h widoczne, żadne pole nie zaznaczone
  const ctx = await b.newContext({ javaScriptEnabled: false, viewport: { width: 390, height: 844 } });
  const p = await ctx.newPage(); await p.goto(file);
  const nojs = { search: await p.locator('#zab-search').isVisible(), listy: await p.locator('.zab-full a').isVisible(), klauzula: await p.locator('#klauzula-open').getAttribute('href'), ah: await p.locator('input[name=ankieta]').first().isVisible(), checked: await p.locator('#calc input:checked').count() };
  console.log('nojs', nojs);
  if (nojs.search || !nojs.listy || nojs.klauzula !== 'oc-beauty.html#ochrona-prawna' || !nojs.ah || nojs.checked) bledy.push('bez JS: ' + JSON.stringify(nojs));
  await p.locator('#kalkulator-oc').screenshot({ path: OUT + 'calc-nojs-390.png' });
  await b.close();
  console.log(bledy.length ? 'BŁĘDY (' + bledy.length + '):\n' + bledy.join('\n') : 'OK');
  process.exit(bledy.length ? 1 : 0);
})();
