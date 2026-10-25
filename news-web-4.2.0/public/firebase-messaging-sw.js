// Push notification handling only — no Firebase SDK or config here.
// FCM subscribes against this registration (see getFcmToken in
// src/utils/Firebase.ts), so the raw 'push' event carries the FCM payload.

const getNotificationUrl = (data) => {
    if (data.url || data.click_action) return data.url || data.click_action;
    if (data.news_slug) return `/${data.language_code}/news/${data.news_slug}`;
    if (data.podcast_slug) return `/${data.language_code}/podcast/${data.podcast_slug}`;
    return '/';
};

self.addEventListener('push', (event) => {
    if (!event.data) return;

    let payload;
    try {
        payload = event.data.json();
    } catch {
        return;
    }
    const notification = payload.notification || {};
    const data = payload.data || {};
    const title = notification.title || notification.body || '';
    const options = {
        body: notification.body,
        icon: notification.icon || data.image || '/favicon.png',
        data: { url: getNotificationUrl(data), id: data.news_id },
    };

    event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', (event) => {
    event.notification.close();

    const targetUrl = event.notification.data && event.notification.data.url
        ? event.notification.data.url
        : '/';

    event.waitUntil(
        self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientsList) => {
            for (const client of clientsList) {
                const clientUrl = new URL(client.url);
                if (clientUrl.origin === self.location.origin && 'focus' in client) {
                    client.focus();
                    if ('navigate' in client) {
                        return client.navigate(targetUrl);
                    }
                    return;
                }
            }
            return self.clients.openWindow(targetUrl);
        })
    );
});
