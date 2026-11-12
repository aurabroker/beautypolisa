// Podgląd roboczy BeautyPolisa: pliki statyczne za hasłem (HTTP Basic), bez indeksowania.
// Hasło tylko w sekrecie Workera PODGLAD_HASLO – bez sekretu Worker blokuje wszystko.
import { ASSETS } from './assets.js';
const USER = 'beautypolisa';
const enc = new TextEncoder();

async function same(a, b) {
  const [x, y] = await Promise.all([crypto.subtle.digest('SHA-256', enc.encode(a)), crypto.subtle.digest('SHA-256', enc.encode(b))]);
  return crypto.subtle.timingSafeEqual(x, y);
}

function harden(res) {
  const r = new Response(res.body, res);
  r.headers.set('X-Robots-Tag', 'noindex, nofollow, noarchive');
  r.headers.set('Cache-Control', 'private, no-store');
  r.headers.set('Referrer-Policy', 'no-referrer');
  r.headers.set('X-Content-Type-Options', 'nosniff');
  r.headers.set('X-Frame-Options', 'DENY');
  r.headers.set('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
  r.headers.set('Strict-Transport-Security', 'max-age=31536000');
  return r;
}

const deny = () => harden(new Response('Podgląd roboczy BeautyPolisa – wymagane logowanie.', {
  status: 401,
  headers: { 'WWW-Authenticate': 'Basic realm="BeautyPolisa - podglad roboczy", charset="UTF-8"', 'Content-Type': 'text/plain; charset=utf-8' },
}));

export default {
  async fetch(request, env) {
    if (!env.PODGLAD_HASLO) return harden(new Response('Podgląd wyłączony.', { status: 503 }));
    const auth = request.headers.get('Authorization') || '';
    if (!auth.startsWith('Basic ')) return deny();
    let user = '', pass = '';
    try {
      const raw = new TextDecoder().decode(Uint8Array.from(atob(auth.slice(6)), (c) => c.charCodeAt(0)));
      const i = raw.indexOf(':');
      user = raw.slice(0, i); pass = raw.slice(i + 1);
    } catch { return deny(); }
    const ok = (await same(user, USER)) & (await same(pass, env.PODGLAD_HASLO));
    if (!ok) return deny();
    const url = new URL(request.url);
    let path = decodeURIComponent(url.pathname);
    if (path.endsWith('/')) path += 'index.html';
    let hit = ASSETS[path] || ASSETS[path + '.html'];
    if (!hit && path.endsWith('/index.html')) hit = ASSETS['/index.html'];
    if (!hit) return harden(new Response('Nie ma takiej strony w podglądzie.', { status: 404, headers: { 'Content-Type': 'text/plain; charset=utf-8' } }));
    if (request.method !== 'GET' && request.method !== 'HEAD') return harden(new Response(null, { status: 405 }));
    return harden(new Response(request.method === 'HEAD' ? null : hit[0], { headers: { 'Content-Type': hit[1] } }));
  },
};
