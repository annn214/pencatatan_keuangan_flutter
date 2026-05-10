import 'package:mongo_dart/mongo_dart.dart';
import 'database_service.dart';
import '../models/transaksi.dart';

class TransaksiService {

  // CREATE - Tambah transaksi baru
  static Future<Map<String, dynamic>> tambahTransaksi({
    required String userId,
    required String tipe,
    required double nominal,
    required String judul,
    required String kategori,
  }) async {
    try {
      final transaksi = Transaksi(
        userId: ObjectId.fromHexString(userId),
        tipe: tipe,
        nominal: nominal,
        judul: judul,
        kategori: kategori,
      );

      await DatabaseService.transaksi.insertOne(transaksi.toMap());
      return {'success': true, 'message': 'Transaksi berhasil ditambahkan!'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // READ - Ambil semua transaksi user
  static Future<List<Transaksi>> getTransaksiByUser(String userId) async {
    try {
      final data = await DatabaseService.transaksi
          .find({'user_id': ObjectId.fromHexString(userId)})
          .toList();
      return data.map((e) => Transaksi.fromMap(e)).toList();
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  // READ - Ambil transaksi pemasukan saja
  static Future<List<Transaksi>> getPemasukan(String userId) async {
    try {
      final data = await DatabaseService.transaksi
          .find({'user_id': ObjectId.fromHexString(userId), 'tipe': 'Pemasukan'})
          .toList();
      return data.map((e) => Transaksi.fromMap(e)).toList();
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  // READ - Ambil transaksi pengeluaran saja
  static Future<List<Transaksi>> getPengeluaran(String userId) async {
    try {
      final data = await DatabaseService.transaksi
          .find({'user_id': ObjectId.fromHexString(userId), 'tipe': 'Pengeluaran'})
          .toList();
      return data.map((e) => Transaksi.fromMap(e)).toList();
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  // DELETE - Hapus transaksi
  static Future<Map<String, dynamic>> deleteTransaksi(String id) async {
    try {
      await DatabaseService.transaksi.deleteOne(
        where.id(ObjectId.fromHexString(id)),
      );
      return {'success': true, 'message': 'Transaksi berhasil dihapus!'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}