# StockMind Notifications

Implementación base para automatizar alertas y push con Cloud Functions.

## Función implementada

`dailyInventoryAlerts`

- corre todos los días a las `09:00`
- timezone: `America/Santiago`
- recorre `users/{uid}/products`
- detecta:
  - `low_stock`
  - `expiring_soon`
  - `expired`
- crea o actualiza `users/{uid}/alerts`
- resuelve alertas cuando el problema deja de existir
- envía FCM si el usuario tiene:
  - `notificationsEnabled == true`
  - `fcmToken` válido

## Tipos de alerta

- `low_stock`
  - `totalStock <= 5`
- `expiring_soon`
  - `expirationDate` dentro de 7 días
- `expired`
  - `expirationDate` menor a hoy

## Envío push

Título:

- `StockMind Alertas`

Cuerpo:

- `Producto con stock bajo: Nombre`
- `Producto próximo a vencer: Nombre`
- `Producto vencido: Nombre`

La función solo envía push cuando una alerta pasa a `active` por primera vez o se reactiva.

## Archivos

- `functions/index.js`
- `functions/package.json`

## Deploy

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

## Prueba recomendada

1. Asegura que un usuario tenga:
   - `notificationsEnabled: true`
   - `fcmToken`
2. Crea o edita productos en `users/{uid}/products` con:
   - `totalStock <= 5`
   - `expirationDate` vencida
   - `expirationDate` dentro de 7 días
3. Ejecuta la función desde el emulador o despliega y espera el scheduler.
4. Verifica:
   - `users/{uid}/alerts`
   - notificación push

## Notas

- No ejecutar revisiones programadas desde Flutter cliente.
- Mantener la lógica centralizada en backend evita depender de que la app esté abierta.
