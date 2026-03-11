import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../services/firestore_service.dart';
import '../widgets/admin_drawer.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final FirestoreService _fs = FirestoreService();
  String? selectedCategoryId;
  File? _selectedImage;
  bool _isSaving = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterCategoryId;

  // Danh sách size cần quản lý
  final List<String> shoeSizes = ['36', '37', '38', '39', '40', '41', '42', '43', '44'];

  @override
  void dispose() {
    _searchController.dispose();
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
                  "Upload ảnh chỉ hỗ trợ tốt trên mobile/emulator. Trên web vui lòng dùng ảnh đã có URL."),
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

  void _confirmDelete(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Xác nhận xóa"),
        content: Text('Bạn có chắc muốn xóa sản phẩm "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _fs.deleteProduct(product.id, product.imageUrl);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }

  void _showProductForm({ProductModel? product}) {
    final isEditing = product != null;

    // Các Controller cho thông tin chữ
    final nameController = TextEditingController(text: isEditing ? product.name : '');
    final brandController = TextEditingController(text: isEditing ? product.brand : ''); // THÊM BRAND
    final priceController = TextEditingController(text: isEditing ? product.price.toString() : '');
    final descController = TextEditingController(text: isEditing ? product.description : '');

    // Controller cho kho hàng theo từng size
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isEditing ? "Cập nhật sản phẩm" : "Thêm giày mới",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- CHỌN ẢNH ---
                  GestureDetector(
                    onTap: _isSaving ? null : () => _pickImage(setDialogState),
                    child: Container(
                      height: 140, width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F1F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: (!kIsWeb && _selectedImage != null)
                          ? Image.file(_selectedImage!, fit: BoxFit.cover)
                          : (isEditing && product != null && product.imageUrl.isNotEmpty)
                              ? Image.network(product.imageUrl, fit: BoxFit.cover)
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined,
                                        color: Colors.black54, size: 32),
                                    SizedBox(height: 4),
                                    Text(
                                      "Thêm ảnh giày",
                                      style: TextStyle(
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
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
                  TextField(controller: brandController, decoration: const InputDecoration(labelText: "Thương hiệu (Brand)")), // UI CHO BRAND
                  TextField(controller: priceController, decoration: const InputDecoration(labelText: "Giá (VNĐ)"), keyboardType: TextInputType.number),
                  TextField(controller: descController, decoration: const InputDecoration(labelText: "Mô tả ngắn")),

                  const SizedBox(height: 20),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Kho hàng theo Size:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  )),
                  const SizedBox(height: 10),

                  // --- GRID NHẬP SIZE ---
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: shoeSizes.map((size) => SizedBox(
                      width: 70,
                      child: TextField(
                        controller: sizeControllers[size],
                        decoration: InputDecoration(
                            labelText: "S-$size",
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8)
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              child: const Text(
                "Hủy",
                style: TextStyle(color: Colors.black54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: _isSaving ? null : () async {
                if (selectedCategoryId == null || nameController.text.isEmpty || brandController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng điền đủ thông tin!")));
                  return;
                }

                setDialogState(() => _isSaving = true);

                try {
                  String finalImageUrl = isEditing ? product.imageUrl : '';

                  // 1. Upload ảnh nếu có chọn ảnh mới (chỉ mobile)
                  if (_selectedImage != null && !kIsWeb) {
                    finalImageUrl = await _fs.uploadImage(_selectedImage!);
                  }

                  // 2. Gom dữ liệu tồn kho từ các controller
                  Map<String, int> inventory = {
                    for (var s in shoeSizes) s: int.tryParse(sizeControllers[s]!.text) ?? 0
                  };

                  // 3. Đóng gói dữ liệu vào Model
                  final p = ProductModel(
                    id: isEditing ? product.id : '',
                    name: nameController.text,
                    brand: brandController.text, // LƯU BRAND
                    price: double.tryParse(priceController.text) ?? 0,
                    categoryId: selectedCategoryId!,
                    imageUrl: finalImageUrl,
                    description: descController.text,
                    sizesStock: inventory,
                  );

                  // 4. Đẩy lên Firestore
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
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,
        title: const Text(
          "Kho Sản Phẩm",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      drawer: const AdminDrawer(selected: AdminMenuItem.products),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductForm(),
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: Container(
        color: const Color(0xFFF5F6FA),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Tìm kiếm theo tên hoặc thương hiệu...",
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
            SizedBox(
              height: 46,
              child: StreamBuilder<List<CategoryModel>>(
                stream: _fs.getCategories(),
                builder: (context, snapshot) {
                  final categories = snapshot.data ?? [];
                  return ListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    scrollDirection: Axis.horizontal,
                    children: [
                      ChoiceChip(
                        label: const Text("Tất cả"),
                        selected: _filterCategoryId == null,
                        selectedColor: Colors.black,
                        labelStyle: TextStyle(
                          color: _filterCategoryId == null
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        backgroundColor: Colors.white,
                        onSelected: (_) {
                          setState(() {
                            _filterCategoryId = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ...categories.map(
                        (cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat.name),
                            selected: _filterCategoryId == cat.id,
                            selectedColor: Colors.black,
                            labelStyle: TextStyle(
                              color: _filterCategoryId == cat.id
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            backgroundColor: Colors.white,
                            onSelected: (_) {
                              setState(() {
                                _filterCategoryId = cat.id;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ProductModel>>(
                stream: _fs.getProducts(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  List<ProductModel> products = snapshot.data!;

                  if (_searchQuery.isNotEmpty) {
                    products = products.where((p) {
                      final name = p.name.toLowerCase();
                      final brand = p.brand.toLowerCase();
                      return name.contains(_searchQuery) || brand.contains(_searchQuery);
                    }).toList();
                  }

                  if (_filterCategoryId != null) {
                    products = products
                        .where((p) => p.categoryId == _filterCategoryId)
                        .toList();
                  }

                  if (products.isEmpty) {
                    return const Center(
                      child: Text(
                        "Không tìm thấy sản phẩm nào",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final p = products[index];
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
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                p.imageUrl,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 72,
                                  height: 72,
                                  color: const Color(0xFFF0F1F5),
                                  child: const Icon(
                                    Icons.image_outlined,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    p.brand,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Kho: ${p.getTotalStock()}   |   ${p.price.toInt()}đ",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.black54,
                              ),
                              onPressed: () => _showProductForm(product: p),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
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
      ),
    );
  }
}