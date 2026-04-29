import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/providers/package_provider.dart';
import '../booking/booking_screen.dart';
import '../package/package_screen.dart';
import '../profile/profile_screen.dart';
import '../tracking/tracking_screen.dart';
import 'home_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 2;
  String? _selectedPackageCategory;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PackageProvider>().fetchAll(forceRefresh: true);
    });
  }

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openPackages({String? category}) {
    setState(() {
      _selectedPackageCategory = category;
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      PackageScreen(
        key: ValueKey('package-${_selectedPackageCategory ?? 'Semua'}'),
        initialCategory: _selectedPackageCategory,
      ),
      const BookingScreen(),
      HomeScreen(
        onOpenPackages: () => _openPackages(),
        onOpenPackageCategory: (category) => _openPackages(category: category),
        onOpenBooking: () => _changeTab(1),
        onOpenTracking: () => _changeTab(3),
      ),
      const TrackingScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _ClientBottomNavigationBar(
        currentIndex: _currentIndex,
        onOpenPackages: () => _openPackages(),
        onChangeTab: _changeTab,
      ),
    );
  }
}

class _ClientBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final VoidCallback onOpenPackages;
  final ValueChanged<int> onChangeTab;

  const _ClientBottomNavigationBar({
    required this.currentIndex,
    required this.onOpenPackages,
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
            left: 14,
            right: 14,
            bottom: 12 + bottomPadding,
            child: Container(
              height: 76,
              decoration: BoxDecoration(
                gradient: AppColors.welcomeCardGradient,
                borderRadius: BorderRadius.circular(34),
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
                      icon: Icons.inventory_2_outlined,
                      activeIcon: Icons.inventory_2_rounded,
                      label: 'Paket',
                      active: currentIndex == 0,
                      onTap: onOpenPackages,
                    ),
                  ),
                  Expanded(
                    child: _BottomItem(
                      icon: Icons.shopping_bag_outlined,
                      activeIcon: Icons.shopping_bag_rounded,
                      label: 'Booking',
                      active: currentIndex == 1,
                      onTap: () => onChangeTab(1),
                    ),
                  ),
                  const SizedBox(width: 82),
                  Expanded(
                    child: _BottomItem(
                      icon: Icons.track_changes_outlined,
                      activeIcon: Icons.track_changes_rounded,
                      label: 'Tracking',
                      active: currentIndex == 3,
                      onTap: () => onChangeTab(3),
                    ),
                  ),
                  Expanded(
                    child: _BottomItem(
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: 'Profile',
                      active: currentIndex == 4,
                      onTap: () => onChangeTab(4),
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
                active: currentIndex == 2,
                onTap: () => onChangeTab(2),
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
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active ? AppColors.welcomeDarkGradient : null,
        color: active ? null : AppColors.welcomeCardMid,
        border: Border.all(
          color: active ? AppColors.welcomeCardDeep : Colors.white,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(active ? 0.28 : 0.16),
            blurRadius: active ? 26 : 16,
            offset: const Offset(0, 10),
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
            size: 32,
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
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 76,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: EdgeInsets.symmetric(
                horizontal: active ? 6 : 2,
                vertical: active ? 5 : 3,
              ),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withOpacity(0.70)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
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
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    width: active ? 31 : 28,
                    height: active ? 28 : 26,
                    decoration: BoxDecoration(
                      gradient: active ? AppColors.welcomeDarkGradient : null,
                      color: active ? null : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      active ? activeIcon : icon,
                      color: active ? Colors.white : color,
                      size: active ? 19 : 22,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      height: 1,
                      fontWeight: active ? FontWeight.w900 : FontWeight.w700,
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
