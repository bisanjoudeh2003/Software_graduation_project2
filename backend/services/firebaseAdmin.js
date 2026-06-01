const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

function initializeFirebaseAdmin() {
  if (admin.apps.length > 0) {
    return admin;
  }

  try {
    let serviceAccount = null;

    if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
      console.log(
        "Firebase service account loaded from FIREBASE_SERVICE_ACCOUNT_JSON"
      );
    }

    if (!serviceAccount && process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      const credentialPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;

      if (fs.existsSync(credentialPath)) {
        serviceAccount = require(credentialPath);
        console.log(
          "Firebase service account loaded from GOOGLE_APPLICATION_CREDENTIALS"
        );
      } else {
        console.warn(
          "GOOGLE_APPLICATION_CREDENTIALS path not found:",
          credentialPath
        );
      }
    }

    if (!serviceAccount) {
      const configPath = path.join(
        __dirname,
        "..",
        "config",
        "firebase-service-account.json"
      );

      if (fs.existsSync(configPath)) {
        serviceAccount = require(configPath);
        console.log(
          "Firebase service account loaded from config/firebase-service-account.json"
        );
      }
    }

    if (!serviceAccount) {
      console.warn(
        "Firebase Admin was not initialized. Service account file was not found."
      );
      return null;
    }

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });

    console.log("Firebase Admin initialized successfully");
    return admin;
  } catch (error) {
    console.error("Firebase Admin initialization error:", error.message);
    return null;
  }
}

module.exports = initializeFirebaseAdmin();