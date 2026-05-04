#  StockMind

<p align="center">
  <img src="assets/screenshots/banner.gif" alt="StockMind Banner" width="100%">
</p>

<p align="center">
  Sistema moderno de gestión de inventario desarrollado en Flutter + Firebase.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white">
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white">
  <img src="https://img.shields.io/badge/Responsive-Design-blueviolet?style=for-the-badge">
</p>

---

##  Descripción

**StockMind** es una aplicación administrativa tipo dashboard diseñada para gestionar productos, inventario y alertas de stock bajo de manera simple, rápida y profesional.

El sistema está pensado para negocios que necesitan controlar su inventario desde una interfaz moderna, responsive y fácil de usar.

---

##  Vista previa

###  Login profesional

<p align="center">
  <img src="assets/screenshots/login.gif" alt="Login StockMind" width="800">
</p>

---

###  Dashboard principal

<p align="center">
  <img src="assets/screenshots/dashboard.gif" alt="Dashboard StockMind" width="800">
</p>

---

###  Gestión de productos

<p align="center">
  <img src="assets/screenshots/products.gif" alt="Productos StockMind" width="800">
</p>

---

###  Modo oscuro

<p align="center">
  <img src="assets/screenshots/dark-mode.gif" alt="Modo oscuro StockMind" width="800">
</p>

---

##  Funcionalidades principales

-  Autenticación con Firebase
-  Dashboard con métricas de inventario
-  Gestión de productos
-  Crear, editar y eliminar productos
-  Alertas automáticas de stock bajo
-  Búsqueda y filtrado de productos
-  Modo claro y oscuro
-  Diseño responsive para web, tablet y móvil
-  Integración con Firestore
-  Interfaz moderna tipo SaaS

---

##  Tecnologías utilizadas

| Tecnología | Uso |
|----------|-----|
| Flutter | Desarrollo frontend multiplataforma |
| Dart | Lenguaje principal |
| Firebase Auth | Autenticación de usuarios |
| Cloud Firestore | Base de datos |
| Provider | Gestión de estado |
| fl_chart | Gráficos del dashboard |
| Google Fonts | Tipografía |
| Flutter SVG | Íconos e ilustraciones |

---

##  Estructura del proyecto

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