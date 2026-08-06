// ¿El idioma indicado (o el activo) es uno de los NATIVOS del juego?
//
// Los idiomas nativos (inglés y japonés) no tienen carpeta en `lang/`: sus
// strings, sprites, sonidos y fuentes ya viven dentro del data.win, y el
// propio juego trae el código que los carga (`scr_84_init_localization`).
// `scan_languages()` los inyecta en `global.languages_list` con el flag
// `native: true` en su settings, y este helper es el que consulta el resto
// del mod para saber que debe apartarse y dejar trabajar al juego.
//
// Si un pack de `lang/` declara el mismo `lang_code`, el pack gana y esta
// función devuelve false para ese código: quien instala un pack "en" quiere
// su pack, no el inglés de fábrica.
function is_native_lang(argument0) //gml_Script_is_native_lang
{
    var code = argument0
    if (is_undefined(code))
    {
        if (!variable_global_exists("lang"))
            return false
        code = global.lang
    }

    if (!variable_global_exists("all_lang_settings"))
        return false

    if (!variable_struct_exists(global.all_lang_settings, code))
        return false

    return get_struct_field(variable_struct_get(global.all_lang_settings, code), "native", false) == true
}
