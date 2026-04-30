import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'editor_dashboard_screen.dart';
import 'editor_task_list_screen.dart';

class EditorMainScreen extends StatefulWidget {
  const EditorMainScreen({super.key});

  @override
  State<EditorMainScreen> createState() => _EditorMainScreenState();
}

class _EditorMainScreenState extends State<EditorMainScreen> {
  int _currentIndex = 1;

  final List<Widget> _pages = const [
    EditorTaskListScreen(
      initialFilter: 'active',
      title: 'Pekerjaan Edit',
      subtitle: 'Request edit foto yang sedang aktif.',
    ),
    EditorDashboardScreen(),
    EditorTaskListScreen(
      initialFilter: 'completed',
      title: 'Riwayat Edit',
      subtitle: 'Request edit foto yang sudah selesai.',
    ),
  ];

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _EditorBottomNavigationBar(
        currentIndex: _currentIndex,
        onChangeTab: _changeTab,
      ),
    );
  }
}

class _EditorBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChangeTab;

  const _EditorBottomNavigationBar({
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
                      icon: Icons.edit_note_outlined,
                      activeIcon: Icons.edit_note_rounded,
                      label: 'Tugas',
                      active: currentIndex == 0,
                      onTap: () => onChangeTab(0),
                    ),
                  ),

                  const SizedBox(width: 82),

                  Expanded(
                    child: _BottomItem(
                      icon: Icons.check_circle_outline_rounded,
                      activeIcon: Icons.check_circle_rounded,
                      label: 'Selesai',
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
