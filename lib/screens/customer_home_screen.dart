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
import 'brand_shoes_screen.dart';
import '../data/shoe_data.dart';
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
  String? _selectedCategoryName;
  String _searchQuery = '';
  int _selectedNavIndex = 0;
  String _selectedSort = 'phobien';
  final Set<String> _favoriteProductIds = <String>{};

  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
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
    _searchController.dispose();
    super.dispose();
  }

  // Badge dùng chung cho icon (giỏ hàng, yêu thích)
  Widget _buildCountBadge(
    int count, {
    Color backgroundColor = Colors.red,
    Color textColor = Colors.white,
  }) {
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
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }

  // Thông báo top cho YÊU THÍCH (màu đỏ)
  Future<void> _showTopFavoriteNotice(String message) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    bool alreadyClosed = false;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'favorite_notice',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, __, ___) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.35),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ).then((_) => alreadyClosed = true);

    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || alreadyClosed) return;
    if (navigator.canPop()) navigator.pop();
  }

  // Thông báo top cho GIỎ HÀNG (màu xanh)
  Future<void> _showTopCartNotice(String message) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    bool alreadyClosed = false;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'cart_notice',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, __, ___) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.35),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ).then((_) => alreadyClosed = true);

    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || alreadyClosed) return;
    if (navigator.canPop()) navigator.pop();
  }

  Future<void> _openCartScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openProductDetail(ProductModel product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
    if (!mounted) return;
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chào mừng bạn,',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            Text(
              _displayName?.isNotEmpty == true 
                  ? _displayName! 
                  : (currentUser?.email?.split('@')[0] ?? 'Khách hàng'),
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
        actions: [_buildFavoriteIcon(), const SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildCategoryList(),
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

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                  ? NetworkImage(_avatarUrl!)
                  : null,
              child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 40, color: Colors.blue)
                  : null,
            ),
            accountName: Text(
              _displayName?.isNotEmpty == true
                  ? _displayName!
                  : (currentUser?.email?.split('@')[0] ?? "Khách hàng"),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(currentUser?.email ?? "Chưa đăng nhập"),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined, color: Colors.blue),
            title: const Text("Trang chủ"),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.category, color: Colors.blue),
            title: const Text("Bộ sưu tập hãng (Brands)"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BrandShoesScreen(
                    onShoeSelected: (shoeName) {
                      setState(() {
                        _searchController.text = shoeName;
                        _searchQuery = shoeName.toLowerCase();
                      });
                    },
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.blue),
            title: const Text("Lịch sử đơn hàng"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.blue),
            title: const Text("Thông tin cá nhân"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ).then((_) => _loadUserInfo());
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.orange),
            title: const Text("Đổi mật khẩu"),
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
    );
  }

  Widget _buildFavoriteIcon() {
    final hasFavorites = _favoriteProductIds.isNotEmpty;
    final favoriteCount = _favoriteProductIds.length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            hasFavorites ? Icons.favorite : Icons.favorite_border,
            color: hasFavorites ? Colors.red : Colors.blue,
            size: 28,
          ),
          onPressed: () {
            final msg = hasFavorites
                ? 'Bạn có $favoriteCount sản phẩm yêu thích'
                : 'Chưa có sản phẩm yêu thích';
            _showTopFavoriteNotice(msg);
          },
        ),
        if (favoriteCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: _buildCountBadge(favoriteCount, backgroundColor: Colors.red),
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
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
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
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          final List<CategoryModel> categories = snapshot.data ?? <CategoryModel>[];
          final seenNames = <String>{};
          final uniqueCategories = <CategoryModel>[];
          for (final category in categories) {
            final name = category.name.trim();
            if (name.isEmpty) continue;
            if (seenNames.add(name.toLowerCase())) {
              uniqueCategories.add(category);
            }
          }

          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCategoryChip(label: 'All', value: null),
              ...uniqueCategories.map(
                (category) => _buildCategoryChip(label: category.name, value: category.id),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip({required String label, String? value}) {
    final bool isSelected = _selectedCategoryId == value;
    final chipColor = _chipColorForLabel(label);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryId = value;
          _selectedCategoryName = label == 'All' ? null : label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : chipColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? chipColor : chipColor.withOpacity(0.35),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : chipColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Color _chipColorForLabel(String label) {
    if (label.toLowerCase() == 'all') return Colors.blue;
    const palette = <Color>[
      Colors.blue, Colors.green, Colors.orange, Colors.purple,
      Colors.teal, Colors.indigo, Colors.pink,
    ];
    return palette[label.hashCode.abs() % palette.length];
  }

  Widget _buildSortDropdown() {
    final Map<String, String> sortOptions = {
      'phobien': 'Phổ biến',
      'giathap': 'Giá thấp đến cao',
      'giacao': 'Giá cao đến thấp',
      'danhgia': 'Nhiều đánh giá tốt',
      'banchay': 'Bán chạy',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Tất cả sản phẩm',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Sắp xếp theo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        ...sortOptions.entries.map((entry) {
                          final isSelected = entry.key == _selectedSort;
                          return ListTile(
                            title: Text(entry.value, style: TextStyle(
                              color: isSelected ? Colors.blue : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            )),
                            trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                            onTap: () {
                              setState(() => _selectedSort = entry.key);
                              Navigator.pop(context);
                            },
                          );
                        }),
                      ],
                    ),
                  );
                },
              );
            },
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

  Widget _buildProductGrid() {
    return Expanded(
      child: StreamBuilder<List<ProductModel>>(
        stream: _fs.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return const Center(child: Text('Không thể tải sản phẩm'));

          final List<ProductModel> products = List<ProductModel>.from(snapshot.data ?? []);
          
          final presetProducts = ShoeData.allShoes.map((shoe) {
            final disc = shoe.id.hashCode.abs() % 5 == 0 ? 15 + (shoe.id.hashCode.abs() % 4) * 5 : 0;
            return ProductModel(
              id: 'preset_${shoe.id}',
              name: shoe.name,
              brand: shoe.brand,
              price: 1500000.0 + (shoe.id.hashCode.abs() % 1000000),
              categoryId: 'preset_cat',
              imageUrl: ProductModel.getLocalImage(shoe.name, shoe.brand, 'preset_${shoe.id}'),
              description: 'Sản phẩm ${shoe.name} chính hãng từ ${shoe.brand}.',
              sizesStock: {'39': 10, '40': 15, '41': 20},
              discountPercent: disc,
              soldCount: shoe.id.hashCode.abs() % 300,
              rating: 4.0 + (shoe.id.hashCode.abs() % 10) / 10,
              reviewCount: (shoe.id.hashCode.abs() % 100) + 5,
            );
          }).toList();
          
          products.addAll(presetProducts);

          final List<ProductModel> filteredProducts = products.where((product) {
            bool matchCategory = true;
            if (_selectedCategoryId != null) {
              final catNameLower = _selectedCategoryName?.toLowerCase() ?? "";
              final isMajorBrand = ['nike', 'adidas', 'puma', 'vans', 'converse', 'boot'].contains(catNameLower);
              bool nameOrBrandMatch = product.brand.toLowerCase().contains(catNameLower) || product.name.toLowerCase().contains(catNameLower);
              
              matchCategory = isMajorBrand ? nameOrBrandMatch : (product.categoryId == _selectedCategoryId || nameOrBrandMatch);
            }
            final matchSearch = product.name.toLowerCase().contains(_searchQuery) || product.brand.toLowerCase().contains(_searchQuery);
            return matchCategory && matchSearch;
          }).toList();

          if (_selectedSort == 'giathap') filteredProducts.sort((a, b) => a.price.compareTo(b.price));
          else if (_selectedSort == 'giacao') filteredProducts.sort((a, b) => b.price.compareTo(a.price));
          else if (_selectedSort == 'danhgia') filteredProducts.sort((a, b) => b.rating.compareTo(a.rating));
          else if (_selectedSort == 'banchay') filteredProducts.sort((a, b) => b.soldCount.compareTo(a.soldCount));

          if (filteredProducts.isEmpty) {
            return Center(child: Text(_searchQuery.isNotEmpty ? "Không tìm thấy sản phẩm cho '$_searchQuery'" : "Chưa có sản phẩm"));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 0.66, mainAxisSpacing: 14, crossAxisSpacing: 14,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) => _buildProductCard(filteredProducts[index]),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final isFavorite = _favoriteProductIds.contains(product.id);

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
                    width: double.infinity, padding: const EdgeInsets.all(10), margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(14)),
                    child: Hero(
                      tag: product.id,
                      child: product.imageUrl.startsWith('http')
                          ? Image.network(product.imageUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined))
                          : Image.asset(product.imageUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined)),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (product.discountPercent > 0)
                                  Text(formatPrice(product.price * 100 / (100 - product.discountPercent)), style: TextStyle(color: Colors.grey.shade500, fontSize: 11, decoration: TextDecoration.lineThrough)),
                                Text(formatPrice(product.price), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              if (product.sizesStock.isEmpty) return;
                              final size = product.sizesStock.entries.firstWhere((e) => e.value > 0, orElse: () => product.sizesStock.entries.first).key.toString();
                              _cartService.addItem(product, size);
                              setState(() {});
                              _showTopCartNotice('Đã thêm sản phẩm vào giỏ hàng');
                            },
                            child: Icon(Icons.add_circle, color: Colors.blue.shade600, size: 22),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          Text(' ${product.rating.toStringAsFixed(1)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text('Đã bán: ${product.soldCount}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (product.discountPercent > 0)
              Positioned(
                top: 10, left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                  child: Text('-${product.discountPercent}%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            Positioned(
              top: 10, right: 10,
              child: InkWell(
                onTap: () {
                  setState(() => isFavorite ? _favoriteProductIds.remove(product.id) : _favoriteProductIds.add(product.id));
                  if (!isFavorite) _showTopFavoriteNotice('Đã thêm sản phẩm vào yêu thích');
                },
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.85),
                  radius: 16,
                  child: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.red : Colors.grey, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    final selectedColor = Theme.of(context).primaryColor;
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
        child: Row(
          children: [
            _buildNavItem(0, Icons.home_outlined, () => setState(() => _selectedNavIndex = 0)),
            _buildNavItem(1, Icons.shopping_cart_outlined, () async {
              setState(() => _selectedNavIndex = 1);
              await _openCartScreen();
              if (mounted) setState(() => _selectedNavIndex = 0);
            }, badgeCount: _cartService.getTotalItems()),
            _buildNavItem(2, Icons.person_outline, () async {
              setState(() => _selectedNavIndex = 2);
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              if (mounted) setState(() => _selectedNavIndex = 0);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, VoidCallback onTap, {int badgeCount = 0}) {
    final isSelected = _selectedNavIndex == index;
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
                  Icon(icon, color: isSelected ? Colors.blue : Colors.grey, size: 26),
                  if (badgeCount > 0) Positioned(right: -8, top: -8, child: _buildCountBadge(badgeCount)),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20, height: 3,
                decoration: BoxDecoration(color: isSelected ? Colors.blue : Colors.transparent, borderRadius: BorderRadius.circular(10)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}