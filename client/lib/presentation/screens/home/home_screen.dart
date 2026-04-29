import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/app_setting_model.dart';
import '../../../data/models/package_model.dart';
import '../../../data/models/public_review_model.dart';
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

  late Future<AppSettingModel> _settingsFuture;
  late Future<List<PublicReviewModel>> _reviewsFuture;

  @override
  void initState() {
    super.initState();

    _settingsFuture = _appSettingService.getAppSettings();
    _reviewsFuture = _appSettingService.getPublicReviews();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final packageProvider = context.read<PackageProvider>();

      packageProvider.fetchAll(forceRefresh: packageProvider.packages.isEmpty);
      context.read<ClientNotificationProvider>().fetchNotifications();
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

  Future<void> _refresh(
    PackageProvider packageProvider,
    ClientNotificationProvider notificationProvider,
  ) async {
    setState(() {
      _settingsFuture = _appSettingService.getAppSettings();
      _reviewsFuture = _appSettingService.getPublicReviews();
    });

    await Future.wait<Object?>([
      packageProvider.refreshAll(),
      notificationProvider.refresh(),
      _settingsFuture,
      _reviewsFuture,
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final packageProvider = context.watch<PackageProvider>();
    final notificationProvider = context.watch<ClientNotificationProvider>();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => _refresh(packageProvider, notificationProvider),
        child: FutureBuilder<AppSettingModel>(
          future: _settingsFuture,
          builder: (context, snapshot) {
            final setting = snapshot.data ?? AppSettingModel.fallback();

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

            final packages = packageProvider.packages;
            final promoPackages = packageProvider.discountedPackages;
            final portfolioPackages = packages
                .where((item) => item.portfolio.isNotEmpty)
                .toList();

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 118),
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

                _SearchLikeBox(onTap: widget.onOpenPackages),

                const SizedBox(height: 24),

                _SectionTitle(
                  title: 'Kategori',
                  actionText: 'See all',
                  onAction: widget.onOpenPackages,
                ),

                const SizedBox(height: 12),

                _CategoryScroller(
                  packages: packages,
                  onTapCategory: widget.onOpenPackageCategory,
                ),

                const SizedBox(height: 26),

                _SectionTitle(
                  title: 'Promo Hari Ini',
                  actionText: 'See all',
                  onAction: widget.onOpenPackages,
                ),

                const SizedBox(height: 12),

                if (packageProvider.isLoading && packages.isEmpty)
                  const SizedBox(
                    height: 190,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (promoPackages.isEmpty)
                  const _EmptyCard(
                    icon: Icons.local_offer_outlined,
                    title: 'Belum ada promo hari ini',
                    subtitle:
                        'Promo akan muncul otomatis sesuai tanggal yang diatur admin.',
                  )
                else
                  _PromoList(
                    packages: promoPackages,
                    formatCurrency: formatCurrency,
                    onDetail: _openPackageDetail,
                  ),

                const SizedBox(height: 26),

                _SectionTitle(
                  title: 'Portofolio Review',
                  actionText: 'See all',
                  onAction: widget.onOpenPackages,
                ),

                const SizedBox(height: 12),

                if (packageProvider.isLoading && packages.isEmpty)
                  const SizedBox(
                    height: 138,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (portfolioPackages.isEmpty)
                  const _EmptyCard(
                    icon: Icons.photo_library_outlined,
                    title: 'Portofolio belum tersedia',
                    subtitle:
                        'Gambar portofolio akan muncul setelah admin mengisi foto paket.',
                  )
                else
                  _PortfolioStrip(
                    packages: portfolioPackages,
                    onDetail: _openPackageDetail,
                  ),

                const SizedBox(height: 26),

                FutureBuilder<List<PublicReviewModel>>(
                  future: _reviewsFuture,
                  builder: (context, reviewSnapshot) {
                    final reviews = reviewSnapshot.data ?? [];

                    if (reviews.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle(title: 'Review Klien'),
                        const SizedBox(height: 12),
                        _ReviewList(reviews: reviews.take(5).toList()),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
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
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.search_rounded, color: AppColors.grey),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cari paket foto Monoframe',
                style: TextStyle(
                  color: AppColors.grey,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.tune_rounded, color: AppColors.primaryDark),
          ],
        ),
      ),
    );
  }
}

class _CategoryScroller extends StatelessWidget {
  final List<PackageModel> packages;
  final ValueChanged<String> onTapCategory;

  const _CategoryScroller({
    required this.packages,
    required this.onTapCategory,
  });

  @override
  Widget build(BuildContext context) {
    final categories = packages.map((e) => e.categoryName).toSet().toList()
      ..sort();

    if (categories.isEmpty) {
      return const _EmptyMiniText(text: 'Kategori belum tersedia.');
    }

    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = categories[index];
          final count = packages
              .where((item) => item.categoryName == category)
              .length;

          return InkWell(
            onTap: () => onTapCategory(category),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              constraints: const BoxConstraints(minWidth: 106),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withOpacity(0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count paket',
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PromoList extends StatelessWidget {
  final List<PackageModel> packages;
  final String Function(double) formatCurrency;
  final ValueChanged<PackageModel> onDetail;

  const _PromoList({
    required this.packages,
    required this.formatCurrency,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: packages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = packages[index];

          return InkWell(
            onTap: () => onDetail(item),
            borderRadius: BorderRadius.circular(26),
            child: Container(
              width: 286,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                color: AppColors.primaryDark,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withOpacity(0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.coverImage.isNotEmpty)
                    Image.network(
                      item.coverImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.80),
                          Colors.black.withOpacity(0.34),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    top: 16,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Today ${item.activeDiscount?.discountPercent ?? 0}% Off',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'PROMO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (item.hasDiscount) ...[
                                    Flexible(
                                      child: Text(
                                        formatCurrency(item.price),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.72),
                                          fontSize: 11,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          decorationColor: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Flexible(
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
                        const SizedBox(width: 12),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PortfolioStrip extends StatelessWidget {
  final List<PackageModel> packages;
  final ValueChanged<PackageModel> onDetail;

  const _PortfolioStrip({required this.packages, required this.onDetail});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 138,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: packages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = packages[index];

          return InkWell(
            onTap: () => onDetail(item),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 138,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: AppColors.primarySoft,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    item.coverImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primarySoft,
                      child: const Icon(
                        Icons.photo_camera_outlined,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.48),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReviewList extends StatelessWidget {
  final List<PublicReviewModel> reviews;

  const _ReviewList({required this.reviews});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: reviews.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = reviews[index];

          return Container(
            width: 260,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(
                    item.rating.clamp(0, 5),
                    (_) => const Icon(
                      Icons.star_rounded,
                      color: AppColors.warning,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.comment,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(height: 1.35),
                ),
                const Spacer(),
                Text(
                  item.clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
        ),
        if (actionText != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionText!)),
      ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
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
