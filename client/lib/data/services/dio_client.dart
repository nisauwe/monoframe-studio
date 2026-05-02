import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'auth_storage_service.dart';

class DioClient {
  DioClient._internal();

  static final DioClient _instance = DioClient._internal();

  factory DioClient() {
    return _instance;
  }

  // URL publik dari Cloudflare Tunnel kamu.
  // Untuk API pakai /api.
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://soma-ferry-kept-acdbentity.trycloudflare.com/api',
  );

  // Untuk file publik/storage JANGAN pakai /api.
  static const String _publicBaseUrl = String.fromEnvironment(
    'PUBLIC_BASE_URL',
    defaultValue: 'https://soma-ferry-kept-acdbentity.trycloudflare.com',
  );

  // Daftar host lokal/lama yang mungkin masih dikirim dari backend/database.
  // Kalau backend mengirim URL lama seperti http://10.157.71.14:8000/storage/xxx,
  // function normalizePublicUrl akan otomatis mengubahnya ke URL Cloudflare.
  static const List<String> _localOrOldHosts = [
    'localhost',
    '127.0.0.1',
    '10.157.71.14',
  ];

  static String get baseApiUrl {
    return _apiBaseUrl;
  }

  static String get publicBaseUrl {
    return _publicBaseUrl;
  }

  late final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: baseApiUrl,
            connectTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
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

      final isLocalOrOldServer = _localOrOldHosts.contains(uri.host);

      // Kalau backend/database masih mengirim URL lokal/lama,
      // paksa ubah ke URL Cloudflare.
      if (isLocalOrOldServer && path.startsWith('/storage/')) {
        return '$publicBaseUrl$path';
      }

      // Kalau sudah URL online dan path-nya storage, biarkan domain aslinya.
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

    if (cleaned.startsWith('api/storage/')) {
      cleaned = cleaned.replaceFirst('api/storage/', 'storage/');
    }

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
