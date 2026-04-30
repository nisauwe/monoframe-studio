import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'booking_history_screen.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/app_setting_model.dart';
import '../../../data/models/booking_addon_setting_model.dart';
import '../../../data/models/package_model.dart';
import '../../../data/models/schedule_slot_model.dart';
import '../../../data/providers/app_setting_provider.dart';
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
      context.read<AppSettingProvider>().fetchSettings();
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

  int _maxMoodboardUpload(BookingSetting setting) {
    if (setting.maxMoodboardUpload <= 0) return 10;
    return setting.maxMoodboardUpload;
  }

  int _maxExtraDurationUnits(BookingSetting setting) {
    if (setting.maxExtraDurationUnits < 0) return 0;
    return setting.maxExtraDurationUnits;
  }

  int _safeExtraDurationValue(int maxUnits) {
    if (extraDurationUnits < 0) return 0;
    if (extraDurationUnits > maxUnits) return 0;
    return extraDurationUnits;
  }

  List<DropdownMenuItem<int>> extraDurationItems(int maxUnits) {
    final safeMax = maxUnits < 0 ? 0 : maxUnits;

    return List.generate(safeMax + 1, (index) {
      if (index == 0) {
        return const DropdownMenuItem<int>(
          value: 0,
          child: _DropdownItemText('Tidak ada extra durasi'),
        );
      }

      return DropdownMenuItem<int>(
        value: index,
        child: _DropdownItemText('+ ${index * 30} menit'),
      );
    });
  }

  List<Widget> extraDurationSelectedItems(int maxUnits) {
    final safeMax = maxUnits < 0 ? 0 : maxUnits;

    return List.generate(safeMax + 1, (index) {
      if (index == 0) {
        return const _DropdownSelectedText('Tidak ada extra durasi');
      }

      return _DropdownSelectedText('+ ${index * 30} menit');
    });
  }

  Future<void> pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _BookingPalette.darkBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _BookingPalette.darkBlue,
            ),
          ),
          child: child!,
        );
      },
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
    final setting = context.read<AppSettingProvider>().setting.booking;
    final maxUpload = _maxMoodboardUpload(setting);

    final images = await _picker.pickMultiImage(imageQuality: 85);

    if (images.isEmpty) return;

    final combined = [...selectedMoodboards, ...images];

    if (combined.length > maxUpload) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Moodboard maksimal $maxUpload file')),
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
    final appSetting = context.read<AppSettingProvider>().setting;
    final bookingSetting = appSetting.booking;
    final maxMoodboardUpload = _maxMoodboardUpload(bookingSetting);

    if (!bookingSetting.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bookingSetting.closedMessage.isNotEmpty
                ? bookingSetting.closedMessage
                : 'Booking sedang ditutup oleh admin.',
          ),
        ),
      );
      return;
    }

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

    if (selectedMoodboards.length > maxMoodboardUpload) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Moodboard maksimal $maxMoodboardUpload file')),
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

  int packageOriginalPrice(PackageModel package) {
    return package.price.round();
  }

  int packageFinalPrice(PackageModel package) {
    return package.finalPrice.round();
  }

  int videoAddonPrice(BookingAddonSettingModel? addon) {
    return addon?.price ?? 0;
  }

  int extraDurationFee() {
    return selectedSlot?.extraDurationFee ?? 0;
  }

  int totalOriginalPrice(
    PackageModel package,
    BookingAddonSettingModel? addon,
  ) {
    return packageOriginalPrice(package) +
        videoAddonPrice(addon) +
        extraDurationFee();
  }

  int totalFinalPrice(PackageModel package, BookingAddonSettingModel? addon) {
    return packageFinalPrice(package) +
        videoAddonPrice(addon) +
        extraDurationFee();
  }

  bool hasPackageDiscount(PackageModel package) {
    return package.hasDiscount &&
        packageOriginalPrice(package) > packageFinalPrice(package);
  }

  @override
  Widget build(BuildContext context) {
    final appSettingProvider = context.watch<AppSettingProvider>();
    final bookingProvider = context.watch<BookingProvider>();

    final package = widget.selectedPackage;
    final bookingSetting = appSettingProvider.setting.booking;
    final maxMoodboardUpload = _maxMoodboardUpload(bookingSetting);
    final maxExtraDurationUnits = _maxExtraDurationUnits(bookingSetting);

    if (extraDurationUnits > maxExtraDurationUnits) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        setState(() {
          extraDurationUnits = 0;
          selectedSlot = null;
        });
      });
    }

    final selectedAddon = getSelectedAddon(bookingProvider.addons);

    if (package == null) {
      return const BookingHistoryScreen();
    }

    if (!bookingSetting.isActive) {
      return _BookingClosedView(message: bookingSetting.closedMessage);
    }

    final originalTotal = totalOriginalPrice(package, selectedAddon);
    final finalTotal = totalFinalPrice(package, selectedAddon);
    final discountActive = hasPackageDiscount(package);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: _BookingPalette.darkBlue,
        centerTitle: true,
        title: const Text(
          'Form Booking',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _BookingPalette.darkBlue,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              _SelectedPackageCard(
                package: package,
                formatCurrency: formatCurrency,
              ),

              const SizedBox(height: 22),

              const _SectionTitle(
                icon: Icons.person_outline_rounded,
                title: 'Data Klien',
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: nameController,
                readOnly: true,
                decoration: _inputDecoration(
                  label: 'Nama',
                  helper: 'Diambil dari akun login',
                  icon: Icons.person_outline_rounded,
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: phoneController,
                readOnly: true,
                decoration: _inputDecoration(
                  label: 'Nomor HP',
                  helper: 'Diambil dari akun login',
                  icon: Icons.phone_outlined,
                ),
              ),

              const SizedBox(height: 24),

              const _SectionTitle(
                icon: Icons.add_circle_outline_rounded,
                title: 'Add-on Layanan',
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                value: _safeExtraDurationValue(maxExtraDurationUnits),
                isExpanded: true,
                menuMaxHeight: 360,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                decoration: _inputDecoration(
                  label: 'Extra Duration',
                  icon: Icons.timer_outlined,
                ),
                selectedItemBuilder: (context) {
                  return extraDurationSelectedItems(maxExtraDurationUnits);
                },
                items: extraDurationItems(maxExtraDurationUnits),
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

              if (maxExtraDurationUnits <= 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Extra duration sedang tidak tersedia.',
                  style: TextStyle(
                    color: _BookingPalette.darkBlue.withValues(alpha: 0.62),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              if (extraDurationUnits > 0 && selectedSlot == null) ...[
                const SizedBox(height: 8),
                Text(
                  'Biaya extra durasi akan dihitung setelah kamu memilih jam booking.',
                  style: TextStyle(
                    color: _BookingPalette.darkBlue.withValues(alpha: 0.62),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              if (selectedSlot != null &&
                  selectedSlot!.extraDurationFee > 0) ...[
                const SizedBox(height: 8),
                _SmallPriceInfo(
                  icon: Icons.timer_rounded,
                  label:
                      'Extra duration ${selectedSlot!.extraDurationMinutes} menit',
                  price: formatCurrency(selectedSlot!.extraDurationFee),
                ),
              ],

              const SizedBox(height: 16),

              DropdownButtonFormField<String?>(
                value: selectedVideoAddonType,
                isExpanded: true,
                menuMaxHeight: 360,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                decoration: _inputDecoration(
                  label: 'Video Cinematic',
                  icon: Icons.videocam_outlined,
                ),
                selectedItemBuilder: (context) {
                  return [
                    const _DropdownSelectedText('Tanpa add-on video'),
                    ...bookingProvider.addons.map(
                      (addon) => _DropdownSelectedText(
                        '${addon.addonName} (${formatCurrency(addon.price)})',
                      ),
                    ),
                  ];
                },
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: _DropdownItemText('Tanpa add-on video'),
                  ),
                  ...bookingProvider.addons.map(
                    (addon) => DropdownMenuItem<String?>(
                      value: addon.addonKey,
                      child: _DropdownItemText(
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
                const SizedBox(height: 8),
                _SmallPriceInfo(
                  icon: Icons.movie_creation_outlined,
                  label: selectedAddon.addonName,
                  price: formatCurrency(selectedAddon.price),
                ),
              ],

              const SizedBox(height: 24),

              const _SectionTitle(
                icon: Icons.calendar_month_outlined,
                title: 'Jadwal Booking',
              ),

              const SizedBox(height: 12),

              InkWell(
                onTap: pickDate,
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: _inputDecoration(
                    label: 'Tanggal Booking',
                    icon: Icons.date_range_outlined,
                  ),
                  child: Text(
                    selectedDate == null
                        ? 'Pilih tanggal booking'
                        : formatDate(selectedDate!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selectedDate == null
                          ? AppColors.grey
                          : _BookingPalette.darkBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              if (bookingProvider.isLoadingSlots)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _BookingPalette.darkBlue,
                    ),
                  ),
                )
              else if (selectedDate != null && bookingProvider.slots.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: _BookingPalette.softGradient,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _BookingPalette.cardDeep),
                  ),
                  child: const Text(
                    'Belum ada slot tersedia di tanggal ini.',
                    style: TextStyle(
                      color: _BookingPalette.darkBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else if (bookingProvider.slots.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Jam Booking',
                      style: TextStyle(
                        color: _BookingPalette.darkBlue.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: bookingProvider.slots.map((slot) {
                        final isSelected =
                            selectedSlot?.startTime == slot.startTime;

                        final slotLabel = slot.extraDurationFee > 0
                            ? '${slot.label} • +${formatCurrency(slot.extraDurationFee)}'
                            : slot.label;

                        return ChoiceChip(
                          label: Text(
                            slotLabel,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: isSelected,
                          selectedColor: _BookingPalette.darkBlue,
                          backgroundColor: Colors.white,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : _BookingPalette.darkBlue,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? _BookingPalette.darkBlue
                                : _BookingPalette.cardDeep,
                          ),
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

              const _SectionTitle(
                icon: Icons.location_on_outlined,
                title: 'Lokasi Foto',
              ),

              const SizedBox(height: 12),

              if (isIndoor)
                TextFormField(
                  initialValue: 'Indoor Studio Monoframe',
                  readOnly: true,
                  decoration: _inputDecoration(
                    label: 'Nama Lokasi',
                    helper: 'Otomatis sesuai paket indoor',
                    icon: Icons.home_work_outlined,
                  ),
                )
              else
                TextFormField(
                  controller: locationController,
                  decoration: _inputDecoration(
                    label: 'Nama Lokasi Foto',
                    helper: 'Wajib diisi untuk paket outdoor',
                    icon: Icons.place_outlined,
                  ),
                  validator: (value) {
                    if (isOutdoor && (value == null || value.trim().isEmpty)) {
                      return 'Nama lokasi outdoor wajib diisi';
                    }

                    return null;
                  },
                ),

              const SizedBox(height: 24),

              const _SectionTitle(
                icon: Icons.image_outlined,
                title: 'Moodboard',
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: pickMoodboards,
                icon: const Icon(Icons.image_outlined),
                label: Text(
                  selectedMoodboards.isEmpty
                      ? 'Tambah Moodboard'
                      : 'Tambah Lagi (${selectedMoodboards.length}/$maxMoodboardUpload)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _BookingPalette.darkBlue,
                  side: const BorderSide(color: _BookingPalette.cardDeep),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
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
                      label: Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onDeleted: () => removeMoodboard(index),
                      backgroundColor: _BookingPalette.cardMid,
                      side: const BorderSide(color: _BookingPalette.cardDeep),
                      labelStyle: const TextStyle(
                        color: _BookingPalette.darkBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }),
                )
              else
                Text(
                  'Moodboard opsional. Maksimal $maxMoodboardUpload file.',
                  style: const TextStyle(color: AppColors.grey),
                ),

              const SizedBox(height: 24),

              const _SectionTitle(
                icon: Icons.notes_outlined,
                title: 'Catatan untuk Fotografer',
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: notesController,
                maxLines: 4,
                decoration: _inputDecoration(
                  label: 'Notes',
                  hint: 'Tulis catatan tambahan untuk fotografer',
                  icon: Icons.edit_note_outlined,
                ),
              ),

              if (bookingSetting.policy.isNotEmpty ||
                  bookingSetting.terms.isNotEmpty) ...[
                const SizedBox(height: 24),
                const _SectionTitle(
                  icon: Icons.policy_outlined,
                  title: 'Kebijakan Booking',
                ),
                const SizedBox(height: 12),
                _BookingPolicyCard(
                  policy: bookingSetting.policy,
                  terms: bookingSetting.terms,
                ),
              ],

              const SizedBox(height: 28),

              _SubmitAndTotalRow(
                isSubmitting: bookingProvider.isSubmitting,
                originalTotal: originalTotal,
                finalTotal: finalTotal,
                hasDiscount: discountActive,
                hasExtraDurationPending:
                    extraDurationUnits > 0 && selectedSlot == null,
                formatCurrency: formatCurrency,
                onSubmit: submitBooking,
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? helper,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: Colors.white,
      isDense: false,
      contentPadding: const EdgeInsets.fromLTRB(14, 18, 12, 18),
      labelStyle: TextStyle(
        color: _BookingPalette.darkBlue.withValues(alpha: 0.68),
        fontWeight: FontWeight.w700,
      ),
      helperStyle: TextStyle(
        color: _BookingPalette.darkBlue.withValues(alpha: 0.46),
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(color: AppColors.grey),
      prefixIconColor: _BookingPalette.darkBlue,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _BookingPalette.cardDeep),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _BookingPalette.darkBlue,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
      ),
    );
  }
}

class _BookingPalette {
  static const Color darkBlue = Color(0xFF233B93);
  static const Color midBlue = Color(0xFF344FA5);
  static const Color lightBlue = Color(0xFF5E7BDA);

  static const Color cardLight = Color(0xFFF0FAFF);
  static const Color cardMid = Color(0xFFD9F0FA);
  static const Color cardDeep = Color(0xFFC5E4F2);

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkBlue, midBlue, lightBlue],
  );

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardLight, cardMid, cardDeep],
  );
}

class _BookingClosedView extends StatelessWidget {
  final String message;

  const _BookingClosedView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: _BookingPalette.darkBlue,
        centerTitle: true,
        title: const Text(
          'Form Booking',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _BookingPalette.darkBlue,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
              decoration: BoxDecoration(
                gradient: _BookingPalette.softGradient,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
                boxShadow: [
                  BoxShadow(
                    color: _BookingPalette.darkBlue.withValues(alpha: 0.07),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.event_busy_rounded,
                      color: _BookingPalette.darkBlue,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Booking Sedang Ditutup',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _BookingPalette.darkBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message.isNotEmpty
                        ? message
                        : 'Booking sementara ditutup. Silakan hubungi admin untuk informasi lebih lanjut.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _BookingPalette.darkBlue.withValues(alpha: 0.66),
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownSelectedText extends StatelessWidget {
  final String text;

  const _DropdownSelectedText(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: const TextStyle(
          color: AppColors.dark,
          fontSize: 15.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DropdownItemText extends StatelessWidget {
  final String text;

  const _DropdownItemText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: const TextStyle(
        color: AppColors.dark,
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SelectedPackageCard extends StatelessWidget {
  final PackageModel package;
  final String Function(int) formatCurrency;

  const _SelectedPackageCard({
    required this.package,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final originalPrice = package.price.round();
    final finalPrice = package.finalPrice.round();
    final hasDiscount = package.hasDiscount && originalPrice > finalPrice;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: _BookingPalette.darkGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _BookingPalette.darkBlue.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -36,
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paket Dipilih',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                package.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${package.categoryName} • ${package.locationTypeLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.84),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${package.durationMinutes} menit • ${package.photoCount} foto edit',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (hasDiscount)
                    Text(
                      formatCurrency(originalPrice),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.56),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Colors.white,
                      ),
                    ),
                  Text(
                    formatCurrency(finalPrice),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (hasDiscount)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${package.activeDiscount?.discountPercent ?? 0}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: _BookingPalette.softGradient,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.white),
          ),
          child: Icon(icon, color: _BookingPalette.darkBlue, size: 16),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _BookingPalette.darkBlue,
              fontSize: 16,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _SmallPriceInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String price;

  const _SmallPriceInfo({
    required this.icon,
    required this.label,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        gradient: _BookingPalette.softGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.76)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _BookingPalette.darkBlue, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _BookingPalette.darkBlue,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            price,
            style: const TextStyle(
              color: _BookingPalette.darkBlue,
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingPolicyCard extends StatelessWidget {
  final String policy;
  final String terms;

  const _BookingPolicyCard({required this.policy, required this.terms});

  @override
  Widget build(BuildContext context) {
    final hasPolicy = policy.trim().isNotEmpty;
    final hasTerms = terms.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: _BookingPalette.softGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPolicy) ...[
            const Text(
              'Catatan Kebijakan',
              style: TextStyle(
                color: _BookingPalette.darkBlue,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              policy,
              style: TextStyle(
                color: _BookingPalette.darkBlue.withValues(alpha: 0.68),
                height: 1.45,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (hasPolicy && hasTerms) const SizedBox(height: 12),
          if (hasTerms) ...[
            const Text(
              'Syarat & Ketentuan',
              style: TextStyle(
                color: _BookingPalette.darkBlue,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              terms,
              style: TextStyle(
                color: _BookingPalette.darkBlue.withValues(alpha: 0.68),
                height: 1.45,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubmitAndTotalRow extends StatelessWidget {
  final bool isSubmitting;
  final int originalTotal;
  final int finalTotal;
  final bool hasDiscount;
  final bool hasExtraDurationPending;
  final String Function(int) formatCurrency;
  final VoidCallback onSubmit;

  const _SubmitAndTotalRow({
    required this.isSubmitting,
    required this.originalTotal,
    required this.finalTotal,
    required this.hasDiscount,
    required this.hasExtraDurationPending,
    required this.formatCurrency,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: hasExtraDurationPending ? 92 : 74,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: _TotalPriceCard(
              originalTotal: originalTotal,
              finalTotal: finalTotal,
              hasDiscount: hasDiscount,
              hasExtraDurationPending: hasExtraDurationPending,
              formatCurrency: formatCurrency,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: _SubmitBookingCard(
              isSubmitting: isSubmitting,
              onSubmit: onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalPriceCard extends StatelessWidget {
  final int originalTotal;
  final int finalTotal;
  final bool hasDiscount;
  final bool hasExtraDurationPending;
  final String Function(int) formatCurrency;

  const _TotalPriceCard({
    required this.originalTotal,
    required this.finalTotal,
    required this.hasDiscount,
    required this.hasExtraDurationPending,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        gradient: _BookingPalette.softGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
        boxShadow: [
          BoxShadow(
            color: _BookingPalette.darkBlue.withValues(alpha: 0.055),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Harga',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          if (hasDiscount)
            Text(
              formatCurrency(originalTotal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _BookingPalette.darkBlue.withValues(alpha: 0.42),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          Text(
            formatCurrency(finalTotal),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _BookingPalette.darkBlue,
              fontSize: 15,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (hasExtraDurationPending) ...[
            const SizedBox(height: 4),
            Text(
              '+ extra durasi setelah jam dipilih',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _BookingPalette.darkBlue.withValues(alpha: 0.58),
                fontSize: 8.8,
                height: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubmitBookingCard extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _SubmitBookingCard({
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isSubmitting ? null : onSubmit,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: _BookingPalette.darkBlue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _BookingPalette.darkBlue.withValues(
          alpha: 0.45,
        ),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.70),
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      child: isSubmitting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month_rounded, size: 18),
                SizedBox(width: 7),
                Flexible(
                  child: Text(
                    'Submit Booking',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
