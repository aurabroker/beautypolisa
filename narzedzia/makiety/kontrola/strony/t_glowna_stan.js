// Strona główna (makieta-v3.html) – stan kalkulatorów i formularza kontaktu (raport 16, rozdz. 3.3; 17.11.2026):
//   1. powrót „wstecz” bez bfcache: pola przywrócone bez zdarzenia change → pageshow przelicza OC i Tax (wynik = zaznaczenie),
//      a formularz kontaktu dostaje właściwy tekst „co dalej” (syncCalc);
//   2. odpowiedzi kalkulatorów w adresie (?rodzaj=…&osoby=…&suma=…, ?przychody=…&sumaTax=…&spory=…) – zapis i odtworzenie przy wejściu;
//      zakładka kalkulatora w kotwicy (#kalkulator-tax) po kliknięciu;
//   3. nieaktywny przycisk OC: komunikat przy polu z brakiem (.pole-brak, aria-describedby), znika po uzupełnieniu;
//   4. formularz kontaktu: stan wysyłania (disabled, aria-busy, „Wysyłanie…”), błąd sieci (?symulacja=blad-wysylki: dane zostają,
//      role=alert z następnym krokiem), podziękowanie po sukcesie; długi tekst bez spacji nie rozpycha strony (320 px).
// Uruchom: node narzedzia/makiety/kontrola/strony/t_glowna_stan.js (kod 1 przy błędzie). Bez zrzutów.
const { chromium } = require('playwright');
const path = require('path');
const URL = 'file://' + path.resolve(__dirname, '../../../../docs/koncepcja/design/v3/makieta-v3.html');
const NB = ' ';
const bledy = []; let asercje = 0;
const ok = (w, opis) => { asercje++; if (!w) bledy.push(opis); };

