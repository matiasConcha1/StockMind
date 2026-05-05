#  StockMind

<p align="center">
  <img src="assets/images/logo_icon.png" width="120" alt="StockMind Logo"/>
</p>

<p align="center">
  Sistema moderno de gestión de inventario para negocios que necesitan controlar su stock de forma simple, rápida y visual.
</p>

<p align="center">
  <a href="https://ejemplofirebase-38f98.web.app">🌐 Ver demo en vivo</a>
</p>

---

## Descripción

**StockMind** es una plataforma tipo SaaS desarrollada con **Flutter Web + Firebase**, pensada para reemplazar planillas, cuadernos o sistemas complejos de inventario.

Permite gestionar productos, ubicaciones físicas, imágenes, alertas de stock bajo y métricas operativas en tiempo real desde una interfaz moderna y responsive.

---

## Características principales

- Autenticación con Email y Google
- Gestión completa de productos
- Control de ubicaciones físicas
- Subida de imágenes para productos y ubicaciones
- Alertas automáticas de stock bajo
- Dashboard con métricas en tiempo real
- Exportación a Excel y PDF
- Modo oscuro / claro
- PWA instalable
- Deploy en Firebase Hosting

---

##  Capturas de pantalla

### Login

![Login](assets/screenshots/login.png)

---

### Registro

![Registro](assets/screenshots/register.png)

---

### Dashboard

![Dashboard](assets/screenshots/dashboard.png)

---

### Productos

![Productos](assets/screenshots/products.png)

---

### Nuevo producto

![Nuevo producto](assets/screenshots/products2.png)

---

### Alertas

![Alertas](assets/screenshots/alerts.png)

---

### Ubicaciones

![Ubicaciones](assets/screenshots/locations.png)

---

### Nueva ubicación

![Nueva ubicación](assets/screenshots/locations2.png)

---

### Configuración

![Configuración](assets/screenshots/settings.png)

---

### Perfil y seguridad

![Perfil y configuración](assets/screenshots/settings2.png)

---

##  Tecnologías utilizadas

| Tecnología | Uso |
|---|---|
| Flutter Web | Frontend multiplataforma |
| Dart | Lenguaje principal |
| Firebase Auth | Autenticación |
| Cloud Firestore | Base de datos en tiempo real |
| Firebase Storage | Almacenamiento de imágenes |
| Firebase Hosting | Deploy web |
| Provider | Gestión de estado |
| GoRouter | Navegación |
| Google Fonts | Tipografía |
| Material Icons | Iconografía |

---

##  Estructura del proyecto

```bash
lib/
├── app/
├── core/
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── products/
│   ├── locations/
│   ├── alerts/
│   └── settings/
├── services/
├── firebase_options.dart
└── main.dart
