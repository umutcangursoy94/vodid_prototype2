import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

function todayIdUTC(): string {
  const now = new Date();
  const yyyy = now.getUTCFullYear();
  const mm = String(now.getUTCMonth() + 1).padStart(2, "0");
  const dd = String(now.getUTCDate()).padStart(2, "0");
  return `${yyyy}-${mm}-${dd}`;
}

// ... (submitVote, adminCreateDailySet, createDailySetHttp fonksiyonları aynı kalacak)

export const likeComment = functions.https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
        throw new functions.https.HttpsError("unauthenticated", "Beğenmek için giriş yapmalısınız.");
    }

    const { pollId, commentId } = data;
    if (!pollId || !commentId) {
        throw new functions.https.HttpsError("invalid-argument", "pollId ve commentId gereklidir.");
    }

    const commentRef = db.collection("polls").doc(pollId).collection("comments").doc(commentId);
    const commentDoc = await commentRef.get();

    if (!commentDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Yorum bulunamadı.");
    }

    const likes = commentDoc.data()?.likes || {};
    const likeCount = commentDoc.data()?.likeCount || 0;

    if (likes[uid]) {
        delete likes[uid];
        await commentRef.update({
            likes,
            likeCount: likeCount - 1,
        });
        return { liked: false };
    } else {
        likes[uid] = true;
        await commentRef.update({
            likes,
            likeCount: likeCount + 1,
        });
        return { liked: true };
    }
});

export const addReply = functions.https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
        throw new functions.https.HttpsError("unauthenticated", "Yanıtlamak için giriş yapmalısınız.");
    }

    const { pollId, commentId, text } = data;
    if (!pollId || !commentId || !text) {
        throw new functions.https.HttpsError("invalid-argument", "pollId, commentId, ve text gereklidir.");
    }

    const commentRef = db.collection("polls").doc(pollId).collection("comments").doc(commentId);
    const replyRef = commentRef.collection("replies").doc();

    await replyRef.set({
        text,
        uid,
        displayName: context.auth?.token.name || "Anonim",
        photoURL: context.auth?.token.picture || null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await commentRef.update({
        replyCount: admin.firestore.FieldValue.increment(1),
    });

    return { success: true };
});