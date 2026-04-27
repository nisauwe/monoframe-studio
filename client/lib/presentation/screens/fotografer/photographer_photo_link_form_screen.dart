import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/photographer_models.dart';
import '../../../data/providers/photographer_provider.dart';

class PhotographerPhotoLinkFormScreen extends StatefulWidget {
  final PhotographerBookingModel booking;

  const PhotographerPhotoLinkFormScreen({super.key, required this.booking});

  @override
  State<PhotographerPhotoLinkFormScreen> createState() =>
      _PhotographerPhotoLinkFormScreenState();
}

class _PhotographerPhotoLinkFormScreenState
    extends State<PhotographerPhotoLinkFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _driveUrlController = TextEditingController();
  final _driveLabelController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final photoLink = widget.booking.photoLink;

    if (photoLink != null) {
      _driveUrlController.text = photoLink.driveUrl;
      _driveLabelController.text = photoLink.driveLabel;
      _notesController.text = photoLink.notes;
    } else {
      _driveLabelController.text = 'Hasil Foto ${widget.booking.clientName}';
    }
  }

  @override
  void dispose() {
    _driveUrlController.dispose();
    _driveLabelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _isValidUrl(String value) {
    final uri = Uri.tryParse(value.trim());

    if (uri == null) {
      return false;
    }

    return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<PhotographerProvider>();

    final ok = await provider.storePhotoLink(
      bookingId: widget.booking.id,
      driveUrl: _driveUrlController.text.trim(),
      driveLabel: _driveLabelController.text.trim(),
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link Google Drive berhasil disimpan')),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Gagal menyimpan link Google Drive',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotographerProvider>();
    final booking = widget.booking;

    return Scaffold(
      appBar: AppBar(title: const Text('Input Link Foto')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    color: Color(0xFF6C63FF),
                    size: 36,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upload Hasil Foto',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${booking.clientName} • ${booking.bookingDate}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Langkah fotografer:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Upload hasil foto ke Google Drive.\n'
              '2. Pastikan folder/link bisa diakses klien.\n'
              '3. Copy link Google Drive.\n'
              '4. Paste link di form ini.\n'
              '5. Simpan agar tracking klien berubah.',
              style: TextStyle(height: 1.5, color: Colors.black54),
            ),

            const SizedBox(height: 24),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _driveUrlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Link Google Drive',
                      hintText: 'https://drive.google.com/...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Link Google Drive wajib diisi';
                      }

                      if (!_isValidUrl(value)) {
                        return 'Masukkan URL yang valid';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _driveLabelController,
                    decoration: const InputDecoration(
                      labelText: 'Label Link',
                      hintText: 'Contoh: Hasil Foto Anisa',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.drive_file_rename_outline),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Catatan',
                      hintText:
                          'Contoh: Semua foto original sudah diupload ke folder ini.',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.isSubmitting ? null : _submit,
                      icon: provider.isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        provider.isSubmitting
                            ? 'Menyimpan...'
                            : 'Simpan Link Google Drive',
                      ),
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
