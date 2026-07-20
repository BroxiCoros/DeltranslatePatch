function scr_init_localization()
{    
    if (!variable_global_exists("lang_loaded"))
    {
        global.lang_loaded = "";
        global.loaded_sprites = [];
        global.loaded_sounds = [];
        global.loaded_fonts = [];
    }
    
    if (global.lang_loaded != global.lang)
    {
        global.lang_loaded = global.lang;
        
        if (variable_global_exists("lang_map"))
        {
            for (var i = 0; i < array_length(global.loaded_sprites); i++)
                sprite_delete(global.loaded_sprites[i]);
            
            for (var i = 0; i < array_length(global.loaded_fonts); i++)
                font_delete(global.loaded_fonts[i]);
            
            for (var i = 0; i < array_length(global.loaded_sounds); i++)
                audio_destroy_stream(global.loaded_sounds[i]);
            
            ds_map_destroy(global.lang_map);
            ds_map_destroy(global.font_map);
            ds_map_destroy(global.chemg_sprite_map);
            ds_map_destroy(global.chemg_sound_map);
            global.chapter_lang_settings = {};
            global.loaded_sprites = [];
            global.loaded_sounds = [];
            global.loaded_fonts = [];
        }
        
        global.chapter_lang_settings = scr_load_json(get_lang_folder_path() + "chapter4/chapter_settings.json");
        global.font_map = ds_map_create();
        global.lang_missing_map = ds_map_create();
        global.chemg_sprite_map = ds_map_create();
        global.chemg_sound_map = ds_map_create();
        font_add_enable_aa(false);
        
        for (var i = 0; i < array_length(global.fonts_list); i++)
            add_font(global.fonts_list[i][0], global.fonts_list[i][1]);
        
        if (is_undefined(ds_map_find_value(global.font_map, "fnt_main_mono")) || ds_map_find_value(global.font_map, "fnt_main_mono") == -1)
            ds_map_set(global.font_map, "fnt_main_mono", ds_map_find_value(global.font_map, "fnt_main"));
        
        if (is_undefined(ds_map_find_value(global.font_map, "fnt_mainbig_mono")) || ds_map_find_value(global.font_map, "fnt_mainbig_mono") == -1)
            ds_map_set(global.font_map, "fnt_mainbig_mono", ds_map_find_value(global.font_map, "fnt_mainbig"));
        
        if (is_undefined(ds_map_find_value(global.font_map, "fnt_8bit_mixed")) || ds_map_find_value(global.font_map, "fnt_8bit_mixed") == -1)
            ds_map_set(global.font_map, "fnt_8bit_mixed", ds_map_find_value(global.font_map, "fnt_8bit"));
        
        if (is_undefined(ds_map_find_value(global.font_map, "fnt_legend_alt")) || ds_map_find_value(global.font_map, "fnt_legend_alt") == -1)
            ds_map_set(global.font_map, "fnt_legend_alt", ds_map_find_value(global.font_map, "fnt_legend"));
        
        // El loop de sprites se salta cuando hay una recarga de idioma en
        // caliente pendiente: los sprites se difieren y los carga
        // `scr_load_lang_sprites_only`. En el boot (pending = false) se
        // cargan normalmente aqui.
        if (!(variable_global_exists("lang_sprites_pending") && global.lang_sprites_pending))
        {
            for (var i = 0; i < array_length(global.sprites_list); i++)
                add_sprite(global.sprites_list[i]);

            // Sprites adicionales declarados por el pack para esta lengua.
            var additional_funny_words = get_chapter_lang_setting("additional_funny_words", []);
            for (var i = 0; i < array_length(additional_funny_words); i++)
                add_sprite(additional_funny_words[i]);
        }
        
        var additional_funny_words = get_chapter_lang_setting("additional_funny_words", []);
        
        for (var i = 0; i < array_length(additional_funny_words); i++)
            add_sprite(additional_funny_words[i]);
        
        // Sonidos diferidos: en el boot se cargan aqui; en un cambio de
        // idioma en caliente el loop se salta (pending) y los carga
        // `scr_load_lang_sounds_only` de forma perezosa. El loader se
        // registra siempre para que el codigo compartido pueda invocarlo.
        global.lang_sounds_loader = scr_load_lang_sounds_only;
        if (!(variable_global_exists("lang_sounds_pending") && global.lang_sounds_pending))
            scr_load_lang_sounds_only();

        global.lang_map = ds_map_create();
        scr_lang_load();
        scr_ascii_input_names();
    }
}

// Carga (o recarga) los streams de sonido del idioma activo al
// `chemg_sound_map`. Contiene el bloque de sonidos especifico del Cap.4
// (sounds_list + funny sounds). Lo llaman `scr_init_localization` (boot)
// y `scr_apply_pending_sound_reload` (recarga diferida tras un cambio de
// idioma en caliente).
function scr_load_lang_sounds_only()
{
    if (variable_global_exists("chemg_sound_map"))
        ds_map_clear(global.chemg_sound_map);
    else
        global.chemg_sound_map = ds_map_create();

    for (var i = 0; i < array_length(global.sounds_list); i++)
        add_sound(global.sounds_list[i]);

    var additional_funny_sounds = get_chapter_lang_setting("additional_funny_sounds", []);
    for (var i = 0; i < array_length(additional_funny_sounds); i++)
        add_sound(additional_funny_sounds[i]);
}
