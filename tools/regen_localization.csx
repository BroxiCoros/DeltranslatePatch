// =====================================================================
// regen_localization.csx
// =====================================================================
// Regenera, para los 4 capitulos, los .gml de localizacion derivados:
//
//   - gml_GlobalScript_scr_init_localization.gml
//   - gml_GlobalScript_scr_lang_reload_partial.gml
//   - gml_GlobalScript_scr_load_lang_sprites_only.gml
//
// Lee el manifest.json de cada capitulo y emite los .gml en su carpeta
// CodeEntries/. NO TOCA el data.win: solo escribe ficheros de texto en
// disco, asi que se puede correr abriendo cualquier data.win en UTMT.
//
// Ejecutarlo despues de editar cualquiera de los manifest.json. El output
// es deterministico: dos corridas seguidas producen el mismo bytes-a-bytes.
//
// USO desde UndertaleModTool:
//   1. Abrir cualquier data.win (por ejemplo el del menu).
//   2. Scripts -> Run other script -> seleccionar este archivo.
//   3. Repetir Fix-*.csx normales para aplicar al data.win.
// =====================================================================

#load "../scripts/Common/LocalizationGenerator.csx"

using System.IO;

string scriptsRoot;
{
    // ScriptPath apunta a este archivo (tools/regen_localization.csx).
    // Subimos un nivel y entramos a "scripts/".
    string toolsFolder = Path.GetDirectoryName(ScriptPath);
    string repoRoot = Path.GetDirectoryName(toolsFolder);
    scriptsRoot = Path.Combine(repoRoot, "scripts");
}

if (!Directory.Exists(scriptsRoot))
{
    ScriptError("No se encontro la carpeta 'scripts/' en " + scriptsRoot);
    return;
}

int regenerated = 0;
foreach (int ch in new[] { 1, 2, 3, 4 })
{
    string chapterFolder = Path.Combine(scriptsRoot, "Chapter" + ch);
    string manifestPath = Path.Combine(chapterFolder, "manifest.json");
    if (!File.Exists(manifestPath))
    {
        ScriptMessage("Aviso: no hay manifest.json en " + chapterFolder + ", se omite.");
        continue;
    }

    try
    {
        var gen = new LocalizationGenerator(chapterFolder);
        gen.GenerateAll();
        regenerated++;
    }
    catch (System.Exception ex)
    {
        ScriptError("Error regenerando Chapter" + ch + ": " + ex.Message);
        return;
    }
}

ScriptMessage("Localizacion regenerada en " + regenerated + " capitulos.\n" +
              "Ahora puedes ejecutar Fix-*.csx para aplicar los cambios al data.win.");
