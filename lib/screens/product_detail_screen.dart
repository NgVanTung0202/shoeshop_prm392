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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _animateHeroImage = true;
      });
    });
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _showTopSuccessDialog(String message) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    bool alreadyClosed = false;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'success',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, __, ___) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.35),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ).then((_) {
      alreadyClosed = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || alreadyClosed) return;
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> _submitInlineReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần đăng nhập để đánh giá')),
      );
      return;
    }

    final comment = _reviewController.text.trim();
    if (comment.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đánh giá')));
      return;
    }

    final review = ReviewModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: widget.product.id,
      userId: user.uid,
      userName: user.email?.split('@')[0] ?? 'Customer',
      rating: 5.0,
      comment: comment,
      createdAt: DateTime.now(),
    );

    try {
      await _fs.addReview(review);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không thể gửi đánh giá')));
      return;
    }

    if (!mounted) return;
    FocusScope.of(context).unfocus();
    _reviewController.clear();
    await _showTopSuccessDialog('Cảm ơn bạn đã đánh giá!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.product.name),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.blue.shade50.withValues(alpha: 0.5),
              child: Hero(
                tag: widget.product.id,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  offset:
                      _animateHeroImage ? Offset.zero : const Offset(0, 0.06),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOut,
                    opacity: _animateHeroImage ? 1 : 0,
                    child: Image.network(
                      widget.product.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (_, __, ___) => const Icon(Icons.error, size: 50),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.product.brand.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatPrice(widget.product.price),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Chọn Size:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children:
                        widget.product.sizesStock.entries.map((entry) {
                          final hasStock = entry.value > 0;
                          final isSelected = _selectedSize == entry.key;
                          return ChoiceChip(
                            label: Text(entry.key),
                            selected: isSelected,
                            onSelected:
                                hasStock
                                    ? (selected) {
                                      setState(() {
                                        _selectedSize =
                                            selected ? entry.key : null;
                                      });
                                    }
                                    : null,
                            selectedColor: Colors.blue,
                            labelStyle: TextStyle(
                              color:
                                  isSelected
                                      ? Colors.white
                                      : (hasStock ? Colors.black : Colors.grey),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Đánh giá sản phẩm',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ghi chú: Vui lòng đăng nhập trước khi gửi đánh giá.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reviewController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'Nhập đánh giá của bạn...'
                          ' (ví dụ: form đẹp, đi êm, đúng size)',
                      filled: true,
                      fillColor: Colors.blue.shade50,
                      prefixIcon: const Icon(Icons.edit_outlined),
                      suffixIcon: IconButton(
                        tooltip: 'Gửi',
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: _submitInlineReview,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitInlineReview(),
                  ),
                  const Divider(),
                  StreamBuilder<List<ReviewModel>>(
                    stream: _fs.getProductReviews(widget.product.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        debugPrint(
                          'Lỗi tải đánh giá: ${snapshot.error.toString()}',
                        );
                        return Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Center(
                            child: Text('Lỗi tải dữ liệu: ${snapshot.error}'),
                          ),
                        );
                      }

                      final reviews = snapshot.data ?? <ReviewModel>[];
                      if (reviews.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(
                            child: Text(
                              'Chưa có đánh giá nào cho sản phẩm này.',
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final rev = reviews[index];
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        rev.userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      RatingBarIndicator(
                                        rating: rev.rating,
                                        itemBuilder:
                                            (context, _) => const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                            ),
                                        itemCount: 5,
                                        itemSize: 16.0,
                                        direction: Axis.horizontal,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(rev.comment),
                                ],
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
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _selectedSize != null ? Colors.blue : Colors.grey,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () {
              if (_selectedSize == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng chọn size')),
                );
                return;
              }

              _cartService.addItem(widget.product, _selectedSize!);
              _showTopSuccessDialog('Đã thêm vào giỏ hàng');
            },
            child: const Text(
              'THÊM VÀO GIỎ HÀNG',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
