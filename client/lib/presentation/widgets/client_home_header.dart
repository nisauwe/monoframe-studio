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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: AppColors.darkBrandGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MonoframeLogoMark(size: 48),
              const SizedBox(width: 12),
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
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Halo, $clientName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: onNotificationPressed,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.15),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                  if (unreadNotificationCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          unreadNotificationCount > 99
                              ? '99+'
                              : unreadNotificationCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            home.title.isNotEmpty
                ? home.title
                : 'Abadikan momen terbaik bersama Monoframe Studio',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              height: 1.16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            home.subtitle.isNotEmpty
                ? home.subtitle
                : 'Pilih paket foto, tentukan jadwal, lakukan pembayaran, dan pantau progres hasil foto langsung dari aplikasi.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 12.8,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeaderActionButton(
                  icon: Icons.calendar_month_rounded,
                  label: 'Booking',
                  onTap: onBookingPressed,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeaderActionButton(
                  icon: Icons.support_agent_rounded,
                  label: 'Call Center',
                  onTap: onSupportPressed,
                ),
              ),
            ],
          ),
        ],
      ),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.white.withOpacity(0.45),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.primaryDark),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
