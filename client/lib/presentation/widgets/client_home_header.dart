import 'package:flutter/material.dart';

import '../../data/models/app_setting_model.dart';

class ClientHomeHeader extends StatelessWidget {
  final AppSettingModel setting;
  final VoidCallback? onBookingPressed;
  final VoidCallback? onSupportPressed;

  const ClientHomeHeader({
    super.key,
    required this.setting,
    this.onBookingPressed,
    this.onSupportPressed,
  });

  @override
  Widget build(BuildContext context) {
    final studio = setting.studio;
    final home = setting.clientHome;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF344FA5), Color(0xFF8A84FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF344FA5).withOpacity(0.20),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StudioLogo(url: studio.logoUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studio.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (studio.tagline.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        studio.tagline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.78),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (home.bannerUrl.isNotEmpty) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  home.bannerUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.white.withOpacity(0.12),
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            home.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1.18,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (home.subtitle.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              home.subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.86),
                fontSize: 13,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: setting.booking.isActive ? onBookingPressed : null,
                icon: const Icon(Icons.calendar_month_rounded, size: 18),
                label: Text(home.ctaText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF344FA5),
                  disabledBackgroundColor: Colors.white.withOpacity(0.50),
                  disabledForegroundColor: const Color(0xFF344FA5).withOpacity(0.50),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              if (home.showSupportContact)
                OutlinedButton.icon(
                  onPressed: onSupportPressed,
                  icon: const Icon(Icons.support_agent_rounded, size: 18),
                  label: const Text('Bantuan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.55)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
                borderRadius: BorderRadius.circular(14),
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

class _StudioLogo extends StatelessWidget {
  final String url;

  const _StudioLogo({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return _FallbackLogo();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        url,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _FallbackLogo(),
      ),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.camera_alt_rounded,
        color: Colors.white,
      ),
    );
  }
}