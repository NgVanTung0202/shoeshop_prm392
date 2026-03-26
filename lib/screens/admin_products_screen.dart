import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product_model.dart';
import '../models/category_model.dart';
import '../services/firestore_service.dart';
import '../services/db_seeder.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/storage_network_image.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final FirestoreService _fs = FirestoreService();
  XFile? _pickedProductImage;
  Uint8List? _productImagePreviewBytes;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = ''; // Đổi thành biến thường để cập nhật được
  String? _filterCategoryId;

  final List<String> shoeSizes = [
    '36',
    '37',
    '38',
    '39',
    '40',
    '41',
    '42',
    '43',
    '44',
  ];

  Future<String> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'customer';
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return (doc.data()?['role'] ?? 'customer').toString().toLowerCase().trim();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Hàm chọn ảnh (mobile + web: XFile + preview bytes) ---
  Future<void> _pickImage(StateSetter setDialogState) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();
    setDialogState(() {
      _pickedProductImage = pickedFile;
      _productImagePreviewBytes = bytes;
    });
  }

fix/profile-firestore-error
  void _confirmDelete(ProductModel product) {


  void _confirmDelete(ProductModel product, {required String role}) {
    if (role != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn không có quyền xóa sản phẩm')),
      );
      return;
    }
 main
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
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
                  final messenger = ScaffoldMessenger.of(dialogContext);
                  try {
                    await _fs.deleteProduct(product.id, product.imageUrl);
                    if (!mounted) return;
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Đã xóa "${product.name}"'),
                        backgroundColor: Colors.green.shade700,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    final msg =
                        e is FirebaseException &&
                                e.message != null &&
                                e.message!.isNotEmpty
                            ? e.message!
                            : e.toString();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Không thể xóa: $msg'),
                        backgroundColor: Colors.red.shade800,
                      ),
                    );
                  }
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

    final nameController = TextEditingController(
      text: isEditing ? product.name : '',
    );
    final brandController = TextEditingController(
      text: isEditing ? product.brand : '',
    );
    final priceController = TextEditingController(
      text: isEditing ? product.price.toString() : '',
    );
    final descController = TextEditingController(
      text: isEditing ? product.description : '',
    );

    final Map<String, TextEditingController> sizeControllers = {
      for (var size in shoeSizes)
        size: TextEditingController(
          text: isEditing ? (product.sizesStock[size] ?? 0).toString() : '0',
        ),
    };

    _pickedProductImage = null;
    _productImagePreviewBytes = null;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(
                    isEditing ? "Cập nhật sản phẩm" : "Thêm giày mới",
                  ),
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
                              child:
                                  (_productImagePreviewBytes != null)
                                      ? Image.memory(
                                        _productImagePreviewBytes!,
                                        fit: BoxFit.cover,
                                      )
                                      : (isEditing &&
                                          product.imageUrl.isNotEmpty)
                                      ? _buildStoredProductImage(
                                        product.imageUrl,
                                      )
                                      : const Center(
                                        child: Icon(
                                          Icons.add_a_photo_outlined,
                                          size: 40,
                                        ),
                                      ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          StreamBuilder<List<CategoryModel>>(
                            stream: _fs.getCategories(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const LinearProgressIndicator();
                              }
                              return DropdownButtonFormField<String>(
                                initialValue: dialogCategoryId,
                                hint: const Text("Chọn danh mục"),
                                items:
                                    snapshot.data!
                                        .map(
                                          (cat) => DropdownMenuItem(
                                            value: cat.id,
                                            child: Text(cat.name),
                                          ),
                                        )
                                        .toList(),
                                onChanged:
                                    (val) => setDialogState(
                                      () => dialogCategoryId = val,
                                    ),
                              );
                            },
                          ),
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: "Tên giày",
                            ),
                          ),
                          TextField(
                            controller: brandController,
                            decoration: const InputDecoration(
                              labelText: "Brand",
                            ),
                          ),
                          TextField(
                            controller: priceController,
                            decoration: const InputDecoration(labelText: "Giá"),
                            keyboardType: TextInputType.number,
                          ),
                          TextField(
                            controller: descController,
                            decoration: const InputDecoration(
                              labelText: "Mô tả",
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Kho hàng theo Size",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                shoeSizes
                                    .map(
                                      (size) => SizedBox(
                                        width: 70,
                                        child: TextField(
                                          controller: sizeControllers[size],
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: "S-$size",
                                            border: const OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Hủy"),
                    ),
                    ElevatedButton(
                      onPressed:
                          isSaving
                              ? null
                              : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                if (dialogCategoryId == null ||
                                    nameController.text.isEmpty) {
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Vui lòng chọn danh mục và nhập tên sản phẩm',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                setDialogState(() => isSaving = true);
                                try {
                                  String finalImageUrl =
                                      isEditing ? product.imageUrl : '';
                                  if (_pickedProductImage != null) {
                                    finalImageUrl = await _fs
                                        .uploadImageFromXFile(
                                          _pickedProductImage!,
                                        );
                                  }

                                  Map<String, int> inventory = {
                                    for (var s in shoeSizes)
                                      s:
                                          int.tryParse(
                                            sizeControllers[s]!.text,
                                          ) ??
                                          0,
                                  };

                                  final p = ProductModel(
                                    id: isEditing ? product.id : '',
                                    name: nameController.text,
                                    brand: brandController.text,
                                    price:
                                        double.tryParse(priceController.text) ??
                                        0,
                                    categoryId: dialogCategoryId!,
                                    imageUrl: finalImageUrl,
                                    description: descController.text,
                                    sizesStock: inventory,
                                  );

                                  if (isEditing) {
                                    await _fs.updateProduct(p);
                                  } else {
                                    await _fs.addProduct(p);
                                  }

                                  if (!mounted) return;
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isEditing
                                            ? 'Đã cập nhật sản phẩm'
                                            : 'Đã thêm sản phẩm',
                                      ),
                                      backgroundColor: Colors.green.shade700,
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  final String msg;
                                  if (e is FirebaseException) {
                                    msg =
                                        e.message != null &&
                                                e.message!.isNotEmpty
                                            ? e.message!
                                            : 'Lỗi Firebase (${e.code})';
                                  } else {
                                    msg = e.toString();
                                  }
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Không thể lưu: $msg'),
                                      backgroundColor: Colors.red.shade800,
                                    ),
                                  );
                                } finally {
                                  setDialogState(() => isSaving = false);
                                }
                              },
                      child:
                          isSaving
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text("Lưu"),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
fix/profile-firestore-error
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          "Kho Sản Phẩm",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.data_object),
            onPressed: () async {
              // Sửa DbSeeder thành DBSeeder (viết hoa chữ B)
              final messenger = ScaffoldMessenger.of(context);
              await DBSeeder.seedAll();
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Đã tạo data mẫu!')),
                );
              }
            },

    return FutureBuilder<String>(
      future: _getUserRole(),
      builder: (context, roleSnap) {
        final role = roleSnap.data ?? 'customer';
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
 main
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
                  products =
                      products
                          .where((p) => p.categoryId == _filterCategoryId)
                          .toList();
                }

                // Tìm kiếm theo tên hoặc thương hiệu
                if (_searchQuery.isNotEmpty) {
                  products =
                      products.where((p) {
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
                            child: _buildProductImageTile(p.imageUrl, size: 72),
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
                          if (role == 'admin')
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.grey,
                                size: 22,
                              ),
                              onPressed: () => _confirmDelete(p, role: role),
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
      },
    );
  }

  /// Form sửa: ảnh đã lưu — URL Storage dùng network, ảnh mẫu trong app dùng asset.
  Widget _buildStoredProductImage(String url) {
    const double h = 140;
    const Widget fallback = SizedBox(
      height: h,
      child: Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40),
      ),
    );
    if (url.isEmpty) {
      return const Center(child: Icon(Icons.add_a_photo_outlined, size: 40));
    }
    if (ProductModel.isNetworkImageUrl(url)) {
      return StorageNetworkImage(
        url: url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: h,
        fallback: fallback,
      );
    }
    return Image.asset(
      ProductModel.normalizeLocalAssetPath(url),
      fit: BoxFit.cover,
      width: double.infinity,
      height: h,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  Widget _buildProductImageTile(String imageUrl, {double size = 72}) {
    final Widget fallback = Container(
      width: size,
      height: size,
      color: const Color(0xFFF0F1F5),
      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
    );
    if (imageUrl.isEmpty) return fallback;
    if (ProductModel.isNetworkImageUrl(imageUrl)) {
      return StorageNetworkImage(
        url: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        fallback: fallback,
      );
    }
    return Image.asset(
      ProductModel.normalizeLocalAssetPath(imageUrl),
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
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
