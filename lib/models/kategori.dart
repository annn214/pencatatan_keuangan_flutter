import 'package:mongo_dart/mongo_dart.dart';

class Kategori {
  ObjectId? id;
  String nama;
  String ikon;

  Kategori({
    this.id,
    required this.nama,
    required this.ikon,
  });

  // Simpan ke MongoDB
  Map<String, dynamic> toMap() {
    return {
      '_id': id ?? ObjectId(),
      'nama': nama,
      'ikon': ikon,
    };
  }

  // Ambil dari MongoDB
  factory Kategori.fromMap(Map<String, dynamic> map) {
    return Kategori(
      id: map['_id'],
      nama: map['nama'],
      ikon: map['ikon'],
    );
  }
}