import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'auth_bottom_sheets.dart';

class AuthWelcomeScreen extends StatelessWidget {
  const AuthWelcomeScreen({super.key});

  void _openLogin(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) {
        return AuthLoginBottomSheet(
          onOpenRegister: () {
            Navigator.pop(context);

            Future.delayed(const Duration(milliseconds: 180), () {
              if (context.mounted) {
                _openRegister(context);
              }
            });
          },
        );
      },
    );
  }

  void _openRegister(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) {
        return AuthRegisterBottomSheet(
          onOpenLogin: () {
            Navigator.pop(context);

            Future.delayed(const Duration(milliseconds: 180), () {
              if (context.mounted) {
                _openLogin(context);
              }
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF253E8F),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallHeight = constraints.maxHeight < 720;

          return Stack(
            children: [
              const _AdminBlueBackground(),
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        22,
                        isSmallHeight ? 18 : 24,
                        22,
                        22,
                      ),
                      child: Column(
                        children: [
                          const _TopMiniText(),

                          SizedBox(height: isSmallHeight ? 34 : 48),

                          const _MainLogo(),

                          SizedBox(height: isSmallHeight ? 30 : 46),

                          _BottomWelcomeCard(
                            onLogin: () => _openLogin(context),
                            onRegister: () => _openRegister(context),
                          ),
                        ],
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

class _TopMiniText extends StatelessWidget {
  const _TopMiniText();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            color: Color(0xFFCFEAFF),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Text(
          'MONOFRAME STUDIO',
          style: TextStyle(
            color: Colors.white.withOpacity(0.86),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.2,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.13),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Text(
            'Photo Studio',
            style: TextStyle(
              color: Colors.white.withOpacity(0.90),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _MainLogo extends StatelessWidget {
  const _MainLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/monoframe_logo_full.png',
          width: 272,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            return Column(
              children: const [
                Icon(Icons.camera_alt_rounded, color: Colors.white, size: 96),
                SizedBox(height: 16),
                Text(
                  'MONOFRAME STUDIO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        Text(
          'Capture Your Best Moment',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.78),
            fontSize: 13,
            height: 1.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _BottomWelcomeCard extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const _BottomWelcomeCard({required this.onLogin, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0FAFF), Color(0xFFD9F0FA), Color(0xFFC5E4F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.white.withOpacity(0.65), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D3483).withOpacity(0.28),
            blurRadius: 38,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -54,
            right: -42,
            child: _DecorCircle(size: 150, color: Color(0x3DFFFFFF)),
          ),
          const Positioned(
            bottom: -50,
            left: -52,
            child: _DecorCircle(size: 150, color: Color(0x2EFFFFFF)),
          ),
          Positioned(
            top: 15,
            right: 15,
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome',
                style: TextStyle(
                  color: Color(0xFF17384D),
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Masuk atau buat akun untuk booking sesi foto, melihat portofolio, dan memantau progres hasil foto kamu.',
                style: TextStyle(
                  color: const Color(0xFF17384D).withOpacity(0.72),
                  fontSize: 13,
                  height: 1.55,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 78),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: onLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D3483),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: onRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1D3483),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.64),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.76)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6E9FBD).withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: const Color(0xFF17384D)),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF17384D),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminBlueBackground extends StatelessWidget {
  const _AdminBlueBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF233B93), Color(0xFF344FA5), Color(0xFF5E7BDA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -120,
            child: _BlurCircle(size: 340, color: Color(0x4FDDEFFF)),
          ),
          Positioned(
            top: 155,
            left: -170,
            child: _BlurCircle(size: 330, color: Color(0x336E9FBD)),
          ),
          Positioned(
            bottom: -135,
            right: -70,
            child: _BlurCircle(size: 300, color: Color(0x40A8CBE0)),
          ),
          Positioned(
            bottom: 210,
            left: 44,
            child: _FloatingDot(size: 9, color: Color(0xFFEAF6FB)),
          ),
          Positioned(
            top: 128,
            right: 42,
            child: _FloatingDot(size: 7, color: Color(0xFFCFEAFF)),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _SubtleAdminPatternPainter()),
          ),
        ],
      ),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _BlurCircle({required this.size, required this.color});

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

  const _FloatingDot({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.72),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.24),
            blurRadius: 18,
            spreadRadius: 3,
          ),
        ],
      ),
    );
  }
}

class _SubtleAdminPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.055)
      ..strokeWidth = 1;

    const spacing = 34.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.055)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    for (double y = 160; y < size.height * 0.58; y += 12) {
      final path = Path();
      path.moveTo(-40, y);

      for (double x = -40; x < size.width + 50; x += 24) {
        path.quadraticBezierTo(x + 12, y + 7, x + 24, y);
      }

      canvas.drawPath(path, wavePaint);
    }

    final diagonalPaint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    for (double x = -size.height; x < size.width; x += 52) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        diagonalPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
