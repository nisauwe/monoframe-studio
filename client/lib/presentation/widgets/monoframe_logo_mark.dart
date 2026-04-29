import 'package:flutter/material.dart';

class MonoframeLogoMark extends StatelessWidget {
  final double size;
  final bool withBackground;

  const MonoframeLogoMark({
    super.key,
    this.size = 90,
    this.withBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/images/monoframe_logo.png',
      width: size * 0.72,
      height: size * 0.72,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return Icon(
          Icons.camera_alt_rounded,
          size: size * 0.42,
          color: Colors.white,
        );
      },
    );

    if (!withBackground) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(child: logo),
      );
    }

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.20),
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(color: Colors.white.withOpacity(0.24), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E5873).withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: logo,
    );
  }
}
