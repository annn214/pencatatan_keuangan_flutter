import 'package:mongo_dart/mongo_dart.dart';

class User {
  ObjectId? id;
  String nama;
  String email;
  String password;
  DateTime tanggalDaftar;

  User({
    this.id,
    required this.nama,
    required this.email,
    required this.password,
    DateTime? tanggalDaftar,
  }) : tanggalDaftar = tanggalDaftar ?? DateTime.now();

  // Simpan ke MongoDB
  Map<String, dynamic> toMap() {
    return {
      '_id': id ?? ObjectId(),
      'nama': nama,
      'email': email,
      'password': password,
      'tanggal_daftar': tanggalDaftar.toIso8601String(),
    };
  }

  // Ambil dari MongoDB
  factory User.fromMap(Map<String, dynamic> map) {
    final rawTanggalDaftar = map['tanggal_daftar'];

    return User(
      id: map['_id'],
      nama: map['nama'],
      email: map['email'],
      password: map['password'],
      tanggalDaftar: rawTanggalDaftar is DateTime
          ? rawTanggalDaftar
          : DateTime.parse(rawTanggalDaftar as String),
    );
  }
}
