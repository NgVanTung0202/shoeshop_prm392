import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/category_model.dart';
 update-code
import '../models/product_model.dart';
import '../models/review_model.dart'; // Đảm bảo import model này

import '../models/review_model.dart';
import '../models/order_model.dart';
 main

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return CategoryModel(
          id: doc.id,
          name: data["name"] ?? "",
          imageUrl: data["imageUrl"] ?? "",
        );
      }).toList();
    });
  }

  Future<void> addCategory(String name, {String imageUrl = ""}) async {
    await _db.collection("categories").add({
      "name": name,
      "imageUrl": imageUrl,
    });
  }

  Future<void> updateCategory(String id, String name,
      {String imageUrl = ""}) async {
    await _db.collection("categories").doc(id).update({
      "name": name,
      "imageUrl": imageUrl,
    });
  }

  Future<void> deleteCategory(String id) async {
    await _db.collection("categories").doc(id).delete();
  }

  /// ================= PRODUCT =================

  Stream<List<ProductModel>> getProducts() {
    return _db.collection("products").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ProductModel.fromFirestore(
          doc.id,
          data,
        );
      }).toList();
    });
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
        await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      } catch (_) {}
    }
  }

  /// ================= IMAGE UPLOAD =================

  Future<String> uploadImage(File file) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = _storage.ref().child("images/$fileName.jpg");
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  /// ================= REVIEWS =================

  // Thêm review mới vào Sub-collection của Product
  Future<void> addReview(ReviewModel review) async {
    await _db
        .collection('products')
        .doc(review.productId)
        .collection('reviews')
        .add(review.toMap());
  }

  // Lấy danh sách review của một sản phẩm cụ thể (Stream)
  Stream<List<ReviewModel>> getProductReviews(String productId) {
    return _db
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // --- QUẢN LÝ ĐÁNH GIÁ (UC21, UC22) ---
  Stream<List<ReviewModel>> getProductReviews(String productId) {
    return _db.collection('reviews')
        .where('productId', isEqualTo: productId)
        // .orderBy('createdAt', descending: true) // Đã gỡ bỏ để tránh lỗi Index Firebase
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((doc) => ReviewModel.fromFirestore(doc.id, doc.data())).toList();
          // Sort mảng ở Client
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> addReview(ReviewModel review) => _db.collection('reviews').doc(review.id).set(review.toMap());

  // --- QUẢN LÝ ĐƠN HÀNG (Dùng cho Dashboard UC23) ---
  Stream<List<OrderModel>> getAllOrders() {
    return _db.collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => OrderModel.fromFirestore(doc.id, doc.data())).toList());
  }
}