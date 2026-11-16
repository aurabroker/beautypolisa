#!/usr/bin/env node
// Test czystej funkcji wyceny OC (snippets/oc-skladka.js) na fixture kontrola/kalkulator-przypadki.json – bez frameworka.
//   * 49 przypadków (44 porównywalne z CRM, w tym 3 z odstępstwem D45, + 5 stanów interfejsu portalu, tylko_portal): stan,
//     kategoria, nazwa, kwota, tekst i opis w formacie portalu, opis w formacie CRM (opisCrm), powód wyceny indywidualnej,
//     komunikat braku, kafelki sum; pole odstepstwo_D45 – kwota portalu = wynik funkcji, kwota CRM inna, tylko przy połączeniu D45;
//   * 64 kombinacje rodzajów działalności → kategoria według reguły D45 (decyzja zleceniodawcy 16.11.2026; reguła zapisana
//     niżej wprost, niezależnie od oc-skladka.js) = fixture = OcSkladka.kategoria; odstepstwo_D45 dokładnie w 9 połączeniach,
//     w których CRM (kategoriaZRodzajow) daje taryfę kosmetologiczną; grupy T.regula_kategorii – każdy rodzaj w jednej grupie;
//   * 36 kwot taryfy (3 kategorie × 3 sumy × 1–5/6–8 osób × ochrona prawna);
//   * spójność fixture z danymi: nazwy zabiegów z ankiety = pozycje a–h w zabiegi-oc-beauty.json, zabiegi z wyszukiwarki
//     (E1–E4) na wskazanych listach, stałe taryfy-oc-beauty.json użyte przez funkcję.
// Uruchom: node narzedzia/makiety/kontrola/oc/oc-skladka.test.js   (kod wyjścia 1 przy błędzie)
'use strict';
const fs = require('fs');
const path = require('path');

const REPO = path.resolve(__dirname, '../../../..');
const SN = path.join(REPO, 'docs/koncepcja/snippets');
const T = JSON.parse(fs.readFileSync(path.join(SN, 'taryfa-oc-beauty.json'), 'utf8'));
const Z = JSON.parse(fs.readFileSync(path.join(SN, 'zabiegi-oc-beauty.json'), 'utf8'));
const F = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../kalkulator-przypadki.json'), 'utf8'));
const O = require(path.join(SN, 'oc-skladka.js'));

const bledy = [];
let liczba = 0;
function rowne(opis, jest, ma) {
  liczba++;
  if (JSON.stringify(jest) !== JSON.stringify(ma)) bledy.push(`${opis}: jest ${JSON.stringify(jest)}, ma być ${JSON.stringify(ma)}`);
}

// --- mapa a–h z zabiegi-oc-beauty.json (jedno miejsce: pozycje listy „ankieta”) ---
const ankieta = Z.zabiegi
  .flatMap((z) => z.pozycje.filter((p) => p.lista === 'ankieta').map((p) => ({ litera: p.nr, id: z.id, nazwa: z.nazwa })))
  .sort((a, b) => a.litera.localeCompare(b.litera));
rowne('ankieta: litery a–h', ankieta.map((a) => a.litera).join(''), 'abcdefgh');
const nazwyAnkiety = new Set(ankieta.map((a) => a.nazwa));
const naListach = (id) => {
  const z = Z.zabiegi.find((x) => x.id === id);
  return z ? z.pozycje.map((p) => p.lista) : null;
};

// --- reguła kategorii D45 (decyzja zleceniodawcy 16.11.2026) – zapisana tu wprost, bez T.regula_kategorii ---
const LISTA_1 = ['kosmetyczny', 'fryzjerski', 'masaz'], LISTA_2 = ['kosmetologiczny', 'tatuaz'];
function kategoriaD45(rodzaje) {
  if (!rodzaje.length) return null;
  const l1 = rodzaje.some((r) => LISTA_1.includes(r)), l2 = rodzaje.some((r) => LISTA_2.includes(r));
  if (rodzaje.includes('podologiczny') || (l1 && l2)) return 'pelny';
  return l2 ? 'kosmetologiczny' : 'kosmetyczny_fryzjerski';
}
// = kategoriaZRodzajow w CRM (stan przed zmianą D45) – tylko do sprawdzenia oznaczeń odstepstwo_D45
function kategoriaCrm(rodzaje) {
  if (!rodzaje.length) return null;
  const l2 = rodzaje.some((r) => LISTA_2.includes(r));
  if (rodzaje.includes('podologiczny') || (l2 && rodzaje.includes('fryzjerski'))) return 'pelny';
  return l2 ? 'kosmetologiczny' : 'kosmetyczny_fryzjerski';
}
const D45 = (rodzaje) => kategoriaD45(rodzaje) !== kategoriaCrm(rodzaje);
// połączenia D45 słowami: kosmetyczny lub masaż, bez fryzjerskiego i podologicznego, razem z kosmetologicznym lub tatuażem
const D45slowami = (r) => !r.includes('fryzjerski') && !r.includes('podologiczny')
  && (r.includes('kosmetyczny') || r.includes('masaz')) && r.some((x) => LISTA_2.includes(x));
