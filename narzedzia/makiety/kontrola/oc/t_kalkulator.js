#!/usr/bin/env node
// Kalkulator OC na makieta-v3.html przez interfejs (Playwright) – fixture kontrola/kalkulator-przypadki.json (plan „OC beauty
// po Aneksie nr 5”, rozdz. 7 i 8; krok 4).
//   * 49 przypadków: 44 porównywalne z CRM (A–E, wynik policzony regułami CRM z kategorią taryfy według decyzji D45 – w A7, A11
//     i B17 odstępstwo od CRM oznaczone odstepstwo_D45: strona pokazuje kwotę portalu, nie kwotę CRM) + 5 stanów interfejsu
//     portalu (F1–F5, tylko_portal).
//     Dla każdego: świeża strona, pola ustawione kliknięciami (rodzaje, osoby, suma, ochrona prawna, „Wykonuję zabiegi wymagające
//     ankiety…” i pozycje a–h, wyszukiwarka), potem porównanie: #taryfa, #cena (tekst z twardymi spacjami, jak w fixture), #cena-dop,
//     #cena-opis, druga linia kafelków sum, zdanie pod kafelkami, przycisk (tekst, aria-disabled), komunikat przy pozycjach a–h,
//     pola #lead i zdanie #kontakt-wynik po kliknięciu przycisku (albo fokus na brakującym polu, gdy przycisk jest nieaktywny).
//     Kwoty kafelków i opis wyceny indywidualnej liczone tu niezależnie od snippets/oc-skladka.js – z kwot taryfy w fixture.
//   * „Dla kogo” (decyzja zleceniodawcy 14.11.2026): kafelek profilu zaznacza rodzaj działalności – linergistka i kosmetolog →
//     Gabinet kosmetologiczny, stylistka paznokci → Gabinet kosmetyczny, fryzjer i barber → Salon fryzjerski, podolog → Gabinet
//     podologiczny, tatuażysta → Salon tatuażu, trycholog → Gabinet kosmetyczny, masażysta → Salon masażu (dwa ostatnie – uwagi
//     zleceniodawcy 16.11.2026, 00 D46 e); kwota przy do 5 osobach i 200 tys. zł z fixture; dwa profile – rodzaje się sumują;
//     kosmetolog + stylistka paznokci (gabinet kosmetologiczny + gabinet kosmetyczny) → pełna taryfa, 980,00 zł (D45, 16.11.2026);
//     trycholog i masażysta – podstawowa taryfa „Gabinety kosmetyczne i fryzjerskie”, 500,00 zł, także razem (oczekiwania wpisane wprost).
//   * stan startowy (z JS i bez JS): żadne pole kalkulatora nie jest zaznaczone, brak kwoty, brak plakietek przy sumach.
//   * zmiany po kliknięciu przycisku (weryfikacja, runda 1): pola #lead i zdanie #kontakt-wynik idą za kalkulatorem (ankieta, suma,
//     ochrona prawna, chip w wyszukiwarce), stan „brak” je czyści i wyłącza; bez przycisku kalkulatora pola OC nie idą z formularzem
//     (02: LeadInput.calc opcjonalne), także przy temacie z adresu ?produkt=oc-beauty. Runda 2: powiązanie z kalkulatorem trwa po
//     stanie „brak” (zmiana jedynego rodzaju działalności – lead z nowym wynikiem); „Wykonuję…” bez pozycji a–h (D4, oczekiwane.
//     przycisk_portalu) – przycisk nieaktywny, fokus na pozycji a), lead bez wyniku; przycisk Tax Protect przejmuje formularz.
// Uruchom: node narzedzia/makiety/kontrola/oc/t_kalkulator.js   (kod wyjścia 1 przy błędzie; wymaga npm install w narzedzia/makiety)
'use strict';
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const REPO = path.resolve(__dirname, '../../../..');
const SN = path.join(REPO, 'docs/koncepcja/snippets');
// MAKIETA=<ścieżka> – inna kopia strony (np. test mutacyjny); domyślnie makieta z repozytorium
const PAGE = 'file://' + (process.env.MAKIETA ? path.resolve(process.env.MAKIETA) : path.join(REPO, 'docs/koncepcja/design/v3/makieta-v3.html'));
const F = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../kalkulator-przypadki.json'), 'utf8'));
const T = JSON.parse(fs.readFileSync(path.join(SN, 'taryfa-oc-beauty.json'), 'utf8'));
const Z = JSON.parse(fs.readFileSync(path.join(SN, 'zabiegi-oc-beauty.json'), 'utf8'));
const NB = ' ';

