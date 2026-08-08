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
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  String? _selectedUniversity;
  bool _isLoading = false, _showPass = false, _showConfirm = false;
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
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    _phoneCtrl.dispose(); _animCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    _animCtrl.reset();
    setState(() { _isSignIn = !_isSignIn; _errorMessage = null; });
    _animCtrl.forward();
  }

  // ── Email validator: only gmail.com accepted ────────────────────────────────
  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final trimmed = v.trim().toLowerCase();
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(trimmed)) return 'Enter a valid email address';
    if (!trimmed.endsWith('@gmail.com')) return 'Only Gmail addresses are accepted (@gmail.com)';
    return null;
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
      setState(() {
        _isLoading = false;
        // Show actual code in brackets to help debug
        _errorMessage = '${_mapError(e.code)} [${e.code}]';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  String _mapError(String code) {
    switch (code) {
      case 'email-already-in-use':   return 'This email is already registered. Try signing in instead.';
      case 'invalid-email':          return 'Please enter a valid Gmail address.';
      case 'weak-password':          return 'Password is too weak.';
      case 'user-not-found':         return 'No account found. Please create an account first.';
      case 'wrong-password':         return 'Incorrect password. Please try again.';
      case 'invalid-credential':     return 'Incorrect email or password.';
      case 'too-many-requests':      return 'Too many attempts. Please wait a few minutes.';
      case 'network-request-failed': return 'No internet connection.';
      case 'user-disabled':          return 'This account has been disabled.';
      default: return 'Something went wrong. Please try again.';
    }
  }

  void _showVerificationDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (_) =>
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.mark_email_unread_outlined, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('Verify Your Email'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              const Text('📧', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('We sent a verification link to:',
                style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(_emailCtrl.text.trim(),
                style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
                textAlign: TextAlign.center),
            ]),
          ),
          const SizedBox(height: 12),
          Text('Please check your inbox and click the link before signing in.',
            style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ]),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); _toggleMode(); },
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header — always primary blue ─────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (Navigator.canPop(context))
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      _isSignIn ? 'Welcome\nBack 👋' : 'Create Your\nAccount 🎓',
                      style: AppTextStyles.displayMedium.copyWith(
                          color: Colors.white, height: 1.2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignIn
                        ? 'Sign in to find lost items on your campus'
                        : 'Join thousands of students on CampusFind PK',
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // ── Form ─────────────────────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tab switcher — always primary blue
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                          ),
                          child: Row(children: [
                            _tab('Create Account', !_isSignIn, () { if (_isSignIn) _toggleMode(); }),
                            _tab('Sign In', _isSignIn, () { if (!_isSignIn) _toggleMode(); }),
                          ]),
                        ),
                        const SizedBox(height: 28),

                        // ── SIGNUP ONLY FIELDS ──────────────────────────
                        if (!_isSignIn) ...[
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
                        ],

                        // ── EMAIL ───────────────────────────────────────
                        _label('Email Address *'),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'yourname@gmail.com',
                            prefixIcon: Icon(Icons.email_outlined),
                            helperText: 'Only Gmail addresses accepted',
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 16),

                        // ── PASSWORD ────────────────────────────────────
                        _label('Password *'),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: !_showPass,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: _isSignIn
                              ? 'Your password'
                              : 'Min 8 chars, uppercase, number & symbol',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_showPass
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                              onPressed: () => setState(() => _showPass = !_showPass)),
                          ),
                          validator: _isSignIn
                            ? (v) => v == null || v.isEmpty ? 'Password is required' : null
                            : AppValidators.password,
                        ),

                        // Password strength (signup only)
                        if (!_isSignIn && _passCtrl.text.isNotEmpty) ...[
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
                          const SizedBox(height: 6),
                          Text('Must include: uppercase, number and special character',
                            style: AppTextStyles.caption),
                        ],

                        // Confirm Password (signup only)
                        if (!_isSignIn) ...[
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
                                onPressed: () => setState(() => _showConfirm = !_showConfirm)),
                            ),
                            validator: (v) => AppValidators.confirmPassword(v, _passCtrl.text),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // Error box
                        if (_errorMessage != null) ...[
                          Container(
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
                          const SizedBox(height: 16),
                        ],

                        // Submit — always primary blue
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _submit,
                          icon: _isLoading
                            ? const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Icon(_isSignIn ? Icons.login_rounded : Icons.person_add_outlined),
                          label: Text(_isLoading
                            ? (_isSignIn ? 'Signing in...' : 'Creating account...')
                            : (_isSignIn ? 'Sign In' : 'Create Account')),
                        ),
                        const SizedBox(height: 20),

                        if (!_isSignIn)
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
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          child: Text(label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelLarge.copyWith(
              color: active ? Colors.white : AppColors.textSecondary)),
        ),
      ),
    );
  }
}