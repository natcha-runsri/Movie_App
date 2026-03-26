import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'homepage.dart';
import 'MorePage.dart';
import 'PromotionPage.dart';
import '../database/dataHelper.dart';
import '../database/Moviemodel.dart';
import '../detail/movie_detail_page.dart';

/// ───────────────── Favorite Repository (เก็บ/อ่านรายการโปรด) ─────────────────
class _FavoriteRepo {
  final _db = FirebaseFirestore.instance;

  Stream<Set<String>> streamMyFavorites(String uid) {
    return _db
        .collection('profile')
        .doc(uid)
        .collection('favorites')
        .snapshots()
        .map((qs) => qs.docs.map((d) => d.id).toSet());
  }

  Future<void> toggle(String uid, String movieId, bool isFav) async {
    final ref =
        _db.collection('profile').doc(uid).collection('favorites').doc(movieId);
    if (isFav) {
      await ref.delete();
    } else {
      await ref.set({'createdAt': FieldValue.serverTimestamp()});
    }
  }
}

/// ─────────────────────────────────────────────────────────────────────────────

class Moviespage extends StatefulWidget {
  const Moviespage({super.key});

  @override
  State<Moviespage> createState() => _MovieBrowseTabsPageState();
}

class _MovieBrowseTabsPageState extends State<Moviespage> {
  final _db = MovieDatabaseHelper();

  final List<String> _genres = const [
    'All',
    'Action',
    'Romance',
    'Horror',
    'Thriller',
    'Comedy',
    'Drama'
  ];

  String _query = '';
  _Sort _sort = _Sort.favorite; // ✅ ค่าเริ่มต้น: แสดงรายการโปรดก่อน

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _genres.length,
      initialIndex: 0,
      child: Scaffold(
        backgroundColor: Colors.black,

        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 70,
          titleSpacing: 16,
          title: Row(
            children: [
              const Text(
                'Movie',
                style: TextStyle(
                    color: Color(0xFFF4C23E),
                    fontSize: 40,
                    fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              _Logo(),
            ],
          ),
        ),

        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _SearchBar(
                hint: 'search movie',
                onChanged: (v) => setState(() => _query = v),
                onSubmitted: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 15),

            // TabBar + Sort
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TabBar(
                      tabAlignment: TabAlignment.start,
                      isScrollable: true,
                      dividerColor: const Color.fromARGB(54, 156, 155, 155),
                      indicatorSize: TabBarIndicatorSize.label,
                      labelPadding: EdgeInsets.zero,
                      indicator: BoxDecoration(
                        color: const Color.fromARGB(227, 255, 206, 29),
                        borderRadius: BorderRadius.circular(888),
                      ),
                      overlayColor:
                          const WidgetStatePropertyAll(Color.fromARGB(255, 0, 0, 0)),
                      splashFactory: NoSplash.splashFactory,
                      labelColor: const Color.fromARGB(255, 255, 255, 255),
                      unselectedLabelColor: Colors.white70,
                      labelStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      tabs: _genres
                          .map(
                            (g) => Tab(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: Text(g),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: _SortDropdown(
                  value: _sort,
                  onChanged: (s) => setState(() => _sort = s),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // เนื้อหาแต่ละแท็บ
            Expanded(
              child: TabBarView(
                children: _genres.map((genre) {
                  return _GenreGrid(
                    db: _db,
                    genre: genre,
                    query: _query,
                    sort: _sort,
                  );
                }).toList(),
              ),
            ),
          ],
        ),

        // bottom nav
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.yellow,
          unselectedItemColor: Colors.white70,
          type: BottomNavigationBarType.fixed,
          currentIndex: 1,
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
            BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.bars), label: 'More'),
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
      ),
    );
  }
}

// โลโก้
class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Padding(
          padding: EdgeInsets.only(right: 0.5),
          child: Image(
            image: AssetImage('images/logo_movi.jpg'),
            height: 50,
            width: 50,
          ),
        ),
      ],
    );
  }
}

// ───────────────── กริดหนังในแต่ละแท็บ ─────────────────
enum _Sort { favorite, latest, oldest }

class _GenreGrid extends StatelessWidget {
  final MovieDatabaseHelper db;
  final String genre; // 'All' หรือชื่อหมวด
  final String query;
  final _Sort sort;

  const _GenreGrid({
    required this.db,
    required this.genre,
    required this.query,
    required this.sort,
  });

