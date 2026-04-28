import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/app_setting_model.dart';
import '../../../data/models/package_model.dart';
import '../../../data/models/public_review_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/package_provider.dart';
import '../../../data/services/app_setting_service.dart';
import '../../widgets/client_home_header.dart';
import '../contact/contact_screen.dart';
import '../package/package_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onOpenPackages;
  final VoidCallback onOpenBooking;
  final VoidCallback onOpenTracking;

  const HomeScreen({
    super.key,
    required this.onOpenPackages,
    required this.onOpenBooking,
    required this.onOpenTracking,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AppSettingService _appSettingService = AppSettingService();

  late Future<AppSettingModel> _settingsFuture;
  late Future<List<PublicReviewModel>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _settingsFuture = _appSettingService.getAppSettings();
    _reviewsFuture = _appSettingService.getPublicReviews();
  }

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

  Future<void> _refresh(PackageProvider packageProvider) async {
    setState(_loadSettings);

    await Future.wait<Object?>([
      packageProvider.refreshAll(),
      _settingsFuture,
      _reviewsFuture,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final packageProvider = context.watch<PackageProvider>();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => _refresh(packageProvider),
        child: FutureBuilder<AppSettingModel>(
          future: _settingsFuture,
          builder: (context, settingsSnapshot) {
            final setting = settingsSnapshot.data;
            final isSettingLoading =
                settingsSnapshot.connectionState == ConnectionState.waiting;
            final hasSettingError = settingsSnapshot.hasError;

            if (setting?.system.maintenanceMode == true) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 120),
                  _MaintenanceCard(setting: setting!),
                ],
              );
            }

            final showPopularPackages =
                setting?.clientHome.showPopularPackages ?? true;
            final showClientReviews =
                setting?.clientHome.showClientReviews ?? true;
            final showSupportContact =
                setting?.clientHome.showSupportContact ?? true;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (isSettingLoading)
                  const _LoadingHeroCard()
                else if (hasSettingError)
                  _ErrorHeroCard(
                    message: settingsSnapshot.error.toString().replaceFirst(
                      'Exception: ',
                      '',
                    ),
                    username: auth.user?.username.isNotEmpty == true
                        ? '@${auth.user!.username}'
                        : auth.user?.name ?? 'Klien',
                  )
                else if (setting != null)
                  ClientHomeHeader(
                    setting: setting,
                    onBookingPressed: widget.onOpenPackages,
                    onSupportPressed: showSupportContact
                        ? () => _openContact(context)
                        : null,
                  )
                else
                  _DefaultHeroCard(
                    username: auth.user?.username.isNotEmpty == true
                        ? '@${auth.user!.username}'
                        : auth.user?.name ?? 'Klien',
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
                      onTap: widget.onOpenPackages,
                    ),
                    _MenuCard(
                      icon: Icons.calendar_month_outlined,
                      title: 'Booking',
                      subtitle: 'Riwayat booking',
                      onTap: widget.onOpenBooking,
                    ),
                    _MenuCard(
                      icon: Icons.track_changes_outlined,
                      title: 'Tracking',
                      subtitle: 'Cek progres',
                      onTap: widget.onOpenTracking,
                    ),
                    if (showSupportContact)
                      _MenuCard(
                        icon: Icons.support_agent_outlined,
                        title: 'Kontak',
                        subtitle: 'Tanya paket/custom',
                        onTap: () => _openContact(context),
                      )
                    else
                      _MenuCard(
                        icon: Icons.info_outline,
                        title: 'Info Studio',
                        subtitle: setting?.studio.name ?? 'Monoframe',
                        onTap: () {},
                      ),
                  ],
                ),

                if (showPopularPackages) ...[
                  const SizedBox(height: 28),
                  const Text(
                    'Promo & Diskon',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (packageProvider.isLoading &&
                      packageProvider.packages.isEmpty)
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
                          final item =
                              packageProvider.discountedPackages[index];

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
                ],

                if (showClientReviews) ...[
                  const SizedBox(height: 28),
                  _PublicReviewSection(reviewsFuture: _reviewsFuture),
                ],

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
                    onTap: widget.onOpenPackages,
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
                    onTap: widget.onOpenPackages,
                  ),
                ),

                if (showSupportContact) ...[
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
                ],

                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  final AppSettingModel setting;

  const _MaintenanceCard({required this.setting});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.construction_rounded,
              color: AppColors.primary,
              size: 38,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            setting.studio.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            setting.system.maintenanceMessage.isNotEmpty
                ? setting.system.maintenanceMessage
                : 'Aplikasi sedang dalam perbaikan. Silakan coba kembali beberapa saat lagi.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _LoadingHeroCard extends StatelessWidget {
  const _LoadingHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF8A84FF)],
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

class _ErrorHeroCard extends StatelessWidget {
  final String message;
  final String username;

  const _ErrorHeroCard({required this.message, required this.username});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            username,
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
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Pengaturan aplikasi belum bisa dimuat: $message',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DefaultHeroCard extends StatelessWidget {
  final String username;

  const _DefaultHeroCard({required this.username});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            username,
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
    );
  }
}

class _PublicReviewSection extends StatelessWidget {
  final Future<List<PublicReviewModel>> reviewsFuture;

  const _PublicReviewSection({required this.reviewsFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PublicReviewModel>>(
      future: reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final reviews = snapshot.data ?? <PublicReviewModel>[];

        if (reviews.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Review Klien',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 182,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: reviews.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _ReviewCard(review: reviews[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final PublicReviewModel review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      review.packageName.isNotEmpty
                          ? review.packageName
                          : 'Paket Foto',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 3),
                  Text(
                    review.rating.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              review.comment.isNotEmpty
                  ? review.comment
                  : 'Klien puas dengan layanan Monoframe Studio.',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF374151), height: 1.45),
            ),
          ),
        ],
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
                '${discount?.promoName ?? "Promo"} - ${discount?.discountPercent ?? 0}%',
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
              '${package.locationTypeLabel} - ${package.durationMinutes} menit - ${package.photoCount} foto edit',
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