const R = T.regula_kategorii;
rowne('regula_kategorii: grupy = reguła D45', [R.lista_1, R.lista_2, R.zawsze_pelna], [LISTA_1, LISTA_2, ['podologiczny']]);
rowne('regula_kategorii: każdy rodzaj w dokładnie jednej grupie', [...R.lista_1, ...R.lista_2, ...R.zawsze_pelna].sort(),
  T.rodzaje_gabinetu.map((r) => r.klucz).sort());
{
  liczba++;
  try { O.kategoria(['kosmetyczny'], { rodzaje_gabinetu: T.rodzaje_gabinetu }); bledy.push('kategoria bez T.regula_kategorii: brak TypeError'); }
  catch (e) { if (!(e instanceof TypeError)) bledy.push(`kategoria bez T.regula_kategorii: ${e}`); }
}

// --- 49 przypadków ---
let crm = 0, portal = 0, odstepstwa = [];
for (const p of F.przypadki) {
  p.tylko_portal ? portal++ : crm++;
  for (const n of p.zabiegi_ankieta) if (!nazwyAnkiety.has(n)) bledy.push(`${p.id}: „${n}” nie jest pozycją a–h w zabiegi-oc-beauty.json`);
  if (p.ankieta_zaznaczona !== (p.zabiegi_ankieta.length > 0) && !p.oczekiwane.komunikat_ankiety) {
    bledy.push(`${p.id}: ankieta_zaznaczona bez pozycji a–h wymaga oczekiwane.komunikat_ankiety`);
  }
  // „Wykonuję…” bez pozycji a–h przy wyniku (kwota albo wycena indywidualna): przycisk portalu nieaktywny, fokus na pozycji a)
  // (CRM zatrzymuje taki wniosek walidacją – stan.svelte.ts, sprawdzWniosek; weryfikacja, runda 2)
  const bezPozycji = p.ankieta_zaznaczona && p.zabiegi_ankieta.length === 0 && p.oczekiwane.stan !== 'brak';
  rowne(`${p.id} przycisk_portalu tylko przy „Wykonuję…” bez pozycji a–h`, !!p.oczekiwane.przycisk_portalu, bezPozycji);
  if (p.oczekiwane.przycisk_portalu) {
    rowne(`${p.id} przycisk_portalu`, p.oczekiwane.przycisk_portalu,
      { tekst: 'Najpierw zaznacz zabiegi wymagające ankiety', nieaktywny: true, fokus: ankieta[0].id });
  }
  const w = O.skladkaOc(
    { rodzaje: p.rodzaje, osoby: p.osoby, suma: p.suma, ochronaPrawna: p.ochrona_prawna, zabiegiAnkieta: p.zabiegi_ankieta },
    T
  );
  const o = p.oczekiwane;
  rowne(`${p.id} stan`, w.stan, o.stan);
  // odstępstwo od CRM (D45): tylko przy wyniku z kwotą i połączeniu rodzajów, w którym reguły się różnią
  const odst = p.odstepstwo_D45;
  rowne(`${p.id} odstepstwo_D45 tylko przy kwocie i połączeniu D45`, !!odst, !p.tylko_portal && o.stan === 'kwota' && D45(p.rodzaje));
  if (odst) {
    odstepstwa.push(p.id);
    rowne(`${p.id} odstepstwo_D45: kwota portalu = wynik funkcji`, [odst.kwota_portalu, w.kwota], [o.kwota, o.kwota]);
    rowne(`${p.id} odstepstwo_D45: kategoria CRM`, [odst.kategoria_crm, odst.nazwa_crm],
      [kategoriaCrm(p.rodzaje), T.kategorie.find((k) => k.klucz === kategoriaCrm(p.rodzaje)).nazwa]);
    rowne(`${p.id} odstepstwo_D45: kwota CRM ≠ kwota portalu`, odst.kwota_crm !== odst.kwota_portalu, true);
    const wCrm = O.skladkaOc({ rodzaje: ['kosmetologiczny'], osoby: p.osoby, suma: p.suma, ochronaPrawna: p.ochrona_prawna, zabiegiAnkieta: [] }, T);
    rowne(`${p.id} odstepstwo_D45: kwota i opis CRM = taryfa „${odst.nazwa_crm}”`, [odst.kwota_crm, odst.opis_crm], [wCrm.kwota, wCrm.opisCrm]);
  }
  if (o.stan === 'kwota') {
    rowne(`${p.id} kategoria = reguła D45`, w.kategoria, kategoriaD45(p.rodzaje));
    rowne(`${p.id} kategoria`, w.kategoria, o.kategoria);
    rowne(`${p.id} nazwa`, w.nazwa, o.nazwa);
    rowne(`${p.id} kwota`, w.kwota, o.kwota);
    rowne(`${p.id} tekst`, O.formatKwota(w.kwota), o.tekst);
    rowne(`${p.id} opis`, w.opis, o.opis);
    rowne(`${p.id} opisCrm`, w.opisCrm, o.opis_crm);
  } else if (o.stan === 'indywidualna') {
    rowne(`${p.id} powód`, w.powod, o.powod);
  } else {
    rowne(`${p.id} komunikat`, w.komunikat, o.komunikat);
  }
  if (o.komunikat_ankiety) rowne(`${p.id} komunikat ankiety`, T.komunikaty_brakow.ankieta_bez_pozycji, o.komunikat_ankiety);
  if (o.kafelki) {
    for (const s of T.sumy) {
      const k = O.skladkaOc({ rodzaje: p.rodzaje, osoby: p.osoby, suma: s, ochronaPrawna: p.ochrona_prawna, zabiegiAnkieta: p.zabiegi_ankieta }, T);
      rowne(`${p.id} kafelek ${s}`, k.stan === 'kwota' ? O.formatKwota(k.kwota) : k.stan, o.kafelki[String(s)]);
    }
  }
  // Wyszukiwarka: wybór zabiegu z list nr 1 i 2 nie zmienia składki ani rodzajów (P2); z ankiety – zaznacza pozycję a–h.
  const sz = p.wyszukiwarka;
  if (sz) {
    if (sz.wybrano) {
      rowne(`${p.id} wybrany zabieg – listy`, naListach(sz.wybrano), sz.listy);
      const zAnk = ankieta.find((a) => a.id === sz.wybrano);
      if (zAnk) rowne(`${p.id} zabieg z ankiety w zabiegi_ankieta`, p.zabiegi_ankieta.includes(zAnk.nazwa), true);
      else {
        const bez = O.skladkaOc({ rodzaje: p.rodzaje, osoby: p.osoby, suma: p.suma, ochronaPrawna: p.ochrona_prawna, zabiegiAnkieta: [] }, T);
        rowne(`${p.id} wybór z listy nie zmienia składki`, w.kwota, bez.kwota);
      }
    }
    for (const id of sz.podpowiedzi_zawieraja || []) {
      const z = Z.zabiegi.find((x) => x.id === id);
      rowne(`${p.id} podpowiedź ${id} zawiera frazę`, !!z && z.nazwa.toLowerCase().includes(sz.fraza.toLowerCase()), true);
    }
  }
}
rowne('przypadki: porównywalne z CRM / tylko portal', [crm, portal], [44, 5]);
rowne('przypadki tylko_portal = F1–F5', F.przypadki.filter((p) => p.tylko_portal).map((p) => p.id), ['F1', 'F2', 'F3', 'F4', 'F5']);
rowne('przypadki z odstepstwo_D45 (w tym kosmetyczny + kosmetologiczny – uwaga zleceniodawcy 16.11.2026)', odstepstwa, ['A7', 'A11', 'B17']);

