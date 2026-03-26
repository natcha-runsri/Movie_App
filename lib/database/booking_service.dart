import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookingService {
  final _db = FirebaseFirestore.instance;
  
  /// บันทึกการจอง + เปลี่ยนสถานะที่นั่งเป็น reserved แบบ atomic
  /// [screenRef] = showtimes/{slotId}/screens/{screenId}
  Future<String> confirmBooking({
    required String uid,
    required DocumentReference<Map<String, dynamic>> screenRef,
    required String movieId,
    required String movieTitle,
    required String cinemaId,
    required String cinemaName,
    required String screenId,
    required DateTime showDate,
    required String showTime,
    required List<String> seats,         // ["B9","B10"]
    required int pricePerSeat,
    required String seatType,            // ถ้าคละ type ให้คำนวณเองเป็น items
    int discount = 0,
    required String phone, 
    required String posterUrl,
  }) async {
    if (seats.isEmpty) {
      throw StateError('No seats selected');
    }

    final dateKey = DateFormat('yyyy-MM-dd').format(showDate);
    final subTotal = seats.length * pricePerSeat;
    final total = (subTotal - discount).clamp(0, 1 << 31);

    // จัดกลุ่มที่นั่งตามแถวเพื่ออัปเดตเอกสาร row เดียวต่อแถว
    Map<String, List<int>> byRow = {};
    for (final s in seats) {
      final row = s.substring(0, 1).toUpperCase();
      final no = int.tryParse(s.substring(1)) ?? -1;
      if (no > 0) (byRow[row] ??= <int>[]).add(no);
    }

    // path bookings ของ user
    final bookingRef = _db.collection('profile').doc(uid)
        .collection('bookings').doc();

    await _db.runTransaction((tx) async {
      // 1) ตรวจและล็อกที่นั่ง
      for (final entry in byRow.entries) {
        final rowId = entry.key; // "A","B",...
        final rowRef = screenRef.collection('seats').doc(rowId);
        final rowSnap = await tx.get(rowRef);
        if (!rowSnap.exists) {
          throw StateError('Row ${entry.key} not found');
        }
        final data = rowSnap.data() as Map<String, dynamic>;
        final List seatIds = (data['seatId'] as List? ?? const []);
        final List statuses = (data['status'] as List? ?? const []);

        // เตรียมสำเนาสถานะใหม่
        final List newStatuses = List.of(statuses);

        for (final no in entry.value) {
          final idx = seatIds.indexWhere((e) => (e is num ? e.toInt() : int.tryParse(e.toString()) ?? -1) == no);
          if (idx < 0) {
            throw StateError('Seat $rowId$no not found');
          }
          final cur = (idx < statuses.length ? statuses[idx] : 'free').toString().toLowerCase();
          final isFree = (cur.isEmpty || cur == 'free' || cur == 'unreserved' || cur == 'available' || cur == 'open' || cur == 'false');
          if (!isFree) {
            throw StateError('Seat $rowId$no already reserved');
          }
          if (idx >= newStatuses.length) {
            // ถ้า array สั้น เติมจนถึง idx
            newStatuses.length = idx + 1;
          }
          newStatuses[idx] = 'reserved';
        }

        tx.update(rowRef, {'status': newStatuses});
      }

      // 2) เขียนเอกสารการจองของผู้ใช้
      tx.set(bookingRef, {
        'userId': uid,
        'movieId': movieId,
        'movieTitle': movieTitle,
        'cinemaId': cinemaId,
        'cinemaName': cinemaName,
        'screenId': screenId,
        'dateKey': dateKey,
        'time': showTime,
        'seats': seats,
        'pricePerSeat': pricePerSeat,
        'subtotal': subTotal,
        'discount': discount,
        'total': total,
        'seatType': seatType,
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
        // เก็บอ้างอิงไว้เผื่อย้อนกลับ
        'screenRef': screenRef,
        'phone': phone,
        'posterUrl': posterUrl,
      });
    });

    return bookingRef.id; // ส่ง bookingId กลับไป
  }
}
