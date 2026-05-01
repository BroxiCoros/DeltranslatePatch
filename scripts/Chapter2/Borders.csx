// =====================================================================
// Chapter2/Borders.csx
// =====================================================================
// Version del script NXRUNE_CH2.csx (de NXRUNE, por IRUZZ) adaptada
// para correr DESPUES de que se haya aplicado el mod de traduccion
// deltranslate sobre el data.win de DELTARUNE Capitulo 2.
//
// USO:
//
//   Automatico (instalador / DeltaPatcherCLI):
//     Cuando se pasa la bandera --borders al patcher, el instalador
//     invoca este script DESPUES de Fix.csx sobre el mismo data.win.
//     No hay nada manual que hacer: los recursos PNG viven en la
//     carpeta hermana scripts/Chapter2/Borders/ y se descubren via
//     Path.GetDirectoryName(ScriptPath).
//
//   Manual (UndertaleModTool):
//     1. Cargar chapter2_windows/data.win en UndertaleModTool.
//     2. Ejecutar primero scripts/Chapter2/Fix.csx (Scripts -> Run
//        other script).
//     3. Ejecutar este archivo (scripts/Chapter2/Borders.csx) sobre
//        el MISMO data.win, sin guardar entre ambos pasos.
//     4. Guardar el data.win.
//
// QUE CAMBIA RESPECTO AL NXRUNE_CH2.csx ORIGINAL:
//
//   A) gml_Object_obj_darkcontroller_Draw_0  (deltranslate lo REEMPLAZA
//      entero desde Chapter2/CodeEntries):
//        - Patron original: `if (global.is_console)`,
//          `border_options[selected_border]` y `xx + 430` para
//          fullscreenoff/runoff.
//        - Tras pasar deltranslate:
//            * `if (global.is_console || os_type == os_android)` (deltranslate
//              activa los bordes tambien en Android).
//            * `border_options_tr[selected_border]` (array paralelo en el
//              que cada nombre pasa por stringsetloc para que
//              "Dynamic"/"Simple"/"None" se traduzcan).
//            * `_selectXPos` en lugar de `xx + 430`.
//        - Ajustamos el patron de busqueda Y el reemplazo para preservar
//          esos cambios (en particular `border_options_tr` para no perder
//          las traducciones de los nombres del borde).
//
//   B) gml_Object_DEVICE_MENU_Step_0  (deltranslate lo REEMPLAZA entero):
//        - El parche original de NXRUNE expandia
//            if (!global.is_console) { ini_close(); }
//          para que tambien leyera el ID del borde del .ini en PC.
//        - deltranslate YA APLICA esa misma logica en su reemplazo del
//          archivo. Eliminamos ese QueueFindReplace para evitar el
//          "no-op find and replace".
//
//   C) gml_Object_obj_initializer2_Create_0  (NO es full-replace, pero
//      deltranslate trae un parche en CodeChanges.txt que intenta
//      convertir
//          global.screen_border_id = stringsetloc("Dynamic", "obj_initializer2_slash_Create_0_gml_22_0")
//      de vuelta a
//          global.screen_border_id = "Dynamic"
//      Eso significa que deltranslate prefiere que `screen_border_id` sea
//      una cadena LITERAL ("Dynamic") y no una cadena pasada por
//      stringsetloc. Razon: en obj_darkcontroller_Create_0 (que
//      deltranslate SI reemplaza), `selected_border` se calcula
//      comparando `screen_border_id` contra el array
//      `border_options = ["Dynamic", "Simple", "None"]` (en ingles). Si
//      `screen_border_id` quedara localizado (p. ej. "Dinamico"), el
//      match fallaria y selected_border caeria a 0 silenciosamente.
//      Cambiamos el reemplazo de NXRUNE para que use el literal
//      "Dynamic" (mismo comportamiento que tendria el stringsetloc en
//      ingles, pero robusto frente a otros idiomas).
//
// El resto de los parches no cambian: deltranslate no toca obj_time,
// obj_border_controller, scr_draw_background_ps4, obj_darkcontroller_Step_0,
// DEVICE_MENU_Alarm_0, DEVICE_MENU_Create_0, scr_text,
// obj_ch2_lw_cutscenes_short_Create_0, obj_onion_event_Create_0, ni los
// bloques del obj_initializer2_Step_0 que NXRUNE necesita.
//
// Strings traducibles nuevos: NINGUNO. Todas las claves de loc que usa
// NXRUNE (gml_86_0..96_0 y gml_112_0 de Draw_0, y Create_0_gml_153_0..2)
// ya estan en deltranslate. La clave gml_22_0 que usaba el NXRUNE
// original ahora ya no se invoca (usamos el literal "Dynamic").
//
// Si en el futuro deltranslate cambia algo mas, este script fallara con
// "no-op find and replace" sobre el codigo correspondiente y habra que
// volver a sincronizar los patrones.
// =====================================================================

