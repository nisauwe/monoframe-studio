class ClientNotificationResponse {
  final int unreadCount;
  final List<ClientNotificationModel> notifications;

  ClientNotificationResponse({
    required this.unreadCount,
    required this.notifications,
  });

  factory ClientNotificationResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'] is List ? json['data'] as List : [];

    return ClientNotificationResponse(
      unreadCount: _toInt(json['unread_count']),
      notifications: rawList
          .map(
            (item) => ClientNotificationModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}

class ClientNotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final String icon;
  final DateTime? createdAt;
  final String? actionType;
  final int? actionId;
  final bool isRead;

  ClientNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.icon,
    required this.createdAt,
    required this.actionType,
    required this.actionId,
    required this.isRead,
  });

  factory ClientNotificationModel.fromJson(Map<String, dynamic> json) {
    return ClientNotificationModel(
      id: _string(json['id']),
      type: _string(json['type']),
      title: _string(json['title']),
      body: _string(json['body']),
      icon: _string(json['icon']),
      createdAt: _toDate(json['created_at']),
      actionType: _nullableString(json['action_type']),
      actionId: json['action_id'] == null ? null : _toInt(json['action_id']),
      isRead: _toBool(json['is_read']),
    );
  }
}

String _string(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return fallback;
  return text;
}

String? _nullableString(dynamic value) {
  final text = _string(value);
  return text.isEmpty ? null : text;
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is num) return value != 0;
  final text = value.toString().toLowerCase().trim();
  return text == 'true' || text == '1' || text == 'yes' || text == 'on';
}

DateTime? _toDate(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return null;
  return DateTime.tryParse(text);
}
