import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vms_frontend/app/app_shell.dart';
import 'package:vms_frontend/core/theme/app_theme.dart';
import 'package:vms_frontend/features/auth/data/auth_api_exception.dart';
import 'package:vms_frontend/features/auth/data/auth_service.dart';
import 'package:vms_frontend/shared/widgets/server_request_progress.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService.instance;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _isRestoring = true;
  String? _authError;
  String? _restoreError;

  @override
  void initState() {
    super.initState();
    unawaited(_restoreSession());
  }

  Future<void> _restoreSession() async {
    setState(() {
      _isRestoring = true;
      _restoreError = null;
    });
    try {
      final session = await _authService.restoreSession();
      if (!mounted) return;
      setState(() => _isRestoring = false);
      if (session != null) _openWorkspace();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isRestoring = false;
        _restoreError = error is AuthApiException
            ? error.message
            : 'Could not restore your session. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _authError = null;
    });
    try {
      await _authService.login(_emailController.text, _passwordController.text);
      _passwordController.clear();
      if (mounted) _openWorkspace();
    } catch (error) {
      if (mounted) {
        setState(() {
          _authError = error is AuthApiException
              ? error.message
              : 'Sign in failed. Please check your credentials and try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _openWorkspace() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => AppShell(authService: _authService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 960;

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop) const Expanded(flex: 11, child: _HeroTelemetryPanel()),
            Expanded(
              flex: isDesktop ? 9 : 1,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 48 : 20,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Container(
                      padding: EdgeInsets.all(isDesktop ? 36 : 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Mobile/Header Brand Tag
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const _BrandBadge(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.tealLight,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.shield_outlined,
                                        size: 13,
                                        color: AppTheme.teal,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'ENTERPRISE',
                                        style: TextStyle(
                                          color: AppTheme.tealDark,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),

                            // Heading
                            Text(
                              'Welcome back',
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Enter your credentials to access your fleet.',
                              style: TextStyle(
                                color: AppTheme.mutedInk,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Email Field
                            const _FieldLabel('Work email'),
                            Semantics(
                              container: true,
                              label: 'Work email',
                              textField: true,
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.username],
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: 'name@company.com',
                                  prefixIcon: Icon(
                                    Icons.alternate_email_rounded,
                                    size: 19,
                                    color: AppTheme.mutedInk,
                                  ),
                                ),
                                validator: (value) {
                                  final email = value?.trim() ?? '';
                                  if (email.isEmpty) {
                                    return 'Enter your work email.';
                                  }
                                  if (!RegExp(r'^.+@.+\..+$').hasMatch(email)) {
                                    return 'Enter a valid email address.';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Password Field
                            const _FieldLabel('Password'),
                            Semantics(
                              container: true,
                              label: 'Password',
                              textField: true,
                              child: TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: (_) => _signIn(),
                                decoration: InputDecoration(
                                  hintText: '••••••••••••',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 19,
                                    color: AppTheme.mutedInk,
                                  ),
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePassword
                                        ? 'Show password'
                                        : 'Hide password',
                                    onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword,
                                    ),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 19,
                                      color: AppTheme.mutedInk,
                                    ),
                                  ),
                                ),
                                validator: (value) => (value?.isEmpty ?? true)
                                    ? 'Enter a password to continue.'
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Error states
                            if (_authError != null) ...[
                              Semantics(
                                liveRegion: true,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFFCA5A5),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: Color(0xFFDC2626),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 9),
                                      Expanded(
                                        child: Text(
                                          _authError!,
                                          style: const TextStyle(
                                            color: Color(0xFF991B1B),
                                            fontSize: 12,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (_restoreError != null) ...[
                              Semantics(
                                liveRegion: true,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFFCA5A5),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _restoreError!,
                                        style: const TextStyle(
                                          color: Color(0xFF991B1B),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextButton.icon(
                                        onPressed: _isRestoring ? null : _restoreSession,
                                        icon: const Icon(Icons.refresh_rounded, size: 16),
                                        label: const Text(
                                          'Retry session restore',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        style: TextButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            // Cold-start progress bar if active
                            if (_isRestoring || _isSubmitting) ...[
                              const ServerRequestProgress(),
                              const SizedBox(height: 16),
                            ],

                            // Submit Button
                            SizedBox(
                              height: 48,
                              child: FilledButton.icon(
                                onPressed: _isSubmitting || _isRestoring ? null : _signIn,
                                icon: _isSubmitting || _isRestoring
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.arrow_forward_rounded, size: 18),
                                label: const Text('Sign in'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.teal,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Security Assurance Tag
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceAlt,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lock_rounded,
                                    size: 13,
                                    color: AppTheme.mutedInk,
                                  ),
                                  SizedBox(width: 7),
                                  Text(
                                    'Encrypted enterprise session',
                                    style: TextStyle(
                                      color: AppTheme.mutedInk,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Center(
                              child: Text(
                                '© Stark Fleet Systems',
                                style: TextStyle(
                                  color: AppTheme.subtleInk,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroTelemetryPanel extends StatelessWidget {
  const _HeroTelemetryPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.navy,
        borderRadius: BorderRadius.circular(28),
        gradient: const RadialGradient(
          center: Alignment(0.8, -0.6),
          radius: 1.4,
          colors: [
            Color(0xFF1E3A5F),
            Color(0xFF0F1E36),
            Color(0xFF0A1220),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Logo
          const _BrandBadge(isLight: true),
          const Spacer(flex: 2),

          // Eyebrow
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'FLEET TELEMETRY & OPERATIONS',
                style: TextStyle(
                  color: Color(0xFF67E8F9),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Headline
          const Text(
            'Complete visibility\nfor every asset.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: const Text(
              'Real-time vehicle register, status diagnostics, and centralized fleet controls built for enterprise precision.',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Live Operations Preview Card
          const Expanded(flex: 5, child: _LiveFleetHudCard()),
          const Spacer(),

          // Trust Badges
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF2DD4BF),
                size: 15,
              ),
              const SizedBox(width: 6),
              const Text(
                'Live Cloud Sync',
                style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
              ),
              const SizedBox(width: 20),
              const Icon(
                Icons.security_rounded,
                color: Color(0xFF2DD4BF),
                size: 15,
              ),
              const SizedBox(width: 6),
              const Text(
                'Multi-Tenant Isolation',
                style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
              ),
              const SizedBox(width: 20),
              const Icon(
                Icons.speed_rounded,
                color: Color(0xFF2DD4BF),
                size: 15,
              ),
              const SizedBox(width: 6),
              const Text(
                'Sub-second Latency',
                style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveFleetHudCard extends StatelessWidget {
  const _LiveFleetHudCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF132238).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HUD Top Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.teal.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.hub_outlined,
                      color: Color(0xFF2DD4BF),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OPERATIONS COMMAND',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'Automated Health & Status Monitor',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 6,
                      color: Color(0xFF10B981),
                    ),
                    SizedBox(width: 5),
                    Text(
                      'SYSTEM READY',
                      style: TextStyle(
                        color: Color(0xFF6EE7B7),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3 Metric HUD Tiles
          Row(
            children: [
              Expanded(
                child: _HudMetricTile(
                  label: 'OPERATIONAL',
                  value: '98.2%',
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HudMetricTile(
                  label: 'ACTIVE FLEET',
                  value: 'Ready',
                  icon: Icons.local_shipping_outlined,
                  color: const Color(0xFF0EA5E9),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HudMetricTile(
                  label: 'SERVICING',
                  value: 'Scheduled',
                  icon: Icons.build_circle_outlined,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Route Vector Canvas Preview
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: const Color(0xFF0A1424),
                child: CustomPaint(
                  painter: _HudGridPainter(),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _VehicleNodePill(
                          tag: 'METRO-401',
                          status: 'ACTIVE',
                          color: const Color(0xFF10B981),
                        ),
                        _VehicleNodePill(
                          tag: 'FREIGHT-88',
                          status: 'IN TRANSIT',
                          color: const Color(0xFF0EA5E9),
                        ),
                        _VehicleNodePill(
                          tag: 'LOGIX-12',
                          status: 'STANDBY',
                          color: const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HudMetricTile extends StatelessWidget {
  const _HudMetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleNodePill extends StatelessWidget {
  const _VehicleNodePill({
    required this.tag,
    required this.status,
    required this.color,
  });

  final String tag;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF132238),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamilyFallback: ['monospace', 'Courier'],
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(
                status,
                style: TextStyle(
                  color: color,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HudGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF1E3A5F).withValues(alpha: 0.25)
      ..strokeWidth = 1;

    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Connect node path
    final pathPaint = Paint()
      ..color = const Color(0xFF0EA5E9).withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.5)
      ..lineTo(size.width * 0.5, size.height * 0.5)
      ..lineTo(size.width * 0.8, size.height * 0.5);

    canvas.drawPath(path, pathPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BrandBadge extends StatelessWidget {
  const _BrandBadge({this.isLight = false});

  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final titleColor = isLight ? Colors.white : AppTheme.navy;
    final subtitleColor = isLight ? const Color(0xFF94A3B8) : AppTheme.mutedInk;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.teal,
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0EA5E9), Color(0xFF088395)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33088395),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_shipping_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'STARK',
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'FLEET',
              style: TextStyle(
                color: subtitleColor,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      label,
      style: const TextStyle(
        color: AppTheme.ink,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
