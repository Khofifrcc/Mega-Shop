import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
      print("GOOGLE ERROR");
      print(e);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> login() async {
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
      String message = 'Terjadi kesalahan';

      if (e.code == 'user-not-found') {
        message = 'No account found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        message = 'Email not found';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid email or password';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> register() async {
    try {
      setState(() => _isLoading = true);

      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      final user = userCredential.user;

      if (user != null) {
        await http.post(
          Uri.parse('http://127.0.0.1:8000/users/'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'firebase_uid': user.uid,
            'username': _emailCtrl.text.split('@')[0],
            'email': _emailCtrl.text.trim(),
            'bio': '',
            'profile_photo': '',
          }),
        );

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Registrasi gagal';

      if (e.code == 'email-already-in-use') {
        message = 'This email is already in use';
      } else if (e.code == 'weak-password') {
        message = 'Password must be at least 6 characters';
      } else if (e.code == 'invalid-email') {
        message = 'Incorrect email format';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
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
              // ── Form card (index-based, no TabBarView) ────────────────
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
                        ctaLabel: 'Masuk',
                        onCta: login,
                        isRegister: false,
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
                        ctaLabel: 'Daftar Sekarang',
                        onCta: register,
                        isRegister: true,
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
                      icon: Icons.g_mobiledata_rounded,
                      onTap: signInWithGoogle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SocialButton(
                      label: 'Apple',
                      icon: Icons.apple_rounded,
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

// ── Tab button (replaces TabBar — no TabBarView needed) ───────────────────────

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
            hint: 'Email or Phone Number',
            icon: Icons.mail_outline_rounded,
          ),
          const SizedBox(height: 12),
          _AuthField(
            controller: passCtrl,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            obscure: obscurePass,
            suffix: IconButton(
              onPressed: onTogglePass,
              icon: Icon(
                obscurePass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.iconMuted,
                size: 20,
              ),
            ),
          ),
          if (isRegister) ...[
            const SizedBox(height: 12),
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
              onPressed: onCta,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(ctaLabel,
                      style: AppTextStyles.buttonFilled.copyWith(fontSize: 16)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded,
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

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
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
  final IconData icon;
  final VoidCallback onTap;

  const _SocialButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            Text(label,
                style: AppTextStyles.productName.copyWith(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
