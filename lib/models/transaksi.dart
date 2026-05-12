import 'package:mongo_dart/mongo_dart.dart';

class Transaksi {
  final ObjectId? id;
  final ObjectId userId;
  final String tipe;
  final double nominal;
  final String judul;
  final String kategori;
  final DateTime tanggal;

  Transaksi({
    this.id,
    required this.userId,
    required this.tipe,
    required this.nominal,
    required this.judul,
    required this.kategori,
    DateTime? tanggal,
  }) : tanggal = tanggal ?? DateTime.now().toLocal();

  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      id: map['_id'] as ObjectId?,
      userId: map['user_id'] as ObjectId,
      tipe: map['tipe'] as String,
      nominal: (map['nominal'] as num).toDouble(),
      judul: map['judul'] as String,
      kategori: map['kategori'] as String,
      tanggal: map['tanggal'] != null 
          ? (map['tanggal'] as DateTime).toLocal()
          : DateTime.now().toLocal(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'user_id': userId,
      'tipe': tipe,
      'nominal': nominal,
      'judul': judul,
      'kategori': kategori,
      'tanggal': tanggal.toUtc(),
    };
  }
}