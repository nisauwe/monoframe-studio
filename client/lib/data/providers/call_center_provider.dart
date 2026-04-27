import 'package:flutter/material.dart';

import '../models/call_center_contact_model.dart';
import '../services/call_center_service.dart';

class CallCenterProvider extends ChangeNotifier {
  final CallCenterService _service = CallCenterService();

  bool _isLoading = false;
  String? _errorMessage;
  List<CallCenterContactModel> _contacts = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<CallCenterContactModel> get contacts => _contacts;

  Future<void> fetchContacts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _contacts = await _service.getContacts();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
