import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quản lý sản phẩm (UC15)")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // Chuyển đổi dữ liệu từ Firestore sang danh sách ProductModel
          List<ProductModel> products = snapshot.data!.docs.map((doc) {
            return ProductModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
          }).toList();

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              return ListTile(
                leading: Image.network(p.imageUrl, width: 50, fit: BoxFit.cover),
                title: Text(p.name),
                subtitle: Text("${p.price} VNĐ - Kho: ${p.stock}"),
                trailing: const Icon(Icons.edit), // Nút để làm UC16 sau này
              );
            },
          );
        },
      ),
    );
  }
}