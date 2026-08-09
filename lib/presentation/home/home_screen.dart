import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../auth/email_signup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('CampusFind PK'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(
                    builder: (_) => const EmailSignupScreen(startOnSignIn: true)),
                  (_) => false);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: const BoxDecoration(
                  color: AppColors.secondaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.secondary, size: 56),
              ),
              const SizedBox(height: 24),
              Text('You are In! 🎉', style: AppTextStyles.headlineLarge),
              const SizedBox(height: 8),
              Text(
                'Welcome, ${user?.displayName ?? user?.email ?? 'User'}!',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('Phase 3: Home Feed coming next →', style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}