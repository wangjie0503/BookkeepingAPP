import 'package:flutter/material.dart';

/// Shared visual tokens for the calm, personal bookkeeping interface.
abstract final class AppPalette {
  static const canvas = Color(0xfff3f7f6);
  static const surface = Color(0xffffffff);
  static const ink = Color(0xff18312e);
  static const mutedInk = Color(0xff5f716e);
  static const teal = Color(0xff0d8b7e);
  static const tealDark = Color(0xff06645b);
  static const mint = Color(0xffd9f3ed);
  static const line = Color(0xffdce7e4);
  static const warm = Color(0xfff3ad58);
  static const lavender = Color(0xff9b8ee9);
  static const coral = Color(0xffeb8372);
  static const sky = Color(0xff68a8d8);

  static const chartColors = <Color>[teal, warm, lavender, coral, sky];
}

ThemeData buildAppTheme() {
  final colors =
      ColorScheme.fromSeed(
        seedColor: AppPalette.teal,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppPalette.teal,
        onPrimary: Colors.white,
        primaryContainer: AppPalette.mint,
        onPrimaryContainer: AppPalette.tealDark,
        surface: AppPalette.surface,
        onSurface: AppPalette.ink,
        outline: AppPalette.line,
        error: const Color(0xffc94b40),
      );
  const rounded14 = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
  );
  const rounded20 = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    scaffoldBackgroundColor: AppPalette.canvas,
    textTheme: ThemeData.light().textTheme.apply(
      bodyColor: AppPalette.ink,
      displayColor: AppPalette.ink,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: AppPalette.canvas,
      foregroundColor: AppPalette.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: AppPalette.ink,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppPalette.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: rounded20,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppPalette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: AppPalette.line),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: AppPalette.line),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: AppPalette.teal, width: 1.5),
      ),
      labelStyle: const TextStyle(color: AppPalette.mutedInk),
      hintStyle: TextStyle(color: AppPalette.mutedInk.withValues(alpha: 0.72)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        shape: rounded14,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: const BorderSide(color: AppPalette.line),
        shape: rounded14,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: rounded14),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppPalette.surface,
      selectedColor: AppPalette.mint,
      side: const BorderSide(color: AppPalette.line),
      shape: rounded14,
      labelStyle: const TextStyle(color: AppPalette.ink),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: AppPalette.surface,
      indicatorColor: AppPalette.mint,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? AppPalette.tealDark
              : AppPalette.mutedInk,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: AppPalette.surface,
      indicatorColor: AppPalette.mint,
      selectedIconTheme: IconThemeData(color: AppPalette.tealDark),
      selectedLabelTextStyle: TextStyle(
        color: AppPalette.tealDark,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: TextStyle(color: AppPalette.mutedInk),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      iconColor: AppPalette.teal,
    ),
    dividerTheme: const DividerThemeData(color: AppPalette.line),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppPalette.surface,
      shape: rounded20,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppPalette.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: rounded14,
    ),
  );
}
