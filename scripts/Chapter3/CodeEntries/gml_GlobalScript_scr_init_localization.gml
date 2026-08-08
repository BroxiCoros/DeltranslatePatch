function scr_init_localization()
{
    if (!variable_global_exists("lang_loaded"))
    {
        global.lang_loaded = "";
        global.loaded_sprites = [];
        global.loaded_sounds = [];
        global.loaded_fonts = [];
    }

    // Primer arranque del capitulo (aun no se ha cargado ningun idioma). Es
    // cuando toca precargar los demas packs: hay pantalla de carga y el coste
    // se paga ahi en vez de en mitad de la partida.
    var is_boot = (global.lang_loaded == "");
    
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
    //   - Los sprites/sonidos del pack que estuviera activo NO se liberan: se
    //     guardan enteros en la cache (`scr_lang_cache`) para poder volver a el
    //     sin recargar nada. Aqui solo se reconstruyen los mapas.
    if (is_native_lang())
    {
        // El pack que estuviera activo se guarda entero en la cache antes de
        // ceder el control al vanilla, y los globales se desconectan para que
        // el `ds_map_destroy` de `scr_84_init_localization` se lleve por
        // delante cuatro maps desechables y no los del pack. Antes aqui se
        // borraban las fuentes del pack a mano; ya no hace falta, porque no se
        // destruye nada suyo.
        // OJO con la condicion: el detach va SOLO cuando venimos de un pack.
        //
        // Al salir al menu del capitulo hay un `game_restart()`, y ni los
        // globales ni los ds_map se pierden ahi. O sea que se vuelve a entrar
        // aqui con `lang_loaded` ya valiendo el idioma nativo, y entonces
        // `scr_84_init_localization` NO reconstruye nada (su gate es
        // `lang_loaded != lang`, y son iguales). Si hubieramos hecho el detach
        // igualmente, `global.lang_map` se habria quedado en el map vacio que
        // deja el detach y nadie lo volveria a llenar: en el Cap.1 eso reventaba
        // en el `window_set_caption` del Create de `obj_initializer2`, que pide
        // un string antes de que nada reinicialice la localizacion.
        if (global.lang_loaded != "" && !is_native_lang(global.lang_loaded))
        {
            scr_lang_cache_save(global.lang_loaded);
            scr_lang_cache_detach();
        }

        global.chapter_lang_settings = json_parse("{}");

        ossafe_ini_open("true_config.ini");
        ini_write_string("LANG", "LANG", global.lang);
        ossafe_ini_close();

        scr_84_init_localization();

        // Nada quedó pendiente de cargar: los assets nativos ya están en
        // los mapas, no hay recarga diferida que disparar.
        global.lang_sprites_pending = false;
        global.lang_sounds_pending = false;

        // Arrancar en el idioma nativo no exime de precargar los packs: el
        // jugador puede cambiarse a uno en cualquier momento.
        if (is_boot)
            scr_lang_preload_others();

        exit;
    }

    if (global.lang_loaded != global.lang)
    {
        var prev = global.lang_loaded;

        // El idioma que dejamos: si es un pack se guarda tal cual (nada se
        // destruye, por eso volver a el es gratis); si era nativo, sus maps
        // los creo el vanilla, nadie mas los referencia y se destruyen aqui.
        if (prev != "")
        {
            if (is_native_lang(prev))
                scr_lang_cache_discard_current();
            else
                scr_lang_cache_save(prev);
        }

        global.lang_loaded = global.lang;

        // El loader de sonidos se registra siempre, venga el idioma de la
        // cache o del disco: el codigo compartido lo invoca por su cuenta.
        global.lang_sounds_loader = scr_load_lang_sounds_only;

        // ¿Ya lo teniamos cargado? Entonces esto es solo reasignar punteros:
        // ni disco, ni decodificar PNG, ni rasterizar fuentes. Es el camino
        // que hace que cambiar de idioma sea instantaneo como en nativo.
        if (scr_lang_cache_load(global.lang))
        {
            global.lang_sprites_pending = false;
            global.lang_sounds_pending = false;

            // Las fuentes-sprite (tvlandfont en el Cap.3, las de dano en el
            // Cap.5) se construyen a partir de sprites que el pack localiza,
            // asi que hay que rehacerlas contra el map recien activado.
            if (variable_global_exists("lang_fonts_loader"))
                global.lang_fonts_loader();

            scr_ascii_input_names();
            exit;
        }

        scr_lang_load_assets();
        scr_ascii_input_names();

        if (is_boot)
            scr_lang_preload_others();
    }
}

