/*
 * Wycena OC beauty (program WA50/003353/24/A) – czysta funkcja wspólna dla makiety, aplikacji i testów.
 * Przepisanie reguł CRM (crmaura/src/lib/renewals/program.ts): skladkaProgramu – ta sama kolejność działań i zaokrąglenie;
 * wycenaNowej – ten sam wynik dla kompletu odpowiedzi. Kategoria taryfy – reguła portalu według decyzji zleceniodawcy D45
 * (16.11.2026; 00), ODSTĘPSTWO od kategoriaZRodzajow w CRM (opis przy funkcji kategoria). Stałe nie są tu wpisane:
 * przychodzą jako T = snippets/taryfa-oc-beauty.json (grupy rodzajów działalności – T.regula_kategorii).
 *
 * Dla kompletu odpowiedzi (rodzaje, osoby, suma) wynik jest taki sam jak w CRM – kwota do grosza, powód wyceny
 * indywidualnej, opis (pole opisCrm) – z wyjątkiem 9 połączeń rodzajów z D45: tam portal liczy pełną taryfę, a CRM do czasu
 * zmiany kategoriaZRodzajow – taryfę „Gabinety kosmetologiczne” (fixture: pole odstepstwo_D45 z kwotą CRM; opisCrm = opis
 * w formacie CRM dla kategorii portalu). Przy brakach – stany interfejsu portalu (fixture F1–F5, tylko_portal): w CRM bez
 * sumy nie ma wyceny (wycenaNowej zwraca null), a taki wniosek zatrzymuje walidacja.
 * Kolejność sprawdzeń w portalu: zabiegi wymagające ankiety (cała składka do wyceny indywidualnej), rodzaje, osoby,
 * więcej niż 8 osób, suma – wycenaNowej w CRM najpierw sprawdza sumę.
 *
 * Wejście po walidacji (jak w CRM po listOf/oneOf): rodzaje – klucze z T.rodzaje_gabinetu, osoby – klucz
 * z T.liczba_osob albo pusty, suma – wartość z T.sumy albo pusta, zabiegiAnkieta – wybrane pozycje a–h
 * (identyfikatory g4-xx albo nazwy z CRM; funkcja liczy tylko, czy są). Nieznana wartość = błąd programisty (TypeError).
 *
 * Plik działa jako zwykły skrypt w przeglądarce (globalny OcSkladka) i jako moduł CommonJS w Node.
 */
