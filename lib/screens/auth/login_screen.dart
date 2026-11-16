import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../admin/admin_home_screen.dart';
import '../kurir/kurir_tugas_screen.dart';
import '../pelanggan/pelanggan_main_screen.dart';


class _ApiServiceShim {
  const _ApiServiceShim();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError('ApiService.login is not available in this build.');
  }

  Future<void> register({
    required String email,
    required String password,
    required String role,
    required String namaLengkap,
    String? noTelp,
    String? lokasiPos,
    String? platKendaraan,
  }) async {
    throw UnimplementedError('ApiService.register is not available in this build.');
  }
}

final ApiService = _ApiServiceShim();

class LoginScreen extends StatefulWidget {
  final String initialRole; // 'PetugasGudang', 'Kurir', atau 'User'

  const LoginScreen({super.key, required this.initialRole});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isRegisterMode = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _namaController = TextEditingController();
  final _extraFieldController = TextEditingController(); // noTelp / lokasiPos / platKendaraan

  String get _roleLabel {
    switch (widget.initialRole) {
      case 'PetugasGudang':
        return 'Admin Pos';
      case 'Kurir':
        return 'Kurir';
      default:
        return 'User / Pelanggan';
    }
  }

  String get _extraFieldLabel {
    switch (widget.initialRole) {
      case 'PetugasGudang':
        return 'Lokasi Pos (contoh: DC Surabaya)';
      case 'Kurir':
        return 'Plat Kendaraan (contoh: L 4521 AB)';
      default:
        return 'Nomor Telepon (contoh: 08123456789)';
    }
  }

  void _navigateToDashboard(String role) {
    Widget destination;
    if (role == 'PetugasGudang') {
      destination = const AdminHomeScreen();
    } else if (role == 'Kurir') {
      destination = const KurirTugasScreen();
    } else {
      destination = const PelangganMainScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Email dan password wajib diisi.');
      return;
    }

    if (_isRegisterMode && _namaController.text.trim().isEmpty) {
      _showError('Nama lengkap wajib diisi.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isRegisterMode) {
        await ApiService.register(
          email: email,
          password: password,
          role: widget.initialRole,
          namaLengkap: _namaController.text.trim(),
          noTelp: widget.initialRole == 'User'
              ? _extraFieldController.text.trim()
              : null,
          lokasiPos: widget.initialRole == 'PetugasGudang'
              ? _extraFieldController.text.trim()
              : null,
          platKendaraan: widget.initialRole == 'Kurir'
              ? _extraFieldController.text.trim()
              : null,
        );
      }

      final loginData = await ApiService.login(
        email: email,
        password: password,
      );

      final actualRole = loginData['role']?.toString() ?? widget.initialRole;
      if (!mounted) return;
      _navigateToDashboard(actualRole);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _roleLabel,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 14),
              Text(
                _isRegisterMode ? 'Buat akun baru.' : 'Selamat datang kembali.',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isRegisterMode
                    ? 'Daftarkan akun $_roleLabel untuk mulai menggunakan SI-PAKET.'
                    : 'Masuk dengan akun $_roleLabel Anda yang terdaftar.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),

              if (_isRegisterMode) ...[
                const Text('Nama Lengkap',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _namaController,
                  hint: 'Masukkan nama lengkap',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 14),
              ],

              const Text('Email',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _emailController,
                hint: 'nama@email.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),

              const Text('Password',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: AppColors.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceGray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              if (_isRegisterMode) ...[
                const SizedBox(height: 14),
                Text(_extraFieldLabel,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _extraFieldController,
                  hint: _extraFieldLabel,
                  icon: Icons.badge_outlined,
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.yellowAccent,
                          ),
                        )
                      : Text(
                          _isRegisterMode ? 'Daftar & Masuk' : 'Masuk',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 14),

              // Toggle Login <-> Register
              Center(
                child: TextButton(
                  onPressed: () =>
                      setState(() => _isRegisterMode = !_isRegisterMode),
                  child: Text(
                    _isRegisterMode
                        ? 'Sudah punya akun? Masuk di sini'
                        : 'Belum punya akun? Daftar sekarang',
                    style: const TextStyle(
                      color: AppColors.navyPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              // Opsi Lacak Publik khusus User/Pelanggan
              if (widget.initialRole == 'User') ...[
                const Divider(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToDashboard('User'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navyPrimary,
                      side: const BorderSide(color: AppColors.borderLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.search),
                    label: const Text(
                      'Lacak Nomor Resi Tanpa Login',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surfaceGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}