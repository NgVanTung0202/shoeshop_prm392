class ProductModel {
  String id;
  String name;
  String brand;
  double price;
  String categoryId;
  String imageUrl;
  String description;
  Map<String, int> sizesStock;
  int discountPercent;
  int soldCount;
  double rating;
  int reviewCount;

  ProductModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.categoryId,
    required this.imageUrl,
    required this.description,
    required this.sizesStock,
    this.discountPercent = 0,
    this.soldCount = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  factory ProductModel.fromFirestore(String id, Map<String, dynamic> data) {
    int sCount = data['soldCount'] ?? 0;
    if (sCount == 0) sCount = (id.hashCode.abs() % 500) + 10;
    
    int rCount = data['reviewCount'] ?? 0;
    if (rCount == 0) rCount = (id.hashCode.abs() % 200) + 5;
    
    double ratingValue = (data['rating'] ?? 0).toDouble();
    if (ratingValue == 0) ratingValue = 4.0 + (id.hashCode.abs() % 10) / 10;
    
    int disc = data['discountPercent'] ?? 0;
    if (disc == 0 && id.hashCode.abs() % 5 == 0) {
      disc = 15 + (id.hashCode.abs() % 5) * 5; 
    }

    final rawImg = data['imageUrl'] ?? data['image_url'];
    String storedUrl = '';
    if (rawImg != null) {
      final s = rawImg.toString().trim();
      if (s.isNotEmpty && s.toLowerCase() != 'null') {
        storedUrl = s;
      }
    }
    // Ưu tiên URL đã lưu (Storage / CDN); không bắt buộc — thiếu thì dùng 1 placeholder cố định
    final String resolvedImageUrl = storedUrl.isNotEmpty
        ? storedUrl
        : placeholderImageAsset;

    return ProductModel(
      id: id,
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      categoryId: data['categoryId'] ?? '',
      imageUrl: resolvedImageUrl,
      description: data['description'] ?? '',
      sizesStock: Map<String, int>.from(data['sizes_stock'] ?? {}),
      discountPercent: disc,
      soldCount: sCount,
      rating: ratingValue,
      reviewCount: rCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'brand': brand,
      'price': price,
      'categoryId': categoryId,
      'imageUrl': imageUrl,
      'description': description,
      'sizes_stock': sizesStock,
      'discountPercent': discountPercent,
      'soldCount': soldCount,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  int getTotalStock() {
    return sizesStock.values.fold(0, (sum, quantity) => sum + quantity);
  }

  /// Ảnh mặc định khi sản phẩm không có `imageUrl` (không bắt buộc upload).
  static const String placeholderImageAsset = 'app_images/snakers/convert.png';

  static bool isNetworkImageUrl(String url) {
    final u = url.trim();
    return u.startsWith('http://') || u.startsWith('https://');
  }

  /// Flutter Web ghép URL `assets/` + key; nếu key bắt đầu bằng `assets/` sẽ thành `assets/assets/...` (404).
  /// Ảnh nằm trong thư mục [app_images/], không dùng tên thư mục `assets` ở root.
  static String normalizeLocalAssetPath(String path) {
    if (path.startsWith('assets/')) {
      return path.replaceFirst('assets/', 'app_images/');
    }
    return path;
  }
}
