import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/validators/app_validators.dart';
import '../../core/constants/app_constants.dart';
import 'otp_screen.dart';
import 'email_signup_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});
  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  String? _selectedUniversity;
  bool _isLoading  = false;
  String? _errorMessage;

  @override
  void dispose() { _phoneCtrl.dispose(); super.dispose(); }

  String get _fullPhone => AppValidators.normalizePhone(_phoneCtrl.text.trim());

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUniversity == null) {
      setState(() => _errorMessage = 'Please select your university');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _fullPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential cred) async {
          await FirebaseAuth.instance.signInWithCredential(cred);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() { _isLoading = false; _errorMessage = _mapError(e.code); });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _isLoading = false);
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => OtpScreen(
              verificationId: verificationId,
              phoneNumber: _fullPhone,
              university: _selectedUniversity!,
              resendToken: resendToken,
            ),
          ));
        },
        codeAutoRetrievalTimeout: (_) => setState(() => _isLoading = false),
      );
    } catch (_) {
      setState(() { _isLoading = false; _errorMessage = 'Something went wrong. Try again.'; });
    }
  }

  String _mapError(String code) {
    switch (code) {
      case 'invalid-phone-number':    return 'Invalid phone number. Use format: 03XXXXXXXXX';
      case 'too-many-requests':       return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':  return 'No internet connection.';
      default: return 'Failed to send OTP. Try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0, title: const Text('Sign In')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome Back 👋', style: AppTextStyles.headlineLarge),
                const SizedBox(height: 8),
                Text('Enter your phone number to continue',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 32),

                Text('Phone Number', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  decoration: InputDecoration(
                    hintText: '03001234567',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    prefixText: '+92  ',
                    prefixStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                    counterText: '${_phoneCtrl.text.length}/11',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: AppValidators.phone,
                ),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.info_outline, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text('Pakistani numbers only: 03XXXXXXXXX', style: AppTextStyles.caption),
                ]),
                const SizedBox(height: 24),

                Text('University', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedUniversity,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    hintText: 'Select your university',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  items: AppUniversities.all.map((u) => DropdownMenuItem(
                    value: u.shortName,
                    child: Text('${u.shortName} — ${u.city}', style: AppTextStyles.bodyMedium),
                  )).toList(),
                  onChanged: (v) => setState(() { _selectedUniversity = v; _errorMessage = null; }),
                  validator: (v) => v == null ? 'Please select your university' : null,
                ),
                const SizedBox(height: 32),

                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMessage!,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.error))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _sendOtp,
                  icon: _isLoading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded),
                  label: Text(_isLoading ? 'Sending OTP...' : 'Send OTP'),
                ),
                const SizedBox(height: 24),

                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('or', style: AppTextStyles.caption),
                  ),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 24),

                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EmailSignupScreen())),
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Continue with Email'),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Text.rich(TextSpan(
                    text: 'By continuing you agree to our ',
                    style: AppTextStyles.caption,
                    children: [
                      TextSpan(text: 'Terms of Service',
                        style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      const TextSpan(text: ' and '),
                      TextSpan(text: 'Privacy Policy',
                        style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ],
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}