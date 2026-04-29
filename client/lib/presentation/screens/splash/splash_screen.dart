import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/providers/auth_provider.dart';
import '../auth/auth_welcome_screen.dart';
import '../role/role_gate_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _backgroundController;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoSlide;
  late final Animation<double> _logoGlow;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1550),
    );

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();

    _logoOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.00, 0.70, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.00, 0.82, curve: Curves.easeOutBack),
      ),
    );

    _logoSlide = Tween<double>(begin: 36, end: 0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.00, 0.74, curve: Curves.easeOutCubic),
      ),
    );

    _logoGlow = Tween<double>(begin: 0.18, end: 0.42).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.20, 1.00, curve: Curves.easeOut),
      ),
    );

    _introController.forward();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(milliseconds: 2300));

    if (!mounted) return;

    await context.read<AuthProvider>().checkSession();

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650),
        reverseTransitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) {
          return authProvider.isLoggedIn
              ? const RoleGateScreen()
              : const AuthWelcomeScreen();
        },
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: Transform.scale(
              scale: 0.985 + (0.015 * curved.value),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _introController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101B4D),
      body: AnimatedBuilder(
        animation: Listenable.merge([_introController, _backgroundController]),
        builder: (context, _) {
          return Stack(
            children: [
              _SplashPremiumBackground(
                animationValue: _backgroundController.value,
              ),

              SafeArea(
                child: Center(
                  child: Transform.translate(
                    offset: Offset(0, _logoSlide.value),
                    child: Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: _LogoOnlyStage(
                          glowOpacity: _logoGlow.value,
                          animationValue: _backgroundController.value,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LogoOnlyStage extends StatelessWidget {
  final double glowOpacity;
  final double animationValue;

  const _LogoOnlyStage({
    required this.glowOpacity,
    required this.animationValue,
  });

  @override
  Widget build(BuildContext context) {
    final pulse = 1.0 + (math.sin(animationValue * math.pi * 2) * 0.018);

    return Transform.scale(
      scale: pulse,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFFFFFF).withOpacity(glowOpacity * 0.34),
                  const Color(0xFFCFEAFF).withOpacity(glowOpacity * 0.26),
                  const Color(0xFF6E9FBD).withOpacity(glowOpacity * 0.18),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.30, 0.58, 1.0],
              ),
            ),
          ),

          Container(
            width: 290,
            height: 290,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1.2,
              ),
            ),
          ),

          Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.055),
                width: 1,
              ),
            ),
          ),

          Image.asset(
            'assets/images/monoframe_logo_full.png',
            width: 310,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) {
              return const _FallbackLogo();
            },
          ),
        ],
      ),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.camera_alt_rounded, color: Colors.white, size: 106),
        SizedBox(height: 18),
        Text(
          'MONOFRAME STUDIO',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

class _SplashPremiumBackground extends StatelessWidget {
  final double animationValue;

  const _SplashPremiumBackground({required this.animationValue});

  @override
  Widget build(BuildContext context) {
    final drift = math.sin(animationValue * math.pi * 2);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF17246D),
            Color(0xFF263F9A),
            Color(0xFF3E61C6),
            Color(0xFF6E9FBD),
          ],
          stops: [0.0, 0.38, 0.74, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -150 + (drift * 10),
            right: -115,
            child: _GlowCircle(
              size: 340,
              color: const Color(0xFFDDEFFF).withOpacity(0.30),
            ),
          ),

          Positioned(
            left: -165,
            top: 175 - (drift * 8),
            child: _GlowCircle(
              size: 330,
              color: const Color(0xFF8FB6FF).withOpacity(0.18),
            ),
          ),

          Positioned(
            bottom: -135,
            right: -80 + (drift * 8),
            child: _GlowCircle(
              size: 320,
              color: const Color(0xFFA8CBE0).withOpacity(0.24),
            ),
          ),

          Positioned(
            top: 125,
            right: 42,
            child: _FloatingDot(
              size: 8,
              color: const Color(0xFFCFEAFF),
              opacity: 0.72,
            ),
          ),

          Positioned(
            bottom: 168,
            left: 44,
            child: _FloatingDot(
              size: 10,
              color: const Color(0xFFEAF6FB),
              opacity: 0.62,
            ),
          ),

          Positioned(
            top: 250,
            left: 82,
            child: _FloatingDot(size: 5, color: Colors.white, opacity: 0.42),
          ),

          Positioned.fill(
            child: CustomPaint(painter: _PremiumGridPainter(animationValue)),
          ),

          Positioned.fill(
            child: CustomPaint(painter: _SoftParticlePainter(animationValue)),
          ),

          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.95,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _FloatingDot extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _FloatingDot({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(opacity * 0.40),
            blurRadius: 18,
            spreadRadius: 3,
          ),
        ],
      ),
    );
  }
}

class _PremiumGridPainter extends CustomPainter {
  final double animationValue;

  const _PremiumGridPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.050)
      ..strokeWidth = 1;

    const spacing = 34.0;
    final offset = animationValue * spacing;

    for (double x = -spacing + offset; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = -spacing + offset; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.060)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    for (double y = 145; y < size.height * 0.60; y += 13) {
      final path = Path();
      path.moveTo(-50, y);

      for (double x = -50; x < size.width + 60; x += 24) {
        path.quadraticBezierTo(
          x + 12,
          y + 7 + math.sin((animationValue * math.pi * 2) + x * 0.02) * 1.8,
          x + 24,
          y,
        );
      }

      canvas.drawPath(path, wavePaint);
    }

    final diagonalPaint = Paint()
      ..color = Colors.white.withOpacity(0.022)
      ..strokeWidth = 1;

    for (double x = -size.height; x < size.width; x += 54) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        diagonalPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PremiumGridPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class _SoftParticlePainter extends CustomPainter {
  final double animationValue;

  const _SoftParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final particles = <_Particle>[
      _Particle(0.16, 0.20, 3.5, 0.00),
      _Particle(0.78, 0.18, 2.4, 0.22),
      _Particle(0.70, 0.36, 4.2, 0.45),
      _Particle(0.18, 0.58, 2.6, 0.67),
      _Particle(0.87, 0.64, 3.0, 0.31),
      _Particle(0.28, 0.80, 4.0, 0.75),
      _Particle(0.70, 0.86, 2.8, 0.12),
    ];

    for (final particle in particles) {
      final floating =
          math.sin((animationValue + particle.phase) * math.pi * 2) * 9;

      final opacity =
          0.20 +
          (math.sin((animationValue + particle.phase) * math.pi * 2) + 1) *
              0.10;

      final paint = Paint()
        ..color = const Color(0xFFEAF6FB).withOpacity(opacity);

      canvas.drawCircle(
        Offset(size.width * particle.dx, size.height * particle.dy + floating),
        particle.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SoftParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class _Particle {
  final double dx;
  final double dy;
  final double radius;
  final double phase;

  const _Particle(this.dx, this.dy, this.radius, this.phase);
}
