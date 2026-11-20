import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../role_selection_screen.dart';

class PelangganMainScreen extends StatefulWidget {
  const PelangganMainScreen({super.key});

  @override
  State<PelangganMainScreen> createState() => _PelangganMainScreenState();
}

class _PelangganMainScreenState extends State<PelangganMainScreen> {
  final _resiController = TextEditingController();
  bool _isTracking = false;
  bool _isLoadingPaket = true;
  bool _isLoggedIn = false;
  String _namaUser = 'Pelanggan';

  Map<String, dynamic>? _trackingDetail;
  List<dynamic> _paketSaya = [];

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  @override
  void dispose() {
    _resiController.dispose();
    super.dispose();
  }

  Future<void> _initPage() async {
    final token = await ApiService.getToken();
    final nama = await ApiService.getNama();
    if (!mounted) return;
    setState(() {
      _isLoggedIn = token != null && token.isNotEmpty;
      if (nama != null && nama.isNotEmpty) _namaUser = nama;
    });

    if (_isLoggedIn) {
      await _fetchPaketSaya();
    } else {
      setState(() => _isLoadingPaket = false);
    }
  }

  Future<void> _fetchPaketSaya() async {
    setState(() => _isLoadingPaket = true);
    try {
      final raw = await ApiService.getPaketSaya();
      if (!mounted) return;
      setState(() {
        _paketSaya =
            raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
    } catch (_) {
      // Abaikan jika mode tamu tanpa token
    } finally {
      if (mounted) setState(() => _isLoadingPaket = false);
    }
  }

  Future<void> _lacakResi([String? resiParam]) async {
    final resi = (resiParam ?? _resiController.text).trim();
    if (resi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Masukkan nomor resi terlebih dahulu.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _resiController.text = resi;
    setState(() {
      _isTracking = true;
      _trackingDetail = null;
    });

    try {
      final raw = await ApiService.trackPaketPublic(resi);
      final data = (raw['data'] is Map<String, dynamic>)
          ? raw['data'] as Map<String, dynamic>
          : raw;
      if (!mounted) return;
      setState(() => _trackingDetail = data);
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
      if (mounted) setState(() => _isTracking = false);
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
    final riwayat = (_trackingDetail?['riwayat'] ??
            _trackingDetail?['riwayatPelacakan'] ??
            _trackingDetail?['riwayat_pelacakan'] ??
            []) as List<dynamic>;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _initPage,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              // HEADER PELANGGAN
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isLoggedIn
                            ? 'Halo, $_namaUser'
                            : 'Mode Pelacakan Publik',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Pantau posisi & jejak perjalanan paketmu',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _logout,
                    icon: Icon(
                      _isLoggedIn ? Icons.logout : Icons.login,
                      size: 18,
                      color: _isLoggedIn
                          ? Colors.red.shade700
                          : AppColors.navyPrimary,
                    ),
                    label: Text(
                      _isLoggedIn ? 'Keluar' : 'Masuk',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _isLoggedIn
                            ? Colors.red.shade700
                            : AppColors.navyPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // KOTAK LACAK RESI UTAMA
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          color: AppColors.yellowAccent,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Lacak Nomor Resi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _resiController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan nomor resi (misal: SPK-...)',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.navyPrimary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _isTracking ? null : () => _lacakResi(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.yellowAccent,
                          foregroundColor: AppColors.navyPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _isTracking ? 'Melacak...' : 'Cek Status Resi',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // HASIL VERTICAL TIMELINE
              if (_trackingDetail != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderLight, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            (_trackingDetail!['noResi'] ??
                                    _trackingDetail!['no_resi'] ??
                                    _resiController.text)
                                .toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.badgeGreenBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              (_trackingDetail!['statusTerkini'] ??
                                      _trackingDetail!['status_terkini'] ??
                                      '-')
                                  .toString(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.badgeGreenText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Penerima: ${_trackingDetail!['namaPenerima'] ?? _trackingDetail!['nama_penerima'] ?? '-'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Alamat Tujuan: ${_trackingDetail!['alamatTujuan'] ?? _trackingDetail!['alamat_tujuan'] ?? '-'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Divider(height: 24),
                      const Text(
                        'Jejak Perjalanan Paket',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (riwayat.isEmpty)
                        const Text(
                          'Paket baru didaftarkan di loket pengiriman.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        ...List.generate(riwayat.length, (idx) {
                          final item =
                              Map<String, dynamic>.from(riwayat[idx] as Map);
                          final isLatest = idx == 0;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Icon(
                                    isLatest
                                        ? Icons.radio_button_checked
                                        : Icons.circle,
                                    size: isLatest ? 16 : 12,
                                    color: isLatest
                                        ? AppColors.navyPrimary
                                        : AppColors.textMuted,
                                  ),
                                  if (idx != riwayat.length - 1)
                                    Container(
                                      width: 2,
                                      height: 34,
                                      color: AppColors.borderLight,
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (item['lokasiUpdate'] ??
                                                item['lokasi_update'] ??
                                                '-')
                                            .toString(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: isLatest
                                              ? AppColors.navyPrimary
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        (item['deskripsiStatus'] ??
                                                item['deskripsi_status'] ??
                                                '-')
                                            .toString(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                    ],
                  ),
                ),
              ],

              // DAFTAR PAKET TERHUBUNG KE AKUN (JIKA LOGIN)
              if (_isLoggedIn) ...[
                const SizedBox(height: 24),
                const Text(
                  'Paket Terhubung ke Akunmu',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ketuk kartu paket untuk melihat timeline perjalanan.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                if (_isLoadingPaket)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.navyPrimary,
                    ),
                  )
                else if (_paketSaya.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGray,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Belum ada kiriman paket yang terdaftar atas akun ini.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  ..._paketSaya.map((p) {
                    final resi =
                        (p['noResi'] ?? p['no_resi'] ?? '-').toString();
                    final penerima =
                        (p['namaPenerima'] ?? p['nama_penerima'] ?? '-')
                            .toString();
                    final status =
                        (p['statusTerkini'] ?? p['status_terkini'] ?? '-')
                            .toString();

                    return GestureDetector(
                      onTap: () => _lacakResi(resi),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
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
                                  resi,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Penerima: $penerima',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  status,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navyPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.navyPrimary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}