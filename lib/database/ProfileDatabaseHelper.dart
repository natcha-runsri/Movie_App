// profile_database_helper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_model_service.dart'; // มี ProfileModel.fromMap / toMap

class ProfileDatabaseHelper {
  final _db = FirebaseFirestore.instance;
  late final CollectionReference<ProfileModel> _col;

  ProfileDatabaseHelper() {
    _col = _db.collection('profile').withConverter<ProfileModel>(
      fromFirestore: (snap, _) {
        final raw = snap.data() ?? <String, dynamic>{};
        // บังคับ uid = doc.id ให้ตรงกับเจ้าของเสมอ
        final m = {...raw, 'uid': snap.id};
        return ProfileModel.fromMap(m);
      },
      toFirestore: (p, _) => p.toMap(),
    );
  }

  // ────────────────── Generic by UID ──────────────────
  DocumentReference<ProfileModel> docRef(String uid) => _col.doc(uid);

  Future<void> set(ProfileModel profile) => docRef(profile.uid).set(profile);

  Future<void> upsert(ProfileModel profile) =>
      docRef(profile.uid).set(profile, SetOptions(merge: true));

  Future<ProfileModel?> getById(String uid) async {
    final doc = await docRef(uid).get();
    return doc.data();
  }

  Stream<ProfileModel?> streamById(String uid) =>
      docRef(uid).snapshots().map((s) => s.data());

  Future<void> update(
    String uid, {
    String? name,
    String? birthdate,
    String? contact,
    String? tel,
    String? email,
    String? images,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (birthdate != null) data['birthdate'] = birthdate;
    if (contact != null) data['contact'] = contact;
    if (tel != null) data['tel'] = tel;
    if (email != null) data['email'] = email;
    if (images != null) data['images'] = images;
    if (data.isEmpty) return;
    data['updatedAt'] = FieldValue.serverTimestamp();
    await docRef(uid).update(data);
  }

  Future<void> delete(String uid) => docRef(uid).delete();

  Future<bool> exists(String uid) async => (await docRef(uid).get()).exists;

  // ───────────── Helpers for CURRENT USER (Auth) ─────────────
  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  /// สร้าง/อัปเดตโปรไฟล์ของผู้ใช้ที่ล็อกอินอยู่ (merge)
  Future<void> upsertCurrentUser(ProfileModel profile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final data = {
      ...profile.toMap(), // ถ้าใน model ชื่อ toMap/ toJson ปรับตามจริง
      'uid': user.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _db.collection('profile').doc(user.uid).set(data, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw Exception('Firestore error: ${e.code} ${e.message ?? ""}');
    }
  }

  /// อ่านโปรไฟล์ของผู้ใช้ปัจจุบันครั้งเดียว (แบบ model)
  Future<ProfileModel?> getCurrent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await docRef(user.uid).get();
    return doc.data();
  }

  /// stream โปรไฟล์ของผู้ใช้ปัจจุบัน (เรียลไทม์)
  Stream<ProfileModel?> streamCurrent() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return docRef(user.uid).snapshots().map((s) => s.data());
  }

  /// อัปเดตเฉพาะฟิลด์ของผู้ใช้ปัจจุบัน
  Future<void> updateCurrent({
    String? name,
    String? birthdate,
    

    String? tel,
    String? email,
    String? images,
    String? contact,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    await update(
      user.uid,
      name: name,
      birthdate: birthdate,
      contact: contact,
      tel: tel,
      email: email,
      images: images,
    );
  }

  /// ลบโปรไฟล์ของผู้ใช้ปัจจุบัน
  Future<void> deleteCurrent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    await delete(user.uid);
  }

  /// สร้างโปรไฟล์เริ่มต้นให้ผู้ใช้ที่เพิ่งล็อกอิน (ถ้ายังไม่มี)
  Future<void> ensureForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    if (await exists(uid)) return;

    final p = ProfileModel(
      uid: uid,
      name: user.displayName ?? '',
      birthdate: '',
      contact: '',
      tel: '',
      email: user.email ?? '',
      images: user.photoURL ?? '',
    );
    await set(p);
  }

  /// สร้างครั้งแรกเท่านั้น (กันเขียนทับ)
  Future<void> createIfAbsent(ProfileModel profile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    final ref = docRef(user.uid);
    if ((await ref.get()).exists) return;
    final data = {
      ...profile.toMap(),
      'uid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    };
    await _db.collection('profile').doc(user.uid).set(data);
  }

  
}
