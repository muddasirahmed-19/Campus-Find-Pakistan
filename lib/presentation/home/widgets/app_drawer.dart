import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  final void Function(String route) onNavigate;
  const AppDrawer({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? user?.email ?? 'Student';
    final initials = _initials(name);

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(children: [
          // Profile header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 2)),
                child: Center(child: Text(initials,
                  style: AppTextStyles.headlineMedium
                    .copyWith(color: Colors.white, fontWeight: FontWeight.w700))),
              ),
              const SizedBox(height: 12),
              Text(user?.displayName ?? 'Student',
                style: AppTextStyles.titleLarge.copyWith(color: Colors.white)),
              const SizedBox(height: 2),
              Text(user?.email ?? '',
                style: AppTextStyles.caption.copyWith(color: Colors.white70)),
            ]),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: ListView(padding: EdgeInsets.zero, children: [
              _Item(icon: Icons.home_outlined,      label: 'Home Feed',
                onTap: () => Navigator.pop(context)),
              _Item(icon: Icons.post_add_outlined,  label: 'Create Post',
                onTap: () => onNavigate('create_post')),
              _Item(icon: Icons.list_alt_outlined,  label: 'My Posts',
                onTap: () => onNavigate('my_posts')),
              _Item(icon: Icons.notifications_outlined, label: 'Notifications',
                onTap: () => onNavigate('notifications')),
              const Divider(indent: 16, endIndent: 16, height: 24),
              _Item(icon: Icons.person_outline_rounded, label: 'Profile',
                onTap: () => onNavigate('profile')),
              _Item(icon: Icons.settings_outlined,  label: 'Settings',
                onTap: () => onNavigate('settings')),
              const Divider(indent: 16, endIndent: 16, height: 24),
              _Item(icon: Icons.logout_rounded,     label: 'Sign Out',
                color: AppColors.error,
                onTap: () => onNavigate('logout')),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('CampusFind PK v1.0.0',
              style: AppTextStyles.caption, textAlign: TextAlign.center)),
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

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _Item({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: c)),
      onTap: onTap,
      horizontalTitleGap: 4,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}
