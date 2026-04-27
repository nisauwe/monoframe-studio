import 'package:flutter/material.dart';

import 'editor_dashboard_screen.dart';
import 'editor_profile_screen.dart';
import 'editor_task_list_screen.dart';

class EditorMainScreen extends StatefulWidget {
  const EditorMainScreen({super.key});

  @override
  State<EditorMainScreen> createState() => _EditorMainScreenState();
}

class _EditorMainScreenState extends State<EditorMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    EditorDashboardScreen(),
    EditorTaskListScreen(),
    EditorProfileScreen(),
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
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note_outlined),
            activeIcon: Icon(Icons.edit_note),
            label: 'Pekerjaan',
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
