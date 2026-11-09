import 'package:flutter/material.dart';
import 'package:vms_frontend/core/theme/app_theme.dart';
import 'package:vms_frontend/features/auth/login_screen.dart';

class VmsApp extends StatelessWidget {
  const VmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stark Fleet | Vehicle Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
