class EditRequestModel {
  final int id;
  final int bookingId;
  final int? editorUserId;
  final List<String> selectedFiles;
  final String requestNotes;
  final String status;
  final String statusLabel;
  final String assignedAt;
  final String editDeadlineAt;
  final String startedAt;
  final String completedAt;
  final String editorNotes;
  final int? remainingDays;
  final String editorName;
  final String editorPhone;

  EditRequestModel({
    required this.id,
    required this.bookingId,
    required this.editorUserId,
    required this.selectedFiles,
    required this.requestNotes,
    required this.status,
    required this.statusLabel,
    required this.assignedAt,
    required this.editDeadlineAt,
    required this.startedAt,
    required this.completedAt,
    required this.editorNotes,
    required this.remainingDays,
    required this.editorName,
    required this.editorPhone,
  });

  factory EditRequestModel.fromJson(Map<String, dynamic> json) {
    final editorJson = json['editor'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['editor'])
        : <String, dynamic>{};

    final rawFiles = json['selected_files'] is List
        ? json['selected_files'] as List
        : <dynamic>[];

    return EditRequestModel(
      id: _toInt(json['id']),
      bookingId: _toInt(json['schedule_booking_id'] ?? json['booking_id']),
      editorUserId: json['editor_user_id'] == null
          ? null
          : _toInt(json['editor_user_id']),
      selectedFiles: rawFiles.map((e) => e.toString()).toList(),
      requestNotes: json['request_notes']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusLabel:
          json['status_label']?.toString() ?? _statusLabel(json['status']),
      assignedAt: json['assigned_at']?.toString() ?? '',
      editDeadlineAt: json['edit_deadline_at']?.toString() ?? '',
      startedAt: json['started_at']?.toString() ?? '',
      completedAt: json['completed_at']?.toString() ?? '',
      editorNotes: json['editor_notes']?.toString() ?? '',
      remainingDays: json['remaining_days'] == null
          ? null
          : _toInt(json['remaining_days']),
      editorName: editorJson['name']?.toString() ?? '',
      editorPhone: editorJson['phone']?.toString() ?? '',
    );
  }

  bool get isSubmitted => status == 'submitted';
  bool get isAssigned => status == 'assigned';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';

  static String _statusLabel(dynamic value) {
    switch (value?.toString()) {
      case 'submitted':
        return 'Menunggu Assign Editor';
      case 'assigned':
        return 'Sudah Dikirim ke Editor';
      case 'in_progress':
        return 'Sedang Diedit';
      case 'completed':
        return 'Edit Selesai';
      default:
        return '-';
    }
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
