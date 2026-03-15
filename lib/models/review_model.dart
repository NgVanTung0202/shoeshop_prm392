update-code
class ReviewModel {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String comment;
  final double rating;
  final DateTime createdAt;

import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  String id;
  String productId;
  String userId;
  String userName;
  double rating;
  String comment;
  DateTime createdAt;
main

  ReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
update-code
    required this.comment,
    required this.rating,

    required this.rating,
    required this.comment,
main
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'userId': userId,
      'userName': userName,
update-code
      'comment': comment,
      'rating': rating,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReviewModel.fromMap(String id, Map<String, dynamic> data) {
    
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ReviewModel.fromFirestore(String id, Map<String, dynamic> data) {
main
    return ReviewModel(
      id: id,
      productId: data['productId'] ?? '',
      userId: data['userId'] ?? '',
update-code
      userName: data['userName'] ?? '',
      comment: data['comment'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      createdAt: DateTime.parse(data['createdAt']),
    );
  }
}

      userName: data['userName'] ?? 'Customer',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
 main
