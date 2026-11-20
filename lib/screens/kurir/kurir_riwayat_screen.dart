import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class KurirRiwayatScreen extends StatefulWidget {
  const KurirRiwayatScreen({super.key});

  @override
  State<KurirRiwayatScreen> createState() => _KurirRiwayatScreenState();
}

class _KurirRiwayatScreenState extends State<KurirRiwayatScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _riwayatSelesai = [];

  @override
  void initState() {
    super.initState();
    _fetchRiwayat();
  }

  Future<void> _fetchRiwayat() async {
    setState(() => _isLoading = true);
    try {
      final raw = await ApiService.getTugasKurir(status: 'Selesai');
      if (!mounted) return;
      setState(() {
        _riwayatSelesai =
            raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchRiwayat,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Riwayat Pengantaran',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              IconButton(
                onPressed: _fetchRiwayat,
                icon: const Icon(Icons.refresh, color: AppColors.navyPrimary),
              ),
            ],
          ),
          Text(
            'Total ${_riwayatSelesai.length} paket telah selesai diantar',
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.navyPrimary),
              ),
            )
          else if (_riwayatSelesai.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  'Belum ada riwayat paket selesai.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ..._riwayatSelesai.map((p) {
              final resi = (p['noResi'] ?? p['no_resi'] ?? '-').toString();
              final penerima =
                  (p['namaPenerima'] ?? p['nama_penerima'] ?? '-').toString();
              final tujuan =
                  (p['alamatTujuan'] ?? p['alamat_tujuan'] ?? '-').toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGray,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(resi,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.badgeGreenBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Selesai',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.badgeGreenText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Penerima: $penerima',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(
                      tujuan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
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