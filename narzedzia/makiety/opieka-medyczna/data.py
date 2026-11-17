# Dane strony „Opieka medyczna” – przepisane 1:1 z /medical.html (pData, comparisonData, specializations_map).
# Jedno źródło dla tabel statycznych (bez JS), danych dla skryptu i JSON-LD.

PRICES = {  # pData: [Singiel, Partner, Rodzina] zł / miesiąc
    '3-10':  {'enel': [216, 237, 478], 'lux': [131, 234, 347]},
    '11-20': {'enel': [202, 220, 450], 'lux': [124, 220, 327]},
    '21-50': {'enel': [194, 212, 420], 'lux': [120, 212, 314]},
}
TEAMS = [('3-10', '3–10'), ('11-20', '11–20'), ('21-50', '21–50')]
SCOPES = [('singiel', 'Singiel'), ('partner', 'Partner'), ('rodzina', 'Rodzina')]
OPS = {
    'enel': {'brand': 'ENEL-MED', 'legal': 'ENEL-MED S.A.', 'pkg': 'ENEL-MED Standard', 'src': 'ENEL „Pakiet Standard”'},
    'lux':  {'brand': 'LUX MED', 'legal': 'LUX MED sp. z o.o.', 'pkg': 'LUX MED Standard', 'src': 'LuxMed „Opieka Standard” / „Standardowa”'},
}

# comparisonData
PACKAGES = [
    {'id': 'enel-basic', 'op': 'enel', 'name': 'ENEL-MED Basic', 'token': 'Basic',
     'specs': '17 specjalności',
     'specs_list': ["Chirurg", "Ginekolog", "Internista", "Kardiolog", "Laryngolog", "Neurolog", "Okulista", "Pediatra", "Urolog", "Lekarz Rodzinny"],
     'labs': 'Morfologia, mocz, cytologia (1/rok bez skierowania)',
     'diag': 'Audiogram, EKG, RTG klatki i miednicy (podstawowe)',
     'preg': 'Zgodnie z PTG, Karta Przebiegu Ciąży',
     'proc': 'Biopsja zmian skórnych, szycie rany <5 cm, tamponada nosa, iniekcje.',
     'priced': False},
    {'id': 'enel-std', 'op': 'enel', 'name': 'ENEL-MED Standard', 'token': 'Standard',
     'specs': '33 specjalności (brak limitów na skierowania)',
     'specs_list': ["Chirurg", "Ginekolog", "Internista", "Kardiolog", "Laryngolog", "Neurolog", "Okulista", "Pediatra", "Urolog", "Lekarz Rodzinny", "Alergolog", "Chirurg Onkolog", "Dermatolog", "Diabetolog", "Endokrynolog", "Gastrolog", "Hematolog", "Nefrolog", "Ortopeda", "Reumatolog"],
     'labs': 'Ponad 300 badań laboratoryjnych, nielimitowana liczba badań',
     'diag': 'Pełne RTG kostne i diagnostyka obrazowa',
     'preg': 'Kompleksowe prowadzenie (Karta Ciąży), nielimitowane badania',
     'proc': 'Pełen zakres ambulatoryjny Basic + procedury ginekologiczne rozszerzone.',
     'priced': True},
    {'id': 'lux-basic', 'op': 'lux', 'name': 'LUX MED Podstawowa', 'token': 'Podstawowa',
     'specs': '11 specjalności lekarskich',
     'specs_list': ["Internista", "Pediatra", "Lekarz Rodzinny", "Ginekolog", "Okulista", "Chirurg", "Dermatolog"],
     'labs': '52 badania podstawowe (hematologia, analityka)',
     'diag': 'RTG klatki piersiowej, EKG spoczynkowe',
     'preg': 'Opieka podstawowa bez hospitalizacji',
     'proc': 'Podstawowe zabiegi pielęgniarskie, iniekcje, proste opatrunki.',
     'priced': False},
    {'id': 'lux-std', 'op': 'lux', 'name': 'LUX MED Standard', 'token': 'Standardowa',
     'specs': '17 specjalności lekarskich',
     'specs_list': ["Internista", "Pediatra", "Lekarz Rodzinny", "Ginekolog", "Okulista", "Chirurg", "Dermatolog", "Kardiolog", "Laryngolog", "Neurolog", "Ortopeda", "Urolog", "Pulmonolog", "Hematolog", "Lekarz Dyżurny"],
     'labs': '263 badania laboratoryjne (szeroka diagnostyka)',
     'diag': 'Rozszerzone RTG kostne, USG jamy brzusznej',
     'preg': 'Pełny standard opieki zgodnie z Kartą Ciąży',
     'proc': '46 procedur ambulatoryjnych i pielęgniarskich.',
     'priced': True},
]

