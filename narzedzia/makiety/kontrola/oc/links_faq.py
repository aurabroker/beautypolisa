import pathlib
REPO = str(pathlib.Path(__file__).resolve().parents[4])  # katalog główny repozytorium
import re, json, html, sys, os
base=REPO+'/docs/koncepcja/design/v3/'
pages={p:open(base+p,encoding='utf-8').read() for p in ['makieta-v3.html','oc-beauty.html','tax-protect.html','utrata-dochodu.html']}
ids={p:set(re.findall(r'\bid="([^"]+)"',t)) for p,t in pages.items()}
bad=[]
for p,t in pages.items():
    for h in re.findall(r'href="([^"]+)"',t):
        if h.startswith(('http','mailto','tel','/','data:')): continue
        f,_,a=h.partition('#')
        tgt=f or p
        if tgt not in pages:
            if not os.path.exists(base+tgt): bad.append((p,h,'brak pliku'))
            continue
        if a and a not in ids[tgt]: bad.append((p,h,'brak id'))
print('ZLE LINKI:',sorted(set(bad)))
for p in ['makieta-v3.html']:
    print('makieta -> oc-beauty:',sorted(set(re.findall(r'href="(oc-beauty\.html[^"]*)"',pages[p]))))
print('oc -> makieta:',sorted(set(re.findall(r'href="(makieta-v3\.html[^"]*)"',pages['oc-beauty.html']))))
# FAQ compare
t=pages['oc-beauty.html']
blocks=re.findall(r'<script type="application/ld\+json">(.*?)</script>',t,re.S)
faq=None
for b in blocks:
    d=json.loads(b)
    for n in (d.get('@graph',[d]) if isinstance(d,dict) else d):
        if n.get('@type')=='FAQPage': faq=n
snip=json.load(open(REPO+'/docs/koncepcja/snippets/schema-faq-oc-beauty.json',encoding='utf-8'))
a=[(q['name'],q['acceptedAnswer']['text']) for q in faq['mainEntity']]
b=[(q['name'],q['acceptedAnswer']['text']) for q in snip['mainEntity']]
print('FAQ strona',len(a),'snippet',len(b))
for i,(x,y) in enumerate(zip(a,b)):
    if x!=y: print('ROZNICA',i+1,'\n STRONA:',x,'\n SNIPPET:',y)
