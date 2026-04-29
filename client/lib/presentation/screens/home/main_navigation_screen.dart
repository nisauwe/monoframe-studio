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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          elevation: 8,
          backgroundColor: _currentIndex == 2
              ? AppColors.primaryDark
              : Colors.white,
          foregroundColor: _currentIndex == 2
              ? Colors.white
              : AppColors.primaryDark,
          shape: const CircleBorder(),
          onPressed: () => _changeTab(2),
          child: const Icon(Icons.home_rounded, size: 30),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 82,
        color: Colors.white,
        elevation: 18,
        shadowColor: AppColors.primaryDark.withOpacity(0.14),
        surfaceTintColor: Colors.transparent,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          children: [
            Expanded(
              child: _BottomItem(
                icon: Icons.inventory_2_outlined,
                activeIcon: Icons.inventory_2_rounded,
                label: 'Paket',
                active: _currentIndex == 0,
                onTap: () => _openPackages(),
              ),
            ),
            Expanded(
              child: _BottomItem(
                icon: Icons.shopping_bag_outlined,
                activeIcon: Icons.shopping_bag_rounded,
                label: 'Booking',
                active: _currentIndex == 1,
                onTap: () => _changeTab(1),
              ),
            ),
            const SizedBox(width: 76),
            Expanded(
              child: _BottomItem(
                icon: Icons.track_changes_outlined,
                activeIcon: Icons.track_changes_rounded,
                label: 'Tracking',
                active: _currentIndex == 3,
                onTap: () => _changeTab(3),
              ),
            ),
            Expanded(
              child: _BottomItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                active: _currentIndex == 4,
                onTap: () => _changeTab(4),
              ),
            ),
          ],
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
    final color = active ? AppColors.primaryDark : AppColors.grey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(active ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
