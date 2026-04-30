import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/indonesian_date_formatter.dart';
import '../../../data/models/edit_request_model.dart';
import '../../../data/providers/edit_request_provider.dart';
import 'edit_request_form_screen.dart';

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

        const _EditRequestSectionHeader(),

        const SizedBox(height: 12),

        if (provider.isLoading)
          const _LoadingEditRequestCard()
        else if (!widget.hasPhotoLink)
          const _InfoBox(
            color: _EditRequestPalette.warning,
            icon: Icons.link_off_rounded,
            title: 'Link foto belum tersedia',
            message:
                'Form daftar foto edit akan muncul setelah fotografer mengupload link hasil foto.',
          )
        else if (!widget.canOpenPhotoLink)
          const _InfoBox(
            color: _EditRequestPalette.warning,
            icon: Icons.lock_outline_rounded,
            title: 'Pelunasan belum selesai',
            message:
                'Kamu bisa mengirim daftar foto edit setelah pelunasan booking selesai.',
          )
        else if (widget.maxPhotoCount <= 0)
          const _InfoBox(
            color: _EditRequestPalette.danger,
            icon: Icons.error_outline_rounded,
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
          _ErrorMessageBox(message: provider.errorMessage!),
        ],
      ],
    );
  }
}

class _EditRequestPalette {
  static const Color darkBlue = Color(0xFF233B93);
  static const Color midBlue = Color(0xFF344FA5);
  static const Color lightBlue = Color(0xFF5E7BDA);

  static const Color cardLight = Color(0xFFF0FAFF);
  static const Color cardMid = Color(0xFFD9F0FA);
  static const Color cardDeep = Color(0xFFC5E4F2);

  static const Color dark = Color(0xFF111827);
  static const Color grey = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);

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

class _EditRequestSectionHeader extends StatelessWidget {
  const _EditRequestSectionHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 38,
          width: 5,
          decoration: BoxDecoration(
            gradient: _EditRequestPalette.darkGradient,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Daftar Foto Edit',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _EditRequestPalette.dark,
                  fontSize: 19,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Pilih file foto yang ingin diedit sesuai kuota paket.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _EditRequestPalette.grey.withOpacity(0.92),
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: _EditRequestPalette.softGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.78)),
          ),
          child: const Icon(
            Icons.edit_note_rounded,
            color: _EditRequestPalette.darkBlue,
            size: 24,
          ),
        ),
      ],
    );
  }
}

