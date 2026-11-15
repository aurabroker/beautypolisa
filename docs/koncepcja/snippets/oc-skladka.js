/*
 * Wycena OC beauty (program WA50/003353/24/A) – czysta funkcja wspólna dla makiety, aplikacji i testów.
 * Przepisanie reguł CRM (crmaura/src/lib/renewals/program.ts): kategoriaZRodzajow i skladkaProgramu – ta sama kolejność
 * działań i zaokrąglenie; wycenaNowej – ten sam wynik dla kompletu odpowiedzi. Stałe nie są tu wpisane: przychodzą jako
 * T = snippets/taryfa-oc-beauty.json.
 *
 * Dla kompletu odpowiedzi (rodzaje, osoby, suma) wynik jest taki sam jak w CRM: ta sama kategoria, kwota do grosza,
 * ten sam powód wyceny indywidualnej i ten sam opis (pole opisCrm). Przy brakach – stany interfejsu portalu (fixture
 * F1–F5, tylko_portal): w CRM bez sumy nie ma wyceny (wycenaNowej zwraca null), a taki wniosek zatrzymuje walidacja.
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

  // = kategoriaZRodzajow (program.ts): podologia albo fryzjerstwo razem z kosmetologią lub tatuażem – pełna;
  // kosmetologia albo tatuaż – kosmetologiczna; pozostałe – kosmetyczna i fryzjerska; brak rodzaju – null.
  function kategoria(rodzaje) {
    if (!rodzaje.length) return null;
    var r = new Set(rodzaje);
    var lista2 = r.has('kosmetologiczny') || r.has('tatuaz');
    if (r.has('podologiczny') || (lista2 && r.has('fryzjerski'))) return 'pelny';
    if (lista2) return 'kosmetologiczny';
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
    var k = kategoria(rodzaje);
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
