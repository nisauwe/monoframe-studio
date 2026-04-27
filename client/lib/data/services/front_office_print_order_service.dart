import 'package:dio/dio.dart';

import '../models/front_office_print_order_model.dart';
import 'dio_client.dart';

class FrontOfficePrintOrderService {
  final Dio _dio = DioClient().dio;

  Future<List<FrontOfficePrintOrderModel>> getPrintOrders({
    String status = 'all',
  }) async {
    try {
      final response = await _dio.get(
        '/front-office/print-orders',
        queryParameters: {if (status != 'all') 'status': status},
      );

      final list = _extractList(response.data);

      return list.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return FrontOfficePrintOrderModel.fromJson(_normalizeImageUrls(map));
      }).toList();
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal mengambil pesanan cetak'));
    }
  }

  Future<FrontOfficePrintOrderModel> markProcessing({
    required int printOrderId,
  }) async {
    try {
      final response = await _dio.patch(
        '/front-office/print-orders/$printOrderId/process',
      );

      final data = _extractObject(response.data);

      return FrontOfficePrintOrderModel.fromJson(_normalizeImageUrls(data));
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal memproses pesanan cetak'));
    }
  }

  Future<FrontOfficePrintOrderModel> completePrintOrder({
    required int printOrderId,
    required String completionPhotoPath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'completion_photo': await MultipartFile.fromFile(
          completionPhotoPath,
          filename: _fileName(completionPhotoPath),
        ),
      });

      final response = await _dio.post(
        '/front-office/print-orders/$printOrderId/complete',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {'Accept': 'application/json'},
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      final data = _extractObject(response.data);

      return FrontOfficePrintOrderModel.fromJson(_normalizeImageUrls(data));
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal menyelesaikan pesanan cetak'));
    } catch (e) {
      throw Exception('Gagal membaca file gambar: $e');
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
      if (data['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data['data']);
      }

      if (data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }

      return data;
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

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

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Koneksi timeout saat upload gambar.';
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'Tidak bisa terhubung ke server.';
    }

    return fallback;
  }

  String _fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');

    if (parts.isEmpty) return 'completion_photo.jpg';

    final name = parts.last.trim();

    return name.isEmpty ? 'completion_photo.jpg' : name;
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
