import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vodid_prototype2/app/router.dart';
import 'package:vodid_prototype2/app/theme/app_theme.dart';
import 'package:vodid_prototype2/core/constants/strings.dart';

/// Uygulamanın ana widget'ı.
/// Tema, dil desteği ve router burada yönetilir.
class VodidApp extends StatelessWidget {
  const VodidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: AppRouter.router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('tr'),
      ],
    );
  }
}
