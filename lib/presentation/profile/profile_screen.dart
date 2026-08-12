import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/validators/app_validators.dart';
import '../../data/services/cloudinary_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(_user!.uid)
        .get();
      setState(() {
        _userData  = doc.data() ?? {};
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String get _initials {
    final name = _user?.displayName ?? _user?.email ?? 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppColors.surface),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(children: [
              // Header
              _ProfileHeader(
                initials: _initials,
                photoUrl: _userData['photoUrl'] as String?,
                name: _user?.displayName ?? 'Student',
                email: _user?.email ?? '',
                university: _userData['university'] as String? ?? '',
                onPhotoTap: () => _changePhoto(),
              ),

              const SizedBox(height: 8),

              // Account Settings
              _Section(title: 'Account', items: [
                _SettingItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Full Name',
                  value: _user?.displayName ?? 'Not set',
                  onTap: () => _editName(),
                ),
                _SettingItem(
                  icon: Icons.school_outlined,
                  label: 'University',
                  value: _userData['university'] as String? ?? 'Not set',
                  onTap: () => _editUniversity(),
                ),
                _SettingItem(
                  icon: Icons.phone_outlined,
                  label: 'Phone Number',
                  value: _userData['phone'] as String? ?? 'Not set',
                  onTap: () => _editPhone(),
                ),
              ]),

              const SizedBox(height: 8),

              // Security Settings
              _Section(title: 'Security', items: [
                _SettingItem(
                  icon: Icons.email_outlined,
                  label: 'Email Address',
                  value: _user?.email ?? '',
                  onTap: () => _changeEmail(),
                ),
                _SettingItem(
                  icon: Icons.lock_outline_rounded,
                  label: 'Change Password',
                  value: '••••••••',
                  onTap: () => _changePassword(),
                ),
              ]),

              const SizedBox(height: 32),
            ]),
          ),
    );
  }

  // ── Change Profile Photo ─────────────────────────────────────────────────
  Future<void> _changePhoto() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border,
              borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Take Photo'),
            onTap: () => Navigator.pop(context, 'camera')),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from Gallery'),
            onTap: () => Navigator.pop(context, 'gallery')),
          if (_userData['photoUrl'] != null)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error),
              title: const Text('Remove Photo',
                style: TextStyle(color: AppColors.error)),
              onTap: () => Navigator.pop(context, 'remove')),
          const SizedBox(height: 8),
        ]),
      ),
    );

    if (choice == null) return;

    if (choice == 'remove') {
      await _savePhotoUrl(null);
      return;
    }

    final source = choice == 'camera'
      ? ImageSource.camera
      : ImageSource.gallery;

    try {
      final file = await ImagePicker().pickImage(
        source: source, imageQuality: 80, maxWidth: 512, maxHeight: 512);
      if (file == null) return;

      final bytes = await file.readAsBytes();
      _showLoadingDialog('Uploading photo...');

      final url = await CloudinaryService.instance.uploadImageBytes(
        bytes,
        fileName: 'avatar_${_user!.uid}.jpg',
        folder: 'campusfind/avatars',
      );

      Navigator.pop(context); // close loading
      await _savePhotoUrl(url);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showError('Failed to upload photo. Try again.');
    }
  }

  Future<void> _savePhotoUrl(String? url) async {
    await _user!.updatePhotoURL(url);
    await FirebaseFirestore.instance
      .collection(FirestoreCollections.users)
      .doc(_user!.uid)
      .set({'photoUrl': url}, SetOptions(merge: true));
    setState(() => _userData['photoUrl'] = url);
    _showSnack('Profile photo updated!');
  }

  // ── Edit Name ────────────────────────────────────────────────────────────
  void _editName() {
    final ctrl = TextEditingController(text: _user?.displayName);
    final key  = GlobalKey<FormState>();
    _showEditDialog(
      title: 'Full Name',
      child: Form(key: key, child: TextFormField(
        controller: ctrl,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'Muhammad Ali',
          prefixIcon: Icon(Icons.person_outline)),
        validator: AppValidators.fullName)),
      onSave: () async {
        if (!key.currentState!.validate()) return false;
        await _user!.updateDisplayName(ctrl.text.trim());
        await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(_user!.uid)
          .set({'name': ctrl.text.trim()}, SetOptions(merge: true));
        setState(() {});
        _showSnack('Name updated!');
        return true;
      },
    );
  }

  // ── Edit University ──────────────────────────────────────────────────────
  void _editUniversity() {
    String? selected = _userData['university'] as String?;
    _showEditDialog(
      title: 'University',
      child: StatefulBuilder(builder: (_, setS) =>
        DropdownButtonFormField<String>(
          value: selected,
          isExpanded: true,
          decoration: const InputDecoration(
            hintText: 'Select university',
            prefixIcon: Icon(Icons.school_outlined)),
          items: AppUniversities.all.map((u) => DropdownMenuItem(
            value: u.shortName,
            child: Text('${u.shortName} — ${u.city}',
              overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) { setS(() => selected = v); },
        )),
      onSave: () async {
        if (selected == null) return false;
        await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(_user!.uid)
          .set({'university': selected}, SetOptions(merge: true));
        setState(() => _userData['university'] = selected);
        _showSnack('University updated!');
        return true;
      },
    );
  }

  // ── Edit Phone ───────────────────────────────────────────────────────────
  void _editPhone() {
    final ctrl = TextEditingController(
      text: _userData['phone'] as String? ?? '');
    final key  = GlobalKey<FormState>();
    _showEditDialog(
      title: 'Phone Number',
      child: Form(key: key, child: TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(11)],
        decoration: const InputDecoration(
          hintText: '03001234567',
          prefixText: '+92  ',
          prefixIcon: Icon(Icons.phone_outlined)),
        validator: (v) => v != null && v.isNotEmpty
          ? AppValidators.phone(v) : null)),
      onSave: () async {
        if (!key.currentState!.validate()) return false;
        await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(_user!.uid)
          .set({'phone': ctrl.text.trim()}, SetOptions(merge: true));
        setState(() => _userData['phone'] = ctrl.text.trim());
        _showSnack('Phone updated!');
        return true;
      },
    );
  }

  // ── Change Email ─────────────────────────────────────────────────────────
  void _changeEmail() {
    final emailCtrl = TextEditingController();
    final passCtrl  = TextEditingController();
    final key = GlobalKey<FormState>();

    _showEditDialog(
      title: 'Change Email',
      child: Form(key: key, child: Column(children: [
        Text('Enter your current password to confirm.',
          style: AppTextStyles.bodySmall),
        const SizedBox(height: 12),
        TextFormField(
          controller: passCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Current password',
            prefixIcon: Icon(Icons.lock_outline)),
          validator: (v) => v == null || v.isEmpty ? 'Required' : null),
        const SizedBox(height: 12),
        TextFormField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'newmail@gmail.com',
            prefixIcon: Icon(Icons.email_outlined)),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email required';
            if (!v.trim().toLowerCase().endsWith('@gmail.com'))
              return 'Only Gmail accepted';
            return null;
          }),
      ])),
      onSave: () async {
        if (!key.currentState!.validate()) return false;
        try {
          // Re-authenticate first
          final cred = EmailAuthProvider.credential(
            email: _user!.email!,
            password: passCtrl.text);
          await _user!.reauthenticateWithCredential(cred);
          await _user!.verifyBeforeUpdateEmail(emailCtrl.text.trim());
          _showSnack('Verification sent to new email. Check your inbox.');
          return true;
        } on FirebaseAuthException catch (e) {
          _showError(e.code == 'wrong-password'
            ? 'Incorrect password.' : 'Failed: ${e.message}');
          return false;
        }
      },
    );
  }

  // ── Change Password ──────────────────────────────────────────────────────
  void _changePassword() {
    final oldCtrl  = TextEditingController();
    final newCtrl  = TextEditingController();
    final confCtrl = TextEditingController();
    final key = GlobalKey<FormState>();

    _showEditDialog(
      title: 'Change Password',
      child: Form(key: key, child: Column(children: [
        TextFormField(
          controller: oldCtrl, obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Current password',
            prefixIcon: Icon(Icons.lock_outline)),
          validator: (v) => v == null || v.isEmpty ? 'Required' : null),
        const SizedBox(height: 12),
        TextFormField(
          controller: newCtrl, obscureText: true,
          decoration: const InputDecoration(
            hintText: 'New password',
            prefixIcon: Icon(Icons.lock_outline)),
          validator: AppValidators.password),
        const SizedBox(height: 12),
        TextFormField(
          controller: confCtrl, obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Confirm new password',
            prefixIcon: Icon(Icons.lock_outline)),
          validator: (v) =>
            AppValidators.confirmPassword(v, newCtrl.text)),
      ])),
      onSave: () async {
        if (!key.currentState!.validate()) return false;
        try {
          final cred = EmailAuthProvider.credential(
            email: _user!.email!, password: oldCtrl.text);
          await _user!.reauthenticateWithCredential(cred);
          await _user!.updatePassword(newCtrl.text);
          _showSnack('Password changed successfully!');
          return true;
        } on FirebaseAuthException catch (e) {
          _showError(e.code == 'wrong-password'
            ? 'Current password is incorrect.' : 'Failed: ${e.message}');
          return false;
        }
      },
    );
  }

  // ── Generic Edit Dialog ──────────────────────────────────────────────────
  void _showEditDialog({
    required String title,
    required Widget child,
    required Future<bool> Function() onSave,
  }) {
    bool saving = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: SingleChildScrollView(child: child),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel')),
          ElevatedButton(
            onPressed: saving ? null : () async {
              setS(() => saving = true);
              final ok = await onSave();
              if (ok && ctx.mounted) Navigator.pop(ctx);
              else setS(() => saving = false);
            },
            child: saving
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
              : const Text('Save')),
        ],
      )),
    );
  }

  void _showLoadingDialog(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 16),
          Text(msg),
        ]),
      ),
    );
  }

  void _showSnack(String msg) {
    if (mounted) ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showError(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error));
  }
}

