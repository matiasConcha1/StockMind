# StockMind Deployment

## Scope

This document covers the current deployment flow for the Flutter Web app hosted on Firebase.

## Build The Web App

```bash
flutter pub get
flutter build web --release
```

The generated files are written to `build/web`, which matches the current Firebase Hosting configuration.

## Deploy To Firebase Hosting

### First-time setup

If Firebase CLI is not configured on your machine yet:

```bash
firebase login
```

This repository already includes `firebase.json`, so running `firebase init hosting` is not required unless you want to reconfigure the hosting target from scratch.

### Standard deployment

```bash
flutter build web --release
firebase deploy
```

## Hosting Configuration

The project is configured to serve the compiled web app from:

- `public`: `build/web`

Routing is handled through this rewrite in `firebase.json`:

```json
{
  "source": "**",
  "destination": "/index.html"
}
```

This keeps `GoRouter` routes working correctly in production.

## Custom Domain

To connect a custom domain:

1. Open Firebase Console.
2. Go to `Hosting`.
3. Select `Add custom domain`.
4. Complete DNS and SSL verification in the Firebase wizard.

## Web Push Notifications

If you need real web push support through Firebase Cloud Messaging, build with the public VAPID key:

```bash
flutter build web --release --dart-define=FCM_WEB_VAPID_KEY=YOUR_PUBLIC_VAPID_KEY
firebase deploy
```

The base service worker file already exists at `web/firebase-messaging-sw.js`.
