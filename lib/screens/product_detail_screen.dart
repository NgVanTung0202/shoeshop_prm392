import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../models/product_model.dart';
import '../models/review_model.dart';
import '../services/firestore_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final FirestoreService _fs = FirestoreService();
  String? _selectedSize;

  void _showAddReviewDialog() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần đăng nhập để đánh giá')),
      );
      return;
    }

    double currentRating = 5.0;
    final TextEditingController commentController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Đánh giá sản phẩm'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingBar.builder(
                initialRating: currentRating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder:
                    (context, _) => const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) {
                  currentRating = rating;
                },
              ),
              const SizedBox(height: 15),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Nhập bình luận của bạn...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final comment = commentController.text.trim();
                if (comment.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập bình luận')),
                  );
                  return;
                }

                final review = ReviewModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  productId: widget.product.id,
                  userId: user.uid,
                  userName: user.email?.split('@')[0] ?? 'Customer',
                  rating: currentRating,
                  comment: comment,
                  createdAt: DateTime.now(),
                );

                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(ctx);

                try {
                  await _fs.addReview(review);
                } catch (_) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Không thể gửi đánh giá')),
                  );
                  return;
                }

                if (!mounted) return;
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Cảm ơn bạn đã đánh giá!')),
                );
              },
              child: const Text('Gửi đánh giá'),
            ),
          ],
        );
      },
    );
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
                child: Image.network(
                  widget.product.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (_, __, ___) => const Icon(Icons.error, size: 50),
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
                        '${widget.product.price.toInt()}đ',
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Đánh giá sản phẩm',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Viết đánh giá'),
                        onPressed: _showAddReviewDialog,
                      ),
                    ],
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

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chức năng giỏ hàng đang bảo trì!'),
                ),
              );
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
