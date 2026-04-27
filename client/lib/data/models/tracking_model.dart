import 'review_model.dart';

class TrackingDetailModel {
  final TrackingBookingModel booking;
  final List<TrackingTimelineModel> timeline;

  TrackingDetailModel({required this.booking, required this.timeline});

  factory TrackingDetailModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    final bookingJson = data['booking'] is Map
        ? Map<String, dynamic>.from(data['booking'] as Map)
        : <String, dynamic>{};

    final timelineRaw = data['timeline'] is List
        ? data['timeline'] as List
        : <dynamic>[];

    return TrackingDetailModel(
      booking: TrackingBookingModel.fromJson(bookingJson),
      timeline: timelineRaw
          .where((item) => item is Map)
          .map(
            (item) => TrackingTimelineModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class TrackingBookingModel {
  final int id;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final String status;
  final String paymentStatus;

  final String clientName;
  final String clientPhone;
  final String locationType;
  final String locationName;
  final String? notes;

  final String packageName;
  final int totalBookingAmount;
  final int minimumDpAmount;
  final int paidBookingAmount;
  final int remainingBookingAmount;

  final String? paymentWarning;

  final bool canPayDp;
  final bool canPayFull;
  final bool canPayRemaining;

  final bool hasPhotographerAssigned;
  final bool isWaitingPhotographerAssignment;

  final String? photographerName;
  final String? photographerEmail;
  final String? photographerPhone;

  final bool hasPhotoLink;
  final bool canOpenPhotoLink;
  final String? photoDriveUrl;
  final String? photoDriveLabel;

  final int maxPhotoEdit;
  final bool canSubmitEditRequest;
  final TrackingEditRequestModel? editRequest;

  final bool canPrint;
  final bool canReview;
  final TrackingPrintOrderModel? printOrder;

  final ReviewModel? review;

  TrackingBookingModel({
    required this.id,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.paymentStatus,
    required this.clientName,
    required this.clientPhone,
    required this.locationType,
    required this.locationName,
    required this.notes,
    required this.packageName,
    required this.totalBookingAmount,
    required this.minimumDpAmount,
    required this.paidBookingAmount,
    required this.remainingBookingAmount,
    required this.paymentWarning,
    required this.canPayDp,
    required this.canPayFull,
    required this.canPayRemaining,
    required this.hasPhotographerAssigned,
    required this.isWaitingPhotographerAssignment,
    required this.photographerName,
    required this.photographerEmail,
    required this.photographerPhone,
    required this.hasPhotoLink,
    required this.canOpenPhotoLink,
    required this.photoDriveUrl,
    required this.photoDriveLabel,
    required this.maxPhotoEdit,
    required this.canSubmitEditRequest,
    required this.editRequest,
    required this.canPrint,
    required this.canReview,
    required this.printOrder,
    required this.review,
  });

  factory TrackingBookingModel.fromJson(Map<String, dynamic> json) {
    final packageJson = json['package'] is Map
        ? Map<String, dynamic>.from(json['package'] as Map)
        : <String, dynamic>{};

    final photographerJson = json['photographer'] is Map
        ? Map<String, dynamic>.from(json['photographer'] as Map)
        : null;

    final photoLinkJson = json['photo_link'] is Map
        ? Map<String, dynamic>.from(json['photo_link'] as Map)
        : null;

    final editRequestJson = json['edit_request'] is Map
        ? Map<String, dynamic>.from(json['edit_request'] as Map)
        : null;

    final printOrderJson = json['print_order'] is Map
        ? Map<String, dynamic>.from(json['print_order'] as Map)
        : null;

    final reviewJson = json['review'] is Map
        ? Map<String, dynamic>.from(json['review'] as Map)
        : null;

    final packagePhotoCount = _toInt(packageJson['photo_count']);

    return TrackingBookingModel(
      id: _toInt(json['id']),
      bookingDate: _asString(json['booking_date']),
      startTime: _asString(json['start_time']),
      endTime: _asString(json['end_time']),
      status: _asString(json['status']),
      paymentStatus: _firstString([json['payment_status'], 'unpaid']),

      clientName: _asString(json['client_name']),
      clientPhone: _asString(json['client_phone']),
      locationType: _asString(json['location_type']),
      locationName: _asString(json['location_name']),
      notes: _nullableString(json['notes']),

      packageName: _firstString([
        packageJson['name'],
        packageJson['title'],
        'Paket Foto',
      ]),

      totalBookingAmount: _toInt(json['total_booking_amount']),
      minimumDpAmount: _toInt(json['minimum_dp_amount']),
      paidBookingAmount: _toInt(json['paid_booking_amount']),
      remainingBookingAmount: _toInt(json['remaining_booking_amount']),

      paymentWarning: _nullableString(json['payment_warning']),

      canPayDp: _toBool(json['can_pay_dp']),
      canPayFull: _toBool(json['can_pay_full']),
      canPayRemaining: _toBool(json['can_pay_remaining']),

      hasPhotographerAssigned: _toBool(json['has_photographer_assigned']),
      isWaitingPhotographerAssignment: _toBool(
        json['is_waiting_photographer_assignment'],
      ),

      photographerName: _nullableString(photographerJson?['name']),
      photographerEmail: _nullableString(photographerJson?['email']),
      photographerPhone: _nullableString(photographerJson?['phone']),

      hasPhotoLink: _toBool(json['has_photo_link']),
      canOpenPhotoLink: _toBool(json['can_open_photo_link']),
      photoDriveUrl: _nullableString(photoLinkJson?['drive_url']),
      photoDriveLabel: _nullableString(photoLinkJson?['drive_label']),

      maxPhotoEdit: _toInt(json['max_photo_edit']) > 0
          ? _toInt(json['max_photo_edit'])
          : packagePhotoCount,

      canSubmitEditRequest: _toBool(json['can_submit_edit_request']),
      editRequest: editRequestJson == null
          ? null
          : TrackingEditRequestModel.fromJson(editRequestJson),

      canPrint: _toBool(json['can_print']),
      canReview: _toBool(json['can_review']),
      printOrder: printOrderJson == null
          ? null
          : TrackingPrintOrderModel.fromJson(printOrderJson),

      review: reviewJson == null ? null : ReviewModel.fromJson(reviewJson),
    );
  }

  String get formattedBookingDate {
    return _formatDateOnly(bookingDate);
  }

  String get formattedStartTime {
    return _formatTimeOnly(startTime);
  }

  String get formattedEndTime {
    return _formatTimeOnly(endTime);
  }

  String get formattedBookingDateTime {
    return '$formattedBookingDate, $formattedStartTime - $formattedEndTime';
  }

  String get paymentStatusLabel {
    final value = paymentStatus.toLowerCase();

    if (value == 'paid' || value == 'fully_paid') return 'Lunas';

    if (value == 'dp_paid' || value == 'partially_paid') {
      return 'DP Terbayar';
    }

    if (value == 'pending') return 'Menunggu Pembayaran';
    if (value == 'failed') return 'Pembayaran Gagal';

    return 'Belum Bayar';
  }

  String get bookingStatusLabel {
    final value = status.toLowerCase();

    if (value == 'pending') return 'Menunggu';
    if (value == 'confirmed') return 'Dikonfirmasi';
    if (value == 'completed') return 'Selesai';
    if (value == 'cancelled') return 'Dibatalkan';

    return status.isEmpty ? '-' : status;
  }

  bool get isDpPaid {
    final value = paymentStatus.toLowerCase();

    return value == 'dp_paid' ||
        value == 'partially_paid' ||
        value == 'paid' ||
        value == 'fully_paid';
  }

  bool get isFullyPaid {
    final value = paymentStatus.toLowerCase();

    return value == 'paid' || value == 'fully_paid';
  }
}

class TrackingEditRequestModel {
  final int id;
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
  final TrackingPersonModel? editor;

  TrackingEditRequestModel({
    required this.id,
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
    required this.editor,
  });

  factory TrackingEditRequestModel.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['selected_files'] is List
        ? json['selected_files'] as List
        : <dynamic>[];

    final editorJson = json['editor'] is Map
        ? Map<String, dynamic>.from(json['editor'] as Map)
        : null;

    return TrackingEditRequestModel(
      id: _toInt(json['id']),
      selectedFiles: rawFiles.map((item) => item.toString()).toList(),
      requestNotes: _asString(json['request_notes']),
      status: _asString(json['status']),
      statusLabel: _asString(json['status_label']),
      assignedAt: _asString(json['assigned_at']),
      editDeadlineAt: _asString(json['edit_deadline_at']),
      startedAt: _asString(json['started_at']),
      completedAt: _asString(json['completed_at']),
      editorNotes: _asString(json['editor_notes']),
      resultDriveUrl: _asString(json['result_drive_url']),
      resultDriveLabel: _asString(json['result_drive_label']),
      remainingDays: json['remaining_days'] == null
          ? null
          : _toInt(json['remaining_days']),
      editor: editorJson == null
          ? null
          : TrackingPersonModel.fromJson(editorJson),
    );
  }

  String get formattedAssignedAt {
    return _formatDateTime(assignedAt);
  }

  String get formattedEditDeadline {
    return _formatDateTime(editDeadlineAt);
  }

  String get formattedStartedAt {
    return _formatDateTime(startedAt);
  }

  String get formattedCompletedAt {
    return _formatDateTime(completedAt);
  }

  bool get isSubmitted => status == 'submitted';
  bool get isAssigned => status == 'assigned';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
}

class TrackingPrintOrderModel {
  final int id;
  final int bookingId;
  final int clientUserId;
  final int printPriceId;

  final List<String> selectedFiles;
  final List<TrackingPrintOrderItemModel> items;

  final int quantity;

  final String sizeName;
  final String paperType;
  final bool useFrame;

  final int printUnitPrice;
  final int frameUnitPrice;
  final int subtotalPrint;
  final int subtotalFrame;
  final int totalAmount;

  final String deliveryMethod;
  final String recipientName;
  final String recipientPhone;
  final String deliveryAddress;

  final String status;
  final String statusLabel;
  final String paymentStatus;

  final String paidAt;
  final String processedAt;
  final String completedAt;

  final String deliveryProofPath;
  final String deliveryProofUrl;
  final String completionPhotoPath;
  final String completionPhotoUrl;

  final String notes;

  final TrackingPrintPaymentModel? payment;

  TrackingPrintOrderModel({
    required this.id,
    required this.bookingId,
    required this.clientUserId,
    required this.printPriceId,
    required this.selectedFiles,
    required this.items,
    required this.quantity,
    required this.sizeName,
    required this.paperType,
    required this.useFrame,
    required this.printUnitPrice,
    required this.frameUnitPrice,
    required this.subtotalPrint,
    required this.subtotalFrame,
    required this.totalAmount,
    required this.deliveryMethod,
    required this.recipientName,
    required this.recipientPhone,
    required this.deliveryAddress,
    required this.status,
    required this.statusLabel,
    required this.paymentStatus,
    required this.paidAt,
    required this.processedAt,
    required this.completedAt,
    required this.deliveryProofPath,
    required this.deliveryProofUrl,
    required this.completionPhotoPath,
    required this.completionPhotoUrl,
    required this.notes,
    required this.payment,
  });

  factory TrackingPrintOrderModel.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['selected_files'] is List
        ? json['selected_files'] as List
        : <dynamic>[];

    final rawItems = json['items'] is List
        ? json['items'] as List
        : <dynamic>[];

    final paymentJson = json['payment'] is Map
        ? Map<String, dynamic>.from(json['payment'] as Map)
        : null;

    return TrackingPrintOrderModel(
      id: _toInt(json['id']),
      bookingId: _toInt(json['schedule_booking_id'] ?? json['booking_id']),
      clientUserId: _toInt(json['client_user_id']),
      printPriceId: _toInt(json['print_price_id']),

      selectedFiles: rawFiles.map((item) => item.toString()).toList(),
      items: rawItems
          .where((item) => item is Map)
          .map(
            (item) => TrackingPrintOrderItemModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      quantity: _toInt(json['quantity']),

      sizeName: _asString(json['size_name']),
      paperType: _asString(json['paper_type']),
      useFrame: _toBool(json['use_frame']),

      printUnitPrice: _toInt(json['print_unit_price']),
      frameUnitPrice: _toInt(json['frame_unit_price']),
      subtotalPrint: _toInt(json['subtotal_print']),
      subtotalFrame: _toInt(json['subtotal_frame']),
      totalAmount: _toInt(json['total_amount']),

      deliveryMethod: _firstString([json['delivery_method'], 'pickup']),
      recipientName: _asString(json['recipient_name']),
      recipientPhone: _asString(json['recipient_phone']),
      deliveryAddress: _asString(json['delivery_address']),

      status: _asString(json['status']),
      statusLabel: _asString(json['status_label']),
      paymentStatus: _asString(json['payment_status']),

      paidAt: _asString(json['paid_at']),
      processedAt: _asString(json['processed_at']),
      completedAt: _asString(json['completed_at']),

      deliveryProofPath: _asString(json['delivery_proof_path']),
      deliveryProofUrl: _asString(json['delivery_proof_url']),
      completionPhotoPath: _asString(json['completion_photo_path']),
      completionPhotoUrl: _asString(json['completion_photo_url']),

      notes: _asString(json['notes']),

      payment: paymentJson == null
          ? null
          : TrackingPrintPaymentModel.fromJson(paymentJson),
    );
  }

  bool get isPaid {
    final value = paymentStatus.toLowerCase();
    return value == 'paid' || value == 'settlement' || value == 'capture';
  }

  bool get isPendingPayment {
    return status == 'pending_payment';
  }

  bool get isProcessing {
    return status == 'processing';
  }

  bool get isCompleted {
    return status == 'completed';
  }

  bool get isDelivery {
    return deliveryMethod == 'delivery';
  }

  bool get isPickup {
    return deliveryMethod == 'pickup';
  }

  String get deliveryMethodLabel {
    return isDelivery ? 'Diantar Ekspedisi' : 'Jemput di Studio';
  }

  String get frameLabel {
    return useFrame ? 'Pakai Bingkai' : 'Cetak Saja';
  }

  String get formattedPaidAt {
    return _formatDateTime(paidAt);
  }

  String get formattedProcessedAt {
    return _formatDateTime(processedAt);
  }

  String get formattedCompletedAt {
    return _formatDateTime(completedAt);
  }

  String get cleanStatusLabel {
    if (statusLabel.isNotEmpty) return statusLabel;

    switch (status) {
      case 'pending_payment':
        return 'Menunggu Pembayaran';
      case 'paid':
        return 'Menunggu Diproses';
      case 'processing':
        return 'Sedang Diproses';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status.isEmpty ? '-' : status;
    }
  }
}

class TrackingPrintOrderItemModel {
  final int id;
  final int printOrderId;
  final int printPriceId;
  final String fileName;
  final int qty;
  final bool useFrame;
  final int unitPrintPrice;
  final int unitFramePrice;
  final int lineTotal;
  final String sizeName;

  TrackingPrintOrderItemModel({
    required this.id,
    required this.printOrderId,
    required this.printPriceId,
    required this.fileName,
    required this.qty,
    required this.useFrame,
    required this.unitPrintPrice,
    required this.unitFramePrice,
    required this.lineTotal,
    required this.sizeName,
  });

  factory TrackingPrintOrderItemModel.fromJson(Map<String, dynamic> json) {
    final printPriceJson = json['print_price'] is Map
        ? Map<String, dynamic>.from(json['print_price'] as Map)
        : <String, dynamic>{};

    return TrackingPrintOrderItemModel(
      id: _toInt(json['id']),
      printOrderId: _toInt(json['print_order_id']),
      printPriceId: _toInt(json['print_price_id']),
      fileName: _asString(json['file_name']),
      qty: _toInt(json['qty']),
      useFrame: _toBool(json['use_frame']),
      unitPrintPrice: _toInt(json['unit_print_price']),
      unitFramePrice: _toInt(json['unit_frame_price']),
      lineTotal: _toInt(json['line_total']),
      sizeName: _firstString([
        printPriceJson['size_name'],
        printPriceJson['size_label'],
        json['size_name'],
        '-',
      ]),
    );
  }

  String get frameLabel {
    return useFrame ? 'Pakai Bingkai' : 'Tanpa Bingkai';
  }
}

class TrackingPrintPaymentModel {
  final int id;
  final String orderId;
  final String transactionStatus;
  final int grossAmount;
  final String snapRedirectUrl;

  TrackingPrintPaymentModel({
    required this.id,
    required this.orderId,
    required this.transactionStatus,
    required this.grossAmount,
    required this.snapRedirectUrl,
  });

  factory TrackingPrintPaymentModel.fromJson(Map<String, dynamic> json) {
    return TrackingPrintPaymentModel(
      id: _toInt(json['id']),
      orderId: _asString(json['order_id']),
      transactionStatus: _asString(json['transaction_status']),
      grossAmount: _toInt(json['gross_amount']),
      snapRedirectUrl: _asString(json['snap_redirect_url']),
    );
  }

  bool get isPaid {
    final value = transactionStatus.toLowerCase();
    return value == 'settlement' || value == 'capture';
  }

  bool get isPending {
    final value = transactionStatus.toLowerCase();
    return value == 'pending' || value == 'created';
  }
}

class TrackingPersonModel {
  final int id;
  final String name;
  final String email;
  final String phone;

  TrackingPersonModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory TrackingPersonModel.fromJson(Map<String, dynamic> json) {
    return TrackingPersonModel(
      id: _toInt(json['id']),
      name: _asString(json['name']),
      email: _asString(json['email']),
      phone: _asString(json['phone']),
    );
  }
}

class TrackingTimelineModel {
  final int id;
  final int stageOrder;
  final String stageKey;
  final String stageName;
  final String status;
  final String? description;
  final String? occurredAt;

  TrackingTimelineModel({
    required this.id,
    required this.stageOrder,
    required this.stageKey,
    required this.stageName,
    required this.status,
    required this.description,
    required this.occurredAt,
  });

  factory TrackingTimelineModel.fromJson(Map<String, dynamic> json) {
    return TrackingTimelineModel(
      id: _toInt(json['id']),
      stageOrder: _toInt(json['stage_order']),
      stageKey: _asString(json['stage_key']),
      stageName: _asString(json['stage_name']),
      status: _firstString([json['status'], 'pending']),
      description: _nullableString(json['description']),
      occurredAt: _nullableString(json['occurred_at']),
    );
  }

  bool get isDone => status.toLowerCase() == 'done';
  bool get isCurrent => status.toLowerCase() == 'current';
  bool get isSkipped => status.toLowerCase() == 'skipped';
  bool get isPending => status.toLowerCase() == 'pending';

  String get formattedOccurredAt {
    return _formatDateTime(occurredAt ?? '');
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

String? _nullableString(dynamic value) {
  final text = _asString(value);
  return text.isEmpty ? null : text;
}

String _firstString(List<dynamic> values) {
  for (final value in values) {
    final text = _asString(value);

    if (text.isNotEmpty) {
      return text;
    }
  }

  return '';
}

int _toInt(dynamic value) {
  if (value == null) return 0;

  if (value is int) return value;

  if (value is double) return value.toInt();

  final raw = value.toString().trim();

  if (raw.isEmpty || raw.toLowerCase() == 'null') return 0;

  final cleaned = raw.replaceAll(',', '').replaceAll('.00', '');

  final asInt = int.tryParse(cleaned);
  if (asInt != null) return asInt;

  final asDouble = double.tryParse(cleaned);
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

String _formatDateOnly(String value) {
  if (value.trim().isEmpty) return '-';

  try {
    final parsed = DateTime.parse(value).toLocal();

    return '${_two(parsed.day)} ${_month(parsed.month)} ${parsed.year}';
  } catch (_) {
    try {
      final parsed = DateTime.parse('${value}T00:00:00').toLocal();

      return '${_two(parsed.day)} ${_month(parsed.month)} ${parsed.year}';
    } catch (_) {
      return value;
    }
  }
}

String _formatTimeOnly(String value) {
  if (value.trim().isEmpty) return '-';

  try {
    if (value.contains('T')) {
      final parsed = DateTime.parse(value).toLocal();
      return '${_two(parsed.hour)}:${_two(parsed.minute)} WIB';
    }

    final parts = value.split(':');

    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }

    return value;
  } catch (_) {
    return value;
  }
}

String _formatDateTime(String value) {
  if (value.trim().isEmpty) return '-';

  try {
    final parsed = DateTime.parse(value).toLocal();

    return '${_two(parsed.day)} ${_month(parsed.month)} ${parsed.year}, ${_two(parsed.hour)}:${_two(parsed.minute)} WIB';
  } catch (_) {
    return value;
  }
}

String _two(int value) {
  return value.toString().padLeft(2, '0');
}

String _month(int value) {
  const months = [
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

  if (value < 1 || value > 12) return '';

  return months[value];
}
