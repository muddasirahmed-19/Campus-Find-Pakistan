import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class AppDrawer extends StatelessWidget {
  final void Function(String route) onNavigate;
  const AppDrawer({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(children: [

          // ── Profile Header — streams live Firestore data ───────────
          StreamBuilder<DocumentSnapshot>(
            stream: user == null ? null : FirebaseFirestore.instance
              .collection(FirestoreCollections.users)
              .doc(user.uid)
              .snapshots(),
            builder: (_, snap) {
              final data = snap.data?.data() as Map<String, dynamic>? ?? {};
              final name       = data['name'] as String?
                              ?? user?.displayName
                              ?? 'Student';
              final university = data['university'] as String? ?? '';
              final photoUrl   = data['photoUrl'] as String?
                              ?? user?.photoURL;

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5), width: 2)),
                    child: ClipOval(
                      child: photoUrl != null && photoUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: photoUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _InitialsBg(_initials(name)),
                            errorWidget: (_, __, ___) => _InitialsBg(_initials(name)))
                        : _InitialsBg(_initials(name)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(name,
                    style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
                    overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(user?.email ?? '',
                    style: AppTextStyles.caption.copyWith(color: Colors.white70),
                    overflow: TextOverflow.ellipsis),
                  if (university.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppDimens.radiusFull)),
                      child: Text(university,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w600))),
                  ],
                ]),
              );
            },
          ),

          const SizedBox(height: 8),

          // ── Menu Items ─────────────────────────────────────────────
          Expanded(
            child: ListView(padding: EdgeInsets.zero, children: [
              _Item(icon: Icons.home_outlined, label: 'Home Feed',
                onTap: () => Navigator.pop(context)),
              _Item(icon: Icons.post_add_outlined, label: 'Create Post',
                onTap: () => onNavigate('create_post')),
              _Item(icon: Icons.list_alt_outlined, label: 'My Posts',
                onTap: () => onNavigate('my_posts')),
              const Divider(indent: 16, endIndent: 16, height: 24),
              _Item(icon: Icons.person_outline_rounded, label: 'Profile',
                onTap: () => onNavigate('profile')),
              const Divider(indent: 16, endIndent: 16, height: 24),
              _Item(icon: Icons.logout_rounded, label: 'Sign Out',
                color: AppColors.error,
                onTap: () => onNavigate('logout')),
            ]),
          ),

        ]),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}

class _InitialsBg extends StatelessWidget {
  final String initials;
  const _InitialsBg(this.initials);
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white.withOpacity(0.2),
    child: Center(child: Text(initials,
      style: AppTextStyles.headlineMedium.copyWith(
        color: Colors.white, fontWeight: FontWeight.w700))));
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _Item({required this.icon, required this.label,
    required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: c)),
      onTap: onTap,
      horizontalTitleGap: 4,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2));
  }
}