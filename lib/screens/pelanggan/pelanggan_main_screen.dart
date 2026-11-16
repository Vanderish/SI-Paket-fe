import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart' hide ApiService;
import '../role_selection_screen.dart';

class PelangganMainScreen extends StatefulWidget {
  const PelangganMainScreen({super.key});

  @override
  State<PelangganMainScreen> createState() => _PelangganMainScreenState();
}

class _PelangganMainScreenState extends State<PelangganMainScreen> {
  int _tabIndex = 0;
  bool _isLoggedIn = false;
  String _userNama = 'Pelanggan';

  // State Tab Lacak (Public Tracking)
  final _resiController = TextEditingController();
  bool _isLoadingTrack = false;
  Map<String, dynamic>? _trackingData;

  // State Tab Kiriman Saya (Authenticated User)
  bool _isLoadingKiriman = false;
  List<Map<String, dynamic>> _paketSaya = [];

  @override
  void initState() {
    super.initState();
    _initUserSession();
  }

  Future<void> _initUserSession() async {
    final token = await ApiService.getToken();
    final nama = await ApiService.getNama();
    if (!mounted) return;

    setState(() {
      _isLoggedIn = token != null && token.isNotEmpty;
      _userNama = nama ?? 'Pelanggan';
    });

    if (_isLoggedIn) {
      await _loadPaketSaya();
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

  Future<void> _cariResi() async {
    final resi = _resiController.text.trim();
    if (resi.isEmpty) {
      _showSnack('Masukkan nomor resi terlebih dahulu.', isError: true);
      return;
    }

    setState(() => _isLoadingTrack = true);
    try {
      final data = await ApiService.trackPaketPublic(resi);
      if (!mounted) return;
      setState(() => _trackingData = data);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingTrack = false);
    }
  }

  Future<void> _loadPaketSaya() async {
    setState(() => _isLoadingKiriman = true);
    try {
      final raw = await ApiService.getPaketSaya();
      if (!mounted) return;
      setState(() {
        _paketSaya = raw.cast<Map<String, dynamic>>();
        if (_paketSaya.isNotEmpty && _resiController.text.isEmpty) {
          _resiController.text =
              (_paketSaya.first['nomorResi'] ?? '').toString();
        }
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingKiriman = false);
    }
  }

  Future<void> _showBuatPaketDialog() async {
    final penerimaCtrl = TextEditingController();
    final alamatCtrl = TextEditingController();
    final beratCtrl = TextEditingController(text: '1.0');
    String jenis = 'Reguler';

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Buat Kiriman Baru',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: penerimaCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Penerima'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: alamatCtrl,
                  decoration: const InputDecoration(labelText: 'Alamat Tujuan'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: beratCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Berat (kg)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: jenis,
                  decoration: const InputDecoration(labelText: 'Jenis Layanan'),
                  items: const [
                    DropdownMenuItem(value: 'Reguler', child: Text('Reguler')),
                    DropdownMenuItem(value: 'Express', child: Text('Express')),
                  ],
                  onChanged: (v) => setDialogState(() => jenis = v ?? 'Reguler'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (penerimaCtrl.text.trim().isEmpty ||
                    alamatCtrl.text.trim().isEmpty) {
                  return;
                }
                try {
                  final berat =
                      double.tryParse(beratCtrl.text.replaceAll(',', '.')) ??
                          1.0;
                  await ApiService.buatPaketUser({
                    'namaPenerima': penerimaCtrl.text.trim(),
                    'alamatTujuan': alamatCtrl.text.trim(),
                    'kotaAsal': 'Surabaya',
                    'kotaTujuan': 'Surabaya',
                    'berat': berat,
                    'jenisPaket': jenis,
                  });
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (mounted) {
                    _showSnack(e.toString().replaceFirst('Exception: ', ''),
                        isError: true);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyPrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Buat Resi'),
            ),
          ],
        ),
      ),
    );

    if (created == true) {
      _showSnack('Kiriman baru berhasil dibuat!');
      await _loadPaketSaya();
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _tabIndex == 0
            ? _buildLacakTab()
            : _tabIndex == 1
                ? _buildKirimanTab()
                : _buildAkunTab(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) {
          setState(() => _tabIndex = i);
          if (i == 1 && _isLoggedIn) _loadPaketSaya();
        },
        selectedItemColor: AppColors.navyPrimary,
        unselectedItemColor: AppColors.textMuted,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Lacak'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined), label: 'Kiriman'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Akun'),
        ],
      ),
    );
  }

  // SCREEN 05 · Pelanggan & Pelacakan
  Widget _buildLacakTab() {
    final paketObj = (_trackingData?['paket'] is Map<String, dynamic>)
        ? _trackingData!['paket'] as Map<String, dynamic>
        : _trackingData;
    final riwayatList = (_trackingData?['riwayat'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
              (route) => false,
            ),
            child: Row(
              children: [
                const Icon(Icons.arrow_back_ios,
                    size: 12, color: AppColors.textSecondary),
                Text(
                  'PELANGGAN / ${_userNama.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Paket Anda,\ndalam pantauan.',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Cek perjalanan kiriman kapan saja.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          const Text(
            'Cari Paket / Cek Nomor Resi',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _resiController,
                  onSubmitted: (_) => _cariResi(),
                  decoration: InputDecoration(
                    hintText: 'Contoh: RESI-001 atau SPK...',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surfaceGray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _isLoadingTrack ? null : _cariResi,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.yellowAccent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _isLoadingTrack
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.navyPrimary,
                          ),
                        )
                      : const Icon(Icons.search, color: AppColors.navyPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (paketObj == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceGray,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Icon(Icons.local_shipping_outlined,
                      size: 40, color: AppColors.textMuted),
                  SizedBox(height: 10),
                  Text(
                    'Masukkan nomor resi di atas untuk melihat posisi paket secara real-time.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else ...[
            // Kartu Resi Utama (Dark Navy)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.navyPrimary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NOMOR RESI',
                    style: TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (paketObj['nomorResi'] ?? _resiController.text).toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      (paketObj['status'] ?? 'Dalam Proses').toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.badgeBlueText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (paketObj['kotaAsal'] ?? 'Asal').toString(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
                      const Icon(Icons.arrow_forward,
                          color: AppColors.yellowAccent, size: 18),
                      Text(
                        (paketObj['kotaTujuan'] ?? 'Tujuan').toString(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${paketObj['jenisPaket'] ?? 'Reguler'} · ${paketObj['berat'] ?? '-'} kg',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Penerima Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceGray,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PENERIMA',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (paketObj['namaPenerima'] ?? '-').toString(),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    (paketObj['alamatTujuan'] ?? '-').toString(),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Timeline Riwayat Pelacakan
            const Text(
              'Riwayat pelacakan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const Text(
              'Terbaru di atas · Semua waktu WIB',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            if (riwayatList.isEmpty)
              const Text('Belum ada catatan riwayat transit.',
                  style: TextStyle(color: AppColors.textSecondary))
            else
              ...riwayatList.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final isFirst = idx == 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isFirst
                              ? AppColors.yellowAccent
                              : AppColors.surfaceGray,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFirst
                              ? Icons.local_shipping_outlined
                              : Icons.inventory_2_outlined,
                          size: 16,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (item['waktu'] ?? item['timestamp'] ?? '-')
                                  .toString(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isFirst
                                    ? AppColors.badgeBlueText
                                    : AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              (item['lokasi'] ?? '-').toString(),
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              (item['keterangan'] ?? '').toString(),
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }

  // SCREEN 06 · Daftar Kiriman & Status Penerimaan
  Widget _buildKirimanTab() {
    if (!_isLoggedIn) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline,
                size: 48, color: AppColors.navyPrimary),
            const SizedBox(height: 14),
            const Text(
              'Masuk untuk Melihat Kiriman Anda',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Login sebagai User untuk membuat kiriman baru dan memantau seluruh paket Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(initialRole: 'User'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Login / Daftar User',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPaketSaya,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KIRIMAN SAYA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Penerimaan & Kiriman',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showBuatPaketDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellowAccent,
                  foregroundColor: AppColors.navyPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Kirim',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_isLoadingKiriman)
            const Center(
                child: CircularProgressIndicator(color: AppColors.navyPrimary))
          else if (_paketSaya.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('Belum ada riwayat kiriman di akun Anda.',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            ..._paketSaya.map((p) {
              final resi = (p['nomorResi'] ?? '-').toString();
              final status = (p['status'] ?? 'Menunggu Penjemputan').toString();
              final isSelesai = status.toLowerCase().contains('selesai');

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
                                fontSize: 15, fontWeight: FontWeight.w800)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelesai
                                ? AppColors.badgeGreenBg
                                : AppColors.yellowSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelesai
                                  ? AppColors.badgeGreenText
                                  : AppColors.yellowText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text((p['namaPenerima'] ?? '-').toString(),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    Text((p['alamatTujuan'] ?? '-').toString(),
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _resiController.text = resi;
                          setState(() => _tabIndex = 0);
                          _cariResi();
                        },
                        icon: const Icon(Icons.timeline, size: 16),
                        label: const Text('Lihat Detail Pelacakan'),
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

  Widget _buildAkunTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Akun Pelanggan',
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
                  child: Icon(Icons.person, color: AppColors.yellowAccent),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isLoggedIn ? _userNama : 'Mode Tamu (Publik)',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(
                        _isLoggedIn
                            ? 'Role: User'
                            : 'Hanya akses pelacakan resi',
                        style: const TextStyle(
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
              onPressed: _isLoggedIn
                  ? _logout
                  : () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RoleSelectionScreen()),
                        (route) => false,
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isLoggedIn ? Colors.red.shade700 : AppColors.navyPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(_isLoggedIn ? Icons.logout : Icons.login),
              label: Text(
                _isLoggedIn ? 'Keluar / Logout' : 'Kembali ke Pilihan Peran',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}