using System;
using System.Collections.Generic;
using System.IO;
using UndertaleModLib.Util;

// EnsureDataLoaded() era una utilidad de UndertaleModTool, no
// existe en el contexto de DeltaPatcherCLI. Tanto en UTMT (donde
// hay que abrir un data.win antes de correr scripts) como en el
// CLI (donde ApplyChapterPatch carga el data.win antes de invocar
// el script) la verificacion es redundante. La rama de abajo
// (Data?.GeneralInfo?...) ya cubre el caso degenerado de Data
// nulo gracias al null-conditional.

if (Data?.GeneralInfo?.DisplayName?.Content.ToLower() != "deltarune chapter 2")
{
    ScriptError("Error : Not a Deltarune CH2 data.win file");
    return;
}

string bordersPath = Path.Combine(Path.GetDirectoryName(ScriptPath), "Borders");

Dictionary<string, UndertaleEmbeddedTexture> textures = new();
if (!Directory.Exists(bordersPath))
{
    throw new ScriptException("Border textures not found?? (esperaba: " + bordersPath + ")");
}

int lastTextPage = Data.EmbeddedTextures.Count - 1;
int lastTextPageItem = Data.TexturePageItems.Count - 1;

foreach (var path in Directory.EnumerateFiles(bordersPath))
{
    UndertaleEmbeddedTexture newtex = new UndertaleEmbeddedTexture();
    newtex.Name = new UndertaleString($"Texture {++lastTextPage}");
    newtex.TextureData.Image = GMImage.FromPng(File.ReadAllBytes(path));
    Data.EmbeddedTextures.Add(newtex);
    textures.Add(Path.GetFileName(path), newtex);
}

Action<string, UndertaleEmbeddedTexture, ushort, ushort, ushort, ushort> AssignBorderBackground = (name, tex, x, y, width, height) =>
{
    var bg = Data.Sprites.ByName(name);
    if (bg is null)
    {
        ScriptError(name + " not found!");
        return;
    }
    UndertaleTexturePageItem tpag = new UndertaleTexturePageItem();
    tpag.Name = new UndertaleString($"PageItem {++lastTextPageItem}");
    tpag.SourceX = x; tpag.SourceY = y; tpag.SourceWidth = width; tpag.SourceHeight = height;
    tpag.TargetX = 0; tpag.TargetY = 0; tpag.TargetWidth = width; tpag.TargetHeight = height;
    tpag.BoundingWidth = width; tpag.BoundingHeight = height;
    tpag.TexturePage = tex;
    Data.TexturePageItems.Add(tpag);
    bg.Textures[0].Texture = tpag;
};


AssignBorderBackground("border_line_1080", textures["border_line_1080.png"], 2, 2, 1920, 1080);
AssignBorderBackground("border_lw_town", textures["border_lw_town.png"], 2, 2, 1920, 1080);
AssignBorderBackground("border_dw_castletown", textures["border_dw_castletown.png"], 2, 2, 1920, 1080);
AssignBorderBackground("border_dw_cyber", textures["border_dw_cyber.png"], 2, 2, 1920, 1080);
AssignBorderBackground("border_dw_mansion", textures["border_dw_mansion.png"], 2, 2, 1920, 1080);
AssignBorderBackground("border_dw_city", textures["border_dw_city.png"], 2, 2, 1920, 1080);

var decompSettings = new Underanalyzer.Decompiler.DecompileSettings()
    {
        RemoveSingleLineBlockBraces = true,
        EmptyLineAroundBranchStatements = true,
        EmptyLineBeforeSwitchCases = true,
    };

UndertaleModLib.Compiler.CodeImportGroup importGroup = new(Data, null, decompSettings)
{
    ThrowOnNoOpFindReplace = true
};

