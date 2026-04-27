import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/call_center_contact_model.dart';
import 'dio_client.dart';

class CallCenterService {
  final Dio _dio = DioClient().dio;

  Future<List<CallCenterContactModel>> getContacts() async {
    try {
      final response = await _dio.get('/call-center-contacts');

      debugPrint('GET CALL CENTER CONTACTS RESPONSE: ${response.data}');

      final list = _extractList(response.data);

      return list.map((item) {
        return CallCenterContactModel.fromJson(Map<String, dynamic>.from(item));
      }).toList();
    } on DioException catch (e) {
      final data = e.response?.data;

      debugPrint('GET CALL CENTER CONTACTS ERROR: $data');

      if (data is Map<String, dynamic> && data['message'] != null) {
        throw Exception(data['message'].toString());
      }

      throw Exception('Gagal mengambil kontak call center');
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;

    if (data is Map && data['data'] is List) {
      return data['data'] as List<dynamic>;
    }

    return [];
  }
}
