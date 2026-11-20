import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'pelanggan_akun_screen.dart';
import 'pelanggan_lacak_screen.dart';
import 'pelanggan_paket_screen.dart';

class PelangganMainScreen extends StatefulWidget {
  const PelangganMainScreen({super.key});

  @override
  State<PelangganMainScreen> createState() => _PelangganMainScreenState();
}

class _PelangganMainScreenState extends State<PelangganMainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const PelangganLacakScreen(),
      const PelangganPaketScreen(),
      const PelangganAkunScreen(),
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
            icon: Icon(Icons.search),
            label: 'Lacak',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Paket Saya',
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