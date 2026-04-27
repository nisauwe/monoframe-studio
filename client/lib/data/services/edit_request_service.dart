import 'package:dio/dio.dart';

import '../models/edit_request_model.dart';
import 'dio_client.dart';

class EditRequestService {
  final Dio _dio = DioClient().dio;

  Future<Map<String, dynamic>> getEditRequest({required int bookingId}) async {
    try {
      final response = await _dio.get('/edit-requests/$bookingId');

      if (response.data is Map<String, dynamic>) {
        final root = Map<String, dynamic>.from(response.data);

        if (root['data'] is Map<String, dynamic>) {
          return Map<String, dynamic>.from(root['data']);
        }

        return root;
      }

      return {};
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal mengambil data edit request'));
    }
  }

  Future<EditRequestModel> submitEditRequest({
    required int bookingId,
    required List<String> selectedFiles,
    required String? requestNotes,
  }) async {
    try {
      final response = await _dio.post(
        '/edit-requests',
        data: {
          'booking_id': bookingId,
          'selected_files': selectedFiles,
          if (requestNotes != null && requestNotes.trim().isNotEmpty)
            'request_notes': requestNotes.trim(),
        },
      );

      final root = Map<String, dynamic>.from(response.data);
      final data = root['data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(root['data'])
          : root;

      return EditRequestModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal mengirim daftar foto edit'));
    }
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

    return fallback;
  }
}
