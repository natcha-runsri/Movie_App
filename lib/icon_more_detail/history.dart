import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../detail/myticket.dart';
import '../bar_icon/MorePage.dart';

class TicketHistoryPage extends StatelessWidget {
  const TicketHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const _ErrorScaffold(msg: 'Please sign in first');
    }

    final col = FirebaseFirestore.instance
        .collection('profile')
        .doc(user.uid)
        .collection('bookings');

    // ✅ ดึง “ทุกใบ” เรียงจากใหม่ไปเก่า (ถ้าไม่มี createdAt จะเรียงด้วย dateKey+time แทน)
    final stream = col.orderBy('createdAt', descending: true).snapshots();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const Morepage()),
            ),
        ),
        title: const Text('Ticket History',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: Colors.white12, height: 1),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ถ้า index ยังไม่มี createdAt ให้ fallback เรียงด้วย dateKey/time ใน memory
          final docs = (snap.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[]).toList();
          if (docs.isNotEmpty && docs.first.data()['createdAt'] == null) {
            docs.sort((a, b) {
              int cmp = ((b.data()['dateKey'] ?? '') as String)
                  .compareTo((a.data()['dateKey'] ?? '') as String);
              if (cmp != 0) return cmp;
              return ((b.data()['time'] ?? '') as String)
                  .compareTo((a.data()['time'] ?? '') as String);
            });
          }

          if (docs.isEmpty) {
            return const _EmptyHistory();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: docs.length,
            separatorBuilder: (_, __) =>
                const Divider(color: Colors.white12, height: 28),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final id = docs[i].id;

              final dateKey = (d['dateKey'] ?? '').toString(); // yyyy-MM-dd
              final timeStr = (d['time'] ?? '').toString();     // HH:mm
              final movieTitle = (d['movieTitle'] ?? '').toString();
              final cinemaName = (d['cinemaName'] ?? '').toString();
              final total = (d['total'] ?? 0);
              final totalFmt = _fmtBaht(total);
              final dateFmt = _fmtDate(dateKey);

              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyTicketsPage(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // วันที่ + เวลา
                      Row(
                        children: [
                          Text(dateFmt,
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 12)),
                          const SizedBox(width: 10),
                          const Icon(Icons.access_time,
                              color: Colors.white38, size: 14),
                          const SizedBox(width: 4),
                          Text(timeStr,
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // ชื่อเรื่อง + สาขา
                      Text(
                        movieTitle.isEmpty ? '-' : movieTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cinemaName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 10),

                      // ราคา (ชิปสีเหลือง)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4C23E),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$totalFmt THB',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _fmtBaht(dynamic v) {
    if (v is num) {
      return NumberFormat('#,##0.00', 'th_TH').format(v);
    }
    return v?.toString() ?? '0.00';
  }

  static String _fmtDate(String ymd) {
    try {
      final d = DateFormat('yyyy-MM-dd').parse(ymd);
      // รูปแบบเดียวกับภาพ: "4 September 2025"
      return DateFormat('d MMMM yyyy', 'en_US').format(d);
    } catch (_) {
      return ymd;
    }
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Column(
          children: [
            // โลโก้ (เปลี่ยนเป็น asset ของคุณ)
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              alignment: Alignment.center,
              child: Image.asset('images/logo_movi.jpg')
            ),
            const SizedBox(height: 10),
            const Text('MOVI',
                style: TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('No Ticket History',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  final String msg;
  const _ErrorScaffold({required this.msg});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: Center(child: Text(msg, style: const TextStyle(color: Colors.white70))),
    );
  }
}
