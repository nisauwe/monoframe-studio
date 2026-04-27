class ReviewModel {
  final int id;
  final int bookingId;
  final int clientUserId;
  final int rating;
  final String comment;
  final String createdAt;
  final String updatedAt;

  ReviewModel({
    required this.id,
    required this.bookingId,
    required this.clientUserId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: _toInt(json['id']),
      bookingId: _toInt(json['schedule_booking_id'] ?? json['booking_id']),
      clientUserId: _toInt(json['client_user_id']),
      rating: _toInt(json['rating']),
      comment: _asString(json['comment']),
      createdAt: _asString(json['created_at']),
      updatedAt: _asString(json['updated_at']),
    );
  }
}

class ReviewStatusModel {
  final int bookingId;
  final bool canReview;
  final ReviewModel? review;

  ReviewStatusModel({
    required this.bookingId,
    required this.canReview,
    required this.review,
  });

  factory ReviewStatusModel.fromJson(Map<String, dynamic> json) {
    final reviewJson = json['review'];

    return ReviewStatusModel(
      bookingId: _toInt(json['booking_id']),
      canReview: _toBool(json['can_review']),
      review: reviewJson is Map
          ? ReviewModel.fromJson(Map<String, dynamic>.from(reviewJson))
          : null,
    );
  }
}

String _asString(dynamic value) {
  if (value == null) return '';

  final text = value.toString().trim();

  if (text.isEmpty || text.toLowerCase() == 'null') {
    return '';
  }

  return text;
}

int _toInt(dynamic value) {
  if (value == null) return 0;

  if (value is int) return value;

  if (value is double) return value.toInt();

  final text = value.toString().trim();

  if (text.isEmpty || text.toLowerCase() == 'null') return 0;

  final asInt = int.tryParse(text);
  if (asInt != null) return asInt;

  final asDouble = double.tryParse(text);
  if (asDouble != null) return asDouble.toInt();

  return 0;
}

bool _toBool(dynamic value) {
  if (value == null) return false;

  if (value is bool) return value;

  if (value is int) return value == 1;

  final text = value.toString().toLowerCase().trim();

  return text == 'true' || text == '1' || text == 'yes' || text == 'aktif';
}
