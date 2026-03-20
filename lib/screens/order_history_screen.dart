import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/format_utils.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  String _normalizeStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'chờ xác nhận':
        return 'Chờ xác nhận';
      case 'đã xác nhận đơn hàng':
        return 'Đã xác nhận đơn hàng';
      case 'đang chuẩn bị hàng':
        return 'Đang chuẩn bị hàng';
      case 'đã giao cho đơn vị vận chuyển':
        return 'Đã giao cho đơn vị vận chuyển';
      case 'shipping':
      case 'đang giao':
      case 'đang giao hàng':
        return 'Đang giao hàng';
      case 'completed':
      case 'hoàn thành':
      case 'giao hàng thành công':
        return 'Giao hàng thành công';
      case 'cancelled':
      case 'đã hủy':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (_normalizeStatus(status)) {
      case 'Chờ xác nhận':
        return Colors.orange;
      case 'Đã xác nhận đơn hàng':
        return Colors.cyan;
      case 'Đang chuẩn bị hàng':
        return Colors.indigo;
      case 'Đã giao cho đơn vị vận chuyển':
        return Colors.deepPurple;
      case 'Đang giao hàng':
        return Colors.blue;
      case 'Giao hàng thành công':
        return Colors.green;
      case 'Đã hủy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lịch sử đơn hàng', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: Colors.blue),
        ),
        body: const Center(child: Text('Vui lòng đăng nhập')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Lịch sử đơn hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = [...snapshot.data!.docs]..sort((a, b) {
              final aCreatedAt =
                  (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              final bCreatedAt =
                  (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;

              final createdAtCompare = (bCreatedAt?.millisecondsSinceEpoch ?? 0)
                  .compareTo(aCreatedAt?.millisecondsSinceEpoch ?? 0);

              if (createdAtCompare != 0) return createdAtCompare;
              return b.id.compareTo(a.id);
            });
          if (docs.isEmpty) {
            return const Center(child: Text('Bạn chưa có đơn hàng nào', style: TextStyle(fontSize: 16, color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final orderId = docs[index].id;
              final shortId =
                  orderId.length > 8 ? orderId.substring(0, 8) : orderId;
              final status = _normalizeStatus(
                  (data['status'] ?? 'Chờ xác nhận').toString());
              final totalPrice = (data['totalPrice'] ?? 0).toDouble();
              final date = (data['createdAt'] as Timestamp?)?.toDate();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            OrderDetailScreen(orderId: orderId, isAdmin: false),
                      ),
                    );
                  },
                  title: Text('Đơn hàng: #$shortId',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      date != null
                          ? '${date.day}/${date.month}/${date.year} - ${formatPrice(totalPrice)}'
                          : formatPrice(totalPrice),
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getStatusColor(status)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
