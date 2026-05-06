import { initializeApp } from "firebase-admin/app";
import {
  FieldValue,
  Firestore,
  Timestamp,
  getFirestore,
} from "firebase-admin/firestore";
import { Message, getMessaging } from "firebase-admin/messaging";
import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

const REGION = "us-central1";
const TIME_ZONE = "America/Santiago";
const SCHEDULE = "0 9 * * *";

const ALERT_STATUS_ACTIVE = "active";
const ALERT_TYPE_LOW_STOCK = "low_stock";
const ALERT_TYPE_EXPIRING_SOON = "expiring_soon";
const ALERT_TYPE_EXPIRED = "expired";

type AlertType =
  | typeof ALERT_TYPE_LOW_STOCK
  | typeof ALERT_TYPE_EXPIRING_SOON
  | typeof ALERT_TYPE_EXPIRED;

type AlertSeverity = "low" | "medium" | "high";

interface ProductRecord {
  id: string;
  name: string;
  stock: number;
  expirationDate: Date | null;
  isDeleted: boolean;
}

interface AlertEvaluation {
  type: AlertType;
  severity: AlertSeverity;
  active: boolean;
  message: string;
  pushBody: string;
}

export const dailyInventoryAlerts = onSchedule(
  {
    schedule: SCHEDULE,
    timeZone: TIME_ZONE,
    region: REGION,
    retryCount: 0,
  },
  async () => {
    logger.info("dailyInventoryAlerts started");

    const usersSnapshot = await db.collection("users").get();

    const settingsSnapshot = await db
      .collection("app_config")
      .doc("settings")
      .get();
    const autoArchiveExpiredProducts =
      (settingsSnapshot.data()?.autoArchiveExpiredProducts ?? false) === true;

    for (const userDoc of usersSnapshot.docs) {
      await processUserInventoryAlerts(
        db,
        userDoc.id,
        userDoc.data(),
        autoArchiveExpiredProducts,
      );
    }

    logger.info("dailyInventoryAlerts finished", {
      usersProcessed: usersSnapshot.size,
    });
  },
);

