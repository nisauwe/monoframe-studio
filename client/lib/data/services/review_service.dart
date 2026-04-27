import 'package:dio/dio.dart';

import '../models/review_model.dart';
import 'dio_client.dart';

class ReviewService {
  final Dio _dio = DioClient().dio;

  Future<ReviewStatusModel> getReview({required int bookingId}) async {
    try {
      final response = await _dio.get('/reviews/$bookingId');

      final data = _extractData(response.data);

      return ReviewStatusModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal mengambil data review'));
    }
  }

  Future<ReviewModel> submitReview({
    required int bookingId,
    required int rating,
    required String comment,
  }) async {
    try {
      final response = await _dio.post(
        '/reviews',
        data: {
          'booking_id': bookingId,
          'rating': rating,
          'comment': comment.trim(),
        },
      );

      final data = _extractData(response.data);

      return ReviewModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal mengirim review'));
    }
  }

  Map<String, dynamic> _extractData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(responseData['data']);
      }

      if (responseData['data'] is Map) {
        return Map<String, dynamic>.from(responseData['data'] as Map);
      }

      return responseData;
    }

    if (responseData is Map) {
      final map = Map<String, dynamic>.from(responseData);

      if (map['data'] is Map) {
        return Map<String, dynamic>.from(map['data'] as Map);
      }

      return map;
    }

    return <String, dynamic>{};
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
          final first = errors.values.first;

          if (first is List && first.isNotEmpty) {
            return first.first.toString();
          }

          return first.toString();
        }
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    return fallback;
  }
}
