import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vms_frontend/app/app_shell.dart';
import 'package:vms_frontend/core/theme/app_theme.dart';
import 'package:vms_frontend/features/auth/data/auth_api_exception.dart';
import 'package:vms_frontend/features/auth/data/auth_service.dart';

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

  @override
  void initState() {
    super.initState();
    unawaited(_restoreSession());
  }

  Future<void> _restoreSession() async {
    final session = await _authService.restoreSession();
    if (!mounted) return;
    setState(() => _isRestoring = false);
    if (session != null) _openWorkspace();
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
      body: SafeArea(
        child: Row(
          children: [
            if (isWide) const Expanded(flex: 11, child: _WelcomePanel()),
            Expanded(
              flex: isWide ? 9 : 1,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 36,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!isWide) ...[
                            const _BrandLockup(dark: true),
                            const SizedBox(height: 44),
                          ],
                          Text(
                            'Welcome back',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sign in to your fleet workspace to continue.',
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
                              decoration: const InputDecoration(
                                hintText: 'name@company.com',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
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
                                  ),
                                ),
                              ),
                              validator: (value) => (value?.isEmpty ?? true)
                                  ? 'Enter a password to continue.'
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 26),
                          if (_authError != null) ...[
                            Semantics(
                              liveRegion: true,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3F2),
                                  borderRadius: BorderRadius.circular(10),
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
                          FilledButton(
                            onPressed: _isSubmitting || _isRestoring
                                ? null
                                : _signIn,
                            child: _isSubmitting || _isRestoring
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Sign in'),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF5F5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: AppTheme.teal,
                                  size: 19,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Sign in with your VMS account credentials.',
                                    style: TextStyle(fontSize: 13, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Center(
                            child: Text(
                              '© 2026 Stark Group',
                              style: TextStyle(fontSize: 12),
                            ),
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
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppTheme.navy,
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF142B45), Color(0xFF1B4965)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrandLockup(dark: false),
          const Spacer(),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Every journey,\nunder control.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 42,
              height: 1.1,
              letterSpacing: -1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'A clear view of your fleet, your teams, and the work that keeps you moving.',
            style: TextStyle(
              color: Color(0xFFD0DCE6),
              fontSize: 16,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 36),
          const Row(
            children: [
              _TrustPoint(
                icon: Icons.grid_view_rounded,
                label: 'One fleet view',
              ),
              SizedBox(width: 24),
              _TrustPoint(icon: Icons.route_rounded, label: 'Built for teams'),
            ],
          ),
          const Spacer(),
          const Text(
            'STARK GROUP  /  FLEET OPERATIONS',
            style: TextStyle(
              color: Color(0xFFB3C6D6),
              fontSize: 11,
              letterSpacing: 1.2,
            ),
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

class _TrustPoint extends StatelessWidget {
  const _TrustPoint({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: const Color(0xFF7FD1D2), size: 18),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
    ],
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
