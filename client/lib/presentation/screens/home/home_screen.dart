import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/app_setting_model.dart';
import '../../../data/models/package_model.dart';
import '../../../data/models/public_review_model.dart';
import '../../../data/providers/app_setting_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/client_notification_provider.dart';
import '../../../data/providers/package_provider.dart';
import '../../../data/services/app_setting_service.dart';
import '../../widgets/client_home_header.dart';
import '../booking/booking_screen.dart';
import '../contact/contact_screen.dart';
import '../notification/client_notification_screen.dart';
import '../package/package_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onOpenPackages;
  final ValueChanged<String> onOpenPackageCategory;
  final VoidCallback onOpenBooking;
  final VoidCallback onOpenTracking;

  const HomeScreen({
    super.key,
    required this.onOpenPackages,
    required this.onOpenPackageCategory,
    required this.onOpenBooking,
    required this.onOpenTracking,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AppSettingService _appSettingService = AppSettingService();

  late Future<List<PublicReviewModel>> _reviewsFuture;

  @override
  void initState() {
    super.initState();

    _reviewsFuture = _appSettingService.getPublicReviews();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appSettingProvider = context.read<AppSettingProvider>();
      final packageProvider = context.read<PackageProvider>();
      final notificationProvider = context.read<ClientNotificationProvider>();

      appSettingProvider.fetchSettings();
      packageProvider.fetchAll(forceRefresh: packageProvider.packages.isEmpty);
      notificationProvider.fetchNotifications();
    });
  }

  String formatCurrency(double value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  String _clientName(AuthProvider auth) {
    final name = auth.user?.name.trim() ?? '';

    if (name.isNotEmpty) {
      return name;
    }

    final username = auth.user?.username.trim() ?? '';

    if (username.isNotEmpty) {
      return username;
    }

    return 'Klien';
  }

  Future<void> _refresh({
    required AppSettingProvider appSettingProvider,
    required PackageProvider packageProvider,
    required ClientNotificationProvider notificationProvider,
  }) async {
    final newReviewsFuture = _appSettingService.getPublicReviews();

    setState(() {
      _reviewsFuture = newReviewsFuture;
    });

    await Future.wait<Object?>([
      appSettingProvider.refresh(),
      packageProvider.refreshAll(),
      notificationProvider.refresh(),
      newReviewsFuture,
    ]);
  }

  void _openPackageDetail(PackageModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PackageDetailScreen(packageId: item.id),
      ),
    );
  }

  void _openBooking(PackageModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookingScreen(selectedPackage: item)),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ClientNotificationScreen()),
    );
  }

  void _openContact(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ContactScreen()),
    );
  }

  List<PackageModel> _popularPackages(List<PackageModel> packages) {
    final sorted = [...packages];

    sorted.sort((a, b) {
      if (a.hasDiscount != b.hasDiscount) {
        return a.hasDiscount ? -1 : 1;
      }

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return sorted.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appSettingProvider = context.watch<AppSettingProvider>();
    final auth = context.watch<AuthProvider>();
    final packageProvider = context.watch<PackageProvider>();
    final notificationProvider = context.watch<ClientNotificationProvider>();

    final setting = appSettingProvider.setting;

    return SafeArea(
      child: Container(
        color: AppColors.background,
        child: RefreshIndicator(
          color: AppColors.welcomeBlueDark,
          backgroundColor: AppColors.welcomeCardLight,
          onRefresh: () => _refresh(
            appSettingProvider: appSettingProvider,
            packageProvider: packageProvider,
            notificationProvider: notificationProvider,
          ),
          child: _buildContent(
            context: context,
            setting: setting,
            auth: auth,
            packageProvider: packageProvider,
            notificationProvider: notificationProvider,
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required AppSettingModel setting,
    required AuthProvider auth,
    required PackageProvider packageProvider,
    required ClientNotificationProvider notificationProvider,
  }) {
    if (setting.system.maintenanceMode) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 120),
          _MaintenanceCard(setting: setting),
        ],
      );
    }

    final activePackages = packageProvider.packages
        .where((item) => item.isActive)
        .toList();

    final promoPackages = activePackages
        .where((item) => item.hasDiscount)
        .toList();

    final portfolioPackages = activePackages
        .where(
          (item) => item.portfolio.isNotEmpty || item.coverImage.isNotEmpty,
        )
        .toList();

    final popularPackages = _popularPackages(activePackages);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 118),
      children: [
        ClientHomeHeader(
          setting: setting,
          clientName: _clientName(auth),
          unreadNotificationCount: notificationProvider.unreadCount,
          onNotificationPressed: _openNotifications,
          onBookingPressed: widget.onOpenBooking,
          onSupportPressed: setting.clientHome.showSupportContact
              ? () => _openContact(context)
              : null,
        ),

        const SizedBox(height: 22),

        if (packageProvider.isLoading && activePackages.isEmpty)
          const _LoadingBanner()
        else if (promoPackages.isEmpty)
          _PromoFallbackBanner(setting: setting, onTap: widget.onOpenPackages)
        else
          _PromoBannerList(
            packages: promoPackages,
            portfolioPackages: portfolioPackages,
            formatCurrency: formatCurrency,
            onDetail: _openPackageDetail,
          ),

        const SizedBox(height: 26),

        const _SectionTitle(title: 'Kategori'),

        const SizedBox(height: 12),

        _CategoryScroller(
          packages: activePackages,
          onTapAll: widget.onOpenPackages,
          onTapCategory: widget.onOpenPackageCategory,
        ),

        const SizedBox(height: 18),

        _SearchLikeBox(onTap: widget.onOpenPackages),

        if (setting.clientHome.showPopularPackages) ...[
          const SizedBox(height: 26),
          const _SectionTitle(title: 'Paket Populer'),
          const SizedBox(height: 12),
          if (packageProvider.isLoading && activePackages.isEmpty)
            const SizedBox(
              height: 236,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.welcomeBlueDark,
                ),
              ),
            )
          else if (popularPackages.isEmpty)
            const _EmptyCard(
              icon: Icons.inventory_2_outlined,
              title: 'Paket belum tersedia',
              subtitle:
                  'Paket aktif akan muncul setelah admin mengaktifkan paket layanan.',
            )
          else
            _PopularPackageList(
              packages: popularPackages,
              formatCurrency: formatCurrency,
              onDetail: _openPackageDetail,
              onBooking: _openBooking,
            ),
        ],

        if (setting.clientHome.showClientReviews) ...[
          const SizedBox(height: 28),
          FutureBuilder<List<PublicReviewModel>>(
            future: _reviewsFuture,
            builder: (context, reviewSnapshot) {
              final reviews = reviewSnapshot.data ?? [];

              if (reviewSnapshot.connectionState == ConnectionState.waiting) {
                return const _ReviewLoadingCard();
              }

              return _PublicReviewSection(reviews: reviews);
            },
          ),
        ],
      ],
    );
  }
}

