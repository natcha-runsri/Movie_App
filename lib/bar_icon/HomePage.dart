import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/Moviemodel.dart';
import '../detail/movie_detail_page.dart';
import '../database/dataHelper.dart';
import 'MorePage.dart';
import 'MoviesPage.dart';
import 'PromotionPage.dart';
import 'dart:async';
import 'package:flutter/rendering.dart' show ScrollDirection;
import '../icon_more_detail/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../detail/myticket.dart';
import 'notification.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData.dark(),
      home: const HomeDashboardPage(),
      routes: {'/profile': (context) => const Profile(docId: '')},
    );
  }
}

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  final _db = MovieDatabaseHelper();
  final _pageCtrl = PageController(viewportFraction: 0.92);
  String _query = '';

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        toolbarHeight: 80,
        titleSpacing: 16,
        title: Row(
          children: [
            _Logo(),
            const Spacer(),

            //ปุ่ม ticket กดแล้วจะแสดงหน้า ตั๋วของเรา ถ้ามีการจองตั๋วไว้ 
            IconButton(
              icon: const Icon(
                FontAwesomeIcons.ticket,
                color: Colors.white,
                size: 30,
              ),

              //กดแล้วก็จะตรวจว่ามีการเข้าสู่ระบบไหม ถ้ามีก็จะจะไปดูว่ามีข้อมูลการจองรึเปล่า
              onPressed: () {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please sign in first')),
                  );
                  return;
                }
                
                //ดึงข้อมูล booking ล่าสุดของ user
                FirebaseFirestore.instance
                    .collection('profile')
                    .doc(user.uid)
                    .collection('bookings')
                    .orderBy('createdAt', descending: true) //เรียงตาม field createdAt ล่าสุดมาก่อน
                    .limit(1) //ดึงมาแค่ 1 record (ล่าสุด)
                    .get()
                    .then((snap) { //รอผลลัพธ์
                      if (snap.docs.isEmpty) { //ถ้าว่าง
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No tickets found')),
                        );
                        return;
                      }
                      final bookingId = snap.docs.first.id; //ได้ id ของ booking ล่าสุด
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyTicketsPage(), //เปิดหน้าแสดงตั๋ว
                        ),
                      );
                    });
              },
            ),

            //ปุ่มNotifications กดแล้วจะเข้าหน้าแจ้งเตือน
            IconButton(
              icon: const Icon(
                FontAwesomeIcons.bell,
                color: Colors.white,
                size: 30,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                );
              },
            ),
            const SizedBox(width: 4),

            InkWell(
              onTap: () {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  // ยังไม่ได้ล็อกอิน → แจ้งเตือนหรือพาไปหน้า Login
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please sign in first')),
                  );
                  return;
                }

                final uid = user.uid; // ได้ uid แน่นอนแล้ว
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => Profile(
                          key: ValueKey(
                            uid,
                          ), // บังคับ rebuild เมื่อเปลี่ยนผู้ใช้
                          docId: uid, // โหลดเอกสารโปรไฟล์ตาม uid
                        ),
                  ),
                );
              },
              child: _ProfileAvatar(
                uid: FirebaseAuth.instance.currentUser?.uid,
              ),
            ),
            const SizedBox(width: 8),

          ],
        ),
      ),

      body: StreamBuilder<List<MovieModel>>(
        stream: _db.streamAll(descending: true), //ข้อมูลหนังทั้งหมดจาก Firestore (เรียงลำดับใหม่ → เก่า)
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data!;//เก็บข้อมูลไว้ใน all
          final coming = //หนังที่ status มีคำว่า "soon"
              all
                  .where((m) => m.status.toLowerCase().contains('soon'))
                  .toList();
          final recommend = //หนังอื่น ๆ
              all
                  .where((m) => !m.status.toLowerCase().contains('soon'))
                  .toList();

          //ฟังก์ชันค้นหา (_filter)
          List<MovieModel> _filter(List<MovieModel> src) {
            if (_query.trim().isEmpty) return src;//ถ้า _query ว่าง → คืนค่า list เดิม
            final q = _query.toLowerCase();
            return src.where((m) => m.name.toLowerCase().contains(q)).toList(); //filter เฉพาะหนังที่ชื่อ (m.name)
          }

          final comingView = _filter(coming);
          final recommendView = _filter(recommend);

          //หาข้อมูล Favorites ของ user
          final user = FirebaseAuth.instance.currentUser;
          final favStream =
              (user == null)
                  ? const Stream<QuerySnapshot<Map<String, dynamic>>>.empty()
                  : FirebaseFirestore.instance
                      .collection('profile')
                      .doc(user.uid)
                      .collection('favorites')
                      .snapshots(); //listen แบบ realtime

          //
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: favStream,
            builder: (context, favSnap) {
              // set ของ movieId ที่กด favorite
              final favIds = <String>{
                if (favSnap.hasData) ...favSnap.data!.docs.map((d) => d.id),
              };
              // เลือกหนังที่เป็น favorite
              final favoriteMovies =
                  all.where((m) => favIds.contains(m.id ?? '')).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // ………………………… (บล็อก Banner images ) …………………………
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('movie')
                              .doc('11')
                              .snapshots(),
                      builder: (context, snap11) {
                        if (snap11.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: 170,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (!snap11.hasData || !snap11.data!.exists) {
                          return const SizedBox.shrink();
                        }
                        final data = snap11.data!.data();
                        final urls =
                            (data?['recommend'] as List?)
                                ?.where((e) => e != null)
                                .map((e) => e.toString())
                                .toList() ??
                            const <String>[];
                        if (urls.isEmpty) return const SizedBox.shrink();
                        return _BannerImagesCarousel(imageUrls: urls);
                      },
                    ),
                    const SizedBox(height: 20),

                    _SearchBar(
                      hint: 'search',
                      onChanged: (v) => setState(() => _query = v),
                      onSubmitted: (v) => setState(() => _query = v),
                    ),
                    const SizedBox(height: 16),

                    // ───────────── Now Showing ─────────────
                    _SectionHeader(
                      title: 'Now Showing...',
                      onSeeAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => Moviespage()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _HorizontalMovieList(movies: recommendView),
                    const SizedBox(height: 12,),
                    const Divider(
                      color: Color.fromARGB(255, 176, 174, 174),
                      height: 1,
                    ),
                    const SizedBox(height: 12,),

                    // ───────────── Recommend (Favorites) ─────────────
                    if (user != null && favoriteMovies.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Favorites...',
                        onSeeAll: () {
                          // จะพาไป Moviespage ก็ได้ หรือทำหน้า favorites แยกภายหลัง
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => Moviespage()),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _HorizontalMovieList(movies: favoriteMovies),
                      const SizedBox(height: 12,),
                      const Divider(
                        color: Color.fromARGB(255, 176, 174, 174),
                        height: 1,
                      ),
                    ],
                      const SizedBox(height: 12,),

                    // ───────────── Coming Soon ─────────────
                    _SectionHeader(title: 'Coming Soon ...', 
                    onSeeAll: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => Moviespage()),
                        );
                    }),
                    const SizedBox(height: 12),
                    _HorizontalMovieList(movies: comingView),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          );
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        selectedItemColor: Colors.yellow,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.house),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.film),
            label: 'Movies',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.gift),
            label: 'Gift',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.bars),
            label: 'More',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomePage()),
            );
          }
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => Moviespage()),
            );
          }
          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => Promotionpage()),
            );
          }
          if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => Morepage()),
            );
          }
        },
      ),
    );
  }
}

