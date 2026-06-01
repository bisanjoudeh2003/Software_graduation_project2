import 'dart:async';
import 'package:flutter/material.dart';

import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../services/message_service.dart';
import '../services/notification_service.dart';

import 'login_screen.dart';
import 'admin_manage_users_screen.dart';
import 'admin_messages_screen.dart';
import 'admin_manage_photographers_screen.dart';
import 'admin_manage_clients_screen.dart';
import 'admin_manage_venues_screen.dart';
import 'admin_manage_community_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_manage_bookings_screen.dart';
import 'admin_post_session_monitor_screen.dart';
import 'admin_manage_warehouse_screen.dart';
import 'admin_notifications_screen.dart';

const Color adminPrimaryGreen = Color(0xFF2F4F3E);
const Color adminLightCream = Color(0xFFF6F4EE);
const Color adminSoftGreen = Color(0xFF3D6B57);
const Color adminPaleGreen = Color(0xFFEAF3EE);
const Color adminLightGreen = Color(0xFFC1D9CC);
const Color adminGold = Color(0xFFC9A84C);
const Color adminRed = Color(0xFFD9534F);
const Color adminGrey = Color(0xFF8A8A8A);
const Color adminDarkText = Color(0xFF26352D);

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  bool loading = true;

  Map<String, dynamic>? data;
  Map<String, dynamic>? user;

  int unreadMessages = 0;
  int unreadNotifications = 0;

  Timer? _badgeTimer;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _loadAll();

    _badgeTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadBadges(),
    );
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => loading = true);

    try {
      final userData = await AuthService.getMe();
      final dashboardData = await AdminService.getDashboardStats();

      if (!mounted) return;

      setState(() {
        user = userData;
        data = dashboardData;
        loading = false;
      });

      await _loadBadges();

      _animController.reset();
      _animController.forward();
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      _showMessage(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  Future<void> _loadBadges() async {
    try {
      final convs = await MessageService.getUserConversations();

      int msgs = 0;

      for (final c in convs) {
        msgs += int.tryParse(c["unread_count"]?.toString() ?? "0") ?? 0;
      }

      final notificationsCount = await NotificationService.getUnreadCount();

      if (!mounted) return;

      setState(() {
        unreadMessages = msgs;
        unreadNotifications = notificationsCount;
      });
    } catch (_) {}
  }

  Future<void> _logout() async {
    await AuthService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openAdminMessages() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminMessagesScreen(),
      ),
    );

    _loadBadges();
  }

  Future<void> _openAdminNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminNotificationsScreen(),
      ),
    );

    _loadBadges();
  }

  Future<void> _openManageUsers() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminManageUsersScreen(),
      ),
    );

    _loadAll();
  }

  Future<void> _openManagePhotographers() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminManagePhotographersScreen(),
      ),
    );

    _loadAll();
  }

  Future<void> _openManageClients() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminManageClientsScreen(),
      ),
    );

    _loadAll();
  }

  Future<void> _openManageVenues() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminManageVenuesScreen(),
      ),
    );

    _loadAll();
  }

  Future<void> _openManageWarehouse() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminManageWarehouseScreen(),
      ),
    );

    _loadAll();
  }

  Future<void> _openManageBookings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminManageBookingsScreen(),
      ),
    );

    _loadAll();
  }

  Future<void> _openManageCommunity() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminManageCommunityScreen(),
      ),
    );

    _loadAll();
  }

  Future<void> _openAdminProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminProfileScreen(),
      ),
    );

    _loadAll();
  }

  Future<void> _openPostSessionMonitor() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminPostSessionMonitorScreen(),
      ),
    );

    _loadAll();
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

  String _money(dynamic value) {
    return "\$${_toDouble(value).toStringAsFixed(0)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: adminLightCream,
      extendBody: true,
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: adminPrimaryGreen),
            )
          : FadeTransition(
              opacity: _fadeAnim,
              child: _buildHomePage(),
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomePage() {
    final stats = data?["stats"] ?? {};
    final latest = data?["latest"] ?? {};

    final users = stats["users"] ?? {};
    final phBookings = stats["photographer_bookings"] ?? {};
    final venueBookings = stats["venue_bookings"] ?? {};
    final warehouse = stats["warehouse"] ?? {};
    final community = stats["community"] ?? {};

    final String name =
        user?["full_name"]?.toString() ?? user?["email"]?.toString() ?? "Admin";

    final totalUsers = _toInt(users["total_users"]);
    final totalPhotographers = _toInt(users["total_photographers"]);
    final totalVenues = _toInt(stats["venues"]?["total_venues"]);
    final totalBookings =
        _toInt(phBookings["total"]) + _toInt(venueBookings["total"]);

    return RefreshIndicator(
      color: adminPrimaryGreen,
      onRefresh: _loadAll,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(name)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _overviewCard(
                  totalUsers: totalUsers,
                  totalPhotographers: totalPhotographers,
                  totalVenues: totalVenues,
                  totalBookings: totalBookings,
                ),
                const SizedBox(height: 22),
                _sectionHeader(
                  "Main Admin Controls",
                  Icons.admin_panel_settings_outlined,
                ),
                const SizedBox(height: 12),
                _mainAdminControls(),
                const SizedBox(height: 22),
                _sectionHeader(
                  "Needs Attention",
                  Icons.priority_high_rounded,
                ),
                const SizedBox(height: 12),
                _attentionCard(
                  photographerPending: _toInt(phBookings["pending"]),
                  venuePending: _toInt(venueBookings["pending"]),
                  communityReports: _toInt(community["total_reports"]),
                  totalPendingBookings: _toInt(phBookings["pending"]) +
                      _toInt(venueBookings["pending"]),
                ),
                const SizedBox(height: 22),
                _sectionHeader(
                  "Money Overview",
                  Icons.payments_outlined,
                ),
                const SizedBox(height: 12),
                _moneyOverviewCard(
                  photographerDeposits: _money(phBookings["deposits_total"]),
                  photographerRemaining:
                      _money(phBookings["remaining_paid_total"]),
                  venueDeposits: _money(venueBookings["deposits_total"]),
                  storePaid: _money(warehouse["paid_total"]),
                ),
                const SizedBox(height: 22),
                _sectionHeader(
                  "Latest Users",
                  Icons.person_add_alt_1_outlined,
                  onTap: _openManageUsers,
                ),
                const SizedBox(height: 12),
                _latestUsers(latest["users"] ?? []),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String name) {
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
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _adminAvatar(size: 58),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back 👋",
                          style: TextStyle(
                            color: Colors.white.withOpacity(.76),
                            fontSize: 12.5,
                            fontFamily: "Montserrat",
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            fontFamily: "Montserrat",
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.16),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(.22),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.admin_panel_settings_outlined,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 5),
                              Text(
                                "System Admin",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: "Montserrat",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _headerBadgeIcon(
                            Icons.chat_bubble_outline_rounded,
                            badge: unreadMessages,
                            onTap: _openAdminMessages,
                          ),
                          const SizedBox(width: 8),
                          _headerBadgeIcon(
                            Icons.notifications_none_rounded,
                            badge: unreadNotifications,
                            onTap: _openAdminNotifications,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _headerIcon(Icons.refresh_rounded, onTap: _loadAll),
                          const SizedBox(width: 8),
                          _headerIcon(Icons.logout_rounded, onTap: _logout),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.13),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withOpacity(.18),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.insights_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Manage users, bookings, venues, warehouse products, community reports, and post-session quality from one place.",
                        style: TextStyle(
                          color: Colors.white.withOpacity(.82),
                          fontFamily: "Montserrat",
                          fontSize: 12,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mainAdminControls() {
    final items = [
      _ManagementItem(
        title: "Photographers",
        subtitle: "Trust, visibility and quality",
        icon: Icons.camera_alt_outlined,
        color: adminPrimaryGreen,
        onTap: _openManagePhotographers,
      ),
      _ManagementItem(
        title: "Clients",
        subtitle: "Trust, bookings and restrictions",
        icon: Icons.person_search_outlined,
        color: adminGold,
        onTap: _openManageClients,
      ),
      _ManagementItem(
        title: "Venues",
        subtitle: "Visibility, review and quality",
        icon: Icons.location_city_outlined,
        color: adminSoftGreen,
        onTap: _openManageVenues,
      ),
      _ManagementItem(
        title: "Post-Session",
        subtitle: "Delivery, revisions and reviews",
        icon: Icons.fact_check_outlined,
        color: adminGold,
        onTap: _openPostSessionMonitor,
      ),
      _ManagementItem(
        title: "Warehouse",
        subtitle: "Review products, orders and stock",
        icon: Icons.warehouse_outlined,
        color: adminSoftGreen,
        onTap: _openManageWarehouse,
      ),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 13,
        mainAxisSpacing: 13,
        childAspectRatio: 1.65,
      ),
      itemBuilder: (_, index) {
        final item = items[index];

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: item.onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: item.color.withOpacity(.045),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _iconBox(item.icon, item.color),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: adminDarkText,
                            fontSize: 13.2,
                            fontWeight: FontWeight.w900,
                            fontFamily: "Montserrat",
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black.withOpacity(.45),
                            fontSize: 10.5,
                            height: 1.25,
                            fontFamily: "Montserrat",
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _overviewCard({
    required int totalUsers,
    required int totalPhotographers,
    required int totalVenues,
    required int totalBookings,
  }) {
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
      child: Column(
        children: [
          Row(
            children: [
              _iconBox(Icons.insights_outlined, adminPrimaryGreen),
              const SizedBox(width: 11),
              const Expanded(
                child: Text(
                  "System Overview",
                  style: TextStyle(
                    color: adminPrimaryGreen,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    fontFamily: "Montserrat",
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(child: _overviewItem("Users", totalUsers.toString())),
              Expanded(
                child: _overviewItem(
                  "Photographers",
                  totalPhotographers.toString(),
                ),
              ),
              Expanded(child: _overviewItem("Venues", totalVenues.toString())),
              Expanded(
                child: _overviewItem("Bookings", totalBookings.toString()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: adminPrimaryGreen,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            fontFamily: "Montserrat",
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black.withOpacity(.48),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            fontFamily: "Montserrat",
          ),
        ),
      ],
    );
  }

  Widget _attentionCard({
    required int photographerPending,
    required int venuePending,
    required int communityReports,
    required int totalPendingBookings,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: adminRed.withOpacity(.045),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _attentionRow(
            "Pending photographer bookings",
            photographerPending,
            Icons.camera_alt_outlined,
            adminPrimaryGreen,
          ),
          _divider(),
          _attentionRow(
            "Pending venue bookings",
            venuePending,
            Icons.location_on_outlined,
            adminSoftGreen,
          ),
          _divider(),
          _attentionRow(
            "Total pending bookings",
            totalPendingBookings,
            Icons.event_note_outlined,
            adminGold,
          ),
          _divider(),
          _attentionRow(
            "Community reports",
            communityReports,
            Icons.report_outlined,
            adminRed,
          ),
        ],
      ),
    );
  }

  Widget _attentionRow(
    String title,
    int value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          _iconBox(icon, color),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: adminDarkText,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                fontFamily: "Montserrat",
              ),
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              fontFamily: "Montserrat",
            ),
          ),
        ],
      ),
    );
  }

  Widget _moneyOverviewCard({
    required String photographerDeposits,
    required String photographerRemaining,
    required String venueDeposits,
    required String storePaid,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [adminPrimaryGreen, adminSoftGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: adminPrimaryGreen.withOpacity(.14),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _moneyRow("Photographer deposits", photographerDeposits),
          _moneyRow("Photographer remaining paid", photographerRemaining),
          _moneyRow("Venue deposits", venueDeposits),
          _moneyRow("Store paid orders", storePaid),
        ],
      ),
    );
  }

  Widget _moneyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(.76),
                fontSize: 12,
                fontFamily: "Montserrat",
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              fontFamily: "Montserrat",
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
    String title,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Row(
      children: [
        Icon(icon, color: adminPrimaryGreen, size: 19),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: adminDarkText,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            fontFamily: "Montserrat",
          ),
        ),
        const Spacer(),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.black.withOpacity(.35),
              size: 15,
            ),
          ),
      ],
    );
  }

  Widget _latestUsers(List users) {
    if (users.isEmpty) {
      return _emptyCard("No users found");
    }

    return Column(
      children: users.map((u) {
        return _listCard(
          icon: _roleIcon(u["role"]?.toString()),
          title: u["full_name"]?.toString() ?? "User",
          subtitle: "${_roleName(u["role"]?.toString())} · ${u["email"] ?? ""}",
          color: adminPrimaryGreen,
        );
      }).toList(),
    );
  }

  Widget _listCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.045),
            blurRadius: 9,
            offset: const Offset(0, 4),
          ),
        ],
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: adminPrimaryGreen,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    fontFamily: "Montserrat",
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black.withOpacity(.46),
                    fontSize: 11.5,
                    fontFamily: "Montserrat",
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.black.withOpacity(.45),
          fontFamily: "Montserrat",
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 10,
      color: Colors.black.withOpacity(.06),
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _adminAvatar({double size = 58}) {
    final image = user?["profile_image"]?.toString();

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(.75),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: image != null && image.isNotEmpty
            ? Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _defaultAvatar(),
              )
            : _defaultAvatar(),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: Colors.white.withOpacity(.18),
      child: const Icon(
        Icons.admin_panel_settings_outlined,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  Widget _headerBadgeIcon(
    IconData icon, {
    required int badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.16),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 21,
            ),
          ),
          if (badge > 0)
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: const BoxDecoration(
                  color: adminRed,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    badge > 9 ? "9+" : badge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.8,
                      fontWeight: FontWeight.w900,
                      fontFamily: "Montserrat",
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.16),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: Colors.white, size: 21),
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      _NavItem(Icons.home_rounded, "Home"),
      _NavItem(Icons.groups_outlined, "Users"),
      _NavItem(Icons.event_note_outlined, "Bookings"),
      _NavItem(Icons.forum_outlined, "Community"),
      _NavItem(Icons.person_outline, "Account"),
    ];

    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (index == 0) {
                    _loadAll();
                  } else if (index == 1) {
                    _openManageUsers();
                  } else if (index == 2) {
                    _openManageBookings();
                  } else if (index == 3) {
                    _openManageCommunity();
                  } else if (index == 4) {
                    _openAdminProfile();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color: index == 0 ? adminPrimaryGreen : adminGrey,
                        size: 26,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: index == 0 ? adminPrimaryGreen : adminGrey,
                          fontSize: 10,
                          fontWeight:
                              index == 0 ? FontWeight.w800 : FontWeight.w500,
                          fontFamily: "Montserrat",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  IconData _roleIcon(String? role) {
    switch (role) {
      case "photographer":
        return Icons.camera_alt_outlined;
      case "venue_owner":
        return Icons.location_city_outlined;
      case "warehouse_owner":
        return Icons.warehouse_outlined;
      case "admin":
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.person_outline;
    }
  }

  String _roleName(String? role) {
    switch (role) {
      case "photographer":
        return "Photographer";
      case "venue_owner":
        return "Venue Owner";
      case "warehouse_owner":
        return "Warehouse Owner";
      case "admin":
        return "Admin";
      default:
        return "Client";
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: "Montserrat",
            fontSize: 12.5,
          ),
        ),
        backgroundColor: adminPrimaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class _ManagementItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ManagementItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _NavItem {
  final IconData icon;
  final String label;

  _NavItem(this.icon, this.label);
}