if global.translator_mode
{
    if keyboard_check_released(ord("U"))
        global.translator_mode = 0

    switch (speed_mode) {
        case (-1): room_speed = 1; break;
        case (1): room_speed = 120; break;
        case (2): room_speed = 360; break;
        case (0.25): room_speed = 7; break;
        default: room_speed = 30; break;
    }
        
    if keyboard_check_released(ord("F"))
    {
        if (speed_mode != 0) {
            speed_mode = 0
            room_speed = 30
        } else {
            speed_mode = 1
            if (keyboard_check(vk_shift)) {
                speed_mode = 2
            }
            if (keyboard_check(ord("0"))) {
                speed_mode = -1
            }
            if (keyboard_check(ord("A"))) {
                speed_mode = 0.25
            }
        }
    }

    if (keyboard_check_released(ord("S")) && (!instance_exists(obj_savemenu)))
        instance_create(0, 0, obj_savemenu)

    if keyboard_check_released(ord("L"))
        scr_load()

    if keyboard_check_released(ord("Q"))
        change_language()

    if keyboard_check_released(ord("R"))
    {
        scr_lang_load(true)
        update_on_room_end = true
    }

    if keyboard_check_released(ord("N"))
        room_goto_next()

    if keyboard_check_released(ord("P"))
        room_goto_previous()

    if keyboard_check_released(ord("G")) {
        var rm = get_string("New room?", room_get_name(room))
        if (room_exists(asset_get_index(rm))) {
            room_goto(asset_get_index(rm))
        } else {
            show_message("No such a room")
        }
    }

    if keyboard_check_released(ord("H")) {
        scr_healall(1000)
    }

    if (keyboard_check_pressed(ord("I")) && instance_exists(obj_writer))
    {
        with (obj_writer) {
            var true_orig = ds_map_find_value(global.lang_to_orig, origstring)
            if (true_orig == undefined) {
                true_orig = "| Original string not found |"
            }
            var new_string = get_string(true_orig, origstring);
            if (new_string != origstring && new_string != "") {
                obj_gamecontroller.add_new_translation(origstring, new_string)
                origstring = new_string
                mystring = origstring;
                pos = 2;
                formatted = 0;
                length = string_length(mystring);
                alarm[0] = 1;
            }
        }
    }
}
else if keyboard_check_released(ord("U"))
{
    // `get_lang_setting` mira el pack ACTIVO, que tras un cambio de idioma en
    // caliente puede no ser el del arranque. Por eso reservamos aquí el estado
    // del modo traductor (idempotente) antes de encender el flag: si el idioma
    // de arranque no traía `translator_mode` y el actual sí, los mapas no
    // existirían y `scr_get_lang_string` reventaría en el primer string.
    if get_lang_setting("translator_mode", 0)
    {
        init_translator_data()
        global.translator_mode = true
    }
}

// En consola el juego repone `global.lang` a "en" el solo cada vez que carga la
// savedata (`obj_init_console` -> `load_default_settings`), y eso pasa tambien en
// cada `room_restart`. Lo deshacemos aqui, que corre en todas las pantallas: si
// no, el menu de idioma escribe sus claves por idioma con el codigo equivocado
// (`translated_songs_en` en vez de `translated_songs_es_mx`) y la primera
// pulsacion de izquierda/derecha en "Language" se gasta en reparar el valor en
// vez de cambiar de idioma. `lang_choice` es la eleccion real del jugador.
if (variable_global_exists("is_console") && global.is_console
    && variable_global_exists("lang_choice") && global.lang != global.lang_choice)
{
    global.lang = global.lang_choice
}

// track how ossafe has loaded the player's slot on consoles
// (única divergencia con el upstream: la lectura del ini se delega en
// `scr_console_read_lang_config`, porque aquí las claves son por idioma y
// además hay que recuperar el idioma guardado)
if (global.is_console)
{
	if (ld_load_state == 0 && instance_exists(obj_time))
	{
		ld_load_state = 2
		if (ossafe_file_exists("true_config.ini"))
		{
			scr_console_read_lang_config()
		}
	}
}
