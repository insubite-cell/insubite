// import_modelos.js

const admin = require('./firebase'); // Asegúrate de que la ruta esté correcta
const fs = require('fs');

// Lee el archivo JSON de modelos de sensores
const modelosSensores = JSON.parse(fs.readFileSync('./modelos_sensores.json', 'utf8'));

// Accede a Firestore
const db = admin.firestore();

async function importData() {
  // Define la colección y agrega los documentos
  const modelosCollection = db.collection('modelos_sensores');  // Aquí puedes poner el nombre de la colección que quieras

  const batch = db.batch(); // Usamos batch para hacer varias escrituras a la vez

  modelosSensores.forEach((modelo) => {
    const docRef = modelosCollection.doc(modelo.id.toString()); // Usamos el campo 'id' como el ID del documento
    batch.set(docRef, modelo); // Añadimos el modelo al batch
  });

  // Ejecuta el batch
  try {
    await batch.commit();
    console.log('Datos de modelos de sensores importados correctamente');
  } catch (error) {
    console.error('Error al importar los modelos de sensores:', error);
  }
}

importData();
