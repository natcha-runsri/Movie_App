// authenticationService.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ================== Public getters / streams ==================
  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;
  String? get currentEmail => _auth.currentUser?.email;
  bool get isLoggedIn => _auth.currentUser != null;
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // ================== Private helpers ==================
  Future<void> _persistUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logged_in', true);
    await prefs.setString('uid', user.uid);
    if (user.email != null) {
      await prefs.setString('email', user.email!);
    }
  }

  Future<void> _clearPersistedUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_in');
    await prefs.remove('uid');
    await prefs.remove('email');

    print('✅ SharedPreferences ถูกเคลียร์แล้ว');
  }

  // ================== Auth APIs ==================
  Future<bool> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = userCredential.user;
      if (user == null) return false;

      await _persistUser(user); // ✅ เก็บ UID/Email ลง SharedPreferences
      return true;
    } catch (e) {
      // print('login error: $e');
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = userCredential.user;
      if (user == null) return false;

      await _persistUser(user); // ✅ เก็บ UID/Email ลง SharedPreferences
      return true;
    } catch (e) {
      // print('register error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } finally {
      await _clearPersistedUser(); // ✅ เคลียร์ค่าที่เก็บไว้ในเครื่อง
    }
  }

  // ถ้าต้องการเช็คจากเครื่องล้วน ๆ (เช่นตอน boot ก่อน Firebase init เสร็จ)
  Future<bool> isAuthenticatedLocal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('logged_in') == true && prefs.getString('uid') != null;
  }

}
