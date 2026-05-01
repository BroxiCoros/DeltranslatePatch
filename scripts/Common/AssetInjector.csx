// =====================================================================
// AssetInjector.csx
// =====================================================================
// Inyecta llamadas a scr_84_get_sprite / scr_84_get_sound en el codigo
// del juego, para que los sprites y sonidos cargados por el sistema de
// localizacion (chemg_sprite_map / chemg_sound_map) se resuelvan en
// runtime en lugar de quedar hardcodeados al asset original.
//
// Tambien crea sprites nuevos (vacios) para placeholders del idioma:
// dimensiones, origen y numero de frames se leen de new_sprites.json.
//
// Fuentes leidas:
//
//   - ObjectsWithAssignedSprites.json
//        { "obj_X": "spr_X", ... }
//        Para cada objeto, en su Create_0 anade:
//          if (sprite_index == spr_X) sprite_index = scr_84_get_sprite("spr_X");
//        Si el Create_0 no existe, lo crea con event_inherited().
//
//   - CodesWithSprites.json
//        { "gml_Object_obj_X_Step_0": ["spr_a", "spr_b"], ... }
//        Para cada code, envuelve cada referencia simbolica al sprite con
//        scr_84_get_sprite("spr_a") usando regex con \b...\b.
//
//   - CodesWithSounds.json
//        { "gml_Object_obj_X_Step_0": ["snd_a", ...], ... }
//        Equivalente, con scr_84_get_sound.
//
//   - RoomsWithBacksLayers.json
//        Reservado: lo carga porque varios Fix-*.csx por capitulo lo
//        consultan despues como `jsonRooms` para construir codigo
//        especifico de room (ver RoomDecorator.csx).
//
//   - new_sprites.json
//        Crea sprites nuevos vacios con Width/Height/MarginXxx, OriginX/Y,
//        y ajusta el numero de TextureEntry segun "frames_num". Si el
//        sprite ya existe, solo le edita los campos presentes.
//
// Depende de Helpers.csx.
// =====================================================================

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using UndertaleModLib.Models;

var objectsWithAssignedSprites = new Dictionary<string, string>();
var codesWithSprites = new Dictionary<string, List<string>>();
var jsonRooms = new Dictionary<string, List<Dictionary<string, string>>>();
var codesWithSounds = new Dictionary<string, List<string>>();

if (File.Exists(scriptFolder + "ObjectsWithAssignedSprites.json"))
{
    using StreamReader r = new StreamReader(scriptFolder + "ObjectsWithAssignedSprites.json");
    string json = r.ReadToEnd();
    objectsWithAssignedSprites = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, string>>(json);
}
if (File.Exists(scriptFolder + "CodesWithSprites.json"))
{
    using StreamReader r = new StreamReader(scriptFolder + "CodesWithSprites.json");
    string json = r.ReadToEnd();
    codesWithSprites = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, List<string>>>(json);
}
if (File.Exists(scriptFolder + "RoomsWithBacksLayers.json"))
{
    using StreamReader r = new StreamReader(scriptFolder + "RoomsWithBacksLayers.json");
    string json = r.ReadToEnd();
    jsonRooms = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, List<Dictionary<string, string>>>>(json);
}
if (File.Exists(scriptFolder + "CodesWithSounds.json"))
{
    using StreamReader r = new StreamReader(scriptFolder + "CodesWithSounds.json");
    string json = r.ReadToEnd();
    codesWithSounds = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, List<string>>>(json);
}

