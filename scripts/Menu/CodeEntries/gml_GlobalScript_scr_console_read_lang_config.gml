// Lectura DIFERIDA de `true_config.ini` en consola (versión del Menu raíz).
// Ver el gemelo en `SharedCodeEntries/GameControllerThings/` para el porqué:
// en consola `ossafe_ini_open` lee de `global.savedata`, que se rellena de
// forma asíncrona y todavía no existe cuando corre el Create.
//
// Diferencia con el de capítulos: aquí el cambio de idioma en caliente es
// `change_language` (el Menu no tiene `scr_switch_game_language`, y su
// `change_language` sí hace lo que aquí necesitamos, a diferencia del de los
// capítulos, que alterna el modo traductor).
//
// Ojo: `change_language` persiste `LANG_DT` al final. Es reescribir el mismo
// valor que acabamos de leer, así que es inocuo.
//
// Lo llama el Draw_73 de `obj_gamecontroller` una única vez, cuando
// `ld_load_state` llega a 2.

function scr_console_read_lang_config() //gml_GlobalScript_scr_console_read_lang_config
{
    ossafe_ini_open("true_config.ini")
    var saved_lang = ini_read_string("LANG", "LANG_DT", "")
    ossafe_ini_close()

    // Idioma objetivo: el que el jugador dejo elegido. Si nunca eligio, el que
    // decidio el escaneo del Create. NUNCA el `global.lang` de este momento: en
    // consola vale "en" porque acaba de pisarlo `load_default_settings()` del
    // juego al cargar la savedata. Ver la guarda de `is_native_lang`.
    var target = saved_lang
    if (target == "" || !variable_global_exists("all_lang_settings")
        || !variable_struct_exists(global.all_lang_settings, target))
    {
        target = variable_global_exists("lang_scan_pick") ? global.lang_scan_pick : global.lang
    }

    // Con que idioma esta cargado el pack de verdad, que es lo unico fiable aqui.
    var loaded = variable_global_exists("lang_loaded") ? global.lang_loaded : global.lang

    if (target == loaded)
    {
        // Ya esta cargado el idioma bueno: solo hay que deshacer el "en" prestado
        // del juego y releer los ajustes de ese idioma.
        global.lang = target
        global.lang_choice = target

        ossafe_ini_open("true_config.ini")
        global.special_mode = ini_read_real("LANG", "special_mode_" + global.lang, ini_read_real("LANG", "special_mode", 0))
        global.translated_songs = ini_read_real("LANG", "translated_songs_" + global.lang, ini_read_real("LANG", "translated_songs", 1))
        ossafe_ini_close()
        exit;
    }

    // Hay que conmutar. Reponemos primero el idioma realmente cargado porque
    // change_language sale temprano si el objetivo coincide con `global.lang`,
    // y ahi `global.lang` puede ser justo el "en" del juego.
    global.lang = loaded
    global.lang_choice = target
    change_language(target)
}
