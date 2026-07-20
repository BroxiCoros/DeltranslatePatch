// Borra los streams del idioma anterior que quedaron en RAM tras un
// cambio de idioma en caliente. Espeja a `scr_cleanup_outdated_sprites`,
// pero con una diferencia clave: un stream de audio puede seguir
// sonando cruzando la transicion de sala (una voz de Flowery, un
// jingle). Destruirlo a mitad de reproduccion corta el sonido de golpe.
//
// Por eso, antes de `audio_destroy_stream`, comprobamos
// `audio_is_playing`: los que aun suenan se conservan en la lista y se
// reintentan en el siguiente cleanup; solo se destruyen los que ya
// callaron. `global.outdated_sounds` se rellena en
// `scr_switch_game_language` con los streams del idioma viejo.
//
// Nota: solo contiene streams creados con audio_create_stream (los que
// add_sound empuja a `loaded_sounds`); nunca assets vanilla, asi que
// audio_destroy_stream siempre recibe un stream valido.

function scr_cleanup_outdated_sounds() //gml_Script_scr_cleanup_outdated_sounds
{
    if (!variable_global_exists("outdated_sounds"))
        exit;

    var n = array_length(global.outdated_sounds)
    if (n == 0)
        exit;

    var still_playing = []
    for (var i = 0; i < n; i++)
    {
        var snd = global.outdated_sounds[i]
        if (audio_is_playing(snd))
            array_push(still_playing, snd)   // aun sonando: destruir en el proximo cleanup
        else
            audio_destroy_stream(snd)
    }

    global.outdated_sounds = still_playing
}
