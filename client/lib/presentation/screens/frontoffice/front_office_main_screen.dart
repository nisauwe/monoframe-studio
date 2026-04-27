import 'package:flutter/material.dart';

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
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    FrontOfficeDashboardScreen(),
    FrontOfficeAssignScreen(),
    FrontOfficeCalendarScreen(),
    FrontOfficeProgressScreen(),
    FrontOfficeEditAssignmentScreen(),
    FrontOfficePrintOrdersScreen(),
    FrontOfficeFinanceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF6C63FF),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 10,
        unselectedFontSize: 9,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_ind_outlined),
            activeIcon: Icon(Icons.assignment_ind),
            label: 'Assign',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Kalender',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes_outlined),
            activeIcon: Icon(Icons.track_changes),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note_outlined),
            activeIcon: Icon(Icons.edit_note),
            label: 'Edit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.print_outlined),
            activeIcon: Icon(Icons.print),
            label: 'Cetak',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Keuangan',
          ),
        ],
      ),
    );
  }
}
