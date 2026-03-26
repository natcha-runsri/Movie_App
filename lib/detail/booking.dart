// booking_page.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/showtime_database_helper.dart'; // ยังใช้ได้หากต้อง upsert/find อื่น ๆ
import '../database/showtime_model.dart'; // ✅ ใช้ ScreenShowtime
import '../database/cinema_database_helper.dart';
import '../database/cinema_model.dart';
import 'seat_page.dart';

class BookingPage extends StatefulWidget {
  final String movieId;
  final String posterUrl;
  final String title;
  final Duration runtime;

  // ✅ เลือกสาขาทีหลังได้ (nullable)
  final String? cinemaId;
  final String? cinemaName;

  const BookingPage({
    super.key,
    required this.movieId,
    required this.posterUrl,
    required this.title,
    required this.runtime,
    this.cinemaId,
    this.cinemaName,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _cinDb = CinemaDatabase();
  final _showDb = ShowtimesService();

  static const gold = Color(0xFFF4C23E);
  static const tileBg = Color(0xFF0F0F0F);

  // เตรียม 7 วันล่วงหน้า (normalize เป็น 00:00)
  late final List<DateTime> _days = List.generate(7, (i) {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day).add(Duration(days: i));
  });

  int _dayIndex = 0;

  String? _cinemaId;
  String? _cinemaName;


  @override
  void initState() {
    super.initState();
    _cinemaId = widget.cinemaId;
    _cinemaName = widget.cinemaName;
  }

  String _runtimeText(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0 && m > 0) return '$h hr $m min';
    if (h > 0) return '$h hr';
    return '$m min';
  }

  // ───────────────────────── Streams / Queries (ตามโมเดลใหม่) ─────────────────────────

  /// Stream screens ทั้งหมดของ "วันนั้น" สำหรับหนัง + สาขาที่เลือก
  Stream<List<ScreenShowtime>> _streamScreensForDay({
    required String movieId,
    required String cinemaId,
    required DateTime dayLocal,
  }) {
    final dateKey = DateFormat('yyyy-MM-dd').format(dayLocal);

    return FirebaseFirestore.instance
        .collectionGroup('screens')
        .where('movieId', isEqualTo: movieId)
        .where('cinemaId', isEqualTo: cinemaId)
        .where('dateKey', isEqualTo: dateKey)
        .snapshots()
        .map((qs) => qs.docs.map((d) => ScreenShowtime.fromDoc(d)).toList());
  }

  /// รวมเป็น: screenId -> times[] และ audio ต่อ screen
  (Map<String, List<String>>, Map<String, String>) _groupTimesByScreen(
    List<ScreenShowtime> items,
  ) {
    final byScreen = <String, List<String>>{};
    final audio = <String, String>{};

    for (final s in items) {
      (byScreen[s.screenId] ??= <String>[]).addAll(
        s.time,
      ); // ⬅️ เปลี่ยนเป็น addAll
      audio.putIfAbsent(s.screenId, () => s.audio);
    }

    // unique + sort เวลา
    byScreen.updateAll((_, list) {
      final seen = <String>{};
      final cleaned = <String>[];
      for (final t in list) {
        final tt = t.trim();
        if (tt.isEmpty) continue;
        if (seen.add(tt)) cleaned.add(tt);
      }
      cleaned.sort((a, b) => a.compareTo(b));
      return cleaned;
    });

    return (byScreen, audio);
  }

  // ───────────────────────── UI helpers ─────────────────────────

