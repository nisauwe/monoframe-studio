import 'package:flutter/material.dart';
import '../models/package_model.dart';
import '../models/print_price_model.dart';
import '../services/package_service.dart';

class PackageProvider extends ChangeNotifier {
  final PackageService _service = PackageService();

  List<PackageModel> _packages = [];
  List<PrintPriceModel> _printPrices = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PackageModel> get packages => _packages;
  List<PrintPriceModel> get printPrices => _printPrices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Map<String, List<PackageModel>> get groupedPackages {
    final Map<String, List<PackageModel>> grouped = {};
    for (final item in _packages) {
      grouped.putIfAbsent(item.categoryName, () => []);
      grouped[item.categoryName]!.add(item);
    }
    return grouped;
  }

  List<PackageModel> get discountedPackages {
    return _packages.where((e) => e.hasDiscount).toList();
  }

  Future<void> fetchAll({bool forceRefresh = false}) async {
    if (_packages.isNotEmpty && _printPrices.isNotEmpty && !forceRefresh)
      return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _packages = await _service.getPackages();
      _printPrices = await _service.getPrintPrices();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    await fetchAll(forceRefresh: true);
  }
}
