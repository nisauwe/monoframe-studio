import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/providers/booking_provider.dart';
import '../payment/booking_payment_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchBookings();
    });
  }

  String formatCurrency(int value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  Color paymentColor(BookingModel booking) {
    if (booking.isPaid) return AppColors.success;
    if (booking.isPaymentPending) return _HistoryPalette.midBlue;
    if (booking.isPaymentFailed) return AppColors.danger;
    return AppColors.warning;
  }

  IconData paymentIcon(BookingModel booking) {
    if (booking.isPaid) return Icons.check_circle_rounded;
    if (booking.isPaymentPending) return Icons.hourglass_top_rounded;
    if (booking.isPaymentFailed) return Icons.cancel_rounded;
    return Icons.payment_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();

    return SafeArea(
      child: Container(
        color: AppColors.background,
        child: RefreshIndicator(
          color: _HistoryPalette.darkBlue,
          backgroundColor: _HistoryPalette.cardLight,
          onRefresh: provider.fetchBookings,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 118),
            children: [
              const _HistoryHeader(),

              const SizedBox(height: 18),

              if (provider.isLoadingBookings)
                const Padding(
                  padding: EdgeInsets.only(top: 90),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _HistoryPalette.darkBlue,
                    ),
                  ),
                )
              else if (provider.bookings.isEmpty)
                _EmptyBookingHistory(
                  message:
                      provider.errorMessage ??
                      'Booking yang kamu buat akan tampil di sini.',
                  onRefresh: () {
                    context.read<BookingProvider>().fetchBookings();
                  },
                )
              else
                ...provider.bookings.map((booking) {
                  final color = paymentColor(booking);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BookingHistoryCard(
                      booking: booking,
                      statusColor: color,
                      statusIcon: paymentIcon(booking),
                      formatCurrency: formatCurrency,
                      onContinuePayment: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BookingPaymentScreen(booking: booking),
                          ),
                        );

                        if (!mounted) return;
                        context.read<BookingProvider>().fetchBookings();
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

class _HistoryPalette {
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

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: _HistoryPalette.darkGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _HistoryPalette.darkBlue.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -32,
            top: -34,
            child: Container(
              width: 118,
              height: 118,
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
                      'Riwayat Booking',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Pantau status booking dan pembayaran kamu di sini.',
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
        Icons.receipt_long_rounded,
        color: Colors.white,
        size: 29,
      ),
    );
  }
}

class _BookingHistoryCard extends StatelessWidget {
  final BookingModel booking;
  final Color statusColor;
  final IconData statusIcon;
  final String Function(int) formatCurrency;
  final VoidCallback onContinuePayment;

  const _BookingHistoryCard({
    required this.booking,
    required this.statusColor,
    required this.statusIcon,
    required this.formatCurrency,
    required this.onContinuePayment,
  });

  @override
  Widget build(BuildContext context) {
    final total = booking.totalEstimatedAmount;
    final location = booking.locationName.trim().isEmpty
        ? '-'
        : booking.locationName.trim();

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _HistoryPalette.cardDeep),
        boxShadow: [
          BoxShadow(
            color: _HistoryPalette.darkBlue.withValues(alpha: 0.05),
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
              _StatusIconBox(icon: statusIcon, color: statusColor),
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
                        color: _HistoryPalette.darkBlue,
                        fontSize: 17,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      booking.bookingDate.isEmpty
                          ? '-'
                          : '${booking.bookingDate} • ${booking.startTime}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _HistoryPalette.darkBlue.withValues(alpha: 0.58),
                        fontSize: 11.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                formatCurrency(total),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _HistoryPalette.darkBlue,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
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
                  label: booking.bookingStatusLabel,
                  color: _HistoryPalette.darkBlue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
            decoration: BoxDecoration(
              gradient: _HistoryPalette.softGradient,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: Colors.white.withValues(alpha: 0.76)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _CompactInfo(
                        icon: Icons.schedule_rounded,
                        label: 'Jam',
                        value: booking.startTime.isEmpty
                            ? '-'
                            : '${booking.startTime} - ${booking.endTime}',
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

          if (booking.canContinuePayment) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: onContinuePayment,
                icon: const Icon(Icons.payments_rounded, size: 18),
                label: Text(
                  booking.isPaymentPending
                      ? 'Cek / Lanjut Pembayaran'
                      : 'Lanjut Pembayaran',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _HistoryPalette.darkBlue,
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
          ] else if (booking.isPaid) ...[
            const SizedBox(height: 12),
            const _MessageBox(
              color: AppColors.success,
              icon: Icons.check_circle_outline_rounded,
              text:
                  'Pembayaran sudah diterima. Booking akan diproses Front Office.',
            ),
          ] else if (booking.isPaymentFailed) ...[
            const SizedBox(height: 12),
            const _MessageBox(
              color: AppColors.danger,
              icon: Icons.error_outline_rounded,
              text:
                  'Pembayaran gagal atau expired. Silakan buat pembayaran ulang.',
            ),
          ],
        ],
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
        label,
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
        Icon(icon, color: _HistoryPalette.darkBlue, size: 16),
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
                  color: _HistoryPalette.darkBlue.withValues(alpha: 0.54),
                  fontSize: 9.8,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _HistoryPalette.darkBlue,
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

class _MessageBox extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _MessageBox({
    required this.color,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
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

class _EmptyBookingHistory extends StatelessWidget {
  final String message;
  final VoidCallback onRefresh;

  const _EmptyBookingHistory({required this.message, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 70),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
        decoration: BoxDecoration(
          gradient: _HistoryPalette.softGradient,
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
                Icons.receipt_long_outlined,
                size: 34,
                color: _HistoryPalette.darkBlue,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada riwayat booking',
              style: TextStyle(
                color: _HistoryPalette.darkBlue,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _HistoryPalette.darkBlue.withValues(alpha: 0.62),
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
                foregroundColor: _HistoryPalette.darkBlue,
                side: const BorderSide(color: _HistoryPalette.cardDeep),
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