// ── Profile Header ───────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final String initials, name, email, university;
  final String? photoUrl;
  final VoidCallback onPhotoTap;

  const _ProfileHeader({
    required this.initials, required this.name,
    required this.email, required this.university,
    required this.onPhotoTap, this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Column(children: [
        // Avatar
        Stack(children: [
          GestureDetector(
            onTap: onPhotoTap,
            child: Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                color: Colors.white.withOpacity(0.2)),
              child: ClipOval(child: photoUrl != null
                ? Image.network(photoUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _InitialsAvatar(initials))
                : _InitialsAvatar(initials)),
            ),
          ),
          // Camera icon overlay
          Positioned(bottom: 0, right: 0,
            child: GestureDetector(
              onTap: onPhotoTap,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_rounded,
                  size: 16, color: AppColors.primary)),
            )),
        ]),
        const SizedBox(height: 14),
        Text(name,
          style: AppTextStyles.headlineMedium.copyWith(color: Colors.white)),
        const SizedBox(height: 4),
        Text(email,
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
        if (university.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppDimens.radiusFull)),
            child: Text(university,
              style: AppTextStyles.caption
                .copyWith(color: Colors.white, fontWeight: FontWeight.w600))),
        ],
      ]),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  const _InitialsAvatar(this.initials);
  @override
  Widget build(BuildContext context) => Center(
    child: Text(initials,
      style: AppTextStyles.headlineLarge.copyWith(
        color: Colors.white, fontWeight: FontWeight.w700)));
}

// ── Section & Setting Item ────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(title, style: AppTextStyles.overline
          .copyWith(color: AppColors.textSecondary))),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.border, width: 0.8)),
        child: Column(
          children: items.asMap().entries.map((e) => Column(children: [
            e.value,
            if (e.key < items.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ])).toList()),
      ),
    ]);
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final VoidCallback onTap;
  const _SettingItem({required this.icon, required this.label,
    required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.primary, size: 22),
    title: Text(label, style: AppTextStyles.bodySmall
      .copyWith(color: AppColors.textSecondary)),
    subtitle: Text(value, style: AppTextStyles.titleMedium),
    trailing: const Icon(Icons.chevron_right_rounded,
      color: AppColors.textHint),
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4));
}