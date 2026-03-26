import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
// ถ้ายังไม่ใช้จริง ลบไฟล์นี้ออกได้
import 'payment.dart';

class SeatPage extends StatefulWidget {
  final String movieId;
  final String movieTitle;
  final String posterUrl;
  final String cinemaId;
  final String cinemaName;
  final String screenId; // เช่น "1"
  final DateTime showDate; // วันเลือก (local)
  final String showTime; // เช่น "15:00"
  final String? phone; 

  const SeatPage({
    super.key,
    required this.movieId,
    required this.movieTitle,
    required this.posterUrl,
    required this.cinemaId,
    required this.cinemaName,
    required this.screenId,
    required this.showDate,
    required this.showTime,
    this.phone,
  });

  @override
  State<SeatPage> createState() => _SeatPageState();
}

class _SeatPageState extends State<SeatPage> {
  static const gold = Color(0xFFF4C23E);
  static const tileBg = Color(0xFF0F0F0F);
  late final TextEditingController _phone;
  

  /// อ้างอิงไปที่ `showtimes/{slotId}/screens/{screenId}`
  DocumentReference<Map<String, dynamic>>? _screenRef;

  // ที่นั่งที่เลือก (key = "A10")
  final Set<String> _selected = {};
  // เก็บราคาต่อแถว
  final Map<String, int> _priceByRow = {};
  // เก็บประเภทต่อแถว
  final Map<String, String> _typeByRow = {};

