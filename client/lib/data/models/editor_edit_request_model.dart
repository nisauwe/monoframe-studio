class EditorPackageModel {
  final int id;
  final String name;
  final int photoCount;
  final int durationMinutes;
  final String locationType;
  final String description;

  EditorPackageModel({
    required this.id,
    required this.name,
    required this.photoCount,
    required this.durationMinutes,
    required this.locationType,
    required this.description,
  });

  factory EditorPackageModel.fromJson(Map<String, dynamic> json) {
    return EditorPackageModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? 'Paket Foto',
      photoCount: _toInt(json['photo_count']),
      durationMinutes: _toInt(json['duration_minutes']),
      locationType: json['location_type']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

class EditorClientModel {
  final int id;
  final String name;
  final String email;
  final String phone;

  EditorClientModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory EditorClientModel.fromJson(Map<String, dynamic> json) {
    return EditorClientModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone:
          json['phone']?.toString() ??
          json['whatsapp']?.toString() ??
          json['phone_number']?.toString() ??
          '',
    );
  }
}

class EditorPhotoLinkModel {
  final int id;
  final String driveUrl;
  final String driveLabel;
  final String notes;

  EditorPhotoLinkModel({
    required this.id,
    required this.driveUrl,
    required this.driveLabel,
    required this.notes,
  });

  factory EditorPhotoLinkModel.fromJson(Map<String, dynamic> json) {
    return EditorPhotoLinkModel(
      id: _toInt(json['id']),
      driveUrl: json['drive_url']?.toString() ?? '',
      driveLabel: json['drive_label']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }
}

class EditorBookingModel {
  final int id;
  final String clientName;
  final String clientPhone;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final String locationType;
  final String locationName;
  final String status;
  final String paymentStatus;
  final EditorPackageModel? package;
  final EditorClientModel? clientUser;
  final EditorPhotoLinkModel? photoLink;

  EditorBookingModel({
    required this.id,
    required this.clientName,
    required this.clientPhone,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.locationType,
    required this.locationName,
    required this.status,
    required this.paymentStatus,
    required this.package,
    required this.clientUser,
    required this.photoLink,
  });

  factory EditorBookingModel.fromJson(Map<String, dynamic> json) {
    final packageJson = json['package'] is Map
        ? Map<String, dynamic>.from(json['package'])
        : null;

    final clientJson = json['client_user'] is Map
        ? Map<String, dynamic>.from(json['client_user'])
        : null;

    final photoLinkJson = json['photo_link'] is Map
        ? Map<String, dynamic>.from(json['photo_link'])
        : json['photoLink'] is Map
        ? Map<String, dynamic>.from(json['photoLink'])
        : null;

    return EditorBookingModel(
      id: _toInt(json['id']),
      clientName: json['client_name']?.toString() ?? '',
      clientPhone: json['client_phone']?.toString() ?? '',
      bookingDate: json['booking_date']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      locationType: json['location_type']?.toString() ?? '',
      locationName: json['location_name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? '',
      package: packageJson == null
          ? null
          : EditorPackageModel.fromJson(packageJson),
      clientUser: clientJson == null
          ? null
          : EditorClientModel.fromJson(clientJson),
      photoLink: photoLinkJson == null
          ? null
          : EditorPhotoLinkModel.fromJson(photoLinkJson),
    );
  }

  String get packageName {
    return package?.name ?? 'Paket Foto';
  }

  String get displayClientName {
    if (clientName.isNotEmpty) return clientName;
    return clientUser?.name ?? 'Klien';
  }

  String get displayClientPhone {
    if (clientPhone.isNotEmpty) return clientPhone;
    return clientUser?.phone ?? '-';
  }
}

class EditorEditRequestModel {
  final int id;
  final int scheduleBookingId;
  final int? photoLinkId;
  final int? clientUserId;
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
  final String resultDriveUrl;
  final String resultDriveLabel;
  final int? remainingDays;

  final EditorBookingModel? booking;
  final EditorClientModel? client;
  final EditorPhotoLinkModel? photoLink;

  EditorEditRequestModel({
    required this.id,
    required this.scheduleBookingId,
    required this.photoLinkId,
    required this.clientUserId,
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
    required this.resultDriveUrl,
    required this.resultDriveLabel,
    required this.remainingDays,
    required this.booking,
    required this.client,
    required this.photoLink,
  });

  factory EditorEditRequestModel.fromJson(Map<String, dynamic> json) {
    final bookingJson = json['booking'] is Map
        ? Map<String, dynamic>.from(json['booking'])
        : null;

    final clientJson = json['client'] is Map
        ? Map<String, dynamic>.from(json['client'])
        : null;

    final photoLinkJson = json['photo_link'] is Map
        ? Map<String, dynamic>.from(json['photo_link'])
        : json['photoLink'] is Map
        ? Map<String, dynamic>.from(json['photoLink'])
        : null;

    final rawFiles = json['selected_files'] is List
        ? json['selected_files'] as List
        : <dynamic>[];

    return EditorEditRequestModel(
      id: _toInt(json['id']),
      scheduleBookingId: _toInt(json['schedule_booking_id']),
      photoLinkId: json['photo_link_id'] == null
          ? null
          : _toInt(json['photo_link_id']),
      clientUserId: json['client_user_id'] == null
          ? null
          : _toInt(json['client_user_id']),
      editorUserId: json['editor_user_id'] == null
          ? null
          : _toInt(json['editor_user_id']),
      selectedFiles: rawFiles.map((item) => item.toString()).toList(),
      requestNotes: json['request_notes']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusLabel:
          json['status_label']?.toString() ?? _statusLabel(json['status']),
      assignedAt: json['assigned_at']?.toString() ?? '',
      editDeadlineAt: json['edit_deadline_at']?.toString() ?? '',
      startedAt: json['started_at']?.toString() ?? '',
      completedAt: json['completed_at']?.toString() ?? '',
      editorNotes: json['editor_notes']?.toString() ?? '',
      resultDriveUrl: json['result_drive_url']?.toString() ?? '',
      resultDriveLabel: json['result_drive_label']?.toString() ?? '',
      remainingDays: json['remaining_days'] == null
          ? null
          : _toInt(json['remaining_days']),
      booking: bookingJson == null
          ? null
          : EditorBookingModel.fromJson(bookingJson),
      client: clientJson == null
          ? null
          : EditorClientModel.fromJson(clientJson),
      photoLink: photoLinkJson == null
          ? null
          : EditorPhotoLinkModel.fromJson(photoLinkJson),
    );
  }

  bool get isAssigned => status == 'assigned';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';

  bool get canStart {
    return isAssigned;
  }

  bool get canComplete {
    return isAssigned || isInProgress;
  }

  String get clientName {
    return booking?.displayClientName ?? client?.name ?? 'Klien';
  }

  String get clientPhone {
    return booking?.displayClientPhone ?? client?.phone ?? '-';
  }

  String get packageName {
    return booking?.packageName ?? 'Paket Foto';
  }

  String get originalPhotoDriveUrl {
    return photoLink?.driveUrl ?? booking?.photoLink?.driveUrl ?? '';
  }

  String get originalPhotoDriveLabel {
    return photoLink?.driveLabel ??
        booking?.photoLink?.driveLabel ??
        'Link Foto';
  }

  static String _statusLabel(dynamic value) {
    switch (value?.toString()) {
      case 'assigned':
        return 'Menunggu Dikerjakan';
      case 'in_progress':
        return 'Sedang Diedit';
      case 'completed':
        return 'Edit Selesai';
      case 'submitted':
        return 'Menunggu Assign Editor';
      default:
        return '-';
    }
  }

  String get formattedAssignedAt {
    return _formatDateTimeToIndonesian(assignedAt);
  }

  String get formattedEditDeadline {
    return _formatDateTimeToIndonesian(editDeadlineAt);
  }

  String get formattedStartedAt {
    return _formatDateTimeToIndonesian(startedAt);
  }

  String get formattedCompletedAt {
    return _formatDateTimeToIndonesian(completedAt);
  }
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();

  final text = value.toString().replaceAll('.00', '');
  return int.tryParse(text) ?? 0;
}

String _formatDateTimeToIndonesian(String value) {
  if (value.trim().isEmpty) return '-';

  try {
    final parsed = DateTime.parse(value).toLocal();

    final months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final day = parsed.day.toString().padLeft(2, '0');
    final month = months[parsed.month];
    final year = parsed.year.toString();
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute WIB';
  } catch (_) {
    return value;
  }
}
