import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/package_model.dart';
import '../../../data/models/print_price_model.dart';
import '../../../data/providers/package_provider.dart';
import '../booking/booking_screen.dart';
import 'package_detail_screen.dart';

class PackageScreen extends StatelessWidget {
  const PackageScreen({super.key});

  String formatCurrency(double value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PackageProvider>();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: provider.refreshAll,
        child:
            provider.isLoading &&
                provider.packages.isEmpty &&
                provider.printPrices.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Paket Layanan',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pilih paket foto atau paket cetak & bingkai sesuai kebutuhan kamu.',
                    style: TextStyle(color: AppColors.grey),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Paket Foto',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  ...provider.groupedPackages.entries.map((entry) {
                    final categoryName = entry.key;
                    final items = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 10),
                          child: Text(
                            categoryName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        ...items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
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
                      ],
                    );
                  }),

                  const SizedBox(height: 28),
                  const Text(
                    'Paket Cetak & Bingkai',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (package.hasDiscount)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${package.activeDiscount?.promoName ?? "Promo"} • ${package.activeDiscount?.discountPercent ?? 0}%',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            if (package.hasDiscount) const SizedBox(height: 12),

            Text(
              package.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Text(
              '${package.locationTypeLabel} • ${package.durationMinutes} menit • ${package.photoCount} foto edit',
              style: const TextStyle(color: AppColors.grey),
            ),
            const SizedBox(height: 8),

            Text(
              package.description.isEmpty ? '-' : package.description,
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 14),

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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDetail,
                    child: const Text('Lihat Detail'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onBooking,
                    child: const Text('Pilih Paket'),
                  ),
                ),
              ],
            ),
          ],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.sizeLabel,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Harga cetak: ${formatCurrency(item.basePrice)}'),
            const SizedBox(height: 4),
            Text('Harga bingkai: ${formatCurrency(item.framePrice)}'),
            const SizedBox(height: 4),
            Text(
              'Total cetak + bingkai: ${formatCurrency(item.totalWithFrame)}',
            ),
            if (item.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(item.notes, style: const TextStyle(color: AppColors.grey)),
            ],
          ],
        ),
      ),
    );
  }
}
