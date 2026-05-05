# StockMind

<p align="center">
  <img src="assets/screenshots/banner.gif" alt="StockMind Banner" width="100%">
</p>

<p align="center">
  <strong>Plataforma moderna de gestión de inventario</strong><br>
  Aplicación multiplataforma desarrollada con Flutter, Firebase y arquitectura modular escalable.
</p>

<p align="center">
  <a href="#descripción">Descripción</a> ·
  <a href="#vista-previa">Vista previa</a> ·
  <a href="#arquitectura-del-proyecto">Arquitectura</a> ·
  <a href="#stack-tecnológico">Stack</a> ·
  <a href="#instalación">Instalación</a>
</p>

---

## Descripción

**StockMind** es una aplicación administrativa tipo dashboard diseñada para gestionar inventario, productos, ubicaciones y alertas de stock de forma eficiente.

El proyecto fue desarrollado con un enfoque profesional, priorizando una arquitectura modular, separación de responsabilidades, escalabilidad y una experiencia de usuario moderna en escritorio, web, tablet y dispositivos móviles.

---

## Vista previa

### Login y autenticación

<p align="center">
  <img src="assets/screenshots/login.gif" width="900">
</p>

### Dashboard principal

<p align="center">
  <img src="assets/screenshots/dashboard.gif" width="900">
</p>

### Gestión de productos

<p align="center">
  <img src="assets/screenshots/products.gif" width="900">
</p>

### Modo oscuro

<p align="center">
  <img src="assets/screenshots/dark-mode.gif" width="900">
</p>

---

## Funcionalidades principales

* Autenticación con Firebase
* Inicio de sesión con Google
* Dashboard con métricas en tiempo real
* Gestión completa de productos (CRUD)
* Subida de imágenes (móvil y escritorio)
* Alertas automáticas de stock bajo
* Búsqueda y filtrado dinámico
* Modo claro / oscuro
* Diseño responsive tipo dashboard

---

## Arquitectura del proyecto

StockMind utiliza una arquitectura modular basada en funcionalidades, separando la lógica de negocio, la interfaz, los servicios externos y la gestión de estado.

```
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   └── utils/
│
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── products/
│   └── alerts/
│
├── models/
├── providers/
├── services/
├── router/
└── main.dart
```

---

## Detalle de arquitectura

### core/

Configuración global reutilizable:

* constants → variables globales
* theme → modo claro/oscuro
* utils → helpers

---

### features/

Módulos principales:

* auth → autenticación
* dashboard → métricas
* products → inventario
* alerts → alertas

Cada módulo es independiente y escalable.

---

### models/

Estructura de datos:

* product_model.dart
* user_model.dart
* location_model.dart

---

### providers/

Gestión de estado:

* auth_provider.dart
* product_provider.dart
* dashboard_provider.dart
* theme_provider.dart

---

### services/

Comunicación con Firebase:

* auth_service.dart
* firestore_service.dart
* storage_service.dart
* google_auth_service.dart

---

### router/

Navegación centralizada:

* app_router.dart

---

## Flujo de la aplicación

```
Usuario → UI → Provider → Services → Firebase
```

---

## Stack tecnológico

* Flutter
* Dart
* Firebase Auth
* Google Sign-In
* Cloud Firestore
* Firebase Storage
* Provider
* fl_chart

---

## Instalación

```
git clone https://github.com/matiasConcha1/stockmind.git
cd stockmind
flutter pub get
flutter run
```

---

## Configuración Firebase

Agregar:

```
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

Activar en Firebase:

* Authentication
* Google Sign-In
* Firestore
* Storage

---

## Roadmap

* Roles (admin / usuario)
* Reportes (PDF / Excel)
* Notificaciones
* Código de barras
* Historial de inventario
* Multiempresa

---

## Autor

**Matías Concha**
Ingeniero en Informática

GitHub: https://github.com/matiasConcha1
Email: [matiasconcha.2025@gmail.com](mailto:matiasconcha.2025@gmail.com)

---

<p align="center">
  <sub>StockMind — Gestión inteligente de inventario</sub>
</p>
