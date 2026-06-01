import 'dart:async';
import 'package:flutter/material.dart';

import '../services/admin_venue_service.dart';
import 'admin_venue_details_screen.dart';

const Color adminPrimaryGreen = Color(0xFF2F4F46);
const Color adminLightCream = Color(0xFFF5F1EB);
const Color adminSoftGreen = Color(0xFF3E6B5C);
const Color adminGold = Color(0xFFC9A84C);
const Color adminRed = Color(0xFFB84040);
const Color adminGrey = Color(0xFF8A8A8A);

class AdminManageVenuesScreen extends StatefulWidget {
  const AdminManageVenuesScreen({super.key});

  @override
  State<AdminManageVenuesScreen> createState() =>
      _AdminManageVenuesScreenState();
}

class _AdminManageVenuesScreenState extends State<AdminManageVenuesScreen> {
  bool loading = true;

  Map<String, dynamic> summary = {};
  List<dynamic> venues = [];

  String selectedFilter = "all";

  Timer? _debounce;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVenues();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVenues() async {
    setState(() => loading = true);

    final result = await AdminVenueService.getVenues(
      q: searchController.text.trim(),
      filter: selectedFilter,
    );

    if (!mounted) return;

    setState(() {
      summary = Map<String, dynamic>.from(result["summary"] ?? {});
      venues = List<dynamic>.from(result["venues"] ?? []);
      loading = false;
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 450), () {
      _loadVenues();
    });

    setState(() {});
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

  Future<void> _openVenueDetails(dynamic venue) async {
    final id = _toInt(venue["id"]);

    if (id <= 0) {
      _showMessage("Invalid venue id");
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminVenueDetailsScreen(venueId: id),
      ),
    );

    if (!mounted) return;

    _loadVenues();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: adminLightCream,
      body: RefreshIndicator(
        color: adminPrimaryGreen,
        onRefresh: _loadVenues,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 215,
              pinned: true,
              elevation: 0,
              backgroundColor: adminPrimaryGreen,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  onPressed: _loadVenues,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _header(),
              ),
              bottom: _roundedBottom(),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 34),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _summaryCard(),
                  const SizedBox(height: 16),
                  _searchBox(),
                  const SizedBox(height: 14),
                  _simpleFilters(),
                  const SizedBox(height: 20),
                  _listHeader(),
                  const SizedBox(height: 12),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 45),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: adminPrimaryGreen,
                        ),
                      ),
                    )
                  else if (venues.isEmpty)
                    _emptyCard("No venues found")
                  else
                    ...venues.map((venue) => _venueCard(venue)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF25463D), adminSoftGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.location_city_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "Venues Management",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Playfair",
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Review venue readiness, visibility and quality",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 13,
                  fontFamily: "Playfair",
                ),
              ),
            ],
          ),
        ),
      ),
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

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: adminPrimaryGreen.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              title: "Venues",
              value: _toInt(summary["total"]).toString(),
              icon: Icons.location_city_outlined,
              color: adminPrimaryGreen,
            ),
          ),
          _summaryDivider(),
          Expanded(
            child: _summaryItem(
              title: "Visible",
              value: _toInt(summary["visible"]).toString(),
              icon: Icons.visibility_outlined,
              color: adminSoftGreen,
            ),
          ),
          _summaryDivider(),
          Expanded(
            child: _summaryItem(
              title: "Hidden",
              value: _toInt(summary["hidden"]).toString(),
              icon: Icons.visibility_off_outlined,
              color: adminGold,
            ),
          ),
          _summaryDivider(),
          Expanded(
            child: _summaryItem(
              title: "Needs",
              value: _toInt(summary["needs_attention"]).toString(),
              icon: Icons.warning_amber_rounded,
              color: adminRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryDivider() {
    return Container(
      width: 1,
      height: 45,
      color: Colors.black.withOpacity(0.06),
    );
  }

  Widget _summaryItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 7),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 19,
            fontWeight: FontWeight.bold,
            fontFamily: "Playfair",
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.black.withOpacity(0.43),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            fontFamily: "Playfair",
          ),
        ),
      ],
    );
  }

  Widget _searchBox() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: adminPrimaryGreen.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: searchController,
          onChanged: _onSearchChanged,
          onSubmitted: (_) => _loadVenues(),
          style: const TextStyle(
            color: adminPrimaryGreen,
            fontFamily: "Playfair",
            fontSize: 14,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            icon: const Icon(Icons.search_rounded, color: adminPrimaryGreen),
            hintText: "Search venues by name, owner, or location",
            hintStyle: TextStyle(
              color: Colors.black.withOpacity(0.35),
              fontFamily: "Playfair",
              fontSize: 13,
            ),
            suffixIcon: searchController.text.trim().isEmpty
                ? IconButton(
                    onPressed: _loadVenues,
                    icon: const Icon(Icons.refresh_rounded),
                    color: adminGrey,
                  )
                : IconButton(
                    onPressed: () {
                      searchController.clear();
                      _loadVenues();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded),
                    color: adminGrey,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _simpleFilters() {
    return Row(
      children: [
        Expanded(
          child: _filterChip(
            label: "All Venues",
            icon: Icons.apps_rounded,
            value: "all",
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _filterChip(
            label: "Needs Attention",
            icon: Icons.warning_amber_rounded,
            value: "needs_attention",
          ),
        ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required IconData icon,
    required String value,
  }) {
    final selected = selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() => selectedFilter = value);
        _loadVenues();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? adminPrimaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? adminPrimaryGreen
                : adminPrimaryGreen.withOpacity(0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: adminPrimaryGreen.withOpacity(selected ? 0.13 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : adminPrimaryGreen,
              size: 17,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : adminPrimaryGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Playfair",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listHeader() {
    return Row(
      children: [
        const Text(
          "Venues",
          style: TextStyle(
            color: Color(0xFF1E1E1E),
            fontSize: 19,
            fontWeight: FontWeight.bold,
            fontFamily: "Playfair",
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: adminPrimaryGreen.withOpacity(0.09),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "${venues.length} results",
            style: const TextStyle(
              color: adminPrimaryGreen,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: "Playfair",
            ),
          ),
        ),
      ],
    );
  }

  Widget _venueCard(dynamic venue) {
    final v = Map<String, dynamic>.from(venue);

    final name = _text(v["name"], fallback: "Venue");
    final owner = _text(v["owner_name"], fallback: "Owner");
    final location = _text(v["location"], fallback: "");
    final image = _image(v["image_url"]);

    final visibility = _text(v["admin_visibility"], fallback: "hidden");
    final visible = visibility == "visible";
    final reviewed = _boolValue(v["venue_reviewed"]);
    final flagged = _boolValue(v["venue_flagged"]);
    final needsAttention = _boolValue(v["needs_attention"]);

    final imagesCount = _toInt(v["images_count"]);
    final availabilityCount = _toInt(v["availability_count"]);

    final booking = Map<String, dynamic>.from(v["booking_summary"] ?? {});
    final rating = Map<String, dynamic>.from(v["rating_summary"] ?? {});

    final totalBookings = _toInt(booking["total"]);
    final ratingAvg = _toDouble(rating["average"]);
    final reviewsCount = _toInt(rating["reviews_count"]);

    Color sideColor = adminSoftGreen;

    if (flagged) {
      sideColor = adminRed;
    } else if (needsAttention || !visible || !reviewed) {
      sideColor = adminGold;
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _openVenueDetails(v),
        child: Container(
          margin: const EdgeInsets.only(bottom: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: sideColor.withOpacity(0.06),
                blurRadius: 13,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: sideColor,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(22),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _venueImage(image, sideColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: adminPrimaryGreen,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: "Playfair",
                                          ),
                                        ),
                                      ),
                                      _statusBadge(
                                        needsAttention
                                            ? "Needs Attention"
                                            : "Ready",
                                        needsAttention
                                            ? adminGold
                                            : adminSoftGreen,
                                        needsAttention
                                            ? Icons.warning_amber_rounded
                                            : Icons.check_circle_outline,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    owner,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.50),
                                      fontSize: 12,
                                      fontFamily: "Playfair",
                                    ),
                                  ),
                                  if (location.isNotEmpty &&
                                      location != "Not set") ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.black.withOpacity(0.38),
                                        fontSize: 11,
                                        fontFamily: "Playfair",
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _smallBadge(
                                        visible ? "Visible" : "Hidden",
                                        visible ? adminSoftGreen : adminGold,
                                        visible
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      _smallBadge(
                                        reviewed ? "Reviewed" : "Not Reviewed",
                                        reviewed ? adminSoftGreen : adminGold,
                                        reviewed
                                            ? Icons.fact_check_outlined
                                            : Icons.pending_actions_outlined,
                                      ),
                                      if (flagged)
                                        _smallBadge(
                                          "Flagged",
                                          adminRed,
                                          Icons.flag_outlined,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 13),
                        Row(
                          children: [
                            Expanded(
                              child: _miniStat(
                                "Images",
                                imagesCount.toString(),
                                Icons.image_outlined,
                                imagesCount > 0 ? adminSoftGreen : adminGold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _miniStat(
                                "Availability",
                                availabilityCount.toString(),
                                Icons.event_available_outlined,
                                availabilityCount > 0
                                    ? adminSoftGreen
                                    : adminGold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _miniStat(
                                "Bookings",
                                totalBookings.toString(),
                                Icons.event_note_outlined,
                                adminPrimaryGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _miniStat(
                                "Rating",
                                ratingAvg.toStringAsFixed(1),
                                Icons.star_outline_rounded,
                                adminGold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _miniStat(
                                "Reviews",
                                reviewsCount.toString(),
                                Icons.rate_review_outlined,
                                adminPrimaryGreen,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _cardAction(
                                title: "Details",
                                icon: Icons.visibility_outlined,
                                color: adminPrimaryGreen,
                                onTap: () => _openVenueDetails(v),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _venueImage(String image, Color color) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: adminPrimaryGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: image.isNotEmpty
            ? Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.location_city_outlined,
                  color: color,
                ),
              )
            : Icon(
                Icons.location_city_outlined,
                color: color,
              ),
      ),
    );
  }

  Widget _statusBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              fontFamily: "Playfair",
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontFamily: "Playfair",
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              fontFamily: "Playfair",
            ),
          ),
          const SizedBox(height: 1),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black.withOpacity(0.40),
              fontSize: 9.5,
              fontFamily: "Playfair",
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardAction({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.09),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Playfair",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.black.withOpacity(0.45),
          fontFamily: "Playfair",
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: adminPrimaryGreen,
        content: Text(message),
      ),
    );
  }
}