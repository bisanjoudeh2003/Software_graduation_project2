import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import 'admin_manage_warehouse_screen.dart';

const Color adminPrimaryGreen = Color(0xFF2F4F3E);
const Color adminLightCream = Color(0xFFF6F4EE);
const Color adminSoftGreen = Color(0xFF3D6B57);
const Color adminPaleGreen = Color(0xFFEAF3EE);
const Color adminGold = Color(0xFFC9A84C);
const Color adminRed = Color(0xFFD9534F);
const Color adminGrey = Color(0xFF8A8A8A);
const Color adminDarkText = Color(0xFF26352D);

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  bool loading = true;
  bool actionLoading = false;

  List notifications = [];
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    setState(() => loading = true);

    try {
      final data = await NotificationService.getMyNotifications();

      if (!mounted) return;

      setState(() {
        notifications = data?["notifications"] ?? [];
        unreadCount =
            int.tryParse(data?["unread_count"]?.toString() ?? "0") ?? 0;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);
      showMessage(e.toString(), isError: true);
    }
  }

  Future<void> markAllRead() async {
    if (actionLoading) return;

    setState(() => actionLoading = true);

    final ok = await NotificationService.markAllAsRead();

    if (!mounted) return;

    setState(() => actionLoading = false);

    if (ok) {
      await loadNotifications();
      showMessage("All notifications marked as read");
    } else {
      showMessage("Failed to mark notifications as read", isError: true);
    }
  }

  Future<void> openNotification(Map item) async {
    final id = int.tryParse(item["id"]?.toString() ?? "");
    final type = item["type"]?.toString() ?? "";
    final referenceType = item["reference_type"]?.toString() ?? "";

    if (id != null) {
      await NotificationService.markAsRead(id);
    }

    if (!mounted) return;

    if (type == "admin_warehouse_product" ||
        referenceType == "warehouse_product") {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminManageWarehouseScreen(),
        ),
      );

      await loadNotifications();
      return;
    }

    await loadNotifications();
  }

  void showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message.replaceFirst("Exception: ", ""),
          style: const TextStyle(
            fontFamily: "Montserrat",
            fontSize: 12.5,
          ),
        ),
        backgroundColor: isError ? adminRed : adminPrimaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  int toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  String cleanText(dynamic value, {String fallback = ""}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty || text == "null") return fallback;
    return text;
  }

  IconData notificationIcon(Map item) {
    final type = cleanText(item["type"]);
    final ref = cleanText(item["reference_type"]);

    if (type.contains("warehouse") || ref.contains("warehouse")) {
      return Icons.warehouse_outlined;
    }

    if (type.contains("community") || ref.contains("community")) {
      return Icons.forum_outlined;
    }

    if (type.contains("venue") || ref.contains("venue")) {
      return Icons.location_city_outlined;
    }

    if (type.contains("photographer") || ref.contains("photographer")) {
      return Icons.camera_alt_outlined;
    }

    if (type.contains("booking") || ref.contains("booking")) {
      return Icons.event_note_outlined;
    }

    if (type.contains("report") || ref.contains("report")) {
      return Icons.report_outlined;
    }

    return Icons.notifications_none_rounded;
  }

  Color notificationColor(Map item) {
    final type = cleanText(item["type"]);
    final ref = cleanText(item["reference_type"]);

    if (type.contains("warehouse") || ref.contains("warehouse")) {
      return adminSoftGreen;
    }

    if (type.contains("report") || ref.contains("report")) {
      return adminRed;
    }

    if (type.contains("community") || ref.contains("community")) {
      return adminGold;
    }

    if (type.contains("venue") || ref.contains("venue")) {
      return adminPrimaryGreen;
    }

    if (type.contains("photographer") || ref.contains("photographer")) {
      return adminPrimaryGreen;
    }

    return adminGrey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: adminLightCream,
      body: RefreshIndicator(
        color: adminPrimaryGreen,
        onRefresh: loadNotifications,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: header()),
            if (loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: adminPrimaryGreen),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      summaryCard(),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Notifications",
                              style: TextStyle(
                                fontFamily: "Montserrat",
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: adminDarkText,
                              ),
                            ),
                          ),
                          if (unreadCount > 0)
                            GestureDetector(
                              onTap: markAllRead,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: adminPrimaryGreen.withOpacity(.1),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  actionLoading ? "..." : "Mark all read",
                                  style: const TextStyle(
                                    fontFamily: "Montserrat",
                                    color: adminPrimaryGreen,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (notifications.isEmpty)
                        emptyState()
                      else
                        ...notifications.map(
                          (item) => notificationCard(
                            Map<String, dynamic>.from(item as Map),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget header() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [adminPrimaryGreen, adminSoftGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context, true),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "Admin Notifications",
                style: TextStyle(
                  fontFamily: "Montserrat",
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Review alerts, reports, approvals and system updates",
                style: TextStyle(
                  fontFamily: "Montserrat",
                  color: Colors.white.withOpacity(.82),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget summaryCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: adminPrimaryGreen.withOpacity(.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: adminPrimaryGreen.withOpacity(.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: adminPrimaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unreadCount > 0
                      ? "$unreadCount unread notification${unreadCount == 1 ? "" : "s"}"
                      : "All caught up",
                  style: const TextStyle(
                    fontFamily: "Montserrat",
                    color: adminPrimaryGreen,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  unreadCount > 0
                      ? "Tap a notification to review its related section."
                      : "No unread admin alerts right now.",
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    color: Colors.black.withOpacity(.48),
                    fontSize: 11.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget notificationCard(Map<String, dynamic> item) {
    final isRead = toInt(item["is_read"]) == 1 || item["is_read"] == true;
    final color = notificationColor(item);

    return GestureDetector(
      onTap: () => openNotification(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isRead ? Colors.grey.shade200 : color.withOpacity(.35),
            width: isRead ? 1 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(.045),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: color.withOpacity(.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    notificationIcon(item),
                    color: color,
                    size: 22,
                  ),
                ),
                if (!isRead)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: const BoxDecoration(
                        color: adminRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cleanText(item["title"], fallback: "Notification"),
                    style: TextStyle(
                      fontFamily: "Montserrat",
                      color: isRead ? adminDarkText.withOpacity(.72) : color,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    cleanText(
                      item["body"] ?? item["message"],
                      fallback: "You have a new update.",
                    ),
                    style: TextStyle(
                      fontFamily: "Montserrat",
                      color: Colors.black.withOpacity(.56),
                      fontSize: 11.7,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: Colors.black.withOpacity(.35),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          cleanText(item["created_at"], fallback: ""),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: "Montserrat",
                            color: Colors.black.withOpacity(.38),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.black.withOpacity(.28),
              size: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            color: adminGrey.withOpacity(.45),
            size: 58,
          ),
          const SizedBox(height: 12),
          const Text(
            "No notifications yet",
            style: TextStyle(
              fontFamily: "Montserrat",
              color: adminPrimaryGreen,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Admin alerts will appear here when something needs review.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "Montserrat",
              color: Colors.black.withOpacity(.45),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}