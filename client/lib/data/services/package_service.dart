import 'package:dio/dio.dart';
import '../models/package_model.dart';
import '../models/print_price_model.dart';
import 'dio_client.dart';

class PackageService {
  final Dio _dio = DioClient().dio;

  Future<List<PackageModel>> getPackages() async {
    final response = await _dio.get('/packages');
    final list = _extractList(response.data);

    return list
        .map((e) => PackageModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<PackageModel> getPackageDetail(int packageId) async {
    final response = await _dio.get('/packages/$packageId');
    final map = _extractMap(response.data);
    return PackageModel.fromJson(map);
  }

  Future<List<PrintPriceModel>> getPrintPrices() async {
    final response = await _dio.get('/print-prices');
    final list = _extractList(response.data);

    return list
        .map((e) => PrintPriceModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return data['data'] as List<dynamic>;
    }
    return [];
  }

  Map<String, dynamic> _extractMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data['data']);
      }
      return data;
    }
    return {};
  }
}
