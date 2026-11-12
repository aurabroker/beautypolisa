# 05 · Strategia treści i autorytet tematyczny

> Sekcja koncepcji portalu **beautypolisa.eu**. Fakty o produktach, cenach, konkurencji w SERP i infrastrukturze pochodzą wyłącznie z `01-audyt-stanu-obecnego.md` (składki programu są sztywne – taryfa programu, rozstrzygnięte przez zleceniodawcę 11.11.2026); magazyn treści (MDX/JSON w repozytorium, walidacja Zod, przegląd w PR) i model leada – z `02-architektura-i-bezpieczenstwo.md`; schema, `llms.txt` i dostęp crawlerów AI – z `04-seo-geo-i-schema.md`. Narzędzia keyword research były niedostępne (01, pkt 7), więc każdy wolumen wyszukiwań jest **hipotezą** w skali wysoki / średni / niski. Bez sekretów i identyfikatorów.

## TL;DR

- Hubami są **strony produktowe i kalkulator**, nie osobne „artykuły filarowe”: 6 produktów + 2 filary tematyczne („Prawo, kontrole i bezpieczeństwo w salonie”, „Pracownicy i benefity”), 45 artykułów long-tail w 20 klastrach, 5 treści narzędziowych.
- Największa przewaga: BeautyPolisa będzie **pierwotnym źródłem** dla programu OC ERGO Hestia realizowanego z Fundacją Beauty Razem, czterech grup ryzyka zabiegów i listy zabiegów wysokiego ryzyka (01, pkt 7) – te treści idą pierwsze.
- Kolejność: quick wins w OC i prawie salonowym (tygodnie 1–5), potem Tax Protect i utrata dochodu (sezon styczeń–luty), grupowe i opieka medyczna, NNW dzieci jako evergreen przed wrześniem. Rytm: **2 publikacje + 1 aktualizacja strony produktowej tygodniowo**.
- „Utrata dochodu” i „NNW dzieci” nie mają danych produktowych w audycie – do ich dostarczenia treści są edukacyjne, a strony produktowe działają w trybie „zapytaj o ofertę”.
- YMYL: imienny autor, recenzent z uprawnieniami do dystrybucji ubezpieczeń, data przeglądu, wersja OWU, zastrzeżenie prawne; AI wspiera, nie jest autorem. Metryki jako przedziały [hipoteza], baseline = 0 (apex nie serwuje dziś strony – 01, pkt 6).

---

## Grupa docelowa

Wspólny mianownik: mikroprzedsiębiorca lub mała firma beauty, wysoka ekspozycja na roszczenia z zabiegu, niska znajomość języka ubezpieczeniowego, decyzje „przy okazji” (odnowienie polisy, kontrola, pierwsze roszczenie, nowy pracownik). Portal nie sprzedaje online – każda persona kończy na formularzu leadowym lub `/kalkulator/oc` (01, pkt 8.1). Grupy ryzyka wg cennika kalkulatora (01, pkt 3.1). Produkty w tabelach skrótowo; pełne nazwy: OC dla branży beauty (ERGO Hestia), Tax Protect (Colonnade), Utrata dochodu, NNW dzieci, Grupowe ERGO dla beauty, Opieka medyczna (ENEL-MED / LUX MED).

| Persona | Cele | Obawy | Typowe pytania | Etap zakupu | Produkt główny | Dodatkowe |
|---|---|---|---|---|---|---|
| Właścicielka salonu 1–8 osób | ciągłość biznesu, jedna polisa dla zespołu | roszczenie klientki, kontrola, odejście pracownicy | „czy OC obejmuje pracownice”, „ile kosztuje ubezpieczenie salonu” | rozważanie → decyzja (odnowienie) | OC | Tax Protect, Grupowe ERGO, Opieka medyczna |
| Kosmetolog JDG | bezpiecznie wykonywać zabiegi gr. 2, czasem gr. 4 | powikłanie, brak dochodu w chorobie, granice kompetencji | „oc kosmetologa mezoterapia”, „prywatne L4 na JDG” | świadomość → rozważanie | OC (gr. 2 / 4) | Utrata dochodu, Opieka medyczna, NNW dzieci (jako rodzic) |
| Fryzjer / barber | niska składka, szybka wycena | uczulenie na farbę, choroba zawodowa | „oc fryzjera ile kosztuje” | decyzja (porównuje cenę) | OC (gr. 1) | Utrata dochodu, Grupowe ERGO (gdy zatrudnia) |
| Podolog | ochrona przy pacjencie obciążonym [hipoteza] | rana, zakażenie | „oc podologa” | rozważanie | OC (gr. 3) | Utrata dochodu, Opieka medyczna |
| Linergistka / makijaż permanentny | ochrona przed roszczeniami „estetycznymi” | niezadowolenie z efektu, migracja pigmentu, alergia | „oc linergistki”, „zgoda na makijaż permanentny wzór” | rozważanie → decyzja | OC (gr. 2) | Utrata dochodu, Tax Protect |
| Stylistka paznokci | najtańsze OC, pierwszy kontakt z ubezpieczeniem | uszkodzenie płytki, zakażenie | „czy stylistka paznokci musi mieć oc” | świadomość | OC (gr. 1) | Utrata dochodu, NNW dzieci (jako rodzic) |
| Tatuażysta | OC wymagane przez studio, zgodność z sanepidem | zakażenie, błąd sterylizacji | „oc tatuażysty”, „sanepid studio tatuażu wymagania” | rozważanie | OC (gr. 2) | Tax Protect, Utrata dochodu |
| Trycholog | ochrona przy zabiegach na skórę głowy | zarzut „leczenia bez uprawnień” | „oc trychologa” | świadomość | OC – grupa [hipoteza – do weryfikacji] | Utrata dochodu, Opieka medyczna |
| Manager sieci salonów (> 8 osób) | jedna umowa, benefity obniżające rotację | rotacja, koszty stałe, kontrola PIP | „ubezpieczenie grupowe dla pracowników salonu” | rozważanie → decyzja (budżet XI–XII) | Grupowe ERGO | Opieka medyczna, OC (wycena indywidualna), Tax Protect |

Dwa wymiary przekrojowe. **Rodzic**: pracownice i klientki salonów to w większości osoby w wieku rodzicielskim [założenie]; NNW dzieci jest produktem prywatnym, ale kanał dotarcia jest zawodowy (salon jako miejsce rozmowy, pracodawca jako fundator benefitu) – treści D piszemy do rodzica, dystrybuujemy przez persony 1, 2, 6, 9 i filar H. **JDG**: większość person to jednoosobowa działalność; „Utrata dochodu” dotyczy tej grupy (wg researchu w 01: min. ok. 80 % przychodów z własnej działalności), a niezdolność do pracy, karencja, wyłączenia i koszt podatkowy to pojęcia, o które persona pyta.

---

## Filary i klastry

Hub-and-spoke: **hub = strona produktowa** (`/ubezpieczenia/*`) lub `/kalkulator/oc`, szprychy = artykuły `/baza-wiedzy/<slug>`. Filary G i H mają hub w widoku bazy wiedzy filtrowanym po filarze i w `/dla-kogo/<zawod>`. Nie tworzymy osobnych „pillar pages”, żeby nie kanibalizować stron produktowych na frazach komercyjnych.

