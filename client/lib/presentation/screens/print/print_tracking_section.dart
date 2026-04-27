import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
          const Text(
            'Apakah kamu ingin mencetak foto?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kamu bisa memilih beberapa ukuran cetak dalam satu pesanan. Setiap cetakan bisa memakai bingkai atau tidak.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: provider.isSubmitting ? null : _openForm,
              icon: const Icon(Icons.print_outlined),
              label: const Text('Mau Cetak'),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: provider.isSubmitting ? null : _skipPrint,
              icon: provider.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.skip_next_outlined),
              label: const Text('Tidak Cetak, Lanjut Review'),
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
        const Text(
          'Gambar Cetakan Selesai',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _openImagePreview(cleanUrl),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
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
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const CircularProgressIndicator(),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Gambar tidak bisa dimuat',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openImagePreview(cleanUrl),
            icon: const Icon(Icons.image_outlined),
            label: const Text('Buka Gambar di Aplikasi'),
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
          Text(
            order.statusLabel,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF6C63FF),
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 10),

          _InfoLine(label: 'Metode', value: order.deliveryMethodLabel),
          _InfoLine(
            label: 'Total Jumlah Cetak',
            value: '${order.quantity} cetakan',
          ),
          _InfoLine(
            label: 'Subtotal Cetak',
            value: _currency(order.subtotalPrint),
          ),
          _InfoLine(
            label: 'Subtotal Bingkai',
            value: _currency(order.subtotalFrame),
          ),
          _InfoLine(
            label: 'Total Pembayaran',
            value: _currency(order.totalAmount),
            isBold: true,
          ),

          const SizedBox(height: 16),

          const Text(
            'Detail Cetakan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),

          const SizedBox(height: 10),

          if (order.items.isEmpty)
            const Text(
              'Detail item cetak belum tersedia.',
              style: TextStyle(color: Colors.grey),
            )
          else
            ...List.generate(order.items.length, (index) {
              final item = order.items[index];

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cetakan ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
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
            const Text(
              'Data Pengiriman',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            _InfoLine(
              label: 'Nama Penerima',
              value: order.recipientName.isEmpty ? '-' : order.recipientName,
            ),
            _InfoLine(
              label: 'Nomor HP',
              value: order.recipientPhone.isEmpty ? '-' : order.recipientPhone,
            ),
            _InfoLine(
              label: 'Alamat',
              value: order.deliveryAddress.isEmpty
                  ? '-'
                  : order.deliveryAddress,
            ),
            const SizedBox(height: 6),
            const Text(
              'Biaya ekspedisi ditanggung klien di luar sistem.',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          if (order.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Catatan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(order.notes),
          ],

          const SizedBox(height: 16),

          if (showPaymentButton) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.isSubmitting ? null : _payPrintOrder,
                icon: provider.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.payments_outlined),
                label: Text(
                  provider.isSubmitting
                      ? 'Memproses...'
                      : 'Bayar Pesanan Cetak',
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: provider.isSubmitting
                    ? null
                    : () => _checkPaymentStatus(showMessage: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Cek Status Pembayaran'),
              ),
            ),
          ],

          if (order.isPaid && !order.isCompleted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Pembayaran cetak sudah diterima. Pesanan sedang menunggu diproses Front Office.',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          if (order.deliveryMethod == 'pickup' && order.isCompleted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Cetakan sudah selesai. Silakan ambil ke Studio Monoframe.',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          if (order.deliveryMethod == 'delivery' && order.isCompleted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Cetakan sudah selesai dan akan/sudah dikirim oleh Front Office.',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
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

        const Row(
          children: [
            Icon(Icons.print_outlined),
            SizedBox(width: 8),
            Text(
              'Cetak Foto',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (provider.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (!widget.canPrint)
          _Box(
            child: const Text(
              'Tahap cetak akan aktif setelah hasil edit selesai.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else if (provider.printOrder == null)
          _buildEmptyPrintBox(provider)
        else
          _buildOrderBox(provider),
      ],
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
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: style)),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }
}
