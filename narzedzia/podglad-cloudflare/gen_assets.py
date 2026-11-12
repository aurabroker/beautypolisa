#!/usr/bin/env python3
# Generuje src/assets.js: mapa ścieżka → (treść, typ) z importami plików z public/ (wrangler: Text/Data).
import pathlib, json
root = pathlib.Path(__file__).parent; pub = root / 'public'
TYPES = {'.html': 'text/html; charset=utf-8', '.css': 'text/css; charset=utf-8', '.txt': 'text/plain; charset=utf-8',
         '.webp': 'image/webp', '.png': 'image/png', '.svg': 'image/svg+xml'}
lines, entries = [], []
for i, p in enumerate(sorted(x for x in pub.rglob('*') if x.is_file())):
    rel = '/' + str(p.relative_to(pub))
    lines.append(f"import a{i} from '../public{rel}';")
    entries.append(f"  {json.dumps(rel)}: [a{i}, {json.dumps(TYPES[p.suffix])}],")
(root / 'src/assets.js').write_text('\n'.join(lines) + '\n\nexport const ASSETS = {\n' + '\n'.join(entries) + '\n};\n')
print(len(entries), 'plików')
