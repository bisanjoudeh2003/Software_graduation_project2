import 'package:flutter/material.dart';
import '../services/venue_service.dart';
import '../services/auth_service.dart';
import 'venue_owner_home.dart';
import 'add_venue_page.dart';
import 'venue_owner_bottom_nav.dart';
import 'viewvenuepage.dart';
import 'edit_venue_page.dart';

class MyVenuesPage extends StatefulWidget {
  const MyVenuesPage({super.key});

  @override
  State<MyVenuesPage> createState() => _MyVenuesPageState();
}

class _MyVenuesPageState extends State<MyVenuesPage> {
  static const Color primaryGreen = Color(0xFF2F4F3E);
  static const Color midGreen = Color(0xFF3D6B57);
  static const Color background = Color(0xFFF6F4EE);
  static const Color gold = Color(0xFFC9A84C);
  static const Color red = Color(0xFFB84040);

  List allVenues = [];
  List venues = [];
  bool loading = true;

  bool searching = false;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadVenues();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  bool _boolValue(dynamic value) {
    return value == true ||
        value == 1 ||
        value == "1" ||
        value?.toString() == "true";
  }

  String _cleanText(dynamic value, {String fallback = ""}) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == "null") return fallback;

    return text;
  }

  String _venueStatusTitle(Map<String, dynamic> venue) {
    final visibility = _cleanText(
      venue["admin_visibility"],
      fallback: "hidden",
    );

    final reviewed = _boolValue(venue["venue_reviewed"]);
    final flagged = _boolValue(venue["venue_flagged"]);

    if (flagged) return "Needs Admin Review";

    if (!reviewed) return "Under Admin Review";

    if (reviewed && visibility == "hidden") {
      return "Reviewed, Still Hidden";
    }

    return "Approved & Visible";
  }

  String _venueStatusMessage(Map<String, dynamic> venue) {
    final visibility = _cleanText(
      venue["admin_visibility"],
      fallback: "hidden",
    );

    final reviewed = _boolValue(venue["venue_reviewed"]);
    final flagged = _boolValue(venue["venue_flagged"]);
    final reason = _cleanText(venue["venue_flag_reason"]);

    if (flagged) {
      return reason.isNotEmpty
          ? reason
          : "This venue needs admin attention. Please check its information, images, location, and availability.";
    }

    if (!reviewed) {
      return "This venue is not visible to clients yet. It will appear after admin review and approval.";
    }

    if (reviewed && visibility == "hidden") {
      return "This venue was reviewed, but it is still hidden from clients.";
    }

    return "This venue is visible to clients and available in search.";
  }

  Color _venueStatusColor(Map<String, dynamic> venue) {
    final visibility = _cleanText(
      venue["admin_visibility"],
      fallback: "hidden",
    );

    final reviewed = _boolValue(venue["venue_reviewed"]);
    final flagged = _boolValue(venue["venue_flagged"]);

    if (flagged) return red;
    if (!reviewed || visibility == "hidden") return gold;

    return midGreen;
  }

  IconData _venueStatusIcon(Map<String, dynamic> venue) {
    final visibility = _cleanText(
      venue["admin_visibility"],
      fallback: "hidden",
    );

    final reviewed = _boolValue(venue["venue_reviewed"]);
    final flagged = _boolValue(venue["venue_flagged"]);

    if (flagged) return Icons.flag_outlined;
    if (!reviewed) return Icons.pending_actions_rounded;
    if (reviewed && visibility == "hidden") {
      return Icons.visibility_off_outlined;
    }

    return Icons.verified_outlined;
  }

  bool _venueNeedsAttention(Map<String, dynamic> venue) {
    final visibility = _cleanText(
      venue["admin_visibility"],
      fallback: "hidden",
    );

    final reviewed = _boolValue(venue["venue_reviewed"]);
    final flagged = _boolValue(venue["venue_flagged"]);

    return visibility != "visible" || !reviewed || flagged;
  }

  Future<void> loadVenues() async {
    try {
      String? token = await AuthService.getToken();

      if (token == null) {
        setState(() => loading = false);
        return;
      }

      final data = await VenueService.getOwnerVenues(token);

      if (!mounted) return;

      setState(() {
        allVenues = data;
        venues = data;
        loading = false;
      });
    } catch (e) {
      debugPrint("LOAD VENUES ERROR: $e");

      if (!mounted) return;

      setState(() => loading = false);
    }
  }

  void searchVenues(String query) {
    if (query.isEmpty) {
      setState(() => venues = allVenues);
      return;
    }

    final q = query.toLowerCase();

    setState(() {
      venues = allVenues.where((v) {
        final name = v["name"]?.toString().toLowerCase() ?? "";
        final location = v["location"]?.toString().toLowerCase() ?? "";
        return name.contains(q) || location.contains(q);
      }).toList();
    });
  }

  Future<void> deleteVenue(int id) async {
    String? token = await AuthService.getToken();

    if (token == null) return;

    await VenueService.deleteVenue(token, id);
    await loadVenues();

    if (searchController.text.isNotEmpty) {
      searchVenues(searchController.text);
    }
  }

  int get attentionCount {
    int count = 0;

    for (final v in allVenues) {
      final venue = Map<String, dynamic>.from(v);

      if (_venueNeedsAttention(venue)) count++;
    }

    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: const VenueOwnerBottomNav(currentIndex: 1),
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const VenueOwnerHome(),
            ),
          ),
        ),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: searching
              ? TextField(
                  key: const ValueKey("search"),
                  controller: searchController,
                  autofocus: true,
                  onChanged: searchVenues,
                  style: const TextStyle(fontFamily: "Montserrat"),
                  decoration: InputDecoration(
                    hintText: "Search venues...",
                    hintStyle: const TextStyle(fontFamily: "Montserrat"),
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        searchController.clear();

                        setState(() {
                          searching = false;
                          venues = allVenues;
                        });
                      },
                    ),
                  ),
                )
              : const Text(
                  "My Venues",
                  key: ValueKey("title"),
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
        ),
        centerTitle: true,
        actions: [
          if (!searching)
            IconButton(
              icon: const Icon(
                Icons.search,
                color: Colors.black,
                size: 26,
              ),
              onPressed: () => setState(() => searching = true),
            ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: primaryGreen),
            )
          : venues.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_city_outlined,
                        size: 60,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        searchController.text.isNotEmpty
                            ? "No results found"
                            : "No venues yet",
                        style: const TextStyle(
                          fontFamily: "Montserrat",
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: primaryGreen,
                  onRefresh: loadVenues,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                    children: [
                      if (attentionCount > 0) _summaryWarningCard(),
                      ...venues.map((item) {
                        final venue = Map<String, dynamic>.from(item);
                        return venueCard(venue);
                      }),
                    ],
                  ),
                ),
      bottomSheet: Container(
        decoration: BoxDecoration(
          color: background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 12,
              offset: const Offset(0, -3),
            )
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: const Icon(
              Icons.add_circle_outline,
              size: 20,
              color: Colors.white,
            ),
            label: const Text(
              "Add New Venue",
              style: TextStyle(
                fontFamily: "Montserrat",
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddVenuePage(),
                ),
              ).then((_) => loadVenues());
            },
          ),
        ),
      ),
    );
  }

  Widget _summaryWarningCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: gold.withOpacity(.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: gold.withOpacity(.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: gold.withOpacity(.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: gold,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              attentionCount == 1
                  ? "1 venue needs admin review or approval."
                  : "$attentionCount venues need admin review or approval.",
              style: const TextStyle(
                fontFamily: "Montserrat",
                color: primaryGreen,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget venueCard(Map<String, dynamic> venue) {
    final image = venue["image_url"]?.toString() ?? "";
    final name = venue["name"]?.toString() ?? "";
    final location = venue["location"]?.toString() ?? "";

    final rawPrice =
        double.tryParse(venue["price_per_hour"]?.toString() ?? "0") ?? 0;

    final price = rawPrice == rawPrice.truncate()
        ? rawPrice.toInt().toString()
        : rawPrice.toStringAsFixed(2);

    final rating = double.tryParse(venue["rating_avg"].toString())
            ?.toStringAsFixed(1) ??
        "0.0";

    final reviews = venue["reviews_count"]?.toString() ?? "0";

    final statusColor = _venueStatusColor(venue);
    final statusTitle = _venueStatusTitle(venue);
    final statusMessage = _venueStatusMessage(venue);
    final statusIcon = _venueStatusIcon(venue);

    final visibility = _cleanText(
      venue["admin_visibility"],
      fallback: "hidden",
    );

    final reviewed = _boolValue(venue["venue_reviewed"]);
    final flagged = _boolValue(venue["venue_flagged"]);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: statusColor.withOpacity(.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: image.isNotEmpty
                    ? Image.network(
                        image,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: _statusChip(
                  statusTitle,
                  statusIcon,
                  statusColor,
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "\$$price/hr",
                    style: const TextStyle(
                      fontFamily: "Montserrat",
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: "Montserrat",
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                          fontFamily: "Montserrat",
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      rating,
                      style: const TextStyle(
                        fontFamily: "Montserrat",
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      "($reviews)",
                      style: TextStyle(
                        fontFamily: "Montserrat",
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: _adminStatusBox(
              title: statusTitle,
              message: statusMessage,
              color: statusColor,
              icon: statusIcon,
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _miniBadge(
                  visibility == "visible" ? "Visible" : "Hidden",
                  visibility == "visible"
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  visibility == "visible" ? midGreen : gold,
                ),
                _miniBadge(
                  reviewed ? "Reviewed" : "Not Reviewed",
                  reviewed
                      ? Icons.fact_check_outlined
                      : Icons.pending_actions_outlined,
                  reviewed ? midGreen : gold,
                ),
                if (flagged)
                  _miniBadge(
                    "Flagged",
                    Icons.flag_outlined,
                    red,
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    Icons.edit_rounded,
                    "Edit",
                    primaryGreen,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditVenuePage(venue: venue),
                        ),
                      ).then((result) {
                        if (result == true) {
                          loadVenues();
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionBtn(
                    Icons.delete_outline_rounded,
                    "Delete",
                    Colors.red,
                    () {
                      _confirmDelete(venue);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionBtn(
                    Icons.visibility_rounded,
                    "View",
                    midGreen,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewVenuePage(venue: venue),
                        ),
                      ).then((_) => loadVenues());
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String text, IconData icon, Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: "Montserrat",
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminStatusBox({
    required String title,
    required String message,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    color: Colors.black.withOpacity(.55),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontFamily: "Montserrat",
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> venue) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "Delete Venue",
          style: TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "Are you sure you want to delete this venue?",
          style: TextStyle(fontFamily: "Montserrat"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(
                fontFamily: "Montserrat",
                color: Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteVenue(venue["id"]);
            },
            child: const Text(
              "Delete",
              style: TextStyle(
                fontFamily: "Montserrat",
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(color: Colors.grey[200]),
      child: const Icon(
        Icons.image_outlined,
        size: 40,
        color: Colors.grey,
      ),
    );
  }

  Widget _actionBtn(
    IconData icon,
    String text,
    Color color,
    VoidCallback onTap,
  ) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onTap,
        child: FittedBox(
          child: Row(
            children: [
              Icon(icon, size: 15),
              const SizedBox(width: 5),
              Text(
                text,
                style: const TextStyle(
                  fontFamily: "Montserrat",
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}