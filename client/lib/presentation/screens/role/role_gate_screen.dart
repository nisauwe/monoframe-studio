import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/providers/auth_provider.dart';
import '../auth/auth_welcome_screen.dart';
import '../home/main_navigation_screen.dart';
import '../frontoffice/front_office_main_screen.dart';
import '../fotografer/photographer_main_screen.dart';
import '../editor/editor_main_screen.dart';

class RoleGateScreen extends StatefulWidget {
  const RoleGateScreen({super.key});

  @override
  State<RoleGateScreen> createState() => _RoleGateScreenState();
}

class _RoleGateScreenState extends State<RoleGateScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRole();
    });
  }

  void _checkRole() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthWelcomeScreen()),
        (route) => false,
      );
      return;
    }

    final role = user.role.toLowerCase().trim();

    Widget targetScreen;

    if (role == 'klien') {
      targetScreen = const MainNavigationScreen();
    } else if (role == 'front office') {
      targetScreen = const FrontOfficeMainScreen();
    } else if (role == 'fotografer') {
      targetScreen = const PhotographerMainScreen();
    } else if (role == 'editor') {
      targetScreen = const EditorMainScreen();
    } else if (role == 'admin') {
      targetScreen = const _RoleNotReadyScreen(
        title: 'Admin',
        message: 'Admin menggunakan halaman server web.',
      );
    } else {
      targetScreen = _RoleNotReadyScreen(
        title: 'Role Tidak Dikenali',
        message: 'Role akun ini tidak dikenali: ${user.role}',
      );
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: Center(child: CircularProgressIndicator())),
    );
  }
}

class _RoleNotReadyScreen extends StatelessWidget {
  final String title;
  final String message;

  const _RoleNotReadyScreen({required this.title, required this.message});

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthWelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), automaticallyImplyLeading: false),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 72, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, height: 1.5),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Keluar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
