/* =====================================================================
   BeautyPolisa · Strefa Klienta · wspólne wzorce makiet (raport 16, rozdz. 3.3; 17.11.2026)
   Ładowany przed skryptem strony w logowanie.html, panel.html, dam-prace.html i szkolenia.html (window.bpStrefa).
   W produkcji te same zachowania dają komponenty formularzy i akcji Strefy (11 §6, §9).

   - setErr(pole, idBledu, tekst)   błąd przy polu: tekst w <p class="field-error">, aria-invalid i aria-describedby;
   - fokusBledu(pole)               przenosi fokus na pole z błędem; gdy fokus już w nim jest (Enter w formularzu
                                    jednopolowym), błąd ogłasza wspólny region sr-only role="alert" (czytnik nie odczyta
                                    ponownie opisu pola, w którym już stoi);
   - ogloszenie(tekst, pilne)       jedno ogłoszenie w regionie sr-only (role="status", a pilne – role="alert");
   - pokazStatus(pole, tekst)       pokazuje ukryty komunikat role="status" i wpisuje treść po chwili – zmiana treści jest
                                    ogłaszana (samo odkrycie regionu z gotowym tekstem czytniki często pomijają); bez tekstu –
                                    wstawia ponownie własną treść komunikatu (z <span translate="no">);
   - zablokuj(przycisk, tekst)      blokada po akcji przez aria-disabled zamiast disabled: przycisk zostaje w kolejności Tab
                                    i nie zrzuca fokusu na <body>; kliknięcie i Enter są blokowane niżej (faza przechwytywania);
   - details.mini                   rozwijane potwierdzenie (działa bez JS): Esc i przycisk [data-zamknij] zamykają je
                                    i oddają fokus na summary;
   - cofnij({...})                  okno „Cofnij” po akcji, którą da się odwrócić (zamknięcie ogłoszenia, usunięcie szkicu,
                                    rezygnacja z zapisu): 10 s, czas stoi, gdy przycisk ma fokus albo kursor; w produkcji
                                    serwer wykonuje akcję dopiero po tym czasie;
   - form[data-niezapisane]         ostrzeżenie przed utratą danych: flaga „zmiany” po zdarzeniu input; przy wyjściu ze strony
                                    (beforeunload) i przy przejściu do innego ekranu linkiem („Anuluj”, menu) – potwierdzenie;
                                    czysty(form) po udanym wysłaniu;
   - .table-wrap[role="region"]      przewijana tabela: tabindex="0" tylko wtedy, gdy obszar się przewija (bez JS – zawsze);
   - kwota(), zakresKwot(), data(), godzina(), NB – polskie formaty (Intl, useGrouping:'always', twarde spacje).
   ===================================================================== */
