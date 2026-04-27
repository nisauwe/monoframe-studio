import 'package:dio/dio.dart';

import '../models/payment_snap_model.dart';
import 'dio_client.dart';

class PaymentService {
  final Dio _dio = DioClient().dio;

  Future<PaymentSnapModel> createBookingPayment({
    required int bookingId,
    required String mode,
  }) async {
    try {
      final response = await _dio.post(
        '/bookings/$bookingId/payments',
        data: {'mode': mode},
      );

      return PaymentSnapModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map<String, dynamic> && data['message'] != null) {
        throw Exception(data['message'].toString());
      }

      throw Exception('Gagal membuat pembayaran');
    }
  }

  Future<Map<String, dynamic>> checkBookingPaymentStatus({
    required int bookingId,
  }) async {
    try {
      final response = await _dio.post(
        '/bookings/$bookingId/payments/check-status',
      );

      if (response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }

      throw Exception('Response cek pembayaran tidak valid');
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map<String, dynamic> && data['message'] != null) {
        throw Exception(data['message'].toString());
      }

      throw Exception('Gagal cek status pembayaran');
    }
  }
}
