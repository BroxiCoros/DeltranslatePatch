// =====================================================================
// BaseFix.csx - punto de entrada compartido para los Fix-*.csx
// =====================================================================
// Cada Fix-*.csx por capitulo hace `#load "../BaseFix.csx"` al principio,
// lo que importa textualmente este archivo. Este se encarga de cargar a
// su vez los modulos comunes en el orden correcto:
//
//   1. Helpers          - utilidades de bajo nivel (ReplaceGML, GetOrig,
//                         Decompile, AddNewEvent, SaveEntries, etc).
//   2. MenuSetup        - obj_lang_settings + hooks en obj_gamecontroller.
//   3. CodeChangesParser- aplica CodeEntries/*.gml + CodeChanges.txt +
//                         CodesWithSpritesIds.json.
//   4. AssetInjector    - sprites/sonidos/rooms (CodesWithSprites,
//                         CodesWithSounds, ObjectsWithAssignedSprites,
//                         RoomsWithBacksLayers, new_sprites).
//   5. FontInjector     - fuentes (CodesWithFonts) + normalizacion _ja_.
//   6. RoomDecorator    - funcion BuildRoomDecorationCode (NO se ejecuta
//                         aqui; queda definida para que cada Fix.csx la
//                         llame con sus parametros).
//
// Tras este BaseFix, cada Fix-*.csx por capitulo hace su trabajo
// especifico (room_code con prepend del capitulo, hacks puntuales) y
// finalmente llama a `await SaveEntries()` para commit.
//
// El orden importa porque CS-Script `#load` es include textual: las
// variables y funciones de cada modulo solo son visibles en los modulos
// cargados despues.
// =====================================================================

#load "Common/Helpers.csx"
#load "Common/MenuSetup.csx"
#load "Common/CodeChangesParser.csx"
#load "Common/AssetInjector.csx"
#load "Common/FontInjector.csx"
#load "Common/RoomDecorator.csx"
