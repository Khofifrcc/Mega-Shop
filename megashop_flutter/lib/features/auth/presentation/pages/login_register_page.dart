import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Login / Register page.
///
/// Uses index-based tab switching (NOT TabBarView) to avoid the
/// "Cannot hit test a render box that has never been laid out" error
/// that occurs when TabBarView is inside SingleChildScrollView.
class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage> {
  int _tabIndex = 1; // 0 = Login, 1 = Register
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Helper: styled snackbar ──────────────────────────────────────────────────

  void _showSnackBar(String message,
      {bool isError = true, IconData? icon}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        duration: const Duration(seconds: 4),
        backgroundColor: isError
            ? const Color(0xFFD32F2F)
            : const Color(0xFF2E7D32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Icon(
              icon ??
                  (isError
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded),
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Validation ───────────────────────────────────────────────────────────────

  /// Returns an error string if invalid, null if valid.
  String? _validateFields() {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (email.isEmpty) return 'Please enter your email address.';

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address (e.g. user@email.com).';
    }

    if (pass.isEmpty) return 'Please enter your password.';

    if (_tabIndex == 1 && pass.length < 6) {
      return 'Password must be at least 6 characters long.';
    }

    return null;
  }

  // ── Google Sign-In ───────────────────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    try {
      setState(() => _isLoading = true);

      UserCredential userCredential;

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        userCredential =
            await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        await GoogleSignIn.instance.initialize();
        final googleUser = await GoogleSignIn.instance.authenticate();
        final googleAuth = googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
      }

      final user = userCredential.user;
      if (user != null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      _showSnackBar('Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Login ────────────────────────────────────────────────────────────────────

  Future<void> login() async {
    // Client-side validation first
    final validationError = _validateFields();
    if (validationError != null) {
      _showSnackBar(validationError);
      return;
    }

    try {
      setState(() => _isLoading = true);

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'user-not-found':
          message =
              'No account found with this email. Please register first.';
          break;
        case 'wrong-password':
          message = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          message =
              'Invalid email format. Please check your email address.';
          break;
        case 'invalid-credential':
          message =
              'Incorrect email or password. Please double-check and try again.';
          break;
        case 'user-disabled':
          message =
              'This account has been disabled. Please contact support.';
          break;
        case 'too-many-requests':
          message =
              'Too many failed attempts. Please wait a moment and try again.';
          break;
        default:
          message = 'Login failed. Please try again later.';
      }

      _showSnackBar(message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Register ─────────────────────────────────────────────────────────────────

  Future<void> register() async {
    // Client-side validation first
    final validationError = _validateFields();
    if (validationError != null) {
      _showSnackBar(validationError);
      return;
    }

    try {
      setState(() => _isLoading = true);

      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      final user = userCredential.user;

      if (user != null) {
        // Try to sync user to backend (non-blocking — failure is ignored)
        try {
          await http.post(
            Uri.parse('http://127.0.0.1:8000/users/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'firebase_uid': user.uid,
              'username': _emailCtrl.text.split('@')[0],
              'email': _emailCtrl.text.trim(),
              'bio': '',
              'profile_photo': '',
            }),
          ).timeout(const Duration(seconds: 5));
        } catch (_) {
          // Backend unreachable — not a blocker for the user
        }

        // Sign out so user must log in manually
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          // Keep email, clear password, switch to Login tab
          _passCtrl.clear();
          setState(() => _tabIndex = 0);

          _showSnackBar(
            'Account created! Please sign in with your new credentials.',
            isError: false,
            icon: Icons.check_circle_outline_rounded,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message =
              'This email is already registered. Try logging in instead.';
          break;
        case 'weak-password':
          message =
              'Password is too weak. Use at least 6 characters with a mix of letters and numbers.';
          break;
        case 'invalid-email':
          message =
              'Invalid email format. Please enter a valid email address.';
          break;
        case 'operation-not-allowed':
          message =
              'Email/password registration is not enabled. Please contact support.';
          break;
        default:
          message = 'Registration failed. Please try again later.';
      }

      _showSnackBar(message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // ── Top row ───────────────────────────────────────────────
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  ),
                  Expanded(
                    child: Center(
                        child: Text('MegaShop', style: AppTextStyles.appLogo)),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 24),
              // ── Tab switcher ──────────────────────────────────────────
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    _TabButton(
                      label: 'Login',
                      isActive: _tabIndex == 0,
                      onTap: () => setState(() => _tabIndex = 0),
                    ),
                    _TabButton(
                      label: 'Register',
                      isActive: _tabIndex == 1,
                      onTap: () => setState(() => _tabIndex = 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // ── Form card ─────────────────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _tabIndex == 0
                    ? _FormCard(
                        key: const ValueKey('login'),
                        title: 'Welcome Back',
                        subtitle: 'Sign in to continue shopping.',
                        emailCtrl: _emailCtrl,
                        passCtrl: _passCtrl,
                        obscurePass: _obscurePass,
                        onTogglePass: () =>
                            setState(() => _obscurePass = !_obscurePass),
                        ctaLabel: 'Sign In',
                        onCta: login,
                        isRegister: false,
                        isLoading: _isLoading,
                      )
                    : _FormCard(
                        key: const ValueKey('register'),
                        title: 'Create Account',
                        subtitle:
                            'Join the ultimate shopping experience today.',
                        emailCtrl: _emailCtrl,
                        passCtrl: _passCtrl,
                        obscurePass: _obscurePass,
                        onTogglePass: () =>
                            setState(() => _obscurePass = !_obscurePass),
                        ctaLabel: 'Create Account',
                        onCta: register,
                        isRegister: true,
                        isLoading: _isLoading,
                      ),
              ),
              const SizedBox(height: 24),
              // ── OR divider ────────────────────────────────────────────
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.divider)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or continue with',
                        style: AppTextStyles.brandName),
                  ),
                  const Expanded(child: Divider(color: AppColors.divider)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SocialButton(
                      label: 'Google',
                      icon: Image.network(
                        'https://cdn-icons-png.flaticon.com/512/300/300221.png',
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Text(
                          'G',
                          style: AppTextStyles.productName.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      onTap: signInWithGoogle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SocialButton(
                      label: 'Apple',
                      icon: Image.network(
                        'https://cdn-icons-png.flaticon.com/512/0/747.png',
                        width: 20,
                        height: 20,
                        color: AppColors.textPrimary,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.apple,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab button ────────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isActive ? AppColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(26),
              boxShadow: isActive
                  ? const [
                      BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 8,
                          offset: Offset(0, 2))
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                label,
                style: isActive
                    ? AppTextStyles.categoryActive
                        .copyWith(color: AppColors.primary)
                    : AppTextStyles.categoryInactive,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Form card ─────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscurePass;
  final VoidCallback onTogglePass;
  final String ctaLabel;
  final VoidCallback onCta;
  final bool isRegister;
  final bool isLoading;

  const _FormCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscurePass,
    required this.onTogglePass,
    required this.ctaLabel,
    required this.onCta,
    required this.isRegister,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 16,
              offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(title,
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 24)),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(subtitle,
                style: AppTextStyles.brandName.copyWith(fontSize: 13),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 24),
          _AuthField(
            controller: emailCtrl,
            hint: 'Email Address',
            icon: CupertinoIcons.mail,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _AuthField(
            controller: passCtrl,
            hint: isRegister
                ? 'Password (min. 6 characters)'
                : 'Password',
            icon: CupertinoIcons.lock,
            obscure: obscurePass,
            suffix: IconButton(
              onPressed: onTogglePass,
              icon: Icon(
                obscurePass
                    ? CupertinoIcons.eye_slash
                    : CupertinoIcons.eye,
                color: AppColors.iconMuted,
                size: 20,
              ),
            ),
          ),
          if (isRegister) ...[
            const SizedBox(height: 10),
            // Password hint
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.info,
                      size: 13, color: AppColors.iconMuted),
                  const SizedBox(width: 6),
                  Text(
                    'Use letters, numbers, and symbols for a strong password.',
                    style: AppTextStyles.brandName.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyles.brandName.copyWith(fontSize: 12),
                  children: [
                    const TextSpan(text: 'By registering, you agree to our '),
                    TextSpan(
                      text: 'Terms',
                      style: AppTextStyles.brandName.copyWith(
                          fontSize: 12,
                          color: AppColors.primary,
                          decoration: TextDecoration.underline),
                    ),
                    const TextSpan(text: ' & '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: AppTextStyles.brandName.copyWith(
                          fontSize: 12,
                          color: AppColors.primary,
                          decoration: TextDecoration.underline),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : onCta,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(ctaLabel,
                            style: AppTextStyles.buttonFilled
                                .copyWith(fontSize: 16)),
                        const SizedBox(width: 8),
                        const Icon(CupertinoIcons.arrow_right,
                            color: AppColors.textOnPrimary, size: 20),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Auth text field ───────────────────────────────────────────────────────────

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: AppTextStyles.productName.copyWith(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.brandName.copyWith(fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.iconMuted, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.primarySurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ── Social login button ───────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;

  const _SocialButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 8),
              Text(label,
                  style: AppTextStyles.productName.copyWith(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
