const admin = require('./firebase'); // tu firebase.js
const db = admin.firestore();

async function traerSinCarbohidratos() {
  try {
    const snapshot = await db.collection('alimentos_maestro')
                             .where('carbohidratos.cantidad', '==', 0)
                             .get();

    if (snapshot.empty) {
      console.log('No se encontraron alimentos con carbohidratos 0.');
      return;
    }

    snapshot.forEach(doc => {
      console.log(doc.id, doc.data());
    });

  } catch (error) {
    console.error('❌ Error al consultar alimentos:', error);
  }
}

traerSinCarbohidratos();