class _SearchLikeBox extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchLikeBox({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: AppColors.welcomeCardGradient,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.72)),
          boxShadow: [
            BoxShadow(
              color: AppColors.welcomeBlueDark.withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: AppColors.welcomeBlueDark.withOpacity(0.76),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cari paket foto, kategori, atau promo studio',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.welcomeBlueDark.withOpacity(0.62),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 31,
              height: 31,
              decoration: const BoxDecoration(
                color: AppColors.welcomeBlueDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoBannerList extends StatelessWidget {
  final List<PackageModel> packages;
  final List<PackageModel> portfolioPackages;
  final String Function(double) formatCurrency;
  final ValueChanged<PackageModel> onDetail;

  const _PromoBannerList({
    required this.packages,
    required this.portfolioPackages,
    required this.formatCurrency,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 36;
    final visiblePackages = packages.take(6).toList();

    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visiblePackages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = visiblePackages[index];

          return SizedBox(
            width: width,
            child: _PromoBannerCard(
              item: item,
              portfolioPackages: portfolioPackages,
              portfolioIndex: index,
              formatCurrency: formatCurrency,
              onTap: () => onDetail(item),
            ),
          );
        },
      ),
    );
  }
}

class _PromoBannerCard extends StatelessWidget {
  final PackageModel item;
  final List<PackageModel> portfolioPackages;
  final int portfolioIndex;
  final String Function(double) formatCurrency;
  final VoidCallback onTap;

  const _PromoBannerCard({
    required this.item,
    required this.portfolioPackages,
    required this.portfolioIndex,
    required this.formatCurrency,
    required this.onTap,
  });

  String _portfolioImage() {
    if (item.coverImage.isNotEmpty) {
      return item.coverImage;
    }

    if (item.portfolio.isNotEmpty) {
      return item.portfolio.first;
    }

    if (portfolioPackages.isNotEmpty) {
      final safeIndex = portfolioIndex % portfolioPackages.length;
      final package = portfolioPackages[safeIndex];

      if (package.coverImage.isNotEmpty) {
        return package.coverImage;
      }

      if (package.portfolio.isNotEmpty) {
        return package.portfolio.first;
      }
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final discount = item.activeDiscount;
    final percent = discount?.discountPercent ?? 0;
    final promoName = discount?.promoName.trim().isNotEmpty == true
        ? discount!.promoName
        : 'Special Offer';

    final imageUrl = _portfolioImage();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: AppColors.welcomeDarkGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.welcomeBlueDark.withOpacity(0.24),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return Container(
                    color: AppColors.welcomeBlueDark,
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.welcomeBlueDark,
                  child: Icon(
                    Icons.photo_camera_outlined,
                    color: Colors.white.withOpacity(0.35),
                    size: 52,
                  ),
                ),
              )
            else
              Container(
                color: AppColors.welcomeBlueDark,
                child: Icon(
                  Icons.photo_camera_outlined,
                  color: Colors.white.withOpacity(0.35),
                  size: 52,
                ),
              ),

            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.welcomeBlueDark.withOpacity(0.96),
                    AppColors.welcomeBlueMid.withOpacity(0.72),
                    AppColors.welcomeBlueLight.withOpacity(0.24),
                  ],
                ),
              ),
            ),

            Positioned(
              right: -26,
              top: -20,
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),

            Positioned(
              right: 22,
              bottom: -20,
              child: Text(
                'Frame',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.15),
                  fontSize: 48,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.20)),
                    ),
                    child: Text(
                      promoName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Diskon $percent% untuk',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.88),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const Spacer(),

                  Row(
                    children: [
                      Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'BOOK NOW',
                          style: TextStyle(
                            color: AppColors.welcomeBlueDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          formatCurrency(item.finalPrice),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
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

class _PromoFallbackBanner extends StatelessWidget {
  final AppSettingModel setting;
  final VoidCallback onTap;

  const _PromoFallbackBanner({required this.setting, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final studioName = setting.studio.name.trim().isNotEmpty
        ? setting.studio.name.trim()
        : 'MONOFRAME STUDIO';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 168,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: AppColors.welcomeDarkGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.welcomeBlueDark.withOpacity(0.22),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              top: -26,
              child: Icon(
                Icons.camera_alt_rounded,
                size: 128,
                color: Colors.white.withOpacity(0.10),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 190),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    studioName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Temukan Paket Foto Terbaik',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  setting.clientHome.subtitle.isNotEmpty
                      ? setting.clientHome.subtitle
                      : 'Pilih paket, tentukan jadwal, dan pantau progres langsung dari aplikasi.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.82),
                    height: 1.35,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'LIHAT PAKET',
                    style: TextStyle(
                      color: AppColors.welcomeBlueDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
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

class _LoadingBanner extends StatelessWidget {
  const _LoadingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 168,
      decoration: BoxDecoration(
        gradient: AppColors.welcomeCardGradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.72)),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.welcomeBlueDark),
      ),
    );
  }
}

class _CategoryScroller extends StatelessWidget {
  final List<PackageModel> packages;
  final VoidCallback onTapAll;
  final ValueChanged<String> onTapCategory;

  const _CategoryScroller({
    required this.packages,
    required this.onTapAll,
    required this.onTapCategory,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, int> categoryCounts = {};

    for (final item in packages) {
      final category = item.categoryName.trim().isEmpty
          ? 'Tanpa Kategori'
          : item.categoryName.trim();

      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    final categories = categoryCounts.keys.toList()..sort();

    if (packages.isEmpty) {
      return const _EmptyMiniText(text: 'Kategori belum tersedia.');
    }

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _CategoryPill(
              title: 'Semua Paket',
              count: packages.length,
              icon: Icons.grid_view_rounded,
              selected: true,
              onTap: onTapAll,
            );
          }

          final category = categories[index - 1];
          final count = categoryCounts[category] ?? 0;

          return _CategoryPill(
            title: category,
            count: count,
            icon: _categoryIcon(category),
            selected: false,
            onTap: () => onTapCategory(category),
          );
        },
      ),
    );
  }

  IconData _categoryIcon(String category) {
    final text = category.toLowerCase();

    if (text.contains('wedding') || text.contains('nikah')) {
      return Icons.favorite_rounded;
    }

    if (text.contains('family') || text.contains('keluarga')) {
      return Icons.groups_rounded;
    }

    if (text.contains('wisuda') || text.contains('graduation')) {
      return Icons.school_rounded;
    }

    if (text.contains('produk') || text.contains('product')) {
      return Icons.inventory_2_rounded;
    }

    if (text.contains('studio')) {
      return Icons.camera_indoor_rounded;
    }

    if (text.contains('outdoor')) {
      return Icons.landscape_rounded;
    }

    return Icons.photo_camera_rounded;
  }
}

class _CategoryPill extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.title,
    required this.count,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.welcomeBlueDark;

    final subtitleColor = selected
        ? Colors.white.withOpacity(0.74)
        : AppColors.welcomeBlueDark.withOpacity(0.64);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 142,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: selected
              ? AppColors.welcomeDarkGradient
              : AppColors.welcomeCardGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? AppColors.welcomeCardDeep.withOpacity(0.86)
                : Colors.white.withOpacity(0.72),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.welcomeBlueDark.withOpacity(
                selected ? 0.18 : 0.08,
              ),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withOpacity(0.14)
                    : Colors.white.withOpacity(0.68),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: foreground, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$count paket',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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

class _PopularPackageList extends StatelessWidget {
  final List<PackageModel> packages;
  final String Function(double) formatCurrency;
  final ValueChanged<PackageModel> onDetail;
  final ValueChanged<PackageModel> onBooking;

  const _PopularPackageList({
    required this.packages,
    required this.formatCurrency,
    required this.onDetail,
    required this.onBooking,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 246,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: packages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = packages[index];

          return _PopularPackageCard(
            item: item,
            formatCurrency: formatCurrency,
            onDetail: () => onDetail(item),
            onBooking: () => onBooking(item),
          );
        },
      ),
    );
  }
}

