import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../widgets/storage_network_image.dart';
import 'brand_shoes_screen.dart';
import 'order_history_screen.dart';

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

  String? _avatarUrl;
  String? _displayName;
  String? _selectedCategoryId;
  String? _selectedBrand;
  String _searchQuery = '';
  int _selectedNavIndex = 0;
  String _selectedSort = 'phobien';
  final Set<String> _favoriteProductIds = <String>{};

  int _currentBannerIndex = 0;
  final PageController _pageController = PageController();
  Timer? _bannerTimer;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _startBannerTimer(); // Kích hoạt chạy banner tự động
  }

  // --- LOGIC TỰ ĐỘNG CHẠY BANNER (MINHBVHE) ---
  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _currentBannerIndex + 1;
        if (nextPage >= 5) { // Reset về trang đầu sau 5 banner
          nextPage = 0;
          _pageController.jumpToPage(nextPage);
        } else {
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (data != null && mounted) {
      setState(() {
        _avatarUrl = data["avatarUrl"];
        _displayName = data["name"];
      });
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _bannerTimer?.cancel(); // Hủy timer tránh rò rỉ bộ nhớ
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Badge dùng chung cho icon
  Widget _buildCountBadge(int count, {Color backgroundColor = Colors.red}) {
    if (count <= 0) return const SizedBox.shrink();
    final label = count > 99 ? '99+' : count.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 1.6),
      ),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, height: 1.1),
      ),
    );
  }

  // Thông báo Custom Top Notice
  Future<void> _showTopNotice(String message, IconData icon, Color color) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'notice',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, __, ___) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.25)),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 22),
                    const SizedBox(width: 10),
                    Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(animation),
            child: child,
          ),
        );
      },
    );
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted && navigator.canPop()) navigator.pop();
  }

  Future<void> _openCartScreen() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
    if (mounted) setState(() {});
  }

  Future<void> _openProductDetail(ProductModel product) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)));
    if (mounted) setState(() {});
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
            Text(
              _displayName?.isNotEmpty == true ? _displayName! : (currentUser?.email?.split('@')[0] ?? 'Khách hàng'),
              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        actions: [_buildFavoriteIcon(), const SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildBannerSlider(),
            const SizedBox(height: 12),
            _buildBrandList(), // Brand UI của minhbvhe
            const SizedBox(height: 10),
            _buildSortDropdown(),
            const SizedBox(height: 10),
            _buildProductGrid(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildFavoriteIcon() {
    final count = _favoriteProductIds.length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(count > 0 ? Icons.favorite : Icons.favorite_border, color: count > 0 ? Colors.red : Colors.blue, size: 28),
          onPressed: () => _showTopNotice(count > 0 ? 'Bạn có $count sản phẩm yêu thích' : 'Chưa có yêu thích', Icons.favorite, Colors.red),
        ),
        if (count > 0) Positioned(right: 6, top: 6, child: _buildCountBadge(count)),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm mẫu giày mới...',
          prefixIcon: const Icon(Icons.search, color: Colors.blue),
          suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }) 
            : null,
          filled: true,
          fillColor: Colors.blue.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildBannerSlider() {
    return SizedBox(
      height: 150,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => _currentBannerIndex = index,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assets/banner/banner${index + 1}.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.blue.shade100, child: const Icon(Icons.image, size: 50, color: Colors.blue)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBrandList() {
    return SizedBox(
      height: 45,
      child: FutureBuilder<List<String>>(
        future: _fs.getAllBrands(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
          final brands = snapshot.data ?? [];
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildBrandChip(label: 'Tất cả hãng', value: null),
              ...brands.map((b) => _buildBrandChip(label: b, value: b)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBrandChip({required String label, String? value}) {
    final isSelected = _selectedBrand == value;
    const chipColor = Colors.orange; 
    return GestureDetector(
      onTap: () => setState(() => _selectedBrand = value),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : chipColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: isSelected ? chipColor : chipColor.withOpacity(0.35)),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : chipColor, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildSortDropdown() {
    final Map<String, String> sortOptions = {
      'phobien': 'Phổ biến', 'giathap': 'Giá thấp', 'giacao': 'Giá cao', 'banchay': 'Bán chạy',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Tất cả sản phẩm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          InkWell(
            onTap: () => _showSortBottomSheet(sortOptions),
            child: Row(
              children: [
                const Icon(Icons.sort, size: 20, color: Colors.blue),
                const SizedBox(width: 4),
                Text(sortOptions[_selectedSort] ?? 'Sắp xếp', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSortBottomSheet(Map<String, String> options) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          const Text('Sắp xếp theo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...options.entries.map((e) => ListTile(
            title: Text(e.value, style: TextStyle(color: _selectedSort == e.key ? Colors.blue : Colors.black)),
            trailing: _selectedSort == e.key ? const Icon(Icons.check, color: Colors.blue) : null,
            onTap: () { setState(() => _selectedSort = e.key); Navigator.pop(context); },
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return Expanded(
      child: StreamBuilder<List<ProductModel>>(
        stream: _fs.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Text('Lỗi tải dữ liệu'));

          final products = snapshot.data ?? [];
          // LOGIC LỌC THUẦN TỪ DATA (MINHBVHE)
          final filtered = products.where((p) {
            bool matchCat = _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
            bool matchBrand = _selectedBrand == null || p.brand.toLowerCase() == _selectedBrand!.toLowerCase();
            bool matchSearch = p.name.toLowerCase().contains(_searchQuery);
            return matchCat && matchBrand && matchSearch;
          }).toList();

          if (_selectedSort == 'giathap') filtered.sort((a, b) => a.price.compareTo(b.price));
          else if (_selectedSort == 'giacao') filtered.sort((a, b) => b.price.compareTo(a.price));
          else if (_selectedSort == 'banchay') filtered.sort((a, b) => b.soldCount.compareTo(a.soldCount));

          if (filtered.isEmpty) return const Center(child: Text('Không tìm thấy sản phẩm nào'));

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 0.66, mainAxisSpacing: 14, crossAxisSpacing: 14,
            ),
            itemCount: filtered.length,
            itemBuilder: (_, index) => _buildProductCard(filtered[index]),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final isFav = _favoriteProductIds.contains(product.id);
    return GestureDetector(
      onTap: () => _openProductDetail(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity, margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(14)),
                    child: Hero(
                      tag: product.id,
                      child: ProductModel.isNetworkImageUrl(product.imageUrl)
                        ? StorageNetworkImage(url: product.imageUrl, fit: BoxFit.contain)
                        : Image.asset(ProductModel.normalizeLocalAssetPath(product.imageUrl), fit: BoxFit.contain),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(product.brand, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(formatPrice(product.price), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                          InkWell(
                            onTap: () {
                              // LOGIC CHECK STOCK CỦA MINHBVHE
                              if (product.getTotalStock() <= 0) {
                                _showTopNotice('Sản phẩm đã hết hàng!', Icons.error_outline, Colors.orange);
                                return;
                              }
                              final size = product.sizesStock.entries.firstWhere((e) => e.value > 0).key.toString();
                              _cartService.addItem(product, size);
                              setState(() {});
                              _showTopNotice('Đã thêm vào giỏ hàng', Icons.check_circle, Colors.green);
                            },
                            child: Icon(Icons.add_circle, color: Colors.blue.shade600, size: 22),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 10, right: 10,
              child: InkWell(
                onTap: () => setState(() => isFav ? _favoriteProductIds.remove(product.id) : _favoriteProductIds.add(product.id)),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.8),
                  radius: 16,
                  child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.grey, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          _buildNavItem(0, Icons.home, () => setState(() => _selectedNavIndex = 0)),
          _buildNavItem(1, Icons.shopping_cart, _openCartScreen, badgeCount: _cartService.getTotalItems()),
          _buildNavItem(2, Icons.person, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, VoidCallback onTap, {int badgeCount = 0}) {
    final isSel = _selectedNavIndex == index;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: isSel ? Colors.blue : Colors.grey, size: 26),
                  if (badgeCount > 0) Positioned(right: -8, top: -8, child: _buildCountBadge(badgeCount)),
                ],
              ),
              const SizedBox(height: 4),
              if (isSel) Container(width: 20, height: 3, decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(10))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty) ? NetworkImage(_avatarUrl!) : null,
              child: (_avatarUrl == null || _avatarUrl!.isEmpty) ? const Icon(Icons.person, size: 40, color: Colors.blue) : null,
            ),
            accountName: Text(_displayName ?? "Khách hàng", style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(currentUser?.email ?? ""),
          ),
          ListTile(leading: const Icon(Icons.home_outlined), title: const Text("Trang chủ"), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.history), title: const Text("Lịch sử đơn hàng"), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())); }),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Đăng xuất"), onTap: _handleLogout),
        ],
      ),
    );
  }
}