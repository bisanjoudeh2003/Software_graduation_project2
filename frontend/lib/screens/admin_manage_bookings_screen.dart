import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../services/admin_booking_service.dart';

class AdminManageBookingsScreen extends StatefulWidget {
  const AdminManageBookingsScreen({super.key});

  @override
  State<AdminManageBookingsScreen> createState() =>
      _AdminManageBookingsScreenState();
}

class _AdminManageBookingsScreenState extends State<AdminManageBookingsScreen> {
  static const Color primaryGreen = Color(0xFF2F4F46);
  static const Color softGreen = Color(0xFF3E6B5C);
  static const Color cream = Color(0xFFF5F1EB);
  static const Color gold = Color(0xFFC9A84C);
  static const Color red = Color(0xFFB84040);
  static const Color blue = Color(0xFF2F80ED);
  static const Color grey = Color(0xFF8A8A8A);
  static const Color purple = Color(0xFF7C4DFF);

  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  bool loading = true;
  bool photographerTab = true;

  List bookings = [];

  String selectedStatus = "all";
  String selectedDateFilter = "all";

  final List<Map<String, String>> statusFilters = const [
    {"label": "All", "value": "all"},
    {"label": "Pending", "value": "pending"},
    {"label": "Confirmed", "value": "confirmed"},
    {"label": "Completed", "value": "completed"},
    {"label": "Cancelled", "value": "cancelled"},
    {"label": "Rejected", "value": "rejected"},
  ];

  final List<Map<String, String>> dateFilters = const [
    {"label": "All Dates", "value": "all"},
    {"label": "Today", "value": "today"},
    {"label": "Upcoming", "value": "upcoming"},
    {"label": "Past", "value": "past"},
  ];

