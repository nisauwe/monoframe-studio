class PhotographerPackageModel {
  final int id;
  final String name;
  final String locationType;
  final int durationMinutes;
  final int photoCount;
  final int personCount;
  final int price;
  final String description;

  PhotographerPackageModel({
    required this.id,
    required this.name,
    required this.locationType,
    required this.durationMinutes,
    required this.photoCount,
    required this.personCount,
    required this.price,
    required this.description,
  });

  factory PhotographerPackageModel.fromJson(Map<String, dynamic> json) {
    return PhotographerPackageModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? 'Paket Foto',
      locationType: json['location_type']?.toString() ?? '',
      durationMinutes: _toInt(json['duration_minutes']),
      photoCount: _toInt(json['photo_count']),
      personCount: _toInt(json['person_count']),
      price: _toInt(json['price']),
      description: json['description']?.toString() ?? '',
    );
  }

  String get locationTypeLabel {
    final value = locationType.toLowerCase();

    if (value == 'outdoor') {
      return 'Outdoor';
    }

    if (value == 'indoor') {
      return 'Indoor';
    }

    return locationType.isEmpty ? '-' : locationType;
  }
}

class PhotographerClientModel {
  final int id;
  final String name;
  final String email;
  final String username;
  final String phone;
  final String address;

  PhotographerClientModel({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.phone,
    required this.address,
  });

  factory PhotographerClientModel.fromJson(Map<String, dynamic> json) {
    return PhotographerClientModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      phone:
          json['phone']?.toString() ??
          json['whatsapp']?.toString() ??
          json['phone_number']?.toString() ??
          '',
      address: json['address']?.toString() ?? json['alamat']?.toString() ?? '',
    );
  }
}

class PhotographerMoodboardModel {
  final int id;
  final String filePath;
  final String fileUrl;
  final String originalName;
  final int sortOrder;

  PhotographerMoodboardModel({
    required this.id,
    required this.filePath,
    required this.fileUrl,
    required this.originalName,
    required this.sortOrder,
  });

  factory PhotographerMoodboardModel.fromJson(Map<String, dynamic> json) {
    return PhotographerMoodboardModel(
      id: _toInt(json['id']),
      filePath: json['file_path']?.toString() ?? json['path']?.toString() ?? '',
      fileUrl:
          json['file_url']?.toString() ??
          json['url']?.toString() ??
          json['full_url']?.toString() ??
          '',
      originalName:
          json['original_name']?.toString() ??
          json['file_name']?.toString() ??
          'Moodboard',
      sortOrder: _toInt(json['sort_order']),
    );
  }

  String get displayUrl {
    if (fileUrl.isNotEmpty) return fileUrl;
    return filePath;
  }
}

class PhotographerPhotoLinkModel {
  final int id;
  final int scheduleBookingId;
  final int photographerUserId;
  final String driveUrl;
  final String driveLabel;
  final String notes;
  final String uploadedAt;
  final bool isActive;

  PhotographerPhotoLinkModel({
    required this.id,
    required this.scheduleBookingId,
    required this.photographerUserId,
    required this.driveUrl,
    required this.driveLabel,
    required this.notes,
    required this.uploadedAt,
    required this.isActive,
  });

  factory PhotographerPhotoLinkModel.fromJson(Map<String, dynamic> json) {
    return PhotographerPhotoLinkModel(
      id: _toInt(json['id']),
      scheduleBookingId: _toInt(json['schedule_booking_id']),
      photographerUserId: _toInt(json['photographer_user_id']),
      driveUrl: json['drive_url']?.toString() ?? '',
      driveLabel: json['drive_label']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      uploadedAt: json['uploaded_at']?.toString() ?? '',
      isActive: _toBool(json['is_active']),
    );
  }
}

class PhotographerBookingModel {
  final int id;
  final int packageId;
  final int? clientUserId;
  final int? photographerUserId;

  final String clientName;
  final String clientPhone;
  final String photographerName;

  final String bookingDate;
  final String startTime;
  final String endTime;
  final String blockedUntil;

  final int durationMinutes;
  final int extraDurationMinutes;
  final int extraDurationFee;

  final String videoAddonType;
  final String videoAddonName;
  final int videoAddonPrice;

  final String locationType;
  final String locationName;
  final String status;
  final String paymentStatus;
  final String source;
  final String notes;

