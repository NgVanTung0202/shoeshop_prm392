import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../models/category_model.dart';
import '../services/firestore_service.dart';
import '../widgets/admin_drawer.dart';

class AdminCategoryScreen extends StatefulWidget {
  const AdminCategoryScreen({super.key});

  @override
  State<AdminCategoryScreen> createState() => _AdminCategoryScreenState();
}

class _AdminCategoryScreenState extends State<AdminCategoryScreen> {
  final FirestoreService _fs = FirestoreService();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  String _searchQuery = '';

  File? _selectedImage;
  bool _isSaving = false;

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(StateSetter setDialogState) async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    if (kIsWeb) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Upload ảnh danh mục tốt nhất trên mobile."),
        ),
      );
      return;
    }

    setDialogState(() {
      _selectedImage = File(pickedFile.path);
    });
  }

  void _showCategoryDialog({CategoryModel? category}) {
    final bool isEditing = category != null;

    _nameController.text = category?.name ?? "";
    _selectedImage = null;
    _isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(isEditing ? "Sửa danh mục" : "Thêm danh mục"),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _pickImage(setDialogState),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F1F5),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: _selectedImage != null && !kIsWeb
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : (isEditing &&
                                category.imageUrl.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.network(
                                  category.imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                              ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Tên danh mục",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  _isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      final name = _nameController.text.trim();

                      if (name.isEmpty) return;

                      setDialogState(() => _isSaving = true);

                      try {
                        String finalImageUrl = category?.imageUrl ?? "";

                        if (_selectedImage != null && !kIsWeb) {
                          finalImageUrl =
                              await _fs.uploadImage(_selectedImage!);
                        }

                        if (isEditing) {
                          await _fs.updateCategory(
                            category.id,
                            name,
                            imageUrl: finalImageUrl,
                          );
                        } else {
                          await _fs.addCategory(
                            name,
                            imageUrl: finalImageUrl,
                          );
                        }

                        if (!mounted) return;

                        Navigator.pop(context);
                      } catch (e) {
                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Lỗi: $e")),
                        );
                      } finally {
                        setDialogState(() => _isSaving = false);
                      }
                    },
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Lưu"),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(CategoryModel category) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text('Bạn có chắc muốn xóa "${category.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _fs.deleteCategory(category.id);

              if (!mounted) return;

              Navigator.pop(context);
            },
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(selected: AdminMenuItem.categories),
      appBar: AppBar(
        title: const Text("Quản lý danh mục"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Tìm danh mục...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<CategoryModel>>(
              stream: _fs.getCategories(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                      child: Text("Lỗi tải danh mục"));
                }

                List<CategoryModel> categories =
                    snapshot.data ?? [];

                if (_searchQuery.isNotEmpty) {
                  categories = categories
                      .where((c) => c.name
                          .toLowerCase()
                          .contains(_searchQuery))
                      .toList();
                }

                if (categories.isEmpty) {
                  return const Center(
                      child: Text("Không có danh mục"));
                }

                return ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];

                    return ListTile(
                      leading: cat.imageUrl.isNotEmpty
                          ? Image.network(
                              cat.imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.category),
                      title: Text(cat.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                _showCategoryDialog(category: cat),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () =>
                                _confirmDelete(cat),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}