const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1280, height: 900 } });
  await p.goto('file://' + process.argv[2], { waitUntil: 'load' });
  const cb = p.locator('[role="combobox"]').first();
  await cb.fill('mezo'); await p.waitForTimeout(200);
  const opts = await p.locator('[role="option"]').allTextContents();
  await cb.press('ArrowDown'); await cb.press('Enter'); await p.waitForTimeout(200);
  const g2 = await p.locator('#g2').isChecked();
  const status = await p.evaluate(() => [...document.querySelectorAll('[role=status]')].map(e => e.textContent.trim()).filter(Boolean).join(' | '));
  const btn = p.locator('button:has-text("Treść klauzuli")').first();
  await btn.click(); await p.waitForTimeout(200);
  const dlg = await p.evaluate(() => { const d = document.querySelector('dialog[open]'); return d ? [d.querySelectorAll('ol > li').length, d.textContent.includes('zgodą Ubezpieczyciela')] : null; });
  await p.keyboard.press('Escape'); await p.waitForTimeout(150);
  const closed = await p.evaluate(() => !document.querySelector('dialog[open]') && document.activeElement && document.activeElement.textContent.trim());
  console.log({ opts: opts.slice(0, 4), g2, status: status.slice(0, 160), dlg, closedFocus: closed });
  await b.close();
})();
