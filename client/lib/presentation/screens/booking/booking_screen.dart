import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'booking_history_screen.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/booking_addon_setting_model.dart';
import '../../../data/models/package_model.dart';
import '../../../data/models/schedule_slot_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/booking_provider.dart';
import '../payment/booking_payment_screen.dart';

class BookingScreen extends StatefulWidget {
  final PackageModel? selectedPackage;

  const BookingScreen({super.key, this.selectedPackage});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  final TextEditingController locationController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  DateTime? selectedDate;
  ScheduleSlotModel? selectedSlot;

  int extraDurationUnits = 0;
  String? selectedVideoAddonType;
  List<XFile> selectedMoodboards = [];

  @override
  void initState() {
    super.initState();

    final user = context.read<AuthProvider>().user;
    nameController = TextEditingController(text: user?.name ?? '');
    phoneController = TextEditingController(text: user?.phone ?? '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchAddons();
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    locationController.dispose();
    notesController.dispose();
    super.dispose();
  }

  bool get isOutdoor {
    final package = widget.selectedPackage;
    if (package == null) return false;
    return package.locationType.toLowerCase() == 'outdoor';
  }

  bool get isIndoor {
    final package = widget.selectedPackage;
    if (package == null) return false;
    return package.locationType.toLowerCase() == 'indoor';
  }

  Future<void> pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );

    if (picked == null) return;

    setState(() {
      selectedDate = picked;
      selectedSlot = null;
    });

