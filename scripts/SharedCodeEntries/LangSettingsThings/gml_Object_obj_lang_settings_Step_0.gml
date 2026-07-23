// La R reiniciaba la sala SIEMPRE, con dos problemas:
//   1) Cualquier jugador podía hacerlo aunque el modo traductor no
//      estuviera activo (R es feature de dev, igual que en
//      obj_gamecontroller_Step_0).
//   2) `room_restart()` no detiene los audios en curso, así que la BGM
//      en loop seguía sonando mientras los objetos recreados arrancaban
//      su propia copia → música duplicada.
// Fix: gate por `global.translator_mode` + `audio_stop_all()` antes.
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

        // Con varios idiomas, ←/→ cicla y cambia de idioma en caliente.
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

            scr_switch_game_language(global.languages_list[cur_idx])
            update_strings()
            audio_play_sound(snd_menumove, 50, 0)
        }
        else if (button1_p()) {
            var link = get_lang_setting("link", "")
            if (link != "") {
                audio_play_sound(snd_menumove, 50, 0)
                url_open(link)
            }
        }
    } else

    if (options[option] == "special_mode") {
        if (left_p() || right_p() || button1_p()) {
            ossafe_ini_open("true_config.ini")
            global.special_mode = !global.special_mode
            // Clave por idioma: cada pack recuerda su propio estado.
            ini_write_string("LANG", "special_mode_" + global.lang, global.special_mode)
            ossafe_ini_close()
            ossafe_savedata_save()

            audio_play_sound(snd_menumove, 50, 0)
        }
    } else

    if (options[option] == "enable_translated_songs_switch") {
        if (left_p() || right_p() || button1_p()) {
            ossafe_ini_open("true_config.ini")
            global.translated_songs = !global.translated_songs
            // Clave por idioma: cada pack recuerda su propio estado.
            ini_write_string("LANG", "translated_songs_" + global.lang, global.translated_songs)
            ossafe_ini_close()
            ossafe_savedata_save()

            audio_play_sound(snd_menumove, 50, 0)
        }
    }
}

if ((option == options_count && button1_p()) || keyboard_check_pressed(vk_shift)) {
    audio_play_sound(snd_menumove, 50, 0)
    instance_activate_object(DEVICE_MENU)
    with (DEVICE_MENU) {
        if (ossafe_file_exists("dr.ini")) {
            ossafe_ini_open("dr.ini");
            for (i = 0; i < 3; i += 1) {
                if (FILE[i] == 1) {
                    var room_id = ini_read_real(scr_ini_chapter(global.chapter, i), "Room", scr_get_id_by_room_index(room));
                    var room_index = scr_get_room_by_id(room_id);
                    PLACE[i] = scr_roomname(room_index);
                }
            }
        }
    }

    DEVICE_MENU.BG_SINER = BG_SINER
    DEVICE_MENU.OB_DEPTH = OB_DEPTH
    DEVICE_MENU.obacktimer = obacktimer
    DEVICE_MENU.OBM = OBM
    DEVICE_MENU.COL_A = COL_A
    DEVICE_MENU.COL_B = COL_B
    DEVICE_MENU.COL_PLUS = COL_PLUS
    
    // Simetrico al Create: con la UI verde (sin partidas) DEVICE_MENU no tiene
    // estas variables y no las usa, asi que no se las devolvemos.
    if (SUBTYPE == 1) {
        DEVICE_MENU.BGSINER = BGSINER
        DEVICE_MENU.BGMAGNITUDE = BGMAGNITUDE
        DEVICE_MENU.ANIM_SINER = ANIM_SINER
        DEVICE_MENU.ANIM_SINER_B = ANIM_SINER_B
        DEVICE_MENU.TRUE_ANIM_SINER = TRUE_ANIM_SINER
    }
    DEVICE_MENU.COL_A = COL_A
    DEVICE_MENU.COL_B = COL_B
    DEVICE_MENU.COL_PLUS = COL_PLUS
    BGMADE = 1
    DEVICE_MENU.BG_ALPHA = BG_ALPHA
    if (SUBTYPE == 0) {
        DEVICE_MENU.COL_A = COL_A
        DEVICE_MENU.COL_B = COL_B
        DEVICE_MENU.COL_PLUS = COL_PLUS
        BGMADE = 0
    }

    instance_destroy(self)
}