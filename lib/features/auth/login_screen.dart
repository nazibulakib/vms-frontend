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
              : 'Sign in failed. Please try again.';
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
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          children: [
            if (isWide) const Expanded(flex: 11, child: _WelcomePanel()),
            Expanded(
              flex: isWide ? 9 : 1,
              child: Container(
                color: AppTheme.canvas,
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 44 : 22,
                      vertical: 28,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Form(
                        key: _formKey,
                        child: Container(
                          padding: EdgeInsets.all(isWide ? 34 : 26),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE8EDF2)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x10142B45),
                                blurRadius: 38,
                                offset: Offset(0, 18),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const _BrandLockup(dark: true),
                                  const Spacer(),
                                  _PortalBadge(compact: !isWide),
                                ],
                              ),
                              const SizedBox(height: 34),
                              Text(
                                'Welcome back',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontSize: 30,
                                      letterSpacing: -0.9,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Sign in to your fleet workspace to continue.',
                                style: TextStyle(
                                  color: AppTheme.mutedInk,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 30),
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
                                  decoration:
                                      const InputDecoration(
                                        hintText: 'name@company.com',
                                        prefixIcon: Icon(
                                          Icons.mail_outline_rounded,
                                        ),
                                      ).copyWith(
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                      ),
                                  validator: (value) {
                                    final email = value?.trim() ?? '';
                                    if (email.isEmpty) {
                                      return 'Enter your work email.';
                                    }
                                    if (!RegExp(r'^.+@.+\..+$')
                                        .hasMatch(email)) {
                                      return 'Enter a valid email address.';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
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
                                    hintText: 'Enter your password',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    suffixIcon: IconButton(
                                      tooltip: _obscurePassword
                                          ? 'Show password'
                                          : 'Hide password',
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: (value) => (value?.isEmpty ?? true)
                                      ? 'Enter a password to continue.'
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 22),
                              if (_authError != null) ...[
                                Semantics(
                                  liveRegion: true,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF4F2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFFED7D2),
                                      ),
                                    ),
                                    child: Text(
                                      _authError!,
                                      style: const TextStyle(
                                        color: Color(0xFFB42318),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (_restoreError != null) ...[
                                Semantics(
                                  liveRegion: true,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        _restoreError!,
                                        style: const TextStyle(
                                          color: Color(0xFFB42318),
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: _isRestoring
                                            ? null
                                            : _restoreSession,
                                        icon: const Icon(Icons.refresh_rounded),
                                        label: const Text(
                                          'Retry session restore',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (_isRestoring || _isSubmitting) ...[
                                const SizedBox(height: 16),
                                const ServerRequestProgress(),
                                const SizedBox(height: 16),
                              ],
                              SizedBox(
                                height: 54,
                                child: FilledButton.icon(
                                  onPressed: _isSubmitting || _isRestoring
                                      ? null
                                      : _signIn,
                                  icon: _isSubmitting || _isRestoring
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 19,
                                        ),
                                  label: Text(
                                    _authError == null
                                        ? 'Sign in'
                                        : 'Try again',
                                  ),
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const _SecureNote(),
                              const SizedBox(height: 26),
                              const Center(
                                child: Text(
                                  '© 2026 Stark Group',
                                  style: TextStyle(
                                    color: Color(0xFF98A2B3),
                                    fontSize: 12,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(42, 34, 42, 28),
      decoration: BoxDecoration(
        color: AppTheme.navy,
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10243B), Color(0xFF143C53), Color(0xFF087F8C)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -88,
            top: 80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: .08)),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _BrandLockup(dark: false),
                  const Spacer(),
                  _PortalBadge(compact: false, light: true),
                ],
              ),
              const Spacer(flex: 2),
              const _PanelEyebrow(),
              const SizedBox(height: 18),
              const Text(
                'A clearer view\nof every vehicle.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  height: 1.08,
                  letterSpacing: -1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              const SizedBox(
                width: 430,
                child: Text(
                  'Keep the details that move your operation together in one calm, focused workspace.',
                  style: TextStyle(
                    color: Color(0xFFD5E4E9),
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Expanded(flex: 5, child: _FleetPreview()),
              const Spacer(),
              const Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: Color(0xFF9ADCDD),
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'STARK GROUP  ·  FLEET OPERATIONS',
                    style: TextStyle(
                      color: Color(0xFFC3D6DC),
                      fontSize: 10,
                      letterSpacing: 1.15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = dark ? AppTheme.navy : Colors.white;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.teal,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.local_shipping_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STARK',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'FLEET',
              style: TextStyle(
                color: dark ? AppTheme.mutedInk : const Color(0xFFB3C6D6),
                fontSize: 10,
                letterSpacing: 2.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PortalBadge extends StatelessWidget {
  const _PortalBadge({required this.compact, this.light = false});

  final bool compact;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final foreground = light ? const Color(0xFFD9F3F1) : AppTheme.teal;
    final background = light
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFFE8F6F5);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 12,
        vertical: compact ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded, size: 14, color: foreground),
          if (!compact) ...[
            const SizedBox(width: 7),
            Text(
              'VMS WORKSPACE',
              style: TextStyle(
                color: foreground,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PanelEyebrow extends StatelessWidget {
  const _PanelEyebrow();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 24, height: 1, color: const Color(0xFF82D0D1)),
      const SizedBox(width: 10),
      const Text(
        'FLEET OPERATIONS, IN FOCUS',
        style: TextStyle(
          color: Color(0xFF9ADCDD),
          fontSize: 10,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _FleetPreview extends StatelessWidget {
  const _FleetPreview();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 500;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: CustomPaint(painter: _RoutePainter())),
              Positioned(
                right: compact ? -3 : 6,
                top: 0,
                child: _FloatingTag(compact: compact),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: constraints.maxWidth * (compact ? .97 : .91),
                  padding: EdgeInsets.all(compact ? 17 : 22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12324A).withValues(alpha: .88),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .18),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33091B2B),
                        blurRadius: 30,
                        offset: Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8BD2D0)
                                  .withValues(alpha: .16),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.local_shipping_rounded,
                              color: Color(0xFF9ADCDD),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 11),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FLEET OVERVIEW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'A single view of your vehicles',
                                  style: TextStyle(
                                    color: Color(0xFFB9CFD7),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.more_horiz_rounded,
                            color: Color(0xFFB9CFD7),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: .13),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: const [
                          _StatusTile(
                            label: 'ACTIVE',
                            color: Color(0xFF8BE0BB),
                            icon: Icons.check_circle_outline_rounded,
                          ),
                          _StatusTile(
                            label: 'IN MAINTENANCE',
                            color: Color(0xFFF4CC84),
                            icon: Icons.build_outlined,
                          ),
                          _StatusTile(
                            label: 'INACTIVE',
                            color: Color(0xFFB6C7D5),
                            icon: Icons.pause_circle_outline_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          for (var index = 0; index < 4; index++) ...[
                            Expanded(
                              child: Container(
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(
                                    alpha: index == 0 ? .62 : .14,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            if (index < 3) const SizedBox(width: 7),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: Colors.white.withValues(alpha: .08)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: .4,
          ),
        ),
      ],
    ),
  );
}

class _FloatingTag extends StatelessWidget {
  const _FloatingTag({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFD8F3EC),
      borderRadius: BorderRadius.circular(10),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22091B2B),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.route_rounded, color: AppTheme.teal, size: 15),
        if (!compact) ...[
          const SizedBox(width: 6),
          const Text(
            'BUILT FOR YOUR FLEET',
            style: TextStyle(
              color: AppTheme.navy,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: .6,
            ),
          ),
        ],
      ],
    ),
  );
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * .08, size.height * .75)
      ..cubicTo(
        size.width * .28,
        size.height * .16,
        size.width * .48,
        size.height * 1.08,
        size.width * .68,
        size.height * .46,
      )
      ..cubicTo(
        size.width * .79,
        size.height * .12,
        size.width * .87,
        size.height * .27,
        size.width * .98,
        size.height * .06,
      );
    final routePaint = Paint()
      ..color = Colors.white.withValues(alpha: .17)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, routePaint);
    for (final point in [
      Offset(size.width * .08, size.height * .75),
      Offset(size.width * .68, size.height * .46),
      Offset(size.width * .98, size.height * .06),
    ]) {
      canvas.drawCircle(point, 5, Paint()..color = const Color(0xFF9ADCDD));
      canvas.drawCircle(point, 10, Paint()..color = const Color(0x269ADCDD));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SecureNote extends StatelessWidget {
  const _SecureNote();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F8F8),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield_outlined, color: AppTheme.teal, size: 19),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Use your VMS account credentials to access your secure workspace.',
            style: TextStyle(
              color: AppTheme.mutedInk,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label, style: Theme.of(context).textTheme.labelLarge),
  );
}
