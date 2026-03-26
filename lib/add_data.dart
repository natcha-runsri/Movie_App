// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// /// ปรับค่าได้ตามต้องการ
// const int kSeatsPerRow = 14;
// const seatConfig = <String, Map<String, dynamic>>{
//   'A': {'type': 'VIP', 'price': 400},
//   'B': {'type': 'PREMIUM', 'price': 250},
//   'C': {'type': 'PREMIUM', 'price': 250},
//   'D': {'type': 'PREMIUM', 'price': 250},
//   'E': {'type': 'PREMIUM', 'price': 250},
//   'F': {'type': 'STANDARD', 'price': 150},
//   'G': {'type': 'STANDARD', 'price': 150},
//   'H': {'type': 'STANDARD', 'price': 150},
//   'I': {'type': 'STANDARD', 'price': 150},
// };

// class SeedSelectorPage extends StatefulWidget {
//   const SeedSelectorPage({super.key});

//   @override
//   State<SeedSelectorPage> createState() => _SeedSelectorPageState();
// }

// class _SeedSelectorPageState extends State<SeedSelectorPage> {
//   String? _selectedShowtimeId;
//   String? _selectedScreenId;

//   final _manualShowtime = TextEditingController(); // ใส่เองได้
//   final _manualScreen   = TextEditingController();

//   bool _busy = false;

//   @override
//   void dispose() {
//     _manualShowtime.dispose();
//     _manualScreen.dispose();
//     super.dispose();
//   }

//   // ----- Data sources -----
//   Stream<List<String>> _showtimeIds() {
//     return FirebaseFirestore.instance
//         .collection('showtime')
//         .orderBy(FieldPath.documentId)
//         .snapshots()
//         .map((s) => s.docs.map((d) => d.id).toList());
//   }

//   Stream<List<String>> _screenIds(String showId) {
//     return FirebaseFirestore.instance
//         .collection('showtime').doc(showId)
//         .collection('screens')
//         .orderBy(FieldPath.documentId)
//         .snapshots()
//         .map((s) => s.docs.map((d) => d.id).toList());
//   }

//   // ----- Action -----
//   Future<void> _seedSeatsOnly({
//     required String showId,
//     required String screenId,
//   }) async {
//     final db = FirebaseFirestore.instance;
//     final batch = db.batch();

//     final seatIds =
//         List.generate(kSeatsPerRow, (i) => (i + 1).toString().padLeft(2, '0'));
//     final statuses = List.filled(kSeatsPerRow, 'unreserved');

//     for (final e in seatConfig.entries) {
//       final row = e.key;
//       final cfg = e.value;

//       final seatDoc = db
//           .collection('showtime').doc(showId)
//           .collection('screens').doc(screenId)
//           .collection('seats').doc(row);

//       batch.set(
//         seatDoc,
//         {
//           'row': row,
//           'type': cfg['type'],
//           'price': cfg['price'],
//           'seatId': seatIds,
//           'status': statuses,
//         },
//         SetOptions(merge: true), // ไม่ยุ่ง field อื่นของ screens/{screenId}
//       );
//     }
//     await batch.commit();
//   }

//   Future<void> _onSeedPressed() async {
//     // ให้ค่าจาก dropdown มีสิทธิก่อน ถ้าไม่ได้เลือก ใช้ที่พิมพ์เอง
//     var showId = _selectedShowtimeId ?? _manualShowtime.text.trim();
//     var screenId = _selectedScreenId ?? _manualScreen.text.trim();

//     if (showId.isEmpty || screenId.isEmpty) {
//       _toast('เลือกหรือกรอก showtime/screen ให้ครบก่อน');
//       return;
//     }

//     setState(() => _busy = true);
//     try {
//       await _seedSeatsOnly(showId: showId, screenId: screenId);
//       _toast('✅ Seed สำเร็จ → showtime/$showId/screens/$screenId/seats');
//     } catch (e) {
//       _toast('❌ Error: $e');
//     } finally {
//       if (mounted) setState(() => _busy = false);
//     }
//   }

//   void _toast(String msg) =>
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

