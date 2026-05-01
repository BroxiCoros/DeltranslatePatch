// =====================================================================
// RoomDecorator.csx
// =====================================================================
// Funcion compartida por los 4 capitulos para construir el "room code":
// un bloque GML que se inyecta en obj_gamecontroller en el evento
// RoomStart, y que para cada room aplica overrides graficos a tiles,
// sprites de capa y backgrounds del idioma activo.
//
// Antes del refactor este bloque vivia copy-pasteado en cada Fix.csx por
// capitulo, con minor variations (scr_marker vs scr_marker_animated,
// excepcion de room_town_school). Ahora vive aqui y cada Fix.csx
// configura los flags y el preambulo especifico del capitulo.
//
// Diferencias entre capitulos absorbidas por parametros:
//
//   useAnimatedMarkers:
//       false = scr_marker(...)             (Cap. 1)
//       true  = scr_marker_animated(...)    (Cap. 2, 3, 4)
//
//   skipTownSchoolException:
//       false = aplicar la excepcion especial a room_town_school     (Cap. 1, 2, 4)
//               (que usa "depth" sin restar 1 y destruye un tilemap)
//       true  = NO aplicar esa excepcion (Cap. 3 simplemente usa "depth - 1"
//               igual que cualquier otra room)
//
// El input es jsonRooms (cargado por AssetInjector.csx) que tiene la
// estructura:
//
//   {
//     "room_X": [
//       { "type": "tile",       "x": "...", "y": "...", "sprite": "spr_X",
//         "depth": "...", "layer": "..." },
//       { "type": "sprite",     "layer": "...", "spr_name": "...", "sprite": "spr_X" },
//       { "type": "background", "layer": "...", "sprite": "spr_X" },
//       ...
//     ],
//     ...
//   }
//
// El flag prependCode se usa para anadir codigo especifico del capitulo
// ANTES del bloque generado (room_cc_5f de Cap. 1, queen_poster de
// Cap. 2, tv_word_poster de Cap. 3, etc.).
//
// Depende de Helpers.csx (no usa nada directamente, pero los Fix.csx que
// la llaman si).
// =====================================================================

using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Text.Json;

string BuildRoomDecorationCode(
    Dictionary<string, List<Dictionary<string, string>>> jsonRoomsInput,
    bool useAnimatedMarkers,
    bool skipTownSchoolException = false,
    string prependCode = "")
{
    string room_code = prependCode;

    string markerCall = useAnimatedMarkers
        ? "scr_marker_animated({0}, {1}, scr_84_get_sprite(\"{2}\"), sprite_get_speed(scr_84_get_sprite(\"{2}\")))"
        : "scr_marker({0}, {1}, scr_84_get_sprite(\"{2}\"))";

    foreach (var room in jsonRoomsInput)
    {
        room_code += string.Format("if (room == {0}) {{\n", room.Key);

        foreach (var spr in jsonRoomsInput[room.Key])
        {
            switch (spr["type"])
            {
                case "tile":
                {
                    bool useTownSchoolException =
                        !skipTownSchoolException && room.Key == "room_town_school";

                    var marker = string.Format(markerCall, spr["x"], spr["y"], spr["sprite"]);

                    if (useTownSchoolException)
                    {
                        // En room_town_school no restamos 1 al depth, y
                        // destruimos el tilemap original.
                        room_code += $@"    
                var n = {marker}
                n.depth = {spr["depth"]}
                var arr = layer_get_all_elements(""{spr["layer"]}"")
                layer_tilemap_destroy(arr[array_length(arr) - 4])
                ";
                    }
                    else
                    {
                        // Caso general: depth - 1
                        room_code += $@"    
                var n = {marker}
                n.depth = {spr["depth"]} - 1
                ";
                    }
                    break;
                }

                case "sprite":
                {
                    // Reemplaza un sprite asignado a una capa con su version
                    // localizada via scr_84_get_sprite.
                    room_code += $@"
            var lay_id = layer_get_id(""{spr["layer"]}"");
            var back_id = layer_sprite_get_id(lay_id, ""{spr["spr_name"]}"");
            layer_sprite_change(back_id, scr_84_get_sprite(""{spr["sprite"]}""));
            ";
                    break;
                }

                case "background":
                {
                    // Reemplaza el sprite de un background-layer.
                    room_code += $@"
            var lay_id = layer_get_id(""{spr["layer"]}"");
            var back_id = layer_background_get_id(lay_id);
            layer_background_sprite(back_id, scr_84_get_sprite(""{spr["sprite"]}""));
            ";
                    break;
                }
            }

            IncrementProgress();
            UpdateProgressValue(GetProgress());
        }

        room_code += "}\n";
    }

    return room_code;
}

// =====================================================================
// BuildExtraDecorationsCode + LoadAndBuildExtraDecorations
// =====================================================================
// Generan el "preambulo" de decoraciones especificas del capitulo a partir
// de extra_decorations.json (si existe). Antes este preambulo vivia
// hardcodeado como literal C# en cada Fix.csx (room_cc_5f del Cap. 1,
// queen_poster del Cap. 2, tv_word_poster + board_shop del Cap. 3).
//
// Schema esperado:
//
// {
//   "extra_decorations": [
//     {
//       "_comment": "...",                                 // opcional
//       "guard": {                                         // opcional
//         "type": "sprite_loaded" | "sprite_localized",
//         "sprite": "spr_X"
//       },
//       "blocks": [
//         {
//           "room": "room_X",
//           "markers": [                                   // opcional
//             {
//               "type": "marker" | "marker_animated",      // default "marker"
//               "x": N, "y": N,
//               "sprite": "spr_X",
//               "depth": N,
//               "image_index": N                           // opcional
//             }
//           ],
//           "raw": "GML literal..."                        // opcional, escape hatch
//         }
//       ]
//     }
//   ]
// }
//
// Significado de los guards:
//   sprite_loaded   -> if (scr_84_get_sprite("X") != -1) { ... }
//   sprite_localized -> if (scr_84_get_sprite("X") != X) { ... }
//                       (es decir, "el sprite que devuelve el sistema de
//                       localizacion no es el asset original; el pack si
//                       provee version traducida")
//
// El guard se puede declarar a nivel de section (envuelve TODOS los blocks)
// o a nivel de block individual (envuelve solo los items de ese block,
// dentro del if (room == ...)). Util para preservar el comportamiento
// exacto cuando el guard original estaba dentro del check de room.
//
// Si extra_decorations.json no existe, devuelve string vacio.
// =====================================================================

