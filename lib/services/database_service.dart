import 'package:mongo_dart/mongo_dart.dart';

class DatabaseService {
  static Db? _db;

  static const String connectionString =
      'mongodb+srv://muhdimas_db_user:qvHqfYNeLRTP16Oh@cluster0.e8xuege.mongodb.net/Keuangan_db?appName=Cluster0';

  // Koneksi ke MongoDB
  static Future<void> connect() async {
    try {
      _db = await Db.create(connectionString);
      await _db!.open();
      print('✅ Berhasil konek ke MongoDB!');
    } catch (e) {
      print('❌ Gagal konek ke MongoDB: $e');
    }
  }

  // Ambil collection users
  static DbCollection get users => _db!.collection('users');

  // Ambil collection transaksi
  static DbCollection get transaksi => _db!.collection('transaksi');

  // Ambil collection kategori
  static DbCollection get kategori => _db!.collection('kategori');

  // Tutup koneksi
  static Future<void> close() async {
    await _db!.close();
    print('🔒 Koneksi MongoDB ditutup');
  }
}