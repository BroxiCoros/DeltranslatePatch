// =====================================================================
// FontInjector.csx
// =====================================================================
// Inyecta llamadas a scr_84_get_font en codigo del juego, para que las
// fuentes se resuelvan a traves de font_map (cargado por el sistema de
// localizacion) en lugar de quedar hardcodeadas.
//
// Tambien renombra las fuentes japonesas: las que tienen "_ja_" en su
// nombre se renombran al esquema "<nombre>_ja" (mover el sufijo de
// idioma al final). Es un detalle del juego original.
//
// Fuente leida:
//
//   - CodesWithFonts.json
//        { "fnt_main": ["gml_Object_obj_X_Step_0", ...], ... }
//        Para cada (fuente, lista de codigos), reemplaza el simbolo
//        "fnt_main" por scr_84_get_font("main") en cada codigo. (Nota: el
//        prefijo "fnt_" se quita porque scr_84_get_font lo agrega
//        internamente: "fnt_" + argument0).
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

var jsonFonts = new Dictionary<string, List<string>>();

if (File.Exists(scriptFolder + "CodesWithFonts.json"))
{
    using StreamReader r = new StreamReader(scriptFolder + "CodesWithFonts.json");
    string json = r.ReadToEnd();
    jsonFonts = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, List<string>>>(json);
}

maxCount = Math.Max(1, jsonFonts.Sum(e => e.Value.Count));
await Task.Run(() =>
{
    SetProgressBar(null, "Fonts injecting", 0, maxCount);

    // ---- Reemplazo de simbolos de fuente ----
    foreach (var font in jsonFonts)
    {
        foreach (var scr in font.Value)
        {
            GetOrig(scr);
            // font.Key es algo como "fnt_main"; le quitamos el prefijo "fnt_"
            // (4 chars) para pasarlo a scr_84_get_font, que internamente
            // hace "fnt_" + argument0.
            ReplacePart(scr, font.Key, "scr_84_get_font(\"" + font.Key.Substring(4) + "\")", true);
            IncrementProgress();
            UpdateProgressValue(GetProgress());
        }
    }

    // ---- Normalizacion de fuentes _ja_ ----
    // El juego original tiene fuentes con nombres como "fnt_ja_main" o
    // similares; las reescribimos a "fnt_main_ja" para encajar con el
    // esquema "<base>_<lang>" usado por el sistema de localizacion.
    foreach (var font in Data.Fonts)
    {
        if (font.Name.ToString().Contains("_ja_"))
        {
            font.Name.Content = font.Name.ToString().Trim(new char[] { '"' }).Replace("_ja_", "_") + "_ja";
        }
    }
});