// --- dane pomocnicze z plików (nie z kodu strony) ---
const ANKIETA_ID = {};  // dosłowna nazwa CRM (fixture) → id g4-xx (mapa a–h w zabiegi-oc-beauty.json, pozycje[].nr)
for (const z of Z.zabiegi) for (const p of z.pozycje) if (p.lista === 'ankieta') ANKIETA_ID[z.nazwa] = z.id;
const KAT_RODZAJOW = new Map(F.kombinacje_rodzajow.map((x) => [[...x.rodzaje].sort().join(','), x.kategoria]));
const NAZWA_KAT = Object.fromEntries(T.kategorie.map((k) => [k.klucz, k.nazwa]));
const OSOBY_ID = { '1-5': '#o-1-5', '6-8': '#o-6-8', '9+': '#o-9-plus' };
function kwotaTaryfy(kat, suma, osoby, op) {
  const x = F.kwoty_taryfy.find((k) => k.kategoria === kat && k.suma === suma && k.osoby === osoby && k.ochrona_prawna === op);
  if (!x) throw new Error('brak kwoty w fixture: ' + [kat, suma, osoby, op]);
  return x.kwota;
}
// format portalu (decyzja Q9): zawsze z groszami, separator tysięcy i spacja przed „zł” twarde – niezależnie od oc-skladka.js
function zl(k) {
  const gr = Math.round(k * 100), c = String(Math.floor(gr / 100)), g = String(gr % 100).padStart(2, '0');
  return c.replace(/\B(?=(\d{3})+(?!\d))/g, NB) + ',' + g + NB + 'zł';
}
const sp = (s) => String(s == null ? '' : s).replace(/ /g, ' ').replace(/\s+/g, ' ').trim();
function kafelkiOczekiwane(c) {
  const out = {};
  const ankieta = c.ankieta_zaznaczona && c.zabiegi_ankieta.length > 0;
  const kat = KAT_RODZAJOW.get([...c.rodzaje].sort().join(','));
  for (const s of T.sumy) {
    if (ankieta) out[s] = 'składka do wyceny';
    else if (!kat || !c.osoby) out[s] = '';
    else if (c.osoby === '9+') out[s] = 'składka do wyceny';
    else out[s] = zl(kwotaTaryfy(kat, s, c.osoby, c.ochrona_prawna)) + ' rocznie';
  }
  if (c.oczekiwane.kafelki) for (const [s, t] of Object.entries(c.oczekiwane.kafelki)) {
    if (sp(out[s]) !== sp(t + ' rocznie')) throw new Error(`${c.id}: kafelek ${s} w fixture ${t} ≠ kwota taryfy ${out[s]}`);
  }
  return out;
}

const bledy = [];
let asercje = 0;
function rowne(opis, jest, ma) {
  asercje++;
  if (JSON.stringify(jest) !== JSON.stringify(ma)) bledy.push(`${opis}: jest ${JSON.stringify(jest)}, ma być ${JSON.stringify(ma)}`);
}

async function stan(p) {
  return p.evaluate(() => {
    const $ = (id) => document.getElementById(id);
    const f = $('lead').elements;
    const cta = $('cta-oferta');
    return {
      taryfa: $('taryfa-blok').hidden ? null : $('taryfa').textContent.replace(/\u00a0/g, ' '),   // nazwa z twardymi spacjami (tw) – porównanie jak spacja
      cena: $('cena').textContent, dop: $('cena-dop').textContent,
      opis: $('cena-opis').hidden ? null : $('cena-opis').textContent,
      cta: cta.textContent, ctaDis: cta.getAttribute('aria-disabled') === 'true',
      kafelki: Object.fromEntries([...document.querySelectorAll('[id^="kw-"]')].map((x) => [x.id.slice(3), x.textContent])),
      nota: $('suma-nota').textContent,
      ankietaBrak: $('ankieta-brak').hidden ? null : $('ankieta-brak').textContent,
      ankietaInfo: !$('ankieta-info').hidden,
      calcAnkieta: !$('calc-ankieta').hidden,
      rodzaje: [...document.querySelectorAll('input[name="rodzaj"]:checked')].map((i) => i.value),
      ankieta: [...document.querySelectorAll('input[name="ankieta"]:checked')].map((i) => i.value),
      ankietaTak: $('ankieta').checked,
      chips: [...document.querySelectorAll('.zab-chip')].map((c) => c.dataset.id),
      lead: { rodzaje: f.rodzaje.value, osoby: f.osoby.value, suma: f.suma.value, prawna: f.prawna.value, ankieta: f.ankieta.value, zabiegi: f.zabiegi.value },
      wynikKontakt: $('kontakt-wynik').hidden ? null : $('kontakt-wynik').textContent,
      fokus: document.activeElement && document.activeElement.id,
      // P9: bez plakietek i bez wyróżnienia wariantu
      plakietka: /najczęściej wybier|polecan|rekomend/i.test(document.getElementById('kalkulator-oc').textContent),
    };
  });
}