string LoadAndBuildExtraDecorations()
{
    var path = scriptFolder + "extra_decorations.json";
    if (!System.IO.File.Exists(path))
        return "";
    var json = System.IO.File.ReadAllText(path);
    using var doc = System.Text.Json.JsonDocument.Parse(json);
    return BuildExtraDecorationsCode(doc.RootElement);
}

string BuildExtraDecorationsCode(System.Text.Json.JsonElement root)
{
    if (root.ValueKind != System.Text.Json.JsonValueKind.Object)
        return "";
    if (!root.TryGetProperty("extra_decorations", out var sectionsArr))
        return "";

    var sb = new System.Text.StringBuilder();
    sb.Append("\n");
    foreach (var section in sectionsArr.EnumerateArray())
    {
        sb.Append(BuildExtraDecorationSection(section));
    }
    return sb.ToString();
}

(string Open, string Close) BuildGuard(System.Text.Json.JsonElement guard, string innerIndent)
{
    var guardType = guard.GetProperty("type").GetString();
    var guardSprite = guard.GetProperty("sprite").GetString();
    switch (guardType)
    {
        case "sprite_loaded":
            return ($"{innerIndent}if (scr_84_get_sprite(\"{guardSprite}\") != -1) {{\n",
                    $"{innerIndent}}}\n");
        case "sprite_localized":
            return ($"{innerIndent}if (scr_84_get_sprite(\"{guardSprite}\") != {guardSprite}) {{\n",
                    $"{innerIndent}}}\n");
        default:
            throw new System.Exception("extra_decorations.json: tipo de guard desconocido '" + guardType + "'.");
    }
}

string BuildExtraDecorationSection(System.Text.Json.JsonElement section)
{
    var sb = new System.Text.StringBuilder();

    // ---- Guard a nivel de section ----
    string guardOpen = "";
    string guardClose = "";
    if (section.TryGetProperty("guard", out var guard) &&
        guard.ValueKind == System.Text.Json.JsonValueKind.Object)
    {
        (guardOpen, guardClose) = BuildGuard(guard, "");
    }

    sb.Append(guardOpen);

    // ---- Blocks ----
    if (!section.TryGetProperty("blocks", out var blocks))
        return "";

    foreach (var block in blocks.EnumerateArray())
    {
        var room = block.GetProperty("room").GetString();
        sb.Append("    if (room == ").Append(room).Append(") {\n");

        // Guard a nivel de block: se aplica DENTRO del if (room == ...)
        // pero antes de los items. Util para preservar comportamiento del
        // mod base cuando el sprite-check estaba anidado dentro del room-check.
        string blockGuardOpen = "";
        string blockGuardClose = "";
        if (block.TryGetProperty("guard", out var blockGuard) &&
            blockGuard.ValueKind == System.Text.Json.JsonValueKind.Object)
        {
            (blockGuardOpen, blockGuardClose) = BuildGuard(blockGuard, "        ");
        }
        sb.Append(blockGuardOpen);

        // markers
        if (block.TryGetProperty("markers", out var markers))
        {
            foreach (var m in markers.EnumerateArray())
            {
                sb.Append(EmitMarker(m));
            }
        }

        // raw GML (escape hatch para casos exoticos)
        if (block.TryGetProperty("raw", out var raw))
        {
            var rawText = raw.GetString();
            // Indentar 8 espacios (4 del if + 4 del bloque)
            foreach (var line in rawText.Split('\n'))
            {
                sb.Append("        ").Append(line).Append("\n");
            }
        }

        sb.Append(blockGuardClose);
        sb.Append("    }\n");
    }

    sb.Append(guardClose);
    return sb.ToString();
}

string EmitMarker(System.Text.Json.JsonElement m)
{
    var markerType = m.TryGetProperty("type", out var mt) ? mt.GetString() : "marker";
    var x = m.GetProperty("x").GetInt32();
    var y = m.GetProperty("y").GetInt32();
    var sprite = m.GetProperty("sprite").GetString();
    var depth = m.GetProperty("depth").GetInt32();

    string markerCall;
    if (markerType == "marker_animated")
    {
        markerCall = "scr_marker_animated(" + x + ", " + y +
                     ", scr_84_get_sprite(\"" + sprite + "\"), sprite_get_speed(scr_84_get_sprite(\"" + sprite + "\")))";
    }
    else
    {
        markerCall = "scr_marker(" + x + ", " + y +
                     ", scr_84_get_sprite(\"" + sprite + "\"))";
    }

    var sb = new System.Text.StringBuilder();
    sb.Append("        n = ").Append(markerCall).Append("\n");
    sb.Append("        n.depth = ").Append(depth).Append("\n");
    if (m.TryGetProperty("image_index", out var ii))
    {
        sb.Append("        n.image_index = ").Append(ii.GetInt32()).Append("\n");
    }
    return sb.ToString();
}
