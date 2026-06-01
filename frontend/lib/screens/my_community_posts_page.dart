import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/community_service.dart';
import 'community_post_details_page.dart';

class MyCommunityPostsPage extends StatefulWidget {
  const MyCommunityPostsPage({super.key});

  @override
  State<MyCommunityPostsPage> createState() => _MyCommunityPostsPageState();
}

class _MyCommunityPostsPageState extends State<MyCommunityPostsPage> {
  static const Color primaryGreen = Color(0xFF2F4F3E);
  static const Color midGreen = Color(0xFF3D6B57);
  static const Color lightGreen = Color(0xFFC1D9CC);
  static const Color paleGreen = Color(0xFFEAF3EE);
  static const Color cream = Color(0xFFF6F4EE);
  static const Color softRed = Color(0xFFD9534F);
  static const Color gold = Color(0xFFC9A84C);
  static const Color grey = Color(0xFF8A8A8A);
  static const Color purple = Color(0xFF7C4DBC);

  bool loading = true;
  List allPosts = [];
  List posts = [];

  String selectedFilter = "all";

  final List<Map<String, dynamic>> filters = const [
    {
      "label": "All",
      "value": "all",
      "icon": Icons.apps_rounded,
    },
    {
      "label": "Pending",
      "value": "pending",
      "icon": Icons.pending_actions_rounded,
    },
    {
      "label": "Approved",
      "value": "approved",
      "icon": Icons.check_circle_outline_rounded,
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
  ];

  @override
  void initState() {
    super.initState();
    loadPosts();
  }

  Future<void> loadPosts() async {
    setState(() => loading = true);

    try {
      final data = await CommunityService.getMyPosts();

      if (!mounted) return;

      setState(() {
        allPosts = data;
        loading = false;
      });

      _applyFilter();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        allPosts = [];
        posts = [];
        loading = false;
      });

      _showMessage(
        e.toString().replaceAll("Exception:", "").trim(),
        isError: true,
      );
    }
  }

  void _applyFilter() {
    List filtered = List.from(allPosts);

    if (selectedFilter == "pending") {
      filtered = filtered.where((post) {
        final p = Map<String, dynamic>.from(post);
        return _approvalStatus(p) == "pending" && !_asBool(p["is_hidden"]);
      }).toList();
    } else if (selectedFilter == "approved") {
      filtered = filtered.where((post) {
        final p = Map<String, dynamic>.from(post);
        return _approvalStatus(p) == "approved" && !_asBool(p["is_hidden"]);
      }).toList();
    } else if (selectedFilter == "rejected") {
      filtered = filtered.where((post) {
        final p = Map<String, dynamic>.from(post);
        return _approvalStatus(p) == "rejected";
      }).toList();
    } else if (selectedFilter == "hidden") {
      filtered = filtered.where((post) {
        final p = Map<String, dynamic>.from(post);
        return _asBool(p["is_hidden"]);
      }).toList();
    }

    setState(() => posts = filtered);
  }

  bool _asBool(dynamic value) {
    return value == true || value == 1 || value == "1" || value == "true";
  }

  int _toInt(dynamic value) {
    return int.tryParse(value?.toString() ?? "0") ?? 0;
  }

  String _cleanText(dynamic value, {String fallback = ""}) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == "null") return fallback;

    return text;
  }

  String _approvalStatus(Map<String, dynamic> post) {
    return _cleanText(
      post["approval_status"],
      fallback: "pending",
    );
  }

  String _formatDate(dynamic raw) {
    final value = raw?.toString() ?? "";

    if (value.isEmpty || value == "null") return "";

    try {
      final d = DateTime.parse(value).toLocal();
      return DateFormat("MMM d, yyyy • h:mm a").format(d);
    } catch (_) {
      return value.length >= 10 ? value.substring(0, 10) : value;
    }
  }

  String _statusTitle(Map<String, dynamic> post) {
    final status = _approvalStatus(post);
    final hidden = _asBool(post["is_hidden"]);

    if (hidden && status == "approved") return "Hidden";
    if (status == "approved") return "Approved";
    if (status == "rejected") return "Rejected";
    return "Pending Review";
  }

  String _statusMessage(Map<String, dynamic> post) {
    final status = _approvalStatus(post);
    final hidden = _asBool(post["is_hidden"]);
    final reason = _cleanText(post["rejection_reason"]);

    if (status == "rejected") {
      return reason.isNotEmpty
          ? "Reason: $reason"
          : "This post was rejected by admin.";
    }

    if (hidden && status == "approved") {
      return "This post was approved but is currently hidden from the community.";
    }

    if (status == "approved") {
      return "This post is visible in the community.";
    }

    return "This post is waiting for admin approval before it appears in the community.";
  }

  Color _statusColor(Map<String, dynamic> post) {
    final status = _approvalStatus(post);
    final hidden = _asBool(post["is_hidden"]);

    if (hidden) return grey;
    if (status == "approved") return midGreen;
    if (status == "rejected") return softRed;

    return gold;
  }

  IconData _statusIcon(Map<String, dynamic> post) {
    final status = _approvalStatus(post);
    final hidden = _asBool(post["is_hidden"]);

    if (hidden) return Icons.visibility_off_outlined;
    if (status == "approved") return Icons.check_circle_outline_rounded;
    if (status == "rejected") return Icons.cancel_outlined;

    return Icons.pending_actions_rounded;
  }

  bool _hasVideo(Map<String, dynamic> post) {
    final media = post["media"];

    if (media is List) {
      for (final item in media) {
        final m = Map<String, dynamic>.from(item);
        final type = _cleanText(m["media_type"]).toLowerCase();
        final url = _cleanText(m["media_url"]).toLowerCase();

        if (type == "video" ||
            url.endsWith(".mp4") ||
            url.endsWith(".mov") ||
            url.endsWith(".webm") ||
            url.endsWith(".avi") ||
            url.endsWith(".mkv")) {
          return true;
        }
      }
    }

    final mediaType = _cleanText(post["media_type"]).toLowerCase();
    final mediaUrl = _cleanText(post["media_url"]).toLowerCase();

    return mediaType == "video" ||
        mediaUrl.endsWith(".mp4") ||
        mediaUrl.endsWith(".mov") ||
        mediaUrl.endsWith(".webm") ||
        mediaUrl.endsWith(".avi") ||
        mediaUrl.endsWith(".mkv");
  }

  String _firstImage(Map<String, dynamic> post) {
    final media = post["media"];

    if (media is List) {
      for (final item in media) {
        final m = Map<String, dynamic>.from(item);
        final type = _cleanText(m["media_type"]).toLowerCase();
        final url = _cleanText(m["media_url"]);

        if (url.isNotEmpty && type != "video") {
          return url;
        }
      }
    }

    final mediaType = _cleanText(post["media_type"]).toLowerCase();
    final mediaUrl = _cleanText(post["media_url"]);

    if (mediaUrl.isNotEmpty && mediaType != "video") return mediaUrl;

    return "";
  }

  int _countByStatus(String status) {
    if (status == "all") return allPosts.length;

    if (status == "hidden") {
      return allPosts.where((item) {
        final p = Map<String, dynamic>.from(item);
        return _asBool(p["is_hidden"]);
      }).length;
    }

    return allPosts.where((item) {
      final p = Map<String, dynamic>.from(item);
      final hidden = _asBool(p["is_hidden"]);
      final approval = _approvalStatus(p);

      if (status == "approved") {
        return approval == "approved" && !hidden;
      }

      if (status == "pending") {
        return approval == "pending" && !hidden;
      }

      return approval == status;
    }).length;
  }

  Future<void> _openApprovedPost(Map<String, dynamic> post) async {
    final status = _approvalStatus(post);
    final hidden = _asBool(post["is_hidden"]);

    if (status != "approved" || hidden) {
      _showMessage(
        "This post is not visible in the community yet.",
        isError: false,
      );
      return;
    }

    final postId = _toInt(post["id"]);
    if (postId <= 0) return;

    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityPostDetailsPage(postId: postId),
      ),
    );

    if (changed == true) {
      loadPosts();
    }
  }

  Future<void> _deletePost(Map<String, dynamic> post) async {
    final postId = _toInt(post["id"]);
    if (postId <= 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            "Delete Post",
            style: TextStyle(
              fontFamily: "Montserrat",
              color: primaryGreen,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            "Are you sure you want to delete this post?",
            style: TextStyle(
              fontFamily: "Montserrat",
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                "Cancel",
                style: TextStyle(
                  fontFamily: "Montserrat",
                  color: Colors.black45,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Delete",
                style: TextStyle(
                  fontFamily: "Montserrat",
                  color: softRed,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await CommunityService.deletePost(postId);
      await loadPosts();

      _showMessage("Post deleted successfully.");
    } catch (e) {
      _showMessage(
        e.toString().replaceAll("Exception:", "").trim(),
        isError: true,
      );
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? softRed : primaryGreen,
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: RefreshIndicator(
        color: primaryGreen,
        onRefresh: loadPosts,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _summaryCard(),
                    const SizedBox(height: 16),
                    _filtersList(),
                    const SizedBox(height: 20),
                    _sectionHeader(),
                    const SizedBox(height: 12),
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: primaryGreen,
                          ),
                        ),
                      )
                    else if (posts.isEmpty)
                      _emptyState()
                    else
                      ...posts.map((item) {
                        final post = Map<String, dynamic>.from(item);
                        return _postCard(post);
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryGreen, midGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
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
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                "My Community Posts",
                style: TextStyle(
                  fontFamily: "Montserrat",
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Track your submitted posts, review status and admin feedback.",
                style: TextStyle(
                  fontFamily: "Montserrat",
                  color: Colors.white.withOpacity(.75),
                  fontSize: 13.5,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.045),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              title: "Pending",
              value: _countByStatus("pending").toString(),
              icon: Icons.pending_actions_rounded,
              color: gold,
            ),
          ),
          _summaryDivider(),
          Expanded(
            child: _summaryItem(
              title: "Approved",
              value: _countByStatus("approved").toString(),
              icon: Icons.check_circle_outline_rounded,
              color: midGreen,
            ),
          ),
          _summaryDivider(),
          Expanded(
            child: _summaryItem(
              title: "Rejected",
              value: _countByStatus("rejected").toString(),
              icon: Icons.cancel_outlined,
              color: softRed,
            ),
          ),
          _summaryDivider(),
          Expanded(
            child: _summaryItem(
              title: "Hidden",
              value: _countByStatus("hidden").toString(),
              icon: Icons.visibility_off_outlined,
              color: grey,
            ),
          ),
        ],
      ),
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
        Icon(icon, color: color, size: 21),
        const SizedBox(height: 6),
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
          style: const TextStyle(
            fontFamily: "Montserrat",
            color: Colors.black45,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _summaryDivider() {
    return Container(
      width: 1,
      height: 44,
      color: Colors.black.withOpacity(.06),
    );
  }

  Widget _filtersList() {
    return SizedBox(
      height: 43,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final item = filters[index];

          return _filterChip(
            label: item["label"],
            value: item["value"],
            icon: item["icon"],
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
        _applyFilter();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? primaryGreen : lightGreen.withOpacity(.55),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : primaryGreen,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: "Montserrat",
                color: selected ? Colors.white : primaryGreen,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            "Posts",
            style: TextStyle(
              fontFamily: "Montserrat",
              color: primaryGreen,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          "${posts.length} results",
          style: const TextStyle(
            fontFamily: "Montserrat",
            color: Colors.black38,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _postCard(Map<String, dynamic> post) {
    final title = _cleanText(post["title"], fallback: "Community Post");
    final body = _cleanText(post["body"]);
    final category = _cleanText(post["category"], fallback: "general");
    final createdAt = _formatDate(post["created_at"]);

    final likes = _toInt(post["likes_count"]);
    final comments = _toInt(post["comments_count"]);
    final reports = _toInt(post["reports_count"]);
    final mediaCount = _toInt(post["media_count"]);

    final statusColor = _statusColor(post);
    final statusIcon = _statusIcon(post);
    final statusTitle = _statusTitle(post);
    final statusMessage = _statusMessage(post);
    final firstImage = _firstImage(post);
    final hasVideo = _hasVideo(post);

    final canOpen = _approvalStatus(post) == "approved" &&
        !_asBool(post["is_hidden"]);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: statusColor.withOpacity(.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.045),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (firstImage.isNotEmpty || hasVideo)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: Stack(
                children: [
                  firstImage.isNotEmpty
                      ? Image.network(
                          firstImage,
                          width: double.infinity,
                          height: 155,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _mediaPlaceholder(
                            hasVideo: hasVideo,
                          ),
                        )
                      : _mediaPlaceholder(hasVideo: hasVideo),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _statusChip(
                      statusTitle,
                      statusIcon,
                      statusColor,
                    ),
                  ),
                  if (hasVideo)
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: _smallDarkChip(
                        "Reel",
                        Icons.play_circle_outline_rounded,
                      ),
                    ),
                  if (mediaCount > 1)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: _smallDarkChip(
                        "$mediaCount media",
                        Icons.perm_media_outlined,
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (firstImage.isEmpty && !hasVideo)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _statusChip(
                      statusTitle,
                      statusIcon,
                      statusColor,
                    ),
                  ),
                if (firstImage.isEmpty && !hasVideo) const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: "Montserrat",
                          color: primaryGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _categoryChip(category),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  createdAt,
                  style: const TextStyle(
                    fontFamily: "Montserrat",
                    color: Colors.black38,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: "Montserrat",
                    color: Colors.black87,
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _statusBox(
                  title: statusTitle,
                  message: hasVideo && _approvalStatus(post) == "pending"
                      ? "$statusMessage Your reel will appear after approval."
                      : statusMessage,
                  icon: statusIcon,
                  color: statusColor,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _statItem(
                      Icons.favorite_border_rounded,
                      likes.toString(),
                      softRed,
                    ),
                    const SizedBox(width: 14),
                    _statItem(
                      Icons.chat_bubble_outline_rounded,
                      comments.toString(),
                      primaryGreen,
                    ),
                    if (reports > 0) ...[
                      const SizedBox(width: 14),
                      _statItem(
                        Icons.report_gmailerrorred_outlined,
                        reports.toString(),
                        softRed,
                      ),
                    ],
                    const Spacer(),
                    _moreMenu(post),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 43,
                  child: ElevatedButton.icon(
                    onPressed: canOpen ? () => _openApprovedPost(post) : null,
                    icon: Icon(
                      canOpen
                          ? Icons.visibility_outlined
                          : Icons.lock_outline_rounded,
                      size: 18,
                    ),
                    label: Text(
                      canOpen ? "View in Community" : "Not Visible Yet",
                      style: const TextStyle(
                        fontFamily: "Montserrat",
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade200,
                      disabledForegroundColor: Colors.grey.shade600,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
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
      constraints: const BoxConstraints(maxWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.94),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: "Montserrat",
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBox({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(.14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    fontFamily: "Montserrat",
                    color: Colors.black54,
                    fontSize: 11.5,
                    height: 1.35,
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

  Widget _categoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: primaryGreen.withOpacity(.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: const TextStyle(
          fontFamily: "Montserrat",
          color: primaryGreen,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _smallDarkChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.58),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontFamily: "Montserrat",
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediaPlaceholder({required bool hasVideo}) {
    return Container(
      width: double.infinity,
      height: 155,
      color: hasVideo ? Colors.black87 : paleGreen,
      child: Icon(
        hasVideo ? Icons.play_circle_fill_rounded : Icons.image_outlined,
        color: hasVideo ? Colors.white : primaryGreen,
        size: hasVideo ? 50 : 36,
      ),
    );
  }

  Widget _statItem(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: "Montserrat",
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _moreMenu(Map<String, dynamic> post) {
    return PopupMenuButton<String>(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      icon: const Icon(
        Icons.more_horiz_rounded,
        color: primaryGreen,
      ),
      onSelected: (value) {
        if (value == "delete") {
          _deletePost(post);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: "delete",
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                color: softRed,
                size: 19,
              ),
              SizedBox(width: 8),
              Text(
                "Delete",
                style: TextStyle(
                  fontFamily: "Montserrat",
                  color: softRed,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.forum_outlined,
            color: primaryGreen,
            size: 42,
          ),
          SizedBox(height: 12),
          Text(
            "No posts found",
            style: TextStyle(
              fontFamily: "Montserrat",
              color: primaryGreen,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 5),
          Text(
            "Submitted posts and review status will appear here.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "Montserrat",
              color: Colors.black38,
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}