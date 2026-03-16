import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../models/product_model.dart';
import '../models/review_model.dart';
import '../services/cart_service.dart';
import '../services/firestore_service.dart';
import '../utils/format_utils.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final CartService _cartService = CartService();
  final FirestoreService _fs = FirestoreService();
  final TextEditingController _reviewController = TextEditingController();

  String? _selectedSize;
  bool _animateHeroImage = false;
  double _currentRating = 5.0; // Thêm biến để lưu rating từ main

  @override
  void initState() {
    super.initState();
    // Hiệu ứng Hero khi vào màn hình (từ HEAD)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _animateHeroImage = true);
    });
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  // --- Thông báo thành công kiểu Toast phía trên (Xịn hơn SnackBar) ---
  Future<void> _showTopSuccessDialog(String message) async {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'success',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, __, ___) => SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 10),
                  Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  // --- Logic gửi đánh giá ---
  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập để đánh giá')));
      return;
    }

    final comment = _reviewController.text.trim();
    if (comment.isEmpty) return;

    final review = ReviewModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: widget.product.id,
      userId: user.uid,
      userName: user.email?.split('@')[0] ?? 'Khách hàng',
      rating: _currentRating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    try {
      await _fs.addReview(review);
      _reviewController.clear();
      setState(() => _currentRating = 5.0);
      FocusScope.of(context).unfocus();
      _showTopSuccessDialog('Cảm ơn bạn đã đánh giá!');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi gửi đánh giá')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.product.name, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Image Area
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.blue.shade50.withOpacity(0.5),
              child: Hero(
                tag: widget.product.id,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: _animateHeroImage ? 1 : 0,
                  child: Image.network(widget.product.imageUrl, fit: BoxFit.contain),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Giá và Thương hiệu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.product.brand.toUpperCase(), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text(formatPrice(widget.product.price), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Chọn Size
                  const Text('Chọn Size:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: widget.product.sizesStock.entries.map((e) {
                      bool hasStock = e.value > 0;
                      bool isSelected = _selectedSize == e.key;
                      return ChoiceChip(
                        label: Text(e.key),
                        selected: isSelected,
                        onSelected: hasStock ? (val) => setState(() => _selectedSize = val ? e.key : null) : null,
                        selectedColor: Colors.blue,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : (hasStock ? Colors.black : Colors.grey)),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 30),
                  const Divider(),
                  const Text('Đánh giá sản phẩm', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  // Ô nhập đánh giá Inline (Gộp HEAD & main)
                  RatingBar.builder(
                    initialRating: 5,
                    minRating: 1,
                    itemSize: 25,
                    itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) => _currentRating = rating,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _reviewController,
                    decoration: InputDecoration(
                      hintText: 'Nhập bình luận...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      suffixIcon: IconButton(icon: const Icon(Icons.send, color: Colors.blue), onPressed: _submitReview),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Danh sách review từ Firestore
                  StreamBuilder<List<ReviewModel>>(
                    stream: _fs.getProductReviews(widget.product.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final reviews = snapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final rev = reviews[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(rev.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(rev.comment),
                              trailing: RatingBarIndicator(
                                rating: rev.rating,
                                itemSize: 12,
                                itemBuilder: (ctx, _) => const Icon(Icons.star, color: Colors.amber),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedSize != null ? Colors.blue : Colors.grey,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (_selectedSize == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn size')));
                return;
              }
              _cartService.addItem(widget.product, _selectedSize!);
              _showTopSuccessDialog('Đã thêm vào giỏ hàng');
            },
            child: const Text('THÊM VÀO GIỎ HÀNG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}