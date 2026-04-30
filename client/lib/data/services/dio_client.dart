import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'auth_storage_service.dart';

class DioClient {
  DioClient._internal();

  static final DioClient _instance = DioClient._internal();

  factory DioClient() {
    return _instance;
  }

  // GANTI IP INI SESUAI IP LAPTOP/SERVER LARAVEL KAMU
  static const String _serverHost = '10.157.71.14';
  static const String _serverPort = '8000';

  static String get baseApiUrl {
    return 'http://$_serverHost:$_serverPort/api';
  }

  static String get publicBaseUrl {
    return 'http://$_serverHost:$_serverPort';
  }

  late final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: baseApiUrl,
            connectTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
            headers: {'Accept': 'application/json'},
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final token = await AuthStorageService.getToken();

              if (token != null && token.trim().isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }

              return handler.next(options);
            },
            onError: (error, handler) {
              return handler.next(error);
            },
          ),
        );

  static String normalizePublicUrl(dynamic value) {
    final raw = value == null ? '' : value.toString().trim();

    if (raw.isEmpty || raw.toLowerCase() == 'null') {
      return '';
    }

    String cleaned = raw
        .replaceAll('\\', '/')
        .replaceAll('?#/', '/')
        .replaceAll('#/', '/')
        .replaceAll('?/storage/', '/storage/')
        .replaceAll('?storage/', '/storage/');

    if (cleaned.contains('/api/storage/')) {
      cleaned = cleaned.replaceAll('/api/storage/', '/storage/');
    }

    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      final uri = Uri.tryParse(cleaned);

      if (uri == null) {
        return cleaned;
      }

      String path = uri.path;

      if (path.isEmpty && uri.fragment.startsWith('/storage/')) {
        path = uri.fragment;
      }

      if (path.isEmpty && uri.query.startsWith('/storage/')) {
        path = uri.query;
      }

      if (path.startsWith('/api/storage/')) {
        path = path.replaceFirst('/api/storage/', '/storage/');
      }

      final isLocalhost = uri.host == 'localhost' || uri.host == '127.0.0.1';
      final isSameServer = uri.host == _serverHost;

      if ((isLocalhost || isSameServer) && path.startsWith('/storage/')) {
        return '$publicBaseUrl$path';
      }

      if (path.startsWith('/storage/')) {
        final port = uri.hasPort ? ':${uri.port}' : '';
        return '${uri.scheme}://${uri.host}$port$path';
      }

      return cleaned;
    }

    if (cleaned.startsWith('/storage/')) {
      return '$publicBaseUrl$cleaned';
    }

    if (cleaned.startsWith('storage/')) {
      return '$publicBaseUrl/$cleaned';
    }

    if (cleaned.startsWith('/')) {
      return '$publicBaseUrl$cleaned';
    }

    return '$publicBaseUrl/storage/$cleaned';
  }

  static String normalizeStoragePath(dynamic value) {
    final raw = value == null ? '' : value.toString().trim();

    if (raw.isEmpty || raw.toLowerCase() == 'null') {
      return '';
    }

    String cleaned = raw
        .replaceAll('\\', '/')
        .replaceAll('?#/', '/')
        .replaceAll('#/', '/');

    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      final uri = Uri.tryParse(cleaned);

      if (uri == null) return cleaned;

      cleaned = uri.path;
    }

    cleaned = cleaned.replaceFirst(RegExp(r'^/+'), '');

    if (cleaned.startsWith('storage/')) {
      return cleaned;
    }

    return 'storage/$cleaned';
  }

  static void debugPrintUrls() {
    if (!kReleaseMode) {
      debugPrint('Dio baseApiUrl: $baseApiUrl');
      debugPrint('Dio publicBaseUrl: $publicBaseUrl');
    }
  }
}
