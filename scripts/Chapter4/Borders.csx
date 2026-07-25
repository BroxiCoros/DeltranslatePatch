// =====================================================================
// Chapter4/Borders.csx
// =====================================================================
// Version del script NXRUNE_CH4.csx (de NXRUNE, por IRUZZ) adaptada
// para correr DESPUES de que se haya aplicado el mod de traduccion
// deltranslate sobre el data.win de DELTARUNE Capitulo 4.
//
// USO:
//
//   Automatico (instalador / DeltaPatcherCLI):
//     Cuando se pasa la bandera --borders al patcher, el instalador
//     invoca este script DESPUES de Fix.csx sobre el mismo data.win.
//     No hay nada manual que hacer: los recursos PNG viven en la
//     carpeta hermana scripts/Chapter4/Borders/ y se descubren via
//     Path.GetDirectoryName(ScriptPath).
//
//   Manual (UndertaleModTool):
//     1. Cargar chapter4_windows/data.win en UndertaleModTool.
//     2. Ejecutar primero scripts/Chapter4/Fix.csx (Scripts -> Run
//        other script).
//     3. Ejecutar este archivo (scripts/Chapter4/Borders.csx) sobre
//        el MISMO data.win, sin guardar entre ambos pasos.
//     4. Guardar el data.win.
//
// QUE CAMBIA RESPECTO AL NXRUNE_CH4.csx ORIGINAL:
//
//   A) gml_Object_obj_darkcontroller_Draw_0, parche del bloque if-else
//      del menu de configuracion:
//        - El patron de busqueda original asume el codigo del juego
//          virgen: `if (global.is_console)` y `border_options[...]`.
//        - Tras pasar deltranslate, ese codigo es ahora
//          `if (global.is_console || os_type == os_android)` y usa
//          `border_options_tr[...]` (la version traducida del array).
//        - Ajustamos el patron de busqueda Y el reemplazo para usar
//          `border_options_tr` y conservar la traduccion de los nombres
//          "Dynamic"/"Simple"/"None" en el menu del borde.
//
//   B) gml_Object_DEVICE_MENU_Step_0:
//        - El parche original de NXRUNE expandia
//            if (!global.is_console) { ini_close(); }
//          para que tambien leyera el ID del borde del .ini en PC.
//        - deltranslate YA APLICA ese mismo cambio (de hecho lo extiende
//          al else tambien). Por lo tanto eliminamos ese
//          QueueFindReplace para evitar el "no-op find and replace".
//
// El resto de los parches no cambian: deltranslate no toca obj_time,
// obj_border_controller, scr_draw_background_ps4, obj_darkcontroller_Step_0,
// DEVICE_MENU_Alarm_0, scr_text, obj_onion_event_Create_0,
// obj_dw_church_ripplepuzzle_postgers_Step_0, scr_load, ni el bloque del
// obj_initializer2_Create_0 que NXRUNE necesita.
//
// Si en el futuro deltranslate cambia algo mas, este script fallara con
// "no-op find and replace" sobre el codigo correspondiente y habra que
// volver a sincronizar los patrones.
// =====================================================================

// =====================================================================
// AJUSTE PROPIO DEL FORK: layout condicional con el borde en "None"
// =====================================================================
// NXRUNE convierte el juego a 16:9 de forma INCONDICIONAL: el xx/yy del
// Draw_77 mete SIEMPRE la application_surface en el recuadro interior del
// marco de 1920x1080 (320 px de margen lateral, 60 px arriba y abajo), se
// dibuje o no un borde. Con la opcion "None" eso dejaba franjas negras
// arriba y abajo y el juego mas chico que sin el mod.
//
// Aqui el layout consulta global.screen_border_id:
//   - "None" / "なし"  -> formula vanilla (centrar y maximizar con
//     global.window_scale) + draw_surface_ext: el juego ocupa todo lo que
//     puede en la ventana, igual que sin los scripts de bordes.
//   - cualquier otra -> layout del marco + draw_surface_stretched.
//
// Se consulta screen_border_id (la opcion ELEGIDA por el jugador) y NO
// screen_border_active porque el Cap.3 fuerza scr_enable_screen_border(1)
// al crear obj_tenna_enemy: con screen_border_active el juego cambiaria de
// tamano de golpe al entrar en ese combate.
//
// Mismo criterio en el mensaje de salida (obj_time_Draw_64): (4, 4) vanilla
// con el borde desactivado, (40, 30) cuando hay marco. Se deja como UNA
// sola sentencia con ternarios a proposito: el decompilador corre con
// RemoveSingleLineBlockBraces, asi que ese draw_sprite_ext puede quedar
// dentro de un `if (quit_timer >= 1)` SIN llaves y partirlo en varias
// sentencias romperia la condicion.
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

