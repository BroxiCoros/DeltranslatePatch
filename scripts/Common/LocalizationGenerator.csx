// =====================================================================
// LocalizationGenerator.csx
// =====================================================================
// Genera, para un capitulo dado, las tres funciones GML de localizacion:
//
//   - gml_GlobalScript_scr_init_localization.gml
//   - gml_GlobalScript_scr_lang_reload_partial.gml
//   - gml_GlobalScript_scr_load_lang_sprites_only.gml
//
// Las tres comparten ~80% de la logica y antes vivian duplicadas en cada
// capitulo (con riesgo cronico de desincronizacion). Este modulo las
// produce desde un unico manifiesto JSON por capitulo
// (scripts/ChapterN/manifest.json), de modo que las listas de sprites,
// sonidos, songs, fuentes y aliases solo existan en un sitio.
//
// USO:
//
//   #load "../Common/LocalizationGenerator.csx"
//   var gen = new LocalizationGenerator(scriptFolder);
//   gen.GenerateAll();
//
// Donde `scriptFolder` apunta a la carpeta del capitulo (la que contiene
// `manifest.json` y `CodeEntries/`).
//
// El regenerador (tools/regen_localization.csx) procesa los 4 capitulos
// llamando a este modulo en bucle.
// =====================================================================

#nullable disable

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.Json;

class LocalizationGenerator
{
    private readonly string _chapterFolder;
    private readonly string _codeEntriesFolder;
    private readonly Manifest _manifest;

    public LocalizationGenerator(string chapterFolder)
    {
        _chapterFolder = chapterFolder.TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
        _codeEntriesFolder = _chapterFolder + "CodeEntries" + Path.DirectorySeparatorChar;

        var manifestPath = _chapterFolder + "manifest.json";
        if (!File.Exists(manifestPath))
            throw new FileNotFoundException("No se encontro manifest.json en " + _chapterFolder);

        _manifest = Manifest.Load(manifestPath);
    }

    public int Chapter => _manifest.Chapter;

    public void GenerateAll()
    {
        Directory.CreateDirectory(_codeEntriesFolder);
        WriteFile("gml_GlobalScript_scr_init_localization.gml",        BuildInit());
        WriteFile("gml_GlobalScript_scr_lang_reload_partial.gml",      BuildReloadPartial());
        WriteFile("gml_GlobalScript_scr_load_lang_sprites_only.gml",   BuildSpritesOnly());
    }

    private void WriteFile(string fileName, string content)
    {
        File.WriteAllText(_codeEntriesFolder + fileName, content);
    }

    // -----------------------------------------------------------------
    // Helpers de emision
    // -----------------------------------------------------------------

    /// <summary>
    /// Emite un array literal GML de strings: ["a", "b", "c"].
    /// Usa una linea por elemento si hay mas de 6 elementos para legibilidad.
    /// </summary>
    private static string GmlStringArray(IList<string> items, string indent = "    ")
    {
        if (items.Count == 0) return "[]";
        if (items.Count <= 6)
            return "[" + string.Join(", ", items.Select(s => "\"" + s + "\"")) + "]";

        var sb = new StringBuilder();
        sb.Append("[\n");
        for (int i = 0; i < items.Count; i++)
        {
            sb.Append(indent).Append("    \"").Append(items[i]).Append("\"");
            if (i < items.Count - 1) sb.Append(",");
            sb.Append("\n");
        }
        sb.Append(indent).Append("]");
        return sb.ToString();
    }

    private static string GmlFontsArray(IList<Manifest.FontEntry> fonts, string indent = "    ")
    {
        if (fonts.Count == 0) return "[]";
        var sb = new StringBuilder();
        sb.Append("[\n");
        for (int i = 0; i < fonts.Count; i++)
        {
            sb.Append(indent).Append("    [\"").Append(fonts[i].Name).Append("\", ").Append(fonts[i].DefaultSize).Append("]");
            if (i < fonts.Count - 1) sb.Append(",");
            sb.Append("\n");
        }
        sb.Append(indent).Append("]");
        return sb.ToString();
    }

    // -----------------------------------------------------------------
    // Bloques reusables (texto GML)
    // -----------------------------------------------------------------

    private string ChapterPath() => "chapter" + Chapter;

