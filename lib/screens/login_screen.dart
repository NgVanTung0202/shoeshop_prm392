import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/db_seeder.dart';
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

  void _handleLogin() async {
    try {
      await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sai email hoặc mật khẩu!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
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
                    onPressed: _handleLogin,
                    child: const Text("Đăng nhập", style: TextStyle(fontSize: 18))),
              ),

              const SizedBox(height: 10),


              // TextButton.icon(
              //   onPressed: () async {
              //     await DbSeeder.seedAll();
              //     if (mounted) {
              //       ScaffoldMessenger.of(context).showSnackBar(
              //         const SnackBar(content: Text("Dữ liệu đã lên Firebase!")),
              //       );
              //     }
              //   },
              //   icon: const Icon(Icons.storage, color: Colors.orange),
              //   label: const Text("Khởi tạo dữ liệu mẫu (Seed Data)",
              //       style: TextStyle(color: Colors.orange)),
              // ),

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
    );
  }
}