// Carga desde el disco los assets del idioma activo al estado global.
//
// Sale del cuerpo de `scr_init_localization` para que la precarga
// (`scr_lang_preload_others`) pueda reutilizarla con otro idioma activo
// temporalmente. No toca `lang_loaded` ni `scr_ascii_input_names`: de eso se
// encarga quien llama.
//
// Sigue respetando `lang_sprites_pending` / `lang_sounds_pending`. Con la
// cache ese diferido casi nunca entra en juego (si el idioma se precargo, ni
// se llega aqui), pero sigue haciendo falta para el caso en que toca cargar de
// verdad en mitad de la partida: en consola no hay precarga, y un pack que se
// instale despues del arranque tampoco estara cacheado. La precarga apaga los
// dos flags antes de llamar, porque ahi si queremos la carga completa.
function scr_lang_load_assets()
{
    // Los recursos creados en runtime son por idioma; los del anterior ya
    // estan a salvo en la cache, asi que aqui se empieza de cero.
    global.loaded_sprites = [];
    global.loaded_sounds = [];
    global.loaded_fonts = [];

    global.chapter_lang_settings = scr_load_json(get_lang_folder_path() + "chapter3/chapter_settings.json");
    global.font_map = ds_map_create();
    global.lang_missing_map = ds_map_create();
    global.chemg_sprite_map = ds_map_create();
    global.chemg_sound_map = ds_map_create();
    font_add_enable_aa(false);
    
    for (var i = 0; i < array_length(global.fonts_list); i++)
        add_font(global.fonts_list[i][0], global.fonts_list[i][1]);
    
    if (is_undefined(ds_map_find_value(global.font_map, "fnt_main_mono")) || ds_map_find_value(global.font_map, "fnt_main_mono") == -1)
        ds_map_set(global.font_map, "fnt_main_mono", ds_map_find_value(global.font_map, "fnt_main"));
    
    if (is_undefined(ds_map_find_value(global.font_map, "fnt_8bit_mixed")) || ds_map_find_value(global.font_map, "fnt_8bit_mixed") == -1)
        ds_map_set(global.font_map, "fnt_8bit_mixed", ds_map_find_value(global.font_map, "fnt_8bit"));
    
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
    
    // La fuente-sprite de TV Land depende de `spr_tvlandfont`, que el pack
    // localiza, asi que hay que rehacerla en cada cambio de idioma. La
    // registramos como loader para que `scr_load_lang_sprites_only` la
    // reconstruya DESPUES de la recarga diferida de sprites.
    //
    // Antes esto era una llamada suelta aqui, y anulaba el diferido entero:
    // `scr_84_get_sprite` aplica la recarga pendiente antes de resolver, y
    // `scr_switch_game_language` ya habia marcado `lang_sprites_pending`, o
    // sea que los 356 sprites del capitulo se cargaban de golpe en el frame
    // del cambio. Ver `scr_reload_tvlandfont`.
    global.lang_fonts_loader = scr_reload_tvlandfont;

    // En el boot no hay recarga pendiente y los sprites acaban de cargarse
    // justo arriba, asi que la fuente se construye ya (ahi
    // `scr_84_get_sprite` no dispara nada). En el cambio en caliente NO se
    // toca aqui: la hace el loader al terminar de cargar los sprites.
    if (!(variable_global_exists("lang_sprites_pending") && global.lang_sprites_pending))
        scr_reload_tvlandfont();

    // Sonidos diferidos: en el boot se cargan aqui; en un cambio de
    // idioma en caliente el loop se salta (pending) y los carga
    // `scr_load_lang_sounds_only` de forma perezosa. El loader se
    // registra siempre para que el codigo compartido pueda invocarlo.
    global.lang_sounds_loader = scr_load_lang_sounds_only;
    if (!(variable_global_exists("lang_sounds_pending") && global.lang_sounds_pending))
        scr_load_lang_sounds_only();

    global.lang_map = ds_map_create();
    scr_lang_load();
}

// Carga (o recarga) los streams de sonido del idioma activo al
// `chemg_sound_map`. Contiene el bloque de sonidos especifico del Cap.3
// (button sounds del speak-and-spell + sounds_list + funny sounds). Lo
// llaman `scr_init_localization` (boot) y `scr_apply_pending_sound_reload`
// (recarga diferida tras un cambio de idioma en caliente).
function scr_load_lang_sounds_only()
{
    if (variable_global_exists("chemg_sound_map"))
        ds_map_clear(global.chemg_sound_map);
    else
        global.chemg_sound_map = ds_map_create();

    var sound_symbols = get_chapter_lang_setting("button_sounds_symbols", ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "!", "?"]);
    set_chapter_lang_setting("button_sounds_symbols", sound_symbols);

    for (var i = 0; i < array_length(sound_symbols); i++)
        add_sound("snd_speak_and_spell_" + sound_symbols[i], 1);

    for (var i = 0; i < array_length(global.sounds_list); i++)
        add_sound(global.sounds_list[i]);

    var additional_funny_sounds = get_chapter_lang_setting("additional_funny_sounds", []);
    for (var i = 0; i < array_length(additional_funny_sounds); i++)
        add_sound(additional_funny_sounds[i]);
}
