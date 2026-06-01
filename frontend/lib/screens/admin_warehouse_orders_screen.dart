import 'package:flutter/material.dart';

import '../services/admin_warehouse_service.dart';

class AdminWarehouseOrdersScreen extends StatefulWidget {
  const AdminWarehouseOrdersScreen({super.key});

  @override
  State<AdminWarehouseOrdersScreen> createState() =>
      _AdminWarehouseOrdersScreenState();
}

class _AdminWarehouseOrdersScreenState
    extends State<AdminWarehouseOrdersScreen> {
  bool loading = true;
  bool actionLoading = false;
  bool ordersLoading = false;

  List orders = [];

  String selectedStatus = "all";
  String selectedPayment = "all";

  final Map<String, String> statusFilters = {
    "all": "All",
    "pending": "Pending",
    "approved": "Approved",
    "rejected": "Rejected",
    "delivered": "Delivered",
    "completed": "Completed",
    "cancelled": "Cancelled",
  };

  final Map<String, String> paymentFilters = {
    "all": "All Payments",
    "paid": "Paid",
    "unpaid": "Unpaid",
  };

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    setState(() => loading = true);

    try {
      final data = await AdminWarehouseService.getOrders(
        status: selectedStatus == "all" ? null : selectedStatus,
        paymentStatus: selectedPayment == "all" ? null : selectedPayment,
      );

      if (!mounted) return;

      setState(() {
        orders = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);
      showMessage(e.toString(), isError: true);
    }
  }

  Future<void> reloadOrdersOnly() async {
    setState(() => ordersLoading = true);

    try {
      final data = await AdminWarehouseService.getOrders(
        status: selectedStatus == "all" ? null : selectedStatus,
        paymentStatus: selectedPayment == "all" ? null : selectedPayment,
      );

      if (!mounted) return;

      setState(() {
        orders = data;
        ordersLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => ordersLoading = false);
      showMessage(e.toString(), isError: true);
    }
  }

  Future<void> changeStatusFilter(String status) async {
    if (ordersLoading) return;

    setState(() => selectedStatus = status);
    await reloadOrdersOnly();
  }

  Future<void> changePaymentFilter(String payment) async {
    if (ordersLoading) return;

    setState(() => selectedPayment = payment);
    await reloadOrdersOnly();
  }

  Future<void> updateOrderStatus(Map<String, dynamic> order) async {
    final orderId = toInt(order["id"]);
    if (orderId == null) return;

    final colors = Theme.of(context).colorScheme;

    String selected = order["status"]?.toString() ?? "pending";
    final noteController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "Update Order Status",
                style: TextStyle(
                  fontFamily: "Montserrat",
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selected,
                    decoration: InputDecoration(
                      labelText: "Status",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "pending",
                        child: Text("Pending"),
                      ),
                      DropdownMenuItem(
                        value: "approved",
                        child: Text("Approved"),
                      ),
                      DropdownMenuItem(
                        value: "rejected",
                        child: Text("Rejected"),
                      ),
                      DropdownMenuItem(
                        value: "delivered",
                        child: Text("Delivered"),
                      ),
                      DropdownMenuItem(
                        value: "completed",
                        child: Text("Completed"),
                      ),
                      DropdownMenuItem(
                        value: "cancelled",
                        child: Text("Cancelled"),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => selected = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    style: TextStyle(
                      fontFamily: "Montserrat",
                      color: colors.onSurface,
                    ),
                    decoration: InputDecoration(
                      labelText: "Admin note",
                      hintText: "Optional note for this update...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
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
                      "status": selected,
                      "note": noteController.text.trim(),
                    });
                  },
                  child: const Text(
                    "Update",
                    style: TextStyle(
                      fontFamily: "Montserrat",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    await runAction(() async {
      await AdminWarehouseService.updateOrderStatus(
        orderId: orderId,
        status: result["status"].toString(),
        adminNote: result["note"]?.toString(),
      );

      showMessage("Order status updated successfully");
      await reloadOrdersOnly();
    });
  }

  Future<void> openOrderDetails(Map<String, dynamic> order) async {
    final orderId = toInt(order["id"]);
    if (orderId == null) return;

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
          future: AdminWarehouseService.getOrderDetails(orderId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: MediaQuery.of(context).size.height * .45,
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

            return orderDetailsSheet(snapshot.data ?? {});
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

  String money(dynamic value) {
    return "\$${toDouble(value).toStringAsFixed(2)}";
  }

  String textValue(dynamic value) {
    if (value == null) return "-";
    final text = value.toString().trim();
    return text.isEmpty ? "-" : text;
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

  Color statusColor(String? status) {
    final colors = Theme.of(context).colorScheme;

    switch (status) {
      case "approved":
        return colors.primary;
      case "paid":
      case "delivered":
      case "completed":
        return Colors.green.shade700;
      case "rejected":
      case "cancelled":
      case "canceled":
        return colors.error;
      case "pending":
      default:
        return Colors.orange.shade700;
    }
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
        onRefresh: reloadOrdersOnly,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: header()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle("Order Status"),
                    const SizedBox(height: 12),
                    filterWrap(
                      entries: statusFilters,
                      selected: selectedStatus,
                      onTap: changeStatusFilter,
                    ),
                    const SizedBox(height: 20),
                    sectionTitle("Payment Status"),
                    const SizedBox(height: 12),
                    filterWrap(
                      entries: paymentFilters,
                      selected: selectedPayment,
                      onTap: changePaymentFilter,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Orders",
                            style: TextStyle(
                              fontFamily: "Montserrat",
                              color: colors.primary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (actionLoading || ordersLoading)
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: colors.primary,
                              strokeWidth: 2,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (ordersLoading)
                      Padding(
                        padding: const EdgeInsets.only(top: 30),
                        child: Center(
                          child: CircularProgressIndicator(color: colors.primary),
                        ),
                      )
                    else if (orders.isEmpty)
                      emptyOrders()
                    else
                      ...orders.map(
                        (o) => orderCard(Map<String, dynamic>.from(o as Map)),
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
                "Warehouse Orders",
                style: TextStyle(
                  fontFamily: "Montserrat",
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: colors.onPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Review customer orders, payment status and fulfillment progress",
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

  Widget sectionTitle(String title) {
    final colors = Theme.of(context).colorScheme;

    return Text(
      title,
      style: TextStyle(
        fontFamily: "Montserrat",
        color: colors.primary,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget filterWrap({
    required Map<String, String> entries,
    required String selected,
    required Future<void> Function(String) onTap,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: entries.entries.map((entry) {
        final isSelected = selected == entry.key;

        return GestureDetector(
          onTap: () => onTap(entry.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: BoxDecoration(
              color:
                  isSelected ? colors.primary : colors.surfaceContainerHighest,
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
                color: isSelected ? colors.onPrimary : colors.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget emptyOrders() {
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
            Icons.receipt_long_outlined,
            size: 58,
            color: colors.onSurfaceVariant.withOpacity(.5),
          ),
          const SizedBox(height: 12),
          Text(
            "No orders found",
            style: TextStyle(
              fontFamily: "Montserrat",
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Try another status or payment filter.",
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

  Widget orderCard(Map<String, dynamic> order) {
    final colors = Theme.of(context).colorScheme;

    final status = order["status"]?.toString() ?? "pending";
    final payment = order["payment_status"]?.toString() ?? "unpaid";
    final items = order["items"];

    int itemsCount = 0;
    if (items is List) itemsCount = items.length;

    return GestureDetector(
      onTap: () => openOrderDetails(order),
      child: Container(
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
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withOpacity(.45),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: colors.primary,
                    size: 26,
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
                          badge(status, statusColor(status)),
                          badge(payment, statusColor(payment)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Order #${textValue(order["id"])}",
                        style: TextStyle(
                          fontFamily: "Montserrat",
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Buyer: ${textValue(order["requester_name"])} (${textValue(order["requester_role"])})",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: "Montserrat",
                          fontSize: 12.5,
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "Owner: ${textValue(order["warehouse_owner_name"])}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: "Montserrat",
                          fontSize: 12.5,
                          color: colors.onSurfaceVariant,
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
            const SizedBox(height: 12),
            Row(
              children: [
                smallInfo(
                  "Total",
                  money(order["total_price"]),
                  Icons.payments_outlined,
                ),
                const SizedBox(width: 8),
                smallInfo(
                  "Items",
                  itemsCount.toString(),
                  Icons.inventory_2_outlined,
                ),
                const SizedBox(width: 8),
                smallInfo(
                  "Qty",
                  textValue(order["quantity"]),
                  Icons.numbers_rounded,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: actionLoading ? null : () => updateOrderStatus(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text(
                  "Update Status",
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
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

  Widget orderDetailsSheet(Map<String, dynamic> order) {
    final colors = Theme.of(context).colorScheme;
    final items = order["items"] is List ? order["items"] as List : [];

    return DraggableScrollableSheet(
      initialChildSize: .84,
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
            Text(
              "Order #${textValue(order["id"])}",
              style: TextStyle(
                fontFamily: "Montserrat",
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                badge(
                  textValue(order["status"]),
                  statusColor(order["status"]?.toString()),
                ),
                badge(
                  textValue(order["payment_status"]),
                  statusColor(order["payment_status"]?.toString()),
                ),
              ],
            ),
            const SizedBox(height: 16),
            detailCard(
              "Order Info",
              [
                detailRow("Buyer", order["requester_name"]),
                detailRow("Buyer Role", order["requester_role"]),
                detailRow("Buyer Email", order["requester_email"]),
                detailRow("Warehouse Owner", order["warehouse_owner_name"]),
                detailRow("Owner Email", order["warehouse_owner_email"]),
                detailRow("Total", money(order["total_price"])),
                detailRow("Quantity", order["quantity"]),
                detailRow("Needed Date", order["needed_date"]),
                detailRow("Created At", order["created_at"]),
                detailRow("Paid At", order["paid_at"]),
                detailRow("Owner/Admin Note", order["owner_response"]),
              ],
            ),
            const SizedBox(height: 12),
            detailCard(
              "Items",
              items.isEmpty
                  ? [
                      Text(
                        "No items found",
                        style: TextStyle(
                          fontFamily: "Montserrat",
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ]
                  : items.map((item) {
                      final itemMap = Map<String, dynamic>.from(item as Map);
                      return itemRow(itemMap);
                    }).toList(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: actionLoading
                    ? null
                    : () {
                        Navigator.pop(context);
                        updateOrderStatus(order);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text(
                  "Update Order Status",
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
  }

  Widget itemRow(Map<String, dynamic> item) {
    final colors = Theme.of(context).colorScheme;

    final image = item["image_url"]?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Container(
              width: 54,
              height: 54,
              color: colors.primaryContainer.withOpacity(.35),
              child: image == null || image.isEmpty
                  ? Icon(
                      Icons.inventory_2_outlined,
                      color: colors.primary,
                    )
                  : Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.broken_image_outlined,
                        color: colors.primary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  textValue(item["product_name"] ?? item["name"]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Qty: ${textValue(item["quantity"])} • Unit: ${money(item["unit_price"])}",
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Total: ${money(item["total_price"])}",
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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