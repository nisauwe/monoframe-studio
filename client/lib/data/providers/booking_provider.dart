import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/booking_addon_setting_model.dart';
import '../models/booking_model.dart';
import '../models/schedule_slot_model.dart';
import '../services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _service = BookingService();

  bool _isLoadingSlots = false;
  bool _isLoadingAddons = false;
  bool _isLoadingBookings = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<ScheduleSlotModel> _slots = [];
  List<BookingAddonSettingModel> _addons = [];
  List<BookingModel> _bookings = [];
  BookingModel? _lastCreatedBooking;

  bool get isLoadingSlots => _isLoadingSlots;
  bool get isLoadingAddons => _isLoadingAddons;
  bool get isLoadingBookings => _isLoadingBookings;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  List<ScheduleSlotModel> get slots => _slots;
  List<BookingAddonSettingModel> get addons => _addons;
  List<BookingModel> get bookings => _bookings;
  BookingModel? get lastCreatedBooking => _lastCreatedBooking;

  Future<void> fetchBookings() async {
    _isLoadingBookings = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _bookings = await _service.getBookings();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingBookings = false;
      notifyListeners();
    }
  }

  Future<void> fetchAddons() async {
    _isLoadingAddons = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _addons = await _service.getAddonSettings();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingAddons = false;
      notifyListeners();
    }
  }

  Future<void> fetchSlots({
    required int packageId,
    required String bookingDate,
    required int extraDurationUnits,
  }) async {
    _isLoadingSlots = true;
    _errorMessage = null;
    _slots = [];
    notifyListeners();

    try {
      _slots = await _service.getAvailableSlots(
        packageId: packageId,
        bookingDate: bookingDate,
        extraDurationUnits: extraDurationUnits,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingSlots = false;
      notifyListeners();
    }
  }

  Future<bool> submitBooking({
    required int packageId,
    required String bookingDate,
    required String startTime,
    required int extraDurationUnits,
    required String? locationName,
    required String? notes,
    required String? videoAddonType,
    required List<XFile> moodboards,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _lastCreatedBooking = await _service.createBooking(
        packageId: packageId,
        bookingDate: bookingDate,
        startTime: startTime,
        extraDurationUnits: extraDurationUnits,
        locationName: locationName,
        notes: notes,
        videoAddonType: videoAddonType,
        moodboards: moodboards,
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

  void clearSlots() {
    _slots = [];
    notifyListeners();
  }
}
