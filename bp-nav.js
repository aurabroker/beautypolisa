/* ================================================================
   BeautyPolisa · bp-nav.js  v1.0
   Wspólny header z paskiem produktów — do wstawienia na każdej stronie.
   Konfiguracja: <script>window.BP_PAGE = 'oc'</script> przed tym plikiem.
================================================================ */
(function () {
"use strict";

/* ── PRODUKTY ───────────────────────────────────────────────── */
const PRODUCTS = [
  { id: "oc",      href: "new.html",         icon: "🛡️",  name: "OC",          title: "OC Zawodowe" },
  { id: "tax",     href: "tax-protect.html", icon: "⚖️",  name: "Tax Protect", title: "Ochrona Karno-Skarbowa" },
  { id: "l4",      href: "#",               icon: "🩺",  name: "Prywatne L4", title: "Utrata Dochodu" },
  { id: "medical", href: "medical.html",     icon: "➕",  name: "Opieka Med.", title: "Opieka Medyczna" },
  { id: "life",    href: "life1.html",       icon: "💙",  name: "Życie",       title: "Ubezpieczenie Życia" },
  { id: "nnw",     href: "#",               icon: "⭐",  name: "NNW Dzieci",  title: "NNW Dzieci" },
];

/* ── CSS ────────────────────────────────────────────────────── */
const CSS = `
:root{
  --nav-navy:#2a3b69;--nav-pink:#e11d48;--nav-bg:#ffffff;
  --nav-border:#e2e8f0;--nav-text:#1e293b;--nav-muted:#64748b;--nav-sub:#f8fafc;
}
html.dark{
  --nav-bg:#0f172a;--nav-border:#334155;--nav-text:#e2e8f0;
  --nav-muted:#94a3b8;--nav-sub:#1e293b;
}
#bp-header{
  background:var(--nav-bg);backdrop-filter:blur(14px);-webkit-backdrop-filter:blur(14px);
  border-bottom:1px solid var(--nav-border);position:sticky;top:0;z-index:50;
  box-shadow:0 1px 6px rgba(0,0,0,.07);transition:background .3s;
}
.bp-hdr-inner{
  max-width:1280px;margin:0 auto;padding:.35rem 1.25rem;
  display:flex;align-items:center;gap:.5rem;
}
/* Logo */
.bp-hdr-logo{display:flex;align-items:center;gap:.4rem;text-decoration:none;flex-shrink:0;margin-right:.5rem}
.bp-hdr-logo-text{font-family:'Montserrat',sans-serif;font-size:1rem;font-weight:800;
  color:var(--nav-navy);letter-spacing:-.02em;line-height:1}
.bp-hdr-logo-sub{font-size:7px;color:var(--nav-muted);font-weight:700;text-transform:uppercase;letter-spacing:.12em}
.bp-hdr-sep{width:1px;height:1.4rem;background:var(--nav-border);flex-shrink:0;margin:0 .25rem}
/* Product tabs */
.bp-hdr-products{display:flex;align-items:center;gap:.2rem;flex:1;overflow-x:auto;scrollbar-width:none;-ms-overflow-style:none}
.bp-hdr-products::-webkit-scrollbar{display:none}
.bp-prod-tab{
  display:inline-flex;align-items:center;gap:.25rem;
  padding:.28rem .6rem;border-radius:9999px;border:1px solid transparent;
  font-family:'Montserrat',sans-serif;font-size:.68rem;font-weight:600;
  color:var(--nav-muted);text-decoration:none;white-space:nowrap;
  cursor:pointer;transition:all .18s;flex-shrink:0;
}
.bp-prod-tab:hover{color:var(--nav-navy);background:var(--nav-sub);border-color:var(--nav-border)}
.bp-prod-tab.active{color:var(--nav-navy);background:var(--nav-sub);border-color:var(--nav-border);font-weight:700}
.bp-prod-tab.active .bp-prod-icon{opacity:1}
.bp-prod-tab[href="#"]{opacity:.5;cursor:default}
.bp-prod-tab[href="#"]:hover{background:transparent;border-color:transparent;color:var(--nav-muted)}
.bp-prod-icon{font-size:.8rem;line-height:1}
/* Right side */
.bp-hdr-right{display:flex;align-items:center;gap:.4rem;flex-shrink:0;margin-left:auto}
.bp-dark-toggle{
  background:none;border:1px solid var(--nav-border);border-radius:9999px;
  padding:.22rem .5rem;cursor:pointer;font-size:.75rem;line-height:1;
  transition:all .2s;color:var(--nav-text);flex-shrink:0;
}
.bp-dark-toggle:hover{border-color:var(--nav-navy)}
/* dark overrides for body / page */
html.dark body{background:#0f172a !important;color:#e2e8f0 !important}
html.dark .hero-gradient{background:linear-gradient(135deg,#0d1f3c 0%,#0f172a 100%) !important}
html.dark .bg-white,html.dark .bg-white\\/90,html.dark .bg-white\\/95,html.dark .bg-white\\/80{background:#162032 !important}
html.dark .bg-slate-50,html.dark .bg-gray-50{background:#1e293b !important}
html.dark .bg-slate-100,html.dark .bg-gray-100{background:#1e293b !important}
html.dark .text-slate-600,html.dark .text-slate-500,html.dark .text-gray-600{color:#94a3b8 !important}
html.dark .text-slate-700,html.dark .text-slate-800,html.dark .text-gray-700,html.dark .text-gray-800,html.dark .text-slate-900{color:#e2e8f0 !important}
html.dark .border-slate-100,html.dark .border-slate-200,html.dark .border-gray-200{border-color:#334155 !important}
html.dark .shadow-sm,html.dark .shadow-md,html.dark .shadow-lg{box-shadow:0 1px 6px rgba(0,0,0,.4) !important}
html.dark .rounded-3xl.bg-white,html.dark .rounded-2xl.bg-white{background:#162032 !important}
@media(max-width:640px){
  .bp-hdr-logo-sub{display:none}
  .bp-prod-tab .bp-prod-name{display:none}
  .bp-prod-tab{padding:.28rem .45rem;gap:0}
}
`;

/* ── HELPERS ────────────────────────────────────────────────── */
function getDark() { return localStorage.getItem("bp_dark") === "1"; }

function syncBtn() {
  const btn = document.getElementById("bp-dark-toggle");
  if (btn) btn.textContent = document.documentElement.classList.contains("dark") ? "☀️" : "🌙";
}

function toggleDark() {
  const isDark = document.documentElement.classList.toggle("dark");
  localStorage.setItem("bp_dark", isDark ? "1" : "0");
  syncBtn();
}

/* ── BUILD ──────────────────────────────────────────────────── */
function build() {
  if (getDark()) document.documentElement.classList.add("dark");

  document.head.insertAdjacentHTML("beforeend", `<style>${CSS}</style>`);

  const active = window.BP_PAGE || "oc";
  const tabs = PRODUCTS.map(p => `
    <a href="${p.href}" class="bp-prod-tab${p.id === active ? " active" : ""}" title="${p.title}">
      <span class="bp-prod-icon">${p.icon}</span>
      <span class="bp-prod-name">${p.name}</span>
    </a>`).join("");

  const el = document.createElement("header");
  el.id = "bp-header";
  el.innerHTML = `
    <div class="bp-hdr-inner">
      <a class="bp-hdr-logo" href="new.html">
        <div>
          <div class="bp-hdr-logo-text">BeautyPolisa</div>
          <div class="bp-hdr-logo-sub">Aura Consulting</div>
        </div>
      </a>
      <div class="bp-hdr-sep"></div>
      <nav class="bp-hdr-products" aria-label="Produkty BeautyPolisa">${tabs}</nav>
      <div class="bp-hdr-right">
        <button id="bp-dark-toggle" class="bp-dark-toggle" onclick="bpNav.toggleDark()" title="Tryb ciemny">🌙</button>
        <div id="bp-hdr-auth"></div>
      </div>
    </div>`;

  document.body.insertBefore(el, document.body.firstChild);
  syncBtn();
}

/* ── INIT ───────────────────────────────────────────────────── */
if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", build);
} else {
  build();
}

/* ── EXPOSE ─────────────────────────────────────────────────── */
window.bpNav = { toggleDark, syncBtn };

})();
