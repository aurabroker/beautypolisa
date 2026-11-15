const { chromium } = require('playwright');
const REPO = require('path').resolve(__dirname, '../../../..');  // katalog główny repozytorium
const WYNIKI = require('path').join(__dirname, '../wyniki/dam-prace') + '/';  // zrzuty i wyniki (poza gitem)
require('fs').mkdirSync(WYNIKI, { recursive: true });
const BASE='file://' + REPO + '/docs/koncepcja/design/v3/strefa/dam-prace.html';
const desc=()=>{const a=document.activeElement;const s=getComputedStyle(a);const r=a.getBoundingClientRect();return (a.tagName+'#'+a.id+' '+(a.value&&a.type==='checkbox'?a.value:'')+' "'+(a.getAttribute('aria-label')||a.textContent||'').trim().slice(0,28)+'" outline:'+s.outlineStyle+'/'+s.outlineWidth+' top:'+Math.round(r.top))};
(async()=>{const b=await chromium.launch();
 for (const [w,h,m] of [[1440,900,false],[390,844,true]]) {
 const c=await b.newContext({viewport:{width:w,height:h},isMobile:m,hasTouch:m});const p=await c.newPage();
 await p.goto(BASE+'#oferty');await p.waitForTimeout(200);
 console.log('\n##',w);
 // dojście klawiaturą do filtrów
 if(!(await p.$eval('#filtry-panel',d=>d.open))){await p.focus('#filtry-panel > summary');await p.keyboard.press('Enter');}
 await p.focus('#f-umowa');await p.keyboard.press('Tab');console.log('Tab po „Rodzaj umowy” ->',await p.evaluate(desc));
 await p.keyboard.press('Enter');await p.waitForTimeout(300);console.log('Enter ->',await p.evaluate(desc),'open',await p.$eval('#zab-oferty-dlg',d=>d.open));
 for(let i=0;i<4;i++){await p.keyboard.press('Tab');console.log(' Tab ->',await p.evaluate(desc));}
 await p.keyboard.press('Enter');await p.waitForTimeout(50);console.log('Enter na summary -> open grp?',await p.evaluate(()=>[...document.querySelectorAll('#zab-oferty-dlg .zab-grp')].map(g=>g.open)));
 await p.keyboard.press('Tab');console.log(' Tab ->',await p.evaluate(desc));
 await p.screenshot({path:WYNIKI+`fokus-checkbox-${w}.png`});
 await p.keyboard.press('Space');await p.keyboard.press('Tab');await p.keyboard.press('Space');
 console.log('2x Spacja -> ',await p.$eval('#zab-oferty-dlg .zab-count',e=>e.textContent),'|',await p.$eval('#zab-oferty-dlg .zab-done',e=>e.textContent));
 // Enter w polu szukania nie wysyła formularza
 await p.focus('#zab-oferty-q');await p.keyboard.type('Barb');await p.keyboard.press('Enter');await p.waitForTimeout(100);
 console.log('Enter w szukaniu -> url',p.url().replace(/.*\//,''),'open',await p.$eval('#zab-oferty-dlg',d=>d.open));
 await p.keyboard.press('Shift+Tab');console.log(' Shift+Tab z pola szukania ->',await p.evaluate(desc));
 // pierwszy summary – czy obrys nie jest przycięty przez kontener przewijany
 await p.fill('#zab-oferty-q','');await p.focus('#zab-oferty-q');await p.keyboard.press('Tab');
 const clip=await p.evaluate(()=>{const a=document.activeElement;const r=a.getBoundingClientRect();const body=a.closest('.zab-sheet-body').getBoundingClientRect();const s=getComputedStyle(a);const o=parseFloat(s.outlineOffset)+parseFloat(s.outlineWidth);return {el:a.tagName,outline:s.outlineStyle,top:r.top-o,bodyTop:body.top,left:r.left-o,bodyLeft:body.left,clipTop:(r.top-o)<body.top,clipLeft:(r.left-o)<body.left}});
 console.log('obrys 1. summary vs kontener:',JSON.stringify(clip));
 await p.screenshot({path:WYNIKI+`fokus-summary-${w}.png`});
 // do „Pokaż ogłoszenia”
 await p.focus('#zab-oferty-dlg .zab-done');await p.keyboard.press('Enter');await p.waitForTimeout(200);
 const ob=await p.evaluate(()=>{const a=document.activeElement;const r=a.getBoundingClientRect();const hd=document.querySelector('.pub-header');const hr=hd.getBoundingClientRect();return {focus:a.id,top:Math.round(r.top),bottom:Math.round(r.bottom),headerBottom:Math.round(hr.bottom),headerPos:getComputedStyle(hd).position,obscured:r.top<hr.bottom&&getComputedStyle(hd).position==='sticky',spt:getComputedStyle(document.documentElement).scrollPaddingTop}});
 console.log('fokus po „Pokaż ogłoszenia” vs przyklejony nagłówek:',JSON.stringify(ob));
 await p.screenshot({path:WYNIKI+`po-pokaz-${w}.png`});
 // chipy: Tab od przycisku
 await p.focus('#zab-oferty .zab-open');await p.keyboard.press('Tab');console.log('Tab za przyciskiem ->',await p.evaluate(desc));
 await p.keyboard.press('Tab');console.log('Tab ->',await p.evaluate(desc));
 await p.keyboard.press('Tab');console.log('Tab ->',await p.evaluate(desc));
 await c.close();}
 await b.close();})();
