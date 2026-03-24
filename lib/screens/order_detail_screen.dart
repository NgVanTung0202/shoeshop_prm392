import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../utils/format_utils.dart';
import '../models/product_model.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  final bool isAdmin;

  const OrderDetailScreen(
      {super.key, required this.orderId, this.isAdmin = false});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final FirestoreService _fs = FirestoreService();
  late Future<DocumentSnapshot> _orderFuture;

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

  bool _canCustomerCancel(String status) {
    final normalized = _normalizeStatus(status);
    return normalized == 'Chờ xác nhận' ||
        normalized == 'Đã xác nhận đơn hàng' ||
        normalized == 'Đang chuẩn bị hàng';
  }

  @override
  void initState() {
    super.initState();
    _orderFuture = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .get();
  }

  Future<void> _cancelOrder(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đơn hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn hủy đơn hàng này không?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Không')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Có, Hủy', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (widget.isAdmin) {
        await _fs.updateOrderStatus(widget.orderId, 'Đã hủy');
      } else {
        await _fs.cancelOrder(widget.orderId, userId);
      }
      if (!mounted) return;
      setState(() {
        _orderFuture = FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .get();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy đơn hàng thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi hủy đơn hàng: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Không tìm thấy đơn hàng'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status =
              _normalizeStatus((data['status'] ?? 'Chờ xác nhận').toString());
          final userId = data['userId'] ?? '';
          final currentUser = FirebaseAuth.instance.currentUser;

          if (!widget.isAdmin && currentUser?.uid != userId) {
            return const Center(child: Text('Không có quyền truy cập'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildInfoSection('Thông tin đơn hàng', [
                'Trạng thái: $status',
                'Phương thức thanh toán: ${data['paymentMethod'] ?? '-'}',
                'Tổng tiền: ${formatPrice((data['totalPrice'] ?? 0).toDouble())}',
              ]),
              const SizedBox(height: 16),
              _buildInfoSection('Thông tin giao hàng', [
                'Người nhận: ${data['receiverName'] ?? (data['name'] ?? '-')}',
                'Số điện thoại: ${data['phone'] ?? '-'}',
                'Địa chỉ: ${data['address'] ?? '-'}',
              ]),
              const SizedBox(height: 24),
              const Text('Sản phẩm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('orders')
                    .doc(widget.orderId)
                    .collection('items')
                    .get(),
                builder: (context, itemsSnap) {
                  if (itemsSnap.hasError) {
                    return Text('Lỗi: ${itemsSnap.error}');
                  }
                  if (itemsSnap.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  final items = itemsSnap.data!.docs;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      children: items.map((doc) {
                        final itemData = doc.data() as Map<String, dynamic>;
                        String imageUrl = itemData['imageUrl']?.toString() ?? '';

                        if (imageUrl.isEmpty) {
                          imageUrl = ProductModel.placeholderImageAsset;
                        } else if (!imageUrl.startsWith('http')) {
                          imageUrl =
                              ProductModel.normalizeLocalAssetPath(imageUrl);
                        }

                        return ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: imageUrl.startsWith('http')
                                      ? Image.network(imageUrl,
                                          width: 60, height: 60, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey))
                                      : Image.asset(imageUrl,
                                          width: 60, height: 60, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey)),
                                )
                              : const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                          title: Text(itemData['productName'] ?? 'Không rõ tên', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                                'Size: ${itemData['size'] ?? '-'}  x  ${itemData['quantity'] ?? 0}'),
                          ),
                          trailing: Text(formatPrice(
                              (itemData['price'] ?? 0).toDouble() *
                                  (itemData['quantity'] ?? 1)), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              if (_canCustomerCancel(status))
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 1,
                  ),
                  onPressed: () => _cancelOrder(userId),
                  child: const Text('Hủy đơn hàng',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> details) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue)),
          const Divider(height: 24, thickness: 1.5, color: Color(0xFFEEEEEE)),
          ...details
              .map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(d, style: const TextStyle(fontSize: 14)),
                  )),
        ],
      ),
    );
  }
}
