import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bar_icon/MorePage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Profile extends StatefulWidget {
  final String docId;
  const Profile({super.key, required this.docId});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  // controllers
  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _addrCtrl = TextEditingController(); // contact/address
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _editing = false;
  bool _loading = true;

  // avatar ที่เลือก (female1, female2, male1, male2)
  String? _avatar;

  // คีย์ cache ผูกกับ uid/docId
  late String _kName, _kDob, _kAddr, _kTel, _kEmail, _kAvatar;

  @override
  void initState() {
    super.initState();
    _kName  = 'profile_${widget.docId}_name';
    _kDob   = 'profile_${widget.docId}_dob';
    _kAddr  = 'profile_${widget.docId}_address';
    _kTel   = 'profile_${widget.docId}_tel';
    _kEmail = 'profile_${widget.docId}_email';
    _kAvatar = 'profile_${widget.docId}_avatar';
    _load();
  }

  // ถ้า docId เปลี่ยน ให้รีโหลดข้อมูล
  @override
  void didUpdateWidget(covariant Profile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.docId != widget.docId) {
      _kName  = 'profile_${widget.docId}_name';
      _kDob   = 'profile_${widget.docId}_dob';
      _kAddr  = 'profile_${widget.docId}_address';
      _kTel   = 'profile_${widget.docId}_tel';
      _kEmail = 'profile_${widget.docId}_email';
      _kAvatar = 'profile_${widget.docId}_avatar';

      _nameCtrl.clear();
      _dobCtrl.clear();
      _addrCtrl.clear();
      _telCtrl.clear();
      _emailCtrl.clear();
      _avatar = null;

      _loading = true;
      setState(() {});
      _load();
    }
  }

  // ---------- Helpers ----------
  String _fmtBirth(dynamic v) {
    if (v == null) return '';
    try {
      if (v is Timestamp) return DateFormat('d MMMM yyyy').format(v.toDate());
      if (v is DateTime)  return DateFormat('d MMMM yyyy').format(v);
      return v.toString();
    } catch (_) {
      return v.toString();
    }
  }

  DateTime? _parseBirth(String s) {
    if (s.trim().isEmpty) return null;
    try {
      return DateFormat('d MMMM yyyy').parse(s);
    } catch (_) {
      return null;
    }
  }

  // map avatar key -> เส้นทางไฟล์ asset
  String? _avatarAsset(String? key) {
    switch (key) {
      case 'female1': return 'images/avatar_profile/avatarwoman1.png';
      case 'female2': return 'images/avatar_profile/avatarwoman2.png';
      case 'male1'  : return 'images/avatar_profile/male_avatar1.png';
      case 'male2'  : return 'images/avatar_profile/male_avatar2.png';
    }
    return null;
  }

  Future<void> _load() async {
    try {
      // --- Firestore ---
      final ref  = FirebaseFirestore.instance.collection('profile').doc(widget.docId);
      final snap = await ref.get();
      if (snap.exists && snap.data() != null) {
        final d = snap.data()!;
        _nameCtrl.text  = (d['name'] ?? '').toString();
        _dobCtrl.text   = _fmtBirth(d['birthdate']);
        _addrCtrl.text  = (d['contact'] ?? '').toString(); // address
        _telCtrl.text   = (d['tel'] ?? '').toString();
        _emailCtrl.text = (d['email'] ?? '').toString();
        _avatar         = (d['avatar'] ?? '').toString().isEmpty ? null : d['avatar'] as String?;
      } else {
        await ref.set({'uid': widget.docId}, SetOptions(merge: true));
      }

      // --- SharedPreferences (cache) ---
      final sp = await SharedPreferences.getInstance();
      _nameCtrl.text  = sp.getString(_kName)  ?? _nameCtrl.text;
      _dobCtrl.text   = sp.getString(_kDob)   ?? _dobCtrl.text;
      _addrCtrl.text  = sp.getString(_kAddr)  ?? _addrCtrl.text;
      _telCtrl.text   = sp.getString(_kTel)   ?? _telCtrl.text;
      _emailCtrl.text = sp.getString(_kEmail) ?? _emailCtrl.text;
      _avatar         = sp.getString(_kAvatar) ?? _avatar;
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firestore error: ${e.code} ${e.message ?? ""}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    // Firestore
    final ref = FirebaseFirestore.instance.collection('profile').doc(widget.docId);
    await ref.set({
      'uid'      : widget.docId,
      'name'     : _nameCtrl.text.trim(),
      'birthdate': _dobCtrl.text.trim(), // ถ้าจะเก็บ Timestamp ให้แปลงจาก _parseBirth
      'contact'  : _addrCtrl.text.trim(),
      'tel'      : _telCtrl.text.trim(),
      'email'    : _emailCtrl.text.trim(),
      'avatar'   : _avatar, // <-- เซฟ avatar key
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Cache
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kName,  _nameCtrl.text.trim());
    await sp.setString(_kDob,   _dobCtrl.text.trim());
    await sp.setString(_kAddr,  _addrCtrl.text.trim());
    await sp.setString(_kTel,   _telCtrl.text.trim());
    await sp.setString(_kEmail, _emailCtrl.text.trim());
    if (_avatar != null) {
      await sp.setString(_kAvatar, _avatar!);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
  }

  // ---------- เลือกวันเกิด ----------
  Future<void> _pickBirthdate() async {
    if (!_editing) return;
    DateTime initial = _parseBirth(_dobCtrl.text) ?? DateTime(2000, 1, 1);
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD4AF37),
              surface: Color(0xFF121212),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _dobCtrl.text = DateFormat('d MMMM yyyy').format(picked);
      setState(() {});
    }
  }

  // ---------- เลือก Avatar (ตัวอักษร) ----------
  Future<void> _pickAvatar() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('เลือก Avatar'),
        children: [
          SimpleDialogOption(
            child: const Text('female1'),
            onPressed: () => Navigator.pop(ctx, 'female1'),
          ),
          SimpleDialogOption(
            child: const Text('female2'),
            onPressed: () => Navigator.pop(ctx, 'female2'),
          ),
          SimpleDialogOption(
            child: const Text('male1'),
            onPressed: () => Navigator.pop(ctx, 'male1'),
          ),
          SimpleDialogOption(
            child: const Text('male2'),
            onPressed: () => Navigator.pop(ctx, 'male2'),
          ),
        ],
      ),
    );

    if (choice != null) {
      setState(() => _avatar = choice);
      await _save(); // เซฟทันทีทั้ง Firestore + Cache
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _addrCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Colors.black;
    const border = Colors.white12;
    const tileBg = Color(0xFF232323);
    const gold = Color(0xFFD4AF37);
    const faintText = Colors.white60;

    Widget boxText(String value, {TextAlign align = TextAlign.left}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: tileBg, borderRadius: BorderRadius.circular(8)),
          child: Text(
            (value.isEmpty) ? '—' : value,
            textAlign: align,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: faintText, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        );

    Widget boxField(TextEditingController c, {TextInputType? type, int maxLines = 1}) =>
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: tileBg, borderRadius: BorderRadius.circular(8)),
          child: TextField(
            controller: c,
            maxLines: maxLines,
            keyboardType: type,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: 'พิมพ์ข้อมูล...',
              hintStyle: TextStyle(color: Colors.white38, fontWeight: FontWeight.w500),
            ),
          ),
        );

    Widget sectionCard({required String title, required Widget child}) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              child,
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        toolbarHeight: 100,
        titleSpacing: 16,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const Morepage()),
            );
          },
        ),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 28),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Colors.white12),
        ),
      ),
      backgroundColor: bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: border, width: 2),
                      ),
                      child: (_avatarAsset(_avatar) != null)
                          ? CircleAvatar(
                              backgroundImage: AssetImage(_avatarAsset(_avatar)!),
                            )
                          : const CircleAvatar(
                              radius: 44,
                              backgroundColor: Color(0xFFCFE3FF),
                              child: Icon(Icons.person, size: 56, color: Colors.black54),
                            ),
                    ),
                    const SizedBox(height: 10),
                    // ปุ่มเลือก avatar (ตัวอักษร)
                    IconButton(
                      onPressed: _pickAvatar,
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      tooltip: 'เลือก Avatar',
                    ),
                    const SizedBox(height: 18),

                    // Name
                    sectionCard(
                      title: 'Name',
                      child: _editing ? boxField(_nameCtrl) : boxText(_nameCtrl.text),
                    ),
                    const SizedBox(height: 14),

                    // Date of Birth
                    sectionCard(
                      title: 'Date of Birth',
                      child: _editing
                          ? InkWell(onTap: _pickBirthdate, child: boxText(_dobCtrl.text))
                          : boxText(_dobCtrl.text),
                    ),
                    const SizedBox(height: 14),

                    // Address
                    sectionCard(
                      title: 'Address',
                      child: _editing ? boxField(_addrCtrl, maxLines: 2) : boxText(_addrCtrl.text),
                    ),
                    const SizedBox(height: 14),

                    // UID (read-only)
                    sectionCard(
                      title: 'UID',
                      child: boxText(widget.docId),
                    ),
                    const SizedBox(height: 14),

                    // Contract: Telephone + Email
                    sectionCard(
                      title: 'Contract',
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const SizedBox(
                                width: 96,
                                child: Text('Telephone',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _editing
                                    ? boxField(_telCtrl, type: TextInputType.phone)
                                    : boxText(_telCtrl.text, align: TextAlign.right),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const SizedBox(
                                width: 96,
                                child: Text('Email',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _editing
                                    ? boxField(_emailCtrl, type: TextInputType.emailAddress)
                                    : boxText(_emailCtrl.text, align: TextAlign.right),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Edit / Save
                    SizedBox(
                      width: 160,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          if (_editing) {
                            try {
                              await _save();
                              if (!mounted) return;
                              setState(() => _editing = false);
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Save failed: $e')),
                              );
                            }
                          } else {
                            setState(() => _editing = true);
                          }
                        },
                        child: Text(
                          _editing ? 'Save' : 'Edit',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
