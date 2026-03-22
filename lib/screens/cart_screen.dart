import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../widgets/storage_network_image.dart';
import '../services/cart_service.dart';
import 'checkout_screen.dart';
import '../utils/format_utils.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final Set<String> _selectedKeys = <String>{};

  @override
  void initState() {
    super.initState();
    for (final item in _cartService.items) {
      _selectedKeys.add(_cartService.itemKey(item));
    }
  }

  double _selectedTotalPrice() {
    double total = 0;
    for (final item in _cartService.items) {
      final key = _cartService.itemKey(item);
      if (_selectedKeys.contains(key)) {
        total += item.product.price * item.quantity;
      }
    }
    return total;
  }

  void _removeItem(CartItem item) {
    final key = _cartService.itemKey(item);
    _cartService.removeItem(item.product.id, item.size);
    setState(() {
      _selectedKeys.remove(key);
    });
  }

  void _incrementQuantity(CartItem item) {
    setState(() {
      item.quantity += 1;
    });
  }

  void _decrementQuantity(CartItem item) {
    if (item.quantity <= 1) {
      _removeItem(item);
      return;
    }

    setState(() {
      item.quantity -= 1;
    });
  }

  Widget _buildQuantityStepper(CartItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.blue.shade100),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Giảm',
            onPressed: () => _decrementQuantity(item),
            icon: const Icon(Icons.remove_circle_outline),
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          const SizedBox(width: 6),
          Text(
            item.quantity.toString(),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Tăng',
            onPressed: () => _incrementQuantity(item),
            icon: const Icon(Icons.add_circle_outline),
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  void _clearCart() {
    _cartService.clear();
    setState(() {
      _selectedKeys.clear();
    });
  }

  void _checkoutSelected() {
    if (_selectedKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn sản phẩm để thanh toán')),
      );
      return;
    }

    final selectedItems =
        _cartService.items
            .where((item) => _selectedKeys.contains(_cartService.itemKey(item)))
            .toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn sản phẩm để thanh toán')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(selectedItems: selectedItems),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.blue),
        actions: [
          if (_cartService.items.isNotEmpty)
            IconButton(
              tooltip: 'Xoá tất cả',
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearCart,
            ),
        ],
      ),
      body:
          _cartService.items.isEmpty
              ? const Center(child: Text('Giỏ hàng đang trống'))
              : Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _cartService.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _cartService.items[index];
                        final key = _cartService.itemKey(item);
                        final isSelected = _selectedKeys.contains(key);
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.blue.shade50),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedKeys.add(key);
                                    } else {
                                      _selectedKeys.remove(key);
                                    }
                                  });
                                },
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: ProductModel.isNetworkImageUrl(
                                        item.product.imageUrl)
                                    ? StorageNetworkImage(
                                        url: item.product.imageUrl,
                                        width: 64,
                                        height: 64,
                                        fit: BoxFit.cover,
                                        fallback: Container(
                                          width: 64,
                                          height: 64,
                                          color: Colors.blue.shade50,
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            Icons.image_not_supported_outlined,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                    : Image.asset(
                                        ProductModel.normalizeLocalAssetPath(
                                            item.product.imageUrl),
                                        width: 64,
                                        height: 64,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 64,
                                          height: 64,
                                          color: Colors.blue.shade50,
                                          alignment: Alignment.center,
                                          child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: DropdownButton<String>(
                                        value: item.size,
                                        isDense: true,
                                        underline: const SizedBox(),
                                        icon: const Icon(Icons.arrow_drop_down, size: 18),
                                        items: item.product.sizesStock.entries
                                            .where((e) => e.value > 0)
                                            .map((e) => DropdownMenuItem(
                                                  value: e.key,
                                                  child: Text('Size ${e.key}', style: const TextStyle(fontSize: 13)),
                                                ))
                                            .toList(),
                                        onChanged: (newSize) {
                                          if (newSize != null && newSize != item.size) {
                                            // Lấy list keys đã chọn để phục hồi nếu nó đổi key
                                            bool wasSelected = _selectedKeys.contains(key);
                                            setState(() {
                                              if (wasSelected) _selectedKeys.remove(key);
                                              _cartService.updateSize(item.product.id, item.size, newSize);
                                              // CartService đã cập nhật / gộp item nên ta cần render lại list key tùy item mới
                                              if (wasSelected) {
                                                _selectedKeys.add(_cartService.itemKey(CartItem(product: item.product, size: newSize)));
                                              }
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildQuantityStepper(item),
                                    const SizedBox(height: 8),
                                    Text(
                                      formatPrice(
                                        item.product.price * item.quantity,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    tooltip: 'Xoá',
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _removeItem(item),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.blue.shade50),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng cộng',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              formatPrice(_selectedTotalPrice()),
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _checkoutSelected,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'THANH TOÁN',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
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
}
