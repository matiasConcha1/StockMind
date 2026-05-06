importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCMEDX0KEhMBnbVKYpx9HHhasleAppGK3E',
  authDomain: 'ejemplofirebase-38f98.firebaseapp.com',
  projectId: 'ejemplofirebase-38f98',
  storageBucket: 'ejemplofirebase-38f98.firebasestorage.app',
  messagingSenderId: '464927983622',
  appId: '1:464927983622:web:a6564aa10a146f9af21b87',
  measurementId: 'G-P7JNPZYK1E',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || 'StockMind';
  const options = {
    body:
        payload.notification?.body ||
        'Tienes una nueva alerta de inventario.',
    icon: '/icons/Icon-192.png',
  };
  self.registration.showNotification(title, options);
});
