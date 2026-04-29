import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/package_model.dart';
import '../../../data/services/package_service.dart';
import '../booking/booking_screen.dart';

class PackageDetailScreen extends StatefulWidget {
  final int packageId;

  const PackageDetailScreen({super.key, required this.packageId});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  late Future<PackageModel> futurePackage;
  final PageController pageController = PageController();

  int currentImage = 0;

  @override
  void initState() {
    super.initState();
    futurePackage = PackageService().getPackageDetail(widget.packageId);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  String formatCurrency(double value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: FutureBuilder<PackageModel>(
        future: futurePackage,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Detail Paket')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Gagal memuat detail paket.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: Text('Data paket tidak ditemukan')),
            );
          }

          final item = snapshot.data!;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 330,
                pinned: true,
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.dark,
                title: const Text('Detail Paket'),
                flexibleSpace: FlexibleSpaceBar(
                  background: _PortfolioHero(
                    package: item,
                    pageController: pageController,
                    currentImage: currentImage,
                    onChanged: (index) {
                      setState(() => currentImage = index);
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PackageSummary(
                        item: item,
                        formatCurrency: formatCurrency,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Deskripsi Paket',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.description.isEmpty ? '-' : item.description,
                        style: const TextStyle(height: 1.6),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Informasi Paket',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoCard(item: item),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BookingScreen(selectedPackage: item),
                            ),
                          );
                        },
                        icon: const Icon(Icons.calendar_month_rounded),
                        label: const Text('Booking Paket Ini'),
                      ),
                      const SizedBox(height: 22),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PortfolioHero extends StatelessWidget {
  final PackageModel package;
  final PageController pageController;
  final int currentImage;
  final ValueChanged<int> onChanged;

  const _PortfolioHero({
    required this.package,
    required this.pageController,
    required this.currentImage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (package.portfolio.isEmpty) {
      return Container(
        color: AppColors.primaryLight,
        child: const Center(
          child: Icon(
            Icons.photo_camera_outlined,
            size: 72,
            color: Colors.white,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: pageController,
          itemCount: package.portfolio.length,
          onPageChanged: onChanged,
          itemBuilder: (context, index) {
            return Image.network(
              package.portfolio[index],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.primaryLight,
                child: const Icon(
                  Icons.broken_image_outlined,
                  size: 54,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.15),
                Colors.black.withOpacity(0.05),
                Colors.black.withOpacity(0.55),
              ],
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 22,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  package.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${currentImage + 1}/${package.portfolio.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PackageSummary extends StatelessWidget {
  final PackageModel item;
  final String Function(double) formatCurrency;

  const _PackageSummary({required this.item, required this.formatCurrency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.categoryName,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            '${item.locationTypeLabel} - ${item.durationMinutes} menit - ${item.photoCount} foto edit',
            style: const TextStyle(color: AppColors.grey),
          ),
          const SizedBox(height: 16),
          if (item.hasDiscount)
            Text(
              formatCurrency(item.price),
              style: const TextStyle(
                color: AppColors.grey,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          Text(
            formatCurrency(item.finalPrice),
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (item.hasDiscount) ...[
            const SizedBox(height: 8),
            Text(
              'Promo aktif: ${item.activeDiscount?.promoName ?? "-"} (${item.activeDiscount?.discountPercent ?? 0}%)',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final PackageModel item;

  const _InfoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _InfoTile(
            icon: Icons.category_outlined,
            title: 'Kategori',
            value: item.categoryName,
          ),
          _InfoTile(
            icon: Icons.location_on_outlined,
            title: 'Tipe Lokasi',
            value: item.locationTypeLabel,
          ),
          _InfoTile(
            icon: Icons.schedule_outlined,
            title: 'Durasi',
            value: '${item.durationMinutes} menit',
          ),
          _InfoTile(
            icon: Icons.photo_library_outlined,
            title: 'Jumlah Foto Edit',
            value: '${item.photoCount} foto',
          ),
          if (item.personCount != null)
            _InfoTile(
              icon: Icons.people_outline,
              title: 'Jumlah Orang',
              value: '${item.personCount} orang',
            ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryDark),
      title: Text(title),
      subtitle: Text(value),
    );
  }
}
