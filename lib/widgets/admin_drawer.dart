import 'package:flutter/material.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/admin_products_screen.dart';
import '../screens/admin_category_screen.dart';
import '../screens/admin_users_screen.dart';
import '../services/auth_service.dart';

enum AdminMenuItem { dashboard, products, categories, users, orders, other }

class AdminDrawer extends StatelessWidget {
  final AdminMenuItem selected;

  const AdminDrawer({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Admin Panel",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Quản lý Shoe Shop",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.dashboard,
                    title: "Dashboard",
                    item: AdminMenuItem.dashboard,
                    onTap: () {
                      if (selected != AdminMenuItem.dashboard) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => AdminDashboardScreen()),
                        );
                      }
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.inventory_2,
                    title: "Sản phẩm",
                    item: AdminMenuItem.products,
                    onTap: () {
                      if (selected != AdminMenuItem.products) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminProductsScreen()),
                        );
                      }
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.category,
                    title: "Danh mục",
                    item: AdminMenuItem.categories,
                    onTap: () {
                      if (selected != AdminMenuItem.categories) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminCategoryScreen()),
                        );
                      }
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.people,
                    title: "Người dùng",
                    item: AdminMenuItem.users,
                    onTap: () {
                      if (selected != AdminMenuItem.users) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => AdminUsersScreen()),
                        );
                      }
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.shopping_cart,
                    title: "Đơn hàng",
                    item: AdminMenuItem.orders,
                    onTap: () {
                      if (selected != AdminMenuItem.orders) {
                        Navigator.pushReplacementNamed(context, '/admin_orders');
                      }
                    },
                  ),
                  const Divider(),
                  _buildMenuItem(
                    context,
                    icon: Icons.logout,
                    title: "Đăng xuất",
                    item: AdminMenuItem.other,
                    iconColor: Colors.red,
                    textColor: Colors.red,
                    onTap: () async {
                      await AuthService().logout();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required AdminMenuItem item,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final isSelected = selected == item;
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? (isSelected ? Colors.blue : Colors.grey.shade700),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? (isSelected ? Colors.blue : Colors.black87),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: Colors.blue,
      onTap: onTap,
    );
  }
}
