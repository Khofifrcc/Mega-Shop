import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// OTP verification page matching the mockup.
///
/// Shows 6 PIN input boxes, a countdown timer, and a "VERIFY CODE" button.
class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _secondsLeft = 59;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 59);
    _startTimer();
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String get _otp =>
      _controllers.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.textPrimary),
              ),
              const Spacer(flex: 2),
              // Lock icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded,
                      color: AppColors.primary, size: 36),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text('Verification',
                    style: AppTextStyles.sectionTitle.copyWith(fontSize: 28)),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('Enter the code sent to your phone',
                    style: AppTextStyles.brandName.copyWith(fontSize: 14)),
              ),
              const SizedBox(height: 36),
              // ── PIN boxes ────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _PinBox(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  onChanged: (v) => _onChanged(v, i),
                )),
              ),
              const SizedBox(height: 24),
              // ── Resend timer ─────────────────────────────────────────────
              Center(
                child: _secondsLeft > 0
                    ? RichText(
                        text: TextSpan(
                          style: AppTextStyles.brandName.copyWith(fontSize: 13),
                          children: [
                            const TextSpan(text: 'Resend code in '),
                            TextSpan(
                              text:
                                  '00:${_secondsLeft.toString().padLeft(2, '0')}',
                              style: AppTextStyles.brandName.copyWith(
                                  fontSize: 13, color: AppColors.accent),
                            ),
                          ],
                        ),
                      )
                    : GestureDetector(
                        onTap: _resetTimer,
                        child: Text(
                          'Resend Code',
                          style: AppTextStyles.brandName.copyWith(
                              fontSize: 13,
                              color: AppColors.primary,
                              decoration: TextDecoration.underline),
                        ),
                      ),
              ),
              const SizedBox(height: 32),
              // ── Verify button ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_otp.length == 6) {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                    elevation: 0,
                  ),
                  child: Text('VERIFY CODE',
                      style: AppTextStyles.buttonFilled
                          .copyWith(fontSize: 15, letterSpacing: 1.2)),
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _PinBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLength: 1,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        style: AppTextStyles.sectionTitle.copyWith(fontSize: 22),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: focusNode.hasFocus
              ? AppColors.surface
              : AppColors.primarySurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: focusNode.hasFocus
                  ? AppColors.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }
}
