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

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isCheckingSession => _isCheckingSession;
  String? get errorMessage => _errorMessage;
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(email: email, password: password);

      _token = result['token'] as String?;
      _user = result['user'] as UserModel?;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.register(
        name: name,
        username: username,
        phone: phone,
        address: address,
        email: email,
        password: password,
      );

      _token = result['token'] as String?;
      _user = result['user'] as UserModel?;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _token = null;
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }
}