// ───────────────────────── widgets ─────────────────────────

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Padding(
          padding: EdgeInsets.only(left: 0.5),
          child: Image(
            image: AssetImage('images/logo_movi.jpg'),
            height: 70,
            width: 70,
          ),
        ),
      ],
    );
  }
}

class _BannerImagesCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final int autoPlayIntervalSec;

  const _BannerImagesCarousel({
    required this.imageUrls,
    this.autoPlayIntervalSec = 3,
    super.key,
  });

  @override
  State<_BannerImagesCarousel> createState() => _BannerImagesCarouselState();
}

class _BannerImagesCarouselState extends State<_BannerImagesCarousel> {
  late final PageController _controller;
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 1.1);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    if (widget.imageUrls.length <= 1) return;
    _timer = Timer.periodic(Duration(seconds: widget.autoPlayIntervalSec), (_) {
      if (!mounted) return;
      final next = (_index + 1) % widget.imageUrls.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void didUpdateWidget(covariant _BannerImagesCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrls.length != widget.imageUrls.length ||
        oldWidget.autoPlayIntervalSec != widget.autoPlayIntervalSec) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          NotificationListener<UserScrollNotification>(
            onNotification: (n) {
              if (n.direction != ScrollDirection.idle) {
                _timer?.cancel();
              } else {
                _startAutoPlay();
              }
              return false;
            },
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              itemCount: widget.imageUrls.length,
              itemBuilder: (context, i) {
                final url = widget.imageUrls[i];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url.isEmpty
                        ? 'https://via.placeholder.co/900x600?text=No+Image'
                        : url,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(
                          color: const Color(0xFF1E1E1E),
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.white38,
                          ),
                        ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 10,
            child: Row(
              children: List.generate(widget.imageUrls.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: active ? 18 : 6,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white38,
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _SearchBar({required this.hint, this.onChanged, this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: const Color(0xFF121212),
        shape: StadiumBorder(
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                border: InputBorder.none,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Icon(Icons.search, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final bool showTitle;
  const _SectionHeader({
    required this.title,
    this.onSeeAll,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showTitle)
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        const Spacer(),
        TextButton(
          onPressed: onSeeAll,
          child: Text(
            'See All :',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ),
      ],
    );
  }
}

class _HorizontalMovieList extends StatelessWidget {
  final List<MovieModel> movies;
  const _HorizontalMovieList({required this.movies});

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text('No items', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final m = movies[i];
          return SizedBox(
            width: 150,
            child: InkWell(
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MovieDetailPage(movieId: m.id!),
                    ),
                  ),
              borderRadius: BorderRadius.circular(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: Image.network(
                        m.images.isEmpty
                            ? 'https://via.placeholder.co/600x800?text=No+Image'
                            : m.images,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              color: const Color(0xFF1E1E1E),
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.white38,
                              ),
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    m.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: -8,
                    children:
                        m.type.take(2).map((t) {
                          return Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(
                              t,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            labelStyle: const TextStyle(color: Colors.white),
                            backgroundColor: Colors.black,
                            side: const BorderSide(
                              color: Color.fromARGB(255, 178, 177, 177),
                              width: 1,
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 3),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ───────────── avatar widget ─────────────
class _ProfileAvatar extends StatelessWidget {
  final String? uid;
  const _ProfileAvatar({super.key, required this.uid});

  String? _assetFromKey(String? key) {
    switch (key) {
      case 'female1':
        return 'images/avatar_profile/avatarwoman1.png';
      case 'female2':
        return 'images/avatar_profile/avatarwoman2.png';
      case 'male1':
        return 'images/avatar_profile/male_avatar1.png';
      case 'male2':
        return 'images/avatar_profile/male_avatar2.png';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const CircleAvatar(radius: 20, backgroundColor: Colors.white);
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection('profile').doc(uid).snapshots(),
      builder: (context, snap) {
        if (snap.hasError || !snap.hasData || !snap.data!.exists) {
          return const CircleAvatar(radius: 20, backgroundColor: Colors.white);
        }
        final data = snap.data!.data();
        final avatarKey = (data?['avatar'] as String?)?.trim();
        final asset = _assetFromKey(avatarKey);
        if (asset != null) {
          return CircleAvatar(radius: 20, backgroundImage: AssetImage(asset));
        }
        return const CircleAvatar(radius: 20, backgroundColor: Colors.white);
      },
    );
  }
}
