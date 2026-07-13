import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/Auth/data/user_model.dart';

class TokenStorage {
  TokenStorage(this._storage);
  final FlutterSecureStorage _storage;

  Future<String?> readToken() async => _storage.read(key: 'token');
  Future<void> saveToken(String token) async => _storage.write(key: 'token', value: token);
  
  Future<UserModel?> readUser() async {
    final userJson = await _storage.read(key: 'user');
    if (userJson == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
  
  Future<void> saveUser(UserModel user) async {
    await _storage.write(key: 'user', value: jsonEncode(user.toJson()));
  }
  
  Future<void> clear() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user');
  }
}

// Le provider — permet à apiClientProvider de récupérer TokenStorage
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(const FlutterSecureStorage());
});