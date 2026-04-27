import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
    if (booking.isPaid) return Colors.green;
    if (booking.isPaymentPending) return Colors.blue;
    if (booking.isPaymentFailed) return Colors.red;
    return Colors.orange;
  }

  IconData paymentIcon(BookingModel booking) {
    if (booking.isPaid) return Icons.check_circle_outline;
    if (booking.isPaymentPending) return Icons.hourglass_top_outlined;
    if (booking.isPaymentFailed) return Icons.cancel_outlined;
    return Icons.payment_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: provider.fetchBookings,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Riwayat Booking',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Semua booking kamu akan tampil di sini, baik belum bayar, pending, DP terbayar, lunas, maupun selesai.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            if (provider.isLoadingBookings)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.bookings.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 70,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum ada riwayat booking',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      provider.errorMessage ??
                          'Booking yang kamu buat akan tampil di sini.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        context.read<BookingProvider>().fetchBookings();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Muat Ulang'),
                    ),
                  ],
                ),
              )
            else
              ...provider.bookings.map((booking) {
                final color = paymentColor(booking);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(paymentIcon(booking), color: color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booking.packageName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ID Booking #${booking.id}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _StatusChip(
                                label: booking.paymentStatusLabel,
                                color: color,
                              ),
                              _StatusChip(
                                label: 'Booking ${booking.bookingStatusLabel}',
                                color: Colors.grey,
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          _InfoRow(
                            icon: Icons.calendar_month_outlined,
                            label: 'Tanggal',
                            value: booking.bookingDate.isEmpty
                                ? '-'
                                : booking.bookingDate,
                          ),
                          _InfoRow(
                            icon: Icons.schedule_outlined,
                            label: 'Jam',
                            value: booking.startTime.isEmpty
                                ? '-'
                                : '${booking.startTime} - ${booking.endTime}',
                          ),
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'Lokasi',
                            value: booking.locationName.isEmpty
                                ? '-'
                                : booking.locationName,
                          ),
                          _InfoRow(
                            icon: Icons.payments_outlined,
                            label: 'Total',
                            value: formatCurrency(booking.totalEstimatedAmount),
                          ),

                          if (booking.extraDurationMinutes > 0)
                            _InfoRow(
                              icon: Icons.timer_outlined,
                              label: 'Extra Duration',
                              value:
                                  '${booking.extraDurationMinutes} menit (${formatCurrency(booking.extraDurationFee)})',
                            ),

                          if (booking.videoAddonName != null &&
                              booking.videoAddonName!.isNotEmpty)
                            _InfoRow(
                              icon: Icons.videocam_outlined,
                              label: 'Add-on Video',
                              value:
                                  '${booking.videoAddonName} (${formatCurrency(booking.videoAddonPrice)})',
                            ),

                          const SizedBox(height: 14),

                          if (booking.canContinuePayment)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BookingPaymentScreen(
                                        booking: booking,
                                      ),
                                    ),
                                  );

                                  if (!mounted) return;
                                  context
                                      .read<BookingProvider>()
                                      .fetchBookings();
                                },
                                child: Text(
                                  booking.isPaymentPending
                                      ? 'Cek / Lanjut Pembayaran'
                                      : 'Lanjut Pembayaran',
                                ),
                              ),
                            )
                          else if (booking.isPaid)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Pembayaran sudah diterima. Booking akan diproses Front Office.',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          else if (booking.isPaymentFailed)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Pembayaran gagal atau expired. Silakan buat pembayaran ulang.',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          SizedBox(
            width: 115,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
