const CACHE_NAME = 'campolongo-team-sheet-v2';
const APP_SHELL = [
  './',
  './index.html',
  './manifest.webmanifest',
  './icon-192.png',
  './icon-512.png',
  './logo.png',
  './logolega.jpg',
  './giocatore.png'
];

self.addEventListener('install', event=>{
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache=>cache.addAll(APP_SHELL))
      .then(()=>self.skipWaiting())
  );
});

self.addEventListener('activate', event=>{
  event.waitUntil(
    caches.keys()
      .then(keys=>Promise.all(keys
        .filter(key=>key.startsWith('campolongo-team-sheet-') && key !== CACHE_NAME)
        .map(key=>caches.delete(key))))
      .then(()=>self.clients.claim())
  );
});

self.addEventListener('fetch', event=>{
  const request = event.request;
  if(request.method !== 'GET' || new URL(request.url).origin !== self.location.origin) return;

  if(request.mode === 'navigate'){
    event.respondWith(
      fetch(request)
        .then(response=>{
          if(response.ok){
            const copy = response.clone();
            caches.open(CACHE_NAME).then(cache=>cache.put(request, copy));
          }
          return response;
        })
        .catch(async ()=>{
          return await caches.match(request) || await caches.match('./index.html');
        })
    );
    return;
  }

  if(request.destination === 'image' || request.url.endsWith('.webmanifest')){
    event.respondWith(
      caches.match(request).then(cached=>{
        if(cached) return cached;
        return fetch(request).then(response=>{
          if(response.ok){
            const copy = response.clone();
            caches.open(CACHE_NAME).then(cache=>cache.put(request, copy));
          }
          return response;
        });
      })
    );
  }
});
