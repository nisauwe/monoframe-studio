class PrintPriceModel {
  final int id;
  final String sizeLabel;
  final double basePrice;
  final double framePrice;
  final String notes;

  PrintPriceModel({
    required this.id,
    required this.sizeLabel,
    required this.basePrice,
    required this.framePrice,
    required this.notes,
  });

  factory PrintPriceModel.fromJson(Map<String, dynamic> json) {
    return PrintPriceModel(
      id: _toInt(json['id']),
      sizeLabel: json['size_label']?.toString() ?? '',
      basePrice: _toDouble(json['base_price']),
      framePrice: _toDouble(json['frame_price']),
      notes: json['notes']?.toString() ?? '',
    );
  }

  double get totalWithFrame => basePrice + framePrice;

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
