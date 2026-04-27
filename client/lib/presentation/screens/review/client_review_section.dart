import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/review_model.dart';
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
        selected ? Icons.star : Icons.star_border,
        color: selected ? Colors.amber : Colors.grey,
        size: 34,
      ),
    );
  }

  Widget _buildSubmittedReview(ReviewModel review) {
    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review Kamu',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              final value = index + 1;

              return Icon(
                value <= review.rating ? Icons.star : Icons.star_border,
                color: value <= review.rating ? Colors.amber : Colors.grey,
                size: 28,
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            review.comment.isEmpty ? 'Tidak ada komentar.' : review.comment,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Terima kasih. Review kamu sudah tercatat.',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingReviewBox() {
    return _Box(
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Review dapat diberikan setelah tahap cetak selesai atau setelah kamu memilih tidak cetak.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewForm(ReviewProvider provider) {
    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Beri Review',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bagikan penilaianmu terkait pelayanan dan hasil foto Monoframe.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),

          const Text('Rating', style: TextStyle(fontWeight: FontWeight.bold)),
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
                color: Color(0xFF6C63FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 18),

          TextField(
            controller: _commentController,
            enabled: !provider.isSubmitting,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Komentar',
              hintText: 'Tulis pengalaman kamu di sini...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),

          if (provider.errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              provider.errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ],

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: provider.isSubmitting ? null : _submitReview,
              icon: provider.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.rate_review_outlined),
              label: Text(
                provider.isSubmitting ? 'Mengirim...' : 'Kirim Review',
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

    if (!_initialized || provider.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final review = provider.review ?? widget.initialReview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),

        const Row(
          children: [
            Icon(Icons.reviews_outlined),
            SizedBox(width: 8),
            Text(
              'Review',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (review != null)
          _buildSubmittedReview(review)
        else if (provider.canReview || widget.canReview)
          _buildReviewForm(provider)
        else
          _buildWaitingReviewBox(),
      ],
    );
  }
}

class _Box extends StatelessWidget {
  final Widget child;

  const _Box({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }
}
