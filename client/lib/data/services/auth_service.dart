import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'dio_client.dart';

class AuthService {
  final Dio _dio = DioClient().dio;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );

      final data = Map<String, dynamic>.from(response.data);
      final token = data['token']?.toString();
      final user = data['user'] != null
          ? UserModel.fromJson(Map<String, dynamic>.from(data['user']))
          : null;

      if (token == null || user == null) {
        throw Exception('Response login tidak valid');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('user', jsonEncode(user.toJson()));

      return {
        'token': token,
        'user': user,
        'message': data['message']?.toString() ?? 'Login berhasil',
      };
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String username,
    required String phone,
    required String address,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/register',
        data: {
          'name': name,
          'username': username,
          'phone': phone,
          'address': address,
          'email': email,
          'password': password,
          'password_confirmation': password,
        },
      );

      final data = Map<String, dynamic>.from(response.data);
      final token = data['token']?.toString();
      final user = data['user'] != null
          ? UserModel.fromJson(Map<String, dynamic>.from(data['user']))
          : null;

      if (token == null || user == null) {
        throw Exception('Response register tidak valid');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('user', jsonEncode(user.toJson()));

      return {
        'token': token,
        'user': user,
        'message': data['message']?.toString() ?? 'Registrasi berhasil',
      };
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/logout');
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<UserModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user');

    if (raw == null || raw.isEmpty) return null;

    final map = jsonDecode(raw) as Map<String, dynamic>;
    return UserModel.fromJson(map);
  }

  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      if (data['message'] != null) {
        return data['message'].toString();
      }

      if (data['errors'] is Map<String, dynamic>) {
        final errors = data['errors'] as Map<String, dynamic>;
        if (errors.isNotEmpty) {
          final key = errors.keys.first;
          final value = errors[key];
          if (value is List && value.isNotEmpty) {
            return value.first.toString();
          }
          return value.toString();
        }
      }
    }

    return 'Terjadi kesalahan saat terhubung ke server';
  }
}
