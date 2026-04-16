/* ================================================================
   BeautyKatalog · panel-app.js  v1.0
   Panel właściciela: logowanie, rejestracja, zarządzanie salonem
================================================================ */
(function () {
"use strict";

const { sb, BK } = window;

/* ── STATE ────────────────────────────────────────────────────── */
let me = null, salon = null;

/* ── INIT ─────────────────────────────────────────────────────── */
async function init() {
  BK.nav("panel");
  document.body.insertAdjacentHTML("beforeend", `<div id="bk-root"><div class="bk-spinner"></div></div>`);

  const { data: { user } } = await sb.auth.getUser();
  me = user;
  me ? await loadDashboard() : showAuth();

  sb.auth.onAuthStateChange((ev, session) => {
    me = session?.user ?? null;
    if (ev === "SIGNED_IN")  loadDashboard();
    if (ev === "SIGNED_OUT") showAuth();
  });
}

/* ══════════════════════════════════════════════════════════════
   AUTH
══════════════════════════════════════════════════════════════ */
let authMode = "login";

function showAuth() {
  document.getElementById("bk-root").innerHTML = `
    <div style="min-height:80vh;display:flex;align-items:center;justify-content:center;padding:2rem">
      <div class="bk-card" style="padding:2rem;width:100%;max-width:420px">
        <h1 style="font-size:1.4rem;color:#4c1d95;margin-bottom:.25rem">Panel właściciela</h1>
        <p style="font-size:.875rem;color:#64748b;margin-bottom:1.5rem">
          Zaloguj się lub utwórz konto, aby zarządzać swoim salonem w katalogu.
        </p>

        <!-- Tabs -->
        <div style="display:flex;gap:.4rem;background:#f1f5f9;border-radius:.6rem;padding:.25rem;margin-bottom:1.5rem">
          <button id="bk-tab-l" onclick="BKP.authTab('login')"
            style="flex:1;padding:.45rem;border:none;border-radius:.45rem;font-size:.85rem;font-weight:700;cursor:pointer;background:#fff;color:#7c3aed;box-shadow:0 1px 3px rgba(0,0,0,.08)">
            Logowanie
          </button>
          <button id="bk-tab-r" onclick="BKP.authTab('register')"
            style="flex:1;padding:.45rem;border:none;border-radius:.45rem;font-size:.85rem;font-weight:700;cursor:pointer;background:transparent;color:#64748b">
            Rejestracja
          </button>
        </div>

        <form onsubmit="BKP.authSubmit(event)">
          <div id="bk-name-row" style="display:none;margin-bottom:1rem">
            <label class="bk-label" for="bk-fullname">Imię i nazwisko</label>
            <input id="bk-fullname" type="text" class="bk-input" placeholder="Jan Kowalski" autocomplete="name">
          </div>
          <div style="margin-bottom:1rem">
            <label class="bk-label" for="bk-email">Adres e-mail</label>
            <input id="bk-email" type="email" class="bk-input" placeholder="jan@example.com" required autocomplete="email">
          </div>
          <div style="margin-bottom:1.5rem">
            <label class="bk-label" for="bk-pass">Hasło</label>
            <input id="bk-pass" type="password" class="bk-input" placeholder="••••••••" required minlength="6" autocomplete="current-password">
          </div>
          <button type="submit" id="bk-auth-btn" class="bk-btn bk-btn-primary" style="width:100%;justify-content:center;padding:.7rem">
            Zaloguj się
          </button>
          <p id="bk-auth-err" style="color:#dc2626;font-size:.8rem;margin-top:.7rem;display:none"></p>
        </form>
      </div>
    </div>
    <footer class="bk-footer">© 2026 BeautyKatalog by Aura Consulting</footer>`;
}

/* ══════════════════════════════════════════════════════════════
   DASHBOARD
══════════════════════════════════════════════════════════════ */
async function loadDashboard() {
  const root = document.getElementById("bk-root");
  root.innerHTML = `<div class="bk-spinner"></div>`;

  const { data: salonData } = await sb.from("salons").select("*").eq("owner_id", me.id).maybeSingle();
  salon = salonData ?? null;

  const [{ data: services }, { data: photos }] = await Promise.all([
    salon ? sb.from("salon_services").select("*").eq("salon_id", salon.id).order("created_at") : { data: [] },
    salon ? sb.from("salon_photos").select("*").eq("salon_id", salon.id).order("order")       : { data: [] }
  ]);

  renderDashboard(services ?? [], photos ?? []);
}

function renderDashboard(services, photos) {
  document.getElementById("bk-root").innerHTML = `
    <div class="bk-container" style="padding-top:2rem;padding-bottom:3rem;max-width:860px">

      <!-- Header -->
      <div style="display:flex;align-items:flex-start;justify-content:space-between;flex-wrap:wrap;gap:1rem;margin-bottom:2rem">
        <div>
          <h1 style="font-size:1.5rem;color:#4c1d95">${salon ? BK.esc(salon.name) : "Mój salon"}</h1>
          <p style="font-size:.82rem;color:#64748b;margin-top:.2rem">
            ${BK.esc(me.email)} ·
            <button onclick="BKP.signOut()" style="background:none;border:none;color:#dc2626;cursor:pointer;font-size:.82rem;font-weight:700">Wyloguj</button>
          </p>
        </div>
        ${salon ? `<a href="salon.html?id=${salon.id}" target="_blank" class="bk-btn bk-btn-outline" style="font-size:.82rem">👁 Podgląd profilu</a>` : ""}
      </div>

      <!-- Tabs -->
      <div style="display:flex;gap:.25rem;border-bottom:2px solid #e2e8f0;margin-bottom:1.75rem">
        ${["Profil salonu","Zabiegi","Zdjęcia"].map((t, i) => `
          <button onclick="BKP.tab(${i})" id="bk-pt${i}"
            style="padding:.6rem 1.1rem;border:none;background:none;font-family:inherit;font-size:.875rem;font-weight:700;cursor:pointer;
                   color:${i === 0 ? "#7c3aed" : "#64748b"};border-bottom:2px solid ${i === 0 ? "#7c3aed" : "transparent"};margin-bottom:-2px;transition:.15s">
            ${t}${i === 1 ? ` <span class="bk-badge" style="font-size:.65rem">${services.length}</span>` : ""}
            ${i === 2 ? ` <span class="bk-badge" style="font-size:.65rem">${photos.length}</span>` : ""}
          </button>`).join("")}
      </div>

      <div id="bk-t0">${tabProfile()}</div>
      <div id="bk-t1" style="display:none">${tabServices(services)}</div>
      <div id="bk-t2" style="display:none">${tabPhotos(photos)}</div>
    </div>
    <footer class="bk-footer">© 2026 BeautyKatalog by Aura Consulting · <a href="../index.html">BeautyPolisa OC</a></footer>`;
}

/* ══════════════════════════════════════════════════════════════
   TAB: PROFIL
══════════════════════════════════════════════════════════════ */
function tabProfile() {
  const s = salon ?? {};
  return `
    <form onsubmit="BKP.saveSalon(event)">
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;margin-bottom:1rem">
        <div>
          <label class="bk-label" for="bp-name">Nazwa salonu *</label>
          <input id="bp-name" type="text" class="bk-input" value="${BK.esc(s.name ?? "")}" required>
        </div>
        <div>
          <label class="bk-label" for="bp-city">Miasto *</label>
          <input id="bp-city" type="text" class="bk-input" value="${BK.esc(s.city ?? "")}" required placeholder="np. Warszawa">
        </div>
      </div>
      <div style="margin-bottom:1rem">
        <label class="bk-label" for="bp-addr">Adres</label>
        <input id="bp-addr" type="text" class="bk-input" value="${BK.esc(s.address ?? "")}" placeholder="ul. Przykładowa 1">
      </div>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;margin-bottom:1rem">
        <div>
          <label class="bk-label" for="bp-lat">Szerokość geogr. (lat)</label>
          <input id="bp-lat" type="number" step="any" class="bk-input" value="${s.lat ?? ""}" placeholder="52.2297">
        </div>
        <div>
          <label class="bk-label" for="bp-lng">Długość geogr. (lng)</label>
          <input id="bp-lng" type="number" step="any" class="bk-input" value="${s.lng ?? ""}" placeholder="21.0122">
        </div>
      </div>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;margin-bottom:1rem">
        <div>
          <label class="bk-label" for="bp-phone">Telefon</label>
          <input id="bp-phone" type="tel" class="bk-input" value="${BK.esc(s.phone ?? "")}" placeholder="+48 000 000 000">
        </div>
        <div>
          <label class="bk-label" for="bp-email">E-mail kontaktowy</label>
          <input id="bp-email" type="email" class="bk-input" value="${BK.esc(s.email ?? "")}" placeholder="salon@example.com">
        </div>
      </div>
      <div style="margin-bottom:1rem">
        <label class="bk-label" for="bp-web">Strona internetowa</label>
        <input id="bp-web" type="url" class="bk-input" value="${BK.esc(s.website ?? "")}" placeholder="https://mojsalon.pl">
      </div>
      <div style="margin-bottom:1.25rem">
        <label class="bk-label" for="bp-desc">Opis salonu</label>
        <textarea id="bp-desc" class="bk-input" rows="4" placeholder="Opisz swój salon — specjalizacje, atmosferę, doświadczenie...">${BK.esc(s.description ?? "")}</textarea>
      </div>
      <label style="display:flex;align-items:center;gap:.6rem;cursor:pointer;font-size:.875rem;font-weight:600;margin-bottom:1.5rem">
        <input type="checkbox" id="bp-pub" ${s.is_published ? "checked" : ""} style="accent-color:#7c3aed;width:1rem;height:1rem">
        Publikuj salon w katalogu (widoczny dla odwiedzających)
      </label>
      <button type="submit" id="bk-save-btn" class="bk-btn bk-btn-primary" style="padding:.65rem 2rem">
        Zapisz profil
      </button>
    </form>`;
}

/* ══════════════════════════════════════════════════════════════
   TAB: ZABIEGI
══════════════════════════════════════════════════════════════ */
function tabServices(services) {
  if (!salon) return noSalonMsg();
  return `
    <div>
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:1rem">
        <h2 style="font-size:1rem;color:#4c1d95">Zabiegi w ofercie</h2>
        <button onclick="BKP.addService()" class="bk-btn bk-btn-primary" style="font-size:.82rem">+ Dodaj zabieg</button>
      </div>
      <div id="bk-sv-list">
        ${services.length ? serviceList(services) : emptyServices()}
      </div>
    </div>`;
}

function serviceList(services) {
  return `
    <div class="bk-card" style="overflow:hidden">
      ${services.map((sv, i) => `
        <div style="display:flex;align-items:center;gap:.75rem;padding:.8rem 1rem;${i ? "border-top:1px solid #f1f5f9" : ""}">
          <div style="flex:1;min-width:0">
            <div style="font-weight:600;font-size:.875rem;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${BK.esc(sv.name)}</div>
            <div style="font-size:.73rem;color:#94a3b8;margin-top:.1rem">
              ${sv.category ? BK.esc(sv.category) + " · " : ""}${sv.duration_min ? sv.duration_min + " min" : ""}
            </div>
          </div>
          <div style="font-weight:700;color:#7c3aed;white-space:nowrap;font-size:.875rem">${priceStr(sv)}</div>
          <button onclick="BKP.editService('${sv.id}')"
            style="background:none;border:none;color:#7c3aed;font-size:.8rem;font-weight:700;cursor:pointer;flex-shrink:0">Edytuj</button>
          <button onclick="BKP.deleteService('${sv.id}')"
            style="background:none;border:none;color:#dc2626;font-size:.8rem;font-weight:700;cursor:pointer;flex-shrink:0">Usuń</button>
        </div>`).join("")}
    </div>`;
}

function emptyServices() {
  return `<div class="bk-empty"><h3>Brak zabiegów</h3><p>Dodaj pierwsze zabiegi klikając przycisk powyżej.</p></div>`;
}

function serviceModal(sv = {}) {
  return `
    <h2 style="font-size:1.1rem;color:#4c1d95;margin-bottom:1.25rem">${sv.id ? "Edytuj zabieg" : "Nowy zabieg"}</h2>
    <form onsubmit="BKP.saveService(event,'${sv.id ?? ""}')">
      <div style="margin-bottom:1rem">
        <label class="bk-label">Nazwa zabiegu *</label>
        <input name="name" type="text" class="bk-input" value="${BK.esc(sv.name ?? "")}" required placeholder="np. Manicure hybrydowy">
      </div>
      <div style="margin-bottom:1rem">
        <label class="bk-label">Kategoria</label>
        <input name="category" type="text" class="bk-input" value="${BK.esc(sv.category ?? "")}" placeholder="np. Manicure, Fryzjerstwo, Masaż...">
      </div>
      <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:.75rem;margin-bottom:1.5rem">
        <div>
          <label class="bk-label">Cena od (zł)</label>
          <input name="price_from" type="number" class="bk-input" value="${sv.price_from ?? ""}" min="0" step="1" placeholder="100">
        </div>
        <div>
          <label class="bk-label">Cena do (zł)</label>
          <input name="price_to" type="number" class="bk-input" value="${sv.price_to ?? ""}" min="0" step="1" placeholder="150">
        </div>
        <div>
          <label class="bk-label">Czas (min)</label>
          <input name="duration_min" type="number" class="bk-input" value="${sv.duration_min ?? ""}" min="0" step="5" placeholder="60">
        </div>
      </div>
      <button type="submit" class="bk-btn bk-btn-primary">Zapisz zabieg</button>
    </form>`;
}

/* ══════════════════════════════════════════════════════════════
   TAB: ZDJĘCIA
══════════════════════════════════════════════════════════════ */
function tabPhotos(photos) {
  if (!salon) return noSalonMsg();
  return `
    <div>
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:1rem">
        <h2 style="font-size:1rem;color:#4c1d95">Zdjęcia salonu</h2>
        <label class="bk-btn bk-btn-primary" style="font-size:.82rem;cursor:pointer">
          + Dodaj zdjęcia
          <input type="file" accept="image/*" multiple style="display:none" onchange="BKP.uploadPhotos(this)">
        </label>
      </div>

      <div id="bk-upload-bar-wrap" style="display:none;margin-bottom:1rem">
        <div style="background:#e2e8f0;border-radius:9999px;height:6px;overflow:hidden">
          <div id="bk-ubar" style="background:#7c3aed;height:100%;width:0%;transition:width .3s"></div>
        </div>
        <p id="bk-ubar-label" style="font-size:.75rem;color:#64748b;margin-top:.35rem">Przesyłanie...</p>
      </div>

      <div id="bk-ph-grid">
        ${photos.length
          ? photoGrid(photos)
          : `<div class="bk-empty"><h3>Brak zdjęć</h3><p>Dodaj zdjęcia swojego salonu — pierwsze zostanie okładką.</p></div>`}
      </div>
    </div>`;
}

function photoGrid(photos) {
  return `
    <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(180px,1fr));gap:.75rem">
      ${photos.map(p => `
        <div style="position:relative;border-radius:.75rem;overflow:hidden;border:${p.is_cover ? "3px solid #7c3aed" : "1.5px solid #e2e8f0"}">
          <img src="${BK.esc(p.url)}" alt="Zdjęcie salonu" loading="lazy"
               style="width:100%;height:155px;object-fit:cover;display:block">
          <div class="bk-ph-overlay"
               style="position:absolute;inset:0;background:rgba(0,0,0,0);display:flex;flex-direction:column;align-items:center;justify-content:center;gap:.4rem;opacity:0;transition:.18s"
               onmouseover="this.style.background='rgba(0,0,0,.48)';this.style.opacity='1'"
               onmouseout="this.style.background='rgba(0,0,0,0)';this.style.opacity='0'">
            ${p.is_cover
              ? `<span style="background:#7c3aed;color:#fff;padding:.25rem .8rem;border-radius:9999px;font-size:.7rem;font-weight:700">✓ Okładka</span>`
              : `<button onclick="BKP.setCover('${p.id}')" style="background:#fff;border:none;padding:.3rem .9rem;border-radius:9999px;font-size:.75rem;font-weight:700;cursor:pointer;color:#7c3aed">Ustaw okładkę</button>`}
            <button onclick="BKP.deletePhoto('${p.id}','${BK.esc(p.url)}')"
              style="background:#dc2626;border:none;padding:.3rem .9rem;border-radius:9999px;font-size:.75rem;font-weight:700;cursor:pointer;color:#fff">
              Usuń
            </button>
          </div>
          ${p.is_cover ? `<div style="position:absolute;top:.4rem;left:.4rem;background:#7c3aed;color:#fff;padding:.15rem .5rem;border-radius:9999px;font-size:.65rem;font-weight:700">Okładka</div>` : ""}
        </div>`).join("")}
    </div>`;
}

/* ── HELPERS ──────────────────────────────────────────────────── */
function noSalonMsg() {
  return `<div class="bk-empty"><h3>Najpierw zapisz profil salonu</h3><p>Przejdź na zakładkę „Profil salonu" i wypełnij dane.</p></div>`;
}

function priceStr(sv) {
  if (!sv.price_from && !sv.price_to) return "zapytaj";
  if (sv.price_from && sv.price_to && sv.price_to !== sv.price_from)
    return `${sv.price_from}–${sv.price_to} zł`;
  return `od ${sv.price_from ?? sv.price_to} zł`;
}

/* ══════════════════════════════════════════════════════════════
   PUBLIC API  (wywołania z HTML onclick)
══════════════════════════════════════════════════════════════ */
window.BKP = {

  /* ── AUTH ── */
  authTab(mode) {
    authMode = mode;
    const isLogin = mode === "login";
    const tabL = document.getElementById("bk-tab-l");
    const tabR = document.getElementById("bk-tab-r");
    if (!tabL) return;
    const active   = "flex:1;padding:.45rem;border:none;border-radius:.45rem;font-size:.85rem;font-weight:700;cursor:pointer;background:#fff;color:#7c3aed;box-shadow:0 1px 3px rgba(0,0,0,.08)";
    const inactive = "flex:1;padding:.45rem;border:none;border-radius:.45rem;font-size:.85rem;font-weight:700;cursor:pointer;background:transparent;color:#64748b";
    tabL.style.cssText = isLogin  ? active : inactive;
    tabR.style.cssText = !isLogin ? active : inactive;
    document.getElementById("bk-name-row").style.display = isLogin ? "none" : "block";
    document.getElementById("bk-auth-btn").textContent   = isLogin ? "Zaloguj się" : "Utwórz konto";
    document.getElementById("bk-pass").autocomplete      = isLogin ? "current-password" : "new-password";
    document.getElementById("bk-auth-err").style.display = "none";
  },

  async authSubmit(e) {
    e.preventDefault();
    const btn    = document.getElementById("bk-auth-btn");
    const errEl  = document.getElementById("bk-auth-err");
    const email  = document.getElementById("bk-email").value.trim();
    const pass   = document.getElementById("bk-pass").value;

    btn.disabled = true;
    btn.textContent = "...";
    errEl.style.display = "none";

    let error;
    if (authMode === "login") {
      ({ error } = await sb.auth.signInWithPassword({ email, password: pass }));
    } else {
      const name = document.getElementById("bk-fullname")?.value?.trim() ?? "";
      ({ error } = await sb.auth.signUp({ email, password: pass, options: { data: { full_name: name } } }));
      if (!error) {
        const uid = (await sb.auth.getUser()).data.user?.id;
        if (uid) await sb.from("katalog_profiles").upsert({ id: uid, full_name: name });
        BK.toast("Sprawdź e-mail i potwierdź konto.", "info", 7000);
      }
    }

    if (error) {
      errEl.textContent = error.message;
      errEl.style.display = "block";
      btn.disabled = false;
      btn.textContent = authMode === "login" ? "Zaloguj się" : "Utwórz konto";
    }
  },

  async signOut() {
    await sb.auth.signOut();
    BK.toast("Wylogowano.", "info");
  },

  /* ── TABS ── */
  tab(idx) {
    [0, 1, 2].forEach(i => {
      const pane = document.getElementById(`bk-t${i}`);
      const btn  = document.getElementById(`bk-pt${i}`);
      if (pane) pane.style.display = i === idx ? "block" : "none";
      if (btn) {
        btn.style.color             = i === idx ? "#7c3aed" : "#64748b";
        btn.style.borderBottomColor = i === idx ? "#7c3aed" : "transparent";
      }
    });
  },

  /* ── SALON SAVE ── */
  async saveSalon(e) {
    e.preventDefault();
    const btn = document.getElementById("bk-save-btn");
    btn.disabled = true; btn.textContent = "Zapisywanie...";

    const payload = {
      owner_id:     me.id,
      name:         document.getElementById("bp-name").value.trim(),
      slug:         BK.slug(document.getElementById("bp-name").value),
      city:         document.getElementById("bp-city").value.trim(),
      address:      document.getElementById("bp-addr").value.trim() || null,
      lat:          parseFloat(document.getElementById("bp-lat").value) || null,
      lng:          parseFloat(document.getElementById("bp-lng").value) || null,
      phone:        document.getElementById("bp-phone").value.trim() || null,
      email:        document.getElementById("bp-email").value.trim() || null,
      website:      document.getElementById("bp-web").value.trim() || null,
      description:  document.getElementById("bp-desc").value.trim() || null,
      is_published: document.getElementById("bp-pub").checked
    };

    let error;
    if (salon) {
      ({ error } = await sb.from("salons").update(payload).eq("id", salon.id));
    } else {
      const { data, error: ie } = await sb.from("salons").insert(payload).select().single();
      error = ie;
      if (!error) salon = data;
    }

    btn.disabled = false; btn.textContent = "Zapisz profil";
    if (error) { BK.toast(error.message, "error"); }
    else { BK.toast("Profil zapisany!", "success"); await loadDashboard(); }
  },

  /* ── SERVICES ── */
  addService() { BK.modal(serviceModal()); },

  async editService(id) {
    const { data } = await sb.from("salon_services").select("*").eq("id", id).single();
    if (data) BK.modal(serviceModal(data));
  },

  async saveService(e, id) {
    e.preventDefault();
    const fd = new FormData(e.target);
    const num = key => { const v = fd.get(key); return v ? parseInt(v) : null; };
    const payload = {
      salon_id:     salon.id,
      name:         fd.get("name"),
      category:     fd.get("category") || null,
      price_from:   num("price_from"),
      price_to:     num("price_to"),
      duration_min: num("duration_min")
    };

    const { error } = id
      ? await sb.from("salon_services").update(payload).eq("id", id)
      : await sb.from("salon_services").insert(payload);

    if (error) { BK.toast(error.message, "error"); return; }
    document.querySelector(".bk-modal-bg")?.remove();
    BK.toast("Zabieg zapisany!", "success");
    await loadDashboard();
    setTimeout(() => BKP.tab(1), 80);
  },

  async deleteService(id) {
    if (!confirm("Usunąć ten zabieg?")) return;
    const { error } = await sb.from("salon_services").delete().eq("id", id);
    if (error) { BK.toast(error.message, "error"); return; }
    BK.toast("Zabieg usunięty.", "info");
    await loadDashboard();
    setTimeout(() => BKP.tab(1), 80);
  },

  /* ── PHOTOS ── */
  async uploadPhotos(input) {
    const files = Array.from(input.files);
    if (!files.length || !salon) return;

    const wrap  = document.getElementById("bk-upload-bar-wrap");
    const bar   = document.getElementById("bk-ubar");
    const label = document.getElementById("bk-ubar-label");
    wrap.style.display = "block";

    let done = 0;
    for (const file of files) {
      const ext  = file.name.split(".").pop().toLowerCase();
      const path = `${salon.id}/${crypto.randomUUID()}.${ext}`;

      const { error: upErr } = await sb.storage.from("salon-photos").upload(path, file, { upsert: true });
      if (upErr) { BK.toast(`Błąd przesyłania: ${upErr.message}`, "error"); done++; continue; }

      const { data: { publicUrl } } = sb.storage.from("salon-photos").getPublicUrl(path);
      const isCover = done === 0 && (salon ? !(await sb.from("salon_photos").select("id").eq("salon_id", salon.id).limit(1)).data?.length : true);
      await sb.from("salon_photos").insert({ salon_id: salon.id, url: publicUrl, is_cover: isCover, order: 99 });

      done++;
      bar.style.width = `${(done / files.length) * 100}%`;
      label.textContent = `Przesłano ${done} z ${files.length}...`;
    }

    wrap.style.display = "none";
    BK.toast(`Dodano ${done} zdjęć!`, "success");
    await loadDashboard();
    setTimeout(() => BKP.tab(2), 80);
  },

  async setCover(id) {
    await sb.from("salon_photos").update({ is_cover: false }).eq("salon_id", salon.id);
    await sb.from("salon_photos").update({ is_cover: true }).eq("id", id);
    BK.toast("Okładka ustawiona.", "success");
    await loadDashboard();
    setTimeout(() => BKP.tab(2), 80);
  },

  async deletePhoto(id, url) {
    if (!confirm("Usunąć to zdjęcie?")) return;
    const path = url.split("/salon-photos/").pop();
    if (path) await sb.storage.from("salon-photos").remove([path]);
    await sb.from("salon_photos").delete().eq("id", id);
    BK.toast("Zdjęcie usunięte.", "info");
    await loadDashboard();
    setTimeout(() => BKP.tab(2), 80);
  }
};

/* ── BOOT ─────────────────────────────────────────────────────── */
init();

})();
