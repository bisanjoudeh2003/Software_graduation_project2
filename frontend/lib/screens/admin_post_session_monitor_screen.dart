import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Color postPrimaryGreen = Color(0xFF2F4F46);
const Color postLightCream = Color(0xFFF5F1EB);
const Color postSoftGreen = Color(0xFF3E6B5C);
const Color postGold = Color(0xFFC9A84C);
const Color postRed = Color(0xFFB84040);
const Color postGrey = Color(0xFF8A8A8A);
const Color postBlue = Color(0xFF2F80ED);
const Color postPurple = Color(0xFF7C4DFF);

class AdminPostSessionMonitorScreen extends StatefulWidget {
  const AdminPostSessionMonitorScreen({super.key});

  @override
  State<AdminPostSessionMonitorScreen> createState() =>
      _AdminPostSessionMonitorScreenState();
}

class _AdminPostSessionMonitorScreenState
    extends State<AdminPostSessionMonitorScreen> {
  final List<Map<String, dynamic>> sessions = [
    {
      "id": 101,
      "title": "Wedding Session",
      "client": "Sara Ahmad",
      "photographer": "Mira Studio",
      "venue": "Rose Villa",
      "completed_at": "2026-05-20",
      "last_update": "2 days ago",
      "gallery_created": true,
      "delivered": true,
      "revisions_done": false,
      "final_access": false,
      "review_submitted": false,
      "revision_count": 2,
      "clean_copy": "pending",
      "rating": null,
      "status_note": "Client has pending revision requests.",
    },
    {
      "id": 102,
      "title": "Graduation Session",
      "client": "Lina Omar",
      "photographer": "Ahmad Lens",
      "venue": "Campus Garden",
      "completed_at": "2026-05-18",
      "last_update": "5 days ago",
      "gallery_created": true,
      "delivered": false,
      "revisions_done": false,
      "final_access": false,
      "review_submitted": false,
      "revision_count": 0,
      "clean_copy": "none",
      "rating": null,
      "status_note": "Gallery was created but not delivered yet.",
    },
    {
      "id": 103,
      "title": "Birthday Session",
      "client": "Nour Sami",
      "photographer": "Luma Photos",
      "venue": "Sky Hall",
      "completed_at": "2026-05-15",
      "last_update": "1 day ago",
      "gallery_created": true,
      "delivered": true,
      "revisions_done": true,
      "final_access": true,
      "review_submitted": true,
      "revision_count": 1,
      "clean_copy": "approved",
      "rating": 4.8,
      "status_note": "Post-session flow completed successfully.",
    },
    {
      "id": 104,
      "title": "Engagement Session",
      "client": "Haya Ali",
      "photographer": "Focus Frame",
      "venue": "Old City View",
      "completed_at": "2026-05-12",
      "last_update": "6 days ago",
      "gallery_created": false,
      "delivered": false,
      "revisions_done": false,
      "final_access": false,
      "review_submitted": false,
      "revision_count": 0,
      "clean_copy": "none",
      "rating": null,
      "status_note": "No gallery has been created after the session.",
    },
    {
      "id": 105,
      "title": "Family Session",
      "client": "Rama Nasser",
      "photographer": "Golden Shot",
      "venue": "Home Location",
      "completed_at": "2026-05-10",
      "last_update": "3 days ago",
      "gallery_created": true,
      "delivered": true,
      "revisions_done": true,
      "final_access": true,
      "review_submitted": true,
      "revision_count": 0,
      "clean_copy": "none",
      "rating": 2.5,
      "status_note": "Low rating received after delivery.",
    },
  ];

  String _formatDate(String value) {
    try {
      final date = DateTime.parse(value);
      return DateFormat("MMM d, yyyy").format(date);
    } catch (_) {
      return value;
    }
  }

  int _completedCount() {
    return sessions.where((s) => _progressValue(s) == 6).length;
  }

  int _needsReviewCount() {
    return sessions.where((s) => _needsAdminReview(s)).length;
  }

  int _missingGalleryCount() {
    return sessions.where((s) => s["gallery_created"] != true).length;
  }

  int _pendingRevisionsCount() {
    return sessions.where((s) {
      return s["gallery_created"] == true &&
          s["delivered"] == true &&
          s["revisions_done"] != true;
    }).length;
  }

  int _missingReviewsCount() {
    return sessions.where((s) => s["review_submitted"] != true).length;
  }

  bool _needsAdminReview(Map<String, dynamic> session) {
    final rating = double.tryParse(session["rating"]?.toString() ?? "");
    return session["gallery_created"] != true ||
        session["delivered"] != true ||
        session["revisions_done"] != true ||
        session["final_access"] != true ||
        session["review_submitted"] != true ||
        session["clean_copy"] == "pending" ||
        (rating != null && rating < 3);
  }

  int _progressValue(Map<String, dynamic> session) {
    int value = 1;

    if (session["gallery_created"] == true) value++;
    if (session["delivered"] == true) value++;
    if (session["revisions_done"] == true) value++;
    if (session["final_access"] == true) value++;
    if (session["review_submitted"] == true) value++;

    return value;
  }

  Color _progressColor(Map<String, dynamic> session) {
    final rating = double.tryParse(session["rating"]?.toString() ?? "");

    if (rating != null && rating < 3) return postRed;
    if (_progressValue(session) == 6) return postSoftGreen;
    if (_needsAdminReview(session)) return postGold;
    return postPrimaryGreen;
  }

  String _statusText(Map<String, dynamic> session) {
    final rating = double.tryParse(session["rating"]?.toString() ?? "");

    if (rating != null && rating < 3) return "Low Rating";
    if (session["gallery_created"] != true) return "Gallery Missing";
    if (session["delivered"] != true) return "Not Delivered";
    if (session["revisions_done"] != true) return "Revision Pending";
    if (session["final_access"] != true) return "Access Locked";
    if (session["review_submitted"] != true) return "No Review";
    return "Completed";
  }

  IconData _statusIcon(Map<String, dynamic> session) {
    final status = _statusText(session);

    switch (status) {
      case "Gallery Missing":
        return Icons.photo_library_outlined;
      case "Not Delivered":
        return Icons.outbox_outlined;
      case "Revision Pending":
        return Icons.edit_note_rounded;
      case "Access Locked":
        return Icons.lock_outline_rounded;
      case "No Review":
        return Icons.rate_review_outlined;
      case "Low Rating":
        return Icons.warning_amber_rounded;
      default:
        return Icons.verified_rounded;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: postPrimaryGreen,
        content: Text(
          message,
          style: const TextStyle(fontFamily: "Montserrat"),
        ),
      ),
    );
  }

  void _openSessionSheet(Map<String, dynamic> session) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _sessionSheet(session),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: postLightCream,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header()),
          SliverToBoxAdapter(child: _topSummary()),
          SliverToBoxAdapter(child: _journeyIntro()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, index) {
                  final session = sessions[index];
                  return _sessionCard(session);
                },
                childCount: sessions.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF25463D), postSoftGreen],
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
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context, true),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withOpacity(.22),
                      ),
                    ),
                    child: const Icon(
                      Icons.fact_check_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Post-Session Monitor",
                          style: TextStyle(
                            fontFamily: "Montserrat",
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Track delivery, revisions, final access and reviews.",
                          style: TextStyle(
                            fontFamily: "Montserrat",
                            color: Colors.white70,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 0, 0),
      child: SizedBox(
        height: 102,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _summaryCard(
              title: "Sessions",
              value: sessions.length.toString(),
              icon: Icons.event_available_outlined,
              color: postPrimaryGreen,
            ),
            _summaryCard(
              title: "Completed Flow",
              value: _completedCount().toString(),
              icon: Icons.verified_rounded,
              color: postSoftGreen,
            ),
            _summaryCard(
              title: "Needs Review",
              value: _needsReviewCount().toString(),
              icon: Icons.priority_high_rounded,
              color: postRed,
            ),
            _summaryCard(
              title: "Missing Gallery",
              value: _missingGalleryCount().toString(),
              icon: Icons.photo_library_outlined,
              color: postGold,
            ),
            _summaryCard(
              title: "Pending Revision",
              value: _pendingRevisionsCount().toString(),
              icon: Icons.edit_note_rounded,
              color: postPurple,
            ),
            _summaryCard(
              title: "No Reviews",
              value: _missingReviewsCount().toString(),
              icon: Icons.rate_review_outlined,
              color: postBlue,
            ),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 145,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.12)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: "Montserrat",
                    color: Colors.black45,
                    fontSize: 10.5,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _journeyIntro() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: postPrimaryGreen,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: postPrimaryGreen.withOpacity(.12),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.14),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.timeline_rounded,
                color: Colors.white,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Each card shows the post-session journey only, without repeating booking details.",
                style: TextStyle(
                  fontFamily: "Montserrat",
                  color: Colors.white,
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sessionCard(Map<String, dynamic> session) {
    final color = _progressColor(session);
    final progress = _progressValue(session);
    final status = _statusText(session);

    return GestureDetector(
      onTap: () => _openSessionSheet(session),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(.16)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(.055),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 49,
                  height: 49,
                  decoration: BoxDecoration(
                    color: color.withOpacity(.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _statusIcon(session),
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session["title"]?.toString() ?? "Session",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: "Montserrat",
                          color: postPrimaryGreen,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${session["photographer"]} → ${session["client"]}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: "Montserrat",
                          color: Colors.black45,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusChip(status, color),
              ],
            ),
            const SizedBox(height: 14),
            _progressBar(progress, color),
            const SizedBox(height: 12),
            _journeySteps(session),
            const SizedBox(height: 13),
            Row(
              children: [
                _smallInfo(
                  Icons.calendar_today_outlined,
                  _formatDate(session["completed_at"]),
                ),
                const SizedBox(width: 9),
                _smallInfo(
                  Icons.update_rounded,
                  session["last_update"]?.toString() ?? "No update",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressBar(int progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress / 6,
                  minHeight: 8,
                  backgroundColor: postLightCream,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "$progress/6",
              style: TextStyle(
                fontFamily: "Montserrat",
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _journeySteps(Map<String, dynamic> session) {
    final steps = [
      {
        "label": "Completed",
        "done": true,
        "icon": Icons.check_circle_outline_rounded,
      },
      {
        "label": "Gallery",
        "done": session["gallery_created"] == true,
        "icon": Icons.photo_library_outlined,
      },
      {
        "label": "Delivery",
        "done": session["delivered"] == true,
        "icon": Icons.outbox_outlined,
      },
      {
        "label": "Revisions",
        "done": session["revisions_done"] == true,
        "icon": Icons.edit_note_rounded,
      },
      {
        "label": "Access",
        "done": session["final_access"] == true,
        "icon": Icons.lock_open_outlined,
      },
      {
        "label": "Review",
        "done": session["review_submitted"] == true,
        "icon": Icons.rate_review_outlined,
      },
    ];

    return Row(
      children: steps.map((step) {
        final done = step["done"] == true;
        return Expanded(
          child: Column(
            children: [
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: done
                      ? postSoftGreen.withOpacity(.12)
                      : postGold.withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  step["icon"] as IconData,
                  color: done ? postSoftGreen : postGold,
                  size: 15,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                step["label"].toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: "Montserrat",
                  color: done ? postPrimaryGreen : Colors.black38,
                  fontSize: 8.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _statusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontFamily: "Montserrat",
          color: color,
          fontSize: 10.2,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _smallInfo(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        decoration: BoxDecoration(
          color: postLightCream,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Icon(icon, color: postPrimaryGreen, size: 14),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: "Montserrat",
                  color: postPrimaryGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sessionSheet(Map<String, dynamic> session) {
    final color = _progressColor(session);
    final rating = session["rating"];

    return DraggableScrollableSheet(
      initialChildSize: 0.76,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      builder: (context, controller) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: const BoxDecoration(
            color: postLightCream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      session["title"]?.toString() ?? "Session",
                      style: const TextStyle(
                        fontFamily: "Montserrat",
                        color: postPrimaryGreen,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _statusChip(_statusText(session), color),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Post-session quality review",
                style: TextStyle(
                  fontFamily: "Montserrat",
                  color: Colors.black.withOpacity(.45),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _sheetSection(
                title: "Journey Status",
                icon: Icons.timeline_rounded,
                children: [
                  _sheetRow("Gallery Created",
                      session["gallery_created"] == true ? "Yes" : "No"),
                  _sheetRow(
                      "Delivered", session["delivered"] == true ? "Yes" : "No"),
                  _sheetRow("Revisions Done",
                      session["revisions_done"] == true ? "Yes" : "No"),
                  _sheetRow("Final Access",
                      session["final_access"] == true ? "Enabled" : "Locked"),
                  _sheetRow("Review Submitted",
                      session["review_submitted"] == true ? "Yes" : "No"),
                ],
              ),
              const SizedBox(height: 13),
              _sheetSection(
                title: "Quality Signals",
                icon: Icons.insights_outlined,
                children: [
                  _sheetRow(
                    "Revision Requests",
                    session["revision_count"].toString(),
                  ),
                  _sheetRow(
                    "Clean Copy",
                    session["clean_copy"]?.toString() ?? "none",
                  ),
                  _sheetRow(
                    "Rating",
                    rating == null ? "Not submitted" : rating.toString(),
                  ),
                  _sheetRow(
                    "Last Update",
                    session["last_update"]?.toString() ?? "Not set",
                  ),
                ],
              ),
              const SizedBox(height: 13),
              _noteCard(session["status_note"]?.toString() ?? "", color),
              const SizedBox(height: 18),
              _actionButton(
                label: "Send Reminder",
                icon: Icons.notifications_active_outlined,
                color: postPrimaryGreen,
                onTap: () {
                  Navigator.pop(context);
                  _showMessage("Reminder action will be connected later.");
                },
              ),
              const SizedBox(height: 10),
              _actionButton(
                label: "Add Admin Note",
                icon: Icons.note_add_outlined,
                color: postGold,
                onTap: () {
                  Navigator.pop(context);
                  _showMessage("Admin note action will be connected later.");
                },
              ),
              const SizedBox(height: 10),
              _actionButton(
                label: "Contact User",
                icon: Icons.support_agent_outlined,
                color: postSoftGreen,
                onTap: () {
                  Navigator.pop(context);
                  _showMessage("Support message action will be connected later.");
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: postPrimaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: "Montserrat",
                  color: postPrimaryGreen,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _sheetRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: "Montserrat",
                color: Colors.black45,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: "Montserrat",
              color: postPrimaryGreen,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noteCard(String note, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              note,
              style: const TextStyle(
                fontFamily: "Montserrat",
                color: Colors.black54,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}