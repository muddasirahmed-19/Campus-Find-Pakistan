import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../core/validators/app_validators.dart';
import '../../core/constants/app_constants.dart';
import '../home/home_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  SIGN IN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class EmailSignupScreen extends StatefulWidget {
  final bool startOnSignIn;
  const EmailSignupScreen({super.key, this.startOnSignIn = true});
  @override
  State<EmailSignupScreen> createState() => _EmailSignupScreenState();
}

class _EmailSignupScreenState extends State<EmailSignupScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _isLoading  = false;
  bool _showPass   = false;
  String? _errorMessage;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
        .hasMatch(v.trim())) return 'Enter a valid email address';
    if (!v.trim().toLowerCase().endsWith('@gmail.com'))
      return 'Only Gmail addresses accepted (@gmail.com)';
    return null;
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(), password: _passCtrl.text);

      if (!cred.user!.emailVerified) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showNotVerifiedDialog();
        return;
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _errorMessage = _mapError(e.code); });
    } catch (_) {
      if (!mounted) return;
      setState(() { _isLoading = false; _errorMessage = 'Something went wrong. Try again.'; });
    }
  }

  void _showNotVerifiedDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Email Not Verified'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.mark_email_unread_outlined, size: 56, color: AppColors.primary),
        const SizedBox(height: 16),
        Text('Your email is not verified yet.\n\nPlease click the link sent to your Gmail inbox.',
          style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ElevatedButton.icon(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: _emailCtrl.text.trim(), password: _passCtrl.text);
              await cred.user?.sendEmailVerification();
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Verification email resent. Check inbox and spam folder.')));
            } catch (_) {}
          },
          icon: const Icon(Icons.send_rounded, size: 16),
          label: const Text('Resend Email')),
      ],
    ));
  }

  void _showForgotPasswordDialog() {
    final ctrl    = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool sending  = false;
    String? dialogError;

    showDialog(context: context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Enter your registered Gmail to receive a reset link.',
            style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Form(key: formKey, child: TextFormField(
            controller: ctrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'yourname@gmail.com',
              prefixIcon: Icon(Icons.email_outlined)),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.trim().toLowerCase().endsWith('@gmail.com'))
                return 'Only Gmail addresses accepted';
              return null;
            })),
          if (dialogError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.4))),
              child: Row(children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(dialogError!,
                  style: AppTextStyles.caption.copyWith(color: AppColors.error))),
              ])),
          ],
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: sending ? null : () async {
              if (!formKey.currentState!.validate()) return;
              setS(() { sending = true; dialogError = null; });
              final email = ctrl.text.trim();
              try {
                final methods = await FirebaseAuth.instance
                  .fetchSignInMethodsForEmail(email);
                if (methods.isEmpty) {
                  setS(() { sending = false; dialogError = 'No account found with this email.'; });
                  return;
                }
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) _showResetSentDialog(email);
              } on FirebaseAuthException catch (e) {
                setS(() { sending = false; dialogError = 'Error: ${e.message}'; });
              } catch (_) {
                setS(() { sending = false; dialogError = 'Something went wrong.'; });
              }
            },
            icon: sending
              ? const SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send_rounded, size: 16),
            label: Text(sending ? 'Checking...' : 'Send Reset Link')),
        ],
      ));
    });
  }

  void _showResetSentDialog(String email) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Reset Link Sent'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.check_circle_outline_rounded,
          size: 56, color: AppColors.secondary),
        const SizedBox(height: 16),
        Text('Password reset link sent to:\n$email',
          style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.accent.withOpacity(0.4))),
          child: Row(children: [
            const Icon(Icons.info_outline, color: AppColors.accent, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text('Check spam/junk if not in inbox.',
              style: AppTextStyles.caption)),
          ])),
      ]),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK')),
      ],
    ));
  }

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':  return 'Incorrect email or password.';
      case 'too-many-requests':   return 'Too many attempts. Please wait.';
      case 'network-request-failed': return 'No internet connection.';
      case 'user-disabled':       return 'This account has been disabled.';
      default:                    return 'Something went wrong. Try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 36),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 8),
                Text('Welcome Back',
                  style: AppTextStyles.displayMedium.copyWith(
                    color: Colors.white, height: 1.2)),
                const SizedBox(height: 8),
                Text('Sign in to CampusFind PK',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 8),
                  Text('Email Address', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'yourname@gmail.com',
                      prefixIcon: Icon(Icons.email_outlined)),
                    validator: _validateEmail),
                  const SizedBox(height: 16),
                  Text('Password', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: !_showPass,
                    decoration: InputDecoration(
                      hintText: 'Your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_showPass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                        onPressed: () => setState(() => _showPass = !_showPass))),
                    validator: (v) => v == null || v.isEmpty ? 'Password is required' : null),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: Text('Forgot Password?',
                        style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)))),
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        border: Border.all(color: AppColors.error.withOpacity(0.4))),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_errorMessage!,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.error))),
                      ])),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _signIn,
                    icon: _isLoading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.login_rounded),
                    label: Text(_isLoading ? 'Signing in...' : 'Sign In')),
                  const SizedBox(height: 24),
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text("Don't have an account?", style: AppTextStyles.caption)),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CreateAccountScreen())),
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text('Create New Account')),
                  const SizedBox(height: 32),
                ])),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CREATE ACCOUNT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});
  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  String? _selectedUniversity;
  String _savedPassword = '';
  bool _isLoading = false, _showPass = false, _showConfirm = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose();
    _confirmCtrl.dispose(); _phoneCtrl.dispose(); super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
        .hasMatch(v.trim())) return 'Enter a valid email address';
    if (!v.trim().toLowerCase().endsWith('@gmail.com'))
      return 'Only Gmail addresses accepted (@gmail.com)';
    return null;
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    final email    = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    _savedPassword = password;

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email, password: password);
      try { await cred.user?.updateDisplayName(_nameCtrl.text.trim()); } catch (_) {}

      // Save user data to Firestore — university saved here for auto-filtering
      await FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(cred.user!.uid)
        .set({
          'uid':        cred.user!.uid,
          'name':       _nameCtrl.text.trim(),
          'email':      email,
          'university': _selectedUniversity ?? '',
          'phone':      _phoneCtrl.text.trim(),
          'createdAt':  DateTime.now().toIso8601String(),
        });

      await cred.user?.sendEmailVerification();
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showVerificationDialog(email);

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _errorMessage = _mapError(e.code); });
    } catch (_) {
      if (!mounted) return;
      setState(() { _isLoading = false; _errorMessage = 'Something went wrong.'; });
    }
  }

  void _showVerificationDialog(String email) {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => _VerificationDialog(
        email: email, password: _savedPassword,
        onVerifiedAndLoggedIn: () {
          Navigator.pop(ctx);
          Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
        },
        onClose: () => Navigator.pop(ctx)));
  }

  String _mapError(String code) {
    switch (code) {
      case 'email-already-in-use': return 'This email is already registered.';
      case 'invalid-email':        return 'Please enter a valid Gmail address.';
      case 'weak-password':        return 'Password too weak.';
      case 'network-request-failed': return 'No internet connection.';
      default: return 'Something went wrong. Try again.';
    }
  }

  Widget _lbl(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: AppTextStyles.labelLarge));

  @override
  Widget build(BuildContext context) {
    final strength = PasswordStrengthChecker.check(_passCtrl.text);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const EmailSignupScreen()), (_) => false);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 36),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft, end: Alignment.bottomRight)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  GestureDetector(
                    onTap: () => Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (_) => const EmailSignupScreen()),
                      (_) => false),
                    child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 28)),
                  const SizedBox(height: 20),
                  Text('Create Account',
                    style: AppTextStyles.displayMedium.copyWith(
                      color: Colors.white, height: 1.2)),
                  const SizedBox(height: 8),
                  Text('Join your campus lost & found community',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 8),
                  _lbl('Full Name *'),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Muhammad Ali',
                      prefixIcon: Icon(Icons.person_outline)),
                    validator: AppValidators.fullName),
                  const SizedBox(height: 16),
                  _lbl('University *'),
                  DropdownButtonFormField<String>(
                    value: _selectedUniversity, isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: 'Select your university',
                      prefixIcon: Icon(Icons.school_outlined)),
                    items: AppUniversities.all.map((u) => DropdownMenuItem(
                      value: u.shortName,
                      child: Text('${u.shortName} — ${u.city}',
                        style: AppTextStyles.bodyMedium,
                        overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setState(() => _selectedUniversity = v),
                    validator: (v) => v == null ? 'Please select your university' : null),
                  const SizedBox(height: 16),
                  _lbl('Phone Number (optional)'),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11)],
                    decoration: const InputDecoration(
                      hintText: '03001234567', prefixText: '+92  ',
                      prefixIcon: Icon(Icons.phone_outlined)),
                    validator: (v) => v != null && v.isNotEmpty
                      ? AppValidators.phone(v) : null),
                  const SizedBox(height: 16),
                  _lbl('Email Address *'),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'yourname@gmail.com',
                      prefixIcon: Icon(Icons.email_outlined),
                      helperText: 'Only Gmail addresses accepted'),
                    validator: _validateEmail),
                  const SizedBox(height: 16),
                  _lbl('Password *'),
                  TextFormField(
                    controller: _passCtrl, obscureText: !_showPass,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Min 8 chars, uppercase, number & symbol',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_showPass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                        onPressed: () => setState(() => _showPass = !_showPass))),
                    validator: AppValidators.password),
                  if (_passCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: LinearProgressIndicator(
                        value: strength == PasswordStrength.weak ? 0.33
                             : strength == PasswordStrength.medium ? 0.66 : 1.0,
                        color: strength == PasswordStrength.weak ? AppColors.error
                             : strength == PasswordStrength.medium ? AppColors.accent
                             : AppColors.secondary,
                        backgroundColor: AppColors.border, minHeight: 5,
                        borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 10),
                      Text(PasswordStrengthChecker.labelFor(strength),
                        style: AppTextStyles.caption.copyWith(
                          color: strength == PasswordStrength.weak ? AppColors.error
                               : strength == PasswordStrength.medium ? AppColors.accent
                               : AppColors.secondary,
                          fontWeight: FontWeight.w600)),
                    ]),
                  ],
                  const SizedBox(height: 16),
                  _lbl('Confirm Password *'),
                  TextFormField(
                    controller: _confirmCtrl, obscureText: !_showConfirm,
                    decoration: InputDecoration(
                      hintText: 'Repeat your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_showConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                        onPressed: () => setState(() => _showConfirm = !_showConfirm))),
                    validator: (v) => AppValidators.confirmPassword(v, _passCtrl.text)),
                  const SizedBox(height: 28),
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        border: Border.all(color: AppColors.error.withOpacity(0.4))),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_errorMessage!,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.error))),
                      ])),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _createAccount,
                    icon: _isLoading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.person_add_outlined),
                    label: Text(_isLoading ? 'Creating account...' : 'Create Account')),
                  const SizedBox(height: 32),
                ])),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  VERIFICATION DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _VerificationDialog extends StatefulWidget {
  final String email, password;
  final VoidCallback onVerifiedAndLoggedIn;
  final VoidCallback onClose;
  const _VerificationDialog({
    required this.email, required this.password,
    required this.onVerifiedAndLoggedIn, required this.onClose});
  @override
  State<_VerificationDialog> createState() => _VerificationDialogState();
}

