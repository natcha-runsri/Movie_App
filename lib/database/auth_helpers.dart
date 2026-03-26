// lib/utils/auth_helpers.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login&register_page/loginpage.dart'; // <-- แก้ path ให้ตรงโปรเจ็กต์ของคุณ

Future<void> signOutAndClearCache(BuildContext context) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  await FirebaseAuth.instance.signOut();

  if (uid != null) {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('profile_${uid}_name');
    await sp.remove('profile_${uid}_dob');
    await sp.remove('profile_${uid}_address');
    await sp.remove('profile_${uid}_tel');
    await sp.remove('profile_${uid}_email');
  }

  if (context.mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Loginpage()),
      (route) => false,
    );
  }
}
