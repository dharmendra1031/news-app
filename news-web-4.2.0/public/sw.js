// Service worker for PWA install + offline asset caching.
// Push notifications are handled separately by firebase-messaging-sw.js —
// FCM subscribes against that registration directly, so it's the only one
// that ever receives a 'push' event; no need to duplicate that here.
self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

const CACHE_NAME = 'news-cache-v1';

self.addEventListener('fetch', (event) => {
  // Skip cross-origin requests
  if (!event.request.url.startsWith(self.location.origin)) {
    return;
  }

  // Network-first strategy for HTML pages, so navigations always get the
  // latest page when online and only fall back to the cache when offline.
  if (event.request.headers.get('Accept')?.includes('text/html')) {
    event.respondWith(
      fetch(event.request).catch(() => caches.match(event.request))
    );
    return;
  }

  // Cache-first strategy for static assets (scripts, styles, images, fonts).
  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      if (cachedResponse) {
        return cachedResponse;
      }

      return fetch(event.request)
        .then((response) => {
          // Don't cache non-successful or opaque responses.
          if (!response || response.status !== 200 || response.type !== 'basic') {
            return response;
          }

          const responseToCache = response.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(event.request, responseToCache);
          });

          return response;
        })
        .catch(() => {
          if (event.request.destination === 'image') {
            return new Response();
          }
        });
    })
  );
});
