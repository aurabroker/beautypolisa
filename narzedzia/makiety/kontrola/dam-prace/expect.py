import pathlib
REPO = str(pathlib.Path(__file__).resolve().parents[4])  # katalog główny repozytorium
import json, unicodedata, re
d=json.load(open(REPO + '/docs/koncepcja/snippets/zabiegi-oc-beauty.json',encoding='utf-8'))
def norm(s):
    s=s.lower().replace('ł','l'); s=unicodedata.normalize('NFD',s); s=''.join(c for c in s if not unicodedata.combining(c)); return re.sub(r'\s+',' ',s).strip()
out={}
for q in ['wlos','WŁOS','lozysk','łożysk','Masaz','fotoodmladzanie','rzes','RZĘS','rzęs','mezo','peeling','żel','zel','ŁUSZCZ','luszcz','laser','pazn','Paznokc','  tatu  ','xyzxyz','g1-17','oczyszczanie twarzy','ń','ó']:
    t=norm(q); hits=[z['id'] for z in d['zabiegi'] if t in norm(z['nazwa'])] if t else [z['id'] for z in d['zabiegi']]
    out[q]=hits
json.dump(out,open(pathlib.Path(__file__).resolve().with_name('expect.json'),'w'),ensure_ascii=False,indent=0)
for k,v in out.items(): print(repr(k),len(v),v[:8])
