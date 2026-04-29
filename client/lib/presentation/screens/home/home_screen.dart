import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/app_setting_model.dart';
import '../../../data/models/package_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/package_provider.dart';
import '../../../data/services/app_setting_service.dart';
import '../../widgets/client_home_header.dart';
import '../booking/booking_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _settingsFuture = _appSettingService.getAppSettings();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PackageProvider>();
      provider.fetchAll(forceRefresh: provider.packages.isEmpty);
    });
  }

  String formatCurrency(double value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  String _username(AuthProvider auth) {
    if (auth.user?.username.isNotEmpty == true)
      return '@${auth.user!.username}';
    return auth.user?.name ?? 'Klien';
  }

  void _openContact(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ContactScreen()),
    );
  }

  Future<void> _refresh(PackageProvider packageProvider) async {
    setState(() {
      _settingsFuture = _appSettingService.getAppSettings();
    });

    await Future.wait<Object?>([packageProvider.refreshAll(), _settingsFuture]);
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
          builder: (context, snapshot) {
            final setting = snapshot.data ?? AppSettingModel.fallback();

            if (setting.system.maintenanceMode) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 120),
                  _MaintenanceCard(setting: setting),
                ],
              );
            }

            final packages = packageProvider.packages;
            final portfolios = packages
                .where((item) => item.portfolio.isNotEmpty)
                .toList();

            final recommended = packages.take(6).toList();

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ClientHomeHeader(
                  setting: setting,
                  username: _username(auth),
                  onBookingPressed: widget.onOpenPackages,
                  onSupportPressed: setting.clientHome.showSupportContact
                      ? () => _openContact(context)
                      : null,
                ),
                const SizedBox(height: 22),
                _QuickActions(
                  onPackages: widget.onOpenPackages,
                  onBooking: widget.onOpenBooking,
                  onTracking: widget.onOpenTracking,
                  onContact: setting.clientHome.showSupportContact
                      ? () => _openContact(context)
                      : null,
                ),
                const SizedBox(height: 28),
                _SectionHeader(
                  title: 'Portofolio Monoframe',
                  subtitle: 'Lihat hasil foto yang sudah diinput admin.',
                  onSeeAll: widget.onOpenPackages,
                ),
                const SizedBox(height: 14),
                if (packageProvider.isLoading && portfolios.isEmpty)
                  const SizedBox(
                    height: 210,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (portfolios.isEmpty)
                  const _EmptyPortfolioCard()
                else
                  _PortfolioSlider(
                    packages: portfolios,
                    formatCurrency: formatCurrency,
                    onOpenDetail: (item) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PackageDetailScreen(packageId: item.id),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 28),
                _SectionHeader(
                  title: 'Kategori Paket',
                  subtitle: 'Pilih layanan sesuai kebutuhan sesi foto.',
                  onSeeAll: widget.onOpenPackages,
                ),
                const SizedBox(height: 14),
                _CategoryChips(
                  packages: packages,
                  onTapCategory: widget.onOpenPackages,
                ),
                const SizedBox(height: 28),
                _SectionHeader(
                  title: 'Paket Rekomendasi',
                  subtitle: '${packages.length} paket tersedia',
                  onSeeAll: widget.onOpenPackages,
                ),
                const SizedBox(height: 14),
                if (packageProvider.isLoading && packages.isEmpty)
                  const SizedBox(
                    height: 170,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (recommended.isEmpty)
                  const _EmptyPackageCard()
                else
                  ...recommended.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _HomePackageCard(
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
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.construction_rounded,
            color: AppColors.primaryDark,
            size: 58,
          ),
          const SizedBox(height: 18),
          Text(
            setting.studio.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
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

class _QuickActions extends StatelessWidget {
  final VoidCallback onPackages;
  final VoidCallback onBooking;
  final VoidCallback onTracking;
  final VoidCallback? onContact;

  const _QuickActions({
    required this.onPackages,
    required this.onBooking,
    required this.onTracking,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickActionItem(
        icon: Icons.photo_library_outlined,
        title: 'Paket',
        onTap: onPackages,
      ),
      _QuickActionItem(
        icon: Icons.calendar_month_outlined,
        title: 'Booking',
        onTap: onBooking,
      ),
      _QuickActionItem(
        icon: Icons.track_changes_outlined,
        title: 'Tracking',
        onTap: onTracking,
      ),
      _QuickActionItem(
        icon: Icons.support_agent_outlined,
        title: 'Kontak',
        onTap: onContact ?? onPackages,
      ),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: .82,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(item.icon, color: AppColors.primaryDark),
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickActionItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _QuickActionItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        TextButton(onPressed: onSeeAll, child: const Text('Lihat semua')),
      ],
    );
  }
}

class _PortfolioSlider extends StatelessWidget {
  final List<PackageModel> packages;
  final String Function(double) formatCurrency;
  final ValueChanged<PackageModel> onOpenDetail;

  const _PortfolioSlider({
    required this.packages,
    required this.formatCurrency,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 258,
      child: PageView.builder(
        controller: PageController(viewportFraction: .88),
        itemCount: packages.length,
        itemBuilder: (context, index) {
          final item = packages[index];
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: InkWell(
              onTap: () => onOpenDetail(item),
              borderRadius: BorderRadius.circular(28),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      item.coverImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primaryLight,
                        child: const Icon(
                          Icons.photo_camera_outlined,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.primaryDark.withOpacity(0.88),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.categoryName,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.80),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${item.locationTypeLabel} - ${item.durationMinutes} menit - ${formatCurrency(item.finalPrice)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.82),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<PackageModel> packages;
  final VoidCallback onTapCategory;

  const _CategoryChips({required this.packages, required this.onTapCategory});

  @override
  Widget build(BuildContext context) {
    final categories = packages.map((e) => e.categoryName).toSet().toList()
      ..sort();

    if (categories.isEmpty) {
      return const _EmptyPackageCard();
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _CategoryChip(
          label: 'Semua',
          count: packages.length,
          onTap: onTapCategory,
        ),
        ...categories.map((category) {
          final count = packages
              .where((item) => item.categoryName == category)
              .length;
          return _CategoryChip(
            label: category,
            count: count,
            onTap: onTapCategory,
          );
        }),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.border),
      avatar: CircleAvatar(
        backgroundColor: AppColors.primarySoft,
        foregroundColor: AppColors.primaryDark,
        child: Text(count.toString(), style: const TextStyle(fontSize: 11)),
      ),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class _HomePackageCard extends StatelessWidget {
  final PackageModel package;
  final String Function(double) formatCurrency;
  final VoidCallback onDetail;
  final VoidCallback onBooking;

  const _HomePackageCard({
    required this.package,
    required this.formatCurrency,
    required this.onDetail,
    required this.onBooking,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onDetail,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: 96,
                height: 96,
                child: package.coverImage.isEmpty
                    ? Container(
                        color: AppColors.primarySoft,
                        child: const Icon(
                          Icons.photo_camera_outlined,
                          color: AppColors.primaryDark,
                        ),
                      )
                    : Image.network(
                        package.coverImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.primarySoft,
                          child: const Icon(
                            Icons.photo_camera_outlined,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.categoryName,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    package.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${package.locationTypeLabel} - ${package.durationMinutes} menit',
                    style: const TextStyle(color: AppColors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    formatCurrency(package.finalPrice),
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onBooking,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPortfolioCard extends StatelessWidget {
  const _EmptyPortfolioCard();

  @override
  Widget build(BuildContext context) {
    return const _EmptyInfoCard(
      icon: Icons.photo_library_outlined,
      title: 'Portofolio belum tersedia',
      subtitle: 'Upload portofolio dari admin saat membuat paket foto.',
    );
  }
}

class _EmptyPackageCard extends StatelessWidget {
  const _EmptyPackageCard();

  @override
  Widget build(BuildContext context) {
    return const _EmptyInfoCard(
      icon: Icons.inventory_2_outlined,
      title: 'Paket belum tersedia',
      subtitle: 'Paket foto akan muncul setelah admin mengaktifkannya.',
    );
  }
}

class _EmptyInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyInfoCard({
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
