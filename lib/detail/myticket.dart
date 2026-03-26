import 'package:cinema_app/bar_icon/homepage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MyTicketsPage extends StatelessWidget {
  final String? uid; // ถ้าไม่ส่งมา จะใช้ currentUser.uid
  const MyTicketsPage({super.key, this.uid});

  @override
  Widget build(BuildContext context) {
    final _uid = uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (_uid == null) {
      return const _Error(msg: 'ยังไม่ได้ล็อกอิน');
    }

    final col = FirebaseFirestore.instance
        .collection('profile').doc(_uid)
        .collection('bookings');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white,size: 35,),
          onPressed: () => Navigator.push(
            context,
           MaterialPageRoute(builder: (context) => HomePage(),)
          ),
        ),
        title: const Text('My Tickets', style: TextStyle(
          color: Colors.amber,
          fontSize: 30,
          fontWeight: FontWeight.w700,
          )
        ),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: col
            // ถ้าคุณเก็บเวลา เช่น createdAt, bookedAt, timestamp ให้สั่งเรียงได้
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(
              child: Text('ยังไม่มีตั๋วที่จอง', style: TextStyle(color: Colors.white70)),
            );
          }

          final docs = snap.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (_, i) {
              final d = docs[i];
              final b = d.data();
              final bookingId = d.id;

              final posterFromBooking = (b['posterUrl'] ?? '').toString();

              // ถ้ามีโปสเตอร์ใน booking ใช้อันนี้เลย (โหลดไวกว่า)
              if (posterFromBooking.isNotEmpty) {
                return _TicketCard(
                  posterUrl: posterFromBooking,
                  movieTitle: (b['movieTitle'] ?? '').toString(),
                  cinemaName: (b['cinemaName'] ?? '').toString(),
                  screenId: (b['screenId'] ?? '').toString(),
                  dateKey: (b['dateKey'] ?? '').toString(),
                  time: (b['time'] ?? '').toString(),
                  seats: List<String>.from(b['seats'] ?? const []),
                  seatType: (b['seatType'] ?? '').toString(),
                  total: (b['total'] ?? 0) is num ? (b['total'] as num).toInt() : 0,
                  phone: (b['phone'] ?? '').toString(),
                  bookingId: bookingId,
                  userId: (b['userId'] ?? _uid).toString(),
                  audio: _optString(b['audio']),
                  rating: _optString(b['rating']),
                );
              }

              // ถ้าไม่ได้เก็บ posterUrl ใน booking → ไปดึงจาก movie/{movieId}
              final movieId = (b['movieId'] ?? '').toString();
              return FutureBuilder<String?>(
                future: _loadPosterIfAny(movieId),
                builder: (_, posterSnap) {
                  return _TicketCard(
                    posterUrl: posterSnap.data,
                    movieTitle: (b['movieTitle'] ?? '').toString(),
                    cinemaName: (b['cinemaName'] ?? '').toString(),
                    screenId: (b['screenId'] ?? '').toString(),
                    dateKey: (b['dateKey'] ?? '').toString(),
                    time: (b['time'] ?? '').toString(),
                    seats: List<String>.from(b['seats'] ?? const []),
                    seatType: (b['seatType'] ?? '').toString(),
                    total: (b['total'] ?? 0) is num ? (b['total'] as num).toInt() : 0,
                    phone: (b['phone'] ?? '').toString(),
                    bookingId: bookingId,
                    userId: (b['userId'] ?? _uid).toString(),
                    audio: _optString(b['audio']),
                    rating: _optString(b['rating']),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// ===== Helpers ที่ใช้ร่วมกับ _TicketCard =====
String? _optString(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

// โหลดโปสเตอร์จาก movie/{movieId} หากมี
Future<String?> _loadPosterIfAny(String movieId) async {
  if (movieId.isEmpty) return null;
  try {
    final doc = await FirebaseFirestore.instance.collection('movie').doc(movieId).get();
    if (!doc.exists) return null;
    final m = doc.data() as Map<String, dynamic>;
    return (m['image_url'] ?? m['posterUrl'])?.toString();
  } catch (_) {
    return null;
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.posterUrl,
    required this.movieTitle,
    required this.cinemaName,
    required this.screenId,
    required this.dateKey,
    required this.time,
    required this.seats,
    required this.seatType,
    required this.total,
    required this.phone,
    required this.bookingId,
    required this.userId,
    this.audio,
    this.rating,
  });

  final String? posterUrl;
  final String movieTitle, cinemaName, screenId, dateKey, time, seatType, phone, bookingId, userId;
  final List<String> seats;
  final int total;
  final String? audio;   // แสดงต่อเมื่อมี
  final String? rating;  // แสดงต่อเมื่อมี

  @override
  Widget build(BuildContext context) {
    final yellow = const Color(0xFFF4C23F);
    final seatJoined = seats.join(', ');
    final (dateStr, timeStr) = _fmtDate(dateKey, time);
    final totalStr = NumberFormat.currency(locale: 'th_TH', symbol: '฿').format(total);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: yellow, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 8))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child:
                          (posterUrl == null || posterUrl!.isEmpty)
                              ? Container(
                                color: const Color.fromARGB(255, 0, 0, 0),
                                child: const Center(
                                  child: Icon(
                                    Icons.local_movies,
                                    color: Colors.white54,
                                    size: 48,
                                  ),
                                ),
                              )
                              : Image.network(
                                posterUrl!,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => Container(
                                      color: Colors.black26,
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          color: Colors.white54,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                              ),

                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: Text(movieTitle,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                        ),
                        if (audio != null || rating != null)
                          Row(children: [
                            if (audio != null)
                              Text(audio!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            if (audio != null && rating != null) const SizedBox(width: 6),
                            if (rating != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6)),
                                child: Text(rating!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              ),
                          ]),
                      ]),
                      const SizedBox(height: 8),
                      Text('$dateStr  $timeStr', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('$cinemaName   $screenId', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 8),
                      _DashedDivider(color: Colors.white12),
                      const SizedBox(height: 8),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('ประเภทที่นั่ง', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            Text(seatType.isEmpty ? '-' : seatType,
                                style: TextStyle(color: yellow, fontSize: 14, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            const Text('ที่นั่ง', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            Text(seatJoined, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            const Text('ราคารวม', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            Text(totalStr, style: TextStyle(color: yellow, fontWeight: FontWeight.w800, fontSize: 16)),
                          ]),
                        ),
                        const SizedBox(width: 12),
                        Column(children: [
                          QrImageView(
                            data: 'booking:$bookingId;user:$userId',
                            version: QrVersions.auto,
                            size: 92,
                            backgroundColor: Colors.white,
                            gapless: true,
                          ),
                          const SizedBox(height: 6),
                          Text('code: $bookingId', style: const TextStyle(color: Colors.white60, fontSize: 10)),
                        ]),
                      ]),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(children: [
                          Container(
                            width: 34, height: 34, alignment: Alignment.center,
                            decoration: BoxDecoration(color: Colors.black, border: Border.all(color: yellow, width: 1.2), borderRadius: BorderRadius.circular(8)),
                            child: Image.asset('images/logo_movi.jpg')
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text('TicketId: $bookingId', style: const TextStyle(color: Colors.white60, fontSize: 10)),
                              Text('userid : $userId', style: const TextStyle(color: Colors.white60, fontSize: 10)),
                            ]),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
            const Positioned(left: 4, child: _CutCircle()),
            const Positioned(right: 4, child: _CutCircle()),
          ],
        ),
      ),
    );
  }

  static (String, String) _fmtDate(String dateKey, String time) {
    try {
      final d = DateFormat('yyyy-MM-dd').parse(dateKey);
      return (DateFormat('d MMMM yyyy', 'en_US').format(d), time);
    } catch (_) {
      return (dateKey, time);
    }
  }
}

class _DashedDivider extends StatelessWidget {
  final Color color;
  const _DashedDivider({required this.color});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final n = (c.maxWidth / 6).floor();
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(n, (_) => Container(width: 3, height: 1.5, color: color)),
      );
    });
  }
}

class _CutCircle extends StatelessWidget {
  const _CutCircle();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black, border: Border.all(color: Colors.white24)),
    );
  }
}

class _Error extends StatelessWidget {
  final String msg;
  const _Error({required this.msg});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, elevation: 0),
      body: Center(child: Text(msg, style: const TextStyle(color: Colors.white70))),
    );
  }
}
