class ProductModel {
  String id;
  String name;
  String brand;
  double price;
  String categoryId;
  String imageUrl;
  String description;
  Map<String, int> sizesStock;

  ProductModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.categoryId,
    required this.imageUrl,
    required this.description,
    required this.sizesStock,
  });


  factory ProductModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ProductModel(
      id: id,
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      categoryId: data['categoryId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',

      sizesStock: Map<String, int>.from(data['sizes_stock'] ?? {}),
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
    };
  }


  int getTotalStock() {
    return sizesStock.values.fold(0, (sum, quantity) => sum + quantity);
  }
}