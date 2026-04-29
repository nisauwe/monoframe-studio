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

  List<String> _categories(List<PackageModel> packages) {
    final categories =
        packages.map((item) => item.categoryName).toSet().toList()..sort();
    return ['Semua', ...categories];
  }

  List<PackageModel> _filtered(List<PackageModel> packages) {
    if (selectedCategory == 'Semua') return packages;

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
      child: RefreshIndicator(
        onRefresh: provider.refreshAll,
        child:
            provider.isLoading &&
                provider.packages.isEmpty &&
                provider.printPrices.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 118),
                children: [
                  const Text(
                    'Paket Layanan',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pilih kategori paket foto sesuai kebutuhanmu.',
                    style: TextStyle(color: AppColors.grey, height: 1.5),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 46,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final selected = category == selectedCategory;
                        final count = category == 'Semua'
                            ? provider.packages.length
                            : provider.packages
                                  .where(
                                    (item) => item.categoryName == category,
                                  )
                                  .length;

                        return ChoiceChip(
                          selected: selected,
                          showCheckmark: false,
                          label: Text('$category ($count)'),
                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                          ),
                          selectedColor: AppColors.primaryDark,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: selected
                                ? AppColors.primaryDark
                                : AppColors.border,
                          ),
                          onSelected: (_) {
                            setState(() => selectedCategory = category);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (packages.isEmpty)
                    const _EmptyPackageList()
                  else
                    ...packages.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _PhotoPackageCard(
                          package: item,
                          formatCurrency: formatCurrency,
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
                  const SizedBox(height: 18),
                  const Text(
                    'Paket Cetak & Bingkai',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Harga tambahan untuk kebutuhan cetak foto.',
                    style: TextStyle(color: AppColors.grey),
                  ),
                  const SizedBox(height: 12),
                  if (provider.printPrices.isEmpty)
                    const _EmptyPrintList()
                  else
                    ...provider.printPrices.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _PrintPriceCard(
                          item: item,
                          formatCurrency: formatCurrency,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _PhotoPackageCard extends StatelessWidget {
  final PackageModel package;
  final String Function(double) formatCurrency;
  final VoidCallback onDetail;
  final VoidCallback onBooking;

  const _PhotoPackageCard({
    required this.package,
    required this.formatCurrency,
    required this.onDetail,
    required this.onBooking,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onDetail,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PortfolioPreview(package: package),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          package.categoryName,
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (package.hasDiscount)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${package.activeDiscount?.discountPercent ?? 0}% OFF',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    package.name,
                    style: const TextStyle(
                      color: AppColors.dark,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${package.locationTypeLabel} • ${package.durationMinutes} menit • ${package.photoCount} foto edit',
                    style: const TextStyle(color: AppColors.grey),
                  ),
                  if (package.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      package.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(height: 1.5),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (package.hasDiscount)
                              Text(
                                formatCurrency(package.price),
                                style: const TextStyle(
                                  color: AppColors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            Text(
                              formatCurrency(package.finalPrice),
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onDetail,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primarySoft,
                          foregroundColor: AppColors.primaryDark,
                        ),
                        icon: const Icon(Icons.visibility_outlined),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: onBooking,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.calendar_month_rounded),
                      ),
                    ],
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

class _PortfolioPreview extends StatelessWidget {
  final PackageModel package;

  const _PortfolioPreview({required this.package});

  @override
  Widget build(BuildContext context) {
    if (package.portfolio.isEmpty) {
      return Container(
        height: 190,
        decoration: const BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: const Center(
          child: Icon(
            Icons.photo_camera_outlined,
            color: AppColors.primaryDark,
            size: 46,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: SizedBox(
        height: 205,
        child: PageView.builder(
          itemCount: package.portfolio.length,
          itemBuilder: (context, index) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  package.portfolio[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.primarySoft,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${index + 1}/${package.portfolio.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.print_outlined,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.sizeLabel,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Cetak: ${formatCurrency(item.basePrice)} • Bingkai: ${formatCurrency(item.framePrice)}',
                    style: const TextStyle(color: AppColors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    formatCurrency(item.totalWithFrame),
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w900,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 42),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }
}
