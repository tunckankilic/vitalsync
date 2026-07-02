import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitalsync/core/auth/auth_provider.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';

/// Arguments for [ConfirmSignUpScreen], passed through the router's `extra`.
class ConfirmSignUpArgs {
  const ConfirmSignUpArgs({required this.email, this.password});

  final String email;

  /// When set (arriving straight from registration or a login attempt), a
  /// successful confirmation signs the user in automatically. Held in memory
  /// only — never persisted.
  final String? password;
}

/// Sign-up email verification screen.
///
/// Cognito creates email/password accounts in the UNCONFIRMED state and emails
/// a verification code; this screen collects that code and completes the
/// registration. Reached from [RegisterScreen] right after sign-up, and from
/// [LoginScreen] when an unconfirmed user tries to log in.
class ConfirmSignUpScreen extends ConsumerStatefulWidget {
  const ConfirmSignUpScreen({required this.email, this.password, super.key});

  final String email;
  final String? password;

  @override
  ConsumerState<ConfirmSignUpScreen> createState() =>
      _ConfirmSignUpScreenState();
}

class _ConfirmSignUpScreenState extends ConsumerState<ConfirmSignUpScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;

    // Captured before any await so we never touch context across async gaps.
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref
          .read(authProvider.notifier)
          .confirmSignUp(widget.email, _codeController.text.trim());
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.verificationFailed(e))),
      );
      return;
    }

    // Verified. Sign in automatically while we still hold the password from
    // the registration/login form; otherwise hand over to the login screen.
    final password = widget.password;
    if (password != null && password.isNotEmpty) {
      try {
        await ref.read(authProvider.notifier).signIn(widget.email, password);
        if (mounted) context.go('/dashboard');
        return;
      } catch (_) {
        // Fall through to the manual login path below.
      }
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.emailVerifiedPleaseLogin)),
    );
    if (mounted) context.go('/auth/login');
  }

  Future<void> _handleResend() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(authProvider.notifier).resendSignUpCode(widget.email);
      messenger.showSnackBar(SnackBar(content: Text(l10n.codeResent)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.resendCodeFailed(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: () => context.go('/auth/login'),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE3F2FD), Color(0xFFF3E5F5)],
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
                        Icons.mark_email_read_outlined,
                        size: 64,
                        color: Theme.of(context).primaryColor,
                      ).animate().fadeIn().scale(),
                      const SizedBox(height: 24),
                      Text(
                        l10n.verifyEmailTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ).animate().fadeIn().moveY(begin: 10, end: 0),
                      const SizedBox(height: 8),
                      Text(
                        l10n.verifyEmailSubtitle(widget.email),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 48),

                      // Verification Code Field
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 6,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                          validator: (value) {
                            final code = value?.trim() ?? '';
                            if (code.isEmpty) {
                              return l10n.enterVerificationCode;
                            }
                            if (code.length < 6) {
                              return l10n.verificationCodeTooShort;
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: l10n.verificationCode,
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              letterSpacing: 0,
                            ),
                            counterText: '',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Verify Button
                      ElevatedButton(
                        onPressed: isLoading ? null : _handleConfirm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
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
                                l10n.verifyButton,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),

                      const SizedBox(height: 24),

                      // Resend Code
                      TextButton(
                        onPressed: isLoading ? null : _handleResend,
                        child: Text(l10n.resendCode),
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
