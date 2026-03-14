import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';

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
    await _db.collection("users").doc(uid).update({
      "role": role
    });
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

  Future<void> addCategory(String name,{String imageUrl = ""}) async {

    await _db.collection("categories").add({
      "name": name,
      "imageUrl": imageUrl,
    });
  }

  Future<void> updateCategory(
      String id,
      String name,
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

    await _db.collection("products")
        .doc(product.id)
        .update(product.toMap());
  }

  Future<void> deleteProduct(String id,String imageUrl) async {

    await _db.collection("products").doc(id).delete();

    if (imageUrl.isNotEmpty) {

      try {
        await FirebaseStorage.instance
            .refFromURL(imageUrl)
            .delete();
      } catch (_) {}
    }
  }

  /// ================= IMAGE UPLOAD =================

  Future<String> uploadImage(File file) async {

    final fileName =
        DateTime.now().millisecondsSinceEpoch.toString();

    final ref =
        _storage.ref().child("images/$fileName.jpg");

    await ref.putFile(file);

    return await ref.getDownloadURL();
  }
}
