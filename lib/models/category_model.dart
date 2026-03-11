class CategoryModel {
  String id;
  String name;
  String imageUrl;

  CategoryModel({
    required this.id,
    required this.name,
    this.imageUrl = '',
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'imageUrl': imageUrl,
      };

  factory CategoryModel.fromDoc(String id, Map<String, dynamic> data) {
    return CategoryModel(
      id: id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}