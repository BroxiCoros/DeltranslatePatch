// =====================================================================
// Chapter3/Fix.csx
// =====================================================================
// Modificaciones especificas del Capitulo 3.
//
// Trabajo:
//   1. Construir room_code con preambulo de spr_dw_tv_word_poster (carteles
//      de TV) y spr_board_shop (game shows). Cap. 3 NO usa la excepcion
//      de room_town_school.
//   2. Reemplazo masivo de c_tenna_sprite(N) en muchos Step_0 de objetos
//      del rhythm/chef/teevie usando sprites.json para mapear ids
//      numericos a nombres simbolicos.
// =====================================================================

#load "../BaseFix.csx"

using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;

// ----- 1. Construir el room_code -----

string room_code = BuildRoomDecorationCode(
    jsonRooms,
    useAnimatedMarkers: true,
    skipTownSchoolException: true,        // <- diferencia con Cap. 1, 2, 4
    prependCode: LoadAndBuildExtraDecorations());

AddNewEvent("obj_gamecontroller", EventType.Other, (uint)EventSubtypeOther.RoomStart, room_code);

// ----- 2. Reemplazo de c_tenna_sprite(numero) por scr_84_get_sprite -----
//
// En los Step_0 de los objetos listados, el codigo original llama a
// c_tenna_sprite con un id numerico de sprite hardcodeado. sprites.json
// nos dice que id corresponde a que sprite simbolicamente. Reescribimos
// las llamadas para resolver el sprite via scr_84_get_sprite, asi se
// localiza correctamente.

var scriptsWithTennaSpriteCall = new List<string>()
{
    "gml_Object_obj_ch3_BTB02_Step_0",
    "gml_Object_obj_ch3_BTB03_Step_0",
    "gml_Object_obj_ch3_BTB04_Step_0",
    "gml_Object_obj_ch3_BTB06_Step_0",
    "gml_Object_obj_ch3_closet_Step_0",
    "gml_Object_obj_ch3_GSA01G_Step_0",
    "gml_Object_obj_ch3_GSA02_Step_0",
    "gml_Object_obj_ch3_GSA04_Step_0",
    "gml_Object_obj_ch3_GSA06_Step_0",
    "gml_Object_obj_ch3_GSB01_Step_0",
    "gml_Object_obj_ch3_GSB02_Step_0",
    "gml_Object_obj_ch3_GSB03_Step_0",
    "gml_Object_obj_ch3_GSB05_Step_0",
    "gml_Object_obj_ch3_GSC05_Step_0",
    "gml_Object_obj_ch3_GSC07_Step_0",
    "gml_Object_obj_ch3_GSD01_Step_0",
    "gml_Object_obj_ch3_PTB01_Step_0",
    "gml_Object_obj_ch3_PTB02_Step_0",
    "gml_Object_obj_room_chef_empty_Step_0",
    "gml_Object_obj_room_rhythm_empty_Step_0",
    "gml_Object_obj_room_stage_Step_0",
    "gml_Object_obj_room_teevie_bonus_zone_Step_0",
    "gml_Object_obj_room_teevie_large_02_Step_0",
    "gml_Object_obj_room_teevie_stealth_c_Step_0",
    "gml_Object_obj_victory_chef_Step_0",
    "gml_Object_obj_victory_rhythm_Step_0"
};

var sprites_ids = new Dictionary<string, string>();

if (File.Exists(scriptFolder + "sprites.json"))
{
    using StreamReader r = new StreamReader(scriptFolder + "sprites.json");
    string json = r.ReadToEnd();
    var sprites = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, List<string>>>(json)["sprites"];
    foreach (var spr in sprites)
    {
        sprites_ids[Data.Sprites.IndexOf(Data.Sprites.ByName(spr)).ToString()] = spr;
    }
}

maxCount = scriptsWithTennaSpriteCall.Count;
await Task.Run(() =>
{
    SetProgressBar(null, "Codes with Tenna sprite replacing", 0, maxCount);

    foreach (var codeName in scriptsWithTennaSpriteCall)
    {
        GetOrig(codeName);

        var text = Decompile(codeName);
        Regex rx = new Regex(@"c_tenna_sprite\((\d*?)\)");
        text = rx.Replace(text, new MatchEvaluator((match) => {
            var id = match.Groups[1].Value;
            if (sprites_ids.ContainsKey(id)) {
                return "c_tenna_sprite(scr_84_get_sprite(\"" + sprites_ids[id] + "\"));";
            } else
                return match.Groups[0].Value;
        }));
        ReplaceGML(codeName, text);

        IncrementProgress();
        UpdateProgressValue(GetProgress());
    }
});

await SaveEntries();
