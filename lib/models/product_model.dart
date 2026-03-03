class ProductModel {
  String id;
  String name;
  double price;
  String categoryId;
  String imageUrl;
  String description;
  int stock;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    required this.imageUrl,
    required this.description,
    required this.stock,
  });

  // Chuyển dữ liệu từ Firestore Document sang Object trong Flutter
  factory ProductModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ProductModel(
      id: id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      categoryId: data['categoryId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      stock: data['stock'] ?? 0,
    );
  }

  // Chuyển từ Object Flutter sang Map để đẩy lên Firestore (Dùng cho UC16 - Add/Update)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'categoryId': categoryId,
      'imageUrl': imageUrl,
      'description': description,
      'stock': stock,
    };
  }
}