class BookingModel {
  final int id;
  final int packageId;
  final int? clientUserId;
  final int? photographerUserId;

  final String clientName;
  final String clientPhone;
  final String bookingDate;
  final String startTime;
  final String endTime;

  final String locationType;
  final String locationName;
  final String status;
  final String paymentStatus;
  final String? latestPaymentStatus;
  final String? latestPaymentStage;
  final String? notes;

  final int durationMinutes;
  final int extraDurationUnits;
  final int extraDurationMinutes;
  final int extraDurationFee;

  final String? videoAddonType;
  final String? videoAddonName;
  final int videoAddonPrice;

  final String packageName;
  final int packagePrice;

  final Map<String, dynamic>? latestPayment;

  final bool isDpPaid;
  final bool isFullyPaid;

  final int totalBookingAmount;
  final int minimumDpAmount;
  final int remainingBookingAmount;

  final Map<String, dynamic>? currentStage;
  final String currentStageKey;
  final String currentStageName;
  final String currentStageStatus;
  final String currentStageDescription;

  final bool hasPhotoLink;
  final String? editRequestStatus;
  final String? printOrderStatus;
  final bool hasReview;
  final List<dynamic> timeline;

  BookingModel({
    required this.id,
    required this.packageId,
    required this.clientUserId,
    required this.photographerUserId,
    required this.clientName,
    required this.clientPhone,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.locationType,
    required this.locationName,
    required this.status,
    required this.paymentStatus,
    required this.latestPaymentStatus,
    required this.latestPaymentStage,
    required this.notes,
    required this.durationMinutes,
    required this.extraDurationUnits,
    required this.extraDurationMinutes,
    required this.extraDurationFee,
    required this.videoAddonType,
    required this.videoAddonName,
    required this.videoAddonPrice,
    required this.packageName,
    required this.packagePrice,
    required this.latestPayment,
    required this.isDpPaid,
    required this.isFullyPaid,
    required this.totalBookingAmount,
    required this.minimumDpAmount,
    required this.remainingBookingAmount,
    required this.currentStage,
    required this.currentStageKey,
    required this.currentStageName,
    required this.currentStageStatus,
    required this.currentStageDescription,
    required this.hasPhotoLink,
    required this.editRequestStatus,
    required this.printOrderStatus,
    required this.hasReview,
    required this.timeline,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final packageJson = json['package'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['package'])
        : <String, dynamic>{};

    final latestPaymentJson = json['latest_payment'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['latest_payment'])
        : null;

    final extraDurationFee = _toInt(json['extra_duration_fee']);
    final videoAddonPrice = _toInt(json['video_addon_price']);

    final totalBookingAmount = _toInt(json['total_booking_amount']);

    final inferredPackagePrice =
        totalBookingAmount - extraDurationFee - videoAddonPrice;

    final packageFinalFromJson = _firstPositiveInt([
      packageJson['discounted_price'],
      packageJson['final_price'],
      packageJson['finalPrice'],
      packageJson['package_base_price'],
      json['package_base_price'],
    ]);

    final packageOriginalFromJson = _firstPositiveInt([
      packageJson['price'],
      json['package_price'],
    ]);

    final resolvedPackagePrice = packageFinalFromJson > 0
        ? packageFinalFromJson
        : inferredPackagePrice > 0
        ? inferredPackagePrice
        : packageOriginalFromJson;

    final currentStageJson = json['current_stage'] is Map
        ? Map<String, dynamic>.from(json['current_stage'])
        : null;

    final timelineJson = json['timeline'] is List
        ? json['timeline'] as List<dynamic>
        : <dynamic>[];

    return BookingModel(
      id: _toInt(json['id']),
      packageId: _toInt(json['package_id']),
      clientUserId: json['client_user_id'] == null
          ? null
          : _toInt(json['client_user_id']),
      photographerUserId: json['photographer_user_id'] == null
          ? null
          : _toInt(json['photographer_user_id']),

      clientName: json['client_name']?.toString() ?? '',
      clientPhone: json['client_phone']?.toString() ?? '',

      bookingDate: json['booking_date']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',

      locationType: json['location_type']?.toString() ?? '',
      locationName: json['location_name']?.toString() ?? '',

      status: json['status']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? 'unpaid',

      latestPaymentStatus:
          json['latest_payment_status']?.toString() ??
          latestPaymentJson?['transaction_status']?.toString(),

      latestPaymentStage:
          json['latest_payment_stage']?.toString() ??
          latestPaymentJson?['payment_stage']?.toString(),

      notes: json['notes']?.toString(),

      durationMinutes: _toInt(json['duration_minutes']),
      extraDurationUnits: _toInt(json['extra_duration_units']),
      extraDurationMinutes: _toInt(json['extra_duration_minutes']),
      extraDurationFee: extraDurationFee,

      videoAddonType: json['video_addon_type']?.toString(),
      videoAddonName: json['video_addon_name']?.toString(),
      videoAddonPrice: videoAddonPrice,

      packageName:
          packageJson['name']?.toString() ??
          json['package_name']?.toString() ??
          'Paket Foto',

      packagePrice: resolvedPackagePrice,

      latestPayment: latestPaymentJson,

      isDpPaid: _toBool(json['is_dp_paid']),
      isFullyPaid: _toBool(json['is_fully_paid']),

      totalBookingAmount: totalBookingAmount,
      minimumDpAmount: _toInt(json['minimum_dp_amount']),
      remainingBookingAmount: _toInt(json['remaining_booking_amount']),

      currentStage: currentStageJson,
      currentStageKey: currentStageJson?['stage_key']?.toString() ?? '',
      currentStageName: currentStageJson?['stage_name']?.toString() ?? '',
      currentStageStatus: currentStageJson?['status']?.toString() ?? '',
      currentStageDescription:
          currentStageJson?['description']?.toString() ?? '',

      hasPhotoLink: _toBool(json['has_photo_link']),
      editRequestStatus: json['edit_request_status']?.toString(),
      printOrderStatus: json['print_order_status']?.toString(),
      hasReview: _toBool(json['has_review']),
      timeline: timelineJson,
    );
  }

  bool get hasPaymentAttempt {
    return latestPayment != null || latestPaymentStatus != null;
  }

  bool get isWaitingPayment {
    final payment = paymentStatus.toLowerCase();
    final latest = latestPaymentStatus?.toLowerCase() ?? '';

    return payment == 'unpaid' ||
        payment == 'pending' ||
        latest == 'pending' ||
        latest == 'created';
  }

  bool get isPaymentPending {
    final latest = latestPaymentStatus?.toLowerCase() ?? '';
    return latest == 'pending' || latest == 'created';
  }

  bool get isPaymentFailed {
    final payment = paymentStatus.toLowerCase();
    final latest = latestPaymentStatus?.toLowerCase() ?? '';

    return payment == 'failed' ||
        latest == 'deny' ||
        latest == 'expire' ||
        latest == 'cancel' ||
        latest == 'failure';
  }

  bool get isPaid {
    final payment = paymentStatus.toLowerCase();
    final latest = latestPaymentStatus?.toLowerCase() ?? '';

    return isDpPaid ||
        isFullyPaid ||
        payment == 'dp_paid' ||
        payment == 'paid' ||
        payment == 'partially_paid' ||
        payment == 'fully_paid' ||
        latest == 'settlement' ||
        latest == 'capture';
  }

  bool get isUnpaid {
    return !isPaid;
  }

  String get paymentStatusLabel {
    final payment = paymentStatus.toLowerCase();
    final latest = latestPaymentStatus?.toLowerCase() ?? '';

    if (isFullyPaid || payment == 'paid' || payment == 'fully_paid') {
      return 'Lunas';
    }

    if (isDpPaid || payment == 'dp_paid' || payment == 'partially_paid') {
      return 'DP Terbayar';
    }

    if (latest == 'settlement' || latest == 'capture') {
      return 'Pembayaran Sukses';
    }

    if (isPaymentPending) {
      return 'Pembayaran Pending';
    }

    if (isPaymentFailed) {
      return 'Pembayaran Gagal';
    }

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

  bool get canContinuePayment {
    return !isPaid && !isPaymentFailed;
  }

  int get totalEstimatedAmount {
    if (totalBookingAmount > 0) return totalBookingAmount;
    return packagePrice + extraDurationFee + videoAddonPrice;
  }

  int get packagePriceForBilling {
    if (packagePrice > 0) return packagePrice;

    final inferred = totalEstimatedAmount - extraDurationFee - videoAddonPrice;

    if (inferred > 0) {
      return inferred;
    }

    return 0;
  }

  int get dpAmountForBilling {
    if (minimumDpAmount > 0) return minimumDpAmount;
    return (totalEstimatedAmount * 0.5).ceil();
  }

  int get fullAmountForBilling {
    return totalEstimatedAmount;
  }

  static int _firstPositiveInt(List<dynamic> values) {
    for (final value in values) {
      final parsed = _toInt(value);

      if (parsed > 0) {
        return parsed;
      }
    }

    return 0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    return value.toString().toLowerCase() == 'true';
  }
}