async function przypadek(b, c) {
  const p = await b.newPage({ viewport: { width: 1280, height: 900 }, reducedMotion: 'reduce' });
  const errs = [];
  p.on('pageerror', (e) => errs.push(e.message));
  // błędy skryptu strony; brak zasobu (obraz, czcionka) przy kopii strony poza repozytorium – pomijany
  p.on('console', (m) => { if (m.type() === 'error' && !/Failed to load resource/.test(m.text())) errs.push(m.text()); });
  await p.goto(PAGE, { waitUntil: 'load' });
  const id = c.id;
  for (const r of c.rodzaje) await p.check('#r-' + r);
  if (c.osoby) await p.check(OSOBY_ID[c.osoby]);
  if (c.suma) await p.check('#s-' + c.suma);
  if (c.ochrona_prawna) await p.check('#prawna');
  const w = c.wyszukiwarka;
  const przezWyszukiwarke = w && w.wybrano && w.listy[0] === 'ankieta' ? w.wybrano : null;
  if (w) {
    const przed = await stan(p);
    await p.fill('#zab-q', w.fraza);
    await p.waitForSelector('#zab-lista [role="option"]');
    const opcje = await p.$$eval('#zab-lista [role="option"]', (l) => l.map((x) => x.id.replace('zab-opt-', '')));
    for (const z of w.podpowiedzi_zawieraja || []) rowne(`${id}: podpowiedzi zawierają ${z}`, opcje.includes(z), true);
    if (w.wybrano) {
      rowne(`${id}: podpowiedzi zawierają ${w.wybrano}`, opcje.includes(w.wybrano), true);
      const plak = (await p.textContent(`#zab-opt-${w.wybrano} .zab-badge`)).replace(/\u00a0/g, ' ');  // twarda spacja = spacja (runda 2: „nr\u00a01”)
      const plakMa = w.listy[0] === 'ankieta' ? null : w.listy.length > 1 ? 'Listy nr 1 i 2' : 'Lista nr ' + w.listy[0].slice(-1);
      if (plakMa) rowne(`${id}: plakietka podpowiedzi`, plak, plakMa);
      else rowne(`${id}: plakietka podpowiedzi (ankieta, pozycja)`, /^Ankieta, poz\. [a-h]\)$/.test(plak), true);
      await p.click('#zab-opt-' + w.wybrano);
      const po = await stan(p);
      if (!przezWyszukiwarke) {
        // P2: wybór zabiegu z list nr 1 i 2 nie zmienia rodzajów ani składki; trafia do „Wybranych zabiegów”
        rowne(`${id}: wyszukiwarka nie zmienia rodzajów`, po.rodzaje, przed.rodzaje);
        rowne(`${id}: wyszukiwarka nie zmienia składki`, po.cena, przed.cena);
        rowne(`${id}: chip wybranego zabiegu`, po.chips, [w.wybrano]);
      } else {
        rowne(`${id}: wybór pozycji a–h zaznacza „Wykonuję…”`, po.ankietaTak, true);
        rowne(`${id}: wybór pozycji a–h zaznacza tę pozycję`, po.ankieta, [przezWyszukiwarke]);
        rowne(`${id}: pozycja a–h bez chipa`, po.chips, []);
      }
    }
  }
  if (c.ankieta_zaznaczona && !przezWyszukiwarke) {
    await p.check('#ankieta');
    for (const n of c.zabiegi_ankieta) {
      if (!ANKIETA_ID[n]) throw new Error(`${id}: nazwa spoza ankiety a–h: ${n}`);
      await p.check('#' + ANKIETA_ID[n]);
    }
  }
  await p.waitForTimeout(50);
  const s = await stan(p);
  const o = c.oczekiwane;
  const kat = KAT_RODZAJOW.get([...c.rodzaje].sort().join(','));
  // „Wykonuję…” bez pozycji a–h (D4): kwota bez zmian, przycisk nieaktywny – jak walidacja wniosku w CRM
  const przycisk = o.przycisk_portalu ? [o.przycisk_portalu.tekst, o.przycisk_portalu.nieaktywny] : null;
  rowne(`${id}: kafelki sum`, s.kafelki, Object.fromEntries(Object.entries(kafelkiOczekiwane(c)).map(([k, v]) => [String(k), v])));
  // zdanie pod kafelkami: przy więcej niż 8 osobach (z rodzajem działalności) – powód z CRM jak w #cena-opis, bez wzmianki o ankiecie (Q11)
  const powodOsoby = T.powody_wyceny_indywidualnej.osoby;
  rowne(`${id}: zdanie pod kafelkami`, sp(s.nota), c.ankieta_zaznaczona && c.zabiegi_ankieta.length
    ? 'Przy zabiegach wymagających ankiety składkę ustala indywidualnie ubezpieczyciel.'
    : kat && c.osoby === '9+'
      ? powodOsoby.charAt(0).toUpperCase() + powodOsoby.slice(1) + '. Doradca przygotuje wycenę i skontaktuje się z Tobą.'
      : 'Składki według taryfy programu' + (c.ochrona_prawna ? ', z ochroną prawną' : '') + '.');
  rowne(`${id}: komunikat przy pozycjach a–h`, s.ankietaBrak, o.komunikat_ankiety || null);
  rowne(`${id}: dokumenty przy pozycjach a–h`, s.ankietaInfo, c.ankieta_zaznaczona && c.zabiegi_ankieta.length > 0);
  rowne(`${id}: bez plakietek przy wariantach`, s.plakietka, false);
  if (c.odstepstwo_D45) {
    // D45: strona liczy według decyzji zleceniodawcy, nie według obecnej reguły CRM (kategoriaZRodzajow)
    const od = c.odstepstwo_D45;
    rowne(`${id}: odstępstwo D45 – kwota portalu, nie CRM`, [s.cena === zl(od.kwota_portalu), s.cena === zl(od.kwota_crm), s.taryfa === od.nazwa_crm],
      [true, false, false]);
  }
  if (o.stan === 'kwota') {
    rowne(`${id}: taryfa`, s.taryfa, o.nazwa);
    rowne(`${id}: kwota (tekst z twardymi spacjami)`, s.cena, o.tekst);
    rowne(`${id}: kwota = taryfa z fixture`, s.cena, zl(kwotaTaryfy(o.kategoria, c.suma, c.osoby, c.ochrona_prawna)));
    rowne(`${id}: „rocznie”`, s.dop, 'rocznie');
    rowne(`${id}: opis wyliczenia`, sp(s.opis), sp(o.opis));
    rowne(`${id}: przycisk`, [sp(s.cta), s.ctaDis], przycisk || ['Poproś o polisę', false]);
    rowne(`${id}: bez noty o ankiecie w panelu`, s.calcAnkieta, false);
  } else if (o.stan === 'indywidualna') {
    rowne(`${id}: taryfa`, s.taryfa, o.powod.startsWith('zabiegi') ? null : (kat ? NAZWA_KAT[kat] : null));
    rowne(`${id}: cena`, s.cena, 'Składka do indywidualnej wyceny');
    rowne(`${id}: opis (powód)`, sp(s.opis), o.powod.charAt(0).toUpperCase() + o.powod.slice(1) + '. Doradca przygotuje wycenę i skontaktuje się z Tobą.');
    rowne(`${id}: przycisk`, [sp(s.cta), s.ctaDis], przycisk || ['Poproś o wycenę indywidualną', false]);
    rowne(`${id}: nota o ankiecie w panelu`, s.calcAnkieta, o.powod.startsWith('zabiegi'));
  } else {
    rowne(`${id}: komunikat braku`, s.cena, o.komunikat);
    rowne(`${id}: bez opisu`, s.opis, null);
    rowne(`${id}: przycisk nieaktywny`, s.ctaDis, true);
    rowne(`${id}: taryfa`, s.taryfa, kat ? NAZWA_KAT[kat] : null);
  }
  // przycisk → formularz kontaktu (albo fokus na brakującym polu)
  await p.click('#cta-oferta', { force: true });  // aria-disabled: Playwright bez force czeka na „enabled”
  await p.waitForTimeout(50);
  const l = await stan(p);
  if (o.stan === 'brak' || o.przycisk_portalu) {
    rowne(`${id}: nieaktywny przycisk nie wypełnia formularza`, [l.lead, l.wynikKontakt], [{ rodzaje: '', osoby: '', suma: '', prawna: '', ankieta: '', zabiegi: '' }, null]);
    const pole = o.przycisk_portalu ? o.przycisk_portalu.fokus : !kat ? 'r-' + T.rodzaje_gabinetu[0].klucz : !c.osoby ? 'o-1-5' : 's-' + T.sumy[0];
    rowne(`${id}: fokus na brakującym polu`, l.fokus, pole);
  } else {
    const ank = c.ankieta_zaznaczona ? c.zabiegi_ankieta.map((n) => ANKIETA_ID[n]) : [];
    const ankStrony = [...document_order(ank)];
    rowne(`${id}: pola #lead`, l.lead, {
      rodzaje: T.rodzaje_gabinetu.map((r) => r.klucz).filter((k) => c.rodzaje.includes(k)).join(','),
      osoby: c.osoby || '', suma: c.suma ? String(c.suma) : '', prawna: c.ochrona_prawna ? '1' : '0',
      ankieta: ankStrony.join(','), zabiegi: w && w.wybrano && !przezWyszukiwarke ? w.wybrano : '',
    });
    const zd = sp(l.wynikKontakt);
    if (o.stan === 'kwota') rowne(`${id}: zdanie #kontakt-wynik z kwotą`, zd.includes(sp(o.tekst) + ' rocznie') && zd.includes(o.nazwa), true);
    else rowne(`${id}: zdanie #kontakt-wynik z powodem`, zd.startsWith('Wynik kalkulatora: składka do indywidualnej wyceny – ' + o.powod + '.'), true);
  }
  rowne(`${id}: błędy JS`, errs, []);
  await p.close();
}
// kolejność pozycji a–h jak na stronie (a, b, …) – id z mapy w zabiegi-oc-beauty.json
const KOLEJNOSC_A_H = Z.zabiegi.flatMap((z) => z.pozycje.filter((p) => p.lista === 'ankieta').map((p) => [p.nr, z.id]))
  .sort((a, b) => a[0].localeCompare(b[0])).map((x) => x[1]);
