import 'package:shared_preferences/shared_preferences.dart';

class AuthStorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'auth_user_id';
  static const String _nameKey = 'auth_name';
  static const String _emailKey = 'auth_email';
  static const String _roleKey = 'auth_role';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);

    // Cadangan supaya tetap cocok kalau kode lama pernah pakai key lain.
    await prefs.setString('token', token);
    await prefs.setString('access_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString(_tokenKey);

    if (token != null && token.trim().isNotEmpty) {
      return token;
    }

    final oldToken = prefs.getString('token');

    if (oldToken != null && oldToken.trim().isNotEmpty) {
      return oldToken;
    }

    final accessToken = prefs.getString('access_token');

    if (accessToken != null && accessToken.trim().isNotEmpty) {
      return accessToken;
    }

    return null;
  }

  static Future<void> saveUser({
    required int id,
    required String name,
    required String email,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_userIdKey, id);
    await prefs.setString(_nameKey, name);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_roleKey, role);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.trim().isNotEmpty;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_roleKey);

    await prefs.remove('token');
    await prefs.remove('access_token');
  }
}
