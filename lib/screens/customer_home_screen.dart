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
            _buildCategoryList(),
            const SizedBox(height: 10),
            _buildProductGrid(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
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

          // Lọc trùng danh mục theo tên (không phân biệt hoa thường)
          final seenNames = <String>{};
          final uniqueCategories = <CategoryModel>[];
          for (final category in categories) {
            final name = category.name.trim();
            if (name.isEmpty) continue;
            final key = name.toLowerCase();
            if (seenNames.add(key)) {
              uniqueCategories.add(category);
            }
          }

          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCategoryChip(label: 'All', value: null),
              ...uniqueCategories.map(
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
    final chipColor = _chipColorForLabel(label);

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
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              formatPrice(product.price),
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              if (product.sizesStock.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sản phẩm đã hết hàng'),
                                  ),
                                );
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
                    ],
                  ),
                ),
              ],
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
}