import 'dart:async';
import 'package:flutter/material.dart';

import '../services/admin_community_service.dart';
import 'admin_community_post_details_screen.dart';

const Color adminPrimaryGreen = Color(0xFF2F4F46);
const Color adminLightCream = Color(0xFFF5F1EB);
const Color adminSoftGreen = Color(0xFF3E6B5C);
const Color adminGold = Color(0xFFC9A84C);
const Color adminRed = Color(0xFFB84040);
const Color adminGrey = Color(0xFF8A8A8A);

class AdminManageCommunityScreen extends StatefulWidget {
  const AdminManageCommunityScreen({super.key});

  @override
  State<AdminManageCommunityScreen> createState() =>
      _AdminManageCommunityScreenState();
}

class _AdminManageCommunityScreenState
    extends State<AdminManageCommunityScreen> {
  bool loading = true;

  Map<String, dynamic> summary = {};
  List<dynamic> posts = [];

  String selectedFilter = "pending";

  Timer? _debounce;
  final TextEditingController searchController = TextEditingController();

  final List<Map<String, dynamic>> filters = const [
    {
      "label": "Pending",
      "value": "pending",
      "icon": Icons.pending_actions_rounded,
    },
    {
      "label": "Approved",
      "value": "approved",
      "icon": Icons.check_circle_outline,
    },
    {
      "label": "Reported",
      "value": "reported",
      "icon": Icons.report_gmailerrorred_outlined,
    },
    {
      "label": "Rejected",
      "value": "rejected",
      "icon": Icons.cancel_outlined,
    },
    {
      "label": "Hidden",
      "value": "hidden",
      "icon": Icons.visibility_off_outlined,
    },
    {
      "label": "All",
      "value": "all",
      "icon": Icons.apps_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() => loading = true);

    final result = await AdminCommunityService.getPosts(
      q: searchController.text.trim(),
      filter: selectedFilter,
    );

    if (!mounted) return;

    setState(() {
      summary = Map<String, dynamic>.from(result["summary"] ?? {});
      posts = List<dynamic>.from(result["posts"] ?? []);
      loading = false;
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 450), () {
      _loadPosts();
    });

    setState(() {});
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
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

  Future<void> _openPostDetails(dynamic post) async {
    final p = Map<String, dynamic>.from(post);
    final id = _toInt(p["id"]);

    if (id <= 0) {
      _showMessage("Invalid post id");
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminCommunityPostDetailsScreen(postId: id),
      ),
    );

    if (!mounted) return;

    _loadPosts();
  }

  Color _statusColor(String status, bool hidden, int reports) {
    if (hidden) return adminGrey;
    if (reports > 0) return adminRed;

    if (status == "approved") return adminSoftGreen;
    if (status == "rejected") return adminRed;
    if (status == "pending") return adminGold;

    return adminPrimaryGreen;
  }

  IconData _statusIcon(String status, bool hidden, int reports) {
    if (hidden) return Icons.visibility_off_outlined;
    if (reports > 0) return Icons.report_gmailerrorred_outlined;

    if (status == "approved") return Icons.check_circle_outline;
    if (status == "rejected") return Icons.cancel_outlined;
    if (status == "pending") return Icons.pending_actions_rounded;

    return Icons.article_outlined;
  }

  String _statusLabel(String status, bool hidden, int reports) {
    if (hidden) return "Hidden";
    if (reports > 0) return "Reported";

    if (status == "approved") return "Approved";
    if (status == "rejected") return "Rejected";
    if (status == "pending") return "Pending";

    return "Post";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: adminLightCream,
      body: RefreshIndicator(
        color: adminPrimaryGreen,
        onRefresh: _loadPosts,
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
                  onPressed: _loadPosts,
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
                  _filtersList(),
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
                  else if (posts.isEmpty)
                    _emptyCard("No community posts found")
                  else
                    ...posts.map((post) => _postCard(post)),
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
                  Icons.forum_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "Community Management",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Playfair",
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Approve posts, review reports and moderate content",
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
              title: "Pending",
              value: _toInt(summary["pending"]).toString(),
              icon: Icons.pending_actions_rounded,
              color: adminGold,
            ),
          ),
          _summaryDivider(),
          Expanded(
            child: _summaryItem(
              title: "Approved",
              value: _toInt(summary["approved"]).toString(),
              icon: Icons.check_circle_outline,
              color: adminSoftGreen,
            ),
          ),
          _summaryDivider(),
          Expanded(
            child: _summaryItem(
              title: "Reported",
              value: _toInt(summary["reported"]).toString(),
              icon: Icons.report_gmailerrorred_outlined,
              color: adminRed,
            ),
          ),
          _summaryDivider(),
          Expanded(
            child: _summaryItem(
              title: "Hidden",
              value: _toInt(summary["hidden"]).toString(),
              icon: Icons.visibility_off_outlined,
              color: adminGrey,
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
          onSubmitted: (_) => _loadPosts(),
          style: const TextStyle(
            color: adminPrimaryGreen,
            fontFamily: "Playfair",
            fontSize: 14,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            icon: const Icon(Icons.search_rounded, color: adminPrimaryGreen),
            hintText: "Search posts, category, photographer...",
            hintStyle: TextStyle(
              color: Colors.black.withOpacity(0.35),
              fontFamily: "Playfair",
              fontSize: 13,
            ),
            suffixIcon: searchController.text.trim().isEmpty
                ? IconButton(
                    onPressed: _loadPosts,
                    icon: const Icon(Icons.refresh_rounded),
                    color: adminGrey,
                  )
                : IconButton(
                    onPressed: () {
                      searchController.clear();
                      _loadPosts();
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

  Widget _filtersList() {
    return SizedBox(
      height: 43,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (_, index) {
          final f = filters[index];
          return _filterChip(
            label: f["label"],
            value: f["value"],
            icon: f["icon"],
          );
        },
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final selected = selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() => selectedFilter = value);
        _loadPosts();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
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
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : adminPrimaryGreen,
              size: 16,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : adminPrimaryGreen,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: "Playfair",
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
          "Community Posts",
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
            "${posts.length} results",
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

  Widget _postCard(dynamic post) {
    final p = Map<String, dynamic>.from(post);

    final title = _text(p["title"], fallback: "Community Post");
    final body = _text(p["body"], fallback: "");
    final category = _text(p["category"], fallback: "general");

    final status = _text(p["approval_status"], fallback: "pending");
    final hidden = _boolValue(p["is_hidden"]);

    final photographer = Map<String, dynamic>.from(p["photographer"] ?? {});
    final photographerName = _text(photographer["name"], fallback: "Photographer");
    final photographerImage = _image(photographer["image"]);

    final stats = Map<String, dynamic>.from(p["stats"] ?? {});
    final likes = _toInt(stats["likes"]);
    final comments = _toInt(stats["comments"]);
    final reports = _toInt(stats["reports"]);
    final media = _toInt(stats["media"]);

    final color = _statusColor(status, hidden, reports);
    final icon = _statusIcon(status, hidden, reports);
    final label = _statusLabel(status, hidden, reports);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _openPostDetails(p),
        child: Container(
          margin: const EdgeInsets.only(bottom: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.06),
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
                    color: color,
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
                            _avatar(photographerImage, color),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
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
                                      _statusBadge(label, color, icon),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    photographerName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.50),
                                      fontSize: 12,
                                      fontFamily: "Playfair",
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.45),
                                      fontSize: 12,
                                      height: 1.25,
                                      fontFamily: "Playfair",
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _smallBadge(
                                        category,
                                        adminPrimaryGreen,
                                        Icons.category_outlined,
                                      ),
                                      if (media > 0)
                                        _smallBadge(
                                          "$media media",
                                          adminSoftGreen,
                                          Icons.perm_media_outlined,
                                        ),
                                      if (reports > 0)
                                        _smallBadge(
                                          "$reports reports",
                                          adminRed,
                                          Icons.report_outlined,
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
                                "Likes",
                                likes.toString(),
                                Icons.favorite_border_rounded,
                                adminRed,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _miniStat(
                                "Comments",
                                comments.toString(),
                                Icons.chat_bubble_outline_rounded,
                                adminPrimaryGreen,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _miniStat(
                                "Reports",
                                reports.toString(),
                                Icons.report_gmailerrorred_outlined,
                                reports > 0 ? adminRed : adminGrey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _cardAction(
                          title: "Review Details",
                          icon: Icons.visibility_outlined,
                          color: adminPrimaryGreen,
                          onTap: () => _openPostDetails(p),
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

  Widget _avatar(String image, Color color) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: adminPrimaryGreen.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.25), width: 2),
      ),
      child: ClipOval(
        child: image.isNotEmpty
            ? Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.person_outline,
                  color: color,
                ),
              )
            : Icon(
                Icons.person_outline,
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
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
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