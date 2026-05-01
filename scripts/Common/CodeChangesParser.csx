// =====================================================================
// CodeChangesParser.csx
// =====================================================================
// Aplica al data.win las modificaciones declaradas por el capitulo en
// tres fuentes:
//
//   A) CodeEntries/*.gml          - reemplazos completos de codigo GML.
//   B) CodesWithSpritesIds.json   - sustituye ids numericos de sprites por
//                                   sus nombres simbolicos (preparacion
//                                   para que AssetInjector.csx luego los
//                                   envuelva con scr_84_get_sprite).
//   C) CodeChanges.txt            - patches estilo diff con DSL propio
//                                   (===/---/+++/%%%, ver abajo).
//
// Tambien crea funciones GlobalScript vacias para los archivos
// gml_GlobalScript_*.gml que aun no existen como UndertaleScript en el
// data.win, de forma que ReplaceGML las pueda rellenar.
//
// Depende de Helpers.csx.
//
// =====================================================================
// FORMATO DE CodeChanges.txt
// =====================================================================
//
// Linea-por-linea, con marcadores de prefijo:
//
//   === gml_Object_obj_X_Step_0       <- nombre del codigo a parchear
//   --- # (opcional: # = ignorar si no encuentra el patron)
//   bloque                            <- texto a buscar (multilinea OK)
//   ANTES
//   +++
//   bloque                            <- texto de reemplazo
//   DESPUES
//   %%%                               <- fin del cambio actual
//   ---
//   otro_patron                       <- otro cambio sobre el MISMO codigo
//   +++
//   otro_reemplazo
//   %%%
//   === gml_Object_obj_Y_Create_0     <- siguiente codigo
//   --- # ...
//
// Reglas:
//
//  - Los espacios consecutivos en el patron --- se colapsan a "\s*" en el
//    regex final, asi que no hay que preocuparse por indentacion exacta.
//  - Las llaves { y } se hacen opcionales en el patron ({?, }?).
//  - Si el flag de ignorar (---#) NO esta presente y el patron no se
//    encuentra, se imprime un aviso (ScriptMessage) pero el script
//    continua.
//  - Si esta el flag --- # y el patron no se encuentra, se omite en
//    silencio (util para parches que solo aplican en algunas versiones
//    del juego).
//  - Cada bloque empieza con --- (busqueda) y termina con %%%, con +++
//    como separador de busqueda y reemplazo.
//
// =====================================================================

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;

// ---- A) Cargar CodeEntries/*.gml ----
var codeEntrs = new List<(string, string)>();

foreach (string fileName in Directory.GetFiles(scriptFolder + "CodeEntries"))
{
    if (!fileName.EndsWith(".gml"))
        continue;
    var codeName = Path.GetFileNameWithoutExtension(fileName);
    codeEntrs.Add((codeName, File.ReadAllText(fileName)));

    // Si el archivo es un gml_GlobalScript_<X>.gml y la funcion <X> aun
    // no existe en data.win, la creamos vacia para que ReplaceGML pueda
    // rellenarla en el siguiente paso.
    if (codeName.Contains("GlobalScript") && Data.Code.ByName(codeName) == null)
    {
        // "gml_GlobalScript_" tiene 17 caracteres; el resto es el nombre.
        CreateBlankFunction(codeName.Substring(17));
    }
}

// ---- B) Cargar CodesWithSpritesIds.json ----
var codesWithSpritesIds = new Dictionary<string, List<string>>();
if (File.Exists(scriptFolder + "CodesWithSpritesIds.json"))
{
    using StreamReader r = new StreamReader(scriptFolder + "CodesWithSpritesIds.json");
    string json = r.ReadToEnd();
    codesWithSpritesIds = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, List<string>>>(json);
}

// ---- C) Cargar y parsear CodeChanges.txt ----
//
// El parser es state-machine por flag:
//   flag = 0 -> esperando ===, ---, %%%
//   flag = 1 -> acumulando texto en cur_from (despues de ---)
//   flag = 2 -> acumulando texto en cur_to   (despues de +++)
//
// Estructura: codeChanges[codeName] = lista de (patron, reemplazo, ignorar_no_match)

