// Cambia el idioma activo DENTRO de un capítulo, sin reiniciar la sala.
//
// No se puede reusar `change_language` en los capítulos porque esa
// función ya existe y hace otra cosa completamente distinta: alterna
// `global.orig_en` (el "modo traductor" que compara el texto con el
// original en inglés). Por eso aquí se define una función nueva.
//
// Diferencia respecto a versiones anteriores: en lugar de llamar a
// `scr_init_localization` (que recarga TODO de una vez, incluyendo
// los ~120-300 sprites del capítulo), aquí hacemos:
//
//   1. Una recarga parcial inmediata (`scr_lang_reload_partial`) que
//      cubre fuentes, sonidos y strings. Estos cambian al instante.
//   2. Un diferido de sprites: los del idioma viejo se mueven al array
//      `global.outdated_sprites`, y se marca un flag
//      `global.lang_sprites_pending`. La carga real de los sprites del
//      idioma nuevo se dispara cuando algún objeto pide un sprite
//      (lazy, vía `scr_84_get_sprite`) o cuando se cambie de sala
//      (vía detector en el Step de `obj_gamecontroller`).
//   3. Tras cambiar de sala, los sprites viejos se borran con
//      `scr_cleanup_outdated_sprites`. Los persistentes que aún
//      tuvieran sprite_index a un sprite viejo no deberían existir,
//      ya que la lista incluye solo props/UI/batalla, no Kris/etc.
//
// No toca `global.orig_en` ni el modo traductor: son variables de
// gameplay independientes del idioma.

function scr_switch_game_language(argument0) //gml_Script_scr_switch_game_language
{
    var target_lang = argument0
    if (target_lang == global.lang) {
        exit;
    }

    global.lang = target_lang

    // Usar la caché si el Create del gamecontroller ya escaneó todos
    // los idiomas; si no (por seguridad), leer del disco.
    if (variable_global_exists("all_lang_settings") && variable_struct_exists(global.all_lang_settings, target_lang))
    {
        global.lang_settings = variable_struct_get(global.all_lang_settings, target_lang)
    }
    else
    {
        var settings_path = get_lang_folder_path() + "settings.json"
        if (file_exists(settings_path))
            global.lang_settings = scr_load_json(settings_path)
    }

    // Recargar modos especiales (pueden ser distintos en cada pack).
    scr_load_special_modes()

    // ----- Defer sprites: trasladar los actuales a outdated_sprites -----
    // Pueden encadenarse varios cambios de idioma sin pasar de sala;
    // por eso concatenamos en lugar de sobrescribir.
    if (!variable_global_exists("outdated_sprites"))
        global.outdated_sprites = []
    if (variable_global_exists("loaded_sprites"))
    {
        for (var i = 0; i < array_length(global.loaded_sprites); i++)
            array_push(global.outdated_sprites, global.loaded_sprites[i])
    }
    global.loaded_sprites = []

    // Marcar reload pendiente. La carga real ocurre en el primer
    // `scr_84_get_sprite` o en el Step del gamecontroller al detectar
    // cambio de sala.
    global.lang_sprites_pending = true

    // ----- Recarga inmediata de fuentes, sonidos y strings -----
    scr_lang_reload_partial()

    // Persistir la elección para próximas sesiones y para que el menú
    // principal arranque en el mismo idioma.
    ossafe_ini_open("true_config.ini")
    ini_write_string("LANG", "LANG_DT", global.lang)
    ossafe_ini_close()
    ossafe_savedata_save()
}
