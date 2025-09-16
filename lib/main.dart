import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // ❌ ลบออก
import 'login&register_page/loginpage.dart';
import '../database/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ เพิ่ม
import 'bar_icon/homepage.dart'; // ✅ import HomePage

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ❌ ไม่ใช้ prefs แล้ว
  // final prefs = await SharedPreferences.getInstance();
  // final loggedIn = prefs.getBool('logged_in') ?? false;

  // ✅ ใช้ FirebaseAuth เช็คสถานะ
  final startHome = FirebaseAuth.instance.currentUser != null;

  runApp(MyApp(startHome: startHome)); // เหมือนเดิม
}

class MyApp extends StatelessWidget {
  final bool startHome;
  const MyApp({super.key, required this.startHome});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cenima App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // ✅ เลือกหน้าโดยดูจาก FirebaseAuth
      home: startHome ? const HomePage() : const Loginpage(),
    );
  }
}
