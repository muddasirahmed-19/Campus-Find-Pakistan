import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/validators/app_validators.dart';
import '../../core/constants/app_constants.dart';
import '../home/home_screen.dart';

class EmailSignupScreen extends StatefulWidget {
  const EmailSignupScreen({super.key});
  @override
  State<EmailSignupScreen> createState() => _EmailSignupScreenState();
}

class _EmailSignupScreenState extends State<EmailSignupScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  String? _selectedUniversity;
  bool _isLoading = false, _showPass = false, _showConfirm = false, _isSignIn = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      if (_isSignIn) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(), password: _passCtrl.text);
        if (mounted) Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(), password: _passCtrl.text);
        await cred.user?.updateDisplayName(_nameCtrl.text.trim());
        await cred.user?.sendEmailVerification();
        if (mounted) _showVerificationDialog();
      }
    } on FirebaseAuthException catch (e) {
      setState(() { _isLoading = false; _errorMessage = _mapError(e.code); });
    }
  }

  String _mapError(String code) {
    switch (code) {
      case 'email-already-in-use':   return 'This email is already registered. Try signing in.';
      case 'invalid-email':          return 'Invalid email address.';
      case 'weak-password':          return 'Password is too weak.';
      case 'user-not-found':         return 'No account found with this email.';
      case 'wrong-password':         return 'Incorrect password.';
      case 'invalid-credential':     return 'Incorrect email or password.';
      case 'too-many-requests':      return 'Too many attempts. Please wait.';
      case 'network-request-failed': return 'No internet connection.';
      default: return 'Something went wrong. Please try again.';
    }
  }

  void _showVerificationDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (_) =>
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Verify Your Email 📧'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.mark_email_unread_outlined, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          Text('We sent a verification link to:\n${_emailCtrl.text.trim()}',
            textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          Text('Please check your inbox and verify your email before signing in.',
            textAlign: TextAlign.center, style: AppTextStyles.bodySmall),
        ]),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); setState(() { _isSignIn = true; _isLoading = false; }); },
            child: const Text('I Verified, Sign In'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: AppTextStyles.labelLarge),
  );

  @override
  Widget build(BuildContext context) {
    final strength = PasswordStrengthChecker.check(_passCtrl.text);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isSignIn ? 'Welcome Back 👋' : 'Create Account 🎓', style: AppTextStyles.headlineLarge),
                const SizedBox(height: 8),
                Text(_isSignIn ? 'Sign in to your CampusFind account' : 'Join your campus lost & found community',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Row(children: [
                  Text(_isSignIn ? 'New to CampusFind? ' : 'Already have an account? ', style: AppTextStyles.bodySmall),
                  GestureDetector(
                    onTap: () => setState(() { _isSignIn = !_isSignIn; _errorMessage = null; }),
                    child: Text(_isSignIn ? 'Create account' : 'Sign in',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 32),

                if (!_isSignIn) ...[
                  _label('Full Name'),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'Muhammad Ali', prefixIcon: Icon(Icons.person_outline)),
                    validator: AppValidators.fullName,
                  ),
                  const SizedBox(height: 16),
                  _label('Phone Number (optional)'),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(hintText: '03001234567', prefixText: '+92  ', prefixIcon: Icon(Icons.phone_outlined)),
                    validator: (v) => v != null && v.isNotEmpty ? AppValidators.phone(v) : null,
                  ),
                  const SizedBox(height: 16),
                  _label('University'),
                  DropdownButtonFormField<String>(
                    value: _selectedUniversity,
                    isExpanded: true,
                    decoration: const InputDecoration(hintText: 'Select your university', prefixIcon: Icon(Icons.school_outlined)),
                    items: AppUniversities.all.map((u) => DropdownMenuItem(
                      value: u.shortName,
                      child: Text('${u.shortName} — ${u.city}', style: AppTextStyles.bodyMedium))).toList(),
                    onChanged: (v) => setState(() => _selectedUniversity = v),
                    validator: (v) => v == null ? 'Please select your university' : null,
                  ),
                  const SizedBox(height: 16),
                ],

                _label('Email Address'),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'you@example.com', prefixIcon: Icon(Icons.email_outlined)),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim()))
                      return 'Enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _label('Password'),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: !_showPass,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: _isSignIn ? 'Your password' : 'Min 8 chars, 1 upper, 1 number, 1 special',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _showPass = !_showPass)),
                  ),
                  validator: _isSignIn
                    ? (v) => v == null || v.isEmpty ? 'Password is required' : null
                    : AppValidators.password,
                ),

                if (!_isSignIn && _passCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: LinearProgressIndicator(
                      value: strength == PasswordStrength.weak ? 0.33 : strength == PasswordStrength.medium ? 0.66 : 1.0,
                      color: strength == PasswordStrength.weak ? AppColors.error : strength == PasswordStrength.medium ? AppColors.accent : AppColors.secondary,
                      backgroundColor: AppColors.border, minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    )),
                    const SizedBox(width: 8),
                    Text(PasswordStrengthChecker.labelFor(strength),
                      style: AppTextStyles.caption.copyWith(
                        color: strength == PasswordStrength.weak ? AppColors.error : strength == PasswordStrength.medium ? AppColors.accent : AppColors.secondary,
                        fontWeight: FontWeight.w600)),
                  ]),
                ],

                if (!_isSignIn) ...[
                  const SizedBox(height: 16),
                  _label('Confirm Password'),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: !_showConfirm,
                    decoration: InputDecoration(
                      hintText: 'Repeat your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_showConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setState(() => _showConfirm = !_showConfirm)),
                    ),
                    validator: (v) => AppValidators.confirmPassword(v, _passCtrl.text),
                  ),
                ],
                const SizedBox(height: 32),

                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMessage!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(_isSignIn ? Icons.login_rounded : Icons.person_add_outlined),
                  label: Text(_isLoading
                    ? (_isSignIn ? 'Signing in...' : 'Creating account...')
                    : (_isSignIn ? 'Sign In' : 'Create Account')),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}