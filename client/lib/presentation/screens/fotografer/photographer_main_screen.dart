import 'package:flutter/material.dart';

import 'photographer_dashboard_screen.dart';
import 'photographer_profile_screen.dart';
import 'photographer_schedule_screen.dart';

class PhotographerMainScreen extends StatefulWidget {
  const PhotographerMainScreen({super.key});

  @override
  State<PhotographerMainScreen> createState() => _PhotographerMainScreenState();
}

class _PhotographerMainScreenState extends State<PhotographerMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    PhotographerDashboardScreen(),
    PhotographerScheduleScreen(),
    PhotographerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF6C63FF),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Jadwal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
