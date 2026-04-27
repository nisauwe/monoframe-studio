import 'package:flutter/material.dart';

import '../models/edit_request_model.dart';
import '../services/edit_request_service.dart';

class EditRequestProvider extends ChangeNotifier {
  final EditRequestService _service = EditRequestService();

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  int _maxPhotoCount = 0;
  bool _hasPhotoLink = false;
  bool _canSubmitEditRequest = false;
  EditRequestModel? _editRequest;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  int get maxPhotoCount => _maxPhotoCount;
  bool get hasPhotoLink => _hasPhotoLink;
  bool get canSubmitEditRequest => _canSubmitEditRequest;
  EditRequestModel? get editRequest => _editRequest;

  Future<void> fetchEditRequest({required int bookingId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _service.getEditRequest(bookingId: bookingId);

      _maxPhotoCount = _toInt(data['max_photo_count']);
      _hasPhotoLink = _toBool(data['has_photo_link']);
      _canSubmitEditRequest = _toBool(data['can_submit_edit_request']);

      if (data['edit_request'] is Map<String, dynamic>) {
        _editRequest = EditRequestModel.fromJson(
          Map<String, dynamic>.from(data['edit_request']),
        );
      } else {
        _editRequest = null;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitEditRequest({
    required int bookingId,
    required List<String> selectedFiles,
    required String? requestNotes,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _editRequest = await _service.submitEditRequest(
        bookingId: bookingId,
        selectedFiles: selectedFiles,
        requestNotes: requestNotes,
      );

      await fetchEditRequest(bookingId: bookingId);

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    final text = value.toString().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }
}