```text
A. OC dla branży beauty (ERGO Hestia)   A1 Podstawy OC · A2 Grupy ryzyka (pierwotne źródło) · A3 Wniosek i klauzule · A4 Szkody
B. Tax Protect (Colonnade)               B1 Ochrona karnoskarbowa właściciela (sekcja 1) · B2 Ochrona podatkowa firmy (sekcja 2), kontrole
C. Utrata dochodu                        C1 „Prywatne L4” dla JDG · C2 Pojęcia: niezdolność, karencja, wyłączenia, podatki
D. NNW dzieci                            D1 NNW szkolne a indywidualne (wrzesień) · D2 NNW dziecka jako benefit
E. Grupowe ERGO dla beauty               E1 Grupowe w małym salonie · E2 Moduły MediOpieki, argument anty-rotacyjny
F. Opieka medyczna (ENEL-MED / LUX MED)  F1 Abonament dla zespołu · F2 Abonament dla JDG, medycyna pracy
G. Prawo, kontrole i bezpieczeństwo      G1 Zgoda i dokumentacja · G2 Kontrole · G3 Kompetencje · G4 Reklamacje i odpowiedzialność
H. Pracownicy i benefity                 H1 Zatrudnienie i odpowiedzialność · H2 Benefity, które zatrzymują
```

„Wol.” = wolumen [hipoteza]: W / Ś / N. Intencja: inf., kom., trans., naw. PŹ = pierwotne źródło.

| ID | Tytuł roboczy | Słowo kluczowe [hipoteza] | Wol. | Intencja | Typ |
|---|---|---|---|---|---|
| A1.1 | OC kosmetyczki – zakres i składka | oc kosmetyczki | Ś | inf. / kom. | poradnik + FAQ |
| A1.2 | Ubezpieczenie salonu – co obowiązkowe | ubezpieczenie salonu kosmetycznego | Ś | inf. | przewodnik |
| A1.3 | OC zawodowe a OC działalności | oc zawodowe kosmetologa | N | inf. | wyjaśnienie |
| A1.4 | Suma 100 / 200 / 300 tys. zł – jak dobrać | suma gwarancyjna oc kosmetyczka | N | kom. | poradnik |
| A2.1 | Cztery grupy ryzyka zabiegów – pełna lista | grupy ryzyka zabiegów kosmetycznych ubezpieczenie | N | inf. | tabela (PŹ) |
| A2.2 | Zabiegi wysokiego ryzyka (gr. 4) – ocena indywidualna | oc kosmetologa medycyna estetyczna | Ś | inf. / kom. | opis procesu (PŹ) |
| A2.3 | Quiz „Czy Twoje zabiegi są w grupie ryzyka?” | ubezpieczenie oc zabiegi lista | N | kom. | narzędzie |
| A3.1 | Co przygotować do wniosku (NIP, REGON, szkodowość 3 lat, zabiegi, zgody, kwalifikacje) | wniosek oc kosmetyczka dokumenty | N | trans. | checklista |
| A3.2 | Klauzula ochrony prawnej | ochrona prawna dla kosmetyczki | N | inf. | wyjaśnienie |
| A3.3 | Zespół > 8 osób – wycena indywidualna | oc salon kosmetyczny pracownicy | N | kom. | poradnik |
| A4.1 | Nieudany zabieg – zgłoszenie szkody krok po kroku | odszkodowanie za nieudany zabieg kosmetyczny | W | inf. | poradnik procesowy |
| A4.2 | Poparzenie, uczulenie, migracja pigmentu – scenariusze (hipotetyczne) | roszczenie klientki salon kosmetyczny | N | inf. | studia przypadków |
| B1.1 | Karno-skarbowe dla właściciela – sekcja 1 | ubezpieczenie karno skarbowe | Ś | inf. | wyjaśnienie |
| B2.1 | Kontrola skarbowa w salonie | kontrola skarbowa salon kosmetyczny | N | inf. | poradnik procesowy |
| B2.2 | Kasa fiskalna, terminal, gotówka – ryzyka podatkowe | kasa fiskalna salon kosmetyczny | Ś | inf. | lista ryzyk |
| B2.3 | Sekcja 1 a sekcja 2 (jeden pełny spór w roku) | tax protect colonnade | N (naw.) | kom. | porównanie |
| B2.4 | Z czego składają się koszty sporu podatkowego | koszty sporu podatkowego | N | inf. | wyjaśnienie (składki wg taryfy programu; inne kwoty tylko ze źródłem) |
| C1.1 | „Prywatne L4” dla kosmetyczki na JDG | prywatne l4 jdg | Ś | inf. | przewodnik |
| C1.2 | ZUS chorobowe na JDG a prywatna polisa | chorobowe jdg a ubezpieczenie utraty dochodu | Ś | kom. | porównanie (bez kwot) |
| C1.3 | Choroby zawodowe fryzjerów i kosmetyczek | choroby zawodowe fryzjerów | Ś | inf. | poradnik |
| C1.4 | Kalkulator kosztu dnia przestoju w JDG | ile tracę gdy nie pracuję jdg | N | kom. | narzędzie |
| C2.1 | Niezdolność, karencja, wyłączenia – słownik | ubezpieczenie utraty dochodu wyłączenia | N | inf. | słownik |
| C2.2 | Utrata dochodu a koszt podatkowy – niejednoznaczne interpretacje | ubezpieczenie utraty dochodu koszt podatkowy | N | inf. | wyjaśnienie z zastrzeżeniem |
| D1.1 | NNW szkolne jest dobrowolne – co to znaczy dla rodzica | ubezpieczenie szkolne obowiązkowe czy dobrowolne | W (sezon) | inf. | wyjaśnienie |
| D1.2 | Suma i tabela uszczerbków w NNW dziecka | nnw dziecka jaka suma | Ś | inf. | poradnik |
| D1.3 | NNW całoroczne: wakacje, sport, droga do szkoły | nnw dziecka sport wakacje | Ś | inf. | poradnik |
| D2.1 | NNW dla dzieci pracownic salonu – benefit | nnw dzieci pracowników benefit | N | kom. | poradnik dla pracodawcy |
| E1.1 | Grupowe w małym salonie – od ilu osób | ubezpieczenie grupowe mała firma od ilu osób | Ś | inf. | przewodnik |
| E1.2 | Grupowe na życie a pakiet medyczny (zespół 3–8) | ubezpieczenie grupowe czy pakiet medyczny | N | kom. | porównanie |
| E2.1 | Moduły MediOpieki (assistance, diagnostyka, onkologia, zdrowie psychiczne, tele-EKG, rehabilitacja) | ergo mediopieka | N (naw.) | inf. | opis wg OWU |
| E2.2 | Pakiet zamiast podwyżki – koszt rotacji | koszt rotacji pracownika | N | kom. | poradnik z arkuszem |
| F1.1 | ENEL-MED czy LUX MED dla zespołu | abonament medyczny dla firm porównanie | Ś | kom. | porównanie |
| F1.2 | Medycyna pracy w salonie – obowiązek a benefit | medycyna pracy fryzjer badania | Ś | inf. | wyjaśnienie |
| F2.1 | Pakiet medyczny dla właścicielki na JDG | pakiet medyczny jdg | Ś | kom. | poradnik |
| G1.1 | Zgoda na zabieg – co musi zawierać | zgoda na zabieg kosmetyczny wzór | W | inf. / trans. | poradnik + generator (lead magnet) |
| G1.2 | Karta klienta i wywiad – dokumentacja, która broni | karta klienta kosmetyczka wzór | Ś | inf. | poradnik + szablon |
| G1.3 | Zdjęcia przed/po, zgody marketingowe, RODO | rodo salon kosmetyczny | Ś | inf. | przewodnik |
| G2.1 | Kontrola sanepidu – checklista | kontrola sanepidu salon kosmetyczny | Ś | inf. | checklista (lead magnet) |
| G2.2 | Sterylizacja w tatuażu i podologii | sanepid studio tatuażu wymagania | Ś | inf. | poradnik |
| G3.1 | Kto może wykonywać mezoterapię, lasery, iniekcje | kto może wykonywać mezoterapię igłową | Ś | inf. | wyjaśnienie z zastrzeżeniem |
| G3.2 | Podnajem stanowiska – czyje OC działa | wynajem stanowiska fryzjerskiego odpowiedzialność | N | inf. | poradnik |
| G4.1 | Reklamacja klientki po zabiegu | reklamacja zabiegu kosmetycznego | Ś | inf. | poradnik procesowy |
| H1.1 | Umowa o pracę, zlecenie czy B2B w salonie | zatrudnienie w salonie kosmetycznym umowa | N | inf. | porównanie |
| H2.1 | Jak zatrzymać pracownika w salonie | jak zatrzymać pracownika w salonie | N | inf. | poradnik |
| H2.2 | Benefity w małej firmie beauty | benefity dla pracowników mała firma | Ś | kom. | przewodnik |

