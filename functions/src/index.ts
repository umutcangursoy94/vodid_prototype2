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

export const submitVote = functions.https.onCall(async (data, context) => {
  const uid = context.auth?.uid;
  if (!uid) {
    throw new functions.https.HttpsError("unauthenticated", "Login gerekli");
  }
  const pollId: string = data?.pollId;
  const optionIndex: number = data?.optionIndex;

  if (!pollId || (optionIndex !== 0 && optionIndex !== 1)) {
    throw new functions.https.HttpsError("invalid-argument", "Parametre hatalı");
  }

  const voteDocId = `${uid}_${pollId}`;
  const voteRef = db.collection("votes").doc(voteDocId);

  const dateId = todayIdUTC();
  const pollRef = db.collection("daily_sets").doc(dateId).collection("polls").doc(pollId);

  await db.runTransaction(async (tx) => {
    const existing = await tx.get(voteRef);
    if (existing.exists) {
      throw new functions.https.HttpsError("already-exists", "Bu ankete zaten oy verdin.");
    }

    const pollSnap = await tx.get(pollRef);
    if (!pollSnap.exists) {
      throw new functions.https.HttpsError("not-found", "Anket bulunamadı.");
    }

    tx.set(voteRef, {
      userId: uid,
      pollId,
      option: optionIndex,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: false });

    const inc = admin.firestore.FieldValue.increment(1);
    const updates: Record<string, admin.firestore.FieldValue> = {};
    if (optionIndex === 0) updates["option0Count"] = inc;
    else updates["option1Count"] = inc;

    tx.set(pollRef, updates, { merge: true });
  });

  return { ok: true };
});

export const adminCreateDailySet = functions.https.onCall(async (data, context) => {
  const uid = context.auth?.uid;
  if (!uid) throw new functions.https.HttpsError("unauthenticated", "Login gerekli");

  const dateId: string = data?.dateId ?? todayIdUTC();
  const polls: any[] = data?.polls;
  if (!Array.isArray(polls) || polls.length === 0) {
    throw new functions.https.HttpsError("invalid-argument", "polls[] gerekli");
  }

  const dailyRef = db.collection("daily_sets").doc(dateId);
  await db.runTransaction(async (tx) => {
    tx.set(dailyRef, {
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      totalPolls: polls.length,
      dateId,
    }, { merge: true });

    const col = dailyRef.collection("polls");
    polls.forEach((p, idx) => {
      const id = p.id ?? db.collection("_").doc().id;
      tx.set(col.doc(id), {
        question: p.question ?? "",
        option0Label: p.option0Label ?? "Seçenek A",
        option1Label: p.option1Label ?? "Seçenek B",
        option0Image: p.option0Image ?? "",
        option1Image: p.option1Image ?? "",
        option0Count: 0,
        option1Count: 0,
        order: p.order ?? idx,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: false });
    });
  });

  return { ok: true, dateId };
});

export const createDailySetHttp = functions.https.onRequest(async (req, res) => {
  const dateId = todayIdUTC();
  const dailyRef = db.collection("daily_sets").doc(dateId);
  const batch = db.batch();

  batch.set(dailyRef, {
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    totalPolls: 10,
    dateId,
  }, { merge: true });

  const polls = Array.from({ length: 10 }).map((_, i) => ({
    id: `p${i+1}`,
    question: `Günün ${i+1}. sorusu: Kanye vs Taylor? (örnek)`,
    option0Label: "Kanye",
    option1Label: "Taylor",
    option0Image: "",
    option1Image: "",
    order: i,
  }));

  polls.forEach((p) => {
    const ref = dailyRef.collection("polls").doc(p.id);
    batch.set(ref, {
      question: p.question,
      option0Label: p.option0Label,
      option1Label: p.option1Label,
      option0Image: p.option0Image,
      option1Image: p.option1Image,
      option0Count: 0,
      option1Count: 0,
      order: p.order,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  await batch.commit();
  res.json({ ok: true, dateId });
});

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

// --- BU FONKSİYON GÜNCELLENDİ ---
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