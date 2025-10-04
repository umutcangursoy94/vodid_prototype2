// Firebase Admin SDK ve Cloud Functions'ı projemize dahil ediyoruz.
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Bir ankete YENİ BİR YORUM eklendiğinde tetiklenecek fonksiyon.
exports.onCommentCreated = functions.firestore
  // Wildcard {pollId} ve {commentId} ile TÜM anketlerin altındaki
  // TÜM yorumları dinliyoruz.
  .document("polls/{pollId}/comments/{commentId}")
  .onCreate(async (snap, context) => {
    // Yorumu yapan kullanıcının UID'sini alıyoruz.
    const commentData = snap.data();
    const userId = commentData.uid;

    if (!userId) {
      console.log("Yorumda kullanıcı UID'si bulunamadı.");
      return null;
    }

    // İlgili kullanıcının Firestore'daki döküman referansını alıyoruz.
    const userRef = admin.firestore().collection("users").doc(userId);

    try {
      // FieldValue.increment(1) kullanarak commentsCount alanını
      // atomik olarak 1 artırıyoruz. Bu, aynı anda birden fazla
      // işlem olsa bile sayının doğru kalmasını sağlar.
      await userRef.update({
        commentsCount: admin.firestore.FieldValue.increment(1),
      });
      console.log(`Kullanıcı ${userId} için yorum sayısı artırıldı.`);
      return null;
    } catch (error) {
      console.error(
        `Kullanıcı ${userId} için yorum sayısı artırılamadı:`,
        error
      );
      return null;
    }
  });

// Bir anketten BİR YORUM SİLİNDİĞİNDE tetiklenecek fonksiyon.
exports.onCommentDeleted = functions.firestore
  .document("polls/{pollId}/comments/{commentId}")
  .onDelete(async (snap, context) => {
    // Silinen yorumun verilerini alıyoruz.
    const commentData = snap.data();
    const userId = commentData.uid;

    if (!userId) {
      console.log("Silinen yorumda kullanıcı UID'si bulunamadı.");
      return null;
    }

    // İlgili kullanıcının döküman referansı.
    const userRef = admin.firestore().collection("users").doc(userId);

    try {
      // FieldValue.increment(-1) kullanarak sayıyı 1 eksiltiyoruz.
      await userRef.update({
        commentsCount: admin.firestore.FieldValue.increment(-1),
      });
      console.log(`Kullanıcı ${userId} için yorum sayısı azaltıldı.`);
      return null;
    } catch (error) {
      console.error(
        `Kullanıcı ${userId} için yorum sayısı azaltılamadı:`,
        error
      );
      return null;
    }
  });