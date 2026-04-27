import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../data/models/front_office_print_order_model.dart';
import '../../../data/providers/front_office_print_order_provider.dart';

class FrontOfficePrintOrdersScreen extends StatefulWidget {
  const FrontOfficePrintOrdersScreen({super.key});

  @override
  State<FrontOfficePrintOrdersScreen> createState() =>
      _FrontOfficePrintOrdersScreenState();
}

class _FrontOfficePrintOrdersScreenState
    extends State<FrontOfficePrintOrdersScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FrontOfficePrintOrderProvider>().fetchOrders();
    });
  }

  Future<void> _refresh() async {
    await context.read<FrontOfficePrintOrderProvider>().fetchOrders();
  }

  Future<void> _changeFilter(String status) async {
    await context.read<FrontOfficePrintOrderProvider>().fetchOrders(
      status: status,
    );
  }

  Future<void> _markProcessing(FrontOfficePrintOrderModel order) async {
    final provider = context.read<FrontOfficePrintOrderProvider>();

    final ok = await provider.markProcessing(printOrderId: order.id);

    if (!mounted) return;

    if (ok) {
      _showMessage('Pesanan cetak masuk proses.');
      await _refresh();
    } else {
      _showMessage(provider.errorMessage ?? 'Gagal memproses pesanan cetak.');
    }
  }

  Future<void> _completeOrder(FrontOfficePrintOrderModel order) async {
    final source = await _showImageSourceDialog();

    if (!mounted) return;
    if (source == null) return;

    XFile? picked;

    try {
      picked = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1600,
        maxHeight: 1600,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Gagal membuka ${source == ImageSource.camera ? 'kamera' : 'galeri'}: $e',
      );
      return;
    }

    if (!mounted) return;
    if (picked == null) return;

    final imageFile = File(picked.path);

    if (!imageFile.existsSync()) {
      _showMessage('File gambar tidak ditemukan.');
      return;
    }

    final confirmed = await _showConfirmUploadDialog(
      order: order,
      imageFile: imageFile,
    );

    if (!mounted) return;
    if (confirmed != true) return;

    await _uploadCompletionPhoto(order: order, imagePath: picked.path);
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 420 ? 380.0 : screenWidth - 40;

    return showDialog<ImageSource>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: SizedBox(
            width: dialogWidth,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upload Gambar Cetakan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pilih sumber gambar cetakan yang sudah selesai.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(ImageSource.gallery);
                      },
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Pilih dari Galeri'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(ImageSource.camera);
                      },
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Ambil dari Kamera'),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showConfirmUploadDialog({
    required FrontOfficePrintOrderModel order,
    required File imageFile,
  }) async {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width > 440 ? 400.0 : screenSize.width - 32;
    final imageHeight = screenSize.height > 700 ? 260.0 : 200.0;

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: SizedBox(
            width: dialogWidth,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: screenSize.height * 0.82),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Konfirmasi Pesanan Selesai',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Pesanan Cetak #${order.id} akan dikonfirmasi selesai.',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Pastikan gambar yang dipilih adalah bukti cetakan sudah selesai.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: dialogWidth - 36,
                          height: imageHeight,
                          child: Image.file(
                            imageFile,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                alignment: Alignment.center,
                                color: const Color(0xFFF3F4F6),
                                child: const Text(
                                  'Preview gambar gagal dimuat',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop(false);
                              },
                              child: const Text('Batal'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(dialogContext).pop(true);
                              },
                              icon: const Icon(Icons.cloud_upload_outlined),
                              label: const Text('Kirim'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadCompletionPhoto({
    required FrontOfficePrintOrderModel order,
    required String imagePath,
  }) async {
    final provider = context.read<FrontOfficePrintOrderProvider>();

    _showLoadingDialog('Mengupload gambar cetakan...');

    final ok = await provider.completePrintOrder(
      printOrderId: order.id,
      completionPhotoPath: imagePath,
    );

    if (!mounted) return;

    _closeLoadingDialog();

    if (ok) {
      _showMessage('Pesanan cetak berhasil dikonfirmasi selesai.');
      await _refresh();
    } else {
      _showMessage(
        provider.errorMessage ?? 'Gagal menyelesaikan pesanan cetak.',
      );
    }
  }

  void _showLoadingDialog(String message) {
    if (!mounted) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 420 ? 360.0 : screenWidth - 40;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              width: dialogWidth,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _closeLoadingDialog() {
    if (!mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);

    if (navigator.canPop()) {
      navigator.pop();
    }
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

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _filterChip({
    required String label,
    required String value,
    required String selected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected == value,
      onSelected: (_) => _changeFilter(value),
    );
  }

  Widget _buildPhotoColumn(FrontOfficePrintOrderModel order) {
    final url = order.completionPhotoUrl.trim();

    if (url.isEmpty) {
      return Container(
        height: 110,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, color: Colors.grey),
            SizedBox(height: 6),
            Text(
              'Belum ada foto cetakan selesai',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        url,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 110,
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
    );
  }

  Widget _buildOrderCard(
    FrontOfficePrintOrderModel order,
    FrontOfficePrintOrderProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.print_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pesanan Cetak #${order.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(order.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  order.statusLabel,
                  style: TextStyle(
                    color: _statusColor(order.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _InfoLine(label: 'Klien', value: order.clientName),
          _InfoLine(
            label: 'No HP',
            value: order.clientPhone.isEmpty ? '-' : order.clientPhone,
          ),
          _InfoLine(label: 'Paket', value: order.packageName),
          _InfoLine(label: 'Metode', value: order.deliveryMethodLabel),
          _InfoLine(label: 'Jumlah', value: '${order.quantity} cetakan'),
          _InfoLine(
            label: 'Total',
            value: _currency(order.totalAmount),
            isBold: true,
          ),

          if (order.deliveryMethod == 'delivery') ...[
            const SizedBox(height: 8),
            const Text(
              'Data Pengiriman',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            _InfoLine(
              label: 'Penerima',
              value: order.recipientName.isEmpty ? '-' : order.recipientName,
            ),
            _InfoLine(
              label: 'HP Penerima',
              value: order.recipientPhone.isEmpty ? '-' : order.recipientPhone,
            ),
            _InfoLine(
              label: 'Alamat',
              value: order.deliveryAddress.isEmpty
                  ? '-'
                  : order.deliveryAddress,
            ),
          ],

          const SizedBox(height: 12),

          const Text(
            'Detail Cetakan',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (order.items.isEmpty)
            const Text(
              'Detail cetakan belum tersedia.',
              style: TextStyle(color: Colors.grey),
            )
          else
            ...List.generate(order.items.length, (index) {
              final item = order.items[index];

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cetakan ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    _InfoLine(label: 'File', value: item.fileName),
                    _InfoLine(label: 'Ukuran', value: item.sizeName),
                    _InfoLine(label: 'Jumlah', value: '${item.qty}'),
                    _InfoLine(label: 'Bingkai', value: item.frameLabel),
                    _InfoLine(
                      label: 'Subtotal',
                      value: _currency(item.lineTotal),
                      isBold: true,
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 12),

          const Text(
            'Gambar Cetakan Selesai',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildPhotoColumn(order),

          if (order.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Catatan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(order.notes),
          ],

          const SizedBox(height: 14),

          if (order.canProcess)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: provider.isSubmitting
                    ? null
                    : () => _markProcessing(order),
                icon: const Icon(Icons.hourglass_bottom),
                label: const Text('Proses Cetakan'),
              ),
            ),

          if (order.canComplete)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.isSubmitting
                    ? null
                    : () => _completeOrder(order),
                icon: provider.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  provider.isSubmitting
                      ? 'Memproses...'
                      : 'Konfirmasi Pesanan Selesai + Upload Gambar',
                ),
              ),
            ),

          if (order.isCompleted)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Pesanan cetak sudah selesai dikonfirmasi.',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FrontOfficePrintOrderProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Cetak')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Pesanan Cetak Klien',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              const SizedBox(height: 6),
              const Text(
                'Front Office memproses pesanan cetak yang sudah dibayar, lalu mengkonfirmasi selesai dengan upload gambar cetakan.',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 14),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip(
                      label: 'Semua',
                      value: 'all',
                      selected: provider.selectedStatus,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      label: 'Menunggu Diproses',
                      value: 'paid',
                      selected: provider.selectedStatus,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      label: 'Diproses',
                      value: 'processing',
                      selected: provider.selectedStatus,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      label: 'Selesai',
                      value: 'completed',
                      selected: provider.selectedStatus,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (provider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (provider.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else if (provider.orders.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Belum ada pesanan cetak yang perlu diproses.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...provider.orders.map((order) {
                  return _buildOrderCard(order, provider);
                }),
            ],
          ),
        ),
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
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: style)),
        ],
      ),
    );
  }
}
