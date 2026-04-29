import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/app_setting_model.dart';
import 'monoframe_logo_mark.dart';

class ClientHomeHeader extends StatelessWidget {
  final AppSettingModel setting;
  final String username;
  final VoidCallback? onBookingPressed;
  final VoidCallback? onSupportPressed;

  const ClientHomeHeader({
    super.key,
    required this.setting,
    required this.username,
    this.onBookingPressed,
    this.onSupportPressed,
  });

  @override
  Widget build(BuildContext context) {
    final studio = setting.studio;
    final home = setting.clientHome;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: AppColors.darkBrandGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.25),
            blurRadius: 26,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MonoframeLogoMark(size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studio.name.isNotEmpty ? studio.name : 'Monoframe Studio',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hi, $username',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.76),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (home.showSupportContact)
                IconButton(
                  onPressed: onSupportPressed,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.14),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.support_agent_rounded),
                ),
            ],
          ),
          if (home.bannerUrl.isNotEmpty) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  home.bannerUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
          Text(
            home.title.isNotEmpty
                ? home.title
                : 'Studio foto modern untuk momen terbaikmu',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              height: 1.12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            home.subtitle.isNotEmpty
                ? home.subtitle
                : 'Pilih paket, lihat portofolio, booking jadwal, dan pantau hasil foto langsung dari aplikasi.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 13.5,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: setting.booking.isActive ? onBookingPressed : null,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: Text(
                    home.ctaText.isNotEmpty ? home.ctaText : 'Lihat Paket',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                    disabledBackgroundColor: Colors.white.withOpacity(0.50),
                    disabledForegroundColor: AppColors.primaryDark.withOpacity(
                      0.45,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!setting.booking.isActive &&
              setting.booking.closedMessage.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                setting.booking.closedMessage,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.90),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
