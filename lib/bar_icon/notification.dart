import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../detail/myticket.dart';
import '../detail/movie_detail_page.dart';
// ใช้ data layer เดียวกับหน้า Home
import '../database/dataHelper.dart';
import '../database/Moviemodel.dart';
import 'PromotionPage.dart' show Promotionpage; 

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // ซ่อน (Swipe-hide) – มีอยู่แล้ว
  final Set<String> _hiddenKeys = {};
  static const _prefsHiddenKey = 'hidden_notifications_v1';

  // ✅ ชุด “อ่านแล้ว”
  final Set<String> _readKeys = {};
  static const _prefsReadKey = 'read_notifications_v1';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    _hiddenKeys
      ..clear()
      ..addAll(p.getStringList(_prefsHiddenKey) ?? const []);
    _readKeys
      ..clear()
      ..addAll(p.getStringList(_prefsReadKey) ?? const []);
    if (mounted) setState(() {});
  }

  //ใช้ตอนมีการซ่อนอ่าน เพื่อเซฟสถานะกลับไปยังเครื่อง
  Future<void> _saveHidden() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_prefsHiddenKey, _hiddenKeys.toList());
  }

  Future<void> _saveRead() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_prefsReadKey, _readKeys.toList());
  }

  //วม “ชนิด” + “id” ให้เป็นสตริงเดียวเพื่อใช้ระบุตัวตนรายการนั้น ๆ
  String _keyOf(_NotifyItem it) => '${it.type.index}:${it.id}';

  void _hideItem(_NotifyItem it) {
    setState(() => _hiddenKeys.add(_keyOf(it)));
    _saveHidden();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar( //แสดงแถบแจ้งเตือน/ปุ่ม Undo
        content: const Text('Hidden'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() => _hiddenKeys.remove(_keyOf(it)));
            _saveHidden();
          },
        ),
      ),
    );
  }

  void _markRead(_NotifyItem it) {
    setState(() => _readKeys.add(_keyOf(it)));
    _saveRead();
  }

  Future<void> _restoreAll() async {
    setState(() {
      _hiddenKeys.clear();
      _readKeys.clear();
    });
    await _saveHidden();
    await _saveRead();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Restored all')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _ScaffoldError(msg: 'Please sign in first');

    final bookingsStream = FirebaseFirestore.instance
        .collection('profile')
        .doc(user.uid)
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();

    final moviesStream = MovieDatabaseHelper().streamAll(descending: true);

    final promotionsStream = FirebaseFirestore.instance
        .collection('promotion') // เปลี่ยนเป็น 'promotions' ถ้าคุณใช้ชื่อนั้น
        .limit(50)
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Restore all',
            onPressed: _restoreAll,
            icon: const Icon(Icons.restore, color: Colors.white70),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: Colors.white12, height: 1),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: bookingsStream,
        builder: (context, bookSnap) {
          final bookingDocs =
              (bookSnap.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[]);

          return StreamBuilder<List<MovieModel>>(
            stream: moviesStream,
            builder: (context, movieSnap) {
              final movies = movieSnap.data ?? const <MovieModel>[];
              final comingMovies =
                  movies.where((m) => m.status.toLowerCase().contains('soon'));

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: promotionsStream,
                builder: (context, promoSnap) {
                  final promoDocs =
                      (promoSnap.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[]);

                  final items = <_NotifyItem>[];

                  for (final d in bookingDocs) {
                    final m = d.data();
                    final ts = (m['createdAt'] as Timestamp?);
                    final dateKey = (m['dateKey'] ?? '').toString();
                    final time = (m['time'] ?? '').toString();
                    final dtFallback = _parseFallback(dateKey, time);
                    items.add(_NotifyItem.booking(
                      id: d.id,
                      title: (m['movieTitle'] ?? '').toString(),
                      sub: (m['cinemaName'] ?? '').toString(),
                      poster: (m['posterUrl'] ?? '').toString(),
                      total: (m['total'] ?? 0),
                      stamp: ts?.toDate() ?? dtFallback,
                    ));
                  }

                  for (final m in comingMovies) {
                    items.add(_NotifyItem.newMovie(
                      id: m.id!,
                      title: m.name,
                      sub: 'New Movie is coming...',
                      poster: m.images,
                      stamp: DateTime.now(), // ใส่ releaseDate ถ้ามี
                    ));
                  }

                  for (final d in promoDocs) {
                    final p = d.data();
                    final ts = (p['createdAt'] as Timestamp?);
                    items.add(_NotifyItem.promotion(
                      id: d.id,
                      title: (p['promotion_name'] ?? p['title'] ?? 'New Promotion!!!').toString(),
                      sub: (p['promotion_detail'] ?? p['detail'] ?? '').toString(),
                      poster: (p['image_url'] ?? p['posterUrl'] ?? '').toString(),
                      stamp: ts?.toDate() ?? DateTime.now(),
                    ));
                  }

                  items.sort((a, b) => b.stamp.compareTo(a.stamp));

                  final visible = items
                      .where((it) => !_hiddenKeys.contains(_keyOf(it)))
                      .toList();

                  if (visible.isEmpty) return const _EmptyNotifications();

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: visible.length + 1,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white12, height: 20),
                    itemBuilder: (context, i) {
                      if (i == 0) return _HeaderCount(total: visible.length);

                      final it = visible[i - 1];
                      final key = _keyOf(it);
                      final isRead = _readKeys.contains(key);

                      return Dismissible(
                        key: ValueKey('notif-$key'),
                        direction: DismissDirection.endToStart,
                        background: _DismissBg(),
                        onDismissed: (_) => _hideItem(it),
                        child: _NotificationCard(
                          item: it,
                          isRead: isRead,
                          onTap: () {
                            _markRead(it); // ✅ ทำเครื่องหมายว่าอ่านแล้ว

                            switch (it.type) {
                              case _NotifyType.booking:
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MyTicketsPage(),
                                  ),
                                );
                                break;
                              case _NotifyType.newMovie:
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MovieDetailPage(movieId: it.id),
                                  ),
                                );
                                break;
                              case _NotifyType.promotion:
                                // ✅ ไปหน้าโปรโมชัน
                                // ถ้าคุณมี Promotioncmo ให้ใช้บรรทัดล่างแทน
                                // Navigator.push(context, MaterialPageRoute(builder: (_) => const Promotioncmo()));
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => Promotionpage(), // เปลี่ยนเป็นหน้า/คลาสของคุณ
                                  ),
                                );
                                break;
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  static DateTime _parseFallback(String dateKey, String time) {
    try {
      final d = DateFormat('yyyy-MM-dd').parse(dateKey);
      final t = time.split(':');
      return DateTime(
        d.year,
        d.month,
        d.day,
        t.isNotEmpty ? int.tryParse(t[0]) ?? 0 : 0,
        t.length > 1 ? int.tryParse(t[1]) ?? 0 : 0,
      );
    } catch (_) {
      return DateTime.now();
    }
  }
}

// ─────────────────── UI ───────────────────

class _DismissBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF8A1E1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: const [
          Text('Hide', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          SizedBox(width: 8),
          Icon(Icons.visibility_off, color: Colors.white),
        ],
      ),
    );
  }
}

