/* =====================================================================
   BeautyPolisa · Strefa Klienta · „Zakładki w Strefie” (makieta v3)
   Prośba zleceniodawcy (16.11.2026): w Ustawieniach salonu włącz / wyłącz zakładki „Praca” (Dam pracę i Szukam pracy)
   i „Szkolenia” – np. salon prowadzony przez jedną albo dwie osoby ukrywa „Pracę”, bo z niej nie korzysta.

   PREFERENCJA WIDOKU, NIE KONTROLA DOSTĘPU. Ukryta zakładka znika w Strefie tego salonu – dla wszystkich jego członków –
   tylko jako wejście do modułu: pozycja menu (menu boczne i szuflada), kafel na pulpicie i skróty. Moduły „Dam pracę”,
   „Szukam pracy” i „Szkolenia” zostają w pełni wdrożone: bezpośredni adres działa (u góry informacja „Zakładka … jest ukryta
   w ustawieniach salonu”, właściciel ma przycisk „Pokaż zakładkę”), aktywne ogłoszenia zostają opublikowane, kontakty od
   kandydatów dochodzą, zapisy i opłacone zamówienia na szkolenia są bez zmian, e-maile modułów wychodzą. Publiczne /dam-prace
   i katalog /szkolenia – bez zmian. Globalny przełącznik szukam_pracy (11 §11.9.6, app_feature_flags) jest osobny i ma
   pierwszeństwo: wyłączony usuwa „Szukam pracy” niezależnie od tej preferencji (wtedy przełącznik nazywa się „Praca – Dam pracę”,
   a wpis w „Historii konta” – „… zakładkę Praca (Dam pracę) …”; makieta: ?szukam=wylaczone w panel.html).

   Produkcja: preferencja na koncie salonu (client_accounts.ukryte_zakladki), zmienia ją tylko właściciel funkcją
   app_client_set_tab_visibility() (idempotentna, wpis w client_audit_log); serwer renderuje menu i pulpit już bez ukrytych
   wejść, więc działa to też bez JS. RLS i funkcje modułów – bez zmian.

   Makieta: stan w localStorage (klucz bp-strefa-zakladki, każdy dostęp w try/catch – bez pamięci przeglądarki stan trwa do
   przeładowania strony), wspólny dla panel.html, dam-prace.html i szkolenia.html (ten plik dołączają wszystkie trzy).
   Atrybut html[data-ukryte] ustawia wcześniej skrypt w <head> tych stron – także z adresu ?zakladki=bez-pracy, bez-szkolen,
   bez-pracy,bez-szkolen albo wszystkie (zapisuje stan) – a CSS (strefa.css) ukrywa elementy [data-zakladka]. Wariant pracownika:
   ?rola=pracownik albo „Pulpit pracownika” (przełączniki tylko do odczytu, linki Strefy niosą rolę). Parametr ?zakladki= działa
   raz: skrypt w <head> zapisuje stan i usuwa parametr z adresu (history.replaceState, z zachowaniem ?rola i #kotwicy), więc
   odświeżenie strony pokazuje stan zapisany, a nie ten z linku. Informację o ukrytej zakładce skrypt przenosi na początek
   aktywnego ekranu modułu, a przy kotwicy stanu ([data-trasa]) – tuż przed kartę z celem (umiescUwagi). Bez JS – wszystko widoczne.
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
  /* makieta: globalny przełącznik szukam_pracy wyłączony (11.9.6) – ?szukam=wylaczone. Ma pierwszeństwo przed preferencją salonu:
     „Szukam pracy” znika (CSS: [data-szukam-pracy]), zakładka salonu to „Praca – Dam pracę”, wpis w historii bez „Szukam pracy” */
  if (/[?&]szukam=wylaczone(&|$)/.test(location.search)) { root.setAttribute('data-szukam', 'wylaczone'); PELNA.praca = 'Praca (Dam pracę)'; }
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

  /* ---------- informacja o ukrytej zakładce u góry AKTYWNEGO ekranu modułu ----------
     W HTML informacja stoi przed pierwszym ekranem (bez JS – wzór na górze strony). Wejście pod adres z kotwicą ekranu (link
     z „Ustawień”, z e-maila, zakładka przeglądarki, np. dam-prace.html#szukam-pracy) przewija do ekranu – informacja nad nim
     zostałaby nad krawędzią okna, pod przyklejonym paskiem. Dlatego skrypt przenosi ją na początek aktywnego ekranu (przed
     nagłówek strony): przewinięcie do ekranu (html scroll-padding-top = pasek + 24 px) pokazuje ją u góry. Po zmianie ekranu
     (hashchange – po render() strony) przenosi ją znowu, a gdy kotwica wskazuje sam ekran i informacja jest nad paskiem –
     przewija do niej.
     Kotwica stanu w głębi ekranu ([data-trasa]: zakładka „Moje szkolenia”, w tym „Zamówienia i faktury” = /strefa-klienta/zamowienia,
     kroki zamówienia = /strefa-klienta/szkolenia/[slug]/zamowienie i /strefa-klienta/zamowienia/[ref], kroki zapisu, stany po
     wysłaniu formularza) – w produkcji to osobna trasa albo stan strony po 303, wczytywany od początku, z informacją na górze.
     W makiecie to kotwice w ekranach „Moje szkolenia”, „Zamówienie”, strony szkolenia i „Dam pracę”, więc skrypt stawia
     informację tuż przed kartą z celem i przewija do niej: informacja u góry okna, cel zaraz pod nią. Kotwica zwykłego
     fragmentu strony bez [data-trasa] (np. #f-nowe, #sp-lista) – przeglądarka pokazuje wskazane miejsce, a informacja stoi na
     początku ekranu, nad nim; tak samo w produkcji. Zmiana ekranu kończy też jednorazowe potwierdzenie „… jest znowu
     widoczna” (w produkcji – komunikat po 303). W produkcji serwer renderuje informację od razu na początku ekranu modułu. */
  function pasekDol() {
    var b = all('.topbar, .pub-header').filter(function (e) { return e.getClientRects().length; })[0];
    return b ? b.getBoundingClientRect().bottom : 0;
  }
  function kotwica() {
    try { return decodeURIComponent(location.hash.slice(1)); } catch (e) { return ''; }   // zły adres – jak bez kotwicy
  }
  /* karta z celem kotwicy stanu ([data-trasa]) w aktywnym ekranie; null – kotwica ekranu, fragmentu albo brak kotwicy */
  function kartaStanu(v, id) {
    var el = id && id !== v.id ? document.getElementById(id) : null;
    var t = el && v.contains(el) ? el.closest('[data-trasa]') : null;
    if (!t || !v.contains(t)) { return null; }
    var k = t.closest('.card');
    return k && v.contains(k) ? k : t;
  }
  var ekran = null;   // aktywny ekran przy ostatnim umieszczeniu informacji
  function umiescUwagi(przewin) {
    var v = document.querySelector('.view.is-active');
    if (!v) { return; }
    if (ekran && ekran !== v) {   // nowy ekran: potwierdzenie po „Pokaż zakładkę” było jednorazowe
      all('[data-zakladka-uwaga].is-done').forEach(function (box) {
        var f = box.querySelector('form'), ok = box.querySelector('.tab-note-ok');
        box.classList.remove('is-done'); if (f) { f.hidden = false; } if (ok) { ok.hidden = true; }
      });
    }
    ekran = v;
    var id = kotwica(), karta = kartaStanu(v, id);
    all('[data-zakladka-uwaga]').forEach(function (box) {
      if (karta) { if (box.nextElementSibling !== karta) { karta.parentNode.insertBefore(box, karta); } }
      else if (v.firstElementChild !== box) { v.insertBefore(box, v.firstChild); }
      if (!przewin || !box.getClientRects().length) { return; }
      if (!karta && id && id !== v.id) { return; }   // zwykły fragment w głębi ekranu – jak w produkcji
      if (box.getBoundingClientRect().top < pasekDol()) { box.scrollIntoView({ block: 'start' }); }
    });
  }
  window.addEventListener('hashchange', function () { umiescUwagi(true); });
  window.addEventListener('load', function () { umiescUwagi(true); });

  /* zmiana w innej karcie tej samej przeglądarki */
  window.addEventListener('storage', function (e) {
    if (e.key !== KLUCZ && e.key !== null) { return; }
    root.setAttribute('data-ukryte', znane(wczytaj().ukryte).join(' '));
    odswiez();
    historia();
  });
  /* rola zmienia się z widokiem (panel.html: „Pulpit pracownika”) – przełączniki i linki za nią */
  if (window.MutationObserver) { new MutationObserver(odswiez).observe(body, { attributes: true, attributeFilter: ['data-role'] }); }

  umiescUwagi(false);
  odswiez();
  historia();
})();