function document_order(ids) { return KOLEJNOSC_A_H.filter((i) => ids.includes(i)); }

const DLA_KOGO = [  // decyzja zleceniodawcy 14.11.2026; trycholog i masażysta – uwagi zleceniodawcy 16.11.2026 (00 D46 e)
  ['Kosmetolog', 'kosmetologiczny'], ['Fryzjer i barber', 'fryzjerski'], ['Podolog', 'podologiczny'],
  ['Linergistka', 'kosmetologiczny'], ['Stylistka paznokci', 'kosmetyczny'], ['Tatuażysta', 'tatuaz'],
  ['Trycholog', 'kosmetyczny'], ['Masażysta', 'masaz'],
];
async function dlaKogo(b) {
  for (const [zawod, rodzaj] of DLA_KOGO) {
    const p = await b.newPage({ viewport: { width: 1280, height: 900 }, reducedMotion: 'reduce' });
    await p.goto(PAGE, { waitUntil: 'load' });
    await p.click(`.pro[data-rodzaj] >> text="${zawod}"`);
    await p.check('#o-1-5'); await p.check('#s-200000');
    const s = await stan(p);
    const kat = KAT_RODZAJOW.get(rodzaj);
    rowne(`Dla kogo – ${zawod}: zaznaczony rodzaj`, s.rodzaje, [rodzaj]);
    rowne(`Dla kogo – ${zawod}: podpis kafelka`, sp(await p.textContent(`.pro[data-rodzaj] >> text="${zawod}" >> xpath=ancestor::a//small`)),
      'Rodzaj: ' + T.rodzaje_gabinetu.find((r) => r.klucz === rodzaj).nazwa);
    rowne(`Dla kogo – ${zawod}: taryfa i kwota`, [s.taryfa, s.cena], [NAZWA_KAT[kat], zl(kwotaTaryfy(kat, 200000, '1-5', false))]);
    await p.close();
  }
  // dwa profile: rodzaje się sumują (kosmetolog + fryzjer → gabinet kosmetologiczny + salon fryzjerski)
  const p = await b.newPage({ viewport: { width: 1280, height: 900 }, reducedMotion: 'reduce' });
  await p.goto(PAGE, { waitUntil: 'load' });
  await p.click('.pro[data-rodzaj] >> text="Kosmetolog"');
  await p.click('.pro[data-rodzaj] >> text="Fryzjer i barber"');
  await p.check('#o-1-5'); await p.check('#s-200000');
  const s = await stan(p);
  const kat = KAT_RODZAJOW.get(['fryzjerski', 'kosmetologiczny'].join(','));
  rowne('Dla kogo – dwa profile: rodzaje się sumują', s.rodzaje, ['fryzjerski', 'kosmetologiczny']);
  rowne('Dla kogo – dwa profile: taryfa i kwota', [s.taryfa, s.cena], [NAZWA_KAT[kat], zl(kwotaTaryfy(kat, 200000, '1-5', false))]);
  rowne('Dla kogo – liczba profili z rodzajem', await p.locator('.pro[data-rodzaj]').count(), DLA_KOGO.length);
  await p.close();
  // D45 (decyzja zleceniodawcy 16.11.2026): kosmetolog + stylistka paznokci = gabinet kosmetologiczny + gabinet kosmetyczny → pełna
  // taryfa; oczekiwania wpisane wprost (nie z fixture), żeby test pilnował samej decyzji
  const q = await b.newPage({ viewport: { width: 1280, height: 900 }, reducedMotion: 'reduce' });
  await q.goto(PAGE, { waitUntil: 'load' });
  await q.click('.pro[data-rodzaj] >> text="Kosmetolog"');
  await q.click('.pro[data-rodzaj] >> text="Stylistka paznokci"');
  await q.check('#o-1-5'); await q.check('#s-200000');
  const d = await stan(q);
  rowne('D45 – kosmetolog + stylistka paznokci: rodzaje, taryfa i kwota', [d.rodzaje, d.taryfa, d.cena],
    [['kosmetyczny', 'kosmetologiczny'], NAZWA_KAT.pelny, `980,00${NB}zł`]);
  rowne('D45 – kafelki sum: pełna taryfa', d.kafelki, { 100000: `850,00${NB}zł rocznie`, 200000: `980,00${NB}zł rocznie`, 300000: `1${NB}250,00${NB}zł rocznie` });
  await q.close();
  // trycholog i masażysta (uwagi zleceniodawcy 16.11.2026, 00 D46 e): rodzaje z listy nr 1 → podstawowa taryfa, każdy osobno i razem;
  // oczekiwania wpisane wprost (nie z fixture)
  for (const profile of [['Trycholog'], ['Masażysta'], ['Trycholog', 'Masażysta']]) {
    const r = await b.newPage({ viewport: { width: 1280, height: 900 }, reducedMotion: 'reduce' });
    await r.goto(PAGE, { waitUntil: 'load' });
    for (const z of profile) await r.click(`.pro[data-rodzaj] >> text="${z}"`);
    await r.check('#o-1-5'); await r.check('#s-200000');
    const t = await stan(r);
    const oczek = { Trycholog: 'kosmetyczny', 'Masażysta': 'masaz' };
    rowne(`Dla kogo – ${profile.join(' + ')}: rodzaje, podstawowa taryfa i kwota`, [t.rodzaje, t.taryfa, t.cena],
      [profile.map((z) => oczek[z]).sort(), NAZWA_KAT.kosmetyczny_fryzjerski, `500,00${NB}zł`]);
    rowne(`Dla kogo – ${profile.join(' + ')}: kafelki sum`, t.kafelki, { 100000: `400,00${NB}zł rocznie`, 200000: `500,00${NB}zł rocznie`, 300000: `650,00${NB}zł rocznie` });
    await r.close();
  }
}

