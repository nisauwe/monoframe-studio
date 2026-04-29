import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/providers/auth_provider.dart';
import '../auth/auth_welcome_screen.dart';
import '../contact/contact_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthWelcomeScreen()),
      (route) => false,
    );
  }

  void _openContactScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ContactScreen()),
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

          const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),

          const SizedBox(height: 16),

          Center(
            child: Text(
              user?.name ?? '-',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                  leading: const Icon(Icons.alternate_email),
                  title: const Text('Username'),
                  subtitle: Text(
                    user?.username.isNotEmpty == true ? user!.username : '-',
                  ),
                ),
                const Divider(height: 1),

                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Nama Lengkap'),
                  subtitle: Text(user?.name ?? '-'),
                ),
                const Divider(height: 1),

                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(user?.email ?? '-'),
                ),

                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Nomor WhatsApp'),
                  subtitle: Text(
                    user?.phone.isNotEmpty == true ? user!.phone : '-',
                  ),
                ),
                const Divider(height: 1),

                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Alamat'),
                  subtitle: Text(
                    user?.address.isNotEmpty == true ? user!.address : '-',
                  ),
                ),
                const Divider(height: 1),
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
