import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/review_model.dart';
import '../../../data/providers/app_setting_provider.dart';
import '../../../data/providers/review_provider.dart';

class ClientReviewSection extends StatefulWidget {
  final int bookingId;
  final bool canReview;
  final ReviewModel? initialReview;
  final VoidCallback? onReviewSubmitted;

  const ClientReviewSection({
    super.key,
    required this.bookingId,
    required this.canReview,
    this.initialReview,
    this.onReviewSubmitted,
  });

  @override
  State<ClientReviewSection> createState() => _ClientReviewSectionState();
}

class _ClientReviewSectionState extends State<ClientReviewSection> {
  final TextEditingController _commentController = TextEditingController();

  int _rating = 5;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppSettingProvider>().fetchSettings();

      final provider = context.read<ReviewProvider>();

      provider.setFromTracking(
        canReview: widget.canReview,
        review: widget.initialReview,
      );

      if (widget.initialReview != null) {
        _rating = widget.initialReview!.rating;
        _commentController.text = widget.initialReview!.comment;
      }

      if (widget.initialReview == null) {
        provider.fetchReview(bookingId: widget.bookingId);
      }

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant ClientReviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.bookingId != widget.bookingId ||
        oldWidget.canReview != widget.canReview ||
        oldWidget.initialReview?.id != widget.initialReview?.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final provider = context.read<ReviewProvider>();

        provider.setFromTracking(
          canReview: widget.canReview,
          review: widget.initialReview,
        );

        if (widget.initialReview != null) {
          _rating = widget.initialReview!.rating;
          _commentController.text = widget.initialReview!.comment;
        }

        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final reviewSetting = context.read<AppSettingProvider>().setting.review;

    if (!reviewSetting.isActive) {
      _showMessage('Review sedang dinonaktifkan oleh admin.');
      return;
    }

    final comment = _commentController.text.trim();

    if (_rating < 1 || _rating > 5) {
      _showMessage('Pilih rating 1 sampai 5 bintang.');
      return;
    }

    final provider = context.read<ReviewProvider>();

    final ok = await provider.submitReview(
      bookingId: widget.bookingId,
      rating: _rating,
      comment: comment,
    );

    if (!mounted) return;

