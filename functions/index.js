const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

exports.checkDates = onSchedule("every 5 minutes", async () => {
  const now = new Date();

  const snapshot = await admin.firestore()
    .collection("Eventos")
    .where("fecha", "<=", now)
    .where("ejecutado", "==", false)
    .get();

  if (snapshot.empty) {
    console.log("Nada para ejecutar");
    return;
  }

  const batch = admin.firestore().batch();

  snapshot.docs.forEach(doc => {
    batch.update(doc.ref, {
      ejecutado: true,
      ejecutadoEn: admin.firestore.FieldValue.serverTimestamp()
    });
  });

  await batch.commit();

  console.log("Eventos ejecutados:", snapshot.size);
});