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

    String brandStr = (data['brand'] ?? '').toString().toLowerCase();
    String nameStr = (data['name'] ?? '').toString().toLowerCase();
    String localImg = ProductModel.getLocalImage(nameStr, brandStr, id);

    return ProductModel(
      id: id,
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      categoryId: data['categoryId'] ?? '',
      imageUrl: localImg,
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

  /// Flutter Web ghép URL `assets/` + key; nếu key bắt đầu bằng `assets/` sẽ thành `assets/assets/...` (404).
  /// Ảnh nằm trong thư mục [app_images/], không dùng tên thư mục `assets` ở root.
  static String normalizeLocalAssetPath(String path) {
    if (path.startsWith('assets/')) {
      return path.replaceFirst('assets/', 'app_images/');
    }
    return path;
  }

  static String getLocalImage(String name, String brand, String id) {
    String brandStr = brand.toLowerCase();
    String nameStr = name.toLowerCase();
    
    if (brandStr.contains('nike') || nameStr.contains('nike')) {
      final arr = ['app_images/nike/jodan.png', 'app_images/nike/jodanvang.png', 'app_images/nike/nike2.png', 'app_images/nike/niketrang.png', 'app_images/nike/resize.jpg', 'app_images/nike/unnamed.png'];
      return arr[id.hashCode.abs() % arr.length];
    } else if (brandStr.contains('adidas') || nameStr.contains('adidas')) {
      final arr = ['app_images/adidas/adidas.png', 'app_images/adidas/adidas2.png', 'app_images/adidas/adidasboot.png', 'app_images/adidas/images.jpg'];
      return arr[id.hashCode.abs() % arr.length];
    } else if (brandStr.contains('puma') || nameStr.contains('puma')) {
      final arr = ['app_images/puma/puma.png', 'app_images/puma/puma2.jpg', 'app_images/puma/pumado.png', 'app_images/puma/pumado2.png'];
      return arr[id.hashCode.abs() % arr.length];
    } else if (brandStr.contains('boot') || nameStr.contains('boot')) {
      final arr = ['app_images/boots/boot.png', 'app_images/boots/boot2.png'];
      return arr[id.hashCode.abs() % arr.length];
    } else {
      final arr = [
        'app_images/snakers/convert.png', 
        'app_images/snakers/convert2.png',
        'app_images/nike/jodan.png', 
        'app_images/nike/jodanvang.png', 
        'app_images/nike/nike2.png', 
        'app_images/nike/niketrang.png', 
        'app_images/nike/unnamed.png',
        'app_images/adidas/adidas.png', 
        'app_images/adidas/adidas2.png', 
        'app_images/adidas/adidasboot.png',
        'app_images/puma/puma.png', 
        'app_images/puma/pumado.png', 
        'app_images/puma/pumado2.png',
        'app_images/boots/boot.png', 
        'app_images/boots/boot2.png'
      ];
      return arr[id.hashCode.abs() % arr.length];
    }
  }
}
