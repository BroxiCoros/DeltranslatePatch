var flag, i, spr_arr, snd_arr;
function scr_init_localization() //gml_Script_scr_init_localization
{
    if (!variable_global_exists("lang_loaded")) {
        global.lang_loaded = "";
        global.loaded_sprites = [];
        global.loaded_sounds = [];
        global.loaded_fonts = [];
        global.chemg_sprite_map = ds_map_create();
    }
    // ---------------------------------------------------------------
    // Idiomas NATIVOS del juego (inglés / japonés): apartarse
    // ---------------------------------------------------------------
    // El menú raíz no tiene sistema de localización que delegar (aquí no
    // existe `scr_84_init_localization`): sus textos son ternarios sobre
    // `global.lang` y sus fuentes se piden por id. Así que "cargar" un idioma
    // nativo es exactamente no cargar nada y dejar `global.lang` puesto.
    //
    // Lo único que sí hay que hacer es escribir la clave `LANG.LANG` del
    // true_config.ini, que es la que lee el `obj_init_pc_Create_0` del juego
    // (el mod usa `LANG_DT`, que es otra), y soltar las fuentes que hubiera
    // cargado un pack anterior.
    if (is_native_lang())
    {
        if (global.lang_loaded != global.lang)
        {
            global.lang_loaded = global.lang

            for (i = 0; i < array_length(global.loaded_fonts); i++)
                font_delete(global.loaded_fonts[i])

            global.loaded_fonts = []
        }

        ossafe_ini_open("true_config.ini")
        ini_write_string("LANG", "LANG", global.lang)
        ossafe_ini_close()
        exit
    }

    if (global.lang_loaded != global.lang)
    {
	    global.lang_loaded = global.lang
        ds_map_destroy(global.font_map)
        ds_map_destroy(global.lang_sprites)
        ds_map_destroy(global.lang_sounds)
        ds_map_destroy(global.chemg_sprite_map)
        global.font_map = ds_map_create()
        global.lang_sprites = ds_map_create()
        global.lang_sounds = ds_map_create()
        global.chemg_sprite_map = ds_map_create();
        var fonts_arr = [["fnt_main", 12], ["fnt_mainbig", 24]]
        font_add_enable_aa(false)
        for (i = 0; i < array_length(fonts_arr); i++) {
            add_font(fonts_arr[i][0], fonts_arr[i][1])
        }

        ds_map_add(global.font_map, "fnt_placeholder", font_add("Calibri", 10, 1, 0, 32, 70000))

        global.lang_map = ds_map_create()
        scr_lang_load()
    }
}

