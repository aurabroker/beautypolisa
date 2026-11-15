const { chromium } = require('playwright');
const REPO = require('path').resolve(__dirname, '../../../..');  // katalog główny repozytorium
const BASE='file://' + REPO + '/docs/koncepcja/design/v3/strefa/dam-prace.html';
(async()=>{const b=await chromium.launch();const p=await b.newPage({viewport:{width:1440,height:900}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));p.on('console',m=>{if(m.type()==='error')errs.push(m.text())});
await p.goto(BASE+'#nowe-ogloszenie');await p.waitForTimeout(300);
console.log('duplikaty id:',await p.evaluate(()=>{const c={};document.querySelectorAll('[id]').forEach(e=>c[e.id]=(c[e.id]||0)+1);return Object.entries(c).filter(([k,v])=>v>1)}));
console.log('pickery:',await p.evaluate(()=>[...document.querySelectorAll('[data-zab]')].map(f=>f.id+' mode='+f.dataset.zab+' max='+(f.dataset.zabMax||'-')+' form='+(f.form||f.closest('form')||{}).id)));
const fid=await p.evaluate(()=>[...document.querySelectorAll('[data-zab="field"],[data-zab]:not([data-zab="filter"])')].map(f=>f.id)[0]);
console.log('pole formularza:',fid);
const r=await p.evaluate((fid)=>{const fs=document.getElementById(fid);const boxes=[...fs.querySelectorAll('input[name=zabieg]')];boxes.forEach(b=>b.checked=false);
 for(let i=0;i<30;i++)boxes[i].checked=true;boxes[0].dispatchEvent(new Event('change',{bubbles:true}));
 const dis=boxes.filter(b=>b.disabled).length;const note=fs.querySelector('.zab-limit');const dlg=document.getElementById(fid+'-dlg');
 return {disabled:dis,note:note.hidden?'':note.textContent,count:dlg.querySelector('.zab-count').textContent,done:dlg.querySelector('.zab-done').textContent,chips:fs.querySelectorAll('.zab-chip').length,label:fs.querySelector('legend').textContent.trim()}},fid);
console.log('30 wybranych:',JSON.stringify(r));
console.log('błędy',errs);await b.close();})();
