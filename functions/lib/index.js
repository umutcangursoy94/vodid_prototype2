"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.incrementShareCount = exports.toggleSavePoll = exports.likeComment = exports.addReply = exports.addComment = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();
const regionalFunctions = functions.region("europe-west1");
async function parseMentions(text) {
    const mentions = text.match(/@(\w+)/g) || [];
    if (mentions.length === 0) {
        return [];
    }
    const usernames = mentions.map((mention) => mention.substring(1));
    const uniqueUsernames = [...new Set(usernames)];
    const mentionedUids = [];
    for (const username of uniqueUsernames) {
        try {
            const userQuery = await db.collection("users").where("username", "==", username).limit(1).get();
            if (!userQuery.empty) {
                mentionedUids.push(userQuery.docs[0].id);
            }
        }
        catch (error) {
            console.error(`Kullanıcı adı ${username} için UID bulunurken hata oluştu:`, error);
        }
    }
    return mentionedUids;
}
exports.addComment = regionalFunctions.https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
        throw new functions.https.HttpsError("unauthenticated", "Yorum yapmak için giriş yapmalısınız.");
    }
    const { pollId, text } = data;
    if (!pollId || !text) {
        throw new functions.https.HttpsError("invalid-argument", "pollId ve text gereklidir.");
    }
    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Kullanıcı bulunamadı.");
    }
    const userData = userDoc.data();
    const pollDocRef = db.collection("polls").doc(pollId);
    const mentionedUids = await parseMentions(text);
    const newCommentRef = pollDocRef.collection("comments").doc();
    const batch = db.batch();
    batch.set(newCommentRef, {
        text: text,
        uid: uid,
        displayName: userData.displayName || "Anonim",
        username: userData.username || "",
        photoURL: userData.photoURL || null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        pollId: pollId,
        likeCount: 0,
        replyCount: 0,
        likes: {},
        mentions: mentionedUids,
    });
    batch.update(pollDocRef, { commentsCount: admin.firestore.FieldValue.increment(1) });
    batch.update(userDoc.ref, { commentsCount: admin.firestore.FieldValue.increment(1) });
    await batch.commit();
    return { success: true, commentId: newCommentRef.id };
});
exports.addReply = regionalFunctions.https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
        throw new functions.https.HttpsError("unauthenticated", "Yanıtlamak için giriş yapmalısınız.");
    }
    const { pollId, commentId, text } = data;
    if (!pollId || !commentId || !text) {
        throw new functions.https.HttpsError("invalid-argument", "pollId, commentId, ve text gereklidir.");
    }
    const user = await admin.auth().getUser(uid);
    const commentRef = db.collection("polls").doc(pollId).collection("comments").doc(commentId);
    const replyRef = commentRef.collection("replies").doc();
    const mentionedUids = await parseMentions(text);
    await replyRef.set({
        text: text,
        uid: uid,
        displayName: user.displayName || "Anonim",
        photoURL: user.photoURL || null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        mentions: mentionedUids,
    });
    await commentRef.update({
        replyCount: admin.firestore.FieldValue.increment(1),
    });
    return { success: true };
});
exports.likeComment = regionalFunctions.https.onCall(async (data, context) => {
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
        await commentRef.update({ likes, likeCount: likeCount - 1 });
        return { liked: false };
    }
    else {
        likes[uid] = true;
        await commentRef.update({ likes, likeCount: likeCount + 1 });
        return { liked: true };
    }
});
exports.toggleSavePoll = regionalFunctions.https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
        throw new functions.https.HttpsError("unauthenticated", "Bu işlem için giriş yapmalısınız.");
    }
    const { pollId } = data;
    if (!pollId) {
        throw new functions.https.HttpsError("invalid-argument", "pollId gereklidir.");
    }
    const userSavedPollsRef = db.collection("users").doc(uid).collection("savedPolls").doc(pollId);
    const pollRef = db.collection("polls").doc(pollId);
    const doc = await userSavedPollsRef.get();
    if (doc.exists) {
        await userSavedPollsRef.delete();
        await pollRef.set({ savedByCount: admin.firestore.FieldValue.increment(-1) }, { merge: true });
        return { saved: false };
    }
    else {
        await userSavedPollsRef.set({
            savedAt: admin.firestore.FieldValue.serverTimestamp(),
            pollRef: pollRef,
        });
        await pollRef.set({ savedByCount: admin.firestore.FieldValue.increment(1) }, { merge: true });
        return { saved: true };
    }
});
exports.incrementShareCount = regionalFunctions.https.onCall(async (data, context) => {
    const { pollId, platform } = data;
    if (!pollId || !platform) {
        throw new functions.https.HttpsError("invalid-argument", "pollId ve platform gereklidir.");
    }
    const pollRef = db.collection("polls").doc(pollId);
    await pollRef.set({
        shareCounts: {
            [platform.replace(/\./g, '_')]: admin.firestore.FieldValue.increment(1)
        }
    }, { merge: true });
    return { success: true };
});
//# sourceMappingURL=index.js.map