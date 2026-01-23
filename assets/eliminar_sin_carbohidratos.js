const admin = require('./firebase'); // tu firebase.js
const db = admin.firestore();

async function eliminarSinCarbohidratos() {
  try {
    const snapshot = await db.collection('alimentos_maestro')
                             .where('carbohidratos.cantidad', '==', 0)
                             .get();

    if (snapshot.empty) {
      console.log('No se encontraron alimentos con carbohidratos 0.');
      return;
    }

    const batch = db.batch();

    snapshot.forEach(doc => {
      console.log(`🗑 Eliminando: ${doc.id} - ${doc.data().nombre}`);
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log('✅ Todos los alimentos con carbohidratos 0 han sido eliminados.');
    
  } catch (error) {
    console.error('❌ Error al eliminar alimentos:', error);
  }
}

eliminarSinCarbohidratos();
