import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DBSeeder {
  static Future<void> seedAll() async {
    await seedDatabase();
  }

  static Future<void> seedDatabase() async {
    final FirebaseFirestore db = FirebaseFirestore.instance;

    debugPrint('🚀 Bắt đầu Seed dữ liệu database...');

    try {
      // 1. Tạo Categories với ID cố định (HEAD style) để tránh tạo trùng
      final DocumentReference<Map<String, dynamic>> catSneakerRef =
          db.collection('categories').doc('seed_sneakers');
      final DocumentReference<Map<String, dynamic>> catRunningRef =
          db.collection('categories').doc('seed_running');
      final DocumentReference<Map<String, dynamic>> catSandalRef =
          db.collection('categories').doc('seed_sandal');

      await catSneakerRef.set({
        'name': 'Sneakers',
        'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2742/2742674.png'
      });
      await catRunningRef.set({
        'name': 'Running',
        'imageUrl': 'https://cdn-icons-png.flaticon.com/512/10336/10336279.png'
      });
      await catSandalRef.set({
        'name': 'Sandal',
        'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2553/2553714.png'
      });

      debugPrint('✅ Categories seeded');

      // 2. Danh sách sản phẩm mẫu (Sử dụng URL ảnh thật từ main)
      final List<Map<String, dynamic>> products = [
        {
          'docId': 'seed_nike_air_max_2026',
          'name': 'Nike Air Max 2026',
          'price': 2500000.0,
          'categoryId': catSneakerRef.id,
          'brand': 'Nike',
          'imageUrl':
              'https://static.nike.com/a/images/t_PDP_1280_v1/f_auto,q_auto:eco/99486149-0345-41ef-8b89-4670081d5f2a/air-force-1-07-shoes-Wr0Q1H.png',
          'description': 'Mẫu giày chạy bộ cao cấp nhất của Nike năm 2026.',
          'sizesStock': {'39': 5, '40': 5, '41': 6, '42': 4},
        },
        {
          'docId': 'seed_adidas_ultraboost_v5',
          'name': 'Adidas UltraBoost v5',
          'price': 3200000.0,
          'categoryId': catRunningRef.id,
          'brand': 'Adidas',
          'imageUrl':
              'https://assets.adidas.com/images/h_840,f_auto,q_auto,fl_lossy,c_fill,g_auto/0f4327463f6449179017af3200057f97_9366/Giay_UltraBoost_Light_trang_HQ6351_01_standard.jpg',
          'description': 'Sự kết hợp hoàn hảo giữa thời trang và hiệu năng.',
          'sizesStock': {'38': 2, '39': 10, '40': 15, '41': 3},
        },
        {
          'docId': 'seed_classic_sandal_xl',
          'name': 'Classic Sandal XL',
          'price': 450000.0,
          'categoryId': catSandalRef.id,
          'brand': 'Bitis',
          'imageUrl':
              'https://picsum.photos/seed/shoeshop_bitis_sandal/1024/1024',
          'description': 'Sandal bền bỉ cho mùa hè năng động.',
          'sizesStock': {'36': 10, '37': 10, '38': 10, '39': 10},
        },
      ];

      for (final p in products) {
        final String docId = p.remove('docId') as String;
        await db.collection('products').doc(docId).set(p);
      }
      debugPrint('✅ Products seeded');

      // 3. Admin User
      await db.collection('users').doc('seed_admin').set({
        'email': 'admin@shoeshop.local',
        'name': 'Admin Manager',
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Admin user seeded');

      // 4. Tạo Đơn hàng mẫu (Dữ liệu cho biểu đồ Dashboard)
      final DateTime today = DateTime.now();
      final List<Map<String, dynamic>> orders = [
        {
          'id': 'ORD-001',
          'userId': 'seed_customer',
          'items': [],
          'totalPrice': 1200000.0,
          'status': 'Hoàn thành',
          'shippingAddress': 'Hà Nội',
          'createdAt': Timestamp.fromDate(today),
        },
        {
          'id': 'ORD-002',
          'userId': 'seed_customer',
          'items': [],
          'totalPrice': 2500000.0,
          'status': 'Hoàn thành',
          'shippingAddress': 'HCM',
          'createdAt':
              Timestamp.fromDate(today.subtract(const Duration(days: 1))),
        },
        {
          'id': 'ORD-003',
          'userId': 'seed_customer',
          'items': [],
          'totalPrice': 450000.0,
          'status': 'Hoàn thành',
          'shippingAddress': 'Đà Nẵng',
          'createdAt':
              Timestamp.fromDate(today.subtract(const Duration(days: 2))),
        },
        {
          'id': 'ORD-004',
          'userId': 'seed_customer',
          'items': [],
          'totalPrice': 3200000.0,
          'status': 'Hoàn thành',
          'shippingAddress': 'Hải Phòng',
          'createdAt':
              Timestamp.fromDate(today.subtract(const Duration(days: 5))),
        },
      ];

      for (final o in orders) {
        final String id = o.remove('id') as String;
        await db.collection('orders').doc(id).set(o);
      }

      debugPrint('✅ Orders seeded (Chart data ready)');
      debugPrint('--- 🏁 HOÀN TẤT SEED DỮ LIỆU ---');
    } catch (e) {
      debugPrint('❌ Lỗi khi seed dữ liệu: $e');
    }
  }
}
