import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
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

  int get totalAmount => booking.fullAmountForBilling;

  int get dpAmount => booking.dpAmountForBilling;

  int get fullAmount => booking.fullAmountForBilling;

  int get resolvedPackageAmount {
    return booking.packagePriceForBilling;
  }

  int get resolvedAddonAmount {
    return booking.videoAddonPrice;
  }

  int get resolvedExtraDurationAmount {
    final rawExtraFee = booking.extraDurationFee;

    if (rawExtraFee > 0) {
      return rawExtraFee;
    }

    if (booking.extraDurationMinutes <= 0) {
      return 0;
    }

    final inferredExtraFee =
        totalAmount - resolvedPackageAmount - resolvedAddonAmount;

    if (inferredExtraFee > 0) {
      return inferredExtraFee;
    }

    return 0;
  }

  bool get canCancelBeforePayment {
    return booking.id > 0 && !booking.isDpPaid && !booking.isFullyPaid;
  }

  Future<void> createAndOpenPayment({
    required BuildContext context,
    required String mode,
  }) async {
    if (booking.id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking tidak valid. Silakan cek riwayat booking.'),
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

  Future<void> confirmCancelBooking(BuildContext context) async {
    if (!canCancelBeforePayment) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Booking tidak bisa dicancel karena sudah ada pembayaran.',
          ),
        ),
      );
      return;
    }

    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Cancel Booking?',
            style: TextStyle(
              color: _PaymentPalette.darkBlue,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Booking akan dihapus dari riwayat klien. Booking tidak bisa dicancel jika sudah membayar DP.',
                style: TextStyle(height: 1.45),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Alasan cancel opsional',
                  hintText: 'Contoh: salah pilih jam / salah pilih paket',
                  filled: true,
                  fillColor: _PaymentPalette.cardLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Tidak'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya, Cancel'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final provider = context.read<PaymentProvider>();

    final ok = await provider.cancelBookingBeforePayment(
      bookingId: booking.id,
      reason: reasonController.text,
    );

    if (!context.mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking berhasil dicancel')),
      );

      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal cancel booking'),
        ),
      );
    }
  }

  Future<void> checkPaymentStatus(BuildContext context) async {
    final ok = await context.read<PaymentProvider>().checkPaymentStatus(
      bookingId: booking.id,
    );

    if (!context.mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status pembayaran berhasil diperbarui')),
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
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();
    final isBusy =
        paymentProvider.isLoading ||
        paymentProvider.isCheckingStatus ||
        paymentProvider.isCancellingBooking;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: _PaymentPalette.darkBlue,
        centerTitle: true,
        title: const Text(
          'Pembayaran',
          style: TextStyle(
            color: _PaymentPalette.darkBlue,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
          children: [
            _PaymentHeroCard(booking: booking),

            const SizedBox(height: 18),

            _WarningCard(
              text:
                  'Pembayaran DP minimal 50% diperlukan agar booking bisa diproses Front Office. Booking tidak bisa dicancel jika sudah membayar DP.',
            ),

            const SizedBox(height: 18),

            _BookingInfoCard(booking: booking),

            const SizedBox(height: 18),

            _BillSummaryCard(
              booking: booking,
              totalAmount: totalAmount,
              dpAmount: dpAmount,
              fullAmount: fullAmount,
              packageAmount: resolvedPackageAmount,
              addonAmount: resolvedAddonAmount,
              extraDurationAmount: resolvedExtraDurationAmount,
              formatCurrency: formatCurrency,
            ),

            const SizedBox(height: 22),

            Row(
              children: [
                Expanded(
                  child: _PaymentModeButton(
                    title: 'Bayar DP 50%',
                    icon: Icons.payments_outlined,
                    isLoading: paymentProvider.isLoading,
                    enabled: !isBusy && booking.id > 0,
                    onTap: () {
                      createAndOpenPayment(context: context, mode: 'dp');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PaymentModeButton(
                    title: 'Bayar Lunas',
                    icon: Icons.verified_rounded,
                    isLoading: paymentProvider.isLoading,
                    enabled: !isBusy && booking.id > 0,
                    onTap: () {
                      createAndOpenPayment(context: context, mode: 'full');
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: paymentProvider.isCheckingStatus || booking.id <= 0
                  ? null
                  : () => checkPaymentStatus(context),
              icon: paymentProvider.isCheckingStatus
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: const Text('Saya Sudah Bayar / Cek Status'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _PaymentPalette.darkBlue,
                side: const BorderSide(color: _PaymentPalette.cardDeep),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed:
                  paymentProvider.isCancellingBooking || !canCancelBeforePayment
                  ? null
                  : () => confirmCancelBooking(context),
              icon: paymentProvider.isCancellingBooking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cancel_outlined),
              label: const Text('Cancel Booking'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: BorderSide(
                  color: AppColors.danger.withValues(alpha: 0.30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: isBusy
                  ? null
                  : () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
              child: const Text(
                'Bayar Nanti',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentPalette {
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

class _PaymentHeroCard extends StatelessWidget {
  final BookingModel booking;

  const _PaymentHeroCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: _PaymentPalette.darkGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _PaymentPalette.darkBlue.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -46,
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
                  Icons.payments_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.packageName.isEmpty
                          ? 'Paket Foto'
                          : booking.packageName,
                      maxLines: 2,
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
                      'Booking berhasil dibuat. Pilih metode pembayaran untuk melanjutkan.',
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
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF9A3412),
                height: 1.45,
                fontSize: 12.6,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingInfoCard extends StatelessWidget {
  final BookingModel booking;

  const _BookingInfoCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final location = booking.locationName.trim().isEmpty
        ? '-'
        : booking.locationName.trim();

    final notes = booking.notes == null || booking.notes!.trim().isEmpty
        ? '-'
        : booking.notes!.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _PaymentPalette.cardDeep),
        boxShadow: [
          BoxShadow(
            color: _PaymentPalette.darkBlue.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.calendar_month_outlined,
            label: 'Tanggal Booking',
            value: booking.bookingDate.isEmpty ? '-' : booking.bookingDate,
          ),
          const _InfoDivider(),
          _InfoRow(
            icon: Icons.schedule_outlined,
            label: 'Jam Booking',
            value: booking.startTime.isEmpty
                ? '-'
                : '${booking.startTime} - ${booking.endTime}',
          ),
          const _InfoDivider(),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Lokasi Foto',
            value: location,
          ),
          const _InfoDivider(),
          _InfoRow(
            icon: Icons.description_outlined,
            label: 'Deskripsi / Catatan',
            value: notes,
          ),
        ],
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: _PaymentPalette.softGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: _PaymentPalette.darkBlue, size: 19),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: _PaymentPalette.darkBlue.withValues(alpha: 0.54),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: _PaymentPalette.darkBlue,
                  height: 1.32,
                  fontSize: 13.3,
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

class _InfoDivider extends StatelessWidget {
  const _InfoDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        height: 1,
        color: _PaymentPalette.cardDeep.withValues(alpha: 0.78),
      ),
    );
  }
}

class _BillSummaryCard extends StatelessWidget {
  final BookingModel booking;
  final int totalAmount;
  final int dpAmount;
  final int fullAmount;
  final int packageAmount;
  final int addonAmount;
  final int extraDurationAmount;
  final String Function(int) formatCurrency;

  const _BillSummaryCard({
    required this.booking,
    required this.totalAmount,
    required this.dpAmount,
    required this.fullAmount,
    required this.packageAmount,
    required this.addonAmount,
    required this.extraDurationAmount,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: _PaymentPalette.softGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
        boxShadow: [
          BoxShadow(
            color: _PaymentPalette.darkBlue.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Tagihan',
            style: TextStyle(
              color: _PaymentPalette.darkBlue,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _BillLine(label: 'Harga Paket', value: formatCurrency(packageAmount)),
          if (booking.extraDurationMinutes > 0)
            _BillLine(
              label: 'Extra Duration ${booking.extraDurationMinutes} menit',
              value: formatCurrency(extraDurationAmount),
            ),
          if (booking.videoAddonName != null &&
              booking.videoAddonName!.isNotEmpty)
            _BillLine(
              label: 'Add-on ${booking.videoAddonName}',
              value: formatCurrency(addonAmount),
            ),
          const SizedBox(height: 8),
          Divider(color: _PaymentPalette.darkBlue.withValues(alpha: 0.12)),
          const SizedBox(height: 8),
          _BillLine(
            label: 'Total Biaya',
            value: formatCurrency(totalAmount),
            strong: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PaymentAmountBox(
                  title: 'DP 50%',
                  amount: formatCurrency(dpAmount),
                  subtitle: 'Tagihan minimal',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PaymentAmountBox(
                  title: 'Lunas',
                  amount: formatCurrency(fullAmount),
                  subtitle: 'Bayar penuh',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillLine extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _BillLine({
    required this.label,
    required this.value,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: strong
                    ? _PaymentPalette.darkBlue
                    : _PaymentPalette.darkBlue.withValues(alpha: 0.62),
                fontSize: strong ? 14 : 12.5,
                fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              color: _PaymentPalette.darkBlue,
              fontSize: strong ? 15 : 12.5,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentAmountBox extends StatelessWidget {
  final String title;
  final String amount;
  final String subtitle;

  const _PaymentAmountBox({
    required this.title,
    required this.amount,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _PaymentPalette.darkBlue.withValues(alpha: 0.58),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _PaymentPalette.darkBlue,
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              color: _PaymentPalette.darkBlue.withValues(alpha: 0.52),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentModeButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  const _PaymentModeButton({
    required this.title,
    required this.icon,
    required this.isLoading,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: _PaymentPalette.darkBlue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _PaymentPalette.darkBlue.withValues(
          alpha: 0.42,
        ),
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.2,
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
    );
  }
}
