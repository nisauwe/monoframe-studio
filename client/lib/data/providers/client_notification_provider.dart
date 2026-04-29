import 'package:flutter/material.dart';

import '../models/client_notification_model.dart';
import '../services/client_notification_service.dart';

class ClientNotificationProvider extends ChangeNotifier {
  final ClientNotificationService _service = ClientNotificationService();

  bool _isLoading = false;
  String? _errorMessage;
  int _unreadCount = 0;
  List<ClientNotificationModel> _notifications = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _unreadCount;
  List<ClientNotificationModel> get notifications => _notifications;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.getNotifications();
      _unreadCount = response.unreadCount;
      _notifications = response.notifications;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await fetchNotifications();
  }
}
