const { chromium } = require('playwright');
const REPO = require('path').resolve(__dirname, '../../../..');  // katalog główny repozytorium
const WYNIKI = require('path').join(__dirname, '../wyniki/dam-prace') + '/';  // zrzuty i wyniki (poza gitem)
require('fs').mkdirSync(WYNIKI, { recursive: true });
const BASE='file://' + REPO + '/docs/koncepcja/design/v3/strefa/dam-prace.html';
(async()=>{const b=await chromium.launch();
for (const [w,h,m] of [[844,390,true],[568,320,true],[320,256,false],[1024,600,false]]){
 const c=await b.newContext({viewport:{width:w,height:h},isMobile:m,hasTouch:m});const p=await c.newPage();
 await p.goto(BASE+'#oferty');await p.waitForTimeout(200);
 if(!(await p.$eval('#filtry-panel',d=>d.open)))await p.click('#filtry-panel > summary');
 await p.click('#zab-oferty .zab-open');await p.waitForTimeout(300);
 await p.click('#zab-oferty-dlg .zab-grp[data-lista="lista-2"] > summary');
 await p.click('#zab-oferty-dlg .zab-grp[data-lista="lista-2"] label >> nth=0');
 // tab through 12 checkboxes and check obscured by footer
 await p.focus('#zab-oferty-dlg .zab-grp[data-lista="lista-2"] input');let obs=0,max=0;
 for(let i=0;i<14;i++){await p.keyboard.press('Tab');const r=await p.evaluate(()=>{const a=document.activeElement;const r=a.getBoundingClientRect();const f=document.querySelector('#zab-oferty-dlg .zab-sheet-foot').getBoundingClientRect();return {ov:Math.max(0,r.bottom-f.top),foot:f.height}});if(r.ov>0)obs++;max=Math.max(max,r.ov);var fh=r.foot;}
 console.log(w+'x'+h,'foot h',Math.round(fh),'obscured focus',obs,'max px',max, 'docSW',await p.evaluate(()=>document.documentElement.scrollWidth));
 await p.screenshot({path:WYNIKI+`foot-${w}x${h}.png`});
 await c.close();}
 await b.close();})();
