import 'package:mongo_dart/mongo_dart.dart';
import 'database_service.dart';
import '../models/user.dart';

class UserService {
  // REGISTER
  static Future<Map<String, dynamic>> register({
    required String nama,
    required String email,
    required String password,
  }) async {
    try {
      final col = await DatabaseService.getUsers();
      final existing = await col.findOne({'email': email});
      if (existing != null) {
        return {'success': false, 'message': 'Email sudah terdaftar!'};
      }
      final user = User(nama: nama, email: email, password: password);
      await col.insertOne(user.toMap());
      return {'success': true, 'message': 'Registrasi berhasil!'};
    } catch (e) {
      print('❌ Error register: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // LOGIN
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final col = await DatabaseService.getUsers();
      final data = await col.findOne({
        'email': email,
        'password': password,
      });
      if (data == null) {
        return {'success': false, 'message': 'Email atau password salah!'};
      }
      return {
        'success': true,
        'message': 'Login berhasil!',
        'data': User.fromMap(data),
      };
    } catch (e) {
      print('❌ Error login: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // GET USER BY ID
  static Future<User?> getUserById(String id) async {
    try {
      final col = await DatabaseService.getUsers();
      final data = await col.findOne(
        where.id(ObjectId.fromHexString(id)),
      );
      if (data == null) return null;
      return User.fromMap(data);
    } catch (e) {
      print('❌ Error getUserById: $e');
      return null;
    }
  }

  // UPDATE USER
  static Future<Map<String, dynamic>> updateUser({
    required String id,
    String? nama,
    String? email,
  }) async {
    try {
      final col = await DatabaseService.getUsers();
      await col.updateOne(
        where.id(ObjectId.fromHexString(id)),
        modify
            .set('nama', nama)
            .set('email', email),
      );
      return {'success': true, 'message': 'Profil berhasil diupdate!'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // DELETE USER
  static Future<Map<String, dynamic>> deleteUser(String id) async {
    try {
      final col = await DatabaseService.getUsers();
      await col.deleteOne(
        where.id(ObjectId.fromHexString(id)),
      );
      return {'success': true, 'message': 'User berhasil dihapus!'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}