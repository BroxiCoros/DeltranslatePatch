function scr_init_localization()
{    
    if (!variable_global_exists("lang_loaded"))
    {
        global.lang_loaded = "";
        global.loaded_sprites = [];
        global.loaded_sounds = [];
        global.loaded_fonts = [];
    }
    
    // ---------------------------------------------------------------
    // Idiomas NATIVOS del juego (inglés / japonés): apartarse
    // ---------------------------------------------------------------
    // No hay pack que cargar. El juego trae su propio inicializador de
    // localización, `scr_84_init_localization`, que el mod NO reemplaza y
    // que hoy es código muerto. Rellena exactamente los mismos tres mapas
    // que consultan los resolvedores del mod:
    //
    //   global.font_map          -> fnt_ja_main, fnt_ja_dotumche, ...
    //   global.chemg_sprite_map  -> "spr_quitmessage" -> spr_ja_quitmessage, ...
    //   global.chemg_sound_map   -> "snd_joker_chaos" -> snd_joker_chaos_ja, ...
    //
    // y carga los strings con `scr_84_lang_load()` desde el
    // `chapterN_windows/lang/lang_<idioma>.json` que trae el propio juego.
    // Como `scr_84_get_sprite` / `scr_84_get_sound` / `scr_get_font` leen
    // esos mismos mapas, todo el código que el mod reescribió sigue
    // funcionando y recibe los assets japoneses sin tocar una línea más.
    //
    // Detalles que importan:
    //   - `scr_84_init_localization` LEE `global.lang` de la clave `LANG.LANG`
    //     del true_config.ini (la del juego, distinta de la `LANG_DT` del
    //     mod), así que hay que escribirla antes o pisaría nuestra elección.
    //   - NO se toca `global.lang_loaded` aquí: esa función tiene su propio
    //     gate `lang_loaded != lang` y se encarga de marcarla.
    //   - Los sprites/sonidos externos que hubiera cargado un pack anterior
    //     los libera el mecanismo de `outdated_*` de
    //     `scr_switch_game_language`; aquí solo se reconstruyen los mapas.
    if (is_native_lang())
    {
        global.chapter_lang_settings = json_parse("{}");

        // Las fuentes que hubiera añadido un pack sí se liberan aquí (igual
        // que hace la rama normal de más abajo): no las cubre el mecanismo
        // de `outdated_*`, que solo difiere sprites y sonidos, y
        // `scr_84_init_localization` va a destruir el `font_map` que las
        // referencia.
        if (variable_global_exists("loaded_fonts"))
        {
            for (var i = 0; i < array_length(global.loaded_fonts); i++)
                font_delete(global.loaded_fonts[i]);

            global.loaded_fonts = [];
        }

        ossafe_ini_open("true_config.ini");
        ini_write_string("LANG", "LANG", global.lang);
        ossafe_ini_close();

        scr_84_init_localization();

        // Nada quedó pendiente de cargar: los assets nativos ya están en
        // los mapas, no hay recarga diferida que disparar.
        global.lang_sprites_pending = false;
        global.lang_sounds_pending = false;
        exit;
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
        
        global.chapter_lang_settings = scr_load_json(get_lang_folder_path() + "chapter" + string(global.chapter) + "/chapter_settings.json");
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
        
        // Sonidos diferidos: en el boot se cargan aqui; en un cambio de
        // idioma en caliente el loop se salta (pending) y los carga
        // `scr_load_lang_sounds_only` de forma perezosa. El loader se
        // registra siempre para que el codigo compartido pueda invocarlo.
        global.lang_sounds_loader = scr_load_lang_sounds_only;
        if (!(variable_global_exists("lang_sounds_pending") && global.lang_sounds_pending))
            scr_load_lang_sounds_only();

        // Las fuentes-sprite de numeros (damage/hp) se rehacen tras la recarga
        // de sprites en caliente: dependen de sprites que el pack localiza.
        // scr_load_lang_sprites_only invoca este loader al terminar.
        global.lang_fonts_loader = scr_reload_damage_fonts;

        global.lang_map = ds_map_create();
        scr_lang_load();
        scr_ascii_input_names();
    }
}

// Carga (o recarga) los streams de sonido del idioma activo al
// `chemg_sound_map`. Contiene el bloque de sonidos especifico del Cap.5
// (sounds_list + voicelines adicionales) y re-cachea las voces de Flowery
// justo despues, para que `global.flowery_txtsnd` apunte a los streams
// del idioma nuevo. Lo llaman `scr_init_localization` (boot) y
// `scr_apply_pending_sound_reload` (recarga diferida tras un cambio de
// idioma en caliente). En la ruta diferida `scr_apply_pending_sound_reload`
// ya puso `lang_sounds_pending = false` antes de llamar aqui, asi que el
// `scr_84_get_sound` interno de flowery no vuelve a disparar el reload.
function scr_load_lang_sounds_only()
{
    if (variable_global_exists("chemg_sound_map"))
        ds_map_clear(global.chemg_sound_map);
    else
        global.chemg_sound_map = ds_map_create();

    for (var i = 0; i < array_length(global.sounds_list); i++)
        add_sound(global.sounds_list[i]);

    var additional_voicelines = get_chapter_lang_setting("additional_voicelines", {});
    var letters = variable_struct_get_names(additional_voicelines)
    for (var i = 0; i < array_length(letters); i++)
    {
        var letter = letters[i];
        var voice = variable_struct_get(additional_voicelines, letter);
        add_sound(voice);

        // Registrar la voz extra en `songs_list` para que el interruptor de
        // voces dobladas (`translated_songs`) tambien la cubra: sin esto,
        // `scr_84_get_sound` no devuelve el asset vanilla al apagarlas.
        //
        // El guard es propio del fork: aqui esta funcion se re-ejecuta en cada
        // cambio de idioma en caliente (upstream solo corre este bucle una vez,
        // dentro de `scr_init_localization`), y `global.songs_list` la crea
        // `init_global_vars` una sola vez por arranque. Sin el `array_includes`
        // la lista creceria sin freno acumulando duplicados.
        if (!array_includes(global.songs_list, voice))
            global.songs_list[array_length(global.songs_list)] = voice;
    }

    scr_floweryvoiceclip_init();
}
