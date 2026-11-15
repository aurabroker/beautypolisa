const { chromium } = require('playwright');
const REPO = require('path').resolve(__dirname, '../../../..');  // katalog główny repozytorium
const WYNIKI = require('path').join(__dirname, '../wyniki/oc') + '/';  // zrzuty i wyniki (poza gitem)
require('fs').mkdirSync(WYNIKI, { recursive: true });
const fs = require('fs');
const OUT = WYNIKI;
const file = 'file://' + REPO + '/docs/koncepcja/design/v3/makieta-v3.html';
const K = JSON.parse(fs.readFileSync(REPO + '/docs/koncepcja/snippets/klauzula-ochrona-prawna.json','utf8'));
(async () => {
  const b = await chromium.launch();
  for (const [w,h] of [[1440,900],[390,844]]) {
    const p = await b.newPage({ viewport:{width:w,height:h} });
    const errs=[]; p.on('pageerror',e=>errs.push(e.message)); p.on('console',m=>{if(m.type()==='error')errs.push(m.text())});
    await p.goto(file,{waitUntil:'networkidle'});
    const log=(...a)=>console.log(w+':',...a);
    log('search visible', await p.locator('#zab-search').isVisible());
    await p.locator('#g1').uncheck();
    await p.locator('#zab-q').focus();
    await p.keyboard.type('mezo');
    log('expanded', await p.locator('#zab-q').getAttribute('aria-expanded'), 'options', await p.locator('#zab-lista [role=option]').allTextContents());
    await p.keyboard.press('ArrowDown');
    const ad = await p.locator('#zab-q').getAttribute('aria-activedescendant');
    log('activedescendant', ad, await p.locator('#'+ad).getAttribute('aria-selected'));
    await p.locator('#kalkulator-oc').screenshot({path: OUT+`calc-open-${w}.png`});
    await p.keyboard.press('End'); log('End ->', await p.locator('#zab-q').getAttribute('aria-activedescendant'));
    await p.keyboard.press('Home'); log('Home ->', await p.locator('#zab-q').getAttribute('aria-activedescendant'));
    await p.keyboard.press('Enter');
    await p.waitForTimeout(600);
    log('g2', await p.locator('#g2').isChecked(), 'chips', await p.locator('.zab-chip').allTextContents(), 'status', await p.locator('#calc-status').textContent(), 'price', await p.locator('#cena').textContent());
    log('focus after pick', await p.evaluate(()=>document.activeElement.id), 'expanded', await p.locator('#zab-q').getAttribute('aria-expanded'));
    // diacritics + synonym
    await p.keyboard.type('zel hybrydowy'); log('zel ->', (await p.locator('#zab-lista [role=option]').allTextContents()).slice(0,3));
    await p.keyboard.press('Escape'); log('esc closes', await p.locator('#zab-q').getAttribute('aria-expanded'), 'value', await p.locator('#zab-q').inputValue());
    await p.keyboard.press('Escape'); log('esc2 clears', JSON.stringify(await p.locator('#zab-q').inputValue()));
    await p.keyboard.type('LASER'); log('laser count', await p.locator('#zab-lista [role=option]').count(), await p.locator('#zab-wszystkie').textContent());
    await p.locator('#zab-q').fill(''); await p.keyboard.type('hifu');
    // mouse pick
    await p.locator('#zab-lista [role=option]').first().click();
    await p.waitForTimeout(600);
    log('g4', await p.locator('#g4').isChecked(), 'price', await p.locator('#cena').textContent(), 'status', await p.locator('#calc-status').textContent());
    // no results
    await p.locator('#zab-q').fill(''); await p.keyboard.type('xyzzy');
    await p.waitForTimeout(600);
    log('brak', await p.locator('#zab-brak').isVisible(), await p.locator('#zab-brak').textContent(), '| status', await p.locator('#calc-status').textContent());
    await p.locator('#zab-q').fill('');
    // chip removal keeps group
    await p.locator('.zab-chip-x').first().click(); await p.waitForTimeout(600);
    log('after remove: g2', await p.locator('#g2').isChecked(), 'chips', await p.locator('.zab-chip').count(), 'focus', await p.evaluate(()=>document.activeElement.className), 'status', await p.locator('#calc-status').textContent());
    await p.locator('#kalkulator-oc').screenshot({path: OUT+`calc-chips-${w}.png`});
    // CTA to form
    await p.locator('#cta-oferta').click(); await p.waitForTimeout(300);
    log('lead', await p.locator('#kontakt-wynik').textContent(), '| zabiegi=', await p.evaluate(()=>document.querySelector('#lead').elements.zabiegi.value));
    // dialog
    await p.locator('#klauzula-open').scrollIntoViewIfNeeded();
    log('opener tag', await p.evaluate(()=>document.getElementById('klauzula-open').tagName));
    await p.locator('#klauzula-open').focus(); await p.keyboard.press('Enter');
    await p.waitForTimeout(500);
    log('dialog open', await p.evaluate(()=>document.getElementById('klauzula-dialog').open), 'focus', await p.evaluate(()=>document.activeElement.className));
    const dl = await p.evaluate(()=>{const d=document.getElementById('klauzula-dialog');const r=d.getBoundingClientRect();const bd=d.querySelector('.klauzula-body');return {w:r.width,h:r.height,scrollH:bd.scrollHeight,clientH:bd.clientHeight,tytul:d.querySelector('.klauzula-tytul').textContent,items:[...d.querySelectorAll('.klauzula-body > ol > li')].map(li=>({t:li.firstChild.textContent.trim(),u:[...li.querySelectorAll('ul li')].map(x=>x.textContent)}))}});
    const same = dl.tytul===K.tytul && dl.items.length===12 && dl.items.every((it,i)=>it.t===K.punkty[i].tekst && JSON.stringify(it.u)===JSON.stringify(K.punkty[i].wyliczenie||[]));
    log('dialog size', dl.w, dl.h, 'scroll', dl.scrollH, dl.clientH, 'verbatim', same);
    await p.screenshot({path: OUT+`dialog-${w}.png`});
    await p.keyboard.press('Escape'); await p.waitForTimeout(300);
    log('after esc open', await p.evaluate(()=>document.getElementById('klauzula-dialog').open), 'focus', await p.evaluate(()=>document.activeElement.id));
    // FAQ link with tax tab active
    await p.locator('#tab-tax').click();
    await p.locator('#faq-ochrona-prawna summary').click();
    await p.locator('#faq-ochrona-prawna a[data-klauzula]').click(); await p.waitForTimeout(400);
    log('faq opens dialog', await p.evaluate(()=>document.getElementById('klauzula-dialog').open), await p.locator('#klauzula-dialog').isVisible());
    await p.locator('.klauzula-close').click(); await p.waitForTimeout(300);
    log('close -> focus', await p.evaluate(()=>document.activeElement.textContent));
    log('scrollWidth', await p.evaluate(()=>document.documentElement.scrollWidth), 'errors', JSON.stringify(errs));
    await p.close();
  }
  // no JS
  const ctx = await b.newContext({javaScriptEnabled:false, viewport:{width:390,height:844}});
  const p = await ctx.newPage(); await p.goto(file);
  console.log('nojs: search visible', await p.locator('#zab-search').isVisible(), 'full list link', await p.locator('.zab-full a').isVisible(), 'klauzula link', await p.locator('#klauzula-open').getAttribute('href'));
  await p.locator('#kalkulator-oc').screenshot({path: OUT+'calc-nojs-390.png'});
  await b.close();
})();