  final PhotographerPackageModel? package;
  final PhotographerClientModel? clientUser;
  final PhotographerPhotoLinkModel? photoLink;
  final List<PhotographerMoodboardModel> moodboards;

  PhotographerBookingModel({
    required this.id,
    required this.packageId,
    required this.clientUserId,
    required this.photographerUserId,
    required this.clientName,
    required this.clientPhone,
    required this.photographerName,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.blockedUntil,
    required this.durationMinutes,
    required this.extraDurationMinutes,
    required this.extraDurationFee,
    required this.videoAddonType,
    required this.videoAddonName,
    required this.videoAddonPrice,
    required this.locationType,
    required this.locationName,
    required this.status,
    required this.paymentStatus,
    required this.source,
    required this.notes,
    required this.package,
    required this.clientUser,
    required this.photoLink,
    required this.moodboards,
  });

  factory PhotographerBookingModel.fromJson(Map<String, dynamic> json) {
    final packageJson = json['package'] is Map
        ? Map<String, dynamic>.from(json['package'])
        : null;

    final clientJson = json['client_user'] is Map
        ? Map<String, dynamic>.from(json['client_user'])
        : json['clientUser'] is Map
        ? Map<String, dynamic>.from(json['clientUser'])
        : null;

    final photoLinkJson = json['photo_link'] is Map
        ? Map<String, dynamic>.from(json['photo_link'])
        : json['photoLink'] is Map
        ? Map<String, dynamic>.from(json['photoLink'])
        : null;

    final moodboardRaw = json['moodboards'] is List
        ? json['moodboards'] as List
        : <dynamic>[];

    return PhotographerBookingModel(
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
      photographerName: json['photographer_name']?.toString() ?? '',
      bookingDate: json['booking_date']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      blockedUntil: json['blocked_until']?.toString() ?? '',
      durationMinutes: _toInt(json['duration_minutes']),
      extraDurationMinutes: _toInt(json['extra_duration_minutes']),
      extraDurationFee: _toInt(json['extra_duration_fee']),
      videoAddonType: json['video_addon_type']?.toString() ?? '',
      videoAddonName: json['video_addon_name']?.toString() ?? '',
      videoAddonPrice: _toInt(json['video_addon_price']),
      locationType: json['location_type']?.toString() ?? '',
      locationName: json['location_name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      package: packageJson == null
          ? null
          : PhotographerPackageModel.fromJson(packageJson),
      clientUser: clientJson == null
          ? null
          : PhotographerClientModel.fromJson(clientJson),
      photoLink: photoLinkJson == null
          ? null
          : PhotographerPhotoLinkModel.fromJson(photoLinkJson),
      moodboards: moodboardRaw
          .map(
            (item) => PhotographerMoodboardModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  bool get hasPhotoLink {
    return photoLink != null && photoLink!.driveUrl.isNotEmpty;
  }

  bool get isToday {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return bookingDate == today;
  }

  bool get isPast {
    final date = DateTime.tryParse(bookingDate);
    if (date == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return date.isBefore(today);
  }

  bool get isUpcoming {
    final date = DateTime.tryParse(bookingDate);
    if (date == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return date.isAfter(today);
  }

  String get packageName {
    return package?.name ?? 'Paket Foto';
  }

  String get locationTypeLabel {
    final value = locationType.toLowerCase();

    if (value == 'indoor') return 'Indoor';
    if (value == 'outdoor') return 'Outdoor';

    return locationType.isEmpty ? '-' : locationType;
  }

  String get statusLabel {
    final value = status.toLowerCase();

    if (value == 'pending') return 'Menunggu';
    if (value == 'confirmed') return 'Dikonfirmasi';
    if (value == 'completed') return 'Selesai';
    if (value == 'cancelled') return 'Dibatalkan';

    return status.isEmpty ? '-' : status;
  }

  String get paymentStatusLabel {
    final value = paymentStatus.toLowerCase();

    if (value == 'dp_paid' || value == 'partially_paid') {
      return 'DP Terbayar';
    }

    if (value == 'paid' || value == 'fully_paid') {
      return 'Lunas';
    }

    if (value == 'pending') return 'Pending';
    if (value == 'failed') return 'Gagal';

    return 'Belum Bayar';
  }
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();

  final text = value.toString().replaceAll('.00', '');
  return int.tryParse(text) ?? 0;
}

bool _toBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is int) return value == 1;

  final text = value.toString().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes';
}
