import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

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
  final _formKey = GlobalKey<FormState>();

  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  final List<XFile> _moodboards = [];

  FoPackageModel? _selectedPackage;
  FoAddonModel? _selectedAddon;
  FoScheduleSlotModel? _selectedSlot;

  DateTime? _selectedDate;
  int _extraDurationUnits = 0;

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

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (result == null) return;

    setState(() {
      _selectedDate = result;
      _selectedSlot = null;
    });

    await _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    if (_selectedPackage == null || _selectedDate == null) return;

    await context.read<FrontOfficeProvider>().fetchSlots(
      packageId: _selectedPackage!.id,
      bookingDate: _formatDate(_selectedDate!),
      extraDurationUnits: _extraDurationUnits,
    );
  }

  Future<void> _pickMoodboards() async {
    final picker = ImagePicker();

    final files = await picker.pickMultiImage();

    if (files.isEmpty) return;

    final remaining = 10 - _moodboards.length;

    setState(() {
      _moodboards.addAll(files.take(remaining));
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

    final provider = context.read<FrontOfficeProvider>();

    final ok = await provider.createManualBooking(
      packageId: _selectedPackage!.id,
      clientName: _clientNameController.text.trim(),
      clientPhone: _clientPhoneController.text.trim(),
      clientEmail: _clientEmailController.text.trim(),
      bookingDate: _formatDate(_selectedDate!),
      startTime: _selectedSlot!.startTime,
      extraDurationUnits: _extraDurationUnits,
      locationName: _locationController.text.trim(),
      notes: _notesController.text.trim(),
      videoAddonType: _selectedAddon?.addonKey,
      moodboards: _moodboards,
    );

    if (!mounted) return;

    if (ok) {
      _showMessage('Booking manual berhasil dibuat');
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FrontOfficeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Manual')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.fetchManualBookingResources,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Input Booking Offline',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              const SizedBox(height: 6),
              const Text(
                'Digunakan Front Office untuk input booking klien yang datang langsung.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              if (provider.isLoading && provider.packages.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<FoPackageModel>(
                        value: _selectedPackage,
                        decoration: const InputDecoration(
                          labelText: 'Paket Foto',
                          border: OutlineInputBorder(),
                        ),
                        items: provider.packages.map((package) {
                          return DropdownMenuItem(
                            value: package,
                            child: Text(package.name),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          setState(() {
                            _selectedPackage = value;
                            _selectedSlot = null;
                          });

                          await _fetchSlots();
                        },
                        validator: (value) {
                          if (value == null) return 'Paket wajib dipilih';
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _clientNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Klien',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama klien wajib diisi';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _clientPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Nomor HP/WhatsApp',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nomor HP wajib diisi';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _clientEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Klien jika sudah punya akun',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: const Text('Tanggal Booking'),
                        subtitle: Text(
                          _selectedDate == null
                              ? 'Belum dipilih'
                              : _formatDate(_selectedDate!),
                        ),
                        trailing: TextButton(
                          onPressed: _pickDate,
                          child: const Text('Pilih'),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          const Expanded(child: Text('Extra Duration')),
                          IconButton(
                            onPressed: _extraDurationUnits <= 0
                                ? null
                                : () async {
                                    setState(() {
                                      _extraDurationUnits--;
                                      _selectedSlot = null;
                                    });
                                    await _fetchSlots();
                                  },
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('${_extraDurationUnits * 30} menit'),
                          IconButton(
                            onPressed: () async {
                              setState(() {
                                _extraDurationUnits++;
                                _selectedSlot = null;
                              });
                              await _fetchSlots();
                            },
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Pilih Jam',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (provider.slots.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            'Slot belum tersedia. Pilih paket dan tanggal terlebih dahulu.',
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: provider.slots.map((slot) {
                            final selected =
                                _selectedSlot?.startTime == slot.startTime;

                            return ChoiceChip(
                              label: Text(slot.label),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedSlot = slot;
                                });
                              },
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lokasi Foto',
                          helperText:
                              'Indoor akan otomatis diisi oleh backend. Outdoor wajib diisi.',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      DropdownButtonFormField<FoAddonModel?>(
                        value: _selectedAddon,
                        decoration: const InputDecoration(
                          labelText: 'Add-on Video',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<FoAddonModel?>(
                            value: null,
                            child: Text('Tanpa video'),
                          ),
                          ...provider.addons.map((addon) {
                            return DropdownMenuItem<FoAddonModel?>(
                              value: addon,
                              child: Text(addon.addonName),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedAddon = value;
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _notesController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Catatan untuk Fotografer',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _moodboards.length >= 10
                              ? null
                              : _pickMoodboards,
                          icon: const Icon(Icons.image_outlined),
                          label: Text(
                            'Tambah Moodboard (${_moodboards.length}/10)',
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: provider.isSubmitting ? null : _submit,
                          child: provider.isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Simpan Booking Manual'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
