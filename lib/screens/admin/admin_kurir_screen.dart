import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminKurirScreen extends StatefulWidget {
  const AdminKurirScreen({super.key});

  @override
  State<AdminKurirScreen> createState() => _AdminKurirScreenState();
}

class _AdminKurirScreenState extends State<AdminKurirScreen> {
  bool _isLoading = true;
  bool _hanyaTersedia = false;
  List<Map<String, dynamic>> _daftarKurir = [];

  @override
  void initState() {
    super.initState();
    _fetchKurir();
  }

  Future<void> _fetchKurir() async {
    setState(() => _isLoading = true);
    try {
      final raw = await ApiService.getDaftarKurir(
        tersedia: _hanyaTersedia ? true : null,
      );
      if (!mounted) return;
      setState(() {
        _daftarKurir = raw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchKurir,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daftar Kurir',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              IconButton(
                onPressed: _fetchKurir,
                icon: const Icon(Icons.refresh, color: AppColors.navyPrimary),
              ),
            ],
          ),
          Text(
            'Total ${_daftarKurir.length} kurir terdaftar',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          // Filter Ketersediaan Kurir
          Row(
            children: [
              ChoiceChip(
                label: const Text('Semua Kurir', style: TextStyle(fontSize: 12)),
                selected: !_hanyaTersedia,
                onSelected: (_) {
                  setState(() => _hanyaTersedia = false);
                  _fetchKurir();
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Aktif / Tersedia', style: TextStyle(fontSize: 12)),
                selected: _hanyaTersedia,
                onSelected: (_) {
                  setState(() => _hanyaTersedia = true);
                  _fetchKurir();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.navyPrimary),
              ),
            )
          else if (_daftarKurir.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  'Belum ada data kurir terdaftar.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ..._daftarKurir.map((k) {
              final nama = (k['namaLengkap'] ?? k['nama_lengkap'] ?? 'Kurir').toString();
              final plat = (k['platKendaraan'] ?? k['plat_kendaraan'] ?? '-').toString();
              final idKurir = (k['idPengguna'] ?? k['id_pengguna'] ?? '-').toString();
              final statusRaw = k['statusKetersediaan'] ?? k['status_ketersediaan'];
              final tersedia = statusRaw == true || statusRaw == 1;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGray,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$nama (ID: $idKurir)',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Plat: $plat',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: tersedia
                            ? AppColors.badgeGreenBg
                            : AppColors.yellowSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tersedia ? 'Aktif' : 'Sibuk',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: tersedia
                              ? AppColors.badgeGreenText
                              : AppColors.yellowText,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}