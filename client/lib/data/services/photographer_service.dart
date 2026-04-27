import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/photographer_models.dart';
import 'dio_client.dart';

class PhotographerService {
  final Dio _dio = DioClient().dio;

  Future<List<PhotographerBookingModel>> getAssignedBookings() async {
    try {
      final response = await _dio.get('/photographer/bookings');

      debugPrint('PHOTOGRAPHER BOOKINGS RESPONSE: ${response.data}');

      final list = _extractList(response.data);

      return list.map((item) {
        return PhotographerBookingModel.fromJson(
          Map<String, dynamic>.from(item),
        );
      }).toList();
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal mengambil jadwal fotografer'));
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<PhotographerBookingModel> getBookingDetail({
    required int bookingId,
  }) async {
    try {
      final response = await _dio.get('/photographer/bookings/$bookingId');

      debugPrint('PHOTOGRAPHER BOOKING DETAIL RESPONSE: ${response.data}');

      final map = _extractDataMap(response.data);

      return PhotographerBookingModel.fromJson(map);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal mengambil detail booking'));
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<PhotographerPhotoLinkModel> storePhotoLink({
    required int bookingId,
    required String driveUrl,
    required String? driveLabel,
    required String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/photographer/photo-links',
        data: {
          'booking_id': bookingId,
          'drive_url': driveUrl,
          if (driveLabel != null && driveLabel.trim().isNotEmpty)
            'drive_label': driveLabel.trim(),
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        },
      );

      debugPrint('STORE PHOTO LINK RESPONSE: ${response.data}');

      final map = _extractDataMap(response.data);

      return PhotographerPhotoLinkModel.fromJson(map);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal menyimpan link Google Drive'));
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map && data['data'] is List) {
      return data['data'] as List<dynamic>;
    }

    if (data is Map && data['data'] is Map) {
      final dataMap = Map<String, dynamic>.from(data['data']);

      if (dataMap['data'] is List) {
        return dataMap['data'] as List<dynamic>;
      }
    }

    return [];
  }

  Map<String, dynamic> _extractDataMap(dynamic data) {
    if (data is! Map) {
      return <String, dynamic>{};
    }

    final root = Map<String, dynamic>.from(data);

    if (root['data'] is Map) {
      return Map<String, dynamic>.from(root['data']);
    }

    return root;
  }

  String _messageFromDio(DioException e, String fallback) {
    final data = e.response?.data;

    debugPrint('PHOTOGRAPHER API ERROR: $data');

    if (data is Map<String, dynamic>) {
      if (data['message'] != null) {
        return data['message'].toString();
      }

      if (data['errors'] is Map<String, dynamic>) {
        final errors = data['errors'] as Map<String, dynamic>;

        if (errors.isNotEmpty) {
          final firstValue = errors.values.first;

          if (firstValue is List && firstValue.isNotEmpty) {
            return firstValue.first.toString();
          }

          return firstValue.toString();
        }
      }
    }

    return fallback;
  }
}
