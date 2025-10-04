import 'package:flutter/material.dart';

/// Uygulama genelinde kullanılan ortak widget temaları.
/// Buradaki stiller [ThemeData] içine entegre edilebilir.
class WidgetsTheme {
  /// Ortak CardTheme
  static CardTheme cardTheme = CardTheme(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    elevation: 2,
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
  );

  /// Ortak InputDecorationTheme
  static InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.indigo, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  );

  /// Ortak ElevatedButtonTheme
  static ElevatedButtonThemeData elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
  );

  /// Ortak TextButtonTheme
  static TextButtonThemeData textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.indigo,
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  );

  /// Ortak OutlinedButtonTheme
  static OutlinedButtonThemeData outlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      side: const BorderSide(color: Colors.indigo),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  );
}
