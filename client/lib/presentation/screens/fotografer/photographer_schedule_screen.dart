import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/photographer_models.dart';
import '../../../data/providers/photographer_provider.dart';
import 'photographer_booking_detail_screen.dart';

class PhotographerScheduleScreen extends StatefulWidget {
  const PhotographerScheduleScreen({super.key});

  @override
  State<PhotographerScheduleScreen> createState() =>
      _PhotographerScheduleScreenState();
}

class _PhotographerScheduleScreenState
    extends State<PhotographerScheduleScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PhotographerProvider>().fetchBookings();
    });
  }

  List<PhotographerBookingModel> _filteredBookings(
    PhotographerProvider provider,
  ) {
    if (_filter == 'today') {
      return provider.todayBookings;
    }

    if (_filter == 'upcoming') {
      return provider.upcomingBookings;
    }

    if (_filter == 'need_upload') {
      return provider.needUploadBookings;
    }

    if (_filter == 'past') {
      return provider.pastBookings;
    }

    return provider.bookings;
  }

  void _openDetail(PhotographerBookingModel booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotographerBookingDetailScreen(bookingId: booking.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotographerProvider>();
    final bookings = _filteredBookings(provider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: provider.fetchBookings,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Jadwal Pemotretan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            const SizedBox(height: 6),
            const Text(
              'Daftar jadwal yang sudah di-assign oleh Front Office.',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 18),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Semua',
                    value: 'all',
                    selectedValue: _filter,
                    onSelected: _setFilter,
                  ),
                  _FilterChip(
                    label: 'Hari Ini',
                    value: 'today',
                    selectedValue: _filter,
                    onSelected: _setFilter,
                  ),
                  _FilterChip(
                    label: 'Akan Datang',
                    value: 'upcoming',
                    selectedValue: _filter,
                    onSelected: _setFilter,
                  ),
                  _FilterChip(
                    label: 'Perlu Upload',
                    value: 'need_upload',
                    selectedValue: _filter,
                    onSelected: _setFilter,
                  ),
                  _FilterChip(
                    label: 'Lewat',
                    value: 'past',
                    selectedValue: _filter,
                    onSelected: _setFilter,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (provider.isLoading && provider.bookings.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (bookings.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(child: Text('Belum ada jadwal.')),
              )
            else
              ...bookings.map((booking) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _openDetail(booking),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.photo_camera_outlined,
                              color: Color(0xFF6C63FF),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.clientName.isEmpty
                                      ? 'Klien'
                                      : booking.clientName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(booking.packageName),
                                Text(
                                  '${booking.bookingDate} • ${booking.startTime} - ${booking.endTime}',
                                ),
                                Text(
                                  '${booking.locationTypeLabel} • ${booking.locationName}',
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    _StatusBadge(
                                      text: booking.statusLabel,
                                      color: Colors.blue,
                                    ),
                                    _StatusBadge(
                                      text: booking.paymentStatusLabel,
                                      color: Colors.green,
                                    ),
                                    _StatusBadge(
                                      text: booking.hasPhotoLink
                                          ? 'Foto Terupload'
                                          : 'Belum Upload',
                                      color: booking.hasPhotoLink
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                );
              }),

            if (provider.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                provider.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _setFilter(String value) {
    setState(() {
      _filter = value;
    });
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == selectedValue;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(value),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
