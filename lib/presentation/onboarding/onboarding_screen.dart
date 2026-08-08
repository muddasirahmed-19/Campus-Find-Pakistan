import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../auth/phone_auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  final _pages = const [
    _Page(emoji: '🔍', title: 'Lost Something?', subtitle: 'Post your lost item and let your\ncampus community help you find it.', color: Color(0xFF1A73E8)),
    _Page(emoji: '📦', title: 'Found Something?', subtitle: 'Report found items and help reunite\nthem with their rightful owners.', color: Color(0xFF34A853)),
    _Page(emoji: '🤝', title: 'Safe Handoff', subtitle: 'Our dual-confirmation OTP system ensures\nitems are returned safely and securely.', color: Color(0xFF9C27B0)),
  ];

  void _goToAuth() => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PhoneAuthScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(alignment: Alignment.topRight,
              child: Padding(padding: const EdgeInsets.all(16),
                child: TextButton(onPressed: _goToAuth,
                  child: Text('Skip', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary))))),
            Expanded(child: PageView.builder(
              controller: _ctrl,
              onPageChanged: (i) => setState(() => _page = i),
              itemCount: _pages.length,
              itemBuilder: (_, i) => _pages[i],
            )),
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _page == i ? 24 : 8, height: 8,
                decoration: BoxDecoration(
                  color: _page == i ? _pages[_page].color : AppColors.border,
                  borderRadius: BorderRadius.circular(4)),
              ))),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _pages[_page].color),
                onPressed: () {
                  if (_page < _pages.length - 1) {
                    _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  } else { _goToAuth(); }
                },
                child: Text(_page < _pages.length - 1 ? 'Next' : 'Get Started'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  final String emoji, title, subtitle;
  final Color color;
  const _Page({required this.emoji, required this.title, required this.subtitle, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 160, height: 160,
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 72)))),
        const SizedBox(height: 40),
        Text(title, style: AppTextStyles.headlineLarge, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text(subtitle, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
      ]),
    );
  }
}