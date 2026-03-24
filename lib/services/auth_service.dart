import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Đăng ký cho KHÁCH HÀNG — gửi email xác thực, đăng xuất ngay
  /// Nếu email đã được admin tạo sẵn (pendingAuth=true) → gán role đúng, không gửi email xác thực
  Future<User?> signUp(
      String email,
      String password,
      String name) async {

    // Kiểm tra xem email có phải nhân viên được admin tạo sẵn không
    final existingSnap = await _db
        .collection("users")
        .where("email", isEqualTo: email)
        .where("pendingAuth", isEqualTo: true)
        .limit(1)
        .get();

    final bool isPreCreatedStaff = existingSnap.docs.isNotEmpty;

    UserCredential credential =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (isPreCreatedStaff) {
      // Nhân viên được admin tạo sẵn: cập nhật doc cũ với uid Auth mới
      final oldDoc = existingSnap.docs.first;
      final oldData = oldDoc.data();

      await _db.collection("users").doc(credential.user!.uid).set({
        "email": email,
        "name": oldData["name"] ?? name,
        "phone": oldData["phone"] ?? "",
        "role": oldData["role"] ?? "staff",
        "createdAt": oldData["createdAt"] ?? Timestamp.now(),
      });

      // Xóa doc cũ (pendingAuth)
      await _db.collection("users").doc(oldDoc.id).delete();

      // Nhân viên KHÔNG cần xác thực email, đăng xuất để đăng nhập lại bình thường
      await _auth.signOut();
    } else {
      // Khách hàng thông thường
      await credential.user!.sendEmailVerification();

      await _db.collection("users").doc(credential.user!.uid).set({
        "email": email,
        "name": name,
        "role": "customer",
        "createdAt": Timestamp.now(),
      });

      // Đăng xuất ngay — bắt buộc xác thực email trước khi dùng app
      await _auth.signOut();
    }

    return credential.user;
  }

  /// Admin tạo tài khoản NHÂN VIÊN — chỉ lưu Firestore (không tạo Auth)
  /// Nhân viên sẽ dùng email này để tự đăng ký tài khoản Auth sau
  /// Khi đăng ký, hệ thống sẽ nhận ra email và gán đúng role từ Firestore
  Future<void> createStaffRecord({
    required String email,
    required String name,
    required String phone,
    required String role,
  }) async {
    // Kiểm tra email đã tồn tại trong Firestore chưa
    final existing = await _db
        .collection("users")
        .where("email", isEqualTo: email)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception("Email này đã tồn tại trong hệ thống");
    }

    await _db.collection("users").add({
      "email": email,
      "name": name,
      "phone": phone,
      "role": role,
      "createdAt": Timestamp.now(),
      "pendingAuth": true, // đánh dấu chưa có tài khoản Auth
    });
  }

  Future<User?> signIn(
      String email,
      String password) async {

    UserCredential credential =
        await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Kiểm tra user có active không (chưa bị xóa)
    if (credential.user != null) {
      try {
        final userDoc = await _db
            .collection("users")
            .doc(credential.user!.uid)
            .get();

        if (userDoc.exists) {
          final isActive = userDoc.data()?["isActive"] ?? true;

          if (!isActive) {
            await _auth.signOut();
            throw Exception(
              "Tài khoản này đã bị vô hiệu hóa. Vui lòng liên hệ admin.",
            );
          }
        }
      } catch (e) {
        if (e.toString().contains("vô hiệu hóa")) {
          rethrow;
        }
        // Nếu document không tồn tại, tạo mới (cho Firebase Auth user cũ)
        await _db.collection("users").doc(credential.user!.uid).set({
          "email": credential.user!.email,
          "isActive": true,
          "createdAt": Timestamp.now(),
        }, SetOptions(merge: true));
      }
    }

    return credential.user;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Gửi email đặt lại mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}