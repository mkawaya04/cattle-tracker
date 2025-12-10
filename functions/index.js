const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.createAnimalAlert = functions.firestore
  .document("animals/{animalId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (after.status !== before.status &&
        (after.status === "Sick" || after.status === "Needs Attention")) {

      const existingAlert = await admin.firestore()
        .collection("alerts")
        .where("animalId", "==", after.animalId)
        .where("message", "==", `${after.name} is ${after.status}`)
        .limit(1)
        .get();

      if (!existingAlert.empty) return null;

      await admin.firestore().collection("alerts").add({
        ownerId: after.ownerId,
        animalId: after.animalId,
        message: `${after.name} is ${after.status}`,
        severity: after.status === "Sick" ? "critical" : "warning",
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });
    }
  });
