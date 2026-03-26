import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Seeder {
  static Future<void> seedDatabase() async {
    final db = FirebaseFirestore.instance;

    // Kiem tra xem da co du lieu hay chua tranh seed trung lap
    final snap = await db.collection('products').limit(1).get();
    if (snap.docs.isNotEmpty) {
      debugPrint('✅ Database đã có du luu, bo qua buoc seed!');
      return;
    }

    debugPrint('⏳ Dang tien hanh doc Assets va ghi vao Firestore...');

    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      // Lay ra tat ca cac file thuoc thu muc assets (tranh list icon...)
      final assetPaths = manifestMap.keys
          .where((String key) => key.startsWith('assets/'))
          .where((String key) {
            final ext = key.split('.').last.toLowerCase();
            return ['png', 'jpg', 'jpeg', 'webp'].contains(ext);
          })
          .toList();

      final random = Random();
      WriteBatch batch = db.batch();
      
      int count = 0;

      for (var path in assetPaths) {
        // Vd: path = 'assets/nike/jodan.png'
        final segments = path.split('/');
        final parentFolder = segments[segments.length - 2].toLowerCase(); // 'nike', 'adidas', 'puma', 'boots', 'snakers'
        final fileName = segments.last; 
        final ext = fileName.split('.').last.toLowerCase();
        
        // Ten san pham tu file name (bo duoi va format)
        final nameWithoutExt = fileName.replaceFirst('.$ext', '');
        final parts = nameWithoutExt.split('_');
        
        String brand = capitalize(parentFolder);
        // Neu muc la 'boots' or 'snakers' thi co the thu lay hang tu ten file
        if (brand == 'Boots' || brand == 'Snakers') {
           if (parts.isNotEmpty) {
              brand = capitalize(parts.first); 
           } else {
              brand = 'Other';
           }
        }
        
        String name = capitalize(nameWithoutExt.replaceAll('_', ' ')); 

        final price = (random.nextInt(51) * 50000) + 500000;

        final product = {
          "name": name,
          "brand": brand,
          "categoryId": "REPLACE_WITH_VALID_CATEGORY_ID", 
          "description": "Sản phẩm $name chính hãng nguyên bản từ thương hiệu $brand, đem lại trải nghiệm hoàn hảo.",
          "discountPercent": random.nextInt(4) * 5, // 0, 5, 10, 15
          "imageUrl": path, // Link tro truc tiep vao path local
          "price": price,
          "rating": double.parse((4.0 + (random.nextInt(11) / 10)).toStringAsFixed(1)),
          "reviewCount": random.nextInt(100) + 10,
          "sizes_stock": {
            "36": 5, "37": 5, "38": 5, "39": 5, 
            "40": 5, "41": 5, "42": 5, "43": 5, "44": 5
          },
          "soldCount": random.nextInt(500),
          "createdAt": FieldValue.serverTimestamp()
        };

        // Tao tham chieu
        DocumentReference docRef = db.collection('products').doc();
        batch.set(docRef, product);
        count++;
      }

      await batch.commit();
      debugPrint('🚀 DA DAY THANH CONG $count SAN PHAM TU ASSETS VAO FIRESTORE!');

    } catch (e) {
      debugPrint('❌ Loi khi day du lieu vao Firestore: $e');
    }
  }

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
