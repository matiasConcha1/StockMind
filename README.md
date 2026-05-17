# StockMind

<p align="center">
  <img src="assets/images/logo_icon.png" width="120" alt="StockMind logo" />
</p>

<p align="center">
  Smart inventory management SaaS built with Flutter Web and Firebase.
</p>

<p align="center">
  StockMind helps teams control products, locations, alerts, and stock movements from a responsive web platform designed for modern operations.
</p>

<p align="center">
  <a href="https://ejemplofirebase-38f98.web.app">Live demo</a>
</p>

## Overview

StockMind is a product-oriented inventory platform focused on visibility, execution speed, and operational control. It combines authentication, inventory workflows, analytics, export tools, and cloud deployment into a single Flutter Web application backed by Firebase.

It is positioned as a lightweight SaaS for companies that need a cleaner alternative to spreadsheets or fragmented stock processes.

## Product Highlights

- Responsive inventory platform for desktop and tablet workflows
- Firebase Authentication with email/password and Google sign-in
- Product catalog with stock, metadata, and image management
- Multi-location inventory organization
- Low-stock monitoring and alert flows
- Inventory analytics and movement tracking
- Export capabilities for operational reporting
- PWA support for installable web experience
- Firebase Hosting deployment ready

## Demo

- Production demo: `https://ejemplofirebase-38f98.web.app`

## Screenshots

### Login
<img src="assets/screenshots/login.png" width="100%" alt="StockMind login screen" />

### Register
<img src="assets/screenshots/register.png" width="100%" alt="StockMind register screen" />

### Inventory Control Center
<img src="assets/screenshots/dashboard.png" width="100%" alt="StockMind inventory control center" />

### Products
<img src="assets/screenshots/products.png" width="100%" alt="StockMind products view" />

### New Product
<img src="assets/screenshots/products2.png" width="100%" alt="StockMind product creation view" />

### Alerts
<img src="assets/screenshots/alerts.png" width="100%" alt="StockMind stock alerts" />

### Locations
<img src="assets/screenshots/locations.png" width="100%" alt="StockMind locations module" />

### New Location
<img src="assets/screenshots/locations2.png" width="100%" alt="StockMind location creation view" />

### Settings
<img src="assets/screenshots/settings.png" width="100%" alt="StockMind settings screen" />

### Profile And Security
<img src="assets/screenshots/settings2.png" width="100%" alt="StockMind profile and security screen" />

## Core Features

- Authentication and protected access flows
- Product registration, editing, and stock visibility
- Inventory location management
- Stock movement and operational snapshot views
- Smart low-stock alerts
- File and image storage for operational records
- Excel and PDF export support
- Responsive UI for mobile-aware web usage

## Tech Stack

| Layer | Technology |
| --- | --- |
| Frontend | Flutter Web, Dart |
| State management | Provider |
| Routing | GoRouter |
| Backend services | Firebase |
| Authentication | Firebase Auth, Google Sign-In |
| Database | Cloud Firestore |
| Storage | Firebase Storage |
| Notifications | Firebase Messaging |
| Charts and reporting | fl_chart, pdf, excel |
| Deployment | Firebase Hosting |

## Project Architecture

The codebase is organized by feature and shared core modules:

```text
lib/
  app/                    App bootstrap and routing
  core/                   Shared theme, widgets, services, constants, utilities
  features/
    activity_logs/        Activity and audit-related services
    alerts/               Low-stock alert logic and UI
    auth/                 Authentication flows and providers
    company/              Company profile and onboarding
    dashboard/            Inventory analytics and overview screens
    locations/            Inventory location management
    products/             Product catalog and stock operations
    replenishment/        Replenishment requests and workflows
    users/                User and role management views
  firebase_options.dart   Firebase platform configuration
  main.dart               Application entrypoint
```

## Local Installation

### Prerequisites

- Flutter SDK compatible with `>=3.5.0 <4.0.0`
- Dart SDK included with Flutter
- Firebase project configured for the app

### Run locally

```bash
flutter pub get
flutter run -d chrome
```

If Firebase credentials need to be refreshed, verify `lib/firebase_options.dart` and `android/app/google-services.json` match your target project.

## Web Build

```bash
flutter build web --release
```

The build output is generated in `build/web`.

## Firebase Deployment

The repository already includes Firebase Hosting configuration in `firebase.json`.

```bash
firebase login
flutter build web --release
firebase deploy
```

For web push notifications, build with the VAPID key when needed:

```bash
flutter build web --release --dart-define=FCM_WEB_VAPID_KEY=YOUR_PUBLIC_VAPID_KEY
firebase deploy
```

## Roadmap

- Multi-tenant SaaS setup by company or workspace
- Advanced inventory forecasting and replenishment suggestions
- Richer analytics for stock turnover and demand trends
- Role-based permissions refinement
- Operational audit trail and activity insights
- Billing and subscription readiness

## Author

- Matias Concha
- GitHub: [@matiasConcha1](https://github.com/matiasConcha1)

## License

This project is distributed under the MIT License. See [LICENSE](LICENSE) for details.
