import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'login_screen.dart';
import 'admin_edit_profile_screen.dart';
import 'change_password_page.dart';

const Color adminPrimaryGreen = Color(0xFF2F4F46);
const Color adminLightCream = Color(0xFFF5F1EB);
const Color adminSoftGreen = Color(0xFF3E6B5C);
const Color adminGold = Color(0xFFC9A84C);
const Color adminRed = Color(0xFFB84040);
const Color adminGrey = Color(0xFF8A8A8A);

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  bool loading = true;
  bool uploadingImage = false;

  Map<String, dynamic> user = {};
  File? imageFile;

  @override
  void initState() {
    super.initState();
    _loadAdmin();
  }

  Future<void> _loadAdmin() async {
    setState(() => loading = true);

    try {
      final data = await AuthService.getMe();

      if (!mounted) return;

      setState(() {
        user = Map<String, dynamic>.from(data ?? {});
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _openEditAccount() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminEditProfileScreen(),
      ),
    );

    if (changed == true) {
      _loadAdmin();
    }
  }

  Future<void> _openChangePassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChangePasswordPage(),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (picked == null) return;

      final file = File(picked.path);

      setState(() {
        imageFile = file;
        uploadingImage = true;
      });

      final url = await ProfileService.uploadProfileImage(file);

      if (!mounted) return;

      if (url != null && url.isNotEmpty) {
        setState(() {
          user["profile_image"] = url;
        });

        _showMessage("Account image updated");
      } else {
        _showMessage("Failed to upload image", isError: true);
      }
    } catch (_) {
      _showMessage("Failed to upload image", isError: true);
    }

    if (mounted) {
      setState(() => uploadingImage = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            "Logout",
            style: TextStyle(
              color: adminPrimaryGreen,
              fontWeight: FontWeight.bold,
              fontFamily: "Playfair",
            ),
          ),
          content: const Text(
            "Are you sure you want to logout from your admin account?",
            style: TextStyle(
              color: Colors.black54,
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
              child: const Text(
                "Logout",
                style: TextStyle(
                  color: adminRed,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Playfair",
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await AuthService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String _text(dynamic value, {String fallback = "Not set"}) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == "null") return fallback;

    return text;
  }

  String _roleName(String role) {
    if (role == "admin") return "System Admin";
    return role;
  }

  @override
  Widget build(BuildContext context) {
    final name = _text(user["full_name"], fallback: "Admin");
    final email = _text(user["email"], fallback: "No email");
    final phone = _text(user["phone"]);
    final role = _text(user["role"], fallback: "admin");
    final image = _text(user["profile_image"], fallback: "");

    return Scaffold(
      backgroundColor: adminLightCream,
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: adminPrimaryGreen),
            )
          : RefreshIndicator(
              color: adminPrimaryGreen,
              onRefresh: _loadAdmin,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _header(
                      name: name,
                      email: email,
                      role: role,
                      image: image,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _adminAccessCard(),
                        const SizedBox(height: 22),
                        _sectionTitle(
                          "Account Information",
                          Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 10),
                        _card([
                          _infoTile(
                            Icons.badge_outlined,
                            "Full Name",
                            name,
                          ),
                          _divider(),
                          _infoTile(
                            Icons.email_outlined,
                            "Email",
                            email,
                          ),
                          _divider(),
                          _infoTile(
                            Icons.phone_outlined,
                            "Phone",
                            phone,
                          ),
                          _divider(),
                          _infoTile(
                            Icons.admin_panel_settings_outlined,
                            "Role",
                            _roleName(role),
                          ),
                        ]),
                        const SizedBox(height: 22),
                        _sectionTitle(
                          "Account Settings",
                          Icons.settings_outlined,
                        ),
                        const SizedBox(height: 10),
                        _card([
                          _menuItem(
                            icon: Icons.edit_outlined,
                            title: "Edit Account",
                            subtitle: "Update your name and phone number",
                            color: adminPrimaryGreen,
                            onTap: _openEditAccount,
                          ),
                          _divider(),
                          _menuItem(
                            icon: Icons.lock_outline_rounded,
                            title: "Change Password",
                            subtitle: "Keep your admin account secure",
                            color: adminPrimaryGreen,
                            onTap: _openChangePassword,
                          ),
                          _divider(),
                          _menuItem(
                            icon: Icons.image_outlined,
                            title: uploadingImage
                                ? "Uploading Image..."
                                : "Update Account Image",
                            subtitle: "Change the image shown on your admin dashboard",
                            color: adminGold,
                            onTap: uploadingImage ? () {} : _pickImage,
                          ),
                          _divider(),
                          _menuItem(
                            icon: Icons.refresh_rounded,
                            title: "Refresh Account",
                            subtitle: "Reload your latest account information",
                            color: adminSoftGreen,
                            onTap: _loadAdmin,
                          ),
                        ]),
                        const SizedBox(height: 18),
                        _logoutCard(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _header({
    required String name,
    required String email,
    required String role,
    required String image,
  }) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF25463D), adminSoftGreen],
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
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 34),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Admin Account",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Playfair",
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _logout,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Stack(
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.85),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: imageFile != null
                          ? Image.file(
                              imageFile!,
                              fit: BoxFit.cover,
                            )
                          : image.isNotEmpty
                              ? Image.network(
                                  image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _avatarFallback(),
                                )
                              : _avatarFallback(),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: GestureDetector(
                      onTap: uploadingImage ? null : _pickImage,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: uploadingImage
                            ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                  color: adminPrimaryGreen,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                color: adminPrimaryGreen,
                                size: 17,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Playfair",
                ),
              ),
              const SizedBox(height: 5),
              Text(
                email,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 13,
                  fontFamily: "Playfair",
                ),
              ),
              const SizedBox(height: 13),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.22),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _roleName(role),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Playfair",
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

  Widget _avatarFallback() {
    return Container(
      color: Colors.white.withOpacity(0.18),
      child: const Icon(
        Icons.admin_panel_settings_outlined,
        color: Colors.white,
        size: 44,
      ),
    );
  }

  Widget _adminAccessCard() {
    return Container(
      width: double.infinity,
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
            color: adminPrimaryGreen.withOpacity(0.14),
            blurRadius: 15,
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
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.security_outlined,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "System Access",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Playfair",
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Manage platform users, approvals, reports and moderation tools from your admin dashboard.",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 12,
                    height: 1.35,
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

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: adminPrimaryGreen, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: adminPrimaryGreen,
            fontSize: 17,
            fontWeight: FontWeight.bold,
            fontFamily: "Playfair",
          ),
        ),
      ],
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color: adminPrimaryGreen.withOpacity(0.06),
            blurRadius: 13,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _infoTile(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      child: Row(
        children: [
          _smallIcon(icon, adminPrimaryGreen),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.42),
                    fontSize: 11,
                    fontFamily: "Playfair",
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: adminPrimaryGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(21),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        child: Row(
          children: [
            _smallIcon(icon, color),
            const SizedBox(width: 13),
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
                      fontFamily: "Playfair",
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: Colors.black.withOpacity(0.25),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallIcon(IconData icon, Color color) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      indent: 70,
      endIndent: 16,
      color: Colors.black.withOpacity(0.055),
    );
  }

  Widget _logoutCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(21),
      onTap: _logout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(21),
          boxShadow: [
            BoxShadow(
              color: adminRed.withOpacity(0.06),
              blurRadius: 13,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            _smallIcon(Icons.logout_rounded, adminRed),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Logout",
                    style: TextStyle(
                      color: adminRed,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Playfair",
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    "Sign out of admin account",
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 12,
                      fontFamily: "Playfair",
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: adminRed,
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? adminRed : adminPrimaryGreen,
        content: Text(message),
      ),
    );
  }
}