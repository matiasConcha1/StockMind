# StockMind

StockMind es una aplicación de gestión de inventario desarrollada en **Flutter**, pensada para funcionar correctamente tanto en **Web/Desktop** como en **Mobile**.

El proyecto incluye una interfaz moderna, responsive y profesional, con dashboard, gestión de productos, alertas de stock y una vista previa animada tipo demo/GIF.

---

## Características

- Login y registro de usuarios
- Dashboard con métricas principales
- Gestión de productos e inventario
- Alertas de bajo stock
- Visualización de gráficos
- Pantalla de configuración
- Tema claro/oscuro
- Diseño responsive para Web y Mobile
- Animación tipo demo/GIF creada con widgets de Flutter

---

## Vista previa animada

La página principal incluye una animación tipo **demo interactiva**, creada sin usar archivos GIF externos.

Esta animación simula el funcionamiento de la aplicación mostrando:

- Métricas del dashboard
- Gráficos de stock
- Tabla de productos
- Alertas de bajo stock
- Vista Web/Desktop y Mobile

---

## Diseño Responsive

### Web / Desktop

- Layout tipo dashboard
- Sidebar lateral
- Header superior
- Contenido distribuido en tarjetas
- Tablas y gráficos adaptados al ancho de pantalla

### Mobile

- Navegación adaptada
- Contenido en una sola columna
- Componentes ajustados al tamaño de pantalla
- Diseño sin errores de overflow

---

## Tecnologías utilizadas

- Flutter
- Dart
- Firebase
- Provider
- Material Design

---

## Estructura del proyecto

```txt
lib/
├── core/
│   ├── router/
│   └── theme/
├── features/
│   ├── app/
│   ├── auth/
│   ├── dashboard/
│   └── shell/
├── models/
├── providers/
├── services/
└── widgets/
