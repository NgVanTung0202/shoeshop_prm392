import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../models/product_model.dart';
import '../models/category_model.dart';
import '../services/firestore_service.dart';
// Đã loại bỏ DBSeeder import
import '../widgets/admin_drawer.dart';
import 'admin_dashboard_screen.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final FirestoreService _fs = FirestoreService();
  File? _selectedImage;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String? _filterCategoryId;

  final List<String> shoeSizes = ['36', '37', '38', '39', '40', '41', '42', '43', '44'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Hàm chọn ảnh ---
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
        const SnackBar(content: Text("Upload ảnh tốt nhất trên mobile/emulator")),
      );
      return;
    }

    setDialogState(() {
      _selectedImage = File(pickedFile.path);
    });
  }

  // --- Xác nhận xóa ---
  void _confirmDelete(ProductModel product) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text('Bạn có chắc muốn xóa "${product.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _fs.deleteProduct(product.id, product.imageUrl);
              if (!mounted) return;
              Navigator.pop(dialogContext);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- Form Thêm/Sửa sản phẩm ---
  void _showProductForm({ProductModel? product}) {
    final bool isEditing = product != null;
    String? dialogCategoryId = isEditing ? product.categoryId : null;
    bool isSaving = false;

    final nameController = TextEditingController(text: isEditing ? product.name : '');
    final brandController = TextEditingController(text: isEditing ? product.brand : '');
    final priceController = TextEditingController(text: isEditing ? product.price.toString() : '');
    final descController = TextEditingController(text: isEditing ? product.description : '');

    final Map<String, TextEditingController> sizeControllers = {
      for (var size in shoeSizes)
        size: TextEditingController(
          text: isEditing ? (product.sizesStock[size] ?? 0).toString() : '0',
        )
    };

    _selectedImage = null;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(isEditing ? "Cập nhật sản phẩm" : "Thêm giày mới"),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _pickImage(setDialogState),
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F1F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: (!kIsWeb && _selectedImage != null)
                          ? Image.file(_selectedImage!, fit: BoxFit.cover)
                          : (isEditing && product.imageUrl.isNotEmpty)
                          ? Image.network(product.imageUrl, fit: BoxFit.cover)
                          : const Center(child: Icon(Icons.add_a_photo_outlined, size: 40)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  StreamBuilder<List<CategoryModel>>(
                    stream: _fs.getCategories(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const LinearProgressIndicator();
                      return DropdownButtonFormField<String>(
                        value: dialogCategoryId,
                        hint: const Text("Chọn danh mục"),
                        items: snapshot.data!.map((cat) => DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        )).toList(),
                        onChanged: (val) => setDialogState(() => dialogCategoryId = val),
                      );
                    },
                  ),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: "Tên giày")),
                  TextField(controller: brandController, decoration: const InputDecoration(labelText: "Brand")),
                  TextField(controller: priceController, decoration: const InputDecoration(labelText: "Giá"), keyboardType: TextInputType.number),
                  TextField(controller: descController, decoration: const InputDecoration(labelText: "Mô tả")),
                  const SizedBox(height: 20),
                  const Align(alignment: Alignment.centerLeft, child: Text("Kho hàng theo Size", style: TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: shoeSizes.map((size) => SizedBox(
                      width: 70,
                      child: TextField(
                        controller: sizeControllers[size],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: "S-$size", border: const OutlineInputBorder()),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Hủy")),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (dialogCategoryId == null || nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng điền đủ thông tin")));
                  return;
                }
                setDialogState(() => isSaving = true);
                try {
                  String finalImageUrl = isEditing ? product.imageUrl : '';
                  if (!kIsWeb && _selectedImage != null) finalImageUrl = await _fs.uploadImage(_selectedImage!);

                  Map<String, int> inventory = {for (var s in shoeSizes) s: int.tryParse(sizeControllers[s]!.text) ?? 0};

                  final p = ProductModel(
                    id: isEditing ? product.id : '',
                    name: nameController.text,
                    brand: brandController.text,
                    price: double.tryParse(priceController.text) ?? 0,
                    categoryId: dialogCategoryId!,
                    imageUrl: finalImageUrl,
                    description: descController.text,
                    sizesStock: inventory,
                  );

                  isEditing ? await _fs.updateProduct(p) : await _fs.addProduct(p);
                  if (!mounted) return;
                  Navigator.pop(dialogContext);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
                } finally {
                  setDialogState(() => isSaving = false);
                }
              },
              child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Lưu"),
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
        centerTitle: true,
        title: const Text("Kho Sản Phẩm", style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          // Đã xóa nút Seed Data
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminDashboardScreen())),
          ),
        ],
      ),
      drawer: const AdminDrawer(selected: AdminMenuItem.products),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductForm(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: _fs.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Text("Lỗi tải dữ liệu"));

          List<ProductModel> products = snapshot.data ?? [];

          if (_searchQuery.isNotEmpty) {
            products = products.where((p) {
              final name = p.name.toLowerCase();
              final brand = p.brand.toLowerCase();
              return name.contains(_searchQuery.toLowerCase()) || brand.contains(_searchQuery.toLowerCase());
            }).toList();
          }
          if (_filterCategoryId != null) {
            products = products.where((p) => p.categoryId == _filterCategoryId).toList();
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    p.imageUrl,
                    width: 55, height: 55, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                  ),
                ),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${p.brand} • ${p.price.toInt()}đ"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => _showProductForm(product: p)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(p)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}