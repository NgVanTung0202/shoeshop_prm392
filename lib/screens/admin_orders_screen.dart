import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../utils/format_utils.dart';
import '../widgets/admin_drawer.dart';
import 'order_detail_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final FirestoreService _fs = FirestoreService();
  String _filterStatus = 'Tất cả';

  final List<String> _statusOptions = [
    'Tất cả',
    'Chờ xác nhận',
    'Đã xác nhận đơn hàng',
    'Đang chuẩn bị hàng',
    'Đã giao cho đơn vị vận chuyển',
    'Đang giao hàng',
    'Giao hàng thành công',
    'Đã hủy',
  ];

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

  bool _isValidStatusTransition(String currentStatus, String nextStatus) {
    final current = _normalizeStatus(currentStatus);
    final next = _normalizeStatus(nextStatus);

    if (current == next) return false;

    switch (current) {
      case 'Chờ xác nhận':
        return next == 'Đã xác nhận đơn hàng' || next == 'Đã hủy';
      case 'Đã xác nhận đơn hàng':
        return next == 'Đang chuẩn bị hàng' || next == 'Đã hủy';
      case 'Đang chuẩn bị hàng':
        return next == 'Đã giao cho đơn vị vận chuyển' || next == 'Đã hủy';
      case 'Đã giao cho đơn vị vận chuyển':
        return next == 'Đang giao hàng';
      case 'Đang giao hàng':
        return next == 'Giao hàng thành công';
      default:
        return false;
    }
  }

  List<String> _nextStatusOptions(String currentStatus) {
    switch (_normalizeStatus(currentStatus)) {
      case 'Chờ xác nhận':
        return ['Đã xác nhận đơn hàng', 'Đã hủy'];
      case 'Đã xác nhận đơn hàng':
        return ['Đang chuẩn bị hàng', 'Đã hủy'];
      case 'Đang chuẩn bị hàng':
        return ['Đã giao cho đơn vị vận chuyển', 'Đã hủy'];
      case 'Đã giao cho đơn vị vận chuyển':
        return ['Đang giao hàng'];
      case 'Đang giao hàng':
        return ['Giao hàng thành công'];
      default:
        return [];
    }
  }

  Future<void> _updateStatus(
      String orderId, String currentStatus, String newStatus) async {
    // Validate strict state transitions
    if (_normalizeStatus(newStatus) == _normalizeStatus(currentStatus)) return;

    currentStatus = _normalizeStatus(currentStatus);
    final nextStatus = _normalizeStatus(newStatus);

    if (!_isValidStatusTransition(currentStatus, nextStatus)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid status transition.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Status'),
        content: Text('Mark this order as $newStatus?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _fs.updateOrderStatus(orderId, nextStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
      ),
      drawer: const AdminDrawer(selected: AdminMenuItem.orders),
      body: user == null
          ? const Center(child: Text('Vui lòng đăng nhập tài khoản admin'))
          : FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userData = userSnapshot.data?.data() ?? {};
                final role = (userData['role'] ?? '').toString().toLowerCase();
                const allowedRoles = {'admin', 'staff'};
                if (!allowedRoles.contains(role)) {
                  return const Center(
                    child: Text('Bạn không có quyền truy cập màn hình này'),
                  );
                }

                return _buildOrdersStream();
              },
            ),
    );
  }

  Widget _buildOrdersStream() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusOptions.map((status) {
                final isSelected = _filterStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _filterStatus = status),
                    selectedColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var docs = snapshot.data!.docs;
              if (_filterStatus != 'Tất cả') {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _normalizeStatus((data['status'] ?? '').toString()) ==
                      _filterStatus;
                }).toList();
              }

              if (docs.isEmpty) {
                return const Center(child: Text('No orders found'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8),
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

                  return Card(
                    elevation: 2,
                    margin:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailScreen(
                                orderId: orderId, isAdmin: true),
                          ),
                        );
                      },
                      title: Text('Order: #$shortId',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(date != null
                              ? '${date.day}/${date.month}/${date.year} - ${formatPrice(totalPrice)}'
                              : formatPrice(totalPrice)),
                          Text('User: ${data['userId']}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (val) =>
                            _updateStatus(orderId, status, val),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _getStatusColor(status)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                status,
                                style: TextStyle(
                                    color: _getStatusColor(status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_drop_down,
                                  size: 16, color: _getStatusColor(status)),
                            ],
                          ),
                        ),
                        itemBuilder: (ctx) {
                          final options = _nextStatusOptions(status);
                          return options
                              .map((s) =>
                                  PopupMenuItem(value: s, child: Text(s)))
                              .toList();
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