// obj_initializer2
//
// PARCHE ADAPTADO PARA DELTRANSLATE:
//   El NXRUNE original usaba
//       global.screen_border_id = stringsetloc("Dynamic", "obj_initializer2_slash_Create_0_gml_22_0")
//   Como deltranslate prefiere el literal (ver cabecera apartado C),
//   aqui reemplazamos directamente con la cadena "Dynamic" sin
//   stringsetloc para no romper el match contra `border_options` en
//   obj_darkcontroller_Create_0.
importGroup.QueueFindReplace("gml_Object_obj_initializer2_Create_0", "global.screen_border_id = \"\";", "global.screen_border_id = \"Dynamic\";");

importGroup.QueueFindReplace("gml_Object_obj_initializer2_Create_0", @"if (global.is_console)
    loadtex = instance_create(0, 0, obj_prefetchtex);", @"if (true)
    loadtex = instance_create(0, 0, obj_prefetchtex);");

importGroup.QueueFindReplace("gml_Object_obj_initializer2_Step_0", @"    if (!textures_loaded)
        textures_loaded = loadtex.loaded;
    
    if (textures_loaded)
    {
    }
    else
    {
        exit;
    }
}", @"}
    if (!textures_loaded)
        textures_loaded = loadtex.loaded;
    
    if (textures_loaded)
    {
    }
    else
    {
        exit;
    }
");

