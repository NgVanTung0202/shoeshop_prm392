import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// Import các màn hình trong project của bạn
import 'screens/login_screen.dart';
import 'screens/admin_products_screen.dart';
import 'screens/customer_home_screen.dart'; // Đảm bảo bạn đã tạo file này

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shoe Shop',
      // Theme chung cho toàn bộ App (Tone Blue - White)
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      // Logic kiểm tra trạng thái đăng nhập và phân quyền
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. Nếu chưa đăng nhập -> Chuyển đến màn hình Login
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (!snapshot.hasData) {
            return const LoginScreen();
          }

          // 2. Nếu đã đăng nhập -> Kiểm tra Role (admin/customer) trong Firestore
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // Kiểm tra xem dữ liệu User có tồn tại trên Firestore không
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                var userData = userSnapshot.data!.data() as Map<String, dynamic>;

                // --- PHÂN QUYỀN NGƯỜI DÙNG ---
                if (userData['role'] == 'admin') {
                  // Nếu là Admin -> Vào trang quản trị
                  return const AdminProductsScreen();
                } else {
                  // Nếu là Customer -> Vào trang chủ khách hàng (Màu Blue-White)
                  return const CustomerHomeScreen();
                }
              }

              // Trường hợp đã login nhưng không tìm thấy thông tin trong Firestore collection 'users'
              // Thường xảy ra khi bạn tạo User bằng Auth nhưng chưa kịp set dữ liệu vào DB
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Không tìm thấy thông tin tài khoản!"),
                      TextButton(
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        child: const Text("Đăng xuất và thử lại"),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}