async function processUserInventoryAlerts(
  firestore: Firestore,
  userId: string,
  userData: FirebaseFirestore.DocumentData,
  autoArchiveExpiredProducts: boolean,
): Promise<void> {
  const fcmToken = normalizeToken(userData.fcmToken);

  logger.info("Processing user alerts", {
    userId,
    hasToken: Boolean(fcmToken),
  });

  const productsSnapshot = await firestore
    .collection("users")
    .doc(userId)
    .collection("products")
    .get();

  for (const productDoc of productsSnapshot.docs) {
    const product = normalizeProduct(productDoc.id, productDoc.data());
    if (product.isDeleted) {
      continue;
    }

    if (autoArchiveExpiredProducts && isExpiredProduct(product)) {
      await archiveExpiredProduct(firestore, userId, product);
      continue;
    }

    const evaluations = evaluateProductAlerts(product);

    for (const evaluation of evaluations) {
      const alertId = `${product.id}_${evaluation.type}`;
      const alertRef = firestore
        .collection("users")
        .doc(userId)
        .collection("alerts")
        .doc(alertId);

      const existingAlert = await alertRef.get();
      const existingData = existingAlert.data() ?? {};
      const alreadyActive =
        existingAlert.exists && existingData.status === ALERT_STATUS_ACTIVE;

      if (evaluation.active) {
        await alertRef.set(
          {
            productId: product.id,
            productName: product.name,
            type: evaluation.type,
            severity: evaluation.severity,
            message: evaluation.message,
            status: ALERT_STATUS_ACTIVE,
            createdAt: existingAlert.exists
              ? existingData.createdAt ?? FieldValue.serverTimestamp()
              : FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );

        if (!alreadyActive && fcmToken) {
          await sendPushNotification({
            token: fcmToken,
            type: evaluation.type,
            body: evaluation.pushBody,
            userId,
            productId: product.id,
          });
        }
      }
    }
  }
}

function normalizeProduct(
  productId: string,
  data: FirebaseFirestore.DocumentData,
): ProductRecord {
  return {
    id: typeof data.id === "string" && data.id.trim() ? data.id.trim() : productId,
    name:
      typeof data.name === "string" && data.name.trim()
        ? data.name.trim()
        : "Producto sin nombre",
    stock: toInt(data.totalStock ?? data.stock),
    expirationDate: toDate(data.expirationDate ?? data.expiryDate),
    isDeleted: data.isDeleted === true,
  };
}

function evaluateProductAlerts(product: ProductRecord): AlertEvaluation[] {
  const today = startOfDay(new Date());
  const nextSevenDays = addDays(today, 7);
  const expirationDate = product.expirationDate
    ? startOfDay(product.expirationDate)
    : null;

  return [
    {
      type: ALERT_TYPE_LOW_STOCK,
      severity: "high",
      active: product.stock <= 5,
      message: `El producto ${product.name} tiene stock bajo.`,
      pushBody: `Producto con stock bajo: ${product.name}`,
    },
    {
      type: ALERT_TYPE_EXPIRED,
      severity: "high",
      active: Boolean(expirationDate && expirationDate < today),
      message: `El producto ${product.name} ya está vencido.`,
      pushBody: `Producto vencido: ${product.name}`,
    },
    {
      type: ALERT_TYPE_EXPIRING_SOON,
      severity: "medium",
      active: Boolean(
        expirationDate &&
          expirationDate >= today &&
          expirationDate <= nextSevenDays,
      ),
      message: `El producto ${product.name} vence pronto.`,
      pushBody: `Producto próximo a vencer: ${product.name}`,
    },
  ];
}

async function sendPushNotification({
  token,
  type,
  body,
  userId,
  productId,
}: {
  token: string;
  type: AlertType;
  body: string;
  userId: string;
  productId: string;
}): Promise<void> {
  const message: Message = {
    token,
    notification: {
      title: "StockMind Alertas",
      body,
    },
    data: {
      alertType: type,
      userId,
      productId,
    },
    webpush: {
      notification: {
        title: "StockMind Alertas",
        body,
        icon: "/icons/Icon-192.png",
      },
    },
  };

  try {
    await messaging.send(message);
  } catch (error) {
    logger.error("FCM send failed", {
      userId,
      productId,
      alertType: type,
      error: error instanceof Error ? error.message : String(error),
    });
  }
}

async function archiveExpiredProduct(
  firestore: Firestore,
  userId: string,
  product: ProductRecord,
): Promise<void> {
  const productRef = firestore
    .collection("users")
    .doc(userId)
    .collection("products")
    .doc(product.id);

  await productRef.set(
    {
      isDeleted: true,
      deletedAt: FieldValue.serverTimestamp(),
      deletedBy: "system",
      deleteReason: "expired",
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  const alertsSnapshot = await firestore
    .collection("users")
    .doc(userId)
    .collection("alerts")
    .where("productId", "==", product.id)
    .where("status", "==", ALERT_STATUS_ACTIVE)
    .get();

  if (!alertsSnapshot.empty) {
    const batch = firestore.batch();
    for (const alertDoc of alertsSnapshot.docs) {
      batch.set(
        alertDoc.ref,
        {
          status: "resolved",
          resolvedAt: FieldValue.serverTimestamp(),
          resolvedBy: "system",
          updatedAt: FieldValue.serverTimestamp(),
          isRead: true,
        },
        { merge: true },
      );
    }
    await batch.commit();
  }

  await firestore
    .collection("users")
    .doc(userId)
    .collection("activity_logs")
    .add({
      action: "auto_archive_expired_product",
      entityType: "product",
      entityId: product.id,
      entityName: product.name,
      description: `El producto ${product.name} fue archivado automáticamente porque estaba vencido.`,
      createdAt: FieldValue.serverTimestamp(),
    });
}

function isExpiredProduct(product: ProductRecord): boolean {
  const expirationDate = product.expirationDate
    ? startOfDay(product.expirationDate)
    : null;
  return Boolean(expirationDate && expirationDate < startOfDay(new Date()));
}

function normalizeToken(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }

  const trimmed = value.trim();
  return trimmed ? trimmed : null;
}

function toInt(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) {
    return Math.trunc(value);
  }

  if (typeof value === "string") {
    const parsed = Number.parseInt(value, 10);
    return Number.isFinite(parsed) ? parsed : 0;
  }

  return 0;
}

function toDate(value: unknown): Date | null {
  if (!value) {
    return null;
  }

  if (value instanceof Timestamp) {
    return value.toDate();
  }

  if (value instanceof Date) {
    return value;
  }

  return null;
}

function startOfDay(date: Date): Date {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

function addDays(date: Date, days: number): Date {
  const next = new Date(date);
  next.setDate(next.getDate() + days);
  return next;
}