Treści narzędziowe (spójne z sekcją 06-… lead magnety i lejki):

| # | Narzędzie | URL | Bramkowanie | Rola |
|---|---|---|---|---|
| 1 | Kalkulator OC (gr. 1–3, sumy 100/200/300 tys. zł, klauzula ochrony prawnej; gr. 4 i > 8 osób → wycena indywidualna) | `/kalkulator/oc` | brak; lead na końcu | główny konwerter |
| 2 | Quiz grup ryzyka (A2.3) | `/baza-wiedzy/quiz-grupy-ryzyka` | brak; wynik → kalkulator z prewypełnioną grupą | kwalifikacja |
| 3 | Generator wzoru zgody na zabieg (G1.1) | `/baza-wiedzy/zgoda-na-zabieg-wzor` | PDF po e-mailu | lead magnet 1 |
| 4 | Checklista kontroli: sanepid / PIP / skarbowa / UODO (G2.1) | `/baza-wiedzy/checklista-kontroli` | online bez bramki, PDF po e-mailu | lead magnet 2 |
| 5 | Kalkulator kosztu przestoju w JDG (C1.4) | `/baza-wiedzy/kalkulator-przestoju` | brak; CTA „zapytaj o ofertę” | edukacja → lead |

Backlog: arkusz „koszt rotacji vs koszt benefitu” (E2.2) – gdy zespół dostarczy źródło liczb z obecnej argumentacji sprzedażowej (01, pkt 3.3).

---

## Analiza luk

| Temat | Co jest dziś (01) | Kto pokrywa w SERP (01, pkt 7) | Luka i szansa |
|---|---|---|---|
| OC beauty – podstawy, cena | kalkulator w `indeksowt.html` / `bp-app.js`, FAQ bez `FAQPage` | CUK, Rankomat, Warta (Studio urody / Ekstrabiznes Plus) | nikt nie opisuje składki wg grup ryzyka ani nie ma kalkulatora z grupami zabiegów |
| Grupy ryzyka, zabiegi wysokiego ryzyka | lista zaszyta w JS, nieindeksowalna | brak publicznych źródeł o programie OC ERGO Hestia dla Beauty Razem | **PŹ**: cytowalna tabela 4 grup i lista gr. 4 z opisem oceny indywidualnej |
| Wniosek (szkodowość, zgody, kwalifikacje) | ankieta PDF (`AnkietaBPEH.pdf`) | brak | checklista przygotowania – unikalna, skraca sprzedaż |
| Szkody, nieudany zabieg | brak | Prawo.pl (perspektywa klientki) | perspektywa salonu: jak zgłosić, dokumentować; powiązanie ze `/szkoda` |
| Zgoda na zabieg | brak | blog Booksy | wzór powiązany z wymaganiami wniosku OC – mocniejszy niż ogólny poradnik |
| Tax Protect | `tax-protect.html`, sekcje 1 i 2, warianty sum; komentarz „DO POTWIERDZENIA” przy składkach w `tax_warianty` jest nieaktualny – składki sztywne wg taryfy programu (rozstrzygnięte 11.11.2026; 01, pkt 3.2) | nisza bez treści dla beauty | kontrola skarbowa, kasa, gotówka w salonie; warianty sum ze składką roczną wg taryfy programu, przychody powyżej 3 mln zł → wycena indywidualna |
| Utrata dochodu | brak danych; wzmianka o Squarelife w `life.html` | Poradnik Przedsiębiorcy, CUK, Firmove, podatki.biz | konkurencja pisze dla „przedsiębiorcy”, my dla JDG w beauty; do czasu oferty – edukacja |
| NNW dzieci | brak danych | Rankomat, Mubi, Portal Oświatowy, PZU Edukacja, InterRisk | nie wygramy ogólnego „nnw dzieci”; wygrywamy kontekst benefitu dla pracownic i rozmowy z klientką we wrześniu |
| Grupowe ERGO | `life.html` / `life1.html`: pakiety, moduły, argument anty-rotacyjny | brak treści dla beauty | rotacja w salonach, pakiet zamiast podwyżki – liczby tylko ze źródłem |
| Opieka medyczna | `medical.html`: cennik programu (abonamenty 131–478 zł/mies.), próg 51+ | operatorzy, porównywarki | zakresy dla zespołu 2–10 osób, medycyna pracy |
| Prawo i kontrole | brak | rozproszone (Booksy, portale prawne) | hub łączący kontrolę z ubezpieczeniem – leady na Tax Protect i OC |

Tam, gdzie jesteśmy pierwotnym źródłem, treść musi być w stu procentach zgodna z OWU – to szansa na cytowalność w AI i obowiązek precyzji (01, pkt 7). Obecna treść jest zaszyta w HTML/JS i zduplikowana (01, pkt 4.8), więc migracja do MDX (02, pkt 2.5) jest pierwszym zadaniem redakcyjnym.

---

## Mapowanie intencji

| Intencja | Przykładowe frazy [hipoteza] | Typ treści | URL docelowy | CTA |
|---|---|---|---|---|
| Nawigacyjna | beautypolisa, aura expert ubezpieczenia beauty, beauty razem ubezpieczenie oc | strona główna, `/o-nas` | `/`, `/o-nas`, `/ubezpieczenia/oc-beauty` | kalkulator / kontakt |
| Informacyjna „co to / jak działa” | oc kosmetyczki, ubezpieczenie karno skarbowe, prywatne l4 jdg | poradnik, wyjaśnienie, słownik | `/baza-wiedzy/<slug>` | link do produktu + zapis na aktualizacje |
| Informacyjna „jak zrobić” | zgoda na zabieg kosmetyczny wzór, kontrola sanepidu salon kosmetyczny | checklista, poradnik procesowy, generator | `/baza-wiedzy/<slug>`, `/szkoda` | lead magnet (PDF za e-mail) |
| Komercyjna – porównanie | ubezpieczenie grupowe czy pakiet medyczny, abonament medyczny dla firm porównanie | porównanie z tabelą | `/baza-wiedzy/<slug>` → `/ubezpieczenia/*` | „zapytaj o ofertę” |
| Komercyjna – dla zawodu | oc kosmetologa, oc fryzjera, oc podologa, oc linergistki, oc tatuażysty | strona persony | `/dla-kogo/<zawod>` | kalkulator z prewypełnioną grupą |
| Transakcyjna | kalkulator oc kosmetyczka, oc kosmetyczki cena | kalkulator, formularz | `/kalkulator/oc`, formularze `/ubezpieczenia/*` | formularz (Turnstile, zgody – 02) |
| Posprzedażowa | zgłoszenie szkody oc kosmetyczka, owu ergo hestia oc beauty | instrukcja, dokumenty | `/szkoda`, `/dokumenty` | zgłoszenie / pobranie OWU |

