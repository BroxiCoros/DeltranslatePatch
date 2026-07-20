// Carga una fuente del pack con tamano y rango de glifos configurables.
//
// Resolucion de tamano y rango (mayor a menor prioridad):
//   1. chapter_settings.json -> font_settings.<fnt_name>.{size,range}
//   2. settings.json         -> font_settings.<fnt_name>.{size,range}
//   3. argument1 (size por defecto) / get_lang_setting("fonts_range") o [2,128]
//
// Override por capitulo: si el pack provee `<fnt_name>_chapterN.(ttf|otf)`
// en `fonts/`, gana sobre el generico `<fnt_name>.(ttf|otf)`. Sirve cuando
// una fuente compartida por nombre (p. ej. fnt_8bit) es distinta entre
// capitulos: el juego sigue pidiendo "fnt_8bit" y aqui cargamos el correcto.
//
// Nota: todas las temporales son `var` (locales) a proposito. Antes `path`
// era de instancia y podia pisar la variable `path` de obj_mainchara_board
// (mp_grid_path) -> crash del tablero del Cap. 3 al cargar fuentes.
//
// Compatible con packs antiguos: sin font_settings ni `_chapterN`, se
// comporta igual que el mod base.

function add_font(argument0, argument1) //gml_Script_add_font
{
    var fnt_name = argument0
    var fnt_size = argument1

    var fonts_range = get_lang_setting("fonts_range")
    if (is_undefined(fonts_range))
        fonts_range = [2, 128]

    // font_settings: primero global (settings.json), luego capitulo
    // (chapter_settings.json). El de capitulo gana.
    var global_overrides = get_lang_setting("font_settings", undefined)
    if (!is_undefined(global_overrides) && is_struct(global_overrides) && variable_struct_exists(global_overrides, fnt_name)) {
        var ovr = variable_struct_get(global_overrides, fnt_name)
        if (is_struct(ovr)) {
            if (variable_struct_exists(ovr, "size"))
                fnt_size = variable_struct_get(ovr, "size")
            if (variable_struct_exists(ovr, "range"))
                fonts_range = variable_struct_get(ovr, "range")
        }
    }
    var chapter_overrides = get_chapter_lang_setting("font_settings", undefined)
    if (!is_undefined(chapter_overrides) && is_struct(chapter_overrides) && variable_struct_exists(chapter_overrides, fnt_name)) {
        var ovr = variable_struct_get(chapter_overrides, fnt_name)
        if (is_struct(ovr)) {
            if (variable_struct_exists(ovr, "size"))
                fnt_size = variable_struct_get(ovr, "size")
            if (variable_struct_exists(ovr, "range"))
                fonts_range = variable_struct_get(ovr, "range")
        }
    }

    var path = get_lang_folder_path() + "fonts/"
    var suffix = "_chapter" + string(global.chapter)
    var filename_ttf_chapter = ((path + fnt_name) + suffix) + ".ttf"
    var filename_otf_chapter = ((path + fnt_name) + suffix) + ".otf"
    var filename_ttf = (path + fnt_name) + ".ttf"
    var filename_otf = (path + fnt_name) + ".otf"

    var resolved_path = ""
    if (file_exists(filename_ttf_chapter))      resolved_path = filename_ttf_chapter
    else if (file_exists(filename_otf_chapter)) resolved_path = filename_otf_chapter
    else if (file_exists(filename_ttf))         resolved_path = filename_ttf
    else if (file_exists(filename_otf))         resolved_path = filename_otf

    // Asset built-in del juego: hereda bold/italic y sirve de fallback.
    var font = asset_get_index(fnt_name)

    if (resolved_path != "") {
        font = font_add(resolved_path, fnt_size, font_get_bold(font), font_get_italic(font), fonts_range[0], fonts_range[1])
        array_push(global.loaded_fonts, font)
    } else if ((asset_get_index(fnt_name + "_" + global.lang)) != -1) {
        font = asset_get_index(fnt_name + "_" + global.lang)
    }

    ds_map_add(global.font_map, fnt_name, font)
}
