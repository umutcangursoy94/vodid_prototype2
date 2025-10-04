import 'package:flutter/material.dart';

/// Uygulama genelinde kullanılan yükleniyor widget'ı.
/// Ortada dönen progress göstergesi sunar.
class Loading extends StatelessWidget {
  final String? message;
  final bool fullscreen;

  const Loading({
    super.key,
    this.message,
    this.fullscreen = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (fullscreen) {
      return Scaffold(
        body: Center(child: content),
      );
    } else {
      return Center(child: content);
    }
  }
}
