// import_alimentos.js

const fs = require('fs');
const path = require('path');
const admin = require('./firebase'); // tu firebase.js
const db = admin.firestore();        // define db

// Ruta al JSON de alimentos
const filePath = path.join(__dirname, 'alimentos_maestro.json');

// Leer archivo
let alimentos = [];
try {
  const rawData = fs.readFileSync(filePath, 'utf8');
  alimentos = JSON.parse(rawData);
  if (!Array.isArray(alimentos)) throw new Error('El JSON debe ser un array');
} catch (err) {
  console.error('❌ No se pudo leer o parsear alimentos_maestro.json:', err);
  process.exit(1);
}

console.log(`📊 Alimentos a procesar: ${alimentos.length}`);

// Normaliza un campo a {cantidad, unidad}
function normalizarCampo(campo, unidadDefault = "g") {
  if (campo === null || campo === undefined) return { cantidad: 0, unidad: unidadDefault };
  if (typeof campo === "object" && "cantidad" in campo) {
    return { cantidad: isNaN(campo.cantidad) ? 0 : campo.cantidad, unidad: campo.unidad ?? unidadDefault };
  }
  return { cantidad: isNaN(campo) ? 0 : campo, unidad: unidadDefault };
}

// Importación principal con batch de 500
async function importData() {
  const alimentosCollection = db.collection('alimentos_maestro');
  const batchSize = 500;
  let batch = db.batch();
  let batchCount = 0;

  for (let index = 0; index < alimentos.length; index++) {
    const alimento = alimentos[index];
    const nombre = alimento.nombre;
    if (!nombre || nombre === "NaN") continue; // descartar si no tiene nombre válido

    const docId = alimento.id ? alimento.id.toString() : `alimento_${index}`;

    const docData = {
      id: docId,
      nombre,
      energia: normalizarCampo(alimento.energia, "kcal"),
      carbohidratos: normalizarCampo(alimento.carbohidratos, "g"),
      proteinas: normalizarCampo(alimento.proteínas, "g"),
      grasas_totales: normalizarCampo(alimento.grasas, "g"),
      acidos_grasos_saturados: normalizarCampo(alimento.acidos_grasos_saturados, "g"),
      acidos_grasos_trans: normalizarCampo(alimento.acidos_grasos_trans, "g"),
      fibra: normalizarCampo(alimento.fibra, "g"),
      sodio: normalizarCampo(alimento.sodio, "mg"),
      azucares: normalizarCampo(alimento.azucares, "g"),
      calcio: normalizarCampo(alimento.calcio, "mg"),
      porcion: normalizarCampo(alimento.porcion, "g")
      // 🚫 No incluimos "países"
    };

    batch.set(alimentosCollection.doc(docId), docData);
    batchCount++;

    // Si llegamos a 500 documentos, ejecutamos el batch y creamos uno nuevo
    if (batchCount >= batchSize) {
      await batch.commit();
      console.log(`✅ Subidos ${batchCount} alimentos...`);
      batch = db.batch();
      batchCount = 0;
    }
  }

  // Ejecutar batch restante
  if (batchCount > 0) {
    await batch.commit();
    console.log(`✅ Subidos últimos ${batchCount} alimentos`);
  }

  console.log('🎉 Todos los alimentos importados correctamente');
}

// Ejecutar importación
importData().catch(error => console.error('❌ Error inesperado:', error));
