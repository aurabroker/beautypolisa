const { chromium } = require('playwright');
const REPO = require('path').resolve(__dirname, '../../../..');  // katalog główny repozytorium
const BASE='file://' + REPO + '/docs/koncepcja/design/v3/strefa/dam-prace.html';
const fn=(sels)=>{
 const parse=s=>{const m=s.match(/rgba?\(([^)]+)\)/);if(!m)return null;const a=m[1].split(/[ ,\/]+/).filter(Boolean).map(Number);return [a[0],a[1],a[2],a.length>3?a[3]:1]};
 const over=(top,bot)=>{const a=top[3];return [top[0]*a+bot[0]*(1-a),top[1]*a+bot[1]*(1-a),top[2]*a+bot[2]*(1-a),1]};
 const lum=c=>{const f=v=>{v/=255;return v<=.03928?v/12.92:Math.pow((v+.055)/1.055,2.4)};return .2126*f(c[0])+.7152*f(c[1])+.0722*f(c[2])};
 const ratio=(a,b)=>{const l1=lum(a),l2=lum(b);return (Math.max(l1,l2)+.05)/(Math.min(l1,l2)+.05)};
 const bgOf=el=>{const layers=[];let grad=false;for(let n=el;n;n=n.parentElement){const s=getComputedStyle(n);if(s.backgroundImage!=='none'&&!/^url\(.data:image\/svg/.test(s.backgroundImage))grad=n.tagName+'.'+n.className;const c=parse(s.backgroundColor);if(c&&c[3]>0){layers.push(c);if(c[3]>=1)break;}if(n.tagName==='DIALOG'&&n.open)break;}
   let bg=[255,255,255,1];for(let i=layers.length-1;i>=0;i--)bg=over(layers[i],bg);return {bg,grad}};
 return sels.map(sel=>{const els=[...document.querySelectorAll(sel)].filter(e=>e.getClientRects().length);if(!els.length)return {sel,miss:true};const e=els[0];const s=getComputedStyle(e);const {bg,grad}=bgOf(e);let fg=parse(s.color);fg=over(fg,bg);
  return {sel,fs:s.fontSize,fw:s.fontWeight,fg:s.color,bg:bg.map(Math.round).slice(0,3).join(','),ratio:Math.round(ratio(fg,bg)*100)/100,grad:grad||''}});
};
(async()=>{const b=await chromium.launch();
 for(const js of [true,false]){
 const c=await b.newContext({viewport:{width:390,height:844},javaScriptEnabled:js});const p=await c.newPage();
 await p.goto(BASE+(js?'?zabieg=g1-17&zabieg=g2-32#oferty':''));await p.waitForTimeout(200);
 if(js){await p.click('#filtry-panel > summary').catch(()=>{});}
 console.log('\n# JS',js,'– formularz i karty');
 console.log(JSON.stringify(await p.evaluate(fn,['#zab-oferty > legend','#zab-oferty > legend span','#zab-oferty-opis','#zab-oferty .zab-open','#zab-oferty .zab-chip','#zab-oferty .zab-grp-name','#zab-oferty .zab-grp-n','#f-filtry > details > div > p.hint','#lista-ofert .zab-tags li','#lista-ofert .zab-tags li.zab-tags-more','#ofert-liczba','#filtry-aktywne','#f-filtry .check-row span']),null,0).replace(/},{/g,'},\n{'));
 if(js){await p.click('#zab-oferty .zab-open');await p.waitForTimeout(300);await p.click('#zab-oferty-dlg .zab-grp[data-lista="lista-1"] > summary');
  console.log('# okno');
  console.log(JSON.stringify(await p.evaluate(fn,['#zab-oferty-dlg-t','#zab-oferty-dlg .zab-sheet-head p','#zab-oferty-dlg .zab-sheet-search label','#zab-oferty-q-hint','#zab-oferty-dlg .zab-grp-name','#zab-oferty-dlg .zab-grp-n','#zab-oferty-dlg .zab-grp-sel','#zab-oferty-dlg .check-row span','#zab-oferty-dlg .zab-count','#zab-oferty-dlg .zab-clear','#zab-oferty-dlg .zab-done','#zab-oferty-q']),null,0).replace(/},{/g,'},\n{'));
  // nieaktywny przycisk Wyczyść i obramowania (1.4.11)
  const nt=await p.evaluate(()=>{const q=document.getElementById('zab-oferty-q');const s=getComputedStyle(q);const cb=document.querySelector('#zab-oferty-dlg input[name=zabieg]');const cs=getComputedStyle(cb);const cl=document.querySelector('#zab-oferty-dlg .zab-clear');return {inputBorder:s.borderColor+' '+s.borderWidth,inputBg:s.backgroundColor,cbAccent:cs.accentColor,cbSize:cb.getBoundingClientRect().width,clearOpacity:getComputedStyle(cl).opacity,clearColor:getComputedStyle(cl).color,clearDisabled:cl.disabled,closeBtn:(()=>{const x=document.querySelector('#zab-oferty-dlg .drawer-close');const r=x.getBoundingClientRect();return Math.round(r.width)+'x'+Math.round(r.height)+' '+getComputedStyle(x).color+' bg '+getComputedStyle(x).backgroundColor+' border '+getComputedStyle(x).borderColor})()}});
  console.log('# non-text',JSON.stringify(nt));
  await p.locator('#zab-oferty-dlg .zab-grp[data-lista="lista-1"] > summary').focus();
  console.log('# focus summary outline',await p.evaluate(()=>{const s=getComputedStyle(document.activeElement);return s.outlineStyle+' '+s.outlineWidth+' '+s.outlineColor+' offset '+s.outlineOffset}));
  await p.keyboard.press('Tab');
  console.log('# focus checkbox outline',await p.evaluate(()=>{const s=getComputedStyle(document.activeElement);return document.activeElement.value+' '+s.outlineStyle+' '+s.outlineWidth+' '+s.outlineColor+' offset '+s.outlineOffset}));
  await p.keyboard.press('Escape');await p.waitForTimeout(100);
  await p.locator('#zab-oferty .zab-chip').first().focus();
  console.log('# focus chip outline',await p.evaluate(()=>{const s=getComputedStyle(document.activeElement);return s.outlineStyle+' '+s.outlineWidth+' '+s.outlineColor+' offset '+s.outlineOffset}));
 }
 await c.close();}
 await b.close();})();
