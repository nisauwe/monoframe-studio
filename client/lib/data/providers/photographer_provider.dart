import 'package:flutter/material.dart';

import '../models/photographer_models.dart';
import '../services/photographer_service.dart';

class PhotographerProvider extends ChangeNotifier {
  final PhotographerService _service = PhotographerService();

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<PhotographerBookingModel> _bookings = [];
  PhotographerBookingModel? _selectedBooking;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  List<PhotographerBookingModel> get bookings => _bookings;
  PhotographerBookingModel? get selectedBooking => _selectedBooking;

  List<PhotographerBookingModel> get todayBookings {
    return _bookings.where((item) => item.isToday).toList();
  }

  List<PhotographerBookingModel> get upcomingBookings {
    return _bookings.where((item) => item.isUpcoming).toList();
  }

  List<PhotographerBookingModel> get pastBookings {
    return _bookings.where((item) => item.isPast).toList();
  }

  List<PhotographerBookingModel> get needUploadBookings {
    return _bookings.where((item) {
      return !item.hasPhotoLink &&
          item.status.toLowerCase() != 'cancelled' &&
          item.status.toLowerCase() != 'completed';
    }).toList();
  }

  Future<void> fetchBookings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _bookings = await _service.getAssignedBookings();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBookingDetail({required int bookingId}) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedBooking = null;
    notifyListeners();

    try {
      _selectedBooking = await _service.getBookingDetail(bookingId: bookingId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> storePhotoLink({
    required int bookingId,
    required String driveUrl,
    required String? driveLabel,
    required String? notes,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.storePhotoLink(
        bookingId: bookingId,
        driveUrl: driveUrl,
        driveLabel: driveLabel,
        notes: notes,
      );

      await fetchBookingDetail(bookingId: bookingId);
      await fetchBookings();

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearSelectedBooking() {
    _selectedBooking = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
