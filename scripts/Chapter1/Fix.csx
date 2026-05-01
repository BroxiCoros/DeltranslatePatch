// =====================================================================
// Chapter1/Fix.csx
// =====================================================================
// Aplica al data.win las modificaciones especificas del Capitulo 1.
// La logica comun (helpers, parsing del DSL, inyeccion de assets, etc.)
// vive en BaseFix.csx -> Common/*.csx.
//
// Trabajo especifico de este capitulo:
//   1. Construir el room_code con el preambulo de room_cc_5f (la tienda
//      de Rurus que usa un sprite localizado).
//   2. Reordenar el obj_gamecontroller en ROOM_INITIALIZE para que se
//      ejecute antes que obj_initializer2 (necesario para que el modo
//      traductor pueda enganchar antes de que el juego arranque).
// =====================================================================

#load "../BaseFix.csx"

using System.Collections.Generic;
using System.IO;

// ----- Construir el room_code (decoracion de salas) -----
//
// Cap. 1 usa scr_marker (NO scr_marker_animated), conserva la excepcion
// de room_town_school. Tiene un preambulo especifico declarado en
// extra_decorations.json (room_cc_5f).

string room_code = BuildRoomDecorationCode(
    jsonRooms,
    useAnimatedMarkers: false,
    skipTownSchoolException: false,
    prependCode: LoadAndBuildExtraDecorations());

AddNewEvent("obj_gamecontroller", EventType.Other, (uint)EventSubtypeOther.RoomStart, room_code);

// ----- Reordenar obj_gamecontroller delante de obj_initializer2 -----
//
// En ROOM_INITIALIZE el motor crea las instancias en orden de aparicion
// en el array. Necesitamos que obj_gamecontroller se inicialice ANTES de
// obj_initializer2 para que el sistema de localizacion este listo cuando
// obj_initializer2 corra. Lo conseguimos intercambiando posiciones.

var room = Data.Rooms.ByName("ROOM_INITIALIZE");

foreach (var layer in room.Layers)
{
    if (layer.LayerName.Content == "Compatibility_Instances_Depth_0")
    {
        for (var i = 0; i < layer.InstancesData.Instances.Count; i++)
        {
            var inst = layer.InstancesData.Instances[i];
            if (inst.ObjectDefinition.Name.Content == "obj_gamecontroller")
            {
                // Swap con la instancia 0 (incluyendo InstanceID para no romper refs)
                (layer.InstancesData.Instances[0].InstanceID, layer.InstancesData.Instances[i].InstanceID) =
                    (layer.InstancesData.Instances[i].InstanceID, layer.InstancesData.Instances[0].InstanceID);
                (layer.InstancesData.Instances[0], layer.InstancesData.Instances[i]) =
                    (layer.InstancesData.Instances[i], layer.InstancesData.Instances[0]);
            }
        }
    }
}

for (var i = 0; i < room.GameObjects.Count; i++)
{
    if (room.GameObjects[i].ObjectDefinition.Name.Content == "obj_gamecontroller")
    {
        // Swap con el slot 0 (lista de game objects globales de la room)
        (room.GameObjects[i], room.GameObjects[0]) = (room.GameObjects[0], room.GameObjects[i]);
    }
}

await SaveEntries();
