import 'package:cloud_firestore/cloud_firestore.dart';

class MovieModel {
  final String? id;
  final List<String> cast;
  final List<String> cast_images;
  final String name;
  final String status;
  final String description;
  final String images;
  final int time;        // นาที
  final DateTime date;
  final List<String> type;
  final String trailer;
  final List<String> director;
  final List<String> direc_images;
  final List<String> recommend;

  static const CollectionName = 'movie';

  MovieModel({
    this.id,
    required this.name,
    required this.description,
    required this.images,
    required this.time,
    required this.date,
    required this.type,
    required this.cast,
    required this.cast_images,
    required this.status,
    required this.trailer,
    required this.director,
    required this.direc_images,
    required this.recommend,
  });

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static DateTime _toDate(dynamic v, {DateTime? fallback}) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? (fallback ?? DateTime(1970));
    return fallback ?? DateTime(1970);
  }

  static List<String> _toListString(dynamic v) {
    if (v is List) return v.where((e) => e != null).map((e) => e.toString()).toList();
    return const <String>[];
  }

  factory MovieModel.fromMap(Map<String, dynamic> json, String id) {
    return MovieModel(
      id: id,
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      images: (json['images'] ?? '').toString(),
      time: _toInt(json['time'], fallback: 0),       // 👈 สำคัญ
      date: _toDate(json['date'], fallback: DateTime(1970)),
      type: _toListString(json['type']),
      cast: _toListString(json['cast']),
      cast_images: _toListString(json['cast_images']),
      status: (json['status'] ?? '').toString(),
      trailer: (json['trailer'] ?? '').toString(),
      director: _toListString(json['director']),
      direc_images: _toListString(json['direc_images']),
      recommend: _toListString(json['recommend']),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'images': images,
        'time': time,
        'date': date,
        'type': type,
        'cast': cast,
        'cast_images': cast_images,
        'status': status,
        'trailer': trailer,
        'director': director,
        'direc_images': direc_images,
        'recommend': recommend,
      };
  
  /// จับคู่ name <-> image จาก 2 อาเรย์ แบบปลอดภัย
  List<({String name, String image})> get castPairs {
    final len = cast.length < cast_images.length ? cast.length : cast_images.length;
    return List.generate(len, (i) => (name: cast[i], image: cast_images[i]));
  }
}