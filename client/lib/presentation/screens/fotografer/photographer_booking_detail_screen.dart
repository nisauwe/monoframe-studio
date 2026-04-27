import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/photographer_models.dart';
import '../../../data/providers/photographer_provider.dart';
import 'photographer_photo_link_form_screen.dart';

class PhotographerBookingDetailScreen extends StatefulWidget {
  final int bookingId;

  const PhotographerBookingDetailScreen({super.key, required this.bookingId});

  @override
  State<PhotographerBookingDetailScreen> createState() =>
      _PhotographerBookingDetailScreenState();
}

class _PhotographerBookingDetailScreenState
    extends State<PhotographerBookingDetailScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PhotographerProvider>().fetchBookingDetail(
        bookingId: widget.bookingId,
      );
    });
  }

  Future<void> _refresh() {
    return context.read<PhotographerProvider>().fetchBookingDetail(
      bookingId: widget.bookingId,
    );
  }

  Future<void> _openUrl(String url) async {
    if (url.trim().isEmpty) {
      _showMessage('Link belum tersedia');
      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null) {
      _showMessage('Link tidak valid');
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!mounted) return;

    if (!opened) {
      _showMessage('Tidak bisa membuka link');
    }
  }

  void _openPhotoLinkForm(PhotographerBookingModel booking) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotographerPhotoLinkFormScreen(booking: booking),
      ),
    );

    if (!mounted) return;
    _refresh();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotographerProvider>();
    final booking = provider.selectedBooking;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Jadwal')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              if (provider.isLoading && booking == null)
                const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (booking == null)
                Padding(
                  padding: const EdgeInsets.only(top: 120),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        provider.errorMessage ??
                            'Detail booking tidak ditemukan',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else ...[
                Text(
                  booking.packageName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'ID Booking #${booking.id}',
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 18),

                _StatusBanner(booking: booking),

                const SizedBox(height: 18),

                _SectionTitle(title: 'Informasi Jadwal'),
                _InfoCard(
                  children: [
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      title: 'Tanggal',
                      value: booking.bookingDate,
                    ),
                    _InfoRow(
                      icon: Icons.access_time_outlined,
                      title: 'Jam',
                      value: '${booking.startTime} - ${booking.endTime}',
                    ),
                    _InfoRow(
                      icon: Icons.timer_outlined,
                      title: 'Durasi',
                      value:
                          '${booking.durationMinutes + booking.extraDurationMinutes} menit',
                    ),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      title: 'Lokasi',
                      value:
                          '${booking.locationTypeLabel} - ${booking.locationName}',
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                _SectionTitle(title: 'Informasi Klien'),
                _InfoCard(
                  children: [
                    _InfoRow(
                      icon: Icons.person_outline,
                      title: 'Nama Klien',
                      value: booking.clientName,
                    ),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      title: 'Nomor HP',
                      value: booking.clientPhone,
                    ),
                    if (booking.clientUser != null)
                      _InfoRow(
                        icon: Icons.email_outlined,
                        title: 'Email',
                        value: booking.clientUser!.email,
                      ),
                  ],
                ),

                const SizedBox(height: 18),

                _SectionTitle(title: 'Detail Paket'),
                _InfoCard(
                  children: [
                    _InfoRow(
                      icon: Icons.photo_camera_outlined,
                      title: 'Paket',
                      value: booking.packageName,
                    ),
                    _InfoRow(
                      icon: Icons.place_outlined,
                      title: 'Tipe Lokasi',
                      value:
                          booking.package?.locationTypeLabel ??
                          booking.locationTypeLabel,
                    ),
                    _InfoRow(
                      icon: Icons.image_outlined,
                      title: 'Jumlah Foto Edit',
                      value: '${booking.package?.photoCount ?? 0} foto',
                    ),
                    _InfoRow(
                      icon: Icons.group_outlined,
                      title: 'Jumlah Orang',
                      value: '${booking.package?.personCount ?? 0} orang',
                    ),
                    if (booking.videoAddonName.isNotEmpty)
                      _InfoRow(
                        icon: Icons.videocam_outlined,
                        title: 'Add-on Video',
                        value: booking.videoAddonName,
                      ),
                  ],
                ),

                const SizedBox(height: 18),

                _SectionTitle(title: 'Catatan & Moodboard'),
                _InfoCard(
                  children: [
                    _InfoRow(
                      icon: Icons.notes_outlined,
                      title: 'Catatan Klien',
                      value: booking.notes.isEmpty ? '-' : booking.notes,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (booking.moodboards.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Text(
                      'Klien tidak mengupload moodboard.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  Column(
                    children: booking.moodboards.map((moodboard) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.image_outlined),
                          title: Text(moodboard.originalName),
                          subtitle: Text(
                            moodboard.displayUrl.isEmpty
                                ? 'File moodboard'
                                : moodboard.displayUrl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.open_in_new),
                          onTap: () => _openUrl(moodboard.displayUrl),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 18),

                _SectionTitle(title: 'Link Hasil Foto'),
                if (booking.hasPhotoLink)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.green.withOpacity(0.18)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Link Google Drive sudah tersedia',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          booking.photoLink!.driveLabel.isEmpty
                              ? 'Hasil Foto'
                              : booking.photoLink!.driveLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.photoLink!.driveUrl,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (booking.photoLink!.notes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(booking.photoLink!.notes),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _openUrl(booking.photoLink!.driveUrl);
                                },
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Buka Link'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _openPhotoLinkForm(booking),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit Link'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openPhotoLinkForm(booking),
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Input Link Google Drive'),
                    ),
                  ),

                const SizedBox(height: 30),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final PhotographerBookingModel booking;

  const _StatusBanner({required this.booking});

  @override
  Widget build(BuildContext context) {
    final hasPhotoLink = booking.hasPhotoLink;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasPhotoLink
            ? Colors.green.withOpacity(0.08)
            : Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasPhotoLink
              ? Colors.green.withOpacity(0.18)
              : Colors.orange.withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasPhotoLink
                ? Icons.check_circle_outline
                : Icons.cloud_upload_outlined,
            color: hasPhotoLink ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasPhotoLink
                  ? 'Foto sudah diupload. Klien dapat melihat link hasil foto.'
                  : 'Setelah pemotretan selesai, upload foto ke Google Drive lalu input link di sini.',
              style: TextStyle(
                color: hasPhotoLink ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty ? '-' : value;

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(displayValue),
    );
  }
}