class _HeaderCount extends StatelessWidget {
  final int total;
  const _HeaderCount({required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('Total : $total',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const Spacer(),
        ],
      ),
    );
  }
}

enum _NotifyType { booking, newMovie, promotion }

class _NotifyItem {
  final _NotifyType type;
  final String id;
  final String title;
  final String sub;
  final String poster;
  final dynamic total; // booking only
  final DateTime stamp;

  _NotifyItem._({
    required this.type,
    required this.id,
    required this.title,
    required this.sub,
    required this.poster,
    required this.total,
    required this.stamp,
  });

  factory _NotifyItem.booking({
    required String id,
    required String title,
    required String sub,
    required String poster,
    required dynamic total,
    required DateTime stamp,
  }) =>
      _NotifyItem._(
        type: _NotifyType.booking,
        id: id,
        title: title,
        sub: sub,
        poster: poster,
        total: total,
        stamp: stamp,
      );

  factory _NotifyItem.newMovie({
    required String id,
    required String title,
    required String sub,
    required String poster,
    required DateTime stamp,
  }) =>
      _NotifyItem._(
        type: _NotifyType.newMovie,
        id: id,
        title: title,
        sub: sub,
        poster: poster,
        total: null,
        stamp: stamp,
      );

  factory _NotifyItem.promotion({
    required String id,
    required String title,
    required String sub,
    required String poster,
    required DateTime stamp,
  }) =>
      _NotifyItem._(
        type: _NotifyType.promotion,
        id: id,
        title: title,
        sub: sub,
        poster: poster,
        total: null,
        stamp: stamp,
      );
}

class _NotificationCard extends StatelessWidget {
  final _NotifyItem item;
  final bool isRead;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.item,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isBooking = item.type == _NotifyType.booking;
    final isPromo = item.type == _NotifyType.promotion;

    final chipColor = isBooking
        ? const Color(0xFF3A3A3A)
        : isPromo
            ? const Color(0xFF6A4D1E)
            : const Color(0xFF6A4D1E);

    final badgeText = isBooking
        ? 'Booking'
        : isPromo
            ? 'New Promotion!!!'
            : 'New Movie!!!';

    Color base = isBooking
        ? const Color(0xFF1E1E1E)
        : isPromo
            ? const Color.fromARGB(255, 46, 46, 46)
            : const Color.fromARGB(255, 46, 46, 46);

    // ✅ ถ้าอ่านแล้ว ให้การ์ดจางลงเล็กน้อย
    final cardColor = isRead ? base.withOpacity(0.65) : base;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 60,
                child: (item.poster.isEmpty)
                    ? Container(
                        color: Colors.white10,
                        child: const Icon(Icons.local_movies, color: Colors.white54),
                      )
                    : Image.network(
                        item.poster,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.white10,
                          child: const Icon(Icons.broken_image, color: Colors.white54),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),

            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // badge + เวลา + "Already read"
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: chipColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 9),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.schedule, size: 10, color: Colors.white38),
                      const SizedBox(width: 4),
                      Text(_timeAgo(item.stamp),
                          style: const TextStyle(color: Colors.white60, fontSize: 9)),
                      const SizedBox(width: 8),
                      if (isRead)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.check, size: 12, color: Colors.white70),
                              SizedBox(width: 2),
                              Text('Already read',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.sub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),

                  if (isBooking && item.total != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4C23E),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${NumberFormat('#,##0.00', 'th_TH').format(item.total)} THB',
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),
            const Icon(Icons.zoom_out_map, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }

  static String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes} mins ago';
    if (diff.inDays < 1) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return '1 day ago';
    return '${diff.inDays} days ago';
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: const [
            Icon(Icons.notifications_none, color: Colors.white30, size: 54),
            SizedBox(height: 10),
            Text('ไม่มีการแจ้งเตือน',
                style: TextStyle(color: Colors.white60, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _ScaffoldError extends StatelessWidget {
  final String msg;
  const _ScaffoldError({required this.msg});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: Center(child: Text(msg, style: const TextStyle(color: Colors.white70))),
    );
  }
}
