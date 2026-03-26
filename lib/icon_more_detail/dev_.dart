import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bar_icon/MorePage.dart';

class devsPage extends StatelessWidget {
  const devsPage({super.key});

  static const Color gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    final contributors = <_Contributor>[
      _Contributor(
        name: 'ชื่อ นายทัตพงส์ ทองยวง',
        studentId: 'รหัสนิสิต: 6621600861',
        email: 'tatphong.t@ku.th',
        // ใส่ path รูปทีหลังได้ เช่น 'assets/images/contrib1.jpg' หรือ URL
        imagePathOrUrl: 'images/profile1.jpg',
      ),
      _Contributor(
        name: 'ชื่อ นางสาวณัชชา รุนศรี',
        studentId: 'รหัสนิสิต: 6621604807',
        email: 'natcha.runs@ku.th',
        imagePathOrUrl: 'images/profile2.jpg',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: gold,
        title: const Text('ผู้จัดทำ'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const Morepage()),
            ), // ✅ บังคับให้มีปุ่มย้อนกลับ
      ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: contributors.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final c = contributors[index];
          return _ContributorCard(contributor: c);
        },
      ),
    );
  }
}

class _Contributor {
  final String name;
  final String studentId;
  final String email;

  /// รองรับทั้ง asset path, network URL หรือปล่อยว่าง (null) เพื่อแสดงตัวอักษรย่อ
  final String? imagePathOrUrl;

  _Contributor({
    required this.name,
    required this.studentId,
    required this.email,
    this.imagePathOrUrl,
  });
}

class _ContributorCard extends StatelessWidget {
  const _ContributorCard({required this.contributor});

  final _Contributor contributor;
  static const Color gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF111111),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _Avatar(
              name: contributor.name,
              imagePathOrUrl: contributor.imagePathOrUrl,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contributor.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contributor.studentId,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _launchEmail(contributor.email),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.email_outlined, color: gold, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          contributor.email,
                          style: const TextStyle(
                            color: gold,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.imagePathOrUrl});

  final String name;
  final String? imagePathOrUrl;
  static const Color gold = Color(0xFFD4AF37);

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty ? parts.first.characters.first : '';
    final last = parts.length > 1 ? parts.last.characters.first : '';
    final text = (first + last).toUpperCase();
    return text.isEmpty ? '?' : text;
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? provider;
    if (imagePathOrUrl != null && imagePathOrUrl!.isNotEmpty) {
      if (imagePathOrUrl!.startsWith('http')) {
        provider = NetworkImage(imagePathOrUrl!);
      } else {
        provider = AssetImage(imagePathOrUrl!);
      }
    }

    return CircleAvatar(
      radius: 32,
      backgroundColor: gold.withOpacity(0.2),
      backgroundImage: provider,
      child:
          provider == null
              ? Text(
                _initials,
                style: const TextStyle(
                  color: gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
              : null,
    );
  }
}
