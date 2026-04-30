import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/editor_edit_request_model.dart';
import '../../../data/providers/editor_provider.dart';
import 'editor_complete_form_screen.dart';

class EditorTaskDetailScreen extends StatefulWidget {
  final int editRequestId;

  const EditorTaskDetailScreen({super.key, required this.editRequestId});

  @override
  State<EditorTaskDetailScreen> createState() => _EditorTaskDetailScreenState();
}

class _EditorTaskDetailScreenState extends State<EditorTaskDetailScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EditorProvider>().fetchEditRequestDetail(
        editRequestId: widget.editRequestId,
      );
    });
  }

  Future<void> _refresh() {
    return context.read<EditorProvider>().fetchEditRequestDetail(
      editRequestId: widget.editRequestId,
    );
  }

  Future<void> _openUrl(String url) async {
    final cleanUrl = url.trim();

    if (cleanUrl.isEmpty) {
      _showMessage('Link belum tersedia');
      return;
    }

    final uri = Uri.tryParse(cleanUrl);

    if (uri == null || !uri.hasScheme) {
      _showMessage('Link tidak valid');
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!mounted) return;

    if (!opened) {
      _showMessage('Tidak bisa membuka link');
    }
  }

  Future<void> _startEdit(EditorEditRequestModel item) async {
    final provider = context.read<EditorProvider>();

    final ok = await provider.startEdit(editRequestId: item.id);

    if (!mounted) return;

    if (ok) {
      _showMessage('Pekerjaan edit dimulai');
      await _refresh();
    } else {
      _showMessage(provider.errorMessage ?? 'Gagal memulai pekerjaan edit');
    }
  }

  Future<void> _openCompleteForm(EditorEditRequestModel item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditorCompleteFormScreen(editRequest: item),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _refresh();
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Color _statusColor(EditorEditRequestModel item) {
    if (item.isCompleted) return AppColors.success;
    return AppColors.primaryDark;
  }

  IconData _statusIcon(EditorEditRequestModel item) {
    if (item.isCompleted) return Icons.check_circle_rounded;
    if (item.isInProgress) return Icons.auto_fix_high_rounded;
    return Icons.pending_actions_rounded;
  }

  String _safe(String value, {String fallback = '-'}) {
    final clean = value.trim();
    return clean.isEmpty ? fallback : clean;
  }

  String _time(String value) {
    final clean = value.trim();

    if (clean.isEmpty) return '-';

    final parts = clean.split(':');

    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }

    return clean;
  }

  String _deadlineDateOnly(EditorEditRequestModel item) {
    final formatted = item.formattedEditDeadline.trim();

    if (formatted.isEmpty || formatted == '-') return '-';

    if (formatted.contains(',')) {
      final dateOnly = formatted.split(',').first.trim();
      if (dateOnly.isNotEmpty) return dateOnly;
    }

    final raw = item.editDeadlineAt.trim();

    if (raw.isNotEmpty) {
      if (raw.contains('T')) {
        final dateOnly = raw.split('T').first.trim();
        if (dateOnly.isNotEmpty) return dateOnly;
      }

      if (raw.contains(' ')) {
        final dateOnly = raw.split(' ').first.trim();
        if (dateOnly.isNotEmpty) return dateOnly;
      }
    }

    return formatted.replaceAll(RegExp(r'\s+\d{1,2}:\d{2}.*'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();
    final item = provider.selectedEditRequest;

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
          child: RefreshIndicator(
            color: AppColors.primaryDark,
            backgroundColor: AppColors.light,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 34),
              children: [
                _TopBar(
                  title: 'Detail Edit',
                  onBack: () => Navigator.pop(context),
                ),
                const SizedBox(height: 14),

                if (provider.isLoading && item == null)
                  const _LoadingState()
                else if (item == null)
                  _ErrorState(
                    message:
                        provider.errorMessage ??
                        'Detail pekerjaan tidak ditemukan',
                    onRetry: _refresh,
                  )
                else ...[
                  _DetailHero(
                    item: item,
                    statusColor: _statusColor(item),
                    statusIcon: _statusIcon(item),
                  ),

                  const SizedBox(height: 16),

                  _ActionProgressCard(
                    item: item,
                    statusColor: _statusColor(item),
                    statusIcon: _statusIcon(item),
                  ),

                  const SizedBox(height: 18),

                  const _SectionTitle(
                    title: 'Informasi Klien',
                    subtitle: 'Data klien yang meminta hasil edit foto.',
                  ),
                  const SizedBox(height: 12),

                  _InfoCard(
                    children: [
                      _InfoGridRow(
                        left: _CompactInfo(
                          icon: Icons.person_rounded,
                          label: 'Nama Klien',
                          value: _safe(item.clientName, fallback: 'Klien'),
                        ),
                        right: _CompactInfo(
                          icon: Icons.phone_rounded,
                          label: 'Nomor HP',
                          value: _safe(item.clientPhone),
                        ),
                      ),
                      if (item.client?.email.isNotEmpty == true) ...[
                        const SizedBox(height: 10),
                        _WideInfo(
                          icon: Icons.email_rounded,
                          label: 'Email',
                          value: item.client!.email,
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 18),

                  const _SectionTitle(
                    title: 'Informasi Booking',
                    subtitle:
                        'Detail paket, jadwal foto, lokasi, dan deadline.',
                  ),
                  const SizedBox(height: 12),

                  _InfoCard(
                    children: [
                      _InfoGridRow(
                        left: _CompactInfo(
                          icon: Icons.photo_camera_rounded,
                          label: 'Paket',
                          value: _safe(item.packageName),
                        ),
                        right: _CompactInfo(
                          icon: Icons.calendar_today_rounded,
                          label: 'Deadline',
                          value: _deadlineDateOnly(item),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _InfoGridRow(
                        left: _CompactInfo(
                          icon: Icons.calendar_month_rounded,
                          label: 'Tanggal Foto',
                          value: _safe(item.booking?.bookingDate ?? '-'),
                        ),
                        right: _CompactInfo(
                          icon: Icons.schedule_rounded,
                          label: 'Jam Foto',
                          value:
                              '${_time(item.booking?.startTime ?? '')} - ${_time(item.booking?.endTime ?? '')}',
                        ),
                      ),
                      const SizedBox(height: 10),
                      _InfoGridRow(
                        left: _CompactInfo(
                          icon: Icons.location_on_rounded,
                          label: 'Lokasi',
                          value: _safe(item.booking?.locationName ?? '-'),
                        ),
                        right: _CompactInfo(
                          icon: Icons.hourglass_bottom_rounded,
                          label: 'Sisa Hari',
                          value: item.remainingDays == null
                              ? '-'
                              : '${item.remainingDays} hari',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  const _SectionTitle(
                    title: 'Link Foto Original',
                    subtitle: 'Buka link foto original sebelum mulai mengedit.',
                  ),
                  const SizedBox(height: 12),

                  _LinkCard(
                    title: item.originalPhotoDriveLabel.isEmpty
                        ? 'Link Foto Original'
                        : item.originalPhotoDriveLabel,
                    url: item.originalPhotoDriveUrl,
                    icon: Icons.photo_library_rounded,
                    buttonLabel: 'Buka Link Foto',
                    onOpen: item.originalPhotoDriveUrl.isEmpty
                        ? null
                        : () => _openUrl(item.originalPhotoDriveUrl),
                  ),

                  const SizedBox(height: 18),

                  const _SectionTitle(
                    title: 'Daftar File Edit',
                    subtitle: 'File pilihan klien yang harus diedit.',
                  ),
                  const SizedBox(height: 12),

                  _FileListCard(files: item.selectedFiles),

                  if (item.requestNotes.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const _SectionTitle(
                      title: 'Catatan Klien',
                      subtitle: 'Instruksi tambahan dari klien untuk editor.',
                    ),
                    const SizedBox(height: 12),
                    _MessageBox(
                      color: AppColors.primaryDark,
                      icon: Icons.notes_rounded,
                      text: item.requestNotes,
                    ),
                  ],

                  if (item.isCompleted) ...[
                    const SizedBox(height: 18),
                    const _SectionTitle(
                      title: 'Hasil Edit',
                      subtitle: 'Link hasil edit yang sudah dikirim ke klien.',
                    ),
                    const SizedBox(height: 12),
                    _LinkCard(
                      title: item.resultDriveLabel.isEmpty
                          ? 'Link Hasil Edit'
                          : item.resultDriveLabel,
                      url: item.resultDriveUrl,
                      icon: Icons.cloud_done_rounded,
                      buttonLabel: 'Buka Hasil Edit',
                      onOpen: item.resultDriveUrl.isEmpty
                          ? null
                          : () => _openUrl(item.resultDriveUrl),
                    ),
                    if (item.editorNotes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _MessageBox(
                        color: AppColors.success,
                        icon: Icons.task_alt_rounded,
                        text: item.editorNotes,
                      ),
                    ],
                  ],

                  if (item.canStart || item.canComplete) ...[
                    const SizedBox(height: 20),
                    _EditorActionPanel(
                      item: item,
                      isSubmitting: provider.isSubmitting,
                      onStart: () => _startEdit(item),
                      onComplete: () => _openCompleteForm(item),
                    ),
                  ],

                  const SizedBox(height: 14),

                  const _NoticeCard(),
                ],
              ],
            ),
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
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(17),
            child: Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.welcomeBlueDark.withOpacity(0.045),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.primaryDark,
                size: 24,
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
              fontSize: 21,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailHero extends StatelessWidget {
  final EditorEditRequestModel item;
  final Color statusColor;
  final IconData statusIcon;

  const _DetailHero({
    required this.item,
    required this.statusColor,
    required this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    final remainingText = item.remainingDays == null
        ? '-'
        : '${item.remainingDays}';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.welcomeDarkGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.20),
            blurRadius: 24,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -36,
            child: Container(
              height: 116,
              width: 116,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            right: 28,
            bottom: -48,
            child: Container(
              height: 112,
              width: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withOpacity(0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: AppColors.white.withOpacity(0.22),
                          width: 1.1,
                        ),
                      ),
                      child: Icon(statusIcon, color: AppColors.white, size: 25),
                    ),
                    const SizedBox(width: 11),
                    const Expanded(
                      child: Text(
                        'Request Edit',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: AppColors.white.withOpacity(0.18),
                          ),
                        ),
                        child: Text(
                          item.statusLabel.trim().isEmpty
                              ? '-'
                              : item.statusLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  item.clientName.trim().isEmpty ? 'Klien' : item.clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 28,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.packageName.trim().isEmpty ? '-' : item.packageName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white.withOpacity(0.76),
                    fontSize: 13,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HeroMetricBox(
                        icon: Icons.photo_library_rounded,
                        label: 'File Edit',
                        value: '${item.selectedFiles.length}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroMetricBox(
                        icon: Icons.hourglass_bottom_rounded,
                        label: 'Sisa Hari',
                        value: remainingText,
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

class _HeroMetricBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroMetricBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white.withOpacity(0.22), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.white, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.white.withOpacity(0.88),
                fontSize: 10.5,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value.trim().isEmpty ? '-' : value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 19,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionProgressCard extends StatelessWidget {
  final EditorEditRequestModel item;
  final Color statusColor;
  final IconData statusIcon;

  const _ActionProgressCard({
    required this.item,
    required this.statusColor,
    required this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.045),
            blurRadius: 16,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withOpacity(0.09),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryDark.withOpacity(0.12),
              ),
            ),
            child: Icon(statusIcon, color: AppColors.primaryDark, size: 23),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Pekerjaan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.dark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.statusLabel.trim().isEmpty ? '-' : item.statusLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 11.5,
                    height: 1.35,
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

class _EditorActionPanel extends StatelessWidget {
  final EditorEditRequestModel item;
  final bool isSubmitting;
  final VoidCallback onStart;
  final VoidCallback onComplete;

  const _EditorActionPanel({
    required this.item,
    required this.isSubmitting,
    required this.onStart,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final bool canStart = item.canStart;
    final bool canComplete = item.canComplete;

    final String title = canStart
        ? 'Mulai proses editing'
        : 'Upload hasil edit';
    final String subtitle = canStart
        ? 'Tekan tombol di bawah jika kamu sudah siap mengerjakan request ini.'
        : 'Masukkan link Google Drive hasil edit dan selesaikan pekerjaan.';

    final IconData icon = canStart
        ? Icons.play_arrow_rounded
        : Icons.cloud_upload_rounded;
    final String buttonText = canStart ? 'Mulai Editing' : 'Upload Hasil Edit';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.055),
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
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  gradient: AppColors.welcomeDarkGradient,
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withOpacity(0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Icon(icon, color: AppColors.white, size: 24),
              ),
              const SizedBox(width: 11),
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
                        fontSize: 14.8,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 11.3,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PrimaryActionButton(
            label: isSubmitting ? 'Memproses...' : buttonText,
            icon: icon,
            isLoading: isSubmitting,
            onTap: isSubmitting
                ? null
                : canStart
                ? onStart
                : canComplete
                ? onComplete
                : null,
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onTap;

  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;

    return Opacity(
      opacity: enabled ? 1 : 0.60,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Ink(
            height: 48,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: enabled ? AppColors.welcomeDarkGradient : null,
              color: enabled ? null : AppColors.grey.withOpacity(0.30),
              borderRadius: BorderRadius.circular(17),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppColors.primaryDark.withOpacity(0.20),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                else
                  Icon(icon, color: AppColors.white, size: 20),
                const SizedBox(width: 9),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 13.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
          height: 30,
          width: 5,
          decoration: BoxDecoration(
            gradient: AppColors.welcomeDarkGradient,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.dark,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
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

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
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
      child: Column(children: children),
    );
  }
}

class _InfoGridRow extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _InfoGridRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 10),
        Expanded(child: right),
      ],
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
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        gradient: AppColors.welcomeCardGradient,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.white.withOpacity(0.76)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.welcomeBlueDark, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.welcomeBlueDark.withOpacity(0.54),
                    fontSize: 9.8,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.trim().isEmpty ? '-' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.welcomeBlueDark,
                    fontSize: 11.2,
                    height: 1,
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

class _WideInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WideInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        gradient: AppColors.welcomeCardGradient,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.white.withOpacity(0.76)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.welcomeBlueDark, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.welcomeBlueDark.withOpacity(0.54),
                    fontSize: 9.8,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.trim().isEmpty ? '-' : value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.welcomeBlueDark,
                    fontSize: 11.2,
                    height: 1.25,
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

class _LinkCard extends StatelessWidget {
  final String title;
  final String url;
  final IconData icon;
  final String buttonLabel;
  final VoidCallback? onOpen;

  const _LinkCard({
    required this.title,
    required this.url,
    required this.icon,
    required this.buttonLabel,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final hasLink = url.trim().isNotEmpty;

    return Container(
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
            decoration: BoxDecoration(
              gradient: AppColors.welcomeCardGradient,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.white.withOpacity(0.76)),
            ),
            child: _WideInfoPlain(
              icon: icon,
              label: title,
              value: hasLink ? url : 'Link belum tersedia',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(
                buttonLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                side: const BorderSide(color: AppColors.border),
                backgroundColor: AppColors.white.withOpacity(0.55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                textStyle: const TextStyle(
                  fontSize: 12.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WideInfoPlain extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WideInfoPlain({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.welcomeBlueDark, size: 17),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.trim().isEmpty ? '-' : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.welcomeBlueDark.withOpacity(0.54),
                  fontSize: 10,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.trim().isEmpty ? '-' : value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.welcomeBlueDark,
                  fontSize: 11.3,
                  height: 1.25,
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

class _FileListCard extends StatelessWidget {
  final List<String> files;

  const _FileListCard({required this.files});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SmallInfoTitle(
            icon: Icons.folder_copy_rounded,
            text: '${files.length} file dipilih klien',
          ),
          const SizedBox(height: 10),
          if (files.isEmpty)
            const _SmallInfoBox(
              icon: Icons.folder_off_rounded,
              text: 'Belum ada file dipilih',
            )
          else
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: files.map((file) => _FileChip(label: file)).toList(),
            ),
        ],
      ),
    );
  }
}

class _SmallInfoTitle extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SmallInfoTitle({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.welcomeBlueDark, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.welcomeBlueDark.withOpacity(0.58),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SmallInfoBox extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SmallInfoBox({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.grey, size: 17),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FileChip extends StatelessWidget {
  final String label;

  const _FileChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label.trim().isEmpty ? '-' : label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.welcomeBlueDark,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
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
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text.trim().isEmpty ? '-' : text,
              style: TextStyle(
                color: color,
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

class _NoticeCard extends StatelessWidget {
  const _NoticeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryDark.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primaryDark,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pastikan link Google Drive dapat dibuka sebelum mengirim hasil edit ke klien.',
              style: TextStyle(
                color: AppColors.primaryDark.withOpacity(0.88),
                fontWeight: FontWeight.w700,
                fontSize: 11.8,
                height: 1.35,
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
    return Container(
      height: 280,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: AppColors.primaryDark),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 70),
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.danger.withOpacity(0.14)),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.74),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 34,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Detail gagal dimuat',
            style: TextStyle(
              color: AppColors.danger,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.danger,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: BorderSide(color: AppColors.danger.withOpacity(0.22)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
