"""Generuje HTML klauzuli ochrony prawnej z snippets/klauzula-ochrona-prawna.json
i wstawia go między znaczniki <!-- gen:klauzula --> … <!-- /gen:klauzula --> w podanych plikach.
Użycie: python3 -I gen_klauzula.py JSON PLIK_HTML [INDENT] [--check]
--check: nic nie zapisuje, kończy się kodem 1, gdy blok w pliku różni się od wygenerowanego.
Dziś: strefa/panel.html (wcięcie domyślne); w makieta-v3.html blok gen:klauzula odświeża gen_kalkulator_dane.py.
Polska typografia (twarde spacje) przy wypisywaniu HTML – typografia.esc(), ta sama funkcja co w gen_kalkulator_dane.py
i gen_oc_beauty.py; JSON i brzmienie bez zmian (raport 16, 3.1)."""
import json, pathlib, re, sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import typografia  # noqa: E402

check = '--check' in sys.argv
args = [a for a in sys.argv[1:] if a != '--check']
src, target = args[0], args[1]
ind = args[2] if len(args) > 2 else '    '
d = json.load(open(src, encoding='utf-8'))
e = typografia.esc
out = [f'{ind}<p class="klauzula-tytul">{e(d["tytul"])}</p>', f'{ind}<ol>']
for p in d['punkty']:
    if p.get('wyliczenie'):
        out.append(f'{ind}  <li>{e(p["tekst"])}')
        out.append(f'{ind}    <ul>')
        out += [f'{ind}      <li>{e(x)}</li>' for x in p['wyliczenie']]
        out.append(f'{ind}    </ul>')
        out.append(f'{ind}  </li>')
    else:
        out.append(f'{ind}  <li>{e(p["tekst"])}</li>')
out.append(f'{ind}</ol>')
block = '\n'.join(out)
s = open(target, encoding='utf-8').read()
pat = re.compile(r'(<!-- gen:klauzula -->\n).*?(<!-- /gen:klauzula -->)', re.S)
assert len(pat.findall(s)) == 1, 'oczekiwano dokładnie jednej pary znaczników'
new = pat.sub(lambda m: m.group(1) + block + '\n' + m.group(2), s)
if check:
    print('OK' if new == s else 'RÓŻNICA – uruchom bez --check')
    sys.exit(0 if new == s else 1)
s = new
open(target, 'w', encoding='utf-8').write(s)
print('OK', target, len(out), 'linii')
