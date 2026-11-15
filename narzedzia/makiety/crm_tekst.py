#!/usr/bin/env python3
"""Odczyt stałych programu OC z kodu CRM (crmaura) jako TEKSTU – bez uruchamiania kodu CRM.
Używają go migruj_zabiegi_v2.py, check_zabiegi_pdf.py i check_zgodnosc_crm.py.

Katalog CRM: argument --crm KATALOG, zmienna środowiskowa CRMAURA_DIR albo domyślnie repozytorium „aurabroker”
obok repozytorium portalu (<katalog nadrzędny>/aurabroker/crmaura)."""
import os, pathlib, re

REPO = pathlib.Path(__file__).resolve().parents[2]
PROGRAM = 'src/lib/renewals/program.ts'


def katalog_crm(argv=None):
    argv = list(argv or [])
    if '--crm' in argv:
        return pathlib.Path(argv[argv.index('--crm') + 1]).resolve()
    if os.environ.get('CRMAURA_DIR'):
        return pathlib.Path(os.environ['CRMAURA_DIR']).resolve()
    return REPO.parent / 'aurabroker' / 'crmaura'


def czytaj(crm, sciezka=PROGRAM):
    return (pathlib.Path(crm) / sciezka).read_text(encoding='utf-8')


def _napisy(blok):
    return [re.sub(r"\\(.)", r'\1', s) for s in re.findall(r"'((?:[^'\\]|\\.)*)'", blok)]


def ts_lista(src, nazwa):
    """export const NAZWA = [ '…', … ] as const;  →  lista napisów."""
    m = re.search(r'export const ' + nazwa + r' = \[(.*?)\] as const;', src, re.S)
    if not m:
        raise ValueError('brak listy %s w CRM' % nazwa)
    return _napisy(m.group(1))


def ts_slownik_napisow(src, nazwa):
    """const NAZWA: Record<…> = { '…': '…', … };  →  dict (kolejność z pliku)."""
    m = re.search(r'(?:export )?const ' + nazwa + r'\b[^=]*= \{(.*?)\n\};', src, re.S)
    if not m:
        raise ValueError('brak słownika %s w CRM' % nazwa)
    pary = re.findall(r"'((?:[^'\\]|\\.)*)'\s*:\s*'((?:[^'\\]|\\.)*)'", m.group(1))
    return {re.sub(r"\\(.)", r'\1', a): re.sub(r"\\(.)", r'\1', b) for a, b in pary}


def ts_stala(src, nazwa):
    """export const NAZWA = <liczba albo '…'>;  →  wartość."""
    m = re.search(r'export const ' + nazwa + r'(?::\s*\w+)?\s*=\s*([^;]+);', src)
    if not m:
        raise ValueError('brak stałej %s w CRM' % nazwa)
    v = m.group(1).strip()
    if v.startswith("'"):
        return _napisy(v)[0]
    return float(v) if '.' in v else int(v)


def ts_funkcja(src, nazwa):
    """Treść funkcji `export function nazwa(…) { … }` (do zamykającej klamry w kolumnie 0)."""
    m = re.search(r'^export function ' + nazwa + r'\b.*?^\}', src, re.S | re.M)
    if not m:
        raise ValueError('brak funkcji %s w CRM' % nazwa)
    return m.group(0)


def bez_bialych(s):
    return re.sub(r'\s+', ' ', s).strip()
