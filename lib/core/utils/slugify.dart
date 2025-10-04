/// String değerlerden Firestore döküman ID'si veya URL dostu slug üretmek için yardımcı sınıf.
class Slugify {
  Slugify._();

  /// Verilen string'i küçük harfe çevirir, boşlukları ve özel karakterleri temizler.
  /// Örn: "Bugün Anket Var!" → "bugun-anket-var"
  static String generate(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'ğ'), 'g')
        .replaceAll(RegExp(r'ü'), 'u')
        .replaceAll(RegExp(r'ş'), 's')
        .replaceAll(RegExp(r'ı'), 'i')
        .replaceAll(RegExp(r'ö'), 'o')
        .replaceAll(RegExp(r'ç'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-') // sadece a-z ve 0-9 kalsın
        .replaceAll(RegExp(r'-+'), '-') // birden fazla - varsa teke düşür
        .replaceAll(RegExp(r'^-|-$'), ''); // baştaki/sondaki - sil
  }
}
