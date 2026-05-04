# StockMind

StockMind es una aplicación Flutter para gestión de inventario con experiencia SaaS moderna, autenticación con Firebase y dashboard responsive para web, tablet y móvil.

## Qué incluye

- Dashboard con métricas de stock, valor de inventario y salud operativa.
- Gráficos con `fl_chart`.
- CRUD de productos con búsqueda y filtros.
- Alertas automáticas de bajo stock.
- Firebase Auth con email/contraseña, Google Sign-In y recuperación de contraseña.
- Persistencia de sesión.
- Modo claro/oscuro persistente.
- Navegación moderna con sidebar y mobile navigation.

## Stack

- Flutter 3.41+
- Provider
- GoRouter
- Firebase Core
- Firebase Auth
- Cloud Firestore
- Google Sign-In
- Google Fonts
- FL Chart

## Estructura

```text
lib/
  core/
    router/
    theme/
  features/
    app/
    auth/
    dashboard/
    shell/
  models/
  providers/
  services/
    auth/
    products/
    stock/
```

## Capturas

Usa estos placeholders para capturas reales:

- `docs/screenshots/login.png`
- `docs/screenshots/dashboard.png`
- `docs/screenshots/products.png`
- `docs/screenshots/alerts.png`

## Configuración Firebase

1. Ejecuta `flutterfire configure`.
2. Habilita en Firebase Console:
   - Authentication > Email/Password
   - Authentication > Google
   - Firestore Database
3. Para Android, registra SHA-1/SHA-256.
4. Para web, confirma dominios autorizados.

## Instalación

```bash
flutter pub get
flutter run -d chrome
```

## Modelo Firestore sugerido

```text
users/{uid}/products/{productId}
```

Campos por producto:

- `name`
- `category`
- `sku`
- `price`
- `stock`
- `minimumStock`
- `createdAt`
- `updatedAt`

## Notas

- Si el inventario está vacío, el dashboard incluye `Cargar demo`.
- Si Firebase no está configurado, la app muestra una pantalla de setup con instrucciones.