Zasada: nie piszemy artykułu pod frazę transakcyjną (odpowiada kalkulator lub strona produktowa) i nie budujemy strony produktowej pod frazę informacyjną.

Lista 52 fraz do jednorazowej weryfikacji (Senuto / Semrush), potem GSC jako źródło prawdy; `sledz=1` oznacza 20 fraz śledzonych tygodniowo od startu. Po eksporcie kolejka jest przeliczana raz.

```csv
fraza,filar,wolumen_hipoteza,sledz
oc kosmetyczki,A,sredni,1
ubezpieczenie oc kosmetyczka cena,A,sredni,1
ubezpieczenie salonu kosmetycznego,A,sredni,1
oc kosmetologa,A,sredni,1
oc fryzjera,A,sredni,1
oc fryzjera ile kosztuje,A,niski,0
oc podologa,A,niski,1
oc linergistki,A,niski,1
oc stylistki paznokci,A,niski,0
oc tatuazysty,A,niski,1
oc trychologa,A,niski,0
oc zawodowe kosmetologa,A,niski,0
suma gwarancyjna oc kosmetyczka,A,niski,0
grupy ryzyka zabiegow kosmetycznych ubezpieczenie,A,niski,1
oc kosmetologa medycyna estetyczna,A,sredni,1
ubezpieczenie oc mezoterapia,A,niski,0
odszkodowanie za nieudany zabieg kosmetyczny,A,wysoki,1
roszczenie klientki salon kosmetyczny,A,niski,0
ochrona prawna dla kosmetyczki,A,niski,0
ubezpieczenie karno skarbowe,B,sredni,1
ubezpieczenie karnoskarbowe dla firm,B,niski,0
kontrola skarbowa salon kosmetyczny,B,niski,1
kasa fiskalna salon kosmetyczny,B,sredni,0
koszty sporu podatkowego,B,niski,0
tax protect colonnade,B,niski,0
prywatne l4 jdg,C,sredni,1
ubezpieczenie utraty dochodu,C,sredni,0
ubezpieczenie utraty dochodu wylaczenia,C,niski,0
ubezpieczenie utraty dochodu koszt podatkowy,C,niski,0
chorobowe jdg a ubezpieczenie utraty dochodu,C,sredni,0
choroby zawodowe fryzjerow,C,sredni,1
ubezpieczenie szkolne obowiazkowe czy dobrowolne,D,wysoki,0
nnw dziecka jaka suma,D,sredni,0
nnw dziecka sport wakacje,D,sredni,0
nnw dzieci pracownikow benefit,D,niski,1
ubezpieczenie grupowe mala firma od ilu osob,E,sredni,1
ubezpieczenie grupowe dla pracownikow salonu,E,niski,0
ubezpieczenie grupowe czy pakiet medyczny,E,niski,0
ergo mediopieka,E,niski,0
koszt rotacji pracownika,E,niski,0
abonament medyczny dla firm porownanie,F,sredni,0
pakiet medyczny jdg,F,sredni,0
medycyna pracy fryzjer badania,F,sredni,0
zgoda na zabieg kosmetyczny wzor,G,wysoki,1
karta klienta kosmetyczka wzor,G,sredni,0
rodo salon kosmetyczny,G,sredni,0
kontrola sanepidu salon kosmetyczny,G,sredni,1
sanepid studio tatuazu wymagania,G,sredni,0
kto moze wykonywac mezoterapie iglowa,G,sredni,0
wynajem stanowiska fryzjerskiego odpowiedzialnosc,G,niski,0
reklamacja zabiegu kosmetycznego,G,sredni,0
benefity dla pracownikow mala firma,H,sredni,1
```

---

## Kolejka priorytetów

Kryteria: (1) wartość biznesowa – jak blisko leada jest czytelnik, (2) przewaga pierwotnego źródła, (3) sezon, (4) dopiero potem hipotetyczny wolumen. Quick win = niska konkurencja, wysoka wartość; big bet = wysoki wolumen, konkurencja z dużymi portalami; fill-in = uzupełnienie klastra partiami.

| # | Tytuł roboczy | Słowo kluczowe [hipoteza] | Intencja | Priorytet | Szac. długość | Produkt | Lead magnet / CTA |
|---|---|---|---|---|---|---|---|
| 1 | A2.1 Cztery grupy ryzyka | grupy ryzyka zabiegów kosmetycznych ubezpieczenie | inf. | quick win (PŹ) | 1500–2000 | OC | kalkulator |
| 2 | G1.1 Zgoda na zabieg | zgoda na zabieg kosmetyczny wzór | inf. / trans. | big bet | 1800–2500 | OC (pośrednio) | generator wzoru |
| 3 | A1.1 OC kosmetyczki | oc kosmetyczki | inf. / kom. | big bet | 2000–2500 | OC | kalkulator |
| 4 | A4.1 Zgłoszenie szkody | odszkodowanie za nieudany zabieg kosmetyczny | inf. | big bet | 1800–2200 | OC | `/szkoda` + kalkulator |
| 5 | A2.2 Zabiegi wysokiego ryzyka | oc kosmetologa medycyna estetyczna | inf. / kom. | quick win (PŹ) | 1500–2000 | OC | formularz „wycena indywidualna” |
| 6 | A2.3 Quiz grup ryzyka | ubezpieczenie oc zabiegi lista | kom. | quick win | narzędzie + 600 | OC | wynik → kalkulator |
| 7 | B1.1 Karno-skarbowe właściciela | ubezpieczenie karno skarbowe | inf. | quick win (sezon I–II) | 1500–2000 | Tax Protect | „zapytaj o ofertę” |
| 8 | B2.1 Kontrola skarbowa | kontrola skarbowa salon kosmetyczny | inf. | quick win | 1500–1800 | Tax Protect | checklista kontroli |
| 9 | G2.1 Checklista sanepidu | kontrola sanepidu salon kosmetyczny | inf. | big bet | 1500 + checklista | OC, Tax Protect | checklista kontroli |
| 10 | A1.2 Ubezpieczenie salonu | ubezpieczenie salonu kosmetycznego | inf. | big bet | 2000–2500 | OC, Grupowe ERGO | kalkulator |
| 11 | C1.1 Prywatne L4 dla JDG | prywatne l4 jdg | inf. | quick win (sezon I–II) | 1500–2000 | Utrata dochodu | „zapytaj o ofertę” |
| 12 | B2.2 Ryzyka podatkowe | kasa fiskalna salon kosmetyczny | inf. | fill-in | 1200–1500 | Tax Protect | „zapytaj o ofertę” |
| 13 | A3.1 Co przygotować do wniosku | wniosek oc kosmetyczka dokumenty | trans. | quick win | 1000–1200 | OC | kalkulator → formularz |
| 14 | G1.3 RODO w salonie | rodo salon kosmetyczny | inf. | big bet | 1800–2200 | OC (pośrednio) | zapis na aktualizacje |
| 15 | C1.3 Choroby zawodowe | choroby zawodowe fryzjerów | inf. | quick win | 1500 | Utrata dochodu | kalkulator przestoju |
| 16 | C1.4 Kalkulator przestoju | ile tracę gdy nie pracuję jdg | kom. | quick win | narzędzie + 500 | Utrata dochodu | „zapytaj o ofertę” |
| 17 | E1.1 Grupowe w małym salonie | ubezpieczenie grupowe mała firma od ilu osób | inf. | quick win | 1500–1800 | Grupowe ERGO | „zapytaj o ofertę” |
| 18 | G4.1 Reklamacja klientki | reklamacja zabiegu kosmetycznego | inf. | big bet | 1500–1800 | OC | wzór zgody / `/szkoda` |
| 19 | F1.1 ENEL-MED czy LUX MED | abonament medyczny dla firm porównanie | kom. | fill-in | 1500 | Opieka medyczna | „zapytaj o ofertę” |
| 20 | A3.2 Klauzula ochrony prawnej | ochrona prawna dla kosmetyczki | inf. | fill-in | 900–1200 | OC | kalkulator (opcja klauzuli) |
| 21 | D1.1 NNW szkolne dobrowolne | ubezpieczenie szkolne obowiązkowe czy dobrowolne | inf. | big bet (sezon IX) | 1200–1500 | NNW dzieci | „zapytaj o ofertę” / benefit |
| 22 | C2.2 Koszt podatkowy utraty dochodu | ubezpieczenie utraty dochodu koszt podatkowy | inf. | fill-in | 1000–1200 | Utrata dochodu | „zapytaj o ofertę” |
| 23 | G3.1 Kompetencje do zabiegów | kto może wykonywać mezoterapię igłową | inf. | big bet | 1800–2200 | OC | quiz grup ryzyka |
| 24 | A4.2 Scenariusze roszczeń | roszczenie klientki salon kosmetyczny | inf. | fill-in | 1500 | OC | kalkulator |

