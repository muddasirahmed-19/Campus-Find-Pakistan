import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pinput/pinput.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId, phoneNumber, university;
  final int? resendToken;
  const OtpScreen({super.key, required this.verificationId, required this.phoneNumber, required this.university, this.resendToken});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  int _resendSeconds = 60;
  late String _verificationId;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendSeconds--);
      return _resendSeconds > 0;
    });
  }

  Future<void> _verifyOtp(String otp) async {
    if (otp.length != 6) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final credential = PhoneAuthProvider.credential(verificationId: _verificationId, smsCode: otp);
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) {
        Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.code == 'invalid-verification-code'
          ? 'Incorrect OTP. Please check and try again.'
          : e.code == 'session-expired'
            ? 'OTP expired. Please request a new one.'
            : 'Verification failed. Try again.';
      });
      _otpController.clear();
    }
  }

  Future<void> _resendOtp() async {
    if (_resendSeconds > 0) return;
    setState(() { _resendSeconds = 60; _errorMessage = null; });
    _startResendTimer();
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.phoneNumber,
      forceResendingToken: widget.resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (_) {},
      verificationFailed: (e) => setState(() => _errorMessage = 'Failed to resend OTP.'),
      codeSent: (String newId, int? token) {
        setState(() => _verificationId = newId);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent!')));
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  @override
  void dispose() { _otpController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final defaultPin = PinTheme(
      width: 56, height: 60,
      textStyle: AppTextStyles.headlineMedium.copyWith(color: AppColors.primary),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                child: const Icon(Icons.sms_outlined, color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: 24),
              Text('Verify Phone Number', style: AppTextStyles.headlineLarge, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('Enter the 6-digit code sent to',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(widget.phoneNumber, style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary)),
              const SizedBox(height: 40),
              Pinput(
                controller: _otpController,
                length: 6,
                defaultPinTheme: defaultPin,
                focusedPinTheme: defaultPin.copyWith(
                  decoration: defaultPin.decoration!.copyWith(
                    border: Border.all(color: AppColors.primary, width: 2),
                    color: AppColors.primaryLight.withOpacity(0.3),
                  ),
                ),
                errorPinTheme: defaultPin.copyWith(
                  decoration: defaultPin.decoration!.copyWith(
                    border: Border.all(color: AppColors.error, width: 2),
                  ),
                ),
                onCompleted: _verifyOtp,
                hapticFeedbackType: HapticFeedbackType.lightImpact,
                autofocus: true,
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.error))),
                  ]),
                ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _verifyOtp(_otpController.text),
                icon: _isLoading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.verified_outlined),
                label: Text(_isLoading ? 'Verifying...' : 'Verify OTP'),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _resendSeconds == 0 ? _resendOtp : null,
                child: RichText(text: TextSpan(
                  text: "Didn't receive the code? ",
                  style: AppTextStyles.bodySmall,
                  children: [TextSpan(
                    text: _resendSeconds > 0 ? 'Resend in ${_resendSeconds}s' : 'Resend OTP',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _resendSeconds > 0 ? AppColors.textHint : AppColors.primary,
                      fontWeight: FontWeight.w600),
                  )],
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}