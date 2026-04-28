class PublicReviewModel {
  final int id;
  final int rating;
  final String comment;
  final String clientName;
  final String packageName;
  final DateTime? createdAt;

  PublicReviewModel({
    required this.id,
    required this.rating,
    required this.comment,
    required this.clientName,
    required this.packageName,
    required this.createdAt,
  });

  factory PublicReviewModel.fromJson(Map<String, dynamic> json) {
    return PublicReviewModel(
      id: _int(json['id']),
      rating: _int(json['rating']),
      comment: _string(json['comment']),
      clientName: _string(json['client_name'], fallback: 'Klien Monoframe'),
      packageName: _string(json['package_name']),
      createdAt: _date(json['created_at']),
    );
  }
}

String _string(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;

  final text = value.toString().trim();

  if (text.isEmpty || text.toLowerCase() == 'null') {
    return fallback;
  }

  return text;
}

int _int(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value.toString()) ?? fallback;
}

DateTime? _date(dynamic value) {
  if (value == null) return null;

  return DateTime.tryParse(value.toString());
}