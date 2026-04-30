import 'package:flutter/material.dart';

import '../models/payment_snap_model.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _service = PaymentService();

  bool _isLoading = false;
  bool _isCheckingStatus = false;
  bool _isCancellingBooking = false;
  String? _errorMessage;
  PaymentSnapModel? _snap;

  bool get isLoading => _isLoading;
  bool get isCheckingStatus => _isCheckingStatus;
  bool get isCancellingBooking => _isCancellingBooking;
  String? get errorMessage => _errorMessage;
  PaymentSnapModel? get snap => _snap;

  Future<PaymentSnapModel?> createPayment({
    required int bookingId,
    required String mode,
  }) async {
    _isLoading = true;
    _isCheckingStatus = false;
    _isCancellingBooking = false;
    _errorMessage = null;
    _snap = null;
    notifyListeners();

    try {
      _snap = await _service.createBookingPayment(
        bookingId: bookingId,
        mode: mode,
      );
      return _snap;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkPaymentStatus({required int bookingId}) async {
    _isCheckingStatus = true;
    _isLoading = false;
    _isCancellingBooking = false;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.checkBookingPaymentStatus(bookingId: bookingId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isCheckingStatus = false;
      notifyListeners();
    }
  }

  Future<bool> cancelBookingBeforePayment({
    required int bookingId,
    String? reason,
  }) async {
    _isCancellingBooking = true;
    _isLoading = false;
    _isCheckingStatus = false;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.cancelBookingBeforePayment(
        bookingId: bookingId,
        reason: reason,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isCancellingBooking = false;
      notifyListeners();
    }
  }
}