if (Data?.GeneralInfo?.DisplayName?.Content.ToLower() != "deltarune chapter 4")
{
    ScriptError("Error : Not a Deltarune CH4 data.win file");
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

Action<string, UndertaleEmbeddedTexture, ushort, ushort, ushort, ushort, ushort, ushort, ushort, ushort> AssignBorderBackground = (name, tex, x, y, width, height, tarX, tarY, tarWidth, tarHeight) =>
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
    tpag.TargetX = tarX; tpag.TargetY = tarY; tpag.TargetWidth = tarWidth; tpag.TargetHeight = tarHeight;
    tpag.BoundingWidth = width; tpag.BoundingHeight = height;
    tpag.TexturePage = tex;
    Data.TexturePageItems.Add(tpag);
    bg.Textures[0].Texture = tpag;
};

AssignBorderBackground("border_dw_titan_base", textures["border_dw_titan_base.png"], 2, 2, 1920, 1080, 0, 0, 1920, 1080);
AssignBorderBackground("border_dw_titan_eyes_red", textures["border_dw_castletown.png"], 2, 1086, 1920, 941, 0, 70, 1920, 941);
AssignBorderBackground("border_lw_town_night", textures["border_lw_town_night.png"], 2, 2, 1920, 1080, 0, 0, 1920, 1080);
AssignBorderBackground("border_dw_titan_eyes", textures["border_dw_church_a.png"], 2, 1086, 1920, 881, 0, 100, 1920, 881);
AssignBorderBackground("border_line_1080", textures["border_line_1080.png"], 2, 2, 1920, 1080, 0, 0, 1920, 1080);
AssignBorderBackground("border_lw_town", textures["border_lw_town.png"], 2, 2, 1920, 1080, 0, 0, 1920, 1080);
AssignBorderBackground("border_dw_castletown", textures["border_dw_castletown.png"], 2, 2, 1920, 1080, 0, 0, 1920, 1080);
AssignBorderBackground("border_dw_church_c", textures["border_dw_church_c.png"], 2, 2, 1920, 1080, 0, 0, 1920, 1080);
AssignBorderBackground("border_dw_church_a", textures["border_dw_church_a.png"], 2, 2, 1920, 1080, 0, 0, 1920, 1080);
AssignBorderBackground("border_dw_church_b", textures["border_dw_church_b.png"], 2, 2, 1920, 1080, 0, 0, 1920, 1080);



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

// ---------------------------------------------------------------------
// PRECARGA DE TEXTURAS (obj_prefetchtex): QUITADA A PROPOSITO
// ---------------------------------------------------------------------
// NXRUNE encendia en PC el precargador de texturas de consola
//   obj_initializer2_Create_0: `if (global.is_console) loadtex = ...` -> `if (true)`
// y sacaba el gate de `textures_loaded` fuera del bloque de consola en
// obj_initializer2_Step_0, con lo que el juego ESPERABA a la precarga.
// Eso es la animacion del perro (spr_dog_turn_full) con la barra de
// progreso al entrar al capitulo: obj_prefetchtex precarga UNA pagina de
// texturas por frame, asi que la espera dura tantos frames como paginas
// haya. El Cap.1 nunca llevo esos parches, por eso ahi no aparecia.
//
// Los dos parches estan quitados: en PC se vuelve al comportamiento
// vanilla (carga perezosa, sin animacion ni espera). Contrapartida: la
// pagina de textura de cada imagen de borde se sube la primera vez que se
// dibuja, lo que puede dar un micro-tiron puntual.
//
// OJO: los dos parches van JUNTOS. Si se restaura solo el del Step_0, en
// PC `loadtex` vale -4 y `loadtex.loaded` revienta.
// ---------------------------------------------------------------------


