import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/providers/front_office_provider.dart';

class FrontOfficeProgressDetailScreen extends StatefulWidget {
  final int bookingId;
  final String title;

  const FrontOfficeProgressDetailScreen({
    super.key,
    required this.bookingId,
    required this.title,
  });

  @override
  State<FrontOfficeProgressDetailScreen> createState() =>
      _FrontOfficeProgressDetailScreenState();
}

class _FrontOfficeProgressDetailScreenState
    extends State<FrontOfficeProgressDetailScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FrontOfficeProvider>().fetchProgressDetail(
        bookingId: widget.bookingId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FrontOfficeProvider>();
    final detail = provider.selectedProgressDetail;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Progress')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () {
            return context.read<FrontOfficeProvider>().fetchProgressDetail(
              bookingId: widget.bookingId,
            );
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              if (provider.isLoading && detail == null)
                const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (detail == null)
                const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(child: Text('Detail tidak ditemukan.')),
                )
              else ...[
                Text(
                  detail['client_name']?.toString() ?? widget.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'ID Booking #${detail['id']}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),

                _InfoTile(
                  title: 'Tanggal',
                  value: detail['booking_date']?.toString() ?? '-',
                ),
                _InfoTile(
                  title: 'Jam',
                  value:
                      '${detail['start_time'] ?? '-'} - ${detail['end_time'] ?? '-'}',
                ),
                _InfoTile(
                  title: 'Status Booking',
                  value: detail['status']?.toString() ?? '-',
                ),
                _InfoTile(
                  title: 'Lokasi',
                  value: detail['location_name']?.toString() ?? '-',
                ),

                const SizedBox(height: 20),

                const Text(
                  'Timeline',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),

                if (detail['trackings'] is List)
                  ...(detail['trackings'] as List).map((item) {
                    final map = Map<String, dynamic>.from(item);
                    final status = map['status']?.toString() ?? '';
                    final done = status == 'done';
                    final current = status == 'current';

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          done
                              ? Icons.check_circle
                              : current
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: done
                              ? Colors.green
                              : current
                              ? const Color(0xFF6C63FF)
                              : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    map['stage_name']?.toString() ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    map['description']?.toString() ??
                                        'Menunggu proses.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;

  const _InfoTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(title: Text(title), subtitle: Text(value)),
    );
  }
}
