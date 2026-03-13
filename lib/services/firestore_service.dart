import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/review_model.dart';
import '../models/order_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- HÀM XỬ LÝ ẢNH (Dùng cho UC16) ---

  /// Upload ảnh lên Storage và trả về URL để lưu vào Firestore
  Future<String> uploadImage(File imageFile) async {
    try {
      // Tạo tên file duy nhất bằng timestamp
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage.ref().child('products').child('$fileName.jpg');

      // Upload file
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      // Lấy URL tải về
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Lỗi upload ảnh: $e");
      return "";
    }
  }

  /// Xóa ảnh trên Storage khi xóa sản phẩm (để tiết kiệm tài nguyên)
  Future<void> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isNotEmpty && imageUrl.contains('firebase')) {
        await _storage.refFromURL(imageUrl).delete();
      }
    } catch (e) {
      print("Lỗi xóa ảnh: $e");
    }
  }

  // --- QUẢN LÝ CATEGORY (UC17) ---
  Stream<List<CategoryModel>> getCategories() {
    return _db.collection('categories').snapshots().map((snap) =>
        snap.docs.map((doc) => CategoryModel.fromDoc(doc.id, doc.data())).toList());
  }

  Future<void> addCategory(String name) => _db.collection('categories').add({'name': name});

  Future<void> deleteCategory(String id) => _db.collection('categories').doc(id).delete();

  // --- QUẢN LÝ PRODUCT (UC15 & UC16) ---
  Stream<List<ProductModel>> getProducts() {
    return _db.collection('products').snapshots().map((snap) =>
        snap.docs.map((doc) => ProductModel.fromFirestore(doc.id, doc.data())).toList());
  }

  // Thêm sản phẩm mới (Dữ liệu p.sizesStock đã được xử lý từ UI)
  Future<void> addProduct(ProductModel p) => _db.collection('products').add(p.toMap());

  // Cập nhật sản phẩm
  Future<void> updateProduct(ProductModel p) =>
      _db.collection('products').doc(p.id).update(p.toMap());

  // Xóa sản phẩm và xóa luôn ảnh trên Storage
  Future<void> deleteProduct(String id, String? imageUrl) async {
    if (imageUrl != null) await deleteImage(imageUrl);
    return _db.collection('products').doc(id).delete();
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