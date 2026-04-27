class BookingMoodboardModel {
  final int id;
  final String filePath;
  final String fileName;
  final int? fileSize;
  final int sortOrder;
  final String? fileUrl;

  BookingMoodboardModel({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.sortOrder,
    required this.fileUrl,
  });

  factory BookingMoodboardModel.fromJson(Map<String, dynamic> json) {
    return BookingMoodboardModel(
      id: _toInt(json['id']),
      filePath: json['file_path']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? '',
      fileSize: json['file_size'] == null ? null : _toInt(json['file_size']),
      sortOrder: _toInt(json['sort_order']),
      fileUrl: json['file_url']?.toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}
