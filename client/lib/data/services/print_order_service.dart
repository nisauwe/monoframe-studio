import 'package:dio/dio.dart';

import '../models/payment_snap_model.dart';
import '../models/print_order_model.dart';
import 'dio_client.dart';

class PrintOrderService {
  final Dio _dio = DioClient().dio;

  Future<List<PrintPriceModel>> getPrintPrices() async {
    try {
      final response = await _dio.get('/print-prices');
      final list = _extractList(response.data);

      return list.map((item) {
        return PrintPriceModel.fromJson(Map<String, dynamic>.from(item as Map));
      }).toList();
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal mengambil harga cetak'));
    }
  }

  Future<PrintOrderModel?> getPrintOrder({required int bookingId}) async {
    try {
      final response = await _dio.get('/bookings/$bookingId/print-order');

      final root = Map<String, dynamic>.from(response.data as Map);
      final data = _extractObject(root['data']);

      if (data['print_order'] == null) {
        return null;
      }

      final orderJson = _extractObject(data['print_order']);

      return PrintOrderModel.fromJson(_normalizeImageUrls(orderJson));
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal mengambil pesanan cetak'));
    }
  }

  Future<PrintOrderModel> createPrintOrder({
    required int bookingId,
    required List<PrintOrderItemPayload> items,
    required String deliveryMethod,
    required String? recipientName,
    required String? recipientPhone,
    required String? deliveryAddress,
    required String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/print-orders',
        data: {
          'booking_id': bookingId,
          'items': items.map((item) => item.toJson()).toList(),
          'delivery_method': deliveryMethod,
          if (recipientName != null && recipientName.trim().isNotEmpty)
            'recipient_name': recipientName.trim(),
          if (recipientPhone != null && recipientPhone.trim().isNotEmpty)
            'recipient_phone': recipientPhone.trim(),
          if (deliveryAddress != null && deliveryAddress.trim().isNotEmpty)
            'delivery_address': deliveryAddress.trim(),
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        },
      );

      final root = Map<String, dynamic>.from(response.data as Map);
      final data = _extractObject(root['data']);

      return PrintOrderModel.fromJson(_normalizeImageUrls(data));
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal membuat pesanan cetak'));
    }
  }

  Future<void> skipPrint({required int bookingId}) async {
    try {
      await _dio.post('/bookings/$bookingId/print-order/skip');
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal melewati tahap cetak'));
    }
  }

  Future<PaymentSnapModel> createPrintPayment({
    required int printOrderId,
  }) async {
    try {
      final response = await _dio.post('/print-orders/$printOrderId/payments');

      final snap = PaymentSnapModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );

      if (!snap.hasValidRedirectUrl) {
        throw Exception(
          'URL pembayaran Midtrans kosong. Response server: ${response.data}',
        );
      }

      return snap;
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal membuat pembayaran cetak'));
    }
  }

  Future<PrintOrderModel> checkPrintPaymentStatus({
    required int printOrderId,
  }) async {
    try {
      final response = await _dio.post(
        '/print-orders/$printOrderId/payments/check-status',
      );

      final root = Map<String, dynamic>.from(response.data as Map);
      final data = _extractObject(root['data']);

      final orderJson = data['print_order'] == null
          ? data
          : _extractObject(data['print_order']);

      return PrintOrderModel.fromJson(_normalizeImageUrls(orderJson));
    } on DioException catch (e) {
      throw Exception(
        _messageFromDio(e, 'Gagal mengecek status pembayaran cetak'),
      );
    }
  }

  Map<String, dynamic> _normalizeImageUrls(Map<String, dynamic> map) {
    final result = Map<String, dynamic>.from(map);

    final completionPath = _asString(result['completion_photo_path']);
    final completionUrl = _asString(result['completion_photo_url']);

    final deliveryPath = _asString(result['delivery_proof_path']);
    final deliveryUrl = _asString(result['delivery_proof_url']);

    if (completionPath.isNotEmpty) {
      result['completion_photo_url'] = DioClient.normalizePublicUrl(
        completionPath,
      );
    } else {
      result['completion_photo_url'] = DioClient.normalizePublicUrl(
        completionUrl,
      );
    }

    if (deliveryPath.isNotEmpty) {
      result['delivery_proof_url'] = DioClient.normalizePublicUrl(deliveryPath);
    } else {
      result['delivery_proof_url'] = DioClient.normalizePublicUrl(deliveryUrl);
    }

    return result;
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;

    if (data is Map && data['data'] is List) {
      return data['data'] as List<dynamic>;
    }

    return [];
  }

  Map<String, dynamic> _extractObject(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
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

  String _asString(dynamic value) {
    if (value == null) return '';

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return '';
    }

    return text;
  }
}
