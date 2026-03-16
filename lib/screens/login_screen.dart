import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      final user = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        // Lấy thông tin từ Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();
        final data = userDoc.data();
        final String role = data?["role"] ?? "customer";

        // Chỉ chặn nếu tài khoản được đánh dấu cần xác thực email
        // (flag này chỉ được set với customer mới đăng ký)
        final bool needsVerification =
            data?["requireEmailVerification"] == true && !user.emailVerified;

        if (needsVerification) {
          await _authService.logout();
          if (!mounted) return;
          setState(() => _isLoading = false);

          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              icon: const Icon(Icons.mark_email_unread_outlined,
                  size: 40, color: Colors.orange),
              title: const Text("Email chưa xác thực"),
              content: const Text(
                "Vui lòng kiểm tra hộp thư và bấm vào link xác thực trước khi đăng nhập.\n\n"
                "Bạn có muốn gửi lại email xác thực không?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Đóng"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final tempUser = await _authService.signIn(
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                      );
                      await tempUser?.sendEmailVerification();
                      await _authService.logout();
                      messenger.showSnackBar(
                        const SnackBar(
                            content: Text("Đã gửi lại email xác thực")),
                      );
                    } catch (_) {}
                  },
                  child: const Text("Gửi lại"),
                ),
              ],
            ),
          );
          return;
        }

        if (!mounted) return;

        // Xóa flag requireEmailVerification nếu đã xác thực thành công
        if (user.emailVerified && data?["requireEmailVerification"] == true) {
          await FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .update({"requireEmailVerification": false});
        }

        if (!mounted) return;

        if (role == "admin") {
          Navigator.pushReplacementNamed(context, "/admin");
        } else {
          Navigator.pushReplacementNamed(context, "/home");
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đăng nhập thất bại: $e")),
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "SHOE SHOP",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Mật khẩu"),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Đăng nhập"),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterScreen(),
                  ),
                ),
                child: const Text("Chưa có tài khoản? Đăng ký"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}