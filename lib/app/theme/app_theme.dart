import 'package:flutter/material.dart';
import 'widgets_theme.dart';

/// Uygulamanın genel tema ayarları burada toplanır.
/// Renk paleti, yazı tipleri, buton stilleri gibi tüm MaterialTheme ayarlarını içerir.
class AppTheme {
  AppTheme._();

  /// Light tema
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      scaffoldBackgroundColor: Colors.white,
      cardTheme: AppWidgetsTheme.cardTheme,
      elevatedButtonTheme: AppWidgetsTheme.elevatedButtonTheme,
      inputDecorationTheme: AppWidgetsTheme.inputDecorationTheme,
      dividerTheme: const DividerThemeData(
        color: Colors.grey,
        thickness: 0.6,
      ),
    );
  }

  /// Dark tema (opsiyonel, ileride ekleyebilirsin)
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      cardTheme: AppWidgetsTheme.cardTheme,
      elevatedButtonTheme: AppWidgetsTheme.elevatedButtonTheme,
      inputDecorationTheme: AppWidgetsTheme.inputDecorationTheme,
      dividerTheme: const DividerThemeData(
        color: Colors.grey,
        thickness: 0.6,
      ),
    );
  }
}
