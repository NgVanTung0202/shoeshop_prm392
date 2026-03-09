import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import 'admin_products_screen.dart'; // Đảm bảo import đúng file quản lý sản phẩm

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tổng quan sản phẩm", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Lắng nghe dữ liệu từ collection 'products'
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Đã xảy ra lỗi!"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // Chuyển đổi dữ liệu từ Firestore sang danh sách ProductModel mới (có sizesStock)
          List<ProductModel> products = snapshot.data!.docs.map((doc) {
            return ProductModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
          }).toList();

          if (products.isEmpty) return const Center(child: Text("Chưa có sản phẩm nào."));

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      p.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                    ),
                  ),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  // Sửa lỗi hiển thị stock: Dùng hàm getTotalStock() từ Model mới
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Giá: ${p.price.toInt()}đ"),
                      Text(
                        "Tổng tồn kho: ${p.getTotalStock()} đôi",
                        style: TextStyle(
                            color: p.getTotalStock() == 0 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w500
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.blue),
                  onTap: () {
                    // Chuyển sang màn hình quản lý chi tiết (AdminProductsScreen) khi bấm vào
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminProductsScreen()),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}