import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  String id;
  String userId;
  double totalPrice;
  String status; // pending, shipping, delivered
  String address;
  String phone;
  String paymentMethod; // COD, Online
  String paymentStatus; // paid, unpaid
  DateTime createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.totalPrice,
    required this.status,
    required this.address,
    required this.phone,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
  });

  factory OrderModel.fromFirestore(String id, Map<String, dynamic> data) {
    return OrderModel(
      id: id,
      userId: data['userId'] ?? '',
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      paymentMethod: data['paymentMethod'] ?? 'COD',
      paymentStatus: data['paymentStatus'] ?? 'unpaid',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'totalPrice': totalPrice,
    'status': status,
    'address': address,
    'phone': phone,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'createdAt': FieldValue.serverTimestamp(),
  };
}