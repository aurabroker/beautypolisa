/* ================================================================
   BeautyKatalog · app.js  v1.0
   Shared: Supabase client, CSS, nav, utils
   Ładowany synchronicznie przed każdym *-app.js
================================================================ */
(function () {
"use strict";

/* ── SUPABASE ─────────────────────────────────────────────────── */
window.sb = supabase.createClient(
  "https://kukvgsjrmrqtzhkszzum.supabase.co",
  [
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.",
    "eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt1a3Znc2pybXJxdHpoa3N6enVtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI5MTI0NzYsImV4cCI6MjA4ODQ4ODQ3Nn0.",
    "wOB-4CJTcRksSUY7WD7CXEccTKNxPIVF8AT8hczS5zY"
  ].join("")
);

/* ── GLOBAL CSS ───────────────────────────────────────────────── */
document.head.insertAdjacentHTML("beforeend", `<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --v:#7c3aed;--vl:#ede9fe;--vd:#5b21b6;
  --pink:#e11d48;--navy:#1e293b;
  --muted:#64748b;--border:#e2e8f0;--bg:#f8fafc;
  --white:#fff;--r:1rem;
  --shadow:0 4px 24px rgba(124,58,237,.09);
}
body{font-family:'Inter',sans-serif;background:var(--bg);color:var(--navy);line-height:1.6;min-height:100vh}
h1,h2,h3,h4{font-family:'Montserrat',sans-serif;line-height:1.2}
a{color:inherit;text-decoration:none}
button{cursor:pointer;font-family:inherit}
img{max-width:100%;display:block}
input,select,textarea{font-family:inherit}

/* NAV */
#bk-nav{background:var(--white);border-bottom:1px solid var(--border);position:sticky;top:0;z-index:100;box-shadow:0 1px 4px rgba(0,0,0,.06)}
.bk-nav-inner{max-width:1280px;margin:0 auto;padding:.6rem 1.25rem;display:flex;align-items:center;gap:.75rem}
.bk-logo{font-family:'Montserrat',sans-serif;font-weight:900;font-size:1.1rem;color:var(--v);letter-spacing:-.02em;flex-shrink:0}
.bk-logo span{color:var(--pink)}
.bk-nav-links{display:flex;gap:.25rem;flex:1;overflow-x:auto;scrollbar-width:none}
.bk-nav-links::-webkit-scrollbar{display:none}
.bk-nav-link{padding:.3rem .75rem;border-radius:9999px;font-size:.8rem;font-weight:600;color:var(--muted);transition:.15s;white-space:nowrap}
.bk-nav-link:hover,.bk-nav-link.active{color:var(--v);background:var(--vl)}
.bk-nav-cta{padding:.4rem 1rem;background:var(--v);color:#fff;border-radius:9999px;font-size:.8rem;font-weight:700;transition:.15s;flex-shrink:0;white-space:nowrap}
.bk-nav-cta:hover{background:var(--vd)}

/* LAYOUT */
.bk-container{max-width:1280px;margin:0 auto;padding:0 1.25rem}

/* BUTTONS */
.bk-btn{display:inline-flex;align-items:center;justify-content:center;gap:.4rem;padding:.55rem 1.25rem;border-radius:.6rem;font-size:.875rem;font-weight:600;border:none;transition:.18s;cursor:pointer}
.bk-btn-primary{background:var(--v);color:#fff}.bk-btn-primary:hover{background:var(--vd)}
.bk-btn-primary:disabled{opacity:.6;cursor:not-allowed}
.bk-btn-outline{background:#fff;color:var(--v);border:1.5px solid var(--v)}.bk-btn-outline:hover{background:var(--vl)}

/* CARD */
.bk-card{background:var(--white);border-radius:var(--r);box-shadow:var(--shadow);border:1px solid var(--border)}

/* FORM */
.bk-input{width:100%;padding:.55rem .85rem;border:1.5px solid var(--border);border-radius:.6rem;font-size:.875rem;outline:none;transition:.15s;background:#fff}
.bk-input:focus{border-color:var(--v);box-shadow:0 0 0 3px rgba(124,58,237,.12)}
.bk-label{display:block;font-size:.75rem;font-weight:700;color:var(--muted);margin-bottom:.3rem;text-transform:uppercase;letter-spacing:.05em}

/* BADGE */
.bk-badge{display:inline-block;padding:.15rem .55rem;border-radius:9999px;font-size:.7rem;font-weight:700;background:var(--vl);color:var(--v)}

/* SPINNER */
.bk-spinner{width:2.5rem;height:2.5rem;border:3px solid var(--vl);border-top-color:var(--v);border-radius:50%;animation:bk-spin .7s linear infinite;margin:4rem auto}
@keyframes bk-spin{to{transform:rotate(360deg)}}

/* EMPTY STATE */
.bk-empty{text-align:center;padding:4rem 1rem;color:var(--muted)}
.bk-empty h3{font-size:1.1rem;margin-bottom:.5rem;color:var(--navy)}

/* TOAST */
#bk-toast{position:fixed;bottom:1.5rem;left:50%;transform:translateX(-50%);z-index:999;display:flex;flex-direction:column;gap:.5rem;align-items:center;pointer-events:none}
.bk-toast-msg{padding:.65rem 1.4rem;border-radius:9999px;font-size:.85rem;font-weight:600;color:#fff;box-shadow:0 4px 16px rgba(0,0,0,.18);animation:bk-tin .25s ease;white-space:nowrap}
.bk-toast-msg.success{background:#16a34a}.bk-toast-msg.error{background:#dc2626}.bk-toast-msg.info{background:var(--v)}
@keyframes bk-tin{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:none}}

/* MODAL */
.bk-modal-bg{position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:200;display:flex;align-items:center;justify-content:center;padding:1rem;animation:bk-fade .2s ease}
.bk-modal{background:#fff;border-radius:var(--r);padding:2rem;width:100%;max-width:520px;max-height:90vh;overflow-y:auto;position:relative}
.bk-modal-x{position:absolute;top:.75rem;right:.75rem;background:none;border:none;font-size:1.4rem;color:var(--muted);cursor:pointer;line-height:1;padding:.25rem}
@keyframes bk-fade{from{opacity:0}to{opacity:1}}

/* FOOTER */
.bk-footer{background:#1e293b;color:#94a3b8;text-align:center;padding:1.5rem;font-size:.8rem;margin-top:auto}
.bk-footer a{color:#a78bfa}

/* RESPONSIVE */
@media(max-width:640px){
  .bk-nav-cta span{display:none}
  .bk-modal{padding:1.25rem}
}
</style>`);

/* ── UTILITIES ────────────────────────────────────────────────── */
window.BK = {

  esc(s) {
    return String(s ?? "").replace(/[&<>"']/g, c =>
      ({ "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":'&#39;' }[c]));
  },

  slug(str) {
    return String(str).toLowerCase()
      .normalize("NFD").replace(/[\u0300-\u036f]/g, "")
      .replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
  },

  nav(active) {
    document.body.insertAdjacentHTML("afterbegin", `
      <nav id="bk-nav" aria-label="BeautyKatalog nawigacja">
        <div class="bk-nav-inner">
          <a href="index.html" class="bk-logo">Beauty<span>Katalog</span></a>
          <div class="bk-nav-links">
            <a href="index.html" class="bk-nav-link${active === "index" ? " active" : ""}">Katalog salonów</a>
            <a href="panel.html" class="bk-nav-link${active === "panel" ? " active" : ""}">Mój salon</a>
          </div>
          <a href="panel.html" class="bk-nav-cta">+ <span>Dodaj salon</span></a>
        </div>
      </nav>
      <div id="bk-toast" aria-live="polite"></div>`);
  },

  toast(msg, type = "info", ms = 3500) {
    const wrap = document.getElementById("bk-toast");
    if (!wrap) return;
    const el = document.createElement("div");
    el.className = `bk-toast-msg ${type}`;
    el.textContent = msg;
    wrap.appendChild(el);
    setTimeout(() => el.remove(), ms);
  },

  modal(html) {
    const bg = document.createElement("div");
    bg.className = "bk-modal-bg";
    bg.innerHTML = `<div class="bk-modal" role="dialog" aria-modal="true">
      <button class="bk-modal-x" aria-label="Zamknij">&times;</button>
      ${html}
    </div>`;
    bg.querySelector(".bk-modal-x").onclick = () => bg.remove();
    bg.onclick = e => { if (e.target === bg) bg.remove(); };
    document.body.appendChild(bg);
    bg.querySelector("input, button")?.focus();
    return bg;
  }
};

})();
