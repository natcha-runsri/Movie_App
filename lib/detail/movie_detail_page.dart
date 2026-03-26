import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/dataHelper.dart';
import '../database/Moviemodel.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'booking.dart';
import '../database/cinema_database_helper.dart';
import '../database/cinema_model.dart';

class MovieDetailPage extends StatefulWidget {
  final String movieId;
  final String? cinemaId;

  const MovieDetailPage({super.key, required this.movieId, this.cinemaId});

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  final db = MovieDatabaseHelper();
  final _cinDb = CinemaDatabase();
  CinemaModel? _cinema;
  bool _fav = false;
  static const yellow = Color(0xFFF4C23E);

  Future<void> _loadCinema() async {
    if (widget.cinemaId == null) return;
    _cinema = await _cinDb.getById(widget.cinemaId!);
    if (mounted) setState(() {});
  }


  Future<void> _loadFav() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _fav = false);
      return;
    }
    final doc =
        await FirebaseFirestore.instance
            .collection('profile')
            .doc(uid)
            .collection('favorites')
            .doc(widget.movieId)
            .get();
    if (!mounted) return;
    setState(() => _fav = doc.exists);
  }

  Future<void> _toggleFav() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to use favorites')),
      );
      return;
    }
    final ref = FirebaseFirestore.instance
        .collection('profile')
        .doc(uid)
        .collection('favorites')
        .doc(widget.movieId);

    try {
      if (_fav) {
        await ref.delete();
      } else {
        await ref.set({'createdAt': FieldValue.serverTimestamp()});
      }
      if (!mounted) return;
      setState(() => _fav = !_fav);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_fav ? 'Added to favorites' : 'Removed from favorites'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  // ===== Status badge =====
  ({String label, Color color}) _statusStyle(String raw) {
    final s = raw.toLowerCase().trim();
    if (s.contains('now') ||
        s.contains('showing') ||
        s == 'now' ||
        s == 'now_showing') {
      return (label: 'Now Showing', color: const Color(0xFF36D399)); // เขียว
    }
    if (s.contains('soon') || s == 'coming' || s == 'coming_soon') {
      return (label: 'Coming Soon', color: const Color(0xFF60A5FA)); // ฟ้า
    }
    return (label: raw.isEmpty ? 'Unknown' : raw, color: Colors.white24);
  }

  // ===== Time formatter =====
  String _humanTime(int minutes) {
    if (minutes <= 0) return '—';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '$h hr $m min';
    if (h > 0) return '$h hr';
    return '$m min';
  }

  @override
  void initState() {
    super.initState();
    _loadFav();
    _loadCinema(); // 👉 โหลดชื่อโรงไว้ใช้แสดงผล/ส่งต่อให้ BookingPage
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _fav ? FontAwesomeIcons.solidHeart
              : FontAwesomeIcons.heart,
               color: const Color.fromARGB(255, 143, 11, 11), 
            ),
            onPressed: _toggleFav,
            tooltip: 'Favorite',
          ),
          IconButton(
            icon: const Icon(
              Icons.share,
              color: Colors.white
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share coming soon')),
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<MovieModel?>(
        stream: db.streamById(widget.movieId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final err = snapshot.error;
            if (err is FirebaseException) {
              return _ErrorBox(
                title: "FirebaseException",
                lines: [
                  "code: ${err.code}",
                  if (err.message != null) "message: ${err.message}",
                ],
              );
            }
            return _ErrorBox(title: "Error", lines: ["$err"]);
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final movie = snapshot.data;
          if (movie == null) {
            return const Center(
              child: Text(
                "ไม่พบข้อมูลหนัง",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final dateStr = DateFormat("d MMMM yyyy").format(movie.date);
          final status = _statusStyle(movie.status);

          final canBuy = status.label == 'Now Showing';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20,),
                // ── Poster + status + trailer ──────────────────────────
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [

                      // Poster
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color.fromARGB(88, 167, 159, 159), // สีเส้นกรอบ
                            width: 1, // ความหนาเส้น
                          ),
                          borderRadius: BorderRadius.circular(
                            16,
                          ), // ต้องให้เท่ากับ ClipRRect
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            movie.images.isEmpty
                                ? 'https://via.placeholder.co/900x600?text=No+Image'
                                : movie.images,
                            height: 320,
                            width: 260,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => Container(
                                  height: 320,
                                  width: 260,
                                  color: const Color(0xFF1E1E1E),
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.white38,
                                    size: 48,
                                  ),
                                ),
                          ),
                        ),
                      ),

                      // Status badge (มุมขวาบน)
                      Positioned(
                        right: -25,
                        top: -15,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber, // 👈 เปลี่ยนเป็นสีขาวถาวร
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            status.label,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      // Trailer pill (มุมซ้ายล่าง)
                      if (movie.trailer.isNotEmpty)
                        Positioned(
                          left: -60,
                          bottom: 70,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 177, 176, 176).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: const [
                                  Icon(
                                    FontAwesomeIcons.circlePlay,
                                    size: 22,
                                    color: Color.fromARGB(221, 255, 255, 255),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'trailer',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                             onTap:
                                () => openTrailerInApp(context, movie.trailer),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── Title ───────────────────────────────────────────────
                Center(
                  child: Text(
                    movie.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Time & Date ─────────────────────────────────────────
                Column(
                  children: [
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule, size: 14, color: Color.fromARGB(211, 255, 255, 255)),
                          const SizedBox(width: 6),
                          Text(
                            _humanTime(movie.time),
                            style: const TextStyle(color: Color.fromARGB(211, 255, 255, 255), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today,size: 14,color: Color.fromARGB(211, 255, 255, 255),),
                          const SizedBox(width: 6),
                          Text(dateStr,
                          style: const TextStyle(color: Color.fromARGB(211, 255, 255, 255), fontSize:12),
                         ),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 14),

                // ── Type chips ──────────────────────────────────────────
                Center(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children:
                        movie.type.map((t) {
                          return Chip(
                            label: Text(
                              t,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                            side: BorderSide(color: Color.fromARGB(211, 255, 255, 255)),
                            shape: StadiumBorder(
                              side: BorderSide(color: Color.fromARGB(211, 255, 255, 255), width: 0.5),
                            ),
                            labelStyle: const TextStyle(color: Color.fromARGB(211, 255, 255, 255),
                            ),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // 👈 ลด hit area
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4), // 👈 บีบให้เล็กลง
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 18),

                // ── Description ─────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 15,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F0F),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Text(
                    movie.description,
                    style: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255), 
                      height: 1.5,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Cast ────────────────────────────────────────────────
                const _SectionHeader(title: 'Cast'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: movie.cast.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final name = movie.cast[i];
                      final img =
                          i < movie.cast_images.length
                              ? movie.cast_images[i]
                              : '';
                      return _CastTile(name: name, imageUrl: img);
                    },
                  ),
                ),
                const Divider(
                  color: Color.fromARGB(118, 202, 202, 202),
                  thickness: 0.5,
                ),
                const SizedBox(height: 10),

                // ── Director (หัวข้ออย่างในภาพ — ถ้าต้องการข้อมูลจริง ค่อยเพิ่มฟิลด์ใน Model)
                const _SectionHeader(title: 'Director'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: movie.director.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final name = movie.director[i];
                      final img =
                          i < movie.direc_images.length
                              ? movie.direc_images[i]
                              : '';
                      return _CastTile(name: name, imageUrl: img);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),

      // ── Buy Ticket button (เปลี่ยนสถานะ/สีตามหนัง) ─────────────────
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            height: 56,
            child: Builder(
              builder: (context) {
                // ติดตาม snapshot ล่าสุดเพื่ออ่านสถานะปัจจุบัน
                return StreamBuilder<MovieModel?>(
                  stream: db.streamById(widget.movieId),
                  builder: (context, s) {
                    final movie = s.data;
                    final canBuy =
                        movie != null &&
                        _statusStyle(movie.status).label == 'Now Showing';

                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            canBuy
                                ? const Color.fromARGB(255, 39, 92, 161)
                                : Colors.white12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed:
                          canBuy
                              ? () {
                                final m =
                                    s.data; // s = StreamBuilder<MovieModel?> snapshot
                                if (m == null) return;

                                final poster =
                                    m.images.isEmpty
                                        ? 'https://via.placeholder.co/900x600?text=No+Image'
                                        : m.images;

                                if (!mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => BookingPage(
                                          movieId: m.id ?? widget.movieId,
                                          posterUrl: poster,
                                          title: m.name,
                                          runtime: Duration(minutes: m.time),
                                          cinemaId: null, // ← ยังไม่เลือกโรง
                                          cinemaName:
                                              null, // ← ยังไม่เลือกชื่อสาขา
                                        ),
                                  ),
                                );
                              }
                              : null,

                      child: Text(
                        canBuy ? 'Buy Ticket' : 'Coming Soon',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color:
                              canBuy
                                  ? const Color.fromARGB(255, 255, 255, 255)
                                  : Colors.white54,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CastTile extends StatelessWidget {
  final String name;
  final String imageUrl;
  const _CastTile({required this.name, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            imageUrl.isEmpty
                ? 'https://via.placeholder.co/200x200?text=No+Image'
                : imageUrl,
            width: 90,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder:
                (_, __, ___) => Container(
                  width: 64,
                  height: 64,
                  color: const Color(0xFF1E1E1E),
                  child: const Icon(Icons.person, color: Colors.white38),
                ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 90,
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String title;
  final List<String> lines;
  const _ErrorBox({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: Colors.red.shade50,
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.red),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                for (final l in lines) Text(l),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void openTrailerInApp(BuildContext context, String url) {
  if (url.trim().isEmpty) return;

  showDialog(
    context: context,
    useRootNavigator: true, // ✅ Back จะปิด dialog ก่อนเสมอ
    barrierDismissible: false, // ✅ กัน state เพี้ยน
    barrierColor: Colors.black87,
    builder: (_) {
      final isYT = _isYouTube(url);
      return _TrailerDialogScaffold(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child:
              isYT ? YouTubeIframePlayer(url: url) : _Mp4PlayerDialog(url: url),
        ),
      );
    },
  );
}

class _TrailerDialogScaffold extends StatelessWidget {
  final Widget child;
  const _TrailerDialogScaffold({required this.child});

  void _close(BuildContext context) =>
      Navigator.of(context, rootNavigator: true).pop();

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        _close(context);
        return false;
      }, // Android back
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Shortcuts(
                // Web: ESC to close
                shortcuts: <LogicalKeySet, Intent>{
                  LogicalKeySet(LogicalKeyboardKey.escape): ActivateIntent(),
                },
                child: Actions(
                  actions: <Type, Action<Intent>>{
                    ActivateIntent: CallbackAction<Intent>(
                      onInvoke: (Intent intent) => _close(context),
                    ),
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // แถบด้านบน (อยู่นอก iframe) → กดออกได้เสมอ
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            const Text(
                              'Trailer',
                              style: TextStyle(color: Colors.white),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () => _close(context),
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                      ),

                      // กล่องวิดีโอ
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: child, // YouTube หรือ MP4 player
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

bool _isYouTube(String u) {
  final uri = Uri.tryParse(u);
  final h = uri?.host.toLowerCase() ?? '';
  return h.contains('youtube.com') || h.contains('youtu.be');
}

// ===== YouTube (iframe) =====
class YouTubeIframePlayer extends StatefulWidget {
  final String url;
  const YouTubeIframePlayer({super.key, required this.url});
  @override
  State<YouTubeIframePlayer> createState() => _YouTubeIframePlayerState();
}

class _YouTubeIframePlayerState extends State<YouTubeIframePlayer> {
  late final YoutubePlayerController _c;
  StreamSubscription<YoutubePlayerValue>? _sub; // ✅ ฟังสถานะจบคลิป
  bool _tapToUnmute = false;

  @override
  void initState() {
    super.initState();
    final id = YoutubePlayerController.convertUrlToId(widget.url) ?? '';
    _c = YoutubePlayerController.fromVideoId(
      videoId: id,
      params: const YoutubePlayerParams(
        // ===== สำคัญต่อ Chrome autoplay policy =====
        // เริ่มแบบ MUTE เพื่อให้เล่นเองได้ แล้วค่อยให้ผู้ใช้แตะปลดเสียง
        mute: true,
        playsInline: true,
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
      ),
    );

    // ✅ ฟังสถานะ player เพื่อรู้ว่า "จบคลิป" แล้วปิด dialog
    _sub = _c.stream.listen((v) {
      if (!mounted) return;
      if (v.playerState == PlayerState.ended) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });

    // ✅ สั่งเล่นอัตโนมัติ (muted)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _c.playVideo();
      } catch (_) {
        if (mounted) setState(() => _tapToUnmute = true);
      }
    });
  }

  @override
  void dispose() {
    // ✅ หยุดและปิด controller เพื่อกัน "คลิปลอยค้าง"
    try {
      _c.stopVideo();
    } catch (_) {}
    try {
      _c.close();
    } catch (_) {} // บางเวอร์ชันมี close()
    super.dispose();
  }

  Future<void> _onTapUnmute() async {
    try {
      await _c.playVideo();
      await _c.unMute();
    } finally {
      if (mounted) setState(() => _tapToUnmute = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        YoutubePlayer(controller: _c, aspectRatio: 16 / 9),
        if (_tapToUnmute)
          Material(
            color: Colors.black45,
            child: InkWell(
              onTap: _onTapUnmute,
              child: const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// ---------- MP4 / HLS ----------
class _Mp4PlayerDialog extends StatefulWidget {
  final String url;
  const _Mp4PlayerDialog({required this.url});

  @override
  State<_Mp4PlayerDialog> createState() => _Mp4PlayerDialogState();
}

class _Mp4PlayerDialogState extends State<_Mp4PlayerDialog> {
  late final VideoPlayerController _vp;
  ChewieController? _chewie;

  @override
  void initState() {
    super.initState();
    _vp = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _vp.initialize().then((_) {
      _chewie = ChewieController(
        videoPlayerController: _vp,
        autoPlay: true,
        looping: false,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
      );
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _vp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewie == null || !_vp.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        Chewie(controller: _chewie!),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
        ),
      ],
    );
  }
}
