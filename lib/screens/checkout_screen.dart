import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/cart_service.dart';
import '../services/firestore_service.dart';
import '../utils/format_utils.dart';
import 'order_history_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> selectedItems;

  const CheckoutScreen({super.key, required this.selectedItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _receiverNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  String _paymentMethod = 'COD';
  bool _isLoading = false;
  

  final FirestoreService _firestoreService = FirestoreService();

  List<CartItem> get _checkoutItems => widget.selectedItems;

  double _selectedTotalPrice() {
    return _checkoutItems.fold<double>(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_checkoutItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giỏ hàng của bạn đang trống.')),
        );
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _receiverNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập trước khi đặt hàng.')),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firestoreService.createOrder(
        userId: user.uid,
        receiverName: _receiverNameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        paymentMethod: _paymentMethod,
        orderItems: _checkoutItems,
      );

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đặt hàng thành công!')),
      );
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đặt hàng thất bại: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Tiện ích tạo viền cong đẹp đồng bộ
  OutlineInputBorder _buildInputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.blue.shade100, width: 1.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkoutItems.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Thanh toán', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))
                        ]
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Đơn hàng của bạn',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 12),
                          ..._checkoutItems.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Text('Size: ${item.size}  x  ${item.quantity}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    formatPrice(item.product.price * item.quantity),
                                     style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const Divider(height: 24, thickness: 1.5, color: Color(0xFFEEEEEE)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Tổng cộng:',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                formatPrice(_selectedTotalPrice()),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                            ],
                          ),
                        ]
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Thông tin giao hàng',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _receiverNameController,
                      decoration: InputDecoration(
                        labelText: 'Tên người nhận',
                        prefixIcon: const Icon(Icons.person_outline, color: Colors.blue),
                        border: _buildInputBorder(),
                        enabledBorder: _buildInputBorder(),
                        focusedBorder: _buildInputBorder().copyWith(borderSide: const BorderSide(color: Colors.blue, width: 2)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Vui lòng nhập tên người nhận' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Số điện thoại',
                        prefixIcon: const Icon(Icons.phone_outlined, color: Colors.blue),
                        border: _buildInputBorder(),
                        enabledBorder: _buildInputBorder(),
                        focusedBorder: _buildInputBorder().copyWith(borderSide: const BorderSide(color: Colors.blue, width: 2)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
                        if (value.length < 8) return 'Số điện thoại không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Địa chỉ giao hàng',
                        prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.blue),
                        border: _buildInputBorder(),
                        enabledBorder: _buildInputBorder(),
                        focusedBorder: _buildInputBorder().copyWith(borderSide: const BorderSide(color: Colors.blue, width: 2)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Phương thức thanh toán',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _paymentMethod,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.payment_outlined, color: Colors.blue),
                        border: _buildInputBorder(),
                        enabledBorder: _buildInputBorder(),
                        focusedBorder: _buildInputBorder().copyWith(borderSide: const BorderSide(color: Colors.blue, width: 2)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'COD', child: Text('Thanh toán khi nhận hàng (COD)')),
                        DropdownMenuItem(value: 'Online', child: Text('Thanh toán trực tuyến')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _paymentMethod = value);
                        }
                      },
                    ),
                    const SizedBox(height: 36),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _placeOrder,
                      child: const Text('XÁC NHẬN ĐẶT HÀNG', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
