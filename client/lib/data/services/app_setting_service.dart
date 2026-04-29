import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/app_setting_model.dart';
import '../models/public_review_model.dart';
import 'dio_client.dart';

class AppSettingService {
  final Dio _dio = DioClient().dio;

  Future<AppSettingModel> getAppSettings() async {
    try {
      final response = await _dio.get('/app-settings');
      final map = _extractMap(response.data);
      return AppSettingModel.fromJson(map);
    } on DioException catch (e) {
      debugPrint('GET APP SETTINGS ERROR: ${e.response?.data}');
      return AppSettingModel.fallback();
    } catch (e) {
      debugPrint('GET APP SETTINGS ERROR: $e');
      return AppSettingModel.fallback();
    }
  }

  Future<List<PublicReviewModel>> getPublicReviews() async {
    try {
      final response = await _dio.get('/public-reviews');
      final list = _extractList(response.data);
      return list
          .map(
            (item) =>
                PublicReviewModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on DioException catch (e) {
      debugPrint('GET PUBLIC REVIEWS ERROR: ${e.response?.data}');
      return <PublicReviewModel>[];
    } catch (e) {
      debugPrint('GET PUBLIC REVIEWS ERROR: $e');
      return <PublicReviewModel>[];
    }
  }

  Map<String, dynamic> _extractMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data['data']);
      }
      return data;
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (map['data'] is Map) {
        return Map<String, dynamic>.from(map['data']);
      }
      return map;
    }

    return <String, dynamic>{};
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) {
      return data['data'] as List<dynamic>;
    }
    return <dynamic>[];
  }
}
