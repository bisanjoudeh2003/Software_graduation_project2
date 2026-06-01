const notificationModel = require("../model/notificationModel");
const fcmTokenModel = require("../model/fcmTokenModel");

// ── GET /api/notifications ────────────────────────────────────────
// جيب كل إشعارات المستخدم الحالي مع عدد الغير مقروءة

exports.getMyNotifications = async (req, res) => {
  try {
    const userId = req.user.id;

    const notifications = await notificationModel.getNotificationsByUser(userId);
    const unreadCount = await notificationModel.getUnreadCount(userId);

    res.json({
      success: true,
      notifications,
      unread_count: unreadCount,
    });
  } catch (err) {
    console.error("Get notifications error:", err);

    res.status(500).json({
      success: false,
      message: "Server error",
    });
  }
};

// ── POST /api/notifications/fcm-token ─────────────────────────────
// حفظ Firebase FCM token للمستخدم الحالي

exports.saveMyFcmToken = async (req, res) => {
  try {
    const userId = req.user.id;
    const { fcm_token, device_type } = req.body;

    if (!fcm_token || !fcm_token.toString().trim()) {
      return res.status(400).json({
        success: false,
        message: "FCM token is required",
      });
    }

    await fcmTokenModel.saveToken(
      userId,
      fcm_token.toString().trim(),
      device_type || "android"
    );

    res.json({
      success: true,
      message: "FCM token saved successfully",
    });
  } catch (err) {
    console.error("Save FCM token error:", err);

    res.status(500).json({
      success: false,
      message: "Failed to save FCM token",
      error: err.message,
    });
  }
};

// ── DELETE /api/notifications/fcm-token ───────────────────────────
// حذف token عند logout أو تبديل الجهاز

exports.deleteMyFcmToken = async (req, res) => {
  try {
    const userId = req.user.id;
    const { fcm_token } = req.body;

    if (!fcm_token || !fcm_token.toString().trim()) {
      return res.status(400).json({
        success: false,
        message: "FCM token is required",
      });
    }

    await fcmTokenModel.deleteUserToken(userId, fcm_token.toString().trim());

    res.json({
      success: true,
      message: "FCM token deleted successfully",
    });
  } catch (err) {
    console.error("Delete FCM token error:", err);

    res.status(500).json({
      success: false,
      message: "Failed to delete FCM token",
      error: err.message,
    });
  }
};

// ── PATCH /api/notifications/:id/read ────────────────────────────
// خلي إشعار واحد مقروء

exports.markAsRead = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const result = await notificationModel.markAsRead(id, userId);

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: "Notification not found",
      });
    }

    res.json({
      success: true,
      message: "Marked as read",
    });
  } catch (err) {
    console.error("Mark notification as read error:", err);

    res.status(500).json({
      success: false,
      message: "Server error",
    });
  }
};

// ── PATCH /api/notifications/read-all ────────────────────────────
// خلي كل الإشعارات مقروءة

exports.markAllAsRead = async (req, res) => {
  try {
    const userId = req.user.id;

    await notificationModel.markAllAsRead(userId);

    res.json({
      success: true,
      message: "All notifications marked as read",
    });
  } catch (err) {
    console.error("Mark all notifications as read error:", err);

    res.status(500).json({
      success: false,
      message: "Server error",
    });
  }
};