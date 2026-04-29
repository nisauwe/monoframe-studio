import 'package:dio/dio.dart';

import '../models/client_notification_model.dart';
import 'dio_client.dart';

class ClientNotificationService {
  final Dio _dio = DioClient().dio;

  Future<ClientNotificationResponse> getNotifications() async {
    try {
      final response = await _dio.get('/notifications');

      return ClientNotificationResponse.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map<String, dynamic> && data['message'] != null) {
        throw Exception(data['message'].toString());
      }

      throw Exception('Gagal mengambil notifikasi klien.');
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
