import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();
  static const primary        = Color(0xFF1A73E8);
  static const primaryDark    = Color(0xFF1558B0);
  static const primaryLight   = Color(0xFFD2E3FC);
  static const secondary      = Color(0xFF34A853);
  static const secondaryDark  = Color(0xFF1E7E34);
  static const secondaryLight = Color(0xFFCEEAD6);
  static const accent         = Color(0xFFFBBC05);
  static const error          = Color(0xFFEA4335);
  static const errorLight     = Color(0xFFFCE8E6);
  static const background     = Color(0xFFF8F9FA);
  static const surface        = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF1F3F4);
  static const border         = Color(0xFFDADCE0);
  static const textPrimary    = Color(0xFF202124);
  static const textSecondary  = Color(0xFF5F6368);
  static const textHint       = Color(0xFF9AA0A6);
  static const textOnPrimary  = Color(0xFFFFFFFF);
  static const statusActive   = Color(0xFF34A853);
  static const statusPending  = Color(0xFFFBBC05);
  static const statusResolved = Color(0xFF1A73E8);
  static const statusExpired  = Color(0xFF9AA0A6);
  static const lostColor      = Color(0xFFEA4335);
  static const lostLight      = Color(0xFFFCE8E6);
  static const foundColor     = Color(0xFF34A853);
  static const foundLight     = Color(0xFFCEEAD6);
  static const handoff        = Color(0xFF9C27B0);
  static const handoffLight   = Color(0xFFF3E5F5);
  static const shadowLight    = Color(0x0D000000);
  static const shadowMedium   = Color(0x1A000000);
}

class AppTextStyles {
  AppTextStyles._();
  static TextStyle get displayLarge => GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.2);
  static TextStyle get displayMedium => GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3);
  static TextStyle get headlineLarge => GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3);
  static TextStyle get headlineMedium => GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4);
  static TextStyle get headlineSmall => GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4);
  static TextStyle get titleLarge => GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.5);
  static TextStyle get titleMedium => GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.5);
  static TextStyle get bodyLarge => GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.6);
  static TextStyle get bodyMedium => GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.6);
  static TextStyle get bodySmall => GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5);
  static TextStyle get labelLarge => GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary, letterSpacing: 0.1);
  static TextStyle get labelMedium => GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary, letterSpacing: 0.5);
  static TextStyle get caption => GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textHint, height: 1.4);
  static TextStyle get buttonText => GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3);
  static TextStyle get overline => GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textHint, letterSpacing: 1.2);
}

class AppDimens {
  AppDimens._();
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 20.0;
  static const double xxl  = 24.0;
  static const double xxxl = 32.0;
  static const double radiusXs   = 6.0;
  static const double radiusSm   = 8.0;
  static const double radiusMd   = 12.0;
  static const double radiusLg   = 16.0;
  static const double radiusXl   = 20.0;
  static const double radiusFull = 100.0;
  static const double buttonHeight   = 52.0;
  static const double buttonHeightSm = 40.0;
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;
  static const double postImageHeight = 220.0;
}

class AppShadows {
  AppShadows._();
  static List<BoxShadow> get card => [
    const BoxShadow(color: AppColors.shadowLight, blurRadius: 8, offset: Offset(0, 2)),
    const BoxShadow(color: AppColors.shadowMedium, blurRadius: 4, offset: Offset(0, 1)),
  ];
  static List<BoxShadow> get elevated => [
    const BoxShadow(color: AppColors.shadowMedium, blurRadius: 16, offset: Offset(0, 4)),
  ];
  static List<BoxShadow> get button => [
    BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
      surface: AppColors.surface,
      onPrimary: AppColors.textOnPrimary,
      onSurface: AppColors.textPrimary,
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: GoogleFonts.poppins().fontFamily,

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.headlineSmall,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      surfaceTintColor: Colors.transparent,
    ),

    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      margin: EdgeInsets.zero,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        minimumSize: const Size(double.infinity, AppDimens.buttonHeight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
        elevation: 0,
        textStyle: AppTextStyles.buttonText,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, AppDimens.buttonHeight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        textStyle: AppTextStyles.buttonText,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTextStyles.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: const BorderSide(color: AppColors.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
      labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
      floatingLabelStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
      prefixIconColor: AppColors.textSecondary,
      suffixIconColor: AppColors.textSecondary,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceVariant,
      selectedColor: AppColors.primaryLight,
      labelStyle: AppTextStyles.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        side: const BorderSide(color: AppColors.border),
      ),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textHint,
      selectedLabelStyle: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
      unselectedLabelStyle: AppTextStyles.caption,
      type: BottomNavigationBarType.fixed,
      elevation: 12,
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
      elevation: 4,
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 0.8,
      space: 0,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: AppTextStyles.bodySmall.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSm)),
      behavior: SnackBarBehavior.floating,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusLg)),
      titleTextStyle: AppTextStyles.headlineSmall,
      contentTextStyle: AppTextStyles.bodyMedium,
      elevation: 8,
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimens.radiusXl),
          topRight: Radius.circular(AppDimens.radiusXl),
        ),
      ),
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      labelStyle: AppTextStyles.labelLarge,
      unselectedLabelStyle: AppTextStyles.labelMedium,
      indicator: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.primary, width: 2.5),
        ),
      ),
      indicatorSize: TabBarIndicatorSize.label,
    ),
  );
}