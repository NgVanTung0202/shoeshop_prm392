import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DBSeeder {

  static Future<void> seedDatabase() async {

    final db = FirebaseFirestore.instance;

    debugPrint("Start seeding database...");

 update-code
    await db.collection("categories").add({
      "name": "Sneakers",
      "imageUrl": ""
    });

    // 2. Tạo Products mẫu (UC07, 15, 16)
    // Dữ liệu bao gồm: name, price, categoryId, imageUrl, description, stock, brand
    List<Map<String, dynamic>> products = [
      {
        'name': 'Nike Air Max 2026',
        'price': 2500000.0,
        'categoryId': catSneaker.id,
        'brand': 'Nike',
        'imageUrl': 'https://static.nike.com/a/images/t_PDP_1280_v1/f_auto,q_auto:eco/99486149-0345-41ef-8b89-4670081d5f2a/air-force-1-07-shoes-Wr0Q1H.png',
        'description': 'Mẫu giày chạy bộ cao cấp nhất của Nike năm 2026.',
        'sizes_stock': {'39': 5, '40': 5, '41': 6, '42': 4},
      },
      {
        'name': 'Adidas UltraBoost v5',
        'price': 3200000.0,
        'categoryId': catSneaker.id,
        'brand': 'Adidas',
        'imageUrl': 'https://assets.adidas.com/images/h_840,f_auto,q_auto,fl_lossy,c_fill,g_auto/0f4327463f6449179017af3200057f97_9366/Giay_UltraBoost_Light_trang_HQ6351_01_standard.jpg',
        'description': 'Sự kết hợp hoàn hảo giữa thời trang và hiệu năng.',
        'sizes_stock': {'38': 2, '39': 10, '40': 15, '41': 3},
      },
      {
        'name': 'Classic Sandal XL',
        'price': 450000.0,
        'categoryId': catSandal.id,
        'brand': 'Bitis',
        'imageUrl': 'https://bitis.com.vn/cdn/shop/products/3_84967394-3758-4503-912b-7b089c25f190_1024x1024.jpg',
        'description': 'Sandal bền bỉ cho mùa hè năng động.',
        'sizes_stock': {'36': 10, '37': 10, '38': 10, '39': 10},
      }
    ];
 main

    await db.collection("categories").add({
      "name": "Running",
      "imageUrl": ""
    });

    debugPrint("Categories seeded");

    await db.collection("products").add({
      "name": "Nike Air Max",
      "brand": "Nike",
      "price": 2500000,
      "categoryId": "",
      "imageUrl": "",
      "description": "Comfort running shoes",
      "sizesStock": {
        "39": 5,
        "40": 3
      }
    });

 update-code
    debugPrint("Products seeded");

    debugPrint("Database seed completed");

    print("✔ Đã tạo User Admin mẫu");

    // 4. Tạo các báo cáo Đơn hàng mẫu (Giả lập) để xem Thống kê
    final today = DateTime.now();
    List<Map<String, dynamic>> orders = [
      {
        'id': 'ORD-001',
        'userId': 'customer_test_id',
        'items': [],
        'totalPrice': 1200000.0,
        'status': 'Completed',
        'shippingAddress': 'Hà Nội',
        'createdAt': Timestamp.fromDate(today), // Hôm nay
      },
      {
        'id': 'ORD-002',
        'userId': 'customer_test_id',
        'items': [],
        'totalPrice': 2500000.0,
        'status': 'Completed',
        'shippingAddress': 'HCM',
        'createdAt': Timestamp.fromDate(today.subtract(const Duration(days: 1))), // Hôm qua
      },
      {
        'id': 'ORD-003',
        'userId': 'customer_test_id',
        'items': [],
        'totalPrice': 450000.0,
        'status': 'Completed',
        'shippingAddress': 'Đà Nẵng',
        'createdAt': Timestamp.fromDate(today.subtract(const Duration(days: 2))), // Hôm kia
      },
      {
        'id': 'ORD-004',
        'userId': 'customer_test_id',
        'items': [],
        'totalPrice': 3200000.0,
        'status': 'Completed',
        'shippingAddress': 'Hải Phòng',
        'createdAt': Timestamp.fromDate(today.subtract(const Duration(days: 5))), // 5 ngày trước
      }
    ];

    for (var o in orders) {
      await db.collection('orders').doc(o['id']).set(o);
    }
    print("✔ Đã tạo các Đơn hàng mẫu (để xem Chart)");

    print("--- HOÀN TẤT SEED DỮ LIỆU ---");
 main
  }
}