(function (w, d) {
  'use strict';
  var NB = ' ';
  var CZAS_COFNIJ = 10000;

  /* ---------- regiony ogłoszeń (istnieją od wczytania strony – wtedy zmiany treści są ogłaszane) ---------- */
  function region(rola) {
    var p = d.createElement('p');
    p.className = 'sr-only';
    p.setAttribute('role', rola);
    p.setAttribute('aria-atomic', 'true');
    p.setAttribute('data-bp-region', rola);
    d.body.appendChild(p);
    return p;
  }
  var rAlert = region('alert'), rStatus = region('status'), tA = 0, tS = 0;
  function ogloszenie(tekst, pilne) {
    var r = pilne ? rAlert : rStatus;
    clearTimeout(pilne ? tA : tS);
    r.textContent = '';
    var t = setTimeout(function () { r.textContent = tekst; }, 60);
    if (pilne) { tA = t; } else { tS = t; }
  }
  function pokazStatus(el, tekst, cel) {
    var t = cel || el;
    el.hidden = false;
    if (tekst == null) { /* treść z HTML (np. z <span translate="no">) – ta sama, wstawiona ponownie */
      if (t.bpHtml == null) { t.bpHtml = t.innerHTML; }
      t.innerHTML = '';
      setTimeout(function () { t.innerHTML = t.bpHtml; }, 60);
      return;
    }
    t.textContent = '';
    setTimeout(function () { t.textContent = tekst; }, 60);
  }

  /* ---------- błędy przy polach ---------- */
  function setErr(input, errId, msg) {
    var err = d.getElementById(errId);
    if (!('desc' in input.dataset)) { input.dataset.desc = input.getAttribute('aria-describedby') || ''; }
    var base = input.dataset.desc;
    if (msg) {
      err.textContent = msg; err.hidden = false;
      input.setAttribute('aria-invalid', 'true');
      if ((' ' + base + ' ').indexOf(' ' + errId + ' ') < 0) { input.setAttribute('aria-describedby', (base ? base + ' ' : '') + errId); }
      input.dataset.blad = errId;
    } else {
      err.hidden = true;
      input.removeAttribute('aria-invalid');
      if (base) { input.setAttribute('aria-describedby', base); } else { input.removeAttribute('aria-describedby'); }
      delete input.dataset.blad;
    }
    return !msg;
  }
  function fokusBledu(el) {
    if (d.activeElement === el) {
      var e = el.dataset.blad && d.getElementById(el.dataset.blad);
      if (e && e.textContent) { ogloszenie(e.textContent, true); }
    } else {
      el.focus();
    }
  }

  /* ---------- blokada bez gubienia fokusu ---------- */
  function zablokuj(btn, tekst) {
    btn.setAttribute('aria-disabled', 'true');
    if (tekst != null) { (btn.querySelector('.js-etykieta') || btn).textContent = tekst; }
  }
  function odblokuj(btn, tekst) {
    btn.removeAttribute('aria-disabled');
    if (tekst != null) { (btn.querySelector('.js-etykieta') || btn).textContent = tekst; }
  }
  function zablokowany(btn) { return !!btn && btn.getAttribute('aria-disabled') === 'true'; }
  d.addEventListener('click', function (e) {
    var b = e.target.closest && e.target.closest('button[aria-disabled="true"], a[aria-disabled="true"]');
    if (b) { e.preventDefault(); e.stopImmediatePropagation(); }
  }, true);

  /* ---------- potwierdzenia w details.mini: Esc i „Anuluj” zamykają, fokus wraca na summary ---------- */
  function zamknijMini(det) {
    det.open = false;
    var s = det.querySelector('summary');
    if (s) { s.focus(); }
  }
  d.addEventListener('keydown', function (e) {
    if (e.key !== 'Escape') { return; }
    var det = e.target.closest && e.target.closest('details.mini[open]');
    if (det) { e.preventDefault(); e.stopImmediatePropagation(); zamknijMini(det); }
  });
  d.addEventListener('click', function (e) {
    var b = e.target.closest && e.target.closest('[data-zamknij]');
    var det = b && b.closest('details');
    if (det) { e.preventDefault(); zamknijMini(det); }
  });
  /* potwierdzenie w komórce akcji tabeli ułożonej jako tabela (od 720 px, nie .stack): panel pod treścią wiersza (tr.mini-pod,
     --mini-h = wysokość panelu; CSS w strefa.css) – kolumna akcji nie rośnie, tabela nie przewija się w poziomie (runda 2
     weryfikacji). Jedno otwarte potwierdzenie w wierszu. Bez JS i w układzie .stack – panel w komórce, jak dotąd */
  function ukladMini(det) {
    var td = det.closest('td.cell-actions'), tr = td && td.parentNode, body = det.querySelector('.mini-body');
    if (!tr || !body) { return; }
    var tabela = w.getComputedStyle(tr).display === 'table-row';
    if (det.open && tabela) {
      Array.prototype.forEach.call(tr.querySelectorAll('.cell-actions details.mini[open]'), function (o) { if (o !== det) { o.open = false; } });
      /* panel przy prawej krawędzi widocznej części przewijanego obszaru (runda 3 weryfikacji): przy tabeli szerszej niż obszar
         prawa krawędź wiersza leży poza widokiem – panel wystawał, a pole pliku i przycisk były ucięte */
      var wrap = tr.closest('.table-wrap');
      if (wrap && wrap.scrollWidth > wrap.clientWidth + 1) {
        tr.style.setProperty('--mini-r', Math.max(14, tr.offsetWidth - wrap.scrollLeft - wrap.clientWidth + 14) + 'px');
        tr.style.setProperty('--mini-w', Math.max(0, wrap.clientWidth - 28) + 'px');
      } else {
        tr.style.removeProperty('--mini-r');
        tr.style.removeProperty('--mini-w');
      }
      tr.classList.add('mini-pod');
      tr.style.setProperty('--mini-h', body.offsetHeight + 'px');
    } else if (!tr.querySelector('.cell-actions details.mini[open]') || !tabela) {
      tr.classList.remove('mini-pod');
      ['--mini-h', '--mini-r', '--mini-w'].forEach(function (x) { tr.style.removeProperty(x); });
    }
  }
  d.addEventListener('toggle', function (e) {
    if (e.target.matches && e.target.matches('td.cell-actions details.mini')) { ukladMini(e.target); }
  }, true);
  if (w.ResizeObserver) {
    var roMini = new w.ResizeObserver(function (wpisy) {
      wpisy.forEach(function (x) { var det = x.target.closest('details.mini'); if (det && det.open) { ukladMini(det); } });
    });
    Array.prototype.forEach.call(d.querySelectorAll('td.cell-actions details.mini > .mini-body'), function (b) { roMini.observe(b); });
  }
  w.addEventListener('resize', function () {
    Array.prototype.forEach.call(d.querySelectorAll('td.cell-actions details.mini[open]'), ukladMini);
  });
  /* przewinięcie obszaru tabeli w poziomie (także fokusem) – panel zostaje w widocznej części */
  d.addEventListener('scroll', function (e) {
    var t = e.target;
    if (t && t.nodeType === 1 && t.matches('.table-wrap')) { Array.prototype.forEach.call(t.querySelectorAll('td.cell-actions details.mini[open]'), ukladMini); }
  }, true);

  /* ---------- „Cofnij” ----------
     o.po      – element, za którym staje pasek „Cofnij” (zwykle komunikat role="status");
     o.nazwa   – dopisek dla czytnika w nazwie przycisku („Cofnij: zamknięcie ogłoszenia …”);
     o.cofnij  – przywraca stan sprzed akcji (makieta); o.koniec – wywoływane, gdy czas minie (opcjonalnie);
     zwraca obiekt z metodą zakoncz(). */
  var licznik = 0;
  /* dolna krawędź przyklejonego paska górnego (Strefa: .topbar; publiczna tablica „Dam pracę”: .pub-header) */
  function dolPaska() {
    var m = 0;
    Array.prototype.forEach.call(d.querySelectorAll('.topbar, .pub-header'), function (h) {
      var p = w.getComputedStyle(h).position;
      if (p !== 'sticky' && p !== 'fixed') { return; }
      var r = h.getBoundingClientRect();
      if (r.height && r.top < 1 && r.bottom > m) { m = r.bottom; }
    });
    return m;
  }
  function cofnij(o) {
    licznik += 1;
    var id = 'bp-cofnij-' + licznik;
    var bar = d.createElement('div');
    bar.className = 'undo';
    bar.innerHTML = '<button class="btn btn-ghost btn-sm" type="button"><span>Cofnij</span><span class="sr-only"></span></button>' +
      '<span class="xsmall muted" id="' + id + '">Cofnięcie możliwe przez 10' + NB + 's.</span>';
    var btn = bar.querySelector('button');
    btn.querySelector('.sr-only').textContent = o.nazwa ? ': ' + o.nazwa : '';
    btn.setAttribute('aria-describedby', id);
    o.po.parentNode.insertBefore(bar, o.po.nextSibling);
    var zostalo = o.czas || CZAS_COFNIJ, start = 0, timer = 0, stoi = 0, po = false;
    function biegnij() { if (po || stoi > 0) { return; } start = Date.now(); timer = setTimeout(zakoncz, zostalo); }
    function zatrzymaj() { stoi += 1; if (timer) { clearTimeout(timer); timer = 0; zostalo = Math.max(1500, zostalo - (Date.now() - start)); } }
    function wznow() { stoi = Math.max(0, stoi - 1); biegnij(); }
    function usun(focusNa) {
      po = true; clearTimeout(timer);
      var mialFokus = bar.contains(d.activeElement);
      bar.remove();
      if (mialFokus && focusNa) {
        if (!focusNa.matches('a[href],button,input,select,textarea,[tabindex]')) { focusNa.setAttribute('tabindex', '-1'); }
        focusNa.focus();
      }
    }
    function zakoncz() { if (po) { return; } usun(o.po); if (o.koniec) { o.koniec(); } }
    btn.addEventListener('focus', zatrzymaj); btn.addEventListener('blur', wznow);
    bar.addEventListener('mouseenter', zatrzymaj); bar.addEventListener('mouseleave', wznow);
    btn.addEventListener('click', function () {
      if (po) { return; }
      usun(null);
      var cel = o.cofnij ? o.cofnij() : null;
      if (cel && cel.focus) { cel.focus(); }
    });
    biegnij();
    /* fokus od razu (bez przewijania), a położenie – po wpisaniu treści statusu nad przyciskiem (pokazStatus: 60 ms). Wcześniej
       przeglądarka przewijała do przycisku, a dopiero potem tekst statusu spychał go w dół – „Cofnij” i opis „Cofnięcie możliwe
       przez 10 s” lądowały pod krawędzią okna (szkolenia.html#zapisano, 320×568; weryfikacja, runda 1) */
    btn.focus({ preventScroll: true });
    /* runda 2 weryfikacji: w oknie ma być komunikat statusu (co się stało) i cały pasek „Cofnij” pod nim. Samo
       bar.scrollIntoView({block:'nearest'}) stawiało pasek tuż pod paskiem górnym, a status – pod nim albo nad krawędzią okna
       (dam-prace „Usuń szkic” przy 1280 px: 0% statusu w oknie). Przesunięcie dy z przedziału [lo, hi]: lo – dół paska „Cofnij”
       8 px nad dołem okna, hi – góra statusu 8 px pod paskiem górnym; najmniejszy ruch, a gdy obu nie da się spełnić – pasek */
    setTimeout(function () {
      if (po || !bar.isConnected) { return; }
      var tb = dolPaska(), r = o.po.getBoundingClientRect(), b = bar.getBoundingClientRect();
      var lo = b.bottom - (w.innerHeight - 8), hi = r.top - (tb + 8);
      var dy = lo > hi ? lo : Math.min(Math.max(0, lo), hi);
      if (Math.abs(dy) >= 1) { w.scrollBy({ top: dy, left: 0, behavior: 'instant' }); }
    }, 80);
    return { zakoncz: zakoncz, przycisk: btn };
  }

  /* ---------- ostrzeżenie przed utratą danych ---------- */
  var PYTANIE = 'Masz niezapisane zmiany w formularzu. Wyjść bez zapisywania?';
  var formy = Array.prototype.slice.call(d.querySelectorAll('form[data-niezapisane]'));
  formy.forEach(function (f) {
    f.addEventListener('input', function (e) { if (e.isTrusted !== false) { f.setAttribute('data-zmiany', 'tak'); } });
    f.addEventListener('reset', function () { f.removeAttribute('data-zmiany'); });
  });
  function czysty(f) { if (f) { f.removeAttribute('data-zmiany'); } }
  function zmienione() { return formy.filter(function (f) { return f.hasAttribute('data-zmiany') && f.getClientRects().length > 0; }); }
  w.addEventListener('beforeunload', function (e) {
    if (zmienione().length) { e.preventDefault(); e.returnValue = ''; }
  });
  d.addEventListener('click', function (e) {
    if (e.defaultPrevented || e.button > 0 || e.metaKey || e.ctrlKey || e.shiftKey) { return; }
    var a = e.target.closest && e.target.closest('a[href]');
    if (!a) { return; }
    var href = a.getAttribute('href');
    if (href.charAt(0) !== '#') { return; } /* inne strony i adresy – ostrzega beforeunload */
    var z = zmienione();
    if (!z.length) { return; }
    var cel = d.getElementById(decodeURIComponent(href.slice(1)));
    var ekran = z[0].closest('.view, .screen') || z[0];
    if (cel && ekran.contains(cel)) { return; } /* odnośnik w obrębie tego samego ekranu (np. do klauzuli) */
    if (!w.confirm(PYTANIE)) { e.preventDefault(); e.stopImmediatePropagation(); return; }
    z.forEach(czysty);
  }, true);

  /* ---------- polskie formaty ---------- */
  var fKwota = null, fZakres = null, fData = null, fGodz = null;
  try {
    fKwota = new Intl.NumberFormat('pl-PL', { style: 'currency', currency: 'PLN', useGrouping: 'always' });
    fZakres = new Intl.NumberFormat('pl-PL', { style: 'currency', currency: 'PLN', minimumFractionDigits: 0, maximumFractionDigits: 2, useGrouping: 'always' });
    fData = new Intl.DateTimeFormat('pl-PL', { day: 'numeric', month: 'numeric', year: 'numeric' });
    fGodz = new Intl.DateTimeFormat('pl-PL', { hour: 'numeric', minute: '2-digit' });
  } catch (e) { /* bardzo stare przeglądarki – zapas niżej */ }
  function kwota(n) { return fKwota ? fKwota.format(n) : Number(n).toFixed(2).replace('.', ',') + NB + 'zł'; }
  function zakresKwot(od, doK) {
    if (od === doK) { return fZakres ? fZakres.format(od) : od + NB + 'zł'; }
    return fZakres && fZakres.formatRange ? fZakres.formatRange(od, doK) : od + '–' + doK + NB + 'zł';
  }
  function data(dt) { return fData ? fData.format(dt) : dt.getDate() + '.' + (dt.getMonth() + 1) + '.' + dt.getFullYear(); }
  function godzina(dt) { return fGodz ? fGodz.format(dt) : dt.getHours() + ':' + (dt.getMinutes() < 10 ? '0' : '') + dt.getMinutes(); }

  /* ---------- panel zakładki z adresu przy pierwszym wczytaniu (np. panel.html#p-szkody, szkolenia.html#p-zam) ----------
     Przeglądarka przewija do samego panelu, a rząd zakładek chowa się pod paskiem górnym (runda 2 weryfikacji – panel.html;
     runda 3 – szkolenia.html): karta od rzędu zakładek pod paskiem (html scroll-padding-top), także po przewinięciu przeglądarki
     do kotwicy przy zdarzeniu load. Gdy tuż przed kartą stoi informacja o ukrytej zakładce (zakladki.js, D44 – przenosi ją przy
     load, przed tym wywołaniem), przewija do informacji: informacja u góry okna, karta z zakładkami zaraz pod nią */
  function pokazZakladki(tab, id) {
    var karta = tab && (tab.closest('.card') || tab.closest('[role="tablist"]'));
    if (!karta) { return; }
    function pokaz() {
      if (w.location.hash !== '#' + id) { return; }
      var przed = karta.previousElementSibling;
      var cel = przed && przed.matches('[data-zakladka-uwaga]') && przed.getClientRects().length ? przed : karta;
      cel.scrollIntoView({ block: 'start' });
    }
    pokaz();
    if (d.readyState !== 'complete') { w.addEventListener('load', function () { w.requestAnimationFrame(pokaz); }, { once: true }); }
  }

  /* ---------- przewijane tabele: zatrzymanie Tab tylko wtedy, gdy region naprawdę się przewija ----------
     .table-wrap[role="region"][aria-label] ma w HTML tabindex="0" (bez JS przewijanie z klawiatury działa zawsze – WCAG 2.1.1);
     skrypt zdejmuje tabindex, gdy tabela mieści się w karcie (np. układ .stack na telefonie), i oddaje go, gdy tabela znowu się
     przewija (ResizeObserver na obszarze i na tabeli; także po pokazaniu ukrytego ekranu albo zakładki) */
  function fokusTabeli(t) {
    if (!t || !t.clientWidth) { return; }
    if (t.scrollWidth > t.clientWidth + 1) { t.setAttribute('tabindex', '0'); } else if (d.activeElement !== t) { t.removeAttribute('tabindex'); }
  }
  if (w.ResizeObserver) {
    var obserwator = new ResizeObserver(function (wpisy) {
      wpisy.forEach(function (x) { fokusTabeli(x.target.closest('.table-wrap[role="region"]')); });
    });
    Array.prototype.forEach.call(d.querySelectorAll('.table-wrap[role="region"]'), function (t) {
      obserwator.observe(t);
      var tab = t.querySelector('table');
      if (tab) { obserwator.observe(tab); }
    });
  }

  w.bpStrefa = {
    NB: NB, setErr: setErr, fokusBledu: fokusBledu, ogloszenie: ogloszenie, pokazStatus: pokazStatus,
    zablokuj: zablokuj, odblokuj: odblokuj, zablokowany: zablokowany, zamknijMini: zamknijMini,
    cofnij: cofnij, czysty: czysty, kwota: kwota, zakresKwot: zakresKwot, data: data, godzina: godzina, pokazZakladki: pokazZakladki
  };
})(window, document);
