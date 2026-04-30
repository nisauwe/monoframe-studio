import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/front_office_models.dart';
import '../services/front_office_service.dart';

class FrontOfficeProvider extends ChangeNotifier {
  int _reviewCount = 0;
  int get reviewCount => _reviewCount;

  final FrontOfficeService _service = FrontOfficeService();

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<FoPackageModel> _packages = [];
  List<FoAddonModel> _addons = [];
  List<FoScheduleSlotModel> _slots = [];
  List<FoBookingModel> _assignableBookings = [];
  List<FoPhotographerModel> _availablePhotographers = [];
  List<FoCalendarEventModel> _calendarEvents = [];
  List<FoProgressModel> _progressList = [];
  List<FoPrintOrderModel> _printOrders = [];
  List<FoIncomeModel> _incomes = [];

  FoFinanceSummaryModel? _financeSummary;
  FoPrintOrderModel? _selectedPrintOrder;
  Map<String, dynamic>? _selectedProgressDetail;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  List<FoPackageModel> get packages => _packages;
  List<FoAddonModel> get addons => _addons;
  List<FoScheduleSlotModel> get slots => _slots;
  List<FoBookingModel> get assignableBookings => _assignableBookings;
  List<FoPhotographerModel> get availablePhotographers =>
      _availablePhotographers;
  List<FoCalendarEventModel> get calendarEvents => _calendarEvents;
  List<FoProgressModel> get progressList => _progressList;
  List<FoPrintOrderModel> get printOrders => _printOrders;
  List<FoIncomeModel> get incomes => _incomes;

  FoFinanceSummaryModel? get financeSummary => _financeSummary;
  FoPrintOrderModel? get selectedPrintOrder => _selectedPrintOrder;
  Map<String, dynamic>? get selectedProgressDetail => _selectedProgressDetail;

  Future<void> fetchManualAvailablePhotographers({
    required String bookingDate,
    required String startTime,
    required String endTime,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _availablePhotographers = [];
    notifyListeners();

    try {
      _availablePhotographers = await _service.getManualAvailablePhotographers(
        bookingDate: bookingDate,
        startTime: startTime,
        endTime: endTime,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      final results = await Future.wait([
        _service.getAssignableBookings(),
        _service.getCalendar(
          startDate: _formatDate(startDate),
          endDate: _formatDate(endDate),
        ),
        _service.getProgress(),
        _service.getFinanceSummary(
          startDate: _formatDate(startDate),
          endDate: _formatDate(endDate),
        ),
        _service.getPrintOrders(),
        _service.getReviewCount(),
      ]);

      _assignableBookings = results[0] as List<FoBookingModel>;
      _calendarEvents = results[1] as List<FoCalendarEventModel>;
      _progressList = results[2] as List<FoProgressModel>;
      _financeSummary = results[3] as FoFinanceSummaryModel;
      _printOrders = results[4] as List<FoPrintOrderModel>;
      _reviewCount = results[5] as int;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchManualBookingResources() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await Future.wait([
        _service.getPackages(),
        _service.getAddonSettings(),
      ]);

      _packages = result[0] as List<FoPackageModel>;
      _addons = result[1] as List<FoAddonModel>;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSlots({
    required int packageId,
    required String bookingDate,
    required int extraDurationUnits,
  }) async {
    _isLoading = true;
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
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createManualBooking({
    required int packageId,
    required String clientName,
    required String clientPhone,
    required String? clientEmail,
    required String bookingDate,
    required String startTime,
    required int extraDurationUnits,
    required int photographerUserId,
    required String? locationName,
    required String? notes,
    required String? videoAddonType,
    required List<XFile> moodboards,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.createManualBooking(
        packageId: packageId,
        clientName: clientName,
        clientPhone: clientPhone,
        clientEmail: clientEmail,
        bookingDate: bookingDate,
        startTime: startTime,
        extraDurationUnits: extraDurationUnits,
        photographerUserId: photographerUserId,
        locationName: locationName,
        notes: notes,
        videoAddonType: videoAddonType,
        moodboards: moodboards,
      );

      await fetchAssignableBookings();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> fetchAssignableBookings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _assignableBookings = await _service.getAssignableBookings();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAvailablePhotographers({required int bookingId}) async {
    _isLoading = true;
    _errorMessage = null;
    _availablePhotographers = [];
    notifyListeners();

    try {
      _availablePhotographers = await _service.getAvailablePhotographers(
        bookingId: bookingId,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> assignPhotographer({
    required int bookingId,
    required int photographerUserId,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.assignPhotographer(
        bookingId: bookingId,
        photographerUserId: photographerUserId,
      );

      await fetchAssignableBookings();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> fetchCalendar({
    required String startDate,
    required String endDate,
    int? photographerUserId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _calendarEvents = await _service.getCalendar(
        startDate: startDate,
        endDate: endDate,
        photographerUserId: photographerUserId,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProgress({
    String? bookingDate,
    String? status,
    String? search,
    int? photographerUserId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _progressList = await _service.getProgress(
        bookingDate: bookingDate,
        status: status,
        search: search,
        photographerUserId: photographerUserId,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProgressDetail({required int bookingId}) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedProgressDetail = null;
    notifyListeners();

    try {
      _selectedProgressDetail = await _service.getProgressDetail(
        bookingId: bookingId,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFinanceSummary({String? startDate, String? endDate}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _financeSummary = await _service.getFinanceSummary(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchIncomes({String? startDate, String? endDate}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _incomes = await _service.getIncomes(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> storeIncome({
    required String incomeDate,
    required String category,
    required int amount,
    required String description,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.storeIncome(
        incomeDate: incomeDate,
        category: category,
        amount: amount,
        description: description,
      );

      await fetchFinanceSummary();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> storeExpense({
    required String expenseDate,
    required String category,
    required int amount,
    required String description,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.storeExpense(
        expenseDate: expenseDate,
        category: category,
        amount: amount,
        description: description,
      );

      await fetchFinanceSummary();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> fetchPrintOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _printOrders = await _service.getPrintOrders();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPrintOrderDetail({required int printOrderId}) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedPrintOrder = null;
    notifyListeners();

    try {
      _selectedPrintOrder = await _service.getPrintOrderDetail(
        printOrderId: printOrderId,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> confirmPrintOrder({
    required int printOrderId,
    String? notes,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedPrintOrder = await _service.confirmPrintOrder(
        printOrderId: printOrderId,
        notes: notes,
      );

      await fetchPrintOrders();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> markPrintOrderReady({required int printOrderId}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedPrintOrder = await _service.markPrintOrderReady(
        printOrderId: printOrderId,
      );

      await fetchPrintOrders();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> completePrintOrder({required int printOrderId}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedPrintOrder = await _service.completePrintOrder(
        printOrderId: printOrderId,
      );

      await fetchPrintOrders();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
