import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Đăng ký (UC01)
  Future<User?> signUp(String email, String password, String fullName) async {
    UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    User? user = result.user;

    if (user != null) {
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'fullName': fullName,
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return user;
  }

  // Đăng nhập (UC02)
  Future<User?> signIn(String email, String password) async {
    UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return result.user;
  }

  // Đăng xuất (UC03)
  Future<void> signOut() async => await _auth.signOut();
}