// Kontrola uwag raportu 16 (rozdz. 3.3) w Strefie Klienta: logowanie.html, panel.html, dam-prace.html, szkolenia.html, strefa.css,
// strefa.js (wspólne wzorce). Sprawdza:
//  - akcje nieodwracalne w dwóch krokach (details.mini: opis skutku, przycisk wykonania, „Anuluj”, Esc, fokus): Usuń konto,
//    Usuń ogłoszenie, Zwróć 390,00 zł, Odbierz dostęp; akcje odwracalne z „Cofnij” przez 10 s (Zamknij, Usuń szkic, Zrezygnuj):
//    fokus na „Cofnij”, cofnięcie przywraca stan i fokus, czas stoi przy fokusie, po czasie pasek znika;
//  - licznik ponownej wysyłki kodu: role="timer", aria-live="off", bez ogłoszeń co sekundę – ogłoszenie startu (po kliknięciu)
//    i końca; przycisk z aria-disabled (fokus zostaje);
//  - błędy przy polach: tekst w .field-error, aria-invalid, aria-describedby; Enter w polu z fokusem – ogłoszenie w role="alert";
//    widełki (oba pola), liczba miejsc (3 komunikaty), „Zgłoś nadużycie”, kod pocztowy (5 cyfr bez „-” → 00-000);
//  - „Pobieranie…” bez kasowania nazwy linku (sr-only zostaje), stan w role="status"; aria-disabled zamiast disabled (fokus);
//  - deep link #p-szkody / #p-archiwum (właściwa zakładka), adres po kliknięciu zakładki; filtry w adresie (zapis i odczyt,
//    inne parametry zostają); ostrzeżenie przed utratą danych (confirm przy „Anuluj”, flaga po wpisaniu);
//  - teksty (druga osoba, strona czynna, cyfry, placeholdery z „…”, spellcheck, autocomplete="off", fieldset „Adresaci”, h2),
//    polskie formaty (Intl: 1 234,50 zł, 3.12.2026);
//  - axe (WCAG 2.2 AA) na głównych ekranach 4 stron przy 320 i 1280 px – także w każdej zakładce ekranu (weryfikacja, runda 1);
//    tabele: poniżej 720 px .table-wrap bez przewijania w poziomie (znaczki statusu i długie dane łamią się), od 720 px przewijana
//    tabela jest regionem z fokusem (tabindex="0", role="region", aria-label), a mieszcząca się – bez zbędnego zatrzymania Tab;
//    brak przewijania strony w poziomie 320–1440 px, także przy długim tytule od użytkownika (85 znaków bez spacji);
//  - weryfikacja, runda 1: „Cofnij” z opisem czasu w oknie po wpisaniu statusu (szkolenia #zapisano, 4 rozmiary okna), przycisk
//    ponownej wysyłki kodu bez aria-describedby po odliczaniu, „Zapisz szkic” znowu aktywny po edycji formularza;
//  - weryfikacja, runda 2: komunikat statusu (≥ 90%) i pasek „Cofnij” w oknie – dam-prace #moje-ogloszenia (Zamknij, Usuń szkic),
//    szkolenia #moje-szkolenia (Zrezygnuj) przy 320/390/768/1280 px; nazwa „Cofnij: rezygnacja z zapisu na „…”” (jeden dwukropek).
// Tylko odczyt makiet (file://), nic nie zapisuje w repozytorium; zrzuty – kontrola/wyniki/strefa/.
// Uruchomienie: node narzedzia/makiety/kontrola/strefa/potwierdzenia.js   (kod wyjścia 1 przy błędach)
const path = require('path');
const fs = require('fs');
const { chromium } = require('playwright');
const REPO = path.resolve(__dirname, '../../../..');                  // katalog główny repozytorium
const DIR = REPO + '/docs/koncepcja/design/v3/strefa/';
const S = 'file://' + DIR;
const OUT = path.join(__dirname, '../wyniki/strefa') + '/';          // zrzuty (poza gitem)
const AXE = fs.readFileSync(require.resolve('axe-core/axe.min.js'), 'utf8');
fs.mkdirSync(OUT, { recursive: true });

const FAIL = [];
let N = 0;
const ok = (c, m) => { N++; if (!c) { FAIL.push(m); console.log('  FAIL', m); } return !!c; };
const log = (...a) => console.log(...a);
const nb = s => (s || '').replace(/[  ⁠]/g, ' ').replace(/\s+/g, ' ').trim();

