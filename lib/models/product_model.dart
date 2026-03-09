
class ProductModel {
  String id;
  String name;
  double price;
  String categoryId;
  String imageUrl;
  String description;
  Map<String, int> sizesStock;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    required this.imageUrl,
    required this.description,
    required this.sizesStock,
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
      sizesStock: Map<String, int>.from(data['sizes_stock'] ?? {}),
    );
  }

  // Chuyển từ Object Flutter sang Map để đẩy lên Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'categoryId': categoryId,
      'imageUrl': imageUrl,
      'description': description,
      'sizes_stock': sizesStock, // Đẩy cả Map lên thay vì một con số duy nhất
    };
  }

  // Hàm tiện ích để tính tổng số lượng tồn kho nếu cần hiển thị con số tổng quát
  int getTotalStock() {
    return sizesStock.values.fold(0, (sum, quantity) => sum + quantity);
  }
}