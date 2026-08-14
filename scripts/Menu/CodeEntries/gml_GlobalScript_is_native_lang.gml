// Copia de `SharedCodeEntries/Misc/gml_GlobalScript_is_native_lang.gml`: el
// menú raíz no comparte esa carpeta (ver el "Дичайший костыль" de BaseFix), así
// que sus funciones van duplicadas aquí, como el resto de las suyas.
//
// ¿El idioma indicado (o el activo) es uno de los NATIVOS del juego?
//
// En el menú raíz esto es todavía más directo que en los capítulos: aquí no hay
// sistema de localización ninguno (`scr_84_init_localization` no existe), el
// juego lleva el inglés y el japonés incrustados en ternarios
// `(global.lang == "en") ? "Chapter Select" : "チャプター選択"` y elige la fuente
// por id (`_font = (global.lang == "en") ? 2 : 1`). O sea que basta con que
// `global.lang` valga "en"/"ja" y con que corra el código original: de eso se
// encarga el gemelo vanilla que monta BaseFix.
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
