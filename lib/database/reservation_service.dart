import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationService {
  /// path:
  ///   cinema/{cinemaId}/showtime/{showtimeId}/seat/{rowDoc}
  /// - selectedSeats: ["B9","B10", ...]
  static Future<void> reserveSeats({
    required String cinemaId,
    required String showtimeId,
    required List<String> selectedSeats,
  }) async {
    if (selectedSeats.isEmpty) return;

    // กลุ่มที่นั่งเป็นรายแถว:  { 'A': [9,10], 'C': [13], ... }
    final Map<String, List<int>> byRow = {};
    for (final key in selectedSeats) {
      final row = key.substring(0, 1);
      final no = int.parse(key.substring(1));
      (byRow[row] ??= []).add(no);
    }

    final showtimeRef = FirebaseFirestore.instance
        .collection('cinema')
        .doc(cinemaId)
        .collection('showtime')
        .doc(showtimeId);

    final seatCol = showtimeRef.collection('seat');

    await FirebaseFirestore.instance.runTransaction((tx) async {
      int changedCount = 0;

      for (final entry in byRow.entries) {
        final row = entry.key;
        final needNos = entry.value;

        final rowRef = seatCol.doc(row); // ✅ docId เป็นตัวอักษรแถว A,B,C,...
        final rowSnap = await tx.get(rowRef);
        if (!rowSnap.exists) {
          throw 'ไม่พบข้อมูลแถว $row';
        }

        final data = rowSnap.data() as Map<String, dynamic>;
        final seatIds = (data['seatId'] as List).cast<num>().map((e) => e.toInt()).toList();
        final statuses = (data['status'] as List).cast<String>();

        if (seatIds.length != statuses.length) {
          throw 'ข้อมูลที่นั่งแถว $row ไม่สอดคล้อง';
        }

        // ต้องยังเป็น unreserved ทั้งหมด
        for (final no in needNos) {
          final idx = seatIds.indexOf(no);
          if (idx < 0) throw 'ไม่พบที่นั่ง $row$no';
          if (statuses[idx].toLowerCase() != 'unreserved') {
            throw 'ที่นั่ง $row$no ถูกจองไปก่อนแล้ว';
          }
        }

        // อัปเดตเป็น reserved
        for (final no in needNos) {
          final idx = seatIds.indexOf(no);
          statuses[idx] = 'reserved';
          changedCount++;
        }

        tx.update(rowRef, {'status': statuses});
      }

      if (changedCount > 0) {
        tx.update(showtimeRef, {'seatsAvailable': FieldValue.increment(-changedCount)});
      }

      // (ออปชัน) สร้าง record การจอง
      final bookingRef = showtimeRef.collection('bookings').doc();
      tx.set(bookingRef, {
        'seats': selectedSeats,
        'status': 'reserved',                // หรือ 'paid'
        'amount': null,                      // จะใส่ตอน Pay จริงในหน้า Payment ก็ได้
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
