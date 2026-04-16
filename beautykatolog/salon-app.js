/* ================================================================
   BeautyKatalog · salon-app.js  v1.0
   Profil pojedynczego salonu
================================================================ */
(function () {
"use strict";

const { sb, BK } = window;

/* ── INIT ─────────────────────────────────────────────────────── */
async function init() {
  BK.nav("");

  const params = new URLSearchParams(location.search);
  const id     = params.get("id");
  const slug   = params.get("slug");

  document.body.insertAdjacentHTML("beforeend",
    `<div id="bk-root"><div class="bk-spinner"></div></div>`);

  if (!id && !slug) { renderError("Brak identyfikatora salonu."); return; }

  let q = sb.from("salons").select(`
    id, name, slug, tagline, description, city, street, postal_code,
    lat, lng, phone, email_contact, website, status,
    instagram_url, facebook_url,
    salon_photos(id, url, is_cover, sort_order),
    salon_services(id, service_name, price_from, price_to, duration_min, group_id, is_available)
  `);

  q = id ? q.eq("id", id) : q.eq("slug", slug);

  const { data, error } = await q.maybeSingle();

  if (error)  { renderError(error.message); return; }
  if (!data)  { renderError("Salon nie został znaleziony."); return; }
  if (data.status !== "active") { renderError("Profil salonu jest nieaktywny."); return; }

  renderSalon(data);
}

/* ── ERROR ────────────────────────────────────────────────────── */
function renderError(msg) {
  document.getElementById("bk-root").innerHTML = `
    <div class="bk-container bk-empty" style="padding-top:5rem">
      <h3>Ups!</h3>
      <p>${BK.esc(msg)}</p>
      <a href="index.html" class="bk-btn bk-btn-primary" style="margin-top:1.25rem;display:inline-flex">
        ← Wróć do katalogu
      </a>
    </div>`;
}

/* ── RENDER SALON ─────────────────────────────────────────────── */
function renderSalon(s) {
  document.title = `${s.name} — BeautyKatalog`;

  const photos   = (s.salon_photos ?? []).filter(p => p.url).sort((a, b) => (a.sort_order ?? 99) - (b.sort_order ?? 99));
  const cover    = photos.find(p => p.is_cover)?.url ?? photos[0]?.url ?? "";
  const services = (s.salon_services ?? []).filter(sv => sv.is_available !== false);

  const GROUP_NAMES = { 1:"Fryzjerstwo", 2:"Kosmetyka", 3:"Paznokcie", 4:"Masaż i SPA", 5:"Medycyna estetyczna" };
  const grouped = {};
  services.forEach(sv => {
    const cat = GROUP_NAMES[sv.group_id] || "Inne zabiegi";
    (grouped[cat] = grouped[cat] ?? []).push(sv);
  });

  document.getElementById("bk-root").innerHTML = `

    <!-- COVER -->
    <div style="height:300px;background:${cover ? "none" : "linear-gradient(135deg,#3b0764,#7c3aed)"};overflow:hidden;position:relative">
      ${cover
        ? `<img src="${BK.esc(cover)}" alt="Zdjęcie salonu ${BK.esc(s.name)}" style="width:100%;height:100%;object-fit:cover">`
        : `<div style="display:flex;align-items:center;justify-content:center;height:100%;font-size:5rem">💅</div>`}
      <div style="position:absolute;inset:0;background:linear-gradient(to top,rgba(0,0,0,.65) 0%,transparent 55%)"></div>
      <div style="position:absolute;bottom:1.75rem;left:1.75rem;color:#fff;max-width:700px">
        <h1 style="font-size:clamp(1.5rem,4vw,2.4rem);text-shadow:0 2px 10px rgba(0,0,0,.5)">
          ${BK.esc(s.name)}
        </h1>
        <p style="opacity:.9;font-size:.9rem;margin-top:.3rem">
          📍 ${BK.esc(s.city)}${s.street ? `, ${BK.esc(s.street)}` : ""}${s.postal_code ? ` ${BK.esc(s.postal_code)}` : ""}
        </p>
      </div>
    </div>

    <!-- CONTENT GRID -->
    <div class="bk-container" id="bk-salon-grid"
         style="padding-top:2rem;padding-bottom:3rem;display:grid;grid-template-columns:1fr 340px;gap:2rem;align-items:start">

      <!-- ── LEFT ── -->
      <div>

        ${s.description ? `
        <section style="margin-bottom:2rem">
          <h2 style="font-size:1.05rem;color:#4c1d95;margin-bottom:.7rem">O salonie</h2>
          <p style="color:#475569;line-height:1.75;white-space:pre-line">${BK.esc(s.description)}</p>
        </section>` : ""}

        ${Object.keys(grouped).length ? `
        <section style="margin-bottom:2rem">
          <h2 style="font-size:1.05rem;color:#4c1d95;margin-bottom:.9rem">Zabiegi i cennik</h2>
          ${Object.entries(grouped).map(([cat, svs]) => `
            <div style="margin-bottom:1.25rem">
              <h3 style="font-size:.78rem;font-weight:800;text-transform:uppercase;letter-spacing:.07em;color:#7c3aed;margin-bottom:.5rem">
                ${BK.esc(cat)}
              </h3>
              <div class="bk-card" style="overflow:hidden">
                ${svs.map((sv, i) => `
                  <div style="display:flex;align-items:center;justify-content:space-between;gap:1rem;
                              padding:.75rem 1rem;${i ? "border-top:1px solid #f1f5f9" : ""}">
                    <div>
                      <div style="font-size:.9rem;font-weight:500">${BK.esc(sv.service_name)}</div>
                      ${sv.duration_min ? `<div style="font-size:.73rem;color:#94a3b8;margin-top:.1rem">⏱ ${sv.duration_min} min</div>` : ""}
                    </div>
                    <div style="text-align:right;font-weight:700;color:#7c3aed;white-space:nowrap;font-size:.88rem;flex-shrink:0">
                      ${priceStr(sv)}
                    </div>
                  </div>`).join("")}
              </div>
            </div>`).join("")}
        </section>` : ""}

        ${photos.length > 1 ? `
        <section style="margin-bottom:2rem">
          <h2 style="font-size:1.05rem;color:#4c1d95;margin-bottom:.9rem">Zdjęcia</h2>
          <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:.6rem">
            ${photos.map(p => `
              <img src="${BK.esc(p.url)}" alt="Zdjęcie ${BK.esc(s.name)}" loading="lazy"
                   style="width:100%;height:150px;object-fit:cover;border-radius:.6rem;cursor:zoom-in"
                   onclick="window.open('${BK.esc(p.url)}','_blank')">`).join("")}
          </div>
        </section>` : ""}

      </div><!-- /LEFT -->

      <!-- ── RIGHT (sidebar) ── -->
      <aside style="position:sticky;top:80px;display:flex;flex-direction:column;gap:1rem">

        <!-- Contact -->
        <div class="bk-card" style="padding:1.25rem">
          <h3 style="font-size:.85rem;font-weight:700;text-transform:uppercase;letter-spacing:.06em;color:#4c1d95;margin-bottom:.85rem">Kontakt</h3>
          ${contactRow("📞", s.phone ? `<a href="tel:${BK.esc(s.phone)}">${BK.esc(s.phone)}</a>` : "")}
          ${contactRow("✉️", s.email_contact ? `<a href="mailto:${BK.esc(s.email_contact)}">${BK.esc(s.email_contact)}</a>` : "")}
          ${contactRow("🌐", s.website ? `<a href="${BK.esc(s.website)}" target="_blank" rel="noopener" style="color:#7c3aed">Strona internetowa ↗</a>` : "")}
          ${!s.phone && !s.email && !s.website
            ? `<p style="font-size:.82rem;color:#94a3b8">Brak danych kontaktowych</p>` : ""}
        </div>

        <!-- Mini map -->
        ${s.lat && s.lng ? `
        <div class="bk-card" style="overflow:hidden;padding:0">
          <div id="bk-mini-map" style="height:210px"></div>
        </div>` : ""}

        <!-- Owner CTA -->
        <div class="bk-card" style="padding:1.25rem;text-align:center;background:#faf5ff;border-color:#ddd6fe">
          <p style="font-size:.8rem;color:#64748b;margin-bottom:.75rem">Jesteś właścicielem tego salonu?</p>
          <a href="panel.html" class="bk-btn bk-btn-outline" style="width:100%;justify-content:center">
            Zarządzaj profilem
          </a>
        </div>

        <a href="index.html" style="font-size:.8rem;color:#7c3aed;font-weight:700;text-align:center">
          ← Wróć do katalogu
        </a>

      </aside>

    </div><!-- /GRID -->

    <footer class="bk-footer">
      © 2026 BeautyKatalog by Aura Consulting · <a href="../index.html">BeautyPolisa OC</a>
    </footer>`;

  /* responsive sidebar — na mobile jednokolumnowe */
  const mq = window.matchMedia("(max-width:768px)");
  function applyMQ(e) {
    const grid = document.getElementById("bk-salon-grid");
    if (grid) grid.style.gridTemplateColumns = e.matches ? "1fr" : "1fr 340px";
  }
  applyMQ(mq);
  mq.addEventListener("change", applyMQ);

  /* mini mapa */
  if (s.lat && s.lng) {
    const map = L.map("bk-mini-map", { zoomControl: false, scrollWheelZoom: false })
      .setView([s.lat, s.lng], 15);
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
      { attribution: '© <a href="https://openstreetmap.org">OSM</a>' }
    ).addTo(map);
    L.marker([s.lat, s.lng]).addTo(map).bindPopup(s.name).openPopup();
  }
}

/* ── HELPERS ──────────────────────────────────────────────────── */
function priceStr(sv) {
  if (!sv.price_from && !sv.price_to) return "zapytaj";
  if (sv.price_from && sv.price_to && sv.price_to !== sv.price_from)
    return `${sv.price_from}–${sv.price_to} zł`;
  return `od ${sv.price_from ?? sv.price_to} zł`;
}

function contactRow(icon, html) {
  if (!html) return "";
  return `<div style="display:flex;align-items:center;gap:.5rem;font-size:.875rem;margin-bottom:.5rem;color:#1e293b">
    <span>${icon}</span>${html}
  </div>`;
}

/* ── BOOT ─────────────────────────────────────────────────────── */
init();

})();
