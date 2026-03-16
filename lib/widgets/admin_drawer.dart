import 'package:flutter/material.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/admin_products_screen.dart';
import '../screens/admin_category_screen.dart';

enum AdminMenuItem { dashboard, products, categories, other }

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

            ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.blue),
              title: const Text("Tổng quan"),
              selected: selected == AdminMenuItem.dashboard,
              selectedColor: Colors.blue,
              onTap: () {
                Navigator.pop(context);

                if (selected != AdminMenuItem.dashboard) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminDashboardScreen(),
                    ),
                  );
                }
              },
            ),

            ListTile(
              leading: const Icon(Icons.inventory_2, color: Colors.blue),
              title: const Text("Quản lý sản phẩm"),
              selected: selected == AdminMenuItem.products,
              selectedColor: Colors.blue,
              onTap: () {
                Navigator.pop(context);

                if (selected != AdminMenuItem.products) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminProductsScreen(),
                    ),
                  );
                }
              },
            ),

            ListTile(
              leading: const Icon(Icons.category, color: Colors.blue),
              title: const Text("Quản lý danh mục sản phẩm"),
              selected: selected == AdminMenuItem.categories,
              selectedColor: Colors.blue,
              onTap: () {
                Navigator.pop(context);

                if (selected != AdminMenuItem.categories) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminCategoryScreen(),
                    ),
                  );
                }
              },
            ),

            ListTile(
              leading: const Icon(Icons.more_horiz, color: Colors.blue),
              title: const Text("Khác"),
              selected: selected == AdminMenuItem.other,
              selectedColor: Colors.blue,
              onTap: () {
                Navigator.pop(context);
              },
            ),

            const Spacer(),
            const Divider(height: 1),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Đăng xuất"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
