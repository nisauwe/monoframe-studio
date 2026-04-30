import 'package:flutter/material.dart';

import '../models/app_setting_model.dart';
import '../services/app_setting_service.dart';

class AppSettingProvider extends ChangeNotifier {
  final AppSettingService _service = AppSettingService();

  AppSettingModel _setting = AppSettingModel.fallback();
  bool _isLoading = false;
  String? _errorMessage;

  AppSettingModel get setting => _setting;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isMaintenance => _setting.system.maintenanceMode;
  bool get canRegister => _setting.system.allowClientRegistration;
  bool get canBooking => _setting.booking.isActive;
  bool get canReview => _setting.review.isActive;
  bool get showPopularPackages => _setting.clientHome.showPopularPackages;
  bool get showClientReviews => _setting.clientHome.showClientReviews;
  bool get showSupportContact => _setting.clientHome.showSupportContact;

  Future<void> fetchSettings({bool forceRefresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _setting = await _service.getAppSettings();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setting = AppSettingModel.fallback();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await fetchSettings(forceRefresh: true);
  }
}
