import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../role_selection_screen.dart';

class KurirAkunScreen extends StatefulWidget {
  const KurirAkunScreen({super.key});

  @override
  State<KurirAkunScreen> createState() => _KurirAkunScreenState();
}

class _KurirAkunScreenState extends State<KurirAkunScreen> {
  String _nama = 'Kurir SI-PAKET';
  int? _userId;
  bool _tersedia = true;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _loadProfil();
  }

  Future<void> _loadProfil() async {
    final nama = await ApiService.getNama();
    final id = await ApiService.getUserId();
    if (!mounted) return;
    setState(() {
      if (nama != null && nama.isNotEmpty) _nama = nama;
      _userId = id;
    });
  }

  Future<void> _toggleKetersediaan(bool val) async {
    setState(() => _isUpdatingStatus = true);
    try {
      await ApiService.kurirUpdateKetersediaan(val);
      if (!mounted) return;
      setState(() => _tersedia = val);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(val
              ? 'Status diubah menjadi Aktif / Siap Terima Tugas'
              : 'Status diubah menjadi Sibuk / Tidak Tersedia'),
          backgroundColor: AppColors.navyPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
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
            'Akun Kurir',
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
                  child: Icon(Icons.local_shipping,
                      color: AppColors.yellowAccent),
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
                          ? 'ID Kurir: $_userId · Role: Kurir'
                          : 'Role: Kurir',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceGray,
              borderRadius: BorderRadius.circular(18),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.navyPrimary,
              title: const Text(
                'Status Ketersediaan',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              subtitle: Text(
                _tersedia ? 'Aktif menerima tugas baru' : 'Sedang sibuk / off',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              value: _tersedia,
              onChanged: _isUpdatingStatus ? null : _toggleKetersediaan,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Keluar / Logout',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}