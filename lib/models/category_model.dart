class CategoryModel {
  String id;
  String name;

  /// Đánh dấu xóa mềm — không hiển thị trong app; dữ liệu vẫn trên Firestore.
  bool isDeleted;

  CategoryModel({
    required this.id,
    required this.name,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'isDeleted': isDeleted,
      };

  factory CategoryModel.fromDoc(String id, Map<String, dynamic> data) {
    return CategoryModel(
      id: id,
      name: data['name'] ?? '',
      isDeleted: data['isDeleted'] == true,
    );
  }
}
