class BookingAddonSettingModel {
  final int id;
  final String addonKey;
  final String addonName;
  final int price;
  final bool isActive;

  BookingAddonSettingModel({
    required this.id,
    required this.addonKey,
    required this.addonName,
    required this.price,
    required this.isActive,
  });

  factory BookingAddonSettingModel.fromJson(Map<String, dynamic> json) {
    return BookingAddonSettingModel(
      id: _toInt(json['id']),
      addonKey: json['addon_key']?.toString() ?? '',
      addonName: json['addon_name']?.toString() ?? '',
      price: _toInt(json['price']),
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