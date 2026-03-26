import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'showtime_model.dart';

class ShowtimesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _slots =>
      _db.collection('showtime');

  /// สร้าง/อัปเดต Slot (id deterministic)
  Future<DocumentReference<Map<String, dynamic>>> upsertSlot(ShowtimeModel slot) async {
    final ref = _slots.doc(slot.slotId);
    await ref.set(slot.toMap(), SetOptions(merge: true));
    return ref;
  }

  /// เพิ่ม/อัปเดต Screen ใต้ slot
  Future<DocumentReference<Map<String, dynamic>>> upsertScreen({
    required String slotId,
    required ScreenShowtime screen,
  }) async {
    final ref = _slots.doc(slotId).collection('screens').doc(screen.screenId);
    await ref.set(screen.toMap(), SetOptions(merge: true));
    return ref;
  }

  

  /// ดึง slot ตาม (movieId, cinemaId, dateKey) — ใช้บนหน้าเลือกเวลา
  Stream<QuerySnapshot<Map<String, dynamic>>> streamSlotsByMovieCinemaDate({
    required String movieId,
    required String cinemaId,
    required String dateKey,
  }) {
    return _slots
        .where('movieId', isEqualTo: movieId)
        .where('cinemaId', isEqualTo: cinemaId)
        .where('dateKey', isEqualTo: dateKey)
        .orderBy('time')
        .snapshots();
  }

  /// ดึง screens ของ slot หนึ่ง (เวลาเดียวกัน หลายห้อง)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamScreensOfSlot(String slotId) {
    return _slots
        .doc(slotId)
        .collection('screens')
        .orderBy('screenId')
        .snapshots();
  }

  /// (ทางลัด) หา screen doc โดยไม่รู้ slotId ด้วย collectionGroup (ต้อง duplicate keys ใน ScreenShowtime)
  Future<DocumentSnapshot<Map<String, dynamic>>?> findScreenDoc({
    required String movieId,
    required String cinemaId,
    required String dateKey,
    required String time,
    required String screenId,
  }) async {
    final qs = await _db
        .collectionGroup('screens')
        .where('movieId', isEqualTo: movieId)
        .where('cinemaId', isEqualTo: cinemaId)
        .where('dateKey', isEqualTo: dateKey)
        .where('time', isEqualTo: time)
        .where('screenId', isEqualTo: screenId)
        .limit(1)
        .get();

    if (qs.docs.isEmpty) return null;
    return qs.docs.first;
  }

  /// ผังที่นั่ง (ทุกแถว) ของ screen หนึ่ง
  Stream<QuerySnapshot<Map<String, dynamic>>> streamSeatRows({
    required String slotId,
    required String screenId,
  }) {
    return _slots
        .doc(slotId)
        .collection('screens')
        .doc(screenId)
        .collection('seats')
        .orderBy('row') // A,B,C...
        .snapshots();
  }

  /// สร้างแถวที่นั่งเริ่มต้น
  Future<void> seedSeatRow({
    required String slotId,
    required String screenId,
    required SeatRowModel row,
  }) async {
    await _slots
        .doc(slotId)
        .collection('screens')
        .doc(screenId)
        .collection('seats')
        .doc(row.row)
        .set(row.toMap(), SetOptions(merge: false));
  }

  /// จองที่นั่ง: ตรวจแล้ว mark เป็น "reserved" (transaction)
  /// seatNos = หมายเลขที่นั่งที่จะจองในแถวนั้น เช่น [5,6]
  Future<void> reserveSeats({
    required String slotId,
    required String screenId,
    required String row,
    required List<int> seatNos,
  }) async {
    final rowRef = _slots
        .doc(slotId)
        .collection('screens')
        .doc(screenId)
        .collection('seats')
        .doc(row);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(rowRef);
      if (!snap.exists) {
        throw StateError('Seat row $row not found');
      }

      final data = snap.data() as Map<String, dynamic>;
      final seatId = (data['seatId'] as List).map((e) => (e as num).toInt()).toList();
      final status = (data['status'] as List).map((e) => e.toString()).toList();

      // ตรวจทุกที่นั่งต้องยัง free
      for (final n in seatNos) {
        final idx = seatId.indexOf(n);
        if (idx < 0) {
          throw StateError('Seat $row$n not found');
        }
        if (status[idx].toLowerCase() != 'free') {
          throw StateError('Seat $row$n already reserved');
        }
      }

      // Mark reserved
      for (final n in seatNos) {
        final idx = seatId.indexOf(n);
        status[idx] = 'reserved';
      }

      tx.update(rowRef, {'status': status});
    });
  }

  /// ยกเลิกการจอง (ปล่อยที่นั่งกลับเป็น free)
  Future<void> releaseSeats({
    required String slotId,
    required String screenId,
    required String row,
    required List<int> seatNos,
  }) async {
    final rowRef = _slots
        .doc(slotId)
        .collection('screens')
        .doc(screenId)
        .collection('seats')
        .doc(row);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(rowRef);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final seatId = (data['seatId'] as List).map((e) => (e as num).toInt()).toList();
      final status = (data['status'] as List).map((e) => e.toString()).toList();

      for (final n in seatNos) {
        final idx = seatId.indexOf(n);
        if (idx >= 0) status[idx] = 'free';
      }

      tx.update(rowRef, {'status': status});
    });
  }
  // เรียกรายการ screens ของ "หนัง+สาขา+วัน" เดียว (ใช้ collectionGroup)
Stream<List<ScreenShowtime>> streamScreensByMovieCinemaDate({
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

}

