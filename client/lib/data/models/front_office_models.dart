class FoPackageModel {
  final int id;
  final String name;
  final String locationType;
  final int durationMinutes;
  final int photoCount;
  final int price;
  final int finalPrice;

  FoPackageModel({
    required this.id,
    required this.name,
    required this.locationType,
    required this.durationMinutes,
    required this.photoCount,
    required this.price,
    required this.finalPrice,
  });

  factory FoPackageModel.fromJson(Map<String, dynamic> json) {
    return FoPackageModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? 'Paket Foto',
      locationType: json['location_type']?.toString() ?? 'indoor',
      durationMinutes: _toInt(json['duration_minutes']),
      photoCount: _toInt(json['photo_count']),
      price: _toInt(json['price']),
      finalPrice: _toInt(
        json['discounted_price'] ?? json['final_price'] ?? json['price'],
      ),
    );
  }

  String get locationTypeLabel {
    return locationType.toLowerCase() == 'outdoor' ? 'Outdoor' : 'Indoor';
  }
}

class FoAddonModel {
  final int id;
  final String addonKey;
  final String addonName;
  final int price;
  final bool isActive;

  FoAddonModel({
    required this.id,
    required this.addonKey,
    required this.addonName,
    required this.price,
    required this.isActive,
  });

  factory FoAddonModel.fromJson(Map<String, dynamic> json) {
    return FoAddonModel(
      id: _toInt(json['id']),
      addonKey: json['addon_key']?.toString() ?? '',
      addonName: json['addon_name']?.toString() ?? '',
      price: _toInt(json['price']),
      isActive: _toBool(json['is_active']),
    );
  }
}

class FoScheduleSlotModel {
  final String startTime;
  final String endTime;
  final String blockedUntil;
  final int extraDurationMinutes;
  final int extraDurationFee;

  FoScheduleSlotModel({
    required this.startTime,
    required this.endTime,
    required this.blockedUntil,
    required this.extraDurationMinutes,
    required this.extraDurationFee,
  });

  factory FoScheduleSlotModel.fromJson(Map<String, dynamic> json) {
    return FoScheduleSlotModel(
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      blockedUntil: json['blocked_until']?.toString() ?? '',
      extraDurationMinutes: _toInt(json['extra_duration_minutes']),
      extraDurationFee: _toInt(json['extra_duration_fee']),
    );
  }

  String get label {
    return '$startTime - $endTime';
  }
}

class FoBookingModel {
  final int id;
  final String clientName;
  final String clientPhone;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final String status;
  final String paymentStatus;
  final FoPackageModel? package;
  final FoPhotographerModel? photographer;
  final bool canAssign;

  FoBookingModel({
    required this.id,
    required this.clientName,
    required this.clientPhone,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.paymentStatus,
    required this.package,
    required this.photographer,
    required this.canAssign,
  });

  factory FoBookingModel.fromJson(Map<String, dynamic> json) {
    final packageJson = json['package'] is Map
        ? Map<String, dynamic>.from(json['package'])
        : null;

    final photographerJson = json['photographer'] is Map
        ? Map<String, dynamic>.from(json['photographer'])
        : json['photographer_user'] is Map
        ? Map<String, dynamic>.from(json['photographer_user'])
        : null;

    return FoBookingModel(
      id: _toInt(json['id']),
      clientName: json['client_name']?.toString() ?? '',
      clientPhone: json['client_phone']?.toString() ?? '',
      bookingDate: json['booking_date']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? '',
      package: packageJson == null
          ? null
          : FoPackageModel.fromJson(packageJson),
      photographer: photographerJson == null
          ? null
          : FoPhotographerModel.fromJson(photographerJson),
      canAssign: _toBool(json['can_assign']),
    );
  }

  String get packageName {
    return package?.name ?? 'Paket Foto';
  }

  String get paymentStatusLabel {
    final value = paymentStatus.toLowerCase();

    if (value == 'dp_paid' || value == 'partially_paid') {
      return 'DP Terbayar';
    }

    if (value == 'paid' || value == 'fully_paid') {
      return 'Lunas';
    }

    if (value == 'pending') {
      return 'Pending';
    }

    if (value == 'failed') {
      return 'Gagal';
    }

    return 'Belum Bayar';
  }
}

class FoPhotographerModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final bool isAvailable;

  FoPhotographerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.isAvailable,
  });

  factory FoPhotographerModel.fromJson(Map<String, dynamic> json) {
    return FoPhotographerModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      isAvailable: _toBool(json['is_available'], defaultValue: true),
    );
  }
}

class FoCalendarEventModel {
  final int id;
  final String title;
  final String start;
  final String end;
  final String packageName;
  final String photographerName;
  final String status;
  final String locationName;
  final String source;

  FoCalendarEventModel({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.packageName,
    required this.photographerName,
    required this.status,
    required this.locationName,
    required this.source,
  });

