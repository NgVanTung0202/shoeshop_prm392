import 'package:flutter/foundation.dart'; // Đã sửa ở đây
import 'package:cloud_firestore/cloud_firestore.dart';

class DBSeeder {
  static Future<void> seedAll() async {
    final db = FirebaseFirestore.instance;
    debugPrint("🚀 Bắt đầu Seed dữ liệu...");

    try {
      // 1. Tạo Categories và lấy ID về
      final sneakerRef = await db.collection("categories").add({
        "name": "Sneakers",
        "imageUrl": "https://cdn-icons-png.flaticon.com/512/2742/2742674.png"
      });
      final sandalRef = await db.collection("categories").add({
        "name": "Sandals",
        "imageUrl": "https://cdn-icons-png.flaticon.com/512/2553/2553714.png"
      });

      debugPrint("✅ Đã tạo Danh mục");

      // 2. Tạo Products mẫu với CategoryId chính xác
      List<Map<String, dynamic>> products = [
        {
          'name': 'Nike Air Max 2026',
          'price': 2500000.0,
          'categoryId': sneakerRef.id,
          'brand': 'Nike',
          'imageUrl': 'https://static.nike.com/a/images/t_PDP_1280_v1/f_auto,q_auto:eco/99486149-0345-41ef-8b89-4670081d5f2a/air-force-1-07-shoes-Wr0Q1H.png',
          'description': 'Mẫu giày chạy bộ cao cấp nhất của Nike năm 2026.',
          'sizesStock': {'39': 5, '40': 5, '41': 6, '42': 4},
        },
        {
          'name': 'Adidas UltraBoost v5',
          'price': 3200000.0,
          'categoryId': sneakerRef.id,
          'brand': 'Adidas',
          'imageUrl': 'https://assets.adidas.com/images/h_840,f_auto,q_auto,fl_lossy,c_fill,g_auto/0f4327463f6449179017af3200057f97_9366/Giay_UltraBoost_Light_trang_HQ6351_01_standard.jpg',
          'description': 'Sự kết hợp hoàn hảo giữa thời trang và hiệu năng.',
          'sizesStock': {'38': 2, '39': 10, '40': 15, '41': 3},
        },
        {
          'name': 'Classic Sandal XL',
          'price': 450000.0,
          'categoryId': sandalRef.id,
          'brand': 'Bitis',
          'imageUrl': 'https://bitis.com.vn/cdn/shop/products/3_84967394-3758-4503-912b-7b089c25f190_1024x1024.jpg',
          'description': 'Sandal bền bỉ cho mùa hè năng động.',
          'sizesStock': {'36': 10, '37': 10, '38': 10, '39': 10},
        }
      ];

      for (var p in products) {
        await db.collection("products").add(p);
      }
      debugPrint("✅ Đã tạo Sản phẩm");

      // 3. Tạo Đơn hàng mẫu (Giả lập dữ liệu các ngày khác nhau để vẽ biểu đồ)
      final today = DateTime.now();
      List<Map<String, dynamic>> orders = [
        {
          'totalPrice': 1200000.0,
          'status': 'Completed',
          'shippingAddress': 'Hà Nội',
          'createdAt': Timestamp.fromDate(today),
        },
        {
          'totalPrice': 2500000.0,
          'status': 'Completed',
          'shippingAddress': 'HCM',
          'createdAt': Timestamp.fromDate(today.subtract(const Duration(days: 1))),
        },
        {
          'totalPrice': 450000.0,
          'status': 'Completed',
          'shippingAddress': 'Đà Nẵng',
          'createdAt': Timestamp.fromDate(today.subtract(const Duration(days: 2))),
        },
        {
          'totalPrice': 3200000.0,
          'status': 'Completed',
          'shippingAddress': 'Hải Phòng',
          'createdAt': Timestamp.fromDate(today.subtract(const Duration(days: 5))),
        }
      ];

      for (var o in orders) {
        await db.collection('orders').add(o);
      }

      debugPrint("✅ Đã tạo Đơn hàng mẫu (xem Chart)");
      debugPrint("--- HOÀN TẤT SEED DỮ LIỆU ---");

    } catch (e) {
      debugPrint("❌ Lỗi khi seed dữ liệu: $e");
    }
  }
}