// --- 64 kombinacje rodzajów (reguła D45) ---
const klucze = T.rodzaje_gabinetu.map((r) => r.klucz);
const kombinacje = new Set();
const licz = {};
let d45 = 0;
for (const k of F.kombinacje_rodzajow) {
  const opis = k.rodzaje.join('+') || '—';
  kombinacje.add(klucze.map((r) => (k.rodzaje.includes(r) ? 1 : 0)).join(''));
  rowne(`kategoria(${opis}) = reguła D45`, k.kategoria, kategoriaD45(k.rodzaje));
  rowne(`kategoria(${opis})`, O.kategoria(k.rodzaje, T), k.kategoria);
  rowne(`kombinacja ${opis}: odstepstwo_D45 = połączenie D45`, [!!k.odstepstwo_D45, D45(k.rodzaje), D45slowami(k.rodzaje)],
    Array(3).fill(D45(k.rodzaje)));
  if (k.odstepstwo_D45) {
    d45++;
    rowne(`kombinacja ${opis}: CRM – taryfa kosmetologiczna, portal – pełna`, [k.odstepstwo_D45.kategoria_crm, k.kategoria], ['kosmetologiczny', 'pelny']);
  }
  licz[k.kategoria] = (licz[k.kategoria] || 0) + 1;
}
rowne('kombinacje: 64 różne', kombinacje.size, 64);
rowne('kombinacje: liczebność kategorii (D45)', licz, { null: 1, kosmetyczny_fryzjerski: 7, kosmetologiczny: 3, pelny: 53 });
rowne('kombinacje z odstepstwo_D45', d45, 9);
rowne('kosmetyczny + kosmetologiczny → pełna taryfa (decyzja zleceniodawcy 16.11.2026)',
  O.skladkaOc({ rodzaje: ['kosmetyczny', 'kosmetologiczny'], osoby: '1-5', suma: 200000, ochronaPrawna: false, zabiegiAnkieta: [] }, T).kwota, 980);

