import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class PelangganPaketScreen extends StatefulWidget {
  const PelangganPaketScreen({super.key});

  @override
  State<PelangganPaketScreen> createState() => _PelangganPaketScreenState();
}

class _PelangganPaketScreenState extends State<PelangganPaketScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _paketSaya = [];
  String _selectedStatus = '';

  @override
  void initState() {
    super.initState();
    _fetchPaketSaya();
  }

  Future<void> _fetchPaketSaya() async {
    setState(() => _isLoading = true);
    try {
      final raw = await ApiService.getPaketSaya(
        status: _selectedStatus.isEmpty ? null : _selectedStatus,
      );
      if (!mounted) return;
      setState(() {
        _paketSaya =
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

  Future<void> _lihatDetail(String noResi) async {
    try {
      final raw = await ApiService.getDetailPaket(noResi);
      final data = (raw['data'] is Map<String, dynamic>)
          ? raw['data'] as Map<String, dynamic>
          : raw;
      final riwayat = (data['riwayat'] ??
              data['riwayatPelacakan'] ??
              data['riwayat_pelacakan'] ??
              []) as List<dynamic>;

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detail Resi: $noResi',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                  'Penerima: ${data['namaPenerima'] ?? data['nama_penerima'] ?? '-'}'),
              Text(
                  'Asal: ${data['alamatAsal'] ?? data['alamat_asal'] ?? '-'}'),
              Text(
                  'Tujuan: ${data['alamatTujuan'] ?? data['alamat_tujuan'] ?? '-'}'),
              Text(
                  'Layanan: ${data['jenisPaket'] ?? data['jenis_paket'] ?? '-'}'),
              Text(
                  'Status: ${data['statusTerkini'] ?? data['status_terkini'] ?? '-'}'),
              if (riwayat.isNotEmpty) ...[
                const Divider(height: 22),
                const Text(
                  'Riwayat Pelacakan',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...riwayat.map((r) {
                  final item = Map<String, dynamic>.from(r as Map);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.circle,
                            size: 9, color: AppColors.navyPrimary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (item['lokasiUpdate'] ??
                                        item['lokasi_update'] ??
                                        '-')
                                    .toString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              Text(
                                (item['deskripsiStatus'] ??
                                        item['deskripsi_status'] ??
                                        '-')
                                    .toString(),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 16),
            ],
          ),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchPaketSaya,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Paket Saya',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              IconButton(
                onPressed: _fetchPaketSaya,
                icon: const Icon(Icons.refresh, color: AppColors.navyPrimary),
              ),
            ],
          ),
          Text(
            'Total ${_paketSaya.length} riwayat pengiriman',
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Semua', ''),
                const SizedBox(width: 8),
                _filterChip('Menunggu', 'Menunggu Penjemputan'),
                const SizedBox(width: 8),
                _filterChip('Perjalanan', 'Dalam Perjalanan'),
                const SizedBox(width: 8),
                _filterChip('Selesai', 'Selesai'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.navyPrimary),
              ),
            )
          else if (_paketSaya.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  'Belum ada paket pada daftar ini.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ..._paketSaya.map((p) {
              final resi = (p['noResi'] ?? p['no_resi'] ?? '-').toString();
              final penerima =
                  (p['namaPenerima'] ?? p['nama_penerima'] ?? '-').toString();
              final tujuan =
                  (p['alamatTujuan'] ?? p['alamat_tujuan'] ?? '-').toString();
              final status = (p['statusTerkini'] ??
                      p['status_terkini'] ??
                      'Menunggu Penjemputan')
                  .toString();

              return GestureDetector(
                onTap: () => _lihatDetail(resi),
                child: Container(
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
                          Text(
                            resi,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.badgeBlueBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.badgeBlueText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Penerima: $penerima',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      Text(
                        tujuan,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String val) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: _selectedStatus == val,
      onSelected: (_) {
        setState(() => _selectedStatus = val);
        _fetchPaketSaya();
      },
    );
  }
}