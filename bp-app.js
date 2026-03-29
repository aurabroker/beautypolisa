/* ================================================================
   BeautyPolisa · bp-app.js  v4.0
   © 2026 Aura Consulting sp. z o.o.
================================================================ */
(function () {
"use strict";

/* ── ANTI-INSPECT ───────────────────────────────────────────── */
document.addEventListener("contextmenu", e => e.preventDefault());
document.addEventListener("keydown", e => {
  if (e.key === "F12" ||
    (e.ctrlKey && e.shiftKey && ["I","J","C","K"].includes(e.key)) ||
    (e.ctrlKey && ["u","s","p"].includes(e.key.toLowerCase()))) {
    e.preventDefault(); return false;
  }
});
setInterval(() => { const t = performance.now(); debugger; if (performance.now() - t > 100) document.body.innerHTML = ""; }, 4000);

/* ── SUPABASE ───────────────────────────────────────────────── */
const _u = ["https://kukvgsjrmrqtzhkszzum", ".supabase.co"].join("");
const _k = [
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.",
  "eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt1a3Znc2pybXJxdHpoa3N6enVtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI5MTI0NzYsImV4cCI6MjA4ODQ4ODQ3Nn0.",
  "wOB-4CJTcRksSUY7WD7CXEccTKNxPIVF8AT8hczS5zY"
].join("");
const sb = supabase.createClient(_u, _k);

/* ── STATE ──────────────────────────────────────────────────── */
let _user = null, _profile = null;

/* ── SESSION ANALYTICS ID ──────────────────────────────────── */
function getSessionId() {
  let sid = sessionStorage.getItem("bp_sid");
  if (!sid) { sid = crypto.randomUUID ? crypto.randomUUID() : Math.random().toString(36).slice(2) + Date.now(); sessionStorage.setItem("bp_sid", sid); }
  return sid;
}
function getDevice() {
  const w = window.innerWidth;
  return w < 768 ? "mobile" : w < 1024 ? "tablet" : "desktop";
}
async function trackVisit() {
  try {
    const params = new URLSearchParams(window.location.search);
    await sb.from("bp_analytics").insert({
      session_id:   getSessionId(),
      page:         window.location.pathname.split("/").pop() || "BP_index.html",
      referrer:     document.referrer.slice(0, 200) || null,
      utm_source:   params.get("utm_source"),
      utm_medium:   params.get("utm_medium"),
      utm_campaign: params.get("utm_campaign"),
      device:       getDevice(),
      screen_w:     window.innerWidth,
      user_id:      _user?.id || null
    });
  } catch (_) { /* silent */ }
}

/* ── TARIFFS ────────────────────────────────────────────────── */
const PRICING = {
  1: { s100: 400, s200: 500, s300: 650 },
  2: { s100: 650, s200: 790, s300: 950 },
  3: { s100: 850, s200: 980, s300: 1250 }
};
const LEGAL = 92;

const PROCS = {
  1: ["Barbering","Depilacja pastą cukrową","Depilacja woskiem",
      "Dermabrazja i peeling skóry głowy","Diagnoza skóry głowy i USG włosa",
      "Elektrostymulacja","Endermologia – masaż podciśnieniowy","Golenie głowy",
      "Henna","Koloryzacja i dekoloryzacja włosów","Kosmetyczna diagnostyka trychologiczna",
      "Kosmetyczny zabieg trychologiczny","Kuracje nawilżające i odbudowujące włosy",
      "Laminowanie brwi i rzęs","Laminowanie włosów","Makijaż","Manicure",
      "Manualne oczyszczanie twarzy","Masaż bańką chińską","Masaż endodermiczny i drenaż limfatyczny",
      "Masaż manualny ciała i twarzy","Mycie i suszenie włosów","Oczyszczanie włosów",
      "Pasemka i baleyage","Pedicure kosmetyczny","Piercing – przekłuwanie",
      "Presoterapia","Przekłuwanie uszu","Przedłużanie i zagęszczanie rzęs",
      "Przedłużanie włosów","Prostowanie włosów na stałe","Retusz siwizny",
      "Sauna na włosy","Strzyżenie (nożyczki, maszynka, brzytwa, Split-ender)",
      "Trwała ondulacja","Zabiegi z zastosowaniem składników aktywnych",
      "Zabiegi keratynowe","Zabiegi przeciwłupieżowe","Zabiegi LED – terapeutyczne","Zagęszczanie włosów"],
  2: ["Chemiczne usuwanie makijażu permanentnego","Cool Lifting",
      "Elektroliza","Elektrokoagulacja","Elektroporacja",
      "Fala akustyczna i energia wysokiej częstotliwości","Infuzja tlenowa",
      "Jonoforeza","Karboksyterapia","Kawitacja ultradźwiękowa","Kriolipoliza",
      "Makijaż okolicznościowy","Makijaż permanentny",
      "Masaż Kobido","Mezoterapia bezigłowa","Mezoterapia igłowa",
      "Mezoterapia mikroigłowa","Microblading","Mikronakłuwanie",
      "Mikropigmentacja rekonstrukcyjna","Mikrodermabrazja korundowa i diamentowa",
      "Oczyszczanie wodorowo-tlenowe","Opalanie natryskowe","Oxybrazja",
      "Pedicure kosmetyczny (niezastrzeżony dla podologów)","Peeling węglowy",
      "Radiofrekwencja mikroigłowa","Radiotermoliza zmian skórnych",
      "Różnorodne peelingi chemiczne","Sauny infrared","Sonoforeza","Tatuaż",
      "Zabiegi falą radiową",
      "Zabiegi IPL (fotoodmładzanie, przebarwienia, teleangiektazje, depilacja)",
      "Zabiegi laserem frakcyjnym nieablacyjnym",
      "Zabiegi laserem nieablacyjnym (naczynia, tatuaż, depilacja)",
      "Zabiegi z zastosowaniem podczerwieni","Zastosowanie prądów małej i dużej częstotliwości"],
  3: ["Analiza chodu (ocena dynamiczna, wideoanaliza)","Badanie grzybicze paznokcia",
      "Badanie podoskopowe / podoskanerem","Delikatna koloryzacja rekonstrukcyjna paznokci",
      "Diagnostyka i leczenie brodawek","Diagnostyka różnicowa brodawka vs odcisk",
      "Dobór indywidualnych wkładek korygujących","Dobór ortez i separatorów żelowych",
      "Instruktaż ochrony mechanicznej i modyfikacji obuwia",
      "Intensywne kuracje nawilżająco-regenerujące","Klamry ortonyksyjne – aplikacja i aktywacje",
      "Konsultacja podologiczna","Kontrola po klamrze / rekonstrukcji / opatrunku",
      "Korekty ustawienia palucha: taping / fiksatory","Krioterapia zmian skórnych (CO2, punktowa)",
      "Odciążanie miejsc bolesnych (taping)","Opatrunki specjalistyczne",
      "Opracowanie łożyska przy onycholizie","Opracowanie modzeli, odcisków, nagniotków",
      "Opracowanie pęknięć i rozpadlin pięt","Opracowanie wałów z ziarniną","Ozonoterapia",
      "Pedicure podologiczny (medyczny) całościowy","Pobieranie próbek do badań",
      "Profilaktyka i zabiegi u osób z grup ryzyka","Protetyka / rekonstrukcja paznokcia",
      "Rozpoznanie i usuwanie modzeli, odcisków, rozpadlin",
      "Skrócenie i wyrównanie paznokci (zmienionych chorobowo)",
      "Terapia nadpotliwości stóp (jonoforeza)","Usuwanie zrogowaciałego naskórka",
      "Zabiegi skalpelem, dłutem i frezami"],
  4: ["Zabiegi technologią HIFU","Zabiegi z użyciem toksyny botulinowej",
      "Zabiegi osoczem bogatopłytkowym (PRP)","Zabiegi technologią PLASMA",
      "Wypełniacze – kwas hialuronowy","Zabiegi z użyciem nici PDO",
      "Lipoliza iniekcyjna","Zabiegi laserem ablacyjnym"]
};

/* ── HELPERS ────────────────────────────────────────────────── */
const $  = id => document.getElementById(id);
const qsa = (s, r) => (r || document).querySelectorAll(s);
function openModal(id)  { const m=$(id); if(m){m.classList.add("active");    document.body.style.overflow="hidden";} }
function closeModal(id) { const m=$(id); if(m){m.classList.remove("active"); document.body.style.overflow="auto";} }
function showAlert(id, msg, type) { const e=$(id); if(!e)return; e.textContent=msg; e.className="bp-alert bp-alert-"+type; e.style.display="block"; }
function hideAlert(id)  { const e=$(id); if(e)e.style.display="none"; }

/* ── CSS ────────────────────────────────────────────────────── */
document.head.insertAdjacentHTML("beforeend", `<style>
:root{--navy:#2a3b69;--pink:#e11d48;--bg:#fafafa;--border:#e2e8f0;--muted:#64748b;--sm:#f8fafc}
body{font-family:'Montserrat',sans-serif;background:var(--bg);color:#1e293b;margin:0}
*{box-sizing:border-box}
.font-heading,h1,h2,h3{font-family:'Playfair Display',serif}

/* HEADER */
#bp-header{background:rgba(255,255,255,.97);backdrop-filter:blur(14px);box-shadow:0 1px 4px rgba(0,0,0,.07);position:sticky;top:0;z-index:50;border-bottom:1px solid var(--border)}
.hdr-inner{max-width:1280px;margin:0 auto;padding:.4rem 1.25rem;display:flex;justify-content:space-between;align-items:center;gap:.75rem}
.hdr-brand{display:flex;align-items:center;gap:.6rem;text-decoration:none}
.hdr-logo{font-family:'Playfair Display',serif;font-size:1.1rem;font-weight:700;color:var(--navy);line-height:1}
.hdr-sub{font-size:8px;color:#94a3b8;font-weight:700;text-transform:uppercase;letter-spacing:.14em}
.hdr-sep{width:1px;height:1.6rem;background:var(--border)}
.hdr-broker{font-size:10px;font-weight:600;color:var(--navy)}
.hdr-right{display:flex;align-items:center;gap:.5rem}

/* BUTTONS */
.btn{font-family:'Montserrat',sans-serif;font-weight:700;border:none;border-radius:9999px;cursor:pointer;transition:all .2s;line-height:1;display:inline-flex;align-items:center;justify-content:center;gap:.3rem}
.btn-xs{font-size:10px;padding:.35rem .85rem}
.btn-sm{font-size:11px;padding:.42rem 1.1rem}
.btn-md{font-size:12px;padding:.5rem 1.4rem}
.btn-navy{background:var(--navy);color:#fff;box-shadow:0 2px 8px rgba(42,59,105,.2)}
.btn-navy:hover{background:#1e293b}
.btn-outline{background:#fff;color:#475569;border:1px solid var(--border)}
.btn-outline:hover{background:var(--sm)}
.btn-pink{background:var(--pink);color:#fff;box-shadow:0 2px 8px rgba(225,29,72,.18)}
.btn-pink:hover{background:#be123c}
.btn-ghost{background:transparent;color:var(--muted);border:1px solid var(--border)}
.btn-ghost:hover{color:var(--navy);border-color:var(--navy)}
.user-chip{background:#e0e7ff;border:1px solid #c7d2fe;color:var(--navy);border-radius:9999px;padding:.3rem .8rem;font-size:10px;font-weight:600;font-family:'Montserrat',sans-serif}

/* HERO 2-COL */
.bp-hero{background:linear-gradient(135deg,#fff1f2 0%,#fdf2f8 50%,#fff 100%);border-bottom:1px solid #ffe4e6;padding:1.5rem 1.25rem;position:relative;overflow:hidden}
.bp-hero-orb{position:absolute;border-radius:50%;filter:blur(60px);pointer-events:none}
.bp-hero-orb1{width:18rem;height:18rem;background:#fff;opacity:.6;top:-5rem;right:-4rem}
.bp-hero-orb2{width:14rem;height:14rem;background:#fecdd3;opacity:.35;bottom:-3rem;left:-3rem}
.bp-hero-layout{max-width:1280px;margin:0 auto;display:grid;grid-template-columns:1fr 320px;gap:2rem;align-items:center;position:relative;z-index:1}
@media(max-width:900px){.bp-hero-layout{grid-template-columns:1fr}}
.hero-text-col{}
.bp-badge{display:inline-block;padding:.2rem .7rem;border-radius:9999px;background:#fff;border:1px solid #fecdd3;color:var(--pink);font-size:9px;font-weight:700;letter-spacing:.12em;text-transform:uppercase;margin-bottom:.7rem;box-shadow:0 1px 3px rgba(0,0,0,.06)}
.bp-h1{font-family:'Playfair Display',serif;font-size:clamp(1.5rem,3vw,2.3rem);font-weight:700;color:#1e293b;margin:0 0 .65rem;line-height:1.2}
.bp-h1 span{color:var(--pink)}
.bp-sub{font-size:.82rem;color:#475569;max-width:36rem;margin:0 0 .85rem;line-height:1.65}
.bp-pills{display:flex;flex-wrap:wrap;gap:.35rem}
.bp-pill{background:#fff;border:1px solid #fecdd3;border-radius:9999px;padding:.25rem .7rem;font-size:9px;font-weight:600;color:#475569;display:flex;align-items:center;gap:.3rem;box-shadow:0 1px 2px rgba(0,0,0,.04)}
.bp-pill .ck{color:#22c55e}

/* PRODUCTS BOX (hero right) */
.products-box{background:rgba(255,255,255,.9);border-radius:1.1rem;border:1px solid rgba(255,255,255,.8);box-shadow:0 4px 20px rgba(42,59,105,.1);overflow:hidden;backdrop-filter:blur(8px)}
.products-box-hd{background:var(--navy);padding:.55rem .85rem}
.products-box-hd span{font-size:.7rem;font-weight:700;color:#fff;text-transform:uppercase;letter-spacing:.1em}
.products-grid{display:grid;grid-template-columns:1fr 1fr 1fr;padding:.6rem;gap:.45rem}
.prod-card{border:1px solid var(--border);border-radius:.6rem;padding:.55rem .4rem;text-align:center;cursor:pointer;text-decoration:none;color:inherit;transition:all .2s;display:block;background:#fff}
.prod-card:hover{border-color:var(--pink);background:#fff1f2;transform:translateY(-2px);box-shadow:0 3px 10px rgba(225,29,72,.1)}
.prod-card.active-prod{border-color:var(--pink);background:#fff1f2}
.prod-icon{font-size:1.2rem;margin-bottom:.2rem;line-height:1}
.prod-name{font-size:9px;font-weight:700;color:var(--navy);line-height:1.2}

/* MAIN LAYOUT (calculator below hero) */
.bp-main{max-width:1280px;margin:0 auto;padding:1.1rem 1.25rem}

/* COVERAGE */
.cov-card{background:#fff;border-radius:1.1rem;border:1px solid var(--border);box-shadow:0 1px 4px rgba(0,0,0,.05);padding:.9rem;margin-bottom:.9rem}
.cov-title{font-family:'Playfair Display',serif;font-size:.95rem;font-weight:700;color:var(--navy);text-align:center;margin:0 0 .35rem}
.cov-sub{font-size:9px;color:var(--muted);text-align:center;margin:0 0 .7rem;line-height:1.5}
.cov-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:.6rem}
@media(max-width:640px){.cov-grid{grid-template-columns:1fr}}
.cov-box{border-radius:.65rem;padding:.65rem;border:1px solid;font-size:9px}
.cov-box-b{background:#f0f8ff;border-color:#bae6fd}
.cov-box-c{background:#e0f2fe;border-color:#7dd3fc}
.cov-box-r{background:#fff1f2;border-color:#fecdd3}
.cov-box h4{font-weight:700;font-size:9px;color:var(--navy);margin:0 0 .35rem;display:flex;align-items:center;gap:.25rem}
.cov-box h4.pink{color:var(--pink)}
.cov-box ul{list-style:none;padding:0;margin:0}
.cov-box li{display:flex;gap:.3rem;margin-bottom:.25rem;line-height:1.3;color:#475569}

/* CALC */
.calc-card{background:#fff;border-radius:1.1rem;border:1px solid var(--border);box-shadow:0 2px 10px rgba(0,0,0,.06);padding:.9rem;margin-bottom:.9rem}
.calc-hdr{display:flex;justify-content:space-between;align-items:center;margin-bottom:.75rem;padding-bottom:.6rem;border-bottom:1px solid #f1f5f9;flex-wrap:wrap;gap:.4rem}
.calc-step{display:flex;align-items:center;gap:.4rem}
.calc-step-n{background:#ffe4e6;color:var(--pink);width:1.5rem;height:1.5rem;border-radius:50%;display:inline-flex;align-items:center;justify-content:center;font-size:.7rem;font-weight:700;font-family:'Montserrat',sans-serif;flex-shrink:0}
.calc-h{font-family:'Playfair Display',serif;font-size:.95rem;font-weight:700;color:var(--navy)}
.calc-note{font-size:9px;font-weight:500;color:#64748b;background:var(--sm);border:1px solid var(--border);border-radius:9999px;padding:.2rem .6rem}

/* PROC LISTS */
.proc-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:.6rem}
@media(max-width:768px){.proc-grid{grid-template-columns:1fr}}
.proc-col{border:1px solid var(--border);border-radius:.75rem;overflow:hidden;background:#fff;display:flex;flex-direction:column}
.proc-col-hd{background:var(--sm);padding:.4rem .55rem;border-bottom:1px solid var(--border);display:flex;justify-content:space-between;align-items:center}
.proc-col-hd h4{font-weight:700;font-size:.72rem;color:var(--navy);margin:0}
.proc-col-hd p{font-size:8px;color:#94a3b8;text-transform:uppercase;letter-spacing:.08em;margin:.1rem 0 0}
.btn-all{font-size:8px;border:1px solid var(--border);background:#fff;color:var(--navy);border-radius:9999px;padding:2px 7px;cursor:pointer;font-weight:700;font-family:'Montserrat',sans-serif;transition:all .15s;white-space:nowrap}
.btn-all:hover{border-color:var(--navy);background:#f0f4ff}
.proc-list{padding:.25rem;height:200px;overflow-y:auto;flex:1}
.proc-list::-webkit-scrollbar{width:3px}
.proc-list::-webkit-scrollbar-thumb{background:#cbd5e1;border-radius:2px}
.proc-item{display:flex;align-items:flex-start;padding:.18rem .3rem;border-radius:.3rem;cursor:pointer;border:1px solid transparent;transition:all .1s}
.proc-item:hover{background:#fff1f2;border-color:#fecdd3}
.proc-item input{margin-top:.12rem;margin-right:.35rem;width:.85rem;height:.85rem;cursor:pointer;accent-color:var(--pink);flex-shrink:0}
.proc-item span{font-size:9px;color:#475569;line-height:1.3}

/* HIGH RISK */
.hr-box{margin-top:.65rem;border:2px solid #fde68a;border-radius:.75rem;overflow:hidden;background:#fffbeb}
.hr-hd{background:#fef3c7;border-bottom:1px solid #fde68a;padding:.5rem .75rem;display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:.35rem}
.hr-hd h4{font-weight:700;font-size:.72rem;color:#92400e;margin:0}
.hr-hd p{font-size:8px;color:#b45309;margin:.1rem 0 0}
.hr-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:.3rem;padding:.55rem}
@media(max-width:640px){.hr-grid{grid-template-columns:1fr 1fr}}

/* STEP 2 */
#step-2{transition:opacity .35s,transform .35s}
#step-2.locked{opacity:.38;pointer-events:none;transform:translateY(6px)}
.emp-grid{display:flex;gap:.45rem;flex-wrap:wrap}
.emp-card{flex:1;min-width:80px}
.emp-card input[type=radio]{display:none}
.emp-card label{display:flex;flex-direction:column;align-items:center;justify-content:center;padding:.45rem .55rem;border:2px solid var(--border);border-radius:.65rem;cursor:pointer;background:#fff;text-align:center;transition:all .2s;box-shadow:0 1px 2px rgba(0,0,0,.04)}
.emp-card input[type=radio]:checked+label{border-color:var(--navy);background:#f0f4ff;box-shadow:0 4px 10px rgba(42,59,105,.1);transform:translateY(-1px)}
.emp-label{font-weight:700;font-size:9px;color:#1e293b}
.emp-sub{font-size:8px;font-weight:600;text-transform:uppercase;margin-top:.1rem}
.legal-box{border:2px solid var(--border);border-radius:.65rem;padding:.6rem .75rem;cursor:pointer;transition:all .2s;display:flex;align-items:flex-start;gap:.45rem}
.legal-box:hover{background:#fff1f2;border-color:#fecdd3}
.legal-box input{margin-top:.12rem;width:.9rem;height:.9rem;accent-color:var(--pink);flex-shrink:0;cursor:pointer}

/* RESULTS */
#results-section{transition:opacity .5s,transform .5s}
#results-section.hidden-anim{opacity:0;transform:translateY(10px);pointer-events:none}
.tier-banner{background:#fff;border-left:4px solid var(--pink);box-shadow:0 2px 8px rgba(0,0,0,.06);border-radius:0 .7rem .7rem 0;padding:.55rem .85rem;margin-bottom:.8rem;display:flex;justify-content:space-between;align-items:center;gap:.5rem;flex-wrap:wrap}
.tier-lbl{font-size:8px;text-transform:uppercase;letter-spacing:.15em;color:#94a3b8;font-weight:700;margin-bottom:1px}
.tier-val{font-size:.8rem;font-weight:600;color:#1e293b}
.pricing-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:.65rem;margin-bottom:.8rem}
@media(max-width:580px){.pricing-grid{grid-template-columns:1fr}}
.price-card{background:#fff;border-radius:1rem;border:1px solid var(--border);overflow:hidden;display:flex;flex-direction:column;transition:transform .3s,box-shadow .3s}
.price-card:hover{transform:translateY(-3px);box-shadow:0 8px 20px rgba(0,0,0,.09)}
.price-card.featured{border:2px solid var(--pink);transform:translateY(-4px);box-shadow:0 8px 20px rgba(225,29,72,.1)}
.feat-banner{background:linear-gradient(90deg,var(--pink),#f43f5e);color:#fff;font-size:8px;font-weight:700;text-align:center;padding:3px;letter-spacing:.1em;text-transform:uppercase}
.price-top{text-align:center;padding:.75rem .6rem;background:var(--sm);border-bottom:1px solid #f1f5f9}
.price-card.featured .price-top{background:#fff1f2;border-bottom:1px solid #fecdd3}
.price-tier-lbl{font-size:8px;font-weight:700;color:#94a3b8;text-transform:uppercase;letter-spacing:.1em;margin-bottom:.2rem}
.price-card.featured .price-tier-lbl{color:#f43f5e}
.price-sum{font-family:'Playfair Display',serif;font-size:1rem;font-weight:700;color:var(--navy);margin-bottom:.4rem}
.price-card.featured .price-sum{color:var(--pink)}
.price-amount{font-size:1.8rem;font-weight:800;color:#1e293b;line-height:1}
.price-unit{font-size:.65rem;color:#94a3b8;font-weight:500}
.price-body{padding:.75rem .6rem;flex:1;display:flex;flex-direction:column}
.price-btn{margin-top:auto;width:100%;padding:.55rem;border-radius:.55rem;font-family:'Montserrat',sans-serif;font-size:.72rem;font-weight:700;cursor:pointer;transition:all .2s;border:2px solid var(--border);color:#475569;background:#fff}
.price-btn:hover{border-color:var(--navy);color:var(--navy)}
.price-card.featured .price-btn{background:var(--pink);color:#fff;border-color:var(--pink)}
.price-card.featured .price-btn:hover{background:#be123c}

.ind-msg{background:var(--navy);color:#fff;border-radius:1rem;padding:1.25rem;text-align:center;margin-bottom:.8rem;display:none;position:relative;overflow:hidden}
.ind-msg::before{content:'';position:absolute;top:-2rem;right:-2rem;width:8rem;height:8rem;background:#fff;opacity:.05;border-radius:50%}
.ind-msg h3{font-family:'Playfair Display',serif;font-size:1rem;margin:0 0 .35rem;position:relative}
.ind-msg p{font-size:.72rem;color:#cbd5e1;margin:0 0 .8rem;line-height:1.55;position:relative}

/* MODALS */
.bp-modal{display:none;position:fixed;inset:0;z-index:200;background:rgba(15,23,42,.62);backdrop-filter:blur(10px);align-items:center;justify-content:center;padding:1rem}
.bp-modal.active{display:flex;animation:mIn .25s ease}
@keyframes mIn{from{opacity:0;transform:scale(.97)}to{opacity:1;transform:scale(1)}}
.mbox{background:#fff;border-radius:1.2rem;box-shadow:0 16px 40px rgba(0,0,0,.18);max-width:26rem;width:100%;overflow:hidden;max-height:92vh;overflow-y:auto}
.mbox.mbox-wide{max-width:34rem}
.mbox::-webkit-scrollbar{width:3px}
.mbox::-webkit-scrollbar-thumb{background:#cbd5e1;border-radius:2px}
.mbox-hd{background:var(--sm);padding:.75rem 1rem;border-bottom:1px solid var(--border);position:sticky;top:0;display:flex;justify-content:space-between;align-items:flex-start}
.mbox-hd h3{font-family:'Playfair Display',serif;font-size:.95rem;font-weight:700;color:var(--navy);margin:0}
.mbox-hd p{font-size:9px;color:#94a3b8;margin:2px 0 0}
.mclose{background:none;border:none;cursor:pointer;font-size:1rem;color:#94a3b8;line-height:1;transition:color .2s;flex-shrink:0}
.mclose:hover{color:#1e293b}
.mbox-body{padding:1rem}
.mgroup{margin-bottom:.7rem}
.mlabel{display:block;font-size:9px;font-weight:700;text-transform:uppercase;letter-spacing:.08em;color:#475569;margin-bottom:.3rem}
.minput{width:100%;background:var(--sm);border:1px solid var(--border);border-radius:.6rem;padding:.55rem .75rem;font-family:'Montserrat',sans-serif;font-size:.78rem;color:#1e293b;outline:none;transition:border-color .2s}
.minput:focus{border-color:var(--navy);background:#fff}
.loader{border:2px solid #f1f5f9;border-top:2px solid var(--navy);border-radius:50%;width:14px;height:14px;animation:spin 1s linear infinite;display:none;flex-shrink:0}
@keyframes spin{to{transform:rotate(360deg)}}
.bp-alert{padding:.45rem .75rem;border-radius:.5rem;font-size:.72rem;font-weight:500;margin-bottom:.6rem;display:none}
.bp-alert-error{background:#fff1f2;border:1px solid #fecdd3;color:var(--pink);display:block}
.bp-alert-success{background:#f0fdf4;border:1px solid #bbf7d0;color:#16a34a;display:block}

/* LOGIN MODAL TABS */
.mtabs{display:flex;border-bottom:1px solid var(--border)}
.mtab{flex:1;padding:.5rem;font-size:.72rem;font-weight:700;background:none;border:none;cursor:pointer;color:#94a3b8;font-family:'Montserrat',sans-serif;border-bottom:2px solid transparent;transition:all .2s}
.mtab.active{color:var(--navy);border-bottom-color:var(--pink)}

/* ADMIN PANEL */
.admin-overlay{position:fixed;inset:0;z-index:300;background:#f1f5f9;display:none;flex-direction:column}
.admin-overlay.active{display:flex}
.admin-topbar{background:var(--navy);color:#fff;padding:.55rem 1.25rem;display:flex;align-items:center;justify-content:space-between;gap:1rem;flex-shrink:0}
.admin-topbar h2{font-family:'Playfair Display',serif;font-size:.95rem;margin:0}
.admin-nav{display:flex;gap:.4rem}
.admin-nav-btn{background:rgba(255,255,255,.12);color:#fff;border:none;border-radius:.5rem;padding:.3rem .8rem;font-size:10px;font-weight:700;cursor:pointer;font-family:'Montserrat',sans-serif;transition:background .2s}
.admin-nav-btn.active{background:rgba(255,255,255,.28)}
.admin-nav-btn:hover{background:rgba(255,255,255,.2)}
.admin-content{flex:1;overflow-y:auto;padding:1.1rem 1.25rem}
.admin-section{display:none;max-width:1100px;margin:0 auto}
.admin-section.active{display:block}

/* stats row */
.stat-row{display:grid;grid-template-columns:repeat(4,1fr);gap:.65rem;margin-bottom:1rem}
@media(max-width:600px){.stat-row{grid-template-columns:1fr 1fr}}
.stat-card{background:#fff;border-radius:.85rem;border:1px solid var(--border);padding:.75rem;text-align:center;box-shadow:0 1px 3px rgba(0,0,0,.05)}
.stat-n{font-family:'Playfair Display',serif;font-size:1.6rem;font-weight:700;color:var(--navy);line-height:1}
.stat-l{font-size:9px;color:#94a3b8;font-weight:600;text-transform:uppercase;letter-spacing:.08em;margin-top:.2rem}
.stat-card.pink-stat .stat-n{color:var(--pink)}

/* admin table */
.admin-tbl-wrap{background:#fff;border-radius:.85rem;border:1px solid var(--border);overflow:hidden;box-shadow:0 1px 3px rgba(0,0,0,.05)}
.admin-tbl-hd{padding:.65rem .9rem;border-bottom:1px solid var(--border);display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:.4rem}
.admin-tbl-hd h3{font-weight:700;font-size:.82rem;color:var(--navy);margin:0}
.atbl{width:100%;border-collapse:collapse;font-size:10px}
.atbl th{background:var(--sm);padding:.45rem .7rem;text-align:left;font-weight:700;color:#64748b;font-size:8px;text-transform:uppercase;letter-spacing:.08em;border-bottom:1px solid var(--border)}
.atbl td{padding:.5rem .7rem;border-bottom:1px solid #f8fafc;vertical-align:middle}
.atbl tr:last-child td{border-bottom:none}
.atbl tr:hover td{background:#f8fafc}
.sbadge{display:inline-block;padding:2px 7px;border-radius:9999px;font-size:8px;font-weight:700;text-transform:uppercase;letter-spacing:.05em}
.s-new{background:#dbeafe;color:#1d4ed8}
.s-sent{background:#fef9c3;color:#854d0e}
.s-accepted{background:#dcfce7;color:#15803d}
.s-contact{background:#fce7f3;color:#9d174d}
.s-rejected{background:#fee2e2;color:#b91c1c}
.ssel{background:var(--sm);border:1px solid var(--border);border-radius:.4rem;padding:.15rem .35rem;font-size:9px;font-family:'Montserrat',sans-serif;cursor:pointer;color:#1e293b;outline:none}

/* analytics charts */
.analytics-grid{display:grid;grid-template-columns:1fr 1fr;gap:.75rem;margin-bottom:1rem}
@media(max-width:640px){.analytics-grid{grid-template-columns:1fr}}
.chart-card{background:#fff;border-radius:.85rem;border:1px solid var(--border);padding:.85rem;box-shadow:0 1px 3px rgba(0,0,0,.05)}
.chart-card h4{font-weight:700;font-size:.78rem;color:var(--navy);margin:0 0 .65rem}
.bar-row{display:flex;align-items:center;gap:.5rem;margin-bottom:.4rem}
.bar-label{font-size:9px;color:#64748b;min-width:70px;text-align:right;flex-shrink:0}
.bar-track{flex:1;background:#f1f5f9;border-radius:4px;height:14px;overflow:hidden}
.bar-fill{height:100%;border-radius:4px;background:linear-gradient(90deg,var(--navy),#4f6bab);transition:width .6s ease}
.bar-fill.pink-bar{background:linear-gradient(90deg,var(--pink),#f43f5e)}
.bar-val{font-size:9px;font-weight:700;color:var(--navy);min-width:28px}

/* FOOTER */
footer{background:#fff;border-top:1px solid var(--border);padding:1.25rem 1.25rem .9rem;margin-top:1.25rem}
.footer-inner{max-width:1280px;margin:0 auto;display:grid;grid-template-columns:1fr 1fr;gap:1.5rem}
@media(max-width:600px){.footer-inner{grid-template-columns:1fr}}
.footer-copy{max-width:1280px;margin:.6rem auto 0;padding-top:.6rem;border-top:1px solid #f1f5f9;font-size:8px;color:#94a3b8;text-align:center;text-transform:uppercase;letter-spacing:.1em}
footer a{color:#64748b;text-decoration:none;font-size:.72rem;transition:color .2s}
footer a:hover{color:var(--pink)}
</style>`);

/* ================================================================
   BUILD PAGE
================================================================ */
function buildPage() {
  document.body.innerHTML = "";

  /* HEADER */
  const hdr = document.createElement("header");
  hdr.id = "bp-header";
  hdr.innerHTML = `<div class="hdr-inner">
    <a class="hdr-brand" href="new.html">
      <div><div class="hdr-logo">BeautyPolisa</div><div class="hdr-sub">Created by Aura Consulting</div></div>
    </a>
    <div class="hdr-sep" style="display:none" id="hdr-sep-el"></div>
    <div class="hdr-broker" id="hdr-broker-txt" style="display:none">Obsługa brokerska: Aura Consulting</div>
    <div id="hdr-auth" style="display:flex;align-items:center;gap:.5rem"></div>
  </div>`;
  document.body.appendChild(hdr);

  /* HERO — 2 kolumny */
  const hero = document.createElement("section");
  hero.className = "bp-hero";
  hero.innerHTML = `
    <div class="bp-hero-orb bp-hero-orb1"></div>
    <div class="bp-hero-orb bp-hero-orb2"></div>
    <div class="bp-hero-layout">
      <div class="hero-text-col">
        <div class="bp-badge">Kalkulator Składek 2026 · Program BeautyRazem</div>
        <h1 class="bp-h1">Ekskluzywny Program Ochrony<br><span>dla Branży Beauty</span></h1>
        <p class="bp-sub">Zbudowany we współpracy z <strong>BeautyRazem</strong>. Zaznacz zabiegi, a system dobierze optymalną taryfę OC zawodowego.</p>
        <div class="bp-pills">
          <span class="bp-pill"><span class="ck">&#10003;</span> Dedykowane dla BeautyRazem</span>
          <span class="bp-pill"><span class="ck">&#10003;</span> Ochrona do 300 000 zł</span>
          <span class="bp-pill"><span class="ck">&#10003;</span> Ekspercka likwidacja szkód</span>
        </div>
      </div>
      <div>
        <div class="products-box">
          <div class="products-box-hd"><span>Produkty BeautyPolisa</span></div>
          <div class="products-grid">
            <a href="new.html" class="prod-card active-prod" title="OC Zawodowe"><div class="prod-icon">🛡️</div><div class="prod-name">OC</div></a>
            <a href="tax-protect.html" class="prod-card" title="Tax Protect"><div class="prod-icon">📊</div><div class="prod-name">Tax Protect</div></a>
            <a href="#" class="prod-card" title="Prywatne L4 – Utrata Dochodu"><div class="prod-icon">💊</div><div class="prod-name">Prywatne L4</div></a>
            <a href="medical.html" class="prod-card" title="Opieka Medyczna"><div class="prod-icon">🏥</div><div class="prod-name">Opieka Medyczna</div></a>
            <a href="life1.html" class="prod-card" title="Ubezpieczenie Życia"><div class="prod-icon">❤️</div><div class="prod-name">Ubezpiecz Życie</div></a>
            <a href="#" class="prod-card" title="NNW Dzieci"><div class="prod-icon">👶</div><div class="prod-name">NNW Dzieci</div></a>
          </div>
        </div>
      </div>
    </div>`;
  document.body.appendChild(hero);

  /* MAIN — kalkulator pełna szerokość */
  const main = document.createElement("div");
  main.className = "bp-main";
  main.id = "calculator-section";
  main.innerHTML = buildCalcHTML();
  document.body.appendChild(main);

  /* FOOTER */
  const foot = document.createElement("footer");
  foot.innerHTML = `<div class="footer-inner">
    <div>
      <p style="margin:0 0 .25rem;font-size:9px"><strong>Obsługa techniczna:</strong> Aura Expert sp. z o.o. <span style="color:var(--navy);font-weight:600">(tel. 504 400 901)</span></p>
      <p style="margin:0 0 .4rem;font-size:9px"><strong>Likwidacja szkód:</strong> Broker Ubezpieczeniowy Aura Consulting sp. z o.o.</p>
      <span style="font-size:8px;color:#94a3b8;font-weight:700">✨ BeautyPolisa · Aura Consulting</span>
    </div>
    <div style="font-size:9px;color:#94a3b8;display:flex;flex-direction:column;justify-content:center;gap:.25rem;text-align:right">
      <p style="margin:0">Kalkulator ma charakter informacyjny i nie stanowi oferty (art. 66 KC).</p>
      <p style="margin:0">Ostateczna składka zależy od akceptacji ERGO Hestia S.A. OWU: AB-OCZB-01/25.</p>
      <div style="display:flex;gap:.6rem;justify-content:flex-end;margin-top:.25rem;font-weight:700">
        <a href="#" onclick="openModal('modal-dystrybutor');return false">Dystrybutor</a>
        <a href="#" onclick="openModal('modal-rodo');return false">RODO</a>
      </div>
    </div>
  </div>
  <div class="footer-copy">© 2026 Program BeautyRazem · Aura Consulting sp. z o.o.</div>`;
  document.body.appendChild(foot);

  buildModals();
  buildAdminPanel();
  initProcLists();

  // responsive header
  const mq = window.matchMedia("(min-width:640px)");
  function applyMq(m) {
    const sep = document.getElementById("hdr-sep-el");
    const brok = document.getElementById("hdr-broker-txt");
    if (sep)  sep.style.display  = m.matches ? "block" : "none";
    if (brok) brok.style.display = m.matches ? "block" : "none";
  }
  applyMq(mq); mq.addEventListener("change", applyMq);
}

/* ── CALC HTML ── */
function buildCalcHTML() {
  return `
  <!-- COVERAGE -->
  <div class="cov-card">
    <div class="cov-title">Zakres Ochrony Ubezpieczeniowej</div>
    <div class="cov-sub">OC zawodowe za szkody wyrządzone osobom trzecim w związku z wykonywaniem czynności zawodowych w branży beauty (ERGO Hestia · OWU AB-OCZB-01/25).</div>
    <div class="cov-grid">
      <div class="cov-box cov-box-b">
        <h4><span style="color:#3b82f6">&#10003;</span> Zakres Podstawowy</h4>
        <ul>
          <li><span style="color:#3b82f6">&#10003;</span> Szkody przez podwykonawców</li>
          <li><span style="color:#3b82f6">&#10003;</span> Rażące niedbalstwo</li>
          <li><span style="color:#3b82f6">&#10003;</span> Szkody w dokumentach</li>
          <li><span style="color:#3b82f6">&#10003;</span> Szkody z posiadania mienia</li>
        </ul>
      </div>
      <div class="cov-box cov-box-c">
        <h4><span style="color:#2563eb">&#10024;</span> Rozszerzenia (w cenie)</h4>
        <ul>
          <li><span style="color:#2563eb;font-weight:700">+</span> Choroby zakaźne (klauzula 4)</li>
          <li><span style="color:#2563eb;font-weight:700">+</span> Aparatura, lasery, RF (klauzula 5)</li>
          <li><span style="color:#2563eb;font-weight:700">+</span> OC Najemcy – lokal (100 000 zł)</li>
          <li><span style="color:#2563eb;font-weight:700">+</span> OC Najemcy – rzeczy (100 000 zł)</li>
        </ul>
      </div>
      <div class="cov-box cov-box-r">
        <h4 class="pink"><span>&#10005;</span> Wyłączenia</h4>
        <ul>
          <li><span style="color:var(--pink)">&#10005;</span> Wprowadzanie produktów do obrotu</li>
          <li><span style="color:var(--pink)">&#10005;</span> Pojazdy mechaniczne</li>
          <li><span style="color:var(--pink)">&#10005;</span> Branże: budowlana, IT, prawna</li>
          <li><span style="color:var(--pink)">&#10005;</span> Środowisko naturalne</li>
        </ul>
      </div>
    </div>
  </div>

  <!-- STEP 1 -->
  <div class="calc-card">
    <div class="calc-hdr">
      <div class="calc-step"><span class="calc-step-n">1</span><span class="calc-h">Jakie zabiegi wykonujesz?</span></div>
      <span class="calc-note">Zaznacz wszystkie – system dobierze taryfę</span>
    </div>
    <div class="proc-grid" id="proc-grid"></div>
    <div class="hr-box">
      <div class="hr-hd">
        <div><h4>Zabiegi Specjalistyczne – Wysokie Ryzyko</h4><p>Wymagają indywidualnej oceny ryzyka przez ERGO Hestia</p></div>
        <button class="btn-all" onclick="selectAll(4)">Zaznacz wszystkie</button>
      </div>
      <div class="hr-grid" id="list-4-container"></div>
    </div>
  </div>

  <!-- STEP 2 -->
  <div class="calc-card locked" id="step-2">
    <div class="calc-hdr">
      <div class="calc-step"><span class="calc-step-n">2</span><span class="calc-h">Parametry Gabinetu</span></div>
    </div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:.85rem">
      <fieldset style="border:none;padding:0;margin:0">
        <legend style="font-size:.72rem;font-weight:600;color:#1e293b;margin-bottom:.45rem">Ile osób wykonuje zabiegi?</legend>
        <div class="emp-grid">
          <div class="emp-card"><input type="radio" name="employees" id="emp-5" value="1" checked onchange="updateCalculator()">
            <label for="emp-5"><span class="emp-label">1–5 osób</span><span class="emp-sub" style="color:#22c55e">Taryfa bazowa</span></label></div>
          <div class="emp-card"><input type="radio" name="employees" id="emp-8" value="1.25" onchange="updateCalculator()">
            <label for="emp-8"><span class="emp-label">6–8 osób</span><span class="emp-sub" style="color:#64748b">+25% składki</span></label></div>
          <div class="emp-card"><input type="radio" name="employees" id="emp-9" value="ind" onchange="updateCalculator()">
            <label for="emp-9"><span class="emp-label">9 i więcej</span><span class="emp-sub" style="color:#d97706">Ankieta</span></label></div>
        </div>
      </fieldset>
      <div>
        <div style="font-size:.72rem;font-weight:600;color:#1e293b;margin-bottom:.45rem">Rozszerzenie (opcjonalnie)</div>
        <div class="legal-box" onclick="document.getElementById('legal-protection').click()">
          <input type="checkbox" id="legal-protection" onclick="event.stopPropagation()" onchange="updateCalculator()">
          <div>
            <div style="font-weight:700;font-size:.75rem;color:#1e293b">Ubezpieczenie Ochrony Prawnej</div>
            <div style="font-size:9px;color:#64748b;margin-top:.1rem">Koszty adwokata · suma 100 000 zł · <span style="color:var(--pink);font-weight:600">+${LEGAL} zł/rok</span></div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- RESULTS -->
  <div id="results-section" class="hidden-anim" aria-live="polite">
    <div class="tier-banner">
      <div><div class="tier-lbl">Dopasowana Taryfa</div><div class="tier-val" id="detected-tier-msg"></div></div>
      <div style="color:var(--pink);background:#fff1f2;width:1.6rem;height:1.6rem;border-radius:50%;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:.85rem">&#10003;</div>
    </div>
    <div id="pricing-cards-container">
      <h2 class="font-heading" style="text-align:center;font-size:1.1rem;font-weight:700;color:var(--navy);margin:0 0 .7rem">Wybierz wariant ochrony</h2>
      <div class="pricing-grid">
        <div class="price-card">
          <div class="price-top"><div class="price-tier-lbl">Wariant Podstawowy</div><div class="price-sum">100 000 zł</div><div class="price-amount" id="price-100k">—</div><span class="price-unit"> zł/rok</span></div>
          <div class="price-body"><button class="price-btn" id="btn-100k">Wybieram wariant</button></div>
        </div>
        <div class="price-card featured">
          <div class="feat-banner">Rekomendacja Ekspertów</div>
          <div class="price-top"><div class="price-tier-lbl">Wariant Optymalny</div><div class="price-sum">200 000 zł</div><div class="price-amount" id="price-200k">—</div><span class="price-unit"> zł/rok</span></div>
          <div class="price-body"><button class="price-btn" id="btn-200k">Wybieram wariant</button></div>
        </div>
        <div class="price-card">
          <div class="price-top"><div class="price-tier-lbl">Wariant Maksymalny</div><div class="price-sum">300 000 zł</div><div class="price-amount" id="price-300k">—</div><span class="price-unit"> zł/rok</span></div>
          <div class="price-body"><button class="price-btn" id="btn-300k">Wybieram wariant</button></div>
        </div>
      </div>
    </div>
    <div class="ind-msg" id="individual-pricing-msg">
      <h3>Wymagana Indywidualna Ocena Ryzyka</h3>
      <p id="ind-pricing-reason">Ze względu na wybrane parametry przygotujemy taryfę szytą na miarę.</p>
      <button class="btn btn-xs" style="background:#fff;color:var(--navy);border-radius:9999px;position:relative" id="btn-ind">Odbierz Ankietę na e-mail</button>
    </div>
    <div style="margin-top:.65rem;text-align:center">
      <button onclick="openModal('modal-contact')" class="btn btn-ghost btn-sm">Masz pytania? Zostaw kontakt &#8594;</button>
    </div>
  </div>`;
}

/* ── PROC LISTS ── */
function initProcLists() {
  const grid = document.getElementById("proc-grid");
  if (!grid) return;
  [[1,"Grupa 1","Kosmetyka i Fryzjerstwo"],
   [2,"Grupa 2","Kosmetologia i Tatuaż"],
   [3,"Grupa 3","Podologia Medyczna"]].forEach(([tier, title, sub]) => {
    const col = document.createElement("div");
    col.className = "proc-col";
    col.innerHTML = `<div class="proc-col-hd"><div><h4>${title}</h4><p>${sub}</p></div><button class="btn-all" onclick="selectAll(${tier})">Wszystkie</button></div><div class="proc-list" id="list-${tier}-container"></div>`;
    grid.appendChild(col);
    const list = col.querySelector(`#list-${tier}-container`);
    PROCS[tier].forEach(p => {
      const lbl = document.createElement("label");
      lbl.className = "proc-item";
      lbl.innerHTML = `<input type="checkbox" class="tier-checkbox" data-tier="${tier}" onchange="updateCalculator()"><span>${p}</span>`;
      list.appendChild(lbl);
    });
  });
  const t4 = document.getElementById("list-4-container");
  if (t4) PROCS[4].forEach(p => {
    const lbl = document.createElement("label");
    lbl.className = "proc-item";
    lbl.innerHTML = `<input type="checkbox" class="tier-checkbox" data-tier="4" onchange="updateCalculator()"><span>${p}</span>`;
    t4.appendChild(lbl);
  });
}

/* ── CALCULATOR ── */
function selectAll(tier) {
  const c = document.getElementById(`list-${tier}-container`);
  if (!c) return;
  const cbs = c.querySelectorAll("input[type=checkbox]");
  let all = true;
  cbs.forEach(cb => { if (!cb.checked) all = false; });
  cbs.forEach(cb => { cb.checked = !all; });
  const btn = c.parentElement.querySelector(".btn-all");
  if (btn) btn.textContent = !all ? "Odznacz wszystkie" : "Zaznacz wszystkie";
  updateCalculator();
}

function updateCalculator() {
  const allCBs = document.querySelectorAll(".tier-checkbox");
  let h1=false, h2=false, h3=false, hRisk=false, cnt=0;
  allCBs.forEach(cb => {
    if (!cb.checked) return;
    cnt++;
    const t = parseInt(cb.getAttribute("data-tier"));
    if (t===1) h1=true; if (t===2) h2=true; if (t===3) h3=true; if (t===4) hRisk=true;
  });
  const s2  = document.getElementById("step-2");
  const res = document.getElementById("results-section");
  if (!s2 || !res) return;
  if (cnt === 0) { s2.classList.add("locked"); res.classList.add("hidden-anim"); return; }
  s2.classList.remove("locked"); res.classList.remove("hidden-anim");

  let tier=1, taryfaName="";
  if      (h3 && (h1||h2)) { tier=3; taryfaName="Gabinet Wieloprofilowy (Podologia + Beauty)"; }
  else if (h3)             { tier=3; taryfaName="Gabinety Podologiczne (Pakiet Pełny)"; }
  else if (h1 && h2)       { tier=3; taryfaName="Pakiet Łączony (Kosmetyka + Kosmetologia)"; }
  else if (h2)             { tier=2; taryfaName="Gabinety Kosmetologiczne"; }
  else                     { tier=1; taryfaName="Gabinety Kosmetyczne i Fryzjerskie"; }

  const empVal  = document.querySelector("input[name=employees]:checked")?.value;
  const legalCost = document.getElementById("legal-protection")?.checked ? LEGAL : 0;
  const cards   = document.getElementById("pricing-cards-container");
  const indMsg  = document.getElementById("individual-pricing-msg");
  const tierMsg = document.getElementById("detected-tier-msg");
  if (tierMsg) tierMsg.textContent = taryfaName;

  if (empVal==="ind" || hRisk) {
    if (cards)  cards.style.display  = "none";
    if (indMsg) indMsg.style.display = "block";
    const ir = document.getElementById("ind-pricing-reason");
    if (ir) ir.textContent = hRisk
      ? "Wybrałaś zabiegi specjalistyczne (Grupa 4), które wymagają indywidualnej oceny ryzyka przez ERGO Hestia. Wypełnij ankietę."
      : "Dla 9+ osób przygotujemy taryfę indywidualną. Nasz broker wynegocjuje optymalną stawkę.";
    const btnI = document.getElementById("btn-ind");
    if (btnI) btnI.onclick = () => openOfferModal("Wycena Indywidualna","—", hRisk ? "Wycena Indywidualna (Zabiegi Specjalistyczne)" : "Wycena Indywidualna (9+ osób)");
  } else {
    if (cards)  cards.style.display  = "block";
    if (indMsg) indMsg.style.display = "none";
    const mult = parseFloat(empVal)||1;
    const p    = PRICING[tier];
    const [p1,p2,p3] = [p.s100,p.s200,p.s300].map(v => Math.round(v*mult+legalCost));
    [["100k",p1],["200k",p2],["300k",p3]].forEach(([k,v]) => {
      const el = document.getElementById(`price-${k}`);
      if (el) el.textContent = v.toLocaleString("pl-PL");
    });
    const sums  = ["100 000 zł","200 000 zł","300 000 zł"];
    const pvals = [`${p1} zł`,`${p2} zł`,`${p3} zł`];
    ["100k","200k","300k"].forEach((k,i) => {
      const btn = document.getElementById(`btn-${k}`);
      if (btn) btn.onclick = () => openOfferModal(sums[i], pvals[i], taryfaName);
    });
  }
}

function openOfferModal(variant, price, taryfaName) {
  const set = (id,v) => { const e=document.getElementById(id); if(e) e.textContent=v; };
  const hid = (id,v) => { const e=document.getElementById(id); if(e) e.value=v; };
  set("m-variant",variant); set("m-price",price);
  hid("fh-variant",variant); hid("fh-price",price); hid("fh-taryfa",taryfaName);
  hideAlert("m-alert");
  openModal("modal-offer");
}

/* ── AUTH ── */
function renderAuthArea() {
  const area = document.getElementById("hdr-auth");
  if (!area) return;
  if (_user) {
    const name     = _user.user_metadata?.full_name || _user.email.split("@")[0];
    const isAdmin  = _profile?.is_admin;
    area.innerHTML = `
      <span class="user-chip">👤 ${name.split(" ")[0]}</span>
      ${isAdmin ? `<button class="btn btn-xs btn-navy" onclick="openAdmin()">⚙️ Panel Admina</button>` : ""}
      <button class="btn btn-xs btn-outline" onclick="doLogout()">Wyloguj</button>`;
  } else {
    area.innerHTML = `
      <button class="btn btn-xs btn-outline" onclick="openModal('modal-auth')">Zaloguj się</button>
      <button class="btn btn-xs btn-navy"    onclick="openModal('modal-auth');switchAuthTab('register')">Załóż konto</button>`;
  }
}

function switchAuthTab(t) {
  ["login","register"].forEach(tab => {
    const btn = document.getElementById(`atab-${tab}`);
    const frm = document.getElementById(`af-${tab}`);
    if (btn) btn.classList.toggle("active", tab===t);
    if (frm) frm.style.display = tab===t ? "block" : "none";
  });
  hideAlert("af-alert");
}

async function doLogin() {
  const email = document.getElementById("af-email")?.value;
  const pass  = document.getElementById("af-pass")?.value;
  if (!email || !pass) { showAlert("af-alert","Uzupełnij e-mail i hasło.","error"); return; }
  const btn = document.getElementById("af-login-btn");
  if (btn) { btn.textContent="Logowanie…"; btn.disabled=true; }
  const {data, error} = await sb.auth.signInWithPassword({email, password:pass});
  if (btn) { btn.textContent="Zaloguj się"; btn.disabled=false; }
  if (error) { showAlert("af-alert", error.message==="Invalid login credentials"?"Nieprawidłowy e-mail lub hasło.":error.message, "error"); }
  else { _user=data.user; await loadProfile(); closeModal("modal-auth"); renderAuthArea(); }
}

async function doRegister() {
  const name  = document.getElementById("af-name")?.value;
  const email = document.getElementById("af-reg-email")?.value;
  const pass  = document.getElementById("af-reg-pass")?.value;
  const phone = document.getElementById("af-phone")?.value;
  if (!name||!email||!pass) { showAlert("af-alert","Uzupełnij wymagane pola.","error"); return; }
  if (pass.length < 8)      { showAlert("af-alert","Hasło musi mieć min. 8 znaków.","error"); return; }
  const btn = document.getElementById("af-reg-btn");
  if (btn) { btn.textContent="Tworzę konto…"; btn.disabled=true; }
  const {error} = await sb.auth.signUp({email, password:pass, options:{data:{full_name:name, phone}}});
  if (btn) { btn.textContent="Utwórz konto"; btn.disabled=false; }
  if (error) showAlert("af-alert", error.message, "error");
  else showAlert("af-alert","Konto utworzone! Sprawdź e-mail, aby potwierdzić rejestrację.","success");
}

async function doLogout() {
  await sb.auth.signOut();
  _user=null; _profile=null; renderAuthArea();
}

async function loadProfile() {
  if (!_user) return;
  const {data} = await sb.from("bp_profiles").select("*").eq("user_id",_user.id).maybeSingle();
  _profile = data;
}

/* ── OFFER SUBMIT ── */
async function submitOffer(e) {
  e.preventDefault();
  const btn = document.getElementById("m-submit");
  if (btn) { btn.textContent="Wysyłam…"; btn.disabled=true; }
  hideAlert("m-alert");

  const cbs = document.querySelectorAll(".tier-checkbox:checked");
  let notes = `REGON: ${document.getElementById("m-regon")?.value||"—"}\n`;
  notes += `Pracownicy: ${document.querySelector("input[name=employees]:checked")?.value||"—"}\n`;
  notes += `Ochrona prawna: ${document.getElementById("legal-protection")?.checked?"TAK":"NIE"}\n\nZabiegi:\n`;
  [1,2,3,4].forEach(t => {
    const g = [...cbs].filter(cb => cb.getAttribute("data-tier")==t);
    if (g.length) notes += `--- Gr.${t} ---\n${g.map(cb=>cb.nextElementSibling?.textContent).join("\n")}\n`;
  });

  const {error} = await sb.from("bp_quotes").insert({
    user_id:      _user?.id||null,
    email:        document.getElementById("m-email")?.value,
    phone:        document.getElementById("m-phone")?.value,
    specialization: document.getElementById("fh-taryfa")?.value,
    sum_insured:  parseInt((document.getElementById("fh-variant")?.value||"").replace(/\D/g,""))||100000,
    annual_premium: parseInt((document.getElementById("fh-price")?.value||"").replace(/\D/g,""))||null,
    status: "new",
    notes
  });

  if (btn) { btn.textContent="Przekaż do weryfikacji"; btn.disabled=false; }
  if (error) showAlert("m-alert","Błąd wysyłania. Spróbuj ponownie.","error");
  else {
    showAlert("m-alert","✓ Wniosek przyjęty! Skontaktujemy się wkrótce.","success");
    setTimeout(() => { closeModal("modal-offer"); document.getElementById("offer-form")?.reset(); }, 2500);
  }
}

async function submitContact(e) {
  e.preventDefault();
  await sb.from("bp_quotes").insert({
    email: document.getElementById("ct-email")?.value,
    phone: document.getElementById("ct-phone")?.value,
    status: "contact",
    notes: `Imię: ${document.getElementById("ct-name")?.value}`
  });
  showAlert("ct-alert","Sukces! Skontaktujemy się.","success");
  setTimeout(()=>closeModal("modal-contact"),2000);
}

/* ── REGON ── */
function verifyRegon() {
  const inp    = document.getElementById("m-regon");
  const status = document.getElementById("regon-status");
  if (!inp || !status) return;
  const v = inp.value.replace(/\D/g, "");
  if (v.length === 9 || v.length === 14) {
    status.style.color = "#16a34a";
    status.textContent = "✓ Poprawny format REGON";
  } else if (v.length > 0) {
    status.style.color = "#dc2626";
    status.textContent = "REGON musi mieć 9 lub 14 cyfr";
  } else {
    status.textContent = "";
  }
}

/* ── ADMIN ── */
function buildAdminPanel() {
  const panel = document.createElement("div");
  panel.id = "admin-panel";
  panel.className = "admin-overlay";
  panel.innerHTML = `
    <div class="admin-topbar">
      <h2>⚙️ Panel Admina · BeautyPolisa</h2>
      <div class="admin-nav">
        <button class="admin-nav-btn active" id="anav-leads"     onclick="switchAdminTab('leads')">Leady OC</button>
        <button class="admin-nav-btn"         id="anav-analytics" onclick="switchAdminTab('analytics')">Analityka</button>
      </div>
      <button class="btn btn-xs btn-outline" style="color:#fff;border-color:rgba(255,255,255,.35)" onclick="closeAdmin()">✕ Zamknij</button>
    </div>
    <div class="admin-content">

      <!-- LEADS TAB -->
      <div class="admin-section active" id="atab-leads">
        <div class="stat-row" id="leads-stats">
          <div class="stat-card"><div class="stat-n" id="st-total">—</div><div class="stat-l">Wszystkich leadów</div></div>
          <div class="stat-card pink-stat"><div class="stat-n" id="st-new">—</div><div class="stat-l">Nowych</div></div>
          <div class="stat-card"><div class="stat-n" id="st-acc">—</div><div class="stat-l">Zaakceptowanych</div></div>
          <div class="stat-card"><div class="stat-n" id="st-today-leads">—</div><div class="stat-l">Dzisiaj</div></div>
        </div>
        <div class="admin-tbl-wrap">
          <div class="admin-tbl-hd">
            <h3>Wyceny OC · Formularz</h3>
            <div style="display:flex;gap:.4rem">
              <span style="font-size:9px;color:#94a3b8;align-self:center" id="leads-ts"></span>
              <button class="btn btn-xs btn-navy" onclick="loadLeads()">&#8635; Odśwież</button>
            </div>
          </div>
          <div style="overflow-x:auto">
            <table class="atbl">
              <thead><tr><th>Data</th><th>E-mail</th><th>Telefon</th><th>Taryfa</th><th>Suma</th><th>Składka</th><th>Status</th></tr></thead>
              <tbody id="leads-tbody"><tr><td colspan="7" style="text-align:center;padding:1.5rem;color:#94a3b8">Ładowanie…</td></tr></tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- ANALYTICS TAB -->
      <div class="admin-section" id="atab-analytics">
        <div class="stat-row" id="visits-stats">
          <div class="stat-card"><div class="stat-n" id="vst-total">—</div><div class="stat-l">Wszystkich wizyt</div></div>
          <div class="stat-card pink-stat"><div class="stat-n" id="vst-today">—</div><div class="stat-l">Dzisiaj</div></div>
          <div class="stat-card"><div class="stat-n" id="vst-week">—</div><div class="stat-l">Ten tydzień</div></div>
          <div class="stat-card"><div class="stat-n" id="vst-sessions">—</div><div class="stat-l">Unikalne sesje</div></div>
        </div>
        <div class="analytics-grid">
          <div class="chart-card"><h4>Wizyty – ostatnie 7 dni</h4><div id="chart-daily"></div></div>
          <div class="chart-card"><h4>Urządzenia</h4><div id="chart-devices"></div></div>
          <div class="chart-card"><h4>Top źródła (referrer)</h4><div id="chart-referrers"></div></div>
          <div class="chart-card"><h4>UTM Campaigns</h4><div id="chart-utm"></div></div>
        </div>
      </div>

    </div>`;
  document.body.appendChild(panel);
}

function switchAdminTab(tab) {
  ["leads","analytics"].forEach(t => {
    document.getElementById(`anav-${t}`)?.classList.toggle("active", t===tab);
    document.getElementById(`atab-${t}`)?.classList.toggle("active", t===tab);
  });
  if (tab==="analytics") loadAnalytics();
  else loadLeads();
}

function openAdmin()  { const p=document.getElementById("admin-panel"); if(p){p.classList.add("active"); loadLeads();} }
function closeAdmin() { const p=document.getElementById("admin-panel"); if(p) p.classList.remove("active"); }

async function loadLeads() {
  const tbody = document.getElementById("leads-tbody");
  const ts    = document.getElementById("leads-ts");
  if (!tbody) return;
  tbody.innerHTML = `<tr><td colspan="7" style="text-align:center;padding:1.5rem;color:#94a3b8">Ładowanie…</td></tr>`;

  const {data:quotes, error} = await sb.from("bp_quotes").select("*").order("created_at",{ascending:false}).limit(300);
  if (error) { tbody.innerHTML=`<tr><td colspan="7" style="text-align:center;color:var(--pink)">Błąd: ${error.message}</td></tr>`; return; }

  const today = new Date().toISOString().slice(0,10);
  const newCount   = (quotes||[]).filter(q=>q.status==="new").length;
  const accCount   = (quotes||[]).filter(q=>q.status==="accepted").length;
  const todayCount = (quotes||[]).filter(q=>q.created_at?.slice(0,10)===today).length;
  const setEl = (id,v) => { const e=document.getElementById(id); if(e) e.textContent=v; };
  setEl("st-total",quotes?.length||0); setEl("st-new",newCount); setEl("st-acc",accCount); setEl("st-today-leads",todayCount);
  if (ts) ts.textContent = "Zaktualizowano: "+new Date().toLocaleTimeString("pl-PL",{hour:"2-digit",minute:"2-digit"});

  if (!quotes?.length) { tbody.innerHTML=`<tr><td colspan="7" style="text-align:center;padding:1.5rem;color:#94a3b8">Brak danych</td></tr>`; return; }

  const statusLabel = {new:"Nowy",sent:"Wysłany",accepted:"Zaakceptowany",contact:"Kontakt",rejected:"Odrzucony"};
  tbody.innerHTML = "";
  quotes.forEach(q => {
    const d = new Date(q.created_at);
    const dateStr = d.toLocaleDateString("pl-PL")+" "+d.toLocaleTimeString("pl-PL",{hour:"2-digit",minute:"2-digit"});
    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td style="color:#64748b;white-space:nowrap;font-size:9px">${dateStr}</td>
      <td><a href="mailto:${q.email||''}" style="color:var(--navy);font-weight:600;font-size:10px">${q.email||"—"}</a></td>
      <td style="font-size:10px">${q.phone||"—"}</td>
      <td style="max-width:130px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;font-size:9px" title="${q.specialization||''}">${q.specialization||"—"}</td>
      <td style="white-space:nowrap;font-size:10px">${q.sum_insured?(q.sum_insured/1000).toFixed(0)+"k zł":"—"}</td>
      <td style="font-weight:700;color:var(--navy);white-space:nowrap;font-size:10px">${q.annual_premium?q.annual_premium.toLocaleString("pl-PL")+" zł":"—"}</td>
      <td><select class="ssel" data-id="${q.id}" onchange="updateQuoteStatus(this)">
        ${["new","sent","accepted","contact","rejected"].map(s=>`<option value="${s}" ${q.status===s?"selected":""}>${statusLabel[s]}</option>`).join("")}
      </select></td>`;
    tbody.appendChild(tr);
  });
}

async function updateQuoteStatus(sel) {
  const id=sel.getAttribute("data-id"), status=sel.value;
  await sb.from("bp_quotes").update({status}).eq("id",id);
}

async function loadAnalytics() {
  const {data:visits} = await sb.from("bp_analytics").select("*").order("created_at",{ascending:false}).limit(5000);
  if (!visits) return;

  const today  = new Date().toISOString().slice(0,10);
  const weekAgo = new Date(Date.now()-7*864e5).toISOString().slice(0,10);
  const vToday  = visits.filter(v=>v.created_at?.slice(0,10)===today).length;
  const vWeek   = visits.filter(v=>v.created_at?.slice(0,10)>=weekAgo).length;
  const vSess   = new Set(visits.map(v=>v.session_id)).size;
  const setEl = (id,v) => { const e=document.getElementById(id); if(e) e.textContent=v; };
  setEl("vst-total",visits.length); setEl("vst-today",vToday); setEl("vst-week",vWeek); setEl("vst-sessions",vSess);

  // Daily chart — last 7 days
  const dailyMap = {};
  for (let i=6;i>=0;i--) {
    const d = new Date(Date.now()-i*864e5).toISOString().slice(0,10);
    dailyMap[d] = 0;
  }
  visits.forEach(v => { const d=v.created_at?.slice(0,10); if(d in dailyMap) dailyMap[d]++; });
  renderBarChart("chart-daily", Object.entries(dailyMap).map(([k,v])=>[k.slice(5),v]), false);

  // Devices
  const devMap = {};
  visits.forEach(v => { const d=v.device||"unknown"; devMap[d]=(devMap[d]||0)+1; });
  renderBarChart("chart-devices", Object.entries(devMap).sort((a,b)=>b[1]-a[1]), true);

  // Referrers
  const refMap = {};
  visits.forEach(v => {
    if (!v.referrer) return;
    try { const h=new URL(v.referrer).hostname.replace("www.",""); refMap[h]=(refMap[h]||0)+1; } catch(_){}
  });
  const topRef = Object.entries(refMap).sort((a,b)=>b[1]-a[1]).slice(0,6);
  renderBarChart("chart-referrers", topRef.length ? topRef : [["(bezpośrednie)",visits.length]], true);

  // UTM
  const utmMap = {};
  visits.forEach(v => { if(v.utm_campaign){ utmMap[v.utm_campaign]=(utmMap[v.utm_campaign]||0)+1; } });
  const topUtm = Object.entries(utmMap).sort((a,b)=>b[1]-a[1]).slice(0,6);
  renderBarChart("chart-utm", topUtm.length ? topUtm : [["brak UTM",visits.length]], true);
}

function renderBarChart(containerId, data, pinkBars) {
  const container = document.getElementById(containerId);
  if (!container) return;
  container.innerHTML = "";
  const max = Math.max(...data.map(d=>d[1]), 1);
  data.forEach(([label, val]) => {
    const row = document.createElement("div");
    row.className = "bar-row";
    row.innerHTML = `<div class="bar-label">${label}</div>
      <div class="bar-track"><div class="bar-fill${pinkBars?" pink-bar":""}" style="width:${Math.round(val/max*100)}%"></div></div>
      <div class="bar-val">${val}</div>`;
    container.appendChild(row);
  });
}

/* ── MODALS ── */
function buildModals() {
  // Auth modal
  appendModal("modal-auth", `
    <div class="mbox-hd"><div><h3>Panel Klienta</h3><p>BeautyPolisa · Aura Consulting</p></div><button class="mclose" onclick="closeModal('modal-auth')">&#10005;</button></div>
    <div class="mtabs"><button class="mtab active" id="atab-login" onclick="switchAuthTab('login')">Zaloguj się</button><button class="mtab" id="atab-register" onclick="switchAuthTab('register')">Załóż konto</button></div>
    <div class="mbox-body">
      <div id="af-alert" class="bp-alert" style="display:none"></div>
      <div id="af-login">
        <div class="mgroup"><label class="mlabel">E-mail</label><input type="email" class="minput" id="af-email" placeholder="twoj@salon.pl"></div>
        <div class="mgroup"><label class="mlabel">Hasło</label><input type="password" class="minput" id="af-pass" placeholder="••••••••"></div>
        <button class="btn btn-md btn-navy" style="width:100%;padding:.7rem" id="af-login-btn" onclick="doLogin()">Zaloguj się</button>
      </div>
      <div id="af-register" style="display:none">
        <div class="mgroup"><label class="mlabel">Imię i nazwisko</label><input type="text" class="minput" id="af-name" placeholder="Anna Kowalska"></div>
        <div class="mgroup"><label class="mlabel">E-mail</label><input type="email" class="minput" id="af-reg-email" placeholder="twoj@salon.pl"></div>
        <div class="mgroup"><label class="mlabel">Hasło (min. 8 znaków)</label><input type="password" class="minput" id="af-reg-pass" placeholder="••••••••"></div>
        <div class="mgroup"><label class="mlabel">Telefon</label><input type="tel" class="minput" id="af-phone" placeholder="+48 000 000 000"></div>
        <button class="btn btn-md btn-pink" style="width:100%;padding:.7rem" id="af-reg-btn" onclick="doRegister()">Utwórz konto</button>
      </div>
    </div>`);

  // Offer modal
  appendModal("modal-offer", `
    <div class="mbox-hd">
      <div><h3>Wniosek o polisę</h3><p>Wariant: <strong id="m-variant" style="color:var(--pink)"></strong> · <strong id="m-price" style="color:var(--navy)"></strong></p></div>
      <button class="mclose" onclick="closeModal('modal-offer')">&#10005;</button>
    </div>
    <div class="mbox-body">
      <div id="m-alert" class="bp-alert" style="display:none"></div>
      <form id="offer-form" onsubmit="submitOffer(event)">
        <input type="hidden" id="fh-variant"><input type="hidden" id="fh-price"><input type="hidden" id="fh-taryfa">
        <div class="mgroup">
          <label class="mlabel">Numer REGON</label>
          <input type="text" class="minput" id="m-regon" placeholder="9 lub 14 cyfr" oninput="verifyRegon()" inputmode="numeric" maxlength="14">
          <div id="regon-status" style="font-size:8px;color:#16a34a;font-weight:600;margin-top:.2rem;min-height:11px"></div>
        </div>
        <div class="mgroup"><label class="mlabel">E-mail</label><input type="email" class="minput" id="m-email" required placeholder="kontakt@salon.pl"></div>
        <div class="mgroup"><label class="mlabel">Telefon</label><input type="tel" class="minput" id="m-phone" required placeholder="500 000 000"></div>
        <button type="submit" class="btn btn-md btn-navy" style="width:100%;padding:.7rem" id="m-submit">Przekaż do weryfikacji</button>
      </form>
    </div>`);

  // Contact modal
  appendModal("modal-contact", `
    <div class="mbox-hd"><div><h3>Masz pytania?</h3><p>Oddzwonimy do Ciebie.</p></div><button class="mclose" onclick="closeModal('modal-contact')">&#10005;</button></div>
    <div class="mbox-body">
      <div id="ct-alert" class="bp-alert" style="display:none"></div>
      <form onsubmit="submitContact(event)">
        <div class="mgroup"><label class="mlabel">Imię</label><input type="text" class="minput" id="ct-name" required placeholder="Anna"></div>
        <div class="mgroup"><label class="mlabel">E-mail</label><input type="email" class="minput" id="ct-email" required placeholder="twoj@email.pl"></div>
        <div class="mgroup"><label class="mlabel">Telefon</label><input type="tel" class="minput" id="ct-phone" required placeholder="500 000 000"></div>
        <button type="submit" class="btn btn-md btn-pink" style="width:100%;padding:.7rem">Proszę o kontakt</button>
      </form>
    </div>`);

  // Dystrybutor
  appendModal("modal-dystrybutor", `
    <div class="mbox-hd"><h3>Informacja o dystrybutorze</h3><button class="mclose" onclick="closeModal('modal-dystrybutor')">&#10005;</button></div>
    <div class="mbox-body" style="font-size:9px;color:#475569;line-height:1.7">
      <p><strong>Aura Expert sp. z o.o.</strong> · ul. Bolkowska 2A/28, 01-466 Warszawa<br>E-mail: zarzad@auraexpert.pl · Tel. +48 504 400 901</p>
      <p>KRS: 0000599840 · NIP: 5242793544 · REGON: 363673048<br>Rejestr agentów KNF: 11229690/A</p>
      <p>Agent działa na rzecz: ERGO Hestia, UNIQA, Generali, Colonnade, Saltus. Prowizja uwzględniona w kwocie składki.</p>
    </div>`);

  // RODO
  appendModal("modal-rodo", `
    <div class="mbox-hd"><h3>Nota RODO</h3><button class="mclose" onclick="closeModal('modal-rodo')">&#10005;</button></div>
    <div class="mbox-body" style="font-size:9px;color:#475569;line-height:1.7">
      <p><strong>Administrator:</strong> Aura Expert sp. z o.o., ul. Bolkowska 2A lok. 28, 01-466 Warszawa</p>
      <p><strong>Cel:</strong> Wykonywanie czynności agencyjnych i obsługa zapytań ubezpieczeniowych.</p>
      <p><strong>Prawa:</strong> dostęp, sprostowanie, usunięcie, ograniczenie, przeniesienie, sprzeciw, skarga do UODO.</p>
      <p><strong>Kontakt IOD:</strong> iod@auraexpert.pl · +48 504 400 901</p>
    </div>`);
}

function appendModal(id, html) {
  const wrap = document.createElement("div");
  wrap.id = id; wrap.className = "bp-modal";
  wrap.onclick = e => { if (e.target===wrap) closeModal(id); };
  const box = document.createElement("div"); box.className = "mbox";
  box.innerHTML = html; wrap.appendChild(box);
  document.body.appendChild(wrap);
}

/* ── INIT ── */
async function init() {
  buildPage();
  sb.auth.onAuthStateChange(async (_ev, session) => {
    _user = session?.user || null;
    await loadProfile();
    renderAuthArea();
  });
  const {data:{user}} = await sb.auth.getUser();
  _user = user;
  await loadProfile();
  renderAuthArea();
  // ESC zamyka aktywny modal
  document.addEventListener("keydown", e => {
    if (e.key !== "Escape") return;
    document.querySelectorAll(".bp-modal.active").forEach(m => closeModal(m.id));
  });
  // Rejestruj wizytę (z małym opóźnieniem, żeby auth zdążył załadować)
  setTimeout(trackVisit, 800);
}

/* ── EXPOSE GLOBALS ── */
Object.assign(window, {
  selectAll, updateCalculator, openModal, closeModal,
  openOfferModal, submitOffer, submitContact,
  doLogin, doRegister, doLogout, switchAuthTab, verifyRegon,
  openAdmin, closeAdmin, switchAdminTab, loadLeads, loadAnalytics, updateQuoteStatus
});

init();
})();