class _LoadingEditRequestCard extends StatelessWidget {
  const _LoadingEditRequestCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _EditRequestPalette.cardDeep),
        boxShadow: [
          BoxShadow(
            color: _EditRequestPalette.darkBlue.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(color: _EditRequestPalette.darkBlue),
      ),
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: _EditRequestPalette.darkGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _EditRequestPalette.darkBlue.withOpacity(0.16),
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
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.11),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 34,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 17, 17, 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.20),
                        ),
                      ),
                      child: const Icon(
                        Icons.image_search_rounded,
                        color: Colors.white,
                        size: 29,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pilih Foto untuk Diedit',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Maksimal $maxPhotoCount file edit sesuai paket.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.74),
                              fontSize: 12.3,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Masukkan nama file foto yang ingin diedit, misalnya DSC03456.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.82),
                            height: 1.35,
                            fontSize: 11.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Input Daftar Foto Edit'),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.white,
                      foregroundColor: _EditRequestPalette.darkBlue,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
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

  Color get _statusColor {
    if (editRequest.isCompleted) return _EditRequestPalette.success;
    if (editRequest.isAssigned || editRequest.isInProgress) {
      return _EditRequestPalette.darkBlue;
    }

    return _EditRequestPalette.warning;
  }

  IconData get _statusIcon {
    if (editRequest.isCompleted) return Icons.check_circle_rounded;
    if (editRequest.isAssigned || editRequest.isInProgress) {
      return Icons.auto_fix_high_rounded;
    }

    return Icons.pending_actions_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isAssigned = editRequest.isAssigned || editRequest.isInProgress;
    final isCompleted = editRequest.isCompleted;
    final color = _statusColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _EditRequestPalette.cardDeep),
        boxShadow: [
          BoxShadow(
            color: _EditRequestPalette.darkBlue.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusSummaryHeader(
            icon: _statusIcon,
            color: color,
            title: editRequest.statusLabel,
            subtitle:
                '${editRequest.selectedFiles.length}/$maxPhotoCount file dikirim',
          ),

          const SizedBox(height: 14),

          _SelectedFilesPanel(
            files: editRequest.selectedFiles,
            maxPhotoCount: maxPhotoCount,
          ),

          if (editRequest.requestNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _NotesPanel(notes: editRequest.requestNotes),
          ],

          if (isAssigned) ...[
            const SizedBox(height: 12),
            _ProgressInfoPanel(editRequest: editRequest),
          ],

          if (isCompleted) ...[
            const SizedBox(height: 12),
            const _CompletedPanel(),
          ],

          if (canEditAgain) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Ubah Daftar Foto'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _EditRequestPalette.darkBlue,
                  side: const BorderSide(color: _EditRequestPalette.cardDeep),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusSummaryHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _StatusSummaryHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.trim().isEmpty ? 'Status edit' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: color.withOpacity(0.76),
                    fontSize: 11.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedFilesPanel extends StatelessWidget {
  final List<String> files;
  final int maxPhotoCount;

  const _SelectedFilesPanel({required this.files, required this.maxPhotoCount});

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const _MiniInfoBox(
        icon: Icons.image_not_supported_rounded,
        color: _EditRequestPalette.grey,
        text: 'Belum ada file foto yang dikirim.',
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: _EditRequestPalette.softGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.78)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.collections_rounded,
                color: _EditRequestPalette.darkBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'File Foto Pilihan',
                  style: TextStyle(
                    color: _EditRequestPalette.darkBlue.withOpacity(0.86),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _SmallCounterChip(value: '${files.length}/$maxPhotoCount'),
            ],
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: files.map((file) {
              return _FileChip(fileName: file);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SmallCounterChip extends StatelessWidget {
  final String value;

  const _SmallCounterChip({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 27,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: _EditRequestPalette.darkBlue.withOpacity(0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _EditRequestPalette.darkBlue.withOpacity(0.13),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        value,
        style: const TextStyle(
          color: _EditRequestPalette.darkBlue,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FileChip extends StatelessWidget {
  final String fileName;

  const _FileChip({required this.fileName});

  @override
  Widget build(BuildContext context) {
    final display = fileName.trim().isEmpty ? '-' : fileName.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.image_rounded,
            color: _EditRequestPalette.darkBlue,
            size: 14,
          ),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              display,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _EditRequestPalette.darkBlue,
                fontSize: 11.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesPanel extends StatelessWidget {
  final String notes;

  const _NotesPanel({required this.notes});

  @override
  Widget build(BuildContext context) {
    return _MiniInfoBox(
      icon: Icons.notes_rounded,
      color: _EditRequestPalette.darkBlue,
      text: notes,
    );
  }
}

class _ProgressInfoPanel extends StatelessWidget {
  final EditRequestModel editRequest;

  const _ProgressInfoPanel({required this.editRequest});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: _EditRequestPalette.darkBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _EditRequestPalette.darkBlue.withOpacity(0.13),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MiniTitleRow(
            icon: Icons.auto_fix_high_rounded,
            title: 'Sedang Diproses Editor',
            color: _EditRequestPalette.darkBlue,
          ),
          const SizedBox(height: 8),
          Text(
            'List foto sudah dikirim ke editor. Mohon ditunggu kurang lebih selama 7 hari. Foto akan diedit sesuai urutan editan yang masuk.',
            style: TextStyle(
              color: _EditRequestPalette.darkBlue.withOpacity(0.76),
              height: 1.45,
              fontSize: 11.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (editRequest.editorName.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InlineMeta(
              icon: Icons.person_rounded,
              label: 'Editor',
              value: editRequest.editorName,
              color: _EditRequestPalette.darkBlue,
            ),
          ],
          if (editRequest.editDeadlineAt.isNotEmpty) ...[
            const SizedBox(height: 7),
            _InlineMeta(
              icon: Icons.event_available_rounded,
              label: 'Deadline',
              value: IndonesianDateFormatter.dateTime(
                editRequest.editDeadlineAt,
              ),
              color: _EditRequestPalette.darkBlue,
            ),
          ],
        ],
      ),
    );
  }
}

class _CompletedPanel extends StatelessWidget {
  const _CompletedPanel();

  @override
  Widget build(BuildContext context) {
    return const _MiniInfoBox(
      icon: Icons.check_circle_rounded,
      color: _EditRequestPalette.success,
      text:
          'Hasil edit sudah selesai. Silakan lanjut ke tahap cetak atau review.',
    );
  }
}

class _MiniTitleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _MiniTitleRow({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineMeta extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InlineMeta({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final display = value.trim().isEmpty ? '-' : value.trim();

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 7),
        Text(
          '$label: ',
          style: TextStyle(
            color: color.withOpacity(0.66),
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        Expanded(
          child: Text(
            display,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniInfoBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _MiniInfoBox({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final display = text.trim().isEmpty ? '-' : text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.13)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              display,
              style: TextStyle(
                color: color,
                height: 1.35,
                fontSize: 11.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String message;

  const _InfoBox({
    required this.color,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
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
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: TextStyle(
                    color: color.withOpacity(0.78),
                    height: 1.4,
                    fontSize: 11.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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
    return _InfoBox(
      color: _EditRequestPalette.danger,
      icon: Icons.error_outline_rounded,
      title: 'Terjadi kesalahan',
      message: message,
    );
  }
}
