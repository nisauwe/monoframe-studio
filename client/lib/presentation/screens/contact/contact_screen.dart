import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/app_setting_model.dart';
import '../../../data/models/call_center_contact_model.dart';
import '../../../data/providers/app_setting_provider.dart';
import '../../../data/providers/call_center_provider.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppSettingProvider>().fetchSettings();
      context.read<CallCenterProvider>().fetchContacts();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<AppSettingProvider>().refresh(),
      context.read<CallCenterProvider>().fetchContacts(),
    ]);
  }

  Future<void> openRawUrl(String url, String failedMessage) async {
    final uri = Uri.tryParse(url);

    if (uri == null || url.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failedMessage)));
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!mounted) return;

    if (!opened) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failedMessage)));
    }
  }

  Future<void> openContact(CallCenterContactModel contact) async {
    final url = contact.contactUrl;

    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kontak belum memiliki link yang valid')),
      );
      return;
    }

    await openRawUrl(url, 'Tidak bisa membuka kontak');
  }

  Future<void> openWhatsApp(String value) async {
    final phone = _normalizeWhatsapp(value);

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor WhatsApp studio belum tersedia')),
      );
      return;
    }

    await openRawUrl('https://wa.me/$phone', 'Tidak bisa membuka WhatsApp');
  }

  Future<void> openEmail(String value) async {
    final email = value.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email studio belum tersedia')),
      );
      return;
    }

    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': 'Pertanyaan Layanan Monoframe Studio'},
    );

    await openRawUrl(uri.toString(), 'Tidak bisa membuka email');
  }

  String _normalizeWhatsapp(String value) {
    var phone = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (phone.startsWith('0')) {
      phone = '62${phone.substring(1)}';
    }

    return phone;
  }

  bool _hasStudioContact(StudioSetting studio) {
    return studio.whatsapp.trim().isNotEmpty ||
        studio.email.trim().isNotEmpty ||
        studio.mapsUrl.trim().isNotEmpty ||
        studio.instagramUrl.trim().isNotEmpty ||
        studio.tiktokUrl.trim().isNotEmpty ||
        studio.websiteUrl.trim().isNotEmpty ||
        studio.address.trim().isNotEmpty;
  }

  IconData platformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'whatsapp':
        return Icons.chat_outlined;
      case 'instagram':
        return Icons.camera_alt_outlined;
      case 'tiktok':
        return Icons.music_note_outlined;
      case 'email':
        return Icons.email_outlined;
      case 'phone':
        return Icons.phone_outlined;
      case 'website':
        return Icons.language_outlined;
      default:
        return Icons.link_outlined;
    }
  }

  Color platformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'whatsapp':
        return AppColors.success;
      case 'instagram':
        return const Color(0xFFC13584);
      case 'tiktok':
        return const Color(0xFF111827);
      case 'email':
        return AppColors.warning;
      case 'phone':
        return _ContactPalette.midBlue;
      case 'website':
        return const Color(0xFF0F766E);
      default:
        return AppColors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final callCenterProvider = context.watch<CallCenterProvider>();
    final setting = context.watch<AppSettingProvider>().setting;
    final studio = setting.studio;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: _ContactPalette.darkBlue,
        centerTitle: true,
        title: const Text(
          'Kontak',
          style: TextStyle(
            color: _ContactPalette.darkBlue,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _ContactPalette.darkBlue,
          backgroundColor: _ContactPalette.cardLight,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            children: [
              _ContactHeroCard(studio: studio),

              const SizedBox(height: 18),

              if (_hasStudioContact(studio)) ...[
                const _SectionTitle(
                  icon: Icons.storefront_rounded,
                  title: 'Kontak Studio',
                ),
                const SizedBox(height: 12),
                _StudioContactCard(
                  studio: studio,
                  onOpenWhatsApp: openWhatsApp,
                  onOpenEmail: openEmail,
                  onOpenUrl: openRawUrl,
                ),
                const SizedBox(height: 22),
              ],

              const _SectionTitle(
                icon: Icons.support_agent_rounded,
                title: 'Daftar Kontak Bantuan',
              ),

              const SizedBox(height: 12),

              if (callCenterProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _ContactPalette.darkBlue,
                    ),
                  ),
                )
              else if (callCenterProvider.contacts.isEmpty)
                _EmptyContactState(
                  message:
                      callCenterProvider.errorMessage ??
                      'Kontak yang diaktifkan admin akan tampil di sini.',
                  onRefresh: _refresh,
                )
              else
                ...callCenterProvider.contacts.map((contact) {
                  final color = platformColor(contact.platform);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CallCenterContactCard(
                      contact: contact,
                      icon: platformIcon(contact.platform),
                      color: color,
                      onTap: () => openContact(contact),
                    ),
                  );
                }),

              const SizedBox(height: 24),

              const _SectionTitle(
                icon: Icons.help_outline_rounded,
                title: 'Pertanyaan Cepat',
              ),

              const SizedBox(height: 12),

              const _QuestionInfoCard(
                icon: Icons.photo_camera_outlined,
                title: 'Pertanyaan Paket Foto',
                description:
                    'Gunakan kontak Front Office atau Admin untuk menanyakan harga, durasi, lokasi, jumlah foto edit, dan fasilitas paket.',
              ),

              const SizedBox(height: 12),

              const _QuestionInfoCard(
                icon: Icons.auto_awesome_outlined,
                title: 'Request Foto di Luar Paket',
                description:
                    'Hubungi kontak Monoframe jika kamu punya konsep custom, tema khusus, jumlah orang berbeda, atau kebutuhan foto yang tidak tersedia di paket.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactPalette {
  static const Color darkBlue = Color(0xFF233B93);
  static const Color midBlue = Color(0xFF344FA5);
  static const Color lightBlue = Color(0xFF5E7BDA);

  static const Color cardLight = Color(0xFFF0FAFF);
  static const Color cardMid = Color(0xFFD9F0FA);
  static const Color cardDeep = Color(0xFFC5E4F2);

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkBlue, midBlue, lightBlue],
  );

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardLight, cardMid, cardDeep],
  );
}

