"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.dailyInventoryAlerts = void 0;
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const messaging_1 = require("firebase-admin/messaging");
const logger = __importStar(require("firebase-functions/logger"));
const scheduler_1 = require("firebase-functions/v2/scheduler");
(0, app_1.initializeApp)();
const db = (0, firestore_1.getFirestore)();
const messaging = (0, messaging_1.getMessaging)();
const REGION = "us-central1";
const TIME_ZONE = "America/Santiago";
const SCHEDULE = "0 9 * * *";
const ALERT_STATUS_ACTIVE = "active";
const ALERT_TYPE_LOW_STOCK = "low_stock";
const ALERT_TYPE_EXPIRING_SOON = "expiring_soon";
const ALERT_TYPE_EXPIRED = "expired";
exports.dailyInventoryAlerts = (0, scheduler_1.onSchedule)({
    schedule: SCHEDULE,
    timeZone: TIME_ZONE,
    region: REGION,
    retryCount: 0,
}, async () => {
    logger.info("dailyInventoryAlerts started");
    const usersSnapshot = await db
        .collection("users")
        .where("notificationsEnabled", "==", true)
        .get();
    for (const userDoc of usersSnapshot.docs) {
        await processUserInventoryAlerts(db, userDoc.id, userDoc.data());
    }
    logger.info("dailyInventoryAlerts finished", {
        usersProcessed: usersSnapshot.size,
    });
});
async function processUserInventoryAlerts(firestore, userId, userData) {
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
            const alreadyActive = existingAlert.exists && existingData.status === ALERT_STATUS_ACTIVE;
            if (evaluation.active) {
                await alertRef.set({
                    productId: product.id,
                    productName: product.name,
                    type: evaluation.type,
                    severity: evaluation.severity,
                    message: evaluation.message,
                    status: ALERT_STATUS_ACTIVE,
                    createdAt: existingAlert.exists
                        ? existingData.createdAt ?? firestore_1.FieldValue.serverTimestamp()
                        : firestore_1.FieldValue.serverTimestamp(),
                    updatedAt: firestore_1.FieldValue.serverTimestamp(),
                }, { merge: true });
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
function normalizeProduct(productId, data) {
    return {
        id: typeof data.id === "string" && data.id.trim() ? data.id.trim() : productId,
        name: typeof data.name === "string" && data.name.trim()
            ? data.name.trim()
            : "Producto sin nombre",
        stock: toInt(data.totalStock ?? data.stock),
        expirationDate: toDate(data.expirationDate ?? data.expiryDate),
    };
}
function evaluateProductAlerts(product) {
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
            active: Boolean(expirationDate &&
                expirationDate >= today &&
                expirationDate <= nextSevenDays),
            message: `El producto ${product.name} vence pronto.`,
            pushBody: `Producto próximo a vencer: ${product.name}`,
        },
    ];
}
async function sendPushNotification({ token, type, body, userId, productId, }) {
    const message = {
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
    }
    catch (error) {
        logger.error("FCM send failed", {
            userId,
            productId,
            alertType: type,
            error: error instanceof Error ? error.message : String(error),
        });
    }
}
function normalizeToken(value) {
    if (typeof value !== "string") {
        return null;
    }
    const trimmed = value.trim();
    return trimmed ? trimmed : null;
}
function toInt(value) {
    if (typeof value === "number" && Number.isFinite(value)) {
        return Math.trunc(value);
    }
    if (typeof value === "string") {
        const parsed = Number.parseInt(value, 10);
        return Number.isFinite(parsed) ? parsed : 0;
    }
    return 0;
}
function toDate(value) {
    if (!value) {
        return null;
    }
    if (value instanceof firestore_1.Timestamp) {
        return value.toDate();
    }
    if (value instanceof Date) {
        return value;
    }
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
