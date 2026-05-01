// Hook para el sistema de cambio de idioma en caliente:
// detectamos cambios de sala y, si hay un reload de sprites pendiente,
// lo aplicamos AHORA (por si nadie llamó a scr_84_get_sprite todavía
// en la sala nueva, lo cual ocurre si los Creates de los objetos
// se ejecutan antes de que algún script pida un sprite traducido).
// Después limpiamos los sprites del idioma viejo: en este punto los
// objetos de la sala anterior ya se destruyeron, por lo que es seguro
// hacer sprite_delete sobre ellos.
if (variable_global_exists("lang_sprites_pending")) {
    if (!variable_instance_exists(self, "last_room_for_lang"))
        last_room_for_lang = room
    if (room != last_room_for_lang) {
        last_room_for_lang = room
        if (global.lang_sprites_pending)
            scr_apply_pending_sprite_reload()
        scr_cleanup_outdated_sprites()
    }
}

// ----- Bloque original del mod base (modo traductor) -----
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

    if keyboard_check_released(ord("H")) {
        scr_healall(1000)
    }
}
else if keyboard_check_released(ord("U"))
{
    if get_lang_setting("translator_mode", 0)
        global.translator_mode = true
}
