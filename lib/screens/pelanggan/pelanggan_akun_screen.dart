import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../role_selection_screen.dart';

class PelangganAkunScreen extends StatefulWidget {
  const PelangganAkunScreen({super.key});

  @override
  State<PelangganAkunScreen> createState() => _PelangganAkunScreenState();
}

class _PelangganAkunScreenState extends State<PelangganAkunScreen> {
  String _nama = 'Tamu (Belum Login)';
  int? _userId;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final token = await ApiService.getToken();
    final nama = await ApiService.getNama();
    final id = await ApiService.getUserId();
    if (!mounted) return;
    setState(() {
      _isLoggedIn = token != null && token.isNotEmpty;
      if (nama != null && nama.isNotEmpty) _nama = nama;
      _userId = id;
    });
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Akun Pelanggan',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceGray,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.navyPrimary,
                  child: Icon(Icons.person, color: AppColors.yellowAccent),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nama,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Text(
                      _userId != null
                          ? 'ID Pelanggan: $_userId · Role: User'
                          : 'Mode Lacak Publik',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isLoggedIn ? Colors.red.shade700 : AppColors.navyPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(_isLoggedIn ? Icons.logout : Icons.login),
              label: Text(
                _isLoggedIn ? 'Keluar / Logout' : 'Masuk ke Akun',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}