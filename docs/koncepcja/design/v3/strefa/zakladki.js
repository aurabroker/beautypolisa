/* =====================================================================
   BeautyPolisa · Strefa Klienta · „Zakładki w Strefie” (makieta v3)
   Prośba zleceniodawcy (16.11.2026): w Ustawieniach salonu włącz / wyłącz zakładki „Praca” (Dam pracę i Szukam pracy)
   i „Szkolenia” – np. salon prowadzony przez jedną albo dwie osoby ukrywa „Pracę”, bo z niej nie korzysta.

   PREFERENCJA WIDOKU, NIE KONTROLA DOSTĘPU. Ukryta zakładka znika w Strefie tego salonu – dla wszystkich jego członków –
   tylko jako wejście do modułu: pozycja menu (pasek boczny i szuflada), kafel na pulpicie i skróty. Moduły „Dam pracę”,
   „Szukam pracy” i „Szkolenia” zostają w pełni wdrożone: bezpośredni adres działa (u góry informacja „Zakładka … jest ukryta
   w ustawieniach salonu”, właściciel ma przycisk „Pokaż zakładkę”), aktywne ogłoszenia zostają opublikowane, kontakty od
   kandydatów dochodzą, zapisy i opłacone zamówienia na szkolenia są bez zmian, e-maile modułów wychodzą. Publiczne /dam-prace
   i katalog /szkolenia – bez zmian. Globalny przełącznik szukam_pracy (11 §11.9.6, app_feature_flags) jest osobny i ma
   pierwszeństwo: wyłączony usuwa „Szukam pracy” niezależnie od tej preferencji (wtedy przełącznik nazywa się „Praca – Dam pracę”).

   Produkcja: preferencja na koncie salonu (client_accounts.ukryte_zakladki), zmienia ją tylko właściciel funkcją
   app_client_set_tab_visibility() (idempotentna, wpis w client_audit_log); serwer renderuje menu i pulpit już bez ukrytych
   wejść, więc działa to też bez JS. RLS i funkcje modułów – bez zmian.

   Makieta: stan w localStorage (klucz bp-strefa-zakladki, każdy dostęp w try/catch – bez pamięci przeglądarki stan trwa do
   przeładowania strony), wspólny dla panel.html, dam-prace.html i szkolenia.html (ten plik dołączają wszystkie trzy).
   Atrybut html[data-ukryte] ustawia wcześniej skrypt w <head> tych stron – także z adresu ?zakladki=bez-pracy, bez-szkolen,
   bez-pracy,bez-szkolen albo wszystkie (zapisuje stan) – a CSS (strefa.css) ukrywa elementy [data-zakladka]. Wariant pracownika:
   ?rola=pracownik albo „Pulpit pracownika” (przełączniki tylko do odczytu, linki Strefy niosą rolę). Bez JS – wszystko widoczne.
   ===================================================================== */
