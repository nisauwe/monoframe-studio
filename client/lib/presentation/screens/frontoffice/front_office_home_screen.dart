import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'front_office_assign_screen.dart';
import 'front_office_calendar_screen.dart';
import 'front_office_dashboard_screen.dart';
import 'front_office_edit_assignment_screen.dart';
import 'front_office_finance_screen.dart';
import 'front_office_print_orders_screen.dart';
import 'front_office_progress_screen.dart';

class FrontOfficeMainScreen extends StatefulWidget {
  const FrontOfficeMainScreen({super.key});

  @override
  State<FrontOfficeMainScreen> createState() => _FrontOfficeMainScreenState();
}

class _FrontOfficeMainScreenState extends State<FrontOfficeMainScreen> {
  // Home dibuat di tengah, sama seperti navigation role klien.
  int _currentIndex = 3;

  final List<Widget> _pages = const [
    FrontOfficeAssignScreen(),
    FrontOfficeCalendarScreen(),
    FrontOfficeProgressScreen(),
    FrontOfficeDashboardScreen(),
    FrontOfficeEditAssignmentScreen(),
    FrontOfficePrintOrdersScreen(),
    FrontOfficeFinanceScreen(),
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
      bottomNavigationBar: _FrontOfficeBottomNavigationBar(
        currentIndex: _currentIndex,
        onChangeTab: _changeTab,
      ),
    );
  }
}

class _FrontOfficeBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChangeTab;

  const _FrontOfficeBottomNavigationBar({
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
            left: 10,
            right: 10,
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
                      icon: Icons.assignment_ind_outlined,
                      activeIcon: Icons.assignment_ind_rounded,
                      label: 'Assign',
                      active: currentIndex == 0,
                      onTap: () => onChangeTab(0),
                    ),
                  ),
                  Expanded(
                    child: _BottomItem(
                      icon: Icons.calendar_month_outlined,
                      activeIcon: Icons.calendar_month_rounded,
                      label: 'Jadwal',
                      active: currentIndex == 1,
                      onTap: () => onChangeTab(1),
                    ),
                  ),
                  Expanded(
                    child: _BottomItem(
                      icon: Icons.track_changes_outlined,
                      activeIcon: Icons.track_changes_rounded,
                      label: 'Progress',
                      active: currentIndex == 2,
                      onTap: () => onChangeTab(2),
                    ),
                  ),

                  // Ruang kosong untuk tombol Home bulat di tengah.
                  const SizedBox(width: 82),

                  Expanded(
                    child: _BottomItem(
                      icon: Icons.edit_note_outlined,
                      activeIcon: Icons.edit_note_rounded,
                      label: 'Edit',
                      active: currentIndex == 4,
                      onTap: () => onChangeTab(4),
                    ),
                  ),
                  Expanded(
                    child: _BottomItem(
                      icon: Icons.print_outlined,
                      activeIcon: Icons.print_rounded,
                      label: 'Cetak',
                      active: currentIndex == 5,
                      onTap: () => onChangeTab(5),
                    ),
                  ),
                  Expanded(
                    child: _BottomItem(
                      icon: Icons.account_balance_wallet_outlined,
                      activeIcon: Icons.account_balance_wallet_rounded,
                      label: 'Kas',
                      active: currentIndex == 6,
                      onTap: () => onChangeTab(6),
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
                active: currentIndex == 3,
                onTap: () => onChangeTab(3),
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
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: EdgeInsets.symmetric(
                horizontal: active ? 5 : 1,
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
