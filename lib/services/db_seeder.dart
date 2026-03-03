import 'package:cloud_firestore/cloud_firestore.dart';

class DbSeeder {
  static Future<void> seedAll() async {
    final db = FirebaseFirestore.instance;

    print("--- BẮT ĐẦU BƠM DỮ LIỆU MẪU ---");

    // 1. Tạo Categories (UC17, 18)
    // Lưu lại ID để gán cho Product sau này
    final catSneaker = await db.collection('categories').add({'name': 'Sneaker'});
    final catSandal = await db.collection('categories').add({'name': 'Sandal'});
    final catBoots = await db.collection('categories').add({'name': 'Boots'});

    print("✔ Đã tạo 3 Danh mục");

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
        'stock': 15,
      },
      {
        'name': 'Adidas UltraBoost v5',
        'price': 3200000.0,
        'categoryId': catSneaker.id,
        'brand': 'Adidas',
        'imageUrl': 'https://assets.adidas.com/images/h_840,f_auto,q_auto,fl_lossy,c_fill,g_auto/0f4327463f6449179017af3200057f97_9366/Giay_UltraBoost_Light_trang_HQ6351_01_standard.jpg',
        'description': 'Sự kết hợp hoàn hảo giữa thời trang và hiệu năng.',
        'stock': 10,
      },
      {
        'name': 'Classic Sandal XL',
        'price': 450000.0,
        'categoryId': catSandal.id,
        'brand': 'Bitis',
        'imageUrl': 'https://bitis.com.vn/cdn/shop/products/3_84967394-3758-4503-912b-7b089c25f190_1024x1024.jpg',
        'description': 'Sandal bền bỉ cho mùa hè năng động.',
        'stock': 50,
      }
    ];

    for (var p in products) {
      await db.collection('products').add(p);
    }
    print("✔ Đã tạo 3 Sản phẩm mẫu");

    // 3. Tạo User mẫu (Nếu bạn muốn test login/role ngay) - UC06
    // Lưu ý: User này chỉ có trên Firestore, muốn login được vẫn phải tạo bên Auth
    await db.collection('users').doc('admin_test_id').set({
      'uid': 'admin_test_id',
      'email': 'admin@shoeshop.com',
      'fullName': 'Quản Trị Viên',
      'role': 'admin',
      'phoneNumber': '0901234567',
      'address': 'Hà Nội, Việt Nam',
      'createdAt': FieldValue.serverTimestamp(),
    });

    print("✔ Đã tạo User Admin mẫu");
    print("--- HOÀN TẤT SEED DỮ LIỆU ---");
  }
}