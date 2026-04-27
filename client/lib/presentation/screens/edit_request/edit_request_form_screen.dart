import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/providers/edit_request_provider.dart';

class EditRequestFormScreen extends StatefulWidget {
  final int bookingId;
  final int maxPhotoCount;

  const EditRequestFormScreen({
    super.key,
    required this.bookingId,
    required this.maxPhotoCount,
  });

  @override
  State<EditRequestFormScreen> createState() => _EditRequestFormScreenState();
}

class _EditRequestFormScreenState extends State<EditRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final List<TextEditingController> _fileControllers = [];

  @override
  void initState() {
    super.initState();
    _buildMaxFields();
  }

  @override
  void dispose() {
    for (final controller in _fileControllers) {
      controller.dispose();
    }

    _notesController.dispose();
    super.dispose();
  }

  void _buildMaxFields() {
    final max = widget.maxPhotoCount <= 0 ? 1 : widget.maxPhotoCount;

    for (int i = 0; i < max; i++) {
      _fileControllers.add(TextEditingController());
    }
  }

  List<String> _filledFiles() {
    return _fileControllers
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  String? _duplicateFileName(List<String> files) {
    final seen = <String>{};

    for (final file in files) {
      final normalized = file.toUpperCase();

      if (seen.contains(normalized)) {
        return file;
      }

      seen.add(normalized);
    }

    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final files = _filledFiles();

    if (files.isEmpty) {
      _showMessage('Minimal isi 1 nama file foto.');
      return;
    }

    if (files.length > widget.maxPhotoCount) {
      _showMessage('Maksimal ${widget.maxPhotoCount} nama file foto.');
      return;
    }

    final duplicate = _duplicateFileName(files);

    if (duplicate != null) {
      _showMessage(
        'Nama file "$duplicate" duplikat. Setiap nama file harus berbeda.',
      );
      return;
    }

    final provider = context.read<EditRequestProvider>();

    final ok = await provider.submitEditRequest(
      bookingId: widget.bookingId,
      selectedFiles: files,
      requestNotes: _notesController.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      _showMessage('Daftar foto edit berhasil dikirim.');
      Navigator.pop(context, true);
    } else {
      _showMessage(provider.errorMessage ?? 'Gagal mengirim daftar foto edit.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditRequestProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Foto Edit')),
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
                    Icons.edit_note_outlined,
                    color: Color(0xFF6C63FF),
                    size: 38,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Paket kamu mendapatkan maksimal ${widget.maxPhotoCount} foto edit. Isi nama file yang ingin diedit.',
                      style: const TextStyle(
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Contoh nama file:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'DSC03456, DSC03457, IMG_1201',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  ...List.generate(_fileControllers.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: _fileControllers[index],
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Nama File ${index + 1}',
                          hintText: 'Contoh: DSC03456',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.image_outlined),
                          helperText: index == 0
                              ? 'Minimal isi 1 file. Maksimal ${widget.maxPhotoCount} file.'
                              : null,
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Catatan Edit',
                      hintText:
                          'Contoh: tone soft, kulit natural, background jangan diubah.',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),

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
                          : const Icon(Icons.send_outlined),
                      label: Text(
                        provider.isSubmitting
                            ? 'Mengirim...'
                            : 'Kirim Daftar Foto Edit',
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