async function poPrzycisku(b) {
  const p = await b.newPage({ viewport: { width: 1280, height: 900 }, reducedMotion: 'reduce' });
  const errs = [];
  p.on('pageerror', (e) => errs.push(e.message));
  await p.goto(PAGE, { waitUntil: 'load' });
  const lead = () => p.evaluate(() => {
    const f = document.getElementById('lead').elements, w = document.getElementById('kontakt-wynik');
    const pola = ['rodzaje', 'osoby', 'suma', 'prawna', 'ankieta', 'zabiegi'];
    return { pola: Object.fromEntries(pola.map((n) => [n, f[n].value])), wyl: pola.map((n) => f[n].disabled),
      wynik: w.hidden ? null : w.textContent, produkt: w.dataset.produkt || null, temat: f.product.value };
  });
  const H = Object.entries(ANKIETA_ID).find(([, idz]) => Z.zabiegi.find((z) => z.id === idz).pozycje[0].nr === 'h');
  const powodAnk = T.powody_wyceny_indywidualnej.ankieta;
  const kat = KAT_RODZAJOW.get('kosmetologiczny');
  await p.check('#r-kosmetologiczny'); await p.check('#o-1-5'); await p.check('#s-200000');
  await p.click('#cta-oferta'); await p.waitForTimeout(50);
  let l = await lead();
  rowne('po przycisku: pola #lead', l.pola, { rodzaje: 'kosmetologiczny', osoby: '1-5', suma: '200000', prawna: '0', ankieta: '', zabiegi: '' });
  rowne('po przycisku: pola włączone, temat OC', [l.wyl.every((x) => !x), l.temat, l.produkt], [true, 'oc-beauty', 'oc-beauty']);
  rowne('po przycisku: zdanie z kwotą', sp(l.wynik).endsWith(sp(zl(kwotaTaryfy(kat, 200000, '1-5', false))) + ' rocznie.'), true);
  // zabieg z ankiety po kliknięciu przycisku → wycena indywidualna także w formularzu (pole ankieta i zdanie)
  await p.check('#ankieta'); await p.check('#' + H[1]); await p.waitForTimeout(50);
  l = await lead();
  rowne('ankieta po przycisku: pole ankieta', l.pola.ankieta, H[1]);
  rowne('ankieta po przycisku: zdanie', sp(l.wynik).startsWith('Wynik kalkulatora: składka do indywidualnej wyceny – ' + powodAnk + '.') && sp(l.wynik).includes(H[0]), true);
  await p.uncheck('#ankieta'); await p.waitForTimeout(50);
  l = await lead();
  rowne('odznaczenie ankiety: pole ankieta puste, kwota wraca', [l.pola.ankieta, sp(l.wynik).endsWith(sp(zl(kwotaTaryfy(kat, 200000, '1-5', false))) + ' rocznie.')], ['', true]);
  // suma i ochrona prawna po przycisku
  await p.check('#s-300000'); await p.check('#prawna'); await p.waitForTimeout(50);
  l = await lead();
  rowne('suma i ochrona prawna po przycisku', [l.pola.suma, l.pola.prawna, sp(l.wynik).endsWith(sp(zl(kwotaTaryfy(kat, 300000, '1-5', true))) + ' rocznie.')], ['300000', '1', true]);
  // inny temat formularza: pola się aktualizują, zdanie ukryte; powrót tematu OC – zdanie z nową kwotą
  await p.selectOption('#l-produkt', 'utrata-dochodu');
  await p.check('#s-100000'); await p.waitForTimeout(50);
  l = await lead();
  rowne('inny temat: zdanie ukryte, pola OC wyłączone, suma zaktualizowana', [l.wynik, l.wyl.every((x) => x), l.pola.suma], [null, true, '100000']);
  await p.selectOption('#l-produkt', 'oc-beauty'); await p.waitForTimeout(50);
  l = await lead();
  rowne('powrót tematu OC: zdanie z kwotą przy 100 tys. zł, pola włączone', [sp(l.wynik).endsWith(sp(zl(kwotaTaryfy(kat, 100000, '1-5', true))) + ' rocznie.'), l.wyl.every((x) => !x)], [true, true]);
  // chip w wyszukiwarce: dodanie i usunięcie odświeżają pole zabiegi
  await p.fill('#zab-q', 'mezoterapia ig'); await p.waitForSelector('#zab-opt-g2-16');
  await p.click('#zab-opt-g2-16'); await p.waitForTimeout(50);
  l = await lead();
  rowne('chip po przycisku: pole zabiegi i zdanie', [l.pola.zabiegi, sp(l.wynik).includes('Wybrane zabiegi: Mezoterapia igłowa')], ['g2-16', true]);
  await p.click('.zab-chip-x'); await p.waitForTimeout(50);
  l = await lead();
  rowne('usunięcie chipa po przycisku: pole zabiegi puste', [l.pola.zabiegi, sp(l.wynik).includes('Wybrane zabiegi')], ['', false]);
  // stan „brak” (odznaczony rodzaj): pola wyczyszczone i wyłączone, zdanie ukryte, bez data-produkt
  await p.uncheck('#r-kosmetologiczny'); await p.waitForTimeout(50);
  l = await lead();
  rowne('stan „brak” po przycisku: formularz bez wyniku kalkulatora', l,
    { pola: { rodzaje: '', osoby: '', suma: '', prawna: '', ankieta: '', zabiegi: '' }, wyl: [true, true, true, true, true, true], wynik: null, produkt: null, temat: 'oc-beauty' });
  // powrót z „brak” do kwoty: powiązanie z kalkulatorem trwa (data-powiazany) – pola i zdanie wracają z nowym wynikiem
  await p.check('#r-kosmetologiczny'); await p.waitForTimeout(50);
  l = await lead();
  rowne('po stanie „brak” formularz wraca do wyniku kalkulatora', [l.pola, l.wyl.every((x) => !x), l.produkt, sp(l.wynik).endsWith(sp(zl(kwotaTaryfy(kat, 100000, '1-5', true))) + ' rocznie.')],
    [{ rodzaje: 'kosmetologiczny', osoby: '1-5', suma: '100000', prawna: '1', ankieta: '', zabiegi: '' }, true, 'oc-beauty', true]);
  // weryfikacja, runda 2: przycisk → odznaczenie jedynego rodzaju → zaznaczenie innego → lead z nowym wynikiem
  await p.uncheck('#r-kosmetologiczny'); await p.check('#r-fryzjerski'); await p.waitForTimeout(50);
  l = await lead();
  const katF = KAT_RODZAJOW.get('fryzjerski');
  rowne('zmiana jedynego rodzaju po przycisku: lead z nowym wynikiem', [l.pola.rodzaje, l.wyl.every((x) => !x), l.produkt, sp(l.wynik).endsWith(sp(zl(kwotaTaryfy(katF, 100000, '1-5', true))) + ' rocznie.')],
    ['fryzjerski', true, 'oc-beauty', true]);
  // „Wykonuję…” bez pozycji a–h po przycisku: przycisk nieaktywny, lead bez wyniku; pozycja a–h – wycena indywidualna w leadzie
  // (pozycja h) jest jeszcze zaznaczona z wcześniejszego kroku – odznaczenie jej zostawia „Wykonuję…” bez pozycji)
  await p.check('#ankieta'); await p.uncheck('#' + H[1]); await p.waitForTimeout(50);
  l = await lead();
  const ctaAnk = await p.evaluate(() => { const c = document.getElementById('cta-oferta'); return [c.textContent, c.getAttribute('aria-disabled')]; });
  rowne('„Wykonuję…” bez pozycji po przycisku: przycisk nieaktywny, lead bez wyniku', [ctaAnk, l.pola, l.wynik, l.produkt],
    [['Najpierw zaznacz zabiegi wymagające ankiety', 'true'], { rodzaje: '', osoby: '', suma: '', prawna: '', ankieta: '', zabiegi: '' }, null, null]);
  await p.click('#cta-oferta', { force: true }); await p.waitForTimeout(50);
  rowne('„Wykonuję…” bez pozycji: fokus na pozycji a)', await p.evaluate(() => document.activeElement.id), KOLEJNOSC_A_H[0]);
  await p.check('#' + KOLEJNOSC_A_H[0]); await p.waitForTimeout(50);
  l = await lead();
  rowne('pozycja a–h po przycisku: lead z wyceną indywidualną', [l.pola.ankieta, l.produkt, sp(l.wynik).startsWith('Wynik kalkulatora: składka do indywidualnej wyceny – ' + powodAnk + '.')],
    [KOLEJNOSC_A_H[0], 'oc-beauty', true]);
  await p.uncheck('#ankieta'); await p.waitForTimeout(50);
  // przycisk Tax Protect przejmuje formularz – zmiany w kalkulatorze OC go nie nadpisują; przycisk OC wraca do OC
  await p.click('#tab-tax'); await p.click('#tax-cta'); await p.waitForTimeout(50);
  await p.click('#tab-oc'); await p.check('#s-200000'); await p.waitForTimeout(50);
  l = await lead();
  rowne('po przycisku Tax Protect zmiana OC nie nadpisuje formularza', [l.produkt, l.temat, sp(l.wynik).startsWith('Wynik kalkulatora Tax Protect'), l.wyl.every((x) => x)], ['tax-protect', 'tax-protect', true, true]);
  await p.click('#cta-oferta'); await p.waitForTimeout(50);
  l = await lead();
  rowne('przycisk OC po Tax Protect: wynik OC', [l.produkt, l.temat, l.pola.suma, sp(l.wynik).endsWith(sp(zl(kwotaTaryfy(katF, 200000, '1-5', true))) + ' rocznie.')], ['oc-beauty', 'oc-beauty', '200000', true]);
  rowne('po przycisku: błędy JS', errs, []);
  await p.close();
  // temat OC bez kalkulatora (?produkt=oc-beauty): pola kalkulatora OC nie idą z formularzem (LeadInput.calc opcjonalne)
  const q = await b.newPage({ viewport: { width: 1280, height: 900 } });
  await q.goto(PAGE + '?produkt=oc-beauty#kontakt', { waitUntil: 'load' });
  const bez = await q.evaluate(() => {
    const f = document.getElementById('lead').elements;
    return { temat: f.product.value, wyl: ['rodzaje', 'osoby', 'suma', 'prawna', 'ankieta', 'zabiegi'].every((n) => f[n].disabled) };
  });
  rowne('temat OC bez kalkulatora: pola kalkulatora wyłączone', bez, { temat: 'oc-beauty', wyl: true });
  await q.close();
}