importGroup.QueueFindReplace("gml_Object_obj_initializer2_Step_0", @"        if (global.is_console)
            global.screen_border_alpha = 0;", "global.screen_border_alpha = 0;");

importGroup.QueueFindReplace("gml_Object_obj_initializer2_Step_0", @"        if (global.is_console)
            global.screen_border_alpha = 1;", "global.screen_border_alpha = 1;");

importGroup.QueueAppend("gml_Object_obj_initializer2_Step_0", "global.game_won = scr_completed_chapter_any_slot(global.chapter);");

// scr_load
importGroup.QueueFindReplace("gml_GlobalScript_scr_load", @"    if (global.is_console)
        global.tempflag[95] = 1;", "global.tempflag[95] = 1;");

// obj_time

importGroup.QueueFindReplace("gml_Object_obj_time_Create_0", @"if (global.is_console)
{
    if (!instance_exists(obj_gamecontroller))
        instance_create(0, 0, obj_gamecontroller);
    
    instance_create(0, 0, obj_border_controller);
}", @"if (global.is_console)
{
    if (!instance_exists(obj_gamecontroller))
        instance_create(0, 0, obj_gamecontroller);
}
    instance_create(0, 0, obj_border_controller);");


importGroup.QueueFindReplace("gml_Object_obj_time_Create_0", "if (display_width > (640 * _ww) && display_height > (480 * _ww))", "if (display_width > (640 * _ww) && display_height > (360 * _ww))");

importGroup.QueueFindReplace("gml_Object_obj_time_Create_0", "window_set_size(640 * window_size_multiplier, 480 * window_size_multiplier);", "window_set_size(640 * window_size_multiplier, 360 * window_size_multiplier);");

importGroup.QueueFindReplace("gml_Object_obj_time_Create_0", @"    if (global.is_console)
    {
        application_surface_enable(true);
        application_surface_draw_enable(false);
    }", @"application_surface_enable(true);
application_surface_draw_enable(false);");

// ---------------------------------------------------------------------
// Que el menu de seleccion de partida respete la opcion de borde
// ---------------------------------------------------------------------
// La opcion se guarda POR PARTIDA: obj_darkcontroller escribe BORDER/TYPE
// en keyconfig_<filechoice>.ini y DEVICE_MENU la lee al cargar esa partida.
// En la pantalla de seleccion todavia no hay filechoice, asi que
// global.screen_border_id valia siempre el "Dynamic" que deja
// obj_initializer2_Create_0 y el menu salia con marco aunque el jugador lo
// tuviera desactivado.
//
// Aqui se replica el ajuste en true_config.ini, el ini GLOBAL (no por
// partida) que el juego ya usa para FULLSCREEN: se lee en el ini_open que
// ya existe en obj_time_Create_0 (ancla unica en los 5 capitulos, y en
// bloque con llaves), y se escribe desde el bloque del Step de mas abajo
// cada vez que cambia. Cada partida conserva su ajuste; el menu usa el
// ultimo que se uso, igual que hace el juego con la pantalla completa.
//
// obj_initializer2_Create_0 fija global.screen_border_id bastante antes de
// crear obj_time (lineas 54-59 vs 100-111 segun el capitulo), asi que aqui
// la global ya existe.
// ---------------------------------------------------------------------
importGroup.QueueFindReplace("gml_Object_obj_time_Create_0", @"ini_open(""true_config.ini"");", @"ini_open(""true_config.ini"");
global.screen_border_id = ini_read_string(""BORDER"", ""TYPE"", global.screen_border_id);");

importGroup.QueueFindReplace("gml_Object_obj_time_Create_0", "scr_enable_screen_border(global.is_console);", @"scr_enable_screen_border(global.screen_border_id != ""None"" && global.screen_border_id != ""なし"");");

importGroup.QueueFindReplace("gml_Object_obj_time_Alarm_1", "window_set_size(640 * window_size_multiplier, 480 * window_size_multiplier);", "window_set_size(640 * window_size_multiplier, 360 * window_size_multiplier);");

importGroup.QueueFindReplace("gml_Object_obj_time_Step_0", "if (global.is_console)", "if (true)");

importGroup.QueueFindReplace("gml_Object_obj_time_Draw_64", "draw_sprite_ext(scr_84_get_sprite(\"spr_quitmessage\"), quit_timer / 7, 4, 4, 2, 2, 0, c_white, quit_timer / 15);", @"draw_sprite_ext(scr_84_get_sprite(""spr_quitmessage""), quit_timer / 7, ((global.screen_border_id == ""None"" || global.screen_border_id == ""なし"") ? 4 : 40), ((global.screen_border_id == ""None"" || global.screen_border_id == ""なし"") ? 4 : 30), 2, 2, 0, c_white, quit_timer / 15);");

importGroup.QueueFindReplace("gml_Object_obj_time_Draw_77", "window_set_size(640 * window_size_multiplier, 480 * window_size_multiplier);", "window_set_size(640 * window_size_multiplier, 360 * window_size_multiplier);");

// obj_border_controller

importGroup.QueueFindReplace("gml_Object_obj_border_controller_Draw_77", @"var xx = floor((ww - (sw * global.window_scale)) / 2);
var yy = floor((wh - (sh * global.window_scale)) / 2);",
@"var _border_off = (global.screen_border_id == ""None"" || global.screen_border_id == ""なし"");
var xx, yy;

if (_border_off)
{
    xx = floor((ww - (sw * global.window_scale)) / 2);
    yy = floor((wh - (sh * global.window_scale)) / 2);
}
else
{
    var border_w = 1920;
    var border_h = 1080;

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
    }
}");

importGroup.QueueFindReplace("gml_Object_obj_border_controller_Draw_77", "draw_surface_ext(application_surface, xx, yy, global.window_scale, global.window_scale, 0, c_white, 1);", @"if (_border_off)
    draw_surface_ext(application_surface, xx, yy, global.window_scale, global.window_scale, 0, c_white, 1);
else
    draw_surface_stretched(application_surface, xx, yy, ww - (2 * xx), wh - (2 * yy));");


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

importGroup.QueueFindReplace("gml_Object_obj_darkcontroller_Step_0", @"                if (global.is_console)
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
// YA APLICA esa misma logica en su replazo del archivo (de hecho la
// extiende tambien al else, para que tambien funcione en consola). Si lo
// dejaramos, fallaria con "no-op find and replace" porque el patron
// original ya no existe en el codigo.

importGroup.QueueFindReplace("gml_Object_DEVICE_MENU_Alarm_0", "if (global.is_console)", "if (true)");

// scr_text

importGroup.QueueFindReplace("gml_GlobalScript_scr_text", "if (!paptalk && global.is_console)", "if (!paptalk)");

// obj_onion_event

importGroup.QueueFindReplace("gml_Object_obj_onion_event_Create_0", "if (global.is_console)", "if (true)");

// obj_dw_church_ripplepuzzle_postgers

importGroup.QueueFindReplace("gml_Object_obj_dw_church_ripplepuzzle_postgers_Step_0", "if (scr_is_switch_os())", "if (true)");

// ---------------------------------------------------------------------
// Recuperar la ventana 4:3 (640x480) cuando el borde esta en "None"
// ---------------------------------------------------------------------
// Los window_set_size de arriba fijan la ventana a 16:9 (640x360) siempre.
// Este bloque la devuelve a 640x480 cuando el jugador tiene el borde
// desactivado, y a 16:9 cuando lo vuelve a activar.
//
//   - Va como QueueAppend: anadir sentencias al FINAL de una entrada es
//     seguro, no depende de las llaves ni del formato del decompilado
//     (a diferencia de un find&replace multi-sentencia).
//   - Solo actua en las TRANSICIONES (cambio de opcion, salida de pantalla
//     completa, primer frame). Si se forzara cada frame, se pelearia con el
//     jugador cuando redimensiona la ventana a mano.
//   - El multiplicador se recalcula para 4:3: window_size_multiplier se
//     computa contra 360*_ww, asi que en pantallas como 2560x1440 da 3 y
//     480*3 = 1440 no cabria. ceil(display_get_height() / 480) - 1
//     reproduce el ">" estricto del bucle vanilla (1440 -> 2, 1080 -> 2,
//     2160 -> 4).
//   - Las variables de estado se crean con variable_instance_exists en vez
//     de tocar el Create_0, para no anadir otro parche fragil.
// ---------------------------------------------------------------------
importGroup.QueueAppend("gml_Object_obj_time_Step_0", @"
if (!global.is_console && variable_global_exists(""screen_border_id""))
{
    var _bo = (global.screen_border_id == ""None"" || global.screen_border_id == ""なし"");
    var _fs = window_get_fullscreen();

    if (!variable_instance_exists(id, ""border_size_ready""))
    {
        border_size_ready = false;
        border_size_bo = _bo;
        border_size_fs = _fs;
        border_cfg_id = global.screen_border_id;
    }

    if (!_fs && (!border_size_ready || _bo != border_size_bo || _fs != border_size_fs))
    {
        var _m = window_size_multiplier;

        if (_bo)
            _m = max(1, min(_m, ceil(display_get_height() / 480) - 1));

        window_set_size(640 * _m, (_bo ? 480 : 360) * _m);
        alarm[2] = 1;
        border_size_ready = true;
    }

    if (global.screen_border_id != border_cfg_id)
    {
        border_cfg_id = global.screen_border_id;
        ini_open(""true_config.ini"");
        ini_write_string(""BORDER"", ""TYPE"", border_cfg_id);
        ini_close();
    }

    border_size_bo = _bo;
    border_size_fs = _fs;
}");

importGroup.Import();

ScriptMessage("All done! :3  (NXRUNE_CH4 + deltranslate compat)");
