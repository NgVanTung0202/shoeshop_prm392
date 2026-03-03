import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Để xử lý file ảnh
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
  File? _selectedImage; // Biến lưu ảnh vừa chọn

  // Hàm chọn ảnh từ thư viện
  Future<void> _pickImage(StateSetter setDialogState) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
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
    selectedCategoryId = isEditing ? product.categoryId : null;
    _selectedImage = null; // Reset ảnh mỗi lần mở form

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(isEditing ? "Cập nhật sản phẩm" : "Thêm giày mới",
              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Phần chọn ảnh thay vì nhập link
                GestureDetector(
                  onTap: () => _pickImage(setDialogState),
                  child: Container(
                    height: 120,
                    width: double.infinity,
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
                      children: [Icon(Icons.camera_alt, color: Colors.blue), Text("Chọn ảnh giày")],
                    )),
                  ),
                ),
                const SizedBox(height: 15),
                // Dropdown Danh mục
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
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () async {
                // Lưu ý: Ở đây bạn cần thêm hàm upload _selectedImage lên Firebase Storage
                // để lấy lại URL rồi mới gán vào ProductModel.
                // Hiện tại mình tạm để link cũ hoặc rỗng để code không lỗi.
                final p = ProductModel(
                  id: isEditing ? product.id : '',
                  name: nameController.text,
                  price: double.tryParse(priceController.text) ?? 0,
                  categoryId: selectedCategoryId!,
                  imageUrl: isEditing ? product.imageUrl : 'https://link-anh-mac-dinh.com',
                  description: 'Giày chính hãng',
                  stock: 10,
                );
                isEditing ? await _fs.updateProduct(p) : await _fs.addProduct(p);
                if (mounted) Navigator.pop(context);
              },
              child: const Text("Lưu", style: TextStyle(color: Colors.white)),
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
        title: const Text("Quản lý sản phẩm", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Center(child: Text("SHOESHOP ADMIN", style: TextStyle(color: Colors.white, fontSize: 20))),
            ),
            ListTile(leading: const Icon(Icons.list, color: Colors.blue), title: const Text("Sản phẩm"), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.category, color: Colors.blue), title: const Text("Danh mục"),
                onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminCategoryScreen())); }),
            const Spacer(),
            ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Đăng xuất"), onTap: () => FirebaseAuth.instance.signOut()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showProductForm(), backgroundColor: Colors.blue, child: const Icon(Icons.add, color: Colors.white)),
      body: StreamBuilder<List<ProductModel>>(
        stream: _fs.getProducts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final products = snapshot.data!;
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
                columns: const [
                  DataColumn(label: Text('Ảnh')),
                  DataColumn(label: Text('Tên sản phẩm')),
                  DataColumn(label: Text('Giá')),
                  DataColumn(label: Text('Hành động')), // Cột chứa nút Sửa/Xóa
                ],
                rows: products.map((p) => DataRow(cells: [
                  DataCell(Image.network(p.imageUrl, width: 40, height: 40, errorBuilder: (_, __, ___) => const Icon(Icons.image))),
                  DataCell(SizedBox(width: 120, child: Text(p.name, overflow: TextOverflow.ellipsis))),
                  DataCell(Text("${p.price.toInt()}đ")),
                  DataCell(Row( // ĐÂY LÀ NƠI CHỨA NÚT SỬA XÓA
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showProductForm(product: p)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _fs.deleteProduct(p.id)),
                    ],
                  )),
                ])).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}