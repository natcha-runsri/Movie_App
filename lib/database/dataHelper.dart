import 'package:cloud_firestore/cloud_firestore.dart';
import 'Moviemodel.dart'; // แนะนำเปลี่ยนชื่อไฟล์เป็น movie_model.dart ในภายหลัง

class MovieDatabaseHelper {
  final _db = FirebaseFirestore.instance;
  late final CollectionReference<MovieModel> _col;

  MovieDatabaseHelper() {
    _col = _db.collection(MovieModel.CollectionName).withConverter<MovieModel>(
      fromFirestore: (snap, _) => MovieModel.fromMap(snap.data()!, snap.id),
      toFirestore: (movie, _) => movie.toMap(),
    );
  }

  // CREATE: เพิ่มหนังใหม่ (ให้ Firestore สร้าง id)
  Future<DocumentReference<MovieModel>> add(MovieModel movie) async {
    // ถ้าจะใช้ searchByNamePrefix ที่อิง nameLower:
    // ให้แน่ใจว่า movie.toMap() ใส่ 'nameLower': movie.name.toLowerCase()
    return _col.add(movie);
  }

  // CREATE/REPLACE: เซ็ตด้วย id ที่กำหนดเอง (เขียนทับทั้งเอกสาร)
  Future<void> set(String id, MovieModel movie) {
    return _col.doc(id).set(movie);
  }

  // READ: ดึงเอกสารเดี่ยว
  Future<MovieModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    return doc.data();
  }

  // READ (stream): เอกสารเดี่ยวแบบเรียลไทม์
  Stream<MovieModel?> streamById(String id) {
    return _col.doc(id).snapshots().map((s) => s.data());
  }

  // READ (stream): ทั้งคอลเลกชัน เรียงตาม date (ล่าสุดก่อน)
  Stream<List<MovieModel>> streamAll({int? limit, bool descending = true}) {
    Query<MovieModel> q = _col.orderBy('date', descending: descending);
    if (limit != null) q = q.limit(limit);
    return q.snapshots().map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  // UPDATE: อัปเดตเฉพาะฟิลด์ที่ต้องการ
  Future<void> update(
    String id, {
    String? name,
    String? description,
    String? images,
    int? time,
    DateTime? date,
    List<String>? type,
    List<String>? cast,
    List<String>? cast_images,
    String? status,
    String? trailer,
    String? director,
    String? direc_images,
  }) {
    final data = <String, dynamic>{};
    if (name != null) {
      data['name'] = name;
      // ถ้าใช้ nameLower สำหรับค้นหา ให้อัปเดตด้วย
      data['nameLower'] = name.toLowerCase();
    }
    if (description != null) data['description'] = description;
    if (images != null) data['images'] = images;
    if (time != null) data['time'] = time;
    if (date != null) data['date'] = date;
    if (type != null) data['type'] = type;
    if (cast != null) data['cast'] = cast;
    if (cast_images != null) data['cast_image'] = cast_images;
    if (status != null) data['status'] = status;
    if (trailer != null) data['trailer'] = trailer;
    if (director != null) data['director'] = director;
    if (direc_images != null) data['direc_images'] = direc_images;

    if (data.isEmpty) return Future.value(); // ไม่มีอะไรให้แก้
    return _col.doc(id).update(data);
  }

  // DELETE: ลบเอกสาร
  Future<void> delete(String id) {
    return _col.doc(id).delete();
  }

  // FILTER (stream): ตามประเภท (อย่างน้อยชนิดหนึ่งในรายการ)
  // ใช้ array-contains-any → อาจต้องสร้าง index ถ้ามี orderBy ร่วม
  Stream<List<MovieModel>> streamByTypes(
    List<String> types, {
    int? limit,
    bool descending = true,
  }) {
    Query<MovieModel> q = _col
        .where('type', arrayContainsAny: types)
        .orderBy('date', descending: descending);
    if (limit != null) q = q.limit(limit);
    return q.snapshots().map((s) => s.docs.map((d) => d.data()).toList());
  }

  // FILTER (stream): ตามช่วงเวลา [start, end)
  Stream<List<MovieModel>> streamByDateRange(
    DateTime start,
    DateTime end, {
    int? limit,
    bool descending = true,
  }) {
    Query<MovieModel> q = _col
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .orderBy('date', descending: descending);
    if (limit != null) q = q.limit(limit);
    return q.snapshots().map((s) => s.docs.map((d) => d.data()).toList());
  }

  // SEARCH: ค้นหา prefix (แนะนำให้เก็บฟิลด์ nameLower ในเอกสาร)
  Future<List<MovieModel>> searchByNamePrefix(
    String queryText, {
    int limit = 20,
  }) async {
    if (queryText.isEmpty) return [];
    final q = queryText.toLowerCase();
    final end = '$q\uf8ff';

    final snap = await _col
        .orderBy('nameLower') // ต้องมีในเอกสาร
        .startAt([q])
        .endAt([end])
        .limit(limit)
        .get();

    return snap.docs.map((d) => d.data()).toList();
  }

  // PAGINATION: ดึงทีละหน้า
  Future<QuerySnapshot<MovieModel>> fetchPage({
    int pageSize = 10,
    DocumentSnapshot<MovieModel>? startAfterDoc,
  }) {
    Query<MovieModel> q =
        _col.orderBy('date', descending: true).limit(pageSize);
    if (startAfterDoc != null) q = q.startAfterDocument(startAfterDoc);
    return q.get();
  }
  
}