Pozostałe 21 artykułów (A1.3, A1.4, A3.3, B2.3, B2.4, C1.2, C2.1, D1.2, D1.3, D2.1, E1.2, E2.1, E2.2, F1.2, F2.1, G1.2, G2.2, G3.2, H1.1, H2.1, H2.2) wchodzi do kolejki po przeliczeniu wolumenów i pierwszych danych GSC (tydzień 10–12), z priorytetem dla sezonów XI–XII (E, F, H) i IX (D).

---

## Kalendarz 12 tygodni

Start w pierwszym pełnym tygodniu po uruchomieniu; przyjęto **styczeń** [założenie] (sezon „nowe polisy i podatki”). Przy innym starcie tygodnie 1–5 zostają (fundament OC + prawo salonowe), a 6–12 przestawia się wg nakładki sezonowej. Zadanie zerowe: migracja treści z `indeksowt.html`, `tax-protect.html`, `life.html`, `medical.html` do MDX z deduplikacją, usunięciem liczb bez źródła i przekierowaniami 301 (02, pkt 7.4; inwentarz w `03-code-review-obecnego-kodu.md`); muszą istnieć strony produktowe, `/kalkulator/oc`, `/dokumenty`, `/szkoda`, `/rodo` i 6 stron `/dla-kogo/*`.

| Tydz. | Publikacja 1 | Publikacja 2 | Aktualizacja strony produktowej / hubu | Uwagi |
|---|---|---|---|---|
| 1 | A2.1 Cztery grupy ryzyka | G1.1 Zgoda na zabieg + generator | `/ubezpieczenia/oc-beauty`: sekcja „grupy ryzyka” → A2.1, FAQ z `FAQPage` | PŹ + lead magnet 1 |
| 2 | A1.1 OC kosmetyczki | B1.1 Karno-skarbowe | `/ubezpieczenia/tax-protect`: sekcje 1 i 2, warianty sum ze składką roczną wg taryfy programu, przychody > 3 mln zł → wycena indywidualna | sezon podatkowy |
| 3 | A4.1 Zgłoszenie szkody | B2.1 Kontrola skarbowa | `/szkoda`: instrukcja, lista dokumentów → A4.1 | |
| 4 | A1.2 Ubezpieczenie salonu | A2.3 Quiz grup ryzyka | `/kalkulator/oc`: wejście z quizu (parametr grupy), opis grup | narzędzie 2 |
| 5 | A2.2 Zabiegi wysokiego ryzyka | G2.1 Checklista kontroli | `/dla-kogo/kosmetolog` → A2.2, quiz, kalkulator | lead magnet 2 |
| 6 | C1.1 Prywatne L4 dla JDG | B2.2 Ryzyka podatkowe | `/ubezpieczenia/utrata-dochodu`: wersja edukacyjna „zapytaj o ofertę” | C bez parametrów produktu |
| 7 | A3.1 Co przygotować do wniosku | G1.3 RODO w salonie | `/dla-kogo/fryzjer`, `/dla-kogo/stylistka-paznokci`: gr. 1 → A1.1, A3.1 | |
| 8 | C1.3 Choroby zawodowe | C1.4 Kalkulator przestoju | `/dokumenty`: OWU z wersjami (Tax Protect 25.01.2023; EZwB 01/25; MediOpieka MA 01/25) | narzędzie 5 |
| 9 | E1.1 Grupowe w małym salonie | G4.1 Reklamacja klientki | `/ubezpieczenia/grupowe-ergo`: pakiety i moduły wg OWU, bez liczb bez źródła | |
| 10 | F1.1 ENEL-MED czy LUX MED | A3.2 Klauzula ochrony prawnej | `/ubezpieczenia/opieka-medyczna`: zakresy, próg 51+, FAQ | przeliczenie kolejki po eksporcie fraz |
| 11 | D1.1 NNW szkolne dobrowolne | C2.2 Koszt podatkowy utraty dochodu | `/ubezpieczenia/nnw-dzieci`: wersja edukacyjna „zapytaj o ofertę” | evergreen przed wrześniem |
| 12 | G3.1 Kompetencje do zabiegów | A4.2 Scenariusze roszczeń | `/dla-kogo/podolog`, `/dla-kogo/linergistka`, `/dla-kogo/tatuazysta` → A2, G | przegląd kwartalny A2.1, A1.1 |

Nakładka sezonowa (niezależna od tygodnia startu):

| Okres | Temat | Treści do publikacji lub odświeżenia | Strona do aktualizacji |
|---|---|---|---|
| styczeń–luty | nowe polisy, zamknięcie roku, podatki | A1.1, A1.4, B1.1, B2.1, B2.2, C1.1, C2.2 | `/ubezpieczenia/oc-beauty`, `/ubezpieczenia/tax-protect`, `/ubezpieczenia/utrata-dochodu` |
| marzec–maj | kontrole, sezon zabiegowy | G2.1, G2.2, G3.1, A2.2, A4.1 | `/kalkulator/oc`, `/szkoda` |
| czerwiec–sierpień | urlopy, przestoje, zdrowie właścicielki | C1.3, C1.4, F2.1, D1.3 | `/ubezpieczenia/opieka-medyczna` |
| wrzesień | NNW dzieci (publikacja 6–8 tyg. wcześniej) | D1.1, D1.2, D2.1 | `/ubezpieczenia/nnw-dzieci` |
| październik | nowi pracownicy | H1.1, G3.2, A3.3 | `/dla-kogo/*` |
| listopad–grudzień | budżety na benefity, grupowe, odnowienia | E1.1, E1.2, E2.1, E2.2, F1.1, H2.1, H2.2 | `/ubezpieczenia/grupowe-ergo`, `/ubezpieczenia/opieka-medyczna` |

