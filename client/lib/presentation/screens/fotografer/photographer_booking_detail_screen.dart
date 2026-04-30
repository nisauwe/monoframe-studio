import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/photographer_models.dart';
import '../../../data/providers/photographer_provider.dart';
import '../../../data/services/dio_client.dart';
import 'photographer_photo_link_form_screen.dart';

class PhotographerBookingDetailScreen extends StatefulWidget {
  final int bookingId;

  const PhotographerBookingDetailScreen({super.key, required this.bookingId});

  @override
  State<PhotographerBookingDetailScreen> createState() =>
      _PhotographerBookingDetailScreenState();
}

class _PhotographerBookingDetailScreenState
    extends State<PhotographerBookingDetailScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PhotographerProvider>().fetchBookingDetail(
        bookingId: widget.bookingId,
      );
    });
  }

  Future<void> _refresh() {
    return context.read<PhotographerProvider>().fetchBookingDetail(
      bookingId: widget.bookingId,
    );
  }

  Future<void> _openUrl(String url) async {
    final cleanUrl = url.trim();

    if (cleanUrl.isEmpty) {
      _showMessage('Link belum tersedia');
      return;
    }

    final uri = Uri.tryParse(cleanUrl);

    if (uri == null || !uri.hasScheme) {
      _showMessage('Link tidak valid');
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!mounted) return;

    if (!opened) {
      _showMessage('Tidak bisa membuka link');
    }
  }

  Future<void> _openPhotoLinkForm(PhotographerBookingModel booking) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotographerPhotoLinkFormScreen(booking: booking),
      ),
    );

    if (!mounted) return;
    await _refresh();
  }

  void _openMoodboardViewer({
    required List<PhotographerMoodboardModel> moodboards,
    required int initialIndex,
  }) {
    final items = moodboards
        .where((item) => _moodboardUrl(item).trim().isNotEmpty)
        .map(
          (item) => _MoodboardPreviewItem(
            title: _safe(item.originalName, fallback: 'Moodboard'),
            url: _moodboardUrl(item),
          ),
        )
        .toList();

    if (items.isEmpty) {
      _showMessage('File moodboard tidak bisa dibuka.');
      return;
    }

    var safeIndex = initialIndex;

    if (safeIndex < 0) safeIndex = 0;
    if (safeIndex >= items.length) safeIndex = items.length - 1;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.92),
      builder: (_) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          child: _MoodboardFullScreenViewer(
            items: items,
            initialIndex: safeIndex,
          ),
        );
      },
    );
  }

  String _moodboardUrl(PhotographerMoodboardModel moodboard) {
    return DioClient.normalizePublicUrl(moodboard.displayUrl);
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _safe(String value, {String fallback = '-'}) {
    final clean = value.trim();
    return clean.isEmpty ? fallback : clean;
  }

  String _time(String value) {
    final text = value.trim();

    if (text.isEmpty) return '-';

    final parts = text.split(':');

    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }

    return text;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotographerProvider>();
    final booking = provider.selectedBooking;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.secondary,
              AppColors.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: _DetailPalette.darkBlue,
            backgroundColor: _DetailPalette.cardLight,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              children: [
                _TopBar(
                  title: 'Detail Jadwal',
                  onBack: () => Navigator.pop(context),
                ),
                const SizedBox(height: 14),

                if (provider.isLoading && booking == null)
                  const _LoadingState()
                else if (booking == null)
                  _ErrorState(
                    message:
                        provider.errorMessage ??
                        'Detail booking tidak ditemukan',
                    onRetry: _refresh,
                  )
                else ...[
                  _DetailHero(
                    booking: booking,
                    timeText:
                        '${_time(booking.startTime)} - ${_time(booking.endTime)}',
                  ),

                  const SizedBox(height: 18),

                  _StatusBanner(booking: booking),

                  const SizedBox(height: 18),

                  const _SectionTitle(
                    title: 'Detail Paket',
                    subtitle: 'Detail tanggal, jam, durasi, dan lokasi foto.',
                  ),

                  const SizedBox(height: 12),

                  _InfoCard(
                    children: [
                      _InfoGridRow(
                        left: _CompactInfo(
                          icon: Icons.calendar_month_rounded,
                          label: 'Tanggal',
                          value: _safe(booking.bookingDate),
                        ),
                        right: _CompactInfo(
                          icon: Icons.schedule_rounded,
                          label: 'Jam',
                          value:
                              '${_time(booking.startTime)} - ${_time(booking.endTime)}',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoGridRow(
                        left: _CompactInfo(
                          icon: Icons.timer_rounded,
                          label: 'Durasi',
                          value:
                              '${booking.durationMinutes + booking.extraDurationMinutes} menit',
                        ),
                        right: _CompactInfo(
                          icon: Icons.image_rounded,
                          label: 'Foto Edit',
                          value: '${booking.package?.photoCount ?? 0} foto',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoGridRow(
                        left: _CompactInfo(
                          icon: Icons.location_on_rounded,
                          label: 'Tipe Lokasi',
                          value: _safe(
                            booking.package?.locationTypeLabel ??
                                booking.locationTypeLabel,
                          ),
                        ),
                        right: _CompactInfo(
                          icon: Icons.place_rounded,
                          label: 'Lokasi',
                          value: _safe(booking.locationName),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  const _SectionTitle(
                    title: 'Informasi Klien',
                    subtitle: 'Data klien yang harus dilayani.',
                  ),

                  const SizedBox(height: 12),

                  _InfoCard(
                    children: [
                      _InfoGridRow(
                        left: _CompactInfo(
                          icon: Icons.person_rounded,
                          label: 'Nama Klien',
                          value: _safe(booking.clientName, fallback: 'Klien'),
                        ),
                        right: _CompactInfo(
                          icon: Icons.phone_rounded,
                          label: 'Nomor HP',
                          value: _safe(booking.clientPhone),
                        ),
                      ),
                      if (booking.clientUser != null) ...[
                        const SizedBox(height: 12),
                        _WideInfo(
                          icon: Icons.email_rounded,
                          label: 'Email',
                          value: _safe(booking.clientUser!.email),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 18),

                  const _SectionTitle(
                    title: 'Catatan & Moodboard',
                    subtitle:
                        'Referensi pose, konsep, dan arahan visual dari klien.',
                  ),

                  const SizedBox(height: 12),

                  _InfoCard(
                    children: [
                      _WideInfo(
                        icon: Icons.notes_rounded,
                        label: 'Catatan Klien',
                        value: _safe(booking.notes),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (booking.moodboards.isEmpty)
                    const _EmptyMoodboardCard()
                  else
                    _MoodboardGalleryGrid(
                      moodboards: booking.moodboards,
                      normalizeUrl: _moodboardUrl,
                      onTap: (index) {
                        _openMoodboardViewer(
                          moodboards: booking.moodboards,
                          initialIndex: index,
                        );
                      },
                    ),

                  const SizedBox(height: 18),

                  const _SectionTitle(
                    title: 'Link Hasil Foto',
                    subtitle: 'Upload link Google Drive setelah pemotretan.',
                  ),

                  const SizedBox(height: 12),

                  if (booking.hasPhotoLink)
                    _PhotoLinkCard(
                      booking: booking,
                      onOpen: () => _openUrl(booking.photoLink!.driveUrl),
                      onEdit: () => _openPhotoLinkForm(booking),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _openPhotoLinkForm(booking),
                        icon: const Icon(Icons.cloud_upload_rounded),
                        label: const Text('Input Link Google Drive'),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: _DetailPalette.darkBlue,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailPalette {
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

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _TopBar({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: _DetailPalette.darkBlue,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.dark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailHero extends StatelessWidget {
  final PhotographerBookingModel booking;
  final String timeText;

  const _DetailHero({required this.booking, required this.timeText});

  @override
  Widget build(BuildContext context) {
    final clientName = booking.clientName.trim().isEmpty
        ? 'Klien'
        : booking.clientName.trim();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: _DetailPalette.darkGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _DetailPalette.darkBlue.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -40,
            child: Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.11),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 34,
            bottom: -48,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(color: Colors.white.withOpacity(0.20)),
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    color: Colors.white,
                    size: 31,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        booking.packageName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.74),
                          fontSize: 12.8,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _HeroPill(
                            icon: Icons.schedule_rounded,
                            label: timeText,
                          ),
                          _HeroPill(
                            icon: Icons.verified_rounded,
                            label: booking.statusLabel,
                          ),
                        ],
                      ),
                    ],
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

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            label.trim().isEmpty ? '-' : label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final PhotographerBookingModel booking;

  const _StatusBanner({required this.booking});

  @override
  Widget build(BuildContext context) {
    final hasPhotoLink = booking.hasPhotoLink;
    final color = hasPhotoLink ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Icon(
            hasPhotoLink
                ? Icons.check_circle_outline_rounded
                : Icons.cloud_upload_outlined,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasPhotoLink
                  ? 'Foto sudah diupload. Klien dapat melihat link hasil foto.'
                  : 'Setelah pemotretan selesai, upload foto ke Google Drive lalu input link di sini.',
              style: TextStyle(
                color: color,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 38,
          width: 5,
          decoration: BoxDecoration(
            gradient: _DetailPalette.darkGradient,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.dark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _DetailPalette.cardDeep),
        boxShadow: [
          BoxShadow(
            color: _DetailPalette.darkBlue.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoGridRow extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _InfoGridRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 10),
        Expanded(child: right),
      ],
    );
  }
}

class _CompactInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CompactInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final display = value.trim().isEmpty ? '-' : value.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        gradient: _DetailPalette.softGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.78)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _DetailPalette.darkBlue, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _DetailPalette.darkBlue.withOpacity(0.54),
                    fontSize: 10,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  display,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _DetailPalette.darkBlue,
                    fontSize: 12,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
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

class _WideInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WideInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final display = value.trim().isEmpty ? '-' : value.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        gradient: _DetailPalette.softGradient,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withOpacity(0.78)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _DetailPalette.darkBlue, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: _DetailPalette.darkBlue.withOpacity(0.54),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  display,
                  style: const TextStyle(
                    color: _DetailPalette.darkBlue,
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w900,
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

class _MoodboardGalleryGrid extends StatelessWidget {
  final List<PhotographerMoodboardModel> moodboards;
  final String Function(PhotographerMoodboardModel moodboard) normalizeUrl;
  final ValueChanged<int> onTap;

  const _MoodboardGalleryGrid({
    required this.moodboards,
    required this.normalizeUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: moodboards.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.88,
      ),
      itemBuilder: (context, index) {
        final moodboard = moodboards[index];
        final url = normalizeUrl(moodboard);

        return _MoodboardThumbnailCard(
          title: moodboard.originalName.trim().isEmpty
              ? 'Moodboard ${index + 1}'
              : moodboard.originalName,
          url: url,
          index: index,
          onTap: () => onTap(index),
        );
      },
    );
  }
}

class _MoodboardThumbnailCard extends StatelessWidget {
  final String title;
  final String url;
  final int index;
  final VoidCallback onTap;

  const _MoodboardThumbnailCard({
    required this.title,
    required this.url,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _DetailPalette.cardDeep),
            boxShadow: [
              BoxShadow(
                color: _DetailPalette.darkBlue.withOpacity(0.055),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: url.trim().isEmpty
                    ? const _MoodboardImageFallback()
                    : Image.network(
                        url,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;

                          return const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _DetailPalette.darkBlue,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const _MoodboardImageFallback();
                        },
                      ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.62),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  height: 29,
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.86),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.image_rounded,
                        color: _DetailPalette.darkBlue,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '#${index + 1}',
                        style: const TextStyle(
                          color: _DetailPalette.darkBlue,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                right: 10,
                top: 10,
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.zoom_in_rounded,
                    color: _DetailPalette.darkBlue,
                    size: 18,
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodboardImageFallback extends StatelessWidget {
  const _MoodboardImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: _DetailPalette.softGradient),
      child: const Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: _DetailPalette.darkBlue,
          size: 36,
        ),
      ),
    );
  }
}

class _EmptyMoodboardCard extends StatelessWidget {
  const _EmptyMoodboardCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
      decoration: BoxDecoration(
        gradient: _DetailPalette.softGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.78)),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.62),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.image_not_supported_rounded,
              size: 34,
              color: _DetailPalette.darkBlue,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Tidak ada moodboard',
            style: TextStyle(
              color: _DetailPalette.darkBlue,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Klien tidak mengupload referensi moodboard untuk booking ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _DetailPalette.darkBlue.withOpacity(0.62),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodboardPreviewItem {
  final String title;
  final String url;

  const _MoodboardPreviewItem({required this.title, required this.url});
}

class _MoodboardFullScreenViewer extends StatefulWidget {
  final List<_MoodboardPreviewItem> items;
  final int initialIndex;

  const _MoodboardFullScreenViewer({
    required this.items,
    required this.initialIndex,
  });

  @override
  State<_MoodboardFullScreenViewer> createState() =>
      _MoodboardFullScreenViewerState();
}

class _MoodboardFullScreenViewerState
    extends State<_MoodboardFullScreenViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _jump(int offset) {
    final next = _currentIndex + offset;

    if (next < 0 || next >= widget.items.length) return;

    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.items[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.items.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final item = widget.items[index];

                return Center(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Image.network(
                      item.url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;

                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const _FullScreenImageError();
                      },
                    ),
                  ),
                );
              },
            ),

            Positioned(
              left: 14,
              right: 14,
              top: 12,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.48),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        current.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_currentIndex + 1}/${widget.items.length}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.white.withOpacity(0.16),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.pop(context),
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(Icons.close_rounded, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (widget.items.length > 1) ...[
              Positioned(
                left: 14,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _ViewerArrowButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: _currentIndex == 0 ? null : () => _jump(-1),
                  ),
                ),
              ),
              Positioned(
                right: 14,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _ViewerArrowButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: _currentIndex == widget.items.length - 1
                        ? null
                        : () => _jump(1),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ViewerArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ViewerArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Opacity(
      opacity: enabled ? 1 : 0.32,
      child: Material(
        color: Colors.black.withOpacity(0.42),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}

class _FullScreenImageError extends StatelessWidget {
  const _FullScreenImageError();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.broken_image_rounded, color: Colors.white, size: 54),
        const SizedBox(height: 12),
        Text(
          'Moodboard tidak bisa ditampilkan.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.82),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PhotoLinkCard extends StatelessWidget {
  final PhotographerBookingModel booking;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  const _PhotoLinkCard({
    required this.booking,
    required this.onOpen,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final photoLink = booking.photoLink!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _DetailPalette.cardDeep),
        boxShadow: [
          BoxShadow(
            color: _DetailPalette.darkBlue.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.14),
                  ),
                ),
                child: const Icon(
                  Icons.cloud_done_rounded,
                  color: AppColors.success,
                  size: 23,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      photoLink.driveLabel.trim().isEmpty
                          ? 'Hasil Foto'
                          : photoLink.driveLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _DetailPalette.darkBlue,
                        fontSize: 15.5,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      photoLink.driveUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _DetailPalette.darkBlue.withOpacity(0.56),
                        fontSize: 11.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (photoLink.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _WideInfo(
              icon: Icons.notes_rounded,
              label: 'Catatan Link',
              value: photoLink.notes,
            ),
          ],
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Buka Link'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _DetailPalette.darkBlue,
                    side: const BorderSide(color: _DetailPalette.cardDeep),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Edit Link'),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: _DetailPalette.darkBlue,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 120),
      child: Center(
        child: CircularProgressIndicator(color: _DetailPalette.darkBlue),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 90),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.danger.withOpacity(0.14)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.danger,
            ),
            const SizedBox(height: 12),
            const Text(
              'Data gagal dimuat',
              style: TextStyle(
                color: AppColors.danger,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.danger,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: BorderSide(color: AppColors.danger.withOpacity(0.22)),
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
