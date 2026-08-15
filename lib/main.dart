import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'data/services/notification_service.dart';
import 'presentation/onboarding/onboarding_screen.dart';
import 'presentation/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,  // white icons on blue bg
  ));
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.init();
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

// ── Splash Screen ─────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late final AnimationController _iconCtrl;
  late final AnimationController _textCtrl;

  // Icon: scale in from 0 then pulse
  late final Animation<double> _iconScale;
  late final Animation<double> _iconFade;

  // Text + badges: fade+slide up after icon settles
  late final Animation<double> _textFade;
  late final Animation<double> _textSlide;

  // Exit: icon shrinks toward top-left (where it lands on get-started page)
  bool _exiting = false;

  @override
  void initState() {
    super.initState();

    _iconCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
    _textCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));

    _iconScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.1)
        .chain(CurveTween(curve: Curves.easeOut)), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0)
        .chain(CurveTween(curve: Curves.easeIn)), weight: 30),
    ]).animate(_iconCtrl);

    _iconFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconCtrl,
        curve: const Interval(0, 0.4, curve: Curves.easeIn)));

    _textFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _textSlide = Tween(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    // Sequence: icon in → pause → text in → wait → navigate
    _iconCtrl.forward().then((_) {
      _textCtrl.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 1200), _navigate);
      });
    });
  }

  void _navigate() {
    if (!mounted) return;
    setState(() => _exiting = true);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      Navigator.pushReplacement(context,
        _HeroPageRoute(builder: (_) => isLoggedIn
          ? const HomeScreen()
          : const OnboardingScreen()));
    });
  }

  @override
  void dispose() {
    _iconCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([_iconCtrl, _textCtrl]),
            builder: (_, __) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // ── Animated icon ────────────────────────────────
                  AnimatedOpacity(
                    opacity: _exiting ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 400),
                    child: Hero(
                      tag: 'app_icon',
                      child: Container(
                        width: 110, height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 2)),
                        child: const Icon(Icons.search_rounded,
                          color: Colors.white, size: 58),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  AnimatedOpacity(
                    opacity: _exiting ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 400),
                    child: Column(children: [
                        Text(AppConstants.appName,
                          style: AppTextStyles.displayMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text('Lost & Found for Pakistani Universities',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.8))),
                      const SizedBox(height: 48),

                      // ── University badges ───────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          spacing: 8, runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: ['NUST','FAST','LUMS','BUITEMS',
                              'COMSATS','GIKI','UET','IBA','QAU']
                            .map((u) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius:
                                  BorderRadius.circular(AppDimens.radiusFull),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3))),
                              child: Text(u,
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600))))
                            .toList(),
                        )),

                      const SizedBox(height: 24),
                    ]),  // AnimatedOpacity Column
                  ),     // AnimatedOpacity
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Fade page route that preserves Hero ───────────────────────────────────────
class _HeroPageRoute extends PageRouteBuilder {
  final WidgetBuilder builder;
  _HeroPageRoute({required this.builder})
    : super(
        pageBuilder: (ctx, _, __) => builder(ctx),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child));
}