class _PopularPackageCard extends StatelessWidget {
  final PackageModel item;
  final String Function(double) formatCurrency;
  final VoidCallback onDetail;
  final VoidCallback onBooking;

  const _PopularPackageCard({
    required this.item,
    required this.formatCurrency,
    required this.onDetail,
    required this.onBooking,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onDetail,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: 168,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: AppColors.welcomeCardGradient,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withOpacity(0.72)),
          boxShadow: [
            BoxShadow(
              color: AppColors.welcomeBlueDark.withOpacity(0.10),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PackageCover(item: item),

            const SizedBox(height: 10),

            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.welcomeBlueDark,
                fontSize: 14,
                height: 1.18,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              item.categoryName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.welcomeBlueDark.withOpacity(0.64),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: Text(
                    formatCurrency(item.finalPrice),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.welcomeBlueDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onBooking,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.welcomeBlueDark,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
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

class _PackageCover extends StatelessWidget {
  final PackageModel item;

  const _PackageCover({required this.item});

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.coverImage.isNotEmpty
        ? item.coverImage
        : item.portfolio.isNotEmpty
        ? item.portfolio.first
        : '';

    return Container(
      height: 112,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _PackageImageFallback(),
            )
          else
            const _PackageImageFallback(),

          if (item.hasDiscount)
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.welcomeBlueDark.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${item.activeDiscount?.discountPercent ?? 0}% OFF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PackageImageFallback extends StatelessWidget {
  const _PackageImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primarySoft,
      child: const Center(
        child: Icon(
          Icons.photo_camera_outlined,
          color: AppColors.welcomeBlueDark,
          size: 34,
        ),
      ),
    );
  }
}

class _PublicReviewSection extends StatelessWidget {
  final List<PublicReviewModel> reviews;

  const _PublicReviewSection({required this.reviews});

  double _averageRating() {
    if (reviews.isEmpty) return 0;

    final total = reviews.fold<int>(
      0,
      (sum, item) => sum + item.rating.clamp(0, 5).toInt(),
    );

    return total / reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    final average = _averageRating();
    final averageText = reviews.isEmpty ? '0.0' : average.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Review Klien'),

        const SizedBox(height: 12),

        _ReviewSummaryCard(
          totalReview: reviews.length,
          averageRatingText: averageText,
        ),

        const SizedBox(height: 12),

        if (reviews.isEmpty)
          const _EmptyCard(
            icon: Icons.rate_review_outlined,
            title: 'Belum ada review yang tampil',
            subtitle:
                'Review akan muncul jika sudah ada ulasan klien yang lolos pengaturan review publik.',
          )
        else
          Column(
            children: reviews.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PublicReviewCard(item: item),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _ReviewSummaryCard extends StatelessWidget {
  final int totalReview;
  final String averageRatingText;

  const _ReviewSummaryCard({
    required this.totalReview,
    required this.averageRatingText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.welcomeDarkGradient,
        borderRadius: BorderRadius.circular(26),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -36,
            child: Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 34,
            bottom: -50,
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: Colors.white.withOpacity(0.20)),
                ),
                child: const Icon(
                  Icons.reviews_rounded,
                  color: Colors.white,
                  size: 29,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Apa kata klien?',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      totalReview == 0
                          ? 'Belum ada review publik yang tampil.'
                          : '$totalReview review dari klien Monoframe Studio.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.74),
                        fontSize: 12.4,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ReviewHeroPill(
                            icon: Icons.star_rounded,
                            text: '$averageRatingText rating',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ReviewHeroPill(
                            icon: Icons.public_rounded,
                            text: 'Review publik',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewHeroPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ReviewHeroPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicReviewCard extends StatelessWidget {
  final PublicReviewModel item;

  const _PublicReviewCard({required this.item});

  String _initial() {
    final name = item.clientName.trim();

    if (name.isEmpty) return 'K';

    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final rating = item.rating.clamp(0, 5).toInt();
    final clientName = item.clientName.trim().isEmpty
        ? 'Klien Monoframe'
        : item.clientName.trim();

    final comment = item.comment.trim().isEmpty
        ? 'Klien belum menulis komentar.'
        : item.comment.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: AppColors.welcomeCardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.72)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: AppColors.welcomeBlueDark,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _initial(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.welcomeBlueDark,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Klien Monoframe Studio',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.welcomeBlueDark.withOpacity(0.58),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.62),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.78)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.warning,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$rating/5',
                      style: TextStyle(
                        color: AppColors.welcomeBlueDark.withOpacity(0.70),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _ReviewStars(rating: rating),

          const SizedBox(height: 10),

          Text(
            comment,
            style: TextStyle(
              color: AppColors.welcomeBlueDark.withOpacity(0.76),
              height: 1.45,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewStars extends StatelessWidget {
  final int rating;

  const _ReviewStars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final active = index < rating;

        return Icon(
          active ? Icons.star_rounded : Icons.star_border_rounded,
          color: active
              ? AppColors.warning
              : AppColors.welcomeBlueDark.withOpacity(0.28),
          size: 18,
        );
      }),
    );
  }
}

class _ReviewLoadingCard extends StatelessWidget {
  const _ReviewLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Review Klien'),
        const SizedBox(height: 12),
        Container(
          height: 132,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppColors.welcomeCardGradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.72)),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.welcomeBlueDark),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const _SectionTitle({required this.title, this.actionText, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.welcomeBlueDark,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.dark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (actionText != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionText!,
              style: const TextStyle(
                color: AppColors.welcomeBlueDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  final AppSettingModel setting;

  const _MaintenanceCard({required this.setting});

  @override
  Widget build(BuildContext context) {
    final studioName = setting.studio.name.trim().isNotEmpty
        ? setting.studio.name.trim()
        : 'Monoframe Studio';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.welcomeCardGradient,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.72)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.construction_rounded,
            color: AppColors.welcomeBlueDark,
            size: 58,
          ),
          const SizedBox(height: 18),
          Text(
            studioName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.welcomeBlueDark,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            setting.system.maintenanceMessage.isNotEmpty
                ? setting.system.maintenanceMessage
                : 'Aplikasi sedang dalam perbaikan. Silakan coba kembali beberapa saat lagi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.welcomeBlueDark.withOpacity(0.68),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMiniText extends StatelessWidget {
  final String text;

  const _EmptyMiniText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: AppColors.grey));
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyCard({
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
        gradient: AppColors.welcomeCardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.72)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.welcomeBlueDark, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.welcomeBlueDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.welcomeBlueDark.withOpacity(0.68),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
