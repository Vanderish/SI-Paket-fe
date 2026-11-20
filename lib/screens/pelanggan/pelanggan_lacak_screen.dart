import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class PelangganLacakScreen extends StatefulWidget {
  const PelangganLacakScreen({super.key});

  @override
  State<PelangganLacakScreen> createState() => _PelangganLacakScreenState();
}

class _PelangganLacakScreenState extends State<PelangganLacakScreen> {
  final _resiController = TextEditingController();
  bool _isTracking = false;
  Map<String, dynamic>? _hasilTracking;

  // Cek Ongkir
  final _asalController = TextEditingController(text: 'DC Surabaya');
  final _tujuanController = TextEditingController();
  final _beratController = TextEditingController(text: '1.0');
  bool _isExpress = false;
  bool _isCekOngkir = false;
  Map<String, dynamic>? _hasilOngkir;

  @override
  void dispose() {
    _resiController.dispose();
    _asalController.dispose();
    _tujuanController.dispose();
    _beratController.dispose();
    super.dispose();
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

  Future<void> _lacakResi() async {
    final resi = _resiController.text.trim();
    if (resi.isEmpty) {
      _showSnack('Masukkan nomor resi terlebih dahulu.', isError: true);
      return;
    }

    setState(() {
      _isTracking = true;
      _hasilTracking = null;
    });

    try {
      final raw = await ApiService.trackPaketPublic(resi);
      final data = (raw['data'] is Map<String, dynamic>)
          ? raw['data'] as Map<String, dynamic>
          : raw;
      if (!mounted) return;
      setState(() => _hasilTracking = data);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isTracking = false);
    }
  }

  Future<void> _hitungOngkir() async {
    if (_asalController.text.trim().isEmpty ||
        _tujuanController.text.trim().isEmpty) {
      _showSnack('Isi kota asal dan tujuan terlebih dahulu.', isError: true);
      return;
    }

    final berat =
        double.tryParse(_beratController.text.replaceAll(',', '.')) ?? 1.0;

    setState(() => _isCekOngkir = true);
    try {
      final raw = await ApiService.cekOngkir(
        alamatAsal: _asalController.text.trim(),
        alamatTujuan: _tujuanController.text.trim(),
        beratKg: berat,
        jenisPaket: _isExpress ? 'Express' : 'Reguler',
      );
      final data = (raw['data'] is Map<String, dynamic>)
          ? raw['data'] as Map<String, dynamic>
          : raw;
      if (!mounted) return;
      setState(() => _hasilOngkir = data);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isCekOngkir = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final riwayat = (_hasilTracking?['riwayat'] ??
            _hasilTracking?['riwayatPelacakan'] ??
            _hasilTracking?['riwayat_pelacakan'] ??
            []) as List<dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PELANGGAN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Lacak & Cek Ongkir',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 18),

          // CARD LACAK RESI
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.navyPrimary,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lacak Nomor Resi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pantau posisi paket secara real-time.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _resiController,
                  decoration: InputDecoration(
                    hintText: 'Contoh: SPK-20261120-001',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.qr_code_scanner,
                        color: AppColors.navyPrimary),
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
                  child: ElevatedButton.icon(
                    onPressed: _isTracking ? null : _lacakResi,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.yellowAccent,
                      foregroundColor: AppColors.navyPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.search, size: 18),
                    label: Text(
                      _isTracking ? 'Mencari...' : 'Lacak Paket',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // HASIL TRACKING
          if (_hasilTracking != null) ...[
            const SizedBox(height: 16),
            Container(
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
                      Text(
                        (_hasilTracking!['noResi'] ??
                                _hasilTracking!['no_resi'] ??
                                _resiController.text)
                            .toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.badgeBlueBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (_hasilTracking!['statusTerkini'] ??
                                  _hasilTracking!['status_terkini'] ??
                                  '-')
                              .toString(),
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
                    'Penerima: ${_hasilTracking!['namaPenerima'] ?? _hasilTracking!['nama_penerima'] ?? '-'}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  Text(
                    'Tujuan: ${_hasilTracking!['alamatTujuan'] ?? _hasilTracking!['alamat_tujuan'] ?? '-'}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  if (riwayat.isNotEmpty) ...[
                    const Divider(height: 22),
                    const Text(
                      'Riwayat Perjalanan',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    ...riwayat.map((r) {
                      final item = Map<String, dynamic>.from(r as Map);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.circle,
                                size: 10, color: AppColors.navyPrimary),
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
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13),
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
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // CARD CEK ONGKIR
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceGray,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cek Tarif Pengiriman',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _asalController,
                  decoration: _inputDeco('Kota / Gudang Asal'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _tujuanController,
                  decoration: _inputDeco('Alamat / Kota Tujuan'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _beratController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDeco('Berat (kg)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<bool>(
                            value: _isExpress,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                  value: false, child: Text('Reguler')),
                              DropdownMenuItem(
                                  value: true, child: Text('Express')),
                            ],
                            onChanged: (v) =>
                                setState(() => _isExpress = v ?? false),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _isCekOngkir ? null : _hitungOngkir,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _isCekOngkir ? 'Menghitung...' : 'Cek Ongkir',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                if (_hasilOngkir != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Total Biaya: Rp${_hasilOngkir!['totalBiaya'] ?? _hasilOngkir!['total_biaya'] ?? _hasilOngkir!['tarifDasar'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}