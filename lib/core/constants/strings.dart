/// Uygulama genelinde kullanılan sabit stringler.
/// Buraya eklenen metinler hem merkezi yönetim sağlar
/// hem de çoklu dil desteğine geçişi kolaylaştırır.
class AppStrings {
  AppStrings._();

  static const String appName = 'Vodid';

  // Genel
  static const String ok = 'Tamam';
  static const String cancel = 'İptal';
  static const String error = 'Hata';
  static const String couldNotLoad = 'Yüklenemedi';
  static const String noData = 'Veri bulunamadı';

  // Anketler
  static const String todaysPoll = 'Bugünün Anketi';
  static const String noPollFound = 'Aktif anket bulunamadı';
  static const String createPoll = 'Anket Oluştur';
  static const String addSampleComment = 'Örnek Yorum Ekle';
  static const String addSampleReply = 'Örnek Yanıt Ekle';
  static const String adminTitle = 'Admin - Seed Screen';

  // Yorumlar
  static const String comments = 'Yorumlar';
  static const String replies = 'Yanıtlar';
  static const String writeComment = 'Yorum yaz...';
  static const String writeReply = 'Yanıt yaz...';
  static const String sendFailed = 'Gönderilemedi';
  static const String noCommentsYet = 'Henüz yorum yok';

  // Kullanıcı
  static const String profile = 'Profil';
  static const String signin = 'Giriş Yap';
}
