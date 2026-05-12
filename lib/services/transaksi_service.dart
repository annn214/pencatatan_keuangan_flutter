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
      final col = await DatabaseService.getTransaksi();
      final transaksi = Transaksi(
        userId: ObjectId.fromHexString(userId),
        tipe: tipe,
        nominal: nominal,
        judul: judul,
        kategori: kategori,
      );
      await col.insertOne(transaksi.toMap());
      return {'success': true, 'message': 'Transaksi berhasil ditambahkan!'};
    } catch (e) {
      print('❌ Error tambah transaksi: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // READ - Ambil semua transaksi user
  static Future<List<Transaksi>> getTransaksiByUser(String userId) async {
    try {
      final col = await DatabaseService.getTransaksi();
      final data = await col.find({
        'user_id': ObjectId.fromHexString(userId),
      }).toList();
      return data.map((e) => Transaksi.fromMap(e)).toList();
    } catch (e) {
      print('❌ Error get transaksi: $e');
      return [];
    }
  }

  // UPDATE - Edit transaksi
  static Future<Map<String, dynamic>> updateTransaksi({
    required String id,
    required String tipe,
    required double nominal,
    required String judul,
    required String kategori,
  }) async {
    try {
      final col = await DatabaseService.getTransaksi();
      await col.updateOne(
        where.id(ObjectId.fromHexString(id)),
        modify
            .set('tipe', tipe)
            .set('nominal', nominal)
            .set('judul', judul)
            .set('kategori', kategori),
      );
      return {'success': true, 'message': 'Transaksi berhasil diperbarui!'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // DELETE - Hapus transaksi
  static Future<Map<String, dynamic>> deleteTransaksi(String id) async {
    try {
      final col = await DatabaseService.getTransaksi();
      await col.deleteOne(
        where.id(ObjectId.fromHexString(id)),
      );
      return {'success': true, 'message': 'Transaksi berhasil dihapus!'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}