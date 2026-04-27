import 'package:flutter/material.dart';

import '../models/payment_snap_model.dart';
import '../models/print_order_model.dart';
import '../services/print_order_service.dart';

class PrintOrderProvider extends ChangeNotifier {
  final PrintOrderService _service = PrintOrderService();

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<PrintPriceModel> _prices = [];
  PrintOrderModel? _printOrder;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  List<PrintPriceModel> get prices => _prices;
  PrintOrderModel? get printOrder => _printOrder;

  Future<void> fetchPrices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _prices = await _service.getPrintPrices();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPrintOrder({required int bookingId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _printOrder = await _service.getPrintOrder(bookingId: bookingId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PrintOrderModel?> createPrintOrder({
    required int bookingId,
    required List<PrintOrderItemPayload> items,
    required String deliveryMethod,
    required String? recipientName,
    required String? recipientPhone,
    required String? deliveryAddress,
    required String? notes,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _printOrder = await _service.createPrintOrder(
        bookingId: bookingId,
        items: items,
        deliveryMethod: deliveryMethod,
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        deliveryAddress: deliveryAddress,
        notes: notes,
      );

      return _printOrder;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> skipPrint({required int bookingId}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.skipPrint(bookingId: bookingId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<PaymentSnapModel?> createPrintPayment({
    required int printOrderId,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _service.createPrintPayment(printOrderId: printOrderId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> checkPrintPaymentStatus({required int printOrderId}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _printOrder = await _service.checkPrintPaymentStatus(
        printOrderId: printOrderId,
      );

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
