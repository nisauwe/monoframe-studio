import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/providers/front_office_provider.dart';

class FrontOfficeCalendarScreen extends StatefulWidget {
  const FrontOfficeCalendarScreen({super.key});

  @override
  State<FrontOfficeCalendarScreen> createState() =>
      _FrontOfficeCalendarScreenState();
}

class _FrontOfficeCalendarScreenState extends State<FrontOfficeCalendarScreen> {
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCalendar();
    });
  }

  Future<void> _fetchCalendar() {
    final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    return context.read<FrontOfficeProvider>().fetchCalendar(
      startDate: _formatDate(start),
      endDate: _formatDate(end),
    );
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
        1,
      );
    });

    _fetchCalendar();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _monthLabel(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FrontOfficeProvider>();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchCalendar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Kalender Booking',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Jadwal booking yang sudah memiliki fotografer.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _monthLabel(_selectedMonth),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (provider.isLoading && provider.calendarEvents.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.calendarEvents.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: Text('Belum ada jadwal bulan ini.')),
              )
            else
              ...provider.calendarEvents.map((event) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.event_available_outlined),
                    title: Text(event.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${event.start} - ${event.end}'),
                        Text('Fotografer: ${event.photographerName}'),
                        Text('Lokasi: ${event.locationName}'),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
