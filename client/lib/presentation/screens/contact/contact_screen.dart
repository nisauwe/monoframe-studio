import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/call_center_contact_model.dart';
import '../../../data/providers/call_center_provider.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CallCenterProvider>().fetchContacts();
    });
  }

  Future<void> openContact(CallCenterContactModel contact) async {
    final url = contact.contactUrl;

    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kontak belum memiliki link yang valid')),
      );
      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('URL kontak tidak valid')));
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!mounted) return;

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka kontak')),
      );
    }
  }

  IconData platformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'whatsapp':
        return Icons.chat_outlined;
      case 'instagram':
        return Icons.camera_alt_outlined;
      case 'tiktok':
        return Icons.music_note_outlined;
      case 'email':
        return Icons.email_outlined;
      case 'phone':
        return Icons.phone_outlined;
      case 'website':
        return Icons.language_outlined;
      default:
        return Icons.link_outlined;
    }
  }

  Color platformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'whatsapp':
        return Colors.green;
      case 'instagram':
        return Colors.purple;
      case 'tiktok':
        return Colors.black87;
      case 'email':
        return Colors.orange;
      case 'phone':
        return Colors.blue;
      case 'website':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CallCenterProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Kontak')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.fetchContacts,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.support_agent,
                      size: 46,
                      color: Color(0xFF6C63FF),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Butuh Bantuan?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Hubungi kontak Monoframe untuk pertanyaan paket foto, request custom di luar paket, pembayaran, atau kendala aplikasi.',
                      style: TextStyle(height: 1.5, color: Colors.black54),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Daftar Kontak',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              if (provider.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (provider.contacts.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.contact_phone_outlined,
                        size: 72,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Belum ada kontak tersedia',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        provider.errorMessage ??
                            'Kontak yang diaktifkan admin akan tampil di sini.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: provider.fetchContacts,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Muat Ulang'),
                      ),
                    ],
                  ),
                )
              else
                ...provider.contacts.map((contact) {
                  final color = platformColor(contact.platform);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      leading: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          platformIcon(contact.platform),
                          color: color,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              contact.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (contact.isEmergency)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Darurat',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (contact.description != null &&
                                contact.description!.isNotEmpty)
                              Text(contact.description!),
                            const SizedBox(height: 4),
                            Text(
                              '${contact.platformLabel} • ${contact.contactValue}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (contact.contactPerson != null &&
                                contact.contactPerson!.isNotEmpty)
                              Text('PIC: ${contact.contactPerson}'),
                            if (contact.serviceHours != null &&
                                contact.serviceHours!.isNotEmpty)
                              Text('Jam layanan: ${contact.serviceHours}'),
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => openContact(contact),
                    ),
                  );
                }),

              const SizedBox(height: 24),

              const Text(
                'Pertanyaan Cepat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              _QuestionInfoCard(
                icon: Icons.photo_camera_outlined,
                title: 'Pertanyaan Paket Foto',
                description:
                    'Gunakan kontak Front Office atau Admin untuk menanyakan harga, durasi, lokasi, jumlah foto edit, dan fasilitas paket.',
              ),

              const SizedBox(height: 12),

              _QuestionInfoCard(
                icon: Icons.auto_awesome_outlined,
                title: 'Request Foto di Luar Paket',
                description:
                    'Hubungi kontak Monoframe jika kamu punya konsep custom, tema khusus, jumlah orang berbeda, atau kebutuhan foto yang tidak tersedia di paket.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _QuestionInfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6C63FF), size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(color: Colors.black54, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