(async () => {
  const b = await chromium.launch();
  const ctx = await b.newContext({ viewport: { width: 1280, height: 900 }, deviceScaleFactor: 1 });
  const p = await ctx.newPage();
  const errs = []; p.on('pageerror', (e) => errs.push(e.message));

  // 1. pola przywrócone bez change (jak przeglądarka po powrocie bez bfcache) → pageshow
  await p.goto(URL, { waitUntil: 'load' });
  await p.evaluate(() => {
    ['r-kosmetologiczny', 'o-1-5', 's-200000'].forEach((id) => { document.getElementById(id).checked = true; });
    document.getElementById('t-r3').checked = true; document.getElementById('t-s2').checked = true;
    document.getElementById('l-produkt').value = 'tax-protect';
    window.dispatchEvent(new PageTransitionEvent('pageshow', { persisted: false }));
  });
  let st = await p.evaluate(() => ({
    oc: document.getElementById('cena').textContent, cta: document.getElementById('cta-oferta').getAttribute('aria-disabled'),
    tax: document.getElementById('tax-cena').textContent, taxT: document.getElementById('tax-taryfa').textContent,
    next: document.getElementById('lead-next').textContent,
  }));
  ok(st.oc === `790,00${NB}zł` && st.cta === null, '1. OC po pageshow: ' + JSON.stringify(st));
  ok(st.tax === `2${NB}701${NB}zł` && /do 1.mln.zł/.test(st.taxT), '1. Tax po pageshow: ' + JSON.stringify(st));
  ok(/skontaktuje się z.Tobą i.poprowadzi wniosek/.test(st.next) && !/Przy OC/.test(st.next), '1. „co dalej” po pageshow: ' + st.next);

  // 1b. prawdziwy powrót „wstecz” (zaznaczenia przez kliknięcie, przejście na podstronę i powrót)
  await p.goto(URL, { waitUntil: 'load' });
  for (const id of ['r-fryzjerski', 'o-6-8', 's-300000']) await p.locator('#' + id).click();
  await p.goto('file://' + path.resolve(__dirname, '../../../../docs/koncepcja/design/v3/tax-protect.html'), { waitUntil: 'load' });
  await p.goBack({ waitUntil: 'load' }); await p.waitForTimeout(300);
  st = await p.evaluate(() => ({ oc: document.getElementById('cena').textContent, q: location.search,
    zazn: ['r-fryzjerski', 'o-6-8', 's-300000'].every((id) => document.getElementById(id).checked) }));
  ok(st.zazn && st.oc === `812,50${NB}zł`, '1b. powrót wstecz: wynik = zaznaczenie: ' + JSON.stringify(st));

  // 2. adres: zapis i odtworzenie
  ok(/rodzaj=fryzjerski/.test(st.q) && /osoby=6-8/.test(st.q) && /suma=300000/.test(st.q), '2. odpowiedzi OC w adresie: ' + st.q);
  await p.goto(URL + '?rodzaj=kosmetyczny&rodzaj=tatuaz&osoby=1-5&suma=100000&prawna=1&przychody=r500&sumaTax=t100&spory=1&produkt=oc-beauty', { waitUntil: 'load' });
  st = await p.evaluate(() => ({ oc: document.getElementById('cena').textContent, tax: document.getElementById('tax-cena').textContent,
    prawna: document.getElementById('prawna').checked, sel: document.getElementById('l-produkt').value }));
  ok(st.oc === `942,00${NB}zł` && st.prawna, '2. odtworzenie OC z adresu: ' + JSON.stringify(st));
  ok(st.tax === `2${NB}581${NB}zł`, '2. odtworzenie Tax z adresu: ' + JSON.stringify(st));
  ok(st.sel === 'oc-beauty', '2. ?produkt= zostaje: ' + st.sel);
  await p.goto(URL + '?rodzaj=<script>&osoby=99&suma=1', { waitUntil: 'load' });
  st = await p.evaluate(() => ({ n: document.querySelectorAll('#calc input:checked').length, cta: document.getElementById('cta-oferta').getAttribute('aria-disabled') }));
  ok(st.n === 0 && st.cta === 'true', '2. nieznane wartości w adresie pominięte: ' + JSON.stringify(st));
  await p.goto(URL, { waitUntil: 'load' });
  await p.locator('#tab-tax').click();
  ok((await p.evaluate(() => location.hash)) === '#kalkulator-tax', '2. zakładka Tax w kotwicy');
  await p.keyboard.press('ArrowLeft');
  ok((await p.evaluate(() => location.hash)) === '#kalkulator-oc', '2. zakładka OC (strzałka) w kotwicy');

  // 3. komunikat braku przy polu
  await p.goto(URL, { waitUntil: 'load' });
  await p.locator('#cta-oferta').click({ force: true });
  st = await p.evaluate(() => { const b = document.getElementById('kalk-rodzaje-brak'), a = document.activeElement;
    return { vis: !!b && !b.hidden, txt: b && b.textContent, fokus: a.id, opis: a.getAttribute('aria-describedby') || '' }; });
  ok(st.vis && st.fokus === 'r-kosmetyczny' && st.opis.split(' ').includes('kalk-rodzaje-brak'), '3. brak rodzaju przy polu: ' + JSON.stringify(st));
  await p.locator('#r-kosmetyczny').click();
  st = await p.evaluate(() => { const b = document.getElementById('kalk-rodzaje-brak');
    return { hid: b.hidden, opis: document.getElementById('r-kosmetyczny').getAttribute('aria-describedby') || '' }; });
  ok(st.hid && !st.opis.includes('kalk-rodzaje-brak'), '3. komunikat znika po uzupełnieniu: ' + JSON.stringify(st));
  await p.locator('#cta-oferta').click({ force: true });
  st = await p.evaluate(() => ({ b: !!document.getElementById('kalk-osoby-brak') && !document.getElementById('kalk-osoby-brak').hidden, fokus: document.activeElement.id }));
  ok(st.b && st.fokus === 'o-1-5', '3. brak liczby osób przy polu: ' + JSON.stringify(st));

  // 4. formularz: wysyłanie i błąd sieci
  for (const [sym, wynik] of [['blad-wysylki', 'blad'], ['', 'ok']]) {
    await p.goto(URL + (sym ? '?symulacja=' + sym : '') + '#kontakt', { waitUntil: 'load' });
    await p.selectOption('#l-produkt', 'oc-beauty');
    await p.fill('#l-imie', 'Anna Nowak'); await p.fill('#l-email', 'anna@salon.example');
    await p.locator('#lead button[type=submit]').click();
    st = await p.evaluate(() => { const f = document.getElementById('lead'), btn = f.querySelector('button[type=submit]');
      return { busy: f.getAttribute('aria-busy'), dis: btn.disabled, t: btn.textContent.trim() }; });
    ok(st.busy === 'true' && st.dis && st.t === 'Wysyłanie…', `4. ${wynik}: stan wysyłania: ` + JSON.stringify(st));
    await p.waitForTimeout(900);
    st = await p.evaluate(() => { const f = document.getElementById('lead'), btn = f.querySelector('button[type=submit]'), a = document.getElementById('lead-blad');
      return { hidden: f.hidden, busy: f.getAttribute('aria-busy'), dis: btn.disabled, alert: a.getAttribute('role'), blad: a.textContent,
        imie: document.getElementById('l-imie').value, status: document.getElementById('lead-status').textContent, fokus: document.activeElement.id || document.activeElement.tagName }; });
    if (wynik === 'blad') ok(!st.hidden && st.busy === 'false' && !st.dis && st.alert === 'alert' && /spróbuj ponownie/.test(st.blad) && st.imie === 'Anna Nowak', '4. błąd sieci: ' + JSON.stringify(st));
    else ok(st.hidden && /^Dziękujemy, Anna\./.test(st.status) && st.fokus === 'lead-status', '4. wysłano: ' + JSON.stringify(st));
  }

  // 5. długi tekst bez spacji przy 320 px (wyszukiwarka i podziękowanie)
  await p.setViewportSize({ width: 320, height: 640 });
  await p.goto(URL, { waitUntil: 'load' });
  await p.fill('#zab-q', 'x'.repeat(60));
  await p.waitForTimeout(100);
  ok((await p.evaluate(() => document.documentElement.scrollWidth)) <= 320, '5. 320 px: długa fraza w wyszukiwarce bez przewijania w poziomie');
  await p.selectOption('#l-produkt', 'oc-beauty'); await p.fill('#l-imie', 'a'.repeat(70) + '@salon.example'); await p.fill('#l-email', 'anna@salon.example');
  await p.locator('#lead button[type=submit]').click(); await p.waitForTimeout(900);
  ok((await p.evaluate(() => document.documentElement.scrollWidth)) <= 320, '5. 320 px: długie imię w podziękowaniu bez przewijania w poziomie');
  ok(errs.length === 0, 'błędy JS: ' + errs.join('; '));

  await b.close();
  console.log(`asercje: ${asercje}`);
  console.log(bledy.length ? 'BŁĘDY (' + bledy.length + '):\n' + bledy.join('\n') : 'OK');
  process.exit(bledy.length ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(1); });