  // ============== Utils ==============
  String _normTime(String s) {
    final t = s.trim();
    final noAp = t.replaceAll(RegExp(r'\s?(AM|PM)$', caseSensitive: false), '');
    final m = RegExp(r'^(\d{1,2})(?::(\d{1,2}))?$').firstMatch(noAp);
    if (m == null) return noAp;
    final h = m.group(1)!.padLeft(2, '0');
    final mm = (m.group(2) ?? '00').padLeft(2, '0');
    return '$h:$mm';
  }

  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? 0;
    return 0;
  }

  String _formatDate(DateTime d) =>
      DateFormat('EEEE d MMMM yyyy', 'en_US').format(d);

  // ============== Firestore ==============

  /// หา **screen doc** จาก (movieId, cinemaId, dateKey, screenId, time)
  Stream<DocumentSnapshot<Map<String, dynamic>>?> screenDocStream() async* {
    final dayKey = DateFormat('yyyy-MM-dd').format(widget.showDate);
    final wantedTime = _normTime(widget.showTime);

    final qsStream =
        FirebaseFirestore.instance
            .collectionGroup('screens')
            .where('movieId', isEqualTo: widget.movieId)
            .where('cinemaId', isEqualTo: widget.cinemaId)
            .where('dateKey', isEqualTo: dayKey)
            .where('screenId', isEqualTo: widget.screenId)
            .where(
              'time',
              arrayContains: wantedTime,
            ) // ใช้ arrayContains ได้ 1 ตัว
            .limit(1)
            .snapshots();

    await for (final qs in qsStream) {
      if (qs.docs.isEmpty) {
        yield null;
      } else {
        yield qs.docs.first;
      }
    }
  }

  /// stream ที่นั่ง (ทุกแถว) ใต้ **screen doc**
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> seatsStream(
    DocumentReference<Map<String, dynamic>> screenRef,
  ) {
    return screenRef
        .collection('seats') // <-- ตามสคีมาใหม่ ใช้ "seats"
        .orderBy('row')
        .snapshots()
        .map((s) => s.docs);
  }

  // ============== UI helpers ==============

  List<String> get selectedSorted {
    final list = _selected.toList();
    list.sort((a, b) {
      final ra = a.substring(0, 1);
      final rb = b.substring(0, 1);
      if (ra != rb) return ra.compareTo(rb);
      final ai = int.tryParse(a.substring(1)) ?? 0;
      final bi = int.tryParse(b.substring(1)) ?? 0;
      return ai.compareTo(bi);
    });
    return list;
  }

  int get totalPrice {
    int sum = 0;
    for (final key in _selected) {
      final row = key.substring(0, 1);
      sum += _priceByRow[row] ?? 0;
    }
    return sum;
  }

  Color seatColor({
    required bool isReserved,
    required bool isSelected,
    required String type,
  }) {
    if (isReserved) return Colors.white24;
    if (isSelected) return Colors.white;
    switch (type.toUpperCase()) {
      case 'VIP':
        return const Color.fromARGB(255, 209, 168, 45);
      case 'PREMIUM':
        return const Color.fromARGB(255, 50, 45, 148);
      default:
        return const Color.fromARGB(255, 103, 30, 163);
    }
  }
  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.phone ?? '');  // ⬅️ ปลอดภัยกับ null
  }

  Widget _legendChip(Color c, String label, String priceText) {
    return Container(
      width: 95,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color.fromARGB(31, 255, 255, 255)),
      ),
      child: Column(
        children: [
          Container(
            width: 17,
            height: 20,
            decoration: BoxDecoration(color: c, 
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(priceText, style: const TextStyle(color: Color.fromARGB(172, 255, 255, 255))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = Colors.black;
    final canContinue = _screenRef != null && _selected.isNotEmpty;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new, 
            color: Colors.white,
            size: 35,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center, // ดันไปขวาสุด
          children: const [
            Text(
          'Choose seats',
          style: TextStyle(
            color: Color(0xFFF4C23E),
            fontWeight: FontWeight.w900,
            fontSize: 30,
            height: 1,
          ),
        ),
          ],
        ),
      ),
      
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
        stream: screenDocStream(),
        builder: (context, stSnap) {
          if (stSnap.hasError) {
            return Center(
              child: Text(
                'โหลดรอบฉายไม่สำเร็จ\n${stSnap.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!stSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final scDoc = stSnap.data;
          if (scDoc == null || !scDoc.exists) {
            return const Center(
              child: Text(
                'ไม่พบรอบฉายที่เลือก',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          _screenRef = scDoc.reference; // เก็บไว้ใช้ตอนจอง

          return StreamBuilder<
            List<QueryDocumentSnapshot<Map<String, dynamic>>>
          >(
            stream: seatsStream(_screenRef!),
            builder: (context, seatSnap) {
              if (seatSnap.hasError) {
                return const Center(
                  child: Text(
                    'โหลดผังที่นั่งไม่สำเร็จ',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }
              if (!seatSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final rows = seatSnap.data!;
              if (rows.isEmpty) {
                return const Center(
                  child: Text(
                    'ยังไม่มีผังที่นั่ง',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              // อัปเดตราคา/ประเภทต่อแถว
              _priceByRow.clear();
              _typeByRow.clear();
              for (final r in rows) {
                final data = r.data();
                final row = (data['row'] ?? '').toString();
                final price = _asInt(data['price']);
                final type = (data['type'] ?? 'Standard').toString();
                if (row.isNotEmpty) {
                  _priceByRow[row] = price;
                  _typeByRow[row] = type;
                }
              }

              // ราคาโชว์ legend
              int _pickFirstPriceWhere(bool Function(String type) pred) {
                for (final e in _priceByRow.entries) {
                  final t = (_typeByRow[e.key] ?? '').toUpperCase();
                  if (pred(t) && e.value > 0) return e.value;
                }
                return 0;
              }

              final vipPrice = _pickFirstPriceWhere((t) => t == 'VIP');
              final premiumPrice = _pickFirstPriceWhere((t) => t == 'PREMIUM');
              final standardPrice = _pickFirstPriceWhere(
                (t) => t == 'STANDARD' || t.isEmpty,
              );

              final sortedRows = [...rows]..sort((a, b) {
                final ra = (a.data()['row'] ?? '').toString();
                final rb = (b.data()['row'] ?? '').toString();
                return rb.compareTo(ra); // I -> A
              });
              return SingleChildScrollView(
                padding: EdgeInsets.all(15),
                child: Column(
                  children: [
                    // Cinema / Theatre / Audio line
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // ให้ Row กว้างเท่าที่จำเป็น
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            FontAwesomeIcons.film,
                            color: gold,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            widget.cinemaName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // ให้ Row กว้างเท่าที่จำเป็น
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Theatre ${widget.screenId}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            FontAwesomeIcons.volumeLow,
                            color: Colors.white,
                            size: 15,
                          ),
                          Text(
                            ' TH ',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                        size: 18,
                        color: Colors.blue,
                        ),
                        const SizedBox(width: 5,),
                        const Text(
                          'Date',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          // 👈 ทำให้ Divider ขยายเต็มบรรทัด
                          child: Divider(
                            color: const Color.fromARGB(62, 255, 255, 255),
                            thickness: 1,
                            height: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _formatDate(widget.showDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Time
                    Row(
                      children: [
                        Icon(Icons.schedule,
                        size: 20,
                        color: Colors.blue,
                        ),
                        const SizedBox(width: 5,),
                         const Text(
                      'Time',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 10),
                        Expanded(
                          // 👈 ทำให้ Divider ขยายเต็มบรรทัด
                          child: Divider(
                            color: const Color.fromARGB(62, 255, 255, 255),
                            thickness: 1,
                            height: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Center(
                      child:  Text(
                      widget.showTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    ),
                    const SizedBox(height: 20),

                    // Screen curve
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 200,
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white24,
                                width: 2,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(400),
                                topRight: Radius.circular(400),
                                bottomLeft: Radius.circular(200),
                                bottomRight: Radius.circular(200),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Screen',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Seat grid per row (เรียง I..A เหมือนในภาพ)
                    for (final rowDoc in sortedRows) ...[
                      _SeatRow(
                        rowDoc: rowDoc,
                        isSelected: (row, no) => _selected.contains('$row$no'),
                        onTapSeat: (row, no, isReserved, type) {
                          if (isReserved) return;
                          final key = '$row$no';
                          setState(() {
                            if (!_selected.remove(key))
                              _selected.add(key); // toggle
                          });
                        },
                        colorFor: seatColor,
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Icon(
                          Icons.chair,
                          size: 20,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 7),
                        const Text(
                          'Seats',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          // 👈 ทำให้ Divider ขยายเต็มบรรทัด
                          child: Divider(
                            color: const Color.fromARGB(62, 255, 255, 255),
                            thickness: 1,
                            height: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20,),

                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _legendChip(
                          const Color.fromARGB(255, 103, 30, 163),
                          'Standard',
                          standardPrice == 0 ? '' : '฿$standardPrice',
                        ),
                        _legendChip(
                          const Color.fromARGB(255, 50, 45, 148),
                          'Premium',
                          premiumPrice == 0 ? '' : '฿$premiumPrice',
                        ),
                        _legendChip(
                          const Color.fromARGB(255, 209, 168, 45),
                          'VIP',
                          vipPrice == 0 ? '' : '฿$vipPrice',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 20,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 7),
                        const Text(
                          'Telephone',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          // 👈 ทำให้ Divider ขยายเต็มบรรทัด
                          child: Divider(
                            color: const Color.fromARGB(62, 255, 255, 255),
                            thickness: 1,
                            height: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color.fromARGB(164, 244, 195, 62), width: 1.2),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.numbers, color: Color.fromARGB(151, 255, 255, 255),
                            size: 20,
                          ),
                          const SizedBox(width: 20),
                          // สำคัญ: ต้องหุ้มด้วย Expanded ให้ TextField กินพื้นที่ที่เหลือ
                          Expanded(
                            child: TextField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Phone Number',
                                hintStyle: TextStyle(color: Colors.white54),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(vertical: 15,horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed:
                          canContinue
                              ? () {
                                // สรุปประเภท/ราคา ตามแถวของที่เลือกทั้งหมด
                                final selectedRows =
                                    _selected
                                        .map((s) => s.substring(0, 1))
                                        .toSet();

                                // ประเภทที่พบใน selection
                                final selectedTypes =
                                    selectedRows
                                        .map(
                                          (r) =>
                                              (_typeByRow[r] ?? '').toString(),
                                        )
                                        .where((t) => t.isNotEmpty)
                                        .toSet();

                                // ราคาที่พบใน selection
                                final selectedPrices =
                                    selectedRows
                                        .map((r) => _priceByRow[r] ?? 0)
                                        .where((p) => p > 0)
                                        .toSet();

                                final seatTypeToSend =
                                    selectedTypes.length == 1
                                        ? selectedTypes.first
                                        : 'Mixed';
                                final pricePerSeatToSend =
                                    selectedPrices.length == 1
                                        ? selectedPrices.first
                                        : 0;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => PaymentPage(
                                          screenRef: _screenRef!,
                                          cinemaId: widget.cinemaId,
                                          movieId: widget.movieId,
                                          movieTitle: widget.movieTitle,
                                          posterUrl: widget.posterUrl,
                                          audio: 'TH',
                                          cinemaName: widget.cinemaName,
                                          screenId: widget.screenId,
                                          showDate: widget.showDate,
                                          showTime: widget.showTime,
                                          phone: _phone.text.trim(),
                                          selectedSeats: selectedSorted,
                                          seatType:
                                              seatTypeToSend, // 'VIP' / 'Premium' / 'Standard' หรือ 'Mixed'
                                          pricePerSeat:
                                              pricePerSeatToSend, // ราคา/ที่นั่ง ถ้าคละ = 0 (ให้คำนวณจาก total)
                                          // ถ้าต้องการส่งราคารวมไปด้วย:
                                          // totalPrice: totalPrice,
                                        ),
                                  ),
                                );
                              }
                              : null, // 👈 ถ้า null ปุ่มจะ disabled อัตโนมัติ
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          color: Color.fromARGB(172, 0, 0, 0),
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      
      //ปุ่มลอยข้างล่าง
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          color: Colors.transparent,
          child: Row(
            children: [
              // ซ้าย: รายการที่นั่งที่เลือก
              Expanded(
                child: Container(
                  height: 70, // << กำหนดความสูงคงที่
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 33, 44, 167),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // << กันยืดสูง
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seats :',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        _selected.isEmpty ? '-' : selectedSorted.join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.amber,fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // ขวา: Total (กดไปขั้นตอนต่อไปได้ถ้าต้องการ)
              Expanded(
                  child: Container(
                    height: 70, // << กำหนดความสูงคงที่
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 122, 16, 172),
                      borderRadius: BorderRadius.circular(12),
                      // ทำให้ดู disabled ถ้ายังไม่เลือกที่นั่ง
                      boxShadow:
                          _selected.isEmpty
                              ? null
                              : [
                                const BoxShadow(
                                  blurRadius: 8,
                                  color: Colors.black26,
                                ),
                              ],
                      // opacity ถ้าอยากจางเมื่อ disable:
                      // color: Color(0xFF8B1CF5).withOpacity(_selected.isEmpty ? .5 : 1),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center, // << กันยืดสูง
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Total :',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '฿$totalPrice',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
              ),
          ),
        ),
      );
  }
}

/// 1 แถวของผังที่นั่ง (14 ปุ่ม/แถว)
class _SeatRow extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> rowDoc;
  final bool Function(String row, int no) isSelected;
  final void Function(String row, int no, bool isReserved, String type) onTapSeat;
  final Color Function({
    required bool isReserved,
    required bool isSelected,
    required String type,
  }) colorFor;

  const _SeatRow({
    required this.rowDoc,
    required this.isSelected,
    required this.onTapSeat,
    required this.colorFor,
  });

  static const int columns = 14; // ที่ต้องการต่อแถว
  static const double midAisleGap = 30; // ช่องไฟพิเศษระหว่าง E กับ F

  @override
  Widget build(BuildContext context) {
    final data = rowDoc.data();
    final row = (data['row'] ?? '').toString(); // "A".."I"
    final type = (data['type'] ?? 'Standard').toString(); // Standard/Premium/VIP

    // seatId อาจเป็น num หรือ string -> แปลงเป็น int อย่างปลอดภัย
    final List<int> seatIds = (data['seatId'] as List? ?? const [])
        .map((e) {
          if (e is num) return e.toInt();
          if (e is String) return int.tryParse(e) ?? -1;
          return -1;
        })
        .where((v) => v > 0)
        .toList();

    // สถานะ ("free"/"unreserved" = กดได้, อื่น ๆ = reserved)
    final List<String> statuses =
        (data['status'] as List? ?? const []).map((e) => (e ?? 'free').toString()).toList();

    // ปรับให้มี 14 ตำแหน่งเสมอ (ถ้าที่นั่งจริงน้อยกว่า จะเว้นช่องว่าง)
    final idsFixed = List<int?>.filled(columns, null);
    final stsFixed = List<String?>.filled(columns, null);
    for (var i = 0; i < columns && i < seatIds.length; i++) {
      idsFixed[i] = seatIds[i];
      stsFixed[i] = i < statuses.length ? statuses[i] : 'free';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // แทรกช่องไฟเฉพาะกรณีแถวนี้คือ E (ทำให้ระหว่าง E->F ห่างกัน)
        if (row.toUpperCase() == 'E') const SizedBox(height: midAisleGap),

        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ป้ายตัวอักษรแถว
            SizedBox(
              width: 28,
              child: Text(
                row,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 6),

            // พื้นที่ที่นั่ง
            Expanded(
              child: LayoutBuilder(
                builder: (ctx, cons) {
                  const double gap = 6; // ระยะห่างระหว่างปุ่ม
                  final double seatWidth =
                      ((cons.maxWidth - gap * (columns - 1)) / columns).clamp(20.0, 40.0);
                  final double seatHeight = seatWidth * 1.2;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(columns, (i) {
                      final id = idsFixed[i];

                      // ช่องว่าง (ไม่มีเก้าอี้ในตำแหน่งนี้)
                      if (id == null) {
                        return SizedBox(width: seatWidth, height: seatHeight);
                      }

                      final st = (stsFixed[i] ?? 'free').toLowerCase();
                      final reserved = !(st == 'free' || st == 'unreserved');
                      final selected = isSelected(row, id);
                      final type = (data['type'] ?? 'Standard').toString();

                      return GestureDetector(
                        onTap: () => onTapSeat(row, id, reserved, type),
                        child: Container(
                          width: seatWidth,
                          height: seatHeight,
                          decoration: BoxDecoration(
                            color: colorFor(
                              isReserved: reserved,
                              isSelected: selected,
                              type: type,
                            ),
                            borderRadius: const BorderRadius.all(Radius.circular(7)),
                            border: Border.all(
                              color: const Color.fromARGB(255, 0, 0, 0),
                              width: selected ? 2 : 1,
                            ),
                          ),
                          alignment: Alignment.center,

                          // 👇 แสดงไอคอนคน ทั้งกรณี reserved และ selected
                          child: reserved
                              ? const Icon(
                                  Icons.person,
                                  size: 18,
                                  color: Color.fromARGB(255, 255, 255, 255), // คนสีเทาจาง = จองแล้ว
                                )
                              : (selected
                                  ? const Icon(
                                      Icons.person,
                                      size: 14,
                                      color: Color(0xFFFF7676), // คนสีแดง = ผู้ใช้เลือก
                                    )
                                  : const SizedBox.shrink()),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
