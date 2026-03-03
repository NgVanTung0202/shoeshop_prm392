import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/firestore_service.dart';

class AdminCategoryScreen extends StatelessWidget {
  const AdminCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService fs = FirestoreService();
    final TextEditingController catController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Quản lý Danh mục (UC17)")),
      body: StreamBuilder<List<CategoryModel>>(
        stream: fs.getCategories(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final categories = snapshot.data!;
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return ListTile(
                title: Text(cat.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => fs.deleteCategory(cat.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Thêm danh mục mới"),
              content: TextField(controller: catController, decoration: const InputDecoration(hintText: "Tên loại giày")),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    if (catController.text.isNotEmpty) {
                      fs.addCategory(catController.text.trim());
                      catController.clear();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Lưu"),
                )
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}