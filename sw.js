/* ============================================================
   SERVICE WORKER — Dr. Malaquias Fibromialgia (PWA)
   Estrategia SEGURA p/ sistema em producao:
   - HTML/navegacao: NETWORK-FIRST -> quando ONLINE, sempre pega a versao mais
     nova do Vercel (NUNCA prende ninguem em versao velha). Offline -> usa o
     shell cacheado.
   - Supabase (dados): SEM cache, sempre rede (dados precisam estar vivos).
   - CDN/estaticos: cache-first (libs versionadas/estaveis).
   - skipWaiting + clients.claim: SW novo assume na hora.
   Bump CACHE_VERSION pra invalidar o cache antigo num proximo deploy.
   ============================================================ */
const CACHE_VERSION = 'mlq-fibro-v9';
const SHELL_URL = '/';

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_VERSION).then((cache) => cache.addAll(['/', '/index.html', '/icon.svg', '/manifest.json']).catch(() => {}))
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== CACHE_VERSION).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return; /* nao toca POST/PATCH/DELETE (saves) */

  let url;
  try { url = new URL(req.url); } catch (_) { return; }

  /* Supabase (REST + realtime + auth): SEMPRE rede, nunca cacheia dados vivos. */
  if (url.hostname.endsWith('supabase.co')) return;

  /* Navegacao / HTML: NETWORK-FIRST (online = sempre fresco; offline = shell). */
  const isNav = req.mode === 'navigate' ||
    (req.headers.get('accept') || '').includes('text/html');
  if (isNav) {
    event.respondWith(
      fetch(req)
        .then((res) => {
          const copy = res.clone();
          caches.open(CACHE_VERSION).then((c) => c.put(SHELL_URL, copy)).catch(() => {});
          return res;
        })
        .catch(() => caches.match(req).then((m) => m || caches.match(SHELL_URL)))
    );
    return;
  }

  /* Estaticos/CDN (fontes, chart.js, etc.): cache-first com fallback rede. */
  event.respondWith(
    caches.match(req).then((cached) => cached || fetch(req).then((res) => {
      if (res && res.status === 200 && (res.type === 'basic' || res.type === 'cors')) {
        const copy = res.clone();
        caches.open(CACHE_VERSION).then((c) => c.put(req, copy)).catch(() => {});
      }
      return res;
    }).catch(() => cached))
  );
});
