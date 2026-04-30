import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/photographer_models.dart';
import '../../../data/providers/photographer_provider.dart';
import 'photographer_booking_detail_screen.dart';
import 'photographer_dashboard_screen.dart';
import 'photographer_schedule_screen.dart';

class FotograferHomeScreen extends StatefulWidget {
  const FotograferHomeScreen({super.key});

  @override
  State<FotograferHomeScreen> createState() => _FotograferHomeScreenState();
}

class _FotograferHomeScreenState extends State<FotograferHomeScreen> {
  int _selectedIndex = 1;

  final List<Widget> _pages = const [
    PhotographerScheduleScreen(),
    PhotographerDashboardScreen(),
    _PhotographerPhotoScreen(),
  ];

  void _changePage(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: _PhotographerMainNavigation(
        selectedIndex: _selectedIndex,
        onTap: _changePage,
      ),
    );
  }
}

class _PhotographerMainNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _PhotographerMainNavigation({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 98,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFD8F3FB),
                borderRadius: BorderRadius.circular(38),
                border: Border.all(color: Colors.white.withOpacity(0.82)),
                boxShadow: [
                  BoxShadow(
                    color: _PhotographerHomePalette.darkBlue.withOpacity(0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _NavItem(
                      icon: Icons.calendar_month_rounded,
                      label: 'Jadwal',
                      selected: selectedIndex == 0,
                      onTap: () => onTap(0),
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.cloud_upload_rounded,
                      label: 'Foto',
                      selected: selectedIndex == 2,
                      onTap: () => onTap(2),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -2,
              child: GestureDetector(
                onTap: () => onTap(1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _PhotographerHomePalette.darkBlue,
                    border: Border.all(color: Colors.white, width: 6),
                    boxShadow: [
                      BoxShadow(
                        color: _PhotographerHomePalette.darkBlue.withOpacity(
                          0.28,
                        ),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: selectedIndex == 1 ? 39 : 35,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? _PhotographerHomePalette.darkBlue : AppColors.grey;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 48 : 40,
              height: selected ? 48 : 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? Colors.white.withOpacity(0.78)
                    : Colors.transparent,
              ),
              child: Icon(icon, color: color, size: selected ? 25 : 24),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
              ),
            ),
          ],
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
        color: AppColors.background,
        child: RefreshIndicator(
          color: _PhotographerHomePalette.darkBlue,
          backgroundColor: _PhotographerHomePalette.cardLight,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 118),
            children: [
              _PhotoHeader(totalNeedUpload: needUpload.length),

              const SizedBox(height: 18),

              const _PhotoSectionTitle(
                title: 'Perlu Upload Link Foto',
                subtitle: 'Booking yang belum memiliki link Google Drive',
              ),

              const SizedBox(height: 12),

              if (provider.isLoading && provider.bookings.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 90),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _PhotographerHomePalette.darkBlue,
                    ),
                  ),
                )
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

              const SizedBox(height: 18),

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
                ...uploaded.take(5).map((booking) {
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: _PhotographerHomePalette.darkGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _PhotographerHomePalette.darkBlue.withOpacity(0.16),
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
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.20)),
                ),
                child: const Icon(
                  Icons.cloud_upload_rounded,
                  color: Colors.white,
                  size: 30,
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
                        color: Colors.white,
                        fontSize: 23,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Input link Google Drive agar klien dapat melihat hasil foto.',
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
                      child: Text(
                        '$totalNeedUpload perlu upload',
                        style: const TextStyle(
                          color: Colors.white,
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
            gradient: _PhotographerHomePalette.darkGradient,
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _PhotographerHomePalette.cardDeep),
            boxShadow: [
              BoxShadow(
                color: _PhotographerHomePalette.darkBlue.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color.withOpacity(0.14)),
                ),
                child: Icon(
                  hasLink
                      ? Icons.check_circle_rounded
                      : Icons.cloud_upload_rounded,
                  color: color,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.clientName.isEmpty ? 'Klien' : booking.clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _PhotographerHomePalette.darkBlue,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      booking.packageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _PhotographerHomePalette.darkBlue.withOpacity(
                          0.58,
                        ),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 15,
                          color: _PhotographerHomePalette.darkBlue.withOpacity(
                            0.72,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${booking.bookingDate} • $timeText',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _PhotographerHomePalette.darkBlue
                                  .withOpacity(0.70),
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
                color: _PhotographerHomePalette.darkBlue,
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
        gradient: _PhotographerHomePalette.softGradient,
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
            child: Icon(
              icon,
              size: 34,
              color: _PhotographerHomePalette.darkBlue,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: _PhotographerHomePalette.darkBlue,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _PhotographerHomePalette.darkBlue.withOpacity(0.62),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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

class _PhotographerHomePalette {
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
