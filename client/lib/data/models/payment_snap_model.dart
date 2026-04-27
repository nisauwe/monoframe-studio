class PaymentSnapModel {
  final int paymentId;
  final int bookingId;
  final int printOrderId;
  final String orderId;
  final String snapToken;
  final String redirectUrl;
  final int grossAmount;

  PaymentSnapModel({
    required this.paymentId,
    required this.bookingId,
    required this.printOrderId,
    required this.orderId,
    required this.snapToken,
    required this.redirectUrl,
    required this.grossAmount,
  });

  factory PaymentSnapModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['data'])
        : json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    return PaymentSnapModel(
      paymentId: _toInt(
        data['payment_id'] ?? data['id'] ?? json['payment_id'] ?? json['id'],
      ),
      bookingId: _toInt(
        data['booking_id'] ??
            data['schedule_booking_id'] ??
            json['booking_id'] ??
            json['schedule_booking_id'],
      ),
      printOrderId: _toInt(data['print_order_id'] ?? json['print_order_id']),
      orderId: _firstString([data['order_id'], json['order_id']]),
      snapToken: _firstString([
        data['snap_token'],
        json['snap_token'],
        data['token'],
        json['token'],
      ]),
      redirectUrl: _firstString([
        data['redirect_url'],
        data['snap_redirect_url'],
        json['redirect_url'],
        json['snap_redirect_url'],
      ]),
      grossAmount: _toInt(data['gross_amount'] ?? json['gross_amount']),
    );
  }

  bool get hasValidRedirectUrl {
    return redirectUrl.startsWith('http://') ||
        redirectUrl.startsWith('https://');
  }
}

String _firstString(List<dynamic> values) {
  for (final value in values) {
    if (value == null) continue;

    final text = value.toString().trim();

    if (text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
  }

  return '';
}

int _toInt(dynamic value) {
  if (value == null) return 0;

  if (value is int) return value;

  if (value is double) return value.toInt();

  final text = value.toString().replaceAll('.00', '').trim();

  return int.tryParse(text) ?? 0;
}
