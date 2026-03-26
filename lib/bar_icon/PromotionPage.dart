import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'homepage.dart';
import 'MoviesPage.dart';
import 'MorePage.dart';
import '../database/Promotiondatahelper.dart';
import '../database/promotion_model.dart';

class Promotionpage extends StatefulWidget {
  const Promotionpage({super.key});

  @override
  State<Promotionpage> createState() => _PromotionpageState();
}

class _Logo extends StatelessWidget {
  const _Logo({super.key});
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

class _PromotionpageState extends State<Promotionpage> {
  final List<PromotionModel> items = [];

  @override
  Widget build(BuildContext context) {
    const bg = Colors.black;
    const gold = Colors.amber;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: bg,
        elevation: 0,
        toolbarHeight: 100,
        titleSpacing: 16,
        title: Row(
          children: const [
            SizedBox(width: 10),
            Text(
              'Promotion',
              style: TextStyle(
                color: gold,
                fontSize: 45,
                fontWeight: FontWeight.w900,
              ),
            ),
            Spacer(),
            _Logo(),
            SizedBox(width: 20),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.white12),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: Promotiondatahelper().getStreamPayments(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No Promotion found.', style: TextStyle(color: Colors.white)));
          }

          items
            ..clear()
            ..addAll(snapshot.data!.docs.map((d) => PromotionModel(
                  promotion_name: d.get('name'),
                  promotion_detail: d.get('detail'),
                  image_url: d.get('image'),
                  validitty_period: d.get('valid'),
                )));

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              final p = items[i];
              return TicketPromotionCard(
                imageUrl: p.image_url,
                title: p.promotion_name,
                subtitle: p.promotion_detail,
                validText: "Valid ${p.validitty_period}",
              );
            },
          );
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: bg,
        selectedItemColor: Colors.yellow,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        currentIndex: 2,
        selectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.house), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.film), label: 'Movies'),
          BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.gift), label: 'Promotion'),
          BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.bars), label: 'More'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Moviespage()));
          } else if (index == 2) {
            // stay
          } else if (index == 3) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Morepage()));
          }
        },
      ),
    );
  }
}

/// ------------------------------------------------------------
///  Ticket-style promotion card (ตามแบบในภาพตัวอย่าง)
/// ------------------------------------------------------------
class TicketPromotionCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String validText;

  const TicketPromotionCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.validText,
  });

  @override
  Widget build(BuildContext context) {
    // ค่าคงที่ของการ์ด
    const double cardHeight = 138;
    const double cardRadius = 18;
    const double imageWidth = 120;
    const double perforationWidth = 22; // พื้นที่คั่นกลาง (เส้นปรุ)
    const Color cardColor = Color(0xFFECECEC); // เทาอ่อนแบบคูปอง

    return SizedBox(
      height: cardHeight,
      child: Stack(
        children: [
          // การ์ดหลัก
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(cardRadius),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                // ฝั่งรูป (ครอบ/ซูมเล็กน้อยเพื่อตัดกรอบขาวของรูป)
                SizedBox(
                  width: imageWidth,
                  height: double.infinity,
                  child: Transform.scale(
                    scale: 1.06,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Colors.black12,
                        child: Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                  ),
                ),

                // โซนเส้นปรุ
                SizedBox(
                  width: perforationWidth,
                  height: double.infinity,
                  child: CustomPaint(painter: _DashedLinePainter()),
                ),

                // เนื้อหาข้อความ
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          validText,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // รอยเจาะครึ่งวงกลมด้านบน/ล่าง (ที่แนวเส้นปรุ)
          // ใช้สีพื้นหลัง (ดำ) เพื่อให้เหมือนโดนเจาะออก
          // คำนวณตำแหน่ง X = imageWidth + perforationWidth/2
          Positioned.fill(
            child: LayoutBuilder(builder: (context, c) {
              final notchCenterX = imageWidth + perforationWidth / 2;
              return Stack(
                children: [
                  // บน
                  Positioned(
                    top: -10, // ดันขึ้นเล็กน้อยให้ซ้อนขอบ
                    left: notchCenterX - 12,
                    child: _Notch(),
                  ),
                  // ล่าง
                  Positioned(
                    bottom: -10,
                    left: notchCenterX - 12,
                    child: _Notch(),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Notch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // วงกลมสีดำเพื่อเลียนแบบรูเจาะออกจากบัตร
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// เส้นปรุแนวตั้ง (เส้นประ)
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashHeight = 6.0;
    const dashSpace = 6.0;
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..strokeWidth = 2.0;

    double y = 8; // เผื่อไม่ให้ติดมุมโค้ง
    final x = size.width / 2;
    final maxY = size.height - 8;

    while (y < maxY) {
      canvas.drawLine(Offset(x, y), Offset(x, y + dashHeight), paint);
      y += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
