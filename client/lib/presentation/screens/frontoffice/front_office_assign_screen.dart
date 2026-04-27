import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/front_office_models.dart';
import '../../../data/providers/front_office_provider.dart';

class FrontOfficeAssignScreen extends StatefulWidget {
  const FrontOfficeAssignScreen({super.key});

  @override
  State<FrontOfficeAssignScreen> createState() =>
      _FrontOfficeAssignScreenState();
}

class _FrontOfficeAssignScreenState extends State<FrontOfficeAssignScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FrontOfficeProvider>().fetchAssignableBookings();
    });
  }

  Future<void> _openAssignDialog(FoBookingModel booking) async {
    final provider = context.read<FrontOfficeProvider>();

    await provider.fetchAvailablePhotographers(bookingId: booking.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) {
        return Consumer<FrontOfficeProvider>(
          builder: (context, provider, _) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih Fotografer',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${booking.clientName} • ${booking.bookingDate} ${booking.startTime}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),

                          if (provider.availablePhotographers.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 30),
                              child: Center(
                                child: Text(
                                  'Tidak ada fotografer tersedia pada slot ini.',
                                ),
                              ),
                            )
                          else
                            ...provider.availablePhotographers.map((item) {
                              return Card(
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.photo_camera_outlined,
                                  ),
                                  title: Text(item.name),
                                  subtitle: Text(
                                    item.email.isEmpty ? '-' : item.email,
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: provider.isSubmitting
                                        ? null
                                        : () async {
                                            final ok = await provider
                                                .assignPhotographer(
                                                  bookingId: booking.id,
                                                  photographerUserId: item.id,
                                                );

                                            if (!mounted) return;

                                            if (ok) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Fotografer berhasil di-assign',
                                                  ),
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    provider.errorMessage ??
                                                        'Gagal assign fotografer',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                    child: const Text('Assign'),
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FrontOfficeProvider>();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: provider.fetchAssignableBookings,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Assign Fotografer',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Booking yang sudah DP/lunas akan muncul di sini untuk dipilihkan fotografer.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            if (provider.isLoading && provider.assignableBookings.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.assignableBookings.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: Text('Belum ada booking yang perlu di-assign.'),
                ),
              )
            else
              ...provider.assignableBookings.map((booking) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.clientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Paket: ${booking.packageName}'),
                        Text('Tanggal: ${booking.bookingDate}'),
                        Text('Jam: ${booking.startTime} - ${booking.endTime}'),
                        Text('Pembayaran: ${booking.paymentStatusLabel}'),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: booking.canAssign
                                ? () => _openAssignDialog(booking)
                                : null,
                            icon: const Icon(Icons.assignment_ind_outlined),
                            label: const Text('Pilih Fotografer'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

            if (provider.errorMessage != null) ...[
              const SizedBox(height: 12),
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
}
