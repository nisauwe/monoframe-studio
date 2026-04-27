import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/booking_model.dart';
import '../../../data/providers/payment_provider.dart';

class BookingPaymentScreen extends StatelessWidget {
  final BookingModel booking;

  const BookingPaymentScreen({super.key, required this.booking});

  String formatCurrency(int value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  Future<void> createAndOpenPayment({
    required BuildContext context,
    required String mode,
  }) async {
    if (booking.id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID booking tidak valid. Silakan cek riwayat booking.'),
        ),
      );
      return;
    }

    final provider = context.read<PaymentProvider>();

    final snap = await provider.createPayment(
      bookingId: booking.id,
      mode: mode,
    );

    if (!context.mounted) return;

    if (snap == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal membuat pembayaran'),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(snap.redirectUrl);

    if (uri == null || snap.redirectUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL pembayaran tidak valid')),
      );
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!context.mounted) return;

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka halaman pembayaran')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran Booking')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.payments_outlined, size: 72),
            const SizedBox(height: 16),

            const Text(
              'Booking berhasil dibuat',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Silakan lakukan pembayaran terlebih dahulu. Setelah pembayaran berhasil, Front Office dapat memilih fotografer untuk booking kamu.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.5),
            ),

            const SizedBox(height: 24),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('ID Booking'),
                    subtitle: Text('#${booking.id}'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: const Text('Tanggal Booking'),
                    subtitle: Text(
                      booking.bookingDate.isEmpty ? '-' : booking.bookingDate,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.schedule_outlined),
                    title: const Text('Jam Booking'),
                    subtitle: Text(
                      booking.startTime.isEmpty
                          ? '-'
                          : '${booking.startTime} - ${booking.endTime}',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_camera_outlined),
                    title: const Text('Paket'),
                    subtitle: Text(booking.packageName),
                  ),
                  if (booking.extraDurationMinutes > 0)
                    ListTile(
                      leading: const Icon(Icons.timer_outlined),
                      title: const Text('Extra Duration'),
                      subtitle: Text(
                        '${booking.extraDurationMinutes} menit - ${formatCurrency(booking.extraDurationFee)}',
                      ),
                    ),
                  if (booking.videoAddonName != null &&
                      booking.videoAddonName!.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.videocam_outlined),
                      title: const Text('Add-on Video'),
                      subtitle: Text(
                        '${booking.videoAddonName} - ${formatCurrency(booking.videoAddonPrice)}',
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: const Text(
                'Pembayaran DP minimal 50% diperlukan agar booking bisa diproses Front Office.',
                style: TextStyle(height: 1.5),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: paymentProvider.isLoading || booking.id <= 0
                  ? null
                  : () {
                      createAndOpenPayment(context: context, mode: 'dp');
                    },
              child: paymentProvider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Bayar DP 50%'),
            ),

            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: paymentProvider.isLoading || booking.id <= 0
                  ? null
                  : () {
                      createAndOpenPayment(context: context, mode: 'full');
                    },
              child: const Text('Bayar Lunas'),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: paymentProvider.isCheckingStatus || booking.id <= 0
                  ? null
                  : () async {
                      final ok = await context
                          .read<PaymentProvider>()
                          .checkPaymentStatus(bookingId: booking.id);

                      if (!context.mounted) return;

                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Status pembayaran berhasil diperbarui',
                            ),
                          ),
                        );

                        Navigator.popUntil(context, (route) => route.isFirst);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.read<PaymentProvider>().errorMessage ??
                                  'Pembayaran belum terkonfirmasi',
                            ),
                          ),
                        );
                      }
                    },
              icon: paymentProvider.isCheckingStatus
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Saya Sudah Bayar / Cek Status'),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('Bayar Nanti'),
            ),
          ],
        ),
      ),
    );
  }
}