---

## Plan linkowania wewnętrznego

Każdy artykuł linkuje „w górę” do huba produktowego i (jeśli dotyczy OC) do `/kalkulator/oc`, „w bok” do 2–3 artykułów z klastra i do jednej strony `/dla-kogo/<zawod>`. Huby linkują „w dół” do 3–6 artykułów w bloku „Przeczytaj, zanim zdecydujesz”. Linki są deklarowane we frontmatter (`product`, `personas`, `related`) i renderowane komponentami – CI sprawdza, że żaden artykuł nie jest sierotą i każdy slug istnieje.

| Hub | Szprychy (linkują do huba) | Hub linkuje do | Przykładowy anchor |
|---|---|---|---|
| `/ubezpieczenia/oc-beauty` | A1.1–A1.4, A2.1, A2.2, A3.1–A3.3, A4.1, A4.2, G1.1, G3.1, G3.2, G4.1 | A1.1, A2.1, A4.1, A3.1, G1.1 | „OC dla branży beauty (ERGO Hestia) – zakres i składki” |
| `/kalkulator/oc` | A1.1, A1.4, A2.1, A2.2, A2.3 (quiz → grupa), A3.1, A3.2, wszystkie `/dla-kogo/*` | A2.1, A1.4 | „sprawdź, w której grupie ryzyka są Twoje zabiegi” |
| `/ubezpieczenia/tax-protect` | B1.1, B2.1–B2.4, G2.1 | B1.1, B2.1, B2.3 | „Tax Protect (Colonnade) – ochrona karnoskarbowa i podatkowa” |
| `/ubezpieczenia/utrata-dochodu` | C1.1–C1.4, C2.1, C2.2, F2.1 | C1.1, C2.1, C1.4 | „ubezpieczenie utraty dochodu dla JDG – zapytaj o ofertę” |
| `/ubezpieczenia/nnw-dzieci` | D1.1–D1.3, D2.1, H2.2 | D1.1, D2.1 | „NNW dzieci – o co zapytać przed wrześniem” |
| `/ubezpieczenia/grupowe-ergo` | E1.1, E1.2, E2.1, E2.2, H2.1, H2.2, D2.1 | E1.1, E2.1, E2.2 | „Grupowe ERGO dla beauty – pakiety dla zespołu” |
| `/ubezpieczenia/opieka-medyczna` | F1.1, F1.2, F2.1, E1.2, H2.2 | F1.1, F2.1 | „Opieka medyczna (ENEL-MED / LUX MED) dla zespołu” |
| `/dla-kogo/<zawod>` (6 stron) | artykuły z `personas` zawierającym zawód | 2–3 artykuły klastra A2 lub G właściwe dla zawodu + kalkulator (np. kosmetolog: A2.1, A2.2, G3.1; fryzjer: A1.1, C1.3) | „OC dla kosmetologa – grupa 2 i zabiegi wysokiego ryzyka” |
| `/szkoda`, `/dokumenty` | A4.1, A4.2, G4.1; każdy artykuł cytujący OWU | A4.1, G1.2 | „OWU Tax Protect (25.01.2023)” |

Zasady: jeden link do tego samego URL w treści akapitowej (reszta w bloku „powiązane”), anchory opisowe, breadcrumbs z `BreadcrumbList` (04, pkt 4.5), brak linków do subdomen `tax.`, `app.`, `crm.` z treści edukacyjnych (01, pkt 8.3). `/dla-kogo/trycholog` i `/dla-kogo/wlasciciel-salonu` [propozycja rozszerzenia konwencji URL] dochodzą po weryfikacji grupy ryzyka i pierwszych danych GSC.

```yaml
# packages/content/baza-wiedzy/grupy-ryzyka-zabiegow.mdx – frontmatter (fragment)
title: "Cztery grupy ryzyka zabiegów w OC beauty – pełna lista"
pillar: A
cluster: A2
product: oc-beauty                 # hub: /ubezpieczenia/oc-beauty
personas: [kosmetolog, linergistka, podolog, tatuazysta]
keyword: "grupy ryzyka zabiegów kosmetycznych ubezpieczenie"   # [hipoteza]
related: [zabiegi-wysokiego-ryzyka, quiz-grupy-ryzyka, suma-gwarancyjna-oc]
cta: calculator                    # calculator | lead-form | lead-magnet:<id> | ask-offer
author: "<imię i nazwisko, rola>"
reviewedBy: "<imię i nazwisko, uprawnienia>"
reviewedAt: 2027-01-XX
updatedAt: 2027-01-XX
owuVersion: "program OC ERGO Hestia nr WA50/003353/24/A"
disclaimer: insurance-general      # insurance-general | tax-legal | income-protection-tax
hypotheticalCases: false
```

Schemat Zod z 02 (`title`, `description`, `product`, `updatedAt`, `reviewedBy`, `owuVersion`) rozszerzamy o `pillar`, `cluster`, `personas`, `keyword`, `related` (2–5 slugów), `cta`, `author`, `reviewedAt`, `disclaimer`, `hypotheticalCases`; reguła: artykuł z `product` innym niż `none` musi mieć `owuVersion`, a brak `reviewedBy` odrzuca PR w CI.

---

## Standardy redakcyjne E-E-A-T dla YMYL

Treści o ubezpieczeniach, podatkach i odpowiedzialności cywilnej są YMYL: błąd kosztuje czytelnika pieniądze, a wydawcę zaufanie i potencjalnie odpowiedzialność z tytułu obowiązków informacyjnych dystrybutora (IDD; status broker vs agent do potwierdzenia – 01, pkt 2). Standardy są warunkiem publikacji.

1. **Imienny autor z opisaną rolą** (bio na `/o-nas`); nie publikujemy pod „Zespół BeautyPolisa”. Treści prawne i podatkowe mają autora lub współautora z kompetencjami w tej dziedzinie.
2. **Recenzent z uprawnieniami do dystrybucji ubezpieczeń** przegląda każdy tekst o zakresie ochrony, wyłączeniach, składkach i szkodach, porównując z OWU; nazwisko i data widoczne pod tytułem (`reviewedBy`, `reviewedAt`).
3. **Wersja OWU i data aktualizacji**: `owuVersion` wskazuje dokument źródłowy (OWU Tax Protect 25.01.2023; EZwB 01/25 i MediOpieka MA 01/25; numer programu OC); `updatedAt` zmienia się tylko przy zmianie merytorycznej.
4. **Źródła**: każda liczba ma źródło – OWU, cennik programu (taryfa) wersjonowany w bazie (02, decyzja 4) lub akt prawny. Liczby bez źródła (koszt rotacji z obecnych stron – 01, pkt 3.3) nie są publikowane. Dane rynkowe spoza oferty (np. przedziały składek NNW z researchu) są opisane jako „orientacyjne dane rynkowe”, nigdy jako nasza oferta.
5. **Zastrzeżenia prawne** w trzech wariantach renderowane z jednego źródła. Projekt wariantu podstawowego:

