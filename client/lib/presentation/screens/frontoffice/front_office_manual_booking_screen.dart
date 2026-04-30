import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/front_office_models.dart';
import '../../../data/providers/front_office_provider.dart';

class FrontOfficeManualBookingScreen extends StatefulWidget {
  const FrontOfficeManualBookingScreen({super.key});

  @override
  State<FrontOfficeManualBookingScreen> createState() =>
      _FrontOfficeManualBookingScreenState();
}

class _FrontOfficeManualBookingScreenState
    extends State<FrontOfficeManualBookingScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientPhoneController = TextEditingController();
  final TextEditingController _clientEmailController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _moodboards = [];

  FoPackageModel? _selectedPackage;
  FoAddonModel? _selectedAddon;
  FoScheduleSlotModel? _selectedSlot;
  FoPhotographerModel? _selectedPhotographer;

  DateTime? _selectedDate;
  int _extraDurationUnits = 0;

  static const int _maxMoodboard = 10;
  static const int _maxExtraDurationUnits = 10;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FrontOfficeProvider>().fetchManualBookingResources();
    });
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _clientEmailController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isOutdoor {
    return _selectedPackage?.locationType.toLowerCase() == 'outdoor';
  }

  bool get _isIndoor {
    return _selectedPackage?.locationType.toLowerCase() == 'indoor';
  }

  String _shortTime(String value) {
    final text = value.trim();

    if (text.isEmpty) return '-';

    final parts = text.split(':');

    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }

    return text;
  }

  String _shortSlotLabel(FoScheduleSlotModel slot) {
    final start = _shortTime(slot.startTime);
    final end = _shortTime(slot.endTime);

    return '$start - $end';
  }

  String _formatDateApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatDateDisplay(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
  }

  String _formatCurrency(int value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  int _addonPrice() {
    return _selectedAddon?.price ?? 0;
  }

  int _extraDurationFee() {
    return _selectedSlot?.extraDurationFee ?? 0;
  }

  int _totalPrice() {
    return (_selectedPackage?.finalPrice ?? 0) +
        _addonPrice() +
        _extraDurationFee();
  }

  String _effectiveSlotEndTime(FoScheduleSlotModel slot) {
    if (slot.blockedUntil.trim().isNotEmpty) {
      return slot.blockedUntil;
    }

    return slot.endTime;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final result = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _ManualBookingPalette.darkBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _ManualBookingPalette.darkBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result == null) return;

    setState(() {
      _selectedDate = result;
      _selectedSlot = null;
      _selectedPhotographer = null;
    });

    await _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    if (_selectedPackage == null || _selectedDate == null) return;

    await context.read<FrontOfficeProvider>().fetchSlots(
      packageId: _selectedPackage!.id,
      bookingDate: _formatDateApi(_selectedDate!),
      extraDurationUnits: _extraDurationUnits,
    );
  }

  Future<void> _fetchPhotographers() async {
    if (_selectedDate == null || _selectedSlot == null) return;

    await context.read<FrontOfficeProvider>().fetchManualAvailablePhotographers(
      bookingDate: _formatDateApi(_selectedDate!),
      startTime: _selectedSlot!.startTime,
      endTime: _effectiveSlotEndTime(_selectedSlot!),
    );
  }

  Future<void> _pickMoodboards() async {
    if (_moodboards.length >= _maxMoodboard) {
      _showMessage('Moodboard maksimal $_maxMoodboard file.');
      return;
    }

    final images = await _picker.pickMultiImage(imageQuality: 85);

    if (images.isEmpty) return;

    final combined = [..._moodboards, ...images];

    if (combined.length > _maxMoodboard) {
      _showMessage('Moodboard maksimal $_maxMoodboard file.');
      return;
    }

    setState(() {
      _moodboards
        ..clear()
        ..addAll(combined);
    });
  }

  void _removeMoodboard(int index) {
    setState(() {
      _moodboards.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPackage == null) {
      _showMessage('Pilih paket terlebih dahulu.');
      return;
    }

    if (_selectedDate == null) {
      _showMessage('Pilih tanggal booking.');
      return;
    }

    if (_selectedSlot == null) {
      _showMessage('Pilih jam booking.');
      return;
    }

    if (_selectedPhotographer == null) {
      _showMessage('Pilih fotografer terlebih dahulu.');
      return;
    }

    final provider = context.read<FrontOfficeProvider>();

    final ok = await provider.createManualBooking(
      packageId: _selectedPackage!.id,
      photographerUserId: _selectedPhotographer!.id,
      clientName: _clientNameController.text.trim(),
      clientPhone: _clientPhoneController.text.trim(),
      clientEmail: _clientEmailController.text.trim(),
      bookingDate: _formatDateApi(_selectedDate!),
      startTime: _selectedSlot!.startTime,
      extraDurationUnits: _extraDurationUnits,
      locationName: _isOutdoor ? _locationController.text.trim() : null,
      notes: _notesController.text.trim(),
      videoAddonType: _selectedAddon?.addonKey,
      moodboards: _moodboards,
    );

    if (!mounted) return;

    if (ok) {
      _showMessage(
        'Booking manual berhasil dibuat dan fotografer sudah dipilih',
      );
      Navigator.pop(context);
    } else {
      _showMessage(provider.errorMessage ?? 'Gagal membuat booking manual');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    String? helper,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.fromLTRB(14, 18, 12, 18),
      labelStyle: TextStyle(
        color: _ManualBookingPalette.darkBlue.withOpacity(0.68),
        fontWeight: FontWeight.w700,
      ),
      helperStyle: TextStyle(
        color: _ManualBookingPalette.darkBlue.withOpacity(0.48),
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(color: AppColors.grey),
      prefixIconColor: _ManualBookingPalette.darkBlue,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _ManualBookingPalette.cardDeep),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _ManualBookingPalette.darkBlue,
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FrontOfficeProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: _ManualBookingPalette.darkBlue,
          backgroundColor: _ManualBookingPalette.cardLight,
          onRefresh: provider.fetchManualBookingResources,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            children: [
              _TopBar(
                title: 'Booking Manual',
                onBack: () => Navigator.pop(context),
              ),

              const SizedBox(height: 14),

              const _ManualBookingHero(),

              const SizedBox(height: 22),

              if (provider.isLoading && provider.packages.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 90),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _ManualBookingPalette.darkBlue,
                    ),
                  ),
                )
              else
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle(
                        icon: Icons.photo_library_outlined,
                        title: 'Pilih Paket',
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<FoPackageModel>(
                        value: _selectedPackage,
                        isExpanded: true,
                        menuMaxHeight: 360,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        decoration: _inputDecoration(
                          label: 'Paket Foto',
                          icon: Icons.photo_library_outlined,
                        ),
                        selectedItemBuilder: (context) {
                          return provider.packages.map((package) {
                            return _DropdownSelectedText(package.name);
                          }).toList();
                        },
                        items: provider.packages.map((package) {
                          return DropdownMenuItem<FoPackageModel>(
                            value: package,
                            child: _DropdownItemText(package.name),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          setState(() {
                            _selectedPackage = value;
                            _selectedSlot = null;
                            _selectedPhotographer = null;

                            if (_isIndoor) {
                              _locationController.text =
                                  'Indoor Studio Monoframe';
                            } else {
                              _locationController.clear();
                            }
                          });

                          await _fetchSlots();
                        },
                        validator: (value) {
                          if (value == null) return 'Paket wajib dipilih';
                          return null;
                        },
                      ),

                      if (_selectedPackage != null) ...[
                        const SizedBox(height: 12),
                        _SelectedPackageCard(
                          package: _selectedPackage!,
                          formatCurrency: _formatCurrency,
                        ),
                      ],

                      const SizedBox(height: 24),

                      const _SectionTitle(
                        icon: Icons.person_outline_rounded,
                        title: 'Data Klien Offline',
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _clientNameController,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          label: 'Nama Klien',
                          hint: 'Contoh: Anisa Risma',
                          helper: 'Boleh klien tanpa akun aplikasi',
                          icon: Icons.person_outline_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama klien wajib diisi';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _clientPhoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          label: 'Nomor HP / WhatsApp',
                          hint: 'Contoh: 081234567890',
                          icon: Icons.phone_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nomor HP wajib diisi';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _clientEmailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          label: 'Email Klien',
                          hint: 'Opsional, isi kalau klien punya akun',
                          helper:
                              'Jika email cocok dengan akun klien, booking akan tertaut ke akun tersebut',
                          icon: Icons.email_outlined,
                        ),
                      ),

                      const SizedBox(height: 24),

                      const _SectionTitle(
                        icon: Icons.add_circle_outline_rounded,
                        title: 'Add-on Layanan',
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<int>(
                        value: _extraDurationUnits,
                        isExpanded: true,
                        menuMaxHeight: 360,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        decoration: _inputDecoration(
                          label: 'Extra Duration',
                          icon: Icons.timer_outlined,
                        ),
                        selectedItemBuilder: (context) {
                          return List.generate(_maxExtraDurationUnits + 1, (
                            index,
                          ) {
                            return _DropdownSelectedText(
                              index == 0
                                  ? 'Tidak ada extra durasi'
                                  : '+ ${index * 30} menit',
                            );
                          });
                        },
                        items: List.generate(_maxExtraDurationUnits + 1, (
                          index,
                        ) {
                          return DropdownMenuItem<int>(
                            value: index,
                            child: _DropdownItemText(
                              index == 0
                                  ? 'Tidak ada extra durasi'
                                  : '+ ${index * 30} menit',
                            ),
                          );
                        }),
                        onChanged: (value) async {
                          setState(() {
                            _extraDurationUnits = value ?? 0;
                            _selectedSlot = null;
                            _selectedPhotographer = null;
                          });

                          await _fetchSlots();
                        },
                      ),

                      if (_extraDurationUnits > 0 && _selectedSlot == null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Biaya extra durasi akan dihitung setelah memilih jam booking.',
                          style: TextStyle(
                            color: _ManualBookingPalette.darkBlue.withOpacity(
                              0.62,
                            ),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],

                      if (_selectedSlot != null &&
                          _selectedSlot!.extraDurationFee > 0) ...[
                        const SizedBox(height: 8),
                        _SmallPriceInfo(
                          icon: Icons.timer_rounded,
                          label:
                              'Extra duration ${_selectedSlot!.extraDurationMinutes} menit',
                          price: _formatCurrency(
                            _selectedSlot!.extraDurationFee,
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      DropdownButtonFormField<FoAddonModel?>(
                        value: _selectedAddon,
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
                            ...provider.addons.map(
                              (addon) => _DropdownSelectedText(
                                '${addon.addonName} (${_formatCurrency(addon.price)})',
                              ),
                            ),
                          ];
                        },
                        items: [
                          const DropdownMenuItem<FoAddonModel?>(
                            value: null,
                            child: _DropdownItemText('Tanpa add-on video'),
                          ),
                          ...provider.addons.map(
                            (addon) => DropdownMenuItem<FoAddonModel?>(
                              value: addon,
                              child: _DropdownItemText(
                                '${addon.addonName} (${_formatCurrency(addon.price)})',
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedAddon = value;
                          });
                        },
                      ),

                      if (_selectedAddon != null) ...[
                        const SizedBox(height: 8),
                        _SmallPriceInfo(
                          icon: Icons.movie_creation_outlined,
                          label: _selectedAddon!.addonName,
                          price: _formatCurrency(_selectedAddon!.price),
                        ),
                      ],

                      const SizedBox(height: 24),

                      const _SectionTitle(
                        icon: Icons.calendar_month_outlined,
                        title: 'Jadwal Booking',
                      ),
                      const SizedBox(height: 12),

                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(16),
                        child: InputDecorator(
                          decoration: _inputDecoration(
                            label: 'Tanggal Booking',
                            icon: Icons.date_range_outlined,
                          ),
                          child: Text(
                            _selectedDate == null
                                ? 'Pilih tanggal booking'
                                : _formatDateDisplay(_selectedDate!),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _selectedDate == null
                                  ? AppColors.grey
                                  : _ManualBookingPalette.darkBlue,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (_selectedPackage == null || _selectedDate == null)
                        const _InfoBox(
                          icon: Icons.info_outline_rounded,
                          text:
                              'Pilih paket dan tanggal untuk melihat slot tersedia.',
                          color: AppColors.grey,
                        )
                      else if (provider.isLoading && provider.slots.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: _ManualBookingPalette.darkBlue,
                            ),
                          ),
                        )
                      else if (provider.slots.isEmpty)
                        const _InfoBox(
                          icon: Icons.event_busy_rounded,
                          text: 'Belum ada slot tersedia di tanggal ini.',
                          color: AppColors.warning,
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pilih Jam Booking',
                              style: TextStyle(
                                color: _ManualBookingPalette.darkBlue
                                    .withOpacity(0.82),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: provider.slots.map((slot) {
                                final selected =
                                    _selectedSlot?.startTime == slot.startTime;

                                final cleanSlotLabel = _shortSlotLabel(slot);

                                final slotLabel = slot.extraDurationFee > 0
                                    ? '$cleanSlotLabel • +${_formatCurrency(slot.extraDurationFee)}'
                                    : cleanSlotLabel;

                                return ChoiceChip(
                                  label: Text(
                                    slotLabel,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  selected: selected,
                                  showCheckmark: false,
                                  selectedColor: _ManualBookingPalette.darkBlue,
                                  backgroundColor: Colors.white,
                                  labelStyle: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : _ManualBookingPalette.darkBlue,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                  side: BorderSide(
                                    color: selected
                                        ? _ManualBookingPalette.darkBlue
                                        : _ManualBookingPalette.cardDeep,
                                  ),
                                  onSelected: (_) async {
                                    setState(() {
                                      _selectedSlot = slot;
                                      _selectedPhotographer = null;
                                    });

                                    await _fetchPhotographers();
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),

                      const SizedBox(height: 24),

                      const _SectionTitle(
                        icon: Icons.photo_camera_outlined,
                        title: 'Assign Fotografer',
                      ),
                      const SizedBox(height: 12),

                      if (_selectedSlot == null)
                        const _InfoBox(
                          icon: Icons.info_outline_rounded,
                          text:
                              'Pilih slot booking dulu, lalu fotografer tersedia akan muncul.',
                          color: AppColors.grey,
                        )
                      else if (provider.isLoading &&
                          provider.availablePhotographers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: _ManualBookingPalette.darkBlue,
                            ),
                          ),
                        )
                      else if (provider.availablePhotographers.isEmpty)
                        const _InfoBox(
                          icon: Icons.no_photography_outlined,
                          text: 'Tidak ada fotografer tersedia pada slot ini.',
                          color: AppColors.warning,
                        )
                      else
                        Column(
                          children: provider.availablePhotographers.map((
                            photographer,
                          ) {
                            final selected =
                                _selectedPhotographer?.id == photographer.id;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _PhotographerCard(
                                photographer: photographer,
                                selected: selected,
                                onTap: photographer.isAvailable
                                    ? () {
                                        setState(() {
                                          _selectedPhotographer = photographer;
                                        });
                                      }
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: 24),

                      const _SectionTitle(
                        icon: Icons.location_on_outlined,
                        title: 'Lokasi Foto',
                      ),
                      const SizedBox(height: 12),

                      if (_isIndoor)
                        TextFormField(
                          controller: _locationController,
                          readOnly: true,
                          decoration: _inputDecoration(
                            label: 'Nama Lokasi',
                            helper: 'Otomatis sesuai paket indoor',
                            icon: Icons.home_work_outlined,
                          ),
                        )
                      else
                        TextFormField(
                          controller: _locationController,
                          decoration: _inputDecoration(
                            label: 'Nama Lokasi Foto',
                            helper: 'Wajib diisi untuk paket outdoor',
                            icon: Icons.place_outlined,
                          ),
                          validator: (value) {
                            if (_isOutdoor &&
                                (value == null || value.trim().isEmpty)) {
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
                        onPressed: _moodboards.length >= _maxMoodboard
                            ? null
                            : _pickMoodboards,
                        icon: const Icon(Icons.image_outlined),
                        label: Text(
                          _moodboards.isEmpty
                              ? 'Tambah Moodboard'
                              : 'Tambah Lagi (${_moodboards.length}/$_maxMoodboard)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _ManualBookingPalette.darkBlue,
                          side: const BorderSide(
                            color: _ManualBookingPalette.cardDeep,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (_moodboards.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(_moodboards.length, (index) {
                            final item = _moodboards[index];
                            final fileName = item.path.split('/').last;

                            return Chip(
                              label: Text(
                                fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onDeleted: () => _removeMoodboard(index),
                              backgroundColor: _ManualBookingPalette.cardMid,
                              side: const BorderSide(
                                color: _ManualBookingPalette.cardDeep,
                              ),
                              labelStyle: const TextStyle(
                                color: _ManualBookingPalette.darkBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          }),
                        )
                      else
                        Text(
                          'Moodboard opsional. Maksimal $_maxMoodboard file.',
                          style: const TextStyle(color: AppColors.grey),
                        ),

                      const SizedBox(height: 24),

                      const _SectionTitle(
                        icon: Icons.notes_outlined,
                        title: 'Catatan untuk Fotografer',
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _notesController,
                        maxLines: 4,
                        decoration: _inputDecoration(
                          label: 'Notes',
                          hint: 'Tulis catatan tambahan untuk fotografer',
                          icon: Icons.edit_note_outlined,
                        ),
                      ),

                      const SizedBox(height: 28),

                      _SubmitAndTotalRow(
                        isSubmitting: provider.isSubmitting,
                        total: _totalPrice(),
                        hasExtraDurationPending:
                            _extraDurationUnits > 0 && _selectedSlot == null,
                        formatCurrency: _formatCurrency,
                        onSubmit: _submit,
                      ),
                    ],
                  ),
                ),

              if (provider.errorMessage != null) ...[
                const SizedBox(height: 12),
                _ErrorMessageBox(message: provider.errorMessage!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ManualBookingPalette {
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

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _TopBar({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: _ManualBookingPalette.darkBlue,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.dark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _ManualBookingHero extends StatelessWidget {
  const _ManualBookingHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: _ManualBookingPalette.darkGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _ManualBookingPalette.darkBlue.withOpacity(0.16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -40,
            child: Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.11),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 36,
            bottom: -48,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.20)),
                ),
                child: const Icon(
                  Icons.add_business_rounded,
                  color: Colors.white,
                  size: 31,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Input Booking Offline',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Front Office dapat membuat booking klien tanpa akun dan langsung memilih fotografer.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.74),
                        fontSize: 12.8,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.photo_camera_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 7),
                          Text(
                            'Manual + Assign Fotografer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 30,
          width: 30,
          decoration: BoxDecoration(
            gradient: _ManualBookingPalette.softGradient,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.white),
          ),
          child: Icon(icon, color: _ManualBookingPalette.darkBlue, size: 16),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ManualBookingPalette.darkBlue,
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

class _SelectedPackageCard extends StatelessWidget {
  final FoPackageModel package;
  final String Function(int) formatCurrency;

  const _SelectedPackageCard({
    required this.package,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = package.price > package.finalPrice;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: _ManualBookingPalette.softGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.78)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.70),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.photo_library_rounded,
              color: _ManualBookingPalette.darkBlue,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ManualBookingPalette.darkBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${package.locationTypeLabel} • ${package.durationMinutes} menit • ${package.photoCount} foto',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ManualBookingPalette.darkBlue.withOpacity(0.58),
                    fontWeight: FontWeight.w700,
                    fontSize: 11.8,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    if (hasDiscount) ...[
                      Text(
                        formatCurrency(package.price),
                        style: TextStyle(
                          color: _ManualBookingPalette.darkBlue.withOpacity(
                            0.42,
                          ),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 7),
                    ],
                    Flexible(
                      child: Text(
                        formatCurrency(package.finalPrice),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ManualBookingPalette.darkBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
        gradient: _ManualBookingPalette.softGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.76)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _ManualBookingPalette.darkBlue, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ManualBookingPalette.darkBlue,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            price,
            style: const TextStyle(
              color: _ManualBookingPalette.darkBlue,
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotographerCard extends StatelessWidget {
  final FoPhotographerModel photographer;
  final bool selected;
  final VoidCallback? onTap;

  const _PhotographerCard({
    required this.photographer,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final available = photographer.isAvailable;
    final disabled = !available;

    final Color color = selected
        ? AppColors.success
        : available
        ? _ManualBookingPalette.darkBlue
        : AppColors.grey;

    final String statusLabel = selected
        ? 'Dipilih'
        : available
        ? 'Tersedia'
        : 'Bentrok';

    final IconData icon = selected
        ? Icons.check_circle_rounded
        : available
        ? Icons.photo_camera_rounded
        : Icons.block_rounded;

    return Opacity(
      opacity: disabled ? 0.62 : 1,
      child: Material(
        color: selected
            ? _ManualBookingPalette.cardLight
            : disabled
            ? AppColors.grey.withOpacity(0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: available ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AppColors.success
                    : available
                    ? _ManualBookingPalette.cardDeep
                    : AppColors.grey.withOpacity(0.26),
              ),
              boxShadow: [
                if (!disabled)
                  BoxShadow(
                    color: _ManualBookingPalette.darkBlue.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 7),
                  ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.12)),
                  ),
                  child: Icon(icon, color: color, size: 23),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photographer.name.trim().isEmpty
                            ? 'Fotografer'
                            : photographer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: disabled
                              ? AppColors.grey
                              : _ManualBookingPalette.darkBlue,
                          fontSize: 15.5,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        disabled
                            ? 'Sudah memiliki jadwal pada slot ini'
                            : photographer.email.trim().isEmpty
                            ? '-'
                            : photographer.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: disabled
                              ? AppColors.grey
                              : _ManualBookingPalette.darkBlue.withOpacity(
                                  0.56,
                                ),
                          fontSize: 11.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(label: statusLabel, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 29,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoBox({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.13)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                height: 1.35,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitAndTotalRow extends StatelessWidget {
  final bool isSubmitting;
  final int total;
  final bool hasExtraDurationPending;
  final String Function(int) formatCurrency;
  final VoidCallback onSubmit;

  const _SubmitAndTotalRow({
    required this.isSubmitting,
    required this.total,
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
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                gradient: _ManualBookingPalette.softGradient,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.78)),
                boxShadow: [
                  BoxShadow(
                    color: _ManualBookingPalette.darkBlue.withOpacity(0.055),
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
                    'Estimasi Total',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatCurrency(total),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ManualBookingPalette.darkBlue,
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
                        color: _ManualBookingPalette.darkBlue.withOpacity(0.58),
                        fontSize: 8.8,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _ManualBookingPalette.darkBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _ManualBookingPalette.darkBlue
                    .withOpacity(0.45),
                disabledForegroundColor: Colors.white.withOpacity(0.70),
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
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
                        Icon(Icons.save_rounded, size: 18),
                        SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            'Simpan Booking',
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
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorMessageBox extends StatelessWidget {
  final String message;

  const _ErrorMessageBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
