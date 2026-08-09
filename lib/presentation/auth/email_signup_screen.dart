import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/validators/app_validators.dart';
import '../../core/constants/app_constants.dart';
import '../home/home_screen.dart';

class EmailSignupScreen extends StatefulWidget {
  final bool startOnSignIn;
  const EmailSignupScreen({super.key, this.startOnSignIn = false});
  @override
  State<EmailSignupScreen> createState() => _EmailSignupScreenState();
}

class _EmailSignupScreenState extends State<EmailSignupScreen>
    with SingleTickerProviderStateMixin {

  // Separate form keys — fixes parallel submit bug
  final _signUpFormKey = GlobalKey<FormState>();
  final _signInFormKey = GlobalKey<FormState>();

  // Sign Up controllers
  final _nameCtrl    = TextEditingController();
  final _suEmailCtrl = TextEditingController();
  final _suPassCtrl  = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  String? _selectedUniversity;

  // Sign In controllers
  final _siEmailCtrl = TextEditingController();
  final _siPassCtrl  = TextEditingController();

  bool _isLoading   = false;
  bool _showSuPass  = false;
  bool _showConfirm = false;
  bool _showSiPass  = false;
  late bool _isSignIn;
  String? _errorMessage;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _isSignIn = widget.startOnSignIn;
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _suEmailCtrl.dispose();
    _suPassCtrl.dispose(); _confirmCtrl.dispose();
    _phoneCtrl.dispose(); _siEmailCtrl.dispose();
    _siPassCtrl.dispose(); _animCtrl.dispose();
    super.dispose();
  }

  void _switchTab(bool toSignIn) {
    if (_isSignIn == toSignIn) return;
    _animCtrl.reset();
    setState(() {
      _isSignIn = toSignIn;
      _errorMessage = null;
      _isLoading = false;
    });
    _animCtrl.forward();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
        .hasMatch(v.trim())) return 'Enter a valid email address';
    if (!v.trim().toLowerCase().endsWith('@gmail.com'))
      return 'Only Gmail addresses accepted (@gmail.com)';
    return null;
  }

  // ── SIGN IN ──────────────────────────────────────────────────────────────
  Future<void> _signIn() async {
    if (!_signInFormKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _siEmailCtrl.text.trim(),
        password: _siPassCtrl.text,
      );

      // Block if email not verified
      if (!cred.user!.emailVerified) {
        // Stay signed in so we can send/check verification
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showNotVerifiedDialog(
          email: _siEmailCtrl.text.trim(),
          password: _siPassCtrl.text,
        );
        return;
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _errorMessage = _mapError(e.code); });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _errorMessage = 'Something went wrong. Try again.'; });
    }
  }

  // ── SIGN UP ──────────────────────────────────────────────────────────────
  Future<void> _signUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    final email    = _suEmailCtrl.text.trim();
    final password = _suPassCtrl.text;
    final name     = _nameCtrl.text.trim();

    try {
      // Create account — user is signed in at this point
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name while signed in
      try { await cred.user?.updateDisplayName(name); } catch (_) {}

      // Send verification email WHILE user is signed in (this is required)
      await cred.user?.sendEmailVerification();

      // Now sign out — they must verify before accessing the app
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Show verification dialog — pass credentials so we can re-check
      _showVerificationDialog(email: email, password: password);

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _errorMessage = _mapError(e.code); });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _errorMessage = 'Something went wrong. Try again.'; });
    }
  }

  // ── VERIFICATION DIALOG (after signup) ───────────────────────────────────
  void _showVerificationDialog({required String email, required String password}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _VerificationDialog(
        email: email,
        password: password,
        onVerified: () {
          Navigator.pop(ctx);
          // Already signed in inside dialog after verification confirmed
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
        },
        onCancel: () async {
          // Delete unverified account if user cancels
          try {
            final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: email, password: password);
            if (!cred.user!.emailVerified) {
              await cred.user?.delete();
            }
          } catch (_) {}
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  // ── NOT VERIFIED DIALOG (on sign in attempt) ─────────────────────────────
  void _showNotVerifiedDialog({required String email, required String password}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.accent),
          const SizedBox(width: 8),
          const Expanded(child: Text('Email Not Verified')),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📧', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('You need to verify $email before signing in.',
            style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Check your inbox for the verification link, or resend it below.',
            style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ]),
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                // User is already signed in here (from sign in attempt)
                await FirebaseAuth.instance.currentUser?.sendEmailVerification();
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                _showVerificationDialog(email: email, password: password);
              } catch (_) {
                await FirebaseAuth.instance.signOut();
              }
            },
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Resend & Verify'),
          ),
        ],
      ),
    );
  }

  String _mapError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Switch to Sign In tab.';
      case 'invalid-email':        return 'Please enter a valid Gmail address.';
      case 'weak-password':        return 'Password too weak. Use 8+ chars, uppercase, number & symbol.';
      case 'user-not-found':       return 'No account found. Please create an account first.';
      case 'wrong-password':
      case 'invalid-credential':   return 'Incorrect email or password.';
      case 'too-many-requests':    return 'Too many attempts. Please wait a few minutes.';
      case 'network-request-failed': return 'No internet connection.';
      case 'user-disabled':        return 'This account has been disabled.';
      default:                     return 'Error: $code — Please try again.';
    }
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: AppTextStyles.labelLarge),
  );

  Widget _tab(String label, bool active, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        child: Text(label, textAlign: TextAlign.center,
          style: AppTextStyles.labelLarge.copyWith(
            color: active ? Colors.white : AppColors.textSecondary)),
      ),
    ),
  );

  Widget _errorBox() => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.error.withOpacity(0.4)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(_errorMessage!,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.error))),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final strength = PasswordStrengthChecker.check(_suPassCtrl.text);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: [

            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (Navigator.canPop(context))
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white)),
                const SizedBox(height: 16),
                Text(
                  _isSignIn ? 'Welcome\nBack 👋' : 'Create Your\nAccount 🎓',
                  style: AppTextStyles.displayMedium.copyWith(color: Colors.white, height: 1.2)),
                const SizedBox(height: 8),
                Text(
                  _isSignIn
                    ? 'Sign in to find lost items on your campus'
                    : 'Join thousands of students on CampusFind PK',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
              ]),
            ),

            FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // Tab switcher
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
                    child: Row(children: [
                      _tab('Create Account', !_isSignIn, () => _switchTab(false)),
                      _tab('Sign In', _isSignIn,         () => _switchTab(true)),
                    ]),
                  ),
                  const SizedBox(height: 28),

                  // ── CREATE ACCOUNT FORM ──────────────────────────────
                  if (!_isSignIn)
                    Form(
                      key: _signUpFormKey,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label('Full Name *'),
                        TextFormField(
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            hintText: 'Muhammad Ali',
                            prefixIcon: Icon(Icons.person_outline)),
                          validator: AppValidators.fullName,
                        ),
                        const SizedBox(height: 16),

                        _label('University *'),
                        DropdownButtonFormField<String>(
                          value: _selectedUniversity,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            hintText: 'Select your university',
                            prefixIcon: Icon(Icons.school_outlined)),
                          items: AppUniversities.all.map((u) => DropdownMenuItem(
                            value: u.shortName,
                            child: Text('${u.shortName} — ${u.city}',
                              style: AppTextStyles.bodyMedium,
                              overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) => setState(() => _selectedUniversity = v),
                          validator: (v) => v == null ? 'Please select your university' : null,
                        ),
                        const SizedBox(height: 16),

                        _label('Phone Number (optional)'),
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          decoration: const InputDecoration(
                            hintText: '03001234567',
                            prefixText: '+92  ',
                            prefixIcon: Icon(Icons.phone_outlined)),
                          validator: (v) => v != null && v.isNotEmpty
                            ? AppValidators.phone(v) : null,
                        ),
                        const SizedBox(height: 16),

                        _label('Email Address *'),
                        TextFormField(
                          controller: _suEmailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'yourname@gmail.com',
                            prefixIcon: Icon(Icons.email_outlined),
                            helperText: 'Only Gmail addresses accepted'),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 16),

                        _label('Password *'),
                        TextFormField(
                          controller: _suPassCtrl,
                          obscureText: !_showSuPass,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Min 8 chars, uppercase, number & symbol',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_showSuPass
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                              onPressed: () => setState(() => _showSuPass = !_showSuPass))),
                          validator: AppValidators.password,
                        ),

                        if (_suPassCtrl.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(child: LinearProgressIndicator(
                              value: strength == PasswordStrength.weak ? 0.33
                                   : strength == PasswordStrength.medium ? 0.66 : 1.0,
                              color: strength == PasswordStrength.weak ? AppColors.error
                                   : strength == PasswordStrength.medium ? AppColors.accent
                                   : AppColors.secondary,
                              backgroundColor: AppColors.border,
                              minHeight: 5,
                              borderRadius: BorderRadius.circular(3),
                            )),
                            const SizedBox(width: 10),
                            Text(PasswordStrengthChecker.labelFor(strength),
                              style: AppTextStyles.caption.copyWith(
                                color: strength == PasswordStrength.weak ? AppColors.error
                                     : strength == PasswordStrength.medium ? AppColors.accent
                                     : AppColors.secondary,
                                fontWeight: FontWeight.w600)),
                          ]),
                          const SizedBox(height: 4),
                          Text('Must include: uppercase, number and special character',
                            style: AppTextStyles.caption),
                        ],

                        const SizedBox(height: 16),
                        _label('Confirm Password *'),
                        TextFormField(
                          controller: _confirmCtrl,
                          obscureText: !_showConfirm,
                          decoration: InputDecoration(
                            hintText: 'Repeat your password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_showConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                              onPressed: () => setState(() => _showConfirm = !_showConfirm))),
                          validator: (v) => AppValidators.confirmPassword(v, _suPassCtrl.text),
                        ),

                        const SizedBox(height: 28),
                        if (_errorMessage != null) _errorBox(),

                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _signUp,
                          icon: _isLoading
                            ? const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.person_add_outlined),
                          label: Text(_isLoading ? 'Creating account...' : 'Create Account'),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Text.rich(TextSpan(
                            text: 'By creating an account you agree to our ',
                            style: AppTextStyles.caption,
                            children: [
                              TextSpan(text: 'Terms of Service',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary, fontWeight: FontWeight.w600)),
                              const TextSpan(text: ' and '),
                              TextSpan(text: 'Privacy Policy',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary, fontWeight: FontWeight.w600)),
                            ],
                          ), textAlign: TextAlign.center),
                        ),
                        const SizedBox(height: 32),
                      ]),
                    ),

                  // ── SIGN IN FORM ─────────────────────────────────────
                  if (_isSignIn)
                    Form(
                      key: _signInFormKey,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label('Email Address *'),
                        TextFormField(
                          controller: _siEmailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'yourname@gmail.com',
                            prefixIcon: Icon(Icons.email_outlined)),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 16),

                        _label('Password *'),
                        TextFormField(
                          controller: _siPassCtrl,
                          obscureText: !_showSiPass,
                          decoration: InputDecoration(
                            hintText: 'Your password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_showSiPass
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                              onPressed: () => setState(() => _showSiPass = !_showSiPass))),
                          validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
                        ),

                        const SizedBox(height: 28),
                        if (_errorMessage != null) _errorBox(),

                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _signIn,
                          icon: _isLoading
                            ? const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.login_rounded),
                          label: Text(_isLoading ? 'Signing in...' : 'Sign In'),
                        ),
                        const SizedBox(height: 32),
                      ]),
                    ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── VERIFICATION DIALOG ───────────────────────────────────────────────────────
