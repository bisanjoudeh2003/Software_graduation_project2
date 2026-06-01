const db = require("../config/db");
const { sendPushToUser } = require("../services/pushNotificationService");

// ── Create new notification ──────────────────────────────────────

const createNotification = async (
  userId,
  title,
  body,
  type = "general",
  referenceType = null,
  referenceId = null
) => {
  if (!userId) return null;

  const [result] = await db.query(
    `
    INSERT INTO notifications 
      (user_id, title, body, type, reference_type, reference_id, is_read)
    VALUES (?, ?, ?, ?, ?, ?, FALSE)
    `,
    [
      userId,
      title,
      body,
      type,
      referenceType || null,
      referenceId || null,
    ]
  );

  sendPushToUser({
    userId,
    title,
    body,
    type,
    referenceType,
    referenceId,
  }).catch((error) => {
    console.error("Push after notification error:", error.message);
  });

  return result;
};

// ── Create many notifications ────────────────────────────────────

const createManyNotifications = async (notifications = []) => {
  const cleanNotifications = notifications.filter((item) => item.userId);

  if (cleanNotifications.length === 0) return null;

  const values = cleanNotifications.map((item) => [
    item.userId,
    item.title,
    item.body,
    item.type || "general",
    item.referenceType || null,
    item.referenceId || null,
    false,
  ]);

  const [result] = await db.query(
    `
    INSERT INTO notifications
      (user_id, title, body, type, reference_type, reference_id, is_read)
    VALUES ?
    `,
    [values]
  );

  cleanNotifications.forEach((item) => {
    sendPushToUser({
      userId: item.userId,
      title: item.title,
      body: item.body,
      type: item.type || "general",
      referenceType: item.referenceType || null,
      referenceId: item.referenceId || null,
    }).catch((error) => {
      console.error("Bulk push notification error:", error.message);
    });
  });

  return result;
};

// ── Create notification for all admins ────────────────────────────

const createNotificationForAdmins = async (
  title,
  body,
  type = "admin_alert",
  referenceType = null,
  referenceId = null
) => {
  const [admins] = await db.query(
    `
    SELECT id
    FROM users
    WHERE role = 'admin'
      AND (status IS NULL OR status = 'active')
    `
  );

  if (!admins || admins.length === 0) return null;

  const notifications = admins.map((admin) => ({
    userId: admin.id,
    title,
    body,
    type,
    referenceType,
    referenceId,
  }));

  return createManyNotifications(notifications);
};

// ── Get all notifications for current user ───────────────────────

const getNotificationsByUser = async (userId) => {
  const [rows] = await db.query(
    `
    SELECT 
      id,
      user_id,
      title,
      body,
      body AS message,
      type,
      reference_type,
      reference_id,
      is_read,
      created_at
    FROM notifications
    WHERE user_id = ?
    ORDER BY created_at DESC
    LIMIT 80
    `,
    [userId]
  );

  return rows;
};

// ── Mark one notification as read ────────────────────────────────

const markAsRead = async (notificationId, userId) => {
  const [result] = await db.query(
    `
    UPDATE notifications
    SET is_read = TRUE
    WHERE id = ? AND user_id = ?
    `,
    [notificationId, userId]
  );

  return result;
};

// ── Mark all notifications as read ───────────────────────────────

const markAllAsRead = async (userId) => {
  const [result] = await db.query(
    `
    UPDATE notifications
    SET is_read = TRUE
    WHERE user_id = ?
    `,
    [userId]
  );

  return result;
};

// ── Count unread notifications ───────────────────────────────────

const getUnreadCount = async (userId) => {
  const [rows] = await db.query(
    `
    SELECT COUNT(*) AS count
    FROM notifications
    WHERE user_id = ? AND is_read = FALSE
    `,
    [userId]
  );

  return rows[0]?.count || 0;
};

// ── Reminder log helpers ─────────────────────────────────────────

const wasReminderSent = async (bookingId, userId, reminderType) => {
  const [rows] = await db.query(
    `
    SELECT id
    FROM booking_reminder_logs
    WHERE booking_id = ?
      AND user_id = ?
      AND reminder_type = ?
    LIMIT 1
    `,
    [bookingId, userId, reminderType]
  );

  return rows.length > 0;
};

const markReminderSent = async (bookingId, userId, reminderType) => {
  const [result] = await db.query(
    `
    INSERT IGNORE INTO booking_reminder_logs
      (booking_id, user_id, reminder_type)
    VALUES (?, ?, ?)
    `,
    [bookingId, userId, reminderType]
  );

  return result;
};

module.exports = {
  createNotification,
  createManyNotifications,
  createNotificationForAdmins,
  getNotificationsByUser,
  markAsRead,
  markAllAsRead,
  getUnreadCount,
  wasReminderSent,
  markReminderSent,
};