# specializations_map (kolejność źródła)
SPEC_MAP = [
    ("nefrolog", "Standard / Premium / Prestige", "Rozszerzona / Kompleksowa / Premium"),
    ("audiolog", "Premium / Prestige / VIP", "Premium"),
    ("hepatolog", "Standard / Premium / Prestige", "Podstawowa / Standardowa / Rozszerzona"),
    ("alergolog", "Premium / Prestige / VIP", "Rozszerzona / Kompleksowa"),
    ("neurolog", "Basic / Standard / Premium", "Standardowa / Rozszerzona"),
    ("urolog", "Basic / Standard / Premium", "Rozszerzona / Kompleksowa"),
    ("diabetolog", "Standard / Premium / Prestige", "Rozszerzona / Kompleksowa"),
    ("reumatolog", "Standard / Premium", "Standardowa / Rozszerzona"),
    ("psychiatra", "Premium (3 wizyty)", "Kompleksowa (3 wizyty)"),
    ("ginekolog", "Basic / Standard / Premium", "Podstawowa / Standardowa"),
    ("dermatolog", "Basic / Standard / Premium", "Podstawowa / Standardowa"),
    ("kardiolog", "Basic / Standard / Premium", "Podstawowa / Standardowa"),
    ("onkolog", "Standard / Premium / Prestige", "Rozszerzona / Kompleksowa"),
    ("gastrolog", "Standard / Premium", "Standardowa / Rozszerzona"),
    ("chirurg", "Basic / Standard / Premium", "Podstawowa / Standardowa"),
    ("pediatra", "Basic / Standard / Premium", "Podstawowa / Standardowa"),
    ("foniatra", "Premium / Prestige / VIP", "Rozszerzona / Kompleksowa"),
    ("hematolog", "Premium / Prestige / VIP", "Rozszerzona / Kompleksowa"),
    ("biopsja", "Basic (zmiana skórna)", "Standardowa / Rozszerzona"),
    ("krioterapia", "Basic (nadżerek)", "Standardowa"),
    ("tamponada", "Basic (nosa)", "Standardowa"),
    ("iniekcja", "Basic (dożylna/domięśniowa)", "Podstawowa / Standardowa"),
    ("szycie rany", "Basic (do 5cm)", "Standardowa / Rozszerzona"),
    ("proktolog", "Premium / Prestige / VIP", "Kompleksowa / Premium"),
    ("psycholog", "Premium (pierwszorazowa)", "Standardowa (online) / Rozszerzona"),
]
PROCEDURES = {"biopsja", "krioterapia", "tamponada", "iniekcja", "szycie rany"}

# Polska norma (raport 16, 3.1): nazwy specjalności małą literą w środku listy – w danych źródła były wielkie litery
# („Lekarz Rodzinny”, „Chirurg Onkolog”); pierwszą literę listy w komórce porównania podnosi build.py (cell), a w wierszu „Różnice” – skrypt.
for _p in PACKAGES:
    _p['specs_list'] = [_s.lower() for _s in _p['specs_list']]
