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

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService.instance;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _logoScaleAnimation;

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _isRestoring = true;
  String? _authError;
  String? _restoreError;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.85, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _logoScaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _animController.forward();
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
    _animController.dispose();
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
    return Scaffold(
      backgroundColor: const Color(0xFF0A192F),
      body: Stack(
        children: [
          // Dynamic Atmospheric Fleet Background
          Positioned.fill(
            child: CustomPaint(
              painter: _FleetTechBackgroundPainter(),
            ),
          ),

          // Ambient Radial Light Cones
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0052CC).withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -120,
            child: Container(
              width: 550,
              height: 550,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF002D62).withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Centered Content with Smooth Staggered Animation
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header Logo Lockup
                          ScaleTransition(
                            scale: _logoScaleAnimation,
                            child: const _StarkBrandHeader(),
                          ),
                          const SizedBox(height: 24),

                          // Main Login Card
                          Container(
                            padding: const EdgeInsets.fromLTRB(32, 30, 32, 28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x38001F3F),
                                  blurRadius: 40,
                                  offset: Offset(0, 18),
                                ),
                                BoxShadow(
                                  color: Color(0x180052CC),
                                  blurRadius: 16,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Form Title
                                  const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.ink,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Sign in to access your fleet operations.',
                                    style: TextStyle(
                                      color: AppTheme.mutedInk,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Username Field
                                  const _FieldLabel('Username'),
                                  Semantics(
                                    container: true,
                                    label: 'Work email',
                                    textField: true,
                                    child: TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      autofillHints: const [AutofillHints.username],
                                      textInputAction: TextInputAction.next,
                                      decoration: InputDecoration(
                                        hintText: 'e.g. admin@stark.com',
                                        prefixIcon: const Icon(
                                          Icons.person_outline_rounded,
                                          size: 19,
                                          color: AppTheme.mutedInk,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 13,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                            color: AppTheme.border,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                            color: AppTheme.border,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                            color: AppTheme.starkBlue,
                                            width: 1.8,
                                          ),
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
                                        hintText: '••••••••',
                                        prefixIcon: const Icon(
                                          Icons.lock_outline_rounded,
                                          size: 19,
                                          color: AppTheme.mutedInk,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 13,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                            color: AppTheme.border,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                            color: AppTheme.border,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                            color: AppTheme.starkBlue,
                                            width: 1.8,
                                          ),
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
                                  const SizedBox(height: 22),

                                  // Error message if present
                                  if (_authError != null) ...[
                                    Semantics(
                                      liveRegion: true,
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFEBE6),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: const Color(0xFFFFBDAD),
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              Icons.error_outline_rounded,
                                              color: Color(0xFFDE350B),
                                              size: 17,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _authError!,
                                                style: const TextStyle(
                                                  color: Color(0xFFBF2600),
                                                  fontSize: 12,
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
                                          color: const Color(0xFFFFEBE6),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: const Color(0xFFFFBDAD),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _restoreError!,
                                              style: const TextStyle(
                                                color: Color(0xFFBF2600),
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            TextButton.icon(
                                              onPressed: _isRestoring
                                                  ? null
                                                  : _restoreSession,
                                              icon: const Icon(
                                                Icons.refresh_rounded,
                                                size: 15,
                                              ),
                                              label: const Text(
                                                'Retry session restore',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                visualDensity:
                                                    VisualDensity.compact,
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

                                  // Primary Login Action Button
                                  SizedBox(
                                    height: 46,
                                    child: FilledButton(
                                      onPressed:
                                          _isSubmitting || _isRestoring
                                              ? null
                                              : _signIn,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppTheme.starkBlue,
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        shadowColor: const Color(0x330052CC),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: _isSubmitting || _isRestoring
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Login',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Footnote Security Tag
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Secure Enterprise Portal',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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
    );
  }
}

class _StarkBrandHeader extends StatelessWidget {
  const _StarkBrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Official Stark Automotive Fleet Logo
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF172F54),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF00D2FF).withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x660052CC),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
              BoxShadow(
                color: Color(0x3300D2FF),
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/stark_logo.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.directions_car_filled_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Brand Name: STARK
        const Text(
          'STARK',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 3),

        // Text: Vehicle Management System
        Text(
          'Vehicle Management System',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _FleetTechBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base Gradient Canvas matching logo navy tones
    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0F223D),
          Color(0xFF172F54),
          Color(0xFF091629),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // 2. Telemetry Tech Grid Lines
    final gridPaint = Paint()
      ..color = const Color(0xFF00D2FF).withValues(alpha: 0.06)
      ..strokeWidth = 1.0;

    const gridSize = 40.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 3. Grid Intersection Nodes
    final nodePaint = Paint()
      ..color = const Color(0xFF00D2FF).withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    for (double x = gridSize; x < size.width; x += gridSize * 3) {
      for (double y = gridSize; y < size.height; y += gridSize * 3) {
        canvas.drawCircle(Offset(x, y), 1.5, nodePaint);
      }
    }

    // 4. Subtle Ambient Highway / Route Vector Curves
    final routePaint = Paint()
      ..color = const Color(0xFF00D2FF).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final route1 = Path()
      ..moveTo(0, size.height * 0.75)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.65,
        size.width * 0.6,
        size.height * 0.9,
        size.width,
        size.height * 0.8,
      );
    canvas.drawPath(route1, routePaint);

    final route2 = Path()
      ..moveTo(0, size.height * 0.3)
      ..cubicTo(
        size.width * 0.4,
        size.height * 0.2,
        size.width * 0.7,
        size.height * 0.45,
        size.width,
        size.height * 0.35,
      );
    canvas.drawPath(route2, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
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