  Future<void> _openCinemaPicker() async {
    final selected = await showModalBottomSheet<CinemaModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        String q = '';
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.of(ctx).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    TextField(
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      onChanged:
                          (v) =>
                              setSheetState(() => q = v.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'ค้นหาโรงหนัง',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white54,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF0F0F0F),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: StreamBuilder<List<CinemaModel>>(
                        stream: _cinDb.streamAll(),
                        builder: (ctx, snap) {
                          if (snap.hasError) {
                            return const Center(
                              child: Text(
                                'โหลดรายชื่อโรงไม่ได้',
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          }
                          if (!snap.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final all = snap.data!;
                          final list =
                              q.isEmpty
                                  ? all
                                  : all
                                      .where(
                                        (c) =>
                                            (c.name).toLowerCase().contains(q),
                                      )
                                      .toList();

                          if (list.isEmpty) {
                            return const Center(
                              child: Text(
                                'ไม่พบสาขาที่ตรงกับคำค้น',
                                style: TextStyle(color: Colors.white54),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            itemCount: list.length,
                            separatorBuilder:
                                (_, __) => const Divider(
                                  color: Colors.white12,
                                  height: 1,
                                ),
                            itemBuilder: (_, i) {
                              final c = list[i];
                              return ListTile(
                                onTap: () => Navigator.pop(ctx, c),
                                leading: const Icon(
                                  Icons.theaters,
                                  color: Color(0xFFF4C23E),
                                ),
                                title: Text(
                                  c.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle:
                                    c.address.isNotEmpty == true
                                        ? Text(
                                          c.address,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                          ),
                                        )
                                        : null,
                                trailing: const Icon(
                                  Icons.check,
                                  color: Colors.white24,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selected != null) {
      setState(() {
        _cinemaId = selected.id;
        _cinemaName = selected.name;
      });
    }
  }
  

  @override
  Widget build(BuildContext context) {
    final bg = Colors.black;
    final now = DateTime.now();

    // เงื่อนไข "ขึ้นเดือนใหม่ไม่ให้เลือกวัน": กรองเฉพาะวันของเดือนปัจจุบัน
    final List<DateTime> visibleDays =
        _days.where((d) => d.year == now.year && d.month == now.month).toList();

    // แก้ index ให้ปลอดภัย
    if (visibleDays.isEmpty) {
      _dayIndex = -1;
    } else {
      if (_dayIndex < 0 || _dayIndex >= visibleDays.length) {
        _dayIndex = 0;
      }
    }

    final DateTime? selectedDay =
        (_dayIndex >= 0 && _dayIndex < visibleDays.length)
            ? visibleDays[_dayIndex]
            : null;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new, 
            color: Color.fromARGB(255, 187, 187, 187),
            size: 35,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end, // ดันไปขวาสุด
          children: const [
            Text(
              'Booking',
              style: TextStyle(
                 color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 30,
                letterSpacing: .2,
              ),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Poster
            ClipRRect(
              child: AspectRatio(
                aspectRatio: 9 / 7,
                child: Image.network(
                  (widget.posterUrl.isEmpty)
                      ? 'https://via.placeholder.com/900x600?text=No+Image'
                      : widget.posterUrl,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(color: Colors.white10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Title + runtime
            Center(
              child: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            ),
            const SizedBox(height: 6),

            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min, // 👈 ให้แคบเท่ากับเนื้อหา
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _runtimeText(widget.runtime),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search cinema
            GestureDetector(
              onTap: _openCinemaPicker,
              child: AbsorbPointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color.fromARGB(255, 0, 0, 0)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextField(
                    readOnly: true,
                    style: const TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 18,
                    ),
                    decoration: InputDecoration(
                      icon: const Icon(
                        Icons.search, 
                        color: Color.fromARGB(255, 71, 71, 71)
                      ),
                      hintText:
                          _cinemaName?.isNotEmpty == true
                              ? _cinemaName
                              : 'Search cinema',
                      hintStyle: const TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0)
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Branch header + card
            const Text(
              'branch',
              style: TextStyle(
                color: Color.fromARGB(255, 255, 255, 255),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),

            InkWell(
              onTap: _openCinemaPicker,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: tileBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.theaters, color: gold, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _cinemaName ?? 'แตะเพื่อเลือกสาขา',
                        style: TextStyle(
                          color:
                              _cinemaName == null
                                  ? Colors.white54
                                  : Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Month (หัวเดือนใช้เดือนปัจจุบันเสมอ)
            Text(
              DateFormat('MMMM', 'en_US').format(now),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),

            // Day picker (ซ่อนถ้าเดือนใหม่ไม่มีวันให้เลือก)
            if (visibleDays.isEmpty)
              const SizedBox.shrink()
            else
              SizedBox(
                height: 68,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: visibleDays.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final d = visibleDays[i];
                    final sel = i == _dayIndex;
                    final dow = DateFormat('EEE', 'en_US').format(d);
                    final day = d.day;

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _dayIndex = i),
                      child: Container(
                        width: 50,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? const Color.fromARGB(255, 244, 195, 62) : const Color.fromARGB(255, 139, 136, 136),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sel ? Colors.transparent : const Color.fromARGB(31, 0, 0, 0),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dow,
                              style: TextStyle(
                                color: sel ? Colors.black : Colors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '$day',
                              style: TextStyle(
                                color: sel ? Colors.black : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 23,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),

            // ── Theatres + times จาก Screens (โมเดลใหม่) ────────────────────────────
            if (_cinemaId == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'โปรดเลือกสาขาก่อน',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              )
            else if (selectedDay == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'ไม่มีวันที่ให้เลือกในเดือนนี้',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              )
            else
              StreamBuilder<List<ScreenShowtime>>(
                stream: _showDb.streamScreensByMovieCinemaDate(
                  movieId: widget.movieId,
                  cinemaId: _cinemaId!,
                  dayLocal: selectedDay,
                ),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snap.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final screens = snap.data!;
                  if (screens.isEmpty) {
                    return const Center(
                      child: Text(
                        'ยังไม่มีรอบในวันนี้',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  final (timesByScreen, audioByScreen) = _groupTimesByScreen(
                    screens,
                  );
                  final screenIds = timesByScreen.keys.toList()..sort();

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: screenIds.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, idx) {
                      final sid = screenIds[idx];
                      final times = timesByScreen[sid] ?? const <String>[];
                      final audio = audioByScreen[sid] ?? '';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           const Divider(
                            color: Color.fromARGB(197, 107, 102, 102),
                            height: 0.5,
                          ),
                          const SizedBox(height: 10,),
                          Row(
                            children: [
                              Text(
                                'Theatre $sid',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Icon(
                                FontAwesomeIcons.volumeLow,
                                color: Colors.white,
                                size: 15,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                ' $audio ',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children:
                                times.map((t) {
                                  return ActionChip(
                                    label: Text(
                                      '$t',
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 255, 255, 255),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                    backgroundColor: const Color.fromARGB(255, 228, 171, 0),
                                    onPressed: () {
                                      final poster =
                                          (widget.posterUrl.isEmpty)
                                              ? 'https://via.placeholder.com/900x600?text=No+Image'
                                              : widget.posterUrl;

                                      if (!mounted) return;

                                      final cid = _cinemaId ?? '';
                                      final cname = _cinemaName ?? '';
                                      if (cid.isEmpty || cname.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'ไม่พบข้อมูลโรงภาพยนตร์',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => SeatPage(
                                                movieId: widget.movieId,
                                                movieTitle: widget.title,
                                                posterUrl: poster,
                                                cinemaId: cid,
                                                cinemaName: cname,
                                                screenId: sid,
                                                showDate: selectedDay,
                                                showTime: t,
                                              ),
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
