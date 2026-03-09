import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Thêm cái này để đọc DB
import '../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      // 1. Thực hiện đăng nhập
      final currentUser = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (currentUser != null && mounted) {
        // 2. Lấy UID trực tiếp từ currentUser
        String uid = currentUser.uid;

        // 3. Truy vấn Firestore để lấy Role
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();



        if (userDoc.exists && mounted) {
          String role = userDoc.get('role'); // Lấy trường 'role' trong Firestore

          // 4. ĐIỀU HƯỚNG THEO ROLE
          if (role == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin');
          } else if (role == 'staff') {
            // Navigator.pushReplacementNamed(context, '/staff_home');
            // Bạn cần định nghĩa route này trong main.dart nếu có trang riêng cho Staff
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chào Staff!")));
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            // Mặc định là customer
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          throw Exception("Không tìm thấy dữ liệu người dùng!");
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Center( // Để nội dung vào giữa
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text("SHOE SHOP",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                const SizedBox(height: 40),
                TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
                const SizedBox(height: 15),
                TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: "Mật khẩu", border: OutlineInputBorder()),
                    obscureText: true),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Đăng nhập", style: TextStyle(fontSize: 18))),
                ),

                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                  child: const Text("Chưa có tài khoản? Đăng ký tại đây"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}