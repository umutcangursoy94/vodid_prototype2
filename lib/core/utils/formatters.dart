import 'package:intl/intl.dart';

/// Uygulama genelinde kullanılan formatlama yardımcıları.
/// Tek yerde tutarak tarih/sayı biçimlerini standart hale getirir.
class Formatters {
  /// Tarihi (dd.MM.yyyy) formatında döndürür.
  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  /// Tarihi (dd.MM.yyyy HH:mm) formatında döndürür.
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
  }

  /// Sadece saat (HH:mm) formatı.
  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Sayıyı binlik ayırıcılarla (1.234, 56) döndürür.
  static String formatNumber(num? number, {int decimalDigits = 0}) {
    if (number == null) return '-';
    final format = NumberFormat.decimalPattern('tr_TR')
      ..minimumFractionDigits = decimalDigits
      ..maximumFractionDigits = decimalDigits;
    return format.format(number);
  }

  /// Yüzde formatı (örn: 23 → %23)
  static String formatPercent(num? value, {int decimalDigits = 0}) {
    if (value == null) return '-';
    final format = NumberFormat.decimalPercentPattern(
      locale: 'tr_TR',
      decimalDigits: decimalDigits,
    );
    return format.format(value / 100);
  }
}