    /// <summary>
    /// Tabla declarativa de aliases de fuente (alias -> fuente objetivo).
    /// La resolucion se hace en tiempo de ejecucion en scr_84_get_font /
    /// scr_get_font: si una fuente alias no tiene handle valido (porque el
    /// pack no la incluye, o porque su carga lazy fallo), se sirve la
    /// fuente objetivo. Esto sustituye al bloque "if undefined" que se
    /// emitia inline tras la carga, que era incompatible con la carga
    /// diferida de fuentes (la condicion habria disparado falsamente
    /// para toda fuente pendiente).
    /// </summary>
    private string EmitFontAliasTargets(string indent)
    {
        if (_manifest.FontAliases == null || _manifest.FontAliases.Count == 0)
            return "";

        var sb = new StringBuilder();
        sb.Append(indent).Append("// Tabla de aliases de fuente. La resolucion ocurre en\n");
        sb.Append(indent).Append("// scr_84_get_font / scr_get_font: si la fuente alias no tiene handle\n");
        sb.Append(indent).Append("// valido (archivo ausente, lazy load fallido), se sirve la objetivo.\n");
        sb.Append(indent).Append("// Si el pack provee la fuente alias como archivo, se carga normal.\n");
        sb.Append(indent).Append("if (variable_global_exists(\"font_alias_targets\"))\n");
        sb.Append(indent).Append("    ds_map_destroy(global.font_alias_targets);\n");
        sb.Append(indent).Append("global.font_alias_targets = ds_map_create();\n");
        foreach (var kv in _manifest.FontAliases)
        {
            sb.Append(indent).Append("ds_map_add(global.font_alias_targets, \"")
              .Append(kv.Key).Append("\", \"").Append(kv.Value).Append("\");\n");
        }
        return sb.ToString();
    }

    /// <summary>
    /// Carga lazy de fuentes. Solo fnt_main se rasteriza en el momento
    /// (es la unica fuente visible en los menus pre-gameplay: DEVICE_MENU
    /// y obj_lang_settings). El resto se difiere a global.font_pending_map
    /// y se carga la primera vez que alguien la pida via scr_84_get_font /
    /// scr_get_font (tipicamente justo tras el loading screen, durante la
    /// transicion a partida). Combinado con el cache (global.font_cache)
    /// que vive en add_font, los cambios sucesivos de idioma cuestan ~0ms.
    ///
    /// fonts_list debe estar definida antes de este bloque. La fuente
    /// fnt_main siempre se carga eagerly (es asumida en este patron); si
    /// no esta en la lista, no pasa nada (el bucle simplemente no llamara
    /// add_font para ella).
    /// </summary>
    private static string FontsLoadDeferredSnippet(string indent) =>
        indent + "// Carga lazy: fnt_main es la unica fuente visible en los menus\n" +
        indent + "// previos a partida (DEVICE_MENU, obj_lang_settings). El resto se\n" +
        indent + "// difiere a global.font_pending_map y se rasteriza la primera vez\n" +
        indent + "// que alguien la pida (tipicamente despues del loading screen, ya\n" +
        indent + "// dentro de gameplay). Combinado con global.font_cache en add_font,\n" +
        indent + "// los cambios sucesivos al mismo idioma cuestan ~0ms.\n" +
        indent + "if (variable_global_exists(\"font_pending_map\"))\n" +
        indent + "    ds_map_destroy(global.font_pending_map);\n" +
        indent + "global.font_pending_map = ds_map_create();\n" +
        indent + "for (var i = 0; i < array_length(fonts_list); i++)\n" +
        indent + "{\n" +
        indent + "    var _fname = fonts_list[i][0];\n" +
        indent + "    var _fsize = fonts_list[i][1];\n" +
        indent + "    if (_fname == \"fnt_main\")\n" +
        indent + "        add_font(_fname, _fsize);\n" +
        indent + "    else\n" +
        indent + "        ds_map_add(global.font_pending_map, _fname, _fsize);\n" +
        indent + "}\n";

    private bool HasLoader(string name) =>
        _manifest.ExtraLoaders != null && _manifest.ExtraLoaders.Contains(name);

    /// <summary>
    /// Snippet "boob" del Cap. 1 para INIT: spr_blockler_<letra> por cada letra.
    /// Mantiene el patron inline original (dos llamadas a get_chapter_lang_setting,
    /// sin variable intermedia), para preservar el orden exacto del mod base.
    /// </summary>
    private static string BoobSpritesSnippetInit(string indent) =>
        indent + "// Variantes de spr_blockler para el final del Cap. 1 (\"boob\" setting).\n" +
        indent + "for (var i = 0; i < string_length(get_chapter_lang_setting(\"boob\", \"boob\")); i++)\n" +
        indent + "    add_sprite(\"spr_blockler_\" + string_char_at(get_chapter_lang_setting(\"boob\", \"boob\"), i + 1), 4);\n";

