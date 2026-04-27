class PrintPriceModel {
  final int id;
  final String sizeName;
  final String paperType;
  final int printPrice;
  final int framePrice;
  final bool isAvailable;

  PrintPriceModel({
    required this.id,
    required this.sizeName,
    required this.paperType,
    required this.printPrice,
    required this.framePrice,
    required this.isAvailable,
  });

  factory PrintPriceModel.fromJson(Map<String, dynamic> json) {
    return PrintPriceModel(
      id: _toInt(json['id']),
      sizeName: _firstString([
        json['size_name'],
        json['size_label'],
        json['label'],
        json['name'],
      ]),
      paperType: _firstString([
        json['paper_type'],
        json['notes'],
        json['description'],
      ]),
      printPrice: _firstPositiveInt([
        json['print_price'],
        json['base_price'],
        json['price'],
      ]),
      framePrice: _firstPositiveInt([
        json['frame_price'],
        json['bingkai_price'],
        json['frame'],
      ]),
      isAvailable: _toBool(json['is_available'] ?? json['is_active'] ?? true),
    );
  }
}

class PrintOrderItemPayload {
  final int printPriceId;
  final String fileName;
  final int qty;
  final bool useFrame;

  PrintOrderItemPayload({
    required this.printPriceId,
    required this.fileName,
    required this.qty,
    required this.useFrame,
  });

  Map<String, dynamic> toJson() {
    return {
      'print_price_id': printPriceId,
      'file_name': fileName,
      'qty': qty,
      'use_frame': useFrame,
    };
  }
}

class PrintOrderItemModel {
  final int id;
  final int printOrderId;
  final int printPriceId;
  final String fileName;
  final int qty;
  final bool useFrame;
  final int unitPrintPrice;
  final int unitFramePrice;
  final int lineTotal;
  final PrintPriceModel? printPrice;

  PrintOrderItemModel({
    required this.id,
    required this.printOrderId,
    required this.printPriceId,
    required this.fileName,
    required this.qty,
    required this.useFrame,
    required this.unitPrintPrice,
    required this.unitFramePrice,
    required this.lineTotal,
    required this.printPrice,
  });

  factory PrintOrderItemModel.fromJson(Map<String, dynamic> json) {
    final priceJson = json['print_price'] is Map
        ? Map<String, dynamic>.from(json['print_price'] as Map)
        : null;

    return PrintOrderItemModel(
      id: _toInt(json['id']),
      printOrderId: _toInt(json['print_order_id']),
      printPriceId: _toInt(json['print_price_id']),
      fileName: _asString(json['file_name']),
      qty: _toInt(json['qty']),
      useFrame: _toBool(json['use_frame']),
      unitPrintPrice: _toInt(json['unit_print_price']),
      unitFramePrice: _toInt(json['unit_frame_price']),
      lineTotal: _toInt(json['line_total']),
      printPrice: priceJson == null
          ? null
          : PrintPriceModel.fromJson(priceJson),
    );
  }

  String get sizeName {
    return printPrice?.sizeName ?? '-';
  }

  String get frameLabel {
    return useFrame ? 'Pakai Bingkai' : 'Tanpa Bingkai';
  }
}

class PrintOrderModel {
  final int id;
  final int bookingId;
  final int clientUserId;

  final List<String> selectedFiles;
  final List<PrintOrderItemModel> items;

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
  final String paymentStatus;

  final String completionPhotoUrl;
  final String deliveryProofUrl;

  final String notes;

  PrintOrderModel({
    required this.id,
    required this.bookingId,
    required this.clientUserId,
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
    required this.paymentStatus,
    required this.completionPhotoUrl,
    required this.deliveryProofUrl,
    required this.notes,
  });

  factory PrintOrderModel.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['selected_files'] is List
        ? json['selected_files'] as List
        : <dynamic>[];

    final rawItems = json['items'] is List
        ? json['items'] as List
        : <dynamic>[];

    return PrintOrderModel(
      id: _toInt(json['id']),
      bookingId: _toInt(json['schedule_booking_id'] ?? json['booking_id']),
      clientUserId: _toInt(json['client_user_id']),

      selectedFiles: rawFiles.map((e) => e.toString()).toList(),

      items: rawItems
          .where((item) => item is Map)
          .map(
            (item) => PrintOrderItemModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),

      quantity: _toInt(json['quantity']),

      sizeName: _firstString([json['size_name'], json['size_label']]),

      paperType: _firstString([json['paper_type'], json['notes']]),

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
      paymentStatus: _asString(json['payment_status']),

      completionPhotoUrl: _asString(json['completion_photo_url']),
      deliveryProofUrl: _asString(json['delivery_proof_url']),

      notes: _asString(json['notes']),
    );
  }

  bool get isPaid {
    return paymentStatus == 'paid' ||
        paymentStatus == 'settlement' ||
        paymentStatus == 'capture';
  }

  bool get isCompleted {
    return status == 'completed';
  }

  String get deliveryMethodLabel {
    return deliveryMethod == 'delivery'
        ? 'Diantar Ekspedisi'
        : 'Jemput di Studio';
  }

  String get statusLabel {
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

String _asString(dynamic value) {
  if (value == null) return '';

  final text = value.toString().trim();

  if (text.isEmpty || text.toLowerCase() == 'null') {
    return '';
  }

  return text;
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

int _firstPositiveInt(List<dynamic> values) {
  for (final value in values) {
    final number = _toInt(value);

    if (number > 0) {
      return number;
    }
  }

  return 0;
}

int _toInt(dynamic value) {
  if (value == null) return 0;

  if (value is int) return value;

  if (value is double) return value.toInt();

  final raw = value.toString().trim();

  if (raw.isEmpty || raw.toLowerCase() == 'null') return 0;

  final cleaned = raw.replaceAll(',', '');

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
