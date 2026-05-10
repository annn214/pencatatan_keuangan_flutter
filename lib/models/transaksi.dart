import 'package:mongo_dart/mongo_dart.dart';

class Transaksi {
  ObjectId? id;
  ObjectId? userId;
  String tipe; // 'Pemasukan' atau 'Pengeluaran'
  double nominal;
  String judul;
  String kategori;
  DateTime tanggal;

  Transaksi({
    this.id,
    this.userId,
    required this.tipe,
    required this.nominal,
    required this.judul,
    required this.kategori,
    DateTime? tanggal,
  }) : tanggal = tanggal ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      '_id': id ?? ObjectId(),
      'user_id': userId,
      'tipe': tipe,
      'nominal': nominal,
      'judul': judul,
      'kategori': kategori,
      'tanggal': tanggal.toIso8601String(),
    };
  }

  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      id: map['_id'],
      userId: map['user_id'],
      tipe: map['tipe'],
      nominal: map['nominal'].toDouble(),
      judul: map['judul'],
      kategori: map['kategori'],
      tanggal: DateTime.parse(map['tanggal']),
    );
  }
}