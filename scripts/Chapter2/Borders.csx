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

//
// PARCHE ADAPTADO PARA DELTRANSLATE:
//   El NXRUNE original usaba
//       global.screen_border_id = stringsetloc("Dynamic", "obj_initializer2_slash_Create_0_gml_22_0")
//   Como deltranslate prefiere el literal (ver cabecera apartado C),
//   aqui reemplazamos directamente con la cadena "Dynamic" sin
//   stringsetloc para no romper el match contra `border_options` en
//   obj_darkcontroller_Create_0.
importGroup.QueueFindReplace("gml_Object_obj_initializer2_Create_0", "global.screen_border_id = \"\";", "global.screen_border_id = \"Dynamic\";");

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

importGroup.QueueFindReplace("gml_Object_obj_time_Alarm_1", "window_set_size(640 * window_size_multiplier, 480 * window_size_multiplier);", @"window_set_size(640 * window_size_multiplier, 360 * window_size_multiplier);");

importGroup.QueueFindReplace("gml_Object_obj_time_Draw_77", "window_set_size(640 * window_size_multiplier, 480 * window_size_multiplier);", "window_set_size(640 * window_size_multiplier, 360 * window_size_multiplier);");

importGroup.QueueFindReplace("gml_Object_obj_time_Draw_64", "draw_sprite_ext(scr_84_get_sprite(\"spr_quitmessage\"), quit_timer / 7, 4, 4, 2, 2, 0, c_white, quit_timer / 15);", @"draw_sprite_ext(scr_84_get_sprite(""spr_quitmessage""), quit_timer / 7, ((global.screen_border_id == ""None"" || global.screen_border_id == ""なし"") ? 4 : 40), ((global.screen_border_id == ""None"" || global.screen_border_id == ""なし"") ? 4 : 30), 2, 2, 0, c_white, quit_timer / 15);");

// obj_border_controller

importGroup.QueueFindReplace("gml_Object_obj_border_controller_Draw_77",
@"var xx = floor((ww - (sw * global.window_scale)) / 2);
var yy = floor((wh - (sh * global.window_scale)) / 2);", @"var _border_off = (global.screen_border_id == ""None"" || global.screen_border_id == ""なし"");
var xx, yy, _bscale;

if (_border_off)
{
    xx = floor((ww - (sw * global.window_scale)) / 2);
    yy = floor((wh - (sh * global.window_scale)) / 2);
    _bscale = global.window_scale;
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
        _bscale = scale;
    }
    else
    {
        var scale = ww / border_w;
        border_w *= scale;
        border_h *= scale;
        xx = 320 * (ww / 1920);
        yy = (60 * (ww / 1920)) + (abs(wh - border_h) / 2);
        _bscale = scale;
    }
}

// Publica la geometria final del area de juego para que lo que se dibuje en
// capa GUI pueda situarse dentro del marco y no sobre la ventana entera.
// Con el borde en None quedan los valores vanilla, asi que quien lo lea
// obtiene el rectangulo correcto en los dos modos.
application_surface_rects =
{
    xx: xx,
    yy: yy,
    w: (_border_off ? (sw * global.window_scale) : (ww - (2 * xx))),
    h: (_border_off ? (sh * global.window_scale) : (wh - (2 * yy))),
    border_scale: _bscale
};");

