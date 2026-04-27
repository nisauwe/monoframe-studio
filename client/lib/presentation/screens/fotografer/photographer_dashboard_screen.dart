import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/photographer_models.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/photographer_provider.dart';
import 'photographer_booking_detail_screen.dart';

class PhotographerDashboardScreen extends StatefulWidget {
  const PhotographerDashboardScreen({super.key});

  @override
  State<PhotographerDashboardScreen> createState() =>
      _PhotographerDashboardScreenState();
}

class _PhotographerDashboardScreenState
    extends State<PhotographerDashboardScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PhotographerProvider>().fetchBookings();
    });
  }

  Future<void> _refresh() {
    return context.read<PhotographerProvider>().fetchBookings();
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
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<PhotographerProvider>();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Dashboard Fotografer',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Halo, ${auth.user?.name ?? 'Fotografer'}',
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            if (provider.isLoading && provider.bookings.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: [
                  _SummaryCard(
                    title: 'Jadwal Hari Ini',
                    value: provider.todayBookings.length.toString(),
                    icon: Icons.today_outlined,
                    color: Colors.blue,
                  ),
                  _SummaryCard(
                    title: 'Akan Datang',
                    value: provider.upcomingBookings.length.toString(),
                    icon: Icons.event_available_outlined,
                    color: Colors.green,
                  ),
                  _SummaryCard(
                    title: 'Perlu Upload',
                    value: provider.needUploadBookings.length.toString(),
                    icon: Icons.cloud_upload_outlined,
                    color: Colors.orange,
                  ),
                  _SummaryCard(
                    title: 'Total Tugas',
                    value: provider.bookings.length.toString(),
                    icon: Icons.assignment_outlined,
                    color: Colors.purple,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'Jadwal Hari Ini',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),

              const SizedBox(height: 12),

              if (provider.todayBookings.isEmpty)
                _EmptyCard(
                  icon: Icons.event_busy_outlined,
                  title: 'Tidak ada jadwal hari ini',
                  message:
                      'Jadwal yang di-assign Front Office akan muncul di sini.',
                )
              else
                ...provider.todayBookings.map((booking) {
                  return _BookingCard(
                    booking: booking,
                    onTap: () => _openDetail(booking),
                  );
                }),

              const SizedBox(height: 24),

              const Text(
                'Perlu Upload Link Foto',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),

              const SizedBox(height: 12),

              if (provider.needUploadBookings.isEmpty)
                _EmptyCard(
                  icon: Icons.check_circle_outline,
                  title: 'Tidak ada upload tertunda',
                  message:
                      'Booking yang belum memiliki link Google Drive akan tampil di sini.',
                )
              else
                ...provider.needUploadBookings.take(5).map((booking) {
                  return _BookingCard(
                    booking: booking,
                    onTap: () => _openDetail(booking),
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
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final PhotographerBookingModel booking;
  final VoidCallback onTap;

  const _BookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasPhotoLink = booking.hasPhotoLink;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: hasPhotoLink
              ? Colors.green.withOpacity(0.12)
              : Colors.orange.withOpacity(0.12),
          child: Icon(
            hasPhotoLink
                ? Icons.check_circle_outline
                : Icons.cloud_upload_outlined,
            color: hasPhotoLink ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          booking.clientName.isEmpty ? 'Klien' : booking.clientName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(booking.packageName),
              Text(
                '${booking.bookingDate} • ${booking.startTime} - ${booking.endTime}',
              ),
              Text('${booking.locationTypeLabel} • ${booking.locationName}'),
              Text(
                hasPhotoLink
                    ? 'Link foto sudah diupload'
                    : 'Belum upload link foto',
                style: TextStyle(
                  color: hasPhotoLink ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: Colors.grey),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