class _VerificationDialogState extends State<_VerificationDialog> {
  bool _isResending = false, _isChecking = false;

  Future<void> _onClose() async {
    setState(() => _isChecking = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: widget.email, password: widget.password);
      await cred.user?.reload();
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
      if (FirebaseAuth.instance.currentUser?.emailVerified == true) {
        widget.onVerifiedAndLoggedIn(); return;
      }
      await FirebaseAuth.instance.signOut();
    } catch (_) { await FirebaseAuth.instance.signOut(); }
    if (mounted) setState(() => _isChecking = false);
    widget.onClose();
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: widget.email, password: widget.password);
      await cred.user?.sendEmailVerification();
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        setState(() => _isResending = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Verification email resent. Check inbox and spam.')));
      }
    } catch (_) { if (mounted) setState(() => _isResending = false); }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: const Text('Check Your Email'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.mark_email_unread_outlined, size: 64, color: AppColors.primary),
      const SizedBox(height: 16),
      Text('Verification email sent to:', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
      const SizedBox(height: 4),
      Text(widget.email,
        style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
        textAlign: TextAlign.center),
      const SizedBox(height: 16),
      Text('Click the link in your email to verify your account.',
        style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.accent.withOpacity(0.4))),
        child: Row(children: [
          const Icon(Icons.info_outline, color: AppColors.accent, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text('Check spam/junk folder if not found.',
            style: AppTextStyles.caption)),
        ])),
    ]),
    actions: [
      TextButton.icon(
        onPressed: _isResending || _isChecking ? null : _resend,
        icon: _isResending
          ? const SizedBox(width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.refresh_rounded, size: 16),
        label: Text(_isResending ? 'Sending...' : 'Resend')),
      ElevatedButton(
        onPressed: _isChecking || _isResending ? null : _onClose,
        child: _isChecking
          ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Text('Close')),
    ]);
}