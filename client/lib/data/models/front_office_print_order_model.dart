class FrontOfficePrintOrderModel {
  final int id;
  final int bookingId;
  final String clientName;
  final String clientPhone;
  final String packageName;
  final String status;
  final String statusLabel;
  final String paymentStatus;
  final String deliveryMethod;
  final String deliveryMethodLabel;
  final String recipientName;
  final String recipientPhone;
  final String deliveryAddress;
  final String notes;
  final int quantity;
  final int totalAmount;
  final String completionPhotoUrl;
  final String deliveryProofUrl;
  final List<FrontOfficePrintOrderItemModel> items;

  FrontOfficePrintOrderModel({
    required this.id,
    required this.bookingId,
    required this.clientName,
    required this.clientPhone,
    required this.packageName,
    required this.status,
    required this.statusLabel,
    required this.paymentStatus,
    required this.deliveryMethod,
    required this.deliveryMethodLabel,
    required this.recipientName,
    required this.recipientPhone,
    required this.deliveryAddress,
    required this.notes,
    required this.quantity,
    required this.totalAmount,
    required this.completionPhotoUrl,
    required this.deliveryProofUrl,
    required this.items,
  });

  bool get isPaid {
    return paymentStatus == 'paid' ||
        paymentStatus == 'settlement' ||
        paymentStatus == 'capture';
  }

  bool get isCompleted => status == 'completed';

  bool get canProcess {
    return isPaid && status == 'paid';
  }

  bool get canComplete {
    return isPaid && (status == 'paid' || status == 'processing');
  }

  factory FrontOfficePrintOrderModel.fromJson(Map<String, dynamic> json) {
    final booking = _asMap(json['booking']);
    final client = _asMap(json['client']);
    final package = _asMap(booking['package']);

    final rawItems = _asList(json['items']);

    return FrontOfficePrintOrderModel(
      id: _asInt(json['id']),
      bookingId: _asInt(json['schedule_booking_id']),
      clientName: _firstNotEmpty([
        client['name'],
        booking['client_name'],
        _asMap(booking['client_user'])['name'],
      ]),
      clientPhone: _firstNotEmpty([
        client['phone'],
        booking['client_phone'],
        _asMap(booking['client_user'])['phone'],
      ]),
      packageName: _firstNotEmpty([package['name'], package['title'], '-']),
      status: _asString(json['status']),
      statusLabel: _asString(json['status_label']).isEmpty
          ? _statusLabel(_asString(json['status']))
          : _asString(json['status_label']),
      paymentStatus: _asString(json['payment_status']),
      deliveryMethod: _asString(json['delivery_method']),
      deliveryMethodLabel: _asString(json['delivery_method_label']).isEmpty
          ? _deliveryLabel(_asString(json['delivery_method']))
          : _asString(json['delivery_method_label']),
      recipientName: _asString(json['recipient_name']),
      recipientPhone: _asString(json['recipient_phone']),
      deliveryAddress: _asString(json['delivery_address']),
      notes: _asString(json['notes']),
      quantity: _asInt(json['quantity']),
      totalAmount: _asInt(json['total_amount']),
      completionPhotoUrl: _asString(json['completion_photo_url']),
      deliveryProofUrl: _asString(json['delivery_proof_url']),
      items: rawItems
          .map(
            (item) => FrontOfficePrintOrderItemModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    return <dynamic>[];
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static String _firstNotEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = _asString(value).trim();
      if (text.isNotEmpty) return text;
    }

    return '-';
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Menunggu Diproses';
      case 'processing':
        return 'Sedang Diproses';
      case 'completed':
        return 'Selesai';
      case 'pending_payment':
        return 'Menunggu Pembayaran';
      default:
        return status.isEmpty ? '-' : status;
    }
  }

  static String _deliveryLabel(String method) {
    return method == 'delivery' ? 'Diantar Ekspedisi' : 'Jemput di Studio';
  }
}

class FrontOfficePrintOrderItemModel {
  final int id;
  final String fileName;
  final String sizeName;
  final int qty;
  final bool useFrame;
  final int unitPrintPrice;
  final int unitFramePrice;
  final int lineTotal;

  FrontOfficePrintOrderItemModel({
    required this.id,
    required this.fileName,
    required this.sizeName,
    required this.qty,
    required this.useFrame,
    required this.unitPrintPrice,
    required this.unitFramePrice,
    required this.lineTotal,
  });

  String get frameLabel => useFrame ? 'Pakai Bingkai' : 'Tanpa Bingkai';

  factory FrontOfficePrintOrderItemModel.fromJson(Map<String, dynamic> json) {
    final price = _asMap(json['print_price']);

    return FrontOfficePrintOrderItemModel(
      id: _asInt(json['id']),
      fileName: _asString(json['file_name']),
      sizeName: _firstNotEmpty([
        price['size_name'],
        price['size_label'],
        json['size_name'],
        '-',
      ]),
      qty: _asInt(json['qty']),
      useFrame: json['use_frame'] == true || json['use_frame'] == 1,
      unitPrintPrice: _asInt(json['unit_print_price']),
      unitFramePrice: _asInt(json['unit_frame_price']),
      lineTotal: _asInt(json['line_total']),
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static String _firstNotEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = _asString(value).trim();
      if (text.isNotEmpty) return text;
    }

    return '-';
  }
}
