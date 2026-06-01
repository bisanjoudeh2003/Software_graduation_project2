import 'package:flutter/material.dart';

import '../services/warehouse_service.dart';
import 'warehouse_owner_bottom_nav.dart';
import 'warehouse_add_products_page.dart';
import 'warehouse_edit_product_page.dart';

class WarehouseProductsPage extends StatefulWidget {
  const WarehouseProductsPage({super.key});

  @override
  State<WarehouseProductsPage> createState() => _WarehouseProductsPageState();
}

class _WarehouseProductsPageState extends State<WarehouseProductsPage> {
  static const Color primaryGreen = Color(0xFF2F4F3E);
  static const Color midGreen = Color(0xFF4A7C62);
  static const Color lightGreen = Color(0xFFC1D9CC);
  static const Color paleGreen = Color(0xFFEAF3EE);
  static const Color cream = Color(0xFFF6F4EE);
  static const Color softRed = Color(0xFFD9534F);
  static const Color softRedBg = Color(0xFFFAECEC);
  static const Color softRedBorder = Color(0xFFF0BFBF);
  static const Color softOrange = Color(0xFFE38B29);
  static const Color softOrangeBg = Color(0xFFFFF3E4);

  bool loading = true;
  bool deleting = false;
  List products = [];

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    setState(() => loading = true);

