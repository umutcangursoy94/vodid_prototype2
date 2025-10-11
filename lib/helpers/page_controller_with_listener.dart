import 'package:flutter/material.dart';

/// Bu özel PageController, her kaydırma olayında (scroll) listener'ları
/// haberdar eder. Normal PageController sadece kaydırma bittiğinde haber verir.
/// Bu sayede sayfa değişimlerini anlık olarak yakalayabiliriz.
class PageControllerWithListener extends PageController {
  final VoidCallback _listener;

  PageControllerWithListener({required VoidCallback listener})
      : _listener = listener,
        super();

  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    position.addListener(_listener);
  }

  @override
  void detach(ScrollPosition position) {
    position.removeListener(_listener);
    super.detach(position);
  }
}