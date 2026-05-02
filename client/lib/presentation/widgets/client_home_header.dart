import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/app_setting_model.dart';
import 'monoframe_logo_mark.dart';

class ClientHomeHeader extends StatelessWidget {
  final AppSettingModel setting;
  final String clientName;
  final int unreadNotificationCount;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onBookingPressed;
  final VoidCallback? onSupportPressed;

  const ClientHomeHeader({
    super.key,
    required this.setting,
    required this.clientName,
    required this.unreadNotificationCount,
    this.onNotificationPressed,
    this.onBookingPressed,
    this.onSupportPressed,
  });

  @override
  Widget build(BuildContext context) {
    final studio = setting.studio;
    final home = setting.clientHome;

    final studioName = studio.name.trim().isNotEmpty
        ? studio.name.trim()
        : 'Monoframe Studio';

    final homeTitle = home.title.trim().isNotEmpty
        ? home.title.trim()
        : 'Abadikan momen terbaik bersama Monoframe Studio';

    final homeSubtitle = home.subtitle.trim().isNotEmpty
        ? home.subtitle.trim()
        : 'Pilih paket foto, tentukan jadwal, lakukan pembayaran, dan pantau progres hasil foto langsung dari aplikasi.';

    final ctaText = home.ctaText.trim().isNotEmpty
        ? home.ctaText.trim()
        : 'Booking';

    final showSupportButton = onSupportPressed != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: AppColors.welcomeDarkGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.welcomeBlueDark.withOpacity(0.24),
            blurRadius: 26,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -58,
            right: -46,
            child: _HeaderCircle(
              size: 164,
              color: Colors.white.withOpacity(0.13),
            ),
          ),
          Positioned(
            bottom: -72,
            left: -62,
            child: _HeaderCircle(
              size: 176,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Positioned(
            top: 94,
            right: 28,
            child: _HeaderCircle(
              size: 8,
              color: Colors.white.withOpacity(0.30),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StudioLogo(logoUrl: studio.logoUrl),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studioName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            height: 1.12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'Halo, $clientName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.84),
                            fontSize: 13.5,
                            height: 1.18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _NotificationButton(
                    unreadNotificationCount: unreadNotificationCount,
                    onPressed: onNotificationPressed,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Text(
                homeTitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  height: 1.22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                homeSubtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.86),
                  fontSize: 14.2,
                  height: 1.55,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: _HeaderActionButton(
                      icon: Icons.calendar_month_rounded,
                      label: ctaText,
                      onTap: onBookingPressed,
                    ),
                  ),
                  if (showSupportButton) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HeaderActionButton(
                        icon: Icons.support_agent_rounded,
                        label: 'Call Center',
                        onTap: onSupportPressed,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudioLogo extends StatelessWidget {
  final String logoUrl;

  const _StudioLogo({required this.logoUrl});

  @override
  Widget build(BuildContext context) {
    final cleanUrl = logoUrl.trim();

    if (cleanUrl.isEmpty) {
      return const MonoframeLogoMark(size: 56);
    }

    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        cleanUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const MonoframeLogoMark(size: 40),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;

          return const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final int unreadNotificationCount;
  final VoidCallback? onPressed;

  const _NotificationButton({
    required this.unreadNotificationCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.16),
            foregroundColor: Colors.white,
            fixedSize: const Size(52, 52),
          ),
          icon: const Icon(Icons.notifications_none_rounded, size: 29),
        ),
        if (unreadNotificationCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1.7),
              ),
              alignment: Alignment.center,
              child: Text(
                unreadNotificationCount > 99
                    ? '99+'
                    : unreadNotificationCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeaderCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _HeaderCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _HeaderActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.white.withOpacity(0.45),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.welcomeBlueDark.withOpacity(0.13),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 23, color: AppColors.welcomeBlueDark),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.welcomeBlueDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
