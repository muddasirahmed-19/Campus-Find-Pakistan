import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'presentation/onboarding/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: CampusFindApp()));
}

class CampusFindApp extends ConsumerWidget {
  const CampusFindApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale, _slide;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 1000));
    _fade  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _scale = Tween<double>(begin: 0.6, end: 1).animate(CurvedAnimation(
      parent: _ctrl, curve: const Interval(0, 0.7, curve: Curves.elasticOut)));
    _slide = Tween<double>(begin: 40, end: 0).animate(CurvedAnimation(
      parent: _ctrl, curve: const Interval(0.3, 1, curve: Curves.easeOut)));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => FadeTransition(
            opacity: _fade,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                const Spacer(),

                // Logo + Title
                ScaleTransition(
                  scale: _scale,
                  child: Column(children: [
                    Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: AppShadows.button,
                      ),
                      child: const Icon(Icons.search_rounded,
                        color: Colors.white, size: 58),
                    ),
                    const SizedBox(height: 24),
                    Text(AppConstants.appName,
                      style: AppTextStyles.displayMedium
                        .copyWith(color: AppColors.primary)),
                    const SizedBox(height: 8),
                    Text(AppConstants.appTagline,
                      style: AppTextStyles.bodyLarge
                        .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Text('For Pakistani Universities',
                      style: AppTextStyles.caption),
                  ]),
                ),

                const SizedBox(height: 40),

                // University badges
                Transform.translate(
                  offset: Offset(0, _slide.value),
                  child: Wrap(
                    spacing: 8, runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: ['NUST','FAST','LUMS','BUITEMS',
                        'COMSATS','GIKI','UET','IBA','QAU','Air Uni']
                      .map((u) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Text(u, style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                      )).toList(),
                  ),
                ),

                const Spacer(),

                // Single Get Started button only
                Transform.translate(
                  offset: Offset(0, _slide.value),
                  child: Column(children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pushReplacement(context,
                        MaterialPageRoute(
                          builder: (_) => const OnboardingScreen())),
                      child: const Text('Get Started'),
                    ),
                    const SizedBox(height: 32),
                    Text('v1.0.0 • CampusFind PK',
                      style: AppTextStyles.caption),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}