    /// <summary>
    /// Snippet "boob" para SPRITES_ONLY. El mod base usa variable intermedia aqui
    /// (a diferencia de INIT). Se replica para no introducir cambios funcionales.
    /// </summary>
    private static string BoobSpritesSnippetSpritesOnly(string indent) =>
        indent + "// Chapter1: variantes especiales de spr_blockler en funcion de\n" +
        indent + "// get_chapter_lang_setting(\"boob\"). Replica el bloque correspondiente\n" +
        indent + "// de scr_init_localization (Chapter1 lo tiene).\n" +
        indent + "var boob = get_chapter_lang_setting(\"boob\", \"boob\");\n" +
        indent + "for (var i = 0; i < string_length(boob); i++)\n" +
        indent + "    add_sprite(\"spr_blockler_\" + string_char_at(boob, i + 1), 4);\n";

    /// <summary>Setup de sound_symbols (lectura del chapter_settings + write-back).</summary>
    private static string ButtonSoundsSetupSnippet(string indent) =>
        indent + "// Sonidos de botones: simbolos configurados en el pack (default = alfanumericos + !?).\n" +
        indent + "sound_symbols = get_chapter_lang_setting(\"button_sounds_symbols\", [\"A\", \"B\", \"C\", \"D\", \"E\", \"F\", \"G\", \"H\", \"I\", \"J\", \"K\", \"L\", \"M\", \"N\", \"O\", \"P\", \"Q\", \"R\", \"S\", \"T\", \"U\", \"V\", \"W\", \"X\", \"Y\", \"Z\", \"0\", \"1\", \"2\", \"3\", \"4\", \"5\", \"6\", \"7\", \"8\", \"9\", \"!\", \"?\"]);\n" +
        indent + "set_chapter_lang_setting(\"button_sounds_symbols\", sound_symbols);\n";

    /// <summary>Loop add_sound("snd_speak_and_spell_X", 1).</summary>
    private static string ButtonSoundsLoopSnippet(string indent) =>
        indent + "// Carga snd_speak_and_spell_X para cada simbolo configurado.\n" +
        indent + "for (var i = 0; i < array_length(sound_symbols); i++)\n" +
        indent + "    add_sound(\"snd_speak_and_spell_\" + sound_symbols[i], 1);\n";

    /// <summary>Fuente derivada de spr_tvlandfont (Cap. 3, rhythm game).</summary>
    private static string TvLandFontSnippet(string indent) =>
        indent + "// Fuente derivada del sprite spr_tvlandfont (running line del rhythm game).\n" +
        indent + "global.tvlandfont = font_add_sprite_ext(scr_84_get_sprite(\"spr_tvlandfont\"), get_chapter_lang_setting(\"tvlangfont_string\", \"ABCDEFGHIJKLMNOPQRSTUVWXYZ.?!:\\u2026abcdefghijklmnopqrstuvwxyz1234567890\"), 0, 1);\n";

    /// <summary>tvlandfont para sprites_only: borra la fuente vieja antes de recrear.
    /// sprites_only se llama desde scr_apply_pending_sprite_reload tras un cambio
    /// en caliente. Si tvlandfont ya existia, hay que borrar la fuente vieja
    /// para no fugar memoria.</summary>
    private static string TvLandFontRefreshSnippet(string indent) =>
        indent + "// Refrescar global.tvlandfont: el sprite spr_tvlandfont acaba de\n" +
        indent + "// recargarse al idioma nuevo. Si ya existia una fuente, borrarla\n" +
        indent + "// para no fugarla.\n" +
        indent + "if (variable_global_exists(\"tvlandfont\"))\n" +
        indent + "    font_delete(global.tvlandfont);\n" +
        indent + "global.tvlandfont = font_add_sprite_ext(scr_84_get_sprite(\"spr_tvlandfont\"), get_chapter_lang_setting(\"tvlangfont_string\", \"ABCDEFGHIJKLMNOPQRSTUVWXYZ.?!:\\u2026abcdefghijklmnopqrstuvwxyz1234567890\"), 0, 1);\n";