maxCount = codesWithSprites.Count + objectsWithAssignedSprites.Count + jsonRooms.Count + codesWithSounds.Count;
await Task.Run(() =>
{
    SetProgressBar(null, "Sprites and sounds injecting", 0, maxCount);

    // ---- CodesWithSprites: spr_X -> scr_84_get_sprite("spr_X") ----
    foreach (var code in codesWithSprites)
    {
        foreach (var spr in code.Value)
        {
            if (!ReplacePart(code.Key, spr, string.Format("scr_84_get_sprite(\"{0}\")", spr), true))
            {
                // Reportamos al desarrollador en ingles por compatibilidad.
                ScriptMessage(string.Format("Error injecting sprite \"{0}\" into \"{1}\".", spr, code.Key));
            }
        }
        GetOrig(code.Key);

        IncrementProgress();
        UpdateProgressValue(GetProgress());
    }

    // ---- ObjectsWithAssignedSprites: hook en Create_0 ----
    foreach (var obj in objectsWithAssignedSprites)
    {
        if (Data.Code.ByName("gml_Object_" + obj.Key + "_Create_0") == null)
        {
            // No habia Create_0; lo creamos con event_inherited() + el reemplazo.
            AddNewEvent(obj.Key, EventType.Create, 0,
                string.Format("event_inherited();\nif (sprite_index == {0}) sprite_index = scr_84_get_sprite(\"{0}\");", obj.Value));
        }
        else
        {
            // Ya existia; preservar original y prependear el reemplazo.
            GetOrig("gml_Object_" + obj.Key + "_Create_0");
            AppendToStart("gml_Object_" + obj.Key + "_Create_0",
                string.Format("if (sprite_index == {0}) sprite_index = scr_84_get_sprite(\"{0}\");", obj.Value));
        }

        IncrementProgress();
        UpdateProgressValue(GetProgress());
    }

    // ---- CodesWithSounds: snd_X -> scr_84_get_sound("snd_X") ----
    foreach (var code in codesWithSounds)
    {
        var lst = new List<(string, string)>();
        foreach (var snd in code.Value)
        {
            lst.Add((snd, string.Format("scr_84_get_sound(\"{0}\")", snd)));
        }
        GetOrig(code.Key);
        ReplacePart(code.Key, lst, true);

        IncrementProgress();
        UpdateProgressValue(GetProgress());
    }
});

// ---- new_sprites.json: crear/ajustar sprites placeholders ----
//
// Formato esperado:
//   {
//     "spr_nombre": {
//       "width": 100, "height": 50,
//       "origin_x": 0, "origin_y": 0,
//       "frames_num": 3
//     },
//     ...
//   }
// Todos los campos son opcionales (excepto el nombre).

var jsonNewSprites = new Dictionary<string, Dictionary<string, int>>();
if (File.Exists(scriptFolder + "new_sprites.json"))
{
    using StreamReader r = new StreamReader(scriptFolder + "new_sprites.json");
    string json = r.ReadToEnd();
    jsonNewSprites = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, Dictionary<string, int>>>(json);
}

foreach (var spr in jsonNewSprites)
{
    var newSprite = Data.Sprites.ByName(spr.Key);
    if (newSprite is null) {
        newSprite = new();
        newSprite.Name = Data.Strings.MakeString(spr.Key);
        Data.Sprites.Add(newSprite);
    }

    if (spr.Value.ContainsKey("width"))
    {
        newSprite.Width = (uint)spr.Value["width"];
        newSprite.MarginRight = spr.Value["width"] - 1;
        newSprite.MarginLeft = 0;

        newSprite.Height = (uint)spr.Value["height"];
        newSprite.MarginBottom = spr.Value["height"] - 1;
        newSprite.MarginTop = 0;

        newSprite.CollisionMasks.Clear();
        newSprite.CollisionMasks.Add(newSprite.NewMaskEntry());
    }

    if (spr.Value.ContainsKey("origin_x"))
    {
        newSprite.OriginX = spr.Value["origin_x"];
    }

    if (spr.Value.ContainsKey("origin_y"))
    {
        newSprite.OriginY = spr.Value["origin_y"];
    }

    if (spr.Value.ContainsKey("frames_num"))
    {
        var r_frames = spr.Value["frames_num"];
        if (r_frames < newSprite.Textures.Count) {
            // Recortar frames sobrantes
            while (newSprite.Textures.Count > r_frames) {
                newSprite.Textures.RemoveAt(newSprite.Textures.Count - 1);
            }
        } else {
            // Anadir frames vacios para llegar al numero pedido
            var c = newSprite.Textures.Count;
            for (int i = c; i < spr.Value["frames_num"]; i++)
                newSprite.Textures.Add(new UndertaleSprite.TextureEntry());
        }
    }
}
