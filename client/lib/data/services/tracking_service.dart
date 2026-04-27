import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/tracking_model.dart';
import 'dio_client.dart';

class TrackingService {
  final Dio _dio = DioClient().dio;

  Future<TrackingDetailModel> getTrackingDetail({
    required int bookingId,
  }) async {
    try {
      final response = await _dio.get('/tracking/$bookingId');

      debugPrint('GET TRACKING RESPONSE: ${response.data}');

      return TrackingDetailModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      final data = e.response?.data;

      debugPrint('GET TRACKING ERROR: $data');

      if (data is Map<String, dynamic> && data['message'] != null) {
        throw Exception(data['message'].toString());
      }

      throw Exception('Gagal mengambil tracking booking');
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