  Future<void> _toggleFavorite(
      BuildContext context, String? uid, String movieId, bool isFav) async {
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to use favorites')),
      );
      return;
    }
    await _FavoriteRepo().toggle(uid, movieId, isFav);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // สตรีมรายการโปรดของผู้ใช้ (ถ้าไม่ล็อกอิน → เซ็ตว่าง)
    final favStream =
        uid == null ? Stream.value(<String>{}) : _FavoriteRepo().streamMyFavorites(uid);

    // ใช้ streamAll แล้วกรองในแอป
    return StreamBuilder<List<MovieModel>>(
      stream: db.streamAll(descending: true),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text('error: ${snap.error}',
                style: const TextStyle(color: Colors.red)),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // รอ favorites พร้อมกันด้วย
        return StreamBuilder<Set<String>>(
          stream: favStream,
          builder: (context, favSnap) {
            final favs = favSnap.data ?? <String>{};

            var list = snap.data!;

            // กรองตามหมวด
            if (genre != 'All') {
              list = list.where((m) => m.type.contains(genre)).toList();
            }

            // ค้นหาจากชื่อ
            if (query.trim().isNotEmpty) {
              final q = query.toLowerCase();
              list = list.where((m) => m.name.toLowerCase().contains(q)).toList();
            }

            // จัดเรียง
            int cmpLatest(MovieModel a, MovieModel b) =>
                b.date.compareTo(a.date);
            int cmpOldest(MovieModel a, MovieModel b) =>
                a.date.compareTo(b.date);
            int cmpDuration(MovieModel a, MovieModel b) =>
                b.time.compareTo(a.time);

            if (sort == _Sort.favorite) {
              list.sort((a, b) {
                final af = favs.contains(a.id);
                final bf = favs.contains(b.id);
                if (af != bf) return bf ? 1 : -1; // ✅ โปรดมาก่อน
                return cmpLatest(a, b); // แล้วค่อยล่าสุด
              });
            } else if (sort == _Sort.latest) {
              list.sort(cmpLatest);
            } else if (sort == _Sort.oldest) {
              list.sort(cmpOldest);
            } 
            if (list.isEmpty) {
              return const Center(
                child: Text('ไม่พบหนังในหมวดนี้',
                    style: TextStyle(color: Colors.white70)),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.62,
                ),
                itemBuilder: (_, i) {
                  final m = list[i];
                  final isFav = favs.contains(m.id);
                  return _MovieCard(
                    movie: m,
                    isFavorite: isFav,
                    onToggleFavorite: () =>
                        _toggleFavorite(context, uid, m.id!, isFav),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MovieDetailPage(movieId: m.id!),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

// ───────────── การ์ดหนัง 1 เรื่อง ─────────────
class _MovieCard extends StatelessWidget {
  final MovieModel movie;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;

  const _MovieCard({
    required this.movie,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onTap,
  });

  String _humanTime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (minutes <= 0) return '—';
    if (h > 0 && m > 0) return '$h hr $m min';
    if (h > 0) return '$h hr';
    return '$m min';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster + Heart overlay
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    movie.images.isEmpty
                        ? 'https://via.placeholder.co/600x800?text=No+Image'
                        : movie.images,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1E1E1E),
                      child: const Icon(Icons.broken_image,
                          size: 48, color: Colors.white38),
                    ),
                  ),
                  // Heart button
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () {
                        onToggleFavorite();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isFavorite
                              ? const Color(0xFFFF5A5A)
                              : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            movie.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Color.fromARGB(255, 201, 200, 200),
                fontWeight: FontWeight.w700,
                fontSize: 11),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.schedule,
                  size: 12, color: Color.fromARGB(179, 215, 215, 215)),
              const SizedBox(width: 3),
              Text(
                _humanTime(movie.time),
                style: const TextStyle(
                    color: Color.fromARGB(179, 215, 215, 215), fontSize: 9),
              ),
              const Spacer(),
              // ไอคอนหัวใจเล็กย้ำอีกที (optional)
              Icon(
                Icons.favorite,
                size: 12,
                color: isFavorite
                    ? const Color(0xFFFF5A5A)
                    : Colors.transparent, // ถ้าไม่ favorite ก็ซ่อน
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────── ส่วนประกอบอื่น ─────────────

class _SearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _SearchBar({required this.hint, this.onChanged, this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: const Color.fromARGB(255, 115, 115, 115),
        shape: StadiumBorder(
          side: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
      ),
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: const TextStyle(color: Colors.white, fontSize: 18),
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

class _SortDropdown extends StatelessWidget {
  final _Sort value;
  final ValueChanged<_Sort> onChanged;
  const _SortDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<_Sort>(
      dropdownColor: const Color(0xFF1E1E1E),
      value: value,
      underline: const SizedBox.shrink(),
      style: const TextStyle(color: Colors.white),
      items: const [
        DropdownMenuItem(value: _Sort.favorite, child: Text('Favorite')),
        DropdownMenuItem(value: _Sort.latest, child: Text('Latest')),
        DropdownMenuItem(value: _Sort.oldest, child: Text('Oldest')),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
