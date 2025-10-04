import 'package:flutter/material.dart';
import 'package:vodid_prototype2/app/theme/app_theme.dart';
import 'package:vodid_prototype2/features/polls/presentation/today_polls_screen.dart';
import 'package:vodid_prototype2/features/polls/admin/dev_admin_seed_screen.dart';
import 'package:vodid_prototype2/features/comments/presentation/comment_thread.dart';

/// Uygulamanın en üst seviyesi.
/// Buradan [MaterialApp], tema ve yönlendirmeler kontrol edilir.
class VodidApp extends StatelessWidget {
  const VodidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vodid',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      initialRoute: '/',
      onGenerateRoute: _onGenerateRoute,
    );
  }

  /// Uygulamanın route (yönlendirme) haritası
  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const TodayPollsScreen(),
        );
      case '/admin':
        return MaterialPageRoute(
          builder: (_) => const DevAdminSeedScreen(),
        );
      case '/comments':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => CommentThreadPage(
            pollId: args['pollId'] as String,
            parentComment: args['parentComment'],
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('404 - Sayfa bulunamadı')),
          ),
        );
    }
  }
}