class _ContactHeroCard extends StatelessWidget {
  final StudioSetting studio;

  const _ContactHeroCard({required this.studio});

  @override
  Widget build(BuildContext context) {
    final studioName = studio.name.trim().isNotEmpty
        ? studio.name.trim()
        : 'Monoframe Studio';

    final tagline = studio.tagline.trim().isNotEmpty
        ? studio.tagline.trim()
        : 'Hubungi kami untuk bantuan booking, pembayaran, dan layanan foto.';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: _ContactPalette.darkGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _ContactPalette.darkBlue.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -44,
            child: Container(
              width: 142,
              height: 142,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                  ),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studioName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      tagline,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.84),
                        height: 1.35,
                        fontSize: 12.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudioContactCard extends StatelessWidget {
  final StudioSetting studio;
  final Future<void> Function(String value) onOpenWhatsApp;
  final Future<void> Function(String value) onOpenEmail;
  final Future<void> Function(String url, String failedMessage) onOpenUrl;

  const _StudioContactCard({
    required this.studio,
    required this.onOpenWhatsApp,
    required this.onOpenEmail,
    required this.onOpenUrl,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    if (studio.whatsapp.trim().isNotEmpty) {
      items.add(
        _StudioContactTile(
          icon: Icons.chat_outlined,
          color: AppColors.success,
          title: 'WhatsApp',
          value: studio.whatsapp,
          onTap: () => onOpenWhatsApp(studio.whatsapp),
        ),
      );
    }

    if (studio.email.trim().isNotEmpty) {
      items.add(
        _StudioContactTile(
          icon: Icons.email_outlined,
          color: AppColors.warning,
          title: 'Email',
          value: studio.email,
          onTap: () => onOpenEmail(studio.email),
        ),
      );
    }

    if (studio.address.trim().isNotEmpty) {
      items.add(
        _StudioContactTile(
          icon: Icons.location_on_outlined,
          color: _ContactPalette.midBlue,
          title: 'Alamat',
          value: studio.address,
          onTap: studio.mapsUrl.trim().isEmpty
              ? null
              : () => onOpenUrl(studio.mapsUrl, 'Tidak bisa membuka maps'),
        ),
      );
    }

    if (studio.mapsUrl.trim().isNotEmpty && studio.address.trim().isEmpty) {
      items.add(
        _StudioContactTile(
          icon: Icons.map_outlined,
          color: _ContactPalette.midBlue,
          title: 'Google Maps',
          value: 'Buka lokasi studio',
          onTap: () => onOpenUrl(studio.mapsUrl, 'Tidak bisa membuka maps'),
        ),
      );
    }

    if (studio.instagramUrl.trim().isNotEmpty) {
      items.add(
        _StudioContactTile(
          icon: Icons.camera_alt_outlined,
          color: const Color(0xFFC13584),
          title: 'Instagram',
          value: 'Buka Instagram',
          onTap: () =>
              onOpenUrl(studio.instagramUrl, 'Tidak bisa membuka Instagram'),
        ),
      );
    }

    if (studio.tiktokUrl.trim().isNotEmpty) {
      items.add(
        _StudioContactTile(
          icon: Icons.music_note_outlined,
          color: const Color(0xFF111827),
          title: 'TikTok',
          value: 'Buka TikTok',
          onTap: () => onOpenUrl(studio.tiktokUrl, 'Tidak bisa membuka TikTok'),
        ),
      );
    }

    if (studio.websiteUrl.trim().isNotEmpty) {
      items.add(
        _StudioContactTile(
          icon: Icons.language_outlined,
          color: const Color(0xFF0F766E),
          title: 'Website',
          value: 'Buka website',
          onTap: () =>
              onOpenUrl(studio.websiteUrl, 'Tidak bisa membuka website'),
        ),
      );
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ContactPalette.cardDeep),
        boxShadow: [
          BoxShadow(
            color: _ContactPalette.darkBlue.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          return Column(
            children: [
              items[index],
              if (index != items.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 64),
                  child: Divider(
                    height: 1,
                    color: _ContactPalette.cardDeep.withValues(alpha: 0.78),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _StudioContactTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _StudioContactTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        child: Row(
          children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _ContactPalette.darkBlue.withValues(alpha: 0.58),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ContactPalette.darkBlue,
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: _ContactPalette.darkBlue.withValues(alpha: 0.56),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CallCenterContactCard extends StatelessWidget {
  final CallCenterContactModel contact;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CallCenterContactCard({
    required this.contact,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _ContactPalette.cardDeep),
          boxShadow: [
            BoxShadow(
              color: _ContactPalette.darkBlue.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          contact.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ContactPalette.darkBlue,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (contact.isEmergency)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Darurat',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (contact.description != null &&
                      contact.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      contact.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _ContactPalette.darkBlue.withValues(alpha: 0.60),
                        fontSize: 12.2,
                        height: 1.36,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 7),
                  Text(
                    '${contact.platformLabel} • ${contact.contactValue}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ContactPalette.darkBlue,
                      fontSize: 12.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (contact.contactPerson != null &&
                      contact.contactPerson!.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      'PIC: ${contact.contactPerson}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _ContactPalette.darkBlue.withValues(alpha: 0.58),
                        fontSize: 11.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (contact.serviceHours != null &&
                      contact.serviceHours!.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Jam layanan: ${contact.serviceHours}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _ContactPalette.darkBlue.withValues(alpha: 0.58),
                        fontSize: 11.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: _ContactPalette.darkBlue.withValues(alpha: 0.56),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            gradient: _ContactPalette.softGradient,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.white),
          ),
          child: Icon(icon, color: _ContactPalette.darkBlue, size: 16),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ContactPalette.darkBlue,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyContactState extends StatelessWidget {
  final String message;
  final VoidCallback onRefresh;

  const _EmptyContactState({required this.message, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
        decoration: BoxDecoration(
          gradient: _ContactPalette.softGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
        ),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.60),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.contact_phone_outlined,
                size: 34,
                color: _ContactPalette.darkBlue,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada kontak bantuan',
              style: TextStyle(
                color: _ContactPalette.darkBlue,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ContactPalette.darkBlue.withValues(alpha: 0.62),
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Muat Ulang'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _ContactPalette.darkBlue,
                side: const BorderSide(color: _ContactPalette.cardDeep),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _QuestionInfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _ContactPalette.cardDeep),
        boxShadow: [
          BoxShadow(
            color: _ContactPalette.darkBlue.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: _ContactPalette.softGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _ContactPalette.darkBlue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ContactPalette.darkBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: _ContactPalette.darkBlue.withValues(alpha: 0.62),
                    height: 1.45,
                    fontSize: 12.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
