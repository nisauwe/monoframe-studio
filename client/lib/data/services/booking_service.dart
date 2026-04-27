import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/booking_addon_setting_model.dart';
import '../models/booking_model.dart';
import '../models/schedule_slot_model.dart';
import 'dio_client.dart';

class BookingService {
  final Dio _dio = DioClient().dio;

  Future<List<BookingModel>> getBookings() async {
    try {
      final response = await _dio.get('/bookings');

      debugPrint('GET BOOKINGS RESPONSE: ${response.data}');

      final list = _extractList(response.data);

      return list.map((item) {
        return BookingModel.fromJson(Map<String, dynamic>.from(item));
      }).toList();
    } on DioException catch (e) {
      final data = e.response?.data;

      debugPrint('GET BOOKINGS ERROR: $data');

      if (data is Map<String, dynamic>) {
        if (data['message'] != null) {
          throw Exception(data['message'].toString());
        }

        if (data['errors'] is Map<String, dynamic>) {
          final errors = data['errors'] as Map<String, dynamic>;

          if (errors.isNotEmpty) {
            final firstKey = errors.keys.first;
            final value = errors[firstKey];

            if (value is List && value.isNotEmpty) {
              throw Exception(value.first.toString());
            }

            throw Exception(value.toString());
          }
        }
      }

      throw Exception('Gagal mengambil riwayat booking');
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<List<BookingAddonSettingModel>> getAddonSettings() async {
    try {
      final response = await _dio.get('/booking-addon-settings');

      debugPrint('GET ADDON SETTINGS RESPONSE: ${response.data}');

      final list = _extractList(response.data);

      return list.map((item) {
        return BookingAddonSettingModel.fromJson(
          Map<String, dynamic>.from(item),
        );
      }).toList();
    } on DioException catch (e) {
      final data = e.response?.data;

      debugPrint('GET ADDON SETTINGS ERROR: $data');

      if (data is Map<String, dynamic> && data['message'] != null) {
        throw Exception(data['message'].toString());
      }

      throw Exception('Gagal mengambil add-on booking');
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<List<ScheduleSlotModel>> getAvailableSlots({
    required int packageId,
    required String bookingDate,
    required int extraDurationUnits,
  }) async {
    try {
      final response = await _dio.get(
        '/schedules',
        queryParameters: {
          'package_id': packageId,
          'booking_date': bookingDate,
          'extra_duration_units': extraDurationUnits,
        },
      );

      debugPrint('GET AVAILABLE SLOTS RESPONSE: ${response.data}');

      final list = _extractList(response.data);

      return list.map((item) {
        return ScheduleSlotModel.fromJson(Map<String, dynamic>.from(item));
      }).toList();
    } on DioException catch (e) {
      final data = e.response?.data;

      debugPrint('GET AVAILABLE SLOTS ERROR: $data');

      if (data is Map<String, dynamic> && data['message'] != null) {
        throw Exception(data['message'].toString());
      }

      throw Exception('Gagal mengambil slot booking');
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<BookingModel> createBooking({
    required int packageId,
    required String bookingDate,
    required String startTime,
    required int extraDurationUnits,
    required String? locationName,
    required String? notes,
    required String? videoAddonType,
    required List<XFile> moodboards,
  }) async {
    try {
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

      final response = await _dio.post(
        '/bookings',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      debugPrint('CREATE BOOKING RESPONSE: ${response.data}');

      final bookingMap = _extractBookingMap(response.data);
      final booking = BookingModel.fromJson(bookingMap);

      if (booking.id <= 0) {
        throw Exception(
          'Response booking tidak memiliki ID booking. Response server: ${response.data}',
        );
      }

      return booking;
    } on DioException catch (e) {
      final data = e.response?.data;

      debugPrint('CREATE BOOKING ERROR: $data');

      if (data is Map<String, dynamic>) {
        if (data['message'] != null) {
          throw Exception(data['message'].toString());
        }

        if (data['errors'] is Map<String, dynamic>) {
          final errors = data['errors'] as Map<String, dynamic>;

          if (errors.isNotEmpty) {
            final firstKey = errors.keys.first;
            final value = errors[firstKey];

            if (value is List && value.isNotEmpty) {
              throw Exception(value.first.toString());
            }

            throw Exception(value.toString());
          }
        }
      }

      throw Exception('Gagal membuat booking');
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map) {
      final root = Map<String, dynamic>.from(data);

      // Bentuk umum:
      // { "data": [ ... ] }
      if (root['data'] is List) {
        return root['data'] as List<dynamic>;
      }

      // Bentuk alternatif:
      // { "data": { "bookings": [ ... ] } }
      if (root['data'] is Map) {
        final dataMap = Map<String, dynamic>.from(root['data']);

        if (dataMap['bookings'] is List) {
          return dataMap['bookings'] as List<dynamic>;
        }

        if (dataMap['data'] is List) {
          return dataMap['data'] as List<dynamic>;
        }
      }

      // Bentuk alternatif:
      // { "bookings": [ ... ] }
      if (root['bookings'] is List) {
        return root['bookings'] as List<dynamic>;
      }
    }

    return [];
  }

  Map<String, dynamic> _extractBookingMap(dynamic data) {
    if (data is! Map) return {};

    final root = Map<String, dynamic>.from(data);

    // Bentuk 1:
    // { message: "...", data: { booking: {...}, summary: {...} } }
    if (root['data'] is Map) {
      final dataMap = Map<String, dynamic>.from(root['data']);

      if (dataMap['booking'] is Map) {
        return Map<String, dynamic>.from(dataMap['booking']);
      }

      // Bentuk 2:
      // { message: "...", data: { id: 29, ... } }
      if (dataMap['id'] != null) {
        return dataMap;
      }
    }

    // Bentuk 3:
    // { booking: { id: 29, ... } }
    if (root['booking'] is Map) {
      return Map<String, dynamic>.from(root['booking']);
    }

    // Bentuk 4:
    // { id: 29, ... }
    if (root['id'] != null) {
      return root;
    }

    return {};
  }
}
