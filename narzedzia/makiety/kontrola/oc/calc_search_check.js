// Kalkulator OC (makieta-v3.html): wyszukiwarka zabiegów i dialog klauzuli – po Aneksie nr 5 (plan rozdz. 7, krok 4).
//   „mezo”  → podpowiedzi z plakietką listy („Lista nr 2”); Enter na pierwszej: żaden rodzaj działalności nie jest zaznaczony,
//             #cena bez zmian, chip „<nazwa> lista nr 2” w „Wybranych zabiegach” (wybór nie zmienia składki – P2);
//   „nici”  → podpowiedź poz. g) z plakietką „Ankieta, poz. g)”; wybór zaznacza „Wykonuję zabiegi wymagające ankiety ERGO Hestii”
//             i pozycję g) (g4-06), panel: „Składka do indywidualnej wyceny”;
//   dialog klauzuli: 12 punktów, Esc zamyka i oddaje fokus przyciskowi „Pokaż treść klauzuli”.
// Uruchom: node narzedzia/makiety/kontrola/oc/calc_search_check.js [ścieżka makieta-v3.html]   (kod wyjścia 1 przy błędzie)
const { chromium } = require('playwright');
const path = require('path');
const plik = process.argv[2] ? path.resolve(process.argv[2]) : path.resolve(__dirname, '../../../../docs/koncepcja/design/v3/makieta-v3.html');
(async () => {
  const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1280, height: 900 } });
  const errs = []; p.on('pageerror', (e) => errs.push(e.message));
  await p.goto('file://' + plik, { waitUntil: 'load' });
  const bledy = [];
  const ma = (opis, war) => { if (!war) bledy.push(opis); };
  const cb = p.locator('[role="combobox"]').first();
  const cenaPrzed = await p.textContent('#cena');
  await cb.fill('mezo'); await p.waitForTimeout(200);
  // twarda spacja = spacja (runda 2 weryfikacji: plakietki „Lista nr\u00a02”, „Ankieta, poz.\u00a0g)”)
  const nbsp = (l) => l.map((x) => x.replace(/\u00a0/g, ' '));
  const opts = nbsp(await p.locator('[role="option"]').allTextContents());
  const plak = nbsp(await p.locator('[role="option"] .zab-badge').allTextContents());
  ma('„mezo”: podpowiedzi', opts.length > 0 && opts.every((o) => /mezoterapi/i.test(o)));
  ma('„mezo”: plakietki list (bez grup)', plak.length === opts.length && plak.every((x) => /^(Lista nr [12]|Listy nr 1 i 2)$/.test(x)));
  await cb.press('ArrowDown'); await cb.press('Enter'); await p.waitForTimeout(600);
  const rodzaje = await p.locator('input[name="rodzaj"]:checked').count();
  const chips = (await p.locator('.zab-chip').allTextContents()).map((t) => t.replace(/\s+/g, ' ').replace('×', '').trim());
  const status1 = (await p.textContent('#calc-status')).trim();
  ma('„mezo”: wybór nie zaznacza rodzaju działalności', rodzaje === 0);
  ma('„mezo”: wybór nie zmienia #cena', (await p.textContent('#cena')) === cenaPrzed);
  ma('„mezo”: chip z numerem listy', chips.length === 1 && / lista nr [12]$| listy nr 1 i 2$/.test(chips[0]));
  ma('„mezo”: komunikat „Wybór nie zmienia składki.”', /Wybór nie zmienia składki\.$/.test(status1));
  await cb.fill('nici'); await p.waitForTimeout(200);
  const nici = nbsp(await p.locator('[role="option"]').allTextContents());
  ma('„nici”: poz. g) w brzmieniu Aneksu nr 5', nici.some((o) => o.includes('Zabiegi z użyciem nici PDO, PLLA i PLA/CL') && o.includes('Ankieta, poz. g)')));
  await p.click('#zab-opt-g4-06'); await p.waitForTimeout(600);
  const ank = await p.locator('#ankieta').isChecked(), g = await p.locator('#g4-06').isChecked();
  const cena = await p.textContent('#cena');
  ma('„nici”: zaznaczone „Wykonuję…” i poz. g)', ank && g);
  ma('„nici”: wycena indywidualna', cena === 'Składka do indywidualnej wyceny');
  const status2 = (await p.textContent('#calc-status')).trim();
  const btn = p.locator('button:has-text("Pokaż treść klauzuli")').first();
  await btn.click(); await p.waitForTimeout(200);
  const dlg = await p.evaluate(() => { const d = document.querySelector('dialog[open]'); return d ? [d.querySelectorAll('ol > li').length, d.textContent.includes('zgodą Ubezpieczyciela'), d.querySelector('.klauzula-foot').textContent.replace(/\s+/g, ' ').trim()] : null; });
  await p.keyboard.press('Escape'); await p.waitForTimeout(150);
  const closed = await p.evaluate(() => !document.querySelector('dialog[open]') && document.activeElement && document.activeElement.textContent.trim());
  ma('dialog klauzuli: 12 punktów', dlg && dlg[0] === 12 && dlg[1]);
  ma('dialog klauzuli: limit w stopce', dlg && dlg[2].includes('Limit: 100 000 zł'));
  ma('dialog klauzuli: fokus wraca do „Pokaż treść klauzuli”', closed === 'Pokaż treść klauzuli ochrony prawnej');
  ma('błędy JS', errs.length === 0);
  console.log({ opts: opts.slice(0, 4), plak: plak.slice(0, 4), chips, status1, nici: nici.slice(0, 2), ankieta: [ank, g], cena, status2: status2.slice(0, 160), dlg, closedFocus: closed, errs });
  await b.close();
  console.log(bledy.length ? 'BŁĘDY (' + bledy.length + '):\n' + bledy.join('\n') : 'OK');
  process.exit(bledy.length ? 1 : 0);
})();
