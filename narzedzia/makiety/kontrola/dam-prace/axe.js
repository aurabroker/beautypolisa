const { chromium } = require('playwright');
const REPO = require('path').resolve(__dirname, '../../../..');  // katalog główny repozytorium
const AXE=require.resolve('axe-core/axe.min.js');
const BASE='file://' + REPO + '/docs/koncepcja/design/v3/strefa/dam-prace.html';
const run=async(p,label,include)=>{await p.addScriptTag({path:AXE});
  const r=await p.evaluate(async(inc)=>{const res=await axe.run(inc?{include:inc}:document,{runOnly:{type:'tag',values:['wcag2a','wcag2aa','wcag21a','wcag21aa','wcag22aa','best-practice']},resultTypes:['violations','incomplete']});
   const f=v=>v.map(x=>({id:x.id,impact:x.impact,n:x.nodes.length,nodes:x.nodes.slice(0,4).map(n=>n.target.join(' ')+' :: '+(n.failureSummary||'').replace(/\s+/g,' ').slice(0,200))}));
   return {v:f(res.violations),inc:f(res.incomplete.filter(x=>x.id==='color-contrast'))};},include);
  console.log('\n## '+label+' violations:',JSON.stringify(r.v,null,1));
  console.log('## '+label+' color-contrast incomplete:',JSON.stringify(r.inc.map(x=>({n:x.n,nodes:x.nodes.slice(0,4)})),null,1));};
(async()=>{const b=await chromium.launch();
 for(const [w,h,m] of [[1440,900,false],[390,844,true]]){
  const c=await b.newContext({viewport:{width:w,height:h},isMobile:m,hasTouch:m});const p=await c.newPage();
  await p.goto(BASE+'?zabieg=g1-17&zabieg=g2-32#oferty');await p.waitForTimeout(300);
  if(!(await p.$eval('#filtry-panel',d=>d.open)))await p.click('#filtry-panel > summary');
  await run(p,`JS ${w} lista z chipami (sekcja #oferty)`,[['#oferty']]);
  await p.click('#zab-oferty .zab-open');await p.waitForTimeout(300);
  await p.click('#zab-oferty-dlg .zab-grp[data-lista="lista-1"] > summary');await p.click('#zab-oferty-dlg .zab-grp[data-lista="ankieta"] > summary');
  await p.waitForTimeout(100);
  await run(p,`JS ${w} okno otwarte (grupy 1 i 4 rozwinięte)`,[['#zab-oferty-dlg']]);
  await p.fill('#zab-oferty-q','xyz');await p.waitForTimeout(600);
  await run(p,`JS ${w} okno – brak wyników`,[['#zab-oferty-dlg']]);
  await c.close();}
 const c=await b.newContext({viewport:{width:1440,height:900},javaScriptEnabled:false});const p=await c.newPage();
 await p.goto(BASE);await p.click('#zab-oferty .zab-grp[data-lista="lista-1"] > summary');
 // bez JS axe przez addScriptTag nie zadziała (JS off) – osobny kontekst z JS, ale z html bez klasy js? Pomijamy: kontrast w JS-off liczony ręcznie
 await c.close();
 await b.close();})();
