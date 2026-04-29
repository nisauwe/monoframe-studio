import '../services/dio_client.dart';

class PackageDiscount {
  final int id;
  final String promoName;
  final int discountPercent;
  final bool isActive;
  final bool isCurrentlyActive;
  final DateTime? discountStartAt;
  final DateTime? discountEndAt;

  PackageDiscount({
    required this.id,
    required this.promoName,
    required this.discountPercent,
    required this.isActive,
    required this.isCurrentlyActive,
    required this.discountStartAt,
    required this.discountEndAt,
  });

  factory PackageDiscount.fromJson(Map<String, dynamic> json) {
    final isActive = _toBool(json['is_active'] ?? true);

    return PackageDiscount(
      id: _toInt(json['id']),
      promoName: json['promo_name']?.toString() ?? 'Promo',
      discountPercent: _toInt(json['discount_percent']),
      isActive: isActive,
      isCurrentlyActive: _toBool(json['is_currently_active'] ?? isActive),
      discountStartAt: _toDate(json['discount_start_at']),
      discountEndAt: _toDate(json['discount_end_at']),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is num) return value != 0;

    final text = value.toString().toLowerCase().trim();
    return text == 'true' || text == '1' || text == 'yes' || text == 'on';
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }

    return DateTime.tryParse(text);
  }
}

class PackageModel {
  final int id;
  final int categoryId;
  final String categoryName;
  final String name;
  final String description;
  final double price;
  final double? serverDiscountedPrice;
  final int photoCount;
  final int durationMinutes;
  final String locationType;
  final int? personCount;
  final bool isActive;
  final List<String> portfolio;
  final List<PackageDiscount> discounts;
  final PackageDiscount? currentDiscount;

  PackageModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.description,
    required this.price,
    required this.serverDiscountedPrice,
    required this.photoCount,
    required this.durationMinutes,
    required this.locationType,
    required this.personCount,
    required this.isActive,
    required this.portfolio,
    required this.discounts,
    required this.currentDiscount,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['category'])
        : <String, dynamic>{};

    final discountsRaw = json['discounts'] is List
        ? json['discounts'] as List
        : [];

    /*
    |--------------------------------------------------------------------------
    | PENTING
    |--------------------------------------------------------------------------
    | Utamakan portfolio_urls dari server.
    | Jangan ubah full URL yang sudah dikirim server.
    */
    final portfolioRaw = json['portfolio_urls'] is List
        ? json['portfolio_urls'] as List
        : json['portfolio'] is List
        ? json['portfolio'] as List
        : [];

    final currentDiscountMap = json['current_discount'] is Map
        ? Map<String, dynamic>.from(json['current_discount'])
        : null;

    return PackageModel(
      id: _toInt(json['id']),
      categoryId: _toInt(json['category_id'] ?? category['id']),
      categoryName:
          category['name']?.toString() ??
          json['category_name']?.toString() ??
          'Tanpa Kategori',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: _toDouble(json['price']),
      serverDiscountedPrice: json['discounted_price'] == null
          ? null
          : _toDouble(json['discounted_price']),
      photoCount: _toInt(json['photo_count']),
      durationMinutes: _toInt(json['duration_minutes']),
      locationType: json['location_type']?.toString() ?? '-',
      personCount: json['person_count'] != null
          ? _toInt(json['person_count'])
          : null,
      isActive: _toBool(json['is_active'] ?? true),
      portfolio: portfolioRaw
          .map((e) => _normalizePortfolioUrl(e))
          .where((e) => e.trim().isNotEmpty)
          .toList(),
      discounts: discountsRaw
          .map((e) => PackageDiscount.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      currentDiscount: currentDiscountMap == null
          ? null
          : PackageDiscount.fromJson(currentDiscountMap),
    );
  }

  static String _normalizePortfolioUrl(dynamic value) {
    final raw = value == null ? '' : value.toString().trim();

    if (raw.isEmpty || raw.toLowerCase() == 'null') {
      return '';
    }

    final cleaned = raw.replaceAll('\\', '/');

    /*
    |--------------------------------------------------------------------------
    | Jika server sudah kirim URL lengkap, jangan diubah lagi.
    |--------------------------------------------------------------------------
    */
    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      return cleaned;
    }

    return DioClient.normalizePublicUrl(cleaned);
  }

  String get coverImage {
    if (portfolio.isEmpty) return '';
    return portfolio.first;
  }

  PackageDiscount? get activeDiscount {
    if (currentDiscount != null && currentDiscount!.isCurrentlyActive) {
      return currentDiscount;
    }

    try {
      return discounts.firstWhere((e) => e.isCurrentlyActive);
    } catch (_) {
      return null;
    }
  }

  bool get hasDiscount => activeDiscount != null;

  double get finalPrice {
    if (serverDiscountedPrice != null && hasDiscount) {
      return serverDiscountedPrice!;
    }

    if (!hasDiscount) {
      return price;
    }

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
    if (value is num) return value != 0;

    final text = value.toString().toLowerCase().trim();
    return text == 'true' || text == '1' || text == 'yes' || text == 'on';
  }
}
