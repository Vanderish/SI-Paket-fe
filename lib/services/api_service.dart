import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://si-paket.onrender.com/api';

  // --- TOKEN & SESSION STORAGE ---
  static Future<void> saveSession({
    required String token,
    required String role,
    required String email,
    int? userId,
    String? namaLengkap,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    await prefs.setString('user_role', role);
    await prefs.setString('user_email', email);
    if (userId != null) {
      await prefs.setInt('user_id', userId);
    }
    if (namaLengkap != null) {
      await prefs.setString('user_nama', namaLengkap);
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  static Future<String?> getNama() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_nama');
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static dynamic _parseResponse(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is Map && body['success'] == false) {
        throw Exception(body['message'] ?? 'Permintaan ditolak server');
      }
      return body;
    }
    final errorMsg = (body is Map && body['message'] != null)
        ? body['message']
        : (body is Map && body['error'] != null)
            ? body['error']
            : 'Terjadi kesalahan (${response.statusCode})';
    throw Exception(errorMsg);
  }

  // =========================================================
  // 1. AUTENTIKASI & MANAJEMEN PENGGUNA
  // =========================================================

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String role,
    required String namaLengkap,
    String? noTelp,
    String? lokasiPos,
    String? platKendaraan,
  }) async {
    final payload = <String, dynamic>{
      'namaLengkap': namaLengkap,
      'email': email,
      'password': password,
      'role': role,
      if (noTelp != null && noTelp.isNotEmpty) 'noTelp': noTelp,
      if (lokasiPos != null && lokasiPos.isNotEmpty) 'lokasiPos': lokasiPos,
      if (platKendaraan != null && platKendaraan.isNotEmpty)
        'platKendaraan': platKendaraan,
    };

    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    final data = _parseResponse(res) as Map<String, dynamic>;
    await _saveAuthResponse(data, email);
    return data;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _parseResponse(res) as Map<String, dynamic>;
    await _saveAuthResponse(data, email);
    return data;
  }

  static Future<void> _saveAuthResponse(
      Map<String, dynamic> data, String fallbackEmail) async {
    final token = data['token']?.toString() ?? '';
    final role = data['role']?.toString() ?? '';
    final nama = data['namaLengkap']?.toString() ?? fallbackEmail;
    final userId = int.tryParse(data['userId']?.toString() ?? '');
    if (token.isNotEmpty) {
      await saveSession(
        token: token,
        role: role,
        email: data['email']?.toString() ?? fallbackEmail,
        userId: userId,
        namaLengkap: nama,
      );
    }
  }

  static Future<void> logout() async {
    try {
      final headers = await _authHeaders();
      await http.post(Uri.parse('$baseUrl/auth/logout'), headers: headers);
    } finally {
      await clearSession();
    }
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/users/profile'),
      headers: headers,
    );
    return _parseResponse(res) as Map<String, dynamic>;
  }

  // =========================================================
  // 2. LAYANAN PAKET & PEMESANAN
  // =========================================================

  static Future<Map<String, dynamic>> cekOngkir({
    required String alamatAsal,
    required String alamatTujuan,
    required double beratKg,
    required String jenisPaket,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/paket/cek-ongkir'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'alamatAsal': alamatAsal,
        'alamatTujuan': alamatTujuan,
        'beratKg': beratKg,
        'jenisPaket': jenisPaket,
      }),
    );
    return _parseResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> buatPaketUser({
    required String namaPenerima,
    required String alamatAsal,
    required String alamatTujuan,
    required double beratKg,
    required String jenisPaket,
  }) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/paket'),
      headers: headers,
      body: jsonEncode({
        'namaPenerima': namaPenerima,
        'alamatAsal': alamatAsal,
        'alamatTujuan': alamatTujuan,
        'beratKg': beratKg,
        'jenisPaket': jenisPaket,
      }),
    );
    return _parseResponse(res) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getPaketSaya({String? status}) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/paket/saya').replace(
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    final res = await http.get(uri, headers: headers);
    final data = _parseResponse(res);
    return data is List ? data : (data['data'] as List? ?? []);
  }

  static Future<Map<String, dynamic>> getDetailPaket(String noResi) async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/paket/$noResi'),
      headers: headers,
    );
    return _parseResponse(res) as Map<String, dynamic>;
  }

  // =========================================================
  // 3. OPERASIONAL GUDANG
  // =========================================================

  static Future<List<dynamic>> getGudangPaket({
    String? status,
    String? jenisPaket,
  }) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/gudang/paket').replace(
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (jenisPaket != null && jenisPaket.isNotEmpty)
          'jenis_paket': jenisPaket,
      },
    );
    final res = await http.get(uri, headers: headers);
    final data = _parseResponse(res);
    return data is List ? data : (data['data'] as List? ?? []);
  }

  static Future<Map<String, dynamic>> buatPaketGudang({
    required String namaPenerima,
    required String alamatAsal,
    required String alamatTujuan,
    required double beratKg,
    required String jenisPaket,
    int? idKurir,
  }) async {
    final headers = await _authHeaders();
    final userId = await getUserId() ?? 1;
    final res = await http.post(
      Uri.parse('$baseUrl/gudang/paket'),
      headers: headers,
      body: jsonEncode({
        'idPengguna': userId,
        'namaPenerima': namaPenerima,
        'alamatAsal': alamatAsal,
        'alamatTujuan': alamatTujuan,
        'beratKg': beratKg,
        'jenisPaket': jenisPaket,
        'idKurir': ?idKurir,
      }),
    );
    return _parseResponse(res) as Map<String, dynamic>;
  }

  static Future<void> tambahTransit({
    required String noResi,
    required String lokasiUpdate,
    String status = 'Dalam Perjalanan',
    String? deskripsiStatus,
  }) async {
    final headers = await _authHeaders();
    final res = await http.patch(
      Uri.parse('$baseUrl/gudang/paket/$noResi/transit'),
      headers: headers,
      body: jsonEncode({
        'status': status,
        'lokasi_update': lokasiUpdate,
        'deskripsi_status':
            deskripsiStatus ?? 'Paket tiba di titik transit $lokasiUpdate',
      }),
    );
    _parseResponse(res);
  }

  static Future<void> assignKurir({
    required String noResi,
    required int idKurir,
  }) async {
    final headers = await _authHeaders();
    final res = await http.patch(
      Uri.parse('$baseUrl/gudang/paket/$noResi/assign-kurir'),
      headers: headers,
      body: jsonEncode({'id_kurir': idKurir}),
    );
    _parseResponse(res);
  }

  // =========================================================
  // 4. OPERASIONAL KURIR
  // =========================================================

  static Future<List<dynamic>> getDaftarKurir({bool? tersedia}) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/kurir').replace(
      queryParameters: {
        if (tersedia != null) 'tersedia': tersedia.toString(),
      },
    );
    final res = await http.get(uri, headers: headers);
    final data = _parseResponse(res);
    return data is List ? data : (data['data'] as List? ?? []);
  }

  static Future<List<dynamic>> getTugasKurir({String? status}) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/kurir/tugas').replace(
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    final res = await http.get(uri, headers: headers);
    final data = _parseResponse(res);
    return data is List ? data : (data['data'] as List? ?? []);
  }

  static Future<void> kurirTerimaPaket(
    String noResi, {
    String lokasiUpdate = 'Gudang Asal',
  }) async {
    final headers = await _authHeaders();
    final res = await http.patch(
      Uri.parse('$baseUrl/kurir/paket/$noResi/terima'),
      headers: headers,
      body: jsonEncode({'lokasi_update': lokasiUpdate}),
    );
    _parseResponse(res);
  }

  static Future<void> kurirUpdateLokasi({
    required String noResi,
    required String lokasiUpdate,
    String? deskripsiStatus,
  }) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/kurir/paket/$noResi/lokasi'),
      headers: headers,
      body: jsonEncode({
        'lokasi_update': lokasiUpdate,
        'deskripsi_status':
            deskripsiStatus ?? 'Kurir sedang berada di $lokasiUpdate',
      }),
    );
    _parseResponse(res);
  }

  static Future<void> kurirSelesaiAntar(
    String noResi, {
    String lokasiUpdate = 'Alamat Penerima',
    String deskripsiStatus = 'Paket telah diterima oleh penerima',
  }) async {
    final headers = await _authHeaders();
    final res = await http.patch(
      Uri.parse('$baseUrl/kurir/paket/$noResi/selesai'),
      headers: headers,
      body: jsonEncode({
        'lokasi_update': lokasiUpdate,
        'deskripsi_status': deskripsiStatus,
      }),
    );
    _parseResponse(res);
  }

  static Future<void> kurirUpdateKetersediaan(bool statusKetersediaan) async {
    final headers = await _authHeaders();
    final res = await http.patch(
      Uri.parse('$baseUrl/kurir/ketersediaan'),
      headers: headers,
      body: jsonEncode({'status_ketersediaan': statusKetersediaan}),
    );
    _parseResponse(res);
  }

  // =========================================================
  // 5. PELACAKAN RESI PUBLIK
  // =========================================================

  static Future<Map<String, dynamic>> trackPaketPublic(String noResi) async {
    final res = await http.get(Uri.parse('$baseUrl/tracking/$noResi'));
    return _parseResponse(res) as Map<String, dynamic>;
  }
}