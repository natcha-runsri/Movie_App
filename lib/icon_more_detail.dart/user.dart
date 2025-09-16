import 'package:flutter/material.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Colors.black;
    const card = Color(0xFF2A2A2A);
    const border = Colors.white12;
    const label = Colors.white;
    const value = Colors.white70;
    const amber = Colors.amber;

    Widget sectionHeader(String text) => Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 8),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: label,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        );

    Widget pillRow(String left, String right) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            children: [
              Text(left,
                  style: const TextStyle(
                      color: label, fontWeight: FontWeight.w700, fontSize: 14)),
              const Spacer(),
              Text(right, style: const TextStyle(color: value, fontSize: 14)),
            ],
          ),
        );

    Widget pillText(String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1),
          ),
          alignment: Alignment.centerLeft,
          child: Text(text, style: const TextStyle(color: value, fontSize: 14)),
        );

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Column(
            children: [
              // Avatar วงกลมฟ้าอ่อน
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: border, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 44,
                  backgroundColor: Color(0xFFCFE3FF),
                ),
              ),

              // Name
              sectionHeader('Name'),
              pillRow('Name', 'Natcha  Runsri'),

              // DOB
              sectionHeader('Date of Birth'),
              pillRow('Date of Birth', '30 January 2004'),

              // Address
              sectionHeader('Address'),
              pillText('546/49 Rayong'),

              // Contract
              sectionHeader('Contract'),
              pillRow('Telephone', '080-000-1111'),
              const SizedBox(height: 8),
              pillRow('Email', 'nana521@gmail.com'),

              const SizedBox(height: 18),

              // ปุ่ม Edit: กดได้ แต่ไม่ทำอะไร
              TextButton(
                onPressed: () {}, // ทำอะไรไม่ได้ตามที่ขอ
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    color: amber,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
