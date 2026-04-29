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
      return _saveAuthResponse(data, fallbackMessage: 'Login berhasil');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<String> requestRegisterOtp({
    required String name,
    required String username,
    required String phone,
    required String address,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/register/request-otp',
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
      return data['message']?.toString() ?? 'Kode OTP sudah dikirim ke email.';
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> verifyRegisterOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        '/register/verify-otp',
        data: {'email': email, 'otp': otp},
      );

      final data = Map<String, dynamic>.from(response.data);
      return _saveAuthResponse(data, fallbackMessage: 'Registrasi berhasil');
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
    await requestRegisterOtp(
      name: name,
      username: username,
      phone: phone,
      address: address,
      email: email,
      password: password,
    );

    return {
      'token': null,
      'user': null,
      'message': 'Kode OTP sudah dikirim ke email.',
    };
  }

  Future<String> requestPasswordResetOtp({required String email}) async {
    try {
      final response = await _dio.post(
        '/forgot-password/request-otp',
        data: {'email': email},
      );

      final data = Map<String, dynamic>.from(response.data);
      return data['message']?.toString() ??
          'Kode OTP reset password sudah dikirim ke email.';
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<String> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/forgot-password/reset',
        data: {
          'email': email,
          'otp': otp,
          'password': password,
          'password_confirmation': password,
        },
      );

      final data = Map<String, dynamic>.from(response.data);
      return data['message']?.toString() ??
          'Password berhasil diganti. Silakan login.';
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

  Future<Map<String, dynamic>> _saveAuthResponse(
    Map<String, dynamic> data, {
    required String fallbackMessage,
  }) async {
    final token = data['token']?.toString();
    final user = data['user'] != null
        ? UserModel.fromJson(Map<String, dynamic>.from(data['user']))
        : null;

    if (token == null || token.isEmpty || user == null) {
      throw Exception('Response autentikasi tidak valid');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode(user.toJson()));

    return {
      'token': token,
      'user': user,
      'message': data['message']?.toString() ?? fallbackMessage,
    };
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
          final firstKey = errors.keys.first;
          final firstValue = errors[firstKey];

          if (firstValue is List && firstValue.isNotEmpty) {
            return firstValue.first.toString();
          }

          return firstValue.toString();
        }
      }
    }

    return 'Terjadi kesalahan saat terhubung ke server.';
  }
}
