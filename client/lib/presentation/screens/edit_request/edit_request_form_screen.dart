import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();
  final List<TextEditingController> _fileControllers = [];

  int get _maxPhotoCount =>
      widget.maxPhotoCount <= 0 ? 1 : widget.maxPhotoCount;

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
    for (int i = 0; i < _maxPhotoCount; i++) {
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

    if (files.length > _maxPhotoCount) {
      _showMessage('Maksimal $_maxPhotoCount nama file foto.');
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

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperText,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.light,
      contentPadding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      labelStyle: TextStyle(
        color: AppColors.welcomeBlueDark.withOpacity(0.70),
        fontWeight: FontWeight.w800,
        fontSize: 12.2,
      ),
      hintStyle: const TextStyle(
        color: AppColors.grey,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      helperStyle: const TextStyle(
        color: AppColors.grey,
        fontWeight: FontWeight.w600,
        fontSize: 10.8,
      ),
      prefixIconColor: AppColors.welcomeBlueDark,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.primaryDark, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditRequestProvider>();
    final filledCount = _filledFiles().length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.secondary,
              AppColors.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            children: [
              _TopBar(
                title: 'Daftar Foto Edit',
                onBack: () => Navigator.pop(context),
              ),

              const SizedBox(height: 14),

              _RequestEditHero(
                maxPhotoCount: _maxPhotoCount,
                filledCount: filledCount,
              ),

              const SizedBox(height: 18),

              const _SectionTitle(
                title: 'Panduan Request Edit',
                subtitle: 'Isi nama file foto yang ingin diedit oleh editor.',
              ),

              const SizedBox(height: 12),

              const _InstructionCard(),

              const SizedBox(height: 18),

              _ProgressCard(
                filledCount: filledCount,
                maxPhotoCount: _maxPhotoCount,
              ),

              const SizedBox(height: 18),

              const _SectionTitle(
                title: 'Nama File Foto',
                subtitle: 'Masukkan nama file sesuai folder hasil foto.',
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.welcomeBlueDark.withOpacity(0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      ...List.generate(_fileControllers.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextFormField(
                            controller: _fileControllers[index],
                            textCapitalization: TextCapitalization.characters,
                            textInputAction:
                                index == _fileControllers.length - 1
                                ? TextInputAction.next
                                : TextInputAction.next,
                            onChanged: (_) => setState(() {}),
                            decoration: _inputDecoration(
                              label: 'Nama File ${index + 1}',
                              hint: 'Contoh: DSC03456',
                              icon: Icons.image_rounded,
                              helperText: index == 0
                                  ? 'Minimal isi 1 file. Maksimal $_maxPhotoCount file.'
                                  : null,
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 4),

                      TextFormField(
                        controller: _notesController,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        decoration: _inputDecoration(
                          label: 'Catatan Edit',
                          hint:
                              'Contoh: tone soft, kulit natural, background jangan diubah.',
                          icon: Icons.notes_rounded,
                        ),
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: provider.isSubmitting ? null : _submit,
                          icon: provider.isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, size: 19),
                          label: Text(
                            provider.isSubmitting
                                ? 'Mengirim...'
                                : 'Kirim Daftar Foto Edit',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColors.primaryDark,
                            foregroundColor: AppColors.white,
                            disabledBackgroundColor: AppColors.primaryDark
                                .withOpacity(0.45),
                            disabledForegroundColor: AppColors.white
                                .withOpacity(0.78),
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              const _NoticeCard(),
            ],
          ),
        ),
      ),
    );
  }
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
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.primaryDark,
                size: 22,
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
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _RequestEditHero extends StatelessWidget {
  final int maxPhotoCount;
  final int filledCount;

  const _RequestEditHero({
    required this.maxPhotoCount,
    required this.filledCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.welcomeDarkGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.20),
            blurRadius: 24,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -32,
            top: -34,
            child: Container(
              height: 112,
              width: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            right: 28,
            bottom: -42,
            child: Container(
              height: 104,
              width: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withOpacity(0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.white.withOpacity(0.22),
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        color: AppColors.white,
                        size: 29,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Request Edit Foto',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: AppColors.white.withOpacity(0.18),
                        ),
                      ),
                      child: Text(
                        '$filledCount/$maxPhotoCount file',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                const Text(
                  'Pilih foto yang ingin diedit',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.25,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  'Masukkan nama file dari folder hasil foto. Editor akan memproses file sesuai request kamu.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white.withOpacity(0.76),
                    fontSize: 12.3,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _HeroMetricBox(
                        icon: Icons.photo_library_rounded,
                        label: 'Maksimal',
                        value: '$maxPhotoCount',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroMetricBox(
                        icon: Icons.check_circle_rounded,
                        label: 'Terisi',
                        value: '$filledCount',
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

class _HeroMetricBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroMetricBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white.withOpacity(0.22), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.white, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.white.withOpacity(0.88),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 30,
          width: 5,
          decoration: BoxDecoration(
            gradient: AppColors.welcomeDarkGradient,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.dark,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 11.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard();

  @override
  Widget build(BuildContext context) {
    final steps = [
      _StepData(
        icon: Icons.folder_copy_rounded,
        title: 'Lihat folder hasil foto',
        subtitle: 'Buka link hasil foto dari fotografer.',
      ),
      _StepData(
        icon: Icons.image_search_rounded,
        title: 'Pilih nama file',
        subtitle: 'Contoh: DSC03456, DSC03457, IMG_1201.',
      ),
      _StepData(
        icon: Icons.send_rounded,
        title: 'Kirim request edit',
        subtitle: 'Editor akan memproses file yang kamu pilih.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.welcomeCardGradient,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.white.withOpacity(0.78)),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.045),
            blurRadius: 16,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: steps.map((step) {
          final isLast = step == steps.last;

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.70),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.white),
                  ),
                  child: Icon(
                    step.icon,
                    color: AppColors.welcomeBlueDark,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: const TextStyle(
                          color: AppColors.welcomeBlueDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        step.subtitle,
                        style: TextStyle(
                          color: AppColors.welcomeBlueDark.withOpacity(0.62),
                          fontWeight: FontWeight.w600,
                          fontSize: 11.3,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StepData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _StepData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _ProgressCard extends StatelessWidget {
  final int filledCount;
  final int maxPhotoCount;

  const _ProgressCard({required this.filledCount, required this.maxPhotoCount});

  @override
  Widget build(BuildContext context) {
    final progress = maxPhotoCount <= 0 ? 0.0 : filledCount / maxPhotoCount;
    final safeProgress = progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.045),
            blurRadius: 16,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withOpacity(0.09),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primaryDark.withOpacity(0.12),
              ),
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: AppColors.primaryDark,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Progress Pilihan Foto',
                  style: TextStyle(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$filledCount dari $maxPhotoCount nama file sudah diisi.',
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: safeProgress,
                    minHeight: 7,
                    backgroundColor: AppColors.primarySoft,
                    color: AppColors.primaryDark,
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

class _NoticeCard extends StatelessWidget {
  const _NoticeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryDark.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primaryDark,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pastikan nama file ditulis sama seperti di folder hasil foto agar editor tidak salah memilih file.',
              style: TextStyle(
                color: AppColors.primaryDark.withOpacity(0.88),
                fontWeight: FontWeight.w700,
                fontSize: 11.8,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
