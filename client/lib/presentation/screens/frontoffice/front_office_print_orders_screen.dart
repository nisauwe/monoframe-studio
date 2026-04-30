import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
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
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Container(
            width: dialogWidth,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.welcomeCardDeep),
              boxShadow: [
                BoxShadow(
                  color: AppColors.welcomeBlueDark.withOpacity(0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.welcomeDarkGradient,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.22),
                          ),
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate_rounded,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Upload Gambar Cetakan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pilih sumber gambar bukti cetakan selesai.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.74),
                                fontSize: 11.8,
                                height: 1.35,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SourcePickerButton(
                  icon: Icons.photo_library_rounded,
                  title: 'Pilih dari Galeri',
                  subtitle: 'Ambil gambar dari file/galeri perangkat',
                  color: AppColors.welcomeBlueDark,
                  onTap: () {
                    Navigator.of(dialogContext).pop(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 10),
                _SourcePickerButton(
                  icon: Icons.camera_alt_rounded,
                  title: 'Ambil dari Kamera',
                  subtitle: 'Foto bukti cetakan secara langsung',
                  color: AppColors.success,
                  onTap: () {
                    Navigator.of(dialogContext).pop(ImageSource.camera);
                  },
                ),
              ],
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
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: SizedBox(
            width: dialogWidth,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: screenSize.height * 0.84),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.welcomeCardDeep),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.welcomeBlueDark.withOpacity(0.16),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: AppColors.welcomeDarkGradient,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.22),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.fact_check_rounded,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Konfirmasi Pesanan Selesai',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Pesanan Cetak #${order.id} akan dikonfirmasi selesai.',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.74),
                                        fontSize: 11.8,
                                        height: 1.35,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            width: dialogWidth - 36,
                            height: imageHeight,
                            child: Image.file(
                              imageFile,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    gradient: AppColors.welcomeCardGradient,
                                  ),
                                  child: const Text(
                                    'Preview gambar gagal dimuat',
                                    style: TextStyle(
                                      color: AppColors.welcomeBlueDark,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _DialogInfoBox(
                          icon: Icons.info_outline_rounded,
                          color: AppColors.warning,
                          text:
                              'Pastikan gambar yang dipilih adalah bukti cetakan sudah selesai.',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop(false);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.welcomeBlueDark,
                                  side: const BorderSide(
                                    color: AppColors.welcomeCardDeep,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                child: const Text('Batal'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop(true);
                                },
                                icon: const Icon(
                                  Icons.cloud_upload_rounded,
                                  size: 18,
                                ),
                                label: const Text('Kirim'),
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: AppColors.welcomeBlueDark,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: AppColors
                                      .welcomeBlueDark
                                      .withOpacity(0.42),
                                  disabledForegroundColor: Colors.white
                                      .withOpacity(0.74),
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
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
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            child: Container(
              width: dialogWidth,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.welcomeCardDeep),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.welcomeBlueDark.withOpacity(0.14),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.welcomeBlueDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.welcomeBlueDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
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
        return AppColors.welcomeBlueDark;
      case 'processing':
        return AppColors.warning;
      case 'completed':
        return AppColors.success;
      case 'pending_payment':
        return AppColors.grey;
      default:
        return AppColors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'paid':
        return Icons.payments_rounded;
      case 'processing':
        return Icons.hourglass_bottom_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'pending_payment':
        return Icons.pending_actions_rounded;
      default:
        return Icons.print_rounded;
    }
  }

  int _countStatus(List<FrontOfficePrintOrderModel> orders, String status) {
    return orders.where((order) => order.status == status).length;
  }

  Widget _buildOrderCard(
    FrontOfficePrintOrderModel order,
    FrontOfficePrintOrderProvider provider,
  ) {
    return _PrintOrderCard(
      order: order,
      currency: _currency,
      statusColor: _statusColor(order.status),
      statusIcon: _statusIcon(order.status),
      isSubmitting: provider.isSubmitting,
      onProcess: () => _markProcessing(order),
      onComplete: () => _completeOrder(order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FrontOfficePrintOrderProvider>();

    final totalShown = provider.orders.length;
    final waitingCount = _countStatus(provider.orders, 'paid');
    final processingCount = _countStatus(provider.orders, 'processing');
    final completedCount = _countStatus(provider.orders, 'completed');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background,
                AppColors.secondary,
                AppColors.secondary,
              ],
            ),
          ),
          child: RefreshIndicator(
            color: AppColors.welcomeBlueDark,
            backgroundColor: AppColors.welcomeCardLight,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 118),
              children: [
                _PrintHeroCard(
                  totalShown: totalShown,
                  waitingCount: waitingCount,
                  processingCount: processingCount,
                  completedCount: completedCount,
                ),

                const SizedBox(height: 16),

                _StatusFilterBar(
                  selected: provider.selectedStatus,
                  onSelected: _changeFilter,
                ),

                const SizedBox(height: 18),

                const _SectionTitle(
                  title: 'Daftar Pesanan Cetak',
                  subtitle:
                      'Proses pesanan yang sudah dibayar, lalu upload bukti cetakan selesai.',
                ),

                const SizedBox(height: 12),

                if (provider.isLoading)
                  const _LoadingState()
                else if (provider.errorMessage != null)
                  _ErrorState(message: provider.errorMessage!)
                else if (provider.orders.isEmpty)
                  const _EmptyPrintState()
                else
                  ...provider.orders.map((order) {
                    return _buildOrderCard(order, provider);
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SourcePickerButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SourcePickerButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.14)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: color.withOpacity(0.68),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogInfoBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _DialogInfoBox({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.14)),
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
                height: 1.35,
                fontSize: 11.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrintHeroCard extends StatelessWidget {
  final int totalShown;
  final int waitingCount;
  final int processingCount;
  final int completedCount;

  const _PrintHeroCard({
    required this.totalShown,
    required this.waitingCount,
    required this.processingCount,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.welcomeDarkGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -38,
            top: -44,
            child: Container(
              width: 126,
              height: 126,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.11),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 38,
            bottom: -54,
            child: Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.20),
                        ),
                      ),
                      child: const Icon(
                        Icons.local_printshop_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pesanan Cetak',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              height: 1.08,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Kelola cetakan klien dari proses sampai selesai.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.74),
                              fontSize: 12.8,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.20),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$totalShown',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Order',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HeroMetricPill(
                        icon: Icons.payments_rounded,
                        label: 'Menunggu',
                        value: '$waitingCount',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _HeroMetricPill(
                        icon: Icons.hourglass_bottom_rounded,
                        label: 'Diproses',
                        value: '$processingCount',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _HeroMetricPill(
                        icon: Icons.check_circle_rounded,
                        label: 'Selesai',
                        value: '$completedCount',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroMetricPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.fromLTRB(9, 10, 9, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _StatusFilterBar({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const filters = [
      _FilterData(label: 'Semua', value: 'all', icon: Icons.dashboard_rounded),
      _FilterData(
        label: 'Menunggu',
        value: 'paid',
        icon: Icons.payments_rounded,
      ),
      _FilterData(
        label: 'Diproses',
        value: 'processing',
        icon: Icons.hourglass_bottom_rounded,
      ),
      _FilterData(
        label: 'Selesai',
        value: 'completed',
        icon: Icons.check_circle_rounded,
      ),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selected == filter.value;

          return ChoiceChip(
            selected: isSelected,
            showCheckmark: false,
            selectedColor: AppColors.welcomeBlueDark,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected
                  ? AppColors.welcomeBlueDark
                  : AppColors.welcomeCardDeep,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            avatar: Icon(
              filter.icon,
              size: 15,
              color: isSelected ? Colors.white : AppColors.welcomeBlueDark,
            ),
            label: Text(filter.label),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.welcomeBlueDark,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
            onSelected: (_) => onSelected(filter.value),
          );
        },
      ),
    );
  }
}

class _FilterData {
  final String label;
  final String value;
  final IconData icon;

  const _FilterData({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 42,
          width: 5,
          decoration: BoxDecoration(
            gradient: AppColors.welcomeDarkGradient,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.dark,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 12.4,
                  height: 1.25,
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

class _PrintOrderCard extends StatelessWidget {
  final FrontOfficePrintOrderModel order;
  final String Function(int value) currency;
  final Color statusColor;
  final IconData statusIcon;
  final bool isSubmitting;
  final VoidCallback onProcess;
  final VoidCallback onComplete;

  const _PrintOrderCard({
    required this.order,
    required this.currency,
    required this.statusColor,
    required this.statusIcon,
    required this.isSubmitting,
    required this.onProcess,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.welcomeCardDeep),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.055),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OrderHeader(
              order: order,
              statusColor: statusColor,
              statusIcon: statusIcon,
            ),

            const SizedBox(height: 13),

            _ClientSummaryPanel(order: order, currency: currency),

            if (order.deliveryMethod == 'delivery') ...[
              const SizedBox(height: 12),
              _DeliveryPanel(order: order),
            ],

            const SizedBox(height: 14),

            _CardSectionTitle(
              icon: Icons.collections_bookmark_rounded,
              title: 'Detail Cetakan',
              subtitle: '${order.items.length} item cetakan',
            ),

            const SizedBox(height: 10),

            if (order.items.isEmpty)
              const _MiniInfoBox(
                icon: Icons.info_outline_rounded,
                color: AppColors.grey,
                text: 'Detail cetakan belum tersedia.',
              )
            else
              ...List.generate(order.items.length, (index) {
                return _PrintItemCard(
                  index: index,
                  item: order.items[index],
                  currency: currency,
                );
              }),

            const SizedBox(height: 14),

            _CardSectionTitle(
              icon: Icons.image_rounded,
              title: 'Gambar Cetakan Selesai',
              subtitle: order.completionPhotoUrl.trim().isEmpty
                  ? 'Belum ada bukti selesai'
                  : 'Bukti cetakan sudah diupload',
            ),

            const SizedBox(height: 10),

            _CompletionPhotoBox(order: order),

            if (order.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              _MiniInfoBox(
                icon: Icons.notes_rounded,
                color: AppColors.welcomeBlueDark,
                text: order.notes,
              ),
            ],

            const SizedBox(height: 14),

            if (order.canProcess)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: isSubmitting ? null : onProcess,
                  icon: const Icon(Icons.hourglass_bottom_rounded, size: 18),
                  label: const Text('Proses Cetakan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.welcomeBlueDark,
                    disabledForegroundColor: AppColors.welcomeBlueDark
                        .withOpacity(0.40),
                    side: const BorderSide(color: AppColors.welcomeCardDeep),
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

            if (order.canComplete) ...[
              if (order.canProcess) const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: isSubmitting ? null : onComplete,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 19),
                  label: Text(
                    isSubmitting
                        ? 'Memproses...'
                        : 'Konfirmasi Selesai + Upload Gambar',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.welcomeBlueDark,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.welcomeBlueDark
                        .withOpacity(0.42),
                    disabledForegroundColor: Colors.white.withOpacity(0.74),
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
            ],

            if (order.isCompleted) ...[
              const SizedBox(height: 12),
              const _MiniInfoBox(
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                text: 'Pesanan cetak sudah selesai dikonfirmasi.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  final FrontOfficePrintOrderModel order;
  final Color statusColor;
  final IconData statusIcon;

  const _OrderHeader({
    required this.order,
    required this.statusColor,
    required this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.welcomeCardGradient,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: Colors.white.withOpacity(0.78)),
          ),
          child: const Icon(
            Icons.local_printshop_rounded,
            color: AppColors.welcomeBlueDark,
            size: 26,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pesanan Cetak #${order.id}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.welcomeBlueDark,
                  fontSize: 17,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                order.packageName.trim().isEmpty
                    ? 'Paket Foto'
                    : order.packageName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.welcomeBlueDark.withOpacity(0.55),
                  fontSize: 12.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _StatusBadge(
          label: order.statusLabel,
          color: statusColor,
          icon: statusIcon,
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 31,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label.trim().isEmpty ? '-' : label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientSummaryPanel extends StatelessWidget {
  final FrontOfficePrintOrderModel order;
  final String Function(int value) currency;

  const _ClientSummaryPanel({required this.order, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        gradient: AppColors.welcomeCardGradient,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.white.withOpacity(0.78)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _CompactInfo(
                  icon: Icons.person_rounded,
                  label: 'Klien',
                  value: order.clientName,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompactInfo(
                  icon: Icons.phone_rounded,
                  label: 'No HP',
                  value: order.clientPhone.isEmpty ? '-' : order.clientPhone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _CompactInfo(
                  icon: Icons.local_shipping_rounded,
                  label: 'Metode',
                  value: order.deliveryMethodLabel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompactInfo(
                  icon: Icons.photo_size_select_actual_rounded,
                  label: 'Jumlah',
                  value: '${order.quantity} cetakan',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _TotalAmountBox(total: currency(order.totalAmount)),
        ],
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
    final display = value.trim().isEmpty ? '-' : value.trim();

    return Container(
      constraints: const BoxConstraints(minHeight: 62),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.62),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.86)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.welcomeBlueDark, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.welcomeBlueDark.withOpacity(0.54),
                    fontSize: 9.2,
                    height: 1,
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  display,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.welcomeBlueDark,
                    fontSize: 11.8,
                    height: 1.2,
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

class _TotalAmountBox extends StatelessWidget {
  final String total;

  const _TotalAmountBox({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: AppColors.welcomeBlueDark.withOpacity(0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.welcomeBlueDark.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.payments_rounded,
            color: AppColors.welcomeBlueDark,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Total Pesanan',
              style: TextStyle(
                color: AppColors.welcomeBlueDark.withOpacity(0.66),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            total,
            style: const TextStyle(
              color: AppColors.welcomeBlueDark,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryPanel extends StatelessWidget {
  final FrontOfficePrintOrderModel order;

  const _DeliveryPanel({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warning.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MiniTitleRow(
            icon: Icons.local_shipping_rounded,
            title: 'Data Pengiriman',
            color: AppColors.warning,
          ),
          const SizedBox(height: 10),
          _InlineMeta(
            icon: Icons.person_rounded,
            label: 'Penerima',
            value: order.recipientName.isEmpty ? '-' : order.recipientName,
            color: AppColors.warning,
          ),
          const SizedBox(height: 7),
          _InlineMeta(
            icon: Icons.phone_rounded,
            label: 'HP Penerima',
            value: order.recipientPhone.isEmpty ? '-' : order.recipientPhone,
            color: AppColors.warning,
          ),
          const SizedBox(height: 7),
          _InlineMeta(
            icon: Icons.location_on_rounded,
            label: 'Alamat',
            value: order.deliveryAddress.isEmpty ? '-' : order.deliveryAddress,
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }
}

class _CardSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CardSectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.welcomeBlueDark, size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.welcomeBlueDark,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: AppColors.welcomeBlueDark.withOpacity(0.56),
            fontSize: 11.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PrintItemCard extends StatelessWidget {
  final int index;
  final FrontOfficePrintOrderItemModel item;
  final String Function(int value) currency;

  const _PrintItemCard({
    required this.index,
    required this.item,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final frameColor = item.useFrame ? AppColors.success : AppColors.grey;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: AppColors.welcomeCardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.78)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.welcomeBlueDark.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppColors.welcomeBlueDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.fileName.trim().isEmpty ? '-' : item.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.welcomeBlueDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _SmallBadge(label: item.frameLabel, color: frameColor),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TinyInfo(label: 'Ukuran', value: item.sizeName),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TinyInfo(label: 'Qty', value: '${item.qty}'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TinyInfo(
                  label: 'Subtotal',
                  value: currency(item.lineTotal),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TinyInfo extends StatelessWidget {
  final String label;
  final String value;

  const _TinyInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final display = value.trim().isEmpty ? '-' : value.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.82)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.welcomeBlueDark.withOpacity(0.54),
              fontSize: 8.8,
              letterSpacing: 0.3,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            display,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.welcomeBlueDark,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 27,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CompletionPhotoBox extends StatelessWidget {
  final FrontOfficePrintOrderModel order;

  const _CompletionPhotoBox({required this.order});

  @override
  Widget build(BuildContext context) {
    final url = order.completionPhotoUrl.trim();

    if (url.isEmpty) {
      return Container(
        height: 118,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.welcomeCardGradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.78)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.62),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.image_outlined,
                color: AppColors.welcomeBlueDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada foto cetakan selesai',
              style: TextStyle(
                color: AppColors.welcomeBlueDark.withOpacity(0.64),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.welcomeCardDeep),
      ),
      child: Image.network(
        url,
        height: 170,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 118,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: AppColors.welcomeCardGradient,
            ),
            child: const Text(
              'Gambar tidak bisa dimuat',
              style: TextStyle(
                color: AppColors.welcomeBlueDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MiniTitleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _MiniTitleRow({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineMeta extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InlineMeta({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final display = value.trim().isEmpty ? '-' : value.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 7),
        Text(
          '$label: ',
          style: TextStyle(
            color: color.withOpacity(0.66),
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        Expanded(
          child: Text(
            display,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              height: 1.35,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniInfoBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _MiniInfoBox({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final display = text.trim().isEmpty ? '-' : text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.13)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              display,
              style: TextStyle(
                color: color,
                height: 1.35,
                fontSize: 11.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 90, bottom: 90),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.welcomeBlueDark),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return _StateCard(
      icon: Icons.error_outline_rounded,
      title: 'Data gagal dimuat',
      message: message,
      color: AppColors.danger,
    );
  }
}

class _EmptyPrintState extends StatelessWidget {
  const _EmptyPrintState();

  @override
  Widget build(BuildContext context) {
    return const _StateCard(
      icon: Icons.local_printshop_outlined,
      title: 'Belum ada pesanan cetak',
      message: 'Pesanan cetak yang sudah dibayar akan tampil di sini.',
      color: AppColors.welcomeBlueDark,
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.66),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color.withOpacity(0.72),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
