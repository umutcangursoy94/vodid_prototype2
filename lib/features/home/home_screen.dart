import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vodid_prototype2/core/constants/strings.dart';

/// Uygulamanın ana ekranı.
/// Kullanıcıya farklı sayfalara gitmesi için menü sunar.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _HomeItem("Bugünün Anketi", Icons.poll, '/poll'),
      _HomeItem("Arama", Icons.search, '/search'),
      _HomeItem("Oylarım", Icons.how_to_vote, '/votes'),
      _HomeItem("Profil", Icons.person, '/profile'),
      _HomeItem("Giriş Yap", Icons.login, '/signin'),
      _HomeItem("Özet", Icons.article, '/summary'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
      ),
      body: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: Icon(item.icon),
            title: Text(item.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(item.route),
          );
        },
      ),
    );
  }
}

class _HomeItem {
  final String title;
  final IconData icon;
  final String route;

  _HomeItem(this.title, this.icon, this.route);
}
