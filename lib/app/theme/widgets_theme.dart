import 'package:flutter/material.dart';

/// Uygulamanın genel widget temaları burada tanımlanır.
/// Card, Button, Input gibi bileşenlerin ortak stilleri.
class AppWidgetsTheme {
  AppWidgetsTheme._();

  /// Kart teması
  static const CardTheme cardTheme = CardTheme(
    elevation: 2,
    margin: EdgeInsets.all(8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  );

  /// ElevatedButton teması
  static final ElevatedButtonThemeData elevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  /// Input alanı teması
  static const InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    filled: true,
    fillColor: Color(0xFFF9F9F9),
    contentPadding: EdgeInsets.symmetric(
      vertical: 12,
      horizontal: 16,
    ),
  );
}
