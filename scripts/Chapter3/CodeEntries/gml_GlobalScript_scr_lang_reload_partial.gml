// AUTOGENERADO por tools/regen_localization.csx desde scripts/Chapter3/manifest.json.
// NO editar a mano: cualquier cambio se sobrescribira en la proxima regeneracion.
//
// Recarga parcial del idioma activo: fuentes, sonidos y strings.
// Llamada desde scr_switch_game_language para cambiar de idioma SIN
// recargar sprites en el mismo frame (los sprites se difieren a
// scr_load_lang_sprites_only).

function scr_lang_reload_partial()
{
    var fonts_list  = [
        ["fnt_main", 12],
        ["fnt_mainbig", 24],
        ["fnt_tinynoelle", 7],
        ["fnt_dotumche", 12],
        ["fnt_comicsans", 10],
        ["fnt_small", 6],
        ["fnt_8bit", 12],
        ["fnt_8bit_mixed", 12],
        ["fnt_main_mono", 12]
    ];
    var sounds_list = ["AUDIO_INTRONOISE", "ch2_credits", "snd_joker_laugh0", "snd_its_tv_time", "snd_smashreveal"];
    var songs_list  = ["AUDIO_INTRONOISE", "ch2_credits", "snd_joker_laugh0", "snd_its_tv_time", "snd_smashreveal"];

    // ----- Borrar fonts viejas -----
    if (variable_global_exists("loaded_fonts"))
    {
        for (var i = 0; i < array_length(global.loaded_fonts); i++)
            font_delete(global.loaded_fonts[i]);
    }
    global.loaded_fonts = [];
    if (variable_global_exists("font_map"))
        ds_map_destroy(global.font_map);
    global.font_map = ds_map_create();

    // ----- Borrar sounds viejos -----
    if (variable_global_exists("loaded_sounds"))
    {
        for (var i = 0; i < array_length(global.loaded_sounds); i++)
            audio_destroy_stream(global.loaded_sounds[i]);
    }
    global.loaded_sounds = [];
    if (variable_global_exists("chemg_sound_map"))
        ds_map_destroy(global.chemg_sound_map);
    global.chemg_sound_map = ds_map_create();

    // ----- Borrar strings viejos -----
    if (variable_global_exists("lang_map"))
        ds_map_destroy(global.lang_map);

    // chapter_lang_settings puede contener listas (additional_funny_*) que
    // difieren entre packs; lo recargamos antes de reabrir las fuentes.
    global.chapter_lang_settings = scr_load_json(get_lang_folder_path() + "chapter3/chapter_settings.json");

    font_add_enable_aa(false);

    // ----- Recargar fonts (lazy: solo fnt_main eagerly) -----
    // Carga lazy: fnt_main es la unica fuente visible en los menus
    // previos a partida (DEVICE_MENU, obj_lang_settings). El resto se
    // difiere a global.font_pending_map y se rasteriza la primera vez
    // que alguien la pida (tipicamente despues del loading screen, ya
    // dentro de gameplay). Combinado con global.font_cache en add_font,
    // los cambios sucesivos al mismo idioma cuestan ~0ms.
    if (variable_global_exists("font_pending_map"))
        ds_map_destroy(global.font_pending_map);
    global.font_pending_map = ds_map_create();
    for (var i = 0; i < array_length(fonts_list); i++)
    {
        var _fname = fonts_list[i][0];
        var _fsize = fonts_list[i][1];
        if (_fname == "fnt_main")
            add_font(_fname, _fsize);
        else
            ds_map_add(global.font_pending_map, _fname, _fsize);
    }

    // Tabla de aliases de fuente. La resolucion ocurre en
    // scr_84_get_font / scr_get_font: si la fuente alias no tiene handle
    // valido (archivo ausente, lazy load fallido), se sirve la objetivo.
    // Si el pack provee la fuente alias como archivo, se carga normal.
    if (variable_global_exists("font_alias_targets"))
        ds_map_destroy(global.font_alias_targets);
    global.font_alias_targets = ds_map_create();
    ds_map_add(global.font_alias_targets, "fnt_main_mono", "fnt_main");
    ds_map_add(global.font_alias_targets, "fnt_8bit_mixed", "fnt_8bit");

    // ----- Recargar sounds -----
    global.songs_list = songs_list;
    for (var i = 0; i < array_length(sounds_list); i++)
        add_sound(sounds_list[i]);

    // Sonidos de botones: simbolos configurados en el pack (default = alfanumericos + !?).
    sound_symbols = get_chapter_lang_setting("button_sounds_symbols", ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "!", "?"]);
    set_chapter_lang_setting("button_sounds_symbols", sound_symbols);

    // Carga snd_speak_and_spell_X para cada simbolo configurado.
    for (var i = 0; i < array_length(sound_symbols); i++)
        add_sound("snd_speak_and_spell_" + sound_symbols[i], 1);

    // Sonidos adicionales declarados por el pack para esta lengua.
    var additional_funny_sounds = get_chapter_lang_setting("additional_funny_sounds", []);
    for (var i = 0; i < array_length(additional_funny_sounds); i++)
        add_sound(additional_funny_sounds[i]);

    // ----- Recargar strings -----
    global.lang_map = ds_map_create();
    scr_lang_load();
    scr_ascii_input_names();

    // Strings/fonts/sonidos listos. Sprites siguen pendientes:
    // los maneja global.lang_sprites_pending por separado.
    global.lang_loaded = global.lang;
}
