import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

function todayIdUTC(): string {
  const now = new Date();
  const yyyy = now.getUTCFullYear();
  const mm = String(now.getUTCMonth() + 1).padStart(2,"0");
  const dd = String(now.getUTCDate()).padStart(2,"0");
  return `${yyyy}-${mm}-${dd}`;
}

/**
 * submitVote (callable)
 * - Tek oy kuralını server tarafında uygular
 * - votes/{uid}_{pollId} oluşur
 * - ilgili poll sayacını (option0Count/option1Count) atomik artırır
 */
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

  // poll referansı: daily_sets/{today}/polls/{pollId}
  // Not: dilersen client'tan dateId de gönderebilirsin; burada UTC “bugün” varsayıyoruz
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

    // vote doc
    tx.set(voteRef, {
      userId: uid,
      pollId,
      option: optionIndex,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: false });

    // counters
    const inc = admin.firestore.FieldValue.increment(1);
    const updates: Record<string, admin.firestore.FieldValue> = {};
    if (optionIndex === 0) updates["option0Count"] = inc;
    else updates["option1Count"] = inc;

    tx.set(pollRef, updates, { merge: true });
  });

  return { ok: true };
});

/**
 * adminCreateDailySet (callable)
 * - DEV: Günün 10 sorusunu elle basmak için
 * - PROD: Cloud Scheduler/HTTP ile tetikleyip otomatik de yaratabilirsin
 */
export const adminCreateDailySet = functions.https.onCall(async (data, context) => {
  // Basit admin kontrolü: isAdmin custom claim veya whitelist email kontrolü ekle
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

/**
 * (Opsiyonel) HTTP endpoint — Cloud Scheduler ile her sabah 08:00'de oluştur
 * Basit bir sablon basar (dummy).
 */
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
