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


  final startHome = FirebaseAuth.instance.currentUser != null; //เช็คว่าล็อคอินไว้อยู่มั้ย


  runApp(MyApp(startHome: startHome)); // รันแอพแล้วส่งค่าว่า ล็อคอินอยู่รึป่าวเข้าไปด้วย
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
      home: startHome ? const HomePage() : const Loginpage(), // เช็คว่าควรไปหน้าไหน
    );
  }
}
