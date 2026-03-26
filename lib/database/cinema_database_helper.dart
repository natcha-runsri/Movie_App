import 'package:cloud_firestore/cloud_firestore.dart';
import 'cinema_model.dart';

class CinemaDatabase {
  final CollectionReference<CinemaModel> _col =
      FirebaseFirestore.instance
          .collection(CinemaModel.collection)
          .withConverter<CinemaModel>(
            fromFirestore: (snap, _) => CinemaModel.fromMap(snap.data()!, snap.id),
            toFirestore: (c, _) => c.toMap(),
          );

  /// อ่านทั้งหมด (เรียงตามชื่อ)
  Stream<List<CinemaModel>> streamAll() => _col
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()).toList());

  Future<List<CinemaModel>> getAllOnce() async =>
      (await _col.orderBy('name').get())
          .docs
          .map((d) => d.data())
          .toList();

  /// เพิ่มใหม่และคืน ref (เอา id ไปใช้ต่อได้)
  Future<DocumentReference<CinemaModel>> add(CinemaModel c) => _col.add(c);

  /// อ่าน 1 รายการตาม id
  Future<CinemaModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    return doc.data();
  }

  /// ฟัง 1 รายการตาม id (เรียลไทม์)
  Stream<CinemaModel?> streamById(String id) =>
      _col.doc(id).snapshots().map((d) => d.data());

  /// สร้าง/ทับ ด้วย id ที่กำหนดเอง
  Future<void> set(String id, CinemaModel c) => _col.doc(id).set(c);

  /// อัปเดตเฉพาะฟิลด์ (ส่งเฉพาะที่อยากแก้)
  Future<void> update(String id, Map<String, dynamic> data) =>
      _col.doc(id).update(data);

  /// ลบ
  Future<void> delete(String id) => _col.doc(id).delete();

  /// ค้นหาด้วย prefix (แนะนำให้เก็บ field `nameLower` ในเอกสาร)
  Future<List<CinemaModel>> searchByNamePrefix(String q, {int limit = 20}) async {
    if (q.isEmpty) return [];
    final start = q.toLowerCase();
    final end = '$start\uf8ff';
    final snap = await _col
        .orderBy('nameLower')
        .startAt([start])
        .endAt([end])
        .limit(limit)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }
}
