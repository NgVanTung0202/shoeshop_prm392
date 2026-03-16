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
  int _selectedNavIndex = 0;
  final Set<String> _favoriteProductIds = <String>{};

  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Logic Đăng xuất ---
  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  // --- Logic Thông báo phía trên (Top Notice) ---
  Future<void> _showTopNotice(String message, {bool isFavorite = false}) async {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'notice',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, __, ___) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  border: Border.all(
                    color: isFavorite ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(isFavorite ? Icons.favorite : Icons.check_circle,
                        color: isFavorite ? Colors.red : Colors.green, size: 22),
                    const SizedBox(width: 10),
                    Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black))),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim, __, child) {
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(anim),
            child: child,
          ),
        );
      },
    );
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      // Đóng dialog một cách an toàn
      Navigator.of(context, rootNavigator: true).pop();
    }
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chào mừng bạn,', style: TextStyle(color: Colors.grey, fontSize: 13)),
            Text(currentUser?.email?.split('@')[0] ?? 'Khách hàng',
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        actions: [
          _buildTopFavoriteAction(),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryList(),
          const SizedBox(height: 10),
          _buildProductGrid(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // --- UI Các Action trên AppBar ---
  Widget _buildTopFavoriteAction() {
    int count = _favoriteProductIds.length;
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(count > 0 ? Icons.favorite : Icons.favorite_border, color: Colors.red),
          onPressed: () => _showTopNotice("Bạn có $count sản phẩm yêu thích", isFavorite: true),
        ),
        if (count > 0)
          Positioned(right: 8, top: 8, child: _buildBadge(count.toString())),
      ],
    );
  }

  // --- Widget Badge số lượng ---
  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      child: Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center
      ),
    );
  }

  // --- Thanh Tìm Kiếm ---
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm mẫu giày mới...',
          prefixIcon: const Icon(Icons.search, color: Colors.blue),
          filled: true,
          fillColor: Colors.blue.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  // --- Danh sách Danh mục ---
  Widget _buildCategoryList() {
    return SizedBox(
      height: 45,
      child: StreamBuilder<List<CategoryModel>>(
        stream: _fs.getCategories(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final cats = snapshot.data!;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cats.length + 1,
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final label = isAll ? 'Tất cả' : cats[index - 1].name;
              final value = isAll ? null : cats[index - 1].id;
              final isSelected = _selectedCategoryId == value;

              return GestureDetector(
                onTap: () => setState(() => _selectedCategoryId = value),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  alignment: Alignment.center,
                  child: Text(label, style: TextStyle(
                      color: isSelected ? Colors.white : Colors.blue,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                  )),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- Grid Sản phẩm ---
  Widget _buildProductGrid() {
    return Expanded(
      child: StreamBuilder<List<ProductModel>>(
        stream: _fs.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Không có sản phẩm nào."));

          final filtered = snapshot.data!.where((p) {
            final matchCat = _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
            final matchSearch = p.name.toLowerCase().contains(_searchQuery) || p.brand.toLowerCase().contains(_searchQuery);
            return matchCat && matchSearch;
          }).toList();

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) => _buildProductCard(filtered[index]),
          );
        },
      ),
    );
  }

  // --- Widget Card Sản phẩm ---
  Widget _buildProductCard(ProductModel p) {
    bool isFav = _favoriteProductIds.contains(p.id);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(15)),
                    child: Hero(
                      tag: p.id,
                      child: Image.network(p.imageUrl, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported)),
                    ),
                  ),
                  Positioned(
                    top: 12, right: 12,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isFav) _favoriteProductIds.remove(p.id);
                          else {
                            _favoriteProductIds.add(p.id);
                            _showTopNotice("Đã thêm vào yêu thích", isFavorite: true);
                          }
                        });
                      },
                      child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.grey),
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(p.brand, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formatPrice(p.price), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      GestureDetector(
                        onTap: () {
                          // Lấy size đầu tiên còn hàng để thêm vào giỏ
                          String defaultSize = p.sizesStock.keys.firstWhere((s) => p.sizesStock[s]! > 0, orElse: () => "N/A");
                          if (defaultSize != "N/A") {
                            _cartService.addItem(p, defaultSize);
                            _showTopNotice("Đã thêm vào giỏ hàng");
                            setState(() {});
                          } else {
                            _showTopNotice("Sản phẩm đã hết hàng", isFavorite: true);
                          }
                        },
                        child: const Icon(Icons.add_circle, color: Colors.blue, size: 26),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- Bottom Navigation Bar ---
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedNavIndex,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      onTap: (index) async {
        if (index == 0) {
          setState(() => _selectedNavIndex = 0);
        } else if (index == 1) {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
          setState(() {}); // Cập nhật lại badge giỏ hàng khi quay về
        } else if (index == 2) {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          setState(() {});
        }
      },
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
        BottomNavigationBarItem(
            icon: Stack(children: [
              const Icon(Icons.shopping_cart),
              if (_cartService.getTotalItems() > 0)
                Positioned(right: -2, top: -2, child: _buildBadge(_cartService.getTotalItems().toString()))
            ]),
            label: 'Giỏ hàng'
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tôi'),
      ],
    );
  }

  // --- Drawer ---
  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.blue),
            ),
            accountName: Text(currentUser?.email?.split('@')[0] ?? 'Khách hàng', style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(currentUser?.email ?? 'Chưa đăng nhập'),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.blue),
            title: const Text('Trang chủ'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.blue),
            title: const Text('Thông tin cá nhân'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.orange),
            title: const Text('Đổi mật khẩu'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất'),
            onTap: _handleLogout,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}