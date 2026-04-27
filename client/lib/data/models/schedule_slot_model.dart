class ScheduleSlotModel {
  final String startTime;
  final String endTime;
  final String blockedUntil;
  final String label;
  final int? remainingCapacity;
  final int readyPhotographersCount;
  final int extraDurationUnits;
  final int extraDurationMinutes;
  final int extraDurationFee;

  ScheduleSlotModel({
    required this.startTime,
    required this.endTime,
    required this.blockedUntil,
    required this.label,
    required this.remainingCapacity,
    required this.readyPhotographersCount,
    required this.extraDurationUnits,
    required this.extraDurationMinutes,
    required this.extraDurationFee,
  });

  factory ScheduleSlotModel.fromJson(Map<String, dynamic> json) {
    return ScheduleSlotModel(
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      blockedUntil: json['blocked_until']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      remainingCapacity: json['remaining_capacity'] == null
          ? null
          : int.tryParse(json['remaining_capacity'].toString()),
      readyPhotographersCount:
          int.tryParse(json['ready_photographers_count'].toString()) ?? 0,
      extraDurationUnits:
          int.tryParse(json['extra_duration_units'].toString()) ?? 0,
      extraDurationMinutes:
          int.tryParse(json['extra_duration_minutes'].toString()) ?? 0,
      extraDurationFee:
          int.tryParse(json['extra_duration_fee'].toString()) ?? 0,
    );
  }
}
