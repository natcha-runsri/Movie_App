import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'MorePage.dart';
import 'MoviesPage.dart';
import 'PromotionPage.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  String _getUidSafe() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("ไม่พบผู้ใช้ที่ล็อกอิน");
      }
      return user.uid;
    } catch (e) {
      return "เกิดข้อผิดพลาด: $e";
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _getUidSafe();

    return Scaffold(
      appBar: AppBar(
        title: const Text('หน้าหลัก'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome to Home Page!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'UID:',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              uid,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color:
                    uid.startsWith("เกิดข้อผิดพลาด") ? Colors.red : Colors.blue,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.yellow,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        currentIndex: 0, // ระบุตำแหน่งปัจจุบัน
        selectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.movie_filter),
            label: 'Movies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Gift',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'More'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomePage()),
            );
          }
          ;
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => Moviespage()),
            );
          }
          ;
          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => Promotionpage()),
            );
          }
          ;
          if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => Morepage()),
            );
          }
          ;
        },
      ),
    );
  }
}
