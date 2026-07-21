// Cambia el idioma activo DENTRO de un capítulo, sin reiniciar la sala.
//
// No se puede reusar `change_language` en los capítulos porque esa
// función ya existe y hace otra cosa completamente distinta: alterna
// `global.orig_en` (el "modo traductor" que compara el texto con el
// original en inglés). Por eso aquí se define una función nueva.
//
// Estrategia: reutilizamos `scr_init_localization` pero difiriendo la
// parte pesada (los ~120-300 sprites y los streams de sonido del capítulo,
// ~100 clips de voz en el Cap.5):
//
//   1. Recarga inmediata de fuentes y strings vía `scr_init_localization`.
//      Los loops de sprites y de sonidos de `init` estan guardados por
//      `global.lang_sprites_pending` / `global.lang_sounds_pending`, asi
//      que NO se recargan ni sprites ni sonidos aqui (se difieren).
//   2. Un diferido de sprites y otro de sonidos: los recursos del idioma
//      viejo se mueven a `global.outdated_sprites` / `global.outdated_sounds`,
//      y se marcan los flags de pendiente. La carga real del idioma nuevo
//      se dispara de forma perezosa cuando algún objeto pide un sprite
//      (`scr_84_get_sprite`) o un sonido (`scr_84_get_sound`), o al cambiar
//      de sala (detector en el Step de `obj_gamecontroller`).
//   3. Tras cambiar de sala, los sprites viejos se borran con
//      `scr_cleanup_outdated_sprites` y los streams viejos con
//      `scr_cleanup_outdated_sounds`. Los sprites persistentes que aún
//      tuvieran sprite_index a un sprite viejo no deberían existir (la
//      lista incluye solo props/UI/batalla, no Kris/etc.). Los streams que
//      aún estén sonando NO se destruyen: se conservan para el siguiente
//      cleanup (guard `audio_is_playing`), evitando cortar una voz a mitad.
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

    // ----- Defer sonidos: misma estrategia que los sprites -----
    // Los streams del idioma viejo se preservan en `outdated_sounds`
    // (siguen sonando si una voz estaba en curso) y se borran despues,
    // en `scr_cleanup_outdated_sounds`, cuando ya no se reproducen.
    if (!variable_global_exists("outdated_sounds"))
        global.outdated_sounds = []
    if (variable_global_exists("loaded_sounds"))
    {
        for (var i = 0; i < array_length(global.loaded_sounds); i++)
            array_push(global.outdated_sounds, global.loaded_sounds[i])
    }
    global.loaded_sounds = []

    // Marcar reload de sonidos pendiente. La carga real (los ~100
    // `audio_create_stream`) se difiere al primer `scr_84_get_sound` o al
    // cambio de sala, igual que los sprites.
    global.lang_sounds_pending = true

    // ----- Recarga inmediata de fuentes y strings -----
    // Reutilizamos `scr_init_localization`. Los sprites y los sonidos NO
    // se recargan aqui: sus loops en `init` estan guardados por los flags
    // `lang_sprites_pending` / `lang_sounds_pending`, asi que se difieren
    // y los cargan `scr_load_lang_sprites_only` / el `lang_sounds_loader`
    // del capitulo despues.
    scr_init_localization()

    // Persistir la elección para próximas sesiones y para que el menú
    // principal arranque en el mismo idioma.
    ossafe_ini_open("true_config.ini")
    ini_write_string("LANG", "LANG_DT", global.lang)
    ossafe_ini_close()
    ossafe_savedata_save()
}
