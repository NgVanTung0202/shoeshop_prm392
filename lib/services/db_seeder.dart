import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DBSeeder {

  static Future<void> seedDatabase() async {

    final db = FirebaseFirestore.instance;

    debugPrint("Start seeding database...");

    await db.collection("categories").add({
      "name": "Sneakers",
      "imageUrl": ""
    });

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

    debugPrint("Products seeded");

    debugPrint("Database seed completed");
  }
}
