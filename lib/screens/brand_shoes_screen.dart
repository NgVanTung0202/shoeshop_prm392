import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/firestore_service.dart';

/// Danh sách hãng và mẫu lấy từ Firestore (không dùng dữ liệu hard-code).
class BrandShoesScreen extends StatefulWidget {
  final Function(String name) onShoeSelected;

  const BrandShoesScreen({super.key, required this.onShoeSelected});

  @override
  State<BrandShoesScreen> createState() => _BrandShoesScreenState();
}

class _BrandShoesScreenState extends State<BrandShoesScreen> {
  final FirestoreService _fs = FirestoreService();

  Map<String, List<ProductModel>> _groupByBrand(List<ProductModel> products) {
    final map = <String, List<ProductModel>>{};
    for (final p in products) {
      final b = p.brand.trim().isEmpty ? 'Khác' : p.brand;
      map.putIfAbsent(b, () => []).add(p);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    final keys = map.keys.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return {for (final k in keys) k: map[k]!};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Danh mục Hãng & Mẫu giày',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: _fs.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Không thể tải sản phẩm'));
          }
          final grouped = _groupByBrand(snapshot.data ?? []);
          if (grouped.isEmpty) {
            return const Center(child: Text('Chưa có sản phẩm trên cửa hàng'));
          }
          final brands = grouped.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: brands.length,
            itemBuilder: (context, index) {
              final brand = brands[index];
              final items = grouped[brand] ?? [];

              return Card(
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  collapsedShape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  iconColor: Colors.blue,
                  collapsedIconColor: Colors.grey,
                  title: Text(
                    brand,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  children: items.map((product) {
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shopping_bag_outlined, color: Colors.blue, size: 20),
                      ),
                      title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(
                        product.brand,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      onTap: () {
                        widget.onShoeSelected(product.name);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
