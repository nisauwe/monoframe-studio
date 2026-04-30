import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/photographer_models.dart';
import '../../../data/providers/photographer_provider.dart';
import 'photographer_booking_detail_screen.dart';
import 'photographer_dashboard_screen.dart';
import 'photographer_schedule_screen.dart';

class PhotographerMainScreen extends StatefulWidget {
  const PhotographerMainScreen({super.key});

  @override
  State<PhotographerMainScreen> createState() => _PhotographerMainScreenState();
}

class _PhotographerMainScreenState extends State<PhotographerMainScreen> {
  int _currentIndex = 1;

  final List<Widget> _pages = const [
    PhotographerScheduleScreen(),
    PhotographerDashboardScreen(),
    _PhotographerPhotoScreen(),
  ];

  void _changeTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.secondary,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _PhotographerBottomNavigationBar(
        currentIndex: _currentIndex,
        onChangeTab: _changeTab,
      ),
    );
  }
}

class _PhotographerBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChangeTab;

  const _PhotographerBottomNavigationBar({
    required this.currentIndex,
    required this.onChangeTab,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: 104 + bottomPadding,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 18,
            right: 18,
            bottom: 12 + bottomPadding,
            child: Container(
              height: 76,
              decoration: BoxDecoration(
                gradient: AppColors.welcomeCardGradient,
                borderRadius: BorderRadius.circular(38),
                border: Border.all(color: Colors.white.withOpacity(0.72)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.welcomeBlueDark.withOpacity(0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _BottomItem(
                      icon: Icons.calendar_month_outlined,
                      activeIcon: Icons.calendar_month_rounded,
                      label: 'Jadwal',
                      active: currentIndex == 0,
                      onTap: () => onChangeTab(0),
                    ),
                  ),

                  const SizedBox(width: 92),

                  Expanded(
                    child: _BottomItem(
                      icon: Icons.cloud_upload_outlined,
                      activeIcon: Icons.cloud_upload_rounded,
                      label: 'Foto',
                      active: currentIndex == 2,
                      onTap: () => onChangeTab(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: _HomeButton(
                active: currentIndex == 1,
                onTap: () => onChangeTab(1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _HomeButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active ? AppColors.welcomeDarkGradient : null,
        color: active ? null : AppColors.welcomeCardMid,
        border: Border.all(
          color: active ? AppColors.welcomeCardDeep : Colors.white,
          width: 5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(active ? 0.30 : 0.16),
            blurRadius: active ? 28 : 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(
            Icons.home_rounded,
            size: 38,
            color: active ? Colors.white : AppColors.welcomeBlueDark,
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _BottomItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.welcomeBlueDark : AppColors.grey;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 76,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                horizontal: active ? 12 : 6,
                vertical: active ? 6 : 4,
              ),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withOpacity(0.70)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: active
                      ? Colors.white.withOpacity(0.84)
                      : Colors.transparent,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.welcomeBlueDark.withOpacity(0.10),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    active ? activeIcon : icon,
                    color: color,
                    size: active ? 27 : 26,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      height: 1,
                      fontWeight: active ? FontWeight.w900 : FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotographerPhotoScreen extends StatefulWidget {
  const _PhotographerPhotoScreen();

  @override
  State<_PhotographerPhotoScreen> createState() =>
      _PhotographerPhotoScreenState();
}

class _PhotographerPhotoScreenState extends State<_PhotographerPhotoScreen> {
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotographerProvider>();

    final needUpload = provider.needUploadBookings;
    final uploaded = provider.bookings
        .where((item) => item.hasPhotoLink)
        .toList();

    return SafeArea(
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
          color: AppColors.primaryDark,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
            children: [
              _PhotoHeader(totalNeedUpload: needUpload.length),

              const SizedBox(height: 18),

              const _PhotoSectionTitle(
                title: 'Perlu Upload Link Foto',
                subtitle: 'Booking yang belum memiliki link Google Drive',
              ),

              const SizedBox(height: 12),

              if (provider.isLoading && provider.bookings.isEmpty)
                const _LoadingCard()
              else if (needUpload.isEmpty)
                const _PhotoEmptyState(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Semua link sudah aman',
                  message: 'Tidak ada booking yang menunggu upload link foto.',
                )
              else
                ...needUpload.map((booking) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PhotoBookingCard(
                      booking: booking,
                      timeText:
                          '${_time(booking.startTime)} - ${_time(booking.endTime)}',
                      onTap: () => _openDetail(booking),
                    ),
                  );
                }),

              const SizedBox(height: 20),

              const _PhotoSectionTitle(
                title: 'Sudah Upload',
                subtitle: 'Riwayat booking yang sudah memiliki link foto',
              ),

              const SizedBox(height: 12),

              if (uploaded.isEmpty)
                const _PhotoEmptyState(
                  icon: Icons.cloud_done_outlined,
                  title: 'Belum ada link terupload',
                  message: 'Link foto yang sudah diinput akan tampil di sini.',
                )
              else
                ...uploaded.take(6).map((booking) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PhotoBookingCard(
                      booking: booking,
                      timeText:
                          '${_time(booking.startTime)} - ${_time(booking.endTime)}',
                      onTap: () => _openDetail(booking),
                    ),
                  );
                }),

              if (provider.errorMessage != null) ...[
                const SizedBox(height: 8),
                _PhotoErrorMessageBox(message: provider.errorMessage!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoHeader extends StatelessWidget {
  final int totalNeedUpload;

  const _PhotoHeader({required this.totalNeedUpload});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.welcomeDarkGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -32,
            top: -34,
            child: Container(
              height: 118,
              width: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            right: 28,
            bottom: -42,
            child: Container(
              height: 108,
              width: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withOpacity(0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Row(
              children: [
                Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.white.withOpacity(0.20),
                    ),
                  ),
                  child: const Icon(
                    Icons.cloud_upload_rounded,
                    color: AppColors.white,
                    size: 31,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upload Link Foto',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 23,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Input link Google Drive agar klien dapat melihat hasil foto.',
                        style: TextStyle(
                          color: AppColors.white.withOpacity(0.74),
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
                          color: AppColors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: AppColors.white.withOpacity(0.18),
                          ),
                        ),
                        child: Text(
                          '$totalNeedUpload perlu upload',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                          ),
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

class _PhotoSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PhotoSectionTitle({required this.title, required this.subtitle});

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
      ],
    );
  }
}

class _PhotoBookingCard extends StatelessWidget {
  final PhotographerBookingModel booking;
  final String timeText;
  final VoidCallback onTap;

  const _PhotoBookingCard({
    required this.booking,
    required this.timeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasLink = booking.hasPhotoLink;
    final color = hasLink ? AppColors.success : AppColors.warning;

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
          child: Row(
            children: [
              Container(
                width: 54,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.14)),
                ),
                child: Icon(
                  hasLink
                      ? Icons.check_circle_rounded
                      : Icons.cloud_upload_rounded,
                  color: color,
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.clientName.isEmpty ? 'Klien' : booking.clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.welcomeBlueDark,
                        fontSize: 17,
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
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 15,
                          color: AppColors.welcomeBlueDark,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${booking.bookingDate} • $timeText',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.welcomeBlueDark,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.welcomeBlueDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _PhotoEmptyState({
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

class _PhotoErrorMessageBox extends StatelessWidget {
  final String message;

  const _PhotoErrorMessageBox({required this.message});

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
