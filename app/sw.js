// Tide service worker: keeps a copy of the app so it opens even when the
// launcher window is closed. Spotify traffic is never touched.
const VERSION = 'tide-v1';
const CORE = [
  '/',
  '/manifest.webmanifest',
  '/icons/icon.svg',
  '/icons/icon-192.png',
  '/icons/icon-512.png',
  '/icons/icon-maskable-512.png',
  '/fonts/big-shoulders-display-latin-wght-normal.woff2',
  '/fonts/schibsted-grotesk-latin-wght-normal.woff2',
  '/fonts/schibsted-grotesk-latin-ext-wght-normal.woff2'
];

self.addEventListener('install', event => {
  event.waitUntil(caches.open(VERSION).then(cache => cache.addAll(CORE)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== VERSION).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;

  // Pages (including the Spotify sign-in return at /callback): try the
  // local server first so updates show up, fall back to the saved copy
  // when the server is off or doesn't know the address.
  if (req.mode === 'navigate') {
    event.respondWith(
      fetch(req)
        .then(res => {
          if (res.ok) {
            const copy = res.clone();
            caches.open(VERSION).then(cache => cache.put('/', copy));
            return res;
          }
          return caches.match('/').then(hit => hit || res);
        })
        .catch(() => caches.match('/'))
    );
    return;
  }

  // Everything else: serve the saved copy, refresh it in the background.
  event.respondWith(
    caches.match(req).then(hit => {
      const fresh = fetch(req)
        .then(res => {
          if (res.ok) {
            const copy = res.clone();
            caches.open(VERSION).then(cache => cache.put(req, copy));
          }
          return res;
        })
        .catch(() => hit);
      return hit || fresh;
    })
  );
});
