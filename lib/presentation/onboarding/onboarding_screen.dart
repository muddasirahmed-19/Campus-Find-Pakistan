import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../auth/email_signup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  final _pages = const [
    _Page(
      icon: Icons.search_rounded,
      title: 'Lost Something?',
      subtitle: 'Post your lost item and let your campus community help you find it.',
      color: Color(0xFF1A73E8),
    ),
    _Page(
      icon: Icons.inventory_2_outlined,
      title: 'Found Something?',
      subtitle: 'Report found items and help reunite them with their rightful owners.',
      color: Color(0xFF34A853),
    ),
    _Page(
      icon: Icons.handshake_outlined,
      title: 'Safe Handoff',
      subtitle: 'Our dual-confirmation system ensures items are returned safely and securely.',
      color: Color(0xFF9C27B0),
    ),
  ];

  void _goToSignIn() => Navigator.pushReplacement(context,
    MaterialPageRoute(builder: (_) => const EmailSignupScreen()));

  void _goToCreateAccount() => Navigator.pushReplacement(context,
    MaterialPageRoute(builder: (_) => const CreateAccountScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          // Skip button
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: _goToSignIn,
                child: Text('Skip',
                  style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.textSecondary)),
              ),
            ),
          ),

          // Pages
          Expanded(child: PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _pages[i],
          )),

          // Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _page == i ? 24 : 8, height: 8,
              decoration: BoxDecoration(
                color: _page == i ? _pages[_page].color : AppColors.border,
                borderRadius: BorderRadius.circular(4)),
            )),
          ),
          const SizedBox(height: 32),

          // Next / Sign In button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _pages[_page].color),
              onPressed: () {
                if (_page < _pages.length - 1) {
                  _ctrl.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut);
                } else {
                  _goToSignIn();
                }
              },
              child: Text(_page < _pages.length - 1 ? 'Next' : 'Sign In'),
            ),
          ),

          // Create account link on last page
          if (_page == _pages.length - 1) ...[
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text("Don't have an account? ",
                style: AppTextStyles.bodySmall),
              GestureDetector(
                onTap: _goToCreateAccount,
                child: Text('Create one',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
              ),
            ]),
          ],
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;

  const _Page({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst = icon == Icons.search_rounded;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        _buildIcon(isFirst, color),
        const SizedBox(height: 40),
        Text(title,
          style: AppTextStyles.headlineLarge,
          textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text(subtitle,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildIcon(bool withHero, Color color) {
    final container = Container(
      width: 140, height: 140,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle),
      child: Icon(icon, size: 64, color: color),
    );
    return withHero
      ? Hero(tag: 'app_icon', child: container)
      : container;
  }
}