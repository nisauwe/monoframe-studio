import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/edit_request_model.dart';
import '../../../data/providers/edit_request_provider.dart';
import 'edit_request_form_screen.dart';
import '../../../core/utils/indonesian_date_formatter.dart';

class EditRequestSection extends StatefulWidget {
  final int bookingId;
  final int maxPhotoCount;
  final bool hasPhotoLink;
  final bool canOpenPhotoLink;

  const EditRequestSection({
    super.key,
    required this.bookingId,
    required this.maxPhotoCount,
    required this.hasPhotoLink,
    required this.canOpenPhotoLink,
  });

  @override
  State<EditRequestSection> createState() => _EditRequestSectionState();
}

class _EditRequestSectionState extends State<EditRequestSection> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EditRequestProvider>().fetchEditRequest(
        bookingId: widget.bookingId,
      );
    });
  }

  Future<void> _refresh() async {
    await context.read<EditRequestProvider>().fetchEditRequest(
      bookingId: widget.bookingId,
    );
  }

  Future<void> _openForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditRequestFormScreen(
          bookingId: widget.bookingId,
          maxPhotoCount: widget.maxPhotoCount,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditRequestProvider>();
    final editRequest = provider.editRequest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),

        const Row(
          children: [
            Icon(Icons.edit_note_outlined),
            SizedBox(width: 8),
            Text(
              'Daftar Foto Edit',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (provider.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (!widget.hasPhotoLink)
          const _InfoBox(
            color: Colors.orange,
            title: 'Link foto belum tersedia',
            message:
                'Form daftar foto edit akan muncul setelah fotografer mengupload link hasil foto.',
          )
        else if (!widget.canOpenPhotoLink)
          const _InfoBox(
            color: Colors.orange,
            title: 'Pelunasan belum selesai',
            message:
                'Kamu bisa mengirim daftar foto edit setelah pelunasan booking selesai.',
          )
        else if (widget.maxPhotoCount <= 0)
          const _InfoBox(
            color: Colors.red,
            title: 'Jumlah foto edit belum valid',
            message:
                'Jumlah foto edit pada paket belum terbaca. Cek field photo_count pada paket foto.',
          )
        else if (editRequest == null)
          _InputEditRequestCard(
            maxPhotoCount: widget.maxPhotoCount,
            onTap: _openForm,
          )
        else
          _EditRequestResultCard(
            editRequest: editRequest,
            maxPhotoCount: widget.maxPhotoCount,
            canEditAgain:
                provider.canSubmitEditRequest &&
                editRequest.status == 'submitted',
            onEdit: _openForm,
          ),

        if (provider.errorMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            provider.errorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ],
    );
  }
}

class _InputEditRequestCard extends StatelessWidget {
  final int maxPhotoCount;
  final VoidCallback onTap;

  const _InputEditRequestCard({
    required this.maxPhotoCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paket kamu mendapatkan maksimal $maxPhotoCount foto edit.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Masukkan nama file foto yang ingin diedit, misalnya DSC03456.',
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Input Daftar Foto Edit'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditRequestResultCard extends StatelessWidget {
  final EditRequestModel editRequest;
  final int maxPhotoCount;
  final bool canEditAgain;
  final VoidCallback onEdit;

  const _EditRequestResultCard({
    required this.editRequest,
    required this.maxPhotoCount,
    required this.canEditAgain,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isAssigned = editRequest.isAssigned || editRequest.isInProgress;
    final isCompleted = editRequest.isCompleted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.withOpacity(0.08)
            : const Color(0xFF6C63FF).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withOpacity(0.18)
              : const Color(0xFF6C63FF).withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            editRequest.statusLabel,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCompleted ? Colors.green : const Color(0xFF6C63FF),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            '${editRequest.selectedFiles.length}/$maxPhotoCount file dikirim',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 10),

          ...editRequest.selectedFiles.map((file) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.image_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(file)),
                ],
              ),
            );
          }),

          if (editRequest.requestNotes.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Catatan:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(editRequest.requestNotes),
          ],

          if (isAssigned) ...[
            const SizedBox(height: 12),
            const Text(
              'List foto sudah dikirim ke editor. Mohon ditunggu kurang lebih selama 7 hari. Foto akan diedit sesuai urutan editan yang masuk.',
              style: TextStyle(height: 1.5),
            ),
            if (editRequest.editorName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Editor: ${editRequest.editorName}'),
            ],
            if (editRequest.editDeadlineAt.isNotEmpty)
              Text(
                'Deadline: ${IndonesianDateFormatter.dateTime(editRequest.editDeadlineAt)}',
              ),
          ],

          if (editRequest.isCompleted) ...[
            const SizedBox(height: 12),
            const Text(
              'Hasil edit sudah selesai. Silakan lanjut ke tahap cetak atau review.',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],

          if (canEditAgain) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Ubah Daftar Foto'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final Color color;
  final String title;
  final String message;

  const _InfoBox({
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 6),
          Text(message, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }
}