    /// <summary>Sprites adicionales declarados en chapter_settings.json (Cap. 3 y 4).</summary>
    private static string AdditionalFunnyWordsSnippet(string indent) =>
        indent + "// Sprites adicionales declarados por el pack para esta lengua.\n" +
        indent + "var additional_funny_words = get_chapter_lang_setting(\"additional_funny_words\", []);\n" +
        indent + "for (var i = 0; i < array_length(additional_funny_words); i++)\n" +
        indent + "    add_sprite(additional_funny_words[i]);\n";

    /// <summary>Sonidos adicionales declarados en chapter_settings.json (Cap. 3 y 4).</summary>
    private static string AdditionalFunnySoundsSnippet(string indent) =>
        indent + "// Sonidos adicionales declarados por el pack para esta lengua.\n" +
        indent + "var additional_funny_sounds = get_chapter_lang_setting(\"additional_funny_sounds\", []);\n" +
        indent + "for (var i = 0; i < array_length(additional_funny_sounds); i++)\n" +
        indent + "    add_sound(additional_funny_sounds[i]);\n";

    // -----------------------------------------------------------------
    // Generadores de los 3 archivos
    // -----------------------------------------------------------------

    private string BuildInit()
    {
        var sb = new StringBuilder();
        sb.Append("// AUTOGENERADO por tools/regen_localization.csx desde scripts/Chapter").Append(Chapter).Append("/manifest.json.\n");
        sb.Append("// NO editar a mano: cualquier cambio se sobrescribira en la proxima regeneracion.\n");
        sb.Append("\n");
        sb.Append("function scr_init_localization()\n");
        sb.Append("{\n");
        sb.Append("    if (!variable_global_exists(\"lang_loaded\"))\n");
        sb.Append("    {\n");
        sb.Append("        global.lang_loaded = \"\";\n");
        sb.Append("        global.loaded_sprites = [];\n");
        sb.Append("        global.loaded_sounds = [];\n");
        sb.Append("        global.loaded_fonts = [];\n");
        sb.Append("    }\n");
        sb.Append("\n");
        sb.Append("    if (global.lang_loaded != global.lang)\n");
        sb.Append("    {\n");
        sb.Append("        var sprites_list = ").Append(GmlStringArray(_manifest.Sprites, "        ")).Append(";\n");
        sb.Append("        var fonts_list   = ").Append(GmlFontsArray(_manifest.Fonts, "        ")).Append(";\n");
        sb.Append("        global.lang_loaded = global.lang;\n");
        sb.Append("\n");
        sb.Append("        if (variable_global_exists(\"lang_map\"))\n");
        sb.Append("        {\n");
        sb.Append("            for (var i = 0; i < array_length(global.loaded_sprites); i++)\n");
        sb.Append("                sprite_delete(global.loaded_sprites[i]);\n");
        sb.Append("            for (var i = 0; i < array_length(global.loaded_fonts); i++)\n");
        sb.Append("                font_delete(global.loaded_fonts[i]);\n");
        sb.Append("            for (var i = 0; i < array_length(global.loaded_sounds); i++)\n");
        sb.Append("                audio_destroy_stream(global.loaded_sounds[i]);\n");
        sb.Append("\n");
        sb.Append("            ds_map_destroy(global.lang_map);\n");
        sb.Append("            ds_map_destroy(global.font_map);\n");
        sb.Append("            ds_map_destroy(global.chemg_sprite_map);\n");
        sb.Append("            ds_map_destroy(global.chemg_sound_map);\n");
        sb.Append("            global.chapter_lang_settings = {};\n");
        sb.Append("            global.loaded_sprites = [];\n");
        sb.Append("            global.loaded_sounds = [];\n");
        sb.Append("            global.loaded_fonts = [];\n");
        sb.Append("        }\n");
        sb.Append("\n");
        sb.Append("        global.chapter_lang_settings = scr_load_json(get_lang_folder_path() + \"").Append(ChapterPath()).Append("/chapter_settings.json\");\n");
        sb.Append("        global.font_map = ds_map_create();\n");
        sb.Append("        global.lang_missing_map = ds_map_create();\n");
        sb.Append("        global.chemg_sprite_map = ds_map_create();\n");
        sb.Append("        global.chemg_sound_map = ds_map_create();\n");
        sb.Append("        font_add_enable_aa(false);\n");
        sb.Append("\n");

        // Fuentes (carga lazy: solo fnt_main eagerly)
        sb.Append("        // ----- Fuentes -----\n");
        sb.Append(FontsLoadDeferredSnippet("        "));
        var aliases = EmitFontAliasTargets("        ");
        if (aliases.Length > 0) { sb.Append("\n").Append(aliases); }
        sb.Append("\n");

        // Sprites
        sb.Append("        // ----- Sprites -----\n");
        sb.Append("        for (var i = 0; i < array_length(sprites_list); i++)\n");
        sb.Append("            add_sprite(sprites_list[i]);\n");
        if (HasLoader("boob"))
        {
            sb.Append("\n").Append(BoobSpritesSnippetInit("        "));
        }
        if (HasLoader("additional_funny_assets"))
        {
            sb.Append("\n").Append(AdditionalFunnyWordsSnippet("        "));
        }
        sb.Append("\n");

        // Sonidos: setup ANTES de declarar sounds_list (replica orden del mod base)
        sb.Append("        // ----- Sonidos -----\n");
        sb.Append("        var sndm = global.chemg_sound_map;\n");
        if (HasLoader("button_sounds"))
        {
            sb.Append(ButtonSoundsSetupSnippet("        "));
        }
        if (HasLoader("tvlandfont"))
        {
            sb.Append(TvLandFontSnippet("        "));
        }
        sb.Append("        var sounds_list = ").Append(GmlStringArray(_manifest.Sounds, "        ")).Append(";\n");
        sb.Append("        global.songs_list = ").Append(GmlStringArray(_manifest.Songs, "        ")).Append(";\n");
        sb.Append("\n");
        if (HasLoader("button_sounds"))
        {
            sb.Append(ButtonSoundsLoopSnippet("        "));
            sb.Append("\n");
        }
        sb.Append("        for (var i = 0; i < array_length(sounds_list); i++)\n");
        sb.Append("            add_sound(sounds_list[i]);\n");
        if (HasLoader("additional_funny_assets"))
        {
            sb.Append("\n").Append(AdditionalFunnySoundsSnippet("        "));
        }
        sb.Append("\n");

        // Strings
        sb.Append("        // ----- Strings -----\n");
        sb.Append("        global.lang_map = ds_map_create();\n");
        sb.Append("        scr_lang_load();\n");
        sb.Append("        scr_ascii_input_names();\n");
        sb.Append("    }\n");
        sb.Append("}\n");
        return sb.ToString();
    }

