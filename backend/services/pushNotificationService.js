const firebaseAdmin = require("./firebaseAdmin");
const fcmTokenModel = require("../model/fcmTokenModel");

function cleanDataValue(value) {
  if (value === undefined || value === null) return "";

  return value.toString();
}

async function sendPushToTokens({
  tokens = [],
  title,
  body,
  type = "general",
  referenceType = null,
  referenceId = null,
}) {
  if (!firebaseAdmin) {
    console.warn("Push skipped: Firebase Admin is not initialized.");
    return {
      success: false,
      skipped: true,
      reason: "Firebase Admin is not initialized",
    };
  }

  const cleanTokens = [...new Set(tokens.filter(Boolean))];

  if (cleanTokens.length === 0) {
    return {
      success: true,
      sent: 0,
      failed: 0,
      message: "No FCM tokens found",
    };
  }

  const message = {
    notification: {
      title: title || "Lensia",
      body: body || "",
    },
    data: {
      type: cleanDataValue(type),
      reference_type: cleanDataValue(referenceType),
      reference_id: cleanDataValue(referenceId),
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
    android: {
      priority: "high",
      notification: {
        channelId: "lensia_notifications",
        sound: "default",
        priority: "high",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
    tokens: cleanTokens,
  };

  const response = await firebaseAdmin.messaging().sendEachForMulticast(message);

  const invalidTokens = [];

  response.responses.forEach((result, index) => {
    if (!result.success) {
      const code = result.error?.code || "";

      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token" ||
        code === "messaging/invalid-argument"
      ) {
        invalidTokens.push(cleanTokens[index]);
      }

      console.log("Push token failed:", code, result.error?.message);
    }
  });

  if (invalidTokens.length > 0) {
    await Promise.all(
      invalidTokens.map((token) => fcmTokenModel.deleteToken(token))
    );
  }

  return {
    success: true,
    sent: response.successCount,
    failed: response.failureCount,
    invalid_tokens_deleted: invalidTokens.length,
  };
}

async function sendPushToUser({
  userId,
  title,
  body,
  type = "general",
  referenceType = null,
  referenceId = null,
}) {
  if (!userId) {
    return {
      success: false,
      message: "Missing user id",
    };
  }

  const tokens = await fcmTokenModel.getTokensByUser(userId);

  return sendPushToTokens({
    tokens,
    title,
    body,
    type,
    referenceType,
    referenceId,
  });
}

module.exports = {
  sendPushToUser,
  sendPushToTokens,
};