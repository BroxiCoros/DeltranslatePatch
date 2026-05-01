// =====================================================================
// Menu/Fix.csx
// =====================================================================
// El menu de chapters no necesita logica adicional: solo aplica los
// cambios comunes de BaseFix (CodeEntries/*.gml + JSONs declarativos del
// menu) y compila.
// =====================================================================

#load "../BaseFix.csx"

await SaveEntries();
