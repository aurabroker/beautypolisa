/* =====================================================
   BeautyPolisa — bp-app.js
   Cała logika kalkulatora, modali i formularzy
   ===================================================== */

const BP = (() => {

  /* ---------- DANE ---------- */
  const BASE_PRICING = {
    1: { s100: 400, s200: 500, s300: 650 },
    2: { s100: 650, s200: 790, s300: 950 },
    3: { s100: 850, s200: 980, s300: 1250 }
  };
  const LEGAL_COST = 92;

  let _confettiFired = false;

  /* ---------- INIT ---------- */
  function init() {
    // Nasłuchuj na checkboxy i radio buttons
    document.querySelectorAll('.tier-checkbox').forEach(cb => {
      cb.addEventListener('change', updateCalculator);
    });
    document.querySelectorAll('[name="employees"]').forEach(r => {
      r.addEventListener('change', updateCalculator);
    });
    document.getElementById('legal-protection').addEventListener('change', updateCalculator);

    // Zamykanie modali Escape
    document.addEventListener('keydown', e => {
      if (e.key === 'Escape') {
        document.querySelectorAll('.modal:not(.hidden)').forEach(m => {
          closeModal(m.id);
        });
      }
    });
  }

  /* ---------- KALKULATOR ---------- */
  function updateCalculator() {
    const checkboxes = document.querySelectorAll('.tier-checkbox');
    let hasTier = [false, false, false, false]; // indeks 1-4
    let checkedCount = 0;

    checkboxes.forEach(cb => {
      if (cb.checked) {
        checkedCount++;
        const t = parseInt(cb.dataset.tier, 10);
        hasTier[t] = true;
      }
    });

    const step2     = document.getElementById('step-2');
    const resultsEl = document.getElementById('results-section');

    if (checkedCount === 0) {
      step2.classList.add('card--dimmed');
      resultsEl.classList.add('hidden');
      _confettiFired = false;
      return;
    }

    step2.classList.remove('card--dimmed');

    // Określ taryfę
    let finalTier = 1;
    let taryfaName = '';

    if (hasTier[3]) {
      finalTier = 3;
      taryfaName = 'Gabinety Podologiczne (Pakiet Pełny)';
    } else if (hasTier[1] && hasTier[2]) {
      finalTier = 3;
      taryfaName = 'Pakiet Łączony (Kosmetyka + Kosmetologia)';
    } else if (hasTier[2]) {
      finalTier = 2;
      taryfaName = 'Gabinety Kosmetologiczne';
    } else if (hasTier[1]) {
      finalTier = 1;
      taryfaName = 'Gabinety Kosmetyczne i Fryzjerskie';
    }

    document.getElementById('detected-tier-msg').textContent = taryfaName;

    const empValue = getEmpValue();
    const hasLegal = document.getElementById('legal-protection').checked;
    const legalAdd = hasLegal ? LEGAL_COST : 0;

    const cardsEl = document.getElementById('pricing-cards-container');
    const indEl   = document.getElementById('individual-pricing-msg');

    // Pokaż wyniki
    resultsEl.classList.remove('hidden');

    if (hasTier[4] || empValue === 'ind') {
      cardsEl.classList.add('hidden');
      indEl.classList.remove('hidden');

      const reason = hasTier[4]
        ? 'Wybrałaś zabiegi specjalistyczne (Grupa 4), które wymagają indywidualnej oceny ryzyka przez ubezpieczyciela. Wypełnij ankietę, abyśmy mogli wynegocjować dla Ciebie najlepszą stawkę.'
        : 'Ze względu na dużą skalę działalności (powyżej 8 osób), przygotujemy dla Ciebie taryfę szytą na miarę. Nasz broker wynegocjuje optymalną stawkę w ERGO Hestia.';

      document.getElementById('ind-pricing-reason').textContent = reason;
      document.getElementById('btn-ind').onclick = () => openOfferModal('Wycena Indywidualna', 'Brak ceny — wymaga weryfikacji', taryfaName);

    } else {
      cardsEl.classList.remove('hidden');
      indEl.classList.add('hidden');

      const mult = parseFloat(empValue) || 1;
      const p = BASE_PRICING[finalTier];

      const p100 = Math.round(p.s100 * mult + legalAdd);
      const p200 = Math.round(p.s200 * mult + legalAdd);
      const p300 = Math.round(p.s300 * mult + legalAdd);

      document.getElementById('price-100k').textContent = p100;
      document.getElementById('price-200k').textContent = p200;
      document.getElementById('price-300k').textContent = p300;

      document.getElementById('btn-100k').onclick = () => openOfferModal('100 000 zł', p100 + ' zł', taryfaName);
      document.getElementById('btn-200k').onclick = () => openOfferModal('200 000 zł', p200 + ' zł', taryfaName);
      document.getElementById('btn-300k').onclick = () => openOfferModal('300 000 zł (Wymaga Ankiety)', p300 + ' zł', taryfaName);

      fireConfetti();
    }

    // Scroll do wyników tylko gdy po raz pierwszy się pojawiają
    if (checkedCount === 1) {
      setTimeout(() => resultsEl.scrollIntoView({ behavior: 'smooth', block: 'nearest' }), 200);
    }
  }

  function getEmpValue() {
    const radios = document.getElementsByName('employees');
    for (const r of radios) {
      if (r.checked) return r.value;
    }
    return '1';
  }

  /* ---------- CONFETTI ---------- */
  function fireConfetti() {
    if (_confettiFired || typeof confetti === 'undefined') return;
    _confettiFired = true;
    const end = Date.now() + 2500;
    const colors = ['#e63975', '#1e2d5a', '#fce7ef', '#f472a0', '#c9a96e'];
    const interval = setInterval(() => {
      if (Date.now() > end) return clearInterval(interval);
      const count = 40 * ((end - Date.now()) / 2500);
      confetti({ particleCount: count, origin: { x: Math.random() * 0.4 + 0.1, y: -0.1 }, colors, spread: 80, startVelocity: 25 });
      confetti({ particleCount: count, origin: { x: Math.random() * 0.4 + 0.5, y: -0.1 }, colors, spread: 80, startVelocity: 25 });
    }, 280);
  }

  /* ---------- MODALS ---------- */
  function openModal(id) {
    const modal = document.getElementById(id);
    if (!modal) return;
    modal.classList.remove('hidden');
    document.body.style.overflow = 'hidden';
    setTimeout(() => modal.querySelector('input, button')?.focus(), 100);
  }

  function closeModal(id) {
    const modal = document.getElementById(id);
    if (!modal) return;
    modal.classList.add('hidden');
    document.body.style.overflow = '';
  }

  function openOfferModal(variant, price, taryfaName) {
    document.getElementById('modal-chosen-variant').textContent = variant;
    document.getElementById('modal-chosen-price').textContent = price;
    document.getElementById('form-hidden-variant').value = variant;
    document.getElementById('form-hidden-price').value = price;
    document.getElementById('form-hidden-taryfa').value = taryfaName;

    // Zbierz zaznaczone zabiegi
    const groups = { 1: [], 2: [], 3: [], 4: [] };
    document.querySelectorAll('.tier-checkbox:checked').forEach(cb => {
      groups[cb.dataset.tier].push(cb.nextElementSibling.textContent.trim());
    });
    let procedures = '';
    [1, 2, 3, 4].forEach(t => {
      if (groups[t].length) procedures += `--- GRUPA ${t} ---\n${groups[t].join('\n')}\n\n`;
    });
    document.getElementById('form-hidden-procedures').value = procedures.trim();

    const isAnkieta = variant.includes('Ankiety') || variant.includes('Indywidualna');
    const warningEl = document.getElementById('modal-ankieta-warning');
    const ankietaField = document.getElementById('ankieta-agreement-field');
    const submitBtn = document.getElementById('submit-offer-btn');

    warningEl.classList.toggle('hidden', !isAnkieta);
    ankietaField.classList.toggle('hidden', !isAnkieta);
    submitBtn.textContent = isAnkieta ? 'Wyślij dane i POBIERZ ANKIETĘ' : 'Przekaż do weryfikacji';
    submitBtn.className = isAnkieta
      ? 'btn btn--full btn--lg'
      : 'btn btn--primary btn--full btn--lg';
    if (isAnkieta) { submitBtn.style.background = '#d97706'; submitBtn.style.borderColor = '#d97706'; }
    else { submitBtn.style.background = ''; submitBtn.style.borderColor = ''; }

    openModal('modal-offer');
  }

  /* ---------- FORMULARZE ---------- */
  async function submitOffer(e) {
    e.preventDefault();
    const form = document.getElementById('offer-form');
    const btn  = document.getElementById('submit-offer-btn');

    if (!form.checkValidity()) { form.reportValidity(); return; }

    const isAnkieta = document.getElementById('form-hidden-variant').value.includes('Ankiety')
                   || document.getElementById('form-hidden-variant').value.includes('Indywidualna');

    btn.textContent = 'Wysyłanie…';
    btn.disabled = true;

    // GTM event
    pushGTM({ event: 'form_submission', form_type: 'polisa_zapytanie', lead_value: document.getElementById('form-hidden-price').value });

    try {
      const res  = await fetch('https://api.web3forms.com/submit', { method: 'POST', body: new FormData(form) });
      const data = await res.json();

      if (res.ok && data.success) {
        if (isAnkieta) {
          alert('Dziękujemy! Twoje dane zostały przyjęte. Za chwilę pobierze się ankieta.');
          pushGTM({ event: 'file_download', file_name: 'AnkietaBPEH.pdf' });
          const a = document.createElement('a');
          a.href = 'AnkietaBPEH.pdf'; a.download = 'AnkietaBPEH.pdf'; a.target = '_blank';
          document.body.appendChild(a); a.click(); document.body.removeChild(a);
        } else {
          alert('Dziękujemy! Twój wniosek został przyjęty. Sprawdź skrzynkę e-mail — wkrótce się odezwiemy.');
        }
        closeModal('modal-offer');
        form.reset();
        _confettiFired = false;
      } else {
        alert('Błąd wysyłki. Sprawdź poprawność danych i spróbuj ponownie.');
      }
    } catch {
      alert('Błąd sieci. Spróbuj za chwilę.');
    } finally {
      btn.textContent = isAnkieta ? 'Wyślij dane i POBIERZ ANKIETĘ' : 'Przekaż do weryfikacji';
      btn.disabled = false;
    }
  }

  async function submitContact(e) {
    e.preventDefault();
    const form = document.getElementById('contact-form');
    const btn  = document.getElementById('submit-contact-btn');

    if (!form.checkValidity()) { form.reportValidity(); return; }

    btn.textContent = 'Wysyłanie…';
    btn.disabled = true;

    pushGTM({ event: 'form_submission', form_type: 'szybki_kontakt' });

    try {
      const res = await fetch('https://api.web3forms.com/submit', { method: 'POST', body: new FormData(form) });
      if (res.ok) {
        alert('Sukces! Przekazaliśmy Twoje dane — odezwiemy się wkrótce.');
        closeModal('modal-contact');
        form.reset();
      } else {
        alert('Błąd wysyłki. Spróbuj ponownie.');
      }
    } catch {
      alert('Błąd sieci. Spróbuj za chwilę.');
    } finally {
      btn.textContent = 'Proszę o kontakt';
      btn.disabled = false;
    }
  }

  /* ---------- HELPERS ---------- */
  function selectAll(tierId) {
    const container = document.getElementById(`list-${tierId}-container`);
    const boxes = container.querySelectorAll('input[type="checkbox"]');
    const allChecked = [...boxes].every(b => b.checked);
    boxes.forEach(b => { b.checked = !allChecked; });
    updateCalculator();
  }

  function toggleLegal() {
    const cb = document.getElementById('legal-protection');
    cb.checked = !cb.checked;
    updateCalculator();
  }

  function scrollToCalc() {
    document.getElementById('calculator-section').scrollIntoView({ behavior: 'smooth' });
  }

  function pushGTM(obj) {
    window.dataLayer = window.dataLayer || [];
    window.dataLayer.push(obj);
  }

  /* ---------- PUBLIC API ---------- */
  document.addEventListener('DOMContentLoaded', init);

  return { openModal, closeModal, openOfferModal, selectAll, toggleLegal, scrollToCalc, submitOffer, submitContact };

})();
