const { chromium } = require('playwright');
const REPO = require('path').resolve(__dirname, '../../../..');  // katalog główny repozytorium
const WYNIKI = require('path').join(__dirname, '../wyniki/oc') + '/';  // zrzuty i wyniki (poza gitem)
require('fs').mkdirSync(WYNIKI, { recursive: true });
const OUT=WYNIKI;
const file='file://' + REPO + '/docs/koncepcja/design/v3/oc-beauty.html';
(async()=>{
  const b=await chromium.launch();
  for (const [w,h] of [[360,780],[390,844],[1440,900]]) {
    const p=await b.newPage({viewport:{width:w,height:h}});
    const errs=[]; p.on('pageerror',e=>errs.push(e.message)); p.on('console',m=>{if(m.type()==='error')errs.push(m.text())});
    await p.goto(file,{waitUntil:'networkidle'});
    const r={w};
    r.ph=await p.locator('#z-szukaj').getAttribute('placeholder');
    const q=async t=>{await p.fill('#z-szukaj',t);await p.waitForTimeout(450);return p.evaluate(()=>({n:[...document.querySelectorAll('.zlist > li')].filter(l=>!l.hidden).map(l=>l.textContent.trim()),cnt:document.getElementById('z-licznik').textContent,nav:document.querySelector('.zjump').hidden,empty:!document.getElementById('z-brak').hidden}))};
    for (const t of ['klamra','manicure','zel','glowy','mezo','mezoterapia','henna','hifu','kobido','żel hybryd']) { const x=await q(t); r[t]=[x.n.length, x.n.slice(0,3), x.nav, x.empty, x.cnt]; }
    await q('klamra'); await p.locator('.ztools').screenshot({path:OUT+`fix-${w}-klamra.png`});
    await q('xyzqq'); r.zeroNavHidden=await p.evaluate(()=>document.querySelector('.zjump').hidden && getComputedStyle(document.querySelector('.zjump')).display); 
    r.cancelBtn=await p.evaluate(()=>getComputedStyle(document.getElementById('z-szukaj'),'::-webkit-search-cancel-button').display);
    await p.fill('#z-szukaj',''); await p.waitForTimeout(100); await p.evaluate(()=>document.getElementById('z-szukaj').dispatchEvent(new Event('input')));
    await p.waitForTimeout(100);
    r.navBack=await p.evaluate(()=>!document.querySelector('.zjump').hidden);
    await p.evaluate(()=>document.querySelectorAll('.zdetails').forEach(d=>d.open=false));
    await p.click('.zjump a[href="#lista-2"]'); await p.waitForTimeout(300);
    r.open2=await p.evaluate(()=>document.querySelector('#lista-2 .zdetails').open);
    r.overflow=await p.evaluate(()=>document.documentElement.scrollWidth-document.documentElement.clientWidth);
    r.small=await p.evaluate(()=>{const o=[];for(const e of document.querySelectorAll('body *')){if(!e.childNodes.length)continue;const has=[...e.childNodes].some(n=>n.nodeType===3&&n.textContent.trim());if(!has)continue;const cs=getComputedStyle(e);if(cs.display==='none'||cs.visibility==='hidden')continue;if(e.closest('.sr-only,[hidden],svg'))continue;const f=parseFloat(cs.fontSize);if(f<12)o.push(e.tagName+'.'+e.className+':'+f)}return o.slice(0,5)});
    r.footerLink=await p.locator('footer a[href="https://beautyrazem.pl/polisa"]').count();
    await p.locator('#taryfa').screenshot({path:OUT+`fix-${w}-taryfa.png`});
    r.thWrap=await p.evaluate(()=>[...document.querySelectorAll('#taryfa thead th')].map(t=>Math.round(t.getBoundingClientRect().height)));
    r.errors=errs;
    console.log(JSON.stringify(r));
    await p.close();
  }
  await b.close();
})();
