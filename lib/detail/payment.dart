import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/booking_service.dart';
import 'myticket.dart';

class PaymentPage extends StatefulWidget {
  final String movieTitle;
  final String posterUrl;
  final String audio;            // "TH" | "EN"
  final String cinemaName;       // สาขา
  final String screenId;         // ห้อง
  final DateTime showDate;       // วันที่ฉาย (local)
  final String showTime;         // "HH:mm"
  final List<String> selectedSeats; // เช่น ["B9","B10"]
  final String seatType;         // Standard | Premium | VIP (แสดงทางขวา)
  final int pricePerSeat;     
  final DocumentReference<Map<String, dynamic>> screenRef;
  final String movieId;
  final String cinemaId;
  final String phone;
   // ราคา/ที่นั่ง

  const PaymentPage({
    super.key,
    required this.movieTitle,
    required this.posterUrl,
    required this.audio,
    required this.cinemaName,
    required this.screenId,
    required this.showDate,
    required this.showTime,
    required this.selectedSeats,
    required this.seatType,
    required this.pricePerSeat,
    required this.screenRef,
    required this.movieId,
    required this.cinemaId,
    required this.phone,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const gold = Color(0xFFF4C23E);
  static const tileBg = Color(0xFF0F0F0F);

  final _email = TextEditingController();
  String? _appliedCode;
  int _discountBaht = 0;

  String _fmtDate(DateTime d) =>
      DateFormat('d MMM yyyy', 'en_US').format(d);

  String _fmtBaht(num n) =>
      '฿${NumberFormat('#,###').format(n)}';

  int get _qty => widget.selectedSeats.length;

  int get _subtotal => _qty * widget.pricePerSeat;

  int get _total => (_subtotal - _discountBaht).clamp(0, 1 << 31);
  

  
  Future<void> _openDiscount() async {
    final controller = TextEditingController(text: _appliedCode ?? '');
    final code = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black,
        titleTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        contentTextStyle: const TextStyle(color: Colors.white70),
        title: const Text('Apply discount'),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter code (e.g. MOVIE10)',
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white54),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim().toUpperCase()),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (!mounted || code == null) return;

    // ตัวอย่างกติกา:
    // MOVIE10  => ลด 10%
    // FLAT50   => ลด 50 บาท
    int discount = 0;
    if (code == 'MOVIE10') {
      discount = (_subtotal * 0.10).round();
    } else if (code == 'FLAT50') {
      discount = 50;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid code')),
      );
      return;
    }

    setState(() {
      _appliedCode = code;
      _discountBaht = discount;
    });
  }

Future<void> _showPaySheet() async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PaymentChannelSheet(
      total: _total.toDouble(),
      onPay: () async {
        Navigator.pop(context);   // ปิดป็อปอัปก่อน
        await _confirmAndLockSeats(); // แล้วค่อยยืนยันจอง
      },
    ),
  );
}

