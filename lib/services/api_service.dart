import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.0.107:8080/api';

  // --- TOKEN & SESSION STORAGE ---
  static Future<void> saveSession({
    required String token,
    required String role,
    required String email,
    String? namaLengkap,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    await prefs.setString('user_role', role);
    await prefs.setString('user_email', email);
    if (namaLengkap != null) {
      await prefs.setString('user_nama', namaLengkap);
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
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
      return body;
    }
    final errorMsg = (body is Map && body['message'] != null)
        ? body['message']
        : (body is Map && body['error'] != null)
            ? body['error']
            : 'Terjadi kesalahan (${response.statusCode})';
    throw Exception(errorMsg);
  }

  // 1. AUTH & PROFILE ENDPOINTS

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
    final token = data['token']?.toString() ?? '';
    final role = data['role']?.toString() ?? '';
    final nama = data['namaLengkap']?.toString() ?? email;
    if (token.isNotEmpty) {
      await saveSession(
        token: token,
        role: role,
        email: email,
        namaLengkap: nama,
      );
    }
    return data;
  }

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
      'email': email,
      'password': password,
      'role': role,
      'namaLengkap': namaLengkap,
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
    return _parseResponse(res) as Map<String, dynamic>;
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

  // 2. PUBLIC TRACKING & PAKET ENDPOINTS

  static Future<Map<String, dynamic>> trackPaketPublic(String noResi) async {
    final res = await http.get(Uri.parse('$baseUrl/tracking/$noResi'));
    return _parseResponse(res) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> cekOngkir({
    required double beratKg,
    required String jenisLayanan,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/paket/cek-ongkir'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'berat': beratKg,
        'jenisPaket': jenisLayanan,
      }),
    );
    return _parseResponse(res) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getPaketSaya() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/paket/saya'),
      headers: headers,
    );
    final data = _parseResponse(res);
    return data is List ? data : (data['data'] as List? ?? []);
  }

  static Future<Map<String, dynamic>> buatPaketUser(
      Map<String, dynamic> payload) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/paket'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return _parseResponse(res) as Map<String, dynamic>;
  }

  // 3. PETUGAS GUDANG (ADMIN POS) ENDPOINTS

  static Future<List<dynamic>> getGudangPaket() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/gudang/paket'),
      headers: headers,
    );
    final data = _parseResponse(res);
    return data is List ? data : (data['data'] as List? ?? []);
  }

  static Future<Map<String, dynamic>> buatPaketGudang(
      Map<String, dynamic> payload) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/gudang/paket'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return _parseResponse(res) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getDaftarKurir() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/kurir'),
      headers: headers,
    );
    final data = _parseResponse(res);
    return data is List ? data : (data['data'] as List? ?? []);
  }

  static Future<void> assignKurir({
    required String noResi,
    required int kurirId,
  }) async {
    final headers = await _authHeaders();
    final res = await http.patch(
      Uri.parse('$baseUrl/gudang/paket/$noResi/assign-kurir'),
      headers: headers,
      body: jsonEncode({'kurirId': kurirId}),
    );
    _parseResponse(res);
  }

  static Future<void> tambahTransit({
    required String noResi,
    required String lokasi,
    String? keterangan,
  }) async {
    final headers = await _authHeaders();
    final res = await http.patch(
      Uri.parse('$baseUrl/gudang/paket/$noResi/transit'),
      headers: headers,
      body: jsonEncode({
        'lokasi': lokasi,
        'keterangan': keterangan ?? 'Paket tercatat di titik transit $lokasi',
      }),
    );
    _parseResponse(res);
  }

  // 4. KURIR ENDPOINTS

  static Future<List<dynamic>> getTugasKurir() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/kurir/tugas'),
      headers: headers,
    );
    final data = _parseResponse(res);
    return data is List ? data : (data['data'] as List? ?? []);
  }

  static Future<void> kurirTerimaPaket(String noResi) async {
    final headers = await _authHeaders();
    final res = await http.patch(
      Uri.parse('$baseUrl/kurir/paket/$noResi/terima'),
      headers: headers,
    );
    _parseResponse(res);
  }

  static Future<void> kurirUpdateLokasi({
    required String noResi,
    required String lokasi,
    String? keterangan,
  }) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/kurir/paket/$noResi/lokasi'),
      headers: headers,
      body: jsonEncode({
        'lokasi': lokasi,
        'keterangan': keterangan ?? 'Kurir berada di $lokasi',
      }),
    );
    _parseResponse(res);
  }

  static Future<void> kurirSelesaiAntar(String noResi) async {
    final headers = await _authHeaders();
    final res = await http.patch(
      Uri.parse('$baseUrl/kurir/paket/$noResi/selesai'),
      headers: headers,
    );
    _parseResponse(res);
  }

  static Future<void> kurirUpdateKetersediaan(bool tersedia) async {
    final headers = await _authHeaders();
    final res = await http.patch(
      Uri.parse('$baseUrl/kurir/ketersediaan'),
      headers: headers,
      body: jsonEncode({'tersedia': tersedia}),
    );
    _parseResponse(res);
  }
}