// --- 36 kwot taryfy ---
const RODZAJ_KAT = { kosmetyczny_fryzjerski: ['kosmetyczny'], kosmetologiczny: ['kosmetologiczny'], pelny: ['podologiczny'] };
const warianty = new Set();
for (const k of F.kwoty_taryfy) {
  warianty.add([k.kategoria, k.suma, k.osoby, k.ochrona_prawna].join('/'));
  const w = O.skladkaOc({ rodzaje: RODZAJ_KAT[k.kategoria], osoby: k.osoby, suma: k.suma, ochronaPrawna: k.ochrona_prawna, zabiegiAnkieta: [] }, T);
  rowne(`kwota ${k.kategoria}/${k.suma}/${k.osoby}/${k.ochrona_prawna ? 'OP' : '-'}`, [w.kategoria, w.kwota], [k.kategoria, k.kwota]);
}
rowne('kwoty: 36 różnych wariantów', warianty.size, 36);

// --- formaty (Q9) i odporność ---
const NB = ' ';
rowne('formatKwota 1279.5', O.formatKwota(1279.5), `1${NB}279,50${NB}zł`);
rowne('formatKwota 1250', O.formatKwota(1250), `1${NB}250,00${NB}zł`);
rowne('formatKwota 987.5', O.formatKwota(987.5), `987,50${NB}zł`);
rowne('formatKwotaCalkowita 1250', O.formatKwotaCalkowita(1250), `1${NB}250${NB}zł`);
rowne('formatSuma 200000', O.formatSuma(200000), `200${NB}tys.${NB}zł`);
rowne('suma jako tekst z formularza', O.skladkaOc({ rodzaje: ['kosmetyczny'], osoby: '1-5', suma: '300000', ochronaPrawna: false, zabiegiAnkieta: [] }, T).kwota, 650);
for (const [opis, odp] of [
  ['nieznany rodzaj', { rodzaje: ['barber'], osoby: '1-5', suma: 100000 }],
  ['nieznana liczba osób', { rodzaje: ['kosmetyczny'], osoby: '2-8', suma: 100000 }],
  ['nieznana suma', { rodzaje: ['kosmetyczny'], osoby: '1-5', suma: 150000 }]
]) {
  liczba++;
  try {
    O.skladkaOc(odp, T);
    bledy.push(`${opis}: brak TypeError`);
  } catch (e) {
    if (!(e instanceof TypeError)) bledy.push(`${opis}: ${e}`);
  }
}

console.log(bledy.length ? bledy.map((b) => 'BŁĄD: ' + b).join('\n') : 'OK');
console.log(`asercji: ${liczba}; przypadki: ${F.przypadki.length} (CRM ${crm}, w tym odstępstwo D45: ${odstepstwa.length}; tylko portal ${portal}); kombinacje: ${F.kombinacje_rodzajow.length} (odstępstwo D45: ${d45}); kwoty: ${F.kwoty_taryfy.length}`);
process.exit(bledy.length ? 1 : 0);
