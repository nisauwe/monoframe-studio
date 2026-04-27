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

  @override
  void initState() {
    super.initState();
    futurePackage = PackageService().getPackageDetail(widget.packageId);
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
      appBar: AppBar(title: const Text('Detail Paket')),
      body: FutureBuilder<PackageModel>(
        future: futurePackage,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Gagal memuat detail paket.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Data paket tidak ditemukan'));
          }

          final item = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
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
                      item.categoryName,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${item.locationTypeLabel} • ${item.durationMinutes} menit • ${item.photoCount} foto edit',
                      style: const TextStyle(color: AppColors.grey),
                    ),
                    const SizedBox(height: 14),
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
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item.hasDiscount) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Promo aktif: ${item.activeDiscount?.promoName ?? "-"} (${item.activeDiscount?.discountPercent ?? 0}%)',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Deskripsi Paket',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                item.description.isEmpty ? '-' : item.description,
                style: const TextStyle(height: 1.6),
              ),

              const SizedBox(height: 20),
              const Text(
                'Informasi Paket',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.category_outlined),
                      title: const Text('Kategori'),
                      subtitle: Text(item.categoryName),
                    ),
                    ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: const Text('Tipe Lokasi'),
                      subtitle: Text(item.locationTypeLabel),
                    ),
                    ListTile(
                      leading: const Icon(Icons.schedule_outlined),
                      title: const Text('Durasi'),
                      subtitle: Text('${item.durationMinutes} menit'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.photo_library_outlined),
                      title: const Text('Jumlah Foto Edit'),
                      subtitle: Text('${item.photoCount} foto'),
                    ),
                    if (item.personCount != null)
                      ListTile(
                        leading: const Icon(Icons.people_outline),
                        title: const Text('Jumlah Orang'),
                        subtitle: Text('${item.personCount} orang'),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingScreen(selectedPackage: item),
                    ),
                  );
                },
                child: const Text('Booking'),
              ),
            ],
          );
        },
      ),
    );
  }
}
