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
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  "Upload ảnh danh mục chỉ hỗ trợ tốt trên mobile/emulator."),
            ),
          );
        }
        return;
      }
      setDialogState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showCategoryDialog({CategoryModel? category}) {
    final bool isEditing = category != null;
    _nameController.text = isEditing ? category.name : '';
    _selectedImage = null;

    showDialog(
      context: context,
      barrierDismissible: !_isSaving,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEditing ? "Sửa danh mục" : "Thêm danh mục mới"),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _isSaving ? null : () => _pickImage(setDialogState),
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
                                category != null &&
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
                                  color: Colors.grey,
                                  size: 32,
                                ),
                              ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Tên loại giày",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context),
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
                        String finalImageUrl =
                            isEditing ? (category?.imageUrl ?? '') : '';

                        if (_selectedImage != null && !kIsWeb) {
                          finalImageUrl =
                              await _fs.uploadImage(_selectedImage!);
                        }

                        if (isEditing) {
                          await _fs.updateCategory(
                            category!.id,
                            name,
                            imageUrl: finalImageUrl,
                          );
                        } else {
                          await _fs.addCategory(
                            name,
                            imageUrl: finalImageUrl,
                          );
                        }

                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Lỗi: $e")),
                          );
                        }
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Xác nhận xóa"),
        content: Text(
          "Bạn có chắc muốn xóa danh mục \"${category.name}\"?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              await _fs.deleteCategory(category.id);
              if (mounted) Navigator.pop(context);
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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        centerTitle: true,
        title: const Text(
          "Quản lý danh mục",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      drawer: const AdminDrawer(selected: AdminMenuItem.categories),
      body: Container(
        color: const Color(0xFFF5F6FA),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Tìm kiếm danh mục...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
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
                builder: (context, catSnapshot) {
                  if (!catSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  List<CategoryModel> categories = catSnapshot.data!;
                  if (_searchQuery.isNotEmpty) {
                    categories = categories
                        .where(
                            (c) => c.name.toLowerCase().contains(_searchQuery))
                        .toList();
                  }

                  if (categories.isEmpty) {
                    return const Center(
                      child: Text(
                        "Không tìm thấy danh mục nào.",
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }

                  return StreamBuilder(
                    stream: _fs.getProducts(),
                    builder: (context, prodSnapshot) {
                      final Map<String, int> countByCategory = {};

                      if (prodSnapshot.hasData) {
                        for (final p in prodSnapshot.data!) {
                          countByCategory[p.categoryId] =
                              (countByCategory[p.categoryId] ?? 0) + 1;
                        }
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final count = countByCategory[cat.id] ?? 0;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F1F5),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: cat.imageUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          child: Image.network(
                                            cat.imageUrl,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.category_outlined,
                                          color: Colors.grey,
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cat.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "$count sản phẩm",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      _showCategoryDialog(category: cat),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () => _confirmDelete(cat),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}