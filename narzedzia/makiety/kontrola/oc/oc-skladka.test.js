#!/usr/bin/env node
// Test czystej funkcji wyceny OC (snippets/oc-skladka.js) na fixture kontrola/kalkulator-przypadki.json – bez frameworka.
//   * 49 przypadków (44 porównywalne z CRM + 5 stanów interfejsu portalu, tylko_portal): stan, kategoria, nazwa, kwota,
//     tekst i opis w formacie portalu, opis jak w CRM (opisCrm), powód wyceny indywidualnej, komunikat braku, kafelki sum;
//   * 64 kombinacje rodzajów działalności → kategoria (= kategoriaZRodzajow w CRM);
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

// --- 49 przypadków ---
let crm = 0, portal = 0;
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
  if (o.stan === 'kwota') {
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

// --- 64 kombinacje rodzajów ---
const klucze = T.rodzaje_gabinetu.map((r) => r.klucz);
const kombinacje = new Set();
const licz = {};
for (const k of F.kombinacje_rodzajow) {
  kombinacje.add(klucze.map((r) => (k.rodzaje.includes(r) ? 1 : 0)).join(''));
  rowne(`kategoria(${k.rodzaje.join('+') || '—'})`, O.kategoria(k.rodzaje), k.kategoria);
  licz[k.kategoria] = (licz[k.kategoria] || 0) + 1;
}
rowne('kombinacje: 64 różne', kombinacje.size, 64);
rowne('kombinacje: liczebność kategorii', licz, { null: 1, kosmetyczny_fryzjerski: 7, kosmetologiczny: 12, pelny: 44 });

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
console.log(`asercji: ${liczba}; przypadki: ${F.przypadki.length} (CRM ${crm}, tylko portal ${portal}); kombinacje: ${F.kombinacje_rodzajow.length}; kwoty: ${F.kwoty_taryfy.length}`);
process.exit(bledy.length ? 1 : 0);
