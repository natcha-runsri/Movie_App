class ProfileModel {
  final String uid;
  final String name;
  final String email;
  final String tel;
  final String contact;
  final String birthdate;
  final String images;

  ProfileModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.tel,
    required this.contact,
    required this.birthdate,
    required this.images,
  });

  // แปลงเป็น JSON (สำหรับ Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'tel': tel,
      'contact': contact,
      'birthdate': birthdate,
      'images': images,
    };
  }

  // แปลงจาก Firestore Document
  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      tel: map['tel'] ?? '',
      contact: map['contact'] ?? '',
      birthdate: map['birthdate'] ?? '',
      images: map['images'] ?? '',
    );
  }

  // copyWith สำหรับแก้บางฟิลด์
  ProfileModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? tel,
    String? contact,
    String? birthdate,
    String? images,
  }) {
    return ProfileModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      tel: tel ?? this.tel,
      contact: contact ?? this.contact,
      birthdate: birthdate ?? this.birthdate,
      images: images ?? this.images,
    );
  }
}
