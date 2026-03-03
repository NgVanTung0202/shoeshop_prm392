class CategoryModel {
  String id;
  String name;

  CategoryModel({required this.id, required this.name});

  Map<String, dynamic> toMap() => {'name': name};

  factory CategoryModel.fromDoc(String id, Map<String, dynamic> data) {
    return CategoryModel(id: id, name: data['name'] ?? '');
  }
}