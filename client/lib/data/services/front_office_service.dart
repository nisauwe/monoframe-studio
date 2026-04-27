import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/front_office_models.dart';
import 'dio_client.dart';

class FrontOfficeService {
  final Dio _dio = DioClient().dio;

  Future<List<FoPackageModel>> getPackages() async {
    final response = await _dio.get('/front-office/packages');
    final list = _extractList(response.data);

    return list
        .map((item) => FoPackageModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<FoAddonModel>> getAddonSettings() async {
    final response = await _dio.get('/front-office/addon-settings');
    final list = _extractList(response.data);

    return list
        .map((item) => FoAddonModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<FoScheduleSlotModel>> getAvailableSlots({
    required int packageId,
    required String bookingDate,
    required int extraDurationUnits,
  }) async {
    final response = await _dio.get(
      '/front-office/available-slots',
      queryParameters: {
        'package_id': packageId,
        'booking_date': bookingDate,
        'extra_duration_units': extraDurationUnits,
      },
    );

    final list = _extractList(response.data);

    return list
        .map(
          (item) =>
              FoScheduleSlotModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<FoBookingModel> createManualBooking({
    required int packageId,
    required String clientName,
    required String clientPhone,
    required String? clientEmail,
    required String bookingDate,
    required String startTime,
    required int extraDurationUnits,
    required String? locationName,
    required String? notes,
    required String? videoAddonType,
    required List<XFile> moodboards,
  }) async {
    final files = <MultipartFile>[];

    for (final file in moodboards) {
      files.add(
        await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      );
    }

    final formData = FormData.fromMap({
      'package_id': packageId,
      'client_name': clientName,
      'client_phone': clientPhone,
      if (clientEmail != null && clientEmail.isNotEmpty)
        'client_email': clientEmail,
      'booking_date': bookingDate,
      'start_time': startTime,
      'extra_duration_units': extraDurationUnits,
      if (locationName != null && locationName.isNotEmpty)
        'location_name': locationName,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (videoAddonType != null && videoAddonType.isNotEmpty)
        'video_addon_type': videoAddonType,
      if (files.isNotEmpty) 'moodboards[]': files,
    });

    try {
      final response = await _dio.post(
        '/front-office/bookings/manual',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final map = _extractDataMap(response.data);
      return FoBookingModel.fromJson(map);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal membuat booking manual'));
    }
  }

  Future<List<FoBookingModel>> getAssignableBookings() async {
    try {
      final response = await _dio.get('/front-office/bookings/assignable');
      debugPrint('ASSIGNABLE BOOKINGS: ${response.data}');
      final list = _extractList(response.data);

      return list
          .map(
            (item) => FoBookingModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal mengambil booking assignable'));
    }
  }

  Future<List<FoPhotographerModel>> getAvailablePhotographers({
    required int bookingId,
  }) async {
    try {
      final response = await _dio.get(
        '/front-office/bookings/$bookingId/available-photographers',
      );

      final list = _extractList(response.data);

      return list
          .map(
            (item) =>
                FoPhotographerModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _messageFromDio(e, 'Gagal mengambil fotografer tersedia'),
      );
    }
  }

  Future<FoBookingModel> assignPhotographer({
    required int bookingId,
    required int photographerUserId,
  }) async {
    try {
      final response = await _dio.patch(
        '/front-office/bookings/$bookingId/assign-photographer',
        data: {'photographer_user_id': photographerUserId},
      );

      final map = _extractDataMap(response.data);
      return FoBookingModel.fromJson(map);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal assign fotografer'));
    }
  }

  Future<List<FoCalendarEventModel>> getCalendar({
    required String startDate,
    required String endDate,
    int? photographerUserId,
  }) async {
    try {
      final response = await _dio.get(
        '/front-office/calendar',
        queryParameters: {
          'start_date': startDate,
          'end_date': endDate,
          if (photographerUserId != null)
            'photographer_user_id': photographerUserId,
        },
      );

      final list = _extractList(response.data);

      return list
          .map(
            (item) =>
                FoCalendarEventModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal mengambil kalender'));
    }
  }

  Future<List<FoProgressModel>> getProgress({
    String? bookingDate,
    String? status,
    String? search,
    int? photographerUserId,
  }) async {
    try {
      final response = await _dio.get(
        '/front-office/progress',
        queryParameters: {
          if (bookingDate != null && bookingDate.isNotEmpty)
            'booking_date': bookingDate,
          if (status != null && status.isNotEmpty) 'status': status,
          if (search != null && search.isNotEmpty) 'search': search,
          if (photographerUserId != null)
            'photographer_user_id': photographerUserId,
        },
      );

      final list = _extractList(response.data);

      return list
          .map(
            (item) => FoProgressModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal mengambil progress'));
    }
  }

  Future<Map<String, dynamic>> getProgressDetail({
    required int bookingId,
  }) async {
    try {
      final response = await _dio.get('/front-office/progress/$bookingId');
      return _extractDataMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal mengambil detail progress'));
    }
  }

  Future<FoFinanceSummaryModel> getFinanceSummary({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _dio.get(
        '/front-office/finance/summary',
        queryParameters: {
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
        },
      );

      return FoFinanceSummaryModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal mengambil ringkasan keuangan'));
    }
  }

  Future<void> storeExpense({
    required String expenseDate,
    required String category,
    required int amount,
    required String description,
  }) async {
    try {
      await _dio.post(
        '/front-office/expenses',
        data: {
          'expense_date': expenseDate,
          'category': category,
          'amount': amount,
          'description': description,
        },
      );
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal menyimpan pengeluaran'));
    }
  }

  Future<List<FoPrintOrderModel>> getPrintOrders() async {
    try {
      final response = await _dio.get('/front-office/print-orders');
      final list = _extractList(response.data);

      return list
          .map(
            (item) =>
                FoPrintOrderModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal mengambil pesanan cetak'));
    }
  }

  Future<FoPrintOrderModel> getPrintOrderDetail({
    required int printOrderId,
  }) async {
    try {
      final response = await _dio.get(
        '/front-office/print-orders/$printOrderId',
      );
      final map = _extractDataMap(response.data);

      return FoPrintOrderModel.fromJson(map);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal mengambil detail cetak'));
    }
  }

  Future<FoPrintOrderModel> confirmPrintOrder({
    required int printOrderId,
    String? notes,
  }) async {
    try {
      final response = await _dio.patch(
        '/front-office/print-orders/$printOrderId/confirm',
        data: {
          if (notes != null && notes.isNotEmpty) 'front_office_notes': notes,
        },
      );

      return FoPrintOrderModel.fromJson(_extractDataMap(response.data));
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal konfirmasi pesanan cetak'));
    }
  }

  Future<FoPrintOrderModel> markPrintOrderReady({
    required int printOrderId,
  }) async {
    try {
      final response = await _dio.patch(
        '/front-office/print-orders/$printOrderId/ready',
      );

      return FoPrintOrderModel.fromJson(_extractDataMap(response.data));
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal update status siap'));
    }
  }

  Future<FoPrintOrderModel> completePrintOrder({
    required int printOrderId,
  }) async {
    try {
      final response = await _dio.patch(
        '/front-office/print-orders/$printOrderId/complete',
      );

      return FoPrintOrderModel.fromJson(_extractDataMap(response.data));
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal menyelesaikan pesanan cetak'));
    }
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;

    if (data is Map && data['data'] is List) {
      return data['data'] as List;
    }

    if (data is Map && data['data'] is Map) {
      final dataMap = Map<String, dynamic>.from(data['data']);

      if (dataMap['data'] is List) {
        return dataMap['data'] as List;
      }
    }

    return [];
  }

  Map<String, dynamic> _extractDataMap(dynamic data) {
    if (data is! Map) return {};

    final root = Map<String, dynamic>.from(data);

    if (root['data'] is Map) {
      return Map<String, dynamic>.from(root['data']);
    }

    return root;
  }

  String _messageFromDio(DioException e, String fallback) {
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      if (data['message'] != null) {
        return data['message'].toString();
      }

      if (data['errors'] is Map<String, dynamic>) {
        final errors = data['errors'] as Map<String, dynamic>;

        if (errors.isNotEmpty) {
          final value = errors.values.first;

          if (value is List && value.isNotEmpty) {
            return value.first.toString();
          }

          return value.toString();
        }
      }
    }

    return fallback;
  }
}
