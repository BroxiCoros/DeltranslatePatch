// La R reiniciaba la sala SIEMPRE, lo que tenía dos problemas:
//   1) Permitía a cualquier jugador hacerlo aunque el modo traductor
//      no estuviera activo (R es feature de dev/translator, igual que
//      en obj_gamecontroller_Step_0 de los capítulos).
//   2) `room_restart()` no detiene los audios en curso, así que las
//      instancias de música en loop (BGM del menú con AUDIO_DRONE,
//      BGM del capítulo) seguían sonando mientras los objetos
//      recreados arrancaban su propia copia → música duplicada.
//
// Fix: gateamos por `global.translator_mode` (con `variable_global_exists`
// porque en el menú principal esa global puede no estar inicializada),
// y antes del `room_restart()` paramos todos los audios.
if (keyboard_check_released(ord("R"))
    && variable_global_exists("translator_mode")
    && global.translator_mode) {
    audio_stop_all()
    room_restart()
}

if (down_p()) {
    option = (option + 1) % (options_count + 1)
    audio_play_sound(snd_menumove, 50, 0)
}

if (up_p()) {
    option = (option + options_count) % (options_count + 1)
    audio_play_sound(snd_menumove, 50, 0)
}

if (option < options_count) {
    if (options[option] == "language") {
        var langs_count = get_lang_count()

        // Cicla entre los idiomas disponibles con ←/→, siempre que
        // haya más de uno. `change_language` recarga todo (strings,
        // sprites, sonidos, fuentes, modos especiales) y persiste
        // la elección en `true_config.ini`.
        if (langs_count > 1 && (left_p() || right_p())) {
            var cur_idx = 0
            for (var k = 0; k < langs_count; k++) {
                if (global.languages_list[k] == global.lang) {
                    cur_idx = k
                    break
                }
            }
            if (left_p())
                cur_idx = ((cur_idx - 1) + langs_count) mod langs_count
            else
                cur_idx = (cur_idx + 1) mod langs_count

            change_language(global.languages_list[cur_idx])
            update_strings()
            audio_play_sound(snd_menumove, 50, 0)
        }
        else if (button1_p()) {
            // Comportamiento original: abrir link del pack si existe.
            var link = get_lang_setting("link", "")
            if (link != "") {
                audio_play_sound(snd_menumove, 50, 0)
                url_open(link)
            }
        }
    } else

    if (options[option] == "special_mode") {
        // El ring ahora es directamente el tamaño del array, porque el
        // default ocupa la posición 0 dentro de `global.special_modes`.
        // Necesitamos al menos 2 entradas (default + ≥1 modo) para
        // tener algo que ciclar.
        var modes_len = array_length(global.special_modes)

        if (modes_len > 1 && (left_p() || right_p() || button1_p())) {
            if (left_p()) {
                global.special_mode_index = ((global.special_mode_index - 1) + modes_len) mod modes_len
            } else {
                global.special_mode_index = (global.special_mode_index + 1) mod modes_len
            }

            // Globales derivadas para que el resto del juego use el modo nuevo.
            global.special_mode = (global.special_mode_index > 0)
            global.active_sp_prefix = get_struct_field(global.special_modes[global.special_mode_index], "prefix", "")

            ossafe_ini_open("true_config.ini")
            // Clave nueva, por idioma: cada lang recuerda su modo.
            ini_write_string("LANG", "special_mode_index_" + global.lang, global.special_mode_index)
            // Clave global (compat con la versión inicial del mod modificado).
            ini_write_string("LANG", "special_mode_index", global.special_mode_index)
            // Clave heredada bool 0/1 (compat con el mod original).
            ini_write_string("LANG", "special_mode", global.special_mode ? 1 : 0)
            ossafe_ini_close()
            ossafe_savedata_save()

            audio_play_sound(snd_menumove, 50, 0)
        }
    } else

    if (options[option] == "enable_translated_songs_switch") {
        if (left_p() || right_p() || button1_p()) {
            ossafe_ini_open("true_config.ini")
            global.translated_songs = !global.translated_songs
            ini_write_string("LANG", "translated_songs", global.translated_songs)
            ossafe_ini_close()
            ossafe_savedata_save()

            audio_play_sound(snd_menumove, 50, 0)
        }
    }
} else

if (option == options_count && button1_p()) {
    audio_play_sound(snd_menumove, 50, 0)
    room_restart()
}
