/* eslint-disable require-jsdoc, max-len */
const admin = require("firebase-admin");
const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");

admin.initializeApp();

function toStringMap(data = {}) {
  const result = {};
  Object.entries(data).forEach(([key, value]) => {
    if (value === undefined || value === null) {
      return;
    }

    result[key] = typeof value === "string" ? value : String(value);
  });

  return result;
}

function buildMessageFromRequest(requestData = {}) {
  const topic = requestData.topic || requestData.target;
  const notification = requestData.notification || {};
  const data = requestData.data || {};

  if (!topic) {
    throw new Error("Missing topic for notification request");
  }

  const title = notification.title || requestData.title;
  const body = notification.body || requestData.body;

  if (!title || !body) {
    throw new Error("Missing notification title or body");
  }

  return {
    topic,
    notification: {
      title,
      body,
    },
    data: toStringMap({
      ...data,
      type: data.type || requestData.type || "system",
      route: data.route || requestData.route,
      productId: data.productId || requestData.productId,
      productName: data.productName || requestData.productName,
      retailer: data.retailer || requestData.retailer,
      oldPrice: data.oldPrice || requestData.oldPrice,
      newPrice: data.newPrice || requestData.newPrice,
      budgetId: data.budgetId || requestData.budgetId,
      spent: data.spent || requestData.spent,
      limit: data.limit || requestData.limit,
      listId: data.listId || requestData.listId,
      listName: data.listName || requestData.listName,
    }),
  };
}

function applyCors(res) {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
}

async function markQueueStatus(ref, status, extra = {}) {
  await ref.set(
    {
      status,
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
      ...extra,
    },
    { merge: true }
  );
}

async function processNotificationRequest(requestData, queueRef = null) {
  const message = buildMessageFromRequest(requestData);
  const messageId = await admin.messaging().send(message);

  if (queueRef) {
    await markQueueStatus(queueRef, "sent", {
      messageId,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      errorMessage: admin.firestore.FieldValue.delete(),
    });
  }

  return {
    messageId,
    topic: message.topic,
    type: message.data.type,
  };
}

exports.sendNotification = onRequest(async (req, res) => {
  applyCors(res);

  if (req.method === "OPTIONS") {
    return res.status(204).send("");
  }

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Use POST only" });
  }

  try {
    const requestData = typeof req.body === "string" ? JSON.parse(req.body) : (req.body || {});
    const result = await processNotificationRequest(requestData);

    return res.json({ ok: true, ...result });
  } catch (error) {
    logger.error("Failed to send notification request", { error: error.message });
    return res.status(400).json({ ok: false, error: error.message });
  }
});

exports.processNotificationRequest = onDocumentCreated(
  "notification_requests/{requestId}",
  async event => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }

    const requestId = event.params.requestId;
    const ref = snapshot.ref;
    const requestData = snapshot.data() || {};

    try {
      if (requestData.status === "sent") {
        logger.info("Skipping already sent notification request", { requestId });
        return;
      }

      const result = await processNotificationRequest(requestData, ref);

      logger.info("Notification sent successfully", {
        requestId,
        messageId: result.messageId,
        topic: result.topic,
        type: result.type,
      });
    } catch (error) {
      logger.error("Failed to process notification request", {
        requestId,
        error: error.message,
      });

      await markQueueStatus(ref, "failed", {
        errorMessage: error.message,
      });
    }
  }
);

exports.sendNotificationRequest = onDocumentCreated(
  "notification_queue/{requestId}",
  async event => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }

    const requestId = event.params.requestId;
    const ref = snapshot.ref;
    const requestData = snapshot.data() || {};

    try {
      const result = await processNotificationRequest(requestData, ref);

      logger.info("Notification sent from notification_queue", {
        requestId,
        messageId: result.messageId,
        topic: result.topic,
      });
    } catch (error) {
      logger.error("Failed to process notification_queue item", {
        requestId,
        error: error.message,
      });

      await markQueueStatus(ref, "failed", {
        errorMessage: error.message,
      });
    }
  }
);
