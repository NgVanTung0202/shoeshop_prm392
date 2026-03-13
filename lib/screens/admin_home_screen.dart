import 'package:flutter/material.dart';
import '../widgets/admin_drawer.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  final List<String> _pageTitles = const [
    "Tổng quan",
    "Quản lý sản phẩm",
    "Quản lý danh mục sản phẩm",
    "Khác",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Trang quản trị",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
      ),
      drawer: const AdminDrawer(selected: AdminMenuItem.dashboard),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _selectedIndex == 0
                    ? Icons.dashboard
                    : _selectedIndex == 1
                        ? Icons.inventory_2
                        : _selectedIndex == 2
                            ? Icons.category
                            : Icons.more_horiz,
                size: 60,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                _pageTitles[_selectedIndex],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Nội dung trang quản lý sẽ được xây dựng sau.",
                style: TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}