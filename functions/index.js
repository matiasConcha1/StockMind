const { onSchedule } = require('firebase-functions/v2/scheduler');
const logger = require('firebase-functions/logger');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

const ALERT_TYPES = {
  LOW_STOCK: 'low_stock',
  EXPIRING_SOON: 'expiring_soon',
  EXPIRED: 'expired',
};

exports.dailyInventoryAlerts = onSchedule(
  {
    schedule: '0 9 * * *',
    timeZone: 'America/Santiago',
    region: 'us-central1',
    retryCount: 0,
  },
  async () => {
    logger.info('dailyInventoryAlerts: started');

    const usersSnapshot = await db
      .collection('users')
      .where('notificationsEnabled', '==', true)
      .where('role', 'in', ['admin', 'editor'])
      .get();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const userData = userDoc.data() || {};
      const fcmToken =
        typeof userData.fcmToken === 'string' && userData.fcmToken.trim()
          ? userData.fcmToken.trim()
          : null;

      logger.info(`Processing user ${userId}`);

      const productsSnapshot = await db
        .collection('users')
        .doc(userId)
        .collection('products')
        .get();

      for (const productDoc of productsSnapshot.docs) {
        const product = normalizeProduct(productDoc);
        const evaluations = evaluateAlerts(product);

        for (const evaluation of evaluations) {
          const alertId = `${product.id}_${evaluation.type}`;
          const alertRef = db
            .collection('users')
            .doc(userId)
            .collection('alerts')
            .doc(alertId);

          const existingSnapshot = await alertRef.get();
          const existing = existingSnapshot.data() || {};
          const becameActive =
            evaluation.active &&
            (!existingSnapshot.exists || existing.status !== 'active');

          if (evaluation.active) {
            await alertRef.set(
              {
                id: alertId,
                productId: product.id,
                productName: product.name,
                type: evaluation.type,
                severity: evaluation.severity,
                title: evaluation.title,
                message: evaluation.message,
                currentStock: product.totalStock,
                minStock: product.minStock,
                status: 'active',
                isRead: false,
                expirationDate: product.expirationDate ?? null,
                expiryDate: product.expirationDate ?? null,
                createdAt: existingSnapshot.exists
                  ? existing.createdAt || FieldValue.serverTimestamp()
                  : FieldValue.serverTimestamp(),
                updatedAt: FieldValue.serverTimestamp(),
                resolvedAt: null,
                resolvedBy: null,
              },
              { merge: true }
            );

            if (becameActive && fcmToken) {
              await sendAlertNotification({
                token: fcmToken,
                body: evaluation.pushBody,
                userId,
                productId: product.id,
                alertType: evaluation.type,
              });
            }
          } else if (existingSnapshot.exists && existing.status === 'active') {
            await alertRef.set(
              {
                status: 'resolved',
                updatedAt: FieldValue.serverTimestamp(),
                resolvedAt: FieldValue.serverTimestamp(),
                resolvedBy: 'system',
              },
              { merge: true }
            );
          }
        }
      }
    }

    logger.info('dailyInventoryAlerts: finished');
  }
);

function normalizeProduct(doc) {
  const data = doc.data() || {};
  return {
    id: data.id || doc.id,
    name: data.name || 'Producto',
    totalStock: toInt(data.totalStock ?? data.stock),
    minStock: toInt(data.minStock),
    expirationDate: toDate(data.expirationDate) || toDate(data.expiryDate),
  };
}

function evaluateAlerts(product) {
  const today = startOfDay(new Date());
  const sevenDaysAhead = startOfDay(addDays(today, 7));
  const expirationDate = product.expirationDate
    ? startOfDay(product.expirationDate)
    : null;

  const lowStock = {
    type: ALERT_TYPES.LOW_STOCK,
    active: product.totalStock <= 5,
    severity: product.totalStock <= 0 ? 'high' : 'medium',
    title: product.totalStock <= 0 ? 'Producto con stock bajo' : 'Producto con stock bajo',
    message:
      product.totalStock <= 0
        ? 'Este producto no tiene unidades disponibles.'
        : 'Este producto tiene 5 unidades o menos.',
    pushBody:
      product.totalStock <= 0
        ? `Producto con stock bajo: ${product.name}`
        : `Producto con stock bajo: ${product.name}`,
  };

  const expired = {
    type: ALERT_TYPES.EXPIRED,
    active: Boolean(expirationDate && expirationDate < today),
    severity: 'high',
    title: 'Producto vencido',
    message: 'Este producto ya superó su fecha de vencimiento.',
    pushBody: `Producto vencido: ${product.name}`,
  };

  const expiringSoon = {
    type: ALERT_TYPES.EXPIRING_SOON,
    active: Boolean(
      expirationDate &&
        expirationDate >= today &&
        expirationDate <= sevenDaysAhead
    ),
    severity: 'medium',
    title: 'Producto próximo a vencer',
    message: 'Este producto vencerá dentro de los próximos 7 días.',
    pushBody: `Producto próximo a vencer: ${product.name}`,
  };

  return [lowStock, expired, expiringSoon];
}

async function sendAlertNotification({
  token,
  body,
  userId,
  productId,
  alertType,
}) {
  try {
    await messaging.send({
      token,
      notification: {
        title: 'StockMind Alertas',
        body,
      },
      data: {
        userId,
        productId,
        alertType,
      },
      webpush: {
        notification: {
          title: 'StockMind Alertas',
          body,
          icon: '/icons/Icon-192.png',
        },
      },
    });
  } catch (error) {
    logger.error('sendAlertNotification failed', {
      error: error instanceof Error ? error.message : String(error),
      userId,
      productId,
      alertType,
    });
  }
}

function toInt(value) {
  if (typeof value === 'number') {
    return Math.trunc(value);
  }
  return 0;
}

function toDate(value) {
  if (!value) return null;
  if (value instanceof Timestamp) return value.toDate();
  if (value instanceof Date) return value;
  return null;
}

function startOfDay(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

function addDays(date, days) {
  const next = new Date(date);
  next.setDate(next.getDate() + days);
  return next;
}
