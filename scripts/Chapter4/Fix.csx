// =====================================================================
// Chapter4/Fix.csx
// =====================================================================
// Modificaciones especificas del Capitulo 4.
//
// Cap. 4 no tiene preambulo de room_code propio: simplemente aplica el
// patron general (scr_marker_animated, con excepcion de room_town_school)
// sobre RoomsWithBacksLayers.json y guarda. Es el mas simple de los 4.
// =====================================================================

#load "../BaseFix.csx"

using System.Collections.Generic;
using System.IO;

string room_code = BuildRoomDecorationCode(
    jsonRooms,
    useAnimatedMarkers: true,
    skipTownSchoolException: false,
    prependCode: LoadAndBuildExtraDecorations());

AddNewEvent("obj_gamecontroller", EventType.Other, (uint)EventSubtypeOther.RoomStart, room_code);

await SaveEntries();