var codeChanges = new Dictionary<string, List<(string, string, bool)>>();
if (File.Exists(scriptFolder + "CodeChanges.txt")) {
    var changes = File.ReadAllLines(scriptFolder + "CodeChanges.txt");
    var cur_code = "";
    var cur_from = "";
    var cur_to = "";
    int flag = 0;
    bool flag_ignore = false;
    foreach (var str in changes)
    {
        if (str.StartsWith("==="))
        {
            cur_code = str.Substring(4);
            if (!codeChanges.ContainsKey(cur_code))
                codeChanges[cur_code] = new List<(string, string, bool)>();
            flag = 0;
        }
        else if (str.StartsWith("---"))
        {
            flag = 1;
            // Flag opcional "#" inmediatamente despues de --- = ignorar
            // silenciosamente si el patron no se encuentra.
            if (str.Length > 3 && str[3] == '#')
            {
                flag_ignore = true;
            }
        }
        else if (str.StartsWith("+++"))
            flag = 2;
        else if (str.StartsWith("%%%"))
        {
            flag = 0;
            // Quitar el "\n" extra al final que metio el ultimo += str + "\n"
            codeChanges[cur_code].Add((cur_from.Remove(cur_from.Length - 1), cur_to.Remove(cur_to.Length - 1), flag_ignore));
            cur_from = "";
            cur_to = "";
            flag_ignore = false;
        }
        else if (flag == 1)
            cur_from += str + "\n";
        else if (flag == 2)
            cur_to += str + "\n";
    }
}

// ---- Aplicacion ----

maxCount = codesWithSpritesIds.Count + codeEntrs.Count + codeChanges.Count;
await Task.Run(() =>
{
    SetProgressBar(null, "Code entries replacing", 0, maxCount);

    // (A) Reemplazo completo de codigos por archivos .gml
    foreach (var code in codeEntrs)
    {
        if (!GetOrig(code.Item1))
            continue;
        ReplaceGML(Data.Code.ByName(code.Item1), code.Item2);
        IncrementProgress();
        UpdateProgressValue(GetProgress());
    }

    // (B) Sustitucion de ids numericos de sprites por sus nombres
    foreach (var code in codesWithSpritesIds)
    {
        if (!GetOrig(code.Key))
            continue;

        foreach (var spr in code.Value)
        {
            // Si el sprite tiene id 1234 y se llama "spr_foo", reemplaza
            // "1234" por "spr_foo" en el codigo. Asi AssetInjector despues
            // puede envolverlo con scr_84_get_sprite("spr_foo").
            if (!ReplacePart(code.Key, Data.Sprites.IndexOf(Data.Sprites.ByName(spr)).ToString(), spr))
            {
                // Silencioso si el id no aparece (puede ser version distinta).
            }
        }

        IncrementProgress();
        UpdateProgressValue(GetProgress());
    }

    // (C) Patches del DSL CodeChanges.txt
    foreach (var codeName in codeChanges.Keys)
    {
        if (!GetOrig(codeName))
            continue;

        foreach (var change in codeChanges[codeName])
        {
            // Convertir el patron literal en regex permisivo:
            //   - colapsa espacios consecutivos a "\s*"
            //   - escapa caracteres especiales (Regex.Escape)
            //   - hace opcionales las llaves { y } para tolerar variaciones
            var from = Regex.Replace(change.Item1, @"\s+", " ");
            from = Regex.Escape(from);
            from = from.Replace(" ", @"\s*").Replace("\\\\", "\\");
            from = from.Replace("{", "{?").Replace("}", "}?");
            if (!ReplacePart(codeName, from, change.Item2) && !change.Item3)
            {
                // Si el patron no se encontro y el flag de ignorar NO esta
                // activado, avisamos para que el desarrollador lo investigue.
                ScriptMessage(codeName + "\n" + change.Item1);
            }
        }

        IncrementProgress();
        UpdateProgressValue(GetProgress());
    }
});
