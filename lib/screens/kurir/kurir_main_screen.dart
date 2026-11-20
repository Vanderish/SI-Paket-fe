import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'kurir_akun_screen.dart';
import 'kurir_riwayat_screen.dart';
import 'kurir_tugas_screen.dart';

class KurirMainScreen extends StatefulWidget {
  const KurirMainScreen({super.key});

  @override
  State<KurirMainScreen> createState() => _KurirMainScreenState();
}

class _KurirMainScreenState extends State<KurirMainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [
      KurirTugasScreen(),
      KurirRiwayatScreen(),
      KurirAkunScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.navyPrimary,
        unselectedItemColor: AppColors.textMuted,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            label: 'Tugas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}