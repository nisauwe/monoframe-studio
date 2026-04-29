class AppSettingModel {
  final StudioSetting studio;
  final ClientHomeSetting clientHome;
  final BookingSetting booking;
  final ReviewSetting review;
  final SystemSetting system;

  AppSettingModel({
    required this.studio,
    required this.clientHome,
    required this.booking,
    required this.review,
    required this.system,
  });

  factory AppSettingModel.fromJson(Map<String, dynamic> json) {
    return AppSettingModel(
      studio: StudioSetting.fromJson(_map(json['studio'])),
      clientHome: ClientHomeSetting.fromJson(_map(json['client_home'])),
      booking: BookingSetting.fromJson(_map(json['booking'])),
      review: ReviewSetting.fromJson(_map(json['review'])),
      system: SystemSetting.fromJson(_map(json['system'])),
    );
  }

  factory AppSettingModel.fallback() {
    return AppSettingModel(
      studio: StudioSetting.fallback(),
      clientHome: ClientHomeSetting.fallback(),
      booking: BookingSetting.fallback(),
      review: ReviewSetting.fallback(),
      system: SystemSetting.fallback(),
    );
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }
}

class StudioSetting {
  final String name;
  final String tagline;
  final String logo;
  final String logoUrl;
  final String address;
  final String mapsUrl;
  final String email;
  final String whatsapp;
  final String instagramUrl;
  final String tiktokUrl;
  final String websiteUrl;

  StudioSetting({
    required this.name,
    required this.tagline,
    required this.logo,
    required this.logoUrl,
    required this.address,
    required this.mapsUrl,
    required this.email,
    required this.whatsapp,
    required this.instagramUrl,
    required this.tiktokUrl,
    required this.websiteUrl,
  });

  factory StudioSetting.fallback() {
    return StudioSetting(
      name: 'Monoframe Studio',
      tagline: 'Capture Your Best Moment',
      logo: '',
      logoUrl: '',
      address: '',
      mapsUrl: '',
      email: '',
      whatsapp: '',
      instagramUrl: '',
      tiktokUrl: '',
      websiteUrl: '',
    );
  }

  factory StudioSetting.fromJson(Map<String, dynamic> json) {
    return StudioSetting(
      name: _string(json['name'], fallback: 'Monoframe Studio'),
      tagline: _string(json['tagline'], fallback: 'Capture Your Best Moment'),
      logo: _string(json['logo']),
      logoUrl: _string(json['logo_url']),
      address: _string(json['address']),
      mapsUrl: _string(json['maps_url']),
      email: _string(json['email']),
      whatsapp: _string(json['whatsapp']),
      instagramUrl: _string(json['instagram_url']),
      tiktokUrl: _string(json['tiktok_url']),
      websiteUrl: _string(json['website_url']),
    );
  }
}

class ClientHomeSetting {
  final String title;
  final String subtitle;
  final String banner;
  final String bannerUrl;
  final String ctaText;
  final bool showPopularPackages;
  final bool showClientReviews;
  final bool showSupportContact;

  ClientHomeSetting({
    required this.title,
    required this.subtitle,
    required this.banner,
    required this.bannerUrl,
    required this.ctaText,
    required this.showPopularPackages,
    required this.showClientReviews,
    required this.showSupportContact,
  });

  factory ClientHomeSetting.fallback() {
    return ClientHomeSetting(
      title: 'Studio foto modern untuk momen terbaikmu',
      subtitle:
          'Pilih paket, lihat portofolio, booking jadwal, dan pantau hasil foto langsung dari aplikasi.',
      banner: '',
      bannerUrl: '',
      ctaText: 'Lihat Paket',
      showPopularPackages: true,
      showClientReviews: true,
      showSupportContact: true,
    );
  }

