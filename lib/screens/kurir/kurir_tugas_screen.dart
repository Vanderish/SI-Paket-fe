import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/animated_components.dart';
import '../role_selection_screen.dart';

class KurirTugasScreen extends StatefulWidget {
  const KurirTugasScreen({super.key});

  @override
  State<KurirTugasScreen> createState() => _KurirTugasScreenState();
}

class _KurirTugasScreenState extends State<KurirTugasScreen> {
  bool _showAktif = true;
  int _bottomIndex = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isTersedia = true;

  String _kurirNama = 'Andi Pratama';
  List<Map<String, dynamic>> _daftarTugas = [];

  @override
  void initState() {
    super.initState();
    _loadTugas();
  }

  Future<void> _loadTugas() async {
    setState(() => _isLoading = true);
    try {
      final nama = await ApiService.getNama();
      final tugasRaw = await ApiService.getTugasKurir();
      final tugasList = tugasRaw
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      if (!mounted) return;
      setState(() {
        _kurirNama = nama ?? 'Andi Pratama';
        _daftarTugas = tugasList;
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  Future<void> _toggleKetersediaan() async {
    final target = !_isTersedia;
    setState(() => _isSubmitting = true);
    try {
      await ApiService.kurirUpdateKetersediaan(target);
      if (!mounted) return;
      setState(() => _isTersedia = target);
      _showSnack(
        target
            ? 'Status diubah menjadi Aktif'
            : 'Status diubah menjadi Istirahat',
      );
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _terimaTugas(String noResi) async {
    setState(() => _isSubmitting = true);
    try {
      await ApiService.kurirTerimaPaket(noResi);
      _showSnack('Tugas $noResi diterima! Status: Dalam Perjalanan.');
      await _loadTugas();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _updateLokasiDialog(String noResi) async {
    final lokasiCtrl = TextEditingController(text: 'Keputih, Surabaya');
    final ketCtrl =
        TextEditingController(text: 'Kurir sedang menuju alamat penerima');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Perbarui Lokasi Pengiriman',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: lokasiCtrl,
              decoration: const InputDecoration(labelText: 'Lokasi saat ini'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ketCtrl,
              decoration: const InputDecoration(labelText: 'Keterangan'),
            ),
          ],
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
            child: const Text('Kirim Lokasi'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      await ApiService.kurirUpdateLokasi(
        noResi: noResi,
        lokasiUpdate: lokasiCtrl.text.trim(),
        deskripsiStatus: ketCtrl.text.trim(),
      );
      _showSnack('Titik lokasi pengiriman berhasil diperbarui!');
      await _loadTugas();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _selesaiAntar(String noResi) async {
    setState(() => _isSubmitting = true);
    try {
      await ApiService.kurirSelesaiAntar(noResi);
      _showSnack('Paket $noResi ditandai telah sampai tujuan!');
      await _loadTugas();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      SmoothPageRoute(page: const RoleSelectionScreen()),
      (route) => false,
    );
  }

  bool _isStatusSelesai(String status) {
    final s = status.toLowerCase();
    return s.contains('selesai') || s.contains('diterima');
  }

  @override
  Widget build(BuildContext context) {
    final aktifList = _daftarTugas
        .where((p) => !_isStatusSelesai((p['statusTerkini'] ?? '').toString()))
        .toList();
    final selesaiList = _daftarTugas
        .where((p) => _isStatusSelesai((p['statusTerkini'] ?? '').toString()))
        .toList();

    final displayed = _showAktif ? aktifList : selesaiList;
    final totalSemua = _daftarTugas.isEmpty ? 1 : _daftarTugas.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.navyPrimary),
              )
            : _bottomIndex == 2
                ? _buildAkunTab()
                : RefreshIndicator(
                    onRefresh: _loadTugas,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'KURIR / ${_kurirNama.toUpperCase()}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Siap mengantar?',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              BouncyTap(
                                onTap:
                                    _isSubmitting ? null : _toggleKetersediaan,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _isTersedia
                                        ? AppColors.badgeGreenBg
                                        : AppColors.yellowSoft,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        size: 8,
                                        color: _isTersedia
                                            ? AppColors.badgeGreenText
                                            : AppColors.yellowText,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _isTersedia ? 'Aktif' : 'Off',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _isTersedia
                                              ? AppColors.badgeGreenText
                                              : AppColors.yellowText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          FadeSlideIn(
                            delayMs: 60,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.navyPrimary,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${selesaiList.length} / ${_daftarTugas.length}',
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.yellowAccent,
                                        ),
                                      ),
                                      const Text(
                                        'paket terkirim\nhari ini',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: selesaiList.length / totalSemua,
                                      minHeight: 6,
                                      backgroundColor: Colors.white24,
                                      valueColor: const AlwaysStoppedAnimation(
                                          AppColors.yellowAccent),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${aktifList.length} pengiriman tersisa',
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12),
                                      ),
                                      const Icon(Icons.local_shipping_outlined,
                                          color: AppColors.yellowAccent,
                                          size: 18),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _TabButton(
                                  label: 'Aktif (${aktifList.length})',
                                  isSelected: _showAktif,
                                  onTap: () =>
                                      setState(() => _showAktif = true),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _TabButton(
                                  label: 'Selesai (${selesaiList.length})',
                                  isSelected: !_showAktif,
                                  onTap: () =>
                                      setState(() => _showAktif = false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (displayed.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: Text(
                                  'Tidak ada daftar tugas pada kategori ini.',
                                  style:
                                      TextStyle(color: AppColors.textSecondary),
                                ),
                              ),
                            )
                          else
                            ...displayed.asMap().entries.map(
                                  (entry) => FadeSlideIn(
                                    delayMs: 80 + (entry.key * 70),
                                    child: _buildTaskCard(entry.value),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomIndex,
        onTap: (i) {
          setState(() {
            _bottomIndex = i;
            if (i == 0) _showAktif = true;
            if (i == 1) _showAktif = false;
          });
        },
        selectedItemColor: AppColors.navyPrimary,
        unselectedItemColor: AppColors.textMuted,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined), label: 'Tugas'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Akun'),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> paket) {
    final noResi = (paket['noResi'] ?? '-').toString();
    final penerima = (paket['namaPenerima'] ?? '-').toString();
    final alamat = (paket['alamatTujuan'] ?? '-').toString();
    final jenis = (paket['jenisPaket'] ?? 'Reguler').toString();
    final berat = (paket['beratKg'] ?? '1').toString();
    final status =
        (paket['statusTerkini'] ?? 'Menunggu Penjemputan').toString();
    final statusLower = status.toLowerCase();

    final isBaru =
        statusLower.contains('menunggu') || statusLower.contains('proses');
    final isPerjalanan = statusLower.contains('perjalanan') ||
        statusLower.contains('antar') ||
        statusLower.contains('dikirim');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceGray,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBaru)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TUGAS BARU',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '$jenis · $berat kg',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            )
          else if (isPerjalanan)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.badgeGreenBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.badgeGreenText,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Text(
            penerima,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$noResi · $jenis · $berat kg',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  alamat,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isBaru)
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : () => _terimaTugas(noResi),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellowAccent,
                  foregroundColor: AppColors.navyPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Terima Tugas',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            )
          else if (isPerjalanan) ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed:
                    _isSubmitting ? null : () => _updateLokasiDialog(noResi),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Dalam Perjalanan · Perbarui',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : () => _selesaiAntar(noResi),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellowAccent,
                  foregroundColor: AppColors.navyPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Telah Sampai Tujuan',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ] else
            const Text(
              'Pengiriman untuk paket ini telah diselesaikan.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _buildAkunTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Akun Kurir',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
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
                    Text(_kurirNama,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const Text('Role: Kurir',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
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
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Keluar / Logout',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _TabButton(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navyPrimary : AppColors.surfaceGray,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}