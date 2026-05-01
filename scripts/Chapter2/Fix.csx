// =====================================================================
// Chapter2/Fix.csx
// =====================================================================
// Modificaciones especificas del Capitulo 2.
//
// Trabajo:
//   1. Hack de obj_ch2_keyboardpuzzle_monologue_controller: usar el
//      string "DECEMBER" del json de strings localizados como semilla
//      de las teclas del teclado-puzzle.
//   2. Construir el room_code con preambulo de spr_queen_poster
//      (carteles de Queen que aparecen en varias salas de Cybercity).
//   3. Para cada keyboard puzzle (3 rooms) y cada tile listado en
//      InstancesToLetters.json, parchear el PreCreateCode de la instancia
//      para que extraiga su letra del string localizado.
// =====================================================================

#load "../BaseFix.csx"

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;

// ----- 1. Hack: keyboard puzzle monologue controller -----
//
// Nota historica: el codigo original llamaba AppendToEnd aqui, pero por
// un bug en BaseFix.csx (sobrecarga AppendToEnd(string,string) llamaba
// internamente a AppendToStart) el comportamiento real era prepend. El
// bug fue corregido en la Etapa 1 del refactor. Para preservar el
// comportamiento exacto del mod base, llamamos explicitamente
// AppendToStart aqui.
GetOrig("gml_Object_obj_ch2_keyboardpuzzle_monologue_controller_Create_0");
AppendToStart("gml_Object_obj_ch2_keyboardpuzzle_monologue_controller_Create_0", @"
    keys_symbols = stringsetloc(""DECEMBER"", ""obj_ch2_keyboard_cutscene_controller_slash_Create_0_gml_15_0"")
");

// ----- 2. Construir el room_code (decoracion de salas) -----
//
// Cap. 2 usa scr_marker_animated, conserva la excepcion de room_town_school.
// Tiene un preambulo declarado en extra_decorations.json (carteles de Queen
// en treasure / spamton_alley).

string room_code = BuildRoomDecorationCode(
    jsonRooms,
    useAnimatedMarkers: true,
    skipTownSchoolException: false,
    prependCode: LoadAndBuildExtraDecorations());

AddNewEvent("obj_gamecontroller", EventType.Other, (uint)EventSubtypeOther.RoomStart, room_code);

// ----- 3. Letras de teclado en los puzzles -----
//
// InstancesToLetters.json mapea cada instancia (por InstanceID) a la
// letra original del puzzle y su posicion en la palabra. Inyectamos en
// el PreCreateCode de cada instancia el calculo de myString basado en
// el string localizado, asi cada tecla muestra el caracter correcto en
// el idioma activo.
//
// Hay 3 keyboard puzzle rooms en el Cap. 2:
//   - room_dw_cyber_keyboard_puzzle_1 / _2: leen el string del json
//     localizado con un context_id distinto cada uno.
//   - room_dw_city_monologue: lee de una variable global del monologue
//     controller (que a su vez se inicializa con stringsetloc).
//
// La funcion PatchKeyboardPuzzleRoom acepta un builder del cuerpo de
// myString para reutilizar el mismo loop con expresiones distintas.

Dictionary<string, Dictionary<string, string>> insts_with_letters;

using (StreamReader r = new StreamReader(scriptFolder + "InstancesToLetters.json")) {
    string json = r.ReadToEnd();
    insts_with_letters = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, Dictionary<string, string>>>(json);
}

void PatchKeyboardPuzzleRoom(
    string roomName,
    Func<Dictionary<string, string>, string> buildMyStringExpr)
{
    foreach (var inst in Data.Rooms.ByName(roomName)
                            .Layers
                            .FirstOrDefault(x => x.LayerName.Content == "OBJECTS_MAIN")
                            .InstancesData.Instances)
    {
        var instId = inst.InstanceID.ToString();
        if (!insts_with_letters.ContainsKey(instId))
            continue;

        inst.PreCreateCode = AddCreationCodeEntryForInstance(inst);
        GetOrig(inst.PreCreateCode.Name.Content);
        var info = insts_with_letters[instId];
        AppendToEnd(inst.PreCreateCode,
            $"myString = {buildMyStringExpr(info)}");
    }
}

// Rooms 1 y 2: extraen el caracter de un string localizado (json strings).
// El context_id en el segundo argumento de scr_get_lang_string varia segun
// la room (..._gml_1_0 vs ..._gml_2_0).
PatchKeyboardPuzzleRoom("room_dw_cyber_keyboard_puzzle_1", info =>
    $@"string_char_at(scr_get_lang_string(""{info["orig_letter"]}"", ""obj_ch2_keyboardpuzzle_tile_Create_0_gml_1_0""), {info["num"]} + 1)");
PatchKeyboardPuzzleRoom("room_dw_cyber_keyboard_puzzle_2", info =>
    $@"string_char_at(scr_get_lang_string(""{info["orig_letter"]}"", ""obj_ch2_keyboardpuzzle_tile_Create_0_gml_2_0""), {info["num"]} + 1)");

// Room monologue: extrae el caracter de la variable keys_symbols que el
// monologue controller (parcheado arriba) inicializa con stringsetloc.
PatchKeyboardPuzzleRoom("room_dw_city_monologue", info =>
    $@"string_char_at(obj_ch2_keyboardpuzzle_monologue_controller.keys_symbols, {info["num"]} + 1)");

await SaveEntries();
