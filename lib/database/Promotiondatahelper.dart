import 'promotion_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Promotiondatahelper {
  final CollectionReference collection =
      FirebaseFirestore.instance.collection(PromotionModel.CollectionName);

  // insert a new payment (ใช้ uid จาก auth เป็นชื่อ document)
  Future<void> addPayment(PromotionModel payment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    await collection.doc(user.uid).set(payment.toJson());
  }

  // update an existing payment
  Future<void> updatePayment(String id, PromotionModel payment) async {
    return await collection.doc(id).update(payment.toJson());
  }


  // load all payments 
  Stream<QuerySnapshot> getStreamPayments() {
    return collection.snapshots();
  }

  // filter payments by month/year (เช่น "October 2025")
  Stream<QuerySnapshot> getStreamPaymentsByMonthYear(String monthYear) {
    return collection.where('month', isEqualTo: monthYear).snapshots();
  }
}
