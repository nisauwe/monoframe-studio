import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/providers/auth_provider.dart';
import '../auth/login_screen.dart';

class EditorProfileScreen extends StatelessWidget {
  const EditorProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),

          const CircleAvatar(radius: 42, child: Icon(Icons.edit, size: 42)),

          const SizedBox(height: 16),

          Center(
            child: Text(
              user?.name ?? 'Editor',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
          ),

          const SizedBox(height: 6),

          Center(
            child: Text(
              user?.email ?? '-',
              style: const TextStyle(color: Colors.grey),
            ),
          ),

          const SizedBox(height: 24),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Nama Lengkap'),
                  subtitle: Text(user?.name ?? '-'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.alternate_email),
                  title: const Text('Username'),
                  subtitle: Text(
                    user?.username.isNotEmpty == true ? user!.username : '-',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(user?.email ?? '-'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Nomor WhatsApp'),
                  subtitle: Text(
                    user?.phone.isNotEmpty == true ? user!.phone : '-',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.work_outline),
                  title: const Text('Role'),
                  subtitle: Text(user?.role ?? 'Editor'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