async function ctxNew(b, opt = {}) {
  const c = await b.newContext({ viewport: { width: opt.w || 1280, height: opt.h || 900 }, deviceScaleFactor: 1, javaScriptEnabled: opt.js !== false });
  if (opt.zegar) { await c.clock.install(); }
  await c.addInitScript(() => { window.nb0 = s => (s || '').replace(/[  ]/g, ' ').replace(/\s+/g, ' ').trim(); });
  return c;
}
async function open(c, url, errs) {
  const p = await c.newPage();
  p.on('pageerror', e => errs.push(url + ': ' + e.message));
  p.on('console', m => { if (m.type() === 'error' && !/Failed to load resource|ERR_FILE_NOT_FOUND|net::|fonts\.g|XMLHttpRequest at 'file:/.test(m.text())) errs.push(url + ': ' + m.text()); });
  await p.goto(S + url, { waitUntil: 'load' });
  await p.waitForTimeout(150);
  return p;
}
const czekaj = (p, ms) => p.waitForTimeout(ms);
async function nbFn() { /* nb0() w stronie – addInitScript w ctxNew */ }
async function axe(p, label, include) {
  await p.addScriptTag({ content: AXE });
  const r = await p.evaluate(async inc => {
    const res = await axe.run(inc ? { include: inc } : document, { runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'] }, resultTypes: ['violations'] });
    return res.violations.map(v => ({ id: v.id, n: v.nodes.length, t: v.nodes.slice(0, 3).map(n => n.target.join(' ') + ' :: ' + (n.failureSummary || '').replace(/\s+/g, ' ').slice(0, 160)) }));
  }, include || null);
  ok(!r.length, `axe ${label}: ${JSON.stringify(r)}`);
  return r;
}
const poziomo = () => { const de = document.documentElement; return { sw: de.scrollWidth, cw: de.clientWidth }; };
// widoczne .table-wrap: poniżej 720 px (układ .stack) żadna nie przewija się w poziomie; od 720 px przewijana tabela jest regionem
// z fokusem (tabindex="0", role="region", aria-label – WCAG 2.1.1), a tabela mieszcząca się w karcie nie ma zbędnego zatrzymania Tab
const tabeleSzersze = () => [...document.querySelectorAll('.table-wrap')].filter((t) => t.offsetParent && t.clientWidth > 0).map((t) => {
  const id = ((t.closest('[id]') || {}).id || '?'), przew = t.scrollWidth > t.clientWidth + 1, ti = t.getAttribute('tabindex');
  if (przew && innerWidth < 720) { return id + ' przewija się ' + t.scrollWidth + '>' + t.clientWidth; }
  if (przew && !(ti === '0' && t.getAttribute('role') === 'region' && t.getAttribute('aria-label'))) { return id + ' przewija się bez tabindex/role/aria-label'; }
  if (!przew && t.getAttribute('role') === 'region' && ti !== null && document.activeElement !== t) { return id + ' nie przewija się, a ma tabindex'; }
  return null;
}).filter(Boolean);

(async () => {
  const b = await chromium.launch();
  const errs = [];

  // ---------- 0. statycznie: strefa.js przed skryptem strony na 4 stronach, teksty i atrybuty ----------
  log('\n== 0. Statycznie: strefa.js, teksty, atrybuty');
  {
    const html = f => fs.readFileSync(DIR + f, 'utf8');
    const bezGen = h => h.replace(/<!-- gen:([\w:-]+)[^>]*-->[\s\S]*?<!-- \/gen:\1 -->/g, '').replace(/<script\b[\s\S]*?<\/script>/g, '');
    for (const f of ['logowanie.html', 'panel.html', 'dam-prace.html', 'szkolenia.html']) {
      const h = html(f);
      const i = h.indexOf('<script src="strefa.js"></script>');
      ok(i > 0 && h.indexOf('<script>', i) > i, `${f}: <script src="strefa.js"> przed skryptem strony`);
      ok(!/ disabled aria-describedby="[\w-]*resend/.test(h), `${f}: przycisk ponownej wysyłki bez atrybutu disabled`);
    }
    const lg = bezGen(html('logowanie.html'));
    ok(!/sześciocyfrow|Sześć cyfr/i.test(lg), 'logowanie: liczebniki cyframi („6 cyfr”, „6-cyfrowy kod”)');
    ok(!/Mam już konto/.test(lg) && /Masz konto\? Zaloguj się/.test(lg), 'logowanie: „Masz konto? Zaloguj się” zamiast „Mam już konto”');
    ok(!/został unieważniony/.test(lg) && /Ten kod już nie działa/.test(lg), 'logowanie: „Ten kod już nie działa” zamiast strony biernej');
    ok(/placeholder="np\. anna@salon-przykladowy\.example…"/.test(lg), 'logowanie: placeholder kończy się „…”');
    ok(/Sprawdź SMS i&nbsp;wpisz kod ponownie albo wyślij nowy kod/.test(lg), 'logowanie: błędny kod SMS – następny krok');
    for (const id of ['kod', 'totp', 'totp-new', 'totp-zapas', 'rej-kod', 'sms', 'rp-totp']) {
      ok(new RegExp('id="' + id + '" spellcheck="false"').test(lg), `logowanie: #${id} spellcheck="false"`);
    }
    for (const k of ['resend', 'rej-resend', 'sms-resend']) {
      ok(new RegExp('id="' + k + '-left" role="timer" aria-live="off"').test(lg) && !new RegExp('id="' + k + '-info" aria-live').test(lg), `logowanie: ${k} – licznik role="timer" aria-live="off", bez aria-live na opisie`);
    }
    const pn = bezGen(html('panel.html'));
    ok(/>Zarządzaj zespołem</.test(pn), 'panel: „Zarządzaj zespołem”');
    ok(/Doradca dostał zgłoszenie SZ-/.test(pn) && !/zostało przyjęte/.test(pn), 'panel: strona czynna w potwierdzeniu zgłoszenia szkody');
    ok(/>Przejrzyj listę</.test(pn) && !/przejrzę/.test(pn), 'panel: „Przejrzyj listę”');
    ok(/id="sz-email"[^>]*spellcheck="false"/.test(pn), 'panel: e-mail zgłoszenia szkody spellcheck="false"');
    ok(/nr&nbsp;WA50/.test(pn) && /Aneks nr&nbsp;1/.test(pn) && /7&nbsp;listopada/.test(pn) && /2&nbsp;osoby/.test(pn), 'panel: twarde spacje (nr, daty, „2 osoby”)');
    const pnZwykle = (pn.replace(/<!--[\s\S]*?-->/g, '').replace(/<head>[\s\S]*?<\/head>/, '').replace(/<svg\b[\s\S]*?<\/svg>/g, '').replace(/<[^>]*>/g, '>').match(/[^\s>;] – /g) || []).length;  // tylko widoczny tekst (bez SVG; znaczniki → „>”)
    ok(pnZwykle === 0, `panel: półpauza bez twardej spacji przed nią w tekście (${pnZwykle})`);
    const dp = bezGen(html('dam-prace.html'));
    ok(!/>Mam konto</.test(dp), 'dam-prace: bez „Mam konto”');
    ok(!/Moje ogłoszenie[^a]/.test(dp) && /Twoje ogłoszenie/.test(dp), 'dam-prace: „Twoje ogłoszenie” (bez „Moje ogłoszenie”)');
    ok(/<h2 class="card-title">Jak potwierdzamy firmę<\/h2>/.test(dp), 'dam-prace: „Jak potwierdzamy firmę” jako h2');
    ok(/Pracodawca dostał wiadomość/.test(dp) && !/zostało zamknięte|został usunięty|zostały usunięte|zostało usunięte|została przekazana/.test(dp), 'dam-prace: strona czynna w komunikatach');
    ok(/placeholder="np\. 123-456-78-90…"/.test(dp), 'dam-prace: placeholder NIP jako wzór z „…”');
    for (const id of ['n-tytul', 'n-od', 'n-do']) { ok(new RegExp('id="' + id + '"[^>]*autocomplete="off"').test(dp), `dam-prace: #${id} autocomplete="off"`); }
    ok(!/jednym przyciskiem/.test(dp), 'dam-prace: bez „jednym przyciskiem” przy usuwaniu');
    const sz = bezGen(html('szkolenia.html'));
    ok(/<fieldset class="field">\s*<legend>Adresaci<\/legend>/.test(sz), 'szkolenia: „Adresaci” w fieldset z legend');
    // runda 2 weryfikacji: każde potwierdzenie akcji nieodwracalnej (details.mini z przyciskiem .btn-danger) ma „Anuluj”
    // (data-zamknij) w .actions, a przycisk wykonania – aria-describedby do opisu skutku
    for (const [n, t] of [['logowanie.html', lg], ['panel.html', pn], ['dam-prace.html', dp], ['szkolenia.html', sz]]) {
      const bloki = (t.match(/<details class="mini"[^>]*>[\s\S]*?<\/details>/g) || []).filter((x) => /class="btn btn-danger[^"]*"[^>]*>/.test(x.replace(/<summary[\s\S]*?<\/summary>/, '')));
      const zle = bloki.filter((x) => { const bez = x.replace(/<summary[\s\S]*?<\/summary>/, ''); const btn = bez.match(/<button class="btn btn-danger[^>]*>/);
        return !/<div class="actions">[\s\S]*?data-zamknij[^>]*>Anuluj<\/button><\/div>/.test(bez) || !btn || !/aria-describedby="[^"]+"/.test(btn[0]); });
      ok(!zle.length, `${n}: potwierdzenia z „Anuluj” i opisem skutku (${bloki.length} potwierdzeń, bez: ${zle.map((x) => (x.match(/<summary[^>]*>([\s\S]*?)<\/summary>/) || [])[1]).join(' | ')})`);
    }
    for (const id of ['cap-1', 'zw-kw-1', 'zw-kw-2', 'd-tytul', 'd-miejsce', 'd-miejsca', 'd-limit', 'd-cena', 'd-link']) { ok(new RegExp('id="' + id + '"[^>]*autocomplete="off"').test(sz), `szkolenia: #${id} autocomplete="off"`); }
  }

  // ---------- 1. Logowanie: licznik ponownej wysyłki (zegar), błędy z ogłoszeniem, etykiety ----------
  log('\n== 1. Logowanie: licznik, błędy, etykiety');
  {
    const c = await ctxNew(b, { zegar: true });
    const p = await open(c, 'logowanie.html#s-kod', errs); await nbFn(p);
    const st0 = await p.evaluate(() => ({ dis: document.getElementById('resend').getAttribute('aria-disabled'), disabled: document.getElementById('resend').disabled, timer: document.getElementById('resend-left').getAttribute('role'), live: document.getElementById('resend-left').getAttribute('aria-live'), info: document.getElementById('resend-info').getAttribute('aria-live') }));
    ok(st0.dis === 'true' && !st0.disabled && st0.timer === 'timer' && st0.live === 'off' && st0.info === null, `logowanie: start licznika ${JSON.stringify(st0)}`);
    // zapis zmian regionów ogłoszeń przez 60 s
    await p.evaluate(() => { window.zmiany = []; document.querySelectorAll('[data-bp-region]').forEach(r => new MutationObserver(() => { if (r.textContent) window.zmiany.push(r.getAttribute('data-bp-region') + ':' + r.textContent); }).observe(r, { childList: true, characterData: true, subtree: true })); });
    await p.clock.runFor(30000);
    const w30 = await p.evaluate(() => ({ z: window.zmiany.slice(), left: document.getElementById('resend-left').textContent }));
    ok(w30.z.length === 0 && w30.left === '0:29', `logowanie: licznik bez ogłoszeń w trakcie (${JSON.stringify(w30)})`);
    await p.clock.runFor(30500);
    const w60 = await p.evaluate(() => ({ z: window.zmiany.slice(), dis: document.getElementById('resend').getAttribute('aria-disabled'), info: document.getElementById('resend-info').hidden, opis: document.getElementById('resend').getAttribute('aria-describedby') }));
    ok(w60.z.length === 1 && /Możesz już wysłać kod ponownie/.test(w60.z[0]) && w60.dis === null && w60.info, `logowanie: koniec odliczania ogłoszony raz (${JSON.stringify(w60)})`);
    // aktywny przycisk bez opisu „Możliwe za 0:00” (ukryta treść wskazana w aria-describedby trafia do opisu – weryfikacja, runda 1)
    ok(w60.opis === null, `logowanie: po odliczaniu przycisk bez aria-describedby (${w60.opis})`);
    await p.focus('#resend'); await p.keyboard.press('Enter'); await p.clock.runFor(200);
    const po = await p.evaluate(() => ({ a: document.activeElement.id, dis: document.getElementById('resend').getAttribute('aria-disabled'), z: window.zmiany.slice(-1)[0], opis: document.getElementById('resend').getAttribute('aria-describedby') }));
    ok(po.a === 'resend' && po.dis === 'true' && po.opis === 'resend-info' && /Wysłano nowy kod\. Kolejny kod wyślesz za 59.s\./.test(nb(po.z)), `logowanie: po „Wyślij kod ponownie” fokus zostaje, start ogłoszony (${JSON.stringify(po)})`);
    // kliknięcie zablokowanego przycisku niczego nie zmienia
    await p.locator('#resend').click({ force: true }); await p.clock.runFor(100);
    ok(nb(await p.evaluate(() => document.getElementById('resend-left').textContent)) === '0:59', 'logowanie: zablokowany przycisk nie restartuje licznika');
    // błąd przy polu – Enter w polu z fokusem → ogłoszenie w role="alert"
    await p.fill('#kod', '12'); await p.focus('#kod'); await p.keyboard.press('Enter'); await p.clock.runFor(200);
    const e1 = await p.evaluate(() => ({ inv: document.getElementById('kod').getAttribute('aria-invalid'), d: document.getElementById('kod').getAttribute('aria-describedby'), err: nb0(document.getElementById('kod-err').textContent), vis: !document.getElementById('kod-err').hidden, al: nb0(document.querySelector('[data-bp-region="alert"]').textContent), a: document.activeElement.id }));
    ok(e1.inv === 'true' && /kod-err/.test(e1.d) && e1.vis && e1.err === 'Wpisz 6 cyfr z e-maila.' && e1.al === e1.err && e1.a === 'kod', `logowanie: błąd kodu przy polu i w role="alert" (${JSON.stringify(e1)})`);
    await c.close();
    const c2 = await ctxNew(b);
    const p2 = await open(c2, 'logowanie.html#s-totp', errs);
    ok(nb(await p2.textContent('#f-totp button[type=submit]')) === 'Zaloguj się', 'logowanie: TOTP – „Zaloguj się”');
    await p2.goto(S + 'logowanie.html#s-rej-kod'); await czekaj(p2, 100);
    ok(nb(await p2.textContent('#f-rej-kod button[type=submit]')) === 'Potwierdź kod', 'logowanie: kod rejestracji – „Potwierdź kod”');
    // SMS: błędny kod – komunikat z następnym krokiem
    await p2.goto(S + 'logowanie.html#s-sms'); await czekaj(p2, 100); await nbFn(p2);
    await p2.fill('#tel', '512345678'); await p2.click('#tel-btn'); await czekaj(p2, 100);
    await p2.fill('#sms', '000000'); await p2.keyboard.press('Enter'); await czekaj(p2, 150);
    const sm = await p2.evaluate(() => ({ err: nb0(document.getElementById('sms-err').textContent), al: nb0(document.querySelector('[data-bp-region="alert"]').textContent) }));
    ok(sm.err === 'Kod jest nieprawidłowy. Pozostały 4 próby. Sprawdź SMS i wpisz kod ponownie albo wyślij nowy kod.' && sm.al === sm.err, `logowanie: błędny kod SMS ${JSON.stringify(sm)}`);
    await c2.close();
    // runda 2 weryfikacji: „Wyślij kod ponownie” w kroku SMS – fokus zostaje na przycisku (bez przeniesienia na #sms-sent
    // z role="status"), jedno ogłoszenie na akcję – jak przy kodzie z e-maila
    const c3 = await ctxNew(b, { zegar: true });
    const p3 = await open(c3, 'logowanie.html#s-sms', errs);
    await p3.fill('#tel', '512345678'); await p3.click('#tel-btn'); await p3.clock.runFor(100);
    await p3.clock.runFor(61000);
    await p3.evaluate(() => { window.zmiany = []; document.querySelectorAll('[data-bp-region]').forEach(r => new MutationObserver(() => { if (r.textContent) window.zmiany.push(r.getAttribute('data-bp-region') + ':' + r.textContent); }).observe(r, { childList: true, characterData: true, subtree: true })); });
    await p3.focus('#sms-resend'); await p3.keyboard.press('Enter'); await p3.clock.runFor(300);
    const rs = await p3.evaluate(() => ({ a: document.activeElement.id, dis: document.getElementById('sms-resend').getAttribute('aria-disabled'), z: window.zmiany.slice() }));
    ok(rs.a === 'sms-resend' && rs.dis === 'true' && rs.z.length === 1 && /Wysłano nowy SMS z.kodem/.test(nb(rs.z[0])), `logowanie: SMS „Wyślij kod ponownie” – fokus zostaje, jedno ogłoszenie ${JSON.stringify(rs)}`);
    await c3.close();
  }

  // ---------- 2. Panel: deep link zakładek, pobieranie, Odbierz dostęp, aria-disabled, niezapisane zmiany ----------
  log('\n== 2. Panel');
  {
    const c = await ctxNew(b);
    const p = await open(c, 'panel.html#p-szkody', errs); await nbFn(p);
    const t1 = await p.evaluate(() => ({ view: document.querySelector('.view.is-active').id, sel: document.getElementById('t-szkody').getAttribute('aria-selected'), vis: !document.getElementById('p-szkody').hidden, akt: document.getElementById('p-aktualne').hidden }));
    ok(t1.view === 'polisy' && t1.sel === 'true' && t1.vis && t1.akt, `panel: #p-szkody otwiera „Zgłoszenia szkód” ${JSON.stringify(t1)}`);
    // runda 2 weryfikacji: świeże wejście z adresem panelu (np. link ze słownika) – rząd zakładek widoczny pod paskiem górnym
    for (const [vw, vh] of [[320, 640], [390, 844], [768, 1024], [1280, 900], [1440, 900]]) {
      for (const h of ['p-szkody', 'p-archiwum']) {
        const cz = await ctxNew(b, { w: vw, h: vh });
        const pz = await open(cz, 'panel.html#' + h, errs); await czekaj(pz, 200);
        const z = await pz.evaluate((hh) => { const tab = document.getElementById(hh === 'p-szkody' ? 't-szkody' : 't-archiwum'), r = tab.getBoundingClientRect(), bar = document.querySelector('.topbar').getBoundingClientRect();
          return { tabTop: Math.round(r.top), tabBottom: Math.round(r.bottom), belka: Math.round(bar.bottom), vh: innerHeight, sel: tab.getAttribute('aria-selected') }; }, h);
        ok(z.sel === 'true' && z.tabTop >= z.belka && z.tabBottom <= z.vh, `panel: świeże wejście #${h} ${vw}×${vh} – zakładka pod paskiem, w oknie ${JSON.stringify(z)}`);
        await cz.close();
      }
    }
    await p.evaluate(() => { location.hash = 'p-archiwum'; }); await czekaj(p, 150);
    const t2 = await p.evaluate(() => ({ sel: document.getElementById('t-archiwum').getAttribute('aria-selected'), vis: !document.getElementById('p-archiwum').hidden, a: document.activeElement.id }));
    ok(t2.sel === 'true' && t2.vis && t2.a === 't-archiwum', `panel: #p-archiwum – zakładka i fokus ${JSON.stringify(t2)}`);
    await p.click('#t-aktualne'); await czekaj(p, 50);
    ok(await p.evaluate(() => location.hash) === '#p-aktualne', 'panel: kliknięcie zakładki zmienia adres (#p-aktualne)');
    await p.keyboard.press('ArrowRight'); await czekaj(p, 50);
    ok(await p.evaluate(() => location.hash) === '#p-archiwum', 'panel: strzałka w zakładkach zmienia adres');
    // skrót „Archiwum” na pulpicie
    await p.goto(S + 'panel.html?nowa=1#pulpit'); await czekaj(p, 150);
    await p.click('a.shortcut[href="#p-archiwum"]'); await czekaj(p, 150);
    ok(await p.evaluate(() => document.getElementById('t-archiwum').getAttribute('aria-selected')) === 'true', 'panel: skrót „Archiwum” otwiera zakładkę Archiwum');
    // pobieranie PDF
    await p.goto(S + 'panel.html#polisa-oc'); await czekaj(p, 200); await nbFn(p);
    const link = p.locator('#polisa-oc .doc-row .btn').first();
    await link.click(); await czekaj(p, 120);
    const pb = await p.evaluate(() => { const a = document.querySelector('#polisa-oc .doc-row .btn'); return { vis: nb0(a.querySelector('.js-etykieta').textContent), sr: nb0(a.querySelector('.sr-only') && a.querySelector('.sr-only').textContent), st: nb0(document.getElementById('pobieranie-status').textContent), busy: a.getAttribute('aria-busy') }; });
    const nazwa = await link.evaluate(a => a.textContent.replace(/\s+/g, ' ').trim());
    ok(pb.vis === 'Pobieranie…' && pb.sr === ': polisa' && /: polisa$/.test(nazwa) && /^Pobieranie: Polisa BP\/2026\/000123…$/.test(pb.st), `panel: „Pobieranie…” bez kasowania nazwy linku, stan w role="status" ${JSON.stringify(pb)} „${nazwa}”`);
    await czekaj(p, 1300);
    ok(nb(await link.textContent()) === 'Pobierz PDF: polisa', 'panel: po pobraniu etykieta wraca');
    // „Poproś doradcę o nowy link” – aria-disabled, fokus zostaje, kontekst w nazwie zostaje
    await p.goto(S + 'panel.html#sprawy'); await czekaj(p, 150);
    const nl = p.locator('.js-case-newlink button');
    await nl.focus(); await p.keyboard.press('Enter'); await czekaj(p, 150);
    const n1 = await p.evaluate(() => { const b2 = document.querySelector('.js-case-newlink button'); return { a: document.activeElement === b2, dis: b2.getAttribute('aria-disabled'), disabled: b2.disabled, txt: b2.textContent.replace(/\s+/g, ' ').trim(), st: !b2.closest('li').querySelector('.js-case-status').hidden }; });
    ok(n1.a && n1.dis === 'true' && !n1.disabled && n1.txt === 'Prośba wysłana – odnowienie OC' && n1.st, `panel: „Poproś doradcę o nowy link” ${JSON.stringify(n1)}`);
    // „Odbierz dostęp”: dwa kroki, Esc i „Anuluj”, wykonanie
    await p.goto(S + 'panel.html#zespol'); await czekaj(p, 150);
    const sum = p.locator('#osoby details.mini > summary');
    ok(await sum.count() === 1 && nb(await sum.textContent()) === 'Odbierz dostęp: Ewa Przykładowa', 'panel: „Odbierz dostęp” jako summary potwierdzenia');
    await sum.click(); await czekaj(p, 80);
    ok(/Dostęp przywrócisz tylko nowym zaproszeniem/.test(nb(await p.textContent('#osoby details.mini .mini-body'))), 'panel: opis skutku odebrania dostępu');
    await p.keyboard.press('Escape'); await czekaj(p, 60);
    let d = await p.evaluate(() => ({ open: document.querySelector('#osoby details.mini').open, a: document.activeElement.tagName }));
    ok(!d.open && d.a === 'SUMMARY', `panel: Esc zamyka potwierdzenie, fokus na summary ${JSON.stringify(d)}`);
    await sum.click(); await p.click('#osoby details.mini [data-zamknij]'); await czekaj(p, 60);
    d = await p.evaluate(() => ({ open: document.querySelector('#osoby details.mini').open, a: document.activeElement.tagName }));
    ok(!d.open && d.a === 'SUMMARY', `panel: „Anuluj” zamyka potwierdzenie ${JSON.stringify(d)}`);
    await sum.click(); await p.click('.js-odbierz'); await czekaj(p, 80);
    d = await p.evaluate(() => { const tr = document.querySelector('.js-odbierz').closest('tr'); return { badge: tr.querySelector('td[data-label="Rola"] .badge').textContent, a: document.activeElement.className, st: document.activeElement.textContent }; });
    ok(d.badge === 'Dostęp odebrany' && /js-odbierz-status/.test(d.a) && /Dostęp odebrany/.test(d.st), `panel: odebranie dostępu, fokus na komunikacie ${JSON.stringify(d)}`);
    // „Zespół jest aktualny” – fokus na komunikacie
    await p.click('#team-ok'); await czekaj(p, 50);
    ok(await p.evaluate(() => document.activeElement.classList.contains('js-team-status')), 'panel: „Zespół jest aktualny” – fokus na komunikacie (przyciski znikają)');
    // niezapisane zmiany: „Anuluj” w zgłoszeniu szkody
    await p.goto(S + 'panel.html#szkoda'); await czekaj(p, 150);
    await p.fill('#sz-tel', '512 345 678');
    ok(await p.evaluate(() => document.getElementById('f-szkoda').getAttribute('data-zmiany')) === 'tak', 'panel: flaga zmian po wpisaniu');
    let pyt = '';
    p.once('dialog', dl => { pyt = dl.message(); dl.dismiss(); });
    await p.click('#f-szkoda a.link-quiet[href="#pulpit"]'); await czekaj(p, 150);
    ok(/niezapisane zmiany/.test(pyt) && await p.evaluate(() => location.hash) === '#szkoda', `panel: „Anuluj” przy zmianach pyta i zostaje (${pyt})`);
    p.once('dialog', dl => dl.accept());
    await p.click('#f-szkoda a.link-quiet[href="#pulpit"]'); await czekaj(p, 150);
    ok(await p.evaluate(() => location.hash) === '#pulpit', 'panel: po potwierdzeniu wyjście z formularza');
    // Enter w polu e-mail z błędem → ogłoszenie
    await p.goto(S + 'panel.html#szkoda'); await czekaj(p, 150); await nbFn(p);
    await p.fill('#sz-data', '2026-11-01'); await p.selectOption('#sz-rodzaj', { index: 1 }); await p.fill('#sz-tel', '512345678'); await p.fill('#sz-email', 'zly-adres');
    await p.focus('#sz-email'); await p.keyboard.press('Enter'); await czekaj(p, 150);
    const se = await p.evaluate(() => ({ al: nb0(document.querySelector('[data-bp-region="alert"]').textContent), d: document.getElementById('sz-email').getAttribute('aria-describedby') }));
    ok(se.al === 'Wpisz adres e-mail w formacie nazwa@domena.pl.' && /sz-email-err/.test(se.d), `panel: błąd e-maila ogłoszony przy Enter ${JSON.stringify(se)}`);
    await c.close();
  }

  // ---------- 3. Dam pracę: potwierdzenia, „Cofnij”, błędy przy polach, kod pocztowy, filtry w adresie ----------
  log('\n== 3. Dam pracę');
  {
    const c = await ctxNew(b, { zegar: true });
    const p = await open(c, 'dam-prace.html#szukam-moje', errs); await nbFn(p);
    for (const [nazwa, wykonaj, skutek, komunikat, karta] of [
      ['Usuń ogłoszenie', 'Usuwam ogłoszenie', 'Usunięcia nie można cofnąć', 'Ogłoszenia nie ma już na tablicy.', 't-sa-status'],
      ['Usuń konto', 'Usuwam konto', 'Usunięcia nie można cofnąć', 'Twojego konta i ogłoszenia już nie ma.', 't-sa-konto']]) {
      const det = p.locator(`section[aria-labelledby="${karta}"] details.mini`);
      ok(await det.count() === 1 && nb(await det.locator('summary').textContent()) === nazwa, `dam-prace: „${nazwa}” jako summary potwierdzenia`);
      await det.locator('summary').click(); await p.clock.runFor(50);
      ok(new RegExp(skutek).test(nb(await det.locator('.mini-body').textContent())), `dam-prace: „${nazwa}” – opis skutku`);
      await det.getByRole('button', { name: wykonaj }).click(); await p.clock.runFor(50);
      const r = await p.evaluate(k => { const sec = document.querySelector(`section[aria-labelledby="${k}"]`); const st = sec.querySelector('[data-status]'); return { hidden: sec.querySelector('details.mini').hidden, st: nb0(st.textContent), focus: document.activeElement === st }; }, karta);
      ok(r.hidden && r.st.startsWith(komunikat) && r.focus, `dam-prace: „${wykonaj}” ${JSON.stringify(r)}`);
    }
    await p.screenshot({ path: OUT + 'potw-dam-prace-usun-1280.png' });
    // „Zamknij” z „Cofnij”
    await p.goto(S + 'dam-prace.html#moje-ogloszenia'); await p.clock.runFor(150); await nbFn(p);
    const zamknij = p.locator('section[aria-labelledby="t-lista-moje"] button.js-row-action', { hasText: 'Zamknij' });
    await zamknij.click(); await p.clock.runFor(100);
    let u = await p.evaluate(() => { const tr = document.querySelector('section[aria-labelledby="t-lista-moje"] tbody tr'); const a = document.activeElement; return { badge: nb0(tr.querySelector('td[data-label="Status"]').textContent), btns: [...tr.querySelectorAll('.cell-actions .btn')].every(x => x.hidden), a: nb0(a.textContent), st: nb0(document.querySelector('section[aria-labelledby="t-lista-moje"] [data-status]').textContent) }; });
    ok(u.badge === 'Zamknięte' && u.btns && u.a === 'Cofnij: zamknięcie ogłoszenia Kosmetolog / kosmetolożka' && /jest zamknięte/.test(u.st), `dam-prace: „Zamknij” – stan i fokus na „Cofnij” ${JSON.stringify(u)}`);
    await p.screenshot({ path: OUT + 'potw-dam-prace-cofnij-1280.png' });
    await p.clock.runFor(20000);
    ok(await p.locator('.undo').count() === 1, 'dam-prace: czas „Cofnij” stoi, gdy przycisk ma fokus');
    await p.keyboard.press('Enter'); await p.clock.runFor(100);
    u = await p.evaluate(() => { const tr = document.querySelector('section[aria-labelledby="t-lista-moje"] tbody tr'); return { badge: nb0(tr.querySelector('td[data-label="Status"]').textContent), a: nb0(document.activeElement.textContent), undo: document.querySelectorAll('.undo').length, st: nb0(document.querySelector('section[aria-labelledby="t-lista-moje"] [data-status]').textContent) }; });
    ok(/^Opublikowane do 15\.11\.2026/.test(u.badge) && u.a === 'Zamknij: Kosmetolog / kosmetolożka' && u.undo === 0 && /znowu jest na tablicy/.test(u.st), `dam-prace: „Cofnij” przywraca stan i fokus ${JSON.stringify(u)}`);
    // „Usuń szkic”: po 10 s bez fokusu na „Cofnij” pasek znika
    await p.locator('button.js-row-action', { hasText: 'Usuń szkic' }).click(); await p.clock.runFor(100);
    await p.focus('#t-lista-moje').catch(() => p.evaluate(() => { document.body.focus(); document.activeElement.blur(); }));
    await p.evaluate(() => document.activeElement && document.activeElement.blur());
    await p.clock.runFor(10500);
    u = await p.evaluate(() => ({ undo: document.querySelectorAll('.undo').length, badge: nb0([...document.querySelectorAll('section[aria-labelledby="t-lista-moje"] tbody tr')][2].querySelector('td[data-label="Status"]').textContent) }));
    ok(u.undo === 0 && u.badge === 'Usunięty', `dam-prace: „Usuń szkic” – po 10 s bez cofnięcia ${JSON.stringify(u)}`);
    await c.close();

    const c2 = await ctxNew(b);
    const p2 = await open(c2, 'dam-prace.html#nowe-ogloszenie', errs); await nbFn(p2);
    // kod pocztowy: 5 cyfr bez „-” → 00-000; błędny – komunikat przy polu
    await p2.fill('#n-kod', '30001'); await p2.locator('#n-kod').blur();
    ok(await p2.inputValue('#n-kod') === '30-001', 'dam-prace: kod pocztowy 30001 → 30-001');
    await p2.fill('#n-kod', '301'); await p2.fill('#n-od', '90'); await p2.fill('#n-do', '60');
    await p2.click('#f-nowe button[type=submit]'); await czekaj(p2, 120);
    const fe = await p2.evaluate(() => { const g = id => document.getElementById(id); return { kod: [g('n-kod').getAttribute('aria-invalid'), g('n-kod').getAttribute('aria-describedby'), nb0(g('n-kod-err').textContent)], od: [g('n-od').getAttribute('aria-invalid'), g('n-od').getAttribute('aria-describedby')], do: [g('n-do').getAttribute('aria-invalid'), g('n-do').getAttribute('aria-describedby')], err: nb0(g('n-placa-err').textContent), a: document.activeElement.id }; });
    ok(fe.kod[0] === 'true' && /n-kod-err/.test(fe.kod[1]) && fe.kod[2] === 'Wpisz kod pocztowy: 5 cyfr, np. 30-001.' && fe.a === 'n-kod', `dam-prace: błąd kodu pocztowego przy polu ${JSON.stringify(fe.kod)}`);
    ok(fe.od[0] === 'true' && fe.do[0] === 'true' && /n-placa-err/.test(fe.od[1]) && /n-placa-err/.test(fe.do[1]) && /niższa niż kwota/.test(fe.err), `dam-prace: widełki – błąd przy obu polach ${JSON.stringify(fe)}`);
    // podgląd: kwoty przez Intl (6 000–7 500 zł)
    await p2.fill('#n-kod', ''); await p2.fill('#n-od', '6000'); await p2.fill('#n-do', '7500');
    await p2.click('#n-podglad'); await czekaj(p2, 100);
    ok(await p2.textContent('#pv-placa') === '6 000–7 500 zł', `dam-prace: podgląd widełek przez Intl „${await p2.textContent('#pv-placa')}”`);
    // okno zabiegów w formularzu: „Zapisz wybór zabiegów”
    await p2.click('#zab-nowe .zab-open'); await czekaj(p2, 100);
    ok(nb(await p2.textContent('#zab-nowe-dlg .zab-done')) === 'Zapisz wybór zabiegów', 'dam-prace: okno zabiegów – „Zapisz wybór zabiegów”');
    await p2.keyboard.press('Escape'); await czekaj(p2, 80);
    // „Zapisz szkic”: aria-disabled, fokus zostaje
    await p2.focus('#n-szkic'); await p2.keyboard.press('Enter'); await czekaj(p2, 120);
    const sk = await p2.evaluate(() => ({ a: document.activeElement.id, dis: document.getElementById('n-szkic').getAttribute('aria-disabled'), t: document.getElementById('n-szkic').textContent, al: nb0(document.querySelector('[data-bp-region="status"]').textContent) }));
    ok(sk.a === 'n-szkic' && sk.dis === 'true' && sk.t === 'Szkic zapisany' && sk.al === 'Szkic zapisany.', `dam-prace: „Zapisz szkic” ${JSON.stringify(sk)}`);
    // niezapisane zmiany: „Anuluj” pyta
    await p2.fill('#n-opis', 'Zmieniony opis stanowiska');
    // edycja po zapisaniu szkicu: przycisk znowu „Zapisz szkic” i aktywny (weryfikacja, runda 1 – stan sprzeczny ze strażnikiem zmian)
    const sk2 = await p2.evaluate(() => ({ dis: document.getElementById('n-szkic').getAttribute('aria-disabled'), t: document.getElementById('n-szkic').textContent, zm: document.getElementById('f-nowe').getAttribute('data-zmiany') }));
    ok(sk2.dis === null && sk2.t === 'Zapisz szkic' && sk2.zm === 'tak', `dam-prace: edycja po szkicu – „Zapisz szkic” znowu aktywny ${JSON.stringify(sk2)}`);
    let pyt = '';
    p2.once('dialog', dl => { pyt = dl.message(); dl.dismiss(); });
    await p2.click('#f-nowe a.link-quiet[href="#moje-ogloszenia"]'); await czekaj(p2, 120);
    ok(/niezapisane zmiany/.test(pyt) && await p2.evaluate(() => location.hash) === '#nowe-ogloszenie', 'dam-prace: „Anuluj” w nowym ogłoszeniu pyta o niezapisane zmiany');
    // „Zgłoś nadużycie” na ofercie: aria-disabled po wysłaniu, fokus zostaje
    await p2.evaluate(() => document.getElementById('f-nowe').removeAttribute('data-zmiany'));
    await p2.goto(S + 'dam-prace.html#oferta'); await czekaj(p2, 150);
    await p2.click('#zglos > summary'); await p2.fill('#z-opis', 'Ogłoszenie prosi o opłatę za szkolenie wstępne.'); await p2.check('#z-wiara');
    await p2.focus('#f-zglos button[type=submit]'); await p2.keyboard.press('Enter'); await czekaj(p2, 150);
    const zg = await p2.evaluate(() => { const bt = document.querySelector('#f-zglos button[type=submit]'); return { a: document.activeElement === bt, dis: bt.getAttribute('aria-disabled'), st: !document.querySelector('#f-zglos .js-report-status').hidden }; });
    ok(zg.a && zg.dis === 'true' && zg.st, `dam-prace: „Wyślij zgłoszenie” – aria-disabled, fokus zostaje ${JSON.stringify(zg)}`);
    // filtry w adresie: zapis i odczyt
    await p2.goto(S + 'dam-prace.html#oferty'); await czekaj(p2, 150);
    await p2.evaluate(() => { document.getElementById('filtry-panel').open = true; });
    await p2.check('#f-filtry input[name=zawod][value=fryzjer]', { force: true }); await czekaj(p2, 80);
    ok(/[?&]zawod=fryzjer(&|#|$)/.test(await p2.evaluate(() => location.search + location.hash)) && await p2.evaluate(() => location.hash) === '#oferty', `dam-prace: filtr w adresie (${await p2.evaluate(() => location.search)})`);
    await p2.goto(S + 'dam-prace.html?zawod=fryzjer&wojewodztwo=pomorskie#oferty'); await czekaj(p2, 150);
    const fl = await p2.evaluate(() => ({ vis: [...document.querySelectorAll('#lista-ofert > .offer')].filter(o => !o.hidden).length, r: document.querySelector('#f-filtry input[name=zawod]:checked').value, w: document.getElementById('f-woj').value }));
    ok(fl.vis === 1 && fl.r === 'fryzjer' && fl.w === 'pomorskie', `dam-prace: filtry z adresu przy wejściu ${JSON.stringify(fl)}`);
    await c2.close();
  }

  // ---------- 4. Szkolenia: kod pocztowy, liczba miejsc, nadużycie, Zrezygnuj + Cofnij, Zwróć, zakładki i filtry w adresie ----------
  log('\n== 4. Szkolenia');
  {
    const c = await ctxNew(b);
    const p = await open(c, 'szkolenia.html#zamowienie', errs); await nbFn(p);
    await p.check('#kup-osoba', { force: true }); await p.fill('#fv-kod', '00002'); await p.check('#zg-reg', { force: true });
    await p.click('#zam-dane button[type=submit]'); await czekaj(p, 150);
    const kd = await p.evaluate(() => ({ v: document.getElementById('fv-kod').value, err: document.getElementById('fv-kod-err').hidden, hash: location.hash }));
    ok(kd.v === '00-002' && kd.err && kd.hash === '#zam-platnosc', `szkolenia: kod pocztowy 00002 przyjęty jako 00-002 (iOS) ${JSON.stringify(kd)}`);
    // liczba miejsc
    await p.goto(S + 'szkolenia.html#organizator'); await czekaj(p, 150); await nbFn(p);
    await p.click('summary:has-text("Zmień liczbę miejsc")');
    for (const [v, oczek] of [['', 'Wpisz liczbę miejsc od 7 do 200.'], ['300', 'Szkolenie może mieć najwyżej 200 miejsc.'], ['5', 'Liczba miejsc nie może być mniejsza niż 7 – tyle osób jest już zapisanych.']]) {
      await p.fill('#cap-1', v); await p.focus('#cap-1'); await p.keyboard.press('Enter'); await czekaj(p, 120);
      const r = await p.evaluate(() => ({ err: nb0(document.getElementById('cap-1-err').textContent), vis: !document.getElementById('cap-1-err').hidden, d: document.getElementById('cap-1').getAttribute('aria-describedby'), al: nb0(document.querySelector('[data-bp-region="alert"]').textContent) }));
      ok(r.vis && r.err === oczek && /cap-1-err/.test(r.d) && r.al === oczek, `szkolenia: liczba miejsc „${v}” → ${JSON.stringify(r)}`);
    }
    await p.fill('#cap-1', '14'); await p.click('.js-capacity button[type=submit]'); await czekaj(p, 150);
    ok(/Liczba miejsc: 14\./.test(nb(await p.textContent('.js-capacity [role=status]'))) && await p.evaluate(() => document.getElementById('cap-1-err').hidden), 'szkolenia: poprawna liczba miejsc – komunikat statusu, bez błędu');
    // „Adresaci” – grupa z nazwą
    await p.goto(S + 'szkolenia.html#dodaj'); await czekaj(p, 120);
    ok(await p.getByRole('group', { name: 'Adresaci' }).count() === 1, 'szkolenia: grupa radio „Adresaci” ma nazwę (fieldset/legend)');
    // „Zgłoś nadużycie”
    await p.goto(S + 'szkolenia.html#szkolenie'); await czekaj(p, 120); await nbFn(p);
    await p.click('#zglos > summary'); await p.click('#f-abuse button[type=submit]'); await czekaj(p, 120);
    let ab = await p.evaluate(() => ({ err: nb0(document.getElementById('ab-powod-err').textContent), d: document.getElementById('ab-powod').getAttribute('aria-describedby'), a: document.activeElement.id }));
    ok(ab.err === 'Wybierz powód zgłoszenia z listy.' && /ab-powod-err/.test(ab.d) && ab.a === 'ab-powod', `szkolenia: błąd przy polu „Powód” ${JSON.stringify(ab)}`);
    await p.selectOption('#ab-powod', { index: 1 }); await p.focus('#f-abuse button[type=submit]'); await p.keyboard.press('Enter'); await czekaj(p, 150);
    ab = await p.evaluate(() => { const bt = document.querySelector('#f-abuse button[type=submit]'); return { a: document.activeElement === bt, dis: bt.getAttribute('aria-disabled'), ok: !document.getElementById('ab-ok').hidden }; });
    ok(ab.a && ab.dis === 'true' && ab.ok, `szkolenia: zgłoszenie wysłane – aria-disabled, fokus zostaje ${JSON.stringify(ab)}`);
    // zakładki „Moje szkolenia”: adres po kliknięciu i deep link
    await p.goto(S + 'szkolenia.html#moje-szkolenia'); await czekaj(p, 150);
    await p.click('#t-zam-tab'); await czekaj(p, 60);
    ok(await p.evaluate(() => location.hash) === '#p-zam', 'szkolenia: kliknięcie zakładki zmienia adres (#p-zam)');
    await p.goto(S + 'szkolenia.html#p-rez'); await czekaj(p, 150);
    ok(await p.evaluate(() => document.getElementById('t-rez-tab').getAttribute('aria-selected')) === 'true', 'szkolenia: #p-rez otwiera „Listę rezerwową”');
    // „Zrezygnuj” + „Cofnij”
    await p.goto(S + 'szkolenia.html#moje-szkolenia'); await czekaj(p, 150); await nbFn(p);
    await p.click('#t-nad'); await czekaj(p, 50);
    const zr = p.locator('#p-nad li[data-reg] .js-cancel').first();
    await zr.click(); await czekaj(p, 120);
    let zz = await p.evaluate(() => ({ badge: document.querySelector('#p-nad li[data-reg] [data-status]').textContent, a: nb0(document.activeElement.textContent), live: nb0(document.querySelector('#moje-szkolenia .js-live p').textContent) }));
    ok(zz.badge === 'Zrezygnowano' && /^Cofnij: rezygnacja z zapisu na „Obsługa klientki/.test(zz.a) && /^Zrezygnowano z zapisu/.test(zz.live), `szkolenia: „Zrezygnuj” – fokus na „Cofnij” ${JSON.stringify(zz)}`);
    await p.keyboard.press('Enter'); await czekaj(p, 100);
    zz = await p.evaluate(() => ({ badge: document.querySelector('#p-nad li[data-reg] [data-status]').textContent, a: nb0(document.activeElement.textContent), btn: !document.querySelector('#p-nad li[data-reg] .js-cancel').hidden }));
    ok(zz.badge === 'Zapisano' && /^Zrezygnuj/.test(zz.a) && zz.btn, `szkolenia: „Cofnij” przywraca zapis ${JSON.stringify(zz)}`);
    // „Zrezygnuj” na stronie szkolenia (#zapisano) przy niskim oknie: „Cofnij” i opis czasu w całości w oknie po wpisaniu statusu
    // (weryfikacja, runda 1: przycisk z fokusem zjeżdżał w dół o 30–140 px pod krawędź okna – 320×568, 320×640, 390×664, 768×700)
    for (const [vw, vh] of [[320, 568], [320, 640], [390, 664], [768, 700]]) {
      const cz = await ctxNew(b, { w: vw, h: vh });
      const pz = await open(cz, 'szkolenia.html#zapisano', errs);
      await pz.locator('#zapisano .js-cancel').click(); await czekaj(pz, 250);
      const poz = await pz.evaluate(() => { const bar = document.querySelector('#zapisano .undo'), a = document.activeElement;
        if (!bar) { return null; } const r = bar.getBoundingClientRect(), h = document.querySelector('.topbar, header');
        return { top: Math.round(r.top), bottom: Math.round(r.bottom), vh: innerHeight, fokus: bar.contains(a), belka: h ? Math.round(Math.max(0, h.getBoundingClientRect().bottom)) : 0 }; });
      ok(poz && poz.fokus && poz.bottom <= poz.vh && poz.top >= poz.belka, `szkolenia#zapisano ${vw}×${vh}: „Cofnij” z opisem w oknie ${JSON.stringify(poz)}`);
      await cz.close();
    }
    // runda 2 weryfikacji: po akcji odwracalnej w oknie jest komunikat statusu (≥ 90% wysokości, pod paskiem górnym) i cały pasek
    // „Cofnij” – dam-prace #moje-ogloszenia (oba wiersze: Zamknij, Usuń szkic) i szkolenia #moje-szkolenia (Zrezygnuj), 4 rozmiary okna
    // (dawniej bar.scrollIntoView({block:'nearest'}) stawiał pasek tuż pod paskiem górnym, a status zostawał nad krawędzią okna: 0–18%)
    for (const [vw, vh] of [[320, 640], [390, 844], [768, 1024], [1280, 900]]) {
      for (const [url, przed, przycisk] of [
        ['dam-prace.html#moje-ogloszenia', null, ['section[aria-labelledby="t-lista-moje"] button.js-row-action', 'Zamknij']],
        ['dam-prace.html#moje-ogloszenia', null, ['section[aria-labelledby="t-lista-moje"] button.js-row-action', 'Usuń szkic']],
        ['szkolenia.html#moje-szkolenia', '#t-nad', ['#p-nad li[data-reg] .js-cancel', null]]]) {
        const cw = await ctxNew(b, { w: vw, h: vh });
        const pw = await open(cw, url, errs);
        if (przed) { await pw.click(przed); await czekaj(pw, 60); }
        const loc = przycisk[1] ? pw.locator(przycisk[0], { hasText: przycisk[1] }).first() : pw.locator(przycisk[0]).first();
        await loc.click(); await czekaj(pw, 300);
        const w = await pw.evaluate(() => {
          const bar = document.querySelector('.undo'); if (!bar) { return null; }
          const st = bar.previousElementSibling, r = st.getBoundingClientRect(), rb = bar.getBoundingClientRect();
          let belka = 0; document.querySelectorAll('.topbar, .pub-header').forEach((h) => { const p = getComputedStyle(h).position, q = h.getBoundingClientRect(); if ((p === 'sticky' || p === 'fixed') && q.top < 1 && q.bottom > belka) { belka = q.bottom; } });
          const wid = Math.max(0, Math.min(r.bottom, innerHeight) - Math.max(r.top, belka));
          return { st: Math.round(100 * wid / Math.max(1, r.height)), barTop: Math.round(rb.top), barBottom: Math.round(rb.bottom), vh: innerHeight, belka: Math.round(belka), fokus: bar.contains(document.activeElement) };
        });
        ok(w && w.fokus && w.st >= 90 && w.barBottom <= w.vh && w.barTop >= w.belka, `${url} „${przycisk[1] || 'Zrezygnuj'}” ${vw}×${vh}: status i „Cofnij” w oknie ${JSON.stringify(w)}`);
        if (vw === 1280 && przycisk[1] === 'Usuń szkic') { await pw.screenshot({ path: OUT + 'potw-cofnij-usun-szkic-1280.png' }); }
        await cw.close();
      }
    }
    // „Zwróć 390,00 zł”: dwa kroki, Intl
    await p.goto(S + 'szkolenia.html#wyplaty'); await czekaj(p, 150); await nbFn(p);
    const zw = p.locator('summary', { hasText: 'Zwróć 390,00' });
    ok(await zw.count() === 1, 'szkolenia: „Zwróć 390,00 zł” jako summary potwierdzenia');
    await zw.click(); await czekaj(p, 60);
    const zwBody = zw.locator('xpath=..').locator('.mini-body');
    ok(/Zlecenia zwrotu nie można cofnąć/.test(nb(await zwBody.textContent())), 'szkolenia: opis skutku zwrotu');
    await zwBody.locator('button[type=submit]').click(); await czekaj(p, 120);
    const zs = await p.evaluate(() => ({ st: document.activeElement.textContent, role: document.activeElement.getAttribute('role') }));
    ok(zs.role === 'status' && zs.st.startsWith('Zwrot 390,00 zł zlecony'), `szkolenia: zwrot zlecony, kwota przez Intl ${JSON.stringify(zs)}`);
    // filtry katalogu w adresie (?rola zostaje)
    await p.goto(S + 'szkolenia.html?rola=pracownik#katalog'); await czekaj(p, 150);
    await p.selectOption('#fl-temat', 'techniki'); await czekaj(p, 80);
    const q = await p.evaluate(() => location.search + location.hash);
    ok(/rola=pracownik/.test(q) && /temat=techniki/.test(q) && /#katalog$/.test(q), `szkolenia: filtr w adresie, ?rola zostaje (${q})`);
    await p.goto(S + 'szkolenia.html?forma=online#katalog'); await czekaj(p, 150);
    const fo = await p.evaluate(() => ({ vis: [...document.querySelectorAll('#lista-szkolen > .tr')].filter(r => !r.hidden).map(r => r.getAttribute('data-format')), ch: document.getElementById('fl-online').checked }));
    ok(fo.ch && fo.vis.length === 2 && fo.vis.every(f => f === 'online'), `szkolenia: filtr z adresu przy wejściu ${JSON.stringify(fo)}`);
    // polskie formaty
    const fm = await p.evaluate(() => [bpStrefa.kwota(1234.5), bpStrefa.data(new Date(2026, 11, 3)), bpStrefa.godzina(new Date(2026, 11, 3, 9, 5)), bpStrefa.zakresKwot(60, 90)]);
    ok(JSON.stringify(fm) === JSON.stringify(['1 234,50 zł', '3.12.2026', '9:05', '60–90 zł']), `strefa.js: formaty pl-PL ${JSON.stringify(fm)}`);
    await c.close();
  }

  // ---------- 5. axe (WCAG 2.2 AA) i przewijanie w poziomie na głównych ekranach (320 i 1280 px) ----------
  log('\n== 5. axe i przewijanie w poziomie');
  const EKRANY = {
    'logowanie.html': ['s-email', 's-kod', 's-sms', 's-stany', 's-rej', 's-rp-firma', 's-rej-stany'],
    'panel.html': ['pulpit', 'polisy', 'szkoda', 'zespol', 'ustawienia', 'pracownik'],
    'dam-prace.html': ['oferty', 'oferta', 'moje-ogloszenia', 'nowe-ogloszenie', 'szukam-pracy', 'sp-wiadomosc', 'szukam-dodaj', 'szukam-moje', 'wlacz-dam-prace'],
    'szkolenia.html': ['katalog', 'szkolenie', 'szkolenie-platne', 'zamowienie', 'moje-szkolenia', 'organizator', 'wyplaty', 'dodaj', 'uczestnicy']
  };
  for (const w of [320, 1280]) {
    const c = await ctxNew(b, { w, h: w < 800 ? 740 : 900 });
    for (const [f, ids] of Object.entries(EKRANY)) {
      const p = await open(c, f, errs);
      for (const id of ids) {
        await p.goto(S + f + '#' + id); await czekaj(p, 120);
        // potwierdzenia otwarte – axe sprawdza też ich treść
        await p.evaluate(() => document.querySelectorAll('.view.is-active details.mini, .screen.is-active details.mini').forEach(d => { d.open = true; }));
        const r = await p.evaluate(poziomo);
        ok(r.sw <= r.cw, `${f}#${id} ${w}px: przewijanie w poziomie ${r.sw} > ${r.cw}`);
        await axe(p, `${f}#${id} ${w}px`, null);
        // tabele w widoku: .table-wrap bez przewijania w poziomie (znaczki statusu i długie dane łamią się w układzie .stack; weryfikacja,
        // runda 1 – „Kończy się za 49 dni”, „Zaproszenie oczekuje” wychodziły poza kartę przy 320–375 px)
        const tw = await p.evaluate(tabeleSzersze);
        ok(!tw.length, `${f}#${id} ${w}px: .table-wrap – przewijanie / region z fokusem: ${JSON.stringify(tw)}`);
        // wszystkie zakładki widoku (nie tylko domyślna): tabele i axe w panelu każdej zakładki
        const zak = await p.evaluate(() => [...document.querySelectorAll('.view.is-active [role="tab"], .screen.is-active [role="tab"]')]
          .filter((t) => t.offsetParent && t.getAttribute('aria-selected') !== 'true').map((t) => t.id));
        for (const tid of zak) {
          await p.click('#' + tid); await czekaj(p, 80);
          const pid = await p.evaluate((i) => document.getElementById(i).getAttribute('aria-controls'), tid);
          await p.evaluate((i) => document.querySelectorAll('#' + i + ' details.mini').forEach(d => { d.open = true; }), pid);
          const t2 = await p.evaluate(tabeleSzersze);
          ok(!t2.length, `${f}#${id} → zakładka ${tid} ${w}px: .table-wrap – przewijanie / region z fokusem: ${JSON.stringify(t2)}`);
          const r2 = await p.evaluate(poziomo);
          ok(r2.sw <= r2.cw, `${f}#${id} → zakładka ${tid} ${w}px: przewijanie w poziomie ${r2.sw} > ${r2.cw}`);
          await axe(p, `${f}#${id} → zakładka ${tid} ${w}px`, ['#' + pid]);
        }
      }
      await p.close();
    }
    await c.close();
  }
  // długi tytuł od użytkownika (85 znaków bez spacji) – bez przewijania w poziomie
  const DLUGI = 'Kosmetolożkakosmetologkosmetolożkakosmetologkosmetolożkakosmetologkosmetolożkakosmetol';
  for (const w of [320, 768, 1280]) {
    const c = await ctxNew(b, { w, h: 800 });
    for (const [f, h, sel] of [['dam-prace.html', 'oferty', '#lista-ofert .offer h3 a'], ['dam-prace.html', 'oferta', '#t-oferta'], ['dam-prace.html', 'moje-ogloszenia', 'section[aria-labelledby="t-lista-moje"] tbody th .cell a'], ['szkolenia.html', 'katalog', '#lista-szkolen .tr h3 a'], ['szkolenia.html', 'szkolenie', '#t-szk']]) {
      const p = await open(c, f + '#' + h, errs);
      await p.evaluate(([s, t]) => { const e = document.querySelector(s); e.textContent = t; const cr = document.querySelector('.view.is-active .crumbs li[aria-current]'); if (cr) { cr.textContent = t; } }, [sel, DLUGI]);
      await czekaj(p, 60);
      const r = await p.evaluate(poziomo);
      ok(r.sw <= r.cw, `${f}#${h} ${w}px: długi tytuł rozpycha stronę ${r.sw} > ${r.cw}`);
      await p.close();
    }
    await c.close();
  }
  // szerokości 320–1440 na ekranach z potwierdzeniami i „Cofnij”
  for (const w of [320, 360, 390, 768, 1024, 1440]) {
    const c = await ctxNew(b, { w, h: 800 });
    for (const u of ['panel.html#zespol', 'dam-prace.html#szukam-moje', 'dam-prace.html#moje-ogloszenia', 'szkolenia.html#wyplaty', 'szkolenia.html#moje-szkolenia', 'logowanie.html#s-kod']) {
      const p = await open(c, u, errs);
      await p.evaluate(() => document.querySelectorAll('.view.is-active details.mini').forEach(d => { d.open = true; }));
      const zam = p.locator('.view.is-active button.js-row-action', { hasText: 'Zamknij' }).first();
      if (await zam.count() && await zam.isVisible()) { await zam.click(); }
      const zr = p.locator('.view.is-active #p-nad .js-cancel').first();
      if (await zr.count() && await zr.isVisible()) { await zr.click(); }
      await czekaj(p, 80);
      const r = await p.evaluate(poziomo);
      ok(r.sw <= r.cw, `${u} ${w}px: przewijanie w poziomie ${r.sw} > ${r.cw}`);
      if (w === 390) { await p.screenshot({ path: OUT + 'potw-' + u.replace(/[^a-z-]+/g, '-') + '-390.png' }); }
      await p.close();
    }
    await c.close();
  }

  ok(!errs.length, 'błędy JS: ' + JSON.stringify(errs.slice(0, 5)));
  await b.close();
  log('\nasercji: ' + N);
  log('\n=== PODSUMOWANIE: ' + (FAIL.length ? FAIL.length + ' niepowodzeń\n' + FAIL.join('\n') : 'wszystkie asercje OK'));
  process.exit(FAIL.length ? 1 : 0);
})().catch(e => { console.error('SKRYPT', e); process.exit(2); });
