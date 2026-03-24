import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';
import '../models/order_model.dart';
import '../services/cart_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Danh mục dự phòng: sản phẩm được gán về đây khi xóa danh mục; không cho xóa doc này.
  static const String defaultUncategorizedCategoryId = 'uncategorized';
  static const String defaultUncategorizedCategoryName = 'Chưa phân loại';

  String _normalizeOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'chờ xác nhận':
        return 'Chờ xác nhận';
      case 'đã xác nhận đơn hàng':
        return 'Đã xác nhận đơn hàng';
      case 'đang chuẩn bị hàng':
        return 'Đang chuẩn bị hàng';
      case 'đã giao cho đơn vị vận chuyển':
        return 'Đã giao cho đơn vị vận chuyển';
      case 'shipping':
      case 'đang giao':
      case 'đang giao hàng':
        return 'Đang giao hàng';
      case 'completed':
      case 'hoàn thành':
      case 'giao hàng thành công':
        return 'Giao hàng thành công';
      case 'cancelled':
      case 'đã hủy':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  bool _canCustomerCancel(String status) {
    final normalized = _normalizeOrderStatus(status);
    return normalized == 'Chờ xác nhận' ||
        normalized == 'Đã xác nhận đơn hàng' ||
        normalized == 'Đang chuẩn bị hàng';
  }

  bool _isValidStatusTransition(String currentStatus, String nextStatus) {
    final current = _normalizeOrderStatus(currentStatus);
    final next = _normalizeOrderStatus(nextStatus);

    if (current == next) return false;

    switch (current) {
      case 'Chờ xác nhận':
        return next == 'Đã xác nhận đơn hàng' || next == 'Đã hủy';
      case 'Đã xác nhận đơn hàng':
        return next == 'Đang chuẩn bị hàng' || next == 'Đã hủy';
      case 'Đang chuẩn bị hàng':
        return next == 'Đã giao cho đơn vị vận chuyển' || next == 'Đã hủy';
      case 'Đã giao cho đơn vị vận chuyển':
        return next == 'Đang giao hàng';
      case 'Đang giao hàng':
        return next == 'Giao hàng thành công';
      default:
        return false;
    }
  }

  /// ================= USERS =================

  Stream<QuerySnapshot> getUsers() {
    return _db.collection("users").snapshots();
  }

  Future<void> deleteUser(String uid) async {
    await _db.collection("users").doc(uid).delete();
  }

  Future<void> updateUserRole(String uid, String role) async {
    await _db.collection("users").doc(uid).update({"role": role});
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
  }) async {
    await _db.collection("users").doc(uid).update({
      "name": name,
      "phone": phone,
    });
  }

  /// Upload ảnh đại diện lên Storage rồi cập nhật Firestore
  Future<void> updateProfileWithAvatar({
    required String uid,
    required String name,
    required String phone,
    File? avatarFile,
    String? existingAvatarUrl,
  }) async {
    String? avatarUrl = existingAvatarUrl;

    if (avatarFile != null) {
      final ref = _storage.ref().child("avatars/$uid.jpg");
      await ref.putFile(avatarFile);
      avatarUrl = await ref.getDownloadURL();
    }

    await _db.collection("users").doc(uid).update({
      "name": name,
      "phone": phone,
      if (avatarUrl != null) "avatarUrl": avatarUrl,
    });
  }

  /// Upload avatar dùng XFile (hoạt động trên Web, Windows, Android, iOS)
  /// Trả về URL mới nếu có upload, null nếu không đổi ảnh
  Future<String?> updateProfileWithAvatarXFile({
    required String uid,
    required String name,
    required String phone,
    XFile? xfile,
    String? existingAvatarUrl,
  }) async {
    String? avatarUrl = existingAvatarUrl;

    if (xfile != null) {
      final ref = _storage.ref().child("avatars/$uid.jpg");
      final bytes = await xfile.readAsBytes();
      final metadata = SettableMetadata(contentType: "image/jpeg");
      await ref.putData(bytes, metadata);
      avatarUrl = await ref.getDownloadURL();
    }

    await _db.collection("users").doc(uid).update({
      "name": name,
      "phone": phone,
      if (avatarUrl != null) "avatarUrl": avatarUrl,
    });

    return xfile != null ? avatarUrl : null;
  }

  Future<void> createStaffAccount({
    required String email,
    required String name,
    required String phone,
    required String role,
  }) async {
    await _db.collection("users").add({
      "email": email,
      "name": name,
      "phone": phone,
      "role": role,
      "createdAt": Timestamp.now(),
    });
  }

  /// Admin cập nhật thông tin user (name, phone, role)
  Future<void> updateUserInfo({
    required String uid,
    required String name,
    required String phone,
    required String role,
  }) async {
    await _db.collection("users").doc(uid).update({
      "name": name,
      "phone": phone,
      "role": role,
    });
  }

  /// ================= CATEGORY =================

  Stream<List<CategoryModel>> getCategories() {
    return _db.collection("categories").snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return CategoryModel(
              id: doc.id,
              name: data["name"] ?? "",
              isDeleted: data["isDeleted"] == true,
            );
          })
          .where((c) => !c.isDeleted)
          .toList();
    });
  }

  Future<void> addCategory(String name) async {
    await _db.collection("categories").add({
      "name": name,
      "isDeleted": false,
    });
  }

  Future<void> updateCategory(String id, String name) async {
    await _db.collection("categories").doc(id).update({
      "name": name,
    });
  }

  /// Tạo (nếu chưa có) danh mục mặc định để gán sản phẩm khi xóa danh mục.
  Future<String> ensureDefaultUncategorizedCategory() async {
    final ref =
        _db.collection("categories").doc(defaultUncategorizedCategoryId);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        "name": defaultUncategorizedCategoryName,
        "isDeleted": false,
      });
    }
    return defaultUncategorizedCategoryId;
  }

  /// Xóa mềm danh mục: gán mọi sản phẩm sang [Chưa phân loại], rồi đánh dấu `isDeleted`.
  Future<void> deleteCategory(String categoryId) async {
    if (categoryId == defaultUncategorizedCategoryId) {
      throw Exception(
          'Không thể xóa danh mục mặc định "$defaultUncategorizedCategoryName".');
    }

    await ensureDefaultUncategorizedCategory();

    final productsSnap = await _db
        .collection("products")
        .where("categoryId", isEqualTo: categoryId)
        .get();

    const int batchSize = 400;
    WriteBatch batch = _db.batch();
    int ops = 0;

    for (final doc in productsSnap.docs) {
      batch.update(doc.reference, {
        "categoryId": defaultUncategorizedCategoryId,
      });
      ops++;
      if (ops >= batchSize) {
        await batch.commit();
        batch = _db.batch();
        ops = 0;
      }
    }
    if (ops > 0) {
      await batch.commit();
    }

    await _db.collection("categories").doc(categoryId).update({
      "isDeleted": true,
    });
  }

  /// ================= PRODUCT =================

  Stream<List<ProductModel>> getProducts() {
    return _db.collection("products").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ProductModel.fromFirestore(doc.id, data);
      }).toList();
    });
  }

  Stream<List<ProductModel>> getProductsByCategory(String categoryId) {
    return _db.collection('products')
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => ProductModel.fromFirestore(doc.id, doc.data())).toList());
  }

  Future<List<String>> getAllBrands() async {
    final snapshot = await _db.collection('products').get();
    final Set<String> brands = {};
    for (var doc in snapshot.docs) {
      if (doc.data()['brand'] != null && doc.data()['brand'].toString().trim().isNotEmpty) {
        brands.add(doc.data()['brand'].toString().trim().toUpperCase());
      }
    }
    return brands.toList();
  }

  Future<void> addProduct(ProductModel product) async {
    await _db.collection("products").add(product.toMap());
  }

  Future<void> updateProduct(ProductModel product) async {
    await _db.collection("products").doc(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(String id, String imageUrl) async {
    await _db.collection("products").doc(id).delete();
    if (imageUrl.isNotEmpty) {
      try {
        await _storage.refFromURL(imageUrl).delete();
      } catch (_) {
        // Bỏ qua nếu ảnh không tồn tại trên storage
      }
    }
  }

  /// ================= IMAGE UPLOAD =================

  Future<String> uploadImage(File file) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = _storage.ref().child("images/$fileName.jpg");
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  /// Web / mobile: không dùng dart:io File — dùng XFile + putData.
  Future<String> uploadImageFromXFile(XFile xfile) async {
    final original = xfile.name;
    final ext = original.contains('.')
        ? original.substring(original.lastIndexOf('.')).toLowerCase()
        : '.jpg';
    const allowed = {'.jpg', '.jpeg', '.png', '.webp'};
    final safeExt = allowed.contains(ext) ? ext : '.jpg';
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$safeExt';
    final ref = _storage.ref().child('images/$fileName');
    final bytes = await xfile.readAsBytes();
    final metadata = SettableMetadata(
      contentType: _imageContentTypeForExtension(safeExt),
    );
    await ref.putData(bytes, metadata);
    return await ref.getDownloadURL();
  }

  String _imageContentTypeForExtension(String ext) {
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// ================= REVIEWS =================

  // Thêm review mới (Sử dụng collection 'reviews' riêng để dễ quản lý)
  Future<void> addReview(ReviewModel review) async {
    await _db.collection('reviews').doc(review.id).set(review.toMap());
  }

  // Lấy danh sách review của một sản phẩm
  Stream<List<ReviewModel>> getProductReviews(String productId) {
    return _db
        .collection('reviews')
        .where('productId', isEqualTo: productId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => ReviewModel.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// ================= ORDERS =================

  Future<String> createOrder({
    required String userId,
    required String receiverName,
    required String phone,
    required String address,
    required String paymentMethod,
    List<CartItem>? orderItems,
  }) async {
    final cartService = CartService();
    final cartItems = orderItems != null
        ? List<CartItem>.from(orderItems)
        : cartService.items.toList();

    if (cartItems.isEmpty) {
      throw Exception('Cart is empty');
    }

    final orderRef = _db.collection('orders').doc();

    // Calculate total price
    double totalPrice = 0;
    for (var item in cartItems) {
      totalPrice += item.product.price * item.quantity;
    }

    await _db.runTransaction((transaction) async {
      // 1. Read all product documents to check stock
      Map<String, DocumentSnapshot> productDocs = {};
      for (var item in cartItems) {
        if (!productDocs.containsKey(item.product.id)) {
          final pDoc = await transaction
              .get(_db.collection('products').doc(item.product.id));
          if (!pDoc.exists) {
            throw Exception('Product ${item.product.name} no longer exists');
          }
          productDocs[item.product.id] = pDoc;
        }
      }

      // 2. Validate stock and prepare deductions
      Map<String, Map<String, int>> updatedSizesStock = {};

      for (var item in cartItems) {
        final pDoc = productDocs[item.product.id]!;
        final data = pDoc.data() as Map<String, dynamic>;

        Map<String, int> sizesStock = {};
        if (data['sizes_stock'] != null) {
          sizesStock = Map<String, int>.from(data['sizes_stock']);
        }

        // Use updated if already modified in this transaction loop
        if (updatedSizesStock.containsKey(item.product.id)) {
          sizesStock = updatedSizesStock[item.product.id]!;
        }

        int available = sizesStock[item.size] ?? 0;
        if (available < item.quantity) {
          throw Exception(
              'Product ${item.product.name} (Size: ${item.size}) is out of stock');
        }

        sizesStock[item.size] = available - item.quantity;
        updatedSizesStock[item.product.id] = sizesStock;
      }

      // 3. Apply deductions and increase sold count
      updatedSizesStock.forEach((productId, newSizesStock) {
        // Calculate total quantity of this product ordered in this order
        int totalQuantityOrdered = cartItems
            .where((item) => item.product.id == productId)
            .fold(0, (acc, item) => acc + item.quantity);

        transaction.update(_db.collection('products').doc(productId), {
          'sizes_stock': newSizesStock,
          'soldCount': FieldValue.increment(totalQuantityOrdered), // Fix: actually increase soldCount!
        });
      });

      // 4. Create Order
      transaction.set(orderRef, {
        'userId': userId,
        'receiverName': receiverName,
        'phone': phone,
        'address': address,
        'paymentMethod': paymentMethod, // COD or ONLINE
        'totalPrice': totalPrice,
        'status': paymentMethod == 'ONLINE' ? 'Đã thanh toán' : 'Chờ xác nhận', // Fix: differentiate status
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 5. Create Order Items
      for (var item in cartItems) {
        final itemRef = orderRef.collection('items').doc();
        transaction.set(itemRef, {
          'productId': item.product.id,
          'productName': item.product.name,
          'imageUrl': item.product.imageUrl,
          'size': item.size,
          'quantity': item.quantity,
          'price': item.product.price,
        });
      }
    });

    // Remove ordered items from cart after successful transaction.
    if (orderItems != null) {
      for (final item in cartItems) {
        cartService.removeItem(item.product.id, item.size);
      }
    } else {
      cartService.clear();
    }

    return orderRef.id;
  }

  Future<void> cancelOrder(String orderId, String userId) async {
    await _db.runTransaction((transaction) async {
      final orderRef = _db.collection('orders').doc(orderId);
      final orderDoc = await transaction.get(orderRef);

      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final data = orderDoc.data() as Map<String, dynamic>;
      if (data['userId'] != userId) {
        throw Exception('Unauthorized');
      }

      if (!_canCustomerCancel((data['status'] ?? '').toString())) {
        throw Exception('Cannot cancel this order');
      }

      // Get all items to restore stock
      final itemsQuery = await orderRef.collection('items').get();

      // Update order status
      transaction.update(orderRef, {
        'status': 'Đã hủy',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Read current products to restore
      for (var itemDoc in itemsQuery.docs) {
        final itemData = itemDoc.data();
        final productId = itemData['productId'];
        final size = itemData['size'];
        final qty = itemData['quantity'] as int;

        final productRef = _db.collection('products').doc(productId);
        final productDoc = await transaction.get(productRef);

        if (productDoc.exists) {
          final pData = productDoc.data() as Map<String, dynamic>;
          Map<String, int> sizesStock = {};
          if (pData['sizes_stock'] != null) {
            sizesStock = Map<String, int>.from(pData['sizes_stock']);
          }

          sizesStock[size] = (sizesStock[size] ?? 0) + qty;

          transaction.update(productRef, {'sizes_stock': sizesStock});
        }
      }
    });
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _db.runTransaction((transaction) async {
      final orderRef = _db.collection('orders').doc(orderId);
      final orderDoc = await transaction.get(orderRef);

      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final currentStatus = _normalizeOrderStatus(
          (orderDoc.data() as Map<String, dynamic>)['status']?.toString() ??
              '');
      final normalizedStatus = _normalizeOrderStatus(newStatus);

      if (!_isValidStatusTransition(currentStatus, normalizedStatus)) {
        throw Exception(
            'Invalid status transition: $currentStatus -> $normalizedStatus');
      }

      transaction.update(orderRef, {
        'status': normalizedStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (normalizedStatus == 'Đã hủy') {
        // Restore stock
        final itemsQuery = await orderRef.collection('items').get();
        for (var itemDoc in itemsQuery.docs) {
          final itemData = itemDoc.data();
          final productId = itemData['productId'];
          final size = itemData['size'];
          final qty = itemData['quantity'] as int;

          final productRef = _db.collection('products').doc(productId);
          final productDoc = await transaction.get(productRef);

          if (productDoc.exists) {
            final pData = productDoc.data() as Map<String, dynamic>;
            Map<String, int> sizesStock = {};
            if (pData['sizes_stock'] != null) {
              sizesStock = Map<String, int>.from(pData['sizes_stock']);
            }
            sizesStock[size] = (sizesStock[size] ?? 0) + qty;

            transaction.update(productRef, {'sizes_stock': sizesStock});
          }
        }
      }
    });
  }

  Stream<List<OrderModel>> getAllOrders() {
    return _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => OrderModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }
}