```text
[projekt – do akceptacji prawnej]
Materiał ma charakter informacyjny i nie stanowi oferty w rozumieniu art. 66 Kodeksu cywilnego,
porady prawnej ani podatkowej. Zakres ochrony, wyłączenia i obowiązki określają wyłącznie Ogólne
Warunki Ubezpieczenia i dokument polisy – przed zawarciem umowy zapoznaj się z OWU na /dokumenty.
Kalkulator pokazuje składkę roczną wg taryfy programu; zabiegi grupy 4 i zespoły od 9 osób wymagają
wyceny indywidualnej (ankieta ERGO Hestii). Dystrybutor: Aura Expert sp. z o.o. – informacje
wymagane ustawą o dystrybucji ubezpieczeń: /o-nas.
```

6. **Zakaz obietnic**: nie piszemy „gwarantujemy wypłatę”, „najtańsze OC”, „pełna ochrona”, „bez wyłączeń”; konkurencję oceniamy tylko przez cytowanie publicznych OWU; nie udzielamy indywidualnych porad podatkowych – przy koszcie podatkowym utraty dochodu opisujemy niejednoznaczność interpretacji (01, pkt 3.5) i odsyłamy do doradcy.
7. **Język prosty**: krótkie zdania, definicja terminu przy pierwszym użyciu (karencja, suma gwarancyjna, franszyza, regres), tabele zamiast wyliczeń, nagłówki-pytania tam, gdzie fraza jest pytaniem.
8. **Hipotetyczne przykłady** (A4.2) wyraźnie oznaczone; realne, zanonimizowane szkody tylko za zgodą zleceniodawcy.
9. **Dostępność**: alt-teksty, hierarchia nagłówków, informacja nie tylko kolorem, tagowane PDF-y – służy też GEO.
10. **Struktura cytowalna (GEO, wzorce z 04, pkt 5.5)**: pierwszy akapit odpowiada na pytanie z tytułu w 2–3 zdaniach, blok „W skrócie” (3–5 punktów), FAQ w naturalnym brzmieniu, tabele z nagłówkami – pod warunkiem odblokowania crawlerów *search* w strefie (01, pkt 6; 04, pkt 5.1).

---

## Proces produkcji

Treść żyje w repozytorium jako MDX i przechodzi przez pull request (02, pkt 2.5) – mechanizm chroniący kod chroni treść YMYL. Czasy to założenia do kalibracji po pierwszym miesiącu.

| Krok | Kto | Wejście → wyjście | Czas [założenie] | Kryterium wyjścia |
|---|---|---|---|---|
| 1. Brief | strateg treści | pozycja z kolejki → fraza, intencja, persona, hub, CTA, pytania do pokrycia (GSC, rozmowy sprzedażowe), źródła OWU | 1 h | zakres zaakceptowany przez recenzenta |
| 2. Szkic | autor (+ AI jako asystent) | brief → szkic MDX z frontmatter, tabelami, FAQ | 1–2 dni | każda liczba ma źródło lub `TODO:źródło` |
| 3. Przegląd merytoryczny | recenzent z uprawnieniami | szkic → uwagi w PR, porównanie z OWU, usunięcie obietnic, wariant zastrzeżenia | 1–2 dni | brak otwartych komentarzy, `reviewedBy` / `reviewedAt` |
| 4. SEO/GEO check | strateg | tytuł, opis, nagłówki, odpowiedź w pierwszym akapicie, FAQ, linki wg planu, schema (04), alt-teksty | 1 h | checklista PR zielona |
| 5. Publikacja | PR → CI → wdrożenie (02, pkt 5) | walidacja Zod, test linków, build; merge = publikacja | automat | CI zielone, podgląd zaakceptowany |
| 6. Po publikacji | strateg | fraza do śledzenia, wpis w metrykach, zgłoszenie URL do indeksacji | 15 min | – |
| 7. Aktualizacja kwartalna | recenzent + strateg | raport GSC (nowe zapytania, spadki), zmiany OWU, cennika, prawa → lista aktualizacji | 1 dzień / kwartał | każdy artykuł produktowy przejrzany min. raz na 12 mies. |

```markdown
## Checklista treści (wymagana do merge)
- [ ] Frontmatter przechodzi walidację (pillar, cluster, product, personas, cta, related 2–5)
- [ ] Każda liczba, limit i próg ma źródło (OWU / cennik z bazy / akt prawny)
- [ ] Recenzent potwierdził zgodność z OWU (`reviewedBy`, `reviewedAt`)
- [ ] Brak sformułowań zakazanych (gwarancja wypłaty, „pełna ochrona”, „najtańsze”, porady indywidualne)
- [ ] Zastrzeżenie w poprawnym wariancie (C2.2 → `income-protection-tax`)
- [ ] Pierwszy akapit odpowiada na pytanie z tytułu; blok „W skrócie”; FAQ 3–6 pytań
- [ ] Linki: hub, kalkulator (jeśli OC), 1 strona /dla-kogo, 2–3 artykuły z klastra
- [ ] Sekcja „Użycie AI”: co wygenerowano, co zweryfikowano ręcznie
```

**Rola AI.** Modele językowe są asystentem w krokach 1, 2 i 4: grupują pytania z GSC w klastry, proponują strukturę, upraszczają język, generują warianty tytułów i FAQ, sprawdzają spójność terminologii. Nie są autorem: nie generują twierdzeń o zakresie ochrony, wyłączeniach, składkach ani przepisach bez dostarczonego źródła, a każdy fragment z modelu weryfikuje człowiek przed przeglądem merytorycznym. Notatka o użyciu zostaje w PR, nie na stronie. Masowe generowanie („codzienna publikacja”) jest poza zakresem: w YMYL koszt jednego błędu przewyższa korzyść z tempa.

---

## Metryki sukcesu

Żadna wartość nie jest prognozą – to przedziały celów do rewizji po pierwszym kwartale danych. Baseline wynosi zero: apex `beautypolisa.eu` nie serwuje strony (01, pkt 6), `.com` nie była osiągalna, a audyt nie znalazł publicznych źródeł ani cytowań dotyczących programu OC (01, pkt 7).

| Metryka | Źródło | Cel 3 mies. [hipoteza] | Cel 6 mies. [hipoteza] | Cel 12 mies. [hipoteza] |
|---|---|---|---|---|
| Zaindeksowane URL bazy wiedzy | GSC | 20–25 (wszystkie opublikowane) | 35–45 | 55–70 |
| Frazy śledzone (20, `sledz=1`) w top 10 | GSC / Senuto | 2–5 (long-tail PŹ) | 6–10 | 12–16 |
| Kliknięcia organiczne na bazę wiedzy | GSC | trend rosnący m/m | ×2–3 vs mies. 3 | ×2 vs mies. 6 |
| Udział leadów z pierwszą stroną wejścia w bazie wiedzy lub `/dla-kogo/*` | tabela leadów z atrybucją (strona wejścia, UTM – 02) | mierzone | 20–35 % | 30–50 % |
| Przejścia artykuł → kalkulator; ukończenia kalkulatora | zdarzenia first-party (kolektor Aura – 02) | CTR 5–10 % | 8–15 % | optymalizacja CTA |
| Pobrania lead magnetów | tabela subskrybentów / zdarzenia | mierzone | 1 pobranie na 20–40 odsłon artykułu-nośnika | j.w. |
| Cytowania w AI (ChatGPT, Perplexity, AI Overviews, Claude) | ręczny audyt promptów co miesiąc (lista 20 w 04, pkt 5.8; 8 promptów treściowych poniżej) | 0–2 prompty z cytowaniem (po odblokowaniu crawlerów) | 3–5 | 5–8 |
| Artykuły z aktualnym przeglądem (≤ 12 mies.) | frontmatter → raport CI | 100 % | 100 % | 100 % |
| Produkcja wg kalendarza | repozytorium | 24 publikacje + 12 aktualizacji | – | – |

