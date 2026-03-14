import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'profile_screen.dart';
import 'change_password_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {

  final FirestoreService _fs = FirestoreService();
  final AuthService _authService = AuthService();

  String selectedCategoryId = "All";

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<void> _handleLogout() async {

    await _authService.logout();

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,

      drawer: _buildDrawer(),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.blue),

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Chào mừng bạn,",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            Text(
              "Chọn đôi giày yêu thích",
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),

        actions: [
          _buildCartIcon(),
          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildCategoryList(),
            const SizedBox(height: 10),
            _buildProductGrid(),
          ],
        ),
      ),
    );
  }

  Drawer _buildDrawer() {

    return Drawer(
      child: Column(
        children: [

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

            accountEmail: Text(
              currentUser?.email ?? "Chưa đăng nhập",
            ),
          ),

          ListTile(
            leading: const Icon(Icons.home_outlined, color: Colors.blue),
            title: const Text("Trang chủ"),
            onTap: () => Navigator.pop(context),
          ),

          ListTile(
            leading: const Icon(Icons.history, color: Colors.blue),
            title: const Text("Lịch sử đơn hàng"),
            onTap: () {},
          ),

          ListTile(
            leading: const Icon(Icons.person, color: Colors.blue),
            title: const Text("Thông tin cá nhân"),
            onTap: () {

              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.lock, color: Colors.orange),
            title: const Text("Đổi mật khẩu"),
            onTap: () {

              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChangePasswordScreen(),
                ),
              );
            },
          ),

          const Divider(),

          currentUser == null
              ? ListTile(
                  leading: const Icon(Icons.login, color: Colors.green),
                  title: const Text("Đăng nhập ngay"),
                  onTap: () {
                    Navigator.pushNamed(context, '/login');
                  },
                )
              : ListTile(
                  leading:
                      const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text("Đăng xuất"),
                  onTap: () {

                    Navigator.pop(context);
                    _handleLogout();
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildCartIcon() {

    return Stack(
      alignment: Alignment.center,

      children: [

        IconButton(
          icon: const Icon(
            Icons.shopping_cart_outlined,
            color: Colors.blue,
            size: 28,
          ),
          onPressed: () {},
        ),

        Positioned(
          right: 8,
          top: 8,

          child: Container(
            padding: const EdgeInsets.all(2),

            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),

            constraints: const BoxConstraints(
              minWidth: 14,
              minHeight: 14,
            ),

            child: const Text(
              "0",
              style: TextStyle(color: Colors.white, fontSize: 8),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

      child: TextField(
        decoration: InputDecoration(
          hintText: "Tìm kiếm mẫu giày mới...",

          prefixIcon: const Icon(Icons.search, color: Colors.blue),

          filled: true,
          fillColor: Colors.blue.shade50,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
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

          if (!snapshot.hasData) {
            return const SizedBox();
          }

          final categories = snapshot.data!;

          return ListView.builder(
            scrollDirection: Axis.horizontal,

            itemCount: categories.length + 1,

            padding: const EdgeInsets.symmetric(horizontal: 16),

            itemBuilder: (context, index) {

              String catName =
                  index == 0 ? "All" : categories[index - 1].name;

              bool isSelected = selectedCategoryId == catName;

              return GestureDetector(

                onTap: () {
                  setState(() {
                    selectedCategoryId = catName;
                  });
                },

                child: Container(
                  margin: const EdgeInsets.only(right: 12),

                  padding:
                      const EdgeInsets.symmetric(horizontal: 25),

                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue
                        : Colors.white,

                    borderRadius: BorderRadius.circular(25),

                    border: Border.all(
                      color: isSelected
                          ? Colors.blue
                          : Colors.blue.shade100,
                    ),
                  ),

                  alignment: Alignment.center,

                  child: Text(
                    catName,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.blue.shade700,
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

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text("Error loading products"),
            );
          }

          final products = snapshot.data ?? [];

          final filteredProducts = selectedCategoryId == "All"
              ? products
              : products
                  .where((p) =>
                      p.categoryId == selectedCategoryId)
                  .toList();

          return GridView.builder(
            padding: const EdgeInsets.all(16),

            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
            ),

            itemCount: filteredProducts.length,

            itemBuilder: (context, index) =>
                _buildProductCard(filteredProducts[index]),
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

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Expanded(
            child: Container(
              width: double.infinity,

              margin: const EdgeInsets.all(8),

              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(15),
              ),

              child: Center(
                child: Image.network(
                  p.imageUrl,
                  fit: BoxFit.contain,

                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_not_supported),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(
                  p.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                ),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,

                  children: [

                    Text(
                      "${p.price.toInt()}đ",
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Icon(
                      Icons.add_box,
                      color: Colors.blue,
                      size: 28,
                    ),
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