    await loadSlots();
  }

  Future<void> loadSlots() async {
    if (widget.selectedPackage == null || selectedDate == null) return;

    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);

    await context.read<BookingProvider>().fetchSlots(
      packageId: widget.selectedPackage!.id,
      bookingDate: formattedDate,
      extraDurationUnits: extraDurationUnits,
    );
  }

  Future<void> pickMoodboards() async {
    final images = await _picker.pickMultiImage(imageQuality: 85);

    if (images.isEmpty) return;

    final combined = [...selectedMoodboards, ...images];

    if (combined.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Moodboard maksimal 10 file')),
      );
      return;
    }

    setState(() {
      selectedMoodboards = combined;
    });
  }

  void removeMoodboard(int index) {
    setState(() {
      selectedMoodboards.removeAt(index);
    });
  }

  Future<void> submitBooking() async {
    if (widget.selectedPackage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Paket belum dipilih')));
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih tanggal booking')),
      );
      return;
    }

    if (selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih jam booking')),
      );
      return;
    }

    if (selectedMoodboards.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Moodboard maksimal 10 file')),
      );
      return;
    }

    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);

    final success = await context.read<BookingProvider>().submitBooking(
      packageId: widget.selectedPackage!.id,
      bookingDate: formattedDate,
      startTime: selectedSlot!.startTime,
      extraDurationUnits: extraDurationUnits,
      locationName: isOutdoor ? locationController.text.trim() : null,
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      videoAddonType: selectedVideoAddonType,
      moodboards: selectedMoodboards,
    );

    if (!mounted) return;

    final bookingProvider = context.read<BookingProvider>();

    if (success) {
      final createdBooking = bookingProvider.lastCreatedBooking;

      if (createdBooking == null || createdBooking.id <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking berhasil, tetapi ID booking tidak terbaca'),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booking berhasil dibuat')));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingPaymentScreen(booking: createdBooking),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookingProvider.errorMessage ?? 'Booking gagal'),
        ),
      );
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
  }

  String formatCurrency(int value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  BookingAddonSettingModel? getSelectedAddon(
    List<BookingAddonSettingModel> addons,
  ) {
    try {
      return addons.firstWhere((e) => e.addonKey == selectedVideoAddonType);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final package = widget.selectedPackage;
    final selectedAddon = getSelectedAddon(bookingProvider.addons);

    if (package == null) {
      return const BookingHistoryScreen();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Form Booking')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Paket Dipilih',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        package.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${package.categoryName} • ${package.locationTypeLabel}',
                        style: const TextStyle(color: AppColors.grey),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${package.durationMinutes} menit • ${package.photoCount} foto edit',
                        style: const TextStyle(color: AppColors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Data Klien',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: nameController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  helperText: 'Diambil dari akun login',
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: phoneController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Nomor HP',
                  helperText: 'Diambil dari akun login',
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Add-on Layanan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                value: extraDurationUnits,
                decoration: const InputDecoration(labelText: 'Extra Duration'),
                items: const [
                  DropdownMenuItem(
                    value: 0,
                    child: Text('Tidak ada extra durasi'),
                  ),
                  DropdownMenuItem(value: 1, child: Text('+ 30 menit')),
                  DropdownMenuItem(value: 2, child: Text('+ 60 menit')),
                  DropdownMenuItem(value: 3, child: Text('+ 90 menit')),
                  DropdownMenuItem(value: 4, child: Text('+ 120 menit')),
                  DropdownMenuItem(value: 5, child: Text('+ 150 menit')),
                ],
                onChanged: (value) async {
                  setState(() {
                    extraDurationUnits = value ?? 0;
                    selectedSlot = null;
                  });

                  if (selectedDate != null) {
                    await loadSlots();
                  }
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String?>(
                value: selectedVideoAddonType,
                decoration: const InputDecoration(labelText: 'Video Cinematic'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Tanpa add-on video'),
                  ),
                  ...bookingProvider.addons.map(
                    (addon) => DropdownMenuItem<String?>(
                      value: addon.addonKey,
                      child: Text(
                        '${addon.addonName} (${formatCurrency(addon.price)})',
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedVideoAddonType = value;
                  });
                },
              ),

              if (selectedAddon != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Biaya add-on video: ${formatCurrency(selectedAddon.price)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],

              const SizedBox(height: 24),

              const Text(
                'Jadwal Booking',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              InkWell(
                onTap: pickDate,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Booking',
                  ),
                  child: Text(
                    selectedDate == null
                        ? 'Pilih tanggal booking'
                        : formatDate(selectedDate!),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (bookingProvider.isLoadingSlots)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (selectedDate != null && bookingProvider.slots.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Text(
                    'Belum ada slot tersedia di tanggal ini.',
                    style: TextStyle(color: AppColors.grey),
                  ),
                )
              else if (bookingProvider.slots.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih Jam Booking',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: bookingProvider.slots.map((slot) {
                        final isSelected =
                            selectedSlot?.startTime == slot.startTime;

                        return ChoiceChip(
                          label: Text(slot.label),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              selectedSlot = slot;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              const Text(
                'Lokasi Foto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (isIndoor)
                TextFormField(
                  initialValue: 'Indoor Studio Monoframe',
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lokasi',
                    helperText: 'Otomatis sesuai paket indoor',
                  ),
                )
              else
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lokasi Foto',
                    helperText: 'Wajib diisi untuk paket outdoor',
                  ),
                  validator: (value) {
                    if (isOutdoor && (value == null || value.trim().isEmpty)) {
                      return 'Nama lokasi outdoor wajib diisi';
                    }
                    return null;
                  },
                ),

              const SizedBox(height: 24),

              const Text(
                'Moodboard',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: pickMoodboards,
                icon: const Icon(Icons.image_outlined),
                label: Text(
                  selectedMoodboards.isEmpty
                      ? 'Tambah Moodboard'
                      : 'Tambah Lagi (${selectedMoodboards.length}/10)',
                ),
              ),
              const SizedBox(height: 10),

              if (selectedMoodboards.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(selectedMoodboards.length, (index) {
                    final item = selectedMoodboards[index];
                    final fileName = item.path.split('/').last;

                    return Chip(
                      label: Text(fileName),
                      onDeleted: () => removeMoodboard(index),
                    );
                  }),
                )
              else
                const Text(
                  'Moodboard opsional. Maksimal 10 file.',
                  style: TextStyle(color: AppColors.grey),
                ),

              const SizedBox(height: 24),

              const Text(
                'Catatan untuk Fotografer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Tulis catatan tambahan untuk fotografer',
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: bookingProvider.isSubmitting ? null : submitBooking,
                child: bookingProvider.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Booking'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
