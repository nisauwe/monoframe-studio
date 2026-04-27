import 'package:flutter/material.dart';

import '../models/tracking_model.dart';
import '../services/tracking_service.dart';

class TrackingProvider extends ChangeNotifier {
  final TrackingService _service = TrackingService();

  bool _isLoading = false;
  String? _errorMessage;
  TrackingDetailModel? _detail;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  TrackingDetailModel? get detail => _detail;

  Future<void> fetchTrackingDetail({required int bookingId}) async {
    _isLoading = true;
    _errorMessage = null;
    _detail = null;
    notifyListeners();

    try {
      _detail = await _service.getTrackingDetail(bookingId: bookingId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _detail = null;
    _errorMessage = null;
    notifyListeners();
  }
}
