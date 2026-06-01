import 'package:flutter/material.dart';

import '../services/admin_warehouse_service.dart';

import 'admin_warehouse_orders_screen.dart';
import 'admin_warehouse_owners_screen.dart';

class AdminManageWarehouseScreen extends StatefulWidget {
  const AdminManageWarehouseScreen({super.key});

  @override
  State<AdminManageWarehouseScreen> createState() =>
      _AdminManageWarehouseScreenState();
}

class _AdminManageWarehouseScreenState
    extends State<AdminManageWarehouseScreen> {
  bool loading = true;
  bool productsLoading = false;
  bool actionLoading = false;

  Map<String, dynamic> overview = {};
  List products = [];

  String selectedFilter = "pending";

  final Map<String, String> filters = {
    "pending": "Pending Review",
    "approved": "Approved",
    "hidden": "Hidden",
    "flagged": "Flagged",
    "out_stock": "Out of Stock",
    "all": "All Products",
  };

  @override
  void initState() {
    super.initState();
    loadPage();
  }

  Future<void> loadPage() async {
    setState(() => loading = true);

    try {
      final overviewData = await AdminWarehouseService.getOverview();
      final productData = await loadProductsByFilter(selectedFilter);

      if (!mounted) return;

      setState(() {
        overview = overviewData;
        products = productData;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);
      showMessage(e.toString(), isError: true);
    }
  }

  Future<List<dynamic>> loadProductsByFilter(String filter) {
    switch (filter) {
      case "pending":
        return AdminWarehouseService.getProducts(status: "pending");

      case "approved":
        return AdminWarehouseService.getProducts(
          status: "approved",
          visibility: "visible",
        );

      case "hidden":
        return AdminWarehouseService.getProducts(visibility: "hidden");

      case "flagged":
        return AdminWarehouseService.getProducts(flagged: true);

      case "out_stock":
        return AdminWarehouseService.getProducts(stock: "out");

      case "all":
      default:
        return AdminWarehouseService.getProducts();
    }
  }

  Future<void> changeFilter(String filter) async {
    if (productsLoading) return;

    setState(() {
      selectedFilter = filter;
      productsLoading = true;
    });

    try {
      final productData = await loadProductsByFilter(filter);

      if (!mounted) return;

      setState(() {
        products = productData;
        productsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => productsLoading = false);
      showMessage(e.toString(), isError: true);
    }
  }

  Future<void> refreshAll() async {
    try {
      final overviewData = await AdminWarehouseService.getOverview();
      final productData = await loadProductsByFilter(selectedFilter);

      if (!mounted) return;

      setState(() {
        overview = overviewData;
        products = productData;
      });
    } catch (e) {
      showMessage(e.toString(), isError: true);
    }
  }

  Future<void> approveProduct(Map<String, dynamic> product) async {
    final productId = toInt(product["id"]);
    if (productId == null) return;

    await runAction(() async {
      await AdminWarehouseService.approveProduct(productId);
      showMessage("Product approved successfully");
      await refreshAll();
    });
  }

  Future<void> toggleVisibility(Map<String, dynamic> product) async {
    final productId = toInt(product["id"]);
    if (productId == null) return;

    final current = product["admin_visibility"]?.toString() ?? "hidden";
    final next = current == "visible" ? "hidden" : "visible";

    await runAction(() async {
      await AdminWarehouseService.updateProductVisibility(
        productId: productId,
        adminVisibility: next,
      );

      showMessage(next == "visible" ? "Product is now visible" : "Product is now hidden");
      await refreshAll();
    });
  }

  Future<void> flagProduct(Map<String, dynamic> product) async {
    final productId = toInt(product["id"]);
    if (productId == null) return;

    final colors = Theme.of(context).colorScheme;

    final reasonController = TextEditingController(
      text: product["product_flag_reason"]?.toString() ?? "",
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          "Flag Product",
          style: TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        content: TextField(
          controller: reasonController,
          maxLines: 4,
          style: TextStyle(
            fontFamily: "Montserrat",
            color: colors.onSurface,
          ),
          decoration: InputDecoration(
            labelText: "Reason",
            hintText: "Write why this product is flagged...",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                "flagged": false,
                "reason": null,
              });
            },
            child: Text(
              "Remove Flag",
              style: TextStyle(
                fontFamily: "Montserrat",
                color: colors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(
                fontFamily: "Montserrat",
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.pop(context, {
                "flagged": true,
                "reason": reasonController.text.trim(),
              });
            },
            child: const Text(
              "Save",
              style: TextStyle(
                fontFamily: "Montserrat",
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == null) return;

    await runAction(() async {
      await AdminWarehouseService.flagProduct(
        productId: productId,
        flagged: result["flagged"] == true,
        reason: result["reason"]?.toString(),
      );

      showMessage(
        result["flagged"] == true ? "Product flagged successfully" : "Product flag removed",
      );

      await refreshAll();
    });
  }

  Future<void> openProductDetails(Map<String, dynamic> product) async {
    final productId = toInt(product["id"]);
    if (productId == null) return;

    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return FutureBuilder<Map<String, dynamic>>(
          future: AdminWarehouseService.getProductDetails(productId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.45,
                child: Center(
                  child: CircularProgressIndicator(color: colors.primary),
                ),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString().replaceFirst("Exception: ", ""),
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    color: colors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }

            final details = snapshot.data ?? {};
            return productDetailsSheet(details);
          },
        );
      },
    );
  }

  Future<void> runAction(Future<void> Function() action) async {
    if (actionLoading) return;

    setState(() => actionLoading = true);

    try {
      await action();
    } catch (e) {
      showMessage(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => actionLoading = false);
      }
    }
  }

  int? toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  double toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String textValue(dynamic value) {
    if (value == null) return "-";
    final text = value.toString().trim();
    return text.isEmpty ? "-" : text;
  }

  String money(dynamic value) {
    return "\$${toDouble(value).toStringAsFixed(2)}";
  }

  void showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message.replaceFirst("Exception: ", ""),
          style: const TextStyle(fontFamily: "Montserrat"),
        ),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
      ),
    );
  }

  String? productImage(Map<String, dynamic> product) {
    final images = product["images"];

    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first != null && first.toString().trim().isNotEmpty) {
        return first.toString();
      }
    }

    final imageUrl = product["image_url"]?.toString();
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      return imageUrl;
    }

    return null;
  }

  String statusText(Map<String, dynamic> product) {
    final reviewed = toInt(product["product_reviewed"]) == 1;
    final visibility = product["admin_visibility"]?.toString() ?? "hidden";
    final flagged = toInt(product["product_flagged"]) == 1;

    if (!reviewed) return "Pending Review";
    if (flagged) return "Flagged";
    if (visibility == "visible") return "Approved";
    return "Hidden";
  }

  Color statusColor(BuildContext context, Map<String, dynamic> product) {
    final colors = Theme.of(context).colorScheme;
    final reviewed = toInt(product["product_reviewed"]) == 1;
    final visibility = product["admin_visibility"]?.toString() ?? "hidden";
    final flagged = toInt(product["product_flagged"]) == 1;

    if (!reviewed) return Colors.orange.shade700;
    if (flagged) return colors.error;
    if (visibility == "visible") return colors.primary;
    return colors.onSurfaceVariant;
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
        onRefresh: refreshAll,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: header()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    overviewSection(),
                    const SizedBox(height: 24),
                    warehouseActionsSection(),
                    const SizedBox(height: 24),
                    Text(
                      "Products",
                      style: TextStyle(
                        fontFamily: "Montserrat",
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    filterSection(),
                    const SizedBox(height: 18),
                    if (productsLoading)
                      Padding(
                        padding: const EdgeInsets.only(top: 30),
                        child: Center(
                          child: CircularProgressIndicator(color: colors.primary),
                        ),
                      )
                    else if (products.isEmpty)
                      emptyProducts()
                    else
                      ...products.map(
                        (p) => productCard(Map<String, dynamic>.from(p as Map)),
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
                "Admin Warehouse",
                style: TextStyle(
                  fontFamily: "Montserrat",
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: colors.onPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Review products, stock, visibility and warehouse orders",
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

  Widget warehouseActionsSection() {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Warehouse Management",
          style: TextStyle(
            fontFamily: "Montserrat",
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: const Icon(Icons.receipt_long_rounded),
            label: const Text(
              "View Warehouse Orders",
              style: TextStyle(
                fontFamily: "Montserrat",
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminWarehouseOrdersScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primary,
              side: BorderSide(color: colors.primary, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: const Icon(Icons.storefront_outlined),
            label: const Text(
              "View Warehouse Owners",
              style: TextStyle(
                fontFamily: "Montserrat",
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminWarehouseOwnersScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget overviewSection() {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Overview",
          style: TextStyle(
            fontFamily: "Montserrat",
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.65,
          children: [
            overviewCard(
              "Pending",
              overview["pending_products"] ?? 0,
              Icons.pending_actions_rounded,
            ),
            overviewCard(
              "Visible",
              overview["approved_visible_products"] ?? 0,
              Icons.visibility_rounded,
            ),
            overviewCard(
              "Hidden",
              overview["hidden_products"] ?? 0,
              Icons.visibility_off_rounded,
            ),
            overviewCard(
              "Flagged",
              overview["flagged_products"] ?? 0,
              Icons.flag_rounded,
            ),
            overviewCard(
              "Out of Stock",
              overview["out_of_stock_products"] ?? 0,
              Icons.inventory_2_outlined,
            ),
            overviewCard(
              "Orders",
              overview["total_orders"] ?? 0,
              Icons.receipt_long_rounded,
            ),
          ],
        ),
      ],
    );
  }

  Widget overviewCard(String title, dynamic value, IconData icon) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primaryContainer.withOpacity(.55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: colors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget filterSection() {
    final colors = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: filters.entries.map((entry) {
        final selected = selectedFilter == entry.key;

        return GestureDetector(
          onTap: () => changeFilter(entry.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: BoxDecoration(
              color: selected ? colors.primary : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.03),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Text(
              entry.value,
              style: TextStyle(
                fontFamily: "Montserrat",
                color: selected ? colors.onPrimary : colors.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget emptyProducts() {
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
            Icons.inventory_2_outlined,
            size: 58,
            color: colors.onSurfaceVariant.withOpacity(.5),
          ),
          const SizedBox(height: 12),
          Text(
            "No products found",
            style: TextStyle(
              fontFamily: "Montserrat",
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Try another filter or add a new warehouse product.",
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

  Widget productCard(Map<String, dynamic> product) {
    final colors = Theme.of(context).colorScheme;
    final image = productImage(product);
    final status = statusText(product);
    final sColor = statusColor(context, product);
    final reviewed = toInt(product["product_reviewed"]) == 1;
    final visibility = product["admin_visibility"]?.toString() ?? "hidden";

    return GestureDetector(
      onTap: () => openProductDetails(product),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
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
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 86,
                    height: 86,
                    color: colors.primaryContainer.withOpacity(.35),
                    child: image == null
                        ? Icon(
                            Icons.inventory_2_outlined,
                            color: colors.primary,
                            size: 34,
                          )
                        : Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.broken_image_outlined,
                              color: colors.primary,
                              size: 34,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          badge(status, sColor),
                          badge(textValue(product["product_type"]), colors.primary),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        textValue(product["name"]),
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
                        "Owner: ${textValue(product["owner_name"])}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: "Montserrat",
                          fontSize: 12.5,
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${money(product["price"])} • Stock: ${textValue(product["stock_quantity"])}",
                        style: TextStyle(
                          fontFamily: "Montserrat",
                          fontSize: 12.5,
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colors.onSurfaceVariant.withOpacity(.45),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                if (!reviewed)
                  Expanded(
                    child: mainButton(
                      "Approve",
                      Icons.check_rounded,
                      () => approveProduct(product),
                    ),
                  ),
                if (!reviewed) const SizedBox(width: 8),
                Expanded(
                  child: outlineButton(
                    visibility == "visible" ? "Hide" : "Show",
                    visibility == "visible"
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    () => toggleVisibility(product),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: outlineButton(
                    "Flag",
                    Icons.flag_outlined,
                    () => flagProduct(product),
                    error: true,
                  ),
                ),
              ],
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

  Widget mainButton(String text, IconData icon, VoidCallback onTap) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: actionLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: Icon(icon, size: 16),
        label: Text(
          text,
          style: const TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget outlineButton(
    String text,
    IconData icon,
    VoidCallback onTap, {
    bool error = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    final color = error ? colors.error : colors.primary;

    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: actionLoading ? null : onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(.65)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: Icon(icon, size: 15),
        label: Text(
          text,
          style: const TextStyle(
            fontFamily: "Montserrat",
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget productDetailsSheet(Map<String, dynamic> product) {
    final colors = Theme.of(context).colorScheme;
    final image = productImage(product);
    final orderStats = product["order_stats"] is Map
        ? Map<String, dynamic>.from(product["order_stats"])
        : <String, dynamic>{};

    return DraggableScrollableSheet(
      initialChildSize: .82,
      minChildSize: .45,
      maxChildSize: .95,
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
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  image,
                  height: 210,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 18),
            Text(
              textValue(product["name"]),
              style: TextStyle(
                fontFamily: "Montserrat",
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Owner: ${textValue(product["owner_name"])}",
              style: TextStyle(
                fontFamily: "Montserrat",
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            detailCard(
              title: "Product Details",
              children: [
                detailRow("Category", product["category"]),
                detailRow("Type", product["product_type"]),
                detailRow("Price", money(product["price"])),
                detailRow("Stock", product["stock_quantity"]),
                detailRow("Status", product["status"]),
                detailRow("Admin Visibility", product["admin_visibility"]),
                detailRow("Reviewed", toInt(product["product_reviewed"]) == 1 ? "Yes" : "No"),
                detailRow("Reviewed At", product["product_reviewed_at"]),
              ],
            ),
            const SizedBox(height: 12),
            detailCard(
              title: "Description",
              children: [
                Text(
                  textValue(product["description"]),
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    height: 1.5,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            detailCard(
              title: "Order Stats",
              children: [
                detailRow("Orders Count", orderStats["orders_count"]),
                detailRow("Quantity Ordered", orderStats["total_quantity_ordered"]),
                detailRow("Total Sales", money(orderStats["total_sales"])),
              ],
            ),
            const SizedBox(height: 12),
            if (toInt(product["product_flagged"]) == 1)
              detailCard(
                title: "Flag Reason",
                children: [
                  Text(
                    textValue(product["product_flag_reason"]),
                    style: TextStyle(
                      fontFamily: "Montserrat",
                      height: 1.5,
                      color: colors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget detailCard({
    required String title,
    required List<Widget> children,
  }) {
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