(function () {
  'use strict';
  var KLUCZ = 'bp-strefa-zakladki';
  var ZAKLADKI = ['praca', 'szkolenia'];
  var NAZWA = { praca: 'Praca', szkolenia: 'Szkolenia' };
  var PELNA = { praca: 'Praca (Dam pracę i Szukam pracy)', szkolenia: 'Szkolenia' };
  var OSOBA = 'Anna Przykładowa';                                                     // właścicielka konta w makiecie
  var DZIS = { iso: '2026-11-12', krotko: '12.11.2026', dlugo: '12 listopada 2026 r.' };   // „dziś” makiety
  var root = document.documentElement, body = document.body;
  var EMPL = /[?&]rola=pracownik(&|$)/.test(location.search);
  function all(sel, ctx) { return Array.prototype.slice.call((ctx || document).querySelectorAll(sel)); }
  function znane(lista) { return (Array.isArray(lista) ? lista : []).filter(function (t, i, a) { return ZAKLADKI.indexOf(t) > -1 && a.indexOf(t) === i; }); }

  /* ---------- stan: html[data-ukryte] (źródło prawdy dla tej strony) + localStorage (między stronami) ---------- */
  var pamiec = null;   // zapas na czas życia strony, gdy localStorage jest niedostępny
  function wczytaj() {
    try { var s = JSON.parse(localStorage.getItem(KLUCZ)); if (s && typeof s === 'object') { return s; } } catch (e) { /* brak pamięci */ }
    return pamiec || {};
  }
  function zapisz(s) {
    pamiec = s;
    try { localStorage.setItem(KLUCZ, JSON.stringify(s)); } catch (e) { /* brak pamięci – stan do przeładowania strony */ }
  }
  function ukryte() { return znane((root.getAttribute('data-ukryte') || '').split(' ')); }
  function widoczna(t) { return ukryte().indexOf(t) < 0; }
  function rola() { return body.getAttribute('data-role') === 'employee' ? 'employee' : 'owner'; }

  /* zmiana – tylko właściciel (w produkcji sprawdza to funkcja w bazie); idempotentna: bez zmiany stanu nie ma wpisu w historii */
  function ustaw(t, widac) {
    if (ZAKLADKI.indexOf(t) < 0 || widoczna(t) === !!widac) { return false; }
    var u = ukryte().filter(function (x) { return x !== t; });
    if (!widac) { u.push(t); }
    u.sort(function (a, b) { return ZAKLADKI.indexOf(a) - ZAKLADKI.indexOf(b); });
    var s = wczytaj();
    s.ukryte = u;
    s.log = (Array.isArray(s.log) ? s.log : []).concat([{ t: t, v: !!widac }]).slice(-10);
    zapisz(s);
    root.setAttribute('data-ukryte', u.join(' '));
    odswiez();
    historia();
    return true;
  }

  /* ---------- „Historia konta” (panel.html): wpisy ze zmian zakładek, najnowszy na górze ---------- */
  function opis(w) { return (w.v ? 'Pokazano' : 'Ukryto') + ' zakładkę ' + PELNA[w.t] + ' w Strefie salonu'; }
  function historia() {
    var tb = document.querySelector('#historia tbody'), mini = document.querySelector('[data-historia-mini]');
    if (!tb && !mini) { return; }
    var s = wczytaj(), log = (Array.isArray(s.log) ? s.log : []).filter(function (w) { return w && NAZWA[w.t]; });
    all('[data-zak-wpis]').forEach(function (n) { n.parentNode.removeChild(n); });
    log.forEach(function (w) {
      if (tb) {
        var tr = document.createElement('tr');
        tr.setAttribute('data-zak-wpis', '');
        tr.innerHTML = '<td data-label="Data"><time datetime="' + DZIS.iso + '">' + DZIS.krotko + '</time></td><td data-label="Zdarzenie"></td><td data-label="Osoba"></td>';
        tr.children[1].textContent = opis(w);
        tr.children[2].textContent = OSOBA;
        tb.insertBefore(tr, tb.firstChild);
      }
      if (mini) {
        var li = document.createElement('li');
        li.setAttribute('data-zak-wpis', '');
        li.innerHTML = '<div class="grow"><strong></strong><span class="meta"><time datetime="' + DZIS.iso + '">' + DZIS.dlugo + '</time> · ' + OSOBA + '</span></div>';
        li.querySelector('strong').textContent = opis(w);
        mini.insertBefore(li, mini.firstChild);
      }
    });
  }

  /* ---------- makieta: wariant pracownika – linki Strefy niosą rolę między stronami (?rola=pracownik) ---------- */
  function przepnijLinki() {
    var emp = rola() === 'employee';
    all('.sidenav a, .account-panel a, .crumbs a, .topbar a.brand').forEach(function (a) {
      if (!a.hasAttribute('data-href0')) { a.setAttribute('data-href0', a.getAttribute('href') || ''); }
      var h = a.getAttribute('data-href0'), w = h, m = /^(panel|dam-prace|szkolenia)\.html(#.*)?$/.exec(h);
      if (emp) {
        if (h === '#pulpit' || h === 'panel.html#pulpit') { w = (m ? 'panel.html' : '') + '#pracownik'; }
        else if (h === '#ustawienia' || h === '#zakladki') { w = '?rola=pracownik' + h; }
        else if (m) { w = m[1] + '.html?rola=pracownik' + (m[2] || ''); }
      } else if (EMPL && (h === '#ustawienia' || h === '#zakladki')) {
        w = 'panel.html' + h;   // właściciel na adresie z ?rola=pracownik – Ustawienia bez parametru roli
      }
      if (w !== a.getAttribute('href')) { a.setAttribute('href', w); }
    });
  }

  /* ---------- odświeżenie: przełączniki w Ustawieniach, informacje na stronach modułów ---------- */
  var przel = all('input[data-zakladka-przelacznik]');
  przel.forEach(function (inp) { inp.setAttribute('data-opis', inp.getAttribute('aria-describedby') || ''); });
  function odswiez() {
    var emp = rola() === 'employee';
    przel.forEach(function (inp) {
      var t = inp.value, on = widoczna(t), stan = document.getElementById(inp.id + '-stan');
      inp.checked = on;
      inp.disabled = emp;                                   // pracownik: tylko do odczytu
      if (stan) { stan.textContent = on ? 'Widoczna' : 'Ukryta'; }
      var d = inp.getAttribute('data-opis').split(' ').filter(Boolean);
      if (emp && document.getElementById('zak-ro')) { d.push('zak-ro'); }
      if (d.length) { inp.setAttribute('aria-describedby', d.join(' ')); } else { inp.removeAttribute('aria-describedby'); }
    });
    all('[data-zakladka-uwaga]').forEach(function (box) {
      var t = box.getAttribute('data-zakladka-uwaga'), f = box.querySelector('form'), ok = box.querySelector('.tab-note-ok');
      if (!widoczna(t) && box.classList.contains('is-done')) {   // ukryta ponownie (np. w innej karcie) – znowu informacja
        box.classList.remove('is-done'); if (f) { f.hidden = false; } if (ok) { ok.hidden = true; }
      }
    });
    przepnijLinki();
  }

  /* przełączniki: zmiana od razu, bez okna potwierdzenia (to nie jest operacja niebezpieczna); komunikat w aria-live */
  var live = document.getElementById('zak-live');
  przel.forEach(function (inp) {
    inp.addEventListener('change', function () {
      var t = inp.value;
      if (rola() === 'employee') { inp.checked = widoczna(t); return; }
      if (ustaw(t, inp.checked) && live) {
        live.textContent = inp.checked ? 'Zakładka ' + NAZWA[t] + ' jest widoczna w menu i na pulpicie.' : 'Zakładka ' + NAZWA[t] + ' jest ukryta. Włączysz ją tutaj.';
      }
    });
  });
  all('form[data-zakladki-form]').forEach(function (f) {   // „Zapisz” jest tylko bez JS – z JS zmiana zapisuje się od razu
    f.addEventListener('submit', function (e) { e.preventDefault(); });
  });

  /* „Pokaż zakładkę” w informacji na stronie modułu (właściciel): zakładka wraca do menu, fokus na potwierdzeniu */
  all('[data-zakladka-uwaga]').forEach(function (box) {
    var t = box.getAttribute('data-zakladka-uwaga'), f = box.querySelector('form'), ok = box.querySelector('.tab-note-ok');
    if (!f) { return; }
    f.addEventListener('submit', function (e) {
      e.preventDefault();
      if (rola() === 'employee') { return; }
      ustaw(t, true);
      box.classList.add('is-done');
      f.hidden = true;
      if (ok) { ok.hidden = false; ok.focus(); }
    });
  });

  /* zmiana w innej karcie tej samej przeglądarki */
  window.addEventListener('storage', function (e) {
    if (e.key !== KLUCZ && e.key !== null) { return; }
    root.setAttribute('data-ukryte', znane(wczytaj().ukryte).join(' '));
    odswiez();
    historia();
  });
  /* rola zmienia się z widokiem (panel.html: „Pulpit pracownika”) – przełączniki i linki za nią */
  if (window.MutationObserver) { new MutationObserver(odswiez).observe(body, { attributes: true, attributeFilter: ['data-role'] }); }

  odswiez();
  historia();
})();
