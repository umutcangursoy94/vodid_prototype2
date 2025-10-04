import 'package:intl/intl.dart';

/// Uygulama genelinde tarih, saat ve sayı formatlamaları için yardımcı fonksiyonlar.
class Formatters {
  Formatters._();

  /// Tarihi (DateTime) dd.MM.yyyy formatında döner.
  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  /// Tarihi (DateTime) dd.MM.yyyy HH:mm formatında döner.
  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  /// Sadece saati (HH:mm) formatında döner.
  static String formatTime(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('HH:mm').format(date);
  }

  /// Büyük sayıları (örn: 1200 → 1.2K) daha okunabilir hale getirir.
  static String formatCompactNumber(num number) {
    final formatter = NumberFormat.compact(locale: 'tr_TR');
    return formatter.format(number);
  }
}
