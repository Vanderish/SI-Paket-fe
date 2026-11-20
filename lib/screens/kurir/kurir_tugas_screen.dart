import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class KurirTugasScreen extends StatefulWidget {
  const KurirTugasScreen({super.key});

  @override
  State<KurirTugasScreen> createState() => _KurirTugasScreenState();
}

class _KurirTugasScreenState extends State<KurirTugasScreen> {
  bool _isLoading = true;
  bool _isActionLoading = false;
  List<Map<String, dynamic>> _tugasAktif = [];
  String _kurirNama = 'Kurir';

  @override
  void initState() {
    super.initState();
    _loadTugas();
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : AppColors.navyPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadTugas() async {
    setState(() => _isLoading = true);
    try {
      final nama = await ApiService.getNama();
      final raw = await ApiService.getTugasKurir();
      if (!mounted) return;
      setState(() {
        if (nama != null && nama.isNotEmpty) _kurirNama = nama;
        _tugasAktif = raw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((p) {
              final st = (p['statusTerkini'] ?? p['status_terkini'] ?? '')
                  .toString()
                  .toLowerCase();
              return !st.contains('selesai') && !st.contains('terkirim');
            })
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _terimaPaket(String noResi) async {
    setState(() => _isActionLoading = true);
    try {
      await ApiService.kurirTerimaPaket(noResi);
      _showSnack('Paket $noResi berhasil diterima kurir!');
      await _loadTugas();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _dialogUpdateLokasi(String noResi) async {
    final lokasiCtrl = TextEditingController();
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Lokasi ($noResi)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: lokasiCtrl,
          decoration: const InputDecoration(
            hintText: 'Contoh: Jl. Panglima Sudirman, Lamongan',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (konfirmasi != true || lokasiCtrl.text.trim().isEmpty) return;

    setState(() => _isActionLoading = true);
    try {
      await ApiService.kurirUpdateLokasi(
        noResi: noResi,
        lokasiUpdate: lokasiCtrl.text.trim(),
      );
      _showSnack('Lokasi paket $noResi diperbarui!');
      await _loadTugas();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _selesaiAntar(String noResi) async {
    setState(() => _isActionLoading = true);
    try {
      await ApiService.kurirSelesaiAntar(noResi);
      _showSnack('Pengantaran $noResi selesai!');
      await _loadTugas();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadTugas,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OPERASIONAL KURIR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tugas Pengantaran',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Kurir: $_kurirNama',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              IconButton(
                onPressed: _loadTugas,
                icon: const Icon(Icons.refresh, color: AppColors.navyPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Banner Ringkasan
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.navyPrimary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Paket Aktif Hari Ini',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_tugasAktif.length} Paket',
                      style: const TextStyle(
                        color: AppColors.yellowAccent,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.local_shipping,
                    color: AppColors.yellowAccent, size: 36),
              ],
            ),
          ),
          const SizedBox(height: 18),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 50),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.navyPrimary),
              ),
            )
          else if (_tugasAktif.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  'Belum ada tugas pengantaran aktif.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ..._tugasAktif.map((p) => _buildTugasCard(p)),
        ],
      ),
    );
  }

  Widget _buildTugasCard(Map<String, dynamic> p) {
    final resi = (p['noResi'] ?? p['no_resi'] ?? '-').toString();
    final penerima =
        (p['namaPenerima'] ?? p['nama_penerima'] ?? '-').toString();
    final tujuan =
        (p['alamatTujuan'] ?? p['alamat_tujuan'] ?? '-').toString();
    final status =
        (p['statusTerkini'] ?? p['status_terkini'] ?? 'Ditugaskan').toString();
    final isMenunggu = status.toLowerCase().contains('menunggu') ||
        status.toLowerCase().contains('ditugaskan');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceGray,
        borderRadius: BorderRadius.circular(18),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          const SizedBox(height: 8),
          Text(penerima,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 2),
          Text(tujuan,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          if (isMenunggu)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _isActionLoading ? null : () => _terimaPaket(resi),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellowAccent,
                  foregroundColor: AppColors.navyPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Terima Paket dari Gudang',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isActionLoading
                        ? null
                        : () => _dialogUpdateLokasi(resi),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navyPrimary,
                      side: const BorderSide(color: AppColors.navyPrimary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.location_on_outlined, size: 16),
                    label: const Text('Lokasi',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isActionLoading ? null : () => _selesaiAntar(resi),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text('Selesai',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}