if (global.translator_mode) {
    if (update_on_room_end) {
        update_on_room_end = false
        global.lang_loaded = ""
        scr_init_localization()
    }

    ds_map_clear(global.changed_strings)
    ds_map_clear(global.used_room_strings)
    ds_map_clear(global.lang_to_orig)
    ds_map_clear(global.orig_to_lang)
}