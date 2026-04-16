/* ================================================================
   BeautyKatalog · index-app.js  v1.0
   Strona główna katalogu: wyszukiwarka, filtry, siatka salonów, mapa
================================================================ */
(function () {
"use strict";

const { sb, BK } = window;

let allSalons = [], filtered = [], mapInstance = null, mapMarkers = [];
let searchQ = "", filterCity = "", showMap = false;
const PER_PAGE = 12;
let page = 0;

function buildShell() {
  BK.nav("index");
  document.body.insertAdjacentHTML("beforeend", `
    <section style="background:linear-gradient(135deg,#3b0764 0%,#7c3aed 55%,#a855f7 100%);padding:4rem 0 3rem;color:#fff">
      <div class="bk-container">
        <p style="font-size:.8rem;font-weight:700;letter-spacing:.12em;text-transform:uppercase;opacity:.7;margin-bottom:.5rem">BeautyKatalog · Polska</p>
        <h1 style="font-size:clamp(1.8rem,5vw,3rem);margin-bottom:.6rem">Znajdź salon beauty<br>w swoim mieście</h1>
        <p style="font-size:1rem;opacity:.8;margin-bottom:2rem;max-width:520px">Przeglądaj salony kosmetyczne, fryzjerskie, podologiczne i kosmetologiczne w całej Polsce.</p>
        <div style="display:flex;gap:.6rem;max-width:580px">
          <input id="bk-search" type="search" placeholder="Szukaj salonu, miasta, zabiegu..."
            style="flex:1;padding:.8rem 1.1rem;border:none;border-radius:.7rem;font-size:.95rem;outline:none;font-family:inherit"
            aria-label="Szukaj salonów">
          <button onclick="BKI.doSearch()" class="bk-btn bk-btn-primary"
            style="padding:.8rem 1.5rem;font-size:.95rem;flex-shrink:0;border-radius:.7rem;background:#fff;color:#7c3aed">
            Szukaj
          </button>
        </div>
      </div>
    </section>
    <div style="background:#fff;border-bottom:1px solid #e2e8f0;position:sticky;top:58px;z-index:90">
      <div class="bk-container" style="padding-top:.65rem;padding-bottom:.65rem;display:flex;align-items:center;gap:.75rem;flex-wrap:wrap">
        <select id="bk-city" onchange="BKI.doSearch()" class="bk-input" style="width:auto;min-width:170px" aria-label="Filtruj po mieście">
          <option value="">Wszystkie miasta</option>
        </select>
        <span id="bk-count" style="font-size:.8rem;color:#64748b;font-weight:600;margin-left:auto"></span>
        <button id="bk-map-btn" onclick="BKI.toggleMap()" class="bk-btn bk-btn-outline" style="padding:.4rem .9rem;font-size:.8rem">🗺 Mapa</button>
      </div>
    </div>
    <main class="bk-container" style="padding-top:1.75rem;padding-bottom:3rem">
      <div id="bk-map" style="display:none;height:420px;border-radius:1rem;overflow:hidden;margin-bottom:1.75rem;border:1px solid #e2e8f0"></div>
      <div id="bk-grid" style="display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:1.25rem" role="list"></div>
      <div id="bk-more" style="text-align:center;margin-top:2rem;display:none">
        <button onclick="BKI.loadMore()" class="bk-btn bk-btn-outline" style="padding:.65rem 2rem">Załaduj więcej</button>
      </div>
    </main>
    <footer class="bk-footer">© 2026 BeautyKatalog by Aura Consulting · <a href="../index.html">BeautyPolisa OC</a></footer>
  `);
  document.getElementById("bk-search").addEventListener("keydown", e => { if (e.key === "Enter") BKI.doSearch(); });
}

async function fetchSalons() {
  document.getElementById("bk-grid").innerHTML = `<div class="bk-spinner" style="grid-column:1/-1"></div>`;
  const { data, error } = await sb
    .from("salons")
    .select("id,name,slug,city,street,tagline,description,lat,lng,salon_photos(url,is_cover),salon_services(id)")
    .eq("status", "active")
    .order("created_at", { ascending: false });
  if (error) {
    document.getElementById("bk-grid").innerHTML =
      `<div class="bk-empty" style="grid-column:1/-1"><h3>Nie udało się załadować salonów</h3><p>${BK.esc(error.message)}</p></div>`;
    return;
  }
  allSalons = data ?? [];
  fillCities();
  applyFilters();
}

function fillCities() {
  const sel = document.getElementById("bk-city");
  const cities = [...new Set(allSalons.map(s => s.city).filter(Boolean))].sort((a, b) => a.localeCompare(b, "pl"));
  cities.forEach(c => { const o = document.createElement("option"); o.value = c; o.textContent = c; sel.appendChild(o); });
}

function applyFilters() {
  const q = searchQ.trim().toLowerCase();
  filtered = allSalons.filter(s => {
    if (filterCity && s.city !== filterCity) return false;
    if (q && !`${s.name} ${s.city} ${s.description ?? ""}`.toLowerCase().includes(q)) return false;
    return true;
  });
  page = 0;
  document.getElementById("bk-count").textContent =
    filtered.length === 1 ? "1 salon" : filtered.length < 5 ? `${filtered.length} salony` : `${filtered.length} salonów`;
  renderCards(true);
  if (showMap) refreshMap();
}

function renderCards(reset) {
  const grid = document.getElementById("bk-grid");
  const end = (page + 1) * PER_PAGE;
  if (reset) {
    grid.innerHTML = filtered.length === 0
      ? `<div class="bk-empty" style="grid-column:1/-1"><h3>Brak wyników</h3><p>Spróbuj innych słów kluczowych lub usuń filtry.</p></div>`
      : filtered.slice(0, end).map(card).join("");
  } else {
    filtered.slice(page * PER_PAGE, end).forEach(s => grid.insertAdjacentHTML("beforeend", card(s)));
  }
  document.getElementById("bk-more").style.display = filtered.length > end ? "block" : "none";
}

function card(s) {
  const cover = s.salon_photos?.find(p => p.is_cover)?.url ?? s.salon_photos?.[0]?.url ?? "";
  const cnt = s.salon_services?.length ?? 0;
  return `
    <a href="salon.html?id=${BK.esc(s.id)}" role="listitem" class="bk-card"
       style="display:block;overflow:hidden;text-decoration:none;color:inherit;transition:transform .2s,box-shadow .2s"
       onmouseover="this.style.transform='translateY(-3px)';this.style.boxShadow='0 12px 32px rgba(124,58,237,.15)'"
       onmouseout="this.style.transform='';this.style.boxShadow=''">
      <div style="height:190px;overflow:hidden;background:linear-gradient(135deg,#ede9fe,#ddd6fe);position:relative">
        ${cover ? `<img src="${BK.esc(cover)}" alt="${BK.esc(s.name)}" loading="lazy" style="width:100%;height:100%;object-fit:cover">` : `<div style="display:flex;align-items:center;justify-content:center;height:100%;font-size:3.5rem">💅</div>`}
      </div>
      <div style="padding:1.1rem">
        <div style="display:flex;align-items:flex-start;justify-content:space-between;gap:.5rem;margin-bottom:.35rem">
          <h2 style="font-size:.975rem">${BK.esc(s.name)}</h2>
          ${cnt ? `<span class="bk-badge" style="flex-shrink:0">${cnt}&nbsp;zab.</span>` : ""}
        </div>
        <p style="font-size:.8rem;color:#64748b;margin-bottom:.5rem">📍 ${BK.esc(s.city)}${s.street ? `, ${BK.esc(s.street)}` : ""}</p>
        ${(s.tagline || s.description) ? `<p style="font-size:.82rem;color:#475569;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden;margin-bottom:.5rem">${BK.esc(s.tagline || s.description)}</p>` : ""}
        <span style="font-size:.8rem;color:#7c3aed;font-weight:700">Zobacz profil →</span>
      </div>
    </a>`;
}

function refreshMap() {
  if (!mapInstance) {
    mapInstance = L.map("bk-map").setView([52.0, 19.0], 6);
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", { attribution: '© <a href="https://openstreetmap.org">OpenStreetMap</a>' }).addTo(mapInstance);
  }
  mapMarkers.forEach(m => m.remove());
  mapMarkers = filtered.filter(s => s.lat && s.lng).map(s => {
    const m = L.marker([s.lat, s.lng]).addTo(mapInstance);
    m.bindPopup(`<b>${s.name}</b><br>${BK.esc(s.city)}<br><a href="salon.html?id=${s.id}">Zobacz profil →</a>`);
    return m;
  });
}

window.BKI = {
  doSearch() { searchQ = document.getElementById("bk-search").value; filterCity = document.getElementById("bk-city").value; applyFilters(); },
  loadMore() { page++; renderCards(false); },
  toggleMap() {
    showMap = !showMap;
    document.getElementById("bk-map").style.display = showMap ? "block" : "none";
    document.getElementById("bk-map-btn").textContent = showMap ? "☰ Lista" : "🗺 Mapa";
    if (showMap) { refreshMap(); setTimeout(() => mapInstance?.invalidateSize(), 150); }
  }
};

buildShell();
fetchSalons();

})();
