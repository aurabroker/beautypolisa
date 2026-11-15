const { chromium } = require('playwright');
const REPO = require('path').resolve(__dirname, '../../../..');  // katalog główny repozytorium
const WYNIKI = require('path').join(__dirname, '../wyniki/dam-prace') + '/';  // zrzuty i wyniki (poza gitem)
require('fs').mkdirSync(WYNIKI, { recursive: true });
const BASE='file://' + REPO + '/docs/koncepcja/design/v3/strefa/dam-prace.html';
(async()=>{const b=await chromium.launch();const errs=[];
for (const [w,h,m] of [[844,390,true],[740,360,true],[640,360,true],[568,320,true],[320,256,false],[320,568,true],[390,844,true],[768,1024,true],[1440,900,false],[1024,600,false]]){
 const c=await b.newContext({viewport:{width:w,height:h},isMobile:m,hasTouch:m});const p=await c.newPage();
 p.on('pageerror',e=>errs.push(w+'x'+h+' '+e.message));
 await p.goto(BASE+'#oferty');await p.waitForTimeout(200);
 if(!(await p.$eval('#filtry-panel',d=>d.open)))await p.click('#filtry-panel > summary');
 await p.click('#zab-oferty .zab-open');await p.waitForTimeout(300);
 // otwórz grupę 2 (klik w nagłówek), zaznacz 2 zabiegi
 await p.click('#zab-oferty-dlg .zab-grp[data-lista="lista-2"] > summary');
 await p.click('#zab-oferty-dlg .zab-grp[data-lista="lista-2"] label >> nth=0');
 await p.click('#zab-oferty-dlg .zab-grp[data-lista="lista-2"] label >> nth=1');
 const st=await p.$eval('#zab-oferty-dlg .zab-count',e=>e.textContent);
 const done=await p.$('#zab-oferty-dlg .zab-done');const vis=await done.isVisible();
 const box=await done.boundingBox();
 const hs=await p.evaluate(()=>{const d=document.getElementById('zab-oferty-dlg');return {dlgSW:d.scrollWidth,dlgCW:d.clientWidth,docSW:document.documentElement.scrollWidth,vw:innerWidth,dlgH:Math.round(d.getBoundingClientRect().height),dlgSH:d.scrollHeight,disp:getComputedStyle(d).display,bodyH:Math.round(d.querySelector('.zab-sheet-body').getBoundingClientRect().height)}});
 const inView=box && box.y>=0 && box.y+box.height<=h+1;
 await p.screenshot({path:WYNIKI+`okno-${w}x${h}.png`});
 await done.click();await p.waitForTimeout(200);
 const res=await p.$eval('#ofert-liczba',e=>e.textContent);
 console.log(w+'x'+h,'status:',JSON.stringify(st),'| done visible',vis,'inView',inView,'|',JSON.stringify(hs),'| wynik',res);
 await c.close();}
 // search status + outline clip
 const c=await b.newContext({viewport:{width:1440,height:900}});const p=await c.newPage();
 await p.goto(BASE+'#oferty');await p.waitForTimeout(200);
 if(!(await p.$eval('#filtry-panel',d=>d.open)))await p.click('#filtry-panel > summary');
 await p.click('#zab-oferty .zab-open');await p.waitForTimeout(300);
 await p.fill('#zab-oferty-q','rzes');await p.waitForTimeout(600);console.log('search st:',await p.$eval('#zab-oferty-q-st',e=>e.textContent));
 await p.fill('#zab-oferty-q','xyzq');await p.waitForTimeout(600);console.log('search st:',await p.$eval('#zab-oferty-q-st',e=>e.textContent));
 await p.fill('#zab-oferty-q','');await p.focus('#zab-oferty-q');await p.keyboard.press('Tab');
 const clip=await p.evaluate(()=>{const a=document.activeElement;const r=a.getBoundingClientRect();const body=a.closest('.zab-sheet-body').getBoundingClientRect();const s=getComputedStyle(a);const o=parseFloat(s.outlineOffset)+parseFloat(s.outlineWidth);return {el:a.tagName,top:r.top-o,bodyTop:body.top,clipTop:(r.top-o)<body.top}});
 console.log('clip:',JSON.stringify(clip));
 console.log('status 0 zab:',await p.$eval('#zab-oferty-dlg .zab-count',e=>e.textContent));
 await c.close();
 // seeker form hint
 const c2=await b.newContext({viewport:{width:390,height:844}});const p2=await c2.newPage();
 await p2.goto(BASE+'#szukam-moje');await p2.waitForTimeout(200);
 console.log('sa hint:',await p2.$eval('#zab-sa-opis',e=>e.textContent));
 console.log('sa status:',await p2.$eval('#zab-sa-dlg .zab-count',e=>e.textContent));
 await c2.close();
 // no JS
 const c3=await b.newContext({viewport:{width:320,height:640},javaScriptEnabled:false});const p3=await c3.newPage();
 await p3.goto(BASE+'?zabieg=g2-12#oferty');console.log('nojs pusto-p:',await p3.$eval('#ofert-pusto-p',e=>e.textContent),'| docSW',await p3.evaluate(()=>document.documentElement.scrollWidth));
 await c3.close();
 console.log('errors:',errs);
 await b.close();})();