importGroup.QueueFindReplace("gml_Object_obj_border_controller_Draw_77", "draw_surface_ext(application_surface, xx, yy, global.window_scale, global.window_scale, 0, c_white, 1);", @"if (_border_off)
    draw_surface_ext(application_surface, xx, yy, global.window_scale, global.window_scale, 0, c_white, 1);
else
    draw_surface_stretched(application_surface, xx, yy, ww - (2 * xx), wh - (2 * yy));");

// Valores por defecto para el primer frame, antes de que el Draw_77 haya
// corrido ni una vez: identidad (juego a 640x480 sin desplazar).
importGroup.QueueAppend("gml_Object_obj_border_controller_Create_0", @"application_surface_rects =
{
    xx: 0,
    yy: 0,
    w: 640,
    h: 480,
    border_scale: 1
};");


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
//   - Tras cada TRANSICION (cambio de opcion, salida de pantalla completa,
//     arranque) comprueba y corrige el tamano durante 30 frames (~1 s) y
//     luego para. No vale corregir una sola vez: el propio juego tiene un
//     vigilante en obj_time_Draw_75 (Cap.1) / obj_time_Draw_77 (Cap.2-4)
//     que detecta el cambio de pantalla completa y llama a window_set_size
//     DESPUES de este bloque en el mismo frame, dejando la ventana en 16:9.
//     Con la ventana de gracia se corrige al frame siguiente (se ve un
//     frame en 16:9 al salir de pantalla completa). Tampoco se fuerza cada
//     frame para siempre, para no pelearse con el jugador si redimensiona
//     la ventana a mano.
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

    if (!variable_instance_exists(id, ""border_size_hold""))
    {
        border_size_hold = 30;
        border_size_bo = _bo;
        border_size_fs = _fs;
        border_cfg_id = global.screen_border_id;
    }

    if (_bo != border_size_bo || _fs != border_size_fs)
        border_size_hold = 30;

    if (!_fs && border_size_hold > 0)
    {
        border_size_hold -= 1;

        var _m = window_size_multiplier;

        if (_bo)
            _m = max(1, min(_m, ceil(display_get_height() / 480) - 1));

        var _tw = 640 * _m;
        var _th = (_bo ? 480 : 360) * _m;

        if (window_get_width() != _tw || window_get_height() != _th)
        {
            window_set_size(_tw, _th);
            alarm[2] = 1;
        }
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

// =====================================================================
// obj_smallface  (port de NXRUNE b12d9bc0 "Fix obj_smallface")
// =====================================================================
// obj_smallface dibuja en Draw GUI (Draw_64) usando coordenadas de MUNDO
// menos la camara (x - cx). La capa GUI no sigue a la application_surface,
// asi que cuando el marco mete el juego hacia dentro el retrato pequeno y
// su texto se quedan colocados respecto a la ventana entera, no respecto
// al area de juego: aparecen desplazados hacia fuera y mas grandes.
//
// Se corrige recolocandolos dentro del rectangulo que publica
// obj_border_controller.application_surface_rects.
//
// Solo Ch2 y Ch3: en Ch4 y Ch5 este evento es un `exit;` ya en el vanilla
// (el objeto no dibuja nada), asi que no hay nada que corregir. NXRUNE hace
// lo mismo: su fix solo esta en NXRUNE_CH2.csx y NXRUNE_CH3.csx.
//
// DIFERENCIAS DELIBERADAS CON NXRUNE:
//   - NXRUNE multiplica por la constante 3 (3 * border_scale). Eso solo
//     cuadra con SU display_set_gui_maximize(), que nosotros no aplicamos,
//     y aun asi queda 1.5x por encima de la escala real del area de juego
//     (w / 640 = 2 a 1080p). Aqui la escala se DERIVA del rectangulo, que
//     es lo que hace que la imagen coincida con el juego.
//   - La POSICION usa factores x e y por separado (display_get_gui_* /
//     window_get_*), asi que la formula vale tanto si la capa GUI esta
//     maximizada como si no. El DIBUJO, en cambio, usa un factor unico:
//     con dos factores distintos los glifos salen deformados (probado en
//     juego el 2026-08-09: en 16:9 el texto salia un 25% mas estrecho que
//     alto, que es justo el cociente (4/3)/(16/9) = 0.75).
//   - Con el borde en "None" los factores quedan en identidad (0/0/1/1),
//     de modo que el dibujo es byte a byte el vanilla y ese modo no puede
//     regresionar.
// =====================================================================

importGroup.QueueTrimmedLinesFindReplace("gml_Object_obj_smallface_Draw_64", "cx = camerax();", @"var _sfx = 0;
    var _sfy = 0;
    var _sfsx = 1;
    var _sfsy = 1;
    var _sfs = 1;
    if (instance_exists(obj_border_controller) && global.screen_border_id != ""None"" && global.screen_border_id != ""なし"")
    {
        var _r = obj_border_controller.application_surface_rects;
        var _kx = display_get_gui_width() / window_get_width();
        var _ky = display_get_gui_height() / window_get_height();
        _sfx = _r.xx * _kx;
        _sfy = _r.yy * _ky;
        _sfsx = (_r.w / 640) * _kx;
        _sfsy = (_r.h / 480) * _ky;
        // La POSICION necesita los dos factores por separado (la capa GUI no
        // tiene el mismo aspecto que la ventana), pero DIBUJAR con escalas
        // distintas en x e y deforma los glifos y el sprite: en 16:9 el
        // cociente es (4/3)/(16/9) = 0.75, o sea 25% mas estrecho que alto.
        // Asi que para dibujar se usa un factor UNICO. Se toma el vertical
        // porque es el que quedo correcto al probarlo en juego.
        _sfs = _sfsy;
    }
    cx = camerax();");

importGroup.QueueTrimmedLinesFindReplace("gml_Object_obj_smallface_Draw_64", "draw_sprite_ext(sprite_index, image_index, x - cx, y - cy, image_xscale, image_yscale, image_angle, image_blend, facealpha);", "draw_sprite_ext(sprite_index, image_index, _sfx + ((x - cx) * _sfsx), _sfy + ((y - cy) * _sfsy), image_xscale * _sfs, image_yscale * _sfs, image_angle, image_blend, facealpha);");

importGroup.QueueTrimmedLinesFindReplace("gml_Object_obj_smallface_Draw_64", "draw_text((x + 70) - cx, (y + 10) - cy, string_hash_to_newline(mystring));", "draw_text_transformed(_sfx + ((((x + 70) - cx)) * _sfsx), _sfy + ((((y + 10) - cy)) * _sfsy), string_hash_to_newline(mystring), _sfs, _sfs, 0);");

importGroup.QueueTrimmedLinesFindReplace("gml_Object_obj_smallface_Draw_64", "draw_text((x + 70) - cx, (y + 15) - cy, string_hash_to_newline(mystring));", "draw_text_transformed(_sfx + ((((x + 70) - cx)) * _sfsx), _sfy + ((((y + 15) - cy)) * _sfsy), string_hash_to_newline(mystring), _sfs, _sfs, 0);");

importGroup.QueueTrimmedLinesFindReplace("gml_Object_obj_smallface_Draw_64", "draw_text((x + 70 + random(1)) - cx, (y + 15 + random(1)) - cy, string_hash_to_newline(partstring));", "draw_text_transformed(_sfx + ((((x + 70 + random(1)) - cx)) * _sfsx), _sfy + ((((y + 15 + random(1)) - cy)) * _sfsy), string_hash_to_newline(partstring), _sfs, _sfs, 0);");

importGroup.Import();

ScriptMessage("All done! :3  (NXRUNE_CH2 + deltranslate compat)");
