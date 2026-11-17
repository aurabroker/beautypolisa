import pathlib
REPO = str(pathlib.Path(__file__).resolve().parents[4])  # katalog główny repozytorium
import json, re, sys, html
from html.parser import HTMLParser
P=REPO+'/docs/koncepcja/design/v3/oc-beauty.html'
J=REPO+'/docs/koncepcja/snippets/klauzula-ochrona-prawna.json'
src=open(P,encoding='utf-8').read()
k=json.load(open(J,encoding='utf-8'))
# section #ochrona-prawna
m=re.search(r'<section[^>]*id="ochrona-prawna".*?</section>',src,re.S)
sec=m.group(0)
art=re.search(r'<article class="clause".*?</article>',sec,re.S).group(0)
class T(HTMLParser):
    def __init__(s):
        super().__init__(); s.stack=[]; s.title=None; s.items=[]; s.cur=None; s.sub=None; s.depth=0; s.buf=[]; s.mode=None
    def handle_starttag(s,tag,a):
        a=dict(a)
        if tag=='h3' and a.get('id')=='klauzula-tytul': s.mode='title'; s.buf=[]
        elif tag=='ol' and 'clause-text' in (a.get('class') or ''): s.depth=1
        elif s.depth and tag=='li':
            if s.sub is None and s.depth==1:
                s.cur={'tekst':'','wyliczenie':[]}; s.items.append(s.cur); s.mode='li'; s.buf=[]
            else:
                s.mode='subli'; s.buf=[]
        elif s.depth and tag=='ul':
            s.cur['tekst']=''.join(s.buf); s.sub=True; s.mode=None
    def handle_endtag(s,tag):
        if tag=='h3' and s.mode=='title': s.title=''.join(s.buf); s.mode=None
        elif s.depth and tag=='li':
            if s.mode=='subli': s.cur['wyliczenie'].append(''.join(s.buf)); s.mode=None
            elif s.mode=='li': s.cur['tekst']=''.join(s.buf); s.mode=None
        elif s.depth and tag=='ul': s.sub=None
        elif tag=='ol' and s.depth: s.depth=0
    def handle_data(s,d):
        if s.mode in('title','li','subli'): s.buf.append(d)
t=T(); t.feed(art)
def n(x): return re.sub(r'\s+',' ',x).strip()
errs=0
print('tytul HTML == JSON:', n(t.title)==k['tytul'])
if n(t.title)!=k['tytul']: errs+=1; print(repr(n(t.title))); print(repr(k['tytul']))
print('liczba punktow HTML/JSON:',len(t.items),len(k['punkty']))
if len(t.items)!=len(k['punkty']): errs+=1
for i,(h,j) in enumerate(zip(t.items,k['punkty']),1):
    if n(h['tekst'])!=j['tekst']: errs+=1; print('ROZNICA pkt',i); print(' H:',repr(n(h['tekst']))); print(' J:',repr(j['tekst']))
    hw=[n(x) for x in h['wyliczenie']]; jw=j.get('wyliczenie',[])
    if hw!=jw:
        errs+=1; print('ROZNICA wyliczenie pkt',i,len(hw),len(jw))
        for a,b in zip(hw,jw):
            if a!=b: print(' H:',repr(a)); print(' J:',repr(b))
    elif jw: print('pkt',i,'wyliczenie',len(hw),'pozycji OK')
# od 16.11.2026 klauzula ma polską typografię (twarde spacje &nbsp; z narzedzia/makiety/typografia.py – raport 16, 3.1);
# brzmienie porównywane po normalizacji odstępów (\s obejmuje U+00A0); encje inne niż &nbsp; – błąd
inne_encje=[x for x in re.findall(r'&[a-z#0-9]+;',art) if x!='&nbsp;']
print('twarde spacje (&nbsp;) w klauzuli:',art.count('&nbsp;'),'| inne encje:',inne_encje)
if inne_encje: errs+=1
print('ROZNIC:',errs)
