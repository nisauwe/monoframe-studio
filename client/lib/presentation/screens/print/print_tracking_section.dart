import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/providers/print_order_provider.dart';
import 'print_order_form_screen.dart';
import '../common/network_image_preview_screen.dart';

class PrintTrackingSection extends StatefulWidget {
  final int bookingId;
  final bool canPrint;

  const PrintTrackingSection({
    super.key,
    required this.bookingId,
    required this.canPrint,
  });

  @override
  State<PrintTrackingSection> createState() => _PrintTrackingSectionState();
}

class _PrintTrackingSectionState extends State<PrintTrackingSection>
    with WidgetsBindingObserver {
  bool _waitingForPaymentReturn = false;
  bool _autoOpeningPaymentAfterCreate = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrintOrderProvider>().fetchPrintOrder(
        bookingId: widget.bookingId,
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForPaymentReturn) {
      _waitingForPaymentReturn = false;
      _checkPaymentStatus(showMessage: true);
    }
  }

  Future<void> _refresh() async {
    await context.read<PrintOrderProvider>().fetchPrintOrder(
      bookingId: widget.bookingId,
    );
  }

  Future<void> _skipPrint() async {
    final provider = context.read<PrintOrderProvider>();

    final ok = await provider.skipPrint(bookingId: widget.bookingId);

    if (!mounted) return;

    if (ok) {
      _showMessage('Tahap cetak dilewati. Silakan lanjut review.');
      await _refresh();
    } else {
      _showMessage(provider.errorMessage ?? 'Gagal melewati tahap cetak.');
    }
  }

  Future<void> _openForm() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PrintOrderFormScreen(bookingId: widget.bookingId),
      ),
    );

    if (!mounted) return;

    await _refresh();

    if (!mounted) return;

    if (result == true) {
      final order = context.read<PrintOrderProvider>().printOrder;

      if (order == null) {
        _showMessage(
          'Pesanan cetak berhasil dibuat, tetapi data belum terbaca. Silakan refresh halaman.',
        );
        return;
      }

      if (order.isPaid) {
        _showMessage('Pesanan cetak sudah dibayar.');
        return;
      }

      _autoOpeningPaymentAfterCreate = true;

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      await _payPrintOrder();

      _autoOpeningPaymentAfterCreate = false;
    }
  }

  Future<void> _payPrintOrder() async {
    final provider = context.read<PrintOrderProvider>();
    final order = provider.printOrder;

    if (order == null) {
      _showMessage('Pesanan cetak tidak ditemukan.');
      return;
    }

    final snap = await provider.createPrintPayment(printOrderId: order.id);

    if (!mounted) return;

    if (snap == null) {
      _showMessage(provider.errorMessage ?? 'Gagal membuat pembayaran cetak.');
      return;
    }

    final redirectUrl = snap.redirectUrl.trim();

    if (redirectUrl.isEmpty) {
      _showMessage('URL pembayaran Midtrans kosong.');
      return;
    }

    if (!redirectUrl.startsWith('http://') &&
        !redirectUrl.startsWith('https://')) {
      _showMessage('URL pembayaran Midtrans tidak valid.');
      return;
    }

    final uri = Uri.tryParse(redirectUrl);

    if (uri == null) {
      _showMessage('URL pembayaran cetak tidak valid.');
      return;
    }

    _waitingForPaymentReturn = true;

    final openedExternal = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (openedExternal) {
      if (!_autoOpeningPaymentAfterCreate) {
        _showMessage(
          'Setelah pembayaran selesai, kembali ke aplikasi lalu tekan Cek Status Pembayaran.',
        );
      }
      return;
    }

    final openedInApp = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);

    if (openedInApp) {
      if (!_autoOpeningPaymentAfterCreate) {
        _showMessage(
          'Setelah pembayaran selesai, kembali ke aplikasi lalu tekan Cek Status Pembayaran.',
        );
      }
      return;
    }

    final openedDefault = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
    );

    if (!openedDefault) {
      _waitingForPaymentReturn = false;

      if (!mounted) return;

      _showMessage(
        'Tidak bisa membuka halaman pembayaran Midtrans. Pastikan browser tersedia di HP.',
      );
    }
  }

  Future<void> _checkPaymentStatus({bool showMessage = false}) async {
    final provider = context.read<PrintOrderProvider>();
    final order = provider.printOrder;

    if (order == null) {
      _showMessage('Pesanan cetak tidak ditemukan.');
      return;
    }

    final ok = await provider.checkPrintPaymentStatus(printOrderId: order.id);

    if (!mounted) return;

    if (!ok) {
      _showMessage(
        provider.errorMessage ?? 'Gagal mengecek status pembayaran cetak.',
      );
      return;
    }

    await _refresh();

    if (!mounted) return;

    final updatedOrder = context.read<PrintOrderProvider>().printOrder;

    if (updatedOrder?.isPaid == true) {
      _showMessage('Pembayaran cetak sudah berhasil.');
    } else if (showMessage) {
      _showMessage('Pembayaran cetak masih pending atau belum selesai.');
    }
  }

  void _openImagePreview(String imageUrl) {
    final cleanUrl = imageUrl.trim();

    if (cleanUrl.isEmpty) {
      _showMessage('URL gambar kosong.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NetworkImagePreviewScreen(
          imageUrl: cleanUrl,
          title: 'Gambar Cetakan Selesai',
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _currency(int value) {
    final text = value.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;

      buffer.write(text[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    return 'Rp $buffer';
  }

  Widget _buildEmptyPrintBox(PrintOrderProvider provider) {
    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InlineHeader(
            icon: Icons.print_rounded,
            title: 'Apakah kamu ingin mencetak foto?',
            subtitle:
                'Pilih ukuran cetak, jumlah file, dan opsi bingkai dalam satu pesanan.',
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: provider.isSubmitting ? null : _openForm,
              icon: const Icon(Icons.print_rounded, size: 18),
              label: const Text('Mau Cetak'),
              style: _primaryButtonStyle(),
            ),
          ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: provider.isSubmitting ? null : _skipPrint,
              icon: provider.isSubmitting
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.skip_next_rounded, size: 18),
              label: const Text('Tidak Cetak, Lanjut Review'),
              style: _outlineButtonStyle(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofImage(String proofImageUrl) {
    final cleanUrl = proofImageUrl.trim();

    if (cleanUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const _SmallSectionTitle(title: 'Gambar Cetakan Selesai'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _openImagePreview(cleanUrl),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              cleanUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;

                return Container(
                  height: 180,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const CircularProgressIndicator(
                    color: AppColors.primaryDark,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'Gambar tidak bisa dimuat',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: OutlinedButton.icon(
            onPressed: () => _openImagePreview(cleanUrl),
            icon: const Icon(Icons.image_rounded, size: 18),
            label: const Text('Buka Gambar di Aplikasi'),
            style: _outlineButtonStyle(),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderBox(PrintOrderProvider provider) {
    final order = provider.printOrder!;

    final showPaymentButton =
        !order.isPaid &&
        (order.status == 'pending_payment' ||
            order.paymentStatus == 'unpaid' ||
            order.paymentStatus == 'pending' ||
            order.paymentStatus == 'failed');

    final completionUrl = order.completionPhotoUrl.trim();
    final deliveryProofUrl = order.deliveryProofUrl.trim();

    final proofImageUrl = completionUrl.isNotEmpty
        ? completionUrl
        : deliveryProofUrl;

    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OrderStatusHeader(
            statusLabel: order.statusLabel,
            paymentPaid: order.isPaid,
            deliveryMethod: order.deliveryMethodLabel,
          ),

          const SizedBox(height: 14),

          _SummaryPanel(
            children: [
              _SummaryTile(
                icon: Icons.local_shipping_rounded,
                label: 'Metode',
                value: order.deliveryMethodLabel,
              ),
              _SummaryTile(
                icon: Icons.format_list_numbered_rounded,
                label: 'Jumlah',
                value: '${order.quantity} cetakan',
              ),
              _SummaryTile(
                icon: Icons.photo_size_select_actual_rounded,
                label: 'Subtotal Cetak',
                value: _currency(order.subtotalPrint),
              ),
              _SummaryTile(
                icon: Icons.crop_original_rounded,
                label: 'Subtotal Bingkai',
                value: _currency(order.subtotalFrame),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _TotalPaymentStrip(total: _currency(order.totalAmount)),

          const SizedBox(height: 16),

          const _SmallSectionTitle(title: 'Detail Cetakan'),

          const SizedBox(height: 10),

          if (order.items.isEmpty)
            const _SoftNotice(
              icon: Icons.info_outline_rounded,
              text: 'Detail item cetak belum tersedia.',
              color: AppColors.grey,
            )
          else
            ...List.generate(order.items.length, (index) {
              final item = order.items[index];

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.welcomeCardGradient,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.white.withOpacity(0.78)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cetakan ${index + 1}',
                      style: const TextStyle(
                        color: AppColors.welcomeBlueDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _InfoLine(label: 'Nama File', value: item.fileName),
                    _InfoLine(label: 'Ukuran', value: item.sizeName),
                    _InfoLine(label: 'Jumlah', value: '${item.qty}'),
                    _InfoLine(label: 'Bingkai', value: item.frameLabel),
                    _InfoLine(
                      label: 'Harga Cetak',
                      value: _currency(item.unitPrintPrice),
                    ),
                    _InfoLine(
                      label: 'Harga Bingkai',
                      value: _currency(item.unitFramePrice),
                    ),
                    _InfoLine(
                      label: 'Subtotal',
                      value: _currency(item.lineTotal),
                      isBold: true,
                    ),
                  ],
                ),
              );
            }),

          if (order.deliveryMethod == 'delivery') ...[
            const SizedBox(height: 12),
            const _SmallSectionTitle(title: 'Data Pengiriman'),
            const SizedBox(height: 10),
            _SummaryPanel(
              children: [
                _SummaryTile(
                  icon: Icons.person_rounded,
                  label: 'Nama',
                  value: order.recipientName.isEmpty
                      ? '-'
                      : order.recipientName,
                ),
                _SummaryTile(
                  icon: Icons.phone_rounded,
                  label: 'Nomor HP',
                  value: order.recipientPhone.isEmpty
                      ? '-'
                      : order.recipientPhone,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _SoftNotice(
              icon: Icons.location_on_rounded,
              text: order.deliveryAddress.isEmpty ? '-' : order.deliveryAddress,
              color: AppColors.primaryDark,
            ),
            const SizedBox(height: 8),
            const _SoftNotice(
              icon: Icons.info_outline_rounded,
              text: 'Biaya ekspedisi ditanggung klien di luar sistem.',
              color: AppColors.warning,
            ),
          ],

          if (order.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _SmallSectionTitle(title: 'Catatan'),
            const SizedBox(height: 8),
            _SoftNotice(
              icon: Icons.notes_rounded,
              text: order.notes,
              color: AppColors.primaryDark,
            ),
          ],

          const SizedBox(height: 16),

          if (showPaymentButton) ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: provider.isSubmitting ? null : _payPrintOrder,
                icon: provider.isSubmitting
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.payments_rounded, size: 18),
                label: Text(
                  provider.isSubmitting
                      ? 'Memproses...'
                      : 'Bayar Pesanan Cetak',
                ),
                style: _primaryButtonStyle(),
              ),
            ),
            const SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: provider.isSubmitting
                    ? null
                    : () => _checkPaymentStatus(showMessage: true),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Cek Status Pembayaran'),
                style: _outlineButtonStyle(),
              ),
            ),
          ],

          if (order.isPaid && !order.isCompleted)
            const _SoftNotice(
              icon: Icons.hourglass_top_rounded,
              text:
                  'Pembayaran cetak sudah diterima. Pesanan sedang menunggu diproses Front Office.',
              color: AppColors.warning,
            ),

          if (order.deliveryMethod == 'pickup' && order.isCompleted)
            const _SoftNotice(
              icon: Icons.store_rounded,
              text: 'Cetakan sudah selesai. Silakan ambil ke Studio Monoframe.',
              color: AppColors.success,
            ),

          if (order.deliveryMethod == 'delivery' && order.isCompleted)
            const _SoftNotice(
              icon: Icons.local_shipping_rounded,
              text:
                  'Cetakan sudah selesai dan akan/sudah dikirim oleh Front Office.',
              color: AppColors.success,
            ),

          if (proofImageUrl.isNotEmpty) _buildProofImage(proofImageUrl),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrintOrderProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),

        const _SectionHeader(),

        const SizedBox(height: 12),

        if (provider.isLoading)
          Container(
            width: double.infinity,
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: const CircularProgressIndicator(
              color: AppColors.primaryDark,
            ),
          )
        else if (!widget.canPrint)
          const _Box(
            child: _SoftNotice(
              icon: Icons.lock_clock_rounded,
              text: 'Tahap cetak akan aktif setelah hasil edit selesai.',
              color: AppColors.grey,
            ),
          )
        else if (provider.printOrder == null)
          _buildEmptyPrintBox(provider)
        else
          _buildOrderBox(provider),
      ],
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: AppColors.primaryDark,
      foregroundColor: AppColors.white,
      disabledBackgroundColor: AppColors.grey.withOpacity(0.35),
      disabledForegroundColor: AppColors.white.withOpacity(0.86),
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
    );
  }

  ButtonStyle _outlineButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryDark,
      backgroundColor: AppColors.light.withOpacity(0.70),
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 30,
          width: 5,
          decoration: BoxDecoration(
            gradient: AppColors.welcomeDarkGradient,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cetak Foto',
                style: TextStyle(
                  color: AppColors.dark,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Pesan cetakan foto setelah hasil edit selesai.',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 11.2,
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

class _InlineHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InlineHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            gradient: AppColors.welcomeCardGradient,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.white.withOpacity(0.78)),
          ),
          child: Icon(icon, color: AppColors.welcomeBlueDark, size: 25),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.dark,
                  fontSize: 14.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 11.5,
                  height: 1.35,
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

class _OrderStatusHeader extends StatelessWidget {
  final String statusLabel;
  final bool paymentPaid;
  final String deliveryMethod;

  const _OrderStatusHeader({
    required this.statusLabel,
    required this.paymentPaid,
    required this.deliveryMethod,
  });

  @override
  Widget build(BuildContext context) {
    final paymentColor = paymentPaid ? AppColors.success : AppColors.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InlineHeader(
          icon: Icons.print_rounded,
          title: statusLabel,
          subtitle: 'Metode: $deliveryMethod',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatusPill(
                text: statusLabel,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _StatusPill(
                text: paymentPaid ? 'Sudah Bayar' : 'Belum Bayar',
                color: paymentColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Text(
        text.trim().isEmpty ? '-' : text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  final List<Widget> children;

  const _SummaryPanel({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 11, 11, 11),
      decoration: BoxDecoration(
        gradient: AppColors.welcomeCardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white.withOpacity(0.76)),
      ),
      child: Column(
        children: List.generate(children.length, (index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == children.length - 1 ? 0 : 10,
            ),
            child: children[index],
          );
        }),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.welcomeBlueDark, size: 16),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.welcomeBlueDark.withOpacity(0.58),
              fontSize: 10.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value.trim().isEmpty ? '-' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.welcomeBlueDark,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _TotalPaymentStrip extends StatelessWidget {
  final String total;

  const _TotalPaymentStrip({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryDark.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.payments_rounded,
            color: AppColors.primaryDark,
            size: 18,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Total Pembayaran',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            total,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallSectionTitle extends StatelessWidget {
  final String title;

  const _SmallSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.dark,
        fontWeight: FontWeight.w900,
        fontSize: 14.5,
      ),
    );
  }
}

class _SoftNotice extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _SoftNotice({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final actualColor = color == AppColors.grey
        ? AppColors.welcomeBlueDark
        : color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        color: actualColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: actualColor.withOpacity(0.13)),
      ),
      child: Row(
        children: [
          Icon(icon, color: actualColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: actualColor,
                fontSize: 11.4,
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

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _InfoLine({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: AppColors.welcomeBlueDark,
      fontSize: 11.3,
      fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.welcomeBlueDark.withOpacity(0.55),
                fontSize: 10.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(value.trim().isEmpty ? '-' : value, style: style),
          ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  final Widget child;

  const _Box({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.045),
            blurRadius: 16,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: child,
    );
  }
}
