import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/providers/front_office_provider.dart';
import 'front_office_progress_detail_screen.dart';

class FrontOfficeProgressScreen extends StatefulWidget {
  const FrontOfficeProgressScreen({super.key});

  @override
  State<FrontOfficeProgressScreen> createState() =>
      _FrontOfficeProgressScreenState();
}

class _FrontOfficeProgressScreenState extends State<FrontOfficeProgressScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FrontOfficeProvider>().fetchProgress();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() {
    return context.read<FrontOfficeProvider>().fetchProgress(
      search: _searchController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FrontOfficeProvider>();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => context.read<FrontOfficeProvider>().fetchProgress(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Monitoring Progress',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pantau status booking, fotografer, link foto, edit, cetak, dan review.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama klien, paket, fotografer...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _search,
                  icon: const Icon(Icons.arrow_forward),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onSubmitted: (_) => _search(),
            ),

            const SizedBox(height: 20),

            if (provider.isLoading && provider.progressList.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.progressList.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: Text('Belum ada data progress.')),
              )
            else
              ...provider.progressList.map((item) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.track_changes_outlined),
                    title: Text(item.clientName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.packageName),
                        Text('${item.bookingDate} • ${item.startTime}'),
                        Text('Tahap: ${item.currentStageName}'),
                        Text('Fotografer: ${item.photographerName}'),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FrontOfficeProgressDetailScreen(
                            bookingId: item.id,
                            title: item.clientName,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
