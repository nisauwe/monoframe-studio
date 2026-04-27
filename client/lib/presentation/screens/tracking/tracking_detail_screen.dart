import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Color timelineColor(TrackingTimelineModel item) {
    if (item.isDone) return Colors.green;
    if (item.isCurrent) return const Color(0xFF6C63FF);
    if (item.isSkipped) return Colors.grey;
    return Colors.grey.shade400;
  }

  IconData timelineIcon(TrackingTimelineModel item) {
    if (item.isDone) return Icons.check_circle;
    if (item.isCurrent) return Icons.radio_button_checked;
    if (item.isSkipped) return Icons.remove_circle_outline;
    return Icons.radio_button_unchecked;
  }

  Future<void> refreshTracking() async {
    await context.read<TrackingProvider>().fetchTrackingDetail(
      bookingId: widget.bookingId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final trackingProvider = context.watch<TrackingProvider>();
    final paymentProvider = context.watch<PaymentProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Tracking')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refreshTracking,
          child: Builder(
            builder: (context) {
              if (trackingProvider.isLoading) {
                return ListView(
                  children: const [
                    SizedBox(height: 180),
                    Center(child: CircularProgressIndicator()),
                  ],
                );
              }

              if (trackingProvider.errorMessage != null) {
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const SizedBox(height: 120),
                    const Icon(
                      Icons.error_outline,
                      size: 70,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      trackingProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: refreshTracking,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                );
              }

              final detail = trackingProvider.detail;

              if (detail == null) {
                return ListView(
                  children: const [
                    SizedBox(height: 180),
                    Center(child: Text('Data tracking tidak ditemukan')),
                  ],
                );
              }

              final booking = detail.booking;

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _BookingSummaryCard(
                    booking: booking,
                    formatCurrency: formatCurrency,
                  ),
                  const SizedBox(height: 14),

                  if (booking.hasPhotographerAssigned)
                    _InfoCard(
                      title: 'Fotografer',
                      icon: Icons.photo_camera_outlined,
                      children: [
                        _InfoText(
                          label: 'Nama',
                          value: booking.photographerName ?? '-',
                        ),
                        _InfoText(
                          label: 'Email',
                          value: booking.photographerEmail ?? '-',
                        ),
                        _InfoText(
                          label: 'No. HP',
                          value: booking.photographerPhone ?? '-',
                        ),
                      ],
                    )
                  else
                    _InfoCard(
                      title: 'Fotografer',
                      icon: Icons.photo_camera_outlined,
                      children: const [
                        Text(
                          'Menunggu Front Office memilih fotografer untuk booking ini.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),

                  if (booking.paymentWarning != null &&
                      booking.paymentWarning!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        booking.paymentWarning!,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  const Text(
                    'Timeline Progress',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 14),

                  ...detail.timeline.map((item) {
                    final color = timelineColor(item);

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Icon(timelineIcon(item), color: color),
                            Container(
                              width: 2,
                              height:
                                  item.stageKey == 'full_payment' &&
                                      booking.canPayRemaining
                                  ? 150
                                  : 70,
                              color: Colors.grey.shade300,
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: color.withOpacity(0.18),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.stageName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.description?.isNotEmpty == true
                                        ? item.description!
                                        : _defaultDescription(item),
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                  ),
                                  if (item.occurredAt != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      item.formattedOccurredAt,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                  if (item.stageKey == 'full_payment' &&
                                      booking.canPayRemaining) ...[
                                    const SizedBox(height: 14),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Tagihan Pelunasan',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Sisa pembayaran: ${formatCurrency(booking.remainingBookingAmount)}',
                                          ),
                                          const SizedBox(height: 10),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed:
                                                  paymentProvider.isLoading
                                                  ? null
                                                  : payRemaining,
                                              child: paymentProvider.isLoading
                                                  ? const SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    )
                                                  : const Text(
                                                      'Bayar Pelunasan Sekarang',
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton.icon(
                                              onPressed:
                                                  paymentProvider
                                                      .isCheckingStatus
                                                  ? null
                                                  : checkPaymentStatus,
                                              icon:
                                                  paymentProvider
                                                      .isCheckingStatus
                                                  ? const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    )
                                                  : const Icon(Icons.refresh),
                                              label: const Text(
                                                'Saya Sudah Bayar / Cek Status',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 10),

                  if (booking.hasPhotoLink)
                    _InfoCard(
                      title: 'Link Foto',
                      icon: Icons.link_outlined,
                      children: [
                        Text(
                          booking.canOpenPhotoLink
                              ? 'Link foto sudah tersedia.'
                              : 'Link foto tersedia, tapi baru bisa dibuka setelah pembayaran lunas.',
                          style: const TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                booking.canOpenPhotoLink &&
                                    booking.photoDriveUrl != null
                                ? () => openExternalUrl(booking.photoDriveUrl!)
                                : null,
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Buka Link Foto'),
                          ),
                        ),
                      ],
                    )
                  else
                    _InfoCard(
                      title: 'Link Foto',
                      icon: Icons.link_outlined,
                      children: const [
                        Text(
                          'Link hasil foto belum tersedia. Link akan muncul setelah fotografer mengupload hasil foto.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),

                  EditRequestSection(
                    bookingId: booking.id,
                    maxPhotoCount: booking.maxPhotoEdit,
                    hasPhotoLink: booking.hasPhotoLink,
                    canOpenPhotoLink: booking.canOpenPhotoLink,
                  ),

                  PrintTrackingSection(
                    bookingId: booking.id,
                    canPrint: booking.canPrint,
                  ),

                  ClientReviewSection(
                    bookingId: booking.id,
                    canReview: booking.canReview,
                    initialReview: booking.review,
                    onReviewSubmitted: () {
                      refreshTracking();
                    },
                  ),

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

class _BookingSummaryCard extends StatelessWidget {
  final TrackingBookingModel booking;
  final String Function(int value) formatCurrency;

  const _BookingSummaryCard({
    required this.booking,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking.packageName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'ID Booking #${booking.id}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 14),
            _InfoText(label: 'Tanggal', value: booking.formattedBookingDate),
            _InfoText(
              label: 'Jam',
              value:
                  '${booking.formattedStartTime} - ${booking.formattedEndTime}',
            ),
            _InfoText(label: 'Lokasi', value: booking.locationName),
            _InfoText(
              label: 'Status Booking',
              value: booking.bookingStatusLabel,
            ),
            _InfoText(
              label: 'Status Pembayaran',
              value: booking.paymentStatusLabel,
            ),
            _InfoText(
              label: 'Total',
              value: formatCurrency(booking.totalBookingAmount),
            ),
            _InfoText(
              label: 'Sudah Dibayar',
              value: formatCurrency(booking.paidBookingAmount),
            ),
            _InfoText(
              label: 'Sisa Pembayaran',
              value: formatCurrency(booking.remainingBookingAmount),
            ),
          ],
        ),
      ),
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
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
            width: 135,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
