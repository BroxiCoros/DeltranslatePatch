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

    var can_switch = saved_lang != "" && saved_lang != global.lang &&
        variable_global_exists("all_lang_settings") &&
        variable_struct_exists(global.all_lang_settings, saved_lang)

    if (can_switch)
    {
        change_language(saved_lang)
        exit;
    }

    ossafe_ini_open("true_config.ini")
    global.special_mode = ini_read_real("LANG", "special_mode_" + global.lang, ini_read_real("LANG", "special_mode", 0))
    global.translated_songs = ini_read_real("LANG", "translated_songs_" + global.lang, ini_read_real("LANG", "translated_songs", 1))
    ossafe_ini_close()
}