importGroup.QueueFindReplace("gml_Object_obj_initializer2_Step_0", @"        if (global.is_console)
            global.screen_border_alpha = 0;", "global.screen_border_alpha = 0;");

importGroup.QueueFindReplace("gml_Object_obj_initializer2_Step_0", @"        if (global.is_console)
            global.screen_border_alpha = 1;", "global.screen_border_alpha = 1;");

importGroup.QueueFindReplace("gml_Object_obj_initializer2_Step_0", @"    if (global.is_console)
    {
        if (global.game_won == 1)", @"    if (true)
    {
        if (global.game_won == 1)");

importGroup.QueueAppend("gml_Object_obj_initializer2_Step_0", "global.game_won = scr_completed_chapter_any_slot(global.chapter);");

// obj_time

importGroup.QueueFindReplace("gml_Object_obj_time_Create_0", @"if (global.is_console)
{
    if (!instance_exists(obj_gamecontroller))
        instance_create(0, 0, obj_gamecontroller);
    
    if (!i_ex(obj_border_controller))
        instance_create(0, 0, obj_border_controller);
}", @"if (global.is_console)
{
    if (!instance_exists(obj_gamecontroller))
        instance_create(0, 0, obj_gamecontroller);
}

if (!i_ex(obj_border_controller))
    instance_create(0, 0, obj_border_controller);");

importGroup.QueueFindReplace("gml_Object_obj_time_Create_0", "if (display_width > (640 * _ww) && display_height > (480 * _ww))", "if (display_width > (640 * _ww) && display_height > (360 * _ww))");

importGroup.QueueFindReplace("gml_Object_obj_time_Create_0", "window_set_size(640 * window_size_multiplier, 480 * window_size_multiplier);", "window_set_size(640 * window_size_multiplier, 360 * window_size_multiplier);");


importGroup.QueueFindReplace("gml_Object_obj_time_Create_0", @"    if (global.is_console)
    {
        application_surface_enable(true);
        application_surface_draw_enable(false);
    }", @"application_surface_enable(true);
application_surface_draw_enable(false);");

importGroup.QueueFindReplace("gml_Object_obj_time_Create_0", "scr_enable_screen_border(global.is_console);", "scr_enable_screen_border(true);");

importGroup.QueueFindReplace("gml_Object_obj_time_Alarm_1", "window_set_size(640 * window_size_multiplier, 480 * window_size_multiplier);", @"window_set_size(640 * window_size_multiplier, 360 * window_size_multiplier);");

importGroup.QueueFindReplace("gml_Object_obj_time_Draw_77", "window_set_size(640 * window_size_multiplier, 480 * window_size_multiplier);", "window_set_size(640 * window_size_multiplier, 360 * window_size_multiplier);");

importGroup.QueueFindReplace("gml_Object_obj_time_Draw_64", "draw_sprite_ext(scr_84_get_sprite(\"spr_quitmessage\"), quit_timer / 7, 4, 4, 2, 2, 0, c_white, quit_timer / 15);", " draw_sprite_ext(scr_84_get_sprite(\"spr_quitmessage\"), quit_timer / 7, 40, 30, 2, 2, 0, c_white, quit_timer / 15);");

// obj_border_controller

importGroup.QueueFindReplace("gml_Object_obj_border_controller_Draw_77",
@"var xx = floor((ww - (sw * global.window_scale)) / 2);
var yy = floor((wh - (sh * global.window_scale)) / 2);", @"var border_w = 1920;
var border_h = 1080;
var xx, yy;

if ((ww / wh) > (border_w / border_h))
{
    var scale = wh / border_h;
    border_w *= scale;
    border_h *= scale;
    xx = (320 * (wh / 1080)) + (abs(ww - border_w) / 2);
    yy = 60 * (wh / 1080);
}
else
{
    var scale = ww / border_w;
    border_w *= scale;
    border_h *= scale;
    xx = 320 * (ww / 1920);
    yy = (60 * (ww / 1920)) + (abs(wh - border_h) / 2);
}");

importGroup.QueueFindReplace("gml_Object_obj_border_controller_Draw_77", "draw_surface_ext(application_surface, xx, yy, global.window_scale, global.window_scale, 0, c_white, 1);", "draw_surface_stretched(application_surface, xx, yy, ww - (2 * xx), wh - (2 * yy));");


// scr_draw_background_ps4

importGroup.QueueFindReplace("gml_GlobalScript_scr_draw_background_ps4", @"    if (os_type == os_ps4 || scr_is_switch_os() || os_type == os_ps5)
    {
        var scale = window_get_width() / 1920;
        draw_background_stretched(bg, xx * scale, yy * scale, background_get_width(bg) * scale, background_get_height(bg) * scale);
    }
    else
    {
        var scale = window_get_width() / 1920;
        draw_background_stretched(bg, xx * scale, yy * scale, background_get_width(bg) * scale, background_get_height(bg) * scale);
    }",
    @"var ww = window_get_width();
    var wh = window_get_height();
    var border_w = 1920;
    var border_h = 1080;
    var border_aspect = border_w / border_h;
    var window_aspect = ww / wh;
    var scale;
    
    if (window_aspect > border_aspect)
        scale = wh / border_h;
    else
        scale = ww / border_w;
    
    var draw_w = background_get_width(bg) * scale;
    var draw_h = background_get_height(bg) * scale;
    var off_x = (ww - (border_w * scale)) / 2;
    var off_y = (wh - (border_h * scale)) / 2;
    var draw_x = off_x + (xx * scale);
    var draw_y = off_y + (yy * scale);
    draw_background_stretched(bg, draw_x, draw_y, draw_w, draw_h);");

// obj_darkcontroller

importGroup.QueueFindReplace("gml_Object_obj_darkcontroller_Draw_0", "draw_sprite(spr_heart, 0, _heartXPos, yy + 160 + (global.submenucoord[30] * 35));", "draw_sprite(spr_heart, 0, _heartXPos, yy + 140 + (global.submenucoord[30] * 35));");

importGroup.QueueFindReplace("gml_Object_obj_darkcontroller_Draw_0", @"        draw_text(_xPos, yy + 150, string_hash_to_newline(stringsetloc(""Master Volume"", ""obj_darkcontroller_slash_Draw_0_gml_86_0"")));
        draw_text(_selectXPos, yy + 150, string_hash_to_newline(audvol));
        draw_set_color(c_white);
        draw_text(_xPos, yy + 185, string_hash_to_newline(stringsetloc(""Controls"", ""obj_darkcontroller_slash_Draw_0_gml_91_0"")));
        draw_text(_xPos, yy + 220, string_hash_to_newline(stringsetloc(""Simplify VFX"", ""obj_darkcontroller_slash_Draw_0_gml_92_0"")));
        draw_text(_selectXPos, yy + 220, string_hash_to_newline(flashoff));",
        @"        draw_text(_xPos, yy + 130, string_hash_to_newline(stringsetloc(""Master Volume"", ""obj_darkcontroller_slash_Draw_0_gml_86_0"")));
        draw_text(_selectXPos, yy + 130, string_hash_to_newline(audvol));
        draw_set_color(c_white);
        draw_text(_xPos, yy + 165, string_hash_to_newline(stringsetloc(""Controls"", ""obj_darkcontroller_slash_Draw_0_gml_91_0"")));
        draw_text(_xPos, yy + 200, string_hash_to_newline(stringsetloc(""Simplify VFX"", ""obj_darkcontroller_slash_Draw_0_gml_92_0"")));
        draw_text(_selectXPos, yy + 200, string_hash_to_newline(flashoff));");

// ---------------------------------------------------------------------
// PARCHE ADAPTADO PARA DELTRANSLATE:
//   - El condicional ahora incluye `|| os_type == os_android` (deltranslate
//     ya activa los bordes en Android).
//   - El array de opciones de borde se llama `border_options_tr` en lugar
//     de `border_options`. Mantenemos ese nombre en el reemplazo para que
//     "Dynamic"/"Simple"/"None" sigan traduciendose con el sistema de
//     stringsetloc/Create_0_gml_153_X.
//   - La rama else usa `_selectXPos` en lugar de `xx + 430` para
//     fullscreenoff/runoff (deltranslate normalizo las posiciones).
// ---------------------------------------------------------------------
importGroup.QueueFindReplace("gml_Object_obj_darkcontroller_Draw_0", @"        if (global.is_console || os_type == os_android)
        {
            draw_text(_xPos, yy + 255, string_hash_to_newline(autorun_text));
            draw_text(_selectXPos, yy + 255, string_hash_to_newline(runoff));
            
            if (global.submenu == 36)
                draw_set_color(c_yellow);
            else if (global.disable_border)
                draw_set_color(c_gray);
            
            draw_text(_xPos, yy + 290, stringsetloc(""Border"", ""obj_darkcontroller_slash_Draw_0_gml_112_0""));
            draw_text(_selectXPos, yy + 290, border_options_tr[selected_border]);
            draw_set_color(c_white);
            draw_text(_xPos, yy + 325, string_hash_to_newline(stringsetloc(""Return to Title"", ""obj_darkcontroller_slash_Draw_0_gml_95_0"")));
            draw_text(_xPos, yy + 360, string_hash_to_newline(back_text));
        }
        else
        {
            draw_text(_xPos, yy + 255, string_hash_to_newline(stringsetloc(""Fullscreen"", ""obj_darkcontroller_slash_Draw_0_gml_93_0"")));
            draw_text(_selectXPos, yy + 255, string_hash_to_newline(fullscreenoff));
            draw_text(_xPos, yy + 290, string_hash_to_newline(autorun_text));
            draw_text(_selectXPos, yy + 290, string_hash_to_newline(runoff));
            draw_text(_xPos, yy + 325, string_hash_to_newline(stringsetloc(""Return to Title"", ""obj_darkcontroller_slash_Draw_0_gml_95_0"")));
            draw_text(_xPos, yy + 360, string_hash_to_newline(back_text));
        }",
        @"        draw_text(_xPos, yy + 235, string_hash_to_newline(stringsetloc(""Fullscreen"", ""obj_darkcontroller_slash_Draw_0_gml_93_0"")));
        draw_text(_selectXPos, yy + 235, string_hash_to_newline(fullscreenoff));
        draw_text(_xPos, yy + 270, string_hash_to_newline(autorun_text));
        draw_text(_selectXPos, yy + 270, string_hash_to_newline(runoff));
        if (global.submenu == 36)
            draw_set_color(c_yellow);
        else if (global.disable_border)
            draw_set_color(c_gray);
        
        draw_text(_xPos, yy + 305, stringsetloc(""Border"", ""obj_darkcontroller_slash_Draw_0_gml_112_0""));
        draw_text(_selectXPos, yy + 305, border_options_tr[selected_border]);
        draw_set_color(c_white);
        draw_text(_xPos, yy + 340, string_hash_to_newline(stringsetloc(""Return to Title"", ""obj_darkcontroller_slash_Draw_0_gml_95_0"")));
        draw_text(_xPos, yy + 375, string_hash_to_newline(back_text));");

importGroup.QueueFindReplace("gml_Object_obj_darkcontroller_Step_0", "if (global.is_console && global.submenu == 36)", "if (global.submenu == 36)");

importGroup.QueueFindReplace("gml_Object_obj_darkcontroller_Step_0", "if (global.submenucoord[30] > 6)", "if (global.submenucoord[30] > 7)");

importGroup.QueueFindReplace("gml_Object_obj_darkcontroller_Step_0", "global.submenucoord[30] = 6;", "global.submenucoord[30] = 7;");

importGroup.QueueTrimmedLinesFindReplace("gml_Object_obj_darkcontroller_Step_0", @"if (global.is_console)
                {
                    if (global.submenucoord[30] == 3)
                    {
                        if (global.flag[11] == 0)
                            global.flag[11] = 1;
                        else
                            global.flag[11] = 0;
                    }
                    
                    if (global.submenucoord[30] == 4)
                    {
                        if (room == room_dw_mansion_krisroom && global.plot <= 100)
                            global.disable_border = true;

                        if (global.disable_border)
                        {
                            selectnoise = 0;
                        }
                        else
                        {
                            global.submenu = 36;
                            check_border = 1;
                            border_select = 0;
                        }
                    }
                    
                    if (global.submenucoord[30] == 5)
                        global.submenu = 34;
                    
                    if (global.submenucoord[30] == 6)
                    {
                        m_quit = 1;
                        cancelnoise = 1;
                    }
                }
                else
                {
                    if (global.submenucoord[30] == 3)
                    {
                        with (obj_time)
                            fullscreen_toggle = 1;
                    }
                    
                    if (global.submenucoord[30] == 4)
                    {
                        if (global.flag[11] == 0)
                            global.flag[11] = 1;
                        else
                            global.flag[11] = 0;
                    }
                    
                    if (global.submenucoord[30] == 5)
                        global.submenu = 34;
                    
                    if (global.submenucoord[30] == 6)
                    {
                        m_quit = 1;
                        cancelnoise = 1;
                    }
                }",
                @"if (global.submenucoord[30] == 3)
                    {
                        with (obj_time)
                            fullscreen_toggle = 1;
                    }
                    
                    if (global.submenucoord[30] == 4)
                    {
                        if (global.flag[11] == 0)
                            global.flag[11] = 1;
                        else
                            global.flag[11] = 0;
                    }

                    if (global.submenucoord[30] == 5)
                    {
                        if (room == room_dw_mansion_krisroom && global.plot <= 100)
                            global.disable_border = true;
                        
                        if (global.disable_border)
                        {
                            selectnoise = 0;
                        }
                        else
                        {
                            global.submenu = 36;
                            check_border = 1;
                            border_select = 0;
                        }
                    }
                    
                    if (global.submenucoord[30] == 6)
                        global.submenu = 34;
                    
                    if (global.submenucoord[30] == 7)
                    {
                        m_quit = 1;
                        cancelnoise = 1;
                    }");

// DEVICE_MENU
//
// NOTA: el QueueFindReplace original sobre gml_Object_DEVICE_MENU_Step_0
// (que expandia `if (!global.is_console) { ini_close(); }` para que
// leyera el ID del borde del .ini) ha sido eliminado porque deltranslate
// REEMPLAZA el archivo entero y en su version YA APLICA esa misma logica
// (de hecho la extiende tambien al else, para que tambien funcione en
// consola). Si lo dejaramos, fallaria con "no-op find and replace"
// porque el patron original ya no existe en el codigo.

importGroup.QueueFindReplace("gml_Object_DEVICE_MENU_Create_0", @"if (global.is_console)
    global.chapter_return = -1;", "global.chapter_return = -1;");

importGroup.QueueFindReplace("gml_Object_DEVICE_MENU_Alarm_0", "if (global.is_console)", "if (true)");

// scr_text

importGroup.QueueFindReplace("gml_GlobalScript_scr_text", "if (!paptalk && global.is_console)", "if (!paptalk)");

// obj_ch2_lw_cutscenes_short

importGroup.QueueFindReplace("gml_Object_obj_ch2_lw_cutscenes_short_Create_0", "if (!noelle_chalk && global.is_console)", "if (!noelle_chalk)");

// obj_onion_event

importGroup.QueueFindReplace("gml_Object_obj_onion_event_Create_0", "if (global.is_console)", "if (true)");

importGroup.Import();

ScriptMessage("All done! :3  (NXRUNE_CH2 + deltranslate compat)");
