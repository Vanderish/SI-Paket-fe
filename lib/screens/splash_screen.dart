import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/animated_components.dart';
import 'admin/admin_home_screen.dart';
import 'kurir/kurir_tugas_screen.dart';
import 'pelanggan/pelanggan_main_screen.dart';
import 'role_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _driveController;
  late final Animation<double> _truckPosition;

  late final AnimationController _roadController;

  @override
  void initState() {
    super.initState();

    // 1. Mobil
    _driveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    _truckPosition = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.35, end: 0.49)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.49, end: 0.51)
            .chain(CurveTween(curve: Curves.linear)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.51, end: 1.35)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 30,
      ),
    ]).animate(_driveController);

    // 2. Animasi roda berputar & marka jalan bergerak
    _roadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat();

    _driveController.forward();

    _driveController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _navigateAfterSplash();
      }
    });
  }

  Future<void> _navigateAfterSplash() async {
    final token = await ApiService.getToken();
    final role = await ApiService.getRole();

    if (!mounted) return;

    Widget nextPage;
    if (token != null && token.isNotEmpty) {
      if (role == 'PetugasGudang') {
        nextPage = const AdminHomeScreen();
      } else if (role == 'Kurir') {
        nextPage = const KurirTugasScreen();
      } else {
        nextPage = const PelangganMainScreen();
      }
    } else {
      nextPage = const RoleSelectionScreen();
    }

    Navigator.pushReplacement(
      context,
      SmoothPageRoute(page: nextPage),
    );
  }

  @override
  void dispose() {
    _driveController.dispose();
    _roadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // si paket
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.navyPrimary,
                  size: 26,
                ),
                const SizedBox(width: 10),
                const Text(
                  'SI-PAKET',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.navyPrimary,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 24,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.yellowAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),

            const Spacer(flex: 1),

            SizedBox(
              height: 150,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: Listenable.merge([_driveController, _roadController]),
                builder: (context, _) {
                  final truckCenterX = screenWidth * _truckPosition.value;
                  final bounceY =
                      math.sin(_roadController.value * math.pi * 2) * 1.5;
                  final wheelAngle = _roadController.value * math.pi * 2;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 24,
                        child: CustomPaint(
                          size: Size(screenWidth, 16),
                          painter: _RoadPainter(
                            progress: _roadController.value,
                          ),
                        ),
                      ),
                      Positioned(
                        left: truckCenterX - 75,
                        bottom: 30 + bounceY,
                        child: CustomPaint(
                          size: const Size(150, 88),
                          painter: _DeliveryBoxTruckPainter(
                            wheelAngle: wheelAngle,
                            windPhase: _roadController.value,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const Spacer(flex: 2),

            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Text(
                'SI-PAKET',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  final double progress;
  _RoadPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final roadLinePaint = Paint()
      ..color = AppColors.borderLight
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(24, 2),
      Offset(size.width - 24, 2),
      roadLinePaint,
    );

    final dashPaint = Paint()
      ..color = AppColors.textMuted.withValues(alpha: 0.5)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    const dashWidth = 18.0;
    const dashSpace = 22.0;
    const totalStep = dashWidth + dashSpace;
    final offset = progress * totalStep;

    double startX = 24 - offset;
    while (startX < size.width - 24) {
      final drawStart = math.max(24.0, startX);
      final drawEnd = math.min(size.width - 24, startX + dashWidth);
      if (drawEnd > drawStart) {
        canvas.drawLine(
          Offset(drawStart, 10),
          Offset(drawEnd, 10),
          dashPaint,
        );
      }
      startX += totalStep;
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _DeliveryBoxTruckPainter extends CustomPainter {
  final double wheelAngle;
  final double windPhase;

  _DeliveryBoxTruckPainter({
    required this.wheelAngle,
    required this.windPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final navyFill = Paint()
      ..color = AppColors.navyPrimary
      ..style = PaintingStyle.fill;

    final yellowFill = Paint()
      ..color = AppColors.yellowAccent
      ..style = PaintingStyle.fill;

    final whiteFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final navyStroke = Paint()
      ..color = AppColors.navyPrimary
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final windPaint = Paint()
      ..color = AppColors.textMuted.withValues(alpha: 0.65)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final shift1 = (windPhase * 10);
    canvas.drawLine(
      Offset(4 - shift1, 28),
      Offset(20 - shift1, 28),
      windPaint,
    );
    canvas.drawLine(
      Offset(0 - (shift1 * 0.7), 42),
      Offset(22 - (shift1 * 0.7), 42),
      windPaint,
    );
    canvas.drawLine(
      Offset(8 - shift1, 56),
      Offset(20 - shift1, 56),
      windPaint,
    );

    final cargoRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(26, 14, 68, 52),
      const Radius.circular(8),
    );
    canvas.drawRRect(cargoRect, yellowFill);
    canvas.drawRRect(cargoRect, navyStroke);

    canvas.drawLine(
      const Offset(26, 30),
      const Offset(94, 30),
      navyStroke,
    );
    final labelRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(36, 40, 22, 14),
      const Radius.circular(3),
    );
    canvas.drawRRect(labelRect, whiteFill);
    canvas.drawRRect(labelRect, navyStroke);

    final cabinPath = Path()
      ..moveTo(94, 26)
      ..lineTo(118, 26)
      ..quadraticBezierTo(125, 26, 128, 33)
      ..lineTo(136, 48)
      ..quadraticBezierTo(138, 52, 138, 56)
      ..lineTo(138, 66)
      ..lineTo(94, 66)
      ..close();
    canvas.drawPath(cabinPath, navyFill);
    canvas.drawPath(cabinPath, navyStroke);

    final windowPath = Path()
      ..moveTo(101, 32)
      ..lineTo(117, 32)
      ..lineTo(125, 46)
      ..lineTo(101, 46)
      ..close();
    canvas.drawPath(windowPath, whiteFill);

    final headlightRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(132, 53, 6, 6),
      const Radius.circular(2),
    );
    canvas.drawRRect(headlightRect, yellowFill);

    _drawWheel(canvas, const Offset(52, 68), 12, wheelAngle);
    _drawWheel(canvas, const Offset(116, 68), 12, wheelAngle);
  }

  void _drawWheel(
      Canvas canvas, Offset center, double radius, double angle) {
    final outerPaint = Paint()
      ..color = AppColors.navyPrimary
      ..style = PaintingStyle.fill;

    final rimPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final spokePaint = Paint()
      ..color = AppColors.navyPrimary
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, outerPaint);
    canvas.drawCircle(center, radius * 0.48, rimPaint);

    final dx = math.cos(angle) * (radius * 0.45);
    final dy = math.sin(angle) * (radius * 0.45);
    canvas.drawLine(
      Offset(center.dx - dx, center.dy - dy),
      Offset(center.dx + dx, center.dy + dy),
      spokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DeliveryBoxTruckPainter oldDelegate) =>
      oldDelegate.wheelAngle != wheelAngle ||
      oldDelegate.windPhase != windPhase;
}