    try {
      final data = await WarehouseService.getMyProducts();

      if (!mounted) return;

      setState(() {
        products = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      _showSnack(
        e.toString().replaceAll('Exception:', '').trim(),
        isError: true,
      );
    }
  }

  Future<void> _openAddProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WarehouseAddProductPage()),
    );

    if (result == true) {
      loadProducts();
    }
  }

  Future<void> _openEditProduct(Map product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WarehouseEditProductPage(product: product),
      ),
    );

    if (result == true) {
      loadProducts();
    }
  }

  Future<void> _confirmDeleteProduct(Map product) async {
    final name = product['name']?.toString() ?? 'Product';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text(
          'Delete Product',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w900,
            color: softRed,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$name"?\n\nThis product will be hidden from your store.',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 12.5,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: deleting ? null : () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
                color: primaryGreen,
                fontSize: 13,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: deleting ? null : () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_outline, size: 17),
            label: const Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: softRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteProduct(product);
    }
  }

  Future<void> _deleteProduct(Map product) async {
    final id = int.tryParse(product['id'].toString());

    if (id == null) {
      _showSnack('Product id is missing', isError: true);
      return;
    }

    setState(() => deleting = true);

    try {
      await WarehouseService.deleteProduct(id);

      if (!mounted) return;

      _showSnack('Product deleted successfully');
      await loadProducts();
    } catch (e) {
      if (!mounted) return;

      _showSnack(
        e.toString().replaceAll('Exception:', '').trim(),
        isError: true,
      );
    }

    if (mounted) {
      setState(() => deleting = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 12.5,
          ),
        ),
        backgroundColor: isError ? softRed : primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatPrice(dynamic raw) {
    final p = double.tryParse(raw?.toString() ?? '0') ?? 0;
    return p == p.truncateToDouble()
        ? p.toInt().toString()
        : p.toStringAsFixed(2);
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  String _cleanText(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty || text == 'null' ? fallback : text;
  }

  List<String> _getProductImages(Map product) {
    final images = <String>[];
    final rawImages = product['images'];

    if (rawImages is List) {
      for (final item in rawImages) {
        final img = item?.toString() ?? '';
        if (img.trim().isNotEmpty) {
          images.add(img);
        }
      }
    }

    final mainImage = product['image_url']?.toString() ?? '';

    if (mainImage.trim().isNotEmpty && !images.contains(mainImage)) {
      images.insert(0, mainImage);
    }

    return images;
  }

  String _adminStatusLabel(Map product) {
    final reviewed = _toInt(product['product_reviewed']) == 1;
    final visibility = _cleanText(
      product['admin_visibility'],
      fallback: 'hidden',
    );
    final flagged = _toInt(product['product_flagged']) == 1;

    if (flagged) return 'Flagged by Admin';
    if (!reviewed) return 'Under Admin Review';
    if (visibility == 'visible') return 'Approved & Visible';
    return 'Reviewed, Hidden';
  }

  Color _adminStatusColor(Map product) {
    final reviewed = _toInt(product['product_reviewed']) == 1;
    final visibility = _cleanText(
      product['admin_visibility'],
      fallback: 'hidden',
    );
    final flagged = _toInt(product['product_flagged']) == 1;

    if (flagged) return softRed;
    if (!reviewed) return softOrange;
    if (visibility == 'visible') return primaryGreen;
    return Colors.grey.shade700;
  }

  Color _adminStatusBg(Map product) {
    final reviewed = _toInt(product['product_reviewed']) == 1;
    final visibility = _cleanText(
      product['admin_visibility'],
      fallback: 'hidden',
    );
    final flagged = _toInt(product['product_flagged']) == 1;

    if (flagged) return softRedBg;
    if (!reviewed) return softOrangeBg;
    if (visibility == 'visible') return paleGreen;
    return Colors.grey.shade200;
  }

  bool _isProductOutOfStock(Map product) {
    final type = _cleanText(product['product_type'], fallback: 'ready');
    final status = _cleanText(product['status'], fallback: 'available');
    final stock = _toInt(product['stock_quantity']);

    if (type != 'ready') return false;

    return stock <= 0 || status == 'out_of_stock';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      bottomNavigationBar: const WarehouseOwnerBottomNav(currentIndex: 1),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addProductFab',
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Add Product',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
          ),
        ),
        onPressed: _openAddProduct,
      ),
      body: RefreshIndicator(
        color: primaryGreen,
        onRefresh: loadProducts,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _topHeader(context),
            ),
            if (loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: primaryGreen),
                ),
              )
            else if (products.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _emptyState(),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      index == 0 ? 18 : 0,
                      20,
                      index == products.length - 1 ? 110 : 16,
                    ),
                    child: _productCard(products[index]),
                  ),
                  childCount: products.length,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _topHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2F4F3E),
            Color(0xFF3D6B57),
          ],
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
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Products',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.16),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(.22),
                  ),
                ),
                child: Text(
                  '${products.length} Products',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'New products appear publicly after admin approval.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.white.withOpacity(.82),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: lightGreen.withOpacity(.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: primaryGreen,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No products yet',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w900,
                color: primaryGreen,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start by adding photography gear or custom graduation products.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.black45,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _openAddProduct,
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text(
                'Add First Product',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productCard(Map product) {
    final name = _cleanText(product['name'], fallback: 'Product');
    final category = _cleanText(product['category']);
    final description = _cleanText(product['description']);
    final type = _cleanText(product['product_type'], fallback: 'ready');
    final previewType = _cleanText(product['preview_type']);
    final price = _formatPrice(product['price']);
    final stock = _toInt(product['stock_quantity']);
    final images = _getProductImages(product);

    final isCustom = type == 'custom';
    final isOut = _isProductOutOfStock(product);

    final adminLabel = _adminStatusLabel(product);
    final adminColor = _adminStatusColor(product);
    final adminBg = _adminStatusBg(product);
    final flagReason = _cleanText(product['product_flag_reason']);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.055),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
        border: _toInt(product['product_flagged']) == 1
            ? Border.all(color: softRedBorder, width: 1.2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductImagesSlider(images: images),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _badge(
                  adminLabel,
                  adminColor,
                  adminBg,
                  icon: _toInt(product['product_flagged']) == 1
                      ? Icons.flag_outlined
                      : _toInt(product['product_reviewed']) == 1
                          ? Icons.verified_outlined
                          : Icons.pending_actions_outlined,
                ),
                if (flagReason.isNotEmpty &&
                    _toInt(product['product_flagged']) == 1) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: softRedBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: softRedBorder),
                    ),
                    child: Text(
                      'Admin note: $flagReason',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11.5,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                        color: softRed,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 11),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w900,
                          fontSize: 16.5,
                          color: primaryGreen,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.grey,
                        size: 22,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _openEditProduct(product);
                        }

                        if (value == 'delete') {
                          _confirmDeleteProduct(product);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: softRed,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  color: softRed,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (category.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    category,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                      color: Colors.black45,
                    ),
                  ),
                ],
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11.5,
                      height: 1.45,
                      color: Colors.black45,
                    ),
                  ),
                ],
                const SizedBox(height: 11),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _badge(
                      isCustom ? 'Custom' : 'Ready',
                      isCustom ? const Color(0xFF7C4DBC) : primaryGreen,
                      isCustom ? const Color(0xFFF3ECFC) : paleGreen,
                    ),
                    _badge('\$$price', midGreen, paleGreen),
                    _badge(
                      isOut ? 'Out of stock' : 'Stock: $stock',
                      isOut ? softRed : const Color(0xFF4A6580),
                      isOut ? softRedBg : const Color(0xFFECF2F8),
                    ),
                    if (previewType.isNotEmpty)
                      _badge(
                        previewType.replaceAll('_', ' '),
                        const Color(0xFF8B5A2B),
                        const Color(0xFFF7EDE3),
                      ),
                  ],
                ),
                if (_toInt(product['product_reviewed']) == 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Colors.orange.shade800,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'This product is waiting for admin approval before appearing to customers.',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 11.2,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 43,
                        child: ElevatedButton.icon(
                          onPressed: () => _openEditProduct(product),
                          icon: const Icon(Icons.edit_outlined, size: 17),
                          label: const Text(
                            'Edit',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: paleGreen,
                            foregroundColor: primaryGreen,
                            elevation: 0,
                            side: const BorderSide(
                              color: lightGreen,
                              width: 1.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 43,
                        child: ElevatedButton.icon(
                          onPressed: deleting
                              ? null
                              : () => _confirmDeleteProduct(product),
                          icon: const Icon(Icons.delete_outline, size: 17),
                          label: const Text(
                            'Delete',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: softRedBg,
                            foregroundColor: softRed,
                            elevation: 0,
                            side: const BorderSide(
                              color: softRedBorder,
                              width: 1.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(
    String text,
    Color textColor,
    Color bgColor, {
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductImagesSlider extends StatefulWidget {
  final List<String> images;

  const ProductImagesSlider({
    super.key,
    required this.images,
  });

  @override
  State<ProductImagesSlider> createState() => _ProductImagesSliderState();
}

class _ProductImagesSliderState extends State<ProductImagesSlider> {
  final PageController _controller = PageController();

  int currentIndex = 0;

  void _goTo(int index) {
    if (index < 0 || index >= widget.images.length) return;

    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.images.isNotEmpty;
    final total = widget.images.length;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(22),
        topRight: Radius.circular(22),
      ),
      child: SizedBox(
        height: 210,
        width: double.infinity,
        child: Stack(
          children: [
            if (!hasImages)
              Container(
                width: double.infinity,
                height: 210,
                color: Colors.grey.shade100,
                child: const Icon(
                  Icons.image_outlined,
                  color: Colors.grey,
                  size: 40,
                ),
              )
            else
              PageView.builder(
                controller: _controller,
                itemCount: total,
                onPageChanged: (i) {
                  setState(() => currentIndex = i);
                },
                itemBuilder: (_, i) {
                  return Image.network(
                    widget.images[i],
                    width: double.infinity,
                    height: 210,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: double.infinity,
                      height: 210,
                      color: Colors.grey.shade100,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
            if (hasImages && total > 1 && currentIndex > 0)
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _ArrowButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => _goTo(currentIndex - 1),
                  ),
                ),
              ),
            if (hasImages && total > 1 && currentIndex < total - 1)
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _ArrowButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => _goTo(currentIndex + 1),
                  ),
                ),
              ),
            if (hasImages && total > 1)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(total, (i) {
                    final selected = currentIndex == i;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: selected ? 17 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white
                            : Colors.white.withOpacity(.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }),
                ),
              ),
            if (hasImages && total > 1)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.38),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${currentIndex + 1}/$total',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ArrowButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(.32),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 21,
        ),
      ),
    );
  }
}