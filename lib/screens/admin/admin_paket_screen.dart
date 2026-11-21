import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class AdminPaketScreen extends StatefulWidget {
  const AdminPaketScreen({super.key});

  @override
  State<AdminPaketScreen> createState() => _AdminPaketScreenState();
}

class _AdminPaketScreenState extends State<AdminPaketScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _daftarPaket = [];
  String _selectedStatus = ''; // '' = Semua (tanpa query ?status)

  @override
  void initState() {
    super.initState();
    _fetchPaket();
  }

  Future<void> _fetchPaket() async {
    setState(() => _isLoading = true);
    try {
      // Memanggil GET /api/gudang/paket atau GET /api/gudang/paket?status=<status_terkini>
      final raw = await ApiService.getGudangPaket(
        status: _selectedStatus.isEmpty ? null : _selectedStatus,
      );
      if (!mounted) return;
      setState(() {
        _daftarPaket = raw
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
      onRefresh: _fetchPaket,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Semua Daftar Paket',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              IconButton(
                onPressed: _fetchPaket,
                icon: const Icon(Icons.refresh, color: AppColors.navyPrimary),
              ),
            ],
          ),
          Text(
            'Total ${_daftarPaket.length} paket di database',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          // Filter Status -> mengirim ?status=status_terkini ke /api/paket/saya
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Semua', ''),
                const SizedBox(width: 8),
                _buildFilterChip('Menunggu', 'Menunggu Penjemputan'),
                const SizedBox(width: 8),
                _buildFilterChip('Perjalanan', 'Dalam Perjalanan'),
                const SizedBox(width: 8),
                _buildFilterChip('Selesai', 'Selesai'),
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
          else if (_daftarPaket.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  'Belum ada data paket pada filter ini.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ..._daftarPaket.map((paket) => _buildPaketCard(paket)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String statusValue) {
    final selected = _selectedStatus == statusValue;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) {
        setState(() => _selectedStatus = statusValue);
        _fetchPaket();
      },
    );
  }

  Widget _buildPaketCard(Map<String, dynamic> paket) {
    final resi = (paket['noResi'] ?? paket['no_resi'] ?? '-').toString();
    final penerima =
        (paket['namaPenerima'] ?? paket['nama_penerima'] ?? '-').toString();
    final tujuan =
        (paket['alamatTujuan'] ?? paket['alamat_tujuan'] ?? '-').toString();
    final jenis =
        (paket['jenisPaket'] ?? paket['jenis_paket'] ?? 'Reguler').toString();
    final status = (paket['statusTerkini'] ??
            paket['status_terkini'] ??
            'Menunggu Penjemputan')
        .toString();

    final isPerjalanan = status.toLowerCase().contains('perjalanan') ||
        status.toLowerCase().contains('antar');

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
            children: [
              const Icon(Icons.inventory_2_outlined,
                  size: 16, color: AppColors.navyPrimary),
              const SizedBox(width: 6),
              Text(
                resi,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            penerima,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  tujuan,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                jenis,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isPerjalanan ? AppColors.badgeBlueBg : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isPerjalanan
                    ? AppColors.badgeBlueText
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}