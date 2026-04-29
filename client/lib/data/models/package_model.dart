import '../services/dio_client.dart';

class PackageDiscount {
  final int id;
  final String promoName;
  final int discountPercent;
  final bool isActive;

  PackageDiscount({
    required this.id,
    required this.promoName,
    required this.discountPercent,
    required this.isActive,
  });

  factory PackageDiscount.fromJson(Map<String, dynamic> json) {
    return PackageDiscount(
      id: _toInt(json['id']),
      promoName: json['promo_name']?.toString() ?? 'Promo',
      discountPercent: _toInt(json['discount_percent']),
      isActive: _toBool(json['is_active'] ?? true),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    return value.toString().toLowerCase() == 'true';
  }
}

class PackageModel {
  final int id;
  final int categoryId;
  final String categoryName;
  final String name;
  final String description;
  final double price;
  final int photoCount;
  final int durationMinutes;
  final String locationType;
  final int? personCount;
  final bool isActive;
  final List<String> portfolio;
  final List<PackageDiscount> discounts;

  PackageModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.description,
    required this.price,
    required this.photoCount,
    required this.durationMinutes,
    required this.locationType,
    required this.personCount,
    required this.isActive,
    required this.portfolio,
    required this.discounts,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['category'])
        : <String, dynamic>{};

    final discountsRaw = json['discounts'] is List
        ? json['discounts'] as List
        : [];

    final portfolioRaw = json['portfolio'] is List
        ? json['portfolio'] as List
        : json['portfolio_urls'] is List
        ? json['portfolio_urls'] as List
        : [];

    return PackageModel(
      id: _toInt(json['id']),
      categoryId: _toInt(json['category_id'] ?? category['id']),
      categoryName: category['name']?.toString() ?? 'Tanpa Kategori',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: _toDouble(json['price']),
      photoCount: _toInt(json['photo_count']),
      durationMinutes: _toInt(json['duration_minutes']),
      locationType: json['location_type']?.toString() ?? '-',
      personCount: json['person_count'] != null
          ? _toInt(json['person_count'])
          : null,
      isActive: _toBool(json['is_active'] ?? true),
      portfolio: portfolioRaw
          .map((e) => DioClient.normalizePublicUrl(e))
          .where((e) => e.trim().isNotEmpty)
          .toList(),
      discounts: discountsRaw
          .map((e) => PackageDiscount.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  String get coverImage {
    if (portfolio.isEmpty) return '';
    return portfolio.first;
  }

  PackageDiscount? get activeDiscount {
    try {
      return discounts.firstWhere((e) => e.isActive);
    } catch (_) {
      return null;
    }
  }

  bool get hasDiscount => activeDiscount != null;

  double get finalPrice {
    if (!hasDiscount) return price;
    final percent = activeDiscount!.discountPercent;
    return price - (price * percent / 100);
  }

  String get locationTypeLabel {
    if (locationType.toLowerCase() == 'indoor') return 'Indoor';
    if (locationType.toLowerCase() == 'outdoor') return 'Outdoor';
    return locationType;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    return value.toString().toLowerCase() == 'true';
  }
}
