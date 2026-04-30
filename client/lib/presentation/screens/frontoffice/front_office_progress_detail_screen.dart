import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/providers/front_office_provider.dart';

class FrontOfficeProgressDetailScreen extends StatefulWidget {
  final int bookingId;
  final String title;

  const FrontOfficeProgressDetailScreen({
    super.key,
    required this.bookingId,
    required this.title,
  });

  @override
  State<FrontOfficeProgressDetailScreen> createState() =>
      _FrontOfficeProgressDetailScreenState();
}

class _FrontOfficeProgressDetailScreenState
    extends State<FrontOfficeProgressDetailScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FrontOfficeProvider>().fetchProgressDetail(
        bookingId: widget.bookingId,
      );
    });
  }

  Future<void> _refresh() {
    return context.read<FrontOfficeProvider>().fetchProgressDetail(
      bookingId: widget.bookingId,
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    return <dynamic>[];
  }

  String _text(dynamic value, [String fallback = '-']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _normalizeTime(dynamic value) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty) return '-';

    final parts = text.split(':');

    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }

    return text;
  }

  Map<String, dynamic> _currentTracking(Map<String, dynamic> detail) {
    final trackings = _asList(detail['trackings']);

    for (final item in trackings) {
      final map = _asMap(item);
      final status = map['status']?.toString().toLowerCase() ?? '';

      if (status == 'current' || status == 'in_progress') {
        return map;
      }
    }

    if (trackings.isNotEmpty) {
      return _asMap(trackings.last);
    }

    return <String, dynamic>{};
  }

  String _packageName(Map<String, dynamic> detail) {
    final package = _asMap(detail['package']);

    return _text(package['name'] ?? detail['package_name'], 'Paket Foto');
  }

  String _clientName(Map<String, dynamic> detail) {
    final clientUser = _asMap(detail['client_user']);

    return _text(detail['client_name'] ?? clientUser['name'], widget.title);
  }

  String _photographerName(Map<String, dynamic> detail) {
    final photographer = _asMap(detail['photographer_user']);

    return _text(
      detail['photographer_name'] ?? photographer['name'],
      'Belum di-assign',
    );
  }

  String _editorStatus(Map<String, dynamic> detail) {
    final editRequest = _asMap(detail['edit_request']);

    return _text(
      editRequest['status_label'] ??
          editRequest['status'] ??
          detail['edit_request_status'],
      'Belum ada permintaan edit',
    );
  }

  String _photoLinkText(Map<String, dynamic> detail) {
    final photoLink = _asMap(detail['photo_link']);

    return _text(
      photoLink['client_gallery_url'] ??
          photoLink['drive_url'] ??
          photoLink['url'] ??
          photoLink['link'] ??
          detail['photo_link_url'],
      'Belum ada link foto',
    );
  }

  String _paymentLabel(Map<String, dynamic> detail) {
    final explicit = detail['payment_status_label']?.toString().trim();

    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }

    if (detail['is_fully_paid'] == true) return 'Lunas';
    if (detail['is_dp_paid'] == true) return 'DP Terbayar';

    final payment = _asMap(detail['latest_payment'] ?? detail['payment']);
    final transactionStatus =
        payment['transaction_status']?.toString().toLowerCase() ?? '';

    if (transactionStatus == 'settlement' ||
        transactionStatus == 'capture' ||
        transactionStatus == 'paid') {
      return 'Lunas';
    }

    if (transactionStatus == 'pending') {
      return 'Menunggu Pembayaran';
    }

    if (transactionStatus == 'deny' ||
        transactionStatus == 'expire' ||
        transactionStatus == 'cancel' ||
        transactionStatus == 'failed') {
      return 'Pembayaran Gagal';
    }

    final status = detail['payment_status']?.toString().toLowerCase() ?? '';

    switch (status) {
      case 'dp_paid':
      case 'partially_paid':
        return 'DP Terbayar';
      case 'paid':
      case 'fully_paid':
        return 'Lunas';
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'failed':
        return 'Pembayaran Gagal';
      case 'unpaid':
        return 'Belum Bayar';
      default:
        return status.isEmpty ? 'Belum Bayar' : status;
    }
  }

  Color _paymentColor(Map<String, dynamic> detail) {
    final label = _paymentLabel(detail).toLowerCase();

    if (label.contains('lunas')) return AppColors.success;
    if (label.contains('dp')) return AppColors.warning;
    if (label.contains('gagal')) return AppColors.danger;
    if (label.contains('menunggu')) return AppColors.warning;

    return AppColors.grey;
  }

  String _stageLabel(Map<String, dynamic> detail) {
    final current = _currentTracking(detail);

    return _text(
      current['stage_name'] ?? detail['current_stage_name'],
      'Assign Fotografer',
    );
  }

  Color _stageColor(Map<String, dynamic> detail) {
    final label = _stageLabel(detail).toLowerCase();

    if (label.contains('assign')) return _ProgressDetailPalette.midBlue;
    if (label.contains('foto') || label.contains('photo')) {
      return _ProgressDetailPalette.midBlue;
    }
    if (label.contains('edit')) return _ProgressDetailPalette.lightBlue;
    if (label.contains('cetak')) return AppColors.warning;
    if (label.contains('review') || label.contains('selesai')) {
      return AppColors.success;
    }

    return _ProgressDetailPalette.darkBlue;
  }

  IconData _stageIcon(Map<String, dynamic> detail) {
    final label = _stageLabel(detail).toLowerCase();

    if (label.contains('assign')) return Icons.assignment_ind_rounded;
    if (label.contains('foto') || label.contains('photo')) {
      return Icons.photo_camera_rounded;
    }
    if (label.contains('edit')) return Icons.auto_fix_high_rounded;
    if (label.contains('cetak')) return Icons.print_rounded;
    if (label.contains('review') || label.contains('selesai')) {
      return Icons.check_circle_rounded;
    }

    return Icons.track_changes_rounded;
  }

  Color _timelineColor(String status) {
    final value = status.toLowerCase();

    if (value == 'done' || value == 'completed' || value == 'finish') {
      return AppColors.success;
    }

    if (value == 'current' || value == 'in_progress') {
      return _ProgressDetailPalette.darkBlue;
    }

    return AppColors.grey;
  }

  IconData _timelineIcon(String status) {
    final value = status.toLowerCase();

    if (value == 'done' || value == 'completed' || value == 'finish') {
      return Icons.check_circle_rounded;
    }

    if (value == 'current' || value == 'in_progress') {
      return Icons.radio_button_checked_rounded;
    }

    return Icons.radio_button_unchecked_rounded;
  }

  List<Widget> _detailContent(Map<String, dynamic> detail) {
    final trackings = _asList(detail['trackings']);
    final packageName = _packageName(detail);
    final clientName = _clientName(detail);
    final photographerName = _photographerName(detail);
    final paymentLabel = _paymentLabel(detail);
    final paymentColor = _paymentColor(detail);
    final stageLabel = _stageLabel(detail);
    final stageColor = _stageColor(detail);
    final stageIcon = _stageIcon(detail);

    final bookingDate = _text(detail['booking_date']);
    final startTime = _normalizeTime(detail['start_time']);
    final endTime = _normalizeTime(detail['end_time']);
    final location = _text(detail['location_name'], 'Belum ada lokasi');
    final bookingStatus = _text(detail['status'], 'Belum ada status');
    final notes = _text(detail['notes'], '');

    return [
      _DetailHero(
        clientName: clientName,
        packageName: packageName,
        stageLabel: stageLabel,
        stageColor: stageColor,
        stageIcon: stageIcon,
        paymentLabel: paymentLabel,
        paymentColor: paymentColor,
      ),

      const SizedBox(height: 16),

      _SectionTitle(
        title: 'Detail Booking',
        subtitle: 'Informasi utama jadwal dan layanan klien',
      ),

      const SizedBox(height: 10),

      _InfoPanel(
        children: [
          _InfoItem(
            icon: Icons.calendar_month_rounded,
            label: 'Tanggal',
            value: bookingDate,
          ),
          _InfoItem(
            icon: Icons.schedule_rounded,
            label: 'Jam',
            value: '$startTime - $endTime',
          ),
          _InfoItem(
            icon: Icons.location_on_rounded,
            label: 'Lokasi',
            value: location,
          ),
          _InfoItem(
            icon: Icons.verified_rounded,
            label: 'Status Booking',
            value: bookingStatus,
          ),
        ],
      ),

      const SizedBox(height: 16),

      _SectionTitle(
        title: 'Monitoring Front Office',
        subtitle: 'Pantau fotografer, edit, link foto, dan catatan layanan',
      ),

      const SizedBox(height: 10),

      _MonitoringCard(
        photographerName: photographerName,
        editStatus: _editorStatus(detail),
        photoLinkText: _photoLinkText(detail),
        notes: notes,
      ),

      const SizedBox(height: 16),

      _SectionTitle(
        title: 'Timeline Progress',
        subtitle: 'Alur tracking layanan yang dilihat oleh klien',
      ),

      const SizedBox(height: 10),

      if (trackings.isEmpty)
        const _EmptyTimelineCard()
      else
        _TimelinePanel(
          trackings: trackings,
          timelineColor: _timelineColor,
          timelineIcon: _timelineIcon,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FrontOfficeProvider>();
    final detail = provider.selectedProgressDetail;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: _ProgressDetailPalette.darkBlue,
          backgroundColor: _ProgressDetailPalette.cardLight,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
            children: [
              _TopBar(
                title: 'Detail Progress',
                onBack: () => Navigator.pop(context),
              ),

              const SizedBox(height: 14),

              if (provider.isLoading && detail == null)
                const _LoadingState()
              else if (detail == null)
                _EmptyDetailState(onRefresh: _refresh)
              else
                ..._detailContent(_asMap(detail)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressDetailPalette {
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
                color: _ProgressDetailPalette.darkBlue,
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

class _DetailHero extends StatelessWidget {
  final String clientName;
  final String packageName;
  final String stageLabel;
  final Color stageColor;
  final IconData stageIcon;
  final String paymentLabel;
  final Color paymentColor;

  const _DetailHero({
    required this.clientName,
    required this.packageName,
    required this.stageLabel,
    required this.stageColor,
    required this.stageIcon,
    required this.paymentLabel,
    required this.paymentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: _ProgressDetailPalette.darkGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _ProgressDetailPalette.darkBlue.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -34,
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 28,
            bottom: -46,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.20),
                        ),
                      ),
                      child: Icon(stageIcon, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clientName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            packageName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
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
                      child: _HeroChip(
                        label: stageLabel,
                        color: stageColor,
                        icon: Icons.track_changes_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroChip(
                        label: paymentLabel,
                        color: paymentColor,
                        icon: Icons.payments_rounded,
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

class _HeroChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _HeroChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 39,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
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
          height: 34,
          width: 5,
          decoration: BoxDecoration(
            gradient: _ProgressDetailPalette.darkGradient,
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
                style: const TextStyle(
                  color: AppColors.dark,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
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

class _InfoPanel extends StatelessWidget {
  final List<_InfoItem> children;

  const _InfoPanel({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 13),
      decoration: BoxDecoration(
        gradient: _ProgressDetailPalette.softGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.78)),
        boxShadow: [
          BoxShadow(
            color: _ProgressDetailPalette.darkBlue.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: children[0]),
              const SizedBox(width: 10),
              Expanded(child: children[1]),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(child: children[2]),
              const SizedBox(width: 10),
              Expanded(child: children[3]),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _ProgressDetailPalette.darkBlue, size: 18),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _ProgressDetailPalette.darkBlue.withOpacity(0.54),
                  fontSize: 10,
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
                  color: _ProgressDetailPalette.darkBlue,
                  fontSize: 12,
                  height: 1.1,
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

class _MonitoringCard extends StatelessWidget {
  final String photographerName;
  final String editStatus;
  final String photoLinkText;
  final String notes;

  const _MonitoringCard({
    required this.photographerName,
    required this.editStatus,
    required this.photoLinkText,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _ProgressDetailPalette.cardDeep),
        boxShadow: [
          BoxShadow(
            color: _ProgressDetailPalette.darkBlue.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _MonitoringRow(
            icon: Icons.photo_camera_rounded,
            title: 'Fotografer',
            value: photographerName,
            color: _ProgressDetailPalette.darkBlue,
          ),
          const SizedBox(height: 10),
          _MonitoringRow(
            icon: Icons.auto_fix_high_rounded,
            title: 'Status Edit',
            value: editStatus,
            color: _ProgressDetailPalette.lightBlue,
          ),
          const SizedBox(height: 10),
          _MonitoringRow(
            icon: Icons.link_rounded,
            title: 'Link Foto',
            value: photoLinkText,
            color: AppColors.success,
          ),
          if (notes.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _MessageBox(
              color: AppColors.warning,
              icon: Icons.notes_rounded,
              text: notes,
            ),
          ],
        ],
      ),
    );
  }
}

class _MonitoringRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _MonitoringRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.trim().isEmpty ? '-' : value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
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

class _TimelinePanel extends StatelessWidget {
  final List<dynamic> trackings;
  final Color Function(String status) timelineColor;
  final IconData Function(String status) timelineIcon;

  const _TimelinePanel({
    required this.trackings,
    required this.timelineColor,
    required this.timelineIcon,
  });

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 14, 13, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _ProgressDetailPalette.cardDeep),
        boxShadow: [
          BoxShadow(
            color: _ProgressDetailPalette.darkBlue.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: List.generate(trackings.length, (index) {
          final map = _asMap(trackings[index]);
          final status = map['status']?.toString() ?? '';
          final color = timelineColor(status);

          return _TimelineItem(
            title: map['stage_name']?.toString() ?? '-',
            description: map['description']?.toString() ?? 'Menunggu proses.',
            status: status,
            color: color,
            icon: timelineIcon(status),
            isLast: index == trackings.length - 1,
          );
        }),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String description;
  final String status;
  final Color color;
  final IconData icon;
  final bool isLast;

  const _TimelineItem({
    required this.title,
    required this.description,
    required this.status,
    required this.color,
    required this.icon,
    required this.isLast,
  });

  String get _statusLabel {
    final value = status.toLowerCase();

    if (value == 'done' || value == 'completed' || value == 'finish') {
      return 'Selesai';
    }

    if (value == 'current' || value == 'in_progress') {
      return 'Sedang Berjalan';
    }

    return 'Menunggu';
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 38,
            child: Column(
              children: [
                Container(
                  width: 31,
                  height: 31,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.18)),
                  ),
                  child: Icon(icon, color: color, size: 19),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 10 : 13),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color.withOpacity(0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title.trim().isEmpty ? '-' : title,
                            style: TextStyle(
                              color: color,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _SmallStatusChip(label: _statusLabel, color: color),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      description.trim().isEmpty
                          ? 'Menunggu proses.'
                          : description,
                      style: TextStyle(
                        color: color.withOpacity(0.74),
                        height: 1.35,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallStatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 25,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
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
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(14),
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

class _EmptyTimelineCard extends StatelessWidget {
  const _EmptyTimelineCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        gradient: _ProgressDetailPalette.softGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.78)),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.60),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.timeline_outlined,
              size: 32,
              color: _ProgressDetailPalette.darkBlue,
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'Timeline belum tersedia',
            style: TextStyle(
              color: _ProgressDetailPalette.darkBlue,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tracking layanan akan muncul setelah status booking dibuat atau diperbarui.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ProgressDetailPalette.darkBlue.withOpacity(0.62),
              height: 1.45,
              fontWeight: FontWeight.w600,
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
      padding: EdgeInsets.only(top: 120),
      child: Center(
        child: CircularProgressIndicator(
          color: _ProgressDetailPalette.darkBlue,
        ),
      ),
    );
  }
}

class _EmptyDetailState extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyDetailState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 90),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
        decoration: BoxDecoration(
          gradient: _ProgressDetailPalette.softGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.78)),
        ),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.60),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 34,
                color: _ProgressDetailPalette.darkBlue,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Detail tidak ditemukan',
              style: TextStyle(
                color: _ProgressDetailPalette.darkBlue,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Data progress booking ini belum tersedia atau gagal dimuat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ProgressDetailPalette.darkBlue.withOpacity(0.62),
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
                foregroundColor: _ProgressDetailPalette.darkBlue,
                side: const BorderSide(color: _ProgressDetailPalette.cardDeep),
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