    private string BuildReloadPartial()
    {
        // Recarga parcial: fuentes, sonidos y strings (NO sprites).
        //
        // Notas intencionales para preservar comportamiento del mod base:
        //  1) emite el bloque additional_funny_sounds INCONDICIONALMENTE,
        //     aunque el feature 'additional_funny_assets' no este declarado
        //     en el manifest. El mod base lo hace asi en los 4 capitulos
        //     (en Cap. 1 y 2 init no carga additional_funny_*, pero
        //     reload_partial si). El for sobre [] es no-op si el pack no
        //     define el campo.
        //  2) NO emite el bloque button_sounds aqui: el mod base no recarga
        //     snd_speak_and_spell_X tras un cambio de idioma en caliente.
        //     Es un bug latente del mod base, pero se mantiene para no
        //     introducir cambios funcionales en este refactor.
        var sb = new StringBuilder();
        sb.Append("// AUTOGENERADO por tools/regen_localization.csx desde scripts/Chapter").Append(Chapter).Append("/manifest.json.\n");
        sb.Append("// NO editar a mano: cualquier cambio se sobrescribira en la proxima regeneracion.\n");
        sb.Append("//\n");
        sb.Append("// Recarga parcial del idioma activo: fuentes, sonidos y strings.\n");
        sb.Append("// Llamada desde scr_switch_game_language para cambiar de idioma SIN\n");
        sb.Append("// recargar sprites en el mismo frame (los sprites se difieren a\n");
        sb.Append("// scr_load_lang_sprites_only).\n");
        sb.Append("\n");
        sb.Append("function scr_lang_reload_partial()\n");
        sb.Append("{\n");
        sb.Append("    var fonts_list  = ").Append(GmlFontsArray(_manifest.Fonts, "    ")).Append(";\n");
        sb.Append("    var sounds_list = ").Append(GmlStringArray(_manifest.Sounds, "    ")).Append(";\n");
        sb.Append("    var songs_list  = ").Append(GmlStringArray(_manifest.Songs, "    ")).Append(";\n");
        sb.Append("\n");
        sb.Append("    // ----- Borrar fonts viejas -----\n");
        sb.Append("    if (variable_global_exists(\"loaded_fonts\"))\n");
        sb.Append("    {\n");
        sb.Append("        for (var i = 0; i < array_length(global.loaded_fonts); i++)\n");
        sb.Append("            font_delete(global.loaded_fonts[i]);\n");
        sb.Append("    }\n");
        sb.Append("    global.loaded_fonts = [];\n");
        sb.Append("    if (variable_global_exists(\"font_map\"))\n");
        sb.Append("        ds_map_destroy(global.font_map);\n");
        sb.Append("    global.font_map = ds_map_create();\n");
        sb.Append("\n");
        sb.Append("    // ----- Borrar sounds viejos -----\n");
        sb.Append("    if (variable_global_exists(\"loaded_sounds\"))\n");
        sb.Append("    {\n");
        sb.Append("        for (var i = 0; i < array_length(global.loaded_sounds); i++)\n");
        sb.Append("            audio_destroy_stream(global.loaded_sounds[i]);\n");
        sb.Append("    }\n");
        sb.Append("    global.loaded_sounds = [];\n");
        sb.Append("    if (variable_global_exists(\"chemg_sound_map\"))\n");
        sb.Append("        ds_map_destroy(global.chemg_sound_map);\n");
        sb.Append("    global.chemg_sound_map = ds_map_create();\n");
        sb.Append("\n");
        sb.Append("    // ----- Borrar strings viejos -----\n");
        sb.Append("    if (variable_global_exists(\"lang_map\"))\n");
        sb.Append("        ds_map_destroy(global.lang_map);\n");
        sb.Append("\n");
        sb.Append("    // chapter_lang_settings puede contener listas (additional_funny_*) que\n");
        sb.Append("    // difieren entre packs; lo recargamos antes de reabrir las fuentes.\n");
        sb.Append("    global.chapter_lang_settings = scr_load_json(get_lang_folder_path() + \"").Append(ChapterPath()).Append("/chapter_settings.json\");\n");
        sb.Append("\n");
        sb.Append("    font_add_enable_aa(false);\n");
        sb.Append("\n");
        sb.Append("    // ----- Recargar fonts (lazy: solo fnt_main eagerly) -----\n");
        sb.Append(FontsLoadDeferredSnippet("    "));

        var aliases = EmitFontAliasTargets("    ");
        if (aliases.Length > 0) { sb.Append("\n").Append(aliases); }

        sb.Append("\n");
        sb.Append("    // ----- Recargar sounds -----\n");
        sb.Append("    global.songs_list = songs_list;\n");
        sb.Append("    for (var i = 0; i < array_length(sounds_list); i++)\n");
        sb.Append("        add_sound(sounds_list[i]);\n");
        sb.Append("\n");

        // button_sounds en reload_partial: arregla el bug latente de que tras
        // cambio de idioma en caliente los snd_speak_and_spell_X se quedaban
        // apuntando a los sonidos del idioma viejo.
        if (HasLoader("button_sounds"))
        {
            sb.Append(ButtonSoundsSetupSnippet("    "));
            sb.Append("\n");
            sb.Append(ButtonSoundsLoopSnippet("    "));
            sb.Append("\n");
        }

        // SIEMPRE emite additional_funny_sounds, replica el patron del mod base
        sb.Append(AdditionalFunnySoundsSnippet("    "));
        sb.Append("\n");

        sb.Append("    // ----- Recargar strings -----\n");
        sb.Append("    global.lang_map = ds_map_create();\n");
        sb.Append("    scr_lang_load();\n");
        sb.Append("    scr_ascii_input_names();\n");
        sb.Append("\n");
        sb.Append("    // Strings/fonts/sonidos listos. Sprites siguen pendientes:\n");
        sb.Append("    // los maneja global.lang_sprites_pending por separado.\n");
        sb.Append("    global.lang_loaded = global.lang;\n");
        sb.Append("}\n");
        return sb.ToString();
    }

