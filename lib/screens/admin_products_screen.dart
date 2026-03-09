import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../services/firestore_service.dart';
import 'admin_category_screen.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final FirestoreService _fs = FirestoreService();
  String? selectedCategoryId;
  File? _selectedImage;
  bool _isSaving = false; // Trạng thái chờ khi upload ảnh và lưu

  // Danh sách size từ 36 đến 44
  final List<String> shoeSizes = ['36', '37', '38', '39', '40', '41', '42', '43', '44'];

  Future<void> _pickImage(StateSetter setDialogState) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setDialogState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showProductForm({ProductModel? product}) {
    final isEditing = product != null;
    final nameController = TextEditingController(text: isEditing ? product.name : '');
    final priceController = TextEditingController(text: isEditing ? product.price.toString() : '');
    final descController = TextEditingController(text: isEditing ? product.description : '');

    // Khởi tạo controller cho từng size
    final Map<String, TextEditingController> sizeControllers = {
      for (var size in shoeSizes)
        size: TextEditingController(
            text: isEditing ? (product.sizesStock[size] ?? 0).toString() : '0'
        )
    };

    selectedCategoryId = isEditing ? product.categoryId : null;
    _selectedImage = null;

    showDialog(
      context: context,
      barrierDismissible: !_isSaving,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(isEditing ? "Cập nhật sản phẩm" : "Thêm giày mới",
              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- KHU VỰC CHỌN ẢNH ---
                  GestureDetector(
                    onTap: _isSaving ? null : () => _pickImage(setDialogState),
                    child: Container(
                      height: 140, width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: _selectedImage != null
                          ? Image.file(_selectedImage!, fit: BoxFit.cover)
                          : (isEditing
                          ? Image.network(product.imageUrl, fit: BoxFit.cover)
                          : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Icon(Icons.add_a_photo, color: Colors.blue, size: 40), Text("Thêm ảnh giày")],
                      )),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // --- THÔNG TIN CHUNG ---
                  StreamBuilder<List<CategoryModel>>(
                    stream: _fs.getCategories(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const LinearProgressIndicator();
                      return DropdownButtonFormField<String>(
                        value: selectedCategoryId,
                        hint: const Text("Chọn danh mục"),
                        items: snapshot.data!.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name))).toList(),
                        onChanged: (val) => setDialogState(() => selectedCategoryId = val),
                      );
                    },
                  ),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: "Tên giày")),
                  TextField(controller: priceController, decoration: const InputDecoration(labelText: "Giá (VNĐ)"), keyboardType: TextInputType.number),
                  TextField(controller: descController, decoration: const InputDecoration(labelText: "Mô tả ngắn")),

                  const SizedBox(height: 20),
                  const Align(alignment: Alignment.centerLeft, child: Text("Kho hàng theo Size:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: shoeSizes.map((size) => SizedBox(
                      width: 70,
                      child: TextField(
                        controller: sizeControllers[size],
                        decoration: InputDecoration(labelText: "S-$size", border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 8)),
                        keyboardType: TextInputType.number,
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: _isSaving ? null : () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: _isSaving ? null : () async {
                if (selectedCategoryId == null || nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng điền đủ thông tin!")));
                  return;
                }

                setDialogState(() => _isSaving = true);

                try {
                  String finalImageUrl = isEditing ? product.imageUrl : '';

                  // 1. Upload ảnh nếu có chọn ảnh mới
                  if (_selectedImage != null) {
                    finalImageUrl = await _fs.uploadImage(_selectedImage!);
                  }

                  // 2. Gom dữ liệu size
                  Map<String, int> inventory = {
                    for (var s in shoeSizes) s: int.tryParse(sizeControllers[s]!.text) ?? 0
                  };

                  // 3. Tạo model và lưu Firestore
                  final p = ProductModel(
                    id: isEditing ? product.id : '',
                    name: nameController.text,
                    price: double.tryParse(priceController.text) ?? 0,
                    categoryId: selectedCategoryId!,
                    imageUrl: finalImageUrl,
                    description: descController.text,
                    sizesStock: inventory,
                  );

                  isEditing ? await _fs.updateProduct(p) : await _fs.addProduct(p);

                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
                } finally {
                  setDialogState(() => _isSaving = false);
                }
              },
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Lưu", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kho Sản Phẩm", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductForm(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: _fs.getProducts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final products = snapshot.data!;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: Image.network(p.imageUrl, width: 50, height: 50, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image)),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Tổng kho: ${p.getTotalStock()} | Giá: ${p.price.toInt()}đ"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showProductForm(product: p)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _fs.deleteProduct(p.id, p.imageUrl)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}