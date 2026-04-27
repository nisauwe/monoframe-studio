import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/package_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/package_provider.dart';
import '../contact/contact_screen.dart';
import '../package/package_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onOpenPackages;
  final VoidCallback onOpenBooking;
  final VoidCallback onOpenTracking;

  const HomeScreen({
    super.key,
    required this.onOpenPackages,
    required this.onOpenBooking,
    required this.onOpenTracking,
  });

  String formatCurrency(double value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  void _openContact(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ContactScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final packageProvider = context.watch<PackageProvider>();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: packageProvider.refreshAll,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF8A84FF)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selamat datang,',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    auth.user?.username.isNotEmpty == true
                        ? '@${auth.user!.username}'
                        : auth.user?.name ?? 'Klien',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Lihat promo, pilih paket foto, lalu lanjut booking langsung dari aplikasi.',
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                _MenuCard(
                  icon: Icons.inventory_2_outlined,
                  title: 'Paket Foto',
                  subtitle: 'Lihat semua paket',
                  onTap: onOpenPackages,
                ),
                _MenuCard(
                  icon: Icons.calendar_month_outlined,
                  title: 'Booking',
                  subtitle: 'Riwayat booking',
                  onTap: onOpenBooking,
                ),
                _MenuCard(
                  icon: Icons.track_changes_outlined,
                  title: 'Tracking',
                  subtitle: 'Cek progres',
                  onTap: onOpenTracking,
                ),
                _MenuCard(
                  icon: Icons.support_agent_outlined,
                  title: 'Kontak',
                  subtitle: 'Tanya paket/custom',
                  onTap: () => _openContact(context),
                ),
              ],
            ),

            const SizedBox(height: 28),

            const Text(
              'Promo & Diskon',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            if (packageProvider.isLoading && packageProvider.packages.isEmpty)
              const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (packageProvider.discountedPackages.isEmpty)
              Container(
                height: 170,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Center(
                  child: Text(
                    'Belum ada promo aktif saat ini.',
                    style: TextStyle(color: AppColors.grey),
                  ),
                ),
              )
            else
              SizedBox(
                height: 230,
                child: PageView.builder(
                  controller: PageController(viewportFraction: 0.9),
                  itemCount: packageProvider.discountedPackages.length,
                  itemBuilder: (context, index) {
                    final item = packageProvider.discountedPackages[index];

                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _PromoCard(
                        package: item,
                        formatCurrency: formatCurrency,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PackageDetailScreen(packageId: item.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 28),

            const Text(
              'Ringkasan Layanan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Paket Foto'),
                subtitle: Text(
                  '${packageProvider.packages.length} paket tersedia',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: onOpenPackages,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const Icon(Icons.print_outlined),
                title: const Text('Paket Cetak & Bingkai'),
                subtitle: Text(
                  '${packageProvider.printPrices.length} ukuran tersedia',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: onOpenPackages,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const Icon(Icons.support_agent_outlined),
                title: const Text('Kontak Monoframe'),
                subtitle: const Text(
                  'Tanya paket foto, request custom, atau kendala aplikasi',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openContact(context),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final PackageModel package;
  final String Function(double) formatCurrency;
  final VoidCallback onTap;

  const _PromoCard({
    required this.package,
    required this.formatCurrency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final discount = package.activeDiscount;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Color(0xFF111827), Color(0xFF374151)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${discount?.promoName ?? "Promo"} • ${discount?.discountPercent ?? 0}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              package.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${package.locationTypeLabel} • ${package.durationMinutes} menit • ${package.photoCount} foto edit',
              style: const TextStyle(color: Colors.white70),
            ),
            const Spacer(),
            Text(
              formatCurrency(package.price),
              style: const TextStyle(
                color: Colors.white54,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            Text(
              formatCurrency(package.finalPrice),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