//   // ----- UI -----
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Seed seats → เลือกปลายทาง')),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           // 1) เลือก showtime จาก Firestore
//           StreamBuilder<List<String>>(
//             stream: _showtimeIds(),
//             builder: (context, snap) {
//               final ids = snap.data ?? const <String>[];
//               return Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Expanded(
//                     child: DropdownButtonFormField<String>(
//                       isExpanded: true,
//                       value: _selectedShowtimeId != null &&
//                               ids.contains(_selectedShowtimeId)
//                           ? _selectedShowtimeId
//                           : null,
//                       items: ids
//                           .map((id) => DropdownMenuItem(
//                                 value: id,
//                                 child: Text(id),
//                               ))
//                           .toList(),
//                       onChanged: (v) {
//                         setState(() {
//                           _selectedShowtimeId = v;
//                           _selectedScreenId = null; // reset เมื่อเปลี่ยน showtime
//                         });
//                       },
//                       decoration: const InputDecoration(
//                         labelText: 'เลือก showtime (หรือกรอกเองด้านขวา)',
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   SizedBox(
//                     width: 220,
//                     child: TextField(
//                       controller: _manualShowtime,
//                       decoration: const InputDecoration(
//                         labelText: 'พิมพ์ showtime id เอง',
//                         border: OutlineInputBorder(),
//                         isDense: true,
//                       ),
//                     ),
//                   ),
//                 ],
//               );
//             },
//           ),

//           const SizedBox(height: 16),

//           // 2) เลือก screen จาก Firestore (ขึ้นกับ showtime ที่เลือก)
//           if (_selectedShowtimeId != null)
//             StreamBuilder<List<String>>(
//               stream: _screenIds(_selectedShowtimeId!),
//               builder: (context, snap) {
//                 final screens = snap.data ?? const <String>[];
//                 return Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       child: DropdownButtonFormField<String>(
//                         isExpanded: true,
//                         value: _selectedScreenId != null &&
//                                 screens.contains(_selectedScreenId)
//                             ? _selectedScreenId
//                             : null,
//                         items: screens
//                             .map((id) => DropdownMenuItem(
//                                   value: id,
//                                   child: Text(id),
//                                 ))
//                             .toList(),
//                         onChanged: (v) => setState(() {
//                           _selectedScreenId = v;
//                         }),
//                         decoration: const InputDecoration(
//                           labelText: 'เลือก screen (หรือกรอกเองด้านขวา)',
//                           border: OutlineInputBorder(),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     SizedBox(
//                       width: 220,
//                       child: TextField(
//                         controller: _manualScreen,
//                         decoration: const InputDecoration(
//                           labelText: 'พิมพ์ screen id เอง',
//                           border: OutlineInputBorder(),
//                           isDense: true,
//                         ),
//                       ),
//                     ),
//                   ],
//                 );
//               },
//             )
//           else
//             Row(
//               children: [
//                 const Expanded(
//                   child: Text(
//                     'เลือก showtime ก่อนเพื่อดึงรายการ screens อัตโนมัติ',
//                     style: TextStyle(color: Colors.white70),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 SizedBox(
//                   width: 220,
//                   child: TextField(
//                     controller: _manualScreen,
//                     decoration: const InputDecoration(
//                       labelText: 'หรือพิมพ์ screen id เลย',
//                       border: OutlineInputBorder(),
//                       isDense: true,
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//           const SizedBox(height: 24),

//           SizedBox(
//             height: 48,
//             child: FilledButton(
//               onPressed: _busy ? null : _onSeedPressed,
//               child: Text(_busy ? 'Working…' : 'Seed seats'),
//             ),
//           ),

//           const SizedBox(height: 12),
//           const Text(
//             'จะสร้าง/อัปเดต: showtime/{showId}/screens/{screenId}/seats/{A..I}\n'
//             'A=VIP:400, B–E=PREMIUM:250, F–I=STANDARD:150, status="unreserved"\n'
//             'หมายเหตุ: ไม่แก้ไข field อื่นของ screens/{screenId}',
//             style: TextStyle(color: Colors.white70),
//           ),
//         ],
//       ),
//     );
//   }
// }
