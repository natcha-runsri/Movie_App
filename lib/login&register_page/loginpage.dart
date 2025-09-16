// loginpage.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 👈 เพิ่มบรรทัดนี้
import '../database/authenticationService.dart';
import 'registerpage.dart';
import '../bar_icon/homepage.dart'; // ถ้ามีหน้า Home จริง ให้ import อันนี้

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    final email = _email.text.trim();
    final pass = _password.text;

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรอก Email และ Password ให้ครบ')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final ok = await AuthenticationService().login(email, pass);
      if (!mounted) return;

      if (ok) {
        // ✅ เซฟว่าเคยล็อกอินไว้แล้ว (และจะเอาไปเช็คใน main)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('logged_in', true);
        await prefs.setString('email', email); // (ทางเลือก) เก็บว่าใครล็อกอิน

        // ไปหน้า Home ได้เลย ถ้าพร้อม
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));

        // หรือถ้ายังไม่มีหน้า Home ก็แค่แจ้งสำเร็จไว้ก่อน
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('เข้าสู่ระบบสำเร็จ')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อีเมลหรือรหัสผ่านไม่ถูกต้อง')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เข้าสู่ระบบล้มเหลว: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              const FlutterLogo(size: 100), //ใสส่รูปโลโก้ตรงนี้นะ
              const SizedBox(height: 50),
              Text(
                'Welcome',
                style: TextStyle(
                  fontSize: 45,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 50),
              TextField(
                controller: _email,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Email',
                  prefixIcon: Icon(Icons.email, color: Colors.amberAccent),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 25),
              TextField(
                controller: _password,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Password',
                  prefixIcon: Icon(Icons.lock, color: Colors.amberAccent),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                obscureText: true,
                style: const TextStyle(color: Colors.black),
              ),

              const SizedBox(height: 15),
              Align(
                alignment: Alignment.centerRight, // ดันไปขวาสุด
                child: InkWell(
                  onTap: () {},
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 75),

              SizedBox(
                width: 300,
                height: 45,
                child: ElevatedButton(
                  onPressed: _loading ? null : _doLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // พื้นหลังสีดำ
                    foregroundColor: Colors.white, // สีตัวอักษร/ไอคอน
                    side: const BorderSide(
                      color: Colors.white,
                      width: 2,
                    ), // กรอบสีขาว
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        8,
                      ), // มุมโค้ง (ปรับได้)
                    ),
                  ),
                  child:
                      _loading
                          ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text(
                            'Log in',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 270,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        8,
                      ), // มุมโค้ง (ปรับได้)
                    ),
                  ),
                  onPressed: () async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const RegisterSheet(),
                    );
                  },
                  child: const Text(
                    'Sign up',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
