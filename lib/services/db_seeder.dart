import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DBSeeder {
  static Future<void> seedAll() async {
    await seedDatabase();
  }

  static Future<void> seedDatabase() async {
    final FirebaseFirestore db = FirebaseFirestore.instance;

    debugPrint('Start seeding database...');

    final DocumentReference<Map<String, dynamic>> catSneakerRef = db
        .collection('categories')
        .doc('seed_sneakers');
    final DocumentReference<Map<String, dynamic>> catRunningRef = db
        .collection('categories')
        .doc('seed_running');
    final DocumentReference<Map<String, dynamic>> catSandalRef = db
        .collection('categories')
        .doc('seed_sandal');

    await catSneakerRef.set({'name': 'Sneakers', 'imageUrl': ''});
    await catRunningRef.set({'name': 'Running', 'imageUrl': ''});
    await catSandalRef.set({'name': 'Sandal', 'imageUrl': ''});

    debugPrint('Categories seeded');

    final List<Map<String, dynamic>> products = <Map<String, dynamic>>[
      {
        'docId': 'seed_nike_air_max_2026',
        'name': 'Nike Air Max 2026',
        'price': 2500000.0,
        'categoryId': catSneakerRef.id,
        'brand': 'Nike',
        'imageUrl':
            'https://static.nike.com/a/images/t_PDP_1280_v1/f_auto,q_auto:eco/99486149-0345-41ef-8b89-4670081d5f2a/air-force-1-07-shoes-Wr0Q1H.png',
        'description': 'Mau giay chay bo cao cap nhat cua Nike nam 2026.',
        'sizes_stock': {'39': 5, '40': 5, '41': 6, '42': 4},
      },
      {
        'docId': 'seed_adidas_ultraboost_v5',
        'name': 'Adidas UltraBoost v5',
        'price': 3200000.0,
        'categoryId': catRunningRef.id,
        'brand': 'Adidas',
        // Note: some brand CDNs may return 404 later; use a stable placeholder endpoint for seeded demo data.
        'imageUrl':
            'https://picsum.photos/seed/shoeshop_adidas_ultraboost/1024/1024',
        'description': 'Su ket hop hoan hao giua thoi trang va hieu nang.',
        'sizes_stock': {'38': 2, '39': 10, '40': 15, '41': 3},
      },
      {
        'docId': 'seed_classic_sandal_xl',
        'name': 'Classic Sandal XL',
        'price': 450000.0,
        'categoryId': catSandalRef.id,
        'brand': 'Bitis',
        'imageUrl':
            'https://picsum.photos/seed/shoeshop_bitis_sandal/1024/1024',
        'description': 'Sandal ben bi cho mua he nang dong.',
        'sizes_stock': {'36': 10, '37': 10, '38': 10, '39': 10},
      },
    ];

    for (final Map<String, dynamic> p in products) {
      final String docId = p.remove('docId') as String;
      await db.collection('products').doc(docId).set(p);
    }

    debugPrint('Products seeded');

    await db.collection('users').doc('seed_admin').set({
      'email': 'admin@shoeshop.local',
      'name': 'Admin',
      'role': 'admin',
      'createdAt': Timestamp.now(),
    });

    debugPrint('Admin user seeded');

    final DateTime today = DateTime.now();
    final List<Map<String, dynamic>> orders = <Map<String, dynamic>>[
      {
        'id': 'ORD-001',
        'userId': 'customer_test_id',
        'items': <Map<String, dynamic>>[],
        'totalPrice': 1200000.0,
        'status': 'completed',
        'address': 'Ha Noi',
        'phone': '0000000000',
        'paymentMethod': 'cod',
        'paymentStatus': 'paid',
        'createdAt': Timestamp.fromDate(today),
      },
      {
        'id': 'ORD-002',
        'userId': 'customer_test_id',
        'items': <Map<String, dynamic>>[],
        'totalPrice': 2500000.0,
        'status': 'completed',
        'address': 'HCM',
        'phone': '0000000000',
        'paymentMethod': 'cod',
        'paymentStatus': 'paid',
        'createdAt': Timestamp.fromDate(
          today.subtract(const Duration(days: 1)),
        ),
      },
      {
        'id': 'ORD-003',
        'userId': 'customer_test_id',
        'items': <Map<String, dynamic>>[],
        'totalPrice': 450000.0,
        'status': 'completed',
        'address': 'Da Nang',
        'phone': '0000000000',
        'paymentMethod': 'cod',
        'paymentStatus': 'paid',
        'createdAt': Timestamp.fromDate(
          today.subtract(const Duration(days: 2)),
        ),
      },
      {
        'id': 'ORD-004',
        'userId': 'customer_test_id',
        'items': <Map<String, dynamic>>[],
        'totalPrice': 3200000.0,
        'status': 'completed',
        'address': 'Hai Phong',
        'phone': '0000000000',
        'paymentMethod': 'cod',
        'paymentStatus': 'paid',
        'createdAt': Timestamp.fromDate(
          today.subtract(const Duration(days: 5)),
        ),
      },
    ];

    for (final Map<String, dynamic> o in orders) {
      final String id = o['id'] as String;
      await db.collection('orders').doc(id).set(o);
    }

    debugPrint('Orders seeded');
    debugPrint('Database seed completed');
  }
}