    if (ok) {
      _showMessage('Review berhasil dikirim. Terima kasih!');
      widget.onReviewSubmitted?.call();
    } else {
      _showMessage(provider.errorMessage ?? 'Gagal mengirim review.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _starButton({required int value, required bool enabled}) {
    final selected = value <= _rating;

    return IconButton(
      onPressed: enabled
          ? () {
              setState(() {
                _rating = value;
              });
            }
          : null,
      icon: Icon(
        selected ? Icons.star_rounded : Icons.star_border_rounded,
        color: selected ? AppColors.warning : AppColors.grey,
        size: 32,
      ),
    );
  }

  Widget _buildSubmittedReview(ReviewModel review) {
    return _ReviewBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ReviewHeader(
            icon: Icons.verified_rounded,
            title: 'Review Kamu',
            subtitle: 'Terima kasih, review kamu sudah tercatat.',
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(5, (index) {
              final value = index + 1;

              return Icon(
                value <= review.rating
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: value <= review.rating
                    ? AppColors.warning
                    : AppColors.grey,
                size: 24,
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            review.comment.isEmpty ? 'Tidak ada komentar.' : review.comment,
            style: TextStyle(
              color: _ReviewPalette.darkBlue.withValues(alpha: 0.72),
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.14),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Review kamu berhasil dikirim.',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
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

  Widget _buildWaitingReviewBox(String invitationMessage) {
    return _ReviewBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ReviewHeader(
            icon: Icons.hourglass_top_rounded,
            title: 'Review Belum Tersedia',
            subtitle:
                'Review dapat diberikan setelah tahap cetak selesai atau setelah kamu memilih tidak cetak.',
          ),
          const SizedBox(height: 12),
          Text(
            invitationMessage,
            style: TextStyle(
              color: _ReviewPalette.darkBlue.withValues(alpha: 0.64),
              height: 1.45,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewDisabledBox(String message) {
    return _ReviewBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ReviewHeader(
            icon: Icons.block_rounded,
            title: 'Review Dinonaktifkan',
            subtitle: 'Admin sedang menonaktifkan fitur review dari klien.',
          ),
          const SizedBox(height: 12),
          Text(
            message.isNotEmpty
                ? message
                : 'Kamu belum bisa mengirim review untuk saat ini.',
            style: TextStyle(
              color: _ReviewPalette.darkBlue.withValues(alpha: 0.64),
              height: 1.45,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewForm({
    required ReviewProvider provider,
    required String invitationMessage,
  }) {
    return _ReviewBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReviewHeader(
            icon: Icons.rate_review_outlined,
            title: 'Beri Review',
            subtitle: invitationMessage.isNotEmpty
                ? invitationMessage
                : 'Bagikan pengalamanmu bersama Monoframe Studio.',
          ),

          const SizedBox(height: 16),

          const Text(
            'Rating',
            style: TextStyle(
              color: _ReviewPalette.darkBlue,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return _starButton(
                value: index + 1,
                enabled: !provider.isSubmitting,
              );
            }),
          ),

          Center(
            child: Text(
              '$_rating dari 5 bintang',
              style: const TextStyle(
                color: _ReviewPalette.darkBlue,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ),

          const SizedBox(height: 18),

          TextField(
            controller: _commentController,
            enabled: !provider.isSubmitting,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Komentar',
              hintText: 'Tulis pengalaman kamu di sini...',
              alignLabelWithHint: true,
              filled: true,
              fillColor: Colors.white,
              labelStyle: TextStyle(
                color: _ReviewPalette.darkBlue.withValues(alpha: 0.62),
                fontWeight: FontWeight.w700,
              ),
              hintStyle: const TextStyle(color: AppColors.grey),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _ReviewPalette.cardDeep),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: _ReviewPalette.darkBlue,
                  width: 1.4,
                ),
              ),
            ),
          ),

          if (provider.errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              provider.errorMessage!,
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: provider.isSubmitting ? null : _submitReview,
              icon: provider.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.rate_review_outlined, size: 18),
              label: Text(
                provider.isSubmitting ? 'Mengirim...' : 'Kirim Review',
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _ReviewPalette.darkBlue,
                foregroundColor: Colors.white,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReviewProvider>();
    final reviewSetting = context.watch<AppSettingProvider>().setting.review;

    if (!_initialized || provider.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(color: _ReviewPalette.darkBlue),
        ),
      );
    }

    final review = provider.review ?? widget.initialReview;
    final invitationMessage = reviewSetting.invitationMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),

        if (review != null)
          _buildSubmittedReview(review)
        else if (!reviewSetting.isActive)
          _buildReviewDisabledBox(invitationMessage)
        else if (provider.canReview || widget.canReview)
          _buildReviewForm(
            provider: provider,
            invitationMessage: invitationMessage,
          )
        else
          _buildWaitingReviewBox(invitationMessage),
      ],
    );
  }
}

class _ReviewPalette {
  static const Color darkBlue = Color(0xFF233B93);
  static const Color midBlue = Color(0xFF344FA5);
  static const Color lightBlue = Color(0xFF5E7BDA);

  static const Color cardLight = Color(0xFFF0FAFF);
  static const Color cardMid = Color(0xFFD9F0FA);
  static const Color cardDeep = Color(0xFFC5E4F2);

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardLight, cardMid, cardDeep],
  );
}

class _ReviewHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ReviewHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: _ReviewPalette.softGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: _ReviewPalette.darkBlue, size: 20),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ReviewPalette.darkBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: _ReviewPalette.darkBlue.withValues(alpha: 0.58),
                  fontSize: 12.2,
                  height: 1.38,
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

class _ReviewBox extends StatelessWidget {
  final Widget child;

  const _ReviewBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: _ReviewPalette.softGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
        boxShadow: [
          BoxShadow(
            color: _ReviewPalette.darkBlue.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
