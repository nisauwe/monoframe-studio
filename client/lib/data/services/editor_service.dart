import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/editor_edit_request_model.dart';
import 'dio_client.dart';

class EditorService {
  final Dio _dio = DioClient().dio;

  Future<List<EditorEditRequestModel>> getEditRequests() async {
    try {
      final response = await _dio.get('/editor/edit-requests');

      debugPrint('EDITOR EDIT REQUESTS RESPONSE: ${response.data}');

      final list = _extractList(response.data);

      return list.map((item) {
        return EditorEditRequestModel.fromJson(Map<String, dynamic>.from(item));
      }).toList();
    } on DioException catch (e) {
      throw Exception(
        _messageFromDio(e, 'Gagal mengambil daftar pekerjaan edit'),
      );
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<EditorEditRequestModel> getEditRequestDetail({
    required int editRequestId,
  }) async {
    try {
      final response = await _dio.get('/editor/edit-requests/$editRequestId');

      debugPrint('EDITOR DETAIL RESPONSE: ${response.data}');

      final map = _extractDataMap(response.data);

      return EditorEditRequestModel.fromJson(map);
    } on DioException catch (e) {
      throw Exception(
        _messageFromDio(e, 'Gagal mengambil detail pekerjaan edit'),
      );
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<EditorEditRequestModel> startEdit({required int editRequestId}) async {
    try {
      final response = await _dio.patch(
        '/editor/edit-requests/$editRequestId/start',
      );

      debugPrint('EDITOR START RESPONSE: ${response.data}');

      final map = _extractDataMap(response.data);

      return EditorEditRequestModel.fromJson(map);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal memulai pekerjaan edit'));
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<EditorEditRequestModel> completeEdit({
    required int editRequestId,
    required String resultDriveUrl,
    required String? resultDriveLabel,
    required String? editorNotes,
  }) async {
    try {
      final response = await _dio.patch(
        '/editor/edit-requests/$editRequestId/complete',
        data: {
          'result_drive_url': resultDriveUrl,
          if (resultDriveLabel != null && resultDriveLabel.trim().isNotEmpty)
            'result_drive_label': resultDriveLabel.trim(),
          if (editorNotes != null && editorNotes.trim().isNotEmpty)
            'editor_notes': editorNotes.trim(),
        },
      );

      debugPrint('EDITOR COMPLETE RESPONSE: ${response.data}');

      final map = _extractDataMap(response.data);

      return EditorEditRequestModel.fromJson(map);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Gagal menyelesaikan pekerjaan edit'));
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

    debugPrint('EDITOR API ERROR: $data');

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
