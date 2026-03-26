import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'admin_products_screen.dart';

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
  bool _obscurePassword = true; // 👁️ thêm dòng này

  String _loginErrorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'wrong-password':
          return 'Sai mật khẩu. Vui lòng thử lại.';
        case 'user-not-found':
          return 'Không tìm thấy tài khoản với email này.';
        case 'invalid-email':
          return 'Email không hợp lệ.';
        case 'user-disabled':
          return 'Tài khoản đã bị vô hiệu hóa.';
        case 'too-many-requests':
          return 'Bạn thử quá nhiều lần. Vui lòng đợi và thử lại.';
        case 'network-request-failed':
          return 'Lỗi kết nối mạng. Vui lòng kiểm tra Internet.';
        case 'invalid-credential':
          // Firebase mới thường trả code này khi email/mật khẩu sai
          return 'Email hoặc mật khẩu không đúng.';
      }
      final msg = (e.message ?? '').trim();
      if (msg.isNotEmpty) return msg;
      return 'Đăng nhập thất bại. Vui lòng thử lại.';
    }
    if (e is PlatformException) {
      if (e.code == 'sign_in_failed' &&
          (e.message?.contains('ApiException: 10') ?? false)) {
        return 'Google Sign-In chưa cấu hình đúng (SHA-1/SHA-256 hoặc google-services.json).';
      }
      final platformMsg = (e.message ?? '').trim();
      if (platformMsg.isNotEmpty) return platformMsg;
    }
    final msg = e.toString().replaceFirst('Exception: ', '').trim();
    if (msg.isNotEmpty) return msg;
    return 'Đăng nhập thất bại. Vui lòng thử lại.';
  }

  Future<void> _handleLoginSuccess(User user) async {
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final data = userDoc.data();
    final String role = data?["role"] ?? "customer";

    final bool needsVerification =
        data?["requireEmailVerification"] == true && !user.emailVerified;

    if (needsVerification) {
      await _authService.logout();
      if (!mounted) return;
      setState(() => _isLoading = false);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(
            Icons.mark_email_unread_outlined,
            size: 40,
            color: Colors.orange,
          ),
          title: const Text("Email chưa xác thực"),
          content: const Text(
            "Vui lòng kiểm tra hộp thư và xác thực trước khi đăng nhập.\n\nBạn có muốn gửi lại email không?",
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
                      content: Text("Đã gửi lại email xác thực"),
                    ),
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

    if (user.emailVerified && data?["requireEmailVerification"] == true) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .update({"requireEmailVerification": false});
    }

    if (!mounted) return;

    if (role == "admin") {
      Navigator.pushReplacementNamed(context, "/admin");
    } else if (role == "staff") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminProductsScreen()),
      );
    } else {
      Navigator.pushReplacementNamed(context, "/home");
    }
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      final user = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        await _handleLoginSuccess(user);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_loginErrorMessage(e))),
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        await _handleLoginSuccess(user);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_loginErrorMessage(e))),
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_bag,
                          size: 60, color: Colors.blue),
                      const SizedBox(height: 10),

                      const Text(
                        "SHOE SHOP",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 30),

                      /// EMAIL
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email),
                          labelText: "Email",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      /// PASSWORD 👁️
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock),
                          labelText: "Mật khẩu",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// FORGOT PASSWORD LINK
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ForgotPasswordScreen(),
                            ),
                          ),
                          child: const Text(
                            'Quên mật khẩu?',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 13),

                      /// BUTTON LOGIN
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.blue,
                          ),
                          onPressed:
                              _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Đăng nhập",
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleGoogleLogin,
                          icon: const Icon(Icons.g_mobiledata, size: 24),
                          label: const Text("Đăng nhập với Google"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// REGISTER
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const RegisterScreen(),
                          ),
                        ),
                        child: const Text(
                          "Chưa có tài khoản? Đăng ký",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}