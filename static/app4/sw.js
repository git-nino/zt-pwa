// Install Service Worker
self.addEventListener('install', event => {
    self.skipWaiting();
    console.log('Service Worker Installed');
});

// Activate Service Worker
self.addEventListener('activate', event => {
    self.clients.claim();
    console.log('Service Worker Activated');
});

// Fetch handler
self.addEventListener('fetch', event => {
    const request = event.request;

    // Always fetch fresh HTML pages (navigation requests)
    if (request.mode === 'navigate') {
        event.respondWith(
            fetch(request)
                .then(response => response)
                .catch(err => caches.match(request)) // fallback to cache if offline
        );
    } else {
        // For other requests (CSS, JS, images), just fetch normally
        event.respondWith(fetch(request));
    }
});