  factory ClientHomeSetting.fromJson(Map<String, dynamic> json) {
    return ClientHomeSetting(
      title: _string(
        json['title'],
        fallback: 'Studio foto modern untuk momen terbaikmu',
      ),
      subtitle: _string(
        json['subtitle'],
        fallback:
            'Pilih paket, lihat portofolio, booking jadwal, dan pantau hasil foto langsung dari aplikasi.',
      ),
      banner: _string(json['banner']),
      bannerUrl: _string(json['banner_url']),
      ctaText: _string(json['cta_text'], fallback: 'Lihat Paket'),
      showPopularPackages: _bool(json['show_popular_packages'], fallback: true),
      showClientReviews: _bool(json['show_client_reviews'], fallback: true),
      showSupportContact: _bool(json['show_support_contact'], fallback: true),
    );
  }
}

class BookingSetting {
  final bool isActive;
  final String closedMessage;
  final int maxMoodboardUpload;
  final int maxExtraDurationUnits;
  final int minRescheduleDays;
  final String policy;
  final String terms;

  BookingSetting({
    required this.isActive,
    required this.closedMessage,
    required this.maxMoodboardUpload,
    required this.maxExtraDurationUnits,
    required this.minRescheduleDays,
    required this.policy,
    required this.terms,
  });

  factory BookingSetting.fallback() {
    return BookingSetting(
      isActive: true,
      closedMessage: '',
      maxMoodboardUpload: 10,
      maxExtraDurationUnits: 10,
      minRescheduleDays: 2,
      policy: '',
      terms: '',
    );
  }

  factory BookingSetting.fromJson(Map<String, dynamic> json) {
    return BookingSetting(
      isActive: _bool(json['is_active'], fallback: true),
      closedMessage: _string(json['closed_message']),
      maxMoodboardUpload: _int(json['max_moodboard_upload'], fallback: 10),
      maxExtraDurationUnits: _int(
        json['max_extra_duration_units'],
        fallback: 10,
      ),
      minRescheduleDays: _int(json['min_reschedule_days'], fallback: 2),
      policy: _string(json['policy']),
      terms: _string(json['terms']),
    );
  }
}

class ReviewSetting {
  final bool isActive;
  final bool showOnClient;
  final int minimumRatingDisplay;
  final bool autoHideLowRating;
  final String invitationMessage;

  ReviewSetting({
    required this.isActive,
    required this.showOnClient,
    required this.minimumRatingDisplay,
    required this.autoHideLowRating,
    required this.invitationMessage,
  });

  factory ReviewSetting.fallback() {
    return ReviewSetting(
      isActive: true,
      showOnClient: true,
      minimumRatingDisplay: 4,
      autoHideLowRating: true,
      invitationMessage: 'Bagikan pengalamanmu bersama Monoframe Studio.',
    );
  }

  factory ReviewSetting.fromJson(Map<String, dynamic> json) {
    return ReviewSetting(
      isActive: _bool(json['is_active'], fallback: true),
      showOnClient: _bool(json['show_on_client'], fallback: true),
      minimumRatingDisplay: _int(json['minimum_rating_display'], fallback: 4),
      autoHideLowRating: _bool(json['auto_hide_low_rating'], fallback: true),
      invitationMessage: _string(
        json['invitation_message'],
        fallback: 'Bagikan pengalamanmu bersama Monoframe Studio.',
      ),
    );
  }
}

class SystemSetting {
  final bool maintenanceMode;
  final String maintenanceMessage;
  final bool allowClientRegistration;

  SystemSetting({
    required this.maintenanceMode,
    required this.maintenanceMessage,
    required this.allowClientRegistration,
  });

  factory SystemSetting.fallback() {
    return SystemSetting(
      maintenanceMode: false,
      maintenanceMessage: '',
      allowClientRegistration: true,
    );
  }

  factory SystemSetting.fromJson(Map<String, dynamic> json) {
    return SystemSetting(
      maintenanceMode: _bool(json['maintenance_mode']),
      maintenanceMessage: _string(json['maintenance_message']),
      allowClientRegistration: _bool(
        json['allow_client_registration'],
        fallback: true,
      ),
    );
  }
}

String _string(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return fallback;
  return text;
}

bool _bool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value.toString().toLowerCase().trim();
  if (text == 'true' || text == '1' || text == 'yes' || text == 'on')
    return true;
  if (text == 'false' || text == '0' || text == 'no' || text == 'off')
    return false;
  return fallback;
}

int _int(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}
