import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    // Validation cơ bản
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng điền đầy đủ thông tin")),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mật khẩu xác nhận không khớp")),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mật khẩu phải có ít nhất 6 ký tự")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // signUp tự detect: nhân viên pre-created hay khách hàng mới
      final user = await _authService.signUp(email, password, name);

      if (!mounted) return;

      // Kiểm tra Firestore xem có phải staff không
      bool isStaff = false;
      if (user != null) {
        // Vì đã signOut, kiểm tra qua email
        final snap = await FirebaseFirestore.instance
            .collection("users")
            .where("email", isEqualTo: email)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          final role = snap.docs.first.data()["role"] ?? "customer";
          isStaff = role == "staff" || role == "admin";
        }
      }

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: Icon(
            isStaff ? Icons.badge_outlined : Icons.mark_email_unread_outlined,
            size: 48,
            color: Colors.blue,
          ),
          title: Text(isStaff ? "Đăng ký thành công" : "Xác thực email"),
          content: Text(
            isStaff
                ? "Tài khoản nhân viên của bạn đã được kích hoạt.\nBạn có thể đăng nhập ngay bây giờ."
                : "Chúng tôi đã gửi email xác thực đến\n$email\n\n"
                    "Vui lòng kiểm tra hộp thư và bấm vào link xác thực trước khi đăng nhập.",
            textAlign: TextAlign.center,
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Đã hiểu"),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.pop(context); // Về màn hình Login
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      String errorMsg = "Lỗi đăng ký";
      final msg = e.toString();
      if (msg.contains("email-already-in-use")) {
        errorMsg = "Email này đã được sử dụng";
      } else if (msg.contains("invalid-email")) {
        errorMsg = "Email không hợp lệ";
      } else if (msg.contains("weak-password")) {
        errorMsg = "Mật khẩu quá yếu";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
      return;
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký thành viên")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Họ và tên",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: "Mật khẩu",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: "Xác nhận mật khẩu",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _handleRegister,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Đăng ký ngay",
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}