import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  bool _isCheckingSession = true;
  String? _errorMessage;
  String? _successMessage;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isCheckingSession => _isCheckingSession;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  Future<void> checkSession() async {
    _isCheckingSession = true;
    notifyListeners();

    _token = await _authService.getSavedToken();
    _user = await _authService.getSavedUser();

    _isCheckingSession = false;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _setLoading();

    try {
      final result = await _authService.login(email: email, password: password);

      _token = result['token'] as String?;
      _user = result['user'] as UserModel?;
      _successMessage = result['message']?.toString();
      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      return false;
    } finally {
      _stopLoading();
    }
  }

  Future<bool> requestRegisterOtp({
    required String name,
    required String username,
    required String phone,
    required String address,
    required String email,
    required String password,
  }) async {
    _setLoading();

    try {
      _successMessage = await _authService.requestRegisterOtp(
        name: name,
        username: username,
        phone: phone,
        address: address,
        email: email,
        password: password,
      );

      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      return false;
    } finally {
      _stopLoading();
    }
  }

  Future<bool> verifyRegisterOtp({
    required String email,
    required String otp,
  }) async {
    _setLoading();

    try {
      final result = await _authService.verifyRegisterOtp(
        email: email,
        otp: otp,
      );

      _token = result['token'] as String?;
      _user = result['user'] as UserModel?;
      _successMessage = result['message']?.toString();
      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      return false;
    } finally {
      _stopLoading();
    }
  }

  Future<bool> register({
    required String name,
    required String username,
    required String phone,
    required String address,
    required String email,
    required String password,
  }) async {
    return requestRegisterOtp(
      name: name,
      username: username,
      phone: phone,
      address: address,
      email: email,
      password: password,
    );
  }

  Future<bool> requestPasswordResetOtp({required String email}) async {
    _setLoading();

    try {
      _successMessage = await _authService.requestPasswordResetOtp(
        email: email,
      );

      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      return false;
    } finally {
      _stopLoading();
    }
  }

  Future<bool> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String password,
  }) async {
    _setLoading();

    try {
      _successMessage = await _authService.resetPasswordWithOtp(
        email: email,
        otp: otp,
        password: password,
      );

      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      return false;
    } finally {
      _stopLoading();
    }
  }

  Future<void> logout() async {
    await _authService.logout();

    _token = null;
    _user = null;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void _setLoading() {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void _stopLoading() {
    _isLoading = false;
    notifyListeners();
  }

  String _cleanError(Object e) {
    return e.toString().replaceFirst('Exception: ', '');
  }
}
