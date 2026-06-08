import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppColors {
  static const Color primaryStart = Color(0xFF4E4AF2);
  static const Color primaryEnd = Color(0xFF34C8E8);
  static const Color danger = Color(0xFFFF6B6B);

  // Auth screens always use the dark palette styling.
  static const Color background = Color(0xFF1B1E28);
  static const Color surface = Color(0xFF232736);
  static const Color surfaceLight = Color(0xFF2D3142);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9BA4B5);
  static const Color textMuted = Color(0xFF6B7280);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryStart, primaryEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF1B1E28), Color(0xFF151821)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1B1E28), Color(0xFF2A2F6E), Color(0xFF1B3A5C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppPalette {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.divider,
    required this.cardBorder,
    required this.inputFill,
    required this.shadow,
    required this.backgroundGradient,
  });

  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color divider;
  final Color cardBorder;
  final Color inputFill;
  final Color shadow;
  final LinearGradient backgroundGradient;

  static AppPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
  }

  static const dark = AppPalette(
    background: Color(0xFF1B1E28),
    surface: Color(0xFF232736),
    surfaceLight: Color(0xFF2D3142),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF9BA4B5),
    textMuted: Color(0xFF6B7280),
    divider: Color(0x14FFFFFF),
    cardBorder: Color(0x14FFFFFF),
    inputFill: Color(0xFF1A1D27),
    shadow: Color(0x59000000),
    backgroundGradient: AppColors.backgroundGradient,
  );

  static const light = AppPalette(
    background: Color(0xFFF3F5FA),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFF0F2F8),
    textPrimary: Color(0xFF1B1E28),
    textSecondary: Color(0xFF5C6370),
    textMuted: Color(0xFF8B93A1),
    divider: Color(0xFFE8ECF4),
    cardBorder: Color(0xFFE2E6EF),
    inputFill: Color(0xFFF5F7FC),
    shadow: Color(0x1A1A2E40),
    backgroundGradient: LinearGradient(
      colors: [Color(0xFFF3F5FA), Color(0xFFE9EDF6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
}

class AppDecorations {
  static BoxDecoration glassCard(
    BuildContext context, {
    double radius = 24,
  }) {
    final palette = AppPalette.of(context);
    return BoxDecoration(
      color: palette.surface,
      borderRadius: BorderRadius.circular(radius.r),
      border: Border.all(color: palette.cardBorder),
      boxShadow: [
        BoxShadow(
          color: palette.shadow,
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration secondaryButton(
    BuildContext context, {
    double radius = 20,
  }) {
    final palette = AppPalette.of(context);
    return BoxDecoration(
      color: palette.surfaceLight,
      borderRadius: BorderRadius.circular(radius.r),
      border: Border.all(color: palette.cardBorder),
      boxShadow: [
        BoxShadow(
          color: palette.shadow,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

class AppTheme {
  static ThemeData _baseTheme(AppPalette palette, Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: palette.background,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primaryStart,
        onPrimary: Colors.white,
        secondary: AppColors.primaryEnd,
        onSecondary: Colors.white,
        error: AppColors.danger,
        onError: Colors.white,
        surface: palette.surface,
        onSurface: palette.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
        iconTheme: IconThemeData(color: palette.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: palette.cardBorder),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.divider,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surfaceLight,
        contentTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14.sp,
          color: palette.textPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.inputFill,
        hintStyle: TextStyle(
          color: palette.textMuted,
          fontSize: 14.sp,
          fontFamily: 'Poppins',
        ),
        labelStyle: TextStyle(
          color: palette.textSecondary,
          fontSize: 14.sp,
          fontFamily: 'Poppins',
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.r),
          borderSide: BorderSide(color: palette.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.r),
          borderSide: const BorderSide(
            color: AppColors.primaryEnd,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.r),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 20.w,
          vertical: 18.h,
        ),
      ),
    );
  }

  static ThemeData get darkTheme =>
      _baseTheme(AppPalette.dark, Brightness.dark);

  static ThemeData get lightTheme =>
      _baseTheme(AppPalette.light, Brightness.light);
}
