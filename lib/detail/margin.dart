import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ย้ายข้อมูลจาก profile/1 ไปที่ profile/{uid ของผู้ใช้ที่ล็อกอิน}
Future<void> migrateProfileDocToUid() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('User not logged in');
  }
  final uid = user.uid;

  final DocumentReference<Map<String, dynamic>> src =
      FirebaseFirestore.instance.collection('profile').doc('1');
  final DocumentReference<Map<String, dynamic>> dst =
      FirebaseFirestore.instance.collection('profile').doc(uid);

  final DocumentSnapshot<Map<String, dynamic>> snap = await src.get();
  if (!snap.exists) {
    // ไม่มี profile/1 ก็จบ
    return;
  }

  final Map<String, dynamic> data = Map<String, dynamic>.from(snap.data()!);
  data['uid'] = uid;
  data['migratedAt'] = FieldValue.serverTimestamp();

  await dst.set(data, SetOptions(merge: true)); // เขียนทับ/ผสาน
  await src.delete();                           // ลบของเดิม
}
