const admin = require("firebase-admin");
const fs = require("fs");

// Servis hesabı key dosyasını oku
const serviceAccount = require("./serviceAccountKey.json");

// Firebase Admin başlat
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function getSchema() {
  let schema = {};
  const collections = await db.listCollections();

  for (const col of collections) {
    const snapshot = await col.limit(5).get(); // her koleksiyondan max 5 doc alıyoruz
    schema[col.id] = {};

    snapshot.forEach(doc => {
      const data = doc.data();
      for (let key in data) {
        const value = data[key];
        let type;

        if (Array.isArray(value)) type = "array";
        else if (value === null) type = "null";
        else if (value instanceof admin.firestore.Timestamp) type = "timestamp";
        else if (value instanceof admin.firestore.GeoPoint) type = "geopoint";
        else if (value instanceof admin.firestore.DocumentReference) type = "reference";
        else type = typeof value;

        schema[col.id][key] = type;
      }
    });
  }

  fs.writeFileSync("firestore-schema.json", JSON.stringify(schema, null, 2));
  console.log("✅ Şema çıkarıldı → firestore-schema.json");
}

getSchema();
