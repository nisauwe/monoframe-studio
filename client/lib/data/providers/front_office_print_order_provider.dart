import 'package:flutter/material.dart';

import '../models/front_office_print_order_model.dart';
import '../services/front_office_print_order_service.dart';

class FrontOfficePrintOrderProvider extends ChangeNotifier {
  final FrontOfficePrintOrderService _service = FrontOfficePrintOrderService();

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String _selectedStatus = 'all';

  List<FrontOfficePrintOrderModel> _orders = [];

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String get selectedStatus => _selectedStatus;
  List<FrontOfficePrintOrderModel> get orders => _orders;

  Future<void> fetchOrders({String? status}) async {
    _isLoading = true;
    _errorMessage = null;

    if (status != null) {
      _selectedStatus = status;
    }

    notifyListeners();

    try {
      _orders = await _service.getPrintOrders(status: _selectedStatus);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markProcessing({required int printOrderId}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _service.markProcessing(printOrderId: printOrderId);
      _replaceOrder(updated);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> completePrintOrder({
    required int printOrderId,
    required String completionPhotoPath,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _service.completePrintOrder(
        printOrderId: printOrderId,
        completionPhotoPath: completionPhotoPath,
      );

      _replaceOrder(updated);

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void _replaceOrder(FrontOfficePrintOrderModel updated) {
    final index = _orders.indexWhere((item) => item.id == updated.id);

    if (index >= 0) {
      _orders[index] = updated;
    } else {
      _orders.insert(0, updated);
    }

    notifyListeners();
  }
}
