import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:vitalsync/core/auth/auth_provider.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/core/services/biometric_service.dart';
import 'package:vitalsync/core/settings/settings_provider.dart';
import 'package:vitalsync/domain/repositories/shared/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  final _biometricService = GetIt.instance<BiometricService>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref
            .read(authProvider.notifier)
            .signIn(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );
        // Navigation is handled by auth state listener ideally, but for now we can force it
        // Check if mounted
        if (mounted) {
          context.go('/dashboard');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).loginFailed(e)),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    final l10n = AppLocalizations.of(context);
    try {
      final authenticated = await _biometricService.authenticate(
        reason: l10n.biometricLogin,
      );
      if (!authenticated || !mounted) return;

      // Verify auth session is still valid before navigating
      final authRepo = GetIt.instance<AuthRepository>();
      final currentUser = authRepo.currentUser;
      if (currentUser == null) {
        // No cached auth user — biometric alone is not enough
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.loginFailed('Session expired'))),
          );
        }
        return;
      }

      context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.loginFailed(e))),
        );
      }
    }
  }

  Future<void> _handleAppleLogin() async {
    try {
      await ref.read(authProvider.notifier).signInWithApple();
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).appleLoginFailed(e)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth loading state if needed
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Background — uses theme's primary/tertiary containers for adaptive theming
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.tertiaryContainer,
                ],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.health_and_safety,
                        size: 64,
                        color: colorScheme.primary,
                      ).animate().scale(duration: 600.ms),
                      const SizedBox(height: 24),
                      Text(
                        l10n.welcomeBack,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ).animate().fadeIn().moveY(begin: 10, end: 0),
                      const SizedBox(height: 8),
                      Text(
                        l10n.signInSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 48),

                      // Email Field
                      _GlassTextField(
                        controller: _emailController,
                        label: l10n.email,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.enterEmail;
                          }
                          // Basic email format check
                          final emailRegex = RegExp(
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                          );
                          if (!emailRegex.hasMatch(value.trim())) {
                            return l10n.invalidEmail;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      _GlassTextField(
                        controller: _passwordController,
                        label: l10n.password,
                        icon: Icons.lock_outline,
                        obscureText: !_isPasswordVisible,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.enterPassword;
                          }
                          return null;
                        },
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: colorScheme.outline,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              context.push('/auth/forgot-password'),
                          child: Text(l10n.forgotPassword),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Login Button — uses colorScheme for adaptive theming
                      ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l10n.logIn,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              l10n.orSeparator,
                              style: TextStyle(color: colorScheme.outline),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Apple Sign In
                      OutlinedButton.icon(
                        onPressed: isLoading ? null : _handleAppleLogin,
                        icon: const Icon(Icons.apple, size: 28),
                        label: Text(l10n.continueWithApple),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(color: colorScheme.outline),
                        ),
                      ),

                      // Biometric Login
                      _BiometricLoginButton(
                        biometricService: _biometricService,
                        isLoading: isLoading,
                        onPressed: _handleBiometricLogin,
                      ),

                      const SizedBox(height: 24),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.dontHaveAccount,
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                          TextButton(
                            onPressed: () => context.go('/auth/register'),
                            child: Text(l10n.signUp),
                          ),
                        ],
                      ),
                    ],
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

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,
  });
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
          hintText: label,
          hintStyle: TextStyle(color: colorScheme.outline),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}

/// Shows biometric login button only when device supports it and user enabled it.
class _BiometricLoginButton extends ConsumerStatefulWidget {
  const _BiometricLoginButton({
    required this.biometricService,
    required this.isLoading,
    required this.onPressed,
  });

  final BiometricService biometricService;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  ConsumerState<_BiometricLoginButton> createState() =>
      _BiometricLoginButtonState();
}

class _BiometricLoginButtonState extends ConsumerState<_BiometricLoginButton> {
  bool _isAvailable = false;
  IconData _biometricIcon = Icons.fingerprint;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await widget.biometricService.isAvailable();
    if (!available || !mounted) return;

    final types = await widget.biometricService.getAvailableBiometrics();
    setState(() {
      _isAvailable = true;
      _biometricIcon = types.contains(BiometricType.face)
          ? Icons.face
          : Icons.fingerprint;
    });
  }

  @override
  Widget build(BuildContext context) {
    final biometricEnabled = ref.watch(biometricSettingProvider);

    if (!_isAvailable || !biometricEnabled) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: OutlinedButton.icon(
        onPressed: widget.isLoading ? null : widget.onPressed,
        icon: Icon(_biometricIcon, size: 28),
        label: Text(l10n.biometricLogin),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}
