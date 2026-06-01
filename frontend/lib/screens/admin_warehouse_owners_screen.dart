import 'package:flutter/material.dart';

import '../services/admin_warehouse_service.dart';
import 'warehouse_owner_public_profile_page.dart';

class AdminWarehouseOwnersScreen extends StatefulWidget {
  const AdminWarehouseOwnersScreen({super.key});

  @override
  State<AdminWarehouseOwnersScreen> createState() =>
      _AdminWarehouseOwnersScreenState();
}

class _AdminWarehouseOwnersScreenState extends State<AdminWarehouseOwnersScreen> {
  bool loading = true;
  List owners = [];

  @override
  void initState() {
    super.initState();
    loadOwners();
  }

  Future<void> loadOwners() async {
    setState(() => loading = true);

    try {
      final data = await AdminWarehouseService.getWarehouseOwners();

      if (!mounted) return;

      setState(() {
        owners = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);
      showMessage(e.toString(), isError: true);
    }
  }

  int toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  String textValue(dynamic value) {
    if (value == null) return "-";
    final text = value.toString().trim();
    return text.isEmpty ? "-" : text;
  }

  void openWarehousePublicProfile(Map<String, dynamic> owner) {
    final ownerId = toInt(owner["id"]);

    if (ownerId <= 0) {
      showMessage("Invalid warehouse owner id", isError: true);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WarehouseOwnerPublicProfilePage(
          ownerId: ownerId,
          ownerName: textValue(owner["full_name"]),
          ownerImage: owner["profile_image"]?.toString(),
        ),
      ),
    );
  }

  void showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message.replaceFirst("Exception: ", ""),
          style: const TextStyle(fontFamily: "Montserrat"),
        ),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (loading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: colors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: colors.primary,
        onRefresh: loadOwners,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: header()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Warehouse Owners",
                      style: TextStyle(
                        fontFamily: "Montserrat",
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Monitor stores, products, pending reviews and orders.",
                      style: TextStyle(
                        fontFamily: "Montserrat",
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (owners.isEmpty)
                      emptyOwners()
                    else
                      ...owners.map(
                        (owner) => ownerCard(
                          Map<String, dynamic>.from(owner as Map),
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
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.onPrimary.withOpacity(.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: colors.onPrimary,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Warehouse Owners",
                style: TextStyle(
                  fontFamily: "Montserrat",
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: colors.onPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Track warehouse owner activity and product review quality",
                style: TextStyle(
                  fontFamily: "Montserrat",
                  fontSize: 13,
                  color: colors.onPrimary.withOpacity(.82),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget emptyOwners() {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 58,
            color: colors.onSurfaceVariant.withOpacity(.5),
          ),
          const SizedBox(height: 12),
          Text(
            "No warehouse owners found",
            style: TextStyle(
              fontFamily: "Montserrat",
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Warehouse owners will appear here after signup.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "Montserrat",
              fontSize: 13,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget ownerCard(Map<String, dynamic> owner) {
    final colors = Theme.of(context).colorScheme;
    final image = owner["profile_image"]?.toString();
    final pending = toInt(owner["pending_products_count"]);
    final flagged = toInt(owner["flagged_products_count"]);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.045),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: Container(
                  width: 58,
                  height: 58,
                  color: colors.primaryContainer.withOpacity(.55),
                  child: image == null || image.isEmpty
                      ? Icon(
                          Icons.storefront_outlined,
                          color: colors.primary,
                          size: 29,
                        )
                      : Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.storefront_outlined,
                            color: colors.primary,
                            size: 29,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: GestureDetector(
                  onTap: () => showOwnerDetails(owner),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        textValue(owner["full_name"]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: "Montserrat",
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        textValue(owner["email"]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: "Montserrat",
                          fontSize: 12.5,
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          if (pending > 0)
                            badge("$pending pending", Colors.orange.shade700),
                          if (flagged > 0)
                            badge("$flagged flagged", colors.error),
                          if (pending == 0 && flagged == 0)
                            badge("Clear", colors.primary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => openWarehousePublicProfile(owner),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: colors.primary,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              smallInfo(
                "Products",
                textValue(owner["products_count"]),
                Icons.inventory_2_outlined,
              ),
              const SizedBox(width: 8),
              smallInfo(
                "Orders",
                textValue(owner["orders_count"]),
                Icons.receipt_long_outlined,
              ),
              const SizedBox(width: 8),
              smallInfo(
                "Paid",
                textValue(owner["paid_orders_count"]),
                Icons.payments_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => openWarehousePublicProfile(owner),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              icon: const Icon(Icons.storefront_outlined, size: 18),
              label: const Text(
                "Open Public Profile",
                style: TextStyle(
                  fontFamily: "Montserrat",
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget smallInfo(String label, String value, IconData icon) {
    final colors = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: colors.primary, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: "Montserrat",
                color: colors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: "Montserrat",
                color: colors.onSurfaceVariant,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: "Montserrat",
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void showOwnerDetails(Map<String, dynamic> owner) {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: .74,
          minChildSize: .40,
          maxChildSize: .92,
          expand: false,
          builder: (_, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colors.onSurfaceVariant.withOpacity(.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  textValue(owner["full_name"]),
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  textValue(owner["email"]),
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                detailCard(
                  "Owner Summary",
                  [
                    detailRow("User ID", owner["id"]),
                    detailRow("Joined At", owner["created_at"]),
                    detailRow("Products", owner["products_count"]),
                    detailRow("Pending Products", owner["pending_products_count"]),
                    detailRow("Flagged Products", owner["flagged_products_count"]),
                    detailRow("Orders", owner["orders_count"]),
                    detailRow("Paid Orders", owner["paid_orders_count"]),
                  ],
                ),
                const SizedBox(height: 12),
                detailCard(
                  "Admin Notes",
                  [
                    Text(
                      "Use this page to quickly monitor warehouse owners. Product approval and flags are managed from the Warehouse Products screen.",
                      style: TextStyle(
                        fontFamily: "Montserrat",
                        height: 1.5,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      openWarehousePublicProfile(owner);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    icon: const Icon(Icons.storefront_outlined),
                    label: const Text(
                      "Open Public Profile",
                      style: TextStyle(
                        fontFamily: "Montserrat",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget detailCard(String title, List<Widget> children) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: "Montserrat",
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget detailRow(String label, dynamic value) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: "Montserrat",
                color: colors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value?.toString() ?? "-",
              textAlign: TextAlign.end,
              style: TextStyle(
                fontFamily: "Montserrat",
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}