  factory FoCalendarEventModel.fromJson(Map<String, dynamic> json) {
    final photographerJson = json['photographer'] is Map
        ? Map<String, dynamic>.from(json['photographer'])
        : <String, dynamic>{};

    return FoCalendarEventModel(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? '',
      start: json['start']?.toString() ?? '',
      end: json['end']?.toString() ?? '',
      packageName: json['package']?.toString() ?? '',
      photographerName: photographerJson['name']?.toString() ?? '-',
      status: json['status']?.toString() ?? '',
      locationName: json['location_name']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
    );
  }
}

class FoTimelineModel {
  final int id;
  final int stageOrder;
  final String stageKey;
  final String stageName;
  final String status;
  final String description;
  final String occurredAt;

  FoTimelineModel({
    required this.id,
    required this.stageOrder,
    required this.stageKey,
    required this.stageName,
    required this.status,
    required this.description,
    required this.occurredAt,
  });

  factory FoTimelineModel.fromJson(Map<String, dynamic> json) {
    return FoTimelineModel(
      id: _toInt(json['id']),
      stageOrder: _toInt(json['stage_order']),
      stageKey: json['stage_key']?.toString() ?? '',
      stageName: json['stage_name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      description: json['description']?.toString() ?? '',
      occurredAt: json['occurred_at']?.toString() ?? '',
    );
  }

  bool get isDone => status.toLowerCase() == 'done';
  bool get isCurrent => status.toLowerCase() == 'current';
}

class FoProgressModel {
  final int id;
  final String clientName;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final String status;
  final FoPackageModel? package;
  final FoPhotographerModel? photographer;
  final bool paymentIsPaid;
  final String paymentStatus;
  final String currentStageName;
  final String currentStageKey;
  final bool hasPhotoLink;
  final String editRequestStatus;
  final List<FoTimelineModel> timeline;

  FoProgressModel({
    required this.id,
    required this.clientName,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.package,
    required this.photographer,
    required this.paymentIsPaid,
    required this.paymentStatus,
    required this.currentStageName,
    required this.currentStageKey,
    required this.hasPhotoLink,
    required this.editRequestStatus,
    required this.timeline,
  });

