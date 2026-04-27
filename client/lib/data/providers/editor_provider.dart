import 'package:flutter/material.dart';

import '../models/editor_edit_request_model.dart';
import '../services/editor_service.dart';

class EditorProvider extends ChangeNotifier {
  final EditorService _service = EditorService();

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<EditorEditRequestModel> _editRequests = [];
  EditorEditRequestModel? _selectedEditRequest;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  List<EditorEditRequestModel> get editRequests => _editRequests;
  EditorEditRequestModel? get selectedEditRequest => _selectedEditRequest;

  List<EditorEditRequestModel> get waitingTasks {
    return _editRequests.where((item) => item.isAssigned).toList();
  }

  List<EditorEditRequestModel> get inProgressTasks {
    return _editRequests.where((item) => item.isInProgress).toList();
  }

  List<EditorEditRequestModel> get completedTasks {
    return _editRequests.where((item) => item.isCompleted).toList();
  }

  List<EditorEditRequestModel> get activeTasks {
    return _editRequests.where((item) {
      return item.isAssigned || item.isInProgress;
    }).toList();
  }

  Future<void> fetchEditRequests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _editRequests = await _service.getEditRequests();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchEditRequestDetail({required int editRequestId}) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedEditRequest = null;
    notifyListeners();

    try {
      _selectedEditRequest = await _service.getEditRequestDetail(
        editRequestId: editRequestId,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startEdit({required int editRequestId}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedEditRequest = await _service.startEdit(
        editRequestId: editRequestId,
      );

      await fetchEditRequests();
      await fetchEditRequestDetail(editRequestId: editRequestId);

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> completeEdit({
    required int editRequestId,
    required String resultDriveUrl,
    required String? resultDriveLabel,
    required String? editorNotes,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedEditRequest = await _service.completeEdit(
        editRequestId: editRequestId,
        resultDriveUrl: resultDriveUrl,
        resultDriveLabel: resultDriveLabel,
        editorNotes: editorNotes,
      );

      await fetchEditRequests();
      await fetchEditRequestDetail(editRequestId: editRequestId);

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearSelected() {
    _selectedEditRequest = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
