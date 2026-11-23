import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../role_selection_screen.dart';

class KurirTugasScreen extends StatefulWidget {
  const KurirTugasScreen({super.key});

  @override
  State<KurirTugasScreen> createState() => _KurirTugasScreenState();
}

class _KurirTugasScreenState extends State<KurirTugasScreen> {
  bool _isLoading = true;
  bool _isActionLoading = false;
  bool _isOnline = true;
  List<Map<String, dynamic>> _tugasList = [];
  String _kurirNama = 'Kurir';
  String _selectedStatus = ''; // '' = semua, atau 'Menunggu Penjemputan', 'Dalam Perjalanan', 'Selesai'

  @override
  void initState() {
    super.initState();
    _loadData();
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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final nama = await ApiService.getNama();
      // Ambil SEMUA tugas sekali saja, filter dilakukan lokal di UI
      final raw = await ApiService.getTugasKurir();
      if (!mounted) return;
      setState(() {
        if (nama != null && nama.isNotEmpty) _kurirNama = nama;
        _tugasList =
            raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStatus(bool val) async {
    setState(() => _isActionLoading = true);
    try {
      await ApiService.kurirUpdateKetersediaan(val);
      if (!mounted) return;
      setState(() => _isOnline = val);
      _showSnack(
        val
            ? 'Status ON DUTY: Siap menerima tugas baru'
            : 'Status OFF DUTY: Tidak menerima tugas baru',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _terimaPaket(String resi) async {
    setState(() => _isActionLoading = true);
    try {
      await ApiService.kurirTerimaPaket(resi);
      _showSnack('Paket $resi berhasil diambil dari gudang!');
      await _loadData();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _dialogUpdateLokasi(String resi) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Checkpoint Lokasi ($resi)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Contoh: Simpang Tiga Babat / Jl. Sunan Giri',
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
            child: const Text('Kirim Lokasi'),
          ),
        ],
      ),
    );

    if (ok != true || ctrl.text.trim().isEmpty) return;

    setState(() => _isActionLoading = true);
    try {
      await ApiService.kurirUpdateLokasi(
        noResi: resi,
        lokasiUpdate: ctrl.text.trim(),
      );
      _showSnack('Posisi pengiriman $resi diperbarui!');
      await _loadData();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _selesaiAntar(String resi) async {
    setState(() => _isActionLoading = true);
    try {
      await ApiService.kurirSelesaiAntar(
        resi,
        deskripsiStatus:
            'Paket telah diantar ke alamat tujuan (Menunggu Konfirmasi Penerima)',
      );
      _showSnack('Pengantaran $resi selesai!');
      await _loadData();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
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
    // Statistik selalu dihitung dari keseluruhan _tugasList (tidak berubah saat filter)
    final totalAktif = _tugasList.where((p) {
      final st = (p['statusTerkini'] ?? p['status_terkini'] ?? '')
          .toString()
          .toLowerCase();
      return !st.contains('selesai') && !st.contains('terkirim');
    }).length;

    final totalSelesai = _tugasList.length - totalAktif;

    // Filter lokal berdasarkan statusTerkini
    final filteredList = _tugasList.where((p) {
      if (_selectedStatus.isEmpty) return true;
      final st = (p['statusTerkini'] ?? p['status_terkini'] ?? '')
          .toString()
          .toLowerCase();
      if (_selectedStatus == 'Menunggu') {
        return st.contains('menunggu') || st.contains('ditugaskan');
      } else if (_selectedStatus == 'Perjalanan') {
        return st.contains('perjalanan');
      } else if (_selectedStatus == 'Terkirim') {
        return st.contains('selesai') || st.contains('terkirim');
      }
      return st.contains(_selectedStatus.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              // HEADER DRIVER + LOGOUT
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.navyPrimary,
                        child: Icon(
                          Icons.two_wheeler,
                          color: AppColors.yellowAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _kurirNama,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            'Armada Kurir SI-PAKET',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _loadData,
                        tooltip: 'Refresh',
                        icon: const Icon(
                          Icons.refresh,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: _logout,
                        tooltip: 'Keluar',
                        icon: Icon(Icons.logout, color: Colors.red.shade700),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // PANEL STATUS ON DUTY / OFF DUTY & STATISTIK
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color:
                      _isOnline ? AppColors.navyPrimary : Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isOnline
                                  ? 'STATUS: ON DUTY'
                                  : 'STATUS: OFF DUTY',
                              style: const TextStyle(
                                color: AppColors.yellowAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isOnline
                                  ? 'Siap menerima penugasan gudang'
                                  : 'Sedang tidak menerima tugas baru',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isOnline,
                          activeThumbColor: AppColors.yellowAccent,
                          onChanged: _isActionLoading ? null : _toggleStatus,
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _driverStat('$totalAktif', 'Tugas Aktif'),
                        ),
                        Container(width: 1, height: 32, color: Colors.white24),
                        Expanded(
                          child: _driverStat('$totalSelesai', 'Selesai Antar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              const Text(
                'Daftar Misi Pengantaran',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),

              // Filter Status (filter lokal di memory)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Semua', ''),
                    const SizedBox(width: 8),
                    _buildFilterChip('Menunggu', 'Menunggu'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Perjalanan', 'Perjalanan'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Terkirim', 'Terkirim'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 50),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.navyPrimary,
                    ),
                  ),
                )
              else if (filteredList.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGray,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 40,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tidak ada paket pada filter ini.',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                )
              else
                ...filteredList.map((p) => _buildMissionCard(p)),
            ],
          ),
        ),
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
        // Filter lokal di memory, tidak perlu hit API
      },
    );
  }

  Widget _driverStat(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(
            color: AppColors.yellowAccent,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> p) {
    final resi = (p['noResi'] ?? p['no_resi'] ?? '-').toString();
    final penerima =
        (p['namaPenerima'] ?? p['nama_penerima'] ?? '-').toString();
    final asal = (p['alamatAsal'] ?? p['alamat_asal'] ?? 'Gudang').toString();
    final tujuan =
        (p['alamatTujuan'] ?? p['alamat_tujuan'] ?? '-').toString();
    final status =
        (p['statusTerkini'] ?? p['status_terkini'] ?? 'Ditugaskan').toString();

    final statusLower = status.toLowerCase();
    final belumDiambil = statusLower.contains('menunggu') ||
        statusLower.contains('ditugaskan');
    final sudahTerkirim = statusLower.contains('selesai') || statusLower.contains('terkirim');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.yellowSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  resi,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: AppColors.yellowText,
                  ),
                ),
              ),
              Text(
                status,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // RUTE VISUAL (ASAL -> TUJUAN)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Column(
                children: [
                  Icon(
                    Icons.radio_button_checked,
                    size: 16,
                    color: AppColors.navyPrimary,
                  ),
                  SizedBox(height: 22),
                  Icon(Icons.location_on, size: 18, color: Colors.red),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ambil: $asal',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Antar ke: $penerima',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      tujuan,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (belumDiambil)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isActionLoading ? null : () => _terimaPaket(resi),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellowAccent,
                  foregroundColor: AppColors.navyPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.inventory),
                label: const Text(
                  '1. Konfirmasi Ambil Paket',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            )
          else if (sudahTerkirim)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.badgeGreenBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.badgeGreenText, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Paket Sudah Diterima',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.badgeGreenText,
                          ),
                        ),
                        const SizedBox(height: 2)
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: _isActionLoading
                          ? null
                          : () => _dialogUpdateLokasi(resi),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navyPrimary,
                        side: const BorderSide(color: AppColors.navyPrimary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.my_location, size: 18),
                      label: const Text(
                        'Update Posisi',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed:
                          _isActionLoading ? null : () => _selesaiAntar(resi),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.badgeGreenText,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text(
                        'Selesai Antar',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}