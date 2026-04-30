import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/front_office_models.dart';
import '../../../data/providers/front_office_provider.dart';

class FrontOfficeAssignScreen extends StatefulWidget {
  const FrontOfficeAssignScreen({super.key});

  @override
  State<FrontOfficeAssignScreen> createState() =>
      _FrontOfficeAssignScreenState();
}

class _FrontOfficeAssignScreenState extends State<FrontOfficeAssignScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FrontOfficeProvider>().fetchAssignableBookings();
    });
  }

  Color _paymentColor(FoBookingModel booking) {
    final status = booking.paymentStatus.toLowerCase();
    final label = booking.paymentStatusLabel.toLowerCase();

    if (status.contains('paid') ||
        status.contains('settlement') ||
        label.contains('lunas')) {
      return AppColors.success;
    }

    if (status.contains('dp') ||
        status.contains('partial') ||
        label.contains('dp')) {
      return _AssignPalette.midBlue;
    }

    if (status.contains('failed') || label.contains('gagal')) {
      return AppColors.danger;
    }

    return AppColors.warning;
  }

  IconData _paymentIcon(FoBookingModel booking) {
    final status = booking.paymentStatus.toLowerCase();
    final label = booking.paymentStatusLabel.toLowerCase();

    if (status.contains('paid') ||
        status.contains('settlement') ||
        label.contains('lunas')) {
      return Icons.check_circle_rounded;
    }

    if (status.contains('dp') ||
        status.contains('partial') ||
        label.contains('dp')) {
      return Icons.verified_rounded;
    }

    if (status.contains('failed') || label.contains('gagal')) {
      return Icons.cancel_rounded;
    }

    return Icons.hourglass_top_rounded;
  }

  Future<void> _openAssignDialog(FoBookingModel booking) async {
    final provider = context.read<FrontOfficeProvider>();

    await provider.fetchAvailablePhotographers(bookingId: booking.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (modalContext) {
        return Consumer<FrontOfficeProvider>(
          builder: (context, provider, _) {
            return _AssignPhotographerSheet(
              booking: booking,
              provider: provider,
              onAssign: (photographer) async {
                final ok = await provider.assignPhotographer(
                  bookingId: booking.id,
                  photographerUserId: photographer.id,
                );

                if (!mounted) return;

                if (ok) {
                  Navigator.pop(modalContext);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fotografer berhasil di-assign'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.errorMessage ?? 'Gagal assign fotografer',
                      ),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FrontOfficeProvider>();

    return SafeArea(
      child: Container(
        color: AppColors.background,
        child: RefreshIndicator(
          color: _AssignPalette.darkBlue,
          backgroundColor: _AssignPalette.cardLight,
          onRefresh: provider.fetchAssignableBookings,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 118),
            children: [
              _AssignHeader(
                totalAssignable: provider.assignableBookings.length,
              ),

              const SizedBox(height: 18),

              if (provider.isLoading && provider.assignableBookings.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 90),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _AssignPalette.darkBlue,
                    ),
                  ),
                )
              else if (provider.assignableBookings.isEmpty)
                _EmptyAssignState(
                  message:
                      provider.errorMessage ??
                      'Booking yang sudah DP atau lunas akan tampil di sini untuk dipilihkan fotografer.',
                  onRefresh: () {
                    context
                        .read<FrontOfficeProvider>()
                        .fetchAssignableBookings();
                  },
                )
              else
                ...provider.assignableBookings.map((booking) {
                  final statusColor = _paymentColor(booking);
                  final statusIcon = _paymentIcon(booking);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AssignBookingCard(
                      booking: booking,
                      statusColor: statusColor,
                      statusIcon: statusIcon,
                      onChoosePhotographer: booking.canAssign
                          ? () => _openAssignDialog(booking)
                          : null,
                    ),
                  );
                }),

              if (provider.errorMessage != null &&
                  provider.assignableBookings.isNotEmpty) ...[
                const SizedBox(height: 4),
                _ErrorMessageBox(message: provider.errorMessage!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignPalette {
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

class _AssignHeader extends StatelessWidget {
  final int totalAssignable;

  const _AssignHeader({required this.totalAssignable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: _AssignPalette.darkGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _AssignPalette.darkBlue.withOpacity(0.16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -32,
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
            bottom: -48,
            child: Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              const _HeaderIcon(),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assign Fotografer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Pilih fotografer untuk booking yang sudah DP atau lunas.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
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
                          const Icon(
                            Icons.assignment_ind_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '$totalAssignable booking perlu assign',
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
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: const Icon(
        Icons.assignment_ind_rounded,
        color: Colors.white,
        size: 29,
      ),
    );
  }
}

class _AssignBookingCard extends StatelessWidget {
  final FoBookingModel booking;
  final Color statusColor;
  final IconData statusIcon;
  final VoidCallback? onChoosePhotographer;

  const _AssignBookingCard({
    required this.booking,
    required this.statusColor,
    required this.statusIcon,
    required this.onChoosePhotographer,
  });

  @override
  Widget build(BuildContext context) {
    final clientName = booking.clientName.trim().isEmpty
        ? 'Klien'
        : booking.clientName.trim();

    final packageName = booking.packageName.trim().isEmpty
        ? 'Paket Foto'
        : booking.packageName.trim();

    final bookingDate = booking.bookingDate.trim().isEmpty
        ? '-'
        : booking.bookingDate.trim();

    final scheduleTime = booking.startTime.trim().isEmpty
        ? '-'
        : '${booking.startTime} - ${booking.endTime}';

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _AssignPalette.cardDeep),
        boxShadow: [
          BoxShadow(
            color: _AssignPalette.darkBlue.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusIconBox(icon: statusIcon, color: statusColor),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AssignPalette.darkBlue,
                        fontSize: 17,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      packageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _AssignPalette.darkBlue.withOpacity(0.58),
                        fontSize: 11.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _StatusChip(
                  label: booking.paymentStatusLabel,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusChip(
                  label: booking.canAssign ? 'Siap Assign' : 'Belum Siap',
                  color: booking.canAssign
                      ? _AssignPalette.darkBlue
                      : AppColors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
            decoration: BoxDecoration(
              gradient: _AssignPalette.softGradient,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: Colors.white.withOpacity(0.76)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _CompactInfo(
                        icon: Icons.calendar_month_rounded,
                        label: 'Tanggal',
                        value: bookingDate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CompactInfo(
                        icon: Icons.schedule_rounded,
                        label: 'Jam',
                        value: scheduleTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _CompactInfo(
                        icon: Icons.photo_library_rounded,
                        label: 'Paket',
                        value: packageName,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CompactInfo(
                        icon: Icons.payments_rounded,
                        label: 'Pembayaran',
                        value: booking.paymentStatusLabel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 43,
            child: ElevatedButton.icon(
              onPressed: onChoosePhotographer,
              icon: const Icon(Icons.photo_camera_rounded, size: 18),
              label: Text(
                booking.canAssign ? 'Pilih Fotografer' : 'Belum Bisa Assign',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: booking.canAssign
                    ? _AssignPalette.darkBlue
                    : AppColors.grey,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: AppColors.grey.withOpacity(0.35),
                disabledForegroundColor: Colors.white.withOpacity(0.86),
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
      ),
    );
  }
}

class _StatusIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _StatusIconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 39,
      height: 39,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Icon(icon, color: color, size: 21),
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
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      alignment: Alignment.center,
      child: Text(
        label.isEmpty ? '-' : label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
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
    return Row(
      children: [
        Icon(icon, color: _AssignPalette.darkBlue, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _AssignPalette.darkBlue.withOpacity(0.54),
                  fontSize: 9.8,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value.isEmpty ? '-' : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _AssignPalette.darkBlue,
                  fontSize: 11.2,
                  height: 1,
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

class _AssignPhotographerSheet extends StatelessWidget {
  final FoBookingModel booking;
  final FrontOfficeProvider provider;
  final Future<void> Function(FoPhotographerModel photographer) onAssign;

  const _AssignPhotographerSheet({
    required this.booking,
    required this.provider,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final clientName = booking.clientName.trim().isEmpty
        ? 'Klien'
        : booking.clientName.trim();

    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: _AssignPalette.cardDeep,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: _AssignPalette.darkGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _AssignPalette.darkBlue.withOpacity(0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.20),
                        ),
                      ),
                      child: const Icon(
                        Icons.photo_camera_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pilih Fotografer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$clientName • ${booking.bookingDate} ${booking.startTime}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.72),
                              fontSize: 12.2,
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
            ),

            const SizedBox(height: 14),

            Flexible(
              child: provider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: _AssignPalette.darkBlue,
                      ),
                    )
                  : provider.availablePhotographers.isEmpty
                  ? _EmptyPhotographerState(
                      message:
                          provider.errorMessage ??
                          'Tidak ada fotografer tersedia pada slot ini.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      shrinkWrap: true,
                      itemCount: provider.availablePhotographers.length,
                      itemBuilder: (context, index) {
                        final photographer =
                            provider.availablePhotographers[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PhotographerOptionCard(
                            photographer: photographer,
                            isSubmitting: provider.isSubmitting,
                            onAssign: () => onAssign(photographer),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotographerOptionCard extends StatelessWidget {
  final FoPhotographerModel photographer;
  final bool isSubmitting;
  final Future<void> Function() onAssign;

  const _PhotographerOptionCard({
    required this.photographer,
    required this.isSubmitting,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final name = photographer.name.trim().isEmpty
        ? 'Fotografer'
        : photographer.name.trim();

    final email = photographer.email.trim().isEmpty
        ? '-'
        : photographer.email.trim();

    final phone = photographer.phone.trim().isEmpty
        ? '-'
        : photographer.phone.trim();

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _AssignPalette.cardDeep),
        boxShadow: [
          BoxShadow(
            color: _AssignPalette.darkBlue.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: _AssignPalette.darkBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _AssignPalette.darkBlue.withOpacity(0.12),
                  ),
                ),
                child: const Icon(
                  Icons.photo_camera_rounded,
                  color: _AssignPalette.darkBlue,
                  size: 23,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AssignPalette.darkBlue,
                        fontSize: 16,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _AssignPalette.darkBlue.withOpacity(0.56),
                        fontSize: 11.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(
                label: photographer.isAvailable ? 'Tersedia' : 'Penuh',
                color: photographer.isAvailable
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
            decoration: BoxDecoration(
              gradient: _AssignPalette.softGradient,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: Colors.white.withOpacity(0.76)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _CompactInfo(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    value: email,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CompactInfo(
                    icon: Icons.phone_rounded,
                    label: 'Telepon',
                    value: phone,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: isSubmitting || !photographer.isAvailable
                  ? null
                  : onAssign,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.assignment_turned_in_rounded, size: 18),
              label: Text(
                isSubmitting ? 'Memproses...' : 'Assign Fotografer',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _AssignPalette.darkBlue,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: AppColors.grey.withOpacity(0.35),
                disabledForegroundColor: Colors.white.withOpacity(0.86),
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
      ),
    );
  }
}

class _EmptyAssignState extends StatelessWidget {
  final String message;
  final VoidCallback onRefresh;

  const _EmptyAssignState({required this.message, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 70),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
        decoration: BoxDecoration(
          gradient: _AssignPalette.softGradient,
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
                Icons.assignment_ind_outlined,
                size: 34,
                color: _AssignPalette.darkBlue,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada booking assign',
              style: TextStyle(
                color: _AssignPalette.darkBlue,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _AssignPalette.darkBlue.withOpacity(0.62),
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
                foregroundColor: _AssignPalette.darkBlue,
                side: const BorderSide(color: _AssignPalette.cardDeep),
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

class _EmptyPhotographerState extends StatelessWidget {
  final String message;

  const _EmptyPhotographerState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        decoration: BoxDecoration(
          gradient: _AssignPalette.softGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.78)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.60),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.no_photography_outlined,
                size: 32,
                color: _AssignPalette.darkBlue,
              ),
            ),
            const SizedBox(height: 13),
            const Text(
              'Fotografer belum tersedia',
              style: TextStyle(
                color: _AssignPalette.darkBlue,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _AssignPalette.darkBlue.withOpacity(0.62),
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
