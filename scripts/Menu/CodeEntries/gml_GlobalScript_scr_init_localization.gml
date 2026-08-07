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

        // Sin pack no hay strings que buscar, asi que el mapa se deja VACIO y
        // `scr_get_lang_string` devuelve su literal (el ingles del fork). Sin
        // esto seguia sirviendo los textos del pack ANTERIOR: el selector se
        // quedaba en español -- "Idioma", "Versión de traducción actual" --
        // dibujado con la fuente del juego, que no tiene tildes, asi que
        // ademas salia cortado.
        //
        // Pero lo importante es otra cosa: `obj_gamecontroller_Create_0` corta
        // por lo sano con `if (variable_global_exists("lang_map")) return;`, y
        // en idioma nativo ese global no se creaba NUNCA. Asi que cada
        // `room_restart` -- y salir de este menu es uno -- reejecutaba el
        // Create entero, que rehace `global.font_map` vacio de cero. Creando
        // aqui el mapa, el idioma nativo entra por la misma puerta que un pack.
        if (variable_global_exists("lang_map"))
            ds_map_destroy(global.lang_map)

        global.lang_map = ds_map_create()

        // FUERA del guard de `lang_loaded` a proposito: si el Create llego a
        // reejecutarse, `global.font_map` esta vacio pero `global.lang_loaded`
        // ya coincide con `global.lang`, asi que dentro del guard no se
        // repoblaria y todo el menu del fork acabaria dibujando con la fuente
        // latina del juego: sin kana en japones y sin tildes en nada.
        //
        // Borrar las fuentes del pack tampoco basta por si solo: el mapa se
        // quedaba con sus handles, ya invalidos, y `scr_get_font` los daba por
        // buenos (no son `undefined` ni -1). En los capitulos nada de esto pasa
        // porque alli la rama nativa llama a `scr_84_init_localization`, que
        // rellena el mapa con las fuentes del juego.
        ds_map_destroy(global.font_map)
        global.font_map = ds_map_create()

        // El codigo vanilla del menu pide sus fuentes por id
        // (`_font = (global.lang == "en") ? 2 : 1`), asi que aqui solo hay que
        // cubrir las claves del mod. En ingles el mapa vacio ya vale:
        // `scr_get_font` cae a `asset_get_index` y "fnt_main" y "fnt_mainbig"
        // existen como assets del juego.
        //
        // Por `asset_get_index` y NO por el nombre del asset a pelo: el
        // compilador de UTMT no resuelve nombres de fuente dentro de una
        // llamada cualquiera, los compila como variable de instancia
        // (`push.v self.fnt_ja_main`). Eso metia `undefined` en el mapa.
        //
        // Y OJO CON EL NOMBRE: el propio patcher RENOMBRA las fuentes
        // japonesas del juego, de `fnt_ja_X` a `fnt_X_ja` (el bucle sobre
        // `Data.Fonts` del final de BaseFix). En el data.win parcheado -- que
        // es el unico que existe en tiempo de ejecucion -- el prefijo ya no
        // esta, asi que buscando `fnt_ja_main` esto devolvia -1, el `!= -1` se
        // saltaba las cinco altas sin decir nada y el mapa se quedaba vacio: el
        // selector caia a la fuente latina y el japones salia en blanco. Se
        // prueban los dos nombres por si el renombrado cambia algun dia.
        if (global.lang == "ja")
        {
            var ja_fonts = ["main", "mainbig", "small", "comicsans", "dotumche"]

            for (i = 0; i < array_length(ja_fonts); i++)
            {
                var ja_font = asset_get_index("fnt_" + ja_fonts[i] + "_ja")

                if (ja_font == -1)
                    ja_font = asset_get_index("fnt_ja_" + ja_fonts[i])

                if (ja_font != -1)
                    ds_map_add(global.font_map, "fnt_" + ja_fonts[i], ja_font)
            }
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

