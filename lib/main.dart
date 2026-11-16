import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/role_selection_screen.dart';

void main() {
  runApp(const SiPaketApp());
}

class SiPaketApp extends StatelessWidget {
  const SiPaketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SI-PAKET',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const RoleSelectionScreen(),
    );
  }
}