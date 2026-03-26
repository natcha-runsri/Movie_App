import 'package:cloud_firestore/cloud_firestore.dart';

class CinemaModel {
  final String id;
  final String name;
  final String address;
  final String phone;
  final GeoPoint? location;
  final int screen;

  CinemaModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.location,
    required this.screen,
  });

  factory CinemaModel.fromMap(Map<String, dynamic> json, String id) {
    return CinemaModel(
      id: id,
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      location: json['location'] is GeoPoint ? json['location'] as GeoPoint : null,
      screen: (json['screen'] ?? 0) is num ? (json['screen'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'address': address,
    'phone': phone,
    'location': location,
    'screen': screen,
  };

  static const collection = 'cinema';
}
