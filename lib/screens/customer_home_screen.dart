import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
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
  String? _selectedBrand;
  String _searchQuery = '';
  int _selectedNavIndex = 0;
  String _selectedSort = 'phobien';
  final Set<String> _favoriteProductIds = <String>{};

  int _currentBannerIndex = 0;
  final PageController _pageController = PageController();
  Timer? _bannerTimer;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  // Badge dùng chung cho icon (giỏ hàng, yêu thích)
  Widget _buildCountBadge(
    int count, {
    Color backgroundColor = Colors.red,
    Color textColor = Colors.white,
  }) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

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

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageController.dispose();
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.25),
                    ),
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
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
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
    ).then((_) {
      alreadyClosed = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || alreadyClosed) return;
    if (navigator.canPop()) {
      navigator.pop();
    }
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 22,
                      ),
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
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
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
    ).then((_) {
      alreadyClosed = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || alreadyClosed) return;
    if (navigator.canPop()) {
      navigator.pop();
    }
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
              currentUser?.email?.split('@')[0] ?? 'Khách hàng',
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
            _buildBannerSlider(),
            const SizedBox(height: 10),
            _buildBrandList(), // Fix: Add Brand UI
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

  Drawer _buildDrawer() {

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
            leading: const Icon(Icons.category, color: Colors.blue),
            title: const Text("Bộ sưu tập hãng (Brands)"),
            onTap: () {
              Navigator.pop(context); // Đóng drawer
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
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
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

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _startBannerTimer();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _currentBannerIndex + 1;
        if (nextPage >= 5) { // We have 5 banners (banner1 -> banner5)
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

  // Nút yêu thích trên AppBar với badge số lượng
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
            final msg =
                hasFavorites
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

  Widget _buildBannerSlider() {
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          _currentBannerIndex = index;
        },
        itemCount: 5,
        itemBuilder: (context, index) {
          // Because assets/banner/ contains banner1.png through banner5.png
          final bannerNumber = index + 1;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assets/banner/banner$bannerNumber.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.blue.shade100,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image, size: 50, color: Colors.blue),
                  );
                },
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          final brands = snapshot.data ?? [];
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildBrandChip(label: 'All Brands', value: null),
              ...brands.map((b) => _buildBrandChip(label: b, value: b)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBrandChip({required String label, String? value}) {
    final bool isSelected = _selectedBrand == value;
    final chipColor = Colors.orange; // Để phân biệt với màu xanh của Category

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBrand = value;
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
    if (label.toLowerCase() == 'all') {
      return Colors.blue;
    }

    const palette = <Color>[
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
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
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Text(
                            'Sắp xếp theo',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...sortOptions.entries.map((entry) {
                          final isSelected = entry.key == _selectedSort;
                          return ListTile(
                            title: Text(
                              entry.value,
                              style: TextStyle(
                                color: isSelected ? Colors.blue : Colors.black,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                            onTap: () {
                              setState(() {
                                _selectedSort = entry.key;
                              });
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
                Text(
                  sortOptions[_selectedSort] ?? 'Sắp xếp',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
                ),
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

          if (snapshot.hasError) {
            return const Center(child: Text('Không thể tải sản phẩm'));
          }

          final List<ProductModel> loadedProducts = snapshot.data ?? <ProductModel>[];
          final List<ProductModel> products = List<ProductModel>.from(loadedProducts);

          final List<ProductModel> filteredProducts =
              products.where((product) {
                // 1. Lọc theo Category ID (KHÔNG dùng name hoặc brand nữa)
                bool matchCategory = _selectedCategoryId == null || product.categoryId == _selectedCategoryId;

                // 2. Lọc theo Hãng (Brand)
                bool matchBrand = _selectedBrand == null || product.brand.toUpperCase() == _selectedBrand?.toUpperCase();

                // 3. Lọc theo Search Query
                bool matchSearch = true;
                if (_searchQuery.isNotEmpty) {
                  final String name = product.name.toLowerCase();
                  matchSearch = name.contains(_searchQuery);
                }

                return matchCategory && matchBrand && matchSearch;
              }).toList();

          if (_selectedSort == 'giathap') {
            filteredProducts.sort((a, b) => a.price.compareTo(b.price));
          } else if (_selectedSort == 'giacao') {
            filteredProducts.sort((a, b) => b.price.compareTo(a.price));
          } else if (_selectedSort == 'danhgia') {
            filteredProducts.sort((a, b) => b.rating.compareTo(a.rating));
          } else if (_selectedSort == 'banchay') {
            filteredProducts.sort((a, b) => b.soldCount.compareTo(a.soldCount));
          } else if (_selectedSort == 'phobien') {
            // Default, maybe just id sorting or default fetch order
          }

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
    final isFavorite = _favoriteProductIds.contains(product.id);

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
        child: Stack(
          children: [
            Column(
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
                      child: product.imageUrl.startsWith('http')
                          ? Image.network(
                              product.imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey,
                              ),
                            )
                          : Image.asset(
                              product.imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
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
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (product.discountPercent > 0)
                                  Text(
                                    formatPrice(product.price * 100 / (100 - product.discountPercent)),
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                Text(
                                  formatPrice(product.price),
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              if (product.getTotalStock() <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sản phẩm đã hết hàng, chuyển đến trang chi tiết...'),
                                  ),
                                );
                                _openProductDetail(product);
                                return;
                              }

                              final inStock = product.sizesStock.entries
                                  .where((e) => e.value > 0)
                                  .toList();
                              final size =
                                  (inStock.isNotEmpty
                                          ? inStock.first.key
                                          : product.sizesStock.entries.first.key)
                                      .toString();

                              _cartService.addItem(product, size);
                              setState(() {});
                              _showTopCartNotice(
                                'Đã thêm sản phẩm vào giỏ hàng',
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.add_circle,
                                color: Colors.blue.shade600,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 3),
                          Text('${product.rating.toStringAsFixed(1)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          Text(' (${product.reviewCount})', style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '-${product.discountPercent}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 10,
              right: 10,
              child: Material(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    setState(() {
                      if (isFavorite) {
                        _favoriteProductIds.remove(product.id);
                      } else {
                        _favoriteProductIds.add(product.id);
                      }
                    });

                    if (!isFavorite) {
                      _showTopFavoriteNotice('Đã thêm sản phẩm vào yêu thích');
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
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
    final unselectedColor = Colors.grey.shade500;

    Widget buildItem({
      required int index,
      required IconData icon,
      required VoidCallback onTap,
      int badgeCount = 0,
    }) {
      final isSelected = _selectedNavIndex == index;

      return Expanded(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 30,
                  height: 26,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Icon(
                          icon,
                          size: 26,
                          color: isSelected ? selectedColor : unselectedColor,
                        ),
                      ),
                      if (badgeCount > 0)
                        Positioned(
                          right: -6,
                          top: -8,
                          child: _buildCountBadge(
                            badgeCount,
                            backgroundColor: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 3,
                  decoration: BoxDecoration(
                    color: isSelected ? selectedColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            buildItem(
              index: 0,
              icon: Icons.home_outlined,
              onTap: () {
                setState(() => _selectedNavIndex = 0);
              },
            ),
            buildItem(
              index: 1,
              icon: Icons.shopping_cart_outlined,
              badgeCount: _cartService.getTotalItems(),
              onTap: () async {
                setState(() => _selectedNavIndex = 1);
                await _openCartScreen();
                if (!mounted) return;
                setState(() => _selectedNavIndex = 0);
              },
            ),
            buildItem(
              index: 2,
              icon: Icons.person_outline,
              onTap: () async {
                setState(() => _selectedNavIndex = 2);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
                if (!mounted) return;
                setState(() => _selectedNavIndex = 0);
              },
            ),
          ],
        ),
      ),
    );
  }

}