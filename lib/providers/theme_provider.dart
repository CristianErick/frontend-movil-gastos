import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  static const _primary = Color(0xFF6366F1);
  static const _accent = Color(0xFF06B6D4);
  static const _success = Color(0xFF10B981);
  static const _error = Color(0xFFEF4444);
  static const _surfaceLight = Color(0xFFF8FAFC);

  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.light,
          primary: _primary,
          secondary: _accent,
          tertiary: _success,
          error: _error,
          surface: Colors.white,
          surfaceContainerHighest: _surfaceLight,
          onSurface: const Color(0xFF0F172A),
          onSurfaceVariant: const Color(0xFF475569),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.25),
          displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.1),
          titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
          titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.1),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.4),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.3),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
          labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.5),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surfaceLight,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _error.withValues(alpha: 0.5)),
          ),
          labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500),
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          floatingLabelStyle: const TextStyle(color: _primary, fontWeight: FontWeight.w600),
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 8,
          height: 72,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: _primary.withValues(alpha: 0.12),
          indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _primary);
            }
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B));
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: _primary, size: 24);
            }
            return const IconThemeData(color: Color(0xFF64748B), size: 24);
          }),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
          focusElevation: 0,
          hoverElevation: 0,
          highlightElevation: 0,
          shape: CircleBorder(),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          side: BorderSide(color: Colors.grey.shade200),
          selectedColor: _primary.withValues(alpha: 0.12),
          checkmarkColor: _primary,
          backgroundColor: _surfaceLight,
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey.shade200,
          thickness: 1,
          space: 1,
        ),
        listTileTheme: ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
          subtitleTextStyle: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          elevation: 8,
          modalBackgroundColor: Colors.white,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          contentTextStyle: TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF1E293B),
          contentTextStyle: const TextStyle(fontSize: 14, color: Colors.white),
          actionTextColor: _accent,
        ),
      );

  ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.dark,
          primary: _primary,
          secondary: _accent,
          tertiary: _success,
          error: _error,
          surface: const Color(0xFF1E1E2E),
          surfaceContainerHighest: const Color(0xFF2A2A3D),
          onSurface: const Color(0xFFF8FAFC),
          onSurfaceVariant: const Color(0xFF94A3B8),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Colors.white),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.25, color: Colors.white),
          displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
          headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
          headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.1, color: Colors.white),
          titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, color: Colors.white),
          titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.1, color: Colors.white),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.4, color: Color(0xFFE2E8F0)),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.3, color: Color(0xFF94A3B8)),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1, color: Colors.white),
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: Colors.white),
          labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: Color(0xFF94A3B8)),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
          backgroundColor: Color(0xFF0F172A),
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: const Color(0xFF1E1E2E),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E2E),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF33334D)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF33334D)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _error.withValues(alpha: 0.5)),
          ),
          labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500),
          hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
          floatingLabelStyle: const TextStyle(color: _primary, fontWeight: FontWeight.w600),
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 8,
          height: 72,
          backgroundColor: const Color(0xFF1E1E2E),
          surfaceTintColor: Colors.transparent,
          indicatorColor: _primary.withValues(alpha: 0.18),
          indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _primary);
            }
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8));
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: _primary, size: 24);
            }
            return const IconThemeData(color: Color(0xFF94A3B8), size: 24);
          }),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
          focusElevation: 0,
          hoverElevation: 0,
          highlightElevation: 0,
          shape: CircleBorder(),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          side: BorderSide(color: Color(0xFF33334D)),
          selectedColor: _primary.withValues(alpha: 0.18),
          checkmarkColor: _primary,
          backgroundColor: Color(0xFF1E1E2E),
        ),
        dividerTheme: DividerThemeData(
          color: Color(0xFF33334D),
          thickness: 1,
          space: 1,
        ),
        listTileTheme: ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
          subtitleTextStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: Color(0xFF1E1E2E),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          elevation: 8,
          modalBackgroundColor: Color(0xFF1E1E2E),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Color(0xFF1E1E2E),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
          contentTextStyle: const TextStyle(fontSize: 14, color: Color(0xFFE2E8F0)),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF334155),
          contentTextStyle: const TextStyle(fontSize: 14, color: Colors.white),
          actionTextColor: _accent,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      );

  Color get surfaceContainerLow => _themeMode == ThemeMode.dark
      ? const Color(0xFF1A1A2E)
      : _surfaceLight;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  void toggle() {
    final next = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(next);
  }
}