class _VerificationDialog extends StatefulWidget {
  final String email, password;
  final VoidCallback onVerified;
  final VoidCallback onCancel;
  const _VerificationDialog({
    required this.email, required this.password,
    required this.onVerified, required this.onCancel,
  });
  @override
  State<_VerificationDialog> createState() => _VerificationDialogState();
}

class _VerificationDialogState extends State<_VerificationDialog> {
  Timer? _timer;
  bool _isChecking  = false;
  bool _justChecked = false;
  String _statusMsg = 'Waiting for you to verify...';

  @override
  void initState() {
    super.initState();
    // Auto-poll every 6 seconds
    _timer = Timer.periodic(const Duration(seconds: 6), (_) => _checkVerification());
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _checkVerification() async {
    if (_isChecking) return;
    setState(() { _isChecking = true; _statusMsg = 'Checking...'; });

    try {
      // Must sign in to get fresh token and check emailVerified
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      // Force refresh the token to get latest emailVerified status
      await cred.user?.reload();
      final user = FirebaseAuth.instance.currentUser;
      await user?.getIdToken(true);

      if (user != null && user.emailVerified) {
        // Verified! Stay signed in and go to home
        _timer?.cancel();
        widget.onVerified();
        return;
      }

      // Not verified yet — sign out and wait
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      setState(() {
        _isChecking  = false;
        _justChecked = true;
        _statusMsg   = 'Not verified yet. Check your inbox.';
      });

      // Reset message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() {
          _justChecked = false;
          _statusMsg   = 'Waiting for you to verify...';
        });
      });

    } catch (e) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      setState(() {
        _isChecking  = false;
        _statusMsg   = 'Check failed. Try again.';
      });
    }
  }

  Future<void> _resendEmail() async {
    setState(() { _isChecking = true; _statusMsg = 'Resending...'; });
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: widget.email, password: widget.password);
      await cred.user?.sendEmailVerification();
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      setState(() {
        _isChecking = false;
        _statusMsg  = 'Verification email resent! Check your inbox.';
      });
    } catch (_) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      setState(() { _isChecking = false; _statusMsg = 'Resend failed. Try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Verify Your Email 📧'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            const Text('📩', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text('Verification email sent to:',
              style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(widget.email,
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
              textAlign: TextAlign.center),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            const Text('📋 Steps:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('1. Open your Gmail inbox\n'
                       '2. Find email from Firebase\n'
                       '3. Click the verification link\n'
                       '4. Come back and tap "I Verified"',
              textAlign: TextAlign.left,
              style: TextStyle(fontSize: 13, height: 1.6)),
          ]),
        ),
        const SizedBox(height: 12),

        // Status indicator
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (_isChecking)
            const SizedBox(width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
          else
            Icon(
              _justChecked ? Icons.close_rounded : Icons.access_time_rounded,
              size: 14,
              color: _justChecked ? AppColors.error : AppColors.textHint),
          const SizedBox(width: 6),
          Text(_statusMsg,
            style: AppTextStyles.caption.copyWith(
              color: _justChecked ? AppColors.error : AppColors.textHint)),
        ]),
      ]),
      actions: [
        // Cancel — deletes unverified account
        TextButton(
          onPressed: _isChecking ? null : widget.onCancel,
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        // Resend email
        TextButton(
          onPressed: _isChecking ? null : _resendEmail,
          child: const Text('Resend Email'),
        ),
        // Check verification manually
        ElevatedButton.icon(
          onPressed: _isChecking ? null : _checkVerification,
          style: ElevatedButton.styleFrom(minimumSize: const Size(120, 40)),
          icon: _isChecking
            ? const SizedBox(width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.verified_outlined, size: 16),
          label: Text(_isChecking ? 'Checking...' : 'I Verified ✓'),
        ),
      ],
    );
  }
}