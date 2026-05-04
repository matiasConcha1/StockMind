<h1 align="center">StockMind</h1>

<p align="center">
  <img src="assets/screenshots/cover-placeholder.png" alt="StockMind Cover" width="100%" />
</p>

<p align="center">
  Sistema de gestión de inventario construido con <strong>Flutter + Firebase</strong>, diseñado con enfoque SaaS para ofrecer una experiencia moderna, responsive y profesional.
</p>

<p align="center">
  <a href="https://flutter.dev/">
    <img src="https://img.shields.io/badge/Flutter-3.41+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  </a>
  <a href="https://dart.dev/">
    <img src="https://img.shields.io/badge/Dart-3.11+-0175C2?logo=dart&logoColor=white" alt="Dart" />
  </a>
  <a href="https://firebase.google.com/">
    <img src="https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase&logoColor=black" alt="Firebase" />
  </a>
  <a href="https://pub.dev/packages/provider">
    <img src="https://img.shields.io/badge/State%20Management-Provider-7B61FF" alt="Provider" />
  </a>
  <a href="https://pub.dev/packages/go_router">
    <img src="https://img.shields.io/badge/Routing-go__router-5E5CE6" alt="GoRouter" />
  </a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Status-En%20desarrollo-22C55E" alt="Estado del proyecto" />
  <img src="https://img.shields.io/badge/UI-Responsive-0EA5E9" alt="Responsive UI" />
  <img src="https://img.shields.io/badge/Theme-Light%20%26%20Dark-111827" alt="Theme support" />
</p>

---

## Descripción

**StockMind** es una aplicación de gestión de inventario enfocada en negocios que necesitan controlar productos, monitorear stock, visualizar métricas operativas y responder rápidamente a alertas de reposición.

El proyecto fue diseñado como un dashboard moderno tipo SaaS, con una arquitectura organizada, autenticación integrada con Firebase y experiencia adaptativa para **web, tablet y móvil**.

## Vista General

- Gestión centralizada de productos e inventario.
- Dashboard con métricas y gráficos accionables.
- Alertas automáticas de bajo stock.
- Login con Firebase Auth y persistencia de sesión.
- Diseño limpio y profesional con modo claro/oscuro.
- Base sólida para evolucionar a producto real o de portafolio.

## Funcionalidades Principales

### Dashboard Administrativo

- Métricas clave del inventario.
- Indicadores de stock total y productos críticos.
- Visualización de datos con `fl_chart`.
- Resumen visual del estado operativo.

### Gestión de Productos

- Crear productos.
- Editar productos.
- Eliminar productos.
- Buscar por nombre, categoría o SKU.
- Filtrar por categoría y estado de stock.

### Alertas Inteligentes

- Detección automática de bajo stock.
- Vista dedicada para productos críticos.
- Preparado para futuras notificaciones o automatizaciones.

### Autenticación

- Inicio de sesión con email y contraseña.
- Registro de nuevos usuarios.
- Recuperación de contraseña.
- Google Sign-In.
- Sesión persistente mediante Firebase Auth.

### Experiencia de Usuario

- Diseño responsive.
- Sidebar en escritorio.
- Navegación adaptada en móvil.
- Modo claro y oscuro persistente.
- Transiciones suaves entre pantallas.

## Tecnologías Usadas

| Tecnología | Uso |
|---|---|
| Flutter | Desarrollo multiplataforma |
| Dart | Lenguaje principal |
| Firebase Core | Inicialización de Firebase |
| Firebase Auth | Autenticación |
| Cloud Firestore | Base de datos |
| Provider | Manejo de estado |
| GoRouter | Navegación declarativa |
| Google Fonts | Tipografía |
| FL Chart | Gráficos |
| Shared Preferences | Persistencia de preferencias |

## Estructura del Proyecto

```text
lib/
  core/
    router/
    theme/
  features/
    app/
    auth/
      presentation/
        screens/
        widgets/
    dashboard/
      presentation/
        screens/
        widgets/
    shell/
      presentation/
  models/
  providers/
  services/
    auth/
    products/
    stock/
test/
assets/
  screenshots/
```

## Capturas

Las siguientes imágenes son placeholders. Reemplázalas por capturas reales de la aplicación dentro de `assets/screenshots/`.

### Login

![Login](assets/screenshots/login-placeholder.png)

### Dashboard

![Dashboard](assets/screenshots/dashboard-placeholder.png)

### Productos

![Productos](assets/screenshots/products-placeholder.png)

### Alertas

![Alertas](assets/screenshots/alerts-placeholder.png)

## Instalación Paso a Paso

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

Ejecuta el asistente oficial de FlutterFire:

```bash
flutterfire configure
```

Después, en Firebase Console habilita:

- `Authentication > Email/Password`
- `Authentication > Google`
- `Firestore Database`

Configuración recomendada adicional:

- Android: registra `SHA-1` y `SHA-256`.
- Web: agrega tu dominio a los dominios autorizados.

### 4. Ejecutar la app

```bash
flutter run -d chrome
```

También puedes ejecutarla en Android, iOS, Windows o macOS según tu entorno.

## Modelo de Datos Sugerido

```text
users/{uid}/products/{productId}
```

Campos principales por producto:

- `name`
- `category`
- `sku`
- `price`
- `stock`
- `minimumStock`
- `createdAt`
- `updatedAt`

## Estado del Proyecto

**Estado actual:** en desarrollo activo.

StockMind ya cuenta con:

- Base visual moderna tipo SaaS.
- Autenticación con Firebase.
- Dashboard responsive.
- CRUD de productos.
- Alertas de bajo stock.
- Soporte de tema claro y oscuro.

Próximas mejoras posibles:

- Movimientos de inventario.
- Exportación CSV/PDF.
- Roles y permisos.
- Historial de actividad.
- Reportes avanzados.

## Autor

**Matías Concha**

- GitHub: [matiasConcha1](https://github.com/matiasConcha1)
- Correo: [matiasconcha.2025@gmail.com](mailto:matiasconcha.2025@gmail.com)

## Contacto

Si quieres colaborar, reportar una mejora o usar este proyecto como base, puedes contactarme directamente desde GitHub o por correo.

---

<p align="center">
  Hecho con Flutter, Firebase y enfoque de producto real.
</p>
