import 'package:flutter/material.dart';
import '../database/authenticationService.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ____________________________ Class Register _________________________________
class RegisterSheet extends StatefulWidget {
  const RegisterSheet({super.key});

  @override
  State<RegisterSheet> createState() => _RegisterSheetState();
}

class _RegisterSheetState extends State<RegisterSheet> {
  String email = '';
  String password = '';
  String confirmPassword = '';
  bool _obscure1 = true;
  bool _obscure2 = true;
//____________________________________________________________________________

//
  @override
  Widget build(BuildContext context) {
    // รองรับคีย์บอร์ดดันขึ้น
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        minChildSize: 0.52,
        initialChildSize: 0.70,
        maxChildSize: 0.75,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // แถบจับลาก
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // โลโก้ด้านบน (ของแผง)
                  Center(
                    child: Column(
                      children: [
                        Container(
                          height: 72,
                          width: 72,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: const FlutterLogo(size: 44),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'MOVI',
                          style: TextStyle(
                            fontSize: 13,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  _OutlineField(
                    label: 'Enter Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (v) => email = v,
                  ),
                  const SizedBox(height: 12),

                  _OutlineField(
                    label: 'Enter Password',
                    icon: Icons.lock_outline,
                    obscureText: _obscure1,
                    onChanged: (v) => password = v,
                    trailing: IconButton(
                      icon: Icon(
                        _obscure1 ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _OutlineField(
                    label: 'Confirm Password',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscure2,
                    onChanged: (v) => confirmPassword = v,
                    trailing: IconButton(
                      icon: Icon(
                        _obscure2 ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: SizedBox(
                      width: 300,

                      child: ElevatedButton(
                        onPressed: () async {
                          if (email.isEmpty || password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('กรอก Email และ Password AAให้ครบ'),
                              ),
                            );
                            return;
                          }
                          if (password != confirmPassword) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('รหัสผ่านไม่ตรงกัน'),
                              ),
                            );
                            return;
                          }

                          final ok = await AuthenticationService().register(
                            email,
                            password,
                          );
                          if (!mounted) return;

                          if (ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ลงทะเบียนสำเร็จ')),
                            );
                            Navigator.of(
                              context,
                            ).pop(); // ปิดแผง (ยังอยู่หน้าเดิม)
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ลงทะเบียนล้มเหลว')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B5BDB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Create',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Center(
                    child: Column(
                      children: [
                        const Text(
                          '----------------------------  Sign up with  ----------------------------',
                          style: TextStyle(fontSize: 15, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.blue,
                              child: FaIcon(
                                FontAwesomeIcons.facebookF,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 14),
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Color.fromARGB(255, 255, 242, 242),
                              child: FaIcon(
                                FontAwesomeIcons.google,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 14),
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.white,
                              child: FaIcon(
                                FontAwesomeIcons.apple,
                                color: Colors.black,
                                size: 22,
                              ),
                            ),
                            SizedBox(width: 14),
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.lightBlue,
                              child: FaIcon(
                                FontAwesomeIcons.twitter,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: InkWell(
                      onTap:
                          () =>
                              Navigator.of(context).pop(), // ปิดแผงกลับไป Login
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Already have an account? Log in',
                          style: TextStyle(fontSize: 15, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ____________________________ ช่วยตกแต่ง _________________________________
class _OutlineField extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _OutlineField({
    required this.label,
    required this.icon,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black87, width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black87),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              obscureText: obscureText,
              keyboardType: keyboardType,
              decoration: InputDecoration(            // ← เอา const ออก
                hintText: label,                      // ← ใช้ label เป็นข้อความในกล่อง
                border: InputBorder.none,
                isDense: true,
                hintStyle: const TextStyle(
                  color: Colors.black45,
                  fontSize: 13.5,
                ),
              ),
              style: const TextStyle(color: Colors.black, fontSize: 14.5),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
// ___________________________________________________________________________
