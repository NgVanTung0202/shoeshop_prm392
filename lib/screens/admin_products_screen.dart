import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../models/product_model.dart';
import '../models/category_model.dart';
import '../services/firestore_service.dart';
import '../services/db_seeder.dart';
import '../widgets/admin_drawer.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final FirestoreService _fs = FirestoreService();
  File? _selectedImage;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = ''; // Đổi thành biến thường để cập nhật được
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
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                      child: (_selectedImage != null)
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (dialogCategoryId == null || nameController.text.isEmpty) return;
                setDialogState(() => isSaving = true);
                try {
                  String finalImageUrl = isEditing ? product.imageUrl : '';
                  if (_selectedImage != null) finalImageUrl = await _fs.uploadImage(_selectedImage!);

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
                  if (mounted) Navigator.pop(context);
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
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Kho Sản Phẩm", style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.data_object),
            onPressed: () async {
              // Sửa DbSeeder thành DBSeeder (viết hoa chữ B)
              await DBSeeder.seedAll();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã tạo data mẫu!'))
                );
              }
            },
          ),
        ],
      ),
      drawer: const AdminDrawer(selected: AdminMenuItem.products),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () => _showProductForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Ô tìm kiếm
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: "Tìm kiếm theo tên hoặc thương hiệu...",
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim().toLowerCase());
                },
              ),
            ),
          ),
          // Dải filter danh mục (simple)
          SizedBox(
            height: 44,
            child: StreamBuilder<List<CategoryModel>>(
              stream: _fs.getCategories(),
              builder: (context, snapshot) {
                final cats = snapshot.data ?? [];
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCategoryFilterChip(label: "Tất cả", id: null),
                    ...cats.map(
                      (c) => _buildCategoryFilterChip(label: c.name, id: c.id),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Danh sách sản phẩm
          Expanded(
            child: StreamBuilder<List<ProductModel>>(
              stream: _fs.getProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Lỗi tải dữ liệu"));
                }

                List<ProductModel> products = snapshot.data ?? [];

                // Lọc theo danh mục
                if (_filterCategoryId != null) {
                  products = products
                      .where((p) => p.categoryId == _filterCategoryId)
                      .toList();
                }

                // Tìm kiếm theo tên hoặc thương hiệu
                if (_searchQuery.isNotEmpty) {
                  products = products.where((p) {
                    final name = p.name.toLowerCase();
                    final brand = p.brand.toLowerCase();
                    return name.contains(_searchQuery) ||
                        brand.contains(_searchQuery);
                  }).toList();
                }

                if (products.isEmpty) {
                  return const Center(child: Text("Không có sản phẩm"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final p = products[index];
                    final totalStock = p.sizesStock.values.fold<int>(
                      0,
                      (prev, e) => prev + e,
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              p.imageUrl,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(
                                    width: 72,
                                    height: 72,
                                    color: const Color(0xFFF0F1F5),
                                    child: const Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Colors.grey,
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.brand,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 13,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      "Kho: $totalStock",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      "|",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "${p.price.toStringAsFixed(0)}đ",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.grey,
                              size: 22,
                            ),
                            onPressed: () => _showProductForm(product: p),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.grey,
                              size: 22,
                            ),
                            onPressed: () => _confirmDelete(p),
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
    );
  }

  // Chip filter danh mục giống ảnh
  Widget _buildCategoryFilterChip({required String label, String? id}) {
    final bool isSelected = _filterCategoryId == id;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _filterCategoryId = id;
          });
        },
        selectedColor: Colors.blue,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
        backgroundColor: const Color(0xFFE9EDF7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
            color: isSelected ? Colors.blue : Colors.transparent,
          ),
        ),
      ),
    );
  }
}