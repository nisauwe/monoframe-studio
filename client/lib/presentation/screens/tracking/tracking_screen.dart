import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/providers/booking_provider.dart';
import 'tracking_detail_screen.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchBookings();
    });
  }

  Color statusColor(BookingModel booking) {
    if (booking.isPaid) return AppColors.success;
    if (booking.isPaymentPending) return _TrackingPalette.midBlue;
    if (booking.isPaymentFailed) return AppColors.danger;
    return AppColors.warning;
  }

  IconData statusIcon(BookingModel booking) {
    if (booking.isPaid) return Icons.check_circle_rounded;
    if (booking.isPaymentPending) return Icons.hourglass_top_rounded;
    if (booking.isPaymentFailed) return Icons.cancel_rounded;
    return Icons.track_changes_rounded;
  }

  String trackingStageLabel(BookingModel booking) {
    final status = booking.status.toLowerCase().trim();

    if (status == 'cancelled') return 'Dibatalkan';
    if (status == 'completed') return 'Selesai';

    if (booking.isPaymentFailed) return 'Pembayaran Gagal';

    if (!booking.isPaid) {
      if (booking.isPaymentPending) return 'Menunggu Pembayaran';
      return 'Belum Bayar';
    }

    final currentStageName = booking.currentStageName.trim();

    if (currentStageName.isNotEmpty) {
      return currentStageName;
    }

    final currentStage = booking.currentStage;

    if (currentStage != null) {
      final name = currentStage['stage_name']?.toString().trim();

      if (name != null && name.isNotEmpty) {
        return name;
      }
    }

    final timeline = booking.timeline
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    final current = timeline.where((item) {
      return item['status']?.toString().toLowerCase() == 'current';
    }).toList();

    if (current.isNotEmpty) {
      final name = current.first['stage_name']?.toString().trim();

      if (name != null && name.isNotEmpty) {
        return name;
      }
    }

    if (booking.editRequestStatus != null &&
        booking.editRequestStatus!.trim().isNotEmpty) {
      final editStatus = booking.editRequestStatus!.toLowerCase();

      if (editStatus == 'submitted') return 'Menunggu Assign Editor';
      if (editStatus == 'assigned') return 'Menunggu Dikerjakan Editor';
      if (editStatus == 'in_progress') return 'Sedang Diedit';
      if (editStatus == 'completed') return 'Edit Selesai';
    }

    if (booking.hasPhotoLink) {
      return 'Upload Edit';
    }

    final hasPhotographer =
        booking.photographerUserId != null && booking.photographerUserId != 0;

    if (!hasPhotographer) {
      return 'Assign Fotografer';
    }

    return 'Siap Pemotretan';
  }

  Color trackingStageColor(BookingModel booking) {
    final label = trackingStageLabel(booking).toLowerCase();

    if (label.contains('selesai') ||
        label.contains('review') ||
        label.contains('ulas')) {
      return AppColors.success;
    }

    if (label.contains('gagal') || label.contains('dibatalkan')) {
      return AppColors.danger;
    }

    if (label.contains('bayar')) {
      return AppColors.warning;
    }

    if (label.contains('assign')) {
      return AppColors.warning;
    }

    if (label.contains('foto') ||
        label.contains('pemotretan') ||
        label.contains('upload')) {
      return _TrackingPalette.darkBlue;
    }

    if (label.contains('edit') || label.contains('revisi')) {
      return _TrackingPalette.lightBlue;
    }

    if (label.contains('cetak') || label.contains('print')) {
      return AppColors.warning;
    }

    return _TrackingPalette.darkBlue;
  }

  IconData trackingStageIcon(BookingModel booking) {
    final label = trackingStageLabel(booking).toLowerCase();

    if (label.contains('selesai') ||
        label.contains('review') ||
        label.contains('ulas')) {
      return Icons.check_circle_rounded;
    }

    if (label.contains('gagal') || label.contains('dibatalkan')) {
      return Icons.cancel_rounded;
    }

    if (label.contains('bayar')) {
      return Icons.payments_rounded;
    }

    if (label.contains('assign')) {
      return Icons.assignment_ind_rounded;
    }

    if (label.contains('foto') || label.contains('pemotretan')) {
      return Icons.photo_camera_rounded;
    }

    if (label.contains('upload')) {
      return Icons.cloud_upload_rounded;
    }

    if (label.contains('edit') || label.contains('revisi')) {
      return Icons.auto_fix_high_rounded;
    }

    if (label.contains('cetak') || label.contains('print')) {
      return Icons.print_rounded;
    }

    return Icons.track_changes_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();

    return SafeArea(
      child: Container(
        color: AppColors.background,
        child: RefreshIndicator(
          color: _TrackingPalette.darkBlue,
          backgroundColor: _TrackingPalette.cardLight,
          onRefresh: bookingProvider.fetchBookings,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 118),
            children: [
              const _TrackingHeader(),

              const SizedBox(height: 18),

              if (bookingProvider.isLoadingBookings)
                const Padding(
                  padding: EdgeInsets.only(top: 90),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _TrackingPalette.darkBlue,
                    ),
                  ),
                )
              else if (bookingProvider.bookings.isEmpty)
                _EmptyTrackingState(
                  message:
                      bookingProvider.errorMessage ??
                      'Booking yang kamu buat akan muncul di sini.',
                  onRefresh: () {
                    context.read<BookingProvider>().fetchBookings();
                  },
                )
              else
                ...bookingProvider.bookings.map((booking) {
                  final paymentColor = statusColor(booking);
                  final stageLabel = trackingStageLabel(booking);
                  final stageColor = trackingStageColor(booking);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TrackingBookingCard(
                      booking: booking,
                      statusColor: paymentColor,
                      statusIcon: trackingStageIcon(booking),
                      trackingStageLabel: stageLabel,
                      trackingStageColor: stageColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TrackingDetailScreen(bookingId: booking.id),
                          ),
                        );
                      },
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackingPalette {
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

class _TrackingHeader extends StatelessWidget {
  const _TrackingHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: _TrackingPalette.darkGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _TrackingPalette.darkBlue.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -36,
            child: Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Row(
            children: [
              _HeaderIcon(),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tracking Booking',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Pantau progres pembayaran, pemotretan, editing, cetak, hingga review.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.8,
                        height: 1.35,
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

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: const Icon(
        Icons.track_changes_rounded,
        color: Colors.white,
        size: 29,
      ),
    );
  }
}

class _TrackingBookingCard extends StatelessWidget {
  final BookingModel booking;
  final Color statusColor;
  final IconData statusIcon;
  final String trackingStageLabel;
  final Color trackingStageColor;
  final VoidCallback onTap;

  const _TrackingBookingCard({
    required this.booking,
    required this.statusColor,
    required this.statusIcon,
    required this.trackingStageLabel,
    required this.trackingStageColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final location = booking.locationName.trim().isEmpty
        ? '-'
        : booking.locationName.trim();

    final dateText = booking.bookingDate.trim().isEmpty
        ? '-'
        : booking.bookingDate.trim();

    final timeText = booking.startTime.trim().isEmpty
        ? '-'
        : '${booking.startTime} - ${booking.endTime}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _TrackingPalette.cardDeep),
            boxShadow: [
              BoxShadow(
                color: _TrackingPalette.darkBlue.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusIconBox(icon: statusIcon, color: trackingStageColor),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.packageName.isEmpty
                              ? 'Paket Foto'
                              : booking.packageName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _TrackingPalette.darkBlue,
                            fontSize: 17,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '$dateText • $trackingStageLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _TrackingPalette.darkBlue.withValues(
                              alpha: 0.58,
                            ),
                            fontSize: 11.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: _TrackingPalette.softGradient,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: _TrackingPalette.darkBlue,
                      size: 22,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _StatusChip(
                      label: booking.paymentStatusLabel,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatusChip(
                      label: trackingStageLabel,
                      color: trackingStageColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
                decoration: BoxDecoration(
                  gradient: _TrackingPalette.softGradient,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.76),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _CompactInfo(
                            icon: Icons.schedule_rounded,
                            label: 'Jam',
                            value: timeText,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CompactInfo(
                            icon: Icons.location_on_rounded,
                            label: 'Lokasi',
                            value: location,
                          ),
                        ),
                      ],
                    ),
                    if (booking.extraDurationMinutes > 0 ||
                        (booking.videoAddonName != null &&
                            booking.videoAddonName!.isNotEmpty)) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (booking.extraDurationMinutes > 0)
                            Expanded(
                              child: _CompactInfo(
                                icon: Icons.timer_rounded,
                                label: 'Extra',
                                value: '${booking.extraDurationMinutes} menit',
                              ),
                            ),
                          if (booking.extraDurationMinutes > 0 &&
                              booking.videoAddonName != null &&
                              booking.videoAddonName!.isNotEmpty)
                            const SizedBox(width: 10),
                          if (booking.videoAddonName != null &&
                              booking.videoAddonName!.isNotEmpty)
                            Expanded(
                              child: _CompactInfo(
                                icon: Icons.videocam_rounded,
                                label: 'Add-on',
                                value: booking.videoAddonName!,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              _ProgressPreview(
                booking: booking,
                color: trackingStageColor,
                trackingStageLabel: trackingStageLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _StatusIconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 39,
      height: 39,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      alignment: Alignment.center,
      child: Text(
        label.trim().isEmpty ? '-' : label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
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
    return Row(
      children: [
        Icon(icon, color: _TrackingPalette.darkBlue, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _TrackingPalette.darkBlue.withValues(alpha: 0.54),
                  fontSize: 9.8,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value.trim().isEmpty ? '-' : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _TrackingPalette.darkBlue,
                  fontSize: 11.2,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressPreview extends StatelessWidget {
  final BookingModel booking;
  final Color color;
  final String trackingStageLabel;

  const _ProgressPreview({
    required this.booking,
    required this.color,
    required this.trackingStageLabel,
  });

  bool _stageContains(String text) {
    return trackingStageLabel.toLowerCase().contains(text);
  }

  @override
  Widget build(BuildContext context) {
    final hasPaid = booking.isPaid || booking.isPaymentPending;
    final hasPhotoStage =
        _stageContains('foto') ||
        _stageContains('pemotretan') ||
        _stageContains('selesai');
    final hasEditStage = _stageContains('edit') || _stageContains('selesai');
    final hasReviewStage =
        _stageContains('review') || _stageContains('selesai');

    final steps = [
      _ProgressStep(
        icon: Icons.payments_rounded,
        label: 'Bayar',
        active: hasPaid,
      ),
      _ProgressStep(
        icon: Icons.camera_alt_rounded,
        label: 'Foto',
        active: hasPhotoStage,
      ),
      _ProgressStep(
        icon: Icons.brush_rounded,
        label: 'Edit',
        active: hasEditStage,
      ),
      _ProgressStep(
        icon: Icons.rate_review_rounded,
        label: 'Review',
        active: hasReviewStage,
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _TrackingPalette.cardDeep),
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final item = steps[index];

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: item.active
                              ? color.withValues(alpha: 0.13)
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: item.active
                                ? color.withValues(alpha: 0.26)
                                : _TrackingPalette.cardDeep,
                          ),
                        ),
                        child: Icon(
                          item.icon,
                          color: item.active ? color : AppColors.grey,
                          size: 15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: item.active
                              ? _TrackingPalette.darkBlue
                              : AppColors.grey,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index != steps.length - 1)
                  Container(
                    width: 13,
                    height: 1.5,
                    color: item.active
                        ? color.withValues(alpha: 0.34)
                        : _TrackingPalette.cardDeep,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ProgressStep {
  final IconData icon;
  final String label;
  final bool active;

  const _ProgressStep({
    required this.icon,
    required this.label,
    required this.active,
  });
}

class _EmptyTrackingState extends StatelessWidget {
  final String message;
  final VoidCallback onRefresh;

  const _EmptyTrackingState({required this.message, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 70),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
        decoration: BoxDecoration(
          gradient: _TrackingPalette.softGradient,
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
                Icons.track_changes_outlined,
                size: 35,
                color: _TrackingPalette.darkBlue,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada booking untuk dilacak',
              style: TextStyle(
                color: _TrackingPalette.darkBlue,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _TrackingPalette.darkBlue.withValues(alpha: 0.62),
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
                foregroundColor: _TrackingPalette.darkBlue,
                side: const BorderSide(color: _TrackingPalette.cardDeep),
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
