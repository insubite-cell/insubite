const admin = require('firebase-admin');

// Inicializa Firebase con las credenciales del archivo JSON
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

module.exports = admin;
