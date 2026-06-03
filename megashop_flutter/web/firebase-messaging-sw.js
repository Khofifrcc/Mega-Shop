importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBVEhQy_yfRTucX7VTGNKf7Y3PIZ2HkLa0',
  appId: '1:825628512269:web:c5c169bc581d8f11794544',
  messagingSenderId: '825628512269',
  projectId: 'megashop-c6e70',
  authDomain: 'megashop-c6e70.firebaseapp.com',
  storageBucket: 'megashop-c6e70.firebasestorage.app',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notification = payload.notification || {};
  const title = notification.title || 'MegaShop';
  const options = {
    body: notification.body || 'You have a new update.',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data || {},
  };

  self.registration.showNotification(title, options);
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const data = event.notification.data || {};
  const target = data.type === 'chat' ? '/#/chat' : '/#/notifications';

  event.waitUntil(
    clients.matchAll({type: 'window', includeUncontrolled: true}).then((clientList) => {
      for (const client of clientList) {
        if ('focus' in client) {
          client.navigate(target);
          return client.focus();
        }
      }

      if (clients.openWindow) {
        return clients.openWindow(target);
      }
    })
  );
});
