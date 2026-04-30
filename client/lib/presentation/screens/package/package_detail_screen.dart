import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/package_model.dart';
import '../../../data/models/public_review_model.dart';
import '../../../data/services/app_setting_service.dart';
import '../../../data/services/package_service.dart';
import '../booking/booking_screen.dart';

class PackageDetailScreen extends StatefulWidget {
  final int packageId;

  const PackageDetailScreen({super.key, required this.packageId});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  final PageController _pageController = PageController();

  late Future<PackageModel> _packageFuture;
  late Future<List<PublicReviewModel>> _reviewsFuture;

  int _currentImage = 0;

  @override
  void initState() {
    super.initState();

    _packageFuture = PackageService().getPackageDetail(widget.packageId);
    _reviewsFuture = AppSettingService().getPublicReviews();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String formatCurrency(double value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  String formatCompactCurrency(double value) {
    return NumberFormat.compactCurrency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  _PackageRating _ratingForPackage(
    PackageModel item,
    List<PublicReviewModel> reviews,
  ) {
    final packageName = _normalizeName(item.name);

    final matchedReviews = reviews.where((review) {
      final reviewPackageName = _normalizeName(review.packageName);

      if (packageName.isEmpty || reviewPackageName.isEmpty) {
        return false;
      }

      return reviewPackageName == packageName ||
          reviewPackageName.contains(packageName) ||
          packageName.contains(reviewPackageName);
    }).toList();

    if (matchedReviews.isEmpty) {
      return const _PackageRating(average: 0, count: 0);
    }

    final total = matchedReviews.fold<int>(
      0,
      (sum, review) => sum + review.rating,
    );

    return _PackageRating(
      average: total / matchedReviews.length,
      count: matchedReviews.length,
    );
  }

  String _normalizeName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  void _openBooking(PackageModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookingScreen(selectedPackage: item)),
    );
  }

  void _openGalleryPreview(List<String> images, int initialIndex) {
    if (images.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.92),
      builder: (_) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          child: _FullImageViewer(images: images, initialIndex: initialIndex),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageModel>(
      future: _packageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: _DetailPalette.darkBlue),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const _DetailTopBar(title: 'Detail Paket'),
                    const Spacer(),
                    _ErrorCard(message: 'Gagal memuat detail paket.'),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _DetailPalette.darkBlue.withOpacity(0.62),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  children: [
                    _DetailTopBar(title: 'Detail Paket'),
                    Spacer(),
                    _ErrorCard(message: 'Data paket tidak ditemukan.'),
                    Spacer(),
                  ],
                ),
              ),
            ),
          );
        }

        final item = snapshot.data!;

        return Scaffold(
          backgroundColor: AppColors.background,
          bottomNavigationBar: _BottomBookingBar(
            item: item,
            formatCurrency: formatCurrency,
            onBooking: () => _openBooking(item),
          ),
          body: SafeArea(
            bottom: false,
            child: FutureBuilder<List<PublicReviewModel>>(
              future: _reviewsFuture,
              builder: (context, reviewSnapshot) {
                final reviews = reviewSnapshot.data ?? [];
                final rating = _ratingForPackage(item, reviews);

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 18, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _DetailTopBar(title: 'Detail Paket'),
                            const SizedBox(height: 10),

                            _HeroPackageImage(
                              item: item,
                              pageController: _pageController,
                              currentImage: _currentImage,
                              compactPrice: formatCompactCurrency(
                                item.finalPrice,
                              ),
                              onChanged: (index) {
                                setState(() => _currentImage = index);
                              },
                            ),

                            Transform.translate(
                              offset: const Offset(0, -12),
                              child: _FloatingSummaryCard(
                                item: item,
                                rating: rating,
                              ),
                            ),

                            const SizedBox(height: 0),

                            _SectionHeader(title: 'Detail Paket'),

                            const SizedBox(height: 12),

                            _PackageFeatureGrid(item: item),

                            const SizedBox(height: 20),

                            const _SectionHeader(title: 'Deskripsi'),

                            const SizedBox(height: 12),

                            _DescriptionCard(description: item.description),

                            const SizedBox(height: 20),

                            _SectionHeader(
                              title: 'Galeri',
                              actionText: item.portfolio.isEmpty
                                  ? null
                                  : 'Klik untuk lihat',
                            ),

                            const SizedBox(height: 12),

                            _GallerySamples(
                              images: item.portfolio,
                              currentImage: _currentImage,
                              onTap: (index) {
                                _openGalleryPreview(item.portfolio, index);
                              },
                            ),

                            const SizedBox(height: 98),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _DetailPalette {
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

class _PackageRating {
  final double average;
  final int count;

  const _PackageRating({required this.average, required this.count});

  String get averageText {
    if (count == 0) {
      return '0.0';
    }

    return average.toStringAsFixed(1);
  }

  String get countText {
    if (count == 0) {
      return 'Belum ada review';
    }

    return '$count review';
  }
}

class _DetailTopBar extends StatelessWidget {
  final String title;

  const _DetailTopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              color: _DetailPalette.darkBlue,
              iconSize: 24,
              splashRadius: 22,
            ),
          ),
          Center(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: _DetailPalette.darkBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPackageImage extends StatelessWidget {
  final PackageModel item;
  final PageController pageController;
  final int currentImage;
  final String compactPrice;
  final ValueChanged<int> onChanged;

  const _HeroPackageImage({
    required this.item,
    required this.pageController,
    required this.currentImage,
    required this.compactPrice,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final images = item.portfolio;

    return Container(
      height: 390,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        color: _DetailPalette.cardMid,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (images.isEmpty)
            const _GalleryImageFallback()
          else
            PageView.builder(
              controller: pageController,
              itemCount: images.length,
              onPageChanged: onChanged,
              itemBuilder: (context, index) {
                return Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }

                    return const _GalleryImageFallback(showLoading: true);
                  },
                  errorBuilder: (_, __, ___) {
                    return const _GalleryImageFallback();
                  },
                );
              },
            ),

          // Shadow putih dibuat tipis dan hanya di area bawah gambar.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.18),
                  AppColors.background.withValues(alpha: 0.82),
                ],
                stops: const [0.0, 0.70, 0.88, 1.0],
              ),
            ),
          ),

          if (item.hasDiscount)
            Positioned(left: 16, bottom: 76, child: _DiscountBadge(item: item)),

          Positioned(
            right: 16,
            bottom: 70,
            child: _PriceBubble(compactPrice: compactPrice),
          ),

          if (images.isNotEmpty)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.photo_library_outlined,
                      color: _DetailPalette.darkBlue,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${currentImage + 1}/${images.length}',
                      style: const TextStyle(
                        color: _DetailPalette.darkBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
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

class _DiscountBadge extends StatelessWidget {
  final PackageModel item;

  const _DiscountBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    final discount = item.activeDiscount?.discountPercent ?? 0;

    return Container(
      constraints: const BoxConstraints(maxWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB452), Color(0xFFFF8A3D)],
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$discount% OFF',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PriceBubble extends StatelessWidget {
  final String compactPrice;

  const _PriceBubble({required this.compactPrice});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        compactPrice,
        style: const TextStyle(
          color: _DetailPalette.darkBlue,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FloatingSummaryCard extends StatelessWidget {
  final PackageModel item;
  final _PackageRating rating;

  const _FloatingSummaryCard({required this.item, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _DetailPalette.cardDeep.withValues(alpha: 0.62),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _CategoryAndName(item: item)),
          const SizedBox(width: 10),
          _RatingText(rating: rating),
        ],
      ),
    );
  }
}

class _CategoryAndName extends StatelessWidget {
  final PackageModel item;

  const _CategoryAndName({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.categoryName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _DetailPalette.darkBlue.withValues(alpha: 0.54),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          item.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _DetailPalette.darkBlue,
            fontSize: 22,
            height: 1.08,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _RatingText extends StatelessWidget {
  final _PackageRating rating;

  const _RatingText({required this.rating});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.warning, size: 21),
          const SizedBox(height: 3),
          Text(
            rating.averageText,
            style: const TextStyle(
              color: _DetailPalette.darkBlue,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            rating.countText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: _DetailPalette.darkBlue.withValues(alpha: 0.52),
              fontSize: 9.5,
              height: 1.12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;

  const _SectionHeader({required this.title, this.actionText});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _DetailPalette.darkBlue,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        if (actionText != null)
          Text(
            actionText!,
            style: TextStyle(
              color: _DetailPalette.darkBlue.withOpacity(0.64),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
      ],
    );
  }
}

class _PackageFeatureGrid extends StatelessWidget {
  final PackageModel item;

  const _PackageFeatureGrid({required this.item});

  @override
  Widget build(BuildContext context) {
    final features = <_FeatureData>[
      _FeatureData(
        icon: Icons.schedule_outlined,
        title: '${item.durationMinutes} Menit',
        value: 'Durasi',
      ),
      _FeatureData(
        icon: Icons.photo_library_outlined,
        title: '${item.photoCount} Foto',
        value: 'Foto Edit',
      ),
      _FeatureData(
        icon: Icons.location_on_outlined,
        title: item.locationTypeLabel,
        value: 'Tipe Lokasi',
      ),
      _FeatureData(
        icon: Icons.category_outlined,
        title: item.categoryName,
        value: 'Kategori',
      ),
      if (item.personCount != null)
        _FeatureData(
          icon: Icons.people_outline,
          title: '${item.personCount} Orang',
          value: 'Kapasitas',
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: features.map((feature) {
            return SizedBox(
              width: features.length == 5 && feature == features.last
                  ? constraints.maxWidth
                  : itemWidth,
              child: _FeatureCard(feature: feature),
            );
          }).toList(),
        );
      },
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String value;

  const _FeatureData({
    required this.icon,
    required this.title,
    required this.value,
  });
}

class _FeatureCard extends StatelessWidget {
  final _FeatureData feature;

  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _DetailPalette.cardDeep.withOpacity(0.68)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: _DetailPalette.softGradient,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(feature.icon, color: _DetailPalette.darkBlue, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _DetailPalette.darkBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  feature.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _DetailPalette.darkBlue.withOpacity(0.54),
                    fontSize: 10.5,
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

class _DescriptionCard extends StatelessWidget {
  final String description;

  const _DescriptionCard({required this.description});

  @override
  Widget build(BuildContext context) {
    final value = description.trim().isEmpty ? '-' : description.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _DetailPalette.cardDeep.withOpacity(0.68)),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: _DetailPalette.darkBlue.withOpacity(0.68),
          fontSize: 13,
          height: 1.58,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GallerySamples extends StatelessWidget {
  final List<String> images;
  final int currentImage;
  final ValueChanged<int> onTap;

  const _GallerySamples({
    required this.images,
    required this.currentImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        height: 124,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: _DetailPalette.softGradient,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.72)),
        ),
        child: const Center(
          child: Text(
            'Portfolio belum tersedia',
            style: TextStyle(
              color: _DetailPalette.darkBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final selected = index == currentImage;

          return GestureDetector(
            onTap: () => onTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: selected ? 100 : 92,
              padding: EdgeInsets.all(selected ? 3 : 0),
              decoration: BoxDecoration(
                gradient: selected ? _DetailPalette.darkGradient : null,
                borderRadius: BorderRadius.circular(22),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(selected ? 19 : 22),
                child: Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return const _GalleryImageFallback(iconSize: 28);
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FullImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullImageViewer({required this.images, required this.initialIndex});

  @override
  State<_FullImageViewer> createState() => _FullImageViewerState();
}

class _FullImageViewerState extends State<_FullImageViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();

    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.95),
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (value) {
                setState(() => _index = value);
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white,
                          size: 54,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 14,
              left: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.42),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_index + 1}/${widget.images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 14,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.42),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryImageFallback extends StatelessWidget {
  final bool showLoading;
  final double iconSize;

  const _GalleryImageFallback({this.showLoading = false, this.iconSize = 58});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: _DetailPalette.softGradient),
      child: Center(
        child: showLoading
            ? const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  color: _DetailPalette.darkBlue,
                  strokeWidth: 2.4,
                ),
              )
            : Icon(
                Icons.photo_camera_outlined,
                color: _DetailPalette.darkBlue.withOpacity(0.42),
                size: iconSize,
              ),
      ),
    );
  }
}

class _BottomBookingBar extends StatelessWidget {
  final PackageModel item;
  final String Function(double) formatCurrency;
  final VoidCallback onBooking;

  const _BottomBookingBar({
    required this.item,
    required this.formatCurrency,
    required this.onBooking,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: _DetailPalette.cardDeep.withOpacity(0.70)),
          ),
          boxShadow: [
            BoxShadow(
              color: _DetailPalette.darkBlue.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Harga',
                    style: TextStyle(
                      color: AppColors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (item.hasDiscount)
                    Text(
                      formatCurrency(item.price),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _DetailPalette.darkBlue.withOpacity(0.42),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    formatCurrency(item.finalPrice),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _DetailPalette.darkBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onBooking,
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: const Text('Booking'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _DetailPalette.darkBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: _DetailPalette.softGradient,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.72)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: _DetailPalette.darkBlue,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _DetailPalette.darkBlue,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
