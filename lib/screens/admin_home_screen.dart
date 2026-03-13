import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import 'admin_products_screen.dart';
import 'admin_dashboard_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tổng quan kho", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Dashboard Thống Kê',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => AdminDashboardScreen()));
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(

        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Đã xảy ra lỗi kết nối!"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Chuyển đổi dữ liệu sang ProductModel (đã bao gồm field 'brand')
          List<ProductModel> products = snapshot.data!.docs.map((doc) {
            return ProductModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
          }).toList();

          if (products.isEmpty) {
            return const Center(child: Text("Kho hàng trống. Hãy thêm sản phẩm!"));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              final totalStock = p.getTotalStock();

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Hero(
                      tag: p.id, // Tạo hiệu ứng chuyển cảnh mượt
                      child: Image.network(
                        p.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 60, height: 60, color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hiển thị Brand và Giá
                        Text(
                          "Hãng: ${p.brand.toUpperCase()}",
                          style: TextStyle(color: Colors.blueGrey[700], fontWeight: FontWeight.w500),
                        ),
                        Text(
                          "Giá: ${p.price.toInt()} VNĐ",
                          style: const TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        // Hiển thị trạng thái kho hàng
                        Row(
                          children: [
                            Icon(
                                Icons.inventory_2_outlined,
                                size: 16,
                                color: totalStock == 0 ? Colors.red : Colors.green
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Tồn kho: $totalStock đôi",
                              style: TextStyle(
                                  color: totalStock == 0 ? Colors.red : Colors.green[700],
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {

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