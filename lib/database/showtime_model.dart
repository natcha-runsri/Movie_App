import 'package:cloud_firestore/cloud_firestore.dart';

/// 1) เอกสาร showtimes/{slotId}
///    แทน "slot เวลา" หนึ่งอัน = (movieId + cinemaId + dateKey + time)
class ShowtimeModel{
  final String movieId;
  final String movieTitle;
  final String cinemaId;
  final String cinemaName;
  final String dateKey;   // YYYY-MM-DD
  final String time;      // HH:mm (24h)
  final Timestamp? showDate; // ใช้สำหรับ query ช่วงวัน (ตั้งค่าเป็น 00:00 น.)

  ShowtimeModel({

    required this.movieId,
    required this.movieTitle,
    required this.cinemaId,
    required this.cinemaName,
    required this.dateKey,
    required this.time,
    this.showDate,
  });

  /// แนะนำให้ใช้ slotId แบบ deterministic: c_{cinemaId}_m_{movieId}_{dateKey}_{HHmm}
  String get slotId =>
      'c_${cinemaId}_m_${movieId}_${dateKey}_${time.replaceAll(":", "")}';

  Map<String, dynamic> toMap() => {
        'movieId': movieId,
        'movieTitle': movieTitle,
        'cinemaId': cinemaId,
        'cinemaName': cinemaName,
        'dateKey': dateKey,
        'time': time,
        if (showDate != null) 'showDate': showDate,
      };

  factory ShowtimeModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ShowtimeModel(
      movieId: d['movieId'] ?? '',
      movieTitle: d['movieTitle'] ?? '',
      cinemaId: d['cinemaId'] ?? '',
      cinemaName: d['cinemaName'] ?? '',
      dateKey: d['dateKey'] ?? '',
      time: d['time'] ?? '',
      showDate: d['showDate'],
    );
  }
}

/// 2) เอกสาร showtimes/{slotId}/screens/{screenId}
///    ห้องฉายใน slot เวลาเดียวกัน (duplicate key สำคัญเพื่อให้ collectionGroup ค้นได้ง่าย)
class ScreenShowtime {
  final String screenId;   // "1","2"
  final String audio;      // "TH","EN"
  final String format;     // "2D","3D"
  final int basePrice;

  // duplicate keys สำหรับ query collectionGroup
  final String movieId;
  final String cinemaId;
  final String dateKey;

  /// หลายเวลาในเอกสารเดียว
  final List<String> time;

  ScreenShowtime({
    required this.screenId,
    required this.audio,
    required this.format,
    required this.basePrice,
    required this.movieId,
    required this.cinemaId,
    required this.dateKey,
    required this.time,
  });

  // ── helper ปรับรูปแบบเวลาให้เป็น HH:mm ──
  static String _norm(String s) {
    final t = s.trim();
    final noAp = t.replaceAll(RegExp(r'\s?(AM|PM)$', caseSensitive: false), '');
    final m = RegExp(r'^(\d{1,2})(?::(\d{1,2}))?$').firstMatch(noAp);
    if (m == null) return noAp;
    final h = m.group(1)!.padLeft(2, '0');
    final mm = (m.group(2) ?? '00').padLeft(2, '0');
    return '$h:$mm';
  }

  /// 👉 ใช้ตัวนี้ตอนเขียนขึ้น Firestore (ที่ service เรียกอยู่)
  Map<String, dynamic> toMap() => {
        'screenId': screenId,
        'audio': audio,
        'format': format,
        'basePrice': basePrice,
        'movieId': movieId,
        'cinemaId': cinemaId,
        'dateKey': dateKey,
        'time': time.map(_norm).toList(), // บันทึกเป็นลิสต์ของ HH:mm
      };

  /// อ่านกลับจาก Firestore แบบกัน null/ชนิดข้อมูล
  factory ScreenShowtime.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};

    final bpRaw = d['basePrice'];
    final int safeBasePrice = bpRaw is int
        ? bpRaw
        : bpRaw is num
            ? bpRaw.toInt()
            : (bpRaw is String && bpRaw.trim().isNotEmpty
                ? int.tryParse(bpRaw.trim()) ?? 0
                : 0);

    final times = (d['time'] as List? ?? const [])
        .map((e) => _norm(e.toString()))
        .where((s) => s.isNotEmpty)
        .toList();

    return ScreenShowtime(
      screenId: (d['screenId'] ?? '').toString(),
      audio: (d['audio'] ?? 'TH').toString(),
      format: (d['format'] ?? '2D').toString(),
      basePrice: safeBasePrice,
      movieId: (d['movieId'] ?? '').toString(),
      cinemaId: (d['cinemaId'] ?? '').toString(),
      dateKey: (d['dateKey'] ?? '').toString(),
      time: times,
    );
  }
}



/// 3) เอกสารที่นั่งหนึ่ง "แถว" ใต้ showtimes/{slotId}/screens/{screenId}/seats/{row}
class SeatRowModel {
  final String row;          // "A"
  final String type;         // "Standard" | "Premium" | "VIP"
  final int price;           // ราคาของแถวนี้
  final List<String> seatId;    // [1,2,3,...]
  final List<String> status; // ["free"|"reserved"|...]

  SeatRowModel({
    required this.row,
    required this.type,
    required this.price,
    required this.seatId,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
        'row': row,
        'type': type,
        'price': price,
        'seatId': seatId,
        'status': status,
      };

  factory SeatRowModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final d = doc.data() ?? {};

  final prRaw = d['price'];
  final int safePrice = prRaw is int
      ? prRaw
      : prRaw is num
          ? prRaw.toInt()
          : (prRaw is String && prRaw.trim().isNotEmpty
              ? int.tryParse(prRaw.trim()) ?? 0
              : 0);

  final List<String> ids = (d['seatId'] as List? ?? const [])
      .whereType<String>()
      .map((e) => e.toString())
      .toList();

  final List<String> sts = (d['status'] as List? ?? const [])
      .map((e) => (e ?? 'free').toString())
      .toList();

  return SeatRowModel(
    row: (d['row'] ?? '').toString(),
    type: (d['type'] ?? 'Standard').toString(),
    price: safePrice,
    seatId: ids,
    status: sts,
  );
}

}
