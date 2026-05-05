# StockMind

<p align="center">
  <img src="assets/screenshots/banner.gif" alt="StockMind Banner" width="100%">
</p>

<p align="center">
  <strong>Plataforma moderna de gestión de inventario</strong><br>
  Aplicación multiplataforma desarrollada con Flutter, Firebase y arquitectura modular escalable.
</p>

---

## Descripción

**StockMind** es una aplicación administrativa tipo dashboard diseñada para gestionar inventario, productos, categorías, ubicaciones y alertas de stock de forma eficiente.

El proyecto fue desarrollado con un enfoque profesional, priorizando una arquitectura limpia, separación de responsabilidades, escalabilidad y una experiencia de usuario moderna tanto en escritorio como en dispositivos móviles.

---

## Vista previa

### Login y autenticación

<p align="center">
  <img src="assets/screenshots/login.gif" alt="Login StockMind" width="900">
</p>

### Dashboard principal

<p align="center">
  <img src="assets/screenshots/dashboard.gif" alt="Dashboard StockMind" width="900">
</p>

### Gestión de productos

<p align="center">
  <img src="assets/screenshots/products.gif" alt="Productos StockMind" width="900">
</p>

### Modo oscuro

<p align="center">
  <img src="assets/screenshots/dark-mode.gif" alt="Modo oscuro StockMind" width="900">
</p>

---

## Funcionalidades principales

- Autenticación con Firebase
- Inicio de sesión con Google
- Dashboard con métricas generales del inventario
- Gestión completa de productos
- Registro, edición y eliminación de productos
- Gestión de ubicaciones o sectores
- Subida de imágenes desde galería o archivos
- Alertas automáticas de stock bajo
- Búsqueda y filtrado dinámico
- Interfaz responsive para web, tablet y móvil
- Modo claro y oscuro
- Navegación fluida tipo aplicación SaaS

---

## Arquitectura del proyecto

StockMind utiliza una arquitectura modular basada en funcionalidades, separando la lógica de negocio, la interfaz, los servicios externos y la gestión de estado.

```bash
lib/
│
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
