import 'package:flutter/material.dart';

import '../services/admin_venue_service.dart';
import 'admin_user_details_screen.dart';

const Color adminPrimaryGreen = Color(0xFF2F4F46);
const Color adminLightCream = Color(0xFFF5F1EB);
const Color adminSoftGreen = Color(0xFF3E6B5C);
const Color adminGold = Color(0xFFC9A84C);
const Color adminRed = Color(0xFFB84040);
const Color adminGrey = Color(0xFF8A8A8A);

class AdminVenueDetailsScreen extends StatefulWidget {
  final int venueId;

  const AdminVenueDetailsScreen({
    super.key,
    required this.venueId,
  });

  @override
  State<AdminVenueDetailsScreen> createState() =>
      _AdminVenueDetailsScreenState();
}

class _AdminVenueDetailsScreenState extends State<AdminVenueDetailsScreen> {
  bool loading = true;
  bool actionLoading = false;

  Map<String, dynamic>? venue;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => loading = true);

    final result = await AdminVenueService.getVenueDetails(widget.venueId);

    if (!mounted) return;

    setState(() {
      venue = result;
      loading = false;
    });
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  bool _boolValue(dynamic value) {
    return value == true ||
        value == 1 ||
        value == "1" ||
        value?.toString() == "true";
  }

  String _text(dynamic value, {String fallback = "Not set"}) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == "null") return fallback;

    return text;
  }

  String _image(dynamic value) {
    if (value == null) return "";

    final text = value.toString().trim();

    if (text.isEmpty || text == "null") return "";

    return text;
  }

  Future<void> _toggleVisibility() async {
    final v = venue;
    if (v == null) return;

    final current = _text(v["admin_visibility"], fallback: "hidden");
    final next = current == "visible" ? "hidden" : "visible";

    final confirm = await _confirmDialog(
      title: next == "visible" ? "Show Venue?" : "Hide Venue?",
      message: next == "visible"
          ? "This venue will be visible to clients if it is reviewed."
          : "This venue will be hidden from client search and booking.",
      confirmText: next == "visible" ? "Show" : "Hide",
      confirmColor: next == "visible" ? adminSoftGreen : adminGold,
      icon: next == "visible"
          ? Icons.visibility_outlined
          : Icons.visibility_off_outlined,
    );

    if (confirm != true) return;

    setState(() => actionLoading = true);

    final ok = await AdminVenueService.updateVisibility(
      venueId: widget.venueId,
      visibility: next,
    );

    if (!mounted) return;

    setState(() => actionLoading = false);

    if (ok) {
      _showMessage(next == "visible" ? "Venue is visible" : "Venue is hidden");
      _loadDetails();
    } else {
      _showMessage("Failed to update visibility");
    }
  }

  Future<void> _toggleReviewed() async {
    final v = venue;
    if (v == null) return;

    final reviewed = _boolValue(v["venue_reviewed"]);
    final next = !reviewed;

    final confirm = await _confirmDialog(
      title: next ? "Mark Venue Reviewed?" : "Remove Review Status?",
      message: next
          ? "This means admin reviewed this venue information, images, and availability."
          : "This will remove the reviewed status from this venue.",
      confirmText: next ? "Mark Reviewed" : "Remove",
      confirmColor: next ? adminSoftGreen : adminGold,
      icon: next ? Icons.fact_check_outlined : Icons.pending_actions_outlined,
    );

    if (confirm != true) return;

    setState(() => actionLoading = true);

    final ok = await AdminVenueService.updateReviewed(
      venueId: widget.venueId,
      reviewed: next,
    );

    if (!mounted) return;

    setState(() => actionLoading = false);

    if (ok) {
      _showMessage(next ? "Venue marked as reviewed" : "Review status removed");
      _loadDetails();
    } else {
      _showMessage("Failed to update review status");
    }
  }

  Future<void> _toggleFlag() async {
    final v = venue;
    if (v == null) return;

    final flagged = _boolValue(v["venue_flagged"]);

    if (flagged) {
      final confirm = await _confirmDialog(
        title: "Remove Venue Flag?",
        message: "This venue will no longer be marked as needing admin review.",
        confirmText: "Remove Flag",
        confirmColor: adminSoftGreen,
        icon: Icons.outlined_flag_rounded,
      );

      if (confirm != true) return;

      setState(() => actionLoading = true);

      final ok = await AdminVenueService.updateFlag(
        venueId: widget.venueId,
        flagged: false,
      );

      if (!mounted) return;

      setState(() => actionLoading = false);

      if (ok) {
        _showMessage("Venue flag removed");
        _loadDetails();
      } else {
        _showMessage("Failed to remove flag");
      }

      return;
    }

    final reason = await _reasonDialog(
      title: "Flag Venue",
      hint: "Reason, e.g. missing images, unclear location...",
      icon: Icons.flag_outlined,
      color: adminRed,
      buttonText: "Flag",
    );

    if (reason == null || reason.trim().length < 3) return;

    setState(() => actionLoading = true);

    final ok = await AdminVenueService.updateFlag(
      venueId: widget.venueId,
      flagged: true,
      reason: reason.trim(),
    );

    if (!mounted) return;

    setState(() => actionLoading = false);

    if (ok) {
      _showMessage("Venue flagged");
      _loadDetails();
    } else {
      _showMessage("Failed to flag venue");
    }
  }

  Future<void> _openOwnerDetails() async {
    final ownerId = _toInt(venue?["owner_id"]);

    if (ownerId <= 0) {
      _showMessage("Owner user not found");
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminUserDetailsScreen(userId: ownerId),
      ),
    );

    if (!mounted) return;

    _loadDetails();
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
    required IconData icon,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: Row(
          children: [
            Icon(icon, color: confirmColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: adminPrimaryGreen,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Playfair",
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            color: Colors.black.withOpacity(0.62),
            height: 1.35,
            fontFamily: "Playfair",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(
                color: adminGrey,
                fontFamily: "Playfair",
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmText,
              style: TextStyle(
                color: confirmColor,
                fontWeight: FontWeight.bold,
                fontFamily: "Playfair",
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _reasonDialog({
    required String title,
    required String hint,
    required IconData icon,
    required Color color,
    required String buttonText,
  }) async {
    String reason = "";

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: adminPrimaryGreen,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Playfair",
                  ),
                ),
              ),
            ],
          ),
          content: TextField(
            maxLines: 4,
            autofocus: true,
            onChanged: (value) => reason = value,
            style: const TextStyle(
              color: adminPrimaryGreen,
              fontFamily: "Playfair",
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.black.withOpacity(0.35),
                fontFamily: "Playfair",
              ),
              filled: true,
              fillColor: adminLightCream,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: adminGrey,
                  fontFamily: "Playfair",
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final cleaned = reason.trim();
                if (cleaned.length < 3) return;
                Navigator.of(dialogContext).pop(cleaned);
              },
              child: Text(
                buttonText,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Playfair",
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = venue;

    return Scaffold(
      backgroundColor: adminLightCream,
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: adminPrimaryGreen),
            )
          : v == null
              ? const Center(
                  child: Text("Venue not found"),
                )
              : RefreshIndicator(
                  color: adminPrimaryGreen,
                  onRefresh: _loadDetails,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 300,
                        pinned: true,
                        elevation: 0,
                        backgroundColor: adminPrimaryGreen,
                        iconTheme: const IconThemeData(color: Colors.white),
                        actions: [
                          IconButton(
                            onPressed: _loadDetails,
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                        ],
                        flexibleSpace: FlexibleSpaceBar(
                          background: _header(v),
                        ),
                        bottom: _roundedBottom(),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 34),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            if (actionLoading) _actionLoadingBar(),
                            _statusSection(v),
                            const SizedBox(height: 18),
                            _readinessSection(v),
                            const SizedBox(height: 18),
                            _imagesSection(v),
                            const SizedBox(height: 18),
                            _availabilitySection(v),
                            const SizedBox(height: 18),
                            _bookingSection(v),
                            const SizedBox(height: 18),
                            _adminControlsSection(v),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _header(Map<String, dynamic> v) {
    final name = _text(v["name"], fallback: "Venue");
    final owner = _text(v["owner_name"], fallback: "Owner");
    final location = _text(v["location"], fallback: "");
    final image = _image(v["image_url"]);

    final visible = _text(v["admin_visibility"], fallback: "hidden") == "visible";
    final reviewed = _boolValue(v["venue_reviewed"]);
    final flagged = _boolValue(v["venue_flagged"]);

    Color color = adminSoftGreen;
    if (flagged) {
      color = adminRed;
    } else if (!visible || !reviewed) {
      color = adminGold;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        image.isNotEmpty
            ? Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: adminPrimaryGreen),
              )
            : Container(color: adminPrimaryGreen),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.62),
                adminPrimaryGreen.withOpacity(0.92),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 46),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _topBadge(
                  label: flagged
                      ? "Flagged"
                      : visible && reviewed
                          ? "Ready"
                          : "Needs Review",
                  icon: flagged
                      ? Icons.flag_outlined
                      : visible && reviewed
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_rounded,
                  color: color,
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Playfair",
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  owner,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.78),
                    fontSize: 13,
                    fontFamily: "Playfair",
                  ),
                ),
                if (location.isNotEmpty && location != "Not set") ...[
                  const SizedBox(height: 5),
                  Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 12,
                      fontFamily: "Playfair",
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  PreferredSize _roundedBottom() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(24),
      child: Container(
        height: 26,
        decoration: const BoxDecoration(
          color: adminLightCream,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
      ),
    );
  }

  Widget _topBadge({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.92),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: "Playfair",
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionLoadingBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              color: adminPrimaryGreen,
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 10),
          Text(
            "Updating venue...",
            style: TextStyle(
              color: adminPrimaryGreen,
              fontWeight: FontWeight.bold,
              fontFamily: "Playfair",
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusSection(Map<String, dynamic> v) {
    final visible = _text(v["admin_visibility"], fallback: "hidden") == "visible";
    final reviewed = _boolValue(v["venue_reviewed"]);
    final flagged = _boolValue(v["venue_flagged"]);
    final flagReason = _text(v["venue_flag_reason"], fallback: "");

    return _section(
      title: "Venue Status",
      icon: Icons.admin_panel_settings_outlined,
      children: [
        _statusHeader(
          title: visible && reviewed
              ? "Visible to Clients"
              : "Not Visible to Clients",
          subtitle: visible && reviewed
              ? "This venue can appear in client search and booking."
              : "Venue appears to clients only when it is reviewed and visible.",
          icon: visible && reviewed
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: visible && reviewed ? adminSoftGreen : adminGold,
        ),
        if (flagged && flagReason.isNotEmpty) ...[
          const SizedBox(height: 10),
          _reasonBox("Flag reason", flagReason, adminRed),
        ],
      ],
    );
  }

  Widget _readinessSection(Map<String, dynamic> v) {
    final missing = List<dynamic>.from(v["missing"] ?? []);

    final price = _text(v["price_per_hour"], fallback: "0");
    final location = _text(v["location"], fallback: "Not set");

    return _section(
      title: "Venue Readiness",
      icon: Icons.fact_check_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: _metricBox(
                "Price/hr",
                "\$$price",
                Icons.payments_outlined,
                adminPrimaryGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricBox(
                "Missing",
                missing.length.toString(),
                Icons.warning_amber_rounded,
                missing.isEmpty ? adminSoftGreen : adminGold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _plainInfo("Location", location),
        if (missing.isNotEmpty) ...[
          const SizedBox(height: 10),
          _reasonBox(
            "Missing",
            missing.join(", "),
            adminGold,
          ),
        ],
      ],
    );
  }

  Widget _imagesSection(Map<String, dynamic> v) {
    final images = List<dynamic>.from(v["images"] ?? []);
    final imagesCount = _toInt(v["images_count"]);

    return _section(
      title: "Images",
      icon: Icons.image_outlined,
      children: [
        _statusHeader(
          title: imagesCount > 0 ? "Images Available" : "No Images",
          subtitle: imagesCount > 0
              ? "$imagesCount image(s) uploaded for this venue."
              : "Venue should have at least one clear image before being visible.",
          icon: imagesCount > 0 ? Icons.image_outlined : Icons.image_not_supported_outlined,
          color: imagesCount > 0 ? adminSoftGreen : adminGold,
        ),
        if (images.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 82,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (_, index) {
                final img = Map<String, dynamic>.from(images[index]);
                final url = _image(img["image_url"]);

                return Container(
                  width: 92,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: adminLightCream,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: url.isNotEmpty
                        ? Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              color: adminGrey,
                            ),
                          )
                        : const Icon(
                            Icons.image_outlined,
                            color: adminGrey,
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _availabilitySection(Map<String, dynamic> v) {
    final availability = List<dynamic>.from(v["availability"] ?? []);
    final availabilityCount = _toInt(v["availability_count"]);

    return _section(
      title: "Availability",
      icon: Icons.event_available_outlined,
      children: [
        _statusHeader(
          title: availabilityCount > 0 ? "Availability Added" : "No Availability",
          subtitle: availabilityCount > 0
              ? "$availabilityCount availability slot(s) found."
              : "Venue owner should add availability before this venue is useful for booking.",
          icon: availabilityCount > 0
              ? Icons.event_available_outlined
              : Icons.event_busy_outlined,
          color: availabilityCount > 0 ? adminSoftGreen : adminGold,
        ),
        if (availability.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...availability.take(3).map((item) {
            final a = Map<String, dynamic>.from(item);
            final booked = _boolValue(a["is_booked"]);

            return _plainInfo(
              "${_text(a["date"])} · ${_text(a["start_time"])} - ${_text(a["end_time"])}",
              booked ? "Booked" : "Free",
            );
          }),
        ],
      ],
    );
  }

  Widget _bookingSection(Map<String, dynamic> v) {
    final booking = Map<String, dynamic>.from(v["booking_summary"] ?? {});
    final rating = Map<String, dynamic>.from(v["rating_summary"] ?? {});

    return _section(
      title: "Bookings & Ratings",
      icon: Icons.insights_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: _metricBox(
                "Bookings",
                _toInt(booking["total"]).toString(),
                Icons.event_note_outlined,
                adminPrimaryGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricBox(
                "Completed",
                _toInt(booking["completed"]).toString(),
                Icons.check_circle_outline,
                adminSoftGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricBox(
                "Rating",
                _toDouble(rating["average"]).toStringAsFixed(1),
                Icons.star_outline_rounded,
                adminGold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _adminControlsSection(Map<String, dynamic> v) {
    final visible = _text(v["admin_visibility"], fallback: "hidden") == "visible";
    final reviewed = _boolValue(v["venue_reviewed"]);
    final flagged = _boolValue(v["venue_flagged"]);

    return _section(
      title: "Admin Controls",
      icon: Icons.admin_panel_settings_outlined,
      children: [
        _actionRow(
          icon: visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          title: visible ? "Hide Venue" : "Show Venue",
          subtitle: visible
              ? "Hide this venue from client search and booking"
              : "Allow this venue to appear after review approval",
          color: visible ? adminGold : adminSoftGreen,
          onTap: actionLoading ? () {} : _toggleVisibility,
        ),
        _actionRow(
          icon: reviewed ? Icons.pending_actions_outlined : Icons.fact_check_outlined,
          title: reviewed ? "Remove Reviewed Status" : "Mark Venue Reviewed",
          subtitle: reviewed
              ? "Remove admin review approval from this venue"
              : "Confirm that venue info, images and availability were checked",
          color: reviewed ? adminGold : adminSoftGreen,
          onTap: actionLoading ? () {} : _toggleReviewed,
        ),
        _actionRow(
          icon: flagged ? Icons.outlined_flag_rounded : Icons.flag_outlined,
          title: flagged ? "Remove Venue Flag" : "Flag Venue",
          subtitle: flagged
              ? "Remove internal warning from this venue"
              : "Mark this venue as needing admin attention",
          color: flagged ? adminSoftGreen : adminRed,
          onTap: actionLoading ? () {} : _toggleFlag,
        ),
        _actionRow(
          icon: Icons.account_circle_outlined,
          title: "Open Owner Details",
          subtitle: "Go to owner account controls, notes, messages and logs",
          color: adminPrimaryGreen,
          onTap: _openOwnerDetails,
        ),
      ],
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: adminPrimaryGreen, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: adminPrimaryGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Playfair",
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: adminPrimaryGreen.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _statusHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          _iconBox(icon, color),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Playfair",
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.45),
                    fontSize: 12,
                    height: 1.25,
                    fontFamily: "Playfair",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reasonBox(String title, String reason, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        "$title: $reason",
        style: TextStyle(
          color: color,
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          height: 1.35,
          fontFamily: "Playfair",
        ),
      ),
    );
  }

Widget _plainInfo(String label, String value) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: 4),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: adminLightCream.withOpacity(0.55),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.black.withOpacity(0.42),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: "Playfair",
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          softWrap: true,
          overflow: TextOverflow.visible,
          style: const TextStyle(
            color: adminPrimaryGreen,
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            height: 1.35,
            fontFamily: "Playfair",
          ),
        ),
      ],
    ),
  );
}
  Widget _metricBox(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: "Playfair",
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black.withOpacity(0.42),
              fontSize: 10.5,
              fontFamily: "Playfair",
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _iconBox(icon, color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Playfair",
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.42),
                      fontSize: 12,
                      height: 1.25,
                      fontFamily: "Playfair",
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.black.withOpacity(0.25),
              size: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: adminPrimaryGreen,
      ),
    );
  }
}