  @override
  void initState() {
    super.initState();
    loadBookings();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 450), () {
      loadBookings(showLoader: false);
    });
  }

  Future<void> loadBookings({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() => loading = true);
    }

    try {
      final data = photographerTab
          ? await AdminBookingService.getPhotographerBookings(
              status: selectedStatus,
              dateFilter: selectedDateFilter,
              search: searchController.text.trim(),
            )
          : await AdminBookingService.getVenueBookings(
              status: selectedStatus,
              dateFilter: selectedDateFilter,
              search: searchController.text.trim(),
            );

      if (!mounted) return;

      setState(() {
        bookings = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        bookings = [];
        loading = false;
      });

      _showMessage(
        e.toString().replaceAll("Exception:", "").trim(),
        isError: true,
      );
    }
  }

  void _changeTab(bool toPhotographer) {
    if (photographerTab == toPhotographer) return;

    setState(() {
      photographerTab = toPhotographer;
      selectedStatus = "all";
      selectedDateFilter = "all";
      searchController.clear();
      bookings = [];
    });

    loadBookings();
  }

  void _clearFilters() {
    setState(() {
      selectedStatus = "all";
      selectedDateFilter = "all";
      searchController.clear();
    });

    loadBookings();
  }

  String _text(dynamic value, {String fallback = "Not set"}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty || text == "null") return fallback;
    return text;
  }

  String _money(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? "0") ?? 0;
    if (amount == amount.truncate()) {
      return "\$${amount.toInt()}";
    }
    return "\$${amount.toStringAsFixed(2)}";
  }

  bool _isPaid(dynamic value) {
    return value == 1 || value == true || value?.toString() == "1";
  }

  bool _hasValue(dynamic value) {
    final text = value?.toString().trim() ?? "";
    return text.isNotEmpty && text != "null";
  }

  DateTime? _bookingDate(Map<String, dynamic> booking) {
    final raw = photographerTab
        ? booking["date"]?.toString()
        : booking["booking_date"]?.toString();

    if (raw == null || raw.trim().isEmpty || raw == "null") return null;

    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  bool _isPastBooking(Map<String, dynamic> booking) {
    final date = _bookingDate(booking);
    if (date == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingDay = DateTime(date.year, date.month, date.day);

    return bookingDay.isBefore(today);
  }

  String _formatDate(dynamic value) {
    final raw = value?.toString() ?? "";
    if (raw.isEmpty || raw == "null") return "Not set";

    try {
      final date = DateTime.parse(raw).toLocal();
      return DateFormat("MMM d, yyyy").format(date);
    } catch (_) {
      return raw.length >= 10 ? raw.substring(0, 10) : raw;
    }
  }

  String _formatTime(dynamic value) {
    final raw = value?.toString() ?? "";
    if (raw.isEmpty || raw == "null") return "";

    try {
      final parts = raw.split(":");
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        final date = DateTime(2026, 1, 1, hour, minute);
        return DateFormat.jm().format(date);
      }
      return raw;
    } catch (_) {
      return raw;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case "pending":
        return gold;
      case "confirmed":
        return blue;
      case "completed":
        return softGreen;
      case "cancelled":
      case "rejected":
        return red;
      default:
        return grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case "pending":
        return Icons.hourglass_top_rounded;
      case "confirmed":
        return Icons.check_circle_outline_rounded;
      case "completed":
        return Icons.verified_rounded;
      case "cancelled":
      case "rejected":
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _statusLabel(String status) {
    if (status.isEmpty) return "Unknown";
    return status[0].toUpperCase() + status.substring(1);
  }

  List<Map<String, dynamic>> _attentionItems(Map<String, dynamic> booking) {
    final status = _text(booking["status"], fallback: "").toLowerCase();
    final depositPaid = _isPaid(booking["deposit_paid"]);
    final remainingPaid = _isPaid(booking["remaining_paid"]);
    final past = _isPastBooking(booking);

    final items = <Map<String, dynamic>>[];

    if (status == "pending" && !depositPaid) {
      items.add({
        "label": "Waiting Deposit",
        "icon": Icons.payments_outlined,
        "color": gold,
      });
    }

    if (status == "confirmed" && !remainingPaid) {
      items.add({
        "label": "Remaining Unpaid",
        "icon": Icons.credit_card_off_outlined,
        "color": gold,
      });
    }

    if (status == "pending" && past) {
      items.add({
        "label": "Past Pending",
        "icon": Icons.warning_amber_rounded,
        "color": red,
      });
    }

    if (status == "confirmed" && past) {
      items.add({
        "label": "Needs Follow-up",
        "icon": Icons.task_alt_outlined,
        "color": purple,
      });
    }

    if ((status == "cancelled" || status == "rejected") &&
        (_hasValue(booking["cancellation_reason"]) ||
            _hasValue(booking["rejection_reason"]))) {
      items.add({
        "label": "Has Reason",
        "icon": Icons.info_outline_rounded,
        "color": red,
      });
    }

    if (photographerTab && _isPaid(booking["refunded"])) {
      items.add({
        "label": "Refunded",
        "icon": Icons.currency_exchange_rounded,
        "color": softGreen,
      });
    }

    return items;
  }

  int _countStatus(String status) {
    return bookings.where((b) {
      final booking = Map<String, dynamic>.from(b);
      return _text(booking["status"], fallback: "").toLowerCase() == status;
    }).length;
  }

  int _needsAttentionCount() {
    return bookings.where((b) {
      final booking = Map<String, dynamic>.from(b);
      return _attentionItems(booking).isNotEmpty;
    }).length;
  }

  int _waitingDepositCount() {
    return bookings.where((b) {
      final booking = Map<String, dynamic>.from(b);
      final status = _text(booking["status"], fallback: "").toLowerCase();
      return status == "pending" && !_isPaid(booking["deposit_paid"]);
    }).length;
  }

  int _remainingUnpaidCount() {
    return bookings.where((b) {
      final booking = Map<String, dynamic>.from(b);
      final status = _text(booking["status"], fallback: "").toLowerCase();
      return status == "confirmed" && !_isPaid(booking["remaining_paid"]);
    }).length;
  }

  void _openDetails(Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _detailsSheet(booking);
      },
    );
  }

  List<Map<String, dynamic>> _timelineItems(Map<String, dynamic> booking) {
    final status = _text(booking["status"], fallback: "").toLowerCase();

    final items = <Map<String, dynamic>>[];

    items.add({
      "title": "Booking created",
      "value": _formatDate(booking["created_at"]),
      "icon": Icons.add_circle_outline_rounded,
      "color": primaryGreen,
    });

    if (_hasValue(booking["deposit_paid_at"])) {
      items.add({
        "title": "Deposit paid",
        "value": _formatDate(booking["deposit_paid_at"]),
        "icon": Icons.payments_outlined,
        "color": softGreen,
      });
    } else {
      items.add({
        "title": "Deposit",
        "value": _isPaid(booking["deposit_paid"]) ? "Paid" : "Not paid yet",
        "icon": Icons.hourglass_top_rounded,
        "color": _isPaid(booking["deposit_paid"]) ? softGreen : gold,
      });
    }

    if (_hasValue(booking["remaining_paid_at"])) {
      items.add({
        "title": "Remaining paid",
        "value": _formatDate(booking["remaining_paid_at"]),
        "icon": Icons.credit_score_outlined,
        "color": softGreen,
      });
    } else if (status == "confirmed" || status == "completed") {
      items.add({
        "title": "Remaining payment",
        "value": _isPaid(booking["remaining_paid"]) ? "Paid" : "Not paid yet",
        "icon": Icons.credit_card_off_outlined,
        "color": _isPaid(booking["remaining_paid"]) ? softGreen : gold,
      });
    }

    if (status == "rejected" && _hasValue(booking["rejection_reason"])) {
      items.add({
        "title": "Rejected",
        "value": _text(booking["rejection_reason"]),
        "icon": Icons.block_rounded,
        "color": red,
      });
    } else if (status == "cancelled") {
      items.add({
        "title": "Cancelled",
        "value": _hasValue(booking["cancellation_reason"])
            ? _text(booking["cancellation_reason"])
            : "No reason provided",
        "icon": Icons.cancel_outlined,
        "color": red,
      });
    } else {
      items.add({
        "title": "Current status",
        "value": _statusLabel(status),
        "icon": _statusIcon(status),
        "color": _statusColor(status),
      });
    }

    return items;
  }

  String _bookingSummaryText(Map<String, dynamic> booking) {
    final status = _text(booking["status"], fallback: "Unknown");
    final title = photographerTab
        ? _text(booking["session_type"], fallback: "Photography Booking")
        : _text(booking["venue_name"], fallback: "Venue Booking");

    final secondParty = photographerTab
        ? _text(booking["photographer_name"])
        : _text(booking["owner_name"]);

    final secondPartyLabel = photographerTab ? "Photographer" : "Venue Owner";

    final date = photographerTab
        ? _formatDate(booking["date"])
        : _formatDate(booking["booking_date"]);

    final time = photographerTab
        ? _formatTime(booking["time"])
        : "${_formatTime(booking["start_time"])} - ${_formatTime(booking["end_time"])}";

    return """
Booking Summary
Booking ID: ${_text(booking["id"])}
Type: $title
Status: ${_statusLabel(status)}
Client: ${_text(booking["client_name"])}
$secondPartyLabel: $secondParty
Date: $date
Time: $time
Total Price: ${_money(booking["total_price"])}
Deposit: ${_isPaid(booking["deposit_paid"]) ? "Paid" : "Unpaid"}
Remaining: ${_isPaid(booking["remaining_paid"]) ? "Paid" : "Unpaid"}
""";
  }

  Future<void> _copyBookingSummary(Map<String, dynamic> booking) async {
    await Clipboard.setData(
      ClipboardData(text: _bookingSummaryText(booking)),
    );

    _showMessage("Booking summary copied.");
  }

  Widget _detailsSheet(Map<String, dynamic> booking) {
    final status = _text(booking["status"], fallback: "unknown");
    final color = _statusColor(status);

    final title = photographerTab
        ? _text(booking["session_type"], fallback: "Photography Booking")
        : _text(booking["venue_name"], fallback: "Venue Booking");

    final date = photographerTab
        ? _formatDate(booking["date"])
        : _formatDate(booking["booking_date"]);

    final time = photographerTab
        ? _formatTime(booking["time"])
        : "${_formatTime(booking["start_time"])} - ${_formatTime(booking["end_time"])}";

    final attention = _attentionItems(booking);

    return DraggableScrollableSheet(
      initialChildSize: 0.84,
      maxChildSize: 0.94,
      minChildSize: 0.45,
      builder: (context, controller) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: const BoxDecoration(
            color: cream,
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
                      title,
                      style: const TextStyle(
                        fontFamily: "Montserrat",
                        color: primaryGreen,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _statusChip(status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "$date • $time",
                style: const TextStyle(
                  fontFamily: "Montserrat",
                  color: Colors.black45,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              _copySummaryButton(booking),
              if (attention.isNotEmpty) ...[
                const SizedBox(height: 14),
                _attentionWrap(attention),
              ],
              const SizedBox(height: 18),
              _timelineSection(booking),
              const SizedBox(height: 14),
              _detailSection(
                title: "People",
                icon: Icons.people_outline_rounded,
                children: photographerTab
                    ? [
                        _detailRow("Client", _text(booking["client_name"])),
                        _detailRow(
                          "Photographer",
                          _text(booking["photographer_name"]),
                        ),
                        _detailRow(
                          "Client Email",
                          _text(booking["client_email"]),
                        ),
                        _detailRow(
                          "Photographer Email",
                          _text(booking["photographer_email"]),
                        ),
                      ]
                    : [
                        _detailRow("Client", _text(booking["client_name"])),
                        _detailRow("Venue Owner", _text(booking["owner_name"])),
                        _detailRow(
                          "Client Email",
                          _text(booking["client_email"]),
                        ),
                        _detailRow("Owner Email", _text(booking["owner_email"])),
                      ],
              ),
              const SizedBox(height: 14),
              _detailSection(
                title: "Booking Details",
                icon: photographerTab
                    ? Icons.camera_alt_outlined
                    : Icons.location_city_outlined,
                children: photographerTab
                    ? [
                        _detailRow(
                          "Session Type",
                          _text(booking["session_type"]),
                        ),
                        _detailRow("Location", _text(booking["location"])),
                        _detailRow(
                          "Venue",
                          _text(booking["venue_name"], fallback: "No venue"),
                        ),
                        _detailRow(
                          "Duration",
                          "${_text(booking["duration_hours"], fallback: "0")} hours",
                        ),
                      ]
                    : [
                        _detailRow("Venue", _text(booking["venue_name"])),
                        _detailRow(
                          "Location",
                          _text(booking["venue_location"]),
                        ),
                        _detailRow("Notes", _text(booking["notes"])),
                      ],
              ),
              const SizedBox(height: 14),
              _detailSection(
                title: "Payment",
                icon: Icons.payments_outlined,
                children: [
                  _detailRow("Total Price", _money(booking["total_price"])),
                  _detailRow("Deposit", _money(booking["deposit_amount"])),
                  _detailRow(
                    "Deposit Paid",
                    _isPaid(booking["deposit_paid"]) ? "Yes" : "No",
                  ),
                  if (booking.containsKey("remaining_amount"))
                    _detailRow(
                      "Remaining Amount",
                      _money(booking["remaining_amount"]),
                    ),
                  _detailRow(
                    "Remaining Paid",
                    _isPaid(booking["remaining_paid"]) ? "Yes" : "No",
                  ),
                  if (photographerTab)
                    _detailRow(
                      "Remaining Status",
                      _text(
                        booking["remaining_payment_status"],
                        fallback: "Not set",
                      ),
                    ),
                ],
              ),
              if (status == "cancelled" || status == "rejected") ...[
                const SizedBox(height: 14),
                _detailSection(
                  title: status == "cancelled"
                      ? "Cancellation Reason"
                      : "Rejection Reason",
                  icon: Icons.info_outline_rounded,
                  children: [
                    if (_hasValue(booking["cancellation_reason"]))
                      _detailRow(
                        "Reason",
                        _text(booking["cancellation_reason"]),
                      ),
                    if (_hasValue(booking["cancelled_at"]))
                      _detailRow(
                        "Cancelled At",
                        _formatDate(booking["cancelled_at"]),
                      ),
                    if (_hasValue(booking["rejection_reason"]))
                      _detailRow(
                        "Rejection Reason",
                        _text(booking["rejection_reason"]),
                      ),
                  ],
                ),
              ],
              if (photographerTab && _isPaid(booking["refunded"])) ...[
                const SizedBox(height: 14),
                _detailSection(
                  title: "Refund",
                  icon: Icons.currency_exchange_rounded,
                  children: [
                    _detailRow("Refunded", "Yes"),
                    _detailRow(
                      "Refund Reason",
                      _text(booking["refund_reason"]),
                    ),
                    _detailRow(
                      "Refunded At",
                      _formatDate(booking["refunded_at"]),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              _noteBox(color),
            ],
          ),
        );
      },
    );
  }

  Widget _copySummaryButton(Map<String, dynamic> booking) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: () => _copyBookingSummary(booking),
        icon: const Icon(Icons.copy_rounded, size: 18),
        label: const Text(
          "Copy Booking Summary",
          style: TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _timelineSection(Map<String, dynamic> booking) {
    final items = _timelineItems(booking);

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
          const Row(
            children: [
              Icon(Icons.timeline_rounded, color: primaryGreen, size: 20),
              SizedBox(width: 8),
              Text(
                "Booking Timeline",
                style: TextStyle(
                  fontFamily: "Montserrat",
                  color: primaryGreen,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(items.length, (index) {
            final item = items[index];
            final isLast = index == items.length - 1;

            return _timelineRow(
              title: item["title"]?.toString() ?? "",
              value: item["value"]?.toString() ?? "",
              icon: item["icon"] as IconData,
              color: item["color"] as Color,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _timelineRow({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 15),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: color.withOpacity(.16),
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: "Montserrat",
                    color: primaryGreen,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: "Montserrat",
                    color: Colors.black45,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _noteBox(Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.admin_panel_settings_outlined, color: color, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "This page is for monitoring bookings, spotting issues, and supporting users from the admin users/messages area.",
              style: TextStyle(
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

  Widget _detailSection({
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
              Icon(icon, color: primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: "Montserrat",
                  color: primaryGreen,
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 126,
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
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: "Montserrat",
                color: primaryGreen,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? red : primaryGreen,
        content: Text(
          message,
          style: const TextStyle(fontFamily: "Montserrat"),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title =
        photographerTab ? "Photographer Bookings" : "Venue Bookings";

    return Scaffold(
      backgroundColor: cream,
      body: RefreshIndicator(
        color: primaryGreen,
        onRefresh: () => loadBookings(showLoader: false),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header(title)),
            SliverToBoxAdapter(child: _tabs()),
            SliverToBoxAdapter(child: _summaryCards()),
            SliverToBoxAdapter(child: _filters()),
            if (loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: primaryGreen),
                ),
              )
            else if (bookings.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _emptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, index) {
                      final booking =
                          Map<String, dynamic>.from(bookings[index]);
                      return _bookingCard(booking);
                    },
                    childCount: bookings.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header(String title) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF25463D), softGreen],
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
              Text(
                title,
                style: const TextStyle(
                  fontFamily: "Montserrat",
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.18,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                "${bookings.length} booking${bookings.length == 1 ? '' : 's'} found",
                style: TextStyle(
                  fontFamily: "Montserrat",
                  color: Colors.white.withOpacity(.72),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: TextField(
                  controller: searchController,
                  style: const TextStyle(
                    fontFamily: "Montserrat",
                    color: primaryGreen,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: photographerTab
                        ? "Search client, photographer, session..."
                        : "Search client, owner, venue...",
                    hintStyle: const TextStyle(
                      fontFamily: "Montserrat",
                      color: Colors.black38,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: primaryGreen,
                    ),
                    suffixIcon: searchController.text.trim().isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              searchController.clear();
                              loadBookings(showLoader: false);
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.black45,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.045),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _tabButton(
                title: "Photographer",
                selected: photographerTab,
                onTap: () => _changeTab(true),
              ),
            ),
            Expanded(
              child: _tabButton(
                title: "Venues",
                selected: !photographerTab,
                onTap: () => _changeTab(false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: "Montserrat",
            color: selected ? Colors.white : primaryGreen,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _summaryCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 0, 0),
      child: SizedBox(
        height: 94,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _summaryCard(
              title: "Total",
              value: bookings.length.toString(),
              icon: Icons.event_note_outlined,
              color: primaryGreen,
            ),
            _summaryCard(
              title: "Needs Attention",
              value: _needsAttentionCount().toString(),
              icon: Icons.priority_high_rounded,
              color: red,
            ),
            _summaryCard(
              title: "Waiting Deposit",
              value: _waitingDepositCount().toString(),
              icon: Icons.hourglass_top_rounded,
              color: gold,
            ),
            _summaryCard(
              title: "Remaining Unpaid",
              value: _remainingUnpaidCount().toString(),
              icon: Icons.credit_card_off_outlined,
              color: gold,
            ),
            _summaryCard(
              title: "Pending",
              value: _countStatus("pending").toString(),
              icon: Icons.pending_actions_rounded,
              color: gold,
            ),
            _summaryCard(
              title: "Confirmed",
              value: _countStatus("confirmed").toString(),
              icon: Icons.check_circle_outline_rounded,
              color: blue,
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
      width: 142,
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
            width: 38,
            height: 38,
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

  Widget _filters() {
    final hasActiveFilters = selectedStatus != "all" ||
        selectedDateFilter != "all" ||
        searchController.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _filtersHeader(hasActiveFilters),
          const SizedBox(height: 12),
          _filterSectionTitle(
            icon: Icons.tune_rounded,
            title: "Status",
            subtitle: "Filter bookings by current state",
          ),
          const SizedBox(height: 8),
          _filterRow(
            items: statusFilters,
            selectedValue: selectedStatus,
            onSelected: (value) {
              setState(() => selectedStatus = value);
              loadBookings();
            },
          ),
          const SizedBox(height: 14),
          _filterSectionTitle(
            icon: Icons.calendar_month_outlined,
            title: "Date",
            subtitle: "Focus on today, upcoming, or past bookings",
          ),
          const SizedBox(height: 8),
          _filterRow(
            items: dateFilters,
            selectedValue: selectedDateFilter,
            onSelected: (value) {
              setState(() => selectedDateFilter = value);
              loadBookings();
            },
          ),
        ],
      ),
    );
  }

  Widget _filtersHeader(bool hasActiveFilters) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Row(
        children: [
          const Icon(
            Icons.filter_alt_outlined,
            color: primaryGreen,
            size: 19,
          ),
          const SizedBox(width: 7),
          const Text(
            "Smart Filters",
            style: TextStyle(
              fontFamily: "Montserrat",
              color: primaryGreen,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          if (hasActiveFilters)
            GestureDetector(
              onTap: _clearFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: red.withOpacity(.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  "Clear",
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    color: red,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryGreen, size: 17),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: "Montserrat",
                    color: primaryGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: "Montserrat",
                    color: Colors.black38,
                    fontSize: 11,
                    height: 1.25,
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

  Widget _filterRow({
    required List<Map<String, String>> items,
    required String selectedValue,
    required Function(String) onSelected,
  }) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...items.map((item) {
            return _filterChip(
              label: item["label"]!,
              value: item["value"]!,
              selectedValue: selectedValue,
              onSelected: onSelected,
            );
          }),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required String value,
    required String selectedValue,
    required Function(String) onSelected,
  }) {
    final selected = selectedValue == value;

    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        margin: const EdgeInsets.only(right: 9),
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: selected ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? primaryGreen : Colors.black.withOpacity(.08),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: "Montserrat",
            color: selected ? Colors.white : primaryGreen,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _bookingCard(Map<String, dynamic> booking) {
    final status = _text(booking["status"], fallback: "unknown");
    final statusColor = _statusColor(status);
    final attention = _attentionItems(booking);

    final title = photographerTab
        ? _text(booking["session_type"], fallback: "Photography Booking")
        : _text(booking["venue_name"], fallback: "Venue Booking");

    final subtitle = photographerTab
        ? "${_text(booking["client_name"])} → ${_text(booking["photographer_name"])}"
        : "${_text(booking["client_name"])} → ${_text(booking["owner_name"])}";

    final date = photographerTab
        ? _formatDate(booking["date"])
        : _formatDate(booking["booking_date"]);

    final time = photographerTab
        ? _formatTime(booking["time"])
        : "${_formatTime(booking["start_time"])} - ${_formatTime(booking["end_time"])}";

    return GestureDetector(
      onTap: () => _openDetails(booking),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: statusColor.withOpacity(.16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.045),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    photographerTab
                        ? Icons.camera_alt_outlined
                        : Icons.location_city_outlined,
                    color: statusColor,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: "Montserrat",
                          color: primaryGreen,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
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
                _statusChip(status),
              ],
            ),
            if (attention.isNotEmpty) ...[
              const SizedBox(height: 12),
              _attentionWrap(attention),
            ],
            const SizedBox(height: 13),
            Row(
              children: [
                _miniInfo(Icons.calendar_today_outlined, date),
                const SizedBox(width: 10),
                _miniInfo(Icons.access_time_rounded, time),
              ],
            ),
            const SizedBox(height: 11),
            Row(
              children: [
                _paymentBadge(
                  label: "Deposit",
                  paid: _isPaid(booking["deposit_paid"]),
                ),
                const SizedBox(width: 8),
                _paymentBadge(
                  label: "Remaining",
                  paid: _isPaid(booking["remaining_paid"]),
                ),
                const Spacer(),
                Text(
                  _money(booking["total_price"]),
                  style: const TextStyle(
                    fontFamily: "Montserrat",
                    color: primaryGreen,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _attentionWrap(List<Map<String, dynamic>> attention) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: attention.map((item) {
          return _attentionBadge(
            label: item["label"]?.toString() ?? "",
            icon: item["icon"] as IconData,
            color: item["color"] as Color,
          );
        }).toList(),
      ),
    );
  }

  Widget _attentionBadge({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: "Montserrat",
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            _statusLabel(status),
            style: TextStyle(
              fontFamily: "Montserrat",
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        decoration: BoxDecoration(
          color: cream,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryGreen, size: 14),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: "Montserrat",
                  color: primaryGreen,
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

  Widget _paymentBadge({
    required String label,
    required bool paid,
  }) {
    final color = paid ? softGreen : gold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "$label: ${paid ? 'Paid' : 'Unpaid'}",
        style: TextStyle(
          fontFamily: "Montserrat",
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                photographerTab
                    ? Icons.camera_alt_outlined
                    : Icons.location_city_outlined,
                color: primaryGreen,
                size: 42,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              photographerTab
                  ? "No photographer bookings"
                  : "No venue bookings",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: "Montserrat",
                color: primaryGreen,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              "Try changing filters or search text.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Montserrat",
                color: Colors.black38,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
