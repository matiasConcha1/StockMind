# Deploy StockMind

## Build Web

```bash
flutter clean
flutter pub get
flutter build web --release
```

## Firebase Hosting

1. Inicia sesión:

```bash
firebase login
```

2. Si todavía no lo hiciste, inicializa Hosting:

```bash
firebase init hosting
```

Usa estas opciones:

- `public`: `build/web`
- `single-page app rewrite`: `Yes`
- no sobrescribas `index.html` si Firebase CLI lo pregunta

3. Despliega:

```bash
firebase deploy
```

## Dominio personalizado

1. Abre Firebase Console.
2. Ve a `Hosting`.
3. Pulsa `Agregar dominio personalizado`.
4. Sigue el wizard para validar DNS y SSL.

## Flutter Web Routing

`firebase.json` ya debe conservar el rewrite:

```json
{
  "source": "**",
  "destination": "/index.html"
}
```

Esto permite que `GoRouter` funcione bien en rutas directas.

## Notificaciones web

Si quieres push web real con FCM:

1. Genera la Web Push certificate key (VAPID) en Firebase Console.
2. Construye con:

```bash
flutter build web --release --dart-define=FCM_WEB_VAPID_KEY=TU_VAPID_PUBLIC_KEY
```

3. Despliega nuevamente.

El archivo `web/firebase-messaging-sw.js` ya quedó preparado como base.