(function (root, fabryka) {
  var api = fabryka();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.OcSkladka = api;
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict';
  var NB = ' ', WJ = '\u2060';

  // Kategoria taryfy z rodzajów działalności – decyzja zleceniodawcy D45 (16.11.2026): podologia – zawsze pełna; rodzaj
  // z listy nr 1 (kosmetyczny, fryzjerski, masaż) razem z rodzajem z listy nr 2 (kosmetologiczny, tatuaż) – pełna; same
  // rodzaje z listy nr 2 – kosmetologiczna; same rodzaje z listy nr 1 – kosmetyczna i fryzjerska; brak rodzaju – null.
  // Grupy rodzajów: T.regula_kategorii. ODSTĘPSTWO od CRM (kategoriaZRodzajow w program.ts): tam pełną taryfę z listą nr 2
  // daje tylko salon fryzjerski, więc gabinet kosmetyczny lub salon masażu razem z gabinetem kosmetologicznym lub salonem
  // tatuażu (9 połączeń) ma w CRM taryfę kosmetologiczną – do zmiany w CRM (docs/koncepcja/do-crm/, 14 §4.7).
  function kategoria(rodzaje, T) {
    if (!rodzaje.length) return null;
    var R = T && T.regula_kategorii;
    if (!R) throw new TypeError('Brak T.regula_kategorii (snippets/taryfa-oc-beauty.json)');
    var ma = function (grupa) {
      return grupa.some(function (x) { return rodzaje.indexOf(x) >= 0; });
    };
    if (ma(R.zawsze_pelna) || (ma(R.lista_1) && ma(R.lista_2))) return 'pelny';
    if (ma(R.lista_2)) return 'kosmetologiczny';
    return 'kosmetyczny_fryzjerski';
  }

  function klucze(lista) {
    return lista.map(function (x) { return x.klucz; });
  }

  function kategoriaT(T, k) {
    for (var i = 0; i < T.kategorie.length; i++) if (T.kategorie[i].klucz === k) return T.kategorie[i];
    throw new TypeError('Nieznana kategoria: ' + k);
  }

  function pusta(v) {
    return v === null || v === undefined || v === '';
  }

  // Grupowanie tysięcy spacją twardą (1 279,50 zł; 1 250 zł).
  function grupuj(n) {
    return String(n).replace(/\B(?=(\d{3})+(?!\d))/g, NB);
  }

  // Kwota wyniku kalkulatora – zawsze z groszami: „987,50 zł”, „1 279,50 zł”, „1 250,00 zł” (spacje twarde).
  function formatKwota(kwota) {
    var gr = Math.round(kwota * 100);
    var zl = Math.floor(gr / 100), reszta = gr % 100;
    return grupuj(zl) + ',' + (reszta < 10 ? '0' : '') + reszta + NB + 'zł';
  }

  // Kwota całkowita (tabele taryfy, stawka w opisie): „790 zł”, „1 250 zł”.
  function formatKwotaCalkowita(kwota) {
    return grupuj(kwota) + NB + 'zł';
  }

  // Suma gwarancyjna jak dotąd na stronach portalu: „200 tys. zł”.
  function formatSuma(suma) {
    return suma % 1000 === 0 ? suma / 1000 + NB + 'tys.' + NB + 'zł' : grupuj(suma) + NB + 'zł';
  }

  // Formaty CRM (program.ts: formatSuma) – tylko do opisu identycznego z CRM (opisCrm).
  function formatSumaCrm(suma) {
    return Math.round(suma).toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.') + ' zł';
  }

  // Wycena: { rodzaje, osoby, suma, ochronaPrawna, zabiegiAnkieta } → wynik.
  //   { stan: 'brak', pole: 'rodzaje'|'osoby'|'suma', komunikat }
  //   { stan: 'indywidualna', powodKlucz: 'ankieta'|'osoby', powod, kategoria (null przy ankiecie), nazwa }
  //   { stan: 'kwota', kategoria, nazwa, suma, baza, kwota, opis, opisCrm }
  function skladkaOc(odp, T) {
    var rodzaje = odp.rodzaje || [];
    var dozwolone = klucze(T.rodzaje_gabinetu);
    rodzaje.forEach(function (r) {
      if (dozwolone.indexOf(r) < 0) throw new TypeError('Nieznany rodzaj działalności: ' + r);
    });
    var osoby = pusta(odp.osoby) ? null : odp.osoby;
    if (osoby !== null && klucze(T.liczba_osob).indexOf(osoby) < 0) throw new TypeError('Nieznana liczba osób: ' + osoby);
    var suma = pusta(odp.suma) ? null : Number(odp.suma);
    if (suma !== null && T.sumy.indexOf(suma) < 0) throw new TypeError('Nieznana suma gwarancyjna: ' + odp.suma);
    var ochronaPrawna = odp.ochronaPrawna === true;
    var ankieta = odp.zabiegiAnkieta || [];

    // = wycenaNowej (program.ts): zabiegi z ankiety – cała składka do indywidualnej wyceny, przed rodzajem i osobami.
    if (ankieta.length) {
      return { stan: 'indywidualna', powodKlucz: 'ankieta', powod: T.powody_wyceny_indywidualnej.ankieta, kategoria: null, nazwa: null };
    }
    var k = kategoria(rodzaje, T);
    if (!k) return { stan: 'brak', pole: 'rodzaje', komunikat: T.komunikaty_brakow.rodzaje };
    var kat = kategoriaT(T, k);
    if (!osoby) return { stan: 'brak', pole: 'osoby', komunikat: T.komunikaty_brakow.osoby, kategoria: k, nazwa: kat.nazwa };
    // = skladkaProgramu (program.ts): więcej niż 8 osób – wycena indywidualna.
    if (osoby === '9+') {
      return { stan: 'indywidualna', powodKlucz: 'osoby', powod: T.powody_wyceny_indywidualnej.osoby, kategoria: k, nazwa: kat.nazwa };
    }
    if (suma === null) return { stan: 'brak', pole: 'suma', komunikat: T.komunikaty_brakow.suma, kategoria: k, nazwa: kat.nazwa };

    // = skladkaProgramu: stawka × 1,25 tylko przy 6–8 osobach, potem + ochrona prawna (bez dopłaty), zaokrąglenie do grosza.
    var baza = kat.skladka[String(suma)];
    var zDoplata = osoby === '6-8' ? baza * (1 + T.doplata_6_8_osob) : baza;
    var kwota = Math.round((zDoplata + (ochronaPrawna ? T.ochrona_prawna.skladka : 0)) * 100) / 100;

    var crm = [kat.nazwa + ', suma ' + formatSumaCrm(suma) + ': ' + baza + ' zł'];
    var portal = [kat.nazwa + ', suma ' + formatSuma(suma) + ': ' + formatKwotaCalkowita(baza)];
    if (osoby === '6-8') {
      crm.push('+25% (6–8 osób)');
      // łącznik słowa (U+2060) po półpauzie: „6–8 osób” nie łamie się na wąskim ekranie
      portal.push('+' + Math.round(T.doplata_6_8_osob * 100) + '% (6–' + WJ + '8' + NB + 'osób)');
    }
    if (ochronaPrawna) {
      crm.push('+' + T.ochrona_prawna.skladka + ' zł ochrona prawna');
      portal.push('+' + T.ochrona_prawna.skladka + NB + 'zł ochrona prawna');
    }
    return {
      stan: 'kwota', kategoria: k, nazwa: kat.nazwa, suma: suma, baza: baza, kwota: kwota,
      opis: portal.join(', '), opisCrm: crm.join(', ')
    };
  }

  return {
    kategoria: kategoria,
    skladkaOc: skladkaOc,
    formatKwota: formatKwota,
    formatKwotaCalkowita: formatKwotaCalkowita,
    formatSuma: formatSuma
  };
});
