// import_recetas.js

const admin = require('./firebase'); // archivo donde inicializas firebase-admin
const fs = require('fs');

// Lee el archivo JSON de recetas
const recetas = JSON.parse(fs.readFileSync('./recetas_maestro.json', 'utf8'));

// Accede a Firestore
const db = admin.firestore();

async function importData() {
  const recetasCollection = db.collection('recetas_maestro');  

  const batch = db.batch();

  recetas.forEach((receta) => {
    // Si tu JSON tiene un campo "id", lo usamos como ID de documento
    const docRef = recetasCollection.doc(receta.id ? receta.id.toString() : undefined);

    batch.set(docRef, receta);
  });

  try {
    await batch.commit();
    console.log('✅ Datos de recetas importados correctamente');
  } catch (error) {
    console.error('❌ Error al importar las recetas:', error);
  }
}

importData();
