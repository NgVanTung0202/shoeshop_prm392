import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../services/firestore_service.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final FirestoreService _fs = FirestoreService();
  String selectedCategoryId = 'All';
  final User? currentUser = FirebaseAuth.instance.currentUser;

  void _handleLogout() {
    FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 1. THÊM SIDEBAR (DRAWER)
      drawer: Drawer(
        child: Column(
          children: [
            // Header của Sidebar
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.blue),
              ),
              accountName: Text(
                currentUser?.email?.split('@')[0] ?? "Khách hàng",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(currentUser?.email ?? "Chưa đăng nhập"),
            ),

            // Các mục Menu
            ListTile(
              leading: const Icon(Icons.home_outlined, color: Colors.blue),
              title: const Text("Trang chủ"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.blue),
              title: const Text("Lịch sử đơn hàng"),
              onTap: () {
                // Điều hướng đến lịch sử
              },
            ),
            const Divider(), // Đường kẻ ngang

            // Logic hiển thị nút Đăng nhập hoặc Đăng xuất
            currentUser == null
                ? ListTile(
              leading: const Icon(Icons.login, color: Colors.green),
              title: const Text("Đăng nhập ngay"),
              onTap: () => Navigator.pushNamed(context, '/login'),
            )
                : ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text("Đăng xuất"),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
          ],
        ),
      ),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.blue), // Đổi màu icon hamburger
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Chào mừng bạn,",
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            Text("Chọn đôi giày yêu thích",
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        actions: [
          _buildCartIcon(),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryList(),
          const SizedBox(height: 15),
          _buildProductGrid(),
        ],
      ),
    );
  }

  // --- TÁCH CÁC WIDGET CON ĐỂ CODE GỌN HƠN ---

  Widget _buildCartIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.blue, size: 28),
          onPressed: () {},
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
            child: const Text('0', style: TextStyle(color: Colors.white, fontSize: 8), textAlign: TextAlign.center),
          ),
        )
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Tìm kiếm mẫu giày mới...",
          prefixIcon: const Icon(Icons.search, color: Colors.blue),
          filled: true,
          fillColor: Colors.blue.shade50,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: 45,
      child: StreamBuilder<List<CategoryModel>>(
        stream: _fs.getCategories(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          final categories = snapshot.data!;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              String catName = index == 0 ? 'All' : categories[index - 1].name;
              bool isSelected = selectedCategoryId == catName;
              return GestureDetector(
                onTap: () => setState(() => selectedCategoryId = catName),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: isSelected ? Colors.blue : Colors.blue.shade100),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    catName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.blue.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    return Expanded(
      child: StreamBuilder<List<ProductModel>>(
        stream: _fs.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data ?? [];
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) => _buildProductCard(products[index]),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(ProductModel p) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue.shade50.withOpacity(0.5), borderRadius: BorderRadius.circular(15)),
              child: Center(
                child: Image.network(p.imageUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${p.price.toInt()}đ", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    const Icon(Icons.add_box, color: Colors.blue, size: 28),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}