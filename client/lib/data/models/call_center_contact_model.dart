class CallCenterContactModel {
  final int id;
  final String title;
  final String? division;
  final String? description;
  final String? contactPerson;
  final String platform;
  final String platformLabel;
  final String contactValue;
  final String? whatsappNumber;
  final String? url;
  final String? contactUrl;
  final String? serviceHours;
  final String priority;
  final String priorityLabel;
  final String status;
  final String statusLabel;
  final bool isEmergency;

  CallCenterContactModel({
    required this.id,
    required this.title,
    required this.division,
    required this.description,
    required this.contactPerson,
    required this.platform,
    required this.platformLabel,
    required this.contactValue,
    required this.whatsappNumber,
    required this.url,
    required this.contactUrl,
    required this.serviceHours,
    required this.priority,
    required this.priorityLabel,
    required this.status,
    required this.statusLabel,
    required this.isEmergency,
  });

  factory CallCenterContactModel.fromJson(Map<String, dynamic> json) {
    return CallCenterContactModel(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? '',
      division: json['division']?.toString(),
      description: json['description']?.toString(),
      contactPerson: json['contact_person']?.toString(),
      platform: json['platform']?.toString() ?? '',
      platformLabel: json['platform_label']?.toString() ?? '',
      contactValue: json['contact_value']?.toString() ?? '',
      whatsappNumber: json['whatsapp_number']?.toString(),
      url: json['url']?.toString(),
      contactUrl: json['contact_url']?.toString(),
      serviceHours: json['service_hours']?.toString(),
      priority: json['priority']?.toString() ?? '',
      priorityLabel: json['priority_label']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? '',
      isEmergency: _toBool(json['is_emergency']),
    );
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
