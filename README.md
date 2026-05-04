# StockMind

StockMind es una aplicación Flutter para gestión de inventario con autenticación Firebase, dashboard administrativo responsive, alertas de stock bajo y soporte de tema claro/oscuro.

## Vista Previa

![Vista general de StockMind](assets/screenshots/cover-placeholder.png)

![Demo de StockMind](assets/screenshots/preview.gif)

## Descripción

StockMind está pensado como una base profesional para un sistema de inventario moderno. El proyecto combina una estructura escalable por features con Firebase Auth, Cloud Firestore y una interfaz orientada a dashboard SaaS.

El objetivo es servir tanto como proyecto de portafolio como base real para evolucionar a un producto comercial.

## Funcionalidades

### Autenticación

- Inicio de sesión con correo y contraseña
- Registro de usuarios
- Recuperación de contraseña
- Google Sign-In
- Persistencia de sesión

### Dashboard

- Métricas principales del inventario
- Resumen de productos y stock
- Visualización de datos con gráficos
- Indicadores de productos con bajo stock

### Gestión de productos

- Crear productos
- Editar productos
- Eliminar productos
- Buscar por nombre, categoría o SKU
- Filtrar por categoría
- Filtrar por estado de stock

### Alertas

- Detección automática de productos críticos
- Vista dedicada de alertas
- Cobertura de stock saludable

### Experiencia de usuario

- Interfaz responsive para web, tablet y móvil
- Sidebar de navegación
- Navegación sin recarga completa
- Tema claro y oscuro persistente

## Tecnologías

- Flutter
- Dart
- Firebase Core
- Firebase Authentication
- Cloud Firestore
- Provider
- GoRouter
- Google Fonts
- FL Chart
- Shared Preferences

## Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/matiasConcha1/StockMind.git
cd StockMind
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar Firebase

Ejecuta FlutterFire CLI:

```bash
flutterfire configure
```

Después habilita en Firebase Console:

- `Authentication > Email/Password`
- `Authentication > Google`
- `Firestore Database`

Configuración recomendada:

- Android: registrar `SHA-1` y `SHA-256`
- Web: agregar dominio autorizado

### 4. Ejecutar el proyecto

```bash
flutter run -d chrome
```

## Estructura del Proyecto

```text
lib/
├── app/
│   ├── app.dart
│   └── routes.dart
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── widgets/
├── features/
│   ├── alerts/
│   ├── auth/
│   ├── dashboard/
│   └── products/
├── firebase_options.dart
└── main.dart
```

## Capturas

### Login

![Pantalla de login](assets/screenshots/login-placeholder.png)

### Dashboard

![Dashboard administrativo](assets/screenshots/dashboard-placeholder.png)

### Productos

![Gestión de productos](assets/screenshots/products-placeholder.png)

### Alertas

![Alertas de stock](assets/screenshots/alerts-placeholder.png)

## Estado del Proyecto

Estado actual: en desarrollo activo.

La base del proyecto ya incluye arquitectura por features, autenticación, productos, alertas, dashboard responsive y configuración de tema. Los siguientes pasos naturales serían movimientos de inventario, reportes y roles/permisos.

## Autor

**Matías Concha**

- GitHub: [matiasConcha1](https://github.com/matiasConcha1)
- Correo: [matiasconcha.2025@gmail.com](mailto:matiasconcha.2025@gmail.com)
