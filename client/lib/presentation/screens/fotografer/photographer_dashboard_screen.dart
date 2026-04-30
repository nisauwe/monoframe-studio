import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/photographer_models.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/photographer_provider.dart';
import '../auth/auth_welcome_screen.dart';
import 'photographer_booking_detail_screen.dart';

class PhotographerDashboardScreen extends StatefulWidget {
  const PhotographerDashboardScreen({super.key});

  @override
  State<PhotographerDashboardScreen> createState() =>
      _PhotographerDashboardScreenState();
}

class _PhotographerDashboardScreenState
    extends State<PhotographerDashboardScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PhotographerProvider>().fetchBookings();
    });
  }

  Future<void> _refresh() {
    return context.read<PhotographerProvider>().fetchBookings();
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthWelcomeScreen()),
      (route) => false,
    );
  }

  void _openDetail(PhotographerBookingModel booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotographerBookingDetailScreen(bookingId: booking.id),
      ),
    );
  }

  String _time(String value) {
    final parts = value.split(':');

    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }

    return value.isEmpty ? '-' : value;
  }

  String _shortName(String name) {
    final trimmed = name.trim();

    if (trimmed.isEmpty) return 'Fotografer';

    final parts = trimmed.split(' ');

    if (parts.length == 1) return parts.first;

    return '${parts.first} ${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<PhotographerProvider>();

    final name = _shortName(auth.user?.name ?? 'Fotografer');
    final todayCount = provider.todayBookings.length;
    final upcomingCount = provider.upcomingBookings.length;
    final needUploadCount = provider.needUploadBookings.length;
    final totalCount = provider.bookings.length;

    return Container(
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
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 132),
            children: [
              _TopGreetingBar(
                name: auth.user?.name ?? 'Fotografer',
                onLogout: () => _logout(context),
              ),

              const SizedBox(height: 14),

              _DashboardHero(
                name: name,
                todayCount: todayCount,
                needUploadCount: needUploadCount,
              ),

              const SizedBox(height: 18),

              const _SectionTitle(
                title: 'Ringkasan Tugas',
                subtitle: 'Pantau jadwal dan pekerjaan fotografer hari ini',
                trailingText: 'Live',
              ),

              const SizedBox(height: 12),

              _OperationalStatusCard(
                isSafe: todayCount == 0 && needUploadCount == 0,
                message: todayCount == 0 && needUploadCount == 0
                    ? 'Tidak ada jadwal dan upload tertunda hari ini.'
                    : '$todayCount jadwal hari ini dan $needUploadCount link foto perlu diupload.',
              ),

              const SizedBox(height: 14),

              _PhotographerShortcutGrid(
                todayCount: todayCount,
                upcomingCount: upcomingCount,
                needUploadCount: needUploadCount,
                totalCount: totalCount,
              ),

              const SizedBox(height: 22),

              const _SectionTitle(
                title: 'Jadwal Hari Ini',
                subtitle: 'Booking klien yang harus dikerjakan hari ini',
              ),

              const SizedBox(height: 12),

              if (provider.isLoading && provider.bookings.isEmpty)
                const _LoadingCard()
              else if (provider.todayBookings.isEmpty)
                const _EmptyState(
                  icon: Icons.event_busy_rounded,
                  title: 'Tidak ada jadwal hari ini',
                  message:
                      'Jadwal yang di-assign Front Office akan muncul di sini.',
                )
              else
                ...provider.todayBookings.map((booking) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BookingCard(
                      booking: booking,
                      timeText:
                          '${_time(booking.startTime)} - ${_time(booking.endTime)}',
                      onTap: () => _openDetail(booking),
                    ),
                  );
                }),

              const SizedBox(height: 22),

              const _SectionTitle(
                title: 'Perlu Upload Link Foto',
                subtitle: 'Booking yang belum memiliki link Google Drive',
              ),

              const SizedBox(height: 12),

              if (provider.needUploadBookings.isEmpty)
                const _EmptyState(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Tidak ada upload tertunda',
                  message:
                      'Booking yang belum memiliki link Google Drive akan tampil di sini.',
                )
              else
                ...provider.needUploadBookings.take(5).map((booking) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BookingCard(
                      booking: booking,
                      timeText:
                          '${_time(booking.startTime)} - ${_time(booking.endTime)}',
                      onTap: () => _openDetail(booking),
                    ),
                  );
                }),

              if (provider.errorMessage != null) ...[
                const SizedBox(height: 8),
                _ErrorBox(message: provider.errorMessage!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TopGreetingBar extends StatelessWidget {
  final String name;
  final VoidCallback onLogout;

  const _TopGreetingBar({required this.name, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isEmpty ? 'Fotografer' : name.trim();

    return Row(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            gradient: AppColors.welcomeCardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.white.withOpacity(0.76)),
            boxShadow: [
              BoxShadow(
                color: AppColors.welcomeBlueDark.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.photo_camera_rounded,
            color: AppColors.welcomeBlueDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fotografer',
                style: TextStyle(
                  color: AppColors.grey,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.dark,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onLogout,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardHero extends StatelessWidget {
  final String name;
  final int todayCount;
  final int needUploadCount;

  const _DashboardHero({
    required this.name,
    required this.todayCount,
    required this.needUploadCount,
  });

  String _dayName(DateTime date) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    return days[date.weekday - 1];
  }

  String _monthName(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return months[date.month - 1];
  }

  String _shortMonthName(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return months[date.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final fullDate =
        '${_dayName(now)}, ${now.day} ${_monthName(now)} ${now.year}';
    final shortDate = '${now.day} ${_shortMonthName(now)} ${now.year}';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.welcomeDarkGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -42,
            child: Container(
              height: 124,
              width: 124,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            right: 38,
            bottom: -64,
            child: Container(
              height: 128,
              width: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            left: -42,
            bottom: -52,
            child: Container(
              height: 108,
              width: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withOpacity(0.045),
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
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: AppColors.white.withOpacity(0.22),
                          width: 1.1,
                        ),
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: AppColors.white,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Monoframe Studio',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.white.withOpacity(0.22),
                        ),
                      ),
                      child: Text(
                        shortDate,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 10.8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                Text(
                  'Halo, $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 27,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 9),

                Text(
                  fullDate,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white.withOpacity(0.74),
                    fontSize: 13.5,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _HeroMetricBox(
                        icon: Icons.calendar_month_rounded,
                        label: 'Jadwal Hari Ini',
                        value: '$todayCount',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroMetricBox(
                        icon: Icons.cloud_upload_rounded,
                        label: 'Butuh Upload',
                        value: '$needUploadCount',
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
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white.withOpacity(0.22), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.white, size: 19),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.white.withOpacity(0.90),
                fontSize: 10.8,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 20,
              height: 1,
              fontWeight: FontWeight.w900,
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
  final String? trailingText;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 34,
          width: 5,
          decoration: BoxDecoration(
            gradient: AppColors.welcomeDarkGradient,
            borderRadius: BorderRadius.circular(99),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (trailingText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  height: 7,
                  width: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  trailingText!,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _OperationalStatusCard extends StatelessWidget {
  final bool isSafe;
  final String message;

  const _OperationalStatusCard({required this.isSafe, required this.message});

  @override
  Widget build(BuildContext context) {
    final color = isSafe ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isSafe
            ? AppColors.welcomeCardGradient
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFBEB), Color(0xFFEAF5FA)],
              ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.white.withOpacity(0.74)),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.74),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.white),
            ),
            child: Icon(
              isSafe
                  ? Icons.check_circle_rounded
                  : Icons.notifications_active_rounded,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSafe ? 'Tugas aman' : 'Ada prioritas',
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.grey,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
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

class _PhotographerShortcutGrid extends StatelessWidget {
  final int todayCount;
  final int upcomingCount;
  final int needUploadCount;
  final int totalCount;

  const _PhotographerShortcutGrid({
    required this.todayCount,
    required this.upcomingCount,
    required this.needUploadCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniActionCard(
                icon: Icons.today_rounded,
                title: 'Hari Ini',
                subtitle: '$todayCount jadwal',
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniActionCard(
                icon: Icons.event_available_rounded,
                title: 'Akan Datang',
                subtitle: '$upcomingCount booking',
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MiniActionCard(
                icon: Icons.cloud_upload_rounded,
                title: 'Upload',
                subtitle: '$needUploadCount link foto',
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniActionCard(
                icon: Icons.assignment_rounded,
                title: 'Total Tugas',
                subtitle: '$totalCount booking',
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _MiniActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    height: 1.05,
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

class _BookingCard extends StatelessWidget {
  final PhotographerBookingModel booking;
  final String timeText;
  final VoidCallback onTap;

  const _BookingCard({
    required this.booking,
    required this.timeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhotoLink = booking.hasPhotoLink;
    final uploadColor = hasPhotoLink ? AppColors.success : AppColors.warning;

    return Material(
      color: AppColors.light,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: uploadColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: uploadColor.withOpacity(0.14)),
                    ),
                    child: Icon(
                      hasPhotoLink
                          ? Icons.check_circle_rounded
                          : Icons.cloud_upload_rounded,
                      color: uploadColor,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.clientName.isEmpty
                              ? 'Klien'
                              : booking.clientName,
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
                          booking.packageName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 11.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.welcomeBlueDark,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _StatusChip(
                      label: booking.statusLabel,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatusChip(
                      label: booking.paymentStatusLabel,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
                decoration: BoxDecoration(
                  gradient: AppColors.welcomeCardGradient,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.white.withOpacity(0.76)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _CompactInfo(
                            icon: Icons.calendar_month_rounded,
                            label: 'Tanggal',
                            value: booking.bookingDate,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CompactInfo(
                            icon: Icons.schedule_rounded,
                            label: 'Jam',
                            value: timeText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _CompactInfo(
                            icon: Icons.location_on_rounded,
                            label: 'Lokasi',
                            value:
                                '${booking.locationTypeLabel} • ${booking.locationName}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CompactInfo(
                            icon: Icons.cloud_upload_rounded,
                            label: 'Foto',
                            value: hasPhotoLink ? 'Terupload' : 'Belum Upload',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
        borderRadius: BorderRadius.circular(99),
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
        Icon(icon, color: AppColors.welcomeBlueDark, size: 16),
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
                  color: AppColors.welcomeBlueDark.withOpacity(0.54),
                  fontSize: 9.8,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
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
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
      decoration: BoxDecoration(
        gradient: AppColors.welcomeCardGradient,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.white.withOpacity(0.78)),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.60),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: AppColors.welcomeBlueDark),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.welcomeBlueDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.welcomeBlueDark.withOpacity(0.62),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: const CircularProgressIndicator(color: AppColors.primaryDark),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.danger.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