async function startowy(b) {
  for (const js of [true, false]) {
    const ctx = await b.newContext({ javaScriptEnabled: js, viewport: { width: 390, height: 844 } });
    const p = await ctx.newPage();
    await p.goto(PAGE, { waitUntil: 'load' });
    const r = await p.evaluate(() => ({
      zaznaczone: [...document.querySelectorAll('#calc input:checked')].map((i) => i.id),
      cena: document.getElementById('cena').textContent,
      kafelki: [...document.querySelectorAll('[id^="kw-"]')].map((x) => x.textContent),
      tekst: document.getElementById('kalkulator-oc').textContent,
    }));
    const tryb = js ? 'z JS' : 'bez JS';
    rowne(`stan startowy ${tryb}: żadne pole nie jest zaznaczone (P9)`, r.zaznaczone, []);
    rowne(`stan startowy ${tryb}: bez kwoty`, r.cena, T.komunikaty_brakow.rodzaje);
    rowne(`stan startowy ${tryb}: kafelki sum puste`, r.kafelki, ['', '', '']);
    rowne(`stan startowy ${tryb}: bez plakietek i słów o niepewności kwoty`, /najczęściej wybier|orientacyjn|szacunkow|do potwierdzenia/i.test(r.tekst), false);
    await ctx.close();
  }
}

(async () => {
  const b = await chromium.launch();
  let crm = 0, portal = 0;
  for (const c of F.przypadki) {
    const przed = bledy.length;
    await przypadek(b, c);
    if (bledy.length === przed) { if (c.tylko_portal) portal++; else crm++; }
  }
  await dlaKogo(b);
  await poPrzycisku(b);
  await startowy(b);
  await b.close();
  const wszystkie = F.przypadki.length, crmMax = F.przypadki.filter((c) => !c.tylko_portal).length;
  console.log(`przypadki fixture: ${crm}/${crmMax} porównywalnych z CRM + ${portal}/${wszystkie - crmMax} stanów interfejsu portalu (tylko_portal); „Dla kogo”: ${DLA_KOGO.length} profili + 2 profile razem + D45 (kosmetolog + stylistka paznokci) + trycholog i masażysta (osobno i razem); zmiany po przycisku; asercje: ${asercje}`);
  if (bledy.length) {
    console.log('BŁĘDY (' + bledy.length + '):\n' + bledy.join('\n'));
    process.exit(1);
  }
  console.log('OK');
})();
