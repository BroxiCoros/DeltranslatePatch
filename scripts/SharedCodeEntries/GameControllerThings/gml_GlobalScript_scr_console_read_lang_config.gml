// Lectura DIFERIDA de `true_config.ini` en consola.
//
// En Switch/PS4/PS5 `ossafe_ini_open` no toca el disco: lee de
// `global.savedata`, un ds_map que `obj_initializer2` rellena de forma
// ASÍNCRONA (`buffer_load_async` en su Create, mapa listo en su Other_72).
// El Create de `obj_gamecontroller` corre antes de que exista, así que allí
// no se puede leer nada persistido y el arranque se hace con los defaults.
//
// Este script recupera lo que faltaba en cuanto el mapa está disponible. Lo
// llama el Step de `obj_gamecontroller` (Draw_73 en el Menu) en cuanto existe
// el objeto que marca que la partida ya está cargada: `obj_time` en los
// capítulos, `obj_screen_start`/`obj_screen_select` en el Menu.
// Antes se seguía la transición de `global.savedata_async_load`; el upstream
// la abandonó en 5.2.2 porque tras un `game_restart()` la savedata sigue
// montada y ese flag ya no vuelve a bascular.
//
// Reaplica dos cosas:
//   1. El idioma que el jugador dejó elegido (`LANG_DT`). Si difiere del que
//      arrancó, se conmuta en caliente; `scr_switch_game_language` ya relee
//      por su cuenta el modo especial y las voces del idioma nuevo, así que
//      en ese camino no hace falta tocar nada más.
//   2. Si el idioma no cambia, el modo especial y las voces dobladas de ese
//      idioma (`special_mode_<lang>` / `translated_songs_<lang>`), con las
//      claves globales del upstream como fallback de migración, igual que en
//      el Create.
//
// Solo se puede llamar en consola y una única vez: los llamadores lo
// garantizan con `ld_load_state`.

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
    // scr_switch_game_language sale temprano si el objetivo coincide con `global.lang`,
    // y ahi `global.lang` puede ser justo el "en" del juego.
    global.lang = loaded
    global.lang_choice = target
    scr_switch_game_language(target)
}
