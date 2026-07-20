// Aplica una recarga de sonidos diferida (lazy reload). Espeja a
// `scr_apply_pending_sprite_reload`, pero delega la carga real en el
// `lang_sounds_loader` que registra cada capitulo, porque el bloque de
// sonidos es especifico de cada uno (button sounds en Ch2/3, funny
// sounds en Ch3/4, voicelines + flowery en Ch5). Por eso NO se puede
// usar una funcion compartida unica como con los sprites.
//
// Se dispara en dos lugares:
//   1. Al inicio de `scr_84_get_sound`: si algun objeto pide un sonido
//      tras un cambio de idioma, los streams se cargan antes de
//      devolverlo (evita entregar el asset ingles del idioma viejo).
//   2. En el Step de `obj_gamecontroller` al detectar cambio de sala.
//
// Es idempotente: si no hay reload pendiente, no hace nada. En el Menu
// (que no carga sonidos) `lang_sounds_loader` no existe y sale sin tocar
// nada.

function scr_apply_pending_sound_reload() //gml_Script_scr_apply_pending_sound_reload
{
    if (!variable_global_exists("lang_sounds_pending"))
        exit;
    if (!global.lang_sounds_pending)
        exit;

    // Marcar como aplicado *antes* de cargar, para evitar recursion:
    // el loader llama a add_sound, que no consulta scr_84_get_sound.
    global.lang_sounds_pending = false

    if (variable_global_exists("lang_sounds_loader"))
        global.lang_sounds_loader()
}
