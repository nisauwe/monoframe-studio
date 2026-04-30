import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/package_model.dart';
import '../../../data/models/print_price_model.dart';
import '../../../data/providers/package_provider.dart';
import '../booking/booking_screen.dart';
import 'package_detail_screen.dart';

class PackageScreen extends StatefulWidget {
  final String? initialCategory;

  const PackageScreen({super.key, this.initialCategory});

  @override
  State<PackageScreen> createState() => _PackageScreenState();
}

class _PackageScreenState extends State<PackageScreen> {
  String selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    selectedCategory = _normalizeCategory(widget.initialCategory);
  }

  @override
  void didUpdateWidget(covariant PackageScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialCategory != widget.initialCategory) {
      setState(() {
        selectedCategory = _normalizeCategory(widget.initialCategory);
      });
    }
  }

  String _normalizeCategory(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? 'Semua' : text;
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

  List<String> _categories(List<PackageModel> packages) {
    final categories =
        packages.map((item) => item.categoryName).toSet().toList()..sort();

    return ['Semua', ...categories];
  }

  List<PackageModel> _filtered(List<PackageModel> packages) {
    if (selectedCategory == 'Semua') {
      return packages;
    }

    return packages
        .where((item) => item.categoryName == selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PackageProvider>();
    final categories = _categories(provider.packages);
    final packages = _filtered(provider.packages);

    if (!categories.contains(selectedCategory)) {
      selectedCategory = 'Semua';
    }

    return SafeArea(
      child: Container(
        color: AppColors.background,
        child: RefreshIndicator(
          color: _PackageListPalette.darkBlue,
          backgroundColor: _PackageListPalette.cardLight,
          onRefresh: provider.refreshAll,
          child:
              provider.isLoading &&
                  provider.packages.isEmpty &&
                  provider.printPrices.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    color: _PackageListPalette.darkBlue,
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 118),
                  children: [
                    const Text(
                      'Paket Layanan',
                      style: TextStyle(
                        color: _PackageListPalette.darkBlue,
                        fontSize: 24,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pilih paket foto sesuai kebutuhanmu.',
                      style: TextStyle(
                        color: _PackageListPalette.darkBlue.withValues(
                          alpha: 0.62,
                        ),
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _CategoryTabs(
                      categories: categories,
                      selectedCategory: selectedCategory,
                      packages: provider.packages,
                      onSelected: (category) {
                        setState(() => selectedCategory = category);
                      },
                    ),
                    const SizedBox(height: 18),
                    if (packages.isEmpty)
                      const _EmptyPackageList()
                    else
                      ...packages.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PhotoPackageCard(
                            package: item,
                            formatCompactCurrency: formatCompactCurrency,
                            onDetail: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PackageDetailScreen(packageId: item.id),
                                ),
                              );
                            },
                            onBooking: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BookingScreen(selectedPackage: item),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    const Text(
                      'Paket Cetak & Bingkai',
                      style: TextStyle(
                        color: _PackageListPalette.darkBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Harga tambahan untuk kebutuhan cetak foto.',
                      style: TextStyle(
                        color: _PackageListPalette.darkBlue.withValues(
                          alpha: 0.58,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (provider.printPrices.isEmpty)
                      const _EmptyPrintList()
                    else
                      ...provider.printPrices.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PrintPriceCard(
                            item: item,
                            formatCurrency: formatCurrency,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PackageListPalette {
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

class _CategoryTabs extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final List<PackageModel> packages;
  final ValueChanged<String> onSelected;

  const _CategoryTabs({
    required this.categories,
    required this.selectedCategory,
    required this.packages,
    required this.onSelected,
  });

  int _countForCategory(String category) {
    if (category == 'Semua') {
      return packages.length;
    }

    return packages.where((item) => item.categoryName == category).length;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category == selectedCategory;
          final count = _countForCategory(category);

          return InkWell(
            onTap: () => onSelected(category),
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                gradient: selected ? _PackageListPalette.darkGradient : null,
                color: selected ? null : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? _PackageListPalette.lightBlue.withValues(alpha: 0.60)
                      : _PackageListPalette.cardDeep,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _PackageListPalette.darkBlue.withValues(
                            alpha: 0.14,
                          ),
                          blurRadius: 14,
                          offset: const Offset(0, 7),
                        ),
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Text(
                '$category ($count)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : _PackageListPalette.darkBlue,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PhotoPackageCard extends StatelessWidget {
  final PackageModel package;
  final String Function(double) formatCompactCurrency;
  final VoidCallback onDetail;
  final VoidCallback onBooking;

  const _PhotoPackageCard({
    required this.package,
    required this.formatCompactCurrency,
    required this.onDetail,
    required this.onBooking,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onDetail,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 152,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _PackageListPalette.cardDeep),
          boxShadow: [
            BoxShadow(
              color: _PackageListPalette.darkBlue.withValues(alpha: 0.055),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            _PackageImageSide(
              package: package,
              priceText: formatCompactCurrency(package.finalPrice),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: _PackageCardContent(
                  package: package,
                  onDetail: onDetail,
                  onBooking: onBooking,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageCardContent extends StatelessWidget {
  final PackageModel package;
  final VoidCallback onDetail;
  final VoidCallback onBooking;

  const _PackageCardContent({
    required this.package,
    required this.onDetail,
    required this.onBooking,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          package.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _PackageListPalette.darkBlue,
            fontSize: 18,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          package.categoryName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _PackageListPalette.darkBlue.withValues(alpha: 0.58),
            fontSize: 12,
            height: 1.05,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        _PackageMiniInfo(package: package),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 30,
                child: OutlinedButton(
                  onPressed: onDetail,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: _PackageListPalette.darkBlue,
                    side: BorderSide(
                      color: _PackageListPalette.darkBlue.withValues(
                        alpha: 0.22,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 10.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: const Text('Lihat Paket'),
                ),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: SizedBox(
                height: 30,
                child: ElevatedButton(
                  onPressed: onBooking,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    backgroundColor: _PackageListPalette.darkBlue,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 10.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: const Text('Booking'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PackageMiniInfo extends StatelessWidget {
  final PackageModel package;

  const _PackageMiniInfo({required this.package});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.fromLTRB(9, 7, 9, 7),
      decoration: BoxDecoration(
        gradient: _PackageListPalette.softGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.76)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _MiniInfoRow(
            icon: Icons.schedule_rounded,
            text: '${package.durationMinutes} menit',
          ),
          const SizedBox(height: 5),
          _MiniInfoRow(
            icon: Icons.location_on_rounded,
            text: package.locationTypeLabel,
          ),
        ],
      ),
    );
  }
}

class _MiniInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _PackageListPalette.darkBlue, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _PackageListPalette.darkBlue,
              fontSize: 11,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _PackageImageSide extends StatelessWidget {
  final PackageModel package;
  final String priceText;

  const _PackageImageSide({required this.package, required this.priceText});

  @override
  Widget build(BuildContext context) {
    final imageUrl = package.coverImage.isNotEmpty
        ? package.coverImage
        : package.portfolio.isNotEmpty
        ? package.portfolio.first
        : '';

    return SizedBox(
      width: 122,
      height: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Container(
          decoration: BoxDecoration(
            gradient: _PackageListPalette.softGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _PackageListPalette.darkBlue.withValues(alpha: 0.18),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: _PackageListPalette.darkBlue.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.all(4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return const _PackageImageFallback();
                          },
                        )
                      : const _PackageImageFallback(),
                ),
              ),

              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.06),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.95),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _PackageListPalette.darkBlue.withValues(
                          alpha: 0.10,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    priceText,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _PackageListPalette.darkBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

              if (package.hasDiscount)
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.warning.withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      '${package.activeDiscount?.discountPercent ?? 0}% OFF',
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackageImageFallback extends StatelessWidget {
  const _PackageImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: _PackageListPalette.softGradient,
      ),
      child: Center(
        child: Icon(
          Icons.photo_camera_outlined,
          color: _PackageListPalette.darkBlue.withValues(alpha: 0.42),
          size: 30,
        ),
      ),
    );
  }
}

class _PrintPriceCard extends StatelessWidget {
  final PrintPriceModel item;
  final String Function(double) formatCurrency;

  const _PrintPriceCard({required this.item, required this.formatCurrency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _PackageListPalette.cardDeep),
        boxShadow: [
          BoxShadow(
            color: _PackageListPalette.darkBlue.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: _PackageListPalette.softGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.print_outlined,
              color: _PackageListPalette.darkBlue,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.sizeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _PackageListPalette.darkBlue,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cetak: ${formatCurrency(item.basePrice)} • Bingkai: ${formatCurrency(item.framePrice)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _PackageListPalette.darkBlue.withValues(alpha: 0.58),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(item.totalWithFrame),
                  style: const TextStyle(
                    color: _PackageListPalette.darkBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
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

class _EmptyPackageList extends StatelessWidget {
  const _EmptyPackageList();

  @override
  Widget build(BuildContext context) {
    return const _EmptyState(
      icon: Icons.inventory_2_outlined,
      title: 'Paket tidak tersedia',
      subtitle: 'Belum ada paket aktif di kategori ini.',
    );
  }
}

class _EmptyPrintList extends StatelessWidget {
  const _EmptyPrintList();

  @override
  Widget build(BuildContext context) {
    return const _EmptyState(
      icon: Icons.print_outlined,
      title: 'Paket cetak belum tersedia',
      subtitle: 'Harga cetak akan muncul setelah admin mengaktifkannya.',
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: _PackageListPalette.softGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.76)),
      ),
      child: Column(
        children: [
          Icon(icon, color: _PackageListPalette.darkBlue, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: _PackageListPalette.darkBlue,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _PackageListPalette.darkBlue.withValues(alpha: 0.62),
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
