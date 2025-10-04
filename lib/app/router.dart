import 'package:flutter/material.dart';
import 'package:vodid_prototype2/features/polls/presentation/today_polls_screen.dart';
import 'package:vodid_prototype2/features/polls/admin/dev_admin_seed_screen.dart';
import 'package:vodid_prototype2/features/comments/presentation/comment_thread.dart';

/// Uygulamanın tüm route'larını yöneten sınıf.
/// Yeni ekran eklendiğinde buraya eklemen yeterli.
class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
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
