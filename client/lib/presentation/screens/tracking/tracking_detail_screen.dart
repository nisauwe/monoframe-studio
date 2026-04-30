import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/tracking_model.dart';
import '../../../data/providers/payment_provider.dart';
import '../../../data/providers/tracking_provider.dart';
import '../edit_request/edit_request_section.dart';
import '../print/print_tracking_section.dart';
import '../review/client_review_section.dart';

class TrackingDetailScreen extends StatefulWidget {
  final int bookingId;

  const TrackingDetailScreen({super.key, required this.bookingId});

  @override
  State<TrackingDetailScreen> createState() => _TrackingDetailScreenState();
}

class _TrackingDetailScreenState extends State<TrackingDetailScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshTracking();
    });
  }

  String formatCurrency(int value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  Future<void> openExternalUrl(String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('URL tidak valid')));
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!mounted) return;

    if (!opened) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tidak bisa membuka URL')));
    }
  }

  Future<void> payRemaining() async {
    final paymentProvider = context.read<PaymentProvider>();

    final snap = await paymentProvider.createPayment(
      bookingId: widget.bookingId,
      mode: 'full',
    );

    if (!mounted) return;

    if (snap == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            paymentProvider.errorMessage ?? 'Gagal membuat pelunasan',
          ),
        ),
      );
      return;
    }

    await openExternalUrl(snap.redirectUrl);
  }

  Future<void> checkPaymentStatus() async {
    final paymentProvider = context.read<PaymentProvider>();

    final ok = await paymentProvider.checkPaymentStatus(
      bookingId: widget.bookingId,
    );

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            paymentProvider.errorMessage ?? 'Pembayaran belum terkonfirmasi',
          ),
        ),
      );
      return;
    }

    await refreshTracking();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Status pembayaran berhasil diperbarui')),
    );
  }

  Future<void> refreshTracking() async {
    await context.read<TrackingProvider>().fetchTrackingDetail(
      bookingId: widget.bookingId,
    );
  }

  Color timelineColor(TrackingTimelineModel item) {
    if (item.isDone) return AppColors.success;
    if (item.isCurrent) return _TrackingDetailPalette.midBlue;
    if (item.isSkipped) return AppColors.grey;
    return AppColors.grey.withValues(alpha: 0.72);
  }

  IconData timelineIcon(TrackingTimelineModel item) {
    if (item.isDone) return Icons.check_circle_rounded;
    if (item.isCurrent) return Icons.radio_button_checked_rounded;
    if (item.isSkipped) return Icons.remove_circle_outline_rounded;
    return Icons.radio_button_unchecked_rounded;
  }

  String _stageText(TrackingTimelineModel item) {
    return '${item.stageKey} ${item.stageName}'.toLowerCase();
  }

  bool _isPhotoUploadStage(TrackingTimelineModel item) {
    final text = _stageText(item);

    final containsPhoto =
        text.contains('photo') ||
        text.contains('foto') ||
        text.contains('gallery') ||
        text.contains('galeri');

    final containsUpload =
        text.contains('upload') ||
        text.contains('link') ||
        text.contains('hasil');

    final isOtherStage =
        text.contains('edit') ||
        text.contains('print') ||
        text.contains('cetak') ||
        text.contains('review') ||
        text.contains('ulas');

    return containsPhoto && containsUpload && !isOtherStage;
  }

  bool _isEditStage(TrackingTimelineModel item) {
    final text = _stageText(item);
    return text.contains('edit') ||
        text.contains('editing') ||
        text.contains('revisi');
  }

  bool _isPrintStage(TrackingTimelineModel item) {
    final text = _stageText(item);
    return text.contains('print') || text.contains('cetak');
  }

  bool _isReviewStage(TrackingTimelineModel item) {
    final text = _stageText(item);
    return text.contains('review') || text.contains('ulas');
  }

  List<Widget> _timelineExtraContent({
    required TrackingTimelineModel item,
    required TrackingBookingModel booking,
    required PaymentProvider paymentProvider,
  }) {
    final children = <Widget>[];

    if (item.stageKey == 'full_payment' && booking.canPayRemaining) {
      children.add(
        _RemainingPaymentTimelineContent(
          remainingAmount: booking.remainingBookingAmount,
          formatCurrency: formatCurrency,
          isPayLoading: paymentProvider.isLoading,
          isCheckLoading: paymentProvider.isCheckingStatus,
          onPay: payRemaining,
          onCheckStatus: checkPaymentStatus,
        ),
      );
    }

    if (_isPhotoUploadStage(item)) {
      children.add(
        _PhotoLinkTimelineContent(booking: booking, onOpen: openExternalUrl),
      );
    }

    if (_isEditStage(item)) {
      children.add(
        EditRequestSection(
          bookingId: booking.id,
          maxPhotoCount: booking.maxPhotoEdit,
          hasPhotoLink: booking.hasPhotoLink,
          canOpenPhotoLink: booking.canOpenPhotoLink,
        ),
      );
    }

    if (_isPrintStage(item)) {
      children.add(
        PrintTrackingSection(bookingId: booking.id, canPrint: booking.canPrint),
      );
    }

    if (_isReviewStage(item)) {
      children.add(
        ClientReviewSection(
          bookingId: booking.id,
          canReview: booking.canReview,
          initialReview: booking.review,
          onReviewSubmitted: refreshTracking,
        ),
      );
    }

    return children;
  }

  @override
  Widget build(BuildContext context) {
    final trackingProvider = context.watch<TrackingProvider>();
    final paymentProvider = context.watch<PaymentProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: _TrackingDetailPalette.darkBlue,
        centerTitle: true,
        title: const Text(
          'Detail Tracking',
          style: TextStyle(
            color: _TrackingDetailPalette.darkBlue,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _TrackingDetailPalette.darkBlue,
          backgroundColor: _TrackingDetailPalette.cardLight,
          onRefresh: refreshTracking,
          child: Builder(
            builder: (context) {
              if (trackingProvider.isLoading) {
                return ListView(
                  children: const [
                    SizedBox(height: 180),
                    Center(
                      child: CircularProgressIndicator(
                        color: _TrackingDetailPalette.darkBlue,
                      ),
                    ),
                  ],
                );
              }

              if (trackingProvider.errorMessage != null) {
                return _ErrorTrackingView(
                  message: trackingProvider.errorMessage!,
                  onRetry: refreshTracking,
                );
              }

              final detail = trackingProvider.detail;

              if (detail == null) {
                return const _EmptyTrackingDetailView();
              }

              final booking = detail.booking;

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
                children: [
                  _BookingSummaryCard(
                    booking: booking,
                    formatCurrency: formatCurrency,
                  ),

                  const SizedBox(height: 14),

                  _PhotographerCard(booking: booking),

                  if (booking.paymentWarning != null &&
                      booking.paymentWarning!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _WarningCard(text: booking.paymentWarning!),
                  ],

                  const SizedBox(height: 22),

                  const _SectionTitle(
                    icon: Icons.timeline_rounded,
                    title: 'Timeline Progress',
                  ),

                  const SizedBox(height: 14),

                  ...List.generate(detail.timeline.length, (index) {
                    final item = detail.timeline[index];
                    final color = timelineColor(item);
                    final isLast = index == detail.timeline.length - 1;
                    final extraWidgets = _timelineExtraContent(
                      item: item,
                      booking: booking,
                      paymentProvider: paymentProvider,
                    );

                    return _TimelineItemCard(
                      item: item,
                      color: color,
                      icon: timelineIcon(item),
                      isLast: isLast,
                      description: item.description?.isNotEmpty == true
                          ? item.description!
                          : _defaultDescription(item),
                      extraChildren: extraWidgets,
                    );
                  }),

                  const SizedBox(height: 30),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _defaultDescription(TrackingTimelineModel item) {
    if (item.isDone) return 'Tahap ini sudah selesai.';
    if (item.isCurrent) return 'Tahap ini sedang diproses.';
    if (item.isSkipped) return 'Tahap ini dilewati.';

    return 'Menunggu tahap sebelumnya selesai.';
  }
}

class _TrackingDetailPalette {
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

class _BookingSummaryCard extends StatelessWidget {
  final TrackingBookingModel booking;
  final String Function(int value) formatCurrency;

  const _BookingSummaryCard({
    required this.booking,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: _TrackingDetailPalette.darkGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _TrackingDetailPalette.darkBlue.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: -42,
            child: Container(
              width: 142,
              height: 142,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paket Booking',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                booking.packageName.isEmpty
                    ? 'Paket Foto'
                    : booking.packageName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _HeroInfoChip(
                      icon: Icons.calendar_month_rounded,
                      label: 'Tanggal',
                      value: booking.formattedBookingDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeroInfoChip(
                      icon: Icons.schedule_rounded,
                      label: 'Jam',
                      value:
                          '${booking.formattedStartTime} - ${booking.formattedEndTime}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _HeroInfoChip(
                icon: Icons.location_on_rounded,
                label: 'Lokasi',
                value: booking.locationName.isEmpty
                    ? '-'
                    : booking.locationName,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _AmountInfo(
                      label: 'Total',
                      value: formatCurrency(booking.totalBookingAmount),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AmountInfo(
                      label: 'Sisa',
                      value: formatCurrency(booking.remainingBookingAmount),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroInfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 17),
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
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? '-' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
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

class _AmountInfo extends StatelessWidget {
  final String label;
  final String value;

  const _AmountInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _TrackingDetailPalette.darkBlue.withValues(alpha: 0.58),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _TrackingDetailPalette.darkBlue,
              fontSize: 13.4,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotographerCard extends StatelessWidget {
  final TrackingBookingModel booking;

  const _PhotographerCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    if (!booking.hasPhotographerAssigned) {
      return const _InfoCard(
        title: 'Fotografer',
        icon: Icons.photo_camera_outlined,
        children: [
          Text(
            'Menunggu Front Office memilih fotografer untuk booking ini.',
            style: TextStyle(
              color: AppColors.grey,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return _InfoCard(
      title: 'Fotografer',
      icon: Icons.photo_camera_outlined,
      children: [
        _InfoText(label: 'Nama', value: booking.photographerName ?? '-'),
        _InfoText(label: 'Email', value: booking.photographerEmail ?? '-'),
        _InfoText(label: 'No. HP', value: booking.photographerPhone ?? '-'),
      ],
    );
  }
}

class _WarningCard extends StatelessWidget {
  final String text;

  const _WarningCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.warning,
            size: 21,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF9A3412),
                height: 1.45,
                fontSize: 12.4,
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
            gradient: _TrackingDetailPalette.softGradient,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.white),
          ),
          child: Icon(icon, color: _TrackingDetailPalette.darkBlue, size: 16),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            color: _TrackingDetailPalette.darkBlue,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _TimelineItemCard extends StatelessWidget {
  final TrackingTimelineModel item;
  final Color color;
  final IconData icon;
  final bool isLast;
  final String description;
  final List<Widget> extraChildren;

  const _TimelineItemCard({
    required this.item,
    required this.color,
    required this.icon,
    required this.isLast,
    required this.description,
    required this.extraChildren,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.24)),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: _TrackingDetailPalette.cardDeep,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: item.isCurrent
                        ? color.withValues(alpha: 0.30)
                        : _TrackingDetailPalette.cardDeep,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _TrackingDetailPalette.darkBlue.withValues(
                        alpha: item.isCurrent ? 0.08 : 0.045,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.stageName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontSize: 15.2,
                              height: 1.18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (item.isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Aktif',
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      description,
                      style: TextStyle(
                        color: _TrackingDetailPalette.darkBlue.withValues(
                          alpha: 0.68,
                        ),
                        height: 1.45,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.occurredAt != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: _TrackingDetailPalette.darkBlue.withValues(
                              alpha: 0.46,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              item.formattedOccurredAt,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _TrackingDetailPalette.darkBlue
                                    .withValues(alpha: 0.46),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (extraChildren.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...extraChildren.map(
                        (child) => Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: child,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RemainingPaymentTimelineContent extends StatelessWidget {
  final int remainingAmount;
  final String Function(int value) formatCurrency;
  final bool isPayLoading;
  final bool isCheckLoading;
  final VoidCallback onPay;
  final VoidCallback onCheckStatus;

  const _RemainingPaymentTimelineContent({
    required this.remainingAmount,
    required this.formatCurrency,
    required this.isPayLoading,
    required this.isCheckLoading,
    required this.onPay,
    required this.onCheckStatus,
  });

  @override
  Widget build(BuildContext context) {
    return _TimelineInnerBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tagihan Pelunasan',
            style: TextStyle(
              color: _TrackingDetailPalette.darkBlue,
              fontSize: 13.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Sisa pembayaran: ${formatCurrency(remainingAmount)}',
            style: TextStyle(
              color: _TrackingDetailPalette.darkBlue.withValues(alpha: 0.66),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: isPayLoading ? null : onPay,
              icon: isPayLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.payments_rounded, size: 18),
              label: const Text('Bayar Pelunasan'),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _TrackingDetailPalette.darkBlue,
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
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: isCheckLoading ? null : onCheckStatus,
              icon: isCheckLoading
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Saya Sudah Bayar / Cek Status'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _TrackingDetailPalette.darkBlue,
                side: const BorderSide(color: _TrackingDetailPalette.cardDeep),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoLinkTimelineContent extends StatelessWidget {
  final TrackingBookingModel booking;
  final Future<void> Function(String url) onOpen;

  const _PhotoLinkTimelineContent({
    required this.booking,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final hasLink = booking.hasPhotoLink;
    final canOpen = booking.canOpenPhotoLink && booking.photoDriveUrl != null;

    return _TimelineInnerBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasLink ? 'Link foto sudah tersedia.' : 'Link foto belum tersedia.',
            style: const TextStyle(
              color: _TrackingDetailPalette.darkBlue,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasLink
                ? canOpen
                      ? 'Klik tombol di bawah untuk membuka hasil foto.'
                      : 'Link foto tersedia, tapi baru bisa dibuka setelah pembayaran lunas.'
                : 'Link hasil foto akan muncul setelah fotografer mengupload hasil foto.',
            style: TextStyle(
              color: _TrackingDetailPalette.darkBlue.withValues(alpha: 0.64),
              fontSize: 12,
              height: 1.42,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (hasLink) ...[
            const SizedBox(height: 11),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: canOpen
                    ? () => onOpen(booking.photoDriveUrl!)
                    : null,
                icon: const Icon(Icons.open_in_new_rounded, size: 17),
                label: const Text('Buka Link Foto'),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _TrackingDetailPalette.darkBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _TrackingDetailPalette.darkBlue
                      .withValues(alpha: 0.38),
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineInnerBox extends StatelessWidget {
  final Widget child;

  const _TimelineInnerBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        gradient: _TrackingDetailPalette.softGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
      ),
      child: child,
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: _TrackingDetailPalette.cardDeep),
        boxShadow: [
          BoxShadow(
            color: _TrackingDetailPalette.darkBlue.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  gradient: _TrackingDetailPalette.softGradient,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: _TrackingDetailPalette.darkBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  color: _TrackingDetailPalette.darkBlue,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoText extends StatelessWidget {
  final String label;
  final String value;

  const _InfoText({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: TextStyle(
                color: _TrackingDetailPalette.darkBlue.withValues(alpha: 0.54),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: _TrackingDetailPalette.darkBlue,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorTrackingView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorTrackingView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 120),
        Container(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
          decoration: BoxDecoration(
            gradient: _TrackingDetailPalette.softGradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 58,
                color: AppColors.danger,
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.danger,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _TrackingDetailPalette.darkBlue,
                  side: const BorderSide(
                    color: _TrackingDetailPalette.cardDeep,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyTrackingDetailView extends StatelessWidget {
  const _EmptyTrackingDetailView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 180),
        Center(
          child: Text(
            'Data tracking tidak ditemukan',
            style: TextStyle(
              color: _TrackingDetailPalette.darkBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
