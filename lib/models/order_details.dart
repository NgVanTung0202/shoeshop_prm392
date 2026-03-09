class OrderDetailModel {
  String productId;
  String productName;
  String imageUrl;
  String size;
  int quantity;
  double price;

  OrderDetailModel({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.size,
    required this.quantity,
    required this.price,
  });

  factory OrderDetailModel.fromMap(Map<String, dynamic> data) {
    return OrderDetailModel(
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      size: data['size'] ?? '',
      quantity: data['quantity'] ?? 0,
      price: (data['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'productName': productName,
    'imageUrl': imageUrl,
    'size': size,
    'quantity': quantity,
    'price': price,
  };
}