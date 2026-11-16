import 'package:flutter/material.dart';

enum StatusPaket {
  dalamProses,
  dalamPerjalanan,
  menungguKonfirmasi,
  selesai,
}

class RiwayatTransit {
  final String waktu;
  final String lokasi;
  final String keterangan;
  final bool isCurrent;

  RiwayatTransit({
    required this.waktu,
    required this.lokasi,
    required this.keterangan,
    this.isCurrent = false,
  });
}

// Superclass Paket
abstract class Paket {
  final String nomorResi;
  final String namaPenerima;
  final String alamatTujuan;
  final String kotaAsal;
  final String kotaTujuan;
  final double beratKg;
  final String estimasiTiba;
  StatusPaket status;
  String? kurirNama;
  List<RiwayatTransit> riwayat;

  Paket({
    required this.nomorResi,
    required this.namaPenerima,
    required this.alamatTujuan,
    required this.kotaAsal,
    required this.kotaTujuan,
    required this.beratKg,
    required this.estimasiTiba,
    this.status = StatusPaket.dalamProses,
    this.kurirNama,
    required this.riwayat,
  });

  String get jenisLayanan;
  int hitungOngkir();
}

// Subclass PaketReguler
class PaketReguler extends Paket {
  PaketReguler({
    required super.nomorResi,
    required super.namaPenerima,
    required super.alamatTujuan,
    required super.kotaAsal,
    required super.kotaTujuan,
    required super.beratKg,
    super.estimasiTiba = '2-3 hari',
    super.status,
    super.kurirNama,
    required super.riwayat,
  });

  @override
  String get jenisLayanan => 'Reguler';

  @override
  int hitungOngkir() => beratKg.ceil() * 10000;
}

// Subclass PaketExpress
class PaketExpress extends Paket {
  PaketExpress({
    required super.nomorResi,
    required super.namaPenerima,
    required super.alamatTujuan,
    required super.kotaAsal,
    required super.kotaTujuan,
    required super.beratKg,
    super.estimasiTiba = '1 hari',
    super.status,
    super.kurirNama,
    required super.riwayat,
  });

  @override
  String get jenisLayanan => 'Express';

  @override
  int hitungOngkir() => beratKg.ceil() * 18000;
}

class PaketStore extends ChangeNotifier {
  static final PaketStore instance = PaketStore._internal();

  PaketStore._internal() {
    _daftarPaket = [
      PaketReguler(
        nomorResi: 'SPK2611140008',
        namaPenerima: 'Nabila Putri',
        alamatTujuan: 'Jl. Keputih Tegal No. 18, Sukolilo, Surabaya',
        kotaAsal: 'Surabaya',
        kotaTujuan: 'Sukolilo',
        beratKg: 2.4,
        estimasiTiba: 'Estimasi tiba 16 Nov',
        status: StatusPaket.dalamProses,
        kurirNama: 'Andi Pratama',
        riwayat: [
          RiwayatTransit(
            waktu: '14 Nov 2026 · 08.30 WIB',
            lokasi: 'DC Surabaya',
            keterangan: 'Paket diterima dan diproses di gudang.',
            isCurrent: true,
          ),
        ],
      ),
      PaketReguler(
        nomorResi: 'SPK2611120042',
        namaPenerima: 'Dimas Saputra',
        alamatTujuan: 'Jl. Teknik Kimia No. 12, Sukolilo, Surabaya',
        kotaAsal: 'Jakarta',
        kotaTujuan: 'Surabaya',
        beratKg: 2.0,
        estimasiTiba: 'Estimasi tiba 14 Nov',
        status: StatusPaket.dalamPerjalanan,
        kurirNama: 'Andi Pratama',
        riwayat: [
          RiwayatTransit(
            waktu: '14 Nov 2026 · 09.15 WIB',
            lokasi: 'Keputih, Surabaya',
            keterangan: 'Kurir Andi sedang menuju alamat Anda.',
            isCurrent: true,
          ),
          RiwayatTransit(
            waktu: '14 Nov 2026 · 08.10 WIB',
            lokasi: 'DC Surabaya',
            keterangan: 'Paket tiba dan diserahkan ke kurir.',
          ),
          RiwayatTransit(
            waktu: '13 Nov 2026 · 21.30 WIB',
            lokasi: 'DC Semarang',
            keterangan: 'Paket berangkat menuju DC Surabaya.',
          ),
          RiwayatTransit(
            waktu: '12 Nov 2026 · 17.20 WIB',
            lokasi: 'DC Cakung',
            keterangan: 'Paket diterima dan diproses di gudang.',
          ),
        ],
      ),
      PaketReguler(
        nomorResi: 'SPK2611120039',
        namaPenerima: 'Sinta Maharani',
        alamatTujuan: 'Jl. Mulyorejo No. 9, Surabaya',
        kotaAsal: 'Bandung',
        kotaTujuan: 'Surabaya',
        beratKg: 1.5,
        estimasiTiba: 'Tiba 08.45 WIB',
        status: StatusPaket.menungguKonfirmasi,
        kurirNama: 'Andi Pratama',
        riwayat: [
          RiwayatTransit(
            waktu: '14 Nov 2026 · 08.45 WIB',
            lokasi: 'Mulyorejo, Surabaya',
            keterangan: 'Paket telah tiba di tujuan. Menunggu konfirmasi penerima.',
            isCurrent: true,
          ),
        ],
      ),
    ];
  }

