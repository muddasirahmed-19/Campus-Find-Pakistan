import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      emoji: '🔍',
      title: 'Lost Something?',
      subtitle: 'Post your lost item and let your\ncampus community help you find it.',
      color: Color(0xFF1A73E8),
    ),
    _OnboardingPage(
      emoji: '📦',
      title: 'Found Something?',
      subtitle: 'Report found items and help reunite\nthem with their rightful owners.',
      color: Color(0xFF34A853),
    ),
    _OnboardingPage(
      emoji: '🤝',
      title: 'Safe Handoff',
      subtitle: 'Our dual-confirmation system ensures\nitems are returned safely and securely.',
      color: Color(0xFF9C27B0),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => _goToAuth(context),
                  child: Text('Skip', style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textSecondary)),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _pages[i],
              ),
            ),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == i ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? _pages[_currentPage].color
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            const SizedBox(height: 32),

            // Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pages[_currentPage].color,
                ),
                onPressed: () {
                  if (_currentPage < _pages.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    _goToAuth(context);
                  }
                },
                child: Text(
                  _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _goToAuth(BuildContext context) {
    Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => const AuthGateScreen()));
  }
}

class _OnboardingPage extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;

  const _OnboardingPage({
    required this.emoji, required this.title,
    required this.subtitle, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140, height: 140,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 64)),
            ),
          ),
          const SizedBox(height: 40),
          Text(title, style: AppTextStyles.headlineLarge, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(subtitle,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// Placeholder for auth gate (will be replaced in Phase 2)
class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome to CampusFind PK', style: AppTextStyles.headlineLarge),
            const SizedBox(height: 8),
            Text('Sign in to find lost items on your campus',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 40),

            // Phone number field
            Text('Phone Number', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '03XXXXXXXXX',
                prefixIcon: Icon(Icons.phone_outlined),
                prefixText: '+92 ',
              ),
            ),
            const SizedBox(height: 16),

            // University dropdown
            Text('University', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                hintText: 'Select your university',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              items: ['NUST', 'FAST-NUCES', 'BUITEMS', 'COMSATS', 'LUMS',
                      'IBA', 'QAU', 'GIKI', 'Air University', 'UET Lahore']
                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                  .toList(),
              onChanged: (_) {},
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () {},
              child: const Text('Send OTP'),
            ),
            const SizedBox(height: 12),

            // Divider
            Row(children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('or', style: AppTextStyles.caption),
              ),
              const Expanded(child: Divider()),
            ]),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.email_outlined),
              label: const Text('Continue with University Email'),
            ),
          ],
        ),
      ),
    );
  }
}