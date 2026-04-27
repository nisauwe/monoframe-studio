import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/editor_edit_request_model.dart';
import '../../../data/providers/editor_provider.dart';

class EditorCompleteFormScreen extends StatefulWidget {
  final EditorEditRequestModel editRequest;

  const EditorCompleteFormScreen({super.key, required this.editRequest});

  @override
  State<EditorCompleteFormScreen> createState() =>
      _EditorCompleteFormScreenState();
}

class _EditorCompleteFormScreenState extends State<EditorCompleteFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _resultDriveUrlController = TextEditingController();
  final _resultDriveLabelController = TextEditingController();
  final _editorNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _resultDriveUrlController.text = widget.editRequest.resultDriveUrl;
    _resultDriveLabelController.text =
        widget.editRequest.resultDriveLabel.isEmpty
        ? 'Hasil Edit ${widget.editRequest.clientName}'
        : widget.editRequest.resultDriveLabel;
    _editorNotesController.text = widget.editRequest.editorNotes;
  }

  @override
  void dispose() {
    _resultDriveUrlController.dispose();
    _resultDriveLabelController.dispose();
    _editorNotesController.dispose();
    super.dispose();
  }

  bool _isValidUrl(String value) {
    final uri = Uri.tryParse(value.trim());

    if (uri == null) return false;

    return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<EditorProvider>();

    final ok = await provider.completeEdit(
      editRequestId: widget.editRequest.id,
      resultDriveUrl: _resultDriveUrlController.text.trim(),
      resultDriveLabel: _resultDriveLabelController.text.trim(),
      editorNotes: _editorNotesController.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hasil edit berhasil dikirim')),
      );

      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Gagal menyelesaikan pekerjaan edit',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditorProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Hasil Edit')),
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
                    size: 38,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Upload hasil edit ke Google Drive, lalu masukkan link-nya di sini untuk dikirim ke klien.',
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

            Text(
              widget.editRequest.clientName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.editRequest.selectedFiles.length} file edit',
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _resultDriveUrlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Link Google Drive Hasil Edit',
                      hintText: 'https://drive.google.com/...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Link hasil edit wajib diisi';
                      }

                      if (!_isValidUrl(value)) {
                        return 'Masukkan URL yang valid';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _resultDriveLabelController,
                    decoration: const InputDecoration(
                      labelText: 'Label Link',
                      hintText: 'Contoh: Hasil Edit Anisa',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.drive_file_rename_outline),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _editorNotesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Catatan Editor',
                      hintText:
                          'Contoh: Semua file sudah diedit sesuai daftar pilihan klien.',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes_outlined),
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
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        provider.isSubmitting
                            ? 'Menyimpan...'
                            : 'Selesaikan Editing',
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
