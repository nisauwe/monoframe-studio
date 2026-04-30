import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/photographer_models.dart';
import '../../../data/providers/photographer_provider.dart';

class PhotographerPhotoLinkFormScreen extends StatefulWidget {
  final PhotographerBookingModel booking;

  const PhotographerPhotoLinkFormScreen({super.key, required this.booking});

  @override
  State<PhotographerPhotoLinkFormScreen> createState() =>
      _PhotographerPhotoLinkFormScreenState();
}

class _PhotographerPhotoLinkFormScreenState
    extends State<PhotographerPhotoLinkFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _driveUrlController = TextEditingController();
  final TextEditingController _driveLabelController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final photoLink = widget.booking.photoLink;

    if (photoLink != null) {
      _driveUrlController.text = photoLink.driveUrl;
      _driveLabelController.text = photoLink.driveLabel;
      _notesController.text = photoLink.notes;
    } else {
      _driveLabelController.text = 'Hasil Foto ${widget.booking.clientName}';
    }
  }

  @override
  void dispose() {
    _driveUrlController.dispose();
    _driveLabelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _isValidUrl(String value) {
    final uri = Uri.tryParse(value.trim());

    if (uri == null) return false;

    return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  String _time(String value) {
    final text = value.trim();

    if (text.isEmpty) return '-';

    final parts = text.split(':');

    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }

    return text;
  }

  String _safeText(String? value, {String fallback = '-'}) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? fallback : trimmed;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<PhotographerProvider>();

    final ok = await provider.storePhotoLink(
      bookingId: widget.booking.id,
      driveUrl: _driveUrlController.text.trim(),
      driveLabel: _driveLabelController.text.trim(),
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      _showMessage('Link Google Drive berhasil disimpan');
      Navigator.pop(context);
    } else {
      _showMessage(
        provider.errorMessage ?? 'Gagal menyimpan link Google Drive',
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.light,
      contentPadding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
      labelStyle: TextStyle(
        color: AppColors.welcomeBlueDark.withOpacity(0.70),
        fontWeight: FontWeight.w800,
        fontSize: 12.5,
      ),
      hintStyle: const TextStyle(
        color: AppColors.grey,
        fontWeight: FontWeight.w600,
        fontSize: 12.5,
      ),
      prefixIconColor: AppColors.welcomeBlueDark,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.primaryDark, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotographerProvider>();
    final booking = widget.booking;

    final hasExistingLink = booking.photoLink != null || booking.hasPhotoLink;

    final date = _safeText(booking.bookingDate);
    final time = '${_time(booking.startTime)} - ${_time(booking.endTime)}';

    final locationType = _safeText(
      booking.locationTypeLabel,
      fallback: 'Belum ada tipe',
    );

    final locationName = _safeText(
      booking.locationName,
      fallback: 'Belum ada lokasi',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
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
        child: SafeArea(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            children: [
              _TopBar(
                title: hasExistingLink
                    ? 'Update Link Foto'
                    : 'Upload Link Foto',
                onBack: () => Navigator.pop(context),
              ),

              const SizedBox(height: 14),

              _PhotoLinkHero(
                hasExistingLink: hasExistingLink,
                clientName: booking.clientName,
                packageName: booking.packageName,
              ),

              const SizedBox(height: 18),

              _BookingSnapshotCard(
                clientName: _safeText(booking.clientName, fallback: 'Klien'),
                packageName: _safeText(booking.packageName),
                date: date,
                time: time,
                locationType: locationType,
                locationName: locationName,
                statusLabel: _safeText(booking.statusLabel),
                paymentLabel: _safeText(booking.paymentStatusLabel),
                hasPhotoLink: hasExistingLink,
              ),

              const SizedBox(height: 18),

              const _SectionTitle(
                title: 'Panduan Upload',
                subtitle: 'Pastikan link dapat diakses oleh klien.',
              ),

              const SizedBox(height: 12),

              const _StepInstructionCard(),

              const SizedBox(height: 18),

              const _SectionTitle(
                title: 'Form Link Foto',
                subtitle: 'Masukkan link Google Drive hasil foto klien.',
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.welcomeBlueDark.withOpacity(0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _driveUrlController,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          label: 'Link Google Drive',
                          hint: 'https://drive.google.com/...',
                          icon: Icons.link_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Link Google Drive wajib diisi';
                          }

                          if (!_isValidUrl(value)) {
                            return 'Masukkan URL yang valid';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _driveLabelController,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          label: 'Label Link',
                          hint: 'Contoh: Hasil Foto Anisa',
                          icon: Icons.drive_file_rename_outline_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Label link wajib diisi';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _notesController,
                        maxLines: 4,
                        decoration: _inputDecoration(
                          label: 'Catatan',
                          hint:
                              'Contoh: Semua foto original sudah diupload ke folder ini.',
                          icon: Icons.notes_rounded,
                        ),
                      ),

                      const SizedBox(height: 16),

                      _AccessWarningBox(hasExistingLink: hasExistingLink),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: provider.isSubmitting ? null : _submit,
                          icon: provider.isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  hasExistingLink
                                      ? Icons.update_rounded
                                      : Icons.save_rounded,
                                  size: 19,
                                ),
                          label: Text(
                            provider.isSubmitting
                                ? 'Menyimpan...'
                                : hasExistingLink
                                ? 'Update Link Google Drive'
                                : 'Simpan Link Google Drive',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColors.welcomeBlueDark,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.welcomeBlueDark
                                .withOpacity(0.42),
                            disabledForegroundColor: Colors.white.withOpacity(
                              0.74,
                            ),
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (provider.errorMessage != null) ...[
                const SizedBox(height: 12),
                _ErrorMessageBox(message: provider.errorMessage!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _TopBar({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.welcomeBlueDark,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.dark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoLinkHero extends StatelessWidget {
  final bool hasExistingLink;
  final String clientName;
  final String packageName;

  const _PhotoLinkHero({
    required this.hasExistingLink,
    required this.clientName,
    required this.packageName,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = hasExistingLink ? 'Update Link' : 'Upload Baru';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.welcomeDarkGradient,
        borderRadius: BorderRadius.circular(28),
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
            right: -34,
            top: -40,
            child: Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.11),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 32,
            bottom: -48,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(color: Colors.white.withOpacity(0.20)),
                  ),
                  child: const Icon(
                    Icons.cloud_upload_rounded,
                    color: Colors.white,
                    size: 31,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upload Hasil Foto',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '${clientName.trim().isEmpty ? 'Klien' : clientName} • ${packageName.trim().isEmpty ? 'Paket Foto' : packageName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.74),
                          fontSize: 12.8,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasExistingLink
                                  ? Icons.update_rounded
                                  : Icons.add_link_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              statusText,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingSnapshotCard extends StatelessWidget {
  final String clientName;
  final String packageName;
  final String date;
  final String time;
  final String locationType;
  final String locationName;
  final String statusLabel;
  final String paymentLabel;
  final bool hasPhotoLink;

  const _BookingSnapshotCard({
    required this.clientName,
    required this.packageName,
    required this.date,
    required this.time,
    required this.locationType,
    required this.locationName,
    required this.statusLabel,
    required this.paymentLabel,
    required this.hasPhotoLink,
  });

  Color _statusColor(String value) {
    final text = value.toLowerCase();

    if (text.contains('selesai') ||
        text.contains('done') ||
        text.contains('completed')) {
      return AppColors.success;
    }

    if (text.contains('batal') ||
        text.contains('cancel') ||
        text.contains('ditolak')) {
      return AppColors.danger;
    }

    return AppColors.primaryDark;
  }

  Color _paymentColor(String value) {
    final text = value.toLowerCase();

    if (text.contains('lunas') ||
        text.contains('paid') ||
        text.contains('sudah bayar')) {
      return AppColors.success;
    }

    if (text.contains('dp')) {
      return AppColors.primaryDark;
    }

    if (text.contains('belum') ||
        text.contains('unpaid') ||
        text.contains('menunggu')) {
      return AppColors.warning;
    }

    return AppColors.primaryDark;
  }

  @override
  Widget build(BuildContext context) {
    final photoColor = hasPhotoLink ? AppColors.success : AppColors.warning;
    final statusColor = _statusColor(statusLabel);
    final paymentColor = _paymentColor(paymentLabel);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: AppColors.welcomeCardGradient,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: AppColors.white.withOpacity(0.78)),
                ),
                child: const Icon(
                  Icons.photo_camera_rounded,
                  color: AppColors.welcomeBlueDark,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName.trim().isEmpty ? 'Klien' : clientName,
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
                      packageName.trim().isEmpty ? '-' : packageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.welcomeBlueDark.withOpacity(0.56),
                        fontSize: 12.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _StatusPaymentPill(
                  value: paymentLabel,
                  color: paymentColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatusPaymentPill(
                  value: statusLabel,
                  color: statusColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          Row(
            children: [
              Expanded(
                child: _CompactInfo(
                  icon: Icons.calendar_month_rounded,
                  label: 'Tanggal',
                  value: date,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompactInfo(
                  icon: Icons.schedule_rounded,
                  label: 'Jam',
                  value: time,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _CompactInfo(
                  icon: Icons.place_rounded,
                  label: 'Tipe Lokasi',
                  value: locationType,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompactInfo(
                  icon: Icons.location_on_rounded,
                  label: 'Nama Lokasi',
                  value: locationName,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: photoColor.withOpacity(0.09),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: photoColor.withOpacity(0.14)),
            ),
            child: Row(
              children: [
                Icon(
                  hasPhotoLink
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_upload_rounded,
                  color: photoColor,
                  size: 19,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    hasPhotoLink
                        ? 'Link hasil foto sudah pernah diupload.'
                        : 'Booking ini belum memiliki link hasil foto.',
                    style: TextStyle(
                      color: photoColor,
                      fontSize: 11.8,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                    ),
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

class _StatusPaymentPill extends StatelessWidget {
  final String value;
  final Color color;

  const _StatusPaymentPill({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final display = value.trim().isEmpty ? '-' : value.trim();

    return Container(
      height: 42,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18), width: 1.2),
      ),
      child: Text(
        display,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 13,
          height: 1,
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
    final display = value.trim().isEmpty ? '-' : value.trim();

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        gradient: AppColors.welcomeCardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withOpacity(0.78)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.welcomeBlueDark, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.welcomeBlueDark.withOpacity(0.54),
                    fontSize: 9.4,
                    height: 1,
                    letterSpacing: 0.5,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 38,
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
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 12,
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

class _StepInstructionCard extends StatelessWidget {
  const _StepInstructionCard();

  @override
  Widget build(BuildContext context) {
    const steps = [
      _StepData(
        icon: Icons.cloud_upload_outlined,
        title: 'Upload ke Google Drive',
        description: 'Masukkan semua file hasil foto ke folder klien.',
      ),
      _StepData(
        icon: Icons.lock_open_rounded,
        title: 'Atur Akses Link',
        description: 'Pastikan link dapat dibuka oleh klien.',
      ),
      _StepData(
        icon: Icons.link_rounded,
        title: 'Paste Link di Form',
        description: 'Simpan link agar tracking klien berubah.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: List.generate(steps.length, (index) {
          final step = steps[index];

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == steps.length - 1 ? 0 : 10,
            ),
            child: _StepRow(
              number: index + 1,
              icon: step.icon,
              title: step.title,
              description: step.description,
            ),
          );
        }),
      ),
    );
  }
}

class _StepData {
  final IconData icon;
  final String title;
  final String description;

  const _StepData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _StepRow extends StatelessWidget {
  final int number;
  final IconData icon;
  final String title;
  final String description;

  const _StepRow({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        gradient: AppColors.welcomeCardGradient,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.white.withOpacity(0.78)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.welcomeBlueDark.withOpacity(0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColors.welcomeBlueDark, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number. $title',
                  style: const TextStyle(
                    color: AppColors.welcomeBlueDark,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.welcomeBlueDark.withOpacity(0.58),
                    height: 1.28,
                    fontSize: 11.4,
                    fontWeight: FontWeight.w700,
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

class _AccessWarningBox extends StatelessWidget {
  final bool hasExistingLink;

  const _AccessWarningBox({required this.hasExistingLink});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.09),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.warning.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.warning,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasExistingLink
                  ? 'Link lama akan diganti dengan link baru setelah tombol update ditekan.'
                  : 'Setelah link disimpan, tracking klien akan bergerak ke tahap berikutnya.',
              style: const TextStyle(
                color: AppColors.warning,
                height: 1.35,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorMessageBox extends StatelessWidget {
  final String message;

  const _ErrorMessageBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
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