  factory FoProgressModel.fromJson(Map<String, dynamic> json) {
    final packageJson = json['package'] is Map
        ? Map<String, dynamic>.from(json['package'])
        : null;

    final photographerJson = json['photographer'] is Map
        ? Map<String, dynamic>.from(json['photographer'])
        : null;

    final paymentJson = json['payment'] is Map
        ? Map<String, dynamic>.from(json['payment'])
        : <String, dynamic>{};

    final stageJson = json['current_stage'] is Map
        ? Map<String, dynamic>.from(json['current_stage'])
        : <String, dynamic>{};

    final timelineRaw = json['timeline'] is List
        ? json['timeline'] as List
        : [];

    return FoProgressModel(
      id: _toInt(json['id']),
      clientName: json['client_name']?.toString() ?? '',
      bookingDate: json['booking_date']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      package: packageJson == null
          ? null
          : FoPackageModel.fromJson(packageJson),
      photographer: photographerJson == null
          ? null
          : FoPhotographerModel.fromJson(photographerJson),
      paymentIsPaid: _toBool(paymentJson['is_paid']),
      paymentStatus: paymentJson['transaction_status']?.toString() ?? '',
      currentStageName: stageJson['stage_name']?.toString() ?? '-',
      currentStageKey: stageJson['stage_key']?.toString() ?? '',
      hasPhotoLink: _toBool(json['has_photo_link']),
      editRequestStatus: json['edit_request_status']?.toString() ?? '-',
      timeline: timelineRaw
          .map(
            (item) => FoTimelineModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }

  String get packageName => package?.name ?? 'Paket Foto';
  String get photographerName => photographer?.name ?? 'Belum di-assign';
}

class FoFinanceSummaryModel {
  final int income;
  final int expenses;
  final int balance;
  final List<FoPaymentModel> recentPayments;
  final List<FoExpenseModel> recentExpenses;

  FoFinanceSummaryModel({
    required this.income,
    required this.expenses,
    required this.balance,
    required this.recentPayments,
    required this.recentExpenses,
  });

  factory FoFinanceSummaryModel.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] is Map
        ? Map<String, dynamic>.from(json['summary'])
        : <String, dynamic>{};

    final paymentsRaw = json['recent_payments'] is List
        ? json['recent_payments'] as List
        : <dynamic>[];

    final expensesRaw = json['recent_expenses'] is List
        ? json['recent_expenses'] as List
        : <dynamic>[];

    return FoFinanceSummaryModel(
      income: _toInt(summary['income']),
      expenses: _toInt(summary['expenses']),
      balance: _toInt(summary['balance']),
      recentPayments: paymentsRaw
          .map(
            (item) => FoPaymentModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      recentExpenses: expensesRaw
          .map(
            (item) => FoExpenseModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

class FoPaymentModel {
  final int id;
  final String orderId;
  final String paymentStage;
  final String transactionStatus;
  final int grossAmount;
  final int baseAmount;
  final String paidAt;
  final String clientName;
  final String packageName;

  FoPaymentModel({
    required this.id,
    required this.orderId,
    required this.paymentStage,
    required this.transactionStatus,
    required this.grossAmount,
    required this.baseAmount,
    required this.paidAt,
    required this.clientName,
    required this.packageName,
  });

  factory FoPaymentModel.fromJson(Map<String, dynamic> json) {
    final booking = json['schedule_booking'] is Map
        ? Map<String, dynamic>.from(json['schedule_booking'])
        : <String, dynamic>{};

    final packageJson = booking['package'] is Map
        ? Map<String, dynamic>.from(booking['package'])
        : <String, dynamic>{};

    return FoPaymentModel(
      id: _toInt(json['id']),
      orderId: json['order_id']?.toString() ?? '',
      paymentStage: json['payment_stage']?.toString() ?? '',
      transactionStatus: json['transaction_status']?.toString() ?? '',
      grossAmount: _toInt(json['gross_amount']),
      baseAmount: _toInt(json['base_amount']),
      paidAt:
          json['paid_at']?.toString() ?? json['settled_at']?.toString() ?? '',
      clientName: booking['client_name']?.toString() ?? '-',
      packageName: packageJson['name']?.toString() ?? '-',
    );
  }
}

class FoExpenseModel {
  final int id;
  final String expenseDate;
  final String category;
  final int amount;
  final String description;
  final String createdBy;

  FoExpenseModel({
    required this.id,
    required this.expenseDate,
    required this.category,
    required this.amount,
    required this.description,
    required this.createdBy,
  });

  factory FoExpenseModel.fromJson(Map<String, dynamic> json) {
    final createdByJson = json['created_by'] is Map
        ? Map<String, dynamic>.from(json['created_by'])
        : <String, dynamic>{};

    return FoExpenseModel(
      id: _toInt(json['id']),
      expenseDate: json['expense_date']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      amount: _toInt(json['amount']),
      description: json['description']?.toString() ?? '',
      createdBy: createdByJson['name']?.toString() ?? '-',
    );
  }
}

class FoPrintOrderModel {
  final int id;
  final String status;
  final String deliveryMethod;
  final String deliveryAddress;
  final int totalAmount;
  final String clientName;
  final String packageName;
  final List<FoPrintOrderItemModel> items;

  FoPrintOrderModel({
    required this.id,
    required this.status,
    required this.deliveryMethod,
    required this.deliveryAddress,
    required this.totalAmount,
    required this.clientName,
    required this.packageName,
    required this.items,
  });

  factory FoPrintOrderModel.fromJson(Map<String, dynamic> json) {
    final booking = json['booking'] is Map
        ? Map<String, dynamic>.from(json['booking'])
        : <String, dynamic>{};

    final packageJson = booking['package'] is Map
        ? Map<String, dynamic>.from(booking['package'])
        : <String, dynamic>{};

    final clientJson = json['client'] is Map
        ? Map<String, dynamic>.from(json['client'])
        : <String, dynamic>{};

    final itemsRaw = json['items'] is List ? json['items'] as List : [];

    return FoPrintOrderModel(
      id: _toInt(json['id']),
      status: json['status']?.toString() ?? '',
      deliveryMethod: json['delivery_method']?.toString() ?? '',
      deliveryAddress: json['delivery_address']?.toString() ?? '',
      totalAmount: _toInt(json['total_amount']),
      clientName:
          clientJson['name']?.toString() ??
          booking['client_name']?.toString() ??
          '-',
      packageName: packageJson['name']?.toString() ?? '-',
      items: itemsRaw
          .map(
            (item) =>
                FoPrintOrderItemModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'requested':
        return 'Menunggu Konfirmasi';
      case 'awaiting_payment':
        return 'Menunggu Pembayaran';
      case 'processing':
        return 'Diproses';
      case 'ready_for_pickup':
        return 'Siap Diambil';
      case 'ready_for_delivery':
        return 'Siap Dikirim';
      case 'completed':
        return 'Selesai';
      default:
        return status.isEmpty ? '-' : status;
    }
  }
}

class FoPrintOrderItemModel {
  final int id;
  final String fileName;
  final int quantity;
  final int subtotal;
  final String sizeLabel;

  FoPrintOrderItemModel({
    required this.id,
    required this.fileName,
    required this.quantity,
    required this.subtotal,
    required this.sizeLabel,
  });

  factory FoPrintOrderItemModel.fromJson(Map<String, dynamic> json) {
    final printPrice = json['print_price'] is Map
        ? Map<String, dynamic>.from(json['print_price'])
        : <String, dynamic>{};

    return FoPrintOrderItemModel(
      id: _toInt(json['id']),
      fileName: json['file_name']?.toString() ?? '',
      quantity: _toInt(json['quantity']),
      subtotal: _toInt(json['subtotal']),
      sizeLabel:
          printPrice['size_label']?.toString() ??
          printPrice['name']?.toString() ??
          '-',
    );
  }
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString().replaceAll('.00', '')) ?? 0;
}

bool _toBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value == 1;
  final text = value.toString().toLowerCase();
  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;
  return defaultValue;
}
