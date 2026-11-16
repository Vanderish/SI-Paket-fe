import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'auth/login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _onSelectRole(BuildContext context, String roleEnum) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(initialRole: roleEnum),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(width: 10),
                  const Text(
                    'SI-PAKET',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  
                ],
              ),
              const SizedBox(height: 24),

              // Ilustrasi Hero Card (Gudang -> Paket -> Truk -> Pin Lokasi)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.surfaceGray,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 42,
                      child: SizedBox(
                        width: 210,
                        height: 60,
                        child: CustomPaint(
                          painter: _DashedArcPainter(),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 52,
                      top: 66,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.navyPrimary,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.warehouse_outlined,
                          color: AppColors.navyPrimary,
                          size: 28,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 54,
                      top: 34,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.navyPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.yellowAccent,
                          size: 22,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 88,
                      bottom: 34,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.yellowAccent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.navyPrimary,
                            width: 2.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.inventory_2,
                          color: AppColors.navyPrimary,
                          size: 34,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 68,
                      bottom: 38,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.navyPrimary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.local_shipping,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'Paket terhubung.\nSemua lebih mudah.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Kelola pengiriman dan pantau paket dalam satu genggaman.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'Masuk sebagai',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              // 3 Pilihan Role Cards -> mengarah ke LoginScreen dengan enum backend
              _RoleOptionCard(
                icon: Icons.warehouse_outlined,
                title: 'Admin Pos',
                subtitle: 'Kelola paket & penugasan kurir',
                onTap: () => _onSelectRole(context, 'PetugasGudang'),
              ),
              const SizedBox(height: 12),
              _RoleOptionCard(
                icon: Icons.local_shipping_outlined,
                title: 'Kurir',
                subtitle: 'Antarkan paket, perbarui status',
                onTap: () => _onSelectRole(context, 'Kurir'),
              ),
              const SizedBox(height: 12),
              _RoleOptionCard(
                icon: Icons.person_outline,
                title: 'User/Pelanggan',
                subtitle: 'Lacak & konfirmasi paket Anda',
                onTap: () => _onSelectRole(context, 'User'),
              ),
              const SizedBox(height: 28),

            
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'SI-PAKET',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderLight, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.navyPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.navyPrimary
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.45, -15, size.width, size.height * 0.35);

    const dashWidth = 4.0;
    const dashSpace = 5.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}