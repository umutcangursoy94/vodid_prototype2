import 'dart:math';

/// Metinleri Firestore doküman id'si veya URL için uygun slug formatına çevirir.
class Slugify {
  /// Türkçe karakterleri dönüştürür, boşlukları `-` yapar, küçük harfe çevirir.
  /// Sonuna rastgele 3 harf ekleyerek benzersizliği artırır.
  static String generate(String input) {
    if (input.isEmpty) return '';

    const trMap = {
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
      'Ç': 'c',
      'Ğ': 'g',
      'İ': 'i',
      'Ö': 'o',
      'Ş': 's',
      'Ü': 'u',
    };

    // Türkçe karakterleri dönüştür
    final replaced = input.split('').map((ch) => trMap[ch] ?? ch).join();

    // Sadece harf, sayı ve boşluk bırak
    final cleaned =
        replaced.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s-]'), '').trim();

    // Boşlukları tireye çevir
    final slug = cleaned.replaceAll(RegExp(r'\s+'), '-');

    // Sonuna 3 harflik random suffix ekle
    final rand = String.fromCharCodes(
      List.generate(3, (_) => 97 + Random().nextInt(26)),
    );

    return '$slug-$rand';
  }
}
