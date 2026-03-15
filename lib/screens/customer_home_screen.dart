import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/firestore_service.dart';
import '../utils/format_utils.dart';
import 'cart_screen.dart';
import 'change_password_screen.dart';
import 'product_detail_screen.dart';
import 'profile_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final FirestoreService _fs = FirestoreService();
  final AuthService _authService = AuthService();
  final CartService _cartService = CartService();
  final TextEditingController _searchController = TextEditingController();

  String? _selectedCategoryId;
  String _searchQuery = '';

  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    await _authService.logout();

    if (!mounted) {
      return;
    }

    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _openCartScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _openProductDetail(ProductModel product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
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
              'Chào mừng bạn,',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            Text(
              'Chọn đôi giày yêu thích',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
        actions: [_buildCartIcon(), const SizedBox(width: 8)],
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
              currentUser?.email?.split('@')[0] ?? 'Khách hàng',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(currentUser?.email ?? 'Chưa đăng nhập'),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined, color: Colors.blue),
            title: const Text('Trang chủ'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.blue),
            title: const Text('Lịch sử đơn hàng'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.blue),
            title: const Text('Thông tin cá nhân'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.orange),
            title: const Text('Đổi mật khẩu'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            },
          ),
          const Divider(),
          currentUser == null
              ? ListTile(
                leading: const Icon(Icons.login, color: Colors.green),
                title: const Text('Đăng nhập ngay'),
                onTap: () => Navigator.pushNamed(context, '/login'),
              )
              : ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Đăng xuất'),
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
    final int totalItems = _cartService.getTotalItems();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(
            Icons.shopping_cart_outlined,
            color: Colors.blue,
            size: 28,
          ),
          onPressed: _openCartScreen,
        ),
        if (totalItems > 0)
          Positioned(
            right: 4,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              constraints: const BoxConstraints(minWidth: 18),
              child: Text(
                '$totalItems',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
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
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim().toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Tìm kiếm mẫu giày mới...',
          prefixIcon: const Icon(Icons.search, color: Colors.blue),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                  : null,
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }

          final List<CategoryModel> categories =
              snapshot.data ?? <CategoryModel>[];

          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCategoryChip(label: 'All', value: null),
              ...categories.map(
                (category) => _buildCategoryChip(
                  label: category.name,
                  value: category.id,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip({required String label, String? value}) {
    final bool isSelected = _selectedCategoryId == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryId = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.blue.shade100,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.blue.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
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

          if (snapshot.hasError) {
            return const Center(child: Text('Không thể tải sản phẩm'));
          }

          final List<ProductModel> products = snapshot.data ?? <ProductModel>[];
          final List<ProductModel> filteredProducts =
              products.where((product) {
                final bool matchCategory =
                    _selectedCategoryId == null
                        ? true
                        : product.categoryId == _selectedCategoryId;

                if (_searchQuery.isEmpty) {
                  return matchCategory;
                }

                final String name = product.name.toLowerCase();
                final String brand = product.brand.toLowerCase();
                final bool matchSearch =
                    name.contains(_searchQuery) || brand.contains(_searchQuery);

                return matchCategory && matchSearch;
              }).toList();

          if (filteredProducts.isEmpty) {
            if (_searchQuery.isNotEmpty) {
              return Center(
                child: Text(
                  "Không tìm thấy sản phẩm nào cho '$_searchQuery'",
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              );
            }

            return const Center(
              child: Text('Chưa có sản phẩm', style: TextStyle(fontSize: 16)),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.66,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              return _buildProductCard(filteredProducts[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () => _openProductDetail(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Hero(
                  tag: product.id,
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (_, __, ___) => const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                        ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatPrice(product.price),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