```text
Prompty treściowe do audytu cytowań (uzupełnienie listy z 04; zapis: domena, URL, zgodność z treścią)
1. Jakie OC powinna mieć kosmetyczka w Polsce i ile kosztuje?
2. Jakie zabiegi kosmetyczne ubezpieczyciele uznają za wysokiego ryzyka?
3. Co powinna zawierać zgoda na zabieg kosmetyczny?
4. Jak zgłosić szkodę z OC po nieudanym zabiegu w salonie?
5. Co to jest ubezpieczenie karno-skarbowe i kto go potrzebuje?
6. Jak działa ubezpieczenie utraty dochodu dla osoby na JDG?
7. Od ilu pracowników można kupić ubezpieczenie grupowe w salonie?
8. Program OC dla branży beauty Beauty Razem – co obejmuje?
```

Warunek wstępny dla cytowań: zmiana bot managementu w strefie (dziś blokada wszystkich crawlerów AI, w tym *search* – 01, pkt 6), opisana w 04 (pkt 5.1) i w pytaniu 10 sekcji 02. Bez niej metryka zostaje na zerze niezależnie od jakości treści.

---

## Decyzje

1. **Huby = strony produktowe i kalkulator; baza wiedzy to szprychy.** Fraza komercyjna ma jedno miejsce docelowe, strona produktowa zyskuje linki i treść pomocniczą. Odrzucone: „pillar pages” w bazie wiedzy (dublują intencję stron produktowych), blog bez struktury.
2. **Pierwsze pięć tygodni to klaster OC + prawo salonowe.** Tam jest przewaga pierwotnego źródła i jedyny produkt z kalkulatorem taryfy programu (grupy ryzyka × sumy gwarancyjne). Odrzucone: start od sześciu produktów naraz (rozproszenie, brak danych dla dwóch).
3. **Wolumeny jako hipotezy w trzech progach, jednorazowa weryfikacja 52 fraz, potem GSC jako źródło prawdy.** Narzędzia były niedostępne (01, pkt 7); w niszy dane GSC po 2–3 miesiącach będą wiarygodniejsze niż estymaty. Odrzucone: czekanie na narzędzia, publikacja bez weryfikacji.
4. **Rytm 2 publikacje + 1 aktualizacja huba tygodniowo, produkcja w dwutygodniowych partiach.** Wystarcza do zbudowania klastra OC w kwartał przy zespole 1 autor + 1 recenzent. Odrzucone: 1/tydz. (klaster w pół roku), codzienne publikacje AI (ryzyko YMYL, obciążenie recenzenta).
5. **Pięć treści narzędziowych, bramka e-mailowa tylko dla wzoru zgody i checklisty kontroli.** Quiz i kalkulatory bez bramki zbierają linki i prowadzą do kalkulatora OC. Odrzucone: bramkowanie wszystkiego (spadek zasięgu), brak bramek (brak bazy do nurture – 06-…).
6. **Imienny autor i recenzent z uprawnieniami.** YMYL i obowiązki dystrybutora; E-E-A-T to weryfikowalne osoby. Odrzucone: podpis „Zespół BeautyPolisa”, recenzja wyłącznie redakcyjna.
7. **AI jako asystent z notatką w PR; zero generowania faktów o OWU.** Największe ryzyko to zmyślone wyłączenie lub limit. Odrzucone: AI jako autor pierwszej wersji z „ludzkim przeglądem”, publiczne oznaczanie „wspomagane AI”.
8. **MDX w repozytorium, publikacja przez PR z walidacją Zod i testem linków** – spójnie z 02 (decyzja 6). Odrzucone: CMS, dokumenty Google jako źródło prawdy.
9. **„Utrata dochodu” i „NNW dzieci” – edukacja i „zapytaj o ofertę” do czasu dostarczenia produktu.** Publikowanie parametrów rynkowych jako własnych naruszałoby E-E-A-T. Odrzucone: wstrzymanie filarów (strata sezonów), orientacyjne ceny jako oferta.
10. **Nakładka sezonowa zamiast dat dziennych; sześć stron `/dla-kogo/*` na start, trycholog i właścicielka salonu po weryfikacji.** Data startu nieznana, sezony stałe; dla trychologa brak grupy ryzyka w cenniku z audytu. Odrzucone: kalendarz z datami, strona persony z „wyceną indywidualną” jako zastępnikiem.

## Pytania otwarte do zleceniodawcy

1. Kto będzie imiennym autorem, a kto recenzentem z uprawnieniami do dystrybucji ubezpieczeń? Jaki jest potwierdzony status dystrybutora (broker vs agent) – wpływa na zastrzeżenia i stopki (01, pkt 2)?
2. Czy ERGO Hestia i Fundacja Beauty Razem wymagają akceptacji materiałów o programie OC (numer, logo, zasady grup ryzyka) przed publikacją? Tryb i czas akceptacji wpływają na SLA kroku 3.
3. Czy lista zabiegów w grupach 1–4 z kalkulatora (01, pkt 3.1) jest kompletna i może być opublikowana jako „pełna lista”? Do której grupy należą zabiegi trychologiczne i inne nieobecne na liście?
4. Kiedy zespół produktowy dostarczy parametry „Utrata dochodu” i „NNW dzieci” (ubezpieczyciel, definicje, karencje, sumy)? Czy tryb „zapytaj o ofertę” do tego czasu jest akceptowalny?
5. Rozstrzygnięte 11.11.2026 (pytanie 7 sekcji 02): składki Tax Protect są sztywne (taryfa programu) – B2.3, B2.4 i `/ubezpieczenia/tax-protect` podają składkę roczną wg taryfy (wartości z `tax_warianty` lub od zleceniodawcy); przychody powyżej 3 mln zł → wycena indywidualna.
6. Czy liczby z obecnej argumentacji grupowego (koszt rotacji, pakiet zamiast podwyżki – 01, pkt 3.3) mają cytowalne źródło? Bez niego znikają z treści.
7. Czy zleceniodawca udostępni jednorazowy eksport z Senuto lub Semrush dla 52 fraz oraz dostęp do GSC po uruchomieniu?
8. Czy można dopuścić crawlery AI kategorii *search* i *user* przy utrzymaniu blokady *training* (01, pkt 6; 04, pkt 5.1)? Bez tego metryka cytowań nie ma sensu.
9. Kto zatwierdza prawnie wzór zgody na zabieg i checklistę kontroli (dokumenty stosowane przez klientów w praktyce) i czy Aura Expert akceptuje wydawanie ich pod swoją marką? Czy w A4.2 możemy użyć zanonimizowanych realnych szkód z praktyki Aura?
10. Czy newsletter (nurture po pobraniu lead magnetu) jest w zakresie v1 i kto odpowiada za treść zgód marketingowych (02 – zgody wersjonowane; 06-… – lejek)?
11. Jakie zasoby redakcyjne są dostępne (autor wewnętrzny czy zewnętrzny, godziny recenzenta tygodniowo)? Od tego zależy, czy rytm 2 + 1 jest realny, czy startujemy od 1 + 1.
