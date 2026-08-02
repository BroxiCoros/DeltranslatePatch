// Carga una fuente del pack (Menu raiz). Soporta `font_settings` global
// (settings.json) para override de tamano/rango. El Menu no tiene numero
// de capitulo, asi que NO usa el sufijo `_chapterN` (eso es de capitulos).
//
// Nombre alternativo (`scr_letter_fix`): en consola los ficheros del pack no
// pueden llevar caracteres no ASCII, asi que se guardan con el `ord()` de cada
// uno. Se prueba primero el alternativo y luego el literal; en nombres ASCII
// (el caso normal) ambos coinciden.
//
// Temporales como `var` (locales) a proposito, por consistencia con el
// add_font de capitulos (evita pisar variables de instancia del llamador).

function add_font(argument0, argument1) //gml_Script_add_font
{
    var fnt_name = argument0
    var fnt_name_alt = scr_letter_fix(fnt_name)
    var fnt_size = argument1
    var fonts_range = get_lang_setting("fonts_range", [32, 128])

    // Override por fuente desde settings.json -> font_settings.<fnt_name>.
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

    var path = get_lang_folder_path() + "fonts/"
    var filename_ttf = ((path + fnt_name) + ".ttf")
    var filename_otf = ((path + fnt_name) + ".otf")
    var filename_ttf_alt = ((path + fnt_name_alt) + ".ttf")
    var filename_otf_alt = ((path + fnt_name_alt) + ".otf")
    var font = asset_get_index(fnt_name)
    if scr_file_exists(filename_ttf_alt)
        font = font_add(filename_ttf_alt, fnt_size, font_get_bold(font), font_get_italic(font), fonts_range[0], fonts_range[1])
    else if scr_file_exists(filename_otf_alt)
        font = font_add(filename_otf_alt, fnt_size, font_get_bold(font), font_get_italic(font), fonts_range[0], fonts_range[1])
    else if scr_file_exists(filename_ttf)
        font = font_add(filename_ttf, fnt_size, font_get_bold(font), font_get_italic(font), fonts_range[0], fonts_range[1])
    else if scr_file_exists(filename_otf)
        font = font_add(filename_otf, fnt_size, font_get_bold(font), font_get_italic(font), fonts_range[0], fonts_range[1])
    else if ((asset_get_index(fnt_name_alt + "_" + global.lang)) != -1)
        font = asset_get_index(fnt_name_alt + "_" + global.lang)
    else if ((asset_get_index(fnt_name + "_" + global.lang)) != -1)
        font = asset_get_index(fnt_name + "_" + global.lang)
    ds_map_add(global.font_map, fnt_name, font)
}
