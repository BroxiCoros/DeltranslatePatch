// ¿El idioma indicado (o el activo) es uno de los NATIVOS del juego?
//
// Los idiomas nativos (inglés y japonés) no tienen carpeta en `lang/`: sus
// strings, sprites, sonidos y fuentes ya viven dentro del data.win, y el
// propio juego trae el código que los carga (`scr_84_init_localization`).
// `scan_languages()` los inyecta en `global.languages_list` con el flag
// `native: true` en su settings, y este helper es el que consulta el resto
// del mod para saber que debe apartarse y dejar trabajar al juego.
//
// Un pack instalado en `lang/en/` gana y esta función devuelve false para ese
// código: quien lo instala quiere su pack, no el inglés de fábrica. Manda la
// carpeta: un pack en `lang/english/` que declare `"lang_code": "en"` no
// suprime el inglés nativo.
function is_native_lang(argument0) //gml_Script_is_native_lang
{
    var code = argument0
    var implicito = is_undefined(code)
    if (implicito)
    {
        if (!variable_global_exists("lang"))
            return false
        code = global.lang
    }

    // En consola `global.lang` NO dice lo que el jugador eligio: el juego lo pone
    // a "en" el solo cada vez que carga la savedata (`obj_init_console` ->
    // `load_default_settings`), y eso pasa en el arranque Y en cada
    // `room_restart()` del selector. Ademas el `LANG` del true_config.ini vale
    // "en" para quien no haya tocado el menu de idioma del juego base: el mod
    // guarda el suyo en `LANG_DT`. Asi que aqui solo nos fiamos de nuestra propia
    // eleccion, `global.lang_choice`, hasta que el hook diferido reponga
    // `global.lang`. Sin esta guarda el selector entraba en modo nativo con el
    // pack cargado por debajo y el proceso abortaba (pantalla negra en Switch).
    if (implicito && variable_global_exists("is_console") && global.is_console)
    {
        if (!variable_global_exists("lang_choice") || code != global.lang_choice)
            return false
    }

    if (!variable_global_exists("all_lang_settings"))
        return false

    if (!variable_struct_exists(global.all_lang_settings, code))
        return false

    return get_struct_field(variable_struct_get(global.all_lang_settings, code), "native", false) == true
}
