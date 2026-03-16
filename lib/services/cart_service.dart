import 'dart:collection';

import '../models/product_model.dart';

class CartItem {
  final ProductModel product;
  final String size;
  int quantity;

  CartItem({required this.product, required this.size, this.quantity = 1});
}

class CartService {
  CartService._();

  static final CartService _instance = CartService._();

  factory CartService() => _instance;

  final Map<String, CartItem> _itemsByKey = <String, CartItem>{};

  String _key(String productId, String size) => '$productId|$size';

  String itemKey(CartItem item) => _key(item.product.id, item.size);

  UnmodifiableListView<CartItem> get items =>
      UnmodifiableListView<CartItem>(_itemsByKey.values);

  void addItem(ProductModel product, String size, {int quantity = 1}) {
    final key = _key(product.id, size);
    final existing = _itemsByKey[key];
    if (existing != null) {
      existing.quantity += quantity;
      return;
    }

    _itemsByKey[key] = CartItem(
      product: product,
      size: size,
      quantity: quantity,
    );
  }

  void removeItem(String productId, String size) {
    _itemsByKey.remove(_key(productId, size));
  }

  void clear() {
    _itemsByKey.clear();
  }

  int getTotalItems() {
    return _itemsByKey.values.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  double getTotalPrice() {
    return _itemsByKey.values.fold<double>(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
  }
}