    private string BuildSpritesOnly()
    {
        var sb = new StringBuilder();
        sb.Append("// AUTOGENERADO por tools/regen_localization.csx desde scripts/Chapter").Append(Chapter).Append("/manifest.json.\n");
        sb.Append("// NO editar a mano: cualquier cambio se sobrescribira en la proxima regeneracion.\n");
        sb.Append("//\n");
        sb.Append("// Carga los sprites del idioma actual al chemg_sprite_map. NO borra los\n");
        sb.Append("// sprites viejos: el codigo que llama (scr_switch_game_language) ya los\n");
        sb.Append("// movio al array global.outdated_sprites para borrarlos despues, en\n");
        sb.Append("// scr_cleanup_outdated_sprites al cambiar de sala.\n");
        sb.Append("\n");
        sb.Append("function scr_load_lang_sprites_only()\n");
        sb.Append("{\n");
        sb.Append("    var sprites_list = ").Append(GmlStringArray(_manifest.Sprites, "    ")).Append(";\n");
        sb.Append("\n");
        sb.Append("    // Vaciamos el map; las entradas apuntan a los sprites viejos, que ya\n");
        sb.Append("    // estan en outdated_sprites. Tras add_sprite el map vuelve a estar\n");
        sb.Append("    // lleno con los sprites del idioma nuevo.\n");
        sb.Append("    if (variable_global_exists(\"chemg_sprite_map\"))\n");
        sb.Append("        ds_map_clear(global.chemg_sprite_map);\n");
        sb.Append("    else\n");
        sb.Append("        global.chemg_sprite_map = ds_map_create();\n");
        sb.Append("\n");
        sb.Append("    for (var i = 0; i < array_length(sprites_list); i++)\n");
        sb.Append("        add_sprite(sprites_list[i]);\n");

        if (HasLoader("boob"))
        {
            sb.Append("\n").Append(BoobSpritesSnippetSpritesOnly("    "));
        }
        if (HasLoader("additional_funny_assets"))
        {
            sb.Append("\n").Append(AdditionalFunnyWordsSnippet("    "));
        }
        // tvlandfont refresh: tras cargar el sprite, recrear la fuente
        // derivada de spr_tvlandfont. Si esta funcion se llama desde
        // scr_apply_pending_sprite_reload (cambio en caliente), la
        // fuente vieja se borra para no fugar memoria.
        if (HasLoader("tvlandfont"))
        {
            sb.Append("\n").Append(TvLandFontRefreshSnippet("    "));
        }

        sb.Append("}\n");
        return sb.ToString();
    }
}

