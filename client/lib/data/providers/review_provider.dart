import 'package:flutter/material.dart';

import '../models/review_model.dart';
import '../services/review_service.dart';

class ReviewProvider extends ChangeNotifier {
  final ReviewService _service = ReviewService();

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool _canReview = false;
  ReviewModel? _review;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get canReview => _canReview;
  ReviewModel? get review => _review;

  Future<void> fetchReview({required int bookingId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final status = await _service.getReview(bookingId: bookingId);

      _canReview = status.canReview;
      _review = status.review;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitReview({
    required int bookingId,
    required int rating,
    required String comment,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _review = await _service.submitReview(
        bookingId: bookingId,
        rating: rating,
        comment: comment,
      );

      _canReview = false;

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void setFromTracking({required bool canReview, ReviewModel? review}) {
    _canReview = canReview;
    _review = review;
    _errorMessage = null;
    notifyListeners();
  }
}
