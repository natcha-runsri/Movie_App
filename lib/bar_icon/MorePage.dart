import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../login&register_page/loginpage.dart';
import '../database/authenticationService.dart'; // ✅ import AuthService
import 'homepage.dart';
import 'MoviesPage.dart';
import 'PromotionPage.dart';
import '../icon_more_detail/dev_.dart';
import '../icon_more_detail/contact.dart';
import '../icon_more_detail/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/auth_helpers.dart'; // ✅ import ฟังก์ชันช่วยเหลือ
import '../icon_more_detail/history.dart';

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Padding(
          padding: EdgeInsets.only(left: 0.5),
          child: Image(
            image: AssetImage('images/logo_movi.jpg'),
            height: 70,
            width: 70,
          ),
        ),
      ],
    );
  }
}

class Morepage extends StatelessWidget {
  const Morepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false, // เอาลูกศรย้อนกลับออก
        backgroundColor: Colors.black,
        elevation: 0,
        toolbarHeight: 100,
        titleSpacing: 16,
        title: Row(
          children: [
            const SizedBox(width: 10),
            const Text(
              'More',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 45,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            _Logo(),
            const SizedBox(width: 8),
          ],
        ),
        // เส้นแบ่งสีเทาบาง ๆ ด้านล่าง
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white12),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 70),
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title: const Text(
              'Account Management',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white),
            onTap: () {
              // ไปหน้า Account Management
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => Profile(
                        docId: FirebaseAuth.instance.currentUser!.uid,
                      ),
                ),
              );
            },
          ),
          const Divider(color: Colors.white12, thickness: 0.5),
          ListTile(
            leading: const Icon(Icons.movie_filter, color: Colors.white),
            title: const Text(
              'Ticket History',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white),
            onTap: () {
              // ไปหน้า Ticket History
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TicketHistoryPage()),
              );
            },
          ),
          const Divider(color: Colors.white12, thickness: 0.5),
          ListTile(
            leading: const Icon(Icons.call, color: Colors.white),
            title: const Text(
              'Contact Us',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => Contact()),
              );
            },
          ),

          const Divider(color: Colors.white12, thickness: 0.5),
          ListTile(
            leading: const Icon(Icons.developer_mode, color: Colors.white),
            title: const Text(
              'Dev',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => devsPage()),
              );
            },
          ),

          const Divider(color: Colors.white12, thickness: 0.5),
          ListTile(
            leading: const Icon(
              Icons.logout_rounded,
              color: Color.fromARGB(255, 255, 0, 0),
            ),
            title: const Text(
              'Log Out',
              style: TextStyle(
                color: Color.fromARGB(255, 255, 0, 0),
                fontSize: 24,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: Color.fromARGB(255, 255, 0, 0),
            ),

            onTap: () async {
              final auth = AuthenticationService();
              await signOutAndClearCache(context);
              // หลัง logout ให้ไปหน้า login
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const Loginpage()),
                (route) => false,
              );
            },
          ),

          const SizedBox(height: 100),
          Text(
            'Movi App ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color.fromARGB(110, 255, 193, 7),
              fontSize: 20,
            ),
          ),
          Text(
            'version 1.0.0',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color.fromARGB(110, 255, 193, 7),
              fontSize: 20,
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.yellow,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        currentIndex: 3,
        selectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.house),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.film),
            label: 'Movies',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.gift),
            label: 'Gift',
          ),
          BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.bars), label: 'More'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomePage()),
            );
          }
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => Moviespage()),
            );
          }
          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => Promotionpage()),
            );
          }
          if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => Morepage()),
            );
          }
        },
      ),
    );
  }
}
