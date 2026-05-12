import 'package:mongo_dart/mongo_dart.dart';

class DatabaseService {
  static Db? _db;

  static const String connectionString =
      'mongodb+srv://muhdimas_db_user:qvHqfYNeLRTP16Oh@cluster0.e8xuege.mongodb.net/Keuangan_db?appName=Cluster0';

  static Future<void> connect() async {
    try {
      if (_db != null && _db!.isConnected) return;
      _db = await Db.create(connectionString);
      await _db!.open();
      print('✅ Berhasil konek ke MongoDB!');
    } catch (e) {
      print('❌ Gagal konek: $e');
      _db = null;
    }
  }

  static bool get isConnected => _db != null && _db!.isConnected;

  static DbCollection get users {
    if (_db == null || !_db!.isConnected) {
      throw Exception('Database belum terkoneksi!');
    }
    return _db!.collection('users');
  }

  static DbCollection get transaksi {
    if (_db == null || !_db!.isConnected) {
      throw Exception('Database belum terkoneksi!');
    }
    return _db!.collection('transaksi');
  }

  static DbCollection get kategori {
    if (_db == null || !_db!.isConnected) {
      throw Exception('Database belum terkoneksi!');
    }
    return _db!.collection('kategori');
  }

  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}