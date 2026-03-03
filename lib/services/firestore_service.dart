import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- QUẢN LÝ CATEGORY (UC17) ---
  Stream<List<CategoryModel>> getCategories() {
    return _db.collection('categories').snapshots().map((snap) =>
        snap.docs.map((doc) => CategoryModel.fromDoc(doc.id, doc.data() as Map<String, dynamic>)).toList());
  }

  Future<void> addCategory(String name) => _db.collection('categories').add({'name': name});

  Future<void> deleteCategory(String id) => _db.collection('categories').doc(id).delete();

  // --- QUẢN LÝ PRODUCT (UC15 & UC16) ---
  Stream<List<ProductModel>> getProducts() {
    return _db.collection('products').snapshots().map((snap) =>
        snap.docs.map((doc) => ProductModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>)).toList());
  }

  Future<void> addProduct(ProductModel p) => _db.collection('products').add(p.toMap());

  Future<void> updateProduct(ProductModel p) => _db.collection('products').doc(p.id).update(p.toMap());

  Future<void> deleteProduct(String id) => _db.collection('products').doc(id).delete();
}