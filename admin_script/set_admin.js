const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

// 1. Download your serviceAccountKey.json from Firebase Console
// (Project Settings -> Service Accounts -> Generate new private key)
// and place it in this folder.
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

// 2. Paste the UID of the user you created in the Firebase Console here:
const uid = 'jtAtdzOyUjTlaAxFD3IQJXH0pOT2'; 

getAuth().setCustomUserClaims(uid, { role: 'admin' })
  .then(() => {
    console.log('✅ Successfully set admin claim for user:', uid);
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Error setting custom claim:', error);
    process.exit(1);
  });