Future<void> _confirmAndLockSeats() async {
  try {
    // ensure login (guest ก็ได้)
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }

    final bookingId = await BookingService().confirmBooking(
      uid: auth.currentUser!.uid,
      screenRef: widget.screenRef,      // 🔹 ใช้อันที่ส่งมาจาก SeatPage
      movieId: widget.movieId,
      movieTitle: widget.movieTitle,
      cinemaId: widget.cinemaId,
      cinemaName: widget.cinemaName,
      screenId: widget.screenId,
      showDate: widget.showDate,
      showTime: widget.showTime,
      seats: widget.selectedSeats,       // ["B9","B10"]
      pricePerSeat: widget.pricePerSeat, // ถ้าเลือกหลาย type ให้ปรับ service ภายหลัง
      seatType: widget.seatType,
      discount: _discountBaht,          // ถ้ามีส่วนลดจากหน้าจอนี้
      phone: widget.phone,
      posterUrl: widget.posterUrl,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Booked! #$bookingId')),
    );

    // TODO: ไปหน้า Ticket / หรือปิดแล้วไปหน้า History
      Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const MyTicketsPage()),
  );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Booking failed: $e')),
    );
  }
}

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = Colors.black;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white,size: 35,),
          onPressed: () => Navigator.pop(context),
        ),
        title: Center(
         child: Text(
          'Payment',
          style: TextStyle(
            color: Colors.amber,
            fontWeight: FontWeight.w900,
            fontSize: 30,
            letterSpacing: .2,
          ),
        ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15,),
            // Header card (poster + info)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color.fromARGB(88, 167, 159, 159), // สีเส้นกรอบ
                        width: 1, // ความหนาเส้น
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.network(
                      widget.posterUrl,
                      width: 120,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(width: 120, height: 160, color: Colors.white10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.movieTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 20,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(FontAwesomeIcons.volumeLow, color: Colors.white54, size: 12),
                          const SizedBox(width: 6),
                          Text(widget.audio, style: const TextStyle(color: Colors.white70,fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Text('Cinema', style: const TextStyle(color: Colors.white70,fontSize: 14),),
                      const SizedBox(height: 8),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: gold, size: 16),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              widget.cinemaName,
                              style: const TextStyle(
                                color: Colors.white, 
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Row(
                          children: [
                            const SizedBox(width: 15),
                            Text('Date', style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14
                              ),
                            ),
                           const SizedBox(width: 120),
                            Text("Time",style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14
                              ),
                            ),
                          ],
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const SizedBox(width: 5),
                          const Icon(Icons.calendar_today, color: Colors.white54, size: 14),
                          const SizedBox(width: 6),
                          Text(_fmtDate(widget.showDate),
                              style: const TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255),
                                fontWeight: FontWeight.w700,
                              )
                            ),
                          const SizedBox(width: 50),
                          const Icon(Icons.access_time, color: Colors.white54, size: 14),
                          const SizedBox(width: 6),
                          Text(widget.showTime,
                              style: const TextStyle(
                                 color: Color.fromARGB(255, 255, 255, 255),
                                 fontWeight: FontWeight.w700,
                                )
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12, height: 24),

            // Check block
            const Text('Check',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 10),

            _colLine(
              label: 'Selected Seats',
              value: widget.selectedSeats.isEmpty
                  ? '-'
                  : widget.selectedSeats.join(' , '),
              trailing: widget.seatType,
            ),
            const SizedBox(height: 16),

            _rowLine(label: 'Quantity', value: '$_qty'),
            const SizedBox(height: 16),

            // Discount
            const Text('Discount', style: TextStyle(
              color: Colors.white70, 
              fontWeight: FontWeight.w700,
              fontSize: 16,
              )
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _openDiscount,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: gold, width: 1.2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      _appliedCode == null ? 'Apply Discount' : '$_appliedCode  (-${_fmtBaht(_discountBaht)})',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Email
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: const TextStyle(color: Color.fromARGB(141, 255, 255, 255)),
                filled: true,
                fillColor: tileBg,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color.fromARGB(96, 255, 255, 255)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color.fromARGB(111, 255, 255, 255)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text('we will send confirmation',
                style: TextStyle(color: Colors.white30, fontSize: 12)),

            const SizedBox(height: 18),

            // Total bar
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 30, 39, 134),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Text('Total', style: TextStyle(
                    color: Colors.amber, 
                    fontWeight: FontWeight.w800,
                    fontSize: 18
                    )
                  ),
                  const Spacer(),
                  Text(_fmtBaht(_total),
                      style: const TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.w900, 
                        fontSize: 18)
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Pay button
            Center(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: gold,
                  side: const BorderSide(color: gold, width: 1.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 12),
                ),
                onPressed: _showPaySheet,
                child: const Text('Pay', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowLine({required String label, required String value, String? trailing}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                    color: Colors.white54, 
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    )
                  ),
              Spacer(),
              Text(value, style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                )
              ),
            ],
          ),
        ),
      ],
    );
  }
}

  Widget _colLine({required String label, required String value, String? trailing}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                     color: Colors.white54, 
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    )
                  ),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(
                  color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                )
              ),
            ],
          ),
        ),
        if (trailing != null)
          Text(trailing, style: const TextStyle(
            color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
            )
          ),
      ],
    );
  }

class PaymentChannelSheet extends StatelessWidget {
  final double total;
  final VoidCallback onPay;

  const PaymentChannelSheet({
    super.key,
    required this.total,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFF4C23E);

    String fmtBaht(num n) => '฿ ${n.toStringAsFixed(2)}';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          // การ์ดหลัก
          decoration: BoxDecoration(
            color: const Color(0xFF0B0B0B),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white12, width: 1),
            boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.black54)],
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // แถบหัว
              Row(
                children: [
                  const Text(
                    'Payment',
                    style: TextStyle(
                      color: gold,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // label channel
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('channel',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ),
              const SizedBox(height: 8),

              // ไอคอนช่องทาง (QR)
              Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.qr_code_2, size: 40, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  const Text('QR',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.white12, height: 20),

              // Total
              Row(
                children: [
                  const Text('Total',
                      style: TextStyle(
                          color: Colors.white70, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(fmtBaht(total),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18)),
                ],
              ),

              const SizedBox(height: 16),

              // ปุ่ม Pay Now
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A2DFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: onPay,
                  child: const Text('Pay Now',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