// =====================================================================
// Manifest: parser del JSON. Tolerante a campos faltantes (todos opcionales
// salvo `chapter`).
// =====================================================================
class Manifest
{
    public int Chapter { get; set; }
    public List<FontEntry> Fonts { get; set; } = new();
    public Dictionary<string, string> FontAliases { get; set; } = new();
    public List<string> Sprites { get; set; } = new();
    public List<string> Sounds { get; set; } = new();
    public List<string> Songs { get; set; } = new();
    public List<string> ExtraLoaders { get; set; } = new();

    public class FontEntry
    {
        public string Name { get; set; }
        public int DefaultSize { get; set; }
    }

    public static Manifest Load(string path)
    {
        using var doc = JsonDocument.Parse(File.ReadAllText(path));
        var root = doc.RootElement;
        var m = new Manifest();

        if (!root.TryGetProperty("chapter", out var chProp))
            throw new Exception("manifest.json: falta campo 'chapter'");
        m.Chapter = chProp.GetInt32();

        if (root.TryGetProperty("fonts", out var fontsProp))
        {
            foreach (var f in fontsProp.EnumerateArray())
            {
                m.Fonts.Add(new FontEntry
                {
                    Name = f.GetProperty("name").GetString(),
                    DefaultSize = f.GetProperty("default_size").GetInt32()
                });
            }
        }
        if (root.TryGetProperty("font_aliases", out var aliasesProp))
        {
            foreach (var p in aliasesProp.EnumerateObject())
                m.FontAliases[p.Name] = p.Value.GetString();
        }
        m.Sprites      = ReadStringList(root, "sprites");
        m.Sounds       = ReadStringList(root, "sounds");
        m.Songs        = ReadStringList(root, "songs");
        m.ExtraLoaders = ReadStringList(root, "extra_loaders");
        return m;
    }

    private static List<string> ReadStringList(JsonElement root, string field)
    {
        var result = new List<string>();
        if (!root.TryGetProperty(field, out var arr)) return result;
        foreach (var s in arr.EnumerateArray())
            result.Add(s.GetString());
        return result;
    }
}
