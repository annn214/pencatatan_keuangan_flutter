import 'package:mongo_dart/mongo_dart.dart';
import 'database_service.dart';
import '../models/kategori.dart';

class KategoriService {

  // CREATE - Tambah kategori baru
  static Future<Map<String, dynamic>> tambahKategori({
    required String nama,
    required String ikon,
  }) async {
    try {
      final kategori = Kategori(
        nama: nama,
        ikon: ikon,
      );

      await DatabaseService.kategori.insertOne(kategori.toMap());
      return {'success': true, 'message': 'Kategori berhasil ditambahkan!'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // READ - Ambil semua kategori
  static Future<List<Kategori>> getAllKategori() async {
    try {
      final data = await DatabaseService.kategori
          .find().toList();
      return data.map((e) => Kategori.fromMap(e)).toList();
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  // DELETE - Hapus kategori
  static Future<Map<String, dynamic>> deleteKategori(String id) async {
    try {
      await DatabaseService.kategori.deleteOne(
        where.id(ObjectId.fromHexString(id)),
      );
      return {'success': true, 'message': 'Kategori berhasil dihapus!'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}