  late List<Paket> _daftarPaket;
  List<Paket> get daftarPaket => _daftarPaket;

  void tambahPaketBaru({
    required String namaPenerima,
    required String alamatTujuan,
    required double beratKg,
    required bool isExpress,
  }) {
    final resiBaru = 'SPK261117${1000 + _daftarPaket.length}';
    final paketBaru = isExpress
        ? PaketExpress(
            nomorResi: resiBaru,
            namaPenerima: namaPenerima,
            alamatTujuan: alamatTujuan,
            kotaAsal: 'Surabaya',
            kotaTujuan: 'Surabaya',
            beratKg: beratKg,
            riwayat: [
              RiwayatTransit(
                waktu: '17 Nov 2026 · 03.15 WIB',
                lokasi: 'DC Surabaya',
                keterangan: 'Resi dibuat & paket diterima di pos.',
                isCurrent: true,
              ),
            ],
          )
        : PaketReguler(
            nomorResi: resiBaru,
            namaPenerima: namaPenerima,
            alamatTujuan: alamatTujuan,
            kotaAsal: 'Surabaya',
            kotaTujuan: 'Surabaya',
            beratKg: beratKg,
            riwayat: [
              RiwayatTransit(
                waktu: '17 Nov 2026 · 03.15 WIB',
                lokasi: 'DC Surabaya',
                keterangan: 'Resi dibuat & paket diterima di pos.',
                isCurrent: true,
              ),
            ],
          );

    _daftarPaket.insert(0, paketBaru);
    notifyListeners();
  }

  void tugaskanKurir(String nomorResi, String namaKurir) {
    final paket = _daftarPaket.firstWhere((p) => p.nomorResi == nomorResi);
    paket.kurirNama = namaKurir;
    notifyListeners();
  }

  void tambahTitikTransit(String nomorResi, String lokasiTransit) {
    final paket = _daftarPaket.firstWhere((p) => p.nomorResi == nomorResi);
    paket.riwayat = [
      RiwayatTransit(
        waktu: '17 Nov 2026 · 03.20 WIB',
        lokasi: lokasiTransit,
        keterangan: 'Paket tercatat di titik transit $lokasiTransit.',
        isCurrent: true,
      ),
      ...paket.riwayat.map(
        (e) => RiwayatTransit(
          waktu: e.waktu,
          lokasi: e.lokasi,
          keterangan: e.keterangan,
          isCurrent: false,
        ),
      ),
    ];
    notifyListeners();
  }

  void mulaiAntarKurir(String nomorResi) {
    final paket = _daftarPaket.firstWhere((p) => p.nomorResi == nomorResi);
    paket.status = StatusPaket.dalamPerjalanan;
    tambahTitikTransit(nomorResi, 'Keputih, Surabaya');
  }

  void sampaiTujuanKurir(String nomorResi) {
    final paket = _daftarPaket.firstWhere((p) => p.nomorResi == nomorResi);
    paket.status = StatusPaket.menungguKonfirmasi;
    paket.riwayat = [
      RiwayatTransit(
        waktu: '17 Nov 2026 · 10.42 WIB',
        lokasi: paket.alamatTujuan,
        keterangan: 'Paket telah sampai tujuan. Menunggu konfirmasi user.',
        isCurrent: true,
      ),
      ...paket.riwayat,
    ];
    notifyListeners();
  }

  void konfirmasiPenerimaanUser(String nomorResi) {
    final paket = _daftarPaket.firstWhere((p) => p.nomorResi == nomorResi);
    paket.status = StatusPaket.selesai;
    paket.riwayat = [
      RiwayatTransit(
        waktu: '17 Nov 2026 · 10.45 WIB',
        lokasi: 'Diterima oleh ${paket.namaPenerima}',
        keterangan: 'Paket telah dikonfirmasi diterima dengan baik.',
        isCurrent: true,
      ),
      ...paket.riwayat,
    ];
    notifyListeners();
  }
}